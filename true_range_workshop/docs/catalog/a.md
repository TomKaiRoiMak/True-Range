# สารบัญมอน — A

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="adult_flytrap"></a>

## adult_flytrap

แหล่งข้อมูล: TE `moves_sim_te.lua:34`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst | 15 | target | 0 |  |  |  | TE | `moves_sim_te.lua:34` |

<a id="alpha_lightninggoat"></a>

## alpha_lightninggoat — Alpha Volt Goat

แหล่งข้อมูล: UM `moves_sim_um.lua:84`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 12 | target | 0 | ขนาด 1.1 |  |  | UM | `moves_sim_um.lua:85` |
| `stompy` | stompy, stompy_loop, stompy_pst | 19 | facing | 0 | ขนาด 1.1 |  |  | UM | `moves_sim_um.lua:86` |

<a id="alterguardian_phase1"></a>

## alterguardian_phase1 — Celestial Champion

แหล่งข้อมูล: เกม `moves_sim.lua:109`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `roll_pre` | roll_pre, roll_loop, roll_pst | 51 | facing | 52 | พุ่งเป็นขา · กรวย · เคลื่อน 16.3 |  | roll_cooldown | เกม | `moves_sim.lua:110` |
| `tantrum_loop` | tantrum_loop, tantrum_pst | 8 | facing | 0 |  |  |  | เกม | `moves_sim.lua:111` |
| `tantrum_pre` | tantrum_pre | 26 | facing | 0 |  |  |  | เกม | `moves_sim.lua:112` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `gestalt_alterguardian_projectile` | Gestalt | ดีเลย์ 34 | เกม | `moves_sim.lua:75` |  |

<a id="alterguardian_phase1_lunarrift"></a>

## alterguardian_phase1_lunarrift — Celestial Revenant

แหล่งข้อมูล: เกม `moves_sim.lua:114`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `roll_pre` | roll_pre, roll_loop, roll_pst | 51 | facing | 52 | พุ่งเป็นขา · กรวย · เคลื่อน 16.3 |  | roll_cooldown | เกม | `moves_sim.lua:115` |
| `tantrum_loop` | tantrum_loop, tantrum_pst | 8 | facing | 0 |  |  |  | เกม | `moves_sim.lua:116` |
| `tantrum_pre` | tantrum_pre | 26 | facing | 0 |  |  |  | เกม | `moves_sim.lua:117` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `gestalt_alterguardian_projectile` | Gestalt | ดีเลย์ 34 | เกม | `moves_sim.lua:75` |  |

<a id="alterguardian_phase2"></a>

## alterguardian_phase2 — Celestial Champion

