-- luajit tools/modenv_check.lua <modmain.lua>: names a mod's main file reads straight that the game's mod environment hasn't
-- got (mods.lua CreateEnvironment: pairs, ipairs, print, math, table, type, string, tostring, require, Class, TUNING ... GLOBAL) -
-- the Lua builtins left out of it (tonumber, setmetatable, pcall, os ...): read bare they're nil, the mod failing as it loads.
-- tests/strict_check.lua runs the scripts, not modmain in its environment: a bare setmetatable put in modmain went to the game,
-- every bench share stopping at once ("attempt to call global 'setmetatable'"), 2026-10-21. Prints each, and exits 1 if any.
local MISSING = { "tonumber", "setmetatable", "getmetatable", "rawget", "rawset", "rawequal", "rawlen", "pcall", "xpcall",
    "select", "next", "unpack", "error", "assert", "loadstring", "load", "dofile", "loadfile", "setfenv", "getfenv",
    "collectgarbage", "os", "io", "debug", "coroutine", "package", "_G", "_VERSION", "newproxy" }
local f = assert(io.open(arg[1], "rb"))
local src = f:read("*a")
f:close()
-- (code only: comments and strings out)
src = src:gsub("%-%-%[(=*)%[.-%]%1%]", ""):gsub("%-%-[^\n]*", "")
src = src:gsub("%[(=*)%[.-%]%1%]", "\"\""):gsub('"[^"\n]*"', '""'):gsub("'[^'\n]*'", "''")
local bad = 0
local line_of = {}
do
    local n = 1
    for i = 1, #src do
        line_of[i] = n
        if src:sub(i, i) == "\n" then n = n + 1 end
    end
end
for _, name in ipairs(MISSING) do
    -- (declared as a local of its own anywhere - local tonumber = GLOBAL.tonumber: taken as that)
    local declared = src:find("local%s+" .. name .. "%f[^%w_]") ~= nil or src:find("local%s+[%w_,%s]-,%s*" .. name .. "%f[^%w_]") ~= nil
    if not declared then
        local pos = 1
        while true do
            local s, e = src:find("%f[%w_]" .. name .. "%f[^%w_]", pos)
            if s == nil then break end
            local before = src:sub(math.max(1, s - 1), s - 1)
            local after = src:match("^%s*(.)", e + 1)
            -- (not a field - x.tonumber, x:select - nor a table key - { select = ... })
            if before ~= "." and before ~= ":" and after ~= "=" then
                print(string.format("%s:%d: %s read bare - not in the mod's environment (GLOBAL.%s)", arg[1], line_of[s] or 0, name, name))
                bad = bad + 1
            end
            pos = e + 1
        end
    end
end
if bad > 0 then os.exit(1) end
print("modenv: ok")
