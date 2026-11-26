# Monster catalog - D

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="daywalker"></a>

## daywalker — Nightmare Werepig

Data from: game `moves_sim.lua:243`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk3` | atk3, atk3_pst | 1 | facing | 0 |  |  |  | game | `moves_sim.lua:244` |
| `atk_slam` | atk_slam | 26 | facing | 20 | follows target |  |  | game | `moves_sim.lua:245` |
| `atk_slam_pre` | atk_slam_pre, atk_slam | 47 | facing | 41 | follows target |  |  | game | `moves_sim.lua:246` |
| `shrug1` | shrug1, shrug_pst | 7 | facing | 0 |  |  |  | game | `moves_sim.lua:247` |
| `struggle1` | struggle1, struggle1_pst | 5 | facing | 0 |  |  |  | game | `moves_sim.lua:248` |

<a id="daywalker2"></a>

## daywalker2 — Scrappy Werepig

Data from: game `moves_sim.lua:250`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk3` ▦ | atk3, atk3_pst | 1 | facing | 0 |  |  |  | game | `moves_sim.lua:251` |
| `atk_object` ▦ | atk_object, atk_object_pst | 16 | target | 0 |  | daywalker2_swipe_fx |  | game | `moves_sim.lua:252` |
| `laser_pre` | laser_pre, laser_pst, hit | 36 | target | 36 |  | alterguardian_laser, alterguardian_laserempty |  | game | `moves_sim.lua:253` |
| `laser_pst` | laser_pst, hit | 5 | target | 5 |  | alterguardian_laser, alterguardian_laserempty |  | game | `moves_sim.lua:254` |
| `tackle_pre` | tackle_pre, tackle, tackle_lift, hit | 8 | facing | 19 |  |  |  | game | `moves_sim.lua:255` |
| `throw_pre` ▦ | throw_pre, throw, throw_pst | 106 | facing | 86 | strikes only through things | junkball_fall_fx, junkball_fx |  | game | `moves_sim.lua:256` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `daywalker2_swipe_fx` |  | drawn with the boss move · delay 4 · strikes until 4 | game | `moves_sim.lua:62` |  |
| `junkball_fall_fx` |  | delay 15 · strikes until 15 | game | `moves_sim.lua:81` |  |

<a id="deer"></a>

## deer — No-Eyed Deer

Data from: game `moves_sim.lua:258`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | game | `moves_sim.lua:259` |

<a id="deer_blue"></a>

## deer_blue

Data from: game `moves_sim.lua:261`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | game | `moves_sim.lua:262` |
| `atk_magic_pre` ▦ | atk_magic_pre | 20 | target | 21 | follows target | deer_ice_circle | deercast_cd | game | `moves_sim.lua:263` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `deer_ice_circle` |  | lasting · delay 0 | game | `moves_sim.lua:65` | simmoves.lua:4616 |

<a id="deer_red"></a>

## deer_red

Data from: game `moves_sim.lua:265`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | game | `moves_sim.lua:266` |
| `atk_magic_pre` ▦ | atk_magic_pre, atk_magic_pst | 83 | target | 54 | follows target | deer_fire_circle | deercast_cd | game | `moves_sim.lua:267` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `deer_fire_circle` |  | lasting · delay 30 | game | `moves_sim.lua:64` |  |

<a id="deerclops"></a>

## deerclops — Deerclops

