# สารบัญมอน — M

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="magmahound"></a>

## magmahound — Magma Varglet

แหล่งข้อมูล: UM `moves_sim_um.lua:238`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, taunt | 16 | target | 0 | ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:239` |
| `scared_pre` | scared_pre, burningup, scared_pst, belch | 48 | facing |  | รอบตัว · ขนาด 1.2 |  | lightningshot_cooldown | UM | `moves_sim_um.lua:240` |
| `scared_pst` | scared_pst, belch | 9 | facing |  | รอบตัว · ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:241` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `um_fire_projectile` |  | เคลื่อนที่ · อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:68` | simmoves.lua:4185 |

**โค้ดพิเศษที่อ้างถึง:** simmoves.lua:3213

<a id="malbatross"></a>

## malbatross — Malbatross

แหล่งข้อมูล: เกม `moves_sim.lua:371` · UM `moves_sim_um.lua:243` · TE `moves_sim_te.lua:108`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 29 | target | 0 | ขนาด 1.3 |  |  | เกม | `moves_sim.lua:372` |
| `atk` ▦ | atk | 29 | facing | 0 | ขนาด 1.3 |  |  | TE | `moves_sim_te.lua:108` |
| `atk` ▦ | atk | 29 | facing | 0 | ขนาด 1.3 |  |  | UM | `moves_sim_um.lua:244` |
| `swoop_pre` | swoop_pre, swoop_loop, swoop_pst, taunt | 26 | target | 11 | ขนาด 1.3 · เคลื่อน 19.5 |  |  | เกม | `moves_sim.lua:373` |
| `swoop_pre` | swoop_pre, swoop_loop, swoop_pst, taunt | 26 | facing | 34 | ขนาด 1.3 · เคลื่อน 19.5 |  |  | TE | `moves_sim_te.lua:108` |
| `swoop_pre` | swoop_pre, swoop_loop, swoop_pst, taunt | 26 | facing | 34 | ขนาด 1.3 · เคลื่อน 19.5 |  |  | UM | `moves_sim_um.lua:245` |

<a id="mandrakeman"></a>

## mandrakeman

แหล่งข้อมูล: TE `moves_sim_te.lua:109`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | ขนาด 1.25 |  |  | TE | `moves_sim_te.lua:109` |

<a id="mean_flytrap"></a>

## mean_flytrap

แหล่งข้อมูล: TE `moves_sim_te.lua:110`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst | 15 | target | 0 |  |  |  | TE | `moves_sim_te.lua:110` |

<a id="mecfish_alive"></a>

## mecfish_alive

แหล่งข้อมูล: TE `moves_sim_te.lua:111`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `walk_loop` | walk_loop | 10 | target | 0 | ขนาด 1 |  |  | TE | `moves_sim_te.lua:111` |

<a id="merm"></a>

## merm — Merm

แหล่งข้อมูล: เกม `moves_sim.lua:375`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | เกม | `moves_sim.lua:376` |

<a id="mermb"></a>

## mermb

แหล่งข้อมูล: TE `moves_sim_te.lua:112`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | TE | `moves_sim_te.lua:112` |

<a id="mermb2"></a>

## mermb2

แหล่งข้อมูล: TE `moves_sim_te.lua:113`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | ขนาด 2 |  |  | TE | `moves_sim_te.lua:113` |

<a id="mermking"></a>

## mermking — King of the Merms

แหล่งข้อมูล: เกม `moves_sim.lua:378`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|

<a id="minotaur"></a>

## minotaur — Ancient Guardian

แหล่งข้อมูล: เกม `moves_sim.lua:379` · UM `moves_sim_um.lua:247`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, paw_loop, atk, gore | 45 | target | 45 |  |  |  | เกม | `moves_sim.lua:380` |
| `bite` ▦ | bite | 16 | target | 0 |  |  |  | เกม | `moves_sim.lua:381` |
| `gore` | gore | 1 | target |  |  |  |  | เกม | `moves_sim.lua:382` |
| `gore~run_stop` | gore | 5 | target | 0 |  |  |  | เกม | `moves_sim.lua:383` |
| `jump_atk_pre` | jump_atk_pre, jump_atk_loop, jump_atk_pst, taunt | 59 | target | 31 | ตามเป้า · เคลื่อน 3.0 |  | leapattack_cooldown | เกม | `moves_sim.lua:384` |
| `jump_atk_pre` | jump_atk_pre, jump_atk_loop, jump_atk_pst, taunt | 59 | target | 31 | ตามเป้า · เคลื่อน 3.0 |  | forceleapattack | UM | `moves_sim_um.lua:248` |
| `jump_atk_pre_quick` | jump_atk_pre_quick, jump_atk_loop, jump_atk_pst, taunt | 44 | target | 16 | ตามเป้า · เคลื่อน 3.0 |  | forceleapattack | UM | `moves_sim_um.lua:249` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `groundpoundring_fx` |  | วาดกับท่าบอส · ดีเลย์ 0 · ตีถึง 6 | เกม | `moves_sim.lua:79` |  |
| `guardian_goo` |  | เคลื่อนที่ · ตีตอนตก · ดีเลย์ 0 | UM | `moves_sim_um.lua:52` |  |

<a id="mock_dragonfly"></a>

## mock_dragonfly — Dragonfly

แหล่งข้อมูล: UM `moves_sim_um.lua:251`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | facing | 0 | ขนาด 1.3 |  |  | UM | `moves_sim_um.lua:252` |
| `fire_on` | fire_on, dash_pre, charge, charge_pst | 63 | facing | 151 | พุ่งเป็นขา · ขนาด 1.3 · เคลื่อน 19.4 |  | RockThrow | UM | `moves_sim_um.lua:253` |
| `taunt` | taunt, taunt_pst | 2 | facing | 0 | ขนาด 1.3 |  |  | UM | `moves_sim_um.lua:254` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `fireball_throwable` |  | เคลื่อนที่ · ดีเลย์ 0 | UM | `moves_sim_um.lua:49` |  |
| `firesplash_fx` |  | อยู่นาน · วาดกับท่าบอส · ดีเลย์ 0 · ตีถึง 123 | UM | `moves_sim_um.lua:50` |  |
| `magmafire` |  | อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:53` |  |

