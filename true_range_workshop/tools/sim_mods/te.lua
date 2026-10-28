-- Tropical Experience's moves (tools/sim_moves.lua SIM_MOD_SPEC): each a boss as tools/sim_moves.lua's
-- BOSSES lists them - one of the game's it changes, in place of the game's; its own monsters are found by
-- AutoBosses in its scripts laid over the game's (tools/mod_scripts.ps1 -Name te). Begun empty, 2026-10-20:
-- what the run can't find or drive, added here as it's found.
local list = {
    -- (the Thunderbird: lightning brought down on whom its brain picked (inst.lightning_target, thunderbirdbrain) as it
    -- shoots - none here: its target)
    { prefab = "thunderbird", sg = "SGthunderbird", states = {
        { name = "thunder_attack", prep = function(boss, target) rawset(boss, "lightning_target", target) end },
    } },
}
-- (the sea Rook: the game's Rook's charge on water (SGrookwater: run_start pawing, run on atk, runningattack as it
-- reaches you) - found on its own, its charge's parts each a "move", nothing struck: run as the Rook's is, its brain
-- saying how far - no atk_collide of its own)
list[#list + 1] = { prefab = "rookwater", sg = "SGrookwater", also = { "rookwaterfixo" }, no_auto = { "run_start", "run", "runningattack" }, states = {
    { name = "run_start", ram = { dist = 25, time = 5, aim = 1, lock = 15, front = true, anims = { "atk_pre", "paw_loop", "atk" } } },
} }
-- (the Roc's head: it grabs whom its body (inst.controller, roc_controller) is after - struck, 50, within sqrt(2) of the
-- head, and carried off to its nest (SGroc_head DoGrab): its body, a stand-in after you)
list[#list + 1] = { prefab = "roc_head", sg = "SGroc_head", states = {
    { name = "grab", prep = function(boss, target)
        rawset(boss, "controller", setmetatable({ target = target, EatSomething = function() end }, { __index = function() return function() end end }))
    end },
} }
-- (the Ant Queen's leap: the room quakes ("queenattack", quaker_interior ForceQuake - 15-20 a second for 4-8 s), debris
-- falling at random, each with its shadow (warningshadow) and striking within 2 of where it lands (grounddetection, your
-- middle: 1.5 and your body) - nothing of her own strikes; drawn by each shadow, hers as the Bee Queen's guards' are)
-- (and the jungle treeguard's snakes, thrown (thrower: jungletreeguard_snake) - each its warningshadow where it'll land, striking
-- within 1.5 of it there, put down to the treeguard (GetAttacked(thrower)): as_boss - 6 "missed" in its throw, the stress bench
-- 2026-10-21)
list[#list + 1] = { striker = { prefab = "warningshadow", radius = 1.5, delay = 0, moved = true, lasting = true, by = { "antqueen", "jungletreeguard", "treeguard" },
    as_boss = true, strikes_until = 60 } }
-- (the harmful states the run never went into on its own - tools/mod_coverage.lua over Tropical Experience's stategraphs,
-- the user: "still missing a huge number of moves", 2026-10-20: added to what each was found with - and that one again where it
-- starts a combo of the added: taken for its wind-up, dropped (beetletaur, the twisters, hulk, herald: their attack))
-- (the Boarrior's attack: attack1 or attack3, its uppercut, at random (math.random(1, 2) in its onenter) - the run went the
-- first way only: 9 of its 16 blows undrawn in the player's game, all uppercuts, 2026-10-21. Run once more, that roll made 2 -
-- once: math.random as it was again at once)
local function Uppercut()
    local r = math.random
    math.random = function(a, b)
        if a == 1 and b == 2 then math.random = r return 2 end
        return r(a, b)
    end
