-- Moves written by hand for Tropical Experience, not by the offline runs - laid over its data as it's put on
-- (true_range/moddata), as moves_hand_um is for Uncompromising Mode: a rebuild of moves_sim_te never drops them.
return {
    -- (Tropical Experience's twisters' attack (SGtwister / SGfiretwister attack): half the time, at random, its atk played 10
    -- frames late with a tornado made then (twister_tornado / twister_tornadodefogo) - its blow still at the state's 33: 23
    -- into that atk. Drawn 10 late, the red after the blow: 223 and 269 drawn-in unstruck (bench 2026-11-01_0556). Told by
    -- the tornado. TR_OLD_TWISTERTELL: one timing)
    twister = not rawget(_G, "TR_OLD_TWISTERTELL") and { ["atk~tornado"] = { copy = { "twister", "atk" }, shift = -10, tell = "twister_tornado" } } or nil,
    firetwister = not rawget(_G, "TR_OLD_TWISTERTELL") and { ["atk~tornado"] = { copy = { "firetwister", "atk" }, shift = -10, tell = "twister_tornadodefogo" } } or nil,
    -- (Tropical Experience's live fish (fishesunderwater.lua, SGfishunderwater): their "attack" plays walk_loop - their idle and
    -- swim the same - its damage commented out, no retarget: 0 blows on the bench, ~70 drawn-in each kind, all while idle
    -- (bench 2026-11-01_0556). Not a move. TR_OLD_FISHATK: as run)
    mecfish_alive = not rawget(_G, "TR_OLD_FISHATK") and { walk_loop = false } or nil,
    fish2_alive = not rawget(_G, "TR_OLD_FISHATK") and { walk_loop = false } or nil,
    fish3_alive = not rawget(_G, "TR_OLD_FISHATK") and { walk_loop = false } or nil,
    fish4_alive = not rawget(_G, "TR_OLD_FISHATK") and { walk_loop = false } or nil,
    fish5_alive = not rawget(_G, "TR_OLD_FISHATK") and { walk_loop = false } or nil,
    fish6_alive = not rawget(_G, "TR_OLD_FISHATK") and { walk_loop = false } or nil,
    fish7_alive = not rawget(_G, "TR_OLD_FISHATK") and { walk_loop = false } or nil,
    goldfish_alive = not rawget(_G, "TR_OLD_FISHATK") and { walk_loop = false } or nil,
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
        or { copy = { "rookwater", "atk_pre" }, shift = -30, anims = { "atk" }, lock = 0,
        -- (and the way it faces as it runs on, as the Rook's - true_range/simmoves; TR_OLD_ROOKFACE: at its target)
        frame = not rawget(_G, "TR_OLD_ROOKFACE") and "facing" or nil } } or nil,
    -- (the wild boar king's pound (SGwildboreking pound: jump, GroundPound at 30 round itself - groundpounder rings from 1, each
    -- point striking 3 round, it doesn't move): run on into its walk (walk_loop, a leg of 6.5 twice), drawn 3.4 on ahead of it -
    -- struck 1.99-2.56 behind it, 8 of 39 undrawn, TE bench 2026-10-31_1020. Its pound alone, where it stands. TR_OLD_BOARPOUND:
    -- as run)
    wildboreking = not rawget(_G, "TR_OLD_BOARPOUND") and { jump = { copy = { "wildboreking", "jump" }, drop = { "leg" },
        anims = { "jump" }, replace = true } } or nil,
    -- (the gem deer's tornadoes: striking all within 3 of their middle (SGgreentornado1 destroystuff, FindEntities 3), run offline
    -- reaching ~2.85 - struck 2.85-3.00 off undrawn, 6 of 6 missed on the bench 2026-11-01. Drawn 1.05 as big (h.scale .95).
    -- TR_OLD_TORNADO2: as run)
    -- (the spiky turtle's slide (SGspikyturtle_tfc slide: attack2_loop, up to 25 a second, 5 slides of 2 s): striking each
    -- within 3 of its middle once a slide (SlideTask every 0.1 s, SLIDE_RADIUS) - not in the run's data, never drawn: 3 struck
    -- undrawn on the lag bench 2026-11-02_0329. Round itself while it plays attack2_loop (simmoves _on_anims), the shape of UM
    -- shadow Abigail's burst (FindEntities 3 too). TR_OLD_TURTLESLIDE: none)
    _hazards = { greentornado2 = not rawget(_G, "TR_OLD_TORNADO2") and { copy_hazard = "greentornado2", scale = .95, replace = true } or nil,
        spiky_turtle_tfc = not rawget(_G, "TR_OLD_TURTLESLIDE") and { by = { "spiky_turtle_tfc" }, delay = 0, lasting = true, moved = true,
            steps = { { at = 0, cells = "b21k2411h2A11f2E11e2G11d2I11c2K11c2K11b2M11b2M11b2M11a2O11a2O11a2O11a2O11a2O11b2M11b2M11b2M11c2K11c2K11d2I11e2G11f2E11h2A11k24" } } } or nil },
    scorpion = not rawget(_G, "TR_OLD_SCORPFAR") and { ["atk~leap_attack"] = { copy = { "scorpion", "atk~leap_attack" }, far = 3,
        replace = true } } or nil,
}
