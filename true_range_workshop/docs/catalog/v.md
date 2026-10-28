# สารบัญมอน — V

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="vampirebat"></a>

## vampirebat

แหล่งข้อมูล: TE `moves_sim_te.lua:194`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 14 | target | 0 | ขนาด 0.9 |  |  | TE | `moves_sim_te.lua:194` |

<a id="vault_crawler"></a>

## vault_crawler — Lustrous Weevil

แหล่งข้อมูล: เกม `moves_sim.lua:634`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 13 | facing | 7 |  |  |  | เกม | `moves_sim.lua:635` |
| `spawn` | spawn | 0 | facing |  | รอบตัว |  |  | เกม | `moves_sim.lua:636` |

<a id="vault_pillar_guard"></a>

## vault_pillar_guard — Ancient Guard Tower

แหล่งข้อมูล: เกม `moves_sim.lua:638`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_1` ▦ | atk_1 | 29 | target | 0 |  |  |  | เกม | `moves_sim.lua:639` |
| `atk_2` ▦ | atk_2, atk_3_pre_a | 26 | target | 0 |  |  |  | เกม | `moves_sim.lua:640` |
| `atk_3_pre_a` | atk_3_pre_a, atk_3, atk_3_pst | 45 | target | 31 | ตามเป้า |  | quickjump_cd | เกม | `moves_sim.lua:641` |
| `atk_3_pre_b` ▦ | atk_3_pre_b, atk_3, atk_3_pst | 45 | target | 31 | ตามเป้า |  | quickjump_cd | เกม | `moves_sim.lua:642` |
| `spin_loop` | spin_loop, spin_pst | 0 | facing |  | รอบตัว |  | spin_cd | เกม | `moves_sim.lua:643` |
| `spin_pre` | spin_pre | 25 | facing | 0 |  |  | spin_cd | เกม | `moves_sim.lua:644` |

<a id="viperling"></a>

## viperling — Writhing Apparition

แหล่งข้อมูล: UM `moves_sim_um.lua:510`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | ขนาด 0.5 |  |  | UM | `moves_sim_um.lua:511` |

<a id="viperlingfriend"></a>

## viperlingfriend — Writhing Apparition

แหล่งข้อมูล: UM `moves_sim_um.lua:513`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | ขนาด 0.5 |  |  | UM | `moves_sim_um.lua:514` |

<a id="viperworm"></a>

## viperworm — Depths Viper

แหล่งข้อมูล: UM `moves_sim_um.lua:516`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | UM | `moves_sim_um.lua:517` |

