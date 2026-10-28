-- luajit unknown_moves.lua: attacks the game has that the data has nothing for. For every monster in the data
-- (game + Uncompromising Mode), its stategraph(s) read (UM's own over the game's): each state that harms
-- (DoAttack, DoAreaAttack, GetAttacked, a projectile launched, something spawned) and the animations it plays;
-- a state none of whose animations any move of that monster has - never drawn as a move. Things it spawns
-- not in _hazards are listed with it (drawn by no one either). VERIFY_PLAN 6.15 (the user: "how will you
-- find moves that aren't in the system?").
-- Prints "<prefab> <stategraph> <state>: plays a,b; harms by X; spawns p,q (no hazard)".
DEGREES, FRAMES = math.pi / 180, 1 / 30
local ROOT = [[D:\Work\Coding\dont starve\true_range_workshop\tests\work\]]
local g = dofile([[D:\Work\Coding\dont starve\true_range\scripts\true_range\moves_sim.lua]])
local u = dofile([[D:\Work\Coding\dont starve\true_range\scripts\true_range\moves_sim_um.lua]])
local function Read(p) local f = io.open(p, "rb") if not f then return nil end local s = f:read("*a") f:close() return s end
local hazards = {}
for _, d in ipairs({ g, u }) do for k in pairs(d._hazards or {}) do hazards[k] = true end end
local alias = {}
for _, d in ipairs({ g, u }) do for k, v in pairs(d._alias or {}) do alias[k] = v end end
-- (each monster's moves' animations - the hand-made ones too (moves_hand, merged at load): the Pengull's
-- slide, drawing its runningattack)
local h = dofile([[D:\Work\Coding\dont starve\true_range\scripts\true_range\moves_hand.lua]])
local anims = {}
for _, d in ipairs({ g, u, h }) do
    for prefab, mv in pairs(d) do
        if prefab:sub(1, 1) ~= "_" and type(mv) == "table" then
            anims[prefab] = anims[prefab] or {}
            for _, e in pairs(mv) do for _, a in ipairs(type(e) == "table" and e.anims or {}) do anims[prefab][a] = true end end
        end
    end
end
-- (which stategraph each prefab uses: its prefab file's SetStateGraph - UM's own prefab files first)
local function PrefabText(prefab)
    -- (the file that makes it - Prefab("x", ...) - before one that only names it in a list: the Hooded
    -- Widow's "spider_trapdoor", among what it eats, took its stategraph for the trapdoor spider's)
    local cands = {}
    for _, dir in ipairs({ "game_scripts_um", "game_scripts" }) do
        local p = io.popen('findstr /s /m /c:"\\"' .. prefab .. '\\"" "' .. ROOT .. dir .. '\\prefabs\\*.lua" 2>nul')
        for l in p:lines() do cands[#cands + 1] = l end
        p:close()
    end
    for _, f in ipairs(cands) do
        local t = Read(f)
        if t and t:find('%f[%w_]Prefab%(%s*"' .. prefab .. '"') then return t end
    end
    for _, f in ipairs(cands) do
        local t = Read(f)
        if t and t:find('"' .. prefab .. '"%s*,') then return t end
    end
end
local HARM = { "DoAttack", "DoAreaAttack", "GetAttacked", "DoAOEAttack", "LaunchProjectile", ":Launch(", "DoArcAttack" }
-- (a thing spawned matters only if its own code can harm - a splash, dirt, a key dropped can't; a monster of
-- the data is drawn as itself)
local harmful = {}
local function Harmful(p)
    if harmful[p] == nil then
        local t = anims[p] == nil and PrefabText(p) or nil
        harmful[p] = false
        for _, w in ipairs(HARM) do if t and t:find(w, 1, true) then harmful[p] = true break end end
    end
    return harmful[p]
end
-- (looked at and found never reached, or drawn otherwise - VERIFY_PLAN 6.15, agents 2026-10-18)
local SKIP = {
    ["mutatedbearger|attack"] = "goes straight to attack_combo1 (cancombo, prefabs/bearger.lua:809)",
    ["um_shadow_wes|attack"] = "no GoToState(\"attack\") anywhere in SGum_shadow_characters",
    ["um_shadow_wes|wortox_attack_jumpout"] = "reached by wortox_attack only (um_shadow_wortox, not in the data)",
    ["spat|launchprojectile"] = "its snot drawn as the spat_bomb hazard",
    ["moose|layegg2"] = "the egg shocks only who works it (mooseegg.lua:78) - not an attack",
    ["mothergoose|layegg2"] = "the egg shocks only who works it (mooseegg.lua:78) - not an attack",
    ["minotaur|death"] = "its chest spawner",
    ["alterguardian_phase1|death_lunar"] = "the next phase coming (a boss of its own)",
    ["alterguardian_phase1|death_lunar_loop"] = "the next phase coming (a boss of its own)",
    ["alterguardian_phase1_lunarrift|death_lunar"] = "the next phase coming (a boss of its own)",
    ["alterguardian_phase1_lunarrift|death_lunar_loop"] = "the next phase coming (a boss of its own)",
    ["eyeofterror|spawnminieyes_mouth_loop"] = "mini eyes launched - eyeofterror_mini, a monster of the data",
    ["twinofterror1|spawnminieyes_mouth_loop"] = "mini eyes launched - eyeofterror_mini, a monster of the data",
    ["twinofterror2|spawnminieyes_mouth_loop"] = "mini eyes launched - eyeofterror_mini, a monster of the data",
}
local skipped = 0
local seen_sg = {}
local list = {}
for prefab in pairs(anims) do list[#list + 1] = prefab end
table.sort(list)
for _, prefab in ipairs(list) do
    local text = PrefabText(alias[prefab] or prefab) or ""
    for sg in text:gmatch('SetStateGraph%(%s*"([%w_]+)"') do
        local key = prefab .. "|" .. sg
        if not seen_sg[key] then
            seen_sg[key] = true
            local st = Read(ROOT .. "game_scripts_um\\stategraphs\\" .. sg .. ".lua") or Read(ROOT .. "game_scripts\\stategraphs\\" .. sg .. ".lua") or ""
            -- (code commented out is not the game's: --[[ ... ]] blocks gone - the moose's old layegg_pst, the
            -- angry antlion's attack_pst, read as moves of theirs)
            st = st:gsub("%-%-%[(=*)%[.-%]%1%]", "")
            -- (its own stategraph only - one prefab file making several (Celestial phases, the leech in the
            -- Nightmare Werepig's) named others' too: one sharing no animation with its moves is someone else's)
            local shares = false
            for a in st:gmatch('PlayAnimation%(%s*"([%w_]+)"') do if anims[prefab][a] then shares = true break end end
            if not shares then st = "" end
            local pos = 1
            while true do
                local s, e, name = st:find('State%s*%{%s*name%s*=%s*"([%w_]+)"', pos)
                if s == nil then break end
                local nxt = st:find('State%s*%{%s*name%s*=', e + 1) or #st
                -- (the last state's body ends with the states' list - not running on into what follows it:
                -- CommonStates.AddCombatStates' attack, read as the Mother Goose's layegg_pst)
                local close = st:find("\n}", e + 1, true)
                if close ~= nil and close < nxt then nxt = close end
                -- (its own braces only: to the brace closing its State{ - not on into the common attack
                -- timeline after it, its DoAttack taken for the state's)
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
                local spawns = {}
                for p in body:gmatch('SpawnPrefab%(%s*"([%w_]+)"') do if not hazards[p] and not p:find("fx") and Harmful(p) then spawns[#spawns + 1] = p end end
                if SKIP[prefab .. "|" .. name] ~= nil and (#by > 0 or #spawns > 0) then
                    skipped = skipped + 1
                elseif #by > 0 or #spawns > 0 then
                    local plays, known = {}, false
                    for a in body:gmatch('PlayAnimation%(%s*"([%w_]+)"') do plays[#plays + 1] = a if anims[prefab][a] then known = true end end
                    for a in body:gmatch('PushAnimation%(%s*"([%w_]+)"') do plays[#plays + 1] = a if anims[prefab][a] then known = true end end
                    if not known and #plays > 0 then
                        print(string.format("%s %s %s: plays %s; harms by %s%s", prefab, sg, name, table.concat(plays, ","),
                            #by > 0 and table.concat(by, ",") or "-", #spawns > 0 and ("; spawns " .. table.concat(spawns, ",") .. " (no hazard)") or ""))
                    end
                end
                pos = nxt
            end
        end
    end
end
print(string.format("(%d looked at before and skipped - SKIP)", skipped))

-- ===== (2) harm a prefab's own code starts on a timer, a task or an event =====
do
-- luajit unknown_prefab_timers.lua [data dir]: harm a prefab's own code starts on a timer, a task or an
-- event (DoPeriodicTask / DoTaskInTime / a "timerdone" handler / ListenForEvent) - no stategraph state of
-- its - for prefabs neither in _hazards nor a monster of the data (Creeping Fear's spike waves, the Fused
-- Shadeling's bombs). To go at the end of tools/unknown_moves.lua (it has hazards, anims, Read, ROOT).
-- Prints "<file>: <prefab,...> - <fn> (by <how>) harms by X".
local ROOT = [[D:\Work\Coding\dont starve\true_range_workshop\tests\work\]]
local DATA = [[D:\Work\Coding\dont starve\true_range\scripts\true_range\]]
local g = dofile(DATA .. "moves_sim.lua")
local u = dofile(DATA .. "moves_sim_um.lua")
local function Read(p) local f = io.open(p, "rb") if not f then return nil end local s = f:read("*a") f:close() return s end
local known = {}
for _, d in ipairs({ g, u }) do
    for k in pairs(d._hazards or {}) do known[k] = true end
    for k in pairs(d) do if k:sub(1, 1) ~= "_" then known[k] = true end end
end
local HARM = { "GetAttacked", "DoAttack(", "DoAreaAttack", "DoAOEAttack", "DoArcAttack", "DoThornDamage" }
-- (each file once - Uncompromising Mode's own over the game's)
local files, order = {}, {}
for _, dir in ipairs({ "game_scripts_um", "game_scripts" }) do
    local p = io.popen('dir /b "' .. ROOT .. dir .. '\\prefabs\\*.lua" 2>nul')
    for name in p:lines() do
        if files[name] == nil then files[name] = ROOT .. dir .. "\\prefabs\\" .. name order[#order + 1] = name end
    end
    p:close()
end
table.sort(order)
local function Harms(body)
    local by = {}
    for _, h in ipairs(HARM) do if body:find(h, 1, true) then by[#by + 1] = h end end
    return by
end
for _, name in ipairs(order) do
    local t = Read(files[name]) or ""
    -- (its local functions, by name: from "local function f(" / "function f(" to the next one)
    local fns, starts = {}, {}
    for s, fname in t:gmatch("()local%s+function%s+([%w_]+)%s*%(") do starts[#starts + 1] = { s, fname } end
    for s, fname in t:gmatch("\n()function%s+([%w_]+)%s*%(") do starts[#starts + 1] = { s, fname } end
    table.sort(starts, function(a, b) return a[1] < b[1] end)
    for i, st in ipairs(starts) do fns[st[2]] = t:sub(st[1], (starts[i + 1] and starts[i + 1][1] or #t + 1) - 1) end
    -- (harms itself, or through those it calls - three deep: a timer's end, the explosion, its blow)
    local HarmsFn
    HarmsFn = function(fname, depth, seen)
        local body = fns[fname]
        if body == nil or seen[fname] then return {} end
        seen[fname] = true
        local by = Harms(body)
        if #by == 0 and depth > 0 then
            for callee in body:gmatch("([%w_]+)%s*%(") do
                if callee ~= fname and fns[callee] ~= nil then
                    local b2 = HarmsFn(callee, depth - 1, seen)
                    if #b2 > 0 then by = b2 by[#by + 1] = "via " .. callee break end
                end
            end
        end
        return by
    end
    -- (started how: a task, a timer's end, an event)
    local found = {}
    for how, fname in t:gmatch("(DoPeriodicTask)%s*%(%s*[%w_%.%*%s%+%-/]-,%s*([%w_]+)") do found[#found + 1] = { how, fname } end
    for how, fname in t:gmatch("(DoTaskInTime)%s*%(%s*[%w_%.%*%s%+%-/%(%)]-,%s*([%w_]+)") do found[#found + 1] = { how, fname } end
    for ev, fname in t:gmatch('ListenForEvent%(%s*"([%w_]+)"%s*,%s*([%w_]+)') do found[#found + 1] = { "event " .. ev, fname } end
    local out, said = {}, {}
    for _, f in ipairs(found) do
        local by = HarmsFn(f[2], 3, {})
        if #by > 0 and not said[f[2]] then
            said[f[2]] = true
            out[#out + 1] = string.format("%s (by %s) harms by %s", f[2], f[1], table.concat(by, ","))
        end
    end
    if #out > 0 then
        local unknown = {}
        local said_p = {}
        for p in t:gmatch('%f[%w_]Prefab%(%s*"([%w_]+)"') do if not known[p] and not said_p[p] then said_p[p] = true unknown[#unknown + 1] = p end end
        -- (a file making makers - MakeSinkhole("x", ...) - its prefabs named by the first argument of each)
        -- (a file making one the data has - a laser beside its scorch and trail: its harm taken as that one's)
        local any_known = false
        for p in t:gmatch('%f[%w_]Prefab%(%s*"([%w_]+)"') do if known[p] then any_known = true end end
        -- (what a player wields, wears or is given - ammunition, a staff, a debuff on what you hit: not a monster's)
        local players = name:find("slingshot") or name:find("wixie") or name:find("abigail") or name:find("debuff")
            or name:find("buff") or name:find("_hat") or name:find("staff") or name:find("armor") or name:find("beegun") or name:find("beefalo")
        if #unknown > 0 and not any_known and not players then
            print(string.format("%s: %s - %s", name, table.concat(unknown, ","), table.concat(out, "; ")))
        end
    end
end

end
