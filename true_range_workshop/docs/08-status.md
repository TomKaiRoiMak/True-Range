# 08 · สถานะปัจจุบัน — เวอร์ชัน 1.1.6 (อัปเดต 2026-10-28)

[← สารบัญ](README.md)

> หน้านี้คือ "บอร์ดงาน" — อัปเดตเมื่อปิด/เปิดงาน รายละเอียดการแก้แต่ละครั้งอยู่ใน `git log`

## ตัวเลขล่าสุด

| วัด | ค่า |
|---|---|
| replay baseline 0805 (โค้ดปัจจุบัน) | missed **25** / 59,086 (บอส 6, ของที่ปล่อย 19) · false 2,019 |
| bench เต็มล่าสุด 1503 | missed 35 / 59,697 — A/B ยืนยันว่าไม่ใช่ถดถอย |
| lag bench (shrouden + wings) | NOT drawn 0–2 ต่อรอบ, วงเตือนกระพริบ 0 |
| Ink Blight จุดตกขยับ | 0.01 ครั้งต่อลูก (เดิม 0.84 → LANDSTOP 0.13 → + รอ 7 ค่า/hold .4 = 0.01) |
| โหลดข้อมูลในเกม | 93 ms, ~30 MB Lua memory |

## เกมอัปเดต 760178 (2026-10-27) — ✔ ตรวจแล้ว ไม่ต้อง rebuild

- [x] แตกโค้ดเกมใหม่, `game_scripts_um`, `anim_lengths.lua` ใหม่
- [x] diff: 106 stategraph เปลี่ยน แต่ไม่มีท่าไหนเปลี่ยนเฟรม/ความเร็ว/ระยะ (เพิ่ม knockback ; ระยะ "สวนกลับ" shrouden 16→20, charlie 8→14 ; horns spitout +3)
- [x] `tools\data_game_version.txt` = `760178` (เหตุผลอยู่ในไฟล์และ commit `a9efe7b`)

## งานค้าง (เรียงตามความสำคัญ)

| # | งาน | สถานะ / ข้อมูลที่มี |
|---|---|---|
| 1 | bench เต็มบนเกม 760178 + replay เทียบ baseline | ยืนยันอีกชั้นหลังอัปเดต |
| 2 | ลาวา moonmaw รูป "กระโดด 1 แล้วกลับ" (~6 ครั้ง/รอบ) | ลอง ease-in และ grow แล้วแย่ลง (ปิดไว้) ; ใช้เส้นทางจากข้อมูลไม่ได้ — `moonmaw_lavae.stab_pre` มี `path = "0.00"` (sim ไม่ได้จับการพุ่ง เพราะความเร็วมาจากตัวบอส) → ต้องให้ sim จับการพุ่งก่อน |
| 3 | ลาวาวง moonmaw NOT drawn 2–6/รอบ (คุณอยู่ขอบนอกของส่วนที่วาด) | ตอนนี้ `[tr_lagframe]` มี `ext` แล้ว วิเคราะห์ต่อได้ |
| 4 | หนอน: วัดฝั่ง client เพิ่ม | testbench เริ่มฉากหนอนได้แล้ว (2026-10-28) — รันรอบยาวขึ้น |
| 5 | บอสพลาดที่เหลือ (ขอบ < 1 cell, testbench artifacts) | catcoon, rocky warp dash, vault_crawler, twins charge, stumpling — ดูประวัติ |
| 6 | ท่า NEVER (bench บังคับ state) | `never_force.ps1` หา state ได้ครบแล้ว (รวม UM postinit ที่ชื่อไฟล์ไม่ตรง) — รอ bench บังคับรอบใหม่หลัง bench เต็ม 760178 ; บาง state บังคับแล้วยังไม่ตี (mock_dragonfly taunt, snapper speen_pst, wagboss taunt) ต้องดูทีละตัว |

## หลังปล่อย 1.1.6 (ตกลงกันแล้ว)

- แยก `simmoves.lua` / `predict.lua` เป็นโมดูล (เพดาน 200 local)
- ลบสวิตช์ `TR_OLD_xxx` ที่ครบอายุ (ดูกติกาใน `VERIFY_PLAN.md`)
- พิจารณาโหลดข้อมูลตามบอสที่เจอ (lazy) — วัดแล้ว 93 ms / 30 MB ยังไม่เร่ง

## ล่าสุดที่ทำ (28 ต.ค.)

Umbral: วงเตือนไม่กระพริบ, laser วาดที่ beam จริง · Ink Blight: จุดตกนิ่ง · git + .gitignore · install ตรวจ patch notes / เวอร์ชันเกม / ท่าเขียนมือ · เอกสารชุดนี้
