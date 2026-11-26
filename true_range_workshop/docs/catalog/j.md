# Monster catalog - J

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="jungletreeguard"></a>

## jungletreeguard

Data from: TE `moves_sim_te.lua:306`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 37 | target | 0 |  |  |  | TE | `moves_sim_te.lua:307` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `warningshadow` |  | moving · lasting · delay 0 · strikes until 60 | TE | `moves_sim_te.lua:58` | predict.lua:4062 predict.lua:4077 predict.lua:4096 |

**Special code that names it:** predict.lua:4069

