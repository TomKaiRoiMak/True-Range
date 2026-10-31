# 08 · สถานะปัจจุบัน — เวอร์ชัน 1.1.6 (อัปเดต 2026-10-30)

[← สารบัญ](README.md)

> **กติกาของหน้านี้**: มีแค่งานที่ยังเปิด + ตัวเลขล่าสุด, งานละ 1 บรรทัด. ปิดงานแล้ว = ลบบรรทัดออก (รายละเอียดอยู่ใน `git log` ตาม template ปัญหา/สาเหตุ/แก้/วัด/ค้าง). ประวัติก่อนหน้า: [history/29_status-2026-10.md](history/29_status-2026-10.md)

## ตัวเลขล่าสุด (baseline)

| วัด | ค่า | เมื่อ |
|---|---|---|
| replay 1610 host / client (Predictive) | host missed 14 / 56,739 · false 1,879; client missed 24 / 56,798 · false 2,858 · boss jumps 748 | 2026-10-31 (นับ hit ไม่มีผู้ตีแล้ว cbae236) |
| bench ทุกมอน (271, 3 รอบ) เกม 761239 + replay | host missed 15 / 60,408 · false 2,141; client missed 29 / 60,430 · false 3,111 | bench 2026-10-31_0741 |
| bench TE (มอนของ TE 174) + replay -TE | host missed 36 / 25,306 · client 36 / 25,329 · two-shapes 0 (เดิม 45 / 57 / 962 ก่อนแก้ scorpion, rookwater) | bench 2026-10-31_0611 |
| lag บอสหลัก 15 ตัว 40 นาที | NOT 10 / 1,008 (on 3/401, off 7/607) · frame_check 243 | lag 2026-10-31_0407 |
| lag มอนทั่วไป 20 ตัว | NOT 4 / 529 (icehound 3 on = ปลายเลนแบบ Glacial) · frame_check 80 | lag 2026-10-31_0448 |
| lag TE (-TE ปิด UM) | NOT 0 / 90 | lag 2026-10-31_0706 |
| เกม / ข้อมูล | 761239 / data `83852BF58E33` | ติดตั้งแล้ว |

## กำลังทำ

| งาน | สถานะ |
|---|---|
| lag 0347 (ไม่ล่ม, new pieces สูงสุด 1,210): goat / trepidation / สุนัขสายฟ้า / Spazmatism NOT 0; Wixie NOT 7/47 on, 4/38 off (ลูกระยะใกล้), clone 1/10; union REVERSE 165 = ลูกพัดของ Wixie | mindweaver ✔ จับตอนตัวเราห่าง 2.84 ในวง 3 (lag 0936 - จับด้วย DoDelta ตัวนับเลยนับเป็น false 1), fuelseeker ✔ NOT 0 / 4 (lag 0929, กองไฟให้ดูด); ยังไม่ได้วัดในเกม: haunt ไม่เริ่ม, toadling spawner ทำเกมล่ม (Invalid Prefab ของ UM - ห้ามใส่ใน lag), moonpig ไม่ตี, jellyfish ✔ วง 3 ขึ้นทุกเฟรมที่ช็อต (lag 0855: 539 / 540), fissure ต้องมี arena |

## รอเจ้าของตัดสิน

| งาน | ทางเลือก |
|---|---|
| - | - |

## งานเปิด (เรียงตามความสำคัญ)

