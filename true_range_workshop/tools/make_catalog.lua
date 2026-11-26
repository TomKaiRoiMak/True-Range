-- luajit tools/make_catalog.lua <true_range dir> <out dir> <names.tsv>
-- Every monster and every move in the data, as markdown pages to find and fix them by (docs/catalog): run by
-- tools\make_catalog.ps1, which gathers the in-game names first. Made from the data files themselves - never edited by hand.
local root, out, names_file = arg[1], arg[2], arg[3]
local dir = root .. "/scripts/true_range/"

-- (in-game names: PREFAB -> name)
local names = {}
for l in io.lines(names_file) do
    local k, v = l:match("^([^\t]+)\t(.+)$")
    if k ~= nil and names[k] == nil then names[k] = v end
end
local function Name(p) return names[p:upper()] or "" end

-- (where each prefab / move / thing starts in a data file: its line)
local function Lines(file)
    local at, cur, inhaz = { p = {}, m = {}, h = {} }, nil, false
    local n = 0
    for l in io.lines(dir .. file .. ".lua") do
        n = n + 1
        local p = l:match("^    ([%w_]+) = {") or l:match('^    %["([^"]+)"%] = {')
        if p ~= nil then
            cur, inhaz = p, (p == "_hazards")
            if not inhaz and at.p[p] == nil then at.p[p] = n end
            -- (moves written on the same line: "boulder_crab = { uppercut = { ... }, ... }" - every key one brace in)
            local s = l:find("{", 1, true)
            if s ~= nil then
                local depth, i = 0, s
                while i <= #l do
                    local c = l:sub(i, i)
                    if c == "{" then depth = depth + 1 elseif c == "}" then depth = depth - 1 if depth <= 0 then break end
                    elseif c == '"' then local j = l:find('"', i + 1, true) i = j or #l
                    elseif depth == 1 then
                        local k = l:match("^([%a_][%w_]*) = {", i) or l:match('^%["([^"]+)"%] = {', i)
                        if k ~= nil then
                            local key = (inhaz and k) or (p .. "/" .. k)
                            local tbl = inhaz and at.h or at.m
                            tbl[key] = tbl[key] or n
                            i = i + #k
                        end
                    end
                    i = i + 1
                end
            end
        else
            local m = l:match("^        ([%w_]+) = {") or l:match('^        %["([^"]+)"%] = {')
            if m ~= nil and cur ~= nil then
                if inhaz then at.h[m] = at.h[m] or n else at.m[cur .. "/" .. m] = at.m[cur .. "/" .. m] or n end
            end
        end
    end
    return at
end

