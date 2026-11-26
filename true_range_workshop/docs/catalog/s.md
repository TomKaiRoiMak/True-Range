# Monster catalog - S

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="scorpion"></a>

## scorpion

Data from: TE `moves_sim_te.lua:488`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:489` |
| `atk~leap_attack` | atk, taunt | 19 | target | 0 | follows target |  |  | TE | `moves_sim_te.lua:490` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua:491` |
| `tail` | tail | 20 | target | 0 |  |  |  | TE | `moves_sim_te.lua:492` |

<a id="sea_eel"></a>

## sea_eel

Data from: TE `moves_sim_te.lua:494`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 30 | target | 0 | scale 0.3 |  |  | TE | `moves_sim_te.lua:495` |

<a id="seaquaketentacle"></a>

## seaquaketentacle

Data from: TE `moves_sim_te.lua:497`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk_loop, atk_idle | 32 | target | 0 |  |  |  | TE | `moves_sim_te.lua:498` |

<a id="seatentacle"></a>

## seatentacle

Data from: TE `moves_sim_te.lua:500`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk_loop, atk_idle | 32 | target | 0 |  |  |  | TE | `moves_sim_te.lua:501` |

<a id="shadow_bishop"></a>

## shadow_bishop — Shadow Bishop

Data from: game `moves_sim.lua:493` · UM `moves_sim_um.lua:369`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_side_pre` | atk_side_pre, atk_side_loop_pre, atk_side_loop, atk_side_pst | 35 | target |  | follows target · around itself · moves 1.0 |  |  | game | `moves_sim.lua:494` |
| `atk_side_pre` | atk_side_pre, atk_side_loop_pre, atk_side_loop, atk_side_loop_pst, … | 35 | facing |  | follows target · charge legs · around itself · moves 6.2 |  |  | UM | `moves_sim_um.lua:370` |
| `atk_side_pre@LevelUp` | atk_side_pre, atk_side_loop_pre, atk_side_loop, atk_side_pst | 35 | target |  | follows target · around itself · scale 1.6 · moves 1.0 |  |  | game | `moves_sim.lua:495` |
| `atk_side_pre@LevelUp` | atk_side_pre, atk_side_loop_pre, atk_side_loop, atk_side_loop_pst, … | 35 | facing |  | follows target · charge legs · around itself · scale 1.6 · moves 8.8 |  |  | UM | `moves_sim_um.lua:371` |
| `atk_side_pre@LevelUp,LevelUp` | atk_side_pre, atk_side_loop_pre, atk_side_loop, atk_side_pst | 35 | target |  | follows target · around itself · scale 2.2 · moves 1.0 |  |  | game | `moves_sim.lua:496` |
| `atk_side_pre@LevelUp,LevelUp` | atk_side_pre, atk_side_loop_pre, atk_side_loop, atk_side_loop_pst, … | 35 | facing |  | follows target · charge legs · around itself · scale 2.2 · moves 9.8 |  |  | UM | `moves_sim_um.lua:372` |

<a id="shadow_knight"></a>

## shadow_knight — Shadow Knight

Data from: game `moves_sim.lua:498`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 3 | target |  |  |  |  | game | `moves_sim.lua:499` |
| `atk@LevelUp` | atk | 3 | target |  | scale 1.7 |  |  | game | `moves_sim.lua:500` |
| `atk@LevelUp,LevelUp` | atk | 3 | target |  | scale 2.5 |  |  | game | `moves_sim.lua:501` |
| `atk_plus` | atk_plus | 5 | target | 0 |  |  |  | game | `moves_sim.lua:502` |
| `atk_plus@LevelUp` ▦ | atk_plus | 5 | target | 0 | scale 1.7 |  |  | game | `moves_sim.lua:503` |
| `atk_plus@LevelUp,LevelUp` | atk_plus | 5 | target | 0 | scale 2.5 |  |  | game | `moves_sim.lua:504` |
| `atk_pre` | atk_pre, atk | 17 | target | 0 |  |  |  | game | `moves_sim.lua:505` |
| `atk_pre@LevelUp` | atk_pre, atk | 17 | target | 0 | scale 1.7 |  |  | game | `moves_sim.lua:506` |
| `atk_pre@LevelUp,LevelUp` | atk_pre, atk | 17 | target | 0 | scale 2.5 |  |  | game | `moves_sim.lua:507` |

<a id="shadow_leech"></a>

## shadow_leech — Parasitic Shadeling

Data from: game `moves_sim.lua:509`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|

<a id="shadow_rook"></a>

## shadow_rook — Shadow Rook

Data from: game `moves_sim.lua:510`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `teleport_pre` | teleport_pre, teleport, teleport_atk, teleport_pst | 48 | facing | 32 | cone · moves 1.0 |  |  | game | `moves_sim.lua:511` |
| `teleport_pre@LevelUp` | teleport_pre, teleport, teleport_atk, teleport_pst | 48 | facing | 32 | cone · scale 1.2 · moves 1.0 |  |  | game | `moves_sim.lua:512` |
| `teleport_pre@LevelUp,LevelUp` | teleport_pre, teleport, teleport_atk, teleport_pst | 48 | facing | 32 | cone · scale 1.6 · moves 1.0 |  |  | game | `moves_sim.lua:513` |

<a id="shadow_wixie"></a>

## shadow_wixie — Wixie?

Data from: UM `moves_sim_um.lua:374` · hand-UM `moves_hand_um.lua:87`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `slingshot_pre` |  |  |  |  |  |  |  | hand-UM | `moves_hand_um.lua:87` |
| `slingshot_pre` | slingshot_pre, slingshot | 15 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:375` |
| `spearjab` | spearjab, emote_laugh | 1 | target | 0 |  |  |  | UM | `moves_sim_um.lua:376` |
| `staff_pre` | staff_pre, staff, spearjab_pre, spearjab, … | 62 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:377` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `bagofwarbles` |  | moving · lasting · delay 16 | UM | `moves_sim_um.lua:35` |  |
| `slipperymarbles` |  | delay 3 | UM | `moves_sim_um.lua:67` |  |
| `wixie_shadow_shot` |  | moving · lasting · delay 0 · strikes until 60 | UM | `moves_sim_um.lua:85` |  |

<a id="shadowtentacle"></a>

## shadowtentacle — Shadow Tentacle

Data from: game `moves_sim.lua:515`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk_loop, atk_idle, atk_pst | 37 | target | 0 | scale 0.5 |  |  | game | `moves_sim.lua:516` |

<a id="shadowthrall_hands"></a>

## shadowthrall_hands — Ink Blight

Data from: game `moves_sim.lua:518` · hand `moves_hand.lua:80`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `portal_appear` | portal_appear, run_loop, shrouden_disappear | 11 | facing | 0 |  |  |  | hand | `moves_hand.lua:80` |
| `run_pre` | run_pre, run_loop, run_pst | 15 | facing | 0 |  |  |  | game | `moves_sim.lua:519` |

<a id="shadowthrall_horns"></a>

## shadowthrall_horns — Ink Blight

Data from: game `moves_sim.lua:521` · hand `moves_hand.lua:69`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `appear` | appear | 47 | facing | 0 |  |  |  | game | `moves_sim.lua:522` |
| `jump` ▦ | jump, jump_pst | 29 | facing | 6 | follows target · moves 1.1 |  |  | game | `moves_sim.lua:523` |
| `shrouden_jump` | shrouden_jump, shrouden_jump_pst | 11 | target | 1 | moves 4.2 |  |  | hand | `moves_hand.lua:69` |
| `slap` | slap | 14 | facing | 0 |  |  |  | game | `moves_sim.lua:524` |

**Special code that names it:** simmoves.lua:28

<a id="shadowthrall_mouth"></a>

## shadowthrall_mouth — Ink Blight

Data from: game `moves_sim.lua:526` · hand `moves_hand.lua:75`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `bite_final` | bite_final | 6 | facing | 0 |  |  |  | hand | `moves_hand.lua:75` |
| `bite_pre` | bite_pre, bite_loop, bite_final | 19 | facing |  | around itself |  |  | game | `moves_sim.lua:527` |
| `land` | land | 0 | facing |  | around itself |  |  | game | `moves_sim.lua:528` |
| `leap_pre` | leap_pre, land | 38 | target | 25 | follows target · moves 1.0 |  | leap_cd | game | `moves_sim.lua:529` |
| `portal_appear` | portal_appear | 8 | facing | 0 |  |  |  | hand | `moves_hand.lua:75` |
| `shrouden_disappear` | shrouden_disappear | 6 | facing | 0 |  |  |  | hand | `moves_hand.lua:75` |
| `stalk_bite` | stalk_bite | 22 | facing | 0 |  |  |  | game | `moves_sim.lua:530` |

**Special code that names it:** simmoves.lua:3669

<a id="shadowthrall_wings"></a>

## shadowthrall_wings — Ink Blight

Data from: game `moves_sim.lua:532`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `shadowthrall_projectile_fx` |  | moving · delay 21 · strikes until 31 | game | `moves_sim.lua:92` | simmoves.lua:39 |

<a id="shark"></a>

## shark — Rockjaw

Data from: game `moves_sim.lua:533` · UM `moves_sim_um.lua:379`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 12 | target | 0 |  |  | getdistance | game | `moves_sim.lua:534` |
| `attack` | attack | 12 | facing | 0 |  |  | getdistance | UM | `moves_sim_um.lua:380` |
| `attack~bite` | attack, idle | 12 | target | 0 |  |  |  | game | `moves_sim.lua:535` |
| `attack~bite` | attack, idle | 12 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:381` |

