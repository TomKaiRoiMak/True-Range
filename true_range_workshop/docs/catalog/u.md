# สารบัญมอน — U

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="um_bee_moon"></a>

## um_bee_moon — Carrion Bee

แหล่งข้อมูล: UM `moves_sim_um.lua:440`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 |  |  |  | UM | `moves_sim_um.lua:441` |

<a id="um_beeguard_blocker"></a>

## um_beeguard_blocker — Blocker Bee

แหล่งข้อมูล: UM `moves_sim_um.lua:443` · มือ-UM `moves_hand_um.lua:28`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | ขนาด 1.6 |  |  | มือ-UM | `moves_hand_um.lua:28` |
| `atk` | atk | 13 | target | 0 | ขนาด 1.6 |  |  | UM | `moves_sim_um.lua:444` |
| `stab_pre` | stab_pre, stab, stab_pst, stuck_loop, … | 3 | facing |  | รอบตัว · ขนาด 1.6 |  |  | UM | `moves_sim_um.lua:445` |
| `stab_pst` | stab_pst | 3 | facing | 0 |  |  |  | มือ-UM | `moves_hand_um.lua:28` |
| `stab_pst` | stab_pst, stuck_loop, stuck_pst | 3 | facing |  | รอบตัว · ขนาด 1.6 |  |  | UM | `moves_sim_um.lua:446` |

**โค้ดพิเศษที่อ้างถึง:** simmoves.lua:3160

<a id="um_beeguard_seeker"></a>

## um_beeguard_seeker — Bomber Bee

แหล่งข้อมูล: UM `moves_sim_um.lua:448` · มือ-UM `moves_hand_um.lua:29`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | ขนาด 1.2 |  |  | มือ-UM | `moves_hand_um.lua:29` |
| `atk` | atk, ascend_pre | 13 | target | 0 | ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:449` |
| `stab_death` | stab_death | 3 | facing | 0 |  |  |  | มือ-UM | `moves_hand_um.lua:29` |
| `stab_death` | stab_death | 3 | facing |  | รอบตัว · ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:450` |
| `stab_pre` | stab_pre, stab, stab_death | 3 | facing |  | รอบตัว · ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:451` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `warningshadow` |  | เคลื่อนที่ · อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:79` | predict.lua:3734 predict.lua:3749 |

**โค้ดพิเศษที่อ้างถึง:** simmoves.lua:3161

<a id="um_beeguard_shooter"></a>

## um_beeguard_shooter — Bullet Bee

แหล่งข้อมูล: UM `moves_sim_um.lua:453` · มือ-UM `moves_hand_um.lua:30`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | ขนาด 1.2 |  |  | มือ-UM | `moves_hand_um.lua:30` |
| `atk` | atk | 13 | target | 0 | ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:454` |
| `stab_pre` | stab_pre, stab, stab_pst, stuck_loop, … | 3 | facing |  | รอบตัว · ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:455` |
| `stab_pst` | stab_pst | 3 | facing | 0 |  |  |  | มือ-UM | `moves_hand_um.lua:30` |
| `stab_pst` | stab_pst, stuck_loop, stuck_pst | 3 | facing |  | รอบตัว · ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:456` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `um_beestinger_projectile` |  | เคลื่อนที่ · อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:67` | modmain.lua:1041 |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:1041 simmoves.lua:3162

<a id="um_fern_fox"></a>

## um_fern_fox — Ferned Fox

แหล่งข้อมูล: UM `moves_sim_um.lua:458`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | UM | `moves_sim_um.lua:459` |

<a id="um_ocupus_tentacle"></a>

## um_ocupus_tentacle — Tentacle

แหล่งข้อมูล: UM `moves_sim_um.lua:461`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `clamp_counter` | clamp_counter, clamp | 29 | facing | 0 | ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:462` |

<a id="um_pepperdragon"></a>

## um_pepperdragon — Capsidragon

แหล่งข้อมูล: UM `moves_sim_um.lua:464`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `bite` | bite | 16 | target | 0 | ขนาด 1.5 |  |  | UM | `moves_sim_um.lua:465` |
| `flame_loop` | flame_loop, flame_pst | 5 | target |  | รอบตัว · ขนาด 1.5 |  | flame_cd | UM | `moves_sim_um.lua:466` |
| `pound` | pound | 36 | facing | 0 | ขนาด 1.5 |  |  | UM | `moves_sim_um.lua:467` |

**โค้ดพิเศษที่อ้างถึง:** simmoves.lua:3213

<a id="um_ribopod"></a>

## um_ribopod — Ribopod

แหล่งข้อมูล: UM `moves_sim_um.lua:469`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 12 | target | 0 | ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:470` |

