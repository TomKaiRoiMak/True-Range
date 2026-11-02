# 08 · สถานะปัจจุบัน — เวอร์ชัน 1.1.6 (อัปเดต 2026-10-30)

[← สารบัญ](README.md)

> **กติกาของหน้านี้**: มีแค่งานที่ยังเปิด + ตัวเลขล่าสุด, งานละ 1 บรรทัด. ปิดงานแล้ว = ลบบรรทัดออก (รายละเอียดอยู่ใน `git log` ตาม template ปัญหา/สาเหตุ/แก้/วัด/ค้าง). ประวัติก่อนหน้า: [history/29_status-2026-10.md](history/29_status-2026-10.md)

## ตัวเลขล่าสุด (baseline)

| วัด | ค่า | เมื่อ |
|---|---|---|
| replay เต็ม หลังงาน 2026-11-02 (ท่าพุ่ง Eye/Twins, เลเซอร์, Klaus, Bee Queen, twister) | UM host 17 / 59,546 · false 1,362; client 26 / 59,507 · false 2,107; TE host 15 / 25,717 · 421; client 11 / 25,709 · 594 | bench 1604 / 0556 replay 2026-11-02 |
| replay -HazOnly หลังกับดัก walrus / มือ usher / turtle / มะพร้าว (8d3cc15) | UM host 17 / 59,547 · false 1,396; client 29 / 59,507 · false 2,138; TE host 15 / 25,717 · 421, client 11 / 25,709 · 594 - ไม่มีอะไรถอย | bench 1604 / 0556 replay 2026-11-02 |
| bench ทุกมอน ใหม่ (โค้ดหลัง 5d745e1) + replay | host missed 17 / 59,547 · false 1,411; client 29 / 59,507 · false 2,153 (things host 687 / client 1,424 - client ราว 2 เท่าเหมือน 0433; worm_boss 97 / 250, groundpoundring_fx 87 / 225) | bench 2026-11-01_1604 |
| bench ทุกมอน (271, 3 รอบ) เกม 761239 + replay | host missed 20 / 58,304 · false 2,017 → 1,367 (runner lots 221e52b; BENCHMOVED_FALSE 390 ช่วง แยกออก; hit arc); client missed 35 → 34 / 58,311 · false 2,503 → 1,888 (hit arc ด้วย) ←เดิม 2,352 (runner lots 221e52b; things 1,510 → 1,115 หลังแยก BENCHMOVED_FALSE 395) (daywalker pounce 7 = ไม่แก้; replay CLIENT แก้ tell ช้า d34decb+) | bench 2026-11-01_0433 (testbench ใหม่; 0741 หลังแก้: 14 / 2,159 · 24 / 3,122) |
| bench TE (170 ตัว, testbench ใหม่) + replay -TE | host missed 55 → 15 / 25,717 · false 1,515 → 421; client 53 → 11 / 25,709 · false 1,581 → 594 (ปลา + twister ด้วย) (replay ใหม่หลัง 946d035/298208d) (ของ 47 / 46 → 3 / 2 หลัง replay_haz รู้จักวงสปินของ hulk) | bench 2026-11-01_0556 (0611: 36 / 2,036) |
| lag บอสหลัก 15 ตัว | NOT 7 / 1,495 (on 3/638, off 4/857) · false 60 · AG2 2, moonmaw 2, shrouden 2, daywalker 1; minotaur / stalker 0 / 84 | lag 2026-10-31_1354 + 1441 (เดิม 0407: 10 / 1,008) |
| lag มอนทั่วไป 20 ตัว | NOT 3 / 546 (on 3/267: rook 2, walrus 1; off 0/279) · false 4 | lag 2026-10-31_1450 (เดิม 0448: 4 / 529) |
| lag TE (-TE ปิด UM) | NOT 0 / 90; wildboreking NOT 0 / 102 (on 44, off 58; false 9 / 22); tigershark, mandrakeman, spider_tropical, snake NOT 0 / 79 · false 0 (wildbeaverguard ตีแค่ 2 - item 10) | lag 2026-10-31_0706, 1029, 2026-11-01_2213 |
| lag มอนที่ไม่เคยลง lag (UM 8 ตัว) | claywarg, crawlinghorror, junkrat NOT 0; stageusher มือ NOT 39 / 391 → 11 / 402 (lead ตามทิศมือ) · false 0; slurper false 10 = headslurpmiss ของ bench (เราบล็อกทุกครั้ง); bishop_nightmareb ไม่มี prefab, beeguard_seeker / monkey ไม่ตี | lag 2026-11-02_0133, 0209 / 0227 (A/B) |
| lag มอนที่ไม่เคยลง lag (ชุด 2-4) | buzzard, chest_mimic, lunarfrog, merm_lunar, teenbird, bee, bulletbee, fruitdragon NOT 0 / 242 · false 0; TE crocodog, poisoncrocodog, frog_poison, rabid_beetle, weevole, zeb NOT 0 / 285 · false 1; TE ancient_herald NOT 1 / 262 · false 9 (state attack ค้าง t=0.033 ~0.6 วิ ก่อนตีที่ 0.667); birchnutdrake / stalker_minion2 ไม่ตี | lag 2026-11-02_0247, 0300, 0306 |
| lag TE ชุด 5 + spiky turtle กลิ้ง | adult_flytrap, panda, snake_amphibious, swordfish NOT 0 / 82; spiky_turtle_tfc NOT 15 / 71 → 3 / 72 (วาดท่ากลิ้ง) · false 0 | lag 2026-11-02_0329, 0349 / 0354 (A/B) |
| lag ชุด 6-8 | bight NOT 0 / 23; TE bear, flup, giantsnow, spider_snow, spiderb2, trapslug, gnat NOT 0 / 130; TE treeguard NOT 2 / 5 (item 16); TE piggolem, pigman_minion, pinkman, snapdragon, terrorbeak NOT 0 / 96; hatty_piggy_tfc NOT 2 / 54 (เรานำ 0.5-0.76 ที่ขอบ) · false 0 ทุกชุด | lag 2026-11-02_0400, 0404, 0425 |
| lag Klaus ท่ากัดใหม่ (d2e1d90) | NOT 0 / 387 · false 1 เทียบตัวเดิม 0 / 375 · 1 (bench ไม่วิ่งหนีท่ากัด - log ผู้เล่น false 7 → 0) | lag 2026-11-02_0838 / 0850 |
| lag UM walrus ปากับดัก (หลังวาดจุดตก) | NOT 0 / 38 · false 0; กับดักโดน 1 ครั้ง วาดที่จุดตก 0.4 วิก่อน (ห่างจุดจริง 0.1) | lag 2026-11-01_2222 |
| เกม / ข้อมูล | 761239 / data `83852BF58E33` | ติดตั้งแล้ว |

