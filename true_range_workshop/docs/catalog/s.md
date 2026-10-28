# สารบัญมอน — S

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="scorpion"></a>

## scorpion

แหล่งข้อมูล: TE `moves_sim_te.lua:153`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:153` |
| `atk~leap_attack` | atk, taunt | 19 | target | 0 | ตามเป้า |  |  | TE | `moves_sim_te.lua:153` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua` |
| `tail` | tail | 20 | target | 0 |  |  |  | TE | `moves_sim_te.lua` |

<a id="sea_eel"></a>

## sea_eel

แหล่งข้อมูล: TE `moves_sim_te.lua:154`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 30 | target | 0 | ขนาด 0.3 |  |  | TE | `moves_sim_te.lua:154` |

<a id="seaquaketentacle"></a>

## seaquaketentacle

แหล่งข้อมูล: TE `moves_sim_te.lua:155`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk_loop, atk_idle | 32 | target | 0 |  |  |  | TE | `moves_sim_te.lua:155` |

<a id="seatentacle"></a>

## seatentacle

แหล่งข้อมูล: TE `moves_sim_te.lua:156`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk_loop, atk_idle | 32 | target | 0 |  |  |  | TE | `moves_sim_te.lua:156` |

<a id="shadow_bishop"></a>

## shadow_bishop — Shadow Bishop

