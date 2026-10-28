-- Server side: learning the shape of monsters' attacks from where they actually land.
-- Only works when a hit happens (the victim's "attacked" event names the attacker): it notes which move
-- the attacker was in, how far and at what angle from its facing the victim stood, and when
-- in the move it came. Over a few hits that gives each move a fan (or a circle) and its
-- damage frames, kept between games (a persistent string) and sent to players' games on
-- request (just the monsters they meet).
-- (its log lines only with the mod's debugging on - TR_DEBUG, modmain: debug.txt in the mod's folder)
local print = function(...) if rawget(_G, "TR_DEBUG") then _G.print(...) end end

local Preload = require("true_range/moves_preload")
local Probe = require("true_range/probe")
local SimData = require("true_range/moves_sim")

local Learn = {}

local FILE = "true_range_learned"
local SAVE_EVERY = 60            -- seconds between saves, when something changed
local MAX_PREFABS = 400
local MIN_HITS_FOR_FAN = 3       -- fewer hits than this: a circle (the side it hits isn't sure)
local FAN_MARGIN = 15            -- degrees added to the widest angle seen
local CIRCLE_FROM = 150          -- a fan this wide is a circle
local REACH_MARGIN = .2

-- prefab -> { version, moves = { [anim] = { hits, reach, angle, frames = { [frame] = true } } } }
local data = {}
local prefab_count = 0
local dirty = false

-- an animation for standing about or getting around, never an attack
local function IdleName(key)
    local k = string.lower(key)
    return k:find("idle", 1, true) ~= nil or k:find("^walk") ~= nil or k:find("^run") ~= nil
end

local function Load()
    TheSim:GetPersistentString(FILE, function(ok, text)
        if ok and text ~= nil and text ~= "" then
            local done, loaded = pcall(json.decode, text)
            if done and type(loaded) == "table" then
                data = loaded
                prefab_count = 0
                for _, p in pairs(data) do
                    prefab_count = prefab_count + 1
                    -- (travel learned before 2: only the trips that moved counted - start over)
                    if (p.format or 1) < 2 then
                        for _, m in pairs(p.moves or {}) do
                            m.travel, m.trips, m.drift = nil, nil, nil
                        end
                        p.format = 2
                        p.version = (p.version or 0) + 1
                        dirty = true
                    end
                    -- (probed before 3: without what probes now see - things a boss sets off,
                    -- damage a moment later, the round each point came in - probe again)
                    if p.format < 3 then
                        for _, m in pairs(p.moves or {}) do
                            m.pts, m.probe_rounds, m.probe_tries, m.noprobe = nil, nil, nil, nil
                        end
                        p.format = 3
                        p.version = (p.version or 0) + 1
                        dirty = true
                    end
                    -- (before 4: probes lacked what effects reach for on what got hit - those
                    -- moves get another try; and hits while standing about were taken for moves)
                    if p.format < 4 then
                        for key, m in pairs(p.moves or {}) do
                            if m.noprobe then
                                m.noprobe, m.probe_tries = nil, nil
                            end
                            if IdleName(key) then
                                m.hits, m.reach, m.angle, m.frames = 0, 0, 0, {}
                                m.side, m.ahead, m.front, m.on_target, m.off_target = nil, nil, nil, nil, nil
                            end
                        end
                        p.format = 4
                        p.version = (p.version or 0) + 1
                        dirty = true
                    end
                    -- (before 5: a boss's next phase was taken for something it set off, and
                    -- spikes' hits for the boss's: probe everything again)
                    if p.format < 5 then
                        for _, m in pairs(p.moves or {}) do
                            m.pts, m.probe_rounds, m.probe_tries, m.noprobe = nil, nil, nil, nil
                        end
                        p.spawns = nil
                        p.format = 5
                        p.version = (p.version or 0) + 1
                        dirty = true
                    end
                    -- (before 6: probes answered wide searches for targets too - the boss aimed
                    -- spikes at them - and points didn't say where its target stood: again)
                    if p.format < 6 then
                        for _, m in pairs(p.moves or {}) do
                            m.pts, m.probe_rounds, m.probe_tries, m.noprobe, m.at_n, m.at_ok = nil, nil, nil, nil, nil, nil
                        end
                        p.spawns = nil
                        p.format = 6
                        p.version = (p.version or 0) + 1
                        dirty = true
                    end
                end
            end
        end
    end)
end

local function Save()
    if dirty then
        dirty = false
        TheSim:SetPersistentString(FILE, json.encode(data), false)
    end
end

-- the move an entity is in: the first animation of the matching preloaded move (so it names
-- moves the way players' games see them start), or else its current animation
local function MoveKey(ent)
    local moves = Preload[ent.prefab]
    for _, move in ipairs(moves or {}) do
        for _, anim in ipairs(move.anims) do
            if ent.AnimState:IsCurrentAnimation(anim) then
                return move.anims[1], ent.AnimState:GetCurrentAnimationTime()
            end
        end
    end
    -- (not preloaded: its animation's name, from the engine's debug text - only on a hit)
    local text = ent.entity:GetDebugString() or ""
    local anim = text:match("anim:%s*([%w_]+)")
    if anim ~= nil then
        return anim, ent.AnimState:GetCurrentAnimationTime()
    end
    return nil
end

local function Prefab(prefab)
    local p = data[prefab]
    if p == nil then
        if prefab_count >= MAX_PREFABS then
            return nil
        end
        p = { version = 0, format = 6, moves = {} }
        data[prefab] = p
        prefab_count = prefab_count + 1
    end
    return p
end

local function Move(p, key)
    local m = p.moves[key]
    if m == nil then
        m = { hits = 0, reach = 0, angle = 0, frames = {} }
        p.moves[key] = m
    end
    return m
end

local function Changed(p)
    p.version = p.version + 1
    dirty = true
end

-- (dx, dz) seen from something facing `rot` degrees: how far ahead, and how far to the side
local function Local(dx, dz, rot)
    local r = rot * DEGREES
    local c, s = math.cos(r), math.sin(r)
    return dx * c - dz * s, math.abs(dx * s + dz * c)
end

-- mv: the move it's in now (its first hit there, for when it's over: true_range_move)
function Learn.NoteProgress(m, progress, mv)
    m.prog_min = math.min(m.prog_min or math.huge, progress)
    if mv ~= nil then
        mv.hit_prog = math.min(mv.hit_prog or math.huge, progress)
    end
end

local SINGLE_FROM = 3   -- hits, all on what it was after: it only ever hits its target

function Learn.Hit(attacker, victim)
    if attacker == nil or victim == nil or attacker == victim or attacker:HasTag("player")
        or attacker.AnimState == nil or not attacker:IsValid() or not victim:IsValid() then
        return
    end
    local key, t = MoveKey(attacker)
    if key == nil or IdleName(key) then
        return
    end
    -- (something it set off did this - a spike, a laser: not its move)
    local actor = Probe.Actor()
    if actor ~= nil and actor ~= attacker then
        return
    end
    -- (standing about or walking when something hit: not its move - a trap it set, a spike)
    local sg = attacker.sg
    if sg ~= nil and sg.HasStateTag ~= nil and (sg:HasStateTag("idle") or sg:HasStateTag("moving")) then
        return
    end
    local ax, _, az = attacker.Transform:GetWorldPosition()
    local vx, _, vz = victim.Transform:GetWorldPosition()
    local dx, dz = vx - ax, vz - az
    local dist = math.sqrt(dx * dx + dz * dz)
    local vr = victim:GetPhysicsRadius(0)
    local reach = math.max(0, dist - vr)
    local facing = attacker.Transform:GetRotation()
    local angle = dist > .05 and math.abs(DiffAngle(facing, math.atan2(-dz, dx) / DEGREES)) or 0
    local ahead, side = Local(dx, dz, facing)

    local p = Prefab(attacker.prefab)
    if p == nil then
        return
    end
    local m = Move(p, key)
    local changed = false
    m.hits = m.hits + 1
    if reach > m.reach + .05 then
        m.reach = reach
        changed = true
    end
    if angle > m.angle + 1 then
        m.angle = angle
        changed = true
    end
    -- (for telling a straight beam apart: how far to its side, and how far ahead, hits came)
    local side_reach = math.max(0, side - vr)
    if side_reach > (m.side or 0) + .05 then
        m.side = side_reach
        changed = true
    end
    if ahead > (m.ahead or 0) + .05 then
        m.ahead = ahead
        changed = true
    end
    -- (and how far in front of it, past the victim's body: a charge's hits reach ahead of it)
    local front = ahead - vr
    if front > (m.front or 0) + .05 then
        m.front = front
        changed = true
    end
    -- (how far it had come since the move began: a leap only hits where it lands)
    local mv = attacker._true_range_move
    if mv ~= nil and mv.key == key then
        Learn.NoteProgress(m, (Local(ax - mv.x, az - mv.z, mv.rot)), mv)
    end
    -- (was it what it's after? a move that only ever hits its target is no area attack:
    -- whoever it's after, within its hit range, is hit - nobody else)
    local combat = attacker.components ~= nil and attacker.components.combat or nil
    if combat ~= nil and combat.target == victim then
        m.on_target = (m.on_target or 0) + 1
        if m.on_target == SINGLE_FROM and (m.off_target or 0) == 0 then
            changed = true
        end
    else
        m.off_target = (m.off_target or 0) + 1
        if m.off_target == 1 then
            changed = true
        end
    end
    local frame = tostring(math.floor((t or 0) / FRAMES + .5))
    if not m.frames[frame] then
        m.frames[frame] = true
        changed = true
    end
    if m.hits == MIN_HITS_FOR_FAN then
        changed = true -- (its shape changes from a circle)
    end
    if changed then
        Changed(p)
    end
end

-- Big monsters' moves as they go from one to the next (the "newstate" event, only on bosses
-- and large creatures): how far each move carries it (a charge, a leap) and which move
-- usually follows which (a wind-up, then the charge).
local MIN_TRAVEL = 2   -- moving less than this in a move isn't a charge
local MAX_FOLLOWS = 6  -- moves remembered as coming after one
local TURN_DEGREES = 5 -- turning more than this during a move: it took aim
local AIM_TOLERANCE = 2 -- stopping this close to where its target stood: it went for the target
local AIM_GAP = 4       -- ...or ending up this close to its target
local CHASE_TURN = 15   -- turning more than this on the way: it steers
local LEAP_FROM = .6    -- hits only once it's come this much of the way: a leap

-- the first frame of a move its damage comes on (read from the code, or learned)
local function FirstHitFrame(prefab, key)
    local first = nil
    for _, move in ipairs(Preload[prefab] or {}) do
        if move.anims[1] == key then
            for _, f in ipairs(move.frames) do
                first = math.min(first or f, f)
            end
        end
    end
    if first == nil then
        local p = data[prefab]
        local m = p ~= nil and p.moves[key] or nil
        for f in pairs(m ~= nil and m.frames or {}) do
            local n = tonumber(f)
            if n ~= nil and n > 0 then
                first = math.min(first or n, n)
            end
        end
    end
    return first
end

function Learn.OnNewState(inst)
    -- (the state before is over: what probing it showed)
    Probe.Finish(inst)
    if not inst:IsValid() or inst.AnimState == nil then
        return
    end
    local now = GetTime()
    local x, _, z = inst.Transform:GetWorldPosition()
    local key = MoveKey(inst)
    local prev = inst._true_range_move
    -- (walking, running, standing about and flinching are never a move)
    if prev ~= nil and prev.key ~= nil and not prev.walking then
        local p = Prefab(inst.prefab)
        if p ~= nil then
            local ahead, side = Local(x - prev.x, z - prev.z, prev.rot)
            if now - prev.t > .1 then
                -- (every time counts, the ones it hardly moved too: a move that only slides
                -- now and then - a charge's wind-down - averages out to no charge)
                local m = Move(p, prev.key)
                local n = m.trips or 0
                local before = m.travel or 0
                m.trips = n + 1
                m.travel = (before * n + math.max(0, ahead)) / (n + 1)
                if ahead >= MIN_TRAVEL then
                    m.drift = math.max(m.drift or 0, side)
                end
                if (before >= MIN_TRAVEL) ~= (m.travel >= MIN_TRAVEL)
                    or (m.travel >= MIN_TRAVEL and math.abs(m.travel - before) > .25) then
                    Changed(p)
                end
                if ahead >= MIN_TRAVEL then
                    m.travel_max = math.max(m.travel_max or 0, ahead)
                    -- (did it go for its target? it went as far as its target stood when it
                    -- began, or it ended up by its target - it may have aimed again on the way)
                    local combat = inst.components ~= nil and inst.components.combat or nil
                    local target = combat ~= nil and combat.target or nil
                    local gap = nil
                    if target ~= nil and target:IsValid() then
                        local tx, _, tz = target.Transform:GetWorldPosition()
                        gap = math.sqrt((tx - x) ^ 2 + (tz - z) ^ 2)
                    end
                    if prev.target_ahead ~= nil or gap ~= nil then
                        m.aim_n = (m.aim_n or 0) + 1
                        if (prev.target_ahead ~= nil and math.abs(ahead - prev.target_ahead) <= AIM_TOLERANCE)
                            or (gap ~= nil and gap <= AIM_GAP) then
                            m.aim_ok = (m.aim_ok or 0) + 1
                        end
                        if m.aim_n == 2 then
                            Changed(p)
                        end
                    end
                    -- (did it turn on the way? with going for its target: it chases it)
                    m.turn_n = (m.turn_n or 0) + 1
                    if math.abs(DiffAngle(inst.Transform:GetRotation(), prev.rot)) > CHASE_TURN then
                        m.turn_ok = (m.turn_ok or 0) + 1
                    end
                    -- (a leap: it only hit once it had come most of this trip - however far that was)
                    if prev.hit_prog ~= nil then
                        m.leap_n = (m.leap_n or 0) + 1
                        if prev.hit_prog >= LEAP_FROM * ahead then
                            m.leap_ok = (m.leap_ok or 0) + 1
                        end
                        Changed(p)
                    end
                end
            end
            -- (a wind-up has no hit and no travel of its own: it's remembered for what follows it)
            -- (counted twice over: all told, and apart for when it turned during the move - took
            -- aim at something - and when it held still: a charge that winds down into another
            -- turns towards its next target, the last one of a run doesn't)
            if key ~= nil and key ~= prev.key then
                local m = Move(p, prev.key)
                local turned = math.abs(DiffAngle(inst.Transform:GetRotation(), prev.rot)) > TURN_DEGREES
                for _, field in ipairs({ "next", turned and "next_turned" or "next_still" }) do
                    local counts = m[field] or {}
                    m[field] = counts
                    if counts[key] ~= nil or GetTableSize(counts) < MAX_FOLLOWS then
                        counts[key] = (counts[key] or 0) + 1
                        if counts[key] == 2 then
                            Changed(p) -- (seen twice: worth telling)
                        end
                    end
                end
            end
        end
    end
    local sg = inst.sg
    local walking = sg ~= nil and (sg:HasStateTag("moving") or sg:HasStateTag("running") or sg:HasStateTag("idle")
        or sg:HasStateTag("hit"))
    -- (an animation of a move that's also how it starts running, or stands: players can't tell
    -- one from the other - the move's not foretold from it)
    if walking and key ~= nil then
        local p = data[inst.prefab]
        local m = p ~= nil and p.moves[key] or nil
        if m ~= nil and not m.shared then
            m.shared = true
            Changed(p)
        end
    end
    local rot = inst.Transform:GetRotation()
    -- (how far ahead its target stands now)
    local combat = inst.components ~= nil and inst.components.combat or nil
    local target = combat ~= nil and combat.target or nil
    local target_ahead = nil
    if target ~= nil and target:IsValid() then
        local tx, _, tz = target.Transform:GetWorldPosition()
        target_ahead = Local(tx - x, tz - z, rot)
    end
    local mv = { key = key, x = x, z = z, rot = rot, t = now, walking = walking, target_ahead = target_ahead }
    inst._true_range_move = mv
    -- (a move still being learned: probe it - true_range/probe)
    inst._true_range_state_n = (inst._true_range_state_n or 0) + 1
    -- (where it is when its damage comes - even if nothing gets hit: a leap is still in the air
    -- then, most of the way)
    local first = key ~= nil and not walking and FirstHitFrame(inst.prefab, key) or nil
    if first ~= nil and inst.DoTaskInTime ~= nil then
        local n = inst._true_range_state_n
        local delay = math.max(0, first * FRAMES - (inst.AnimState:GetCurrentAnimationTime() or 0))
        inst:DoTaskInTime(delay, function()
            if inst._true_range_state_n == n and inst:IsValid() then
                local hx, _, hz = inst.Transform:GetWorldPosition()
                local d = Local(hx - mv.x, hz - mv.z, mv.rot)
                mv.hit_prog = math.min(mv.hit_prog or math.huge, d)
            end
        end)
    end
    inst._true_range_probe_key = key ~= nil and not walking and Learn.NeedsProbe(inst.prefab, key) and key or nil
end

-- what a player's game gets, per move: "anim,radius,half,frames,travel,width,next"
--   radius/half: a fan (half 180: a circle); width > 0: a straight beam that wide to each side
--   and `radius` long instead; travel: how far the move carries it (a charge: then width is
--   how far its hits land to its sides, radius how far in front); next: the move that
--   usually follows (seen twice or more); offset: how far ahead of it the fan's middle is;
--   probed: 1 if measured with probes (exact - not just as far as hits happened to land)
local AIM_SHARE = .5    -- landing where its target stood this often: it aims at its target
local LINE_SIDE = 1.2   -- hits never further than this to its side...
local LINE_AHEAD = 6    -- ...and reaching this far ahead: a beam, not a fan

--------------------------------------------------------------------------------
-- probing (true_range/probe): points around a boss, seen from it (ahead, side), hit or not

local PROBE_ROUNDS = 5     -- rounds with a probe hit per move, then it's known
local PROBE_TRIES = 8      -- rounds without any hit: its code doesn't attack probes
local MAX_POINTS = 800     -- points kept per move

-- a boss sets off things that hurt (traps, spikes, lasers): players near it are told which
function Learn.NoteSpawn(boss, thing)
    local p = Prefab(boss)
    if p ~= nil then
        p.spawns = p.spawns or {}
        if not p.spawns[thing] and GetTableSize(p.spawns) >= 12 then
            return
        end
        p.spawns[thing] = true
        Changed(p) -- (also when the thing learned more: its version goes along)
    end
end

function Learn.NeedsProbe(prefab, key)
    -- (run offline from the game's code already: never probed)
    if SimData[prefab] ~= nil then
        return false
    end
    local p = data[prefab]
    local m = p ~= nil and p.moves[key] or nil
    if m == nil then
        return true
    end
    if m.noprobe then
        return false
    end
    -- (a move that carries it, not yet known whether it hits all the way or only at the end;
    -- probed before that was noted: once more)
    if (m.travel or 0) >= MIN_TRAVEL and m.prog_min == nil then
        return (m.probe_tries or 0) < PROBE_TRIES
    end
    return (m.probe_rounds or 0) < PROBE_ROUNDS
end

function Learn.ProbeFailed(prefab, key)
    local p = Prefab(prefab)
    if p ~= nil then
        Move(p, key).noprobe = true
        dirty = true
    end
end

function Learn.ProbeMissed(prefab, key)
    local p = Prefab(prefab)
    if p ~= nil then
        local m = Move(p, key)
        m.probe_tries = (m.probe_tries or 0) + 1
        if m.probe_tries >= PROBE_TRIES and (m.probe_rounds or 0) == 0 then
            m.noprobe = true
        end
        dirty = true
    end
end

-- points: { { ahead, side, hit }, ... }; frames: when in the move the probes were hit;
-- progress: how far it had come since the move began, each time
-- at_target: the points are seen from where its target stood (something thrown at it)
function Learn.Probed(prefab, key, frames, points, progress, mv, at_target)
    local p = Prefab(prefab)
    if p == nil then
        return
    end
    local m = Move(p, key)
    m.at_n = (m.at_n or 0) + 1
    if at_target then
        m.at_ok = (m.at_ok or 0) + 1
    end
    for _, d in ipairs(progress or {}) do
        Learn.NoteProgress(m, d, mv)
    end
    m.probe_rounds = (m.probe_rounds or 0) + 1
    m.pts = m.pts or {}
    for _, pt in ipairs(points) do
        local ahead, side, hit = pt[1], pt[2], pt[3]
        -- (and how far ahead its target stood then, if it had one)
        local entry = { math.floor(ahead * 100 + .5) / 100, math.floor(side * 100 + .5) / 100, hit and 1 or 0,
            m.probe_rounds, pt[4] ~= nil and math.floor(pt[4] * 100 + .5) / 100 or nil }
        if #m.pts < MAX_POINTS then
            table.insert(m.pts, entry)
        else
            -- (full: a hit takes a miss's place - hits are what's rare; a miss takes anyone's)
            local i = math.random(#m.pts)
            if hit then
                for _ = 1, 8 do
                    if m.pts[i][3] == 0 then
                        break
                    end
                    i = math.random(#m.pts)
                end
                m.pts[i] = entry
            elseif m.pts[i][3] == 0 then
                m.pts[i] = entry
            end
        end
        if hit then
            -- (like a hit on something with no body: Learn.Hit)
            local dist = math.sqrt(ahead * ahead + side * side)
            m.hits = m.hits + 1
            m.reach = math.max(m.reach, dist)
            if dist > .3 then
                m.angle = math.max(m.angle, math.abs(math.atan2(side, ahead)) / DEGREES)
            end
            m.side = math.max(m.side or 0, math.abs(side))
            m.ahead = math.max(m.ahead or 0, ahead)
            m.front = math.max(m.front or 0, ahead)
        end
    end
    for _, f in ipairs(frames) do
        m.frames[tostring(f)] = true
    end
    Changed(p)
end

-- The shape that fits the probes best: a fan (or a circle: half 180) centred `offset` ahead
-- of it, as small as it can be while holding every hit; of those, the one with the fewest
-- misses inside it. Returns radius, half (degrees), offset - or nil without hits.
local FIT_OFFSETS = { -2, -1.5, -1, -.75, -.5, -.25, 0, .25, .5, .75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3, 4 }
local FIT_MARGIN = .1      -- (the probes are only so close together)
local FIT_ANGLE_MARGIN = 4

-- ...plus, maybe, a circle all round it (`inner`) holding the hits close by: an attack in two
-- parts (Deerclops: a cone of spikes far ahead, and some all round it close by)
local FIT_INNER = { 0, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5 }

local function Fit(pts)
    local any = false
    for _, pt in ipairs(pts) do
        if pt[3] == 1 then
            any = true
            break
        end
    end
    if not any then
        return nil
    end
    local best = nil
    for _, c in ipairs(FIT_INNER) do
        local inner = c > 0 and c + FIT_MARGIN or 0
        for _, o in ipairs(FIT_OFFSETS) do
            -- the fan: around the hits the inner circle doesn't hold
            local r, half, rest = 0, 0, false
            for _, pt in ipairs(pts) do
                if pt[3] == 1 and pt[1] * pt[1] + pt[2] * pt[2] > inner * inner then
                    rest = true
                    local a, s = pt[1] - o, pt[2]
                    local d = math.sqrt(a * a + s * s)
                    r = math.max(r, d)
                    if d > .3 then
                        half = math.max(half, math.abs(math.atan2(s, a)) / DEGREES)
                    end
                end
            end
            if rest then
                r = r + FIT_MARGIN
                half = half + FIT_ANGLE_MARGIN
                if half >= CIRCLE_FROM then
                    half = 180
                end
            end
            local wrong = 0
            for _, pt in ipairs(pts) do
                if pt[3] == 0 then
                    local a, s = pt[1] - o, pt[2]
                    local d = math.sqrt(a * a + s * s)
                    local in_fan = rest and d <= r and (half >= 180 or d < .01 or math.abs(math.atan2(s, a)) / DEGREES <= half)
                    if in_fan or pt[1] * pt[1] + pt[2] * pt[2] <= inner * inner then
                        wrong = wrong + 1
                    end
                end
            end
            local area = r * r * half + inner * inner * 180
            if best == nil or wrong < best.wrong or (wrong == best.wrong and area < best.area - .01) then
                best = { wrong = wrong, area = area, r = r, half = half, o = o, inner = inner }
            end
            if not rest then
                break -- (no fan: the offset doesn't matter)
            end
        end
    end
    return best.r, best.half, best.o, best.inner, best.wrong
end

Learn._fit = Fit

-- When no fan fits well (lasers going three ways, things scattered about), the probes
-- themselves are sent: a map around it, in sectors (seen from it, by angle off its facing)
-- and rings, each cell marked if hits came there. "hex" of the cells, sector by sector.
local GRID = { sectors = 40, step = 1, rings = 20 }
Learn.GRID = GRID
local GRID_OVERREACH = 2.8 -- a fan this many times bigger than where hits came: use the map...
local GRID_WRONG = .2      -- ...or with this many misses inside it (for each hit)...
local GRID_STEADY = 1.8    -- ...if the cells hit were hit in this many rounds each, on average

local function Cell(ahead, side)
    local d = math.sqrt(ahead * ahead + side * side)
    local ring = math.floor(d / GRID.step)
    if ring >= GRID.rings then
        return nil
    end
    local a = math.atan2(side, ahead) -- (-pi..pi)
    local sector = math.floor((a + math.pi) / (2 * math.pi) * GRID.sectors) % GRID.sectors
    return sector * GRID.rings + ring
end
Learn.Cell = Cell

-- The map can be seen three ways (Learn.GRID_MODES): from the monster (0); from where its
-- target stood (1: an attack laid around its target - arcs through it); or scaled by how far
-- its target stood (2: aimed through its target - lasers reaching past it). A point in mode
-- `mode` (nil: it can't be seen that way - no target then).
local GRID_REF = 8   -- (mode 2: as if its target stood this far ahead)
Learn.GRID_REF = GRID_REF

local function InMode(pt, mode)
    local d = pt[5]
    if mode == 0 then
        return pt[1], pt[2]
    elseif d == nil or d < 1 then
        return nil
    elseif mode == 1 then
        return pt[1] - d, pt[2]
    end
    return pt[1] * GRID_REF / d, pt[2] * GRID_REF / d
end

-- Returns the marked cells, how many, and how many rounds on average each marked cell was hit
-- in (the same pattern every time - lasers - is hit round after round; scattered spikes aren't).
local function GridCells(pts, mode)
    local hits, misses, rounds = {}, {}, {}
    for _, pt in ipairs(pts) do
        local a, s = InMode(pt, mode or 0)
        local c = a ~= nil and Cell(a, s) or nil
        if c ~= nil then
            if pt[3] == 1 then
                hits[c] = (hits[c] or 0) + 1
                rounds[c] = rounds[c] or {}
                rounds[c][pt[4] or 0] = true
            else
                misses[c] = (misses[c] or 0) + 1
            end
        end
    end
    local seen, in_rounds = 0, 0
    for _, r in pairs(rounds) do
        seen = seen + 1
        in_rounds = in_rounds + GetTableSize(r)
    end
    local steady = seen > 0 and in_rounds / seen or 0
    local cells, count = {}, 0
    for c, n in pairs(hits) do
        if (misses[c] or 0) < 3 * n then
            cells[c] = true
            count = count + 1
        end
    end
    -- (holes no probe happened to land in, between marked cells along a ray or across one:
    -- marked too, unless probes there missed)
    local fill = {}
    for sector = 0, GRID.sectors - 1 do
        for ring = 0, GRID.rings - 1 do
            local c = sector * GRID.rings + ring
            if not cells[c] and (misses[c] or 0) == 0 then
                local left = ((sector - 1) % GRID.sectors) * GRID.rings + ring
                local right = ((sector + 1) % GRID.sectors) * GRID.rings + ring
                local along = ring > 0 and ring < GRID.rings - 1 and cells[c - 1] and cells[c + 1]
                if along or (cells[left] and cells[right]) then
                    table.insert(fill, c)
                end
            end
        end
    end
    for _, c in ipairs(fill) do
        cells[c] = true
        count = count + 1
    end
    return cells, count, steady
end

-- how many cells the fitted shape covers
local function FitCells(r, half, o, inner)
    local count = 0
    for sector = 0, GRID.sectors - 1 do
        local a = (sector + .5) / GRID.sectors * 2 * math.pi - math.pi
        for ring = 0, GRID.rings - 1 do
            local d = (ring + .5) * GRID.step
            local ahead, side = d * math.cos(a), d * math.sin(a)
            local fa, fs = ahead - o, side
            local fd = math.sqrt(fa * fa + fs * fs)
            local in_fan = r > 0 and fd <= r and (half >= 180 or fd < .01 or math.abs(math.atan2(fs, fa)) / DEGREES <= half)
            if in_fan or d <= inner then
                count = count + 1
            end
        end
    end
    return count
end

local HEX = "0123456789abcdef"
local function GridText(cells)
    local out = {}
    local total = GRID.sectors * GRID.rings
    for i = 0, total - 1, 4 do
        local v = 0
        for b = 0, 3 do
            if cells[i + b] then
                v = v + 2 ^ b
            end
        end
        table.insert(out, HEX:sub(v + 1, v + 1))
    end
    return table.concat(out)
end

function Learn.GridFromText(text)
    if text == nil or text == "" then
        return nil
    end
    local cells = {}
    for i = 1, #text do
        local v = (HEX:find(text:sub(i, i), 1, true) or 1) - 1
        for b = 0, 3 do
            if v % 2 == 1 then
                cells[(i - 1) * 4 + b] = true
            end
            v = math.floor(v / 2)
        end
    end
    return cells
end

-- the move that follows most often (seen twice or more), and how often: "anim@percent" (""
-- if none, or if fewer than `least` moves were seen after it)
local function Follows(counts, least)
    local key, best, total = "", 1, 0
    for k, n in pairs(counts or {}) do
        total = total + n
        if n > best then
            key, best = k, n
        end
    end
    if key == "" or total < (least or 0) then
        return ""
    end
    return string.format("%s@%d", key, math.floor(100 * best / total + .5))
end

function Learn.Encode(prefab)
    local p = data[prefab]
    if p == nil then
        return ""
    end
    local parts = {}
    for anim, m in pairs(p.moves) do
        local half, width, radius = 180, 0, m.reach + REACH_MARGIN
        local offset, probed, inner = 0, 0, 0
        local fr, fh, fo, fi, fw = nil, nil, nil, nil, 0
        if m.pts ~= nil and (m.probe_rounds or 0) > 0 then
            fr, fh, fo, fi, fw = Fit(m.pts)
        end
        -- a leap: it carries it, but hits only once it's most of the way (where it lands)
        local travel = m.travel or 0
        local leap = false
        if travel >= MIN_TRAVEL then
            if (m.leap_n or 0) > 0 then
                leap = (m.leap_ok or 0) / m.leap_n >= .6
            else
                leap = m.prog_min ~= nil and m.prog_min >= LEAP_FROM * travel
            end
        end
        -- it only ever hits what it's after (no probe ever hit either): its target, if in reach
        local single = (m.on_target or 0) >= SINGLE_FROM and (m.off_target or 0) == 0 and (m.probe_rounds or 0) == 0
        -- it lands where its target stood (most times)
        local aim = (m.aim_n or 0) >= 2 and (m.aim_ok or 0) / m.aim_n >= AIM_SHARE
        -- it steers after its target on the way (turns, and ends up by it): it chases
        local chase = not leap and travel >= MIN_TRAVEL and aim and (m.turn_n or 0) >= 2
            and (m.turn_ok or 0) / m.turn_n >= .5
        -- no fan fits (it reaches far wider than where hits came): the map of where they came
        -- (a pattern that's the same every time - lasers - and that the fan overstates: misses
        -- inside it, or it's much bigger than where hits came)
        local grid, grid_mode = "", 0
        if fr ~= nil and travel < MIN_TRAVEL and (m.probe_rounds or 0) >= 2 then
            local cells, count, steady = GridCells(m.pts, 0)
            -- (seen the way its pattern holds steadiest - lasers aimed through where its target
            -- stood keep their shape scaled by how far that was)
            local with_target = 0
            for _, pt in ipairs(m.pts) do
                if pt[5] ~= nil and pt[5] >= 1 then
                    with_target = with_target + 1
                end
            end
            -- (steadiest and tightest: hit round after round, in as few cells as it takes;
            -- another way only if clearly better)
            local function Score(n, st)
                return n > 0 and st / math.sqrt(n) or 0
            end
            local best_cells, best_count, best_steady, best_mode = cells, count, steady, 0
            local best_score = Score(count, steady) * 1.05
            if with_target >= .8 * #m.pts then
                for _, mode in ipairs({ 1, 2 }) do
                    local c2, n2, s2 = GridCells(m.pts, mode)
                    if n2 >= 4 and Score(n2, s2) > best_score then
                        best_cells, best_count, best_steady, best_mode = c2, n2, s2, mode
                        best_score = Score(n2, s2)
                    end
                end
            end
            local overreach = count >= 4 and FitCells(fr, fh, fo, fi or 0) > GRID_OVERREACH * count
            local wrong = fw >= math.max(5, GRID_WRONG * m.hits) and best_steady >= GRID_STEADY
            if best_count >= 4 and (overreach or wrong) then
                grid, grid_mode = GridText(best_cells), best_mode
            end
        end
        if leap and fr ~= nil then
            radius, half, offset, probed, inner = fr, fh, fo, 1, fi
        elseif leap then
            half = m.hits >= MIN_HITS_FOR_FAN and m.angle + FAN_MARGIN or 180
            if half >= CIRCLE_FROM then
                half = 180
            end
        elseif travel >= MIN_TRAVEL and m.hits > 0 then
            -- a charge: width = how far to its sides hits land, radius = how far in front
            width = (m.side or 0) + REACH_MARGIN
            radius = math.max(0, m.front or m.ahead or 0) + REACH_MARGIN
            probed = fr ~= nil and 1 or 0
        elseif m.hits >= MIN_HITS_FOR_FAN then
            if (m.side or 99) <= LINE_SIDE and (m.ahead or 0) >= LINE_AHEAD then
                width = (m.side or 0) + REACH_MARGIN
                radius = (m.ahead or 0) + REACH_MARGIN
            elseif fr ~= nil then
                -- measured with probes: hits and misses both
                radius, half, offset, probed, inner = fr, fh, fo, 1, fi
            elseif (m.off_target or 0) >= 2 then
                -- (a fan from hits alone only when it hit more than what it was after: an
                -- attack on its target always lands in front - it turned to face it)
                half = m.angle + FAN_MARGIN
                if half >= CIRCLE_FROM then
                    half = 180
                end
            end
        end
        local frames = {}
        for f in pairs(m.frames) do
            table.insert(frames, f)
        end
        table.sort(frames, function(a, b) return tonumber(a) < tonumber(b) end)
        local next_key = Follows(m.next)
        local split = Follows(m.next_still, 2) .. "/" .. Follows(m.next_turned, 2)
        if split ~= "/" then
            next_key = next_key .. "/" .. split
        end
        -- (thrown at its target: the shape is around where its target is)
        local at = (m.at_n or 0) > 0 and (m.at_ok or 0) * 2 > m.at_n
        table.insert(parts, string.format("%s,%.2f,%d,%s,%.2f,%.2f,%s,%.2f,%d,%d,%d,%.2f,%.2f,%d,%s,%d,%d,%d,%d", anim, radius,
            math.floor(half + .5), table.concat(frames, " "), travel, width, next_key, offset, probed,
            leap and 1 or 0, aim and 1 or 0, m.travel_max or travel, inner or 0, single and 1 or 0,
            grid, chase and 1 or 0, at and 1 or 0, grid_mode, m.shared and 1 or 0))
    end
    -- what it sets off (traps, spikes, lasers), each with the version of what's known of it
    if p.spawns ~= nil then
        local list = {}
        for thing in pairs(p.spawns) do
            table.insert(list, thing .. ":" .. Learn.Version(thing))
        end
        table.sort(list)
        table.insert(parts, "@spawns," .. table.concat(list, " "))
    end
    return table.concat(parts, ";")
end

function Learn.Version(prefab)
    local p = data[prefab]
    return p ~= nil and p.version or 0
end

-- player side: the text back into { [anim] = { radius, half, frames, travel, width, next } },
-- and what it sets off: { [prefab] = version }
function Learn.Decode(text)
    local moves, spawns = {}, {}
    for part in string.gmatch(text or "", "[^;]+") do
        local list = string.match(part, "^@spawns,(.*)$")
        if list ~= nil then
            for thing, version in string.gmatch(list, "([^%s:]+):(%d+)") do
                spawns[thing] = tonumber(version) or 0
            end
        end
        local fields = {}
        for f in string.gmatch(part .. ",", "([^,]*),") do
            table.insert(fields, f)
        end
        local anim, radius, half, frames, travel, width, nxt = fields[1], fields[2], fields[3], fields[4] or "",
            fields[5], fields[6], fields[7] or ""
        if anim ~= nil and anim ~= "" and #fields >= 7 then
            local list = {}
            for f in string.gmatch(frames, "%d+") do
                table.insert(list, tonumber(f))
            end
            table.sort(list)
            -- "all/still/turned", each "anim@percent" or empty
            local function One(text)
                local a, share = string.match(text or "", "^(.-)@(%d+)$")
                if a == nil and text ~= nil and text ~= "" then
                    return text, 1
                end
                if a == nil or a == "" then
                    return nil, 0
                end
                return a, (tonumber(share) or 0) / 100
            end
            local all, still, turned = string.match(nxt, "^([^/]*)/([^/]*)/([^/]*)$")
            all = all or nxt
            local m = { radius = tonumber(radius) or 0, half = tonumber(half) or 180, frames = list,
                travel = tonumber(travel) or 0, width = tonumber(width) or 0 }
            m.offset = tonumber(fields[8]) or 0
            m.probed = fields[9] == "1"
            m.leap = fields[10] == "1"
            m.aim = fields[11] == "1"
            m.travel_max = tonumber(fields[12]) or m.travel
            m.inner = tonumber(fields[13]) or 0
            m.single = fields[14] == "1"
            m.grid = Learn.GridFromText(fields[15])
            m.chase = fields[16] == "1"
            m.at_target = fields[17] == "1"
            m.grid_mode = tonumber(fields[18]) or 0
            m.shared = fields[19] == "1"
            m.next, m.next_share = One(all)
            m.next_still, m.still_share = One(still)
            m.next_turned, m.turned_share = One(turned)
            moves[anim] = m
        end
    end
    return moves, spawns
end
-- server: load what was learned before, and keep it saved. Hits come in through the
-- "attacked" event (see OnAttacked; modmain listens for it on everything that fights - an
-- event, so it works whatever other mods do to Combat:GetAttacked).
function Learn.Start()
    if Learn.started then
        return
    end
    Learn.started = true
    Load()
    if TheWorld ~= nil then
        TheWorld:DoPeriodicTask(SAVE_EVERY, Save)
    end
end

function Learn.OnAttacked(victim, event)
    local attacker = event ~= nil and event.attacker or nil
    if attacker ~= nil then
        local ok, err = pcall(Learn.Hit, attacker, victim)
        if not ok then
            print("[true_range] learning a hit failed: " .. tostring(err))
        end
    end
end
-- (for tests)
Learn._data = function() return data end

return Learn
