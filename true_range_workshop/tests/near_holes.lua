-- luajit near_holes.lua <mod root>: a worm segment is drawn only by one of its holes (h.near) -
-- true_range/simmoves Shown, its grid of holes: segments near and far of holes laid about,
-- against looking at every hole
package.path = arg[1] .. "/scripts/?.lua;" .. package.path
DEGREES, FRAMES = math.pi / 180, 1 / 30
local now = 0
GetTime = function() return now end
GetStaticTime = GetTime
function GetTableSize(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end
function DiffAngle(a, b) local d = math.abs(a - b) % 360 return d > 180 and 360 - d or d end
TheSim = {}
-- (nothing laid - only whether it's drawn)
local function P() end
package.loaded["true_range/lines"] = { TriRecs = function(a, b, c, d, e, f, out) out[#out + 1] = {} end,
    SegRec = function() return {} end, PutTri = P, PutSeg = P, Begin = P, End = P, Pulse = P, Segment = P,
    Shape = P, Tri = P, Disc = P, Wedge = P, _styles = {} }
local SimMoves = require("true_range/simmoves")
local h = SimMoves.Hazards().worm_boss_segment
local hole_prefab, r = h.near[1], h.near[2]
math.randomseed(7)
local holes = {}
for i = 1, 40 do
    local hx, hz = math.random() * 120 - 60, math.random() * 120 - 60
    local e = { prefab = hole_prefab, Transform = {} }
    function e:IsValid() return true end
    function e:HasTag() return false end
    function e.Transform:GetWorldPosition() return hx, 0, hz end
    -- (held here: the game holds its own - kept only weakly by the mod)
    holes[#holes + 1] = { hx, hz, e }
    SimMoves.NearThing(e)
end
local bad, n_in = 0, 0
for i = 1, 3000 do
    now = i * FRAMES
    -- (some right by a hole, at the edge of its reach either side; most anywhere)
    local x, z
    local hole = holes[math.random(#holes)]
    local pick = i % 3
    if pick == 0 then
        local a, d = math.random() * 2 * math.pi, r * (0.98 + math.random() * .04)
        x, z = hole[1] + d * math.cos(a), hole[2] + d * math.sin(a)
    elseif pick == 1 then
        x, z = hole[1] + math.random() - .5, hole[2] + math.random() - .5
    else
        x, z = math.random() * 140 - 70, math.random() * 140 - 70
    end
    local want = false
    for _, ho in ipairs(holes) do
        if (ho[1] - x) ^ 2 + (ho[2] - z) ^ 2 <= r * r then want = true break end
    end
    if want then n_in = n_in + 1 end
    local seg = { prefab = "worm_boss_segment", Transform = {}, AnimState = {} }
    function seg:IsValid() return true end
    function seg:HasTag() return false end
    function seg.Transform:GetScale() return 1, 1, 1 end
    function seg.AnimState:GetBuild() return h.look end
    function seg.AnimState:GetCurrentAnimationTime() return 0 end
    function seg.AnimState:IsCurrentAnimation() return false end
    local hidden0 = SimMoves.stage_hidden
    SimMoves.DrawHazard(seg, x, z, 0, 1000, 1000, now, false)
    local got = SimMoves.stage_hidden == hidden0
    if got ~= want then
        bad = bad + 1
        if bad <= 5 then
            local best = math.huge
            for _, ho in ipairs(holes) do best = math.min(best, math.sqrt((ho[1] - x) ^ 2 + (ho[2] - z) ^ 2)) end
            print(string.format("FAIL at %.2f, %.2f: drawn %s, by a hole %s (nearest %.3f of %.2f; kind %d)", x, z, tostring(got), tostring(want), best, r, pick))
        end
    end
end
print(bad == 0 and string.format("near_holes ok (%d of 3000 by a hole)", n_in) or string.format("near_holes: %d wrong", bad))
