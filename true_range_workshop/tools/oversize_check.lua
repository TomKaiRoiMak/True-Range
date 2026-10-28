-- luajit oversize_check.lua <bench_x run folder> [data dir]: what a thing is drawn as, against how far from it it
-- really strikes (VERIFY_PLAN 6.16 I7 - drawn far bigger than it strikes). Every "[tr_haz] t thing guid=N HIT
-- pos=x,z you=x,z" of the bench's expanded logs gives how far you were from it struck; the data's cells for that
-- thing how far out it's drawn (round: furthest cell from it; flying: furthest to either side of its way). The
-- player (2026-10-19): the Ancient Guardian's goo "hitbox doesn't match" - drawn 4 round its way, striking within
-- 1.6, and no check saw it: every blow inside what was drawn, so neither missed nor drawn-in-unstruck.
-- Prints per thing: strikes, struck at most / p95, drawn out to, and OVERSIZE? where drawn > struck max + SLACK.
-- A suspect, not a finding: the bench may never have had you that far off when one struck - Bearger's boulders
-- (radius 3 in its code, bearger_boulder.lua:20, struck at most 2.06: aimed at you, they land on you) and the War
-- Machine's beam (3 + your body, wagboss_beam.lua:132-172, 10 strikes) were drawn right; the goo (4 drawn, 1.5 in
-- its code) was not. Each checked against the thing's own code before anything's changed.
DEGREES, FRAMES = math.pi / 180, 1 / 30
local RUN = arg[1]
local DATA = arg[2] or [[D:\Work\Coding\dont starve\true_range\scripts\true_range\]]
local SLACK = 1.0
local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"
local DIGIT = {}
for i = 1, #B64 do DIGIT[B64:byte(i)] = i - 1 end
-- (as true_range/simmoves Unpack: rows on from the last, runs, each run's start and length)
local function Runs(text)
    local runs, pos, row = {}, 1, -1
    local function Num()
        local v, scale = 0, 1
        while true do
            local d = DIGIT[text:byte(pos)] or 0
            pos = pos + 1
            v = v + (d % 32) * scale
            if d < 32 then return v end
            scale = scale * 32
        end
    end
    while pos <= #text do
        row = row + Num()
        local n = Num()
        local last_end = -1
        for _ = 1, n do
            local from = last_end + 1 + Num()
            local to = from + Num()
            runs[#runs + 1] = { row, from, to }
            last_end = to
        end
    end
    return runs
end
-- (the things, the game's and Uncompromising Mode's over it)
local hazards, grid = {}, nil
for _, f in ipairs({ "moves_sim.lua", "moves_sim_um.lua" }) do
    local ok, d = pcall(dofile, DATA .. f)
    if ok and type(d) == "table" then
        grid = grid or d._grid
        for k, h in pairs(d._hazards or {}) do hazards[k] = h end
    end
end
local step, ahead, side = grid.step, grid.ahead, grid.side
-- (how far out it's drawn: cell (row, col) is ahead + col*step forward, -side + row*step aside, of it)
local function Extent(h)
    local far, wide = 0, 0
    for _, st in ipairs(h.steps or {}) do
        for _, r in ipairs(Runs(st.cells or "")) do
            local sd = -side + r[1] * step
            for c = r[2], r[3] do
                local fw = ahead + c * step
                far = math.max(far, math.sqrt(fw * fw + sd * sd))
            end
            wide = math.max(wide, math.abs(sd))
        end
    end
    return far, wide
end
-- (the strikes: from every expanded share log)
local dist = {}
local p = io.popen('dir /b "' .. RUN .. '\\share*.txt" 2>nul')
for name in p:lines() do
    if not name:find("%.expand") and not name:find("%.err") then
        local fh = io.open(RUN .. "\\" .. name, "rb")
        if fh then
            for l in fh:lines() do
                local th, x, z, yx, yz = l:match("%[tr_haz%] [%d%.]+ ([%w_]+) guid=%d+ HIT pos=([%d%.%-]+),([%d%.%-]+) you=([%d%.%-]+),([%d%.%-]+)")
                if th then
                    local d = math.sqrt((tonumber(x) - tonumber(yx)) ^ 2 + (tonumber(z) - tonumber(yz)) ^ 2)
                    dist[th] = dist[th] or {}
                    table.insert(dist[th], d)
                end
            end
            fh:close()
        end
    end
end
p:close()
local names = {}
for k in pairs(dist) do names[#names + 1] = k end
table.sort(names)
local over = 0
print(string.format("%-40s %7s %7s %7s %7s %s", "thing", "strikes", "max", "p95", "drawn", ""))
for _, k in ipairs(names) do
    local t = dist[k]
    table.sort(t)
    local mx, p95 = t[#t], t[math.max(1, math.ceil(#t * .95))]
    local h = hazards[k]
    local drawn, how = -1, "not in data"
    if h ~= nil then
        local far, wide = Extent(h)
        if h.flies then drawn, how = wide, "flying: to its side" else drawn, how = far, "round" end
    end
    local flag = (drawn > 0 and drawn > mx + SLACK) and "OVERSIZE?" or ""
    if flag ~= "" then over = over + 1 end
    print(string.format("%-40s %7d %7.2f %7.2f %7.2f %s %s", k, #t, mx, p95, drawn, flag, how))
end
print(string.format("%d things struck; %d drawn more than %.1f past the furthest they struck", #names, over, SLACK))