แหล่งข้อมูล: เกม `moves_sim.lua:490` · UM `moves_sim_um.lua:345`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_side_pre` | atk_side_pre, atk_side_loop_pre, atk_side_loop, atk_side_pst | 35 | target |  | ตามเป้า · รอบตัว · เคลื่อน 1.0 |  |  | เกม | `moves_sim.lua:491` |
| `atk_side_pre` | atk_side_pre, atk_side_loop_pre, atk_side_loop, atk_side_loop_pst, … | 35 | facing |  | ตามเป้า · พุ่งเป็นขา · รอบตัว · เคลื่อน 6.2 |  |  | UM | `moves_sim_um.lua:346` |
| `atk_side_pre@LevelUp` | atk_side_pre, atk_side_loop_pre, atk_side_loop, atk_side_pst | 35 | target |  | ตามเป้า · รอบตัว · ขนาด 1.6 · เคลื่อน 1.0 |  |  | เกม | `moves_sim.lua:492` |
| `atk_side_pre@LevelUp` | atk_side_pre, atk_side_loop_pre, atk_side_loop, atk_side_loop_pst, … | 35 | facing |  | ตามเป้า · พุ่งเป็นขา · รอบตัว · ขนาด 1.6 · เคลื่อน 8.8 |  |  | UM | `moves_sim_um.lua:347` |
| `atk_side_pre@LevelUp,LevelUp` | atk_side_pre, atk_side_loop_pre, atk_side_loop, atk_side_pst | 35 | target |  | ตามเป้า · รอบตัว · ขนาด 2.2 · เคลื่อน 1.0 |  |  | เกม | `moves_sim.lua:493` |
| `atk_side_pre@LevelUp,LevelUp` | atk_side_pre, atk_side_loop_pre, atk_side_loop, atk_side_loop_pst, … | 35 | facing |  | ตามเป้า · พุ่งเป็นขา · รอบตัว · ขนาด 2.2 · เคลื่อน 9.8 |  |  | UM | `moves_sim_um.lua:348` |

<a id="shadow_knight"></a>

## shadow_knight — Shadow Knight

แหล่งข้อมูล: เกม `moves_sim.lua:495`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 3 | target |  |  |  |  | เกม | `moves_sim.lua:496` |
| `atk@LevelUp` | atk | 3 | target |  | ขนาด 1.7 |  |  | เกม | `moves_sim.lua:497` |
| `atk@LevelUp,LevelUp` | atk | 3 | target |  | ขนาด 2.5 |  |  | เกม | `moves_sim.lua:498` |
| `atk_plus` | atk_plus | 5 | target | 0 |  |  |  | เกม | `moves_sim.lua:499` |
| `atk_plus@LevelUp` ▦ | atk_plus | 5 | target | 0 | ขนาด 1.7 |  |  | เกม | `moves_sim.lua:500` |
| `atk_plus@LevelUp,LevelUp` | atk_plus | 5 | target | 0 | ขนาด 2.5 |  |  | เกม | `moves_sim.lua:501` |
| `atk_pre` | atk_pre, atk | 17 | target | 0 |  |  |  | เกม | `moves_sim.lua:502` |
| `atk_pre@LevelUp` | atk_pre, atk | 17 | target | 0 | ขนาด 1.7 |  |  | เกม | `moves_sim.lua:503` |
| `atk_pre@LevelUp,LevelUp` | atk_pre, atk | 17 | target | 0 | ขนาด 2.5 |  |  | เกม | `moves_sim.lua:504` |

<a id="shadow_leech"></a>

## shadow_leech — Parasitic Shadeling

แหล่งข้อมูล: เกม `moves_sim.lua:506`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|

<a id="shadow_rook"></a>

## shadow_rook — Shadow Rook

แหล่งข้อมูล: เกม `moves_sim.lua:507`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `teleport_pre` | teleport_pre, teleport, teleport_atk, teleport_pst | 48 | facing | 32 | กรวย · เคลื่อน 1.0 |  |  | เกม | `moves_sim.lua:508` |
| `teleport_pre@LevelUp` | teleport_pre, teleport, teleport_atk, teleport_pst | 48 | facing | 32 | กรวย · ขนาด 1.2 · เคลื่อน 1.0 |  |  | เกม | `moves_sim.lua:509` |
| `teleport_pre@LevelUp,LevelUp` | teleport_pre, teleport, teleport_atk, teleport_pst | 48 | facing | 32 | กรวย · ขนาด 1.6 · เคลื่อน 1.0 |  |  | เกม | `moves_sim.lua:510` |

<a id="shadowtentacle"></a>

## shadowtentacle — Shadow Tentacle

แหล่งข้อมูล: เกม `moves_sim.lua:512`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk_loop, atk_idle, atk_pst | 37 | target | 0 | ขนาด 0.5 |  |  | เกม | `moves_sim.lua:513` |

<a id="shadowthrall_hands"></a>

## shadowthrall_hands — Ink Blight

แหล่งข้อมูล: เกม `moves_sim.lua:515` · มือ `moves_hand.lua:65`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `portal_appear` | portal_appear, run_loop, shrouden_disappear | 11 | facing | 0 |  |  |  | มือ | `moves_hand.lua:65` |
| `run_pre` | run_pre, run_loop, run_pst | 15 | facing | 0 |  |  |  | เกม | `moves_sim.lua:516` |

<a id="shadowthrall_horns"></a>

## shadowthrall_horns — Ink Blight

แหล่งข้อมูล: เกม `moves_sim.lua:518` · มือ `moves_hand.lua:54`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `appear` | appear | 47 | facing | 0 |  |  |  | เกม | `moves_sim.lua:519` |
| `jump` ▦ | jump, jump_pst | 29 | facing | 6 | ตามเป้า · เคลื่อน 1.1 |  |  | เกม | `moves_sim.lua:520` |
| `shrouden_jump` | shrouden_jump, shrouden_jump_pst | 11 | target | 1 | เคลื่อน 4.2 |  |  | มือ | `moves_hand.lua:54` |
| `slap` | slap | 14 | facing | 0 |  |  |  | เกม | `moves_sim.lua:521` |

**โค้ดพิเศษที่อ้างถึง:** simmoves.lua:28

<a id="shadowthrall_mouth"></a>

## shadowthrall_mouth — Ink Blight

แหล่งข้อมูล: เกม `moves_sim.lua:523` · มือ `moves_hand.lua:60`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `bite_final` | bite_final | 6 | facing | 0 |  |  |  | มือ | `moves_hand.lua:60` |
| `bite_pre` | bite_pre, bite_loop, bite_final | 19 | facing |  | รอบตัว |  |  | เกม | `moves_sim.lua:524` |
| `land` | land | 0 | facing |  | รอบตัว |  |  | เกม | `moves_sim.lua:525` |
| `leap_pre` | leap_pre, land | 38 | target | 25 | ตามเป้า · เคลื่อน 1.0 |  | leap_cd | เกม | `moves_sim.lua:526` |
| `portal_appear` | portal_appear | 8 | facing | 0 |  |  |  | มือ | `moves_hand.lua:60` |
| `shrouden_disappear` | shrouden_disappear | 6 | facing | 0 |  |  |  | มือ | `moves_hand.lua:60` |
| `stalk_bite` | stalk_bite | 22 | facing | 0 |  |  |  | เกม | `moves_sim.lua:527` |

<a id="shadowthrall_wings"></a>

## shadowthrall_wings — Ink Blight

แหล่งข้อมูล: เกม `moves_sim.lua:529`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `shadowthrall_projectile_fx` |  | เคลื่อนที่ · ดีเลย์ 21 · ตีถึง 31 | เกม | `moves_sim.lua:92` |  |

<a id="shark"></a>

## shark — Rockjaw

แหล่งข้อมูล: เกม `moves_sim.lua:530` · UM `moves_sim_um.lua:350`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 12 | target | 0 |  |  | getdistance | เกม | `moves_sim.lua:531` |
| `attack` | attack | 12 | facing | 0 |  |  | getdistance | UM | `moves_sim_um.lua:351` |
| `attack~bite` | attack, idle | 12 | target | 0 |  |  |  | เกม | `moves_sim.lua:532` |
| `attack~bite` | attack, idle | 12 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:352` |

