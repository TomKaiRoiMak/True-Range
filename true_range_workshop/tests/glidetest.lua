package.path = arg[1] .. "/scripts/?.lua;" .. package.path
DEGREES, FRAMES = math.pi / 180, 1 / 30
local now = 100
GetTime = function() return now end
GetStaticTime = GetTime
local n = 0
package.loaded["true_range/lines"] = { Begin = function() end, End = function() end, Pulse = function() end,
  Segment = function() n = n + 1 end, Tri = function() n = n + 1 end, Disc = function() end, Wedge = function() end,
  TriRecs = function(a,b,c,d,e,f,out) out[#out+1] = {} end, SegRec = function() return {} end,
  PutTri = function() n = n + 1 end, PutSeg = function() n = n + 1 end, _styles = {} }
local SimMoves = require("true_range/simmoves")
local ent = { prefab = "junkball_fall_fx", IsValid = function() return true end }
for f = 0, 20 do
  now = 100 + f / 30
  local x = math.min(f, 15) / 15 * 3
  n = 0
  local at_land = SimMoves.DrawHazard(ent, x, 0, 0, 3, 0, now, true)
  local at_start = SimMoves.DrawHazard(ent, x, 0, 0, 0, 0, now, true)
  print(string.format("f=%d x=%.2f pieces=%d landing-in=%s start-in=%s", f, x, n, tostring(at_land), tostring(at_start)))
end
local ent2 = { prefab = "deer_fire_circle", IsValid = function() return true end }
now = 200 n = 0
print("fire circle", SimMoves.DrawHazard(ent2, 0, 0, 0, 0, 0, now, false), n)
