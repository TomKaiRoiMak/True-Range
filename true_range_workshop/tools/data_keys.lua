-- luajit data_keys.lua <moves_sim.lua> <moves_sim_um.lua> [<moves_sim_te.lua> ...]: for every monster in the data, a key for
-- what its replay draws from - its own moves (the game's and each mod's, as moddata lays them), the one it's drawn as
-- (_alias), and the things it sets off (_hazards whose "by" has it) - so a replay is run again only when that changed
-- (tests/bench_replay.ps1's cache; VERIFY_PLAN 6.15). "_haz" keys all things. Prints "<prefab> <key>" a line.
-- (any number of data files - Tropical Experience's too, bench_replay -TE: left out, a change to it alone kept the old
-- results, 2026-10-21)
DEGREES, FRAMES = math.pi / 180, 1 / 30
local ds = {}
for i = 1, #arg do ds[#ds + 1] = dofile(arg[i]) end
local g = ds[1]
local function S(v)
    if type(v) ~= "table" then return type(v) == "number" and string.format("%.6g", v) or tostring(v) end
    local ks = {}
    for k in pairs(v) do ks[#ks + 1] = k end
    table.sort(ks, function(a, b) return tostring(a) < tostring(b) end)
    local o = {}
    for _, k in ipairs(ks) do o[#o + 1] = tostring(k) .. "=" .. S(v[k]) end
    return "{" .. table.concat(o, ",") .. "}"
end
-- (a short hash of a string - FNV-1a, 32 bits, twice over two halves of the seed: collisions here only
-- cost a replay run that needn't have been)
local bit = require("bit")
local function H(s)
    local a, b = 2166136261, 16777619
    for i = 1, #s do
        local c = s:byte(i)
        a = bit.tobit(bit.bxor(a, c) * 16777619)
        b = bit.tobit(bit.bxor(b, c) * 2166136261 + i)
    end
    return string.format("%08x%08x", bit.band(a, 0xffffffff) % 4294967296, bit.band(b, 0xffffffff) % 4294967296)
end
local alias = {}
for _, d in ipairs(ds) do for k, v in pairs(d._alias or {}) do alias[k] = v end end
local names = {}
for _, d in ipairs(ds) do
    for k in pairs(d) do if k:sub(1, 1) ~= "_" then names[k] = true end end
end
for k in pairs(alias) do names[k] = true end
local hz = {}
for _, d in ipairs(ds) do for k, v in pairs(d._hazards or {}) do hz[k] = hz[k] or {} hz[k][#hz[k] + 1] = v end end
local list = {}
for k in pairs(names) do list[#list + 1] = k end
table.sort(list)
for _, p in ipairs(list) do
    local a = alias[p]
    local parts = { "alias=" .. tostring(a) }
    for _, d in ipairs(ds) do parts[#parts + 1] = S(d[p]) end
    if a ~= nil then for _, d in ipairs(ds) do parts[#parts + 1] = S(d[a]) end end
    -- (and the things its moves put down, "by" it or not - the reviewer, 2026-10-18)
    local put = {}
    local function Puts(v, seen)
        if type(v) ~= "table" or seen[v] then return end
        seen[v] = true
        if type(v.puts) == "table" then for _, n in ipairs(v.puts) do put[n] = true end end
        for _, w in pairs(v) do Puts(w, seen) end
    end
    local seen = {}
    for _, d in ipairs(ds) do Puts(d[p], seen) end
    if a ~= nil then for _, d in ipairs(ds) do Puts(d[a], seen) end end
    local hk = {}
    for name, l in pairs(hz) do
        for _, h in ipairs(l) do
            local mine = put[name]
            for _, b in ipairs(h.by or {}) do if b == p or b == a then mine = true end end
            if mine then hk[#hk + 1] = name .. S(h) end
        end
    end
    table.sort(hk)
    parts[#parts + 1] = table.concat(hk, ";")
    parts[#parts + 1] = S(g._grid)
    print(p .. " " .. H(table.concat(parts, "|")))
end
local all = {}
for name, l in pairs(hz) do for _, h in ipairs(l) do all[#all + 1] = name .. S(h) end end
table.sort(all)
print("_haz " .. H(table.concat(all, ";") .. S(g._grid)))
