-- luajit expand_haz.lua <log> [out]: a game log whose things on the ground were written only as they
-- changed ("[tr_haz] t prefab guid=N pos=... you=... y=... scale=...", "... guid=N GONE", and
-- "[tr_haz] t _you you=x,z" once a tick while any is) made a line a tick for each again, as the
-- replays read them: at each "_you", every thing there then, as it last was, where you are then.
-- Older logs (no "_you") left as they are. Written over the log, or to out.
local path, out_path = arg[1], arg[2] or arg[1]
-- (written again within this long (s): filled in between - only if the game wrote a moving thing
-- once every few ticks (true_range modmain MOVE_EVERY > 1). It writes every change now: a tick with
-- no line is one it stood still - not filled. Off)
local FILL_GAP = 0
local lines = {}
for line in io.lines(path) do lines[#lines + 1] = line end
local compact = false
for _, line in ipairs(lines) do
    if line:find("%[tr_haz%] [%d%.]+ _you ") then compact = true break end
end
if not compact then
    print("expand_haz: not written as it changes - left as it is")
    return
end
-- (each thing: what it was from when - its lines in order; GONE: nothing)
local events = {}   -- guid -> { { t, prefab, rest | false } }
for _, line in ipairs(lines) do
    local t, prefab, guid, rest = line:match("%[tr_haz%] ([%d%.]+) ([%w_]+) guid=(%d+) (.*)$")
    -- (the game ends each line it writes with a tab: off)
    if rest ~= nil then rest = rest:gsub("%s+$", "") end
    -- (a line cut short - a print too long for the game, in older logs: left out)
    if t ~= nil and rest ~= "GONE" and not rest:find("^HIT") and not rest:find("scale=[%d%.%-]+$") then t = nil end
    if t ~= nil and not rest:find("^HIT") then
        local ev = events[guid]
        if ev == nil then ev = {} events[guid] = ev end
        ev[#ev + 1] = { tonumber(t), prefab, rest ~= "GONE" and rest or false }
    end
end
-- (a blow on you the game credits to no one ("[tr_hit] t ? 0 ..."): a thing that struck as it went and named no
-- striker - Uncompromising Mode's guardian goo never sets the _caster it strikes for (shadow_goo.lua:73, :91):
-- 32 blows of the Ancient Guardian's belch, never once checked, the player seeing it off, 2026-10-19. Given to
-- the thing gone that tick nearest you, within 2.5 - a "HIT" of its own, as replay_haz reads them)
local gone_at = {}   -- { t, prefab, guid, x, z }
for g, ev in pairs(events) do
    local e = ev[#ev]
    if e ~= nil and not e[3] and #ev >= 2 and ev[#ev - 1][3] then
        local x, z = ev[#ev - 1][3]:match("pos=([%d%.%-]+),([%d%.%-]+)")
        if x ~= nil then gone_at[#gone_at + 1] = { e[1], e[2], g, tonumber(x), tonumber(z) } end
    end
end
local nobody, given = 0, 0
local hit_lines = {}  -- line index -> HIT line made
for i, line in ipairs(lines) do
    local t, yx, yz = line:match("%[tr_hit%] ([%d%.]+) %? 0 %S+ %S+ you ([%d%.%-]+) ([%d%.%-]+)")
    if t ~= nil then
        nobody = nobody + 1
        t, yx, yz = tonumber(t), tonumber(yx), tonumber(yz)
        local best, bd = nil, 2.5
        for _, ga in ipairs(gone_at) do
            if math.abs(ga[1] - t) <= 0.05 then
                local d = math.sqrt((ga[4] - yx) ^ 2 + (ga[5] - yz) ^ 2)
                if d < bd then best, bd = ga, d end
            end
        end
        if best ~= nil then
            given = given + 1
            hit_lines[i] = string.format("[tr_haz] %.3f %s guid=%s HIT pos=%.2f,%.2f you=%.2f,%.2f", t, best[2], best[3], best[4], best[5], yx, yz)
        end
    end
end
local guids = {}
for g in pairs(events) do guids[#guids + 1] = g end
table.sort(guids, function(a, b) return tonumber(a) < tonumber(b) end)
-- (each tick only the things there by then and not gone for good - in guid order as before: every guid the
-- log ever had, each tick, made the biggest share 134 s, 2026-10-18)
local by_first = {}
for _, g in ipairs(guids) do by_first[#by_first + 1] = g end
table.sort(by_first, function(a, b)
    local ta, tb = events[a][1][1], events[b][1][1]
    if ta ~= tb then return ta < tb end
    return tonumber(a) < tonumber(b)
end)
local next_in = 1
local live = {}    -- guids there now, in guid order
local num = {}
for _, g in ipairs(guids) do num[g] = tonumber(g) end
local function Join(g)
    local n, lo, hi = num[g], 1, #live + 1
    while lo < hi do
        local mid = math.floor((lo + hi) / 2)
        if num[live[mid]] < n then lo = mid + 1 else hi = mid end
    end
    table.insert(live, lo, g)
end
local at = {}  -- guid -> index of its latest event so far
local out = {}
local made = 0
for li, line in ipairs(lines) do
    local t, prefab, guid, rest = line:match("%[tr_haz%] ([%d%.]+) ([%w_]+) guid=(%d+) (.*)$")
    if t ~= nil and not rest:find("^HIT") then
        -- (its own line: made again below, at each tick)
    else
        out[#out + 1] = line
        if hit_lines[li] ~= nil then out[#out + 1] = hit_lines[li] end
        local yt, yx, yz = line:match("%[tr_haz%] ([%d%.]+) _you you=([%d%.%-]+),([%d%.%-]+)")
        if yt ~= nil then
            local tt = tonumber(yt)
            while next_in <= #by_first and events[by_first[next_in]][1][1] <= tt + 1e-6 do
                Join(by_first[next_in])
                next_in = next_in + 1
            end
            local k = 1
            while k <= #live do
                local g = live[k]
                local ev = events[g]
                local i = at[g] or 0
                while i < #ev and ev[i + 1][1] <= tt + 1e-6 do i = i + 1 end
                at[g] = i
                local e = ev[i]
                -- (its last, and gone: never written again - out of the live ones)
                local done = e ~= nil and i == #ev and not e[3]
                if done then table.remove(live, k) else k = k + 1 end
                if e ~= nil and e[3] then
                    -- (as it was, but where you are now)
                    local rest2 = e[3]:gsub("you=[%d%.%-]+,[%d%.%-]+", "you=" .. yx .. "," .. yz)
                    -- (only moving, written once every few ticks: on in a straight line to where it
                    -- was written next - its turning the short way round - if that's soon)
                    local nx = ev[i + 1]
                    if nx ~= nil and nx[3] and nx[1] - e[1] <= FILL_GAP and tt > e[1] + 1e-6 then
                        local ax, az, ar = e[3]:match("pos=([%d%.%-]+),([%d%.%-]+) rot=([%d%.%-]+)")
                        local bx, bz, br = nx[3]:match("pos=([%d%.%-]+),([%d%.%-]+) rot=([%d%.%-]+)")
                        if ax ~= nil and bx ~= nil then
                            local f = (tt - e[1]) / (nx[1] - e[1])
                            local dr = (tonumber(br) - tonumber(ar) + 180) % 360 - 180
                            rest2 = rest2:gsub("pos=[%d%.%-]+,[%d%.%-]+ rot=[%d%.%-]+", string.format("pos=%.2f,%.2f rot=%.1f",
                                tonumber(ax) + (tonumber(bx) - tonumber(ax)) * f, tonumber(az) + (tonumber(bz) - tonumber(az)) * f,
                                tonumber(ar) + dr * f))
                        end
                    end
                    out[#out + 1] = string.format("[tr_haz] %s %s guid=%s %s", yt, e[2], g, rest2)
                    made = made + 1
                end
            end
        end
    end
end
local fh = assert(io.open(out_path, "wb"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()
print(string.format("expand_haz: %d things, %d lines made a tick each; blows by no one %d, given to a thing gone then %d", #guids, made, nobody, given))
