# 08 · สถานะปัจจุบัน — เวอร์ชัน 1.1.6 (อัปเดต 2026-10-30)

[← สารบัญ](README.md)

> **กติกาของหน้านี้**: มีแค่งานที่ยังเปิด + ตัวเลขล่าสุด, งานละ 1 บรรทัด. ปิดงานแล้ว = ลบบรรทัดออก (รายละเอียดอยู่ใน `git log` ตาม template ปัญหา/สาเหตุ/แก้/วัด/ค้าง). ประวัติก่อนหน้า: [history/29_status-2026-10.md](history/29_status-2026-10.md)

## ตัวเลขล่าสุด (baseline)

| วัด | ค่า | เมื่อ |
|---|---|---|
| bench ทุกมอน (271, 3 รอบ) เกม 761239 + replay | host missed 20 / 58,304 · false 2,017; client missed 35 / 58,313 · false 2,503 (daywalker pounce 7 = ไม่แก้; replay CLIENT แก้ tell ช้า d34decb+) | bench 2026-11-01_0433 (testbench ใหม่; 0741 หลังแก้: 14 / 2,159 · 24 / 3,122) |
| bench TE (170 ตัว, testbench ใหม่) + replay -TE | host missed 55 / 25,722 · false 1,515; client 53 / 25,739 · false 1,581 (ของ 47 / 46 → 3 / 2 หลัง replay_haz รู้จักวงสปินของ hulk) | bench 2026-11-01_0556 (0611: 36 / 2,036) |
| lag บอสหลัก 15 ตัว | NOT 7 / 1,495 (on 3/638, off 4/857) · false 60 · AG2 2, moonmaw 2, shrouden 2, daywalker 1; minotaur / stalker 0 / 84 | lag 2026-10-31_1354 + 1441 (เดิม 0407: 10 / 1,008) |
| lag มอนทั่วไป 20 ตัว | NOT 3 / 546 (on 3/267: rook 2, walrus 1; off 0/279) · false 4 | lag 2026-10-31_1450 (เดิม 0448: 4 / 529) |
| lag TE (-TE ปิด UM) | NOT 0 / 90; wildboreking NOT 0 / 102 (on 44, off 58; false 9 / 22) | lag 2026-10-31_0706, 1029 |
| เกม / ข้อมูล | 761239 / data `83852BF58E33` | ติดตั้งแล้ว |

## กำลังทำ

| งาน | สถานะ |
|---|---|
| ของที่เพิ่มคืนนี้ วัดในเกมแล้ว | goat / trepidation / สุนัขสายฟ้า / Spazmatism / jellyfish / mindweaver / fuelseeker / haunt / moonpig NOT 0 (lag 0347-1006); Wixie NOT 1/43 on, 1/36 off (lag 1114, ทางลูก volley 7 เส้น - เดิม 7/47, 4/38); เหลือ: toadling spawner ทำเกมล่ม (Invalid Prefab ของ UM - ห้ามใส่ใน lag), fissure ต้องมี arena |

## รอเจ้าของตัดสิน

| งาน | ทางเลือก |
|---|---|
| - | - |

## งานเปิด (เรียงตามความสำคัญ)

| # | งาน | ข้อมูลที่มี |
|---|---|---|
| 2 | ของที่ client replay ยังพลาด (14, `tools\haz_missed.ps1` 11:35) | sporecloud ที่ห่าง 0.00 = bench วาร์ปตัวแทนลงกลางเมฆ (ตอนนี้นับเป็น BENCHMOVED, 7604f04); sporecloud_toad 5 (ยืนขอบ 3.50 พอดี), stageusher_attackhand 3 (anim `sleep` ซ้ำกับ sitdown), charlie_boss_minion1 2 (วิ่งหนีหลังล็อก), spiketrail 1, eyeofterror_laser 1, glacialhound_icespike 1, um_bear_trap 1 |
| 10 | TE ที่เหลือ: beetletaur / goddess_deer_gem / wildbeaverguard ทำ server bench ล่มด้วยโค้ด TE เอง (laststartattacktime nil, ต้องมี fountain, action ไม่มีเป้า); rookwater ในทะเล NOT 1 ตอนชนขอบเรา (lag 1347, ข้อมูลน้อย); Hulk ตายแล้ว server ค้าง (dropparts ของ TE) | ไม่ใช่ของเรา ยกเว้นจะทำ setup ให้ bench |
| 12 | NOT ของ lag 1354 (7 / 1,411) | AG2 2 = รางหนาม atk_spike หยุดสุ่ม 0.5-1.0 วิ (10-20) แล้วกำแพงโผล่ทันที (ห่างบอส 10, off) - วาดได้แค่ทั้งเลน = false; shrouden 2 = optic blast: server ห่าง fx 2.49 (AOE 2 + ตัว 0.5) แต่บน Predictive ตัวเรานำไป ~0.6 ลำแสง (_land at_thing) lead แล้ว (LeadMovingRaw) แต่ไม่พอตอนมันเร่ง 8-12/วิ เลยดูห่าง 3.0 - ไม่ใช่ลำแสงกว้าง (ไม่มี pre3); daywalker 1 (on, 2.14, age 2.5); moonmaw 2 = ลาวาวง (ไม่แก้) |
| 13 | UM deerclops (MakeStrong) uppercutcombo จังหวะ 2: ตอนนี้วางจากตัวมันแล้ว (ตัด follow) แต่วงยังไกลเกิน ~3 (sim พุ่ง ~10.7, จริง ~7.6 จากเฟรม 60) - พลาด 1 / 26 (618.367 share078) | ต้องปรับรูปที่ 70 ให้ใกล้ขึ้น 3 หรือรัน sim ใหม่ด้วยความเร็วจริง |
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
