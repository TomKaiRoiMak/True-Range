# สารบัญมอน — B

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="ballphin"></a>

## ballphin

แหล่งข้อมูล: TE `moves_sim_te.lua:44`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:44` |

<a id="ballphin2"></a>

## ballphin2

แหล่งข้อมูล: TE `moves_sim_te.lua:45`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:45` |

<a id="bat"></a>

## bat — Batilisk

แหล่งข้อมูล: เกม `moves_sim.lua:147`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 11 | target | 0 | ขนาด 0.75 |  |  | เกม | `moves_sim.lua:148` |
| `hair_attack` | hair_attack, hair_attack_fail | 10 | target | 21 | ตามเป้า · ขนาด 0.75 · เคลื่อน 0.6 |  |  | เกม | `moves_sim.lua:149` |

<a id="bat_boss"></a>

## bat_boss — Hound Batilisk

แหล่งข้อมูล: เกม `moves_sim.lua:151`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 | เคลื่อน 1.3 |  |  | เกม | `moves_sim.lua:152` |
| `hair_attack` | hair_attack, hair_attack_fail | 10 | target |  | ตามเป้า · เคลื่อน 0.8 |  |  | เกม | `moves_sim.lua:153` |

<a id="bat_boss_shadow"></a>

## bat_boss_shadow — Blighted Hound Batilisk

แหล่งข้อมูล: เกม `moves_sim.lua:155`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 | เคลื่อน 1.3 |  |  | เกม | `moves_sim.lua:156` |
| `hair_attack` | hair_attack, hair_attack_fail | 10 | target |  | ตามเป้า · เคลื่อน 0.8 |  |  | เกม | `moves_sim.lua:157` |

<a id="bear"></a>

## bear

แหล่งข้อมูล: TE `moves_sim_te.lua:46`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 9 | target | 0 | ขนาด 1.8 |  |  | TE | `moves_sim_te.lua:46` |

<a id="bearger"></a>

## bearger — Bearger

แหล่งข้อมูล: เกม `moves_sim.lua:159` · UM `moves_sim_um.lua:101`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 32 | facing | 10 |  | bearger_swipe_fx |  | เกม | `moves_sim.lua:160` |
| `atk1` | atk1, atk1_pst, atk2 | 32 | facing | 10 | เคลื่อน 0.4 |  |  | เกม | `moves_sim.lua:161` |
| `atk1a` | atk1a, atk1_pst, atk2 | 28 | facing | 10 | เคลื่อน 0.4 |  |  | เกม | `moves_sim.lua:162` |
| `atk2` | atk2, atk2_pst, atk1a | 28 | facing | 10 | เคลื่อน 0.4 |  |  | เกม | `moves_sim.lua:163` |
| `butt_pre_L` | butt_pre_L, butt, butt_pst | 40 | facing | 0 | เคลื่อน 3.1 |  |  | เกม | `moves_sim.lua:164` |
| `butt_pre_L~running_butt_pre` | butt_pre_L, butt, butt_pst | 18 | facing | 0 | เคลื่อน 3.1 |  |  | เกม | `moves_sim.lua:165` |
| `ground_pound` | ground_pound | 20 | facing | 0 |  |  | GroundPound | เกม | `moves_sim.lua:166` |
| `ground_pound` | ground_pound | 20 | target | 21 |  | um_bearger_sinkhole | GroundPound | UM | `moves_sim_um.lua:102` |
| `ground_pound~pound` | ground_pound, stagger_pre, stagger_pst | 20 | facing | 0 |  |  | GroundPound | เกม | `moves_sim.lua:167` |
| `ground_pound~pound` | ground_pound, stagger_pre, stagger_pst | 20 | target | 21 |  | um_bearger_sinkhole | GroundPound | UM | `moves_sim_um.lua:103` |
| `sleep_pst` | sleep_pst, yawn, standing_yawn_pst | 103 | facing | 0 |  |  | Yawn | เกม | `moves_sim.lua:168` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `bearger_boulder` |  | เคลื่อนที่ · ดีเลย์ 22 | UM | `moves_sim_um.lua:35` |  |
| `bearger_swipe_fx` |  | วาดกับท่าบอส · ดีเลย์ 3 · ตีถึง 3 | เกม | `moves_sim.lua:53` |  |
| `um_bearger_sinkhole` |  | ดีเลย์ 15 · ตีถึง 30 | UM | `moves_sim_um.lua:66` |  |

<a id="beefalo"></a>