<a id="sharkboi"></a>

## sharkboi — Frostjaw

Data from: game `moves_sim.lua:537`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk1` | atk1 | 16 | target | 0 |  | sharkboi_swipe_fx |  | game | `moves_sim.lua:538` |
| `atk2` ▦ | atk2, atk2_delay | 4 | facing | 0 |  | sharkboi_swipe_fx |  | game | `moves_sim.lua:539` |
| `atk3` ▦ | atk3 | 12 | facing | 0 |  |  |  | game | `moves_sim.lua:540` |
| `icedive_jump_pre` | icedive_jump_pre, icedive_jump, icedive_dig_pre, icedive_dig_loop | 3 | facing | 6 | cone · moves 2.0 |  | standing_dive_cd | game | `moves_sim.lua:541` |
| `icedive_standing_jump_pre` | icedive_standing_jump_pre, icedive_jump, icedive_dig_pre, icedive_dig_loop | 33 | facing | 14 | follows target · cone · moves 1.8 |  | standing_dive_cd | game | `moves_sim.lua:542` |
| `torpedo_pre` | torpedo_pre, torpedo_jump, torpedo_loop, torpedo_climb | 34 | facing | 34 | moves 20.4 |  | torpedo_cd | game | `moves_sim.lua:543` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `sharkboi_swipe_fx` |  | drawn with the boss move · delay 4 · strikes until 4 | game | `moves_sim.lua:93` |  |

<a id="sharkitten"></a>

## sharkitten

Data from: TE `moves_sim_te.lua:503`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:504` |

