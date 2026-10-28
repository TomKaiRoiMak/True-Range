-- luajit tools/merge_moves.lua <data file> <second run's file> <prefab,...>
-- Each listed prefab's moves from the second run added to the data file's - none of its own replaced (a move named alike
-- kept as it was) - and the file written again in place. For a monster run twice, once per stategraph (tools/build_te.ps1,
-- tools/sim_mods/te_second.lua). Prints what it added.
local DATA, SECOND = arg[1], arg[2]
local want = {}
for p in (arg[3] or ""):gmatch("[^,]+") do want[p] = true end
local function Read(p) local f = assert(io.open(p, "rb")) local s = f:read("*a") f:close() return s end
local text, second = Read(DATA), dofile(SECOND)
-- (the second run's lines for one prefab's moves, as written - its block, each move one line at 8 spaces)
local stext = Read(SECOND)
local added = 0
for prefab in pairs(want) do
    local moves = second[prefab]
    if type(moves) == "table" then
        local block = stext:match('\n    %["' .. prefab:gsub("%W", "%%%0") .. '"%] = %{\n(.-)\n    %},')
        local have = dofile(DATA)[prefab] or {}
        -- (each move a block of lines: its own at 8 spaces, its maps deeper, its closing "        } }," - all of it)
        local groups, cur = {}, nil
        for line in (block or ""):gmatch("[^\n]+") do
            local name = line:match('^        %["([^"]+)"%] = ') or line:match("^        ([%w_~@]+) = ")
            if name ~= nil then
                cur = { name = name, lines = { line } }
                groups[#groups + 1] = cur
            elseif cur ~= nil then
                table.insert(cur.lines, line)
            end
        end
        local lines = {}
        for _, g in ipairs(groups) do
            if have[g.name] == nil then
                for _, l in ipairs(g.lines) do lines[#lines + 1] = l end
                added = added + 1
                print("added " .. prefab .. " " .. g.name)
            end
        end
        if #lines > 0 then
            local pat = '(\n    %["' .. prefab:gsub("%W", "%%%0") .. '"%] = %{\n)'
            -- (or the whole monster on one line, as tools/mod_diff.lua writes it: put in after its opening brace, one line too)
            local one = '(\n    %["' .. prefab:gsub("%W", "%%%0") .. '"%] = %{ )'
            if text:find(pat) then
                text = text:gsub(pat, function(head) return head .. table.concat(lines, "\n") .. "\n" end, 1)
            elseif text:find(one) then
                local flat = table.concat(lines, " "):gsub("%s+", " ")
                text = text:gsub(one, function(head) return head .. flat .. " " end, 1)
            else
                -- (none of its own yet: a block of its own, before the things)
                text = text:gsub("(\n    %[\"_hazards\"%] = )", "\n    [\"" .. prefab .. "\"] = {\n" .. table.concat(lines, "\n") .. "\n    },%1", 1)
            end
        end
    end
end
local f = assert(io.open(DATA, "wb"))
f:write(text)
f:close()
assert(loadfile(DATA), "merged file does not load")
print(added .. " moves added")
