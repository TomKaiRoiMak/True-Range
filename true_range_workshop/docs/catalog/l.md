# Monster catalog - L

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="lavae"></a>

## lavae — Lavae

Data from: game `moves_sim.lua:347`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst, taunt | 21 | target | 0 |  |  |  | game | `moves_sim.lua:348` |

<a id="lavae2"></a>

## lavae2

Data from: UM `moves_sim_um.lua:237`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst, taunt | 21 | target | 0 |  |  |  | UM | `moves_sim_um.lua:238` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `lavaeslime` | Lavae Slime | lasting · delay 90 | hand-UM | `moves_hand_um.lua:132` |  |

<a id="leechswarm"></a>

## leechswarm — Leech Swarm

Data from: UM `moves_sim_um.lua:240`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pre` | attack_pre, attack_pst | 20 | target | 0 |  |  |  | UM | `moves_sim_um.lua:241` |

<a id="leif"></a>

## leif — Treeguard

Data from: game `moves_sim.lua:350` · UM `moves_sim_um.lua:243`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 25 | target | 0 |  |  |  | game | `moves_sim.lua:351` |
| `atk` ▦ | atk | 25 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:244` |
| `special` | special | 35 | facing | 0 |  |  | snare_cd | UM | `moves_sim_um.lua:245` |
| `special~summon` | special | 35 | facing | 0 |  |  | snare_cd | UM | `moves_sim_um.lua:246` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `rootspike` |  | delay 0 | UM | `moves_sim_um.lua:64` |  |

<a id="lightninggoat"></a>

## lightninggoat — Volt Goat

Data from: game `moves_sim.lua:353`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | game | `moves_sim.lua:354` |

<a id="lightninghound"></a>

## lightninghound — Lightning Hound

Data from: UM `moves_sim_um.lua:248`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:249` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `hound_lightning` | Supercharged Lightning | lasting · delay 30 | UM | `moves_sim_um.lua:55` |  |

<a id="lizardman"></a>

## lizardman

Data from: TE `moves_sim_te.lua:329`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 18 | target | 0 |  |  |  | TE | `moves_sim_te.lua:330` |
| `spit` | spit | 15 | target | 15 |  |  |  | TE | `moves_sim_te.lua:331` |

**Special code that names it:** modmain.lua:1094

<a id="lizardman_tfc"></a>

## lizardman_tfc

Data from: TE `moves_sim_te.lua:333`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 15 | target | 0 |  |  |  | TE | `moves_sim_te.lua:334` |
| `spit` | spit | 10 | target | 10 |  |  |  | TE | `moves_sim_te.lua:335` |

**Special code that names it:** modmain.lua:1091

<a id="lordfruitfly"></a>

## lordfruitfly — Lord of the Fruit Flies

Data from: game `moves_sim.lua:356`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 8 | target | 0 | scale 2 |  |  | game | `moves_sim.lua:357` |

<a id="lunar_grazer"></a>

## lunar_grazer — Grazer

Data from: game `moves_sim.lua:359`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `devour` | devour | 32 | target | 0 |  |  |  | game | `moves_sim.lua:360` |
| `spawn` | spawn | 88 | facing | 0 |  |  |  | game | `moves_sim.lua:361` |

<a id="lunarplanttentacle"></a>

## lunarplanttentacle

Data from: game `moves_sim.lua:363`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk, breach_pst | 15 | target | 0 | scale 0.55 |  |  | game | `moves_sim.lua:364` |

<a id="lunarthrall_plant"></a>

## lunarthrall_plant — Deadly Brightshade

Data from: game `moves_sim.lua:366`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_med` | atk_med | 4 | facing | 0 |  |  |  | game | `moves_sim.lua:367` |

<a id="lunarthrall_plant_vine_end"></a>

## lunarthrall_plant_vine_end — Tunneling Vine

Data from: game `moves_sim.lua:369`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 17 | facing | 0 |  |  | attack_cooldown | game | `moves_sim.lua:370` |

<a id="lureplague_rat"></a>

## lureplague_rat — Lureplague Rat

Data from: UM `moves_sim_um.lua:251`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 7 | target | 0 |  |  |  | UM | `moves_sim_um.lua:252` |

