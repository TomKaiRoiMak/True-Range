# Monster catalog - G

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="gatorsnake"></a>

## gatorsnake

Data from: UM `moves_sim_um.lua:204`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk, head_idle_pst, atk_pre | 25 | target |  | moves 1.0 |  |  | UM | `moves_sim_um.lua:205` |

<a id="gestalt"></a>

## gestalt — Gestalt

Data from: game `moves_sim.lua:306`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack, mutate | 8 | target |  | moves 11.2 |  |  | game | `moves_sim.lua:307` |

**Special code that names it:** modmain.lua:688 modmain.lua:711

<a id="gestalt_guard"></a>

## gestalt_guard — Greater Gestalt

Data from: game `moves_sim.lua:309`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack, mutate | 8 | target |  | scale 0.8 · moves 9.7 |  |  | game | `moves_sim.lua:310` |

<a id="gestalt_guard_evolved"></a>

## gestalt_guard_evolved — Inimical Gestalt

Data from: game `moves_sim.lua:312`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 15 | target | 0 | scale 0.8 · moves 5.3 |  |  | game | `moves_sim.lua:313` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `gestalt_guard_projectile` |  | delay 0 · strikes until 49 | game | `moves_sim.lua:76` |  |

<a id="giantgrub"></a>

## giantgrub

Data from: TE `moves_sim_te.lua:223`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `action` | action | 4 | target | 0 | scale 3 |  |  | TE | `moves_sim_te.lua:224` |
| `exit` | exit | 22 | facing | 0 | scale 3 |  |  | TE | `moves_sim_te.lua:225` |

<a id="giantsnow"></a>

## giantsnow

Data from: TE `moves_sim_te.lua:227`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `action` | action | 4 | target | 0 | scale 3 |  |  | TE | `moves_sim_te.lua:228` |

<a id="glacialhound"></a>

## glacialhound — Glacial Varglet

Data from: UM `moves_sim_um.lua:207`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 | scale 1.3 |  |  | UM | `moves_sim_um.lua:208` |
| `atk_pre~ice_howl_attack` | atk_pre | 8 | target | 5 | scale 1.3 · strikes only through things | glacialhound_icespike |  | UM | `moves_sim_um.lua:209` |
| `scared_pre` | scared_pre, scared_loop, scared_pst | 51 | target | 49 | scale 1.3 · strikes only through things | glacialhound_icespike | lightningshot_cooldown | UM | `moves_sim_um.lua:210` |
| `scared_pst` | scared_pst | 12 | target | 10 | scale 1.3 · strikes only through things | glacialhound_icespike |  | UM | `moves_sim_um.lua:211` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `glacialhound_icespike` | Ice Spike | delay 0 · strikes until 3 | UM | `moves_sim_um.lua:52` |  |

<a id="glowfly"></a>

## glowfly

Data from: TE `moves_sim_te.lua:230`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 | scale 0.6 |  |  | TE | `moves_sim_te.lua:231` |

<a id="glowfly_cocoon"></a>

## glowfly_cocoon

Data from: TE `moves_sim_te.lua:233`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 | scale 0.6 |  |  | TE | `moves_sim_te.lua:234` |

<a id="gnarwail"></a>

## gnarwail — Gnarwail

Data from: game `moves_sim.lua:315` · TE `moves_sim_te.lua:236`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack_2` | attack_2 | 33 | target | 0 |  |  |  | game | `moves_sim.lua:316` |
| `attack_2` | attack_2 | 33 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:237` |

<a id="gnarwailunderwater"></a>

## gnarwailunderwater

Data from: TE `moves_sim_te.lua:239`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack_2` | attack_2 | 33 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:240` |
| `attack_2~body_slam` | attack_2 | 33 | target | 0 |  |  |  | TE | `moves_sim_te.lua:241` |
| `attack_2~body_slam_hide` | attack_2 | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:242` |
| `bite` | bite | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:243` |

<a id="gnat"></a>

## gnat

Data from: TE `moves_sim_te.lua:245`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pre` | attack_pre, attack_pst | 20 | target | 0 |  |  |  | TE | `moves_sim_te.lua:246` |

<a id="goddess_deer"></a>

## goddess_deer

Data from: TE `moves_sim_te.lua:248`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 | scale 0.8 |  |  | TE | `moves_sim_te.lua:249` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `greentornado2` |  | moving · lasting · delay 0 | TE | `moves_sim_te.lua:45` |  |

<a id="goddess_deer_gem"></a>

## goddess_deer_gem

Data from: TE `moves_sim_te.lua:251`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:252` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `greentornado2` |  | moving · lasting · delay 0 | TE | `moves_sim_te.lua:45` |  |

<a id="goddess_spider_hostile"></a>

## goddess_spider_hostile

Data from: TE `moves_sim_te.lua:254`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:255` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua:256` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | lane |  |  | TE | `moves_sim_te.lua:257` |

<a id="goddess_sword"></a>

## goddess_sword

Data from: TE `moves_sim_te.lua:259`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 | scale 2.3 |  |  | TE | `moves_sim_te.lua:260` |

<a id="goldbishop"></a>

## goldbishop

Data from: TE `moves_sim_te.lua:262`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk2_pre` | atk2_pre, atk2_loop, atk2_pst | 31 | facing | 25 | follows target | bishop_targeting_fx |  | TE | `moves_sim_te.lua:263` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `bishop_targeting_fx` |  | drawn with the boss move · delay 25 · strikes until 25 | TE | `moves_sim_te.lua:37` |  |

<a id="goldfish_alive"></a>

## goldfish_alive

Data from: TE `moves_sim_te.lua:265`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `walk_loop` | walk_loop | 10 | target | 0 | scale 1 |  |  | TE | `moves_sim_te.lua:266` |

<a id="goldmonkey"></a>

## goldmonkey

Data from: TE `moves_sim_te.lua:268`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 17 | target | 0 |  |  |  | TE | `moves_sim_te.lua:269` |

<a id="grabbing_vine"></a>

## grabbing_vine

Data from: TE `moves_sim_te.lua:271`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 15 | target | 0 |  |  |  | TE | `moves_sim_te.lua:272` |

<a id="grabbing_vinefixo"></a>

## grabbing_vinefixo

Data from: TE `moves_sim_te.lua:274`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 15 | target | 0 |  |  |  | TE | `moves_sim_te.lua:275` |

<a id="grassgator"></a>

## grassgator — Grass Gator

Data from: game `moves_sim.lua:318`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 15 | target | 0 |  |  |  | game | `moves_sim.lua:319` |

<a id="greententacle"></a>

## greententacle

Data from: TE `moves_sim_te.lua:277`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_loop` | atk_loop, atk_idle | 7 | target | 0 |  |  |  | TE | `moves_sim_te.lua:278` |
| `atk_pre` | atk_pre, atk_loop, atk_idle | 32 | target | 0 |  |  |  | TE | `moves_sim_te.lua:279` |

**Special code that names it:** modmain.lua:1082

<a id="gw_yellow_lizardman"></a>

## gw_yellow_lizardman

Data from: TE `moves_sim_te.lua:281`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 18 | target | 0 | scale 1.2 |  |  | TE | `moves_sim_te.lua:282` |

**Special code that names it:** modmain.lua:923