## กำลังทำ

| งาน | สถานะ |
|---|---|
| ของที่เพิ่มคืนนี้ วัดในเกมแล้ว | goat / trepidation / สุนัขสายฟ้า / Spazmatism / jellyfish / mindweaver / fuelseeker / haunt / moonpig NOT 0 (lag 0347-1006); Wixie NOT 1/43 on, 1/36 off (lag 1114, ทางลูก volley 7 เส้น - เดิม 7/47, 4/38); เหลือ: toadling spawner ทำเกมล่ม (Invalid Prefab ของ UM - ห้ามใส่ใน lag), fissure ต้องมี arena |

## รอเจ้าของตัดสิน

| งาน | ทางเลือก |
|---|---|
| UM Retinazer (twinofterror1) เลเซอร์ปาก mouthshoot_loop: ครึ่งหนึ่งของรอบ (bench 0433 31/63, lag 0813 17/33) เลเซอร์ไม่มาทางเรา - ที่จริงออกตาม rot ตอนเริ่มแต่ละรอบ (SpawnLaser ที่ TimeEvent 0 ก่อน ForceFacePoint; lag 0813 2790.367 rot 120.4 = เลเซอร์ 120.4, 2790.633 166.1 = 166.1) หันได้ ~40° ต่อรอบ - เดิมเขียนว่าทิศคงที่ ผิด; ตอนนี้วาดเลนไปหาเรา = false 31 (share065) แต่ตัวเลเซอร์จริง (eyeofterror_laser fx) ก็วาดอยู่แล้ว | ก) คงไว้ ข) ไม่วาดเลนของท่านี้ ให้ fx วาดอย่างเดียว (เตือน 0-19 เฟรม, 2 จุดแรกไม่มีเตือน) ค) (เสนอ) เลนตาม rot ตอนเริ่มรอบ ล็อกไว้ทั้งรอบ - เจ้าของกำลังดูเอง 2026-11-02 |

## งานเปิด (เรียงตามความสำคัญ)

