-- True Range: rings on the ground showing how far monsters (and you) really reach.
-- The server knows the real numbers (players' games only get a few of them), so each
-- player's game asks it about what it shows, and draws the rings.

Assets = {
    Asset("ANIM", "anim/firefighter_placement.zip"),
    -- the mod's own white shapes (square, disc, wedge): source in true_range_workshop\art,
    -- built with the Mod Tools' scml.exe
    Asset("ANIM", "anim/trshapes.zip"),
    -- (every move's shape, drawn ahead of time - true_range_workshop/tools/silhouettes.lua)
    Asset("ANIM", "anim/trsil.zip"),
}

-- debugging - the testing logs (client_log.txt), keys and chat notes: only with a file debug.txt in
-- the mod's folder (put one there to have them back; TR_DEBUG for the mod's other files)
-- (opened as well: the game's own file check said no to one there, put in after it began)
-- (the game's file check answers true on some builds, 1 on others - a player's report, 2026-10-18; never 0 or nil for one there)
local function FileThere(path)
    local ok, r = GLOBAL.pcall(GLOBAL.kleifileexists, path)
    return ok and (r == true or r == 1)
end
local DEBUG = FileThere(MODROOT .. "debug.txt")
if not DEBUG and GLOBAL.io ~= nil then
    local ok, fh = GLOBAL.pcall(GLOBAL.io.open, MODROOT .. "debug.txt", "r")
    if ok and fh ~= nil then DEBUG = true fh:close() end
end
if DEBUG then GLOBAL.rawset(GLOBAL, "TR_DEBUG", true) end
-- the client-only build (True Range (Client) - client_only.txt in its folder, tools/install_client.ps1): for
-- servers without the mod - nothing asked of or sent by a server; reach read from what every game sees
-- (the combat's attack range, the weapon held); no poses, aims or cooldowns from the server
-- (or its modinfo saying it's a client mod - the file left out on its way to the Workshop, it took itself
-- for the server build: every few seconds an RPC to a server without the mod, "Error decoding lua RPC mod
-- namespace" filling that server's log - a player's report, 2026-10-18)
local CLIENT_ONLY = FileThere(MODROOT .. "client_only.txt")
    or (type(modinfo) == "table" and modinfo.client_only_mod == true)
-- (the server build here too - the server has True Range: the client build steps aside, both drawing at once
-- otherwise; TR_SERVER_BUILD, looked at once you're in, when both have loaded)
if not CLIENT_ONLY then GLOBAL.rawset(GLOBAL, "TR_SERVER_BUILD", true) end
local function StepAside() return CLIENT_ONLY and GLOBAL.rawget(GLOBAL, "TR_SERVER_BUILD") == true end

local TheNet = GLOBAL.TheNet
local TheInput = GLOBAL.TheInput
-- (testing, to be removed: the game's clock when "." asked for one tick on - see below)
local step_from = nil
-- (testing, to be removed: you were moved while paused - the pause report said again)
local warped = false

-- (monsters a mod changes or adds - Uncompromising Mode's: their moves over the game's, when it's
-- on - before anything reads them: true_range/moddata)
do
    local applied = GLOBAL.require("true_range/moddata").Apply(function(name)
        return GLOBAL.KnownModIndex ~= nil and GLOBAL.KnownModIndex:IsModEnabledAny(name) and true or false
    end)
    if DEBUG and #applied > 0 then print("[true_range] moves of mods: " .. table.concat(applied, ", ")) end
end

local Rings = GLOBAL.require("true_range/rings")
local Telegraph = GLOBAL.require("true_range/telegraph")
local Lines = GLOBAL.require("true_range/lines")
local Predict = GLOBAL.require("true_range/predict")
local Render = GLOBAL.require("true_range/render")
-- (which moves data this game runs on - its hash, written as it's installed: told from a log)
do
    local ok, id = GLOBAL.pcall(GLOBAL.require, "true_range/data_id")
    if DEBUG then print("[true_range] data " .. (ok and GLOBAL.tostring(id) or "unknown")) end
end

-- how many things one question asks about, and how often an answer is asked again (ranges
-- change: a monster picks up a weapon, a boss changes phase)
local ASK_BATCH = 8
local ASK_AGAIN = 1
-- an answer older than this isn't drawn any more (the thing went out of sight, say)
local FORGET_AFTER = 5
-- how far around you monsters are looked at
local NEAR = 24
-- (a boss run offline: from this far - its longest charge reaches you from there)
local SIM_FAR = 40
-- how often what's shown is worked out again (the rings follow every frame)
local PICK_EVERY = .2

--------------------------------------------------------------------------------
-- server: answering

local RangesLib = GLOBAL.require("true_range/ranges")
local Learn = GLOBAL.require("true_range/learn")
local Ranges = TheNet:GetIsServer() and RangesLib or nil

local OnRanges -- (player side, below)

local function Reply(player, ent, r)
    if player == GLOBAL.ThePlayer then
        OnRanges(ent, r.attack, r.hit, r.area, r.radius, r.harmful, r.pound, r.specials, r.waves, r.pound_ready, r.pound_cd,
            Learn.Version(ent.prefab), r.cds)
    else
        SendModRPCToClient(GetClientModRPC("true_range", "ranges"), player.userid, ent, r.attack, r.hit, r.area, r.radius,
            r.harmful, r.pound, r.specials, r.waves, r.pound_ready, r.pound_cd, Learn.Version(ent.prefab), r.cds)
    end
end

local function OnAsk(player, ...)
    if Ranges == nil or player == nil then
        return
    end
    local n = GLOBAL.select("#", ...)
    for i = 1, math.min(n, ASK_BATCH) do
        local ent = GLOBAL.select(i, ...)
        if type(ent) == "table" and ent.IsValid ~= nil and ent:IsValid() then
            local r = Ranges.Of(ent)
            if r ~= nil then
                Reply(player, ent, r)
            end
        end
    end
end

-- (registered on the server and every player alike, in the same order)
-- (once only: a second True Range in the same game - the client build beside the Workshop's, or a local copy - adding
-- its own after the first's numbered them on, "ask" 3 and "learnask" 4 on that player's side, the server having
-- 1 and 2: "Invalid RPC code: true_range 3" in the host's log every few frames, a friend in, 2026-10-22. The client
-- build sends none; a second copy uses the first's)
local REGISTER_RPC = not CLIENT_ONLY
if REGISTER_RPC then
    local mod_rpc = GLOBAL.rawget(GLOBAL, "MOD_RPC")
    local ns = mod_rpc ~= nil and GLOBAL.rawget(mod_rpc, "true_range") or nil
    if ns ~= nil and GLOBAL.rawget(ns, "ask") ~= nil then REGISTER_RPC = false end
end
local OnLearned -- (player side, below)
if REGISTER_RPC then
    AddModRPCHandler("true_range", "ask", OnAsk)
    AddClientModRPCHandler("true_range", "ranges", function(ent, attack, hit, area, radius, harmful, pound, specials, waves, pound_ready, pound_cd, learned_version, cds)
        OnRanges(ent, attack, hit, area, radius, harmful, pound, specials, waves, pound_ready, pound_cd, learned_version, cds)
    end)
    -- what the server has learned about one kind of monster's attacks (see true_range/learn)
    AddModRPCHandler("true_range", "learnask", function(player, prefab)
        if Ranges == nil or player == nil or type(prefab) ~= "string" or #prefab > 64 then
            return
        end
        SendModRPCToClient(GetClientModRPC("true_range", "learned"), player.userid, prefab, Learn.Encode(prefab),
            Learn.Version(prefab))
    end)
    AddClientModRPCHandler("true_range", "learned", function(prefab, text, version)
        OnLearned(prefab, text, version)
    end)
end

-- each offline-run monster's pose through its moves, tick by tick as the server has it, with how
-- far into the move it is (true_range/simmoves Pose): what a player's game sees of it comes late
-- and slid between ticks, its animation not - put together here, not guessed apart there
local SimMovesPose = GLOBAL.require("true_range/simmoves")
if REGISTER_RPC then
    AddClientModRPCHandler("true_range", "pose", function(ent, key, go, ft, x, z, rot, after, aim, ram_t, ram_d, tpx, tpz, apx, apz)
        if type(ent) == "table" and ent.IsValid ~= nil and ent:IsValid() and type(key) == "string" then
            if not (type(aim) == "table" and aim.IsValid ~= nil) then aim = nil end
            SimMovesPose.Pose(ent, key, go, ft, x, z, rot, after, aim, ram_t, ram_d, tpx, tpz, apx, apz)
        end
    end)
    -- (where the server has you, each tick - a player's own game, with the game's lag compensation, shows you on
    -- ahead of it: what's drawn moved on by as much, true_range/lines Lines.ox)
    AddClientModRPCHandler("true_range", "you", function(x, z)
        if type(x) == "number" and type(z) == "number" then
            -- (and how fast, from the one before: where the server has you between its ticks - from the last word
            -- alone, what's drawn went back and forth by a tick's walk each tick, "everything wobbles", 2026-10-22)
            local now = GLOBAL.GetTime()
            local was = SimMovesPose.you_told
            local vx, vz = 0, 0
            if was ~= nil and now - was.at > .001 and now - was.at < .3 then
                vx, vz = (x - was.x) / (now - was.at), (z - was.z) / (now - was.at)
            end
            SimMovesPose.you_told = { x = x, z = z, at = now, vx = vx, vz = vz }
        end
    end)
end
-- (each monster run offline, on the server -> its pose's state. One task on the world goes through
-- them all: a task each was every such monster anywhere in the world run every tick, with two new
-- lists each time, a player near or not - the mod's biggest piece of the host's time in the game's
-- profile, a fifth of it)
local pose_ents = {}
local pose_ids = {}
local pose_near = {} -- (the player of each of pose_ids)
-- (one this much further off than SIM_FAR from every player looked at again only FAR_RECHECK on:
-- every monster in the world gone through every tick was most of what's left of the host's part -
-- 10 units in 0.3 s is faster than any of them runs)
local FAR_MARGIN, FAR_RECHECK = 10, .3
-- (the players and where they are, once a tick: x, z, player - each monster asks its own place once,
-- not the game twice for every player (IsNear))
local pose_pl = {}
-- (its brain's charge (ChaseAndRam) under way: how long and how far it has left - it gives up 5 s
-- and 25 from where it took it up, before its wind-up, often in the stun before: what a player's
-- game can't see - "-1,-1": none. Its node found once for each brain it has)
local function FindRam(node, depth)
    if type(node) ~= "table" or depth > 12 then return nil end
    if node.max_charge_dist ~= nil and node.max_chase_time ~= nil then return node end
    for _, c in ipairs(node.children or {}) do
        local r = FindRam(c, depth + 1)
        if r ~= nil then return r end
    end
    return nil
end
local function RamLeft(inst, s, x, z, now)
    local bt = inst.brain ~= nil and inst.brain.bt or nil
    if bt == nil then return -1, -1 end
    if s.ram_bt ~= bt then s.ram_bt, s.ram_node = bt, FindRam(bt.root, 0) or false end
    local n = s.ram_node
    if not n or n.status ~= "RUNNING" then return -1, -1 end
    local tl, dl = -1, -1
    if n.startruntime ~= nil then tl = math.max(0, n.max_chase_time - (now - n.startruntime)) end
    if n.startloc ~= nil then dl = math.max(0, n.max_charge_dist - math.sqrt((x - n.startloc.x) ^ 2 + (z - n.startloc.z) ^ 2)) end
    return tl, dl
end
local function PoseOne(inst, s, players, now)
    -- (as it is now - the flag can go back: the Eye of Terror healed past its turning point is an
    -- eye again; one with no flag known, once seen turning, from then on - watched from the start,
    -- whoever is near: told with its poses, to one who came after it turned)
    local turns, turned, flag = s.turns, s.turned, s.flag
    if #turns > 0 then
        local mem = inst.sg ~= nil and inst.sg.mem or nil
        for _, aa in ipairs(turns) do
            if flag[aa] ~= nil and mem ~= nil then
                turned[aa] = mem[flag[aa]] == true
            elseif not turned[aa] and inst.AnimState:IsCurrentAnimation(aa) then
                turned[aa] = true
            end
        end
    end
    -- (only with a player near: where its move began is told by its animation's own time, so
    -- picked up again mid-move just the same)
    local ids, host = pose_ids, false
    for i = #ids, 1, -1 do ids[i] = nil end
    local ix, _, iz = inst.Transform:GetWorldPosition()
    local far2, nearest = SIM_FAR * SIM_FAR, math.huge
    for i = 1, #players, 3 do
        local p = players[i + 2]
        local d2 = (players[i] - ix) ^ 2 + (players[i + 1] - iz) ^ 2
        if d2 < nearest then nearest = d2 end
        if d2 < far2 then
            -- (this game's own player - the host: straight in, no message to itself)
            if p == GLOBAL.ThePlayer then host = true
            elseif p.userid ~= nil and p.userid ~= "" then ids[#ids + 1] = p.userid pose_near[#ids] = p end
        end
    end
    -- (well off from everyone: not looked at again for a while - FAR_MARGIN further than SIM_FAR,
    -- more than any runs in FAR_RECHECK)
    s.next_t = nearest > (SIM_FAR + FAR_MARGIN) ^ 2 and now + FAR_RECHECK or nil
    if not host and #ids == 0 then return end
    local anim_t = inst.AnimState:GetCurrentAnimationTime()
    local key, go, ft = SimMovesPose.PoseTrack(s.st, inst.prefab, s.playing, anim_t, now)
    if key == nil then return end
    -- ("-": told, and none - not "not told")
    local after = "-"
    if #turns > 0 then
        local now_in = {}
        for _, aa in ipairs(turns) do
            if turned[aa] then now_in[#now_in + 1] = aa end
        end
        if #now_in > 0 then after = table.concat(now_in, ",") end
    end
    local x, _, z = inst.Transform:GetWorldPosition()
    local rot = inst.Transform:GetRotation()
    -- (whom the move itself goes at: the one its state took as it began - not whom it's after
    -- now: Klaus' bite goes on at the one it set off at, though a friend's blow has turned it to
    -- them meanwhile - and what a player's game has of whom it's after comes late besides)
    local aim = inst.sg ~= nil and inst.sg.statemem ~= nil and inst.sg.statemem.target or nil
    if not (type(aim) == "table" and aim.IsValid ~= nil and aim:IsValid() and aim.Network ~= nil) then
        aim = inst.components.combat ~= nil and inst.components.combat.target or nil
    end
    if aim ~= nil and not (aim:IsValid() and aim.Network ~= nil) then aim = nil end
    -- (or a list of them, each struck where they stand - the Klaus deer's spells (SGdeer magic_pre statemem.targets: every player
    -- near, its ice circle put where each stands at frame 19.5): none told, its circle drawn where a player's game shows them, not
    -- where the server has them - the player 2026-10-27. Each told themselves, if on the list; kept on through that go - the list is
    -- emptied as it casts. TR_OLD_AIMLIST)
    -- (before whom it's after: the deer take Klaus' target as their own (deer.lua), set though the spell goes at the list)
    local on_list = nil
    if not GLOBAL.rawget(GLOBAL, "TR_OLD_AIMLIST") then
        local sm0 = inst.sg ~= nil and inst.sg.statemem or nil
        local list = sm0 ~= nil and sm0.targets or nil
        if type(list) == "table" and list[1] ~= nil then
            on_list = {}
            for _, t in ipairs(list) do
                if type(t) == "table" and t.IsValid ~= nil and t:IsValid() and t.Network ~= nil then on_list[t] = true end
            end
            s.list_kept = { key = key, go = go, set = on_list }
        elseif s.list_kept ~= nil and s.list_kept.key == key and s.list_kept.go == go then
            on_list = s.list_kept.set
        end
    end
    local ram_t, ram_d = -1, -1
    if s.rams then ram_t, ram_d = RamLeft(inst, s, x, z, now) end
    -- (the spot its move goes for, as its state took it - the Ancient Guardian's leap: where you
    -- were at 1 s, it lands 2 past; what a player's game saw of you then was late - its ring
    -- drawn .5 to 1 off. -1e9: none)
    local tpx, tpz = -1e9, -1e9
    local sm = inst.sg ~= nil and inst.sg.statemem or nil
    local tp = sm ~= nil and sm.targetpos or nil
    if type(tp) == "table" and type(tp.x) == "number" and type(tp.z) == "number" then tpx, tpz = tp.x, tp.z
    -- (or the spot it aims at, crept after you - the Clockwork Bishop's, till it shoots there)
    elseif sm ~= nil and type(sm.tgtx) == "number" and type(sm.tgtz) == "number" then tpx, tpz = sm.tgtx, sm.tgtz end
    if host then
        local host_aim = aim
        if on_list ~= nil and on_list[GLOBAL.ThePlayer] then host_aim = GLOBAL.ThePlayer end
        SimMovesPose.Pose(inst, key, go, ft, x, z, rot, after, host_aim, ram_t, ram_d, tpx, tpz)
    end
    -- (those on its list: each told on their own, aimed at themselves; the rest together, as before)
    if on_list ~= nil and #ids > 0 then
        for i = #ids, 1, -1 do
            local p = pose_near[i]
            if p ~= nil and on_list[p] then
                local ax, _, az = p.Transform:GetWorldPosition()
                SendModRPCToClient(GetClientModRPC("true_range", "pose"), { ids[i] }, inst, key, go, ft, x, z, rot, after, p, ram_t, ram_d, tpx, tpz, ax, az)
                table.remove(ids, i)
            end
        end
    end
    if #ids > 0 then
        -- (and where whom it goes at stands, as the server has it - a player's own game shows them a frame or two
        -- on from that: true_range/predict takes the server's at the moment it stops aiming. -1e9: none)
        local apx, apz = -1e9, -1e9
        if aim ~= nil then local ax, _, az = aim.Transform:GetWorldPosition() apx, apz = ax, az end
        SendModRPCToClient(GetClientModRPC("true_range", "pose"), ids, inst, key, go, ft, x, z, rot, after, aim, ram_t, ram_d, tpx, tpz, apx, apz)
    end
end
local you_rpc = nil
local function PoseTick()
    local players = pose_pl
    for i = #players, 1, -1 do players[i] = nil end
    for _, p in ipairs(GLOBAL.AllPlayers) do
        if p:IsValid() then
            local x, _, z = p.Transform:GetWorldPosition()
            local n = #players
            players[n + 1], players[n + 2], players[n + 3] = x, z, p
        end
    end
    if #players == 0 then return end
    -- (each player's game told where the server has them - not the host's own)
    -- (asked for once: a second, older True Range's numbering may not have it - none sent then)
    if you_rpc == nil then
        local ok, r = GLOBAL.pcall(GetClientModRPC, "true_range", "you")
        you_rpc = ok and r or false
    end
    if you_rpc and GLOBAL.rawget(GLOBAL, "TR_LEAD") then
        for i = 1, #players, 3 do
            local p = players[i + 2]
            if p ~= GLOBAL.ThePlayer and p.userid ~= nil and p.userid ~= "" then
                SendModRPCToClient(you_rpc, p.userid, players[i], players[i + 1])
            end
        end
    end
    local now = GLOBAL.GetTime()
    for inst, s in pairs(pose_ents) do
        if (s.next_t == nil or now >= s.next_t) and inst:IsValid() and inst.AnimState ~= nil then PoseOne(inst, s, players, now) end
    end
end
local function SendPoses(inst)
    -- (the animations of its turning into a later form, its moves' after_anim; or the flag that
    -- state sets, after_mem - one loaded from a save already turned never plays it: the Eye of
    -- Terror as a mouth, its charges drawn as an eye's)
    local s = { st = {}, turns = {}, turned = {}, flag = {} }
    for _, m in ipairs(SimMovesPose.Moves(inst.prefab)) do
        local aa = m.sim ~= nil and m.sim.after_anim or nil
        if aa ~= nil and s.turned[aa] == nil then s.turned[aa] = false s.turns[#s.turns + 1] = aa s.flag[aa] = m.sim.after_mem end
    end
    s.playing = function(a) return inst.AnimState:IsCurrentAnimation(a) end
    for _, m in ipairs(SimMovesPose.Moves(inst.prefab)) do
        if m.sim ~= nil and m.sim.fixed then s.rams = true end
    end
    pose_ents[inst] = s
    inst:ListenForEvent("onremove", function() pose_ents[inst] = nil end)
end
AddPrefabPostInit("world", function(w)
    if w.ismastersim and not CLIENT_ONLY then w:DoPeriodicTask(0, PoseTick) end
end)
do
    local data = GLOBAL.require("true_range/moves_sim")
    local list = {}
    for prefab in pairs(data) do
        if prefab:sub(1, 1) ~= "_" then list[prefab] = true end
    end
    -- (and those drawn as another - a fire hound as a hound)
    for prefab in pairs(data._alias or {}) do list[prefab] = true end
    for prefab in pairs(list) do
        AddPrefabPostInit(prefab, function(inst)
            if GLOBAL.TheWorld.ismastersim and not CLIENT_ONLY then SendPoses(inst) end
        end)
    end
end

-- the server watches monsters' hits land, to learn their moves' shapes (the old ways: off for
-- now - true_range/legacy)
local Legacy = GLOBAL.require("true_range/legacy")
if Ranges ~= nil and Legacy.on then
    -- (measuring bosses' attacks with probes: true_range/probe)
    local Probe = GLOBAL.require("true_range/probe")
    AddPrefabPostInit("world", function(inst)
        inst:DoTaskInTime(0, Learn.Start)
        Probe.Install(Learn)
    end)
    AddComponentPostInit("combat", function(self)
        self.inst:ListenForEvent("attacked", Learn.OnAttacked)
        Probe.WrapCombat(self)
    end)
    -- bosses and big monsters: their moves one after another (charges, what follows what)
    AddPrefabPostInitAny(function(inst)
        if inst.sg ~= nil and (inst:HasTag("epic") or inst:HasTag("largecreature")) and not inst:HasTag("player") then
            inst:ListenForEvent("newstate", Learn.OnNewState)
        end
    end)
end

--------------------------------------------------------------------------------
-- player side

-- (a server with no screen: nothing below is for it - but the local copy's traces (debug.txt) are below too,
-- wanted there by the headless testbench (tr_testbench, tools/run_bench.ps1): on, with debug.txt only)
if TheNet:IsDedicated() and not DEBUG then
    return
end

-- (the settings: as the mod settings set them, or as changed in the game since - true_range/settings,
-- its window true_range/settingsscreen; S read each time, changed in place)
local Settings = GLOBAL.require("true_range/settings")
Settings.Init(function(name) return GetModConfigData(name, true) end)
local S = Settings.values

-- (how far on you're shown from where the server has you, eased - each frame's drawing, below)
local lead = { x = 0, z = 0 }
-- how long your body ring stays red after a hit
local HIT_FLASH = .45
-- a boss whose next attack is known warns this much before its target is in its reach
local SOON_MARGIN = 1.5

local known = GLOBAL.setmetatable({}, { __mode = "k" })  -- ent -> { attack, hit, area, radius, at }
local asked = GLOBAL.setmetatable({}, { __mode = "k" })  -- ent -> when last asked
local show_all = false

-- what's learned about each kind of monster: the version this game has, and when it last asked
local learned_have = {}
local learned_asked = {}
local LEARN_ASK_AGAIN = 5

local function WantLearned(prefab, version)
    if CLIENT_ONLY then return end
    if version <= (learned_have[prefab] or 0) then
        return
    end
    local now = GLOBAL.GetStaticTime()
    if (learned_asked[prefab] or -math.huge) + LEARN_ASK_AGAIN > now then
        return
    end
    learned_asked[prefab] = now
    if GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld.ismastersim then
        OnLearned(prefab, Learn.Encode(prefab), Learn.Version(prefab))
    else
        SendModRPCToServer(GetModRPC("true_range", "learnask"), prefab)
    end
end

OnLearned = function(prefab, text, version)
    if type(prefab) ~= "string" or type(text) ~= "string" then
        return
    end
    learned_have[prefab] = type(version) == "number" and version or 0
    Predict.learned[prefab], Predict.spawns[prefab] = Learn.Decode(text)
end
OnRanges = function(ent, attack, hit, area, radius, harmful, pound, specials, waves, pound_ready, pound_cd, learned_version, cds)
    -- (its moves' cooldowns: timer name -> seconds left, when it was asked)
    local cd = {}
    for name, left in string.gmatch(type(cds) == "string" and cds or "", "([%w_]+)=([%d.]+)") do
        cd[name] = GLOBAL.tonumber(left)
    end
    -- (testing: what the server says of its cooldowns, while one is counting down)
    if DEBUG and type(cds) == "string" and cds:find("=[1-9]") ~= nil and ent ~= nil then
        print(string.format("[true_range] %s cooldowns: %s", tostring(ent.prefab), cds))
    end
    -- (cooldown: "left,total" seconds when it was asked)
    local left, total = string.match(type(pound_cd) == "string" and pound_cd or "", "^([^,]+),([^,]+)$")
    if ent == nil or type(attack) ~= "number" then
        return
    end
    known[ent] = { attack = attack, hit = hit or attack, area = area or 0, radius = radius or 0,
        harmful = harmful ~= false, pound = type(pound) == "number" and pound or 0,
        specials = RangesLib.Decode(type(specials) == "string" and specials or ""),
        waves = RangesLib.DecodeWaves(waves), pound_ready = pound_ready ~= false,
        pound_left = GLOBAL.tonumber(left) or 0, pound_total = GLOBAL.tonumber(total) or 0, cds = cd, at = GLOBAL.GetStaticTime() }
    -- the server learned something new about this kind of monster: ask for it
    if type(learned_version) == "number" and ent.prefab ~= nil then
        WantLearned(ent.prefab, learned_version)
    end
end

local function Ask(ents)
    local now = GLOBAL.GetStaticTime()
    -- (the client-only build: from what this game sees itself - its attack range with the weapon held,
    -- harmful if run offline or tagged a monster; no splash, pounds or cooldowns)
    if CLIENT_ONLY then
        for _, ent in ipairs(ents) do
            if (asked[ent] or -math.huge) + ASK_AGAIN <= now and ent:IsValid() then
                asked[ent] = now
                local c = ent.replica ~= nil and ent.replica.combat or nil
                if c ~= nil then
                    local attack = c:GetAttackRangeWithWeapon() or 0
                    local harmful = ent:HasTag("player") or ent:HasTag("hostile") or ent:HasTag("monster") or Predict.HasSim(ent.prefab)
                    OnRanges(ent, attack, attack, 0, ent:GetPhysicsRadius(0), harmful, 0, "", nil, true, nil, nil, nil)
                end
            end
        end
        return
    end
    local batch = {}
    local function Send()
        if #batch == 0 then
            return
        end
        if GLOBAL.TheWorld ~= nil and GLOBAL.TheWorld.ismastersim then
            OnAsk(GLOBAL.ThePlayer, GLOBAL.unpack(batch))
        else
            SendModRPCToServer(GetModRPC("true_range", "ask"), GLOBAL.unpack(batch))
        end
        batch = {}
    end
    for _, ent in ipairs(ents) do
        if (asked[ent] or -math.huge) + ASK_AGAIN <= now then
            asked[ent] = now
            table.insert(batch, ent)
            if #batch >= ASK_BATCH then
                Send()
            end
        end
    end
    Send()
end

local function Known(ent)
    local r = known[ent]
    if r ~= nil and GLOBAL.GetStaticTime() - r.at <= FORGET_AFTER then
        return r
    end
    return nil
end

local NEAR_MUST = { "_combat" }
local NEAR_CANT = { "INLIMBO", "FX", "NOCLICK", "DECOR", "playerghost" }
-- (with "all nearby": not your friends' followers and such)
local ALL_CANT = { "INLIMBO", "FX", "NOCLICK", "DECOR", "playerghost", "player", "companion", "abigail", "wall" }
-- (one run offline may not be clicked on (NOCLICK) and still strike - the Ancient Guardian's
-- shadow tentacles: never found, never drawn)
-- (or tagged fx - the Deadly Brightshade's vines)
local SIM_CANT = { "INLIMBO", "DECOR", "playerghost" }

local function Hunting(ent, player)
    local combat = ent.replica.combat
    return combat ~= nil and combat:GetTarget() == player
end

-- what gets rings now: { ent, ... } (not you)
-- (one after you a moment ago, kept on .3 s: whom it's after not said a frame now and then - the Umbral Abomination left out of
-- the list those frames, its warning glow out 1-3 frames and back, [tr_lagframe] lag_ink4 2026-10-28. TR_OLD_HUNTSTICK)
local hunted_at = GLOBAL.setmetatable({}, { __mode = "k" })
local function HuntingNow(ent, player)
    local now = GLOBAL.GetTime()
    if Hunting(ent, player) then hunted_at[ent] = now return true end
    return not GLOBAL.rawget(GLOBAL, "TR_OLD_HUNTSTICK") and hunted_at[ent] ~= nil and now - hunted_at[ent] <= .3
end
local function Pick(player)
    local list, seen = {}, {}
    local function Add(ent, sim)
        -- (things that fight but aren't creatures - a laser's blasts: not monsters; one run offline
        -- may have no health and still strike - the Ancient Guardian's shadow tentacles)
        if ent ~= nil and ent ~= player and not seen[ent] and ent:IsValid() and ent:HasTag("_combat")
            and (sim or ent:HasTag("_health")) then
            seen[ent] = true
            table.insert(list, ent)
        end
    end
    Add(TheInput:GetWorldEntityUnderMouse())
    local x, y, z = player.Transform:GetWorldPosition()
    if show_all or S.monsters == "all" then
        for _, ent in ipairs(GLOBAL.TheSim:FindEntities(x, y, z, NEAR, NEAR_MUST, ALL_CANT)) do
            Add(ent)
        end
    elseif S.monsters == "target" then
        for _, ent in ipairs(GLOBAL.TheSim:FindEntities(x, y, z, NEAR, NEAR_MUST, NEAR_CANT)) do
            if HuntingNow(ent, player) then
                Add(ent)
            end
        end
    end
    -- (a boss run offline, from further off: one setting off at you from about NEAR away -
    -- Frostjaw's torpedo, 24 off - went in and out of the list, its shape there one moment and
    -- gone the next)
    for _, ent in ipairs(GLOBAL.TheSim:FindEntities(x, y, z, SIM_FAR, NEAR_MUST, SIM_CANT)) do
        if Predict.HasSim(ent.prefab) and (show_all or S.monsters == "all" or HuntingNow(ent, player)) then
            Add(ent, true)
        end
    end
    -- (no more than S.max_monsters (0: all) - the one under your mouse, then those after you, then the nearest:
    -- a crowd's every shape drawn every frame slowed slower machines, "killer bees" - a player, 2026-10-23)
    local cap = GLOBAL.tonumber(S.max_monsters) or 0
    if cap > 0 and #list > cap then
        local under = TheInput:GetWorldEntityUnderMouse()
        local rank = {}
        for _, ent in ipairs(list) do
            local ex, _, ez = ent.Transform:GetWorldPosition()
            local d = (ex - x) ^ 2 + (ez - z) ^ 2
            -- (and before those after you, the ones striking now - a swarm of the Eye of Terror's mini eyes, dozens
            -- after you: the nearest 16 kept, one a little further off biting you undrawn, 11 on a lag bench
            -- 2026-10-27. TR_OLD_PICKATTACK: as before)
            local attacking = not GLOBAL.rawget(GLOBAL, "TR_OLD_PICKATTACK") and Predict.Attacking ~= nil and Predict.Attacking(ent)
            -- (and before all those, a boss: Moonmaw's ring of lavae strikes only in its spin - Moonmaw, further off than its 8
            -- lavae and 8 of the ring, left out, the ring striking undrawn, 82 on a lag bench 2026-10-27. TR_OLD_PICKEPIC: as before)
            local epic = not GLOBAL.rawget(GLOBAL, "TR_OLD_PICKEPIC") and ent:HasTag("epic")
            if ent == under then d = d - 1e9 elseif epic then d = d - 1e8 elseif attacking then d = d - 1e7 elseif Hunting(ent, player) then d = d - 1e6 end
            rank[ent] = d
        end
        table.sort(list, function(a, b) return rank[a] < rank[b] end)
        for i = #list, cap + 1, -1 do list[i] = nil end
    end
    return list
end

local function InFight(player, list)
    local combat = player.replica.combat
    if combat ~= nil and combat:GetTarget() ~= nil then
        return true
    end
    if player:HasTag("attack") or (player.sg ~= nil and player.sg:HasStateTag("attack")) then
        return true
    end
    for _, ent in ipairs(list) do
        if Hunting(ent, player) then
            return true
        end
    end
    return false
end

-- (other players near: their body rings, and their reach if wanted - Friends; S.friend_own as S.own, for
-- each of them)

local FRIEND_MUST, FRIEND_CANT = { "player" }, { "playerghost", "INLIMBO" }
local friends = { list = {} }
-- (whether your reach is shown, as last picked; each ring's own slot - true_range/telegraph Circle)
local reach = { own = false, own_slot = {}, friend_slots = GLOBAL.setmetatable({}, { __mode = "k" }),
    start_slots = GLOBAL.setmetatable({}, { __mode = "k" }) }
local function Friends(player)
    local list = {}
    local x, y, z = player.Transform:GetWorldPosition()
    for _, ent in ipairs(GLOBAL.TheSim:FindEntities(x, y, z, NEAR, FRIEND_MUST, FRIEND_CANT)) do
        if ent ~= player and ent:IsValid() then list[#list + 1] = ent end
    end
    return list
end
-- Abigail (Wendy's): her aura strikes what's within 4 of her middle (aura radius 4, FindEntities) - drawn
-- while she's after something (S.abigail "fight"), or always; as a gestalt (Wendy's lunar skills) she
-- strikes in her dashes only, within sqrt 2 (GESTALT_ATTACK_HIT_RANGE_SQ). And her commands, as you aim
-- or pick them (true_range/ghostcommand_defs): Attack At - she takes the first thing within 2 of the spot
-- (a gestalt: dashes there, striking within 4 - ABIGAIL_GESTALT_ATTACKAT_RADIUS); Haunt At - the first
-- within 2; Scare - all within 10 of her panic (the wheel open: drawn round her)
local ABIGAIL_MUST = { "abigail" }
local abig = { list = {}, next = 0, slots = GLOBAL.setmetatable({}, { __mode = "k" }), cmd_slot = {} }
local function AbigailRings(player, mx, mz)
    local now = GLOBAL.GetStaticTime()
    if now >= abig.next then
        abig.next = now + .3
        abig.list = GLOBAL.TheSim:FindEntities(mx, 0, mz, NEAR, ABIGAIL_MUST, { "INLIMBO" })
    end
    local mine, mine_d = nil, math.huge
    for _, a in ipairs(abig.list) do
        if a:IsValid() then
            local ax, _, az = a.Transform:GetWorldPosition()
            local d = (ax - mx) ^ 2 + (az - mz) ^ 2
            if d < mine_d then mine, mine_d = a, d end
            local c = a.replica ~= nil and a.replica.combat or nil
            if S.abigail == "always" or (c ~= nil and c:GetTarget() ~= nil) then
                local slot = abig.slots[a]
                if slot == nil then slot = {} abig.slots[a] = slot end
                Telegraph.Circle(ax, az, a:HasTag("gestalt") and math.sqrt(2) or 4, "abigail", slot)
            end
        end
    end
    -- (her commands - only with your own flower in hand: the nearest Abigail taken for yours)
    if mine == nil or player.HUD == nil then return end
    local hud = player.HUD
    if hud.IsSpellWheelOpen ~= nil and hud:IsSpellWheelOpen() then
        local book = hud:GetCurrentOpenSpellBook()
        if book ~= nil and book.prefab == "abigail_flower" then
            local ax, _, az = mine.Transform:GetWorldPosition()
            Telegraph.Circle(ax, az, 10, "abigail_cmd", abig.cmd_slot)
        end
    end
    local pc = player.components.playercontroller
    if pc ~= nil and pc.IsAOETargeting ~= nil and pc:IsAOETargeting() and pc.reticule ~= nil then
        local item = pc.reticule.inst
        local book = item ~= nil and item.prefab == "abigail_flower" and item.components.spellbook or nil
        local cmds = GLOBAL.STRINGS.GHOSTCOMMANDS or {}
        local pos = book ~= nil and pc:GetAOETargetingPos() or nil
        if pos ~= nil then
            local r = nil
            if book.spellname == cmds.ATTACK_AT then
                r = mine:HasTag("gestalt") and (GLOBAL.TUNING.ABIGAIL_GESTALT_ATTACKAT_RADIUS or 4) or 2
            elseif book.spellname == cmds.HAUNT_AT then
                r = 2
            end
            if r ~= nil then Telegraph.Circle(pos.x, pos.z, r, "abigail_cmd", abig.cmd_slot) end
        end
    end
end
local function ShowFriendOwn(f)
    if S.friend_own == "always" or (S.friend_own ~= "off" and show_all) then return true end
    if S.friend_own ~= "fight" then return false end
    local c = f.replica ~= nil and f.replica.combat or nil
    return (c ~= nil and c:GetTarget() ~= nil) or f:HasTag("attack") or (f.sg ~= nil and f.sg:HasStateTag("attack"))
end

local function ShowOwn(player, list)
    return S.own == "always" or (S.own == "key" and show_all) or (S.own == "fight" and (show_all or InFight(player, list)))
end

-- Rings for everything picked. Returns the bosses' fans to outline every frame (a ring would
-- overstate them), and whether you stand inside something's red reach.
local function Draw(player, list, own)
    Rings.Begin()
    local my_radius = player:GetPhysicsRadius(0)
    local mx, _, mz = player.Transform:GetWorldPosition()
    local statics, danger, bodies, cooldowns = {}, false, {}, {}
    local function Inside(ent, radius, offset, half)
        local x, _, z = ent.Transform:GetWorldPosition()
        local rot = ent.Transform:GetRotation() * GLOBAL.DEGREES
        offset = offset or 0
        return Telegraph.InFan(mx, mz, x + offset * math.cos(rot), z - offset * math.sin(rot), rot, radius, half or 180)
    end
    for _, ent in ipairs(list) do
        local r = Known(ent)
        -- (nothing for harmless critters: birds, butterflies, rabbits...)
        if r ~= nil and r.harmful then
            local key = ent.GUID
            -- its body: where you bump into it
            if r.radius > 0 then
                table.insert(bodies, { ent = ent, radius = r.radius })
            end
            -- attacks it makes its own way (a boss's swipe): drawn as they are, and its Combat
            -- hit range is left out if one of them is what really lands
            local replaced = false
            for i, s in ipairs(r.specials) do
                if s.kind == "aroundtarget" then
                    -- (lands on whoever it's after: around them)
                    local combat = ent.replica.combat
                    local target = combat ~= nil and combat:GetTarget() or nil
                    if target ~= nil and target:IsValid() then
                        Rings.Show(key .. "s" .. i, "area", target, s.radius)
                    end
                elseif s.half > 0 and s.half < 180 then
                    -- a fan: outlined every frame, turning with it
                    table.insert(statics, { ent = ent, radius = s.radius + my_radius, offset = s.offset, half = s.half })
                    danger = danger or (s.kind ~= "area" and Inside(ent, s.radius + my_radius, s.offset, s.half))
                else
                    Rings.Show(key .. "s" .. i, s.kind == "area" and "area" or "hit", ent, s.radius + my_radius, s.offset)
                    danger = danger or (s.kind ~= "area" and Inside(ent, s.radius + my_radius, s.offset))
                end
                replaced = replaced or s.replaces
            end
            -- your middle inside the red ring: its attack lands on you
            if not replaced then
                Rings.Show(key .. "hit", "hit", ent, r.hit + my_radius)
                -- (only for monsters whose moves aren't known: for the others, what they're
                -- doing tells - true_range/predict)
                danger = danger or (not Predict.Knows(ent.prefab) and Inside(ent, r.hit + my_radius))
            end
            -- its ground pound: with a known cooldown (Bearger), a ring that fills back in like a
            -- clock as the cooldown runs out - whole means its next attack is the pound (drawn
            -- every frame: see Telegraph.Cooldown); otherwise a plain purple ring
            if r.pound > 0 and r.pound_total > 0 then
                table.insert(cooldowns, { ent = ent, r = r })
            elseif r.pound > 0 and r.pound_ready then
                Rings.Show(key .. "pound", "area", ent, r.pound)
            end
            -- yellow: inside it, it stops and attacks; outside it, it walks to you (drawn under the
            -- red one: when they're the same, only red shows)
            if S.start_ring then
                Rings.Show(key .. "attack", "attack", ent, r.attack + my_radius)
            end
            -- its splash: around whoever it's attacking
            if r.area > 0 then
                local combat = ent.replica.combat
                local target = combat ~= nil and combat:GetTarget() or nil
                if target ~= nil and target:IsValid() then
                    Rings.Show(key .. "area", "area", target, r.area)
                end
            end
        end
    end
    -- (a friend's reach, by their weapon as the server has it: light blue)
    for _, f in ipairs(friends.list) do
        if f:IsValid() and ShowFriendOwn(f) then
            local r = Known(f)
            if r ~= nil then Rings.Show("friend" .. f.GUID, "friend_own", f, r.hit) end
        end
    end
    if own then
        local r = Known(player)
        if r ~= nil then
            -- a target whose edge touches the green ring can be hit
            Rings.Show("own", "own", player, r.hit)
            if S.start_ring and math.abs(r.attack - r.hit) > .05 then
                Rings.Show("own_start", "own_start", player, r.attack)
            end
        end
    end
    Rings.Sweep()
    return statics, danger, bodies, cooldowns
end

-- bosses whose attacks get outlined while they wind up (true_range/telegraph)
local function Bosses(player)
    local list = {}
    local x, y, z = player.Transform:GetWorldPosition()
    for _, ent in ipairs(GLOBAL.TheSim:FindEntities(x, y, z, NEAR + 8, NEAR_MUST, NEAR_CANT)) do
        if Telegraph.Knows(ent.prefab) then
            table.insert(list, ent)
        end
    end
    return list
end

-- Things the bosses near you set off (what they are comes with what's learned about the boss):
-- asked about, and looked for around you.
local HAZARD_CANT = { "INLIMBO", "player" }

local function Hazards(player, list)
    local wanted = {}
    for _, ent in ipairs(list) do
        for thing, version in pairs(Predict.spawns[ent.prefab] or {}) do
            wanted[thing] = true
            WantLearned(thing, version)
        end
    end
    -- (and those known from the offline runs - crystals, spike trails, gestalts...: always - the
    -- boss that set them off may be well away, past where bosses are looked for)
    for thing in pairs(Predict.SimHazards()) do
        wanted[thing] = true
    end
    -- (not a player's own - Abigail, picked up by the offline runs as a thing that strikes round itself: her
    -- reach drawn all the time, whatever the settings; drawn now as the friend she is - AbigailRings)
    wanted.abigail = nil
    if GLOBAL.next(wanted) == nil then
        return {}
    end
    local found, have = {}, {}
    local x, y, z = player.Transform:GetWorldPosition()
    for _, ent in ipairs(GLOBAL.TheSim:FindEntities(x, y, z, NEAR, nil, HAZARD_CANT)) do
        if wanted[ent.prefab] then
            table.insert(found, ent)
            have[ent] = true
        end
    end
    -- (and those made near, seen as they were made - a search never finds some: the War
    -- Machine's missiles are CLASSIFIED, never once drawn in the game)
    for ent in pairs(Predict.made_hazards) do
        -- (not one put away out of the scene - a flame back in its pool till it's breathed again)
        if not have[ent] and ent:IsValid() and wanted[ent.prefab] and not ent:HasTag("INLIMBO")
            and ent:GetDistanceSqToPoint(x, y, z) < NEAR * NEAR then
            table.insert(found, ent)
        end
    end
    return found
end

-- (testing: who makes Lua's garbage - true_range/allocwatch; off)
local ALLOC_WATCH = false
-- (testing: the replays' traces written - F9 on and off while playing: the frame rate without them)
local trace_on = true
-- (how near a monster takes you for its target, drawn round it all the while - by prefab;
-- AGGRO_CANT: what's looked through for them)
-- (or touches you: a gelblob takes you in at 1.2 from it and your body (its _contact_radius); the
-- Shadow Thrall centipede's head and body strike what they run into - 1.5 round, your body)
-- (and the Great Depths Worm's mounds: where it comes up and goes down, it swallows what's within 2
-- (WORM_BOSS_EAT_RANGE), its spiked segments striking 2 round and your body as they come and go)
-- (every tentacle: the marsh's (TENTACLE_ATTACK_DIST 4), the Big Tentacle's arms (_PILLAR_ARM_ 3))
local AGGRO = { bigshadowtentacle = 4, tentacle = 4, tentacle_pillar_arm = 3, gelblob = 1.7, shadowthrall_centipede_head = 2, shadowthrall_centipede_body = 2,
    -- (a Dread Mite: it bursts 3 round itself (EXPLODE_RANGE) as it gets to you, or its time is up)
    fused_shadeling_bomb = 3,
    -- (and the three red ones it throws out as it bursts - each bursting 3 round itself a moment on)
    fused_shadeling_quickfuse_bomb = 3 }
local AGGRO_CANT = { "INLIMBO" }
-- (and only while it plays these, after you - a Pengull sliding at you strikes whoever it comes
-- within 2.5 of (PENGUIN_ATTACK_DIST) and their body on its slide's first frame: nothing to warn of
-- as it begins - the ring round it all the while it slides)
local AGGRO_WHILE = {
    penguin = { r = 3, anims = { "slide_loop", "slide_bounce" } },
    -- (the Great Depths Worm's mounds: it swallows what's within 2 and your body only as its head comes up out of one or goes
    -- down into one (worm_boss_util CollectThingsToEat: EmergeHead, the new dirt_end) - not all the while a mound lies there:
    -- "a ring outside the real one, only the circle hurts", the player 2026-10-28 - nor while its spiked segments go through it (DoThornDamage
    -- as each comes out and goes in, w.near: one within 1.6): 10 struck there undrawn without. TR_OLD_WORMDIRT: always)
    worm_boss_dirt = { r = 2.5, anims = { "dirt_pre_slow", "dirt_pre_fast", "dirt_emerge_loop_pre", "dirt_emerge_loop", "dirt_emerge" }, linger = .3, any_target = true, near = { "worm_boss_segment", 1.6 } },
    worm_boss_shadow_dirt = { r = 2.5, anims = { "dirt_pre_slow", "dirt_shadow_pre_slow", "dirt_pre_fast", "dirt_emerge_loop_pre", "dirt_emerge_loop", "dirt_emerge" }, linger = .3, any_target = true, near = { "worm_boss_shadow_segment", 1.6 } },
    mutated_penguin = { r = 3, anims = { "slide_loop", "slide_bounce" } },
    -- (Tropical Experience's yellow lizardman: its zap (spit_attack, spit) strikes whom it's after at frame 15, anywhere within
    -- 16 + 4 of it (its weapon's SetRange(16, 20)), no shot to dodge - drawn as a dark ring 20 round it, cut square by the data's
    -- grid: "very wide, and not even round", the player 2026-10-22. Now: its reach pale, and a mark on you - yellow as it
    -- winds up, red from frame 15 (core.on_you); only when it's after you)
    gw_yellow_lizardman = { r = 20, anims = { "spit" }, linger = .2,
        core = { r = 1.2, on_you = true, warn = { "spit" }, hit_after = { spit = 15 } } },
    -- (and the Forge's elemental (golem): after monsters only - but after whoever strikes it; its homing fireballs (frames 7 and
    -- 17 of attack, 40 a second) striking you anywhere within 15 + 2 of it (weapon SetRange(15, 17)): the same, the fireball's
    -- flight after (linger))
    golem = { r = 17, anims = { "attack" }, linger = .5,
        core = { r = 1.2, on_you = true, warn = { "attack" }, hit_after = { attack = 7 } } },
    -- (Tropical Experience's Thunderbird: lightning called down 3 times 0.4 s apart round whom it's after - the weather strikes
    -- the nearest it can (OnSendLightningStrike: the player, a rod...), shocking all within 3 (LIGHTNING_STRIKE_RADIUS):
    -- where can't be told before, too quick to dodge - the user's call, 2026-10-20: an area, round you (at_you), faint, as it
    -- shoots and the 1.2 s its strikes take after (linger); after you or not, its brain picks)
    -- (not drawn any more: the user, 2026-10-21 - "why up, it often strikes no one": where it falls is the weather's pick)
    -- (Tropical Experience's twister: its vacuum (components/vacuum.lua) pulls in every player within 20 of it for 5 s (vacuum_loop),
    -- then spits them out struck (spitplayer, DoAttack) as vacuum_pst begins - 91 of its blows undrawn on the bench, 2026-10-20)
    -- (core: where you're held as it pulls, and struck as it spits you out - within 3 of it (vacuum player_hold_distance) and
    -- your body: strike-yellow while it pulls (vacuum_loop), hit-red as it spits (vacuum_pst) - the faint ring 20 out the only
    -- thing drawn, you held in its middle saw nothing of the blow, the player 2026-10-21)
    twister = { r = 20, anims = { "vacuum_loop", "vacuum_pst" }, any_target = true,
        core = { r = 3.5, warn = { "vacuum_loop" }, hit = { "vacuum_pst" } } },
    -- (its Ancient Hulk's spin: a laser swept round it 45 degrees at a time, everything within 7 struck (DoDamage BEAMRAD, frames
    -- 37-50 of atk_circle) - 75 of its blows undrawn on the bench, 2026-10-20; the run can't measure it (tools/sim_mods/te.lua))
    -- (and as it dies: blown apart, all within 6 struck (death, DoDamage 6 at frame 81 of death_explode) - 3 struck undrawn, the
    -- bench 2026-10-21; one ring for both, the larger)
    -- (core too: the faint ring alone was not seen at all, the player 2026-10-21 - strike-yellow as it winds up, hit-red from the
    -- frame its laser sweeps (hit_after, frames into the animation: 37 of atk_circle, 81 of death_explode))
    -- (not the lasers it lays out as it sweeps (spawnburns, 7 from its middle): each is set off (Trigger, delay 0 - DoDamage at once) before
    -- it is moved there - where it was made, the world's middle; seen at 7, striking nothing there: the player stood on them at 7.04-7.88 three
    -- times unstruck, 2026-10-21. r_of: its size by animation - as it dies, DoDamage 6)
    ancient_hulk = { r = 7, anims = { "atk_circle", "death_explode" }, any_target = true,
        core = { r = 7, r_of = { death_explode = 6 }, warn = { "atk_circle", "death_explode" }, hit_after = { atk_circle = 37, death_explode = 81 } } },
    -- (its Pugalisk's head pounding the ground - 2 rings, 8 from your middle (groundpounder 1 and 5 out, 3 wide): as it comes up
    -- (emerge_taunt) and as it comes up from moving underground (startmove head_idle_pst, then hidden playing head_idle_pre as it
    -- goes, struck where it comes up - the bench: 1.5 s under, then the pound at emerge's first frame) - 23 of its blows undrawn
    -- on the bench, 2026-10-20)
    -- (its spiky turtle's slide: at you up to 5 times, striking all within 3 of it every 0.1 s (SlideTask, SLIDE_RADIUS) - 90 of
    -- its blows undrawn on the bench, 2026-10-20: as the Pengull's, round it while it slides)
    spiky_turtle_tfc = { r = 3, anims = { "attack2_pre", "attack2_loop" }, any_target = true },
    -- (Tropical Experience's Rhinocebros' charge: turning after you every frame, striking within 4.5 of it (its range) and your
    -- body at frame 15 of each loop, on till it hits - round it as it charges, plain: 5 of 7 blows undrawn, the player 2026-10-21)
    rhinodrill = { r = 5, anims = { "attack2_pre", "attack2_loop" }, core = { r = 5, warn = { "attack2_pre", "attack2_loop" } } },
    rhinodrill2 = { r = 5, anims = { "attack2_pre", "attack2_loop" }, core = { r = 5, warn = { "attack2_pre", "attack2_loop" } } },
    -- (jump: what it really strikes by under the ground - every 1.8 s its head, hidden, jumps 12 on to where its body comes up
    -- (bodycomplete, SetPosition) and pounds there 0.75 s later; all 4 blows the player took, 2026-10-21, 0.75 s after one.
    -- Drawn plain there from the jump - yellow, red as it pounds; the faint ring not left the whole time it's under, round
    -- where it went down: only its way down (head_idle_pst - backing up, it pounds 0.75 s on, no jump) and emerge_taunt)
    -- (6.5, not 8: its pounds are point mode (TE components/groundpounder: DestroyPoints' DoAttack) - within its hit range, 6 (PUGALISK_MELEE_RANGE)
    -- and your body, whatever the rings reach; 8 was drawn "too wide", the player 2026-10-21)
    pugalisk = { r = 6.5, anims = { "head_idle_pst", "emerge_taunt" }, any_target = true, linger = 1.2,
        jump = { d = 3, warn = .75, hit = .3 } },
    -- (the Tiger Shark's leap on land, coming down: from fallwarn it's above whom it was after, its shadow put down under it
    -- (drawn - tigersharkshadow), falling (fall: ground_launch_down_loop) till it lands in a ground pound (fallpost) - its
    -- shadow gone 1.8 s on (Ground_Fall), the pound 0.5-0.7 s later: nothing drawn as it struck, the player's log 2026-10-21.
    -- Round it as it falls, where its shadow was - yellow, red as it lands (ground_launch_down_pst), off .25 s on. 4.7: its
    -- shadow's - hit range 4 and your body, the bench's 540 blows within 4.67. Its leap no longer run as a move of its own,
    -- slid from where it leapt: tools/sim_mods/te_second.lua)
    -- (and not round its shadow: high up, it drifts on after you - 0.2 a frame - landing 4.3 from where its shadow was put
    -- down, two rings seen, the player 2026-10-21. Round it from the moment it's moved above you (jump: 4-6 off at once, a
    -- frame - 1.5: you near where it leapt from, moved less; it drifts .25 a frame going up), on with it as it drifts: yellow
    -- 2 s, red .4 - it lands 2.2-2.3 s on. Its shadow not drawn (te.lua))
    -- (and yellow as it falls, red as it lands, whether or not that jump was seen - whom it's after near where it leapt
    -- from, moved too little to tell: only the pale ring, the clips 2026-10-21)
    tigershark = { r = 4.7, anims = { "ground_launch_down_loop" }, any_target = true, linger = .25,
        jump = { d = 1.5, warn = 2, hit = .4 },
        core = { r = 4.7, warn = { "ground_launch_down_loop" }, hit = { "ground_launch_down_pst" } } },
    -- (Uncompromising Mode's nightmare pawn: no blow of its own - from the moment it has a target (newcombattarget) a fuse of
    -- some 3.75 s (ExplodePing, faster and faster), then it blows up where it has run to, all within 6 struck (explosive
    -- explosiverange 6; FindEntities - your middle). Struck 4.58 off as it ran after you, nothing drawn, the player's log
    -- 2026-10-21. Round it, plain yellow, while it's after you)
    -- (idle_r: and before it's after anyone, how near sets it off - it takes a target within 8 (NormalRetarget, FindTarget 8):
    -- pale, "show how near it notices you - it's that dangerous", the player 2026-10-21)
    um_pawn_nightmare = { r = 6, anims = { "walk_pre", "walk_loop", "idle", "hit", "look_pre" }, idle_r = 8,
        core = { r = 6, warn = { "walk_pre", "walk_loop", "idle", "hit", "look_pre" } } },
    -- (Uncompromising Mode's clockwork pawn: no blow of its own - come within 7 of it (playerprox SetDist(7, 13)) and a ring of
    -- spikes rises 15 round you, two amalgams brought down by you (SpawnSpikes, SpawnAmalgams): how near, pale, all the while,
    -- hidden too - the player 2026-10-21)
    um_pawn = { r = 7, anims = { "idle", "walk_pre", "walk_loop", "hit", "look_pre", "hide_idle", "emerge", "dig" }, any_target = true },
}
if GLOBAL.rawget(GLOBAL, "TR_OLD_WORMDIRT") ~= nil then AGGRO_WHILE.worm_boss_dirt, AGGRO_WHILE.worm_boss_shadow_dirt = nil, nil AGGRO.worm_boss_dirt, AGGRO.worm_boss_shadow_dirt = 2.5, 2.5 end
for prefab, w in pairs(AGGRO_WHILE) do AGGRO[prefab] = w.r end
-- (one whose code drops its reach (combat.ignorehitrange = true) - every blow of it then strikes its target wherever that
-- is: Tropical Experience's Infernal Swineclops, its guard broken (BreakGuard - each belly flop as it lands, SGbeetletaur
-- :496), till it guards again (EnterGuardMode: _bufftype 1). Its blows were drawn round it, you struck 4.6-10 off - "0%
-- right, far off", the player 2026-10-21. Then: no shape round it, a mark on you instead - yellow, red from the frame it
-- strikes (hit_at, frames into each animation). broken_by: the animation that breaks it, by its frame; net: its guard)
local ANYWHERE = {
    -- (its state's frame 23 is about frame 19 of bellyflop - bellyflop_pre some 4 frames long, the player's trace)
    beetletaur = { net = "_bufftype", broken_by = { bellyflop = 19 },
        hit_at = { attack1 = 6, attack2 = 7, attack1b = 7, attack3 = 3, block_counter = 6, bellyflop_pre = 99, bellyflop = 19, taunt2 = 8 } },
}
local anywhere_on = GLOBAL.setmetatable({}, { __mode = "k" })
local function Anywhere(e)
    local w = ANYWHERE[e.prefab]
    if w == nil or not e:IsValid() or e.AnimState == nil then return nil end
    local s = anywhere_on[e]
    if s == nil then s = { broken = false } anywhere_on[e] = s end
    local nv = e[w.net] ~= nil and e[w.net]:value() or nil
    if nv == 1 then s.broken = false
    elseif nv ~= nil and s.last == 1 then s.broken = true end
    s.last = nv
    for an, f in pairs(w.broken_by) do
        if e.AnimState:IsCurrentAnimation(an) and e.AnimState:GetCurrentAnimationTime() >= f * GLOBAL.FRAMES then s.broken = true end
    end
    if not s.broken then return nil end
    for an, f in pairs(w.hit_at) do
        if e.AnimState:IsCurrentAnimation(an) then
            return e.AnimState:GetCurrentAnimationTime() >= f * GLOBAL.FRAMES and "hit" or "strike"
        end
    end
    return false
end
-- (each one's core ring kept apart from its outer one - telegraph's ring slots: one ring each)
local aggro_core_slot = GLOBAL.setmetatable({}, { __mode = "k" })
-- (and where each was last frame, and when it last jumped - w.jump: { x, z, t })
local aggro_jumped = GLOBAL.setmetatable({}, { __mode = "k" })
-- (an AGGRO_WHILE area filled, as a move's is - edge and fill in its style: a thin ring alone (Telegraph.Circle, 0.06 wide)
-- was not seen at all - the Pugalisk's, the sealnado's, the hulk's laser "no hitbox", the player 2026-10-21)
local function AggroFill(x, z, r, style)
    GLOBAL.require("true_range/simmoves").DrawCapsule(x, z, 0, 0, r, style)
end
-- (a ruins nightmare's horns: two, from either side of you 10 off, closing on where you stood till
-- they meet - striking 1.25 round each (and your body) all the way: the lane between them, as soon
-- as they're made - looked for each frame they'd come too late, gone in a second)
local horns = {}
AddPrefabPostInit("ruinsnightmare_horn_attack", function(inst) horns[#horns + 1] = inst end)
-- (what falls on a warning shadow harming nothing - the Queen Womant's eggs (antqueen.lua SpawnWarrior: dropped from 35
-- up, a warningshadow put under each; it lands and hatches, striking no one): its shadow not drawn - predict's
-- Predict.harmless_falls; her quake's debris, under shadows just the same, does strike)
Predict.harmless_falls = GLOBAL.setmetatable({}, { __mode = "k" })
AddPrefabPostInit("antman_warrior_egg", function(inst) Predict.harmless_falls[inst] = true end)
-- (MacTusk's dart in flight: straight on (not homing) the way it was shot, till 25 from where it
-- was shot from - first seen 3 ahead of it, 22 on from there; striking within 1 aside (sqrt 5, 2 up)
-- and your body: its lane as it really goes, from the dart itself)
local darts = {}
-- (and a Spitter's web, the same: 20 a second, not homing, striking within 1 and your body - on and on:
-- it gives up only once it stops getting nearer you, or further - running from it, it never does; struck
-- at 20 in the game: 30 on)
local DARTS = { blowdart_walrus = { len = 22, width = 1.5 }, spider_web_spit = { len = 30, width = 1.5 }, spider_web_spit_acidinfused = { len = 12, width = 1.5 },
    -- (Uncompromising Mode's bees' stingers: straight at 25 a second, striking whoever's middle comes within sqrt(2) as it flies
    -- (um_beestinger_projectile.lua PhysTest) - drawn round where it was, a tick or two behind it: struck 2.44 off, 8 on the bench,
    -- 2026-10-20; its lane ahead of it, 12 from the guards' ring and some)
    -- (by, strikes_until: its blows the game's as the shooter guard's, the guard dead by then sometimes - for the checks only,
    -- tests/replay*.lua: 6 "missed" in its death, 3-5 off, the bench 2026-10-21; 15 at 25 a second and some)
    um_beestinger_projectile = { len = 15, width = 1.414, by = "um_beeguard_shooter", strikes_until = 30 },
    -- (Uncompromising Mode's Eye of Terror's mini eye flung at you: straight on at 20 a second (postinit SGeyeofterror
    -- ShootEye), never coming down (its ground check commented out), gone in 3 s - 60 on; striking whoever its 1.5
    -- capsule meets, and your body (eyeofterror_extras.lua fneye_proj, oncollide): drawn as a ring once it stopped, 25
    -- struck undrawn, 2026-10-20. Made 2 ahead of the eye, it strikes you near it before it has gone .3: its way from
    -- the way it faces as it's made (face - Launch turns it to its target))
    -- (only so far: it sinks as it flies (linearprojectile gravity -0.1: 1 up as made, 0.135 lower each unit on - the player's
    -- log 2026-10-21), under the ground past ~18 out, its capsule (1.5 high) through no one - drawn 60 on, its lane ran on far
    -- past the eye, the eye itself seen sunk off it, the player: "the hitbox off its real place". Struck on the benches at
    -- most 11.8 along)
    eyeofterror_minieye_projectile = { len = 20, width = 2.0, face = true },
    -- (Tropical Experience's green tentacle's spike, thrown from as far as 24 (its weapon's range 20, +4): straight at where
    -- you were at 40 a second, not homing, no end to it (no range set) - striking you within 1 and your body (projectile
    -- hitdist): 25 of its 101 offline strikes undrawn, its throw played on its idle animation, 2026-10-20. 30 on)
    -- (by, strikes_until: its blows the game's as the tentacle's (its weapon's projectile) - for the checks only, tests/replay*.lua;
    -- its strike no longer drawn round the tentacle itself (a ring 20 round it, dark, the player 2026-10-22), 2 "missed")
    tentacle_attack_spike = { len = 30, width = 1.5, by = "greententacle", strikes_until = 30 },
    -- (Tropical Experience's pig ruins' dart traps: shot straight across the room till it meets something, its body 0.5 (and
    -- yours) - pig_ruins_dart.lua oncollide; a room 30 across at most)
    pig_ruins_dart = { len = 30, width = 1.0 },
    -- (Tropical Experience's lizardman's spit: shot straight at whom it's after from up to 20 (DIST_ATTACK_RANGE 16, + 4), not
    -- following, 40 a second, striking within 1 of it and your body (projectile SetHitDist) - 23 of its blows undrawn on the
    -- bench, struck as it had walked on, 2026-10-20; turned to its target as it's made)
    -- (by, strikes_until: its blows the game's as the lizardman's (projectile, its combat) - for the checks only, tests/replay*.lua;
    -- 20 off at 40 a second, 15 frames, and some)
    lizardman_spit_tfc = { len = 24, width = 1.5, face = true, by = "lizardman_tfc", strikes_until = 30 },
    -- (and the plain lizardman's, the same (lizardman.lua: 16 + 4, 40 a second, hit within 1) - 4 struck undrawn as it ran on, the
    -- stress bench 2026-10-21)
    lizardman_spit = { len = 24, width = 1.5, face = true, by = "lizardman", strikes_until = 30 } }
for prefab, d in pairs(DARTS) do
    AddPrefabPostInit(prefab, function(inst) darts[#darts + 1] = { ent = inst, len = d.len, width = d.width, face = d.face } end)
    -- (and their lane before they're shot, from the one that shoots them - true_range/simmoves DrawShot)
    GLOBAL.require("true_range/simmoves").shots[prefab] = { len = d.len, width = d.width }
end
local aggro_ents, aggro_next = {}, nil
local aggro_until = GLOBAL.setmetatable({}, { __mode = "k" })
-- (one short-lived, picked up as it's made - looked for only every .3 s, a red bomb's second was a third gone)
AddPrefabPostInit("fused_shadeling_quickfuse_bomb", function(inst) aggro_ents[#aggro_ents + 1] = inst end)
local function Start(player)
    if StepAside() then return end
    local next_pick = 0
    local bosses = {}
    local hazards = {}
    local statics, danger, bodies, cooldowns = {}, false, {}, {}
    local picked = {}
    local last_hit = -math.huge
    local last_inside_at = -math.huge -- (testing: when you last stood in something drawn)
    local paused = { last = nil, since = nil, told = false } -- (testing: the game's clock standing still)
    -- a hit (health going down, not from hunger, cold and such over time): flash your body ring
    player:ListenForEvent("healthdelta", function(_, data)
        if data ~= nil and not data.overtime and (data.newpercent or 1) < (data.oldpercent or 0) then
            last_hit = GLOBAL.GetStaticTime()
        end
    end)
    -- struck by a thing that strikes each once among its lot (junk falling): the rest of that lot
    -- drawn faint - they can't strike you now (seen where the world runs: you hosting)
    for _, ev in ipairs({ "attacked", "blocked" }) do
        player:ListenForEvent(ev, function(_, data)
            if data ~= nil and data.attacker ~= nil then GLOBAL.require("true_range/simmoves").Struck(data.attacker) end
        end)
    end
    -- (testing: when you were really struck - even with no health lost (god mode), or blocked -
    -- to set beside what was drawn: client_log.txt; only seen where the world runs)
    -- (testing: the other way round - you stood in a part drawn striking just then, and weren't
    -- struck: drawn too big? Said after a moment with nothing - in chat and the log)
    local SimMovesLib = GLOBAL.require("true_range/simmoves")
    local pending = {}  -- monster -> { when, move }
    local struck_by = GLOBAL.setmetatable({}, { __mode = "k" })  -- monster -> when it last struck you
    SimMovesLib.on_strike = function(ent, inside, edge)
        -- (the hit is told before the strike is drawn, the same moment: struck just now counts)
        if inside and GLOBAL.GetStaticTime() - (struck_by[ent] or -math.huge) > .4 then
            -- (how far off it was then, as its part struck - not .4 s on, when it's said: a charge
            -- gone past you by then, "7.5 away" said of one that passed you at 4.3)
            pending[ent] = { when = GLOBAL.GetStaticTime(), move = Predict.MoveOf(ent), edge = edge,
                d = ent:IsValid() and math.sqrt(player:GetDistanceSqToInst(ent)) or -1 }
        end
    end
    -- (testing: struck in ways the game tells no one of as a blow - frozen, set alight, knocked back: as "you were struck",
    -- the same "drawn:" - seen in your own game too (its animation, its "fire" tag); a frozen player never counted, the Klaus
    -- deer's circle froze the player outside what was drawn, the player 2026-10-27)
    local EFFECTS = { { "frozen", anims = { "frozen", "frozen_loop_pst" } }, { "set alight", tag = "fire" },
        { "knocked back", anims = { "knockback", "knockback_high", "knockback_pst" } } }
    local eff_was = {}
    if DEBUG then player:DoStaticPeriodicTask(0, function()
        if not player:IsValid() then return end
        local now = GLOBAL.GetStaticTime()
        for i, e in ipairs(EFFECTS) do
            local on = e.tag ~= nil and player:HasTag(e.tag) or false
            if not on and e.anims ~= nil and player.AnimState ~= nil then
                for _, an in ipairs(e.anims) do if player.AnimState:IsCurrentAnimation(an) then on = true break end end
            end
            if on and not eff_was[i] then
                print(string.format("[true_range] you were %s - drawn: %s age=%.3f", e[1], now - last_inside_at < .15 and "in" or "NOT",
                    math.min(99, now - last_inside_at)))
            end
            eff_was[i] = on
        end
    end) end
    if DEBUG then player:DoStaticPeriodicTask(.1, function()
        local now = GLOBAL.GetStaticTime()
        for ent, p in pairs(pending) do
            if now - p.when > .4 then
                pending[ent] = nil
                local d = p.d or -1
                print(string.format("[true_range] drawn IN but NOT struck by %s (%s), %.2f from it%s", ent.prefab or "?", p.move or "?", d,
                    p.edge and " - at its edge" or " - WELL INSIDE"))
                local chat = GLOBAL.ChatHistory
                if chat ~= nil then
                    chat:AddToHistory(GLOBAL.ChatTypes.Message, nil, nil, "True Range",
                        string.format("NOT HIT by %s%s, %.1f away - you were %s", ent.prefab or "?",
                            p.move ~= nil and (" (" .. p.move .. ")") or "", d,
                            p.edge and "at the drawn edge (coin toss)" or "WELL INSIDE the drawn strike"), { .6, .8, 1, 1 }, nil, nil, true)
                end
            end
        end
    end)
    for _, ev in ipairs({ "attacked", "blocked" }) do
        player:ListenForEvent(ev, function(_, data)
            local by = data ~= nil and data.attacker or nil
            -- (a player's game isn't told who struck it ("?") - a server with caves, the host's own game a player of it: "HIT by ?"
            -- every blow, and each the drawn one took for "NOT HIT", the player 2026-10-27. Who it most likely was: the one whose
            -- drawn strike you were in just now, else the nearest one striking - its name with a "?" after. TR_OLD_GUESSBY)
            local guessed = false
            if by == nil and not GLOBAL.rawget(GLOBAL, "TR_OLD_GUESSBY") then
                local best_t = -math.huge
                for ent, p in pairs(pending) do
                    if ent:IsValid() and p.when > best_t then by, best_t = ent, p.when end
                end
                if by == nil then
                    local best_d = 8 * 8
                    for _, ent in ipairs(picked) do
                        if ent:IsValid() and Predict.Attacking ~= nil and Predict.Attacking(ent) then
                            local dd = player:GetDistanceSqToInst(ent)
                            if dd < best_d then by, best_d = ent, dd end
                        end
                    end
                end
                guessed = by ~= nil
            end
            if by ~= nil then
                pending[by] = nil
                struck_by[by] = GLOBAL.GetStaticTime()
            end
            local d = by ~= nil and by:IsValid() and math.sqrt(player:GetDistanceSqToInst(by)) or -1
            -- (age: how long since you last stood in it - "in" takes .15 s back, near a unit at a run; tools/lag_report.lua
            -- reads it for a stricter count)
            -- ("(worn)": put on you, in your inventory - the Hound Batilisk as a hat, biting; where your game has it is where
            -- it was put on: tools/lag_report.lua leaves these out)
            local worn = by ~= nil and by:IsValid() and by:HasTag("INLIMBO")
            print(string.format("[true_range] you were %s%s by %s, %.2f from it - drawn: %s age=%.3f", ev == "attacked" and "struck" or "struck (blocked)",
                worn and " (worn)" or "", by ~= nil and ((by.prefab or "?") .. (guessed and "?" or "")) or "?", d, GLOBAL.GetStaticTime() - last_inside_at < .15 and "in" or "NOT",
                math.min(99, GLOBAL.GetStaticTime() - last_inside_at)))
            -- (testing, in chat too: what struck you, in which move, and whether you stood in
            -- what was drawn just then - god mode on, sound off, it's easy to miss)
            local chat = GLOBAL.ChatHistory
            if chat ~= nil then
                local move = by ~= nil and Predict.MoveOf(by) or nil
                local drawn = GLOBAL.GetStaticTime() - last_inside_at < .15
                chat:AddToHistory(GLOBAL.ChatTypes.Message, nil, nil, "True Range",
                    string.format("HIT by %s%s, %.1f away - drawn: %s", by ~= nil and ((by.prefab or "?") .. (guessed and "?" or "")) or "?",
                        move ~= nil and (" (" .. move .. ")") or "", d, drawn and "you were IN it" or "you were NOT in it"),
                    { 1, .6, .2, 1 }, nil, nil, true)
            end
        end)
    end
    end
    -- (testing: how long each frame's drawing takes, and the game's own frame - a slow one in
    -- client_log.txt as "[tr_perf]", with what took it; every 10s a summary)
    local perf = { frames = 0, sum = 0, worst = 0, last_wall = nil, mem0 = GLOBAL.collectgarbage("count"), t0 = GLOBAL.os.clock(), long = 0 }
    local function Mark() return GLOBAL.os.clock() end
    -- (testing, to be removed: who makes Lua's garbage - the local copy only)
    -- (off: watching hooked every Lua instruction of the game for its first 4 minutes - every
    -- test of the frame rate with the local copy slowed by it. ALLOC_WATCH true to look again)
    if DEBUG and ALLOC_WATCH then
        player:DoStaticTaskInTime(5, function() GLOBAL.require("true_range/allocwatch").Start(player) end)
    end
    player:DoStaticPeriodicTask(0, function()
        if player ~= GLOBAL.ThePlayer or not player:IsValid() then
            return
        end
        local c_start = Mark()
        local wall = GLOBAL.os.clock()  -- (Windows: the wall clock, to the ms)
        local gap = perf.last_wall ~= nil and (wall - perf.last_wall) or 0
        perf.last_wall = wall
        local created0, made0, mem_before = Lines.created, SimMovesLib.made or 0, GLOBAL.collectgarbage("count")
        -- (what the hazards' part went on: how many things, how many past the looks and holes, the
        -- time drawing those; pieces laid, calls made to the game, groups laid again, moved)
        local hn0, hd0, ht0 = Predict.haz_n, SimMovesLib.haz_drawn, Predict.haz_draw_t
        local laid0, calls0, gb0, gm0 = Lines.laid, Lines.calls, Lines.group_builds, Lines.groups_moved
        local c_pick, c_tele, c_moves, c_haz = 0, 0, 0, 0
        local now = GLOBAL.GetStaticTime()
        local c0 = Mark()
        if now >= next_pick then
            next_pick = now + PICK_EVERY
            local list = Pick(player)
            picked = list
            local own = ShowOwn(player, list)
            local ask = {}
            for _, ent in ipairs(list) do
                table.insert(ask, ent)
            end
            if own then
                table.insert(ask, player)
            end
            reach.own = own
            friends.list = (S.friend_body or S.friend_own ~= "off") and Friends(player) or {}
            if S.friend_own ~= "off" then
                for _, f in ipairs(friends.list) do
                    if ShowFriendOwn(f) then table.insert(ask, f) end
                end
            end
            bosses = Bosses(player)
            for _, ent in ipairs(bosses) do
                table.insert(ask, ent)
            end
            Ask(ask)
            hazards = Hazards(player, list)
            if Render.lines then
                statics, danger, bodies, cooldowns = Draw(player, list, own)
            else
                -- (lines and rings off for now - true_range/render: none shown)
                Rings.Begin()
                Rings.Sweep()
                statics, danger, bodies, cooldowns = {}, false, {}, {}
            end
        end
        c_pick = Mark() - c0
        Rings.Follow()
        local mx, _, mz = player.Transform:GetWorldPosition()
        local my_radius = player:GetPhysicsRadius(0)
        Lines.Begin()
        -- (a player's game: how far on you're shown from where the server has you - the game's lag compensation; all
        -- that strikes drawn on by that much (true_range/lines), its checks of you made where the server has you (sx, sz).
        -- Eased, not stepped tick by tick; none told of late, or over 4 off (a teleport): none. Off: "everything wobbles, back and forth, not where the player is" - the player 2026-10-22. TR_LEAD=1: on)
        local sx, sz = mx, mz
        do
            local told = SimMovesPose.you_told
            local lx, lz = 0, 0
            if told ~= nil and not GLOBAL.TheWorld.ismastersim and GLOBAL.rawget(GLOBAL, "TR_LEAD")
                and GLOBAL.GetTime() - told.at < .5 then
                local since = math.min(GLOBAL.GetTime() - told.at, .2)
                lx, lz = mx - (told.x + (told.vx or 0) * since), mz - (told.z + (told.vz or 0) * since)
                if lx * lx + lz * lz > 4 * 4 then lx, lz = 0, 0 end
            end
            lead.x = lead.x + (lx - lead.x) * .12
            lead.z = lead.z + (lz - lead.z) * .12
            Lines.ox, Lines.oz = lead.x, lead.z
            sx, sz = mx - lead.x, mz - lead.z
        end
        c0 = Mark()
        local winding = Render.lines and Telegraph.Draw(bosses, Known, my_radius, statics, { x = sx, z = sz }) or false
        c_tele = Mark() - c0
        c0 = Mark()
        -- every other monster's known moves (read from the game's code, or learned)
        -- (one striking its target wherever it is just now (ANYWHERE): not its shape round it - a mark on you, if it's after you)
        local draw_list = picked
        for i, e in ipairs(picked) do
            local st = ANYWHERE[e.prefab] ~= nil and Anywhere(e) or nil
            if st ~= nil then
                if draw_list == picked then
                    draw_list = {}
                    for k = 1, i - 1 do draw_list[k] = picked[k] end
                end
                if st and Hunting(e, player) then AggroFill(sx, sz, my_radius + .5, st) end
            elseif draw_list ~= picked then
                draw_list[#draw_list + 1] = e
            end
        end
        winding = Predict.Draw(draw_list, Known, my_radius, { x = sx, z = sz, ent = player }, Telegraph.Knows) or winding
        c_moves = Mark() - c0
        c0 = Mark()
        -- what bosses set off: traps, spikes, lasers
        winding = Predict.DrawHazards(hazards, my_radius, { x = sx, z = sz }) or winding
        c_haz = Mark() - c0
        if winding then last_inside_at = now end
        -- (testing, to be removed: the game paused (P) - its clock still while frames go on: once,
        -- in chat and client_log.txt ("[tr_pause]"), what's drawn now and from what - Predict.Report)
        -- (still for .2s of the wall clock: not just frames drawn faster than the game ticks)
        local game_now = GLOBAL.GetTime()
        if game_now ~= paused.last then
            paused.last, paused.since, paused.told = game_now, now, false
        end
        if warped then
            warped, paused.told = false, false
        end
        if DEBUG and not paused.told and paused.since ~= nil and now - paused.since > .2 then
            paused.told = true
            local lines = Predict.Report(mx, mz)
            local head = string.format("PAUSED - game time %.3f, frame %d; you at %.2f, %.2f; %d drawn", game_now,
                math.floor(game_now / GLOBAL.FRAMES + .5), mx, mz, #lines)
            print("[tr_pause] " .. head)
            for _, l in ipairs(lines) do print("[tr_pause] " .. l) end
            local chat = GLOBAL.ChatHistory
            if chat ~= nil then
                chat:AddToHistory(GLOBAL.ChatTypes.Message, nil, nil, "True Range", head, { .5, 1, .5, 1 }, nil, nil, true)
                for _, l in ipairs(lines) do
                    chat:AddToHistory(GLOBAL.ChatTypes.Message, nil, nil, "True Range", l, { .5, 1, .5, 1 }, nil, nil, true)
                end
            end
        end
        -- ground pounds coming back off cooldown
        for _, c in ipairs(cooldowns) do
            if c.ent:IsValid() then
                local left = math.max(0, c.r.pound_left - (now - c.r.at))
                local cx, _, cz = c.ent.Transform:GetWorldPosition()
                Telegraph.Cooldown(cx, cz, c.r.pound, 1 - left / c.r.pound_total, left <= 0, c.r.waves)
                -- ready, and its target is in reach: its very next attack is the pound - warn now,
                -- not only once it has started the move (then the move's own warning takes over)
                if left <= 0 and not c.ent.AnimState:IsCurrentAnimation("ground_pound") then
                    local combat = c.ent.replica.combat
                    local target = combat ~= nil and combat:GetTarget() or nil
                    if target ~= nil and target:IsValid() then
                        local reach = c.r.attack + target:GetPhysicsRadius(0) + SOON_MARGIN
                        if c.ent:GetDistanceSqToInst(target) <= reach * reach then
                            winding = Telegraph.PoundSoon(cx, cz, c.r.waves, sx, sz) or winding
                        end
                    end
                end
            end
        end
        -- monsters' bodies: you bump into them where this ring meets yours
        for _, b in ipairs(bodies) do
            if b.ent:IsValid() then
                local bx, _, bz = b.ent.Transform:GetWorldPosition()
                Telegraph.Circle(bx, bz, b.radius, "monster_body", b.ent)
            end
        end
        -- (how near it takes you for its target - the Ancient Guardian's shadow tentacles: 4 round
        -- each (TENTACLE_ATTACK_DIST), its strikes coming only once you're in; looked for a few
        -- times a second, not every frame)
        if now >= (aggro_next or 0) then
            aggro_next = now + .3
            for i = #aggro_ents, 1, -1 do aggro_ents[i] = nil end
            for _, e in ipairs(GLOBAL.TheSim:FindEntities(mx, 0, mz, 24, nil, AGGRO_CANT)) do
                if AGGRO[e.prefab] ~= nil then aggro_ents[#aggro_ents + 1] = e end
            end
        end
        for _, e in ipairs(aggro_ents) do
            local w = AGGRO_WHILE[e.prefab]
            local on = e:IsValid()
            if on and w ~= nil then
                on = false
                if (w.any_target or Hunting(e, player)) and e.AnimState ~= nil then
                    for _, an in ipairs(w.anims) do
                        if e.AnimState:IsCurrentAnimation(an) then on = true break end
                    end
                end
                -- (or something of its own going through it now - w.near: { prefab, how near })
                if not on and w.near ~= nil and e.Transform ~= nil then
                    local nx, _, nz = e.Transform:GetWorldPosition()
                    for _, o in ipairs(GLOBAL.TheSim:FindEntities(nx, 0, nz, w.near[2])) do
                        if o.prefab ~= nil and o.prefab:find(w.near[1], 1, true) == 1 then on = true break end
                    end
                end
                -- (and a while after - what it set off still to come: w.linger seconds)
                if on and w.linger ~= nil then aggro_until[e] = now + w.linger end
                if not on and w.linger ~= nil and (aggro_until[e] or 0) > now then on = true end
                -- (not after you yet: how near sets it off, pale - w.idle_r)
                if not on and w.idle_r ~= nil and e:IsValid() and not e:HasTag("INLIMBO") then
                    local ix, _, iz = e.Transform:GetWorldPosition()
                    AggroFill(ix, iz, w.idle_r, "fill_light")
                end
            end
            -- (jumped far since last frame: its strike to come there - w.jump)
            if w ~= nil and w.jump ~= nil and e:IsValid() then
                local jx, _, jz = e.Transform:GetWorldPosition()
                local j = aggro_jumped[e]
                if j == nil then j = { x = jx, z = jz } aggro_jumped[e] = j end
                if (jx - j.x) ^ 2 + (jz - j.z) ^ 2 > w.jump.d * w.jump.d then j.t = now end
                j.x, j.z = jx, jz
                if j.t ~= nil and now - j.t <= w.jump.warn + w.jump.hit then
                    AggroFill(jx, jz, w.r, now - j.t >= w.jump.warn and "hit" or "strike")
                    -- (testing: you in it - "drawn: in" when struck; drawn here, not by Predict: the Tiger Shark's landing,
                    -- struck 2.82 inside its ring, said "drawn: NOT", the player's log 2026-10-21)
                    if (sx - jx) ^ 2 + (sz - jz) ^ 2 <= w.r * w.r then last_inside_at = now end
                end
            end
            if on then
                local ex, _, ez = e.Transform:GetWorldPosition()
                -- (round you, not it - lightning brought down on you (w.at_you))
                if w ~= nil and w.at_you then ex, ez = sx, sz end
                -- (and its core, plainer: yellow while it's coming, red as it strikes - w.core)
                local core = w ~= nil and w.core or nil
                local core_drawn = false
                if core ~= nil and e.AnimState ~= nil then
                    local style = nil
                    for _, an in ipairs(core.hit or {}) do if e.AnimState:IsCurrentAnimation(an) then style = "hit" end end
                    -- (or from that many frames into it - core.hit_after)
                    for an, f in pairs(core.hit_after or {}) do
                        if e.AnimState:IsCurrentAnimation(an) and e.AnimState:GetCurrentAnimationTime() >= f * GLOBAL.FRAMES then style = "hit" end
                    end
                    if style == nil then
                        for _, an in ipairs(core.warn or {}) do if e.AnimState:IsCurrentAnimation(an) then style = "strike" end end
                    end
                    if style ~= nil then
                        local cx, _, cz = e.Transform:GetWorldPosition()
                        -- (on you, not round it - struck wherever you stand in its reach: core.on_you)
                        if core.on_you then cx, cz = sx, sz end
                        local cr = core.r
                        for an, rr in pairs(core.r_of or {}) do if e.AnimState:IsCurrentAnimation(an) then cr = rr end end
                        AggroFill(cx, cz, cr, style)
                        if (sx - cx) ^ 2 + (sz - cz) ^ 2 <= cr * cr then last_inside_at = now end
                        core_drawn = core.r >= AGGRO[e.prefab]
                    end
                end
                -- (the whole of it, pale - may be: as a filled area too, not a thin line alone; not under a core as big)
                if w == nil then Telegraph.Circle(ex, ez, AGGRO[e.prefab], "edge_light", e)
                elseif not core_drawn then AggroFill(ex, ez, AGGRO[e.prefab], "fill_light") end
            end
        end
        for i = #horns, 1, -1 do
            local h = horns[i]
            if not h:IsValid() or h:HasTag("FX") then table.remove(horns, i) end
        end
        for i, h in ipairs(horns) do
            local hx, _, hz = h.Transform:GetWorldPosition()
            -- (its pair: the other one nearest - drawn once, from the first of the two)
            local other, best = nil, 22 * 22
            for j, o in ipairs(horns) do
                if j ~= i then
                    local ox, _, oz = o.Transform:GetWorldPosition()
                    local d = (ox - hx) ^ 2 + (oz - hz) ^ 2
                    if d < best then other, best = j, d end
                end
            end
            if other == nil then
                local rot = h.Transform:GetRotation() * GLOBAL.DEGREES
                Telegraph.Lane(hx, hz, hx + 10 * math.cos(rot), hz - 10 * math.sin(rot), 1.75)
            elseif other > i then
                local ox, _, oz = horns[other].Transform:GetWorldPosition()
                Telegraph.Lane(hx, hz, ox, oz, 1.75)
            end
        end
        for i = #darts, 1, -1 do
            local d = darts[i]
            if not d.ent:IsValid() or d.ent:HasTag("INLIMBO") then table.remove(darts, i) end
        end
        for _, d in ipairs(darts) do
            local dx, _, dz = d.ent.Transform:GetWorldPosition()
            -- (its way set once, from its first step of flight: where first seen to where it is a
            -- frame on - the way it faced as the client had it went the other way, its lane drawn back
            -- to the walrus; nor taken again each frame - it swung about as the network moved it on)
            if d.x == nil then d.x, d.z = dx, dz end
            if d.ex == nil then
                local mx, mz = dx - d.x, dz - d.z
                local ml = math.sqrt(mx * mx + mz * mz)
                if ml > .3 then
                    d.wx, d.wz = mx / ml, mz / ml
                    d.ex, d.ez = d.x + d.wx * d.len, d.z + d.wz * d.len
                end
            end
            -- (one turned to its target as it's made (d.face): the way it faces, till it has gone .3)
            local ex, ez, wx, wz = d.ex, d.ez, d.wx, d.wz
            if ex == nil and d.face then
                local r = d.ent.Transform:GetRotation() * GLOBAL.DEGREES
                wx, wz = math.cos(r), -math.sin(r)
                ex, ez = d.x + wx * d.len, d.z + wz * d.len
            end
            if ex ~= nil then
                local left = (ex - dx) * wx + (ez - dz) * wz
                if left > 0 then
                    Telegraph.Lane(ex - wx * left, ez - wz * left, ex, ez, d.width)
                    -- (testing: you in it - "drawn: in" when struck; drawn here, not by Predict: the queen's guards' stingers,
                    -- struck 1.4 inside their lanes, said "drawn: NOT" x4, lag 0521)
                    local ax, az = ex - wx * left, ez - wz * left
                    local along = math.max(0, math.min(left, (sx - ax) * wx + (sz - az) * wz))
                    local qx, qz = ax + wx * along, az + wz * along
                    if (sx - qx) ^ 2 + (sz - qz) ^ 2 <= d.width * d.width then last_inside_at = now end
                end
            end
        end
        -- (lines off: the bosses' bodies all the same - true_range/render: bodies)
        if not Render.lines and Render.bodies then
            for _, ent in ipairs(picked) do
                if ent:IsValid() and Predict.HasSim(ent.prefab) then
                    local r = ent:GetPhysicsRadius(0)
                    if r > 0 then
                        local bx, _, bz = ent.Transform:GetWorldPosition()
                        Telegraph.Circle(bx, bz, r, "monster_body", ent)
                    end
                end
            end
        end
        -- your body ring: red just after a hit, orange while you stand where something's attack
        -- reaches (or one winding up), white otherwise
        if S.body and (Render.lines or Render.bodies) then
            local style = (now - last_hit < HIT_FLASH and "body_hit") or ((danger or winding) and "body_danger") or "body"
            Telegraph.Circle(mx, mz, my_radius, style, player)
        end
        -- (and each other player's - white)
        if S.friend_body and (Render.lines or Render.bodies) then
            for _, f in ipairs(friends.list) do
                if f:IsValid() and not f:HasTag("playerghost") then
                    local fx, _, fz = f.Transform:GetWorldPosition()
                    Telegraph.Circle(fx, fz, f:GetPhysicsRadius(0), "body", f)
                end
            end
        end
        -- how far you reach, by your weapon (green) - a target whose edge touches it can be hit; and
        -- each friend's (light blue). Drawn as lines: the rings on the ground (true_range/rings) are off
        -- with Render.lines, these were never seen
        if reach.own then
            local r = Known(player)
            if r ~= nil and r.hit > 0 then Telegraph.Circle(mx, mz, r.hit, "own", reach.own_slot) end
        end
        -- (each monster's reach where it starts attacking you - yellow: its attack range, as the
        -- server has it, and your body; was a ring on the ground, off with them)
        if S.start_ring then
            for _, ent in ipairs(picked) do
                local r = ent:IsValid() and Known(ent) or nil
                if r ~= nil and r.harmful and r.attack > 0 then
                    local slot = reach.start_slots[ent]
                    if slot == nil then slot = {} reach.start_slots[ent] = slot end
                    local ex, _, ez = ent.Transform:GetWorldPosition()
                    Telegraph.Circle(ex, ez, r.attack + my_radius, "attack_start", slot)
                end
            end
        end
        if S.abigail ~= "off" then AbigailRings(player, mx, mz) end
        if S.friend_own ~= "off" then
            for _, f in ipairs(friends.list) do
                if f:IsValid() and not f:HasTag("playerghost") and ShowFriendOwn(f) then
                    local r = Known(f)
                    if r ~= nil and r.hit > 0 then
                        local slot = reach.friend_slots[f]
                        if slot == nil then slot = {} reach.friend_slots[f] = slot end
                        local fx, _, fz = f.Transform:GetWorldPosition()
                        Telegraph.Circle(fx, fz, r.hit, "friend_own", slot)
                    end
                end
            end
        end
        Lines.End()
        Lines.Warm(12)
        local total = Mark() - c_start
        perf.frames, perf.sum, perf.worst = perf.frames + 1, perf.sum + total, math.max(perf.worst, total)
        local mem_after = GLOBAL.collectgarbage("count")
        -- (what's made: by us in our part of the frame, by everything else between - a fall is the
        -- collector, left out)
        if mem_after > mem_before then perf.ours_kb = (perf.ours_kb or 0) + mem_after - mem_before end
        if perf.last_mem ~= nil and mem_before > perf.last_mem then perf.rest_kb = (perf.rest_kb or 0) + mem_before - perf.last_mem end
        perf.last_mem = mem_after
        -- (a slow frame of ours, or a long gap between the game's frames - a hitch, whoever's)
        if DEBUG and (total > .006 or gap > .1) then
            perf.long = perf.long + 1
            print(string.format("[tr_perf] ours %.1fms (pick %.1f, bosses %.1f, moves %.1f, hazards %.1f: %d things, %d drawn, %.1fms in drawing) | laid %d, calls %d, groups laid again %d, moved %d | game frame gap %.0fms | new pieces %d, new shapes %d | mem %.0fKB %s%.0fKB%s",
                total * 1000, c_pick * 1000, c_tele * 1000, c_moves * 1000, c_haz * 1000, Predict.haz_n - hn0, SimMovesLib.haz_drawn - hd0,
                (Predict.haz_draw_t - ht0) * 1000, Lines.laid - laid0, Lines.calls - calls0, Lines.group_builds - gb0, Lines.groups_moved - gm0, gap * 1000,
                Lines.created - created0, (SimMovesLib.made or 0) - made0, mem_after, mem_after >= mem_before and "+" or "",
                mem_after - mem_before, mem_after < mem_before - 500 and " (GC ran)" or ""))
        end
        if wall - perf.t0 >= 10 then
            local _ = DEBUG and print(string.format("[tr_perf] 10s: %d frames, ours avg %.2fms worst %.1fms, %d slow; pieces made %d; Lua memory %.0fKB (%+.0fKB/s); made: ours %.0fKB/s, the rest %.0fKB/s",
                perf.frames, perf.sum / math.max(1, perf.frames) * 1000, perf.worst * 1000, perf.long, Lines.created,
                mem_after, (mem_after - perf.mem0) / (wall - perf.t0), (perf.ours_kb or 0) / (wall - perf.t0), (perf.rest_kb or 0) / (wall - perf.t0)))
            -- (testing: the hazards' time by stage, a frame on average while any were there - each
            -- thing asked where it is; the quick look, kept / not; the whole way: before it, asking
            -- whether to draw it at all (and how many not), drawing it; the bosses gathered first)
            local ST = Predict.stage
            if ST.frames > 0 then
                local f = ST.frames
                local _ = DEBUG and print(string.format("[tr_perf] stages (%d frames with things): %.1f things, %.1f kept quick, %.1f the whole way (%.1f not to be drawn) | ms a frame: loop %.2f = bosses %.2f + asking %.2f + quick kept %.2f + quick missed %.2f + before %.2f + whole way %.2f (of it, whether to draw %.2f)",
                    f, ST.things / f, ST.n_quick / f, ST.n_full / f, SimMovesLib.stage_hidden / f,
                    ST.loop * 1000 / f, ST.bosses * 1000 / f, ST.ask * 1000 / f, ST.quick * 1000 / f, ST.quick_miss * 1000 / f,
                    ST.full_pre * 1000 / f, ST.full * 1000 / f, SimMovesLib.stage_shown * 1000 / f))
                for k in pairs(ST) do ST[k] = 0 end
                SimMovesLib.stage_shown, SimMovesLib.stage_hidden = 0, 0
            end
            perf.ours_kb, perf.rest_kb = 0, 0
            perf.frames, perf.sum, perf.worst, perf.long, perf.t0, perf.mem0 = 0, 0, 0, 0, wall, mem_after
        end
    end)
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0, function()
        if inst == GLOBAL.ThePlayer then
            Start(inst)
        end
    end)
end)

-- the settings window's key, as set now (it can be changed in the window): opens it (not while typing,
-- nor over another window)
TheInput:AddKeyHandler(function(key, down)
    if not down or StepAside() then return end
    local frontend = GLOBAL.TheFrontEnd
    if frontend == nil or frontend.textProcessorWidget ~= nil then
        return
    end
    local screen = frontend:GetActiveScreen()
    if screen == nil or screen.name ~= "HUD" then
        return
    end
    if key == Settings.KeyCode("settings_key") then
        frontend:PushScreen(GLOBAL.require("true_range/settingsscreen")())
    end
    -- (no show-all key any more - a key too many: show_all stays off)
end)

-- (the testing keys and tweaks below: only with debugging on - DEBUG)
if DEBUG then
-- (testing, to be removed: while paused (P), "." steps the game on one tick - unpaused, paused
-- again once its clock has moved (the pause report then said again, for that tick); the pause's
-- dark overlay not shown; chat gone twice as fast - 5s, fading over 1s)
-- (testing, to be removed: "," lays the sort-order test grid round you, again takes it away -
-- true_range/lines SortTest)
-- (testing, to be removed: "/" puts the dark band along each edge half under the outline, as it
-- was, or beside it, as now - to see the two side by side, zooming in and out)
TheInput:AddKeyDownHandler(GLOBAL.KEY_SLASH, function()
    local frontend = GLOBAL.TheFrontEnd
    if frontend == nil or frontend.textProcessorWidget ~= nil then return end
    local screen = frontend:GetActiveScreen()
    if screen == nil or screen.name ~= "HUD" then return end
    local SM = GLOBAL.require("true_range/simmoves")
    SM.outline_in = SM.outline_in > 0 and 0 or .2
    local player = GLOBAL.ThePlayer
    if player ~= nil and player.components.talker ~= nil then
        player.components.talker:Say(SM.outline_in > 0 and "band: beside the outline (new)" or "band: half under the outline (old)")
    end
end)
-- (testing, to be removed: F7 - where the game's Lua time goes, every 10s in the log as
-- "[tr_prof]" - true_range/profiler; again: off)
TheInput:AddKeyDownHandler(GLOBAL.KEY_F7, function()
    local frontend = GLOBAL.TheFrontEnd
    if frontend == nil or frontend.textProcessorWidget ~= nil then return end
    local screen = frontend:GetActiveScreen()
    if screen == nil or screen.name ~= "HUD" then return end
    local player = GLOBAL.ThePlayer
    if player == nil then return end
    local on = GLOBAL.require("true_range/profiler").Toggle(player)
    if player.components.talker ~= nil then
        player.components.talker:Say(on and "True Range: profiling (test)" or "True Range: profiling off")
    end
end)
-- (testing, to be removed: F10 - who makes Lua's garbage, by mod and file, for 4 minutes - every
-- 20s in the log as "[tr_alloc]" - true_range/allocwatch; slows the game while on)
local alloc_started = false
TheInput:AddKeyDownHandler(GLOBAL.KEY_F10, function()
    local frontend = GLOBAL.TheFrontEnd
    if frontend == nil or frontend.textProcessorWidget ~= nil then return end
    local screen = frontend:GetActiveScreen()
    if screen == nil or screen.name ~= "HUD" then return end
    local player = GLOBAL.ThePlayer
    if player == nil or alloc_started then return end
    alloc_started = true
    GLOBAL.require("true_range/allocwatch").Start(player)
    if player.components.talker ~= nil then player.components.talker:Say("True Range: watching garbage (test)") end
end)
-- (testing, to be removed: F9 - the replays' traces ([tr_trace], [tr_haz], [tr_env]) off and on
-- while playing: the frame rate without them, against the game without the mod)
TheInput:AddKeyDownHandler(GLOBAL.KEY_F9, function()
    local frontend = GLOBAL.TheFrontEnd
    if frontend == nil or frontend.textProcessorWidget ~= nil then return end
    local screen = frontend:GetActiveScreen()
    if screen == nil or screen.name ~= "HUD" then return end
    trace_on = not trace_on
    print(string.format("[tr_perf] F9: traces %s", trace_on and "ON" or "OFF"))
    local player = GLOBAL.ThePlayer
    if player ~= nil and player.components.talker ~= nil then
        player.components.talker:Say(trace_on and "True Range: test log ON" or "True Range: test log OFF")
    end
end)
-- (testing, to be removed: F8 - every piece the mod draws hidden, all else worked out the same:
-- the frame rate with and without the game drawing them - true_range/lines SetUnseen; in the log
-- as "[tr_perf] F8")
TheInput:AddKeyDownHandler(GLOBAL.KEY_F8, function()
    local frontend = GLOBAL.TheFrontEnd
    if frontend == nil or frontend.textProcessorWidget ~= nil then return end
    local screen = frontend:GetActiveScreen()
    if screen == nil or screen.name ~= "HUD" then return end
    Lines.SetUnseen(not Lines.unseen)
    print(string.format("[tr_perf] F8: pieces %s", Lines.unseen and "HIDDEN (worked out, not drawn)" or "shown again"))
    local player = GLOBAL.ThePlayer
    if player ~= nil and player.components.talker ~= nil then
        player.components.talker:Say(Lines.unseen and "True Range: hidden (test)" or "True Range: shown")
    end
end)
-- (testing, to be removed: ";" - the deep red striking now at sort 2 or 3, the outline light or
-- see-through red - true_range/lines TestEdge)
TheInput:AddKeyDownHandler(GLOBAL.KEY_SEMICOLON, function()
    local frontend = GLOBAL.TheFrontEnd
    if frontend == nil or frontend.textProcessorWidget ~= nil then return end
    local screen = frontend:GetActiveScreen()
    if screen == nil or screen.name ~= "HUD" then return end
    local mode = Lines.TestEdge()
    local names = { "1: red fill sort 2, light outline (now)", "2: red fill sort 3, light outline", "3: red fill sort 3, see-through red outline (old)" }
    local player = GLOBAL.ThePlayer
    if player ~= nil and player.components.talker ~= nil then player.components.talker:Say(names[mode]) end
end)
-- (the game names no KEY_COMMA: its code, as KEY_PERIOD's 46 is ".")
TheInput:AddKeyDownHandler(44, function()
    local frontend = GLOBAL.TheFrontEnd
    if frontend == nil or frontend.textProcessorWidget ~= nil then return end
    local screen = frontend:GetActiveScreen()
    if screen == nil or screen.name ~= "HUD" then return end
    local player = GLOBAL.ThePlayer
    if player == nil then return end
    local x, _, z = player.Transform:GetWorldPosition()
    local mode = Lines.SortTest(x, z)
    local names = { "1: line (red) vs fill (blue)", "2: line vs line", "3: fill vs fill", "4: disc (red) vs line (blue)", "5: disc (red) vs fill (blue)", "6: line vs line at -10 -1 0 7 8 15 100" }
    if player.components.talker ~= nil then player.components.talker:Say(names[mode] or "sort test off") end
end)
TheInput:AddKeyDownHandler(GLOBAL.KEY_PERIOD, function()
    local frontend = GLOBAL.TheFrontEnd
    if frontend == nil or frontend.textProcessorWidget ~= nil then return end
    local screen = frontend:GetActiveScreen()
    if screen == nil or screen.name ~= "HUD" then return end
    local world = GLOBAL.TheWorld
    if world == nil or not GLOBAL.TheNet:IsServerPaused(true) or step_from ~= nil then return end
    step_from = GLOBAL.GetTime()
    GLOBAL.SetServerPaused(false)
end)
-- (testing, to be removed: while paused, the arrow keys move you at once - an eighth of a unit,
-- with Shift half one, the way they point on screen; "'" puts you where the mouse is. The game's
-- clock doesn't move: what's drawn is drawn again for where you are now, and said again)
local function Warp(fn)
    local frontend = GLOBAL.TheFrontEnd
    if frontend == nil or frontend.textProcessorWidget ~= nil then return end
    local screen = frontend:GetActiveScreen()
    if screen == nil or screen.name ~= "HUD" then return end
    local world, player = GLOBAL.TheWorld, GLOBAL.ThePlayer
    if world == nil or not world.ismastersim or player == nil or player.Physics == nil
        or not GLOBAL.TheNet:IsServerPaused(true) then
        return
    end
    local x, _, z = player.Transform:GetWorldPosition()
    local nx, nz = fn(x, z)
    if nx == nil then return end
    player.Physics:Teleport(nx, 0, nz)
    -- (the camera with you at once - paused, it doesn't follow)
    if GLOBAL.TheCamera ~= nil then GLOBAL.TheCamera:Snap() end
    warped = true
    local line = string.format("moved %.2f, %.2f -> %.2f, %.2f (%.3f)", x, z, nx, nz, math.sqrt((nx - x) ^ 2 + (nz - z) ^ 2))
    print("[tr_pause] " .. line)
    if GLOBAL.ChatHistory ~= nil then
        GLOBAL.ChatHistory:AddToHistory(GLOBAL.ChatTypes.Message, nil, nil, "True Range", line, { .5, 1, .5, 1 }, nil, nil, true)
    end
end
local function Nudge(right, up)
    return function()
        Warp(function(x, z)
            local cam = GLOBAL.TheCamera
            if cam == nil then return nil end
            local step = TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) and .5 or .125
            local r, d = cam:GetRightVec(), cam:GetDownVec()
            return x + (r.x * right - d.x * up) * step, z + (r.z * right - d.z * up) * step
        end)
    end
end
TheInput:AddKeyDownHandler(GLOBAL.KEY_UP, Nudge(0, 1))
TheInput:AddKeyDownHandler(GLOBAL.KEY_DOWN, Nudge(0, -1))
TheInput:AddKeyDownHandler(GLOBAL.KEY_LEFT, Nudge(-1, 0))
TheInput:AddKeyDownHandler(GLOBAL.KEY_RIGHT, Nudge(1, 0))
-- (the game names no KEY_APOSTROPHE: its code, 39 - "'")
TheInput:AddKeyDownHandler(39, function()
    Warp(function()
        local p = TheInput:GetWorldPosition()
        if p == nil then return nil end
        return p.x, p.z
    end)
end)
-- (paused again within the very tick it ran - the game's own per-tick calls, inside its Update: not
-- from a static task (the game, mid-frame, then ran a tick paused and crashed - "Update() called
-- on paused server!"), nor a task in time 0 (that ran a tick later: two frames a step))
GLOBAL.RegisterStaticComponentUpdate("true_range_step", function()
    if step_from ~= nil then
        step_from = nil
        GLOBAL.SetServerPaused(true)
    end
end)
AddClassPostConstruct("screens/playerhud", function(self)
    local set = self.SetServerPaused
    self.SetServerPaused = function(hud, paused, ...)
        set(hud, paused, ...)
        if hud.serverpause_underlay ~= nil then hud.serverpause_underlay:Hide() end
    end
    if self.serverpause_underlay ~= nil then self.serverpause_underlay:Hide() end
end)
AddClassPostConstruct("widgets/redux/chatqueue", function(self)
    local push = self.PushMessage
    self.PushMessage = function(q, ...)
        push(q, ...)
        q.message_alpha_time[1] = GLOBAL.GetStaticTime() + 5
        q:RefreshWidgets(true)
    end
    self.CalculateChatAlpha = function(q, i)
        local at = i ~= nil and q.message_alpha_time[i] or nil
        if at == nil then return 0 end
        local past = GLOBAL.GetStaticTime() - at
        if past < 0 then return 1 end
        return past < 1 and 1 - past or 0
    end
end)
end

-- (testing, to be removed: a trace of each offline-run boss, every tick while it attacks - where
-- it is, which way it faces, how fast it goes, its state and how long in it, where you are; and
-- each strike it makes, from where, on whom - client_log.txt, "[tr_trace]")
-- (the local copy only - folder "true_range", not the Workshop's: in the game's profile it was 5% of
-- the host's Lua time with one boss, every player hosting with the Workshop's copy paying it)
local TRACE = DEBUG
-- (testing: where each move set as it stops aiming is drawn, frame by frame - true_range/simmoves
-- "[tr_draw]", the local copy only)
if TRACE then GLOBAL.rawset(GLOBAL, "TR_DRAWLOG", true) end
local SimData = require("true_range/moves_sim")
local QUIET_STATE = { idle = true, walk = true, walk_start = true, walk_stop = true, run = true,
    run_start = true, run_stop = true, taunt = true, hit = true }
-- (whom the traces are of: you - or, the testbench run on a server with no one on (tr_testbench, headless),
-- the stand-in it puts up for you: TR_BENCH_YOU)
-- (several side by side, each a boss of its own 300+ apart (its lanes, TR_BENCH_YOUS - VERIFY_PLAN 6.18): a
-- monster's "you" the stand-in nearest it)
local function You(inst)
    local list = GLOBAL.rawget(GLOBAL, "TR_BENCH_YOUS")
    if list ~= nil and inst ~= nil and inst.Transform ~= nil then
        local x, _, z = inst.Transform:GetWorldPosition()
        local best, bd = nil, math.huge
        for _, p in ipairs(list) do
            if p:IsValid() then
                local px, _, pz = p.Transform:GetWorldPosition()
                local d = (px - x) ^ 2 + (pz - z) ^ 2
                if d < bd then best, bd = p, d end
            end
        end
        if best ~= nil then return best end
    end
    -- (in a game: the one playing here (ThePlayer) - AllPlayers[1] is the host for everyone: a friend's log traced the host
    -- as "you", 2026-10-21)
    return GLOBAL.rawget(GLOBAL, "TR_BENCH_YOU") or GLOBAL.ThePlayer or GLOBAL.AllPlayers[1]
end
-- (debugging only - the testbench (tr_testbench) asking which animations begin a move of a monster, as
-- drawn here: its scene begun as the drawing's move is - not by its state's tags alone, the Eye of
-- Terror's charge and the Twins' none of "attack")
if DEBUG then
    GLOBAL.rawset(GLOBAL, "TR_MOVE_STARTS", function(prefab)
        local set = {}
        for _, m in ipairs(SimMovesPose.Moves(prefab) or {}) do
            if m.anims ~= nil and m.anims[1] ~= nil then set[m.anims[1]] = true end
        end
        return set
    end)
end
local function TraceLine(inst, what)
    local x, _, z = inst.Transform:GetWorldPosition()
    local vx, vz = 0, 0
    if inst.Physics ~= nil then
        local ok, a, _, c = GLOBAL.pcall(inst.Physics.GetVelocity, inst.Physics)
        if ok then vx, vz = a or 0, c or 0 end
    end
    local p = You(inst)
    local px, pz, pvx, pvz = 0, 0, 0, 0
    -- (one gone - a player leaving the world as a boss is traced, the testbench's stand-in removed: its
    -- place nothing, the line written with 0, 0 - not an error every tick)
    if p ~= nil and p:IsValid() then
        local a, _, c = p.Transform:GetWorldPosition()
        px, pz = a or 0, c or 0
        if p.Physics ~= nil then
            local ok, u, _, w = GLOBAL.pcall(p.Physics.GetVelocity, p.Physics)
            if ok then pvx, pvz = u or 0, w or 0 end
        end
    end
    local sg = inst.sg
    -- (the animation playing, by name - the replays can't tell an attack's _pst from it begun over
    -- else: the game says it only in its debug string)
    local anim_name = nil
    local okd, dbg = GLOBAL.pcall(function() return inst.entity:GetDebugString() end)
    if okd and type(dbg) == "string" then anim_name = dbg:match("anim: ([%w_]+)") end
    -- (" notarget": it has none - the replay's ent.replica.combat:GetTarget())
    local no_target = inst.components.combat ~= nil and inst.components.combat.target == nil
    -- (" forms=": the later forms it is in now, as the server tells with its poses - the replay sends the same)
    local forms = {}
    for _, m in ipairs(SimMovesPose.Moves(inst.prefab)) do
        local f = m.sim ~= nil and m.sim.after_mem or nil
        if f ~= nil and inst.sg ~= nil and inst.sg.mem[f] == true then forms[#forms + 1] = m.sim.after_anim end
    end
    -- (" me=": who "you" is - the first player, the host; " tgt=": whom its move goes at, as the
    -- server tells with its poses (aim), when that's someone else - a friend: the replays had only
    -- the host, and took every strike on a "wilson" for one on you)
    local tgt = ""
    local aim = sg ~= nil and sg.statemem ~= nil and sg.statemem.target or nil
    if not (type(aim) == "table" and aim.IsValid ~= nil and aim:IsValid() and aim.Transform ~= nil) then
        aim = inst.components.combat ~= nil and inst.components.combat.target or nil
    end
    if type(aim) == "table" and aim ~= p and aim.IsValid ~= nil and aim:IsValid() and aim.Transform ~= nil then
        local ax, _, az = aim.Transform:GetWorldPosition()
        tgt = string.format(" tgt=%.2f,%.2f,%s", ax, az, tostring(aim.prefab))
    end
    -- (" ram=": its charge's time and way left, as the server tells with its poses)
    local ps = pose_ents[inst]
    if ps ~= nil and ps.rams then
        local rt, rd = RamLeft(inst, ps, x, z, GLOBAL.GetTime())
        if rt >= 0 or rd >= 0 then tgt = tgt .. string.format(" ram=%.3f,%.2f", rt, rd) end
    end
    -- (" tpos=": the spot its move goes for, as its state took it - sent with its poses)
    local tpos = sg ~= nil and sg.statemem ~= nil and sg.statemem.targetpos or nil
    if type(tpos) == "table" and type(tpos.x) == "number" and type(tpos.z) == "number" then tgt = tgt .. string.format(" tpos=%.2f,%.2f", tpos.x, tpos.z)
    elseif sg ~= nil and sg.statemem ~= nil and type(sg.statemem.tgtx) == "number" and type(sg.statemem.tgtz) == "number" then
        tgt = tgt .. string.format(" tpos=%.2f,%.2f", sg.statemem.tgtx, sg.statemem.tgtz)
    end
    -- (" build=": how it looks - a move told apart by it (sim.look: Uncompromising Mode's icy Deerclops
    -- swiping in its old build) - the replays had only its name)
    if inst.AnimState.GetBuild ~= nil then
        local okb, b = GLOBAL.pcall(inst.AnimState.GetBuild, inst.AnimState)
        if okb and type(b) == "string" and b ~= "" then tgt = tgt .. " build=" .. b end
    end
    -- (" scale=": how big it is now - a move run offline at two sizes told apart only by it (Klaus
    -- enraged, a shadow piece levelled up: sim.scale) - the replays had none, and drew the smallest)
    if inst.Transform.GetScale ~= nil then
        local oks, sc = GLOBAL.pcall(inst.Transform.GetScale, inst.Transform)
        if oks and type(sc) == "number" then tgt = tgt .. string.format(" scale=%.3f", sc) end
    end
    print(string.format("[tr_trace] %.3f %s %s state=%s t=%.3f anim_t=%.3f pos=%.2f,%.2f rot=%.1f vel=%.2f,%.2f you=%.2f,%.2f d=%.2f guid=%d yvel=%.2f,%.2f%s%s me=%s%s forms=%s",
        GLOBAL.GetTime(), inst.prefab, what, sg ~= nil and sg.currentstate ~= nil and sg.currentstate.name or "?",
        sg ~= nil and sg.timeinstate or -1, inst.AnimState:GetCurrentAnimationTime(), x, z, inst.Transform:GetRotation(), vx, vz, px, pz,
        math.sqrt((px - x) ^ 2 + (pz - z) ^ 2), inst.GUID, pvx, pvz, no_target and " notarget" or "", anim_name and (" anim=" .. anim_name) or "",
        p ~= nil and tostring(p.prefab) or "?", tgt, #forms > 0 and table.concat(forms, ",") or "-"))
end
-- (for the testbench (tr_testbench): a freeze or a fire with no blow, told as the boss's strike - judged by what it drew)
SimMovesPose._trace_line = TraceLine
-- (and each thing a boss sets off that's run offline - spike trails, crystals, spell circles, spore
-- clouds: where it is and which way it faces, every tick near a player - "[tr_haz]"; the replay
-- draws them as the mod does)
-- (each thing the offline runs know, as it's made: kept, for Hazards - not all are found by a search)
Predict.made_hazards = GLOBAL.setmetatable({}, { __mode = "k" })
for prefab in pairs(SimData._hazards or {}) do
    AddPrefabPostInit(prefab, function(inst)
        -- (when: one made after a move began is that move's - true_range/predict, its tables)
        Predict.made_hazards[inst] = GLOBAL.GetTime()
    end)
end
-- (what a move's state makes as it begins, telling it from one begun alike - sim.tell, the shot's
-- eyeofterror_chargepulse: networked, made in every player's game - kept as each is made, for
-- true_range/predict)
do
    local tells = {}
    for boss, moves in pairs(SimData) do
        if type(boss) == "string" and boss:sub(1, 1) ~= "_" and type(moves) == "table" then
            for _, m in pairs(moves) do
                if type(m) == "table" and m.tell ~= nil then tells[m.tell] = true end
            end
        end
    end
    for prefab in pairs(tells) do
        AddPrefabPostInit(prefab, function(inst) Predict.tell_things[inst] = GLOBAL.GetTime() end)
    end
end
-- (what one strikes only near - the worm's holes: kept as each is made, in every player's game -
-- true_range/simmoves DrawHazard)
do
    local near = {}
    for _, h in pairs(SimData._hazards or {}) do
        if h.near ~= nil then near[h.near[1]] = true end
    end
    for prefab in pairs(near) do
        AddPrefabPostInit(prefab, function(inst) SimMovesPose.NearThing(inst) end)
    end
end
-- (the moment where you are was last written - "_you", once a tick; each stand-in's, with several)
local haz_you_at = GLOBAL.setmetatable({}, { __mode = "k" })
-- (a thing only moving: written once in this many ticks - tools/expand_haz.lua fills in between.
-- 1: every change - filled in, 2 or 3 ticks apart, the replays found 10% more drawn-in-unstruck)
local MOVE_EVERY = 1
-- (the lines of a tick written together, one print: the worm's hundred segments each its own print
-- was most of the cost of writing them - the same lines in the log)
-- (the game cuts what one print writes at about 4100 characters: written out before 3500 - a whole
-- tick's at once, the rest of each line was lost)
local HAZ_PRINT_MAX = 3500
local haz_buf, haz_n, haz_len = {}, 0, 0
local function HazFlush()
    if haz_n > 0 then
        print(table.concat(haz_buf, "\n", 1, haz_n))
        for i = 1, haz_n do haz_buf[i] = nil end
        haz_n, haz_len = 0, 0
    end
end
local function HazOut(s)
    if haz_len + #s + 1 > HAZ_PRINT_MAX then HazFlush() end
    haz_n = haz_n + 1
    haz_buf[haz_n] = s
    haz_len = haz_len + #s + 1
end
-- (each thing traced -> what it was last written as. One task on the world goes through them all:
-- a task each was the worm's hundreds of segments each run every tick, the traces on or off - the
-- game's scheduler making a table every tick holding them all, most of the garbage on the host
-- with ten worms, its frames slowed the more segments there were)
local haz_traced = {}
-- (written only as it changes - where it is, its turning, height, size - and "GONE" once it's no
-- longer traced; where you are once a tick, "_you", while any is: every thing every tick was up to
-- 10000 lines a second with the Crystal Deerclops' spikes, the host's frames slowed by the writing
-- alone. tools/expand_haz.lua makes it a line a tick again for the replays)
local function HazGone(inst, s)
    if s.said then
        HazOut(string.format("[tr_haz] %.3f %s guid=%d GONE", GLOBAL.GetTime(), inst.prefab, inst.GUID))
        s.said = false
    end
end
local haz_was_on = false
local function HazTick()
    if not trace_on then
        -- (turned off: each written one "GONE", once)
        if haz_was_on then
            haz_was_on = false
            for inst, s in pairs(haz_traced) do HazGone(inst, s) end
        end
        return
    end
    haz_was_on = true
    local many = GLOBAL.rawget(GLOBAL, "TR_BENCH_YOUS") ~= nil
    local p = You()
    local p_ok = p ~= nil and p:IsValid()
    for inst, s in pairs(haz_traced) do
        if many and inst:IsValid() then
            p = You(inst)
            p_ok = p ~= nil and p:IsValid()
        end
        -- (one that strikes only looking so - a worm segment with spikes: only then - the Great
        -- Depths Worm's hundred segments, every tick, were thousands of lines a second)
        local look = s.look
        -- (and only while it can strike - a flame put back in its pool (out of the scene), or dying
        -- down: written on, the replay drew it there long after)
        local off = SimMovesPose._off_anims[inst.prefab]
        if off ~= nil and inst:IsValid() and inst.AnimState ~= nil then
            for _, an in ipairs(off) do
                if inst.AnimState:IsCurrentAnimation(an) then off = true break end
            end
        end
        -- (nor, one striking only while it plays these (simmoves _on_anims), while it doesn't - as it's drawn: Uncompromising
        -- Mode's queen's guards, monsters with bites of their own besides, taken for charging the whole time, 2026-10-20)
        -- (or done by its own net value - the Queen's vines once come up: simmoves _off_nets)
        if off ~= true and inst:IsValid() and SimMovesPose.OffByNet(inst) then off = true end
        local on = SimMovesPose._on_anims[inst.prefab]
        if off ~= true and on ~= nil and inst:IsValid() and inst.AnimState ~= nil then
            off = true
            for _, an in ipairs(on) do
                if inst.AnimState:IsCurrentAnimation(an) then off = nil break end
            end
        end
        if p_ok and inst:IsValid() and inst:IsNear(p, 40) and off ~= true and not inst:IsInLimbo()
            and (look == nil or inst.AnimState == nil or inst.AnimState.GetBuild == nil or inst.AnimState:GetBuild() == look) then
            local x, y, z = inst.Transform:GetWorldPosition()
            local px, _, pz = p.Transform:GetWorldPosition()
            local now = GLOBAL.GetTime()
            if haz_you_at[p] ~= now then
                haz_you_at[p] = now
                HazFlush()
                HazOut(string.format("[tr_haz] %.3f _you you=%.2f,%.2f", now, px, pz))
            end
            -- (written as it changes, to the places written - compared as numbers: a string made for
            -- every thing every tick was most of the garbage the mod made, the game stalling to clear it)
            local rot, scale = inst.Transform:GetRotation(), (inst.Transform:GetScale())
            local qx, qz, qr = math.floor(x * 100 + .5), math.floor(z * 100 + .5), math.floor(rot * 10 + .5)
            local qy, qs = math.floor((y or 0) * 100 + .5), math.floor(scale * 1000 + .5)
            if not s.said or qx ~= s.x or qz ~= s.z or qr ~= s.r or qy ~= s.y or qs ~= s.s then
                s.said, s.x, s.z, s.r, s.y, s.s = true, qx, qz, qr, qy, qs
                HazOut(string.format("[tr_haz] %.3f %s guid=%d pos=%.2f,%.2f rot=%.1f you=%.2f,%.2f y=%.2f scale=%.3f", now, inst.prefab, inst.GUID, x, z,
                    rot, px, pz, y or 0, scale))
            end
        else
            HazGone(inst, s)
        end
    end
end
AddPrefabPostInit("world", function(w)
    if TRACE and w.ismastersim then
        w:DoPeriodicTask(1, HazFlush)
        w:DoPeriodicTask(0, HazTick)
    end
end)
-- (and what sets one of those off for real where it stands, not a boss - the Great Depths Worm's dirt,
-- pounding: traced too, for the replays to find it there as the mod does - true_range/thing_sources)
local traced_too = {}
do
    local ok, srcs = GLOBAL.pcall(require, "true_range/thing_sources")
    if ok and type(srcs) == "table" then
        for _, list in pairs(srcs) do
            for _, p in ipairs(list) do
                if (SimData._hazards or {})[p] == nil and SimData[p] == nil and ((SimData._alias or {})[p]) == nil then traced_too[p] = true end
            end
        end
    end
    -- (and the darts, the spit shot at you, drawn by this file's own code (DARTS): where each flies, for
    -- the replays to draw them as it does - VERIFY_PLAN C1)
    for p in pairs(DARTS) do
        if (SimData._hazards or {})[p] == nil then traced_too[p] = true end
    end
end
for prefab in pairs(traced_too) do
    AddPrefabPostInit(prefab, function(inst)
        if not TRACE or not GLOBAL.TheWorld.ismastersim then return end
        haz_traced[inst] = { said = false }
        inst:ListenForEvent("onremove", function()
            local s = haz_traced[inst]
            if s ~= nil then HazGone(inst, s) haz_traced[inst] = nil end
        end)
    end)
end
for prefab in pairs(SimData._hazards or {}) do
    AddPrefabPostInit(prefab, function(inst)
        if not TRACE or not GLOBAL.TheWorld.ismastersim then return end
        haz_traced[inst] = { look = SimData._hazards[prefab].look, said = false }
        inst:ListenForEvent("onremove", function()
            local s = haz_traced[inst]
            if s ~= nil then
                HazGone(inst, s)
                haz_traced[inst] = nil
            end
        end)
        -- (and each of its own blows that lands on a player - a spore cloud's, a crystal's)
        inst:ListenForEvent("onhitother", function(_, data)
            local target = data ~= nil and data.target or nil
            -- (one striking as a thing only while it plays these: its other blows its moves' - simmoves _on_anims)
            local on = SimMovesPose._on_anims[inst.prefab]
            if on ~= nil and inst.AnimState ~= nil then
                local playing = false
                for _, an in ipairs(on) do if inst.AnimState:IsCurrentAnimation(an) then playing = true end end
                if not playing then target = nil end
            end
            if target ~= nil and target:HasTag("player") then
                local x, _, z = inst.Transform:GetWorldPosition()
                local tx, _, tz = target.Transform:GetWorldPosition()
                print(string.format("[tr_haz] %.3f %s guid=%d HIT pos=%.2f,%.2f you=%.2f,%.2f", GLOBAL.GetTime(), inst.prefab, inst.GUID, x, z, tx, tz))
            end
        end)
    end)
end
-- (each monster traced -> where its surroundings were last written)
local boss_traced = {}
local function Traced(inst, p)
    if inst:HasTag("epic") then return inst:IsNear(p, 40) end
    local c = inst.components.combat
    -- (or striking near you after no one - sent at a spot by another: Uncompromising Mode's queen's guards diving where she
    -- says, notarget - not a line of them till they struck, nothing for the replays to judge, 2026-10-20)
    if c ~= nil and c.target ~= p and inst.sg ~= nil and inst.sg:HasStateTag("attack") and inst:IsNear(p, 20) then return true end
    -- (or right by you, after no one, in no "attack" state - the Umbral Abomination's hands running on the spot (shrouden_run),
    -- striking whoever comes by: 4 "missed" with no line of them, 2026-10-28)
    if c ~= nil and inst:IsNear(p, 6) then return true end
    return c ~= nil and c.target == p and inst:IsNear(p, 20)
end
-- (an offline test replays it: true_range_workshop tests/replay.lua)
local function BossTick()
    if not trace_on then return end
    local many = GLOBAL.rawget(GLOBAL, "TR_BENCH_YOUS") ~= nil
    local p = You()
    if p == nil or not p:IsValid() then return end
    -- (one well off from you looked at again only FAR_RECHECK on - every monster of these in the
    -- world asked every tick was most of the trace's time)
    local px, _, pz = p.Transform:GetWorldPosition()
    local now = GLOBAL.GetTime()
    for inst, e in pairs(boss_traced) do
        if (e.next_t == nil or now >= e.next_t) and inst:IsValid() then
            if many then
                p = You(inst)
                px, _, pz = p.Transform:GetWorldPosition()
            end
            local x, _, z = inst.Transform:GetWorldPosition()
            if (x - px) ^ 2 + (z - pz) ^ 2 > (40 + FAR_MARGIN) ^ 2 then
                e.next_t = now + FAR_RECHECK
            else
                e.next_t = nil
                if Traced(inst, p) then TraceLine(inst, "after") end
            end
        end
    end
end
-- (what's round it - so the replay knows what stops it: the ground it may stand on, a yes/no every
-- unit 40 round (as rows of 0/1), and each thing with a body - where, how big, its collision group,
-- whether it can be broken; again once it's gone 10 on, or every 10 seconds)
local function BossEnv(inst, e)
    local x, _, z = inst.Transform:GetWorldPosition()
    local now = GLOBAL.GetTime()
    if e.env_x ~= nil and (x - e.env_x) ^ 2 + (z - e.env_z) ^ 2 < 100 and now - e.env_t < 10 then return end
    e.env_x, e.env_z, e.env_t = x, z, now
    local map = GLOBAL.TheWorld.Map
    local cx, cz = math.floor(x + .5), math.floor(z + .5)
    local rows = {}
    for dz = -40, 40 do
        local row = {}
        for dx = -40, 40 do
            row[#row + 1] = map:IsPassableAtPoint(cx + dx, 0, cz + dz) and "1" or "0"
        end
        rows[#rows + 1] = table.concat(row)
    end
    -- (in parts of 40 rows, each saying its first (row0=): all 81 in one line was cut at the game's 4,095
    -- characters, rows 50-81 never written - the shark's water undecided, the twins agent 2026-10-19)
    -- (now 10 rows a line, under 1,000 characters: 40, 3,380, and the game's console opened over them crashed the
    -- game (BitmapFontRenderer text_len < MAX_NUM_CHARS), the player 2026-10-23)
    for r0 = 0, #rows - 1, 10 do
        local part = {}
        for k = r0 + 1, math.min(#rows, r0 + 10) do part[#part + 1] = rows[k] end
        print(string.format("[tr_env] %.3f %s guid=%d ground x0=%d z0=%d step=1 n=81 row0=%d %s", now, inst.prefab, inst.GUID,
            cx - 40, cz - 40, r0, table.concat(part, "/")))
    end
    local list = {}
    for _, v in ipairs(GLOBAL.TheSim:FindEntities(x, 0, z, 40, nil, { "INLIMBO", "FX", "NOCLICK", "DECOR", "player" })) do
        local ph = v.Physics
        if ph ~= nil and v ~= inst then
            local ok, group = GLOBAL.pcall(ph.GetCollisionGroup, ph)
            if ok and group ~= nil then
                local vx, _, vz = v.Transform:GetWorldPosition()
                local work = v:HasTag("CHOP_workable") or v:HasTag("MINE_workable") or v:HasTag("HAMMER_workable") or v:HasTag("DIG_workable")
                list[#list + 1] = string.format("%s:%.2f,%.2f,%.2f,%d,%d,%d", v.prefab or "?", vx, vz, v:GetPhysicsRadius(0), group,
                    work and 1 or 0, v:HasTag("_combat") and 1 or 0)
            end
        end
    end
    -- (in lines under 1,000 characters, as the ground above - a swarm round it made one line thousands long)
    local part, len = {}, 0
    for i, s in ipairs(list) do
        part[#part + 1] = s
        len = len + #s + 1
        if len > 900 or i == #list then
            print(string.format("[tr_env] %.3f %s guid=%d things %s", now, inst.prefab, inst.GUID, table.concat(part, ";")))
            part, len = {}, 0
        end
    end
    if #list == 0 then print(string.format("[tr_env] %.3f %s guid=%d things ", now, inst.prefab, inst.GUID)) end
end
AddPrefabPostInit("world", function(w)
    if not TRACE or not w.ismastersim then return end
    w:DoPeriodicTask(0, BossTick)
    w:DoPeriodicTask(.5, function()
        if not trace_on then return end
        local p = You()
        if p == nil or not p:IsValid() then return end
        for inst, e in pairs(boss_traced) do
            if inst:IsValid() and Traced(inst, You(inst)) then BossEnv(inst, e) end
        end
    end)
end)
-- (and every one drawn as another - a fire hound as a hound, the merm guards as a merm: never traced,
-- the testbench's replays had nothing of 26 such though they struck its stand-in thousands of times)
local traced_prefabs = {}
for prefab in pairs(SimData) do if prefab:sub(1, 1) ~= "_" then traced_prefabs[prefab] = true end end
for prefab in pairs(SimData._alias or {}) do traced_prefabs[prefab] = true end
local function TraceSetup(inst)
            -- (bosses; and any other only while it's after you - a pack of hounds idling, tick by
            -- tick, would bury the log; Klaus' deer were never traced at all)
            if not TRACE or not GLOBAL.TheWorld.ismastersim then
                return
            end
            inst:DoTaskInTime(0, function()
                local sg = inst.sg
                if sg == nil or not inst:IsValid() then
                    return
                end
                -- (every tick, whatever it does, while a player is near - one task on the world for
                -- them all, BossTick: one each was every monster of these anywhere in the world run
                -- every tick, the traces on or off)
                boss_traced[inst] = { env_t = -100 }
                inst:ListenForEvent("onremove", function() boss_traced[inst] = nil end)
                -- (each strike that lands: on whom)
                inst:ListenForEvent("onhitother", function(_, data)
                    local target = data ~= nil and data.target or nil
                    local who = tostring(target ~= nil and target.prefab or "?")
                    -- (another player than you: "other_player", as a STRIKE on one is)
                    if target ~= nil and target.HasTag ~= nil and (target:HasTag("player") or target:HasTag("character")) and target ~= You(inst) then who = "other_player" end
                    TraceLine(inst, "HIT at " .. who)
                end)
                -- (each one its area blow takes in (combat DoAreaAttack - a swing that missed falling to
                -- one round it, a stomp): told before it's struck, so a blow on you blocked is here too)
                inst:ListenForEvent("onareaattackother", function(_, data)
                    local target = data ~= nil and data.target or nil
                    if target ~= nil and target:HasTag("player") then
                        TraceLine(inst, "AREA at " .. (target ~= You(inst) and "other_player" or tostring(target.prefab)))
                    end
                end)
                -- (each strike: on whom)
                local combat = inst.components.combat
                if combat ~= nil then
                    local attack = combat.DoAttack
                    combat.DoAttack = function(self, target, ...)
                        -- (judged as the game's own DoAttack judges it (combat.lua): its reach from where and
                        -- how far it was told, with its weapon - a dart or a spit judged where it is, by its
                        -- own reach; out of it, a miss - dodged, or its area blow round it (MISSAREA))
                        local args = { ... }
                        -- (the trace's own error never the game's: the attack goes on whatever)
                        GLOBAL.pcall(function()
                            local weapon, projectile, range, pos = args[1], args[2], args[5], args[6]
                            local targ = target or self.target
                            -- (Uncompromising Mode's area swing (leif): its own DoAttack strikes each in its
                            -- cone again, each written then - this outer one strikes no one itself)
                            if self.um_areahit and not self.um_ignoreareahit then return end
                            local who = tostring(targ ~= nil and targ.prefab or "its target")
                            -- (another player, not you - with a friend: struck as "other_player", not counted on you; the testbench's
                            -- friend (watch) and a game with two of the same character were both "STRIKE at wilson", 2026-10-21)
                            if targ ~= nil and targ.HasTag ~= nil and (targ:HasTag("player") or targ:HasTag("character")) and targ ~= You(inst) then who = "other_player" end
                            -- (no one to strike: a miss, as the game has it - CanHitTarget(nil))
                            local can = false
                            if targ ~= nil and self.CanHitTarget ~= nil then
                                local had_range, had_pos = self.temprange, self.temppos
                                if range then self.temprange = range end
                                if pos then self.temppos = pos end
                                if weapon == nil and self.GetWeapon ~= nil then weapon = self:GetWeapon() end
                                can = self:CanHitTarget(targ, weapon) and not self.AOEarc
                                self.temprange, self.temppos = had_range, had_pos
                            elseif targ ~= nil then
                                can = true
                            end
                            local wc = weapon ~= nil and weapon.components or nil
                            if not can then
                                if self.areahitrange ~= nil and not self.areahitdisabled then
                                    TraceLine(inst, string.format("MISSAREA at %s r=%.2f%s", who, self.areahitrange,
                                        projectile ~= nil and (" by " .. tostring(projectile.prefab)) or ""))
                                end
                            elseif projectile ~= nil then
                                -- (its dart, its spit come to you: struck by that, where it is - not the boss swinging)
                                TraceLine(inst, "STRIKE by " .. tostring(projectile.prefab) .. " at " .. who)
                            elseif wc ~= nil and (wc.projectile ~= nil
                                or (wc.complexprojectile ~= nil and not wc.complexprojectile.ismeleeweapon)
                                or (wc.weapon ~= nil and wc.weapon.CanRangedAttack ~= nil and wc.weapon:CanRangedAttack())) then
                                -- (only shot off - it strikes once it's there, a "STRIKE by" of its own; named by
                                -- what it shoots - most such weapons are made without a prefab of their own)
                                local shot = weapon.prefab or (wc.weapon ~= nil and wc.weapon.projectile) or "?"
                                TraceLine(inst, "LAUNCH " .. tostring(shot) .. " at " .. who)
                            else
                                TraceLine(inst, "STRIKE at " .. who)
                            end
                        end)
                        return attack(self, target, ...)
                    end
                end
            end)
end
for prefab in pairs(traced_prefabs) do AddPrefabPostInit(prefab, TraceSetup) end
-- (and any other with a fight in it, data or none - one we've nothing for was never traced, so nothing could show
-- what it did: Uncompromising Mode's queen's guards struck the stand-in hundreds of times, not a line of them -
-- tools/nomove_check.lua sees only what's traced, 2026-10-20. The traces on only: TRACE)
if TRACE then
    AddPrefabPostInitAny(function(inst)
        if traced_prefabs[inst.prefab] or inst:HasTag("player") or inst.components == nil or inst.components.combat == nil then return end
        TraceSetup(inst)
    end)
end
