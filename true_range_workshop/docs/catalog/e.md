# Monster catalog - E

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="elephantcactus_active"></a>

## elephantcactus_active

Data from: TE `moves_sim_te.lua:182`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pre` | attack_pre, attack | 30 | facing | 0 |  |  | SPIKE | TE | `moves_sim_te.lua:183` |

<a id="eyeofterror"></a>

## eyeofterror — Eye Of Terror

Data from: game `moves_sim.lua:278` · UM `moves_sim_um.lua:192` · hand-UM `moves_hand_um.lua:20`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `charge_pre` | charge_pre, charge_loop, charge_pst | 34 | facing | 11 | moves 15.0 |  | charge_cd | game | `moves_sim.lua:279` |
| `charge_pre~charge_pre` | charge_pre, charge_loop, charge_pst, taunt | 34 | facing | 123 | charge legs · moves 18.8 |  | charge_cd | game | `moves_sim.lua:280` |
| `charge_pre~shoot_pre` | charge_pre, charge_loop, charge_pst | 39 | target | 39 | told by eyeofterror_chargepulse |  | charge_cd | hand-UM | `moves_hand_um.lua:21` |
| `charge_pre~shoot_pre~2` | charge_pre, charge_loop, charge_pst | 39 | target | 39 | told by eyeofterror_chargepulse |  | charge_cd | hand-UM | `moves_hand_um.lua:22` |
| `chomp` ▦ | chomp, taunt | 25 | facing | 0 |  |  |  | game | `moves_sim.lua:281` |
| `shoot` | shoot | 11 | target | 11 |  | eyeofterror_laser, eyeofterror_laserempty |  | UM | `moves_sim_um.lua:193` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `cursed_fire` |  | lasting | hand-UM | `moves_hand_um.lua` | simmoves.lua:4621 |
| `eyeofterror_laser` |  | delay 1 | UM | `moves_sim_um.lua:47` |  |
| `eyeofterror_laserempty` |  | delay 0 | UM | `moves_sim_um.lua:48` |  |
| `eyeofterror_minieye_projectile` |  | moving · delay 0 | UM | `moves_sim_um.lua:49` | modmain.lua:1076 |

**Special code that names it:** simmoves.lua:3411

<a id="eyeofterror_mini"></a>

## eyeofterror_mini — Suspicious Peeper

Data from: game `moves_sim.lua:283`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, taunt | 14 | target | 0 | moves 2.3 |  |  | game | `moves_sim.lua:284` |

<a id="eyeofterror_mini_ally"></a>

## eyeofterror_mini_ally — Hardy Peeper

Data from: UM `moves_sim_um.lua:195`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, taunt | 14 | target | 0 | scale 1.2 · moves 2.7 |  |  | UM | `moves_sim_um.lua:196` |

<a id="eyeplant"></a>

## eyeplant — Eye Plant

Data from: game `moves_sim.lua:286`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 14 | target | 0 |  |  |  | game | `moves_sim.lua:287` |

