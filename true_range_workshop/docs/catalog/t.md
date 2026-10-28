# สารบัญมอน — T

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="tallbird"></a>

## tallbird — Tallbird

แหล่งข้อมูล: เกม `moves_sim.lua:600`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 12 | target | 0 |  |  |  | เกม | `moves_sim.lua:601` |
| `teenatk_pre` | teenatk_pre, teenatk | 13 | target | 0 |  |  |  | เกม | `moves_sim.lua:602` |

<a id="teenbird"></a>

## teenbird — Smallish Tallbird

แหล่งข้อมูล: เกม `moves_sim.lua:604`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 12 | target | 0 | ขนาด 0.8 |  |  | เกม | `moves_sim.lua:605` |
| `teenatk_pre` | teenatk_pre, teenatk | 13 | target | 0 | ขนาด 0.8 |  |  | เกม | `moves_sim.lua:606` |

<a id="tentacle"></a>

## tentacle — Tentacle

แหล่งข้อมูล: เกม `moves_sim.lua:608`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_loop` | atk_loop, atk_idle | 7 | target | 0 |  |  |  | เกม | `moves_sim.lua:609` |
| `atk_pre` | atk_pre, atk_loop, atk_idle | 32 | target | 0 |  |  |  | เกม | `moves_sim.lua:610` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:877

<a id="tentacle_pillar_arm"></a>

## tentacle_pillar_arm — Baby Tentacle

แหล่งข้อมูล: เกม `moves_sim.lua:612`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_loop` | atk_loop, atk_pst | 7 | target | 0 | ขนาด 0.95 |  |  | เกม | `moves_sim.lua:613` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:877

<a id="tentacleunderwater"></a>

## tentacleunderwater

แหล่งข้อมูล: TE `moves_sim_te.lua:188`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk_loop, atk_idle | 32 | target | 0 |  |  |  | TE | `moves_sim_te.lua:188` |

<a id="thunderbird"></a>

## thunderbird

แหล่งข้อมูล: TE `moves_sim_te.lua:189`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|

<a id="ticoon"></a>

## ticoon — Ticoon

แหล่งข้อมูล: เกม `moves_sim.lua:615`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 | ขนาด 1.1 |  |  | เกม | `moves_sim.lua:616` |

<a id="tigershark"></a>

## tigershark

แหล่งข้อมูล: TE `moves_sim_te.lua:190`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 23 | facing | 0 |  |  | Run | TE | `moves_sim_te.lua:190` |
| `launch_down_pst` | launch_down_pst | 0 | facing |  | รอบตัว |  |  | TE | `moves_sim_te.lua` |
| `launch_up_pre` | launch_up_pre, launch_up_loop | 0 | facing |  | รอบตัว |  |  | TE | `moves_sim_te.lua` |
| `launch_up_pre~jump` | launch_up_pre, launch_up_loop | 0 | facing |  | รอบตัว · เคลื่อน 1.0 |  |  | TE | `moves_sim_te.lua` |
| `water_atk_pre` | water_atk_pre, water_atk, water_atk_pst | 27 | facing | 0 |  |  | Run | TE | `moves_sim_te.lua` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:960

<a id="tikiman"></a>

## tikiman

แหล่งข้อมูล: TE `moves_sim_te.lua:191`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 17 | target | 0 | ขนาด 1.25 |  |  | TE | `moves_sim_te.lua:191` |

<a id="toadstool"></a>

## toadstool — Toadstool

แหล่งข้อมูล: เกม `moves_sim.lua:618`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pound_pre` ▦ | attack_pound_pre, attack_pound_loop, attack_pound_pst | 36 | facing | 0 |  |  | pound_cd | เกม | `moves_sim.lua:619` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `mushroombomb` | Boomshroom | ดีเลย์ 95 | เกม | `moves_sim.lua:85` |  |

<a id="toadstool_dark"></a>

## toadstool_dark — Misery Toadstool

แหล่งข้อมูล: เกม `moves_sim.lua:621`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pound_pre` | attack_pound_pre, attack_pound_loop, attack_pound_pst | 36 | facing | 0 |  |  | pound_cd | เกม | `moves_sim.lua:622` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `mushroombomb_dark` | Misery Boomshroom | ดีเลย์ 95 | เกม | `moves_sim.lua:86` |  |

<a id="treeguard"></a>

## treeguard

