-- Polygons (with holes) cut into triangles - to fill a shape on the ground smoothly, with the
-- one triangle picture the mod has (true_range/lines: Lines.Tri).
--   Triangulate(loops) -> { { ax, ay, bx, by, cx, cy }, ... }
-- loops: closed outlines { { x, y }, ... } (the first point not repeated at the end), outer
-- ones and holes in them alike - which is which is told by what lies inside what.

local Triangulate = {}

local function Area(l)
    local a = 0
    for i = 1, #l do
        local p, q = l[i], l[i % #l + 1]
        a = a + p[1] * q[2] - q[1] * p[2]
    end
    return a / 2
end

local function Inside(pt, l)
    local x, y, inside = pt[1], pt[2], false
    local j = #l
    for i = 1, #l do
        local a, b = l[i], l[j]
        if (a[2] > y) ~= (b[2] > y) and x < (b[1] - a[1]) * (y - a[2]) / (b[2] - a[2]) + a[1] then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function Cross(o, a, b)
    return (a[1] - o[1]) * (b[2] - o[2]) - (a[2] - o[2]) * (b[1] - o[1])
end

local function InTri(p, a, b, c)
    local d1, d2, d3 = Cross(a, b, p), Cross(b, c, p), Cross(c, a, p)
    local neg = d1 < 0 or d2 < 0 or d3 < 0
    local pos = d1 > 0 or d2 > 0 or d3 > 0
    return not (neg and pos)
end

-- (a hole joined to the outline round it by a cut from its rightmost point to an outline point
-- it sees: one loop, going in and back out along the cut)
local function Bridge(outer, hole)
    local hi, hx = 1, -math.huge
    for i, p in ipairs(hole) do
        if p[1] > hx then hi, hx = i, p[1] end
    end
    local h = hole[hi]
    -- (the nearest outline point to its right, not hidden behind another piece of outline)
    local best, bd = nil, math.huge
    for i, p in ipairs(outer) do
        if p[1] >= h[1] then
            local d = (p[1] - h[1]) ^ 2 + (p[2] - h[2]) ^ 2
            if d < bd then
                -- (seen: the cut crosses no piece of the outline)
                local ok = true
                for j = 1, #outer do
                    local a, b = outer[j], outer[j % #outer + 1]
                    if a ~= p and b ~= p then
                        local d1, d2 = Cross(h, p, a), Cross(h, p, b)
                        local d3, d4 = Cross(a, b, h), Cross(a, b, p)
                        if ((d1 > 0) ~= (d2 > 0)) and ((d3 > 0) ~= (d4 > 0)) then ok = false break end
                    end
                end
                if ok then best, bd = i, d end
            end
        end
    end
    if best == nil then
        for i, p in ipairs(outer) do
            local d = (p[1] - h[1]) ^ 2 + (p[2] - h[2]) ^ 2
            if d < bd then best, bd = i, d end
        end
    end
    local out = {}
    for i = 1, best do table.insert(out, outer[i]) end
    for k = 0, #hole do table.insert(out, hole[(hi - 1 + k) % #hole + 1]) end
    table.insert(out, { outer[best][1], outer[best][2] })
    for i = best + 1, #outer do table.insert(out, outer[i]) end
    return out
end

-- one simple loop (counter-clockwise) cut ear by ear
local function Ears(l, out)
    local idx = {}
    for i = 1, #l do idx[i] = i end
    local guard = 0
    while #idx > 3 and guard < 10000 do
        guard = guard + 1
        local cut = false
        local n = #idx
        for k = 1, n do
            local ia, ib, ic = idx[(k - 2) % n + 1], idx[k], idx[k % n + 1]
            local a, b, c = l[ia], l[ib], l[ic]
            if Cross(a, b, c) > 1e-9 then
                local ear = true
                for m = 1, n do
                    local im = idx[m]
                    if im ~= ia and im ~= ib and im ~= ic then
                        local p = l[im]
                        -- (a point where the cut doubles back on itself isn't in the way)
                        if not ((p[1] == a[1] and p[2] == a[2]) or (p[1] == b[1] and p[2] == b[2]) or (p[1] == c[1] and p[2] == c[2]))
                            and InTri(p, a, b, c) then
                            ear = false
                            break
                        end
                    end
                end
                if ear then
                    table.insert(out, { a[1], a[2], b[1], b[2], c[1], c[2] })
                    table.remove(idx, k)
                    cut = true
                    break
                end
            end
        end
        if not cut then
            -- (nothing left that's clean to cut - a sliver: the flattest corner goes)
            local bk, bv = 1, math.huge
            for k = 1, n do
                local v = math.abs(Cross(l[idx[(k - 2) % n + 1]], l[idx[k]], l[idx[k % n + 1]]))
                if v < bv then bk, bv = k, v end
            end
            table.remove(idx, bk)
        end
    end
    if #idx == 3 then
        local a, b, c = l[idx[1]], l[idx[2]], l[idx[3]]
        if Cross(a, b, c) > 1e-9 then table.insert(out, { a[1], a[2], b[1], b[2], c[1], c[2] }) end
    end
end

-- Thin slivers made fat: where two triangles share a side that isn't the outline's, and the
-- other way across their four corners gives a bigger smallest angle, swapped (Lawson's flips -
-- toward Delaunay). A sliver is drawn blurred by the game (its texture shrunk), its colour
-- running past its sides.
local function MinSin(a, b, c)
    -- (the smallest angle's sine, near enough: twice the area over the two longest sides)
    local ab = math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2)
    local bc = math.sqrt((b[1] - c[1]) ^ 2 + (b[2] - c[2]) ^ 2)
    local ca = math.sqrt((c[1] - a[1]) ^ 2 + (c[2] - a[2]) ^ 2)
    local area2 = math.abs(Cross(a, b, c))
    -- (the two longest: all three's product over the shortest)
    local lo = math.min(ab, bc, ca)
    local two = lo > 1e-9 and ab * bc * ca / lo or 0
    if two < 1e-12 then return 0 end
    return area2 / two
end
local function Fatten(tris)
    -- (a point's key: a number - its corners lie on an eighth of a cell, and well within 10000)
    local floor = math.floor
    local function K(p) return floor(p[1] * 64 + .5) * 1048576 + floor(p[2] * 64 + .5) end
    -- (the triangles as point triples, counter-clockwise)
    local T = {}
    for _, t in ipairs(tris) do
        local a, b, c = { t[1], t[2] }, { t[3], t[4] }, { t[5], t[6] }
        if Cross(a, b, c) < 0 then b, c = c, b end
        table.insert(T, { a, b, c })
    end
    for _ = 1, 8 do
        -- (each side by its two ends' keys: the triangle on one side, and the one across)
        local by_edge = {}
        local pairs_found = {}
        for i, t in ipairs(T) do
            for k = 1, 3 do
                local a, b = K(t[k]), K(t[k % 3 + 1])
                if a > b then a, b = b, a end
                local row = by_edge[a]
                if row == nil then row = {} by_edge[a] = row end
                local first = row[b]
                if first == nil then
                    row[b] = { i, k }
                else
                    table.insert(pairs_found, { first[1], first[2], i, k })
                end
            end
        end
        local flipped, touched = 0, {}
        for _, pr in ipairs(pairs_found) do
            do
                local i1, k1, i2, k2 = pr[1], pr[2], pr[3], pr[4]
                if not touched[i1] and not touched[i2] then
                    local t1, t2 = T[i1], T[i2]
                    -- (t1: p, q along the side, r across; t2: q, p, s)
                    local p, q, r = t1[k1], t1[k1 % 3 + 1], t1[(k1 + 1) % 3 + 1]
                    local s = t2[(k2 + 1) % 3 + 1]
                    -- (the other way only where r, p, s, q make a convex four-sided shape)
                    if Cross(r, p, s) > 1e-9 and Cross(s, q, r) > 1e-9 then
                        local now = math.min(MinSin(p, q, r), MinSin(q, p, s))
                        local after = math.min(MinSin(r, p, s), MinSin(s, q, r))
                        if after > now * 1.05 then
                            T[i1], T[i2] = { r, p, s }, { s, q, r }
                            touched[i1], touched[i2] = true, true
                            flipped = flipped + 1
                        end
                    end
                end
            end
        end
        if flipped == 0 then break end
    end
    local out = {}
    for _, t in ipairs(T) do table.insert(out, { t[1][1], t[1][2], t[2][1], t[2][2], t[3][1], t[3][2] }) end
    return out
end
Triangulate._Fatten = Fatten
Triangulate._MinSin = MinSin

-- (a point just inside a loop's first side, the way it runs - for telling what lies in what
-- without a corner that may sit on another loop too)
local function Probe(l)
    local a, b = l[1], l[2]
    return { (a[1] + b[1]) / 2, (a[2] + b[2]) / 2 }
end
-- signed: the loops already run the right way round (outer ones counter-clockwise, holes
-- clockwise) - which is which told by that, not by what lies in what (pieces touching at a
-- corner fooled that)
function Triangulate.Loops(loops, signed)
    -- (outer loops counter-clockwise, holes clockwise: how deep each lies decides)
    local info = {}
    for i, l in ipairs(loops) do
        if #l >= 3 then
            local a = Area(l)
            if signed then
                if math.abs(a) > 1e-9 then
                    table.insert(info, { loop = l, hole = a < 0, area = math.abs(a) })
                end
            else
                local depth = 0
                for j, o in ipairs(loops) do
                    if j ~= i and #o >= 3 and Inside(l[1], o) then depth = depth + 1 end
                end
                local hole = depth % 2 == 1
                if (a < 0) ~= hole then
                    local r = {}
                    for k = #l, 1, -1 do table.insert(r, l[k]) end
                    l = r
                end
                table.insert(info, { loop = l, hole = hole, depth = depth })
            end
        end
    end
    if signed then
        -- (each hole in the smallest outer loop round it)
        for _, h in ipairs(info) do
            if h.hole then
                local p, best = Probe(h.loop), nil
                for _, o in ipairs(info) do
                    if not o.hole and Inside(p, o.loop) and (best == nil or o.area < best.area) then best = o end
                end
                h.owner = best
            end
        end
    end
    local out = {}
    for _, o in ipairs(info) do
        if not o.hole then
            local poly = o.loop
            -- (its holes: the loops just one deeper, inside it - rightmost first)
            local holes = {}
            for _, h in ipairs(info) do
                if h.hole and ((signed and h.owner == o)
                    or (not signed and h.depth == o.depth + 1 and Inside(h.loop[1], o.loop))) then
                    table.insert(holes, h.loop)
                end
            end
            table.sort(holes, function(a, b)
                local ma, mb = -math.huge, -math.huge
                for _, p in ipairs(a) do ma = math.max(ma, p[1]) end
                for _, p in ipairs(b) do mb = math.max(mb, p[1]) end
                return ma > mb
            end)
            for _, h in ipairs(holes) do poly = Bridge(poly, h) end
            Ears(poly, out)
        end
    end
    if not Triangulate.fatten then return out end
    return Fatten(out)
end

return Triangulate
