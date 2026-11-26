# Monster catalog - M

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="magmahound"></a>

## magmahound — Magma Varglet

Data from: UM `moves_sim_um.lua:254`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, taunt | 16 | target | 0 | scale 1.2 |  |  | UM | `moves_sim_um.lua:255` |
| `scared_pre` | scared_pre, burningup, scared_pst, belch | 48 | facing |  | around itself · scale 1.2 |  | lightningshot_cooldown | UM | `moves_sim_um.lua:256` |
| `scared_pst` | scared_pst, belch | 9 | facing |  | around itself · scale 1.2 |  |  | UM | `moves_sim_um.lua:257` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `um_fire_projectile` |  | moving · lasting · delay 0 | UM | `moves_sim_um.lua:72` | simmoves.lua:3667 simmoves.lua:4617 |

**Special code that names it:** simmoves.lua:3452

<a id="malbatross"></a>

## malbatross — Malbatross

Data from: game `moves_sim.lua:372` · UM `moves_sim_um.lua:259` · TE `moves_sim_te.lua:337`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 29 | target | 0 | scale 1.3 |  |  | game | `moves_sim.lua:373` |
| `atk` ▦ | atk | 29 | facing | 0 | scale 1.3 |  |  | TE | `moves_sim_te.lua:338` |
| `atk` ▦ | atk | 29 | facing | 0 | scale 1.3 |  |  | UM | `moves_sim_um.lua:260` |
| `swoop_pre` | swoop_pre, swoop_loop, swoop_pst, taunt | 26 | target | 11 | scale 1.3 · moves 19.5 |  |  | game | `moves_sim.lua:374` |
| `swoop_pre` | swoop_pre, swoop_loop, swoop_pst, taunt | 26 | facing | 34 | scale 1.3 · moves 19.5 |  |  | TE | `moves_sim_te.lua:339` |
| `swoop_pre` | swoop_pre, swoop_loop, swoop_pst, taunt | 26 | facing | 34 | scale 1.3 · moves 19.5 |  |  | UM | `moves_sim_um.lua:261` |

<a id="mandrakeman"></a>

## mandrakeman

Data from: TE `moves_sim_te.lua:341`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | scale 1.25 |  |  | TE | `moves_sim_te.lua:342` |

<a id="mean_flytrap"></a>

## mean_flytrap

Data from: TE `moves_sim_te.lua:344`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst | 15 | target | 0 |  |  |  | TE | `moves_sim_te.lua:345` |

<a id="mecfish_alive"></a>

## mecfish_alive

Data from: TE `moves_sim_te.lua:347`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `walk_loop` | walk_loop | 10 | target | 0 | scale 1 |  |  | TE | `moves_sim_te.lua:348` |

<a id="merm"></a>

## merm — Merm

Data from: game `moves_sim.lua:376` · UM `moves_sim_um.lua:263` · hand-UM

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | game | `moves_sim.lua:377` |
| `atk_combo` | atk_combo |  |  |  |  |  |  | hand-UM | `moves_hand_um.lua` |
| `were_atk_pre` | were_atk_pre, were_atk, halloween_atk_pst | 12 | target | 0 |  |  |  | game | `moves_sim.lua:378` |
| `were_atk_pre` | were_atk_pre, were_atk, halloween_atk_pst | 12 | target | 0 |  |  |  | UM | `moves_sim_um.lua:264` |

**Special code that names it:** simmoves.lua:170

<a id="mermb"></a>

## mermb

Data from: TE `moves_sim_te.lua:350`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | TE | `moves_sim_te.lua:351` |

<a id="mermb2"></a>

## mermb2

Data from: TE `moves_sim_te.lua:353`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | scale 2 |  |  | TE | `moves_sim_te.lua:354` |

<a id="mermking"></a>

## mermking — King of the Merms

Data from: game `moves_sim.lua:380`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|

<a id="mindweaver"></a>

## mindweaver — Mind Weaver

Data from: UM `moves_sim_um.lua:266`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `grab` | grab, retreat | 27 | facing | 0 | scale 1.6 |  |  | UM | `moves_sim_um.lua:267` |

<a id="minotaur"></a>

## minotaur — Ancient Guardian

