-- Server side: measuring a boss's attack with stand-ins that aren't there ("probes").
-- An area attack asks the game what's around (TheSim:FindEntities), keeps what its own code
-- says it hits (by angle, by distance - whatever it is), and attacks those. While a boss's
-- move is still being learned, its answer gets probes added - points scattered over the
-- area it asked about. Its code picks them like anything else; when it attacks one, that is
-- noted and nothing more happens (no damage, no events, nothing in the world). Which points
-- were hit and which weren't is the attack's real shape, its code a black box.
-- A few rounds per move, then it stops for good. If its code trips over a probe (asks it for
-- something it doesn't have), that one attack is lost, the move is never probed again, and
-- the error goes no further.
-- (its log lines only with the mod's debugging on - TR_DEBUG, modmain: debug.txt in the mod's folder)
local print = function(...) if rawget(_G, "TR_DEBUG") then _G.print(...) end end

local Probe = {}

-- what a thing a boss set off does, learned under this name (true_range/learn)
Probe.HAZARD = "@hazard"

local Learn -- (true_range/learn, set by Install)

local PER_QUERY = 64     -- probes per question asked (the first few)...
local PER_QUERY_LATER = 24 -- ...and after those (attacks made of many small hits: ice spikes)
local FIRST_QUERIES = 3
local MAX_QUERIES = 40   -- questions with probes per move
-- bigger questions aren't an attack's (an attack asks about a few units round where it hits;
-- a wider one is looking for something - who to aim the next spikes at - and a probe found
-- there would change what the boss does)
local MAX_RADIUS = 10
local AT_TARGET = 3      -- a question this close to its target...
local AWAY = 3           -- ...and this far from itself: about its target's surroundings
local MIN_RADIUS = .5

-- a question about these is an attack looking for targets...
local TARGETISH = {
    _combat = true, _health = true, character = true, player = true, monster = true, animal = true,
    smallcreature = true, largecreature = true, creature = true, hostile = true, shadowminion = true,
    epic = true, prey = true, insect = true, bird = true, pig = true, merm = true, companion = true,
}
-- ...and about these, it isn't
local NOT_TARGETS = {
    _inventoryitem = true, structure = true, wall = true, tree = true, boulder = true, plant = true,
    CHOP_workable = true, MINE_workable = true, HAMMER_workable = true, DIG_workable = true,
    pickable = true, FX = true, fire = true, smolder = true, _workable = true, NET_workable = true,
    blocker = true, CLASSIFIED = true, flower = true, heavy = true,
}

local function List(tags)
    return type(tags) == "table" and tags or {}
end

local function Targetish(must, oneof)
    -- (what it must have rules it out; "one of" may also list things it smashes on the way -
    -- trees, rocks - as long as creatures are among them)
    for _, t in ipairs(List(must)) do
        if NOT_TARGETS[t] then
            return false
        end
    end
    if #List(must) == 0 and #List(oneof) == 0 then
        return true
    end
    for _, t in ipairs(List(must)) do
        if TARGETISH[t] then
            return true
        end
    end
    for _, t in ipairs(List(oneof)) do
        if TARGETISH[t] then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- a probe: what attack code usually asks of something it found, answered like a plain
-- creature standing there; anything else it doesn't have (nil), like a real one

local probe_id = 0
local NOOP = function() end
local FALSE = function() return false end

-- an engine part (AnimState, Physics...) that takes any call and does nothing
local STUB = setmetatable({}, { __index = function() return NOOP end })

local METHODS = {}
METHODS.__index = METHODS

function METHODS:IsValid() return true end
function METHODS:IsInLimbo() return false end
function METHODS:IsAsleep() return false end
function METHODS:HasTag(t) return self._tags[t] == true end
local function AnyIn(self, ...)
    local first = ...
    local list = type(first) == "table" and first or { ... }
    for _, t in ipairs(list) do
        if self._tags[t] then
            return true
        end
    end
    return false
end
local function AllIn(self, ...)
    local first = ...
    local list = type(first) == "table" and first or { ... }
    for _, t in ipairs(list) do
        if not self._tags[t] then
            return false
        end
    end
    return true
end
METHODS.HasAnyTag = AnyIn
METHODS.HasOneOfTags = AnyIn
METHODS.HasAllTags = AllIn
function METHODS:GetPosition() return Vector3(self._x, 0, self._z) end
function METHODS:GetPhysicsRadius() return 0 end
function METHODS:GetDistanceSqToPoint(x, y, z)
    if type(x) == "table" then
        x, z = x.x, x.z
    end
    local dx, dz = self._x - x, self._z - z
    return dx * dx + dz * dz
end
function METHODS:GetDistanceSqToInst(other)
    local x, _, z = other.Transform:GetWorldPosition()
    return self:GetDistanceSqToPoint(x, 0, z)
end
function METHODS:IsNear(other, dist)
    return self:GetDistanceSqToInst(other) < dist * dist
end
METHODS.PushEvent = NOOP
METHODS.PushEventImmediate = NOOP
METHODS.ListenForEvent = NOOP
METHODS.RemoveEventCallback = NOOP
METHODS.GetCurrentPlatform = NOOP
METHODS.IsOnOcean = FALSE
function METHODS:GetDisplayName() return "probe" end

local function Hit(probe)
    probe._hit = true
end

local function NewProbe(x, z, tags)
    probe_id = probe_id + 1
    local p = setmetatable({
        _x = x, _z = z, _tags = tags, _hit = false,
        is_true_range_probe = true,
        GUID = -probe_id,
        prefab = "true_range_probe",
    }, METHODS)
    p.Transform = {
        GetWorldPosition = function() return p._x, 0, p._z end,
        GetRotation = function() return 0 end,
        SetPosition = NOOP,
    }
    p.entity = {
        IsValid = function() return true end,
        IsVisible = function() return true end,
        IsAwake = function() return true end,
        GetParent = NOOP,
    }
    local combat = {
        inst = p, defaultdamage = 0,
        CanBeAttacked = function() return true end,
        GetAttacked = function() Hit(p) return true end,
        ShouldRecoil = function() return false, nil end,
        GetTarget = NOOP,
        HasTarget = FALSE,
        IsAlly = FALSE,
        CanBeAlly = FALSE,
        SuggestTarget = NOOP,
        SetTarget = NOOP,
        ShareTarget = NOOP,
    }
    local health = {
        inst = p, currenthealth = 100, maxhealth = 100, invincible = false,
        IsDead = FALSE,
        IsInvincible = FALSE,
        IsHurt = FALSE,
        GetPercent = function() return 1 end,
        DoDelta = function(_, amount) if (amount or 0) < 0 then Hit(p) end end,
    }
    p.components = { combat = combat, health = health }
    -- (what effects reach for on whatever got hit - making it glow, a sound, a push: takes
    -- anything, does nothing)
    p.AnimState, p.SoundEmitter, p.Physics, p.Light = STUB, STUB, STUB, STUB
    p.replica = {
        combat = { inst = p, CanBeAttacked = function() return true end, GetTarget = NOOP, IsAlly = FALSE, CanBeAlly = FALSE },
        health = { inst = p, IsDead = FALSE, GetPercent = function() return 1 end, IsHurt = FALSE },
    }
    return p
end

-- the tags a probe has for one question: whatever it must have, the first of the "one of"
-- (a creature's if there is one), and never one it can't
local function TagsFor(must, cant, oneof)
    local tags = { _combat = true, _health = true }
    for _, t in ipairs(List(must)) do
        tags[t] = true
    end
    local pick = nil
    for _, t in ipairs(List(oneof)) do
        if TARGETISH[t] then
            pick = t
            break
        end
    end
    pick = pick or List(oneof)[1]
    if pick ~= nil then
        tags[pick] = true
    end
    for _, t in ipairs(List(cant)) do
        tags[t] = nil
    end
    return tags
end

--------------------------------------------------------------------------------
-- rounds: one per state a boss enters with a move still being learned

local running = nil                                    -- the boss whose stategraph code runs now
local acting = nil                                     -- something a boss set off, acting now

-- whose doing is happening now (nil: not known)
function Probe.Actor()
    return running or acting
end
local sessions = setmetatable({}, { __mode = "k" })    -- boss -> this state's probing

local function Session(inst)
    local s = sessions[inst]
    if s == nil or s.n ~= inst._true_range_state_n then
        s = { n = inst._true_range_state_n, key = inst._true_range_probe_key, queries = {} }
        sessions[inst] = s
    end
    return s
end

local function AnyHit(q)
    for _, p in ipairs(q.probes) do
        if p._hit then
            return true
        end
    end
    return false
end

local function Inject(inst, ents, x, z, r, must, cant, oneof)
    local s = Session(inst)
    if s.key == nil or s.failed or #s.queries >= MAX_QUERIES then
        return
    end
    local ax, _, az = inst.Transform:GetWorldPosition()
    local q = {
        probes = {}, x = ax, z = az, ax = ax, az = az, rot = inst.Transform:GetRotation() * DEGREES,
        t = inst.AnimState ~= nil and inst.AnimState:GetCurrentAnimationTime() or 0,
    }
    -- (asked about around where its target is, away from itself: something thrown at its
    -- target - seen from there instead)
    local combat = inst.components ~= nil and inst.components.combat or nil
    local target = combat ~= nil and combat.target or nil
    if target ~= nil and target.IsValid ~= nil and target:IsValid() and not target.is_true_range_probe then
        local tx, _, tz = target.Transform:GetWorldPosition()
        -- (how far ahead of it its target stands: attacks aimed at it reach as far as it is)
        q.ta = (tx - ax) * math.cos(q.rot) - (tz - az) * math.sin(q.rot)
        if (tx - x) ^ 2 + (tz - z) ^ 2 <= AT_TARGET ^ 2 and (ax - x) ^ 2 + (az - z) ^ 2 > AWAY ^ 2 then
            q.x, q.z, q.at = x, z, true
        end
    end
    local tags = TagsFor(must, cant, oneof)
    for _ = 1, #s.queries < FIRST_QUERIES and PER_QUERY or PER_QUERY_LATER do
        -- (over the circle asked about: half evenly, half thicker towards its middle - what an
        -- attack hits is usually well inside what it asks about)
        local d = r * (math.random() < .5 and math.sqrt(math.random()) or math.random())
        local a = math.random() * 2 * math.pi
        local p = NewProbe(x + d * math.cos(a), z - d * math.sin(a), tags)
        table.insert(q.probes, p)
        table.insert(ents, p)
    end
    table.insert(s.queries, q)
    s.injected = true
end

-- the state is over: what the probes showed goes to Learn
function Probe.Finish(inst)
    local s = sessions[inst]
    sessions[inst] = nil
    if s == nil or s.key == nil or s.failed or #s.queries == 0 or Learn == nil then
        return
    end
    local points, frames, progress = {}, {}, {}
    -- (where the move began: how far it had come when it hit - a leap only hits at its end)
    local mv = inst._true_range_move
    -- (about its target's surroundings, mostly: those only, seen from there)
    local at, around = 0, 0
    for _, q in ipairs(s.queries) do
        if AnyHit(q) then
            around = around + 1
            at = at + (q.at and 1 or 0)
        end
    end
    local at_target = around > 0 and at * 2 > around
    for _, q in ipairs(s.queries) do
        if AnyHit(q) and (q.at == true) == at_target then
            local c, sn = math.cos(q.rot), math.sin(q.rot)
            for _, p in ipairs(q.probes) do
                local dx, dz = p._x - q.x, p._z - q.z
                -- (seen from the boss: how far ahead, how far to its side)
                table.insert(points, { dx * c - dz * sn, dx * sn + dz * c, p._hit, q.ta })
            end
            table.insert(frames, math.floor(q.t / FRAMES + .5))
            if mv ~= nil and mv.key == s.key then
                local r = mv.rot * DEGREES
                table.insert(progress, (q.ax - mv.x) * math.cos(r) - (q.az - mv.z) * math.sin(r))
            end
        end
    end
    if #points > 0 then
        Learn.Probed(inst.prefab, s.key, frames, points, progress, mv ~= nil and mv.key == s.key and mv or nil, at_target)
        if inst._true_range_hazard and inst._true_range_root ~= nil then
            -- (the boss sets these off: players near it look out for them)
            Learn.NoteSpawn(inst._true_range_root.prefab, inst.prefab)
        end
    else
        Learn.ProbeMissed(inst.prefab, s.key)
    end
end

--------------------------------------------------------------------------------
-- the hooks

-- A boss's stategraph code runs (with probing on for its move): note whose it is, and keep
-- an error that a probe caused from going further.
-- runs fn(...) as inst's code; an error that came of probes stops there, any other goes on
local function RunAs(inst, fn, ...)
    running = inst
    local ok, result = pcall(fn, ...)
    running = nil
    -- (something a boss set off - a trap, a spike: each time it acts is a round of its own)
    if inst._true_range_hazard then
        Probe.Finish(inst)
    end
    if ok then
        return result
    end
    local s = sessions[inst]
    if s ~= nil and s.injected and s.key ~= nil then
        s.failed = true
        inst._true_range_probe_key = nil
        if Learn ~= nil then
            Learn.ProbeFailed(inst.prefab, s.key)
        end
        print("[true_range] " .. tostring(inst.prefab) .. " " .. tostring(s.key)
            .. ": its attack code doesn't take probes, not probing it again (" .. tostring(result) .. ")")
        return nil
    end
    error(result, 0)
end

local function Guard(old)
    return function(self, ...)
        local inst = self.inst
        if running ~= nil or inst == nil or inst._true_range_probe_key == nil then
            return old(self, ...)
        end
        return RunAs(inst, old, self, ...)
    end
end

-- Something a boss's move sets off a moment later (ice spikes, one after another): still that
-- move's, if it's still in it then.
local function GuardLater(old)
    return function(self, time, fn, ...)
        if running ~= nil and type(fn) == "function" and type(self) == "table" and self ~= running
            and type(self.prefab) == "string" and self.Transform ~= nil
            -- (not a creature - its next phase, a minion: those have moves of their own)
            and self.sg == nil and not (self.components ~= nil and self.components.health ~= nil) then
            -- Something else's own later doing, set up during a boss's move (or a thing it
            -- spawned): a crystal landing, spikes rising, a laser burning - a hazard of its
            -- own, measured around itself.
            local root = running._true_range_root or running
            self._true_range_root = root
            if not self._true_range_hazard then
                self._true_range_hazard = true
                self._true_range_state_n = 1
                if Learn ~= nil then
                    self._true_range_probe_key = Learn.NeedsProbe(self.prefab, Probe.HAZARD) and Probe.HAZARD or nil
                end
            end
            local thing, inner = self, fn
            fn = function(...)
                if running == nil and thing._true_range_probe_key ~= nil then
                    return RunAs(thing, inner, ...)
                end
                -- (its doing, not the boss's: a hit now isn't the boss's move - Learn.Hit)
                local before = acting
                acting = thing
                local ok, result = pcall(inner, ...)
                acting = before
                if not ok then
                    error(result, 0)
                end
                return result
            end
        elseif running ~= nil and type(fn) == "function" then
            local inst, n, inner = running, running._true_range_state_n, fn
            fn = function(...)
                if running ~= nil or inst._true_range_state_n ~= n or inst._true_range_probe_key == nil then
                    return inner(...)
                end
                return RunAs(inst, inner, ...)
            end
        end
        return old(self, time, fn, ...)
    end
end

-- Combat on everything (server): an attack on a probe only notes whether it would land
-- (Combat's own hit check, as DoAttack does it); a probe never becomes anyone's target.
function Probe.WrapCombat(combat)
    local DoAttack, SetTarget, SuggestTarget = combat.DoAttack, combat.SetTarget, combat.SuggestTarget
    combat.DoAttack = function(self, targ, weapon, projectile, stimuli, instancemult, instrangeoverride, instpos, ...)
        if type(targ) == "table" and targ.is_true_range_probe then
            pcall(function()
                if instrangeoverride then
                    self.temprange = instrangeoverride
                end
                if instpos then
                    self.temppos = instpos
                end
                if self:CanHitTarget(targ, weapon or self:GetWeapon()) and not self.AOEarc then
                    Hit(targ)
                end
            end)
            self.temprange, self.temppos = nil, nil
            return
        end
        return DoAttack(self, targ, weapon, projectile, stimuli, instancemult, instrangeoverride, instpos, ...)
    end
    combat.SetTarget = function(self, target, ...)
        if type(target) == "table" and target.is_true_range_probe then
            return
        end
        return SetTarget(self, target, ...)
    end
    combat.SuggestTarget = function(self, target, ...)
        if type(target) == "table" and target.is_true_range_probe then
            return false
        end
        return SuggestTarget(self, target, ...)
    end
end

function Probe.Install(learn)
    if Probe.installed then
        return
    end
    Probe.installed = true
    Learn = learn
    local mt = getmetatable(TheSim)
    local sim = mt ~= nil and mt.__index or nil
    if type(sim) ~= "table" or sim.FindEntities == nil then
        print("[true_range] can't probe: TheSim:FindEntities not found")
        return
    end
    local FindEntities = sim.FindEntities
    sim.FindEntities = function(self, x, y, z, r, must, cant, oneof, ...)
        local ents = FindEntities(self, x, y, z, r, must, cant, oneof, ...)
        if running ~= nil and running._true_range_probe_key ~= nil and type(ents) == "table"
            and type(r) == "number" and r >= MIN_RADIUS and r <= MAX_RADIUS and Targetish(must, oneof) then
            Inject(running, ents, x, z, r, must, cant, oneof)
        end
        return ents
    end
    StateGraphInstance.UpdateState = Guard(StateGraphInstance.UpdateState)
    StateGraphInstance.HandleEvents = Guard(StateGraphInstance.HandleEvents)
    if EntityScript ~= nil and EntityScript.DoTaskInTime ~= nil then
        EntityScript.DoTaskInTime = GuardLater(EntityScript.DoTaskInTime)
    end
    if EntityScript ~= nil and EntityScript.DoPeriodicTask ~= nil then
        EntityScript.DoPeriodicTask = GuardLater(EntityScript.DoPeriodicTask)
    end
end

-- (for tests)
Probe._running = function() return running end

return Probe
