# Monster catalog - C

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="catcoon"></a>

## catcoon — Catcoon

Data from: game `moves_sim.lua:201` · UM `moves_sim_um.lua:157`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 |  |  |  | game | `moves_sim.lua:202` |
| `atk` | atk | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:158` |
| `jump_atk` | jump_atk | 19 | target | 0 | follows target |  |  | game | `moves_sim.lua:203` |
| `jump_atk` | jump_atk | 19 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:159` |
| `jump_grab` | jump_grab | 31 | target | 0 |  |  |  | game | `moves_sim.lua:204` |
| `jump_grab` | jump_grab | 31 | target | 0 |  |  |  | UM | `moves_sim_um.lua:160` |
| `taunt_pre` | taunt_pre, taunt, taunt_pst, jump_atk | 43 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:161` |

<a id="cave_vent_mite"></a>

## cave_vent_mite — Geothermite

Data from: game `moves_sim.lua:206`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 0 |  |  |  | game | `moves_sim.lua:207` |

<a id="charlie_boss"></a>

## charlie_boss — Shrouded Queen

Data from: game `moves_sim.lua:209`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `aoe` | aoe | 19 | facing | 0 |  |  |  | game | `moves_sim.lua:210` |
| `castlift` | castlift | 33 | facing | 22 | strikes only through things | charlie_boss_minion1, charlie_boss_minion2 |  | game | `moves_sim.lua:211` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `charlie_boss_minion1` |  | moving · delay 0 · strikes until 18 | game | `moves_sim.lua:57` | simmoves.lua:42 simmoves.lua:3388 simmoves.lua:3522 simmoves.lua:3524 |
| `charlie_boss_minion2` |  | moving · delay 0 · strikes until 14 | game | `moves_sim.lua:58` | simmoves.lua:43 simmoves.lua:3389 simmoves.lua:3522 simmoves.lua:3524 |
| `charlie_boss_projectile` | Swarming Horror | lasting · delay 0 | game | `moves_sim.lua:59` |  |
| `charlie_boss_vines` |  | lasting · delay 0 | game | `moves_sim.lua:60` | simmoves.lua:3395 |
| `charliearena_spike` | Dreadstone Outcrop | delay 29 | game | `moves_sim.lua:61` | simmoves.lua:3377 |

**Special code that names it:** simmoves.lua:3419 simmoves.lua:3539

<a id="charlie_boss_runner"></a>

## charlie_boss_runner — Grim Harrier

Data from: game `moves_sim.lua:213` · hand `moves_hand.lua:66`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 16 | target | 6 | follows target |  |  | hand | `moves_hand.lua:66` |
| `attack_quick` | attack_quick | 11 | target | 6 | follows target · moves 0.6 |  |  | game | `moves_sim.lua:214` |

**Special code that names it:** simmoves.lua:27

<a id="cherrybulletbee"></a>

## cherrybulletbee — Bullet Hibeescus

Data from: UM `moves_sim_um.lua:163`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 | scale 0.9 |  |  | UM | `moves_sim_um.lua:164` |

<a id="chest_mimic_revealed"></a>

## chest_mimic_revealed — Ornery Chest

Data from: game `moves_sim.lua:216`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack, taunt_pre | 18 | target | 0 |  |  |  | game | `moves_sim.lua:217` |
| `spawn` | spawn, taunt_pre | 38 | target | 0 |  |  |  | game | `moves_sim.lua:218` |

<a id="chimp"></a>

## chimp — Random Chimp

Data from: UM `moves_sim_um.lua:166`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 17 | target | 0 |  |  |  | UM | `moves_sim_um.lua:167` |

<a id="clayhoundb"></a>

## clayhoundb

Data from: TE `moves_sim_te.lua:164`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, howl | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:165` |

<a id="commonfish"></a>

## commonfish

Data from: TE `moves_sim_te.lua:167`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 | scale 1 |  |  | TE | `moves_sim_te.lua:168` |

<a id="cookiecutter"></a>

## cookiecutter — Cookie Cutter

Data from: game `moves_sim.lua:220` · TE `moves_sim_te.lua:170`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `hit` | hit, attack_loop, drill_pst | 25 | facing | 0 | moves 11.1 |  |  | game | `moves_sim.lua:221` |
| `hit` | hit, attack_loop, drill_pst | 25 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:171` |
| `jump_pre` | jump_pre, jumping, jump_pst_water | 28 | facing | 0 |  |  |  | game | `moves_sim.lua:222` |

<a id="cozy_bunnyman"></a>

## cozy_bunnyman — Cozy Bunnyman

Data from: game `moves_sim.lua:224`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | scale 1.25 |  |  | game | `moves_sim.lua:225` |
| `atk_object` | atk_object | 9 | target | 0 | scale 1.25 |  |  | game | `moves_sim.lua:226` |

<a id="crabking"></a>

## crabking — Crab King

Data from: game `moves_sim.lua:228`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `crabking_geyser_single` |  | lasting · delay 0 | UM | `moves_sim_um.lua:37` |  |

<a id="crabking_claw"></a>

## crabking_claw — Imposing Claw

Data from: game `moves_sim.lua:229`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 21 | facing | 0 | scale 0.7 |  |  | game | `moves_sim.lua:230` |

<a id="crabking_mob"></a>

## crabking_mob — Crab Guard

Data from: game `moves_sim.lua:232`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk1` | atk1 | 18 | target | 0 |  |  |  | game | `moves_sim.lua:233` |
| `atk_pre` ▦ | atk_pre, atk_loop, atk_pst | 14 | target | 14 |  |  |  | game | `moves_sim.lua:234` |

<a id="crabking_mob_knight"></a>

## crabking_mob_knight — Crab Knight

Data from: game `moves_sim.lua:236`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk1` | atk1 | 18 | target | 0 | scale 1.7 |  |  | game | `moves_sim.lua:237` |
| `atk_pre` | atk_pre, atk_loop, atk_pst | 14 | target | 14 |  |  |  | game | `moves_sim.lua:238` |

<a id="crawlinghorror"></a>

## crawlinghorror — Crawling Horror

Data from: game `moves_sim.lua:240` · UM `moves_sim_um.lua:169`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, taunt | 16 | target | 0 |  |  |  | game | `moves_sim.lua:241` |
| `atk_pre~terrorattack` | atk_pre, atk, taunt | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:170` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `shadow_goo` | Shadow Ink | moving · delay 0 | UM | `moves_sim_um.lua:66` |  |

<a id="creepingfear"></a>

## creepingfear — Creeping Fear

Data from: UM `moves_sim_um.lua:172`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, taunt | 16 | target | 0 | scale 1.2 |  |  | UM | `moves_sim_um.lua:173` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `uncompromising_shadow_projectile1_fx_fast` |  | delay 18 · strikes until 18 | UM | `moves_sim_um.lua:82` |  |

<a id="crocodog"></a>

## crocodog

Data from: TE `moves_sim_te.lua:173`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 20 | target | 0 |  |  |  | TE | `moves_sim_te.lua:174` |