<a id="sharx"></a>

## sharx

Data from: TE `moves_sim_te.lua:506`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:507` |

<a id="sharxunderwater"></a>

## sharxunderwater

Data from: TE `moves_sim_te.lua:509`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:510` |

<a id="shockworm"></a>

## shockworm — Depths Eel

Data from: UM `moves_sim_um.lua:383`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | UM | `moves_sim_um.lua:384` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `um_shock_projectile` |  | delay 3 | UM | `moves_sim_um.lua:78` |  |

<a id="shrouden"></a>

## shrouden — Umbral Abomination

Data from: game `moves_sim.lua:545`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `optic_blast_pre1` | optic_blast_pre1, optic_blast_pre2, optic_blast_loop, optic_blast_pst, … | 45 | facing | 116 | follows target · cone · moves 1.0 |  | opticblastcd | game | `moves_sim.lua:546` |
| `punch_pre` | punch_pre, punch_loop, punch_pst | 19 | target | 1 |  |  | portalcd | game | `moves_sim.lua:547` |
| `teleport_pre` | teleport_pre, teleport_loop, teleport_pst | 57 | target | 60 | moves 1.0 |  | teleportcd | game | `moves_sim.lua:548` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `charliearena_spike` | Dreadstone Outcrop | delay 29 | game | `moves_sim.lua:61` | simmoves.lua:3377 |
| `shrouden_optic_blast_fx` |  | lasting · drawn with the boss move · delay 26 · strikes until 90 | game | `moves_sim.lua:94` | simmoves.lua:3483 simmoves.lua:3484 simmoves.lua:3486 |

