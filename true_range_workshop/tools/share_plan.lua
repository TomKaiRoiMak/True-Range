-- luajit share_plan.lua <log> <max pieces> <trace lines a piece> > <plan>: all tests/bench_replay.ps1 needs
-- of one testbench share, from one read of it - the bosses with scenes, whether its things were traced
-- (and whether written only as they change), each monster's cuts by its own work (as tools/work_cuts.lua)
-- and its things' (as tools/haz_cuts.lua). Every share read four or five times over, one after another,
-- was minutes before any replay began (2026-10-18); run side by side, a core each.
-- Lines: "boss <prefab>", "haz", "you", "cuts <prefab> <lines> <cut> ...", "hazcuts <cut> ...".
local max_pieces = tonumber(arg[2]) or 16
local per = tonumber(arg[3]) or 40000
local bosses, bseen, times, haz, starts = {}, {}, {}, {}, {}
local has_haz, has_you = false, false
for line in io.lines(arg[1]) do
    local c = line:find("[tr_", 1, true)
    if c ~= nil then
        local kind = line:sub(c + 4, c + 8)
        if kind == "trace" then
            local t, p = line:match("^%[tr_trace%] ([%d%.]+) ([%w_]+) ", c)
            if t ~= nil then
                local l = times[p]
                if l == nil then l = {} times[p] = l end
                l[#l + 1] = tonumber(t)
            end
        elseif kind == "haz] " then
            has_haz = true
            local t, p = line:match("^%[tr_haz%] ([%d%.]+) ([%w_]+)", c)
            if t ~= nil then
                if p == "_you" then has_you = true end
                haz[#haz + 1] = tonumber(t)
            end
        elseif kind == "bench" then
            local st = line:match("^%[tr_bench%] ([%d%.]+) %S+ start ", c)
            if st ~= nil then starts[#starts + 1] = tonumber(st) end
            local p = line:match("^%[tr_bench%] [%d%.]+ (%S+) end ", c)
            if p ~= nil and not bseen[p] then bseen[p] = true bosses[#bosses + 1] = p end
        end
    end
end
table.sort(bosses)
table.sort(starts)
for _, p in ipairs(bosses) do print("boss " .. p) end
if has_haz then print("haz") end
if has_you then print("you") end
local function Cuts(l, n, snap)
    table.sort(l)
    local cuts, last = {}, nil
    for i = 1, n - 1 do
        local t = l[math.floor(#l * i / n)]
        -- (at the scene begun last before it - not in a scene's middle: cut there, 9 of the Mini Eyes' 145 came out
        -- otherwise than cut by scenes, 2026-10-18)
        if snap and #starts > 0 then
            local s = nil
            for _, st in ipairs(starts) do if st <= t then s = st else break end end
            t = s or t
        end
        if last == nil or t > last + 1 then cuts[#cuts + 1] = string.format("%.3f", t) last = t end
    end
    return cuts
end
local names = {}
for p in pairs(times) do names[#names + 1] = p end
table.sort(names)
for _, p in ipairs(names) do
    local l = times[p]
    -- (its work, every one - for the scheduler: the longest started first)
    print("lines " .. p .. " " .. #l)
    local n = math.min(max_pieces, math.ceil(#l / per))
    if n >= 2 then print("cuts " .. p .. " " .. #l .. " " .. table.concat(Cuts(l, n, true), " ")) end
end
if #haz >= max_pieces * 2 then print("hazcuts " .. table.concat(Cuts(haz, max_pieces), " ")) end
