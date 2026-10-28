-- luajit tools/mod_coverage.lua <mod scripts folder> <merged scripts folder> [data file ...]
-- Every monster a mod makes (its prefab files with a combat component and a stategraph), every state of its stategraph
-- that harms - DoAttack, DoAreaAttack, GetAttacked, a projectile launched (LaunchProjectile / :Launch / SetProjectile in its
-- file), a thing spawned that strikes, or tagged "attack" - against our data: drawn if the animation it plays is one of a
-- move's of that monster (or of the one it's drawn as - _alias). Starts from the game's code, not from our data: a move the
-- data never had shows here (checks-start-from-game). 2026-10-20, the user: "still missing a huge number of moves".
-- Prints: per monster "<prefab> <sg>: <n> harmful, <k> drawn" and each "  MISSING <state> (<anim>) <why>"; totals at the end.
local MOD, MERGED = arg[1], arg[2]
local function Read(p) local f = io.open(p, "rb") if not f then return nil end local s = f:read("*a") f:close() return s end
-- (the data: every monster's moves' animations, and the things struck by)
local anims_of, alias, hazards = {}, {}, {}
for i = 3, #arg do
    local ok, d = pcall(dofile, arg[i])
    if ok and type(d) == "table" then
        for k, v in pairs(d) do
            if type(k) == "string" and k:sub(1, 1) ~= "_" and type(v) == "table" then
                anims_of[k] = anims_of[k] or {}
                for mv, e in pairs(v) do
                    if type(e) == "table" then
                        for _, a in ipairs(e.anims or {}) do anims_of[k][a] = true end
                        anims_of[k][(tostring(mv):match("^([^~]+)"))] = true
                    end
                end
            end
        end
        for k, v in pairs(d._alias or {}) do alias[k] = v end
        for k in pairs(d._hazards or {}) do hazards[k] = true end
    end
end
local HARM = { "DoAttack", "DoAreaAttack", "GetAttacked", "DoAOEAttack", "DoArcAttack", '"knockback"', ":Ignite", "AddColdness",
    "LaunchProjectile", ":Launch(", "SetProjectile" }
