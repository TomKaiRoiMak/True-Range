-- luajit merge_sim.lua <moves_sim.lua> <part.lua> prefab[,prefab...]
-- Puts the named bosses' moves from a sim_moves.lua run of only them (-only=...) into the whole
-- file the mod reads - each boss's block ("    [\"prefab\"] = {" up to the next line at that depth)
-- swapped for the new one; nothing else touched. Checked: the result loads, and has every boss
-- it had.
local dst_path, src_path, list = arg[1], arg[2], arg[3]
local function Read(p) local f = assert(io.open(p, "rb")) local t = f:read("*a") f:close() return t end
local dst, src = Read(dst_path), Read(src_path)
-- (a boss's block: from its line to just before the next line four spaces in - another boss,
-- _hazards, or the file's end)
local function Block(text, prefab)
    local head = "\n    [\"" .. prefab .. "\"] = {"
    local i = text:find(head, 1, true)
    if i == nil then return nil end
    local j = i + #head
    while true do
        local n = text:find("\n    ", j, true)
        if n == nil then return nil end
        local c = text:sub(n + 5, n + 5)
        if c == "[" or c == "_" or c == "}" then return i + 1, n end
        j = n + 1
    end
end
local before = assert(loadstring(dst))()
for prefab in list:gmatch("[^,]+") do
    local si, sj = Block(src, prefab)
    local di, dj = Block(dst, prefab)
    assert(si ~= nil, prefab .. ": not in " .. src_path)
    assert(di ~= nil, prefab .. ": not in " .. dst_path)
    dst = dst:sub(1, di - 1) .. src:sub(si, sj) .. dst:sub(dj + 1)
end
local after = assert(loadstring(dst))()
for k in pairs(before) do assert(after[k] ~= nil, "lost " .. tostring(k)) end
local f = assert(io.open(dst_path, "wb"))
f:write(dst)
f:close()
print("merged " .. list .. " into " .. dst_path)
