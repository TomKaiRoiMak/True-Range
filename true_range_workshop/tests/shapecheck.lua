-- tests/shapecheck.lua - what's drawn each frame looked at as a shape, not as sums (replay.lua,
-- SHAPE_CHECK=1; VERIFY_PLAN 6.3): the fills laid on a grid -
--   OVERLAP  two pieces over one spot: of two shapes (each its own outline crossing the other's
--            inside, darker where they lie over each other), or within one (its own drawing wrong)
--   SPLIT    how many pieces it falls into, or holes in it, other for a frame or two and back
--   MORPH    a frame's shape not like the one before nor the one after, though those two are alike
--   OPEN     an edge line's end no other line goes on from - its outline broken
-- (a ring is a hole by design, a lane in two parts too: only what comes and goes is said)
local SC = {}
local CELL = tonumber(os.getenv("SHAPE_CELL") or "") or .1
local EDGE_IN = .15
local tris, segs = {}, {}
local frames = {}
local said = { OVERLAP = 0, SPLIT = 0, MORPH = 0, OPEN = 0, EDGEIN = 0, DASH = 0 }
local counts = { OVERLAP = 0, SPLIT = 0, MORPH = 0, OPEN = 0, EDGEIN = 0, DASH = 0 }
local edge_by = {}
local SAY_MAX = 25

