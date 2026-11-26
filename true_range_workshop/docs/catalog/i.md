# Monster catalog - I

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="ice_deer"></a>

## ice_deer

Data from: TE `moves_sim_te.lua:296`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:297` |

<a id="icedeerclops"></a>

## icedeerclops

Data from: TE `moves_sim_te.lua:299`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 34 | target | 16 | scale 1.65 · strikes only through things | deerclops_icespike_fx |  | TE | `moves_sim_te.lua:300` |
| `throw` | throw | 60 | facing | 30 | scale 1.65 | deerclops_icelance_ping_fx, deerclops_impact_circle_fx |  | TE | `moves_sim_te.lua:301` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `deerclops_icelance_ping_fx` |  | drawn with the boss move · delay 30 · strikes until 30 | TE | `moves_sim_te.lua:39` |  |
| `deerclops_icespike_fx` |  | delay 0 · strikes until 3 | TE | `moves_sim_te.lua:40` |  |
| `deerclops_impact_circle_fx` |  | lasting · delay 0 | TE | `moves_sim_te.lua:41` |  |

<a id="icehound"></a>

## icehound — Ice Hound

Data from: hand-UM `moves_hand_um.lua:74`

Drawn as: `hound`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` |  |  |  |  |  |  |  | hand-UM | `moves_hand_um.lua:80` |
| `atk_pre~quickattack` | atk_pre |  |  | 24 |  |  |  | hand-UM | `moves_hand_um.lua:74` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `glacialhound_icespike` | Ice Spike | delay 0 · strikes until 3 | UM | `moves_sim_um.lua:52` |  |

<a id="icehoundb"></a>

## icehoundb

Data from: TE `moves_sim_te.lua:303`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:304` |

