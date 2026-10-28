-- luajit tools/nothing_check.lua <mod root> <log> [log ...]
-- nomove_check's other half: not a monster's animation but what struck you - "you were struck by X" (true_range modmain,
-- the game's own word) - with nothing of ours that could have drawn it: no move for X (by _alias), no thing of X's
-- (_hazards), not one of modmain's DARTS. A projectile with no hazard entry is drawn by nothing as it flies.
-- Prints: NOTHING <what struck> <times> (<what set it off, if the log says>) - worst first.
local ROOT = arg[1]
local function Load(name)
    local ok, t = pcall(dofile, ROOT .. "/scripts/true_range/" .. name .. ".lua")
    return ok and type(t) == "table" and t or {}
end
local data = { Load("moves_sim"), Load("moves_sim_um"), Load("moves_hand"), Load("moves_hand_um") }
local has = {}
for _, d in ipairs(data) do
    for k, v in pairs(d) do if type(k) == "string" and k:sub(1, 1) ~= "_" and type(v) == "table" then has[k] = true end end
    for k in pairs(d._hazards or {}) do has[k] = true end
    for k, v in pairs(d._alias or {}) do has[k] = true end
end
-- (modmain's own: drawn by its dart code)
local mm = io.open(ROOT .. "/modmain.lua", "rb")
local src = mm and mm:read("*a") or "" if mm then mm:close() end
local darts = src:match("local DARTS = (%b{})") or ""
for k in darts:gmatch("([%w_]+) = {") do has[k] = true end
local n = {}
for i = 2, #arg do
    for line in io.lines(arg[i]) do
        local by = line:match("you were struck by ([%w_]+),")
        if by ~= nil and not has[by] then n[by] = (n[by] or 0) + 1 end
    end
end
local l = {}
for k, c in pairs(n) do l[#l + 1] = { k, c } end
table.sort(l, function(a, b) return a[2] > b[2] end)
for _, e in ipairs(l) do print(string.format("NOTHING %s %d", e[1], e[2])) end
print(string.format("NOTHINGS: %d kinds struck you with nothing of ours for them", #l))