<a id="sharkboi"></a>

## sharkboi — Frostjaw

แหล่งข้อมูล: เกม `moves_sim.lua:534`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk1` | atk1 | 16 | target | 0 |  | sharkboi_swipe_fx |  | เกม | `moves_sim.lua:535` |
| `atk2` ▦ | atk2, atk2_delay | 4 | facing | 0 |  | sharkboi_swipe_fx |  | เกม | `moves_sim.lua:536` |
| `atk3` ▦ | atk3 | 12 | facing | 0 |  |  |  | เกม | `moves_sim.lua:537` |
| `icedive_jump_pre` | icedive_jump_pre, icedive_jump, icedive_dig_pre, icedive_dig_loop | 3 | facing | 6 | กรวย · เคลื่อน 2.0 |  | standing_dive_cd | เกม | `moves_sim.lua:538` |
| `icedive_standing_jump_pre` | icedive_standing_jump_pre, icedive_jump, icedive_dig_pre, icedive_dig_loop | 33 | facing | 14 | ตามเป้า · กรวย · เคลื่อน 1.8 |  | standing_dive_cd | เกม | `moves_sim.lua:539` |
| `torpedo_pre` | torpedo_pre, torpedo_jump, torpedo_loop, torpedo_climb | 34 | facing | 34 | เคลื่อน 20.4 |  | torpedo_cd | เกม | `moves_sim.lua:540` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `sharkboi_swipe_fx` |  | วาดกับท่าบอส · ดีเลย์ 4 · ตีถึง 4 | เกม | `moves_sim.lua:93` |  |

<a id="sharkitten"></a>

## sharkitten

แหล่งข้อมูล: TE `moves_sim_te.lua:157`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:157` |

<a id="sharx"></a>

## sharx

แหล่งข้อมูล: TE `moves_sim_te.lua:158`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:158` |

<a id="sharxunderwater"></a>

## sharxunderwater

แหล่งข้อมูล: TE `moves_sim_te.lua:159`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:159` |

<a id="shockworm"></a>

## shockworm — Depths Eel

แหล่งข้อมูล: UM `moves_sim_um.lua:354`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | UM | `moves_sim_um.lua:355` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `um_shock_projectile` |  | ดีเลย์ 3 | UM | `moves_sim_um.lua:74` |  |

<a id="shrouden"></a>

## shrouden — Umbral Abomination

