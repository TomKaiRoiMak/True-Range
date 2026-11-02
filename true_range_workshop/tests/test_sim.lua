package.path = arg[1] .. "/scripts/?.lua;" .. package.path
DEGREES = math.pi / 180
FRAMES = 1 / 30
local now = 0
GetStaticTime = function() return now end
GetTime = GetStaticTime
function GetTableSize(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end
function DiffAngle(a, b) local d = math.abs(a - b) % 360 return d > 180 and 360 - d or d end
local drawn = 0
package.loaded["true_range/lines"] = { TriRecs = function(a, b, c, d, e, f, out) out[#out + 1] = {} out[#out + 1] = {} end, SegRec = function() return {} end, PutTri = function() drawn = drawn + 1 end, PutSeg = function() drawn = drawn + 1 end, Begin = function() end, End = function() end, Pulse = function() end,
    Segment = function() drawn = drawn + 1 end, Shape = function() drawn = drawn + 100 end, Tri = function() drawn = drawn + 1 end, Disc = function() end, Wedge = function() end }
local Predict = require("true_range/predict")
local Learn = require("true_range/learn")
local fails = 0
local function check(ok, msg) print((ok and "ok   " or "FAIL ") .. msg) if not ok then fails = fails + 1 end end
-- (you, looked at where px, pz: the boss's target itself only when it stands there - else someone else, there. Handed the
-- target as you wherever you were, you and it apart: true_range/predict takes where you are as where its target is when
-- that's you (2026-10-22, a player's game shows you ahead of the server) - 9 of these failed so, a state no game has)
local function Me(px, pz, tg)
    local tx, _, tz = tg.Transform.GetWorldPosition()
    if (tx - px) ^ 2 + (tz - pz) ^ 2 < .0001 then return { x = px, z = pz, ent = tg } end
    local you = { IsValid = function() return true end, Transform = { GetWorldPosition = function() return px, 0, pz end } }
    return { x = px, z = pz, ent = you }
end

-- the Celestial Champion's tri-beam, facing +x (rotation 0), you its target 10 ahead
local function Boss(anim, tx, tz, me)
    local e = { prefab = "alterguardian_phase3", AnimState = {}, Transform = {} }
    function e:IsValid() return true end
    function e.AnimState:IsCurrentAnimation(a) return a == anim end
    function e.AnimState:GetCurrentAnimationTime() return 0 end
    function e.Transform:GetWorldPosition() return 0, 0, 0 end
    function e.Transform:GetRotation() return 0 end
    local tg = { IsValid = function() return true end, Transform = { GetWorldPosition = function() return tx, 0, tz end } }
    e.replica = { combat = { GetTarget = function() return tg end } }
    return e, tg
end
local function At(anim, px, pz, tx)
    local e, tg = Boss(anim, tx or 10, 0)
    drawn = 0
    return Predict.Draw({ e }, function() return { harmful = true, hit = 3 } end, .5, Me(px, pz, tg), function() return false end)
end
check(At("attk_beam", 10, 0) == true and drawn > 10, "on the middle beam, where you stand: hit (" .. drawn .. " pieces)")
-- the side beams: through you turned some, from the boss
local hit_side = false
for deg = 15, 45, 1 do
    if At("attk_beam", 9 * math.cos(deg * DEGREES), -9 * math.sin(deg * DEGREES)) then hit_side = true end
end
check(hit_side, "a side beam, 9 out")
check(At("attk_beam", 3, 6) == false, "off to the side, close: safe")
check(At("attk_beam", -5, 0) == false, "behind it: safe")
-- the sweep: arcs at your distance and 4.5 either side
check(At("attk_swipe", 10, 0) == true, "the sweep, where you stand: hit")
check(At("attk_swipe", 7.5, 0) == false, "between its arcs (10 and 5.5): safe")
-- the laser stops aiming (frame ~21): you step aside after that - the beam stays where it was
local beam_boss, beam_tg = Boss("attk_beam", 10, 0)
local tpos = { 10, 0 }
beam_tg.Transform.GetWorldPosition = function() return tpos[1], 0, tpos[2] end
local function B(px, pz) return Predict.Draw({ beam_boss }, function() return { harmful = true, hit = 3 } end, .5, Me(px, pz, beam_tg), function() return false end) end
now = 100
B(10, 0)
now = 100 + 30 * FRAMES -- (locked by now)
check(B(10, 0) == true, "locked: where you stood is hit")
tpos[1], tpos[2] = 10, -5 -- (you ran off to the side)
check(B(10, 0) == true and B(10, -5) == false, "you moved after it locked: the beam stayed")
-- you got behind it, close: it still faces the other way, but its lasers go at you
local turned, tg2 = Boss("attk_beam", -6, 0)
function turned.Transform:GetRotation() return 0 end -- (facing +x; you're at -6)
now = 150
local function T2(px, pz) return Predict.Draw({ turned }, function() return { harmful = true, hit = 3 } end, .5, Me(px, pz, tg2), function() return false end) end
check(T2(-6, 0) == true and T2(6, 0) == false, "facing away from you: the beam still comes your way")

-- the roll: legs straight ahead, from where it turned
local roller = { prefab = "alterguardian_phase1", AnimState = {}, Transform = {} }
function roller:IsValid() return true end
function roller.AnimState:IsCurrentAnimation(a) return a == "roll_pre" end
function roller.AnimState:GetCurrentAnimationTime() return 0 end
function roller.Transform:GetWorldPosition() return 0, 0, 0 end
function roller.Transform:GetRotation() return 0 end
local function R(px, pz) return Predict.Draw({ roller }, function() return { harmful = true, hit = 3 } end, .5, { x = px, z = pz }, function() return false end) end
now = 200
check(R(8, 0) == true and R(8, 6) == false and R(-6, 0) == false, "a roll: ahead of it, 4.5 wide, not behind")
-- its last roll winds down (roll_pst): a slide and a slam ahead of where that began
local anim_now = "roll_pre"
function roller.AnimState:IsCurrentAnimation(a) return a == anim_now end
now = 210
R(0, 0)
anim_now = "roll_pst"
now = 210.5
check(R(6.5, 0) == true and R(-3, 0) == false, "the slam after the last roll: some 6 ahead")
now = 210.5 + 40 * FRAMES
check(R(6.5, 0) == false, "after the slam: gone")
-- an attack on its target only (phase 2's chop): cells all round it when you're its target
local chop = { prefab = "alterguardian_phase2", AnimState = {}, Transform = {} }
function chop:IsValid() return true end
function chop.AnimState:IsCurrentAnimation(a) return a == "attk_chop" end
local chop_t = 0
function chop.AnimState:GetCurrentAnimationTime() return chop_t end
function chop.Transform:GetWorldPosition() return 0, 0, 0 end
function chop.Transform:GetRotation() return 0 end
local me_ent = {}
local function C(px, pz, after)
    local tg = after or me_ent
    tg.IsValid = function() return true end
    tg.Transform = { GetWorldPosition = function() return px, 0, pz end }
    chop.replica = { combat = { GetTarget = function() return tg end } }
    return Predict.Draw({ chop }, function() return { harmful = true, hit = 3 } end, .5, { x = px, z = pz, ent = me_ent }, function() return false end)
end
now = 400
-- (begun, then 5 frames on: begun as another of its moves does, nothing drawn its first 4 frames (tell_wait, 2026-10-19))
C(-3, 2)
now, chop_t = 400 + 5 * FRAMES, 5 * FRAMES
check(C(-3, 2) == true and C(-6, 0) == false, "chop at you: all round it, out to its reach")
chop_t = 0
-- (a new chop: one already aimed stays on whoever it aimed at)
chop = setmetatable({}, { __index = chop })
check(C(-3, 2, {}) == false, "chop at someone else: nothing")

-- the five bosses: one move each, you their target 5 ahead
local function Move(prefab, anim, px, pz, tx, tz)
    local e = { prefab = prefab, AnimState = {}, Transform = {} }
    function e:IsValid() return true end
    function e.AnimState:IsCurrentAnimation(a) return a == anim end
    function e.AnimState:GetCurrentAnimationTime() return 0 end
    function e.Transform:GetWorldPosition() return 0, 0, 0 end
    function e.Transform:GetRotation() return 0 end
    local tg = { IsValid = function() return true end, Transform = { GetWorldPosition = function() return tx or 5, 0, tz or 0 end } }
    e.replica = { combat = { GetTarget = function() return tg end } }
    now = now + 10
    return Predict.Draw({ e }, function() return { harmful = true, hit = 3 } end, .5, Me(px, pz, tg), function() return false end)
end
check(Move("bearger", "atk", 4, 3) == true and Move("bearger", "atk", -3, 0) == false, "Bearger's swipe: in front, not behind")
check(Move("bearger", "ground_pound", -4, 0) == true and Move("bearger", "ground_pound", -9, 0) == false, "Bearger's pound: all round, some 6")
check(Move("deerclops", "atk", 5, 0) == true and Move("deerclops", "atk", -10, 0) == false, "Deerclops: its spikes ahead, not far behind")
check(Move("eyeofterror", "charge_pre", 12, 0) == true and Move("eyeofterror", "charge_pre", 12, 5) == false, "Eye of Terror's charge: along it, not beside it")
check(Move("daywalker", "atk_slam_pre", 5, 1) == true and Move("daywalker", "atk_slam_pre", 0, -6) == false, "the Werepig's slam: where you stand")
check(Move("daywalker", "run_pre", 3, 0) == false, "the Werepig just starting to run: nothing")
check(Move("klaus", "attack_doubleclaw", 2, 1, 2, 1) == true, "Klaus' swipe at you: all round it")
check(Move("hound", "atk_pre", 2, 0, 2, 0) == true and Move("hound", "atk_pre", 6, 0, 6, 0) == false, "a hound's bite: close by, not far")
check(Move("firehound", "atk_pre", 2, 0, 2, 0) == true, "a fire hound: as a hound")
-- the Werepig's pounce: stopped by its target in its way; its whole way once they're off it
check(Move("daywalker", "atk3", 9, 0, 3, 0) == false, "the Werepig's pounce: stopped at its target in its way")
check(Move("daywalker", "atk3", 9, 0, 0, 4) == true, "the Werepig's pounce: its whole way, its target off its path")

-- Bearger's pound: waves - once the inner rings have struck, only the outer ones are left
local pounder = { prefab = "bearger", AnimState = {}, Transform = {} }
local pound_t = 0
function pounder:IsValid() return true end
function pounder.AnimState:IsCurrentAnimation(a) return a == "ground_pound" end
function pounder.AnimState:GetCurrentAnimationTime() return pound_t end
function pounder.Transform:GetWorldPosition() return 0, 0, 0 end
function pounder.Transform:GetRotation() return 0 end
local ptg = { IsValid = function() return true end, Transform = { GetWorldPosition = function() return 5, 0, 0 end } }
pounder.replica = { combat = { GetTarget = function() return ptg end } }
local function PD(px, pz) return Predict.Draw({ pounder }, function() return { harmful = true, hit = 3 } end, .5, Me(px, pz, ptg), function() return false end) end
now = 1000
check(PD(1.5, 0) == true and PD(6, 0) == true, "pound: before it, near and far")
now = 1000 + 1.6 -- (well into its waves)
check(PD(1.5, 0) == false, "pound: the inner waves have struck - gone there")
-- Klaus' chomp at you 5 away: where it lands (on you), not round where it set off
-- (its bite reaches ~5.2 round where it lands, 2.6 on towards you - behind it at 3 it doesn't, SimMoves._land.klaus)
check(Move("klaus", "attack_chomp", 5, 0) == true and Move("klaus", "attack_chomp", -3, 0) == false,
    "Klaus' chomp: where it lands on you, not where it set off")
-- the Werepig's slam goes the way it faces (it turns slower than you run): you off to its side
local function Side(px, pz) return Move("daywalker", "atk_slam_pre", px, pz, 0, -6) end
check(Side(6, 0) == true and Side(0, -6) == false, "Werepig's slam: the way it faces, not swung round at you")
-- one of Deerclops' ice spikes coming up: round it until it strikes
local spike = { prefab = "deerclops_icespike_fx", Transform = { GetWorldPosition = function() return 70, 0, 70 end, GetRotation = function() return 0 end } }
function spike:IsValid() return true end
now = 2000
check(Predict.DrawHazards({ spike }, .5, { x = 71, z = 70 }) == true and Predict.DrawHazards({ spike }, .5, { x = 73, z = 70 }) == false,
    "an ice spike coming up: 1 round it, not 3")

-- the Werepig's slam with you close (3 away): it shoves you on and lands on you - not far past
check(Move("daywalker", "atk_slam_pre", 3, 0, 3, 0) == true and Move("daywalker", "atk_slam_pre", 10, 0, 3, 0) == false,
    "Werepig's slam, you 3 away: on you, not 10 on")
-- its pounce: seen from where it leaps (its run-up before that is behind it by then)
check(Move("daywalker", "atk3", 4, 0, 4, 0) == true and Move("daywalker", "atk3", -2, 0, 4, 0) == false,
    "Werepig's pounce: ahead of where it leaps, not behind")
-- Klaus' chomp: the bite only - a swipe after it is a move of its own
local chomp_anims = require("true_range/moves_sim").klaus.attack_chomp.anims
check(#chomp_anims == 1, "Klaus' chomp: the bite only, its swipe after is its own move")
-- the Eye of Terror after its charge (winding down): nothing more
local eye2 = { prefab = "eyeofterror", AnimState = {}, Transform = {} }
local eye_anim, eye_t = "charge_pre", 0
function eye2:IsValid() return true end
function eye2.AnimState:IsCurrentAnimation(a) return a == eye_anim end
function eye2.AnimState:GetCurrentAnimationTime() return eye_t end
function eye2.Transform:GetWorldPosition() return 0, 0, 0 end
local eye_rot = 0
function eye2.Transform:GetRotation() return eye_rot end
local etg = { IsValid = function() return true end, Transform = { GetWorldPosition = function() return 5, 0, 0 end } }
eye2.replica = { combat = { GetTarget = function() return etg end } }
local function E(px, pz) return Predict.Draw({ eye2 }, function() return { harmful = true, hit = 3 } end, .5, Me(px, pz, etg), function() return false end) end
-- (its later form, charge after charge: seen turning into it first - "transform")
local eye_anim_was = eye_anim
eye_anim = "transform"
now = 2999
E(10, 0)
eye_anim = eye_anim_was
now = 3000
check(E(10, 0) == true, "Eye winding up: the charge to come")
now, eye_anim, eye_t = 3001, "charge_loop", .1
check(E(10, 0) == true, "Eye charging: its path")
now, eye_anim, eye_t = 3002, "charge_pst", .1
-- (you straight ahead of it as it winds down: its next charge drawn faint already - it charges on with no turn, 30 struck
-- with nothing drawn on the stress bench, 2026-10-21; predict TR_OLD_AHEADLEG. Without that rule: nothing, as before)
-- (the old way first: once taken for its next, kept for the go)
rawset(_G, "TR_OLD_AHEADLEG", true)
check(E(10, 0) == false, "Eye winding down after a charge, still facing on: nothing (its last) - TR_OLD_AHEADLEG")
rawset(_G, "TR_OLD_AHEADLEG", nil)
check(E(10, 0) == true, "Eye winding down after a charge, you straight ahead: the next one, faint")
now, eye_rot = 3002.1, 180
check(E(-10, 0) == true, "Eye turned round to you between charges: the next one, that way")
now = 3003
check(E(-10, 0) == false, "Eye: no next charge after its wait - nothing")
-- Klaus enraged (bigger): its chomp reaches you 11 away; as it is, not
local function KlausAt(scale)
    local k = { prefab = "klaus", AnimState = {}, Transform = {} }
    function k:IsValid() return true end
    function k.AnimState:IsCurrentAnimation(a) return a == "attack_chomp" end
    function k.AnimState:GetCurrentAnimationTime() return 0 end
    function k.Transform:GetWorldPosition() return 0, 0, 0 end
    function k.Transform:GetRotation() return 0 end
    function k.Transform:GetScale() return scale, scale, scale end
    local tg = { IsValid = function() return true end, Transform = { GetWorldPosition = function() return 15, 0, 0 end } }
    k.replica = { combat = { GetTarget = function() return tg end } }
    now = now + 10
    return Predict.Draw({ k }, function() return { harmful = true, hit = 3 } end, .5, { x = 15, z = 0, ent = tg }, function() return false end)
end
check(KlausAt(1.68) == true and KlausAt(1.2) == false, "Klaus enraged: its chomp reaches you 15 away (its leap goes as far as it is big); as it is, it falls short")
-- Klaus' chomp: once it has aimed (frame 28), running off doesn't move where it lands
local kl = { prefab = "klaus", AnimState = {}, Transform = {} }
local kpos, kt = { 5, 0 }, 0
function kl:IsValid() return true end
function kl.AnimState:IsCurrentAnimation(a) return a == "attack_chomp" end
function kl.AnimState:GetCurrentAnimationTime() return kt end
function kl.Transform:GetWorldPosition() return 0, 0, 0 end
function kl.Transform:GetRotation() return 0 end
local ktg = { IsValid = function() return true end, Transform = { GetWorldPosition = function() return kpos[1], 0, kpos[2] end } }
kl.replica = { combat = { GetTarget = function() return ktg end } }
local function K2(px, pz) return Predict.Draw({ kl }, function() return { harmful = true, hit = 3 } end, .5, Me(px, pz, ktg), function() return false end) end
now = 4000
K2(5, 0)
now = 4000 + 30 * FRAMES -- (aimed)
kt = 30 * FRAMES -- (its animation that far on too: it aims till frame 26 of it)
K2(5, 0)
kpos[1], kpos[2] = 5, -6 -- (you ran off)
check(K2(5, 0) == true and K2(5, -6) == false, "Klaus' chomp: lands where it aimed, not following you after")

-- the old ways are off: an unknown monster isn't foretold
local hound = { prefab = "hound", AnimState = {}, Transform = {} }
function hound:IsValid() return true end
function hound.AnimState:IsCurrentAnimation(a) return a == "atk_pre" end
function hound.AnimState:GetCurrentAnimationTime() return 0 end
function hound.Transform:GetWorldPosition() return 0, 0, 0 end
function hound.Transform:GetRotation() return 0 end
check(Predict.Draw({ hound }, function() return { harmful = true, hit = 3 } end, .5, { x = 1, z = 0 }, function() return false end) == false,
    "old ways off: a hound winding up isn't foretold")

-- (a while on: the hound just looked at gone - a crystal falls with no hound by it)
now = now + 5
-- a crystal falling: where it lands is outlined around it
local crystal = { prefab = "alterguardian_phase3trapprojectile", Transform = { GetWorldPosition = function() return 30, 0, 30 end, GetRotation = function() return 0 end } }
function crystal:IsValid() return true end
check(Predict.DrawHazards({ crystal }, .5, { x = 31.5, z = 30 }) == true, "next to a falling crystal: in it")
check(Predict.DrawHazards({ crystal }, .5, { x = 34, z = 30 }) == false, "4 away: not")

-- a spike trail: the whole wall while it runs; once it stops, spike by spike from the middle out
local tx2, tz2 = 50, 50
local trail = { prefab = "alterguardian_phase2spiketrail", Transform = { GetWorldPosition = function() return tx2, 0, tz2 end, GetRotation = function() return 0 end } }
function trail:IsValid() return true end
local function W(px, pz) return Predict.DrawHazards({ trail }, .5, { x = px, z = pz }) end
now = 300
W(0, 0)
now, tx2 = 300.1, 52 -- (running)
-- running: its whole wall goes along with it
check(W(52, 50) == true and W(62, 50) == false, "running: its wall goes along with it")
now = 300.2 -- (stopped)
W(0, 0)
-- (the middle's spikes up - those beside it too; the ends still to come: 12 frames after its first, which comes 16 after
-- it stops (its data's delay, run offline since 2026-10-19) - at 12 from the stop none had risen, all of it still to come)
-- (its strikes any time 15-30 frames from the stop since 2026-10-29 (SimMoves TRAILWAIT): 12 frames past the latest)
now = 300.2 + ((rawget(_G, "TR_OLD_TRAILWAIT") and 16 or 30) + 12) * FRAMES
check(W(52, 50) == false and W(50, 50 + 7) == true, "after the middle rose: only the rest still to come")
now = 300.2 + 60 * FRAMES
check(W(52, 50 + 7) == false, "all risen: nothing left")

-- not probed
check(not Learn.NeedsProbe("alterguardian_phase3", "attk_beam"), "simulated bosses aren't probed")
-- the Celestial Champion's phase 2 spin chases you (as fast as you run): round itself, wherever it is
check(Move("alterguardian_phase2", "attk_spin_pre", 2, 0, 10, 0) == true and Move("alterguardian_phase2", "attk_spin_pre", 8, 0, 10, 0) == false,
    "spin: round itself, not out past you")
-- the Celestial Champion's phase 1 stomping (3 to 5 times): on while it stomps, gone after its last
local st = { prefab = "alterguardian_phase1", AnimState = {}, Transform = {} }
local st_anim, st_t = "tantrum_pre", 0
function st:IsValid() return true end
function st:HasTag() return false end
function st.AnimState:IsCurrentAnimation(a) return a == st_anim end
function st.AnimState:GetCurrentAnimationTime() return st_t end
function st.Transform:GetWorldPosition() return 0, 0, 0 end
function st.Transform:GetRotation() return 0 end
local sttg = { IsValid = function() return true end, Transform = { GetWorldPosition = function() return 4, 0, 0 end } }
st.replica = { combat = { GetTarget = function() return sttg end } }
local function ST(px) return Predict.Draw({ st }, function() return { harmful = true, hit = 3 } end, .5, Me(px, 0, sttg), function() return false end) end
now = 5000
check(ST(2) == true, "stomping: before the first")
now, st_anim, st_t = 5003, "tantrum_loop", .5
check(ST(2) == true, "stomping: still at it a few stomps on")
-- (its last stomp in tantrum_pst, 8 frames in - not before the loop's own 64 frames are out, as
-- in the game: the loop seen at 0.5 in, begun at 5002.5)
now, st_anim, st_t = 5002.5 + 64 / 30 + .1, "tantrum_pst", .1
check(ST(2) == true, "stomping: its last, in the pst, still to come")
now, st_anim, st_t = 5002.5 + 64 / 30 + 1.2, "tantrum_pst", 1.2
check(ST(2) == false, "stomping: done after its last")
print(fails == 0 and "ALL PASSED" or (fails .. " FAILED"))
