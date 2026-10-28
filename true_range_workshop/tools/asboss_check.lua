-- luajit asboss_check.lua <expanded share log> <thing> <boss>: a thing whose blows the game puts down to its boss
-- (as_boss - the Possessed Varg's flames strike with the warg's combat): each blow on you by the boss, against the
-- thing of that kind nearest you that same tick - how far it was. Two passes: a thing's place that tick may be
-- written after the blow (its lines held back and written together, true_range modmain HazOut) - a pooled flame
-- moved on, taken where it was before, 3.56 off a flame that strikes at most 2.48 (warg_mutated_fx.lua:75-82).
-- Optional 4th/5th args: the tick window around the blow (default -1 1), to see a thing written only after it struck.
local IN, THING, BOSS = arg[1], arg[2], arg[3]
local LO, HI = tonumber(arg[4]) or -1, tonumber(arg[5]) or 1
local N = "(%-?[%d%.]+)"
local recs = {}   -- tick (frame) -> { { x, z } }
local hits = {}
for l in io.lines(IN) do
    local t, g, x, z = l:match("%[tr_haz%] " .. N .. " " .. THING .. " guid=(%d+) pos=" .. N .. "," .. N)
    if t then
        local f = math.floor(tonumber(t) * 30 + .5)
        recs[f] = recs[f] or {}
        table.insert(recs[f], { tonumber(x), tonumber(z) })
    end
    local ht, hb, yx, yz = l:match("%[tr_hit%] " .. N .. " (%S+) %d+ %S+ %S+ you " .. N .. " " .. N)
    if ht and hb == BOSS then hits[#hits + 1] = { tonumber(ht), tonumber(yx), tonumber(yz) } end
end
local dists = {}
for _, h in ipairs(hits) do
    local f = math.floor(h[1] * 30 + .5)
    local bd = math.huge
    for df = LO, HI do
        for _, p in ipairs(recs[f + df] or {}) do
            bd = math.min(bd, math.sqrt((p[1] - h[2]) ^ 2 + (p[2] - h[3]) ^ 2))
        end
    end
    if bd < 8 then dists[#dists + 1] = bd end
end
table.sort(dists)
local function Q(q) return dists[math.max(1, math.ceil(#dists * q))] or -1 end
print(string.format("%s blows by %s, a %s there that tick: %d of %d", BOSS, BOSS, THING, #dists, #hits))
print(string.format("  nearest one struck from: p50 %.2f p90 %.2f p99 %.2f max %.2f", Q(.5), Q(.9), Q(.99), Q(1)))
local over = 0
for _, d in ipairs(dists) do if d > 2.5 then over = over + 1 end end
print(string.format("  over 2.5: %d", over))
