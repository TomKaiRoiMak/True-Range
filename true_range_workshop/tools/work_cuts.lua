-- luajit work_cuts.lua <log> <max pieces> <lines a piece>: for each monster traced in a log, how many
-- [tr_trace] lines it has and where to cut its replay so no piece holds more than <lines a piece> of
-- them - its work, not its scenes or the file's size: the Mini Eyes, thousands of them in a 140 MB log,
-- one replay of 30 minutes, a single core while the rest stood idle (tests/bench_replay.ps1, 2026-10-18).
-- One line each: "<prefab> <lines> <cut> <cut> ..." (cuts: where pieces after the first begin).
local max_pieces = tonumber(arg[2]) or 16
local per = tonumber(arg[3]) or 40000
local times = {}
for line in io.lines(arg[1]) do
    local t, p = line:match("%[tr_trace%] ([%d%.]+) ([%w_]+) ")
    if t ~= nil then
        local l = times[p]
        if l == nil then l = {} times[p] = l end
        l[#l + 1] = tonumber(t)
    end
end
local names = {}
for p in pairs(times) do names[#names + 1] = p end
table.sort(names)
for _, p in ipairs(names) do
    local l = times[p]
    table.sort(l)
    local n = math.min(max_pieces, math.ceil(#l / per))
    local cuts, last = {}, nil
    for i = 1, n - 1 do
        local t = l[math.floor(#l * i / n)]
        if last == nil or t > last + 1 then cuts[#cuts + 1] = string.format("%.3f", t) last = t end
    end
    print(p .. " " .. #l .. (#cuts > 0 and (" " .. table.concat(cuts, " ")) or ""))
end
