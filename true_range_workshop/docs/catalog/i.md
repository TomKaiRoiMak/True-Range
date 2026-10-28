# สารบัญมอน — I

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="ice_deer"></a>

## ice_deer

แหล่งข้อมูล: TE `moves_sim_te.lua:96`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:96` |

<a id="icedeerclops"></a>

## icedeerclops

แหล่งข้อมูล: TE `moves_sim_te.lua:97`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 34 | target | 16 | ขนาด 1.65 · ตีด้วยของเท่านั้น | deerclops_icespike_fx |  | TE | `moves_sim_te.lua:97` |
| `throw` | throw | 60 | facing | 30 | ขนาด 1.65 | deerclops_icelance_ping_fx, deerclops_impact_circle_fx |  | TE | `moves_sim_te.lua:97` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `deerclops_icelance_ping_fx` |  | วาดกับท่าบอส · ดีเลย์ 30 · ตีถึง 30 | TE | `moves_sim_te.lua:13` |  |
| `deerclops_icespike_fx` |  | ดีเลย์ 0 · ตีถึง 3 | TE | `moves_sim_te.lua:14` |  |
| `deerclops_impact_circle_fx` |  | อยู่นาน · ดีเลย์ 0 | TE | `moves_sim_te.lua:15` |  |

<a id="icehoundb"></a>

## icehoundb

แหล่งข้อมูล: TE `moves_sim_te.lua:98`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:98` |