## beefalo — Beefalo

แหล่งข้อมูล: เกม `moves_sim.lua:170` · UM `moves_sim_um.lua:105`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:106` |
| `atk_pre` | atk_pre, atk | 15 | target | 0 |  |  |  | เกม | `moves_sim.lua:171` |
| `atk_pre` | atk_pre, atk, mating_taunt1 | 15 | target |  |  |  |  | UM | `moves_sim_um.lua:107` |

<a id="beefalo_moon"></a>

## beefalo_moon

แหล่งข้อมูล: UM `moves_sim_um.lua:109`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:110` |
| `atk_pre` | atk_pre, atk, mating_taunt1 | 15 | target |  |  |  |  | UM | `moves_sim_um.lua:111` |

<a id="beeguard"></a>

## beeguard — Grumble Bee

แหล่งข้อมูล: เกม `moves_sim.lua:173` · UM `moves_sim_um.lua:113`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | ขนาด 1.4 |  |  | เกม | `moves_sim.lua:174` |
| `stab_pre` | stab_pre, stab, stab_pst, stuck_loop, … | 3 | facing |  | รอบตัว · ขนาด 1.4 |  |  | UM | `moves_sim_um.lua:114` |
| `stab_pst` | stab_pst, stuck_loop, stuck_pst | 3 | facing |  | รอบตัว · ขนาด 1.4 |  |  | UM | `moves_sim_um.lua:115` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `warningshadow` |  | เคลื่อนที่ · อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:79` | predict.lua:3734 predict.lua:3749 |

<a id="beequeen"></a>

## beequeen — Bee Queen

แหล่งข้อมูล: เกม `moves_sim.lua:176` · UM `moves_sim_um.lua:117`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 14 | target | 0 | ขนาด 1.4 |  |  | เกม | `moves_sim.lua:177` |
| `combotaunt` | combotaunt, atk | 54 | target | 0 | ขนาด 1.4 |  |  | UM | `moves_sim_um.lua:118` |
| `stomp` | stomp, tired_loop | 31 | facing | 0 | ขนาด 1.4 |  |  | UM | `moves_sim_um.lua:119` |
| `stomp_pre` | stomp_pre, stomp, screech | 46 | facing | 0 | ขนาด 1.4 |  |  | UM | `moves_sim_um.lua:120` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `um_beeguard_blocker` | Blocker Bee | เคลื่อนที่ · อยู่นาน · ดีเลย์ 0 | มือ | `moves_hand.lua:81` | simmoves.lua:3160 |
| `um_beeguard_seeker` | Bomber Bee | เคลื่อนที่ · อยู่นาน · ดีเลย์ 0 | มือ | `moves_hand.lua:82` | simmoves.lua:3161 |
| `um_beeguard_shooter` | Bullet Bee | เคลื่อนที่ · อยู่นาน · ดีเลย์ 0 | มือ | `moves_hand.lua:83` | modmain.lua:1041 simmoves.lua:3162 |
| `um_beestinger_projectile` |  | เคลื่อนที่ · อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:67` | modmain.lua:1041 |
| `warningshadow` |  | เคลื่อนที่ · อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:79` | predict.lua:3734 predict.lua:3749 |

<a id="beetletaur"></a>

## beetletaur — Infernal Swineclops

แหล่งข้อมูล: TE `moves_sim_te.lua:47`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1, attack1_pst | 6 | target | 0 | ขนาด 1.05 |  |  | TE | `moves_sim_te.lua:47` |
| `attack1b` | attack1b, attack1_pst | 7 | target | 0 | ขนาด 1.05 |  |  | TE | `moves_sim_te.lua:47` |
| `attack2` | attack2, attack1_pst | 7 | target | 0 | ขนาด 1.05 |  |  | TE | `moves_sim_te.lua:47` |
| `attack3` | attack3 | 3 | target |  | ขนาด 1.05 |  |  | TE | `moves_sim_te.lua:47` |
| `bellyflop_pre` | bellyflop_pre, bellyflop | 23 | target | 7 | ขนาด 1.05 · เคลื่อน 0.6 |  |  | TE | `moves_sim_te.lua:47` |
| `block_counter` | block_counter | 6 | target | 0 | ขนาด 1.05 |  |  | TE | `moves_sim_te.lua:47` |
| `taunt2` | taunt2 | 8 | target | 0 | ขนาด 1.05 |  |  | TE | `moves_sim_te.lua:47` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:985

<a id="bight"></a>

## bight — Comingled Clockwork

แหล่งข้อมูล: UM `moves_sim_um.lua:122`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 26 | target | 0 |  |  |  | UM | `moves_sim_um.lua:123` |

<a id="bigshadowtentacle"></a>

## bigshadowtentacle — Guardian Shadow Tentacle

แหล่งข้อมูล: เกม `moves_sim.lua:179` · UM `moves_sim_um.lua:125`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_loop` | atk_loop, atk_idle | 7 | target | 0 | ขนาด 1.3 |  |  | เกม | `moves_sim.lua:180` |
| `atk_loop` | atk_loop, atk_idle, atk_pst | 7 | target | 0 | ขนาด 1.3 |  |  | UM | `moves_sim_um.lua:126` |
| `atk_pre` | atk_pre, atk_loop, atk_idle | 37 | target | 0 | ขนาด 1.3 |  |  | เกม | `moves_sim.lua:181` |
| `atk_pre` | atk_pre, atk_loop, atk_idle, atk_pst | 37 | target | 0 | ขนาด 1.3 |  |  | UM | `moves_sim_um.lua:127` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:877

