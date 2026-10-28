-- luajit tools/mod_diff.lua <with the mod.lua> <without it.lua> <out.lua> [<the mod's spec, tools/sim_mods/<mod>.lua>]
-- A mod's moves (tools/sim_moves.lua SIM_MOD) against the same bosses run without it, by this same
-- sim: only what came out otherwise kept, move by move - a move that differs, a new one; a thing
-- set off that differs or is new. What the mod didn't change stays the game's own data
-- (true_range/moves_sim, checked against every kept log), not this run's - true_range/moddata lays
-- these over it move by move. A move gone with the mod on is no word on the game's: one that
-- wouldn't run in the mod's world (wagboss_robot's), kept as the game's.
-- A boss the spec lists (its moves set out by hand - Deerclops' mutations, named anew): all of it,
-- in place of the game's (_replace).
-- [<the game's data as the mod has it, true_range/scripts/true_range/moves_sim.lua>]: a move the same both
-- ways but missing from that (built before the sim found it - a full mosquito's burst): kept too, else
-- with the mod on it's drawn by neither
local with, without, out = dofile(arg[1]), dofile(arg[2]), arg[3]
local spec = arg[4] and arg[4] ~= "" and dofile(arg[4]) or {}
local installed = arg[5] and dofile(arg[5]) or nil
local function Installed(prefab, mv)
    if installed == nil then return true end
    local e = installed[prefab] or installed[(installed._alias or {})[prefab] or ""]
    return e ~= nil and e[mv] ~= nil
end

local function Same(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then
        if type(a) == "number" then return math.abs(a - b) < 1e-9 end
        return a == b
    end
    for k, v in pairs(a) do if not Same(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

local function Sorted(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys, function(x, y)
        if type(x) == type(y) then return x < y end
        return type(x) == "number"
    end)
    return keys
end

local function Dump(v)
    if type(v) == "table" then
        local parts = {}
        local arr = #v
        for _, k in ipairs(Sorted(v)) do
            local key
            if type(k) == "number" and k >= 1 and k <= arr and k % 1 == 0 then key = ""
            elseif type(k) == "string" and k:match("^[%a_][%w_]*$") then key = k .. " = "
            else key = "[" .. (type(k) == "string" and string.format("%q", k) or string.format("%.17g", k)) .. "] = " end
            parts[#parts + 1] = key .. Dump(v[k])
        end
        return "{ " .. table.concat(parts, ", ") .. " }"
    elseif type(v) == "string" then
        return string.format("%q", v)
    elseif type(v) == "number" then
        return string.format("%.17g", v)
    end
    return tostring(v)
end

local whole, skip, drop, alias_of = {}, {}, {}, {}
for _, d in ipairs(spec) do
    -- (d.alias_of: drawn as another, its own run's moves left out - Tropical Experience's mammoth, the game's koalefant
    -- reskinned (its bank, body, damage): as it, Uncompromising Mode's changes to its stategraph theirs too)
    if d.prefab ~= nil and d.alias_of ~= nil then
        alias_of[d.prefab] = d.alias_of
        skip[d.prefab] = true
    -- (all of it: one set out by hand in place of the game's - not one only added to, nor a thing of its own)
    elseif d.prefab ~= nil and d.add == nil then
        if d.keep_game then skip[d.prefab] = true else whole[d.prefab] = true end
    end
    -- (d.drop: moves left out of the data whatever the runs made - the Hooded Widow's "fall", the same animations
    -- as its canopyland inside whose shape it lies: no_auto never reached the scan that adds it, 2026-10-19)
    if d.prefab ~= nil and d.drop ~= nil then
        drop[d.prefab] = drop[d.prefab] or {}
        for _, mv in ipairs(d.drop) do drop[d.prefab][mv] = true end
    end
end

local lines = { "-- made by tools/mod_diff.lua: the mod's moves where they differ from the game's", "return {" }
local kept, moves_kept, hz_kept, replaced = {}, 0, 0, {}
for _, k in ipairs(Sorted(with)) do
    local v = with[k]
    if k == "_hazards" or k == "_alias" then
        local base = without[k] or {}
        lines[#lines + 1] = string.format("    %s = {", k)
        for _, hk in ipairs(Sorted(v)) do
            if not Same(v[hk], base[hk]) or (k == "_hazards" and installed ~= nil and (installed._hazards or {})[hk] == nil) then
                lines[#lines + 1] = string.format("        [%q] = %s,", hk, Dump(v[hk]))
                hz_kept = hz_kept + 1
            end
        end
        if k == "_alias" then
            for _, p in ipairs(Sorted(alias_of)) do lines[#lines + 1] = string.format("        [%q] = %q,", p, alias_of[p]) end
        end
        lines[#lines + 1] = "    },"
    elseif k == "_grid" then
        lines[#lines + 1] = "    _grid = " .. Dump(v) .. ","
    elseif type(k) == "string" and k:sub(1, 1) ~= "_" and type(v) == "table" and not skip[k] then
        for mv in pairs(drop[k] or {}) do v[mv] = nil end
        if whole[k] then
            replaced[#replaced + 1] = k
            kept[#kept + 1] = k .. " (all)"
            lines[#lines + 1] = string.format("    [%q] = %s,", k, Dump(v))
        else
            local base = without[k] or {}
            local part = {}
            for _, mv in ipairs(Sorted(v)) do
                if not Same(v[mv], base[mv]) or not Installed(k, mv) then part[mv] = v[mv] moves_kept = moves_kept + 1 end
            end
            if next(part) ~= nil then
                local names = {}
                for mv in pairs(part) do names[#names + 1] = mv end
                table.sort(names)
                kept[#kept + 1] = k .. " (" .. table.concat(names, ", ") .. ")"
                lines[#lines + 1] = string.format("    [%q] = %s,", k, Dump(part))
            end
        end
    end
end
local rq = {}
for _, k in ipairs(replaced) do rq[#rq + 1] = string.format("[%q] = true", k) end
lines[#lines + 1] = "    _replace = { " .. table.concat(rq, ", ") .. " },"
lines[#lines + 1] = "}"
local fh = assert(io.open(out, "wb"))
fh:write(table.concat(lines, "\n"), "\n")
fh:close()
print(string.format("kept %d monsters, %d moves; %d things set off", #kept, moves_kept, hz_kept))
for _, k in ipairs(kept) do print("  " .. k) end
