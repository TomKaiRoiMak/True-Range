# Monster catalog - A

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="adult_flytrap"></a>

## adult_flytrap

Data from: TE `moves_sim_te.lua:71`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst | 15 | target | 0 |  |  |  | TE | `moves_sim_te.lua:72` |

<a id="alpha_lightninggoat"></a>

## alpha_lightninggoat — Alpha Volt Goat

Data from: UM `moves_sim_um.lua:89`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 | scale 1.1 |  |  | UM | `moves_sim_um.lua:90` |
| `lightcharge_atk_loop` | lightcharge_atk_loop | 26 | target | 0 | scale 1.1 · strikes only through things | goat_lightning |  | UM | `moves_sim_um.lua:91` |
| `stompy` | stompy, stompy_loop, stompy_pst | 19 | facing | 0 | scale 1.1 |  |  | UM | `moves_sim_um.lua:92` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `goat_lightning` |  | moving · lasting · delay 0 | UM | `moves_sim_um.lua:53` |  |
| `hound_lightning` | Supercharged Lightning | lasting · delay 30 | UM | `moves_sim_um.lua:55` |  |

<a id="alterguardian_phase1"></a>

## alterguardian_phase1 — Celestial Champion

Data from: game `moves_sim.lua:109`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `roll_pre` | roll_pre, roll_loop, roll_pst | 51 | facing | 52 | charge legs · cone · moves 16.3 |  | roll_cooldown | game | `moves_sim.lua:110` |
| `tantrum_loop` | tantrum_loop, tantrum_pst | 8 | facing | 0 |  |  |  | game | `moves_sim.lua:111` |
| `tantrum_pre` | tantrum_pre | 26 | facing | 0 |  |  |  | game | `moves_sim.lua:112` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `gestalt_alterguardian_projectile` | Gestalt | delay 34 | game | `moves_sim.lua:75` |  |

**Special code that names it:** simmoves.lua:3668

<a id="alterguardian_phase1_lunarrift"></a>

## alterguardian_phase1_lunarrift — Celestial Revenant

Data from: game `moves_sim.lua:114`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `roll_pre` | roll_pre, roll_loop, roll_pst | 51 | facing | 52 | charge legs · cone · moves 16.3 |  | roll_cooldown | game | `moves_sim.lua:115` |
| `tantrum_loop` | tantrum_loop, tantrum_pst | 8 | facing | 0 |  |  |  | game | `moves_sim.lua:116` |
| `tantrum_pre` | tantrum_pre | 26 | facing | 0 |  |  |  | game | `moves_sim.lua:117` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `gestalt_alterguardian_projectile` | Gestalt | delay 34 | game | `moves_sim.lua:75` |  |

**Special code that names it:** simmoves.lua:3668

<a id="alterguardian_phase2"></a>

## alterguardian_phase2 — Celestial Champion

