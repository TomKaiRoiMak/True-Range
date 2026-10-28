-- luajit flash_aim.lua <mod root>: a cooldown nearly over flashes its move's shape at whom the boss
-- is after - two players hitting it, its target changing every few frames: the flash stays at whom
-- it was after as it began, all through it (it jumped between the two, Klaus' bite, in the game)
package.path = arg[1] .. "/scripts/?.lua;" .. package.path
DEGREES, FRAMES = math.pi / 180, 1 / 30
local now = 100
GetTime = function() return now end
GetStaticTime = GetTime
function GetTableSize(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end
function DiffAngle(a, b) local d = math.abs(a - b) % 360 return d > 180 and 360 - d or d end
local function Noop() end
CreateEntity = function()
    local e = {}
    e.entity = setmetatable({}, { __index = function() return Noop end })
    e.Transform = setmetatable({}, { __index = function() return Noop end })
    e.AnimState = setmetatable({}, { __index = function() return Noop end })
    function e:IsValid() return true end
    e.Hide, e.Show, e.Remove, e.AddTag = Noop, Noop, Noop, Noop
    return e
end
ANIM_ORIENTATION = { OnGround = 1 } LAYER_BACKGROUND = 4 LAYER_GROUND = 3
local Predict = require("true_range/predict")
local SimMoves = require("true_range/simmoves")
local Render = require("true_range/render")
local Lines = require("true_range/lines")
Render.cooldown = "shape"
Lines.Pulse = Noop
local at = {}
SimMoves.Flash = function(sim, x, z, rot, tx, tz) at[#at + 1] = { tx, tz } end
local function Player(x, z)
    local p = { Transform = {} }
    function p:IsValid() return true end
    function p.Transform:GetWorldPosition() return x, 0, z end
    return p
end
local me, friend = Player(5, 0), Player(0, 6)
local frame = 0
local boss = { prefab = "klaus", Transform = {}, AnimState = {} }
function boss.Transform:GetWorldPosition() return 0, 0, 0 end
function boss.Transform:GetRotation() return 0 end
function boss.Transform:GetScale() return 1.2, 1.2, 1.2 end
function boss.AnimState:GetBuild() return "klaus" end
function boss:IsValid() return true end
-- (its target: you, then your friend, by turns of 3 frames)
boss.replica = { combat = { GetTarget = function() return math.floor(frame / 3) % 2 == 0 and me or friend end } }
local moves = SimMoves.Moves("klaus")
local fails = 0
if #moves == 0 then print("FAIL: no moves for klaus") fails = fails + 1 end
local r = { cds = { chomp_cd = .9 }, at = now }
for f = 0, 40 do
    frame = f
    now = 100 + f * FRAMES
    Predict._Flash(boss, moves, r, nil)
end
if #at < 10 then print("FAIL: flashed only " .. #at .. " frames") fails = fails + 1 end
for i = 2, #at do
    if at[i][1] ~= at[1][1] or at[i][2] ~= at[1][2] then
        print(string.format("FAIL: frame %d flashed at %.1f,%.1f, the first at %.1f,%.1f", i, at[i][1], at[i][2], at[1][1], at[1][2]))
        fails = fails + 1
        break
    end
end
-- (the next flash, later: at whom it's after then)
frame = 3
now = 200
local r2 = { cds = { chomp_cd = .5 }, at = now }
at = {}
Predict._Flash(boss, moves, r2, nil)
if #at == 0 or at[1][1] ~= 0 or at[1][2] ~= 6 then print("FAIL: a later flash not at whom it's after then") fails = fails + 1 end
print(fails == 0 and "flash_aim: OK" or ("flash_aim: " .. fails .. " FAILED"))
os.exit(fails == 0 and 0 or 1)