local SOURCES = {
    { file = "moves_sim", tag = "game" },
    { file = "moves_sim_um", tag = "UM" },
    { file = "moves_sim_te", tag = "TE" },
    { file = "moves_hand", tag = "hand" },
    { file = "moves_hand_um", tag = "hand-UM" },
}
local mons, hazards, aliases = {}, {}, {}
for _, s in ipairs(SOURCES) do
    local ok, t = pcall(dofile, dir .. s.file .. ".lua")
    if ok and type(t) == "table" then
        local at = Lines(s.file)
        for p, moves in pairs(t) do
            if p == "_hazards" and type(moves) == "table" then
                for hp, h in pairs(moves) do
                    hazards[#hazards + 1] = { name = hp, h = h, src = s, line = at.h[hp] }
                end
            elseif p == "_alias" and type(moves) == "table" then
                for a, b in pairs(moves) do aliases[a] = b end
            elseif type(p) == "string" and p:sub(1, 1) ~= "_" and type(moves) == "table" then
                local m = mons[p]
                if m == nil then m = { prefab = p, rows = {}, srcs = {}, lines = {} } mons[p] = m end
                m.srcs[s.tag] = true
                m.lines[s.tag] = at.p[p]
                for mv, e in pairs(moves) do
                    if type(e) == "table" then
                        m.rows[#m.rows + 1] = { move = mv, e = e, src = s, line = at.m[p .. "/" .. mv] }
                    end
                end
            end
        end
    end
end
-- (moves_table: moves run at every angle and reach - marked on their rows)
local tabled = {}
do
    local ok, t = pcall(dofile, dir .. "moves_table.lua")
    if ok and type(t) == "table" then
        for p, moves in pairs(t) do
            if type(p) == "string" and p:sub(1, 1) ~= "_" and type(moves) == "table" then
                for mv in pairs(moves) do tabled[p .. "/" .. mv] = true end
            end
        end
    end
end

-- (the mod's own code naming each monster or thing: where special handling lives - modmain, predict, simmoves)
local code_refs = {}
local CODE = { { path = root .. "/modmain.lua", short = "modmain.lua" }, { path = dir .. "predict.lua", short = "predict.lua" },
    { path = dir .. "simmoves.lua", short = "simmoves.lua" } }
local want = {}
for p in pairs(mons) do want[p] = true end
for _, h in ipairs(hazards) do want[h.name] = true end
for _, c in ipairs(CODE) do
    local n = 0
    for l in io.lines(c.path) do
        n = n + 1
        local code = l:gsub("%-%-.*$", "")
        for w in code:gmatch("[%a_][%w_]*") do
            if want[w] then
                code_refs[w] = code_refs[w] or {}
                local r = code_refs[w]
                if #r < 12 and (r[#r] == nil or r[#r] ~= c.short .. ":" .. n) then r[#r + 1] = c.short .. ":" .. n end
            end
        end
    end
end

local function Esc(s) return (tostring(s):gsub("|", "/")) end
local function List(t, max)
    if type(t) ~= "table" then return "" end
    local o = {}
    for i, v in ipairs(t) do if i > (max or 4) then o[#o + 1] = "…" break end o[#o + 1] = tostring(v) end
    return table.concat(o, ", ")
end
local function Travel(e)
    local m = e.maps ~= nil and e.maps[1] or nil
    local path = (m ~= nil and m.path) or (e.free ~= nil and e.free[1] ~= nil and e.free[1].path) or nil
    local far = 0
    if type(path) == "string" then for v in path:gmatch("[%d%.]+") do far = math.max(far, tonumber(v) or 0) end end
    return far
end
local function Kind(e)
    local k = {}
    if e.follow ~= nil then k[#k + 1] = "follows target" end
    if e.leg ~= nil then k[#k + 1] = "charge legs" end
    if e.around ~= nil then k[#k + 1] = "around itself" end
    if e.lane ~= nil then k[#k + 1] = "lane" end
    if e.cone ~= nil then k[#k + 1] = "cone" end
    if e.tell ~= nil then k[#k + 1] = "told by " .. tostring(e.tell) end
    if e.scale ~= nil then k[#k + 1] = "scale " .. tostring(e.scale) end
    if e.things_only then k[#k + 1] = "strikes only through things" end
    local far = Travel(e)
    if far > .3 then k[#k + 1] = string.format("moves %.1f", far) end
    return table.concat(k, " · ")
end
local function Ref(src, line) return line ~= nil and string.format("`%s.lua:%d`", src.file, line) or ("`" .. src.file .. ".lua`") end

-- (pages by first letter)
local list = {}
for _, m in pairs(mons) do list[#list + 1] = m end
table.sort(list, function(a, b) return a.prefab < b.prefab end)
local by_letter, letters = {}, {}
for _, m in ipairs(list) do
    local L = m.prefab:sub(1, 1):lower()
    if not L:match("%a") then L = "0" end
    if by_letter[L] == nil then by_letter[L] = {} letters[#letters + 1] = L end
    table.insert(by_letter[L], m)
end
local haz_of = {}
for _, h in ipairs(hazards) do
    local by = type(h.h) == "table" and h.h.by or nil
    if type(by) == "table" and #by > 0 then
        for _, b in ipairs(by) do haz_of[b] = haz_of[b] or {} table.insert(haz_of[b], h) end
    else
        haz_of["?"] = haz_of["?"] or {} table.insert(haz_of["?"], h)
    end
end
local function HazRow(h)
    local x = type(h.h) == "table" and h.h or {}
    local k = {}
    if x.moved then k[#k + 1] = "moving" end
    if x.lasting then k[#k + 1] = "lasting" end
    if x.in_move then k[#k + 1] = "drawn with the boss move" end
    if x.lands then k[#k + 1] = "strikes on landing" end
    if x.delay ~= nil then k[#k + 1] = "delay " .. tostring(x.delay) end
    if x.strikes_until ~= nil then k[#k + 1] = "strikes until " .. tostring(x.strikes_until) end
    local refs = code_refs[h.name] and table.concat(code_refs[h.name], " ") or ""
    return string.format("| `%s` | %s | %s | %s | %s | %s |", h.name, Esc(Name(h.name)), table.concat(k, " · "), h.src.tag, Ref(h.src, h.line), refs)
end

for _, L in ipairs(letters) do
    local f = assert(io.open(out .. "/" .. L .. ".md", "wb"))
    f:write("# Monster catalog - " .. L:upper() .. "\n\n[<- full index](README.md) · made by `tools\\make_catalog.ps1` - **don't edit this page by hand**\n\n")
    f:write("Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)\n\n")
    for _, m in ipairs(by_letter[L]) do
        local srcs = {}
        for _, s in ipairs(SOURCES) do if m.srcs[s.tag] then srcs[#srcs + 1] = s.tag .. (m.lines[s.tag] and (" `" .. s.file .. ".lua:" .. m.lines[s.tag] .. "`") or "") end end
        f:write(string.format('<a id="%s"></a>\n\n## %s%s\n\n', m.prefab, m.prefab, Name(m.prefab) ~= "" and (" — " .. Name(m.prefab)) or ""))
        f:write("Data from: " .. table.concat(srcs, " · ") .. "\n\n")
        if aliases[m.prefab] then f:write("Drawn as: `" .. tostring(aliases[m.prefab]) .. "`\n\n") end
        table.sort(m.rows, function(a, b) if a.move ~= b.move then return a.move < b.move end return a.src.file < b.src.file end)
        f:write("| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |\n|---|---|---|---|---|---|---|---|---|---|\n")
        for _, r in ipairs(m.rows) do
            local e = r.e
            f:write(string.format("| `%s`%s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n", Esc(r.move), tabled[m.prefab .. "/" .. r.move] and " ▦" or "",
                Esc(List(e.anims)), tostring(e.first or ""), tostring(e.frame or ""), tostring(e.lock or ""), Esc(Kind(e)), Esc(List(e.puts, 3)),
                Esc(e.cooldown or ""), r.src.tag, Ref(r.src, r.line)))
        end
        if haz_of[m.prefab] then
            f:write("\n**Things it puts out**\n\n| thing | name | kind | source | where | code that names it |\n|---|---|---|---|---|---|\n")
            table.sort(haz_of[m.prefab], function(a, b) return a.name < b.name end)
            for _, h in ipairs(haz_of[m.prefab]) do f:write(HazRow(h) .. "\n") end
        end
        if code_refs[m.prefab] then
            f:write("\n**Special code that names it:** " .. table.concat(code_refs[m.prefab], " ") .. "\n")
        end
        f:write("\n")
    end
    f:close()
end

-- (the index)
local f = assert(io.open(out .. "/README.md", "wb"))
local nmoves, nhaz = 0, #hazards
for _, m in ipairs(list) do nmoves = nmoves + #m.rows end
f:write("# Monster and move catalog\n\n[<- docs](../README.md) · made from the data files - **don't edit by hand** · remake: `powershell -File tools\\make_catalog.ps1`\n\n")
f:write(string.format("**%d** monsters · **%d** moves · **%d** things they put out\n\n", #list, nmoves, nhaz))
f:write("Sources: **game** = `moves_sim.lua` (run offline from the base game) · **UM** = `moves_sim_um.lua` · **TE** = `moves_sim_te.lua` · **hand** / **hand-UM** = `moves_hand*.lua` (written by hand) · ▦ = has a `moves_table.lua` table\n\n")
f:write("To find one: Ctrl+F the prefab or in-game name -> open its page -> **where** gives the data's file:line, **special code that names it** the places in modmain/predict/simmoves that treat that monster specially\n\n")
local nav = {}
for _, L in ipairs(letters) do nav[#nav + 1] = "[" .. L:upper() .. "](" .. L .. ".md)" end
f:write(table.concat(nav, " · ") .. "\n\n")
f:write("| prefab | in-game name | source | moves | things | special code |\n|---|---|---|---|---|---|\n")
for _, m in ipairs(list) do
    local srcs = {}
    for _, s in ipairs(SOURCES) do if m.srcs[s.tag] then srcs[#srcs + 1] = s.tag end end
    local L = m.prefab:sub(1, 1):lower()
    if not L:match("%a") then L = "0" end
    f:write(string.format("| [`%s`](%s.md#%s) | %s | %s | %d | %d | %s |\n", m.prefab, L, m.prefab, Esc(Name(m.prefab)), table.concat(srcs, ", "),
        #m.rows, haz_of[m.prefab] and #haz_of[m.prefab] or 0, code_refs[m.prefab] and #code_refs[m.prefab] or 0))
end
if haz_of["?"] then
    f:write("\n## Things with no owner in the data\n\n| thing | name | kind | source | where | code that names it |\n|---|---|---|---|---|---|\n")
    table.sort(haz_of["?"], function(a, b) return a.name < b.name end)
    for _, h in ipairs(haz_of["?"]) do f:write(HazRow(h) .. "\n") end
end
f:close()
print(string.format("catalog: %d monsters, %d moves, %d things, %d pages -> %s", #list, nmoves, nhaz, #letters, out))