แหล่งข้อมูล: เกม `moves_sim.lua:542`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `optic_blast_pre1` | optic_blast_pre1, optic_blast_pre2, optic_blast_loop, optic_blast_pst, … | 45 | facing | 116 | ตามเป้า · กรวย · เคลื่อน 1.0 |  | opticblastcd | เกม | `moves_sim.lua:543` |
| `punch_pre` | punch_pre, punch_loop, punch_pst | 19 | target | 1 |  |  | portalcd | เกม | `moves_sim.lua:544` |
| `teleport_pre` | teleport_pre, teleport_loop, teleport_pst | 57 | target | 60 | เคลื่อน 1.0 |  | teleportcd | เกม | `moves_sim.lua:545` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `charliearena_spike` | Dreadstone Outcrop | ดีเลย์ 29 | เกม | `moves_sim.lua:61` | simmoves.lua:3166 |
| `shrouden_optic_blast_fx` |  | อยู่นาน · วาดกับท่าบอส · ดีเลย์ 26 · ตีถึง 90 | เกม | `moves_sim.lua:94` | simmoves.lua:3238 simmoves.lua:3239 simmoves.lua:3241 |

**โค้ดพิเศษที่อ้างถึง:** simmoves.lua:3231

<a id="sinheniddnadtdfo"></a>

## sinheniddnadtdfo

แหล่งข้อมูล: UM `moves_sim_um.lua:357`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 3 | target |  | ขนาด 2 |  |  | UM | `moves_sim_um.lua:358` |

<a id="slip"></a>

## slip

แหล่งข้อมูล: TE `moves_sim_te.lua:160`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `eat_pre` | eat_pre, taunt | 19 | target | 0 |  |  |  | TE | `moves_sim_te.lua:160` |
| `eat_pre~attack` | eat_pre | 18 | target | 0 |  |  |  | TE | `moves_sim_te.lua:160` |
| `eat_pre~spitter_attack` | eat_pre, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua` |

<a id="slipstor"></a>

## slipstor

แหล่งข้อมูล: TE `moves_sim_te.lua:161`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `anim` | anim, idle_loop | 11 | target | 0 |  |  |  | TE | `moves_sim_te.lua:161` |

<a id="slurper"></a>

## slurper — Slurper

แหล่งข้อมูล: เกม `moves_sim.lua:547`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 30 | facing | 0 | เคลื่อน 6.7 |  |  | เกม | `moves_sim.lua:548` |
| `headslurp` | headslurp | 23 | facing | 0 | เคลื่อน 2.0 |  |  | เกม | `moves_sim.lua:549` |

<a id="slurtle"></a>

## slurtle — Slurtle

แหล่งข้อมูล: เกม `moves_sim.lua:551`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 |  |  |  | เกม | `moves_sim.lua:552` |

<a id="smallbird"></a>

## smallbird — Smallbird

แหล่งข้อมูล: เกม `moves_sim.lua:554` · มือ `moves_hand.lua:43`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | เกม | `moves_sim.lua:555` |
| `chase` | walk_loop, idle_loop, walk_pre |  | facing |  | พุ่งเป็นขา |  |  | มือ | `moves_hand.lua` |

<a id="snaildrake_magma"></a>

## snaildrake_magma — Snaildrake

แหล่งข้อมูล: UM `moves_sim_um.lua:360`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 | ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:361` |

<a id="snaildrake_slime"></a>

## snaildrake_slime — Snaildrake

แหล่งข้อมูล: UM `moves_sim_um.lua:363`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 | ขนาด 1.2 |  |  | UM | `moves_sim_um.lua:364` |

<a id="snake"></a>

## snake

แหล่งข้อมูล: TE `moves_sim_te.lua:162`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst | 27 | target | 0 |  |  |  | TE | `moves_sim_te.lua:162` |

<a id="snake_amphibious"></a>

## snake_amphibious

แหล่งข้อมูล: TE `moves_sim_te.lua:163`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst | 27 | target | 0 |  |  |  | TE | `moves_sim_te.lua:163` |

<a id="snake_poison"></a>

## snake_poison

แหล่งข้อมูล: TE `moves_sim_te.lua:164`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst | 27 | target | 0 |  |  |  | TE | `moves_sim_te.lua:164` |

<a id="snapdragon"></a>

## snapdragon

แหล่งข้อมูล: TE `moves_sim_te.lua:165`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 15 | target | 0 | ขนาด 1.22 |  |  | TE | `moves_sim_te.lua:165` |

<a id="snapperturtle"></a>

## snapperturtle — Snapper Turtle

