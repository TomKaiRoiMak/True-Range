-- Moves written by hand for Tropical Experience, not by the offline runs - laid over its data as it's put on
-- (true_range/moddata), as moves_hand_um is for Uncompromising Mode: a rebuild of moves_sim_te never drops them.
return {
    -- (the scorpion's leap (SGscorpion leap_attack: atk, SetMotorVelOverride 20 from frame 8, its blow at 19) and its claw (attack:
    -- atk, still, its blow at 25) begin alike - both drawn at once, 962 frames on the bench of its monsters (2026-10-31_0611
    -- BOTHDRAWN). The leap only when you're over 3 off (evade_pst: JUMP_DISTANCE 3) - the run never found that (not where it
    -- looks for it): far told here, the claw drawn till the leap sets off (true_range/predict's far tell, as the slip's).
    -- TR_OLD_SCORPFAR: both)
    scorpion = not rawget(_G, "TR_OLD_SCORPFAR") and { ["atk~leap_attack"] = { copy = { "scorpion", "atk~leap_attack" }, far = 3,
        replace = true } } or nil,
}
