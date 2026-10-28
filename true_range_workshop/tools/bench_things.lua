-- luajit tools/bench_things.lua <bench log> [moves_sim.lua] [moves_sim_um.lua]
-- Every thing the bench saw made ([tr_ent], tr_testbench headless - the world holds nothing else, so
-- each is a boss's doing) set against every blow on the stand-in ([tr_hit]: who dealt it, where it and
-- you were) and where you were all along ([tr_trace] you=): per kind of thing -
--   made        how many
--   struck      blows it dealt itself, and the farthest it was from you then
--   in reach    of those you stood within the reach the mod draws for it (its data), any frame
--   no blow     of those, with no blow on you at all from anything while in it - drawn, never struck
-- A thing in the data as one that strikes, many times in reach, never struck and never a blow while in
-- it: only a picture (a pound's ring) - DRAWN-NEVER. One striking from farther than drawn: FARTHER.
DEGREES = math.pi / 180 FRAMES = 1 / 30
local LOG = arg[1]
local reach, alias = {}, {}
do
    local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"
    local DIGIT = {}
    for i = 1, #B64 do DIGIT[B64:byte(i)] = i - 1 end
    local function Far(text, G)
        local pos, row, far = 1, -1, 0
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
            local n, last_end = Num(), -1
            for _ = 1, n do
                local from = last_end + 1 + Num()
                local to = from + Num()
                for c = from, to do
                    local ah, sd = G.ahead + c * G.step, -G.side + row * G.step
                    far = math.max(far, math.sqrt(ah * ah + sd * sd) + G.step / 2)
                end
                last_end = to
            end
        end
        return far
    end
    local G = nil
    for i = 2, #arg do
        local ok, d = pcall(dofile, arg[i])
        if ok and type(d) == "table" then
            G = G or d._grid
            for k, h in pairs(d._hazards or {}) do
                local f = 0
                for _, s in ipairs(h.steps or {}) do f = math.max(f, Far(s.cells or "", G or d._grid)) end
                -- (whose, from every file - the game's and the mod's, as true_range/moddata joins them; and
                -- what it does: only a status (a deer's ice circle freezing) - not judged by blows)
                local was = reach[k]
                local by = was ~= nil and (was.by ~= "" and was.by .. "," or "") or ""
                by = by .. table.concat(h.by or {}, ",")
                local harm = h.effects == nil or h.effects:find("harm", 1, true) ~= nil
                reach[k] = { far = math.max(f, was ~= nil and was.far or 0), by = by, in_move = h.in_move or (was ~= nil and was.in_move), harm = harm and (was == nil or was.harm) }
            end
            for a, b in pairs(d._alias or {}) do alias[a] = b end
        end
    end
end
local things, hits, you = {}, {}, {}
for line in io.lines(LOG) do
    local t, what, p, guid, x, z, fx = line:match("%[tr_ent%] ([%d%.]+) (%a+) (%S+) (%d+) (%-?[%d%.]+) (%-?[%d%.]+)%s*(.*)$")
    if t ~= nil then
        guid = tonumber(guid)
        local e = things[guid]
        if what == "born" then
            things[guid] = { prefab = p, guid = guid, t0 = tonumber(t), x = tonumber(x), z = tonumber(z), fx = fx:find("fx=1", 1, true) ~= nil }
        elseif e ~= nil then e.t1, e.x1, e.z1 = tonumber(t), tonumber(x), tonumber(z) end
    end
    local ht, hp, hg, ax, az, yx, yz = line:match("%[tr_hit%] ([%d%.]+) (%S+) (%d+) (%-?[%d%.e+]+) (%-?[%d%.e+]+) you (%-?[%d%.]+) (%-?[%d%.]+)")
    if ht ~= nil then hits[#hits + 1] = { t = tonumber(ht), prefab = hp, guid = tonumber(hg), ax = tonumber(ax), az = tonumber(az), yx = tonumber(yx), yz = tonumber(yz) } end
    -- (a loss of health with no blow - fire burning: in it, struck all the same; not counted as a blow of its)
    local ut, up, ug = line:match("%[tr_hurt%] ([%d%.]+) (%S+) (%d+) ")
    if ut ~= nil and line:find("cause=", 1, true) then hits[#hits + 1] = { t = tonumber(ut), prefab = up, guid = tonumber(ug), ax = -1e9, az = -1e9, yx = 0, yz = 0, hurt = true } end
    local tt, yx2, yz2 = line:match("%[tr_trace%] ([%d%.]+) %S+ after .- you=(%-?[%d%.]+),(%-?[%d%.]+)")
    if tt ~= nil then you[#you + 1] = { tonumber(tt), tonumber(yx2), tonumber(yz2) } end
end
table.sort(you, function(a, b) return a[1] < b[1] end)
local function YouFrom(i0, t) -- (first sample at or after t)
    local lo, hi = 1, #you
    while lo < hi do
        local m = math.floor((lo + hi) / 2)
        if you[m][1] < t then lo = m + 1 else hi = m end
    end
    return lo
end
-- (a blow while in it, from it or from the boss its strikes are credited to (its data's by) - not one
-- from something else there at the same time: a rock's own blow where its ring lies)
-- (any: a blow from anything at all; else only from it or its own (by - or one drawn as one of them:
-- a nightmare bishop as a bishop))
local function HitNear(t0, t1, guid, by, any)
    for _, h in ipairs(hits) do
        if h.t >= t0 - .05 and h.t <= t1 + .05 then
            if any or h.guid == guid then return true end
            local list = "," .. by .. ","
            if by ~= "" and (list:find("," .. h.prefab .. ",", 1, true) or (alias[h.prefab] and list:find("," .. alias[h.prefab] .. ",", 1, true))) then return true end
        end
    end
    return false
end
-- (made by what: a thing gone where it was made, that moment - a rock come down, its ring - or else
-- the boss, the thing with a fight in it nearest then; kept apart: the same ring from a rock and from
-- the Minotaur's leap are two)
local list = {}
for _, e in pairs(things) do list[#list + 1] = e end
local bosses = {}
for line in io.lines(LOG) do
    local tt, bp, bx, bz = line:match("%[tr_trace%] ([%d%.]+) (%S+) after .- pos=(%-?[%d%.]+),(%-?[%d%.]+)")
    if tt ~= nil then
        bosses[bp] = bosses[bp] or {}
        table.insert(bosses[bp], { tonumber(tt), tonumber(bx), tonumber(bz) })
    end
end
for _, e in ipairs(list) do
    local best, bd = nil, .5
    for _, o in ipairs(list) do
        if o ~= e and o.t1 ~= nil and math.abs(o.t1 - e.t0) <= .07 and not o.prefab:find("_classified$") then
            local d = math.sqrt((o.x1 - e.x) ^ 2 + (o.z1 - e.z) ^ 2)
            if d < bd then best, bd = o.prefab, d end
        end
    end
    if best == nil then
        local bdist = math.huge
        for bp, l in pairs(bosses) do
            for _, s in ipairs(l) do
                if math.abs(s[1] - e.t0) <= .04 then
                    local d = math.sqrt((s[2] - e.x) ^ 2 + (s[3] - e.z) ^ 2)
                    if d < bdist then best, bdist = bp, d end
                end
            end
        end
    end
    e.from = best or "?"
end
local by_kind = {}
for _, e in pairs(things) do
    local kk = e.prefab .. " <" .. e.from .. ">"
    local k = by_kind[kk]
    if k == nil then k = { prefab = e.prefab, made = 0, struck = 0, far = 0, inreach = 0, noblow = 0, fx = e.fx } by_kind[kk] = k end
    k.made = k.made + 1
    local r = reach[e.prefab]
    if r ~= nil and #you > 0 then
        local t1 = e.t1 or (e.t0 + 30)
        local i = YouFrom(1, e.t0)
        local first_in, last_in = nil, nil
        while i <= #you and you[i][1] <= t1 do
            local d = math.sqrt((you[i][2] - e.x) ^ 2 + (you[i][3] - e.z) ^ 2)
            if d <= r.far then first_in = first_in or you[i][1] last_in = you[i][1] end
            i = i + 1
        end
        if first_in ~= nil then
            k.inreach = k.inreach + 1
            if not HitNear(first_in, last_in + .2, e.guid, r.by) then k.noblow = k.noblow + 1 end
            if not HitNear(first_in, last_in + .2, e.guid, r.by, true) then k.noany = (k.noany or 0) + 1 end
        end
    end
end
for _, h in ipairs(hits) do
    local e = things[h.guid]
    local k = e ~= nil and by_kind[e.prefab .. " <" .. e.from .. ">"] or nil
    if k == nil then
        k = by_kind[h.prefab .. " <self>"]
        if k == nil then k = { prefab = h.prefab, made = 0, struck = 0, far = 0, inreach = 0, noblow = 0 } by_kind[h.prefab .. " <self>"] = k end
    end
    if h.ax > -1e8 then
        k.struck = k.struck + 1
        k.far = math.max(k.far, math.sqrt((h.ax - h.yx) ^ 2 + (h.az - h.yz) ^ 2))
    end
end
local names = {}
for p in pairs(by_kind) do names[#names + 1] = p end
table.sort(names, function(a, b) return by_kind[a].made > by_kind[b].made end)
print(string.format("%-36s %6s %6s %6s %7s %6s %8s  %s", "thing", "made", "struck", "farth", "inreach", "noblow", "drawn", "verdict"))
for _, p in ipairs(names) do
    local k = by_kind[p]
    local r = reach[k.prefab]
    local verdict = ""
    if r ~= nil then
        if not r.harm then verdict = "(a status only - not judged by blows)"
        elseif k.struck == 0 and k.inreach >= 3 and (k.noany or 0) == k.inreach then verdict = "NEVER-ANY (in it, no blow from anything)"
        elseif k.struck == 0 and k.inreach >= 3 and k.noblow == k.inreach then verdict = "NEVER-OWN (blows only from others while in it)"
        elseif k.struck > 0 and k.far > r.far + .3 then verdict = string.format("FARTHER (struck %.2f, drawn %.2f)", k.far, r.far)
        elseif k.inreach > 0 and k.noblow / k.inreach > .5 then verdict = "mostly no blow in it" end
    elseif k.struck > 0 then verdict = "STRIKES, NOT IN DATA" end
    if r ~= nil or k.struck > 0 then
        print(string.format("%-36s %6d %6d %6.2f %7d %6d %8s  %s%s", p, k.made, k.struck, k.far, k.inreach, k.noblow,
            r ~= nil and string.format("%.2f", r.far) or "-", verdict, r ~= nil and r.by ~= "" and (" [by " .. r.by .. (r.in_move and ", in_move" or "") .. "]") or ""))
    end
end
print(string.format("%d things made, %d blows on the stand-in, %d places of you", (function() local n = 0 for _ in pairs(things) do n = n + 1 end return n end)(), #hits, #you))
