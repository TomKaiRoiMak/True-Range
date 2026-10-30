# 08 · สถานะปัจจุบัน — เวอร์ชัน 1.1.6 (อัปเดต 2026-10-30)

[← สารบัญ](README.md)

> **กติกาของหน้านี้**: มีแค่งานที่ยังเปิด + ตัวเลขล่าสุด, งานละ 1 บรรทัด. ปิดงานแล้ว = ลบบรรทัดออก (รายละเอียดอยู่ใน `git log` ตาม template ปัญหา/สาเหตุ/แก้/วัด/ค้าง). ประวัติก่อนหน้า: [history/29_status-2026-10.md](history/29_status-2026-10.md)

## ตัวเลขล่าสุด (baseline)

| วัด | ค่า | เมื่อ |
|---|---|---|
| replay 1610 host | missed 14 / 56,739 · false 1,879 (เดิม 1,903 ก่อนนับ hit ไม่มีผู้ตี, cbae236) | 2026-10-30 17:30; วัดซ้ำ 23:30 หลังงานคืนนี้ - เท่าเดิม |
| replay 1610 client (Predictive) | missed 24 / 56,798 · false 2,858 (2,896 ก่อน cbae236) · boss jumps 748 (เดิม 1,204) | 2026-10-30 19:25; วัดซ้ำ 23:30 - เท่าเดิม |
| lag บอสหลัก 16 ตัว 70 นาที | NOT drawn 12 / 2,165 (0.55%) - เดิม 13 / 1,980 (0.66%, lag 0314) | lag 1042, เกม 760944 + ตัวแก้ 30 ต.ค. |
| lag มอนทั่วไป 20 ตัว 50 นาที (เกมใหม่) | NOT 1 / 853 (0.12%), false 4 | lag 1240 |
| lag บอสหลัก 15 ตัว 40 นาที (ตัวบันทึกรายตัว) | NOT 8 / 970 - AG2 spin 4 ตอน client ตามหลัง server 3-6.5 (lag spike); วงตัว (body) กะพริบ 0 | lag 1621 |
| เกม / ข้อมูล | 760944 / data `0ADD43380DDD` | ติดตั้งแล้ว |

## กำลังทำ

| งาน | สถานะ |
|---|---|
| lag ยังไม่ได้วัด: Wixie (ลูกเป็นวงแล้ว c9c59b0), mindweaver, fuelseeker, ancient_trepidation_arm (4b9373c), hound_lightning / goat_lightning (6ad449d), budget ชิ้นใหม่ต่อเฟรม (9a4c93e), TE jellyfish วงตอนช็อต (modmain), toadlingspawner (7d19d55), cursed fire, Scion fissures (เฉพาะใน arena - bench ไม่มี), Wixie clone (bench 2348 host 0 พลาด) - bench 2152 (ไม่มีหน้าจอ): บอสทุกตัว drawn ครบ host/client, ของ host 0 พลาด; client: ลูก Wixie 13 (ยิงจาก 4 ถึงตัวในไม่กี่ tick); mindweaver/fuelseeker ไม่ได้ตี (ต้องคนบ้า) | เกมเปิดไม่ขึ้นหลังล่ม 20:57 - CrashReporter.exe ค้าง (ปิดเองไม่ได้) |

## รอเจ้าของตัดสิน

| งาน | ทางเลือก |
|---|---|
| Glacial Hound ฝั่ง Predictive โดนปลายแนวหนาม 13-23 / ~100 (ผู้เล่นบนจอนำ server) | ยืดปลายเลนตาม lead → false เพิ่ม / ปล่อยไว้ |
| UM fire hounds: "set alight" 0-2 / run ทั้งที่ไม่ได้อยู่ในวงไหน 3-6 วิ - ผู้เล่นห่างไฟ 2.5-3 (วงเผาของไฟ = scale×2 ≤ 1.9) = ความร้อนลาม (propagator) ที่เราไม่ได้วาด (lag 1526) | วาดวงความร้อนจาง ๆ รอบไฟทุกกอง → รก / ปล่อยไว้ |
| Daywalker pounce: ครั้งแรกเตือนได้แค่ 1-4 เฟรม (15/36) - ท่า pre เล่น `run_pre` ตัวเดียวกับออกวิ่ง (`tools\warn_time.lua`, lag 0314) | วาดตั้งแต่ run_pre ตอนอยู่ใกล้เป้า → เตือนผิดทุกครั้งที่ออกวิ่ง / ปล่อยไว้ |

