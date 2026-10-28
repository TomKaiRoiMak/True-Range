-- Every shape the mod draws (a move's whole reach at one distance, a leg, a spin's reach, what a
-- thing a boss sets off strikes), drawn ahead of time as a picture - smooth, its edge darker -
-- for the game to lay on the ground in one piece, coloured as it likes (true_range/simmoves).
--   luajit silhouettes.lua <mod root> <out dir> [px a unit]
-- Writes <out dir>/shapes.txt (for make_silhouettes.ps1: one shape a line - its name, size in
-- pixels, and its smooth outline's loops in pixels) and <mod>/scripts/true_range/silhouettes.lua
-- (cells string -> { shape, where its middle sits, in cells }). Shapes the same but for where
-- they are (a laser at one distance and the next) are drawn once.
package.path = arg[1] .. "/scripts/?.lua;" .. package.path
DEGREES, FRAMES = math.pi / 180, 1 / 30
package.loaded["true_range/lines"] = { Begin = function() end, End = function() end, Pulse = function() end,
    Segment = function() end, Disc = function() end, Wedge = function() end, _styles = {} }
local SimMoves = require("true_range/simmoves")
local Data = require("true_range/moves_sim")
local T = SimMoves._test
local OUT = arg[2]
local PX = tonumber(arg[3] or "16")         -- pixels a unit
local G = Data._grid
local PX_CELL = PX * G.step                  -- pixels a cell
local PAD = 2                                -- cells of room round each shape

-- every cells string in the data that's drawn as a shape of its own, once
local sources = {}
local function Add(cells_text)
    if cells_text ~= nil and cells_text ~= "" then sources[cells_text] = true end
end
local function Union(steps)
    local all = {}
    for _, s in ipairs(steps or {}) do
        for k in pairs(T.Unpack(s.cells or "").cells) do all[k] = true end
    end
    return all
end
local unions = {}  -- cells string (the union, packed) -> cells
local function Pack(cells)
    -- (rows of runs as text: a key, not the game's packing)
    local rows = {}
    for k in pairs(cells) do
        local c = k % 1000
        local r = math.floor((k - c) / 1000 + .5)
        rows[r] = rows[r] or {}
        table.insert(rows[r], c)
    end
    local keys = {}
    for r in pairs(rows) do table.insert(keys, r) end
    table.sort(keys)
    local out = {}
    for _, r in ipairs(keys) do
        table.sort(rows[r])
        table.insert(out, r .. ":" .. table.concat(rows[r], ","))
    end
    return table.concat(out, ";")
end

local entries = {}   -- { key (what the game looks it up by), cells }
for prefab, moves in pairs(Data) do
    if prefab:sub(1, 1) ~= "_" then
        for name, e in pairs(moves) do
            local base = prefab .. "|" .. name
            for _, kind in ipairs({ "maps", "free" }) do
                local prev = nil
                for i, m in ipairs(e[kind] or {}) do
                    local steps = m.same and prev or m.steps
                    prev = steps
                    table.insert(entries, { key = base .. "|" .. kind .. "|" .. i, cells = Union(steps) })
                end
            end
            if e.around then table.insert(entries, { key = base .. "|around", cells = T.Unpack(e.around).cells }) end
            if e.leg and e.leg.cells then table.insert(entries, { key = base .. "|leg", cells = T.Unpack(e.leg.cells).cells }) end
            if e.leg and e.leg.finish and e.leg.finish.cells then
                table.insert(entries, { key = base .. "|finish", cells = T.Unpack(e.leg.finish.cells).cells })
            end
        end
    end
end
for prefab, h in pairs(Data._hazards or {}) do
    table.insert(entries, { key = "_hazard|" .. prefab, cells = Union(h.steps) })
end

-- the same shape wherever it is: moved to its corner
local shapes, by_norm, index = {}, {}, {}
local total_px = 0
for _, en in ipairs(entries) do
    local minr, minc, maxr, maxc = math.huge, math.huge, -math.huge, -math.huge
    for k in pairs(en.cells) do
        local c = k % 1000
        local r = math.floor((k - c) / 1000 + .5)
        minr, minc = math.min(minr, r), math.min(minc, c)
        maxr, maxc = math.max(maxr, r), math.max(maxc, c)
    end
    if minr ~= math.huge then
        local norm = {}
        for k in pairs(en.cells) do
            local c = k % 1000
            local r = math.floor((k - c) / 1000 + .5)
            norm[(r - minr) * 1000 + (c - minc)] = true
        end
        local nkey = Pack(norm)
        local sh = by_norm[nkey]
        if sh == nil then
            sh = { id = #shapes + 1, cells = norm, rows = maxr - minr + 1, cols = maxc - minc + 1 }
            sh.w = math.ceil((sh.cols + 2 * PAD) * PX_CELL)
            sh.h = math.ceil((sh.rows + 2 * PAD) * PX_CELL)
            total_px = total_px + sh.w * sh.h
            by_norm[nkey] = sh
            table.insert(shapes, sh)
        end
        -- (where this one's corner is: its picture's middle sits at the middle of its cells)
        index[en.key] = { sh.id, minr, minc, sh.rows, sh.cols }
    end
end
io.stderr:write(string.format("%d shapes drawn (%d places), %.1f megapixels at %d px a unit\n", #shapes,
    #entries, total_px / 1e6, PX))
if OUT == nil then return end

-- each shape's smooth outline, in its picture's pixels (y down: rows go down)
local f = assert(io.open(OUT .. "/shapes.txt", "wb"))
for _, sh in ipairs(shapes) do
    local map = { cells = sh.cells }
    local loops = {}
    for _, p in ipairs(T.Outline(map)) do
        table.insert(loops, string.format("%.2f,%.2f,%.2f,%.2f", (p[2] + PAD + .5) * PX_CELL, (p[1] + PAD + .5) * PX_CELL,
            (p[4] + PAD + .5) * PX_CELL, (p[3] + PAD + .5) * PX_CELL))
    end
    f:write(string.format("s%d %d %d %s\n", sh.id, sh.w, sh.h, table.concat(loops, " ")))
end
f:close()

-- the game's side: what to draw where
local keys = {}
for k in pairs(index) do table.insert(keys, k) end
table.sort(keys)
local out = { "-- Made by true_range_workshop/tools/silhouettes.lua: each shape's picture (anim/trsil, animation",
    "-- \"s<id>\"), and where its cells' corner is (row, column) and how many (rows, columns).",
    "return {", string.format("    _px = %d, _pad = %d,", PX, PAD) }
for _, k in ipairs(keys) do
    local v = index[k]
    table.insert(out, string.format("    [%q] = { %d, %d, %d, %d, %d },", k, v[1], v[2], v[3], v[4], v[5]))
end
table.insert(out, "}")
local g = assert(io.open(arg[1] .. "/scripts/true_range/silhouettes.lua", "wb"))
g:write(table.concat(out, "\n"), "\n")
g:close()