แหล่งข้อมูล: TE `moves_sim_te.lua:192`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:192` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `warningshadow` |  | เคลื่อนที่ · อยู่นาน · ดีเลย์ 0 · ตีถึง 60 | TE | `moves_sim_te.lua:32` | predict.lua:3734 predict.lua:3749 |

**โค้ดพิเศษที่อ้างถึง:** predict.lua:3741

<a id="tricktreatpigman"></a>

## tricktreatpigman

แหล่งข้อมูล: UM `moves_sim_um.lua:425`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | UM | `moves_sim_um.lua:426` |
| `counter_atk` | counter_atk, charge_pre, charge_loop, charge_atk | 54 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:427` |
| `counter_atk~counterattack_pre` | counter_atk, charge_pre, charge_loop, charge_atk | 54 | facing | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:428` |
| `paw_loop` | paw_loop, charge_pre, charge_loop, charge_atk | 74 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:429` |
| `paw_pre` | paw_pre, paw_loop, charge_pre, charge_loop, … | 79 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:430` |

<a id="twinofterror1"></a>

## twinofterror1 — Retinazor

แหล่งข้อมูล: เกม `moves_sim.lua:624` · UM `moves_sim_um.lua:432`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `charge_pre` | charge_pre, charge_loop, charge_pst | 34 | facing | 11 | เคลื่อน 20.0 |  | charge_cd | เกม | `moves_sim.lua:625` |
| `charge_pre~charge_pre` | charge_pre, charge_loop, charge_pst, taunt | 34 | facing | 105 | พุ่งเป็นขา · เคลื่อน 15.4 |  | charge_cd | เกม | `moves_sim.lua:626` |
| `charge_pre~shoot_pre` | charge_pre, charge_loop, charge_pst, taunt | 34 | target | 34 | แยกด้วย eyeofterror_chargepulse | eyeofterror_laser, eyeofterror_laserempty | charge_cd | UM | `moves_sim_um.lua:433` |
| `charge_pre~shoot_pre~2` | charge_pre, charge_loop, charge_pst | 34 | target | 50 | แยกด้วย eyeofterror_chargepulse | eyeofterror_laser, eyeofterror_laserempty | charge_cd | UM | `moves_sim_um.lua:434` |
| `chomp` ▦ | chomp, taunt | 25 | facing | 0 |  |  |  | เกม | `moves_sim.lua:627` |
| `shoot` | shoot | 11 | target | 11 |  | eyeofterror_laser, eyeofterror_laserempty |  | UM | `moves_sim_um.lua:435` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `eyeofterror_laser` |  | ดีเลย์ 1 | UM | `moves_sim_um.lua:46` |  |
| `eyeofterror_laserempty` |  | ดีเลย์ 0 | UM | `moves_sim_um.lua:47` |  |

**โค้ดพิเศษที่อ้างถึง:** simmoves.lua:3200 simmoves.lua:3207

<a id="twinofterror2"></a>

## twinofterror2 — Spazmatism

แหล่งข้อมูล: เกม `moves_sim.lua:629` · UM `moves_sim_um.lua:437` · มือ-UM `moves_hand_um.lua:16`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `charge_pre` | charge_pre, charge_loop, charge_pst | 34 | facing | 11 | เคลื่อน 9.2 |  |  | เกม | `moves_sim.lua:630` |
| `charge_pre~charge_pre` | charge_pre, charge_loop, charge_pst | 34 | facing | 93 | พุ่งเป็นขา · เคลื่อน 12.5 |  | charge_cd | เกม | `moves_sim.lua:631` |
| `charge_pre~shoot_pre` | charge_pre, charge_loop, charge_pst | 34 | target | 34 | แยกด้วย eyeofterror_chargepulse |  | charge_cd | มือ-UM | `moves_hand_um.lua:17` |
| `charge_pre~shoot_pre~2` | charge_pre, charge_loop, charge_pst | 34 | target | 34 | แยกด้วย eyeofterror_chargepulse |  | charge_cd | มือ-UM | `moves_hand_um.lua:18` |
| `chomp` ▦ | chomp, taunt | 25 | facing | 0 |  |  |  | เกม | `moves_sim.lua:632` |
| `shoot` | shoot | 11 | target | 11 |  | eyeofterror_laser, eyeofterror_laserempty |  | UM | `moves_sim_um.lua:438` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `cursed_fire` |  | อยู่นาน · ดีเลย์ 15 | UM | `moves_sim_um.lua:37` |  |
| `eyeofterror_fireball` |  | เคลื่อนที่ · ดีเลย์ 0 | UM | `moves_sim_um.lua:45` |  |
| `eyeofterror_laser` |  | ดีเลย์ 1 | UM | `moves_sim_um.lua:46` |  |
| `eyeofterror_laserempty` |  | ดีเลย์ 0 | UM | `moves_sim_um.lua:47` |  |

**โค้ดพิเศษที่อ้างถึง:** simmoves.lua:3200

<a id="twister"></a>

## twister

แหล่งข้อมูล: TE `moves_sim_te.lua:193`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 33 | facing | 0 | ขนาด 1 |  |  | TE | `moves_sim_te.lua:193` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:916

