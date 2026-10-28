-- luajit pool_hide.lua <mod root>: pieces laid one frame and not the next are hidden - true_range/lines
-- (Lines.End hides only as far up its heap as pieces were shown: none left showing above that)
package.path = arg[1] .. "/scripts/?.lua;" .. package.path
DEGREES, FRAMES = math.pi / 180, 1 / 30
local shown = 0
local function Fake() return setmetatable({}, { __index = function() return function() end end }) end
CreateEntity = function()
    -- (only pieces counted - what has a picture: not the groups' parents, nor the turn test's)
    local e = { entity = Fake(), Transform = Fake(), vis = false }
    e.AnimState = setmetatable({ SetPercent = function() if not e.piece then e.piece = true if e.vis then shown = shown + 1 end end end }, { __index = function() return function() end end })
    e.vis = true
    function e:AddTag() end
    function e:IsValid() return true end
    function e:Show() if not self.vis then self.vis = true if self.piece then shown = shown + 1 end end end
    function e:Hide() if self.vis then self.vis = false if self.piece then shown = shown - 1 end end end
    function e:Remove() if self.vis and self.piece then shown = shown - 1 end self.vis = false end
    return e
end
ANIM_ORIENTATION, LAYER_BACKGROUND, LAYER_GROUND = { OnGround = 1 }, 4, 3
local Lines = require("true_range/lines")
local bad = 0
local function Frame(n)
    Lines.Begin()
    for i = 1, n do Lines.Segment(i, 0, i + .5, 0, "edge") end
    for i = 1, n do Lines.Tri(i, 0, i + 1, 0, i, 1, "hit") end
    Lines.End()
    -- (each segment one piece, each triangle two)
    if shown ~= 3 * n then
        print(string.format("FAIL: %d laid, %d showing", 3 * n, shown))
        bad = bad + 1
    end
end
for _, n in ipairs({ 100, 10, 0, 50, 50, 3, 120, 0 }) do Frame(n) end
-- (and a heap warmed ahead, all hidden)
Lines.Warm(500)
Frame(5)
print(bad == 0 and "pool_hide ok" or ("pool_hide: " .. bad .. " wrong"))