**Special code that names it:** simmoves.lua:3473

<a id="sinheniddnadtdfo"></a>

## sinheniddnadtdfo

Data from: UM `moves_sim_um.lua:386`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 3 | target |  | scale 2 |  |  | UM | `moves_sim_um.lua:387` |

<a id="slip"></a>

## slip

Data from: TE `moves_sim_te.lua:512`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `eat_pre` | eat_pre, taunt | 19 | target | 0 |  |  |  | TE | `moves_sim_te.lua:513` |
| `eat_pre~attack` | eat_pre | 18 | target | 0 |  |  |  | TE | `moves_sim_te.lua:514` |
| `eat_pre~spitter_attack` | eat_pre, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua:515` |

<a id="slipstor"></a>

## slipstor

Data from: TE `moves_sim_te.lua:517`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `anim` | anim, idle_loop | 11 | target | 0 |  |  |  | TE | `moves_sim_te.lua:518` |

<a id="slurper"></a>

## slurper — Slurper

Data from: game `moves_sim.lua:550`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 30 | facing | 0 | moves 6.7 |  |  | game | `moves_sim.lua:551` |
| `headslurp` | headslurp | 23 | facing | 0 | moves 2.0 |  |  | game | `moves_sim.lua:552` |

<a id="slurtle"></a>

## slurtle — Slurtle

Data from: game `moves_sim.lua:554`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 |  |  |  | game | `moves_sim.lua:555` |

**Special code that names it:** simmoves.lua:171

<a id="smallbird"></a>

## smallbird — Smallbird

Data from: game `moves_sim.lua:557` · hand `moves_hand.lua:43`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | game | `moves_sim.lua:558` |
| `chase` | walk_loop, idle_loop, walk_pre |  | facing |  | charge legs |  |  | hand | `moves_hand.lua` |

<a id="snaildrake_magma"></a>

## snaildrake_magma — Snaildrake

Data from: UM `moves_sim_um.lua:389`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 | scale 1.2 |  |  | UM | `moves_sim_um.lua:390` |

<a id="snaildrake_slime"></a>

## snaildrake_slime — Snaildrake

Data from: UM `moves_sim_um.lua:392`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 | scale 1.2 |  |  | UM | `moves_sim_um.lua:393` |

<a id="snake"></a>

## snake

Data from: TE `moves_sim_te.lua:520`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst | 27 | target | 0 |  |  |  | TE | `moves_sim_te.lua:521` |

<a id="snake_amphibious"></a>

## snake_amphibious

Data from: TE `moves_sim_te.lua:523`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst | 27 | target | 0 |  |  |  | TE | `moves_sim_te.lua:524` |

<a id="snake_poison"></a>

## snake_poison

Data from: TE `moves_sim_te.lua:526`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst | 27 | target | 0 |  |  |  | TE | `moves_sim_te.lua:527` |

<a id="snapdragon"></a>

## snapdragon

Data from: TE `moves_sim_te.lua:529`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 15 | target | 0 | scale 1.22 |  |  | TE | `moves_sim_te.lua:530` |

<a id="snapperturtle"></a>

## snapperturtle — Snapper Turtle

Data from: UM `moves_sim_um.lua:395`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 8 | target | 0 | scale 1 |  |  | UM | `moves_sim_um.lua:396` |
| `spin_pre` | spin_pre, spin_loop, spin_pst | 16 | facing |  | around itself · scale 1 · moves 2.0 |  |  | UM | `moves_sim_um.lua:397` |
| `spin_pst` | spin_pst | 16 | target | 0 | scale 1 |  |  | UM | `moves_sim_um.lua:398` |

**Special code that names it:** simmoves.lua:3667

<a id="snapperturtlebaby"></a>

## snapperturtlebaby — Whippersnapper Turtle

Data from: UM `moves_sim_um.lua:400`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 8 | target | 0 | scale 0.6 |  |  | UM | `moves_sim_um.lua:401` |
| `spin_pre` | spin_pre, spin_loop, spin_pst | 16 | facing |  | around itself · scale 0.6 · moves 2.3 |  |  | UM | `moves_sim_um.lua:402` |
| `spin_pst` | spin_pst | 16 | target | 0 | scale 0.6 |  |  | UM | `moves_sim_um.lua:403` |

**Special code that names it:** simmoves.lua:3667

<a id="snowgoat"></a>

## snowgoat

Data from: TE `moves_sim_te.lua:532`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:533` |

