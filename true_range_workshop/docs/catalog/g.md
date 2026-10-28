# สารบัญมอน — G

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="gatorsnake"></a>

## gatorsnake

แหล่งข้อมูล: UM `moves_sim_um.lua:188`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk, head_idle_pst, atk_pre | 25 | target |  | เคลื่อน 1.0 |  |  | UM | `moves_sim_um.lua:189` |

<a id="gestalt"></a>

## gestalt — Gestalt

แหล่งข้อมูล: เกม `moves_sim.lua:305`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack, mutate | 8 | target |  | เคลื่อน 11.2 |  |  | เกม | `moves_sim.lua:306` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:675 modmain.lua:698

<a id="gestalt_guard"></a>

## gestalt_guard — Greater Gestalt

แหล่งข้อมูล: เกม `moves_sim.lua:308`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack, mutate | 8 | target |  | ขนาด 0.8 · เคลื่อน 9.7 |  |  | เกม | `moves_sim.lua:309` |

<a id="gestalt_guard_evolved"></a>

## gestalt_guard_evolved — Inimical Gestalt

แหล่งข้อมูล: เกม `moves_sim.lua:311`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 15 | target | 0 | ขนาด 0.8 · เคลื่อน 5.3 |  |  | เกม | `moves_sim.lua:312` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `gestalt_guard_projectile` |  | ดีเลย์ 0 · ตีถึง 49 | เกม | `moves_sim.lua:76` |  |

<a id="giantgrub"></a>

## giantgrub

แหล่งข้อมูล: TE `moves_sim_te.lua:75`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `action` | action | 4 | target | 0 | ขนาด 3 |  |  | TE | `moves_sim_te.lua:75` |
| `exit` | exit | 22 | facing | 0 | ขนาด 3 |  |  | TE | `moves_sim_te.lua:75` |

<a id="giantsnow"></a>

## giantsnow

แหล่งข้อมูล: TE `moves_sim_te.lua:76`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `action` | action | 4 | target | 0 | ขนาด 3 |  |  | TE | `moves_sim_te.lua:76` |

<a id="glacialhound"></a>

## glacialhound — Glacial Varglet

แหล่งข้อมูล: UM `moves_sim_um.lua:191`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 | ขนาด 1.3 |  |  | UM | `moves_sim_um.lua:192` |
| `atk_pre~ice_howl_attack` | atk_pre | 8 | target | 5 | ขนาด 1.3 · ตีด้วยของเท่านั้น | glacialhound_icespike |  | UM | `moves_sim_um.lua:193` |
| `scared_pre` | scared_pre, scared_loop, scared_pst | 51 | target | 49 | ขนาด 1.3 · ตีด้วยของเท่านั้น | glacialhound_icespike | lightningshot_cooldown | UM | `moves_sim_um.lua:194` |
| `scared_pst` | scared_pst | 12 | target | 10 | ขนาด 1.3 · ตีด้วยของเท่านั้น | glacialhound_icespike |  | UM | `moves_sim_um.lua:195` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `glacialhound_icespike` | Ice Spike | ดีเลย์ 0 · ตีถึง 3 | UM | `moves_sim_um.lua:51` |  |

<a id="glowfly"></a>

## glowfly

แหล่งข้อมูล: TE `moves_sim_te.lua:77`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 | ขนาด 0.6 |  |  | TE | `moves_sim_te.lua:77` |

<a id="glowfly_cocoon"></a>

## glowfly_cocoon

แหล่งข้อมูล: TE `moves_sim_te.lua:78`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 | ขนาด 0.6 |  |  | TE | `moves_sim_te.lua:78` |

<a id="gnarwail"></a>

## gnarwail — Gnarwail

แหล่งข้อมูล: เกม `moves_sim.lua:314` · TE `moves_sim_te.lua:79`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack_2` | attack_2 | 33 | target | 0 |  |  |  | เกม | `moves_sim.lua:315` |
| `attack_2` | attack_2 | 33 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:79` |

<a id="gnarwailunderwater"></a>

## gnarwailunderwater