แหล่งข้อมูล: UM `moves_sim_um.lua:366`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 8 | target | 0 | ขนาด 1 |  |  | UM | `moves_sim_um.lua:367` |
| `spin_pre` | spin_pre, spin_loop, spin_pst | 16 | facing |  | รอบตัว · ขนาด 1 · เคลื่อน 2.0 |  |  | UM | `moves_sim_um.lua:368` |
| `spin_pst` | spin_pst | 16 | target | 0 | ขนาด 1 |  |  | UM | `moves_sim_um.lua:369` |

<a id="snapperturtlebaby"></a>

## snapperturtlebaby — Whippersnapper Turtle

แหล่งข้อมูล: UM `moves_sim_um.lua:371`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 8 | target | 0 | ขนาด 0.6 |  |  | UM | `moves_sim_um.lua:372` |
| `spin_pre` | spin_pre, spin_loop, spin_pst | 16 | facing |  | รอบตัว · ขนาด 0.6 · เคลื่อน 2.3 |  |  | UM | `moves_sim_um.lua:373` |
| `spin_pst` | spin_pst | 16 | target | 0 | ขนาด 0.6 |  |  | UM | `moves_sim_um.lua:374` |

<a id="snowgoat"></a>

## snowgoat

แหล่งข้อมูล: TE `moves_sim_te.lua:166`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:166` |

<a id="snowmong"></a>

## snowmong — Abominamole

แหล่งข้อมูล: UM `moves_sim_um.lua:376`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `action` | action | 8 | target | 0 | ขนาด 2 |  |  | UM | `moves_sim_um.lua:377` |
| `exit` | exit | 22 | facing | 0 | ขนาด 2 |  |  | UM | `moves_sim_um.lua:378` |

<a id="snowperd"></a>

## snowperd

แหล่งข้อมูล: TE `moves_sim_te.lua:167`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 0 |  |  |  | TE | `moves_sim_te.lua:167` |

<a id="snowwarg"></a>

## snowwarg

แหล่งข้อมูล: TE `moves_sim_te.lua:168`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 11 | target | 0 |  |  |  | TE | `moves_sim_te.lua:168` |

<a id="snurtle"></a>

## snurtle — Snurtle

แหล่งข้อมูล: เกม `moves_sim.lua:557`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 10 | target | 0 |  |  |  | เกม | `moves_sim.lua:558` |

<a id="spat"></a>

## spat — Ewecus

แหล่งข้อมูล: เกม `moves_sim.lua:560`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `strike` | strike, strike_pst | 5 | target | 0 |  |  |  | เกม | `moves_sim.lua:561` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `spat_bomb` |  | เคลื่อนที่ · ดีเลย์ 0 · ตีถึง 15 | เกม | `moves_sim.lua:96` |  |

<a id="spider"></a>

## spider — Spider

แหล่งข้อมูล: เกม `moves_sim.lua:563` · UM `moves_sim_um.lua:380`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 25 | target | 0 |  |  |  | เกม | `moves_sim.lua:564` |
| `hide` | hide, hit_shield | 15 | target | 0 | ตีด้วยของเท่านั้น | minimoonspider_spike |  | UM | `moves_sim_um.lua:381` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:382` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | เลน |  |  | UM | `moves_sim_um.lua:383` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `minimoonspider_spike` |  | อยู่นาน · ดีเลย์ 1 · ตีถึง 82 | UM | `moves_sim_um.lua:54` |  |

<a id="spider_ape"></a>

## spider_ape

แหล่งข้อมูล: TE `moves_sim_te.lua:169`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 17 | target | 0 |  |  |  | TE | `moves_sim_te.lua:169` |

<a id="spider_monkey"></a>

## spider_monkey

แหล่งข้อมูล: TE `moves_sim_te.lua:170`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 11 | target | 0 |  |  |  | TE | `moves_sim_te.lua:170` |
| `throw` | throw | 14 | target | 0 |  |  |  | TE | `moves_sim_te.lua:170` |

<a id="spider_moon"></a>

## spider_moon — Shattered Spider

