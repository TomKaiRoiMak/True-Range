-- luajit merge_hazard.lua <moves_sim.lua> <part.lua> prefab[,prefab...]
-- Puts things' lines (_hazards: ["prefab"] = { ... }) from a sim_moves.lua run of a few bosses into
-- the whole file the mod reads - replaced where there, added where not; nothing else touched.
-- Checked: the result loads, and has each of them.
local dst_path, src_path, list = arg[1], arg[2], arg[3]
local function Read(p) local f = assert(io.open(p, "rb")) local t = f:read("*a") f:close() return t end
local dst, src = Read(dst_path), Read(src_path)
local function Line(text, prefab)
    local head = "\n        [\"" .. prefab .. "\"] = { "
    local i = text:find(head, 1, true)
    if i == nil then return nil end
    local e = text:find("\n", i + 1, true)
    return i + 1, e - 1
end
for prefab in list:gmatch("[^,]+") do
    local si, sj = Line(src, prefab)
    assert(si ~= nil, prefab .. ": not in " .. src_path)
    local line = src:sub(si, sj)
    local di, dj = Line(dst, prefab)
    if di ~= nil then
        dst = dst:sub(1, di - 1) .. line .. dst:sub(dj + 1)
    else
        local h = dst:find("\n    _hazards = {\n", 1, true)
        assert(h ~= nil, "no _hazards in " .. dst_path)
        local at = h + #"\n    _hazards = {\n"
        dst = dst:sub(1, at - 1) .. line .. "\n" .. dst:sub(at)
    end
end
local data = assert(loadstring(dst))()
for prefab in list:gmatch("[^,]+") do assert(data._hazards[prefab] ~= nil, prefab .. " not read back") end
local f = assert(io.open(dst_path, "wb"))
f:write(dst)
f:close()
print("merged things " .. list .. " into " .. dst_path)
