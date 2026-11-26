# 08 · Status - version 1.1.8 in progress (1.1.7 released 2026-11-02; updated 2026-11-26)

[<- Contents](README.md)

> **Rules for this page**: only open items + the latest numbers, one line each. An item closed = its line deleted (the details live in `git log`, by the Problem/Cause/Fix/Measured/Left template).

## Latest numbers (baselines)

| Measured | Result | When |
|---|---|---|
| full replay after the Shrouded Queen work | UM host missed 17 / 59,548 · false 1,347; client 26 / 59,510 · false 2,089; TE host 15 / 25,717 · false 421; client 11 / 25,709 · false 594 | bench 2026-11-01_1604 (UM) / 0556 (TE), replayed 2026-11-02 |
| lag, 15 main bosses | NOT drawn 7 / 1,495 (Predictive on 3/638, off 4/857) · false 60 · AG2 2, moonmaw 2, shrouden 2, daywalker 1 | lag 2026-10-31_1354 + 1441 |
| lag, 20 common monsters | NOT 3 / 546 (on 3/267: rook 2, walrus 1; off 0/279) · false 4 | lag 2026-10-31_1450 |
| lag, TE (`-TE`, UM off) | NOT 0 / 90; wildboreking NOT 0 / 102; tigershark, mandrakeman, spider_tropical, snake NOT 0 / 79 · false 0 | lag 2026-10-31_0706, 1029, 2026-11-01_2213 |
| lag, monsters never lag-run before (UM, TE, 8 sets) | all NOT 0 except: stageusher hands 11 / 402 (lead by the hand's way); TE ancient_herald 1 / 262 (state attack stuck at t=0.033 ~0.6 s before striking at 0.667); spiky_turtle_tfc 3 / 72; TE treeguard 2 / 5 (item 16); hatty_piggy_tfc 2 / 54 (we lead 0.5-0.76 at the edge) | lag 2026-11-02_0133 to 0425 |
| lag, Klaus' new chomp | NOT 0 / 387 · false 1 (the player's own log: false 7 -> 0) | lag 2026-11-02_0838 / 0850 |
| release checks for 1.1.7 (no debug.txt) | plain game (deerclops, bearger, moose, klaus) and UM (eyeofterror, deerclops, bearger, klaus, beequeen): 0 LUA ERROR client and server | lag 2026-11-02 |
| game / data | 761239 / data `83852BF58E33` | installed |

## Waiting on the owner

| Item | Options |
|---|---|
| UM Retinazer (twinofterror1) mouth laser `mouthshoot_loop`: in half the loops (bench 0433 31/63, lag 0813 17/33) the laser doesn't come our way - it really fires along the rotation at the start of each loop (SpawnLaser at TimeEvent 0, before ForceFacePoint), turning ~40° per loop. We draw the lane at you = false 31, while the real laser (eyeofterror_laser fx) is drawn anyway | a) keep b) no lane for this move, the fx alone (warns 0-19 frames, the first 2 spots unwarned) c) (proposed) the lane along the rotation at each loop's start, locked for the loop |

## Open items (most important first)