<a id="molebat"></a>

## molebat — Naked Mole Bat

แหล่งข้อมูล: เกม `moves_sim.lua:386`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 10 | target | 0 |  |  |  | เกม | `moves_sim.lua:387` |

<a id="monkey"></a>

## monkey — Splumonkey

แหล่งข้อมูล: เกม `moves_sim.lua:389`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 17 | target | 0 |  |  |  | เกม | `moves_sim.lua:390` |

<a id="moonmaw_dragonfly"></a>

## moonmaw_dragonfly — Moonmaw Dragonfly

แหล่งข้อมูล: UM `moves_sim_um.lua:256`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | facing | 0 | ขนาด 1.3 | moonmaw_glass |  | UM | `moves_sim_um.lua:257` |
| `bigattack` | bigattack | 26 | facing | 0 | ขนาด 1.3 |  |  | UM | `moves_sim_um.lua:258` |
| `skyfall` | skyfall, crashed_loop | 6 | facing | 0 | ขนาด 1.3 |  |  | UM | `moves_sim_um.lua:259` |
| `spin_pre` | spin_pre, spin | 14 | facing | 0 | ขนาด 1.3 |  |  | UM | `moves_sim_um.lua:260` |
| `taunt_pre` | taunt_pre, taunt, taunt_pst | 25 | facing | 0 | ขนาด 1.3 |  |  | UM | `moves_sim_um.lua:261` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `moonmaw_glass` | Unstable Moon Glass | อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:55` |  |
| `moonmaw_glassshards` |  | เคลื่อนที่ · ดีเลย์ 0 | UM | `moves_sim_um.lua:56` |  |
| `moonmaw_trapprojectile` |  | ดีเลย์ 32 | UM | `moves_sim_um.lua:57` | simmoves.lua:3158 |

<a id="moonmaw_lavae"></a>

## moonmaw_lavae — Glass Lavae

แหล่งข้อมูล: UM `moves_sim_um.lua:263`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `drop` | drop, deathground | 11 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:264` |
| `stab_pre` | stab_pre, stab_loop | 11 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:265` |

<a id="moonpig"></a>

## moonpig

แหล่งข้อมูล: เกม `moves_sim.lua:392` · UM `moves_sim_um.lua:267`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `were_atk_pre` | were_atk_pre, were_atk | 16 | target | 0 |  |  |  | เกม | `moves_sim.lua:393` |
| `were_atk_pre` | were_atk_pre, were_atk | 16 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:268` |