<a id="snowmong"></a>

## snowmong — Abominamole

Data from: UM `moves_sim_um.lua:405`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `action` | action | 8 | target | 0 | scale 2 |  |  | UM | `moves_sim_um.lua:406` |
| `exit` | exit | 22 | facing | 0 | scale 2 |  |  | UM | `moves_sim_um.lua:407` |

<a id="snowperd"></a>

## snowperd

Data from: TE `moves_sim_te.lua:535`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 0 |  |  |  | TE | `moves_sim_te.lua:536` |

<a id="snowwarg"></a>

## snowwarg

Data from: TE `moves_sim_te.lua:538`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 11 | target | 0 |  |  |  | TE | `moves_sim_te.lua:539` |

<a id="snurtle"></a>

## snurtle — Snurtle

Data from: game `moves_sim.lua:560`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 |  |  |  | game | `moves_sim.lua:561` |

**Special code that names it:** simmoves.lua:171

<a id="spat"></a>

## spat — Ewecus

Data from: game `moves_sim.lua:563` · hand `moves_hand.lua:47`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `snot_pre` | snot_pre, snot, snot_pst | 27 | target | 27 |  |  |  | hand | `moves_hand.lua:47` |
| `strike` | strike, strike_pst | 5 | target | 0 |  |  |  | game | `moves_sim.lua:564` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `spat_bomb` |  | moving · delay 0 · strikes until 15 | game | `moves_sim.lua:96` |  |

**Special code that names it:** simmoves.lua:3546

<a id="spider"></a>

## spider — Spider