| # | Item | What's known |
|---|---|---|
| 2 | things the client replay still misses (haz_missed 11) | stageusher_attackhand 2 = client lead (we lead 3 frames and run out; on screen 2.9 from the hand / server 1.9); glacialhound_icespike 2, guardian_goo 2, um_fire_projectile, sporecloud, um_bear_trap, magma_sludge, mortarball, charlie_boss_minion1 - 1 each |
| 10 | TE leftovers: wildbeaverguard's brain acts with no target (actions.lua:1742 error, server survives); rookwater at sea doesn't move when it charges (bench); after the Hulk dies the server hangs (TE's dropparts) | not ours, unless the bench setup is changed |
| 12 | NOT in lag 1354 (7 / 1,411) | AG2 2 = atk_spike's trail stops at random for 0.5-1.0 s, then the wall comes up at once (10 from the boss) - only drawable as the whole lane = false; shrouden 2 = optic blast: Predictive puts us ~0.6 ahead and the beam's lead isn't enough when it speeds to 8-12/s; daywalker 1; moonmaw 2 = lava ring (won't fix) |
| 15 | Eye/Twins charging from a walk: the way is decided at frame 14 (eye form) / 27 (mouth form); the lane is reversed for the first 13 frames of charge_pre and can't be known earlier (lag 0657) | the eye form aims until 11, then turns back the way it walked or stays - knowable from frame 12 |
| 16 | TE treeguard: when throwing (ranged mode) DoAttack deals 0 at frame 25 = struck unhurt, not drawn; coconuts' landing is drawn, radius 4 (0.1 / 0.4 from the real spot) but no lag run has a coconut hit yet | need a lag run where a coconut really hits to measure NOT |
| 17 | TE firetwister attack hits its target from 12 (SetRange 6, 12) - NOT 3 at 12.1-12.4 (lag 0820) of 76 beyond 9 | edge, not fixing now |
| 18 | TE twister suction ring: NOT only with pred=1 (lag 0956: 4, 1013: 2; pred=0: 0) - while sucked in, the client predicts us standing still outside the 20.5 ring while the server drags us in | a measuring / Predictive limit, not drawing |
| 4 | small flickers left (lag 1354: 185 spots, was 243) | wagboss_missile JUMP 19 / REVERSE 25 = lead turns on at once above 1.5 and off when slowing (like bearger_boulder); Eye small REVERSE; bearger_boulder JUMP 27 = lead on as it starts rolling (known trade-off); web_mortar JUMP 11 = moves once from round itself to the landing spot; bigshadowtentacle AIM 14 |
| 19 | items added on the 2026-11-02 night, measured in game | NOT 0 for goat / trepidation / lightning hounds / Spazmatism / jellyfish / mindweaver / fuelseeker / haunt / moonpig; Wixie NOT 1/43 on, 1/36 off. Left: the toadling spawner crashes the game (UM's Invalid Prefab - keep it out of lag runs), fissures need an arena |

## Decided: won't fix

- UM Bee Queen shooter guards: no lane while winding up, stinger lane 4 (owner 2026-11-02: "covers the screen"); TE twister suction ring 20.5 (owner's choice)
- UM shadow Wes' balloons drawn their whole life (false 46) - owner: keep, warns all along (2026-11-02)
- UM catcoon's hiss drawn as its pounce (pounce_pre) - same animations, told apart only when the pounce starts (0.77 s late); chose to warn early (2026-11-01)
- Moonmaw's lava ring NOT 0.65% at the edge 2.76-3.00 - the client sees it late; a bigger ring = false every time
- Worm: segment comes up and strikes on the same frame - the owner doesn't want rings round dirt mounds (2026-10-29)
- shadowthrall_mouth JUMP (replay client 375) - the mouths the Umbral calls run 8/s and bite every ~7 frames, each drawn where it is as it bites = ~1 step each, as the game does
- mutatedbearger combo1 half-ring edge 87°/90°; combo1a 1 / 416 = charges 1.1 past the player on its striking frame (speed 11.7)
- rook LATE in replay (as the charge starts) - in game it warns a median 49 frames (1.6 s) before the hit, 8/8 drawn in (lag 1240, `tools\warn_time.lua`)
- beeguard atk turns with a target flying round it - bites one target; drawn on the side the target is, as the game does; NOT 0
- Bee Queen's strike ring shows 2 frames then goes when UM stuns her (3.5 s timer) just as she starts - owner: leave it (2026-10-30)
- Glacial Hound, Predictive side, hit by the tip of the spike line 13-23 / ~100 - owner: leave it (2026-10-31)
- Daywalker's first pounce warns 1-4 frames (the same run_pre as running) - owner: leave it (2026-10-31)
- UM fire hounds' spreading heat (propagator) sets things alight outside the ring - owner: leave it, no heat ring (2026-10-31)

## Planned

- Split `simmoves.lua` / `predict.lua` into modules (the 200-local limit)
- Remove `TR_OLD_xxx` switches past their time (see the rules in `VERIFY_PLAN.md`)
- Consider loading data per boss met (lazy) - measured 93 ms / 30 MB, not urgent
- Hard-coded game paths in the tools (`D:\Games Manager\...`) - read them from one place
