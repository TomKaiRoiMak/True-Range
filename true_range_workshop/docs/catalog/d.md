# สารบัญมอน — D

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="daywalker"></a>

## daywalker — Nightmare Werepig

แหล่งข้อมูล: เกม `moves_sim.lua:242`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk3` | atk3, atk3_pst | 1 | facing | 0 |  |  |  | เกม | `moves_sim.lua:243` |
| `atk_slam` | atk_slam | 26 | facing | 20 | ตามเป้า |  |  | เกม | `moves_sim.lua:244` |
| `atk_slam_pre` | atk_slam_pre, atk_slam | 47 | facing | 41 | ตามเป้า |  |  | เกม | `moves_sim.lua:245` |
| `shrug1` | shrug1, shrug_pst | 7 | facing | 0 |  |  |  | เกม | `moves_sim.lua:246` |
| `struggle1` | struggle1, struggle1_pst | 5 | facing | 0 |  |  |  | เกม | `moves_sim.lua:247` |

<a id="daywalker2"></a>

## daywalker2 — Scrappy Werepig

แหล่งข้อมูล: เกม `moves_sim.lua:249`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk3` ▦ | atk3, atk3_pst | 1 | facing | 0 |  |  |  | เกม | `moves_sim.lua:250` |
| `atk_object` ▦ | atk_object, atk_object_pst | 16 | target | 0 |  | daywalker2_swipe_fx |  | เกม | `moves_sim.lua:251` |
| `laser_pre` | laser_pre, laser_pst, hit | 36 | target | 36 |  | alterguardian_laser, alterguardian_laserempty |  | เกม | `moves_sim.lua:252` |
| `laser_pst` | laser_pst, hit | 5 | target | 5 |  | alterguardian_laser, alterguardian_laserempty |  | เกม | `moves_sim.lua:253` |
| `tackle_pre` | tackle_pre, tackle, tackle_lift, hit | 8 | facing | 19 |  |  |  | เกม | `moves_sim.lua:254` |
| `throw_pre` ▦ | throw_pre, throw, throw_pst | 106 | facing | 86 | ตีด้วยของเท่านั้น | junkball_fall_fx, junkball_fx |  | เกม | `moves_sim.lua:255` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `daywalker2_swipe_fx` |  | วาดกับท่าบอส · ดีเลย์ 4 · ตีถึง 4 | เกม | `moves_sim.lua:62` |  |
| `junkball_fall_fx` |  | ดีเลย์ 15 · ตีถึง 15 | เกม | `moves_sim.lua:81` |  |

<a id="deer"></a>

## deer — No-Eyed Deer

แหล่งข้อมูล: เกม `moves_sim.lua:257`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | เกม | `moves_sim.lua:258` |

<a id="deer_blue"></a>

## deer_blue

แหล่งข้อมูล: เกม `moves_sim.lua:260`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | เกม | `moves_sim.lua:261` |
| `atk_magic_pre` ▦ | atk_magic_pre | 20 | target | 21 | ตามเป้า | deer_ice_circle | deercast_cd | เกม | `moves_sim.lua:262` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `deer_ice_circle` |  | อยู่นาน · ดีเลย์ 0 | เกม | `moves_sim.lua:65` | simmoves.lua:4184 |

<a id="deer_red"></a>

## deer_red

แหล่งข้อมูล: เกม `moves_sim.lua:264`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | เกม | `moves_sim.lua:265` |
| `atk_magic_pre` ▦ | atk_magic_pre, atk_magic_pst | 83 | target | 54 | ตามเป้า | deer_fire_circle | deercast_cd | เกม | `moves_sim.lua:266` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `deer_fire_circle` |  | อยู่นาน · ดีเลย์ 30 | เกม | `moves_sim.lua:64` |  |

<a id="deerclops"></a>

## deerclops — Deerclops