Data from: game `moves_sim.lua:119`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attk_chop` | attk_chop | 23 | target | 0 |  |  |  | game | `moves_sim.lua:120` |
| `attk_chop~atk_summon` | attk_chop | 23 | target | 0 | told by alterguardian_summon_fx |  | summon_cd | game | `moves_sim.lua:121` |
| `attk_spin_pre` | attk_spin_pre, attk_spin_loop, attk_spin_pst | 35 | target |  | around itself |  |  | game | `moves_sim.lua:122` |
| `attk_stab_pre` | attk_stab_pre, attk_stab_loop, attk_stab_pst | 28 | target | 0 |  |  | spike_cd | game | `moves_sim.lua:123` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `alterguardian_phase2spiketrail` |  | moving · delay 16 · strikes until 60 | game | `moves_sim.lua:48` | simmoves.lua:3441 simmoves.lua:3442 simmoves.lua:3443 |
| `smallguard_alterguardian_projectile` | Minor Gestalt | delay 34 | game | `moves_sim.lua:95` |  |

**Special code that names it:** simmoves.lua:3668

<a id="alterguardian_phase3"></a>

## alterguardian_phase3 — Celestial Champion

Data from: game `moves_sim.lua:125` · UM `moves_sim_um.lua:94`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attk_beam` | attk_beam | 35 | target | 22 | follows target | alterguardian_laser, alterguardian_laserempty |  | game | `moves_sim.lua:126` |
| `attk_skybeam` | attk_skybeam | 90 | facing | 0 |  |  | traps_cd | game | `moves_sim.lua:127` |
| `attk_stab` | attk_stab | 29 | target | 0 |  |  |  | game | `moves_sim.lua:128` |
| `attk_stab` | attk_stab | 29 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:95` |
| `attk_stab2_loop` | attk_stab2_loop | 1 | target | 0 |  |  |  | game | `moves_sim.lua:129` |
| `attk_stab2_loop` | attk_stab2_loop | 1 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:96` |
| `attk_stab2_pre` | attk_stab2_pre | 33 | target | 0 |  |  |  | game | `moves_sim.lua:130` |
| `attk_stab2_pre` | attk_stab2_pre | 33 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:97` |
| `attk_stab2_pre@lucky` | attk_stab2_pre | 33 | target | 0 |  |  |  | game | `moves_sim.lua:131` |
| `attk_stab2_pre@lucky` | attk_stab2_pre | 33 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:98` |
| `attk_swipe` | attk_swipe | 37 | target | 22 |  | alterguardian_laser |  | game | `moves_sim.lua:132` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `alterguardian_laser` |  | lasting · drawn with the boss move · delay 0 · strikes until 25 | game | `moves_sim.lua:46` |  |
| `alterguardian_laserempty` |  | lasting · drawn with the boss move · delay 0 · strikes until 23 | game | `moves_sim.lua:47` |  |
| `alterguardian_phase3trap` | Enlightening Snare | lasting · delay 170 | game | `moves_sim.lua:49` |  |
| `alterguardian_phase3trapprojectile` |  | delay 31 · strikes until 31 | hand | `moves_hand.lua:113` |  |
| `alterguardian_phase3trapprojectile` |  | delay 31 · strikes until 31 | game | `moves_sim.lua:50` |  |
| `gestalt_alterguardian_projectile` | Gestalt | delay 34 | game | `moves_sim.lua:75` |  |
| `largeguard_alterguardian_projectile` | Greater Gestalt | delay 34 | game | `moves_sim.lua:82` |  |

<a id="alterguardian_phase4_lunarrift"></a>

## alterguardian_phase4_lunarrift — Celestial Scion

Data from: game `moves_sim.lua:134`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_burst_pre` ▦ | atk_burst_pre, atk_burst_charge_loop, atk_burst_charge_to_shoot, atk_burst_shoot_loop | 146 | facing | 0 |  |  | supernova_cd | game | `moves_sim.lua:135` |
| `dash_pre` | dash_pre, dash_loop, dash_pst | 64 | target | 63 | charge legs · moves 14.3 |  |  | game | `moves_sim.lua:136` |
| `slam` | slam | 43 | target | 23 |  | alterguardian_phase4_lunarrift_slam_fx |  | game | `moves_sim.lua:137` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `alterguardian_lunar_fissures` |  | lasting · delay 17 | hand | `moves_hand.lua` |  |
| `alterguardian_phase4_lunarrift_slam_fx` |  | lasting · drawn with the boss move · delay 1 · strikes until 34 | game | `moves_sim.lua:51` |  |

<a id="ancient_herald"></a>

## ancient_herald

Data from: TE `moves_sim_te.lua:74`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 20 | facing | 0 | scale 1.25 |  |  | TE | `moves_sim_te.lua:75` |

<a id="ancient_hulk"></a>

## ancient_hulk

Data from: TE `moves_sim_te.lua:77`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_barrier` | atk_barrier | 64 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:78` |
| `atk_chomp` | atk_chomp | 15 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:79` |
| `atk_lob` | atk_lob | 183 | target | 31 | follows target | ancient_hulk_orb |  | TE | `moves_sim_te.lua:80` |
| `teleport_in` | teleport_in | 17 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:81` |
| `teleport_out_pre` | teleport_out_pre, teleport_out | 51 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:82` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `ancient_hulk_mine` |  | lasting · delay 0 | TE | `moves_sim_te.lua:35` | simmoves.lua:3375 |
| `ancient_hulk_orb` |  | moving · delay 153 | TE | `moves_sim_te.lua:36` |  |

**Special code that names it:** modmain.lua:951

<a id="ancient_robot_claw"></a>

## ancient_robot_claw

