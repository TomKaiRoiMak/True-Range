# Monster catalog - U

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="um_bee_moon"></a>

## um_bee_moon — Carrion Bee

Data from: UM `moves_sim_um.lua:470`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 |  |  |  | UM | `moves_sim_um.lua:471` |

<a id="um_beeguard_blocker"></a>

## um_beeguard_blocker — Blocker Bee

Data from: UM `moves_sim_um.lua:473` · hand-UM `moves_hand_um.lua:36`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | scale 1.6 |  |  | hand-UM | `moves_hand_um.lua:36` |
| `atk` | atk | 13 | target | 0 | scale 1.6 |  |  | UM | `moves_sim_um.lua:474` |
| `stab_pre` | stab_pre, stab, stab_pst, stuck_loop, … | 3 | facing |  | around itself · scale 1.6 |  |  | UM | `moves_sim_um.lua:475` |
| `stab_pst` | stab_pst | 3 | facing | 0 |  |  |  | hand-UM | `moves_hand_um.lua:36` |
| `stab_pst` | stab_pst, stuck_loop, stuck_pst | 3 | facing |  | around itself · scale 1.6 |  |  | UM | `moves_sim_um.lua:476` |

**Special code that names it:** simmoves.lua:3369

<a id="um_beeguard_seeker"></a>

## um_beeguard_seeker — Bomber Bee

Data from: UM `moves_sim_um.lua:478` · hand-UM `moves_hand_um.lua:47`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | scale 1.2 |  |  | hand-UM | `moves_hand_um.lua:47` |
| `atk` | atk, ascend_pre | 13 | target | 0 | scale 1.2 |  |  | UM | `moves_sim_um.lua:479` |
| `stab_death` | stab_death | 3 | facing | 0 |  |  |  | hand-UM | `moves_hand_um.lua:47` |
| `stab_death` | stab_death | 3 | facing |  | around itself · scale 1.2 |  |  | UM | `moves_sim_um.lua:480` |
| `stab_pre` | stab_pre, stab, stab_death | 3 | facing |  | around itself · scale 1.2 |  |  | UM | `moves_sim_um.lua:481` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `warningshadow` |  | moving · lasting · delay 0 | UM | `moves_sim_um.lua:83` | predict.lua:4062 predict.lua:4077 predict.lua:4096 |

**Special code that names it:** simmoves.lua:3370

<a id="um_beeguard_shooter"></a>

## um_beeguard_shooter — Bullet Bee

Data from: UM `moves_sim_um.lua:483` · hand-UM `moves_hand_um.lua:57`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | scale 1.2 |  |  | hand-UM | `moves_hand_um.lua` |
| `atk` | atk | 13 | target | 0 | scale 1.2 |  |  | UM | `moves_sim_um.lua:484` |
| `shoot_pre` | shoot_pre | 30 | target | 30 |  |  |  | hand-UM | `moves_hand_um.lua` |
| `stab_pre` | stab_pre, stab, stab_pst, stuck_loop, … | 3 | facing |  | around itself · scale 1.2 |  |  | UM | `moves_sim_um.lua:485` |
| `stab_pst` | stab_pst | 3 | facing | 0 |  |  |  | hand-UM | `moves_hand_um.lua` |
| `stab_pst` | stab_pst, stuck_loop, stuck_pst | 3 | facing |  | around itself · scale 1.2 |  |  | UM | `moves_sim_um.lua:486` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `um_beestinger_projectile` |  | moving · lasting · delay 0 | UM | `moves_sim_um.lua:71` | modmain.lua:1066 |

**Special code that names it:** modmain.lua:1066 simmoves.lua:3371

<a id="um_fern_fox"></a>

## um_fern_fox — Ferned Fox

Data from: UM `moves_sim_um.lua:488`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | UM | `moves_sim_um.lua:489` |

<a id="um_ocupus_tentacle"></a>

## um_ocupus_tentacle — Tentacle

Data from: UM `moves_sim_um.lua:491`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `clamp_counter` | clamp_counter, clamp | 29 | facing | 0 | scale 1.2 |  |  | UM | `moves_sim_um.lua:492` |

<a id="um_pepperdragon"></a>

## um_pepperdragon — Capsidragon

