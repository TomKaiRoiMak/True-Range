# Monster catalog - H

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="hatty_piggy_tfc"></a>

## hatty_piggy_tfc

Data from: TE `moves_sim_te.lua:284`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1 | 12 | target | 0 | scale 0.8 |  |  | TE | `moves_sim_te.lua:285` |
| `attack2` | attack2 | 26 | target | 0 | follows target · scale 0.8 |  |  | TE | `moves_sim_te.lua:286` |

<a id="hippopotamoose"></a>

## hippopotamoose

Data from: TE `moves_sim_te.lua:288`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:289` |
| `atk~attack` | atk | 17 | target | 0 |  |  |  | TE | `moves_sim_te.lua:290` |
| `jump_atk_pre` | jump_atk_pre, jump_atk_loop, jump_atk_pst, taunt | 39 | target | 0 | follows target · moves 1.0 |  |  | TE | `moves_sim_te.lua:291` |

<a id="hoodedwidow"></a>

## hoodedwidow — Hooded Widow

Data from: UM `moves_sim_um.lua:213`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 30 | facing | 0 | scale 1.5 |  |  | UM | `moves_sim_um.lua:214` |
| `charge_strike` | charge_strike | 12 | facing |  | around itself · scale 1.5 · moves 8.1 |  |  | UM | `moves_sim_um.lua:215` |
| `charge_turn` | charge_turn, charge_loop, charge_strike, charge_pst | 66 | facing |  | around itself · scale 1.5 · moves 13.2 |  | pounce | UM | `moves_sim_um.lua:216` |
| `fall~canopyland` | fall, taunt | 12 | facing | 0 | scale 1.5 |  |  | UM | `moves_sim_um.lua:217` |
| `hang_leap_pre` | hang_leap_pre, hang_leap_loop, leap_pst | 20 | target | 0 | scale 1.5 · moves 14.4 |  | pounce | UM | `moves_sim_um.lua:218` |
| `prejump` | prejump, leap | 38 | target | 19 | scale 1.5 · moves 9.1 |  | pounce | UM | `moves_sim_um.lua:219` |
| `shoot_pre` | shoot_pre, shoot_loop, shoot_pst | 32 | facing | 0 | scale 1.5 |  | mortar | UM | `moves_sim_um.lua:220` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `web_mortar` |  | moving · delay 0 | UM | `moves_sim_um.lua:84` |  |

<a id="hound"></a>

## hound — Hound

Data from: game `moves_sim.lua:321`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | game | `moves_sim.lua:322` |

<a id="houndb"></a>

## houndb

Data from: TE `moves_sim_te.lua:293`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:294` |