<a id="um_shadow_wes"></a>

## um_shadow_wes — Wes?

แหล่งข้อมูล: UM `moves_sim_um.lua:472`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `build_pre` | build_pre, build_loop, build_pst | 50 | target | 0 |  | um_shadow_balloon |  | UM | `moves_sim_um.lua:473` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `um_shadow_balloon` |  | อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:72` |  |

<a id="um_shambler"></a>

## um_shambler

แหล่งข้อมูล: UM `moves_sim_um.lua:475`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `eat_90s` | eat_90s | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:476` |

<a id="um_tentacle_moon"></a>

## um_tentacle_moon — Gros Tentacle

แหล่งข้อมูล: UM `moves_sim_um.lua:478`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack_land` | attack_land, attack_pst_land | 7 | target | 0 | ขนาด 1.25 |  |  | UM | `moves_sim_um.lua:479` |
| `attack_pre_land` | attack_pre_land, attack_land, attack_pst_land | 20 | target | 0 | ขนาด 1.25 |  |  | UM | `moves_sim_um.lua:480` |
| `attack_pre_land~attack_pre_old` | attack_pre_land, attack_land, attack_pst_land | 20 | target | 0 | ขนาด 1.25 |  |  | UM | `moves_sim_um.lua:481` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `um_tentacle_moon_projectile` |  | เคลื่อนที่ · ดีเลย์ 20 | UM | `moves_sim_um.lua:77` |  |

<a id="um_vampirebat"></a>

## um_vampirebat — Adult Batilisk

แหล่งข้อมูล: UM `moves_sim_um.lua:483`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 11 | target | 0 | ขนาด 0.9 |  |  | UM | `moves_sim_um.lua:484` |

<a id="uncompromising_buffrat"></a>

## uncompromising_buffrat

แหล่งข้อมูล: UM `moves_sim_um.lua:486`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1, attack1_pst | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:487` |
| `attack2` | attack2, attack2_pst | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:488` |
| `attack3` | attack3 | 7 | target | 0 |  |  |  | UM | `moves_sim_um.lua:489` |
| `bellyflop_block_pre` | bellyflop_block_pre, bellyflop, taunt | 19 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:490` |
| `bellyflop_pre` | bellyflop_pre, bellyflop, taunt | 19 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:491` |
| `block_counter` | block_counter | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:492` |
| `block_pst` | block_pst, taunt2 | 12 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:493` |

<a id="uncompromising_caverat"></a>

## uncompromising_caverat — Cave Rat

แหล่งข้อมูล: UM `moves_sim_um.lua:495`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 7 | target | 0 |  |  |  | UM | `moves_sim_um.lua:496` |

<a id="uncompromising_junkrat"></a>

## uncompromising_junkrat

แหล่งข้อมูล: UM `moves_sim_um.lua:498`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 7 | target | 0 | ขนาด 1.25 |  |  | UM | `moves_sim_um.lua:499` |

<a id="uncompromising_packrat"></a>

## uncompromising_packrat — Pack Rat

แหล่งข้อมูล: UM `moves_sim_um.lua:501`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 7 | target | 0 |  |  |  | UM | `moves_sim_um.lua:502` |

<a id="uncompromising_rat"></a>

## uncompromising_rat — Rat

แหล่งข้อมูล: UM `moves_sim_um.lua:504`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 7 | target | 0 |  |  |  | UM | `moves_sim_um.lua:505` |

<a id="uncompromising_toad"></a>

## uncompromising_toad — Sickly Frog

แหล่งข้อมูล: UM `moves_sim_um.lua:507`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 25 | target | 0 |  |  |  | UM | `moves_sim_um.lua:508` |

