# Monster catalog - R

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="rabbitking_aggressive"></a>

## rabbitking_aggressive — Wrathful Rabbit King

Data from: game `moves_sim.lua:464`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `dropkick_pre` | dropkick_pre, dropkick_loop, dropkick_hit, dropkick_hit_pst | 10 | target | 0 |  |  |  | game | `moves_sim.lua:465` |

<a id="rabbitkingminion_bunnyman"></a>

## rabbitkingminion_bunnyman — Royal Rabbit Enforcer

Data from: game `moves_sim.lua:467`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | scale 1.25 |  |  | game | `moves_sim.lua:468` |

<a id="rabid_beetle"></a>

## rabid_beetle

Data from: TE `moves_sim_te.lua:468`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 | scale 0.6 |  |  | TE | `moves_sim_te.lua:469` |

<a id="rambranch"></a>

## rambranch

Data from: UM `moves_sim_um.lua:356`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pound_pre` | attack_pound_pre, attack_pound_loop | 37 | facing | 0 |  |  | pound_cd | UM | `moves_sim_um.lua:357` |

<a id="real_shadowwaxwell"></a>

## real_shadowwaxwell

Data from: UM `moves_sim_um.lua:359`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 8 | target | 0 |  |  |  | UM | `moves_sim_um.lua:360` |

<a id="rhinodrill"></a>

## rhinodrill — Rhinocebro Snapback

Data from: TE `moves_sim_te.lua:471`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 13 | target | 0 | scale 1.15 |  |  | TE | `moves_sim_te.lua:472` |
| `chest_bump` | chest_bump | 16 | target | 0 | scale 1.15 |  |  | TE | `moves_sim_te.lua:473` |

**Special code that names it:** modmain.lua:962

<a id="rhinodrill2"></a>

## rhinodrill2 — Rhinocebro Flatbrim

Data from: TE `moves_sim_te.lua:475`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 13 | target | 0 | scale 1.15 |  |  | TE | `moves_sim_te.lua:476` |
| `chest_bump` | chest_bump | 16 | target | 0 | scale 1.15 |  |  | TE | `moves_sim_te.lua:477` |

**Special code that names it:** modmain.lua:963

<a id="rneskeleton"></a>

## rneskeleton — Skeleton

Data from: UM `moves_sim_um.lua:362` · hand-UM

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk, idle | 19 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:363` |
| `atk_pre` | atk_pre, atk |  |  |  |  |  |  | hand-UM | `moves_hand_um.lua` |
| `atk_pre` | atk_pre, atk, walk_loop | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:364` |

<a id="roc_head"></a>

## roc_head

Data from: TE `moves_sim_te.lua:479`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `bash_pre` | bash_pre, bash_loop, bash_pst | 37 | facing | 0 | scale 0.8 |  |  | TE | `moves_sim_te.lua:480` |

<a id="roc_leg"></a>

## roc_leg

Data from: TE `moves_sim_te.lua:482`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `stomp_pre` | stomp_pre | 8 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:483` |

<a id="rocky"></a>

## rocky — Rock Lobster

Data from: game `moves_sim.lua:470`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 20 | target | 0 |  |  |  | game | `moves_sim.lua:471` |
| `atk_dash` | atk_dash | 12 | target | 0 | moves 13.8 |  | dashcd | game | `moves_sim.lua:472` |
| `atk_snip` | atk_snip | 15 | target | 0 |  | rocky_snip_fx |  | game | `moves_sim.lua:473` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `rocky_snip_fx` |  | drawn with the boss move · delay 0 · strikes until 19 | game | `moves_sim.lua:87` |  |

**Special code that names it:** simmoves.lua:171 simmoves.lua:235 simmoves.lua:272

<a id="rocky_boss"></a>

## rocky_boss — Rock Master

Data from: game `moves_sim.lua:475`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | scale 1.4 |  |  | game | `moves_sim.lua:476` |
| `atk_dash` | atk_dash | 12 | target | 0 | scale 1.4 · moves 14.3 |  | dashcd | game | `moves_sim.lua:477` |
| `atk_snip` | atk_snip | 15 | target | 0 | scale 1.4 | rocky_snip_fx |  | game | `moves_sim.lua:478` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `rocky_snip_fx` |  | drawn with the boss move · delay 0 · strikes until 19 | game | `moves_sim.lua:87` |  |

**Special code that names it:** simmoves.lua:171 simmoves.lua:3457

<a id="rocky_boss_shadow"></a>

## rocky_boss_shadow — Blighted Rock Master

Data from: game `moves_sim.lua:480`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | scale 1.4 |  |  | game | `moves_sim.lua:481` |
| `atk_dash` | atk_dash | 12 | target | 0 | scale 1.4 · moves 48.7 |  | dashcd | game | `moves_sim.lua:482` |
| `atk_snip` | atk_snip | 15 | target | 0 | scale 1.4 | rocky_snip_fx |  | game | `moves_sim.lua:483` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `rocky_snip_fx` |  | drawn with the boss move · delay 0 · strikes until 19 | game | `moves_sim.lua:87` |  |

**Special code that names it:** simmoves.lua:3457

<a id="rook"></a>

## rook — Clockwork Rook

Data from: game `moves_sim.lua:485`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk, atk_collide | 0 | target | 0 |  |  |  | game | `moves_sim.lua:486` |
| `atk_pre` | atk_pre, paw_loop, atk, atk_collide | 30 | target | 15 |  |  |  | game | `moves_sim.lua:487` |

**Special code that names it:** simmoves.lua:51

<a id="rookwater"></a>

## rookwater

Data from: TE `moves_sim_te.lua:485`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, paw_loop, atk | 30 | target | 15 |  |  |  | TE | `moves_sim_te.lua:486` |

<a id="ruinsnightmare"></a>

## ruinsnightmare — Lurking Nightmare

Data from: game `moves_sim.lua:489` · UM `moves_sim_um.lua:366`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | game | `moves_sim.lua:490` |
| `atk_pre~terrorattack` | atk_pre, atk | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:367` |
| `atk_walk_pre` | atk_walk_pre, atk | 20 | target | 0 |  |  |  | game | `moves_sim.lua:491` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `ruinsnightmare_horn_attack` |  | moving · delay 0 · strikes until 36 | game | `moves_sim.lua:88` | modmain.lua:1047 |