Data from: UM `moves_sim_um.lua:494`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `bite` | bite | 16 | target | 0 | scale 1.5 |  |  | UM | `moves_sim_um.lua:495` |
| `flame_loop` | flame_loop, flame_pst | 5 | target |  | around itself · scale 1.5 |  | flame_cd | UM | `moves_sim_um.lua:496` |
| `pound` | pound | 36 | facing | 0 | scale 1.5 |  |  | UM | `moves_sim_um.lua:497` |

**Special code that names it:** simmoves.lua:3452

<a id="um_ribopod"></a>

## um_ribopod — Ribopod

Data from: UM `moves_sim_um.lua:499`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 12 | target | 0 | scale 1.2 |  |  | UM | `moves_sim_um.lua:500` |

<a id="um_shadow_wes"></a>

## um_shadow_wes — Wes?

Data from: UM `moves_sim_um.lua:502`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `build_pre` | build_pre, build_loop, build_pst | 50 | target | 0 |  | um_shadow_balloon |  | UM | `moves_sim_um.lua:503` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `um_shadow_balloon` |  | lasting · delay 0 | UM | `moves_sim_um.lua:76` |  |

<a id="um_shambler"></a>

## um_shambler

Data from: UM `moves_sim_um.lua:505`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `eat_90s` | eat_90s | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:506` |

<a id="um_tentacle_moon"></a>

## um_tentacle_moon — Gros Tentacle

Data from: UM `moves_sim_um.lua:508`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack_land` | attack_land, attack_pst_land | 7 | target | 0 | scale 1.25 |  |  | UM | `moves_sim_um.lua:509` |
| `attack_pre_land` | attack_pre_land, attack_land, attack_pst_land | 20 | target | 0 | scale 1.25 |  |  | UM | `moves_sim_um.lua:510` |
| `attack_pre_land~attack_pre_old` | attack_pre_land, attack_land, attack_pst_land | 20 | target | 0 | scale 1.25 |  |  | UM | `moves_sim_um.lua:511` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `um_tentacle_moon_mine` |  | lasting · delay 60 | hand-UM | `moves_hand_um.lua` |  |
| `um_tentacle_moon_projectile` |  | moving · delay 20 | UM | `moves_sim_um.lua:81` |  |

<a id="um_vampirebat"></a>

## um_vampirebat — Adult Batilisk

Data from: UM `moves_sim_um.lua:513`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 11 | target | 0 | scale 0.9 |  |  | UM | `moves_sim_um.lua:514` |

<a id="uncompromising_buffrat"></a>

## uncompromising_buffrat

Data from: UM `moves_sim_um.lua:516`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1, attack1_pst | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:517` |
| `attack2` | attack2, attack2_pst | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:518` |
| `attack3` | attack3 | 7 | target | 0 |  |  |  | UM | `moves_sim_um.lua:519` |
| `bellyflop_block_pre` | bellyflop_block_pre, bellyflop, taunt | 19 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:520` |
| `bellyflop_pre` | bellyflop_pre, bellyflop, taunt | 19 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:521` |
| `block_counter` | block_counter | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:522` |
| `block_pst` | block_pst, taunt2 | 12 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:523` |

<a id="uncompromising_caverat"></a>

## uncompromising_caverat — Cave Rat

Data from: UM `moves_sim_um.lua:525`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 7 | target | 0 |  |  |  | UM | `moves_sim_um.lua:526` |

<a id="uncompromising_junkrat"></a>

## uncompromising_junkrat

Data from: UM `moves_sim_um.lua:528`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 7 | target | 0 | scale 1.25 |  |  | UM | `moves_sim_um.lua:529` |

<a id="uncompromising_packrat"></a>

## uncompromising_packrat — Pack Rat

Data from: UM `moves_sim_um.lua:531`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 7 | target | 0 |  |  |  | UM | `moves_sim_um.lua:532` |

<a id="uncompromising_rat"></a>

## uncompromising_rat — Rat

Data from: UM `moves_sim_um.lua:534`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 7 | target | 0 |  |  |  | UM | `moves_sim_um.lua:535` |

<a id="uncompromising_toad"></a>

## uncompromising_toad — Sickly Frog

Data from: UM `moves_sim_um.lua:537`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 25 | target | 0 |  |  |  | UM | `moves_sim_um.lua:538` |