| # | งาน | ข้อมูลที่มี |
|---|---|---|
| 2 | ของที่ client replay ยังพลาด (14, `tools\haz_missed.ps1` 11:35) | sporecloud_toad 5 (ยืนขอบ 3.50 พอดี), stageusher_attackhand 3 (anim `sleep` ซ้ำกับ sitdown), charlie_boss_minion1 2 (วิ่งหนีหลังล็อก), spiketrail 1, eyeofterror_laser 1, glacialhound_icespike 1, um_bear_trap 1 |
| 10 | TE: lag 0706 (-TE, ปิด UM) scorpion / rookwater / bossboar / slip NOT 0 / 90; rookwater ระยะ 3 ของตัวเอง (bench ในทะเล 0933: missed 2 → 0, false 22 → 40); false บนบก 544 = bench เดิมวางมันบนบก (ตอนนี้วางในทะเลแล้ว) | things missed 30 ดูแล้ว (hulk spin = modmain ✔ วง 7 ขึ้น 1,974 / 2,009 เฟรมของสปิน lag 0901; mine = ไฟ); UM+TE พร้อมกันล่มเมื่อมีผู้เล่น (moisture IsInBathingPool); Hulk ตายแล้ว server ค้างใน bench = dropparts ของ TE วนหาพื้น Hamlet ใน 80 ไม่เจอ (โลก bench ไม่มี) ไม่ใช่ของเรา |
| 4 | กะพริบเล็กที่เหลือ (frame_check, lag 1042) | Eye REVERSE เล็ก, Klaus POP 1, AG1 2, lunarrift roll JUMP 2; bearger_boulder JUMP 27 = lead เปิดทันทีตอนเริ่มกลิ้ง (ข้อแลกเดิม); gestalt projectile JUMP 20 = โซนข้างหน้าวางใหม่ 1.4 ครั้งเดียวก่อนหมด; AG2 spin_pst JUMP ~1.04 ครั้งเดียวตอนจบสปิน (replay client 67 - ตรงเกณฑ์ 1 พอดี, วาดทาง legs ไม่ใช่ Draw/DrawTable); web_mortar JUMP 11 (lag 1334) = ย้ายจากรอบตัวไปจุดตกครั้งเดียวตอนเริ่มตก; bigshadowtentacle AIM 14 |

## ตัดสินแล้วว่าไม่แก้

- ลาวาวง Moonmaw NOT 0.65% ที่ขอบ 2.76-3.00 — client เห็นตำแหน่งช้า, ขยายวง = false ทุกรอบ
- หนอน: ท่อนโผล่+ตีเฟรมเดียวกัน — เจ้าของไม่ให้แสดงวงรอบกองดิน (2026-10-29)
- shadowthrall_mouth JUMP (replay client 375) — ปากที่ Umbral เรียก (shrouden_bite_loop) วิ่ง 8/วิ กัดทุก ~7 เฟรม แต่ละครั้งวาดที่ตัวมันตอนกัด = ก้าวไป ~1 ต่อครั้งตามเกม (probe ใน replay 2026-10-30); ease ช่วยแค่ 430 → 375
- mutatedbearger combo1 ขอบครึ่งวง 87°/90°; combo1a 1 / 416 = พุ่งเลยตัวผู้เล่นไป 1.1 ในเฟรมที่ตี (เร็ว 11.7) ผู้เล่นอยู่ข้างตัว 90° ห่าง 1.4
- rook LATE ใน replay (ตอนเริ่มพุ่ง) - ในเกมเตือนก่อนโดนค่ากลาง 49 เฟรม (1.6 วิ), 8/8 drawn in (lag 1240, `tools\warn_time.lua`); ease ทำ false 1 → 15
- beeguard atk หมุนตามเป้าที่บินวน (frame_check AIM ~12 / run) - กัดเป้าตัวเดียว (single, frame target): วาดฝั่งที่เป้าอยู่ ตามเกม (lag 1042: กลางรูปห่างผึ้ง 0-2.75), NOT 0
- Bee Queen วงตีโผล่ 2 เฟรมแล้วหาย เมื่อ UM สั่งสตั้น (ตัวจับเวลา 3.5 วิ) ตอนเพิ่งเริ่มตี — เจ้าของ: ปล่อยไว้ (2026-10-30)
- Glacial Hound ฝั่ง Predictive โดนปลายแนวหนาม 13-23 / ~100 — เจ้าของ: ปล่อยไว้ (2026-10-31)
- Daywalker pounce ครั้งแรกเตือน 1-4 เฟรม (run_pre ตัวเดียวกับออกวิ่ง) — เจ้าของ: ปล่อยไว้ (2026-10-31)
- UM fire hounds ความร้อนลาม (propagator) set alight นอกวง — เจ้าของ: ปล่อยไว้ ไม่วาดวงความร้อน (2026-10-31)

## หลังปล่อย 1.1.6 (ตกลงกันแล้ว)

- แยก `simmoves.lua` / `predict.lua` เป็นโมดูล (เพดาน 200 local)
- ลบสวิตช์ `TR_OLD_xxx` ที่ครบอายุ (ดูกติกาใน `VERIFY_PLAN.md`)
- พิจารณาโหลดข้อมูลตามบอสที่เจอ (lazy) — วัดแล้ว 93 ms / 30 MB ยังไม่เร่ง