Data from: game `moves_sim.lua:269` · UM `moves_sim_um.lua:175` · hand-UM

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 34 | target | 16 | scale 1.65 · strikes only through things | deerclops_icespike_fx |  | game | `moves_sim.lua:270` |
| `atk2@MakeEnrageable` | atk2 | 19 | target | 18 | scale 1.85 | deerclops_laser_blue, deerclops_laserempty |  | UM | `moves_sim_um.lua:176` |
| `atk@MakeIcey` | atk | 35 | target | 0 | scale 1.65 |  |  | UM | `moves_sim_um.lua:177` |
| `atk@MakeStrong` | atk | 34 | facing | 16 | scale 1.65 · strikes only through things | deerclops_icespike_fx |  | UM | `moves_sim_um.lua:178` |
| `fortresscast_pre@MakeIcey` | fortresscast_pre, fortresscast_loop | 0 | target | 0 | scale 1.65 | deer_ice_circle |  | UM | `moves_sim_um.lua:179` |
| `ring_pre@MakeEnrageable` | ring_pre, ring_loop, taunt | 31 | facing | 0 | scale 1.85 | deerclops_laser_blue, deerclops_laserempty_blue |  | UM | `moves_sim_um.lua:180` |
| `throw` | throw | 60 | facing | 30 | scale 1.65 | deerclops_icelance_ping_fx, deerclops_impact_circle_fx |  | game | `moves_sim.lua:271` |
| `throw` | throw | 60 | facing | 30 | scale 1.85 | deerclops_icelance_ping_fx, deerclops_impact_circle_fx |  | UM | `moves_sim_um.lua:181` |
| `uppercut@MakeStrong` | uppercut | 35 | target |  | around itself · scale 1.65 |  |  | UM | `moves_sim_um.lua:182` |
| `uppercutcombo@MakeStrong` |  |  |  |  |  |  |  | hand-UM | `moves_hand_um.lua` |
| `uppercutcombo@MakeStrong` | uppercutcombo | 35 | target | 61 | follows target · scale 1.65 |  |  | UM | `moves_sim_um.lua:183` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `deer_ice_circle` |  | lasting · delay 0 | UM | `moves_sim_um.lua:39` | simmoves.lua:4616 |
| `deerclops_icelance_ping_fx` |  | drawn with the boss move · delay 30 · strikes until 30 | UM | `moves_sim_um.lua:40` |  |
| `deerclops_icelance_ping_fx` |  | drawn with the boss move · delay 30 · strikes until 30 | game | `moves_sim.lua:66` |  |
| `deerclops_icelance_ping_fx` |  | drawn with the boss move · delay 30 · strikes until 30 | TE | `moves_sim_te.lua:39` |  |
| `deerclops_icespike_fx` |  | delay 0 · strikes until 3 | TE | `moves_sim_te.lua:40` |  |
| `deerclops_icespike_fx` |  | delay 0 · strikes until 3 | game | `moves_sim.lua:67` |  |
| `deerclops_icespike_fx` |  | delay 0 · strikes until 3 | UM | `moves_sim_um.lua:41` |  |
| `deerclops_impact_circle_fx` |  | lasting · delay 0 | UM | `moves_sim_um.lua:42` |  |
| `deerclops_impact_circle_fx` |  | lasting · delay 0 | TE | `moves_sim_te.lua:41` |  |
| `deerclops_impact_circle_fx` |  | lasting · delay 0 | game | `moves_sim.lua:68` |  |
| `deerclops_laser_blue` |  | drawn with the boss move · delay 0 · strikes until 73 | UM | `moves_sim_um.lua:43` |  |
| `deerclops_laserempty` |  | drawn with the boss move · delay 0 · strikes until 0 | UM | `moves_sim_um.lua:44` |  |
| `deerclops_laserempty_blue` |  | drawn with the boss move · delay 0 · strikes until 0 | UM | `moves_sim_um.lua:45` |  |

<a id="deprecated_swilson"></a>

## deprecated_swilson

Data from: UM `moves_sim_um.lua:185`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk, walk_loop | 13 | target | 0 |  |  |  | UM | `moves_sim_um.lua:186` |
| `atk~leap_attack` | atk, idle | 19 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:187` |

<a id="doydoybaby"></a>

## doydoybaby

Data from: TE `moves_sim_te.lua:176`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 0 |  |  |  | TE | `moves_sim_te.lua:177` |

<a id="dragonfly"></a>

## dragonfly — Dragonfly

Data from: game `moves_sim.lua:273`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 | scale 1.3 |  |  | game | `moves_sim.lua:274` |
| `atk@TransformFire` | atk | 15 | target | 0 | scale 1.3 |  |  | game | `moves_sim.lua:275` |
| `taunt_pre@TransformFire` | taunt_pre, taunt, taunt_pst | 20 | facing | 0 | scale 1.3 |  | groundpound_cd | game | `moves_sim.lua:276` |

<a id="dragoon"></a>

## dragoon

Data from: TE `moves_sim_te.lua:179`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 | scale 1.3 |  |  | TE | `moves_sim_te.lua:180` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `dragoonspit` |  | lasting · delay 0 | TE | `moves_sim_te.lua:43` | simmoves.lua:3362 |

<a id="dreadeye"></a>

## dreadeye — Dread Eye

Data from: UM `moves_sim_um.lua:189`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:190` |