function SC.Tri(ax, az, bx, bz, cx, cz, owner)
    tris[#tris + 1] = { ax, az, bx, bz, cx, cz, owner or 0 }
end
function SC.Seg(ax, az, bx, bz, owner, style)
    if (ax - bx) ^ 2 + (az - bz) ^ 2 < 1e-8 then return end
    segs[#segs + 1] = { ax, az, bx, bz, owner or 0, tostring(style or "") }
end

-- (each cell's middle: in a triangle well inside it (strict, for two over one spot - not a shared
-- edge counted twice), or at all (loose, for what's filled))
local function Raster()
    local cover, own, deep = {}, {}, {}
    -- (well inside - more than EDGE_IN in from its edge: whose, up to two - an outline of another
    -- crossing there is EDGEIN)
    local in1, in2 = {}, {}
    local minx, minz, maxx, maxz = math.huge, math.huge, -math.huge, -math.huge
    for _, t in ipairs(tris) do
        local ax, az, bx, bz, cx, cz = t[1], t[2], t[3], t[4], t[5], t[6]
        local d = (bx - ax) * (cz - az) - (bz - az) * (cx - ax)
        if math.abs(d) > 1e-9 then
            local s = d > 0 and 1 or -1
            local la = math.sqrt((cx - bx) ^ 2 + (cz - bz) ^ 2)
            local lb = math.sqrt((ax - cx) ^ 2 + (az - cz) ^ 2)
            local lc = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
            local i0, i1 = math.floor(math.min(ax, bx, cx) / CELL), math.floor(math.max(ax, bx, cx) / CELL)
            local j0, j1 = math.floor(math.min(az, bz, cz) / CELL), math.floor(math.max(az, bz, cz) / CELL)
            minx, maxx, minz, maxz = math.min(minx, i0), math.max(maxx, i1), math.min(minz, j0), math.max(maxz, j1)
            local IN = CELL * .3
            for i = i0, i1 do
                local px = (i + .5) * CELL
                for j = j0, j1 do
                    local pz = (j + .5) * CELL
                    -- (signed distance to each side, inward positive)
                    local w0 = s * ((cx - bx) * (pz - bz) - (cz - bz) * (px - bx)) / la
                    local w1 = s * ((ax - cx) * (pz - cz) - (az - cz) * (px - cx)) / lb
                    local w2 = s * ((bx - ax) * (pz - az) - (bz - az) * (px - ax)) / lc
                    local m = math.min(w0, w1, w2)
                    if m >= -1e-6 then
                        local k = i * 65536 + j
                        cover[k] = true
                        if m > EDGE_IN then
                            local a = in1[k]
                            if a == nil then in1[k] = t[7] elseif a ~= t[7] and in2[k] == nil then in2[k] = t[7] end
                        end
                        if m > IN then
                            local o = own[k]
                            if o == nil then own[k] = t[7]
                            elseif o ~= t[7] then deep[k] = o < t[7] and (o .. " + " .. t[7]) or (t[7] .. " + " .. o)
                            else deep[k] = deep[k] or "within one" end
                        end
                    end
                end
            end
        end
    end
    return cover, deep, minx, minz, maxx, maxz, in1, in2
end
-- (how much of the outlines runs well inside another shape - drawn across its inside, read as one
-- shape broken, or two laid one over the other: sampled every cell along each line)
local function EdgeIn(in1, in2)
    local len, by = 0, {}
    for _, s in ipairs(segs) do
        local dx, dz = s[3] - s[1], s[4] - s[2]
        local L = math.sqrt(dx * dx + dz * dz)
        local n = math.max(1, math.floor(L / CELL + .5))
        for q = 0, n - 1 do
            local px, pz = s[1] + dx * (q + .5) / n, s[2] + dz * (q + .5) / n
            local k = math.floor(px / CELL) * 65536 + math.floor(pz / CELL)
            local a, b = in1[k], in2[k]
            local other = (a ~= nil and a ~= s[5] and a) or (b ~= nil and b ~= s[5] and b) or nil
            if other ~= nil then
                len = len + L / n
                local key = tostring(s[5]):gsub("^%d+:", "") .. " in " .. tostring(other):gsub("^%d+:", "")
                by[key] = (by[key] or 0) + L / n
            end
        end
    end
    return len, by
end

-- (pieces of it, and holes in it: cells filled that touch, and cells not filled that can't be
-- reached from outside)
local function Topo(cover, minx, minz, maxx, maxz)
    local comps, holes = 0, 0
    local seen = {}
    local stack = {}
    local function Flood(k0, filled)
        stack[1] = k0 seen[k0] = true
        local n = 1
        local edge = false
        while n > 0 do
            local k = stack[n] stack[n] = nil n = n - 1
            local i, j = math.floor(k / 65536 + .5), 0
            j = k - i * 65536
            if j > 32767 then j = j - 65536 i = i + 1 end
            for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
                local ni, nj = i + d[1], j + d[2]
                if ni < minx or ni > maxx or nj < minz or nj > maxz then edge = true
                else
                    local nk = ni * 65536 + nj
                    if not seen[nk] and (cover[nk] == true) == filled then seen[nk] = true n = n + 1 stack[n] = nk end
                end
            end
        end
        return edge
    end
    for k in pairs(cover) do if not seen[k] then comps = comps + 1 Flood(k, true) end end
    -- (holes: only looked for inside what's filled - the box round it, a cell over)
    for i = minx, maxx do
        for j = minz, maxz do
            local k = i * 65536 + j
            if not cover[k] and not seen[k] then
                if not Flood(k, false) then holes = holes + 1 end
            end
        end
    end
    return comps, holes
end

-- (a line's end no other line goes on from - not one inside another shape: an outline cut where it
-- runs into another (true_range/simmoves, SimMoves._rg) ends there on purpose, unseen under it)
local function Ends(in1, in2)
    local ends, at = {}, {}
    local function K(x, z) return math.floor(x / .02 + .5) .. "," .. math.floor(z / .02 + .5) end
    for _, s in ipairs(segs) do
        -- (not a seam between two colours - a line across the inside, ending on the outline as it should)
        if not s[6]:find("seam", 1, true) then
        local a, b = K(s[1], s[2]), K(s[3], s[4])
        ends[a] = (ends[a] or 0) + 1
        ends[b] = (ends[b] or 0) + 1
        at[a] = at[a] or { s[1], s[2], s[5], s[6] }
        at[b] = at[b] or { s[3], s[4], s[5], s[6] }
        end
    end
    local open = 0
    for k, n in pairs(ends) do
        if n % 2 == 1 then
            local p = at[k]
            -- (at it, or within two cells of it: a cut comes at the other's very edge)
            local ci, cj = math.floor(p[1] / CELL), math.floor(p[2] / CELL)
            local under = false
            for di = -2, 2 do
                for dj = -2, 2 do
                    local ck = (ci + di) * 65536 + (cj + dj)
                    local o1, o2 = in1 ~= nil and in1[ck] or nil, in2 ~= nil and in2[ck] or nil
                    if (o1 ~= nil and o1 ~= p[3]) or (o2 ~= nil and o2 ~= p[3]) then under = true end
                end
            end
            if not under then open = open + 1 end
        end
    end
    return open
end
local by_pair = {}
local function Say(kind, f, what)
    counts[kind] = counts[kind] + 1
    if kind == "OVERLAP" then
        local k = (f.state or "-") .. "  " .. ((what:match("%((.*)%)$") or "within one"):gsub("%d+:", ""))
        by_pair[k] = (by_pair[k] or 0) + 1
    end
    if said[kind] < SAY_MAX then
        said[kind] = said[kind] + 1
        io.stdout:write(string.format("%s %.3f %s %s: %s\n", kind, f.t, SC.prefab or "", f.state or "-", what))
    end
end

-- (one frame done: what it drew, looked at; frames before it judged once the next is in)
SC.n = 0
function SC.EndFrame(t, state, move)
    SC.n = SC.n + 1
    local f = { t = t, state = state, move = move }
    if #tris > 0 then
        local cover, deep, minx, minz, maxx, maxz, in1, in2 = Raster()
        f.edgein, f.edge_by = EdgeIn(in1, in2)
        f.in1, f.in2 = in1, in2
        SC.edge_len = (SC.edge_len or 0) + f.edgein
        local n, two, one = 0, 0, 0
        local pair_n = {}
        for _ in pairs(cover) do n = n + 1 end
        for _, v in pairs(deep) do
            if v == "within one" then one = one + 1 else two = two + 1 pair_n[v] = (pair_n[v] or 0) + 1 end
        end
        local best = nil
        for p, c in pairs(pair_n) do if best == nil or c > pair_n[best] then best = p end end
        f.pair = best
        f.cells, f.cover = n, cover
        f.comps, f.holes = Topo(cover, minx - 1, minz - 1, maxx + 1, maxz + 1)
        f.two, f.one = two, one
    else
        f.cells, f.comps, f.holes, f.two, f.one = 0, 0, 0, 0, 0
    end
    f.open = Ends(f.in1, f.in2)
    -- (DASH: an outline in pieces, so as it stands - not only for a frame or two (OPEN): two shapes all
    -- but one over the other, each cut where the other's edge cells were, one dashed line round them)
    SC.loose = (SC.loose or 0) + f.open
    if f.open >= 4 then Say("DASH", f, string.format("%d loose line ends", f.open)) end
    if (f.edgein or 0) >= .3 then
        local top, tl = nil, 0
        for k, v in pairs(f.edge_by) do edge_by[(state or "-") .. "  " .. k] = (edge_by[(state or "-") .. "  " .. k] or 0) + 1 if v > tl then top, tl = k, v end end
        Say("EDGEIN", f, string.format("%.1f of outline inside another shape (most: %s)", f.edgein, top or "?"))
    end
    tris, segs = {}, {}
    -- (over one spot: said as it is - not a matter of coming and going)
    local area = CELL * CELL
    if f.two * area >= .05 then Say("OVERLAP", f, string.format("two shapes over %.2f of ground (%s)", f.two * area, f.pair or "?")) end
    if f.one * area >= .05 then Say("OVERLAP", f, string.format("one shape over itself, %.2f of ground", f.one * area)) end
    frames[#frames + 1] = f
    local N = #frames
    -- (a frame or two other than both sides of it, those alike - the same move all along)
    for k = 1, 2 do
        local a, z = frames[N - k - 1], frames[N]
        if a ~= nil and a.cells > 0 and z.cells > 0 and a.move == z.move then
            local mids = {}
            local same_move = true
            for i = N - k, N - 1 do mids[#mids + 1] = frames[i] if frames[i].move ~= a.move then same_move = false end end
            if same_move then
                local function Sig(x) return x.comps .. "/" .. x.holes end
                if Sig(a) == Sig(z) then
                    local odd = true
                    for _, m in ipairs(mids) do if Sig(m) == Sig(a) then odd = false end end
                    if odd then Say("SPLIT", mids[1], string.format("%d pieces %d holes for %d frame(s), else %d pieces %d holes",
                        mids[1].comps, mids[1].holes, k, a.comps, a.holes)) end
                end
                if (a.open == 0) and (z.open == 0) then
                    local odd = true
                    for _, m in ipairs(mids) do if m.open == 0 then odd = false end end
                    if odd then Say("OPEN", mids[1], string.format("%d loose line ends for %d frame(s)", mids[1].open, k)) end
                end
            end
        end
    end
    -- (MORPH: like before-and-after, unlike its own frame)
    local a, m, z = frames[N - 2], frames[N - 1], frames[N]
    if a ~= nil and a.cover ~= nil and m.cover ~= nil and z.cover ~= nil and a.move == m.move and m.move == z.move then
        local function IoU(p, q)
            local i, u = 0, 0
            for k in pairs(p.cover) do u = u + 1 if q.cover[k] then i = i + 1 end end
            for k in pairs(q.cover) do if not p.cover[k] then u = u + 1 end end
            return u > 0 and i / u or 1
        end
        local az, am, mz = IoU(a, z), IoU(a, m), IoU(m, z)
        -- (against how alike its neighbours are - a big shape set off a little is still mostly over itself)
        if az > .8 and am < az - .2 and mz < az - .2 then Say("MORPH", m, string.format("unlike the frames either side (%.2f, %.2f) - they alike %.2f", am, mz, az)) end
    end
    -- (only the last few kept whole)
    if frames[N - 3] ~= nil then frames[N - 3].cover, frames[N - 3].in1, frames[N - 3].in2 = nil, nil, nil end
end

function SC.Report()
    local l = {}
    for k, n in pairs(by_pair) do l[#l + 1] = { k, n } end
    table.sort(l, function(a, b) return a[2] > b[2] end)
    for _, x in ipairs(l) do io.stdout:write(string.format("OVERLAPS %s %d frames: %s\n", SC.prefab or "", x[2], x[1])) end
    local el = {}
    for k, n in pairs(edge_by) do el[#el + 1] = { k, n } end
    table.sort(el, function(a, b) return a[2] > b[2] end)
    for i = 1, math.min(15, #el) do io.stdout:write(string.format("EDGEINS %s %d frames: %s\n", SC.prefab or "", el[i][2], el[i][1])) end
    io.stdout:write(string.format("%s: shapes - %d overlap, %d split, %d morph, %d open-edge frames, %d edge-inside frames (%.0f long), %d dashed (%d loose ends in all)\n", SC.prefab or "",
        counts.OVERLAP, counts.SPLIT, counts.MORPH, counts.OPEN, counts.EDGEIN, SC.edge_len or 0, counts.DASH, SC.loose or 0))
end

return SC