แหล่งข้อมูล: TE `moves_sim_te.lua:80`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack_2` | attack_2 | 33 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:80` |
| `attack_2~body_slam` | attack_2 | 33 | target | 0 |  |  |  | TE | `moves_sim_te.lua:80` |
| `attack_2~body_slam_hide` | attack_2 | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua` |
| `bite` | bite | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua` |

<a id="gnat"></a>

## gnat

แหล่งข้อมูล: TE `moves_sim_te.lua:81`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pre` | attack_pre, attack_pst | 20 | target | 0 |  |  |  | TE | `moves_sim_te.lua:81` |

<a id="goddess_deer"></a>

## goddess_deer

แหล่งข้อมูล: TE `moves_sim_te.lua:82`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 | ขนาด 0.8 |  |  | TE | `moves_sim_te.lua:82` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `greentornado2` |  | เคลื่อนที่ · อยู่นาน · ดีเลย์ 0 | TE | `moves_sim_te.lua:19` |  |

<a id="goddess_deer_gem"></a>

## goddess_deer_gem

แหล่งข้อมูล: TE `moves_sim_te.lua:83`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:83` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `greentornado2` |  | เคลื่อนที่ · อยู่นาน · ดีเลย์ 0 | TE | `moves_sim_te.lua:19` |  |

<a id="goddess_spider_hostile"></a>

## goddess_spider_hostile

แหล่งข้อมูล: TE `moves_sim_te.lua:84`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:84` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua:84` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | เลน |  |  | TE | `moves_sim_te.lua:84` |

<a id="goddess_sword"></a>

## goddess_sword

แหล่งข้อมูล: TE `moves_sim_te.lua:85`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 | ขนาด 2.3 |  |  | TE | `moves_sim_te.lua:85` |

<a id="goldbishop"></a>

## goldbishop

แหล่งข้อมูล: TE `moves_sim_te.lua:86`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk2_pre` | atk2_pre, atk2_loop, atk2_pst | 31 | facing | 25 | ตามเป้า | bishop_targeting_fx |  | TE | `moves_sim_te.lua:86` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `bishop_targeting_fx` |  | วาดกับท่าบอส · ดีเลย์ 25 · ตีถึง 25 | TE | `moves_sim_te.lua:11` |  |

<a id="goldfish_alive"></a>

## goldfish_alive

แหล่งข้อมูล: TE `moves_sim_te.lua:87`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `walk_loop` | walk_loop | 10 | target | 0 | ขนาด 1 |  |  | TE | `moves_sim_te.lua:87` |

<a id="goldmonkey"></a>

## goldmonkey

แหล่งข้อมูล: TE `moves_sim_te.lua:88`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 17 | target | 0 |  |  |  | TE | `moves_sim_te.lua:88` |

<a id="grabbing_vine"></a>

## grabbing_vine

แหล่งข้อมูล: TE `moves_sim_te.lua:89`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 15 | target | 0 |  |  |  | TE | `moves_sim_te.lua:89` |

<a id="grabbing_vinefixo"></a>

## grabbing_vinefixo

แหล่งข้อมูล: TE `moves_sim_te.lua:90`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 15 | target | 0 |  |  |  | TE | `moves_sim_te.lua:90` |

<a id="grassgator"></a>

## grassgator — Grass Gator

แหล่งข้อมูล: เกม `moves_sim.lua:317`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 15 | target | 0 |  |  |  | เกม | `moves_sim.lua:318` |

<a id="greententacle"></a>

## greententacle

แหล่งข้อมูล: TE `moves_sim_te.lua:91`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_loop` | atk_loop, atk_idle | 7 | target | 0 |  |  |  | TE | `moves_sim_te.lua:91` |
| `atk_pre` | atk_pre, atk_loop, atk_idle | 32 | target | 0 |  |  |  | TE | `moves_sim_te.lua:91` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:1057

<a id="gw_yellow_lizardman"></a>

## gw_yellow_lizardman

แหล่งข้อมูล: TE `moves_sim_te.lua:92`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 18 | target | 0 | ขนาด 1.2 |  |  | TE | `moves_sim_te.lua:92` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:899

