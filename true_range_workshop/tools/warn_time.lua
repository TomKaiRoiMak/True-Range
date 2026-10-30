-- luajit tools/warn_time.lua <client_log> [...]
-- For each blow on you ([tr_lag] struck by <prefab> ... guid=<g>): how many frames before it the striker's own shape was drawn,
-- unbroken ([tr_lagframe] <prefab> <g>) - "drawn: in" says only that it was there at the blow. UM's bomber bee: in at every
-- blow, up 0-3 frames before most of them (lag 0841) - a ring you can't step out of. Per striker: blows, how many with under
-- 5 frames (1/6 s) of warning, the median. Worst first.
local per = {}
for _, file in ipairs(arg) do
    local drawn, hits = {}, {}
    for line in io.lines(file) do
        local t, own, g, tri, grp = line:match("%[tr_lagframe%] ([%d%.]+) (%S+) (%d+) tri=(%d+) .- grp=(%d+)")
        if t and (tonumber(tri) > 0 or tonumber(grp) > 0) then
            local k = own .. "#" .. g
            drawn[k] = drawn[k] or {}
            drawn[k][math.floor(tonumber(t) * 30 + .5)] = true
        end
        local ht, p, hg = line:match("%[tr_lag%] ([%d%.]+) struck by (%S+) .-guid=(%d+)")
        if ht then hits[#hits + 1] = { f = math.floor(tonumber(ht) * 30 + .5), p = p, g = hg } end
    end
    for _, h in ipairs(hits) do
        local d, n, f = drawn[h.p .. "#" .. h.g] or {}, 0, h.f
        -- (the blow heard a frame or two after it struck: from the last frame drawn within 3 of it)
        local back = 0
        while not d[f] and back < 3 do f = f - 1 back = back + 1 end
        while d[f] do f = f - 1 n = n + 1 if n > 600 then break end end
        local s = per[h.p] or { n = 0, short = 0, list = {} }
        s.n = s.n + 1
        if n < 5 then s.short = s.short + 1 end
        s.list[#s.list + 1] = n
        per[h.p] = s
    end
end
local rows = {}
for p, s in pairs(per) do
    table.sort(s.list)
    rows[#rows + 1] = { p = p, n = s.n, short = s.short, med = s.list[math.floor((#s.list + 1) / 2)] }
end
table.sort(rows, function(a, b) return a.short / a.n > b.short / b.n end)
print(string.format("%-34s %6s %8s %7s", "striker", "blows", "under 5", "median"))
for _, r in ipairs(rows) do print(string.format("%-34s %6d %8d %7d", r.p, r.n, r.short, r.med)) end
