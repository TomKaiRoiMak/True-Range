-- luajit segtris.lua <mod root>
-- A line laid as two triangles (true_range/lines Segment): their corners, as the game would put the
-- "tri" picture (right angle at its pivot, width along its turning, height a quarter turn on),
-- cover the line's rectangle exactly - checked by sampling points in and round it.
package.path = arg[1] .. "/scripts/?.lua;" .. package.path
LAYER_BACKGROUND, ANIM_ORIENTATION = 1, { OnGround = 1 }
local placed = {}
function CreateEntity()
    local e = { entity = {}, Transform = {}, AnimState = {}, rec = {} }
    function e.entity:SetCanSleep() end
    function e.entity:AddTransform() end
    function e.entity:AddAnimState() end
    function e:AddTag() end
    function e:IsValid() return true end
    function e:Show() end
    function e:Hide() end
    function e.AnimState:SetBank() end
    function e.AnimState:SetBuild() end
    function e.AnimState:SetPercent(anim) e.rec.anim = anim end
    function e.AnimState:SetLightOverride() end
    function e.AnimState:SetOrientation() end
    function e.AnimState:SetLayer() end
    function e.AnimState:SetMultColour() end
    function e.AnimState:SetSortOrder(s) e.rec.sort = s end
    function e.AnimState:SetScale(sx, sy) e.rec.sx, e.rec.sy = sx, sy placed[#placed + 1] = e.rec end
    function e.Transform:SetPosition(x, _, z) e.rec.x, e.rec.z = x, z end
    function e.Transform:SetRotation(d) e.rec.deg = d end
    return e
end
local Lines = require("true_range/lines")
local unit = 256 / 150
-- (a "square": its middle, turned, stretched - 64 px a side; split into two triangles to test)
local function Corners(r)
    local d = math.rad(r.deg)
    if r.anim == "square" then
        local u = 64 / 150
        local hl, hw = r.sx * u / 2, r.sy * u / 2
        local ux, uz, nx, nz = math.cos(d), -math.sin(d), math.cos(d + math.pi / 2), -math.sin(d + math.pi / 2)
        local function P(a, b) return r.x + ux * a + nx * b, r.z + uz * a + nz * b end
        local ax, az = P(-hl, -hw)
        local bx, bz = P(hl, -hw)
        local cx, cz = P(hl, hw)
        local dx, dz = P(-hl, hw)
        return { ax, az, bx, bz, cx, cz }, { ax, az, cx, cz, dx, dz }
    end
    local len, h = r.sx * unit, r.sy * unit
    local px, pz = r.x + len * math.cos(d), r.z - len * math.sin(d)
    local q = d + math.pi / 2
    local ax, az = r.x + h * math.cos(q), r.z - h * math.sin(q)
    return { r.x, r.z, px, pz, ax, az }
end
local function InTri(t, x, z)
    local function E(ax, az, bx, bz) return (bx - ax) * (z - az) - (bz - az) * (x - ax) end
    local a, b, c = E(t[1], t[2], t[3], t[4]), E(t[3], t[4], t[5], t[6]), E(t[5], t[6], t[1], t[2])
    return (a >= -1e-9 and b >= -1e-9 and c >= -1e-9) or (a <= 1e-9 and b <= 1e-9 and c <= 1e-9)
end
local bad, n = 0, 0
for _, case in ipairs({ { 0, 0, 3, 1, .1, true }, { 1, 2, -2, 5, .25, false }, { 0, 0, 0, -4, .4, true } }) do
    placed = {}
    Lines.Begin()
    Lines.Segment(case[1], case[2], case[3], case[4], "edge", case[5], case[6])
    local tris = {}
    for _, r in ipairs(placed) do
        local t1, t2 = Corners(r)
        tris[#tris + 1] = t1
        if t2 then tris[#tris + 1] = t2 end
    end
    local dx, dz = case[3] - case[1], case[4] - case[2]
    local len = math.sqrt(dx * dx + dz * dz)
    local ux, uz = dx / len, dz / len
    local ext = case[6] and 0 or math.min(case[5], Lines._styles.edge.width)
    for i = -10, 110 do
        for j = -10, 10 do
            local along = -ext / 2 + (len + ext) * i / 100
            local across = case[5] / 2 * j / 9
            local x, z = case[1] + ux * along - uz * across, case[2] + uz * along + ux * across
            local want = i > 0 and i < 100 and math.abs(j) < 9
            local edge = i <= 0 or i >= 100 or math.abs(j) >= 9
            local got = false
            for _, t in ipairs(tris) do if InTri(t, x, z) then got = true end end
            if not edge and want ~= got then bad = bad + 1 end
            if math.abs(j) == 10 and got then bad = bad + 1 end
            n = n + 1
        end
    end
    print(string.format("case %d: %d pieces, %s", _, #placed, placed[1] and placed[1].anim or "?"))
end
print(string.format("%s%d of %d points wrong", bad > 0 and "FAIL " or "", bad, n))
os.exit(bad == 0 and 0 or 1)
