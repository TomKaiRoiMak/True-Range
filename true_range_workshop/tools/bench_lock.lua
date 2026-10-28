-- luajit tools/bench_lock.lua <client_log.txt> [<true_range dir>] [um]
-- What the testbench (tr_testbench, [tr_bench] lines) found, move by move, against True Range's data:
--   step k: you stepped 5 to its side at frame k of the move - struck after that or not. Struck when you
--           stepped late, not when early: it stopped aiming between. Struck either way: it follows you
--           (or reaches 5 aside anyway). The data's lock should sit where struck turns to missed.
--   jump d: you were put d in front of it at its first frame - struck or not: how far it reaches.
-- Moves told apart by the state it was in as it began and its animation then.
local LOG, MOD, UM = arg[1], arg[2] or "../true_range", arg[3] == "um"
local FRAMES = 1 / 30

-- (the data as the mod has it: the game's, the mod's laid over move by move)
local function Load(f) local fn = loadfile(f) if fn == nil then return {} end return fn() or {} end
local data = Load(MOD .. "/scripts/true_range/moves_sim.lua")
if UM then
    local um = Load(MOD .. "/scripts/true_range/moves_sim_um.lua")
    for p, e in pairs(um) do
        if p:sub(1, 1) ~= "_" and type(e) == "table" then
            if (um._replace or {})[p] then data[p] = e else
                data[p] = data[p] or {}
                for k, v in pairs(e) do data[p][k] = v end
            end
        end
    end