| # | งาน | ข้อมูลที่มี |
|---|---|---|
| 2 | ของที่ client replay ยังพลาด (haz_missed 13 → 11 หลัง 946d035) | stageusher_attackhand 2 = client lead (เรานำไป 3 เฟรม หนีออก, บนจอห่างมือ 2.9 / server 1.9); glacialhound_icespike 2, guardian_goo 2, um_fire_projectile, sporecloud (3.30), um_bear_trap (0.11), magma_sludge, mortarball, charlie_boss_minion1 - อย่างละ 1 |
| 10 | TE ที่เหลือ: wildbeaverguard brain ทำ action ไม่มีเป้า (actions.lua:1742 error, server ไม่ล่ม, ได้ฉากครบ); rookwater ในทะเลไม่ขยับตอนพุ่ง (bench); Hulk ตายแล้ว server ค้าง (dropparts ของ TE) - beetletaur / goddess_deer_gem bench วิ่งได้แล้ว (setup ใหม่, bench 1816/1820) | ไม่ใช่ของเรา ยกเว้นจะทำ setup ให้ bench |
| 12 | NOT ของ lag 1354 (7 / 1,411) | AG2 2 = รางหนาม atk_spike หยุดสุ่ม 0.5-1.0 วิ (10-20) แล้วกำแพงโผล่ทันที (ห่างบอส 10, off) - วาดได้แค่ทั้งเลน = false; shrouden 2 = optic blast: server ห่าง fx 2.49 (AOE 2 + ตัว 0.5) แต่บน Predictive ตัวเรานำไป ~0.6 ลำแสง (_land at_thing) lead แล้ว (LeadMovingRaw) แต่ไม่พอตอนมันเร่ง 8-12/วิ เลยดูห่าง 3.0 - ไม่ใช่ลำแสงกว้าง (ไม่มี pre3); daywalker 1 (on, 2.14, age 2.5); moonmaw 2 = ลาวาวง (ไม่แก้) |
| 15 | Eye/Twins พุ่งจากเดิน: ตัดสินทางที่เฟรม 14 (ร่างตา) / 27 (ร่างปาก) - f41d61f; เลนกลับด้าน 13 เฟรมแรกของ charge_pre ยังรู้ไม่ได้ (lag 0657) | ร่างตาเล็งถึง 11 แล้วหันกลับทางเดินหรือค้าง - รู้ได้จากเฟรม 12 |
| 16 | TE treeguard: ตอนปา (โหมดระยะไกล) DoAttack ดาเมจ 0 ที่เฟรม 25 = struck ไม่เจ็บ ไม่วาด; มะพร้าววาดจุดตกแล้ว รัศมี 4 (lag 0455: ห่างจุดจริง 0.1 / 0.4) แต่ lag 0455 / 0500 ไม่มีลูกไหนโดน | ต้องมี lag ที่โดนมะพร้าวจริงถึงจะวัด NOT ได้ |
| 17 | TE firetwister attack ตีเป้าจาก 12 (SetRange 6, 12) - NOT 3 ที่ 12.1-12.4 (lag 0820) จาก 76 ที่เกิน 9 | ขอบ ไม่แก้ตอนนี้ |
| 18 | TE twister วงดูด: NOT เฉพาะ pred=1 (lag 0956: 4, 1013: 2; pred=0 0 ทุกรอบ) - ตอนถูกดูด client ทำนายตัวเราค้างที่เดิม (lead) นอกวง 20.5 ส่วน server ลากเข้า 3 ([tr_aggrotrace]: วงเปิดตลอด vacuum_loop) | ข้อจำกัดการวัด/Predictive ไม่ใช่การวาด |
| 4 | กะพริบเล็กที่เหลือ (frame_check, lag 1042; lag 1354: 185 จุด เดิม 243 - wagboss_missile JUMP 19 / REVERSE 25 = lead เปิดทันทีตอนเร็วเกิน 1.5 แล้วปิดตอนชะลอ แบบ bearger_boulder; AG3 attk_swipe JUMP 3.62 = ไปจังหวะกวาดที่ 2 (เฟรม 59), bearger ground_pound 6.0 / 2.2 = ส่วนของท่าเอง ไม่ใช่กะพริบ) | Eye REVERSE เล็ก, Klaus POP 1, AG1 2, lunarrift roll JUMP 2; bearger_boulder JUMP 27 = lead เปิดทันทีตอนเริ่มกลิ้ง (ข้อแลกเดิม); gestalt projectile JUMP 20 = โซนข้างหน้าวางใหม่ 1.4 ครั้งเดียวก่อนหมด; AG2 spin_pst JUMP ~1.04 ครั้งเดียวตอนจบสปิน (replay client 67 - ตรงเกณฑ์ 1 พอดี, วาดทาง legs ไม่ใช่ Draw/DrawTable); web_mortar JUMP 11 (lag 1334) = ย้ายจากรอบตัวไปจุดตกครั้งเดียวตอนเริ่มตก; bigshadowtentacle AIM 14 |

## ตัดสินแล้วว่าไม่แก้
- UM Bee Queen ลูกน้อง shooter: ไม่วาดเลนตอนง้าง, เลนเหล็กไน 4 (เจ้าของ 2026-11-02 "บังจอ") - 66f5a90; TE twister วงดูด 20.5 (เจ้าของเลือก) - 66f5a90

- UM shadow Wes ลูกโป่งวาดตลอดอายุ (false 46) - เจ้าของ: คงไว้ เตือนตลอด (2026-11-02)
- UM catcoon ขู่ (hiss) ถูกวาดเป็นท่าตะครุบ (pounce_pre) - anim เดียวกัน (taunt_pre, taunt) มีเป้าเหมือนกัน แยกได้แค่ตอนเริ่มตะครุบ (ช้า 0.77 วิ); เห็นแค่ตอนบังคับ (bench -Force 146 เฟรม), lag 0914 ไม่ขู่เลย - เลือกเตือนเร็ว (2026-11-01)

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