แหล่งข้อมูล: เกม `moves_sim.lua:119`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attk_chop` | attk_chop | 23 | target | 0 |  |  |  | เกม | `moves_sim.lua:120` |
| `attk_chop~atk_summon` | attk_chop | 23 | target | 0 | แยกด้วย alterguardian_summon_fx |  | summon_cd | เกม | `moves_sim.lua:121` |
| `attk_spin_pre` | attk_spin_pre, attk_spin_loop, attk_spin_pst | 35 | target |  | รอบตัว |  |  | เกม | `moves_sim.lua:122` |
| `attk_stab_pre` | attk_stab_pre, attk_stab_loop, attk_stab_pst | 28 | target | 0 |  |  | spike_cd | เกม | `moves_sim.lua:123` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `alterguardian_phase2spiketrail` |  | เคลื่อนที่ · ดีเลย์ 16 · ตีถึง 60 | เกม | `moves_sim.lua:48` |  |
| `smallguard_alterguardian_projectile` | Minor Gestalt | ดีเลย์ 34 | เกม | `moves_sim.lua:95` |  |

<a id="alterguardian_phase3"></a>

## alterguardian_phase3 — Celestial Champion

แหล่งข้อมูล: เกม `moves_sim.lua:125` · UM `moves_sim_um.lua:88`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attk_beam` | attk_beam | 35 | target | 22 | ตามเป้า | alterguardian_laser, alterguardian_laserempty |  | เกม | `moves_sim.lua:126` |
| `attk_skybeam` | attk_skybeam | 90 | facing | 0 |  |  | traps_cd | เกม | `moves_sim.lua:127` |
| `attk_stab` | attk_stab | 29 | target | 0 |  |  |  | เกม | `moves_sim.lua:128` |
| `attk_stab` | attk_stab | 29 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:89` |
| `attk_stab2_loop` | attk_stab2_loop | 1 | target | 0 |  |  |  | เกม | `moves_sim.lua:129` |
| `attk_stab2_loop` | attk_stab2_loop | 1 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:90` |
| `attk_stab2_pre` | attk_stab2_pre | 33 | target | 0 |  |  |  | เกม | `moves_sim.lua:130` |
| `attk_stab2_pre` | attk_stab2_pre | 33 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:91` |
| `attk_stab2_pre@lucky` | attk_stab2_pre | 33 | target | 0 |  |  |  | เกม | `moves_sim.lua:131` |
| `attk_stab2_pre@lucky` | attk_stab2_pre | 33 | facing | 0 |  |  |  | UM | `moves_sim_um.lua:92` |
| `attk_swipe` | attk_swipe | 37 | target | 22 |  | alterguardian_laser |  | เกม | `moves_sim.lua:132` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `alterguardian_laser` |  | อยู่นาน · วาดกับท่าบอส · ดีเลย์ 0 · ตีถึง 25 | เกม | `moves_sim.lua:46` |  |
| `alterguardian_laserempty` |  | อยู่นาน · วาดกับท่าบอส · ดีเลย์ 0 · ตีถึง 23 | เกม | `moves_sim.lua:47` |  |
| `alterguardian_phase3trap` | Enlightening Snare | อยู่นาน · ดีเลย์ 170 | เกม | `moves_sim.lua:49` |  |
| `alterguardian_phase3trapprojectile` |  | ดีเลย์ 31 · ตีถึง 31 | มือ | `moves_hand.lua:92` |  |
| `alterguardian_phase3trapprojectile` |  | ดีเลย์ 31 · ตีถึง 31 | เกม | `moves_sim.lua:50` |  |
| `gestalt_alterguardian_projectile` | Gestalt | ดีเลย์ 34 | เกม | `moves_sim.lua:75` |  |
| `largeguard_alterguardian_projectile` | Greater Gestalt | ดีเลย์ 34 | เกม | `moves_sim.lua:82` |  |

<a id="alterguardian_phase4_lunarrift"></a>

## alterguardian_phase4_lunarrift — Celestial Scion

แหล่งข้อมูล: เกม `moves_sim.lua:134`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_burst_pre` ▦ | atk_burst_pre, atk_burst_charge_loop, atk_burst_charge_to_shoot, atk_burst_shoot_loop | 146 | facing | 0 |  |  | supernova_cd | เกม | `moves_sim.lua:135` |
| `dash_pre` | dash_pre, dash_loop, dash_pst | 64 | target | 63 | พุ่งเป็นขา · เคลื่อน 14.3 |  |  | เกม | `moves_sim.lua:136` |
| `slam` | slam | 43 | target | 23 |  | alterguardian_phase4_lunarrift_slam_fx |  | เกม | `moves_sim.lua:137` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `alterguardian_phase4_lunarrift_slam_fx` |  | อยู่นาน · วาดกับท่าบอส · ดีเลย์ 1 · ตีถึง 34 | เกม | `moves_sim.lua:51` |  |

<a id="ancient_herald"></a>

## ancient_herald

แหล่งข้อมูล: TE `moves_sim_te.lua:35`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 20 | facing | 0 | ขนาด 1.25 |  |  | TE | `moves_sim_te.lua:35` |

<a id="ancient_hulk"></a>

## ancient_hulk

