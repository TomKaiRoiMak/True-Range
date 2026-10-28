-- luajit build_tables.lua <game scripts> <out dir> [-list] [-one=prefab#i] [-pic] [-budget=s]
--     [-client=<file>] [prefab:state ...]
-- REDESIGN.md part [3]: for each move, where it strikes with its target at each place round the
-- boss - the target there all along, at an angle from the way the boss faces as the move begins
-- (all the way round), at each distance - every blow its code makes, as the game's own code runs.
-- Each place's cells kept as the offline data's maps are (steps by frame), seen from the boss as
-- the move begins. With it, the frame after which the target's place no longer matters (each
-- group of blows: tools/trace_moves.lua), and whether one place gives the same each run (not:
-- random - the cells of all runs kept, as where it may strike).
--   -list: every move run offline, one a line ("prefab#i state") - tools/build_all_tables.ps1 runs
--     each with -one, several at once
--   -one=prefab#i: that one (the i-th of its moves); prefab:state - by its state's name
--   -part=K/N: only the K-th of every N angles (raw, <prefab>#<i>.pK.lua); -part=decide: only its
--     deciding frame (.pd.lua); -merge=N: the N parts and that, as one move's file - several
--     processes on one move at once (tools/build_all_tables.ps1)
--   -follow: for a move built, how far it goes with its target late on (Follow), as
--     <prefab>#<i>.follow.lua - put in the mod's file with it
--   -budget: seconds one process may take (a run timed): over, not built
--   -client: every move built (<out dir>/index.lua: its files) as one file the mod reads
--     (true_range/moves_table), less those in <out dir>/drop.lua (the replays found worse)
-- Written: <out dir>/<prefab>#<i>.lua (-pic: a picture of a few places, .ppm).
-- Frames, as the mod's offline data has them: from when the move's first animation begins.
local HERE = (arg[0]:match("^(.*)[/\\]") or ".")
local SCRIPTS, OUTDIR = arg[1], arg[2]
local wanted = {}
local CLIENT, LIST, PIC, BUDGET = nil, false, false, 240
local PART, PARTS, MERGE, FOLLOW = nil, nil, nil, false
for i = 3, #arg do
    local a = arg[i]
    if a:match("^%-client=") then CLIENT = a:match("^%-client=(.+)$")
    elseif a == "-list" then LIST = true
    elseif a == "-pic" then PIC = true
    elseif a:match("^%-budget=") then BUDGET = tonumber(a:match("=(.+)$"))
    elseif a:match("^%-one=") then wanted[#wanted + 1] = a:match("=(.+)$")
    elseif a == "-part=decide" then PART = "decide"
    elseif a:match("^%-part=%d+/%d+$") then PART, PARTS = tonumber(a:match("=(%d+)/")), tonumber(a:match("/(%d+)$"))
    elseif a:match("^%-merge=%d+$") then MERGE = tonumber(a:match("=(%d+)$"))
    elseif a == "-wide" then
        -- (one thrown far - the Scrappy Werepig's junk, 28 off: the map the runs keep wider, places
        -- 26 off to its side run too, not only 15)
        sim_ahead, sim_side = { -32, 40 }, 32
    elseif a == "-follow" then
        FOLLOW = true
        -- (places far off to its side too - the map the runs keep wider: tools/sim_moves.lua)
        sim_ahead, sim_side = { -32, 40 }, 32
    else wanted[#wanted + 1] = a end
end
local real_print = print

trace_lib_mode = true
local saved = arg
arg = { [0] = HERE .. "/trace_moves.lua", SCRIPTS }
local T = dofile(HERE .. "/trace_moves.lua")
arg = saved
print = real_print
local Lib = T.Lib

local function StateName(s) return type(s) == "table" and s.name or s end

if LIST then
    for _, d in ipairs(Lib.BOSSES) do
        for i, s in ipairs(d.states) do real_print(string.format("%s#%d %s", d.prefab, i, StateName(s))) end
    end
    return
end

-- (all the way round: the game's code needn't treat either side alike)
local ANGLES, ANGLES_FEW = {}, {}
for a = -165, 180, 15 do ANGLES[#ANGLES + 1] = a end
for a = -150, 180, 30 do ANGLES_FEW[#ANGLES_FEW + 1] = a end
-- (out as far as one may be after you: the War Machine's beam, cast at you 34 away, never gets
-- there - what's further than run isn't known)
local DISTS, DISTS_FEW = {}, {}
-- (and nearer than that: a plant's bite reaches no further than 1)
for _, d in ipairs({ .5, 1, 1.5 }) do DISTS[#DISTS + 1] = d end
for d = 2, 40, 2 do DISTS[#DISTS + 1] = d end
for d = 2, 38, 4 do DISTS_FEW[#DISTS_FEW + 1] = d end
-- (one not the same twice over: run as many times as the old rings do theirs (sim_moves'
-- RUNS_RANDOM) and all of them kept - junk thrown, spikes: where any run struck, it may)
local SEEDS = 16
-- (a place whose blows would go off the map the runs keep - from AHEAD[1] to AHEAD[2] ahead,
-- SIDE aside: not run; not known - not "nothing struck")
local M = 5

local function Now() return os.clock() end

-- a move: its def, stategraph, spec, index among its boss's
local function Which(w)
    local prefab, i = w:match("^([^#]+)#(%d+)$")
    if prefab ~= nil then
        for _, d in ipairs(Lib.BOSSES) do
            if d.prefab == prefab and d.states[tonumber(i)] ~= nil then
                local sg = assert(loadfile(SCRIPTS .. "/stategraphs/" .. d.sg .. ".lua"))()
                return d, sg, d.states[tonumber(i)], tonumber(i)
            end
        end
        return nil
    end
    local p, state = w:match("^([^:]+):(.+)$")
    for _, d in ipairs(Lib.BOSSES) do
        if d.prefab == p then
            for k, s in ipairs(d.states) do
                if StateName(s) == state then
                    return d, assert(loadfile(SCRIPTS .. "/stategraphs/" .. d.sg .. ".lua"))(), s, k
                end
            end
        end
    end
end

-- (struck again this many frames after the first, at least: a strike of its own - not one blow
-- going on a frame or two)
local AGAIN_APART = 4
-- (finer places: between two whose middles are over REFINE_APART apart; kept if over REFINE_OFF off
-- half way between them; REFINE_DEPTH halvings at most, REFINE_RUNS places a move at most)
local REFINE_APART, REFINE_OFF, REFINE_DEPTH, REFINE_RUNS = 1, .5, 2, 400
refined = 0
-- a row's steps: its first strikes, and those again later - each part by when (Lib.Steps), in order
-- (and how far its cells were moved back to be kept - sx ahead, sz aside: run on a wider map (-wide),
-- further off than the files keep (Lib.PACK_AHEAD, PACK_SIDE) - junk 26 off to the side; the mod
-- draws them on by as much)
local function StepsOf(e)
    local lo_x, hi_x, lo_z, hi_z = nil, nil, nil, nil
    for _, set in ipairs({ e.cells, e.again or {} }) do
        for key in pairs(set) do
            local gx, gz = Lib.KeyXZ(key)
            lo_x, hi_x = math.min(lo_x or gx, gx), math.max(hi_x or gx, gx)
            lo_z, hi_z = math.min(lo_z or gz, gz), math.max(hi_z or gz, gz)
        end
    end
    local S = Lib.STEP
    local wx0, wx1 = math.ceil(Lib.PACK_AHEAD[1] / S), math.floor(Lib.PACK_AHEAD[2] / S)
    local wz0, wz1 = math.ceil(-Lib.PACK_SIDE / S), math.floor(Lib.PACK_SIDE / S)
    local mx, mz = 0, 0
    if lo_x ~= nil and (lo_x < wx0 or hi_x > wx1) then mx = math.floor((lo_x + hi_x) / 2 - (wx0 + wx1) / 2 + .5) end
    if lo_z ~= nil and (lo_z < wz0 or hi_z > wz1) then mz = math.floor((lo_z + hi_z) / 2 - (wz0 + wz1) / 2 + .5) end
    local function Moved(set)
        if mx == 0 and mz == 0 then return set end
        local out = {}
        for key, v in pairs(set) do
            local gx, gz = Lib.KeyXZ(key)
            out[Lib.Key((gx - mx) * S, (gz - mz) * S)] = v
        end
        return out
    end
    local list = assert(loadstring("return " .. Lib.Steps(Moved(e.cells))))()
    if next(e.again or {}) ~= nil then
        for _, s in ipairs(assert(loadstring("return " .. Lib.Steps(Moved(e.again))))()) do list[#list + 1] = s end
        table.sort(list, function(p, q) return p.at < q.at end)
    end
    local out = {}
    for _, s in ipairs(list) do out[#out + 1] = string.format("{ at = %d, cells = %q }", s.at, s.cells) end
    return "{ " .. table.concat(out, ", ") .. " }", mx * S, mz * S
end

-- a move's branches (see the decide part): "nil", or "{ { at = frame, zones = { [state] = cells } }, ... }"
-- - each frame its code reads where its target is after it has begun striking, where four places
-- round it (ahead, behind, either side) don't all go on the same way: there, a place every
-- BRANCH_STEP (a cell) within BRANCH_R of it
local BRANCH_R, BRANCH_STEP, BRANCH_MAX = 10, .25, 3
function Branches(def, sg, spec, k0)
    local base = T.RunOnce(def, sg, spec, 3, nil, 1)
    if base == nil then return "nil" end
    -- (after its first blow: what it reads then decides what comes next, not where this one goes -
    -- read with you still in front of it, and with you gone behind it: each way it may check)
    local first = nil
    for _, g in pairs(base.groups) do first = math.min(first or g.first, g.first) end
    if first == nil then return "nil" end
    -- (frames: each with the run it was read in, and how its target was moved before then)
    local frames, seen = {}, {}
    local function Note(run, before)
        for _, r in ipairs(run ~= nil and run.reads or {}) do
            if r.by == "boss" and not seen[r.frame] and r.frame > first then
                seen[r.frame] = true
                frames[#frames + 1] = { r.frame, run, before }
            end
        end
    end
    Note(base, nil)
    local p0 = base.res.pose_at[first]
    if p0 ~= nil then
        local c0, s0 = math.cos((p0.rot or 0) * math.pi / 180), math.sin((p0.rot or 0) * math.pi / 180)
        local before = { first + 1, p0.x - 3 * c0, p0.z + 3 * s0 }
        Note(T.RunOnce(def, sg, spec, 3, { frame = first + 1, x = before[2], z = before[3] }, 1), before)
    end
    table.sort(frames, function(p, q) return p[1] < q[1] end)
    local out = {}
    for _, fr in ipairs(frames) do
        if #out >= BRANCH_MAX then break end
        local at, run, before = fr[1] - 1, fr[2], fr[3]
        local p = run.res.pose_at[at]
        if p ~= nil then
            local c, s = math.cos((p.rot or 0) * math.pi / 180), math.sin((p.rot or 0) * math.pi / 180)
            local function Into(ax, sd)
                local r = T.RunOnce(def, sg, spec, 3, { frame = at, x = p.x + ax * c + sd * s, z = p.z - ax * s + sd * c, before = before }, 1)
                return r ~= nil and r.went_into or nil
            end
            local ways, differ = {}, false
            for _, q in ipairs({ { 3, 0 }, { -3, 0 }, { 0, 3 }, { 0, -3 } }) do
                local w = tostring(Into(q[1], q[2]))
                if ways[1] ~= nil and w ~= ways[1] then differ = true end
                ways[#ways + 1] = w
            end
            if differ then
                local zones = {}
                for ax = -BRANCH_R, BRANCH_R, BRANCH_STEP do
                    for sd = -BRANCH_R, BRANCH_R, BRANCH_STEP do
                        if ax * ax + sd * sd <= BRANCH_R * BRANCH_R then
                            local into = Into(ax, sd)
                            if into ~= nil then
                                zones[into] = zones[into] or {}
                                zones[into][Lib.Key(ax, sd)] = 0
                            end
                        end
                    end
                end
                local z = {}
                for into, cells in pairs(zones) do
                    local st = assert(loadstring("return " .. Lib.Steps(cells)))()
                    if st[1] ~= nil then z[#z + 1] = string.format("[%q] = %q", into, st[1].cells) end
                end
                if #z > 0 then out[#out + 1] = string.format("{ at = %d, zones = { %s } }", at - k0, table.concat(z, ", ")) end
            end
        end
    end
    if #out == 0 then return "nil" end
    return "{ " .. table.concat(out, ", ") .. " }"
end
-- a move's follow (-follow): "nil", or "{ from = frame, at = { { a, d, s }, ... } }" - one still
-- moved by where its target goes after a frame, but only so far: the Scrappy Werepig's junk, once
-- thrown (frame 21 of its throw), turns 45 degrees at most after you and goes only so much further
-- or shorter - drawn as going all the way with you it fell 3 to 5 off you as you ran. from: the
-- last frame a jump of its target is gone all the way with; after it, up to its deciding frame,
-- for places round it (a: angle, d: distance), with its target moved off that place by so much
-- then, how far its middle went: s = "qx,qz,mx,mz;..." (seen from the boss as the move began)
-- (gone with a jump less than FOLLOW_PART of the way: not all the way; over FOLLOW_SOME: still
-- going with it at all)
local FOLLOW_PART, FOLLOW_SOME = .75, .2
local FOLLOW_RADII, FOLLOW_TURNS = { 1, 2, 3, 4.5, 6, 7.5, 9, 11, 14 }, 16
local FOLLOW_DISTS = { 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30 }
local FOLLOW_ANGLES = {}
for a = -165, 180, 15 do FOLLOW_ANGLES[#FOLLOW_ANGLES + 1] = a end
-- (the middle of all a run struck)
local function MidOf(run)
    if run == nil then return nil end
    local n, x, z = 0, 0, 0
    for _, g in pairs(run.groups) do
        for k in pairs(g.cells) do
            local kx, kz = k:match("^([^,]+),(.+)$")
            n, x, z = n + 1, x + tonumber(kx), z + tonumber(kz)
        end
    end
    if n == 0 then return nil end
    return x / n, z / n
end
local function OnMap(x, z) return x >= Lib.AHEAD[1] + M and x <= Lib.AHEAD[2] - M and math.abs(z) <= Lib.SIDE - M end
function Follow(def, sg, spec, k0, dec)
    local bases = {}
    -- (its target at angle a, r away; it jumps to jx, jz at frame f: its middle then, and as it is)
    local function Run(a, r, f, jx, jz)
        spec_angle = a + .01
        local key = a .. "|" .. r
        if bases[key] == nil then bases[key] = { MidOf(T.RunOnce(def, sg, spec, r, nil, 1)) } end
        -- (never exactly on the line it faces: Place's .01)
        local qx, qz = MidOf(T.RunOnce(def, sg, spec, r, { frame = f, x = jx, z = jz - .002 }, 1))
        spec_angle = nil
        return qx, qz, bases[key][1], bases[key][2]
    end
    -- (how much of the way it went with a jump at frame f: aside and further, the least - jumps no
    -- bigger than one walks in a few frames: a boss turning after you only so far at once (the
    -- Scrappy Werepig, 45 degrees) follows a walk all the way, not a jump round it)
    local function Part(f)
        local part = nil
        for _, j in ipairs({ { 10, -3 }, { 16, 0 } }) do
            local qx, qz, bx, bz = Run(0, 10, f, j[1], j[2])
            if qx ~= nil and bx ~= nil then
                local vx, vz = j[1] - 10, j[2]
                local p = ((qx - bx) * vx + (qz - bz) * vz) / (vx * vx + vz * vz)
                part = math.min(part or p, p)
            end
        end
        return part
    end
    local from, some = nil, false
    for f = 0, dec - 1, 2 do
        local p = Part(f)
        if p ~= nil and from == nil and p < FOLLOW_PART then from = f end
        if from ~= nil and p ~= nil and p > FOLLOW_SOME then some = true end
    end
    if from == nil or not some then return "nil" end
    if from > 0 then
        local p = Part(from - 1)
        if p ~= nil and p < FOLLOW_PART then from = from - 1 end
    end
    local at = {}
    for _, a in ipairs(FOLLOW_ANGLES) do
        for _, r in ipairs(FOLLOW_DISTS) do
            local px, pz = r * math.cos(a * math.pi / 180), -r * math.sin(a * math.pi / 180)
            if OnMap(px, pz) then
                -- (each move in turn - radius by radius, round each - its middle gone so far: "" not known)
                local s, any = {}, false
                for _, q in ipairs(FOLLOW_RADII) do
                    for k = 0, FOLLOW_TURNS - 1 do
                        local qa = k * 2 * math.pi / FOLLOW_TURNS
                        local qx, qz = q * math.cos(qa), -q * math.sin(qa)
                        local v = ""
                        if OnMap(px + qx, pz + qz) then
                            local mx, mz, bx, bz = Run(a, r, from, px + qx, pz + qz)
                            if mx ~= nil and bx ~= nil then
                                local function F(n)
                                    local t = string.format("%.1f", n)
                                    t = t:gsub("^(%-?)0%.", "%1."):gsub("%.0$", "")
                                    if t == "" or t == "-" or t == "-." or t == "." then t = "0" end
                                    return t
                                end
                                v = F(mx - bx) .. "," .. F(mz - bz)
                                any = true
                            end
                        end
                        s[#s + 1] = v
                    end
                end
                if any then at[#at + 1] = string.format("{ a = %g, d = %g, s = %q }", a, r, table.concat(s, ";")) end
            end
        end
    end
    if #at == 0 then return "nil" end
    -- (from: the last frame gone all the way with - a read then sees a jump then)
    local radii = {}
    for _, q in ipairs(FOLLOW_RADII) do radii[#radii + 1] = tostring(q) end
    return string.format("{ from = %d, radii = { %s }, turns = %d, at = { %s } }", from - 1 - k0, table.concat(radii, ", "),
        FOLLOW_TURNS, table.concat(at, ", "))
end
local function Write(path, text)
    local f = assert(io.open(path, "wb"))
    f:write(text)
    f:close()
end

for _, w in ipairs(wanted) do
    local def, sg, spec, idx = Which(w)
    if def == nil then
        real_print("== " .. w .. ": not among the bosses run offline")
    else
        local prefab, state = def.prefab, StateName(spec)
        -- (each of its moves' first animation - going on into one of them stops a run there, as
        -- tools/sim_moves.lua does: a combo's next blow is a move of its own)
        local about = Lib.GettingAbout(def.sg)
        do
            trace_stop_at = nil
            local stop = {}
            for _, s in ipairs(def.states) do
                local r = T.RunOnce(def, sg, s, 3, nil, 1)
                local key = r ~= nil and KeyAnims(r.res, StateName(s), about) or {}
                if key[1] ~= nil then stop[key[1]] = StateName(s) end
            end
            for _, a in ipairs(def.stop or {}) do stop[a] = stop[a] or a end
            trace_stop_at = stop
        end
        local path = string.format("%s/%s#%d.lua", OUTDIR, prefab, idx)
        local t0 = Now()
        local skip, decide, name, k0, step_decide, branch = nil, nil, state, 0, nil, nil
        local entries, random, runs, made, by_boss = {}, false, 0, nil, false
        local partial = false
        local function PartPath(k) return string.format("%s/%s#%d.p%s.lua", OUTDIR, prefab, idx, tostring(k)) end
        -- (the name the mod knows it by - its first animation, as tools/sim_moves.lua names it, and
        -- its later form's - and the frame that begins on)
        local function Named(res)
            local key = KeyAnims(res, state, about)
            name = (key[1] or state) .. (type(spec) == "table" and spec.setup and ("@" .. spec.setup) or "")
                .. (type(spec) == "table" and spec.lucky and "@lucky" or "")
            k0 = key[1] ~= nil and res.anim_frame[key[1]] or 0
        end
        -- -follow: the move's file built already - its deciding frame from there
        if FOLLOW then
            local okf, tf = pcall(dofile, path)
            local out = "nil"
            if okf and type(tf) == "table" and tf.skip == nil and tf.decide ~= nil then
                local base = T.RunOnce(def, sg, spec, 6, nil, 1)
                if base ~= nil then
                    Named(base.res)
                    local dec = 0
                    for _, f in pairs(tf.decide) do dec = math.max(dec, f) end
                    out = Follow(def, sg, spec, k0, dec + k0)
                end
            end
            Write(string.format("%s/%s#%d.follow.lua", OUTDIR, prefab, idx), "return " .. out .. "\n")
            real_print(string.format("== %s (%s) follow: %s, %.0fs", w, state, out == "nil" and "none" or out:match("^{ from = %-?%d+"), Now() - t0))
            goto next_move
        end
        -- one place: cells -> the frame first struck (all seeds'); each seed's set, to tell random from not
        -- (and where the boss went, frame by frame from its first animation's start, as the first run
        -- went - "x,z;x,z;..." - up to its last strike there: true_range/predict moves the shape on by
        -- how far the boss really is from that)
        local function Place(a, r)
            local cells, first_set, pose, again, differs = {}, nil, nil, {}, false
            for seed = 1, SEEDS do
                -- (never exactly on the line it faces - the game's code treats that apart (the
                -- Scrappy Werepig's junk: "dx ~= 0 and dz ~= 0"), and in the game you never are)
                spec_angle = a + .01
                local res = T.RunOnce(def, sg, spec, r, nil, seed)
                runs = runs + 1
                if seed == 1 and res ~= nil then pose = res.res.pose_at end
                local set = {}
                for who, g in pairs(res and res.groups or {}) do
                    -- (the latest any thing that strikes is made, any place: by then it's there, or
                    -- isn't coming)
                    if who ~= "boss" and g.born ~= nil then made = math.max(made or 0, g.born - k0) end
                    if who == "boss" then by_boss = true end
                    for k, f in pairs(g.cells) do
                        local x, z = k:match("^([^,]+),(.+)$")
                        local key = Lib.Key(tonumber(x), tonumber(z))
                        set[key] = true
                        if cells[key] == nil or f - k0 < cells[key] then cells[key] = f - k0 end
                    end
                    for k, f in pairs(g.again or {}) do
                        local x, z = k:match("^([^,]+),(.+)$")
                        local key = Lib.Key(tonumber(x), tonumber(z))
                        again[key] = math.max(again[key] or (f - k0), f - k0)
                    end
                end
                if first_set == nil then first_set = set
                else
                    for key in pairs(set) do if not first_set[key] then differs = true end end
                    for key in pairs(first_set) do if not set[key] then differs = true end end
                end
                random = random or differs
                -- (the same twice: not random here - no more runs)
                if seed == 2 and not differs then break end
            end
            spec_angle = nil
            local path = nil
            -- (one that stays where it is: none)
            local moves = false
            if pose ~= nil then
                for fi = 0, 300 do
                    local q = pose[fi + k0]
                    if q == nil then break end
                    if q.x * q.x + q.z * q.z > .09 or math.abs((q.rot or 0) + 0) > 2 then moves = true break end
                end
            end
            if pose ~= nil and moves then
                local lastf = -1
                for _, fr in pairs(cells) do lastf = math.max(lastf, fr) end
                local p = {}
                for fi = 0, lastf do
                    local q = pose[fi + k0]
                    if q == nil then break end
                    p[#p + 1] = string.format("%.1f,%.1f,%.0f", q.x, q.z, q.rot or 0)
                end
                path = table.concat(p, ";")
            end
            -- (struck again there well after the first: kept apart - "again", as the first)
            for key, f in pairs(again) do
                if cells[key] == nil or f - cells[key] < AGAIN_APART then again[key] = nil end
            end
            return cells, path, again
        end
        -- the places run: every angle, or the K-th of each N (-part)
        local function Each(K, N, fn)
            for ai, a in ipairs(ANGLES) do
                if N == nil or (ai - 1) % N == K then
                    for _, r in ipairs(DISTS) do
                        local tx, tz = r * math.cos(a * math.pi / 180), -r * math.sin(a * math.pi / 180)
                        if tx >= Lib.AHEAD[1] + M and tx <= Lib.AHEAD[2] - M and math.abs(tz) <= Lib.SIDE - M then
                            fn(a, r, math.floor(tx / Lib.STEP + .5), math.floor(tz / Lib.STEP + .5))
                        end
                    end
                end
            end
        end
        if MERGE ~= nil then
            -- the parts, as one (and gone)
            local okd, pd = pcall(dofile, PartPath("d"))
            if not okd then pd = { skip = "a part missing" } end
            skip, decide, step_decide, branch = pd.skip, pd.decide, pd.step, pd.branch
            for K = 0, MERGE - 1 do
                local okp, p = pcall(dofile, PartPath(K))
                if not okp then p = { skip = "a part missing" } end
                skip = skip or p.skip
                random = random or p.random
                if p.made ~= nil then made = math.max(made or 0, p.made) end
                by_boss = by_boss or p.by_boss
                runs = runs + (p.runs or 0)
                name, k0 = p.name or name, p.k0 or k0
                for _, row in ipairs(p.rows or {}) do
                    local cells = {}
                    for gx, gz, fr in row.c:gmatch("(%-?%d+),(%-?%d+),(%-?%d+)") do
                        cells[Lib.Key(tonumber(gx) * Lib.STEP, tonumber(gz) * Lib.STEP)] = tonumber(fr)
                    end
                    local again = {}
                    for gx, gz, fr in (row.ag or ""):gmatch("(%-?%d+),(%-?%d+),(%-?%d+)") do
                        again[Lib.Key(tonumber(gx) * Lib.STEP, tonumber(gz) * Lib.STEP)] = tonumber(fr)
                    end
                    entries[#entries + 1] = { angle = row.angle, dist = row.dist, tgx = row.tgx, tgz = row.tgz, cells = cells, path = row.path, again = again }
                end
            end
            for K = 0, MERGE - 1 do os.remove(PartPath(K)) end
            os.remove(PartPath("d"))
            -- (finer where what it strikes changes fast from one place run to the next: half way
            -- between two side by side, run - kept where it isn't about half way between theirs
            -- (REFINE_OFF), and halved again there, REFINE_DEPTH times; not between two the same
            -- moved on with its target, or turned round the boss with it - those go between as they
            -- are. And between one that strikes and one that doesn't (the edge of its reach))
            if skip == nil then
                local function Mid(e)
                    local n, x, z = 0, 0, 0
                    for key in pairs(e.cells) do local gx, gz = Lib.KeyXZ(key) n = n + 1 x = x + gx * Lib.STEP z = z + gz * Lib.STEP end
                    if n == 0 then return nil end
                    return { x / n, z / n, n }
                end
                local function Norm(v) v = (v + 180) % 360 - 180 if v == -180 then v = 180 end return v end
                local function Target(a, r) return r * math.cos(a * math.pi / 180), -r * math.sin(a * math.pi / 180) end
                local have = {}
                for _, e in ipairs(entries) do e.mid = Mid(e) have[e.angle .. "|" .. e.dist] = e end
                local budget, extra = REFINE_RUNS, {}
                local function Try(A, B, depth)
                    local ca, cb = A.mid, B.mid
                    if ca == nil and cb == nil then return end
                    if ca ~= nil and cb ~= nil then
                        local d = math.sqrt((ca[1] - cb[1]) ^ 2 + (ca[2] - cb[2]) ^ 2)
                        if d <= REFINE_APART then return end
                        local alike = math.abs(ca[3] - cb[3]) <= .05 * math.max(ca[3], cb[3])
                        -- (moved on with its target)
                        local tax, taz = Target(A.angle, A.dist)
                        local tbx, tbz = Target(B.angle, B.dist)
                        if alike and math.abs((cb[1] - ca[1]) - (tbx - tax)) < .5 and math.abs((cb[2] - ca[2]) - (tbz - taz)) < .5 then
                            -- (and so known to go with its target: true_range/predict moves it on to
                            -- just where it is - kind "target")
                            A.follows, B.follows = true, true
                            return
                        end
                        -- (turned round the boss with it: as far out, the way it is)
                        local ra, rb = math.sqrt(ca[1] ^ 2 + ca[2] ^ 2), math.sqrt(cb[1] ^ 2 + cb[2] ^ 2)
                        if alike and A.dist == B.dist and math.abs(ra - rb) < .3 then return end
                    end
                    if budget <= 0 then return end
                    local ma = Norm(A.angle + ((B.angle - A.angle + 180) % 360 - 180) / 2)
                    local md = (A.dist + B.dist) / 2
                    local tx, tz = Target(ma, md)
                    if not (tx >= Lib.AHEAD[1] + M and tx <= Lib.AHEAD[2] - M and math.abs(tz) <= Lib.SIDE - M) then return end
                    budget = budget - 1
                    local cells, path, again = Place(ma, md)
                    local Me = { angle = ma, dist = md, cells = cells, path = path, again = again,
                        tgx = math.floor(tx / Lib.STEP + .5), tgz = math.floor(tz / Lib.STEP + .5) }
                    Me.mid = Mid(Me)
                    local keep = true
                    if ca ~= nil and cb ~= nil and Me.mid ~= nil then
                        local lx, lz = (ca[1] + cb[1]) / 2, (ca[2] + cb[2]) / 2
                        keep = math.sqrt((Me.mid[1] - lx) ^ 2 + (Me.mid[2] - lz) ^ 2) > REFINE_OFF
                    end
                    if keep then
                        extra[#extra + 1] = Me
                        if depth < REFINE_DEPTH then Try(A, Me, depth + 1) Try(Me, B, depth + 1) end
                    end
                end
                local di = {}
                for i, d in ipairs(DISTS) do di[d] = i end
                for _, e in ipairs(entries) do
                    local side = have[Norm(e.angle + 15) .. "|" .. e.dist]
                    if side ~= nil then Try(e, side, 1) end
                    local nd = di[e.dist] ~= nil and DISTS[di[e.dist] + 1] or nil
                    local out = nd ~= nil and have[e.angle .. "|" .. nd] or nil
                    if out ~= nil then Try(e, out, 1) end
                end
                for _, e in ipairs(extra) do entries[#entries + 1] = e end
                refined = #extra
            end
            table.sort(entries, function(p, q)
                if p.angle ~= q.angle then return p.angle < q.angle end
                return p.dist < q.dist
            end)
        elseif PART == "decide" then
            -- -part=decide: the frame its target's place stops mattering
            local d, base, step = T.Deciding(def, sg, spec, 6)
            local out = {}
            if base == nil then
                out[#out + 1] = string.format("return { skip = %q }", "it would not run")
            else
                Named(base.res)
                local l = {}
                for who, f in pairs(d or {}) do l[#l + 1] = string.format("[%q] = %d", who, f - k0) end
                -- (each blow's own: the frame it strikes -> its deciding frame)
                local s = {}
                for fr, f in pairs(step or {}) do s[#s + 1] = string.format("[%d] = %d", fr - k0, f - k0) end
                table.sort(s)
                -- (where its target stands at one frame says which of its moves it goes on into - a combo's
                -- next swipe if you're still in front of it, a butt slam if you're behind: that frame,
                -- and for each move it may go on into, where its target stood for it - seen from the
                -- boss as it was then (its place, the way it faced))
                local br = Branches(def, sg, spec, k0)
                out[#out + 1] = "return { decide = { " .. table.concat(l, ", ") .. " }, step = { " .. table.concat(s, ", ") .. " }, branch = " .. br .. " }"
            end
            Write(PartPath("d"), table.concat(out, "\n") .. "\n")
            partial = true
        else
            -- (one run, timed: how long all of them would take - the second: the first loads things)
            local first = T.RunOnce(def, sg, spec, 6, nil, 1)
            local t1 = Now()
            if first ~= nil then T.RunOnce(def, sg, spec, 6, nil, 2) end
            local one = Now() - t1
            local n = 0
            Each(PART, PARTS, function() n = n + 1 end)
            if first == nil then skip = "it would not run"
            else
                Named(first.res)
                if one * n * 2 > BUDGET then skip = string.format("too slow (%.2fs a run)", one) end
            end
            if skip == nil then
                Each(PART, PARTS, function(a, r, tgx, tgz)
                    local cells, path, again = Place(a, r)
                    entries[#entries + 1] = { angle = a, dist = r, cells = cells, path = path, again = again, tgx = tgx, tgz = tgz }
                end)
            end
            if PART ~= nil then
                -- -part=K/N: its places, raw - put together by -merge
                local out = { "return {", string.format("    name = %q, k0 = %d, random = %s, made = %s, by_boss = %s, runs = %d, skip = %s, rows = {",
                    name, k0, tostring(random), tostring(made), tostring(by_boss), runs, skip and string.format("%q", skip) or "nil") }
                for _, e in ipairs(entries) do
                    local c = {}
                    for key, fr in pairs(e.cells) do local gx, gz = Lib.KeyXZ(key) c[#c + 1] = gx .. "," .. gz .. "," .. fr end
                    local ag = {}
                    for key, fr in pairs(e.again or {}) do local gx, gz = Lib.KeyXZ(key) ag[#ag + 1] = gx .. "," .. gz .. "," .. fr end
                    out[#out + 1] = string.format("        { angle = %g, dist = %g, tgx = %d, tgz = %d, c = %q, ag = %q, path = %q },", e.angle, e.dist,
                        e.tgx, e.tgz, table.concat(c, ";"), table.concat(ag, ";"), e.path or "")
                end
                out[#out + 1] = "    },"
                out[#out + 1] = "}"
                Write(PartPath(PART), table.concat(out, "\n") .. "\n")
                partial = true
            else
                local d, _, st = T.Deciding(def, sg, spec, 6)
                decide, step_decide = {}, {}
                for who, f in pairs(d or {}) do decide[who] = f - k0 end
                for fr, f in pairs(st or {}) do step_decide[fr - k0] = f - k0 end
            end
        end
        if partial then
            real_print(string.format("== %s part %s: %d places, %d runs, %.0fs", w, tostring(PART), #entries, runs, Now() - t0))
        elseif skip ~= nil then
            Write(path, string.format("-- built by tools/build_tables.lua: %s\nreturn { prefab = %q, state = %q, index = %d, skip = %q }\n",
                w, prefab, state, idx, skip))
            real_print(string.format("== %s (%s): not built - %s", w, state, skip))
        else
            -- (a place struck just as another is - the same cells, or the same moved on with its
            -- target: that one's, not written again - a spell cast where you stand is the same
            -- circle everywhere, a swipe the same whatever you do)
            -- (alike: all but a few cells - LIKE_OFF of them - the same, struck within LIKE_FRAMES: a
            -- target a part of a cell off changes a circle's edge by a cell, no more)
            local LIKE_OFF, LIKE_FRAMES = .03, 2
            -- (struck only by things it sets off: when each cell is struck as one's about the same -
            -- junk falling where it may: alike by where, not when)
            if not by_boss then LIKE_FRAMES = math.huge end
            local bases = {}
            for _, e in ipairs(entries) do
                e.list = {}
                for key, fr in pairs(e.cells) do
                    local gx, gz = Lib.KeyXZ(key)
                    e.list[#e.list + 1] = { gx, gz, fr }
                end
                for key, fr in pairs(e.again or {}) do
                    local gx, gz = Lib.KeyXZ(key)
                    e.list[#e.list + 1] = { gx, gz + 2000, fr }
                end
            end
            -- (how many of e's cells are not in base b's, moved by (sx, sz) cells, struck about as soon)
            local function Off(e, b, sx, sz, limit)
                if b.lookup == nil then
                    b.lookup = {}
                    for _, c in ipairs(b.list) do b.lookup[c[1] * 4096 + c[2]] = c[3] end
                end
                local bad = 0
                for _, c in ipairs(e.list) do
                    local f = b.lookup[(c[1] - sx) * 4096 + (c[2] - sz)]
                    if f == nil or math.abs(f - c[3]) > LIKE_FRAMES then
                        bad = bad + 1
                        if bad > limit then return bad end
                    end
                end
                return bad
            end
            for i, e in ipairs(entries) do
                local n = #e.list
                local limit = math.floor(n * LIKE_OFF)
                for _, j in ipairs(bases) do
                    local b = entries[j]
                    if math.abs(#b.list - n) <= limit then
                        -- (the same where it is; or moved on with its target)
                        if Off(e, b, 0, 0, limit) <= limit and Off(b, e, 0, 0, limit) <= limit then
                            e.like = j
                            break
                        end
                        local sx, sz = e.tgx - b.tgx, e.tgz - b.tgz
                        if n > 0 and Off(e, b, sx, sz, limit) <= limit and Off(b, e, -sx, -sz, limit) <= limit then
                            e.like, e.dx, e.dz = j, sx * Lib.STEP, sz * Lib.STEP
                            break
                        end
                    end
                end
                if e.like == nil then bases[#bases + 1] = i end
            end
            local out = { "-- built by tools/build_tables.lua: " .. w, "return {" }
            local last = 0
            for _, e in ipairs(entries) do for _, fr in pairs(e.cells) do last = math.max(last, fr) end end
            out[#out + 1] = string.format("    prefab = %q, state = %q, index = %d, name = %q, random = %s, last = %d, made = %s, by_boss = %s,",
                prefab, state, idx, name, tostring(random), last, tostring(made), tostring(by_boss))
            local d = {}
            for who, f in pairs(decide or {}) do d[#d + 1] = string.format("[%q] = %d", who, f) end
            table.sort(d)
            out[#out + 1] = "    decide = { " .. table.concat(d, ", ") .. " },"
            local sd = {}
            for fr, f in pairs(step_decide or {}) do sd[#sd + 1] = string.format("[%d] = %d", fr, f) end
            table.sort(sd)
            out[#out + 1] = "    step_decide = { " .. table.concat(sd, ", ") .. " },"
            if branch ~= nil then
                local bl = {}
                for _, b in ipairs(branch) do
                    local z = {}
                    for into, cells in pairs(b.zones) do z[#z + 1] = string.format("[%q] = %q", into, cells) end
                    bl[#bl + 1] = string.format("{ at = %d, zones = { %s } }", b.at, table.concat(z, ", "))
                end
                out[#out + 1] = "    branch = { " .. table.concat(bl, ", ") .. " },"
            end
            out[#out + 1] = "    entries = {"
            local own = 0
            for _, e in ipairs(entries) do
                if e.like ~= nil then
                    out[#out + 1] = string.format("        { angle = %g, dist = %g, like = %d%s },", e.angle, e.dist, e.like,
                        e.dx ~= nil and string.format(", dx = %.2f, dz = %.2f", e.dx, e.dz) or "")
                else
                    own = own + 1
                    local n = 0
                    for _ in pairs(e.cells) do n = n + 1 end
                    -- (the middle of all it strikes there, seen from the boss: true_range/predict eases
                    -- the shape between the places run by it)
                    local sx, sz = 0, 0
                    for key in pairs(e.cells) do local gx, gz = Lib.KeyXZ(key) sx, sz = sx + gx * Lib.STEP, sz + gz * Lib.STEP end
                    local steps, mx, mz = "{}", 0, 0
                    if n > 0 then steps, mx, mz = StepsOf(e) end
                    out[#out + 1] = string.format("        { angle = %g, dist = %g, cx = %.2f, cz = %.2f,%s%s path = %q, steps = %s },", e.angle, e.dist,
                        n > 0 and sx / n or 0, n > 0 and sz / n or 0, e.follows and " follows = true," or "",
                        (mx ~= 0 or mz ~= 0) and string.format(" sx = %g, sz = %g,", mx, mz) or "", e.path or "", steps)
                end
            end
            out[#out + 1] = "    },"
            out[#out + 1] = "}"
            Write(path, table.concat(out, "\n") .. "\n")
            if PIC then
                -- a picture: places at 0, 45 (or 30), 90 degrees, 6 and 12 (or 10) away - each panel seen
                -- from above, the boss (white dot) facing right as the move begins, its target (white
                -- ring), the cells struck coloured by when (early yellow, late red)
                local PX, W = 12, 36
                local shown = { { 0, 6 }, { 45, 6 }, { 90, 6 }, { 0, 12 }, { 45, 12 }, { 90, 12 } }
                local cols, rows = 3, 2
                local pw = W * PX
                local img = {}
                local IW, IH = cols * pw + (cols + 1) * 4, rows * pw + (rows + 1) * 4
                for i = 1, IW * IH do img[i] = { 60, 52, 40 } end
                local function Set(x, y, c) if x >= 0 and y >= 0 and x < IW and y < IH then img[y * IW + x + 1] = c end end
                local fmin, fmax = math.huge, -math.huge
                for _, e in ipairs(entries) do for _, fr in pairs(e.cells) do fmin, fmax = math.min(fmin, fr), math.max(fmax, fr) end end
                for pi, s in ipairs(shown) do
                    local e, best = nil, nil
                    for _, x in ipairs(entries) do
                        local off = math.abs(x.angle - s[1]) * 100 + math.abs(x.dist - s[2])
                        if best == nil or off < best then e, best = x, off end
                    end
                    local ox = 4 + ((pi - 1) % cols) * (pw + 4)
                    local oy = 4 + math.floor((pi - 1) / cols) * (pw + 4)
                    local bx, by = ox + math.floor(pw / 3), oy + math.floor(pw / 2)
                    for y = 0, pw - 1 do for x = 0, pw - 1 do Set(ox + x, oy + y, { 110, 95, 70 }) end end
                    for key, fr in pairs(e and e.cells or {}) do
                        local gx, gz = Lib.KeyXZ(key)
                        local wx, wz = gx * Lib.STEP, gz * Lib.STEP
                        local k = fmax > fmin and (fr - fmin) / (fmax - fmin) or 0
                        local c = { 230, math.floor(220 - 180 * k), 40 }
                        local cx, cy = bx + math.floor(wx * PX), by + math.floor(wz * PX)
                        for dy = 0, math.ceil(Lib.STEP * PX) - 1 do
                            for dx = 0, math.ceil(Lib.STEP * PX) - 1 do
                                if cx + dx >= ox and cx + dx < ox + pw and cy + dy >= oy and cy + dy < oy + pw then Set(cx + dx, cy + dy, c) end
                            end
                        end
                    end
                    for dy = -2, 2 do for dx = -2, 2 do Set(bx + dx, by + dy, { 255, 255, 255 }) end end
                    if e ~= nil then
                        local a = e.angle * math.pi / 180
                        local tx, ty = bx + math.floor(e.dist * math.cos(a) * PX), by + math.floor(-e.dist * math.sin(a) * PX)
                        for t = 0, 63 do
                            local q = t / 64 * 2 * math.pi
                            Set(tx + math.floor(.5 * PX * math.cos(q)), ty + math.floor(.5 * PX * math.sin(q)), { 255, 255, 255 })
                        end
                    end
                end
                local buf = {}
                for i = 1, IW * IH do local c = img[i] buf[i] = string.char(c[1], c[2], c[3]) end
                Write(string.format("%s/%s#%d.ppm", OUTDIR, prefab, idx),
                    string.format("P6\n%d %d\n255\n", IW, IH) .. table.concat(buf))
            end
            local dl = {}
            for who, f in pairs(decide or {}) do dl[#dl + 1] = who .. " " .. f end
            real_print(string.format("== %s (%s, %s): %d places (%d own, %d finer), %d runs, %.0fs; deciding frame: %s; random: %s",
                w, state, name, #entries, own, refined, runs, Now() - t0, table.concat(dl, ", "), tostring(random)))
        end
    end
    ::next_move::
end

-- -client: all of them, as the mod reads them - prefab -> its move's name -> { decide (the frame from
-- which where its target is no longer matters - the latest of its groups), random, last, made,
-- things (what it strikes by: what it sets off - drawn on their own once there), entries }
-- (two of one boss's moves named alike: the later "name~state", as tools/sim_moves.lua names them)
if CLIENT ~= nil then
    local list = dofile(OUTDIR .. "/index.lua")
    local okd, drop = pcall(dofile, OUTDIR .. "/drop.lua")
    if not okd or type(drop) ~= "table" then drop = {} end
    -- (not those the mod draws as before whatever - in legs, spinning round after you, a set way:
    -- true_range/predict TableOf - as the offline data has them)
    local oks, sim = pcall(dofile, (CLIENT:gsub("moves_table%.lua$", "moves_sim.lua")))
    if not oks or type(sim) ~= "table" then sim = {} end
    -- (a boss's way that goes somewhere - not one standing where it is)
    local function Moving(path)
        for x, z, r in (path or ""):gmatch("([%-%d%.]+),([%-%d%.]+),?([%-%d%.]*)") do
            if tonumber(x) ^ 2 + tonumber(z) ^ 2 > .09 or math.abs(tonumber(r) or 0) > 2 then return true end
        end
        return false
    end
    local function Skipped(p, name)
        local e = sim[p] ~= nil and sim[p][name] or nil
        return e ~= nil and (e.leg ~= nil or e.around ~= nil or e.fixed)
    end
    local by, prefabs = {}, {}
    for _, file in ipairs(list) do
        local ok, t = pcall(dofile, OUTDIR .. "/" .. file)
        if ok and type(t) == "table" and not t.skip then
            if by[t.prefab] == nil then by[t.prefab] = {} prefabs[#prefabs + 1] = t.prefab end
            table.insert(by[t.prefab], t)
            -- (how far it goes with its target late on: -follow, if run)
            local f = io.open(string.format("%s/%s#%d.follow.lua", OUTDIR, t.prefab, t.index), "rb")
            if f ~= nil then t.follow = f:read("*a"):match("^return (.-)%s*$") f:close() end
        end
    end
    table.sort(prefabs)
    local out = { "-- Made by true_range_workshop/tools/build_tables.lua - not by hand. Where each move strikes",
        "-- with its target at each place round it (REDESIGN.md): angle from the way the boss faced as",
        "-- the move began (degrees, round to the left), distance; frames from its first animation's start.",
        "-- like: as that row of it (dx, dz: moved on by so much, seen the same way)",
        "return {" }
    local n_moves = 0
    for _, p in ipairs(prefabs) do
        table.sort(by[p], function(a, b) return a.index < b.index end)
        local used, lines = {}, {}
        for _, t in ipairs(by[p]) do
            local name = t.name or t.state
            if used[name] then name = name .. "~" .. t.state end
            used[name] = true
            if not drop[p .. "|" .. name] and not Skipped(p, name) then
                n_moves = n_moves + 1
                local decide, things = 0, {}
                for who, f in pairs(t.decide or {}) do
                    decide = math.max(decide, f)
                    if who ~= "boss" then things[#things + 1] = string.format("%q", who) end
                end
                table.sort(things)
                -- (each move its own function: one file's main function may hold only so many
                -- constants - Lua 5.1, the game's too)
                local sd = {}
                for fr, f in pairs(t.step_decide or {}) do sd[#sd + 1] = string.format("[%d] = %d", fr, f) end
                table.sort(sd)
                local br = "nil"
                if t.branch ~= nil then
                    local bl = {}
                    for _, b in ipairs(t.branch) do
                        local z = {}
                        for into, cells in pairs(b.zones) do z[#z + 1] = string.format("[%q] = %q", into, cells) end
                        bl[#bl + 1] = string.format("{ at = %d, zones = { %s } }", b.at, table.concat(z, ", "))
                    end
                    br = "{ " .. table.concat(bl, ", ") .. " }"
                end
                lines[#lines + 1] = string.format("        [%q] = (function() return { decide = %d, random = %s, last = %d, made = %s, by_boss = %s, things = { %s }, step_decide = { %s }, branch = %s, follow = %s, entries = {",
                    name, decide, tostring(t.random), t.last or 0, tostring(t.made), tostring(t.by_boss == true), table.concat(things, ", "), table.concat(sd, ", "), br, t.follow or "nil")
                -- (what each row's shape goes with, told by the rows like it: the same at other angles -
                -- the boss, not turning to its target ("boss"); the same moved on with its target -
                -- the target ("target"); neither - turned round as far as its target is (nil))
                for _, e in ipairs(t.entries) do
                    if e.follows and e.like == nil then e.kind = e.kind or "target" end
                    local b = e.like ~= nil and t.entries[e.like] or nil
                    if b ~= nil then
                        if e.dx ~= nil then b.kind = "target"
                        elseif b.angle ~= e.angle and b.kind == nil then b.kind = "boss" end
                    end
                end
                for _, e in ipairs(t.entries) do
                    if e.like ~= nil then
                        lines[#lines + 1] = string.format("            { angle = %g, dist = %g, like = %d%s },", e.angle, e.dist, e.like,
                            e.dx ~= nil and string.format(", dx = %.2f, dz = %.2f", e.dx, e.dz) or "")
                    else
                        local steps = {}
                        for _, s in ipairs(e.steps) do steps[#steps + 1] = string.format("{ at = %d, cells = %q }", s.at, s.cells) end
                        lines[#lines + 1] = string.format("            { angle = %g, dist = %g, cx = %.2f, cz = %.2f,%s%s%s steps = { %s } },", e.angle, e.dist, e.cx or 0, e.cz or 0,
                            e.kind and string.format(" kind = %q,", e.kind) or "",
                            e.sx ~= nil and string.format(" sx = %g, sz = %g,", e.sx, e.sz) or "",
                            Moving(e.path) and string.format(" path = %q,", e.path) or "",
                            table.concat(steps, ", "))
                    end
                end
                lines[#lines + 1] = "        } } end)(),"
            end
        end
        if #lines > 0 then
            out[#out + 1] = string.format("    [%q] = {", p)
            for _, l in ipairs(lines) do out[#out + 1] = l end
            out[#out + 1] = "    },"
        end
    end
    -- (and where its target standing makes it go on into another of its moves, every move with one -
    -- drawn whichever way the move itself is: _branches)
    -- (every move's deciding frame, from the game's code - tools/trace_moves.lua: when it stops
    -- going by where its target is - also for a move drawn as before: _decide)
    out[#out + 1] = "    _decide = {"
    for _, p in ipairs(prefabs) do
        local used, dl = {}, {}
        for _, t in ipairs(by[p]) do
            local name = t.name or t.state
            if used[name] then name = name .. "~" .. t.state end
            used[name] = true
            local d = nil
            for _, f in pairs(t.decide or {}) do d = math.max(d or f, f) end
            if d ~= nil then dl[#dl + 1] = string.format("[%q] = %d", name, d) end
        end
        if #dl > 0 then out[#out + 1] = string.format("        [%q] = { %s },", p, table.concat(dl, ", ")) end
    end
    out[#out + 1] = "    },"
    out[#out + 1] = "    _branches = {"
    for _, p in ipairs(prefabs) do
        local used, bl = {}, {}
        for _, t in ipairs(by[p]) do
            local name = t.name or t.state
            if used[name] then name = name .. "~" .. t.state end
            used[name] = true
            if t.branch ~= nil then
                local l = {}
                for _, b in ipairs(t.branch) do
                    local z = {}
                    for into, cells in pairs(b.zones) do z[#z + 1] = string.format("[%q] = %q", into, cells) end
                    l[#l + 1] = string.format("{ at = %d, zones = { %s } }", b.at, table.concat(z, ", "))
                end
                bl[#bl + 1] = string.format("            [%q] = { %s },", name, table.concat(l, ", "))
            end
        end
        if #bl > 0 then
            out[#out + 1] = string.format("        [%q] = {", p)
            for _, l in ipairs(bl) do out[#out + 1] = l end
            out[#out + 1] = "        },"
        end
    end
    out[#out + 1] = "    },"
    -- (states its code may go through on the way, never run offline: one its move's states go to,
    -- an attack's ("attack" among its tags), held on an animation going round, that goes on back
    -- into the move - the Scrappy Werepig
    -- holding its junk (throw_loop), its target lost as it wound up, till it has one again: their
    -- animations, the same move all the while - _waits)
    out[#out + 1] = "    _waits = {"
    for _, d in ipairs(Lib.BOSSES) do
        local f = io.open(SCRIPTS .. "/stategraphs/" .. d.sg .. ".lua", "rb")
        local text = f ~= nil and f:read("*a") or ""
        if f ~= nil then f:close() end
        local blocks, starts = {}, {}
        for pos in text:gmatch("()State%s*{") do starts[#starts + 1] = pos end
        for i, pos in ipairs(starts) do
            local block = text:sub(pos, (starts[i + 1] or #text + 1) - 1)
            local name = block:match('name%s*=%s*"([^"]+)"')
            if name ~= nil then
                local b = { tags = block:match("tags%s*=%s*(%b{})") or "", anims = {}, gotos = {} }
                for a in block:gmatch('PlayAnimation%(%s*"([^"]+)"') do b.anims[#b.anims + 1] = a end
                -- (one held, playing on round till something comes: "PlayAnimation(..., true)")
                b.loops = {}
                for a in block:gmatch('PlayAnimation%(%s*"([^"]+)"%s*,%s*true%s*%)') do b.loops[#b.loops + 1] = a end
                for g in block:gmatch('GoToState%(%s*"([^"]+)"') do b.gotos[g] = true end
                blocks[name] = b
            end
        end
        local moves = sim[d.prefab] or {}
        -- (another move's first animation: that move, not a wait)
        local firsts = {}
        for _, m in pairs(moves) do if type(m) == "table" and m.anims ~= nil and m.anims[1] ~= nil then firsts[m.anims[1]] = true end end
        local wl = {}
        for name, m in pairs(moves) do
            if type(m) == "table" and m.anims ~= nil then
                local mine = {}
                for _, a in ipairs(m.anims) do mine[a] = true end
                local function Its(b) for _, a in ipairs(b.anims) do if mine[a] then return true end end return false end
                local waits, seen = {}, {}
                for _, b in pairs(blocks) do
                    if Its(b) then
                        for g in pairs(b.gotos) do
                            local w = blocks[g]
                            if w ~= nil and not Its(w) and w.tags:find('"attack"', 1, true) then
                                local back = false
                                for g2 in pairs(w.gotos) do if blocks[g2] ~= nil and Its(blocks[g2]) then back = true end end
                                if back then
                                    for _, a in ipairs(w.loops) do
                                        if not firsts[a] and not seen[a] then seen[a] = true waits[#waits + 1] = string.format("%q", a) end
                                    end
                                end
                            end
                        end
                    end
                end
                if #waits > 0 then
                    table.sort(waits)
                    wl[#wl + 1] = string.format("[%q] = { %s }", name, table.concat(waits, ", "))
                end
            end
        end
        table.sort(wl)
        if #wl > 0 then out[#out + 1] = string.format("        [%q] = { %s },", d.prefab, table.concat(wl, ", ")) end
    end
    out[#out + 1] = "    },"
    out[#out + 1] = "}"
    Write(CLIENT, table.concat(out, "\n") .. "\n")
    real_print(string.format("== for the mod: %s (%d moves)", CLIENT, n_moves))
end
