# Monster catalog - T

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="tallbird"></a>

## tallbird — Tallbird

Data from: game `moves_sim.lua:603`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 12 | target | 0 |  |  |  | game | `moves_sim.lua:604` |
| `teenatk_pre` | teenatk_pre, teenatk | 13 | target | 0 |  |  |  | game | `moves_sim.lua:605` |

<a id="teenbird"></a>

## teenbird — Smallish Tallbird

Data from: game `moves_sim.lua:607`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 12 | target | 0 | scale 0.8 |  |  | game | `moves_sim.lua:608` |
| `teenatk_pre` | teenatk_pre, teenatk | 13 | target | 0 | scale 0.8 |  |  | game | `moves_sim.lua:609` |

<a id="tentacle"></a>

## tentacle — Tentacle

Data from: game `moves_sim.lua:611`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_loop` | atk_loop, atk_idle | 7 | target | 0 |  |  |  | game | `moves_sim.lua:612` |
| `atk_pre` | atk_pre, atk_loop, atk_idle | 32 | target | 0 |  |  |  | game | `moves_sim.lua:613` |

**Special code that names it:** modmain.lua:890

<a id="tentacle_pillar_arm"></a>

## tentacle_pillar_arm — Baby Tentacle

Data from: game `moves_sim.lua:615`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_loop` | atk_loop, atk_pst | 7 | target | 0 | scale 0.95 |  |  | game | `moves_sim.lua:616` |

**Special code that names it:** modmain.lua:890

<a id="tentacleunderwater"></a>

## tentacleunderwater

Data from: TE `moves_sim_te.lua:612`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk_loop, atk_idle | 32 | target | 0 |  |  |  | TE | `moves_sim_te.lua:613` |

<a id="thunderbird"></a>

## thunderbird

Data from: TE `moves_sim_te.lua:615`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|

<a id="ticoon"></a>

## ticoon — Ticoon

Data from: game `moves_sim.lua:618`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 | scale 1.1 |  |  | game | `moves_sim.lua:619` |

<a id="tigershark"></a>

## tigershark

Data from: TE `moves_sim_te.lua:616`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 23 | facing | 0 |  |  | Run | TE | `moves_sim_te.lua:617` |
| `launch_down_pst` | launch_down_pst | 0 | facing |  | around itself |  |  | TE | `moves_sim_te.lua:618` |
| `launch_up_pre` | launch_up_pre, launch_up_loop | 0 | facing |  | around itself |  |  | TE | `moves_sim_te.lua:619` |
| `launch_up_pre~jump` | launch_up_pre, launch_up_loop | 0 | facing |  | around itself · moves 1.0 |  |  | TE | `moves_sim_te.lua:620` |
| `water_atk_pre` | water_atk_pre, water_atk, water_atk_pst | 27 | facing | 0 |  |  | Run | TE | `moves_sim_te.lua:621` |

**Special code that names it:** modmain.lua:984

<a id="tikiman"></a>

## tikiman

Data from: TE `moves_sim_te.lua:623`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 17 | target | 0 | scale 1.25 |  |  | TE | `moves_sim_te.lua:624` |

<a id="toadstool"></a>

## toadstool — Toadstool

Data from: game `moves_sim.lua:621`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pound_pre` ▦ | attack_pound_pre, attack_pound_loop, attack_pound_pst | 36 | facing | 0 |  |  | pound_cd | game | `moves_sim.lua:622` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `mushroombomb` | Boomshroom | delay 95 | game | `moves_sim.lua:85` |  |

<a id="toadstool_dark"></a>

## toadstool_dark — Misery Toadstool

Data from: game `moves_sim.lua:624`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pound_pre` | attack_pound_pre, attack_pound_loop, attack_pound_pst | 36 | facing | 0 |  |  | pound_cd | game | `moves_sim.lua:625` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `mushroombomb_dark` | Misery Boomshroom | delay 95 | game | `moves_sim.lua:86` |  |

<a id="trapslug"></a>

## trapslug

Data from: TE `moves_sim_te.lua:626`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 9 | target | 0 |  |  |  | TE | `moves_sim_te.lua:627` |

<a id="treeguard"></a>

## treeguard