<a id="moose"></a>

## moose

แหล่งข้อมูล: เกม `moves_sim.lua:395` · UM `moves_sim_um.lua:270`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 20 | target | 0 | ขนาด 1.55 |  | DisarmCooldown | เกม | `moves_sim.lua:396` |
| `atk` ▦ | atk | 20 | facing | 0 | ขนาด 1.55 |  | DisarmCooldown | UM | `moves_sim_um.lua:271` |
| `hopatk` | hopatk, hopatk_loop, land | 50 | facing | 33 | กรวย · ขนาด 1.55 · เคลื่อน 3.8 |  | SuperHop | UM | `moves_sim_um.lua:272` |
| `takeoff_pre_diagonal` | takeoff_pre_diagonal, tornadoattack | 30 | target | 0 | ขนาด 1.55 | mothergoose_tornado |  | UM | `moves_sim_um.lua:273` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `mothergoose_tornado` |  | อยู่นาน · ดีเลย์ 30 | UM | `moves_sim_um.lua:58` |  |

<a id="mosquito"></a>

## mosquito — Mosquito

แหล่งข้อมูล: เกม `moves_sim.lua:398`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 |  |  |  | เกม | `moves_sim.lua:399` |
| `explode` | explode | 11 | facing | 0 |  |  |  | เกม | `moves_sim.lua:400` |

<a id="mosquito_poison"></a>

## mosquito_poison

แหล่งข้อมูล: TE `moves_sim_te.lua:114`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 15 | target | 0 |  |  |  | TE | `moves_sim_te.lua:114` |
| `explode` | explode | 11 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:114` |

<a id="mossling"></a>

## mossling — Mosling

แหล่งข้อมูล: เกม `moves_sim.lua:402`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 0 |  |  |  | เกม | `moves_sim.lua:403` |
| `spin_pre` | spin_pre, spin_loop, spin_pst | 16 | target | 0 |  |  |  | เกม | `moves_sim.lua:404` |

<a id="mothergoose"></a>

## mothergoose

แหล่งข้อมูล: UM `moves_sim_um.lua:275`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | facing | 0 | ขนาด 1.55 |  | DisarmCooldown | UM | `moves_sim_um.lua:276` |
| `hopatk` | hopatk, hopatk_loop, land | 50 | facing | 33 | กรวย · ขนาด 1.55 · เคลื่อน 3.8 |  | SuperHop | UM | `moves_sim_um.lua:277` |
| `takeoff_pre_diagonal` | takeoff_pre_diagonal, tornadoattack | 30 | target | 0 | ขนาด 1.55 | mothergoose_tornado |  | UM | `moves_sim_um.lua:278` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `mothergoose_tornado` |  | อยู่นาน · ดีเลย์ 30 | UM | `moves_sim_um.lua:58` |  |

<a id="mothermossling"></a>

## mothermossling

แหล่งข้อมูล: UM `moves_sim_um.lua:280`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 0 |  |  |  | UM | `moves_sim_um.lua:281` |
| `spin_pre` | spin_pre, spin_loop, spin_pst | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:282` |

<a id="mushdrake_red"></a>

## mushdrake_red

แหล่งข้อมูล: UM `moves_sim_um.lua:284`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 0 |  |  |  | UM | `moves_sim_um.lua:285` |
| `atk_pre` | atk_pre, atk_loop, atk_pst | 20 | target | 0 |  |  |  | UM | `moves_sim_um.lua:286` |

<a id="mushgnome"></a>

## mushgnome — Mush Gnome

แหล่งข้อมูล: เกม `moves_sim.lua:406`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|

<a id="mutated_penguin"></a>

## mutated_penguin — Permafrost Pengull

แหล่งข้อมูล: เกม `moves_sim.lua:407` · มือ `moves_hand.lua:42`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 15 | target | 0 |  |  |  | เกม | `moves_sim.lua:408` |
| `slide` | slide_bounce, slide_loop |  | facing |  | พุ่งเป็นขา |  |  | มือ | `moves_hand.lua` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:894

<a id="mutatedbearger"></a>

## mutatedbearger — Armored Bearger