Data from: game `moves_sim.lua:381` · UM `moves_sim_um.lua:269`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, paw_loop, atk, gore | 45 | target | 45 |  |  |  | game | `moves_sim.lua:382` |
| `bite` ▦ | bite | 16 | target | 0 |  |  |  | game | `moves_sim.lua:383` |
| `gore` | gore | 1 | target |  |  |  |  | game | `moves_sim.lua:384` |
| `gore~run_stop` | gore | 5 | target | 0 |  |  |  | game | `moves_sim.lua:385` |
| `jump_atk_pre` | jump_atk_pre, jump_atk_loop, jump_atk_pst, taunt | 59 | target | 31 | follows target · moves 3.0 |  | leapattack_cooldown | game | `moves_sim.lua:386` |
| `jump_atk_pre` | jump_atk_pre, jump_atk_loop, jump_atk_pst, taunt | 59 | target | 31 | follows target · moves 3.0 |  | forceleapattack | UM | `moves_sim_um.lua:270` |
| `jump_atk_pre_quick` | jump_atk_pre_quick, jump_atk_loop, jump_atk_pst, taunt | 44 | target | 16 | follows target · moves 3.0 |  | forceleapattack | UM | `moves_sim_um.lua:271` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `groundpoundring_fx` |  | drawn with the boss move · delay 0 · strikes until 6 | game | `moves_sim.lua:79` | simmoves.lua:3469 |
| `guardian_goo` |  | moving · strikes on landing · delay 0 | UM | `moves_sim_um.lua:54` |  |

<a id="mock_dragonfly"></a>

## mock_dragonfly — Dragonfly

Data from: UM `moves_sim_um.lua:273`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | facing | 0 | scale 1.3 |  |  | UM | `moves_sim_um.lua:274` |
| `fire_on` | fire_on, dash_pre, charge, charge_pst | 63 | facing | 151 | charge legs · scale 1.3 · moves 19.4 |  | RockThrow | UM | `moves_sim_um.lua:275` |
| `taunt` | taunt, taunt_pst | 2 | facing | 0 | scale 1.3 |  |  | UM | `moves_sim_um.lua:276` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `fireball_throwable` |  | moving · delay 0 | UM | `moves_sim_um.lua:50` |  |
| `firesplash_fx` |  | lasting · drawn with the boss move · delay 0 · strikes until 123 | UM | `moves_sim_um.lua:51` |  |
| `magmafire` |  | lasting · delay 0 | UM | `moves_sim_um.lua:56` |  |

<a id="molebat"></a>

## molebat — Naked Mole Bat

Data from: game `moves_sim.lua:388`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 10 | target | 0 |  |  |  | game | `moves_sim.lua:389` |

<a id="monkey"></a>

## monkey — Splumonkey

Data from: game `moves_sim.lua:391`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 17 | target | 0 |  |  |  | game | `moves_sim.lua:392` |

<a id="moonmaw_dragonfly"></a>

## moonmaw_dragonfly — Moonmaw Dragonfly

Data from: UM `moves_sim_um.lua:278`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | facing | 0 | scale 1.3 | moonmaw_glass |  | UM | `moves_sim_um.lua:279` |
| `bigattack` | bigattack | 26 | facing | 0 | scale 1.3 |  |  | UM | `moves_sim_um.lua:280` |
| `skyfall` | skyfall, crashed_loop | 6 | facing | 0 | scale 1.3 |  |  | UM | `moves_sim_um.lua:281` |
| `spin_pre` | spin_pre, spin | 14 | facing | 0 | scale 1.3 |  |  | UM | `moves_sim_um.lua:282` |
| `taunt_pre` | taunt_pre, taunt, taunt_pst | 25 | facing | 0 | scale 1.3 |  |  | UM | `moves_sim_um.lua:283` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `moonmaw_glass` | Unstable Moon Glass | lasting · delay 0 | UM | `moves_sim_um.lua:58` |  |
| `moonmaw_glassshards` |  | moving · delay 0 | UM | `moves_sim_um.lua:59` |  |
| `moonmaw_trapprojectile` |  | delay 32 | UM | `moves_sim_um.lua:60` | simmoves.lua:3367 |

<a id="moonmaw_lavae"></a>

## moonmaw_lavae — Glass Lavae

