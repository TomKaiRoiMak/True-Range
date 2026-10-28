-- luajit trace_moves.lua <game scripts> <prefab:state> [prefab:state ...]
-- What each blow of a move depends on - REDESIGN.md part [2].
-- The move is run once as the game would (tools/sim_moves.lua, as a library), and every time the
-- game's code reads where its target is (its position, distance, angle to it; facing it) the frame
-- and whose code it was are noted. Then it is run again and again with the target jumping aside at
-- one frame after another: a blow that lands elsewhere when the target jumps at frame f, and not
-- when it jumps later, depends on where the target was up to frame f - its last read. The two must
-- agree. Each group of blows (by the boss itself, or by a thing it set off - by kind) is reported:
-- when it struck, what it read of the target and when, and the last frame that mattered.
local HERE = (arg[0]:match("^(.*)[/\\]") or ".")
local SCRIPTS = arg[1]
local wanted = {}
for i = 2, #arg do wanted[#wanted + 1] = arg[i] end
local real_print = print

-- the world, as a library: nothing generated, only Run handed over
sim_lib_mode = true
arg = { [0] = HERE .. "/sim_moves.lua", "unused_out.lua", SCRIPTS, "-noauto" }
local Lib = dofile(HERE .. "/sim_moves.lua")
print = real_print

