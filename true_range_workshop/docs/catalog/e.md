# สารบัญมอน — E

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="elephantcactus_active"></a>

## elephantcactus_active

แหล่งข้อมูล: TE `moves_sim_te.lua:62`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pre` | attack_pre, attack | 30 | facing | 0 |  |  | SPIKE | TE | `moves_sim_te.lua:62` |

<a id="eyeofterror"></a>

## eyeofterror — Eye Of Terror

แหล่งข้อมูล: เกม `moves_sim.lua:277` · UM `moves_sim_um.lua:179` · มือ-UM `moves_hand_um.lua:12`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `charge_pre` | charge_pre, charge_loop, charge_pst | 34 | facing | 11 | เคลื่อน 15.0 |  | charge_cd | เกม | `moves_sim.lua:278` |
| `charge_pre~charge_pre` | charge_pre, charge_loop, charge_pst, taunt | 34 | facing | 123 | พุ่งเป็นขา · เคลื่อน 18.8 |  | charge_cd | เกม | `moves_sim.lua:279` |
| `charge_pre~shoot_pre` | charge_pre, charge_loop, charge_pst | 39 | target | 39 | แยกด้วย eyeofterror_chargepulse |  | charge_cd | มือ-UM | `moves_hand_um.lua:13` |
| `charge_pre~shoot_pre~2` | charge_pre, charge_loop, charge_pst | 39 | target | 39 | แยกด้วย eyeofterror_chargepulse |  | charge_cd | มือ-UM | `moves_hand_um.lua:14` |
| `chomp` ▦ | chomp, taunt | 25 | facing | 0 |  |  |  | เกม | `moves_sim.lua:280` |
| `shoot` | shoot | 11 | target | 11 |  | eyeofterror_laser, eyeofterror_laserempty |  | UM | `moves_sim_um.lua:180` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `eyeofterror_laser` |  | ดีเลย์ 1 | UM | `moves_sim_um.lua:46` |  |
| `eyeofterror_laserempty` |  | ดีเลย์ 0 | UM | `moves_sim_um.lua:47` |  |
| `eyeofterror_minieye_projectile` |  | เคลื่อนที่ · ดีเลย์ 0 | UM | `moves_sim_um.lua:48` | modmain.lua:1051 |

**โค้ดพิเศษที่อ้างถึง:** simmoves.lua:3200

<a id="eyeofterror_mini"></a>

## eyeofterror_mini — Suspicious Peeper

แหล่งข้อมูล: เกม `moves_sim.lua:282`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, taunt | 14 | target | 0 | เคลื่อน 2.3 |  |  | เกม | `moves_sim.lua:283` |

<a id="eyeofterror_mini_ally"></a>

## eyeofterror_mini_ally — Hardy Peeper

แหล่งข้อมูล: UM `moves_sim_um.lua:182`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, taunt | 14 | target | 0 | ขนาด 1.2 · เคลื่อน 2.7 |  |  | UM | `moves_sim_um.lua:183` |

<a id="eyeplant"></a>

## eyeplant — Eye Plant

แหล่งข้อมูล: เกม `moves_sim.lua:285`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 14 | target | 0 |  |  |  | เกม | `moves_sim.lua:286` |

