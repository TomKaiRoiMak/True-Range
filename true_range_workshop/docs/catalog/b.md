# Monster catalog - B

[<- full index](README.md) · made by `tools\make_catalog.ps1` - **don't edit this page by hand**

Columns: **hit frame** = first frame it strikes (30 frames/s) · **aim** = `target` turns to its target / `facing` the way the boss faces · **lock** = frame it stops aiming · **kind** = the move's special traits · **where** = data file:line (in `true_range/scripts/true_range/`)

<a id="ballphin"></a>

## ballphin

Data from: TE `moves_sim_te.lua:107`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:108` |

<a id="ballphin2"></a>

## ballphin2

Data from: TE `moves_sim_te.lua:110`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:111` |

<a id="bat"></a>

## bat — Batilisk

Data from: game `moves_sim.lua:147`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 11 | target | 0 | scale 0.75 |  |  | game | `moves_sim.lua:148` |
| `hair_attack` | hair_attack, hair_attack_fail | 10 | target | 21 | follows target · scale 0.75 · moves 0.6 |  |  | game | `moves_sim.lua:149` |

**Special code that names it:** simmoves.lua:170

<a id="bat_boss"></a>

## bat_boss — Hound Batilisk

Data from: game `moves_sim.lua:151`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 | moves 1.3 |  |  | game | `moves_sim.lua:152` |
| `hair_attack` | hair_attack, hair_attack_fail | 10 | target |  | follows target · moves 0.8 |  |  | game | `moves_sim.lua:153` |

<a id="bat_boss_shadow"></a>

## bat_boss_shadow — Blighted Hound Batilisk

Data from: game `moves_sim.lua:155`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 | moves 1.3 |  |  | game | `moves_sim.lua:156` |
| `hair_attack` | hair_attack, hair_attack_fail | 10 | target |  | follows target · moves 0.8 |  |  | game | `moves_sim.lua:157` |

<a id="bear"></a>

## bear

Data from: TE `moves_sim_te.lua:113`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 9 | target | 0 | scale 1.8 |  |  | TE | `moves_sim_te.lua:114` |

<a id="bearger"></a>

## bearger — Bearger

Data from: game `moves_sim.lua:159` · UM `moves_sim_um.lua:111` · hand-UM `moves_hand_um.lua:73`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 32 | facing | 10 |  | bearger_swipe_fx |  | game | `moves_sim.lua:160` |
| `atk1` | atk1, atk1_pst, atk2 | 32 | facing | 10 | moves 0.4 |  |  | game | `moves_sim.lua:161` |
| `atk1a` | atk1a, atk1_pst, atk2 | 28 | facing | 10 | moves 0.4 |  |  | game | `moves_sim.lua:162` |
| `atk2` | atk2, atk2_pst, atk1a | 28 | facing | 10 | moves 0.4 |  |  | game | `moves_sim.lua:163` |
| `butt_pre_L` | butt_pre_L, butt, butt_pst | 40 | facing | 0 | moves 3.1 |  |  | game | `moves_sim.lua:164` |
| `butt_pre_L~running_butt_pre` | butt_pre_L, butt, butt_pst | 18 | facing | 0 | moves 3.1 |  |  | game | `moves_sim.lua:165` |
| `ground_pound` | ground_pound | 20 | facing | 0 |  |  | GroundPound | game | `moves_sim.lua:166` |
| `ground_pound` | ground_pound | 20 | target | 21 |  | um_bearger_sinkhole | GroundPound | UM | `moves_sim_um.lua:112` |
| `ground_pound~pound` | ground_pound, stagger_pre, stagger_pst | 20 | facing | 0 |  |  | GroundPound | game | `moves_sim.lua:167` |
| `ground_pound~pound` | ground_pound, stagger_pre, stagger_pst | 20 | target | 21 |  | um_bearger_sinkhole | GroundPound | UM | `moves_sim_um.lua:113` |
| `sleep_pst` | sleep_pst, yawn, standing_yawn_pst | 103 | facing | 0 |  |  | Yawn | game | `moves_sim.lua:168` |
| `t` | t | 25 | facing |  |  |  |  | hand-UM | `moves_hand_um.lua:73` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `bearger_boulder` |  | moving · delay 22 | UM | `moves_sim_um.lua:36` |  |
| `bearger_swipe_fx` |  | drawn with the boss move · delay 3 · strikes until 3 | game | `moves_sim.lua:53` |  |
| `um_bearger_sinkhole` |  | delay 15 · strikes until 30 | UM | `moves_sim_um.lua:70` |  |