แหล่งข้อมูล: เกม `moves_sim.lua:566` · UM `moves_sim_um.lua:385`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | ขนาด 1.25 |  |  | เกม | `moves_sim.lua:567` |
| `hide` | hide, hit_shield, unhide | 15 | target | 0 | ขนาด 1.25 · ตีด้วยของเท่านั้น | moonspider_spike |  | เกม | `moves_sim.lua:568` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | ตามเป้า · ขนาด 1.25 |  |  | UM | `moves_sim_um.lua:386` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `moonspider_spike` | Shattered Spider | อยู่นาน · ดีเลย์ 1 · ตีถึง 81 | เกม | `moves_sim.lua:83` |  |

<a id="spider_snow"></a>

## spider_snow

แหล่งข้อมูล: TE `moves_sim_te.lua:171`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | ขนาด 1.25 |  |  | TE | `moves_sim_te.lua:171` |
| `hide` | hide, hit_shield, unhide | 15 | target | 0 | ขนาด 1.25 · ตีด้วยของเท่านั้น | snowspider_spike |  | TE | `moves_sim_te.lua:171` |
| `spit` | spit, taunt | 21 | target | 0 | ขนาด 1.25 |  |  | TE | `moves_sim_te.lua:171` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | เลน · ขนาด 1.25 |  |  | TE | `moves_sim_te.lua:171` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `snowspider_spike` |  | อยู่นาน · ดีเลย์ 1 · ตีถึง 82 | TE | `moves_sim_te.lua:28` |  |

<a id="spider_snow2"></a>

## spider_snow2

แหล่งข้อมูล: TE `moves_sim_te.lua:172`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | ขนาด 1.25 |  |  | TE | `moves_sim_te.lua:172` |
| `hide` | hide, hit_shield, unhide | 15 | target | 0 | ขนาด 1.25 · ตีด้วยของเท่านั้น | snowspider_spike2 |  | TE | `moves_sim_te.lua:172` |
| `spit` | spit, taunt | 21 | target | 0 | ขนาด 1.25 |  |  | TE | `moves_sim_te.lua:172` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | เลน · ขนาด 1.25 |  |  | TE | `moves_sim_te.lua:172` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `snowspider_spike2` |  | อยู่นาน · ดีเลย์ 1 · ตีถึง 82 | TE | `moves_sim_te.lua:29` |  |

<a id="spider_spitter"></a>

## spider_spitter — Spitter

แหล่งข้อมูล: เกม `moves_sim.lua:570` · UM `moves_sim_um.lua:388`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | เกม | `moves_sim.lua:571` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:389` |

<a id="spider_trapdoor"></a>

## spider_trapdoor — Trapdoor Spider

แหล่งข้อมูล: UM `moves_sim_um.lua:391`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | ขนาด 1.1 |  |  | UM | `moves_sim_um.lua:392` |
| `spit` | spit, taunt | 21 | target | 0 | ขนาด 1.1 |  |  | UM | `moves_sim_um.lua:393` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | ตามเป้า · ขนาด 1.1 |  |  | UM | `moves_sim_um.lua:394` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | เลน · ขนาด 1.1 |  |  | UM | `moves_sim_um.lua:395` |

<a id="spider_trapdoor_hooded"></a>

## spider_trapdoor_hooded — Hooded Widower

แหล่งข้อมูล: UM `moves_sim_um.lua:397`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 | ขนาด 1.1 |  |  | UM | `moves_sim_um.lua:398` |
| `spit` | spit, taunt | 21 | target | 0 | ขนาด 1.1 |  |  | UM | `moves_sim_um.lua:399` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | ตามเป้า · ขนาด 1.1 |  |  | UM | `moves_sim_um.lua:400` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | เลน · ขนาด 1.1 |  |  | UM | `moves_sim_um.lua:401` |

<a id="spider_tropical"></a>

## spider_tropical

แหล่งข้อมูล: TE `moves_sim_te.lua:173`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:173` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua:173` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | เลน |  |  | TE | `moves_sim_te.lua:173` |

<a id="spider_warrior"></a>

## spider_warrior — Spider Warrior

แหล่งข้อมูล: เกม `moves_sim.lua:573` · UM `moves_sim_um.lua:403`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` ▦ | atk | 25 | target | 0 |  |  |  | เกม | `moves_sim.lua:574` |
| `atk` ▦ | atk | 25 | target | 0 |  |  |  | UM | `moves_sim_um.lua:404` |
| `trapdoor_atk` | trapdoor_atk, taunt | 19 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:405` |
| `warrior_atk` ▦ | warrior_atk, taunt | 19 | facing | 0 | เลน |  |  | เกม | `moves_sim.lua:575` |
| `warrior_atk` ▦ | warrior_atk, taunt | 19 | facing | 0 | เลน |  |  | UM | `moves_sim_um.lua:406` |

<a id="spider_water"></a>

## spider_water — Sea Strider

แหล่งข้อมูล: เกม `moves_sim.lua:577`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 16 | target | 0 |  |  |  | เกม | `moves_sim.lua:578` |

<a id="spiderb"></a>

## spiderb

แหล่งข้อมูล: TE `moves_sim_te.lua:174`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:174` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua:174` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | เลน |  |  | TE | `moves_sim_te.lua:174` |

<a id="spiderb1"></a>

## spiderb1

แหล่งข้อมูล: TE `moves_sim_te.lua:175`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:175` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua:175` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | เลน |  |  | TE | `moves_sim_te.lua:175` |

<a id="spiderb2"></a>

## spiderb2

แหล่งข้อมูล: TE `moves_sim_te.lua:176`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:176` |
| `spit` | spit, taunt | 21 | target | 0 |  |  |  | TE | `moves_sim_te.lua:176` |
| `warrior_atk` | warrior_atk, taunt | 19 | facing | 0 | เลน |  |  | TE | `moves_sim_te.lua:176` |

