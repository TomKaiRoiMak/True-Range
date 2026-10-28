package.path = arg[1] .. "/scripts/?.lua;" .. package.path
DEGREES, FRAMES = math.pi / 180, 1 / 30
-- the game's strict: reading or writing an undeclared global errors
local declared = {}
for k in pairs(_G) do declared[k] = true end
setmetatable(_G, { __newindex = function(t, k, v) if not declared[k] then error("assign to undeclared variable '" .. tostring(k) .. "'", 2) end rawset(t, k, v) end,
    __index = function(_, k) error("variable '" .. tostring(k) .. "' is not declared", 2) end })
local function Fake() return setmetatable({}, { __index = function() return function() end end }) end
rawset(_G, "CreateEntity", function()
    local e = { entity = Fake(), AnimState = Fake(), Transform = Fake() }
    function e:AddTag() end function e:IsValid() return true end function e:Show() end function e:Hide() end function e:Remove() end
    return e
end)
rawset(_G, "ANIM_ORIENTATION", { OnGround = 1 }) rawset(_G, "LAYER_BACKGROUND", 4) rawset(_G, "LAYER_GROUND", 3)
local Lines = require("true_range/lines")
Lines.Begin()
Lines.Segment(0, 0, 1, 1, "edge")
Lines.Tri(0, 0, 2, 0, 1, 1, "hit")
Lines.Disc(0, 0, 1, "edge")
Lines.Wedge(0, 0, 2, 0, .5, "edge")
Lines.End()
Lines.Warm(5)
Lines.Begin()
local recs = {}
Lines.TriRecs(0, 0, 2, 0, 1, 1, recs)
for _, r in ipairs(recs) do Lines.PutTri(r, "hit") end
Lines.PutSeg(Lines.SegRec(0, 0, 1, 1, "edge"), "edge")
Lines.End()
Lines.Begin()
Lines.Segment(0, 0, 1, 1, "edge")
Lines.Shape("s1", 0, 0, 0, 1, "shape_hit")
Lines.End()
Lines.Warm(5)
Lines.Begin()
local recs = {}
Lines.TriRecs(0, 0, 2, 0, 1, 1, recs)
for _, r in ipairs(recs) do Lines.PutTri(r, "hit") end
Lines.PutSeg(Lines.SegRec(0, 0, 1, 1, "edge"), "edge")
Lines.End()
-- (groups: laid, moved, kept a frame, let go)
local slot = {}
for f = 1, 3 do
    Lines.Begin()
    if f < 3 then
        local g = Lines.GroupFor(slot)
        if f == 1 then
            Lines.GroupClear(g)
            for _, r in ipairs(recs) do Lines.GroupTri(g, r, "hit") end
            Lines.GroupSeg(g, Lines.SegRec(0, 0, 1, 1, "edge"), "edge")
            Lines.GroupDone(g)
        end
        Lines.GroupAt(g, f, 0)
    end
    Lines.End()
end
local SimMoves = require("true_range/simmoves")
require("true_range/predict")
require("true_range/ranges")
print("strict ok")
