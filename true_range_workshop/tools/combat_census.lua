-- luajit tools/combat_census.lua <mod root> <prefab dir> [prefab dir ...]
-- Every prefab the game (and a mod) makes that fights - its own maker gives it a combat component and a stategraph
-- (or a function of the file it calls does) - set against our data: those with nothing (no moves, no _alias, no thing of
-- theirs) are never drawn, never benched (the testbench's -All list is our data's), never traced - no other check can
-- see them. The other side of tools/nomove_check.lua, which sees only what was traced, 2026-10-20.
-- Prints: NODATA <prefab> <stategraph> <file>, one each.
local ROOT = arg[1]
local function Load(name)
    local ok, t = pcall(dofile, ROOT .. "/scripts/true_range/" .. name .. ".lua")
    return ok and type(t) == "table" and t or {}
end
local has = {}
for _, n in ipairs({ "moves_sim", "moves_sim_um", "moves_hand", "moves_hand_um" }) do
    local d = Load(n)
    for k, v in pairs(d) do if type(k) == "string" and k:sub(1, 1) ~= "_" then has[k] = true end end
    for k in pairs(d._hazards or {}) do has[k] = true end
    for k in pairs(d._alias or {}) do has[k] = true end
end
-- (each function of a file, by name -> its text; split where a line starts a function at its left edge)
local function Functions(s)
    local fns, cur, buf = {}, nil, {}
    for line in (s .. "\n"):gmatch("([^\n]*)\n") do
        local name = line:match("^local function ([%w_]+)") or line:match("^function ([%w_]+)")
        if name ~= nil or line:match("^return") then
            if cur then fns[cur] = table.concat(buf, "\n") end
            cur, buf = name, {}
        end
        if cur then buf[#buf + 1] = line end
    end
    if cur then fns[cur] = table.concat(buf, "\n") end
    return fns
end
local function Fights(fns, text, depth, seen)
    local combat = text:find('AddComponent%("combat"%)') ~= nil
    local sg = text:match('SetStateGraph%(%s*"([%w_]+)"')
    if combat and sg then return sg end
    if depth <= 0 then return nil end
    -- (or the file's own functions it calls - a maker shared by several: fnmain(...))
    for call in text:gmatch("([%w_]+)%s*%(") do
        if fns[call] ~= nil and not seen[call] then
            seen[call] = true
            local inner = Fights(fns, fns[call], depth - 1, seen)
            if inner then return inner end
        end
    end
    return nil
end
local found, n = {}, 0
for i = 2, #arg do
    local p = io.popen('dir /b /s "' .. arg[i]:gsub("/", "\\") .. '\\*.lua" 2>nul')
    for file in p:lines() do
        local f = io.open(file, "rb")
        local s = f and f:read("*a") or ""
        if f then f:close() end
        if s:find('AddComponent%("combat"%)') and s:find("SetStateGraph") then
            local fns = Functions(s)
            -- (Prefab("name", maker, ...) - the maker a name, or a function written in place: its text up to the call's end)
            for name, rest in s:gmatch('Prefab%(%s*"[%w_/]-%f[%w_]([%w_]+)"%s*,%s*([^\n]+)') do
                local maker = rest:match("^([%w_]+)")
                local text = maker ~= nil and maker ~= "function" and fns[maker] or rest
                local sg = text ~= nil and Fights(fns, text, 3, {}) or nil
                if sg and not has[name] and not found[name] then
                    found[name] = true
                    n = n + 1
                    print(string.format("NODATA %s %s %s", name, sg, file:match("[^\\/]+$")))
                end
            end
        end
    end
    p:close()
end
print(string.format("NODATAS: %d fighting prefabs with nothing of ours", n))
