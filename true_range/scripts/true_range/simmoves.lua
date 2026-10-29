-- Player side: bosses' attacks as the game's own code makes them, run offline
-- (true_range/moves_sim, made by true_range_workshop/tools/sim_moves.lua): for each move, where
-- it hits with its target at a few distances - drawn for how far its target is now.

local Lines = require("true_range/lines")
local Render = require("true_range/render")
local Data = require("true_range/moves_sim")
-- (and the moves written by hand, true_range/moves_hand - one already there by that name kept)
do
    local ok, hand = pcall(require, "true_range/moves_hand")
    if ok and type(hand) == "table" then
        for prefab, moves in pairs(hand) do
            Data[prefab] = Data[prefab] or {}
            for name, e in pairs(moves) do if Data[prefab][name] == nil then Data[prefab][name] = e end end
        end
    end
end
-- (moves that aim where their target will be, by how fast it goes, as they set off - sim.lead seconds on (true_range/predict,
-- as Frostjaw's dives): the offline runs' target stands still, so not in their data. The Shadow Thrall horns' leap as the
-- Umbral Abomination calls them (SGshadowthrall_horns shrouden_jump: 11 frames on) - drawn on you as you ran, landing ahead:
-- 9 of its 10 "drawn IN but NOT struck" on the lag bench 2026-10-26_2333 - those were its turn, below; the Grim Harrier's
-- pounce (SGcharlie_boss_runner: 16 frames from afar, "attack", 11 near). TR_OLD_AIMLEAD: none)
-- (and the horns' leap turning to you only so far (sim.aim_facing, true_range/predict): its own code's numbers -
-- SGshadowthrall_horns shrouden_jump, frame 0; you read 11 frames on there, so not by sim.lead too)
do
    local fields = {
        charlie_boss_runner = { attack = { lead = 16 / 30 }, attack_quick = { lead = 11 / 30 } },
        shadowthrall_horns = { shrouden_jump = { aim_facing = { turn = 45, min = 3.5, max = 9, free = 7, lead = 11 / 30 } } },
    }
    for prefab, moves in pairs(fields) do
        for name, f in pairs(moves) do
            local e = Data[prefab] ~= nil and Data[prefab][name] or nil
            if e ~= nil then
                for k, v in pairs(f) do
                    if e[k] == nil and not (k == "lead" and rawget(_G, "TR_OLD_AIMLEAD")) then e[k] = v end
                end
            end
        end
    end
end
-- (the shapes drawn ahead of time, if there: true_range_workshop/tools/silhouettes.lua)
local sil_ok, Sil = pcall(require, "true_range/silhouettes")
if not sil_ok or not Render.prerendered then Sil = nil end
local Triangulate = require("true_range/triangulate")
-- (each move, leg, spin and thing set off: the name its shape goes by)
for prefab, moves in pairs(Data) do
    if prefab:sub(1, 1) ~= "_" and type(moves) == "table" then
        for name, e in pairs(moves) do
            if type(e) == "table" then
                e._key = prefab .. "|" .. name
                if e.leg ~= nil then
                    e.leg._key = e._key .. "|leg"
                    if e.leg.finish ~= nil then e.leg.finish._key = e._key .. "|finish" end
                end
            end
        end
    end
end

local SimMoves = {}

local G = Data._grid
local maps = {}   -- entry -> { { dist, cells = { [row * 1000 + col] = true }, runs = { { row, from, to } } } }
local moves = {}  -- prefab -> the moves, as true_range/predict tracks them
local flash_unions = setmetatable({}, { __mode = "k" })  -- a map's steps -> all of them as one

-- (one made the same way as one run offline - a fire hound as a hound: that one's moves)
local function Of(prefab)
    if prefab == nil or prefab:sub(1, 1) == "_" then return nil end
    return Data[prefab] or Data[(Data._alias or {})[prefab] or ""]
end

-- (the one it was run offline as - a fire hound as a hound - or nil)
function SimMoves.AliasOf(prefab)
    return (Data._alias or {})[prefab]
end

function SimMoves.Has(prefab)
    return Of(prefab) ~= nil
end

-- things bosses set off, drawn around themselves as soon as they're there (a crystal falling,
-- a spike trail on its way): prefab -> true
-- (for the replays only: what was made of one thing, frame by frame - TR_TRACE_GUID its GUID, into TR_TRACE_EV)
function SimMoves._Trace(ent, now, what, y, s)
    local ev = rawget(_G, "TR_TRACE_EV")
    if ev == nil or ent == nil or ent.GUID ~= rawget(_G, "TR_TRACE_GUID") then return end
    ev[#ev + 1] = string.format("%.3f %s%s land=%s lobbed=%s rose=%s", now, what, y ~= nil and string.format(" y=%.2f", y) or "",
        s.land ~= nil and string.format("%.2f,%.2f@%.3f", s.land[1], s.land[2], s.land[3]) or "-", tostring(s.lobbed), tostring(s.rose))
end

function SimMoves.Hazards()
    return Data._hazards or {}
end

-- Cells as packed by the tool (sim_moves.lua Pack): numbers in 5-bit pieces, a character each
-- (32 added: more to come); per row that has any: rows on from the last, how many runs, then each
-- run's start (on from the last run's end) and length.
local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"
local DIGIT = {}
for i = 1, #B64 do
    DIGIT[B64:byte(i)] = i - 1
end

local function Unpack(text)
    local map = { cells = {}, runs = {} }
    local pos = 1
    local function Num()
        local v, scale = 0, 1
        while true do
            local d = DIGIT[text:byte(pos)] or 0
            pos = pos + 1
            v = v + (d % 32) * scale
            if d < 32 then
                return v
            end
            scale = scale * 32
        end
    end
    local row = -1
    while pos <= #text do
        row = row + Num()
        local n = Num()
        local last_end = -1
        for _ = 1, n do
            local from = last_end + 1 + Num()
            local to = from + Num()
            table.insert(map.runs, { row, from, to })
            for c = from, to do
                map.cells[row * 1000 + c] = true
            end
            last_end = to
        end
    end
    return map
end

-- a move's maps: { { dist, raw } } - each one's steps unpacked only once it's drawn (MapSteps):
-- every distance of every move at once would be some 50MB
-- (src: which of its map lists - entry.maps, or entry.free: its target out of its way)
local function Decode(entry, src)
    src = src or entry.maps or {}
    local list = maps[src]
    if list ~= nil then
        return list
    end
    list = {}
    local kind = src == entry.free and "free" or "maps"
    for i, m in ipairs(src) do
        if m.same and #list > 0 then
            -- (the same as the distance before: that one again)
            table.insert(list, { dist = m.dist, of = list[#list].of, i = i, kind = kind, path = m.path })
        else
            table.insert(list, { dist = m.dist, of = { raw = m, mirror = entry.mirror }, i = i, kind = kind, path = m.path })
        end
    end
    maps[src] = list
    return list
end

-- a map's steps (MapSteps): { { at (frames from its start), cells, runs } } (the last KEEP unpacked are
-- kept; older ones let go, unpacked again if they're wanted again)
local KEEP = 60
-- (a new distance made at most this often, seconds - all moves together: SimMoves.Draw)
local NEW_EVERY = .5
local NEW_NEAR = 1     -- (one drawn already this near you is good enough while waiting - above)
-- (the distance drawn last kept while it's this near the one wanted - units)
local HOLD = .35
-- (...or this far, one moved on with you - entry.follow)
local FOLLOW_HOLD = 1.5
local budget = { t = nil, n = 0 }
-- (parts as one: each within this many frames of the one before, all within CLUSTER_SPAN)
local CLUSTER_GAP, CLUSTER_SPAN = 2, 4
-- (...and a thin rim round the part before - few of its cells inside it, all four beside them
-- its own - within this many frames of it)
local SLIVER_GAP, SLIVER_INNER = 60, .15
local unpacked = {}
local function MapSteps(map)
    local of = map.of
    if of.steps == nil then
        table.insert(unpacked, of)
        if #unpacked > KEEP then
            table.remove(unpacked, 1).steps = nil
        end
        of.steps = {}
        for _, s in ipairs(of.raw.steps or {}) do
            local cells = Unpack(s.cells or "")
            -- (one whose side is chosen at random (entry.mirror): its other side too - the grid's middle column 160 / 2 (side
            -- -20 + col * .25), each cell laid again across it, the runs made anew from them. Charlie's castlift: a hand
            -- either side at random at frame 37 (SGcharlie_boss sideoffs +-4), run offline on one side; the other struck
            -- with nothing drawn, 6 in a player's game, 2026-10-29)
            if of.mirror then
                local add = {}
                for k in pairs(cells.cells) do
                    local col = k % 1000
                    local row = (k - col) / 1000
                    add[row * 1000 + (160 - col)] = true
                end
                for k in pairs(add) do cells.cells[k] = true end
                local rows = {}
                for k in pairs(cells.cells) do
                    local col = k % 1000
                    local row = (k - col) / 1000
                    rows[row] = rows[row] or {}
                    table.insert(rows[row], col)
                end
                cells.runs = {}
                for row, cols in pairs(rows) do
                    table.sort(cols)
                    local from, to = cols[1], cols[1]
                    for i = 2, #cols + 1 do
                        local c = cols[i]
                        if c ~= nil and c == to + 1 then to = c
                        else table.insert(cells.runs, { row, from, to }) from, to = c, c end
                    end
                end
            end
            table.insert(of.steps, { at = s.at or 0, cells = cells.cells, runs = cells.runs,
                again_anim = s.again_anim, again_at = s.again_at, again_until = s.again_until })
        end
        -- (parts struck a frame or two apart - one swipe sweeping on: one part, shown and gone
        -- together - each its own colour, the edge between them came out a jagged double line)
        local first = nil
        for i, s in ipairs(of.steps) do
            local prev = of.steps[i - 1]
            if prev == nil or s.at - prev.at > CLUSTER_GAP or s.at - first.at > CLUSTER_SPAN then first = s end
            s.cl = first
            first.cl_end = s.at
        end
        -- (and a ring round the part before, struck a few frames on - a ground pound's wave: the
        -- Ancient Guardian's landing, its middle at 59, the ring round it at 65 - each its own part,
        -- its own colours (the wave going out), but the ones before kept, struck, red till the last
        -- ring has struck (keep_until): not the middle gone and a ring left, the shape changing as
        -- it lands. Not made one part with them: every pound's wave went out as one piece. Struck
        -- within RING_GAP frames of it, its middle within RING_OFF cells of that one's)
        local RING_GAP, RING_OFF = 8, 4
        local prev_cl, prev_cells, chain = nil, nil, {}
        for _, s in ipairs(of.steps) do
            if s.cl == s then
                local cells = {}
                for _, u in ipairs(of.steps) do
                    if u.cl == s then for k in pairs(u.cells) do cells[k] = true end end
                end
                if prev_cl ~= nil and s.at - (prev_cl.cl_end or prev_cl.at) <= RING_GAP then
                    local n, inside, ax, az, bx, bz, na, nb = 0, 0, 0, 0, 0, 0, 0, 0
                    for k in pairs(cells) do
                        n = n + 1
                        if prev_cells[k] then inside = inside + 1 end
                        ax, az, na = ax + math.floor(k / 1000), az + k % 1000, na + 1
                    end
                    for k in pairs(prev_cells) do bx, bz, nb = bx + math.floor(k / 1000), bz + k % 1000, nb + 1 end
                    if n > 0 and nb > 0 and inside <= .2 * n and n > nb
                        and math.abs(ax / na - bx / nb) <= RING_OFF and math.abs(az / na - bz / nb) <= RING_OFF then
                        local cl_end = s.cl_end or s.at
                        chain[#chain + 1] = prev_cl
                        for _, u in ipairs(chain) do u.keep_until = cl_end end
                    else
                        chain = {}
                    end
                else
                    chain = {}
                end
                prev_cl, prev_cells = s, cells
            end
        end
        -- (and a part only a cell thin round the one before, struck soon after - Armored Bearger's
        -- butt slam, its edge struck again a few frames on: with that one, not a jagged rim of its
        -- own colour - tests/slivercheck.lua)
        local seen, prev = {}, nil
        local i = 1
        while i <= #of.steps do
            local c = of.steps[i].cl
            local members, own, n = {}, {}, 0
            while i <= #of.steps and of.steps[i].cl == c do
                members[#members + 1] = of.steps[i]
                for k in pairs(of.steps[i].cells) do
                    if not seen[k] and not own[k] then own[k] = true n = n + 1 end
                end
                i = i + 1
            end
            if prev ~= nil and n >= 6 and c.at - (prev.cl_end or prev.at) <= SLIVER_GAP then
                -- (thin: hardly a cell with all four beside it its own - two cells thick at most)
                local inner = 0
                for k in pairs(own) do
                    if own[k - 1] and own[k + 1] and own[k - 1000] and own[k + 1000] then inner = inner + 1 end
                end
                if inner <= SLIVER_INNER * n then
                    for _, s in ipairs(members) do s.cl = prev end
                    prev.cl_end = math.max(prev.cl_end or prev.at, members[#members].at)
                    c = prev
                end
            end
            for _, s in ipairs(members) do for k in pairs(s.cells) do seen[k] = true end end
            prev = c
        end
    end
    return of.steps
end
SimMoves._MapSteps = MapSteps

-- (ahead, side) as seen from (x, z) facing rot: the world point
local function World(x, z, rot, ahead, side)
    local c, s = math.cos(rot), math.sin(rot)
    return x + ahead * c + side * s, z - ahead * s + side * c
end

-- the cells within r of the middle (as a map), made once per reach
local discs = {}
local function Disc(r)
    local key = math.floor(r / G.step + .5)
    local map = discs[key]
    if map == nil then
        map = { cells = {}, runs = {} }
        local mid_row = math.floor(G.side / G.step + .5)
        local mid_col = math.floor(-G.ahead / G.step + .5)
        local n = math.floor(r / G.step)
        for dr = -n, n do
            local half = math.floor(math.sqrt(math.max(0, (r / G.step) ^ 2 - dr * dr)))
            local row, from, to = mid_row + dr, mid_col - half, mid_col + half
            table.insert(map.runs, { row, from, to })
            for c = from, to do
                map.cells[row * 1000 + c] = true
            end
        end
        discs[key] = map
    end
    return map
end

-- A set of cells (key -> true) as runs along each row: { { row, from, to } }
local function RunsOf(set)
    local rows = {}
    for k in pairs(set) do
        local col = k % 1000
        local row = math.floor((k - col) / 1000 + .5)
        rows[row] = rows[row] or {}
        table.insert(rows[row], col)
    end
    local runs = {}
    for row, cols in pairs(rows) do
        table.sort(cols)
        local from, to = cols[1], cols[1]
        for i = 2, #cols + 1 do
            local c = cols[i]
            if c ~= nil and c == to + 1 then
                to = c
            else
                table.insert(runs, { row, from, to })
                from, to = c, c
            end
        end
    end
    return runs
end

-- The band along a map's edge, lightly: BAND_IN cells inside it and BAND_OUT outside - right at
-- its edge a frame either way, where it lands that time, or a step you take before it strikes,
-- decides it (in game: struck or not, the Werepig's slam within half a unit of its edge both).
-- { inner = cells of the map in it, runs = the whole band }, made once per map.
local BAND_IN, BAND_OUT = 1, 0
local NO_BAND = { inner = {}, runs = {} }
local function Band(map)
    -- (true_range/render: band - off, the move's own cells to its edge)
    if not Render.band then
        return NO_BAND
    end
    if map.band ~= nil then
        return map.band
    end
    local inner, outer = {}, {}
    local reach = math.max(BAND_IN, BAND_OUT)
    for k in pairs(map.cells) do
        local col = k % 1000
        local row = math.floor((k - col) / 1000 + .5)
        for dr = -reach, reach do
            for dc = -reach, reach do
                local d2 = dr * dr + dc * dc
                if col + dc >= 0 and col + dc < 1000 then
                    local nk = (row + dr) * 1000 + col + dc
                    if not map.cells[nk] then
                        -- (a cell outside this near: this one's in the band, and so is that)
                        if d2 <= BAND_IN * BAND_IN + 1 then inner[k] = true end
                        if BAND_OUT > 0 and d2 <= BAND_OUT * BAND_OUT + 1 then outer[nk] = true end
                    end
                end
            end
        end
    end
    local all = {}
    for k in pairs(inner) do all[k] = true end
    for k in pairs(outer) do all[k] = true end
    map.band = { inner = inner, runs = RunsOf(all) }
    return map.band
end

-- Runs { row, from, to } joined row over row into blocks { row, from, to, rows } where the next
-- row's run is all but the same (a cell either end) - each drawn as one piece, not a row each:
-- a little off at its sides, under the band anyway; at most RECT_ROWS rows.
local RECT_ROWS = 40
local function Rects(runs)
    table.sort(runs, function(a, b) return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2]) end)
    local open, out = {}, {}
    for _, r in ipairs(runs) do
        local joined = false
        for i, b in ipairs(open) do
            -- (every row's ends within a cell of each other: no row drawn more than a cell past its own)
            if b.last == r[1] - 1 and b.rows < RECT_ROWS
                and math.max(b.fmax, r[2]) - math.min(b[2], r[2]) <= 1 and math.max(b[3], r[3]) - math.min(b.tmin, r[3]) <= 1 then
                b[2], b[3] = math.min(b[2], r[2]), math.max(b[3], r[3])
                b.fmax, b.tmin = math.max(b.fmax, r[2]), math.min(b.tmin, r[3])
                b.last, b.rows = r[1], b.rows + 1
                joined = true
                break
            end
        end
        if not joined then
            local b = { r[1], r[2], r[3], rows = 1, last = r[1], fmax = r[2], tmin = r[3] }
            table.insert(open, b)
            table.insert(out, b)
        end
        -- (blocks that can't go on any more: let go of)
        for i = #open, 1, -1 do
            if open[i].last < r[1] - 1 then table.remove(open, i) end
        end
    end
    for _, b in ipairs(out) do b[4] = b.rows end
    return out
end

-- A map's cells not in the band of `whole` (the move it's part of): its sure part, as runs.
local cores = setmetatable({}, { __mode = "k" })
-- (left out: the cells of the whole move's edge not wholly inside its smooth outline - under
-- the band, which hides their steps; whole.under caches which)
local UNDER = .85
local Depth, Within -- (below)
local function Under(whole)
    if whole.under ~= nil then return whole.under end
    -- (its edge cells and the ones next in: the smooth line can cut a corner deeper than a cell)
    local near = {}
    for k in pairs(Band(whole).inner) do
        for dr = -1, 1 do
            for dc = -1, 1 do
                local nk = k + dr * 1000 + dc
                if whole.cells[nk] then near[nk] = true end
            end
        end
    end
    local under = {}
    for k in pairs(near) do
        local col = k % 1000
        local row = math.floor((k - col) / 1000 + .5)
        if Depth(whole, row, col) < UNDER or not Within(whole, row, col) then under[k] = true end
    end
    whole.under = under
    return under
end
local function Core(map, whole)
    local per = cores[map]
    if per == nil then
        per = setmetatable({}, { __mode = "k" })
        cores[map] = per
    end
    local runs = per[whole]
    if runs == nil then
        local inner = Render.band and Under(whole) or {}
        -- (a part of one colour among others: its edge cells outside its own smooth line left out
        -- too - the seam goes over the rest)
        local out_own = {}
        if Render.band and map ~= whole then
            for k in pairs(Band(map).inner) do
                local col = k % 1000
                local row = math.floor((k - col) / 1000 + .5)
                if not Within(map, row, col) or Depth(map, row, col) < .45 then out_own[k] = true end
            end
        end
        local keep = {}
        for k in pairs(map.cells) do
            if not inner[k] and not out_own[k] then keep[k] = true end
        end
        runs = Rects(RunsOf(keep))
        per[whole] = runs
    end
    return runs
end
-- The outline round a map's cells (marching squares over the cells' middles: the line runs
-- along the cells' edges, cutting across corners), as pieces { row1, col1, row2, col2 }
-- (fractions of cells). Made once per map.
-- (corners of each 2x2 of cells: top-left 8, top-right 4, bottom-right 2, bottom-left 1; the
-- line joins the middles of these sides: T, R, B, L)
local CASES = {
    [1] = { { "L", "B" } }, [2] = { { "B", "R" } }, [3] = { { "L", "R" } }, [4] = { { "T", "R" } },
    [5] = { { "L", "T" }, { "B", "R" } }, [6] = { { "T", "B" } }, [7] = { { "L", "T" } },
    [8] = { { "L", "T" } }, [9] = { { "T", "B" } }, [10] = { { "T", "R" }, { "L", "B" } },
    [11] = { { "T", "R" } }, [12] = { { "L", "R" } }, [13] = { { "B", "R" } }, [14] = { { "L", "B" } },
}
local SIDE_AT = { T = { 0, .5 }, R = { .5, 1 }, B = { 1, .5 }, L = { .5, 0 } }
-- Pieces { r1, c1, r2, c2 } joined end to end into lines, each straightened (Douglas-Peucker,
-- off by at most SIMPLIFY cells), back as pieces.
local SIMPLIFY = 1
-- (a point's key: a number - the outline's corners lie on half cells)
local function Key2(r, c) return math.floor(r * 2 + .5) * 65536 + math.floor(c * 2 + .5) end
local function Straighten(pts, i, j, out)
    local a, b = pts[i], pts[j]
    local dr, dc = b[1] - a[1], b[2] - a[2]
    local len = math.sqrt(dr * dr + dc * dc)
    local far, at = 0, nil
    for k = i + 1, j - 1 do
        local p = pts[k]
        local d
        if len < 1e-9 then
            d = math.sqrt((p[1] - a[1]) ^ 2 + (p[2] - a[2]) ^ 2)
        else
            d = math.abs((p[1] - a[1]) * dc - (p[2] - a[2]) * dr) / len
        end
        if d > far then far, at = d, k end
    end
    if at ~= nil and far > SIMPLIFY then
        Straighten(pts, i, at, out)
        Straighten(pts, at, j, out)
    else
        table.insert(out, { a[1], a[2], b[1], b[2] })
    end
end
-- A line's points: straightened (Straighten: the corners kept), then smoothed - each corner cut
-- SMOOTH times (Chaikin: a quarter of the way along each side) - so a curve made of cells' corners
-- reads as a curve, not steps; a closed line (its ends the same point) round its join too.
local SMOOTH = 1
local function Smooth(pts, out, rough)
    local kept = {}
    Straighten(pts, 1, #pts, kept)
    for _, p in ipairs(kept) do table.insert(rough, p) end
    local line = { { kept[1][1], kept[1][2] } }
    for _, p in ipairs(kept) do table.insert(line, { p[3], p[4] }) end
    local closed = #line > 3 and math.abs(line[1][1] - line[#line][1]) < 1e-6 and math.abs(line[1][2] - line[#line][2]) < 1e-6
    for _ = 1, SMOOTH do
        if #line < 3 then break end
        local nl = {}
        if not closed then table.insert(nl, line[1]) end
        local n = #line - 1
        for i = 1, n do
            local a, b = line[i], line[i + 1]
            table.insert(nl, { a[1] * .75 + b[1] * .25, a[2] * .75 + b[2] * .25 })
            table.insert(nl, { a[1] * .25 + b[1] * .75, a[2] * .25 + b[2] * .75 })
        end
        if closed then table.insert(nl, nl[1]) else table.insert(nl, line[#line]) end
        line = nl
    end
    for i = 1, #line - 1 do
        table.insert(out, { line[i][1], line[i][2], line[i + 1][1], line[i + 1][2] })
    end
end
local function Simplify(pieces)
    -- (the pieces don't all run the same way round: joined at either end)
    local at = {}
    local function Add(k, p) at[k] = at[k] or {} table.insert(at[k], p) end
    for _, p in ipairs(pieces) do
        Add(Key2(p[1], p[2]), p)
        Add(Key2(p[3], p[4]), p)
    end
    local used, out, rough = {}, {}, {}
    local function Walk(p, r, c)
        -- (from (r, c), one end of p, on as far as it goes)
        local pts = { { r, c } }
        while p ~= nil do
            used[p] = true
            if math.abs(p[1] - r) < 1e-6 and math.abs(p[2] - c) < 1e-6 then r, c = p[3], p[4] else r, c = p[1], p[2] end
            table.insert(pts, { r, c })
            local nxt = nil
            for _, o in ipairs(at[Key2(r, c)] or {}) do
                if not used[o] then nxt = o break end
            end
            p = nxt
        end
        if #pts >= 2 then Smooth(pts, out, rough) end
    end
    -- (open lines from an end first - a point only one piece touches - then the closed loops)
    for _, p in ipairs(pieces) do
        if not used[p] then
            if #at[Key2(p[1], p[2])] == 1 then Walk(p, p[1], p[2])
            elseif #at[Key2(p[3], p[4])] == 1 then Walk(p, p[3], p[4]) end
        end
    end
    for _, p in ipairs(pieces) do
        if not used[p] then Walk(p, p[1], p[2]) end
    end
    return out, rough
end
local function Outline(map)
    if map.outline ~= nil then
        return map.outline
    end
    local min_r, max_r, min_c, max_c = math.huge, -math.huge, math.huge, -math.huge
    for k in pairs(map.cells) do
        local col = k % 1000
        local row = math.floor((k - col) / 1000 + .5)
        min_r, max_r = math.min(min_r, row), math.max(max_r, row)
        min_c, max_c = math.min(min_c, col), math.max(max_c, col)
    end
    local pieces = {}
    local cells = map.cells
    for r = min_r - 1, max_r do
        local up, down = r * 1000, (r + 1) * 1000
        for c = min_c - 1, max_c do
            local i = (cells[up + c] and 8 or 0) + (cells[up + c + 1] and 4 or 0) + (cells[down + c + 1] and 2 or 0)
                + (cells[down + c] and 1 or 0)
            local case = CASES[i]
            if case ~= nil then
                for _, seg in ipairs(case) do
                    local a, b = SIDE_AT[seg[1]], SIDE_AT[seg[2]]
                    pieces[#pieces + 1] = { r + a[1], c + a[2], r + b[1], c + b[2] }
                end
            end
        end
    end
    -- (pieces end to end going the same way: one line)
    local merged = {}
    local by_start = {}
    for _, p in ipairs(pieces) do
        local k = Key2(p[1], p[2])
        by_start[k] = by_start[k] or {}
        table.insert(by_start[k], p)
    end
    local used = {}
    for _, p in ipairs(pieces) do
        if not used[p] then
            used[p] = true
            local q = { p[1], p[2], p[3], p[4] }
            local dr, dc = p[3] - p[1], p[4] - p[2]
            while true do
                local nxt = nil
                for _, o in ipairs(by_start[Key2(q[3], q[4])] or {}) do
                    if not used[o] and math.abs((o[3] - o[1]) - dr) < 1e-6 and math.abs((o[4] - o[2]) - dc) < 1e-6 then
                        nxt = o
                        break
                    end
                end
                if nxt == nil then break end
                used[nxt] = true
                q[3], q[4] = nxt[3], nxt[4]
            end
            table.insert(merged, q)
        end
    end
    -- (then end to end into whole lines, and those straightened where they hardly bend - a curve
    -- of short corner-cuts is many pieces, each drawn as a thing of its own: few, long ones)
    -- (rough: only straightened - for the band, broad enough not to show its corners)
    map.outline, map.rough = Simplify(merged)
    return map.outline
end

local EDGE_OF = { fill = "edge", soon = "edge", fill_light = "edge_light" }
-- (a move that does no harm, only a status - Bearger's yawn putting you to sleep, a web slowing
-- you: drawn in its own colours, the styles' "st_" kin - set while one is drawn)
local status_only = false
local function S(style)
    if status_only and style then return Lines._styles["st_" .. style] ~= nil and ("st_" .. style) or style end
    return style
end
local function StatusOnly(entry)
    local v = entry._status_only
    if v == nil then
        v = entry.effects ~= nil and not (("," .. entry.effects .. ","):find(",harm,", 1, true))
        entry._status_only = v
    end
    return v
end

local Union -- (below)

-- How dark a part is drawn by how soon it strikes (seconds): the next darkest, fading out to
-- what comes last - it reads from dark to light the way the move goes, and the dark moves on
-- as fast as it does.
-- (the part striking next - within this many seconds: all of it yellow, to step out of)
local STRIKE = .5
local HAZ_LEAD = 2   -- (frames a thing's strike is drawn early - DrawHazardInner)
local PATH_LATE = 4  -- (frames a boss's position may come late - SimMoves.Draw's path fit)
local PRELOCK_MIN = .3  -- (gone less than this before it stops aiming: as it is, not moved on - the Werepig's slam, 0.13, shoved back by you)
local PRELOCK_MOVE = 2 -- (how far it may go before it stops aiming, all told, and still be drawn on by that - Klaus' 1.55 leap; not the Werepig sliding 2.2 your way as it winds up, off its offline timing)
local CHAIN_ON, CHAIN_SPEED, CHAIN_TURN = false, 6, math.pi  -- (each frame on from the one before: SimMoves.Draw; at least this fast, units / radians a second - OFF: tried 2026-10-11, the drawing lagged its pin as it moved and caught up in the last frames: jumps 537 -> 731, late warnings 21 -> 31)
-- (a lot sharing whom they strike, you struck by one of it: prefab -> { at, x, z } - when and where
-- that one was set off; the rest of its lot set off within SHARED_WINDOW s and SHARED_NEAR of it)
local shared_struck = {}
local SHARED_WINDOW, SHARED_NEAR = 1, 1.5
local FLOWN_PAST = .5   -- (how far past a part's middle one that flies is before that part is gone)

local FILL_IN, LATER_IN = .8, 1.4  -- (seconds before it strikes: ByTime's colours)
local function ByTime(dt)
    -- (striking now - its damage frames, and a moment after: deep red)
    -- (from a frame before: the move's clock here runs a frame behind the game's (counted from
    -- its animation's start, less a frame) - a strike on its very last frame (the Ancient
    -- Guardian's landing, the end of the Rabbit King's kick) stayed yellow, never red)
    -- (one drawn as maybe - not yet told from the move begun alike (SimMoves.maybe): no nearer
    -- than faint red, never yellow - it was yellow, then gone as the other turned out the one)
    if SimMoves.maybe and dt <= STRIKE then return "fill" end
    if dt <= FRAMES + 1e-6 then return "hit" end
    if dt <= STRIKE then return "strike" end
    if dt <= FILL_IN then return "fill" end
    if dt <= LATER_IN then return "later" end
    return "last"
end

-- Several parts of one move drawn at once (its steps still to strike): one edge round them all,
-- not one each over one another. owner: what they belong to; parts: the maps; ids: which (made
-- once per set of them).
local unions = setmetatable({}, { __mode = "k" })
function Union(owner, parts, ids)
    if #parts == 1 then
        return parts[1]
    end
    local by = unions[owner]
    if by == nil then
        by = {}
        unions[owner] = by
    end
    local key = table.concat(ids, ",")
    local u = by[key]
    if u == nil then
        u = { cells = {}, runs = {} }
        for _, p in ipairs(parts) do
            for k in pairs(p.cells) do u.cells[k] = true end
        end
        by[key] = u
    end
    return u
end

-- The band's strip: each outline piece moved half a cell inwards (made once per map).
local function Strip(map)
    if map.strip ~= nil then
        return map.strip
    end
    local out = {}
    Outline(map)
    for _, p in ipairs(map.rough) do
        local dr, dc = p[3] - p[1], p[4] - p[2]
        local len = math.sqrt(dr * dr + dc * dc)
        if len > 1e-6 then
            local nr, nc = -dc / len, dr / len
            -- (which side is in: a cell's middle just that way from the piece's middle)
            local mr, mc = (p[1] + p[3]) / 2, (p[2] + p[4]) / 2
            local probe = math.floor(mr + nr * .6 + .5) * 1000 + math.floor(mc + nc * .6 + .5)
            if not map.cells[probe] then nr, nc = -nr, -nc end
            table.insert(out, { p[1] + nr * .5, p[2] + nc * .5, p[3] + nr * .5, p[4] + nc * .5 })
        end
    end
    map.strip = out
    return out
end

-- Which way is in from a piece of outline at (mr, mc), normal (nr, nc): the side whose cells are
-- the map's, a little way and further off (one way only - near a corner both may look so: then
-- as the piece before).
local function InSign(map, mr, mc, nr, nc, prev)
    local score = 0
    for _, d in ipairs({ .7, 1.2, 1.7 }) do
        local a = map.cells[math.floor(mr + nr * d + .5) * 1000 + math.floor(mc + nc * d + .5)]
        local b = map.cells[math.floor(mr - nr * d + .5) * 1000 + math.floor(mc - nc * d + .5)]
        if a and not b then score = score + 1 elseif b and not a then score = score - 1 end
    end
    if score > 0 then return 1 elseif score < 0 then return -1 end
    return prev or 1
end
-- The band: a strip BAND_CELLS wide along the inside of the smooth outline (made once per map).
-- (as wide as the outline is - .1, the edge style's: a whole cell's band stuck out past the
-- outline in spikes where it turns sharply, its corners pushed out twice as far)
local BAND_CELLS = .4
-- (and begun where the outline's inside half ends - .05, half its .1, in cells: not under it. Half
-- under it, what showed of the band was .05 wide - under a pixel zoomed out, in and out of sight
-- as the camera moved, as if the two fought over which lay on top)
-- (SimMoves.outline_in: testing, a key in true_range modmain sets it 0 - half under, as it was - to
-- see the two side by side)
SimMoves.outline_in = .2
local function SmoothStrip(map)
    if map.sstrip ~= nil then
        return map.sstrip
    end
    local out, sign = {}, nil
    for _, p in ipairs(Outline(map)) do
        local dr, dc = p[3] - p[1], p[4] - p[2]
        local len = math.sqrt(dr * dr + dc * dc)
        if len > 1e-6 then
            local nr, nc = -dc / len, dr / len
            sign = InSign(map, (p[1] + p[3]) / 2, (p[2] + p[4]) / 2, nr, nc, sign)
            nr, nc = nr * sign, nc * sign
            local h = BAND_CELLS / 2 + SimMoves.outline_in
            table.insert(out, { p[1] + nr * h, p[2] + nc * h, p[3] + nr * h, p[4] + nc * h })
        end
    end
    map.sstrip = out
    return out
end
-- How far in from the smooth outline a cell's middle is (in cells) - for its edge cells.
-- The smooth outline's pieces filed by the rows they cross (for Within) and by the 2x2-cell
-- squares near them (for Depth): only the few nearby looked at, not all (made once per map).
local function Filed(map)
    if map.filed ~= nil then return map.filed end
    local by_row, near = {}, {}
    for _, p in ipairs(Outline(map)) do
        for r = math.floor(math.min(p[1], p[3])), math.ceil(math.max(p[1], p[3])) do
            by_row[r] = by_row[r] or {}
            table.insert(by_row[r], p)
        end
        for r = math.floor(math.min(p[1], p[3]) / 2) - 1, math.floor(math.max(p[1], p[3]) / 2) + 1 do
            for c = math.floor(math.min(p[2], p[4]) / 2) - 1, math.floor(math.max(p[2], p[4]) / 2) + 1 do
                local k = r * 10000 + c
                near[k] = near[k] or {}
                table.insert(near[k], p)
            end
        end
    end
    map.filed = { by_row = by_row, near = near }
    return map.filed
end
-- Whether a cell's middle is inside the smooth outline (its corners cut: a cell there may not be).
function Within(map, r, c)
    local inside = false
    for _, p in ipairs(Filed(map).by_row[math.floor(r)] or {}) do
        local r1, c1, r2, c2 = p[1], p[2], p[3], p[4]
        if (r1 > r) ~= (r2 > r) then
            local cx = c1 + (r - r1) / (r2 - r1) * (c2 - c1)
            if cx > c then inside = not inside end
        end
    end
    return inside
end
-- How far from the smooth outline a cell's middle is (in cells) - up to 2 (further: 2).
function Depth(map, r, c)
    local best = 4
    for _, p in ipairs(Filed(map).near[math.floor(r / 2) * 10000 + math.floor(c / 2)] or {}) do
        local dr, dc = p[3] - p[1], p[4] - p[2]
        local l2 = dr * dr + dc * dc
        local t = l2 > 0 and math.max(0, math.min(1, ((r - p[1]) * dr + (c - p[2]) * dc) / l2)) or 0
        local qr, qc = p[1] + dr * t - r, p[2] + dc * t - c
        best = math.min(best, qr * qr + qc * qc)
    end
    return math.sqrt(best)
end
-- one map's edge: its outline (true_range/render: outline) and the faint band just outside it
local function DrawEdge(map, x, z, rot, style)
    local step = G.step
    if Render.outline then
        local edge = EDGE_OF[style] or "edge"
        for _, p in ipairs(Outline(map)) do
            -- (rows are sideways, columns ahead; cell (row, col)'s middle sits at its whole numbers)
            local x1, z1 = World(x, z, rot, G.ahead + p[2] * step, -G.side + p[1] * step)
            local x2, z2 = World(x, z, rot, G.ahead + p[4] * step, -G.side + p[3] * step)
            Lines.Segment(x1, z1, x2, z2, edge)
        end
    end
    -- (the band: a strip a cell wide along the inside of the outline - drawn along it, a few
    -- long pieces, not cell by cell)
    -- (opaque, each piece a little longer than its stretch: they overlap at the bends, unseen,
    -- with no gap on the outer side)
    if Render.band then
        for _, p in ipairs(SmoothStrip(map)) do
            local x1, z1 = World(x, z, rot, G.ahead + p[2] * step, -G.side + p[1] * step)
            local x2, z2 = World(x, z, rot, G.ahead + p[4] * step, -G.side + p[3] * step)
            Lines.Segment(x1, z1, x2, z2, "edge_zone", step * BAND_CELLS)
        end
    end
end

-- A part's outline where it meets another part - not along the whole move's edge, where the band
-- is (made once per part and whole).
local seams = setmetatable({}, { __mode = "k" })
local function Seams(map, whole)
    local per = seams[map]
    if per == nil then
        per = setmetatable({}, { __mode = "k" })
        seams[map] = per
    end
    local list = per[whole]
    if list == nil then
        list = {}
        for _, p in ipairs(Outline(map)) do
            if Depth(whole, (p[1] + p[3]) / 2, (p[2] + p[4]) / 2) >= 1 then table.insert(list, p) end
        end
        per[whole] = list
    end
    return list
end

-- whether (px, pz) is in one of a map's cells, it seen from (x, z) facing rot
local function InMap(map, x, z, rot, px, pz)
    if px == nil then
        return false
    end
    local dx, dz = px - x, pz - z
    local c, s = math.cos(rot), math.sin(rot)
    local ahead, side = dx * c - dz * s, dx * s + dz * c
    local col = math.floor((ahead - G.ahead) / G.step + .5)
    local row = math.floor((side + G.side) / G.step + .5)
    return map.cells[row * 1000 + col] == true
end

SimMoves._InMap = InMap
-- one map's cells, a row's run at a time, seen from (x, z) facing rot; and whether (px, pz) is
-- in a cell that's hit (edge false: its cells only - the edge drawn round several at once;
-- whole: what they're part of, whose edge band is left to that)
-- A map's smooth outline as closed loops of points (in cells: row, column), and those cut into
-- triangles (made once per map).
local function Tris(map)
    if map.tris ~= nil then return map.tris end
    local loops, cur = {}, nil
    local lr, lc = nil, nil
    for _, p in ipairs(Outline(map)) do
        if cur == nil or math.abs(p[1] - lr) > 1e-4 or math.abs(p[2] - lc) > 1e-4 then
            cur = { { p[2], p[1] } }
            table.insert(loops, cur)
        end
        table.insert(cur, { p[4], p[3] })
        lr, lc = p[3], p[4]
    end
    -- (a loop's last point is its first again: once is enough)
    for _, l in ipairs(loops) do
        local a, b = l[1], l[#l]
        if #l > 1 and math.abs(a[1] - b[1]) < 1e-4 and math.abs(a[2] - b[2]) < 1e-4 then table.remove(l) end
    end
    map.loops = loops
    SimMoves.made = (SimMoves.made or 0) + 1
    map.tris = Triangulate.Loops(loops)
    return map.tris
end
-- A map filled, smooth to its outline: triangles.
local function FillTris(map, x, z, rot, style)
    local step = G.step
    for _, t in ipairs(Tris(map)) do
        -- (x: column - ahead; y: row - aside)
        local ax, az = World(x, z, rot, G.ahead + t[1] * step, -G.side + t[2] * step)
        local bx, bz = World(x, z, rot, G.ahead + t[3] * step, -G.side + t[4] * step)
        local cx, cz = World(x, z, rot, G.ahead + t[5] * step, -G.side + t[6] * step)
        Lines.Tri(ax, az, bx, bz, cx, cz, style)
    end
end
SimMoves._Tris = Tris

local function DrawMap(map, x, z, rot, px, pz, style, edge, whole)
    local step = G.step
    if Render.tris then
        FillTris(map, x, z, rot, style)
        if edge ~= false then
            DrawEdge(map, x, z, rot, style)
        end
        -- (where it meets a part of another colour: its outline, a seam)
        if Render.band and whole ~= nil and map ~= whole then
            for _, p in ipairs(Seams(map, whole)) do
                local x1, z1 = World(x, z, rot, G.ahead + p[2] * step, -G.side + p[1] * step)
                local x2, z2 = World(x, z, rot, G.ahead + p[4] * step, -G.side + p[3] * step)
                Lines.Segment(x1, z1, x2, z2, "edge_seam", step * .5)
            end
        end
        return InMap(map, x, z, rot, px, pz)
    end
    if edge ~= false then
        DrawEdge(map, x, z, rot, style)
    end
    for _, run in ipairs(Core(map, whole or map)) do
        local rows = run[4] or 1
        local side = -G.side + (run[1] + (rows - 1) / 2) * step
        local x1, z1 = World(x, z, rot, G.ahead + run[2] * step - step / 2, side)
        local x2, z2 = World(x, z, rot, G.ahead + run[3] * step + step / 2, side)
        -- (exactly its cells: blocks side by side don't overlap - no darker seams between them)
        Lines.Segment(x1, z1, x2, z2, style, step * rows, true)
    end
    -- (where it meets a part of another colour: a smooth dark seam over its cells' steps)
    if Render.band and whole ~= nil and map ~= whole then
        for _, p in ipairs(Seams(map, whole)) do
            local x1, z1 = World(x, z, rot, G.ahead + p[2] * step, -G.side + p[1] * step)
            local x2, z2 = World(x, z, rot, G.ahead + p[4] * step, -G.side + p[3] * step)
            Lines.Segment(x1, z1, x2, z2, "edge_seam", step * 1.3)
        end
    end
    return InMap(map, x, z, rot, px, pz)
end

-- Several parts of one move (todo: { { map, style, id } }, owner: what they belong to): each
-- one's sure part in its own colour, one edge and band round them all. Whether (px, pz) is in
-- any.
-- The shape drawn ahead of time for `key`, whole, from (x, z) facing rot, coloured `style`:
-- whether there is one.
local SHAPE_OF = { hit = "shape_hit", strike = "shape_strike", fill = "shape_fill", later = "shape_later",
    last = "shape_last", fill_light = "shape_light", flash = "shape_flash" }
local URGENT = { hit = 6, strike = 5, fill = 4, later = 3, last = 2, fill_light = 1 }
local function DrawShape(key, x, z, rot, style)
    local s = Sil ~= nil and key ~= nil and Sil[key] or nil
    if s == nil then
        return false
    end
    local step = G.step
    local wx, wz = World(x, z, rot, G.ahead + (s[3] + (s[5] - 1) / 2) * step, -G.side + (s[2] + (s[4] - 1) / 2) * step)
    -- (its picture: Sil._px pixels a unit; the game's pictures, 150 a unit as drawn)
    Lines.Shape("s" .. s[1], wx, wz, rot / DEGREES, 150 / Sil._px, SHAPE_OF[style] or style, Render.flip_shapes)
    return true
end
SimMoves.DrawShape = DrawShape

-- A move's parts (its steps) cut once into pieces that each are struck by the same steps
-- ("atoms": a cell's steps, all its cells alike), each filled with triangles, and the lines
-- between them - smooth, each made once and shared by the pieces either side, so they meet
-- exactly. Drawn, each piece takes the colour of its step striking soonest: as the move goes on
-- only the colours change - nothing is worked out again (made once per set of parts).
-- (a part: a step's map itself, or a hazard's step holding one)
local function PartCells(e) return e.cells ~= nil and e.cells or e.map.cells end
local atoms_of = setmetatable({}, { __mode = "k" })
-- (how smooth: Taubin passes over the cells' corners; then lines kept within THIN cells)
local SMOOTH_PASSES = 16
local THIN = .45
-- (a line within: up to half a cell - two lines a cell apart still can't cross)
local MAX_MOVE = .5
local MAX_MOVE_OUTER = .6
-- a line's points pts[i..j] kept where it bends more than THIN (Douglas-Peucker) - the points
-- before j into out
local function Thin(pts, i, j, out)
    local a, b = pts[i], pts[j]
    local dr, dc = b[1] - a[1], b[2] - a[2]
    local len = math.sqrt(dr * dr + dc * dc)
    local far, at = 0, nil
    for k = i + 1, j - 1 do
        local p = pts[k]
        local d
        if len < 1e-9 then
            d = math.sqrt((p[1] - a[1]) ^ 2 + (p[2] - a[2]) ^ 2)
        else
            d = math.abs((p[1] - a[1]) * dc - (p[2] - a[2]) * dr) / len
        end
        if d > far then far, at = d, k end
    end
    if at ~= nil and far > THIN then
        Thin(pts, i, at, out)
        Thin(pts, at, j, out)
    else
        out[#out + 1] = a
    end
end
-- (steps striking within BUCKET frames of each other cut it as one - a sweep strikes frame after
-- frame: a few pieces, not one a frame; its colours a frame or two out at most)
local BUCKET = 3
local function Atoms(owner, whole)
    local by = atoms_of[owner]
    if by == nil then
        by = {}
        atoms_of[owner] = by
    end
    local mode = whole and "whole" or "parts"
    local A = by[mode]
    if A ~= nil then return A end
    if SimMoves._mark then SimMoves._mark("start") end
    -- (each cell's buckets - in order, as a key; a label for each different set; whole: all one -
    -- where it may strike, all of it alike)
    local bucket_of, members = {}, {}
    for i, e in ipairs(owner) do
        -- (as they're shown: parts shown as one (MapSteps' clusters) cut as one - else where three
        -- pieces of one colour met, the corner stayed put, the line to the next colour in steps)
        local b = whole and 0 or (e.cl ~= nil and e.cl.at) or (e.at ~= nil and math.floor(e.at / BUCKET) or i)
        bucket_of[i] = b
        members[b] = members[b] or {}
        table.insert(members[b], i)
    end
    local sig = {}
    for i, e in ipairs(owner) do
        local b = bucket_of[i]
        if members[b][1] == i then
            for _, j in ipairs(members[b]) do
                for k in pairs(PartCells(owner[j])) do
                    local s = sig[k]
                    if s == nil then sig[k] = tostring(b)
                    elseif s:sub(-#tostring(b) - 1) ~= "," .. b and s ~= tostring(b) then sig[k] = s .. "," .. b end
                end
            end
        end
    end
    local label_of, atoms = {}, {}
    local label = {}
    for k, s in pairs(sig) do
        local l = label_of[s]
        if l == nil then
            local ids = {}
            for v in s:gmatch("%-?%d+") do
                for _, j in ipairs(members[tonumber(v)]) do ids[#ids + 1] = j end
            end
            l = #atoms + 1
            atoms[l] = { ids = ids }
            label_of[s] = l
        end
        label[k] = l
    end
    if SimMoves._mark then SimMoves._mark("labels") end
    -- the lines between cells of different pieces (and round the outside: piece 0), on the cells'
    -- edges, each going with its piece on its left (corner (i, j): row i - .5, column j - .5)
    local function V(i, j) return (i + 16) * 4096 + (j + 16) end
    local edges, out_of, degree = {}, {}, {}
    local function Edge(i1, j1, i2, j2, left, right)
        local e = { V(i1, j1), V(i2, j2), i1 - .5, j1 - .5, i2 - .5, j2 - .5, left, right }
        edges[#edges + 1] = e
        out_of[e[1]] = out_of[e[1]] or {}
        table.insert(out_of[e[1]], e)
        degree[e[1]] = (degree[e[1]] or 0) + 1
        degree[e[2]] = (degree[e[2]] or 0) + 1
    end
    for k, l in pairs(label) do
        local c = k % 1000
        local r = math.floor((k - c) / 1000 + .5)
        local up, down = label[k - 1000] or 0, label[k + 1000] or 0
        local lf, rt = label[k - 1] or 0, label[k + 1] or 0
        if up ~= l and (up == 0 or l < up) then Edge(r, c, r, c + 1, l, up) end
        if down ~= l and (down == 0 or l < down) then Edge(r + 1, c + 1, r + 1, c, l, down) end
        if lf ~= l and (lf == 0 or l < lf) then Edge(r + 1, c, r, c, l, lf) end
        if rt ~= l and (rt == 0 or l < rt) then Edge(r, c + 1, r + 1, c + 1, l, rt) end
    end
    -- (the other way round, for whichever piece is on the right: to follow lines on from a corner)
    for _, e in ipairs(edges) do
        if e[8] ~= 0 then
            out_of[e[2]] = out_of[e[2]] or {}
            table.insert(out_of[e[2]], { e[2], e[1], e[5], e[6], e[3], e[4], e[8], e[7], back = e })
        end
    end
    if SimMoves._mark then SimMoves._mark("edges") end
    -- every corner smoothed at once (Taubin: each drawn toward the middle of its neighbours on
    -- the line, then pushed a little back out - the steps go, the shape doesn't shrink); where
    -- pieces meet on the outside edge, that corner slides along the edge with it: the edge stays
    -- one smooth curve, however many pieces lie along it; a corner deeper in, where three meet, stays
    local pos, nb, outer_nb, orig = {}, {}, {}, {}
    local function Link(t, a, b)
        t[a] = t[a] or {}
        table.insert(t[a], b)
    end
    for _, e in ipairs(edges) do
        pos[e[1]] = pos[e[1]] or { e[3], e[4] }
        pos[e[2]] = pos[e[2]] or { e[5], e[6] }
        orig[e[1]], orig[e[2]] = orig[e[1]] or { e[3], e[4] }, orig[e[2]] or { e[5], e[6] }
        Link(nb, e[1], e[2]) Link(nb, e[2], e[1])
        if e[8] == 0 then Link(outer_nb, e[1], e[2]) Link(outer_nb, e[2], e[1]) end
    end
    local moving = {}
    for v, list in pairs(nb) do
        local along = #list == 2 and list or (outer_nb[v] ~= nil and #outer_nb[v] == 2 and outer_nb[v]) or nil
        -- (on the outside edge it may go further: nothing else lies just past it)
        local reach = (outer_nb[v] ~= nil and #outer_nb[v] == 2) and MAX_MOVE_OUTER or MAX_MOVE
        if along ~= nil then moving[#moving + 1] = { v, along[1], along[2], { pos[v][1], pos[v][2] }, reach } end
    end
    -- (the points each moves with looked up once, not every pass; where it's moved to kept in two
    -- lists, not a table each; the square root only for one that may have gone too far - a long
    -- charge's lane, thousands of points, was 8-15 ms here, its frame dropped as each was made)
    local n_mv = #moving
    local P, PA, PB, OX, OZ, R, R2 = {}, {}, {}, {}, {}, {}, {}
    for i = 1, n_mv do
        local m = moving[i]
        P[i], PA[i], PB[i] = pos[m[1]], pos[m[2]], pos[m[3]]
        OX[i], OZ[i], R[i] = m[4][1], m[4][2], m[5]
        R2[i] = m[5] * m[5]
    end
    local QX, QZ = {}, {}
    for _ = 1, SMOOTH_PASSES do
        for k = 1, 2 do
            local f = k == 1 and .5 or -.53
            for i = 1, n_mv do
                local p, a, b = P[i], PA[i], PB[i]
                QX[i] = p[1] + f * ((a[1] + b[1]) / 2 - p[1])
                QZ[i] = p[2] + f * ((a[2] + b[2]) / 2 - p[2])
            end
            for i = 1, n_mv do
                local p = P[i]
                -- (never far from its own corner: lines a cell apart can't cross, and what's
                -- drawn stays true to the cells)
                local dr, dc = QX[i] - OX[i], QZ[i] - OZ[i]
                local d2 = dr * dr + dc * dc
                if d2 > R2[i] * .999999 then
                    local d, r = math.sqrt(d2), R[i]
                    if d > r then dr, dc = dr * r / d, dc * r / d end
                end
                p[1], p[2] = OX[i] + dr, OZ[i] + dc
            end
        end
    end
    if SimMoves._mark then SimMoves._mark("smooth") end
    -- chained into lines, each between two pieces, from corner to corner where three or more
    -- meet (or round, closed); each straightened where it hardly bends (its ends kept)
    local used = {}
    local polys = {}
    local function Follow(e0)
        local pts, keys = { pos[e0[1]] }, { e0[1] }
        local e = e0
        local start = e0[1]
        while true do
            used[e.back or e] = true
            pts[#pts + 1] = pos[e[2]]
            keys[#keys + 1] = e[2]
            local v = e[2]
            if v == start or degree[v] ~= 2 then break end
            local nxt = nil
            for _, o in ipairs(out_of[v] or {}) do
                if not used[o.back or o] and o[7] == e[7] and o[8] == e[8] then nxt = o break end
            end
            if nxt == nil then break end
            e = nxt
        end
        local line, raw = {}, {}
        Thin(pts, 1, #pts, line)
        line[#line + 1] = pts[#pts]
        for i, v in ipairs(keys) do raw[i] = orig[v] end
        local thin_raw = {}
        Thin(raw, 1, #raw, thin_raw)
        thin_raw[#thin_raw + 1] = raw[#raw]
        polys[#polys + 1] = { pts = line, raw = thin_raw, left = e0[7], right = e0[8], a = e0[1], b = e[2] }
    end
    for _, e in ipairs(edges) do
        if not used[e] and degree[e[1]] ~= 2 then Follow(e) end
    end
    for _, e in ipairs(edges) do
        if not used[e] then Follow(e) end
    end
    if SimMoves._mark then SimMoves._mark("lines") end
    -- each piece's outline: its lines, the ones with it on the right turned round, end to end
    local starts = {}
    local function Reversed(pts)
        local rev = {}
        for i = #pts, 1, -1 do rev[#rev + 1] = pts[i] end
        return rev
    end
    for _, p in ipairs(polys) do
        for _, side in ipairs({ "left", "right" }) do
            local l = p[side]
            if l ~= 0 then
                local s = { pts = p.pts, raw = p.raw, a = p.a, b = p.b }
                if side == "right" then
                    s = { pts = Reversed(p.pts), raw = Reversed(p.raw), a = p.b, b = p.a }
                end
                starts[l] = starts[l] or {}
                starts[l][s.a] = starts[l][s.a] or {}
                table.insert(starts[l][s.a], s)
            end
        end
    end
    -- (field: "pts", smoothed - or "raw", on the cells' edges)
    local function LoopsOf(l, field)
        local loops = {}
        local done = {}
        for _, list in pairs(starts[l] or {}) do
            for _, s0 in ipairs(list) do
                if not done[s0] then
                    local loop = {}
                    local s = s0
                    local guard = 0
                    while s ~= nil and not done[s] and guard < 10000 do
                        guard = guard + 1
                        done[s] = true
                        local pts = s[field]
                        for i = 1, #pts - 1 do loop[#loop + 1] = { pts[i][2], pts[i][1] } end
                        -- (where it touches itself at a corner - cells corner to corner - the line
                        -- turning furthest towards the piece: loops apart, not one crossing itself)
                        local nxt, best = nil, nil
                        local p1, p2 = s.raw[#s.raw - 1], s.raw[#s.raw]
                        local ix, iy = p2[2] - p1[2], p2[1] - p1[1]
                        for _, o in ipairs(starts[l][s.b] or {}) do
                            if not done[o] then
                                local q1, q2 = o.raw[1], o.raw[2]
                                local ox, oy = q2[2] - q1[2], q2[1] - q1[1]
                                local turn = math.atan2(ix * oy - iy * ox, ix * ox + iy * oy)
                                if best == nil or turn > best then nxt, best = o, turn end
                            end
                        end
                        s = nxt
                    end
                    -- (one passing a point twice - a figure of eight: cut there into loops of
                    -- their own, each passing every point once)
                    local stack, at = {}, {}
                    for _, p in ipairs(loop) do
                        local key = math.floor(p[1] * 1024 + .5) * 1048576 + math.floor(p[2] * 1024 + .5)
                        local i = at[key]
                        if i ~= nil then
                            local sub = {}
                            for j = i, #stack do
                                sub[#sub + 1] = stack[j]
                                at[stack[j].key] = nil
                            end
                            for j = #stack, i, -1 do stack[j] = nil end
                            if #sub >= 3 then loops[#loops + 1] = sub end
                        end
                        stack[#stack + 1] = p
                        p.key = key
                        at[key] = #stack
                    end
                    if #stack >= 3 then loops[#loops + 1] = stack end
                end
            end
        end
        return loops
    end
    local function Area2(loops)
        local a = 0
        for _, l in ipairs(loops) do
            for i = 1, #l do
                local p, q = l[i], l[i % #l + 1]
                a = a + p[1] * q[2] - q[1] * p[2]
            end
        end
        return a / 2
    end
    local function TriArea(tris)
        local a = 0
        for _, t in ipairs(tris) do a = a + math.abs((t[3] - t[1]) * (t[6] - t[2]) - (t[4] - t[2]) * (t[5] - t[1])) / 2 end
        return a
    end
    for l, atom in ipairs(atoms) do
        SimMoves.made = (SimMoves.made or 0) + 1
        local loops = LoopsOf(l, "pts")
        local tris = Triangulate.Loops(loops, true)
        local want = Area2(loops)
        -- (smoothing folded it over itself somewhere - triangles more than it holds: cut on the
        -- cells' own edges instead, a hair off its neighbours' smooth ones)
        if math.abs(TriArea(tris) - want) > .02 * want + .25 then
            SimMoves.fallbacks = (SimMoves.fallbacks or 0) + 1
            loops = LoopsOf(l, "raw")
            tris = Triangulate.Loops(loops, true)
        end
        atom.loops = loops
        atom.tris = tris
    end
    if SimMoves._mark then SimMoves._mark("triangles") end
    A = { atoms = atoms, polys = polys }
    by[mode] = A
    return A
end

-- (reused each frame: no new tables while a move is drawn)
local RANK = { hit = 6, strike = 5, fill = 4, later = 3, last = 2, fill_light = 1 }
local style_of, atom_style = {}, {}
local next_of, atom_next = {}, {}  -- (the parts striking next; each piece: whether it's in one)
local NEXT_APART = 6               -- (frames: that much after what strikes now, its own outline)

-- Where a set of pieces lies in the world, seen from (x, z) facing rot: every triangle's and
-- line's piece worked out once - laid down again each frame while it stays put (a few places
-- kept: one set of parts may be drawn at several - a hazard's, for each of its kind)
-- (lines: per line, per stretch of it { outline, band if drawn on its left, on its right, seam })
-- (worked out round 0, 0 and kept by how it's turned - wherever it is: kept only once it has
-- stayed turned so a frame - one turning, a spin, is drawn straight each frame: no new tables
-- every frame; up to CACHE_PLACES turns kept, then those not used of late let go)
local CACHE_PLACES, SEEN_PLACES = 48, 256
-- (a thing on the ground (DrawHazard): its pieces worked out the first time it's seen - not drawn
-- piece by piece first: the Crystal Deerclops' volley, sixty spikes at once, was 700 pieces made in
-- one frame. It hardly ever turns: kept, not made over each frame as a boss turning to aim)
local build_now = false
local CACHE_IDLE = .5  -- (a place not drawn for this long: let go when the cache is full)
-- (the band's line, in from an edge by 1 (times its half width), corner by corner: where the bands
-- either side of a corner meet - each piece pushed in square to itself, they'd leave a notch at
-- every corner, the edge looking drawn twice) - { { row, col } } per point, kept on the edge
local function Miters(p)
    if p.miter ~= nil then return p.miter end
    local pts = p.pts
    local n = #pts
    local closed = n > 2 and pts[1][1] == pts[n][1] and pts[1][2] == pts[n][2]
    local normals = {}
    for k = 1, n - 1 do
        local dr, dc = pts[k + 1][1] - pts[k][1], pts[k + 1][2] - pts[k][2]
        local len = math.sqrt(dr * dr + dc * dc)
        normals[k] = len > 1e-6 and { dc / len, -dr / len } or false
    end
    local function Near(k, d)
        -- (the nearest piece with a length, that way)
        while k >= 1 and k <= n - 1 do
            if normals[k] then return normals[k] end
            k = k + d
        end
        if closed then
            k = d < 0 and n - 1 or 1
            for _ = 1, n do
                if normals[k] then return normals[k] end
                k = k + d
                if k < 1 then k = n - 1 elseif k > n - 1 then k = 1 end
            end
        end
        return nil
    end
    local out = {}
    for k = 1, n do
        local a, b = Near(k - 1, -1), Near(k, 1)
        if k == 1 and not closed then a = nil end
        if k == n and not closed then b = nil end
        a, b = a or b, b or a
        if a == nil then
            out[k] = { 0, 0 }
        else
            local mr, mc = a[1] + b[1], a[2] + b[2]
            local ml = math.sqrt(mr * mr + mc * mc)
            if ml < 1e-6 then
                out[k] = { a[1], a[2] }
            else
                mr, mc = mr / ml, mc / ml
                local k2 = math.min(2, 1 / math.max(.5, mr * a[1] + mc * a[2]))
                out[k] = { mr * k2, mc * k2 }
            end
        end
    end
    p.miter = out
    return out
end
-- (where two straight pieces of a line meet at an angle, w wide: the wedge between their square
-- ends filled, on both sides - else a notch on the outside of every corner, the ground or the
-- band showing through it, the outline looking broken at each joint as the deep red struck)
-- (a style drawn solid - not see-through; not known: taken as solid)
local function Solid(style)
    local st = Lines._styles ~= nil and Lines._styles[style] or nil
    return st == nil or st.colour == nil or st.colour[4] >= 1
end
local JOIN_SEEN = .02  -- (a notch narrower than this, in units, isn't filled - about a pixel zoomed as usual)
local function JoinTris(ax, az, bx, bz, cx, cz, w, put)
    local d1x, d1z, d2x, d2z = bx - ax, bz - az, cx - bx, cz - bz
    local l1, l2 = math.sqrt(d1x * d1x + d1z * d1z), math.sqrt(d2x * d2x + d2z * d2z)
    if l1 < 1e-6 or l2 < 1e-6 then return false end
    -- (only a notch that would show: as wide as half the line by the turn's angle, under about a
    -- pixel as the game is usually zoomed (JOIN_SEEN) - a smooth curve turns a little at every
    -- point, and every one of them filled was hundreds of pieces more each frame)
    local cross = d1x * d2z - d1z * d2x
    local sin_turn = cross / (l1 * l2)
    if math.abs(sin_turn) * w / 2 < JOIN_SEEN then return false end
    -- (false: only whether there's a corner)
    if put == false then return true end
    -- (and only on the outside of the turn, where the notch is - inside, the two pieces lie over
    -- each other already)
    local h = (cross > 0 and -w or w) / 2
    local n1x, n1z, n2x, n2z = -d1z / l1 * h, d1x / l1 * h, -d2z / l2 * h, d2x / l2 * h
    -- (put: a list - kept, Lines.TriRecs; else a style - laid down now. No function made for each
    -- corner: with the Great Depths Worm's 33 segments each frame that was over half of all the
    -- memory the mod made, the game stopping to clear it - its frames dropped)
    -- (or one piece, a line's square, where the line is solid: from the corner out along the turn's
    -- middle to where the two outer edges meet, as wide as the notch - the two triangles' kite, and
    -- past the outer edges by only w/2 sin^2(half the turn) - 0.004 a round thing's corner: a
    -- third fewer pieces round each shape. Not where the line is see-through: over its two lines,
    -- a darker bead at each corner)
    local mx, mz = n1x + n2x, n1z + n2z
    local ml = math.sqrt(mx * mx + mz * mz)
    local wide = math.sqrt((n1x - n2x) ^ 2 + (n1z - n2z) ^ 2)
    local rx, rz = nil, nil
    if ml > 1e-6 then
        local reach = w * w / (2 * ml)
        rx, rz = bx + mx / ml * reach, bz + mz / ml * reach
    end
    if type(put) == "table" then
        Lines.TriRecs(bx, bz, bx + n1x, bz + n1z, bx + n2x, bz + n2z, put)
        if rx ~= nil then put.square = Lines.SegRec(bx, bz, rx, rz, "edge", wide, true) end
    elseif rx ~= nil and Solid(put) then
        Lines.Segment(bx, bz, rx, rz, put, wide, true)
    else
        Lines.Tri(bx, bz, bx + n1x, bz + n1z, bx + n2x, bz + n2z, put)
    end
    return true
end
-- (points on the ground kept from one call to the next - Placed, DrawStraight: x, z lists)
local SCRATCH = { {}, {}, {}, {}, {}, {}, {}, {} }
-- (a corner's pieces, kept - the points in S[j], S[j + 1]; false: no corner there)
local function JoinRecs(S, j, pk, k, w)
    local X, Z = S[j], S[j + 1]
    if not JoinTris(X[pk], Z[pk], X[k], Z[k], X[k + 1], Z[k + 1], w, false) then return false end
    local out = {}
    JoinTris(X[pk], Z[pk], X[k], Z[k], X[k + 1], Z[k + 1], w, out)
    return out
end
local function PlaceKey(x, z, rot)
    return (math.floor(x * 64 + .5) * 65536 + math.floor(z * 64 + .5)) * 1024 + math.floor(rot * 100 + .5) % 1024
end
local function Placed(A, x, z, rot, edge)
    -- (worked out round 0, 0 - laid down moved to where it is (DrawAtoms): one set for every place
    -- it's at, turned the same - the Great Depths Worm's hundreds of segments, each moving a little
    -- every frame, made a new set each, every frame: the game stalling to clear them away)
    -- (and by its size - a pound's ring drawn bigger as it spreads (DrawHazard: G.step) - and its
    -- outline's style, the outline's width)
    x, z = 0, 0
    local k = PlaceKey(x, z, rot) + math.floor(G.step * 4096 + .5) * 1024
    if A.places == nil then A.places, A.n_places, A.seen, A.n_seen = {}, 0, {}, 0 end
    local C = A.places[k]
    local now = (GetTime or GetStaticTime)()
    if C ~= nil and C.rot == rot and C.step == G.step and C.edge == edge and C.oi == SimMoves.outline_in then C.used = now SimMoves._ch = (SimMoves._ch or 0) + 1 return C end
    local first = A.seen[k]
    if (first == nil or first == now) and not build_now then
        if first == nil then
            if A.n_seen >= SEEN_PLACES then A.seen, A.n_seen = {}, 0 end
            A.seen[k] = now
            A.n_seen = A.n_seen + 1
        end
        return nil
    end
    local step = G.step
    SimMoves._cb = (SimMoves._cb or 0) + 1
    local C = { x = x, z = z, rot = rot, step = step, edge = edge, tris = {}, lines = {}, oi = SimMoves.outline_in }
    for l, atom in ipairs(A.atoms) do
        local recs = {}
        for _, t in ipairs(atom.tris) do
            local ax, az = World(x, z, rot, G.ahead + t[1] * step, -G.side + t[2] * step)
            local bx, bz = World(x, z, rot, G.ahead + t[3] * step, -G.side + t[4] * step)
            local cx, cz = World(x, z, rot, G.ahead + t[5] * step, -G.side + t[6] * step)
            Lines.TriRecs(ax, az, bx, bz, cx, cz, recs)
        end
        C.tris[l] = recs
    end
    local h = -BAND_CELLS / 2  -- (the band just outside what's drawn, the outline outside it: none of them over another)
    local ew = (Lines._styles ~= nil and Lines._styles[edge] ~= nil and Lines._styles[edge].width) or .1
    for i, p in ipairs(A.polys) do
        local list = {}
        local pts = p.pts
        local mi = Miters(p)
        local n = #pts
        local closed = n > 2 and pts[1][1] == pts[n][1] and pts[1][2] == pts[n][2]
        -- (each point on the ground: on the band's middle either side; and the outline's - just
        -- outside what's drawn, on whichever side that is, its inner edge on the line: nothing laid
        -- over anything else - the game sorts its pieces by where they lie as much as by their sort
        -- order, and a fill and its band or edge took turns on top, piece by piece)
        -- (in lists kept from one call to the next, by side: SCRATCH 1-4 the band's x, z either side,
        -- 5-8 the outline's - no table made for each point)
        local oh = BAND_CELLS + ew / 2 / step
        local SC = SCRATCH
        for k = 1, n do
            local a = pts[k]
            for side = 1, 2 do
                local sign = side == 1 and 1 or -1
                local j = side * 2 - 1
                SC[j][k], SC[j + 1][k] = World(x, z, rot, G.ahead + (a[2] + mi[k][2] * h * sign) * step, -G.side + (a[1] + mi[k][1] * h * sign) * step)
                SC[j + 4][k], SC[j + 5][k] = World(x, z, rot, G.ahead + (a[2] - mi[k][2] * oh * sign) * step, -G.side + (a[1] - mi[k][1] * oh * sign) * step)
            end
        end
        for k = 1, n - 1 do
            local a, b = pts[k], pts[k + 1]
            local x1, z1 = World(x, z, rot, G.ahead + a[2] * step, -G.side + a[1] * step)
            local x2, z2 = World(x, z, rot, G.ahead + b[2] * step, -G.side + b[1] * step)
            local dr, dc = b[1] - a[1], b[2] - a[2]
            local len = math.sqrt(dr * dr + dc * dc)
            -- (not stretched past its ends, any of them - the outline's see-through: where two
            -- overlapped at a joint it came out darker, a bead at every joint; meeting end to end on a
            -- smooth line, the gap left at a joint's outer corner is a hair)
            -- (1 and 8: the outline, for what's drawn on the one side or the other)
            local s = { Lines.SegRec(SC[5][k], SC[6][k], SC[5][k + 1], SC[6][k + 1], edge, nil, true) or false, false, false,
                Lines.SegRec(x1, z1, x2, z2, "edge_seam", step * .5) or false }
            s[8] = Lines.SegRec(SC[7][k], SC[8][k], SC[7][k + 1], SC[8][k + 1], edge, nil, true) or false
            if len > 1e-6 then
                -- (the band: in from the line, on whichever side is drawn - left of row/col run:
                -- column -drow, row +dcol)
                for side = 1, 2 do
                    local sign = side == 1 and 1 or -1
                    local m1, m2 = mi[k], mi[k + 1]
                    local u1, w1 = World(x, z, rot, G.ahead + (a[2] + m1[2] * h * sign) * step, -G.side + (a[1] + m1[1] * h * sign) * step)
                    local u2, w2 = World(x, z, rot, G.ahead + (b[2] + m2[2] * h * sign) * step, -G.side + (b[1] + m2[1] * h * sign) * step)
                    s[1 + side] = Lines.SegRec(u1, w1, u2, w2, "edge_zone", step * BAND_CELLS, true) or false
                end
            end
            -- (and where it meets the piece before: the corner filled - 5 the line's, 6 and 7 the
            -- band's either side)
            local pk = k > 1 and k - 1 or (closed and n - 1 or nil)
            if pk ~= nil then
                -- (5 and 9 the outline's either side, 6 and 7 the band's - a list only where there's
                -- a corner)
                s[5] = JoinRecs(SC, 5, pk, k, ew)
                s[9] = JoinRecs(SC, 7, pk, k, ew)
                s[6] = JoinRecs(SC, 1, pk, k, step * BAND_CELLS)
                s[7] = JoinRecs(SC, 3, pk, k, step * BAND_CELLS)
            end
            list[#list + 1] = s
        end
        C.lines[i] = list
    end
    -- (full: those not drawn of late let go - not all: the Great Depths Worm's 33 segments, one
    -- shape at as many places, and its moving ones filling it up, all were made again and again;
    -- all of them only if every one is still in use and there are far too many)
    if A.n_places >= CACHE_PLACES then
        local n = 0
        for key, P in pairs(A.places) do
            if (P.used or 0) < now - CACHE_IDLE then A.places[key] = nil else n = n + 1 end
        end
        A.n_places = n
        if n >= CACHE_PLACES * 4 then A.places, A.n_places = {}, 0 end
    end
    C.used = now
    A.places[k] = C
    A.n_places = A.n_places + 1
    return C
end

-- The same, straight onto the ground - for one not kept (not still a frame yet)
local function DrawStraight(A, x, z, rot, edge)
    local step = G.step
    for l, atom in ipairs(A.atoms) do
        local style = atom_style[l]
        if style then
            for _, t in ipairs(atom.tris) do
                local ax, az = World(x, z, rot, G.ahead + t[1] * step, -G.side + t[2] * step)
                local bx, bz = World(x, z, rot, G.ahead + t[3] * step, -G.side + t[4] * step)
                local cx, cz = World(x, z, rot, G.ahead + t[5] * step, -G.side + t[6] * step)
                Lines.Tri(ax, az, bx, bz, cx, cz, S(style))
            end
        end
    end
    local h = -BAND_CELLS / 2  -- (the band just outside what's drawn, the outline outside it: none of them over another)
    local ew = (Lines._styles ~= nil and Lines._styles[edge] ~= nil and Lines._styles[edge].width) or .1
    for pi, p in ipairs(A.polys) do
        local sl = p.left ~= 0 and atom_style[p.left] or false
        local sr = p.right ~= 0 and atom_style[p.right] or false
        local outer = (sl and not sr) or (sr and not sl)
        -- (or round the part striking next, inside one colour)
        local nextline = sl and sr and sl == sr and p.left ~= 0 and p.right ~= 0 and atom_next[p.left] ~= atom_next[p.right]
        if outer or (sl and sr and sl ~= sr) or nextline then
            local sign = sl and 1 or -1
            local pts = p.pts
            local mi = Miters(p)
            local n = #pts
            local closed = n > 2 and pts[1][1] == pts[n][1] and pts[1][2] == pts[n][2]
            local SC = SCRATCH
            local inband = Render.band
            local oh = BAND_CELLS + ew / 2 / step
            if outer then
                for k = 1, n do
                    local a = pts[k]
                    -- (the outline just outside what's drawn, as Placed has it)
                    SC[5][k], SC[6][k] = World(x, z, rot, G.ahead + (a[2] - mi[k][2] * oh * sign) * step, -G.side + (a[1] - mi[k][1] * oh * sign) * step)
                    SC[1][k], SC[2][k] = World(x, z, rot, G.ahead + (a[2] + mi[k][2] * h * sign) * step, -G.side + (a[1] + mi[k][1] * h * sign) * step)
                end
            end
            local hidden = SimMoves._rg.on and SimMoves._rg.mask[pi] or nil
            for k = 1, n - 1 do
                local a, b = pts[k], pts[k + 1]
                local x1, z1 = World(x, z, rot, G.ahead + a[2] * step, -G.side + a[1] * step)
                local x2, z2 = World(x, z, rot, G.ahead + b[2] * step, -G.side + b[1] * step)
                local pk = k > 1 and k - 1 or (closed and n - 1 or nil)
                -- (well inside another shape: none of its outline here - SimMoves._rg)
                local cut = hidden ~= nil and hidden[k] and outer or nil
                -- (partly inside another: only the stretches outside - its line and band, no corners)
                if type(cut) == "table" then
                    for v = 1, #cut, 2 do
                        local t0, t1 = cut[v], cut[v + 1]
                        if Render.outline then
                            Lines.Segment(SC[5][k] + (SC[5][k + 1] - SC[5][k]) * t0, SC[6][k] + (SC[6][k + 1] - SC[6][k]) * t0,
                                SC[5][k] + (SC[5][k + 1] - SC[5][k]) * t1, SC[6][k] + (SC[6][k + 1] - SC[6][k]) * t1, S(edge), nil, true)
                        end
                        if inband then
                            local m1, m2 = mi[k], mi[k + 1]
                            local u1, w1 = World(x, z, rot, G.ahead + (a[2] + m1[2] * h * sign) * step, -G.side + (a[1] + m1[1] * h * sign) * step)
                            local u2, w2 = World(x, z, rot, G.ahead + (b[2] + m2[2] * h * sign) * step, -G.side + (b[1] + m2[1] * h * sign) * step)
                            Lines.Segment(u1 + (u2 - u1) * t0, w1 + (w2 - w1) * t0, u1 + (u2 - u1) * t1, w1 + (w2 - w1) * t1, S("edge_zone"), step * BAND_CELLS, true)
                        end
                    end
                end
                if outer and pk ~= nil and not cut then
                    -- (its corners filled, as Placed has them)
                    if Render.outline then
                        JoinTris(SC[5][pk], SC[6][pk], SC[5][k], SC[6][k], SC[5][k + 1], SC[6][k + 1], ew, S(edge))
                    end
                    if inband then
                        JoinTris(SC[1][pk], SC[2][pk], SC[1][k], SC[2][k], SC[1][k + 1], SC[2][k + 1], step * BAND_CELLS, S("edge_zone"))
                    end
                end
                if cut then
                elseif outer then
                    local dr, dc = b[1] - a[1], b[2] - a[2]
                    local len = math.sqrt(dr * dr + dc * dc)
                    if Render.outline then Lines.Segment(SC[5][k], SC[6][k], SC[5][k + 1], SC[6][k + 1], S(edge), nil, true) end
                    if inband and len > 1e-6 then
                        local m1, m2 = mi[k], mi[k + 1]
                        local u1, w1 = World(x, z, rot, G.ahead + (a[2] + m1[2] * h * sign) * step, -G.side + (a[1] + m1[1] * h * sign) * step)
                        local u2, w2 = World(x, z, rot, G.ahead + (b[2] + m2[2] * h * sign) * step, -G.side + (b[1] + m2[1] * h * sign) * step)
                        Lines.Segment(u1, w1, u2, w2, S("edge_zone"), step * BAND_CELLS, true)
                    end
                elseif Render.band then
                    Lines.Segment(x1, z1, x2, z2, S("edge_seam"), step * .5)
                end
            end
        end
    end
end

-- (the thing drawn now - SimMoves.DrawHazard: its pieces kept together, a group; nil: none)
local draw_slot = nil
-- (drawn unturned - a round thing (DrawHazardInner): its pieces only; where it strikes, as turned)
local draw_unturned = false
-- (some of it drawn straight, not in groups, this time - not kept as it is: Kept)
local drew_straight = false
-- (the shapes drawn this frame, by their own (a move's go, a thing): where each is, its cells - an
-- outline not laid where it runs well inside another's: two shapes over each other read as one, not
-- as one broken, a line across its inside - Uncompromising Mode's Bearger's rocks come down side by
-- side, the Celestial Champion's stab over its spike trail (VERIFY_PLAN 6.6). This frame's as drawn,
-- last frame's for those not drawn yet; set in DrawAtoms, used in Lay and DrawStraight)
SimMoves._rg = { f = 0, by = setmetatable({}, { __mode = "k" }), mask = {}, cand = {}, nc = 0, sig = "", on = false, act = {}, na = 0 }
-- (a new frame: of those drawn, only last frame's kept in the list looked through - not every one
-- ever drawn and not yet let go, hundreds of a fight's spent shots gone through for every shape)
function SimMoves.RegionsBegin()
    local rg = SimMoves._rg
    rg.f = rg.f + 1
    local n = 0
    for q = 1, rg.na do
        local R = rg.act[q]
        if R.f >= rg.f - 1 then n = n + 1 rg.act[n] = R R.inact = rg.f end
    end
    for q = n + 1, rg.na do rg.act[q] = nil end
    rg.na = n
end
-- (one drawn this frame: in the list, once)
function SimMoves._rg.Active(R)
    local rg = SimMoves._rg
    if R.inact ~= rg.f then rg.na = rg.na + 1 rg.act[rg.na] = R R.inact = rg.f end
end
-- (how far its cells reach from where it's seen from, at this size)
function SimMoves._rg.Bound(map, step, ga, gs)
    if map._rb ~= nil and map._rb_step == step then return map._rb end
    local r = 0
    for key in pairs(map.cells) do
        local row = math.floor((key + 500) / 1000)
        local col = key - row * 1000
        local a, s = ga + col * step, -gs + row * step
        local d = a * a + s * s
        if d > r then r = d end
    end
    map._rb, map._rb_step = math.sqrt(r) + step, step
    return map._rb
end
-- (well inside one of the others met: in a cell of it, the four round it too - not an outline on
-- the other's very edge)
function SimMoves._rg.Inside(wx, wz)
    local rg = SimMoves._rg
    for q = 1, rg.nc do
        local O = rg.cand[q]
        local dx, dz = wx - O.x, wz - O.z
        if dx * dx + dz * dz < O.r * O.r then
            local c, s = O.c, O.s
            local col = math.floor((dx * c - dz * s - O.ga) / O.step + .5)
            local row = math.floor((dx * s + dz * c + O.gs) / O.step + .5)
            local k = row * 1000 + col
            for _, m in ipairs(O.maps) do
                local cells = m.cells
                -- (the four round it too: not on the other's very edge - two shapes all but one over
                -- the other, the edge of each in and out of the other's edge cells, each outline was cut
                -- to dashes)
                if cells[k] and cells[k + 1] and cells[k - 1] and cells[k + 1000] and cells[k - 1000] then return true end
            end
        end
    end
    return false
end
-- (into group g, one of its sets: f fills, e outline and band, s seams - Lay)
local function GroupTri(r, style, g, _, set) Lines.GroupTri(g, r, style, set) end
local function GroupSeg(r, style, g, _, set) Lines.GroupSeg(g, r, style, set) end
-- (what a group holds against what's to be drawn now, noted for the next frame: "same"; false -
-- other pieces (C) or styles of line: laid anew; else which of its sets changed (g.how): fills
-- coloured again (colours) or laid again (fills: a piece now drawn or not), its outline and band
-- (edges: which lines lie round what's drawn), its seams (seams: where two colours meet, or the
-- part striking next) - the rest kept as it is)
local function SameLaid(g, A, C, edge)
    local base = g.sig == C and g.edge == edge and g.st == status_only and g.ver == Lines.version
    if g.sty == nil then g.sty, g.nxt, g.seam, g.outer, g.how = {}, {}, {}, {}, {} end
    local how = g.how
    how.colours, how.fills, how.edges, how.seams = false, false, false, false
    for l = 1, #A.atoms do
        local was, is = g.sty[l], atom_style[l]
        if was ~= is then
            how.colours = true
            if (was == false) ~= (is == false) then how.fills = true end
        end
        g.sty[l], g.nxt[l] = is, atom_next[l]
    end
    for i, p in ipairs(A.polys) do
        local sl = p.left ~= 0 and atom_style[p.left] or false
        local sr = p.right ~= 0 and atom_style[p.right] or false
        local outer = (sl and not sr) or (sr and not sl) and true or false
        local nextline = sl and sr and sl == sr and p.left ~= 0 and p.right ~= 0 and atom_next[p.left] ~= atom_next[p.right]
        local seam = ((sl and sr and sl ~= sr) or nextline) and true or false
        -- (which side is drawn: its outline on that side)
        local side = outer and (sl and 1 or 2) or 0
        if g.outer[i] ~= side then how.edges = true end
        if g.seam[i] ~= seam then how.seams = true end
        g.outer[i], g.seam[i] = side, seam
    end
    -- (its outline's pieces inside another shape now other than when laid: laid again)
    if g.clip ~= SimMoves._rg.sig then how.edges = true end
    g.clip = SimMoves._rg.sig
    g.sig, g.edge, g.st, g.ver = C, edge, status_only, Lines.version
    if not base then return false end
    if not (how.colours or how.edges or how.seams) then return "same" end
    return how
end
-- (its fills coloured again as atom_style says - in the order Lay laid them)
local function Recolour(g, A, C)
    local j = 0
    for l in ipairs(A.atoms) do
        local best = atom_style[l]
        if best then
            local style = S(best)
            for _ in ipairs(C.tris[l]) do
                j = j + 1
                Lines.GroupRecolour(g, Lines.FILL_TRI, j, style)
            end
        end
    end
end
-- Each piece of C laid down, coloured as atom_style says: tri(r, style, a, b, set),
-- seg(r, style, a, b, set) - Lines.PutTri/PutSeg moved to (a, b), or into group a's set (f fills,
-- e outline and band, s seams); only the sets asked for (fills, edges, seams)
-- (a piece of outline (kind "o") or band ("b") of poly i, from point k to k + 1, on the drawn side
-- (sign), as Placed laid it: its ends - for one partly inside another shape, laid in stretches)
SimMoves._rg.Ends = function(A, C, i, k, kind, sign, ew)
    local p = A.polys[i]
    local pts, mi = p.pts, Miters(p)
    local step = C.step
    local a, b = pts[k], pts[k + 1]
    local d = kind == "o" and -(BAND_CELLS + ew / 2 / step) * sign or (-BAND_CELLS / 2) * sign
    local x1, z1 = World(C.x, C.z, C.rot, G.ahead + (a[2] + mi[k][2] * d) * step, -G.side + (a[1] + mi[k][1] * d) * step)
    local x2, z2 = World(C.x, C.z, C.rot, G.ahead + (b[2] + mi[k + 1][2] * d) * step, -G.side + (b[1] + mi[k + 1][1] * d) * step)
    return x1, z1, x2, z2
end
local function Lay(A, C, edge, tri, seg, a, b, fills, edges, seams)
    if fills then
        for l in ipairs(A.atoms) do
            local best = atom_style[l]
            if best then
                for _, r in ipairs(C.tris[l]) do tri(r, S(best), a, b, "f") end
            end
        end
    end
    if not (edges or seams) then return end
    -- the lines between pieces: round what's drawn, its outline and band (on the drawn side);
    -- between two colours, a seam
    for i, p in ipairs(A.polys) do
        local sl = p.left ~= 0 and atom_style[p.left] or false
        local sr = p.right ~= 0 and atom_style[p.right] or false
        local outer = (sl and not sr) or (sr and not sl)
        local nextline = sl and sr and sl == sr and p.left ~= 0 and p.right ~= 0 and atom_next[p.left] ~= atom_next[p.right]
        if (outer and edges) or (not outer and seams and ((sl and sr and sl ~= sr) or nextline)) then
            local band = sl and 2 or 3
            local ol, oj = sl and 1 or 8, sl and 5 or 9
            -- (the dark band inside the edge only if asked (render.band_inside): laid over the fill,
            -- the game drew it under the fill here and over it there)
            local inband = Render.band
            -- (its pieces well inside another shape: not laid - SimMoves._rg)
            local hidden = SimMoves._rg.on and SimMoves._rg.mask[i] or nil
            for q, s in ipairs(C.lines[i]) do
                local hq = outer and hidden ~= nil and hidden[q] or nil
                if hq == true then
                    -- (none of it)
                elseif hq ~= nil then
                    -- (only the stretches outside the others - its line and band, no corners)
                    local sign = sl and 1 or -1
                    local ew = (Lines._styles ~= nil and Lines._styles[edge] ~= nil and Lines._styles[edge].width) or .1
                    for _, kind in ipairs({ "o", "b" }) do
                        if (kind == "o" and Render.outline) or (kind == "b" and inband) then
                            local x1, z1, x2, z2 = SimMoves._rg.Ends(A, C, i, q, kind, sign, ew)
                            for v = 1, #hq, 2 do
                                local t0, t1 = hq[v], hq[v + 1]
                                local r = kind == "o" and Lines.SegRec(x1 + (x2 - x1) * t0, z1 + (z2 - z1) * t0, x1 + (x2 - x1) * t1, z1 + (z2 - z1) * t1, edge, nil, true)
                                    or Lines.SegRec(x1 + (x2 - x1) * t0, z1 + (z2 - z1) * t0, x1 + (x2 - x1) * t1, z1 + (z2 - z1) * t1, "edge_zone", C.step * BAND_CELLS, true)
                                if r then seg(r, S(kind == "o" and edge or "edge_zone"), a, b, "e") end
                            end
                        end
                    end
                elseif outer then
                    if Render.outline and s[ol] then seg(s[ol], S(edge), a, b, "e") end
                    if inband and s[band] then seg(s[band], S("edge_zone"), a, b, "e") end
                    -- (its corners: only where the piece before is round what's drawn too - on
                    -- this same line, so it is)
                    -- (one square where the line is solid, else its two triangles - JoinTris)
                    local js = Render.outline and s[oj] or nil
                    if js then
                        local st = S(edge)
                        if js.square and Solid(st) then seg(js.square, st, a, b, "e") else for _, r in ipairs(js) do tri(r, st, a, b, "e") end end
                    end
                    js = inband and s[band + 4] or nil
                    if js then
                        local st = S("edge_zone")
                        if js.square and Solid(st) then seg(js.square, st, a, b, "e") else for _, r in ipairs(js) do tri(r, st, a, b, "e") end end
                    end
                elseif Render.band and s[4] then
                    seg(s[4], S("edge_seam"), a, b, "s")
                end
            end
        end
    end
end
local function DrawAtoms(owner, todo, x, z, rot, px, pz, edge_style, whole)
    -- (one that may strike anywhere in it: one piece, all one colour - or one that strikes all of
    -- it on and on, a fire circle burning)
    local A = Atoms(owner, whole or edge_style == "fill_light")
    for k in pairs(style_of) do style_of[k] = nil end
    local inside = false
    for _, p in ipairs(todo) do
        style_of[p.id] = p.style
        if not inside and InMap(p.map, x, z, rot, px, pz) then inside = true end
    end
    local edge = EDGE_OF[edge_style or "fill"] or "edge"
    -- each piece: the colour of its part striking soonest, if any still to
    for l, atom in ipairs(A.atoms) do
        local best = false
        for _, id in ipairs(atom.ids) do
            local s = style_of[id]
            if s ~= nil and (best == false or (RANK[s] or 0) > (RANK[best] or 0)) then best = s end
        end
        atom_style[l] = best
    end
    for l = #A.atoms + 1, #atom_style do atom_style[l] = nil end
    -- (the part striking next - not one striking now: its own outline all round, also where it
    -- lies under one striking now - Frostjaw's landing over where it came up, else a bite out of it)
    -- (only one well apart from what strikes now - a blow struck twice a frame apart, the Armored
    -- Bearger's swipe as it lunges, is one: its two strikes' edges drawn one in the other looked
    -- like two shapes)
    local next_rank, hit_at = 0, nil
    for _, p in ipairs(todo) do
        local r = RANK[p.style] or 0
        if p.style ~= "hit" and r > next_rank then next_rank = r end
        if p.style == "hit" and p.map.at ~= nil then hit_at = math.max(hit_at or p.map.at, p.map.at) end
    end
    for k in pairs(next_of) do next_of[k] = nil end
    if hit_at ~= nil then
        for _, p in ipairs(todo) do
            if p.style ~= "hit" and (RANK[p.style] or 0) == next_rank and (p.map.at or 0) - hit_at >= NEXT_APART then
                next_of[p.id] = true
            end
        end
    end
    for l, atom in ipairs(A.atoms) do
        local n = false
        for _, id in ipairs(atom.ids) do if next_of[id] then n = true break end end
        atom_next[l] = n
    end
    for l = #A.atoms + 1, #atom_next do atom_next[l] = nil end
    -- (this shape among the frame's (SimMoves._rg): where it is and its cells; the others it meets;
    -- which pieces of its outline run well inside one of them - not laid (Lay, DrawStraight), and
    -- as that changes, its outline laid again (SameLaid))
    do
        local rg = SimMoves._rg
        local id = draw_slot or owner
        local R = rg.by[id]
        if R == nil then R = { maps = {}, mask = {}, lc = {}, lcx = {}, lcz = {}, lcr = {}, lcm = {} } rg.by[id] = R end
        local wr = draw_unturned and 0 or rot
        R.f, R.x, R.z, R.rot, R.step, R.ga, R.gs = rg.f, x, z, wr, G.step, G.ahead, G.side
        if R.c == nil or R.crot ~= wr then R.c, R.s, R.crot = math.cos(wr), math.sin(wr), wr end
        local rb = 0
        for q = #R.maps, 1, -1 do R.maps[q] = nil end
        for q, p in ipairs(todo) do
            R.maps[q] = p.map
            rb = math.max(rb, rg.Bound(p.map, G.step, G.ahead, G.side))
        end
        R.r = rb
        rg.Active(R)
        rg.nc = 0
        for q = 1, rg.na do
            local O = rg.act[q]
            if O ~= R and O.f >= rg.f - 1 and O.r ~= nil and (O.x - x) ^ 2 + (O.z - z) ^ 2 < (O.r + rb) ^ 2 then
                rg.nc = rg.nc + 1
                rg.cand[rg.nc] = O
            end
        end
        -- (meeting over 3 others - a swarm: its outline not cut where they lie over it - each moving, all of them
        -- worked out again and laid anew every frame: Uncompromising Mode's Bee Queen, 30-60 of her guards'
        -- dive shadows at once, 10-24 ms a frame - "lag with not many monsters", the player 2026-10-22.
        -- TR_OLD_MASKCAP=1: cut however many)
        if rg.nc > 3 and not rawget(_G, "TR_OLD_MASKCAP") then rg.nc = 0 end
        -- (worked out again only if it or one it meets is elsewhere, turned, or other - else as last time:
        -- most frames nothing moves)
        local same = R.lA == A and R.lx == x and R.lz == z and R.lrot == wr and R.lstep == G.step and R.lnc == rg.nc
        if same then
            for q = 1, rg.nc do
                local O = rg.cand[q]
                if R.lc[q] ~= O or R.lcx[q] ~= O.x or R.lcz[q] ~= O.z or R.lcr[q] ~= O.rot or R.lcm[q] ~= O.maps[1] then same = false break end
            end
        end
        if not same then
            R.lA, R.lx, R.lz, R.lrot, R.lstep, R.lnc = A, x, z, wr, G.step, rg.nc
            for q = 1, rg.nc do
                local O = rg.cand[q]
                R.lc[q], R.lcx[q], R.lcz[q], R.lcr[q], R.lcm[q] = O, O.x, O.z, O.rot, O.maps[1]
            end
            for q = rg.nc + 1, #R.lc do R.lc[q] = nil end
            local sig, hid = "", nil
            local mask = R.mask
            for i = #A.polys + 1, #mask do mask[i] = nil end
            if rg.nc > 0 then
                for i, p in ipairs(A.polys) do
                    local m = mask[i]
                    if m == nil then m = {} mask[i] = m end
                    for q in pairs(m) do m[q] = nil end
                    local pts = p.pts
                    for q = 1, #pts - 1 do
                        local a, b = pts[q], pts[q + 1]
                        -- (along it, a cell apart: all of it inside another - none of it laid; some - only
                        -- the stretches outside (from, to, along it), a lane's side running into a rock's ring)
                        local L = math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2)
                        local n = math.max(2, math.ceil(L / 2))
                        local nin, vis, from = 0, nil, 0
                        -- (looked along only if it comes near one of the others at all - its ends, the
                        -- nearest of it to each: most of an outline is nowhere near)
                        local x1, z1 = World(x, z, wr, G.ahead + a[2] * G.step, -G.side + a[1] * G.step)
                        local x2, z2 = World(x, z, wr, G.ahead + b[2] * G.step, -G.side + b[1] * G.step)
                        local dx, dz = x2 - x1, z2 - z1
                        local ll = dx * dx + dz * dz
                        local near = false
                        for c = 1, rg.nc do
                            local O = rg.cand[c]
                            local t = ll > 0 and math.max(0, math.min(1, ((O.x - x1) * dx + (O.z - z1) * dz) / ll)) or 0
                            local px, pz = x1 + dx * t - O.x, z1 + dz * t - O.z
                            if px * px + pz * pz < O.r * O.r then near = true break end
                        end
                        if not near then n = 0 end
                        for u = 1, n do
                            local t = (u - .5) / n
                            -- (on the line between its ends, as turned and moved - the same as worked out each)
                            if rg.Inside(x1 + dx * t, z1 + dz * t) then
                                nin = nin + 1
                                if from ~= nil then
                                    if (u - 1) / n > from then vis = vis or {} vis[#vis + 1], vis[#vis + 2] = from, (u - 1) / n end
                                    from = nil
                                end
                            elseif from == nil then from = (u - 1) / n end
                        end
                        if nin > 0 then
                            if from ~= nil then vis = vis or {} vis[#vis + 1], vis[#vis + 2] = from, 1 end
                            m[q] = vis or true
                            hid = hid or {}
                            hid[#hid + 1] = i * 10000 + q
                            if vis ~= nil then for v = 1, #vis do hid[#hid + 1] = math.floor(vis[v] * 100 + .5) end end
                        end
                    end
                end
            else
                for i = 1, #mask do mask[i] = nil end
            end
            if hid ~= nil then sig = table.concat(hid, ",") end
            R.sig = sig
        end
        rg.sig, rg.on, rg.mask = R.sig, R.sig ~= "", R.mask
    end
    -- (in a group the game turns with it (Lines.turns): its pieces worked out unturned, the group
    -- turned - one set for a shape however it's turned)
    local turns = draw_slot ~= nil and Lines.GroupFor ~= nil and Lines.turns
    local draw_rot = (draw_unturned or turns) and 0 or rot
    local C = Placed(A, x, z, draw_rot, edge)
    if C == nil then
        drew_straight = true
        -- (laid straight, in no group: turned itself, as it's to be seen - worked out unturned for a
        -- group the game turns, it was drawn pointing nowhere (its turning 0) the first frame of
        -- every new shape, then back: every boss's warning flicking off its aim and back as it aimed)
        DrawStraight(A, x, z, draw_unturned and 0 or rot, edge)
        return inside
    end
    -- (a thing's own group - SimMoves.DrawHazard: its pieces laid again only when what's drawn
    -- changed, else only moved - true_range/lines, groups)
    if draw_slot ~= nil and Lines.GroupFor ~= nil then
        local g = Lines.GroupFor(draw_slot, C)
        local how = SameLaid(g, A, C, edge)
        if not how then
            Lines.GroupClear(g)
            Lay(A, C, edge, GroupTri, GroupSeg, g, nil, true, true, true)
            Lines.GroupDone(g)
        elseif how ~= "same" then
            -- (only the sets that changed)
            if how.fills then
                Lines.GroupClear(g, "f")
                Lay(A, C, edge, GroupTri, GroupSeg, g, nil, true, false, false)
                Lines.GroupDone(g, "f")
            elseif how.colours then
                Recolour(g, A, C)
            end
            if how.edges then
                Lines.GroupClear(g, "e")
                Lay(A, C, edge, GroupTri, GroupSeg, g, nil, false, true, false)
                Lines.GroupDone(g, "e")
            end
            if how.seams then
                Lines.GroupClear(g, "s")
                Lay(A, C, edge, GroupTri, GroupSeg, g, nil, false, false, true)
                Lines.GroupDone(g, "s")
            end
        end
        Lines.GroupAt(g, x, z, (draw_unturned and 0 or rot) / DEGREES)
        return inside
    end
    Lay(A, C, edge, Lines.PutTri, Lines.PutSeg, x, z, true, true, true)
    return inside
end
SimMoves._Atoms = Atoms

-- (moves of one boss drawn together, the same frame (SimMoves.MergeBegin/End): two begun alike, both drawn
-- till told apart - the Celestial Champion's chop and summon, the Minotaur's jump and leap - each its own
-- shape, one over the other: darker where they lie over each other, an outline crossing the other's
-- inside. Laid from the same spot the same way: their steps as one list, drawn once - one outline round
-- both, each cell the colour of what strikes there soonest, as a move's own parts (Atoms))
SimMoves._mg = { owners = setmetatable({}, { __mode = "k" }), near = .05, turn = 1 * DEGREES }
local function DrawParts(owner, todo, x, z, rot, px, pz, edge_style, key, whole)
    if #todo == 0 then
        return false
    end
    -- (not a thing set off - its own group, kept from frame to frame; nor one drawn whole ahead of time)
    if SimMoves._mg.list ~= nil and draw_slot ~= nil and Render.tris and not (key ~= nil and (key:sub(1, 8) == "_hazard|" or (Sil ~= nil and Sil[key] ~= nil))) then
        if SimMoves._record ~= nil then
            local copy = {}
            for i, p in ipairs(todo) do local c = {} for k, v in pairs(p) do c[k] = v end copy[i] = c end
            table.insert(SimMoves._record, { todo = copy, x = x, z = z, rot = rot, key = key, step = G.step, owner = SimMoves._draw_owner })
        end
        local inside = false
        local mine = {}
        for i, p in ipairs(todo) do
            mine[i] = { map = p.map, style = p.style, id = p.id }
            if not inside and InMap(p.map, x, z, rot, px, pz) then inside = true end
        end
        SimMoves._mg.list[#SimMoves._mg.list + 1] = { owner = owner, ent_owner = SimMoves._draw_owner, todo = mine, x = x, z = z, rot = rot, px = px, pz = pz, edge = edge_style,
            key = key, whole = whole, slot = draw_slot, unturned = draw_unturned, build = build_now, status = status_only, step = G.step }
        return inside
    end
    return SimMoves._mg.now(owner, todo, x, z, rot, px, pz, edge_style, key, whole)
end
function SimMoves.MergeBegin()
    if SimMoves._mg.list ~= nil then SimMoves.MergeEnd() end
    SimMoves._mg.list = {}
end
function SimMoves.MergeEnd()
    local list = SimMoves._mg.list
    SimMoves._mg.list = nil
    if list == nil then return end
    local done = {}
    for i, a in ipairs(list) do
        if not done[i] then
            local group = { a }
            for j = i + 1, #list do
                local b = list[j]
                if not done[j] and b.step == a.step and math.abs(b.x - a.x) < SimMoves._mg.near and math.abs(b.z - a.z) < SimMoves._mg.near
                    and math.abs((b.rot - a.rot + math.pi) % (2 * math.pi) - math.pi) < SimMoves._mg.turn then
                    group[#group + 1] = b
                    done[j] = true
                end
            end
            local owner, todo, edge, whole = a.owner, a.todo, a.edge, a.whole
            if #group > 1 then
                -- (their steps one list, kept for the same owners - Atoms works it out once)
                local by = SimMoves._mg.owners
                for _, g in ipairs(group) do
                    local nb = by[g.owner]
                    if nb == nil then nb = setmetatable({}, { __mode = "k" }) by[g.owner] = nb end
                    by = nb
                end
                if by.list == nil then
                    local l = {}
                    for _, g in ipairs(group) do for _, e in ipairs(g.owner) do l[#l + 1] = e end end
                    by.list = l
                end
                owner, todo, whole = by.list, {}, true
                local off = 0
                for _, g in ipairs(group) do
                    for _, p in ipairs(g.todo) do todo[#todo + 1] = { map = p.map, style = p.style, id = p.id + off } end
                    off = off + #g.owner
                    -- (one that may strike anywhere in it, all one colour, only if all are; the outline of
                    -- one sure to come over one that may)
                    whole = whole and g.whole
                    if g.edge ~= "fill_light" then edge = g.edge end
                end
            end
            local s0, u0, b0, st0 = draw_slot, draw_unturned, build_now, status_only
            draw_slot, draw_unturned, build_now, status_only = a.slot, a.unturned, a.build, a.status
            -- (drawn after all have been gone through: whose it was then, not the last one's - the replay's record)
            local o0 = SimMoves._draw_owner
            SimMoves._draw_owner = a.ent_owner
            local ok, err = pcall(SimMoves._mg.now, owner, todo, a.x, a.z, a.rot, a.px, a.pz, edge, a.key, whole)
            SimMoves._draw_owner = o0
            draw_slot, draw_unturned, build_now, status_only = s0, u0, b0, st0
            if not ok then error(err, 0) end
        end
    end
end
SimMoves._mg.now = function(owner, todo, x, z, rot, px, pz, edge_style, key, whole)
    -- (testing: what's drawn this frame, for the replay to ask about any spot - nil in the game)
    if SimMoves._record ~= nil then
        -- (a copy: a thing's list is written over the next frame)
        local copy = {}
        for i, p in ipairs(todo) do
            local c = {}
            for k, v in pairs(p) do c[k] = v end
            copy[i] = c
        end
        table.insert(SimMoves._record, { todo = copy, x = x, z = z, rot = rot, key = key, step = G.step, owner = SimMoves._draw_owner })
    end
    -- (its shape drawn ahead of time, whole, in the colour of its part striking soonest)
    if key ~= nil and Sil ~= nil and Sil[key] ~= nil then
        drew_straight = true
        local top, inside = nil, false
        for _, p in ipairs(todo) do
            if top == nil or (URGENT[p.style] or 0) > (URGENT[top] or 0) then top = p.style end
            inside = InMap(p.map, x, z, rot, px, pz) or inside
        end
        DrawShape(key, x, z, rot, top)
        return inside
    end
    if Render.tris then
        return DrawAtoms(owner, todo, x, z, rot, px, pz, edge_style, whole)
    end
    drew_straight = true
    local parts, ids = {}, {}
    for _, p in ipairs(todo) do
        table.insert(parts, p.map)
        table.insert(ids, p.id)
    end
    local whole = Union(owner, parts, ids)
    -- (the parts of one colour as one: one fill, one smooth edge - not each of a laser's many)
    local by_style, order = {}, {}
    for _, p in ipairs(todo) do
        local g = by_style[p.style]
        if g == nil then
            g = { parts = {}, ids = { p.style } }
            by_style[p.style] = g
            table.insert(order, p.style)
        end
        table.insert(g.parts, p.map)
        table.insert(g.ids, p.id)
    end
    local inside = false
    for _, style in ipairs(order) do
        local g = by_style[style]
        local map = #g.parts == 1 and g.parts[1] or Union(owner, g.parts, g.ids)
        inside = DrawMap(map, x, z, rot, px, pz, style, false, whole) or inside
    end
    DrawEdge(whole, x, z, rot, edge_style or "fill")
    return inside
end

-- Cells kept with a part of a move (t.cells: one leg of it, how its legs end), from where that
-- part began (style: "fill", or "fill_light" for one that may not come).
function SimMoves.DrawCells(t, x, z, rot, px, pz, style)
    local map = maps[t]
    if map == nil then
        map = Unpack(t.cells or "")
        maps[t] = map
    end
    if SimMoves._record ~= nil then
        if not rawget(_G, "TR_ASIDE") then table.insert(SimMoves._record, { todo = { { map = map } }, x = x, z = z, rot = rot, step = G.step, owner = SimMoves._draw_owner }) end
    end
    if DrawShape(t._key, x, z, rot, style or "fill") then
        return InMap(map, x, z, rot, px, pz)
    end
    return DrawMap(map, x, z, rot, px, pz, style or "fill")
end

-- A leg (or legs, LegChain) drawn as a wave, as its runs offline are (the Twins' charges): in
-- bands a unit long, each coloured by when it gets there - from along_now (how far on its way it
-- is), at speed, wait seconds before it sets off; one passed by more than its reach: gone. The
-- Eye of Terror as a mouth, the Scion: their legs were one piece, one colour all along
SimMoves._wave_bands = setmetatable({}, { __mode = "k" })
function SimMoves.DrawLegWave(t, x, z, rot, px, pz, along_now, speed, wait, reach)
    local bands = SimMoves._wave_bands[t]
    if bands == nil then
        local map = maps[t]
        if map == nil then
            map = Unpack(t.cells or "")
            maps[t] = map
        end
        -- (each cell by when it comes within its reach - as far on as it is, less how far round
        -- itself it reaches at that cell's side: the fronts round, as its runs offline draw them
        -- (the Twins' charges) - cut straight across, they read as another thing)
        local lo, hi = nil, nil
        for _, r in ipairs(map.runs) do lo = math.min(lo or r[1], r[1]) hi = math.max(hi or r[1], r[1]) end
        local mid_row = lo ~= nil and (lo + hi) / 2 or 0
        local reach = lo ~= nil and (hi - lo) / 2 * G.step or 0
        local BAND = 1.5
        local by = {}
        for _, r in ipairs(map.runs) do
            local row = r[1]
            local side = (row - mid_row) * G.step
            local back = math.sqrt(math.max(0, reach * reach - side * side))
            for col = r[2], r[3] do
                local fr = G.ahead + col * G.step - back
                local b = math.floor(fr / BAND)
                local band = by[b]
                if band == nil then band = { b = b, fr = (b + .5) * BAND, map = { cells = {}, runs = {} }, rows = {} } by[b] = band end
                band.map.cells[row * 1000 + col] = true
                band.rows[row] = band.rows[row] or {}
                table.insert(band.rows[row], col)
            end
        end
        bands = {}
        for _, band in pairs(by) do
            for row, cols in pairs(band.rows) do
                table.sort(cols)
                local from, last = cols[1], cols[1]
                for i = 2, #cols + 1 do
                    local col = cols[i]
                    if col ~= last + 1 then
                        table.insert(band.map.runs, { row, from, last })
                        from = col
                    end
                    last = col
                end
            end
            band.rows = nil
            bands[#bands + 1] = band
        end
        table.sort(bands, function(p, q) return p.b < q.b end)
        bands.reach = reach
        SimMoves._wave_bands[t] = bands
    end
    -- (all its bands as one shape - each its own colour, one edge round them all, as a move's parts
    -- are drawn: each band outlined on its own, the lane came out in stripes with gaps)
    local todo = {}
    for i, band in ipairs(bands) do
        -- (passed: once it's further on than its reach round that front)
        if band.fr >= along_now - 2 * bands.reach - .5 then
            todo[#todo + 1] = { map = band.map, style = ByTime(wait + math.max(0, band.fr - along_now) / math.max(.1, speed)), id = i }
        end
    end
    return DrawParts(bands, todo, x, z, rot, px, pz)
end
-- A whole round area r about (cx, cz), striking eta seconds on - the Scion's supernova in its arena,
-- barrier up: everything in the arena (40 round its middle), not 24 round itself as run offline
-- (no arena there). One piece, past the grid's own 20 either side.
SimMoves._discs = SimMoves._discs or {}
function SimMoves.DrawDisc(cx, cz, r, eta, px, pz)
    -- (kept by r to .05, made from that r - kept by the quarter, made from whichever r came first: a growing ice circle
    -- drawn .1 smaller than it was, a Klaus deer freezing you 2.61 off its middle "undrawn" once the circles before had
    -- made that quarter smaller; 2026-10-28. TR_OLD_DISCKEY: the quarter)
    local key
    if rawget(_G, "TR_OLD_DISCKEY") then key = math.floor(r * 4 + .5)
    else key = -math.floor(r * 20 + .5) r = -key / 20 end
    local d = SimMoves._discs[key]
    if d == nil then
        d = { parts = {} }
        -- (one piece, from its middle: rows and columns past the grid's own (20 either side) are
        -- still told apart - a cell's key is row * 1000 + column, columns well within 500)
        local map = { cells = {}, runs = {} }
        local rows = math.ceil(r / G.step)
        for k = -rows, rows do
            local side = k * G.step
            local w = math.sqrt(math.max(0, r * r - side * side))
            -- (columns from 0: drawn from r further back than its middle - none below 0 are drawn)
            local a0 = math.ceil((r - w) / G.step - .5)
            local a1 = math.floor((r + w) / G.step + .5)
            -- (rows from 0 too: drawn from r - 20 further to its one side - rows below 0 aren't drawn,
            -- that side came out flat, 20 from the middle, not round at 40)
            local rr = math.floor((side + r) / G.step + .5)
            if a1 >= a0 then
                table.insert(map.runs, { rr, a0, a1 })
                for col = a0, a1 do map.cells[rr * 1000 + col] = true end
            end
        end
        d.parts[1] = { map = map, dx = -r - G.ahead, dz = -(r - G.side) }
        SimMoves._discs[key] = d
    end
    local style = ByTime(eta)
    local inside = false
    -- (its fill only - its edge drawn by the caller, a circle: smooth, not a cell's steps)
    for _, p in ipairs(d.parts) do
        if DrawMap(p.map, cx + p.dx, cz + p.dz, 0, px, pz, style, false) then inside = true end
    end
    return inside, style
end
-- A lane r round a line len long from (x, z) the way rot points - round at both ends: all a thing
-- striking r round itself as it runs that far reaches (the Wilting Dragonfly's dash, 6 round it).
-- One piece, as DrawDisc's.
SimMoves._caps = SimMoves._caps or {}
function SimMoves.DrawCapsule(x, z, rot, len, r, style, px, pz)
    local key = math.floor(len * 4 + .5) * 1000 + math.floor(r * 4 + .5)
    local map = SimMoves._caps[key]
    if map == nil then
        map = { cells = {}, runs = {} }
        local rows = math.ceil(r / G.step)
        for k = -rows, rows do
            local side = k * G.step
            local w = math.sqrt(math.max(0, r * r - side * side))
            local a0 = math.ceil((-w - G.ahead) / G.step - .5)
            local a1 = math.floor((len + w - G.ahead) / G.step + .5)
            local row = math.floor((side + G.side) / G.step + .5)
            if a1 >= a0 then
                table.insert(map.runs, { row, a0, a1 })
                for col = a0, a1 do map.cells[row * 1000 + col] = true end
            end
        end
        SimMoves._caps[key] = map
    end
    return DrawMap(map, x, z, rot, px, pz, style or "fill")
end
-- A move that only shoots a dart flying straight (entry.shoots - tools/sim_moves.lua, the frame it shoots its first): a lane
-- from it the way it aims, as long and wide as that dart's (SimMoves.shots[prefab] - modmain's DARTS), by how soon it shoots,
-- till it has - the dart drawn as it flies after. Run as a blow of its own it was a ring as far round it as it shoots - MacTusk's
-- 15, the green tentacle's 20, dark and never striking, the player 2026-10-22; drawn as nothing, a lizardman's spit from 1 off
-- struck before its dart was seen.
SimMoves.shots = SimMoves.shots or {}
function SimMoves.DrawShot(entry, x, z, rot, t, px, pz)
    local at = (entry.first or 0) * FRAMES
    if t == nil or t > at + 2 * FRAMES then return false end
    local d = SimMoves.shots[entry.shoots] or {}
    return SimMoves.DrawCapsule(x, z, rot, d.len or 15, d.width or 1.5, S(ByTime(at - t)), px, pz)
end
-- One leg and the n - 1 after it straight on, as one shape (DrawCells takes it as a leg) - the
-- Scion's dash, twice: two side by side, outlined each, read as two dashes.
-- (finish: and how its legs end, at the end of the last, in it too - the Celestial Champion's dash and
-- the blow it stops with, two shapes over each other at its end, an outline across the lane)
local chains = setmetatable({}, { __mode = "k" })
function SimMoves.LegChain(leg, n, finish)
    if n <= 1 and finish == nil then return leg end
    chains[leg] = chains[leg] or {}
    local ck = finish ~= nil and (n .. "f") or n
    local t = chains[leg][ck]
    if t == nil then
        local function MapOf(x)
            local m = maps[x]
            if m == nil then
                m = Unpack(x.cells or "")
                maps[x] = m
            end
            return m
        end
        local base = MapOf(leg)
        local shift = math.floor(leg.length / G.step + .5)
        local cells, by_row = {}, {}
        local function Add(nk)
            if not cells[nk] then
                cells[nk] = true
                local r = math.floor((nk + 500) / 1000)
                by_row[r] = by_row[r] or {}
                table.insert(by_row[r], nk - r * 1000)
            end
        end
        for k = 0, n - 1 do
            for key in pairs(base.cells) do Add(key + k * shift) end
        end
        if finish ~= nil then
            local fshift = math.floor(leg.length * n / G.step + .5)
            for key in pairs(MapOf(finish).cells) do Add(key + fshift) end
        end
        local runs = {}
        for r, cols in pairs(by_row) do
            table.sort(cols)
            local from, last = cols[1], cols[1]
            for i = 2, #cols + 1 do
                local c = cols[i]
                if c ~= last + 1 then
                    runs[#runs + 1] = { r, from, last }
                    from = c
                end
                last = c
            end
        end
        table.sort(runs, function(p, q) return p[1] < q[1] or (p[1] == q[1] and p[2] < q[2]) end)
        t = { length = leg.length * n }
        maps[t] = { cells = cells, runs = runs }
        chains[leg][ck] = t
    end
    return t
end

-- A move that chases its target to the end (entry.around): where it goes can't be told - what
-- it hits round itself, wherever it is now.
local arounds = {}
-- t: seconds since the move began - coloured by when it first strikes (entry.first), and on
-- from then (it strikes again and again as it goes) as striking.
-- (and swept on ahead of it by `k` cells - where it's coming, at the speed it's coming: the
-- Celestial Champion's spin rushing at you was drawn only round where it was, under you only as it
-- got there)
local swept = setmetatable({}, { __mode = "k" })
local function Swept(map, k)
    if k <= 0 then return map end
    swept[map] = swept[map] or {}
    local s = swept[map][k]
    if s ~= nil then return s end
    local cells, by_row = {}, {}
    for key in pairs(map.cells) do
        for i = 0, k do
            local nk = key + i
            if not cells[nk] then
                cells[nk] = true
                local r = math.floor((nk + 500) / 1000)
                by_row[r] = by_row[r] or {}
                table.insert(by_row[r], nk - r * 1000)
            end
        end
    end
    local runs = {}
    for r, cols in pairs(by_row) do
        table.sort(cols)
        local from, last = cols[1], cols[1]
        for i = 2, #cols + 1 do
            local c = cols[i]
            if c ~= last + 1 then
                runs[#runs + 1] = { r, from, last }
                from = c
            end
            last = c
        end
    end
    table.sort(runs, function(p, q) return p[1] < q[1] or (p[1] == q[1] and p[2] < q[2]) end)
    s = { cells = cells, runs = runs }
    swept[map][k] = s
    return s
end
function SimMoves.DrawAround(entry, x, z, rot, px, pz, t, ahead)
    local map = arounds[entry]
    if map == nil then
        map = Unpack(entry.around or "")
        arounds[entry] = map
    end
    -- (ahead: how far on it's coming, in half units - a few shapes made, not one every frame)
    local k = math.floor((ahead or 0) * 2 + .5)
    if k > 0 then
        map = Swept(map, math.floor(k * .5 / G.step + .5))
    end
    if SimMoves._record ~= nil then
        if not rawget(_G, "TR_ASIDE") then table.insert(SimMoves._record, { todo = { { map = map } }, x = x, z = z, rot = rot, step = G.step, owner = SimMoves._draw_owner }) end
    end
    local style = t ~= nil and entry.first ~= nil and ByTime(entry.first * FRAMES - t) or "fill"
    if k == 0 and DrawShape(entry._key ~= nil and (entry._key .. "|around") or nil, x, z, rot, style) then
        return InMap(map, x, z, rot, px, pz)
    end
    return DrawMap(map, x, z, rot, px, pz, style)
end

-- Things bosses set off hit in steps (a wall's spikes, pair by pair): each step shown until it
-- has hit. The first comes `delay` frames after the thing appears - or, for one that moves (a
-- spike trail), once it stops.
local hazard_steps = {}                                    -- prefab -> { { at, map } }
local LINGER = .2
-- (where a running spike trail's wall may come up: drawn as one wide line - off, cells only
-- for now)
local SHOW_STRETCH = false
local seen = setmetatable({}, { __mode = "k" })            -- thing -> { since, x, z, moving, stopped }
local glides = setmetatable({}, { __mode = "k" })          -- thing -> { since, x0, z0 } (h.glide)

local function Steps(prefab, h)
    local list = hazard_steps[prefab]
    if list == nil then
        list = {}
        for _, step in ipairs(h.steps or {}) do
            table.insert(list, { at = step.at, map = Unpack(step.cells or "") })
        end
        -- (struck again where it struck, h.again frames after each - UM Bearger's sinkholes, each
        -- stage half a second on: drawn till the last, not gone after the first)
        if h.again ~= nil then
            local n = #list
            for _, off in ipairs(h.again) do
                for i = 1, n do table.insert(list, { at = list[i].at + off, map = list[i].map }) end
            end
            table.sort(list, function(a, b) return a.at < b.at end)
        end
        hazard_steps[prefab] = list
    end
    return list
end

-- (how far one goes on with you (entry.follow): as far as it was run offline, it may be no limit at all - the
-- Ancient Guardian's leap lands 2 past you however far off you are, run only up to 16 away: drawn 18 at
-- most, it leapt on past. Followed to the last distance run: none)
function SimMoves._FollowLimit(entry)
    local f = entry.follow
    if f == nil then return nil end
    if entry._follow_lim == nil then
        local most = 0
        for _, list in ipairs({ entry.maps or {}, entry.free or {} }) do
            for _, m in ipairs(list) do if (m.dist or 0) > most then most = m.dist end end
        end
        entry._follow_lim = (f >= most - .01) and math.huge or f
    end
    return entry._follow_lim
end
-- (whether its far end going on with you is the whole shape moved on along its way (entry.follow): two runs made a
-- distance apart, the later against the earlier moved on by the difference - most of it the same, or not. Not: the
-- Celestial Champion's tri-beam, its side beams each going out its own way (36 degrees off) - moved on along the middle
-- they came out turned in 3 degrees, 0.7 off at 14 out, the player 2026-10-26: such a one held (FOLLOW_HOLD) no further
-- than another (HOLD), drawn from the run nearest you. Worked out once a move, from its own runs - src its list)
function SimMoves._SlideFits(entry, src)
    local key = (src ~= nil and src == entry.free) and "_slide_fits_free" or "_slide_fits"
    if entry[key] ~= nil then return entry[key] end
    local list = Decode(entry, src)
    local lim = SimMoves._FollowLimit(entry) or 0
    -- (two runs as far apart as it may be held (FOLLOW_HOLD, 1 at least), both within its follow, the pair whose gap is
    -- nearest that: what holding it on would do)
    local a, b, gap = nil, nil, nil
    for i = 1, #list do
        for j = i + 1, #list do
            local m1, m2 = list[i], list[j]
            local d = m2.dist - m1.dist
            if m1.of ~= m2.of and m2.dist <= lim + .01 and d >= 1 - .01 and d <= FOLLOW_HOLD + .01
                and (gap == nil or math.abs(d - FOLLOW_HOLD) < math.abs(gap - FOLLOW_HOLD)) then
                a, b, gap = m1, m2, d
            end
        end
    end
    if a == nil then entry[key] = true return true end
    local function All(m)
        local c = {}
        for _, s in ipairs(MapSteps(m)) do for k in pairs(s.cells) do c[k] = true end end
        return c
    end
    local ca, cb = All(a), All(b)
    local shift = math.floor((b.dist - a.dist) / G.step + .5)
    local n, miss = 0, 0
    for k in pairs(cb) do
        n = n + 1
        if not ca[k - shift] then miss = miss + 1 end
    end
    -- (no top-level local: this file is at Lua's 200)
    entry[key] = n == 0 or miss <= (SimMoves.slide_miss or .15) * n
    entry[key .. "_miss"] = n > 0 and miss / n or 0
    return entry[key]
end
-- (how far ahead a map made already reaches, its furthest cell - nil: not made yet)
function SimMoves._FarOf(map)
    local of = map.of
    if of.far == nil and of.steps ~= nil then
        local far = -math.huge
        for _, s in ipairs(of.steps) do
            for _, run in ipairs(s.runs) do far = math.max(far, G.ahead + run[3] * G.step) end
        end
        of.far = far
    end
    return of.far
end

-- how far all its steps' cells reach, seen from it: { ahead_min, ahead_max, side (each way) }
local bounds = {}
local function Bounds(prefab, h)
    local b = bounds[prefab]
    if b == nil then
        b = { ahead_min = math.huge, ahead_max = -math.huge, side = 0 }
        for _, step in ipairs(Steps(prefab, h)) do
            for _, run in ipairs(step.map.runs) do
                local side = math.abs(-G.side + run[1] * G.step) + G.step / 2
                b.side = math.max(b.side, side)
                b.ahead_min = math.min(b.ahead_min, G.ahead + run[2] * G.step - G.step / 2)
                b.ahead_max = math.max(b.ahead_max, G.ahead + run[3] * G.step + G.step / 2)
            end
        end
        bounds[prefab] = b
    end
    return b
end

-- Whether a map is a filled disc round the thing itself: every cell within R of it, every spot
-- within R less ROUND_GIVE cells filled - turned any way, the same within that: drawn unturned. A
-- worm segment turns a little every frame as it follows its body: each turn a new set of pieces,
-- laid one by one - the frame rate down; unturned, one set kept, moved as one (true_range/lines,
-- groups). nil, why: not one
local ROUND_GIVE = 1.5
local function Round(map)
    local step = G.step
    local r0, c0 = G.side / step, -G.ahead / step  -- (the cell the thing itself is in)
    local n, R, ma, ms = 0, 0, 0, 0
    for _, run in ipairs(map.runs) do
        local s = (run[1] - r0) * step
        for c = run[2], run[3] do
            local a = (c - c0) * step
            R = math.max(R, math.sqrt(a * a + s * s))
            n, ma, ms = n + 1, ma + a, ms + s
        end
    end
    if n == 0 then return nil, "empty" end
    if math.abs(ma / n) > step / 2 or math.abs(ms / n) > step / 2 then return nil, "off its middle" end
    local k = math.ceil(R / step)
    for dr = -k, k do
        for dc = -k, k do
            if math.sqrt(dr * dr + dc * dc) * step <= R - ROUND_GIVE * step and not map.cells[(r0 + dr) * 1000 + (c0 + dc)] then
                return nil, string.format("a gap %.2f in, of %.2f", math.sqrt(dr * dr + dc * dc) * step, R)
            end
        end
    end
    return true, string.format("R %.2f", R)
end
SimMoves._Round = function(text) return Round(Unpack(text)) end
-- A thing drawn just as last frame - turned the same, in the same form (start, sfx), no part's
-- colour due to change yet (till): its groups kept, only moved to where it is now; only whether
-- you're in it looked at again. Every thing worked out anew every frame was most of the mod's
-- time with the Crystal Deerclops' spikes and the worm's segments: nil - not so, draw it anew
local function Kept(s, x, z, rot, px, pz, now, sfx, start)
    local m = s.memo
    if m == nil or draw_slot == nil or Lines.GroupKeep == nil or (m.rot ~= rot and not Lines.turns) or m.sfx ~= sfx
        or m.start ~= start or now >= m.till or m.ver ~= Lines.version or m.unturned ~= draw_unturned then
        return nil
    end
    -- (among this frame's shapes still, where it is now; another over it - drawn the whole way, its
    -- outline cut where it runs inside: SimMoves._rg)
    local rg = SimMoves._rg
    local R = rg.by[draw_slot]
    if R ~= nil and R.r ~= nil then
        for q = 1, rg.na do
            local O = rg.act[q]
            if O ~= R and O.f >= rg.f - 1 and O.r ~= nil and (O.x - x) ^ 2 + (O.z - z) ^ 2 < (O.r + R.r) ^ 2 then return nil end
        end
    end
    if not Lines.GroupKeep(draw_slot, x, z, (draw_unturned and 0 or rot) / DEGREES) then return nil end
    if R ~= nil then R.f, R.x, R.z = rg.f, x, z rg.Active(R) end
    local inside = false
    for _, p in ipairs(m.todo) do
        if InMap(p.map, x, z, rot, px, pz) then inside = true break end
    end
    -- (testing: as DrawParts says what's drawn)
    if SimMoves._record ~= nil then
        local copy = {}
        for i, p in ipairs(m.todo) do
            local c = {}
            for k, v in pairs(p) do c[k] = v end
            copy[i] = c
        end
        table.insert(SimMoves._record, { todo = copy, x = x, z = z, rot = rot, key = m.key, step = G.step, owner = SimMoves._draw_owner })
    end
    return inside
end
-- (what it was just drawn from, for Kept - only if all of it went into groups)
local function Remember(s, rot, sfx, start, till, todo, key, h, x, z)
    if drew_straight or draw_slot == nil or (#todo == 0 and start == nil) then
        s.memo = nil
        return
    end
    local m = s.memo
    if m == nil then m = {} s.memo = m end
    m.rot, m.sfx, m.start, m.till, m.todo, m.key, m.done = rot, sfx, start, till, todo, key, false
    m.ver, m.unturned = Lines.version, draw_unturned
    -- (and for SimMoves.QuickKeep: one whose drawing turns on nothing but where it is, how it's
    -- turned, the clock - not part of a move, carried off, flying, spreading, running, one of a lot;
    -- moves: it may move, kept the same (lasting) - else only kept where it was)
    m.h, m.x, m.z = h, x, z
    m.fast = sfx == "" and not (h.in_move or h.glide or h.flies or h.scale or h.moved or h.shared or h.burst)
    m.moves = h.lasting and true or false
end
local hazard_round = {}  -- (prefab -> every step a disc: Round)
-- Round things that last, drawn together - the Great Depths Worm's segments a unit apart, each a
-- disc 2.6 across: nine tenths of each under the others, every one drawn whole, 70 pieces each,
-- its outline running across the others' insides. Each now: its inside one disc (a picture -
-- Lines.GroupDisc), its band and outline only where no other of its kind covers it - the arcs
-- of its circle outside all theirs, worked out exactly (two equal circles: where they cross,
-- acos(d / 2r) either side of the way to the other). Where it strikes, its own cells as before.
-- (set up in SimMoves.DrawHazard, drawn in SimMoves.UnionDraw once all are known, each frame)
local UNION_ARC = 12 * DEGREES  -- (a piece of arc at most this much of its circle: 0.015-0.025 off it - one alone, 30 a line)
local UNION_Q = 1 / DEGREES     -- (its ends kept to a degree - 0.05 at its edge: laid again only if moved more)
local union_kind = {}           -- prefab -> { rf: its inside's radius, bw: its band's width } | false
local U = { n = 0, ents = {}, xs = {}, zs = {}, kind = {}, prefab = {}, fill = {}, edge = {}, zone = {} }
local function UnionKind(prefab, h, steps)
    local k = union_kind[prefab]
    if k ~= nil then return k end
    k = false
    -- (or several steps, every one a disc round it - a lasting one draws them all at once, all
    -- alike: one disc, the largest. Klaus' deer's ice circles, pulsing out and in - Uncompromising
    -- Mode's Deerclops putting down a dozen at once, each drawn whole, edge over the others')
    -- (its steps not each a disc but all of them together one - the deer's circle comes out ring by
    -- ring, each step a ring's slice: the lot, as it's drawn)
    local round = hazard_round[prefab]
    if h.lasting and #steps > 1 and not round then
        local cells, keys = {}, {}
        for _, step in ipairs(steps) do
            for key in pairs(step.map.cells) do
                if not cells[key] then cells[key] = true keys[#keys + 1] = key end
            end
        end
        table.sort(keys)
        local runs = {}
        for _, key in ipairs(keys) do
            local row = math.floor(key / 1000)
            local col = key - row * 1000
            local last = runs[#runs]
            if last ~= nil and last[1] == row and last[3] == col - 1 then last[3] = col else runs[#runs + 1] = { row, col, col } end
        end
        round = Round({ cells = cells, runs = runs }) and true or false
    end
    if h.lasting and #steps >= 1 and round then
        -- (its inside as drawn on its own: the mean of its smooth outline's distance from it)
        local A = Atoms(steps, true)
        local sum, n = 0, 0
        for _, p in ipairs(A.polys) do
            for _, pt in ipairs(p.pts) do
                local ahead, side = G.ahead + pt[2] * G.step, -G.side + pt[1] * G.step
                sum, n = sum + math.sqrt(ahead * ahead + side * side), n + 1
            end
        end
        if n > 0 then k = { rf = sum / n, bw = G.step * BAND_CELLS } end
    end
    union_kind[prefab] = k
    return k
end
function SimMoves.UnionBegin() U.n = 0 end
-- (scratch: a circle's covered stretches, start and end, and its arcs left)
local u_from, u_to, u_n = {}, {}, 0
local arc_a, arc_b, arc_n = {}, {}, 0
local function Cover(phi, alpha)
    -- (kept within 0 .. 2 pi, split where it wraps)
    local a, b = phi - alpha, phi + alpha
    a = a % (2 * math.pi)
    b = a + 2 * alpha
    if b > 2 * math.pi then
        u_n = u_n + 1 u_from[u_n], u_to[u_n] = a, 2 * math.pi
        u_n = u_n + 1 u_from[u_n], u_to[u_n] = 0, b - 2 * math.pi
    else
        u_n = u_n + 1 u_from[u_n], u_to[u_n] = a, b
    end
end
-- (the arcs not covered: arc_a/arc_b, arc_n - by insertion, the stretches few)
local function Arcs(hidden)
    arc_n = 0
    if hidden then return end
    for i = 2, u_n do
        local fa, ta = u_from[i], u_to[i]
        local j = i - 1
        while j >= 1 and u_from[j] > fa do
            u_from[j + 1], u_to[j + 1] = u_from[j], u_to[j]
            j = j - 1
        end
        u_from[j + 1], u_to[j + 1] = fa, ta
    end
    local at = 0
    for i = 1, u_n do
        if u_from[i] > at + 1e-9 then
            arc_n = arc_n + 1
            arc_a[arc_n], arc_b[arc_n] = at, u_from[i]
        end
        if u_to[i] > at then at = u_to[i] end
    end
    if at < 2 * math.pi - 1e-9 then
        arc_n = arc_n + 1
        arc_a[arc_n], arc_b[arc_n] = at, 2 * math.pi
    end
end
-- (its arcs, whole degrees, against what its group holds - kept there, what it held before into
-- prev; true: the same)
local function SameArcs(list, prev)
    for i = 1, #list do prev[i] = list[i] end
    for i = #prev, #list + 1, -1 do prev[i] = nil end
    local same = #list == arc_n * 2
    for i = 1, arc_n do
        local qa, qb = math.floor(arc_a[i] * UNION_Q + .5), math.floor(arc_b[i] * UNION_Q + .5)
        if list[2 * i - 1] ~= qa or list[2 * i] ~= qb then same = false end
        list[2 * i - 1], list[2 * i] = qa, qb
    end
    for i = #list, arc_n * 2 + 1, -1 do list[i] = nil end
    return same
end
-- (scratch: who's near the one being worked out - distance, way; its arcs before)
local nb_d, nb_phi = {}, {}
-- (what the nn near cover of its circle at radius r - each a stretch either side of the way to it;
-- one inside another's left out, as it's found or as a wider one comes: a worm's segments have a
-- score near, each covering less than the one before it on that side - the stretches to sort and
-- merge were tens, now a few)
local acc_phi, acc_al = {}, {}
local function CoverAll(nn, r)
    local na = 0
    for m = 1, nn do
        local d = nb_d[m]
        if d < 2 * r then
            local phi, al = nb_phi[m], math.acos(d / (2 * r))
            local inside = false
            local k = 1
            while k <= na do
                local diff = math.abs((phi - acc_phi[k] + math.pi) % (2 * math.pi) - math.pi)
                if diff <= acc_al[k] - al + 1e-12 then
                    inside = true
                    break
                elseif diff <= al - acc_al[k] + 1e-12 then
                    -- (that one inside this: gone)
                    acc_phi[k], acc_al[k] = acc_phi[na], acc_al[na]
                    na = na - 1
                else
                    k = k + 1
                end
            end
            if not inside then
                na = na + 1
                acc_phi[na], acc_al[na] = phi, al
            end
        end
    end
    u_n = 0
    for k = 1, na do Cover(acc_phi[k], acc_al[k]) end
end
local prev_o, prev_b = {}, {}
-- (one line round it, at radius r, width w, as style: each whole UNION_ARC of its circle a cell,
-- the part of its arcs in it - up to two parts a cell, slots 2k + 1 and 2k + 2 - told only where
-- it differs from what the group holds; and gone through only where its ends moved, between where
-- they were (prev) and are - all of it if its arcs are more or fewer, or all must be told)
local UNION_CELLS = math.ceil(2 * math.pi / UNION_ARC - 1e-9)
local dirty, n_dirty = {}, 0
local function Dirty(q1, q2)
    local a, b = math.min(q1, q2) / UNION_Q, math.max(q1, q2) / UNION_Q
    local k0 = math.max(0, math.floor((a - 1e-6) / UNION_ARC))
    local k1 = math.min(UNION_CELLS - 1, math.floor((b + 1e-6) / UNION_ARC))
    for k = k0, k1 do
        n_dirty = n_dirty + 1
        dirty[n_dirty] = k
    end
end
local function SlotArcs(g, key, list, prev, r, w, style, force)
    if g.u_cell == nil then g.u_cell = {} end
    local held = g.u_cell[key]
    if held == nil then held = {} g.u_cell[key] = held end
    n_dirty = 0
    -- (testing: TR_UNION_FULL - every cell gone through, as before - tests/replay_haz.lua)
    if force or #prev ~= #list or rawget(_G, "TR_UNION_FULL") then
        for k = 0, UNION_CELLS - 1 do
            n_dirty = n_dirty + 1
            dirty[n_dirty] = k
        end
    else
        for i = 1, #list do
            if list[i] ~= prev[i] then Dirty(list[i], prev[i]) end
        end
    end
    for d = 1, n_dirty do
        local k = dirty[d]
        local c0, c1 = k * UNION_ARC, math.min((k + 1) * UNION_ARC, 2 * math.pi)
        local parts = 0
        for i = 1, #list, 2 do
            local t1, t2 = math.max(list[i] / UNION_Q, c0), math.min(list[i + 1] / UNION_Q, c1)
            if t2 > t1 + 1e-9 and parts < 2 then
                parts = parts + 1
                local slot = 2 * k + parts
                if force or held[2 * slot - 1] ~= t1 or held[2 * slot] ~= t2 then
                    held[2 * slot - 1], held[2 * slot] = t1, t2
                    Lines.GroupSlotLine(g, key, slot, r * math.cos(t1), r * math.sin(t1), r * math.cos(t2), r * math.sin(t2), w, style)
                end
            end
        end
        for part = parts + 1, 2 do
            local slot = 2 * k + part
            if force or held[2 * slot - 1] ~= false then
                held[2 * slot - 1], held[2 * slot] = false, false
                Lines.GroupSlot(g, key, slot, nil)
            end
        end
    end
end
local u_grid = {}  -- prefab -> cell -> { index, ... }
local union_frame = 0  -- (UnionDraw's own count: which half works its arcs out)
-- (many of a kind at once - ten worms' segments, a hundred and more: each drawn on its own, its
-- inside and a ring round it, its outline over the others' insides - the arcs where no other
-- covers it, worked out every frame, were nine tenths of the mod's time with them, the frames
-- slowed to 30-40. Over UA.most of a kind: on their own; back together under UA.back - not
-- one way and the other frame to frame. (50 and 40 at first: ten worms went 40 to 70 - together
-- still most of the time.) The ring: UA.ring pieces round, a piece 0.04 off its circle)
-- (alone: prefab -> drawn on their own now; count: prefab -> how many this frame - kept in one
-- table: the file is at the 200 names Lua allows it)
-- (lots, act, put, along, none: the lanes - SimMoves.LaneDraw)
local UA = { most = 30, back = 24, ring = 18, alone = {}, count = {}, lots = {}, act = {}, put = {}, along = {}, none = {}, now = 0 }
-- (a lot of one kind put down in one frame in a row, going off one after another - the Eye of
-- Terror's laser, a blob a frame from the one nearest its first, empty blast on (SGeyeofterror,
-- as SGdeerclops' laser: laserempty at 0, then laser i at i - 1 frames, further on each): drawn
-- as one lane, a wave - each stretch its colour by when its blobs go off, red where it goes off
-- now, yellow on ahead, gone behind (DrawHazardInner sets them up, each frame)
function SimMoves.LaneDraw()
    for q = #UA.act, 1, -1 do
        local lot = UA.act[q]
        UA.act[q] = nil
        local n, xs, zs = lot.n, lot.xs, lot.zs
        local mx, mz = 0, 0
        for i = 1, n do mx, mz = mx + xs[i], mz + zs[i] end
        mx, mz = mx / n, mz / n
        -- (its two ends: the one furthest from its middle, and the one furthest from that)
        local ax, az, best = xs[1], zs[1], -1
        for i = 1, n do
            local d = (xs[i] - mx) ^ 2 + (zs[i] - mz) ^ 2
            if d > best then best, ax, az = d, xs[i], zs[i] end
        end
        local bx, bz = ax, az
        best = -1
        for i = 1, n do
            local d = (xs[i] - ax) ^ 2 + (zs[i] - az) ^ 2
            if d > best then best, bx, bz = d, xs[i], zs[i] end
        end
        -- (which goes off first: the end nearer another thing put down with them - the empty blast)
        local na, nb = math.huge, math.huge
        for f = lot.fr - 1, lot.fr + 1 do
            for _, p in ipairs(UA.put[f] or UA.none) do
                if p[3] ~= lot.prefab then
                    na = math.min(na, (p[1] - ax) ^ 2 + (p[2] - az) ^ 2)
                    nb = math.min(nb, (p[1] - bx) ^ 2 + (p[2] - bz) ^ 2)
                end
            end
        end
        if nb < na then ax, az, bx, bz = bx, bz, ax, az end
        local len = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
        local ux, uz = 1, 0
        if len > 1e-6 then ux, uz = (bx - ax) / len, (bz - az) / len end
        local along = UA.along
        for i = 1, n do along[i] = (xs[i] - ax) * ux + (zs[i] - az) * uz end
        for i = #along, n + 1, -1 do along[i] = nil end
        table.sort(along)
        local rot = math.atan2(-uz, ux)
        local now, r = lot.at, lot.r
        -- (only a lot laid in a row: one further off the line through its ends than its own reach isn't a lane - the
        -- Fuelweaver's cage spikes in a ring, Toadstool's mushroom bombs strewn about: drawn as one long piece across
        -- them all, "joined, where they were apart before", the player 2026-10-21 - each its own then (DrawHazardInner).
        -- TR_OLD_LANEROW: as before)
        if not rawget(_G, "TR_OLD_LANEROW") then
            -- (and four at least: two or three thrown one after another make a line of any two - Toadstool's bombs, a frame
            -- apart, each pair drawn as a long piece between them; a laser lays a dozen and more)
            if n < 4 then lot.not_lane = true end
            for i = 1, n do
                -- (.5 off at most - a laser's blobs are laid on its line; not its own reach, Toadstool's bombs 3 round, a heap of
                -- them within that of some line taken for one)
                if math.abs((xs[i] - ax) * -uz + (zs[i] - az) * ux) > .5 then lot.not_lane = true break end
            end
        end
        -- (this frame, as they were found so: each a disc of its reach, coloured by when the lot began - from the next on,
        -- each drawn as itself)
        if lot.not_lane then
            local st = ByTime(lot.start - now)
            for i = 1, n do SimMoves.DrawCapsule(xs[i], zs[i], 0, 0, r, S(st)) end
            n = 0
        end
        -- (one piece, one outline, as a charge's lane: from the first blob not yet gone off to the last -
        -- red all along while any of it goes off, yellow before; the user's call - its colours in stretches
        -- came out as several shapes outlined over each other. Blob k (0 on) goes off k frames after the first)
        local RANK = { hit = 4, strike = 3, fill = 2 }
        local first, st_best = nil, nil
        for i = 1, n do
            local dt = lot.start + (i - 1) * FRAMES - now
            if dt >= -LINGER then
                first = first or i
                local st = ByTime(dt)
                if st_best == nil or (RANK[st] or 1) > (RANK[st_best] or 1) then st_best = st end
            end
        end
        if first ~= nil then
            local x0, z0 = ax + ux * along[first], az + uz * along[first]
            local l = along[n] - along[first]
            SimMoves.DrawCapsule(x0, z0, rot, l, r, S(st_best))
            if SimMoves._record ~= nil then
                local map = SimMoves._caps[math.floor(l * 4 + .5) * 1000 + math.floor(r * 4 + .5)]
                table.insert(SimMoves._record, { todo = { { map = map, style = st_best, id = first } }, x = x0, z = z0, rot = rot,
                    key = "_hazard|" .. lot.prefab, step = G.step, owner = SimMoves._draw_owner, lane = true })
            end
        end
    end
    -- (old lots and what was put down long ago: let go)
    for pf, by in pairs(UA.lots) do
        for f, lot in pairs(by) do if lot.at < UA.now - 5 then by[f] = nil end end
    end
    local f_now = math.floor(UA.now / FRAMES + .5)
    for f in pairs(UA.put) do if f < f_now - 300 then UA.put[f] = nil end end
end
local u_cs = {}  -- prefab -> its grid's square: its outline's width across - all within reach in the nine round it
function SimMoves.UnionDraw()
    if #UA.act > 0 then SimMoves.LaneDraw() end
    local n = U.n
    if n == 0 then return end
    for _, cells in pairs(u_grid) do
        for _, list in pairs(cells) do for i = #list, 1, -1 do list[i] = nil end end
    end
    for pf in pairs(UA.count) do UA.count[pf] = 0 end
    for i = 1, n do
        UA.count[U.prefab[i]] = (UA.count[U.prefab[i]] or 0) + 1
    end
    for pf, cnt in pairs(UA.count) do
        UA.alone[pf] = cnt > UA.most or (UA.alone[pf] and cnt >= UA.back) or false
    end
    for i = 1, n do
        if not UA.alone[U.prefab[i]] then
        local k = U.kind[i]
        local cs = u_cs[U.prefab[i]]
        if cs == nil then
            local ew = Lines._styles ~= nil and Lines._styles[U.edge[i]] ~= nil and Lines._styles[U.edge[i]].width or .1
            cs = 2 * (k.rf + k.bw + ew / 2)
            u_cs[U.prefab[i]] = cs
        end
        local cells = u_grid[U.prefab[i]]
        if cells == nil then cells = {} u_grid[U.prefab[i]] = cells end
        local key = math.floor(U.xs[i] / cs) * 65536 + math.floor(U.zs[i] / cs)
        -- (not a number - the game stopped, "table index is NaN"; left out of the grid, never a crash)
        if key == key then
            local list = cells[key]
            if list == nil then list = {} cells[key] = list end
            list[#list + 1] = i
        end
        end
    end
    for i = 1, n do
        local k, x, z = U.kind[i], U.xs[i], U.zs[i]
        local ew = Lines._styles ~= nil and Lines._styles[U.edge[i]] ~= nil and Lines._styles[U.edge[i]].width or .1
        local rb, ro = k.rf + k.bw / 2, k.rf + k.bw + ew / 2
        local g = Lines.GroupFor(U.ents[i], k)
        -- (its inside: one disc, laid once - again only for another colour)
        if g.sig ~= k or g.u_fill ~= U.fill[i] then
            Lines.GroupClear(g, "f")
            Lines.GroupDisc(g, k.rf, U.fill[i])
            Lines.GroupDone(g, "f")
            g.u_fill, g.u_o, g.u_b = U.fill[i], nil, nil
        end
        g.sig = k
        local force_all = g.u_edge ~= U.edge[i] or g.u_zone ~= U.zone[i] or g.u_ver ~= Lines.version or g.revived
        if UA.alone[U.prefab[i]] then
            -- (on its own: a whole ring round it - laid once, then only moved)
            if g.u_mode ~= "ring" or force_all then
                if g.u_o ~= nil then
                    arc_n = 0
                    SameArcs(g.u_o, prev_o)
                    SameArcs(g.u_b, prev_b)
                    SlotArcs(g, "band", g.u_b, prev_b, rb, k.bw, U.zone[i], true)
                    SlotArcs(g, "line", g.u_o, prev_o, ro, ew, U.edge[i], true)
                end
                for kk = 0, UA.ring - 1 do
                    local t1, t2 = kk / UA.ring * 2 * math.pi, (kk + 1) / UA.ring * 2 * math.pi
                    if Render.band then
                        Lines.GroupSlotLine(g, "ring_b", kk + 1, rb * math.cos(t1), rb * math.sin(t1), rb * math.cos(t2), rb * math.sin(t2), k.bw, U.zone[i])
                    end
                    if Render.outline then
                        Lines.GroupSlotLine(g, "ring_l", kk + 1, ro * math.cos(t1), ro * math.sin(t1), ro * math.cos(t2), ro * math.sin(t2), ew, U.edge[i])
                    end
                end
                g.u_mode, g.u_nn = "ring", nil
                g.u_edge, g.u_zone, g.u_ver, g.revived = U.edge[i], U.zone[i], Lines.version, nil
            end
            Lines.GroupAt(g, x, z, 0)
        else
        if g.u_mode == "ring" then
            -- (together again: its ring away, its arcs all told)
            for kk = 1, UA.ring do
                Lines.GroupSlot(g, "ring_b", kk, nil)
                Lines.GroupSlot(g, "ring_l", kk, nil)
            end
            g.u_mode, g.revived = "union", true
        end
        -- (who covers it: its kind within reach, in the nine squares round it - found once, then
        -- covering it at the outline's circle and at the band's, a little inside: covered a little less)
        local cells = u_grid[U.prefab[i]]
        local cs = u_cs[U.prefab[i]]
        local cx, cz = math.floor(x / cs), math.floor(z / cs)
        local hidden = false
        local nn, who = 0, 0
        do
            for gx = cx - 1, cx + 1 do
                for gz = cz - 1, cz + 1 do
                    local list = cells[gx * 65536 + gz]
                    if list ~= nil then
                        for _, j in ipairs(list) do
                            if j ~= i then
                                local dx, dz = U.xs[j] - x, U.zs[j] - z
                                local d = math.sqrt(dx * dx + dz * dz)
                                if d < 1e-3 then
                                    -- (one right on it: the first of them drawn, the other under it)
                                    if j < i then hidden = true end
                                elseif d < 2 * ro then
                                    nn = nn + 1
                                    nb_d[nn], nb_phi[nn] = d, math.atan2(dz, dx)
                                    who = who + (U.ents[j].GUID or j)
                                end
                            end
                        end
                    end
                end
            end
        end

        -- (the same ones near as last time, only moved along with it: its arcs worked out again every
        -- other frame, half of them one frame, half the next - where its outline meets the next one's
        -- a frame behind, each still moved with it every frame; any come or gone near it: at once)
        local force0 = g.u_edge ~= U.edge[i] or g.u_zone ~= U.zone[i] or g.u_ver ~= Lines.version or g.revived
        local skip = g.u_o ~= nil and not force0 and g.u_nn == nn and g.u_who == who and g.u_hidden == hidden
            and (union_frame + (U.ents[i].GUID or i)) % 2 == 1 and not rawget(_G, "TR_UNION_EVERY")
        g.u_nn, g.u_who, g.u_hidden = nn, who, hidden
        if skip then
            Lines.GroupAt(g, x, z, 0)
        else
            if g.u_o == nil then g.u_o, g.u_b = {}, {} end
            if not hidden then CoverAll(nn, ro) end
            Arcs(hidden)
            local same_o = SameArcs(g.u_o, prev_o)
            if not hidden then CoverAll(nn, rb) end
            Arcs(hidden)
            local same_b = SameArcs(g.u_b, prev_b)
            -- (all told again: other colours, or a group just taken again - its slots hidden)
            local force = force0
            if not (same_o and same_b) or force then
                g.u_edge, g.u_zone, g.u_ver, g.revived = U.edge[i], U.zone[i], Lines.version, nil
                if Render.band and (force or not same_b) then SlotArcs(g, "band", g.u_b, prev_b, rb, k.bw, U.zone[i], force) end
                if Render.outline and (force or not same_o) then SlotArcs(g, "line", g.u_o, prev_o, ro, ew, U.edge[i], force) end
            end
            Lines.GroupAt(g, x, z, 0)
        end
        end
    end
    union_frame = union_frame + 1
    U.n = 0
end
local lasting_todo = setmetatable({}, { __mode = "k" })
-- (what a hazard strikes only near - h.near: its prefab -> those there now, as each is made)
SimMoves.near_things = {}
SimMoves.haz_drawn = 0
SimMoves.stage_shown, SimMoves.stage_hidden = 0, 0
local NONE = {}
local near_at = {}  -- (prefab -> where those are this frame: { t, n, xs, zs })
function SimMoves.NearThing(inst)
    local set = SimMoves.near_things[inst.prefab]
    if set == nil then
        set = setmetatable({}, { __mode = "k" })
        SimMoves.near_things[inst.prefab] = set
    end
    set[inst] = true
end
-- (what's done striking once it plays these - a flame dying down, its hitbox gone as it begins to:
-- warg_mutated_fx KillFX; drawn on through it, the flames were drawn on too long)
SimMoves._off_anims = {
    warg_mutated_breath_fx = { "flame1_pst", "flame2_pst", "flame3_pst", "flame1_tall_pst", "flame2_tall_pst", "flame3_tall_pst" },
    -- (Tropical Experience's dragoon's lava spit, cooling - burning no one once it has: dragoonspit.lua)
    dragoonspit = { "cool" },
}
-- (and only while it plays these - hidden till then, its clock from as it starts: Uncompromising Mode's
-- Moonmaw's crystals, put down all round you hidden, each coming down 1 to 5 s later)
SimMoves._on_anims = {
    moonmaw_trapprojectile = { "meteor_pre" },
    -- (and Uncompromising Mode's queen's guards, only as they charge - true_range/moves_hand _hazards)
    um_beeguard_blocker = { "run_loop" },
    um_beeguard_seeker = { "run_loop" },
    um_beeguard_shooter = { "run_loop" },
    -- (and Tropical Experience's Ancient Hulk's mines, only once set off - red_loop, going off 1.1 s on; armed, they may never)
    ancient_hulk_mine = { "red_loop" },
    -- (and the Shrouded Queen's arena spikes, only as they rise - a wall after; 2026-10-23 update)
    charliearena_spike = { "spike1_pre", "spike2_pre", "spike3_pre" },
}
-- (drawn k times as big while it plays these - SimMoves.DrawHazard: the flames' 1.6 and your body,
-- 2.1; the Buzzard's 0.9 x 0.93 and your body, 1.33)
SimMoves._anim_scale = {
    warg_mutated_breath_fx = { k = .65, anims = { "flame1_tall_pre", "flame2_tall_pre", "flame3_tall_pre",
        "flame1_tall_loop", "flame2_tall_loop", "flame3_tall_loop" } },
}
-- (done striking this many frames after it appeared (DrawHazardInner): the Queen's shadows, impact + 3 (charlie_boss_minions.lua
-- jumpout/impact frames, OnEndHits))
SimMoves._done_after = {
    charlie_boss_minion1 = 20,
    charlie_boss_minion2 = 16,
}
-- (and done once its own net value says so - the Shrouded Queen's vines, come up (charlie_boss_vines.lua _emerged):
-- striking as they come up, then there 1.5 s more harming no one - drawn on, "drawn in, not struck"; 2026-10-23
-- update. TR_OLD_OFFNET: drawn on)
SimMoves._off_nets = {
    charlie_boss_vines = "_emerged",
}
function SimMoves.OffByNet(ent)
    local n = SimMoves._off_nets[ent.prefab]
    if n == nil or rawget(_G, "TR_OLD_OFFNET") then return false end
    local v = rawget(ent, n)
    if type(v) ~= "table" or v.value == nil then return false end
    local ok, on = pcall(v.value, v)
    return ok and on == true
end
-- (moves begun with this animation that go on the way it was walking, not at whom it turned to - their state stops its
-- body but not its walking (SGeyeofterror charge_pre: Physics:Stop, no locomotor:Stop): it faces you till its frame 11,
-- then its walk turns it back and it charges that way. Uncompromising Mode's Eye of Terror and Twins walk off from you
-- before a charge: drawn at you a third of a second, then the other way - every one of 28 charges from walking on three
-- lag benches went the way it walked, every one from standing at its target; the player 2026-10-27. true_range/predict,
-- TR_OLD_KEEPHEADING)
SimMoves._keeps_heading = { eyeofterror = "charge_pre", twinofterror1 = "charge_pre", twinofterror2 = "charge_pre" }
-- (moves that strike anew each time this animation of theirs starts over, the way it faces at its first frame - from frame
-- `at` of the move, as run offline: Uncompromising Mode's Retinazer, its mouth's laser 3-5 times in a row, turning to you
-- all the while (postinit SGeyeofterror mouthshoot_loop: ForceFacePoint each update, SpawnLaser at TimeEvent 0) - the run
-- has the first alone, locked once; the later ones drawn that way as you went round it, 2-4 undrawn a round on the lag
-- bench 2026-10-27. true_range/predict, TR_OLD_RELOCK)
-- (moves whose side is chosen at random as they go, run offline one way: drawn both ways, mirrored across the way it faces -
-- Charlie's castlift, a hand at 4 to one side at frame 37, the other side at 40 (SGcharlie_boss sideoffs). TR_OLD_MIRROR)
SimMoves._mirror = { charlie_boss = { castlift = true } }
if not rawget(_G, "TR_OLD_MIRROR") then
    for p, ms in pairs(SimMoves._mirror) do
        for m in pairs(ms) do
            if type(Data[p]) == "table" and type(Data[p][m]) == "table" then Data[p][m].mirror = true end
        end
    end
end
SimMoves._relock = {
    twinofterror1 = { ["charge_pre~shoot_pre"] = { anim = "charge_loop", at = 33 }, ["charge_pre~shoot_pre~2"] = { anim = "charge_loop", at = 33 } },
}
-- (ones whose blows are set going for later, each 1-15 frames on (DoTaskInTime) - struck all the same once it's knocked out of
-- its move: drawn on this many frames after, not gone that frame. Uncompromising Mode's breath, each fireball's PoofNearby (4 round,
-- the half ahead) - the Magma Hound's (uncompromising_hounds.lua ShootFire), the Pepper Dragon's (SGum_pepperdragon ShootFire): a
-- hound hit mid-breath set you alight undrawn, 2026-10-28. true_range/predict, TR_OLD_TAIL)
SimMoves._tail = { magmahound = 15, um_pepperdragon = 15 }
-- (one going again straight after itself, its last go of a chain drawn as this other's run: the Blighted Rock Master's dash, run
-- offline chaining on - its slide on at full pace and its snip 20 on, drawn on its last dash too, which slows and snips 14 on:
-- "drawn as two dashes, it dashed once", the player 2026-10-28. Chains 2 unless enraged (SGrocky maxchain 2/3/5, not told to a
-- player's game): the second as the plain Rock Master's (its dash never chains). true_range/predict, TR_OLD_CHAINLAST)
SimMoves._chain_last = { rocky_boss_shadow = { atk_dash = { prefab = "rocky_boss", move = "atk_dash" } } }
-- (moves ending in a fall where it is, after a chase as long as its own code likes - drawn round it as it comes down, from this
-- animation on, r round it (its reach and your body), struck at frame `at`, till `till`: the Umbral Abomination's optic blast,
-- 1.2-2.5 s after you, then down (SGshrouden optic_blast_pst: AOE 2.6 at 17, 3.6 at 18) - drawn where the offline chase ended,
-- 4 off it, 3 of 480 struck undrawn on the bench 2026-10-28. true_range/predict, TR_OLD_LAND2)
-- (and, as it chases, its beam round it (shrouden_optic_blast_fx: AOEUtil.Attack 2 round, 5 once it's gone wide - its pre3, canwideblast)
-- - drawn where the offline chase was, 2 off it, a blow under it undrawn, 2026-10-28: r round it now, wide_r once wide_anim played)
-- (a thrown thing's landing: not drawn till this many guesses (LANDWAIT), then moved only once their average is this far off
-- (LANDHOLD) - tests/replay_haz.lua LAND_WAIT / LAND_HOLD try others on what a player's game saw (tools/lagthing_to_haz.ps1))
SimMoves._land_wait, SimMoves._land_hold, SimMoves._land_soon = 7, .4, .5
-- (things that strike for nothing when set off by these, right where they stand - not drawn then: true_range/predict DrawHazards.
-- The Great Depths Worm's dirt pounds (groundpounder) with no damage of its own: 0, worm_boss.lua 1382-1385. TR_OLD_WORMPOUND)
SimMoves._harmless_from = { groundpoundring_fx = { worm_boss_dirt = true, worm_boss_shadow_dirt = true } }
-- (and its teleport: under the ground after you as long as it takes (SGshrouden teleport_loop, till within 1 of you), up where it
-- is (teleport_pst, AOE 2.4 and your body) - drawn on to 22 where the offline run went, 13 its real way: "the hitbox in the wrong
-- place as it goes under", the player 2026-10-28. eta: drawn coming, not by its frame)
SimMoves._land = { shrouden = { teleport_pre = {
    { anim = "teleport_loop", r = 2.9, eta = .4, till = 1e6 },
    -- (till its last blow at 26, not all its 2 s: kept to its end, then a frame of idle, then the punch - drawn, gone, drawn, a blink
    -- between, [tr_lagframe] lag_ink3 2026-10-28. till_old: TR_OLD_LANDTILL)
    { anim = "teleport_pst", r = 3.0, at = 6, till = 26, till_old = 1e6, r2 = 3.85, r2_at = 26, r2_from = 0 },
    -- (going down: no blow (SGshrouden teleport_pre has none) - drawn as it will be under the ground, round itself, not its
    -- offline run 7.8 across for half a second: "what does the dig warn of?", the player 2026-10-29. TR_OLD_TPPRE; last - nil ends the list)
    not rawget(_G, "TR_OLD_TPPRE") and { anim = "teleport_pre", r = 2.9, eta = .9, till = 1e6 } or nil,
}, optic_blast_pre1 = {
    { anim = "optic_blast_pst", r = 4.1, at = 17, till = 18 },
    { anim = "optic_blast_loop", r = 2.5, wide_anim = "optic_blast_pre3", wide_r = 5.5, at = 0, till = 1e6, at_thing = "shrouden_optic_blast_fx" },
    { anim = "optic_blast_pre3", r = 5.5, at = 0, till = 1e6, at_thing = "shrouden_optic_blast_fx" },
    -- (its beam: made where it comes up (optic_blast_appear, pre2 - on you), then chasing you; winding up (pre1), on you to come)
    { anim = "optic_blast_pre2", r = 2.5, eta = .4, till = 1e6, at_thing = "shrouden_optic_blast_fx" },
    { anim = "optic_blast_pre1", r = 2.5, eta = 1, till = 1e6, on_target = true },
} } }
-- (Spat's phlegm (moves_hand.lua spat.snot_pre): round its target, 4 (SPAT_PHLEGM_RADIUS, from the phlegm's middle) - aimed
-- till it's shot (snot frame 21 = the move's 27), kept there till it lands (some 6 frames on). lock_at: in frames of that
-- animation, where its target was then kept. TR_OLD_SPATSNOT: none)
-- (UM Bearger's boulders, shot from its middle (moves_hand_um bearger.t): 3 round it, and you 0.5, at frame 25. TR_OLD_BEARSHOOT)
if not rawget(_G, "TR_OLD_BEARSHOOT") then
    SimMoves._land.bearger = { t = { { anim = "t", r = 3.5, at = 25, till = 27 } } }
end
if not rawget(_G, "TR_OLD_SPATSNOT") then
    SimMoves._land.spat = { snot_pre = {
        { anim = "snot", r = 4, at = 21, till = 29, on_target = true, lock_at = 21 },
        { anim = "snot_pre", r = 4, eta = .9, till = 1e6, on_target = true },
    } }
end
-- (one that strikes round itself as it goes, going fast: your game shows it where it was a moment ago - the network's
-- tick, the in-between it draws - the server strikes from where it is now. The Shrouded Queen's vines (9 to 6 a
-- second) struck you 1.2 off on the server, 1.5-1.9 off on your screen - never under you before they came up; 0.10 s
-- behind, steady (lag bench 2026-10-26_2223, 30 blows). Drawn where it is now as near as can be told: on, as fast as
-- it's seen going, for that long. SimMoves.hazard_lead: tests/replay.lua sets 0 - its positions the server's own.
-- TR_OLD_HAZLEAD: where your game shows it)
SimMoves.hazard_lead = .1
SimMoves._hz_hist = setmetatable({}, { __mode = "k" })
function SimMoves._LeadMovingRaw(ent, x, z, now, chasing)
    local lead = SimMoves.hazard_lead
    if lead <= 0 or rawget(_G, "TR_OLD_HAZLEAD") then return x, z end
    -- (your game the server itself - hosting, no caves: shown where it is, nothing behind. All 127 of your games' logs
    -- so - drawn on there, 30 -> 48 missed, 945 -> 1041 drawn-in on the Great Depths Worm's segments)
    local world = rawget(_G, "TheWorld")
    if world ~= nil and world.ismastersim then return x, z end
    local s = SimMoves._hz_hist[ent]
    if s == nil then
        s = {}
        SimMoves._hz_hist[ent] = s
    end
    -- (not a frame that brought nothing new - a thing the server moves 15 times a second, every other frame where it was:
    -- its speed read 0 then double, drawn on and back each frame, the Umbral Abomination's beam to and fro .4 (frame_check
    -- REVERSE, lag 0549 2026-10-29). Kept as it was, and on by the time since it was last told. TR_OLD_LEADDUP: each frame)
    local age = 0
    local old_dup = rawget(_G, "TR_OLD_LEADDUP")
    -- (only within a tick of the last told - the same place longer than that, it has stopped: kept as it is, its speed
    -- 0 - not drawn on as it went for good, the Eye of Terror 0 -> 6 struck undrawn so, replay CLIENT)
    if #s > 0 and s[#s][2] == x and s[#s][3] == z and not old_dup and now - s[#s][1] < 2.5 * FRAMES then
        age = math.min(now - s[#s][1], .1)
    elseif #s == 0 or s[#s][1] < now then
        s[#s + 1] = { now, x, z }
        if #s > 30 then table.remove(s, 1) end
    end
    -- (how fast: from where it was a tenth of a second back or more - not a frame's step, the network's jitter -
    -- and only going on steady: the tenth before that the same within 50% (the vines turning after you: 5-30%, more as they near). Not one set down step by step along a
    -- winding way - the Great Depths Worm's segments: drawn on so, 30 -> 48 missed in your games' logs)
    local function V(t1)
        for i = #s, 1, -1 do
            local dt = t1 - s[i][1]
            if dt >= .1 - .001 then
                if dt > .3 then return nil end
                local j = i
                while j < #s and s[j][1] < t1 - .001 do j = j + 1 end
                return (s[j][2] - s[i][2]) / dt, (s[j][3] - s[i][3]) / dt
            end
        end
    end
    local vx, vz = V(age > 0 and s[#s][1] or now)
    if vx == nil or vx * vx + vz * vz < 1.5 * 1.5 then return x, z end
    -- (one shot straight on fast, over 12 a second - Uncompromising Mode's bee stingers at 25: no waiting the second tenth to
    -- see it steady, gone 5 by then, struck undrawn; lag bench 2026-10-27_1229. TR_OLD_HAZFAST: waited)
    -- (nor one gone somewhere at a stroke - a teleport, over 40 a second: the Umbral Abomination onto you, drawn on 4-9 past
    -- where it came up, then back, 3 frames; lag bench 2026-10-28. TR_OLD_LEADTP)
    if vx * vx + vz * vz > 40 * 40 and not rawget(_G, "TR_OLD_LEADTP") then return x, z end
    -- (its last step alone so - over the tenth a 3.2 teleport is "32 a second", drawn 2.2 on past where it came up a frame,
    -- the Umbral Abomination's optic blast, [tr_lagdraw] full3 2026-10-28. TR_OLD_LEADTPSTEP)
    if #s >= 2 and not rawget(_G, "TR_OLD_LEADTPSTEP") then
        local a, b = s[#s - 1], s[#s]
        local dt = b[1] - a[1]
        if dt > 0 and (b[2] - a[2]) ^ 2 + (b[3] - a[3]) ^ 2 > (40 * dt) ^ 2 then return x, z end
    end
    -- (chasing: one that goes after you all its life, turning as it goes - the Umbral Abomination's beam: not "steady" one frame
    -- and not the next as it turns, drawn led and not each frame, to and fro (frame_check REVERSE 6-15 a run): led on as it
    -- goes, no steadiness asked. Its stop still told. TR_OLD_CHASELEAD)
    local fast = (vx * vx + vz * vz > 12 * 12 and not rawget(_G, "TR_OLD_HAZFAST")) or (chasing and not rawget(_G, "TR_OLD_CHASELEAD"))
    if not fast and not rawget(_G, "TR_OLD_HAZSTEADY") then
        local t1 = nil
        for i = #s, 1, -1 do
            if now - s[i][1] >= .1 - .001 then t1 = s[i][1] break end
        end
        local ux, uz = nil, nil
        if t1 ~= nil then ux, uz = V(t1) end
        if ux == nil or (vx - ux) ^ 2 + (vz - uz) ^ 2 > .25 * (vx * vx + vz * vz) then
            -- (speeding up along the same line: on by how fast it went the tenth before, less - growing as it does, not none and
            -- then a whole unit at once: a lava pup's dash, "jump 1.0 then back", lag_main1 2026-10-28. Tried and left off: snap backs 0-5 -> 34 a run, lag_grow1 - on only with TR_LEADGROW)
            local u2, v2 = ux ~= nil and ux * ux + uz * uz or 0, vx * vx + vz * vz
            if ux ~= nil and rawget(_G, "TR_LEADGROW") and u2 < v2 and ux * vx + uz * vz > .9 * math.sqrt(u2 * v2) then
                vx, vz = ux, uz
            else
                return x, z
            end
        end
    end
    -- (and still going now - its last step under half that pace, stopping: where it is. Moonmaw's lavae stop dead as they
    -- stab (Physics:Stop at frame 11) - drawn on 1 past them, then back, 1-8 frames; lag bench 2026-10-28. TR_OLD_LEADSTOP)
    if #s >= 2 and not rawget(_G, "TR_OLD_LEADSTOP") then
        -- (over its last two steps, not one: a player's game has it going on unevenly, a long step then a short one (.8, .35)
        -- - the short one taken for stopping, led on and not, the Umbral Abomination's beam to and fro each frame (frame_check
        -- REVERSE, lag 0901). Tried and left off: Moonmaw's lavae stopping a frame later drawn, 1 -> 12 struck undrawn (lag
        -- A/B 0945 / 0952, 2026-10-29), the beam no steadier - on only with TR_LEADSTOP2)
        local a, b = s[#s - 1], s[#s]
        if #s >= 3 and rawget(_G, "TR_LEADSTOP2") then a = s[#s - 2] end
        local dt = b[1] - a[1]
        if dt > 0 and ((b[2] - a[2]) ^ 2 + (b[3] - a[3]) ^ 2) / (dt * dt) < .25 * (vx * vx + vz * vz) then return x, z end
    end
    local rx, rz = x + vx * (lead + age), z + vz * (lead + age)
    -- (not a number - "table index is NaN" in UnionDraw, Uncompromising Mode's warning shadows, lag bench 2026-10-27_1259:
    -- where it is, as it's shown; told once)
    if rx ~= rx or rz ~= rz or rx == math.huge or rx == -math.huge or rz == math.huge or rz == -math.huge then
        if not SimMoves._lead_nan_told then
            SimMoves._lead_nan_told = true
            print(string.format("[true_range] LeadMoving not a number: %s at %s,%s v %s,%s (%d seen)", tostring(ent.prefab), tostring(x), tostring(z), tostring(vx), tostring(vz), #s))
        end
        return x, z
    end
    return rx, rz
end
-- (and come on and gone off over a few frames, not at a stroke: a lava pup's lead taken up 0.17 s into its dash, its shape a
-- whole unit on in one frame, then back as it stopped - "jump 1.0 then back" on the lag bench, 6 a run, 2026-10-28. Gone at
-- once for a teleport (its step over 40 a second). TR_OLD_LEADEASE: at a stroke)
SimMoves._lead_ease = setmetatable({}, { __mode = "k" })
function SimMoves.LeadMoving(ent, x, z, now)
    local rx, rz = SimMoves._LeadMovingRaw(ent, x, z, now)
    -- (tried and left off - eased in, it came late: 2+0 -> 1+11 struck undrawn on the Moonmaw, 0-2 -> 2+4 on the Umbral Abomination,
    -- lag_ease1/2 2026-10-28; on only with TR_LEADEASE)
    if not rawget(_G, "TR_LEADEASE") or ent == nil then return rx, rz end
    local e = SimMoves._lead_ease[ent]
    if e == nil then e = { ox = 0, oz = 0, t = now } SimMoves._lead_ease[ent] = e end
    local dx, dz = rx - x, rz - z
    if e.t == now then return x + e.ox, z + e.oz end
    local dt = math.min(now - e.t, .1)
    e.t = now
    local s = SimMoves._hz_hist[ent]
    local tp = false
    if s ~= nil and #s >= 2 then
        local a, b = s[#s - 1], s[#s]
        local st = b[1] - a[1]
        tp = st > 0 and (b[2] - a[2]) ^ 2 + (b[3] - a[3]) ^ 2 > (40 * st) ^ 2
    end
    if tp then e.ox, e.oz = 0, 0 return x, z end
    local grow = dx * dx + dz * dz > e.ox * e.ox + e.oz * e.oz
    local k = math.min(1, dt / (grow and .07 or .1))
    e.ox, e.oz = e.ox + (dx - e.ox) * k, e.oz + (dz - e.oz) * k
    return x + e.ox, z + e.oz
end
local function DrawHazardInner(ent, x, z, rot, px, pz, now, in_moves, sfx)
    -- (where it is not a number: nothing - UnionDraw stopped the game on one, 2026-10-27)
    if x ~= x or z ~= z then return false end
    local h = (Data._hazards or {})[ent.prefab]
    if h ~= nil and SimMoves.OffByNet(ent) then return false end
    local off = SimMoves._off_anims[ent.prefab]
    if off ~= nil and h ~= nil and ent.AnimState ~= nil then
        for _, an in ipairs(off) do
            if ent.AnimState:IsCurrentAnimation(an) then return false end
        end
    end
    off = SimMoves._on_anims[ent.prefab]
    if off ~= nil and h ~= nil and ent.AnimState ~= nil then
        local playing = false
        for _, an in ipairs(off) do
            if ent.AnimState:IsCurrentAnimation(an) then playing = true end
        end
        if not playing then return false end
    end
    -- (its clock from when it was first seen - also while drawn with its move, not on its own: once
    -- on its own, as far on as it really is - a pound's ring, there 3 seconds, came up anew then)
    -- (as old as its animation, which began as it appeared - first seen here a few frames on, the
    -- network's lag: junk struck before it was drawn red; a while back at most, past striking)
    if h ~= nil and seen[ent] == nil then
        local age = 0
        if ent.AnimState ~= nil and ent.AnimState.GetCurrentAnimationTime ~= nil then
            age = math.max(0, math.min(ent.AnimState:GetCurrentAnimationTime() or 0, ((h.delay or 0) + 15) * FRAMES))
        end
        seen[ent] = { since = now - age, x = x, z = z, fx = x, fz = z }
    end
    -- (done striking this many frames after it appeared, though still there (h.done_after) - the Shrouded Queen's shadows
    -- stop at their impact + 3 (charlie_boss_minions.lua OnEndHits) and play on till their animation ends: drawn on,
    -- "drawn in, not struck"; 2026-10-26. TR_OLD_DONEAFTER: drawn on)
    local done_after = h ~= nil and (h.done_after or SimMoves._done_after[ent.prefab]) or nil
    if done_after ~= nil and seen[ent] ~= nil and now - seen[ent].since > (done_after + 1) * FRAMES
        and not rawget(_G, "TR_OLD_DONEAFTER") then
        return false
    end
    -- (in_move: all it strikes is in the move that set it off, drawn already - a laser's blasts;
    -- in_moves false: no move is drawn now - its boss was cut short, the laser burns on: its own)
    -- (one carried off before it comes down - junk: where each piece lands, told as it goes - the
    -- move shows only where they may)
    if h == nil or (h.in_move and in_moves ~= false and h.glide == nil) then
        return false
    end
    local steps = Steps(ent.prefab, h)
    -- (one its own code carries off before it comes down - the Scrappy Werepig's junk, each piece
    -- sliding out from where they all appear: where it's going - as fast on as it's seen going,
    -- to h.glide frames after it appeared; not seen going yet, that can't be told)
    -- (not one that burns on round itself where it is - the War Machine's laser, sliding a step on
    -- to you as it begins: where it is, not run on from its first steps to some empty spot)
    if h.glide ~= nil and not h.lasting then
        -- (its clock: its animation's, which began as it appeared - not when it was first seen here,
        -- a few frames on: its way was overshot by that much)
        local a = now
        if ent.AnimState ~= nil and ent.AnimState.GetCurrentAnimationTime ~= nil then
            a = ent.AnimState:GetCurrentAnimationTime()
        end
        -- (how fast it goes: over a few frames back - one frame's step, its position as the network
        -- last told it, made a wild guess its first frames)
        local s = glides[ent]
        if s == nil then
            s = {}
            glides[ent] = s
        end
        if #s == 0 or s[#s][1] ~= a then
            s[#s + 1] = { a, x, z }
            if #s > 12 then table.remove(s, 1) end
        end
        local glide = h.glide * FRAMES
        if a < glide then
            -- (a straight line through where it's been seen since it set off - each position as the
            -- network gave it, some late, some twice - and only once that says the same twice running)
            local from = nil
            for i = 2, #s do
                if (s[i][2] - s[1][2]) ^ 2 + (s[i][3] - s[1][3]) ^ 2 > .0004 then from = i - 1 break end
            end
            if from == nil or #s - from + 1 < 4 or a - s[from][1] < 3 * FRAMES - .001 then
                s.est = nil
                return false
            end
            local n, sa, sx, sz, saa, sax, saz = 0, 0, 0, 0, 0, 0, 0
            for i = from, #s do
                local p = s[i]
                n, sa, sx, sz = n + 1, sa + p[1], sx + p[2], sz + p[3]
                saa, sax, saz = saa + p[1] * p[1], sax + p[1] * p[2], saz + p[1] * p[3]
            end
            local den = n * saa - sa * sa
            if den <= 1e-9 then return false end
            local vx, vz = (n * sax - sa * sx) / den, (n * saz - sa * sz) / den
            local ex = (sx - vx * sa) / n + vx * glide
            local ez = (sz - vz * sa) / n + vz * glide
            local prev = s.est
            s.est = { ex, ez }
            if prev == nil or (prev[1] - ex) ^ 2 + (prev[2] - ez) ^ 2 > .16 then
                return false
            end
            x, z = ex, ez
        end
    end
    -- (every step of it a disc round it: drawn unturned - Round)
    local round = hazard_round[ent.prefab]
    if round == nil then
        round = #steps > 0
        for _, step in ipairs(steps) do
            if not Round(step.map) then round = false break end
        end
        hazard_round[ent.prefab] = round
    end
    draw_unturned = round
    if h.burst then
        -- (one that goes off where it comes down - a missile chasing you: round where it is now,
        -- redder the lower it is: coming down some 10 a second)
        local y = 0
        if ent.Transform ~= nil then
            local _, ey = ent.Transform:GetWorldPosition()
            y = ey or 0
        end
        -- (and on where it is by now, as the others going fast: the W.A.R.B.O.T.'s missiles skim in low at 17 a second -
        -- a player's game had them 1.7 back, struck 0.2-0.7 off undrawn, 11 in a client replay 2026-10-29. TR_OLD_BURSTLEAD)
        if not rawget(_G, "TR_OLD_BURSTLEAD") then x, z = SimMoves.LeadMoving(ent, x, z, now) end
        local list = steps
        local todo = {}
        for i, step in ipairs(list) do
            table.insert(todo, { map = step.map, style = ByTime(math.max(0, y - .5) / 10), id = i })
        end
        return DrawParts(list, todo, x, z, 0, px, pz, nil, "_hazard|" .. ent.prefab .. sfx, true)
    end
    -- (one drawn with its move, on its own now, striking only as it appears - a pound's ring: as
    -- it comes, below - not all the while it's there)
    if h.lasting then
        x, z = SimMoves.LeadMoving(ent, x, z, now)
        -- (one that strikes on and on round itself while it's there - a snare pulsing: its reach,
        -- all the while)
        -- (the same every frame: made once for its kind - the Great Depths Worm's hundreds of
        -- segments made one each, every frame)
        local list = steps
        local todo = lasting_todo[list]
        if todo == nil then
            todo = {}
            for i, step in ipairs(list) do
                table.insert(todo, { map = step.map, style = "fill", id = i })
            end
            lasting_todo[list] = todo
        end
        -- (round, as the rest of its kind: drawn with them, once all are known - SimMoves.UnionDraw;
        -- where it strikes, its own cells, turned as it is)
        local uk = sfx == "" and draw_slot ~= nil and Lines.GroupFor ~= nil and UnionKind(ent.prefab, h, list) or false
        if uk then
            local n = U.n + 1
            U.n = n
            U.ents[n], U.xs[n], U.zs[n], U.kind[n], U.prefab[n] = ent, x, z, uk, ent.prefab
            U.fill[n], U.edge[n], U.zone[n] = S("fill"), S(EDGE_OF.fill or "edge"), S("edge_zone")
            if SimMoves._record ~= nil then
                table.insert(SimMoves._record, { todo = todo, x = x, z = z, rot = rot,
                    key = "_hazard|" .. ent.prefab .. sfx, step = G.step, owner = SimMoves._draw_owner })
            end
            for _, step in ipairs(list) do
                if InMap(step.map, x, z, rot, px, pz) then return true end
            end
            return false
        end
        -- (the same all the while: kept as it was, only moved - Kept)
        local ls = seen[ent]
        local kept = Kept(ls, x, z, rot, px, pz, now, sfx, nil)
        if kept ~= nil then return kept end
        local key = "_hazard|" .. ent.prefab .. sfx
        drew_straight = false
        local inside = DrawParts(list, todo, x, z, rot, px, pz, nil, key, true)
        Remember(ls, rot, sfx, nil, math.huge, todo, key, h, x, z)
        return inside
    end
    -- (its clock: from when it appeared, or stopped moving)
    local s = seen[ent]
    if s == nil then
        s = { since = now, x = x, z = z }
        seen[ent] = s
    end
    -- (where it was put down, by the frame: which end of a lane goes off first - SimMoves.LaneDraw)
    if not s.put and not h.moved then
        s.put = true
        local f = math.floor(s.since / FRAMES + .5)
        local l = UA.put[f]
        if l == nil then l = {} UA.put[f] = l end
        l[#l + 1] = { x, z, ent.prefab }
    end
    local start = nil
    if h.flies then
        -- (one that strikes as it flies - a gestalt: its way is set before it goes; seen from where
        -- it sets off, the way it faces then; gone once it has stopped)
        if now ~= s.t then
            -- (once it's done it drifts on, slowly, harmless - going slower than this is done)
            local speed = s.t ~= nil and math.sqrt((x - s.x) ^ 2 + (z - s.z) ^ 2) / (now - s.t) or 0
            local still = speed < 6
            if not still and not s.moving then
                s.moving = true
            end
            -- (slow for a few moments running - not just a moment its news came late)
            s.slow = (still and s.moving) and (s.slow or 0) + 1 or 0
            if s.slow >= 3 and not s.stopped then
                s.stopped = true
                local _ = rawget(_G, "TR_DEBUG") and print(string.format("[true_range] %s flew %.2f, %.2fs after it appeared; you were %s its drawn way as it flew",
                    ent.prefab, math.sqrt((x - s.ax) ^ 2 + (z - s.az) ^ 2), now - s.since, s.was_in and "IN" or "not in"))
            end
            if not s.moving then
                s.ax, s.az, s.arot = x, z, rot
            end
            s.x, s.z, s.t = x, z, now
        end
        -- (h.aim: it only faces its way this long after it appears - before, it would point wrong)
        if s.stopped or s.ax == nil or now < s.since + (h.aim or 0) * FRAMES then
            return false
        end
        local fly_start = s.since + (h.delay or 0) * FRAMES
        local inside = false
        local todo = {}
        -- (how far it has really flown its way - the server slow, it flew late and slower than run
        -- offline: by time its last part was gone before it got to you)
        local flown = (x - s.ax) * math.cos(s.arot) - (z - s.az) * math.sin(s.arot)
        for i, step in ipairs(steps) do
            if step.mid_col == nil then
                local c0, c1 = math.huge, -math.huge
                for _, run in ipairs(step.map.runs or {}) do c0, c1 = math.min(c0, run[2]), math.max(c1, run[3]) end
                step.mid_col = c1 >= c0 and (c0 + c1) / 2 or 0
            end
            -- (a part it has flown past is gone at once - it's past it, fast)
            if flown <= step.mid_col * G.step + G.ahead + FLOWN_PAST then
                local style = ByTime(fly_start + step.at * FRAMES - now)
                -- (the first part it hasn't flown past - where it is now: red, striking, not yellow for
                -- a frame between one part gone and the next's turn - a gestalt's head went red,
                -- yellow, red, frame by frame)
                if #todo == 0 and style == "strike" and s.moving then style = "hit" end
                table.insert(todo, { map = step.map, style = style, id = i })
            end
        end
        inside = DrawParts(steps, todo, s.ax, s.az, s.arot, px, pz, nil, "_hazard|" .. ent.prefab .. sfx) or inside
        if s.moving and inside then
            s.was_in = true
        end
        return inside
    end
    if h.moved then
        -- (moved since the last moment? - looked at once a moment, however often it's drawn)
        if now ~= s.t then
            local still = (x - s.x) ^ 2 + (z - s.z) ^ 2 < .0004
            -- (not one thrown and still up in the air - lobbed high, it crawls along under .02 a frame: "stopped" up there,
            -- drawn round itself in the air a frame, hidden the next as it went on - the Ink Blight's balls, a ring under each
            -- blinking and creeping along, GAPDRAWN 127 replaying the lag bench 2026-10-28. TR_OLD_AIRSTILL: as before)
            if still and (s.rose or s.lobbed) and not rawget(_G, "TR_OLD_AIRSTILL") and ent ~= nil and ent.Transform ~= nil then
                local _, ay = ent.Transform:GetWorldPosition()
                if (ay or 0) > .3 then still = false end
            end
            -- (stopped only once still two frames running, from the first - one frame in three the same place
            -- as the last, the server's tick and the frame apart: the Moon Tentacle's spines "stopped" up in the
            -- air, drawn round themselves there that frame, at where they'd land the next - leaping, blinking.
            -- TR_OLD_STILL: as before)
            local old_still = rawget(_G, "TR_OLD_STILL")
            if not still then
                s.moving, s.stopped, s.still_at = true, nil, nil
            elseif s.moving and s.stopped == nil then
                if old_still or s.still_at ~= nil then s.stopped = s.still_at or now else s.still_at = now end
            end
            s.x, s.z, s.t = x, z, now
        end
        start = s.stopped
        -- (come down and lying still: where its landing was drawn kept, as LANDKEEP does while it's still settling - once "stopped"
        -- (still two frames) it went to where it lay, 0.1-0.4 over, 2 frames after it touched down: 78 of 91 moves of the Ink
        -- Blights' landings in the player's game ([tr_lagthing] vs [tr_lagframe], 2026-10-28). TR_OLD_LANDSTOP)
        if start ~= nil and s.land ~= nil and not rawget(_G, "TR_OLD_LANDSTOP") and (x - s.land[1]) ^ 2 + (z - s.land[2]) ^ 2 <= 1.5 * 1.5 then
            x, z = s.land[1], s.land[2]
        end
        -- (thrown, still up in the air: where it'll come down, and when - its height these last
        -- frames fitted to a fall (a squid's ink, a lunar bird's bile): drawn there, coming,
        -- not round it in the air and only then where it lands, as it strikes)
        if start == nil and ent ~= nil and ent.Transform ~= nil and ent.Transform.GetWorldPosition ~= nil then
            local _, y = ent.Transform:GetWorldPosition()
            s.air = s.air or {}
            local hist = s.air
            -- (the last six, not three: its height fitted through three a frame apart flicked where it'd land
            -- about - each height off by a hair (the trace's 0.01) was half its fall's curve; the Moon
            -- Tentacle's spines drawn on you for a frame or two, 4 a throw. TR_OLD_FALL: as before)
            local keep_n = rawget(_G, "TR_OLD_FALL") and 3 or 6
            -- (up in the air and not yet moved at all since made - hanging where it's made a few frames: not drawn
            -- till it's off, which way not yet known - drawn round itself there, then gone, then where it lands
            -- (the Moon Tentacle's spines, GAP 0.3 s each); a mini eye's ring 2 frames later. TR_OLD_EARLY: as before)
            -- (nor a frame that brought nothing new - a player's game hears the server 15 times a second, every other frame
            -- the same height and place: fitted as standing a frame, the Moon Tentacle's shots up high taken to land at once
            -- where they set off, drawn there and gone, 656 gaps (replay CLIENT 2026-10-29). TR_OLD_AIRDUP: kept)
            local last = hist[#hist]
            local dup = last ~= nil and last[3] == (y or 0) and last[2] == x and last[4] == z and (y or 0) > .3
                and not rawget(_G, "TR_OLD_AIRDUP")
            if not dup and (last == nil or last[1] < now) then
                -- (going up, and higher than a hop - Bearger's boulders bound along 0.5-0.8 up, striking as they go:
                -- taken for thrown, hidden up there, 5 -> 217 missed; a throw goes far higher. TR_OLD_HOP: as before)
                if hist[#hist] ~= nil and (y or 0) > hist[#hist][3] + .01 and ((y or 0) > 1.2 or rawget(_G, "TR_OLD_HOP")) then s.rose = true end
                if (y or 0) > .3 then s.high = true end
                -- (climbing higher than it has yet been seen - not back up to where it was: a player's game's heights for
                -- Spat's phlegm, only falling, went 1.89, 1.51, 1.89 (replay CLIENT); nor from 0, its first word before its
                -- height came. The Moon Tentacle's shots .9 -> 1.7 in a frame; LOWAIRROSE)
                if (y or 0) > .05 then
                    if s.ytop ~= nil and (y or 0) > s.ytop + .2 then s.climbed = true end
                    s.ytop = math.max(s.ytop or 0, y or 0)
                end
                hist[#hist + 1] = { now, x, y or 0, z }
                SimMoves._Trace(ent, now, "air", y, s)
                while #hist > keep_n do table.remove(hist, 1) end
            end
            -- (its heights kept meanwhile: going up as it sets off is seen at once, its first frame off)
            if (y or 0) > .3 and not s.moving and not rawget(_G, "TR_OLD_EARLY") then
                SimMoves._Trace(ent, now, "hide: up, not off yet", y, s)
                s.memo = nil
                return false
            end
            if (y or 0) > .3 and #hist >= 3 then
                -- (y = a + b t + c t^2, least squares through them all - through the three when only three)
                local s0, s1, s2, s3, s4, q0, q1, q2 = 0, 0, 0, 0, 0, 0, 0, 0
                for _, hp in ipairs(hist) do
                    local tt, yy = hp[1] - now, hp[3]
                    local t2 = tt * tt
                    s0, s1, s2, s3, s4 = s0 + 1, s1 + tt, s2 + t2, s3 + t2 * tt, s4 + t2 * t2
                    q0, q1, q2 = q0 + yy, q1 + yy * tt, q2 + yy * t2
                end
                -- (Cramer's rule on the normal equations)
                local d = s0 * (s2 * s4 - s3 * s3) - s1 * (s1 * s4 - s3 * s2) + s2 * (s1 * s3 - s2 * s2)
                if math.abs(d) > 1e-12 then
                    local a = (q0 * (s2 * s4 - s3 * s3) - s1 * (q1 * s4 - s3 * q2) + s2 * (q1 * s3 - s2 * q2)) / d
                    local b = (s0 * (q1 * s4 - q2 * s3) - q0 * (s1 * s4 - s3 * s2) + s2 * (s1 * q2 - q1 * s2)) / d
                    local c2 = (s0 * (s2 * q2 - s3 * q1) - s1 * (s1 * q2 - s2 * q1) + q0 * (s1 * s3 - s2 * s2)) / d
                    local tl = nil
                    -- (seen falling as a thrown thing falls - its height's curve the pull of the ground:
                    -- only one such hidden up in the air below; not one flying level or steered (Moonmaw's
                    -- glass shards, the War Machine's missiles), which strikes as it flies - the reviewer)
                    -- (taken for thrown only once seen going up - a throw goes up before it comes down; not the
                    -- Eye of Terror's mini eye, only ever sinking, faster its first frames: bent like a throw,
                    -- it was hidden as up in the air 5 frames, 3 on, then shown again - it leapt about, the
                    -- player's report 2026-10-18 (pictures of their log, 8.33-8.47; GAPDRAWN 9). TR_OLD_LOB: as before)
                    if c2 < -2 and (s.rose or rawget(_G, "TR_OLD_LOB")) then s.lobbed = true end
                    -- (where it comes down: only one thrown - the mini eye, sinking on through the ground 2 more,
                    -- was held where it'd "land" and struck you outside it, 2.37 off; drawn where it is)
                    if c2 < -1e-6 and (s.lobbed or rawget(_G, "TR_OLD_LOB")) then
                        local disc = b * b - 4 * c2 * a
                        if disc >= 0 then tl = (-b - math.sqrt(disc)) / (2 * c2) end
                    end
                    if tl ~= nil and tl > 0 and tl < 3 then
                        local h1, hn = hist[1], hist[#hist]
                        local dt = hn[1] - h1[1]
                        local vx, vz = (hn[2] - h1[2]) / dt, (hn[4] - h1[4]) / dt
                        -- (only once it says the same twice running - a shadow thrall's balls fitted as
                        -- they rose, each frame somewhere else 2-6 off, drawn on you a frame or two,
                        -- 1,183 times on the testbench; TR_OLD_LAND: as before)
                        local ex, ez = x + vx * tl, z + vz * tl
                        local pe = s.est_land
                        s.est_land = { ex, ez }
                        if rawget(_G, "TR_OLD_LAND") or (pe ~= nil and (pe[1] - ex) ^ 2 + (pe[2] - ez) ^ 2 <= .16) then
                            -- (where it'll come down is fixed as it's thrown (complexprojectile: Launch(to)) - each frame's fit
                            -- a little off, the next's off the other way: drawn where they all average, not the newest. Taken
                            -- each a hair apart, the Ink Blight's balls slid to and fro under you, the player 2026-10-27; every
                            -- thrown thing so. A new one far off its run's (over 1): thrown anew, from there. TR_OLD_LANDAVG)
                            -- (not a plain average: a high lob's guesses drift one way near its top (the Crab King's mortars,
                            -- 1-2 over its flight) - the average left behind, begun anew over 1 off: leapt 1-3.8. Its first four
                            -- averaged, then a tenth of the way to each new one (a quarter: twice the to and fro); begun anew only over 3 off -
                            -- thrown anew. 1701 bench: biggest slide 1.07 -> 0.54, 2.53 -> 1.27, jumped frames 213 -> 105)
                            if not rawget(_G, "TR_OLD_LANDAVG") then
                                local la = s.land_avg
                                if la == nil or (la.x - ex) ^ 2 + (la.z - ez) ^ 2 > 3 * 3 then
                                    la = { x = ex, z = ez, n = 0 }
                                    s.land_avg = la
                                end
                                la.n = la.n + 1
                                -- (not drawn till three say so: its first one or two off by up to 3 in a player's game, drawn
                                -- there and then jumping over - 36 of 41 such jumps, lag bench 2026-10-28 every-frame record.
                                -- TR_OLD_LANDWAIT: from the first)
                                -- (but not past its last _land_soon s - a short throw (the Moon Tentacle's spines, a Sea Weed's seed)
                                -- drawn as late as a long one was struck undrawn: from 3 then)
                                -- (once shown, shown on - its time to land said a hair over and under that, it blinked: la.shown)
                                -- (and down within a quarter of a second: from the first - Spat's phlegm, thrown 3 off and down 6
                                -- frames later, seen 3 of them in a player's game: never drawn, 26 struck undrawn (replay CLIENT
                                -- 2026-10-28; the host 0). TR_OLD_LANDNOW: from 3 as before)
                                local need = (tl < .25 and not rawget(_G, "TR_OLD_LANDNOW")) and 1 or (tl < SimMoves._land_soon and 3 or SimMoves._land_wait)
                                if not la.shown and la.n < need and not rawget(_G, "TR_OLD_LANDWAIT") then
                                    local ka = math.max(1 / la.n, .1)
                                    la.x, la.z = la.x + (ex - la.x) * ka, la.z + (ez - la.z) * ka
                                    s.memo = nil
                                    SimMoves._Trace(ent, now, "hide: where it lands, settling", y, s)
                                    return false
                                end
                                la.shown = true
                                local k = math.max(1 / la.n, .1)
                                la.x, la.z = la.x + (ex - la.x) * k, la.z + (ez - la.z) * k
                                ex, ez = la.x, la.z
                                -- (and drawn there till it's a quarter off - each frame's average a hair on from the last,
                                -- the Ink Blight's balls crept on under you all the same, the player 2026-10-28. TR_OLD_LANDHOLD)
                                if not rawget(_G, "TR_OLD_LANDHOLD") then
                                    local lh = la.held
                                    if lh == nil or (lh[1] - ex) ^ 2 + (lh[2] - ez) ^ 2 > SimMoves._land_hold ^ 2 then lh = { ex, ez } la.held = lh end
                                    ex, ez = lh[1], lh[2]
                                end
                            end
                            -- (counted for the replays: how far where it's drawn coming down moved, frame to frame - TR_LANDWOB)
                            local wob = rawget(_G, "TR_LANDWOB")
                            if wob ~= nil and s.land ~= nil and s.land_t ~= now then
                                local w = wob[ent.prefab] or { n = 0, moved = 0, dist = 0, most = 0 }
                                wob[ent.prefab] = w
                                local d = math.sqrt((s.land[1] - ex) ^ 2 + (s.land[2] - ez) ^ 2)
                                w.n = w.n + 1
                                if d > .05 then w.moved = w.moved + 1 end
                                w.dist, w.most = w.dist + d, math.max(w.most, d)
                                local wev = rawget(_G, "TR_LANDWOB_EV")
                                if wev ~= nil and d > .5 and #wev < 300 then
                                    wev[#wev + 1] = string.format("LANDJUMP %.3f %s %s %.2f: %.2f,%.2f -> %.2f,%.2f, %d averaged, %.2f s to land, y %.2f",
                                        now, ent.prefab, tostring(ent.GUID), d, s.land[1], s.land[2], ex, ez, s.land_avg ~= nil and s.land_avg.n or 0, tl, y or 0)
                                end
                            end
                            s.land_t = now
                            x, z = ex, ez
                            start = now + tl
                            s.land = { x, z, start }
                        end
                    else
                        s.est_land = nil
                    end
                end
                -- (up in the air, where it'll come down not yet told: nothing - not round it up there,
                -- where it strikes nothing)
                -- (and one seen going up, not yet told thrown: thrown all the same - drawn round it up there a few
                -- frames, then gone, then where it lands: blinking, the Moon Tentacle's spines (TRACE 7.60-7.97);
                -- where it was told it'd land kept a moment past then, still coming down (0.37 up, 0.01 s late):
                -- not gone a frame. TR_OLD_EARLY: as before)
                local early = not rawget(_G, "TR_OLD_EARLY")
                if start == nil and (s.lobbed or (early and s.rose)) and not rawget(_G, "TR_OLD_LAND") then
                    -- (where it was last told it'd come down, still to come: kept - not hidden a frame
                    -- the fit says otherwise, the Wilting Dragonfly's fireballs going up near straight)
                    if s.land ~= nil and now <= s.land[3] + (early and .2 or 0) then x, z, start = s.land[1], s.land[2], s.land[3]
                    -- (but not one low down, a shoulder's height - flung, not lobbed: round it as it flies - Spat's phlegm, 2 up
                    -- at most and down 6 frames on, its fall not yet seen in a player's game: hidden all its way, 23 struck undrawn
                    -- (replay CLIENT 2026-10-28). TR_OLD_LOWAIR: hidden)
                    -- (nor one seen going up - lobbed high, just off: the Moon Tentacle's shots drawn round the tentacle 3 frames,
                    -- then hidden till their landing was known - a blink each shot, 782 gaps on the host, 2026-10-29. Spat's
                    -- phlegm never rises. TR_OLD_LOWAIRROSE: so)
                    elseif y ~= nil and y < 2.1 and not rawget(_G, "TR_OLD_LOWAIR") and not (s.climbed and not rawget(_G, "TR_OLD_LOWAIRROSE")) then SimMoves._Trace(ent, now, "low in the air: round it", y, s)
                    else s.memo = nil SimMoves._Trace(ent, now, "hide: in the air, no landing", y, s) return false end
                end
            -- (its last moments of fall, too low to fit: where it was seen to come down, kept - drawn
            -- round it as it fell on, the Shriek's ball, its shape slid on a little as it struck)
            -- (or down, later than its fall said, still by where it was drawn coming down (1.5): held there - let go at its time
            -- and drawn where it is, it slid over as it struck, the Ink Blight's balls, the player 2026-10-28. TR_OLD_LANDKEEP)
            elseif (y or 0) <= .3 and s.land ~= nil then
                local dd = math.sqrt((x - s.land[1]) ^ 2 + (z - s.land[2]) ^ 2)
                -- (counted for the tests: let go and drawn where it really came down, that far over - TR_LANDWOB "settle")
                local wob = rawget(_G, "TR_LANDWOB")
                -- (and how far what was drawn is from where it came down, once, as it comes down - "err")
                if wob ~= nil and not s.err_done then
                    s.err_done = true
                    local w = wob[ent.prefab] or { n = 0, moved = 0, dist = 0, most = 0 }
                    wob[ent.prefab] = w
                    w.err_n, w.err_sum, w.err_most = (w.err_n or 0) + 1, (w.err_sum or 0) + dd, math.max(w.err_most or 0, dd)
                end
                if now <= s.land[3] + .2 or (not rawget(_G, "TR_OLD_LANDKEEP") and dd <= 1.5) then
                    x, z, start = s.land[1], s.land[2], s.land[3]
                elseif wob ~= nil and not s.settled then
                    s.settled = true
                    local w = wob[ent.prefab] or { n = 0, moved = 0, dist = 0, most = 0 }
                    wob[ent.prefab] = w
                    w.settle_n, w.settle_most = (w.settle_n or 0) + 1, math.max(w.settle_most or 0, dd)
                end
            elseif (y or 0) > .3 and (s.lobbed or (s.rose and not rawget(_G, "TR_OLD_EARLY"))) and not rawget(_G, "TR_OLD_LAND") then
                -- (just thrown, too few heights yet to fit: nothing either - not round it up there; one seen
                -- going up too, its first frame off)
                s.memo = nil
                SimMoves._Trace(ent, now, "hide: just thrown", y, s)
                return false
            end
        end
    else
        -- (one used again somewhere else - spikes are kept and put back out: from now)
        if (x - s.x) ^ 2 + (z - s.z) ^ 2 > .25 then
            s.since = now
        end
        s.x, s.z = x, z
        -- (red as it strikes, not after: offline its blow came a frame late - junk falls 0.5s, on
        -- the server it strikes on its 15th frame, offline the 16th - and what's drawn shows a
        -- frame after the game's own picture)
        start = s.since + ((h.delay or 0) - HAZ_LEAD) * FRAMES
    end
    -- (one flying fast, not thrown: drawn a frame on, where it'll be - it strikes as it gets there, between
    -- this frame and the next: the mini eye 0.6 a frame struck you 2.37 off its middle, 0.12 outside its
    -- ring, the frame before it'd have been 1.84 in. TR_OLD_LEAD: as before)
    -- (not one ever seen going up - thrown, striking where it comes down: a Sea Weed's seed drawn on ahead
    -- of it in the air, 256 -> 728 drawn-in unstruck on the bench; nor one going along the ground, striking
    -- where it's been - the Celestial Champion's spike trail, +5 to +8 a piece: only one up in the air)
    -- (one that strikes only where it comes down (h.lands - its onhit): drawn only once that's known - not where
    -- it's made, about to be thrown, nor up in the air before it's told thrown. Uncompromising Mode's guardian goo
    -- sits 2-3 ticks in the Ancient Guardian's mouth before it flies: drawn there, gone, then where it lands - 257
    -- blinks on the testbench, 2026-10-19. TR_OLD_LANDS: as before)
    if h.lands and h.moved and start == nil and not rawget(_G, "TR_OLD_LANDS") then
        SimMoves._Trace(ent, now, "hide: lands, where not yet known", nil, s)
        s.memo = nil
        return false
    end
    if h.moved and start == nil and not s.lobbed and not s.rose and s.high and ent ~= nil and ent.Transform ~= nil and not rawget(_G, "TR_OLD_LEAD") then
        local ex, _, ez = ent.Transform:GetWorldPosition()
        -- (a new frame: the last one's place kept - drawn more than once a frame, each the same)
        if s.lt ~= now then s.px, s.pz, s.pt, s.lt = s.lx, s.lz, s.lt, now end
        s.lx, s.lz = ex, ez
        -- (its speed over its last 4 frames, not the last one: a mini eye's place comes every other frame,
        -- 1.33 then nothing - drawn 1.33 ahead, then back on it, frame after frame: the hitbox leaping, the
        -- player's report; 858 frames on the 2026-10-20 bench. TR_OLD_LEADAVG: as before)
        if not rawget(_G, "TR_OLD_LEADAVG") then
            s.lh = s.lh or {}
            local lh = s.lh
            if #lh == 0 or lh[#lh][1] < now then
                lh[#lh + 1] = { now, ex, ez }
                if #lh > 5 then table.remove(lh, 1) end
            end
            local h0 = lh[1]
            if #lh >= 3 and now - h0[1] > 1e-6 and now - h0[1] < .3 then
                local k = FRAMES / (now - h0[1])
                x, z = x + (ex - h0[2]) * k, z + (ez - h0[3]) * k
            end
        elseif s.pt ~= nil and now - s.pt < .1 then
            local k = FRAMES / (now - s.pt)
            x, z = x + (ex - s.px) * k, z + (ez - s.pz) * k
        end
        -- (and on a server, where it really is - your game shows it the network's moment behind (LeadMoving, as the
        -- lasting ones): Uncompromising Mode's mini eyes flung level at 15 a second struck 1.5 ahead of where drawn,
        -- 18 of 349 Eye of Terror blows undrawn on the lag bench 2026-10-27_0813)
        -- (by its speed over its last frames here - it flies 0.3 s all told, too short for LeadMoving's steady tenths)
        local world = rawget(_G, "TheWorld")
        local lh = s.lh
        s.led = 0
        if not rawget(_G, "TR_OLD_HAZLEADMOVED") and SimMoves.hazard_lead > 0 and not (world ~= nil and world.ismastersim)
            and lh ~= nil and #lh >= 2 and now - lh[1][1] > FRAMES / 2 and now - lh[1][1] < .3 then
            local k = SimMoves.hazard_lead / (now - lh[1][1])
            x, z = x + (ex - lh[1][2]) * k, z + (ez - lh[1][3]) * k
            s.led = math.sqrt((ex - lh[1][2]) ^ 2 + (ez - lh[1][3]) ^ 2) * k
        end
    end
    -- (one that moves and strikes a while after it's made (h.delay, run offline from when it was made): not
    -- before then, however soon it stopped - the fused shadeling's bomb lands 0.6 s in and goes off at 35
    -- frames: drawn striking as it landed and over before it went off, 300 of 300 struck undrawn; 300 -> 0 on
    -- the bench, the 8 moved things with a delay none worse, 2026-10-19. TR_OLD_MOVEDDELAY: as before)
    if h.moved and start ~= nil and (h.delay or 0) > 0 and not rawget(_G, "TR_OLD_MOVEDDELAY") then
        start = math.max(start, s.since + (h.delay - HAZ_LEAD) * FRAMES)
    end
    if h.moved then SimMoves._Trace(ent, now, string.format("draw %.2f,%.2f start %s", x, z, tostring(start)), nil, s) end
    s.x0, s.z0 = s.x0 or x, s.z0 or z
    -- (counted for the replays: where it's drawn leaping on further in a moment than it really went -
    -- the Eye's mini eyes drawn now round them, now where they'd land, the player's report; TR_JUMP)
    local jump = rawget(_G, "TR_JUMP")
    -- (and drawn, gone a few frames while it's still there, drawn again - the mini eyes, hidden 5 frames
    -- as if thrown, then on again 3 further: what the player saw leap; TR_GAP)
    local gap = rawget(_G, "TR_GAP")
    if gap ~= nil and s.gt ~= now then
        if s.gt ~= nil and now - s.gt > 1.5 * FRAMES and now - s.gt < 1 then
            gap[ent.prefab] = (gap[ent.prefab] or 0) + 1
            local ev = rawget(_G, "TR_GAP_EV")
            if ev ~= nil and #ev < 200 then ev[#ev + 1] = { now, ent.prefab, ent.GUID, now - s.gt } end
        end
        s.gt = now
    end
    if jump ~= nil and h.moved and s.jt ~= now and ent ~= nil and ent.Transform ~= nil then
        local ex, _, ez = ent.Transform:GetWorldPosition()
        if s.jx ~= nil and now - s.jt < .1 then
            local drawn = math.sqrt((x - s.jx) ^ 2 + (z - s.jz) ^ 2)
            local went = math.sqrt((ex - s.jex) ^ 2 + (ez - s.jez) ^ 2)
            -- (or held off where it is - one not thrown drawn more than 1 from it: left behind as it flew on)
            -- (past where it was led on to on purpose (s.led - a player's game, on as fast as it goes): a boulder rolling at 12 a
            -- second drawn 1.3 on, every frame of it counted a jump - 577 in a client replay, 2026-10-29; TR_OLD_JUMPLED: so)
            local off = not s.lobbed and math.sqrt((x - ex) ^ 2 + (z - ez) ^ 2) > 1 + ((not rawget(_G, "TR_OLD_JUMPLED")) and s.led or 0)
            if drawn > went + 1 or off then jump[ent.prefab] = (jump[ent.prefab] or 0) + 1 local jev = rawget(_G, "TR_JUMP_EV") if jev ~= nil and #jev < 400 then jev[#jev + 1] = string.format("JUMP %.3f %s guid=%d drawn=%.2f went=%.2f off=%s lobbed=%s rose=%s start=%s", now, ent.prefab, ent.GUID, drawn, went, tostring(off), tostring(s.lobbed), tostring(s.rose), tostring(start)) end end        end
        s.jx, s.jz, s.jex, s.jez, s.jt = x, z, ex, ez, now
    end
    local inside = false
    if start == nil and h.moved and h.travel ~= nil and SHOW_STRETCH then
        -- still running, and it stops somewhere it can't be told (a random time): the stretch
        -- where its wall may come up - from as far as it's got (or the least it runs) to the
        -- most it runs, as wide as its wall, from where it set off
        local b = Bounds(ent.prefab, h)
        local run = math.sqrt((x - s.x0) ^ 2 + (z - s.z0) ^ 2)
        -- (only once it's on its way - and the way it's going, not the way it's said to face:
        -- that may not have come through yet, just after it appears)
        if not s.moving or run < .5 then
            return false
        end
        rot = math.atan2(-(z - s.z0), x - s.x0)
        local near = math.max(h.travel[1], run) + b.ahead_min
        local far = h.travel[2] + b.ahead_max
        if far > near then
            local x1, z1 = World(s.x0, s.z0, rot, near, 0)
            local x2, z2 = World(s.x0, s.z0, rot, far, 0)
            Lines.Segment(x1, z1, x2, z2, "fill", 2 * b.side)
            if px ~= nil then
                local dx, dz = px - s.x0, pz - s.z0
                local c, sn = math.cos(rot), math.sin(rot)
                local ahead, side = dx * c - dz * sn, dx * sn + dz * c
                inside = ahead >= near and ahead <= far and math.abs(side) <= b.side
            end
        end
        return inside
    end
    -- (one that runs before it hits: its whole wall goes along with it until it stops - where
    -- that'll be can't be told - then comes up there step by step)
    -- (drawn just as last frame, nothing due to change: kept - Kept; not one of a shared lot)
    if not h.shared then
        local kept = Kept(s, x, z, rot, px, pz, now, sfx, start)
        if kept ~= nil then return kept or inside end
    end
    -- (its list kept from frame to frame, written over - not made anew for each thing every frame:
    -- the Crystal Deerclops' hundreds of spikes, a thousand tables a frame)
    local todo = s.todo
    if todo == nil then todo = {} s.todo = todo end
    local n = 0
    -- (and when the next of its parts changes colour, or is gone - ByTime: till then, the same)
    local till = math.huge
    -- (one of a lot put down at once, going off one after another - the Eye of Terror's laser, each
    -- blob a frame after the one before it (h.delay_max: the last's, run offline): any moment from
    -- the first's to the last's, it can't be told which is which)
    local spread = h.delay_max ~= nil and (h.delay_max - (h.delay or 0)) * FRAMES or 0
    for i, step in ipairs(steps) do
        if start == nil or now <= start + spread + step.at * FRAMES + LINGER then
            local dt = start ~= nil and start + step.at * FRAMES - now or nil
            if dt ~= nil and dt < 0 and spread > 0 then dt = math.min(0, dt + spread) end
            local style = dt ~= nil and ByTime(dt) or "fill"
            n = n + 1
            local td = todo[n]
            if td == nil then td = {} todo[n] = td end
            td.map, td.style, td.id = step.map, style, i
            if dt ~= nil then
                local left = (dt > LATER_IN and dt - LATER_IN) or (dt > FILL_IN and dt - FILL_IN) or (dt > STRIKE and dt - STRIKE) or (dt > 0 and dt) or (dt + LINGER)
                till = math.min(till, now + left)
            end
        end
    end
    for j = #todo, n + 1, -1 do todo[j] = nil end
    -- (all its strikes past, not one running on: nothing more to draw of it while it stays there -
    -- the Crystal Deerclops' spikes stand on long after they strike; QuickKeep)
    if n == 0 and start ~= nil then
        drew_straight = false
        Remember(s, rot, sfx, start, math.huge, todo, nil, h, x, z)
        if s.memo ~= nil then s.memo.done = true end
        return inside
    end
    -- (one of a lot put down in one frame in a row, going off one after another (h.delay_max) - the
    -- Eye of Terror's laser: not each blob on its own, its outline over the others', but the lot one
    -- lane, a wave - SimMoves.LaneDraw, once all are known; each blob kept in its lot till the lot's
    -- gone, which goes off when told by its place along it)
    local lot_of = nil
    if spread > 0 and #steps == 1 and not h.moved and not h.shared and sfx == "" and start ~= nil then
        local fr = math.floor(s.since / FRAMES + .5)
        local by = UA.lots[ent.prefab]
        if by == nil then by = {} UA.lots[ent.prefab] = by end
        lot_of = by[fr] or by[fr - 1] or by[fr + 1]
    end
    -- (a lot found not laid in a row (LaneDraw's not_lane): each drawn as itself, below)
    if spread > 0 and #steps == 1 and not h.moved and not h.shared and sfx == "" and start ~= nil and not (lot_of ~= nil and lot_of.not_lane) then
        local fr = math.floor(s.since / FRAMES + .5)
        local by = UA.lots[ent.prefab]
        local lot = lot_of
        if lot == nil then
            local R = 0
            local r0, c0 = G.side / G.step, -G.ahead / G.step
            for _, run in ipairs(steps[1].map.runs) do
                for c = run[2], run[3] do R = math.max(R, math.sqrt((run[1] - r0) ^ 2 + (c - c0) ^ 2) * G.step) end
            end
            lot = { n = 0, xs = {}, zs = {}, has = setmetatable({}, { __mode = "k" }), at = -1, fr = fr, prefab = ent.prefab, start = start, r = R }
            by[fr] = lot
        end
        if not lot.has[ent] then
            lot.n = lot.n + 1
            lot.has[ent] = lot.n
            lot.xs[lot.n], lot.zs[lot.n] = x, z
        elseif not rawget(_G, "TR_OLD_LANEROW") then
            -- (where each is now, not where it was first seen - and one still on its way isn't laid down: Toadstool's
            -- mushroom bombs, thrown out all at once - seen together at its feet, a lane taken from there, never told
            -- apart as they landed strewn about: long pieces over each other, the player 2026-10-21)
            local i = lot.has[ent]
            if (lot.xs[i] - x) ^ 2 + (lot.zs[i] - z) ^ 2 > .01 then lot.not_lane = true end
            lot.xs[i], lot.zs[i] = x, z
        end
        if lot.at ~= now then lot.at = now UA.act[#UA.act + 1] = lot end
        UA.now = now
        s.memo = nil
        return InMap(steps[1].map, x, z, rot, px, pz) or inside
    end
    -- (one of a lot striking each once among them all (h.shared - the Scrappy Werepig's junk, one
    -- throw's pieces): you struck by one, the rest of them can't - drawn faint, no danger. Its lot:
    -- set off from where that one was, about when (one throw's, not the next's)
    if h.shared then
        local sh = shared_struck[ent.prefab]
        if sh ~= nil and s.fx ~= nil and math.abs(s.since - sh.at) <= SHARED_WINDOW
            and (s.fx - sh.x) ^ 2 + (s.fz - sh.z) ^ 2 <= SHARED_NEAR * SHARED_NEAR then
            for _, td in ipairs(todo) do td.style = "fill_light" end
            DrawParts(steps, todo, x, z, rot, px, pz, nil, "_hazard|" .. ent.prefab .. sfx)
            s.memo = nil
            return false
        end
    end
    local key = "_hazard|" .. ent.prefab .. sfx
    drew_straight = false
    local drawn_in = DrawParts(steps, todo, x, z, rot, px, pz, nil, key)
    if h.shared then s.memo = nil else Remember(s, rot, sfx, start, till, todo, key, h, x, z) end
    return drawn_in or inside
end

-- (you struck by a thing set off: if it's one of a lot sharing whom they strike, the rest are
-- spent on you - till none of them has been seen for a moment, the lot over)
function SimMoves.Struck(ent)
    local h = ent ~= nil and (Data._hazards or {})[ent.prefab] or nil
    local s = h ~= nil and h.shared and seen[ent] or nil
    if s == nil or s.fx == nil then return end
    shared_struck[ent.prefab] = { at = s.since, x = s.fx, z = s.fz }
end

-- (one that does no harm, only a status - a deer's ice circle, freezing: in its own colours)
-- Whether a thing is to be drawn at all as it looks now, where it is
local function Shown(ent, h, x, z, now)
    -- (one that strikes only looking so - a worm segment with spikes (h.look: its build) - and
    -- only at one of those (h.near: the holes it comes up out of and goes down into))
    if h.look ~= nil and ent.AnimState ~= nil and ent.AnimState.GetBuild ~= nil
        and ent.AnimState:GetBuild() ~= h.look then
        return false
    end
    -- (a hole the worm's spiked segments come out of and go into (h.src: what comes out, how near,
    -- how long on, how long new): each strikes 2 round the tick it's set there, before it's seen -
    -- drawn on the hole itself while it's new (it comes up a second after) or while they go by it
    -- (one every 0.2 s): worm_boss_util AddSegment, MoveSegmentUnderGround)
    if h.src ~= nil then
        local fa = SimMoves._src_first
        if fa == nil then fa = setmetatable({}, { __mode = "k" }) SimMoves._src_first = fa end
        if fa[ent] == nil then fa[ent] = now end
        if now - fa[ent] <= h.src[4] then return true end
        local hot, r2 = SimMoves._src_hot or NONE, h.src[2] * h.src[2]
        for i = 1, #hot, 3 do
            if now - hot[i + 2] <= h.src[3] and (hot[i] - x) ^ 2 + (hot[i + 1] - z) ^ 2 <= r2 then return true end
        end
        -- (or the worm itself there (h.src[5]) - the newest hole, its head up out of it a while: the
        -- segments come out as it goes back down, two at once - SGworm_boss_head "move")
        local P = h.src[5] ~= nil and package.loaded["true_range/predict"] or nil
        -- (only its first 4 s there - its head up some 3 s, then the segments: a worm stuck sitting on its
        -- hole had the hole drawn round you a whole minute, 5 -> 1,807 frames drawn in, no strike)
        local wa = SimMoves._src_worm
        if wa == nil then wa = setmetatable({}, { __mode = "k" }) SimMoves._src_worm = wa end
        local worm_on = false
        -- (in the game the world's own search - the replays set Predict.EntsNear, the game doesn't)
        if (P == nil or P.EntsNear == nil) and h.src[5] ~= nil and rawget(_G, "TheSim") ~= nil then
            for _, e in ipairs(TheSim:FindEntities(x, 0, z, h.src[2]) or NONE) do
                if e.prefab == h.src[5] then worm_on = true end
            end
        end
        if P ~= nil and P.EntsNear ~= nil then
            for _, e in ipairs(P.EntsNear(x, z, h.src[2]) or NONE) do
                if e.prefab == h.src[5] then worm_on = true end
            end
        end
        if not worm_on then wa[ent] = nil return false end
        if wa[ent] == nil then wa[ent] = now end
        return now - wa[ent] <= 4
    end
    -- (the holes as they're made, kept by true_range modmain (SimMoves.near_things) - not searched
    -- for round every segment: hundreds a frame, each search a new list - the game stalling to
    -- clear them away)
    if h.near ~= nil and TheSim ~= nil then
        -- (where they are: asked once a frame - not again for every segment; in a grid of squares as
        -- wide as how near it must be - each segment looks in the nine round it, not at every hole:
        -- the worm's are dozens, its segments a hundred and more)
        local r = h.near[2]
        local at = near_at[h.near[1]]
        if at == nil then at = { grid = {} } near_at[h.near[1]] = at end
        if at.t ~= now then
            at.t = now
            for key, list in pairs(at.grid) do
                for i = #list, 1, -1 do list[i] = nil end
            end
            local set = SimMoves.near_things[h.near[1]] or NONE
            for v in pairs(set) do
                if not v:IsValid() then
                    set[v] = nil
                elseif not v:HasTag("INLIMBO") then
                    local vx, _, vz = v.Transform:GetWorldPosition()
                    local key = math.floor(vx / r) * 65536 + math.floor(vz / r)
                    local list = at.grid[key]
                    if list == nil then list = {} at.grid[key] = list end
                    list[#list + 1] = vx
                    list[#list + 1] = vz
                end
            end
        end
        local found = false
        local r2 = r * r
        local cx, cz = math.floor(x / r), math.floor(z / r)
        for gx = cx - 1, cx + 1 do
            for gz = cz - 1, cz + 1 do
                local list = at.grid[gx * 65536 + gz]
                if list ~= nil then
                    for k = 1, #list, 2 do
                        if (list[k] - x) ^ 2 + (list[k + 1] - z) ^ 2 <= r2 then found = true break end
                    end
                end
                if found then break end
            end
            if found then break end
        end        if not found then return false end
    end
    -- (where one shown by a hole is, for the hole's own drawing - h.src above; the old let go once a frame)
    if h.near ~= nil then
        local hot = SimMoves._src_hot
        if hot == nil then hot = {} SimMoves._src_hot = hot end
        if SimMoves._src_hot_t ~= now then
            SimMoves._src_hot_t = now
            local n = 0
            for i = 1, #hot, 3 do
                if now - hot[i + 2] <= .5 then hot[n + 1], hot[n + 2], hot[n + 3] = hot[i], hot[i + 1], hot[i + 2] n = n + 3 end
            end
            for i = #hot, n + 1, -1 do hot[i] = nil end
        end
        hot[#hot + 1], hot[#hot + 2], hot[#hot + 3] = x, z, now
    end
    return true
end
-- A thing drawn just as last frame, kept so before anything else is looked at - the worm's
-- segments and the Crystal Deerclops' spikes, hundreds a frame, each gone through it all again:
-- most of the mod's time. Whether you're in it, or nil: draw it (SimMoves.DrawHazard)
-- (all its strikes past, and still where it was (x, z): nothing to draw, nor to ask the game how
-- it's turned - true_range/predict DrawHazards passes it over: the Crystal Deerclops' spikes stand
-- on long after, hundreds. Where it is must still be asked: the game takes a spike that's done
-- for its next volley, moved - passed over as spent, a volley went undrawn)
function SimMoves.Spent(ent, x, z)
    local s = seen[ent]
    local m = s ~= nil and s.memo or nil
    return m ~= nil and m.done and m.fast and not m.moves and m.x == x and m.z == z or false
end
function SimMoves.QuickKeep(ent, x, z, rot, px, pz, now)
    local s = seen[ent]
    local m = s ~= nil and s.memo or nil
    if m == nil or not m.fast or (not m.moves and (m.x ~= x or m.z ~= z)) then return nil end
    -- (all its strikes past - nothing more to draw of it, where it is)
    if m.done then return false end
    if not Shown(ent, m.h, x, z, now) then return nil end
    draw_slot, draw_unturned = ent, m.unturned
    local inside = Kept(s, x, z, rot, px, pz, now, m.sfx, m.start)
    draw_slot, draw_unturned = nil, false
    if inside ~= nil then SimMoves.haz_drawn = SimMoves.haz_drawn + 1 end
    return inside
end
-- (things whose reach the server tells every frame (a net_float): drawn as that - the Klaus deer's ice circle grows from .25 to 3
-- (deer_fx OnUpdateIceCircle, 2% a frame, freezing whoever's middle is within it): drawn from its run offline, smaller than what
-- froze the player, and shrinking - the player 2026-10-27. Its reach now red, how far it grows to outlined. TR_OLD_LIVERADIUS)
-- (only freezing once its frost is up (deer_fx TriggerFX: deer_ice_fx made on it, the deer's magic_pst frame 25 - Uncompromising
-- Mode's own circles never): slowing only till then - drawn as coming, not as striking)
-- (or its reach k times its size, which the game tells every frame: Uncompromising Mode's fire hounds' fireballs burn all within
-- 2 times their size (um_fire_projectile BurnSurroundings, inst.scale * 2), growing from nothing to 1 and down again as they fly
-- - drawn the one size run offline, 34 set alight undrawn on the bench 2026-10-27; drawn on ahead as they fly, as a thing moving)
-- (not taken up for the fireballs: on the bench 2026-10-27_1809 their size as told, drawn so, missed 61 against the one size's 54 -
-- the size told a tick off what it burns with, they flying 10 a second; kept as the run offline drew them)
-- (also_data: its reach as told and as run offline both - the fireballs: the one size alone 54 undrawn, as told alone 61)
SimMoves._live_radius = { deer_ice_circle = { field = "_rad", grows_to = 3, armed_by = "deer_ice_fx" },
    um_fire_projectile = { scale_r = 2, moving = true, also_data = true } }
function SimMoves.DrawHazard(ent, x, z, rot, px, pz, now, in_moves, data_only)
    local lr = not data_only and SimMoves._live_radius[ent.prefab] or nil
    local x0, z0 = x, z
    if lr ~= nil and not rawget(_G, "TR_OLD_LIVERADIUS") then
        local nv = lr.field ~= nil and ent[lr.field] or nil
        -- (a net variable: the engine's own, not a Lua table - asked for its value however it's made)
        local ok, r = false, nil
        if nv ~= nil then ok, r = pcall(function() return nv:value() end) end
        if lr.scale_r ~= nil and ent.Transform ~= nil and ent.Transform.GetScale ~= nil then
            ok, r = pcall(function() return ent.Transform:GetScale() * lr.scale_r end)
        end
        if ok and lr.moving and type(r) == "number" and r > 0 then x, z = SimMoves.LeadMoving(ent, x, z, now) end
        if ok and type(r) == "number" then
            if r <= 0 then return false end
            -- (no world to search - tests/replay_haz.lua: armed, as it is from its frost on)
            local sim = rawget(_G, "TheSim")
            local armed = lr.armed_by == nil or sim == nil or sim.FindEntities == nil
            if not armed then
                for _, e in ipairs(sim:FindEntities(x, 0, z, .5)) do
                    if e.prefab == lr.armed_by then armed = true break end
                end
            end
            local T = require("true_range/telegraph")
            -- (its fill in whole cells, cut short of r by up to one: half a cell more - a fireball .95 round set you alight
            -- .93 off, its fill .75 round)
            local inside = SimMoves.DrawDisc(x, z, r + G.step * .5, armed and 0 or 1, px, pz)
            T.Circle(x, z, r, armed and "edge_zone" or "edge")
            if lr.grows_to ~= nil and lr.grows_to > r + .05 then T.Circle(x, z, lr.grows_to, "edge") end
            if lr.also_data then
                local d = SimMoves.DrawHazard(ent, x0, z0, rot, px, pz, now, in_moves, true)
                return inside or d
            end
            return inside
        end
    end
    local h = SimMoves.Hazards()[ent.prefab]
    -- (testing: modmain's frame timing - the time asking whether it's to be drawn at all, and how
    -- many weren't)
    local sh0 = os.clock()
    local shown = h == nil or Shown(ent, h, x, z, now)
    SimMoves.stage_shown = SimMoves.stage_shown + os.clock() - sh0
    if not shown then SimMoves.stage_hidden = SimMoves.stage_hidden + 1 return false end
    -- (testing: modmain's frame timing - how many got past the looks and the holes)
    SimMoves.haz_drawn = SimMoves.haz_drawn + 1
    status_only = h ~= nil and StatusOnly(h) or false
    -- (drawn bigger than run offline - a pound's ring, as far as that pound reaches: its cells k
    -- times as big, the same smooth shape made bigger - not its cells made over, in bumps)
    local k = 1
    if h ~= nil and h.scale ~= nil and ent.Transform ~= nil and ent.Transform.GetScale ~= nil then
        local s = ent.Transform:GetScale()
        if s ~= nil and s > 0 then k = math.floor((s / h.scale) ^ (h.scale_pow or 1) * 20 + .5) / 20 end
    end
    -- (or as big as true_range/predict told for this one - by whose it is: SimMoves._k_of)
    if SimMoves._k_of ~= nil and SimMoves._k_of[ent] then k = k * SimMoves._k_of[ent] end
    -- (or smaller while it plays these - the Lunar Buzzard's flames, its "tall" ones: 0.85 to 1 big
    -- (SGbuzzard), the Possessed Varg's the same thing 1.4 to 2.2 - drawn as the Varg's, its
    -- strikes came well within)
    local as = h ~= nil and SimMoves._anim_scale[ent.prefab] or nil
    if as ~= nil and ent.AnimState ~= nil then
        for _, an in ipairs(as.anims) do
            if ent.AnimState:IsCurrentAnimation(an) then k = k * as.k break end
        end
    end
    -- (its pieces kept together, moved as one - true_range/lines, groups)
    draw_slot, build_now = ent, true
    local inside
    if math.abs(k - 1) < .01 or k <= 0 then
        inside = DrawHazardInner(ent, x, z, rot, px, pz, now, in_moves, "")
    else
        local step, ahead, side = G.step, G.ahead, G.side
        G.step, G.ahead, G.side = step * k, ahead * k, side * k
        local ok, res = pcall(DrawHazardInner, ent, x, z, rot, px, pz, now, in_moves, "@" .. k)
        G.step, G.ahead, G.side = step, ahead, side
        if not ok then draw_slot, draw_unturned, build_now = nil, false, false error(res, 0) end
        inside = res
    end
    status_only = false
    draw_slot, draw_unturned, build_now = nil, false, false
    return inside
end

-- its moves: { anims, frames (none: on while its animations play), sim = the entry }
-- (a move's first animation -> its other side's, played instead by the same state: SimMoves.Moves)
-- (the Shadow Runner's pounce: "attack" when you're far (its leap 16 frames), "attack_quick" near - run offline at every
-- distance, both ways, the far ones too, but named by the near one's animation: its far pounce never drawn, 2026-10-28)
SimMoves._anim_twin = { butt_pre_L = "butt_pre_R", attack_quick = "attack" }
function SimMoves.Moves(prefab)
    local list = moves[prefab]
    if list == nil then
        list = {}
        for name, entry in pairs(Of(prefab) or {}) do
            table.insert(list, { anims = entry.anims, frames = {}, sim = entry, name = name })
            -- (and the same move begun with its other side's animation - a state picking one at random or by where you
            -- are, run offline down one way only: Bearger's butt slam, butt_pre_L or _R, the R half (65 of 98 ticks on the
            -- bench) never drawn, struck 1.57 off, 2026-10-28. TR_OLD_TWIN: that one alone, as before)
            local twin = entry.anims ~= nil and SimMoves._anim_twin[entry.anims[1]] or nil
            if twin ~= nil and not rawget(_G, "TR_OLD_TWIN") then
                local anims = { twin }
                for i = 2, #entry.anims do anims[i] = entry.anims[i] end
                table.insert(list, { anims = anims, frames = {}, sim = entry, name = name })
            end
        end
        moves[prefab] = list
    end
    return list
end

-- (a part about to be hit: this much before, drawn darker)
local SOON = .4

-- How far it can go from (x, z) facing rot before its body (radius r) runs into what stops it
-- in the game: the sea's edge, the end of the land (entry.ground: it goes on the ground - over
-- rocks or not, the game keeps land monsters off the sea); rocks, pillars, walls it can't break
-- (entry.solid: it bumps into them as it goes - a leap goes over). nil: nothing within `far`.
-- (looked at again only once it's somewhere else, or after a moment - kept in `log`)
local NOT_STOPPING = { "INLIMBO", "FX", "NOCLICK", "DECOR", "player", "_combat",
    "CHOP_workable", "MINE_workable", "HAMMER_workable", "DIG_workable" }
local CLEAR_STEP, CLEAR_AGAIN = .25, .5
local function Clear(entry, x, z, rot, r, far, log)
    if TheWorld == nil or TheWorld.Map == nil then return nil end
    local now = (GetTime or GetStaticTime)()
    local c = log ~= nil and log.clear or nil
    if c ~= nil and c.x == x and c.z == z and c.rot == rot and c.far >= far and now < c.at + CLEAR_AGAIN then
        return c.stop
    end
    local cs, sn = math.cos(rot), math.sin(rot)
    local stop = nil
    if entry.ground or entry.solid then
        -- (its body's front edge on ground it may stand on)
        local s = 0
        while s <= far do
            local fx, fz = x + (s + r) * cs, z - (s + r) * sn
            if not TheWorld.Map:IsPassableAtPoint(fx, 0, fz) then
                stop = s
                break
            end
            s = s + CLEAR_STEP
        end
    end
    if entry.solid and TheSim ~= nil then
        local reach = stop or far
        local mx, mz = x + reach / 2 * cs, z - reach / 2 * sn
        for _, v in ipairs(TheSim:FindEntities(mx, 0, mz, reach / 2 + r + 4, nil, NOT_STOPPING)) do
            local ph = v.Physics
            if ph ~= nil and ph.GetCollisionGroup ~= nil and ph:GetCollisionGroup() == COLLISION.OBSTACLES then
                local ox, _, oz = v.Transform:GetWorldPosition()
                local dx, dz = ox - x, oz - z
                local along, side = dx * cs - dz * sn, dx * sn + dz * cs
                local R = r + (v.GetPhysicsRadius ~= nil and v:GetPhysicsRadius(0) or .5)
                if along > 0 and math.abs(side) < R then
                    local at = along - math.sqrt(R * R - side * side)
                    -- (one it's on already, as it begins: no wall to it)
                    if at > 0 and (stop == nil or at < stop) then stop = at end
                end
            end
        end
    end
    if log ~= nil then log.clear = { x = x, z = z, rot = rot, far = far, at = now, stop = stop } end
    return stop
end

-- (the shape moved with the boss off its offline way only while it goes slower than this a
-- frame - units; and by no more than SHIFT_MAX)
local SHIFT_SLOW, SHIFT_MAX = .15, 12
-- (...sliding there by at most this much a frame)
local SHIFT_STEP = .6
-- (in its way or off it: this much give either side of its edge before it's taken as changed)
local FREE_GIVE = .6

-- (on into an animation the run came to later than t - the Scrappy Werepig at you sooner than
-- offline, lifting you 6 off where the run had it going on to 12: as far on as that animation is
-- there - again_until, less again_at: the frame it began in the run)
local function OnAt(map, t, ent)
    if ent == nil or ent.AnimState == nil or t == nil then return t end
    -- (the earliest the run began it - one played over and over (a butt slam's) began again later)
    local began = nil
    -- (from the file's own steps - not unpacking every map: one unpacked is one "made already")
    for _, step in ipairs(map.of ~= nil and map.of.raw ~= nil and map.of.raw.steps or {}) do
        -- (not one struck last as it began over - again_at 0: which time round it was, not known)
        if step.again_anim ~= nil and step.again_anim ~= "" and step.again_until ~= nil and (step.again_at or 0) > 0
            and ent.AnimState:IsCurrentAnimation(step.again_anim) then
            local b = (step.again_until - step.again_at) * FRAMES
            if began == nil or b < began then began = b end
        end
    end
    if began == nil then return t end
    return math.max(t, began + ent.AnimState:GetCurrentAnimationTime())
end

-- How far along a map's run the boss had gone fi frames in (map.path - nil: not told)
local function PathAt(map, fi)
    local p = map.path
    if p == nil then return nil end
    if type(p) == "string" then
        local list = {}
        for n in p:gmatch("[^,]+") do list[#list + 1] = tonumber(n) end
        map.path, p = list, list
    end
    if #p == 0 or fi < 0 then return nil end
    return p[math.min(fi + 1, #p)]
end
SimMoves._PathAt = PathAt
-- (whether a move, run offline, stays where it began - every run's path within .3 of where it set off; a move told no path:
-- not known, false)
function SimMoves._StaysPut(entry)
    if entry._stays ~= nil then return entry._stays end
    local any, stays = false, true
    for _, src in ipairs({ entry.maps or {}, entry.free or {} }) do
        for _, map in ipairs(Decode(entry, src)) do
            local p = PathAt(map, 0)
            if p ~= nil then
                any = true
                local lo, hi, k = p, p, 0
                while true do
                    k = k + 1
                    local v = PathAt(map, k)
                    if v == nil or k > 400 then break end
                    if v < lo then lo = v end
                    if v > hi then hi = v end
                    if k + 1 > #map.path then break end
                end
                if hi - lo > .3 then stays = false break end
            end
        end
        if not stays then break end
    end
    entry._stays = any and stays
    return entry._stays
end

-- The boss's pose as the server has it, tick by tick through a move (true_range modmain sends
-- it): key - the move's first animation; go - which time round it began that; ft - seconds into
-- it, counted as predict counts t (from the key animation's start, less a frame); x, z; rot
-- (degrees). What the client sees of the boss comes late and slid between ticks - and its
-- animation's frame is not the frame its position is from: told apart here by the server, the
-- frame and where it was then together, not guessed from how far off its run it looks
SimMoves.poses = setmetatable({}, { __mode = "k" })
-- (and the later forms it is in now, by their turning animation - a move's after_anim: ent -> set,
-- as last told with its poses, after - "a,b", "-" none; it can turn back: the Eye of Terror healed
-- past its turning point is an eye again)
SimMoves.after_seen = setmetatable({}, { __mode = "k" })
-- (apx, apz: where whom it goes at stands, as the server has it - sent to players' games only, the host's
-- own seen as the server's already; kept with each pose, [5] [6])
function SimMoves.Pose(ent, key, go, ft, x, z, rot, after, aim, ram_t, ram_d, tpx, tpz, apx, apz)
    if type(after) == "string" and after ~= "" then
        local set = {}
        for name in after:gmatch("[^,]+") do
            if name ~= "-" then set[name] = true end
        end
        SimMoves.after_seen[ent] = set
    end
    local p = SimMoves.poses[ent]
    if p == nil or p.key ~= key or p.go ~= go then
        p = { key = key, go = go, list = {} }
        SimMoves.poses[ent] = p
    end
    p.at = (GetTime or GetStaticTime)()
    -- (whom the move goes at, as the server has it - none told: nil)
    p.aim = aim
    -- (its brain's charge: seconds and way it has left, from this pose - none told, or none: nil)
    if type(ram_t) == "number" and type(ram_d) == "number" and (ram_t >= 0 or ram_d >= 0) then
        p.ram = { ram_t, ram_d, ft, x, z }
        SimMoves.rams_told[ent] = p.at
    else
        p.ram = nil
    end
    -- (the spot its move goes for, as its state took it - kept for this go once told)
    if type(tpx) == "number" and type(tpz) == "number" and tpx > -1e8 then p.tpos = { x = tpx, z = tpz } end
    local list = p.list
    if type(apx) == "number" and type(apz) == "number" and apx > -1e8 then
        list[#list + 1] = { ft, x, z, rot, apx, apz }
    else
        list[#list + 1] = { ft, x, z, rot }
    end
    if #list > 150 then table.remove(list, 1) end
end
-- Whom its move goes at, as the server told with its last pose - nil: not told of late (no pose
-- for ten frames: not in a move run offline, or no word from the server - an older one)
function SimMoves.PoseAim(ent)
    local p = ent ~= nil and SimMoves.poses[ent] or nil
    if p == nil or p.aim == nil or (GetTime or GetStaticTime)() - (p.at or -1e9) > 10 * FRAMES then return nil end
    if not p.aim:IsValid() then return nil end
    return p.aim
end
-- Its brain's charge as the server told with its last pose: { seconds left (-1 none), way left (-1
-- none), ft, x, z } - nil: none, or not told of late
function SimMoves.PoseRam(ent)
    local p = ent ~= nil and SimMoves.poses[ent] or nil
    if p == nil or p.ram == nil or (GetTime or GetStaticTime)() - (p.at or -1e9) > 10 * FRAMES then return nil end
    return p.ram
end
-- (bodies whose server has told a brain's charge of them: when it last did - its poses told without
-- one after that: none under way. ent -> time)
SimMoves.rams_told = setmetatable({}, { __mode = "k" })
-- Whether the server tells, with its poses, that its brain runs no charge now - one it has told a
-- charge of before: the Rook's run_start and run from its RunAway (its attack spent), the same
-- animations as its charge, the way it faces away from you. None for over 4 frames: its charge
-- given up and taken up again leaves one pose without (the Rook pawing, its lane gone for a
-- frame). false: a charge, or not told
function SimMoves.PoseNoRam(ent)
    local p = ent ~= nil and SimMoves.poses[ent] or nil
    local last = ent ~= nil and SimMoves.rams_told[ent] or nil
    local now = (GetTime or GetStaticTime)()
    if p == nil or last == nil or now - (p.at or -1e9) > 10 * FRAMES then return false end
    return p.ram == nil and now - last > 4 * FRAMES
end
-- The spot its move goes for as the server's state took it (statemem.targetpos), this go - nil:
-- not told (yet), or none
function SimMoves.PoseTargetPos(ent)
    local p = ent ~= nil and SimMoves.poses[ent] or nil
    if p == nil or p.tpos == nil or (GetTime or GetStaticTime)() - (p.at or -1e9) > 10 * FRAMES then return nil end
    return p.tpos
end
-- (the server's pose for this go of the move at ft into it - within half a tick, its own ticks
-- being a frame apart; nil: not told (yet) - one go of it only, bound in log the first time)
local function PoseAt(ent, entry, log, ft, t_now)
    local p = ent ~= nil and SimMoves.poses[ent] or nil
    if p == nil or entry.anims == nil or p.key ~= entry.anims[1] then return nil end
    -- (nor one whose poses run on past where this go is (t_now, its time in) - the go before, this one's not told yet: the
    -- Shadow Rocky dashing twice running, in a player's game its second drawn from where its first began, 17 off, 11
    -- struck undrawn (replay CLIENT 2026-10-28). TR_OLD_POSEGO: bound all the same)
    local last = p.list[#p.list]
    if log.pose_go == nil and t_now ~= nil and last ~= nil and last[1] > t_now + 3 * FRAMES and not rawget(_G, "TR_OLD_POSEGO") then return nil end
    -- (bound to a go only one being told now - not one told before, its last word ten frames back:
    -- the same move's go before this, its poses left over)
    if log.pose_go == nil and (GetTime or GetStaticTime)() - (p.at or -1e9) > 10 * FRAMES then return nil end
    if log.pose_go == nil then log.pose_go = p.go elseif log.pose_go ~= p.go then return nil end
    for i = #p.list, 1, -1 do
        local s = p.list[i]
        if math.abs(s[1] - ft) <= FRAMES / 2 then return s end
        if s[1] < ft then break end
    end
    return nil
end
SimMoves._PoseAt = PoseAt
-- (where whom it goes at stood as the server had it, by its latest pose up to ft this go - the pose for ft itself may
-- not be here yet: one a frame on, then none, would have the aim flick between the server's and what's seen. nil: none)
-- (only this go's: its poses told up to about now - not the go before it, its poses still kept as this one begins,
-- not told yet: the Deerclops' beam drawn its first two frames at where you stood the time before. Not bound to a go
-- as PoseAt is - bound before this go's first pose, it kept to the old one)
function SimMoves.PoseAimUpTo(ent, entry, log, ft)
    local p = ent ~= nil and SimMoves.poses[ent] or nil
    if p == nil or entry.anims == nil or p.key ~= entry.anims[1] then return nil end
    if (GetTime or GetStaticTime)() - (p.at or -1e9) > 10 * FRAMES then return nil end
    local last = p.list[#p.list]
    if last == nil or last[1] > ft + 12 * FRAMES or last[1] < ft - 6 * FRAMES then return nil end
    for i = #p.list, 1, -1 do
        local e = p.list[i]
        if e[1] <= ft + FRAMES / 2 then
            if e[5] == nil or ft - e[1] > 4 * FRAMES then return nil end
            return e[5], e[6]
        end
    end
    return nil
end
-- How far this boss really gets before it stops aiming, against its run offline - seen from the
-- server's word as each go stops aiming: it holds for the whole game (Klaus' bite 1.55 offline:
-- 1.54-1.56 one game, 1.43-1.45 another, 1.36-1.37 another - the same go after go), not for the
-- run offline. ent -> key -> the last few (real / offline)
SimMoves.travel = setmetatable({}, { __mode = "k" })
local TRAVEL_KEPT = 5
local function TravelSeen(ent, key, ratio)
    local by = SimMoves.travel[ent]
    if by == nil then by = {} SimMoves.travel[ent] = by end
    local list = by[key]
    if list == nil then list = {} by[key] = list end
    list[#list + 1] = ratio
    if #list > TRAVEL_KEPT then table.remove(list, 1) end
end
-- How much short of (or past) its run offline a move set as it stops aiming really lands, as seen
-- go after go this game - by the distance it was run for: the Nightmare Werepig's slam with you a
-- few units off lands .5-.7 short (your body in its way), from 10 off as run. ent -> entry -> the
-- last few { run's distance, along }; drawn there from the start (SimMoves.Draw), not moved there
-- the frame it strikes
SimMoves.land = setmetatable({}, { __mode = "k" })
local function LandSeen(ent, entry, dist, along)
    local by = SimMoves.land[ent]
    if by == nil then by = setmetatable({}, { __mode = "k" }) SimMoves.land[ent] = by end
    local list = by[entry]
    if list == nil then list = {} by[entry] = list end
    list[#list + 1] = { dist, along }
    if #list > 8 then table.remove(list, 1) end
end
-- (the middle of those seen for a run within 1.5 of this one - two at least; else 0)
local function LandAt(ent, entry, dist)
    local by = ent ~= nil and SimMoves.land[ent] or nil
    local list = by ~= nil and by[entry] or nil
    if list == nil then return 0 end
    local s = {}
    for _, v in ipairs(list) do
        if math.abs(v[1] - dist) <= 1.5 then s[#s + 1] = v[2] end
    end
    if #s < 2 then return 0 end
    table.sort(s)
    return math.max(-1, math.min(1, s[math.floor((#s + 1) / 2)]))
end
-- How far a move set as it stops aiming really goes, against its run offline - seen as each go ends, this game, kept
-- apart by whether it was after someone then (its combat target): enraged Klaus' bite in the player's game (2026-10-28,
-- server log) went 8.3 every time it had a target - its walk taking every other frame of the leap (45 -> 4.6 a second)
-- - and 15 every time it had none; run offline 12.3. Drawn 4 on past where it came down, "it says I'm hit, I'm not".
-- The run picked is the one that goes as far as it will - not the shape moved: its path then matches it on its way.
-- ent -> entry -> "t" / "n" -> the last few { offline, real }. TR_OLD_WENT: as before
SimMoves.went = setmetatable({}, { __mode = "k" })
function SimMoves._RunWent(map)
    local a, b = PathAt(map, 0), PathAt(map, 1e6)
    return a ~= nil and b ~= nil and b - a or nil
end
-- (as a go ends: how far it went from where it began - true_range/predict; log: what Draw kept of it)
function SimMoves.WentSeen(ent, entry, went, log)
    if ent == nil or log == nil or log.went_base == nil or log.went_base < 3 or log.went_tgt == nil then return end
    -- (testing: each go told to whoever keeps them - tests/replay.lua's WENT table, every leap's real going against its run's)
    local wl = rawget(_G, "TR_WENTLOG")
    if wl ~= nil then wl[#wl + 1] = { ent.prefab, entry.name or (entry.anims and entry.anims[1]) or "?", log.went_tgt, log.went_base, went, log.went_dist or -1 } end
    -- (not one that got to whom it went for - stopped by you in its way, not going less far: the Shadow Rocky's dash run 46.9,
    -- 16.9 to you; taken for its going, the next drawn that short, 81 strikes undrawn on the bench, 2026-10-28)
    if log.went_dist ~= nil and went >= log.went_dist - 2.5 then return end
    -- (not one that hardly set off, or flung far off - stopped, cut short, shoved)
    local ratio = went / log.went_base
    if ratio < .3 or ratio > 2 then return end
    local by = SimMoves.went[ent]
    if by == nil then by = setmetatable({}, { __mode = "k" }) SimMoves.went[ent] = by end
    local e = by[entry]
    if e == nil then e = {} by[entry] = e end
    local k = log.went_tgt and "t" or "n"
    local list = e[k] or {}
    e[k] = list
    list[#list + 1] = { log.went_base, went }
    if #list > 8 then table.remove(list, 1) end
end
-- (how far it really goes for a run going bw offline: the middle of those seen for runs within 1.5 of it - two at least.
-- None so near: by the nearest ones - as far as they went at most, for a shorter run (its going has a limit of its own:
-- Klaus' bite after you, 8.3 from 11.7 offline as from 12.9 - not cut down in proportion, it struck past that, 5.35 off),
-- on in proportion for a longer one; never drawn short of where it may go by guessing. nil: nothing seen)
function SimMoves._WentFor(list, bw)
    if list == nil or #list < 2 then return nil end
    local near, nb = {}, nil
    for _, v in ipairs(list) do
        if math.abs(v[1] - bw) <= 1.5 then near[#near + 1] = v[2] end
        if nb == nil or math.abs(v[1] - bw) < math.abs(nb - bw) then nb = v[1] end
    end
    if #near < 2 then
        near = {}
        for _, v in ipairs(list) do
            if math.abs(v[1] - nb) <= 1.5 then near[#near + 1] = v[2] end
        end
        if #near < 2 then return nil end
        table.sort(near)
        if SimMoves._WentSpread(near) then return nil end
        local w = near[math.floor((#near + 1) / 2)]
        return bw < nb and math.min(bw, w) or w * bw / nb
    end
    table.sort(near)
    if SimMoves._WentSpread(near) then return nil end
    return near[math.floor((#near + 1) / 2)]
end
-- (sorted: its middle half over 1 apart - not the same go after go, nothing to go by: the Shadow Rocky's dash, 14.1 to 16.9 for
-- the same run as you stood; Klaus' bite after you 8.47-8.64)
-- (two thirds of them within 1 of their middle, at least - one go of three off (Klaus 8.3, 8.3, 9.7) still the same)
function SimMoves._WentSpread(s)
    local mid, n = s[math.floor((#s + 1) / 2)], 0
    for _, v in ipairs(s) do if math.abs(v - mid) <= 1 then n = n + 1 end end
    return n * 3 < #s * 2
end
-- (how much further on (or back) to draw it: as far as it really goes, less its run's - off by a tenth at least; 0 else.
-- The run itself kept, the one for where you are: a shorter run's bite reached 4.75 past its landing, the real one 5.35 -
-- struck, undrawn, 2026-10-28. Drawn moved on by it after the shift for where it's seen (SimMoves.Draw))
function SimMoves._WentOff(entry, src, dist, ent, log, t, target)
    local combat = ent ~= nil and ent.replica ~= nil and ent.replica.combat or nil
    local tgt = log.went_tgt
    if tgt == nil or t == nil or t < (entry.lock or 0) * FRAMES then tgt = combat == nil or combat:GetTarget() ~= nil end
    -- (where it began - as true_range/predict measures how far it went)
    if log.went_start == nil and ent ~= nil then
        local ex, _, ez = ent.Transform:GetWorldPosition()
        log.went_start = { ex, ez }
    end
    local base = nil
    for _, map in ipairs(Decode(entry, src)) do
        if base == nil or math.abs(map.dist - dist) < math.abs(base.dist - dist) then base = map end
    end
    if base == nil then return 0 end
    local bw = SimMoves._RunWent(base)
    -- (as it stops aiming: kept - what it's set to go then)
    if log.went_tgt == nil and t ~= nil and t >= (entry.lock or 0) * FRAMES then
        log.went_tgt, log.went_base = tgt, bw
        -- (how far whom it went for was then - not the run's distance, one going on past you its own way (46.9))
        if target ~= nil and target.x ~= nil and log.went_start ~= nil then
            log.went_dist = math.sqrt((target.x - log.went_start[1]) ^ 2 + (target.z - log.went_start[2]) ^ 2)
        end
    end
    if rawget(_G, "TR_OLD_WENT") or bw == nil or bw < 3 then return 0 end
    -- (only one striking once, where it comes down - not one striking all along its way: the Shadow Rocky's dash went 16.9 for
    -- 14.35 run, the shape moved on by that, the start of its way left undrawn - 35 strikes, 2026-10-28)
    if #MapSteps(base) ~= 1 then return 0 end
    local e = ent ~= nil and SimMoves.went[ent] ~= nil and SimMoves.went[ent][entry] or nil
    local want = SimMoves._WentFor(e ~= nil and e[tgt and "t" or "n"] or nil, bw)
    -- (none seen yet: from where it began as far as its run has it as it strikes - not from where it stopped aiming, seen a
    -- frame later on its way than run (Klaus' full leap, the first ones of a fight). TR_OLD_WENTSTART: from there, as before)
    if want == nil then
        if rawget(_G, "TR_OLD_WENTSTART") then return 0 end
        log.went_want = math.huge
        return 1e-9
    end
    -- (and a little on: go after go it went .2 more or less (8.47-8.64) - set at its middle, a bite at the edge of its
    -- reach, 5.35 off, went undrawn by .12)
    -- (as far as its run goes too, set from where it began: not only one going less far - Klaus' full leap, after no one,
    -- a frame later setting off than run (1.3 on as it stopped aiming, not 2.8), drawn from there 1 short, struck 4.44 off)
    log.went_want = want + .3
    if math.abs(want - bw) < .1 * bw then return 1e-9 end
    return want - bw
end
-- (its usual so far: the middle one of those seen - one stopped by you in its way, or shoved, not
-- taken for it; 1 - none seen yet)
local function TravelRatio(ent, key)
    local list = ent ~= nil and SimMoves.travel[ent] ~= nil and SimMoves.travel[ent][key] or nil
    if list == nil or #list == 0 then return 1 end
    local s = {}
    for i, v in ipairs(list) do s[i] = v end
    table.sort(s)
    return s[math.floor((#s + 1) / 2)]
end
-- Which move it's in and how far - the server's side of it (true_range modmain), and the
-- replays' (tests/replay.lua), the same: st - kept per boss; is(anim) - whether it plays that
-- now; anim_t - that animation's time; now - the clock. Returns key, go, ft while it plays one of
-- a move's animations (from its first: key), nil else. ft counted as predict counts a move's t: from
-- its first animation's start, less a frame.
function SimMoves.PoseTrack(st, prefab, is, anim_t, now)
    if st.keys == nil then
        st.keys, st.anims, st.go = {}, {}, 0
        for _, m in ipairs(SimMoves.Moves(prefab)) do
            local k = m.anims ~= nil and m.anims[1] or nil
            if k ~= nil then
                if st.anims[k] == nil then st.keys[#st.keys + 1] = k st.anims[k] = {} end
                for _, a in ipairs(m.anims) do st.anims[k][#st.anims[k] + 1] = a end
            end
        end
    end
    if st.key ~= nil then
        local still = false
        for _, a in ipairs(st.anims[st.key]) do
            if is(a) then still = true break end
        end
        -- (its first animation again - from another of its own, or begun over: a new go)
        if not still or (is(st.key) and (st.key_t == nil or anim_t < st.key_t)) then st.key = nil end
    end
    -- (in none: its moves' first animations looked for only as an animation begins - its time
    -- gone back, or not on by about a tick - not each of them asked of the game every tick for
    -- every monster near a player, idling or walking: the host's frames)
    -- (only from the tick before: asked again after a while unasked - no player near)
    if st.key == nil and not (st.idle_t ~= nil and now - st.idle_at <= FRAMES * 1.5 and anim_t >= st.idle_t + FRAMES * .5) then
        for _, k in ipairs(st.keys) do
            if is(k) then
                st.key, st.start, st.go = k, now - anim_t, st.go + 1
                break
            end
        end
    end
    st.idle_t, st.idle_at = st.key == nil and anim_t or nil, now
    st.key_t = st.key ~= nil and is(st.key) and anim_t or nil
    if st.key == nil then return nil end
    return st.key, st.go, now - st.start - FRAMES
end

-- The move, from where it began (x, z, facing rot - towards its target then); target:
-- { x, z, me } or nil; t: seconds since it began. Each part shown until it has been hit (a
-- pound's waves roll out), darker just before; a move not the same each time (entry.random:
-- where it may hit), lightly; one only on whoever it's after (entry.single), only when that's
-- you. Returns whether (px, pz) is in it.
function SimMoves.Draw(entry, x, z, rot, target, my_radius, px, pz, t, log, ent, live, len)
    -- (no target - one laid out the way it faces needs none: as far as you are, to pick its run by -
    -- Moonmaw coming down out of the sky as it appears, after no one yet, struck you, drawn as nothing)
    if target == nil and entry.frame == "facing" and not entry.single and px ~= nil then
        target = { x = px, z = pz, me = true }
    end
    if target == nil or (entry.single and not target.me) then
        return false
    end
    local x_in, z_in = x, z
    local dist = math.sqrt((target.x - x) ^ 2 + (target.z - z) ^ 2)
    -- (one getting on its way before it stops aiming: how far you are from where it began, as
    -- the offline runs have it - not from where it has got to: Klaus' bite setting off, the
    -- distance shrank under it and the shape jumped 1.8 short within one tick)
    local ps = entry.anchor == "lock" and entry.frame == "target" and log ~= nil and log.prestart or nil
    if ps ~= nil then dist = math.sqrt((target.x - ps[1]) ^ 2 + (target.z - ps[2]) ^ 2) end
    if entry.frame == "facing" then
        -- (laid out the way it faces: what counts is how far along that way its target is - one off
        -- to the side is nearer that way; the Werepig's slam lands short of you then)
        -- (you well off to its side - over 60 degrees - and it isn't going for you: as it went in
        -- the offline run with its target off to its side (entry.off) - its full way, or as short
        -- as it goes (Frostjaw's dive))
        local along = (target.x - x) * math.cos(rot) - (target.z - z) * math.sin(rot)
        -- (made with its back to you - Armored Bearger's butt slam: how far behind it you are)
        if entry.behind then along = -along end
        -- (one that goes as far for you behind it as in front - entry.back, Frostjaw's dive)
        if entry.back and along < 0 then along = -along end
        if along >= dist * .5 or (target.me and along > 0 and entry.off == nil) then
            -- (it's after you, off to its side but still in front: as if you'll be in its way by
            -- the time it goes - it lands well clear of you otherwise; the Werepig's slam came in
            -- short only a beat before it hit, when you stepped inside its 60 degrees)
            dist = along
        else
            dist = entry.off or 1e6
        end
    end
    -- (one whose length isn't up to where you are - the Ancient Guardian's charge: its whole way,
    -- unless something's in it)
    -- (len: as far as it has still to go, seen from where it is now)
    if entry.fixed then dist = len or 1e6 end
    -- (one that its target's body stops - a leap landing at you: as it goes with them in its way
    -- now (stopped where they are), or not (on its whole way) - live: where its target is now)
    local src = nil
    -- (once it has gone past where you are - or you off its way as it went - that's settled: as
    -- it was then, not changed again by where you go after - its last strikes came up out of
    -- nowhere, drawn for another distance)
    local passed = log ~= nil and log.passed or nil
    if passed ~= nil then
        dist, src = passed.dist, passed.src
    elseif entry.free ~= nil and live ~= nil then
        local bx, bz = x, z
        if ps ~= nil then bx, bz = ps[1], ps[2] end
        local dx, dz = live.x - bx, live.z - bz
        local c, s = math.cos(rot), math.sin(rot)
        local along, side = dx * c - dz * s, dx * s + dz * c
        local reach = (ent ~= nil and ent.GetPhysicsRadius ~= nil and ent:GetPhysicsRadius(0) or 1) + .5
        -- (still ahead of it as it is now - on its way, it has gone some: one it has passed, or
        -- that stepped off its way, no longer stops it)
        local gone = 0
        if ent ~= nil then
            local ex, _, ez = ent.Transform:GetWorldPosition()
            gone = (ex - bx) * c - (ez - bz) * s
        end
        -- (or as far off its way as it goes for you, run offline - it stops by its own say, where
        -- you are: the Scrappy Werepig's tackle)
        -- (in its way or off it, told with some give: stepping a hair across its edge as it aims
        -- flipped the shape between the two - kept as it was until you're well across)
        local w = entry.reach or reach
        local was = log ~= nil and log.inway or nil
        local give = was == nil and 0 or (was and FREE_GIVE or -FREE_GIVE)
        local inway = along > gone and math.abs(side) < w + give
        if log ~= nil then log.inway = inway end
        -- (gone past you as you stood in its way - reached you, a leap landing a step past: as it was
        -- for you there, its strike round itself where it landed - not its whole way on (free), drawn
        -- ahead of it with you behind: the Dangling Depth Dweller, 207 struck undrawn so; VERIFY_PLAN
        -- 6.0a. Not one you stepped off the way of: that's the free one)
        -- (a strike on its target alone, laid out to it (single, frame "target"), it still by you - not a
        -- swing that goes on its whole way, its target or not (the Scrappy Werepig's pounce: FALSE
        -- 10 -> 199 so), nor one gone off far (the Dreadeye's teleport))
        -- (a leap gone a step past you, landed: you within 3 of it still - not a top-level local: the
        -- file's at Lua's 200)
        -- (one that goes after you as it goes (follow) - a leap: not one set down by you with no going
        -- (the Dreadeye's teleport onto you, 315 -> 369 so))
        local near_now = false
        if ent ~= nil and entry.single and entry.frame == "target" and entry.follow ~= nil then
            local ex, _, ez = ent.Transform:GetWorldPosition()
            near_now = (live.x - ex) ^ 2 + (live.z - ez) ^ 2 < 3 * 3
        end
        local reached = near_now and not inway and was == true and math.abs(side) < w + FREE_GIVE and log ~= nil
            and log.inway_dist ~= nil and log.inway_at ~= nil and (GetTime or GetStaticTime)() - log.inway_at <= 3 * FRAMES
            and not rawget(_G, "TR_OLD_PASS")
        -- (kept so till it's settled: not taken for one off its way the frame after)
        if reached then log.inway = true end
        if entry.reach ~= nil then
            if inway then
                dist = along
                if log ~= nil then log.inway_dist, log.inway_at = dist, (GetTime or GetStaticTime)() end
            elseif reached then
                dist = log.inway_dist
                if gone > .3 then log.passed = { dist = dist, src = nil } end
            else
                src = entry.free
                if log ~= nil and gone > .3 then log.passed = { dist = dist, src = src } end
            end
        elseif inway then
            -- (off to one side of its way: it bumps you further on than square on)
            local sd = math.min(math.abs(side), reach)
            dist = along + reach - math.sqrt(reach * reach - sd * sd)
            if log ~= nil then log.inway_dist, log.inway_at = dist, (GetTime or GetStaticTime)() end
        elseif reached then
            dist = log.inway_dist
            if gone > .3 then log.passed = { dist = dist, src = nil } end
        else
            src = entry.free
            if log ~= nil and gone > .3 then log.passed = { dist = dist, src = src } end
        end
    end
    -- (what's in its way in the game - the sea's edge, a pillar: it stops there, as it does at
    -- your body - drawn as for you standing there; one whose length isn't up to you (fixed): cut
    -- to it)
    if (entry.ground or entry.solid) and ent ~= nil and ent.GetPhysicsRadius ~= nil then
        local r = ent:GetPhysicsRadius(0)
        local far = entry.fixed and 30 or math.min(dist, 30)
        local stop = Clear(entry, x, z, rot, r, far, log)
        if stop ~= nil then
            local d = entry.fixed and stop or stop + r + .5
            if d < dist then dist, src = d, nil end
        end
    end
    -- (a leap set as it stops aiming: how much further on it really goes this game - SimMoves._WentOff)
    if entry.anchor == "lock" and log ~= nil and not entry.fixed and not entry.still and not entry.random then
        log.went_off = SimMoves._WentOff(entry, src, dist, ent, log, t, target)
    end
    local best, ready = nil, nil
    for _, map in ipairs(Decode(entry, src)) do
        -- (one whose length isn't up to you: never one longer than it has left - drawn on past
        -- where it stops)
        if entry.fixed and map.dist > dist + .01 and best ~= nil then
            -- (skip)
        elseif best == nil or math.abs(map.dist - dist) < math.abs(best.dist - dist)
            or (entry.fixed and best.dist > dist + .01) then
            best = map
        end
        -- (one drawn before, its outlines and triangles made)
        if map.of.steps ~= nil and map.of.steps.ready and not (entry.fixed and map.dist > dist + .01)
            and (ready == nil or math.abs(map.dist - dist) < math.abs(ready.dist - dist)) then
            ready = map
        end
    end
    if best == nil then
        return false
    end
    -- (the one drawn last, still near enough - you stepping to and fro by a hair: kept, not
    -- another made)
    local prev = log ~= nil and log.map or nil
    -- (one whose far edge goes on with you - entry.follow: drawn moved on by the difference, a
    -- new one made only well off - a spell cast where you stand slides along under you)
    -- (one that strikes by what it puts down where you are, drawn on its own once there - the War
    -- Machine's beam: on with you however far, not left at the furthest run offline)
    local puts_own = entry.puts ~= nil
    for _, p in ipairs(entry.puts or {}) do
        local hz = (Data._hazards or {})[p]
        if hz == nil or hz.in_move then puts_own = false end
    end
    local follows = entry.follow ~= nil and (dist <= SimMoves._FollowLimit(entry) + .5 or puts_own)
    -- (held on only if moving it on is the run for there - SimMoves._SlideFits; TR_OLD_SLIDEFIT: always, as before)
    local slides_ok = not follows or rawget(_G, "TR_OLD_SLIDEFIT") or SimMoves._SlideFits(entry, src)
    local hold = (follows and slides_ok) and FOLLOW_HOLD or HOLD
    if prev ~= nil and prev ~= best and prev.kind == best.kind and prev.of.steps ~= nil and prev.of.steps.ready
        and math.abs(prev.dist - dist) <= hold and not (entry.fixed and prev.dist > dist + .01) then
        best = prev
    end
    -- (a distance not drawn before costs its making - one every NEW_EVERY at most: until its turn,
    -- the nearest one drawn already; you running about as it aims would make one every frame)
    -- (not one well off where you are, though - you walking off as Crystal Deerclops aims, its
    -- lance kept short of you half a second, then jumping 3 units on at once: made now)
    if not (best.of.steps ~= nil and best.of.steps.ready) and ready ~= nil then
        local now = (GetTime or GetStaticTime)()
        -- (one that can't be moved on whole (SimMoves._SlideFits): no further than it may be held - the tri-beam handed one 1 off
        -- while its own was made, then moved on along its middle, its side beams turned in for a moment; the reviewer 2026-10-26)
        if budget.next ~= nil and now < budget.next and now >= budget.next - NEW_EVERY
            and math.abs(ready.dist - dist) <= (slides_ok and NEW_NEAR or HOLD) then
            best = ready
        else
            budget.next = now + NEW_EVERY
        end
    end
    -- (on its way already, it shows how far it's going - Frostjaw's dive, its length set by where
    -- you were, with a lead, as it last looked: the run that has gone as far by now, once it's
    -- clearly another than the one thought)
    -- (once told so, kept - not back to the one thought as the runs come alike again near its end)
    -- (one seen from where it stops aiming: only from then - till then, from where it is)
    -- (not where things it put down strike - random, crystals: they stay where they were put)
    -- (nor once what it strikes by is all put down - the Klaus deer's circles: they stay, the deer
    -- walking off was taking them with it)
    -- (its last strike over: kept where it was then - a lava leaping at you, stopped short by your
    -- body as it bit, the shape pulled back after it with nothing left to strike)
    -- (stopped aiming: from where it was drawn the frame before, as on by its path - not from where
    -- it's seen then: seen a frame late, it hadn't set off yet, and the shape went back by the frame
    -- it had gone (the Vault Guard's leap, Klaus' bite - 0.7 back as it stopped aiming))
    -- (where it really was as it stopped aiming, told by the server - true_range/predict a.locked,
    -- log.lock_exact: as given; else from where it was drawn the frame before)
    -- (stopped aiming, told where by the server: how far it really went to there, against its run
    -- - kept for its next go, TravelSeen)
    if entry.anchor == "lock" and log ~= nil and log.lock_exact and not log.travel_told and log.prestart ~= nil and ent ~= nil and entry.anims ~= nil then
        log.travel_told = true
        local before = PathAt(best, 0)
        if before ~= nil and before < -PRELOCK_MIN and before > -PRELOCK_MOVE then
            local ps0 = log.prestart
            local went = (x_in - ps0[1]) * math.cos(rot) - (z_in - ps0[2]) * math.sin(rot)
            -- (by its own run's entry - Klaus enraged is another, 0.83 of its run against 1.08 calm: the
            -- two kept as one, the calm one's ratio drew the enraged bite on too far, pulled back as
            -- it stopped aiming; and not one that hardly set off - stopped, or cut short: 0)
            local ratio = went / -before
            if ratio > .3 then TravelSeen(ent, entry, ratio) end
        end
    end
    if entry.anchor == "lock" and log ~= nil and not log.lock_exact and log.prelock ~= nil and t ~= nil and t >= (entry.lock or 0) * FRAMES then
        local q = log.prelock
        if (q[1] - x) ^ 2 + (q[2] - z) ^ 2 < (PRELOCK_MOVE + 1) ^ 2 then x, z = q[1], q[2] end
    end
    local spent = false
    -- (one striking once (entry.single) - not one striking on and on, a tackle's lift past its run)
    if t ~= nil and log ~= nil and entry.single and best.path ~= nil and not entry.fixed and not entry.random then
        local last_at = 0
        for _, st in ipairs(MapSteps(best)) do last_at = math.max(last_at, st.at) end
        spent = t > (last_at + 1) * FRAMES
        if spent then
            if log.path_fit ~= nil then best = log.path_fit end
            local sh = log.shift
            if sh ~= nil and math.abs(sh[1]) + math.abs(sh[2]) > .05
                and not (entry.set_until ~= nil and t > (entry.set_until + 1) * FRAMES) then
                x, z = World(x, z, rot, sh[1], sh[2])
            end
        end
    end
    -- (a move set as it stops aiming, landing short of or past its run as seen this game - drawn
    -- there all along, as the shift below would take it there once it lands (LandAt))
    local land_ok = entry.anchor == "lock" and not entry.still and not entry.fixed and not entry.random and log ~= nil and t ~= nil
    if land_ok then
        if log.land == nil or t < (entry.lock or 0) * FRAMES then log.land = LandAt(ent, entry, best.dist or 0) end
        if math.abs(log.land) > .05 then x, z = World(x, z, rot, log.land, 0) end
        -- (and once it's struck and on a moment: how far off its run it really was, for its next go)
        if not log.land_told and entry.first ~= nil and t >= (entry.first + 8) * FRAMES and log.lock_exact ~= false then
            log.land_told = true
            if ent ~= nil then LandSeen(ent, entry, best.dist or 0, log.land + (log.shift ~= nil and log.shift[1] or 0)) end
        end
    end
    -- (set as it stopped aiming - a leap where it lands: below, moved to and fro by less than .6
    -- no more)
    local set_now = entry.anchor == "lock" and not entry.still and not entry.fixed and not entry.random
    -- (and one not set as it stops aiming but on its way like one - Frostjaw's dive from the water:
    -- not stepped back on its way while late, not moved once struck; the same as a set one)
    local leap_set = set_now or (entry.anchor == nil and not entry.still and not entry.fixed and not entry.random and entry.first ~= nil
        -- (not one that runs on past you as it strikes (free) - the Scrappy Werepig's tackle, carrying
        -- you along: held, 6 of its strikes went undrawn)
        and entry.free == nil)
        and log ~= nil and t ~= nil and t >= (entry.lock or 0) * FRAMES
    -- (set, struck, all it has left one part with its first strike (log.one_part, below): the run
    -- it was drawn as then, kept - not another taken for it as it lands, the Ancient Guardian's
    -- landing moved .5 at frame 60, 13 -> 13.5)
    if leap_set and log ~= nil and t ~= nil and entry.first ~= nil and t >= entry.first * FRAMES then
        if log.one_part and log.first_best ~= nil then
            best, log.path_fit = log.first_best, log.first_best
            -- (and how far it was then: its far edge no more on with you (follow) - .25 to and fro)
            dist = log.first_dist
        end
    end
    local shifting = ent ~= nil and t ~= nil and not entry.fixed and not entry.random and best.path ~= nil and not spent
        and (entry.anchor ~= "lock" or t >= (entry.lock or 0) * FRAMES)
        and not (entry.set_until ~= nil and t > (entry.set_until + 1) * FRAMES)
        -- (one set as it stops aiming: only once the server has told where it stood then - in the
        -- game its first frame stopped is often a frame before that word: shifted from where it
        -- was thought to be, the shape went on .26 and back the next, Klaus' bite every time. With
        -- no word (an older server), two frames on)
        and (entry.anchor ~= "lock" or log == nil or log.lock_exact or t >= ((entry.lock or 0) + 2) * FRAMES)
    -- (drawn again at the same moment - the game draws several frames a tick, the boss slid
    -- between where it was and where it is, and while paused: as it was worked out at that moment,
    -- not stepped on again each time - the shape went out and back within one tick)
    if shifting and log ~= nil and log.shift_t == t then
        if log.path_fit ~= nil then best = log.path_fit end
        local sh = log.shift
        if sh ~= nil and math.abs(sh[1]) + math.abs(sh[2]) > .05 then x, z = World(x, z, rot, sh[1], sh[2]) end
    elseif shifting then
        if log ~= nil then log.shift_t = t end
        local fi = math.floor(OnAt(best, t, ent) / FRAMES + .5)
        local ex, _, ez = ent.Transform:GetWorldPosition()
        local gone = (ex - x) * math.cos(rot) - (ez - z) * math.sin(rot)
        local aside = (ex - x) * math.sin(rot) + (ez - z) * math.cos(rot)
        -- (on past the furthest run made, its far edge with you (follow, no limit): its real run
        -- that much longer - the Ancient Guardian's leap, you 19.4 off, landing 21.4 on: how far
        -- it's gone, scaled to the run drawn - not shifted on by the difference as well as moved on
        -- by it below (follow): the landing slid on 1.2 past where it came down)
        do
            local ext = follows and dist - best.dist or 0
            if ext > .01 and gone > 0 then
                local pend = PathAt(best, 1e6)
                if pend ~= nil and pend > .5 then gone = gone * pend / (pend + ext) end
            end
        end
        local lg = log ~= nil and log.last_pos or nil
        local slow = lg ~= nil and (ex - lg[1]) ^ 2 + (ez - lg[2]) ^ 2 < SHIFT_SLOW * SHIFT_SLOW
        if log ~= nil then log.last_pos = { ex, ez } end
        -- (told by how far it went only while it's going - stood still, stopped by you, any run
        -- that stood still as long would fit: the shape moved with it instead, below)
        local held = log ~= nil and log.path_fit or nil
        local base = held or best
        -- (how far a run had got by now, nearest to how far it's seen: within PATH_LATE frames back
        -- - its position comes a few frames late, never early, and leaping fast (the Nightmare
        -- Werepig's slam, 30 a second) that much short took it for a run a few units shorter: the
        -- shape jumped back at it, then out again)
        -- (and between two frames: a unit a frame, it's seen as often between them as on one)
        local function Near(map, k0)
            local v, last = nil, nil
            for k = k0 - PATH_LATE, k0 + PATH_LATE do
                local p = PathAt(map, k)
                if p ~= nil and (v == nil or math.abs(gone - p) < math.abs(gone - v)) then v = p end
                if p ~= nil and last ~= nil and (gone - p) * (gone - last) <= 0 then return gone end
                last = p
            end
            return v
        end
        local cur = Near(base, fi)
        if cur ~= nil and (held ~= nil or (not slow and lg ~= nil and math.abs(gone - cur) > .25)) then
            local fit, err = nil, nil
            for _, map in ipairs(Decode(entry, src)) do
                local p = Near(map, math.floor(OnAt(map, t, ent) / FRAMES + .5))
                if p ~= nil and (err == nil or math.abs(p - gone) < err - .01) then fit, err = map, math.abs(p - gone) end
            end
            if fit ~= nil and err < math.abs(gone - cur) - .1 and not (log ~= nil and log.one_part)
                and not (leap_set and entry.first ~= nil and t >= (entry.first - 1) * FRAMES) then base = fit end
            if base ~= best then
                best = base
                if log ~= nil then log.path_fit = base end
                fi = math.floor(OnAt(best, t, ent) / FRAMES + .5)
            end
        end
        -- (and what's left between: it got less far or further than offline - Frostjaw's slide
        -- stopped short by you in its way: what it strikes round itself is there, the shape moved
        -- back with it, by that much)
        -- (only while it goes slowly: on its way, it's a frame ahead or behind the offline run as
        -- the game's ticks fall - Frostjaw's dive at 8 a second, a shape jumping to and fro)
        -- (or shoved off its way - you pushing it, or it running into you and bounced back: to
        -- the side as well - all that's slow enough to be no frame's jitter)
        -- (moving fast again: as it was last seen slow - not back and forth, the shape jumping)
        -- (off to its side it went no way offline: that, all along; and the shape slid there, not
        -- jumped - a boss knocked aside two units in four frames)
        if log ~= nil then
            -- (shoved about - you pushing into it as it swings: as far as it really is from where the
            -- run had it, every frame - the run's nearest moment within two frames, not this very
            -- one: on its way as offline, a frame early or late is no shove; going fast (a leap, half
            -- a unit a frame and more), nor seen up to PATH_LATE frames late, or between two frames -
            -- the shape slid back at it a unit or so. Not slow: a bear's swipes, shoved, went unseen)
            local want = { 0, aside }
            local near, last = nil, nil
            local p0, p1 = PathAt(best, fi - PATH_LATE), PathAt(best, fi)
            -- (and it's still going itself: stopped short - by you in its way - is no late picture)
            local fast = p0 ~= nil and p1 ~= nil and math.abs(p1 - p0) >= PATH_LATE * .5
            for k = fast and fi - PATH_LATE or fi - 2, fi + 2 do
                local v = PathAt(best, k)
                if v ~= nil and (near == nil or math.abs(gone - v) < math.abs(gone - near)) then near = v end
                if fast and v ~= nil and last ~= nil and (gone - v) * (gone - last) <= 0 then near = gone break end
                last = v
            end
            if near ~= nil then want[1] = gone - near end
            -- (run into something on its way - its last four frames under .85 of its run's going at full
            -- pace, its run going on further still: stopped short, no late picture (a late one goes as
            -- fast, only later). Drawn where it comes down going on as it goes now. Enraged Klaus' bite
            -- in the user's game: 8.3 of its 15 four times, 10.9 slowed every third frame (.77) - the shape held on where it would have)
            log.lead_short = nil
            if leap_set and not rawget(_G, "TR_OLD_LEAPSHORT") then
                local hist = log.lead_hist or {}
                log.lead_hist = hist
                if log.lead_s == nil then
                    -- (its run: the frames it goes, its pace at full)
                    PathAt(best, 0)
                    local n = type(best.path) == "table" and #best.path or 0
                    local s, e, peak = nil, nil, 0
                    for k = 0, n - 2 do
                        local step = PathAt(best, k + 1) - PathAt(best, k)
                        -- (not a step over 3 a frame - a warp, not its pace: the Blighted Rock Master's dash 9.73 in a frame,
                        -- taken for its pace, "stopped short" each go, its shape thrown 9.73 on for a frame and back - the
                        -- player's "flickering frame" (frame_check, lag 0723, 8 of 8 dashes) 2026-10-29. TR_OLD_LEAPWARP)
                        if step > .05 and (step <= 3 or rawget(_G, "TR_OLD_LEAPWARP")) then s, e, peak = s or k, k + 1, math.max(peak, step) end
                    end
                    log.lead_s, log.lead_e, log.lead_peak = s or -1, e or -1, peak
                end
                -- (only frames it was seen going in, from its second - not a step before, as it turns,
                -- nor frames still to come in the picture: Klaus' plain bite, its shuffle and a frame
                -- late taken for short - 3 strikes missed)
                if log.lead_s >= 0 and fi >= log.lead_s then
                    if log.lead_m ~= nil or (#hist > 0 and gone - hist[#hist] > .05) then log.lead_m = (log.lead_m or 0) + 1 end
                end
                hist[#hist + 1] = gone
                if #hist > 5 then table.remove(hist, 1) end
                -- (a run of over .6 a frame: the Boarrior's dash (.67) - not a slower one that steers as it goes,
                -- measured short along the way it set off: the Archive Centipede's roll (.5), 8 drawn-in with no strike)
                local peak = log.lead_peak
                local land = PathAt(best, log.lead_e)
                if (log.lead_m or 0) >= 6 and #hist == 5 and peak * 4 > 2.4 and land ~= nil and fi <= log.lead_e + 1 then
                    local went = gone - hist[1]
                    if went < .85 * 4 * peak and land - gone > 1.5 then
                        local now_land = gone + math.max(0, went / 4) * math.max(0, log.lead_e - fi)
                        log.lead_short = peak
                        want[1] = math.min(want[1], now_land - land)
                    end
                end
            end
            local off = math.sqrt(want[1] ^ 2 + want[2] ^ 2)
            if off > SHIFT_MAX then want = { 0, 0 } end
            log.want = want
            local sh = log.shift or { 0, 0 }
            local dx, dz = want[1] - sh[1], want[2] - sh[2]
            -- (set as it stopped aiming, a leap: a small step back the way it last went not made - its
            -- going seen a frame early or late, the shape went to and fro as it leapt (Klaus' bite,
            -- the lavae, the Nightmare Werepig: on, back, on again). One on its way any distance,
            -- or back by .6 or more - shoved, Armored Bearger's combo at your reach - made.
            -- Tested over every kept log (tests/leap_stat.ps1): turned back 0.96 times a leap -> 0.76,
            -- strikes missed the same, 8. Stopping all of it - the run kept as set, or no shove after -
            -- steadier still, 30 missed; with no frames' limit 0.60, one strike more missed offline)
            -- (set, and not striking yet - on its way: no step back along it at all. Set off a frame
            -- later than run offline, it's seen behind its run - not shoved: the shape went back,
            -- and on again as it first struck - the Nightmare Werepig's slam .2, the lavae)
            -- (only behind its run on its way - late, not back from where it set off: one shoved back
            -- behind it is, Armored Bearger's combo - 17 strikes missed kept forward)
            if leap_set and gone > -.1 and entry.first ~= nil and t < entry.first * FRAMES and dx < 0 and not log.lead_short then dx = 0 end
            -- (nor on, if it's ahead of its run by no more than its run goes in a frame - a frame early,
            -- not further: the lavae set off a frame early nearly every time (.28 on), to land just
            -- where run - the shape went on in the air and back as it struck. Further ahead than
            -- that, on: Armored Bearger's lunge, slow, its frame's going a hair)
            -- (and not only before its first strike: the Twins' charges strike from the frame they
            -- set off (34) - one a frame early went on .28 at you, and back 6 frames on, every time)
            if set_now and dx > 0 and entry.first ~= nil then
                local pa, pb = PathAt(best, fi), PathAt(best, fi + 1)
                local pc = PathAt(best, fi + 2)
                local frame_go = 0
                if pa ~= nil and pb ~= nil then frame_go = math.abs(pb - pa) end
                if pb ~= nil and pc ~= nil then frame_go = math.max(frame_go, math.abs(pc - pb)) end
                -- (about a whole frame's going - half of it at least: a hair more, Armored Bearger at the
                -- edge of its reach (.06), is no frame early)
                if frame_go > .1 and want[1] >= .15 and want[1] <= frame_go + .05 then dx = 0 end
            end
            if set_now then
                local ld = log.shift_dir
                -- (along its way only - where it is in its run, seen a frame early or late; not to its side:
                -- the Nightmare Werepig's pounce, you crossing it, moved with you aside)
                -- (and four frames at most: still wanted back the fifth, it's back - not to and fro)
                if ld ~= nil and dx * ld[1] + dz * ld[2] < 0 and math.sqrt(dx * dx + dz * dz) < .6 and (log.shift_held or 0) < 4 then
                    dx, dz = 0, 0
                    log.shift_held = (log.shift_held or 0) + 1
                else
                    log.shift_held = 0
                end
                if math.abs(dx) + math.abs(dz) > .01 then log.shift_dir = { dx, dz } end
            end
            -- (set, and struck: all it has left one part with its first strike - the Ancient Guardian's
            -- landing, its middle and the ring round it - not moved now: it was drawn on to where
            -- it really landed as it struck, .1 to 1.25, the shape moving the moment it hit. A later
            -- strike of its own - a combo's next blow - still moves)
            -- (not only from its first strike: from a frame before its last part - Frostjaw's dive
            -- from the water, a splash as it leaps (12) and its landing (25): two parts, never held,
            -- it pulled back as it landed. Looked at again each frame till held)
            if leap_set and entry.first ~= nil and t >= (entry.first - 1) * FRAMES then
                if not log.one_part then
                    local f_next = math.floor(t / FRAMES + .5) + 1
                    local cl, one, any = nil, true, false
                    for _, st in ipairs(MapSteps(best)) do
                        if st.at >= f_next - 1 then
                            any = true
                            cl = cl or st.cl
                            -- (or a ring of its wave - kept with it till the last (keep_until))
                            if st.cl ~= cl and not (cl.keep_until ~= nil and st.at <= cl.keep_until) then one = false end
                        end
                    end
                    -- (its last part next frame or now - not one still to come further on)
                    if any and one and cl ~= nil and cl.at <= f_next then
                        log.one_part = true
                        -- (the run it's drawn as now, as it strikes - after this frame's fitting: kept from here)
                        log.first_best, log.first_dist = best, dist
                    end
                end
                -- (by under 1.5 - landed further off than that, 3.4 on, it goes there: kept, the ring
                -- round where it really came down went undrawn)
                if log.one_part and dx * dx + dz * dz < 1.5 * 1.5 and not log.lead_short then dx, dz = 0, 0 end
            end
            local d = math.sqrt(dx * dx + dz * dz)
            -- (stopped short: back as fast as its run goes - not left behind it, .6 a frame)
            local step = math.max(SHIFT_STEP, log.lead_short or 0)
            if d > step then dx, dz = dx * step / d, dz * step / d end
            log.shift = { sh[1] + dx, sh[2] + dz }
            if math.abs(log.shift[1]) + math.abs(log.shift[2]) > .05 then
                x, z = World(x, z, rot, log.shift[1], log.shift[2])
            end
        end
    end
    -- (and on by as much as it really goes further than its run this game (SimMoves._WentOff) - not twice: the shift for
    -- where it's seen (stopped short) already that way, only what's left beyond it)
    -- (where it lands set from where it began, as far as it really goes - not added to the rest of the moving about: the
    -- drawn start already moved for how far it got before it stopped aiming, 1.5 drawn short again, struck. Seen gone
    -- further already: from there)
    if log ~= nil and log.went_off ~= nil and log.went_off ~= 0 and log.went_want ~= nil and log.went_start ~= nil then
        local ps, c, s = log.went_start, math.cos(rot), math.sin(rot)
        -- (where its run has it as it strikes, set there - not where its run ends: a frame on at full pace, 1.5 further, the
        -- bite drawn that short of a real one; it strikes no further on than where it stops)
        -- (its path's value at a frame is where it is once that frame has gone: struck at frame 35 from where frame 34 left it -
        -- the bite's cells round 10.58, its path 12.10 at 35; set from 35 the bite was drawn 1.5 short)
        local pend = PathAt(best, entry.first ~= nil and entry.first - 1 or 1e6)
        if pend ~= nil then
            -- (where it is as it strikes: no further than its run has it then - a full leap goes on 1.7 after its bite)
            local want = math.min(log.went_want, pend - (PathAt(best, 0) or 0))
            -- (none seen yet, and seen stopping short already (the shift for it, back): left as that has it)
            local unseen = log.went_want == math.huge and log.shift ~= nil and (log.lead_short or log.shift[1] < -.3)
            -- (no further from where it began than you are, and as far past you as its run went past its target - its maps
            -- are kept by how far you were as it stopped aiming, their paths from where the run began: the W.A.R.B.O.T.,
            -- walking onto you before its leap, took the run at 0.1 - one that walked 13.9 first - drawn 13.9 on from where it
            -- began, 3.5 from you: 10.5 ahead a frame, lag 1342 and replay CLIENT 2026-10-29. TR_OLD_WENTCAP)
            if target ~= nil and entry.lock ~= nil and not rawget(_G, "TR_OLD_WENTCAP") then
                local plock = PathAt(best, entry.lock)
                if plock ~= nil then
                    local past = math.max(0, (pend - plock) - (best.dist or 0))
                    local to_you = math.max(0, (target.x - ps[1]) * c - (target.z - ps[2]) * s)
                    -- (only a run that walked further before it stopped aiming than you are from here - not this go's: kept
                    -- to its own run otherwise, not moved with you each frame - Klaus' wobbles 0 -> 4 when every one was)
                    local p0 = PathAt(best, 0)
                    if p0 ~= nil and plock - p0 > to_you + 1 then want = math.min(want, to_you + past) end
                end
            end
            if ent ~= nil then
                local ex, _, ez = ent.Transform:GetWorldPosition()
                want = math.max(want, (ex - ps[1]) * c - (ez - ps[2]) * s)
            end
            if not unseen then x, z = World(x, z, rot, want - ((x - ps[1]) * c - (z - ps[2]) * s + pend), 0) end
        end
    end
    -- (set, told by the server where it stood: where it was thought to be as it still aimed a
    -- little further on its way - by under .6, on its line - kept on by that much; laid there, the
    -- shape not pulled back the frame it stopped aiming (the first bite of a game, its going not
    -- learned yet). Short of it: as told, never drawn short. Where it really is (the shift above)
    -- reckoned from the server's - not undone by it)
    if set_now and log.lock_exact and log.prelock ~= nil then
        if log.keep == nil then
            local q = log.prelock
            local c, s = math.cos(rot), math.sin(rot)
            local ahead = (q[1] - x_in) * c - (q[2] - z_in) * s
            local aside = (q[1] - x_in) * s + (q[2] - z_in) * c
            log.keep = (ahead > 0 and ahead < .6 and math.abs(aside) < .3) and ahead or 0
        end
        if log.keep > 0 then x, z = World(x, z, rot, log.keep, 0) end
    end
    if follows and (best.dist <= SimMoves._FollowLimit(entry) + .5 or puts_own) and math.abs(dist - best.dist) > .01 then
        x, z = World(x, z, rot, dist - best.dist, 0)
    elseif not entry.fixed and not entry.random and dist < 1e5 and math.abs(dist - best.dist) > .01
        and math.abs(dist - best.dist) < 2
        and (t == nil or t < (entry.lock or 0) * FRAMES or (entry.anchor == "lock" and entry.still)) then
        -- (and after, for one thrown where it was aimed - Crystal Deerclops' lance: aimed 10.34
        -- off, the one made for 10.5 drawn as it was, its ring 0.16 too far - you 5.53 from where it
        -- came down, its reach 5.5, were drawn well inside it)
        -- (as it aims, you running in or off: the one made for a distance near yours, moved on by
        -- as much as its far edge goes with the distance (from the one beside it, made already) -
        -- a new one made only every NEW_EVERY, it stepped a unit at a time, your way)
        -- (its far edge where yours is: between the two made either side of you - the same whichever
        -- of them is drawn, so no step as it changes over, nor to and fro)
        local fb = SimMoves._FarOf(best)
        local lo, hi = nil, nil
        for _, map in ipairs(Decode(entry, src)) do
            if map.of.steps ~= nil then
                if map.dist <= dist and (lo == nil or map.dist > lo.dist) then lo = map end
                if map.dist >= dist and (hi == nil or map.dist < hi.dist) then hi = map end
            end
        end
        if fb ~= nil and lo ~= nil and hi ~= nil and hi.dist - lo.dist > .01 and hi.dist - lo.dist <= 3 then
            local fl, fh = SimMoves._FarOf(lo), SimMoves._FarOf(hi)
            local want = fl + (fh - fl) * (dist - lo.dist) / (hi.dist - lo.dist)
            local off = math.max(-2, math.min(2, want - fb))
            if math.abs(off) > .01 then x, z = World(x, z, rot, off, 0) end
        elseif fb ~= nil and entry.still and entry.anchor == "lock" then
            -- (thrown where you are, none made yet past you: on as the two made nearest you go on -
            -- not left a unit short, then a jump; and no further than they do - the game throws
            -- it 14 at most, you further off)
            local a, b = nil, nil
            for _, map in ipairs(Decode(entry, src)) do
                if map.of.steps ~= nil and (hi == nil and map.dist <= dist or lo == nil and map.dist >= dist) then
                    if a == nil or math.abs(map.dist - dist) < math.abs(a.dist - dist) then
                        a, b = map, a
                    elseif b == nil or math.abs(map.dist - dist) < math.abs(b.dist - dist) then
                        b = map
                    end
                end
            end
            if a ~= nil and b ~= nil and math.abs(a.dist - b.dist) > .01 then
                local fa, fbb = SimMoves._FarOf(a), SimMoves._FarOf(b)
                local want = fa + (fa - fbb) * (dist - a.dist) / (a.dist - b.dist)
                local off = math.max(-NEW_NEAR, math.min(NEW_NEAR, want - fb))
                if math.abs(off) > .01 then x, z = World(x, z, rot, off, 0) end
            end
        end
    end
    -- (each frame on from the one before - not laid down anew, a jump each time what it's worked out
    -- from changes: where it will strike is pinned at its first strike, and every frame before goes
    -- towards that pin from the frame before it - so far a frame as to get there just as it strikes,
    -- and no slower than you run (one still aiming at you keeps up with you); from its first strike
    -- on, exactly where it is)
    -- (one laid out from where it stops aiming (anchor "lock"), still aiming: drawn from where it is
    -- now - but it gets on its way before that, its path (from that pose) says how far behind it it
    -- still is: on by that much. Klaus' bite leaps a frame before it stops aiming, 1.55 on by then:
    -- drawn that short, you outside it, bitten)
    if entry.anchor == "lock" and t ~= nil and t < (entry.lock or 0) * FRAMES and best.path ~= nil and not entry.fixed then
        -- (only one just getting going as it stops aiming - not one already far off in the air then,
        -- the War Machine's leap 12 on: that's where it lands, its own way)
        local before = PathAt(best, 0)
        if before ~= nil and before < -PRELOCK_MIN and before > -PRELOCK_MOVE then

            -- (on by what it has still to go of that: all of it less what it's seen to have gone
            -- since - not by where its path has it by now: seen a frame or two late as it sets off,
            -- and slid there between the game's ticks, the shape stepped back and forth by a
            -- frame's going within one moment)
            -- (how far it has gone: where it was given, not where the shape was slid to above for
            -- the distance)
            if log ~= nil and log.prestart == nil then log.prestart = { x_in, z_in } end
            local s = log ~= nil and log.prestart or nil
            local gone = s ~= nil and ((x_in - s[1]) * math.cos(rot) - (z_in - s[2]) * math.sin(rot)) or 0
            -- (all it goes as this boss has been seen to go, this game - its run's, till seen)
            local all = -before * TravelRatio(ent, entry)
            x, z = World(x, z, rot, math.max(0, all - math.max(0, gone)), 0)
            if log ~= nil then log.prelock = { x, z } end
        elseif log ~= nil then
            log.prelock = nil
        end
    end
    if CHAIN_ON and log ~= nil and t ~= nil then
        local c = log.chain
        if c ~= nil and t > c.t and t - c.t < .2 then
            local frames_left = math.max(1, ((entry.first or 0) * FRAMES - t) / FRAMES)
            local dt = t - c.t
            local dx, dz = x - c.x, z - c.z
            local d = math.sqrt(dx * dx + dz * dz)
            local step = math.max(d / frames_left, CHAIN_SPEED * dt)
            if d > step then x, z = c.x + dx * step / d, c.z + dz * step / d end
            local dr = (rot - c.rot + math.pi) % (2 * math.pi) - math.pi
            local rstep = math.max(math.abs(dr) / frames_left, CHAIN_TURN * dt)
            if math.abs(dr) > rstep then rot = c.rot + (dr > 0 and rstep or -rstep) end
        end
        log.chain = { x = x, z = z, rot = rot, t = t }
    end
    -- (testing, to be removed: the local copy (TR_DRAWLOG, set by true_range modmain) - a move set
    -- as it stops aiming, from 10 frames before that to 15 after (8 past its first strike at least): where it's drawn from, its
    -- turning, the run drawn and how far its far edge reaches - client_log.txt "[tr_draw]", to set
    -- beside the replay's, frame by frame)
    if rawget(_G, "TR_DRAWLOG") and (entry.anchor == "lock" or leap_set) and t ~= nil and log ~= nil then
        local lf = entry.lock or 0
        local fi_now = t / FRAMES
        local last_at = 0
        for _, st in ipairs(MapSteps(best)) do last_at = math.max(last_at, st.at) end
        if fi_now >= lf - 10 and fi_now <= math.max(lf + 15, (entry.first or 0) + 8, last_at + 3) then
            local far = SimMoves._FarOf(best)
            local sh = log.shift
            print(string.format("[tr_draw] %.3f %s %s f=%.1f at=%.2f,%.2f rot=%.1f run=%.2f far=%s shift=%s exact=%s",
                (GetTime or GetStaticTime)(), ent ~= nil and tostring(ent.prefab) or "?", tostring(entry.name or (entry.anims and entry.anims[1])), fi_now,
                x, z, rot / DEGREES, best.dist or -1, far ~= nil and string.format("%.2f", far) or "-",
                sh ~= nil and string.format("%.2f,%.2f", sh[1], sh[2]) or "-", tostring(log.lock_exact)))
        end
    end
    t = t or 0
    local inside = false
    local todo = {}
    local steps = MapSteps(best)
    -- (where it may strike, not where it will - crystals falling where they like: one shape, all of
    -- it until its last strike, gone at once - not part by part, as its samples happened to fall)
    local random_until = nil
    -- (and when it begins: all of it struck in one burst, a third of a second at most - Deerclops'
    -- ice spikes, where they come up by chance, all of them within frames 34-39 - its colours by
    -- how soon, as any other's; one striking now and then a long while - junk falling: pale all along)
    local random_from = nil
    if entry.random then
        random_until, random_from = 0, math.huge
        for _, step in ipairs(steps) do
            random_until = math.max(random_until, step.at * FRAMES)
            random_from = math.min(random_from, step.at * FRAMES)
        end
        if random_until - random_from > 10 * FRAMES then random_from = nil end
    end
    -- (one that chases you down - the Scrappy Werepig's tackle, entry.reach: you running on ahead,
    -- it gets to each part later than it did offline, you standing still - a part is over only once
    -- it has gone past it)
    -- (only while it's still on its way - stopped, it has struck you or given up: what's ahead
    -- of it is over)
    local gone_now = nil
    -- (likewise any that goes on its way as it strikes - its run over half a unit)
    -- (sweeping on as it goes: three parts or more a frame or two apart - not one blow struck as it
    -- flies by, a gestalt's: that one's over once struck)
    if best.sweeps == nil then
        local run, most = 1, 1
        local st = MapSteps(best)
        for k = 2, #st do
            if st[k].at - st[k - 1].at <= 2 then run = run + 1 else run = 1 end
            most = math.max(most, run)
        end
        best.sweeps = most >= 3
    end
    if ent ~= nil and (entry.reach ~= nil or (best.sweeps and not entry.fixed and not entry.random and (PathAt(best, 100000) or 0) > .5)) then
        local ex, _, ez = ent.Transform:GetWorldPosition()
        local now = (GetTime or GetStaticTime)()
        local moving = true
        if log ~= nil then
            local p = log.pos
            if p ~= nil and now > p.t then
                local speed = math.sqrt((ex - p.x) ^ 2 + (ez - p.z) ^ 2) / (now - p.t)
                log.slow = speed < 2 and (log.slow or 0) + 1 or 0
                moving = log.slow < 3
            end
            if p == nil or now > p.t then log.pos = { x = ex, z = ez, t = now } end
        end
        if moving then
            gone_now = (ex - x) * math.cos(rot) - (ez - z) * math.sin(rot)
        end
    end
    -- (and how far behind it what it strikes with still reaches - the tackle's hit a circle round a
    -- point ahead of it: each part was kept only where it first struck, a crescent at the front -
    -- dropped once the boss was past its front edge, what was left was crescents' horns round a
    -- notch where it stands, though anyone stepping in there is still struck. The circle's radius:
    -- as wide as its way is; how far it reaches ahead of the boss, its front; behind: the rest)
    local back = 0
    if gone_now ~= nil then
        if best.back == nil then
            local r, front = 0, 0
            for _, step in ipairs(steps) do
                local p = PathAt(best, step.at) or 0
                for _, run in ipairs(step.runs) do
                    for row = run[1], run[1] + (run[4] or 1) - 1 do r = math.max(r, math.abs(-G.side + row * G.step)) end
                    front = math.max(front, G.ahead + run[3] * G.step - p)
                end
            end
            best.back = math.max(0, 2 * r - front)
        end
        back = best.back
    end
    -- (told when each spot goes out of its reach - best.of.raw.ends, tools/sim_moves.lua -ends: the
    -- Scrappy Werepig's tackle striking all round it frame after frame - drawn as two parts, what's
    -- in its reach now and what's still to come; not each spot from where it first came into
    -- reach, crescents whose horns stuck out behind it and a notch where it stands)
    local ends_mode = best.of ~= nil and best.of.raw ~= nil and best.of.raw.ends ~= nil and not entry.random
    local again_ids = ends_mode and {} or nil
    -- (on into an animation the run came to later than now - the Scrappy Werepig at you sooner
    -- than offline, lifting you 6 off where the run had it going on to 12: as far on as that
    -- animation is there - again_until, less again_at: the frame it began in the run - what the
    -- run struck before it over, not drawn on behind it in crescents)
    local t_on = OnAt(best, t, ent)
    for i, step in ipairs(steps) do
        local at = step.at * FRAMES
        local ahead = false
        if gone_now ~= nil and t_on > at + LINGER then
            if step.far == nil then
                local far = -math.huge
                for _, run in ipairs(step.runs) do far = math.max(far, G.ahead + run[3] * G.step) end
                step.far = far
            end
            ahead = step.far > gone_now - back
        end
        -- (struck again and again - a stomp after stomp, as many as it likes: on until the
        -- animation of its last strike is past it)
        local again = false
        if step.again_anim ~= nil and step.again_anim ~= "" and t_on > at + LINGER and ent ~= nil then
            -- (until the animation it last strikes in is past that point - and not once it's on to a
            -- later one of the move's: a pounce's claw done, its last strike came back as it got up)
            local now_i, again_i = nil, nil
            for i, a in ipairs(entry.anims or {}) do
                if ent.AnimState:IsCurrentAnimation(a) then now_i = i end
                if a == step.again_anim then again_i = again_i or i end
            end
            -- (struck once more only in a later go of that animation - its frame past the animation's
            -- end: the move begun anew, a strike of its own then - not this one striking on till it ends:
            -- the Boulder Crab's bite red all through its 41-frame atk for a bite at 87, 2026-10-18)
            local len = not rawget(_G, "TR_OLD_AGAIN") and ent.AnimState.GetCurrentAnimationLength ~= nil and ent.AnimState:GetCurrentAnimationLength() or nil
            if len ~= nil and len > 0 and now_i == again_i and (step.again_at or 0) * FRAMES > len + LINGER then now_i = nil end
            if now_i ~= nil and again_i ~= nil then
                again = now_i < again_i or (now_i == again_i
                    and (ent.AnimState:GetCurrentAnimationTime() <= (step.again_at or 0) * FRAMES + LINGER
                        -- (or the move not yet past its last strike, run offline: one going round again
                        -- runs on past its end a frame or two before it starts over - the War Machine's
                        -- stomping, gone for that frame)
                        or (step.again_until ~= nil and t <= step.again_until * FRAMES + LINGER)))
            end
            -- (an animation going round again - a spin: at its very end, a frame past its last strike,
            -- before it starts over - kept a moment, not gone for that frame)
            if log ~= nil then
                local clock = (GetTime or GetStaticTime)()
                log.again_seen = log.again_seen or {}
                if again then
                    log.again_seen[step] = clock
                -- (or its blows set going for later (SimMoves._tail): that long)
                elseif log.again_seen[step] ~= nil and clock - log.again_seen[step]
                    <= (not rawget(_G, "TR_OLD_TAIL") and ent.prefab ~= nil and SimMoves._tail[ent.prefab] or 3) * FRAMES then
                    again = true
                end
            end
        end
        -- (one of parts struck together: from the first of them, until the last)
        local cl_at, cl_end = at, at
        if step.cl ~= nil then cl_at, cl_end = step.cl.at * FRAMES, (step.cl.cl_end or step.cl.at) * FRAMES end
        -- (one that gores whoever is within its reach as it runs (entry.gore): a spot it has come to
        -- is struck on till it's that far past - kept, striking, as long)
        local gore_on = entry.gore ~= nil and entry.gore / (entry.speed or 6) or 0
        -- (or kept, struck, till the last ring of its wave has struck)
        local keep_end = step.cl ~= nil and step.cl.keep_until or nil
        -- (one that strikes only ahead of itself (entry.front - the Clockwork Rook, 75 either way): a spot
        -- it has got to the middle of is behind it - gone then, not kept on as a red trail)
        if t_on <= cl_end + (entry.front and FRAMES or LINGER) + gore_on or (keep_end ~= nil and t_on <= keep_end * FRAMES + LINGER) or again or ahead or (random_until ~= nil and t <= random_until + LINGER) then
            -- (one struck already and striking on - a laser burning on, a stomp after stomp: when
            -- next can't be told to the frame - as striking, all the while)
            local dt = (again or ahead) and 0 or (t_on < cl_at and cl_at - t_on or math.min(0, at - t_on))
            local style = entry.random and (random_from ~= nil and ByTime(math.max(0, random_from - t_on)) or "fill_light") or ByTime(dt)
            local here = InMap(step, x, z, rot, px, pz)
            table.insert(todo, { map = step, style = style, id = i })
            -- (testing: as each part strikes, whether you stood in it - client_log.txt)
            if log ~= nil and t >= at and not log[step] and px ~= nil then
                log[step] = true
                local dx, dz = px - x, pz - z
                local bx, bz = 0, 0
                if ent ~= nil then
                    local ex, _, ez = ent.Transform:GetWorldPosition()
                    bx, bz = ex - x, ez - z
                end
                local _ = rawget(_G, "TR_DEBUG") and print(string.format("[true_range] strike at %.2fs: you %s in it - %.2f ahead, %.2f aside of where it began (its target %.2f off, map for %s); the boss %.2f ahead, %.2f aside",
                    at, here and "were" or "were NOT", dx * math.cos(rot) - dz * math.sin(rot), dx * math.sin(rot) + dz * math.cos(rot),
                    dist, tostring(best.dist), bx * math.cos(rot) - bz * math.sin(rot), bx * math.sin(rot) + bz * math.cos(rot)))
                -- (testing: told to whoever listens - were you struck after all? true_range modmain)
                if SimMoves.on_strike ~= nil and ent ~= nil and not entry.random then
                    -- (at its edge - the band, where the game itself may go either way: a cell next to
                    -- yours outside all it may strike)
                    -- (the part striking then: its own edge - not the whole move's, where another part
                    -- may lie next to it)
                    local edge = false
                    if here then
                        local u = step
                        local dx2, dz2 = px - x, pz - z
                        local c2, s2 = math.cos(rot), math.sin(rot)
                        local col = math.floor((dx2 * c2 - dz2 * s2 - G.ahead) / G.step + .5)
                        local row = math.floor((dx2 * s2 + dz2 * c2 + G.side) / G.step + .5)
                        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
                            if not u.cells[(row + d[1]) * 1000 + col + d[2]] then edge = true end
                        end
                    end
                    SimMoves.on_strike(ent, here, edge)
                end
            end
        end
    end
    -- (its edge kept with its steps: let go with them)
    -- (entry.whole: one piece, no seams between its parts - all of it struck later by things it
    -- sets off, drawn themselves by then: a ring inside a growing ice circle, there for a moment)
    local owner = steps
    if ends_mode then
        local of = best.of
        -- (each spot: the frame it first came into reach, and the last it was in it)
        if of.reach_first == nil then
            local first, last = {}, {}
            for _, s in ipairs(steps) do
                for k in pairs(s.cells) do if first[k] == nil or s.at < first[k] then first[k] = s.at end end
            end
            for _, e in ipairs(of.raw.ends) do
                for k in pairs(Unpack(e.cells or "").cells) do last[k] = e.at end
            end
            of.reach_first, of.reach_last, of.reach_parts = first, last, {}
        end
        -- (frame by frame - and with the parts struck again later on now: a lift at the end of
        -- the run, struck all round once more - made once each)
        local fi = math.floor(t_on / FRAMES + .5)
        -- (still at it past where the run ended - it chased you on longer than offline: what it
        -- struck last in the run, round where it is now (the shape moved with it, above))
        if of.reach_end == nil then
            of.reach_end = 0
            for _, s in ipairs(of.raw.ends) do of.reach_end = math.max(of.reach_end, s.at or 0) end
        end
        local clamped = fi > of.reach_end
        fi = math.min(fi, of.reach_end)
        -- (but not once its animation is past the last it strikes in it, any distance run - the
        -- lift strikes at its fifth and sixth frames, then nothing: its last strike's ring kept on
        -- red to the lift's end)
        if entry._last_in == nil then
            local last_in = {}
            for _, m in ipairs(Decode(entry, src)) do
                for _, s in ipairs(m.of.raw.steps or {}) do
                    if s.again_anim ~= nil and s.again_anim ~= "" and s.again_at ~= nil then
                        last_in[s.again_anim] = math.max(last_in[s.again_anim] or 0, s.again_at)
                    end
                end
            end
            entry._last_in = last_in
        end
        -- (past the run's end: its last ring kept only while it's in an animation it strikes in,
        -- not past the last it strikes there - not in one it never strikes in at all: the Scrappy
        -- Werepig's cannon broken, its "hit" after it, the blast's ring back for a frame)
        local over = false
        if clamped and ent ~= nil and ent.AnimState ~= nil then
            local striking = false
            for an, f in pairs(entry._last_in) do
                if ent.AnimState:IsCurrentAnimation(an) and ent.AnimState:GetCurrentAnimationTime() <= (f + 2) * FRAMES then striking = true end
            end
            over = not striking
        end
        local key = tostring(fi) .. ":" .. table.concat(again_ids, ",")
        local parts = of.reach_parts[key]
        if parts == nil then
            -- (kept two frames past going out of reach - not LINGER's six: running on at 13 a second
            -- that left a tail three units long behind it)
            local linger = 2
            local now, coming, soon = {}, {}, nil
            for k, f in pairs(of.reach_first) do
                if f > fi then
                    coming[k] = true
                    soon = math.min(soon or f, f)
                elseif (of.reach_last[k] or f) + linger >= fi then
                    now[k] = true
                end
            end
            for _, i in ipairs(again_ids) do
                for k in pairs(steps[i].cells) do now[k] = true coming[k] = nil end
            end
            -- (what's to come only a cell or two thick along the front: with what's in reach now,
            -- one piece - a sliver, smoothed, folds over itself, and it's cut on the cells' own edges:
            -- stairs; tested as MapSteps' slivers)
            if next(now) ~= nil then
                local n, inner = 0, 0
                for k in pairs(coming) do
                    n = n + 1
                    if coming[k - 1] and coming[k + 1] and coming[k - 1000] and coming[k + 1000] then inner = inner + 1 end
                end
                if n > 0 and inner <= SLIVER_INNER * n then
                    for k in pairs(coming) do now[k] = true end
                    coming = {}
                end
            end
            parts = {}
            -- (cl: each its own piece for Atoms, whatever frames they fall in)
            if next(now) ~= nil then parts[#parts + 1] = { cells = now, runs = RunsOf(now), at = fi, now = true, cl = { at = -1 } } end
            if next(coming) ~= nil then parts[#parts + 1] = { cells = coming, runs = RunsOf(coming), at = soon, cl = { at = -2 } } end
            of.reach_parts[key] = parts
        end
        -- (nothing of it in reach now nor to come: as before, part by part - none at all, once
        -- its last strike is over)
        if over then
            todo = {}
        elseif #parts > 0 then
            todo = {}
            for i, p in ipairs(parts) do
                todo[#todo + 1] = { map = p, style = ByTime(p.now and 0 or (p.at * FRAMES - t_on)), id = i }
            end
            owner = parts
        end
    end
    -- (for the pause report: drawn from where, for how far, from which run, how many parts)
    if log ~= nil then
        log.r_x, log.r_z, log.r_rot, log.r_dist, log.r_best, log.r_parts = x, z, rot, dist, best.dist, #todo
        log.r_in_x, log.r_in_z = x_in, z_in
    end
    status_only = StatusOnly(entry)
    -- (its pieces kept together, moved as one - true_range/lines, groups: this go of the move's own)
    draw_slot = log
    -- (a new shape laid into its group the first frame it's drawn - not piece by piece that frame,
    -- then all laid again into its group the next: each new shape paid for twice, the Ancient
    -- Guardian's lane and Klaus' bite growing as they aimed, a frame dropped each time. Only where
    -- the game turns groups (Lines.turns): else its pieces are kept by its turning, and turning as
    -- it aims would keep one for every frame)
    build_now = Lines.turns and Lines.GroupFor ~= nil
    local ok_d, res_d = pcall(DrawParts, owner, todo, x, z, rot, px, pz, entry.random and "fill_light" or "fill",
        entry._key ~= nil and (entry._key .. "|" .. best.kind .. "|" .. best.i) or nil, entry.whole)
    build_now = false
    draw_slot = nil
    if not ok_d then error(res_d, 0) end
    inside = res_d or inside
    status_only = false
    steps.ready = true
    if log ~= nil then log.map = best end
    return inside
end

-- A move it may make again soon (its cooldown nearly over): the outline of all it may strike,
-- in white, from where it is towards (tx, tz) - flashed by true_range/predict.
function SimMoves.Flash(entry, x, z, rot, tx, tz)
    local map
    if entry.around ~= nil then
        map = arounds[entry]
        if map == nil then
            map = Unpack(entry.around)
            arounds[entry] = map
        end
    else
        if entry.frame ~= "facing" and ((tx - x) ^ 2 + (tz - z) ^ 2) > .01 then
            rot = math.atan2(-(tz - z), tx - x)
        end
        local dist = math.sqrt((tx - x) ^ 2 + (tz - z) ^ 2)
        local best = nil
        for _, m in ipairs(Decode(entry)) do
            if best == nil or math.abs(m.dist - dist) < math.abs(best.dist - dist) then best = m end
        end
        if best == nil then return end
        local steps = MapSteps(best)
        map = flash_unions[steps]
        if map == nil then
            map = { cells = {}, runs = {} }
            for _, s in ipairs(steps) do
                for k in pairs(s.cells) do map.cells[k] = true end
            end
            flash_unions[steps] = map
        end
    end
    local step = G.step
    for _, p in ipairs(Outline(map)) do
        local x1, z1 = World(x, z, rot, G.ahead + p[2] * step, -G.side + p[1] * step)
        local x2, z2 = World(x, z, rot, G.ahead + p[4] * step, -G.side + p[3] * step)
        Lines.Segment(x1, z1, x2, z2, "flash", nil, true)
    end
end

-- A boss that may make a move again any moment: a band glowing a little way out from its body
-- (radius r) round (x, z), clear of its body ring - rings red, fading outwards (true_range/
-- predict sets how bright). (One with no body to bump - flying over you: a little way out
-- from where its body would be.)
local GLOW_GAP, GLOW_STEP, GLOW_NOBODY = .4, .2, 1.5
local GLOW_STYLES = { "glow_1", "glow_2", "glow_3", "glow_4" }
SimMoves.GLOW_STYLES = GLOW_STYLES
function SimMoves.Glow(x, z, r)
    if r == nil or r < .3 then r = GLOW_NOBODY end
    for i, style in ipairs(GLOW_STYLES) do
        local rr = r + GLOW_GAP + (i - 1) * GLOW_STEP
        -- (many short pieces: thick ones show their corners round a ring)
        local n = math.max(72, math.floor(rr * 24))
        for k = 0, n - 1 do
            local a1, a2 = k / n * 2 * math.pi, (k + 1) / n * 2 * math.pi
            Lines.Segment(x + rr * math.cos(a1), z - rr * math.sin(a1), x + rr * math.cos(a2), z - rr * math.sin(a2), style)
        end
    end
end

-- (for the tests)
SimMoves._test = { Rects = Rects, RunsOf = RunsOf, Unpack = Unpack, Outline = Outline }

return SimMoves