Data from: UM `moves_sim_um.lua:285`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `drop` | drop, deathground | 11 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:286` |
| `stab_pre` | stab_pre, stab_loop | 11 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:287` |

<a id="moonpig"></a>

## moonpig

Data from: game `moves_sim.lua:394` · UM `moves_sim_um.lua:289`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `were_atk_pre` | were_atk_pre, were_atk, were_atk_pst | 16 | target | 0 |  |  |  | game | `moves_sim.lua:395` |
| `were_atk_pre` | were_atk_pre, were_atk | 16 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:290` |

<a id="moose"></a>

## moose

Data from: game `moves_sim.lua:397` · UM `moves_sim_um.lua:292`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 20 | target | 0 | scale 1.55 |  | DisarmCooldown | game | `moves_sim.lua:398` |
| `atk` ▦ | atk | 20 | facing | 0 | scale 1.55 |  | DisarmCooldown | UM | `moves_sim_um.lua:293` |
| `hopatk` | hopatk, hopatk_loop, land | 50 | facing | 33 | cone · scale 1.55 · moves 3.8 |  | SuperHop | UM | `moves_sim_um.lua:294` |
| `takeoff_pre_diagonal` | takeoff_pre_diagonal, tornadoattack | 30 | target | 0 | scale 1.55 | mothergoose_tornado |  | UM | `moves_sim_um.lua:295` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `mothergoose_tornado` |  | lasting · delay 30 | UM | `moves_sim_um.lua:61` |  |

<a id="mosquito"></a>

## mosquito — Mosquito

Data from: game `moves_sim.lua:400`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 |  |  |  | game | `moves_sim.lua:401` |
| `explode` | explode | 11 | facing | 0 |  |  |  | game | `moves_sim.lua:402` |

<a id="mosquito_poison"></a>

## mosquito_poison

Data from: TE `moves_sim_te.lua:356`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 |  |  |  | TE | `moves_sim_te.lua:357` |
| `explode` | explode | 11 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:358` |

<a id="mossling"></a>

## mossling — Mosling

Data from: game `moves_sim.lua:404`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 0 |  |  |  | game | `moves_sim.lua:405` |
| `spin_pre` | spin_pre, spin_loop, spin_pst | 16 | target | 0 |  |  |  | game | `moves_sim.lua:406` |

<a id="mothergoose"></a>

## mothergoose

Data from: UM `moves_sim_um.lua:297`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | facing | 0 | scale 1.55 |  | DisarmCooldown | UM | `moves_sim_um.lua:298` |
| `hopatk` | hopatk, hopatk_loop, land | 50 | facing | 33 | cone · scale 1.55 · moves 3.8 |  | SuperHop | UM | `moves_sim_um.lua:299` |
| `takeoff_pre_diagonal` | takeoff_pre_diagonal, tornadoattack | 30 | target | 0 | scale 1.55 | mothergoose_tornado |  | UM | `moves_sim_um.lua:300` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `mothergoose_tornado` |  | lasting · delay 30 | UM | `moves_sim_um.lua:61` |  |

<a id="mothermossling"></a>

## mothermossling

