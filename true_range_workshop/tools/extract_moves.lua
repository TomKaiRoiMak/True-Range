-- Reads stategraph and prefab code (the game's, and mods') and writes the attack moves it can
-- find, for True Range to preload: which animation an attack starts with, and on which frames
-- of it the damage comes. Heuristic, on purpose: it reads the code as text.
--
-- run: luajit extract_moves.lua <out.lua> <root> [<root> ...]
--   each root: a folder holding stategraphs/ and prefabs/ (the game's scripts folder, or a
--   mod's scripts folder); a mod's postinit/stategraphs/SG*.lua add states to the game's.

local out_path = arg[1]
local roots = {}
for i = 2, #arg do
    table.insert(roots, arg[i])
end

local function ReadFile(path)
    local f = io.open(path, "rb")
    if f == nil then
        return nil
    end
    local text = f:read("*a")
    f:close()
    return text
end

local function ListFiles(dir, pattern)
    local list = {}
    local p = io.popen('dir /b "' .. dir .. '" 2>nul')
    if p == nil then
        return list
    end
    for name in p:lines() do
        if name:match(pattern) then
            table.insert(list, dir .. "\\" .. name)
        end
    end
    p:close()
    return list
end

-- the text from the "{" at `open` to its matching "}", skipping strings and comments
local function Block(text, open)
    local depth, i, n = 0, open, #text
    while i <= n do
        local c = text:sub(i, i)
        if c == "-" and text:sub(i, i + 1) == "--" then
            local long = text:match("^%-%-%[(=*)%[", i)
            if long ~= nil then
                local close = text:find("]" .. long .. "]", i, true)
                i = (close or n) + #long + 2
            else
                local nl = text:find("\n", i, true)
                i = nl or n
            end
        elseif c == '"' or c == "'" then
            local j = i + 1
            while j <= n do
                local d = text:sub(j, j)
                if d == "\\" then
                    j = j + 1
                elseif d == c then
                    break
                end
                j = j + 1
            end
            i = j
        elseif c == "{" then
            depth = depth + 1
        elseif c == "}" then
            depth = depth - 1
            if depth == 0 then
                return text:sub(open, i), i
            end
        end
        i = i + 1
    end
    return text:sub(open), n
end

-- what in a timeline event's code means damage being dealt
local HIT_WORDS = {
    "DoAttack", "DoAreaAttack", "AreaAttack", "AOE", "Aoe", "GroundPound", "ArcAttack", "DoDamage",
    "Slam", "Stomp", "SpawnIce", "Shockwave", "DoSwipe", "Swipe(", "Trample", "Explode", "LaunchProjectile",
}

local function IsHit(code, attack_state)
    for _, w in ipairs(HIT_WORDS) do
        if code:find(w, 1, true) then
            return true
        end
    end
    -- (an attack state doing its buffered action: the attack itself)
    return attack_state and code:find("PerformBufferedAction", 1, true) ~= nil
end

-- frames (30 a second) of the timeline events in `tl` that deal damage
local function HitFrames(tl, attack_state)
    local events = {}
    local pos = 1
    while true do
        local s, e, kind = tl:find("(%a*Event)%s*%(", pos)
        if s == nil then
            break
        end
        if kind == "TimeEvent" or kind == "FrameEvent" then
            local arg = tl:match("^%s*([^,]+),", e + 1)
            local frame = nil
            if arg ~= nil then
                if kind == "FrameEvent" then
                    frame = tonumber(arg:match("^%s*(%d+)"))
                else
                    local n = arg:match("^%s*([%d%.]+)%s*%*%s*FRAMES")
                    if n ~= nil then
                        frame = tonumber(n)
                    elseif arg:match("^%s*FRAMES%s*$") then
                        frame = 1
                    else
                        local secs = tonumber(arg:match("^%s*([%d%.]+)%s*$"))
                        frame = secs ~= nil and math.floor(secs * 30 + .5) or nil
                    end
                end
            end
            table.insert(events, { at = s, frame = frame })
        end
        pos = e + 1
    end
    local frames = {}
    for i, ev in ipairs(events) do
        local code = tl:sub(ev.at, (events[i + 1] or { at = #tl + 1 }).at - 1)
        if ev.frame ~= nil and IsHit(code, attack_state) then
            table.insert(frames, ev.frame)
        end
    end
    table.sort(frames)
    return frames
end

local ATTACKY = { "attack", "atk", "pound", "slam", "stomp", "swipe", "charge", "spin", "bite", "lunge",
    "smash", "leap", "jump", "breath", "spit", "shoot", "throw", "laser", "tantrum", "combo" }
-- states that are never an attack, whatever their tags say
local NOT_ATTACKS = { "taunt", "howl", "eat", "hit", "death", "sleep", "wake", "idle", "walk", "run", "emerge", "spawn" }

local function Attacky(name, tags)
    local lower0 = name:lower()
    for _, w in ipairs(NOT_ATTACKS) do
        if lower0 == w or lower0:find("^" .. w .. "_") or lower0:find("_" .. w .. "$") then
            return false
        end
    end
    if tags:find('"attack"', 1, true) then
        return true
    end
    local lower = name:lower()
    for _, w in ipairs(ATTACKY) do
        if lower:find(w, 1, true) then
            return true
        end
    end
    return false
end

-- the moves in one stategraph file: { { state, anims = {...}, frames = {...} }, ... }
local function MovesIn(text)
    local moves = {}
    local pos = 1
    while true do
        local s = text:find("State%s*{", pos)
        if s == nil then
            break
        end
        local open = text:find("{", s, true)
        local block, close = Block(text, open)
        pos = close + 1
        local name = block:match('name%s*=%s*"([^"]+)"')
        local tags = block:match("tags%s*=%s*(%b{})") or ""
        if name ~= nil and Attacky(name, tags) then
            local anims, seen = {}, {}
            for anim in block:gmatch('PlayAnimation%(%s*"([^"]+)"') do
                if not seen[anim] then
                    seen[anim] = true
                    table.insert(anims, anim)
                end
            end
            local tl_open = block:find("timeline%s*=%s*{")
            if #anims > 0 and tl_open ~= nil then
                local tl = Block(block, block:find("{", tl_open, true))
                local frames = HitFrames(tl, tags:find('"attack"', 1, true) ~= nil)
                if #frames > 0 then
                    table.insert(moves, { state = name, anims = anims, frames = frames })
                end
            end
        end
    end
    -- CommonStates.AddCombatStates(states, { attacktimeline = ... }, { attack = "..." })
    for call_open in text:gmatch("()AddCombatStates%s*%(") do
        local paren = text:find("(", call_open, true)
        local call = text:sub(paren, paren + 4000)
        local tl = nil
        local tl_at = call:find("attacktimeline%s*=")
        if tl_at ~= nil then
            local brace = call:match("^attacktimeline%s*=%s*()%{", tl_at)
            if brace ~= nil then
                tl = Block(call, brace)
            else
                local var = call:match("^attacktimeline%s*=%s*([%w_]+)", tl_at)
                if var ~= nil then
                    local def = text:find("local%s+" .. var .. "%s*=%s*{")
                    if def ~= nil then
                        tl = Block(text, text:find("{", def, true))
                    end
                end
            end
        end
        if tl ~= nil then
            local frames = HitFrames(tl, true)
            local anim = call:match('attack%s*=%s*"([^"]+)"') or "atk"
            if #frames > 0 then
                table.insert(moves, { state = "attack", anims = { anim }, frames = frames })
            end
        end
    end
    return moves
end

-- stategraph moves by file name ("SGhound"), and the stategraph's own name -> file
local sg_moves = {}
for _, root in ipairs(roots) do
    for _, dir in ipairs({ root .. "\\stategraphs", root .. "\\..\\postinit\\stategraphs" }) do
        for _, path in ipairs(ListFiles(dir, "^SG.*%.lua$")) do
            local file = path:match("([^\\]+)%.lua$")
            local text = ReadFile(path)
            if text ~= nil then
                sg_moves[file] = sg_moves[file] or {}
                for _, m in ipairs(MovesIn(text)) do
                    table.insert(sg_moves[file], m)
                end
            end
        end
    end
end

-- prefab -> stategraph file, from SetStateGraph("SGx") in the prefab files
local prefab_moves = {}
local count = 0
for _, root in ipairs(roots) do
    for _, path in ipairs(ListFiles(root .. "\\prefabs", "%.lua$")) do
        local text = ReadFile(path)
        if text ~= nil then
            local sgs = {}
            for sg in text:gmatch('SetStateGraph%(%s*"([^"]+)"') do
                sgs[sg] = true
            end
            if next(sgs) ~= nil then
                local names = {}
                for name in text:gmatch('Prefab%(%s*"([%w_]+)"') do
                    table.insert(names, name)
                end
                if #names == 0 then
                    table.insert(names, path:match("([^\\]+)%.lua$"))
                end
                for _, name in ipairs(names) do
                    for sg in pairs(sgs) do
                        local moves = sg_moves[sg]
                        if moves ~= nil and #moves > 0 then
                            prefab_moves[name] = prefab_moves[name] or {}
                            for _, m in ipairs(moves) do
                                table.insert(prefab_moves[name], m)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- written out as a Lua table
local lines = {
    "-- Made by true_range_workshop/tools/extract_moves.lua from the game's (and mods') code:",
    "-- prefab -> its attack moves: the animations a move plays (the first is how it starts),",
    "-- and the frames (30 a second, from that start) its damage comes on.",
    "return {",
}
local prefabs = {}
for name in pairs(prefab_moves) do
    table.insert(prefabs, name)
end
table.sort(prefabs)
for _, name in ipairs(prefabs) do
    local parts, seen = {}, {}
    for _, m in ipairs(prefab_moves[name]) do
        local key = table.concat(m.anims, ",") .. "|" .. table.concat(m.frames, ",")
        if not seen[key] then
            seen[key] = true
            local anims = {}
            for _, a in ipairs(m.anims) do
                table.insert(anims, string.format("%q", a))
            end
            table.insert(parts, string.format("{ anims = { %s }, frames = { %s } }", table.concat(anims, ", "), table.concat(m.frames, ", ")))
        end
    end
    table.insert(lines, string.format("    [%q] = {", name))
    for _, p in ipairs(parts) do
        table.insert(lines, "        " .. p .. ",")
    end
    table.insert(lines, "    },")
    count = count + 1
end
table.insert(lines, "}")
local f = assert(io.open(out_path, "wb"))
f:write(table.concat(lines, "\n"), "\n")
f:close()
print(count .. " monsters with attack moves written to " .. out_path)
