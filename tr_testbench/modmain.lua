-- True Range testbench: the real game as the test - each boss of the list brought in, left to attack
-- you as it would (its own brain and stategraph: how it goes into a move, which way it turns, is the
-- game's), and at each attack you're moved by script, every frame:
--   step: where you were as it began, then 60 degrees round it (as far off) at frame k (k = 0, 3, ... 60) - the last k
--         still struck is when it really stops aiming
--   jump: off to d in front of it (d = 2 ... 13) at its first frame - how far it really reaches
-- [tr_bench] lines say which, when; True Range's own traces ([tr_trace], debug.txt) say the rest -
-- tools/bench_lock.lua reads them. You can't be hurt meanwhile. Only while you host.
local G = GLOBAL
local KEY = G.rawget(G, GetModConfigData("key") or "KEY_F7") or G.KEY_F7
local ROUNDS = GetModConfigData("rounds") or 2
-- (the game sped up meanwhile - only if it still steps 1/30 s of game time a tick, many ticks a frame:
-- measured over its first 30 ticks; ticks grown longer (each 2-4 frames) would coarsen every collision,
-- timed event and move of yours - slowed back to 1x then, said in the log as "speed off")
local SPEED = GetModConfigData("speed") or 1

-- (the bosses brought in, in turn - Uncompromising Mode's first: what its players found wrong. Only ones
-- whose moves don't need their home: the Hooded Widow's trees, the Ancient Guardian's pillars, the Crab
-- King's and Malbatross' sea, the Antlion's desert, the Fuelweaver's atrium, Toadstool's mushroom trees,
-- the Celestial Champion's island - those tested where they are: go to one, Shift + the key (HERE))
-- (Deerclops three times: Uncompromising Mode gives each one of three mutations as it's made, at random)
local LIST = {
    "deerclops", "deerclops", "deerclops", "moose", "bearger", "mock_dragonfly", "moonmaw_dragonfly",
    "shadow_bishop", "beequeen", "klaus", "dragonfly", "eyeofterror", "twinofterror1",
}
local HERE_RANGE = 40      -- (the one tested where it is: the nearest boss this near you)
local STEP_KS = {}
for k = 0, 60, 3 do STEP_KS[#STEP_KS + 1] = k end
local JUMPS = { 2, 4, 6, 8, 10, 13 }
-- (running round it from frame k: k = 0, 6, ... 60, at your running speed)
local RUN_KS = {}
for k = 0, 60, 6 do RUN_KS[#RUN_KS + 1] = k end
local RUN_SPEED = 6
-- (walking straight at it or away from it from frame k - how far you are changing all through the move, as
-- a player's does: every other scene keeps you as far off as you began (round it, or jumped there), so the
-- drawer never went from one distance's map to the next under you - VERIFY_PLAN 6.16, I9)
local WALK_KS = { 0, 9, 18, 30 }
local WALK_SPEED = 4
-- (60 degrees round it, as far off: past a blow's width either side, still in its reach - stepped
-- straight aside instead (5, then 10), a wide one still struck, a short one couldn't reach either way)
-- (and 150 round - all but behind it: a wide blow (Deerclops' icy swipe, its boss not turning at all) still
-- struck you 60 round, read as aimed - at 150 only one that turns after you, or strikes all round, does)
local ORBITS = { 60, 150 }
local MAX_FRAMES = 360      -- (12 s: one move no longer than that - a spin, a laser sweep)
local QUIET_FRAMES = 15     -- (half a second out of its attack: that move's over)
-- (one that never attacks: on to the next - as long for each round asked for: 12 minutes a boss with
-- 2, cut short at 10 - the Eye and the Shadow Bishop gave up halfway)
local BOSS_MINUTES = 6 * ROUNDS
-- (and one that hasn't begun a single scene a whole day in: never will - every one that attacked at all began
-- its first in under 11 s; 24 that never did took 9,431 s of 50,974 waiting out the hour, 2026-10-17 run)
local FIRST_SECS = 480

-- (made ready to fight, as its world would - each the game's own calls; file:line in the game's scripts)
-- PHASE_LEVELS BEGIN (written from tools/phase_levels.lua by tools/phase_inject.ps1 - each boss's health thresholds)
local PHASE_LEVELS = {
    alterguardian_phase4_lunarrift = { 0.950, 0.750, 0.650 },
    ancient_trepidation = { 0.500 },
    archive_centipede = { 0.660, 0.330, 0.200 },
    beefalo = { 0.800, 0.500, 0.450, 0.200 },
    beefalo_moon = { 0.800, 0.500, 0.450, 0.200 },
    beeguard = { 0.750, 0.500 },
    beequeen = { 0.750, 0.500, 0.250 },
    bunnyman = { 0.333 },
    cozy_bunnyman = { 0.333 },
    crabking = { 0.900, 0.800, 0.700, 0.600, 0.500, 0.400, 0.350, 0.300, 0.200, 0.100 },
    daywalker = { 0.999, 0.800, 0.500, 0.300 },
    daywalker2 = { 0.750, 0.500 },
    deerclops = { 0.500, 0.330, 0.200 },
    dragonfly = { 0.800, 0.500, 0.200 },
    dreadeye = { 0.700, 0.500, 0.200 },
    eyeofterror = { 0.650 },
    hoodedwidow = { 0.750, 0.500, 0.250 },
    klaus = { 0.500 },
    lavae = { 0.750, 0.500, 0.250 },
    lavae2 = { 0.750, 0.500, 0.250 },
    malbatross = { 0.660, 0.330 },
    mermking = { 0.950, 0.750, 0.500, 0.250, 0.100 },
    minotaur = { 0.600, 0.400, 0.300 },
    moonmaw_dragonfly = { 0.500 },
    moose = { 0.660, 0.600, 0.330 },
    mothergoose = { 0.660 },
    mutated_penguin = { 0.500 },
    mutateddeerclops = { 0.500, 0.330, 0.200 },
    penguin = { 0.500 },
    rambranch = { 0.700, 0.400 },
    smallbird = { 0.900, 0.500, 0.250 },
    snowmong = { 0.300 },
    swathgrithr = { 0.667, 0.333, 0.330 },
    teenbird = { 0.900, 0.500, 0.250 },
    toadstool = { 0.700, 0.400, 0.200 },
    toadstool_dark = { 0.700, 0.400, 0.200 },
    twinofterror1 = { 0.650 },
    twinofterror2 = { 0.650 },
    uncompromising_buffrat = { 0.500 },
    vault_pillar_guard = { 0.750, 0.500 },
    wagboss_robot = { 0.950, 0.750, 0.650, 0.600, 0.400, 0.300, 0.250 },
}
-- PHASE_LEVELS END
-- (the control (VERIFY_PLAN 6.17 D): true - health set as before (SetPercent), its phases never fired)
local OLD_SETPERCENT = false
-- (controls: true - one raised again in itself not followed (Klaus); struck only the once, at the first step)
local OLD_REVIVE = false
local OLD_SCENE_CHARGE = false
local OLD_ONEHIT = false
-- (somewhere at sea for one that lives there: open water 6 round it and round a boat 12 off it, out to 600; you
-- put on the boat, both left there for every scene (_tr_stay). old: the first open water out to 40, no boat)
local function AtSea(boss, p, old)
    local map = G.TheWorld.Map
    local x, _, z = p.Transform:GetWorldPosition()
    local function Open(tx, tz)
        if not map:IsOceanAtPoint(tx, 0, tz) then return false end
        if old then return true end
        for k = 0, 7 do
            local a = k / 8 * 2 * math.pi
            if not map:IsOceanAtPoint(tx + 6 * math.cos(a), 0, tz + 6 * math.sin(a)) then return false end
        end
        return true
    end
    local found = nil
    for r = 8, old and 40 or 600, old and 4 or 8 do
        local n = old and 16 or math.max(16, math.floor(r))
        for k = 0, n - 1 do
            local a = k / n * 2 * math.pi
            local tx, tz = x + r * math.cos(a), z + r * math.sin(a)
            -- (and the boat's spot beside it open water too)
            if Open(tx, tz) and (old or Open(tx + 12, tz)) then found = { tx, tz } break end
        end
        if found then break end
    end
    if found ~= nil then
        boss.Transform:SetPosition(found[1], 0, found[2])
        if not old then
            local boat = G.SpawnPrefab("boat")
            if boat ~= nil then
                boat.Transform:SetPosition(found[1] + 12, 0, found[2])
                boss._tr_boat = boat
                boss._tr_stay = true
                -- (you on it - Put takes a boat's deck as ground (GetPlatformAtPoint))
                if p.Physics ~= nil then p.Physics:Teleport(found[1] + 12, 0, found[2]) else p.Transform:SetPosition(found[1] + 12, 0, found[2]) end
                boss._tr_hold = { x = found[1] + 12, z = found[2] }
            end
        end
    end
    return found
end
local SETUP = {
    -- (it leaves unless a sandstorm's on (antlion.lua:218 OnInit -> Despawn); StartCombat (:284, :495): its
    -- combat, its angry stategraph and brain, after the one in reach)
    antlion = function(boss, p) boss:StartCombat(p) end,
    -- (the moon pig: its brain kills it 5 s with no moon base within 60, petrifies it once the base's mooncharge is over
    -- (moonbeastbrain.lua LostMoonBase, LostMoonCharge): gone 5.1 s in, lag 2026-10-31_0842. Its own base itself - always
    -- near, never workable - charged all along)
    moonpig = function(boss)
        if boss.components.entitytracker == nil then return end
        if boss.components.timer == nil then boss:AddComponent("timer") end
        boss.components.timer:StartTimer("mooncharge", 1e6)
        boss.components.entitytracker:TrackEntity("moonbase", boss)
    end,
    -- (its brain kills it with no atrium gate round it (stalkerbrain.lua:218, stalker.lua:998): a gate where it
    -- is, tracked both ways - as fossil_mound.lua:53-58 makes it)
    stalker_atrium = function(boss, p, bx, bz)
        local g = G.SpawnPrefab("atrium_gate")
        g.Transform:SetPosition(bx, 0, bz)
        if boss.components.entitytracker ~= nil then boss.components.entitytracker:TrackEntity("stargate", g) end
        if g.TrackStalker ~= nil then g:TrackStalker(boss) end
        boss._tr_gate = g
    end,
    -- (Uncompromising Mode's Mind Weaver: gone at any change of isday (mindweaver.lua:200-209 - dusk too) and at
    -- each end of its idle by day (SGmindweaver.lua idle animover), before its grab (5 s, then 5 s growing its
    -- shadow, :71-101): 10 s in on the 2026-10-31_0922 and _0929 lag runs - kept, and night (NIGHT))
    mindweaver = function(boss) boss:StopAllWatchingWorldStates() end,
    -- (Uncompromising Mode's haunt: its hand sent at you every 10 s (SGum_haunt StartHaunting, from its appear), but it
    -- fades out once you're within 4.5 (um_haunt.lua ChangeVisibility, 1 - d^2/100 >= .8) and comes back with the 10 s
    -- begun again - 4 times, then gone: never struck in lag 0837. Its fading taken off (the updatelooper), seen as it is)
    um_haunt = function(boss)
        if boss.components.updatelooper ~= nil then boss.components.updatelooper.onupdatefns = {} end
        boss.AnimState:SetMultColour(0, 0, 0, 1)
    end,
    -- (its Fuel Seeker strikes only by a lit fire: 15 times drunk from it (SGfuelseeker.lua ConsumeLight, level 3)
    -- then the burst (:263-283, 6 round): none on the bench - a fire pit by you, full, taken away after it)
    fuelseeker = function(boss, p)
        local x, _, z = p.Transform:GetWorldPosition()
        local f = G.SpawnPrefab("firepit")
        f.Transform:SetPosition(x + 3, 0, z)
        if f.components.fueled ~= nil then f.components.fueled:SetPercent(1) end
        boss._tr_fire = f
    end,
    -- (no weapon without junk to dig in (daywalker2.lua:252-293; brain :160-163, :213-222): a pile beside it)
    daywalker2 = function(boss, p, bx, bz)
        local j = G.SpawnPrefab("junk_pile_big")
        j.Transform:SetPosition(bx + 6, 0, bz)
        -- (Uncompromising Mode's cooker set beside it a tick on (postinit/prefabs/junk_pile_big.lua:14) found no
        -- ground and broke the server, 2026-10-19: what it set going cancelled - not needed here)
        for task in pairs(j.pendingtasks or {}) do if task.Cancel ~= nil then task:Cancel() end end
        if boss.components.entitytracker ~= nil then boss.components.entitytracker:TrackEntity("junk", j) end
    end,
    -- (the Shrouded Queen's arena's spikes - no arena here (a virtual room in the caves, map.lua IsPointInCharlieBossArena):
    -- five called up round you every 7 s as its own summon does (charliearena_spike.lua OnShroudenSummon - hidden, up
    -- 0-.5 s on, striking 29 frames into rising), taken away 4 s on, not left a wall; 2026-10-26. TR_NO_ARENA_SPIKES: none)
    charlie_boss = function(boss, p)
        if G.rawget(G, "TR_NO_ARENA_SPIKES") ~= nil then return end
        boss:DoPeriodicTask(7, function()
            if p == nil or not p:IsValid() then return end
            local x, _, z = p.Transform:GetWorldPosition()
            for _ = 1, 5 do
                local a, r = math.random() * 2 * math.pi, math.random() * 3
                local s = G.SpawnPrefab("charliearena_spike")
                if s ~= nil then
                    s.Transform:SetPosition(x + r * math.cos(a), 0, z + r * math.sin(a))
                    if s.OnShroudenSummon ~= nil then s:OnShroudenSummon(boss) end
                    s:DoTaskInTime(4, s.Remove)
                end
            end
        end)
    end,
    -- (made from its sack with its two deer (klaus_sack -> klaus.lua:293 SpawnDeer, commander:AddSoldier - their keeper): made
    -- alone, none - the blue deer's ice circle and the red's fire never cast on the bench, 2026-10-27)
    klaus = function(boss) if boss.SpawnDeer ~= nil then boss:SpawnDeer() end end,
    -- (made switched off, its combat off (SGwagboss_robot.lua:757); out of "off" not by "activate": hostile,
    -- as the game's load does it (wagboss_robot.lua:1305-1308))
    wagboss_robot = function(boss) boss.sg:GoToState("idle") end,
    -- (reaches 2.5, drops you past 4 (eyeplant.lua:22-43), never moves: beside you)
    eyeplant = function(boss, p)
        local x, _, z = p.Transform:GetWorldPosition()
        boss.Transform:SetPosition(x + 1.5, 0, z)
    end,
    -- (inert till 9 gems are in (crabking.lua:116, :264-276), and at sea: put in the water nearest, gems in)
    -- (the bench world's start had no sea within 40 - it woke on land and never fought, 2026-10-19: looked
    -- for out to 600, deep enough for it and a boat (open water all round 6); you put on a boat 12 off it, both
    -- left there for every scene (_tr_stay - moved 30 on, it'd be on land or you in the sea). TR_OLD_CRAB: as before)
    crabking = function(boss, p, bx, bz)
        local found = AtSea(boss, p, G.rawget(G, "TR_OLD_CRAB") ~= nil)
        print(string.format("[tr_bench] %.3f crabking at sea%s", G.GetTime(), found ~= nil and string.format(" %.1f,%.1f", found[1], found[2]) or " - none found"))
        for _ = 1, 9 do if boss.SocketItem ~= nil then boss:SocketItem(G.SpawnPrefab("redgem")) end end
    end,
    -- (Tropical Experience's rook of the sea: made 10 off you on land like the rest, it stood there 2 off you
    -- striking at nothing - 447 drawn-in with no strike to 195 struck, bench 2026-10-31_0611; at sea as the
    -- Crab King, you on a boat 12 off it. TR_OLD_ROOKSEA: as before)
    rookwater = function(boss, p)
        if G.rawget(G, "TR_OLD_ROOKSEA") ~= nil then return end
        local found = AtSea(boss, p, false)
        print(string.format("[tr_bench] %.3f rookwater at sea%s", G.GetTime(), found ~= nil and string.format(" %.1f,%.1f", found[1], found[2]) or " - none found"))
    end,
}
-- (and kept so each tick: the stalker killed by its brain when no one's struck it a while (stalkerbrain.lua:242-245))
-- (the Twins change form only by their manager's word, on their health together (eyeofterror.lua:752-767:
-- "health_transform" once under EYEOFTERROR_TRANSFORMPERCENT of both) - one made alone never did: said
-- as the manager would, on its own health)
local function TwinTransform(boss)
    local h = boss.components.health
    if h ~= nil and not boss._tr_tf and h:GetPercent() < (G.TUNING.EYEOFTERROR_TRANSFORMPERCENT or .65) then
        boss._tr_tf = true
        boss:PushEvent("health_transform")
    end
end
local SETUP_TICK = {
    twinofterror1 = TwinTransform,
    twinofterror2 = TwinTransform,
    stalker_atrium = function(boss) boss._lastplayerhittime = G.GetTime() end,
}

-- (moves it never makes of itself, made: tr_force.txt in this mod's folder (tools/run_bench.ps1 -Force), a line a
-- boss - "boss state state ...", the harmful states tools/state_coverage.lua found under 3 times. Gone into by its
-- stategraph with you as its target, between its own attacks - its aim then not the game's own way in (VERIFY_PLAN
-- 6.1: drawn where it strikes and when, not how it aims): "[tr_bench] t boss forced state=" says which)
local FORCE = {}
do
    local io = G.rawget(G, "io")
    local fh = io ~= nil and io.open(MODROOT .. "tr_force.txt", "r") or nil
    if fh ~= nil then
        for line in fh:lines() do
            local b, rest = line:match("^(%S+)%s+(.+)$")
            if b ~= nil then
                FORCE[b] = {}
                for st in rest:gmatch("%S+") do FORCE[b][#FORCE[b] + 1] = st end
            end
        end
        fh:close()
    end
end
local FORCE_TIMES, FORCE_TRIES = 3, 6

-- (lag mode, "tr_bench+lag:...": a real player on the server from a game of its own - tools/run_lag.ps1, its
-- half tr_lagjoin, VERIFY_PLAN 6.20 - as with caves on. Only scenes a player can walk (run round, walk in/out):
-- a step or a jump is a teleport, no prediction in it. Moved by their own game, not put each tick)
local LAG_MODE = false
local LAG_START = nil

local function Scenarios()
    local list = {}
    for r = 1, ROUNDS do
        for _, orbit in ipairs(LAG_MODE and {} or ORBITS) do
            for i, k in ipairs(STEP_KS) do list[#list + 1] = { k = k, side = ((i + r) % 2 == 0) and 1 or -1, orbit = orbit } end
        end
        for i, k in ipairs(RUN_KS) do list[#list + 1] = { k = k, side = ((i + r) % 2 == 0) and 1 or -1, run = true } end
        for _, d in ipairs(LAG_MODE and {} or JUMPS) do list[#list + 1] = { jump = d } end
        for i, k in ipairs(WALK_KS) do
            for _, dir in ipairs({ -1, 1 }) do list[#list + 1] = { k = k, walk = dir, side = ((i + r) % 2 == 0) and 1 or -1 } end
        end
    end
    return list
end

local run = nil   -- { player, li, boss, scen, si, cur, quiet, started }
-- (several bosses at once on one server, each its own stand-in, far apart (lanes): the world's own cost each
-- tick is most of it - an idle world ran at 39x, a hound fighting in it at 40x, at Speed 128 - so K at once is
-- near K times as many, VERIFY_PLAN 6.18. Each lane a run of its own; Tick goes through them, run each in turn)
local LANES = nil
local QI = 0        -- (the list taken from by every lane: the last one taken)
local LANE_GAP = 300
local LANE_ROOM = 60   -- (moved on between scenes no further than this from its home - the logs told apart by place)
-- (a friend: a second stand-in FRIEND_OFF beside the first, all along - what goes for every player (cages, spawns
-- on each) goes for two. "tr_bench+friend:..." - you as before, the boss after you; "+watch" - True Range seen from
-- the friend's side (TR_BENCH_YOU = the friend), the boss after the other one: a player not the one hunted.
-- One lane only)
local FRIEND_MODE, FRIEND = nil, nil
local FRIEND_OFF = 5
local function LaneOf(x, z)
    if LANES == nil then return nil end
    local best, bd = nil, math.huge
    for _, ln in ipairs(LANES) do
        local d = (x - ln.home.x) ^ 2 + (z - ln.home.z) ^ 2
        if d < bd then best, bd = ln, d end
    end
    return best, math.sqrt(bd)
end
-- (a server with no screen and no one on - tools/run_bench.ps1: started by itself, on a stand-in for you)
local HEADLESS = G.TheNet ~= nil and G.TheNet:IsDedicated()

local function Log(what, extra)
    local b = run ~= nil and run.boss or nil
    print(string.format("[tr_bench] %.3f %s %s%s", G.GetTime(), b ~= nil and b.prefab or "-", what, extra or ""))
end

local function Say(text)
    local p = G.ThePlayer
    if p ~= nil and p.components.talker ~= nil then p.components.talker:Say(text) end
end

-- (lag mode's words to the player's game - tr_lagjoin has the same three, in the same order)
AddClientModRPCHandler("tr_lag", "scene", function() end)
AddClientModRPCHandler("tr_lag", "end", function() end)
AddClientModRPCHandler("tr_lag", "struck", function() end)
AddClientModRPCHandler("tr_lag", "you", function() end)
local function ToClient(p, name, ...)
    if p ~= nil and p.userid ~= nil and p.userid ~= "" then SendModRPCToClient(GetClientModRPC("tr_lag", name), p.userid, ...) end
end

-- (a scene begun only on an attack: its taunts and its after-states, busy too, took half the scenes -
-- Deerclops taunting after every swipe)
local function Attacking(boss)
    local sg = boss.sg
    -- (the Great Depths Worm: no stategraph of its own, its head out of a mound near you is its attack - no lag scene ever
    -- began for it, 5 of 5 runs a minute idle, 2026-10-28. TR_BENCH_OLD_WORMSCENE: never)
    if sg == nil and boss.chunks ~= nil and not G.rawget(G, "TR_BENCH_OLD_WORMSCENE") then
        local p = G.AllPlayers ~= nil and G.AllPlayers[1] or nil
        if p ~= nil and p:IsValid() then
            for _, ch in G.pairs(boss.chunks) do
                local d = ch.dirt_start
                if d ~= nil and d:IsValid() and d:IsNear(p, 8) then return true end
            end
        end
        return false
    end
    if sg == nil or sg.currentstate == nil then return false end
    local name = sg.currentstate.name or ""
    if name:find("taunt") or name:find("_pst$") or name:find("^hit") then return false end
    if sg:HasStateTag("attack") or sg:HasStateTag("ability") then return true end
    -- (or the first animation of a move True Range draws for it (TR_MOVE_STARTS, its debugging) - the Eye of
    -- Terror's charge, the Twins', none tagged "attack": their scenes never began, no dodging at all)
    local starts = G.rawget(G, "TR_MOVE_STARTS")
    if starts ~= nil and boss.AnimState ~= nil then
        boss._tr_starts = boss._tr_starts or starts(boss.prefab)
        for an in pairs(boss._tr_starts) do
            if boss.AnimState:IsCurrentAnimation(an) then return true end
        end
    end
    -- (one with no move of its own, only things it sets off: one of those out, 20 round it - Uncompromising Mode's haunt,
    -- its hands sent at you from its "haunt" state, no tag: 12 sent, 44 blows, no scene, lag 2026-10-31_0954.
    -- TR_BENCH_OLD_THINGSCENE: never)
    if (boss._tr_starts == nil or G.next(boss._tr_starts) == nil) and boss.Transform ~= nil and not G.rawget(G, "TR_BENCH_OLD_THINGSCENE") then
        local ok, SM = G.pcall(G.require, "true_range/simmoves")
        local H = ok and SM.Hazards ~= nil and SM.Hazards() or {}
        local x, _, z = boss.Transform:GetWorldPosition()
        for _, e in ipairs(G.TheSim:FindEntities(x, 0, z, 20)) do
            local h = e ~= boss and H[e.prefab] or nil
            if h ~= nil and h.by ~= nil then
                for _, b in ipairs(h.by) do if b == boss.prefab then return true end end
            end
        end
    end
    return false
end

local function Busy(boss)
    local sg = boss.sg
    if sg == nil then return false end
    if sg:HasStateTag("hit") or sg:HasStateTag("frozen") or sg:HasStateTag("sleeping") or sg:HasStateTag("electrocute") then return false end
    return sg:HasStateTag("attack") or sg:HasStateTag("busy")
end

-- (not into the sea, nor off the land at a boss's home: only onto ground or a boat - false if not;
-- anywhere on the water too with Too Many Items Rearranged's water walking on (tmir_waterwalk): the
-- Crab King, the Malbatross)
local function Put(player, x, z)
    local map = G.TheWorld.Map
    if not player:HasTag("tmir_waterwalk") and not map:IsPassableAtPoint(x, 0, z) and map:GetPlatformAtPoint(x, z) == nil then return false end
    if player.Physics ~= nil then player.Physics:Teleport(x, 0, z) else player.Transform:SetPosition(x, 0, z) end
    return true
end

-- (those out only at night - by day they go: the night made to last while one is tested)
local NIGHT = { eyeofterror = true, twinofterror1 = true, twinofterror2 = true, eyeofterror_mini = true, mindweaver = true }

local function NextBoss()
    if run == nil then return end
    if run.here then
        -- (the one where it is: tested once through, left there)
        Log("done")
        Say("Testbench: done")
        if run.player.components.health ~= nil then run.player.components.health:SetInvincible(false) end
        run.task:Cancel()
        G.TheSim:SetTimeScale(1)
        run = nil
        return
    end
    if run.boss ~= nil and run.boss:IsValid() then
        Log("done")
        run.boss:Remove()
    end
    -- (and all it brought with it - on a server with no one on only, never in a player's world: the Rabbit
    -- King's minions stayed on after it, striking the stand-in through every boss after (8,299 blows, three
    -- hours of game), its replay alone 15 minutes; VERIFY_PLAN 6.15) (lag mode's world the bench's own too)
    if run.dummy or run.lag then
        local px, _, pz = run.player.Transform:GetWorldPosition()
        local n = 0
        for _, e in ipairs(G.TheSim:FindEntities(px, 0, pz, 80, { "_combat" }, { "INLIMBO", "player" })) do
            if e ~= run.player and e:IsValid() then e:Remove() n = n + 1 end
        end
        -- (and anything that fights born since the boss, however far: Eye of Terror's minis ran 100-160 off
        -- after rabbits and deer, past the 80, still striking through the next boss, 2026-10-18)
        -- (with lanes: only nearer this lane's home than any other's - not another lane's boss)
        if run.guid0 ~= nil then
            local far = {}
            for _, e in pairs(G.Ents) do
                if e.GUID >= run.guid0 and e ~= run.player and e.components ~= nil and e.components.combat ~= nil
                    and not e:HasTag("player") and e:IsValid() then
                    local mine = true
                    if LANES ~= nil and e.Transform ~= nil then
                        local ex, _, ez = e.Transform:GetWorldPosition()
                        mine = LaneOf(ex, ez) == run
                    end
                    if mine then far[#far + 1] = e end
                end
            end
            for _, e in ipairs(far) do e:Remove() n = n + 1 end
        end
        if n > 0 then Log("cleared", " " .. n) end
    end
    if run.fire ~= nil then
        if run.fire:IsValid() then run.fire:Remove() end
        run.fire = nil
    end
    run.boss, run.cur = nil, nil
    -- (the next on the list - with lanes, the next any lane hasn't taken; one to be made again first)
    local prefab
    if run.retry ~= nil then
        prefab, run.retry = run.retry, nil
    elseif LANES ~= nil then
        QI = QI + 1
        run.li = QI
        prefab = LIST[QI]
    else
        run.li = run.li + 1
        prefab = LIST[run.li]
    end
    -- ("name!np": the stand-in not tagged a player for this one - its server went down when it was: code
    -- for real players only, reaching into what a stand-in hasn't, in the engine itself (warg, pied rat);
    -- tools/run_bench.ps1 queues one again so after a crash)
    local np = false
    if prefab ~= nil and prefab:sub(-3) == "!np" then prefab, np = prefab:sub(1, -4), true end
    if run.player ~= nil and run.player.components ~= nil and run.player.components.health ~= nil and HEADLESS then
        if np then run.player:RemoveTag("player") else run.player:AddTag("player") end
        run.np = np
    end
    if prefab == nil and LANES ~= nil then
        -- (this lane's done; all done once every lane is)
        run.done = true
        Log("lane done", " " .. run.k)
        for _, ln in ipairs(LANES) do if not ln.done then return end end
    end
    if prefab == nil then
        Log("all done")
        Say("Testbench: all done")
        local p = run.player
        if p.components.health ~= nil then p.components.health:SetInvincible(false) end
        run.task:Cancel()
        G.TheSim:SetTimeScale(1)
        run = nil
        -- (on a server with no one on: all it was for is done - shut down, nothing saved)
        if HEADLESS then
            local shut = G.rawget(G, "c_shutdown")
            if shut ~= nil then G.TheWorld:DoTaskInTime(1, function() shut(false) end) end
        end
        return
    end
    local p = run.player
    local x, _, z = p.Transform:GetWorldPosition()
    local boss = G.SpawnPrefab(prefab)
    if boss ~= nil then run.guid0 = boss.GUID end
    -- (which lane, before anything said of it: the logs parted by it after - tools/lane_split.lua)
    if boss ~= nil and LANES ~= nil then print(string.format("[tr_lane] %.3f %s lane=%d", G.GetTime(), prefab, run.k)) end
    if boss == nil then
        print("[tr_bench] no such prefab " .. prefab)
        return NextBoss()
    end
    -- (Uncompromising Mode's Shadow Wixie: made by its puzzle, tagged so - one made without it removes itself the next frame)
    -- (and her decoy throw (swap_ammo: clone balls) only after 1500 taken (OnDamaged) - the bench's hurt never got there: asked for)
    if prefab == "shadow_wixie" or prefab == "shadow_wixie_helper" then boss:AddTag("puzzlespawn") end
    if prefab == "shadow_wixie" then boss.decoy_attack = true end
    -- (Uncompromising Mode's shadow creatures go only for the insane: you made so while one is on, kept so (Tick))
    run.insane = (prefab == "mindweaver" or prefab == "fuelseeker") or nil
    if run.insane and p.components.sanity ~= nil then p.components.sanity:SetPercent(0) end
    -- (on ground, 10 off: straight aside was in the sea once, by the shore - a spider sank the frame it came)
    local map = G.TheWorld.Map
    local bx, bz = x + 10, z
    for k = 0, 15 do
        local a = k / 16 * 2 * math.pi
        local tx, tz = x + 10 * math.cos(a), z + 10 * math.sin(a)
        if map:IsPassableAtPoint(tx, 0, tz) then bx, bz = tx, tz break end
    end
    boss.Transform:SetPosition(bx, 0, bz)
    -- (Hallowed Nights on (run_lag -Event hallowed_nights): each pig, merm and bunnyman made its event monster - the game makes
    -- 30% of pigs franken, bunnymen vampires only in caves, mummy merms never at random: none came on the bench, 2026-10-30)
    if G.IsSpecialEventActive ~= nil and G.IsSpecialEventActive(G.SPECIAL_EVENTS.HALLOWED_NIGHTS) then
        for _, f in ipairs({ "MakeFrankenPig", "MakeMummyMerm", "MakeVampireBunny" }) do
            if type(boss[f]) == "function" then
                boss._frankeninitialized, boss._vampireinitialized = true, true
                local ok, err = G.pcall(boss[f], boss)
                print(string.format("[tr_bench] %.3f %s made by %s %s", G.GetTime(), prefab, f, ok and "" or tostring(err)))
            end
        end
    end
    -- (one that fights only once its world is set up - each made ready the game's own way, the same tick it's
    -- made (the Antlion leaves the next): 6 never fought on the 2026-10-18 bench - the reviewer, VERIFY_PLAN 6.16)
    local setup = SETUP[prefab]
    if setup ~= nil then
        local ok, err = G.pcall(setup, boss, p, bx, bz)
        Log("setup", ok and "" or (" failed: " .. tostring(err)))
        -- (where the setup put you - the Crab King's boat: held there between its attacks)
        if ok and boss._tr_hold ~= nil then run.hold = boss._tr_hold end
        run.fire = boss._tr_fire
    end
    -- (one out only at night - the Eye of Terror and the Twins leave by day: night all along while it's on;
    -- else the days as usual)
    if NIGHT[prefab] then G.TheWorld:PushEvent("ms_setclocksegs", { day = 0, dusk = 0, night = 16 })
    -- (back as the run had it: lag mode's day all along - a real player in the dark struck by the dark itself)
    elseif run.night then G.TheWorld:PushEvent("ms_setclocksegs", run.lag and { day = 16, dusk = 0, night = 0 } or { day = 10, dusk = 4, night = 2 }) end
    run.night = NIGHT[prefab] or nil
    run.boss, run.scen, run.si, run.quiet, run.idle = boss, Scenarios(), 1, 0, 0
    run.hurt, run.killed, run.kill_t, run.kill_guid, run.gone_t,run.revived, run.force_n = nil, nil, nil, nil, nil, nil, nil
    run.boss_t0, run.began, run.thing_hits = G.GetTime(), false, 0
    -- (ticks measured again for every boss, at full speed again: once for the first only, those after
    -- ran 3-4 times slower never looked at)
    if run.speed ~= nil and run.speed < SPEED then run.speed = SPEED G.TheSim:SetTimeScale(SPEED) end
    run.ticks = {}
    Log("spawned", string.format(" scenarios=%d", #run.scen))
    Say("Testbench: " .. prefab)
end

local function CheckSpeed()
    local ts = run.ticks
    if ts == nil or ts.done then return end
    ts[#ts + 1] = G.GetTime()
    if #ts == 31 then
        ts.done = true
        local dt = (ts[31] - ts[1]) / 30
        run.speed = run.speed or SPEED
        Log("tickdt", string.format(" dt=%.4f speed=%d", dt, run.speed))
        if dt > G.FRAMES * 1.5 then
            -- (ticks grown longer: half as fast, measured again - down to 1x at worst; what ran meanwhile
            -- not counted, tools/bench_lock.lua: "speed")
            run.speed = math.max(1, math.floor(run.speed / 2))
            G.TheSim:SetTimeScale(run.speed)
            Log("speed down", string.format(" dt=%.4f now=%d", dt, run.speed))
            Say("Testbench: ticks grew longer - " .. run.speed .. "x")
            if run.speed > 1 then run.ticks = {} end
        end
    end
end

-- (made further down - a stand-in made anew from Tick too)
local MakeStandIn
local function TickLane()
    if run == nil then return end
    CheckSpeed()
    local p, boss = run.player, run.boss
    if not p:IsValid() then
        -- (the stand-in gone - into the sea and sunk, smashed: a new one where it was, on - else the bench
        -- stopped there and then while the server ran on, things still coming and going in its log, so
        -- nothing ever saw it stuck (sharkboi, the vault's meteors: 15 minutes each, doing nothing))
        if HEADLESS and not run.lag and run.hold ~= nil and MakeStandIn ~= nil then
            Log("stand-in lost", string.format(" at=%.2f,%.2f", run.hold.x, run.hold.z))
            p = MakeStandIn(run.hold.x, run.hold.z)
            p.entity:SetCanSleep(false)
            if run.np then p:RemoveTag("player") end
            -- (watched from the friend's side: True Range's "you" stays the friend)
            if FRIEND_MODE ~= "watch" then G.rawset(G, "TR_BENCH_YOU", p) else p._tr_quiet = true end
            if FRIEND_MODE ~= nil then G.rawset(G, "TR_BENCH_ALL", { p, FRIEND }) end
            -- (and in its lane's place among them all)
            local yous = G.rawget(G, "TR_BENCH_YOUS")
            if yous ~= nil then
                for i, y in ipairs(yous) do if y == run.player then yous[i] = p end end
                p._tr_lane = run
            end
            run.player = p
            local c = boss ~= nil and boss:IsValid() and boss.components.combat or nil
            if c ~= nil then c:SetTarget(p) end
        else
            Log("stand-in lost - stopped")
            run = nil
            -- (nothing more it can do: the server down, not left running on with no one to test)
            local shut = HEADLESS and G.rawget(G, "c_shutdown") or nil
            if shut ~= nil then G.TheWorld:DoTaskInTime(1, function() shut(false) end) end
            return
        end
    end
    -- (you: not to be hurt, frozen, stuck in web, knocked off where you're put)
    local h = p.components.health
    if h ~= nil then
        -- (the stand-in on a server with no one on: struck as you'd be, not blocked - its health topped up
        -- every tick instead)
        if not run.dummy then h:SetInvincible(true) end
        if h:GetPercent() < .5 or run.dummy then h:SetPercent(1) end
    end
    if run.insane and p.components.sanity ~= nil and p.components.sanity:GetPercent() > .05 then p.components.sanity:SetPercent(0) end
    if p.components.freezable ~= nil and p.components.freezable:IsFrozen() then p.components.freezable:Unfreeze() end
    if p.components.pinnable ~= nil and p.components.pinnable:IsStuck() then p.components.pinnable:Unstick() end
    -- (the friend: FRIEND_OFF beside you every tick, kept whole and free as you are)
    if FRIEND ~= nil and FRIEND:IsValid() then
        local fx, _, fz = p.Transform:GetWorldPosition()
        if FRIEND.Physics ~= nil then FRIEND.Physics:Teleport(fx + FRIEND_OFF, 0, fz) else FRIEND.Transform:SetPosition(fx + FRIEND_OFF, 0, fz) end
        local fh = FRIEND.components.health
        if fh ~= nil and fh:GetPercent() < 1 then fh:SetPercent(1) end
        if FRIEND.components.pinnable ~= nil and FRIEND.components.pinnable:IsStuck() then FRIEND.components.pinnable:Unstick() end
    end
    if boss == nil then return end
    if boss:IsValid() then
        local x, _, z = boss.Transform:GetWorldPosition()
        run.last_bx, run.last_bz = x, z
    end
    -- (gone, not dead: its next phase made in its place - the Celestial Champion's first form removes itself and
    -- makes the second (alterguardian_phase1.lua:164-177): that one tested on, its scenes going on, not the end.
    -- The one made since this boss came, nearest its last place, that can fight - the most health of them)
    -- (made as it goes, the same tick (alterguardian_phase1.lua:169-171) - looked for a second at most: Glommer,
    -- wandering in 6 s after the rat was gone, taken for its next phase, 2026-10-19)
    if not boss:IsValid() and run.gone_t == nil then run.gone_t = G.GetTime() end
    -- (and made after its last tick here, not as it fell: the rat lets Chester and Glommer go as it dies, 3 s
    -- before it's gone - a few seconds' looking, brought down only)
    if run.killed and boss:IsValid() then
        local top = 0
        for guid in pairs(G.Ents) do if guid > top then top = guid end end
        run.kill_guid = top
    end
    if not boss:IsValid() and run.last_bx ~= nil and not run.no_follow and G.GetTime() - run.gone_t <= 1 then
        local best, bh = nil, 0
        -- (where it was, 4 at most: the Champion's next form made on its very spot (alterguardian_phase1.lua:171-
        -- 172); Chester, born 3 s after the rat fell 10 off, taken for its next phase at 30, 2026-10-19)
        for _, e in ipairs(G.TheSim:FindEntities(run.last_bx, 0, run.last_bz, 4, nil, { "player", "INLIMBO" })) do
            if e.GUID > (run.kill_guid or run.guid0 or 0) and e ~= p and e.components.combat ~= nil and e.components.health ~= nil and not e.components.health:IsDead() then
                local mh = e.components.health.maxhealth or 0
                if mh > bh then best, bh = e, mh end
            end
        end
        if best == nil and not run.follow_said then
            run.follow_said = true
            local n = #G.TheSim:FindEntities(run.last_bx, 0, run.last_bz, 30)
            Log("no next phase yet", string.format(" near=%d at=%.2f,%.2f guid0=%s", n, run.last_bx, run.last_bz, tostring(run.guid0)))
        end
        if best ~= nil then
            Log("next phase", string.format(" %s -> %s", tostring(boss.prefab), best.prefab))
            if LANES ~= nil then print(string.format("[tr_lane] %.3f %s lane=%d", G.GetTime(), best.prefab, run.k)) end
            run.boss, boss = best, best
            run.guid0 = best.GUID
            -- (its own scenes, its own health steps, from the start)
            run.scen, run.si, run.quiet, run.idle, run.cur = Scenarios(), 1, 0, 0, nil
            run.hurt, run.killed, run.kill_t, run.kill_guid, run.gone_t,run.began, run.boss_t0, run.force_n = nil, nil, nil, nil, nil, false, G.GetTime(), nil
            local c = best.components.combat
            if c ~= nil then c:SetTarget(p) end
            return
        end
    end
    -- (brought down and up again, the same one: its next phase in itself - Klaus dies and is raised unchained
    -- (SGklaus.lua:323-326, 431: KLAUS_HEALTH_REZ), its chomps only then (klausbrain.lua:19-22); one held at its
    -- least health (minhealth: daywalker, sharkboi) never rises past 10%: done as before. Five at most)
    if run.killed and boss:IsValid() and boss.components.health ~= nil and not boss.components.health:IsDead()
        and boss.components.health:GetPercent() > .1 and (run.revived or 0) < 4 and not OLD_REVIVE then
        run.revived = (run.revived or 0) + 1
        Log("next phase", string.format(" %s -> %s (raised again, %d%%)", tostring(boss.prefab), tostring(boss.prefab),
            math.floor(boss.components.health:GetPercent() * 100 + .5)))
        run.scen, run.si, run.quiet, run.idle, run.cur = Scenarios(), 1, 0, 0, nil
        run.hurt, run.killed, run.kill_t, run.kill_guid, run.gone_t,run.began, run.boss_t0, run.force_n = nil, nil, nil, nil, nil, false, G.GetTime(), nil
        return
    end
    -- (lag mode: brought down and still standing 30 s on - held at its least health (sharkboi): done. Left there, the
    -- bench stood 6 minutes and the player's game went down, 2026-10-25 run 2)
    if run.lag and run.kill_t ~= nil and G.GetTime() - run.kill_t > 30 and boss:IsValid() then
        Log("done", " - still standing after being brought down")
        return NextBoss()
    end
    if not boss:IsValid() or (boss.components.health ~= nil and boss.components.health:IsDead()) then
        -- (brought down by the testbench: a while for what comes after it - its next phase made as it dies, or
        -- once it's gone - followed above; nothing in 20 s, done)
        if run.kill_t ~= nil and G.GetTime() - run.kill_t < 20 then return end
        return NextBoss()
    end
    -- (its time gone with steps still left: they're taken by time as well (below) - given up only well past it)
    if G.GetTime() - run.boss_t0 > BOSS_MINUTES * 60 * 1.2 then Log("gave up") return NextBoss() end
    -- (not one at its home (Shift+F7): a player there, the Antlion or Crab King slow to begin)
    if not run.began and not run.here and G.GetTime() - run.boss_t0 > FIRST_SECS then
        -- (once more first, made anew: the Great Depths Worm, first out in a world just begun, never set off
        -- in 480 s - made again at 485 it struck 6 s on, 2026-10-18)
        if run.again_li ~= run.li then
            run.again_li = run.li
            Log("gave up", " - no scene begun, once more")
            run.retry = LIST[run.li]
            return NextBoss()
        end
        Log("gave up", " - no scene begun")
        return NextBoss()
    end
    local c = boss.components.combat
    if c ~= nil and c.target ~= p then c:SetTarget(p) end
    local keep = SETUP_TICK[boss.prefab]
    if keep ~= nil then G.pcall(keep, boss, p) end
    if boss.components.sleeper ~= nil and boss.components.sleeper:IsAsleep() then boss.components.sleeper:WakeUp() end
    local cur = run.cur
    local busy = Busy(boss)
    if cur == nil then
        if Attacking(boss) then
            -- (an attack begun: this one's scene, from where it is and faces now)
            local s = run.scen[run.si]
            local bx, _, bz = boss.Transform:GetWorldPosition()
            local px, _, pz = p.Transform:GetWorldPosition()
            local rot = boss.Transform:GetRotation() * G.DEGREES
            cur = { s = s, f = 0, bx = bx, bz = bz, rot = rot, px = px, pz = pz }
            if s.jump ~= nil then cur.px, cur.pz = bx + s.jump * math.cos(rot), bz - s.jump * math.sin(rot) end
            run.cur, run.quiet, run.idle, run.began = cur, 0, 0, true
            local st = boss.sg ~= nil and boss.sg.currentstate ~= nil and boss.sg.currentstate.name or "?"
            Log("start", string.format(" n=%d state=%s mode=%s k=%s orbit=%s jump=%s side=%d at=%.2f,%.2f rot=%.1f you=%.2f,%.2f",
                run.si, st, s.jump ~= nil and "jump" or (s.walk ~= nil and "walk" or (s.run and "run" or "step")), tostring(s.k), tostring(s.orbit), tostring(s.jump), s.side or 0, bx, bz, rot / G.DEGREES, cur.px, cur.pz))
            -- (lag mode: the scene to the player's game, to walk itself - Lag Compensation on every other one, the
            -- same scene the other way in the next round (19 a round): each against its own control)
            if run.lag then
                -- (anything worn on you that strikes - the Hound Batilisk as a hat, biting every .6 s through every scene
                -- after (you can't die): off and away first, else each scene after it its own; 2026-10-27)
                if p.components.inventory ~= nil then
                    for _, slot in pairs(G.EQUIPSLOTS) do
                        local it = p.components.inventory:GetEquippedItem(slot)
                        if it ~= nil and it.components.combat ~= nil then
                            p.components.inventory:DropItem(it, true, true)
                            Log("lag", string.format(" took off worn %s", tostring(it.prefab)))
                        end
                    end
                end
                cur.pred = run.si % 2 == 1
                Log("lag scene", string.format(" n=%d pred=%d", run.si, cur.pred and 1 or 0))
                -- (on / off as 1 / 0: a false sent comes as nothing - every scene of three runs on, 2026-10-25)
                ToClient(p, "scene", run.si, s.walk ~= nil and "walk" or "run", s.k or 0, s.side or 0, s.walk or 0, bx, bz, rot, px, pz, cur.pred and 1 or 0, boss.prefab)
            end
        else
            -- (one it never makes of itself (FORCE): gone into now and then while it's idle, near you)
            local fl = FORCE[boss.prefab]
            -- (each 5 s it stands idle, its first 3 s let be: one that never attacks at all has no scenes to count by;
            -- and one attacking all along, never idle that long (Bearger, a tallbird: none forced on the smoke), every
            -- 4th scene as it's done)
            local by_idle = (run.idle or 0) >= 90 and (run.idle or 0) % 150 == 90
            local by_scene = run.si % 4 == 0 and run.forced_si ~= run.si
            if fl ~= nil and not busy and (by_idle or by_scene) then
                run.forced_si = run.si
                run.force_n = run.force_n or {}
                for _, st in ipairs(fl) do
                    local f = run.force_n[st] or { done = 0, tries = 0 }
                    run.force_n[st] = f
                    if f.done < FORCE_TIMES and f.tries < FORCE_TRIES then
                        f.tries = f.tries + 1
                        local entered = false
                        -- (handed you, as most attacks take their target; else a table with you in it; else nothing)
                        for _, arg in ipairs({ p, { target = p }, false }) do
                            local ok = G.pcall(function() boss.sg:GoToState(st, arg ~= false and arg or nil) end)
                            if ok and boss.sg.currentstate ~= nil and boss.sg.currentstate.name == st then entered = true break end
                        end
                        if entered then f.done = f.done + 1 end
                        Log(entered and "forced" or "forced - not entered", string.format(" state=%s n=%d try=%d", st, f.done, f.tries))
                        if entered then return end
                    end
                end
            end
            -- (between attacks: you stand still - it comes to you; not let wander off)
            local bx, _, bz = boss.Transform:GetWorldPosition()
            local px, _, pz = p.Transform:GetWorldPosition()
            run.hold = run.hold or { x = px, z = pz }
            local dx, dz = run.hold.x - bx, run.hold.z - bz
            local d = math.sqrt(dx * dx + dz * dz)
            if d > 20 then run.hold = { x = bx + dx / d * 4, z = bz + dz / d * 4 } end
            -- (with lanes: you kept within LANE_ROOM of home, and one wandered further brought back beside you - one
            -- that never attacked walked off with you after it, 257 from home, tens of thousands of lines nearer
            -- another lane's home than its own, 2026-10-19)
            if run.home ~= nil then
                local hx, hz = run.hold.x - run.home.x, run.hold.z - run.home.z
                local hd = math.sqrt(hx * hx + hz * hz)
                if hd > LANE_ROOM then run.hold = { x = run.home.x + hx / hd * LANE_ROOM, z = run.home.z + hz / hd * LANE_ROOM } end
                local bhx, bhz = bx - run.home.x, bz - run.home.z
                if bhx * bhx + bhz * bhz > (LANE_ROOM + 30) ^ 2 and not boss._tr_stay then
                    local nx, nz = run.hold.x - hx / math.max(hd, .01) * 6, run.hold.z - hz / math.max(hd, .01) * 6
                    if boss.Physics ~= nil then boss.Physics:Teleport(nx, 0, nz) else boss.Transform:SetPosition(nx, 0, nz) end
                    Log("back home", string.format(" to=%.2f,%.2f", nx, nz))
                end
            end
            -- (no attack for a while: up to it, a step a second, to 2 off - one that stays where it is (a
            -- tentacle, the Celestial Champion's arm, a lunar plant) never came, nor struck, held 10 off)
            run.idle = (run.idle or 0) + 1
            -- (lag mode: a minute with no attack - the Ancient Guardian walking into the player 2 off, never striking, 4
            -- minutes, the player's game looking stuck, 2026-10-25: on to the next)
            if run.lag and run.idle > 1800 then
                -- (made anew once first, as the bench's own give-up does: the Great Depths Worm never struck in any lag run -
                -- 5 of 5 a minute idle, 2026-10-28; made again at 485 on the bench it struck 6 s on. TR_BENCH_OLD_LAGRETRY: on)
                if run.again_li ~= run.li and not G.rawget(G, "TR_BENCH_OLD_LAGRETRY") then
                    run.again_li = run.li
                    Log("gave up", " - a minute with no attack, once more")
                    run.retry = LIST[run.li]
                    return NextBoss()
                end
                Log("gave up", " - a minute with no attack")
                return NextBoss()
            end
            if run.idle > 90 and run.idle % 30 == 0 and d > 2.5 then
                local step = math.min(d - 2, 3)
                run.hold = { x = run.hold.x - dx / d * step, z = run.hold.z - dz / d * step }
            end
            Put(p, run.hold.x, run.hold.z)
            return
        end
    end
    cur.f = cur.f + 1
    if run.lag then
        -- (lag mode: moved by their own game - held where they end up; where the server has them, each other tick, to
        -- their game: set beside where it shows them as the word comes - how far apart what's judged and what's seen)
        local lx, _, lz = p.Transform:GetWorldPosition()
        run.hold = { x = lx, z = lz }
        if cur.f % 2 == 0 then ToClient(p, "you", run.si, lx, lz, G.GetTime()) end
    else
    local x, z = cur.px, cur.pz
    if cur.s.k ~= nil and cur.f >= cur.s.k then
        if not cur.sided then
            cur.sided = true
            Log("side", string.format(" n=%d f=%d", run.si, cur.f))
        end
        -- (round it by 60 degrees, as far from it as you were: turned after you, it strikes you there; not, it
        -- misses - stepped straight aside, you went out of a short blow's reach too, read as "never aimed")
        local dx, dz = cur.px - cur.bx, cur.pz - cur.bz
        local d = math.sqrt(dx * dx + dz * dz)
        if d < 1.5 then dx, dz, d = 3 * math.cos(cur.rot), -3 * math.sin(cur.rot), 3 end
        local a = cur.s.walk ~= nil and 0 or cur.s.side * (cur.s.orbit or 60) * G.DEGREES
        -- (run: not there at once - round it at a run, 6 a second, on till the move's over: as you dodge. A
        -- step there and standing still showed nothing of a shape going along with you after it stopped
        -- aiming - replayed with that very bug in, the same as without it)
        if cur.s.run then a = cur.s.side * math.min(math.pi * 1.5, (cur.f - cur.s.k) * RUN_SPEED * G.FRAMES / d) end
        local ca, sa = math.cos(a), math.sin(a)
        x = cur.bx + dx * ca - dz * sa
        z = cur.bz + dx * sa + dz * ca
        -- (walk: in at it (-1) or out from it (+1) along the line you stood on - from where it is now, if it
        -- went on; no nearer than 1, no further than 16)
        if cur.s.walk ~= nil then
            local nbx, _, nbz = boss.Transform:GetWorldPosition()
            -- (no nearer than its body and yours touching: walked in to 1, you stood inside a Varg (radius 1) and a
            -- Bearger, carried along in them - strikes no game can have, 31 missed, 2026-10-19)
            local near = 1
            if boss.GetPhysicsRadius ~= nil then near = math.max(near, boss:GetPhysicsRadius(0) + .6) end
            local wd = math.max(near, math.min(16, d + cur.s.walk * (cur.f - cur.s.k) * WALK_SPEED * G.FRAMES))
            x, z = nbx + dx / d * wd, nbz + dz / d * wd
        end
    end
    if Put(p, x, z) then
        run.hold = { x = x, z = z }
    elseif not cur.noplace then
        -- (no ground there: this scene didn't happen as meant - tools/bench_lock.lua leaves it out)
        cur.noplace = true
        Log("noplace", string.format(" n=%d f=%d", run.si, cur.f))
    end
    end
    -- (one still charging counts as busy - a charge's run isn't tagged so: the scene ended 15 frames into it and the boss
    -- was moved off mid-charge, the Ancient Guardian's runs 128 frames to its wind-ups' 1,440 on the lag bench, 2026-10-25.
    -- Faster than a walk only (.25 a tick, 7.5 a second): one walking after you once it's struck, not the scene going
    -- on and on. OLD_SCENE_CHARGE: as before (not at all off the lag bench))
    if (run.lag or not OLD_SCENE_CHARGE) and boss:IsValid() then
        local mx, _, mz = boss.Transform:GetWorldPosition()
        if cur.lbx ~= nil and (mx - cur.lbx) ^ 2 + (mz - cur.lbz) ^ 2 > .0625 then busy = true end
        cur.lbx, cur.lbz = mx, mz
    end
    if busy then run.quiet = 0 else run.quiet = run.quiet + 1 end
    local up = false
    for e in pairs(run.flying or {}) do if e:IsValid() then up = true else run.flying[e] = nil end end
    -- (past MAX_FRAMES only once it's out of its move - cut short mid-spin, it and you moved 30 on, its spin
    -- went on aimed at where you'd been: 30 of the Red Mushdrake's "missed", 2026-10-19 bench; three times as
    -- long at most)
    if (run.quiet >= QUIET_FRAMES and not up) or (cur.f >= MAX_FRAMES and not busy) or cur.f >= 3 * MAX_FRAMES then
        run.flying = nil
        Log("end", string.format(" n=%d frames=%d", run.si, cur.f))
        if run.lag then ToClient(p, "end", run.si) end
        run.cur = nil
        if c ~= nil then c:ResetCooldown() end
        -- (both of you off to fresh ground, 30 away: what this move left lying (ice circles, 9 s) can't
        -- strike you in the next one - Deerclops' "taunt" was struck at its frame 89 by the last swipe's
        -- circles. Not one at its home (HERE): left where it is, tools/bench_lock.lua sorts its things)
        if not run.here and not boss._tr_stay then
            local bx, _, bz = boss.Transform:GetWorldPosition()
            -- (with lanes: 30 round its home instead, each scene 135 degrees on from the last - 55 from where it was,
            -- and never further than 34 from home: the logs parted by place)
            if run.home ~= nil then bx, bz = run.home.x, run.home.z end
            local map = G.TheWorld.Map
            for i = 0, 7 do
                local a = (run.si * 3 + i) * math.pi / 4
                local nx, nz = bx + 30 * math.cos(a), bz + 30 * math.sin(a)
                local yx, yz = nx + 4 * math.cos(a), nz + 4 * math.sin(a)
                if map:IsPassableAtPoint(nx, 0, nz) and map:IsPassableAtPoint(yx, 0, yz) then
                    if boss.Physics ~= nil then boss.Physics:Teleport(nx, 0, nz) else boss.Transform:SetPosition(nx, 0, nz) end
                    Put(p, yx, yz)
                    run.hold = { x = yx, z = yz }
                    -- (its gate with it: the atrium's Fuelweaver out of its arena (atrium_gate.lua:26, 14.55 either
                    -- way) is killed by its brain at once (stalkerbrain.lua:218 LostAtrium) - struck once, "done",
                    -- 2026-10-19 bench. TR_OLD_GATE: left where it was)
                    local gate = boss._tr_gate
                    if gate ~= nil and gate:IsValid() and not G.rawget(G, "TR_OLD_GATE") then gate.Transform:SetPosition(nx, 0, nz) end
                    Log("moved", string.format(" to=%.2f,%.2f", nx, nz))
                    break
                end
            end
        end
        run.si = run.si + 1
        -- (its health taken down as its scenes go on, and struck by you - what some only do hurt: the
        -- Ancient Guardian's quick leaps (Uncompromising Mode), never once on a bench at full health, the player
        -- met them; the rat's punches when attacked. The rest of its scenes with that)
        -- (stepped down, not once: an eighth of its scenes at full health, then just under each group of the
        -- thresholds bosses' code has (tools/phase_scan.lua: 90, 80/75, 70/67/66, 60/50, 40/35/33/30, 25/20, 10)
        -- - each phase gone through in turn, with scenes of its own, as a fight does; once at 40% left
        -- the rest untried, the player asking "all of them?")
        -- (each boss its own levels: just under each threshold its code has (PHASE_LEVELS, tools/phase_scan.lua);
        -- one with none read, .5 and .2 all the same - code no scan reads)
        local th = PHASE_LEVELS[boss.prefab] or { .5, .2 }
        local levels = {}
        for _, v in ipairs(th) do if v - .03 > .02 then levels[#levels + 1] = v - .03 end end
        -- (how far through: its scenes, or its time - whichever is further: slow ones (the Celestial Champion,
        -- the Twins) ran out of time 2-11 scenes short of the last steps and the bringing down, 2026-10-19)
        local frac = math.max((run.si - 1) / math.max(1, #run.scen), (G.GetTime() - run.boss_t0) / (BOSS_MINUTES * 60 * .9))
        local step = math.floor(math.min(1, frac) * (#levels + 1))
        if levels[step] ~= nil and run.hurt ~= step then
            run.hurt = step
            local h = boss.components.health
            local pct = levels[step]
            -- (as a blow does, its health falling across each threshold: DoDelta, not SetPercent - which sets the
            -- value first, its healthdelta then old == new (components/health.lua:550-553, :614), no
            -- healthtrigger ever fired (healthtrigger.lua:28-29): Bee Queen, Klaus, Dragonfly... never changed
            -- phase - the reviewer, 2026-10-19. Invincible and armour passed by; what it reached said)
            if h ~= nil and (h:GetPercent() or 1) > pct then
                if OLD_SETPERCENT then G.pcall(function() h:SetPercent(pct) end)
                else G.pcall(function() h:DoDelta(pct * h.maxhealth - h.currenthealth, nil, "testbench", true, nil, true) end) end
            end
            local p = run.player
            -- (struck for real - the rat goes on the offence only once it's taken over 100 in 2 s
            -- (uncompromising_buffrat.lua:44-66): half what it has left, at most 150 - not to kill it)
            -- (once, the first step: struck each step, a small one fell below the next level early)
            if step == 1 and p ~= nil and boss.components.combat ~= nil and h ~= nil then
                local dmg = math.min(150, (h.currenthealth or 0) * .5)
                G.pcall(function() boss.components.combat:GetAttacked(p, dmg) end)
            end
            Log("hurt", string.format(" n=%d to %d%% - it has %d%%", run.si, math.floor(pct * 100 + .5),
                h ~= nil and math.floor((h:GetPercent() or 0) * 100 + .5) or -1))
        elseif not OLD_ONEHIT and run.player ~= nil and boss.components.combat ~= nil and boss.components.health ~= nil
            and not boss.components.health:IsDead() then
            -- (and struck lightly between each of its moves, as a player does all fight long: what it does only
            -- struck - the rat's leap and taunt below half (SGuncompromising_buffrat.lua:403-406, 450-451), once
            -- only at the first step, 2026-10-19 smoke: 1 each)
            -- (every 8th, hard (150, at most a tenth of it): what answers only a heavy blow - the rat out of its
            -- guard on over 100 in 2 s (uncompromising_buffrat.lua:44-66), then its taunt2: once on the smoke.
            -- Its health put back with SetPercent - that fires no threshold (health.lua:550-553), its step kept)
            local h = boss.components.health
            if run.si % 8 == 0 then
                local before = h:GetPercent()
                G.pcall(function() boss.components.combat:GetAttacked(run.player, math.min(150, h.maxhealth * .1)) end)
                if not h:IsDead() then G.pcall(function() h:SetPercent(before) end) end
            else
                G.pcall(function() boss.components.combat:GetAttacked(run.player, 1) end)
            end
        end
        -- (its scenes done: down to nothing once - one that goes on as another (the Celestial Champion's forms, at
        -- their least health: alterguardian_phase1.lua:602) shows it, and is followed (Tick: "next phase"), its
        -- own scenes from the start; a boss that only dies, done)
        if (run.si > #run.scen or frac >= 1) and not run.killed then
            run.killed = true
            local h = boss.components.health
            if h ~= nil then
                G.pcall(function() h:DoDelta(-h.currenthealth, nil, "testbench", true, nil, true) end)
                Log("brought down", string.format(" it has %d%%", math.floor((h:GetPercent() or 0) * 100 + .5)))
            end
            run.si = #run.scen
            run.kill_t = G.GetTime()
            return
        end
        if run.si > #run.scen then run.hurt = nil NextBoss() end
    end
end

-- (each lane in turn, run its own)
local function Tick()
    if LANES == nil then return TickLane() end
    for _, ln in ipairs(LANES) do
        if LANES == nil then return end
        if not ln.done then
            run = ln
            TickLane()
        end
    end
end

local function Start(here, who, lag)
    local p, world = who or G.ThePlayer, G.TheWorld
    if p == nil or world == nil then return end
    if not world.ismastersim then Say("Testbench: only while you host") return end
    if here then
        -- (the nearest boss round you, at its home - its trees, its pillars, its sea as they are)
        local x, y, z = p.Transform:GetWorldPosition()
        local best, bd = nil, math.huge
        for _, e in ipairs(G.TheSim:FindEntities(x, y, z, HERE_RANGE, { "_combat" }, { "player", "INLIMBO" })) do
            if e:HasTag("epic") or e:HasTag("largecreature") then
                local d = e:GetDistanceSqToPoint(x, y, z)
                if d < bd then best, bd = e, d end
            end
        end
        if best == nil then Say("Testbench: no boss within " .. HERE_RANGE) return end
        run = { player = p, li = 0, here = true, ticks = {} }
        G.TheSim:SetTimeScale(SPEED)
        run.task = G.TheWorld:DoPeriodicTask(0, Tick)
        run.boss, run.scen, run.si, run.quiet, run.boss_t0 = best, Scenarios(), 1, 0, G.GetTime()
        Log("begin here", string.format(" rounds=%d scenarios=%d", ROUNDS, #run.scen))
        local bx, _, bz = best.Transform:GetWorldPosition()
        if not world.Map:IsPassableAtPoint(bx, 0, bz) and not p:HasTag("tmir_waterwalk") then
            Say("Testbench: " .. tostring(best.prefab) .. " - it's at sea: turn on TMIR water walking, or scenes off the boat won't run")
        else
            Say("Testbench: " .. tostring(best.prefab) .. " where it is")
        end
        return
    end
    run = { player = p, li = 0, ticks = {}, dummy = who ~= nil and not lag, lag = lag }
    G.TheSim:SetTimeScale(SPEED)
    run.task = G.TheWorld:DoPeriodicTask(0, Tick)
    Log("begin", string.format(" rounds=%d bosses=%d", ROUNDS, #LIST))
    NextBoss()
end

local function Stop()
    if run == nil then return end
    Log("stopped")
    -- (one brought in, taken away; one at its home, left there)
    if not run.here and run.boss ~= nil and run.boss:IsValid() then run.boss:Remove() end
    if run.player.components.health ~= nil then run.player.components.health:SetInvincible(false) end
    run.task:Cancel()
    G.TheSim:SetTimeScale(1)
    run = nil
    Say("Testbench: stopped")
end

-- (a stand-in for you on a server with no one on: a body your size that can be struck - tagged as a
-- player, so what goes only for players goes for it; True Range traces it as "you" (TR_BENCH_YOU); each
-- blow on it said as True Range says one on you, for the replays and tools/bench_lock.lua)
MakeStandIn = function(x, z)
    local inst = G.CreateEntity()
    inst.entity:AddTransform()
    -- (an AnimState too, though nothing's drawn: the Twins' laser hit reaches for its target's)
    inst.entity:AddAnimState()
    -- (a body that can play and sound, as yours: a monster's blow plays its target's hit and sounds on it -
    -- with no bank or build, nor any sound, the server went down with no Lua error at all, the log
    -- ending on the blow (warg, warglet, pied rat, Hooded Widow))
    inst.entity:AddSoundEmitter()
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wilson")
    inst.AnimState:PlayAnimation("idle_loop", true)
    -- (networked, as you are: without, the game's own searches for whom to go after never found it - the
    -- Eye of Terror and a tentacle idle by it all along. The warg's crash was its being a player, not this)
    inst.entity:AddNetwork()
    G.MakeCharacterPhysics(inst, 75, .5)
    inst.prefab = "wilson"
    inst:AddTag("player")
    inst:AddTag("character")
    inst:AddTag("scarytoprey")
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(100000)
    -- (never dead: struck, every blow felt as by you - but not killed outright, eroded away and gone, the
    -- bench left with no one (sharkboi, the vault guard - whatever took 100000 at once))
    -- (not with SetMinHealth: a monster takes one it can't bring down for no target at all - not one
    -- attacked it again, warg and hound alike; its health only kept from 0 below the game's eyes)
    local health = inst.components.health
    local set_val = health.SetVal
    health.SetVal = function(self, val, ...) return set_val(self, math.max(val, 1), ...) end
    inst:AddComponent("combat")
    -- (pockets, as you have: Uncompromising Mode's tornado reaches into its target's inventory - none at
    -- all, an error every tick and the server down (Lua, um_tornado.lua:285))
    inst:AddComponent("inventory")
    -- (legs, as you have: a "dig" blow kills whatever has none outright, struck as you'd be only if it has
    -- (SGsharkboi:208, SGvault_pillar_guard:202, root/sand/fossil spikes) - never a STRIKE, 133 of
    -- sharkboi's 141 drawn-in-not-struck so, 2026-10-18; never set walking - put where it's meant each tick)
    local loco = inst:AddComponent("locomotor")
    loco.walkspeed, loco.runspeed = 4, 6
    -- (and what webs stick to, as you have: Uncompromising Mode's web bomb sticks every player it lands by
    -- (web_bomb.lua:251) - none, a Lua error each, the Hooded Widow's server down; unstuck each tick below)
    inst:AddComponent("pinnable")
    -- (and followers, as you have: Uncompromising Mode's viperling friend takes the player by it as it's made
    -- (viperworm.lua:378 person.components.leader:AddFollower) - none, a Lua error and the server down at once,
    -- every lane with it, 2026-10-19)
    inst:AddComponent("leader")
    -- (and frozen and set alight, as you are: none, the Klaus deer's ice circle froze the player outside what was drawn and no
    -- bench ever saw it - a freeze, a fire no blow ("attacked"), 2026-10-27. Each told as the thing nearest that does it struck
    -- you ([tr_haz] HIT - tests/replay_haz.lua judges it as any thing's blow), and what it was ([tr_eff]). Put out a second on:
    -- burning on and on, its fire's hurt every tick. TR_BENCH_OLD_EFFECTS: none, as before)
    if G.rawget(G, "TR_BENCH_OLD_EFFECTS") == nil then
        inst:AddComponent("freezable")
        if G.MakeMediumBurnableCharacter ~= nil then G.MakeMediumBurnableCharacter(inst, "torso") end
        local function Told(kind)
            if inst._tr_quiet then return end
            local yx, _, yz = inst.Transform:GetWorldPosition()
            -- (with a blow that same tick - a fire hound's bite sets you alight: that blow is judged ([tr_hit]); not the nearest
            -- thing's too - a fire lying by, struck "undrawn" for the bite, 60 so, 2026-10-27)
            if inst._tr_blow_t == G.GetTime() then
                print(string.format("[tr_eff] %.3f %s with a blow pos=%.2f,%.2f", G.GetTime(), kind, yx, yz))
                return
            end
            local ok, SM = G.pcall(G.require, "true_range/simmoves")
            local H = ok and SM.Hazards ~= nil and SM.Hazards() or {}
            local best, bd = nil, 6 * 6
            for _, e in ipairs(G.TheSim:FindEntities(yx, 0, yz, 6)) do
                if e ~= inst and H[e.prefab] ~= nil then
                    local d = inst:GetDistanceSqToInst(e)
                    if d < bd then best, bd = e, d end
                end
            end
            -- (once a half second of each kind - a fire lying on you sets you alight every frame, put out at once)
            inst._tr_eff_t = inst._tr_eff_t or {}
            if G.GetTime() - (inst._tr_eff_t[kind] or -1) < .5 then return end
            inst._tr_eff_t[kind] = G.GetTime()
            -- (where: tools/lane_split.lua puts each line in the lane it's nearest - none, it went to every lane)
            print(string.format("[tr_eff] %.3f %s by %s pos=%.2f,%.2f", G.GetTime(), kind, best ~= nil and best.prefab or "?", yx, yz))
            if best ~= nil then
                local x, _, z = best.Transform:GetWorldPosition()
                print(string.format("[tr_haz] %.3f %s guid=%d HIT pos=%.2f,%.2f you=%.2f,%.2f", G.GetTime(), best.prefab, best.GUID, x, z, yx, yz))
            end
            -- (and as its boss's strike, by that thing (or by nothing traced): judged by what the boss drew - its move or its things
            -- (tests/replay.lua) - a thing's "missed" it drew taken back (ASBOSS_DRAWN): the Wilting Dragonfly's pound, its outer
            -- ring setting you alight with no blow, its splash's own shape not reaching there, 52 so, 2026-10-27)
            local ln = inst._tr_lane or run
            local boss = ln ~= nil and ln.boss or nil
            if ok and SM._trace_line ~= nil and boss ~= nil and boss:IsValid() and inst:GetDistanceSqToInst(boss) < 30 * 30 then
                G.pcall(SM._trace_line, boss, "STRIKE by " .. (best ~= nil and best.prefab or ("effect_" .. kind:gsub(" ", "_"))) .. " at " .. tostring(inst.prefab))
            end
        end
        inst:ListenForEvent("freeze", function() Told("frozen") end)
        -- (put out at once: burning on, its fire hurt you every tick - each a "fire" hurt tests/replay_haz.lua took for one on the ground)
        inst:ListenForEvent("onignite", function()
            Told("set alight")
            inst:DoTaskInTime(0, function() if inst.components.burnable ~= nil then inst.components.burnable:Extinguish() end end)
        end)
    end
    inst.persists = false
    -- (a stategraph of sorts: what reaches into yours - Moonmaw's lavae knocking you about (v.sg:...) - finds
    -- one that never changes state and has no tags; with none at all, an error every tick brought the server down)
    local noop = function() end
    inst.sg = G.setmetatable({ currentstate = { name = "idle" }, statemem = {}, mem = {}, tags = {}, timeinstate = 0,
        HasStateTag = function() return false end, HasAnyStateTag = function() return false end,
        GoToState = noop, AddStateTag = noop, RemoveStateTag = noop, GetTimeInState = function() return 0 end },
        { __index = function() return noop end })
    inst.Transform:SetPosition(x, 0, z)
    -- (gone - by what: its last words, with where they came from (the bench's task on the world, not on
    -- it - it went with the stand-in, the bench stopped dead with the server running on))
    inst:ListenForEvent("onremove", function()
        local ds = G.rawget(G, "debugstack")
        print(string.format("[tr_bench] %.3f - stand-in removed%s", G.GetTime(), ds ~= nil and ("\n" .. ds()) or ""))
    end)
    -- (and every loss of health, whatever the cause - fire burns straight on health, no blow ("attacked")
    -- at all: a magma hound's fire on the ground, never seen striking - tools/bench_things.lua)
    inst:ListenForEvent("healthdelta", function(_, data)
        if data == nil or (data.newpercent or 1) >= (data.oldpercent or 0) then return end
        -- (not the one True Range isn't watching, with a friend about: its blows aren't "you")
        if inst._tr_quiet then return end
        local by = data.afflicter
        local yx, _, yz = inst.Transform:GetWorldPosition()
        local ax, az = -1e9, -1e9
        if by ~= nil and by.IsValid ~= nil and by:IsValid() and by.Transform ~= nil then local x, _, z = by.Transform:GetWorldPosition() ax, az = x, z end
        print(string.format("[tr_hurt] %.3f %s %d %.2f %.2f you %.2f %.2f cause=%s", G.GetTime(), by ~= nil and tostring(by.prefab) or "?",
            by ~= nil and by.GUID or 0, ax, az, yx, yz, tostring(data.cause)))
    end)
    for _, ev in ipairs({ "attacked", "blocked" }) do
        inst:ListenForEvent(ev, function(_, data)
            inst._tr_blow_t = G.GetTime()
            if inst._tr_quiet then return end
            local by = data ~= nil and data.attacker or nil
            local d = by ~= nil and by:IsValid() and math.sqrt(inst:GetDistanceSqToInst(by)) or -1
            print(string.format("[true_range] you were struck%s by %s, %.2f from it - drawn: ?", ev == "blocked" and " (blocked)" or "",
                by ~= nil and tostring(by.prefab) or "?", d))
            -- (and who, where it and you were - tools/bench_things.lua)
            local yx, _, yz = inst.Transform:GetWorldPosition()
            local ax, az = -1e9, -1e9
            if by ~= nil and by:IsValid() then local x, _, z = by.Transform:GetWorldPosition() ax, az = x, z end
            print(string.format("[tr_hit] %.3f %s %d %.2f %.2f you %.2f %.2f", G.GetTime(), by ~= nil and tostring(by.prefab) or "?",
                by ~= nil and by.GUID or 0, ax, az, yx, yz))
            -- (struck by a thing True Range draws (its _hazards), as its boss's strike by that thing too: judged by what the boss drew
            -- as well as the thing's own shape (tests/replay.lua ASBOSS_DRAWN) - Retinazer's laser striking the tick it was made, at
            -- its mouth, its lane drawn by its move, 3 "missed" as a thing, 2026-10-28. TR_BENCH_OLD_THINGSTRIKE: not)
            if G.rawget(G, "TR_BENCH_OLD_THINGSTRIKE") == nil and by ~= nil and by:IsValid() then
                local okt, SMt = G.pcall(G.require, "true_range/simmoves")
                local Ht = okt and SMt.Hazards ~= nil and SMt.Hazards() or {}
                local lnt = inst._tr_lane or run
                local bosst = lnt ~= nil and lnt.boss or nil
                if Ht[by.prefab] ~= nil and SMt._trace_line ~= nil and bosst ~= nil and bosst ~= by and bosst:IsValid()
                    and inst:GetDistanceSqToInst(bosst) < 30 * 30 then
                    G.pcall(SMt._trace_line, bosst, "STRIKE by " .. by.prefab .. " at " .. tostring(inst.prefab))
                end
            end
            -- (struck by the boss or what it brought - born since it: it's at work, even with no scene of its own
            -- begun (the Great Depths Worm's dirt, the Lunar Thrall Plant's vines) - not cut at FIRST_SECS; one
            -- of the world's (a deer) is not it)
            -- (10 of them, not one: a worm stuck by its mound struck once, then nothing the whole hour)
            -- (its own lane's, with lanes - not whichever ran last)
            local ln = inst._tr_lane or run
            if ln ~= nil and ln.guid0 ~= nil and by ~= nil and by.GUID ~= nil and by.GUID >= ln.guid0 then
                ln.thing_hits = (ln.thing_hits or 0) + 1
                -- (and by what, to see one the world brought didn't keep a boss that does nothing the full hour)
                if ln.thing_hits >= 10 and not ln.began then
                    ln.began = true
                    local was = run
                    run = ln
                    Log("began by", " " .. tostring(by.prefab))
                    run = was
                end
            end
        end)
    end
    return inst
end

if HEADLESS then
    -- (Uncompromising Mode's Ram Branch calls a name it never made when a horn linked to it goes
    -- (rambranch.lua:308 OnUnlinkMushroomSprout - its own is OnUnlinkHorn, :296): a Lua error and the server
    -- down each time it died, horns still linked, 2026-10-19 - here as its own would do)
    if G.rawget(G, "OnUnlinkMushroomSprout") == nil then
        G.rawset(G, "OnUnlinkMushroomSprout", function(inst, link)
            if inst._links ~= nil and inst._links[link] ~= nil then
                inst._links[link] = nil
                inst._numlinks = (inst._numlinks or 1) - 1
            end
        end)
    end
    -- (the game's own "nearest player" helpers (simutil.lua) go through AllPlayers - the stand-in isn't one:
    -- Uncompromising Mode's shadow Wes' balloons walked to no one (GetNearestPlayer), popped where they were,
    -- never struck it in 52 scenes. With no one on, AllPlayers is the stand-in for each of those calls alone -
    -- not put in it for good: what goes through every player expects a real one's parts)
    for _, name in ipairs({ "FindClosestPlayerInRangeSq", "FindClosestPlayerOnLandInRangeSq", "FindPlayersInRangeSq",
        "FindPlayersInRangeSqSortedByDistance", "IsAnyPlayerInRangeSq" }) do
        local orig = G.rawget(G, name)
        if orig ~= nil then
            G.rawset(G, name, function(...)
                local you, all = G.rawget(G, "TR_BENCH_YOU"), G.AllPlayers
                if you == nil or not you:IsValid() or all == nil or #all > 0 then return orig(...) end
                -- (with lanes, every lane's - each far from the others, the nearest is its own; with a friend, both)
                G.AllPlayers = G.rawget(G, "TR_BENCH_YOUS") or G.rawget(G, "TR_BENCH_ALL") or { you }
                local ok, a, b = G.pcall(orig, ...)
                G.AllPlayers = all
                if not ok then G.error(a, 0) end
                return a, b
            end)
        end
    end
    -- (each Lua error as the game takes it (_TRACEBACK), written out to a file of its own there and then -
    -- the server brought down after, the log's last lines never written: warg, pied rat, gone with no word)
    do
        local old = G.rawget(G, "_TRACEBACK")
        local io = G.rawget(G, "io")
        if old ~= nil and io ~= nil then
            G._TRACEBACK = function(err)
                local r = old(err)
                G.pcall(function()
                    local fh = io.open("tr_bench_errors.txt", "a")
                    if fh ~= nil then fh:write(string.format("== %.3f\n%s\n", G.GetTime(), tostring(r))) fh:close() end
                end)
                return r
            end
        end
    end
    -- (no one on, so all round goes to sleep - a boss asleep leaves (Deerclops, the Moose gone the tick
    -- they came), what it sets off stops: all made once the bench has begun kept awake - not the whole
    -- world, made before)
    local awake = false
    -- (every thing made once the bench has begun - the world holds nothing else, so each is the boss's
    -- doing: made when and where, gone when and where, an effect only (FX) or one that fights - set
    -- against each blow on the stand-in and who dealt it (tools/bench_things.lua): what really strikes,
    -- and how far; a ring that's only a picture never does)
    local function Where(inst)
        if inst.Transform == nil then return nil end
        local x, _, z = inst.Transform:GetWorldPosition()
        return x, z
    end
    AddPrefabPostInitAny(function(inst)
        if not awake or inst.entity == nil then return end
        inst.entity:SetCanSleep(false)
        local born = G.GetTime()
        -- (something thrown, born in a scene: the scene not over till it's come down - the Moon Tentacle's
        -- spines still up when its throw ended, you put 30 off, landing where you'd been: every one of the
        -- 2,410 drawn-in-not-struck that so, 2026-10-18)
        if LANES == nil and run ~= nil and run.cur ~= nil and inst.components ~= nil
            and (inst.components.complexprojectile ~= nil or inst.components.projectile ~= nil) then
            run.flying = run.flying or {}
            run.flying[inst] = true
        end
        inst:DoTaskInTime(0, function()
            local x, z = Where(inst)
            if x == nil then return end
            -- (with lanes: the lane it was made in, by where - made as the game goes, not in a lane's Tick)
            if LANES ~= nil and inst.components ~= nil and (inst.components.complexprojectile ~= nil or inst.components.projectile ~= nil) then
                local ln, d = LaneOf(x, z)
                if ln ~= nil and ln.cur ~= nil and d < LANE_GAP / 2 then
                    ln.flying = ln.flying or {}
                    ln.flying[inst] = true
                end
            end
            print(string.format("[tr_ent] %.3f born %s %d %.2f %.2f fx=%d combat=%d", born, tostring(inst.prefab), inst.GUID, x, z,
                inst:HasTag("FX") and 1 or 0, inst.components.combat ~= nil and 1 or 0))
            -- (lag mode: whom each one goes for as it begins an attack - drawn at you, struck someone else? UM's aphids
            -- leaping "drawn IN but NOT struck" 41 times by Klaus, 2026-10-26)
            if LAG_MODE and inst.sg ~= nil and inst.components ~= nil and inst.components.combat ~= nil then
                inst:ListenForEvent("newstate", function(_, data)
                    -- (and a charge - the Eye of Terror's charge_pre carries "charge", not "attack")
                    if data == nil or inst.sg == nil or not (inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("charge")) then return end
                    local tgt = inst.components.combat.target
                    local ax, az = Where(inst)
                    local tx, tz = nil, nil
                    if tgt ~= nil and tgt:IsValid() then tx, tz = Where(tgt) end
                    print(string.format("[tr_lag] %.3f atk %s %d state=%s at %.2f %.2f target=%s %s %s", G.GetTime(), tostring(inst.prefab), inst.GUID,
                        tostring(data.statename), ax or 0, az or 0, tgt ~= nil and tostring(tgt.prefab) or "-",
                        tx ~= nil and string.format("%.2f", tx) or "-", tz ~= nil and string.format("%.2f", tz) or "-"))
                end)
            end
        end)
        inst:ListenForEvent("onremove", function()
            local x, z = Where(inst)
            if x ~= nil then print(string.format("[tr_ent] %.3f gone %s %d %.2f %.2f", G.GetTime(), tostring(inst.prefab), inst.GUID, x, z)) end
        end)
    end)
    AddPrefabPostInit("world", function(w)
        if not w.ismastersim then return end
        w:DoTaskInTime(5, function()
            local portal = G.TheSim:FindFirstEntityWithTag("multiplayer_portal")
            local x, z = 0, 0
            if portal ~= nil then
                local px, _, pz = portal.Transform:GetWorldPosition()
                x, z = px + 15, pz
            end
            awake = true
            -- (its share of the list, run side by side with others (a server runs on one core): named in
            -- its cluster's name - "tr_bench:deerclops,moose"; none named, the whole list)
            local name = G.TheNet.GetServerName ~= nil and G.TheNet:GetServerName() or ""
            -- ("tr_bench+friend:..." / "tr_bench+watch:...": a friend beside you - FRIEND_MODE)
            FRIEND_MODE = name:match("^tr_bench[^:]*%+(friend)") or name:match("^tr_bench[^:]*%+(watch)")
            LAG_MODE = name:match("^tr_bench[^:]*%+lag") ~= nil
            name = name:gsub("%+%a+", "")
            -- ("tr_bench@4:a,b,c,d": four at once, each in a lane of its own)
            -- ("tr_bench@8g150:...": eight, homes 150 apart at least)
            local nl, gap, share = name:match("^tr_bench@(%d+)g?(%d*):(.+)$")
            if share == nil then share = name:match("^tr_bench:(.+)$") end
            nl = G.tonumber(nl) or 1
            if G.tonumber(gap) ~= nil then LANE_GAP = G.tonumber(gap) end
            -- ("...:@list": the list in tr_list.txt beside this file - a long one in the server's name, 24 bosses, and
            -- your game couldn't join it (direct connection timed out, twice), 2026-10-27; tools/run_lag.ps1)
            -- (a file read nothing on the dedicated server - the default list run instead; its mod setting "list" then)
            if share == "@list" then
                local l = GetModConfigData("list")
                share = (type(l) == "string" and l ~= "") and l or nil
                print(string.format("[tr_bench] - list from the setting: %s", tostring(share)))
            end
            if share ~= nil then
                LIST = {}
                for p in share:gmatch("[%w_!]+") do LIST[#LIST + 1] = p end
            end
            if nl > 1 then
                -- (the homes: the start, then each the passable spot furthest from those taken, ground all round it
                -- out to LANE_ROOM, LANE_GAP apart at least - fewer if the world has no room)
                local map = G.TheWorld.Map
                local function Good(hx, hz)
                    if not map:IsPassableAtPoint(hx, 0, hz) then return false end
                    for k = 0, 7 do
                        local a = k * math.pi / 4
                        for _, r in ipairs({ 30, LANE_ROOM }) do
                            if not map:IsPassableAtPoint(hx + r * math.cos(a), 0, hz + r * math.sin(a)) then return false end
                        end
                    end
                    return true
                end
                local w, h = map:GetSize()
                local half = math.max(w, h) * 2
                local cands = {}
                for gx = -half, half, 40 do for gz = -half, half, 40 do if Good(gx, gz) then cands[#cands + 1] = { x = gx, z = gz } end end end
                local homes = { { x = x, z = z } }
                while #homes < nl do
                    local best, bd = nil, -1
                    for _, c in ipairs(cands) do
                        local md = math.huge
                        for _, hm in ipairs(homes) do md = math.min(md, (c.x - hm.x) ^ 2 + (c.z - hm.z) ^ 2) end
                        if md > bd then best, bd = c, md end
                    end
                    if best == nil or bd < LANE_GAP ^ 2 then break end
                    homes[#homes + 1] = best
                end
                LANES = {}
                local yous = {}
                for k, hm in ipairs(homes) do
                    local gone = 0
                    for _, e in ipairs(G.TheSim:FindEntities(hm.x, 0, hm.z, 60, { "_combat" })) do
                        if e:IsValid() and e.components.health ~= nil and not e:HasTag("player") and not e:HasTag("wall") then
                            gone = gone + 1
                            e:Remove()
                        end
                    end
                    local you = MakeStandIn(hm.x, hm.z)
                    you.entity:SetCanSleep(false)
                    local ln = { player = you, li = 0, ticks = {}, dummy = true, home = hm, k = k }
                    you._tr_lane = ln
                    LANES[k], yous[k] = ln, you
                    print(string.format("[tr_lane] %.3f - lane=%d home=%.2f,%.2f cleared=%d of %d asked, %d spots", G.GetTime(), k, hm.x, hm.z, gone, nl, #cands))
                end
                G.rawset(G, "TR_BENCH_YOUS", yous)
                G.rawset(G, "TR_BENCH_YOU", yous[1])
                G.TheSim:SetTimeScale(SPEED)
                local task = G.TheWorld:DoPeriodicTask(0, Tick)
                for _, ln in ipairs(LANES) do ln.task = task end
                print(string.format("[tr_bench] %.3f - begin rounds=%d bosses=%d lanes=%d", G.GetTime(), ROUNDS, #LIST, #LANES))
                for _, ln in ipairs(LANES) do
                    run = ln
                    NextBoss()
                end
                return
            end
            -- (the ground cleared first: every creature that fights, 60 round - the world made before held an
            -- Eye of Terror and a Treeguard left from a test in the game, 6 and 15 from here: every monster
            -- since went for the Eye, not the stand-in - a warg's blows all on it, the Eye tested beside itself)
            local gone = 0
            for _, e in ipairs(G.TheSim:FindEntities(x, 0, z, 60, { "_combat" })) do
                if e:IsValid() and e.components.health ~= nil and not e:HasTag("player") and not e:HasTag("wall") then
                    gone = gone + 1
                    e:Remove()
                end
            end
            print(string.format("[tr_bench] %.3f - cleared %d creatures round the start", G.GetTime(), gone))
            -- (lag mode: no stand-in - the player who joins (below, AddPlayerPostInit))
            if LAG_MODE then
                LAG_START = { x = x, z = z }
                print(string.format("[tr_bench] %.3f - lag: waiting for a player at %.2f,%.2f", G.GetTime(), x, z))
                return
            end
            local you = MakeStandIn(x, z)
            you.entity:SetCanSleep(false)
            G.rawset(G, "TR_BENCH_YOU", you)
            print(string.format("[tr_bench] %.3f - headless stand-in at %.2f,%.2f", G.GetTime(), x, z))
            if FRIEND_MODE ~= nil then
                FRIEND = MakeStandIn(x + FRIEND_OFF, z)
                FRIEND.entity:SetCanSleep(false)
                G.rawset(G, "TR_BENCH_ALL", { you, FRIEND })
                if FRIEND_MODE == "watch" then
                    G.rawset(G, "TR_BENCH_YOU", FRIEND)
                    you._tr_quiet = true
                else
                    FRIEND._tr_quiet = true
                end
                print(string.format("[tr_bench] %.3f - friend (%s) at %.2f,%.2f", G.GetTime(), FRIEND_MODE, x + FRIEND_OFF, z))
            end
            Start(false, you)
        end)
    end)
    -- (lag mode: the player in from their own game - put at the start, begun a moment after; each blow on them told
    -- to their game, where True Range sets it beside what it drew; gone, the server down)
    AddPlayerPostInit(function(p)
        p:DoTaskInTime(3, function()
            if not LAG_MODE or LAG_START == nil or run ~= nil or not p:IsValid() then return end
            Put(p, LAG_START.x, LAG_START.z)
            -- (and hurt with no blow by one that's after you - the Mind Weaver's grab, health:DoDelta(-40, ..., inst) and no
            -- "attacked" (SGmindweaver Grabby): told as struck, none counted, "false 1", lag 2026-10-31_0936. Looked at the
            -- tick after - a blow's own DoDelta comes before its "attacked". Taken even while you can't be hurt (DoDelta wrapped,
            -- before its invincible check). TR_BENCH_OLD_DELTA: not)
            local h = p.components.health
            if h ~= nil and G.rawget(G, "TR_BENCH_OLD_DELTA") == nil then
                local DoDelta0 = h.DoDelta
                h.DoDelta = function(self, amount, overtime, cause, ignore_invincible, afflicter, ...)
                    if amount ~= nil and amount < 0 and not overtime then
                        local who = afflicter
                        -- (no afflicter, its name as the cause: the Mind Weaver's grab gives itself one place on - DoDelta(-40, false,
                        -- inst.prefab, false, nil, inst): the nearest of that name, 8 round)
                        if who == nil and type(cause) == "string" then
                            local px, _, pz = p.Transform:GetWorldPosition()
                            local bd = 64
                            for _, e in ipairs(G.TheSim:FindEntities(px, 0, pz, 8)) do
                                if e.prefab == cause and e ~= p then
                                    local d = p:GetDistanceSqToInst(e)
                                    if d < bd then who, bd = e, d end
                                end
                            end
                        end
                        if who ~= nil and who ~= p and who.IsValid ~= nil and who:IsValid() and who.Transform ~= nil and not who:HasTag("player") then
                            local t = G.GetTime()
                            p:DoTaskInTime(0, function()
                                if (p._tr_blow_t ~= nil and p._tr_blow_t >= t) or not who:IsValid() then return end
                                local ax, _, az = who.Transform:GetWorldPosition()
                                local yx, _, yz = p.Transform:GetWorldPosition()
                                print(string.format("[tr_lag] %.3f srv struck by %s %.2f %.2f you %.2f %.2f with health %s", t, tostring(who.prefab), ax, az, yx, yz, tostring(cause)))
                                ToClient(p, "struck", tostring(who.prefab), ax, az, yx, yz, t, 0)
                            end)
                        end
                    end
                    return DoDelta0(self, amount, overtime, cause, ignore_invincible, afflicter, ...)
                end
            end
            for _, ev in ipairs({ "attacked", "blocked" }) do
                p:ListenForEvent(ev, function(_, data)
                    p._tr_blow_t = G.GetTime()
                    local by = data ~= nil and data.attacker or nil
                    local ax, az = -1e9, -1e9
                    if by ~= nil and by:IsValid() and by.Transform ~= nil then local bx, _, bz = by.Transform:GetWorldPosition() ax, az = bx, bz end
                    local yx, _, yz = p.Transform:GetWorldPosition()
                    -- (and what it struck with, where - the Shrouded Queen's vines, minions: struck "by" her, from afar)
                    local wpn, wx, wz = data ~= nil and data.weapon or nil, -1e9, -1e9
                    if wpn ~= nil and wpn.IsValid ~= nil and wpn:IsValid() and wpn.Transform ~= nil then local qx, _, qz = wpn.Transform:GetWorldPosition() wx, wz = qx, qz end
                    print(string.format("[tr_lag] %.3f srv struck%s by %s %.2f %.2f you %.2f %.2f with %s %.2f %.2f", G.GetTime(), ev == "blocked" and " (blocked)" or "",
                        by ~= nil and tostring(by.prefab) or "?", ax, az, yx, yz, wpn ~= nil and tostring(wpn.prefab) or "-", wx, wz))
                    ToClient(p, "struck", by ~= nil and tostring(by.prefab) or "?", ax, az, yx, yz, G.GetTime(), ev == "blocked" and 1 or 0)
                    -- (by a thing True Range draws (its _hazards) - itself or what it struck with: as the headless bench's [tr_haz] HIT,
                    -- for tests/replay_haz.lua to judge the lag bench's things as a player's game sees them (CLIENT) - none told, its
                    -- client mode could not be checked against the real one, 2026-10-27)
                    local okh, SMh = G.pcall(G.require, "true_range/simmoves")
                    local H = okh and SMh.Hazards ~= nil and SMh.Hazards() or {}
                    local th = (by ~= nil and H[by.prefab] ~= nil and by) or (wpn ~= nil and H[wpn.prefab] ~= nil and wpn) or nil
                    if th ~= nil and th:IsValid() then
                        local hx, _, hz = th.Transform:GetWorldPosition()
                        print(string.format("[tr_haz] %.3f %s guid=%d HIT pos=%.2f,%.2f you=%.2f,%.2f", G.GetTime(), th.prefab, th.GUID, hx, hz, yx, yz))
                    end
                end)
            end
            p:ListenForEvent("onremove", function()
                print(string.format("[tr_bench] %.3f - lag: the player left", G.GetTime()))
                local shut = G.rawget(G, "c_shutdown")
                if shut ~= nil then G.TheWorld:DoTaskInTime(1, function() shut(false) end) end
            end)
            -- (day all along: a real player in the dark is struck by the dark itself)
            G.TheWorld:PushEvent("ms_setclocksegs", { day = 16, dusk = 0, night = 0 })
            print(string.format("[tr_bench] %.3f - lag: player %s in", G.GetTime(), tostring(p.prefab)))
            Start(false, p, true)
        end)
    end)
else
    G.TheInput:AddKeyDownHandler(KEY, function()
        local frontend = G.TheFrontEnd
        if frontend == nil or frontend.textProcessorWidget ~= nil then return end
        local screen = frontend:GetActiveScreen()
        if screen == nil or screen.name ~= "HUD" then return end
        if run == nil then Start(G.TheInput:IsKeyDown(G.KEY_SHIFT)) else Stop() end
    end)
end