**Special code that names it:** simmoves.lua:3494

<a id="beefalo"></a>

## beefalo — Beefalo

Data from: game `moves_sim.lua:170` · UM `moves_sim_um.lua:115`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:116` |
| `atk_pre` | atk_pre, atk | 15 | target | 0 |  |  |  | game | `moves_sim.lua:171` |
| `atk_pre` | atk_pre, atk, mating_taunt1 | 15 | target |  |  |  |  | UM | `moves_sim_um.lua:117` |

<a id="beefalo_moon"></a>

## beefalo_moon

Data from: UM `moves_sim_um.lua:119`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:120` |
| `atk_pre` | atk_pre, atk, mating_taunt1 | 15 | target |  |  |  |  | UM | `moves_sim_um.lua:121` |

<a id="beeguard"></a>

## beeguard — Grumble Bee

Data from: game `moves_sim.lua:173` · UM `moves_sim_um.lua:123` · hand-UM `moves_hand_um.lua:46`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | scale 1.4 |  |  | game | `moves_sim.lua:174` |
| `stab_pre` | stab_pre, stab, stab_pst, stuck_loop, … | 3 | facing |  | around itself · scale 1.4 |  |  | UM | `moves_sim_um.lua:124` |
| `stab_pst` | stab_pst, stuck_loop, stuck_pst | 3 | facing |  | around itself · scale 1.4 |  |  | UM | `moves_sim_um.lua:125` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `warningshadow` |  | moving · lasting · delay 0 | UM | `moves_sim_um.lua:83` | predict.lua:4062 predict.lua:4077 predict.lua:4096 |

<a id="beequeen"></a>

## beequeen — Bee Queen

Data from: game `moves_sim.lua:176` · UM `moves_sim_um.lua:127`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 14 | target | 0 | scale 1.4 |  |  | game | `moves_sim.lua:177` |
| `combotaunt` | combotaunt, atk | 54 | target | 0 | scale 1.4 |  |  | UM | `moves_sim_um.lua:128` |
| `stomp` | stomp, tired_loop | 31 | facing | 0 | scale 1.4 |  |  | UM | `moves_sim_um.lua:129` |
| `stomp_pre` | stomp_pre, stomp, screech | 46 | facing | 0 | scale 1.4 |  |  | UM | `moves_sim_um.lua:130` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `um_beeguard_blocker` | Blocker Bee | moving · lasting · delay 0 | hand | `moves_hand.lua:102` | simmoves.lua:3369 |
| `um_beeguard_seeker` | Bomber Bee | moving · lasting · delay 0 | hand | `moves_hand.lua:103` | simmoves.lua:3370 |
| `um_beeguard_shooter` | Bullet Bee | moving · lasting · delay 0 | hand | `moves_hand.lua:104` | modmain.lua:1066 simmoves.lua:3371 |
| `um_beestinger_projectile` |  | moving · lasting · delay 0 | UM | `moves_sim_um.lua:71` | modmain.lua:1066 |
| `warningshadow` |  | moving · lasting · delay 0 | UM | `moves_sim_um.lua:83` | predict.lua:4062 predict.lua:4077 predict.lua:4096 |

<a id="beetletaur"></a>

## beetletaur — Infernal Swineclops

Data from: TE `moves_sim_te.lua:116`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1, attack1_pst | 6 | target | 0 | scale 1.05 |  |  | TE | `moves_sim_te.lua:117` |
| `attack1b` | attack1b, attack1_pst | 7 | target | 0 | scale 1.05 |  |  | TE | `moves_sim_te.lua:118` |
| `attack2` | attack2, attack1_pst | 7 | target | 0 | scale 1.05 |  |  | TE | `moves_sim_te.lua:119` |
| `attack3` | attack3 | 3 | target |  | scale 1.05 |  |  | TE | `moves_sim_te.lua:120` |
| `bellyflop_pre` | bellyflop_pre, bellyflop | 23 | target | 7 | scale 1.05 · moves 0.6 |  |  | TE | `moves_sim_te.lua:121` |
| `block_counter` | block_counter | 6 | target | 0 | scale 1.05 |  |  | TE | `moves_sim_te.lua:122` |
| `taunt2` | taunt2 | 8 | target | 0 | scale 1.05 |  |  | TE | `moves_sim_te.lua:123` |