Data from: game `moves_sim.lua:566` · UM `moves_sim_um.lua:409`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 25 | target | 0 |  |  |  | game | `moves_sim.lua:567` |
| `hide` | hide, hit_shield | 15 | target | 0 | strikes only through things | minimoonspider_spike |  | UM | `moves_sim_um.lua:410` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:411` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | lane |  |  | UM | `moves_sim_um.lua:412` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `minimoonspider_spike` |  | lasting · delay 1 · strikes until 82 | UM | `moves_sim_um.lua:57` |  |

<a id="spider_ape"></a>

## spider_ape

Data from: TE `moves_sim_te.lua:541`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 17 | target | 0 |  |  |  | TE | `moves_sim_te.lua:542` |

<a id="spider_hider"></a>

## spider_hider — Cave Spider

Data from: hand-UM

Drawn as: `spider`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|

<a id="spider_monkey"></a>

## spider_monkey

Data from: TE `moves_sim_te.lua:544`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 11 | target | 0 |  |  |  | TE | `moves_sim_te.lua:545` |
| `throw` | throw | 14 | target | 0 |  |  |  | TE | `moves_sim_te.lua:546` |

<a id="spider_moon"></a>

## spider_moon — Shattered Spider

Data from: game `moves_sim.lua:569` · UM `moves_sim_um.lua:414`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | scale 1.25 |  |  | game | `moves_sim.lua:570` |
| `hide` | hide, hit_shield, unhide | 15 | target | 0 | scale 1.25 · strikes only through things | moonspider_spike |  | game | `moves_sim.lua:571` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | follows target · scale 1.25 |  |  | UM | `moves_sim_um.lua:415` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `moonspider_spike` | Shattered Spider | lasting · delay 1 · strikes until 81 | game | `moves_sim.lua:83` |  |

<a id="spider_snow"></a>

## spider_snow

Data from: TE `moves_sim_te.lua:548`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | scale 1.25 |  |  | TE | `moves_sim_te.lua:549` |
| `hide` | hide, hit_shield, unhide | 15 | target | 0 | scale 1.25 · strikes only through things | snowspider_spike |  | TE | `moves_sim_te.lua:550` |
| `spit` | spit, taunt | 21 | target | 0 | scale 1.25 |  |  | TE | `moves_sim_te.lua:551` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | lane · scale 1.25 |  |  | TE | `moves_sim_te.lua:552` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `snowspider_spike` |  | lasting · delay 1 · strikes until 82 | TE | `moves_sim_te.lua:54` |  |

<a id="spider_snow2"></a>

## spider_snow2

Data from: TE `moves_sim_te.lua:554`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | scale 1.25 |  |  | TE | `moves_sim_te.lua:555` |
| `hide` | hide, hit_shield, unhide | 15 | target | 0 | scale 1.25 · strikes only through things | snowspider_spike2 |  | TE | `moves_sim_te.lua:556` |
| `spit` | spit, taunt | 21 | target | 0 | scale 1.25 |  |  | TE | `moves_sim_te.lua:557` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | lane · scale 1.25 |  |  | TE | `moves_sim_te.lua:558` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `snowspider_spike2` |  | lasting · delay 1 · strikes until 82 | TE | `moves_sim_te.lua:55` |  |

<a id="spider_spitter"></a>

## spider_spitter — Spitter

Data from: game `moves_sim.lua:573` · UM `moves_sim_um.lua:417` · hand

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | game | `moves_sim.lua:574` |
| `spit` | spit | 21 | target | 21 |  |  |  | hand | `moves_hand.lua` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:418` |

<a id="spider_trapdoor"></a>

## spider_trapdoor — Trapdoor Spider

Data from: UM `moves_sim_um.lua:420`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | scale 1.1 |  |  | UM | `moves_sim_um.lua:421` |
| `spit` | spit, taunt | 21 | target | 0 | scale 1.1 |  |  | UM | `moves_sim_um.lua:422` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | follows target · scale 1.1 |  |  | UM | `moves_sim_um.lua:423` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | lane · scale 1.1 |  |  | UM | `moves_sim_um.lua:424` |

<a id="spider_trapdoor_hooded"></a>

## spider_trapdoor_hooded — Hooded Widower

Data from: UM `moves_sim_um.lua:426`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | scale 1.1 |  |  | UM | `moves_sim_um.lua:427` |
| `spit` | spit, taunt | 21 | target | 0 | scale 1.1 |  |  | UM | `moves_sim_um.lua:428` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | follows target · scale 1.1 |  |  | UM | `moves_sim_um.lua:429` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | lane · scale 1.1 |  |  | UM | `moves_sim_um.lua:430` |

