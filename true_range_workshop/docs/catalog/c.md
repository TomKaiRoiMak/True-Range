# สารบัญมอน — C

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="catcoon"></a>

## catcoon — Catcoon

แหล่งข้อมูล: เกม `moves_sim.lua:200` · UM `moves_sim_um.lua:144`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 |  |  |  | เกม | `moves_sim.lua:201` |
| `atk` | atk | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:145` |
| `jump_atk` | jump_atk | 19 | target | 0 | ตามเป้า |  |  | เกม | `moves_sim.lua:202` |
| `jump_atk` | jump_atk | 19 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:146` |
| `jump_grab` | jump_grab | 31 | target | 0 |  |  |  | เกม | `moves_sim.lua:203` |
| `jump_grab` | jump_grab | 31 | target | 0 |  |  |  | UM | `moves_sim_um.lua:147` |
| `taunt_pre` | taunt_pre, taunt, taunt_pst, jump_atk | 43 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:148` |

<a id="cave_vent_mite"></a>

## cave_vent_mite — Geothermite

แหล่งข้อมูล: เกม `moves_sim.lua:205`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 0 |  |  |  | เกม | `moves_sim.lua:206` |

<a id="charlie_boss"></a>

## charlie_boss — Shrouded Queen

แหล่งข้อมูล: เกม `moves_sim.lua:208`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `aoe` | aoe | 19 | facing | 0 |  |  |  | เกม | `moves_sim.lua:209` |
| `castlift` | castlift | 33 | facing | 22 | ตีด้วยของเท่านั้น | charlie_boss_minion1, charlie_boss_minion2 |  | เกม | `moves_sim.lua:210` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `charlie_boss_minion1` |  | เคลื่อนที่ · ดีเลย์ 0 · ตีถึง 18 | เกม | `moves_sim.lua:57` | simmoves.lua:3177 |
| `charlie_boss_minion2` |  | เคลื่อนที่ · ดีเลย์ 0 · ตีถึง 14 | เกม | `moves_sim.lua:58` | simmoves.lua:3178 |
| `charlie_boss_projectile` | Swarming Horror | อยู่นาน · ดีเลย์ 0 | เกม | `moves_sim.lua:59` |  |
| `charlie_boss_vines` |  | อยู่นาน · ดีเลย์ 0 | เกม | `moves_sim.lua:60` | simmoves.lua:3184 |
| `charliearena_spike` | Dreadstone Outcrop | ดีเลย์ 29 | เกม | `moves_sim.lua:61` | simmoves.lua:3166 |

<a id="charlie_boss_runner"></a>

## charlie_boss_runner — Grim Harrier

แหล่งข้อมูล: เกม `moves_sim.lua:212` · มือ `moves_hand.lua:51`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 16 | target | 6 | ตามเป้า |  |  | มือ | `moves_hand.lua:51` |
| `attack_quick` | attack_quick | 11 | target | 6 | ตามเป้า |  |  | เกม | `moves_sim.lua:213` |

**โค้ดพิเศษที่อ้างถึง:** simmoves.lua:27

<a id="cherrybulletbee"></a>

## cherrybulletbee — Bullet Hibeescus

แหล่งข้อมูล: UM `moves_sim_um.lua:150`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 | ขนาด 0.9 |  |  | UM | `moves_sim_um.lua:151` |

<a id="chest_mimic_revealed"></a>

## chest_mimic_revealed — Ornery Chest

แหล่งข้อมูล: เกม `moves_sim.lua:215`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack, taunt_pre | 18 | target | 0 |  |  |  | เกม | `moves_sim.lua:216` |
| `spawn` | spawn, taunt_pre | 38 | target | 0 |  |  |  | เกม | `moves_sim.lua:217` |

<a id="chimp"></a>

## chimp — Random Chimp

แหล่งข้อมูล: UM `moves_sim_um.lua:153`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 17 | target | 0 |  |  |  | UM | `moves_sim_um.lua:154` |

<a id="clayhoundb"></a>

## clayhoundb

แหล่งข้อมูล: TE `moves_sim_te.lua:56`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, howl | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:56` |

<a id="commonfish"></a>

## commonfish

แหล่งข้อมูล: TE `moves_sim_te.lua:57`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 | ขนาด 1 |  |  | TE | `moves_sim_te.lua:57` |

<a id="cookiecutter"></a>

## cookiecutter — Cookie Cutter

แหล่งข้อมูล: เกม `moves_sim.lua:219` · TE `moves_sim_te.lua:58`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `hit` | hit, attack_loop, drill_pst | 25 | facing | 0 | เคลื่อน 11.1 |  |  | เกม | `moves_sim.lua:220` |
| `hit` | hit, attack_loop, drill_pst | 25 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:58` |
| `jump_pre` | jump_pre, jumping, jump_pst_water | 28 | facing | 0 |  |  |  | เกม | `moves_sim.lua:221` |

<a id="cozy_bunnyman"></a>

## cozy_bunnyman — Cozy Bunnyman

แหล่งข้อมูล: เกม `moves_sim.lua:223`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | ขนาด 1.25 |  |  | เกม | `moves_sim.lua:224` |
| `atk_object` | atk_object | 9 | target | 0 | ขนาด 1.25 |  |  | เกม | `moves_sim.lua:225` |

<a id="crabking"></a>

## crabking — Crab King

แหล่งข้อมูล: เกม `moves_sim.lua:227`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `crabking_geyser_single` |  | อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:36` |  |

<a id="crabking_claw"></a>

## crabking_claw — Imposing Claw

แหล่งข้อมูล: เกม `moves_sim.lua:228`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 21 | facing | 0 | ขนาด 0.7 |  |  | เกม | `moves_sim.lua:229` |

<a id="crabking_mob"></a>

## crabking_mob — Crab Guard

แหล่งข้อมูล: เกม `moves_sim.lua:231`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk1` | atk1 | 18 | target | 0 |  |  |  | เกม | `moves_sim.lua:232` |
| `atk_pre` ▦ | atk_pre, atk_loop, atk_pst | 14 | target | 14 |  |  |  | เกม | `moves_sim.lua:233` |

<a id="crabking_mob_knight"></a>

## crabking_mob_knight — Crab Knight

แหล่งข้อมูล: เกม `moves_sim.lua:235`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk1` | atk1 | 18 | target | 0 | ขนาด 1.7 |  |  | เกม | `moves_sim.lua:236` |
| `atk_pre` | atk_pre, atk_loop, atk_pst | 14 | target | 14 |  |  |  | เกม | `moves_sim.lua:237` |

<a id="crawlinghorror"></a>

## crawlinghorror — Crawling Horror

แหล่งข้อมูล: เกม `moves_sim.lua:239` · UM `moves_sim_um.lua:156`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, taunt | 16 | target | 0 |  |  |  | เกม | `moves_sim.lua:240` |
| `atk_pre~terrorattack` | atk_pre, atk, taunt | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:157` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `shadow_goo` | Shadow Ink | เคลื่อนที่ · ดีเลย์ 0 | UM | `moves_sim_um.lua:63` |  |

<a id="creepingfear"></a>

## creepingfear — Creeping Fear

แหล่งข้อมูล: UM `moves_sim_um.lua:159`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, taunt | 16 | target | 0 | ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:160` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `uncompromising_shadow_projectile1_fx_fast` |  | ดีเลย์ 18 · ตีถึง 18 | UM | `moves_sim_um.lua:78` |  |

<a id="crocodog"></a>

## crocodog

แหล่งข้อมูล: TE `moves_sim_te.lua:59`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 20 | target | 0 |  |  |  | TE | `moves_sim_te.lua:59` |

