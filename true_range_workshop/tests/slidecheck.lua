-- luajit slidecheck.lua <mod root>
-- Every move that strikes by what it puts down (entry.set_until - the Klaus deer's fire and ice
-- circles, the Celestial Champion's crystals): run through the mod's own drawing with the boss
-- walking off sideways all along. Once all is put down its shape must stay where it is - not go
-- on with the boss. SLIDE: one that went on. (The deer were never traced in the game, so the
-- replays never saw this.)
package.path = arg[1] .. "/scripts/?.lua;" .. package.path
DEGREES, FRAMES = math.pi / 180, 1 / 30
local now = 0
GetTime = function() return now end
GetStaticTime = GetTime
function GetTableSize(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end
function DiffAngle(a, b) local d = math.abs(a - b) % 360 return d > 180 and 360 - d or d end
-- (the pieces drawn: each triangle's area and middle - the shape's middle, frame by frame)
local area, sx, sz = 0, 0, 0
local function Tri(ax, az, bx, bz, cx, cz)
    local a = math.abs((bx - ax) * (cz - az) - (bz - az) * (cx - ax)) / 2
    area, sx, sz = area + a, sx + a * (ax + bx + cx) / 3, sz + a * (az + bz + cz) / 3
end
local Lines = require("true_range/lines")
Lines.Tri = function(ax, az, bx, bz, cx, cz) Tri(ax, az, bx, bz, cx, cz) end
Lines.TriRecs = function(ax, az, bx, bz, cx, cz, out)
    out[#out + 1] = { ax, az, bx, bz, cx, cz }
end
Lines.PutTri = function(r, _, dx, dz) dx, dz = dx or 0, dz or 0 if r then Tri(r[1] + dx, r[2] + dz, r[3] + dx, r[4] + dz, r[5] + dx, r[6] + dz) end end
Lines.SegRec = function() return false end
Lines.PutSeg = function() end
-- (laid straight, not in groups - the same pieces at the same places: groups only keep them)
Lines.GroupFor = nil
Lines.Segment = function() end
Lines.Pulse = function() end
Lines.Shape = function() end
Lines.Disc = function() end
print = function() end
local real_print = io.write
local Predict = require("true_range/predict")
local Data = require("true_range/moves_sim")

local checked, slid = 0, 0
local names = {}
for prefab in pairs(Data) do if prefab:sub(1, 1) ~= "_" then names[#names + 1] = prefab end end
table.sort(names)
for _, prefab in ipairs(names) do
    local mnames = {}
    for name, e in pairs(Data[prefab]) do if type(e) == "table" and e.set_until ~= nil then mnames[#mnames + 1] = name end end
    table.sort(mnames)
    for _, name in ipairs(mnames) do
        local e = Data[prefab][name]
        local t0 = 1000 + checked * 100
        local ent = { prefab = prefab, AnimState = {}, Transform = {}, x = 0, z = 0 }
        function ent:IsValid() return true end
        function ent:HasTag() return false end
        function ent:GetPhysicsRadius() return 1 end
        function ent.AnimState:IsCurrentAnimation(a) return a == e.anims[1] end
        function ent.AnimState:GetCurrentAnimationTime() return now - t0 end
        function ent.AnimState:GetBuild() return e.look end
        function ent.Transform:GetWorldPosition() return ent.x, 0, ent.z end
        function ent.Transform:GetRotation() return 0 end
        function ent.Transform:GetScale() local s = e.scale or 1 return s, s, s end
        local tg = { IsValid = function() return true end, HasTag = function() return false end,
            Transform = { GetWorldPosition = function() return 6, 0, .001 end } }
        ent.replica = { combat = { GetTarget = function() return tg end } }
        local last = 0
        for _, m in ipairs(e.maps or {}) do
            for _, s in ipairs(m.steps or {}) do last = math.max(last, s.at or 0) end
        end
        local from, worst = nil, 0
        for f = 0, last + 6 do
            now = t0 + f * FRAMES
            -- (walking off to its side all along, a tenth of a unit a frame)
            ent.z = f * .1
            area, sx, sz = 0, 0, 0
            Predict.Draw({ ent }, function() return { harmful = true, hit = 3 } end, .5,
                { x = 6, z = .001, ent = tg }, function() return false end)
            if f > e.set_until + 3 and area > 0 then
                local cx, cz = sx / area, sz / area
                -- (a part struck and gone, the rest left where it was: its middle moves - from there on)
                if from == nil or math.abs(area - from[3]) > .1 * from[3] then from = { cx, cz, area }
                else worst = math.max(worst, math.sqrt((cx - from[1]) ^ 2 + (cz - from[2]) ^ 2)) end
            end
        end
        checked = checked + 1
        if worst > .5 then
            slid = slid + 1
            real_print(string.format("SLIDE %s %s: its shape went %.2f with the boss after all was put down\n", prefab, name, worst))
        end
    end
end
real_print(string.format("slidecheck: %d moves, %d slid\n", checked, slid))
