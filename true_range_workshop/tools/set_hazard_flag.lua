-- luajit set_hazard_flag.lua <moves_sim.lua> <prefab> <flag>
-- Adds ", <flag> = true" to one thing's line in _hazards (a flag a new offline run found, without
-- taking its whole run in); checked: the result loads and has the flag.
local path, prefab, flag = arg[1], arg[2], arg[3]
local f = assert(io.open(path, "rb"))
local text = f:read("*a")
f:close()
local head = "\n        [\"" .. prefab .. "\"] = { "
local i = assert(text:find(head, 1, true), prefab .. ": not in _hazards")
local e = text:find("\n", i + 1, true)
local line = text:sub(i + 1, e - 1)
if line:find(", " .. flag .. " = true", 1, true) then print(prefab .. " has " .. flag .. " already") return end
local new = line:gsub("(, steps = )", ", " .. flag .. " = true%1", 1)
assert(new ~= line, "no steps in its line")
text = text:sub(1, i) .. new .. text:sub(e)
local data = assert(loadstring(text))()
assert(data._hazards[prefab][flag] == true, "flag not read back")
f = assert(io.open(path, "wb"))
f:write(text)
f:close()
print("set " .. flag .. " on " .. prefab)
