-- luajit set_after_mem.lua <moves_sim.lua> <game scripts>
-- Each entry with after_anim (the animation of the state that turns a boss into its later form)
-- gets after_mem - the sg.mem flag that state sets, as tools/sim_moves.lua AfterAnim finds it -
-- without running the offline runs again. The server reads that flag (true_range modmain): a boss
-- loaded from a save already turned never plays its turning animation.
-- Checked: the result loads, and has the same entries as before with only after_mem added.
local path, scripts = arg[1], arg[2]
local fh = assert(io.open(path, "rb"))
local text = fh:read("*a")
fh:close()

-- (anim -> the flag set true in the state that plays it, over every stategraph)
local flag_of = {}
local p = io.popen('dir /b "' .. scripts:gsub("/", "\\") .. '\\stategraphs\\*.lua"')
for name in p:lines() do
    local f = io.open(scripts .. "/stategraphs/" .. name, "rb")
    local st = f and f:read("*a") or ""
    if f then f:close() end
    for at, key in st:gmatch("()sg%.mem%.([%w_]+)%s*=%s*true") do
        local s0 = nil
        for q in st:sub(1, at):gmatch('()State%s*%{%s*name%s*=') do s0 = q end
        local anim = s0 and st:sub(s0, at):match('PlayAnimation%(%s*"([%w_]+)"') or nil
        if anim ~= nil and flag_of[anim] == nil then flag_of[anim] = key end
    end
end
p:close()

local n, missing = 0, 0
assert(not text:find("after_mem", 1, true), "after_mem already there")
local out = text:gsub('after_anim = "([%w_]+)"', function(anim)
    local key = flag_of[anim]
    if key == nil then missing = missing + 1 return nil end
    n = n + 1
    return string.format('after_anim = %q, after_mem = %q', anim, key)
end)

-- (the same data, but for after_mem)
local before = assert(loadstring(text))()
local after = assert(loadstring(out))()
for prefab, moves in pairs(before) do
    if prefab:sub(1, 1) ~= "_" then
        for name, e in pairs(moves) do
            local e2 = after[prefab][name]
            assert(e2 ~= nil, prefab .. " " .. name .. " gone")
            for k in pairs(e) do assert(e2[k] ~= nil, prefab .. " " .. name .. " lost " .. k) end
            for k in pairs(e2) do assert(e[k] ~= nil or k == "after_mem", prefab .. " " .. name .. " gained " .. k) end
            if e.after_anim ~= nil then print(prefab, name, e.after_anim, "->", e2.after_mem) end
        end
    end
end
local w = assert(io.open(path, "wb"))
w:write(out)
w:close()
print(string.format("%d after_mem added, %d without a flag found", n, missing))