<a id="bill"></a>

## bill

แหล่งข้อมูล: TE `moves_sim_te.lua:48`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 4 | target | 0 |  |  |  | TE | `moves_sim_te.lua:48` |

<a id="billsnow"></a>

## billsnow

แหล่งข้อมูล: TE `moves_sim_te.lua:49`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 4 | target | 0 |  |  |  | TE | `moves_sim_te.lua:49` |

<a id="birchling"></a>

## birchling — Birchling

แหล่งข้อมูล: UM `moves_sim_um.lua:129`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack, taunt | 10 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:130` |

<a id="birchnutdrake"></a>

## birchnutdrake — Birchnutter

แหล่งข้อมูล: เกม `moves_sim.lua:183`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | เกม | `moves_sim.lua:184` |
| `atk~attack` | atk | 12 | target | 0 |  |  |  | เกม | `moves_sim.lua:185` |

<a id="bird_mutant"></a>

## bird_mutant — Moonblind Crow

แหล่งข้อมูล: เกม `moves_sim.lua:187`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 8 | target | 0 |  |  |  | เกม | `moves_sim.lua:188` |

<a id="bird_mutant_spitter"></a>

## bird_mutant_spitter — Misshapen Bird

แหล่งข้อมูล: เกม `moves_sim.lua:190`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `bilesplat` |  | เคลื่อนที่ · ดีเลย์ 0 · ตีถึง 45 | เกม | `moves_sim.lua:54` |  |

<a id="bishop"></a>

## bishop — Clockwork Bishop

แหล่งข้อมูล: เกม `moves_sim.lua:191`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk2_pre` | atk2_pre, atk2_loop, atk2_pst | 31 | facing | 25 | ตามเป้า | bishop_targeting_fx |  | เกม | `moves_sim.lua:192` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `bishop_charge2_fx` |  | อยู่นาน · ดีเลย์ 0 | เกม | `moves_sim.lua:55` |  |
| `bishop_targeting_fx` |  | วาดกับท่าบอส · ดีเลย์ 25 · ตีถึง 25 | เกม | `moves_sim.lua:56` |  |
| `bishop_targeting_fx` |  | วาดกับท่าบอส · ดีเลย์ 25 · ตีถึง 25 | TE | `moves_sim_te.lua:11` |  |

<a id="bishop_nightmareb"></a>

## bishop_nightmareb

แหล่งข้อมูล: TE `moves_sim_te.lua:50`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk2_pre` | atk2_pre, atk2_loop, atk2_pst | 31 | facing | 25 | ตามเป้า | bishop_targeting_fx |  | TE | `moves_sim_te.lua:50` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `bishop_targeting_fx` |  | วาดกับท่าบอส · ดีเลย์ 25 · ตีถึง 25 | TE | `moves_sim_te.lua:11` |  |

<a id="bishopb"></a>

## bishopb

แหล่งข้อมูล: TE `moves_sim_te.lua:51`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk2_pre` | atk2_pre, atk2_loop, atk2_pst | 31 | facing | 25 | ตามเป้า | bishop_targeting_fx |  | TE | `moves_sim_te.lua:51` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `bishop_targeting_fx` |  | วาดกับท่าบอส · ดีเลย์ 25 · ตีถึง 25 | TE | `moves_sim_te.lua:11` |  |