แหล่งข้อมูล: เกม `moves_sim.lua:268` · UM `moves_sim_um.lua:162`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 34 | target | 16 | ขนาด 1.65 · ตีด้วยของเท่านั้น | deerclops_icespike_fx |  | เกม | `moves_sim.lua:269` |
| `atk2@MakeEnrageable` | atk2 | 19 | target | 18 | ขนาด 1.85 | deerclops_laser_blue, deerclops_laserempty |  | UM | `moves_sim_um.lua:163` |
| `atk@MakeIcey` | atk | 35 | target | 0 | ขนาด 1.65 |  |  | UM | `moves_sim_um.lua:164` |
| `atk@MakeStrong` | atk | 34 | facing | 16 | ขนาด 1.65 · ตีด้วยของเท่านั้น | deerclops_icespike_fx |  | UM | `moves_sim_um.lua:165` |
| `fortresscast_pre@MakeIcey` | fortresscast_pre, fortresscast_loop | 0 | target | 0 | ขนาด 1.65 | deer_ice_circle |  | UM | `moves_sim_um.lua:166` |
| `ring_pre@MakeEnrageable` | ring_pre, ring_loop, taunt | 31 | facing | 0 | ขนาด 1.85 | deerclops_laser_blue, deerclops_laserempty_blue |  | UM | `moves_sim_um.lua:167` |
| `throw` | throw | 60 | facing | 30 | ขนาด 1.65 | deerclops_icelance_ping_fx, deerclops_impact_circle_fx |  | เกม | `moves_sim.lua:270` |
| `throw` | throw | 60 | facing | 30 | ขนาด 1.85 | deerclops_icelance_ping_fx, deerclops_impact_circle_fx |  | UM | `moves_sim_um.lua:168` |
| `uppercut@MakeStrong` | uppercut | 35 | target |  | รอบตัว · ขนาด 1.65 |  |  | UM | `moves_sim_um.lua:169` |
| `uppercutcombo@MakeStrong` | uppercutcombo | 35 | target | 61 | ตามเป้า · ขนาด 1.65 |  |  | UM | `moves_sim_um.lua:170` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `deer_ice_circle` |  | อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:38` | simmoves.lua:4184 |
| `deerclops_icelance_ping_fx` |  | วาดกับท่าบอส · ดีเลย์ 30 · ตีถึง 30 | เกม | `moves_sim.lua:66` |  |
| `deerclops_icelance_ping_fx` |  | วาดกับท่าบอส · ดีเลย์ 30 · ตีถึง 30 | TE | `moves_sim_te.lua:13` |  |
| `deerclops_icelance_ping_fx` |  | วาดกับท่าบอส · ดีเลย์ 30 · ตีถึง 30 | UM | `moves_sim_um.lua:39` |  |
| `deerclops_icespike_fx` |  | ดีเลย์ 0 · ตีถึง 3 | UM | `moves_sim_um.lua:40` |  |
| `deerclops_icespike_fx` |  | ดีเลย์ 0 · ตีถึง 3 | เกม | `moves_sim.lua:67` |  |
| `deerclops_icespike_fx` |  | ดีเลย์ 0 · ตีถึง 3 | TE | `moves_sim_te.lua:14` |  |
| `deerclops_impact_circle_fx` |  | อยู่นาน · ดีเลย์ 0 | TE | `moves_sim_te.lua:15` |  |
| `deerclops_impact_circle_fx` |  | อยู่นาน · ดีเลย์ 0 | เกม | `moves_sim.lua:68` |  |
| `deerclops_impact_circle_fx` |  | อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:41` |  |
| `deerclops_laser_blue` |  | วาดกับท่าบอส · ดีเลย์ 0 · ตีถึง 73 | UM | `moves_sim_um.lua:42` |  |
| `deerclops_laserempty` |  | วาดกับท่าบอส · ดีเลย์ 0 · ตีถึง 0 | UM | `moves_sim_um.lua:43` |  |
| `deerclops_laserempty_blue` |  | วาดกับท่าบอส · ดีเลย์ 0 · ตีถึง 0 | UM | `moves_sim_um.lua:44` |  |

<a id="deprecated_swilson"></a>

## deprecated_swilson

แหล่งข้อมูล: UM `moves_sim_um.lua:172`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk, walk_loop | 13 | target | 0 |  |  |  | UM | `moves_sim_um.lua:173` |
| `atk~leap_attack` | atk, idle | 19 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:174` |

<a id="doydoybaby"></a>

## doydoybaby

แหล่งข้อมูล: TE `moves_sim_te.lua:60`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 0 |  |  |  | TE | `moves_sim_te.lua:60` |

<a id="dragonfly"></a>

## dragonfly — Dragonfly

แหล่งข้อมูล: เกม `moves_sim.lua:272`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 | ขนาด 1.3 |  |  | เกม | `moves_sim.lua:273` |
| `atk@TransformFire` | atk | 15 | target | 0 | ขนาด 1.3 |  |  | เกม | `moves_sim.lua:274` |
| `taunt_pre@TransformFire` | taunt_pre, taunt, taunt_pst | 20 | facing | 0 | ขนาด 1.3 |  | groundpound_cd | เกม | `moves_sim.lua:275` |

<a id="dragoon"></a>

## dragoon

แหล่งข้อมูล: TE `moves_sim_te.lua:61`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 | ขนาด 1.3 |  |  | TE | `moves_sim_te.lua:61` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `dragoonspit` |  | อยู่นาน · ดีเลย์ 0 | TE | `moves_sim_te.lua:17` | simmoves.lua:3153 |

<a id="dreadeye"></a>

## dreadeye — Dread Eye

แหล่งข้อมูล: UM `moves_sim_um.lua:176`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:177` |

