-- Moves written by hand for Tropical Experience, not by the offline runs - laid over its data as it's put on
-- (true_range/moddata), as moves_hand_um is for Uncompromising Mode: a rebuild of moves_sim_te never drops them.
return {
    -- (the scorpion's leap (SGscorpion leap_attack: atk, SetMotorVelOverride 20 from frame 8, its blow at 19) and its claw (attack:
    -- atk, still, its blow at 25) begin alike - both drawn at once, 962 frames on the bench of its monsters (2026-10-31_0611
    -- BOTHDRAWN). The leap only when you're over 3 off (evade_pst: JUMP_DISTANCE 3) - the run never found that (not where it
    -- looks for it): far told here, the claw drawn till the leap sets off (true_range/predict's far tell, as the slip's).
    -- TR_OLD_SCORPFAR: both)
    -- (the water rook (SGrookwater): the rook's charge over again - atk_pre, paw_loop, then atk looping as it runs, its blow as it
    -- runs into you (runningattack DoAttack); ROOK_RUN_SPEED, its body 1.5 - only its atk_pre in the data: struck running, 9 of 195
    -- undrawn and 524 drawn-in-unstruck on the bench of TE's monsters (0611). The rook's own running blow (atk, first 0) as
    -- its. TR_OLD_ROOKWATER: none)
    -- (and its own reach, not the Rook's: no SetRange (rookwater.lua :181-190), the combat's 3 (combat.lua :29-30) to the Rook's 2
    -- (rook.lua :192) - its own atk_pre run so (gore 3.76 to 2.76); struck 3.07 and 3.29 off out of the Rook's, at sea, bench
    -- 2026-10-31_0933. Its atk_pre's shape from the frame it runs (30), as its blow. TR_OLD_ROOKRANGE: the Rook's)
    rookwater = not rawget(_G, "TR_OLD_ROOKWATER") and { atk = rawget(_G, "TR_OLD_ROOKRANGE") and { copy = { "rook", "atk" } }
        or { copy = { "rookwater", "atk_pre" }, shift = -30, anims = { "atk" }, lock = 0 } } or nil,
    scorpion = not rawget(_G, "TR_OLD_SCORPFAR") and { ["atk~leap_attack"] = { copy = { "scorpion", "atk~leap_attack" }, far = 3,
        replace = true } } or nil,
}
