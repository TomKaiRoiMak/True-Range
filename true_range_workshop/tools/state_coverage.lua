-- luajit state_coverage.lua <bench run folder> [boss,...]: for each monster the data has, each state of its own
-- stategraph that harms (DoAttack, DoAreaAttack, GetAttacked, a projectile launched, a harmful thing spawned - as
-- tools/unknown_moves.lua reads them) against how often the testbench saw it go into that state - and in which
-- of its health steps (tr_testbench "hurt" lines) and forms (tr_trace " forms="). VERIFY_PLAN 6.17 B: "done" is
-- every harmful state gone into at least 3 times, or a reason written.
-- Prints, per boss: "<boss> <state> <times> [steps seen] [forms]", MISSING for under 3; a total at the end.
DEGREES, FRAMES = math.pi / 180, 1 / 30
local RUN = arg[1]
local ONLY = {}
for b in (arg[2] or ""):gmatch("[^,]+") do ONLY[b] = true end
local ROOT = [[D:\Work\Coding\dont starve\true_range_workshop\tests\work\]]
local DATA = [[D:\Work\Coding\dont starve\true_range\scripts\true_range\]]
local NEED = 3
local function Read(p) local f = io.open(p, "rb") if not f then return nil end local s = f:read("*a") f:close() return s end
-- (the monsters: the data's, with their alias - a fire hound drawn as a hound)
local prefabs, alias = {}, {}
for _, f in ipairs({ "moves_sim.lua", "moves_sim_um.lua" }) do
    local d = dofile(DATA .. f)
    for k, v in pairs(d) do if k:sub(1, 1) ~= "_" and type(v) == "table" then prefabs[k] = true end end
    for k, v in pairs(d._alias or {}) do alias[k] = v prefabs[k] = true end
end
local function PrefabText(prefab)
    for _, dir in ipairs({ "game_scripts_um", "game_scripts" }) do
        -- (the file that makes it - Prefab("x", not SpawnPrefab("x": the Champion's second form found in the
        -- first's file, which spawns it, 2026-10-19)
        local p = io.popen('findstr /m /c:"Prefab(\\"' .. prefab .. '\\"" "' .. ROOT .. dir .. '\\prefabs\\*.lua" 2>nul')
        for l in p:lines() do
            local t = Read(l) or ""
            if ("\n" .. t):find('[^%w_]Prefab%(%s*"' .. prefab:gsub("%W", "%%%0") .. '"') then p:close() return t end
        end
        p:close()
    end
end
local HARM = { "DoAttack", "DoAreaAttack", "GetAttacked", "DoAOEAttack", "LaunchProjectile", ":Launch(", "DoArcAttack" }
-- (its harmful states: name -> how)
local function Harmful(prefab)
    local text = PrefabText(prefab) or ""
    local out = {}
    for sg in text:gmatch('SetStateGraph%(%s*"([%w_]+)"') do
        local st = Read(ROOT .. "game_scripts_um\\stategraphs\\" .. sg .. ".lua") or Read(ROOT .. "game_scripts\\stategraphs\\" .. sg .. ".lua") or ""
        st = st:gsub("%-%-%[(=*)%[.-%]%1%]", "")
        local pos = 1
        while true do
            local s, e, name = st:find('State%s*%{%s*name%s*=%s*"([%w_]+)"', pos)
            if s == nil then break end
            local nxt = st:find('State%s*%{%s*name%s*=', e + 1) or #st
            local close = st:find("\n}", e + 1, true)
            if close ~= nil and close < nxt then nxt = close end
            local open = st:find("{", s, true)
            local depth, q = 0, open
            while q ~= nil and q <= #st do
                local c = st:sub(q, q)
                if c == "{" then depth = depth + 1 elseif c == "}" then depth = depth - 1 if depth == 0 then break end end
                q = q + 1
            end
            local body = st:sub(e + 1, (q or nxt) - 1)
            local by = {}
            for _, h in ipairs(HARM) do if body:find(h, 1, true) then by[#by + 1] = h end end
            if #by > 0 then out[name] = table.concat(by, ",") end
            pos = nxt
        end
    end
    return out
end
-- (what the bench saw: per boss, each state gone into - its step of health, its form)
local seen = {}     -- boss -> state -> { n, steps = {}, forms = {} }
-- (gone into by the testbench (its FORCE, "[tr_bench] t boss forced state="): where and when it strikes as the game's,
-- its aim not - said apart)
local forced = {}   -- boss -> state -> times
local fought = {}   -- boss -> true once it began a scene
local hurt_seen = {}
local p = io.popen('dir /b "' .. RUN .. '\\share*.txt" 2>nul')
for name in p:lines() do
    local step, boss_now, last = 0, nil, {}
    for l in io.lines(RUN .. "\\" .. name) do
        local b = l:match("%[tr_bench%] [%d%.]+ ([%w_]+) spawned")
        if b then boss_now, step = b, 0 end
        local hb = l:match("%[tr_bench%] [%d%.]+ ([%w_]+) hurt")
        if hb then step = step + 1 hurt_seen[hb] = true end
        local fb, fs = l:match("%[tr_bench%] [%d%.]+ ([%w_]+) forced state=([%w_]+)")
        if fb then forced[fb] = forced[fb] or {} forced[fb][fs] = (forced[fb][fs] or 0) + 1 end
        local sb = l:match("%[tr_bench%] [%d%.]+ ([%w_]+) start n=")
        if sb then fought[sb] = true end
        local nb, np = l:match("%[tr_bench%] [%d%.]+ ([%w_]+) next phase %S+ %-> ([%w_]+)")
        if np then fought[np] = true end
        local tb, st = l:match("%[tr_trace%] [%d%.]+ ([%w_]+) after state=([%w_]+)")
        if tb and st ~= last[tb] then
            last[tb] = st
            local forms = l:match(" forms=(%S+)") or "-"
            seen[tb] = seen[tb] or {}
            local e = seen[tb][st] or { n = 0, steps = {}, forms = {} }
            seen[tb][st] = e
            e.n = e.n + 1
            e.steps[step] = true
            e.forms[forms] = true
        end
    end
end
p:close()
local list = {}
for b in pairs(prefabs) do if next(ONLY) == nil or ONLY[b] then list[#list + 1] = b end end
table.sort(list)
local total, missing, never = 0, 0, {}
for _, b in ipairs(list) do
    local harm = Harmful(alias[b] or b)
    local names = {}
    for s in pairs(harm) do names[#names + 1] = s end
    table.sort(names)
    if #names > 0 then
        if seen[b] == nil then never[#never + 1] = b end
        for _, s in ipairs(names) do
            total = total + 1
            local e = (seen[b] or {})[s]
            local n = e and e.n or 0
            local steps, forms = {}, {}
            for k in pairs(e and e.steps or {}) do steps[#steps + 1] = k end
            for k in pairs(e and e.forms or {}) do forms[#forms + 1] = k end
            table.sort(steps)
            table.sort(forms)
            if n < NEED then missing = missing + 1 end
            local fn = forced[b] and forced[b][s] or 0
            print(string.format("%-8s %s %s %d steps[%s] forms[%s]%s%s", n < NEED and "MISSING" or "ok", b, s, n, table.concat(steps, ","),
                table.concat(forms, ","), hurt_seen[b] and "" or " (never hurt)", fn > 0 and string.format(" (forced %d - aim not the game's way in)", fn) or ""))
        end
    end
end
print(string.format("TOTAL %d harmful states, %d under %d times ; bosses with no trace at all: %s", total, missing, NEED, table.concat(never, " ")))