**Special code that names it:** modmain.lua:1010 simmoves.lua:3501

<a id="bigfoot"></a>

## bigfoot — Biiigfoot

Data from: TE `moves_sim_te.lua:125`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `stomp` | stomp, stomp_pst | 5 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:126` |

<a id="bight"></a>

## bight — Comingled Clockwork

Data from: UM `moves_sim_um.lua:132`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 26 | target | 0 |  |  |  | UM | `moves_sim_um.lua:133` |

<a id="bigshadowtentacle"></a>

## bigshadowtentacle — Guardian Shadow Tentacle

Data from: game `moves_sim.lua:179` · UM `moves_sim_um.lua:135`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk_loop` | atk_loop, atk_idle | 7 | target | 0 | scale 1.3 |  |  | game | `moves_sim.lua:180` |
| `atk_loop` | atk_loop, atk_idle, atk_pst | 7 | target | 0 | scale 1.3 |  |  | UM | `moves_sim_um.lua:136` |
| `atk_pre` | atk_pre, atk_loop, atk_idle | 37 | target | 0 | scale 1.3 |  |  | game | `moves_sim.lua:181` |
| `atk_pre` | atk_pre, atk_loop, atk_idle, atk_pst | 37 | target | 0 | scale 1.3 |  |  | UM | `moves_sim_um.lua:137` |

**Special code that names it:** modmain.lua:890

<a id="bill"></a>

## bill

Data from: TE `moves_sim_te.lua:128`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 4 | target | 0 |  |  |  | TE | `moves_sim_te.lua:129` |

<a id="billsnow"></a>

## billsnow

Data from: TE `moves_sim_te.lua:131`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 4 | target | 0 |  |  |  | TE | `moves_sim_te.lua:132` |

<a id="birchling"></a>

## birchling — Birchling

Data from: UM `moves_sim_um.lua:139`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack, taunt | 10 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:140` |

<a id="birchnutdrake"></a>

## birchnutdrake — Birchnutter

Data from: game `moves_sim.lua:183`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | game | `moves_sim.lua:184` |
| `atk~attack` | atk | 12 | target | 0 |  |  |  | game | `moves_sim.lua:185` |

<a id="bird_mutant"></a>

## bird_mutant — Moonblind Crow

Data from: game `moves_sim.lua:187`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 8 | target | 0 |  |  |  | game | `moves_sim.lua:188` |

<a id="bird_mutant_spitter"></a>

## bird_mutant_spitter — Misshapen Bird

Data from: game `moves_sim.lua:190`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `bilesplat` |  | moving · delay 0 · strikes until 45 | game | `moves_sim.lua:54` |  |

<a id="bishop"></a>

## bishop — Clockwork Bishop

Data from: game `moves_sim.lua:191`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk2_pre` | atk2_pre, atk2_loop, atk2_pst | 31 | facing | 25 | follows target | bishop_targeting_fx |  | game | `moves_sim.lua:192` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `bishop_charge2_fx` |  | lasting · delay 0 | game | `moves_sim.lua:55` |  |
| `bishop_targeting_fx` |  | drawn with the boss move · delay 25 · strikes until 25 | game | `moves_sim.lua:56` |  |
| `bishop_targeting_fx` |  | drawn with the boss move · delay 25 · strikes until 25 | TE | `moves_sim_te.lua:37` |  |

<a id="bishop_nightmareb"></a>

## bishop_nightmareb

Data from: TE `moves_sim_te.lua:134`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk2_pre` | atk2_pre, atk2_loop, atk2_pst | 31 | facing | 25 | follows target | bishop_targeting_fx |  | TE | `moves_sim_te.lua:135` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `bishop_targeting_fx` |  | drawn with the boss move · delay 25 · strikes until 25 | TE | `moves_sim_te.lua:37` |  |

<a id="bishopb"></a>

## bishopb

Data from: TE `moves_sim_te.lua:137`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk2_pre` | atk2_pre, atk2_loop, atk2_pst | 31 | facing | 25 | follows target | bishop_targeting_fx |  | TE | `moves_sim_te.lua:138` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `bishop_targeting_fx` |  | drawn with the boss move · delay 25 · strikes until 25 | TE | `moves_sim_te.lua:37` |  |

<a id="bishopwater"></a>

## bishopwater

