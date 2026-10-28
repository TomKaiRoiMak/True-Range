-- luajit goo_check.lua <share log> [thing] [boss]: a thing whose blow the game credits to its caster (guardian_goo
-- lands and calls GetAttacked(caster) - shadow_goo.lua:91), so no "[tr_haz] ... HIT" of its own and never checked
-- by replay_haz: where each landed (its last place, low, before it went), and every blow on you by the caster
-- the same tick - how far you were from the landing. Prints the distances struck and not struck within 3.
local IN, THING, BOSS = arg[1], arg[2] or "guardian_goo", arg[3] or "minotaur"
local last = {}       -- guid -> { t, x, z, y }
local lands = {}      -- { t, x, z }
local hits = {}       -- { t, yx, yz }
local yous = {}       -- t -> { x, z } ("_you" lines)
local N = "(%-?[%d%.]+)"
for l in io.lines(IN) do
    local t, g, x, z, y = l:match("%[tr_haz%] " .. N .. " " .. THING .. " guid=(%d+) pos=" .. N .. "," .. N .. " .- y=" .. N)
    -- (and how high it went: one gone where it was made, never up, didn't land - not counted)
    if t then
        local top = math.max(last[g] and last[g][5] or 0, tonumber(y))
        last[g] = { tonumber(t), tonumber(x), tonumber(z), tonumber(y), top }
    end
    local tg, gg = l:match("%[tr_haz%] " .. N .. " " .. THING .. " guid=(%d+) GONE")
    if gg == nil then tg, gg = l:match("%[tr_ent%] " .. N .. " gone " .. THING .. " (%d+)") end
    if gg and last[gg] then
        local p = last[gg]
        if p[5] > 1 and p[4] < 1.5 then lands[#lands + 1] = { tonumber(tg), p[2], p[3], p[4] } else unlanded = (unlanded or 0) + 1 end
        last[gg] = nil
    end
    local ht, hb, yx, yz = l:match("%[tr_hit%] " .. N .. " (%S+) %d+ %S+ %S+ you " .. N .. " " .. N)
    if ht and hb == BOSS then hits[#hits + 1] = { tonumber(ht), tonumber(yx), tonumber(yz) } end
    local ut, ux, uz = l:match("%[tr_haz%] " .. N .. " _you you=" .. N .. "," .. N)
    if ut then yous[ut] = { tonumber(ux), tonumber(uz) } end
end
-- (each landing: you then - the nearest "_you" at or before it; struck if a caster's blow on you within a frame)
-- (each blow: the landing that tick nearest you - two land each tick, 8 times over; a landing so taken is struck)
local struck_d, missed_d = {}, {}
local land_hit = {}
for _, h in ipairs(hits) do
    local best, bd = nil, math.huge
    for i, L in ipairs(lands) do
        if not land_hit[i] and math.abs(h[1] - L[1]) <= 0.05 then
            local d = math.sqrt((h[2] - L[2]) ^ 2 + (h[3] - L[3]) ^ 2)
            if d < bd then best, bd = i, d end
        end
    end
    if best then land_hit[best] = true struck_d[#struck_d + 1] = bd end
end
for i, L in ipairs(lands) do
    if not land_hit[i] then
        local u = yous[string.format("%.3f", L[1])]
        if u then
            local d = math.sqrt((u[1] - L[2]) ^ 2 + (u[2] - L[3]) ^ 2)
            if d < 3 then missed_d[#missed_d + 1] = d end
        end
    end
end
table.sort(struck_d)
table.sort(missed_d)
local function Q(t, q) if #t == 0 then return -1 end return t[math.max(1, math.ceil(#t * q))] end
print(string.format("%s landings %d (gone without landing %d), caster blows %d", THING, #lands, unlanded or 0, #hits))
print(string.format("struck: n=%d dist min %.2f p50 %.2f p90 %.2f max %.2f", #struck_d, Q(struck_d, 0), Q(struck_d, .5), Q(struck_d, .9), Q(struck_d, 1)))
print(string.format("not struck within 3: n=%d dist min %.2f p50 %.2f", #missed_d, Q(missed_d, 0), Q(missed_d, .5)))