<a id="spider_tropical"></a>

## spider_tropical

Data from: TE `moves_sim_te.lua:560`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:561` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua:562` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | lane |  |  | TE | `moves_sim_te.lua:563` |

<a id="spider_warrior"></a>

## spider_warrior — Spider Warrior

Data from: game `moves_sim.lua:576` · UM `moves_sim_um.lua:432`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 25 | target | 0 |  |  |  | game | `moves_sim.lua:577` |
| `atk` ▦ | atk | 25 | target | 0 |  |  |  | UM | `moves_sim_um.lua:433` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:434` |
| `warrior_atk` ▦ | warrior_atk, taunt | 19 | facing | 0 | lane |  |  | game | `moves_sim.lua:578` |
| `warrior_atk` ▦ | warrior_atk, taunt | 19 | facing | 0 | lane |  |  | UM | `moves_sim_um.lua:435` |

<a id="spider_water"></a>

## spider_water — Sea Strider

Data from: game `moves_sim.lua:580`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 |  |  |  | game | `moves_sim.lua:581` |

<a id="spiderb"></a>

## spiderb

Data from: TE `moves_sim_te.lua:565`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:566` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua:567` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | lane |  |  | TE | `moves_sim_te.lua:568` |

<a id="spiderb1"></a>

## spiderb1

Data from: TE `moves_sim_te.lua:570`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:571` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua:572` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | lane |  |  | TE | `moves_sim_te.lua:573` |

<a id="spiderb2"></a>

## spiderb2

Data from: TE `moves_sim_te.lua:575`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:576` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua:577` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | lane |  |  | TE | `moves_sim_te.lua:578` |

<a id="spiderqueen"></a>

## spiderqueen — Spider Queen

Data from: game `moves_sim.lua:583`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 28 | target | 0 |  |  |  | game | `moves_sim.lua:584` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `queen_web_bomb` |  | moving · delay 0 | UM | `moves_sim_um.lua:62` |  |

<a id="spiky_monkey_tfc"></a>

## spiky_monkey_tfc

Data from: TE `moves_sim_te.lua:580`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1 | 21 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:581` |
| `attack2` | attack2 | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:582` |

<a id="spiky_turtle_tfc"></a>

## spiky_turtle_tfc

Data from: TE `moves_sim_te.lua:584`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1 | 12 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:585` |

**Special code that names it:** modmain.lua:959 simmoves.lua:3373

<a id="sporehound"></a>

## sporehound — Spore Hound

Data from: UM `moves_sim_um.lua:437` · hand-UM

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:438` |
| `jump_atk_loop` | jump_atk_loop |  |  |  |  |  |  | hand-UM | `moves_hand_um.lua` |
| `jump_atk_loop` | jump_atk_loop, hit, taunt | 15 | target | 0 | follows target · moves 1.0 |  | lightningshot_cooldown | UM | `moves_sim_um.lua:439` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `sporecloud_toad` | Spore Cloud | lasting · delay 30 | UM | `moves_sim_um.lua:68` |  |

<a id="squid"></a>

## squid — Skittersquid

Data from: game `moves_sim.lua:586` · TE `moves_sim_te.lua:587`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 10 | target | 0 |  |  |  | game | `moves_sim.lua:587` |
| `attack` | attack | 10 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:588` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `inksplat` |  | moving · delay 20 | game | `moves_sim.lua:80` |  |
| `inksplat` |  | moving · delay 20 | TE | `moves_sim_te.lua:46` |  |

<a id="squidunderwater2"></a>

## squidunderwater2