<a id="spiderqueen"></a>

## spiderqueen — Spider Queen

แหล่งข้อมูล: เกม `moves_sim.lua:580`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 28 | target | 0 |  |  |  | เกม | `moves_sim.lua:581` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `queen_web_bomb` |  | เคลื่อนที่ · ดีเลย์ 0 | UM | `moves_sim_um.lua:59` |  |

<a id="spiky_monkey_tfc"></a>

## spiky_monkey_tfc

แหล่งข้อมูล: TE `moves_sim_te.lua:177`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1 | 21 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:177` |
| `attack2` | attack2 | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:177` |

<a id="spiky_turtle_tfc"></a>

## spiky_turtle_tfc

แหล่งข้อมูล: TE `moves_sim_te.lua:178`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack1` | attack1 | 12 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:178` |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:935

<a id="sporehound"></a>

## sporehound — Spore Hound

แหล่งข้อมูล: UM `moves_sim_um.lua:408`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | UM | `moves_sim_um.lua:409` |
| `jump_atk_loop` | jump_atk_loop, hit, taunt | 15 | target | 0 | ตามเป้า · เคลื่อน 1.0 |  | lightningshot_cooldown | UM | `moves_sim_um.lua:410` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `sporecloud_toad` | Spore Cloud | อยู่นาน · ดีเลย์ 30 | UM | `moves_sim_um.lua:64` |  |

<a id="squid"></a>

## squid — Skittersquid

แหล่งข้อมูล: เกม `moves_sim.lua:583` · TE `moves_sim_te.lua:179`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 10 | target | 0 |  |  |  | เกม | `moves_sim.lua:584` |
| `attack` | attack | 10 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:179` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `inksplat` |  | เคลื่อนที่ · ดีเลย์ 20 | เกม | `moves_sim.lua:80` |  |
| `inksplat` |  | เคลื่อนที่ · ดีเลย์ 20 | TE | `moves_sim_te.lua:20` |  |

<a id="squidunderwater2"></a>

## squidunderwater2

แหล่งข้อมูล: TE `moves_sim_te.lua:180`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 10 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:180` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `inksplat` |  | เคลื่อนที่ · ดีเลย์ 20 | TE | `moves_sim_te.lua:20` |  |

<a id="stageusher"></a>

## stageusher — Prickly Stagehand

แหล่งข้อมูล: เกม `moves_sim.lua:586`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `sleep` | sleep, idle_loop_01 | 166 | facing | 16 |  | stageusher_attackhand |  | เกม | `moves_sim.lua:587` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `stageusher_attackhand` |  | อยู่นาน · ดีเลย์ 0 · ตีถึง 300 | เกม | `moves_sim.lua:99` |  |