Data from: TE `moves_sim_te.lua:629`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:630` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `warningshadow` |  | moving · lasting · delay 0 · strikes until 60 | TE | `moves_sim_te.lua:58` | predict.lua:4062 predict.lua:4077 predict.lua:4096 |

**Special code that names it:** predict.lua:4069

<a id="tricktreatpigman"></a>

## tricktreatpigman

Data from: UM `moves_sim_um.lua:454`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | UM | `moves_sim_um.lua:455` |
| `counter_atk` | counter_atk, charge_pre, charge_loop, charge_atk | 54 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:456` |
| `counter_atk~counterattack_pre` | counter_atk, charge_pre, charge_loop, charge_atk | 54 | facing | 0 | follows target |  |  | UM | `moves_sim_um.lua:457` |
| `paw_loop` | paw_loop, charge_pre, charge_loop, charge_atk | 74 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:458` |
| `paw_pre` | paw_pre, paw_loop, charge_pre, charge_loop, … | 79 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:459` |
| `were_atk_pre` | were_atk_pre, were_atk, halloween_atk_pst | 12 | target | 0 |  |  |  | UM | `moves_sim_um.lua:460` |

<a id="twinofterror1"></a>

## twinofterror1 — Retinazor

Data from: game `moves_sim.lua:627` · UM `moves_sim_um.lua:462`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `charge_pre` | charge_pre, charge_loop, charge_pst | 34 | facing | 11 | moves 20.0 |  | charge_cd | game | `moves_sim.lua:628` |
| `charge_pre~charge_pre` | charge_pre, charge_loop, charge_pst, taunt | 34 | facing | 105 | charge legs · moves 15.4 |  | charge_cd | game | `moves_sim.lua:629` |
| `charge_pre~shoot_pre` | charge_pre, charge_loop, charge_pst, taunt | 34 | target | 34 | told by eyeofterror_chargepulse | eyeofterror_laser, eyeofterror_laserempty | charge_cd | UM | `moves_sim_um.lua:463` |
| `charge_pre~shoot_pre~2` | charge_pre, charge_loop, charge_pst | 34 | target | 50 | told by eyeofterror_chargepulse | eyeofterror_laser, eyeofterror_laserempty | charge_cd | UM | `moves_sim_um.lua:464` |
| `chomp` ▦ | chomp, taunt | 25 | facing | 0 |  |  |  | game | `moves_sim.lua:630` |
| `shoot` | shoot | 11 | target | 11 |  | eyeofterror_laser, eyeofterror_laserempty |  | UM | `moves_sim_um.lua:465` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `eyeofterror_laser` |  | delay 1 | UM | `moves_sim_um.lua:47` |  |
| `eyeofterror_laserempty` |  | delay 0 | UM | `moves_sim_um.lua:48` |  |

**Special code that names it:** simmoves.lua:3411 simmoves.lua:3446

<a id="twinofterror2"></a>

## twinofterror2 — Spazmatism

Data from: game `moves_sim.lua:632` · UM `moves_sim_um.lua:467` · hand-UM `moves_hand_um.lua:24`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `charge_pre` | charge_pre, charge_loop, charge_pst | 34 | facing | 11 | moves 9.2 |  |  | game | `moves_sim.lua:633` |
| `charge_pre~charge_pre` | charge_pre, charge_loop, charge_pst | 34 | facing | 93 | charge legs · moves 12.5 |  | charge_cd | game | `moves_sim.lua:634` |
| `charge_pre~shoot_pre` | charge_pre, charge_loop, charge_pst | 34 | target | 34 | told by eyeofterror_chargepulse |  | charge_cd | hand-UM | `moves_hand_um.lua:25` |
| `charge_pre~shoot_pre~2` | charge_pre, charge_loop, charge_pst | 34 | target | 34 | told by eyeofterror_chargepulse |  | charge_cd | hand-UM | `moves_hand_um.lua:26` |
| `chomp` ▦ | chomp, taunt | 25 | facing | 0 |  |  |  | game | `moves_sim.lua:635` |
| `shoot` | shoot | 11 | target | 11 |  | eyeofterror_laser, eyeofterror_laserempty |  | UM | `moves_sim_um.lua:468` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `cursed_fire` |  | lasting | hand-UM | `moves_hand_um.lua` | simmoves.lua:4621 |
| `cursed_fire` |  | lasting · delay 15 | UM | `moves_sim_um.lua:38` | simmoves.lua:4621 |
| `eyeofterror_fireball` |  | moving · delay 0 | UM | `moves_sim_um.lua:46` |  |
| `eyeofterror_laser` |  | delay 1 | UM | `moves_sim_um.lua:47` |  |
| `eyeofterror_laserempty` |  | delay 0 | UM | `moves_sim_um.lua:48` |  |

**Special code that names it:** simmoves.lua:3411

<a id="twister"></a>

## twister

Data from: TE `moves_sim_te.lua:632`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 33 | facing | 0 | scale 1 |  |  | TE | `moves_sim_te.lua:633` |

**Special code that names it:** modmain.lua:912 modmain.lua:940