แหล่งข้อมูล: TE `moves_sim_te.lua:36`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_barrier` | atk_barrier | 64 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:36` |
| `atk_chomp` | atk_chomp | 15 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:36` |
| `atk_lob` | atk_lob | 183 | target | 31 | ตามเป้า | ancient_hulk_orb |  | TE | `moves_sim_te.lua:36` |
| `teleport_in` | teleport_in | 17 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:36` |
| `teleport_out_pre` | teleport_out_pre, teleport_out | 51 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:36` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `ancient_hulk_mine` |  | อยู่นาน · ดีเลย์ 0 | TE | `moves_sim_te.lua:9` | simmoves.lua:3164 |
| `ancient_hulk_orb` |  | เคลื่อนที่ · ดีเลย์ 153 | TE | `moves_sim_te.lua:10` |  |

**โค้ดพิเศษที่อ้างถึง:** modmain.lua:927

<a id="ancient_robot_claw"></a>

## ancient_robot_claw

แหล่งข้อมูล: TE `moves_sim_te.lua:37`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 30 | target | 0 | ตามเป้า | laser, laserempty | laserbeam_cd | TE | `moves_sim_te.lua:37` |
| `atk_pre` | atk_pre, atk_loop, atk_pst | 44 | target | 0 | ตามเป้า · เคลื่อน 1.0 |  |  | TE | `moves_sim_te.lua:37` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `laser` |  | ดีเลย์ 0 · ตีถึง 0 | TE | `moves_sim_te.lua:22` |  |
| `laserempty` |  | วาดกับท่าบอส · ดีเลย์ 0 · ตีถึง 0 | TE | `moves_sim_te.lua:23` |  |

<a id="ancient_robot_head"></a>

## ancient_robot_head

แหล่งข้อมูล: TE `moves_sim_te.lua:38`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk_loop, atk_pst | 41 | target | 0 | ตามเป้า · เคลื่อน 1.0 |  |  | TE | `moves_sim_te.lua:38` |

<a id="ancient_robot_leg"></a>

## ancient_robot_leg

แหล่งข้อมูล: TE `moves_sim_te.lua:39`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk_loop, atk_pst | 42 | target | 0 | ตามเป้า · เคลื่อน 1.0 |  |  | TE | `moves_sim_te.lua:39` |

<a id="ancient_robot_ribs"></a>

## ancient_robot_ribs

แหล่งข้อมูล: TE `moves_sim_te.lua:40`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 30 | target | 0 | ตามเป้า | laser, laserempty | laserbeam_cd | TE | `moves_sim_te.lua:40` |
| `atk_pre` | atk_pre, atk_loop, atk_pst | 44 | target | 0 | ตามเป้า · เคลื่อน 1.0 |  |  | TE | `moves_sim_te.lua:40` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `laser` |  | ดีเลย์ 0 · ตีถึง 0 | TE | `moves_sim_te.lua:22` |  |
| `laserempty` |  | วาดกับท่าบอส · ดีเลย์ 0 · ตีถึง 0 | TE | `moves_sim_te.lua:23` |  |

<a id="ancient_trepidation"></a>

## ancient_trepidation — Trepidation

แหล่งข้อมูล: UM `moves_sim_um.lua:94`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 12 | target | 0 | ขนาด 2 |  |  | UM | `moves_sim_um.lua:95` |

<a id="antlion"></a>

## antlion — Antlion

แหล่งข้อมูล: เกม `moves_sim.lua:139`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `cast_pre` | cast_pre, cast_pst | 33 | target | 3 | ตีด้วยของเท่านั้น | sandspike_med, sandspike_short, sandspike_tall |  | เกม | `moves_sim.lua:140` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `antlion_sinkhole` | Sinkhole | ดีเลย์ 0 | เกม | `moves_sim.lua:52` |  |
| `sandspike_med` |  | ดีเลย์ 30 | เกม | `moves_sim.lua:89` |  |
| `sandspike_short` |  | ดีเลย์ 30 | เกม | `moves_sim.lua:90` |  |
| `sandspike_tall` |  | ดีเลย์ 30 | เกม | `moves_sim.lua:91` |  |

<a id="antman"></a>

## antman

แหล่งข้อมูล: TE `moves_sim_te.lua:41`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | ขนาด 1.15 |  |  | TE | `moves_sim_te.lua:41` |

<a id="antman2"></a>

## antman2

แหล่งข้อมูล: TE `moves_sim_te.lua:42`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 | ขนาด 1.15 |  |  | TE | `moves_sim_te.lua:42` |

<a id="antman_warrior"></a>

## antman_warrior

แหล่งข้อมูล: TE `moves_sim_te.lua:43`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk2` | atk2 | 13 | target | 0 | ขนาด 1.15 |  |  | TE | `moves_sim_te.lua:43` |

<a id="aphid"></a>

## aphid — Aphid

แหล่งข้อมูล: UM `moves_sim_um.lua:97`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `attack` | attack | 10 | target | 0 |  |  |  | UM | `moves_sim_um.lua:98` |
| `leap_attack` | leap_attack, taunt | 18 | target | 0 | ตามเป้า |  |  | UM | `moves_sim_um.lua:99` |

<a id="archive_centipede"></a>

## archive_centipede — Ancient Sentrypede

แหล่งข้อมูล: เกม `moves_sim.lua:142`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 9 | target | 0 |  |  |  | เกม | `moves_sim.lua:143` |
| `atk_aoe` | atk_aoe | 25 | facing | 0 |  |  |  | เกม | `moves_sim.lua:144` |
| `atk_roll_pre` | atk_roll_pre, atk_roll_loop, atk_roll_pst | 11 | target | 0 | เคลื่อน 20.0 |  |  | เกม | `moves_sim.lua:145` |