Data from: TE `moves_sim_te.lua:590`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 10 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:591` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `inksplat` |  | moving · delay 20 | TE | `moves_sim_te.lua:46` |  |

<a id="stageusher"></a>

## stageusher — Prickly Stagehand

Data from: game `moves_sim.lua:589`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `sleep` | sleep, idle_loop_01 | 166 | facing | 16 |  | stageusher_attackhand |  | game | `moves_sim.lua:590` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `stageusher_attackhand` |  | lasting · delay 0 · strikes until 300 | game | `moves_sim.lua:99` | simmoves.lua:3672 |

<a id="stalker_atrium"></a>

## stalker_atrium — Ancient Fuelweaver

Data from: game `moves_sim.lua:592` · UM `moves_sim_um.lua:441` · TE `moves_sim_te.lua:593`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 32 | target | 0 |  |  |  | game | `moves_sim.lua:593` |
| `attack` | attack | 32 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:594` |
| `attack` | attack | 32 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:442` |
| `attack1` | attack1 | 26 | target | 27 |  | fossilspike | mindcontrol_cd | game | `moves_sim.lua:594` |
| `spike` ▦ | spike | 51 | facing | 0 |  | fossilspike2 | mindcontrol_cd | game | `moves_sim.lua:595` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `fossilspike` | Fossil Cage | delay 0 | game | `moves_sim.lua:71` |  |
| `fossilspike2` | Fossil Spike | delay 46 | game | `moves_sim.lua:72` |  |

<a id="stalker_minion"></a>

## stalker_minion — Woven Shadow

Data from: game `moves_sim.lua:597`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|

<a id="stalker_npc"></a>

## stalker_npc — Ancient Fuelweaver

Data from: game `moves_sim.lua:598`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 32 | target | 0 |  |  |  | game | `moves_sim.lua:599` |
| `attack1` | attack1 | 26 | facing | 0 |  |  |  | game | `moves_sim.lua:600` |
| `spike` | spike | 51 | facing | 0 |  |  |  | game | `moves_sim.lua:601` |

<a id="strange_scorpion_tfc"></a>

## strange_scorpion_tfc

Data from: TE `moves_sim_te.lua:596`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pre` | attack_pre, attack | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:597` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `strange_scorpion_massproj_tfc` |  | moving · delay 0 · strikes until 45 | TE | `moves_sim_te.lua:56` |  |
| `strange_scorpion_proj_tfc` |  | moving · delay 0 · strikes until 30 | TE | `moves_sim_te.lua:57` |  |

<a id="stumpling"></a>

## stumpling — Pineling

Data from: UM `moves_sim_um.lua:444`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack, taunt | 10 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:445` |

<a id="stungray"></a>

## stungray

Data from: TE `moves_sim_te.lua:599`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 8 | facing | 0 | scale 1.05 |  |  | TE | `moves_sim_te.lua:600` |

<a id="stungrayunderwater"></a>

## stungrayunderwater

Data from: TE `moves_sim_te.lua:602`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 8 | facing | 0 | scale 1.05 |  |  | TE | `moves_sim_te.lua:603` |

<a id="summerwalrus"></a>

## summerwalrus

Data from: TE `moves_sim_te.lua:605`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 20 |  |  |  | TE | `moves_sim_te.lua:605` |

<a id="swathgrithr"></a>

## swathgrithr — Wigfrid?

Data from: UM `moves_sim_um.lua:447`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, lunge_pst | 32 | target |  | follows target |  |  | UM | `moves_sim_um.lua:448` |
| `lunge_pre` | lunge_pre, lunge_lag, sing_pre | 12 | target | 16 | follows target |  |  | UM | `moves_sim_um.lua:449` |

<a id="swilson"></a>

## swilson — Wilson?

Data from: UM `moves_sim_um.lua:451`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, run_loop | 32 | target |  | follows target |  |  | UM | `moves_sim_um.lua:452` |

<a id="swordfish"></a>

## swordfish

Data from: TE `moves_sim_te.lua:606`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:607` |

<a id="swordfishunderwater"></a>

## swordfishunderwater

Data from: TE `moves_sim_te.lua:609`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:610` |