end
for _, a in ipairs({
    { "beetletaur", "SGbeetletaur", { "attack", "attack_combo_right_hook", "attack_combo_left_hook", "uppercut", "body_slam" } },
    { "bossboarte", "SGbossboarte", { "groundslam", { name = "dash", no_follow = true }, "attack", { name = "attack", prep = Uppercut } } },
    { "bossboar", "SGbossboarte", { "groundslam", { name = "dash", no_follow = true }, "attack", { name = "attack", prep = Uppercut } } },
    { "firetwister", "SGfiretwister", { "attack", "waves_antic_pre" } },
    { "twister", "SGtwister", { "attack", "waves_antic_pre" } },
    { "ice_deer", "SGdeer", { "magic_pre" } },
    { "goddess_deer", "SGdeer", { "magic_pre" } },
    { "goddess_deer_gem", "SGggdeer", { "magic_pre" } },
    { "gnarwailunderwater", "SGgnarwailunderwater", { "boat_attack", "body_slam_pre" } },
    { "primeape", "SGmonkey", { "throw" } },
    { "goldmonkey", "SGmonkey", { "throw" } },
    { "tikiman", "SGmonkey", { "throw" } },
    { "spider_ape", "SGmonkey", { "throw" } },
    { "ancient_herald", "SGancientherald", { "attack", "summon" } },
    { "hippopotamoose", "SGhippopotamoose", { "submerge" } },
    { "weevole", "SGweevole", { "attack" } },
}) do
    list[#list + 1] = { prefab = a[1], sg = a[2], add = a[3] }
end
-- (the Ancient Hulk: its attack and its mines as above; not its spin - a laser swept round it 7 out, 45 degrees at a time
-- (DoDamage over 8 sectors, frames 37-50 of atk_circle): run here each sector's laserhit made on every dummy, past 20
-- minutes - drawn instead by modmain AGGRO_WHILE, a faint ring 7 round it as it plays atk_circle, 2026-10-20)
-- (and its lob (atk_lob): an orb shot at you at frame 30 (ShootProjectile, 60 a second), DoDamage 3.5 round where it lands
-- 0.3 s on (OnHitOrb) - its harm in the orb's own code, so not found by its words; no warning drawn, the player 2026-10-21)
list[#list + 1] = { prefab = "ancient_hulk", sg = "SGancient_hulk", add = { "attack", "bomb", { name = "lob", all_hits = true } }, no_auto = { "spin" } }
-- (the Pugalisk's head: its bite as above; not its ground pounds - as it comes up (emerge_taunt, frame 1) and as it backs into
-- the ground and comes up again 0.75 s on (backup -> underground -> emerge: pugalisk_util findsafelocation first) - 2 rings
-- (groundpounder: 1 and 5 out, 3 wide - 8 from your middle): run here they hung past 20 minutes (its body's helpers), the
-- whole build stopped, 2026-10-20 - drawn instead by modmain AGGRO_WHILE. Its body, tail and segments run the same
-- stategraph: the same)
for _, p in ipairs({ "pugalisk", "pugalisk_body", "pugalisk_tail", "pugalisk_segment", "pugalisk_corpse" }) do
    list[#list + 1] = { prefab = p, sg = "SGpugalisk_head", add = { "attack" }, no_auto = { "emerge_taunt", "backup" } }
end
-- (the turtle's slide: at whoever's nearest, up to 25 a second and back down over 2 s, up to 5 slides one after another,
-- each aimed anew - striking all within 3 every 0.1 s (SlideTask, SLIDE_RADIUS): run here as one move it was drawn where it
-- wasn't (63 glitches) and missed 90 of 270 - drawn instead as the Pengull's slide, a ring round it all the while it slides
-- (modmain AGGRO_WHILE), 2026-10-20)
list[#list + 1] = { prefab = "spiky_turtle_tfc", sg = "SGspikyturtle_tfc", add = {}, no_auto = { "slide_pre", "slide" } }
-- (the Rhinocebros' charge (SGrhinodrill charge / charge_loop): turns after you every frame (CHARGE_MAX_ROTATION), again and
-- again till it strikes you (DoAttack, 4.5, frame 15 of each loop) - no straight way to draw: 5 of 7 blows undrawn, the
-- player 2026-10-21. Drawn instead by modmain AGGRO_WHILE, round it as it charges)
for _, p in ipairs({ "rhinodrill", "rhinodrill2" }) do
    list[#list + 1] = { prefab = p, sg = "SGrhinodrill", add = {}, no_auto = { "charge", "charge_loop" } }
end
-- (the mammoth: the game's koalefant reskinned - its bank, its body (100, 0.75), its damage, its stategraph (mammoth.lua):
-- drawn as the koalefant (tools/mod_diff.lua alias_of) - with Uncompromising Mode on, that mod's charge and stomp
-- (postinit/stategraphs/SGkoalefant.lua) are the mammoth's too: 40 of its blows undrawn on the bench, 2026-10-20)
list[#list + 1] = { prefab = "mammoth", alias_of = "koalefant_summer" }
-- (the spiky monkey's attack: its slam (attack1, SlamAttack) once SLAM_RECHARGE has passed since its last (lastTimeSlam), else a
-- swipe (attack2) - the run, its slam never due, had only the swipe: 78 of its blows undrawn on the bench, 2026-10-20. Run
-- both: the slam with its last one long ago. The yeti runs the same stategraph)
for _, p in ipairs({ "spiky_monkey_tfc", "yeti" }) do
    list[#list + 1] = { prefab = p, sg = "SGspikymonkey_tfc", states = {
        "attack",
        { name = "attack", prep = function(boss) rawset(boss, "lastTimeSlam", -1000) end },
    } }
end
-- (Maxwell (maxwellboss, from his statue): no stategraph - each time he moves on (Teletransporte, timers) his magic
-- attack: meteors (maxwellshadowmeteor) dropped anywhere within 15 of him, each its warning shadow 1 s then crashing,
-- striking at 0.33 s on within its size x 3.5 (METEOR_RADIUS; sizes 0.7/1/1.3 at random) - the largest's, 4.55 (4.05
-- and your body): drawn whole; and lightning, struck by the weather where it likes - not drawn here. The user asked
-- for both, 2026-10-20: no stategraph, so neither the census nor tools/mod_coverage.lua saw him)
list[#list + 1] = { striker = { prefab = "maxwellshadowmeteor", radius = 4.05, delay = 40, moved = false, by = { "maxwellboss" } } }
-- (no stategraph, each struck by its own code - tools/mod_coverage.lua's NO STATEGRAPH list, 2026-10-20:)
-- (the volcano's fire rain and the dragoon eggs coming down: shown by their shadow (firerainshadow), hidden, then a ground
-- pound where they land - its one damage ring 1 out, striking within ringWidth 3 of each point (groundpounder, middles:
-- 4 - 3.5 and your body), at VOLCANO_FIRERAIN_WARNING 2 s less 5 frames (fire rain) or 7 (an egg), setting fire)
list[#list + 1] = { striker = { prefab = "firerain", radius = 3.5, delay = 55, moved = false } }
list[#list + 1] = { striker = { prefab = "dragoonegg_falling", radius = 3.5, delay = 53, moved = false } }
-- (the dragoon's spit (LAVASPIT, actions.lua): a puddle of lava 1.7 before it (dragoonspit.lua), burning whoever's middle comes
-- within 2 (MakeSmallPropagator damagerange 2, damages; heat 24 a second) while it spreads - 3 s, then cooling ("cool", its
-- propagator gone as that ends): "the dragoon's spit has no fire hitbox", the player 2026-10-21. Middles: 1.5 and your body.
-- Not drawn once it cools - true_range/simmoves _off_anims)
list[#list + 1] = { striker = { prefab = "dragoonspit", radius = 1.5, delay = 0, lasting = true, effects = "fire", by = { "dragoon" } } }
-- (the palm treeguard's coconuts and snakes thrown from the jungle treeguard: lobbed, each with its shadow, striking within
-- 1.5 of where it comes down (middles: 1 and your body) - drawn where it'll land)
-- (their blows the game's as the treeguard's (its weapon's projectile, DoAttack): as_boss, landed within strikes_until frames of
-- appearing - 6 "missed" in the throw, 4-10 off, the stress bench 2026-10-21)
-- (the Quacken's spit (throw): 30 things lobbed at once (OnAttack: kraken_projectile x10 round its target, x20 anywhere within
-- 24), no shadow to show where (warningshadow left out in kraken_projectile.lua) - run, one great blob of where they may fall,
-- telling nothing: "throwing creatures shouldn't have a hitbox", the player 2026-10-21. Not drawn)
list[#list + 1] = { prefab = "kraken", sg = "SGkraken", add = {}, no_auto = { "throw" } }
list[#list + 1] = { prefab = "krakenunderwater", sg = "SGkrakenunderwater", add = {}, no_auto = { "throw" } }
-- (not drawn in flight any more: each one's warningshadow, put down where it'll land as it's thrown, is drawn already - the
-- palm treeguard's coconut drawn twice, "only the small one strikes", the player 2026-10-21: the one in the air strikes
-- nothing on its way, only as it comes down - on its shadow)
-- (the Tiger Shark's leap on land: up out of sight, then above whom it's after (fallwarn: moved there, its shadow put down under
-- it - tigersharkshadow), down 34 frames on, landing in a ground pound of 3 rings (groundpounder damageRings 3: 1, 5, 9 out, 3
-- wide - 12 from your middle) - its move drawn where it leapt from, not where it lands: 25 of its blows undrawn in the stress
-- bench, 2026-10-21 (fallwarn 34 frames, falling 34, struck 5 on). Drawn round its shadow, its blows the shark's own: as_boss)
-- (4.2, not 11.5: Tropical Experience's groundpounder is point mode (no UseRingMode in tigershark.lua) - each ring's blow a
-- DoAttack within its hit range, 4 (SetRange(4, 4)) and your body, whatever the rings reach: the bench's 540 blows all within
-- 4.67, 2.9 on average - drawn 11.5, "not right", the player 2026-10-21. Middles: 4.2 and your body)
-- (its shadow not drawn now: high up, the shark drifts on after you (.2 a frame) and lands up to 4.3 from it - two rings,
-- "the shadow and where it really falls", the player 2026-10-21. Drawn round the shark itself instead, from the moment it's
-- moved above you: true_range modmain AGGRO_WHILE tigershark, jump)
-- (the jungle treeguard: its swing only once a snake of its is within 17 (SGjungletreeguard onattack) - melee then (SetMelee: range 3,
-- 150) ; run as it's made, in its throwing mode (range 20, damage 0), its swing struck you 10 off and was drawn so, never landing,
-- "its moves all mixed up", the player 2026-10-21: run in melee. Its pluck and throw (damage 0, the snake thrown on its hit - the
-- snake's warningshadow drawn where it lands): no move of its own - drawn as a blow on you it wasn't, the player: "should only
-- warn")
-- (the slip's leap (warrior_attack: SetMotorVelOverride(20) frames 8-20, its bite at 19): run, it flies 8 - in the game it creeps
-- some 1.1 in that time (the player's traces 2026-10-21: 154.37-155.03, 150.77-151.4, ~3 a second), its bite where it stands:
-- an 8-long lane drawn and never struck, "what's it for", the player. Run kept where it began, as its bite)
list[#list + 1] = { prefab = "slip", sg = "SGslip", add = { { name = "warrior_attack", still = true } } }
-- (the spider warrior: Tropical Experience changes none of it - only swaps it for a tropical spider 0.5 s on where the ground
-- is jungle, magma, ash... (modmain.lua spider_warrior), the run's ground among them: removed mid-leap at frame 15, its leap
-- 5.2 long for its 8, kept as the mod's - drawn short, 4 of its bites missed on the bench, 2026-10-22. The game's)
list[#list + 1] = { prefab = "spider_warrior", keep_game = true }
-- (the green tentacle's bites up close (attack: atk_loop, struck at 7 and 17), over and over while you're near - gone into
-- straight, not through attack_pre once it's up: found only as attack_pre's run, its bites were drawn as that run long
-- over, 361 struck undrawn on the bench once its shot no longer drew a ring 20 round it, 2026-10-22. Not its shot from afar
-- (attack_range, on atk_idle as its pauses are): its spike drawn as it flies, DARTS)
list[#list + 1] = { prefab = "greententacle", sg = "SGgreententacle", add = { "attack_pre", "attack" } }
-- (the summer walrus: MacTusk's, its blowdart in its hands 1 s after it's made (EquipBlowdart) - as by the time it fights; struck
-- from 15 off with none yet, a dark ring 15.6 round it (BIGDARK), 2026-10-22)
-- (the octopus: its attack on run_loop, the very animation it idles and swims on (SGoctopus) - its shot drawn as a move, a dark ring
-- 15 round it the whole while it idled (BIGDARK). Not a move: its ink (octoatt) homing on whom it's after, 15 a second, striking
-- within 1.5 of them - drawn round itself as it comes, its blow the octopus's (as_boss), 2026-10-22)
-- (the knight boat's cannonballs: its attack harms no one (damage 0) - on it, 1-3 lobbed at you, each 4 off at random, striking
-- all within 1.5 of where it comes down (knightboat_cannonshot.lua KNIGHTBOAT_RADIUS; middles: 1 and your body): drawn where they
-- fall, the boat's blows (as_boss) - 71 of them undrawn once its attack was no longer a dark ring 23 round it, 2026-10-22)
list[#list + 1] = { striker = { prefab = "knightboat_cannonshot", radius = 1.0, delay = 0, moved = true, by = { "knightboat" }, as_boss = true, strikes_until = 90 } }
list[#list + 1] = { prefab = "octopus", sg = "SGoctopus", add = {}, no_auto = { "attack" } }
-- (the yellow lizardman's zap (gw_yellow_lizardman, spit_attack): its electric weapon striking whom it's after at frame 15, no
-- shot, anywhere within 16 + 4 - a dark ring 20 round it, cut square by the data's grid (20 each way): "very wide, and not even
-- round", the player 2026-10-22. Drawn instead by modmain AGGRO_WHILE: a mark on you as it zaps you, its reach pale)
list[#list + 1] = { prefab = "gw_yellow_lizardman", sg = "SGlizardman", add = {}, no_auto = { "spit_attack" } }
-- (the Forge's elemental (golem, tfwp_elemental.lua): summoned by a player's book, it takes only monsters for its target
-- (retargetfn: "monster", never "player") - but whoever strikes it (OnAttacked: SetTarget): its homing fireball (40 a second)
-- drawn as a dark ring 26 round it as it shot monsters by you, the player 2026-10-22: "it doesn't hit". No moves - drawn
-- instead by modmain AGGRO_WHILE as the yellow lizardman's: a mark on you, only when it's after you)
list[#list + 1] = { prefab = "golem", sg = "SGtfwp_elemetal", add = {}, no_auto = { "attack" } }
list[#list + 1] = { striker = { prefab = "octoatt", radius = 1.0, delay = 0, moved = true, lasting = true, by = { "octopus" }, as_boss = true, strikes_until = 90 } }
list[#list + 1] = { prefab = "summerwalrus", sg = "SGwalrus", add = { { name = "attack", prep = function(boss) rawget(_G, "SIM_RUN_OWN_TASKS")(boss, 1.5) end } }, no_auto = { "blowdart" } }
-- (and the palm treeguard (treeguard, SGtreeguard) - built the same way, coconuts for snakes (melee: SetRange(20, 3) - starts its
-- swing from 20 off, strikes within 3): drawn the same wrong way, left out when the jungle one was mended, the player 2026-10-21)
for _, p in ipairs({ { "jungletreeguard", "SGjungletreeguard" }, { "treeguard", "SGtreeguard" } }) do
    list[#list + 1] = { prefab = p[1], sg = p[2], add = {
        { name = "attack", prep = function(boss) if boss.SetMelee ~= nil then boss:SetMelee() end end },
    }, no_auto = { "throw_pre", "throw" }, drop = { "pluck" } }
end
-- (the scorpion's spit and its spread - lobbed at each one within 20 (DoSpread, the weapon's projectile), splashing all within 3
-- of where it lands (OnProjectileHit SPLASHRADIUS; middles: 2.5 and your body): 30 of its blows undrawn on the bench, struck
-- as it had walked on, 2026-10-20 - drawn where each will land)
-- (its blows the game's as the scorpion's (complexprojectile.attacker): as_boss, landed within strikes_until frames of
-- appearing - the spit 40 a second, the spread's 20, at most 20 off: the bench's landed in 1 s and less)
list[#list + 1] = { striker = { prefab = "strange_scorpion_proj_tfc", radius = 2.5, delay = 0, moved = true, by = { "strange_scorpion_tfc" },
    as_boss = true, strikes_until = 30 } }
list[#list + 1] = { striker = { prefab = "strange_scorpion_massproj_tfc", radius = 2.5, delay = 0, moved = true, by = { "strange_scorpion_tfc" },
    as_boss = true, strikes_until = 45 } }
-- (the Ancient Hulk's mines (bomb: four lobbed 6-12 out, ancient_hulk.lua LaunchProjectile): each landed and armed, someone
-- within 3.5 sets it off (creatureprox SetDist 3.5) - red_loop 0.8 s, then DoDamage 3.5 round it (middles: 3 and your body)
-- 0.3 s on. Drawn only while it plays red_loop (true_range/simmoves _on_anims): armed, it may never go off)
list[#list + 1] = { striker = { prefab = "ancient_hulk_mine", radius = 3.0, delay = 0, moved = false, lasting = true, by = { "ancient_hulk" } } }
-- (the goddess deer's spell (goddess_deer1.lua SpawnSpells: on each one it's after, gemmed): a green tornado wandering by its
-- own brain, striking within 3 of itself as it goes (SGgreentornado1 destroystuff; middles: 2.5 and your body) - round it
-- all the while)
list[#list + 1] = { striker = { prefab = "greentornado2", radius = 2.5, delay = 0, moved = true, lasting = true, by = { "goddess_deer", "goddess_deer_gem" } } }
-- (the Ancient Robots: each made asleep (its "dormant" tag) till lightning or a hit wakes it - SGAncientRobot - every
-- move of theirs "nothing" so: awake here; and the task it's made with, putting it to sleep a frame on unless it was
-- spawned before (inst.spawned - ancient_robots.lua spawntask), told it was)
local function Wake(boss)
    rawset(boss, "spawned", true)
    if boss.RemoveTag ~= nil then boss:RemoveTag("dormant") end
end
for _, p in ipairs({ "ancient_robot_ribs", "ancient_robot_claw", "ancient_robot_leg", "ancient_robot_head" }) do
    list[#list + 1] = { prefab = p, sg = "SGAncientRobot", states = {
        { name = "attack", prep = Wake }, { name = "laserbeam", prep = Wake }, { name = "leap_attack_pre", prep = Wake },
    } }
end
return list
