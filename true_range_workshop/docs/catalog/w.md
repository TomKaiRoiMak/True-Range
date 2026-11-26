# Monster catalog - W

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="wagboss_robot"></a>

## wagboss_robot — W.A.R.B.O.T.

Data from: game `moves_sim.lua:649`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_leap_pre` | atk_leap_pre, atk_leap, atk_leap_pst | 82 | facing | 78 |  |  | leap_cd | game | `moves_sim.lua:650` |
| `atk_signal_pre` ▦ | atk_signal_pre, atk_signal_loop, atk_signal_pst | 98 | target |  | follows target | wagboss_beam_fx | orbitalstrike_cd | game | `moves_sim.lua:651` |
| `atk_squish` | atk_squish | 27 | facing | 0 |  |  |  | game | `moves_sim.lua:652` |
| `taunt` | taunt | 13 | facing | 0 |  |  | tantrum_cd | game | `moves_sim.lua:653` |
| `taunt2_pre` | taunt2_pre, taunt2_loop, taunt2_pst | 58 | facing | 0 |  |  | tantrum_cd | game | `moves_sim.lua:654` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `wagboss_beam_fx` |  | lasting · delay 34 | game | `moves_sim.lua:100` |  |
| `wagboss_missile` | Thermalock Missile | moving · delay 114 | game | `moves_sim.lua:101` |  |

**Special code that names it:** simmoves.lua:3429 simmoves.lua:3668

<a id="wagdrone_flying"></a>

## wagdrone_flying — Warbler

Data from: game `moves_sim.lua:656`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst | 44 | target | 0 |  | wagdrone_projectile_fx |  | game | `moves_sim.lua:657` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `wagdrone_projectile_fx` |  | delay 32 | game | `moves_sim.lua:102` |  |

<a id="wagdrone_rolling"></a>

## wagdrone_rolling — Terramite

Data from: game `moves_sim.lua:659`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|

<a id="walrus"></a>

## walrus — MacTusk

Data from: game `moves_sim.lua:660` · hand

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 20 |  |  |  | game | `moves_sim.lua:660` |
| `atk_dart` | atk_dart | 20 | target | 20 |  |  |  | hand | `moves_hand.lua` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `um_bear_trap` | Snap-Trap | lasting · delay 0 | UM | `moves_sim_um.lua:69` |  |
| `um_bear_trap_projectile` |  | moving | hand-UM | `moves_hand_um.lua` |  |

<a id="wanawanatiki"></a>

## wanawanatiki

Data from: TE `moves_sim_te.lua:638`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | TE | `moves_sim_te.lua:639` |
| `were_atk_pre` | were_atk_pre, were_atk, were_atk_pst | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:640` |

<a id="warg"></a>

## warg — Varg

Data from: game `moves_sim.lua:661`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 11 | target | 0 |  |  |  | game | `moves_sim.lua:662` |

<a id="warglet"></a>

## warglet — Varglet

Data from: game `moves_sim.lua:664`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 | scale 1.5 |  |  | game | `moves_sim.lua:665` |

<a id="watercrocodog"></a>

## watercrocodog

Data from: TE `moves_sim_te.lua:642`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 20 | target | 0 |  |  |  | TE | `moves_sim_te.lua:643` |

<a id="waterplant"></a>

## waterplant — Sea Weed

Data from: game `moves_sim.lua:667`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `waterplant_projectile` |  | moving · delay 0 · strikes until 30 | game | `moves_sim.lua:105` |  |

<a id="weevole"></a>

## weevole

Data from: TE `moves_sim_te.lua:645`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `leap_attack` | leap_attack, taunt | 18 | target | 0 | follows target |  |  | TE | `moves_sim_te.lua:646` |

<a id="whale_blue"></a>

## whale_blue

Data from: TE `moves_sim_te.lua:648`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:649` |

<a id="whale_bluefinal"></a>

## whale_bluefinal

Data from: TE `moves_sim_te.lua:651`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:652` |

<a id="whale_white"></a>

## whale_white

Data from: TE `moves_sim_te.lua:654`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 25 | target | 0 | scale 1.25 |  |  | TE | `moves_sim_te.lua:655` |

<a id="wicker_tentacle"></a>

## wicker_tentacle — Sickly Tentacle

Data from: UM `moves_sim_um.lua:549`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_loop` | atk_loop, atk_idle | 7 | target | 0 |  |  |  | UM | `moves_sim_um.lua:550` |
| `atk_pre` | atk_pre, atk_loop, atk_idle | 32 | target | 0 |  |  |  | UM | `moves_sim_um.lua:551` |

<a id="wildbeaver"></a>

## wildbeaver

Data from: TE `moves_sim_te.lua:657`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 9 | target | 0 |  |  |  | TE | `moves_sim_te.lua:658` |

<a id="wildbeaverguard"></a>

## wildbeaverguard

Data from: TE `moves_sim_te.lua:660`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 9 | target | 0 |  |  |  | TE | `moves_sim_te.lua:661` |

<a id="wildbore"></a>

## wildbore

Data from: TE `moves_sim_te.lua:663`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | TE | `moves_sim_te.lua:664` |
| `charge_atk` | charge_atk | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:665` |
| `were_atk_pre` | were_atk_pre, were_atk, were_atk_pst | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:666` |

<a id="wildboreguard"></a>

## wildboreguard

Data from: TE `moves_sim_te.lua:668`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | TE | `moves_sim_te.lua:669` |
| `charge_atk` | charge_atk | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:670` |

<a id="wildboreking"></a>

## wildboreking

Data from: TE `moves_sim_te.lua:672`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `death` | death | 20 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:673` |
| `jump` | jump, walk_loop | 30 | facing | 0 | charge legs |  | GroundPound | TE | `moves_sim_te.lua:674` |
| `standup` | standup | 10 | facing | 0 |  |  | GroundPound | TE | `moves_sim_te.lua:675` |

<a id="woodlegs1"></a>

## woodlegs1

Data from: TE `moves_sim_te.lua:677`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | TE | `moves_sim_te.lua:678` |

<a id="worm"></a>

## worm — Depths Worm

Data from: game `moves_sim.lua:668`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | game | `moves_sim.lua:669` |
| `atk_pre` | atk_pre, atk | 50 | target | 0 |  |  |  | game | `moves_sim.lua:670` |