<a id="bishopwater"></a>

## bishopwater

แหล่งข้อมูล: TE `moves_sim_te.lua:52`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk2_pre` | atk2_pre, atk2_loop, atk2_pst | 31 | facing | 25 | ตามเป้า | bishop_targeting_fx |  | TE | `moves_sim_te.lua:52` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `bishop_targeting_fx` |  | วาดกับท่าบอส · ดีเลย์ 25 · ตีถึง 25 | TE | `moves_sim_te.lua:11` |  |

<a id="bishopwaterfixo"></a>

## bishopwaterfixo

แหล่งข้อมูล: TE `moves_sim_te.lua:53`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk2_pre` | atk2_pre, atk2_loop, atk2_pst | 31 | facing | 25 | ตามเป้า | bishop_targeting_fx |  | TE | `moves_sim_te.lua:53` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `bishop_targeting_fx` |  | วาดกับท่าบอส · ดีเลย์ 25 · ตีถึง 25 | TE | `moves_sim_te.lua:11` |  |

<a id="bossboar"></a>

## bossboar

แหล่งข้อมูล: TE `moves_sim_te.lua:54`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1, attack1_pst | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:54` |
| `attack1~combofirsthit` | attack1, attack2 | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:54` |
| `attack3` | attack3 | 3 | target |  |  |  |  | TE | `moves_sim_te.lua` |
| `attack4` | attack4 | 13 | facing | 0 |  |  |  | TE | `moves_sim_te.lua` |
| `attack5` | attack5, taunt | 10 | facing | 0 |  |  |  | TE | `moves_sim_te.lua` |
| `banner_pre` | banner_pre, banner_loop, banner_pst | 40 | target | 53 | ตามเป้า | bossboarfireburst |  | TE | `moves_sim_te.lua` |
| `dash` | dash, attack3 | 22 | target | 0 |  |  |  | TE | `moves_sim_te.lua` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `bossboarfireburst` |  | ดีเลย์ 30 | TE | `moves_sim_te.lua:12` |  |

<a id="bossboarte"></a>

## bossboarte

แหล่งข้อมูล: TE `moves_sim_te.lua:55`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1, attack1_pst | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:55` |
| `attack1~combofirsthit` | attack1, attack2 | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:55` |
| `attack3` | attack3 | 3 | target |  |  |  |  | TE | `moves_sim_te.lua` |
| `attack4` | attack4 | 13 | facing | 0 |  |  |  | TE | `moves_sim_te.lua` |
| `attack5` | attack5, taunt | 10 | facing | 0 |  |  |  | TE | `moves_sim_te.lua` |
| `banner_pre` | banner_pre, banner_loop, banner_pst | 40 | target | 53 | ตามเป้า | bossboarfireburst |  | TE | `moves_sim_te.lua` |
| `dash` | dash, attack3 | 22 | target | 0 |  |  |  | TE | `moves_sim_te.lua` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `bossboarfireburst` |  | ดีเลย์ 30 | TE | `moves_sim_te.lua:12` |  |

<a id="boulder_crab"></a>

## boulder_crab — Boulder Crab

แหล่งข้อมูล: UM `moves_sim_um.lua:132` · มือ-UM `moves_hand_um.lua:37`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk, uppercut | 24 | target | 0 |  |  |  | UM | `moves_sim_um.lua:133` |
| `uppercut` | uppercut | 46 | target |  | รอบตัว |  |  | มือ-UM | `moves_hand_um.lua:37` |

<a id="bulletbee"></a>

## bulletbee — Bullet Bee

แหล่งข้อมูล: UM `moves_sim_um.lua:135`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 | ขนาด 0.9 |  |  | UM | `moves_sim_um.lua:136` |

<a id="bunnyman"></a>

## bunnyman — Bunnyman

แหล่งข้อมูล: เกม `moves_sim.lua:194`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | ขนาด 1.25 |  |  | เกม | `moves_sim.lua:195` |

<a id="bushcrab"></a>

## bushcrab — Bush Crab

แหล่งข้อมูล: UM `moves_sim_um.lua:138`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | UM | `moves_sim_um.lua:139` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | UM | `moves_sim_um.lua:140` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:141` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | เลน |  |  | UM | `moves_sim_um.lua:142` |

<a id="buzzard"></a>

## buzzard — Buzzard

แหล่งข้อมูล: เกม `moves_sim.lua:197`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 13 | target | 0 |  |  |  | เกม | `moves_sim.lua:198` |