แหล่งข้อมูล: เกม `moves_sim.lua:410`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk1` | atk1, atk1_pst, atk2 | 32 | facing | 10 | เคลื่อน 0.4 |  |  | เกม | `moves_sim.lua:411` |
| `atk1a` | atk1a, atk1_pst, atk2 | 28 | facing | 10 | เคลื่อน 0.4 |  |  | เกม | `moves_sim.lua:412` |
| `atk2` | atk2, atk2_pst, atk1a | 28 | facing | 10 | เคลื่อน 0.4 |  |  | เกม | `moves_sim.lua:413` |
| `butt` ▦ | butt, butt_pst | 8 | facing | 0 | เคลื่อน 2.9 |  |  | เกม | `moves_sim.lua:414` |
| `ground_pound` | ground_pound | 20 | facing | 0 |  |  | GroundPound | เกม | `moves_sim.lua:415` |
| `ground_pound~pound` | ground_pound, stagger_pre, stagger_pst | 20 | facing | 0 |  |  | GroundPound | เกม | `moves_sim.lua:416` |
| `sleep_pst` | sleep_pst, yawn, standing_yawn_pst | 103 | facing | 0 |  |  | Yawn | เกม | `moves_sim.lua:417` |

<a id="mutatedbird"></a>

## mutatedbird — Bright-Beaked Bird

แหล่งข้อมูล: เกม `moves_sim.lua:419`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` ▦ | attack | 8 | target | 0 |  |  |  | เกม | `moves_sim.lua:420` |

<a id="mutatedbuzzard_gestalt"></a>

## mutatedbuzzard_gestalt — Crystal-Crested Buzzard

แหล่งข้อมูล: เกม `moves_sim.lua:422`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | เกม | `moves_sim.lua:423` |
| `atk_flame_pre` | atk_flame_pre, atk_flame_loop, atk_flame_pst | 39 | target | 36 | ตีด้วยของเท่านั้น · เคลื่อน 3.2 | warg_mutated_breath_fx | flamethrower_cd | เกม | `moves_sim.lua:424` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `warg_mutated_breath_fx` |  | อยู่นาน · ดีเลย์ 0 · ตีถึง 90 | เกม | `moves_sim.lua:104` | simmoves.lua:3151 simmoves.lua:3171 |

<a id="mutateddeerclops"></a>

## mutateddeerclops — Crystal Deerclops

แหล่งข้อมูล: เกม `moves_sim.lua:426`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 34 | facing | 16 | ขนาด 1.65 | deerclops_icespike_fx |  | เกม | `moves_sim.lua:427` |
| `atk2` | atk2 | 19 | facing | 18 | ขนาด 1.65 | deerclops_laser, deerclops_laserempty | laserbeam_cd | เกม | `moves_sim.lua:428` |
| `throw` | throw | 60 | facing | 30 | ขนาด 1.65 | deerclops_icelance_ping_fx, deerclops_impact_circle_fx |  | เกม | `moves_sim.lua:429` |
| `throw_2` | throw_2 | 60 | facing | 30 | ขนาด 1.65 | deerclops_icelance_ping_fx, deerclops_impact_circle_fx |  | เกม | `moves_sim.lua:430` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `deerclops_icelance_ping_fx` |  | วาดกับท่าบอส · ดีเลย์ 30 · ตีถึง 30 | UM | `moves_sim_um.lua:39` |  |
| `deerclops_icespike_fx` |  | ดีเลย์ 0 · ตีถึง 3 | UM | `moves_sim_um.lua:40` |  |
| `deerclops_impact_circle_fx` |  | อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:41` |  |
| `deerclops_laser` |  | วาดกับท่าบอส · ดีเลย์ 0 · ตีถึง 9 | เกม | `moves_sim.lua:69` |  |
| `deerclops_laserempty` |  | วาดกับท่าบอส · ดีเลย์ 0 · ตีถึง 0 | เกม | `moves_sim.lua:70` |  |

<a id="mutatedwarg"></a>

## mutatedwarg — Possessed Varg

แหล่งข้อมูล: เกม `moves_sim.lua:432`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 11 | target | 0 |  |  |  | เกม | `moves_sim.lua:433` |
| `atk_breath_pre` | atk_breath_pre, atk_breath_loop, atk_breath_pst | 19 | facing | 16 |  |  |  | เกม | `moves_sim.lua:434` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `warg_mutated_breath_fx` |  | อยู่นาน · ดีเลย์ 0 · ตีถึง 90 | เกม | `moves_sim.lua:104` | simmoves.lua:3151 simmoves.lua:3171 |

