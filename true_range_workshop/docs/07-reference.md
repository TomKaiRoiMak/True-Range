# 07 · อ้างอิง

[← สารบัญ](README.md)

## เครื่องมือที่ใช้บ่อย (`true_range_workshop\`)

### ติดตั้ง / ตรวจ

| คำสั่ง | ทำอะไร |
|---|---|
| `tools\install.ps1 [-Src <dir>] [-SkipTests]` | ตรวจ + ทดสอบ + คัดลอก mod เข้าเกม |
| `tools\install_client.ps1 [-Src <dir>]` | สร้างตัว Client จากต้นฉบับเดียวกัน |
| `tools\hand_check.ps1` | ท่าเขียนมือยังชี้ของที่มีในเกม |
| `tools\modenv_check.lua` | modmain ไม่ใช้ของที่ mod env ไม่มี |
| `tools\nomove_check.lua` | ท่าที่เกมมีแต่ข้อมูลไม่มี |
| `tools\make_catalog.ps1` | สร้าง [สารบัญมอนและท่า](catalog/README.md) จากไฟล์ข้อมูล |

### ทดสอบ

| คำสั่ง | ทำอะไร |
|---|---|
| `tools\run_bench.ps1` | testbench (ดู [05](05-testing.md)) |
| `tools\run_lag.ps1` | lag bench (เกมจริง) |
| `tests\bench_replay.ps1` | replay ทั้งชุดเป็นตาราง |
| `tests\replay.lua`, `tests\replay_haz.lua` | replay บอส / ของที่ปล่อย (รายไฟล์) |
| `tests\pics.ps1` | ภาพของสิ่งที่วาด ณ เวลาที่กำหนด |
| `tools\lag_frames.ps1`, `lag_land.ps1`, `lagthing_to_haz.ps1` | วิเคราะห์ log ของ lag bench |
| `tools\never_force.ps1` | สร้างไฟล์บังคับ state จากรายการ NEVER |

### สร้างข้อมูล

| คำสั่ง | ทำอะไร |
|---|---|
| `tools\sim_moves.lua` | รัน stategraph ของบอส offline |
| `tools\build_um.ps1`, `build_te.ps1`, `build_all_tables.ps1`, `build_all_follow.ps1` | สร้างไฟล์ข้อมูลทั้งชุด |
| `tools\mod_scripts.ps1 -Mod <id> -Name <n>` | โค้ดเกม + โค้ด mod ซ้อนกัน (`game_scripts_<n>`) |
| `tools\anim_lengths.ps1` | ความยาวอนิเมชันทุกตัว |
| `tools\verify.ps1` | แตกโค้ดเกมใหม่เมื่อ `scripts.zip` เปลี่ยน + ตรวจรวม |

### ดูแลดิสก์

| คำสั่ง | ทำอะไร |
|---|---|
| `tools\prune_bench_logs.ps1 [-Apply]` | แสดง (หรือย้ายไปถังขยะ) log เก่า — เก็บ baseline + 2 รอบเต็มล่าสุด + 2 วันล่าสุด |

## สวิตช์ที่ควรรู้ (จากงาน 1.1.6)

ทุกตัวตั้งเป็น global (`TR_OLD_X=1` ใน env ของ replay) = กลับไปแบบเดิม · ดูคอมเมนต์ข้างโค้ดสำหรับรายละเอียด/ตัวเลข

| สวิตช์ | กฎ |
|---|---|
| `TR_OLD_LANDSTOP`, `LANDKEEP`, `LANDHOLD`, `LANDWAIT`, `AIRSTILL` | ลูกโยน: จุดตกนิ่ง, ไม่วาดกลางอากาศ |
| `TR_OLD_GLOWPULSE`, `GLOWGRACE`, `GLOWOVERLAP`, `GLOWHOLD`, `GLOWAFTERMOVE` | วงเตือน cooldown ไม่กระพริบ |
| `TR_OLD_LANDAT`, `LANDLOOSE`, `LANDTILL`, `LAND2` | Umbral optic blast/วาร์ป วาดที่ beam/เป้าจริง |
| `TR_OLD_LEADTP`, `LEADTPSTEP`, `LEADSTOP` | LeadMoving: ไม่นำตอนวาร์ป/ตอนหยุด |
| `TR_OLD_CHAINLAST` | Rock Master: ครั้งสุดท้ายของ chain dash |
| `TR_OLD_WORMDIRT` (modmain) | หนอน: วงกองดินเฉพาะตอนหัวโผล่/ท่อนผ่าน |
| `TR_OLD_HUNTSTICK` (modmain) | บอสค้างในรายการวาด .3 s หลังไล่ |

> สวิตช์ที่มีป้าย (modmain) replay มองไม่เห็น — A/B ด้วย `run_lag.ps1 -Old "..."`
| `TR_BENCH_OLD_*` | สวิตช์ฝั่ง testbench |

## คำศัพท์

| คำ | ความหมาย |
|---|---|
| **move / ท่า** | การโจมตีหนึ่งแบบของบอส (ระบุด้วยอนิเมชันแรก) |
| **hazard / ของที่ปล่อย / thing** | entity ที่บอสสร้างแล้วทำดาเมจ (ลูกไฟ หนาม beam) — `_hazards` ในข้อมูล |
| **sim** | การรันโค้ดเกมจริงแบบ offline เพื่อสร้างรูปท่า |
| **share / lane** | หน่วยงานของ testbench: 1 server = 1 share, แบ่งเป็นหลายเลน (บอสหลายตัวพร้อมกัน ห่างกัน) |
| **scene / ฉาก** | หนึ่งครั้งที่บอสเริ่มท่า + ผู้เล่นถูกวางตามแบบทดสอบ |
| **missed** | โดน แต่ไม่ได้วาดคลุม |
| **false / drawn-in-no-strike** | วาดคลุม แต่ไม่โดน |
| **NOT drawn** | (lag bench) missed ฝั่ง client |
| **NEVER** | ท่าในข้อมูลที่ bench ไม่เคยเห็นตี |
| **blink** | ภาพของเจ้าของหนึ่งหาย 1–3 เฟรมแล้วกลับ |
| **jump / snap back** | รูปกระโดดไกลในเฟรมเดียว / กระโดดแล้วกลับ |
| **Predictive / None** | ตัวเลือก Lag Compensation ของเกม (pred=1 / pred=0) |
| **LeadMoving** | วาดนำหน้าของที่เคลื่อนที่ ชดเชยที่ client เห็นช้า |
| **UM / TE** | Uncompromising Mode / Tropical Experience |
| **ASBOSS** | การโดนจากของที่ปล่อย แต่ท่าของบอสวาดคลุมไว้แล้ว (ไม่นับพลาด) |
