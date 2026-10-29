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
| 1 | ~~bench เต็มบนเกม 760178 + replay~~ ✔ | 2026-10-28: missed **22** / 56,675 (บอส 6, ของ 16), false 1,901 — ดีที่สุดที่เคยวัด ; baseline ใหม่ = run ล่าสุด `_shares` ของ 28 ต.ค. บ่าย |
| 2 | ~~ลาวา moonmaw "กระโดด 1 แล้วกลับ"~~ ✔ | 2026-10-28: ต้นเหตุ = ลาวาไถลชะลอตอน stab_pre, lead โผล่ตอนเบรกแล้วหาย; แก้: ท่าที่ข้อมูลอยู่กับที่ ล็อกจุดหน้าสุด (ไม่ถอย) `TR_OLD_STAYLEAD`. lag: jumps 13/10 -> 0 (`tools\lag_jumps.ps1`), NOT drawn 7 -> 3; replay client ทั้งชุด missed เท่าเดิม |
| 3 | ลาวาวง moonmaw NOT drawn 2–6/รอบ (คุณอยู่ขอบนอกของส่วนที่วาด) | 2026-10-28 (lag 1446): 3 / 459 ครั้ง (0.65%) ทุกครั้ง 2.76–3.00 จากลาวา; เกมตี `FindEntities(r=2.2)` ทุก .15 s รอบลาวาที่วิ่งวนเร็ว → ตำแหน่งที่ client เห็นช้า ไม่ใช่รูปผิด. ไม่แก้ (ขยายวงจะได้ false ทุกรอบ) |
| 4 | ~~หนอน: ท่อนหนามตีตอนโผล่จากกองดิน~~ ✔ เจ้าของตัดสิน 2026-10-29: ไม่แสดงวงรอบกองดิน ("ไม่ทำดาเมจ จะแสดงทำไม") — 2 ครั้งที่ท่อนโผล่+ตีเฟรมเดียวกันยอมรับว่าเตือนไม่ได้ | lag_worm6 (1658): 5 โดน — ground pound ที่ 3.28 วาดคลุม ✔ ; 2 ครั้ง "NOT" = ท่อนโผล่+ตีเฟรมเดียวกัน (ผู้เล่นไม่ได้อยู่ในวงใด 16–32 s ก่อนหน้า). เตือนได้ทางเดียวคือแสดงวงรอบกองดินตลอดที่ลำตัวเลื่อนผ่าน — ซึ่งเจ้าของขอเอาออกเมื่อ 28 ต.ค. ("วงนอกที่ไม่ทำดาเมจ") → **รอเจ้าของตัดสิน** |
| 4b | ~~ท่าพุ่งที่ระยะจริงต่างจากข้อมูล (นอกจาก Klaus)~~ ✔ ดูแล้ว: daywalker atk3 = ถึงเป้า (กรองแล้ว); rneskeleton/boulder_crab = บอสยืนตี, path ในข้อมูลไม่ใช่การเคลื่อน, replay ไม่เปลี่ยน (crab 399/399) | `tools\went_table.ps1` บน 1610: sporehound jump_atk_loop 4 → 0.24 (74 ครั้ง), rneskeleton atk 7 → 0.06, boulder_crab atk 3 → 0.07, daywalker atk3 5.95 → 4.85 — `TR_OLD_WENT` เรียนให้เองถ้ากัดครั้งเดียวและสม่ำเสมอ; ยังไม่ได้ดูทีละตัวว่าทำไม sim ได้ระยะต่าง. sporehound (IDLEDRAW 104 / false 71): ✔ ไม่ใช่บั๊ก — 74 ครั้งทันทีหลัง testbench ย้ายหมา (`[tr_bench] moved`), 30 ครั้งคือช่วง taunt หลังลงพื้น ซึ่งท่ารวมเมฆสปอร์ที่ปล่อยตอนลง (`again_anim=sporecloud_loop`, ตีซ้ำได้ 705 เฟรม) = คำเตือนเมฆ; "went 0.24" เพราะท่าเริ่มนับตอนกระโดดไปแล้ว. หมายเหตุ: replay_haz ไม่แน่นอน (log เดียวกัน missed 1–2 สลับกัน) |
| 4c | ~~Klaus พุ่งเต็มไม่มีเป้า พลาดที่ 57.2~~ ✔ | `ebe8428`: path index ผิด 1 เฟรม + Klaus ออกตัวช้ากว่า sim 1 เฟรม → วางจากจุดเริ่ม; log ผู้เล่น missed 0 |
| 4d | Umbral เลเซอร์ (ผู้เล่นรายงาน 2026-10-29 "หลังใช้ laser มีเฟรม hitbox ขึ้นแถวผู้เล่น") | lag 0549 `[tr_lagframe]`: ทุกครั้งที่เริ่ม optic_blast_pre1 (5/5) รูปจำลองยาว 7-20 ขึ้น 1 เฟรม — client รู้ท่าก่อนอนิเมชันมา, `_land` ไม่จับ จึงตกไปวาดรูปจำลอง → `TR_OLD_LANDFIRST` ไม่วาดจนกว่าอนิเมชันมา. ลำเลเซอร์แบบกว้าง (5) วาด 2.5 เพราะ client พลาด anim pre3 สั้น ๆ: 2 โดน 3.7 → อ่าน net `wide` ของลำเอง `TR_OLD_WIDENET`. รอ lag bench ยืนยัน |
| 4e | UM icehound / firehound `quickattack` (postinit SGhound.lua 416): atk_pre ช้า .3 นาน 24 เฟรม แล้ว IceSpike (แนวหนาม 15/25 ทุก 2 หน่วย 30/s ไปทางเป้า) / ShootFire — ข้อมูลมีแค่ hound atk_pre (กัดใกล้) | replay CLIENT: glacialhound_icespike missed 11 (host 0 เพราะ host วาดหนามเฟรมที่เกิด). ต้องแยก quickattack กับ attack (ทั้งคู่ atk_pre) — ระยะเป้า / timer quickspike; ยังไม่ทำ |
| 4f | ท่าจาก UM postinit ที่ไม่มีในข้อมูล (คลาสของ 4e + Bearger shoot `0eccd3e`) | `tools\um_postinit_gaps.lua <UM folder>` 2026-10-29: 16 state ของมอนสเตอร์ — um_deerclops icespiketoss, Leif snare/summon, koalefant chargeattack/stomp, Beefalo chargeattack, pigbunny charge_attack, merm karate, hound howl_attack, shadowcreature terrorattack/taunttp, powdermonkey action, beeguard stab/shoot_pre/charge, beequeen spawnguards_seeker_quick. ทำทีละตัว บอสก่อน |
| 4g | ความต่อเนื่องของรูปทุกเฟรม (`tools\frame_check.lua`, ผู้เล่นขอ 2026-10-29) | lag 28-29 ต.ค.: ✔ Blighted Rock Master dash รูปไป 7-9 หน่วย 1 เฟรม 8/8 = LEAPSHORT ใช้ก้าววาร์ป 9.73 เป็นความเร็ว (`TR_OLD_LEAPWARP`, replay bjump 70 -> 0). ✔ Umbral วงลำเลเซอร์ไป-กลับทุกเฟรม = ตำแหน่ง 15 ครั้ง/วิ ซ้ำทุกเฟรมเว้นเฟรม (`TR_OLD_LEADDUP`; รุ่นแรกนำหน้าของที่หยุดจริงต่อ - Eye 0 -> 6 พลาด, แก้แล้ว: ซ้ำนานเกิน 2.5 เฟรม = หยุด). ✔ ยืนยันใน lag 0822: Rock Master เงา 26 dash ไม่มีผิดปกติ, W.A.R.B.O.T. leap 11-15 หน่วยหาย (LEAPWARP เดียวกัน). ✔ minotaur quick leap เฟรมแรก (body lead ตอนเพิ่งหยุด, `TR_OLD_STARTLEAD`): AIM 21 -> 1 (lag 0901). ✔ Umbral วงไปโผล่ 3-16 หน่วยตอน pre1 -> pre2 (`TR_OLD_THINGWAIT`/`THINGNEW`): POP 3 -> 0. Umbral วงลำเลเซอร์ก้าวยาว-สั้นสลับ: LEADSTOP2 (ก้าวเฉลี่ย 2) ลองแล้ว Moonmaw ลาวาพลาด 1 -> 12 (lag A/B, พลาดตอน lead ปกติ .4-.8 = จริง) -> ปิดเป็นค่าเริ่ม; ✔ Moonmaw pred=1 NOT 15 (lag 1230, โค้ดเดียวกับ 0945 ที่ได้ 0/78) = lag กระตุก: 8 ครั้ง client นำ server 3.6 หน่วย, 6 ครั้ง 1.2 -> lag_report มีคอลัมน์ `(ahead N)` (NOT drawn ตอนนำเกิน `AHEAD_D`=2); LEADHOLD ลองแล้ว replay แย่ลง -> ถอด; ✔ `TR_OLD_CHASELEAD` (ของที่ไล่ตามไม่เช็กความสม่ำเสมอ) REVERSE 2 -> 0. ✔ Eye/Twins "POP" ใน charge = ตัวบันทึกนับ PutTri ผิด (ไม่ใช่ภาพกะพริบ) แก้ tr_lagjoin แล้ว. ค้าง: Eye charge_pst สลับรูปทุกเฟรม (ดูด้วย [tr_lagnote]), phase1_lunarrift roll ขยับทีละช่วง 4.7 (bjump 200), shadowthrall_mouth bjump 509 client. replay: bench_replay นับ wobble + bjump แล้ว |
| 5b | ✔ ท่าที่ state เริ่มด้วยอนิเมชันคนละตัว (สุ่ม/ตามระยะ) | `3d42a24` Bearger butt_pre_R (ครึ่งหนึ่งของ butt slam ไม่เคยวาด), `8a468d6` Shadow Runner "attack" ไกล; `tools\twin_check.ps1` บน 1610 ไม่เหลือตัวอื่น |
| 7 | replay โหมด client (CLIENT=1) | ✔ บอส missed 55 -> 16 (`TR_OLD_POSEGO`: ท่าซ้ำติดกัน client ผูก pose ของครั้งก่อน), ของที่ปล่อย 79 -> 56 (`0e34a5b`) -> 36 (icespike ไกลของ Deerclops: ตัวนับ BYTHING ไม่เช็กท่าบอส `9d07941`) -> 27 (wagboss_missile 11 -> 0: `burst` วาดนำหน้าตามความเร็ว `TR_OLD_BURSTLEAD`); ที่เหลือ: sporecloud_toad 5 (host ก็พลาด, ผู้เล่นที่ขอบ 3.50 หลัง testbench ย้าย), spat_bomb 3, spiketrail 3, stageusher hand 3, อื่น ๆ 1-2. mutatedbearger combo1 (host) = ขอบครึ่งวง 87°/90° และผลสลับตามจุดเริ่ม replay (ค่าที่เรียนจากประวัติ) — ไม่แก้. บอส client ที่เหลือ: vault_pillar_guard attack2 = บอสไถลซ้อนตัวผู้เล่น (0.92) แล้วฟิสิกส์ดันกระตุก (artifact), stageusher hand = ขอบวงขณะผู้เล่นเดินออก. false client: sandspike 89 -> 622 ช่วง (981 -> 1615 เฟรม) = ผู้เล่นใน testbench ถูกหนามดันกระตุก ~0.9/เฟรม ช่วงแตกเป็น 1 เฟรม — artifact. `tools\haz_missed.ps1` = รายการของที่พลาดแบบที่ตารางนับ. ที่เหลือ 16: shadowthrall_hands run 3 = เป้าหายตอนเริ่มท่าเพราะ testbench เพิ่งย้ายตัวผู้เล่น (artifact ของฉาก); shrouden teleport_pst 3 -> 0 (`TR_OLD_R2FROM`: วงกว้าง 3.85 วาดตั้งแต่โผล่ ไม่รอเฟรม 26); อื่น ๆ ครั้งเดียว |
| 5 | บอสพลาดที่เหลือ 6 / ~56,000 (1610) — ทีละ 1 ครั้ง | ดูแล้ว 2: mutatedbearger combo1a (พุ่งสั้นชนตัวผู้เล่น วงตีครึ่งวงอยู่ไกลเกิน), vault_pillar_guard attack3 (โดนหลังบอสหลังมันพุ่ง 5, ข้อมูลเลือก run 1.5 ทั้งที่เป้า 6). ที่เหลือ: rocky_boss_shadow dash_attack, rneskeleton attack, twinofterror1 mouthcharge_loop, mutatedbearger combo1 — ความสำคัญต่ำ |
| 6 | ท่า NEVER (bench บังคับ state) | bench บังคับ 69 บอส (2026-10-28_1637): NEVER 109 → 73, replay missed 12 / 13,944 — ท่าที่ได้ทดสอบใหม่วาดถูก ; pigman charge_attack 1 พลาด = บังคับเข้า state ท้ายท่าตรง ๆ (ในเกมมาหลัง charge_pre/loop เสมอ) ไม่ใช่บั๊ก. แมงมุม (SetStateGraph ในนิพจน์) หาได้แล้ว: bench บังคับ 9 บอส (1651) missed 2 / 2,505 — ทั้งคู่ `trapdoor_attack` ที่ถูกบังคับตอนหันผิดทาง แล้วหันกลับ 100° กลางพุ่ง (ในเกมออกจากรูโดยหันหาเป้าแล้ว — น่าจะเป็นผลของการบังคับ ยังไม่ยืนยัน). (2026-10-28 เย็น: never_force จับครบ 11 บอส, bench บังคับ 1818: 1,864 ครั้ง missed 2 -> 0 หลังแก้ butt_pre_R; NEVER เหลือ beeguard stab_pre = อนิเมชันตอนบินลง ท่าแทงจริงคือ stab_pst ที่ทดสอบแล้ว, stalker attack1 = กิ่งรองของ attack ที่ทดสอบแล้ว 12 ครั้ง; stalker spike บังคับในร่างถ้ำทำเกม crash - ร่างนี้ไม่มีทางทำท่านี้) เดิม: 11 บอส (knight joust, shadow_knight, stalker spike, beeguard stab_pst ฯลฯ) state เลือกอนิเมชันจากตัวแปร ; การบังคับ state ของ Mutated ใส่ Deerclops ปกติทำ server ล่ม (ตัดออกจากไฟล์บังคับ) |

## หลังปล่อย 1.1.6 (ตกลงกันแล้ว)

- แยก `simmoves.lua` / `predict.lua` เป็นโมดูล (เพดาน 200 local)
- ลบสวิตช์ `TR_OLD_xxx` ที่ครบอายุ (ดูกติกาใน `VERIFY_PLAN.md`)
- พิจารณาโหลดข้อมูลตามบอสที่เจอ (lazy) — วัดแล้ว 93 ms / 30 MB ยังไม่เร่ง

## ล่าสุดที่ทำ (28 ต.ค.)

Umbral: วงเตือนไม่กระพริบ, laser วาดที่ beam จริง · Ink Blight: จุดตกนิ่ง · git + .gitignore · install ตรวจ patch notes / เวอร์ชันเกม / ท่าเขียนมือ · เอกสารชุดนี้