end
local function DataMoves(prefab, anim)
    local e = data[prefab] or data[(data._alias or {})[prefab] or ""] or {}
    local out = {}
    for name, m in pairs(e) do
        if type(m) == "table" and m.anims ~= nil and m.anims[1] == anim then
            out[#out + 1] = string.format("%s lock=%s first=%s frame=%s", name, tostring(m.lock), tostring(m.first), tostring(m.frame))
        end
    end
    table.sort(out)
    return #out > 0 and table.concat(out, "; ") or "(no move in the data for this animation)"
end

local runs, open = {}, {}
local last_t = 0
-- (things as they first appeared ([tr_haz], by guid): a hit by one counted for a scene only if one of its
-- kind appeared after the scene began - not one left lying from the move before, at a boss's home where
-- it can't be moved off)
local seen_guid, appeared, haz_kinds = {}, {}, {}
-- (and not one by another monster - traced on its own: Moonmaw's lavae flown off after you, a boss's
-- underlings - their blows aren't the move's)
local monsters = {}
local function NewSince(prefab, t0, t)
    if not haz_kinds[prefab] then return true end   -- (not one the trace follows: can't tell - counted)
    for _, ta in ipairs(appeared[prefab] or {}) do if ta >= t0 - .05 and ta <= t + .05 then return true end end
    return false
end
local function Num(s) return tonumber(s) end
local spawn_t = {}
for line in io.lines(LOG) do
    local t, prefab, what, rest = line:match("%[tr_bench%] ([%d%.]+) ([%w_%-]+) (%a+)(.*)$")
    if t ~= nil then
        t = Num(t)
        last_t = t
        if what == "start" then
            local r = { prefab = prefab, t0 = t, n = Num(rest:match("n=(%d+)")), state = rest:match("state=([%w_]+)"),
                mode = rest:match("mode=(%a+)"), k = Num(rest:match(" k=([%d]+)") or ""), jump = Num(rest:match("jump=([%d%.]+)") or ""),
                orbit = Num(rest:match("orbit=([%d]+)") or "") or 60,
                hits = {} }
            open[prefab] = r
            runs[#runs + 1] = r
        elseif what == "spawned" then
            spawn_t[prefab] = t
        elseif what == "speed" then
            -- ("speed off": sped up, its ticks grew longer - all begun before, at that speed: not counted -
            -- that boss's since it came out only: all runs of every share before, in the logs all in one, were
            -- dropped with them; the reviewer, 2026-10-18)
            for _, r in ipairs(runs) do
                if r.prefab == prefab and r.t0 <= t and r.t0 >= (spawn_t[prefab] or -math.huge) then r.noplace = true end
            end
        elseif what == "noplace" and open[prefab] ~= nil then
            open[prefab].noplace = true
        elseif what == "side" and open[prefab] ~= nil then
            open[prefab].side_t = t
        elseif what == "end" and open[prefab] ~= nil then
            open[prefab].t1 = t
            open[prefab].frames = Num(rest:match("frames=(%d+)"))
            open[prefab] = nil
        end
    else
        local tt, p2, tail = line:match("%[tr_trace%] ([%d%.]+) ([%w_]+) (.*)$")
        if tt ~= nil then
            tt = Num(tt)
            last_t = tt
            monsters[p2] = true
            local r = open[p2]
            if r ~= nil then
                if r.anim == nil then r.anim = tail:match(" anim=([%w_]+)") end
                -- (how far round it turned from how it faced as the move began - turning after you, or not at all)
                local rot = Num(tail:match(" rot=([%d%.%-]+)") or "")
                if rot ~= nil then
                    r.rots = r.rots or {}
                    r.rots[#r.rots + 1] = { tt, rot }
                end
                if tail:find("^STRIKE at ") or tail:find("^HIT at ") then r.hits[#r.hits + 1] = { t = tt, by = p2 } end
            end
        else
            local ht, hp, hg = line:match("%[tr_haz%] ([%d%.]+) ([%w_]+) guid=(%d+)")
            if ht ~= nil then
                haz_kinds[hp] = true
                if not seen_guid[hg] then
                    seen_guid[hg] = true
                    appeared[hp] = appeared[hp] or {}
                    table.insert(appeared[hp], Num(ht))
                end
            end
            local by = line:match("%[true_range%] you were struck[^,]* by ([%w_]+),")
            if by ~= nil then
                for _, r in pairs(open) do
                    if by == r.prefab or (not monsters[by] and NewSince(by, r.t0, last_t)) then r.hits[#r.hits + 1] = { t = last_t, by = by, thing = by ~= r.prefab } end
                end
            end
        end
    end
end

-- per move: step k -> struck after stepping or not; jump d -> struck or not
local moves, order = {}, {}
for _, r in ipairs(runs) do
    if r.t1 ~= nil and not r.noplace then
        local key = r.prefab .. " " .. (r.state or "?") .. " " .. (r.anim or "?")
        local m = moves[key]
        if m == nil then m = { prefab = r.prefab, anim = r.anim, steps = {}, jumps = {}, strike_f = {}, turned = 0, runs = 0, turn_max = 0 } moves[key] = m order[#order + 1] = key end
        m.runs = m.runs + 1
        -- (only up to its first blow: turning to you again after, its move done, is no aim)
        do
            local until_t = math.huge
            for _, h in ipairs(r.hits) do until_t = math.min(until_t, h.t) end
            if until_t == math.huge then until_t = r.t1 end
            local r0 = r.rots ~= nil and r.rots[1] ~= nil and r.rots[1][2] or nil
            r.turn = 0
            for _, s in ipairs(r.rots or {}) do
                if s[1] <= until_t then r.turn = math.max(r.turn, math.abs((s[2] - r0 + 180) % 360 - 180)) end
            end
        end
        if (r.turn or 0) > 5 then m.turned = m.turned + 1 end
        m.turn_max = math.max(m.turn_max, r.turn or 0)
        local first = nil
        for _, h in ipairs(r.hits) do if first == nil or h.t < first then first = h.t end end
        if first ~= nil then m.strike_f[#m.strike_f + 1] = math.floor((first - r.t0) / FRAMES + .5) end
        if r.mode == "step" and r.k ~= nil then
            local after = false
            for _, h in ipairs(r.hits) do if r.side_t ~= nil and h.t > r.side_t + FRAMES then after = true end end
            m.steps[r.orbit] = m.steps[r.orbit] or {}
            local s = m.steps[r.orbit][r.k] or { hit = 0, n = 0 }
            s.n = s.n + 1
            if after then s.hit = s.hit + 1 end
            m.steps[r.orbit][r.k] = s
        elseif r.mode == "jump" and r.jump ~= nil then
            local j = m.jumps[r.jump] or { hit = 0, n = 0 }
            j.n = j.n + 1
            if #r.hits > 0 then j.hit = j.hit + 1 end
            m.jumps[r.jump] = j
        end
    end
end
table.sort(order)
for _, key in ipairs(order) do
    local m = moves[key]
    if next(m.steps) ~= nil or next(m.jumps) ~= nil then
        print("== " .. key)
        print("   data: " .. DataMoves(m.prefab, m.anim or ""))
        table.sort(m.strike_f)
        print("   first struck at frame: " .. (#m.strike_f > 0 and table.concat(m.strike_f, ",") or "never"))
        -- (turned after you or not, as the trace has it: struck when stepped 150 round with no turn = all
        -- round it, or what it set off followed you - not it aiming)
        print(string.format("   turned before its first blow: %d of %d runs (most %.0f deg)", m.turned, m.runs, m.turn_max))
        local orbits = {}
        for o in pairs(m.steps) do orbits[#orbits + 1] = o end
        table.sort(orbits)
        for _, o in ipairs(orbits) do
            local ks = {}
            for k in pairs(m.steps[o]) do ks[#ks + 1] = k end
            table.sort(ks)
            local line, last_hit = {}, nil
            for _, k in ipairs(ks) do
                local s = m.steps[o][k]
                line[#line + 1] = string.format("%d:%d/%d", k, s.hit, s.n)
                if s.hit > 0 then last_hit = k end
            end
            print(string.format("   stepped %d round at k - struck/runs  %s   (last k still struck: %s)", o, table.concat(line, " "), last_hit ~= nil and tostring(last_hit) or "none"))
        end
        local ds = {}
        for d in pairs(m.jumps) do ds[#ds + 1] = d end
        table.sort(ds)
        local jl = {}
        for _, d in ipairs(ds) do jl[#jl + 1] = string.format("%g:%d/%d", d, m.jumps[d].hit, m.jumps[d].n) end
        if #jl > 0 then print("   jump d:struck/runs  " .. table.concat(jl, " ")) end
    end
end

-- coverage: each move in the data for the bosses run - tested how often (by its first animation), or never
do
    local seen, prefabs = {}, {}
    for _, r in ipairs(runs) do
        prefabs[r.prefab] = true
        if r.anim ~= nil then seen[r.prefab .. "|" .. r.anim] = (seen[r.prefab .. "|" .. r.anim] or 0) + 1 end
    end
    local ps = {}
    for p in pairs(prefabs) do ps[#ps + 1] = p end
    table.sort(ps)
    print("")
    print("== coverage (moves in the data, by how often each was tested)")
    for _, p in ipairs(ps) do
        local e = data[p] or data[(data._alias or {})[p] or ""] or {}
        local got, never = {}, {}
        for name, m in pairs(e) do
            if type(m) == "table" and m.anims ~= nil then
                local n = seen[p .. "|" .. m.anims[1]] or 0
                if n > 0 then got[#got + 1] = string.format("%s %d", name, n) else never[#never + 1] = name end
            end
        end
        table.sort(got)
        table.sort(never)
        print(string.format("   %s: tested %s", p, #got > 0 and table.concat(got, ", ") or "-"))
        if #never > 0 then print(string.format("   %s: NEVER %s", p, table.concat(never, ", "))) end
    end
end