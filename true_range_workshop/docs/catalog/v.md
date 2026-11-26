# Monster catalog - V

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="vampirebat"></a>

## vampirebat

Data from: TE `moves_sim_te.lua:635`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 14 | target | 0 | scale 0.9 |  |  | TE | `moves_sim_te.lua:636` |

<a id="vault_crawler"></a>

## vault_crawler — Lustrous Weevil

Data from: game `moves_sim.lua:637`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 13 | facing | 7 |  |  |  | game | `moves_sim.lua:638` |
| `spawn` | spawn | 0 | facing |  | around itself |  |  | game | `moves_sim.lua:639` |

<a id="vault_pillar_guard"></a>

## vault_pillar_guard — Ancient Guard Tower

Data from: game `moves_sim.lua:641`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_1` ▦ | atk_1 | 29 | target | 0 |  |  |  | game | `moves_sim.lua:642` |
| `atk_2` ▦ | atk_2, atk_3_pre_a | 26 | target | 0 |  |  |  | game | `moves_sim.lua:643` |
| `atk_3_pre_a` | atk_3_pre_a, atk_3, atk_3_pst | 45 | target | 31 | follows target |  | quickjump_cd | game | `moves_sim.lua:644` |
| `atk_3_pre_b` ▦ | atk_3_pre_b, atk_3, atk_3_pst | 45 | target | 31 | follows target |  | quickjump_cd | game | `moves_sim.lua:645` |
| `spin_loop` | spin_loop, spin_pst | 0 | facing |  | around itself |  | spin_cd | game | `moves_sim.lua:646` |
| `spin_pre` | spin_pre | 25 | facing | 0 |  |  | spin_cd | game | `moves_sim.lua:647` |

<a id="viperling"></a>

## viperling — Writhing Apparition

Data from: UM `moves_sim_um.lua:540`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | scale 0.5 |  |  | UM | `moves_sim_um.lua:541` |

<a id="viperlingfriend"></a>

## viperlingfriend — Writhing Apparition

Data from: UM `moves_sim_um.lua:543`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | scale 0.5 |  |  | UM | `moves_sim_um.lua:544` |

<a id="viperworm"></a>

## viperworm — Depths Viper

Data from: UM `moves_sim_um.lua:546`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | UM | `moves_sim_um.lua:547` |