Data from: UM `moves_sim_um.lua:302`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 0 |  |  |  | UM | `moves_sim_um.lua:303` |
| `spin_pre` | spin_pre, spin_loop, spin_pst | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:304` |

<a id="mushdrake_red"></a>

## mushdrake_red

Data from: UM `moves_sim_um.lua:306`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 0 |  |  |  | UM | `moves_sim_um.lua:307` |
| `atk_pre` | atk_pre, atk_loop, atk_pst | 20 | target | 0 |  |  |  | UM | `moves_sim_um.lua:308` |

<a id="mushgnome"></a>

## mushgnome — Mush Gnome

Data from: game `moves_sim.lua:408`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|

<a id="mutated_penguin"></a>

## mutated_penguin — Permafrost Pengull

Data from: game `moves_sim.lua:409` · hand `moves_hand.lua:42`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 15 | target | 0 |  |  |  | game | `moves_sim.lua:410` |
| `slide` | slide_bounce, slide_loop |  | facing |  | charge legs |  |  | hand | `moves_hand.lua` |

**Special code that names it:** modmain.lua:907

<a id="mutatedbearger"></a>

## mutatedbearger — Armored Bearger

Data from: game `moves_sim.lua:412`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk1` | atk1, atk1_pst, atk2 | 32 | facing | 10 | moves 0.4 |  |  | game | `moves_sim.lua:413` |
| `atk1a` | atk1a, atk1_pst, atk2 | 28 | facing | 10 | moves 0.4 |  |  | game | `moves_sim.lua:414` |
| `atk2` | atk2, atk2_pst, atk1a | 28 | facing | 10 | moves 0.4 |  |  | game | `moves_sim.lua:415` |
| `butt` ▦ | butt, butt_pst | 8 | facing | 0 | moves 2.9 |  |  | game | `moves_sim.lua:416` |
| `ground_pound` | ground_pound | 20 | facing | 0 |  |  | GroundPound | game | `moves_sim.lua:417` |
| `ground_pound~pound` | ground_pound, stagger_pre, stagger_pst | 20 | facing | 0 |  |  | GroundPound | game | `moves_sim.lua:418` |
| `sleep_pst` | sleep_pst, yawn, standing_yawn_pst | 103 | facing | 0 |  |  | Yawn | game | `moves_sim.lua:419` |

<a id="mutatedbird"></a>

## mutatedbird — Bright-Beaked Bird

Data from: game `moves_sim.lua:421`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` ▦ | attack | 8 | target | 0 |  |  |  | game | `moves_sim.lua:422` |

<a id="mutatedbuzzard_gestalt"></a>

## mutatedbuzzard_gestalt — Crystal-Crested Buzzard

Data from: game `moves_sim.lua:424`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | game | `moves_sim.lua:425` |
| `atk_flame_pre` | atk_flame_pre, atk_flame_loop, atk_flame_pst | 39 | target | 36 | strikes only through things · moves 3.2 | warg_mutated_breath_fx | flamethrower_cd | game | `moves_sim.lua:426` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `warg_mutated_breath_fx` |  | lasting · delay 0 · strikes until 90 | game | `moves_sim.lua:104` | simmoves.lua:3360 simmoves.lua:3382 |

<a id="mutateddeerclops"></a>

## mutateddeerclops — Crystal Deerclops

Data from: game `moves_sim.lua:428`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 34 | facing | 16 | scale 1.65 | deerclops_icespike_fx |  | game | `moves_sim.lua:429` |
| `atk2` | atk2 | 19 | facing | 18 | scale 1.65 | deerclops_laser, deerclops_laserempty | laserbeam_cd | game | `moves_sim.lua:430` |
| `throw` | throw | 60 | facing | 30 | scale 1.65 | deerclops_icelance_ping_fx, deerclops_impact_circle_fx |  | game | `moves_sim.lua:431` |
| `throw_2` | throw_2 | 60 | facing | 30 | scale 1.65 | deerclops_icelance_ping_fx, deerclops_impact_circle_fx |  | game | `moves_sim.lua:432` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `deerclops_icelance_ping_fx` |  | drawn with the boss move · delay 30 · strikes until 30 | UM | `moves_sim_um.lua:40` |  |
| `deerclops_icespike_fx` |  | delay 0 · strikes until 3 | UM | `moves_sim_um.lua:41` |  |
| `deerclops_impact_circle_fx` |  | lasting · delay 0 | UM | `moves_sim_um.lua:42` |  |
| `deerclops_laser` |  | drawn with the boss move · delay 0 · strikes until 9 | game | `moves_sim.lua:69` |  |
| `deerclops_laserempty` |  | drawn with the boss move · delay 0 · strikes until 0 | game | `moves_sim.lua:70` |  |

<a id="mutatedwarg"></a>

## mutatedwarg — Possessed Varg

Data from: game `moves_sim.lua:434`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 11 | target | 0 |  |  |  | game | `moves_sim.lua:435` |
| `atk_breath_pre` | atk_breath_pre, atk_breath_loop, atk_breath_pst | 19 | facing | 16 |  |  |  | game | `moves_sim.lua:436` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `warg_mutated_breath_fx` |  | lasting · delay 0 · strikes until 90 | game | `moves_sim.lua:104` | simmoves.lua:3360 simmoves.lua:3382 |

