# สารบัญมอน — L

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="lavae"></a>

## lavae — Lavae

แหล่งข้อมูล: เกม `moves_sim.lua:346`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst, taunt | 21 | target | 0 |  |  |  | เกม | `moves_sim.lua:347` |

<a id="lavae2"></a>

## lavae2

แหล่งข้อมูล: UM `moves_sim_um.lua:221`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst, taunt | 21 | target | 0 |  |  |  | UM | `moves_sim_um.lua:222` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `lavaeslime` | Lavae Slime | อยู่นาน · ดีเลย์ 90 | มือ-UM | `moves_hand_um.lua:39` |  |

<a id="leechswarm"></a>

## leechswarm — Leech Swarm

แหล่งข้อมูล: UM `moves_sim_um.lua:224`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pre` | attack_pre, attack_pst | 20 | target | 0 |  |  |  | UM | `moves_sim_um.lua:225` |

<a id="leif"></a>

## leif — Treeguard

แหล่งข้อมูล: เกม `moves_sim.lua:349` · UM `moves_sim_um.lua:227`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 25 | target | 0 |  |  |  | เกม | `moves_sim.lua:350` |
| `atk` ▦ | atk | 25 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:228` |
| `special` | special | 35 | facing | 0 |  |  | snare_cd | UM | `moves_sim_um.lua:229` |
| `special~summon` | special | 35 | facing | 0 |  |  | snare_cd | UM | `moves_sim_um.lua:230` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `rootspike` |  | ดีเลย์ 0 | UM | `moves_sim_um.lua:61` |  |

<a id="lightninggoat"></a>

## lightninggoat — Volt Goat

แหล่งข้อมูล: เกม `moves_sim.lua:352`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | เกม | `moves_sim.lua:353` |

<a id="lightninghound"></a>

## lightninghound — Lightning Hound

แหล่งข้อมูล: UM `moves_sim_um.lua:232`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:233` |

<a id="lizardman"></a>

## lizardman

แหล่งข้อมูล: TE `moves_sim_te.lua:106`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 18 | target | 0 |  |  |  | TE | `moves_sim_te.lua:106` |
| `spit` | spit | 15 | target | 15 |  |  |  | TE | `moves_sim_te.lua:106` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:1069

<a id="lizardman_tfc"></a>

## lizardman_tfc

แหล่งข้อมูล: TE `moves_sim_te.lua:107`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 15 | target | 0 |  |  |  | TE | `moves_sim_te.lua:107` |
| `spit` | spit | 10 | target | 10 |  |  |  | TE | `moves_sim_te.lua:107` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:1066

<a id="lordfruitfly"></a>

## lordfruitfly — Lord of the Fruit Flies

แหล่งข้อมูล: เกม `moves_sim.lua:355`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 8 | target | 0 | ขนาด 2 |  |  | เกม | `moves_sim.lua:356` |

<a id="lunar_grazer"></a>

## lunar_grazer — Grazer

แหล่งข้อมูล: เกม `moves_sim.lua:358`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `devour` | devour | 32 | target | 0 |  |  |  | เกม | `moves_sim.lua:359` |
| `spawn` | spawn | 88 | facing | 0 |  |  |  | เกม | `moves_sim.lua:360` |

<a id="lunarplanttentacle"></a>

## lunarplanttentacle

แหล่งข้อมูล: เกม `moves_sim.lua:362`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk, breach_pst | 15 | target | 0 | ขนาด 0.55 |  |  | เกม | `moves_sim.lua:363` |

<a id="lunarthrall_plant"></a>

## lunarthrall_plant — Deadly Brightshade

แหล่งข้อมูล: เกม `moves_sim.lua:365`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_med` | atk_med | 4 | facing | 0 |  |  |  | เกม | `moves_sim.lua:366` |

<a id="lunarthrall_plant_vine_end"></a>

## lunarthrall_plant_vine_end — Tunneling Vine

แหล่งข้อมูล: เกม `moves_sim.lua:368`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 17 | facing | 0 |  |  | attack_cooldown | เกม | `moves_sim.lua:369` |

<a id="lureplague_rat"></a>

## lureplague_rat — Lureplague Rat

แหล่งข้อมูล: UM `moves_sim_um.lua:235`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 7 | target | 0 |  |  |  | UM | `moves_sim_um.lua:236` |