## งานเปิด (เรียงตามความสำคัญ)

| # | งาน | ข้อมูลที่มี |
|---|---|---|
| 2 | ของที่ client replay ยังพลาด (14, `tools\haz_missed.ps1` 11:35) | sporecloud_toad 5 (ยืนขอบ 3.50 พอดี), stageusher_attackhand 3 (anim `sleep` ซ้ำกับ sitdown), charlie_boss_minion1 2 (วิ่งหนีหลังล็อก), spiketrail 1, eyeofterror_laser 1, glacialhound_icespike 1, um_bear_trap 1 |
| 4 | กะพริบเล็กที่เหลือ (frame_check, lag 1042) | Eye REVERSE เล็ก, Klaus POP 1, AG1 2, lunarrift roll JUMP 2; bearger_boulder JUMP 27 = lead เปิดทันทีตอนเริ่มกลิ้ง (ข้อแลกเดิม); gestalt projectile JUMP 20 = โซนข้างหน้าวางใหม่ 1.4 ครั้งเดียวก่อนหมด; AG2 spin_pst JUMP ~1.04 ครั้งเดียวตอนจบสปิน (replay client 67 - ตรงเกณฑ์ 1 พอดี, วาดทาง legs ไม่ใช่ Draw/DrawTable); web_mortar JUMP 11 (lag 1334) = ย้ายจากรอบตัวไปจุดตกครั้งเดียวตอนเริ่มตก; bigshadowtentacle AIM 14 |

## ตัดสินแล้วว่าไม่แก้

- ลาวาวง Moonmaw NOT 0.65% ที่ขอบ 2.76-3.00 — client เห็นตำแหน่งช้า, ขยายวง = false ทุกรอบ
- หนอน: ท่อนโผล่+ตีเฟรมเดียวกัน — เจ้าของไม่ให้แสดงวงรอบกองดิน (2026-10-29)
- shadowthrall_mouth JUMP (replay client 375) — ปากที่ Umbral เรียก (shrouden_bite_loop) วิ่ง 8/วิ กัดทุก ~7 เฟรม แต่ละครั้งวาดที่ตัวมันตอนกัด = ก้าวไป ~1 ต่อครั้งตามเกม (probe ใน replay 2026-10-30); ease ช่วยแค่ 430 → 375
- mutatedbearger combo1 ขอบครึ่งวง 87°/90°; combo1a 1 / 416 = พุ่งเลยตัวผู้เล่นไป 1.1 ในเฟรมที่ตี (เร็ว 11.7) ผู้เล่นอยู่ข้างตัว 90° ห่าง 1.4
- rook LATE ใน replay (ตอนเริ่มพุ่ง) - ในเกมเตือนก่อนโดนค่ากลาง 49 เฟรม (1.6 วิ), 8/8 drawn in (lag 1240, `tools\warn_time.lua`); ease ทำ false 1 → 15
- beeguard atk หมุนตามเป้าที่บินวน (frame_check AIM ~12 / run) - กัดเป้าตัวเดียว (single, frame target): วาดฝั่งที่เป้าอยู่ ตามเกม (lag 1042: กลางรูปห่างผึ้ง 0-2.75), NOT 0
- Bee Queen วงตีโผล่ 2 เฟรมแล้วหาย เมื่อ UM สั่งสตั้น (ตัวจับเวลา 3.5 วิ) ตอนเพิ่งเริ่มตี — เจ้าของ: ปล่อยไว้ (2026-10-30)

## หลังปล่อย 1.1.6 (ตกลงกันแล้ว)

- แยก `simmoves.lua` / `predict.lua` เป็นโมดูล (เพดาน 200 local)
- ลบสวิตช์ `TR_OLD_xxx` ที่ครบอายุ (ดูกติกาใน `VERIFY_PLAN.md`)
- พิจารณาโหลดข้อมูลตามบอสที่เจอ (lazy) — วัดแล้ว 93 ms / 30 MB ยังไม่เร่ง
