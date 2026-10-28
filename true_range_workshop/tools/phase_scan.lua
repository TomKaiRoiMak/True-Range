-- luajit phase_scan.lua [out.lua]: every health threshold each monster of the data changes what it does at - read
-- from its own code: its prefab file, stategraph and brain (Uncompromising Mode's over the game's) and the mod's
-- postinit files for them. A threshold is a healthtrigger's AddTrigger(x), or its health's percent compared with
-- x (GetPercent() < x, a "healthdelta" listener's newpercent < x, a local taken from GetPercent() then compared);
-- x a number, a local constant of the file (local PHASE2_HEALTH = .75) or TUNING's (the game's tuning.lua, the
-- mod's init_tuning.lua over it). The player: "how will you know all the phases were covered?" (2026-10-19,
-- VERIFY_PLAN 6.17, the reviewer: per boss, not one set for all)
-- Prints "<prefab> <value> <how> <file>:<line> <the line>", "UNRESOLVED <prefab> <name> <file>:<line>" for a
-- name it couldn't make a number of; with out.lua: writes { prefab = { values, highest first } }.
DEGREES, FRAMES = math.pi / 180, 1 / 30
local ROOT = [[D:\Work\Coding\dont starve\true_range_workshop\tests\work\]]
local UM = [[D:\Games Manager\Games\steamapps\workshop\content\322330\3193922031\]]
local DATA = [[D:\Work\Coding\dont starve\true_range\scripts\true_range\]]
local function Read(p) local f = io.open(p, "rb") if not f then return nil end local s = f:read("*a") f:close() return s end
local function Lines(t) local out = {} for l in (t .. "\n"):gmatch("([^\n]*)\n") do out[#out + 1] = l end return out end
-- (TUNING: NAME = number, the game's; the mod's TUNING.NAME = number / NAME = number over them)
local TUNING = {}
for _, p in ipairs({ ROOT .. "game_scripts\\tuning.lua", UM .. "init\\init_tuning.lua" }) do
    local t = Read(p) or ""
    for name, v in t:gmatch("([%u%d_]+)%s*=%s*(%-?[%d%.]+)%s*[,\n]") do TUNING[name] = tonumber(v) end
    -- (and a sum on two numbers - MUTATED_DEERCLOPS_FRENZY_HP = 1200 / 6000)
    for name, a, op, b in t:gmatch("([%u%d_]+)%s*=%s*([%d%.]+)%s*([%*/])%s*([%d%.]+)%s*[,\n]") do
        TUNING[name] = op == "/" and tonumber(a) / tonumber(b) or tonumber(a) * tonumber(b)
    end
end
-- (set by hand, each its reason: what no pattern can read)
local MANUAL = {
    -- (crabking.lua:1453-1460: on every 0.1 of its health lost, going down - a step each tenth)
    crabking = { .9, .8, .7, .6, .5, .4, .3, .2, .1 },
}
local function Value(s, locals)
    if s == nil then return nil end
    local n = tonumber(s)
    if n ~= nil then return n end
    local tn = s:match("^TUNING%.([%w_]+)$")
    if tn ~= nil then return TUNING[tn] end
    return locals[s]
end
-- (the monsters: the data's)
local prefabs = {}
for _, f in ipairs({ "moves_sim.lua", "moves_sim_um.lua" }) do
    local d = dofile(DATA .. f)
    for k, v in pairs(d) do if k:sub(1, 1) ~= "_" and type(v) == "table" then prefabs[k] = true end end
end
local list = {}
for p in pairs(prefabs) do list[#list + 1] = p end
table.sort(list)
local function PrefabFile(prefab)
    for _, dir in ipairs({ ROOT .. "game_scripts_um\\prefabs\\", ROOT .. "game_scripts\\prefabs\\" }) do
        local p = io.popen('findstr /m /c:"Prefab(\\"' .. prefab .. '\\"" "' .. dir .. '*.lua" 2>nul')
        -- (the file that makes it - Prefab("x", not SpawnPrefab("x": the Champion's second form read from the
        -- first's file, which spawns it, 2026-10-19)
        for l in p:lines() do
            if ("\n" .. (Read(l) or "")):find('[^%w_]Prefab%(%s*"' .. prefab:gsub("%W", "%%%0") .. '"') then p:close() return l end
        end
        p:close()
    end
end
local VAL = "([%w_%.]+)"
local out_levels = {}
for _, prefab in ipairs(list) do
    local files = {}
    local pf = PrefabFile(prefab)
    if pf ~= nil then
        files[#files + 1] = pf
        local t = Read(pf) or ""
        local name = pf:match("([%w_]+)%.lua$")
        local um = UM .. "postinit\\prefabs\\" .. name .. ".lua"
        if Read(um) then files[#files + 1] = um end
        for sg in t:gmatch('SetStateGraph%(%s*"([%w_]+)"') do
            for _, dir in ipairs({ "game_scripts_um", "game_scripts" }) do
                local p = ROOT .. dir .. "\\stategraphs\\" .. sg .. ".lua"
                if Read(p) then files[#files + 1] = p break end
            end
            local ums = UM .. "postinit\\stategraphs\\" .. sg .. ".lua"
            if Read(ums) then files[#files + 1] = ums end
        end
        for br in t:gmatch('require%(%s*"brains/([%w_]+)"') do
            for _, dir in ipairs({ "game_scripts_um", "game_scripts" }) do
                local p = ROOT .. dir .. "\\brains\\" .. br .. ".lua"
                if Read(p) then files[#files + 1] = p break end
            end
        end
    end
    local seen = {}
    for _, f in ipairs(files) do
        local text = Read(f) or ""
        local fname = f:match("[^\\]+$")
        -- (its own constants: local NAME = number)
        local locals = {}
        for n, v in text:gmatch("local%s+([%w_]+)%s*=%s*(%-?[%d%.]+)") do locals[n] = tonumber(v) end
        for n, v in text:gmatch("local%s+([%w_]+)%s*=%s*TUNING%.([%w_]+)") do locals[n] = TUNING[v] end
        -- (locals taken from its health's percent: compared later)
        local pctvars = { newpercent = true, oldpercent = true }
        for n in text:gmatch("local%s+([%w_]+)%s*=%s*[%w_%.:]*GetPercent%(%)") do pctvars[n] = true end
        -- (or from a healthdelta's data - mermking.lua:263 local new_health_percent = data.newpercent)
        for n in text:gmatch("local%s+([%w_]+)%s*=%s*[%w_%.]*newpercent") do pctvars[n] = true end
        -- (a table of phases each with its hp - { hp = .75, ... }, gone through with v.hp: daywalker, wagboss, the
        -- vault's guard, the Celestial Champion's last form)
        if text:find("v%.hp") then
            for v in text:gmatch("hp%s*=%s*([%d%.]+)") do
                local x = tonumber(v)
                if x ~= nil and x > 0 and x < 1 then
                    print(string.format("%s %.2f table %s (hp =)", prefab, x, fname))
                    local k = string.format("%.3f", x)
                    if not seen[k] then seen[k] = true out_levels[prefab] = out_levels[prefab] or {} table.insert(out_levels[prefab], x) end
                end
            end
        end
        -- (a function given the threshold - UM's minotaur Health_And_Combat_Check(inst, percent), GetPercent() <
        -- percent: each call's number)
        for fn, param in text:gmatch("function%s+([%w_]+)%s*%(%s*[%w_]+%s*,%s*([%w_]+)%s*%)") do
            if text:find("GetPercent%(%)%s*[<>]=?%s*" .. param) then
                for v in text:gmatch(fn .. "%(%s*[%w_]+%s*,%s*([%d%.]+)") do
                    local x = tonumber(v)
                    if x ~= nil and x > 0 and x < 1 then
                        print(string.format("%s %.2f call %s %s", prefab, x, fname, fn))
                        local k = string.format("%.3f", x)
                        if not seen[k] then seen[k] = true out_levels[prefab] = out_levels[prefab] or {} table.insert(out_levels[prefab], x) end
                    end
                end
            end
        end
        for ln, l in ipairs(Lines(text)) do
            if not l:match("^%s*%-%-") then
                local found = {}
                local x = l:match("AddTrigger%(%s*" .. VAL)
                if x then found[#found + 1] = { x, "trigger" } end
                for v in l:gmatch("GetPercent%(%)%s*[<>]=?%s*" .. VAL) do found[#found + 1] = { v, "percent" } end
                for var, v in l:gmatch("([%w_%.]+)%s*[<>]=?%s*" .. VAL) do
                    local last = var:match("([%w_]+)$")
                    if pctvars[last] then found[#found + 1] = { v, "percent" } end
                end
                for _, fo in ipairs(found) do
                    local v = Value(fo[1], locals)
                    if v == nil then
                        print(string.format("UNRESOLVED %s %s %s:%d", prefab, fo[1], fname, ln))
                    elseif v > 0 and v < 1 then
                        print(string.format("%s %.2f %s %s:%d %s", prefab, v, fo[2], fname, ln, l:gsub("^%s+", ""):sub(1, 100)))
                        local k = string.format("%.3f", v)
                        if not seen[k] then seen[k] = true out_levels[prefab] = out_levels[prefab] or {} table.insert(out_levels[prefab], v) end
                    end
                end
            end
        end
    end
end
for p, vs in pairs(MANUAL) do
    out_levels[p] = out_levels[p] or {}
    local have = {}
    for _, v in ipairs(out_levels[p]) do have[string.format("%.3f", v)] = true end
    for _, v in ipairs(vs) do if not have[string.format("%.3f", v)] then table.insert(out_levels[p], v) end end
end
if arg[1] then
    local o = { "-- written by tools/phase_scan.lua: each monster's health thresholds, highest first", "return {" }
    local names = {}
    for p in pairs(out_levels) do names[#names + 1] = p end
    table.sort(names)
    for _, p in ipairs(names) do
        table.sort(out_levels[p], function(a, b) return a > b end)
        local vs = {}
        for _, v in ipairs(out_levels[p]) do vs[#vs + 1] = string.format("%.3f", v) end
        o[#o + 1] = string.format("    %s = { %s },", p, table.concat(vs, ", "))
    end
    o[#o + 1] = "}"
    local fh = io.open(arg[1], "wb") fh:write(table.concat(o, "\n") .. "\n") fh:close()
end
