-- Uncompromising Mode's moves (tools/sim_moves.lua SIM_MOD_SPEC): each a boss as tools/sim_moves.lua's
-- BOSSES lists them - a boss of the game's it changes in place of the game's.
-- (Deerclops: every one gets one of three mutations as it's made, at random - its own moves for
-- each, and its swipe the same in all (each throwing ice spikes ahead of it): run as the strong one.
-- setup: the mutation's own function, which the mod puts on it - postinit/prefabs/deerclops.lua)
-- (the Twins' and the Eye's shot, told from their charge by the chargepulse it makes at once (true_range/predict
-- sim.tell): kept here, not put into the data by hand - a rebuild dropped it, 2026-10-18)
local TELL = { tell = "eyeofterror_chargepulse" }
return {
    { prefab = "deerclops", sg = "SGdeerclops", states = {
        -- (gone into with no target - StrongAttackBank / EnrageAttackBank: GoToState("attack") - never
        -- turning to you as the game's own does till frame 16: swiped the way it faced as it began.
        -- But struck, its "hit" state's own ChooseAttack hands it you, past the mod's doattack: then it turns
        -- with you till 16, as the game's - the spikes 43 degrees off the shape on the bench, 2026-10-26.
        -- lock 16, drawn the way it faces: the same as 0 when it doesn't turn ; lock 16 alone made it "target" -
        -- aimed at you as it begins, the way it never turns with no target)
        { name = "attack", setup = "MakeStrong", noarg = true, lock = 16, frame = "facing" },
        -- (strong: an uppercut, and one after another)
        { name = "uppercut", setup = "MakeStrong" },
        { name = "uppercutcombo", setup = "MakeStrong" },
        -- (enraged - blue, 1.85 big: a laser)
        { name = "laserbeam_blue", setup = "MakeEnrageable" },
        -- (and its lasers swept all round itself, four rings out to 10 - its update adds to when it last
        -- attacked, none here: set)
        { name = "spinbeam_pre", setup = "MakeEnrageable", prep = function(boss) rawset(boss.components.combat, "laststartattacktime", 0) end },
        -- (icy: freezing all round, and a swipe putting down ice circles)
        -- (all it does as it begins - the ice circles, drawn on their own (_hazards), there 9 seconds:
        -- run a second and a half, not all of that)
        { name = "aurafreeze_pre", setup = "MakeIcey", frames = 45 },
        -- (its swipe the strong one's animation too - told apart by its build as it swipes, the
        -- old one: true_range/predict sim.look)
        { name = "aurattack", setup = "MakeIcey", look = "build_old" },
    } },
    -- (Crystal Deerclops: Deerclops' stategraph, so its mutations' states found in it too - never
    -- gone into, it has no mutation; the icy swipe the same animation as its own: the game's moves)
    { prefab = "mutateddeerclops", keep_game = true },
    -- (states the mod puts in that aren't tagged "attack", or that the scan didn't reach - each struck
    -- in a run of every state (COVERAGE): as well as the game's own listed ones)
    -- (Bee Queen: a stomp; a combo; its guards' mortar and shooters, called)
    -- (Shadow Wixie (SGshadow_wixie): a puzzle boss, gone into none of its strikes on its own - "nothing" in every state.
    -- charles_charge: running at you, 75 to all within 2.9 at 1, 8, 18 and 28 (Check_Bowling); slingshot_shoot: 50 to
    -- all within 4 at 15 (DamageNearbyEnemies) and seven wixie_shadow_shot fanned at you. Its "attack" only knocks back.
    -- prep: made by the puzzle, tagged puzzlespawn - one made without it removes itself the next frame (prefabs/shadow_wixie.lua:236))
    { prefab = "shadow_wixie", sg = "SGshadow_wixie", dummy_player = true, strikes_running = { "spearjab" }, add = {
        { name = "charles_charge", prep = function(boss) boss:AddTag("puzzlespawn") end },
        { name = "slingshot_shoot", prep = function(boss) boss:AddTag("puzzlespawn") end } } },
    -- (its shadow creatures that strike only those tagged player (dummy_player): the mindweaver's grab - 40 straight off the health
    -- of all within 3 as its grab ends (SGmindweaver.lua:41 Grabby); the fuelseeker's burst - 50 to all within 6 at 31)
    { prefab = "mindweaver", sg = "SGmindweaver", dummy_player = true, add = { "grab" } },
    { prefab = "fuelseeker", sg = "SGfuelseeker", dummy_player = true, add = { "burst" } },
    -- (the Ancient Trepidation's arms: a tentacle's lash (SGtrepidation_arm: atk_pre, then attack's atk_loop, DoAttack at 7,
    -- TENTACLE_ATTACK_DIST) - never found by the scan; drawn as the marsh tentacle's it was 7 frames late, its atk_pre 18
    -- frames to the tentacle's 25)
    { prefab = "ancient_trepidation_arm", sg = "SGtrepidation_arm", add = { "attack_pre", "attack" } },
    { prefab = "beequeen", sg = "SGbeequeen", add = { "stomp", "combo_prep", "stomp_combo", "lob", "defensive_spin" } },
    -- (moves Uncompromising Mode gives the game's monsters, gone into by its own code now and then: a
    -- Koalefant's stomp (its stompatk - stomp_pre is commented out). A Beefalo's / Koalefant's charge after its
    -- bite: its bite's own handler, and harmless - it bites again at its end. What strikes only through what
    -- it throws - Bearger's rock, the shock worm's bolts, the Ancient Guardian's belch, a fire / ice /
    -- lightning hound's shots: those things drawn (_hazards), not the move. Merm's karate: its stategraph
    -- post-init is commented out in Uncompromising Mode's list - never on)
    { prefab = "koalefant_summer", sg = "SGkoalefant", add = { "stomp" } },
    -- (the Shadow Bishop: its attack made over - off to 10-16 from you at a random side (a teleport), half a
    -- second turning to you, then straight on fast, striking 1.75 round itself every .15 s; again and again
    -- (level + 2). Each charge's lane drawn as one piece from where it went to - true_range/predict leg_whole.
    -- As long as it can go (leg_len): on at 16 / 14 / 13 a level, times its size (1, 1.6, 2.2: its motor's speed
    -- is in its own scaled frame), for the 35 frames left of its 50 - stopped only on you, so stepping aside
    -- it goes the whole way; the run here stops on you)
    { prefab = "shadow_bishop", sg = "SGshadow_bishop", states = {
        { name = "attack", frames = 150, extra = { leg_whole = true, leg_r = 1.75, leg_len = 18.7 } },
        -- (its reach grown with it: 1.75 x its size, 1.6 and 2.2 - shadowchesspieces.lua SetRange)
        -- (frames 150: two charges run, enough for its legs - all five, teleporting all over, the third
        -- level's run took 7 GB)
        { name = "attack", setup = "LevelUp", frames = 150, extra = { leg_whole = true, leg_r = 2.8, leg_len = 26.1 } },
        { name = "attack", setup = "LevelUp,LevelUp", frames = 150, extra = { leg_whole = true, leg_r = 3.85, leg_len = 33.4 } } } },
    -- (its hounds: the glacial hound's charged shots, the magma hound's fire, the spore hound's leap)
    -- (each only its own: the others' states in the same stategraph never gone into by it - their animations
    -- played for other things (scared) would draw them)
    -- (and each its plain bite, as a hound's: its own moves here, so the game's hound isn't looked to for it)
    { prefab = "lightninghound", sg = "SGhound", add = { "attack", "charging_pre" },
        no_auto = { "leap_attack_pre", "leap_attack", "ice_howl_attack", "burning_pre", "burning_pst", "burning_howl_attack", "quickbreath", "quickspike" } },
    -- (its ice howl only ever straight after its charge (UM SGhound.lua:192 - from scared_pst, 320 of 320) and again into
    -- itself up to twice (:269): told from its bite so - true_range/predict PickAlike, the twins agent 2026-10-19)
    -- (lock 5: each of its three shots aimed as it's shot (LaunchProjectile at frame 5 - GlacialProjectile lays its lane to where
    -- you were then), not after you on to the end - run with none found, its lane was drawn turning after you as you ran, the
    -- spikes laid where you'd been: "its three shots don't match", the player 2026-10-21)
    { prefab = "glacialhound", sg = "SGhound", add = { "attack", "charging_pre", { name = "ice_howl_attack", lock = 5, extra = { from = { "scared_pst" }, from_self = 2 } } },
        no_auto = { "leap_attack_pre", "leap_attack", "howl_attack", "burning_pre", "burning_pst", "burning_howl_attack", "quickbreath", "quickspike", "ice_howl_attack" } },
    { prefab = "magmahound", sg = "SGhound", add = { "attack", "burning_pre" },
        no_auto = { "leap_attack_pre", "leap_attack", "charging_pre", "charging_pst", "howl_attack", "ice_howl_attack", "quickbreath", "quickspike" } },
    { prefab = "sporehound", sg = "SGhound", add = { "attack", "leap_attack" },
        no_auto = { "leap_attack_pre", "charging_pre", "charging_pst", "howl_attack", "ice_howl_attack", "burning_pre", "burning_pst", "burning_howl_attack", "quickbreath", "quickspike" } },
    -- (Moose / Mother Goose: a storm of tornadoes; its super hop: faced to you as it begins, never turning
    -- after (facing) - how far, by how far you are as it takes off (hop_speed, frame 32): aimed on till then)
    { prefab = "moose", sg = "SGmoose", add = { "tornadostorm", { name = "hopatk", facing = true } }, no_auto = { "hopatk", "hopatk_loop", "landatk" } },
    { prefab = "mothergoose", sg = "SGmoose", add = { "tornadostorm", { name = "hopatk", facing = true } }, no_auto = { "hopatk", "hopatk_loop", "landatk" } },
    -- (the Eye of Terror and the Twins: a laser)
    { prefab = "eyeofterror", sg = "SGeyeofterror", add = { { name = "shoot_pre", extra = TELL }, "shoot_attack", { name = "shoot_pre", mem = { transformed = true }, extra = TELL } } },
    { prefab = "twinofterror1", sg = "SGeyeofterror", add = { { name = "shoot_pre", extra = TELL }, "shoot_attack", { name = "shoot_pre", mem = { transformed = true }, extra = TELL } } },
    { prefab = "twinofterror2", sg = "SGeyeofterror", add = { { name = "shoot_pre", extra = TELL }, "shoot_attack", { name = "shoot_pre", mem = { transformed = true }, extra = TELL } } },
    -- (Uncompromising Mode's own guards of its bee queens - the game's beeguard's stategraph, their reach their own (1.5
    -- times a plain guard's for some, prefabs/um_beeguards.lua :308/:346): struck you 171/142/13 times on the bench with no
    -- entry at all, never drawn - tools/nothing_check.lua, 2026-10-20)
    { prefab = "um_beeguard_blocker", sg = "SGbeeguard", add = { "attack", "flydown" } },
    { prefab = "um_beeguard_seeker", sg = "SGbeeguard", add = { "attack", "flydown" } },
    { prefab = "um_beeguard_shooter", sg = "SGbeeguard", add = { "attack", "flydown" } },
    -- (monsters of its own with no entry at all, found by tools/combat_census.lua and benched: struck the stand-in with
    -- nothing drawn - the viper worm 392, the junk rat 121 (attack, atk), the shadow Wortox 5 (its jump out of a portal),
    -- 2026-10-20)
    { prefab = "viperworm", sg = "SGworm", add = { "attack" } },
    { prefab = "uncompromising_junkrat", sg = "SGuncompromising_junkrat", add = { "attack" } },
    { prefab = "um_shadow_wortox", sg = "SGum_shadow_characters", add = { "wortox_attack_jumpout" } },
    -- (spiders: the moon spider's spikes)
    -- (and the plain spider's leap - "alljumperspiders": its doattack goes to warrior_attack whenever you're out of its
    -- bite (postinit/stategraphs/SGspider.lua:73-76, tag spider_regular: the plain spider alone, postinit/prefabs/
    -- spider.lua:295) - the spider warrior's leap; not in its data at all, never drawn - the player, 2026-10-20)
    { prefab = "spider", sg = "SGspider", add = { "spike_attack", "warrior_attack" } },
    -- (the Knook: its bite ("attack", animation atk) - gone into from its hop too, not only after atk_pre:
    -- not found so, never drawn - 118 struck within 1-3, nothing near; VERIFY_PLAN 6.0a)
    -- (its bite with its wind-up too, as found before: add takes the place of what's found)
    -- (its wind-up into its bite, as it goes 65 times in 100 (SGknook atk_pre animover: math.random() > 0.35 - "attack", else
    -- its hop): run as it fell, its wind-up was its hop - a hop's lane drawn 0.9 s and it bit where it stood, "it hops slowly,
    -- then bites - its hitbox doesn't match", the player 2026-10-21. Its hops drawn as their own (bigjump))
    { prefab = "knook", sg = "SGknook", add = { { name = "attack_pre", prep = function()
        local r = math.random
        math.random = function(a, b)
            if a == nil and b == nil then math.random = r return .9 end
            return r(a, b)
        end
    end }, "attack" } },
    -- (Wickerbottom's tentacle: a tentacle's lashing, on and on while you stand there (SGtentacle attack ->
    -- attack) - each go its own, as the game's tentacle; found alone only its first: 205 struck undrawn)
    { prefab = "wicker_tentacle", sg = "SGtentacle", add = { "attack_pre", "attack" } },
    -- (Moonmaw Dragonfly: its taunt strikes, falling from the sky, its shards, its lavae)
    { prefab = "moonmaw_dragonfly", sg = "SGmoonmaw_dragonfly", add = { "attack", "spit", "taunt_pre", "skyfall", "summoncrystals",
        -- (its lavae and shards circling it, made as it's made in the game - none here: an empty ring)
        -- (its lavae spinning round it, each striking 2.2 round itself every .15 s while it spins
        -- (moonmaw_lavae.lua destroystuff, by middles): not made here - struck as they would, round it,
        -- while it plays its spin. 4 off, not the 3 it sets: its linearcircler only ever goes out, and
        -- they're 4 off from the first (limit 4 between its attacks) - struck at 6 in the game, never
        -- nearer than 1.8. Spinning 3 times a second - 8 of them, each strike 27 degrees on.
        -- Its shards spin the same animation - never seen used: left out)
        { name = "lavaeattack_pre", fields = { lavae = {} }, prep = function(boss)
            local k = 0
            -- (drawn whole, out to 6.2 - the ring's hole, 1.8 round its middle, is inside its own body (2.5
            -- round): no one stands there, and a ring round it read as something else)
            boss:DoPeriodicTask(.15, function(b)
                if b.anim ~= "spin" then return end
                k = k + 1
                b.components.combat:DoAreaAttack(b, 6.2)
            end)
        end } }, no_auto = { "shards_pre", "shards" } },
    -- (Hooded Widow: its plain bite - gone into from others too, so not found; its web mortar - not the
    -- old web shot, the same animations, it never uses)
    -- (its leap at you: the same animations as its leaps to a tree and at its prey - once it faces off
    -- you after it stops aiming, one of those: abort_turn)
    -- (and its charge: running at you, turning after you; once you're in front, within 6, a swipe on the run
    -- (charge_strike) - half round its front, 3 all round: ChargeAttacked. The swipe drawn as it begins)
    -- (not its "fall" on its own: the same animation as its canopyland, "fall" then "taunt" - never told apart, both drawn at
    -- once (BOTHDRAWN 40 / 294 forced, 2026-10-19); its shape all inside canopyland's ground pound (829 of 829 cells), 2
    -- frames sooner - canopyland's alone draws every blow of both: missed and drawn-in-unstruck the same, two shapes 0)
    -- (chargeattack: frames 23 - one go of charge_strike (23 frames, its blow at 12); run on, it went round again and again, its later
-- blows (36, 60, 84) laid ahead along its way - in the game each go of it begins anew, those drawn trailing after her, two and
-- three shapes chasing each other, "wrong, turning to and fro", the player 2026-10-21)
{ prefab = "hoodedwidow", sg = "SGhoodedwidow", drop = { "fall" }, add = { "attack", "lobprojectile", { name = "preleapattack", abort_turn = 60 }, { name = "chargeattack", frames = 23, extra = { leg = false } } },
        no_auto = { "launchprojectile", "tossplayer", "preleapattack", "leaptotree_shake_pre", "leaptoprey_pre" } },
    -- (Wilting Dragonfly: its plain bite, its spit, its flames, its dash)
    -- (its plain bite only once on fire - flame_on, fire_build - else it taunts; its pre_shoot goes on to no state)
    -- (its taunt strikes round it - gone into straight from its bite, not by its taunt_pre: one of its own)
    -- (its dash: running on, striking at frames 5, 25, 45 of each leg (DoAttack()) - its target, or, out of
    -- its reach, all 6 round itself (its area damage, on a miss): tools/sim_moves.lua's DoAttack)
    { prefab = "mock_dragonfly", sg = "SGmock_dragonfly", add = { { name = "attack", fields = { flame_on = true, fire_build = true } }, "spit", "flamethrower", "taunt",
        -- (its dash's lane drawn as one piece - true_range/predict leg_whole)
        -- (from its fire_on warning - charge_warning, the only way into spin_pre (SGmock_dragonfly :775): run from spin_pre,
        -- its first animation dash_pre, nothing drawn through fire_on - tools/nomove_check.lua, 14274 frames, 2026-10-20)
        -- (wait_anim: drawn only from its dash_pre - it turns to you anew there (spin_pre ForceFacePoint); through fire_on it
        -- was aimed at where you'd been, "up before it should be", the player 2026-10-21)
        { name = "charge_warning", extra = { leg_whole = true, leg_r = 6, wait_anim = "dash_pre" } } },
        no_auto = { "pre_shoot" } },
    -- (its fire breath: how many breaths, counted by its brain - set)
    { prefab = "um_pepperdragon", sg = "SGum_pepperdragon", add = { { name = "flame", fields = { flamecount = 0, flamecount_total = 2 } } } },
    -- (its punches - attack1/2/3, in "offense" (struck >100 in 2 s, or no target): SGuncompromising_buffrat.lua:16-24)
    -- (and its leap from its guard: "bellyflop_block_pre", not bellyflop_pre - its mode then "defence"
    -- (SGuncompromising_buffrat.lua:476-480), struck from its guard (:450-451): 11 of 11 of its leap's blows undrawn,
    -- 2026-10-20)
    { prefab = "uncompromising_buffrat", sg = "SGuncompromising_buffrat", add = { "leap_attack", { name = "leap_attack", fields = { mode = "defence" } }, "attack1", "attack2", "attack3" } },
    -- (a mosquito too full bursting - toofat - striking round itself at frame 11)
    { prefab = "mosquito", sg = "SGmosquito", add = { { name = "splat", fields = { toofat = true } } } },
    -- (Bee Queen's seeker guards: stabbing down and dying, striking 2 round at frame 3)
    { prefab = "um_beeguard_seeker", sg = "SGbeeguard", add = { "stab" } },
    -- (Moonmaw's lavae: its stab, and its fall when killed in the air (death: drop, frame 11 DoAreaAttack 2 round it))
    { prefab = "moonmaw_lavae", sg = "SGmoonmaw_lavae", add = { "attack", "death" } },
    { prefab = "um_shadow_wes", sg = "SGum_shadow_characters", add = { "wes_attack" } },
    -- things struck by their own code, not a state - as STRIKERS in tools/sim_moves.lua (radius: as far as it
    -- reaches less your body's .5 - FindEntities goes by your middle)
    -- (Hooded Widow's web mortar: lobbed at you, pinning whoever's within 1.5 of where it lands - no harm)
    { striker = { prefab = "web_mortar", radius = 1, delay = 0, moved = true, effects = "pinned", by = { "hoodedwidow" } } },
    -- (a shadow on the ground where something comes down: Bee Queen's guards called up as mortars, each
    -- stabbing 2 round where it lands - its shadow sliding after you (4 a second) and the guard on it;
    -- spiders' and the Hooded Widow's web, guano, debris falling the same)
    -- (Shadow Wixie's shot: 50 to all within 0.9 of it, looked for again and again the whole way (CollisionCheck,
    -- shadow_wixie.lua) - a ring round it as it flies, as the bullet bees' stinger. Run from her, it came out a way
    -- 60 parts long (a part a frame): her taunt's ring of 48 laid 18,250 pieces in one frame and the game crashed,
    -- lag 2026-10-30_2054)
    { striker = { prefab = "wixie_shadow_shot", radius = 0.9, delay = 0, moved = true, lasting = true, as_boss = true, strikes_until = 60, by = { "shadow_wixie" } } },
    { striker = { prefab = "warningshadow", radius = 1.5, delay = 0, moved = true, lasting = true, by = { "beequeen", "beeguard", "um_beeguard_seeker" } } },
    -- (the Ancient Guardian's belch: 16 goo thrown at you, each 4 off at random (postinit/prefabs/minotaur.lua
    -- ShootProjectile :49-69), striking within 1.5 of where it comes down (shadow_goo.lua:75, :89-93). No run
    -- sees it - they land out past the dummies ("belch: nothing", player_hits 12); its searches on the way for its
    -- own goo trail were taken for strikes instead, rings 4 round its way and nothing where it lands: 32 of 32 of
    -- its blows undrawn on the testbench, the player saw it, 2026-10-19 (tools/goo_check.lua: struck 0.02-1.57 off)
    -- (lands: struck only by its onhit as it comes down (complexprojectile SetOnHit, :197) - not drawn sitting 2-3
    -- ticks in the Guardian's mouth before it flies, nor its first frame up: a ring there, gone, then where it
    -- lands - 257 blinks on the testbench. A rule for every moved thing hid Bearger's boulders, struck as they're
    -- made: 5 -> 50 missed - so said only of one that only lands)
    { striker = { prefab = "guardian_goo", radius = 1, delay = 0, moved = true, lands = true, by = { "minotaur" } } },
    -- (Moonmaw's shards thrown at you: struck within sqrt(3) as they fly - drawn where each is)
    { striker = { prefab = "moonmaw_glassshards", radius = 1.25, delay = 0, moved = true, by = { "moonmaw_dragonfly" } } },
    -- (Moonmaw's crystals called down all round you: each striking 3 round where it lands, 32 frames after it
    -- shows - true_range/simmoves _on_anims: drawn only once it does)
    { striker = { prefab = "moonmaw_trapprojectile", radius = 2.5, delay = 32, by = { "moonmaw_dragonfly" } } },
    -- (Walrus' bear traps thrown down: springing on whoever's within 1.95 (TRAP_TEETH_RADIUS x 1.3, its mine))
    { striker = { prefab = "um_bear_trap", radius = 1.45, delay = 0, lasting = true, by = { "walrus" } } },
    -- (Spider Queen's web bomb: lobbed, striking and pinning whoever's within 4 of where it lands, as a spat's)
    { striker = { prefab = "queen_web_bomb", radius = 3.5, delay = 0, moved = true, by = { "spiderqueen" } } },
    -- (Crab King's geysers: striking 2 round each as it bursts)
    { striker = { prefab = "crabking_geyser_single", radius = 1.5, delay = 0, lasting = true, by = { "crabking" } } },
    -- (an Ice Hound's ice spikes: 0.8 and 1.0 round each - knocking back)
    -- (its blow put down to the hound (glacialhound_icespike.lua:112 GetAttacked(attacker)), as it appears
    -- (DoTaskInTime(0, DoDamage) :399): as_boss - its "quickspike" 458 struck undrawn as the hound's own,
    -- the testbench 2026-10-17; VERIFY_PLAN 6.0a)
    { striker = { prefab = "glacialhound_icespike", radius = 1.3, delay = 0, by = { "icehound", "glacialhound" }, as_boss = true, strikes_until = 3 } },
    -- (fire left burning by a Fire Hound's and the Wilting Dragonfly's fireballs: 1.5 round, all the while)
    { striker = { prefab = "magmafire", radius = 1, delay = 0, lasting = true, by = { "firehound", "mock_dragonfly" } } },
    -- (fire breathed by a fire hound (its short spit) and a magma hound: flames flying on at 16 and 20, each
    -- burning all within 2 x its size (.8-.9 once grown) every frame - BurnSurroundings: drawn where each is)
    { striker = { prefab = "um_fire_projectile", radius = 1.2, delay = 0, moved = true, lasting = true, effects = "fire", by = { "firehound", "magmahound" } } },
    -- (the Wilting Dragonfly's fireballs thrown: bursting 3 round where they land)
    -- (the Bee Queen's shooter bees' stingers: thrown straight at her chosen target, 25 a second, not homing, for up to
    -- 5 s - striking whoever with a combat comes within sqrt(2) of its middle as it flies (um_beestinger_projectile.lua
    -- PhysTest, FindEntity by middles: 1.41 less your body's .5) - drawn round each where it is, all along)
    -- (and the shooter guard's - it shoots them too (prefabs/um_beeguards.lua Shoot): its stingers' hits taken for its own
    -- blows, 27 "missed" on the bench, 2026-10-20)
    { striker = { prefab = "um_beestinger_projectile", radius = 0.91, delay = 0, moved = true, lasting = true, by = { "beequeen", "um_beeguard_shooter" } } },
    { striker = { prefab = "fireball_throwable", radius = 2.5, delay = 0, moved = true, by = { "mock_dragonfly" } } },
    -- (shadow creatures' goo lobbed: 1.5 round where it lands)
    { striker = { prefab = "shadow_goo", radius = 1, delay = 0, moved = true, by = { "crawlinghorror", "terrorbeak" } } },
    -- (a Treeguard's root spikes coming up: 0.7 round each)
    { striker = { prefab = "rootspike", radius = 0.2, delay = 0, by = { "leif", "leif_sparse" } } },
    -- (the Creeping Fear's spike waves: every 20 s, off its own timer (DoPeriodicTask, not a state - creepingfear.lua
    -- :88-118), three lines of spikes at you a second apart, one every 2 along, one a frame; each strikes 1.5 round
    -- itself (FindEntities, middles) .6 s after it shows (:67-73) - its blow the Fear's own (GetAttacked(inst)): as_boss)
    { striker = { prefab = "uncompromising_shadow_projectile1_fx_fast", radius = 1, delay = 18, by = { "creepingfear" }, as_boss = true, strikes_until = 18 } },
    -- (the Eye of Terror's shot (UM SGeyeofterror.lua ShootEye): a mini eye flown at you at 15 (eyeofterror_extras.lua
    -- :403), its body a 1.5 capsule colliding with characters (:371-374) - struck as it touches you (GetAttacked 30,
    -- :320): drawn where each is; 1.75 - the testbench's blows up to 2.21 off it, median 1.93)
    { striker = { prefab = "eyeofterror_minieye_projectile", radius = 1.75, delay = 0, moved = true, by = { "eyeofterror" } } },
    -- (Spazmatism's shot (ShootProjectile): fireballs lobbed at you (+-1), on landing health:DoDelta(-5) to all
    -- _combat within 4 (eyeofterror_extras.lua:6-23) - no blow, a hurt: tr_hurt)
    { striker = { prefab = "eyeofterror_fireball", radius = 3.5, delay = 0, moved = true, by = { "twinofterror2" } } },
    -- (and half of them leave cursed fire (:31-33): burning all within 4 x its size every .5 s from .5 s on
    -- (:107-136, :183), shrinking away over 5 s (:143))
    { striker = { prefab = "cursed_fire", radius = 3.5, delay = 15, lasting = true, by = { "twinofterror2" } } },
    -- (Uncompromising Mode's lava sinkhole: as the Antlion's, its reach 2.5 + 1/1.5 (3.17, middles - antlion_sinkhole_lava.lua:116),
    -- three blows a second apart from as it appears; who sets it off not found)
    { striker = { prefab = "antlion_sinkhole_lava", radius = 2.67, delay = 0, again = { 30, 60 } } },
    -- (the Snapping Turtles: their spin ends (speen_pst, tagged only "busy") with a bite at its frame 16 -
    -- DoAttack, range 2 round itself (SGsnapperturtle.lua:217). Gone into by a timer whose listener the
    -- game adds in "attack"/"hit" (:92), or its target lost - never in a run of spin_pre here: its own
    -- move. Its timer component made by the spin before it: made here. The bite and the spin too, as
    -- the scan found them - add lists all of one not in BOSSES)
    { prefab = "snapperturtle", sg = "SGsnapperturtle", add = { "attack", "speen_pre",
        { name = "speen_pst", prep = function(boss) boss:AddComponent("timer") end } } },
    { prefab = "snapperturtlebaby", sg = "SGsnapperturtle", add = { "attack", "speen_pre",
        { name = "speen_pst", prep = function(boss) boss:AddComponent("timer") end } } },
    -- (Wes's shadow balloons: drift to you, pop once a player's within 3 (checked every .5 s), striking 2 round
    -- themselves .07-.36 s on (um_shadow_characters.lua:737-773) - any moment it's near: drawn all along)
    { striker = { prefab = "um_shadow_balloon", radius = 1.5, delay = 0, lasting = true, by = { "um_shadow_wes" } } },
}
