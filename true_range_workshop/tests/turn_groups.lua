-- luajit turn_groups.lua <mod root>: a group turned by its parent (Lines.turns) draws the very same
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
local bad, cases = 0, 0
for _, prefab in ipairs({ "deerclops_icespike_fx", "alterguardian_phase2spiketrail", "mushroombomb", "worm_boss_segment" }) do
    for _, deg in ipairs({ 0, 33, 90, 147, 251 }) do
        local got = {}
        for mode = 1, 2 do
            Lines.turns = mode == 1
            local ent = { prefab = prefab, GUID = mode, Transform = {}, AnimState = {} }
            function ent:IsValid() return true end
            function ent:HasTag() return false end
            function ent.Transform:GetScale() return 1, 1, 1 end
            function ent.AnimState:GetCurrentAnimationTime() return 0 end
            function ent.AnimState:GetBuild() return prefab end
            function ent.AnimState:IsCurrentAnimation() return false end
            -- (a few frames: its pieces kept, laid - as drawn the third)
            for f = 1, 3 do
                now = f * FRAMES
                Lines.Begin()
                -- (as Predict.DrawHazards: round things of a kind drawn together at the end)
                SimMoves.UnionBegin()
                SimMoves.DrawHazard(ent, 5, 7, deg * DEGREES, 100, 100, now, false)
                SimMoves.UnionDraw()
                Lines.End()
            end
            got[mode] = Shown()
            -- (and gone - next case clean)
            for _ = 1, 2 do Lines.Begin() Lines.End() end
        end
        cases = cases + 1
        local a, b = got[1], got[2]
        local same = #a == #b
        if same then for i = 1, #a do if a[i] ~= b[i] then same = false break end end end
        if #a == 0 then
            bad = bad + 1
            print(string.format("FAIL %s at %d: nothing drawn - nothing compared", prefab, deg))
        elseif os.getenv("TG_V") then
            print(string.format("%s at %d: %d pieces each way", prefab, deg, #a))
        end
        if not same then
            bad = bad + 1
            print(string.format("FAIL %s at %d: turned group %d pieces, laid turned %d", prefab, deg, #a, #b))
            for i = 1, math.max(#a, #b) do
                if a[i] ~= b[i] then print("  group: " .. tostring(a[i]) .. "\n  laid:  " .. tostring(b[i])) break end
            end
        end
    end
end
print(bad == 0 and string.format("turn_groups ok (%d cases)", cases) or string.format("turn_groups: %d of %d wrong", bad, cases))