local p = io.popen('dir /b "' .. MOD:gsub("/", "\\") .. '\\prefabs\\*.lua" 2>nul')
local files = {}
for f in p:lines() do files[#files + 1] = f end
p:close()
table.sort(files)
local tot_h, tot_d, mons, gap_mons = 0, 0, 0, 0
for _, file in ipairs(files) do
    local text = Read(MOD .. "/prefabs/" .. file) or ""
    if text:find('AddComponent%("combat"%)') then
        local sgs, order = {}, {}
        for sg in text:gmatch('SetStateGraph%(%s*"([%w_]+)"') do if not sgs[sg] then sgs[sg] = true order[#order + 1] = sg end end
        local names = {}
        for n in ("\n" .. text):gmatch('[^%w_]Prefab%(%s*"[%w_/]-%f[%w_]([%w_]+)"') do names[#names + 1] = n end
        -- (one with no stategraph at all - its blows from its own code, timers: Tropical Experience's Maxwell, meteors
        -- and lightning each time he moves on; nothing above looks at it, said apart - its spawns that strike listed)
        if #order == 0 then
            local spawns, seen = {}, {}
            for sp in text:gmatch('SpawnPrefab%(%s*"([%w_]+)"') do
                if not seen[sp] then seen[sp] = true spawns[#spawns + 1] = sp .. (hazards[sp] and "" or "?") end
            end
            local strikes = text:find("GetAttacked", 1, true) or text:find("DoAttack", 1, true) or text:find("ms_sendlightningstrike", 1, true)
            if #spawns > 0 or strikes then
                for _, prefab in ipairs(#names > 0 and names or { file:gsub("%.lua$", "") }) do
                    print(string.format("%s NO STATEGRAPH: %s; spawns %s (? = not a thing our data knows)", prefab,
                        anims_of[prefab] and "has data" or "no data", table.concat(spawns, " ")))
                end
            end
        end
        for _, sgname in ipairs(order) do
            -- (its comments gone - an animation left commented out is none it plays: the sea Rook's atk_pst)
            local st = (Read(MERGED .. "/stategraphs/" .. sgname .. ".lua") or ""):gsub("%-%-%[%[.-%]%]", ""):gsub("%-%-[^\n]*", "")
            -- (its own helpers that harm, by name - a state calling DoLaser() strikes too)
            local harm = { unpack(HARM) }
            for _ = 1, 3 do
                for hname, hbody in ("\n" .. st):gmatch("\nlocal function ([%w_]+)%s*%((.-)\nend") do
                    local known = false
                    for _, h in ipairs(harm) do if h == hname then known = true end end
                    if not known then for _, h in ipairs(harm) do if hbody:find(h, 1, true) then harm[#harm + 1] = hname break end end end
                end
            end
            local states, pos, bodies_all = {}, 1, {}
            while true do
                local s, e, name = st:find('State%s*%{%s*name%s*=%s*"([%w_]+)"', pos)
                if s == nil then break end
                local nxt = st:find('State%s*%{%s*name%s*=', e + 1) or #st
                -- (its own braces, not on to the next state - the last state took the rest of the file, the Vampire Bat's
                -- landing "striking" by the walk states' code after it)
                local body = st:sub(s):match("^State%s*(%b{})") or st:sub(e + 1, nxt - 1)
                local why = nil
                for _, h in ipairs(harm) do if body:find(h, 1, true) then why = h break end end
                local tags = body:match('tags%s*=%s*(%b{})') or ""
                if why == nil and tags:find('"attack"', 1, true) then why = "tag attack" end
                -- (a thing it sets off that strikes - one our data knows as a hazard)
                for sp in body:gmatch('SpawnPrefab%(%s*"([%w_]+)"') do if hazards[sp] then why = why or ("spawns " .. sp) end end
                if why ~= nil then
                    local anim = body:match('PlayAnimation%(%s*"([%w_]+)"') or "?"
                    states[#states + 1] = { name = name, anim = anim, why = why, body = body }
                end
                bodies_all[name] = body
                pos = nxt
            end
            if #states > 0 then
                for _, prefab in ipairs(#names > 0 and names or { file:gsub("%.lua$", "") }) do
                    local have = anims_of[prefab] or (alias[prefab] and anims_of[alias[prefab]]) or {}
                    local drawn, miss = 0, {}
                    -- (part of a move drawn: gone into only from states already drawn - a loop and its end after the
                    -- wind-up our move starts with; worked to a standstill)
                    local covered = {}
                    -- (any animation it may play there - one state, the Pugalisk's head's bite or its tail's smack by a tag)
                    for _, s in ipairs(states) do
                        if have[s.anim] or have[s.name] then covered[s.name] = true end
                        for a in (s.body or ""):gmatch('PlayAnimation%(%s*"([%w_]+)"') do if have[a] then covered[s.name] = true end end
                    end
                    local changed = true
                    while changed do
                        changed = false
                        for _, s in ipairs(states) do
                            if not covered[s.name] then
                                local from_n, from_cov = 0, 0
                                for other, b in pairs(bodies_all) do
                                    if other ~= s.name and b:find('GoToState%(%s*"' .. s.name .. '"') then
                                        from_n = from_n + 1
                                        if covered[other] or have[(b:match('PlayAnimation%(%s*"([%w_]+)"') or "")] then from_cov = from_cov + 1 end
                                    end
                                end
                                if from_n > 0 and from_n == from_cov then covered[s.name] = true changed = true end
                            end
                        end
                    end
                    for _, s in ipairs(states) do
                        if covered[s.name] then drawn = drawn + 1 else miss[#miss + 1] = s end
                    end
                    mons = mons + 1
                    tot_h, tot_d = tot_h + #states, tot_d + drawn
                    if #miss > 0 then
                        gap_mons = gap_mons + 1
                        print(string.format("%s %s: %d harmful, %d drawn%s", prefab, sgname, #states, drawn, anims_of[prefab] == nil and " (NO DATA)" or ""))
                        for _, s in ipairs(miss) do print(string.format("  MISSING %s (%s) %s", s.name, s.anim, s.why)) end
                    end
                end
            end
        end
    end
end
print(string.format("TOTAL: %d monsters, %d with gaps; %d harmful states, %d drawn, %d missing", mons, gap_mons, tot_h, tot_d, tot_h - tot_d))
