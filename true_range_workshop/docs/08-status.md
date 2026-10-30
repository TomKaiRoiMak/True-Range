# 08 · สถานะปัจจุบัน — เวอร์ชัน 1.1.6 (อัปเดต 2026-10-30)

[← สารบัญ](README.md)

> **กติกาของหน้านี้**: มีแค่งานที่ยังเปิด + ตัวเลขล่าสุด, งานละ 1 บรรทัด. ปิดงานแล้ว = ลบบรรทัดออก (รายละเอียดอยู่ใน `git log` ตาม template ปัญหา/สาเหตุ/แก้/วัด/ค้าง). ประวัติก่อนหน้า: [history/29_status-2026-10.md](history/29_status-2026-10.md)

## ตัวเลขล่าสุด (baseline)

| วัด | ค่า | เมื่อ |
|---|---|---|
| replay 1610 host | missed 14 / 56,739 · false 1,903 | 2026-10-30 11:35, ตัวแก้ทั้งวัน |
| replay 1610 client (Predictive) | missed 23 / 56,798 · false 2,899 | 2026-10-30 11:35 |
| lag บอสหลัก 16 ตัว 70 นาที | NOT drawn 12 / 2,165 (0.55%) - เดิม 13 / 1,980 (0.66%, lag 0314) | lag 1042, เกม 760944 + ตัวแก้ 30 ต.ค. |
| lag ตระกูลหมู (เกมใหม่) | NOT 1 / 129, false 0 | lag 0726 |
| เกม / ข้อมูล | 760944 / data `0ADD43380DDD` | ติดตั้งแล้ว |

## กำลังทำ

| งาน | สถานะ |
|---|---|
| - | - |

## รอเจ้าของตัดสิน

| งาน | ทางเลือก |
|---|---|
| Glacial Hound ฝั่ง Predictive โดนปลายแนวหนาม 13-23 / ~100 (ผู้เล่นบนจอนำ server) | ยืดปลายเลนตาม lead → false เพิ่ม / ปล่อยไว้ |
| Daywalker pounce: ครั้งแรกเตือนได้แค่ 1-4 เฟรม (15/36) - ท่า pre เล่น `run_pre` ตัวเดียวกับออกวิ่ง (`tools\warn_time.lua`, lag 0314) | วาดตั้งแต่ run_pre ตอนอยู่ใกล้เป้า → เตือนผิดทุกครั้งที่ออกวิ่ง / ปล่อยไว้ |

## งานเปิด (เรียงตามความสำคัญ)

| # | งาน | ข้อมูลที่มี |
|---|---|---|
| 2 | ของที่ client replay ยังพลาด (14, `tools\haz_missed.ps1` 11:35) | sporecloud_toad 5 (ยืนขอบ 3.50 พอดี), stageusher_attackhand 3 (anim `sleep` ซ้ำกับ sitdown), charlie_boss_minion1 2 (วิ่งหนีหลังล็อก), spiketrail 1, eyeofterror_laser 1, glacialhound_icespike 1, um_bear_trap 1 |
| 3 | บอสพลาดทีละ 1 ครั้ง (replay 1610) | rocky_boss_shadow dash_attack, twinofterror1 mouthcharge_loop, mutatedbearger combo1 |
| 4 | กะพริบเล็กที่เหลือ (frame_check, lag 1042) | Eye REVERSE เล็ก, Klaus POP 1, AG1 2, lunarrift roll JUMP 2, rook lead ตอนเริ่ม; bearger_boulder JUMP 27 = lead เปิดทันทีตอนเริ่มกลิ้ง (ข้อแลกเดิม); gestalt projectile JUMP 20 = โซนข้างหน้าวางใหม่ 1.4 ครั้งเดียวก่อนหมด |

## ตัดสินแล้วว่าไม่แก้

- ลาวาวง Moonmaw NOT 0.65% ที่ขอบ 2.76-3.00 — client เห็นตำแหน่งช้า, ขยายวง = false ทุกรอบ
- หนอน: ท่อนโผล่+ตีเฟรมเดียวกัน — เจ้าของไม่ให้แสดงวงรอบกองดิน (2026-10-29)
- shadowthrall_mouth JUMP — lead เปิดทันที, ease แล้วพลาดเพิ่ม
- mutatedbearger combo1 ขอบครึ่งวง 87°/90°
- beeguard atk หมุนตามเป้าที่บินวน (frame_check AIM ~12 / run) - กัดเป้าตัวเดียว (single, frame target): วาดฝั่งที่เป้าอยู่ ตามเกม (lag 1042: กลางรูปห่างผึ้ง 0-2.75), NOT 0
- Bee Queen วงตีโผล่ 2 เฟรมแล้วหาย เมื่อ UM สั่งสตั้น (ตัวจับเวลา 3.5 วิ) ตอนเพิ่งเริ่มตี — เจ้าของ: ปล่อยไว้ (2026-10-30)

## หลังปล่อย 1.1.6 (ตกลงกันแล้ว)

- แยก `simmoves.lua` / `predict.lua` เป็นโมดูล (เพดาน 200 local)
- ลบสวิตช์ `TR_OLD_xxx` ที่ครบอายุ (ดูกติกาใน `VERIFY_PLAN.md`)
- พิจารณาโหลดข้อมูลตามบอสที่เจอ (lazy) — วัดแล้ว 93 ms / 30 MB ยังไม่เร่ง
