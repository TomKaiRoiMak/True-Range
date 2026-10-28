-- luajit map_steps_check.lua [-all]: each move's maps, one per distance of you (game + Uncompromising Mode),
-- next to the one before - as you walk the drawer goes from one to the next (simmoves.lua Decode / Draw), so a
-- map gone empty between two that aren't, its first strike leaping, or its size leaping, is a shape vanishing
-- or flashing other colours under a player walking (the reviewer, 2026-10-18: I9, "drawn smoothly as you
-- move"). The bench's stand-in stands still: never seen there. Read from the data alone.
-- Prints "<KIND> <prefab> <move> <list> d=<a>-><b>: <what>"; random moves (sim.random) marked, counted apart.
-- -all: every pair, not only those over the limits.
DEGREES, FRAMES = math.pi / 180, 1 / 30
local DATA = [[D:\Work\Coding\dont starve\true_range\scripts\true_range\]]
local ALL, FILES = false, {}
for _, a in ipairs(arg) do if a == "-all" then ALL = true else FILES[#FILES + 1] = a end end
-- (data files given: those, not the installed - a build's output, before it's put in)
if #FILES == 0 then FILES = { DATA .. "moves_sim.lua", DATA .. "moves_sim_um.lua" } end
local AT_JUMP = 3        -- frames: its first strike this much sooner or later from one distance to the next
local SIZE_JUMP = 2      -- times: its cells this many times more or fewer
local MIN_CELLS = 8      -- (tiny ones - a few cells - left out of SIZE: one cell more is half again)
local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"
local DIGIT = {}
for i = 1, #B64 do DIGIT[B64:byte(i)] = i - 1 end
-- (as simmoves.lua Unpack: how many cells only)
local function Count(text)
    local pos, n = 1, 0
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
        Num()
        local runs = Num()
        for _ = 1, runs do Num() n = n + Num() + 1 end
    end
    return n
end
local function Sum(m)
    local cells, at = 0, nil
    for _, st in ipairs(m.steps or {}) do
        local c = Count(st.cells or "")
        if c > 0 then
            cells = cells + c
            if at == nil or st.at < at then at = st.at end
        end
    end
    return cells, at
end
local counts, out = {}, {}
local function Say(kind, random, s)
    local k = kind .. (random and " (random)" or "")
    counts[k] = (counts[k] or 0) + 1
    out[#out + 1] = (random and "~" or "") .. kind .. " " .. s
end
for _, file in ipairs(FILES) do
    local d = dofile(file)
    local bosses = {}
    for b in pairs(d) do if b:sub(1, 1) ~= "_" and type(d[b]) == "table" then bosses[#bosses + 1] = b end end
    table.sort(bosses)
    for _, boss in ipairs(bosses) do
        local names = {}
        for m in pairs(d[boss]) do names[#names + 1] = m end
        table.sort(names)
        for _, name in ipairs(names) do
            local e = d[boss][name]
            if type(e) == "table" then
                local random = e.random == true
                for _, which in ipairs({ "maps", "free" }) do
                    local list, prev = e[which], nil
                    for i, m in ipairs(type(list) == "table" and list or {}) do
                        -- (the same as the one before: that one's)
                        local cells, at
                        if m.same and prev ~= nil then cells, at = prev.cells, prev.at else cells, at = Sum(m) end
                        local cur = { dist = m.dist, cells = cells, at = at }
                        if prev ~= nil then
                            local tag = string.format("%s %s %s d=%s->%s", boss, name, which, tostring(prev.dist), tostring(m.dist))
                            local nxt = list[i + 1]
                            if cells == 0 and prev.cells > 0 and nxt ~= nil then
                                local nc = nxt.same and 0 or Sum(nxt)
                                if nc > 0 then Say("EMPTY", random, tag .. string.format(": none between %d and %d cells", prev.cells, nc)) end
                            end
                            if at ~= nil and prev.at ~= nil and math.abs(at - prev.at) > AT_JUMP then
                                Say("AT", random, tag .. string.format(": first strike frame %d -> %d", prev.at, at))
                            end
                            if cells >= MIN_CELLS and prev.cells >= MIN_CELLS and math.max(cells, prev.cells) > SIZE_JUMP * math.min(cells, prev.cells) then
                                Say("SIZE", random, tag .. string.format(": %d -> %d cells", prev.cells, cells))
                            end
                            if ALL then out[#out + 1] = "  " .. tag .. string.format(": %d cells, at %s", cells, tostring(at)) end
                        end
                        prev = cur
                    end
                end
            end
        end
    end
end
for _, l in ipairs(out) do print(l) end
local ks = {}
for k in pairs(counts) do ks[#ks + 1] = k end
table.sort(ks)
for _, k in ipairs(ks) do print(string.format("TOTAL %s: %d", k, counts[k])) end
