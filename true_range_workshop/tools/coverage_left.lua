-- luajit coverage_left.lua <state_coverage output> <forced bench folder> [<more forced folders>...]: each harmful state
-- still under 3 times (state_coverage's MISSING lines), put in what's left to do for it:
--   no trace    - the monster never fought on the testbench at all (not in the game, gone as made)
--   not its     - the forced run could not put it into that state (tr_testbench "forced - not entered"): not in
--                 its stategraph as it is, or never reachable - the scan's word "harmful" wrong for it
--   forced      - gone into only when forced: where and when it strikes checked, its aim not the game's way in
--   too few     - gone into, under 3 times: more rounds
--   not tried   - never forced yet (no forced run of it)
local COV = arg[1]
local forced, notin = {}, {}
for i = 2, #arg do
    local p = io.popen('dir /b "' .. arg[i] .. '\\share*.txt" 2>nul')
    for name in p:lines() do
        for l in io.lines(arg[i] .. "\\" .. name) do
            local b, how, st = l:match("%[tr_bench%] [%d%.]+ ([%w_]+) (forced[%w %-]*) state=([%w_]+)")
            if b then
                local k = b .. " " .. st
                if how:find("not entered", 1, true) then notin[k] = true else forced[k] = (forced[k] or 0) + 1 end
            end
        end
    end
    p:close()
end
local notrace = {}
local rows = {}
for l in io.lines(COV) do
    local list = l:match("bosses with no trace at all: (.*)$")
    if list then for b in list:gmatch("%S+") do notrace[b] = true end end
    local b, st, n = l:match("^MISSING%s+(%S+)%s+(%S+)%s+(%d+)")
    if b then rows[#rows + 1] = { b, st, tonumber(n) } end
end
local groups, order = {}, { "no trace", "not its", "forced", "too few", "not tried" }
for _, r in ipairs(rows) do
    local k = r[1] .. " " .. r[2]
    local g
    if notrace[r[1]] then g = "no trace"
    elseif notin[k] and not forced[k] then g = "not its"
    elseif forced[k] then g = "forced"
    elseif r[3] > 0 then g = "too few"
    else g = "not tried" end
    groups[g] = groups[g] or {}
    table.insert(groups[g], k .. " (" .. r[3] .. (forced[k] and (", forced " .. forced[k]) or "") .. ")")
end
for _, g in ipairs(order) do
    local l = groups[g] or {}
    print(string.format("== %s: %d", g, #l))
    for _, s in ipairs(l) do print("   " .. s) end
end