Data from: TE `moves_sim_te.lua:84`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 30 | target | 0 | follows target | laser, laserempty | laserbeam_cd | TE | `moves_sim_te.lua:85` |
| `atk_pre` | atk_pre, atk_loop, atk_pst | 44 | target | 0 | follows target · moves 1.0 |  |  | TE | `moves_sim_te.lua:86` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `laser` |  | delay 0 · strikes until 0 | TE | `moves_sim_te.lua:48` |  |
| `laserempty` |  | drawn with the boss move · delay 0 · strikes until 0 | TE | `moves_sim_te.lua:49` |  |

<a id="ancient_robot_head"></a>

## ancient_robot_head

Data from: TE `moves_sim_te.lua:88`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk_loop, atk_pst | 41 | target | 0 | follows target · moves 1.0 |  |  | TE | `moves_sim_te.lua:89` |

<a id="ancient_robot_leg"></a>

## ancient_robot_leg

Data from: TE `moves_sim_te.lua:91`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk_loop, atk_pst | 42 | target | 0 | follows target · moves 1.0 |  |  | TE | `moves_sim_te.lua:92` |

<a id="ancient_robot_ribs"></a>

## ancient_robot_ribs

Data from: TE `moves_sim_te.lua:94`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 30 | target | 0 | follows target | laser, laserempty | laserbeam_cd | TE | `moves_sim_te.lua:95` |
| `atk_pre` | atk_pre, atk_loop, atk_pst | 44 | target | 0 | follows target · moves 1.0 |  |  | TE | `moves_sim_te.lua:96` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `laser` |  | delay 0 · strikes until 0 | TE | `moves_sim_te.lua:48` |  |
| `laserempty` |  | drawn with the boss move · delay 0 · strikes until 0 | TE | `moves_sim_te.lua:49` |  |

<a id="ancient_trepidation"></a>

## ancient_trepidation — Trepidation

Data from: UM `moves_sim_um.lua:100`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 12 | target | 0 | scale 2 |  |  | UM | `moves_sim_um.lua:101` |

<a id="ancient_trepidation_arm"></a>

## ancient_trepidation_arm — Trepidation's Reach

Data from: UM `moves_sim_um.lua:103`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_loop` | atk_loop, taunt | 7 | target | 0 | scale 2 |  |  | UM | `moves_sim_um.lua:104` |
| `atk_pre` | atk_pre, atk_loop, taunt | 25 | target | 0 | scale 2 |  |  | UM | `moves_sim_um.lua:105` |

<a id="antlion"></a>

## antlion — Antlion

Data from: game `moves_sim.lua:139`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `cast_pre` | cast_pre, cast_pst | 33 | target | 3 | strikes only through things | sandspike_med, sandspike_short, sandspike_tall |  | game | `moves_sim.lua:140` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `antlion_sinkhole` | Sinkhole | delay 0 | game | `moves_sim.lua:52` |  |
| `sandspike_med` |  | delay 30 | game | `moves_sim.lua:89` |  |
| `sandspike_short` |  | delay 30 | game | `moves_sim.lua:90` |  |
| `sandspike_tall` |  | delay 30 | game | `moves_sim.lua:91` |  |

<a id="antman"></a>

## antman

Data from: TE `moves_sim_te.lua:98`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | scale 1.15 |  |  | TE | `moves_sim_te.lua:99` |

<a id="antman2"></a>

## antman2

Data from: TE `moves_sim_te.lua:101`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | scale 1.15 |  |  | TE | `moves_sim_te.lua:102` |

<a id="antman_warrior"></a>

## antman_warrior

Data from: TE `moves_sim_te.lua:104`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk2` | atk2 | 13 | target | 0 | scale 1.15 |  |  | TE | `moves_sim_te.lua:105` |

<a id="aphid"></a>

## aphid — Aphid

Data from: UM `moves_sim_um.lua:107`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:108` |
| `leap_attack` | leap_attack, taunt | 18 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:109` |

<a id="archive_centipede"></a>

## archive_centipede — Ancient Sentrypede

Data from: game `moves_sim.lua:142`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 9 | target | 0 |  |  |  | game | `moves_sim.lua:143` |
| `atk_aoe` | atk_aoe | 25 | facing | 0 |  |  |  | game | `moves_sim.lua:144` |
| `atk_roll_pre` | atk_roll_pre, atk_roll_loop, atk_roll_pst | 11 | target | 0 | moves 20.0 |  |  | game | `moves_sim.lua:145` |