<a id="stalker_atrium"></a>

## stalker_atrium — Ancient Fuelweaver

แหล่งข้อมูล: เกม `moves_sim.lua:589` · UM `moves_sim_um.lua:412` · TE `moves_sim_te.lua:181`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 32 | target | 0 |  |  |  | เกม | `moves_sim.lua:590` |
| `attack` | attack | 32 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:181` |
| `attack` | attack | 32 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:413` |
| `attack1` | attack1 | 26 | target | 27 |  | fossilspike | mindcontrol_cd | เกม | `moves_sim.lua:591` |
| `spike` ▦ | spike | 51 | facing | 0 |  | fossilspike2 | mindcontrol_cd | เกม | `moves_sim.lua:592` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `fossilspike` | Fossil Cage | ดีเลย์ 0 | เกม | `moves_sim.lua:71` |  |
| `fossilspike2` | Fossil Spike | ดีเลย์ 46 | เกม | `moves_sim.lua:72` |  |

<a id="stalker_minion"></a>

## stalker_minion — Woven Shadow

แหล่งข้อมูล: เกม `moves_sim.lua:594`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|

<a id="stalker_npc"></a>

## stalker_npc — Ancient Fuelweaver

แหล่งข้อมูล: เกม `moves_sim.lua:595`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 32 | target | 0 |  |  |  | เกม | `moves_sim.lua:596` |
| `attack1` | attack1 | 26 | facing | 0 |  |  |  | เกม | `moves_sim.lua:597` |
| `spike` | spike | 51 | facing | 0 |  |  |  | เกม | `moves_sim.lua:598` |

<a id="strange_scorpion_tfc"></a>

## strange_scorpion_tfc

แหล่งข้อมูล: TE `moves_sim_te.lua:182`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack_pre` | attack_pre, attack | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:182` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `strange_scorpion_massproj_tfc` |  | เคลื่อนที่ · ดีเลย์ 0 · ตีถึง 45 | TE | `moves_sim_te.lua:30` |  |
| `strange_scorpion_proj_tfc` |  | เคลื่อนที่ · ดีเลย์ 0 · ตีถึง 30 | TE | `moves_sim_te.lua:31` |  |

<a id="stumpling"></a>

## stumpling — Pineling

แหล่งข้อมูล: UM `moves_sim_um.lua:415`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack, taunt | 10 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:416` |

<a id="stungray"></a>

## stungray

แหล่งข้อมูล: TE `moves_sim_te.lua:183`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 8 | facing | 0 | ขนาด 1.05 |  |  | TE | `moves_sim_te.lua:183` |

<a id="stungrayunderwater"></a>

## stungrayunderwater

แหล่งข้อมูล: TE `moves_sim_te.lua:184`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 8 | facing | 0 | ขนาด 1.05 |  |  | TE | `moves_sim_te.lua:184` |

<a id="summerwalrus"></a>

## summerwalrus

แหล่งข้อมูล: TE `moves_sim_te.lua:185`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 20 |  |  |  | TE | `moves_sim_te.lua:185` |

<a id="swathgrithr"></a>

## swathgrithr — Wigfrid?

แหล่งข้อมูล: UM `moves_sim_um.lua:418`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, lunge_pst | 32 | target |  | ตามเป้า |  |  | UM | `moves_sim_um.lua:419` |
| `lunge_pre` | lunge_pre, lunge_lag, sing_pre | 12 | target | 16 | ตามเป้า |  |  | UM | `moves_sim_um.lua:420` |

<a id="swilson"></a>

## swilson — Wilson?

แหล่งข้อมูล: UM `moves_sim_um.lua:422`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, run_loop | 32 | target |  | ตามเป้า |  |  | UM | `moves_sim_um.lua:423` |

<a id="swordfish"></a>

## swordfish

แหล่งข้อมูล: TE `moves_sim_te.lua:186`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:186` |

<a id="swordfishunderwater"></a>

## swordfishunderwater

แหล่งข้อมูล: TE `moves_sim_te.lua:187`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 |  |  |  | TE | `moves_sim_te.lua:187` |

