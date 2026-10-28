-- luajit haz_cuts.lua <log> <pieces>: times to cut a log's things at, so each piece holds as many [tr_haz]
-- lines as the next - its work, not its scenes: the Great Depths Worm's hundreds of segments all in its own
-- few scenes, cut by scenes one piece held nearly all of it (tests/bench_replay.ps1, 2026-10-18).
-- Prints the cuts (not the first piece's start), one a line.
local n = tonumber(arg[2]) or 16
local times = {}
for line in io.lines(arg[1]) do
    local t = line:match("^%[tr_haz%] ([%d%.]+) ") or line:match("%[tr_haz%] ([%d%.]+) ")
    if t ~= nil then times[#times + 1] = tonumber(t) end
end
if #times < n * 2 then return end
table.sort(times)
local last = nil
for i = 1, n - 1 do
    local t = times[math.floor(#times * i / n)]
    if last == nil or t > last + 1 then
        print(string.format("%.3f", t))
        last = t
    end
end
