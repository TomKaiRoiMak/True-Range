# สารบัญมอน — W

[← สารบัญทั้งหมด](README.md) · สร้างอัตโนมัติด้วย `tools\make_catalog.ps1` — **อย่าแก้หน้านี้ด้วยมือ**

คอลัมน์: **ตีเฟรม** = เฟรมแรกที่ตี (30 เฟรม/วินาที) · **เล็ง** = `target` หันตามเป้า / `facing` ตามที่บอสหัน · **lock** = เฟรมที่หยุดเล็ง · **แบบ** = ลักษณะพิเศษของท่า · **ที่อยู่** = ไฟล์ข้อมูล:บรรทัด (ใน `true_range/scripts/true_range/`)

<a id="wagboss_robot"></a>

## wagboss_robot — W.A.R.B.O.T.

แหล่งข้อมูล: เกม `moves_sim.lua:646`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_leap_pre` | atk_leap_pre, atk_leap, atk_leap_pst | 82 | facing | 78 |  |  | leap_cd | เกม | `moves_sim.lua:647` |
| `atk_signal_pre` ▦ | atk_signal_pre, atk_signal_loop, atk_signal_pst | 98 | target |  | ตามเป้า | wagboss_beam_fx | orbitalstrike_cd | เกม | `moves_sim.lua:648` |
| `atk_squish` | atk_squish | 27 | facing | 0 |  |  |  | เกม | `moves_sim.lua:649` |
| `taunt` | taunt | 13 | facing | 0 |  |  | tantrum_cd | เกม | `moves_sim.lua:650` |
| `taunt2_pre` | taunt2_pre, taunt2_loop, taunt2_pst | 58 | facing | 0 |  |  | tantrum_cd | เกม | `moves_sim.lua:651` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `wagboss_beam_fx` |  | อยู่นาน · ดีเลย์ 34 | เกม | `moves_sim.lua:100` |  |
| `wagboss_missile` | Thermalock Missile | เคลื่อนที่ · ดีเลย์ 114 | เกม | `moves_sim.lua:101` |  |

<a id="wagdrone_flying"></a>

## wagdrone_flying — Warbler

แหล่งข้อมูล: เกม `moves_sim.lua:653`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk, atk_pst | 44 | target | 0 |  | wagdrone_projectile_fx |  | เกม | `moves_sim.lua:654` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `wagdrone_projectile_fx` |  | ดีเลย์ 32 | เกม | `moves_sim.lua:102` |  |

<a id="wagdrone_rolling"></a>

## wagdrone_rolling — Terramite

แหล่งข้อมูล: เกม `moves_sim.lua:656`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|

<a id="walrus"></a>

## walrus — MacTusk

แหล่งข้อมูล: เกม `moves_sim.lua:657`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 20 | target | 20 |  |  |  | เกม | `moves_sim.lua:657` |

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `um_bear_trap` | Snap-Trap | อยู่นาน · ดีเลย์ 0 | UM | `moves_sim_um.lua:65` |  |

<a id="wanawanatiki"></a>

## wanawanatiki

แหล่งข้อมูล: TE `moves_sim_te.lua:195`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | TE | `moves_sim_te.lua:195` |

<a id="warg"></a>

## warg — Varg

แหล่งข้อมูล: เกม `moves_sim.lua:658`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 11 | target | 0 |  |  |  | เกม | `moves_sim.lua:659` |

<a id="warglet"></a>

## warglet — Varglet

แหล่งข้อมูล: เกม `moves_sim.lua:661`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 16 | target | 0 | ขนาด 1.5 |  |  | เกม | `moves_sim.lua:662` |

<a id="watercrocodog"></a>

## watercrocodog

แหล่งข้อมูล: TE `moves_sim_te.lua:196`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 20 | target | 0 |  |  |  | TE | `moves_sim_te.lua:196` |

<a id="waterplant"></a>

## waterplant — Sea Weed

แหล่งข้อมูล: เกม `moves_sim.lua:664`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|

**ของที่ปล่อย**

| ของ | ชื่อ | แบบ | แหล่ง | ที่อยู่ | โค้ดที่อ้างถึง |
|---|---|---|---|---|---|
| `waterplant_projectile` |  | เคลื่อนที่ · ดีเลย์ 0 · ตีถึง 30 | เกม | `moves_sim.lua:105` |  |

<a id="weevole"></a>

## weevole

แหล่งข้อมูล: TE `moves_sim_te.lua:197`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `leap_attack` | leap_attack, taunt | 18 | target | 0 | ตามเป้า |  |  | TE | `moves_sim_te.lua:197` |

<a id="whale_blue"></a>

## whale_blue

แหล่งข้อมูล: TE `moves_sim_te.lua:198`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:198` |