-- every read of the target by the game's code: { frame, by, how }
local reads = nil
local function Note(how)
    if reads == nil then return end
    local by = Lib.Acting()
    local who = (by == nil or by == Lib.Boss()) and "boss" or tostring(rawget(by, "prefab") or by.prefab)
    local f = Lib.Frame()
    local last = reads[#reads]
    if last ~= nil and last.frame == f and last.by == who and last.how == how then return end
    reads[#reads + 1] = { frame = f, by = who, how = how }
end
local player_now = nil
sim_hooks = {
    player = function(p)
        player_now = p
        local gwp = p.Transform.GetWorldPosition
        p.Transform.GetWorldPosition = function(...) Note("position") return gwp(...) end
        rawset(p, "GetPosition", function(self) Note("position") return Lib.Entity.GetPosition(self) end)
    end,
}
-- (things asked about it from the other side: the distance to it, the angle to it, turning to face it)
for _, name in ipairs({ "GetDistanceSqToInst", "IsNear", "FacePoint", "ForceFacePoint", "GetAngleToPoint",
    "GetDistanceSqToPoint" }) do
    local fn = Lib.Entity[name]
    if fn ~= nil then
        Lib.Entity[name] = function(self, a, ...)
            if player_now ~= nil and (self == player_now or a == player_now) then Note(name) end
            return fn(self, a, ...)
        end
    end
end

-- one run: { groups = { name -> { first, last, cells = { "x,z" -> true } } }, reads, res (Run's) }
local function RunOnce(def, sg, spec, dist, teleport, seed)
    local statename = type(spec) == "table" and spec.name or spec
    spec_data = type(spec) == "table" and spec.data or nil
    spec_behind = type(spec) == "table" and spec.behind or nil
    spec_targets = type(spec) == "table" and spec.targets or nil
    spec_allhits = type(spec) == "table" and spec.all_hits or nil
    spec_setup = type(spec) == "table" and spec.setup or nil
    spec_fields = type(spec) == "table" and spec.fields or nil
    spec_lucky = type(spec) == "table" and spec.lucky or nil
    -- (going on into another of its moves' first animation: stops there, as the offline runs do -
    -- that one is drawn as itself: trace_stop_at, set by tools/build_tables.lua)
    stop_at_anims = rawget(_G, "trace_stop_at")
    sim_went_into = nil
    reads = {}
    local ok, res = pcall(Lib.Run, def, sg, statename, dist, seed or 1, teleport, type(spec) == "table" and spec.mem or nil)
    local got = reads
    reads = nil
    if not ok then return nil, tostring(res) end
    local groups = {}
    for d, h in pairs(res.all_hits or {}) do
        local dummy = rawget(d, "dummy") or d
        if dummy ~= player_now then
            local by = h.by
            local who = (by == nil or rawget(by, "is_sim_boss")) and "boss" or tostring(rawget(by, "prefab") or by.prefab)
            local g = groups[who]
            if g == nil then g = { first = h.frame, last = h.frame, cells = {}, n = 0 } groups[who] = g end
            -- (a thing set off: the frame it was made)
            local born = by ~= nil and rawget(by, "born") or nil
            if born ~= nil then g.born = math.min(g.born or born, born) end
            g.first, g.last = math.min(g.first, h.frame), math.max(g.last, h.frame)
            local k = string.format("%.2f,%.2f", dummy.x, dummy.z)
            if not g.cells[k] then g.cells[k] = h.frame g.n = g.n + 1 end
            -- (and the last time it was struck there: struck again - the second claw of two)
            g.again = g.again or {}
            local lf = type(h.last) == "table" and h.last[1] or h.frame
            g.again[k] = math.max(g.again[k] or lf, lf)
        end
    end
    -- (a blow on its target only - none of the dummies round it struck: round where the boss was
    -- then, as far as it reaches, as the offline data has it - tools/sim_moves.lua target_hits)
    for _, th in ipairs(res.target_hits or {}) do
        local g = groups.boss
        if g == nil then g = { first = th.frame, last = th.frame, cells = {}, n = 0 } groups.boss = g end
        g.first, g.last = math.min(g.first, th.frame), math.max(g.last, th.frame)
        local r = th.range + .5 + Lib.PAD
        for gx = th.x - r, th.x + r, Lib.STEP do
            for gz = th.z - r, th.z + r, Lib.STEP do
                local kx = math.floor(gx / Lib.STEP + .5) * Lib.STEP
                local kz = math.floor(gz / Lib.STEP + .5) * Lib.STEP
                if (kx - th.x) ^ 2 + (kz - th.z) ^ 2 <= r * r then
                    local k = string.format("%.2f,%.2f", kx, kz)
                    if not g.cells[k] then g.cells[k] = th.frame g.n = g.n + 1 end
                    g.again = g.again or {}
                    g.again[k] = math.max(g.again[k] or th.frame, th.frame)
                end
            end
        end
    end
    return { groups = groups, reads = got, res = res, went_into = rawget(_G, "sim_went_into") }
end

local function Same(a, b)
    if a == nil or b == nil then return a == b end
    if a.n ~= b.n then return false end
    for k in pairs(a.cells) do if b.cells[k] == nil then return false end end
    return true
end

-- a boss's def, its stategraph and the spec of one of its moves ("prefab", "state")
local function Find(prefab, state)
    for _, d in ipairs(Lib.BOSSES) do
        if d.prefab == prefab then
            for _, s in ipairs(d.states) do
                if (type(s) == "table" and s.name or s) == state then
                    return d, assert(loadfile(SCRIPTS .. "/stategraphs/" .. d.sg .. ".lua"))(), s
                end
            end
        end
    end
end

-- each group's deciding frame: the last frame the target's place changes where it strikes -
-- jumps every 2 frames, then the one between (a read at f is seen by a jump at f or before).
-- And each blow's own (by the frame it strikes, base run): a move of several blows, each set by
-- where its target was at its own moment - Klaus' chomp lands where it aimed at frame 26, its
-- quick swipe after goes for you as you are at 49.
-- (strikes this many frames apart at most: one blow)
local BLOW = 3
-- (the target jumps this far aside - to +z; a blow counts as moved with it when its middle went
-- over TOWARD that way)
local JUMP_ASIDE, TOWARD = tonumber(os.getenv("JUMP_ASIDE") or "") or 6, .25
local function Deciding(def, sg, spec, dist)
    local base = RunOnce(def, sg, spec, dist, nil)
    if base == nil then return nil end
    local last_f = 0
    local base_frames = {}
    for _, g in pairs(base.groups) do
        last_f = math.max(last_f, g.last)
        for _, fr in pairs(g.cells) do base_frames[fr] = true end
    end
    local function Nearest(fr)
        local best = nil
        for b in pairs(base_frames) do if best == nil or math.abs(b - fr) < math.abs(best - fr) then best = b end end
        return best
    end
    -- (and half as far: one that turns to its target only within 45 degrees - the Vault Guard's
    -- leap at frame 30 - let a target jumped 45 off go, and was taken as aimed at frame 0)
    local function ChangedBy(f, aside)
        local r = RunOnce(def, sg, spec, dist, { frame = f, x = dist, z = aside })
        local out, frames = {}, {}
        -- (struck nowhere now - its target gone out of its reach, a miss: not struck elsewhere -
        -- where it strikes didn't go with it (Klaus' chomp: where it lands is set at frame 26, the
        -- bite at 35 only misses you once you're off)
        for who, g in pairs(base.groups) do
            local rg = r ~= nil and r.groups[who] or nil
            if r == nil then
                out[who] = true
                for _, fr in pairs(g.cells) do frames[fr] = true end
            elseif rg ~= nil and rg.n > 0 then
                -- (blow by blow - each the cells struck within BLOW frames of it: one gone
                -- altogether is a miss, not struck elsewhere; one struck where it wasn't, or one
                -- new, is)
                local function ByFrame(cells)
                    local by = {}
                    for k, fr in pairs(cells) do by[fr] = by[fr] or {} by[fr][k] = true end
                    return by
                end
                local bb, rb = ByFrame(g.cells), ByFrame(rg.cells)
                local function Near(by, fr)
                    local set, any = {}, false
                    for f2, s in pairs(by) do
                        if math.abs(f2 - fr) <= BLOW then for k in pairs(s) do set[k] = true any = true end end
                    end
                    return any and set or nil
                end
                local ch = false
                for fr in pairs(bb) do
                    local mine, theirs = Near(bb, fr), Near(rb, fr)
                    if theirs ~= nil then
                        -- (moved with it: its middle gone over TOWARD the way its target jumped - not a
                        -- body in its way gone, a leap landing a little further on; a beam sliding
                        -- after it only so fast, all the same)
                        local function Mid(set)
                            local n, z = 0, 0
                            for k in pairs(set) do n = n + 1 z = z + tonumber(k:match(",(.+)$")) end
                            return n > 0 and z / n or 0
                        end
                        if Mid(theirs) - Mid(mine) > TOWARD then frames[fr] = true ch = true end
                    end
                end
                for fr in pairs(rb) do
                    -- (a blow where there was none: the group's, not pinned on another blow)
                    if Near(bb, fr) == nil then ch = true end
                end
                out[who] = ch
            end
        end
        return out, frames
    end
    local function Changed(f)
        local out, frames = ChangedBy(f, JUMP_ASIDE)
        if os.getenv("JUMP_ONE") == nil then
            local o2, f2 = ChangedBy(f, JUMP_ASIDE / 2)
            for who, ch in pairs(o2) do out[who] = out[who] or ch end
            for fr in pairs(f2) do frames[fr] = true end
        end
        return out, frames
    end
    local decide, step = {}, {}
    for f = 0, last_f, 2 do
        local out, frames = Changed(f)
        for who, ch in pairs(out) do if ch then decide[who] = f end end
        for fr in pairs(frames) do step[fr] = f end
    end
    local tried = {}
    for who, f in pairs(decide) do
        if tried[f] == nil then tried[f] = { Changed(f + 1) } end
        if tried[f][1][who] then decide[who] = f + 1 end
    end
    for fr, f in pairs(step) do
        if tried[f] == nil then tried[f] = { Changed(f + 1) } end
        if tried[f][2][fr] then step[fr] = f + 1 end
    end
    return decide, base, step
end
-- as a library (tools/build_tables.lua): these, and nothing run here
if rawget(_G, "trace_lib_mode") == true then
    return { Lib = Lib, RunOnce = RunOnce, Same = Same, Find = Find, Deciding = Deciding }
end

for _, w in ipairs(wanted) do
    local prefab, state = w:match("^([^:]+):(.+)$")
    local def, spec = nil, nil
    for _, d in ipairs(Lib.BOSSES) do
        if d.prefab == prefab then
            def = d
            for _, s in ipairs(d.states) do
                if (type(s) == "table" and s.name or s) == state then spec = s break end
            end
        end
    end
    if def == nil or spec == nil then
        real_print(string.format("== %s: not among the bosses run offline", w))
    else
        local sg = assert(loadfile(SCRIPTS .. "/stategraphs/" .. def.sg .. ".lua"))()
        local DIST = 6
        local base, err = RunOnce(def, sg, spec, DIST, nil)
        real_print(string.format("== %s %s (target %d ahead)", prefab, state, DIST))
        if base == nil then
            real_print("   could not run: " .. err)
        else
            -- (what its code read of the target, frame by frame - runs of frames joined)
            local by_who = {}
            for _, r in ipairs(base.reads) do
                local key = r.by .. " " .. r.how
                local l = by_who[key]
                if l == nil then l = {} by_who[key] = l end
                l[#l + 1] = r.frame
            end
            real_print("   reads of the target:")
            local keys = {}
            for k in pairs(by_who) do keys[#keys + 1] = k end
            table.sort(keys)
            for _, k in ipairs(keys) do
                local l, parts, s0, prev = by_who[k], {}, nil, nil
                for _, f in ipairs(l) do
                    if s0 == nil then s0, prev = f, f
                    elseif f <= prev + 1 then prev = f
                    else parts[#parts + 1] = s0 == prev and tostring(s0) or (s0 .. "-" .. prev) s0, prev = f, f end
                end
                if s0 ~= nil then parts[#parts + 1] = s0 == prev and tostring(s0) or (s0 .. "-" .. prev) end
                real_print(string.format("     %-40s frames %s", k, table.concat(parts, ", ")))
            end
            -- (and checked: the target jumping 3 aside at frame f - which groups change)
            local last_f = 0
            for _, g in pairs(base.groups) do last_f = math.max(last_f, g.last) end
            local changed_at = {}
            for f = 0, last_f, 2 do
                local tp = { frame = f, x = DIST, z = 3 }
                local r = RunOnce(def, sg, spec, DIST, tp)
                if r ~= nil then
                    for who, g in pairs(base.groups) do
                        if not Same(g, r.groups[who]) then changed_at[who] = f end
                    end
                end
            end
            real_print("   blows, and the last frame the target's place mattered (it jumping aside then, they land elsewhere):")
            for who, g in pairs(base.groups) do
                real_print(string.format("     %-30s %4d cells, struck frames %d-%d, target mattered up to frame %s",
                    who, g.n, g.first, g.last, changed_at[who] ~= nil and tostring(changed_at[who]) or "never"))
            end
        end
    end
end
