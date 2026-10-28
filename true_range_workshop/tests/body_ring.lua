-- luajit body_ring.lua <mod root>: a body ring kept as a group (Telegraph.Circle with a slot) shows
-- the very same pieces where the world sees them as one drawn piece by piece; moved, only its parent
-- is moved; its colour changed, laid again. (The stand-in engine as turn_groups.lua's)
-- (from turn_groups.lua:) a group turned by its parent (Lines.turns) draws the very same
-- pieces, where the world sees them, as one laid turned piece by piece. Stand-in entities that
-- turn their children with them as the game does (x on by cos, z back by sin); a thing on the
-- ground drawn at several turns both ways, every piece shown compared - place, turning, stretch
package.path = arg[1] .. "/scripts/?.lua;" .. package.path
DEGREES, FRAMES = math.pi / 180, 1 / 30
local now = 0
GetTime = function() return now end
GetStaticTime = GetTime
function GetTableSize(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end
function DiffAngle(a, b) local d = math.abs(a - b) % 360 return d > 180 and 360 - d or d end
local all = {}
local function Noop() end
CreateEntity = function()
    local e = { vis = true, lx = 0, lz = 0, rot = 0, sx = 1, sy = 1 }
    e.entity = { SetCanSleep = Noop, AddTransform = Noop, AddAnimState = Noop,
        SetParent = function(_, pe) e.parent = pe.owner end }
    e.entity.owner = e
    e.Transform = {
        SetPosition = function(_, x, _, z) e.lx, e.lz = x, z end,
        SetRotation = function(_, d) e.rot = d end,
        GetWorldPosition = function()
            local x, z = e.lx, e.lz
            local p = e.parent
            while p ~= nil do
                local r = math.rad(p.rot)
                x, z = p.lx + x * math.cos(r) + z * math.sin(r), p.lz - x * math.sin(r) + z * math.cos(r)
                p = p.parent
            end
            return x, 0, z
        end,
    }
    e.AnimState = setmetatable({ SetPercent = function(_, a) e.anim = a end, SetScale = function(_, a, b) e.sx, e.sy = a, b end,
        SetMultColour = function(_, r, g, b, a) e.colour = string.format("%.2f %.2f %.2f %.2f", r, g, b, a) end },
        { __index = function() return Noop end })
    function e:AddTag() end
    function e:IsValid() return true end
    function e:Show() e.vis = true end
    function e:Hide() e.vis = false end
    function e:Remove() e.vis = false e.removed = true end
    all[#all + 1] = e
    return e
end
ANIM_ORIENTATION, LAYER_BACKGROUND, LAYER_GROUND = { OnGround = 1 }, 4, 3
local Lines = require("true_range/lines")
local SimMoves = require("true_range/simmoves")
-- (the game's own answer first: the stand-ins turn children - the test must find so)
for _ = 1, 3 do Lines.Begin() Lines.End() end
if not Lines.turns then print("FAIL: the turn test said no to stand-ins that do turn") end
-- (every piece showing: where, its world turning, stretch, colour - sorted, for comparing)
local function Shown()
    local out = {}
    for _, e in ipairs(all) do
        if e.vis and not e.removed and e.anim ~= nil then
            local x, _, z = e.Transform.GetWorldPosition()
            local turn = e.rot
            local p = e.parent
            while p ~= nil do turn = turn + p.rot p = p.parent end
            turn = (turn % 360 + 360) % 360
            -- (a quarter of a turn either way the same for a piece mirrored? not here: kept exact)
            out[#out + 1] = string.format("%s %.3f %.3f %.2f %.3f %.3f %s", e.anim, x, z, turn, e.sx, e.sy, tostring(e.colour))
        end
    end
    table.sort(out)
    return out
end

local Telegraph = require("true_range/telegraph")
local calls = 0
local bad = 0
local function Ring(x, z, r, style, slot)
    Lines.Begin()
    Telegraph.Circle(x, z, r, style, slot)
    Lines.End()
end
local me = {}
for _, c in ipairs({ { 0, 0, .5, "body" }, { 3.25, -7.5, .5, "body" }, { 3.3, -7.4, .5, "body_danger" }, { 10, 4, 6.4, "monster_body" } }) do
    Ring(c[1], c[2], c[3], c[4], me)
    Ring(c[1], c[2], c[3], c[4], me)
    local a = Shown()
    for _ = 1, 2 do Lines.Begin() Lines.End() end
    Ring(c[1], c[2], c[3], c[4], nil)
    local b = Shown()
    for _ = 1, 2 do Lines.Begin() Lines.End() end
    local same = #a == #b and #a > 0
    if same then for i = 1, #a do if a[i] ~= b[i] then same = false print("  group: " .. a[i]) print("  drawn: " .. b[i]) break end end end
    if not same then bad = bad + 1 print(string.format("FAIL: ring at %.2f,%.2f r %.1f %s - %d pieces as a group, %d drawn", c[1], c[2], c[3], c[4], #a, #b)) end
end
-- (moved: only the parent - no piece laid again)
local laid0 = Lines.laid or 0
Ring(1, 1, .5, "body", me)
local l1 = Lines.laid or 0
Ring(2, 1.5, .5, "body", me)
Ring(2.5, 1.7, .5, "body", me)
if (Lines.laid or 0) ~= l1 then bad = bad + 1 print(string.format("FAIL: moving the ring laid %d pieces again", (Lines.laid or 0) - l1)) end
print(bad == 0 and "body_ring: OK" or ("body_ring: " .. bad .. " FAILED"))
os.exit(bad == 0 and 0 or 1)