<a id="whale_bluefinal"></a>

## whale_bluefinal

แหล่งข้อมูล: TE `moves_sim_te.lua:199`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 25 | target | 0 |  |  |  | TE | `moves_sim_te.lua:199` |

<a id="whale_white"></a>

## whale_white

แหล่งข้อมูล: TE `moves_sim_te.lua:200`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 25 | target | 0 | ขนาด 1.25 |  |  | TE | `moves_sim_te.lua:200` |

<a id="wicker_tentacle"></a>

## wicker_tentacle — Sickly Tentacle

แหล่งข้อมูล: UM `moves_sim_um.lua:519`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_loop` | atk_loop, atk_idle | 7 | target | 0 |  |  |  | UM | `moves_sim_um.lua:520` |
| `atk_pre` | atk_pre, atk_loop, atk_idle | 32 | target | 0 |  |  |  | UM | `moves_sim_um.lua:521` |

<a id="wildbeaver"></a>

## wildbeaver

แหล่งข้อมูล: TE `moves_sim_te.lua:201`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 9 | target | 0 |  |  |  | TE | `moves_sim_te.lua:201` |

<a id="wildbeaverguard"></a>

## wildbeaverguard

แหล่งข้อมูล: TE `moves_sim_te.lua:202`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk_pre` | atk_pre, atk | 9 | target | 0 |  |  |  | TE | `moves_sim_te.lua:202` |

<a id="wildbore"></a>

## wildbore

แหล่งข้อมูล: TE `moves_sim_te.lua:203`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | TE | `moves_sim_te.lua:203` |
| `charge_atk` | charge_atk | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:203` |

<a id="wildboreguard"></a>

## wildboreguard

แหล่งข้อมูล: TE `moves_sim_te.lua:204`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | TE | `moves_sim_te.lua:204` |
| `charge_atk` | charge_atk | 12 | target | 0 |  |  |  | TE | `moves_sim_te.lua:204` |

<a id="wildboreking"></a>

## wildboreking

แหล่งข้อมูล: TE `moves_sim_te.lua:205`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `death` | death | 20 | facing | 0 |  |  |  | TE | `moves_sim_te.lua:205` |
| `jump` | jump, walk_loop | 30 | facing | 0 | พุ่งเป็นขา |  | GroundPound | TE | `moves_sim_te.lua:205` |
| `standup` | standup | 10 | facing | 0 |  |  | GroundPound | TE | `moves_sim_te.lua:205` |

<a id="woodlegs1"></a>

## woodlegs1

แหล่งข้อมูล: TE `moves_sim_te.lua:206`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 13 | target | 0 |  |  |  | TE | `moves_sim_te.lua:206` |

<a id="worm"></a>

## worm — Depths Worm

แหล่งข้อมูล: เกม `moves_sim.lua:665`

| ท่า | อนิเมชัน | ตีเฟรม | เล็ง | lock | แบบ | ของที่ปล่อย | cooldown | แหล่ง | ที่อยู่ |
|---|---|---|---|---|---|---|---|---|---|
| `atk` | atk | 25 | target | 0 |  |  |  | เกม | `moves_sim.lua:666` |
| `atk_pre` | atk_pre, atk | 50 | target | 0 |  |  |  | เกม | `moves_sim.lua:667` |

