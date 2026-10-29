-- luajit tools/frame_check.lua <client_log> [prefab] [-v]
-- Every shape the player's game drew, frame by frame ([tr_lagframe], tr_lagjoin), checked for what a shape never does in one
-- go of a move: it changes smoothly - so anything that goes and comes back, or leaps, is an anomaly. The player, 2026-10-29:
-- "why not a check for anomalies - frames that are wrong, going the wrong way; normally it's continuous". Per owner (a boss,
-- a thing; its GUID), its pieces (fill, lines, groups) as one shape: reach r (from its area or its group's size) and middle.
-- Flags:
--   POP     size or middle off from both the frame before and after by more than a step - up a frame or two, back again
--   BLINK   drawn, gone 1-3 frames, drawn again within the same move
--   JUMP    middle moved over JUMP_D in a frame, against where its boss went, not as its move changed
--   REVERSE middle went one way, then straight back the other, each step over REV_D (a to-and-fro, its edge a blur)
--   AIM     one go of a move laid from elsewhere, or turned over 45 degrees, in a frame ([tr_lagdraw])
--   PULSE   the glow's brightness up and down again within 3 frames ([tr_lagpulse])
-- Counts per owner and flag; -v lists each with its time and move.
local path, only, verbose = arg[1], nil, false
for i = 2, #arg do if arg[i] == "-v" then verbose = true else only = arg[i] end end
assert(path, "usage: luajit tools/frame_check.lua <client_log> [prefab] [-v]")
local JUMP_D, REV_D, POP_R, POP_D = 1.0, .3, 1.0, 1.0
local FR = 1 / 30

local tracks = {}   -- owner key -> list of { t, r, cx, cz, bx, bz, move }
local move_of = {}  -- prefab..guid -> its move now (tr_lagdraw)
local boss_at = {}  -- prefab..guid -> { x, z } (tr_lagdraw boss, or its body ring's middle)
local pulses = {}   -- style -> list of { t, a }
local gos = {}      -- prefab#guid|go -> { key, move, list of { t, x, z, rot, bx, bz } }
local go_set = {}   -- prefab#guid -> { t, ids } - the goes drawn this frame ([tr_lagdraw] ids)
local parts_of = {} -- prefab -> its offline map's parts drawn now ([tr_lagnote] "parts N")
for line in io.lines(path) do
    local t, pf, guid, rest = line:match("%[tr_lagframe%] ([%d%.]+) ([%w_%?]+) (%d+) (.*)")
    if t ~= nil and (only == nil or pf == only) then
        t = tonumber(t)
        local key = pf .. "#" .. guid
        local tri, area, ax, az, seg, sx, sz, grp, gx, gz, ext = rest:match(
            "tri=(%d+) area=([%d%.]+) at=([%d%.%-]+),([%d%.%-]+) seg=(%d+) at=([%d%.%-]+),([%d%.%-]+) grp=(%d+) at=([%d%.%-]+),([%d%.%-]+) pred=%d+ ext=([%d%.]+)")
        if tri ~= nil then
            local r, cx, cz = 0, nil, nil
            if tonumber(grp) > 0 then r, cx, cz = tonumber(ext) / 2, tonumber(gx), tonumber(gz)
            elseif tonumber(tri) > 0 then r, cx, cz = math.sqrt(tonumber(area) / math.pi), tonumber(ax), tonumber(az) end
            -- (its body ring's middle: where the boss is shown)
            if tonumber(seg) > 0 and pf ~= "?" then boss_at[key] = { tonumber(sx), tonumber(sz) } end
            -- (where its owner is shown, as tr_lagjoin says it from 2026-10-29: " own=x,z,rot" - over all the rest)
            local ox, oz, orot = rest:match(" own=([%d%.%-]+),([%d%.%-]+),([%d%.%-]+)")
            if ox ~= nil then boss_at[key] = { tonumber(ox), tonumber(oz), tonumber(orot) } end
            tracks[key] = tracks[key] or {}
            local b = boss_at[key]
            -- (which goes of its move are drawn: a new one begun (a laser shot again each time its loop starts over, the Twins'
            -- mouth, SimMoves._relock) is a new shape, not the old one leapt - 51 "JUMP"s, lag 1304. OLD_FC_GOES=1: not told)
            local gs = go_set[key]
            local goes = (gs ~= nil and math.abs(gs.t - t) < .001 and not os.getenv("OLD_FC_GOES")) and gs.ids or ""
            -- (and how many parts of its map: one struck and gone (the Werepig's atk3, parts 2 -> 1) shrinks it, its middle on
            -- 1.5 - not a leap, lag 1304)
            if not os.getenv("OLD_FC_PARTS") then goes = goes .. "|" .. (parts_of[pf] or "") end
            -- (and which groups it drew: one thing's drawing taking in other rows far off, one gone and another come - its
            -- mean leapt 31, nothing moved (the Stalker's fossil spikes, lag 1705). tr_lagjoin " gs=". OLD_FC_GS=1: not told)
            if not os.getenv("OLD_FC_GS") then goes = goes .. "|" .. (rest:match(" gs=(%d+)") or "") end
            table.insert(tracks[key], { t = t, r = r, cx = cx, cz = cz, bx = b and b[1], bz = b and b[2], brot = b and b[3], move = (move_of[key] or "-") .. (goes ~= "" and "" or ""), goes = goes,
                pcs = tonumber(tri) * 1000 + tonumber(grp) })
        end
    end
    local dt, dpf, dguid, bx, bz, mv = line:match("%[tr_lagdraw%] ([%d%.]+) ([%w_]+) (%d+) %S+ [%d%.%-]+ [%d%.%-]+ [%d%.%-]+ boss ([%d%.%-]+) ([%d%.%-]+) .*move=(%S+)")
    if dt ~= nil then
        move_of[dpf .. "#" .. dguid] = mv
        boss_at[dpf .. "#" .. dguid] = { tonumber(bx), tonumber(bz) }
        -- (each go of a move (its log's id) on its own: where it's laid from and which way)
        local go, ax, az, rot = line:match("%[tr_lagdraw%] [%d%.]+ [%w_]+ %d+ (%S+) ([%d%.%-]+) ([%d%.%-]+) ([%d%.%-]+) boss")
        local gk0 = dpf .. "#" .. dguid
        local gs = go_set[gk0]
        if gs == nil or math.abs(gs.t - tonumber(dt)) > .001 then gs = { t = tonumber(dt), ids = "" } go_set[gk0] = gs end
        if go ~= nil then
            local ids = {}
            for id in gs.ids:gmatch("[^,]+") do ids[#ids + 1] = id end
            ids[#ids + 1] = go
            table.sort(ids)
            gs.ids = table.concat(ids, ",")
        end
        if go ~= nil and (only == nil or dpf == only) then
            local gk = dpf .. "#" .. dguid .. "|" .. go
            gos[gk] = gos[gk] or { key = dpf .. "#" .. dguid, move = mv, list = {} }
            table.insert(gos[gk].list, { t = tonumber(dt), x = tonumber(ax), z = tonumber(az), rot = tonumber(rot), bx = tonumber(bx), bz = tonumber(bz) })
        end
    end
    local npf, rest_n = line:match("%[tr_lagnote%] [%d%.]+ |([%w_]+) (.*)$")
    if npf ~= nil then
        local ps = {}
        for n in rest_n:gmatch("parts (%d+)") do ps[#ps + 1] = n end
        parts_of[npf] = table.concat(ps, ",")
    end
    local pt, style, a = line:match("%[tr_lagpulse%] ([%d%.]+) (%S+) ([%d%.]+)")
    if pt ~= nil then
        pulses[style] = pulses[style] or {}
        table.insert(pulses[style], { t = tonumber(pt), a = tonumber(a) })
    end
end

local counts, lists = {}, {}
local function Flag(key, kind, f, what)
    counts[key] = counts[key] or {}
    counts[key][kind] = (counts[key][kind] or 0) + 1
    if verbose then
        lists[#lists + 1] = string.format("%-8s %.3f %-32s %-22s %s", kind, f.t, key, f.move, what)
    end
end
local function D(a, b) return math.sqrt((a.cx - b.cx) ^ 2 + (a.cz - b.cz) ^ 2) end
-- (its owner's step and turn from a to b, where told: ", boss went 0.83 turned 180")
local function Own(a, b)
    if not (a.bx and b.bx) then return "" end
    local tr = (a.brot and b.brot) and math.abs((b.brot - a.brot + 180) % 360 - 180) or nil
    return string.format(", boss went %.2f%s", math.sqrt((b.bx - a.bx) ^ 2 + (b.bz - a.bz) ^ 2), tr and string.format(" turned %.0f", tr) or "")
end

for key, L in pairs(tracks) do
    for i = 2, #L do
        local p, c, n = L[i - 1], L[i], L[i + 1]
        -- (the same frame stream: none missing between)
        local steady = c.t - p.t < 1.5 * FR
        -- (the same pieces: one more shape come up beside it (the next leap begun as the last one's landing is still drawn)
        -- moves the middle of them all - no anomaly of either)
        local same_move = p.move == c.move and p.pcs == c.pcs and p.goes == c.goes
        -- POP: off from both sides, both sides alike
        for len = 1, 3 do
            local q = L[i + len]
            if q ~= nil and steady and q.t - L[i + len - 1].t < 1.5 * FR and p.move == q.move then
                local up = true
                for k = i, i + len - 1 do
                    local s = L[k]
                    local off_r = math.min(math.abs(s.r - p.r), math.abs(s.r - q.r))
                    local off_d = (s.cx and p.cx and q.cx) and math.min(D(s, p), D(s, q)) or 0
                    if not (off_r >= POP_R or off_d >= POP_D) then up = false end
                end
                local back = math.abs(p.r - q.r) < .5 and (not (p.cx and q.cx) or D(p, q) < .5)
                if up and back and p.r > 0 then
                    Flag(key, "POP", c, string.format("r %.1f -> %.1f -> %.1f over %d frame(s)", p.r, c.r, q.r, len))
                    break
                end
            end
        end
        -- BLINK: gone 1-3 frames, back in the same move
        if p.r > 0 and c.r == 0 and steady then
            for len = 1, 3 do
                local q = L[i + len]
                if q ~= nil and q.r > 0 and q.t - p.t < (len + 1.5) * FR and q.move == p.move then
                    local all_off = true
                    for k = i, i + len - 1 do if L[k].r > 0 then all_off = false end end
                    if all_off then Flag(key, "BLINK", c, string.format("gone %d frame(s), r %.1f", len, p.r)) break end
                end
            end
        end
        -- JUMP: its middle leapt, its boss didn't, same move
        -- (not one drawing several groups (a thing's draw taking in a row of others): one of them put elsewhere and staying moves
        -- their mean - Charlie's arena spikes, cursed fire, snip fx 6-30 "off", nothing leapt; one gone and back is a POP.
        -- OLD_FC_MULTI=1: counted)
        local multi = (p.pcs % 1000) > 1 and not os.getenv("OLD_FC_MULTI")
        if steady and same_move and p.cx and c.cx and p.r > 0 and c.r > 0 and not key:find("^%?") and not multi then
            local d = D(p, c)
            local bd = (p.bx and c.bx) and math.sqrt((c.bx - p.bx) ^ 2 + (c.bz - p.bz) ^ 2) or 0
            -- (and against how fast it went the frame before - a missile at 19 a second goes .6 a frame, no boss beside it)
            local pp = L[i - 2]
            local was = (pp ~= nil and pp.cx and p.t - pp.t < 1.5 * FR and pp.move == p.move) and D(pp, p) or 0
            if d - math.max(bd, was) > JUMP_D and math.abs(c.r - p.r) < 1 then
                Flag(key, "JUMP", c, string.format("middle %.2f in a frame, boss %.2f%s", d, bd, Own(p, c)))
            end
        end
        -- REVERSE: there and straight back
        if n ~= nil and steady and n.t - c.t < 1.5 * FR and same_move and n.move == c.move and p.cx and c.cx and n.cx
            and math.abs(c.r - p.r) < .3 and math.abs(n.r - c.r) < .3 then
            local d1x, d1z, d2x, d2z = c.cx - p.cx, c.cz - p.cz, n.cx - c.cx, n.cz - c.cz
            local l1, l2 = math.sqrt(d1x * d1x + d1z * d1z), math.sqrt(d2x * d2x + d2z * d2z)
            -- (its boss went just so, each step - the shape on it as it's shown: the Twins' mouth charging, your game going
            -- on its old way a frame or two as it stopped, then put where the server has it, 3.16 in a frame, lag 1139;
            -- the boss as seen did that, not the drawing. OLD_FC_WITHBOSS=1: flagged)
            local function With(a, b, dx, dz)
                if not (a.bx and b.bx) then return false end
                return math.sqrt((b.bx - a.bx - dx) ^ 2 + (b.bz - a.bz - dz) ^ 2) < .35 * math.sqrt(dx * dx + dz * dz) + .1
            end
            local withboss = not os.getenv("OLD_FC_WITHBOSS") and With(p, c, d1x, d1z) and With(c, n, d2x, d2z)
            if l1 > REV_D and l2 > REV_D and (d1x * d2x + d1z * d2z) / (l1 * l2) < -.7 and not withboss then
                Flag(key, "REVERSE", c, string.format("%.2f there, %.2f back%s; then%s", l1, l2, Own(p, c), Own(c, n)))
            end
        end
    end
end
-- AIM: within one go, where it's laid from or which way it points leaping in a frame and staying - its first frame laid
-- before its aim was known (the Ancient Guardian's next leap at 5 degrees, then 29), or a to-and-fro
for _, g in pairs(gos) do
    local L = g.list
    for i = 2, #L do
        local p, c = L[i - 1], L[i]
        if c.t - p.t < 1.5 * FR then
            local dr = math.abs(((c.rot - p.rot) + 180) % 360 - 180)
            local da = math.sqrt((c.x - p.x) ^ 2 + (c.z - p.z) ^ 2)
            local db = math.sqrt((c.bx - p.bx) ^ 2 + (c.bz - p.bz) ^ 2)
            -- (a turn over 45 in a frame - a boss turning as it winds up goes 15-25 a frame, its shape with it)
            if dr > 45 or da - db > JUMP_D then
                Flag(g.key, "AIM", { t = c.t, move = g.move }, string.format("turned %.0f, laid from %.2f on (boss %.2f), frame %d of the go", dr, da, db, i))
            end
        end
    end
end
-- PULSE: the glow up and down again (or down and up) within 3 frames
for style, L in pairs(pulses) do
    for i = 2, #L - 1 do
        local p, c, n = L[i - 1], L[i], L[i + 1]
        if n.t - p.t <= 3 * FR + .001 and math.abs(c.a - p.a) >= .15 and math.abs(n.a - p.a) < .15 then
            Flag("glow:" .. style, "PULSE", { t = c.t, move = "-" }, string.format("%.2f -> %.2f -> %.2f", p.a, c.a, n.a))
        end
    end
end

-- (by kind, its GUIDs together - BY_GUID=1: each on its own)
if not os.getenv("BY_GUID") then
    local merged = {}
    for k, c in pairs(counts) do
        local pf = k:match("^([^#]+)") or k
        merged[pf] = merged[pf] or {}
        for kind, n in pairs(c) do merged[pf][kind] = (merged[pf][kind] or 0) + n end
    end
    counts = merged
end
local keys = {}
for k in pairs(counts) do keys[#keys + 1] = k end
table.sort(keys)
local total = 0
for _, k in ipairs(keys) do
    local parts = {}
    for _, kind in ipairs({ "POP", "BLINK", "JUMP", "REVERSE", "AIM", "PULSE" }) do
        local c = counts[k][kind]
        if c ~= nil then parts[#parts + 1] = kind .. " " .. c total = total + c end
    end
    print(string.format("%-36s %s", k, table.concat(parts, "  ")))
end
if verbose then table.sort(lists) for _, l in ipairs(lists) do print(l) end end
print(total .. " anomalies")