Data from: TE `moves_sim_te.lua:140`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk2_pre` | atk2_pre, atk2_loop, atk2_pst | 31 | facing | 25 | follows target | bishop_targeting_fx |  | TE | `moves_sim_te.lua:141` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `bishop_targeting_fx` |  | drawn with the boss move · delay 25 · strikes until 25 | TE | `moves_sim_te.lua:37` |  |

<a id="bishopwaterfixo"></a>

## bishopwaterfixo

Data from: TE `moves_sim_te.lua:143`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk2_pre` | atk2_pre, atk2_loop, atk2_pst | 31 | facing | 25 | follows target | bishop_targeting_fx |  | TE | `moves_sim_te.lua:144` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `bishop_targeting_fx` |  | drawn with the boss move · delay 25 · strikes until 25 | TE | `moves_sim_te.lua:37` |  |

<a id="bossboar"></a>

## bossboar

Data from: TE `moves_sim_te.lua:146`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1, attack1_pst | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:147` |
| `attack1~combofirsthit` | attack1, attack2 | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:148` |
| `attack3` | attack3 | 3 | target |  |  |  |  | TE | `moves_sim_te.lua:149` |
| `attack4` | attack4 | 13 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:150` |
| `attack5` | attack5, taunt | 10 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:151` |
| `banner_pre` | banner_pre, banner_loop, banner_pst | 40 | target | 53 | follows target | bossboarfireburst |  | TE | `moves_sim_te.lua:152` |
| `dash` | dash, attack3 | 22 | target | 0 |  |  |  | TE | `moves_sim_te.lua:153` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `bossboarfireburst` |  | delay 30 | TE | `moves_sim_te.lua:38` |  |

<a id="bossboarte"></a>

## bossboarte

Data from: TE `moves_sim_te.lua:155`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1, attack1_pst | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:156` |
| `attack1~combofirsthit` | attack1, attack2 | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:157` |
| `attack3` | attack3 | 3 | target |  |  |  |  | TE | `moves_sim_te.lua:158` |
| `attack4` | attack4 | 13 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:159` |
| `attack5` | attack5, taunt | 10 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:160` |
| `banner_pre` | banner_pre, banner_loop, banner_pst | 40 | target | 53 | follows target | bossboarfireburst |  | TE | `moves_sim_te.lua:161` |
| `dash` | dash, attack3 | 22 | target | 0 |  |  |  | TE | `moves_sim_te.lua:162` |

**Things it puts out**

| thing | name | kind | source | where | code that names it |
|---|---|---|---|---|---|
| `bossboarfireburst` |  | delay 30 | TE | `moves_sim_te.lua:38` |  |

<a id="boulder_crab"></a>

## boulder_crab — Boulder Crab

Data from: UM `moves_sim_um.lua:142` · hand-UM `moves_hand_um.lua:66`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk, uppercut | 24 | target | 0 |  |  |  | UM | `moves_sim_um.lua:143` |
| `uppercut` | uppercut | 46 | target |  | around itself |  |  | hand-UM | `moves_hand_um.lua:66` |

<a id="bulletbee"></a>

## bulletbee — Bullet Bee

Data from: UM `moves_sim_um.lua:145`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 | scale 0.9 |  |  | UM | `moves_sim_um.lua:146` |

<a id="bunnyman"></a>

## bunnyman — Bunnyman

Data from: game `moves_sim.lua:194` · UM `moves_sim_um.lua:148`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | scale 1.25 |  |  | game | `moves_sim.lua:195` |
| `halloween_atk_pre` | halloween_atk_pre, halloween_atk, halloween_atk_pst | 12 | target | 0 | scale 1.25 |  |  | game | `moves_sim.lua:196` |
| `halloween_atk_pre` | halloween_atk_pre, halloween_atk, halloween_atk_pst | 12 | target | 0 | scale 1.25 |  |  | UM | `moves_sim_um.lua:149` |

**Special code that names it:** simmoves.lua:170

<a id="bushcrab"></a>

## bushcrab — Bush Crab

Data from: UM `moves_sim_um.lua:151`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | UM | `moves_sim_um.lua:152` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | UM | `moves_sim_um.lua:153` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | follows target |  |  | UM | `moves_sim_um.lua:154` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | lane |  |  | UM | `moves_sim_um.lua:155` |

<a id="buzzard"></a>

## buzzard — Buzzard

Data from: game `moves_sim.lua:198`

| move | animations | hit frame | aim | lock | kind | things put out | cooldown | source | where |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 13 | target | 0 |  |  |  | game | `moves_sim.lua:199` |

