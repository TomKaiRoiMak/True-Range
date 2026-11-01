-- Moves written by hand for Uncompromising Mode, not by the offline runs - laid over its data as it's put
-- on (true_range/moddata), each only where that data has none: a rebuild of moves_sim_um never drops them.
-- (the Eye of Terror's and Spazmatism's shot: a state striking nothing itself (its mini eye, its fireballs
-- strike, drawn as things) - no run makes a move of it ("shoot_pre: nothing"); one that draws nothing (maps
-- {}), still, told by the chargepulse it makes (tell): what tells it from the charge that begins alike, the
-- charge not drawn over it - the twins agent, 2026-10-18; lost to the rebuild of 2026-10-19, kept here since)
-- (the Eye of Terror's own (2026-10-27): its mini eye flies through the ground, striking only what it touches while still up -
-- its capsule 1.5 meeting you within 2 of its way from 2 to 4.5 ahead (UM eyeofterror_extras.lua fneye_proj, Launch offset 2,
-- dipping 14 a second): struck right by the Eye before the mini eye was even seen, 13 of 13 undrawn on the lag bench. Drawn
-- there as it shoots: frame 39 (charge_pre's 33 + shoot_loop's 6), again each charge_loop of its mouth's shots)
return {
    -- (UM's skeletons (SGrneskeletons attack: atk_pre, atk; its second blow's atk alone) run offline on into walk_loop and idle
    -- - them in its lists, any walk or idle taken for its later part: 23 idle-drawn, 47 drawn-in unstruck (bench
    -- 2026-11-01_1604). Their own animations alone. TR_OLD_RNESKEL: as run)
    rneskeleton = not rawget(_G, "TR_OLD_RNESKEL") and { atk_pre = { copy = { "rneskeleton", "atk_pre" }, anims = { "atk_pre", "atk" }, replace = true },
        -- (its "atk" run offline from leap_attack - a state nothing goes into (SGrneskeletons, nowhere else): every plain swing,
        -- its atk_pre a frame long, taken for that leap, its blow drawn at 19, 9 frames after it struck - 30 drawn-in unstruck.
        -- Gone: the swing (atk_pre, atk) drawn by its own. TR_OLD_RNELEAP: kept)
        atk = rawget(_G, "TR_OLD_RNELEAP") and { copy = { "rneskeleton", "atk" }, anims = { "atk" }, replace = true } or false } or nil,
    eyeofterror = {
        ["charge_pre~shoot_pre"] = { anchor = "lock", anims = { "charge_pre", "charge_loop", "charge_pst" }, cooldown = "charge_cd", first = 39, frame = "target", lock = 39, lock_things = true, maps = { { dist = 1, path = "0.00", steps = { { again_anim = "charge_loop", again_at = 6, again_until = 200, at = 39, cells = "f21u2A11r2G11p2K11o2M11o2M11n2O11n2O11n2O11m2Q11n2O11n2O11n2O11o2M11o2M11p2K11r2G11u2A" } } }, { dist = 2, path = "0.00", same = true }, { dist = 3, path = "0.00", same = true }, { dist = 4, path = "0.00", same = true }, { dist = 5, path = "0.00", same = true }, { dist = 6, path = "0.00", same = true }, { dist = 7, path = "0.00", same = true }, { dist = 8, path = "0.00", same = true }, { dist = 9, path = "0.00", same = true }, { dist = 10, path = "0.00", same = true }, { dist = 11, path = "0.00", same = true }, { dist = 12, path = "0.00", same = true }, { dist = 13, path = "0.00", same = true }, { dist = 14, path = "0.00", same = true }, { dist = 15, path = "0.00", same = true }, { dist = 16, path = "0.00", same = true } }, still = true, tell = "eyeofterror_chargepulse" },
        ["charge_pre~shoot_pre~2"] = { after_anim = "transform", after_mem = "transformed", anchor = "lock", anims = { "charge_pre", "charge_loop", "charge_pst" }, cooldown = "charge_cd", first = 39, frame = "target", lock = 39, lock_things = true, maps = { { dist = 1, path = "0.00", steps = { { again_anim = "charge_loop", again_at = 6, again_until = 200, at = 39, cells = "f21u2A11r2G11p2K11o2M11o2M11n2O11n2O11n2O11m2Q11n2O11n2O11n2O11o2M11o2M11p2K11r2G11u2A" } } }, { dist = 2, path = "0.00", same = true }, { dist = 3, path = "0.00", same = true }, { dist = 4, path = "0.00", same = true }, { dist = 5, path = "0.00", same = true }, { dist = 6, path = "0.00", same = true }, { dist = 7, path = "0.00", same = true }, { dist = 8, path = "0.00", same = true }, { dist = 9, path = "0.00", same = true }, { dist = 10, path = "0.00", same = true }, { dist = 11, path = "0.00", same = true }, { dist = 12, path = "0.00", same = true }, { dist = 13, path = "0.00", same = true }, { dist = 14, path = "0.00", same = true }, { dist = 15, path = "0.00", same = true }, { dist = 16, path = "0.00", same = true } }, still = true, tell = "eyeofterror_chargepulse" },
    },
    twinofterror2 = {
        ["charge_pre~shoot_pre"] = { anchor = "lock", anims = { "charge_pre", "charge_loop", "charge_pst" }, cooldown = "charge_cd", first = 34, frame = "target", lock = 34, lock_things = true, maps = {  }, nothing = true, still = true, tell = "eyeofterror_chargepulse" },
        ["charge_pre~shoot_pre~2"] = { after_anim = "transform", after_mem = "transformed", anchor = "lock", anims = { "charge_pre", "charge_loop", "charge_pst" }, cooldown = "charge_cd", first = 34, frame = "target", lock = 34, lock_things = true, maps = {  }, nothing = true, still = true, tell = "eyeofterror_chargepulse" },
    },
    -- (Uncompromising Mode's own guards of its bee queens - their bite (defensiveattack, animation atk, DoAttack at frame 13,
    -- postinit/stategraphs/SGbeeguard.lua :523-551): within their own reach and your body - the blocker 1.5, the seeker and the
    -- shooter 2.25 (prefabs/um_beeguards.lua :308/:346) - no run makes them (the sim can't, without their queen): struck you
    -- 171/142/13 times on the bench with nothing at all drawn, tools/nothing_check.lua, 2026-10-20. Scale: their own size)
    -- (and their dive's landing (stab, frame 3: DoAreaAttack 2 round where it came down - your middle; the seeker's animation
    -- stab_death, the others' stab_pst; postinit/stategraphs/SGbeeguard.lua :273-305) - the seeker's 132 struck undrawn on the bench.
    -- Laid the way it faces, round itself: sent down by its queen at a spot, after no one (notarget) - laid towards its target, none,
    -- it was drawn as nothing)
    um_beeguard_blocker = { stab_pst = { anchor = "lock", anims = { "stab_pst" }, first = 3, frame = "facing", lock = 0, lock_things = true, maps = { { dist = 1, path = "0.00", steps = { { at = 3, cells = "f21k2411i2811h2A11g2C11f2E11f2E11e2G11e2G11e2G11e2G11e2G11f2E11f2E11g2C11h2A11i2811k24" } } }, { dist = 2, path = "0.00", same = true }, { dist = 3, path = "0.00", same = true }, { dist = 4, path = "0.00", same = true }, { dist = 5, path = "0.00", same = true }, { dist = 6, path = "0.00", same = true }, { dist = 7, path = "0.00", same = true }, { dist = 8, path = "0.00", same = true }, { dist = 9, path = "0.00", same = true }, { dist = 10, path = "0.00", same = true }, { dist = 11, path = "0.00", same = true }, { dist = 12, path = "0.00", same = true }, { dist = 13, path = "0.00", same = true }, { dist = 14, path = "0.00", same = true }, { dist = 15, path = "0.00", same = true }, { dist = 16, path = "0.00", same = true } }, random = false, single = false, still = true }, atk = { anchor = "lock", anims = { "atk" }, first = 13, frame = "target", lock = 0, lock_things = true, maps = { { dist = 1, path = "0.00", steps = { { at = 13, cells = "f21k2411i2811h2A11g2C11f2E11f2E11e2G11e2G11e2G11e2G11e2G11f2E11f2E11g2C11h2A11i2811k24" } } }, { dist = 2, path = "0.00", same = true }, { dist = 3, path = "0.00", same = true }, { dist = 4, path = "0.00", same = true }, { dist = 5, path = "0.00", same = true }, { dist = 6, path = "0.00", same = true }, { dist = 7, path = "0.00", same = true }, { dist = 8, path = "0.00", same = true }, { dist = 9, path = "0.00", same = true }, { dist = 10, path = "0.00", same = true }, { dist = 11, path = "0.00", same = true }, { dist = 12, path = "0.00", same = true }, { dist = 13, path = "0.00", same = true }, { dist = 14, path = "0.00", same = true }, { dist = 15, path = "0.00", same = true }, { dist = 16, path = "0.00", same = true } }, random = false, scale = 1.6, single = true, still = true } },
    -- (and its dive: stab_pre then stab looping all the way down from 35 up (postinit/stategraphs/SGbeeguard.lua flydown :190-224),
    -- striking 2 round it at frame 3 of stab_death once down - the run's stab_pre struck at its frame 3, drawn its first frames only;
    -- its clock held while it falls (waits), its ring round it the whole dive, yellow to red by how far it has yet to fall (fall: 30 a
    -- second, 30 to 0 in about 1 s - lag 0853). TR_OLD_SEEKERWAIT: as the run has it)
    -- (the plain guard's dive the same (flydown, stab_pre/stab, its blow at frame 3 of stab_pst once down): as the bomber's.
    -- TR_OLD_SEEKERWAIT: as the run has it)
    beeguard = { stab_pre = not rawget(_G, "TR_OLD_SEEKERWAIT") and { copy = { "beeguard", "stab_pre" },
        waits = { "stab_pre", "stab" }, fall = 30, replace = true } or nil },
    um_beeguard_seeker = { stab_pre = not rawget(_G, "TR_OLD_SEEKERWAIT") and { copy = { "um_beeguard_seeker", "stab_pre" },
        waits = { "stab_pre", "stab" }, fall = 30, replace = true } or nil, stab_death = { anchor = "lock", anims = { "stab_death" }, first = 3, frame = "facing", lock = 0, lock_things = true, maps = { { dist = 1, path = "0.00", steps = { { at = 3, cells = "f21k2411i2811h2A11g2C11f2E11f2E11e2G11e2G11e2G11e2G11e2G11f2E11f2E11g2C11h2A11i2811k24" } } }, { dist = 2, path = "0.00", same = true }, { dist = 3, path = "0.00", same = true }, { dist = 4, path = "0.00", same = true }, { dist = 5, path = "0.00", same = true }, { dist = 6, path = "0.00", same = true }, { dist = 7, path = "0.00", same = true }, { dist = 8, path = "0.00", same = true }, { dist = 9, path = "0.00", same = true }, { dist = 10, path = "0.00", same = true }, { dist = 11, path = "0.00", same = true }, { dist = 12, path = "0.00", same = true }, { dist = 13, path = "0.00", same = true }, { dist = 14, path = "0.00", same = true }, { dist = 15, path = "0.00", same = true }, { dist = 16, path = "0.00", same = true } }, random = false, single = false, still = true }, atk = { anchor = "lock", anims = { "atk" }, first = 13, frame = "target", lock = 0, lock_things = true, maps = { { dist = 1, path = "0.00", steps = { { at = 13, cells = "c21k2411h2A11g2C11f2E11e2G11d2I11c2K11c2K11c2K11b2M11b2M11b2M11b2M11b2M11c2K11c2K11c2K11d2I11e2G11f2E11g2C11h2A11k24" } } }, { dist = 2, path = "0.00", same = true }, { dist = 3, path = "0.00", same = true }, { dist = 4, path = "0.00", same = true }, { dist = 5, path = "0.00", same = true }, { dist = 6, path = "0.00", same = true }, { dist = 7, path = "0.00", same = true }, { dist = 8, path = "0.00", same = true }, { dist = 9, path = "0.00", same = true }, { dist = 10, path = "0.00", same = true }, { dist = 11, path = "0.00", same = true }, { dist = 12, path = "0.00", same = true }, { dist = 13, path = "0.00", same = true }, { dist = 14, path = "0.00", same = true }, { dist = 15, path = "0.00", same = true }, { dist = 16, path = "0.00", same = true } }, random = false, scale = 1.2, single = true, still = true } },
    -- (and its stinger shot: shoot_pre (postinit/stategraphs/SGbeeguard.lua :367-382) loops till Shoot a second on, a homing stinger
    -- at 25 a second (um_beeguards.lua :179-200) - drawn only once seen flying, one shot from 2.9 off struck the frame it was first
    -- seen (lag 0636); drawn as a lane till it shoots, as the spitter's spit. TR_OLD_STINGSHOT: none)
    -- (the shadow hound: a hound with another look (uncompromising_hounds.lua fnrne - fncommon("hound", "rnehound"), SGhound),
    -- not found by the run - drawn as the hound. TR_OLD_RNEHOUND: none)
    -- (and Shadow Wixie's clones in her puzzle (shadow_wixie_helper, SpawnDupes): her own stategraph, bank and build, her charge
    -- and slingshot - "nothing" in every state of the run for her reasons (puzzlespawn, struck only players). TR_OLD_WIXIEHELPER: none)
    _alias = { rnehound = not rawget(_G, "TR_OLD_RNEHOUND") and "hound" or nil,
        shadow_wixie_helper = not rawget(_G, "TR_OLD_WIXIEHELPER") and "shadow_wixie" or nil },
    um_beeguard_shooter = { shoot_pre = not rawget(_G, "TR_OLD_STINGSHOT") and { anchor = "lock", anims = { "shoot_pre" }, first = 30,
        frame = "target", lock = 30, lock_things = true, maps = {}, random = false, shoots = "um_beestinger_projectile", single = true,
        still = true } or nil, stab_pst = { anchor = "lock", anims = { "stab_pst" }, first = 3, frame = "facing", lock = 0, lock_things = true, maps = { { dist = 1, path = "0.00", steps = { { at = 3, cells = "f21k2411i2811h2A11g2C11f2E11f2E11e2G11e2G11e2G11e2G11e2G11f2E11f2E11g2C11h2A11i2811k24" } } }, { dist = 2, path = "0.00", same = true }, { dist = 3, path = "0.00", same = true }, { dist = 4, path = "0.00", same = true }, { dist = 5, path = "0.00", same = true }, { dist = 6, path = "0.00", same = true }, { dist = 7, path = "0.00", same = true }, { dist = 8, path = "0.00", same = true }, { dist = 9, path = "0.00", same = true }, { dist = 10, path = "0.00", same = true }, { dist = 11, path = "0.00", same = true }, { dist = 12, path = "0.00", same = true }, { dist = 13, path = "0.00", same = true }, { dist = 14, path = "0.00", same = true }, { dist = 15, path = "0.00", same = true }, { dist = 16, path = "0.00", same = true } }, random = false, single = false, still = true }, atk = { anchor = "lock", anims = { "atk" }, first = 13, frame = "target", lock = 0, lock_things = true, maps = { { dist = 1, path = "0.00", steps = { { at = 13, cells = "c21k2411h2A11g2C11f2E11e2G11d2I11c2K11c2K11c2K11b2M11b2M11b2M11b2M11b2M11c2K11c2K11c2K11d2I11e2G11f2E11g2C11h2A11k24" } } }, { dist = 2, path = "0.00", same = true }, { dist = 3, path = "0.00", same = true }, { dist = 4, path = "0.00", same = true }, { dist = 5, path = "0.00", same = true }, { dist = 6, path = "0.00", same = true }, { dist = 7, path = "0.00", same = true }, { dist = 8, path = "0.00", same = true }, { dist = 9, path = "0.00", same = true }, { dist = 10, path = "0.00", same = true }, { dist = 11, path = "0.00", same = true }, { dist = 12, path = "0.00", same = true }, { dist = 13, path = "0.00", same = true }, { dist = 14, path = "0.00", same = true }, { dist = 15, path = "0.00", same = true }, { dist = 16, path = "0.00", same = true } }, random = false, scale = 1.2, single = true, still = true } },
    -- (the lavae's slime (lavae2 ondeath -> lavaeslime): set alight as it's made, it blows up 3-6 s on, setting alight all within 4
    -- of it (prefabs/lavaeslime.lua OnExplodeFn, FindEntities 4, Ignite) - no run makes it, no boss sets it off; the testbench's
    -- stand-in set alight 3.5 off one, nothing drawn, 2026-10-28. Drawn 4 round it from its first moment, red from 3 s on)
    -- (the Rock Lobster's uppercut, gone into straight from walking (SGboulder_crab walk animover: uppercut, no atk before it) -
    -- run offline only as the end of its atk: no move begun at it, its claw at frame 46 (DoAttack, its range 3 and your body)
    -- struck undrawn as it ran at you 3 a second, 3 of 383 on the bench, 2026-10-28. Drawn round it as it runs)
    boulder_crab = { uppercut = { anims = { "uppercut" }, around = "Z21m2011h2A11f2E11e2G11d2I11c2K11b2M11a2O11a2O11Z2Q11Z2Q11Z2Q11Z2Q11Z2Q11Y2S11Z2Q11Z2Q11Z2Q11Z2Q11Z2Q11a2O11a2O11b2M11c2K11d2I11e2G11f2E11h2A11m20", first = 46, frame = "target", maps = { { dist = 1, path = "0.00", steps = { { at = 46, cells = "Z21m2011h2A11f2E11e2G11d2I11c2K11b2M11a2O11a2O11Z2Q11Z2Q11Z2Q11Z2Q11Z2Q11Y2S11Z2Q11Z2Q11Z2Q11Z2Q11Z2Q11a2O11a2O11b2M11c2K11d2I11e2G11f2E11h2A11m20" } } }, { dist = 2, path = "0.00", same = true }, { dist = 3, path = "0.00", same = true }, { dist = 4, path = "0.00", same = true }, { dist = 5, path = "0.00", same = true }, { dist = 6, path = "0.00", same = true }, { dist = 7, path = "0.00", same = true }, { dist = 8, path = "0.00", same = true }, { dist = 9, path = "0.00", same = true }, { dist = 10, path = "0.00", same = true }, { dist = 11, path = "0.00", same = true }, { dist = 12, path = "0.00", same = true }, { dist = 13, path = "0.00", same = true }, { dist = 14, path = "0.00", same = true }, { dist = 15, path = "0.00", same = true }, { dist = 16, path = "0.00", same = true } }, random = false, single = true } },
    -- (the ice hound's quickattack (UM postinit SGhound.lua 416): from past 3 off, atk_pre slowed to .3, at frame 24 its IceSpike -
    -- the Glacial Hound's own spike line (GlacialProjectile), shot there at frame 8. Not run offline: UM's postinit stategraphs
    -- aren't in the runs. A player's game drew each spike only as it struck, 11 struck undrawn (replay CLIENT 2026-10-29)
    -- (Bearger's boulders (UM postinit SGbearger shoot, anim "t"): five launched from its own middle at frame 25 - one landing
    -- on whoever is beside it at once, striking 3 round there (bearger_boulder OnHitInk); never seen in a player's game, 5 struck
    -- undrawn at 2 off on the lag bench 2026-10-29_0633. Round itself, SimMoves._land; the boulders farther out are drawn as things)
    bearger = { t = { anims = { "t" }, first = 25, frame = "facing", maps = {}, nothing = true, random = false, single = true, still = true } },
    icehound = { ["atk_pre~quickattack"] = { copy = { "glacialhound", "atk_pre~ice_howl_attack" }, shift = 16, drop = { "from", "from_self" },
        -- (on into idle: atk_pre sped back up at 24, over a few frames on, the line still going out 0.5 s)
        anims = { "atk_pre" }, far = 3, lock = 24, slowed = true },
        -- (and its bite only from within 3 - the hound's own, as it was)
        -- (its bite from past 3 too, its spike not ready: told from the spike by its pace (true_range/predict sim.slowed) - its
        -- near dropped. TR_OLD_SLOWED: near 3.2)
        atk_pre = { copy = { "hound", "atk_pre" }, near = rawget(_G, "TR_OLD_SLOWED") and 3.2 or nil, replace = true } },
    -- (a merm struck four times strikes back: karate, atk_combo, its blow at 12, 18 and 31 - each as its atk's (postinit
    -- stategraphs/SGmerm.lua :65-95); no move begun by atk_combo, tools/um_postinit_gaps.lua 2026-10-29. TR_OLD_KARATE: none)
    -- (Shadow Wixie's slingshot (SGshadow_wixie slingshot_shoot): her burst 4 round her at 15 (DamageNearbyEnemies) - the run's
    -- move - and 7 shots off from 15, .05 s apart (ShootVolley): each at the point 15 on from you at -66..66 by 22 off the way
    -- to you, straight on at 20 a second for 2 s, striking whoever's middle comes within .9 (shadow_wixie.lua CollisionCheck,
    -- your body in it: .4, .5 drawn). TR_OLD_VOLLEY: none)
    shadow_wixie = { slingshot_pre = { copy = { "shadow_wixie", "slingshot_pre" }, replace = true,
        volley = { n = 7, step = 22, out = 15, at = 15, every = 1.5, len = 40, r = .5, speed = 20 } } },
    -- (UM's strong Deerclops' uppercut combo (postinit SGdeerclops uppercutcombo): at 60 turned to you and on at walkspeed 20,
    -- its blow 6 round where it is at 70 - on a set way, past you, not stopping at you: run offline as moving on with you
    -- (follow 7.25), its ring laid on from you - 4.32 and 5.49 behind it struck undrawn (bench 2026-11-01_0433). From itself.
    -- TR_OLD_DEERDASH: as run)
    deerclops = not rawget(_G, "TR_OLD_DEERDASH") and { ["uppercutcombo@MakeStrong"] = { copy = { "deerclops", "uppercutcombo@MakeStrong" },
        drop = { "follow" }, replace = true,
        -- (and as fast as it really goes: run offline 1.1 a frame from 60, in the game .78 - 7.84 by 70, 21 of its 27 goes on the
        -- bench 2026-11-01_0433; its ring laid ~3 past where it struck. TR_OLD_DEERSPEED: as run)
        path_k = not rawget(_G, "TR_OLD_DEERSPEED") and { from = 60, k = .71 } or nil,
        ring_from = not rawget(_G, "TR_OLD_DEERSPEED") and { at = 70, from = "free", ahead = 7.85 } or nil } } or nil,
    -- (the spore hound's leap (postinit SGhound: jump_atk_loop, its blow at 15) run on into hit and taunt, them in its list - any
    -- hit of it taken for gone straight into its leap's later part, its leap drawn through its stagger: 74 of its 77 drawn-in
    -- unstruck on the bench 2026-11-01_0433 (979 frames in "hit"). Its own animation alone. TR_OLD_SPORELEAP: as run)
    sporehound = not rawget(_G, "TR_OLD_SPORELEAP") and { jump_atk_loop = { copy = { "sporehound", "jump_atk_loop" }, anims = { "jump_atk_loop" },
        replace = true } } or nil,
    -- (the cave spider hider drawn as a spider (_alias): a spider's hide is the moon spider's spike attack (SGspider spike_attack,
    -- DoSpikeAttack at 14), the hider's the same animation is its shield (SGspider shield) - harmless, drawn as spikes 120 of its
    -- 200 shield frames on the bench 2026-11-01_0433. TR_OLD_HIDERSHIELD: as a spider's)
    spider_hider = not rawget(_G, "TR_OLD_HIDERSHIELD") and { hide = false } or nil,
    merm = not rawget(_G, "TR_OLD_KARATE") and { atk_combo = { copy = { "merm", "atk" }, anims = { "atk_combo" }, at_each = { 12, 18, 31 } } } or nil,
    _hazards = {
        -- (the Walrus's thrown bear trap (postinit walrus.lua LaunchTrap, um_bear_trap.lua OnTrapLand): lobbed at where you stood
        -- at its frame 20, ~.6 s up, then a trap that tests for you the moment it lands - the trap drawn only once down, too late:
        -- struck 1.88 from where it fell (lag 2026-11-01_2159, 579.833). Drawn as the trap, where it'll come down (moved: its
        -- landing fitted as it flies). TR_OLD_TRAPTHROW: none)
        um_bear_trap_projectile = not rawget(_G, "TR_OLD_TRAPTHROW") and { copy_hazard = "um_bear_trap", by = { "walrus" },
            lasting = false, moved = true } or nil,
        -- (the Moon Tentacle's mine (um_tentacle_moon_projectile.lua lobbedminefn): lands and waits, goes off 2-6 s on or as you come
        -- within 0.5 - striking all within 3 (OnExplode FindEntities 3); never drawn: 3 struck undrawn on the lag bench 2026-10-30_0045.
        -- As Toadstool's bomb (3.5) made 3. TR_OLD_MOONMINE: none)
        um_tentacle_moon_mine = not rawget(_G, "TR_OLD_MOONMINE") and { copy_hazard = "mushroombomb", by = { "um_tentacle_moon" }, delay = 60,
            delay_max = 180, lasting = true, moved = false, scale = 3 / 3.5 } or nil,
        -- (the haunt's hand (um_haunt.lua handfn): the Stage Usher's hand over again - test_for_damage_targets the same code, its
        -- STAGEUSHER_ATTACK_DAMAGERADIUS, its step time; never drawn, not a prefab the scan had (2026-10-30). TR_OLD_HAUNTHAND: none)
        um_haunt_attackhand = not rawget(_G, "TR_OLD_HAUNTHAND") and { copy_hazard = "stageusher_attackhand", by = { "um_haunt" } } or nil,
        -- (the acid mushrooms' toadling spawner (toadlingspawner.lua, acidmushrooms SpawnAt): Toadstool's mushroom bomb over again -
        -- the same Grow, land then grow1, grow2, explode_pre, bursting 40 on all within TOADSTOOL_MUSHROOMBOMB_RADIUS as its toadling
        -- comes out; never drawn (tools/gap_scan.lua, 2026-10-30). Its own "by": not Toadstool's - no Toadstool near, drawn as
        -- another's and left out. TR_OLD_TOADLINGBOMB: none)
        toadlingspawner = not rawget(_G, "TR_OLD_TOADLINGBOMB") and { copy_hazard = "mushroombomb", by = { "toadlingspawner" } } or nil,
        -- (the Eye of Terror's cursed fire: drawn as big as it is now (true_range/simmoves _live_radius, 4 times its size) - this
        -- only so it's among the things looked for; its shape here never drawn. TR_OLD_CURSEDFIRE: none)
        cursed_fire = not rawget(_G, "TR_OLD_CURSEDFIRE") and { copy_hazard = "magmafire", by = { "twinofterror2", "eyeofterror" }, lasting = true, effects = nil } or nil,
        lavaeslime = { by = { "lavae2" }, delay = 90, effects = "fire", lasting = true, moved = false, steps = { { at = 0, cells = "X21m2011h2A11f2E11d2I11c2K11b2M11a2O11Z2Q11Z2Q11Y2S11Y2S11X2U11X2U11X2U11X2U11X2U11W2W111X2U11X2U11X2U11X2U11X2U11Y2S11Y2S11Z2Q11Z2Q11a2O11b2M11c2K11d2I11f2E11h2A11m20" } } },
    },
}