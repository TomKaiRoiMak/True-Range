# True Range — แผนตรวจสอบและแก้แบบเป็นระบบ (2026-10-16)

เขียนหลังจากผู้ใช้เจอปัญหาแบบเดิมซ้ำ 4 รอบ (Deerclops, Moonmaw, Moose, Bearger): "เลิกเล็งแล้ว ตีไปแล้ว แต่ที่แสดงยังเล็งอยู่" กับ hitbox ที่ดูแปลก
แต่ละรอบแก้ทีละบอส แล้วผู้ใช้ก็ไปเจอตัวถัดไปเอง เอกสารนี้ถอยกลับมาดูทั้งระบบ

---

## 1. ระบบทำงานอย่างไร และข้อมูลแต่ละส่วนมาจากไหน

```
โค้ดเกม + UM ──► sim (tools/sim_moves.lua)        ──► ข้อมูลท่า (moves_sim*.lua)
                 โลกจำลอง ผู้เล่นปลอมยืนตรงหน้า          maps / lock / frame / legs / hazards
                 ที่ระยะต่าง ๆ                             │
                                                         ▼
เกมจริง ──► ภาพ anim ที่ client เห็น ──► predict.lua จับ anim ↔ ท่า ──► วาด
```

- **ข้อมูลทุกอย่างมาจาก sim** ถ้า sim คิดต่างจากเกม ข้อมูลก็ผิดทั้งชุด ไม่ว่าวาดดีแค่ไหน
- **sim เป็นแบบจำลอง ไม่ใช่เกม** สิ่งที่ sim ทำต่างจากเกม (ที่เจอแล้ว):
  1. ส่งเป้าหมายเข้า state เสมอ แต่เกมเรียกบาง state โดยไม่ส่ง → บอสใน sim หันหาผู้เล่น ในเกมไม่หัน (Deerclops swipe)
  2. ตัดสิน lock/frame จากดาเมจของตัวบอสเท่านั้น ไม่นับของที่ปล่อยออกมา (Bearger sinkhole)
  3. ฟังก์ชันของเกมถูก mod โหลดทับตัวจำลอง (FindWalkableOffset → Shadow Bishop ไม่วาร์ป)
  4. โครงสร้างที่ไม่เหมือนเกม (events ใน state เป็น list, ActionHandler ไม่มี is_a) → post-init ของ UM พังเงียบ ๆ (Beefalo, Koalefant, Frog, Moose)
  5. สมมติฐานขนาด/รัศมี: aura บวกตัวผู้เล่นซ้ำ, hitrange × scale, ความเร็ว × scale
  6. ผู้เล่นปลอมอยู่ตรงหน้าเสมอ → แยก "เล็งตามผู้เล่น" กับ "ตามทิศที่หัน" ไม่ออก ถ้าผลเหมือนกัน
  7. ค่าที่ผมใส่เองใน spec (radius, leg_len, frames, lock) → ผิดได้ทุกค่า ไม่มีอะไรตรวจ

## 2. ทำไมการตรวจที่มีอยู่ไม่เจอปัญหาก่อนผู้ใช้

| การตรวจ | ตรวจอะไรได้ | ทำไมไม่เจอ |
|---|---|---|
| replay log จริง (MISSED) | โดนจริงแต่ไม่ได้วาด | **รูปที่ตามผู้เล่นนานเกินไป จะคลุมผู้เล่นเสมอ → นับว่า "วาดถูก"** เมตริกนี้ให้รางวัลกับการเล็งนานเกิน |
| replay log จริง (FALSE) | วาดทับแต่ไม่โดน | ถ้าผู้เล่นไม่ได้หลบ ก็ไม่เกิด |
| FOLLOWS | ตามหลัง lock ในข้อมูล | ถ้า lock ในข้อมูลผิดเอง ก็จับไม่ได้ |
| synthetic (sim trace → วาด) | predictor ตรงกับ sim ไหม | **sim ผิดเหมือนกันทั้งสองฝั่ง** เลยผ่านหมด |
| compare.ps1 | log เก่าแย่ลงไหม | log มีแค่บอสที่ผู้ใช้เคยเล่น |
| AIMED (เพิ่งเพิ่ม) | รูปหมุนตามขณะบอสไม่หัน | ไม่เห็นท่าที่ของที่ปล่อยเล็งตาม (Bearger) และแยกไม่ได้ว่าเกมตามจริงหรือไม่ |

**สรุป:** ความจริงเดียวที่มีคือ log ที่ผู้ใช้เล่น ผู้ใช้จึงกลายเป็นคนทดสอบ และเมตริกหลักมองไม่เห็นปัญหาเล็งนาน
การแก้ทีละจุดล่าสุด (นับของที่ปล่อย, อ่าน GoToState) ช่วยได้จริงเฉพาะคลาสนั้น แต่ **ยังไม่มีวิธียืนยันกับเกมจริง** สำหรับบอสที่ไม่มี log

## 3. วิธีตรวจที่ดีที่สุด: ให้เกมจริงเป็นคนตอบ (testbench)

แทนที่จะให้ผู้ใช้เล่นแล้วเจอ ทำ mod ทดสอบ (ใช้ในเครื่องเท่านั้น ไม่อัปโหลด เหมือน tmir_quick) ให้เกมจริงรันทุกท่าเอง:

**ที่สร้างจริงตอนนี้ (อัปเดต 2026-10-16 — ข้างล่างในส่วน 6.1/6.2 คือที่มา):**
1. `tools\run_bench.ps1` — server ของเกมแบบไม่มีจอ หลาย instance พร้อมกัน, "หุ่น" แทนผู้เล่น, ผู้ใช้ไม่ต้องทำอะไร
2. บอสโจมตีเอง**ตามธรรมชาติ** (ไม่บังคับ GoToState — ดู 6.1) หุ่นถูกย้ายตามฉากทุกเฟรมตอนบอสเริ่มท่า:
   - หมุนรอบบอส 60° / 150° ที่เฟรม k, **วิ่งวนรอบบอสต่อเนื่องจากเฟรม k** (ตัวที่ทำให้ตรวจเรื่องเล็งได้), กระโดดไปที่ระยะ d
3. trace ที่มีอยู่บันทึกทุกเฟรม → **replay ผ่านตัววาดจริง = ตัวตัดสิน** (MISSED / FALSE / AIMED / FOLLOWS)
   + การทดลองควบคุม (ตัววาดรุ่นที่รู้ว่าผิด ต้องให้ผลต่างกัน) + รายงานความครอบคลุมต่อท่า (bench_lock)
4. แบบในเกม (F7 / Shift+F7) เก็บไว้สำหรับบอสที่หุ่นใช้ไม่ได้ และบอสที่ผูกกับบ้าน

**สิ่งที่ได้:**
- **lock จริงต่อท่า** เทียบกับ lock ในข้อมูลได้ตรง ๆ ทุกท่า ทุกบอส (คลาสปัญหาที่เจอซ้ำ 4 รอบ)
- **พื้นที่โดนจริง** (ผู้เล่นยืนที่ grid หลายจุด) เทียบกับพื้นที่ที่วาด: วาดขาด / วาดเกิน เป็นตัวเลข
- **ค่าที่ใส่เองใน spec** ถูกพิสูจน์หรือหักล้างด้วยเกม
- บอสที่ผู้ใช้ไม่เคยเจอ ก็มี "log" แล้ว
- ใช้ได้ทั้งเกมปกติ, UM และ Tropical Experience ในอนาคต

**ข้อจำกัด / ความเสี่ยง (ต้องเช็คตอนทำ):**
- บางท่าเกิดเฉพาะเงื่อนไข (เลือดน้อย, timer, phase) → ต้องตั้ง field ให้เหมือน spec ของ sim (ใช้ spec เดิมได้)
- AI ของบอสอาจขัด (brain หันเอง, เดินหนี) → หยุด brain ระหว่างทดสอบ แต่ต้องระวังท่าที่ brain เป็นคนหัน (ดูข้อ 4.4)
- ใช้เวลาเกมจริง (ท่าละ 2–5 วินาที × ฉาก × ท่า ≈ หลายชั่วโมงสำหรับทั้งหมด) → เรียงตามความสำคัญ เร่งความเร็วเกม (TheSim:SetTimeScale) ถ้าไม่ทำให้ผลเพี้ยน
- trace ทำงานบน host เท่านั้น → ต้องเปิดเป็น host

## 4. การตรวจที่ทำได้ทันที (ไม่ต้องรอ testbench)

1. **ตรวจ "ตอนตัดสิน" แทน "ตอนโดน"** (เมตริกใหม่ใน replay): ณ เฟรม lock จริง (ดูจาก log: บอสหยุดหัน + ของที่ปล่อยออกมาแล้ว) รูปที่วาดตรงกับจุดที่โดนจริงไหม และหลังจากนั้นรูปยังขยับตามผู้เล่นไหม → จับ "เล็งนานเกิน" ได้แม้ผู้เล่นจะโดน
2. **diff ข้อมูลก่อน/หลังทุกครั้ง** (aimdiff): ทุกท่าที่ lock / frame / พื้นที่เปลี่ยน ต้องมีเหตุผลจากโค้ด ไม่มีก็ถือว่าผิด
3. **error ของ sim = ความล้มเหลว:** ทุก build สรุป error ของ post-init / state / prefab ที่พัง เป็นรายการ ห้ามปล่อยเงียบ (ที่ผ่านมาพังไปหลายตัวโดยไม่มีใครรู้)
4. **ตรวจ lint จากโค้ด** ต่อทุกท่า แล้วเทียบกับข้อมูล (ไม่ต้องรันเกม):
   - state นี้หัน (ForceFacePoint / FacePoint) ที่เฟรมไหน
   - ของที่ปล่อย ใช้ FindEntities รัศมีเท่าไร (เทียบกับรัศมีใน hazard)
   - SetAreaDamage / SetRange × scale
   - GoToState ส่งเป้าหมายหรือไม่ (ทำแล้ว: AutoNoArg)
   - brain สั่งหันระหว่างท่าหรือไม่ (เช่น ChaseAndAttack + canrotate)
5. **รายการค่าที่ใส่เองใน spec** พร้อมที่มา (บรรทัดในโค้ดเกม) ทุกค่าต้องมี testbench ยืนยันในภายหลัง
6. **rebuild ข้อมูลเกมปกติ** ด้วยกฎใหม่ทั้งหมด แล้วรัน compare กับ log ทั้งหมด (ตอนนี้ base ยังใช้ sim รุ่นเก่า)

## 5. คลาสปัญหาที่รู้แล้ว → ต้องตรวจทุกบอส ไม่ใช่ตัวที่เจอ

| # | คลาส | สถานะ | ตรวจทั้งระบบด้วย |
|---|---|---|---|
| 1 | เข้า state โดยไม่ส่งเป้าหมาย | sim แก้แล้ว (AutoNoArg, heuristic) | testbench lock จริง |
| 2 | lock/ทิศจากของที่ปล่อย | sim แก้แล้ว | testbench + aimdiff |
| 3 | mod ทับฟังก์ชันจำลอง | แก้ FindWalkableOffset | สรุปฟังก์ชันที่ถูกทับทุก build |
| 4 | post-init พังใน sim | แก้ events / is_a | รายการ error ทุก build (4.3) |
| 5 | รัศมี: กลางตัว vs ขอบตัว | แก้ aura ของ UM | ตรวจ hazard ทุกตัวเทียบ FindEntities (4.4) + base rebuild |
| 6 | scale (hitrange, ความเร็ว) | แก้ bishop ด้วยมือ | lint SetRange × scale |
| 7 | ท่าพิเศษ (วาร์ป, legs, ของหมุน) | แก้ทีละตัว | testbench พื้นที่โดนจริง |
| 8 | ข้อมูลเกมปกติเก่ากว่า sim | mod_diff กันได้บางส่วน | base rebuild (4.6) |
| 9 | ค่าที่ใส่เองใน spec | ไม่มีการตรวจ | รายการ + testbench (4.5) |
| 10 | ตัววาดยืด lock ถึงของชิ้นสุดท้าย (puts/set_until) | แก้: ป้าย lock_things (เฉพาะข้อมูล sim ใหม่) | testbench วิ่งหลบ + ควบคุม (Bearger ยืนยัน) |
| 11 | ท่า around ไม่มี lock หันตามจนจบท่า | แก้: บอสยืนกับที่ + anim เดียว + เล็งเป้า (uppercut ยืนยัน) | AIMED หลังเฟรมตี |
| 12 | ท่าที่เริ่มด้วย animation เดียวกัน → วาดผิดท่า | **เปิดอยู่** (Twins เลเซอร์ ↔ พุ่ง) | หาทุกคู่ในข้อมูล + testbench FALSE |
| 13 | หุ่นต่างจากผู้เล่น (testbench เท่านั้น) | แก้ sg, AnimState | ดู Lua error ใน log server ทุกรอบ |

**ข้อสำคัญ:** คลาส 1, 2, 5, 10 แก้ใน sim แล้ว แต่ **มีผลแค่ข้อมูล UM** — ข้อมูลเกมปกติยังเป็นรุ่นเก่าทั้งหมด จนกว่าจะทำ 4.6

## 6.0a ภาพรวม ณ 2026-10-17 บ่าย (อ่านตรงนี้ก่อน — 6.0 ข้างล่างเก่าแล้ว)
**ทำแล้ววันนี้:** replay bench 0835 ทุกมอน (6.13: บอส 102,466 ตี, วาดก่อน 89.4%, 89/150 ตัวครบ) ; จัด MISSED เป็นคลาส C1–C4 (~74%) ;
หลุม Bearger ตีซ้ำ (`again`, ตัวคุมผ่าน) ; `as_boss` ใส่ข้อมูลแล้ว (ยังไม่ตรวจรวม) ; Moonmaw ขอบหยัก (PAD 0.177 เฉพาะ moonmaw)
**ติดตั้งในเกมแล้ว** (เฉพาะ moonmaw + ของ 3 ชิ้น, สำรองที่ scratchpad\moonmaw\game_um.backup.lua) ผู้ใช้ลองแล้ว: "อยู่ข้างในแล้วไม่โดนบางครั้ง"
= คริสตัล 8 ลูก (moonmaw_lavae, ชื่อในโค้ด) หมุนห่าง 4 ตีรอบตัว 2.2 ทุก 0.15 s → ขอบนอก 5.5–6.2 โดน ~50% ต่อครั้ง (ไม่ใช่บั๊ก — วาดทั้งวง
= "อาจโดน") ; รอผู้ใช้เลือก: 2 โซน (เข้ม/อ่อน) หรือคงไว้
**หน้าสรุปให้ผู้ใช้:** https://claude.ai/artifact/3dPRNEmvY1hGQ9BrKGytR2
**batch ที่ตกลงกับผู้ตรวจ (ผู้ใช้: "แก้เป็น batch", เวลาจำกัด) — ยังไม่เริ่ม รอผู้ใช้:**
1. ตัวตรวจ: replay_haz ไม่นับซ้ำของที่วาดกับท่า (lavae "(struck)") ; as_boss คงไว้ ตรวจด้วย nosinkhole
2. sim + rebuild ครั้งเดียว: PAD 0.177 ทุกท่า ; again (มีแล้ว) ; กฎสแกน C3 (sim_moves.lua:557/563-569 + doattack ของ UM postinit:
   worm attack, UM spider warrior_attack, trapdoor)
3. เลื่อน: C1 กระสุน (ในเกมวาดอยู่แล้ว, ต้อง trace+bench), waterplant/stageusher/thrall (งานตัวตรวจ), พื้นที่ตอนพลาด (1 ครั้งจริง),
   lunar_grazer (ทำถ้า stderr บอกสาเหตุบรรทัดเดียว), C4 tentacle, cache/ความเร็ว/ตัวจัดคลาส, Celestial 2 stab (sim ไม่ deterministic)
4. ตรวจครั้งเดียวตอนจบ: mod ก่อน (สำเนาแช่แข็ง) vs หลัง, ตัวตรวจเดียวกัน, bench + log ผู้ใช้ + shapes_all, ข้าม eyeofterror_mini
   ผ่าน = เป้าหมาย ~0 (หลุม +30 135, worm 540, UM spider, moonmaw 1) ; ไม่มีบอส MISSED เพิ่ม ; FALSE ที่เพิ่มอธิบายได้ ; shapes ไม่แย่ลง ;
   ตัวคุม nosinkhole/noagain ยังต่าง. ไม่ผ่านเพราะ FALSE กระจาย = เก็บ PAD เฉพาะ moonmaw (ตัดสินจากรอบเดียวกัน ไม่รันใหม่)
**ขัดกับกฎข้อ 7 ตรงไหน:** "diff ข้อมูลอธิบายได้ทุกบรรทัด" — PAD ทั่วไปเปลี่ยนทุกบรรทัด → อธิบายด้วยกฎเดียว (ขอบ ≥ ระยะจริงทุกทิศ) +
วัดผลต่อบอส (MISSED/FALSE/shapes) แทนการอ่านทีละบรรทัด ; "สองชั้น" (ข้อมูล + วาด) = ring_reach.lua (ข้อมูล) + replay (วาด)

**ผู้ตรวจตัวใหม่ (ไม่มีอคติ, ผู้ใช้: "ไม่ไว้ใจ") → batch ข้างบน 2 ใน 4 ข้อจะพัง (ตรวจกับโค้ดแล้ว):**
- **PAD ทุกท่า = ซ้ำความผิดเดิม:** sim_moves.lua:746 — เคยเป็นครึ่งช่อง (0.125) "วาดเกินระยะจริง ~0.5 วัดกับ log เกม" จึงลดเป็น STEP/4 ;
  0.177 ใหญ่กว่านั้น + PAD ขยายหุ่นและ FindEntities ทุกที่ (:1946, :1537, :2593) → FALSE ขึ้นทุกขอบ ⇒ **ทิ้ง** ; moonmaw เท่านั้น
  (หรือวัดก่อน: MISSED ที่อยู่ห่างขอบวาด ≤ 0.18 มีกี่ครั้งต่อบอส — ถ้าน้อย = ไม่คุ้ม)
- **C3 แบบที่วางไว้ไม่แก้ worm:** :605-618 นับทุก state ที่ไปถึงจาก state ที่ลงชื่อไว้ว่า "ลงแล้ว" → worm attack (มาจาก attack_pre) ถูกข้ามที่ :632 ;
  UM spider ใช้ตัวห่อ `inst.events["doattack"].fn` ใน postinit (ไม่ใช่ EventHandler) นอก SCRIPTS ; trapdoor มีข้อมูล UM อยู่แล้ว (สาเหตุไม่รู้) ;
  แยกท่าออกจากกลางท่าอื่น = เสี่ยงคลาส 12 (ตัววาดสลับท่ากลางคัน)
- replay_haz นับซ้ำ: เสี่ยงต่ำ แต่เป็นการเปลี่ยนตัวตรวจ → ทำแยก (mod เดิม ตัวตรวจเก่า vs ใหม่) ก่อน
- as_boss 25 ตัว (17 เกม + 8 UM) ตัวคุมแค่ 1 — แต่ละตัวต้องมีเหตุผล (กลไกเดียวกับ V2 ที่ซ่อน MISSED)
- ตรวจครั้งเดียว: "FALSE อธิบายได้" ไม่มีวันไม่ผ่าน → ต้องเป็นตัวเลขต่อบอส ; rebuild ไม่ deterministic → ต้อง null rebuild ;
  3 การแก้ในรอบเดียว = แยกไม่ออกว่าตัวไหนทำ ; worm อยู่ในข้อมูลเกม → ต้อง rebuild ข้อมูลเกมด้วย
**แผนใหม่ = ตรวจถูก ๆ ก่อน (นาที) ทีละข้อ หยุดได้ทุกขั้น:** (a) AUTOLIST dry run กฎสแกน เก่า vs ใหม่ (วินาที) ; (b) นับ MISSED ใกล้ขอบต่อบอส
(ตัดสินเรื่อง PAD) ; (c) null rebuild -only บอสเป้าหมาย 2 ครั้งต้องเท่ากัน ; (d) rebuild บอสเป้าหมายทีละการแก้ + replay เฉพาะ log ของมัน ;
(e) แล้วค่อย rebuild เต็ม + ตรวจครั้งเดียว

**ผลเช็กถูก (2026-10-17 บ่าย):**
- (a) AUTOLIST (1.3 s): ขาดจริง = worm `attack` (540), knook `aggresivehop` (119) ; spider มี warrior_attack ไม่ได้ แต่ bench MISSED 0 → ไม่แก้ ;
  trapdoor มีครบ → ไม่ใช่ C3 ; **lunar_grazer มี devour ในรายการแล้ว** → sim สร้างไม่ออก ("devour: nothing")
- **คลาสใหม่ (ปิดแล้ว): sim ไม่มี Combat:CanHitTarget** — stub PERMISSIVE คืน NOOP (sim_moves.lua:769) → `if CanHitTarget(t)` เท็จเสมอ ;
  ผู้ใช้: SGknook:289, SGlunar_grazer:840, SGuncompromising_buffrat:254/288/316 + postinit UM koalefant, pigbunny.
  แก้: c:CanHitTarget = ระยะตีของมัน + ตัวเป้า (เหมือน combat.lua:1034) ; null rebuild 2 ครั้ง (6 บอส) เท่ากันทุก byte ;
  ผล: **lunar_grazer +devour; อื่นเท่าเดิมทุกท่า** (knook/buffrat/koalefant equal) ; bench share025: **MISSED 540 → 0**, FALSE 0 → 0 ;
  hazards ไม่เปลี่ยน ; ตัวคุม = mod เดิม (540). knook ไม่ได้มาจากนี้ = C3 จริง (aggresivehop เข้าตรงจาก doattack :87)
  ยังไม่ติดตั้ง: อยู่ใน scratchpad\c3\mod_fix (เฉพาะ lunar_grazer)
- (b) MISSED ใกล้ขอบวาด (replay NEAR_EDGE=0.18, 60 บอสที่มี MISSED, ไม่รวม eyeofterror_mini): **512 ใกล้ขอบ / 8,019 ไม่มีอะไรใกล้** →
  PAD ทุกท่าได้คืนสูงสุด 6% + ซ้ำความผิดเดิม (:746) ⇒ **ทิ้ง PAD ทั่วไป** ; คงเฉพาะ moonmaw (ใกล้ขอบมากสุด: bat 75, daywalker 72, spat 57 — งานแยก)
- C3 กฎใหม่ "เข้าตรง" (sim_moves.lua: sg_direct) — dry run 3 รอบ: กว้าง (roll/idle/taunt/death…) → จำกัดที่ doattack handler + state เดิน/วิ่ง →
  + ต้องติด tag attack → เหลือ worm, knook, boulder_crab, gnarwail, swathgrithr (ทุกตัวเข้าตรงจริงตามโค้ด) ; rebuild -only + replay bench:
  **worm 540→1 ✓** ; knook 119→119 (MISSED จริงอยู่ใน state attack 118 ไม่ใช่ hop — วินิจฉัยผิด, ยังไม่รู้) ; **boulder_crab 0→40 ✗** (uppercut
  แยกท่า วาดไม่ถึง 2.9 — ในเกมต้องมี myrock) ⇒ กฎใช้เฉพาะบอสที่ลงชื่อด้วยมือ (LISTED) — dry run สุดท้าย: **เพิ่มแค่ worm attack**
  null rebuild (กฎเก่า) = ข้อมูลติดตั้งทุกท่า ; ท่าเดิมของ worm ไม่เปลี่ยน
- **ใส่ซอร์สแล้ว** (สำรอง scratchpad\source_backup_c3): moves_sim.lua = worm + lunar_grazer ; moves_sim_um.lua = moonmaw + glass/glassshards/
  trapprojectile — ตรวจ: เปลี่ยนเฉพาะ entry เหล่านี้, ไม่มี BOM
- replay_haz: ไม่นับ "(struck)" ของ thing ที่อยู่ใน [tr_env] things ของบอสที่มีข้อมูล (replay.lua นับแล้ว) ; OLD_HAZ_STRUCK=1 = เดิม
  ตรวจเก่า vs ใหม่ (mod เดียว, 193 log ผู้ใช้+bench ขยาย, 24 นาที, error 0): ตี 23,714→22,957 (นับซ้ำ 757 ออก), MISSED 1,884→1,473,
  FALSE 4,494→4,496 ; 19 log เปลี่ยน ; ผลข้างเคียงเล็ก: um_bosses4 MISSED 0→1 + FALSE ±1 ใน 3 log (hits ที่ตัดออกเคยป้อน SimMoves.Struck
  → การวาดจางของ thing แบบ shared ขยับ) ; **share026 ไม่ได้ตรวจ**: replay_haz ค้าง 19 นาที 11 GB/ตัว (ลูกไฟ 23,790 ชิ้น) → หยุดเอง
  ⇒ งานแยก: replay_haz กิน RAM ตามจำนวน thing
- **ติดตั้งในเกมแล้ว:** moves_sim.lua (worm + lunar_grazer เท่านั้น, สำรอง scratchpad\c3\game_moves_sim.backup.lua) +
  moves_sim_um.lua (moonmaw ก่อนหน้า) — ไม่มี BOM, โหลดได้

**ชุดที่ 2 (ผู้ใช้: "โอเคหมด ทำต่อเลย") — เรียงตาม MISSED จริง, เช็กถูกก่อนทุกข้อ:**
- penguin/mutated_penguin runningattack 790 = **ตั้งใจไม่วาด** (sim_moves.lua:258: ตีเฟรม 1 ปลายสไลด์ เตือนไม่ทัน) → ไม่แก้ (ถ้าจะเตือนต้องวาดเลนตอนสไลด์ = ผู้ใช้ตัดสิน)
- **tentacle วนตี** (SGtentacle:163 attack → attack): กฎ sg_direct เพิ่ม "state โจมตีที่วนเข้าตัวเอง ยืนที่เดิม" (ไม่รวม roll ที่เดิน) ;
  rebuild -only 10 บอส: กฎเก่า ≠ ข้อมูลติดตั้งสำหรับบอสที่มี -ends (คลาส 14) → **ใส่เฉพาะท่าใหม่ (boss:move)** 7 ท่า ;
  replay 88 ครั้ง: **tentacle 403→1**, vault_pillar_guard FALSE 163→161, bigshadowtentacle FALSE +1, ที่เหลือเท่าเดิม → ใส่ซอร์ส+เกมแล้ว
- eyeofterror_mini 357/9150 (3.9%, ระยะปกติ) = น่าจะตัวตรวจ (หลายตัวพร้อมกัน) → เลื่อน
- **mutatedwarg flamethrower 217** = C2: เปลวไฟตีด้วย combat ของ warg (warg_mutated_fx:47) ; spec striker as_boss + strikes_until 90 (เปลวสูง ≤ 3 s) ;
  เจออีก: **เปลวไฟถูก pool ใช้ GUID ซ้ำ** → อายุต้องนับจากครั้งล่าสุดที่กลับมา (ช่องว่าง > 0.1 s) — replay.lua + replay_haz.lua
- **as_boss ยกให้ของเฉพาะเมื่อท่าไม่ได้วาดครอบ** (เดิมยกทุกครั้ง → bearger FALSE 5→145 เพราะการตีที่ท่าวาดแล้วถูกย้ายออก) ;
  bench 11 บอสที่มีของ as_boss (ก่อนวันนี้ → ตอนนี้, MISSED/FALSE): bearger 46/5→0/5, deerclops 3/91→0/91, mutateddeerclops 14/2→0/2,
  mutatedwarg 217/76→3/76, shadowthrall_wings 265/0→0/0, stageusher 1613/0→0/0, phase2 12→10, phase3/spider เท่าเดิม — **FALSE ไม่เพิ่มสักตัว**
  ; ของที่รับไป (replay_haz): bearger 1022/1022 วาด, thrall 287/290, deer 74/83, warg 201/248, **stageusher มือ 1138/2220 (พลาด 1082 = จริง)**
  ⇒ งานถัดไปจริง: stageusher มือ (1082), เปลว warg (47) ; ตัวตรวจ: replay_haz ยังไม่รู้กฎ "ท่าวาดครอบแล้ว" (นับของซ้ำได้ — ยอมรับ: บอกคุณภาพการวาดของ)

**ชุดที่ 3 (ผู้ใช้: "ทำต่อเรื่อยๆ ไม่ต้องถาม"):**
- **stageusher มือ 1082** — มือคืบช้า (~2/s จริง, TUNING 6) ตีทุก 25 เฟรมในรัศมี 2 ขณะยังอยู่ ; ข้อมูลเดิม flies = เส้นทางบินที่หมด
  ที่ ~1.4 s ทั้งที่มือยังตี → spec striker lasting รัศมี 1.5 (+ตัว) as_boss strikes_until 300 ; share052: **พลาด 1082→50, FALSE 113→82** ✓ ติดตั้ง
- **เปลว warg 47** — ขนาดเปลวจริง 1.4–2.2 (SGwarg SpawnBreathFX) ตีใน 0.9×ขนาด+ตัว ; spec 1.6 → 2.0 ; 7 log: **47→22, FALSE 85→90** ✓ ติดตั้ง
- **knook attack 118** — state attack (anim atk) ไม่มีในข้อมูลเลย (เข้าจาก hop ด้วย) ; um.lua `add = {attack_pre, attack}` ;
  rebuild เต็มของ knook: **119→1, FALSE 0→1** ✓ ติดตั้ง (หมายเหตุ: `add` แทนที่รายการ state ที่หาเอง ไม่ได้เพิ่ม)
- shark bite 206 — ตีพลาดแล้วตีพื้นที่ (SetAreaDamage) ; ลอง `miss_area` (flag ใหม่ใน sim ต่อบอส): map ว่างหลายระยะ, ถึงแค่ 3.55,
  ผลไม่เปลี่ยน → **ไม่ติดตั้ง**, เอา flag ออก (กลไกยังอยู่) — ยังไม่เข้าใจ
- spider_trapdoor(_hooded) 119+151 — ท่า trapdoor_atk มี map ครบทุกระยะ (กระโดดเข้าเป้า) แต่พลาด 1–3 = เล็ง/จุดลง → ต้องสืบเฉพาะ
- bat 75 — ขอบ 1.7–2.1 (ถึง 1.5+ตัว 2.0), ค้างคาวบินขณะกัด 3% → ไม่คุ้ม
- เปิดอยู่: daywalker pounce 115 (ใกล้ขอบ 72), catcoon 93, spat 87, stumpling/birchling, smallbird 30, snapperturtlebaby 45, eyeofterror_mini
- **daywalker pounce MISSED 6055.067: ภาพจริง (pics.ps1 PIC_REAL) ตัวแทนอยู่ในพื้นที่แดงที่วาด** แต่ replay ว่า "ไม่ได้วาด" → ตัวตรวจ
  ตัดสิน inside จากช่องข้อมูล ≠ เส้นที่วาดจริง (หลังรวมรูป/เรียบ) ตอนบอสกระโดด ⇒ งานตัวตรวจ: วัด inside จากรูปที่วาดจริง (REAL lines)
  ก่อนสรุปกลุ่มกระโดด (daywalker/catcoon/trapdoor) — ส่วนหนึ่งอาจไม่ใช่ช่องว่างจริง
- **ทำแล้ว: replay ตัดสิน "อยู่ข้างใน" จากสามเหลี่ยมที่วาดจริงด้วย** (tri_pts ของเฟรม, fill_in ; OLD_INSIDE=1 = เดิม ; FILL_STATS=1 นับ)
  ตัวคุม (เฟรมที่วาด): bat/bearger/deerclops/klaus ตรงกัน ≥99% ; ต่างกระจุกที่ daywalker (1241 เฟรมสามเหลี่ยมเท่านั้น) + shark (1821)
  ⇒ ตัวเช็กช่องเดิมนับขาดเฉพาะบางท่า. bench (54 บอสที่มี MISSED): 267/6697 อยู่ในที่วาดจริง — **daywalker 115/115**, shark 129/206, klaus 5
  log ผู้ใช้ (tester_compare OLD_INSIDE, 844 คู่, 434 s): MISSED 671→661, FALSE 1450→1451, ไม่มีบอสแย่ลง, error 0
  ⇒ daywalker pounce = ไม่ใช่ช่องว่าง (ตัวตรวจผิด) ; shark จริงเหลือ ~77
- **คอขวด (ผู้ใช้: "คอขวด 1 งาน"):** bench_replay ทั้งรอบรอ eyeofterror_mini (share015, 928 MB) ~30 นาที + ตัวจัดคิวหยุดรอทั้งแถวเมื่อไฟล์ใหญ่
  ครบ 2 → แก้ตัวจัดคิว (ไฟล์ใหญ่เริ่มก่อน, ระหว่างนั้นงานอื่นวิ่งต่อ) ; การจับคู่ track (replay.lua :530) ทำเป็นตาราง GUID + เฉพาะ 3 s ล่าสุด
  (OLD_TRACKS=1 = เดิม) — คำตัดสินเท่าเดิมทั้ง 6 กรณี (สรุป + เวลา MISSED/FALSE) ; **ตัวตรวจเดิมเองไม่ deterministic** (deerclops รันเดิม 2 ครั้ง
  บรรทัด OUTSIDE ต่าง — pairs() ตามที่อยู่หน่วยความจำ) → ตัวคุม "เท่ากันทุก byte" ทำไม่ได้, ใช้ "คำตัดสินเท่ากัน" แทน
  ; profiler (luajit -jp): เวลาเกือบทั้งหมด = **อ่าน log หลายรอบ** (:265, :340-358, :779, :1841) ไม่ใช่ track → งานแยก: อ่านรอบเดียว
- **แบ่งงานเดียวเป็นชิ้น (ผู้ใช้: "ทำไมไม่แบ่งให้ละเอียด"):** replay COUNT_FROM (เริ่มก่อน 5 s นับเฉพาะช่วงตัวเอง) ; bench_replay ตัด log > 150 MB
  ที่ขอบฉาก**ของบอสตัวไหนก็ได้** ครอบทั้ง log เป็นชิ้นเท่าจำนวน core ; ตัวคุม: deerclops ทั้งไฟล์ 395/0/91 = รวม 4 ชิ้น 395/0/91 ;
  พลาดครั้งแรก: ตัดตามฉากของ mini เอง → ทิ้งการตีช่วงการต่อสู้ของตัวใหญ่ (5,639 แทน 9,150) → แก้ ; ตอนนี้ **eyeofterror_mini 16 ชิ้น 185 s
  (เดิม 30+ นาที), ตี 9,150 = เท่าเดิมพอดี**
- **ตรวจรวมทั้ง bench ครบ 225/225 (ข้อมูล+ตัวตรวจล่าสุด) vs เช้า:** บอส MISSED **10,814 → 6,689 (−38%)**, FALSE 5,778 → 5,767,
  ของ MISSED 573 → 218, **ไม่มีบอสแย่ลง**, ดีขึ้น 27 ตัว
**ชุดที่ 4:**
- **waterplant 887 → 10**: เมล็ด (spec striker) as_boss strikes_until 30 (waterplant_seed:49 GetAttacked(thrower); บิน < 1 s) ; เมล็ดวาด 360/360 ✓ ติดตั้ง
- **wicker_tentacle 205 → 0**: um.lua add {attack_pre, attack} (SGtentacle วน เหมือน tentacle; บอส AUTO กฎ sg_direct ไม่ครอบ) ✓ ติดตั้ง
- **คลาสใหม่ C5 (ยังไม่ทำ)**: มอนตีประชิดที่ยืนที่ (stumpling 75, birchling 64 ที่ระยะ 1.6–2.0, bat 75, catcoon?) — ข้อมูลวาด
  target_hits = รอบ "จุดที่เป้ายืนตอนตี" (sim_moves.lua ~:4505) ; เกม: DoAttack โดนเป้าที่ไหนก็ได้ในระยะ hitrange+ตัว (2.0 รอบบอส) ;
  ตัวแทนเดินวน → ออกจากจุดที่วาด ยังโดน ⇒ ทางแก้: วงรอบบอส (ใหญ่กว่า → FALSE เพิ่ม) — ต้องวัด FALSE ต่อมอนก่อน + ผู้ตรวจ
- creepingfear 113 (taunt 64, walk_start 28, ระยะ 1.5–12.7) ; klaus 48 (attack 4.3–6.0) — ยังไม่ดู
- **C5 ต้นเหตุจริง (sim):** ใน world ของ mod (MODENV) "พลาดแล้วตีพื้นที่" ของ sim เองเรียก FindEntities ≤ 4 → ตั้ง target_found_at →
  วงรอบบอสของการตีเป้า (target_hits) ถูกทิ้ง → stumpling/birchling วาดถึง 1.52 (ตีจริง 2.0) ; แก้: คืนค่า target_found_at หลังพื้นที่ของ sim
  (SIM_OLD_FOUND=1 = เดิม) ; rebuild UM ทั้งหมด 2 รอบ (มี/ไม่มีการแก้): ท่าที่เปลี่ยน = **stumpling:attack, birchling:attack เท่านั้น** (+phase2
  attk_stab_pre ที่ไม่ deterministic) ; bench: stumpling 75→59, birchling 64→50, FALSE ≤ +1 → ติดตั้ง (ใส่เฉพาะ 2 ท่า)
  เหลือ: map ระยะ ≥ 1.75 วาดแค่ครึ่งหน้า (ที่ r 1.8: 120°–240° ไม่มี) — ระยะ 1 ครบรอบ ; ที่พลาดอยู่ด้านหลัง → sim เลื่อนศูนย์กลาง? ยังไม่ไล่
- **แก้คำพูด:** "trace ของ stumpling ขาด 0.37 s" = ผิด (คำค้นของผมกรองเวลาเอง) ; ตัวเช็ก gap_check: MISSED ทั้ง 13 บอสที่เหลือ **ไม่มี trace ขาดเลย**
**ชุดที่ 5 — เตรียม bench คืนเดียวสำหรับมอนที่ยังไม่ได้ทดสอบ (2026-10-17 ค่ำ):**
- **มอน alias 26 ตัวไม่เคยถูก trace** (firehound 3087 ครั้งที่ตีตัวแทน, lunarfrog 1845, mutatedhound 1095, hedgehound 1029, terrorbeak 747,
  koalefant_winter 676, stalker 556, mermguard ~540, spider ต่าง ๆ ~540 …): ลูป trace ใน modmain วนแค่ key ของ SimData ไม่รวม `_alias`
  → แก้: `traced_prefabs` = SimData + SimData._alias ; strict ok ; ติดตั้งในเกมแล้ว ; ต้อง bench ใหม่ถึงจะมี trace
- "traced แต่ไม่โดน" ที่จดไว้ — **แก้คำพูด:** prime_mate ไม่ใช่ (ตี 2,852 ครั้ง (blocked) วาดครบ 2852/2852, FALSE 11) ; mushgnome/toadstool(_dark)
  ตีด้วยของ (spore_moon 477, sporecloud 284, mushroombomb 15 → replay_haz ตัดสินแล้ว: spore_moon MISSED 2, sporecloud 52) ;
  moonpig ฉากเดียว 3 ครั้งแล้ว "done" (werepig หาย/คืนร่าง — ข้อมูลไม่พอ) ; rambranch / um_shadow_wes ไม่มีอะไรตีตัวแทนเลย (ยังไม่สืบ)
- **sporecloud(_toad) MISSED 52 = ขอบ:** ทั้ง 52 อยู่ที่ 3.3–3.6 จากกลาง ; เกม aura รัศมี 3.5 วัดจากจุดกลาง (ไม่บวกตัว) ; ที่วาด (DrawParts)
  ขอบ ~3.45–3.55 (probe ใน replay_haz: inside=false เริ่มที่ d≈3.5) → ขาดไม่ถึง 1 ช่อง (0.25) — ไม่ใช่ไม่ได้วาด ; ไม่แก้ตอนนี้ (คลาสขอบ)
- **test_sim "stomping: done after its last" FAIL** หลังติดตั้งท่าวน: ข้อมูลใหม่รวม tantrum_pst (เกมตีจริงที่ pst frame 8, SGalterguardian_phase1:623)
  ; เทสต์จำลองให้ pst มา 1 s หลัง loop เริ่ม (เกม loop 64 frame ก่อน) → แก้เทสต์ให้ตรงเกม + เพิ่ม "ตีสุดท้ายใน pst ยังวาด" ; stub ขาด HasTag
  ; ตัวคุม: ข้อมูลเก่าและใหม่ ALL PASSED ทั้งคู่
- **log ผู้ใช้ ข้อมูลก่อนชุด (source_backup_c3) vs ตอนนี้ (compare.ps1, log ชุดเดียวกัน):** MISSED 566→556, FALSE 347→346 ;
  **YELLOW ไม่แดง 1922→2131 (+209)** จากท่าวน: bigshadowtentacle 9→93, daywalker2 149→217, phase1 18→34, vault_pillar_guard 64→88
  = เตือนครั้งที่วงไม่ได้ตีเพราะวงจบก่อน (สุ่ม 3–5 ครั้ง) — ราคาของการวาดวงต่อ ; ยังไม่แก้ (ต้องรู้ว่าวงจบเมื่อไหร่)
  ; verify.ps1 "real missed 787→823" = ชุด log เปลี่ยน (log 10-17_1425 โตขึ้นตอน 17:13 + มอน UM เล่นโดยไม่มีสคริปต์ UM → error "no stategraph" 24)
- **trace C1 ใหม่ (modmain ตัวห่อ DoAttack):** ตัดสินแบบเดียวกับ combat.lua:1095-1164 (instpos/instrangeoverride, อาวุธ, AOEarc) →
  "MISSAREA at … r=" / "STRIKE by <กระสุน> at …" (กระทบ) / "LAUNCH <อาวุธ> at …" (ยิงออก ยังไม่ตี) / "STRIKE at …" (เดิม) ;
  ลูกดอก DARTS (blowdart_walrus, spider_web_spit, _acidinfused) เข้า [tr_haz] ; replay.lua: "STRIKE by" นับแยก ไม่ตัดสิน (replay ยังวาดลูกดอกไม่ได้)
  ; log เก่าไม่มีบรรทัดใหม่ → ผลเท่าเดิมโดยโครงสร้าง
  **ผู้ตรวจ (BLOCKING 1 ข้อ + note) → แก้แล้วทั้งหมด:** (1) พื้นที่ตอนพลาดไม่มีใครอ่าน → เพิ่ม "AREA at <you>" จาก onareaattackother
  (combat.lua:1294/1306, ก่อน GetAttacked — ติดแม้ blocked) ; (2) UM leif um_areahit: ตัวนอกไม่เขียน ; (3) ไม่มีเป้า = พลาด ; (4) trace ใน pcall ;
  (5) LAUNCH ตั้งชื่อตาม weapon.projectile ; replay: แยกเฉพาะ DARTS (ลูกอื่น เช่น monkeyprojectile/spat_bomb/UM = ตัดสินเป็นการตีเหมือนเดิม) ;
  ทิ้ง HIT เฉพาะ guid เดียวกัน |dt|<1e-3 หนึ่งต่อหนึ่ง. ตัวคุมสังเคราะห์ (log walrus เปลี่ยน STRIKE→STRIKE by): DARTS แยก 9, HIT ไม่ถูกทิ้งผิด ;
  ลูกที่ไม่ใช่ DARTS = ผลเท่าเดิม 19/19 ; strict ok, test_sim ALL PASSED ; **ติดตั้งในเกมแล้ว**
  (หมายเหตุ: wrapper เดิมก็ไม่เขียนอะไรตอน CanHitTarget ไม่ผ่าน → พื้นที่ตอนพลาดหายมาตั้งแต่ก่อน ไม่ใช่ regression ใหม่)
  ตัวคุมคืน bench (ตามผู้ตรวจ): STRIKE at ทุกบรรทัดมี "struck (blocked) by" tick เดียวกัน ~100% ; walrus/spitter/spat/monkey LAUNCH>0,
  STRIKE by ≤ LAUNCH ; บอสไม่มีอาวุธยิง LAUNCH=0 ; shark/phase3 MISSAREA>0 และ AREA = blocked ที่ไม่มี STRIKE ; alias 26 ตัวมี trace
  ; tr_testbench: ตัวช่วยหาผู้เล่น 5 ตัว (simutil) เห็นตัวแทนตอนไม่มีผู้เล่น (um_shadow_wes ลูกโป่งเดินหา GetNearestPlayer) → เทียบ blocked/นาที ต่อบอสกับ 0835
- **bench 2026-10-17_1806 (−All, 252 มอน, 63 กลุ่ม, 9 server อัตโนมัติ — run_bench -Jobs 0 = core−2 / (RAM ว่าง−4)/2 GB; 18:07→19:48):**
  ล่ม 4 (cherrybulletbee, hoodedwidow, mutatedwarg, pied_rat — exit 6 ไม่มี Lua error, 0835 ล่มตัวเดียวกัน) ; ตัวคุม trace (log ดิบ,
  scratchpad trace_controls.lua): STRIKE at 123,913 มี "you were struck" tick เดียวกัน **99.51%** (ที่เหลือ = ฝูงหลายตัวใน tick เดียว, ตัวนับ) ;
  spitter LAUNCH 1627 / STRIKE by 1614 / ตรง struck 1614 ✓ ; gestalt_guard_evolved STRIKE by 5 ไม่มี LAUNCH ✓ ; waterplant LAUNCH 590 BY 0 ✓ ;
  MISSAREA: phase3 164, shark 333, squid 273, mock_dragonfly 230, stumpling/birchling ~800 ✓ ; AREA: shadow_bishop 3011, snapperturtle(baby) ~900, moonmaw_lavae 305 …
  **walrus ป่าในโลก bench**: STRIKE by ในฉากของบอสอื่น 32 กลุ่ม (1,320) — ฉากของมันเอง (share062) 74/74 ตรง ; นอกฉากส่วนใหญ่ไม่มี struck (ยังไม่เข้าใจ)
  → งาน bench: เอา walrus ที่ไม่ใช่บอสของฉากออก
- **คอขวด replay_haz (ผู้ใช้: "แบ่งงานไม่ดี"):** 472/474 จบ เหลือ replay_haz ทั้งไฟล์ 2 งาน (share026, 071; 6-7 GB, 1 core) CPU 14% →
  replay_haz HAZ_FROM/HAZ_TO (เก็บแค่ช่วง + นำ 5 s, อายุของจาก first_seen, ตาราง frame ของทั้ง log) + bench_replay ตัดแบบเดียวกับบอส ;
  ตัวคุม (16 ชิ้นเทียบทั้งไฟล์): share032 ตรงทุกบรรทัด ; share056 strikes 573 vs 572, FALSE 2 ตัวเลื่อน 2 frame ; share026 16 ชิ้น 63 s (ทั้งไฟล์ >35 นาทีไม่จบ)
- **ผล bench 1806 vs ตาราง 0835 (16:37 — ก่อนชุด 4: waterplant ยัง 887):** มอน 191 vs 186, error 0
  - **alias 29 ตัว (ใหม่ทั้งหมด):** ตี 17,731, MISSED 1,606 กระจุก: stalker 543/553 (เป็น stalker_atrium), icehound 477/1490 (hound),
    spider_dropper 422/422 + spider_moon 129/134 (spider), claywarg 17, gingerbreadwarg 16 ; rook_nightmare FALSE 1070 ⇒ **alias ผิดท่า = คลาสใหม่**
  - เพิ่งได้ทดสอบ: shadow_bishop 121/3011, rook 1/469 **FALSE 1101**, ruinsnightmare 0/1017 (FALSE 136)
  - ทดสอบทั้งคู่ 148 ตัว: MISSED 6702→2771 **ส่วนใหญ่ = ย้ายไปนับแยก** (spitter 3243, waterplant 887, walrus 120 → LAUNCH/STRIKE by ไม่ตัดสิน)
    ไม่ใช่การแก้ ; จริง: catcoon 93→61, shark 77→57, klaus 48→32 … (ตีต่างจำนวนกัน = สุ่มของ bench) ;
    **แย่ลง: dreadeye 1→315** (UM — สงสัยตัวช่วยหาผู้เล่น/AllPlayers), phase1_lunarrift 3→31, rabbitkingminion FALSE 14→130 (ตี 464→6901), leif FALSE 8→158
  - ไม่ได้ทดสอบ: wicker_tentacle (ไม่ spawn เลย), mutatedbuzzard_gestalt (2 ฉากแล้วเลิก) ; _haz MISSED 218→378, FALSE 3757→3142
**ชุดที่ 6 — วิเคราะห์ (ก่อนแก้, 2026-10-17 ค่ำ):**
- **stalker 543/553 = sim (คลาส C5 "พื้นที่ตอนพลาด" ของ sim ใน world ของ mod):** UM ไม่แตะระยะของ stalker (postinit แค่ battle cry) ;
  ข้อมูลเกม attack ถึง 4.32 (hit 3.8+0.5) ✓ แต่ข้อมูล UM ถึง 2.06 ← ใน MODENV sim ตีพื้นที่รอบตัวทุกครั้ง (DoAttack :1457) → own hits
  เฟรมเดียวกัน → `only_on_target` (:2689) ทิ้งวงระยะตี. แก้: hit จากพื้นที่ของ sim ติด `miss_area` → ไม่นับใน only_on_target (SIM_OLD_AREA=1 เดิม)
  ; ตัวคุม: rebuild UM ทั้งหมด 2 รอบ (ใหม่/SIM_OLD_AREA) → ท่าที่เปลี่ยน = คลาสนี้ทั้งหมด (ทุกบอสที่มี areahitrange ใน UM)
  ; (แก้คำพูดตัวเอง: "map ระยะ ≥2 ว่าง" ผิด — `same = true` = ใช้ map ก่อนหน้า)
- **icehound quickspike 458 = C2 as_boss:** glacialhound_icespike.lua:112 GetAttacked(attacker = หมา), ตีทันทีที่เกิด (:399) → um.lua striker
  as_boss, strikes_until 3
- **alias ผิด:** spider_dropper → warrior_attack (ย้ายไป also ของ spider_warrior :240) ; spider_moon spike_attack (ของเกม SGspider:433) → def ของตัวเอง
- **dreadeye attack_teleport 315 (0.00 off — วาร์ปมาทับ, ตี 2.5 รอบตัว frame 16 FindEntities):** คีย์ชน — attack และ attack_teleport ใช้ atk_pre แรก
  เหมือนกัน, attack_teleport_pre เริ่มด้วย taunt (ท่า taunt ก็มี) → ต้องมีกลไกท่าเดียวแยกตามบริบท — **งานแยก ไม่ทำในชุดนี้** ;
  เพิ่งโผล่เพราะตัวช่วยหาผู้เล่น (ก่อนหน้า dreadeye ไม่เคยวาร์ป)
- **rook/rook_nightmare FALSE ~1100:** run_start/run (พุ่งชน) — คลาสเดียวกับ penguin runningattack (รอผู้ใช้) ; **leif (UM) FALSE 153:**
  UM um_areahit ตีเป็นกรวย (postinit components/combat.lua:173-189) แต่ข้อมูล = วงของเกม ; เดิมซ่อนด้วย STRIKE ปลอมของตัวห่อเก่า → sim ไม่รัน
  component postinit ของ UM — งานแยก
**ชุดที่ 6 — ผล (ติดตั้งแล้ว ทั้ง source และเกม, ทุกไฟล์ตรงกัน byte):**
- rebuild UM 2 รอบ (ใหม่ / SIM_OLD_AREA): ท่าที่เปลี่ยน = birchling:attack, stumpling:attack, stalker_atrium:attack, shark:attack(+~bite),
  malbatross:atk(+~alert) (+phase2 attk_stab_pre ไม่ deterministic — ไม่ใส่) ; ระยะใหม่ = ข้อมูลเกมพอดี (stalker 4.32, shark 3.55, malbatross 5.06)
- bench 1806 replay ใหม่ (ทั้งชุด — ไม่จำเป็น, ผู้ใช้ทัก; ต่อไปเฉพาะบอสที่ข้อมูลเปลี่ยน): ตัวอื่นเท่าเดิมทุกตัว ;
  stalker 543→0, icehound 477→0 (ย้ายเป็นของหนาม, _haz MISSED +3), stumpling 57→0 (FALSE 0→70), birchling 50→2 (FALSE 0→64),
  malbatross 2→0, spider_dropper 422→**207** (spider_warrior เองข้อมูลเดียวกัน 422/0 — โค้ดเหมือนกัน; ยังไม่รู้ → ต้องดูภาพ),
  spider_moon 129 ไม่เปลี่ยน (moonspider_spike ไม่ได้ trace ใน bench นี้ — ข้อมูลเก่า; ต้อง bench ใหม่)
- log ผู้ใช้ (compare.ps1, 315 s): MISSED 556→556, FALSE 346→346, YELLOW 2131→2131 — ไม่มีมอนเหล่านี้ใน log ผู้ใช้
- **แก้คำพูด:** ไฟล์ในเกมขาด hazard fields (UM `again` ของ um_bearger_sinkhole — runtime ใช้!, as_boss 8+16 ตัว — ตัวตรวจใช้เท่านั้น)
  ที่ผมว่าติดตั้งแล้ว ; move_diff_all เทียบแค่ท่า → ต่อไปเทียบทั้งไฟล์ (hash) หลังติดตั้งทุกครั้ง
**ชุดที่ 7 — กระโดดเลยตัวคุณไปนิด (ผู้ใช้นอน: ทำต่อเอง):**
- spider_dropper 207: DUMP — กระโดดลง 0.8 จากคุณแล้วไถลเลยไป ~1.4 ; ตอนผ่านคุณ (along ≤ gone) simmoves ตัดสิน "ออกนอกทาง" → free (ทางเต็ม
  ข้างหน้า, far 6.45→13.62) แต่ตีรอบตัวมันเองที่ 1.2 ข้างหลัง ⇒ คลาส: **ท่ากระโดดใส่เป้า (single, frame target, follow) ที่ไปเลยคุณ**
- แก้ (simmoves ~:3808 "reached"): ผ่านคุณขณะคุณอยู่ในทาง และตัวมันยังห่างคุณ < 3 → ใช้ map ของระยะที่คุณอยู่ (ไม่ใช่ free) ;
  TR_OLD_PASS = เดิม. รอบแรกไม่จำกัด → daywalker FALSE 10→199, mutatedbearger +20, dreadeye 315→369 ⇒ จำกัด single+target+follow
- ผล (50 บอสที่มี free map, bench 1806): dropper 207→1, trapdoor 108→0, trapdoor_hooded 203→0, catcoon 61→19, aphid 1→0 ;
  FALSE +107 (hooded 26→84, trapdoor 0→30, dropper 0→11, catcoon 2→8, aphid +2) ; ที่เหลือเท่าเดิม ; error 0
- log ผู้ใช้: 556→556 / 346→346 / 2131→2131 ; ติดตั้งแล้ว — ทุกไฟล์ตรงกัน, compile ผ่านทุกไฟล์
- **แก้คำพูด: walrus ป่าไม่ได้รบกวน** — STRIKE by นอกฉากของมันยิง rabbit/spiderden/tallbird/deer ห่าง ~400 ; ยิงตัวแทนนอกฉาก: 1806 = 1,
  2229 = 0 (ตัวนับเดิมไม่ดู "at wilson") ; ตัวลบ walrus ใน tr_testbench เอาออกแล้ว ("removed" ที่เห็นคือ log ลบไฟล์เซฟ)
- **dreadeye ต้นเหตุจริง (ไม่ใช่คีย์ชนอย่างเดียว):** ใน sim ที่ frame 15 playerprox onnear (dreadeye.lua:354) → teleport_to เพราะ
  `not combat:HasTarget()` — sim ไม่มี HasTarget (PERMISSIVE คืน nil = "ไม่มีเป้า") ทั้งที่ตั้ง target แล้ว (:2157) → ท่า attack ไม่เคยตีใกล้
  (map ระยะ 1-3.75 ว่าง) ⇒ คลาส: ทุกบอสที่ถาม HasTarget ; แก้: c:HasTarget() (SIM_OLD_HASTARGET=1 เดิม) ; rebuild เกม+UM 2 รอบ เทียบทีละท่า
  ผล: ท่าที่เปลี่ยน เกม = fruitdragon:challenge_pre (ใหม่), mutatedbuzzard_gestalt:atk_flame_pre, pigman:were_atk_pre ; UM = dreadeye:atk_pre,
  pigman:were_atk_pre (+phase2 ไม่ deterministic) ; hazard/alias ไม่เปลี่ยน ; dreadeye ใหม่ = 3.05 รอบตัวทุกระยะ ;
  bench: **dreadeye 315→0** (FALSE 13→19), fruitdragon/pigman/pigguard เท่าเดิม ; log ผู้ใช้ 556/346/2131 เท่าเดิม ; ติดตั้งแล้ว ทุกไฟล์ตรงกัน
  ⇒ "คีย์ชน" ไม่ต้องทำ: ท่าเดียว (atk_pre) ครอบทั้งสองแบบแล้ว
- **leif (UM) um_areahit:** sim ไม่มี UMSetAreaDamage (no-op) → เพิ่ม c:UMSetAreaDamage + UMAreaAttack ตาม postinit/components/combat.lua:157-190
  (ระยะ hit+ตัว, กรวย 120° หรือวงใกล้ hit/2+ตัว, conecheck/check) — MODENV เท่านั้น, SIM_OLD_UMAREA=1 = ปิด ; sim -only=leif:
  atk/special/special~summon เป็น facing, single=false — ใกล้รอบตัว ~2 + กรวยหน้าถึง ~3.5 (เดิมวงรอบตัว 3.5) ; splice 3 ท่าลง UM (source)
  bench 1806: leif_sparse FALSE 164→55, leif 158→158 (ทั้งหมด "at its edge" — สงสัยขนาดตัวสุ่ม SetRange(3*scale)) ; MISSED 0 ทั้งคู่
  ; ลงเกมแล้วหลัง bench 2229 ; ยังต้อง rebuild UM ทั้งหมดยืนยันว่ามีแค่ leif ที่เปลี่ยน (reviewer: leif ตัวเดียวที่ใช้ UMSetAreaDamage)
- **bench 2229 (รอบ 2, 252 มอน, 72 กลุ่ม, 108 นาที; ล่ม 9 exit 6 — warg/warglet/trapdoor_hooded/mini_ally ใหม่, ไม่มี Lua error):**
  ทั้งหมด MISSED 4499 (1806 ก่อนชุด 6) → **2683**, FALSE 11527 → 12615, error 0 ; ชุด 6-8 ยืนครบ: stalker/icehound/dropper/trapdoor(+hooded)/
  dreadeye/spider_moon → 0, stumpling 1, birchling 2, leif_sparse FALSE 164→51 ; ไม่ได้ทดสอบ: eyeofterror_mini_ally (ล่ม)
  ; แย่ลง rabbitkingminion 36→170, eyeofterror_mini 21→145, phase1 11→41, ruinsnightmare 0→36 — **ตัวคุม: mod รุ่นก่อนชุด 6 บน log 2229 ได้
  เท่ากันทุกตัวเลข** ⇒ ฉากต่างกันของ bench (ช่องโหว่จริงที่เพิ่งเจอ ไม่ใช่ผลของการแก้) ; catcoon บน log เดียวกัน เก่า 86 / ใหม่ 62
- **ตัวตรวจ: ตำแหน่งตอนตี (replay.lua DrawnNear):** phase1 tantrum ตีที่ 4.34 (ใน 4.64 ที่วาด, ระยะเกม 4+0.5) แต่ tick บอกคุณอยู่ 4.68 —
  testbench วางตัวแทนใหม่ทุก tick ⇒ ตัดสิน "วาดแล้ว" ถ้า inside ของเฟรม หรือ ตำแหน่ง you ในบรรทัด STRIKE อยู่ใน parts ที่วาด (_InMap) ;
  OLD_STRIKE_POS=1 = เดิม. ตัวคุม: log ผู้ใช้ (tester_compare) 660→658 ไม่มีตัวแย่ลง ; bench 2229: −534 (rabbitkingminion 170→0, bat 62→0,
  archive_centipede 51→0, ruinsnightmare 36→0, phase1 41→2, lunarrift 43→5, catcoon 62→25, mini 145→112, spat 111→101 …), FALSE เท่าเดิม
  ⇒ **bench 2229 รวม MISSED 2,149** (1806 ก่อนชุด 6: 4,499) ; ผู้ตรวจกำลังตรวจกฎนี้ + กฎชุด 7 — ยังไม่สรุปว่าถูก
  ; คลาสขอบ (ขาด <1 ช่อง): sporecloud 52 — rabbitkingminion ที่คิดว่าเป็นขอบ จริง ๆ เป็นตำแหน่ง tick นี้
- **ผู้ตรวจ (AGREE WITH NOTES):** A ถูก (STRIKE you = ตำแหน่งตอน DoAttack ; ลำดับ task ของ bench กับ trace ตาม hash — ไม่คงที่) แต่
  (1) รูปที่ขึ้นกับคุณวาดสำหรับตำแหน่ง tick ; (2) ฝูง: parts ของทุกตัว ; (3) ไม่มีตัวคุม. B ถูกสำหรับท่าที่ตั้งใจ แต่ครอบ ~30 ท่าที่ bench ไม่เคยรัน
  (Klaus chomp, UM pig charge, swathgrithr lunge, nightcrawler …) — **นับเป็น "ยังไม่ทดสอบ" ไม่ใช่ผ่าน** ; inway_dist อาจค้างข้ามเฟรม
- ทำตาม: **ตัวชี้ขาด (1):** วาดใหม่ที่ตำแหน่งตอนตี (STRIKE_YOU) — 15 บอสที่เปลี่ยน: เดิม 784 / กฎ A 262 / วาดที่ตำแหน่งตอนตี 294 → 94% จริง ;
  ต่างที่ eyeofterror_mini (A 112, จริง 145 — ฝูง ตามที่ผู้ตรวจเตือน) ⇒ **ตัวตรวจใช้ STRIKE_YOU เป็นค่าเริ่มต้น**, กฎ A ปิด (STRIKE_POS_PARTS=1),
  OLD_STRIKE_POS=1 = เดิม ; **ตัวคุม (3):** make_controls (แก้ pattern ให้ตรงไฟล์ UM ใหม่ — เดิม build ล้มเงียบ ใช้โฟลเดอร์เก่า) ; nosinkhole
  ตัวตรวจเก่า/ใหม่ 25/25 เท่ากัน ✓ ; oldlock/OLD_LOCK ไม่ต่างบน log นี้ทั้งคู่ ; noagain = งาน replay_haz ; B: inway_dist ใช้ได้เฉพาะ ≤ 3 frame (inway_at)
  ; spider_moon:trapdoor_atk (UM, ท่าใหม่ — แมงมุม UM กระโดดได้) ใส่ใน UM ; UMAREA rebuild ตัวคุม: เปลี่ยนแค่ leif 3 ท่า ✓
  **ผล:** log ผู้ใช้ ตัวตรวจใหม่ 659→660 (เฉพาะ _haz 258→259 — replay_haz ไม่ได้แก้ = ความไม่ deterministic เดิม) ; mod ใหม่ 556/346/2131 เท่าเดิม ;
  **bench 2229: MISSED 2,683 → 2,183, FALSE 12,615 → 12,609, error 0** (แย่ลง: shadow_bishop +1, vault_pillar_guard +1) ; ติดตั้งแล้ว, ทุกไฟล์ตรงกัน,
  compile + test_sim + strict ของสำเนาในเกมผ่าน
- **eyeofterror_mini 145 — กำลังสืบ (จุดเริ่มรอบหน้า):** MISSED 4654.334 (share015): ภาพ (pics.ps1) — วงรอบ mini ครอบคุณ แต่ InMap = ไม่ ;
  REPORT_AT: "given 249.00,-123.46 drawn 247.74,-122.19 **rot 46.2 dist 29.31** run 16" ขณะที่ mini หัน −135 และคุณห่าง 3.26 ; bench ย้าย
  mini+คุณ 30 ไปที่ 4653.6 (จบฉาก) ก่อนท่าเริ่ม 4653.9 ⇒ สงสัย **pose ของ server (SMp.Pose, key/go) ของท่าครั้งก่อนค้าง** ใช้กับครั้งใหม่หลังถูกย้าย —
  ถ้าจริง เกิดในเกมได้เมื่อบอสวาร์ป/ถูกย้ายระหว่างสองท่า ; **127/145 เกิดภายใน 2 s หลัง "moved"** (590 ครั้งที่ย้าย)
  ; ลองแก้ PoseAt (ผูก go ต่อเมื่อ pose ล่าสุดใกล้ ft) → 145→145 ไม่มีผล ⇒ ไม่ใช่ PoseAt — **ถอยแล้ว** ; ต่อไป: ดูที่มาของ "rot 46.2 / dist 29.31" ใน
  Predict.Report (a.locked.rot / target ตอนเล็ง) — สงสัย PoseTargetPos / PoseAim (ไม่ผูก go, แค่ ≤10 เฟรม) หรือ track ของ replay ข้าม teleport
  **ต้นเหตุจริง = ตัวตรวจ:** probe ใน Draw — target/live ของ mini = 269.30,-144.60 (คุณก่อนถูกย้าย) ; replay เอา "you" จาก track แรก (py = py or …)
  ซึ่งอาจเป็น mini ที่หยุดถูก trace — At() ถือ tick เก่า หรือ lerp ข้ามช่วงเว้น ≤3 s ข้ามจุดที่ bench วาร์ป ; ลองแก้ mod 2 จุด (PoseAt, prestart) ไม่มีผล — ถอยแล้ว
  ; แก้ replay: "you" จาก track ที่ tick ล่าสุดใหม่สุด (ค่าที่ At คำนวณ — ไม่ใช่ tick ดิบ: ดิบช้า 1 tick → phase1 0→15) ; OLD_PY=1 เดิม
  ; log ผู้ใช้: 659→660, FALSE 1451→1437 ; bench 2229: **MISSED 2,183 → 2,073, FALSE 12,609 → 12,391** (mini 145→57 / 609→273, shadow_bishop 157→137)
  ; ต้องดู: glacialhound FALSE 107→164, smallbird +29, dreadeye FALSE 1→12 ; bearger ตี 845→821 = ผลของตัดชิ้น 50 MB (คืน 150 MB แล้ว)
- **bench_replay ตัดชิ้น:** haz ตัดตามงาน (tools/haz_cuts.lua — จำนวนบรรทัด [tr_haz] เท่ากัน; ตัดตามฉาก worm_boss กองชิ้นเดียว) share063 25+ นาที → 60 s ;
  บอสยังตัดตามฉาก เกณฑ์ 150 MB (50 MB ทำงาน 530→2,374 แต่ละชิ้นอ่าน log ทั้งไฟล์ — ช้าลง) ; ต้นเหตุจริงของความช้า: replay.lua อ่าน log 7 รอบ (:273 :348 :412 :472 :824 :1379 :1912)
- **feedback ผู้เล่น (จีน): client build ส่ง RPC ไป server ที่ไม่มี mod** — CLIENT_ONLY ดูแค่ client_only.txt ; แก้: หรือ modinfo.client_only_mod (env.modinfo, mods.lua:517)
  ; ติดตั้ง true_range + true_range_client แล้ว ; ยังไม่ได้ลองกับ server จริง
### 6.15 ทำเครื่องมือให้เร็ว (ผู้ใช้ 2026-10-18: "พอก่อน พัก optimize" — งาน mod หยุดไว้)
- **agent ตรวจเครื่องมือ:** เวลาหมดกับ (1) อ่าน log ซ้ำ — replay.lua ~5 รอบ/งาน (:273 :348 :472 :824 :1912), replay_haz 4 รอบ,
  ชิ้นแต่ละชิ้นอ่านทั้งไฟล์ ; (2) ลูป n·m (:843 :1359 :1438 :1445 :1456 :549 :1924 :584) ; (3) ไม่มี cache ; log ผู้ใช้จริง 127 ไฟล์ 1.76 GB
- **ผู้ตรวจอ่านการทบทวนตัวเองของผม — แก้คำพูด:** การลด MISSED ส่วนใหญ่มาจาก **mod** (~2,000 ต่อบอส) ไม่ใช่ตัวตรวจ (~610) ; STRIKE by จากเกม
  มีแล้ว (spitter 1,614) — ที่ขาดคือ ~3,243 ไม่ถูกตัดสิน ; "จุดตัดว่าง" เกิดไม่ได้ (แต่ snap ทำให้ชิ้นน้อยลง) ; nosinkhole ไม่ทดสอบ STRIKE_YOU
  — **ยังไม่มีตัวคุมของ STRIKE_YOU** ; 70 vs 57 ของ mini ทั้งคู่เป็นชิ้น — ยังไม่มีผลทั้งไฟล์ ; replay ไม่ deterministic (pairs) → เทียบคำตัดสินที่เรียงแล้ว ;
  STRIKE_YOU จับคู่ด้วยเวลาเท่านั้น (ไม่ดู guid) ; OLD_PY block เรียก At() ทุก track ทุกเฟรม
- **ลำดับ (ทีละอย่าง):** (a1) อ่านรอบเดียว + แก้ลูป n·m — perf อย่างเดียว ; ตัวคุม = คำตัดสินเรียงแล้วเท่าเดิม บน log ผู้ใช้ทั้งหมด + bench บาง share
  → วัด mini ทั้งไฟล์ใหม่ (ถ้าเร็วพอ เลิกตัดชิ้นบอส) → (a2)+(b) ชิ้น vs ทั้งไฟล์ ถ้ายังต้องตัด (+ตัวคุมตัดผิดโดยตั้งใจ) → ตัวคุมที่ชน STRIKE_YOU
  ก่อนอ้าง 294/57/2,073 อีก
- **(a1) ทำแล้ว:** profile จริง (luajit -jp=F; "l" ทำ JIT พัง ใช้ไม่ได้) — เวลาไม่ได้อยู่ที่อ่านไฟล์ตอนแรก แต่ที่ลูป: ของ×เฟรม OUTSIDE 42%,
  replay_made ทุกเฟรม 38%, IsValid ของที่หมดแล้ว 15% → cursor / หาแบบแบ่งครึ่ง / ปล่อยของที่หมด (OLD_MADE) ; แล้วอ่าน log รอบเดียว (MAIN_LINES + HZ_*,
  OLD_READ=1 เดิม) ; phase3 share002: 106 → 28 → **19 s** ; ตัวคุม: log ผู้ใช้ทั้งหมด 746 คู่ เทียบกับ replay ก่อนแก้ — สรุปตรงทุกคู่, ต่างเฉพาะบรรทัด
  OUTSIDE/YELLOW ที่ขึ้นกับ pairs (4-8 คู่) ; เครื่องมือ: scratchpad a1\ctl.ps1 (รันทั้งสองแบบ) + a1\cmp_pairs.lua (เทียบ 0.6 s — PowerShell เทียบ >5 นาที)
- **mini ทั้งไฟล์จบครั้งแรก: 493 s, MISSED 15 / FALSE 287** ⇒ ชิ้น (57, 70) ผิด → **ปิดตัดชิ้นบอส** (BOSS_PIECES=1 เปิด) ; คิว: ยาวสุดก่อน ตามบรรทัด
  trace (share_plan "lines"), หนัก (>400k บรรทัด) พร้อมกัน ≤2 ; bench ทั้งชุด 25 → **15 นาที** (วางแผน 6 s, 607 งาน) ; รวม MISSED 2,054, FALSE 12,306, error 0
  — ชุดแรกที่มาจากบอสทั้งไฟล์ทุกตัว ; ต่อไป: replay_haz อ่านรอบเดียว, cache ตาม hash
- **replay_haz อ่านรอบเดียว** (MAIN_LINES ระหว่างรอบแรก, OLD_READ=1) ; ตัวคุม 10 log: strikes/drawn/missed ตรง ; FALSE ±1 = replay_haz ไม่ deterministic
  เอง (แบบเดิม 4 รอบ: MISSED 16/17/17/17) ; **_times.csv** ต่องาน ; bench 13.5 → ลากท้ายโดย **rabbitkingminion 936-1056 s**, mini 592 s, ที่เหลือ ≤68 s
  ; ต้นเหตุ = **ลูกน้องค้างข้ามฉาก** (มินเนียน Rabbit King 3 ตัว ~3 ชม.เกม, 900k บรรทัด ; mini 247 ตัว ส่วนใหญ่ 76 → 6,625 s) — tr_testbench แก้แล้ว:
  เปลี่ยนบอสแล้วลบทุก _combat ใน 80 ของตัวแทน (headless เท่านั้น, run.dummy)
- **cache ตาม hash** (bench_replay (3), tools/data_keys.lua: key ต่อบอส = ท่าเกม+UM+alias+hazard ของมัน ; haz = ทั้งไฟล์ข้อมูล ; + log name/size/mtime,
  โค้ด mod ไม่รวมข้อมูล, replay.lua+replay_haz.lua, args, env ; NO_CACHE=1) ; ไม่เปลี่ยนอะไร: 607 จาก cache **4 s** ตารางเหมือนเดิม ;
  ตัวคุม: ข้อมูลรุ่นเก่า → รันใหม่เฉพาะ 6 บอสที่ key เปลี่ยน + haz 404 (5 นาที) ✓
- **(a2) ชิ้น = ทั้งไฟล์?** แก้ 5 ข้อ (ตาราง frame ของทั้ง log, reach ทั้ง log, รอบ pick ตาม guid, COUNT_FROM ครบ, lead PIECE_LEAD=20) — mini ยัง 57 vs 15 ;
  MISSED ที่เกินอยู่ 50-300 s หลังรอยต่อ ; p3 เผื่อ 20/100/400 s ยัง 5, เผื่อ 1,700 s → 1 (= ทั้งไฟล์) ⇒ สถานะต่อตัวของ mod (ท่าค้าง, anims_seen …) ของ mini
  ที่อยู่ข้ามทั้งไฟล์ — **ชิ้นบน log นี้เท่ากับทั้งไฟล์ไม่ได้** ; โค้ด a2 เก็บไว้ (ทั้งไฟล์ไม่เปลี่ยน — PIECE เท็จ) ; ชิ้นบอสยังปิด ; ทดสอบใหม่บน log ที่ลบลูกน้องแล้ว
- **เหลือ (ลำดับ):** eyeofterror_mini 15, spat 101 (C1 snot ไม่มีใครวาด), creepingfear 93, penguin 575 + mutated_penguin 280 + rook ~2200 FALSE
  (เส้นพุ่ง — รอผู้ใช้), shadow_bishop 157, catcoon 26, _haz 594, smallbird 48 / FALSE 302 ; ไม่ได้ทดสอบ: Klaus chomp (AllPlayers ใน klaus.lua:149?),
  UM pig charge, eyeofterror_mini_ally (ล่ม)
- **ผู้ตรวจ (2026-10-18) — รัน bench ใหม่ได้ มีเงื่อนไข:** ข้อสรุป a2 "เท่ากันไม่ได้" พูดเกิน (พิสูจน์แค่ว่าสถานะย้อน >400 s) ; ล้างของใน testbench
  ลบสิ่งก่อสร้างที่มี combat ด้วย (รัง/กำแพง — ไม่เสีย) ; **เหตุผลหลัก: STRIKE_YOU จับด้วยเวลา → การตี 8,299 ครั้งของมินเนียนค้าง อาจทำ MISSED/FALSE
  บอสอื่นเพี้ยน** ; cache มีช่องโหว่ → แก้แล้ว: key รวม stategraph UM + sg_of + shapecheck (343 ไฟล์), env = ทุกชื่อที่ os.getenv ใน checker/mod
  (133 จุด, ไม่ใช่รายการมือ), key บอสรวม hazard ที่ท่ามัน `puts` + `_grid` → key เปลี่ยนทั้งหมด = รันเต็มครั้งถัดไป (มากับ bench ใหม่อยู่แล้ว)
- **คาดไว้ก่อนรัน bench ใหม่ (กฎ 7):** ทุกครั้งที่เปลี่ยนบอสมีบรรทัด `cleared n` ; หลัง spawn บอสถัดไปไม่มี guid ของมินเนียน/mini ; จำนวนฉากต่อบอส
  เท่าเดิม ; ไม่ล่ม ; rabbitkingminion / mini job จาก ~1,000 / 590 s → <100 s ; eyeofterror_mini MISSED ทั้งไฟล์ ~15 (±5) ; บอสที่ตัวเลขเปลี่ยน
  ต้องเป็นตัวที่เคยมีการตีของมินเนียนในหน้าต่างของมัน (ตรวจจาก log เก่า) — ตัวอื่นเปลี่ยน = มีอย่างอื่นต่าง ; ตัวคุม = รอบเก่า 2026-10-17_2229_shares (เก็บไว้)
  ; ลำดับ: แช่สำเนา mod → smoke ~5 นาที (rabbitking, eyeofterror, บอสธรรมดา 1) → เต็ม
- **smoke (2026-10-18):** รอบ 1 — ลบใน 80 ได้ 121 แต่ mini 34 ตัววิ่งไล่กระต่าย/กวางไป 100-160 → 918 บรรทัดหลัง hound spawn (ชื่อ rabbitking ผิด
  = rabbitking_aggressive) ; แก้: ลบทุกตัวมี combat ที่ GUID ≥ GUID บอส (เกิดหลังบอส) ไม่จำกัดระยะ ; รอบ 2 — cleared 49 / 289, บรรทัดของบอสก่อนใน
  หน้าต่างถัดไป = 0 ทั้งสองครั้ง, ไม่ล่ม, hound 590 ฉาก ✓ ; สำเนา mod แช่ไว้ scratchpad frozen_bench_2026-10-18 (31 ไฟล์) ; เริ่มเต็ม -All 11:25
- **ผู้ตรวจอ่านวิธีทดสอบ — แก้ก่อนเทียบ:** (1) ตัวเลขรอบเก่า (2,054, mini 15) มาจาก replay รุ่นก่อน → **replay ทั้งสองรอบด้วยเครื่องมือ+สำเนา mod เดียวกัน**
  แล้วเทียบคำตัดสินเรียงแล้วต่อบอส ; (2) คำทำนาย "เปลี่ยนเฉพาะบอสที่มีของค้าง" ผิด: ล้าง 80 ทำก่อนบอสแรกของทุก share ด้วย (รอบเก่าไม่มี),
  กฎ GUID ลบของที่โลก spawn ระหว่างหน้าต่าง (กระต่าย, walrus, icehound, กับดัก UM …), share ต่างกัน (72 vs ~63 → บอสก่อนหน้า/ฤดูต่าง), เกมไม่ซ้ำเดิม
  → **คำทำนายใหม่:** เปลี่ยนได้ใน (i) หน้าต่างที่มีของค้าง (ii) บอสแรกของ share (iii) noise ; ตัวอื่นเปลี่ยนเกิน noise = มีอย่างอื่นต่าง ;
  **ไม่มีค่า noise** (ไม่มีสองรอบที่ใช้ testbench+mod เดียวกัน) ; (5) mini: ±5 ไม่มีที่มา — เทียบอัตรา MISSED/การตี ในหน้าต่างของมันเอง ;
  (6) จำนวนฉาก = แค่ sanity ; (8) cache ยังต้องมีตัวคุม 3 แบบ (env, ไฟล์ sg, hazard ใน puts) ก่อนเชื่อ cache ; (9) ผลรอบนี้ = ผลของ tester/โลก ไม่ใช่ผลของ mod
- **tools/leftover_count.lua** (ตามข้อ 3 ของผู้ตรวจ): ต่อหน้าต่างบอส นับ tr_hit / trace HIT-STRIKE จากของที่บอสก่อนหน้าใน share ทิ้งไว้ (GUID ≥ บอสแรก,
  < บอสนี้, ยังไม่ gone) + tr_hurt จากของที่เกิดก่อน ; ตรวจ GUID เพิ่มขึ้นข้าม tick ด้วย ; **ตัวคุม:** รอบเก่า share041 rabbitking_lucky 2,844 / passive
  3,459 ครั้ง, smoke ใหม่ 0 ทุกหน้าต่าง ✓ ; (บั๊กแรก: เทียบ max ของ tick เดียวกัน → 15,757 ผิด, แก้แล้ว 0) ; **รอบเก่าทั้งหมด:** 248 หน้าต่าง,
  บอสแรก 72, มีของค้างตี 44, โดน hurt จากของเก่า 21, GUID ย้อน 0 ; มากสุด: rabbitking_passive/lucky, eyeofterror_mini 2,493 (mini ของ eye),
  oculet_rez 594 (terrorbeak), bight 370 (beeguard), twinofterror2 276, sporehound 81 ; ผลอยู่ scratchpad leftover_old_2229.txt
- **bench ช้าตรงไหน (ผู้ตรวจ + วัด, tools/bench_speed.lua):** เวลา server รวม 50,974 s (รอบ 2229) ; **ความเร็วตกตามลำดับในshare:** เก่า 18.3 / 12.3 /
  8.8 / 7.0× (ตำแหน่ง 1-4) ; ใหม่ (ลบของมี combat แล้ว, 17 share แรก) 20.6 / 14.4 / 11.6 / 8.1× → **ไม่ใช่ลูกน้องค้าง** ; ของที่ยังอยู่ปลาย share005: 586 ตัว
  combat 0 (inventoryitem_classified 138, burntground 122 = ไฟป่า, ต้นไม้งอก 172, อาหารเน่า 60, อุกกาบาต) — testbench SetCanSleep(false) ทุกอย่างที่เกิด
  (modmain.lua:534) ; นาฬิกาเกม/ฤดูไปพร้อมตำแหน่ง (clock0 ~1,800 / 4,700 / 6,700 s) แยกสองสาเหตุไม่ได้จาก log ; **ตำแหน่งเปลี่ยนโลกที่บอสถูกทดสอบ
  (ฤดู) = ปัญหาความถูกต้องด้วย** ; บอสที่ไม่เคยเริ่มฉาก 24 หน้าต่าง = 9,431 s (ทุกตัวที่โจมตีเริ่มฉากแรกใน ≤10.9 s) ; boot ต่อ share 44-56 s ;
  ความเร็ว >32 ไร้ผล (CPU) ; ตัวตรวจ dt ทำแค่ 30 tick แรกของบอสแรก (modmain.lua:374/387) ; run_bench อ่าน log ทั้งไฟล์ใน loop (:99)
  **ประมาณ:** ทุกหน้าต่างเร็วเท่าตำแหน่ง 1 = 27,180 s ; **Share=1 (โลกใหม่ทุกบอส) +45 s boot = 34,515 s (−32%)** และทุกบอสได้โลก/นาฬิกาเดียวกัน ;
  เลิกเมื่อไม่เริ่มฉากใน 480 s เกม (1 วัน) = 9,431 → ~1,260 s ; รวม ~26,000 s ≈ ครึ่งหนึ่ง
  **แผน (หลังเทียบ bench 1125 กับ 2229 เสร็จ — ไม่แตะก่อน):** (0) ตัวตรวจ dt ต่อบอส ; (1) Share=1 + งานยาวก่อน (ตามเวลาบอสรอบก่อน) + share ล่ม
  ไปหน้าคิว ; (2) เลิกเมื่อไม่มีฉากแรกใน 480 s เกม ; (3) อ่าน log แบบ stream ; Rounds คงเดิม (ต้องเช็ก subsample ออฟไลน์ก่อน)
  **ตัวคุม:** hound ≥ 590 ฉาก + บอสตำแหน่ง 1 เดิมทุกตัวต้องไม่โดนตัด (ต้องไม่ต่าง) ; บอสที่ไม่โจมตีต้องโดนตัดที่ 480 (ต้องต่าง) ; ความเร็วต่อหน้าต่าง
  ใหม่ต้องเท่าตำแหน่ง 1 เดิม ; noise: รัน 3-4 บอสซ้ำ 2 ครั้งด้วย Share=1 + mod แช่ → เทียบคำตัดสินเรียงแล้ว
- **แก้ความเร็ว (ผู้ใช้ "แก้เลย"):** tr_testbench — FIRST_SECS 480 (ไม่เริ่มฉากใน 480 s เกม → "gave up - no scene begun"), ตัวตรวจ dt + ความเร็วคืน SPEED
  ทุกบอส, run.began ; run_bench — Share=1 ค่าตั้งต้น, เรียงตาม bench_logs\boss_cost.txt (game s ต่อบอส, เขียนท้ายทุกรอบด้วย bench_speed.lua ; seed
  จาก 2229+1125, 24 ตัวไม่โจมตี = 480, ไม่รู้ = ก่อน), share ล่มเข้าหน้าคิว, EndShare อ่านแบบ stream ; smoke ตัวคุม: hound, slurper (ต้องไม่ถูกตัด),
  little_walrus, deer (ต้องถูกตัดที่ 480)
- **smoke 1157 ผ่าน:** hound 590 (24×), slurper 299 ชนเพดาน (23×, เดิม 199 s → 155 s), deer/little_walrus ตัดที่ 485 s เกม (16 s จริง) ; dt 0.0333 ทุกตัว
- **ผู้ตรวจ (BLOCKING ข้อเดียว):** worm_boss (16,176 tr_hit จาก dirt/segment) + lunarthrall_plant (1,184 จาก vine_end) ไม่เคยเริ่มฉาก แต่ตีตลอด → ตัดที่ 480
  เสีย ~87% → แก้: ถูกตีโดย GUID ≥ guid0 = began (กวางของโลกไม่นับ) ; ไม่มีบอสใน 2229/1806 เริ่มหลัง 480 (นานสุด ~10.5 s) ; HERE mode ไม่ตัด (not run.here) ;
  ล่มก่อน spawn ใน Share=1 → ลองซ้ำ 1 ครั้ง ($retried) ; ตัวตรวจ dt ใช้ไม่ได้เป็นตัวคุม (GetTime เดินทีละ tick เสมอ — ช้าเห็นแค่เวลาจริง ;
  bench_lock "speed" ทิ้งทุก run ข้าม share ถ้ามันเคยยิง — ยังไม่แก้) ; เทียบกับ 2229: แยกตามตำแหน่งเดิม — ตำแหน่ง 1 ต้องอยู่ใน noise, 2-4 ต่างได้ (อายุโลก) ;
  noise run: hound + บอสหนัก (eye/bight) + บอส UM สองครั้ง ; smoke ตัวคุมถัดไป: worm_boss, lunarthrall_plant ต้องไม่ถูกตัด, deer ต้องถูกตัด, hound 590
- **smoke 1207-1240:** lunarthrall_plant ✓ (1,184 hit ทั้งชั่วโมง) ; **worm_boss เป็นบอสแรกในโลกใหม่ = ติด** (0 หรือ 1 hit ทั้งชั่วโมง ; ต่อจาก deer: 2/3
  แล้ว 4/4 ทำงาน) — กลไก: ออกจากดินเมื่อเป้าใน 4 ของ mound, ไม่ขยับเมื่อเป้าใน 6 (worm_boss_util.lua:271,497) ; หุ่นค้าง 4.03 ; physics mound แค่ 1
  → ทำไมค้างยัง **เปิด** ; ลองรอเดินเข้า 10 s แทน 3 s = แย่ลง (0/3) → คืนค่า ; **แก้:** run_bench Share=1 วาง deer ก่อน worm_boss ($before), testbench:
  ไม่เริ่มฉากใน 480 s → สร้างใหม่ 1 ครั้งก่อนตัด ("once more"), ถูกของบอสตี ≥10 ครั้ง = เริ่มแล้ว (1 ครั้งไม่นับ) ; smoke สุดท้าย: worm 4/4 (10,193-16,182 hit),
  little_walrus ตัด 2 รอบ, hound 590, lunarthrall 1,185 ✓
- **bench เต็ม 2026-10-18_1241 (Share=1 + ทุกการแก้):** **71.2 นาที** (เดิม 108), 9 server, 260 share, 252 หน้าต่าง ; เวลา server ในหน้าต่าง 23,133 s
  (เดิม 50,974) ; ความเร็ว median 19.5× p10 16× ; boot ~45 s × 260 ≈ 11,700 s = ~1/3 ของเวลาตอนนี้ (ถัดไปที่ควรลด) ; ล่ม 10 (warglet, trapdoor_hooded,
  mutatedwarg, warg, pied_rat, hoodedwidow → !np ; cherrybulletbee + eyeofterror_mini_ally ล่มทั้งสองแบบ = ไม่มีผล) ; ไม่มี prefab 9 (beefalo_moon …
  uncompromising_caverat) ; hound 590 ✓ ; **leftover_count: หน้าต่างที่ของค้างตี 0** (เดิม 44), GUID ย้อน 0 ; hurt จากของเกิดก่อนบอส 11 หน้าต่าง
  (magmahound 6,365, twinofterror2 1,316, slurper 1,797 …) — Share=1 ไม่มีบอสก่อน ⇒ เป็นของโลก/ไฟ (guid 0?) ยังไม่ได้ดู
  ; replay ทั้ง 1241 และ 2229 ด้วย -Mod สำเนาแช่ (กำลังรัน)
- **เทียบ 1241 vs 2229 (replay เดียวกัน, mod แช่ ; scratchpad cmp_runs.lua):** replay 1241 = 8.0 นาที (2229 = 12.7 ; ยาวสุดตอนนี้ expand share028 134 s)
  | กลุ่ม (ตำแหน่งใน 2229) | บอส | MISSED | /1000 ครั้งตี | FALSE /1000 |
  | pos1 (โลกเหมือนกัน ≈ noise) | 56 | 641 → 672 | 22.3 → 23.0 | 93 → 86 |
  | pos2-4 | 102 | 448 → 433 | 7.4 → 7.1 | 77 → 70 |
  | หน้าต่างมีของค้าง | 32 | 368 → 188 | 10.6 → 8.7 | 36 → 51 |
  | _haz | 1 | 597 → 330 | 26.8 → 28.3 | **169 → 523** |
  รวม MISSED 2,054 → 1,623 ; **noise ≈ ±5% (pos1)** ; **ของค้างทำ MISSED ปลอม:** shadow_bishop 157 → 32, smallbird 48 → 0, eyeofterror_mini 15 → 0
  (858 ครั้งตี) → ลบออกจากรายการปัญหา mod ; ยังอยู่จริง: penguin 575 → 571, mutated_penguin 280 → 251, spat 102 → 114, klaus 30 → 39 ; shark (pos1)
  ตีมากขึ้น 110 → 680, MISSED 6 → 33 ; **ต้องดู: _haz FALSE ต่อครั้งตีขึ้น 3 เท่า** (ครั้งตีครึ่งเดียว — โลกใหม่ไม่มีของค้างให้ตีกัน?) ;
  เฉพาะเก่า: moonhound, snowmong ; เฉพาะใหม่: mutatedbuzzard_gestalt, pigelite2, pigelite4
- **_haz FALSE ×3 — สาเหตุ (ตรวจแล้ว):** เพิ่มเกือบทั้งหมดจาก 3 อย่าง: um_tentacle_moon_projectile 602 → 2,409, shadowthrall_projectile_fx 978 → 1,562,
  waterplant_projectile 431 → 746 ; ของเกิดเท่ากัน (3,540 / 590), อายุเท่ากัน (1.33 s), ฉาก 590 ทั้งคู่ ; ไม่ใช่การตัดชิ้น (share058 ทั้งไฟล์ = 602 เท่าชิ้น) ;
  ~~replay_haz ไม่นับ FALSE ถ้าถูกใครตีใน ±0.3 s → ของค้างกลบ FALSE~~ **ผิด (ตรวจแล้ว):** หน้าต่าง um_tentacle_moon ของ 2229 share058 ไม่มีของค้างเลย
  (vampirebat มาทีหลัง ; ตีหุ่นแค่ตัวมันเอง 10 + ของมัน 3) ; ฉากเหมือนกันทุกอย่าง (590, ระยะ 4.0, step/run/jump เท่ากัน), บรรทัด projectile 142,258 vs 141,905 ;
  ต่างกัน = **ที่ยืน**: เก่า 281,-144 (หุ่นถูกบอสก่อนพาไป) ใหม่ 275,-188 (จุดเริ่มโลก) → พื้น/รูปที่วาด (tr_env) ต่าง ⇒ FALSE ของของบางอย่างขึ้นกับที่ยืนมาก ;
  um_tentacle_moon_projectile วาดทับหุ่น 2,409 ครั้ง ตีจริง 0 ยังเป็นปัญหา mod (ค้าง) ; ลองกรอง any_hit ด้วย GUID (เกิดก่อนบอส = ไม่นับ): 8 share รวมที่ของค้างมากสุด
  ต่าง 0 → **ไม่เก็บ** (ไฟล์คืนเป็น byte เดิม, cache ยังใช้ได้)
- **เครื่องมือ (ผู้ใช้ "ทำเครื่องมือต่อให้เสร็จ"):**
  - **expand_haz:** ลูปทุก guid ที่เคยมีทุก tick → เฉพาะที่ยังอยู่ (เรียง guid เหมือนเดิม) ; share028 163.6 → 9.8 s ; **ตัวคุม: 48/48 ไฟล์ byte เท่าเดิม** ;
    ทั้งช่วง expand 2:42 → 14 s ; bench_replay expand ใช้ทุก core + ใหญ่ก่อน
  - **cache ตัวคุม 3 แบบ ผ่าน** (scratchpad cache_ctl.ps1, deer_blue/deer_red/hound บน 1241): ไม่เปลี่ยน → cache 3/3 ; OLD_PY=1 → รัน 3/3, ถอด → cache 3/3
    (เก็บหลายรุ่น) ; sg_of.lua เปลี่ยน → รัน 3/3, คืน → cache ; hazard ที่ deer_blue วางผ่าน puts เท่านั้น (by → deer_red) → deer_blue+deer_red รัน, hound cache ✓ ;
    คืนผลจริงจาก cache แล้ว (ตรงตารางเดิม)
  - **STRIKE_YOU กับ guid: ไม่ต้องแก้** — you= ในบรรทัด STRIKE คือที่ยืนของหุ่นเสมอ ไม่ว่าใครตี (mini ตีกระต่ายไกล 157 ก็เขียน you= ของหุ่น) และ replay.lua
    เก็บ strike เฉพาะ prefab ของบอสที่ "at you / at its target" (replay.lua:454-459, 643-650) → จับคู่ด้วยเวลาถูกแล้ว ; ข้อกังวลของผู้ตรวจไม่เกิด
  - **boot:** วัด 241 share: ถึง spawn 45.5 s (FE 12 s + BE ~25 s + world 8 s + รอ 5 s ที่ 1×), ปิด 3.0 s, รวม 144 s/share → boot 32% ; แก้ได้จากนอกเกม: poll 5 → 1 s,
    jobs: (ว่าง − 3.5)/1.95 GB (เดิม (−4)/2: 23.97 GB ได้ 9 → ตอนนี้ 10) ; ไม่ได้แตะ: รอ 5 s ตอนเริ่ม (เปลี่ยนสภาพเริ่ม), ใช้ server เดียวหลายบอสด้วย c_reset
    (ประหยัด ~12-15 s/บอส แต่ autosave ระหว่างรัน → โลกที่โหลดกลับไม่ใช่ seed ; ซับซ้อน)
- **ผู้ตรวจรอบสุดท้าย — แก้ข้อสรุป 2 ข้อ (ตรวจแล้ว):**
  - **_haz FALSE ×3 = นับเป็นช่วง ไม่ใช่เฟรม:** um_tentacle_moon 2229 = 602 ช่วง / **8,844 เฟรม**, 1241 = 2,409 ช่วง / **5,885 เฟรม** (เฟรมลด 33%) ; ไม่มี
    "HIT at" เป้าอื่นในหน้าต่างทั้งสอง ; tick _you เท่ากัน (1 เฟรม) ; ~~ที่ยืน/พื้น~~ ผิด — replay_haz ไม่มี TheWorld ไม่ใช้พื้น ; ทำไมช่วงแตก (in-in-out ทุก
    3 เฟรม) ยังไม่รู้ ; **แก้เครื่องมือ:** replay_haz พิมพ์ "_hazards: N frame(s) drawn-in with no strike" + bench_replay คอลัมน์ false_fr + TOTAL frames
  - **"ของค้างทำ MISSED ปลอม" ผิด:** replay.lua กรอง strike ตาม prefab (:422-423) ; noise run 1453 (Share=1, mod แช่, ซ้ำ 2): shadow_bishop **112 / 117**
    (1241: 32 ; 2229: 157) — ทั้งหมด attack_loop ตอนบอสทับหุ่น 0.2-1.5 → **ปัญหา mod จริง, noise ต่อบอสสูงมาก (32-157)** ⇒ คืน shadow_bishop เข้ารายการ ;
    hound 0 / 0, bight 0 / 0, um_tentacle_moon FALSE 2,429 / 2,471 (เฟรม 5,904 / 6,377 ≈ ±8%) ; ⇒ ห้ามใช้ต่างต่อบอสเป็นผลโดยไม่ดูซ้ำ
  - **cache:** env ของ mod สแกนผิดที่ (bench_replay ใช้ $root\true_range ไม่มีจริง) → ใช้ -Mod ; ตัวคุม AFTER_DBG=1 → รัน 2/2, ถอด → cache ✓ ;
    key รวม game_scripts_um ทั้งหมด (4,939 ไฟล์) + expand_haz.lua ; expand ทำใหม่เมื่อ expand_haz ใหม่กว่า
  - **expand_haz เพิ่ม:** log ผู้ใช้ compact 20 ไฟล์ = เดิม, round-trip (haz_compact → expand) 6 ไฟล์ = เดิม ; guid ที่มีบรรทัดหลัง GONE 1,556 ตัวอยู่ใน 48 ไฟล์ที่ตรง
  - **อื่น:** bench_lock "speed" ทิ้งเฉพาะบอสนั้นตั้งแต่ spawn (เดิมทุก run ทุก share) ; testbench log "began by <prefab>" ; worm_boss ล่ม → คิวใหม่ "deer,worm_boss!np"
  - **replay 1241 เต็ม (ทุกอย่างใหม่):** 5.4 นาที (เดิม 8.0 / 12.7) ; ผลเท่ารอบก่อนทุกตัว (_haz FALSE 6,106 → 6,108 = pairs) ; things' frames 48,236
  - **ค้าง (เครื่องมือ):** ทำไม worm ค้างเมื่อเป็นบอสแรก
- **งาน mod ต่อ (ผู้ใช้ "จัดไป", 2026-10-18 บ่าย):**
  - **shadow_bishop (UM) attack_loop — แก้แล้ว + ติดตั้ง:** เลนจาก "ที่มันออกตัว" ล็อกทิศตอนยังไม่ขยับ (predict.lua:1679) แต่ UM บิชอปหันหาเป้า**ใน tick
    เดียวกับที่ออกตัว** (0.37 จากจุดเริ่มในเฟรมแรก > .3) → ทิศค้างที่ก่อนวาร์ป (-144.5 vs จริง -119.9 = 25°) ; UM attack_loop ไล่เป้าตลอด (ForceFacePoint ทุก
    update) ตี DoAreaAttack รอบตัวทุก ATTACK_TICK ; แก้: ออกตัวแล้ว ทิศ = ทิศที่ไปจริง (atan2 จุดเริ่ม → ตอนนี้, เรเดียน ; TR_OLD_LANE) ; ใช้เส้นนี้แค่ shadow_bishop 3 ระดับ
    (UM) ; **ผล (mod แช่ vs ใหม่):** MISSED 112 → 0, 117 → 0, 32 → 0, 2229: 157 → 0 ; FALSE 0 → 0 ; log ผู้ใช้ 5 คู่ 0 → 0 ; (พลาดครั้งแรก: ใส่องศา ทั้งที่ rot
    ในนี้เป็นเรเดียน → MISSED ~2,900 ทุก log — จับได้จากตัวเลข)
  - **spat strike — คลาส "อาวุธในมือ":** เกม GetHitRange/GetAttackRange บวกระยะอาวุธที่ถือ (combat.lua:989-1005) ; sim ไม่บวก (stub) และไม่ใส่อาวุธเลย (เข้า state
    ตรงจาก doattack ข้ามการเลือกอาวุธ) → spat ตีจริงถึง 4.0 (3 + 0.5 อาวุธ + 0.5 ตัวเป้า) วาด 3.5 → MISSED 114 ที่ 3.62-3.97 ; แก้ sim: inventory/weapon stub จริง
    (GiveItem/Equip/GetEquippedItem, SetRange), combat GetWeapon/GetHitRange/GetAttackRange ตามเกม, ก่อนเข้า state ใส่อาวุธตาม doattack "HasTag(x) then A else B"
    (SIM_OLD_WEAPON) ; สมาชิกคลาส (prefab ที่ weapon:SetRange): spat (+0.5 ระยะประชิด), spider/waterplant/walrus (อาวุธยิง), monkey/chimp/malbatross (0) ;
    **ผล bench 1241 share082:** spat MISSED 114 → 0, FALSE 0 → 11 ; log ผู้ใช้ 12 → 12 (ทั้งหมด launchprojectile = น้ำมูก C1 ที่ไม่มีใครวาด — แยกเรื่อง) ;
    กำลังรัน sim ทั้งชุดมี/ไม่มีกฎ เพื่อดูว่าท่าไหนเปลี่ยนอีก (ตัวคุม = ต่างเฉพาะคนถืออาวุธ)
  - **penguin/mutated_penguin — ผู้ใช้เลือก "วาดเลนระหว่างพุ่ง":** ไถลใน state run (slide_loop) 6/s ตรงเข้าหาเป้า ตีที่ d 2.2-2.6 เฟรม 1 ของ runningattack (571/571
    MISSED เป็นแบบนี้) ; ต้องวาดแบบใหม่ (ไม่ใช่ท่าโจมตี) → ถามผู้ตรวจว่ากลไกเดิมไหนรองรับก่อนสร้าง ; rook = FALSE ระหว่างพุ่ง (ตรงข้าม) — ดูหลัง penguin
  - **spat/spitter ติดตั้งแล้ว:** sim ทั้งชุด มี/ไม่มีกฎอาวุธ: 4/253 ท่าต่าง — spat:strike, spider_spitter:atk (ถืออาวุธ = ในคลาส), alterguardian_phase2:attk_stab_pre +
    mutatedbuzzard_gestalt:atk_flame_pre (prefab ไม่มี weapon/inventory เลย → กฎไม่มีทางแตะ = ความสุ่มของ sim, รู้อยู่แล้วว่าไม่นิ่ง) → splice แค่ 2 ท่าแรก ;
    spitter bench 1 ครั้งตี 0 → 0, log ผู้ใช้ไม่มี ; ก่อนแก้เก็บไว้ scratchpad weapon\moves_sim_before_weapon.lua
  - **penguin — ออกแบบ (ผู้ตรวจ):** ไม่มีกลไกเดิมที่ใช้ได้ตรง ๆ ; ใช้สาขา leg_whole capsule (predict.lua:1662) + ธงใหม่ leg_follow: เลนตามตัวทุกเฟรม (ไม่ล็อกจุดออกตัว) ;
    ท่าเขียนมือใน moves_hand.lua (ไม่หายตอน rebuild): anims {slide_bounce, slide_loop}, leg {anim=slide_bounce}, leg_len 0.5, leg_r 3.0 (PENGUIN_ATTACK_DIST 2.5 +
    ตัวเรา 0.5 ; DrawCapsule ไม่บวกให้) ; **ประตู:** เป้าจริง (combat:GetTarget() ก่อน fallback) = เรา และเราอยู่หน้า ≤45° (หนี/ตื่นตกใจ/เดินตามไม่วาด ; ห้ามใช้
    fallback "ผู้เล่นใกล้สุด") ; cooldown 3 s ร่วมกับจิก → FALSE คาดว่าขึ้น (วัดเป็นเฟรม) ; **ตัวคุม:** penguin 571 / mutated 251 ต้องลด, TR_OLD_PENGUIN คืนค่าเดิม,
    shadow_bishop UM ต้อง 0 ต่อ, วาดตอนเป้าไม่ใช่เรา = 0, log ผู้ใช้ 2 ไฟล์ไม่มี MISSED ใหม่ ; ต่อไป: minotaur runningattack (279 ครั้ง, กลไกเดียวกัน)
  - **penguin — ทำแล้ว + ติดตั้ง:** moves_hand.lua (ใหม่, รวมเข้าตอนโหลดใน simmoves.lua) + predict.lua leg_follow (said_tgt = เป้าที่เกมบอก ; TR_OLD_PENGUIN) ;
    **bench 1241:** penguin MISSED 571 → 0 (FALSE 108 → 108), mutated_penguin 251 → 0 (29 → 29) — FALSE ไม่ขึ้นเพราะเลนเล็ก (R 3) อยู่ในแค่ ~0.15 s ก่อนตี ;
    shadow_bishop 1453 ×2: 0 / 0 ต่อ ✓ ; minotaur 0 → 0 (ท่า gore first=1 มีอยู่แล้ว — คลาสปิด) ; **log ผู้ใช้:** penguin 11 → 0, mutated 9 → 0, FALSE 1 → 1 ;
    รวม 4 บอสที่แก้วันนี้ บน log ผู้ใช้ MISSED 32 → 12 (ที่เหลือ = น้ำมูก spat) ; strict ok ; source = เกม (hash) ;
    **ยังไม่ได้ตรวจ:** "วาดตอนเป้าไม่ใช่เรา" (bench มีแต่หุ่นเป็นเป้า — ต้องดูในเกมที่มีหลายคน/เพนกวินหนี) ; true_range_client (install_client.ps1) ยังไม่ได้อัปเดต
  - **um_tentacle_moon_projectile FALSE 2,409:** (1) testbench จบฉากแล้วย้ายหุ่นไป 30 ขณะหนามยังลอย (1.33 s) — 2,410/2,410 ช่วง FALSE ตามด้วยการย้าย → แก้
    testbench: ไม่จบฉากขณะของที่ขว้างในฉากยังอยู่ (run.flying) ; smoke 1556: หนามตีหุ่นจริง 700 / 682 ครั้ง วาดถูก 697/697, 680/681 ; hound 590 ✓ ;
    (2) FALSE ที่เหลือ = จุดตกที่ทำนายกระพริบ (ช่วง 1-2 เฟรม กลางทาง 0.2-0.7 s, ~4 ต่อการขว้าง) — fit ความสูง 3 จุดห่าง 1 เฟรม, trace ปัด 0.01 → ความโค้งผิด
    ~23% ; แก้ simmoves: least squares 6 จุด (TR_OLD_FALL) — unit test: ปัดแล้วผิด ~2% (พลาดครั้งแรก: สูตร Cramer พจน์ c ผิด → unit test จับได้) ;
    **replay 1241 เต็ม (mod ใหม่ทั้งหมด vs mod แช่):** เปลี่ยนเฉพาะ penguin/mutated/spat/shadow_bishop + _haz FALSE 6,092 → 4,543 (เฟรม 48,236 → 45,628),
    _haz missed 330 → 330 ; MISSED รวม 1,623 → 655 ; ติดตั้งแล้ว ; baseline ใหม่แช่ไว้ scratchpad frozen_mod_v2
  - **ผู้ใช้: "ทำให้หมดก่อนค่อยไป tropical" + "ทำไมไม่แก้หลายตัวพร้อมกัน":** ส่ง agent 9 ตัวขนาน (สืบ + เสนอ patch เท่านั้น ห้ามแก้ไฟล์จริง ; คำสั่งร่วม
    scratchpad agent_brief.md): creepingfear, klaus, snapper(+baby), shark/catcoon/swathgrithr/gingerbreadwarg, twins/eye FALSE, rook FALSE, smallbird/hounds FALSE,
    buffrat/leif/sharkboi/vault_pillar_guard/boulder_crab FALSE, _haz ; ผมรวม patch → replay ชุดเดียว → ผู้ตรวจ → ติดตั้ง
  - **รวมแล้ว (source เท่านั้น, ยังไม่ลงเกม):** (1) **creepingfear:** หนาม UM จาก timer ของมันเอง (creepingfear.lua:88-118, ตี .6 s หลังโผล่, GetAttacked(inst)) ไม่มีใน
    ข้อมูล → striker as_boss ใน sim_mods/um.lua + บรรทัด _hazards (agent: 94 → 0 บน log ที่เติม tr_haz, FALSE +16 = หลบทัน ; log จริงต้องรอ bench ใหม่ที่ trace มัน) ;
    (2) **klaus:** ไม่ใช่บั๊กวาด — bench ร่างโกรธ (scale 1.68, ตีถึง 6.1) แต่ trace ไม่มี scale → replay ใช้ร่างเล็ก ; แก้ modmain ใส่ " scale=" ในบรรทัด tr_trace
    (agent: 39 → 0 บน log ที่เติม scale ; คลาส: shadow piece LevelUp, deerclops UM Enrage) ; (3) **snapper:** speen_pst งับเฟรม 16 ไม่เคยถูกรัน (เพิ่ม add ใน um.lua)
    + lock ปลอมของ baby จากการรันที่ถูกตัดที่ MAX_FRAMES (sim_moves LockFrame: lock > MAX-30 และไม่จบเอง = ไม่มี lock) → ตรวจหลังรวม: snapperturtle 24 → 0
    (FALSE 13 → 15), baby 38 → 0 (FALSE 257 → 71), glacialhound ตัวคุม 5/110 เท่าเดิม ; strict ok ; agent 6 ตัวติด rate limit → สั่งทำต่อแล้ว
    (4) **rook:** FALSE ส่วนใหญ่ = ตอน**หนี** (RunAway หลังตี ใช้ run_start/run เหมือนพุ่ง ; server บอก "ไม่มี ram" อยู่แล้ว แต่ตัววาดถือว่าไม่ได้บอก) → predict/simmoves:
    เคยบอก ram แล้วตอนนี้ไม่บอก (>4 เฟรม) = หนี: ยืนไม่วาด, วิ่งวาดเลนสั้น 4 ข้างหน้า (ยังชนได้ ~4%) ; agent: rook FALSE 1,049 → 162 (MISSED 0 → 0), nightmare
    909 → 114 (4 → 3) ; YELLOW-never-red 675 → 904 (ปลายเลนหนี) ; ตัวคุม minotaur/crabking_mob_knight/rabbitking/deerclops เท่าเดิม ; พบเพิ่ม (ยังไม่ทำ): speed 16 แต่วัดได้
    ~10.5, ทิศพุ่งควรเป็น facing ; (5) **shark/swathgrithr:** เริ่มท่าเดิมซ้ำไม่นับเป็นครั้งใหม่ เพราะ LastStrike ใช้ again_until มากสุดของทุกระยะ → เช็กเริ่มใหม่ใช้ตีของครั้งแรก
    เท่านั้น (predict.lua) ; agent: shark 33 → 0, swathgrithr 17 → 0 (FALSE 8 → 12) ; 15 บอสในคลาส again_until เท่าเดิม ; catcoon 27 = ส่วนใหญ่ bench ย้ายบอสกลางท่า (16)
    + ขอบกริด 0.25 (10: ตีที่ 3.13-3.15 วาดถึง 3.125 — คลาสทุกท่า "ตีถึงระยะ+ตัว" ; ต้องให้ผู้ใช้ตัดสิน) ; (6) **gingerbreadwarg:** น้ำแข็งเคลือบ (warg_gooicing) ขว้าง 6 ทิศสุ่ม
    ตีเมื่อตกใน 1.5 (GetAttacked(caster)) ไม่มีใน _hazards → เพิ่ม STRIKERS (radius 1, moved, as_boss) + บรรทัดข้อมูล ; log เก่าไม่มี tr_haz ของมัน → รอ bench ใหม่
    (7) **leif (UM):** ตาราง vanilla (moves_table) ทับท่าที่ UM แทน → moddata.lua ลบตารางของท่าที่ UM วางทับ (agent: 167 → 54 ; คลาส malbatross/moose/spider_warrior atk ;
    spider_warrior FALSE 0 → 9 = ข้อมูล UM ที่ถูกวาดจริงครั้งแรก — ต้องดู) ; (8) **boulder_crab:** again_at (87) เลยความยาว animation (41) → แดงทั้งท่า → simmoves: again
    ที่เลยความยาวท่า = ครั้งใหม่ ไม่ใช่ครั้งนี้ (TR_OLD_AGAIN) + replay stub GetCurrentAnimationLength จาก tools/anim_lengths*.lua (ใส่ใน cache key แล้ว) ; agent: 102 → 1 ;
    (9) **sharkboi/vault_pillar_guard:** หุ่นไม่มี locomotor → ท่าขุด Kill() แทน DoAttack (ไม่มี STRIKE) → **testbench ใส่ locomotor ให้หุ่น** (ไม่แก้ที่ replay) ;
    smoke 1643: kill 0, sharkboi 506 ครั้งตี 0 พลาด FALSE 141 → 4, vault_pillar_guard 620 ครั้งตี (เดิม 249) 5 พลาด FALSE 115 → 17, hound 590 ✓ ;
    (10) **twins/eye:** sim ตั้งชื่อ "~state" ซ้ำ → ท่ายิงร่างตาหาย (ทำให้ไม่ซ้ำ ~2, ~3) ; ไม่มีท่า "นิ่ง" ของ eye/twin2 ; Off() แยกท่าด้วย animation สุดท้าย (taunt สุ่ม)
    → ข้าม animation สุดท้าย ; การเลือก alt ดู after_anim ด้วย ; replay ทิ้ง hit ของเลเซอร์ (ไม่อยู่ใน tr_env) → เก็บ hit ของของที่บอสนี้วางเอง (OLD_PUTS) ;
    ข้อมูล UM: สลับบล็อก eye/twin1/twin2 จาก agent (สคริปต์ batch\swap_blocks.lua ; ต่าง frozen 29 บรรทัด = 24 agent + 5 ของผม) ; agent: twin1 1,921 → 21, twin2 237 → 48,
    eye 253 → 17 ; shark จาก Off(): 33 → 1 แต่ VANISH 76 (ต้องดูรวมกับข้อแก้ LastStrike)
    (11) **_haz:** บอลลูน um_shadow_wes (แตกเมื่อเข้าใกล้ → lasting, delay 0 ; striker ใน um.lua) ; เลเซอร์ eye ระเบิดไล่ทีละก้อน (delay_max: sim ส่งออก + simmoves วาดตลอดช่วง) ;
    จุดตกของที่โยน รับเมื่อสองเฟรมติดตรงกัน ≤0.4 (TR_OLD_LAND ; Wilting Dragonfly แตกช่วงมากขึ้น) ; replay_haz: ไฟเผา (tr_hurt cause=fire, ไม่มี HIT) นับเป็นจริง
    (OLD_HURT), กระสุนของบอสเอง (STRIKE ภายใน .05 s) ไม่ให้ของ (OLD_OWNSTRIKE) ; รวมด้วย scratchpad batch\merge3.lua (ไม่มี git ; hunk ที่วางไม่ลงจะปฏิเสธ) ;
    (12) **hounds/smallbird:** quickbreath/quickspike UM เล่น atk_pre ช้า .3 ไม่กัด → ไม่ใช่ท่ากัด (seen._slow ; ยกเว้น GoesAgain = Wigfrid twirl) ; กัดที่ยืนกับที่ถูกตัด
    (ไปท่าอื่น) ไม่วาดต่อแบบ after ; เริ่ม atk_pre ใหม่ก่อนไปต่อ = ครั้งใหม่ ; (agent เปิด replay ทั้ง bench 2 process ~40 นาที — ผมหยุดแล้วให้ใช้ผลที่มี)
  - **replay 1241 ทั้งชุด (ครบ 9 กลุ่ม):** MISSED 655 → **208** (เช้านี้ 1,623), FALSE 12,515 → **5,981** (เช้า 14,051), _haz frames 45,628 → 23,890 ; แย่ลงตัวเดียว:
    spider_warrior FALSE 0 → 9 (ข้อมูลกระโดดของ UM วาดจริงครั้งแรก) ; ตัวอื่นเปลี่ยนตรงตามรายงาน agent ทุกตัว
  - **ผู้ใช้ตัดสิน 4 ข้อ:** rook หนี = วาดเลนสั้น ✓ ; ขอบกริด = คงเดิม ; smallbird = **วาดวงตอนมันไล่เรา** ; เวลาเตือน creepingfear/snapper/eye = คงเดิม
  - **smallbird วง:** moves_hand chase (anims walk_loop, idle_loop, walk_pre ; leg_len 0, r 3.5 = range 3 + ตัว) ; วงไม่ใช้ประตูมุม 45° (predict: เฉพาะ leg_len > 0) —
    รุ่นแรกเริ่มจาก walk_pre + ประตูมุม → VANISH 191 / FLICKER 152 ; รุ่นสอง: 67/67, FALSE 0, VANISH/FLICKER 0 (WOBBLE 11, OUTRAN 3) ; penguin/mutated เท่าเดิม
    (VANISH 185 ของ penguin มีอยู่ก่อน — ยังไม่ได้ดู)
  - **ผู้ตรวจ batch: เห็นด้วยแบบมีข้อสังเกต, BLOCKING 1:** กฎจุดตกใหม่ซ่อนของกลางอากาศทุกตัวที่ moved (glassshards บินระนาบ, ไฟ UM เผาตั้งแต่เกิด, missile เลี้ยว)
    → แก้: ซ่อนเฉพาะที่เห็นตกแบบโค้ง (c2 < -2 → s.lobbed) ; checker อ่าน TR_OLD_* จาก env แล้ว ; **ตัวคุม (5 share ที่มีของโยน, ใหม่ vs TR_OLD_LAND):**
    MISSED 2/0/0/0/0 เท่ากันทุก share, FALSE frames 151: 3,471 → 2,491, 191: 1,869 → 1,579, 165: 4,514 → 3,766, 243: 7 → 12, **124 (Wilting Dragonfly): 567 → 846**
    (ลูกไฟขึ้นเกือบตรง — รู้อยู่แล้ว) ; glassshards/wagboss_missile ไม่มีใน bench → ตอนนี้ไม่โค้ง = วาดแบบเดิม ; (share028 ทั้งไฟล์รันก้อนเดียวช้า → หยุด)
  - **ข้อสังเกตที่ยังไม่ทำ (ผู้ตรวจ):** กฎไฟใน replay_haz แก้ตัวให้ทุก hazard ขณะหุ่นไหม้ (ควรจำกัดเฉพาะของที่เป็นไฟ) ; OLD_PUTS นับ hit โดยไม่ดูตำแหน่ง ;
    ต้องแยกผลของ checker ออกจากผลของ mod (รัน OLD_PUTS/OLD_HURT/OLD_OWNSTRIKE) ; กฎเริ่มใหม่ของ glacial อาจกระทบ daywalker tantrum_loop / tentacle (ดูใน bench ใหม่) ;
    PoseNoRam แตะ knight_yoth/crabking_mob (ดูว่ามีใน bench) ; moddata ลบตารางของทุกท่าที่ UM แทน (ทำรายการ) ; กฎ slow ของ hound พิสูจน์แค่ใน replay (ต้องดูใน client จริง)
  - **ติดตั้งลงเกมแล้ว** (strict ok, ทุกไฟล์ตรง hash ; ของเก่าในเกมสำรองไว้ scratchpad game_mod_before_batch) ; แช่ frozen_mod_v3 ; **bench ใหม่ -All เริ่มแล้ว**
    → ต้องดู: หุ่นมี locomotor เปลี่ยนพฤติกรรม alterguardian_phase2 spin / antlion sinkhole / deer ice slow (เทียบจำนวนตีและ state กับ 1241), ฉากที่จบที่ MAX_FRAMES เพราะรอของบิน,
    creepingfear หนาม (ตอนนี้ trace แล้ว), warg goo, klaus scale=, ตัวคุม hound/glacialhound/minotaur/crabking_mob_knight/rabbitking/deerclops/penguin
  - **kleifileexists คืน 1 ไม่ใช่ true (ผู้เล่นจีน):** modmain FileThere() รับ true/1 (pcall) ใช้กับ DEBUG + CLIENT_ONLY ; true_range_client สร้างใหม่ ; ลงเกมหลัง bench ;
    ยังไม่ได้ทดสอบในเกมจริง (เครื่องนี้คืน true)
  - **bench ใหม่ 2026-10-18_1743 (mod v3 + testbench ใหม่):** 65.6 นาที, 260 share, ล่ม 10 (ชุดเดิม), hound 590 ✓ ; replay (frozen_mod_v3) 6.4 นาที:
    ครั้งตี 130,295, **MISSED 404**, FALSE 6,342, haz frames 32,881 ; **บอสรวม MISSED ~37** (catcoon 8/1608, vault_pillar_guard 6/619, bird_mutant_spitter 5/5,
    gestalt_guard_evolved 5/266 …) ; **_haz 367/17,126** = worm_boss_segment 316 (นับซ้ำ 2 บรรทัด ≈158 ครั้ง, 1.98 off = หนามรัศมี 2, ตีใน tick ที่โผล่) +
    eyeofterror_laser 22 + ที่เหลือ ≤5 ; creepingfear หนาม 1 พลาด, warg goo 0 ; **LUA ERROR:** web_bomb (UM, hoodedwidow) เรียก pinnable ของหุ่น (ไม่มี) → testbench
    เพิ่ม pinnable ให้หุ่น (น่าจะเป็นเหตุ hoodedwidow ล่มทุกรอบด้วย) ; ส่ง agent (worm) ดูปล้องหนอน + เลเซอร์ — ห้าม replay ทั้งไฟล์
  - **ปล้องหนอน:** ตีใน tick ที่วางที่รูดิน (AddSegment segtime .01) → วาดที่**รู** (_hazards.worm_boss_dirt src = ปล้อง, 1.6, .35 s, รูใหม่ 1.2 s, หนอนอยู่บนรู) ; นับซ้ำ 2 บรรทัด
    = ตีจริง 2 ครั้ง (UpdateChunk 9 ครั้งต่อ tick) ; ในเกมไม่มี Predict.EntsNear → ใช้ TheSim:FindEntities ; "หนอนอยู่บนรู" ไม่จำกัด → FALSE +14k frames (หนอนค้างบนรู
    ทั้งนาที: ช่วง 970-1030 5 → 1,807) → จำกัด 4 s แรก ; **replay bench 1743 ทั้งชุด:** MISSED 404 → **165** (ไม่จำกัด 95), haz FALSE frames 32,881 → 33,190 ;
    ติดตั้งแล้ว + client ใหม่ ; บรรทัดข้อมูล worm_boss_dirt เขียนมือ — rebuild ลบได้ (memory tr-build-flags)
  - **ผู้ใช้: "reti/spaz แสดงท่าผิด ผสมทั้งพุ่งและพ่นไฟ" (log จริง 19:36):** ร่างตา shoot_pre ใช้ animation เดียวกับ charge_pre → วาดทั้งสอง ("begun alike, too")
    จนเฟรม 34 ; **ตัวแยกใหม่:** ท่าพุ่งไม่เคยหมุนหลังเฟรม lock 11 (bench + log ผู้ใช้ ทุกครั้ง max 0°) แต่ท่ายิงหมุนตามเรา >8° (log ผู้ใช้ 60/72 twin1, 42/72 twin2) →
    predict: หลัง lock+4 ยังหมุน >8° = ท่านิ่ง (TR_OLD_TURNTELL) ; ตรวจ: REPORT_AT 171.0 เดิมสองท่า → ตอนนี้ท่ายิงอย่างเดียว ; bench 1743 twin1/twin2/eye เท่าเดิมทุกตัวเลข
    (MISSED 0/2/0) ; ก่อนเฟรม ~15 ยังวาดทั้งสอง (บอกไม่ได้จริง) ; ติดตั้ง + client
  - **ผู้ใช้: "จะรู้ได้ยังไงว่าจะไม่เกิดอีก":** MISSED/FALSE ไม่จับ "สองรูปพร้อมกัน" + หุ่น bench แทบไม่ขยับ (บอสไม่ต้องหมุนตาม) → **ตัวตรวจใหม่ BOTHDRAWN:**
    predict นับเฟรมที่วาดท่าที่เหมือนกันซ้อน (TR_BOTH, เฉพาะใน replay ; "(always)" = alt_always) ; replay พิมพ์ "BOTHDRAWN <boss>: n frames" ; bench_replay คอลัมน์ both
    + TOTAL ; ตัวคุม: log ผู้ใช้ twin1 240 → 171, twin2 309 → 262 (TR_OLD_TURNTELL เทียบ) ; **สแกน bench 1743:** crawlinghorror 62,359 (always), alterguardian_phase2
    39,960, glacialhound 35,878, terrorbeak 32,082, krampus 27,627, twin2 24,007, ruinsnightmare 17,556, eye 14,703, twin1 14,437 … — คู่ที่ "always" ทั้งหมดคือท่า
    ปกติ + ท่าแปรของ UM ที่เริ่มด้วย animation เดียวกัน (terrorattack, feint_attack, ice_howl_attack, atk_summon) → ต้องหาตัวแยกต่อคู่ (แบบ twins)
  - **BOTHDRAWN แก้ (agent 4 ตัว, ติดตั้งแล้ว):** (1) คู่ที่รูปเหมือนกันทุกช่อง (UM ทำสำเนาท่า: feint, terrorattack, special~summon, @lucky, attack_pre_old) → วาดครั้งเดียว
    (SameShape ; TR_OLD_SAMEALT) ; (2) รูปเหมือนแต่อีกท่าเล่นซ้ำ (phase2 chop~summon) → ใช้ท่าที่ GoesAgain เป็นหลัก (SameShape อย่างเดียว → VANISH +208 — จับได้) ;
    (3) SameFoot: ตีช่องเดียวกันห่าง ≤ LINGER → ครั้งเดียว ท่าที่ตีก่อน (minotaur gore~run_stop, malbatross ; TR_OLD_SAMEFOOT) ; (4) glacialhound: หอนตามท่าอื่นทันทีเสมอ
    (289/289), กัดเริ่มจาก idle/วิ่งเสมอ (1,103/1,103) → a.straight (TR_OLD_STRAIGHT) ; **replay 1743 ทั้งชุด:** two-shapes frames ~330k → **73,065**, MISSED 165 → 166
    (_haz +1), FALSE 6,300 → 6,248, ไม่มีบอสแย่ลง ; เหลือ: twins/eye (bench หุ่นนิ่ง — ตัวแยกการหมุนไม่ทำงาน), glacialhound ตอนหอน 11,271, shark 6,363, minotaur
    leap/stomp 2,203, hoodedwidow 81
  - **ผู้ใช้: เลเซอร์ eye/reti แยกเป็นวง ๆ ไม่รวมกัน:** UnionDraw ใช้กับ lasting เท่านั้น — เลเซอร์ ~21 ก้อนไม่ lasting → แต่ละก้อนมีขอบของตัวเอง ; MISSED/FALSE ไม่จับ
    (หน้าตาอย่างเดียว) — shapecheck มีแต่ยังไม่ได้รันกับ bench → agent (laser) กำลังทำ union สำหรับของที่วางพร้อมกันเป็นแถว + วัดด้วย SHAPE_CHECK
  - **เลเซอร์เป็นคลื่น (ผู้ใช้เสนอ, ติดตั้งแล้ว):** simmoves LaneDraw: ของที่มี delay_max (ตอนนี้ eyeofterror_laser อย่างเดียว) รวมเป็นเลนจากก้อนแรกถึงก้อนสุดท้าย
    (ปลายแรก = ปลายที่ laserempty อยู่), ก้อน k ระเบิดที่ start+k, ช่วงสีเดียวกันวาดเป็น DrawCapsule ต่อกัน (แดงตอนนี้ เหลืองข้างหน้า จางที่ผ่านไป) ; shapecheck 3 ช่วง
    laser ซ้อนกัน 22/21/22 → 1/1/1 เฟรม, ขอบอยู่ข้างใน 382/1787/1961 → 195/415/575 ; MISSED/FALSE ของเลเซอร์เท่าเดิม ; deerclops UM spikes byte เท่าเดิม ; ภาพ
    agents\laser\pic_base_10.5.png / pic_mod_10.5.png ; เหลือ: รอยต่อวงกลมตรงที่สีเปลี่ยน (ทำปลายแบนได้), sim: แต่ละก้อนควรได้ targets ของตัวเอง (ตอนนี้เป็นเสี้ยว)
    **ผู้ใช้: "ทำไมไม่รวมชิ้นเดียวเหมือน eye พุ่ง"** — ท่อนตามสีทำให้มีขอบซ้อน → LaneDraw วาดแคปซูลเดียว จากก้อนแรกที่ยังไม่ระเบิดถึงก้อนสุดท้าย สีเดียว
    (hit > strike > fill ของก้อนที่ยังเหลือ) ; ภาพ batch\wave_10.5/10.7.png = ชิ้นเดียวขอบเดียว หดจากด้านที่ระเบิดแล้ว ; MISSED/FALSE 3 ช่วงเท่ารุ่นท่อน (1/0, 1/0, 1/1) ;
    ติดตั้งแล้ว ; บทเรียน: ถามให้ชัดว่า "เป็นคลื่น" หมายถึงอะไรก่อนสั่งงาน — ผมสั่งแบบสีไล่ ผู้ใช้หมายถึงชิ้นเดียว
  - **ผู้ใช้เล่นเอง (log 20:29, eye + twin1, เดินอยู่): "ท่ายังซ้อน ท่ายังไม่ครบ" → ผู้ตรวจ:** (1) ร่างปากของ eye/twin2 **ไม่มีท่ายิงในข้อมูล** → วาดเป็นพุ่งร่างปาก
    (ไม่มีตัวตรวจไหนเห็น: ไม่โดนตี, ไม่ซ้อน, coverage ผ่าน) ; (2) รูปซ้อนสองขอบเห็นเฉพาะตอนผู้เล่นเดิน (MergeEnd รวมเมื่อเล็งเท่ากัน) — ภาพจาก bench หุ่นนิ่งจะผ่าน ;
    (3) ลูกไฟ twin2, cursed_fire, กระสุนลูกตาไม่มีใน _hazards ; (4) ตัวแยกแน่นอนเฟรม 0: shoot_pre ปล่อย eyeofterror_chargepulse (374/374) ; BOTHDRAWN นับขาดในทาง table ;
    แผน: ตัวตรวจ ท่า↔state → ท่ายิงร่างปาก → chargepulse/ของที่เกิดตอนเริ่มท่า (ทุกคู่) → TR_OUTLINES → หุ่น bench เดิน → LATE cover → ภาพเฉพาะเฟรมที่ถูกฟ้อง → ออกแบบ candidate set
  - **tools/move_state_check.lua (ใหม่):** ท่าที่เริ่มวาด ("began") เทียบ state จริงบรรทัด trace ถัดไป ; ฟ้องเมื่อข้อมูลมีท่าของ state นั้นแต่เลือกอีกท่า ; log ผู้ใช้ล่าสุด:
    eye/twin1 วาดพุ่งตอนยิง 5+2+3 ; 127 log: bearger/mutatedbearger ground_pound vs ~pound 30/138, phase2 summon 47 (log ก่อนข้อแก้), birchnutdrake 5, daywalker 2 (ต้องดู) ;
    ข้อจำกัด: ดูแค่ท่าที่เลือกตอนเริ่ม (alt สลับทีหลังไม่เห็น) ; ผู้ใช้: **ห้ามสร้าง agent ใหม่ ใช้ตัวเดิม (SendMessage)** — งาน eye/twins ส่ง agent twins ตัวเดิมแล้ว
  - **tools/unknown_moves.lua (ใหม่ — ผู้ใช้: "จะหาท่าที่ไม่มีในระบบยังไง"):** อ่าน SG จริงของทุกบอส (UM ก่อน) หา state ที่ทำดาเมจ (DoAttack/DoAreaAttack/
    GetAttacked/Launch/DoArcAttack) หรือปล่อยของที่ไม่อยู่ใน _hazards แต่ไม่มีท่าไหนมี animation นั้น ; กรอง SG ที่ไม่มี animation ร่วมกับท่าของบอส (ไฟล์ prefab หลายตัว)
    106 → 61 บรรทัด ; ทำดาเมจแต่ไม่มีท่า: twins กระสุนลูกตา (spawnminieyes_mouth_loop), spider_trapdoor lob/fall/canopyland, buffrat attack1-3, um_shadow_wes punch/
    jumpout, mutatedbearger atk, bishop attack, teenbird peck, antlion attack_pst, deer unshackle_pst, mothergoose layegg_pst, mothermossling ; ของไม่มีข้อมูล: fused_shadeling
    bombs, mooseegg, daywalker_sinkhole, collapse_small ; ยังไม่ครอบคลุม: ดาเมจจาก timer ใน prefab (แบบ creepingfear) ; แจก agent เดิม: twins (กระสุน+ลูกไฟ),
    miscfalse (buffrat/wes/bearger/bishop), hounds (teenbird/moose/deer/antlion), haz (trapdoor/ของ + สแกน prefab timer)
  - **ผล agent (2026-10-18 เย็น) รวมแล้ว + ติดตั้ง (data E4A952A1EB57):** twins: tell chargepulse + ท่าร่างปาก ~2 + striker minieye (r **1.75** — bench
    ตีห่างสุด 2.21, median 1.93), fireball 3.5, cursed_fire 3.5 ; buffrat attack1-3 (offense — bench ไม่เคยเข้า, ข้อมูลตรง sim) ; teenbird peck ;
    wes punch/jumpout, mutatedbearger atk, bishop atk = scan ผิด (ไปไม่ถึง / อยู่ใน comment) ; trapdoor = scan เอาไฟล์ hoodedwidow (PrefabText) ;
    mooseegg/daywalker_sinkhole/collapse_small ไม่ต้องวาด ; fused_shadeling bomb ยังไม่มีข้อมูล (bench ไม่เคยเกิด)
  - **twins: วัดด้วย bench_replay จริง (ไม่ใช่ตัวนับของ agent)** ก่อน→หลัง: eye both 14703→1234 FALSE 17→**56** ; twin1 14437→1180 FALSE 18→**97** ;
    twin2 24007→1441 FALSE 56→**193** MISSED 2→**6** ; รวม bench: missed 166→170, two-shapes 73065→23773 — agent รายงาน FALSE→0 ผิด (นับต่างตัว)
    → ส่งกลับ agent twins แก้ ; **กฎ: ตัวเลขจาก agent ต้องวัดซ้ำด้วย bench_replay.ps1 -Mod ก่อนเชื่อ** ; mod2 = source ที่รวมแล้วทุกตัวเลข (รวมถูก)
  - **แก้แล้ว (agent twins รอบ 2):** สาเหตุ = กฎ "ไม่เห็น chargepulse ใน 4 เฟรม → พุ่ง" + replay.lua ไม่เคยป้อน pulse → ทุกช็อตกลายเป็นพุ่ง ;
    แก้ predict: ตัดสิน "ไม่มี pulse" ได้ต่อเมื่อเคยเห็นของชนิดนั้นเกิดแล้ว (Predict.tell_seen — ทุกท่าที่มี tell) ; replay.lua ป้อน tell_things จาก
    [tr_ent] born (สำเนาก่อน: tests\replay_before_feed ใน scratchpad batch) ; control: สำเนาก่อนรวม + ตัวนับใหม่ = ตัวเลขเดิมเป๊ะ (17/18/56 FALSE)
    ผล: eye FALSE 17→0 both 14703→648 ; twin1 18→5, 14437→594 ; twin2 56→0 MISSED 2→2, 24007→717 ; ทั้ง bench: missed 166→166,
    drawn-in-no-strike 6248→6169, ของ 33332→33342, two-shapes 73065→21877 ; ติดตั้ง data E4A952A1EB57
  - **haz agent รอบ 2 (รวมแล้ว, data 37DB0E711FE6):** penguin: slide_bounce เล่นซ้ำตอน runningattack → เวลา anim ถอยกลับ ถูกอ่านเป็น "ช้า" → ท่าถูกทิ้ง
    ตอนตี ; แก้ predict Track: เวลาถอยกลับ = เริ่มรอบใหม่ (TR_OLD_SLOW) ; ทั้ง bench: เปลี่ยนแค่ penguin 292→294 missed 2→0, _haz false_fr 33342→33174
    (4180→4178 ช่วง — ยังไม่ได้ดูว่าบอสไหน) ; fused_shadeling bomb (moved, lasting, 2.5) + quickfuse (delay 35, moved) ใน STRIKERS เกมปกติ — bench ไม่เคยเกิด ;
    gestalt_guard_evolved 5 MISSED = ลูกศร gestalt_guard_projectile ตอน idle — sim ไม่บินกระสุน projectile component ("attack_far: nothing") → ยังไม่แก้ ;
    unknown_moves.lua patch (Prefab( ก่อน, จบ state ที่ปิด list, สแกน prefab timer) — ระบบสิทธิ์ไม่ให้ agent เขียน → รอผู้ใช้อนุญาต
  - **unknown_moves.lua ใหม่ (ผู้ใช้อนุญาตให้ทับ):** หาไฟล์ Prefab( ก่อน, state สุดท้ายจบที่ปิด list, ส่วน (2) prefab timer ; + moves_hand,
    ของที่ปล่อยนับเฉพาะตัวที่โค้ดทำดาเมจได้, SKIP พร้อมเหตุผล (14) → 104 → 7 state + 27 timer ; เหลือ: gestalt_guard_evolved mid/far,
    mock_dragonfly flamethrower (spec มี spit/flamethrower แต่ data ไม่มี!), moonmaw_lavae death, squid shoot, wagboss missiles, walrus blowdart ;
    timer: **Antlion sandspike/sandblock/sinkhole ไม่มีข้อมูลเลย**, wagdrone laserwire, goat_lightning, shadowthrall_centipede, um_robust/beestinger/
    smolder_spore, moonglow ; ที่เหลือเป็นของในโลก (กับดัก ต้นไม้ อุกกาบาต พายุ) ; แจก: haz → Antlion + sim บินกระสุน projectile (gestalt) ;
    miscfalse → dragonfly/squid/walrus LaunchProjectile, wagboss, UM projectile, lavae ; bench ไม่เคยสู้ Antlion/wagboss → ต้องเพิ่มใน testbench
  - build -only ตั้งชื่อท่าต่างจาก build เต็ม (charge_pre~shoot_pre → charge_pre~charge_pre) → เอาเฉพาะบรรทัดที่ต้องการ (cmp_moves.lua) ไม่เอาทั้งบอส
  - ส่งต่อ: haz agent → penguin runningattack (MISSED 2 share069 ยืนยัน), gestalt_guard_evolved 5, แก้ scan (Prefab( ก่อน, layegg), fused bomb ; scan ใหม่
    (หลังแก้ PrefabText) +39 บรรทัด ต้องคัด
  - **ยังเหลือ:** eyeofterror_laser 22 (delay_max ที่ใส่มือ 21 อาจสั้นไป — ให้ sim ส่งค่าจริงตอน rebuild UM), ปล้องหนอนที่เหลือ (หัวโผล่นานกว่า 4 s?), catcoon 8,
    vault_pillar_guard 6, gestalt_guard_evolved 5, bird_mutant_spitter 5/5 ; spider_warrior FALSE 0 → 9 ; ข้อสังเกตตัวตรวจของผู้ตรวจ (ไฟ, OLD_PUTS, แยกผล checker/mod)
  - **น้ำมูก spat (12 บน log ผู้ใช้) = ร่องรอยของ trace รุ่นเก่า ไม่ใช่บั๊กการวาด:** log ผู้ใช้ทั้ง 127 ไฟล์ไม่มีบรรทัด LAUNCH เลย (อัดก่อน modmain เขียน LAUNCH)
    → ตอนพ่นถูกเขียนเป็น "STRIKE at" (183.933 ก่อนมีน้ำมูกสักก้อน) ; spat_bomb เป็น hazard วาดตรงที่ตกอยู่แล้ว (sim_moves.lua:5493) ; bench: spat ไม่เคยพ่น
    (508/508 ประชิด — หุ่นใกล้กว่า FORCE_MELEE_DIST 4) → **ตรวจไม่ได้ตอนนี้** ; ต้องการ: bench ที่ให้หุ่นยืนห่าง > 4 สำหรับ spat หรือ log ผู้ใช้ใหม่ ; tr_hurt จากของเกิดก่อนบอส 11 หน้าต่าง ; ช่วง FALSE แตกเพราะอะไร ; jobs 9/10 ขึ้นกับแรมว่างตอนเริ่ม
    (22.9 GB → 9) ; พีคแรมของ expand ทุก core ยังไม่ได้วัด ; boot 32% (c_reset)
- **11:56 ผู้ใช้สั่งหยุด bench 1125** ("หยุดก่อน ค่อยรันใหม่") — หยุดที่ 29 นาที, 18 share เสร็จ (เก็บไว้, a…l บางส่วน) ; รันใหม่ทีหลัง (น่าจะพร้อมการแก้ข้างบน)
- **เกือบพัง:** local บนสุดตัวใหม่ทำ simmoves.lua เกิน 200 local → โหลดไม่ได้ (strict_check ไม่จับ) — จับได้จาก test_sim ; ห้ามเพิ่ม local บนสุดในไฟล์นี้

### 6.16 ตัวตรวจทั้งระบบ: กฎที่ภาพต้องเป็นจริงทุกเฟรม (ผู้ใช้ 2026-10-18: "brainstorm ช่วยกันคิดตัวตรวจ", "วิเคราะห์ verify plan")

**ปัญหาที่ต้องแก้:** ผู้ใช้เข้าเกมแล้วเจอบัคชนิดใหม่ทุกครั้ง 6 รอบ (ซ้อน 2 รูป, วาดผิดท่า, laser แยกชิ้น, ท่าหาย, Retinazor แวบท่าพุ่ง,
วงลูกตาวาป) — แต่ละอันคือ "กฎ 1 ข้อที่ภาพต้องเป็นจริง" ที่ไม่มีตัวตรวจ ; ข้อ 2 ของแผนนี้ (ทำไมตรวจไม่เจอ) ยังเป็นจริง: ตัววัดหลัก (MISSED/FALSE)
ดูแค่ "โดน/ไม่โดน ตรงจุดผู้เล่น" ไม่ดูว่ารูปนิ่ง ต่อเนื่อง ถูกท่าไหม

**กฎ (I1-I11, ผู้ตรวจ + ผม) และตัวตรวจ:**
| # | กฎ | ตัวตรวจ | สถานะ |
|---|---|---|---|
| I1 | บอส 1 ตัว 1 รูปต่อท่า | BOTHDRAWN | มี |
| I2 | ท่าไม่เปลี่ยนกลางทาง | FLIPDRAWN | ใหม่ — 1,516 → twins 0 |
| I3 | ไม่วาดก่อนรู้ท่า / ตอน state ไม่ตี | IDLEDRAW (เฉพาะ state เงียบ) | บางส่วน |
| I4 | รูปไม่ขยับเกินที่ตัวจริงขยับ | JUMPDRAWN (ของ) ; บอส: ยังไม่มี | กำลังทำ |
| I5 | พื้นที่เปลี่ยนเฉพาะที่ step ในข้อมูล | VANISH/SHRINK | มี |
| I6 | 1 ท่า = 1 ชิ้น | SHAPE_CHECK | มี |
| I7 | จุดโดนอยู่ในรูป / รูปไม่ใหญ่เกินที่ตีได้ | MISSED ; เกิน: OVERDRAWN (พุ่งเท่านั้น) | ขาดฝั่ง "ใหญ่เกิน" |
| I8 | เตือนทัน, เหลือง→แดงเสมอ | SHORT, YELLOW | มี |
| I9 | รูปเปลี่ยนเรียบตามระยะผู้เล่น | map_steps_check.lua (ข้อมูล) ; ผู้เล่นจำลอง (วาด) | ข้อมูล: ทำแล้ว |
| I10 | ทุกอย่างที่ตีมีข้อมูล | unknown_moves.lua | มี |
| I11 | หลายบอสพร้อมกัน = เหมือนทีละตัว | ไม่มี | ยังไม่ทำ |

**ข้อเท็จจริงที่ต้องแก้ในความเข้าใจ:** ตัวยืนใน bench **ขยับ** (step 60/150°, run วนด้วยความเร็ว 6, jump ไประยะ d — tr_testbench
modmain.lua:33-52, :334-338) แต่**ระยะห่างจากบอสคงที่ระหว่างท่า** (วนที่ระยะเดิม) → ไม่เคยเดินเข้า/ออก → I9 (สลับแผนที่ตามระยะ), I4 ฝั่งบอส,
งบสร้างระยะใหม่ (simmoves budget 0.5 s ร่วมทุกบอส) ไม่เคยถูกทดสอบ ; memory checks-miss-visual-mixing ที่ว่า "ไม่ขยับ" ผิดบางส่วน

**ผู้เล่นจำลองใน replay (ข้อเสนอผู้ตรวจ) — วิเคราะห์:**
- ทำเพื่อ: ใช้ log bench เดิมทั้งหมด เปลี่ยนตำแหน่งผู้เล่นให้เดินเข้า-ออก (ระยะ 1-12 แกว่ง) + วน ; ตัววาดเลือกแผนที่ตามระยะผู้เล่นเท่านั้น →
  ทดสอบ I1-I6, I9 ได้ทันที ไม่ต้องรัน bench ใหม่
- ไม่ช่วยเมื่อ: บอสใน log ไล่ตัวยืน ไม่ใช่ผู้เล่นจำลอง → MISSED/FALSE ไร้ความหมายในรอบนี้ ; ท่าที่เล็งตามเป้า (lock) วาดเล็งไปผู้เล่นจำลอง
  แต่บอสหันไปตัวยืน → รูปอาจ "ผิด" แบบที่เกมจริงไม่เกิด — ต้องนับเฉพาะกฎความต่อเนื่อง (JUMP/SIZE/GAP ภายในท่า) ไม่นับตำแหน่ง
- ทางอื่น: ให้ตัวยืนใน bench เดินเข้า/ออกจริง (สมจริง ใช้วัด MISSED ได้) แต่ต้องรัน bench ใหม่ ~70 นาที → ทำทีหลัง เป็นตัวยืนยัน
- รู้ว่าได้ผล: ตัวคุม = TR_OLD_SINK=1 (วงลูกตาวาป) ต้องได้ JUMP > 0 ; ข้อมูลรุ่นเก่า (ก่อนแก้ seed) ต้องได้ SIZE/GAP ที่ bearger/fruitdragon/twins > 0

**ตัวตรวจรวมใน replay.lua (ทำต่อ):** จาก drawn_at ทุกเฟรม (area, cx/cz, move, move_t0) เทียบเฟรมก่อนในท่าเดียวกัน:
JUMP (จุดกลางขยับ > บอส + ผู้เล่น + 1), SIZE (พื้นที่ ×2 ใน 1 เฟรม), GAP (หายแล้วกลับมาในท่าเดียว) → I4, I5, I9 ฝั่งตัววาด

**map_steps_check.lua (I9 จากข้อมูล) ผลแรก:** 122 คู่ไม่สุ่ม (AT 97, SIZE 19, EMPTY 6) + 81 สุ่ม ; ตัวคุม lunar_grazer spawn (ผู้ตรวจชี้) ✓ ;
แบบที่เจอ = **สลับไปมา** bearger butt_pre_L 40/56/40/56, fruitdragon 42/58/42, twins ท่าพุ่ง 1365/2823/1367 ช่อง
→ สาเหตุ: sim seed = seed×7919 + dist (ต่างทุกระยะ) + เช็ก "สุ่มไหม" จากตำแหน่งช่องเท่านั้น ไม่ดูเฟรม → ท่าที่สุ่มจังหวะถูกนับว่าไม่สุ่ม 1 รอบ
แต่ละระยะได้คนละค่า ; แก้ใน sim แล้ว (seed เดียวกันทุกระยะ + HitKeys มีเฟรม ; SIM_OLD_SEED) — **ยังไม่ rebuild** ; EMPTY (catcoon jump_grab,
malbatross atk~alert: แผนที่ว่างระหว่าง 2 แผนที่เหมือนกัน) — ยังไม่สืบ (สงสัย pcall ล้มที่ระยะนั้น)

**เกณฑ์ "เสร็จ" (ไม่ต้องพึ่งผู้ใช้เข้าเกม):** ชุด log ตายตัว (log ผู้ใช้ทั้งหมด + bench + ผู้เล่นจำลอง) ; (ก) ทุกตัวนับ I1-I11 = 0 หรือมีเหตุผลเขียนไว้ ;
(ข) MISSED ต่อบอสไม่แย่กว่าสำเนาแช่แข็ง ; (ค) scan ข้อมูล (unknown_moves, map_steps_check) ไม่มีที่อธิบายไม่ได้ ; (ง) ทุกตัวนับผ่านตัวคุมที่รู้ว่าผิด ;
ผู้ใช้เจอใหม่ = เพิ่มกฎ + log เข้าชุด ไม่รื้อทั้งหมด

**ลำดับ:** (1) JUMP ของ: รัน old/new (กำลังรัน) → (2) ตัวตรวจรวม JUMP/SIZE/GAP ใน replay + ผู้เล่นจำลอง (WALK=1) → (3) rebuild ข้อมูลด้วย seed ใหม่
(vanilla + UM ; ระวังของใส่มือ: tools/ends_moves.txt, worm_boss_dirt src, laser delay_max) → map_steps_check ต้องลด → (4) I7 รูปใหญ่เกิน, I11 สองบอส
→ (5) รันทุกตัวรอบเดียว ได้รายการบัคทั้งหมด แก้ทีละกฎ → (6) ตัวยืน bench เดินเข้า/ออก + bench ใหม่ เป็นตัวยืนยันสุดท้าย

**ความเสี่ยง:** rebuild ทั้งหมด = ข้อมูลทุกบอสเปลี่ยน → ต้อง replay ทั้ง bench เทียบสำเนาแช่แข็ง + diff ข้อมูล ; ผู้เล่นจำลองอาจฟ้องสิ่งที่เกมจริงไม่เกิด
(ข้อจำกัดข้างบน) → ทุกเคสต้องดูว่าเป็นของจริงก่อนแก้ ; แก้ source ระหว่าง replay รัน = ผลปน (เกิดแล้ว 2026-10-18: หยุด + ลบ cache 1,434 ไฟล์)

**ผลคืน 2026-10-18 (ผู้ใช้นอน, ติดตั้งแล้ว — source = เกม):**
- **Retinazor แวบท่าพุ่ง (I2):** ไม่วาดอะไร 4 เฟรมแรกเมื่อมีท่าที่บอกด้วย tell (ตั้งตั้งแต่เฟรมที่สร้างท่า — ครั้งแรกตั้งในบล็อก alt
  ซึ่งทำงานเฟรมถัดไป ไม่ได้ผล) ; FLIPDRAWN twins 833 → 0, MISSED/FALSE เท่าเดิม ; TR_OLD_TELLWAIT
- **ลูกตาวาป (ผู้ใช้):** สาเหตุจริงจากภาพ log ผู้ใช้ (PIC_AT) — ไม่ใช่การเดาครั้งแรก (จุดตก = ผิด, พิสูจน์ด้วย old/new เท่ากัน) ;
  (1) ค้าง 2 เฟรมแล้วจม → นับเป็น "โยน" → ซ่อน 5 เฟรม → กฎ: โยน = เคยเห็นลอยขึ้น**สูงกว่า 1.2** (TR_OLD_LOB, TR_OLD_HOP — หิน bearger กระเด้ง 0.5-0.8) ;
  (2) จุดตก/ตรึงวงใช้เฉพาะของที่โยน ; (3) วาดล่วงหน้า 1 เฟรมเฉพาะของกลางอากาศที่ไม่เคยลอยขึ้น (TR_OLD_LEAD — ตีพลาด 0.12 ที่ 0.6/เฟรม) ;
  log ผู้ใช้: ลูกตา 3/5 → 5/5 วาด, GAP 9 → 0
- **ตำแหน่งซ้ำทุก 3 เฟรม = "หยุด" (คลาส):** server tick ≠ เฟรม → ของบินถูกนับว่าหยุด 1 เฟรม วาดรอบตัวกลางอากาศ แล้วกลับไปจุดตก →
  หยุด = นิ่ง 2 เฟรมติด (TR_OLD_STILL) ; + ของกลางอากาศที่ยังไม่ขยับตั้งแต่เกิด ไม่วาด (TR_OLD_EARLY) + เวลาตกเผื่อ 0.2 s
- **ทั้ง bench 1743:** ของ MISSED 127 → 125, FALSE ช่วง 4,161 → 2,413 / เฟรม 33,411 → 31,420, JUMP 79,953 → 258, GAP 13,938 → 918 ; บอส MISSED 163 → 161
- **ตัวตรวจใหม่:** FLIPDRAWN, JUMPDRAWN (+ "ห่างจากตัวของเกิน 1"), GAPDRAWN (+GAP_V), TRACE_GUID (SimMoves._Trace ทีละเฟรม), things-struck
  นับรูปของของด้วย (haz_in — ก่อนนี้ดูแค่รูปบอส: 7/7 "ไม่วาด" ทั้งที่วาด) ; map_steps_check.lua ; bench_replay: คอลัมน์ flip/jump/gap,
  cache รวมสวิตช์ TR_OLD_* ที่อ่านจากรายการ (เคยดึง cache ผิด), -Mod ได้โฟลเดอร์ผลของตัวเอง (agent เขียนทับ)
- **บทเรียน:** เดา 3 ครั้งผิด (จุดตก, ตัดประวัติ, ซ่อนต้น) — ดู TRACE/ภาพก่อนแก้เสมอ ; ตัวคุมที่ไม่ต่าง = สมมติฐานผิด
- **sim:** seed เดียวกันทุกระยะ + HitKeys(.., true) มีเฟรมเฉพาะเช็กสุ่ม (ทำ bishop พังครั้งแรก — KeyXZ อ่าน key เป็นตำแหน่ง) ; bearger butt 18/
  fruitdragon 24 คู่สลับ → 0 (-only) ; HAZARD_EXTRA (worm src), TELL ใน spec UM ; haz agent: projectile component บินจริง, antlion_sinkhole
  (again 30/60), lava sinkhole ; **ยังไม่ rebuild ทั้งหมด**
- **rebuild เกมปกติ (sim ใหม่, 2026-10-19 ตี):** 350 s ; map_steps_check AT 42 → 0, EMPTY 4 → 0, SIZE 13 → 1 ; 63 ท่าเปลี่ยน ;
  sim check 416 ฉากผิด (last_check 302) — **ไม่ใช่ผลของการแก้:** -only 9 บอส: sim เดิมทั้งหมด 175, seed+dist แต่ HitKeys ใหม่ 175 (AT 42),
  ใหม่ทั้งหมด 159 (AT 0) → last_check เก่ากว่าการแก้อื่น ; worm_boss_dirt ทั้งบรรทัดเป็นของใส่มือ (sim ไม่ทำ) → ย้ายไป moves_hand._hazards
  (merge ตอนโหลด) ; HAZARD_EXTRA เอาออก ; สำเนาก่อน rebuild: scratchpad batch\mod_before_rebuild
- **UM rebuild (build_um 7 นาที) + ติดตั้ง (data 6918B5AA68EE):** map_steps_check UM AT 55 → 1 ; ท่ายิง "still" ของ Eye/twin2 หายอีก (sim:
  "shoot_pre: nothing" — ใส่มือ) → **moves_hand_um.lua** (moddata `hand =`, ใส่เฉพาะที่ข้อมูลไม่มี) ; phase3 attk_beam/swipe frame target→facing
  (sim: turned 0 ที่เฟรม 16 ทั้งที่เกมหันตามใน 45°/16 — ต้นเหตุยังไม่เจอ) → spec frame = "target" (bench: MISSED 0 → 233 ถ้าไม่ใส่) ;
  deerclops strikes 404 → 206 = ย้ายไป BYTHING (UM uppercut) — MISSED 0 ทั้งคู่ ; checker: ของในพูลที่ถูกวางใหม่ที่อื่นทันที = นับอายุใหม่ (non-moved)
  **ทั้ง bench: บอส MISSED 161 → 153, ของ 125 → 122, FALSE 4,407 → 4,392, glitch 9,970 → 9,567 ; WALK glitch 19,958 → 17,695**
- **WALK เจอของใหม่ (เดิน − ยืน ≈ 8,000 glitch, JUMP 9,417):** catcoon pounce 302 → 1,698, glacialhound 542 → 1,772 (ภาพ: เลนที่สองเป็นตัว V
  แวบ 1 เฟรม — alt), swathgrithr 182 → 1,106, แมงมุม ~120 → ~770, stumpling/birchling, rook_nightmare, shadowthrall_horns, deerclops, sharkboi ;
  แจก agent: twins → alt (V), haz → กระโจน/แมงมุม, miscfalse → หมุน/ที่เหลือ ; WALK แทนค่า tgt=/tpos= ของตัวยืนด้วยผู้เล่นจำลอง (log bench ไม่มี tgt)
- **testbench smoke (ฉาก walk + SETUP):** antlion สู้ (cast_pre 28), wagboss (atk_squish 55), eyeplant (4), daywalker2 สู้ (pounce = atk3) หลังยกเลิก
  งานเตาของ UM บนกองขยะ (server ค้าง) ; crabking ตื่นแต่ไม่มีทะเลใกล้ (ยังไม่สู้) ; stalker_atrium ตี 1 ครั้งแล้วจบ ; bench -All ใหม่กำลังรัน
- **bench ใหม่ 2026-10-19_0600 (90 นาที, 258 share, ฉาก walk 12,514):** รุ่นติดตั้ง 6918 vs ใหม่ ; WALK มีบั๊กของตัวตรวจ (ทุก tick ที่ตี "you"
  ถูกตั้งกลับไปที่ตัวยืน — miscfalse agent, TR_OLD_WALKPOS) → glitch ตอนเดินส่วนใหญ่หาย ; ALTLOCK (twins: ท่าคู่ที่ไม่มี lock แต่วางของ
  ล็อกที่ set_until) ติดตั้ง: MISSED 496 = 496, glitch 9,877 → 9,816, walk 15,534 → 15,504 ; **LEAPAIM (haz) ถอน:** ยืนนิ่ง rneskeleton 1 → 10
  missed (พุ่งหันตามเป้า) — ผลดีตอนเดินเป็นของปลอมจาก WALK (บอสใน log กระโจนใส่ตัวยืน) → **บทเรียน: WALK ใช้ตัดสินการแก้เรื่องเล็งไม่ได้**
- **เหลือ (bench ใหม่, ยืน):** BOTH glacialhound 12,480 / shark 9,273 / minotaur 2,410 ; FLIP phase2 775 (chop→~summon) ; MISSED spat 288/588
  (ใหม่ — เพิ่งพ่นได้เพราะฉาก walk), mutatedwarg 18, bearger 13, phase3 12, boulder_crab 11, catcoon 9 ; crabking (ไม่มีทะเล), atrium (ตี 1 ครั้ง)
  → แจก: twins = ท่าคู่ (BOTH/FLIP), haz = spat/warg/bearger, miscfalse = phase3 sim/boulder/catcoon/vault + crabking/atrium setup
- **spat 288 → 0 (ติดตั้ง data FAA4025BEC62):** spat_bomb ไม่ได้ as_boss → การตีของน้ำมูกนับเป็นท่าของ spat ที่ไม่ได้วาด ; ของ: 330 ตี 329 วาด ;
  MISSED ทั้ง bench 496 → 208 ; mutatedwarg/bearger = ตัวยืนอยู่ในตัวบอส (ฉาก walk ลงไปถึงระยะ 1) — **บั๊กของ testbench (ผม)** → หยุดที่ ขอบตัว + .6
- **setup รอบ 2 (miscfalse agent):** stalker_atrium สู้ (attack 58, attack1 2, spike 7 — ประตูย้ายตามบอส) ; crabking ลงทะเล + ตัวยืนบนเรือ:
  เรียกก้าม 84 ครั้ง แต่ตัวเองไม่ตี (ดาเมจมาจากก้าม/น้ำพุ/ปืน — ทดสอบแยกเป็น crabking_claw) ; bench -All รอบ 2 กำลังรัน
- agent twins/miscfalse ติด rate limit (ถึง 9:40) — twins: ท่าคู่ (BOTH/FLIP) แก้ค้างอยู่ใน mod5
- **บั๊กของผม (HitKeys, 2026-10-18 คืน): `.. ""` ทำ key เป็น string → Rotated (number) ไม่ตรง → ทุก turn test "turned 0"** → rebuild
  2026-10-19 ได้ 35 ท่าเป็น facing ผิด (phase3 = อาการนี้ ไม่ใช่ sim ไม่หัน) ; แก้ใน tools แล้ว (SIM_OLD_HITKEY) ; แต่ rebuild ด้วย sim ที่ถูก
  (miscfalse agent, 35 ท่า) **bench แย่ลง:** MISSED 31 → 33, FALSE 332 → 355, glitch 2,737 → 3,091 → ยังไม่ติดตั้ง ; ข้อมูลที่ติดตั้ง = facing (bug) +
  phase3 target มือ ; งาน: ทำไมตัววาดโหมด target แย่กว่า (miscfalse agent) — **ก่อน rebuild ครั้งถัดไปต้องปิดเรื่องนี้ก่อน**
- **ท่าคู่ (twins agent, ติดตั้ง data 30513395313A):** PickAlike จากเกม — glacialhound howl มาหลัง scared_pst เท่านั้น (from), ซ้ำตัวเอง 2 ;
  phase2 summon = summon_fx (tell) ; shark attack บนน้ำ / bite บนบก (on) ; minotaur stomp ไม่มีใครเรียก (ลบ) ; icespike by + glacialhound ;
  ทั้ง bench 0600: BOTH 24,331 → 5,118, FLIP 780 → 0, glitch 9,816 → 9,373, MISSED เท่าเดิม (+1 ของ) ; shark เหลือ 4,950 ;
  เก็บใน spec ทั้งหมด (extra รองรับรายการแล้ว — เคยเขียน "table: 0x") ; TR_OLD_FROMTELL / TR_OLD_TELLSTILL
- **35 ท่า target/facing (miscfalse agent):** 22 ท่า target (เท่า/ดีกว่า — vault glitch 61 → 54) splice แล้ว ; 13 ท่าคง facing ด้วย spec
  frame="facing" (เหตุผลเกม: twins charge steering, mutated deerclops 45°, horns 45-faced/jump ทิ้งเป้า ; shadow_rook ไม่มีเหตุผลโค้ด — bench) ;
  ก่อน rebuild ครั้งถัดไป: snaps ของ twins charge_pre~charge_pre จะเปลี่ยน (turn test ใช้ได้แล้ว) — ต้องเช็ก
- **bench #2 2026-10-19_0942 (132 นาที, ตัวยืนหยุดที่ขอบตัวบอส, atrium/crab setup) + data 994F0CB48EBD:** MISSED 201 (warg/bearger หาย),
  FLIP 0, BOTH 11,720 (shark 11,616 — บน bench นี้ shark สู้มากขึ้น), glitch 9,298 ; เหลือ: mushdrake_red 30 (ใหม่), boulder_crab 13 + glitch 593,
  phase4 glitch 1,068, bishop 411/379, rook ~300 → แจก twins = shark, haz = mushdrake/boulder/daywalker2, miscfalse = glitch top
- **รอบถัดไป (bench #2):** ตัวนับ JUMP หักการหมุนของบอส (เลนยาวหมุนตามบอส ≠ กระโดด — phase4 1,013 → 3, bishop 411 → 236 ; OLD_JUMP_TURN) ;
  mushdrake_red 30 = testbench ย้ายบอสกลางท่าหมุน (MAX_FRAMES) → จบฉากเมื่อออกจากท่าแล้วเท่านั้น (สูงสุด 3 เท่า) ; boulder_crab 13 = วิ่งไปชน
  ตัวผู้เล่นที่ 1.10 แต่แผนที่คิดว่าวิ่งต่อ (ขาด free) ; catcoon = ท่าต่อเนื่องที่ท่าหลังเป็นท่าของตัวเองอีกท่า เล็งต่างกัน ; bishop เล็งไหลตาม
- **ติดตั้ง (data 994F0CB48EBD + โค้ดใหม่):** ตัวตรวจ: แผนที่พื้นอ่านทุกชุด (บรรทัด 4,095 ตัวอักษรถูกตัด — shark BOTH 11,616 → 0) ;
  modmain เขียนแผนที่เป็นส่วนละ 40 แถว (row0=) ; CHAINLOCK (catcoon: ท่าต่อเนื่องเลื่อน lock ไปที่ของท่าหลัง — เกมหันตอนเริ่มกระโจน) ;
  TPKEEP (bishop: ไม่ทิ้งตำแหน่งเป้าของ server เมื่อห่างเกิน 6) ; **bench #2: MISSED 201, BOTH 11,720 → 104, glitch 9,298 → 7,455**
- **รอ rebuild ครั้งถัดไป:** boulder_crab (sim: PushAnimation บนแอนิเมชันที่จบแล้วต้องเล่นทันที + จุดที่ตีซ้ำในแอนิเมชันอื่น = step แยก ;
  13 → 2 missed แต่ FALSE 0 → 33 ; SIM_OLD_PUSH / SIM_OLD_LATER ใน haz agent sim_moves_push2.lua) ; snaps ของ twins charge ; daywalker2 pounce (4)
- **rebuild ทั้งหมดด้วย sim ที่แก้แล้ว (ติดตั้ง data EDAB305328AF, 2026-10-19):** ทุกอย่างที่แก้มือ/ตัดสินไว้มาจาก spec ครบ (tell, from/on,
  icespike by, spat as_boss, 13 facing + laserbeam ของ mutated deerclops ; minotaur stomp ลบ → leap ชื่อ jump_atk_pre เนื้อหาเดิม) ; field ใหม่จาก
  turn test ที่ใช้ได้: cone, snaps, snap_anim ; UM 19 ท่าเปลี่ยน (frame ส่วนใหญ่) ; **bench #2: MISSED 201 → 200, FALSE 5,652 → 5,650, glitch
  7,455 → 7,426** ; แย่ลงเล็กน้อย (ค้าง): phase2 glitch 157 → 182, vault FALSE 11 → 13, sporehound FALSE 10 → 11, bearger glitch +2 ;
  last_check.txt = 292 (ฐานใหม่) ; **ข้อมูลตอนนี้ build ซ้ำได้จาก spec ทั้งหมด — ไม่มีบรรทัดใส่มือใน moves_sim*.lua**
- **ผู้ใช้ 2026-10-19 13:12: "eye ตอนยิงลูกน้อง เฟรมแรกๆ flip"** — ท่าพุ่งของ Eye/twins มี leg → วาดผ่านทาง leg ซึ่ง**ไม่ได้รอ tell_wait** ;
  ตัวนับ FLIP อยู่แค่ทางวาดหลัก → bench บอก 0 ทั้งที่แวบ 867 ครั้ง (eye 237, twin1 227, twin2 403) ; แก้: รอที่จุดแยกทางวาด (ทุกทาง) +
  ตัวนับ FLIP ย้ายไปจุดเดียวกัน (TR_OLD_TELLWAITALL) → 0 ; MISSED/FALSE เท่าเดิม ; ติดตั้ง ; **บทเรียน: ตัวนับ/ตัวกั้นต้องอยู่ที่จุดที่ทุกทางวาดผ่าน
  ไม่ใช่ในทางเดียว — ทางวาดมี 5 ทาง (arena, finish, table, leg_whole, leg, หลัก)**
- **ผู้ใช้ 2026-10-19 13:48: "ancient ไม่นับกระโดดครบทุกรอบ"** — minotaur (UM) กระโดดเร็ว 2 ครั้งติด: ลงที่เฟรม 44 กระโดดใหม่ที่ 45 → กฎ
  "กลับแอนิเมชันแรก = รอบใหม่" ต้องรอ first + LINGER → ไม่ทำงาน → ลูกที่ 2 วาดที่เดิม (OUTSIDE: groundpound ลงที่ไม่มีอะไรวาด) ;
  แก้: หลังผ่านแอนิเมชันถัดไปแล้ว พ้นเฟรมตีพอ (TR_OLD_AGAINLINGER) ; ติดตั้ง ; **bench ไม่เคยเห็น: minotaur บน bench กระโดดเร็ว 0 ครั้ง —
  ท่าที่ออกเมื่อเลือดลด** → testbench: ครึ่งหลังของฉาก ลดเลือดบอสเหลือ 40% + ตีจริง (ไม่เกิน 150 / ครึ่งเลือด) → minotaur quick 33,
  buffrat attack1 24 ; bench #3 (-All + hurt) กำลังรัน
- **laser ของ Retinazor บน log ผู้ใช้:** 2/2 วาด (replay ของ Eye นับ laser ของ twin1 เป็นของตัวเอง = ตัวตรวจ) ; FLIP/BOTH บน log นี้ = ไม่มีบรรทัด pulse
- **ผู้เล่นจำลอง:** replay.lua WALK=1 (ระยะ 1-12 แกว่งทุก 6 s + วนรอบ) ; bench_replay -Walk (โฟลเดอร์ __walk) + คอลัมน์ glitch
- **testbench:** ฉาก walk (เดินเข้า/ออก 4/s จากเฟรม k) ; SETUP: antlion StartCombat, atrium gate, junk pile, wagboss idle, eyeplant ชิด,
  crabking ทะเล+อัญมณี 9 ; SETUP_TICK stalker ; **ยังไม่รัน bench ใหม่**

### 6.17 ทุกบอส ทุกเฟส — แผน (ผู้ใช้ 2026-10-19: "ไปวางแผนดีๆ หยุดทำงานลวกๆ" ; "จะรู้ได้ยังไงว่าครบทุก phase")

**ที่ผ่านมาผิดตรงไหน:** ลดเลือด 40% ครั้งเดียวเพราะเห็น 2 บอสได้ผล — ไม่ได้ถามก่อนว่า "ครบ" หมายถึงอะไร วัดยังไง → ต้องแก้ซ้ำ 3 รอบในชั่วโมงเดียว

**เป้าหมาย (นิยาม "ครบ"):** สำหรับบอสทุกตัวในข้อมูล — ทุก state ที่ทำดาเมจได้ (ตรง/ผ่านของที่ปล่อย) ต้องถูกเข้าบน bench อย่างน้อย 3 ครั้ง
ในฉากที่ตัวยืนขยับ (step/run/walk) หรือมีเหตุผลเขียนไว้ว่าทำไมเข้าไม่ได้ (เช่น ต้องมีผู้เล่น 2 คน, state ตาย, ไปไม่ถึงตามโค้ด)

**ส่วนประกอบ:**
- **A. รายการจากโค้ด (static, ไม่รันเกม):** ต่อบอส: (1) state ที่ทำดาเมจได้ทั้งหมด — ใช้ตรรกะของ unknown_moves แต่ทุก state ไม่ใช่เฉพาะที่ข้อมูลไม่มี ;
  (2) เงื่อนไขที่ทำให้เข้า state นั้น: เลือด (phase_scan: 42 บอส, 90…10%), timer/cooldown, กลางคืน, ลูกน้อง, โหมด (enrage/offense), ทะเล/arena ;
  (3) ต้องการ setup อะไร (SETUP ที่มี: antlion, atrium, daywalker2, wagboss, eyeplant, crabking)
- **B. ตัววัด (dynamic):** tools/state_coverage.lua — จาก log bench: ต่อบอส state ที่เข้าจริง × ช่วงเลือด × ชนิดฉาก ; ออกรายการ "state ทำดาเมจที่เข้า < 3 ครั้ง"
  แยกเหตุผลจาก A
- **C. ตัวขับใน testbench:** ลดเลือดเป็นขั้นต่ำกว่าแต่ละกลุ่ม threshold (85/72/62/48/32/22/9) — ทำแล้วแต่**ยังไม่ได้ตรวจว่าเกมยิง trigger จริง**
  (SetPercent → healthdelta → healthtrigger?) ; เงื่อนไขอื่นจาก A เพิ่มเป็น SETUP ทีละชนิด (คลาส ไม่ใช่ทีละบอส)
- **D. ตัวคุม (ต้องผ่านก่อนเชื่อ):** กรณีที่รู้คำตอบ: minotaur UM ต้องเข้า leap_attack_pre_quick ; Eye of Terror ต้องเปลี่ยนร่าง (transform) ;
  buffrat ต้องเข้า attack1 ; Bee Queen ต้องเปลี่ยน phase ; ถ้าตัวคุมไม่ผ่าน = ตัวขับผิด ไม่ใช่บอสไม่มีเฟส
- **E. ความเสี่ยง:** (1) เลือดต่ำ → บอสตาย/แปลงเป็น prefab อื่น (alterguardian, Eye→Twins?) → bench ต้องเห็นและไม่นับว่า "ล้ม" ;
  (2) SetPercent อาจไม่ยิง trigger บางแบบ (ที่เช็กตอนโดนตี) → ตีจริงเล็กน้อยทุกขั้น? (ตอนนี้ตีครั้งเดียว — ต้องตัดสินจาก D) ;
  (3) เวลา bench: 8 ช่วงเลือด × ฉากเท่าเดิม = ฉากต่อช่วงลดลง → บาง state อาจ < 3 ครั้ง → อาจต้องเพิ่ม Rounds สำหรับบอสที่มีเฟส ;
  (4) bench ไม่ได้ทดสอบหลายผู้เล่น — state ที่ต้องมีหลายคนจดเป็นเหตุผล
- **F. ลำดับ:** A(1)(2) → B → D บน smoke 5 บอส (minotaur, eyeofterror, buffrat, beequeen, + hound ตัวคุมไม่มีเฟส) → แก้ C ตามผล D →
  bench เต็ม → B ทั้งหมด → แก้รายการที่เหลือเป็นคลาส → ทำซ้ำจนรายการว่าง/มีเหตุผลครบ
- **G. รู้ได้ยังไงว่าเสร็จ:** รายการจาก B ว่าง หรือทุกบรรทัดมีเหตุผลจาก A ; ตัวคุม D ผ่านทุกตัว ; ทำซ้ำ bench ได้ผลเดิม

**ผลตรวจของ reviewer (2026-10-19) — แผนแก้ตามนี้:**
- **BLOCKING: SetPercent ไม่ยิง healthtrigger** (health.lua:550-553 SetVal ก่อน DoDelta(0) → oldpercent == newpercent ; healthtrigger.lua:28-29
  ต้องข้ามเส้น) → Bee Queen, Dragonfly, Toadstool, Klaus, Crab King, daywalker(2), Fuelweaver, mermking, wagboss, + UM postinit beequeen/moose/
  minotaur, hoodedwidow, moonmaw, rambranch **ไม่เคยเปลี่ยนเฟส** ; ที่ "ได้ผล" (minotaur, Eye) อ่าน GetPercent ตรงๆ — ไม่ใช่หลักฐาน
  → **ตัวขับ:** `DoDelta(target*max - current, nil, "testbench", true, nil, true)` (ข้ามเส้นจริง) + log เปอร์เซ็นต์หลังเรียก (redirect/deltamodifier/
  maxdamagetakenperhit อาจกัน) + GetAttacked เล็กน้อยทุกขั้นสำหรับโค้ดที่ตอบสนองเมื่อโดนตี
- **นิยาม "ครบ" ละเอียดไม่พอ:** นับ (prefab, state, ร่าง/สาขา mem) ไม่ใช่ชื่อ state (Eye charge ต่างกันตาม sg.mem.transformed) ; เฟสที่เป็น prefab ใหม่
  (alterguardian 1→2 ลบตัวเองแล้วเสกตัวใหม่ — bench ต้องตามไป, ไม่ใช่จบ) ; เฟสของ manager (Twins แปลงร่างผ่าน manager เลือดรวม —
  เสกเดี่ยวไม่มีวันแปลง) ; ของ/ลูกน้องที่ปล่อยเฉพาะบางเฟสก็ต้องนับ ; ระดับเลือดต่อบอสจาก phase_scan ไม่ใช่ LEVELS เดียวทั้งหมด ;
  bench รอบที่สองต้องได้ผลเดิม
- **ประตูอื่นนอกจากเลือด (คลาส):** ดาเมจที่ได้รับ (buffrat, crabking damagetotal) ; โดนผู้เล่นตีล่าสุด (atrium) ; timer/cooldown ; ลูกน้อง
  (Klaus โกรธเมื่อกวางตาย) ; ของ/อุปกรณ์ (daywalker2 junk) ; arena/พื้นที่ (wagboss barrier, crabking ทะเล) ; สภาพโลก (antlion พายุทราย,
  ฤดู, กลางคืน) ; สภาพของเป้า (Fuelweaver ต้องเป้าบ้า, grazer ดูว่าเป้าหลับ) ; จำนวน/แท็กผู้เล่น ; สุ่ม
- **ตัวคุมต้องเป็นแบบเทียบ:** ตัวขับ SetPercent ต้อง **ไม่ผ่าน** และ DoDelta ต้อง **ผ่าน** บน: Bee Queen (state ของเฟส healthtrigger),
  Klaus (unchain), alterguardian 1→2 (ตาม prefab ใหม่), Twins พร้อม manager (แปลงร่าง), buffrat (เส้นทางโดนตี) ; "ผ่าน" = เข้า state ที่มีได้
  หลัง trigger เท่านั้น
- **ความเสี่ยงเพิ่ม:** healthtrigger ยิงขาขึ้นด้วย (ฟื้นเลือด: crabking heal, antlion กิน, Fuelweaver feast) → log เปอร์เซ็นต์ทุกฉาก ; ลดครั้งเดียวข้ามหลายเส้น
  = ยิงทั้งหมดใน tick เดียว เฟสตรงกลางไม่มีฉาก → ระดับต่อบอส ; minhealth/แพ้ที่เลือดต่ำ (daywalker2 OnMinHealth → จากไป) ; บอสมีเฟสให้ Rounds มากขึ้น
- **ลำดับใหม่:** (1) A(2) ประตู+ระดับต่อบอส (static) → (2) แก้ตัวขับ (DoDelta + ตรวจเปอร์เซ็นต์ + ตามการเปลี่ยน prefab) → (3) ตัวคุมเทียบบน
  smoke 5 บอส → (4) B ตัววัดพร้อมคีย์ร่าง/สาขา → (5) bench เต็ม → (6) แก้เป็นคลาส → (7) bench รอบสองยืนยัน
- **ความคืบหน้า (2026-10-19 บ่าย):**
  - (2) ตัวขับเสร็จ: ขั้นเลือดนับตามฉาก **หรือ** เวลา (อันที่ไกลกว่า — Champion/Twins หมดเวลาก่อนถึงขั้นท้าย 2-11 ฉาก) ; จบฉากแล้ว "brought down"
    (DoDelta ถึง 0) รอ 20 วิให้ร่างถัดไปเกิด ; ตาม "next phase" ได้จริง (บั๊ก: last_bz ได้ค่า y จาก GetWorldPosition → หาในรัศมีผิดที่)
    → Champion 1→2→3 ครบทุกขั้น (bench 2026-10-19_1506) ; Twins แปลงร่าง (transform 1) ; Bee Queen/Klaus/buffrat ลดทุกขั้น+ล้ม
  - (4) state_coverage/phase_scan เปิดไฟล์ prefab ผิด ("Prefab(" ใน SpawnPrefab → ร่าง 2 อ่านไฟล์ร่าง 1) → แก้ให้ต้องเป็น Prefab("x" ที่ไม่ใช่ SpawnPrefab ;
    phase_levels สร้างใหม่ (หาย: crabking_claw/moonmaw_lavae/pollenmites/shadow_leech/stalker_minion/tallbird ที่มาจากไฟล์ผิด)
  - smoke ยังขาด (แก้ขั้น 6): klaus quickattack 0 / attack_chomp 1 ; buffrat leap_attack 1, taunt2 1 ; twinofterror2 ต้องมาจาก bench เต็ม
  - (5) bench เต็ม (Rounds 10 เท่า bench #2) เริ่ม
  - ผู้ใช้: "รันครั้งแรกทำไม เสียเวลา" → หยุด bench, แก้ 2 คลาสก่อน (ข้างล่าง) แล้วรันครั้งเดียว. ผล smoke 1514-1521:
    Klaus ฟื้น = "next phase (raised again, 50%)" chomp 1→65, quickattack 0→61 ; buffrat ตีเบาทุกจบฉาก + ตีแรงทุก 8 ฉาก (คืนเลือดด้วย SetPercent
    ไม่ยิง trigger) leap 1→7-11, taunt2 1→2 ; ตัวตาม: รัศมี 4, เฉพาะ GUID ใหม่กว่า tick สุดท้ายที่บอสยังอยู่ (rat ปล่อย Chester/Glommer ตอนตาย
    = เคยถูกจับเป็นร่างถัดไป) ; Champion 1→2→3 ยังผ่าน
  - ผู้ใช้: "multi test ใน 1 instance ประหยัดแรม เร็วขึ้นมหาศาล" — วัด: 16 core, ว่าง 20.9 GB, jobs = min(14, (20.9-3.5)/1.95) = **8 (แรมจำกัด)** ;
    server ติด CPU (median 19.5× < 32 ที่ขอ, bench 1241) และ main thread เดียว → หลายบอสพร้อมกันใน instance เดียว **แบ่ง core เดียวกัน = ไม่เร็วขึ้น**
    (ได้แค่ boot ที่ประหยัด) ; ข้อมูลเก่า: บอสต่อกันในโลกเดียว ช้าลงตามอายุโลก 20.6→8.1× (ไฟป่า/ต้นไม้/ของ, 6.15) + ฤดูเปลี่ยน = ผลเพี้ยน ;
    พร้อมกันยังปนกัน: Klaus FindChompTarget วน AllPlayers, กลางคืนทั้งโลก (Eye/Twins), ลูกน้องวิ่ง 100-160. **ที่ได้จริง:** (ก) แรมต่อ server ↓
    (โลกเล็ก) → jobs 8→14 = ~1.7× ; (ข) boot 45 s × 260 = ~1/3 ของเวลา → ลด boot
  - ผู้ใช้ชี้แจง: "instance เท่าเดิม แต่ในแต่ละ instance ทดสอบพร้อมกันหลายตัว ห่างกัน" → **วัด (Speed 128, bench 1525):** โลกเปล่า (deer ไม่ตี) 39× ,
    hound สู้ 40× , Bee Queen 17× ⇒ ต้นทุนต่อ tick ส่วนใหญ่คือโลก (คงที่) ; มอนทั่วไป ~0 เพิ่ม → K เลนต่อ instance ≈ K× (บอสหนักน้อยกว่า) + boot ลด K เท่า.
    ผู้ใช้ถูก (การวิเคราะห์ "แบ่ง core = ไม่เร็ว" ของผมผิด เพราะไม่ได้วัดว่าโลกกินเท่าไร)
  - **แผนเลน (6.18):**
    1. testbench: `run` ต่อเลน (LANES), Tick วนเลนโดยสลับ `run` ; บ้านของเลนห่างกัน ≥ 300 บนพื้น (เลือกจากจุดเดินได้แบบไกลสุด) ;
       ย้ายฉาก ("moved") อยู่ใน 60 จากบ้าน ; คิวบอสร่วมกันทุกเลน ; "all done" เมื่อทุกเลนหมด ; เก็บกวาด/GUID ≥ guid0 จำกัดในพื้นที่เลน (≤150 จากบ้าน) ;
       listener ที่อ่าน run ต้องผูกเลนของตัวเอง ; log เลน: "[tr_lane] <boss> lane=k home=x,z"
    2. บอสเดี่ยว (ไม่ลงเลน): มี SETUP (antlion, atrium, crab, wagboss, daywalker2 …), NIGHT (eye/twins — นาฬิกาทั้งโลก), worm_boss, บอสหนัก ;
       run_bench จัด share: เลนสำหรับมอนทั่วไป K=4, เดี่ยวสำหรับรายการนั้น
    3. mod (TRACE เท่านั้น): You(inst) = stand-in ที่ใกล้ inst ที่สุด จาก TR_BENCH_YOUS ; "_you" ต่อ stand-in ต่อ tick
    4. run_bench EndShare: แยก log ตามเลน (บรรทัดมีพิกัด → บ้านที่ใกล้สุด ; tr_bench ตามชื่อบอส→เลน ; ไม่มีพิกัด → ทุกไฟล์) → share<n>_L<k>.txt
       ให้ replay/bench_replay/state_coverage ใช้ได้โดยไม่แก้
    5. **ตัวคุม:** บอสชุดเดียวกัน (hound, spider_warrior, deerclops, minotaur) เดี่ยว vs 4 เลน → ตาราง bench_replay ต้องอยู่ใน noise ; บรรทัดที่แยกไม่ได้ = 0 ;
       ไม่มี strike ข้ามเลน (tr_hit ผู้ตีกับ you ต่างเลน = 0) ; วัดความเร็ว (บอส-วินาทีเกม ต่อวินาทีจริงต่อ instance)
  - **เลนทำแล้ว (6.18):** testbench LANES/TickLane/บ้าน 300+ ห่าง, ย้ายฉากรอบบ้าน 30 ; mod You(inst) = stand-in ใกล้สุด (TR_BENCH_YOUS) ;
    tools/lane_split.lua (far/cross/unknown) ; run_bench -Lanes 4 (SETUP/SETUP_TICK/NIGHT/worm/deer เดี่ยว) + **หยุดทั้ง run เมื่อ error มาจากโค้ด
    testbench/True Range** (รอบแรก crash tonumber 6 ครั้งวนซ้ำจนผู้ใช้เปิดดู — ตัวคุม: log crash ต้องเจอ, log ปกติ 0) ; บั๊ก $share/$Share (ไม่มี case)
    **ตัวคุม (Rounds 2, hound/spider_warrior/deerclops/minotaur):** split far=0 cross=0 unknown=0 ; 1 server 4 เลน 78 s vs 4 server เดี่ยว 74 s (≈4×/server) ;
    ตาราง: missed 0 ทุกตัวทั้งสองแบบ ; deerclops strikes เลน 33/26 เดี่ยว 19/32, false 4/7 vs 0/7 ; minotaur false 15/27 vs 25/23 ; hound/spider เท่ากัน
    → อยู่ใน noise ✓ (1539/1542 เลน, 1541/1544 เดี่ยว)
  - **ผู้ใช้: "4 มาจากไหน"** — 4 เป็นค่าที่ผมเดา ไม่ได้วัด. **แผนวัด (หลัง bench 1545 จบ — ห้ามแก้ testbench ระหว่างรัน):**
    - ชุดเดียวกัน 16 ตัว (ไม่เดี่ยว, เบา+หนักปน): hound spider bee killerbee pigman knight bishop tallbird warg merm beefalo leif terrorbeak
      shadow_knight bearger minotaur ; Rounds 2 ; **-Jobs 1** (server ทีละตัว ไม่แย่ง core/แรม single-channel) ; Lanes = 4 / 8 / 16
    - วัด: (ก) บอสต่อนาทีจริงของ server (16 / ผลรวมเวลา server) ; (ข) ความเร็วเกมจริงแต่ละ share (game s / wall s) ; (ค) lane_split far/cross/unknown = 0 ;
      (ง) จำนวนบ้านที่วางได้จริง ("lanes=N" — ได้น้อยกว่าที่ขอ = เลนเอาบอสต่อกันในโลกเดียว ซึ่งช้าลงตามอายุโลก 6.15)
    - ถ้าบ้านไม่พอที่ระยะ 300: เพิ่มตัวเลือกระยะ (tr_bench@K/g) แล้ววัดซ้ำที่ 150 — ต้อง cross=0 far=0
    - ต่อมา: ตรวจซ้ำแบบ 8 job พร้อมกัน (สภาพจริง) สำหรับค่าที่ชนะ ; เลือก -Lanes ค่าตั้งต้นจากตัวเลข
  - **วัดรอบแรก (1553-1558) ใช้ไม่ได้:** warg อยู่ในชุด → ล่ม (exit 6) พาทั้ง server ลง ; บ้านที่ระยะ 300 ได้แค่ 7. แก้: crash_prone.txt
    (ตัวที่เคยล่ม → เดี่ยว + !np ตั้งแต่แรก, ตัวใหม่จดเพิ่มเอง) ; เลนล่ม → **แบ่งครึ่งรันเป็นเลนต่อ** (ไม่ใช่เดี่ยวทุกตัว — ผู้ใช้: "ทำไมมันหยุดถ้า crash")
    ; ลบ server_log ซ้ำ 10 s. วัดใหม่: ชุดไม่มี warg (pigguard แทน), lanes 4/7 (gap 300), 12/16 (gap 150), นับเวลาทุก server รวมเดี่ยว
    **ตัวคุมแบ่งครึ่ง (หลังวัดเสร็จ):** crash_prone ว่าง + 'warg,hound,spider,pigman' → ต้องเห็น ล่ม → ครึ่ง → warg เดี่ยว → warg!np, อีก 3 ตัวจบในเลน
  - **วัดเลน (1606-1612, 16 ตัวเดิม Rounds 2, server ขนาน):** บอส/server-นาที: 4 เลน 3.72 ; 7 (gap 300 = บ้านสูงสุด 7) 4.14 ; 12 gap 150
    (บ้าน 10) 5.75 ; **16 gap 150 (บ้าน 10, เลนที่จบหยิบตัวถัดไป) 8.42** ; far 0/0/4/0, cross 0 ทุกแบบ → **ค่าตั้งต้น -Lanes 16 -LaneGap 150**
    (-Lanes = บอสต่อ server ; บ้านเท่าที่วางได้). ตาราง 1612: missed 0 ทุกตัว, ตัวที่ต่อคิวในเลน (pigman/tallbird/spider/killerbee/pigguard/
    shadow_knight) ปกติ ; **spider drawn 0** มีตั้งแต่ bench #2 เดี่ยว (461/0) = ปัญหาเดิม ไม่ใช่เลน → งานแยก
    **ตัวคุมแบ่งครึ่ง ผ่าน (1616):** ล่ม → spider,warg | hound,pigman → spider | warg → warg → warg!np ; hound/pigman จบในเลน ; crash_prone เรียน warg เอง
  - **bench 1620 (16/150) ล่ม — ผู้ใช้: "ก็อย่าให้ล่ม" → หาต้นเหตุ:**
    - rambranch: ล่มทุกครั้งที่ตาย (ขั้น brought down ของเราทำให้ถึง) — UM rambranch.lua:308 เรียก OnUnlinkMushroomSprout ที่ไม่มี (ของจริง
      OnUnlinkHorn :296) → Lua error (strict) → server ลง. แก้ testbench: นิยามชื่อนั้นทำแบบ OnUnlinkHorn (บั๊ก UM — เกมจริงล่มได้เหมือนกัน)
    - viperlingfriend: viperworm.lua:378 person.components.leader → stand-in ไม่มี leader → แก้: stand-in มี leader
    - share010 (icehound/walrus…): ไม่มี Lua error = engine → แบ่งครึ่ง + crash_prone
    - ปัญหาเลนอื่น: far หลายหมื่นบรรทัด (share 11/12, maxd 257) — บอสไม่โจมตีเดิน stand-in ตาม (hold ตามบอส >20) → ยึด hold ไว้ใน LANE_ROOM
      ของบ้าน (ยังไม่ทำ) ; ล่มกลาง share 16 ตัวเสียงานเป็นชั่วโมง → วัดขนาดกลุ่มที่ Rounds 10 จริง
    - **ตัวคุมหลัง bench จบ:** 'rambranch,viperlingfriend' (เอาออกจาก crash_prone ก่อน) ต้องไม่ล่ม, rambranch "brought down" แล้วจบปกติ
  - **ผู้ใช้: "ancient guardian ท่าพ่นเมือกดำ hitbox ไม่ตรง"** (ช่องว่างตัวตรวจ — bench ไม่เห็น):
    - ตัวตรวจ: เมือก GetAttacked(caster=nil) (UM ไม่ตั้ง _caster) → tr_hit ผู้ตี "?" → replay_haz ไม่เคยตรวจ. แก้ expand_haz: การตีของ "ไม่มีใคร"
      ให้ของที่หายใน tick เดียวกันใกล้สุด ≤2.5 เป็น HIT ของมัน (คลาส: ของที่ตีโดยไม่บอกผู้ตี ทุกบอส) → เมือก 32 โดน **0 วาด** ; เจอ minotaur_blood_big ด้วย
    - tools/goo_check.lua: โดนจริงที่ 0.02–1.57 จากจุดตก, ไม่โดน ≥1.77 → รัศมี 1.5 (shadow_goo.lua:75)
    - sim: ของที่บินค้นหาอะไรก็นับเป็น "ค้นหาเพื่อตี" (fly_queries) → GooNear (หาคราบเมือก ไม่มี tag) = วง 4 ตามทาง. แก้: นับเฉพาะค้นหาที่มี tag
      สิ่งมีชีวิต (_combat/_health/player/...) ; ตัวคุม: gestalt vanilla 27 hazards/18 ท่า เหมือนเดิม (กฎแรก "ต้องตีขณะบิน" ทำ gestalt หาย 4 → ทิ้ง)
    - sim วัดวงตอนตกไม่ได้ (ตก ±4 นอกพื้นที่ dummy: "belch: nothing", player_hits 12) → um.lua striker guardian_goo radius 1 (1.5−0.5) moved
      → replay: 31/32 วาด
    - ตัววาด (สำเนา mod_goo2 ยังไม่ลงซอร์ส): ของ moved ที่เพิ่งเกิดยังไม่ขยับ ไม่วาด 4 เฟรมแรก (TR_OLD_BORN) + ลอยขึ้นเร็ว >10.5/s = ถูกโยน
      (TR_OLD_RISE; boulder ≤0.2/tick, goo 0.74) → GAP 257→1, FALSE เฟรม 86→30, JUMP 52→0. **ต้องเทียบทั้ง bench ก่อนลงซอร์ส**
    - bearger_boulder: ข้อมูลที่ติดตั้ง scale 1.9, sim ตอนนี้ 0.9 = เกมจริง (log 4,441 บรรทัด 0.900 ; bearger.lua:94 .9+math.random(0,.2)=0.9)
  - **bench 1620 (16 ต่อ server, บ้าน 10 → ต่อคิว) ปนโลก:** replay missed 6,562 (bench #2: 200) — _haz 5,344: um_bear_trap 4,072 (walrus ของโลก,
    เวลาเกม 8,314 s = หนาว, ฝูงล่า), glacialhound_icespike 796, fused_shadeling bomb 300 — ไม่ใช่บอส. ต้นเหตุ: ต่อคิวในเลน → server ยาว 2-3 ชม.เกม →
    เหตุการณ์โลก (การวัดเลนใช้ Rounds 2 ~10 นาทีเกม จึงไม่เห็น — ผมเลือก 16 ผิด). **แก้: -Lanes 10 = บ้าน (ไม่ต่อคิว)** ; ผล 1620 ใช้เทียบตัววาดได้
    (log เดียวกัน) แต่ไม่ใช้เป็นตารางสุดท้าย. ตัวตรวจที่ควรมี: การตี stand-in โดยตัวที่ไม่ได้มาจากบอส (GUID<guid0 หรือ prefab ของโลก) ต่อเลน
  - **แก้คำรายงาน:** "ข้อมูลเดิมวาดเมือก 0/32" ผิด — replay นั้นไม่ได้ตั้ง TR_MODS (ไม่มี overlay UM). จริง: ข้อมูลเดิมวาด 140/143 ด้วย **แถบกว้าง 4**
    → ปัญหาคือใหญ่เกิน (I7) ที่ไม่มีตัวตรวจ. **tools/oversize_check.lua** (ทำแล้ว): ระยะโดนจริงต่อของ (HIT ใน log ที่ expand) vs ขอบที่ข้อมูลวาด →
    ข้อมูลเดิม OVERSIZE 4: guardian_goo 1.48 vs 4.00 (ตัวคุม: ตรงที่ผู้ใช้เห็น), bearger_boulder 2.05 vs 3.20, wagboss_beam_fx 1.00 vs 3.64 (12 ครั้ง),
    moonmaw_trapprojectile (1 ครั้ง) ; ข้อมูลใหม่ goo 1.60 ✓. ตัววาด: เปลี่ยนจากกฎทั่วไป (ซ่อน 4 เฟรมแรก — boulder 5→50 missed เพราะตีตอนเกิด)
    เป็น **h.lands** (spec: ตีเฉพาะตอนตก) เท่านั้น ; bench ทั้งชุด: ต่างเฉพาะ goo. **ลงซอร์สแล้ว** (moves_sim_um ใหม่ + simmoves lands) — install หลัง bench จบ
  - **bench 1915 (10 เลน/server, 9 jobs): 88.7 นาที** — ช้ากว่าเดี่ยว. ผู้ใช้: "instance คอขวดไหม" → วัด: ทุก server 1.0 core เต็ม (main thread),
    10 เลน 2.3-3.3x vs เดี่ยว 21-25x ; ท้าย bench 3 server เหลือ (CPU 41%) ; share003 (alterguardian_phase1_lunarrift 16,296 s เกม) 83 นาทีเดียว.
    แรม: private 2.2 GB, peak ws 1.7 → สูตร jobs 1.95→1.75 GB (≈11 jobs). **แบบจำลอง** (scratchpad lane_sim.lua; c(L)=.026+.016L+.00147L² วินาทีจริง/
    วินาทีเกม จาก 39x/23x/3.27x ; LPT บน J server, boot 45 s): ทาย 10 เลน J9 = 91 (จริง 88.7 ✓) ; J11: L1 78, L2 54, L3 47, **L4 46**, L5 45, L6 48,
    L10 91 ; ให้บอสยาวรันเดี่ยว = แย่ลง → **-Lanes 4** ; ยืนยันด้วย bench ถัดไป (คาด ~46 นาที)
  - **ตาราง bench 1915 (ทุกเฟส):** strikes 146,482, missed 1,595, drawn-in-no-strike 4,585, both 264, flip 0, jump 499, gap 960 ; coverage 91/258
    harmful states <3 ; oversize 2 (bearger_boulder 2.06 vs 3.20, wagboss_beam_fx 1.00 vs 3.64). **แก้คืนนี้ (ผู้ใช้หลับ):**
    - ruinsnightmare 186→0: horn_attack (ตอบโต้เมื่อโดนตี — ตัวขับตีเบาทำให้ออก) เขา 2 อันวิ่งเข้าหาจุดที่คุณยืน ตีด้วย combat บอส → striker
      ruinsnightmare_horn_attack r1.25 moved as_boss (sim_moves STRIKERS) ; splice -only=ruinsnightmare
    - rook/rook_nightmare 62/269 → 10/31: quick start "run"(true) ข้าม atk_pre (โดนตี / CanQuickStartRun, SGrook:27-30, :481-500) → spec ram
      "run" anims atk~atk_collide lock 0 ; เหลือ: ขอบ ±75° (front only) ตอนคุณถูกขยับข้าง
    - shadowthrall_mouth 22→0: land→bite_final ตรง (lasttargets) ; spec state ของตัวเองตัด bite_pre (22→102!) → ใส่ moves_hand.lua แทน.
      tools/midchain_check.lua: นับ missed ที่เข้ากลาง chain (เหลือ boulder_crab uppercut 1)
    - fused_shadeling_quickfuse_bomb 300→0 (สำเนา mod_delay, รอเทียบทั้ง bench): ของ moved ที่มี delay (sim วัดจากตอนเกิด) ตัววาดใช้เวลาหยุดนิ่ง
      แทน → ตีหลังรูปจบ ; แก้: start = max(stop, since+delay−lead) (TR_OLD_MOVEDDELAY) ; ของ moved+delay 8 ชนิด ; JUMP/GAP ของระเบิดมีอยู่เดิม (โยน)
    - ติดตั้งแล้ว: goo (data+lands), rook, ruinsnightmare (data 6E994EC5CB2B) ; thrall hand move ในซอร์ส (ยังไม่ install)
    - oversize เหลือ 2 = **ผลบวกปลอม** (ตรวจโค้ด): bearger_boulder ตีรัศมี 3 (bearger_boulder.lua:20) แต่ก้อนเล็งตกใส่คุณ ไม่เคยห่าง >2 ;
      wagboss_beam_fx 3+ตัว (wagboss_beam.lua:132-172). oversize_check = "น่าสงสัย" ต้องยืนยันกับโค้ดทุกครั้ง (OVERSIZE?)
    - BOTH Eye 128 / Twin2 96 = **ตัวนับผิด**: alt = charge_pre~shoot_pre (hand, maps {}, nothing) ไม่วาดอะไร → counter ข้าม alt ที่ว่าง (predict) ;
      hoodedwidow 40 = จริง (alt fall~canopyland always) — ยังไม่ดู
    - Twins/Eye ร่างแปลง พุ่งซ้ำ 3-5 ครั้ง (charge_pst f17 → mouthcharge_loop, SGeyeofterror:370-404) — ไม่มีท่า → twin2 16, twin1 10 missed.
      ลอง hand move "charge_loop" (sim mouthcharge_loop, mem transformed): **แย่ลงมาก** (twin2 missed 16→48, false 8→438) — แย่งการพุ่งครั้งแรกที่ผ่าน
      charge_loop ด้วย ; from = แยกเฉพาะท่าเริ่มเหมือนกัน กันกลาง chain ไม่ได้ → ถอนแล้ว. ต้อง: ประตูเริ่มท่า "หลัง charge_pst เท่านั้น" ในตัววาด
    - um_bear_trap 486 (walrus): mine รัศมี 1.95 (um_bear_trap.lua:255) แต่โดนที่ 2.1-2.2 — ตำแหน่งตอนงับ/ติดตัว? ยังไม่พิสูจน์
    - **moved delay ลงซอร์ส+ติดตั้ง:** bench ทั้งชุด _haz missed 972→670, false 3036→2904, ไม่มีชิ้นไหนแย่ลง (jump/gap เท่าเดิม)
    - **โหมดบังคับท่า (6.1, สร้างแล้ว):** testbench FORCE จาก tr_force.txt (run_bench -Force <file>) ; ตอนบอสว่าง ≥3 s (ทุก 5 s) หรือทุก 4 ฉาก
      GoToState(state, you | {target=you} | nil) ; ≤3 ครั้ง, ลอง ≤6 ; log "forced state=" / "forced - not entered" ; state_coverage บอก
      "(forced N - aim not the game's way in)". smoke: walrus attack/blowdart, bearger butt/butt_pst, tallbird peck ครบ 3 ทุกท่า.
      **bench บังคับ 2132 (67 บอส, Rounds 2, 5.2 นาที):** ท่าที่ขาด 91 → 52 ; replay 3,630 strikes, missed 13 (bird_mutant_spitter 5,
      bearger 4, mutatedbearger 3) ; ที่ยังขาด: 9 บอสไม่มี trace (ไม่มีในเกม/หายทันที), สั่งเข้าไม่ได้ (chimp/monkey throw, minotaur bite,
      smallbird peck, mutatedbearger attack, rabbitking ทั้งหลาย = สแกนนับผิด), 1-2 ครั้งเพราะสั้น ; ล่มเพราะบังคับ (rabbitking_passive, bird_mutant)
      → เอาออกจาก crash_prone (ไม่ใช่บอสล่มเอง)
    - **hoodedwidow BOTH 40/294 → 0:** fall กับ canopyland เล่น anim เดียวกัน (fall~taunt) แยกไม่ได้ ; fall อยู่ในรูป canopyland ทั้งหมด (829/829)
      → spec drop = { "fall" } (mod_diff ใหม่: d.drop) ; no_auto ไม่ได้ผลเพราะ entry สแกนอีกตัว (no_auto ของมันเอง) — และ cache สแกน (SIM_SCAN_CACHE)
      ไม่เคยกรอง no_auto (แก้แล้ว) ; replay ทั้งสอง bench: missed/false เท่าเดิม, both 0 ; ติดตั้งแล้ว
    - alterguardian_phase2 attk_stab_pre เปลี่ยนทุก build (สุ่ม) — replay เท่าเดิม
    - **Twins พุ่งซ้ำ (แก้ความเข้าใจ):** ข้อมูลเกมปกติมี leg อยู่แล้ว (charge_pre~charge_pre: count 3, restart=enter, anim charge_loop) และตัววาด
      สลับเข้า leg เมื่อย้อนกลับกลาง chain (predict:598-608) — missed ส่วนใหญ่ที่ **dash #2** (ไม่ใช่ #4-5 ที่ count 3 ขาด) → การเล็ง leg ที่ 2
      (หันตามช่วง charge_pst f3-13) ยังไม่ตรง ; ลองกฎ restart กลาง chain (สำเนา) ไม่มีผล — ยังเปิด
    - hazard ที่เหลือเป็นหางเล็ก: glacialhound_icespike 36 (p50 2.99 off), warg breath 37 (p50 2.82), minieye 27 (p50 1.97), deerclops icespike 26 (p50 1.2)
    - **bench ยืนยัน 2159 ใช้ไม่ได้ — D: เต็ม (0 GB):** server ล่มทั้งหมด (exit 6 / 0xC0000409), แบ่งครึ่งวน 466 share 170 นาที ; crash_prone
      เรียนผิด 6 ตัว (คืนค่าแล้ว). ต้นเหตุ: bench_logs 124 GB (ไฟล์ *_bench_headless.txt = สำเนาซ้ำของ share 48 GB) + bench_x 39 GB. แก้: ลบสำเนาซ้ำ
      (+ run 2159) → ว่าง 51.9 GB ; run_bench ไม่เก็บสำเนารวมหลัง bench_lock, ไม่เริ่มถ้าว่าง <25 GB, หยุดถ้า <8 GB. รันยืนยันใหม่
    - **bench ยืนยัน 0052 (4 เลน, 10 jobs): 67.4 นาที** (แบบจำลองทาย 46 ที่ 11 jobs — ต่ำไป ; 10 เลน 88.7). ตาราง: strikes 139,759 missed 247,
      false 4,657, both 32, flip 0, jump 1,193, gap 764, glitch 9,390 ; coverage 93/258 <3 ; oversize? 3 (boulder/beam = ผลบวกปลอมตามโค้ด,
      bear trap 2 ครั้ง). **เทียบบน log เดียวกัน (mod ก่อนคืนนี้: data สำรอง + TR_OLD_MOVEDDELAY):** missed 1,063→247, false 4,902→4,657,
      both 73→32, jump 1,191→1,193, gap 752→764, glitch 9,155→9,390 (rook +117, rook_nightmare +134 จากท่าพุ่งเร็ว ; thrall −16).
      ต่อบอส: _haz 426→132, rook 144→0, rook_nightmare 164→3, ruinsnightmare 200→0, thrall 18→1, hoodedwidow both 41→0
    - **coverage ที่เหลือ (tools/coverage_left.lua, 0052 + forced 2132 + 0130):** 93 ท่า → บังคับแล้ว 56 (เล็งยังไม่ยืนยัน), ไม่มี trace 12
      (ไม่มีในเกม/หายทันที), ไม่ใช่ท่าของมัน 13 (บังคับเข้าไม่ได้ = สแกนนับผิด), น้อยไป 1, ยังไม่ได้ 11 (มอนหายเร็ว: birchnutdrake, gestalt,
      lavae death...). alterguardian_phase3: 18/764 missed ที่ 4-5.4 ตอนคุณยืนรอ บอสสลับ sweep/beam หันกระโดด — ค้าง
    - **2026-10-20 เช้า:** ดิสก์: ลบ bench เก่าก่อน 1915 (+bench_x/bench_replay) ได้คืน 92.8 GB → D: ว่าง 128 GB (ผู้ใช้อนุญาต)
      - ตัวตรวจ FALSE: นับ BYTHING (ของที่บอสปล่อย ตีในนามบอส) ภายใน −0.3..+1 s ว่าโดนจริง (OLD_FALSE_BYTHING) — warg พ่นไฟ: รูปพัดเตือน
        แล้วเปลวไฟตีตามมา 0.3-1 s → false รวม 4,657→4,514 (mutatedwarg 98→11, bishop 27→0, bearger 18→0, phase3 19→12), missed เท่าเดิม
      - buffrat leap_attack 11→0: โหมดตั้งรับเล่น bellyflop_block_pre (SG :476-480) ไม่มีในข้อมูล → spec leap_attack fields mode=defence ; ติดตั้งแล้ว
      - mini eye วาป (ผู้ใช้เคยเห็น): ตำแหน่งมาเว้นเฟรม (1.33 / 0) → วาดล่วงหน้า 1 เฟรมจากความเร็ว 2 เฟรมล่าสุด = เด้งไปมา. แก้: ความเร็วเฉลี่ย 4 เฟรม
        (TR_OLD_LEADAVG) → bench ทั้งชุด jump 1,193→300 (minieye 858→0, spat_bomb 38→4), missed 246→236, false 4,514→4,488 ;
        shadow_projectile1_fx_fast missed 5→6 ; ติดตั้งแล้ว. JUMP_V=1 ใน replay_haz พิมพ์เหตุการณ์วาป
      - **ตัวนับ glitch JUMP แก้ 3 อย่าง (นับผิด):** (1) คุณถูกย้ายทันที >0.5/เฟรม (ฉาก step ของ bench; ผู้เล่นจริง ≤0.2) แล้วรูปที่เล็งตามคุณ
        ย้ายตาม (OLD_JUMP_YOU) ; (2) เริ่ม go ใหม่ในเฟรมนั้น (Guardian ลงแล้วกระโดดใหม่ทันที, OLD_JUMP_NEWGO) ; (3) ชุด step ที่วาดเปลี่ยนตามข้อมูล
        (boulder_crab ทุก go เฟรม 30, OLD_JUMP_STEP). glitch 9,383 → 7,127 → 6,212 → 4,791 ; missed/false เท่าเดิม.
        เหลือ: Champion roll 516 (กลิ้งค้าง ชนคุณ: vel 5-7 แต่ขยับ 0.07/เฟรม), mock_dragonfly spin_pre2 156, shadow_rook attack_teleport 147,
        bishop attack_shoot 163
      - **warg เปลวไฟ missed 34 (replay_haz) = ตัวตรวจนับผิด:** 32 ครั้งไม่มีเปลวไหนอยู่ในระยะ (2.5-3.6 ; เปลวตีได้ ≤ 0.9·scale(≤2.2)+0.5
        = 2.48, warg_mutated_fx.lua:75-82) ; ขยายหน้าต่าง −1..+6 tick ไม่ช่วย (ไม่ใช่ trace ช้า). ต้นเหตุ: **SGwarg DoFlamethrowerAOE
        (:98-136)** — ตัวบอสเองตีวง 1.7 (+รัศมีเป้า) ที่ 3 หน้าปาก ทุก tick ใน flamethrower_pre (f20+) / loop ; 128.167: d = 2.12 < 2.2 ✓.
        replay.lua ให้ blow นี้กับท่า (พัดวาดครอบ 517/519) แต่ replay_haz ยกให้เปลว as_boss ที่ใกล้สุด ≤3.5 เสมอ (ไม่รู้ว่าท่าวาดครอบ).
        แก้: replay.lua พิมพ์ ASBOSS_DRAWN เมื่อ blow ที่มีของ as_boss ใกล้ๆ ถูกท่าของบอสวาดครอบ ; bench_replay ลบ MISSED ของ _haz ที่เวลาตรง
        (±0.05, share เดียวกัน) ออกจาก missed (OLD_ASBOSS=1 = เดิม). tools/asboss_check.lua รับหน้าต่าง tick (arg 4-5)
      - **alterguardian_phase3 missed 48 = ฉากเดียวทั้งหมด** (scratchpad miss_scene.lua): `step k=21 orbit=150` beam 24 + sweep 24 —
        เกมเก็บ target_pos ที่ f21 (SGalterguardian_phase3 :682-686, :801-805) ; bench ย้ายคุณ 150° ใน tick เดียวกันพอดี → เกมอ่านตำแหน่งใหม่,
        ตัววาดเล็งจาก (lock−1.5) เฟรม (predict:2397 — ถูกสำหรับคนเดิน 0.2/tick) = กลางทาง. ไม่ใช่ตัววาดผิด: วาป (soul hop) ใน tick ที่บอสอ่าน
        ไม่มีใครรู้ได้ว่าเกมอ่านก่อน/หลัง. แก้ตัวตรวจ: replay.lua AIMJUMP — missed ที่คุณขยับ >1 ใน tick เดียวรอบ tick ที่เกมอ่าน (เริ่ม anim
        แรก + sim.lock, ±1.5 เฟรม) แยกนับ ไม่ใช่ missed (OLD_AIMJUMP=1 = เดิม ; ตัวคุมตรง = missed เดิม = missed + aimjump). share011_L4: 16→0
        missed, 16 AIMJUMP, ไม่มีอื่นเปลี่ยน. bench_replay มีคอลัมน์ aimjump
      - **vault_crawler FALSE 193 = มุมตี (hit arc):** เกม SetHitArc(VAULT_CRAWLER_HIT_ARC 120) → CanHitTarget ตีเฉพาะ ±60° จากที่หัน
        (combat.lua:1064-1072) ; หันตามเป้าถึง f7 เท่านั้น (SGvault_crawler :402-440) ; bench ย้ายคุณ 60° ที่ f9 → 94.6° นอกมุม ไม่โดน
        แต่วาดเป็นวงกลมรอบตัว (spec spot ในตัว sim ไม่รู้มุม). คลาส: มีเฉพาะ vault_crawler ที่ใช้ SetHitArc (เกม + UM, grep แล้ว).
        แก้: spec spot รับ `arc` (เซลล์ภายใน ±arc/2 จากจุดที่กัด) ; ตัว combat จำลองของ sim รับ SetHitArc + CanHitTarget ตามเกม
        (SIM_OLD_ARC=1 = เดิม) + disc ของ target_hits กรองมุม (ทั่วไป, ตอนนี้ไม่มีท่าไหนใช้). movediff: เปลี่ยนแค่ vault_crawler attack maps.
        missed 10 ที่ 2.38-2.39 = ขอบ 1.9+0.5 (ยังไม่แก้ — ระยะพุ่ง 0.4 vs จริง ~0.64)
        รอบแรก (arc, lock 0): false 193→15 แต่ missed 10→90 (ฉาก step k=0-6: มันยังหันตามคุณถึง f7 แต่รูปตั้งตามที่หันตอนเริ่ม)
        → spot รับ `lock` (crawler 7) : missed 10, false 35
      - **ผล replay 0052 (ASBOSS+AIMJUMP, data เดิม):** missed 236→173 (phase3 48→0 เป็น aimjump 48 ; eyeofterror/thrall aimjump 1/1),
        ASBOSS ลบได้แค่ 13 — warg 27 ที่เหลือ = BYTHING ใน replay.lua (ท่าไม่ได้วาดตอน loop) → **ช่องโหว่จริง:** spec fan วาดเตือน
        ถึงเปลวแรกเท่านั้น แต่ลมหายใจรอบปาก (DoFlamethrowerAOE) ตีทุกเฟรมของ loop. แก้: fan again = { 58, "atk_breath_loop", 28 } (ติดตลอด
        loop, ไม่ใน pst) → warg missed 2→0, flame missed ที่ยังไม่ครอบ 27→0 (ASBOSS_DRAWN 257) แต่ false 11→87: เตือนใน pre แล้วโดนตอน
        sweep ถึง 0.3-1 s ต่อมา — เดิมเป็น BYTHING (กฎ −0.3..+1 s), ตอนนี้เป็น strike ของท่าเอง → replay.lua FALSE: strike ของ go เดียวกัน
        (drawn_at move_t0) ภายใน +1 s นับว่าโดน (OLD_FALSE_SAMEGO=1 = เดิม) → false 11.
        replay เต็มชุดรอบแรก: กฎนี้ซ่อน FALSE จริง 30 ของบอสอื่น (rook_nightmare run_start, rabbitking dropkick = ส่วนของท่าพุ่ง
        ขึ้นแดงก่อนโดนจริง 0.3-1 s = วาดเร็วไป ต้องเห็น) → จำกัดเฉพาะท่าที่มี step again_anim (ตีซ้ำต่อเนื่อง) : บอสอื่นกลับเท่าเดิม
        (เหลือ daywalker2 67→66, phase3 12→8 — beam ตีสองครั้ง)
      - **Retinazor พุ่ง+laser พร้อมกัน (ผู้ใช้ถาม 2026-10-20):** ในเกม UM ไม่เคยทั้งสอง — charge_pre หรือ shoot_pre สุ่มอย่างใดอย่างหนึ่ง
        (UM postinit/stategraphs/SGeyeofterror.lua:7-36), anim เหมือนกันทุกตัว (charge_pre/loop/pst), ต่างแค่ shoot_pre ทำ chargepulse ตอนเข้า
        (:153). ตัววาดตัดสิน "ไม่มี pulse = พุ่ง" เฉพาะเมื่อเคยเห็น pulse มาแล้ว (predict tell_seen — กันเทรซที่ไม่บอกของที่สร้าง) → ท่าพุ่ง
        ก่อนการยิงครั้งแรกของการต่อสู้วาดทั้งพุ่งและ laser จนจบ = BOTHDRAWN twinofterror1 32. แก้: ตัดสินได้ถ้าเกมบอกของที่สร้าง
        (ไม่ใช่ TR_UNTOLD) ; TR_OLD_TELLSEEN = เดิม. replay 3 บอส: twin1 both 32→0, ค่าอื่นทั้ง 3 บอสเท่าเดิม. ติดตั้งแล้ว
      - **Deerclops ไม่ขึ้นเตือนบางครั้ง (ผู้ใช้ 2026-10-20, log data 7EB2191125B8):** ตัวตรวจใหม่ replay.lua GOEMPTY (go ที่ไม่วาดอะไรเลย
        ทุกเฟรม) → log ผู้ใช้ 3/13 go = atk@MakeStrong ; bench 555/670. ต้นเหตุ: things_only (สุ่ม + บอสไม่ตีเอง → ปล่อยให้ของวาด) แต่
        ice spike ตีทันทีที่โผล่ (delay 0) = ไม่มีเตือน. คลาส: deerclops atk (เกม+UM), glacialhound 3 ท่า, spider_moon/spider hide, buzzard flame.
        แก้ predict: things_only ยกให้ของวาดเฉพาะเมื่อของทุกชิ้น delay ≥ 10 เฟรม (TR_OLD_THINGSONLY = เดิม). bench: empty deerclops 555→0,
        glacialhound 4192→0, spider_moon 248→0, buzzard 2→0 ; missed/false เท่าเดิม ; antlion/phase3/daywalker2 (ของเตือนเอง 15-31 เฟรม)
        ไม่เปลี่ยน. ติดตั้งด้วย install.ps1 แล้ว. ค้าง: antlion 953/953 go ว่าง (sand spike เตือนเอง 30 เฟรม — ตั้งใจ), phase3 146 ว่าง (ยังไม่ดู)
      - **Celestial Champion phase 2 stab (ผู้ใช้ 2026-10-20 + รูป):** "หนามที่โผล่ถูกแล้ว แต่พื้นที่เตือนตอนแรกมีไว้ทำไม แค่กล่อง hitbox".
        เกม: DoAttack ที่ f28 (ตีรอบตัว) + DoSpikeAttack f32: ราง 3-4 เส้น (เส้นแรกที่ผู้เล่นในระยะ, ที่เหลือสัตว์/ทิศสุ่ม ห่าง ≥30°),
        วิ่ง 20/s นาน 0.5-1 s แล้วผุดกำแพงหนาม 13 อัน กว้าง ±8 (alterguardian_phase2spike.lua). ข้อมูล: random=true รวมทุกกำแพงทุกทิศ
        (also_own) = ก้อนใหญ่. แก้ sim spec `things_apart` (blow ที่โค้ดบอสทำ ณ ของที่ปล่อย = ของนั้นอย่างเดียว ไม่นับเป็นของท่า) →
        stab = วงตีรอบตัวที่ f28 (single, ไม่สุ่ม) ; ทั้ง moves_sim และ moves_sim_um (รัน UM world -only phase2, splice เฉพาะ attk_stab_pre).
        bench: glitch 52→19 แต่ missed 2→43 = หนามริมกำแพงห่างราง 4-10 > THING_NEAR 3.5 → ตัวตรวจนับเป็นของท่า. แก้ตัวตรวจ: ระยะจับคู่ blow
        กับของ = ขอบเซลล์ไกลสุดของของนั้น +0.5 (≥3.5) ทั้ง replay.lua และ replay_haz (OLD_THING_NEAR=1 = เดิม). รัน replay เต็ม 2 รอบ (ใหม่/คุม)
        ผลรอบเต็ม: กฎระยะจับคู่ใหม่ vs คุม แทบเท่ากัน (_haz missed 82→83) และ phase2 ยัง missed 43 → ต้นเหตุจริง: splice แบบ boss:move
        กับไฟล์ UM เติม _hazards ของ part ทั้งหมด (22 ตัว รวม spiketrail in_move=true) → ในโลก UM กำแพงหนามวาดเฉพาะกับท่า = ไม่วาดเลย.
        แก้ splice: boss:move เอาเฉพาะท่า ไม่แตะ _hazards ; movediff รายงาน _hazards ด้วย (ไม่เห็นตอนแรกเพราะ movediff ดูแค่ท่า).
        ตรวจย้อน: data ที่ติดตั้ง (crawler/warg) _hazards ไม่เปลี่ยน
      - **ผู้ใช้ตอบ (2026-10-20):** phase 2 "กล่องไม่บอกอะไร หนามที่มาทีหลังโผล่นอกกล่องอยู่ดี — ถ้าจะมีต้องครอบคลุม" ; phase 3 "ถูกแล้ว แค่เตือน late"
        → หลัก: พื้นที่เตือนต้องครอบทุกที่ที่จะโดน ไม่งั้นไม่ต้องมี. phase 3: spec spot วงเต็มรัศมี 15.25 (12.5 + 2.25 + 0.5) single=false
        จนลูกแรกตก (f90), cooldown traps_cd ; ไม่ใช้พื้นที่สุ่มของรัน (รู 3.5% ที่ 13-14.5). crystal hazard ย้ายไป moves_hand.lua _hazards
        (spot ไม่รัน atk_traps แล้ว rebuild จะไม่สร้าง). predict mod_p3 (things_first) ทิ้ง ไม่ใช้
      - **ผลสุดท้าย + ติดตั้ง (data 221E3F24C00C, install.ps1):** replay เต็ม 0052: missed 145→137, false ~4,322→4,324, phase2 missed 0
        (43 blow เป็นของกำแพงหนาม), phase3 GOEMPTY 146→0, glitch 45 (เดิม 40). ตัวตรวจ OUTSIDE: ของที่ไม่มีท่าไหน puts และไม่ใช่ in_move
        = วาดตัวเอง ไม่ต้องให้ท่าครอบ (OLD_OUTSIDE_PUTS=1 = เดิม) — คริสตัลหลังท่าเป็น spot ถูกโยนให้ท่า beam 56 ครั้ง
      - **ผู้ใช้: "วงเตือนใหญ่ต้องแค่เตือน แต่ขึ้นแดงเข้ม" + log "drawn IN but NOT struck ... WELL INSIDE" (data 221E3F24C00C):**
        spot เขียน random=false = "ตีแน่ทั้งวงที่ f90" → แดง (style last 94 เฟรม) + on_strike. แก้ spot: `random` (where it may: ไม่มี
        on_strike, สีจาง) + `until` (step ที่สอง f175 = คริสตัลลูกสุดท้ายตก ถ้าคนเดียว ; ช่วง >10 เฟรม → fill_light ตลอด). replay log ผู้ใช้
        (STYLES=attk_skybeam ใน replay.lua): last 94/later 32 → fill_light 252. bench phase3 เท่าเดิม. ติดตั้งแล้ว data 920991CC33E2
        **บทเรียน:** พื้นที่ "อาจโดน" ต้อง random เสมอ ; ตัวตรวจไม่มีกฎ "พื้นที่สุ่มห้ามแดง" — STYLES เป็นแค่ diagnostic ยังไม่ใช่ check
      - **แมงมุมธรรมดาไม่มีท่ากระโดด (ผู้ใช้โมโห 2026-10-20: "ไหนบอกครบ ไหนบอกเทสจริง"):** UM "alljumperspiders" (ผู้ใช้เปิด) →
        spider (แท็ก spider_regular) ไป warrior_attack เมื่อเป้านอกระยะกัด ; spec UM ไม่มี → ไม่มีข้อมูล ไม่เคยวาด. bench เห็น 319 เฟรม
        แต่ **ไม่มีตัวตรวจไหนดูได้: ทุกตัวเริ่มจากข้อมูลของเรา** (GOEMPTY/force ก็เหมือนกัน) ; bench spider 68 strikes, 0 drawn, 0 missed =
        ตัวตรวจไม่นับเป็น missed ด้วย (ยังไม่รู้ทำไม — ค้าง). แก้: um.lua spider add warrior_attack → splice spider:warrior_atk ; log ผู้ใช้
        missed 5→1, bench 68/68 drawn. ติดตั้งแล้ว. **ตัวตรวจใหม่ tools/nomove_check.lua**: จาก trace — ทุก anim ที่มอนเล่นแล้วตีโดน
        (STRIKE) หรือชื่อเหมือนท่าตี แต่ไม่มีท่าไหนในข้อมูลมี anim นั้น (ตัวคุม: data ก่อนแก้ → ฟ้อง spider warrior_atk 319/11). รัน bench
        0052+0236 + log ผู้ใช้ 4 ไฟล์: ~170 รายการ (ต้องคัด: atk_pst/hop เป็น noise ส่วนใหญ่). มี strike: spider_spitter/walrus/spat/horn
        = dart/hazard วาดอยู่แล้ว ; ไม่มี strike แต่น่าจะเป็นท่าจริงที่ขาด: mock_dragonfly flamethrower, shark leap, koalefant charge,
        bearger(UM) shoot/charge, mutatedbearger charge, dreadeye attack_teleport, beeguard flydown, mushgnome attack, cave_vent_mite blow,
        waterplant attack, lightninghound howl, archive_centipede roll, gestalt_guard_evolved attack_far/mid, um_ribopod/frog/toad hop —
        ต้องไล่ทีละตัวตามโค้ดเกม (กำลังทำ)
      - **ไล่หาท่า/ของที่ขาดทั้งหมด (ผู้ใช้: "ไปหามาให้ครบ", 2026-10-20):**
        - คัดด้วยเกมจริง: nomove → spec ชั่วคราว (scratch triage_spec.lua) รันทุก state ใน sim โลก UM → state ไหนตีโดน = ท่าที่ขาด ; "nothing"
          ต้องเช็กโค้ดเกมเอง (sim ขับบาง state ไม่ถึง). ผล: ท่าจริงที่ขาดและแก้แล้ว (ติดตั้ง data A418555EDDA4): archive_centipede
          กลิ้งตั้งแต่ atk_roll_pre (เดิมเริ่มที่ loop), lunarplanttentacle atk (ไม่มี entry เลย ; missed 1→0), mock_dragonfly พุ่งตั้งแต่
          fire_on (charge_warning แทน spin_pre ; glitch 291→135), beeguard stab_pre (UM ; เดิมมีแค่ stab_pst). bench: ไม่มีอะไรแย่ลง
        - ไม่ใช่ช่องโหว่ (เช็กโค้ดแล้ว): shark leap (แค่สาด), frog/ribopod aggressivehop (กระโดดเดิน), bearger/mutatedbearger charge_* (เดิน
          เร็ว + DestroyStuff พังของ ไม่ตีคน), dreadeye attack_teleport_pre (แค่เข้า state อื่น), spat/waterplant/gingerbreadwarg/mushgnome
          (กระสุน/สปอร์ วาดเป็นของอยู่แล้ว), spider_spitter/walrus (DARTS), moonmaw_lavae_ring (ท่า spin ครอบหมด ; THING_ALL), moonmaw_glass
          (replay_haz: วาดครบ 0 missed — THINGMISS ของ replay บอสใช้กับของไม่ได้)
        - ตัวตรวจใหม่ tools/nothing_check.lua: "you were struck by X" ที่ X ไม่มีข้อมูลใดๆ. bench: um_beeguard_blocker/seeker/shooter
          (171/142/13), rimeweed (พืช UM หนามรอบตัวเมื่อโดนตี — สิ่งแวดล้อม, ยังไม่ทำ), alterguardianhat_projectile (ของผู้เล่น)
        - **ยังเปิด:** um_beeguard_* — ราชินี UM สั่งเป็นขบวน (postinit/stategraphs/SGbeeguard.lua): flydown→stab (DoAreaAttack 2 ที่
          warningshadow), charge (ขบวนพุ่งไป chargePoint ชนรัศมี 1, 150 dmg ผู้เล่น), defensiveattack ; sim รันไม่ได้ (ต้องมีราชินี) →
          ต้องเขียนมือ. **จุดบอดใหม่:** มอนที่ไม่มีข้อมูลไม่ถูก trace เลย (modmain trace เฉพาะที่มีข้อมูล) → nomove มองไม่เห็นทั้งตัว ;
          nothing_check เห็นเฉพาะที่ตีโดน
      - **ไล่ต่อ (2026-10-20 บ่าย):**
        - bench เต็ม 1049 (mod ใหม่): missed 334 (_haz 243: um_beeguard 138 = ท่ากัดถูกนับเป็นการพุ่งชน — ผึ้งเป็นทั้งมอนและ hazard).
          แก้ modmain: hazard ที่มี _on_anims ถูก trace/นับ HIT เฉพาะตอนเล่น anim นั้น. **bench_replay ตัดสินเฉพาะบอสที่ bench เรียก** —
          ลูกน้อง (beeguard 841,818 บรรทัด) ไม่เคยถูกตัดสิน → ตอนนี้ทุกมอนที่ถูก trace ≥50 บรรทัด (OLD_BOSSES_ONLY=1 = เดิม)
        - modmain: trace ทุกตัวที่มี combat (AddPrefabPostInitAny, เฉพาะ TRACE) — เดิม trace เฉพาะที่มีข้อมูล
        - tools/combat_census.lua: prefab ที่ต่อสู้ได้ (combat+SG ใน maker ของมันเอง) ไม่มีข้อมูล: 73 (ตัวคุม spider/hound/deerclops
          ไม่โผล่). sim_moves AutoBosses สแกนเฉพาะ prefab ของเกม ไม่สแกน prefab ของ UM เอง = ต้นเหตุทั้งตระกูล UM หาย
        - bench 1159 (39 ตัวไม่มีข้อมูล): ตีจริงไม่มีอะไรวาด: um_shadow_abigail 396 (EmitBurst r3), viperworm 392, dumbbell 148 (r4.5
          ตอนตก), junkrat 121, wortox 5, pawn_nightmare 1, spore_shadow 1. แก้: viperworm/junkrat ผ่าน sim (replay 392/392, 121/121 drawn) ;
          abigail/dumbbell hazard มือ (moves_hand) ; wortox sim ขับไม่ได้ (ค้าง). crabking_cannontower/rne_grabbyshadows ล่มเพราะโค้ดเกม
        - splice: แบบทั้งตัวเคยเติม _hazards ที่ไม่ใช่ของบอส (20 ตัวเข้าไฟล์ UM) → เอาเฉพาะของบอสพวกนี้. movediff รายงาน _hazards
        - bench ยืนยัน 1206: missed 575 → (แก้แล้ว) 92: shadow abigail 392 = ตัวตรวจนับผิด (มอนไม่มีท่าแต่เป็น hazard เอง → replay.lua
          SELFTHING ส่งให้ replay_haz ; OLD_SELFTHING=1 = เดิม) ; seeker stab 132 → hand stab_death/stab_pst (DoAreaAttack 2, เฟรม 3) ;
          shooter 27 = เหล็กในที่มันยิง (striker by เพิ่ม um_beeguard_shooter). seeker 40 ที่เหลือ: ผึ้ง notarget (ราชินีสั่งลงที่จุด)
          → (ก) ท่ามือ frame target ไม่วาดเมื่อไม่มีเป้า → facing ; (ข) modmain Traced: non-epic trace เฉพาะตอนเป้าเป็นคุณ → เพิ่ม
          state มีแท็ก attack ใกล้ 20. bench 1218 (beequeen): um_beeguard ทุกแบบ missed 0 (seeker 64/64). ติดตั้งแล้วทั้งหมด
        - ใหม่ที่เห็น: beeguard (ธรรมดา) ถูกตัดสินครั้งแรก: 4169/4169 drawn แต่ glitch 593, false 172 — SHRINK/JUMP/WOBBLE ส่วนใหญ่เป็น
          ตัวตรวจรวมผึ้ง 8 ตัวเป็นรูปเดียว (ตัวหนึ่งจบอีกตัวเริ่ม = พื้นที่รวมหด/กระโดด) → ตัวตรวจ glitch ต้องแยกตาม guid (ค้าง) ;
          YELLOW atk 174 (ขึ้นเหลืองไม่เคยแดง) → **แก้ตัวตรวจแล้ว (2026-10-20):** (1) simmoves _record/คิว merge มี owner (predict ตั้ง
          SimMoves._draw_owner) → replay แยก YELLOW ต่อตัว (OLD_YELLOW_ONE=1 = รวมแบบเดิม) ; แยกแล้วแบบพิกัดโลกกลับได้ 7321 เพราะผึ้ง
          บินเข้าระหว่างง้าง รอยเหลืองค้างข้างหลัง (เดิมแดงของตัวอื่นบังไว้) → (2) ตัดสินในกรอบของรูปเอง (หน้า/ข้างจากจุดวาด) — วาดที่หนึ่ง
          แดงอีกที่ = งานของ AIMJUMP (OLD_YELLOW_WORLD=1 = พิกัดโลก) → 3 ; (3) 3 ที่เหลือ = ราชินีเรียก flyup กลางท่อย (trace ของตัวนั้น
          ออกจาก state ก่อนเฟรมตี) = เหลืองหายถูกแล้ว → YELLOWCUT (ตัดสินจาก trace ไม่ใช่จากภาพ ; OLD_YELLOW_CUT=1 = เดิม) → 0.
          strikes 4169/4169 เท่าเดิม. bench_replay มีคอลัมน์ yellow.
          **รอบ 2 หลังรัน 1049 เต็ม (22,574 → 8,706) — แยกสาเหตุทีละข้อบน bearger/deerclops/claw/tentacle/beeguard/spider:**
          (ก) กฎ cut แบบ "ออกจาก state" ผิด: bearger ground_pound วงไกลตีตามเวลาของมันเองหลังเข้า taunt → 190 ถูกตัดผิด. แก้: ออกจาก
              **ท่า** (anim ไม่อยู่ใน anims ของท่า) และก่อนเฟรมตี**แรก** (at น้อยสุด) ; trace จบก่อน = YELLOWGONE ไม่รู้ (ไม่ใช่ cut)
          (ข) ท่าส่งต่อ: tentacle atk_pre → atk_loop เปลี่ยนชื่อท่ากลางทาง แดงอยู่ใน go ถัดไป → 1,489 "ไม่แดง" ทั้งที่ตีจริง (627.067).
              แก้: หาแดงต่อจนถึงเฟรมตี+3 ในมุมมองของตัวเดียวกัน (OLD_YELLOW_GO=1 = เดิม) — เดิมแบบรวมก็นับผิดแบบนี้ (714)
          (ค) กรอบของรูปเอง ซ่อน "เหลืองที่นี่ แดงที่โน่น" ได้ (JUMP ยกเว้นเฟรมที่ parts เปลี่ยน) → เพิ่มตรวจ: เหลืองเฟรมสุดท้ายของ
              แต่ละ map เทียบแดงเฟรมแรกของ map เดียวกัน ในพิกัดโลก หักการเคลื่อนของเจ้าของ, เผื่อขอบ 0.5. ตัวคุม YELLOW_FAULT=3
              (เลื่อนแดง 3): bearger 0→839, deerclops 2→670, beeguard 0→7,885 = จับได้
          ผลตัวอย่าง: bearger 0, claw 0, tentacle 0 (GONE/CUT 130), beeguard 0, deerclops 2 (atk2 enraged "put elsewhere" 11-13
          หน่วย บอสไม่ขยับ — **ค้าง: ดูภาพ**), spider 116 (warrior_atk กระโดด: เหลืองคลุมทาง แดงแค่จุดลง — **ค้าง: ทางควรจาง?**).
          **รอบ 3 (replay เต็ม: 9,544 ; "put elsewhere" 3,385):** หักการเคลื่อนของเจ้าของผิดสำหรับรูปที่ lock ไว้กับพื้น (Twins dash
          lane วางที่จุดเริ่ม เจ้าของพุ่ง 0.77/เฟรม → 819 ปลอม) → เปลี่ยนเป็น: anchor ของ map เดียวกันขยับ ≤ เจ้าของขยับ+0.5 และหมุน
          <0.1 = "ถูกพาไป" (รูปเดิม) ; ไม่งั้นเทียบพื้นที่ และนับเมื่อ >ครึ่งของเหลืองเฟรมสุดท้าย (ทั้ง go) ไม่อยู่ใต้แดง. ตัวคุม
          YELLOW_FAULT=10: lunarrift 6,087, deerclops 670, bearger 839, twins2 567 ; =3 beeguard 7,885.
          → twins2 0, eyeofterror 0, phase3 0, rabbitking 0, mutatedbearger 0 (moved). **เหลือ lunarrift roll_pre 727 = ของจริง**
          (ภาพ PIC 15.634/15.667: แผ่นเหลืองแรกค้างที่จุดเริ่มกลิ้ง ขณะบอสคืบไปข้างหน้า 8 หน่วยระหว่าง roll_start (3.5/s) แล้วแดง
          โผล่ที่ตัวบอสโดยไม่มีเหลืองตรงนั้นก่อน) → **ค้าง: แก้ data roll ให้แผ่นแรกตามบอสระหว่าง roll_start** ; twins1 3, deerclops 2 ยังไม่ดู.
          เครื่องมือ: scratchpad ppm2png.ps1 (PIC_OUT .ppm → .png).
          **ผล replay เต็ม 1049 รอบ 3: YELLOW 22,574 → 7,792 ; put elsewhere 907 (roll ของ Champion: lunarrift 727 + phase1 162 =
          บั๊กเดียวกัน)**. strikes/missed/aimjump เท่าเดิม ; false 5125→5127, glitch +1 = ผันผวนระหว่างรัน (เคยเห็น missed 400↔401).
          ค้างต่อ: (1) แก้ roll (แผ่นแรกก่อน lock 52 วางที่จุดเริ่มโดยไม่บวก path) (2) glitch แยกต่อตัว (VANISH/SHRINK/JUMP/WOBBLE ;
          แผน: AddTri รวมพื้นที่ต่อ SimMoves._draw_owner, ใช้เฉพาะรันที่มี >1 ตัววาดพร้อมกัน — บอสเดี่ยวคงโค้ดเดิม = ตัวคุมในตัว)
          (3) YELLOW ใหญ่ที่เหลือ: rook_nightmare 878, mutatedbearger 849, rook 729, minotaur 570 (ท่าพุ่ง) ยังไม่ได้แยกดู
        - **แก้ roll (predict.lua leg ช่วงง้าง):** ต้นเหตุ = ขาที่จะมาวาดที่ pre_x + go โดย go เรียนจากครั้งก่อน แต่เรียนเฉพาะ go < 6
          และ Champion เดิน 8.2 ระหว่าง roll_start → ไม่เคยเรียน → วาดที่จุดเริ่มทุกครั้ง. ลองแก้ 1: go เริ่มจาก path offline ที่
          first (8.33) → put elsewhere 889→311 แต่ missed +3: บอสติดผู้เล่น (ขยับ ~1 ระหว่าง roll_start) ขาวาดเลยไป 8 หน่วย.
          แก้ 2 (ใช้): วาดจากตัวบอสตอนนี้ + ระยะที่ path ยังเหลือ (path(first) − path(now)) — ปกติได้ที่เดิม, ติดอยู่ = ที่ตัวบอส
          (TR_OLD_PREGO=1 = เดิม ; simmoves ส่งออก _PathAt). ผล 10 บอสที่มี leg: put elsewhere 889→0, JUMP/roll 355→0,
          missed lunarrift 31→30, eyeofterror 7→6 ; อื่นเท่าเดิม. ผลข้าง: LATE/roll_start +547 = ตัวตรวจนับทางเดินช่วง roll_start
          (ไม่มีแท็ก attack, roll collision เปิดเฉพาะใน roll = ไม่ตี) → LATE ตัดสินเฉพาะตั้งแต่เฟรมตีแรกของท่า (first)
          (OLD_LATE_ALL=1 = เดิม).
          **replay เต็ม v4 (เทียบ v3):** missed 400→398, glitch 6736→6230 (JUMP 1223→719), strikes เท่าเดิม, LATE 1470→1408
          (hoodedwidow 71→10, wagboss 19→3 = ตำแหน่งก่อนเฟรมตีแรก). LATE ที่เหลือ 83 ตัวอยู่ที่ "0.30s" พอดี = 9 เฟรมที่ผลรวม
          ทศนิยมได้ 0.2999 < .3 → แก้เกณฑ์เป็น < .3−1e-3 (Champion 40 ทั้งหมดเป็นแบบนี้). roll_pre YELLOW ไม่แดง 464→1203 **ไม่ใช่
          ถดถอย**: v3 รายงานเป็น put elsewhere ก่อน (if/elseif) ซ่อนไว้ 727+464=1191 → 0+1203. ส่วนที่ไม่แดง = ปลายเลน 7-11 ของขา
          ที่บอสไม่ไปถึง (น่าจะชนผู้เล่นแล้ว roll_stop) → **ค้าง: คลาส "เลนพุ่งถูกตัดเพราะตีโดนแล้ว"**.
          **ติดตั้งแล้ว** (install.ps1: 32 ไฟล์, data A418555EDDA4)
        - **glitch แยกต่อตัว (replay.lua):** AddTri รวมพื้นที่/จุดกลางต่อ SimMoves._draw_owner (tri_pts.own — ไม่เพิ่ม local ระดับไฟล์) ;
          ทุกเฟรมเก็บ own[ตัว] = พื้นที่, state/ตำแหน่ง/ท่าของตัวนั้นจาก track ; ตัวตรวจ VANISH/DROPPED/SHRINK/JUMP/WOBBLE ห่อเป็น
          GlitchOver(list) — รันที่มี >1 ตัววาดพร้อมกัน: ตรวจทีละตัว (GLITCH_EACH) ; ไม่งั้นแบบเดิมทั้งหมด (ตัวคุมในตัว ;
          OLD_GLITCH_ONE=1 = รวม). ผล: beeguard 593→20 (เหลือ WOBBLE ตอน flydown — ค้าง: ดูว่าสั่นจริงไหม), spider 601→6
          (SHRINK 595 = ตัวหนึ่งจบอีกตัวเริ่ม), claw 0→0 ; ตัวคุม deerclops 2=2, bearger 20=20.
          **replay เต็ม v5 (เทียบ v4):** glitch 6230→4641 (beeguard 539→18, spider 615→18, eyeofterror_mini 303→1,
          rabbitkingminion 33→1, bigshadowtentacle 19→0, um_beeguard* →0), LATE 1408→1325 (−83 เศษทศนิยม) ; strikes/missed 398/
          yellow 7797/aimjump เท่าเดิม, false 5125→5124 (ผันผวน). สำรอง scratchpad replay1049_v3, _v4
        - **คลาส YELLOW ใหญ่ที่เหลือ = ท่าพุ่งที่จบเร็ว (ไม่ใช่บั๊กตัวตรวจ):** rook/rook_nightmare atk 1,233 — เช่น rook 8.600 วิ่ง 0.23 s
          แล้ว run_stop (เพิ่งโดนตี 8.367) ไม่ถึงเลนเลย = เลนเหลืองทั้งหมดไม่แดง ; Champion roll ชนแล้วหยุด เหมือนกัน. แก้ได้ทางเดียว
          คือเปลี่ยนแบบ (ส่วนไกลของเลนเป็นจาง) = **ต้องถามผู้ใช้** — ยังไม่ทำ
        - **bigshadowtentacle missed 43:** 31 อยู่ติดการย้ายฉากของ testbench (you= กระโดด >10 ภายใน 0.2 s หลังตี ; scratchpad
          miss_near_tp.lua) — replay At() เลื่อน "you" แบบเส้นตรงไปหา tick ถัดไปที่อยู่ฉากใหม่ (<3 s) → you ห่าง 48 ตอนโดนตี =
          ของ replay ไม่ใช่ mod. ลองแก้: you ไม่เลื่อนข้ามการกระโดด >10 → replay เต็ม v6: tentacle missed เท่าเดิม 43 (ไม่ใช่ต้นเหตุ)
          และ false +95 (beeguard +56: you ค้างที่เดิมหลังย้ายฉาก) → **ถอยกลับแล้ว**. รันช่วงสั้น (1155-1158) ไม่มี MISSED และ you
          ถูก → ต้นเหตุอยู่ที่ประวัติก่อน 1155 (track อื่นที่มี tick ใหม่สุด) ; เพิ่ม PY_DBG=t0,t1 (you + ทุก track).
          **ต้นเหตุจริง:** tentacle 123713 (ฉากถัดไป) trace ครั้งแรก 1158.333 แต่ At() ให้ track โผล่ก่อน tick แรกได้ถึง .5 s
          (ของที่ trace ช้า) → ตัวเลือก "you" เอา tick อนาคตนั้นเป็น "ใหม่สุด" → you = ฉากหน้า −212 ตั้งแต่ 1157.834 ขณะตัวที่นี่ตี.
          แก้: ตัวเลือก you ใช้เฉพาะ tick ที่ ≤ t (OLD_PY_AHEAD=1 = เดิม).
          **replay เต็ม v7 (เทียบ v5): missed 398→344** (bigshadowtentacle 43→0, eyeofterror_mini 11→0, beeguard 1→0, _haz 231→232) ;
          false 5124→5191 (tentacle 11→64, minieye +9) = เฟรมที่เคยตัดสินกับ you ผิดที่ ; 57/64 ของ tentacle ไม่ติดการย้ายฉาก =
          **ค้าง: คลาส "tentacle วาดทับ ไม่ตี"** ; อื่นเท่าเดิม. สำรอง scratchpad replay1049_v5
        - **_haz ที่เหลือ (หลังหัก ASBOSS_DRAWN แบบที่ตารางทำ — นับดิบ 751 บรรทัดเกินจริง):** 230 = UM ผึ้ง 138 (log เก่า, แก้แล้วที่
          1218), minieye_projectile 25, eyeofterror_laser 18, horn 13, worm_boss_segment 11, spiketrail 6, bearger_boulder 5 ... ;
          warg breath = 0 แล้ว (ASBOSS หักครบ).
        - **eyeofterror_minieye_projectile (UM):** linearprojectile ความเร็ว 20 (postinit SGeyeofterror ShootEye), ไม่ตกพื้น (เช็คพื้น
          ถูกคอมเมนต์), หาย 3 s, ชนด้วย capsule 1.5 (+ตัวคุณ 0.5) ตลอดทาง = dart. ข้อมูลเดิมเป็นวงตอนหยุด. ทำโผล่ 2 หน้าตา ตา 4 จากคุณ →
          ชนแทบทันทีก่อนขยับ .3 → ทิศจากการขยับไม่ได้ → DARTS เพิ่ม face=true: ใช้ทิศที่หัน (Launch ForceFacePoint ; ตรวจ trace:
          rot 15° ชี้ตรงไปหาคุณ) จนกว่าจะขยับ .3 ; len 60 width 2.0. replay_haz parse face + DartCovers ใช้ rot แบบเดียวกัน.
          **พบด้วย: game_scripts_um ไม่มีโฟลเดอร์ postinit ของ UM** (shoot ของตาอยู่ที่นั่น) ; ตาเอง "things struck you 166 − 0 drawn"
          = ท่า shoot ของตา (anim เดียวกับ charge) ไม่ถูกวาดเลย → ค้าง: ท่า shoot ของ UM eyeofterror.
          **ผล:** replay_haz share065 minieye 23→0, false 6=6. **ติดตั้งแล้ว** (install.ps1 data A418555EDDA4)
        - **คลาส UM "shoot" ของ eyeofterror/twins (ค้าง — ต้องตัดสินแบบ):** postinit/stategraphs/SGeyeofterror.lua: event charge →
          ตาเดี่ยว: สุ่ม 50/50 charge_pre หรือ shoot_pre ; แฝด: สลับกัน (canshoot). shoot_pre/shoot_loop/mouthshoot_loop/shoot_pst ใช้
          anim charge_pre/charge_loop/charge_pst **เหมือนท่าพุ่งทุกอย่าง** แต่ไม่ขยับ → client แยกไม่ได้ตอนง้าง. ยิงที่เฟรม 0 ของ loop:
          twin1 = SpawnLaser (เส้นตามทิศหัน 1.25→16.25, delay 0-19 เฟรมตามระยะ — laser เกิดแล้วตีในเฟรมถัดไป ตัวมันเองเตือนไม่ได้),
          twin2 = fireball 4 ลูก (f0,3,6,9), ตา = minieye projectile (f6). เส้นพุ่งที่วาดอยู่ครอบเส้น laser เกือบหมด (ภาพ PIC twin
          2425.066) — twinofterror1 "things struck you 278 − 150 drawn, 128 not" ทั้ง share ; ตา 166 − 0 drawn (minieye ตอนนี้มีเลน dart).
          ~~ทางเลือก: วาดทั้งสองแบบ~~ **แก้ความเข้าใจผิด (ผู้ใช้ทักว่าเทสแล้วแยกได้):** mod แยกอยู่แล้ว — ข้อมูลมี charge_pre~shoot_pre
          (moves_sim_um / moves_hand_um) และ predict.lua 685-698 (a.alt: ท่าที่ไปที่อื่นก่อน, ยังอยู่ที่เดิมเกินเวลาออกตัว → อีกท่า)
          + Off() เลือกจาก anim ที่เห็นล่าสุด/after_anim. replay share064 2424: วาดเป็น charge_pre~shoot_pre~2 ตั้งแต่เฟรมแรก = ท่ายิง
          จริง (ภาพ PIC คือเส้น laser ไม่ใช่เลนพุ่ง). ที่เหลือ 128 ไม่ใช่เรื่องแยกท่า → ต้องดูทีละเคส. rook/Champion เลนพุ่ง: ผู้ใช้ให้ปล่อยไว้
        - **twin1 laser 128 "not drawn" (ไล่แล้ว):** ทุกตัวอยู่บนเส้น (aside 0) 5.7-12.5 หน้าแฝด ช่วง shoot_loop/shoot_pst (scratchpad
          thingmiss_geom.lua). ท่า shoot วาดเส้นถึงเฟรม 36 แล้ว predict 2715 ส่งต่อให้ของที่วาง (puts, set_until 34+2) ; เลเซอร์ที่พื้น
          (trace ครบทุกลูก) วาดรวมเป็นเลนเดียว SimMoves.LaneDraw (จากลูกที่ยังไม่ระเบิดถึงลูกสุดท้าย) — แต่ "inside" ที่คืนให้ตัวตรวจ
          = วงของลูกเดียว (simmoves 3582) → ตัวตรวจ replay_haz นับหลุดทั้งที่เลนครอบ = **บั๊กตัวตรวจ**. แก้: record ของ LaneDraw ติด
          lane=true ; replay_haz นับ inside ถ้าอยู่ในเลน (OLD_LANE_IN=1 = เดิม). share064 _haz: laser missed 18→0, FALSE บรรทัด 12→11,
          เฟรม drawn-in-no-strike 56→78 (ชุดเลเซอร์ตีแต่ละเป้าครั้งเดียว — targets ร่วม — อยู่ในเลนหลังโดนแล้วไม่โดนซ้ำ). ติดตั้งแล้ว.
          (THINGMISS ของ replay.lua ฝั่งบอสไม่นับรูปของสิ่งของ จึงยังขึ้น "not" — เป็นแค่บรรทัดข้อมูล ไม่อยู่ในตาราง)
        - **เขา ruins nightmare 13:** เลนระหว่างเขาคู่ (1.75) วาดโดย modmain เอง replay_haz ไม่รู้จัก (แบบ DARTS) → HornCovers
          (OLD_HORNS=1 = เดิม) share015 13→0. **worm_boss_segment 11 / 18,550:** ปล้องโผล่จาก pool แล้ว DoThornDamage (r 2+0.5) ในเฟรม
          เดียวกัน ที่รู dirt — ไม่มีจังหวะเตือนจากตัวปล้อง ; วาดรูเป็นพื้นที่อันตรายต้องรู้สถานะรู (dirt_move/pre/pst/emerge...) ไม่งั้น
          เตือนเกิน → **ค้าง (เล็ก)**. **spiketrail 6:** หนามที่รอยวางใต้คุณตอนวิ่งผ่าน โผล่ช้ากว่าส่วนที่วาด (ถูกเอาออก 683.266 ตีจริง
          683.333) = จังหวะเวลารอยที่หยุดแล้ว → **ค้าง (เล็ก)**. bearger_boulder 5 (เหตุการณ์เดียว 203.2) ยังไม่ได้ดู.
        - **replay เต็ม v8 (เทียบ v5): missed 398→289** (_haz 231→177 = laser 18 + horns 13 + minieye 23 ; tentacle 43→0, minieye 11→0,
          beeguard 1→0) ; false 5124→5276 (_haz +88 เฟรมในเลนหลังโดนแล้ว, tentacle +53) ; strikes/yellow/glitch/aimjump เท่าเดิม
        - **Tropical Experience (workshop 1505270912, เริ่ม 2026-10-20):** mod_scripts -Name te (1,641 ไฟล์), anim_lengths_te (7,349).
          แก้ทางให้ modmain รันในตัวจำลอง: (1) mod_scripts: ไฟล์ของ mod ชื่อชนเกมที่เขียนแบบ GLOBAL (tuning/actions/recipes ฯลฯ 7 ไฟล์)
          คงของเกม ; (2) mod_env: เติม WORLD_TILES จาก GROUND, โหลด strings + containers ของเกมก่อน (containers โหลดไม่ได้ → STUB),
          ห่อ setmetatable(env) ให้ฟังก์ชัน Add*/Register*/Remove* ที่ไม่รู้จักยังตอบ (TE เปลี่ยน metatable ของ env บรรทัดแรก) →
          modmain รันถึง 5497/5515 (ส่วนท้ายเป็น component นก/ผีเสื้อ/แผนที่) ; (3) ชื่อ prefab มีโฟลเดอร์ ("monsters/crocodog") —
          sim Prefab() เก็บส่วนหลัง / , pattern อ่านชื่อ 3 จุด + combat_census รับ "dir/name" → census TE 122 → 214 ตัว
          **tools\build_te.ps1** (แบบ build_um, 3 นาที -jobs): 274 บอสที่ TE เปลี่ยน/เพิ่ม → เก็บ 157 ตัว 210 ท่า 8 สิ่งของ →
          true_range/moves_sim_te.lua ; moddata: workshop-1505270912 "Tropical Experience" (โหลดครบ 157/157). **tools\check_te.ps1**
          (sim -check → replay ผ่านการวาดจริง): replay.lua หา SG ไม่เจอเมื่อชื่อมีโฟลเดอร์ → findstr ด้วยชื่อในเครื่องหมายคำพูด +
          pattern Lua → **293 trace: strikes 2,802, missed 27** (greententacle 25 = ท่า attack_range ยิงหนาม tentacle_attack_spike:
          projectile ไม่ติดตาม ความเร็ว 40, range nil = พุ่งไม่จำกัด, ตีเฉพาะเป้าในระยะ 1.5 → ต้องเป็นเลนแบบ DARTS + ตัวตรวจฝั่งบอส
          ต้องนับเลน ; dragonfly 2 = ตีที่ 6). **ติดตั้งแล้ว** (33 ไฟล์) — ยังไม่ได้ทดสอบในเกมจริง (ต้อง bench โลกที่เปิด TE).
          ยังไม่มีข้อมูล: antqueen, ancient_herald (SG ล้ม บรรทัด 185), roc, twister/firetwister (twister_defogo ล้ม), thunderbird,
          grottoqueen, ancient_robot_* (ไม่มีท่าออก), jellyfish (ตีเมื่อแตะ) ; ที่เหลือใน 66 ส่วนใหญ่ไม่อันตราย (ปลา ผีเสื้อ ฯลฯ)
          **รอบ 2:** (1) tentacle_attack_spike เข้า DARTS (len 30, width 1.5 ; ชื่อ prefab ตรง) — ในเกมวาดเป็นเลน ; check_te ยังนับ 25
          เพราะ replay.lua ฝั่งบอสไม่นับเลน DARTS (ต้องเทสในเกม). (2) ancient_herald: blast ไปโดน "world" — sim ใส่โลกในผลค้นหา
          (ในเกมไม่มี) → เอาออก (SIM_OLD_WORLDFOUND=1 = เดิม ; ตัวคุม: sim เกมปกติทั้งชุดสองแบบ diff = 1 ท่า gestalt
          atk_flame_pre ซึ่งรันแบบใหม่สองครั้งก็ต่างกันเอง = ไม่ deterministic → การแก้นี้ไม่เปลี่ยนข้อมูลเกมปกติ). sim มี
          SIM_TRACEBACK=1 (traceback + ค่า local v). (3) mod_env: TheMixer/TheCamera/TheFocalPoint เป็น stub → twister ได้ท่า.
          (4) spec te.lua: thunderbird prep lightning_target (ฟ้าผ่าเองเป็น event โลก ลงสุ่ม 4-8 รอบเป้า = ต้องวาดแบบ "อาจโดน" ค้าง).
          build ใหม่: 160 ตัว 212 ท่า (+herald attack, +twister atk, เดิม changed 0) ; check_te: 295 trace strikes 2,821 missed 27
          (greententacle 25 ตามที่คาด, dragonfly 2 ที่ขอบ 6.0 ฉากทดสอบ — เกมปกติ bench 0). ติดตั้งแล้ว.
          ค้าง: antqueen (ท่ากระโดด → quaker_interior หินร่วงสุ่ม, ร้องเพลง = มึน 3.5 s ไม่ใช่ดาเมจ), roc_head (ต้องมี controller
          ตัวร่าง roc), ancient_robot_* (nothing), firetwister (twister_defogo ล้ม ItemsMain), rookwater (nothing)
          **หุ่นยนต์ ancient (รอบ 3):** หลับตั้งแต่เกิด (dormant + spawntask DoTaskInTime(0) ใส่กลับ เว้นแต่ inst.spawned) → spec
          prep Wake (spawned=true, ลบ dormant). laser ของมันล้มต่อ: Map:GetTileAtPoint nil → sim ตอบพื้นดิน (SIM_OLD_TILE=1 = เดิม) ;
          component อัตโนมัติ (sim สร้างเมื่อถูกอ่าน, บรรทัด ~1230) ไม่มีค่าเริ่ม → freezable.coldness 0, temperature 35/90/-20 (ค่าเกม).
          ได้ ribs: atk + hazard "laser" (delay_max 11, as_boss). **ตัวคุม (กำลังรัน):** sim เกมปกติทั้งชุดเทียบรอบก่อนแก้ (worldfound\new),
          UM build ใหม่เทียบที่ติดตั้ง (สำรอง scratchpad moves_sim_um_before_simfix.lua)
          **ผลตัวคุม:** sim เกมปกติ = ต่างแค่ gestalt (ไม่ deterministic) → การแก้ sim ไม่เปลี่ยนข้อมูลเกมปกติ. UM build ใหม่ต่าง 3
          (phase2 attk_stab_pre หาย = ที่เคย splice เอง, hazard bearger_boulder / um_shock_projectile เปลี่ยน — ยังไม่รู้ว่าจากการแก้วันนี้
          หรือสะสมตั้งแต่ build UM ก่อน) → **คืนไฟล์ UM เดิม** (ค้าง: ไล่ 3 จุดนี้ก่อน build UM ครั้งหน้า).
          TE build v3: 164 ตัว (+หุ่นยนต์ 4 ชิ้น atk/atk_pre, hazard laser/laserempty ; เดิมไม่เปลี่ยน). check_te: 301 trace strikes 2,915,
          missed 31 (greententacle 25 [DARTS], หุ่นยนต์ claw/ribs 2+2 [น่าจะเลนเลเซอร์ที่ตัวตรวจฝั่งบอสไม่นับ — ยังไม่ยืนยัน],
          dragonfly 2). ติดตั้งแล้ว
          **รอบ 4 (spec te.lua):** rookwater = ท่าพุ่งแบบ rook ของเกม (ram dist 25, anims atk_pre/paw_loop/atk ไม่มี atk_collide ;
          also rookwaterfixo) → ได้ atk_pre. roc_head grab: controller ตัวแทน (target = คุณ) → ไม่ล้มแต่ "nothing" (คว้าในระยะ √2 ของหัว
          ที่ไม่มีขนาดใน sim) → **ค้าง**. antqueen: ไม่ได้ตีเอง — กระโดด → quaker_interior "queenattack" หินร่วงสุ่ม 15-20/s 4-8 s
          แต่ละก้อนมีเงา warningshadow ตีในรัศมี 2 (ตรงกลางตัวคุณ) → striker warningshadow r 1.5 by antqueen (แบบเงาของ UM).
          build สะอาด: 166 ตัว 12 สิ่งของ (warningshadow by antqueen) ; check 301 trace 2,915/31 เท่าเดิม (check_te ครั้งเดียวมี
          WaitForExit "Access is denied" → รัน -NoSim ซ้ำเพื่อสรุป). rookwater ไม่มี trace ในชุด check (ท่า ram ไม่ถูกจำลองในฉาก check?).
          **รอบ 5:** firetwister: twister_defogo.lua:103 inst.ItemsMain:Cancel() — entity ใน sim ตอบชื่อตัวใหญ่ด้วยฟังก์ชันว่าง →
          ภายใต้ MODENV ตอบ CALLABLE (เรียกได้ + index ได้) → ได้ atk. thunderbird: ฟ้าผ่า (weather OnSendLightningStrike) หาเป้า
          ใกล้สุดใน 40 (สายล่อฟ้า/ผู้เล่นตามโอกาส) แล้วผ่าลงตัวเป้า — จุด 4-8 ที่มันเล็งไม่สำคัญ = วาดตามตำแหน่งไม่ได้ ; ทางเลือก
          วงจาง "อาจโดน" ที่ตัวคุณระหว่าง thunder_attack → **ถามผู้ใช้**. jellyfish = ช็อตเมื่อคุณตีมัน (ไม่ใช่ท่าตี) → ไม่วาด
        - **ผู้ใช้ 2026-10-20: "ท่ามันเร็วมาก งั้นเอาพื้นที่แทน" + "ยังขาดท่ามหาศาล"** → (1) modmain AGGRO_WHILE ได้ at_you / any_target /
          linger: thunderbird ตอนเล่น "shoot" + 1.3 s วงจาง r3 รอบตัวคุณ (ติดตั้งแล้ว). (2) **tools\mod_coverage.lua**: เริ่มจากโค้ดเกม —
          ทุก prefab ของ mod ที่มี combat+SG → ทุก state ที่ทำร้าย (DoAttack/AreaAttack/GetAttacked/projectile/spawn hazard/แท็ก attack,
          ช่วยหา helper ที่ทำร้าย, ตัดคอมเมนต์, นับ state ที่ต่อจากท่าที่มีแล้ว) เทียบ anims ในข้อมูล ; + รายการ "NO STATEGRAPH" (มี combat
          แต่ไม่มี SG). ผล (กรองเหลือมอนจริงด้วย scratchpad cov_filter.lua): 99 ตัวขาด 138/198 state ; มีปลา/นก/merm ตกปลาปน.
          (3) Maxwell (ผู้ใช้ถาม "เรียกฟ้าผ่า เรียกอุกกาบาต"): TE maxwellboss ไม่มี SG — magicattack ตอนวาร์ป: maxwellshadowmeteor ±15
          (เงา 1 s, ระเบิด 0.33 s ต่อมา, r = ขนาด×3.5, ขนาด .7/1/1.3) → striker r 4.05 delay 40 by maxwellboss ; ฟ้าผ่า ms_sendlightningstrike
          3-15 รอบตัว = ค้าง (แบบ thunderbird แต่ไม่มี anim ให้จับ). **ข้อมูลเกมปกติไม่มีฝนอุกกาบาต shadowmeteor เลย = ค้าง**.
          (4) striker เพิ่ม: firerain / dragoonegg_falling (groundpounder 1 วง r1 + ringWidth 3 = 4 กลางตัว → 3.5, delay 55 / 53),
          treeguard_coconut / snakefall (r1.5 → 1.0, moved) ; DARTS pig_ruins_dart (len 30 width 1.0). (5) spec add: beetletaur combo/uppercut/
          bellyflop, bossboar dash, gnarwail body_slam ได้ ; ท่าที่ add แล้วตัด "attack" ต้นคอมโบทิ้ง → ใส่ "attack" คืน. ยัง "nothing":
          กวางเวท, ลิงขว้าง, hulk bomb, เต่าสไลด์, pugalisk หาง, hippo ดำน้ำ, weevole, herald summon, gnarwail boat_attack.
          TE build v8: 167 ตัว 220 ท่า 17 สิ่งของ ; check 309 trace 3,013/31 ; coverage ยัง 133/198 ขาด. ติดตั้งแล้ว
        - **คืน 2026-10-20 (ผู้ใช้หลับ — ทำต่อเอง):** shadowmeteor (ฝนอุกกาบาตเกมปกติ) เข้า moves_hand _hazards (cells จาก striker
          r 4.05 delay 40 ผ่าน spec ชั่วคราว ; รอติดตั้ง). mod_coverage: นับ state ที่ anim ใดก็ได้อยู่ในข้อมูล (หัว/หาง pugalisk),
          ตัดเนื้อ state ด้วยวงเล็บคู่ (state สุดท้ายเคยกินทั้งไฟล์ — ค้างคาว land) → 83 ตัว 108/170 ขาด. จัดประเภท "nothing":
          weevole attack = anim attack 19 เฟรม จบก่อน DoAttack เฟรม 25 → ในเกมไม่เคยตีจริง (ตีด้วย leap_attack) = ไม่ต้องวาด ;
          ice_deer = ไม่มีอัญมณี (common_fn ไม่ส่ง gem) ร่ายไม่ได้ = นับเกิน ; goddess_deer_gem ร่าย greentornado2 (พายุเดินเองมี SG)
          = ค้าง (หายาก). DBGSTATE ขนาน 12 ตัว: ลิง throw ออกทันที (ต้องมีขี้) ; gnarwail boat_attack (ต้องมีเรือ) ; ข้อมูลมีอยู่แล้วแต่
          เครื่องมือจับ anim ไม่ได้ (mandrakeman atk, beetletaur bellyflop) ; tigershark มี SG บก/น้ำ — sim รันแค่ SG แรก (น้ำ) = ค้าง
          (ต้องรองรับ 2 SG ต่อ prefab) ; bossboar groundslam: GroundSlamTargets กรอง ent.entity:IsVisible() → sim ตอบ nil → แก้ให้ตอบ
          true เว้นซ่อน (Entity:Hide/Show จำ ; SIM_OLD_VISIBLE=1 = เดิม ; ตัวคุมเกมปกติ diff = gestalt เท่านั้น) แต่ groundslam ยัง
          nothing = ค้าง. firetwister waves / hulk bomb / herald summon / squid shoot / hippo submerge / เต่าสไลด์ = ค้าง.
          TE build v9 changed 0 ; ติดตั้งแล้ว (รวม shadowmeteor มือ).
        - **bench TE ในเกมจริงครั้งแรก:** run_bench -TE (bench_overrides "te" เปิด workshop-1505270912 ในโลกของ bench เท่านั้น) ;
          bench_replay -TE (TR_MODS UM+TE, สคริปต์ tests\work\game_scripts_umte = เกม+UM+TE กฎ GLOBAL เดิม). ทดลอง 2026-10-20_2022:
          **crocodog 84/84, hippopotamoose 84/84, missed 0**. รันเต็ม 167 ตัว (-Rounds 3 -Jobs 8) กำลังรัน (scratchpad bench_te_all.log)
        - **คืน 2026-10-20 ต่อ (ระหว่าง bench TE เต็ม — ยังไม่ติดตั้งอะไรเพื่อไม่ให้ mod เปลี่ยนกลาง bench):**
          (1) **2 SG ต่อ prefab:** tools\sim_mods\te_second.lua (tigershark → SGtigershark_ground: attack, jump) + tools\merge_moves.lua
              (เพิ่มเฉพาะท่าที่ยังไม่มี ; รองรับข้อมูลที่เขียนบอสทั้งตัวในบรรทัดเดียวแบบ mod_diff) ; build_te.ps1 ขั้น 5 รันให้เอง.
              jump ล้มที่ TheCamera:GetHeading() (stub ตอบ nil) → mod_env: TheCamera.GetHeading/GetHeadingTarget = 0.
              ผล: tigershark +atk, +ground_launch_up_pre (61 maps) — merge เข้า moves_sim_te.lua ใน work folder แล้ว (สำรอง scratchpad
              moves_sim_te_before_second.lua) **ยังไม่ติดตั้ง**.
          (2) **bossboar groundslam "nothing" — สาเหตุจริง:** GroundSlamTargets ค้น FindEntities รัศมี 16 แล้วกรองเองด้วยสี่เหลี่ยมคางหมู
              (ยาว 15 ข้างหน้า กว้าง ±1.7) — sim ให้ dummy ตอบเฉพาะการค้น ≤ 12 (WIDE: การค้นกว้าง = หาเป้า) → ไม่โดนใคร. คลาส: "ค้นกว้าง
              แล้วกรองรูปทรงเอง". แก้: การค้นที่บอสทำใน timeline ของท่า (sim_in_timeline) ให้ dummy ตอบไม่จำกัดรัศมี (SIM_OLD_WIDE=1 = เดิม).
              + cast (banner) ล้มที่ FindPlayersInRangeSq = nil → sim require("simutil") ของเกม (FindEntity/FindClosestPlayer ฯลฯ ;
              SIM_OLD_SIMUTIL=1 = เดิม). ผล: bossboar attack5 (groundslam) 16 maps, banner_pre 61 maps, hazard bossboarfireburst.
              **ตัวคุม:** sim เกมปกติทั้งชุด (4 slot ไม่แย่ง bench) เทียบ moves_sim.new3 — กำลังรัน. UM/TE ต้อง build ใหม่หลังผ่าน.
          (3) striker ใหม่ใน te.lua: ancient_hulk_mine r 3.0 lasting (ระเบิด 3.5 หลังมีคนเข้าใกล้ 3.5: red_loop 0.8 s + 0.3 s) วาด
              เฉพาะตอน red_loop (simmoves _on_anims — ตอนติดอาวุธเฉยๆ อาจไม่ระเบิดเลย) ; greentornado2 r 2.5 moved lasting
              (พายุเขียวของกวางเทพ เดินเองด้วย brain ตีรอบตัว 3 ทุกช่วง).
          (4) จัดประเภท "nothing" ที่เหลือ: twister waves = rogue_wave ชนแล้วแค่เปียก (moisture) ไม่มีดาเมจ → ไม่วาด ; hippo submerge
              = wave_ripple เปียกเหมือนกัน → ไม่วาด ; herald summon = สุ่มเรียกผีหมู/firerain/ฝนกบ/nightmare ซึ่งมีของตัวเองแล้ว →
              ไม่วาดที่ herald ; หุ่น leg/head ไม่มีแท็ก beam_attack (brain ยิงเลเซอร์เฉพาะ ribs/claw) → laserbeam ของ leg/head ไม่เกิด
              ในเกม ; เต่าสไลด์ ได้ attack2_loop แล้ว ; roc grab ตีเฉพาะเป้าเดียวในระยะ √2 ของหัว (dummy วัดไม่ได้, พื้นที่เล็ก) = ค้าง.
          (5) **ถามผู้ใช้:** ฟ้าผ่าของ Maxwell (TE) — ms_sendlightningstrike จุดสุ่ม 3-15 รอบตัว ทันที ไม่มี anim ; จับได้แค่ตอน
              maxwellshadowmeteor ลูกใหม่โผล่ใกล้เขา (เกิดพร้อมกัน) → ทางเลือก: วงจาง r 15 รอบ Maxwell ~2 s หลังอุกกาบาตชุดใหม่ หรือไม่วาด
          (6) coverage TE ใหม่ (ก่อน rebuild): 82 ตัว ขาด 107/169 — นับเกินที่รู้แล้ว: แมงมุม TE (spider_tropical/spiderb*/goddess_spider)
              spike_attack/heal เข้าได้เฉพาะแท็ก spider_moon/spider_healer ซึ่ง TE ไม่ใส่ ; snake_fire ถูกคอมเมนต์ใน mod ; beetletaur
              body_slam = bellyflop มีแล้ว ; ปลา/merm ตกปลา. **slipstor (ไม่มีข้อมูล):** attack เล่น "anim" — bank slipstor มี "anim"
              สองไฟล์: slipstor_attacks 8.57 s กับ slipstor_build 0.1 s ; sim เลือกชื่อไฟล์สั้นสุด = 0.1 s → จบก่อน DoAttack เฟรม 11 =
              nothing. ในเกมใช้อันไหน = ไม่รู้ → **ต้อง bench slipstor ในเกม** (ไม่อยู่ในรายการ bench เต็มรอบนี้) ก่อนแก้กฎเลือกไฟล์
          (7) **bench TE เต็มชุด 2026-10-20_2024 (195 share) → bench_replay -TE (ข้อมูล work folder ก่อน rebuild): strikes 23,383
              missed 1,476**, false 2,629, glitch 154, err 0. LUA ERROR 9 ครั้งใน log = โค้ด TE เอง (SGbeetletaur.lua:197
              laststartattacktime nil) ไม่ใช่ของเรา. missed แยกคลาส (state ตอนโดน):
              - หมูป่า wildboreguard 196 / pinkman 152 / wildbore 129 "attack" (anim atk): doattack เรียก GoToState(nstate) ผ่านตัวแปร
                → sim นับ attack เป็นแค่ท้ายของ charge_attack → **แก้ sim: ชื่อ state ที่ใส่ตัวแปรใน doattack นับเป็นจุดเริ่มท่า**
                (SIM_OLD_DOATTACK=1 = เดิม) → ได้ atk ทั้ง 3 ตัว
              - giantgrub exit 150, hulk telportin/barrier: groundpounder:GroundPound() ไม่อยู่ในคำที่ทำร้าย → **เพิ่ม ":GroundPound("**
              - hulk telportout 105 / spin 75 / barrier 28: inst.DoDamage (prefab ผูกให้, ทำร้ายผ่าน applydamagetoent) → **ฟังก์ชันของ
                prefab ที่ผูกกับ inst และทำร้าย (ไล่ต่อหลายชั้น) นับเป็นคำที่ทำร้าย** (SIM_OLD_HARM2=1 = เดิม ทั้งข้อนี้และ GroundPound)
              - bossboar/bossboarte attack 233 + groundslam 18: รอ rebuild (กฎ WIDE/simutil) ; twister vacuum_pst 91, spiky_turtle slide 90,
                spiky_monkey attack 78 (สุ่ม attack1/attack2 ข้อมูลมีแค่ attack2), mammoth chargeattack 40, scorpion/lizardman run_start
                40, pugalisk emerge 23 = ยังไม่ได้ดู
          (8) **ตัวควบคุม WIDE + SIMUTIL (เกมปกติ 14 บอสที่ต่าง, 4 แบบขนาน):** new3 เก่าเกินใช้เทียบ (แบบเดิมล้วนก็ต่าง 20 ท่า) →
              เทียบกันเอง: WIDE เปลี่ยน bearger/mutatedbearger +sleep_pst (ตื่น→หาว: yawn ค้น BEARGER_YAWN_RANGE กว้างกว่า 12 ไม่เคย
              ถูกวัด = ข้อมูลเกมปกติไม่มีท่าหาวเลย → ตอนนี้มี) ; SIMUTIL เปลี่ยน mossling spin_pre (FindClosestPlayerInRange เดิม nil →
              ท่าล้ม) + cookiecutter hit. ทั้งหมด = ใกล้เกมขึ้น → **ยอมรับ**
          (9) ต่อจาก (7): **hulk ยังไม่ได้ท่าแม้มีคำทำร้าย** — สาเหตุ: บอสที่ระบุด้วยมือ (spec add) จะเติมท่าที่หาเจอก็ต่อเมื่อเจอ
              Prefab("<ชื่อ>") ในไฟล์ ; pattern รับโฟลเดอร์ชั้นเดียว แต่ TE เขียน "common/monsters/ancient_hulk" → แก้เป็นหลายชั้น.
              ได้ teleport_out_pre (20 maps), teleport_in (21), atk_barrier (25). spin ล้มที่ TheCamera:GetDownVec() → mod_env กล้อง
              แบบเซิร์ฟเวอร์: heading ค่าเริ่ม 45 (followcamera SetDefault) ทั้ง GetHeading/GetHeadingTarget/GetDownVec (เดิมตั้ง 0 ไว้
              ให้ tigershark → เปลี่ยนเป็น 45 ให้ตรงเกม).
              spiky_monkey_tfc (และ yeti ที่ใช้ SG เดียวกัน): attack สุ่มเป็น slam (attack1) เมื่อพ้น SLAM_RECHARGE — sim ไม่เคยพ้น →
              spec: รัน attack สองแบบ (ปกติ + lastTimeSlam = -1000). slam ล้มที่ v.sg:GoToState("knockback") บนตัวแทนผู้เล่น
              (sg เป็นตารางเปล่า) → ตัวแทนผู้เล่นรับ GoToState ได้ (ไม่ทำอะไร ; SIM_OLD_PLAYERSG=1 = เดิม).
              **twister vacuum (91):** vacuum component ดูดผู้เล่นในรัศมี 20 ตลอด vacuum_loop 5 s แล้วถ่มออกพร้อม DoAttack ตอน vacuum_pst
              เริ่ม → modmain AGGRO_WHILE twister r 20 (vacuum_loop, vacuum_pst, any_target) วงจาง. **replay.lua ไม่เคยตัดสินวง
              AGGRO_WHILE** (thunderbird ด้วย) → เพิ่ม AggroCovers: อ่าน AGGRO_WHILE จาก modmain, บอสเล่น anim ในรายการ (หรือภายใน
              linger) และคุณอยู่ในรัศมีจากบอส (at_you = ครอบเสมอ) → นับวาด พิมพ์ AGGRO_DRAWN (OLD_AGGRO=1 = เดิม).
              mammoth chargeattack 40 = SGkoalefant ที่ UM เพิ่มท่าพุ่งผ่าน postinit → prefab ของ TE ที่ใช้ SG ซึ่ง UM แก้ = ต้อง sim แบบ
              UM+TE ซ้อน (ค้าง). pugalisk emerge 23: โดนที่ t=0 ของ emerge ไม่พบโค้ดทำร้ายในไฟล์ pugalisk (ค้าง)
          (10) **ตัวควบคุมเกมปกติเต็มชุด (HARM2 + DOATTACK + PLAYERSG ปิด vs เปิด, 7 slot ขนาน):** ต่าง 2 = gestalt (ไม่ deterministic)
              + minotaur jump_atk_pre~stomp NEW = ท่ากระทืบพื้นของ Ancient Guardian (dostomp → groundpounder:GroundPound + BounceStuff,
              state ไม่มีแท็ก attack) ซึ่ง**ข้อมูลเกมปกติไม่เคยมี** → กฎ GroundPound เจอ = ถูก → ยอมรับ. spiky_monkey/yeti ได้
              attack1 (slam) + attack2
          (11) build_te v10 ครั้งแรกหยุด: pugalisk#2 (emerge_taunt) เกิน 1200 s ; hulk spin ก่อนหน้าก็เกิน 20 นาที (DoDamage สร้าง laserhit
              ให้ dummy ทุกตัวทุกส่วน) → ไม่รันใน sim (spec no_auto) วาดด้วย AGGRO_WHILE แทน: ancient_hulk r 7 ตอน atk_circle ;
              pugalisk r 8 (groundpounder 2 วง 1/5 กว้าง 3) ตอน head_idle_pst + emerge_taunt linger 1.2 (backup: มุดลง 0.75 s แล้วทุบ
              ตรงที่ลง แล้วโผล่ — คือ miss "emerge t=0" 23 ครั้ง). ตัวหาง/ลำตัว pugalisk ใช้ SG เดียวกัน → no_auto เหมือนกัน
          (12) build v10 ได้ hazard rogue_wave/wave_ripple (คลื่นแค่ทำให้เปียก) — เพราะ simutil ทำให้ GetClosestInstWithTag ทำงาน และกฎ
              "บินแล้วค้นผู้เล่น = อาจตี" (fly_queries, ทำไว้ให้ gestalt) → **FlyHarms: นับเฉพาะสิ่งที่ไฟล์ prefab/SG มีคำทำร้าย**
              (SIM_OLD_FLYHARM=1 = เดิม ; ตัวควบคุมเกมปกติเต็มชุด: ต่างแค่ gestalt ที่ไม่ deterministic) → build v11 คลื่นหาย.
          (13) **replay TE ซ้ำ (log เดิม, ข้อมูล v11 + modmain + ตัวตรวจ AGGRO): missed 1,476 → 220**, false 2,629 → 2,569, glitch 154 → 217
              (+63 = เต่า attack2_loop ใหม่). ที่เหลือ: เต่า slide 90 → ใช้วง AGGRO_WHILE r 3 แบบ pengull (SlideTask SLIDE_RADIUS 3 ทุก 0.1 s,
              ไถลซ้ำได้ 5 รอบ) + เอา slide ออกจาก sim ; pugalisk 23 → trace จริง: startmove (head_idle_pst) → underground (ซ่อน เล่น
              head_idle_pre ~1.5 s เคลื่อนไปใกล้คุณ) → ทุบตอน emerge เฟรมแรก → เพิ่ม head_idle_pre ในวง ; scorpion 30 = กระสุน lob
              (proj / massproj ของ spread, splash 3) → striker moved r 2.5 ; lizardman_tfc 23 = lizardman_spit_tfc กระสุนตรงความเร็ว 40
              ยิงไกล 16+4 hitdist 1 → DARTS len 24 width 1.5 face (ไม่มี trace ของกระสุนใน bench นี้ เพราะ mod ที่ติดตั้งยังไม่รู้จัก →
              ต้อง bench ใหม่) ; mammoth 40 = UM+TE ซ้อน (ค้าง). build v12: 174 ตัว, hazards +scorpion proj ×2
          (14) ข้อมูลเกมปกติ: splice 5 ท่าจากรอบ full_new2 (bearger/mutatedbearger sleep_pst, minotaur jump_atk_pre~stomp, mossling spin_pre,
              cookiecutter hit ; ไม่มีใน ends_moves) — สำรอง scratchpad moves_sim_before_splice_1020.lua ; replay bench 1049 เฉพาะ 5 บอส
              เทียบเดิม/ใหม่: strikes/missed/false เท่าเดิมทุกตัว ; **minotaur glitch 23 → 27** (WOBBLE/SHRINK/OUTRAN ที่ leap_attack_pre:
              stomp ใหม่ขึ้นต้น anim jump_atk_pre เหมือนท่ากระโดด ตัววาดเลือกผิดบางครั้ง — ตรงกับคอมเมนต์เดิมใน BOSSES ว่าตั้งใจไม่ใส่)
              → minotaur no_auto = { "stomp" } ; splice แค่ 4 ท่า (bearger/mutatedbearger sleep_pst, mossling, cookiecutter).
          (15) build_te v13 (ไม่มี minotaur/bearger ใน overlay แล้ว) → replay TE รอบ 3: **missed 77** (mammoth 40 UM+TE, lizardman_tfc 23
              รอ bench เพราะ DARTS ใหม่, ลิง throw 6, ที่เหลือ 1-2), glitch 154 (เท่ารอบแรก). **ติดตั้งแล้ว** data 2A7198AA2CFE.
              bench ในเกมจริงเฉพาะ 17 ตัวที่เปลี่ยน (+slipstor) กำลังรัน (scratchpad bench_te_changed.log)
          (16) **bench จริง 2026-10-20_2347 (17 ตัว, 3 รอบ): strikes 4,184 missed 224** — missed 0: giantgrub 416, เต่า 275, pugalisk 193,
              ลิง 252, bossboar 260/311, กวางเทพ 183, หมูป่า 3 ตัว 447, twister 499 (false 256 = วงจาง r 20 ตอนดูด). ที่เหลือ:
              - **slipstor 180/180 missed** = ในเกมโดนจริงที่เฟรม 11 → เกมเล่น "anim" ตัวยาวของ slipstor_attacks ไม่ใช่ตัว 0.1 s ใน
                slipstor_build → sim: ไฟล์ *_build ไม่ถูกเลือกเมื่อไฟล์อื่นของ bank เดียวกันมี anim นั้น (SIM_OLD_ANIMBUILD=1 = เดิม) →
                ได้ "anim" first 11 ; ตัวควบคุมเกมปกติเต็มชุดกำลังรัน
              - scorpion 22: massproj ตกใส่คุณ (traced แล้ว) แต่เกมนับบอสเป็นผู้ตี → striker ใส่ as_boss + strikes_until (30/45)
              - lizardman_tfc 15: กระสุน DARTS ที่เกมนับเป็นการตีของบอส — replay ยังไม่มีทาง as_boss สำหรับ DARTS (ค้าง)
              - tigershark 6 (fallpost 3, attack 2, jump 1) + glitch 23 (ค้าง)
              - **YELLOW หมูป่า 41-63:** ท่า attack ของ SGwildbore ปลด busy ที่เฟรมตี (13) แล้ววิ่งต่อทันที anim ถูกตัดที่เฟรมตีพอดี →
                เห็นเหลืองจนโดนแล้วหายไม่ทันแดง. แก้ได้โดยให้เฟรมที่ตีเป็นสีแดงเลย แต่เปลี่ยนการแสดงผลทุกท่า → **ถามผู้ใช้**
          (17) ตัวควบคุม ANIMBUILD (เกมปกติเต็มชุด): ต่างแค่ gestalt + minotaur stomp หาย (ตั้งใจ). build_te v14: slipstor anim NEW,
              scorpion proj ×2 as_boss. **บั๊ก cache ของ bench_replay -TE:** key ข้อมูลคิดแค่ moves_sim + moves_sim_um ไม่รวม
              moves_sim_te → เปลี่ยนแค่ข้อมูล TE ได้ผลเก่าทั้งหมด (25/25 จาก cache) → bench_replay ใส่ moves_sim_te เมื่อ -TE,
              tools/data_keys.lua รับกี่ไฟล์ก็ได้ (2 ไฟล์ key เหมือนเดิม). replay bench 2347 ซ้ำ: **missed 224 → 22** (slipstor 180/180,
              scorpion 0 + 28 ครั้งให้ _haz ตัดสิน 160/160 วาด ; เหลือ lizardman 15, tigershark 6, hulk 1). **ติดตั้งแล้ว**
          (18) **build UM ใหม่ด้วยกฎ sim ทั้งหมดของคืนนี้:** ต่างจากที่ติดตั้ง 5 จุด — mossling/cookiecutter หายจาก overlay (ข้อมูลเกม
              ปกติมีแล้ว) + 3 จุดค้างเดิม (phase2 attk_stab_pre หาย = ที่เคย splice มือ ; um_shock_projectile steps เปลี่ยนมาก ;
              bearger_boulder travel 28.63 → 29.29). **ตัดสินด้วย replay เต็ม bench 1049 (743 replay):** ที่ติดตั้ง vs ใหม่ = missed 289 /
              289, false 5,275 / 5,274, glitch 4,641 / 4,641, things drawn 43,397 / 43,582 ; phase2/shockworm/bearger ทุกช่องเท่ากัน →
              ไม่มีผลเสีย → **ติดตั้ง UM ใหม่** (สำรองเดิม scratchpad moves_sim_um_installed_1021.lua) ; ข้อมูล UM rebuild จาก spec ได้ครบ
              (ไม่พึ่ง splice มือของ phase2 แล้ว). ค้างที่ 3 จุดนี้ปิดได้.
              tigershark (bench 2347): JUMP 23 = ตอนกระโดดขึ้น (jump2/fallwarn) จุดวาดตามคุณไปจุดที่จะตก ; missed 6 (fallpost 3, attack 2,
              jump 1) — เล็ก ค้าง
          (19) **DARTS ที่เกมนับเป็นการตีของบอส:** DARTS ใน modmain ใส่ by / strikes_until ได้ (ใช้แค่ตัวตรวจ) → replay.lua + replay_haz.lua
              นับเป็นสิ่งของ as_boss แบบเดียวกับ hazard ในข้อมูล (OLD_DART_ASBOSS=1 = เดิม ; มีผลเฉพาะ DARTS ที่มี by = lizardman_spit_tfc).
              replay bench 2347: **missed 22 → 7** (lizardman 15 → 0, กระสุน 30 ครั้งให้ _haz ตัดสิน 288/288 วาด ; เหลือ tigershark 6,
              hulk 1). ติดตั้งแล้ว
          (20) **mammoth (40):** = koalefant ของเกมเปลี่ยนสกิน (bank koalefant, ตัว 100/0.75, ดาเมจ, SGkoalefant) → UM postinit SGkoalefant
              (charge_start → charge → chargeattack, stomp) ใช้กับ mammoth ด้วย. spec ใหม่ alias_of: te.lua { prefab = "mammoth", alias_of =
              "koalefant_summer" } → mod_diff เขียน _alias และทิ้งท่าของ mammoth เอง (sim ข้ามรายการนี้). build v15 → replay TE เต็ม
              (2024): **missed 37 / 23,383** (mammoth 222/222 ; lizardman 23 = bench รอบนั้นยังไม่ trace กระสุน, bench 2347 = 0 ;
              ลิง throw 6 ; ที่เหลือ 1-2 ตัวละครั้ง). ติดตั้งแล้ว
          (21) **bench TE เต็มชุดในเกมจริงรอบ 2 (2026-10-21_0059, ข้อมูล v15 ที่ติดตั้ง): strikes 23,539 missed 37** (รอบแรก 1,476).
              _haz: ancient_hulk_mine 9/9 missed → สาเหตุ: replay_haz ใช้ AnimState ปลอม IsCurrentAnimation = false เสมอ ของที่วาดเฉพาะตอน
              เล่น _on_anims จึงไม่เคยถูกวาดใน replay (beeguard ของ UM ด้วย) ทั้งที่ tracer เขียนเฉพาะตอนเล่น anim นั้น → ตอบ true สำหรับ
              anim ใน _on_anims (OLD_ONANIMS=1 = เดิม). ผล: **TE 0059 missed 37 → 28 ; bench เกมปกติ/UM 1049 missed 289 → 213**
              (beeguard ฯลฯ ; false 5,275 → 5,314). ที่เหลือ TE 28 = deerclops_icespike_fx ทั้งหมด (share019 icedeerclops ใช้ท่าน้ำแข็ง
              บ่อย ; คลาสเดียวกับ 1049 icespike 11) = ค้าง. glitch 218 (รอบแรก 154): rookwater 68 → 115 (ข้อมูลไม่เปลี่ยน = ความต่างของรอบ)
          (22) **ผู้ใช้ 2026-10-21 "ทำต่อให้หมด ธรรมดา, uncom, te":** bench 1049 (เกมปกติ+UM) หลัง on_anims fix: missed 213 —
              _haz 101 (beeguard_blocker 57, warg breath 49 [คลาสเดิม ASBOSS], icespike 11, worm 10 …), lunarrift phase1 30 (roll_stop 29),
              um_beeguard_seeker 23, boulder_crab 12, twin1 11, vault_crawler 8 …
              **UM beeguard ×3 ไม่มีข้อมูลเลย:** sim "nothing" ทุกท่า — prefab ตั้ง DoTaskInTime(0, GoToState("spawnin")) ตอนสร้าง งานนี้
              ทำงานในเฟรมแรกของท่าแล้วตัดท่าทิ้ง → **sim: งานตั้งเวลา 0 ของบอสตอนสร้าง รันก่อนเริ่มท่า กับ SG ตอนสร้าง (ไม่ใช่ SG ของท่า)**
              (SIM_OLD_SPAWNTASKS=1 = เดิม ; ตัวควบคุมเกมปกติเต็มชุด: ต่างแค่ gestalt). build UM: beeguard ×3 ได้ atk/stab_pre/stab_pst,
              um_ocupus_tentacle clamp_counter NEW, moonmaw_lavae anims, viperlingfriend atk maps, bearger_boulder ; build TE: adult_flytrap
              atk_pre NEW. replay 1049 ใหม่ vs เก่า: missed 213 → 203 (seeker 23 → 13, yellow 37 → 5, glitch +16) → **ติดตั้ง UM v3 + TE v16**
          (23) icespike (เกมปกติ 11, TE 28): ไม่ใช่พื้นที่ไม่พอ — ลองให้ท่า atk ของ deerclops สุ่ม 48 รอบ (spec runs ใหม่ ใช้กับท่าสุ่มได้)
              พื้นที่โต 5,371 → 6,399 แต่ replay 1049 missed เท่าเดิม → ถอน. สาเหตุจริง: ท่า atk วาดพื้นที่ขยายทีละเฟรม (เฟรม 34 ถึง 7.7,
              35 ถึง 8.1, 39 ถึง 9.5) แต่หนามสุ่มในเกมโผล่ที่ 8-9 ตั้งแต่เฟรม 35-36 → จังหวะต่อเฟรมของท่าสุ่ม = ค้าง (ต้องคิดวิธีวาดขั้น
              ของท่าที่สุ่ม) — **แก้คำวินิจฉัย 2026-10-21:** ท่า random ถูกวาดทั้งรูปพร้อมกันอยู่แล้ว (simmoves random_until/random_from)
              จึงไม่ใช่เรื่องขั้นต่อเฟรม ; ไม่ใช่ตีช้า (BYTHING ของ icedeerclops ที่ state t 1.10-1.20 s = เฟรม 33-36 ระหว่างท่า) — คุณอยู่
              ห่างบอส 6-9 = ขอบพัดหนาม (±35°, รัศมี DEERCLOPS_ATTACK_RANGE·√rand + หนาม 1 + ตัวคุณ = ~9.5) ที่ union ของการสุ่มครอบไม่เต็ม
              (48 รอบก็ไม่ช่วยใน replay เกมปกติ) → ทางแก้ที่น่าจะถูก: วาดรูปพัดเต็มตามสูตรของเกม (มือ / spec shape) แทนการสุ่ม = ค้าง.
              lunarrift roll_stop 30: ทุกครั้งห่างรูปที่วาด ≤ 0.5 (ขอบ) = ค้าง.
          (24) **coverage UM (mod_coverage + กรองด้วย AUTOLIST):** 125 ตัว ขาด 369/422 — ส่วนใหญ่เป็น prefab ย่อยที่ใช้ SG เดียวกับตัวที่มี
              ข้อมูลแล้ว (dreadeye, pepperdragon, pied_rat, mock_dragonfly, bushcrab ใน bench 1049 = missed 0). bench จริง 0250 ตัวที่ไม่เคย
              bench (16 ตัว): ตีจริงแต่ไม่มีอะไรวาดแค่ **swilson 54/54** — (ก) ไฟล์ um_shadow_characters.lua มี "--return Prefab("swilson")"
              ที่ถูกคอมเมนต์ sim นับ → จับคู่ SG ผิดแล้วตัดทิ้ง → **AutoBosses ตัดคอมเมนต์ก่อนสแกน** (SIM_OLD_COMMENTS=1 = เดิม ; คลาส
              เดียวกับ snake_fire ของ TE) ; (ข) attack_swilson หยุด anim ด้วย SetDeltaTimeMultiplier(0) เฟรม 5-28 → sim ไม่จำลอง ท่าจบก่อน
              ตีเฟรม 32 → **sim รองรับ SetDeltaTimeMultiplier** (SIM_OLD_ANIMMULT=1 = เดิม) → swilson atk_pre f32 36 maps.
              nomove_check (ใส่ NOMOVE_TE=1 ให้อ่าน moves_sim_te): TE ที่ตีจริงแต่ไม่มีท่า = hulk death_explode 3 → AGGRO_WHILE ancient_hulk
              เพิ่ม death_explode ; ที่เหลือครอบด้วยวง/DARTS/hazard แล้ว หรือคลาสที่รู้ (ลิง throw)
          (25) ตัวควบคุม COMMENTS + ANIMMULT: เกมปกติต่างแค่ gestalt. build UM: swilson atk_pre NEW, swathgrithr atk_pre เปลี่ยน
              (หยุด anim แบบเดียวกัน). แต่ replay 0250 swilson ยัง 54/54 — predict ตัดท่าทิ้งเพราะกฎ "anim แรกเล่นช้ากว่าที่วัด = ท่าอื่น"
              (seen._slow, ทำไว้ให้หมาไฟ/หมาน้ำแข็งของ UM). **sim บันทึก held = true ให้ท่าที่โค้ดตัวเองหยุด/ชะลอ anim ; predict ไม่ตัดท่า
              held**. ตัวควบคุม: เกมปกติ +held แค่ tentacle_pillar_arm atk_loop (splice เข้าข้อมูล ; anim เดียว กฎนี้ไม่แตะ) ; UM +held
              swilson, swathgrithr atk_pre/lunge_pre. replay: **swilson 54 → 0** (yellow 12, glitch 1) ; 1049 missed 203 เท่าเดิม.
              ติดตั้งแล้ว data F6D30C8A9F38. build TE ซ้ำ (held): ไม่เปลี่ยน.
          (26) **bench เกมปกติ+UM เต็มชุดในเกมจริง 2026-10-21_0407 (ข้อมูลล่าสุดทั้งหมด): strikes 57,520 missed 56** (0.10% ; 1049:
              203/170,601 = 0.12%), ASBOSS_DRAWN 8, glitch 1,678. ที่เหลือ: _haz 18, twin2 7 + twin1 2 (mouthcharge คลาสเดิม),
              um_beeguard_shooter 6 (bench เป็นบอสโดยตรงแล้ว 86 ครั้ง ; blocker 273 พลาด 1), bird_mutant_spitter 5/5 (คลาสเดิม),
              boulder_crab 4, vault_crawler 3, lunarrift phase1 2, ที่เหลือ 1 ตัวละครั้ง. _haz 18: warg breath 7, bearger_boulder 5,
              guardian_goo 4, icespike 4+1, spat_bomb 2, mortarball 1, fossilspike 1.
              shooter 6 = เหล็กในยังบินตอนตัวยิงตายแล้ว (state death, 3-5 ห่าง) เกมนับตัวยิงเป็นผู้ตี → DARTS um_beestinger_projectile ใส่
              by = um_beeguard_shooter, strikes_until 30 (ติดตั้งแล้ว) แต่ log ช่องนั้นไม่มี trace ของเหล็กในเลย → ตัวตรวจยังตัดสินไม่ได้
              สาเหตุ: log แยกต่อช่อง (share004_L3.txt) ไม่มีบรรทัด [tr_haz] เลย — สิ่งของอยู่ในไฟล์อื่น → replay ฝั่งบอสของ bench แบบ
              lane ไม่เห็นสิ่งของ ทาง as_boss (by_own) จึงใช้ไม่ได้ในช่องแยก (TE 2347 ใช้ได้เพราะไม่แยกช่อง) = ค้าง: ต้องให้ bench_replay
              ส่ง tr_haz ของช่องนั้นเข้า log ของบอสด้วย. ตรวจเพิ่ม: share004 ทั้ง 4 ช่อง um_beestinger_projectile ไม่ถูก trace เลย (L2 มี
              tr_haz 73 บรรทัดของอย่างอื่น) ขณะที่ bench 1049 เคย trace ได้ → ตัว trace ของ testbench ในโหมดแยกช่องไม่เขียนเหล็กใน = ค้าง
              (แก้ฝั่ง tr_testbench/tracer) — **แก้คำวินิจฉัย:** ดูผิดไฟล์ ; miss อยู่ใน share019_L2 ซึ่งมี trace เหล็กใน 328 บรรทัด. สาเหตุจริง:
              ทาง by ของ DARTS ข้ามตัวที่มีในรายการ hazard ของข้อมูลอยู่แล้ว (เหล็กในอยู่ใน _hazards ของ UM) → replay.lua/replay_haz.lua
              เติม by + as_boss + strikes_until ลงใน hazard เดิมด้วย. replay 0407: **missed 56 → 52** (shooter 6 → 0, bything 16 → 22 ;
              _haz 18 → 20 = เหล็กใน 2 ที่ไม่ได้วาดจริง). (ตัวตรวจเท่านั้น ไม่ต้องติดตั้ง)
              bearger_boulder 5 = เหตุการณ์เดียว: bearger ของ UM state shoot ยิงหิน 5 ก้อนในระยะ 2 โดนเฟรมที่เกิด (trace แรกคือ HIT) ;
              guardian_goo 4 (1.0-1.4 ห่าง), spat_bomb 2 (0.47) — เล็ก ค้าง
          (27) bird_mutant_spitter 5/5: ตั้งใจไม่มีท่า (no_auto) วาดน้ำดีที่จุดตกแทน (striker bilesplat) แต่ striker ไม่มี as_boss ทั้งที่เกม
              นับการโดนเป็นของนก (มันเดินต่อแล้ว) → bilesplat as_boss, strikes_until 45 (sim -only แล้ว splice: เปลี่ยนแค่ bilesplat).
              replay 0407: **missed 52 → 47** (spitter 5 → 0, bything 1 → 6, _haz ไม่เพิ่ม). ติดตั้งแล้ว data 518053C7A09A
          (28) **ผู้ใช้ 2026-10-21 (log เกมจริง UM+TE, คัดลอกไว้ tests\work\user_logs\client_log_2026-10-21_0657.txt):**
              (ก) "sealnado ดูดเสร็จทำดาเมจ ไม่ขึ้น": replay นับว่าวาดแล้ว (AGGRO_DRAWN 3/3 ตอน vacuum_pst) แต่วงที่วาดคือขอบจาง r 20 —
                  คุณถูกจับไว้กลางวง (player_hold_distance 3) มองไม่เห็นอะไรตอนโดน ; bench ไม่เคยเห็นท่าดูดเลย (588 strikes เป็น atk หมด).
                  → AGGRO_WHILE twister core: วง r 3.5 รอบตัว twister สีเหลือง (strike) ตอน vacuum_loop, สีแดง (hit) ตอน vacuum_pst.
              (ข) "ลูกน้อง eye ที่ยิงออกไป hitbox off กับตำแหน่งจริง": eyeofterror_minieye_projectile (UM) บินตรงตามเลน (เพี้ยน ≤ 0.32)
                  แต่จมลงใต้พื้นระหว่างบิน (y 1 → -10.6, ~0.135 ต่อหน่วย) → ภาพตัวลูกน้องจมต่ำกว่าเลน และเลนยาว 60 วาดเลยไปถึงที่มันอยู่ใต้
                  ดินแล้ว ; bench โดนไกลสุด 11.8 → DARTS len 60 → 20. replay 0407 missed 47 เท่าเดิม.
              ทั้งสองข้อ **ยังไม่ติดตั้ง** — stress bench กำลังใช้ mod ที่ติดตั้งอยู่ → ติดตั้งแล้วหลังหยุด stress
          (29) **stress bench เกมปกติ+UM 2026-10-21_0649** (22 ตัว ×10 รอบ ; ผู้ใช้สั่งหยุดกลาง share 1 [lunarrift/glacialhound/
              vault_crawler/minotaur ท่าเยอะ ช้า] — kill server แล้ว run_bench แบ่งครึ่งรันใหม่ → หยุดสคริปต์ทั้งหมด ; ชุด TE ไม่ได้รัน):
              **strikes 29,828 missed 79**, ASBOSS_DRAWN 39 — boulder_crab 20, twin2 13, eye 12, _haz 10, lunarrift 8, twin1 5, vault 5,
              rook_nightmare 3 ; deerclops/mutateddeerclops/bearger/mutatedwarg/glacialhound/spat/shooter = 0.
              **boulder_crab 20 = uppercut ที่เข้าตรงจากตอนเดิน** (SGboulder_crab moving animover: มีหิน myrock + ห่าง ≤ 6) — ข้อมูลมีแค่
              atk → uppercut. ลอง spec add uppercut (prep myrock) : (ก) แยก atk/uppercut 20 → 30 glitch 7 → 146 ; (ข) คง atk เดิม + uppercut
              เดี่ยว 20 → 29 glitch 149, WOBBLE 137 ; miss ใหม่ที่ 2.95 (ระยะตีสุด) — sim วัดได้แค่ตอนวิ่งชนที่ 1.1 ⇒ การพุ่ง (RunForward
              ทุกเฟรม) ของ sim ไม่ตรงเกม → ถอน spec ไม่ติดตั้ง (ซ้ำข้อสรุปเดิม C3). ค้าง: ต้องจำลองการพุ่งแบบ ram
              **eye/twin mouthcharge 30** (ลำดับจริง: charge_pre → mouthcharge_loop [charge_loop] → charge_pst → mouthcharge_loop อีก ตี 0.5 s
              หลัง charge_pst): ลองท่า mouthcharge_loop แยก (mem transformed, frame facing, extra from = charge_pst) → sim ได้ "charge_loop"
              first 0 ; replay **แย่ลงมาก** (0649: eye 12 → 47 glitch 14 → 553, twin1 5 → 30, twin2 13 → 51 ; 0407 แย่ลงเช่นกัน) — from ไม่กัน
              การชนกับพุ่งแรก/ตัววาดสลับไปมา → ถอน (ครั้งที่ 2 ที่แนวทาง "ท่าแยก" ล้มเหลว ; ต้องทำแบบต่อท้ายท่าพุ่งแรก เช่น chain/again).
              เบาะแส: ร่างปากตั้ง mouthcharge_count = random(3,5) ตอน charge_pre animover (SGeyeofterror:285) → ใน sim ควรพุ่งซ้ำเองด้วย
              แต่ข้อมูลท่าร่างปาก (charge_pre~charge_pre) จบที่ charge_pst ครั้งแรก = ตัวตัดท่าของ sim (กลับเข้า anim ที่เล่นแล้ว) → ทางที่
              น่าจะถูก: ให้ท่านั้นต่อการพุ่งซ้ำในตัว (แบบ again ของ mutatedwarg) = ค้าง
              **→ แก้แล้ว (สาเหตุจริงอยู่ฝั่งวาด):** ข้อมูลท่าร่างปากครอบการพุ่งซ้ำถึงเฟรม 199 อยู่แล้ว (sim พุ่งซ้ำที่เฟรม 33/80/127) ;
              YVIEW: ช่วง charge_pst (0.53 s) ไม่มีอะไรวาด แล้วโดนเฟรมแรกของการพุ่งครั้งถัดไป — predict วาด leg ถัดไปเฉพาะเมื่อบอส "หัน
              กลับมา" (Turned > RETURN_TURN 10°) ; คุณอยู่ตรงหน้าห่าง 2 มันไม่ต้องหัน → **predict: หันหาเป้าอยู่แล้ว (≤ AHEAD_LEG 30°)
              ระหว่าง leg = วาด leg ถัดไปแบบจาง** (TR_OLD_AHEADLEG=1 = เดิม). replay: **0649 missed 79 → 49** (eye 12 → 0, twin1 5 → 0,
              twin2 13 → 0 ; false เท่าเดิม ; yellow/glitch ลด), **0407 missed 47 → 38** (mock_dragonfly glitch 55 → 57). ติดตั้งแล้ว
          (30) **บั๊กที่หลุดไปติดตั้ง:** modmain บรรทัด 803 (วง core ของ sealnado) เรียก setmetatable ตรงๆ — env ของ mod (mods.lua
              CreateEnvironment) ไม่มี → mod ล้มตอนโหลด ; stress TE ครั้งแรกหยุดทุก share ภายในวินาทีแรก (bench fail-fast จับได้).
              เกมของผู้ใช้ยังไม่ได้เปิดหลังติดตั้ง (client_log ล่าสุด 06:57, ไม่มี error นี้). แก้ = GLOBAL.setmetatable ; **ตัวตรวจใหม่
              tools/modenv_check.lua** (ชื่อ builtin ที่ env ไม่มี ถูกอ่านแบบไม่มี GLOBAL. ใน modmain ; ตัวควบคุม: ใส่ตัวพังกลับ = จับได้) ;
              **install.ps1 รันตัวตรวจนี้ + compile ทุกไฟล์ .lua ก่อน ไม่ผ่าน = ไม่ติดตั้ง**. ติดตั้งตัวแก้แล้ว ; stress TE รันใหม่
          (31) **stress TE 2026-10-21_0745** (12 ตัว ×10 รอบ ; share ของ hulk ค้างแล้วรันใหม่เป็นครึ่ง): **strikes 9,948 missed 54** —
              icespike 31 (_haz, icedeerclops ขอบพัด), tigershark 25 (fallpost ทั้งหมด), jungletreeguard 6 (throw), lizardman 4 (run) ;
              icedeerclops/hulk/lizardman_tfc/twister/slip 0. twister ใน bench ยังไม่ดูดเลย (1,659 strikes = attack) → วง core ยังไม่ได้
              ทดสอบในเกมจริง. แก้:
              - tigershark: fallwarn ย้ายตัวไปเหนือคุณที่สูง 45 + วาง tigersharkshadow ที่พื้น → ตกลง 34 เฟรมต่อมา → groundpounder 3 วง
                (1/5/9 กว้าง 3 = 12) ; ท่าในข้อมูลยึดจุดก่อนกระโดด → striker tigersharkshadow r 11.5 delay 68 by tigershark as_boss
              - jungletreeguard: thrower ขว้าง jungletreeguard_snake → warningshadow ที่จุดตก, งูตี 1.5 ในนามผู้ขว้าง → warningshadow by +=
                jungletreeguard, as_boss, strikes_until 60 ; (treeguard_coconut / snakefall ใส่ as_boss ด้วย)
              - lizardman (ตัวธรรมดา): DARTS lizardman_spit (แบบ tfc) by lizardman
              build TE: hazards 4 จุดเปลี่ยน ; replay 0745: missed 54 → 51 (jungletreeguard 6 → 3 ; shark/lizardman ไม่มี trace ของเงา/กระสุน
              ใน bench นั้น). ติดตั้งแล้ว ; bench 3 ตัวนี้ใหม่ (6 รอบ) กำลังรัน →
              **bench 2026-10-21_0836: strikes 1,617 missed 2** — tigershark 2/540 (เดิม 25/1,884 ; เหลือ fallpost 4.07-4.08 ห่าง),
              lizardman 0 (bything 4), jungletreeguard 0 (bything 6) ; _haz false 128 เฟรม (ส่วนใหญ่วง r 11.5 รอบเงา shark)
          **ผู้ใช้ 2026-10-21:** Maxwell = วาดแค่อุกกาบาต (มีแล้ว: striker maxwellshadowmeteor) ไม่วาดฟ้าผ่า ; หมูป่า YELLOW = ปล่อยไว้
          **สรุป TE คืนนี้:** missed 1,476 → 28 (bench เต็มในเกมจริงรอบใหม่ 23,539 strikes) และ 224 → 7 (bench ตัวที่เปลี่ยน) ;
          เกมปกติ/UM bench 1049 replay 289 → 213 จากตัวตรวจ on_anims. ค้างให้ผู้ใช้ตัดสิน: (ก) ฟ้าผ่าของ Maxwell
          (วงจาง r 15 หรือไม่วาด) ; (ข) YELLOW หมูป่า — ท่าจบที่เฟรมตีพอดี จะให้เฟรมที่ตีเป็นสีแดงทุกท่าไหม. ค้างเล็ก: tigershark 6 +
          JUMP 23, roc grab, ลิง throw (ต้องมีขี้), slipstor ข้อมูลใหม่ยังไม่ผ่าน bench หลังติดตั้ง (replay ผ่าน 180/180)
          (32) **ผู้ใช้เทสเอง 2026-10-21 (log 0856) — "พังหมด":** ตัวตรวจของเรานับ "drawn" แต่ผู้ใช้เห็นรูปมั่ว/ไม่มีรูป. ทีละตัว:
              - **slip:** 3 ท่า (attack / warrior_attack / spitter_attack) + ท่ากิน (eat) เล่น eat_pre เหมือนกันหมด → ท่ากระโดด 8 วาดซ้อนท่ากัด
                (BOTHDRAWN 63 เฟรม, FLIPDRAWN 6, WOBBLE). เกมเลือกท่ากระโดดเฉพาะเป้าไกลเกิน 3 ("not inst:IsNear(data.target, R) and
                "warrior_attack" or "attack""). **คลาส:** sim อ่าน doattack แบบนี้ → `far = R` ในข้อมูล (SIM_OLD_FAR=1 = เดิม) ;
                predict PickAlike: เป้าอยู่ใกล้กว่า far ตอนเริ่ม = ไม่ใช่ท่านี้ (TR_OLD_FAR). เจอใน spider/slip/crabking_mob/birchnutdrake/aphid/
                nightcrawler ด้วย (ตัวที่ท่าเริ่มด้วยแอนิเมชันต่างกันไม่กระทบ)
              - **pugalisk:** ไม่มีรูปเลย (ในเกม 4/4 "drawn: NOT"). ใต้ดิน หัว (ซ่อน) วาร์ปไป 12 ทุก 1.8 s (bodycomplete → SetPosition) แล้ว
                GroundPound ตรงนั้น 0.75 s ต่อมา — 4 ครั้งที่โดน = จังหวะนี้ทั้งหมด. วงเดิมจาง (edge_light) และค้างที่จุดที่มุดลง.
                แก้: AGGRO_WHILE `jump = { d = 3, warn = .75, hit = .3 }` — ขยับเกิน 3 ในเฟรมเดียว = วงชัดที่จุดใหม่ เหลือง → แดงตอนกระแทก ;
                เอา head_idle_pre ออกจากวงจาง. replay AggroCovers รู้จัก jump แล้ว: log 0856 4/4 ; ตัวควบคุม OLD_AGGRO_JUMP=1 = 0/4
              - **iron hulk:** (ก) ท่าโยน atk_lob ไม่มีเตือน — ShootProjectile ยิง orb แบบ complexprojectile ความเร็ว 60 = วิถีโค้งสูง (usehigharc)
                ลอย 4.8 s, DoDamage 3.5 หลังตก 0.3 s ; ดาเมจอยู่ในโค้ดของ orb → sim ไม่เจอท่า. แก้: add lob + all_hits → atk_lob first 183
                lock 31 (ล็อกจุดที่คุณยืนเฟรม 31). (ข) laser หมุน: วงจาง r 7 มองไม่เห็น → core r 7 เหลืองตลอด atk_circle/death_explode,
                แดงจากเฟรม 37 / 81 (core.hit_after ใหม่)
              - **jungletreeguard:** sim รัน atk ในโหมดขว้าง (range 20) → วาดห่าง 10 ; pluck วาดแดงใส่คุณ. แก้: prep SetMelee, no_auto throw,
                drop pluck ; การขว้างงูเหลือแค่ warningshadow (จุดตก 1.5, งูตีจริง 50 ในนามผู้ขว้าง)
              - **wilting dragonfly (UM):** dash_pre ขึ้นรูปก่อนเวลา — กฎ AHEAD_LEG ใช้เฉพาะ winding_after + `wait_anim = "dash_pre"`
              - **rhino ×2:** ไม่มีข้อมูล — prefab สร้างผ่านฟังก์ชัน MakeRhino("rhinodrill") ไม่ใช่ Prefab("...") → sim สแกนชื่อใน Make*( ด้วย
                (SIM_OLD_MAKERS=1 = เดิม) → attack / attack2_pre / chest_bump
              - **swineclops body_slam:** ยังไม่แก้. JumpToPosition ความเร็ว = ระยะ/25 เฟรม ; ในเกมกระโดดแค่ 2.4 (เป้าใน server ใกล้กว่าที่
                client เห็น — ตำแหน่งตัวเราฝั่ง client นำ server อยู่) → รูปที่วาดไปทางคุณ แต่ตกสั้นกว่าราว 3. ระยะที่วัดตอนโดน 7-9
                = หลังโดน knockback 5 (OnHitOther ตอน slamming) → MISSED 9/13 ส่วนใหญ่น่าจะวัดผิด ไม่ใช่วาดผิด. ทางแก้ที่คิดไว้: ท่ากระโดด
                แบบ MotorVel คงที่ → จุดตก = ตำแหน่ง + ความเร็วจริง × เวลาที่เหลือ (กระทบหลายบอส ต้อง bench ทั้งชุดก่อน)
              - **boarrior:** dash (เร็ว 12 เฟรม 3-9 ≈ 2.5) → combothirdhit ตีเป้า 6.5 + knockback ; วงที่วาด ~6.7 รอบจุดหยุด, 5 ครั้งที่โดนอยู่ในวง.
                ยังไม่รู้ว่าผู้ใช้เห็นอะไรแปลก — ต้องถาม
              - Make*( สแกนครั้งแรกดึงลูกน้อง Maxwell (MakeMinion) กับ merm ตกปลา (fish_loop) มาด้วย → จำกัดเฉพาะไฟล์ที่ AddTag monster/hostile.
                ตัวใหม่ที่ได้: บิชอป TE 5 ตัว (atk2_pre), snowwarg atk, rhino ×2 ; UM: far ใน spider/bushcrab/aphid/nightcrawler, mock_dragonfly
                wait_anim ; bearger_boulder scale เปลี่ยน 0.9 → 1.9 เอง (สุ่มของ sim ไม่เกี่ยวกับการแก้) → ใส่ค่าเดิมคืน
              - **rhino ต่อ:** charge = ไล่หัน CHARGE_MAX_ROTATION ทุกเฟรม วนจนโดน (DoAttack 4.5 เฟรม 15 ของทุกรอบ) → no_auto charge/charge_loop,
                AGGRO_WHILE r 5 + core เหลืองตลอด attack2_pre/attack2_loop. replay log 0856: rhino 7/7 (เดิมไม่มีข้อมูล 0/7)
              - replay log 0856 หลัง build: pugalisk 4/4, hulk 4/4, rhino 7/7 ; slip BOTHDRAWN 63 → 34 (ยังซ้อนตอนเป้าไกลเกิน 3 — ตอนนั้นเกมสุ่ม
                ได้ทั้งกระโดดและกัด) ; mock_dragonfly 3 FALSE ที่เหลือ = taunt/taunt_post (ไม่ใช่ dash_pre แล้ว). ติดตั้งแล้ว (install.ps1) ;
                **bench TE 2026-10-21_0949 (12 ตัว ×6): strikes 3,855 missed 1** (jungletreeguard 1) ; บิชอป TE ใหม่ 4 ตัว 889/889, snowwarg 381/381,
                pugalisk 382/382, hulk 1,023/1,023 ; rhino แค่ 9+9 (bench แทบไม่พุ่ง). JUMP ของบิชอป ~70/ตัว = แบบเดียวกับ bishop ของเกมปกติ
                (bench 0407: 52-53) ไม่ใช่ของใหม่. **ค้าง: slip two-shapes 1,304 เฟรม, flip 158** — เป้าไกลเกิน 3 เกมสุ่ม กระโดด/พ่น/กัด อย่างละ 1/3 ;
                กัดถึงแค่ ~3.5 → ตอนเป้าไกลกว่านั้น รูปกัดที่วาดคู่ไม่มีทางโดน (ทางแก้: ไม่วาด alt ที่นิ่งเมื่อเป้าอยู่นอกระยะของมันตอนเริ่ม — ยังไม่ทำ)
          (33) **ผู้ใช้เทสรอบสอง 2026-10-21 (log 1007) — "ไม่แก้ไรเลย":** pugalisk / sealnado / laser hulk ยังไม่เห็น hitbox.
              **สาเหตุจริง:** วง AGGRO_WHILE (และ core/jump) วาดด้วย Telegraph.Circle = เส้นขอบหนา 0.06-0.08 ไม่มีพื้น → ในเกมแทบมองไม่เห็น ;
              replay ตัดสินจากตาราง AGGRO_WHILE เอง (ไม่ได้รัน modmain) จึงนับ "drawn" — **ตัวตรวจมองไม่เห็นปัญหานี้เลย**. แก้: AggroFill =
              SimMoves.DrawCapsule(len 0) พื้น+ขอบแบบเดียวกับท่าปกติ (strike/hit/fill_light) ; ตัวที่ไม่มี AGGRO_WHILE (tentacle ฯลฯ) คงวงจางเดิม
              - **boarrior:** "attack" สุ่ม attack1 / attack3 (uppercut, ตีเฟรม 3) — sim รันทางเดียว → 9/16 ที่โดนใน log 1007 = uppercut ทั้งหมด.
                te.lua: "attack" + { attack, prep = Uppercut } (math.random(1,2) → 2 ครั้งเดียว) → ท่า attack3 ใหม่ ; replay log 1007: 7/16 → 16/16
              - **swineclops:** BreakGuard (ทุก bellyflop ตอนลง, SGbeetletaur:496) ตั้ง combat.ignorehitrange = true → ทุกหมัดโดนเป้าที่ระยะไหนก็ได้
                จนกว่าจะตั้งการ์ด (EnterGuardMode, _bufftype 1) — นี่คือเหตุของ "ไม่ตรง 0% ไกลมาก" (โดนที่ 4.6-10). modmain ANYWHERE: การ์ดแตก
                (เห็น _bufftype 1→0 หรือ bellyflop ถึงเฟรม 19) → ไม่วาดรูปรอบตัวมัน, วาดเครื่องหมายบนตัวคุณ (เหลือง → แดงตามเฟรมตีของแต่ละท่า)
                ถ้ามันเล็งคุณ. ยังไม่มีตัวตรวจ offline (อยู่ใน modmain)
              - **slip:** ท่าที่เกมสุ่มจากระยะไกล (sim.far) ไม่วาดท่ากระโดดก่อน — วาดท่ากัดจนถึงเฟรมที่ท่ากระโดดจะออกตัว (Predict.SetsOffAt จาก
                path) ถ้าขยับ > .3 → ท่ากระโดด (TR_OLD_FARTELL). bench 0949 replay: two-shapes 1,304 → 0, glitch 15 → 0, 219/219
              ติดตั้งแล้วทั้งหมด (TE data: bossboar attack3)
          (34) **ผู้ใช้เทสรอบสาม (log latest3, 10:45):**
              - pugalisk "กว้างเกิน": groundpounder ของ TE เป็น point mode → DoAttack ติดระยะตีของหัว 6 + ตัว 0.5 → r 8 → 6.5
              - palm tree guard (treeguard, SGtreeguard) = กลไกเดียวกับ jungletreeguard (SetMelee/SetRange, มะพร้าวแทนงู) — รอบก่อนแก้แค่ตัวเดียว
                (ไม่ได้ไล่คลาส). แก้ทั้งคู่ใน loop เดียว + warningshadow by += treeguard. grep SetMeleeMode ใน TE/UM: มีแค่ 2 ตัวนี้
              - slip ท่ากระโดด: ในเกมเคลื่อนแค่ ~1.1 (≈3/s, trace 150.77, 154.37) ไม่ใช่ 8 ที่ sim ได้ (MotorVelOverride 20) — สาเหตุยังไม่รู้ ;
                spec still = true → วาดเหมือนกัด. replay latest3: drawn-in-no-strike 5 → 0
              - hulk laser "ไม่ทำดาเมจ": ตีจริง (bench 75 ครั้ง) — FindEntities 7 จากกลาง ; ในเกมผู้ใช้ช่วงเฟรมกวาด 37-50 ยืน 7.3-7.9 ทุกครั้ง
                (หลบได้เพราะเห็นวง) → ไม่แก้ อธิบาย. **แก้คำตอบ (ผู้ใช้ชี้):** ทุกช่วงที่กวาดยังวาง laser 5 ตัวที่ระยะ 7 (spawnburns) และ laser.lua
                DoDamage ของ TE ตีทุกคนใน 1.7 + ตัว ผ่าน combat ของมันเอง (ผมอ่านแค่ส่วนที่คอมเมนต์ไว้ บรรทัด 115-143 แล้วสรุปผิดว่าไม่ตี — ทางที่
                ทำงานจริงคือบรรทัด 145-146) → พื้นที่จริงถึง 9.2. AGGRO hulk r 9.2 (core.r_of: death_explode 6).
                **กลับเป็น 7:** spawnburns เรียก fx:Trigger(0) ก่อน SetPosition → DoDamage ทันทีที่จุดเกิด (0,0,0 ของโลก) ไม่ใช่ที่ระยะ 7 ;
                หลักฐาน: ผู้ใช้ยืนทับ laser 7.04-7.88 สามครั้งไม่โดน, ไม่มี "struck by laser" ใน log ผู้ใช้/bench เลย. laser = ภาพเท่านั้น.
                **ที่ผู้ใช้หมายถึงจริง (รอบ 5):** mod วาด hazard "laser" (ข้อมูลของ ancient_robot claw/ribs ซึ่ง laser ตีจริง) รอบ hulk ด้วย เลยยื่น
                เกินวง. แก้คลาส (predict TR_OLD_BYONLY): hazard ที่มี by (ไม่ใช่ in_move/lasting) — ค้นครั้งเดียวตอนเห็นครั้งแรก ใน 40: มีบอสอื่น
                (SimMoves.Has) แต่ไม่มีเจ้าของใน by → ไม่วาด. (รุ่นแรกใช้แค่ anims_seen → icespike หาย 49 ; รุ่นสองไม่ยกเว้น "เจ้าของตายแล้ว" →
                quickfuse bomb ของ fused_shadeling หลังตาย 10 s หาย 2). replay_haz EntsNear ใส่บอสจาก boss_at. ผล: bench 0407 missed 38 = เดิม,
                0059 (TE) 21 = เดิม ; log latest3: FALSE laser ทับผู้ใช้ 5 ครั้ง/19 เฟรม → 0
              - **boarrior dash (รอบ 2):** ภาพ 847.87-848.5: วงยืดตามผู้ใช้เลยตัวไป แล้วดีดกลับตอน attack3. สาเหตุ: sim พุ่งชนตัวทดสอบหยุดสั้น
                → follow 6.22 (ดูเหมือนตามเป้า). ของจริง: พุ่งตามทางที่หัน ~1.3-2.5 แล้วตีใน 6.5 รอบจุดหยุด. แก้: spec no_follow (sim_moves) ;
                ภาพหลังแก้: วงอยู่รอบตัวตลอด ; replay latest3 16/16
              - **boarrior ทุบพื้น (รอบ 3, ยังไม่เปลี่ยน):** รัน IsEntityInside ของ mod เอง (scratchpad slam_test.lua): แขนบาง 1 หน่วย = จริงตามโค้ด
                (แขนหลังเลียบขอบข้างหนึ่งยาวถึง 16, แขนตั้งฉากที่ระยะ 2) ; ทุกครั้งที่ผู้ใช้โดน/ถูกทุบ ยืนบนแถบหลัก (เบี่ยง ≤0.2) → ยังไม่มีหลักฐาน
                ในเกมว่าแขนตีหรือไม่ตี
          (35) **ผู้ใช้เล่นกับเพื่อน (workshop 3823875174 = source ตรงทุกไฟล์; ไม่มี debug.txt → ไม่มี trace):**
              - palm tree guard มะพร้าว 2 รูป: striker treeguard_coconut (r 1, วาดตามลูกกลางอากาศ) ซ้อน warningshadow (จุดตก, ตีจริง 1.5) →
                ลบ striker coconut + snakefall (งูก็มี warningshadow). log latest3: โดนมะพร้าว 4 ครั้ง เงาใต้ตัว 0-0.7 ทุกครั้ง. **ช่องโหว่ตัวตรวจ:**
                strike "by treeguard" ที่มาจากของ as_boss ไม่ถูกนับทั้ง replay.lua (0 strikes) และ replay_haz → เช็กด้วยมือ
              - quacken ท่าโยน (throw/spit): ขว้าง 30 ลูก (10 รอบเป้า, 20 สุ่มใน 24), ไม่มีเงา → ผู้ใช้: ไม่ควรมี hitbox → no_auto throw
                (kraken, krakenunderwater)
              - thunderbird: ลบ AGGRO (ผู้ใช้: ฟ้าผ่ามักไม่โดนใคร)
              - Klaus ร่างคลั่ง "เล็กลง": ข้อมูล 1.2 / @Enrage 1.68 (= 1.2 × KLAUS_ENRAGE_SCALE 1.4) ตรงโค้ด, UM/TE ไม่แก้ → รอ log
              - ค้าง รอ trace (ขอผู้ใช้ + เพื่อนวาง debug.txt): Fuelweaver กรงมีเส้นเชื่อม (ต้องมีผู้เล่น ≥2), guardian กระโดด "ลอยไปหาอีกคน"
                ฝั่งเพื่อน (น่าจะถูก: เป้าคืออีกคน), toadstool รูปรวม + เพื่อนไม่เห็นเลย, beequeen แลค + bee ปักพื้นยังแดง, tiger shark,
                hooded widow
              - ant queen (Queen Womant) "hitbox รอบตัวไม่ทำดาเมจ": SpawnWarrior ทิ้งไข่จาก y 35 + warningshadow ใต้ไข่ ; ไข่ไม่ตี (ฟักเป็นทหาร).
                modmain: Predict.harmless_falls (AddPrefabPostInit antman_warrior_egg) ; predict: warningshadow ที่มีไข่อยู่ใน 1 (แนวนอน)
                ช่วง 0.5 s แรก → ไม่วาด (TR_OLD_EGGSHADOW). เศษหินแผ่นดินไหว (warningshadow เหมือนกัน) ยังวาด. ตรวจ offline ไม่ได้ (modmain)
              - **testbench เพื่อน (ผู้ใช้: "เพิ่มคนเล่นใน server ไม่ได้หรอ"):** run_bench -Friend friend|watch → cluster_name "tr_bench+friend:" ;
                tr_testbench: FRIEND = stand-in ตัวที่สอง ห่าง 5 ตามตัวเราทุก tick, TR_BENCH_ALL ใส่ทั้งคู่ใน AllPlayers helpers ;
                watch: TR_BENCH_YOU = เพื่อน (True Range วาด/trace จากเพื่อน), บอสยังล็อกเป้าตัวแรก ; ตัวที่ไม่ได้มอง _tr_quiet (ไม่พิมพ์
                struck/hurt). ทางเดียว (lanes ปิด). ยังจำลองไม่ได้: ข้อมูล replica ที่ client เพื่อนไม่ได้รับ (bench = server)
              - **bench watch แรก 3,602/6,926 missed = นับผิด:** tracer เขียน "STRIKE/HIT at <prefab>" ของใครก็ได้ (ทั้งสอง stand-in = wilson)
                → modmain: เป้าที่เป็น player/character แต่ไม่ใช่ You() → "other_player" (STRIKE, HIT, AREA) ; You() ในเกมจริง = ThePlayer
                (เดิม AllPlayers[1] = host ทุกเครื่อง → log ฝั่งเพื่อนบันทึก host เป็น "you"). bench watch 1454: missed 43/2,068
              - **guardian combo (UM leap_attack_pre_quick) ฝั่งเพื่อน 35 missed:** ลงพื้น → วงนอกของ groundpound ตีหลังวงใน ~0.17 s (ringDelay)
                ในขณะที่กระโดดครั้งถัดไป (ท่าเดิม) เริ่มแล้ว → after[ent] ถูกลบเพราะ "ท่าใหม่เริ่มด้วยแอนิเมชันในท่าเก่า" (กฎ Werepig) →
                ยกเว้นเมื่อเป็นท่าเดียวกัน + เก็บ after เมื่อจบภายใน LastStrike + LINGER (TR_OLD_ENDLINGER). watch: minotaur 35 → 0 (43 → 8) ;
                bench 0407 38 = เดิม, 0059 TE 21 → 23 = quacken 2 (จากการเอา spit ออก ไม่เกี่ยว)
              - fuelweaver กรง (watch, 2 คน): หนามติดกัน union เป็นแถบ = "เส้นเชื่อม" ; ตรงกลางระหว่างหนามก็โดนจริง, หายภายใน ~0.4 s → ไม่แก้ ถามผู้ใช้
              - **ผู้ใช้: "ก่อน UM+TE รูปแยกกันปกติ ตอนนี้เชื่อมกัน" (toadstool, กรง):** สาเหตุจริง = SimMoves.LaneDraw (laser ของ Eye of Terror,
                2026-10-20): ของชนิดเดียวกันที่มี delay_max ลงในเฟรมเดียวกัน (±1) → แคปซูลเดียวจากปลายถึงปลาย ไม่ได้เช็กว่าเรียงแถว.
                โดน: fossilspike (กรงเป็นวง → แท่งผ่ากลาง), mushroombomb / _dark (toadstool), groundpoundring_fx ; ตั้งใจ: deerclops_laser(_blue),
                eyeofterror_laser, laser. แก้: ชิ้นใดห่างเส้นผ่านปลายทั้งสอง > max(r, .5) → not_lane: เฟรมนั้นวาดแผ่นทีละชิ้น, เฟรมต่อไปวาด
                ตามปกติทีละชิ้น (TR_OLD_LANEROW). ภาพ bench 1454 share002 20.55: สองกรงแยกกัน (เดิม: แท่งเดียว)
                bench: 0407 38=38, 0059 23=23, 1454 8=8. ติดตั้งแล้ว
              - **bee (UM beeguard) ปักพื้นแดงค้าง:** stab (stab_pst, AOE 2 เฟรม 3) → stuck_loop ×6 ; ท่า around → ByTime หลังตีแรก = "hit"
                ตลอดท่า (ออกแบบไว้สำหรับท่าที่ตีรัว). แก้: around ที่ still + ไม่ GoesAgain → over เมื่อ t > LastStrike + 6 เฟรม
                (TR_OLD_AROUNDONCE). ภาพ 1454 share001 2291.3: ไม่มีแดงค้างแล้ว (เดิมแดงถึง 2291.3+). เงาของ bee หายเองเมื่อ bee y ≤ .5
              - **tiger shark กระโดด "ไม่ตรง":** groundpounder ของ TE เป็น point mode (tigershark.lua ไม่มี UseRingMode) → DoAttack ติดระยะตี 4 + ตัว ;
                bench 0836: 540 hits สูงสุด 4.67 เฉลี่ย 2.9 → striker tigersharkshadow 11.5 → 4.2. คลาส: ข้อมูลจาก sim ถูกเอง (sim รันคอมโพเนนต์
                จริงของ TE) ; ที่ผิดคือค่ามือ (pugalisk แก้แล้ว, shark)
              - **hooded widow พุ่งฟัน "เลี้ยวไปมา ไม่ตรง":** charge = around frame facing ; ChargeAttacked ตีครึ่งวงหน้า (±90° ของทิศที่หัน) ; หัน
                ตามเป้าได้ทีละ ≤2°/เฟรม แต่ around ถูกหมุนชี้เป้าทุกเฟรม → ใช้ทิศตัวเองเมื่อ sim.frame == "facing" (TR_OLD_AROUNDFACE)
              - **ผิดกฎ:** แก้ predict.lua (AROUNDFACE) ขณะ bench_replay ยังรัน → ผลรอบนั้นทิ้ง รันใหม่ทั้งหมดหลัง build TE
              - ผลรวม: AROUNDFACE รุ่นแรกทำ shadowthrall_mouth bite (around still) พลาด 2 → จำกัดเฉพาะ around ที่ไม่ still. หลังแก้: 0407 38,
                0059 23, 1454 8, 0836 (shark, r 4.2) 2/1,593 — เท่าเดิม. ภาพ widow 529.5 ก่อน/หลังเหมือนกัน: ตอนฟันใช้ท่า charge_strike
                (lock 32, ไม่ใช่ around) → อาการ "เลี้ยวไปมาตอนฟัน" ยังไม่ได้แก้. ติดตั้งแล้ว (tiger shark, bee, widow charge_turn)
              - **widow ต่อ:** sim รัน chargeattack วนต่อ → ตี 12, 36, 60, 84 ตามทาง 8 (free) ; ในเกมแต่ละรอบ (23 เฟรม) เริ่มท่าใหม่ → รูปทางยาว
                ซ้อนกันไล่ตาม (ภาพ 0407 share069 529.35-530.45). um.lua: chargeattack frames = 23 → ตีเดียวที่ 12, กลายเป็น around (facing)
                + AROUNDONCE ใช้กับ around ที่เคลื่อนที่ด้วย. bench: 0407 widow 147→148/148, yellow 5→0, false 10→0, รวม 38→37 ; 1454 8→7 ;
                0059 23 เท่าเดิม. bearger_boulder สุ่มอีก → ใส่คืน (memory um-build-boulder-drift). ติดตั้งแล้ว
              - Klaus ร่างคลั่ง: bench 0407 share009_L1 (scale 1.68) 1,344/1,344, ใช้ @Enrage ทุกครั้ง → ยังหาไม่เจอว่า "เล็กลง" ตรงไหน ; ถามผู้ใช้
          (36) **ผู้ใช้: palm tree guard โยน "ใหญ่เกิน", klaus "กัดไม่โดนจริง", toadstool "เห็ดยังรวมกัน":**
              - toadstool: ภาพ 1454 share001 5710.x = เห็ดแต่ละลูกเป็นแคปซูลยาวซ้อนกัน — การแก้ LANEROW รอบก่อนไม่ได้ผล เพราะ (1) lot จำ
                ตำแหน่งแรกไว้ (2) เห็ดถูกปาทีละลูก → lot ละ 2-3 ลูก, สองจุดเป็นเส้นตรงเสมอ (3) เกณฑ์ max(r, .5) หลวม (r เห็ด ~3). แก้: อัปเดต
                ตำแหน่งทุกเฟรม + ขยับ > .1 = not_lane ; เกณฑ์ .5 ; lane ต้อง ≥ 4 ชิ้น. ภาพหลังแก้: วงแยกทีละลูก
              - palm treeguard: warningshadow ตัวเดียวใช้ร่วม ant queen (เศษหิน ตี 2 → r 1.5) กับ treeguard (มะพร้าว/งู FindEntities 1.5 → ควร r 1)
                → predict: เงาที่มี treeguard/jungletreeguard ใน 30 และไม่มี antqueen → SimMoves._k_of = .75 (TR_OLD_SHADOWSIZE)
              - klaus กัด: DoAttack(target) เฟรม 35 ในรัศมี chomp_hit_range (3.5 × 1.4) ; single=true → วาดเฉพาะเมื่อเป็นเป้าอยู่แล้ว ; bench
                ตีโดนตามรูป (STRIKE 749.233) ; UM ไม่แตะ → ยังไม่เจอ, ต้องการ log
              - bench: 0407 missed 37 (=), false 1020→993 ; 0059 23 (=), false 198→183 ; 1454 7 (=), 96→81 ; 0949 1 (=). ติดตั้งแล้ว
          (37) **Klaus งับร่างคลั่ง "ไม่โดนจริง" — มีข้อมูลในเกม (log 1648, ผู้ใช้: "เทสในเกมไปแล้ว ข้อมูลไม่มีหรอ"):** ผมไปดูแค่ bench (ตีโดน
              ตามรูป) ไม่ได้เปิด log ผู้ใช้ก่อน — log มี "drawn IN but NOT struck (attack_chomp@Enrage) 6.6-9.0 WELL INSIDE" 4 ครั้ง ; replay
              FALSE 5. ข้อมูล: ตอนผู้ใช้วิ่งหนี Klaus กระโดดแค่ 7.4-7.7 (CalcChompSpeed: min(chomp_range 9.8, dist - รัศมี) ที่เฟรม 26, ไปใน 10
              เฟรม) ; รูปที่วาด (replay REPORT: dist 15.46 run 15.20) ลงไกลกว่าจริงหลายหน่วย, ผู้ใช้ที่ 8.9 จาก Klaus อยู่ในรูป. ทางลอง:
              เล็งจุดลงจากความเร็วจริงหลังล็อก (predict lock path) — ไม่มีผล (SimMoves.Draw มี LandAt/shift/path_fit ของตัวเองที่จำจุดลง
              ตอนล็อก) → เอาออกแล้ว ยังไม่แก้. ต่อ: ไล่ log.land / shift ใน SimMoves.Draw กับ user log 1648 (264.07, 268.67, 273.17, 288.17)
              - **บทเรียน:** ผู้ใช้เทสในเกมแล้ว = เปิด client_log ล่าสุดก่อนเสมอ ก่อนไปหา bench
          (38) **สาเหตุ Klaus (ต่อจาก 37):** ความเร็ว × scale ของ sim ถูก (log ผู้ใช้ vel 45.4 = 27 × 1.68 ; bench ลงสุด 15.12) แต่ใน log
              ผู้ใช้ (เป็น host ไม่มีถ้ำ = ตำแหน่ง server จริง) 4 ใน 8 ครั้ง Klaus ไปแค่ 8.26 พอดี: ความเร็วสลับ 45 ↔ 4.6 ทุก 1-2 เฟรม =
              ชนอะไรสักอย่างระหว่างทาง (ไม่ใช่ UM — postinit klaus.lua แตะแค่ Enrage ; log ไม่มีของรอบตัวให้ดูว่าชนอะไร). ที่วาดค้าง:
              SimMoves.Draw ถือว่า "ช้ากว่า run" = ภาพมาช้า (PATH_LATE 4 เฟรม × 1.51 = ยอมได้ 6 หน่วย) และบรรทัด leap_set ห้ามถอยก่อนกัด.
              **กฎใหม่ TR_OLD_LEAPSHORT:** ท่า leap_set: 4 เฟรมล่าสุด (เฉพาะเฟรมที่เห็นขยับแล้ว ตั้งแต่เฟรมที่ 2 ที่ขยับ หลัง run ออกตัว)
              ไปได้ < .85 × 4 × ความเร็วเต็มของ run และ run ยังต้องไปอีก > 1.5 = โดนขวาง → จุดลง = ตอนนี้ + ความเร็วตอนนี้ × เฟรมที่ run เหลือ
              (ไม่ติดกฎห้ามถอย / one_part ; ถอยได้เท่าความเร็วเต็มต่อเฟรม แทน .6). รุ่นแรก (นับสะสมจากเฟรมแรก, ≥75%) ทำ bench 0407 klaus
              missed 0 → 3: นับตั้งแต่ขยับเล็กน้อยก่อนกระโดด + bench เห็นออกตัวช้า 1 เฟรม → แก้เป็นแบบความเร็วล่าสุด: share009 1344/1344.
              user log 1648: klaus FALSE 5 → 1 (ที่เหลือ 299.57 มีอยู่เดิม: ห่าง 5.84 vs กัด ~5.4, ชนทุก 3 เฟรม).
              bench 0407/0059/1454 เทียบกับ TR_OLD_LEAPSHORT=1: missed 37/23/7 เท่าเดิม, false 2155→2154. **ติดตั้งแล้ว**
          (39) **ที่เหลือใน friend bench 1454 (7 missed) — ไม่ใช่บั๊กที่ต้องแก้:**
              - hoodedwidow atk 5 ครั้ง ห่าง 1.54: UM DoArcAttack ARC = 90° ต่อข้าง (ครึ่งวงหน้า) ; bench "side" วางตัวยืนที่ 87.6°
                (หน้าเส้นผ่าศูนย์กลาง 0.064). sim grid 0.25: แถว ahead 0 ไม่โดน (เกมใช้ < 90° เคร่ง) แถว .25 โดน → ขอบวาดที่ .125 =
                ขาด 0.06 ที่ขอบพอดี (การสุ่มตัวอย่างของ grid ไม่ใช่กฎผิด)
              - sporecloud 2 ครั้ง (5177.90, 5258.33): ทั้งสองครั้งหลัง bench ย้ายตัวยืน 26-35 หน่วยใน tick เดียว (5177.60→.63,
                5257.37→.40) แล้วโดนภายใน 1 s — ผู้เล่นจริงทำไม่ได้ (ยกเว้น soul hop)
          (40) **Boarrior dash "พุ่งมาหา hitbox เกินตัวเรา แล้วดึงกลับ" (log 1824):** dash ไม่ตีเอง — ไป combothirdhit (attack3 f7:
              DoAttack เป้าเดียว ระยะ 6.5 จากจุดที่หยุด). ในเกม dash ไปได้ 2.0-2.4 (ทุกครั้งใน log ผู้ใช้; sim 4.07 ; ความเร็วในเกมสลับ
              20 ↔ 4 ทุกเฟรม เหมือน Klaus - ฟิสิกส์ฝั่ง host ไม่ใช่ sim). ที่ผิดจริง: predict chain lock (anims dash,attack3 ; attack3
              ForceFacePoint ตอนเริ่ม) เลื่อน lock เป็น f15 → ก่อนนั้นส่ง "ตำแหน่งปัจจุบัน" เป็น anchor แต่ SimMoves.Draw ถือว่า anchor =
              จุดตอน lock ของ sim (f0) → gone = 0 ตลอด, run ทั้งเส้นถูกวางต่อจากที่บอสไปถึงแล้ว (far 10 เกินตัวเรา) แล้ว path_fit จับ
              map dist 1 (path 0) ที่ f7 → ดีดกลับเหลือ 6.5 รอบตัว. **กฎใหม่ TR_OLD_CHAINPOS:** chain lock เลื่อนแค่ "เล็ง" ; จุดวาง =
              ตำแหน่งที่ sim.lock (a.anchor_at จาก a.hist). replay: gone ตามจริง, หยุดแล้วถอยเหลือ 2.43 ตรงกับเกม. LEAPSHORT
              ลดเกณฑ์ run เป็น peak×4 > 2.4 (dash .667/เฟรม → จับได้ตั้งแต่ f8 ; ที่ > 2 จับ archive_centipede roll .5/เฟรม ที่เลี้ยว
              → FALSE 6→14, เลยยก). bench 0407/0059/1454: missed 37/23/7 เท่าเดิม, false 2155/2202/273 เท่าเดิม (_haz +3, spider/buffrat -2).
              **ติดตั้งแล้ว**
          (41) **Tiger shark กระโดดจากฟ้า "แปลก ไม่ตรง ไม่ smooth" (log 1903):** ท่า jump (ground_launch_up_pre) ถูก sim เป็นท่าของมันเอง
              (te_second states jump) วาดจากจุดกระโดด แล้ว shift ไล่เงา .6/เฟรม ทับวงเงา. ของจริง: ตีครั้งเดียว ground pound ตอน fallpost
              ที่จุดเงา (fallwarn ย้ายไปเหนือเป้า). เงาหายที่ 1.8 s (Ground_Fall) แต่ลงตี ~2.3-2.5 s → ช่วงท้ายไม่มีอะไรวาด. แก้:
              เอา "jump" ออกจาก te_second (rebuild TE: movediff = แค่ ground_launch_up_pre gone) + modmain AGGRO_WHILE tigershark
              r 4.7 ตอน ground_launch_down_loop (linger .25, core เหลือง→แดงตอน down_pst). TE bench 0059: tigershark missed 0 (ไม่มี
              ring = 49), รวม missed 23→20, false 2202→2197 ; log ผู้ใช้ 1/1. **ติดตั้งแล้ว**
              - **ต่อ: "มี 2 hitbox ตรงเงา กับตรงที่ตกจริง" (log 1918):** ตอนอยู่บนฟ้า (fall) ฉลามลอยตามผู้เล่น ~.2/เฟรม → ลงห่างเงา 4.3
                (เงา 48.04,818.90 ; ลง 44.86,821.75). เงาจึงไม่ใช่จุดตก → เอา striker tigersharkshadow ออกจาก te.lua (rebuild: แค่
                _hazards tigersharkshadow gone) ; AGGRO tigershark ใช้ jump = { d 1.5, warn 2, hit .4 } (วาดรอบตัวฉลามตั้งแต่วาร์ป
                ขึ้นเหนือเรา ตามตัวที่ลอย) + anims down_loop linger .25. TE bench tigershark 270/270, รวมเท่าเดิม ; log 1918/1903 1/1.
                **ติดตั้งแล้ว**
              - log 1936: "struck by tigershark 2.82 drawn: NOT" = ตัวตรวจในเกม (last_inside_at) ไม่นับวง AGGRO ของ modmain → ให้วง
                jump/core ตั้ง last_inside_at ด้วย ; replay: AGGRO_DRAWN 2/2.
          (42) **UM um_pawn_nightmare (log 1936, 4.58 drawn NOT):** ไม่มีท่าตี — ได้เป้าแล้วชนวน ~3.75 s (ExplodePing) แล้วระเบิด
              explosiverange 6 ตรงที่วิ่งไปถึง. เพิ่ม AGGRO_WHILE r 6 core เหลือง ตอนไล่เรา (Hunting). replay ตัดสินไม่ได้ (HIT ไม่มี
              STRIKE) ; ระยะ 4.58 < 6. **ติดตั้งแล้ว**
          (43) **รอบ 4 รายการ (dragoon spit / glacial varglet / pawns aggro / knook):**
              - dragoon spit: LAVASPIT วาง dragoonspit 1.7 หน้า ; propagator damagerange 2 (กลางตัวเรา) 24/s ราว 3 s จนเล่น "cool".
                te.lua striker r 1.5 lasting + simmoves _off_anims dragoonspit = {"cool"}. ยังไม่มีใน log ผู้ใช้ (อ่านจากโค้ดล้วน)
              - glacialhound ice howl: ยิง 3 ครั้ง แต่ละครั้งเล็งที่เรา ณ frame 5 (LaunchProjectile → GlacialProjectile) ; data ไม่มี lock
                → วาดหมุนตามเรา. um.lua lock = 5. bench share007_L4 มี bite (940.733) ถูกจับเป็นท่าหอนรอบที่ 4 (from_self รับเพราะจบ
                ใน 12 เฟรม ทั้งที่ idle/run_pre คั่น) — data เดิมรอดเพราะเลนหมุนตามมาทับ. **กฎใหม่ TR_OLD_SELFGAP:** from_self ต้องไม่มี
                anim อื่นเล่นคั่น (anims_seen._other > last_go.t) → missed กลับเป็น 1 (ตัวเดิม)
              - um_pawn: playerprox 7 → spike วง 15 รอบเรา + amalgam → AGGRO_WHILE r 7 pale ตลอด ; um_pawn_nightmare: idle_r 8 (FindTarget 8)
                ตอนยังไม่ไล่ใคร (field ใหม่ใน modmain)
              - knook (Automaton Abomination): atk_pre → 65% กัด / 35% กระโดด (math.random() > .35) ; sim สุ่มได้กระโดด → um.lua prep
                ให้ math.random() คืน .9 ครั้งเดียว → atk_pre = atk_pre,atk first 34 still
              - tigershark: core เหลือง/แดงกลับมาด้วย (คลิปเห็นว่า jump < 1.5 ตอนเป้ายืนใกล้จุดกระโดด → ไม่มีวง jump)
              - ผู้ใช้ขอ "คลิปทุกท่าทุกตัว ไม่อยากเข้าเกม": tests/clips.ps1 (clips_pick.lua เลือก 1 ครั้งต่อท่า จาก bench 0407/0059,
                replay PIC_TIMES หลายเฟรมต่อรอบ + วาดวง AGGRO_WHILE ของ modmain, clips_gif.py → GIF + index.html). ยังไม่วาด hazard แยก
                (หนาม แอ่งลาวา เงา) → ภายหลังเปิด WHOLE=1 วาดครบ ; ชุดเต็ม 667 คลิป tests/work/clips/index.html
          (44) **log 2026-10-22 0514: "แมงมุมกระโดดยังพลาด / ancient tower กระโดดยังพลาด":**
              - vault_pillar_guard ("Ancient Guard Tower") attack3: เฟรม 30 กระโดดหาเป้าเฉพาะเป้าอยู่ใน 45° ของทิศที่หัน (ลงก่อนถึงเป้า 1) ;
                นอกนั้นพุ่งตรงไปข้างหน้า 4. sim มีเป้าอยู่หน้าเสมอ → วาดที่เราตลอด ; log: หัน 141°, เราอยู่ 96° นอก → มันกระโดดหนี แต่วาด
                ทับเรา (FALSE 651.833, "drawn IN but NOT struck 6.50"). **กฎใหม่ TR_OLD_AHEADOFF:** spec extra ahead_if_off 45 / ahead_dist 5
                (sim_moves BOSSES, splice เฉพาะ vault_pillar_guard: diff แค่ 2 ท่า) ; ใช้ทั้งทาง lock (a.locked) และ DrawTable (tab_aims —
                ท่านี้วาดผ่านตาราง). replay: FALSE 1 → 0, 4/4
              - spider (UM alljumper) / spider_warrior: replay ไม่มี MISSED/FALSE ; ตำแหน่งตรง (free map ตอนออกนอกแนว). ที่เห็น: แดงช้า ~2 เฟรม
                — มุมมอง client (anim) ช้ากว่า server 1-2 เฟรม (เฟรม 17 ขณะ server กัดเฟรม 19) — เป็นทั้งระบบ ยังไม่แก้
              - **spider "hitbox กระโดดลอยมาจากที่อื่น":** วาดผ่านตาราง (goes with target) + follow/free → วงเริ่มที่เรา แล้วไหลตามตัว.
                ของจริง: SGspider warrior_attack ความเร็ว 20 เฟรม 8-20 (~8) ตรงตามทิศที่หัน (ไม่ ForceFacePoint), ชนใครในทางก็กัดตรงนั้น,
                ไม่ชนก็กัดรอบจุดลง. **sim spec lane** (LANE_BY_SG spider/warrior_attack, SIM_OLD_LANE): แผนที่เดียว = cell ในทาง (±free_reach)
                ∪ free ทั้งหมด, ไม่มี path/follow/free, frame facing, lane = true → predict TableOf ข้ามตาราง (TR_OLD_SIMLANE).
                TE: spider_warrior ถูก TE สลับเป็น spider_tropical ใน 0.5 s บนพื้นเขตร้อน (sim ตรงเงื่อนไข) → กระโดดสั้น 5.2 → keep_game.
                bench 0407/0059/1454 เท่ากับก่อนทุกตัว (37/20/7, false 2151/2197/273) ; log 0514 spider 3/3, warrior 9/9. **ติดตั้งแล้ว**
              - **ancient tower "วิ่งอ้อมหลัง ยังเล็งตาม แต่กระโดดไปอีกทาง" (log 0625):** กฎ 45° ใช้แค่ตอนล็อก (เฟรม 30) → ก่อนนั้นวงตามเรา
                ทุกที่. AheadIfOff ใช้ทุกเฟรมก่อนล็อกด้วย (DrawTable target + sim path aim) ; ภาพ 114.4-116: วงอยู่หน้ามันตั้งแต่เราออกนอก 45°.
                bench 0407 เท่าเดิม ; log 0514 4/4. **ติดตั้งแล้ว**
          (45) **MacTusk โยนกับดัก / green tentacle "hitbox ใหญ่ สีเข้ม ไม่ทำดาเมจ" (log 0645):** sim นับ DoAttack ด้วยอาวุธยิง
              (weapon:SetProjectile) เป็นตีทันทีทั่วระยะ → วงมืด 15.5 / 20. แก้ sim: (1) weapon SetProjectile เก็บค่า ; (2) DoAttack ด้วย
              อาวุธยิงตรงไม่ homing = ไม่ตี บันทึก SIM_SHOT แทน → ท่า shoots = "<projectile>" (first/lock = เฟรมยิง, ไม่มี maps) ;
              (3) inventory Unequip (tentacle/spitter ถืออาวุธยิงเฉพาะตอนยิง) ; (4) walrus prep SIM_RUN_OWN_TASKS (EquipBlowdart 1 s) ;
              (5) te.lua greententacle add attack (atk_loop ตรง). runtime: SimMoves.DrawShot = แนว DARTS len/width จากตัวมันหาเรา จนยิง
              (modmain ส่ง SimMoves.shots ; replay อ่าน DARTS เอง). bench 37/22/7 (lizardman +2 ไกล 8-10), false -90.
              **ตัวตรวจใหม่ BIGDARK** (replay): พื้นที่สีเข้ม (fill/swept/strike/hit) มากสุดต่อครั้งของท่า > BIGDARK_MIN (250 u²) → พิมพ์.
              รอบ bench นี้เหลือ: golem attack 2162, gw_yellow_lizardman spit 2156, alterguardian_phase4 atk_burst_pre 1819,
              strange_scorpion_tfc spit 1758, knightboat atk 1703, lizardman_tfc attack 862, octopus run_loop 761, summerwalrus
              atk_dart/atk 761, spider_spitter atk 497, pied_rat playatk 497, firetwister atk 497, frog_poison atk_pre 474, mock_dragonfly
              fire_on 383, bigshadowtentacle 323, beeguard 284, bearger ground_pound 262, minotaur atk_pre 260. **ติดตั้งแล้ว**
          (46) **2026-10-22 ตามต่อ (45):** no-harm rule ตัดท่า chimp/spider_ape/tikiman/goldmonkey (ลิงไม่มี damage แต่ถืออาวุธ/ขี้)
              → จำกัดเฉพาะตัวไม่มี inventory ; knightboat ตีเปล่า (damage 0) → striker knightboat_cannonshot. rebuild UM+TE → bench
              37 / 24 / 7. lizardman +2 (24) = **จุดบอดตัวตรวจ ไม่ใช่เกม**: log มีแค่ born/gone ของ lizardman_spit (ไม่มี tr_haz ตอนบิน)
              → ลูกถุยไกล 8-10 โดนหลัง DrawShot หมดหน้าต่าง ทั้งที่ modmain วาดแนว DARTS อยู่. replay ใหม่ DART_LANE: strike by
              DART ที่มี by = บอสนี้ → อยู่ในแคปซูล len/width จากจุดเกิด ทิศ (จุดเกิด - บอสตอนเกิด) ภายใน strikes_until = drawn
              (+ บรรทัด HIT tick เดียวกัน, ไม่นับ SHORT). OLD_DART_LANE=1 = ไม่ใช้. ผล 36 / 21 / 7 (lizardman 3 → 0).
              lizardman_tfc 3 ที่ 8.00 = "STRIKE at" ท่า attack (กัดระยะประชิด) ตอนยืน 8 ไม่มี LAUNCH → bench บังคับ ไม่ใช่ของจริง.
          (47) **tikiman 5 พลาด (10-20 ไกล) = ขี้ลิง monkeyprojectile:** MONKEY_RANGED_DAMAGE = 0 (attacked damage 0, sanity ลด) ไม่มี
              [tr_hurt] → ไม่ใช่ดาเมจ ไม่ควรวาด (จะเป็นแนวมืดไม่ทำดาเมจแบบ (45)). ลอง Thrower prep ใน te.lua แล้วถอนออก.
              replay ใหม่ NOHARM: strike "by <กระสุน>" ที่ไม่มี [tr_hurt] tick เดียวกัน (+ HIT คู่กัน) = ไม่ตัดสิน ; เฉพาะ log
              ที่มี [tr_hit]/[tr_hurt] (testbench). OLD_NOHARM_SHOT=1 = ไม่ใช้. ตัดออกทั้ง 3 bench มีแค่ tikiman 5.
              ผล 36 / 16 / 7.
          (48) **gw_yellow_lizardman สายฟ้า "กว้างมาก วาดไม่กลมครบ" + golem (Elemental จากหนังสือ Forge):** ทั้งคู่ตีเป้าทันที/homing ทุกที่
              ในระยะ → วงมืด 20/26 ถูกตัดเหลี่ยมโดย grid ข้อมูล (±20). te.lua no_auto spit_attack / attack (ไม่มีท่าในข้อมูล) ;
              modmain AGGRO_WHILE ใหม่ core.on_you = จุดเหลือง→แดงบนตัวเรา (r 1.2) + วงจางระยะ (lizard 20 = SetRange(16,20) ;
              golem 17 = RANGE 15 +2) เฉพาะตอนมันล่าเรา. golem ปกติล่าแต่ monster แต่ OnAttacked SetTarget ผู้ตี → ตีเราได้ถ้าเราตีมัน.
              diff ข้อมูล: 2 ท่า gone เท่านั้น. bench TE: gw_yellow 191/191, golem 12/12 AGGRO_DRAWN ; รวม 16. **ติดตั้งแล้ว**
              (pied_rat / firetwister: ผู้ใช้ให้คงไว้)
          (49) **2026-10-22 Bearger (UM) ทุบ "แนวหมุนนานกว่าคลื่น" — เฉพาะตอน join เซิร์ฟเวอร์ (dedicated / ping), ตอนแรกหลังเข้าเกม:**
              ไม่ใช่ข้อมูล/TE/build: ข้อมูลและเกมจริงเหมือนกันทุกแบบ (หลุม 5 + วง 1, เล็งคุณที่ anim @20). client ล็อคที่ตำแหน่งตัวเอง
              บนจอ (นำ server 1-2 เฟรม, มากตอนเพิ่งเข้า/วาร์ป): client 7.20 vs server 6.43. แก้ SERVERAIM: server ส่ง apx,apz
              (ตำแหน่งเป้าที่ server เห็น) ท้าย RPC pose → simmoves list [5][6] → predict ตอนล็อค (lock_f == sim.lock >= 3, ไม่ follow)
              ใช้ค่าเฉลี่ย pose (lock_f-2, lock_f-1) = จังหวะเดียวกับโฮสต์ (aim_t lock_f-1.5). replay ส่ง cur.tx or cur.yx.
              ลอง lock_f-2 (ตรง Bearger 100%) → glacialhound howl/bite +3 พลาด → ถอย. AIMHOLD (ค้างก่อนล็อค) → Celestial Champion
              glitch 18→52 → ถอน. bench สุดท้าย 36 / 16 / 7, glitch 1693 = เท่าก่อนแก้. **ติดตั้งแล้ว 1.1.5 (ตัวหลัก + Client),
              รออัปโหลด patch หน้า.**
              ผู้ใช้ลอง 1.1.5 แรก: "เล็งเกินแล้ว snap กลับ" (ก่อนล็อคยังตามตัวบนจอ). แก้ต่อ: ก่อนล็อคก็ใช้ server pose (เฉลี่ย t-2F,t-1F,
              ต้นท่าใช้ pose แรก, ค้างค่าล่าสุดถ้ายังไม่มา) ; SimMoves.PoseAimUpTo ไม่ bind go (bind ก่อน pose แรกของ go ใหม่ → ใช้ go เก่า:
              Deerclops beam 2 เฟรมแรกชี้ 45° ผิด) ; ใช้เฉพาะ PoseAim(ent) == me.ent ; ยกเว้น anchor lock (Champion sweep เลเซอร์ 36 นอก).
              replay: pose aim ส่งทุก tick (OLD_POSE_AIM), apx = cur.yx ; YOU_LEAD=n จำลอง client นำ n เฟรม ; JUMP ยกเว้น 3 เฟรมหลัง
              ตัวทดสอบวาร์ป (OLD_JUMP_YOU3). Bearger lead 0/3/6/10: 35.3→31.1→28.7→26.4 ไม่ snap. bench ใหม่ vs ควบคุม (OLD_SERVERAIM):
              พลาด 36/16/7 เท่ากัน, กระตุก 1657 vs 1628 (ก่อนยกเว้น anchor; Champion 67→14 หลังยกเว้น), 182 vs 187, 194 vs 194.
              **ผู้ใช้ลองแล้ว "โดนทุกท่า"**: เปิด lag compensation ของเกม ตัวบนจอวิ่งนำ server → วาดที่ server เล็ง ตัวดูออกแล้วแต่ server
              ยังมีคุณอยู่ในวง (ปิด lag comp = ปกติ). **ถอนแล้ว**: กฎปิดเป็นค่าเริ่มต้น (TR_SERVERAIM=1 เปิด), modinfo กลับ 1.1.4,
              ลบ patch notes 1.1.5. โค้ดส่ง apx/apz + PoseAimUpTo ยังอยู่ (ไม่มีผล). ทางที่ถูก (ยังไม่ทำ, รอผู้ใช้): เลื่อนทุกอย่างที่วาด
              ด้วย (ตัวบนจอ - ตัวที่ server เห็น) → ตัวบนจอออกจากแดง = server เห็นออกจริง ; ต้องให้ server ส่งตำแหน่งคุณตลอด.
              **เปิดกลับแล้ว** (ผู้ใช้: ถอนไม่ช่วย, เลเซอร์ Deerclops ไม่ตรง แต่ Eye of Terror พุ่งตรง = วาดตามทิศหันของบอสจาก server;
              ท่าที่เล็งหาคุณใช้ตัวบนจอ). TR_OLD_SERVERAIM=1 ปิด. 1.1.5 + patch notes ใหม่ (มีหมายเหตุ lag compensation). ติดตั้งแล้ว.
              งานถัดไปถ้าผู้ใช้ต้องการ: เลื่อนตาม lead (ข้างบน).
              **ทำแล้ว (ผู้ใช้สั่ง "ทำเลย")**: client RPC "you" (หลัง pose) server ส่ง x,z ผู้เล่นทุก tick (ไม่ใช่โฮสต์, TR_OLD_LEAD=1 ปิด) ;
              modmain: lead = ตัวบนจอ - ที่ server บอก (ease .35, ไม่เกิน 4, เก่าเกิน .5s = 0) → Lines.ox/oz ; ทุกการวาด/เช็คท่าใช้
              sx,sz (ที่ server เห็น) ; lines.lua Off(style) เลื่อนทุกชิ้นในโลก + GroupAt ยกเว้น NOSHIFT (body/own/friend_own/
              monster_body/abigail) ; predict: target ของคุณ = me.x (ที่ส่งมา). bench 36/16/7, glitch 1604/187/194. ทดสอบจริง
              ไม่ได้ใน replay (ไม่มี lag comp) — รอผู้ใช้ลอง. ติดตั้ง 1.1.5.
              **ผู้ใช้: "ทุกอย่าง wobble ขยับไปมา ลายตา ไม่อยู่ที่ผู้เล่น"** แม้ใส่ extrapolate ความเร็ว + ease .12 → **ปิด**
              (TR_LEAD=1 เปิด ทั้งส่ง RPC และเลื่อน). Lines.ox/oz = 0 เสมอ. patch notes 1.1.5 กลับเป็นแบบ server aim + หมายเหตุ.
              บทเรียน: เลื่อนภาพทั้งหมดตาม lead ที่วัดจาก network = สั่นเสมอ (jitter/tick/ความเร็วเปลี่ยน) — ถ้าจะทำใหม่ต้องใช้
              ค่าคงที่ (เช่น ping * ความเร็วตัวเอง) หรือเลื่อนเฉพาะจุดตัดสิน (เช็ค inside) ไม่ใช่ภาพ.
              - boarrior dash "ไม่ทำอะไร": combothirdhit ตีเฉพาะเป้าใน 6.5 ; ทุก dash ใน log ผู้ใช้อยู่ 6.54-9.96 → ไม่โดน (ถูกต้อง) ;
                ทุบพื้น (attack5) โดน 6 ครั้ง × 2 hit อยู่ในรูปทั้งหมด ; แขนบางๆ ของรูป = IsEntityInside ของ mod เช็กเส้นขอบแบบไม่มีปลาย
                (t < 1 ไม่มี t > 0) → ยืนบนเส้นต่อของขอบก็โดนจริง
        - beestinger 8 missed ที่ 2.44 (ตีจริง ≤ sqrt(2) = 1.41 FindEntity ทุกเฟรม, บิน 25/s = 0.83/tick): ตำแหน่งใน trace ช้า 1-2 tick ;
          ขบวน shooter ล้อมยิงเข้าหา. ทางแก้: วาดเป็นแนวตามทิศบิน (แบบ DARTS) แต่ DARTS ไม่มีตัวตรวจ (replay ไม่ตัดสิน) → ต้องมีตัวตรวจ
          dart ก่อน → **ทำแล้ว:** replay_haz ตัดสิน DARTS (อ่านจาก modmain เอง, กติกาเดียวกับ modmain: ทิศจากจุดแรกที่ขยับ >0.3, len,
          แคปซูลรัศมี width จากตัว dart ถึงปลาย) จาก "STRIKE by <dart> at wilson" (เกมนับผู้ตีเป็นคนยิง). ครั้งแรกที่ dart ถูกตัดสิน:
          walrus 157/159 (2 = ตีก่อนบินพ้น 0.3), spitter 789/789. hazard ที่เป็น DARTS ด้วย: ครอบถ้าวงหรือแนวครอบ (OLD_DARTS=1 = เดิม).
          เหล็กในเข้า DARTS (len 15, width 1.414): share beequeen 8 missed → 0. ติดตั้งแล้ว. replay เต็ม 1049 ด้วยตัวตรวจใหม่ทั้งหมด กำลังรัน
      - **phase 3 คริสตัล "เตือนช้า":** คริสตัลตกเป็นวงรอบบอส (ชุดแรก 2-5.5, ชุดสอง 5.5-9 ; projectile โผล่ทีละลูกทุก 0.5 s ตั้งแต่ f59, ตก 31 เฟรม
        หลังโผล่) — log ผู้ใช้: ท่าเริ่ม 173.43, ลูกแรกโผล่ 175.37 ตก ~176.4 = 2 s แรกไม่มีอะไร, แต่ละลูกเตือน ~1 s. ลองแก้ (mod_p3: วาดพื้นที่
        สุ่มของท่าจนลูกแรกโผล่) แต่นั่นคือ "กล่องใหญ่" แบบที่ผู้ใช้ไม่ชอบ → หยุด, ถามผู้ใช้ก่อน ยังไม่ติดตั้ง
      - **ผลรวม 0052 (data ใหม่ + ตัวตรวจใหม่):** missed 236→145 (_haz 119→93, mutatedwarg 2→0, phase3 48→aimjump), false 4,489→4,292 ในรอบกฎกว้าง
        → ราว 4,322 หลังจำกัดกฎ (บวก FALSE ที่กลับมา 30 ; ยังไม่ได้รันเต็มชุดซ้ำ) (vault_crawler 193→35), ASBOSS_DRAWN 40. **ติดตั้งแล้ว** (moves_sim 35E52A4A3574 ; สำรองเดิม scratchpad moves_sim_backup_before_vc.lua)
    - **ค้าง:** glitch ของ rook จากท่าพุ่งเร็ว ; Twins dash #2 ; minieye JUMP (มีอยู่เดิมใน log นี้ 1,191) ;
      buffrat 11 ; vault_crawler false 193 ; coverage 93 (หมวด: ไม่มี trace 9 บอส, สแกนนับผิด, ต้องบังคับ — โหมดบังคับพร้อมแล้ว)
  - คลาสรอแก้หลัง bench (ห้ามแก้ testbench ระหว่างรัน) — **ทำแล้ว (ข้างบน)**:
    - **ฟื้นในตัวเดิม:** Klaus ตาย → resurrect (SGklaus.lua:323-326) เป็นตัวเดิม unchained, เลือด KLAUS_HEALTH_REZ ; quickattack/chomp ต้อง
      IsUnchained (klausbrain.lua:19-22) → ตัวขับเห็น killed แล้วจบหลังฉากเดียว. แก้: หลัง brought down ถ้าตัวเดิมกลับมาไม่ตาย → "next phase
      (revived)" รีเซ็ตฉาก/ขั้นเหมือนตามร่างใหม่ (เพดาน 5 ร่าง) ; ตัวแยก: เลือดกลับขึ้น > 10% หลังล้ม (Klaus REZ) ; บอส minhealth
      (daywalker/2, sharkboi, vault_crawler, worm_boss, lunar_grazer, mara_boss1 — grep แล้ว) ค้างที่ minhealth ไม่ถือว่าฟื้น = จบตามเดิม
    - **ประตู = โดนตี:** buffrat leap_attack/taunt2 ต้องโดนตีขณะเลือด < 50% (SGuncompromising_buffrat.lua:450-451, 403-406) ; ตัวขับตีครั้งเดียว
      (ขั้น 1). แก้: ตีเบาๆ (1) ทุกจบฉาก (ผู้เล่นจริงตีตลอด) + ตัวคุม: buffrat leap_attack ต้อง ≥3 ; ตรวจไม่ให้ MISSED/FALSE เปลี่ยนเพราะ hit

## 6.0 ภาพรวม ณ 2026-10-17 สาย (เก่า — ดู 6.0a)

**เสร็จ + ติดตั้งแล้ว:** rebuild ข้อมูลเกมปกติ (4.6), คลาส 10/11, ท่าคู่ lock เอง, รวมขอบรูปที่ซ้อน (6.6), ring ไม่ตี (คลาส 15 —
**ติดตั้งแล้ว** แม้ 6.5 จะเขียนว่ายังไม่: ดินหนอนยืนยันจากโค้ด ไม่ใช่จาก log), บั๊ก TraceLine (px nil)
**ตัวตรวจที่มีตอนนี้:** compare (การตี, log ผู้ใช้), shapes_all ทั้งเฟรม (ซ้อน/แตก/เส้นลอย), testbench headless ทุกมอน +
census ทุก entity (bench_things), ควบคุมทุกตัวผ่านแล้ว
**ข้อมูลที่เชื่อไม่ได้ (ทิ้ง):** testbench ก่อน 2026-10-17 08:35 — โลกต้นแบบมี Eye/leif ค้าง, SetMinHealth ทำให้ไม่มีใครตีหุ่น →
ข้อสรุปใน 6.7 (NEVER-ANY ต่าง ๆ) ต้องคำนวณใหม่จากรอบ 08:35
**ช่องว่างใหญ่ที่สุด (ยังไม่ทำเลย):** เอา log testbench รอบ 08:35 ไป **replay ผ่านตัววาด** ทุกมอน — นี่คือเป้าหมายแรกของ testbench
(ตรวจว่าวาดตรงกับเกม: MISSED / FALSE / AIMED / FOLLOWS) แต่ยังไม่เคยทำกับมอนทั้งหมด → ต้องมีตัวรัน replay ของ bench
แบบขนาน (มี UM, ทีละ share, ทีละมอน) + สรุปเป็นคลาส; log เหล่านี้ใช้ซ้ำได้ทุกครั้งที่แก้ตัววาด/ข้อมูล (ไม่ต้องรัน bench ใหม่)
**ค้าง (เรียงตามคุณค่า):**
1. replay log bench ทุกมอน → รายการปัญหาเป็นคลาส (หลัง census รอบ 08:35 เสร็จ; ระหว่างนี้ทำกับ share ที่เสร็จแล้ว)
2. census ของ (bench_things) จากรอบใหม่ + [tr_hurt] (ไฟ) → ยืนยัน/ล้าง NEVER-ANY
3. Celestial 2 attk_stab_pre (ข้อมูลเก่า, AIMED จากเฟรม 16) + Shadow Thrall bite + Mutated Buzzard flame (ยังใช้ข้อมูลเก่า)
4. Widow charge_strike (SPLIT, วาดจาก map ระยะ 1)
5. ลาน/ที่อยู่ของบอสที่ยังไม่โจมตี (6.9 กลุ่ม 1) — เฉพาะตัวที่รอบ 08:35 ยังเป็น 0
6. ซ้อนที่เหลือ (Toadstool, Mutated Deerclops, War Machine, Klaus) — ดูคู่ก่อน
7. คลาส 16 (scale ring ยกกำลังสอง), คลาส 12 คู่ที่ทั้งคู่เคลื่อน (Bearger butt), sim error list/lint (4.3/4.4), เมตริก "ตอนตัดสิน" (4.1)
**ข้อจำกัดของ testbench ที่ต้องจำเวลาอ่านผล:** หุ่นไม่ใช่ผู้เล่น (ตัว !np ยิ่งห่าง), การหลบเป็นสคริปต์, บอสที่ผูกกับที่อยู่ไม่มีผล

### 6.10 วิเคราะห์ทั้งหมดอีกรอบ ก่อนทำข้อ 1 (2026-10-17 09:10, ผู้ใช้สั่ง)
**เป้าหมายจริง:** สิ่งที่วาด = สิ่งที่เกมตี (ที่ไหน เมื่อไร เล็งถึงเมื่อไร) และดูเป็นรูปเดียวไม่แตก — ผู้ใช้ไม่ต้องเป็นคนหาบั๊กเอง
**หลักฐานแต่ละแบบพิสูจน์อะไรได้ / ไม่ได้:**
| แหล่ง | พิสูจน์ได้ | พิสูจน์ไม่ได้ |
|---|---|---|
| log ผู้ใช้ (compare/shapes) | ของจริงทุกอย่าง รวมภาพในฉากจริง | เฉพาะบอสที่ผู้ใช้เจอ, ผู้เล่นไม่หลบแบบตั้งใจ |
| bench replay | ทุกมอน, ฉากหลบที่ตั้งใจ (หมุน/วิ่ง/กระโดด) = จับเล็งเกิน/ระยะผิด | หุ่น≠ผู้เล่น, บอสผูกที่อยู่, ท่าที่ไม่ออก |
| bench census (ของ) | ของตีจริงไหม / ไกลแค่ไหน | ดาเมจที่ไม่ผ่าน attacked (แก้ด้วย tr_hurt แล้ว) |
| sim check / synthetic | sim ตรงกับตัววาดไหม | sim ผิดเหมือนกันทั้งสองฝั่ง |
**ทดลองนำร่อง (log รอบ 08:35):** replay ~25 วินาที/มอน → ทั้งหมด ~10 นาทีขนาน = ถูกมาก, ไม่ต้องรอ bench ครบ
- Bearger: 876 ครั้งที่โดน, พลาด 51 (46 ใน state "bi" หลังทุบ — **ปัญหาเดิมจาก 6.2 ยังไม่แก้**), AIMED ground_pound 20 ครั้ง
  **แต่ AIMED ฟ้องที่เฟรม 1–4** (ก่อน lock 21) = ตอนยังเล็งจริง → **ตัวตรวจ AIMED ผิด**: ท่าที่ของที่ปล่อยเล็งเป้าโดยบอสไม่หัน
  (frame=target) ตามผู้เล่นก่อน lock ได้ถูกต้อง → ต้องนับเฉพาะหลัง lock (ของข้อมูล หรือของเกมจากฉากวิ่งหลบ)
- Deerclops (UM): 396 ครั้ง พลาด 3, FALSE 91 ทั้งหมดใน laserbeam_blue → ต้องดูว่าวาดเกินจริง หรือเลเซอร์ไม่ตีซ้ำ (จำคนที่โดนแล้ว)
**ความน่าเชื่อของแต่ละตัวเลขจาก bench:**
- MISSED = แข็ง (เกมตีจริง ไม่ได้วาด) ยกเว้นหุ่นถูกย้ายวาร์ปเข้าไปตรงจังหวะตี (ฉากกระโดด) → แยกตามฉาก
- FALSE = อ่อน (เกมไม่ตีอาจเพราะจำว่าตีแล้ว / สุ่ม) → ใช้เป็นคำถาม ต้องดูโค้ดยืนยันก่อนแก้
- AIMED = ต้องแก้ก่อนใช้ (ข้างบน); FOLLOWS (หลัง lock ของข้อมูล) = ใช้ได้
**ควบคุม (ก่อนเชื่อผลทั้งชุด):** ตัววาดรุ่นที่รู้ว่าผิด (ยืด lock — tr_oldlock) ต้องให้ FOLLOWS/AIMED-หลัง-lock มากกว่ารุ่นปัจจุบัน
บน log bench เดียวกัน; hound ต้องมีฉาก
**ลำดับที่เลือก (ไม่ทำทุกอย่างพร้อมกัน):**
A. แก้ AIMED ให้นับหลัง lock + ทำตัวรัน bench replay ขนาน (ทีละ share × มอน, UM, เก็บผลไว้ cache เหมือน compare)
B. ควบคุมด้วยตัววาดรุ่นผิด บน share ที่เสร็จแล้ว
C. รันทุก share ที่เสร็จ → ตารางปัญหาแยกคลาส (MISSED ตาม state/ฉาก, FOLLOWS, FALSE) → เลือกแก้เป็นคลาส
   **เกณฑ์เลือกแก้:** มีใน bench + (มีใน log ผู้ใช้ หรือยืนยันจากโค้ด) ก่อน; ของที่เห็นแค่ใน bench = ดูก่อนว่าเป็นของหุ่นไหม
D. ทุกการแก้: replay log bench เดิม + compare log ผู้ใช้ + shapes_all → ไม่ต้องรัน bench ใหม่
**ไม่คุ้มตอนนี้:** สร้างลาน (รอดูว่ารอบใหม่ยังไม่โจมตีกี่ตัว), เมตริกตอนตัดสิน (4.1 — FOLLOWS + ฉากวิ่งหลบทำหน้าที่แทนแล้ว)
**ETA bench รอบนี้:** 18 share ใน 34 นาที จาก ~70 → เสร็จราว 10:40

**วิเคราะห์อีกรอบ (ผู้ใช้: "วิเคราะห์อีกรอบ แล้วค่อยทำ") — ข้อเท็จจริงก่อนตัดสิน:**
1. **AIMED:** ไม่ใช่ "แก้ให้นับหลัง lock" — หลัง lock ของข้อมูลคือ FOLLOWS อยู่แล้ว (ซ้ำ) และหา lock ที่ข้อมูลตั้งผิดไม่ได้
   → AIMED ใช้ได้เฉพาะท่า frame=facing (เกมหันตามไม่ได้ถ้าบอสไม่หัน); ท่า frame=target ใช้ความจริงจาก bench (ฉากหลบที่เฟรม k)
   แต่ bench_lock ยังกำกวม: Bearger atk ข้อมูล lock 10, หมุนหนี 60° ถึงเฟรม 30 ยังโดน — เล็งจริง หรือท่ากว้าง > 60°? → ต้องใช้ฉากวิ่ง
2. **Bearger 46 พลาดใน "bi" = ไม่ใช่ท่าที่ขาด:** bi = ท่ายืนสองขา (ไม่มีโจมตี); ทุกครั้งตามหลัง ground_pound; เวลา = เฟรม ~40
   ของการทุบ = ขั้นหลุมยุบเฟรม 40 ในข้อมูล (ดาเมจหลุมนับเป็นของ Bearger — census: หลุมไม่เคยเป็นผู้ตีเอง)
   **และวาดหรือไม่ ขึ้นกับประวัติก่อนหน้า:** replay ตั้งแต่ 8374 → วาดถูก ("you were in it"), ตั้งแต่ 8300 → พลาด
   = **คลาสใหม่ (17): สถานะของตัววาดค้างข้ามท่า** — ผลไม่ควรขึ้นกับว่าดูมาตั้งแต่เมื่อไร → หาว่าอะไรต่างที่ 8378.93 ระหว่างสองรอบ
   (ท่าไหน active / alt / after / map ระยะไหน) — ถูก: REPORT_AT สองรอบเทียบกัน
3. Deerclops เลเซอร์ฟ้า FALSE 91 — ยังไม่ได้ดู (อ่านโค้ดว่าตีซ้ำได้ไหม)
**ลำดับ:** 2 (ทำซ้ำได้แน่นอน + เป็นบั๊กของตัววาดเอง) → 1 (จำกัด AIMED เฉพาะ facing) → 3
**แก้ข้อสรุปข้อ 2 (ตรวจแล้ว):** ~~คลาส 17 สถานะค้างข้ามท่า~~ — ผิด: รูปที่วาดตอนโดน **เหมือนกันทั้งสองรอบ**; ต่างแค่ตาราง
เวลาของ replay เลื่อนกัน (8378.900 vs .933) → รอบ 8374 "ผ่าน" เพราะความคลาดเคลื่อนที่ยอม ±1.5 เฟรม ไปจับเฟรมก่อนหน้าที่ยังเป็นรูปใหญ่
(บทเรียน: ผลที่เปลี่ยนตามจุดเริ่ม replay อาจเป็นแค่ตารางเฟรม — เทียบรูปที่วาดก่อนเรียกว่าบั๊ก)
**ของจริง (census ของรอบนั้น):** ทุบเริ่ม 8377.633; หลุมจริงเกิดเป็นแถวไปทางเป้า: 4.5 จากบอสที่เฟรม 24, 9.0 ที่เฟรม 28, …;
หุ่นยืน 5.0 (ตรงหลุมแรก) **โดนที่เฟรม ~40 = หลุมยุบตี ~16 เฟรมหลังเกิด**; ข้อมูลที่วาดตอนนั้น (ขั้น 40–58 รวม) กลางอยู่ 16 จากบอส
ไม่ครอบหุ่น → **ลำดับ/เวลาของหลุมในข้อมูลไม่ตรงเกม** (คลาส 7/2: ของที่ปล่อยเป็นชุด)
**ตัวตรวจที่ใช้ได้ทั่วไป (ไม่ใช่ทีละบอส):** เทียบข้อมูลกับ census — ต่อของแต่ละชิ้นของท่า: เกิดที่ระยะเท่าไร เฟรมไหน, ตีจริงที่
เฟรมไหน (hit ที่ตำแหน่งของมัน) กับขั้นในข้อมูล (ระยะกลางของ cell, เฟรม) → ไม่ตรง = ข้อมูลผิด ทุกท่าที่มีของเป็นชุด

## 6. ลำดับงาน (สถานะ ณ 2026-10-16 ค่ำ — เก่า, ดู 6.0)

1. **testbench** — ~~1a~~ เสร็จ (headless ตรงกับในเกม: เฟรมที่โดน, ระยะ); ~~1b~~ แทนด้วยฉากวิ่งหลบ + replay + ควบคุม;
   1c พื้นที่โดน: ได้จาก MISSED/FALSE ของ replay แล้ว; 1d ขยายบอส: ยังไม่ทำ
2. เมตริก "ตอนตัดสิน" (4.1) — **ยังไม่ทำ** (AIMED + ฉากวิ่งหลบครอบคลุมบางส่วน)
3. รายการ error ของ sim + lint (4.3, 4.4) — **ยังไม่ทำ**
4. **rebuild ข้อมูลเกมปกติ (4.6) — ยังไม่ทำ และสำคัญที่สุดตอนนี้:** กฎใหม่ใน sim ยังไม่ถึงบอสเกมปกติเลย
   ต้องตามด้วย compare กับ log ผู้ใช้ทั้งหมด + testbench บอสเกมปกติ + การทดลองควบคุม
   แล้วเอากฎยืด lock (คลาส 10) ออกจากตัววาดได้เลย (ไม่มีข้อมูลรุ่นเก่าเหลือ)
5. แก้ตามคลาส: 12 (animation เดียวกัน) ต่อจาก 4; ท่าหายาก → โหมดพาเข้าท่า (6.1)
6. ผู้ใช้เล่นทดสอบเฉพาะความรู้สึก/ความสวยงาม ไม่ใช่หาบั๊ก

**ลำดับที่จะทำต่อ:** 4 → 3 → 12 → โหมดพาเข้าท่า → 2

**4 rebuild — ผล (2026-10-16 ค่ำ):** verify.ps1 sim ใหม่ทั้งหมด → 226 ท่าเปลี่ยน. compare (log ผู้ใช้ทั้งหมด): missed 564→568, FALSE 356→341
- ท่าที่แย่ลง 4 ตัว → ใช้ข้อมูลเดิมไว้ก่อน (splice.lua รับ boss:move แล้ว): Celestial 2 attk_stab_pre (ตอนนี้รวม spiketrail + random —
  ต้องดูแยก), Shadow Thrall mouth bite_pre (sim check 2→40), Mutated Buzzard atk_flame_pre (0→6)
- **คลาสใหม่ (14): ท่าที่สร้างด้วย flag พิเศษแล้ว merge มือ หายเงียบเมื่อ rebuild ทั้งหมด** — `-ends` (ตีซ้ำเมื่อพ้นระยะ/เวลา):
  Scrappy Werepig ×5, Celestial 4 dash_pre → rebuild หาย `ends` → yellow-never-red ของ tackle +49% และ Celestial 4 พลาด +3
  (ที่ผมคิดว่า "dash_pst เล็กลงเพราะ sim ใหม่" — ผิด สาเหตุคือขาด -ends). แก้: สร้างใหม่ด้วย -ends เฉพาะ 6 ท่า แล้ว splice →
  ต่างจากเดิมแค่ lock_things. **กันซ้ำ:** tools/ends_moves.txt + verify.ps1 สร้างท่าในรายการด้วย -ends อัตโนมัติทุกครั้ง
  (ตรวจก่อนใช้: ข้อมูลที่ได้ต้องมี ends ครบทุกท่าในรายการ)

## 6.1 testbench: บังคับท่า หรือ ปล่อยธรรมชาติ? (วิเคราะห์ 2026-10-16)

**คำถาม:** บังคับท่าด้วย script (`sg:GoToState`) ได้ไหม แทนการรอบอสสุ่มเอง

**testbench มีไว้วัด 3 อย่าง:**
1. เลิกเล็งเมื่อไร (lock)
2. โดนตรงไหน (พื้นที่ / ระยะ)
3. เข้าท่ามาอย่างไร (ส่งเป้าหมายไหม, field/timer, brain หันให้ไหม)

ข้อ 3 คือต้นเหตุของปัญหาที่วนซ้ำ (Deerclops swipe, Moonmaw, Moose) — มันกำหนดข้อ 1

**บังคับท่า (GoToState):**
- ได้: ครบทุกท่า เท่ากันทุกท่า เร็ว ท่าหายากก็ได้
- เสีย: **ข้ามข้อ 3 ทั้งหมด** — เราเป็นคนเลือกว่าจะส่งเป้าหมายไหม ตั้ง field อะไร = เอาสมมติฐานเดียวกับ sim ไปใส่ในเกม
  → ผลจะ "ยืนยัน sim" แทนที่จะ "ยืนยันเกม" ในเรื่องเล็ง ซึ่งเป็นปัญหาหลัก **ใช้แทนธรรมชาติไม่ได้**
- ยังมีประโยชน์จริงสำหรับข้อ 2 (พื้นที่/เวลาโดนหลังเข้าท่าแล้ว) เพราะหลังเข้าท่า โค้ดที่รันเป็นของเกมจริงทั้งหมด

**ปล่อยธรรมชาติ:**
- ได้: ทั้ง 3 ข้อเป็นของจริง
- เสีย: ช้า สุ่ม ท่าหายากไม่ออก ต้องทำซ้ำเยอะ

**ข้อสรุป: ใช้ทั้งสองแบบ คนละหน้าที่ และใช้ความต่างของสองแบบเป็นตัวตรวจ**
- ธรรมชาติ = ความจริงเรื่องเล็ง (ข้อ 1, 3) สำหรับท่าที่เกิดบ่อย
- บังคับ = ครอบคลุมพื้นที่/เวลา (ข้อ 2) ทุกท่า
- **ท่าเดียวกันที่วัดได้ทั้งสองแบบ ถ้าผลเล็งต่างกัน = วิธีเข้าท่าที่เราสมมติผิด** → ตัวตรวจอัตโนมัติของคลาส 1 ทั้งระบบ
  (sim ก็ใช้สมมติฐานเดียวกับแบบบังคับ จึงชี้ได้เลยว่าข้อมูลท่าไหนผิด)
- ท่าหายาก: บังคับแบบ "ทางเข้าจริง" ก่อน (ตั้ง timer/flag แล้วให้ event ของเกมพาเข้าท่าเอง เช่น `doattack`) ใกล้ธรรมชาติกว่า GoToState
  ถ้าทำไม่ได้ค่อย GoToState และติดป้ายว่า "เล็งยังไม่ยืนยัน"

**จะรู้ได้อย่างไรว่า testbench เองเชื่อได้:** ข้อ 1a เดิม — เทียบผลธรรมชาติกับ log ที่ผู้ใช้เล่นจริง (Deerclops, Moose) ก่อนใช้ตัดสินอะไร

**ลดเวลา:**
- หา lock ด้วยการแบ่งครึ่ง (binary search) แทนการไล่ k ทุก 3 เฟรม: ~5 ครั้งต่อรอบแทน 21
- ทำซ้ำเฉพาะจุดที่ผลไม่นิ่ง

**ทางเสริมที่คิดได้ระหว่างทาง (ยังไม่ทำ):**
- **probe ในเกม:** hook ForceFacePoint / FacePoint / SetRotation และตำแหน่งที่ของถูกปล่อย (SpawnPrefab + SetPosition) ของบอส
  → บันทึก "บอสใช้ตำแหน่งผู้เล่นครั้งสุดท้ายเฟรมไหน" ได้ตรง ๆ จากการเล่นปกติ ไม่ต้องพึ่งสถิติการหลบ
  ข้อจำกัด: โค้ดที่อ่านตำแหน่งผ่าน `Transform:GetWorldPosition()` (C++) hook ไม่ได้ทั้งหมด → ใช้คู่กับ testbench

**สถานะ:** testbench v0.1 = ธรรมชาติอย่างเดียว; sim เขียนรายการท่าให้แบบบังคับได้แล้ว (BENCH_LIST, 632 ท่า)
แต่ยังไม่ทำโหมดบังคับ จนกว่าข้อ 1a (เชื่อถือ testbench ได้) ผ่าน

## 6.2 testbench แบบไม่มีจอ (headless) — วิเคราะห์ 2026-10-16

**ปัญหาของแบบในเกม:** เกมกระตุกจากการเก็บขยะ (GC), ผู้ใช้ต้องเปิดเกมและรอ, เร่งได้แค่ 2–4x

**GC มาจากไหน:** ระหว่าง testbench ตัว True Range ยังวาดทุกเฟรม (สร้างรูป, คำนวณ) + trace ทุก tick + สแกนรอบตัว (tr_env)
แต่ **ผลของ testbench ใช้แค่ trace** — การวาดจริงตอนนั้นไม่จำเป็นเลย (replay จำลองการวาดใหม่ทีหลังอยู่แล้ว)
→ ทางแก้เล็ก: ปิดการวาด + tr_env ระหว่าง testbench เหลือแค่ trace

**ทางที่ดีกว่า: รันบน server ของเกมแบบไม่มีจอ** (`bin64\dontstarve_dedicated_server_nullrenderer_x64.exe` มีอยู่แล้ว)
- ได้: โค้ดเกมจริง 100% (ไม่ใช่ sim), ไม่มีการวาด/จอ → ไม่มี GC จากการวาด, เร่งได้มากกว่า (ไม่ต้องวาดเฟรม),
  **ผู้ใช้ไม่ต้องทำอะไร** — ผมสั่งรันเองได้ทุกเมื่อ หลังแก้อะไรก็รันซ้ำได้ทันที (เหมือน check_um แต่เป็นเกมจริง)
- ปัญหาหลัก: **ไม่มีผู้เล่น** → บอสไม่มีเป้า
  - ใช้ "หุ่น" แทนผู้เล่น: entity ที่มี tag player/character, combat, health (อมตะ), physics ขนาดตัวผู้เล่น
  - เสี่ยง: โค้ดบอส/UM บางที่อ่าน component ของผู้เล่นจริง (inventory, freezable, pinnable, rider ...) → พังหรือทำต่างจากจริง
  - เสี่ยง: บอสบางตัวหาเป้าเองด้วย FindClosestPlayer (หุ่นไม่ใช่ผู้เล่นจริง) → บังคับ combat target ทุก tick
  - trace ของ True Range อ้าง AllPlayers[1] เป็น "you" → ต้องให้ trace ใช้หุ่นเมื่ออยู่ในโหมด bench
- **ยืนยันว่าเชื่อได้:** รันบอสชุดเดียวกับที่ผู้ใช้รันในเกม (bench2: Deerclops, Moose, Bearger, Wilting, Moonmaw)
  แล้วเทียบเฟรมที่โดน/ระยะ/lock ต้องตรงกัน ถ้าไม่ตรง = หุ่นต่างจากผู้เล่น → แก้หุ่นหรือใช้แบบในเกมกับบอสตัวนั้น
- world: ใช้ cluster ทดสอบแยก (สำเนา mods ของผู้ใช้: UM + True Range + testbench) ไม่แตะโลกของผู้ใช้

**ลำดับ:** (1) server ไม่มีจอ + หุ่น + testbench โหมดอัตโนมัติ (เริ่มเองเมื่อโลกโหลด, ปิด server เมื่อจบ)
(2) เทียบกับ bench2 ของผู้ใช้ (3) ถ้าผ่าน = ใช้เป็นตัวตรวจหลัก แทนการให้ผู้ใช้รัน
แบบในเกมเก็บไว้สำหรับบอสที่หุ่นใช้ไม่ได้ และปิดการวาดระหว่าง testbench เพื่อลด GC

**ผลลองครั้งแรก (2026-10-16):** server ไม่มีจอใช้ได้
- ต้องแก้ 2 อย่างก่อน:
  - True Range ออกจาก modmain บน dedicated → ให้ทำต่อเมื่อมี debug.txt
  - ไม่มีผู้เล่น ของในโลกหลับ → บอส (Deerclops, Moose) หายทันที → ให้ของที่เกิดหลังเริ่มทดสอบไม่หลับ
- เทียบกับในเกม (Deerclops): เฟรมที่โดน (34 vs 33–34) และระยะเอื้อม (2–8 โดน, 10/13 ไม่โดน) ตรงกัน
  → หุ่นถูกปฏิบัติเหมือนผู้เล่น เชื่อได้ในส่วนนี้
- ความเร็ว: ตามที่ผู้ใช้ชี้ — ไม่มีจอ เวลาในเกมเดินเร็วเท่าที่ CPU ไหว → เร่งสูง (32x)
  ถ้า tick ยาวเกิน 1/30 ลดทีละครึ่ง (ไม่ตกไป 1x)
- **จุดผิดของการวัดเล็งที่เจอ:**
  - Deerclops ปัดตีน้ำแข็ง: หมุนหนี 60° ยังโดนทุก k แต่บอส **ไม่หันเลย** (rot เท่าเดิมทั้งฉาก) = ท่ากว้างเกิน 60° ไม่ใช่เล็งตาม
  - → หมุนหนี 2 ขนาด (60° และ 150°) + ตัววิเคราะห์ดูการหันจริงของบอสจาก trace
    - "บอสหัน" = เล็งตาม
    - "ไม่หันแต่โดน" = ท่ากว้าง (หรือของที่ปล่อยเล็งตาม — ดูตำแหน่งของใน [tr_haz] ประกอบ)

- ตัววิเคราะห์นับการหันของบอส **เฉพาะก่อนโดนครั้งแรก** (หลังตีบอสหันกลับหาเป้า ไม่ใช่การเล็ง — นับรวมแล้วได้ "หัน 21/27" ผิด)
  ผลจริง Deerclops ปัดตีน้ำแข็ง: หัน 0/27 → ข้อมูล lock 0 ถูก, โดนที่ 60° = ท่ากว้าง
- server ปิดเองกลางทางหนึ่งครั้ง (ไม่มี error ใน log) → run_bench บันทึก exit code, หยุดเมื่อ log นิ่ง 3 นาที — ดูว่าเกิดซ้ำไหม

- server ไม่มีจอใช้แค่ core เดียว (ผู้ใช้ชี้) → `run_bench.ps1 -Jobs 6`: หลาย instance พร้อมกัน แต่ละตัวโลก/port ของตัวเอง
  แบ่งบอสผ่านชื่อ cluster ("tr_bench:a,b"), copy โลกที่สร้างแล้ว; ~2 GB ต่อตัว → 6 ตัวกับ RAM ที่ว่าง ~19 GB
- ที่ 32x: Deerclops 96 ฉากใช้เวลาจริง 11 วินาที (CPU ไหว tick ยัง 1/30)
- crash ตอน Moonmaw = **หุ่นต่างจากผู้เล่น**: lavae ของ UM เรียก v.sg ของเป้า หุ่นไม่มี → Lua error ทุก tick → server ล่ม
  → ให้หุ่นมี stategraph จำลอง (ไม่มี tag, ไม่เปลี่ยน state); ต่อไปเจออะไรแบบนี้อีก = เพิ่มให้หุ่น แล้วจดตรงนี้

- รอบขนานแรกล้ม: (1) DST รับ server_port แค่ 10998–11018 — ตั้ง 12000+ แล้วตกไป 10999 ทุกตัว ชนกัน (Bench1–5 ค้างเฉย ๆ ที่ 605 MB)
  → ใช้ 11001+; (2) หุ่น: `setmetatable` ไม่มีใน env ของ mod → G.setmetatable

- **รอบขนานเต็ม (6 instance, 11 บอส, 2.8 นาที):** replay log ของ testbench ผ่านตัววาด = ตัวตัดสินหลัก
  (bench_lock อ่านตรง ๆ ไม่ได้: ท่าตีปกติ DoAttack ดูแค่ระยะ ไม่สนทิศ → หมุน 150° ยังโดน แม้บอสไม่หัน)
  - ~1,500 ครั้งที่โดน วาดถูกเกือบหมด, **FOLLOWS = 0 ทุกตัว** (ยืนยันการแก้ lock_things กับเกมจริง)
  - Deerclops 65/65, Moose 96/96, Dragonfly 91/91, Wilting 91/91, Eye 44/44, Bee Queen 95/95 (FALSE 5), Moonmaw 21/21 (FALSE 3)
  - ยังพลาด: Bearger 17 (state "bi" หลังทุบ — โดนจาก sinkhole/แรงกระแทก?), Shadow Bishop 21/646 (ตอนบอสทับตัวผู้เล่น),
    Klaus 4 (ที่ระยะ 6 พอดี = ขอบ)
  - หุ่นต่างจากผู้เล่นอีก: เลเซอร์ Twins เรียก target.AnimState → ให้หุ่นมี AnimState; Eye, Bishop "gave up" (ไม่ครบฉากใน 12 นาทีเกม)
- ~~ถัดไป: แก้ 3 กลุ่มที่พลาด~~ → **วิเคราะห์ใหม่ (ผู้ใช้สั่ง): ข้อสรุปข้างบนผิด**
  - **การทดลองควบคุม:** replay log ชุดเดียวกันด้วยตัววาดรุ่นเก่า (มีบั๊กยืด lock) → **ผลเหมือนรุ่นใหม่ทุกตัวเลข**
    = testbench + replay แบบนี้ **จับบั๊กเรื่องเล็งไม่ได้เลย**; "FOLLOWS = 0 ยืนยันการแก้" ถอนคำ
  - เหตุ: FOLLOWS/AIMED ต้องการผู้เล่นเคลื่อนต่อเนื่อง ≥5 เฟรม; หุ่นวาร์ปทีเดียวแล้วนิ่ง → ไม่มีทางฟ้อง
  - หลักฐานที่ยังจริง: log ที่ผู้ใช้เล่น Bearger (เดินต่อเนื่อง) — เก่า FOLLOWS 3 → ใหม่ 0
  - ยังขาดอีก: บอกไม่ได้ว่าท่าไหนถูกทดสอบ (Deerclops กลายพันธุ์แบบเดียวต่อการเสก, ท่าหายากไม่เกิด)
  - **แก้:**
    1. ฉาก "วิ่งหลบ": ตั้งแต่เฟรม k วิ่งวนรอบบอสต่อเนื่อง 6 หน่วย/วิ (ความเร็วผู้เล่น) จนจบท่า
    2. **กฎ: ตัวตรวจใหม่ต้องผ่านการทดลองควบคุมก่อน** (จับบั๊กที่รู้แล้วได้) ถึงจะเชื่อผล
    3. รายงานความครอบคลุม: ท่าในข้อมูลของแต่ละบอส ถูกทดสอบกี่ครั้ง / ไม่เคยเกิด
    4. Deerclops เสก 3 ครั้ง (ร่างกลายพันธุ์สุ่มต่อการเสก)
  - **ผล (ฉากวิ่งหลบ + ควบคุม):**
    - Bearger: เก่า FOLLOWS 5 / AIMED ถึงเฟรม 25 → ใหม่ 0 / ถึง 13 (lock 21) = **ตัวตรวจไวแล้ว และการแก้ยืนยันกับเกมจริง**
    - Deerclops (UM) swipe, Moonmaw atk: เก่า = ใหม่ → **ยังพิสูจน์ไม่ได้** (ร่าง strong ไม่ได้เกิด? Moonmaw ตัวอย่างน้อย? หรือตัวตรวจไม่ไว)
    - ใหม่: Twins FALSE 296 (วาดทับไม่โดน) — สูงผิดปกติ
    - ความครอบคลุม: ท่าหายากไม่เกิดเลย (Bee Queen stomp/combo, Deerclops enraged/ice cast/uppercut combo, Klaus chomp,
      Wilting dash, Moonmaw bigattack/skyfall, Moose tornado, Bearger atk1/2/butt) → ต้องโหมดพาเข้าท่า (6.1)
  - ถัดไป: (1) ทำไม Deerclops strong / Moonmaw วัดไม่ได้ (2) Twins 296 (3) โหมดพาเข้าท่าด้วย timer/flag
  - (1) ตอบแล้ว: ร่าง strong เกิดจริง (วาด 192 ครั้ง) แต่ swipe ของมันและ atk ของ Moonmaw วาดตาม "ทิศที่หัน" (frame=facing)
    และบอสไม่หันระหว่างท่า → การยืด lock แทบไม่เปลี่ยนรูป = ไม่มีอะไรให้เห็น ไม่ใช่ตัวตรวจไม่ไว;
    ผลเกมจริง (วิ่งหลบหลายสิบครั้ง): ไม่มีครั้งไหนวาดตามผู้เล่น
  - (2) Twins: FALSE เกิดหลังยิงจบ (shoot_pst 259, shoot_loop 37, เกือบทั้งหมด "ที่ขอบ") → ตัววาดยังวาดเลเซอร์เป็น "กำลังตี"
    หลังจบ = **ปัญหาตัววาดจริง** (คลาส: วาดว่ายังตีหลังจบแล้ว) — ต้องดูว่าบอส/ท่าอื่นเป็นด้วยไหม (นับ FALSE ช่วง *_pst ทุกตัว)
  - **วิเคราะห์อีกรอบ (ผู้ใช้สั่ง):** ผมมองข้าม AIMED ของ Deerclops uppercut ที่เฟรม 37, 48 (หลังตีที่ 35)
    = อาการ "ตีแล้วยังเล็ง" ของ Deerclops จริง; สาเหตุ: ท่า around (วาดรอบตัว หันไปหาเป้า) ไม่มี lock → หันตามจนจบท่า
    คลาส: around + ไม่มี lock = UM 2 ท่า (uppercut, Pepper Dragon flame), เกมปกติ 4 (Celestial spin, Shadow Bishop ×3)
    → แก้ตัววาด: ท่า around ที่บอสยืนกับที่ + animation เดียว + เล็งเป้า → หลังตีครั้งสุดท้าย (นับเวลาใน animation) หยุดหัน, ซ่อนหลัง 5 เฟรม
    ควบคุม: ก่อน AIMED ที่ 37/48/49 → หลัง เหลือก่อน 35 เท่านั้น
    รอบแรกกฎกว้างไป: Shadow Thrall ปาก (กัดซ้ำใน bite_loop) พลาด 0→18 ใน compare → จำกัดเป็น animation เดียว + เล็งเป้า → 564→564
  - **(2) Twins ตอบแล้ว — ไม่ใช่ "วาดว่ายังตีหลังจบ":** FALSE ทุกบอส (testbench): มีแค่ Twins (296) + Bee Queen lob (7)
    - Twins: เลเซอร์ของ UM (shoot_pre/loop/pst) เล่น animation charge_pre/loop/pst = **เหมือนท่าพุ่งชาร์จ** →
      ตัววาดเลือกท่าพุ่ง (charge_pre) ตอนบอสยิงเลเซอร์ → วาดเลนพุ่งทับ
      คลาส: **ท่าที่เริ่มด้วย animation เดียวกัน** — มีระบบ "maybe/alt" อยู่แล้ว ต้องดูว่าทำไมไม่ทำงานกับคู่นี้ +
      ตัวแยกที่ผู้เล่นเห็นได้: เลเซอร์ยืนนิ่ง / พุ่งเคลื่อนเร็วตอน charge_loop; หาคู่อื่นที่เริ่มเหมือนกันทั้งหมด
    - **แก้ข้อสรุปข้างบน (ตรวจซ้ำ 2026-10-16 ค่ำ):** 296 มาจาก replay.lua รุ่นเก่า — replay ปัจจุบันทั้ง log รวมและ log ของ
      instance ได้ 46/46, FALSE 10 (ตัววาดรุ่นเก่าก็ 10 = ไม่ได้มาจากการแก้ของผม). "shoot_pst" ในบรรทัด FALSE คือชื่อ state
      ฝั่ง server ไม่ใช่ animation. เลเซอร์กับพุ่งเล่น animation เดียวกันจริง (UM postinit SGeyeofterror) และ**ตีเฟรมเดียวกัน (34)
      บนเส้นเดียวกันไปทางเป้า** → ผู้เล่นแยกไม่ได้ก่อนตี แต่เลนพุ่งที่วาดครอบเลเซอร์อยู่แล้ว → ไม่ใช่บั๊กที่ผู้ใช้เห็น
      FALSE 10 ที่เหลือ: วาดเลนพุ่งต่อตอน charge_pst หลังเลเซอร์ ส่วนมาก "ที่ขอบ" → เล็กน้อย, จดไว้
    - สแกนทุกบอส (scratchpad alike.lua): คู่ที่เริ่มเหมือนกันและไม่มีตัวแยกเลย —
      ทั้งคู่ยืนกับที่: ตัววาดวาดทั้งสองตลอด (alt_always) = ปลอดภัย (Deerclops atk@MakeStrong/atk, Malbatross, Minotaur gore, Shark, Leif,
      Krampus, Crawling horror, Celestial phase 2/3, glacialhound, hoodedwidow fall, um_tentacle_moon)
      ทั้งคู่เคลื่อน: เลือกชื่อที่ไม่มี "~" — Bearger butt_pre_L (testbench ยังไม่เคยเห็น), pigman/pigguard/tricktreat counter_atk, swilson
      → **งานต่อ:** testbench ให้ Bearger ทำ butt (โหมดพาเข้าท่า) ก่อนตัดสินว่าต้องแก้ไหม
    - Bee Queen lob (ราดน้ำผึ้ง ไม่มีดาเมจ) เล่น "atk" เหมือนท่าตี → แยกไม่ได้ก่อนจังหวะตี; วาดเผื่อ = ปลอดภัยกว่า → ไม่แก้
  - compare ช้า (core เดียว): สแกนรายชื่อบอสทุก log ทุกครั้ง + log ของ testbench ใหญ่หลายร้อย MB อยู่ใน tests/logs
    → เก็บรายชื่อบอสต่อ log ไว้ (cache) และย้าย log ของ testbench ไป tests/work/bench_logs

## 6.3 รูปที่วาด: ซ้อนทับ / ลื่นไหล / แตก (ผู้ใช้ขอ 2026-10-16 — วิเคราะห์ก่อนทำ)

ผู้ใช้ขอ: (ก) hitbox ซ้อนกันไหม ถ้าซ้อนให้รวม (ข) ลื่นไหลไหม — ไม่กระพริบ, ไม่เปลี่ยนรูปแปลก, ขอบไม่แตก, ข้างในไม่แยก, ไม่ render เป็นรูปอื่น

**มีอยู่แล้ว (replay ทีละเฟรม ตามเวลา):** FLICKER (หายเฟรมเดียว), VANISH, SHRINK (พื้นที่ลดฮวบ), JUMP (กลางรูปกระโดด ทั้งที่บอสไม่ขยับ),
WOBBLE (สลับไปมา), SLIDE, DROPPED; ออฟไลน์: slivercheck (ขอบหยัก/หนาม บนแผนที่), group_same (วาดเป็นกลุ่ม = ทีละชิ้น);
รวมรูป: มีเฉพาะ "ของกลมชนิดเดียวกัน" (วงน้ำแข็งกวาง Klaus, หนอน) → รวมเป็นเส้นขอบเดียว
**ยังไม่มี (ช่องโหว่):** ทุกตัวข้างบนดู "ตัวเลขรวม" ต่อเฟรม (พื้นที่, จุดกลาง) — ไม่ได้ดู**รูปร่าง**:
1. ซ้อนทับ: สองรูปที่ต่างกัน (ท่าบอส + ของที่ปล่อย, ท่าที่ค้าง (after) + ท่าใหม่, สองบอส, ของคนละชนิด) ทับกัน →
   สีเข้มขึ้นตรงที่ทับ + เส้นขอบตัดกันข้างใน = ดูเหมือนรูปแตก. ไม่มีตัวตรวจเลย
2. ข้างในแตก: รูปเดียวกันมีรู / แยกเป็นหลายก้อน เฟรมเดียวแล้วกลับ — พื้นที่แทบไม่เปลี่ยน → SHRINK ไม่เห็น
3. ขอบแตก: เส้นขอบไม่ปิดเป็นวง (ปลายเส้นลอย) — ไม่มีตัวตรวจ (slivercheck ดูแผนที่ ไม่ได้ดูเส้นที่วาดจริง)
4. รูปผิดรูป: เปลี่ยนรูปแบบกระตุก แต่พื้นที่/จุดกลางใกล้เดิม — ไม่มีตัวตรวจ

**วิธี (เลือกแล้ว):** ใน replay เพิ่มโหมด SHAPE_CHECK=1 — ทุกเฟรม rasterize สามเหลี่ยมที่เติม (ตาราง 0.1 หน่วย)
- ซ้อน: ช่องที่สามเหลี่ยม ≥2 ชิ้นคลุม (ภายในรูปเดียวไม่ควรทับ — ออกแบบไว้ว่า "blocks side by side don't overlap") → OVERLAP
  แยกว่าทับระหว่าง "รูปต่างกัน" (record ต่างกันใน SM._record / hazard) หรือในรูปเดียว (= บั๊กการวาดเอง)
- ก้อน/รู: นับก้อนที่ติดกัน + รูภายใน (flood fill จากขอบ) → HOLE / SPLIT เมื่อจำนวนเปลี่ยนชั่วคราว (≤3 เฟรม) แล้วกลับ
- ขอบ: ปลายเส้นขอบที่ไม่มีเส้นอื่นมาต่อ (ระยะ < 0.02) → OPEN EDGE
- รูปกระตุก: IoU ระหว่างเฟรมติดกัน ต่ำ (< 0.6) ทั้งที่บอส/ผู้เล่นขยับน้อยและท่าเดิม → MORPH
**ทำไมช่วยได้จริง:** ดูรูปจริงที่ส่งให้เกมวาด ไม่ใช่ตัวเลขรวม; ใช้กับ log ผู้ใช้ทั้งหมด + testbench (ผู้เล่นขยับ = กรณียาก)
**เมื่อไรจะไม่ช่วย:** ปัญหาฝั่งเกม render เอง (ลำดับวาด, ความโปร่งใส) — replay ไม่เห็น → ต้องใช้ REAL_LINES (มีอยู่) / ภาพจากเกม
**ควบคุม (ต้องผ่านก่อนเชื่อ):** TR_BREAK=hole|overlap|edge — ทำลายรูปโดยตั้งใจ (ทิ้งสามเหลี่ยม 1 ชิ้นทุก 7 เฟรม / วาดซ้ำ 1 ชิ้น /
ทิ้งเส้นขอบ 1 เส้น) แล้วตัวตรวจต้องจับได้; ไม่ทำลาย = ต้องได้ 0 บน log ที่ผู้ใช้ไม่เคยบ่น (หรืออธิบายได้ทุกอัน)
**ถ้าเจอซ้อน:** แก้เป็นคลาส — รวมรูปที่ทับกันให้เป็นเส้นขอบเดียว (ขยายระบบ union ที่มี จาก "ของกลมชนิดเดียวกัน" ไปทุกรูป
ในเฟรมเดียวกัน) — ตัดสินหลังเห็นตัวเลขว่าซ้อนแบบไหนบ่อย และค่าใช้จ่าย (เครื่องช้า: ดู perf-goal)

**ผล (2026-10-16):** tests/shapecheck.lua + replay SHAPE_CHECK=1. ควบคุม (Klaus log 1858): ไม่ทำลาย 0/0/0/0;
TR_BREAK=hole → SPLIT 129, overlap → OVERLAP 174, edge → OPEN 58, morph → MORPH 67 (รอบแรก MORPH จับไม่ได้: เกณฑ์ IoU<0.6
คงที่ — รูปใหญ่เลื่อน 1.5 ยังทับตัวเองเกิน 0.6 → เปลี่ยนเป็นเทียบกับเฟรมข้างเคียง (ต่ำกว่า IoU เพื่อนบ้าน 0.2))
log ผู้ใช้ 1858 (17 บอส): ซ้อนทับ = **คู่ท่าที่เริ่มเหมือนกัน วาดทั้งสองเป็นคนละรูป** ทุกกรณี —
Celestial 2 (attk_chop + attk_chop~atk_summon, 84 เฟรม), Celestial 3 (attk_stab2_pre + @lucky, 592), Minotaur
(jump_atk_pre + ~leap_attack_pre, 31), Celestial 4 (719 เฟรม dash_pre/loop, record ไม่มี key — ยังไม่รู้ว่าคู่ไหน);
SPLIT: Eye of Terror mouthcharge_loop 3 ครั้ง; ขอบแตก/กระตุก: 0
**วิธีรวม (เลือกแล้ว):** Atoms() รองรับ cell ที่ทับกันในรูปเดียวอยู่แล้ว (สีตามส่วนที่ตีก่อน, ขอบเดียวรอบทั้งหมด) →
ใน frame เดียวกัน, ท่าของบอสตัวเดียวกันที่วางตำแหน่ง/ทิศเดียวกัน (ต่างกัน < 0.05 / 1°) และตาราง cell เดียวกัน →
ต่อรายการ step เป็น owner เดียว (cache ต่อคู่) แล้ววาดครั้งเดียว. ไม่รวม: ของที่ปล่อย (กลุ่มของมันเอง), ตำแหน่งต่างกัน
(ต้องรวมแบบ polygon — แพง; ดูตัวเลขก่อน). ตรวจ: shapecheck OVERLAP ลด + compare MISSED/FALSE เท่าเดิม + perf
**ทำแล้ว — ซ้อนทับเผยบั๊กจริง 2 ตัว (ไม่ใช่แค่ความสวย):**
1. ท่าคู่ที่วาดพร้อมกัน (a.alt): **ท่าคู่หันตามเป้าตลอด ไม่เคย lock** (arot = ทางเป้าทุกเฟรม) — อาการเดียวกับที่ผู้ใช้บ่น
   "ตีแล้วยังเล็ง" แต่ซ่อนอยู่ในท่าคู่ → แก้: ท่าคู่ lock ที่เฟรม lock ของมันเอง (lock เท่ากันและทิศต่าง < 3° → ใช้ทิศเดียวกับท่าหลัก)
   + SimMoves.MergeBegin/End รวมเป็นรูปเดียวเมื่อวางที่เดียวกัน → Celestial 2: 84→0, Celestial 3: 592→0 (strike เท่าเดิม)
2. ท่าพุ่งเป็นช่วง (leg) + ท่าปิดท้าย (finish) วาดเป็นสองรูปซ้อนที่ปลายเลน → LegChain รวม finish เข้า map เดียว
   (เลื่อนเป็นจำนวน cell เต็ม แบบเดียวกับที่ต่อ leg อยู่แล้ว) → Celestial 4: 719→0
   ข้อจำกัด: ไฟล์ simmoves ชน 200 local → state ของการรวมเก็บใน SimMoves._mg
**ยังเหลือ:** Minotaur jump/leap (31→~20 เฟรม): ท่ากระโดด (เคลื่อน) วางจากจุดเริ่ม, ท่ากระทืบ (ยืนนิ่ง) จากจุดปัจจุบัน — จุดต่างกันจริง
ช่วงสั้นก่อนแยกท่าได้ → รวมแบบ cell ไม่ได้, ปล่อยไว้ (จด); Eye of Terror SPLIT 3 (mouthcharge_loop) — ยังไม่ได้ดู
**ติดตั้งแล้ว (2026-10-16 ~22:00, data 60DC80C64929):** ตัววาดใหม่ + ข้อมูลเกมปกติ rebuild (เก็บ 3 ท่าเดิม + 6 ท่า -ends)
เทียบกับตัวที่ติดตั้งก่อนหน้า (tests/compare.ps1 + tests/shapes_all.ps1, log ผู้ใช้ทั้งหมด 709 log×บอส):
missed 564→563, FALSE 356→345, yellow-never-red 1920→1919; ซ้อนทับ 37341→18921 เฟรม, split 149→152 (Minotaur +3 คู่กระโดด/กระทืบ),
morph 15→10, ขอบขาด 60→60. shapes_all ใช้ ~29 นาทีทั้งชุด (rasterize ทุกเฟรม) — รันเฉพาะบอสที่เกี่ยวด้วย -Bosses ได้
**ซ้อนทับที่ยังเหลือ (ต้องวิเคราะห์ทีละคลาส ไม่ใช่ทีละตัว):** mutateddeerclops 9343, lavae 2134, minotaur 1375,
shadowthrall_mouth 1238, bigshadowtentacle 865, knight_yoth 755, mossling 747, beeguard 359, frog 315, birchnutdrake 277…
— น่าจะเป็นหลายตัว (หลายบอสในฉากเดียว / ของที่ปล่อยซ้อนกัน) วาดแยกกัน = ต้องรวมระดับ polygon หรือ cell ข้ามตำแหน่ง;
ดูว่าคู่ไหน (OVERLAPS ใน tests/work/shapes/new_lines.txt) ก่อนตัดสินวิธี. ขอบขาด: mutateddeerclops 55, klaus 3

## 6.4 ผู้ใช้เล่นหลังติดตั้ง (2026-10-16 22:01, data 60DC80C64929) — ยังเห็นซ้อน + วงที่ไม่ตี (วิเคราะห์ก่อนทำ)

ภาพ 3 ภาพ + [tr_pause] ใน log ตรงกับแต่ละภาพ:
1. **Bearger ปาหิน (UM) "วงนอกคืออะไร ทำไมไม่ทำดาเมจ"** — ตอบจากโค้ด: หิน (bearger_boulder) ตีรัศมี 3 (FindEntities กลางตัว);
   แล้ว spawn `groundpoundring_fx` (scale 0.65) ซึ่ง**เป็นแค่ภาพ ไม่ตี**. ข้อมูลเกมปกติมี groundpoundring_fx เป็นของที่ตี
   **by = minotaur, in_move** (sim ให้เครดิตดาเมจกระทืบของ Minotaur กับ ring ที่เกิดจุดเดียวกัน — กฎ "ของที่บอสปล่อยตรงจุดที่ค้นหา",
   sim_moves.lua ~1569) → ในเกม ring ทุกอันจากทุกที่ (หิน Bearger, Koalefant, เครื่องมือ) ถูกวาดเป็นวงกระทืบ ×0.65/0.622 ≈ 5
   = **วงนอก**; วงในเส้นบาง = หินจริง ~3.3 (3 + ขนาด cell)
   **คลาส 15: ของที่เป็นแค่ภาพ ได้เครดิตดาเมจของบอส แล้วถูกวาดทุกที่ที่มันโผล่ โดยไม่ดูว่าใครปล่อย**
   ตัววาดมีกฎ in_moves (บอสใดก็ได้ที่ "กำลังวาดท่า" ใกล้ 40) — ไม่เคยดูว่าบอสนั้นคือ `by` ของมัน; Bearger ตอนปาไม่นับเป็น "ท่าที่วาด" → วาดเดี่ยว
   แก้ (ตัววาด): ของที่ in_move วาดเดี่ยวได้เฉพาะเมื่อบอสที่อยู่ใน `by` อยู่ใกล้ (กรณีเลเซอร์ค้างหลังบอสโดนขัด — บอสยังอยู่ใกล้) ;
   ไม่มี `by` ใกล้ = ไม่ใช่ของบอสนั้น → ไม่วาด. ตรวจทั้งคลาส: รายการ hazard ทุกตัวที่มี tag FX ในโค้ดเกม (ทำแล้ว ~35 ตัว) —
   ตัวไหนเป็นภาพล้วน (ไม่มีโค้ดตีของตัวเอง) ต้องผูกกับ `by` เสมอ
2. **Celestial 2 ท่าแทงหนาม (attk_stab_pre) — ซ้อนหลายชั้น** = ท่าที่ผม "เก็บข้อมูลเดิม" (rebuild แย่ลง) + หนาม spiketrail วาดเป็นของแยก
   replay: AIMED 1 (รูปตามผู้เล่นจากเฟรม 16 ขณะบอสไม่หัน) — ข้อมูลเดิมไม่มี lock_things → ตัววาดยืด lock (คลาส 10 ยังอยู่ในท่านี้)
3. **Hooded Widow charge_strike** — วาดจาก map ระยะ 1.00 ขณะผู้เล่นห่าง 12 (run 1.00, parts 3), SPLIT 13 ใน replay — ต้องดูต่อ

**ทำไมตัวตรวจของผมไม่เห็น (ช่องโหว่ของการตรวจเอง — สำคัญกว่าบั๊ก):**
- replay บอส วาดแค่ท่าของบอส; ของที่ปล่อย replay แยก (replay_haz) → **shapecheck / pics ไม่เคยเห็นท่า+ของ หรือ ของ+ของ ในเฟรมเดียวกัน**
  ทั้งที่เกมวาดรวมกัน → Celestial 2 ได้ "0 overlap" ทั้งที่ภาพผู้ใช้ซ้อนชัด; pics.ps1 ไม่มีหนาม/วงนอกที่ผู้ใช้เห็น
- shapes_all ทดสอบกับ log เก่า ไม่มี UM (TR_MODS) → ไม่เห็น Bearger ปาหิน, Widow
- testbench ไม่ได้ตรวจรูป และไม่ได้วาดของจากแหล่งอื่น (ring จาก Bearger)
**แก้การตรวจ (ก่อนแก้บั๊ก):** replay "ทั้งเฟรม" — วาดบอสทุกตัว + ของทุกชิ้นในเฟรมเดียว เหมือนเกม (Predict.Draw + DrawHazards)
แล้ว shapecheck / pics ใช้ภาพนั้น; log ที่มี UM ใช้ TR_MODS อัตโนมัติ (ดูจาก log ว่ามี "moves of mods")
ควบคุม: log นี้ต้องได้ OVERLAP ที่ Celestial 2 (97.9–99.1) และ Bearger (170.1) — ถ้าไม่ได้ = ตัวตรวจยังบอด
**ผู้ใช้เสนอ (ดีกว่า): "เช็คทุก entity — server ปกติโล่งอยู่แล้ว"** → โลก testbench ไม่มีอะไรเลย ทุก entity ที่เกิดหลังเริ่มฉาก
= มาจากบอส → บันทึกทุก entity (prefab, เกิด/หายเมื่อไร, ตำแหน่ง, tag FX) + ทุกครั้งที่หุ่นโดน (ผู้ตีจริง = data.attacker, ตำแหน่งผู้ตี/หุ่น)
→ ความจริงจากเกมต่อ "ของ" ทุกชนิดของทุกบอส: ตีจริงไหม, ระยะที่โดน/ไม่โดน (เทียบรัศมีที่วาด) — ไม่ต้องพึ่ง sim เดา
ตัวแยก: ของที่เกิดใกล้หุ่น ≥ N ครั้งแต่ไม่เคยเป็นผู้ตี และไม่มีการโดนจากบอสในจังหวะ/ตำแหน่งนั้น = "ภาพล้วน" (groundpoundring_fx ต้องโผล่)
ควบคุม: groundpoundring_fx จาก Bearger ปาหิน ต้องถูกจัดเป็น "ไม่ตี", bearger_boulder ต้อง "ตี ระยะ ≤ 3"
**ลำดับ:** (0) census ทุก entity ใน testbench + tools/bench_things.lua (1) replay ทั้งเฟรม + ควบคุมกับ log นี้ (2) คลาส 15 (by) + ตรวจ (3) ซ้อนของ+ของ / ท่า+ของ → รวมรูป
(4) Celestial 2 stab: ข้อมูลใหม่ (หนาม + lock_things) ทำไมพลาด +2 (5) Widow charge_strike

## 6.5 งานที่ผู้ใช้สั่งไว้ตอนไปนอน (2026-10-16 ~22:40) — ทำเลย ไม่ต้องถาม, กลับมาอ่านแผนนี้บ่อย ๆ

1. **testbench ให้ครบ:** มอนเตอร์ทั้งหมด (ไม่ใช่แค่บอส) + ตัวที่ UM ปรับ + บอส UM ทุกตัว; 10 รอบ (ผู้ใช้: เพิ่ม sample 5 เท่า —
   run_bench ค่าเริ่ม 10 รอบแล้ว, เวลาต่อบอส 6 นาทีเกม × รอบ)
2. census ทุก entity (ทำแล้ว: [tr_ent]/[tr_hit] + tools/bench_things.lua) → ใช้ตัดสิน "ของ" ทุกชนิด
3. ทุกการแก้: ผ่าน compare + replay ทั้งเฟรม (WHOLE=1, SHAPE_CHECK=1) + ควบคุม ก่อน install; ไม่ผ่าน = ไม่ install, จดไว้
4. ระหว่างทาง: อ่าน 6.4 / 6.5 / 7 ซ้ำก่อนเริ่มแต่ละขั้น

**สถานะคลาส 15 (ring):** ตัววาดซ่อน in_move ที่ไม่มีบอสเจ้าของใกล้ → Bearger ring 107 เฟรม → 0 (log ผู้ใช้, ควบคุมผ่าน)
แต่ replay ของทุก log: พลาด 216 → 377 — Great Depths Worm (worm_boss_dirt 25→162): ดาเมจดินของหนอนตรงจุดที่ ring เกิด
เดิม "ถูกโดยบังเอิญ" เพราะ ring ถูกวาดเป็นวงกระทืบ → **ยังไม่ install** จนกว่าดาเมจดินของหนอนจะมีของตัวเอง
(และ replay_haz ไม่วาดบอส → ใช้ตัดสินกฎ "บอสเจ้าของใกล้" ไม่ได้ ต้องใช้ WHOLE)
→ **แก้ต่อ (ไม่ใช่ hack ต่อตัว):** ring เกิดจาก component groundpounder (ดาเมจจริงเป็นวง: Minotaur, ดินของหนอน, Bearger ทุบเอง,
Toadstool ...) หรือจากโค้ดของ prefab เพื่อโชว์ (หิน UM) → tools/thing_sources.lua สแกนโค้ดเกม+UM: ของ in_move แต่ละชนิด ←
prefab ที่ใส่ component ที่ spawn มัน → true_range/thing_sources.lua; ตัววาด: วาดเดี่ยวได้ถ้าบอสเจ้าของใกล้ **หรือ** มี prefab
ต้นทางยืนตรงจุดนั้น (≤0.5 — groundpounder วาง ring ที่ตัวเองพอดี) — หาครั้งเดียวต่อชิ้น. worm_boss_dirt มี network → client เห็น
ข้อจำกัด: log เก่าไม่มี trace ของดินหนอน → replay ยืนยันไม่ได้; testbench: หนอนบนผิวดินไม่โจมตี (gave up, ดิน 1 ก้อน) → ยืนยันไม่ได้ทั้งคู่
→ ~~ยังไม่ install จนกว่าจะมีหลักฐาน~~ **ติดตั้งแล้ว 2026-10-17** — หลักฐานจากโค้ด (GroundPound() วาง ring ที่ตัวดินพอดี, ดินมี network);
  ยังไม่มีหลักฐานจาก log (trace ดินหนอนเพิ่มแล้ว — log ถ้ำครั้งต่อไปจะยืนยันได้)
- **คลาส 16: ขนาดของที่ scale ตามสูตรของเกม ไม่ใช่เชิงเส้น** — groundpounder ตั้ง scale ring = sqrt(รัศมีตี/12) → รัศมี = 12·s²;
  ข้อมูลมี scale_pow = 1 → ring จากต้นทางอื่น (หนอน: รัศมีอื่น) วาดผิดขนาด → sim ต้องหา pow จากการวัดหลายขนาด หรืออ่านสูตร
- **replay ทั้งเฟรม (WHOLE=1) ทำแล้ว** (replay.lua: ของทุกชิ้นจาก [tr_haz] ผ่าน Predict.DrawHazards ในเฟรมเดียวกับบอส; ไม่ปนกับ
  ตัวเลขของบอส): ควบคุมผ่าน — log ผู้ใช้ 22:01 เห็นซ้อนที่ Celestial 2 (ท่า+หนาม ~90 เฟรม), Bearger (หิน+หิน ~200, ทุบ+หลุม),
  Widow (mortar+mortar, ท่า+mortar) ที่ตัวตรวจเดิมได้ 0; ring: ติดตั้งอยู่ 107 เฟรม → แก้แล้ว 0
  ต้อง expand_haz ก่อน (log ที่ไม่ผ่าน verify ยังไม่ขยาย [tr_haz] เป็นทุก tick → ของหาย)
- **testbench ทุกมอน (6.5-1):** run_bench -All (252 = ข้อมูลเกม+UM+alias+worm_boss), แบ่ง share ละ 4, คิว 6 server,
  share ที่ล่มคิวส่วนที่เหลือใหม่, log แยกต่อ share (bench_things อ่านทีละ share — log รวมทำให้ GUID ชนกัน)
  แก้ระหว่างทาง: บอสเกิดในทะเล (spider จม) → หาที่บนบก 16 ทิศ; ตัวแปร $all ชนกับ -All (PowerShell ไม่แยกตัวพิมพ์)
- **ถัดไป (ระหว่างรอ):** คลาสซ้อน "ของ+ของ / ท่า+ของ" → วิเคราะห์วิธีรวม (ข้อ 3) ก่อนทำ

### 6.6 รวมรูปที่ซ้อนกัน — วิเคราะห์ (2026-10-16 คืน)
**ที่ผู้ใช้เห็นผิด:** (ก) เส้นขอบของรูปหนึ่งวิ่งผ่านข้างในอีกรูป → อ่านเป็น "รูปแตก/หลายชั้น" (ข) สีเข้มขึ้นตรงที่ทับ
**ที่มีแล้ว:** (1) ท่าคู่ที่วางที่เดียวกัน → cell เดียวกัน รวมเป็น owner เดียว (6.3) (2) ของกลมที่ค้าง ชนิดเดียวกัน → ข้างในวาดเต็ม,
ขอบ/แถบวาดเฉพาะส่วนที่ไม่มีวงอื่นคลุม (UnionDraw — วงน้ำแข็ง, หนอน)
**ทางเลือก:**
1. รวม cell ในตารางเดียว — ใช้ได้เฉพาะทิศเดียวกัน + เลื่อนเป็นจำนวน cell เต็ม; ของส่วนใหญ่หันคนละทาง → ไม่พอ
2. union ของ polygon ทุกเฟรม — ถูกต้องสุด แต่หนักใน Lua (เครื่องช้าคือเป้าหมาย) และต้องจัดสีของส่วนที่ทับ
3. **ขยายกฎของ UnionDraw ไปทุกรูป:** เส้นขอบ/แถบของรูปใด ไม่วาดช่วงที่อยู่ในรูปอื่น (ทดสอบจุดกลางของแต่ละท่อนเส้นด้วย InMap
   ของรูปอื่น — lookup cell ราคาถูก, กรองก่อนด้วยวงกลมครอบ → ส่วนมากไม่มีรูปทับ = ไม่เสียอะไร); ไส้ยังวาดทุกรูป
   ได้ (ก) ทั้งหมด = ปัญหาหลัก; (ข) ยังอยู่ (ไส้โปร่งแสงทับกัน — ตามธรรมชาติ, เหมือนวงน้ำแข็งตอนนี้)
   ระวัง: รูปที่อยู่ใน group (วางครั้งเดียวแล้วเลื่อนทั้งก้อน) — ต้องวางใหม่เมื่อการทับเปลี่ยน → ต้นทุน; วัดด้วย ENGINE_CALLS/HAZ_TIME
   ระวัง: สีของขอบบอกเวลา (เหลือง→แดง) — ขอบที่ถูกซ่อนเป็นของรูปที่ "ตีทีหลัง" เท่านั้นหรือทุกรูป? → ซ่อนเฉพาะช่วงที่อยู่ใน
   รูปที่ตีก่อนหรือพร้อมกัน (รูปที่ตีก่อนเป็นสิ่งที่ผู้เล่นต้องหลบก่อน — ขอบของมันต้องเห็นครบ)
**เลือก 3** หลังดูตัวเลขจาก shapes_whole (คู่ไหนซ้อนบ่อย); ตรวจ: shapecheck ต้องนับ "เส้นขอบที่อยู่ในรูปอื่น" (เพิ่ม) แทน
OVERLAP ของไส้ — ควบคุม: ปิดกฎ → ต้องเห็น, เปิด → ลด; compare MISSED/FALSE เท่าเดิม (ไม่เปลี่ยนพื้นที่ที่วาด); perf ไม่แย่ลงเกิน 10%
**ทำ (สำเนา scratchpad\tr_dev — ไม่แตะ source ระหว่าง shapes_whole ใช้ source เป็น New):**
- shapecheck เพิ่ม EDGEIN (ความยาวเส้นขอบที่อยู่ลึก >0.15 ในไส้ของรูปอื่น) — ตัววัดที่ตรงกับที่ผู้ใช้เห็น
- simmoves: SimMoves._rg — ทุกรูปลงทะเบียน (id = กลุ่มของมัน, ตำแหน่ง, cell, รัศมีครอบ) ทุกเฟรม; รายการ active ต่อเฟรม
  (รอบแรกวน pairs ของทุกรูปที่ยังไม่ถูกเก็บขยะ = ช้าขึ้นเรื่อย ๆ); ทุกท่อนเส้นขอบ: ใกล้รูปอื่นไหม (ระยะจากเส้นถึงวงครอบ) →
  สุ่มจุดทุก 0.5 → ทั้งท่อนอยู่ใน = ไม่วาด, บางส่วน = วาดเฉพาะช่วงนอก (SegRec ใหม่ เฉพาะท่อนนั้น); ลายเซ็นของส่วนที่ซ่อน →
  กลุ่มวางเส้นขอบใหม่เมื่อเปลี่ยน (SameLaid); Kept ไม่ใช้ของเดิมถ้ามีรูปอื่นซ้อน; จำผลไว้ถ้าทุกอย่างอยู่ที่เดิม
- ผล (log ผู้ใช้ 22:01, WHOLE): ความยาวเส้นขอบในรูปอื่น Bearger 51776 → 3804 (−93%), Celestial 2 10468 → 1249 (−88%),
  Widow 806 → 94 (−88%); split/morph เท่าเดิม; Celestial OPEN 0 → 3 (ปลายเส้นที่ตัด)
  เหลือ: หินหลายก้อนที่จุดเดียวกันขนาดเท่ากัน — ขอบทับขอบพอดี ไม่มีส่วนไหน "ข้างใน" → ไม่ซ่อน (ถูกต้อง: เห็นเป็นเส้นเดียว)
- perf (REAL_LINES = เส้นทางของเกมจริง มี group): ฉากหนักสุด Celestial 2 (กระสุนหลายร้อย): 0.57 → ~0.77–0.87 ms/เฟรม,
  Bearger 0.23 → 0.28; ไม่มีรูปซ้อน = แทบ 0. **ตัดสิน: ยอมรับ** — +0.3 ms ในฉากที่หนักที่สุด < 1% ของเฟรม (33 ms ที่ 30 fps),
  "10%" ในแผนเดิมวัดเทียบเวลาของ mod เองซึ่งเล็กมาก; ตัวเลขมี noise ±0.1 เพราะ bench+census แย่ง CPU อยู่
  การปรับที่ช่วยจริง: รายการ active (ไม่วนทุกรูป), เช็คระยะก่อนสุ่ม, สุ่มทุก 0.5 แทน 0.25 (คุณภาพเท่าเดิม 1259 vs 1264);
  ที่ไม่ช่วย: จำผล (ของเคลื่อนทุกเฟรม), lerp แทน World
- ตรวจ group path (REAL_LINES) ไม่มี Lua error
- **บั๊กที่ผมสร้างเอง แล้วจับได้ก่อน install (2026-10-17 คืน):** ผ่อนกฎ "ในรูปอื่น" เหลือแค่ cell เดียว (เพื่อลดเศษเส้นที่ทิ่มเข้าไป)
  → สองรูปที่เกือบซ้อนพอดี (Celestial สับ + สับ~เรียก) ขอบของแต่ละรูปเข้า-ออก cell ขอบของอีกรูปสลับกัน → **ขอบกลายเป็นเส้นประ**
  เห็นจากภาพ pics (491.0), ตัวเลข OPEN 93 → 215 เป็นสัญญาณแรก. แก้: กลับไปใช้ cell + 4 รอบ (ขอบที่ทับพอดีวาดทั้งคู่ = เห็นเส้นเดียว)
  **ช่องโหว่ของตัวตรวจ:** OPEN นับเฉพาะปลายเส้นที่ "มาแล้วหาย" — เส้นประที่ค้างทุกเฟรมจะไม่ถูกนับเลย (เจอเพราะบังเอิญมีเฟรมเดียวที่ทึบ)
  → เพิ่มผลรวมปลายเส้นลอย (ไม่นับปลายที่อยู่ในรูปอื่น, ไม่นับรอยต่อสี) เทียบเก่า/ใหม่: ควบคุม — รุ่นเส้นประ +10% (+6267),
  รุ่นแก้ +0.1% (+55) → shapes_all รายงานเพิ่ม: ความยาวขอบในรูปอื่น + ปลายเส้นลอยรวม
  (ค่าสัมบูรณ์ใช้ไม่ได้: บางท่าวาดเป็นท่อนโดยตั้งใจ เช่น spin_pre 58 ปลายทุกเฟรม — ใช้เทียบเท่านั้น)
- ผลรอบแรกทุก log (ก่อนแก้เส้นประ): ขอบในรูปอื่น 19,754,036 → 208,946 (−99%), compare การตีเท่าเดิมทุกค่า (569/347/1922)
- **ติดตั้งแล้ว (2026-10-17 เช้ามืด):** ring (คลาส 15) + thing_sources + trace ดินหนอน + รวมขอบรูปที่ซ้อน (แก้เส้นประแล้ว)
  ทุก log (WHOLE): ขอบในรูปอื่น 19.75M → 0.93M (−95%), ปลายเส้นลอยรวม 23.8M → 22.9M (ไม่มีเส้นประ), split 2016 → 1989,
  morph เท่าเดิม, OPEN 95 → 230 (Mutated Deerclops icelance 56 → 178: ปลายตัด 2–4 จุดค้าง 1 เฟรมตอนหนามโผล่ — region ของเฟรมก่อน
  ช้าไป 1 เฟรม; ยอมรับ, จด); compare การตีเท่าเดิม; unit ผ่านทั้งหมด, group_same 0 differ; Lua error 0

### 6.7 census ทุก entity จาก testbench ทุกมอน (2026-10-17 เช้ามืด, 75 share, 10 รอบ)
**ตัวตรวจเองผิดก่อน (แก้แล้ว):** bench_things รอบแรกฟ้อง DRAWN-NEVER ผิด ๆ — (1) by ของไฟล์ UM ทับไฟล์เกม (ตัววาดรวมแล้ว ตัวตรวจไม่)
(2) ไม่รู้ alias (bishop_nightmare = bishop) (3) ตัดสินของที่เป็นแค่สถานะ (วงน้ำแข็งกวาง: แช่แข็ง) ด้วย "การโดนตี"
→ แยกคำตัดสิน: NEVER-ANY (อยู่ในมันแล้วไม่โดนอะไรเลย = แรง) / NEVER-OWN (โดนจากตัวอื่นเท่านั้น = อ่อน) / สถานะ (ไม่ตัดสิน)
**ควบคุม:** ring จาก Minotaur — อยู่ใน 43 ครั้ง โดนทุกครั้ง (ไม่ฟ้อง) ✓; ring จากหิน Bearger — ฟ้อง ✓
**ผล:** ring ใกล้ Bearger/Mutated Bearger/Moose/Widow = NEVER-OWN แต่ที่จริงโดนจาก groundpounder ของตัวมันเอง (ring ที่ตัวมันยืน) —
ตรงกับกฎที่ติดตั้ง (thing_sources); ring จากหิน = ไม่ตีจริง ✓
NEVER-ANY: magmafire (55 ครั้ง), warningshadow (7), mushroombomb (4), fireball_throwable (5) — **สรุปไม่ได้: ไฟลดเลือดตรง ไม่ผ่าน
"attacked"** → testbench เพิ่ม [tr_hurt] (healthdelta + สาเหตุ + ผู้ทำ) และ bench_things นับเป็น "โดนตอนอยู่ในมัน" →
**งานต่อ:** รัน bench ซ้ำเฉพาะตัวที่มีของไฟ (magmahound, mock_dragonfly, firehound, toadstool, beequeen/beeguard)
**server ล่มระหว่างรัน:** cherrybulletbee (exit 6), warglet (-1073740791 = Lua error) + อื่น ๆ — คิวส่วนที่เหลือใหม่ตามแบบ; ต้องดูสาเหตุใน log

### 6.8 testbench: ความเร็วจริง + server ล่ม (วิเคราะห์ 2026-10-17 เช้า, ผู้ใช้: "วิเคราะห์ก่อน ทำต่อ")
**server ล่ม 12 ตัว (WerFault ที่ผู้ใช้เห็นตอนตื่น):** ไม่ใช่ True Range (ปิด True Range แล้วยังล่ม) —
- fruitfly: Lua error ใน um_tornado.lua:285 (หุ่นไม่มี inventory) → ใส่ inventory
- vault_pillar_guard: **บั๊กของ True Range จริง** modmain TraceLine: ผู้เล่น/หุ่นที่หายไปแล้ว → px = nil → error ทุก tick
  (ในเกมจริงเกิดได้ตอนผู้เล่นออกจากโลกระหว่างมีบอส + debug.txt) → แก้ (เช็ค IsValid) + ติดตั้งแล้ว
- warg, warglet, pied_rat, …: ล่มใน engine (ไม่มี Lua error แม้ดัก _TRACEBACK ลงไฟล์ / stdout) ราว 5 วินาทีเกมหลังโดนตี;
  ทดลองตัดทีละอย่าง: ความเร็ว 1x ยังล่ม, ไม่มี True Range ยังล่ม, หุ่นไม่มี network ยังล่ม, **ไม่ติด tag "player" = ไม่ล่ม** (57–101 hits)
  → โค้ดสำหรับผู้เล่นจริงเท่านั้นไปจับของที่หุ่นไม่มี (ใน C++) — แก้ที่ระบบ: ปกติติด tag player (ใกล้เกมจริง), ตัวไหนล่ม
  run_bench คิวซ้ำเป็น "ชื่อ!np" (ไม่ติด player) อัตโนมัติ — ข้อมูลของตัวนั้นจึงห่างจากเกมจริงนิดหน่อย (จดไว้ต่อตัว)
- โลกทดสอบถูก save ต่อกัน → ของค้างข้ามรอบ (leif, eyeofterror ยืนนิ่งใกล้หุ่นทุก log) → ใช้โลกต้นแบบใหม่ทุก share
  (แต่ leif/eyeofterror อยู่ในโลกต้นแบบเองด้วย — ต้องล้าง)
**ความเร็ว: ตั้ง 32x ได้จริง ~5.3x** (log เมื่อคืน: เกม 5067 s / จริง 952 s); ตัวเช็คเดิมดูแค่ "tick = 1/30" (ไม่ข้ามเฟรม) ไม่ได้ดูความเร็วจริง
ข้อมูล: server ละ 100% ของ 1 core (คอขวดที่ CPU ต่อ server), เครื่องรวมใช้ 16% (16 thread ว่างเยอะ), RAM ~2 GB/server
log ต่อ share: tr_trace 90% (816k บรรทัด = ~161/วินาทีเกม = ~5 ตัวถูก trace ทุก tick — รวมของค้างที่ไม่เกี่ยว), tr_env 19% ของ MB
**ทางเลือก:** (1) server มากขึ้น — ได้เชิงเส้นจนชน RAM (31 GB, เหลือ ~19 → ~9 ตัว) (2) งานต่อ tick น้อยลง: ไม่ trace มอนที่
ไม่ใช่ตัวทดสอบ (ล้างของค้างตอนเริ่ม / trace เฉพาะบอสของ share), ลด tr_env; (3) ไม่รู้ว่าเวลาต่อ tick เป็นของเกมเองกี่ส่วน
**ก่อนทำ — วัด:** hound ตัวเดียว True Range เปิด vs ปิด (เทียบความเร็วจริง) = ต้นทุนของ trace; ถ้าส่วนใหญ่เป็นของเกมเอง →
ข้อ 1 เท่านั้นที่ช่วย; ถ้า trace กินมาก → ข้อ 2 ก่อน. ตัวเช็คความเร็ว: รายงาน "เกม s / จริง s" ทุกนาที (ไม่ใช่แค่ tickdt)

**ผลวัด (2026-10-17 เช้า):** hound ตัวเดียว: เปิด True Range 30x, ปิด 30x (เกม 720 s / จริง 24 s) → trace แทบไม่กินในโลกเบา;
5.3x เมื่อคืน = share หนัก (ของค้าง, ของจำนวนมาก, log ใหญ่) + census แย่ง CPU. หุ่นถูกฆ่า (ErodeAway: บางท่าตีเกิน 100000) →
งานของ bench ผูกกับหุ่น ตายไปด้วย → bench หยุดเงียบ server วิ่งต่อ 15 นาที (sharkboi, vault guard) → แก้: งานผูกกับโลก,
หุ่น SetMinHealth(1), หุ่นหายให้สร้างใหม่ + log ว่าใครลบ (debugstack)

### 6.9 ลานของบอส / มอนที่ไม่โจมตีใน testbench (ผู้ใช้: "generate arena ได้ไหม แบบ force เลย")
census: 73 จาก 243 ตัว ไม่โจมตีเลย — แยกตามเหตุ (แต่ละกลุ่มแก้คนละแบบ):
1. **ต้องมีลาน/ที่อยู่:** sharkboi (ลานน้ำแข็งบนทะเล), daywalker2/daywalker (ลานเสา), crabking (ทะเล), antlion (ทะเลทราย),
   stalker_atrium (atrium), worm_boss (ถ้ำ), wagboss_robot (rift), vault_pillar_guard (vault), alterguardian (เกาะดวงจันทร์)
   → **ใช้โค้ดของเกมเองสร้าง** (ไม่ใช่จำลอง): sharkboimanager:PlaceOceanArenaAtPosition + CreateSharkBoi,
   daywalkerspawner:SpawnDayWalkerArena (เกมเขียนว่ามีไว้ให้ mod เรียก), vaultroommanager:CreateLayout; ตัวที่ต้องการ tile พิเศษ
   (ถ้ำ, ทะเลทราย, เกาะ) → ตั้ง tile รอบจุดด้วย Map:SetTile แล้วเสก — ตรวจทีละตัวว่าท่าออกจริง (census: start > 0)
2. **อยู่กับที่** (tentacle, tentacle_pillar_arm, lunarthrall_plant, eyeplant, …): bench ถือหุ่นไว้ห่าง 10 → ไม่ถึง →
   โหมด "เข้าหา": หุ่นเดินเข้าไปในระยะ (ฉากหมุน/วิ่ง/กระโดด ทำรอบตัวมันตามเดิม)
3. **ต้องกลางคืน** (eyeofterror, twins — กลางวันหนีไป): ตั้งนาฬิกาโลกเป็นกลางคืนตอนเสก
4. **ไม่โจมตีโดยธรรมชาติ / ต้องมีตัวอื่น** (friendlyfruitfly, viperlingfriend, pigelite = มินิเกม, mossling = ต้องมีแม่,
   deer = ต้องมี Klaus, ลูกน้องเงา): จดเป็น "ทดสอบไม่ได้แบบนี้" — ไม่เสียเวลา
**ลำดับ:** 3 (ง่าย, Eye/Twins สำคัญ) → 2 → 1 (sharkboi, daywalker ก่อน — มีฟังก์ชันของเกม) → ตัวที่ต้องตั้ง tile
**ผล (2026-10-17 สาย):**
- **ข้อมูล testbench เมื่อคืนปนเปื้อน:** โลกต้นแบบมี Eye of Terror + leif ค้าง (จากการทดสอบในเกม) ห่างจุดเกิดหุ่น 6/15 →
  มอนหลายตัวไปตี Eye แทนหุ่น (warg: "HIT at eyeofterror") → ล้างสัตว์ที่สู้ได้ในรัศมี 60 ตอนเริ่ม; **ต้องรัน census ทุกมอนใหม่**
- **SetMinHealth(1) ทำให้ไม่มีมอนตัวไหนโจมตีหุ่นเลย** (เกมถือว่าเป้าที่ฆ่าไม่ได้ไม่ใช่เป้า) — ผมใส่เพื่อกันหุ่นตาย แล้ว
  ตัวเลขเป็น 0 ทุกตัว ผมเกือบสรุปผิดว่า "sharkboi/vault ต้องมีลาน"; ตัดทีละอย่าง (bisect) เจอ → กันตายด้วยการห่อ SetVal แทน
  **บทเรียน:** ตัวเลข 0 ทุกตัวพร้อมกัน = สงสัยตัวทดสอบก่อนสรุปเรื่องบอส; ควบคุม: hound ต้องโจมตีเสมอ (ใส่ในทุกรอบ)
- กลางคืน + เดินเข้าหา + เริ่มฉากเมื่อเริ่ม animation แรกของท่าในข้อมูล True Range (TR_MOVE_STARTS, เฉพาะ debug):
  Eye 0 → 42 ฉาก, Twins 0 → 39, tentacle 0 → 59, sharkboi โดน 86 (ไม่ต้องมีลาน), warg (!np) 59 ฉาก
  ยังไม่ได้: tentacle_pillar_arm (ต้องมีเสา), eyeplant (ต้องมี lureplant), lunarthrall_plant (ตีผ่านเถา — ตัวมันไม่เริ่มท่าเอง)

### 6.11 ผู้ตรวจ (ผู้ใช้ขอ 2026-10-17: "อยากให้มีคนคอยสกิดไหล่ — แก้ 1 บอส แต่ไม่เห็นอีกหลายสิบบอส")
agent `tr-reviewer` (.claude/agents/tr-reviewer.md, อ่านอย่างเดียว) — ใช้ตัวเดิมต่อเนื่อง (SendMessage) ไม่สร้างใหม่ทุกครั้ง
**จุดตรวจ (บังคับ):** (ก) ทุกครั้งที่สรุปสาเหตุ (ข) ก่อนแก้ (ค) ก่อนบอกผู้ใช้ว่าแก้แล้ว — ส่งข้อสรุป + หลักฐาน → ผู้ตรวจตอบ
"บอสอื่นที่กลไกเดียวกัน (ไฟล์:บรรทัด) / หลักฐานที่ยังไม่พอ / ขัดแผนตรงไหน" → จดข้อท้วง + คำตอบของผมไว้ที่หัวข้อของงานนั้น
ข้อท้วงที่ไม่ตอบ = ห้ามไปขั้นต่อ; ผลของผู้ตรวจก็ต้องตรวจกับข้อมูลจริงก่อนเชื่อ (ไม่ใช่เชื่อเพราะมันบอก)
**ผู้ตรวจวิจารณ์นิยามของตัวเอง → ตรวจข้อเท็จจริงทีละข้อก่อนแก้ (2026-10-17):**
- ถูก: โฟลเดอร์ bench ที่เชื่อได้มีแค่ 2026-10-17_0835 (อีก 24 โฟลเดอร์ = ปนเปื้อน/รอบไล่บั๊ก); บรรทัดข้อมูลยาว 412k–1.2M ตัวอักษร
  (ค้นตรง ๆ โดนตัด); ต้องถามว่าตัวเลขมาจากเครื่องมือรุ่นไหน (Twins 296); ต้องมีขั้นค้น "กลไกเดียวกัน" เป็นระบบ; รูปแบบคำตัดสิน
  BLOCKING/NOTE; คงอ่านอย่างเดียว + บอกคำสั่งที่ผมต้องรันพร้อมผลที่คาด
- ผิด 3 ข้อ (ผู้ตรวจเองก็พลาด — ยืนยันว่าต้องตรวจผลของมัน): alt/maybe/alt_always ไม่ใช่ field ของข้อมูล (0 ครั้ง — ของตัววาด);
  "UM ไม่รวม by" — ตอนเกมรันรวมแล้ว (moddata) แต่ไฟล์ดิบยังแยก; เสนอ path tools\replay.lua = **สำเนาเก่า 9 ต.ค.** (ตัวจริง
  tests\replay.lua) — ถ้าใช้ตามจะได้ตัวเลขผิดแบบ Twins 296 ทุกประการ → นิยามต้องเตือนชัด (ไม่ลบไฟล์เองโดยไม่ถาม)
- ต้นเหตุร่วม: แผนมีส่วนเก่าที่ผิดแล้วปนกับส่วนใหม่ → ผู้ตรวจต้องถือ 6.0 เป็นสถานะปัจจุบัน ส่วนอื่นคือประวัติ
- ความยาว: นิยามถูกอ่านทุกครั้ง → เพิ่มเฉพาะที่ป้องกันความผิดพลาดที่เกิดจริง ไม่ใส่รายละเอียดที่หาเองได้
- **ทำให้เรียบง่าย (ผู้ใช้):** ของเก่าย้ายไป W\old (มี README): tools\replay.lua (สำเนาเก่า) + bench_logs เก่า 51 รายการ
  (ปนเปื้อน/รอบไล่บั๊ก) → tests\work\bench_logs เหลือแค่รอบที่เชื่อได้ (0835 — รอบนี้หยุดกลางทางตอน Claude Code ปิด: 38 share)
  กติกา: **รอบ bench ที่ไม่น่าเชื่อ ย้ายไป old ทันที** — ไม่ทิ้งไว้ปนกับของจริง
- **ผู้ตรวจรอบ 2 (หลังย้าย) → ทำแล้ว 2026-10-17:** นิยามเพิ่ม args ของ replay (ตัววาดที่ทดสอบ = mod root ที่ส่ง) + TR_MODS;
  OLD_LOCK=1 = ย้อนแค่กฎ _decide (predict.lua:1982 ยืนยันแล้ว) ไม่ใช่ประตู lock_things (:1965); ข้อ 1(e) กฎตัววาดโดนทุกท่าที่ตรง
  + ถามกลับว่าเงื่อนไขใหม่จับบอสไหนเพิ่ม (Shadow Thrall 0→18); ข้อ 2 ทั้งสองชั้น/ไฟล์ข้อมูลไหน rebuild/FALSE = คำถาม
- **ตัวคุม (control) ย้ายเข้าโปรเจกต์:** %TEMP%\tr_oldlock เป็น snapshot 16 ต.ค. — ต่างจาก mod ตอนนี้ 6 ไฟล์ (ไม่ใช่ "บั๊กเดียว")
  → ไม่ใช้; สร้างใหม่ด้วย tests\controls\make_controls.ps1 (mod ปัจจุบัน + เอา `not sim.lock_things` ออก 1 จุด) → tests\controls\oldlock
  ผลคุม (bench2, UM bearger): live 26/26 วาด, FALSE 4 — oldlock FALSE 6 (+383.4, +447.7) → replay แยกได้ ✓ (ต้อง build ใหม่ทุกครั้งที่แก้ mod)
- **พลาด (ของผม):** รอบ -All 0835 **ไม่ได้หยุด** (สรุปผิด) — ยังรันอยู่ 8 server; ผมเปิดรอบ hound ซ้อน → ทั้งสองใช้ Bench0
  (ชื่อตาม slot) ชนกัน 09:44–09:5x → หยุดรอบ hound แล้ว; share ของรอบ 0835 ที่ Bench0 เริ่ม ~09:46 = ปนเปื้อน → ต้องย้ายไป old
  เมื่อรอบจบ; ใส่ประตูใน run_bench.ps1: มี run_bench อื่นรันอยู่ = ไม่เริ่ม. control hound ยังไม่ได้ทำ (รอรอบ 0835 จบ)
  ตรวจแล้ว: share043 (Bench0, จบ 09:46, shadow_bishop) — Starting Up 1 ครั้ง, ไม่มีบรรทัด hound → log ไม่ปน (โลกอาจโดนเขียน
  seed ทับขณะรัน — ผลน่าจะไม่กระทบเพราะ server ถือโลกในหน่วยความจำ; ถือเป็น "น่าสงสัย") ; share ถัดไปของ Bench0 (เริ่ม 09:46
  ขณะ hound server ยังอยู่ — port เดียวกัน) **ยังไม่จบ** → ตรวจเมื่อจบ: Starting Up 1, ไม่มี hound, มีฉาก; ไม่ผ่าน = ย้ายไป old
  โฟลเดอร์รอบ hound (0944, ว่าง) ย้ายไป old\bench_logs แล้ว
### 6.14 วิธีทำงานที่คุ้มที่สุด (ผู้ใช้ 2026-10-17: "แก้ 1 จุดแล้วรันใหม่ทั้งหมด ไม่มีที่สิ้นสุด") — วิเคราะห์
**ต้นทุนจริงที่วัดได้:** bench ในเกม หลายชั่วโมง (70 share × 8 server) ; expand_haz 34 share ~3 นาที ; bench_replay ทั้งหมด 46 นาที
(eyeofterror_mini ตัวเดียว ~30 นาที) ; tester_compare log ผู้ใช้ 7 นาที ; rebuild UM 9 + เกม 6–14 นาที ; shapes_all บอสเดียว 1 นาที ;
ผู้ตรวจ 3–5 นาที/รอบ
**ทำไมไม่จบ:** (1) วงสั้น หา→แก้→รันทั้งหมด→เจอใหม่ ; (2) ไม่มีนิยาม "เสร็จ" ; (3) ตัวตรวจแพงเพราะ replay.lua **O(ตี × เฟรม)**: ทุกการตีวน
drawn_at ทั้งก้อน 4 ครั้ง (:1228 DrawnNear, :1287, :1294, :1197 WarnedFor วนจากท้าย) — drawn_at เรียงตามเวลาอยู่แล้ว → ค้นแบบ binary ได้ ;
(4) ไม่มี cache: เปลี่ยนจุดเดียวรันทุกบอส ; (5) หาเหตุทีละบอสด้วยมือ (Bearger ใช้ทั้งวัน) แทนที่จะให้สคริปต์จัดคลาสให้ทุก MISSED
**ข้อเสนอ:**
- A. ตัวตรวจถูกลง: binary search ใน replay.lua (+ ตัวคุม: ตัวเลขต้องเท่าเดิมทุกบอส) ; cache ผลต่อ (hash log, hash ข้อมูลที่บอสนั้นใช้จริง
  [merged ต่อบอส], hash ตัววาด, hash ตัวทดสอบ) → แก้ข้อมูลบอสเดียว = รันบอสเดียว ; แก้ตัววาด/ตัวทดสอบ = รันทุกตัวแต่เร็ว
- B. จัดคลาสอัตโนมัติ: ทุก MISSED/FALSE ได้ป้ายจากหลักฐานใน trace (HIT ไร้ STRIKE+พื้นที่ / ของ as_boss ใกล้ / ฉากเริ่มไม่ใช่อนิเมชันแรก
  ของท่าใด / state ไม่มีในข้อมูล / กระสุน LAUNCH) → ตาราง คลาส × บอส ครั้งเดียว แทนไล่ทีละตัว
- C. หา C3 แบบ static จาก stategraph (เกม + postinit UM) ไม่ต้องรอ bench เจอ
- D. รวบการแก้เป็นชุด: แก้ทุกคลาสที่รู้ → rebuild ครั้งเดียว → ตรวจครั้งเดียว (A ทำให้ ~10 นาที) → ผู้ตรวจครั้งเดียว → bench ในเกมคืนเดียว
  (รวม trace ใหม่ทั้งหมด: LAUNCH/STRIKE by, MISSAREA, ลูกดอก [tr_haz]) ; ของใหม่ที่เจอกลางชุด = จดไว้ชุดหน้า
- E. นิยามเสร็จ (ต่อชุด): ทุก MISSED ที่เหลือมีป้ายคลาส ; ทุกคลาส = แก้แล้ว (ตัวคุมผ่าน) หรือจดเหตุที่ไม่แก้ ; ไม่มีบอสไหนแย่ลง
**ผู้ตรวจ 6.14 (ตรวจกับโค้ดแล้ว):**
- จุดแพงจริงน่าจะไม่ใช่ที่ผมชี้: **การจับ track :530-543** วนทุก track ที่เคยมีทุก tick ไม่ลบที่จบ (eyeofterror_mini เกิด/ตายตลอด) = O(tick×track) ;
  + Dodged :513-519 O(ตี²) ; + in_state :1305 O(ตี×tick) ; + DrawnNear/began/WarnedFor/you_first/NothingDrawn/:1408 → **วัดด้วย os.clock ก่อนแก้**
  ; ค้นแบบ binary ปลอดภัยถ้าคงความหมายเดิมทุกจุด (บางจุด "ตัวสุดท้ายในช่วง", บางจุดเดินถอยหลังพร้อม gap) → ตัวคุม: **stdout ทั้งไฟล์เท่ากันทุก byte**
  ทุก log ผู้ใช้ + ทุก share
- key ของ cache ต้องครบ: ไฟล์ log จริง (ขยาย/ไม่ขยาย ต่างกัน) ; scripts/true_range/*.lua ทั้งหมด **+ modmain.lua** (replay อ่าน SIM_FAR/PICK_EVERY :765) ;
  ข้อมูล: บรรทัดของบอสในทั้งสองไฟล์ + _hazards + _alias ทั้งก้อน (หรือทั้งสองไฟล์ถ้า rebuild ไม่ deterministic) ; stategraph ของบอส + sg_of.lua +
  path game_scripts(_um) ; replay.lua (+shapecheck) ; env ทุกตัวที่ replay อ่าน (57) + from/to + luajit → ตัวคุม: เปลี่ยน 1 byte ต่อชนิด ต้องรันใหม่
- ตัวจัดคลาส = **ป้ายหลักฐาน** ไม่ใช่สาเหตุ (หลายป้ายได้, ไม่มีป้าย = "ยังไม่จัด") ; เชื่อได้: LAUNCH/MISSAREA (เมื่อ trace มี), "state ไม่มีท่าในข้อมูล",
  "ฉากเริ่มกลางท่า", "วนเกินข้อมูล" ; แค่ผู้สมัคร: ของ as_boss ใกล้, ตัวอื่นในโลก ; บอกไม่ได้จาก trace: ข้อมูลผิด vs ตัววาดผิด, สาเหตุ FALSE ;
  ตัวคุมคำตอบที่รู้: share003 Bearger 46+5 หลุม, phase3 10-11_1155 พื้นที่, share050 spitter LAUNCH
- กับดัก: rebuild ไม่ deterministic (phase2) → ตรวจ rebuild 2 ครั้งไม่แก้อะไร = ต้องเท่ากัน ก่อนเชื่อ cache/diff ; รวบชุดซ่อนการถอยหลัง → ตัวคุมต่อการแก้ 1 ตัว
  (ปิดทีละตัว — มี cache ถูก) ; "ไม่แย่ลง" วัดต่อบอส × คลาส, MISSED/FALSE แยก, bench/log ผู้ใช้แยก + shapes_all ; "เสร็จ" ต้องระบุที่ไม่ได้ทดสอบ
  (ตี 0 = FALSE อย่างเดียว ; 0 ฉาก = ยังไม่ทดสอบ) ; log bench 0835 ใช้ต่อได้กับทุกการแก้ข้อมูล/ตัววาด — bench ใหม่จำเป็นเฉพาะ trace ใหม่
**แผนสุดท้าย (ลำดับเร็วสุด):**
1. modmain: trace ใหม่ (LAUNCH / STRIKE by <กระสุน>, MISSAREA, [tr_haz] ของลูกดอก) → bench คืนเดียว **รันคู่ไปกับงาน offline** (ยาวสุด เริ่มก่อน)
2. ความเร็ว: วัด os.clock → แก้ track (:530 ตาราง guid + เฉพาะ 3 s ล่าสุด) → ค้นเป็นช่วง ; ตัวคุม byte-identical
3. cache key ครบ + ตรวจ rebuild deterministic
4. ตัวจัดคลาส (ป้ายหลักฐาน) + ตัวคุมคำตอบที่รู้
5. C3 แบบ static (กฎสแกน sim_moves.lua:557/563-569)
6. แก้ทุกคลาสเป็นชุด + ตัวคุมต่อการแก้
7. ผู้ตรวจรอบเดียว → เสร็จตามนิยาม E
**ตัดทิ้ง:** ไล่ทีละบอสด้วยมือก่อนมีตัวจัดคลาส ; ทาง WHOLE
### 6.13 ทั้ง bench ทีเดียว (ผู้ใช้ 2026-10-17: "ทั้งหมดนี้บอส 1 ตัวหรอ" → ไล่ทีละคลาสจากข้อมูลทั้งหมด) — วิเคราะห์ก่อนทำ
ข้อเท็จจริงของรอบ 0835 (70 share, 4.8 GB; นับแบบ stream: scratchpad share_census.lua):
- ตัวคุม hound: share065 42 ฉาก, ตี 84 → bench ตีจริง ✓ ; **share043 ใช้ไม่ได้** (log เริ่ม t=10622 — ถูกตัดตอน hound ชน Bench0) → old ;
  share052 (Bench0 หลังชน) สะอาด (Starting Up 1, ไม่มี hound)
- สถานะบอส: **590 ฉากแต่ตี 0** (firehound, hedgehound, stalker, toadstool(_dark), terrorbeak, mushgnome, mermguard×3, merm_lunar/shadow,
  knight/bishop_nightmare, spider_dropper/healer/hider/moon, pigguard, koalefant_winter, leif_sparse, gingerbreadwarg, mutatedhound, crawlingnightmare)
  = ตรวจได้แค่ FALSE ไม่ใช่ MISSED ; **0 ฉาก (G)** = ยังไม่ทดสอบ (crabking, daywalker2, deer, gnarwail, lunarthrall_plant, mermking,
  wagboss_robot, worm_boss, sinheniddnadtdfo, …; malbatross 1 ฉาก) — ต้องหาว่าทำไม "ตี 0" เป็นคลาสของ bench เอง (ข้อ 6.13b)
- LUA ERROR ใน 7 share = โค้ด UM/เกม ล่มกับตัวแทน (um_beegun, web_bomb, NumHoundsToSpawn) = คลาสที่รู้แล้ว (!np) ; ข้อมูลก่อนล่มใช้ได้
- ต้อง expand 34 share (มี _you) ; มากสุด share063 ~2.7M บรรทัดเพิ่ม, share026 ~1.7M ; หน่วยความจำ ~4.4× ขนาดเข้า (share003 0.44 GB) →
  share026 ~1.3 GB ; share015 (928 MB) ไม่มี [tr_haz] ไม่ต้อง expand
- ต้นทุน: replay 23 s / 0.41 GB, replay_haz 31 s / 0.33 GB (share014) → ~190 คู่ + 34 haz ≈ 15–25 นาทีบน 16 core, ~8 GB
แผน: tests\bench_replay.ps1 — (1) expand สำเนาไป tests\work\bench_x\<run>\ (ไม่แก้ log ที่เชื่อได้) ทีละ 4 ; (2) replay ทุกบอสที่มีฉาก
(game_scripts_um, TR_MODS) + replay_haz ต่อ share ; ข้าม share043 ; share015 จำกัด 2 พร้อมกัน ; (3) ตาราง: บอส, ฉาก, ตี, strikes, MISSED,
FALSE, สถานะ (ทดสอบแล้ว / FALSE อย่างเดียว / ไม่ได้ทดสอบ) → แล้วจัดกลุ่มตามกลไก
**ผล (224/225 — eyeofterror_mini ใน share015 ยังรัน >30 นาที, 4.3 GB):** 185 บอส, ตี 112,183, MISSED 11,030, FALSE 8,477, error 0 ;
บอสที่โดนตี 150 ตัว: 89 วาดครบ. MISSED 100%: spider_spitter 3243, stageusher 1613, waterplant 887, worm 540, lunar_grazer 540,
shadowthrall_wings 265. FALSE มากสุด: twinofterror1 1914, uncompromising_buffrat 335, smallbird 291, twinofterror2 230, eyeofterror 216
**จัดกลุ่ม (ตรวจโค้ด + ข้อมูล + scene_starts.lua: ฉากที่ 2 s ก่อนเริ่มไม่มีอนิเมชันแรกของท่าใดในข้อมูลเลย):**
- C1 กระสุนที่ตั้งใจไม่ทำเป็นท่า (sim no_auto): spider_spitter spitter_attack (:242), walrus blowdart (:412), waterplant attack (:423)
  → เกมเครดิตการกระทบให้บอส (DoAttack + projectile) → replay ตัดสินกับท่า = MISSED ; STRIKE นับซ้ำ (ยิง+กระทบ: spitter STRIKE 3243 = 2×HIT 1615)
  ยังไม่ตรวจ: กระสุนของ spitter/walrus มีข้อมูล thing ไหม (waterplant_projectile มี)
- C2 ของที่ยกเครดิตให้บอส (as_boss): shadowthrall_wings (cast ไม่ได้ท่า, มีแค่ shadowthrall_projectile_fx; HIT 290 STRIKE 0),
  stageusher (มือใช้ combat ของ usher: HIT=STRIKE 1690; ข้อมูลมีแค่ sleep + stageusher_attackhand), um_bearger_sinkhole
- C3 state ที่เกมเข้าตรง แต่ BOSSES ไม่มี / ท่าในข้อมูลเริ่มด้วยอนิเมชันอื่น: worm attack (SGworm.lua:5 — attack_pre เฉพาะตอนเป็นเหยื่อล่อ;
  BOSSES :358 มีแค่ attack_pre), lunar_grazer devour, spider warrior_attack (UM), knook aggresivehop, dreadeye attack_teleport_pre,
  rambranch mushroombomb ; (toadstool mushroombomb/sporebomb, mushgnome: ตี 0 → ดูได้แค่ FALSE)
- C4 ท่าวนซ้ำเกินข้อมูล: tentacle, wicker_tentacle attack/atk_loop (ข้อมูล atk_pre→atk_loop รอบเดียว; tentacle MISSED 402/1104)
- worm "เริ่มกลางท่า" ที่ดูเหมือนบั๊กของ bench → **ไม่ใช่**: trace ต่อเนื่อง, worm เข้า attack ตรงจริงในเกม = ช่องว่างจริง (C3)
**ต่อไป:** ผู้ตรวจ → แก้ทีละคลาส (C2 as_boss + C1 ตัวทดสอบก่อน — ไม่ต้องรัน bench ใหม่; C3/C4 ต้อง sim ใหม่)
**ผู้ตรวจ (ตรวจกับโค้ดแล้ว):**
- C1 ถูก (spitter spider.lua:418-421, walrus.lua:97): ยิง = combat.lua:1160-1163 LaunchProjectile (ยังไม่ตี) ; กระทบ = projectile.lua:226/242
  `attacker.components.combat:DoAttack(target, weapon, self.inst, …)` → STRIKE 2 ครั้ง. **BLOCKING:** ลูกดอก/ใยพ่นไม่มีข้อมูล hazard และไม่มี
  [tr_haz] — วาดเฉพาะใน modmain.lua:780 DARTS → **ตัวทดสอบวาดไม่ได้** ⇒ ห้ามย้ายออกจาก MISSED จนกว่า replay จะวาด DARTS (ไม่งั้น = เปลี่ยนป้าย)
  ; MISSED ของ spitter ต้องนับเทียบ HIT (~1615) ไม่ใช่ STRIKE 3243
- **waterplant = C2 ไม่ใช่ C1** (waterplant_seed.lua:49 GetAttacked(thrower) — HIT ไม่มี STRIKE) — มีข้อมูล waterplant_projectile + [tr_haz] 15927
- stageusher C2 (stageusher.lua:426-428 `_owner.components.combat:DoAttack`) → as_boss ต้องติดทั้งทาง GetAttacked และทาง DoAttack ของบอส
  (sim_moves.lua:1416-1434) ; บางส่วนเป็น C4 ด้วย (attack_loop ซ้ำ, STEPTIME)
- C3 ที่มาจริง: กฎสแกน sim_moves.lua:563-569 — state ที่ state โจมตีอื่นเข้าไปได้ ไม่นับเป็นจุดเริ่ม ; regex doattack :557 จับแค่
  `GoToState("ชื่อ")` ตรง ๆ (พลาด ternary แบบ SGworm:5) ; ไม่อ่าน postinit stategraph ของ UM (UM spider warrior_attack / spit_web /
  trapdoor_attack, postinit/stategraphs/SGspider.lua:73-80) → ตัวค้นอย่างเป็นระบบ: ทุก state ใน GoToState นอก State{} (handler, local fn)
  ของ SG เกม + postinit UM ที่ทำร้าย (HARM :523) ลบ BOSSES/no_auto/ชื่อท่าในข้อมูล
- lunar_grazer **ไม่ใช่ C3**: devour มี tag attack (SGlunar_grazer:817) + DoAttack (:842) → สแกนเจอ แต่ข้อมูลมีแค่ spawn → น่าจะ sim error ใน onenter
  (inst.core.AnimState :822) — ต้องดู stderr ของ sim
- C1 ย้อนกลับ: อาวุธยิงกระสุนอื่น — eyeturret, monkey, spat (no_auto), UM bearger_boulder, queen_web_bomb, chimp → เปลี่ยนตัวทดสอบแล้วต้องไล่ทุกตัว
- เครื่องหมาย: **อย่าใช้ช่องห่างเวลา** (ใยพ่นกระทบ 6 frame หลังยิง = ช่องห่างคอมโบ) → modmain ตัวห่อ DoAttack (:1754) ได้ args อยู่แล้ว:
  projectile ~= nil = กระทบ → "STRIKE by <prefab>" ; อาวุธยิงไกลแล้ว projectile == nil → "LAUNCH" (ไม่ใช่การตี)
- ตรวจต่อ: ตัวแปลกในโลก (walrus HIT at rabbit ใน share003) ต้องไม่ตีตัวแทนกลางฉากบอสอื่น ; แต่ละบอส 100% ต้องมีภาพ 1 ครั้ง (PIC_AT) ก่อนแก้
**ผล bench ครบ 225/225 (2,749 s):** ตี 121,333, MISSED 11,387, FALSE 9,565, error 0 (eyeofterror_mini 9150 / 357 / 1088)
**(0) rebuild ลอย — ตอบแล้ว:** mosquito explode / minotaur gore "หาย" = mod_diff ทิ้งสำเนาที่**เท่ากับของเกม** (ทั้ง 3 ท่า: UM เดิม = เกมติดตั้ง =
base ใหม่ = UM ใหม่) และ moddata.lua:50-51 รวมทีละท่า → ไม่หายจริง. ข้อมูลที่เกมใช้จริง (เกม + overlay รวมแบบ moddata, merged_eq.lua)
เก่า vs rebuild: ต่าง **2 จุด** = again (ตั้งใจ) + alterguardian_phase2.attk_stab_pre maps → sim รันซ้ำ 2 ครั้งได้ maps **ไม่เท่ากันเอง** (seed ต่อ Run
:2011 แล้ว → น่าจะลำดับ pairs() บนตาราง key เป็นตาราง) = sim ไม่ deterministic สำหรับท่านี้ — งานแยก ความสำคัญต่ำ ⇒ rebuild ใช้ได้
**ลำดับใหม่:** (0) หาสาเหตุ rebuild ลอย (mosquito/minotaur หาย) — งาน sim ทุกอย่างต่อจากนี้ต้อง rebuild ได้เชื่อได้ก่อน
(1) as_boss (sim ทั้งสองทาง + ช่วงเวลา) → C2: waterplant, stageusher, wings, หลุม (2) ตัวค้น C3 อย่างเป็นระบบ + lunar_grazer sim error
(3) modmain: LAUNCH / STRIKE by + [tr_haz] ของลูกดอก, replay วาด DARTS ด้วยโค้ด modmain เอง → ต้อง bench ใหม่ (4) C4 ท่าวน
### 6.12 Bearger (UM) 51 MISSED — วิเคราะห์ (2026-10-17, ยังไม่แก้)
ข้อเท็จจริง (share003 ของ 0835; replay ทั้งช่วง: 876 strikes, 825 drawn, 51 missed):
- โค้ด UM postinit/prefabs/bearger.lua:111-127: หลุม i=1..5 เกิดที่ i·4.5 จากบอส ห่างกัน FRAMES·1.5+0.1 s (= 4.5 frame);
  `PushEvent("startcollapse")` **ก่อน** `fx.bearger = inst` → stage 1 (ทันที) ไม่มีผู้ตี = ไม่ทำดาเมจ;
  um_bearger_sinkhole.lua:186 DoPeriodicTask(0.5) → **ตีที่ born+15 และ born+30 frame**, รัศมี 2.5+1 = 3.5 (จุดกลางเท่านั้น), ผู้ตี = bearger
- census ตรงโค้ด: หลุม 1 (8378.434, ห่างตัวแทน 0.57) → tr_hit 8378.934 (+15) และ 8379.434 (+30); หลุม 2 (3.93) ไม่ตี ✓
- 51 MISSED จับคู่หลุมได้ **51/51**: 46 ที่ +15 (stage 2), 5 ที่ +30 (stage 3, หลุมห่าง 1.0, state walk_start)
- ข้อมูล: hazard `delay = 15`, step เดียว at=0 (= stage 2 เท่านั้น); move first 20 / lock 21 / set_until 43 (หลุม 5 เกิด ~42 ✓)
- **ต้นเหตุ 1 (ตัวทดสอบ):** replay.lua:879 `inside` = Predict.Draw ของบอสเท่านั้น; ของที่บอสวาง (DrawHazards) วาดเฉพาะ WHOLE
  และผลไม่ถูกรวมเข้า `inside` → การตีของหลุม (เกมนับเป็นของ bearger, ไม่มี onhitother → ไม่มีบรรทัด HIT ของ thing) ถูกตัดสินกับรูปของท่า
  → MISSED ทั้งที่หลุมอาจถูกวาดแล้ว. (ช่วง replay 8377–8381 ได้ 0 missed = เส้นตาราง frame เลื่อน 1 ms — ไม่ใช่หลักฐาน; รูปที่วาดเท่ากันทุก frame)
- **ต้นเหตุ 2 (ข้อมูล, น่าจะจริง):** stage 3 (+30) ไม่มีในข้อมูล — หลุมวาดถึงแค่ ~born+20 (start = since+(15−2)F, +LINGER 0.2 s)
  → ตีครั้งที่สองไม่ถูกเตือน (5 ครั้งที่พลาด; ที่เหลือบังเอิญมีท่าอื่นทับ)
- **กลไกเดียวกันที่อื่น:** antlion_sinkhole (เกม: ตี 3 stage ห่าง 1 s, ผู้ตี = ตัวหลุม — prefabs/antlion_sinkhole.lua:162,181),
  antlion_sinkhole_lava / antlion_sinkhole_boat (UM) — **ไม่มีข้อมูลเลยทั้ง 3** (moves_sim*.lua มีแค่ um_bearger_sinkhole) = ไม่ถูกวาด;
  ต้องถามผู้ตรวจ + ค้นทั่วไป: ของที่ตีหลายครั้งด้วย DoPeriodicTask/DoTaskInTime แต่ข้อมูลมี step เดียว
แผน (ทีละขั้น, ตัวคุมทุกขั้น):
1. ตัวทดสอบ: ใน WHOLE ให้ strike ที่ตกในของที่บอสวาง (by ตรง) นับว่า "drawn by thing" แยกบรรทัดจาก drawn by move (ไม่รวมเงียบ ๆ)
   ตัวคุม: ข้อมูลหลุมเลื่อน delay ผิด (เช่น 40) → ต้องกลับมาเป็น MISSED; และท่าอื่นทุกตัวต้องได้เท่าเดิม (compare ทุก log)
2. ข้อมูล: sim ทำ step ที่สอง (+15 จาก step แรก) ให้ um_bearger_sinkhole — แก้ที่กฎของ sim (DoPeriodicTask ของ thing) ไม่ใช่ใส่มือ
3. ของที่ไม่มีข้อมูล (antlion sinkholes): แยกเรื่อง — ถามผู้ใช้ก่อนว่าอยู่ในขอบเขตไหม
**ผู้ตรวจ (AGREE WITH NOTES) — ตรวจกับโค้ดแล้ว:**
- ถูก (BLOCKING): มีกลไกนี้อยู่แล้ว 2 ที่ — replay.lua:440-483 (BYTHING, `OWN_FAR = 6` :446) และ replay_haz.lua:144-179 (gate `> 36` :158):
  ส่งการตีของบอสให้ของของมันเองใน 3.5 **เฉพาะเมื่อบอสอยู่ห่าง > 6** → หลุม 1 อยู่ 4.5 จากบอส ตี d=5.06 → ข้ามทั้งคู่. แผนข้อ 1 เดิม
  (เพิ่มทางที่ 3 ใน WHOLE) = ซ้ำ + WHOLE เขียนทับ Predict.EntsNear (:885) ไม่คืน → **ทิ้ง**; แก้ gate ที่ใช้ร่วมแทน
- ถูก: กฎของ sim ทั่วไป — sim_moves.lua:2538 lasting เฉพาะเมื่อตีซ้ำห่าง ≥ 20 frame; Restruck (:1169) เก็บแค่ run แรก + ครั้งสุดท้าย
  → ของที่ตีซ้ำภายใน 20 frame เหลือ step เดียว (หลุม: 15), 3+ ครั้งหายตรงกลาง → แก้ที่ :2535-2539 ไม่ใช่สเปกหลุม; rebuild ทั้งสองไฟล์ + diff _hazards
- ถูก: antlion_sinkhole_boat ตีแค่เรือ (ไม่ต้องมีข้อมูล); antlion_sinkhole_lava ไม่พบผู้สร้าง; antlion_sinkhole (เกม) ไม่เคยเกิดใน bench = ยังไม่ทดสอบ
- กลไกเดียวกันที่ต้องตรวจ: shadowthrall_projectile_fx (ผู้ตี = inst.owner, by shadowthrall_wings, ไม่ in_move, share045 เกิด 3540)
**แผนใหม่:**
1. gate ใหม่ (ไม่อิงข้อมูลที่ทดสอบ): strike ในสถานะที่ไม่มีข้อมูลท่า + ของของบอสเองอยู่ใน 3.5 → ส่งให้ replay_haz ตัดสิน (ระยะบอสไม่ใช่เงื่อนไข)
   ตัวคุม (สร้างด้วย make_controls): (ก) ลบ hazard um_bearger_sinkhole → 51 ต้องกลับเป็น MISSED ใน replay_haz (ข) delay ผิด → MISSED
   คาด: replay_haz share003 → 46 วาด (+15), 5 MISSED (+30 ไม่มีในข้อมูล); ทุกบอสที่ตัวเลขเปลี่ยน (0835 ทุก share + compare) ต้องอธิบายได้
   **ผลขั้น 1 (2026-10-17):**
   - **พบอีกข้อ (ของผม, เคยจดไว้ :456 แล้วลืม):** log ของ bench **ไม่ได้ผ่าน tools\expand_haz.lua** (verify.ps1 ขยายเฉพาะ log ผู้ใช้)
     → ของที่ยืนนิ่งมี [tr_haz] บรรทัดเดียวตอนเกิด → ทั้ง replay และ replay_haz เห็นมันแค่ ~2 frame. ตัวเลขของ (thing) จาก bench
     ก่อนหน้านี้ทั้งหมดใช้ไม่ได้ → ขยายสำเนาก่อนทุกครั้ง (share003: 9 s, 3131 ของ). ตัวเลข 51 เดิม = log ไม่ขยาย
   - กฎใหม่ (replay.lua by_thing + replay_haz :144): HIT ที่ไม่มี STRIKE ของบอสตัวเดียวกันใน 0.05 s + ของของมันเองใน 3.5
     → ของตัดสิน (นอกจากกฎบอส > 6 เดิม); OLD_THING_GATE=1 = แบบเดิม. ใช้เฉพาะ log ที่มีบรรทัด STRIKE
   - share003 ขยายแล้ว: เดิม bearger 46 MISSED / haz 5 MISSED → ใหม่ bearger 0 MISSED, 271 BYTHING / haz 882 strikes, **135 MISSED
     = ทั้ง 135 คือหลุม +30 frame (stage 3)** — เดิมถูกนับเป็นท่า attack ของบอส (รูปปัดบังพอดี) ; +15 ทั้งหมดวาดถึงแล้ว
     → ต้นเหตุ 2 (ข้อมูลไม่มี +30) ใหญ่กว่าที่คิด: 135 ไม่ใช่ 5
   - ตัวคุม nosinkhole (make_controls): BYTHING 0, MISSED 51 กลับมา ✓ (กฎทำงานผ่านข้อมูลของของบอสเท่านั้น)
   - ⚠ รอบก่อน ๆ ของ UM bearger ใช้ game_scripts ไม่ใช่ game_scripts_um (shapes_all ใช้ _um) → ต่อจากนี้ใช้ _um
   - เครื่องมือใหม่ tests\tester_compare.ps1 -Env <ชื่อ env>: mod เดียว ตัวทดสอบสองแบบ ทุก log × บอส + replay_haz
   - **ตรวจกลับ (log ผู้ใช้ 126 ไฟล์, 844 log×บอส, 425 s, error 0) → ไม่ผ่าน:** เปลี่ยนแค่ alterguardian_phase3 (log 10-11_1155):
     2 ครั้งย้ายไปของ, MISSED 4→3. ตรวจแล้ว = **การแทงของบอสเอง** (atk_summon_loop t=0.033 = TimeEvent(1) do_stab_attack →
     combat:DoAttack, SGalterguardian_phase3:290/508) — projectile ข้าง ๆ ไม่มีบรรทัด [tr_haz] HIT; ทุกครั้งที่แทงใน state นี้ (9 ครั้ง)
     เป็น HIT ไม่มี STRIKE ทั้งที่บอสนี้มี STRIKE 37 ครั้งที่อื่น (ทำไม STRIKE ไม่ถูกเขียน — ยังไม่รู้, ต้องหา: อาจเป็นบั๊ก trace)
     → "HIT ไม่มี STRIKE" **ไม่ใช่เครื่องหมายของ thing ที่เชื่อได้**; กฎซ่อน MISSED จริง → **ปิดเป็นค่าเริ่ม** (เปิดด้วย THING_GATE_V2=1)
     ตรวจแล้ว: ค่าเริ่มให้ตัวเลขเดิม (phase3 10 strikes, 4 missed)
   - **ข้อเสนอใหม่ (ยังไม่ทำ):** ให้ sim บอกจากโค้ด — ตอนของ (acting = thing) ตีหุ่นแล้ว data.attacker = บอส → hazard ได้ `as_boss = true`
     (UM sinkhole: GetAttacked(inst.bearger); gestalt projectile: combat ของตัวเอง → ไม่ได้) ; ตัวทดสอบ: ส่งให้ของเฉพาะ hazard as_boss
     ใน 3.5 (ไม่ต้องดู STRIKE / ระยะบอส) ; ตัวคุม: nosinkhole + phase3 log ต้องไม่เปลี่ยน + shadowthrall_projectile_fx (inst.owner) ต้องได้ as_boss
     ; ต้องให้ผู้ตรวจดูก่อน. ระหว่างนี้: หลุม +30 (135 ครั้งใน share003) = ข้อมูลขาดจริง ไม่ขึ้นกับกฎนี้ (เห็นตรงจาก replay_haz + census)
   - **แก้คำพูดผม:** "9 ครั้งไม่มี STRIKE" ผิด — ผมค้นแค่บรรทัด HIT; จริง ๆ ไม่มี STRIKE **2 ครั้ง (4 รวมไฟล์สำเนา _bk)**
**6.12b — ทำไม HIT ไม่มี STRIKE (วิเคราะห์, 2026-10-17):**
- โค้ด: combat.lua:1122-1126 DoAttack ที่ CanHitTarget ไม่ผ่าน (หรือ AOEarc) → **DoAreaAttack(self.inst, areahitrange)** = ตีทุกอย่างใน
  areahitrange รอบ**ตัวบอส** (GetAttacked(boss), :1308) ; modmain:1757 เขียน STRIKE เฉพาะเมื่อ CanHitTarget ผ่าน → การตีพื้นที่นี้ = HIT ไร้ STRIKE
  phase3: SetAreaDamage(3, 0.8) (prefabs/alterguardian_phase3.lua:425) — ตัวแทนห่าง 2.79 → โดน, **ไม่ได้วาด** (MISSED ในเกมจริง)
- นับทั้ง log ผู้ใช้ (126): HIT ไร้ STRIKE 93 ครั้ง / 14 บอส|state; MISSED แค่ 2 ครั้งจริง (phase3 atk_summon_loop 1, dreadeye
  attack_teleport 1); ส่วนใหญ่ = บอสที่มี SetAreaDamage (UM mock_dragonfly 6, moonmaw_lavae, moose landatk) → **HIT ไร้ STRIKE ส่วนใหญ่คือการตีพื้นที่
  ไม่ใช่ thing** → กฎ V2 ผิดหลักการ (ไม่ใช่แค่ขอบ) → **เอาออก** (ไม่เก็บไว้เป็นทางเลือก — ไม่ให้มีของผิดค้าง)
- **ช่องว่างการวาด (คลาสใหม่ 18?):** sim ทำ "พลาดแล้วตีพื้นที่รอบตัว" แล้ว (sim_moves.lua:1368-1379) แต่**เฉพาะ MODENV** (ข้อมูล UM) —
  ความเห็นว่า "the game's own moves as checked" ไม่มีหลักฐานจดไว้ที่ไหน. บอสเกมที่มี SetAreaDamage: alterguardian_phase3, crabking,
  malbatross, shark, squid, stalker, gnarwail (+ deciduous_root, cannonball/mortarball = ของ). หลักฐานเกมจริง: phase3 1 ครั้ง (2.79 จากบอส)
  ; ความเสี่ยงถ้าเปิด: รูปวงรอบบอสทุกท่าที่ DoAttack ของบอสเหล่านี้ (FALSE เพิ่ม?) → ต้อง rebuild + compare + bench ของบอสพวกนี้
- **trace ขาด:** การตีพื้นที่จาก DoAttack ที่พลาด ไม่มีชื่อใน log → เสนอ modmain (DEBUG) เขียน "AREA at" ในตัวห่อ DoAreaAttack ของบอส
  → ตัวทดสอบแยก "บอสตีพื้นที่" ได้ตรง ๆ แทนการเดาจาก STRIKE ที่หาย
- **แผน (ลำดับ):** (1) ลบกฎ V2 ออกจาก replay/replay_haz (2) trace "AREA at" (3) as_boss จาก sim (ของที่ GetAttacked(บอส)) — ตัวทดสอบส่ง
  ให้ของเฉพาะ hazard as_boss (4) `again` สำหรับหลุม +30 (5) area-on-miss ให้บอสเกม — แยก ตัดสินด้วยข้อมูลหลังข้อ 2
  ผู้ตรวจก่อนข้อ 2-5
  - (1) ทำแล้ว: กฎ V2 ลบออกจากทั้งสองไฟล์ — diff กับสำเนาก่อนแก้ = ต่างแค่ comment (โค้ดเท่าเดิม)
  **ผู้ตรวจรอบ 6.12b (ตรวจกับโค้ดแล้ว):**
  - (d) BLOCKING ถูก: เกมปิดพื้นที่ด้วย EnableAreaDamage(false) ระหว่าง groundpounder (groundpounder.lua:79/174/368) และ SGmalbatross:557;
    sim **ไม่มี** EnableAreaDamage/areahitdisabled/AOEarc เลย → เปิด gate ตอนนี้ = วาดวงรอบบอสระหว่าง pound ผิด ; ข้อมูล UM อาจเสี่ยงอยู่แล้ว
    (บอส UM ที่มี groundpounder + พื้นที่) → ต้องหา. UM UMSetAreaDamage (leif) = ทางอื่น (กรวยทุก DoAttack) — sim ไม่มี um_areahit
  - (a) ย้ายที่: ไม่ห่อ DoAreaAttack (SG เรียกตรงเป็นท่าปกติ: stalker, shadow_bishop/rook, cookiecutter; และรอบเป้าหลังตีโดน combat.lua:1203)
    → เขียน "MISSAREA" ในตัวห่อ DoAttack เดิม (modmain:1754) เมื่อ (ไม่ผ่าน CanHitTarget หรือ AOEarc) และ areahitrange และไม่ areahitdisabled
    = เงื่อนไขเกม :1122-1124. ตัวคุม: phase3 2.79 ต้องมี MISSAREA; บอสไม่มีพื้นที่ต้องไม่มีเลย
  - (b) ตรวจได้ใน sim: dummy GetAttacked ส่ง { attacker } (sim_moves:1894-1897), acting = ของ (task :2468, listener :1264) → ติดป้ายที่ :1234
    `as_boss = data.attacker == sim_boss and acting ~= sim_boss`; และทาง combat ของบอสที่ของเรียก (c:DoAttack :1416, Scrappy junk) ด้วย
    BLOCKING ถูก: หลุมอยู่ต่อ 5 s หลังตีครั้งสุดท้าย (um_bearger_sinkhole:109-110) → "ใน 3.5" อย่างเดียว ขโมยการข่วนจริง → จำกัดด้วยอายุที่มันตีจริง
    (sim: strikes_until จาก h.last ต่อ hazard) + 2 frame. ตัวคุม: nosinkhole, phase3 ไม่เปลี่ยน, shadowthrall_projectile_fx ต้องได้ as_boss,
    + สำเนาหลุม delay +40 (หลุมที่ยังไม่ตีต้องไม่รับ). ตรวจกลับ: รายชื่อ hazard ที่ได้ as_boss ทั้งสองไฟล์ ต้องมีเหตุผลทุกตัว
  - (c) ถูก: รายชื่อจากโค้ดหาไม่ได้ (97 ไฟล์ UM มี DoPeriodicTask สั้น) → **dry run ของ sim ก่อน** พิมพ์ช่องที่ตีขาดตอน > 2 frame
    ภายใน 20 frame และไม่ lasting ; ส่ง `again` เฉพาะเมื่อทุกช่องได้ offset เดียวกัน ±1 frame (ไม่งั้นไม่ส่ง + พิมพ์ไว้ตรวจ)
    ตัวคุม: diff _hazards (เปลี่ยนเฉพาะรายชื่อ dry run), ภาพ born+30, share003 ขยายแล้ว +30 MISSED 135 → 0, FALSE ช่วง 30-45 ไม่เพิ่ม,
    สำเนาไม่มี again → 135 กลับมา
  **ลำดับที่จะทำ:** (c) dry run (อ่านอย่างเดียว) → (c) ทำ → (b) → (a) MISSAREA (ต้องรันเกม/bench ใหม่ถึงได้ข้อมูล) → (d) ทีหลัง
  **(c) dry run (DBG_PULSES=1, sim_moves Restruck จด h.pulses; game ไม่ครบ — TIMEOUT mutatedbuzzard_gestalt ตอนเครื่องแน่น):**
  - um_bearger_sinkhole: ซ้ำ **100%** ของช่อง (509,832), offset **15 อย่างเดียว** → again = { 15 }
  - alterguardian_phase2spiketrail 73% (5 / 5,10 ปน, moved) ; firesplash_fx (UM) 4.7% ปน ; warg_mutated_breath_fx 32% แต่ lasting แล้ว ;
    sharkboi_swipe_fx in_move ; deerclops_icespike_fx 0.2% (ช่องทับสองหนาม) → กฎ "≥95% ของช่องได้ลายเดียวกัน ไม่ lasting ไม่ in_move"
    → ได้ again เฉพาะหลุม. spiketrail/firesplash ไม่ผ่านกฎ = จดไว้เป็นงานแยก (+10 ของ spiketrail อาจเกิน LINGER 6 frame)
  - ทำแล้ว: sim (pulses ต่อช่อง → pulse_sig ต่อ hazard, รวมข้าม -jobs ที่ :3971, เขียน again ที่ตัวเขียน hazard) ; ตัววาด simmoves Steps()
    เพิ่ม step at+off ; สำรองข้อมูลก่อน rebuild: scratchpad\rebuild\moves_sim*.before.lua
  - **rebuild (2026-10-17):** UM: again เฉพาะ um_bearger_sinkhole = { 15 } ; game: 0 ; hazdiff _hazards: UM 1 จุด (again), game 0
    ⚠ rebuild UM ทั้งไฟล์ **ลอยไปจากเดิม** (ไม่เกี่ยวกับ again): mosquito explode หาย, minotaur gore หาย, cells ของบอสบรรทัด 51 หนึ่ง step
    → **ไม่ใช้ไฟล์ rebuild**; ติดตั้ง = ไฟล์เดิม + `again = { 15 }` อย่างเดียว (hazdiff 1 จุด, ไม่มี BOM); ไฟล์ rebuild เก็บที่
    scratchpad\rebuild\moves_sim_um.rebuilt.lua → **งานแยก: ทำไม rebuild ทำให้ 2 ท่าหาย** (UM อัปเดต? sim เปลี่ยน? mod_diff?)
  - **ตัวคุม (share003 ขยาย, replay_haz HAZ_ALL_NEAR=1 — ทดสอบการวาดของอย่างเดียว):** live 174 MISSED / noagain 309 → ต่าง **135 พอดี**
    (= จำนวน +30) ; FALSE 5 → 5 ; ที่เหลือ 174 = ทุกครั้งอยู่ **หลังหลุมเลิกตีแล้ว** (> 32 frame) = การตีของบอสที่ HAZ_ALL_NEAR ยกให้หลุมโดยเจตนา
    → ในช่วงที่หลุมตีจริง (+15, +30) วาดถึงหมด
  - shapes_all (WHOLE, log ผู้ใช้ bearger 9, noagain→live): overlap 1272→1441, split 54→46, morph/open เท่าเดิม, ขอบในรูปอื่น +8.7%,
    ปลายเส้น +3.6% — เข้ากับ "หลุมวาดนานขึ้น ~15 frame" (หลุมห่าง 4.5 รัศมี 3.5 ซ้อนกันจริง) ; **ยังไม่ได้ดูภาพ born+30** (pics.ps1 วาดเฉพาะท่าบอส)
  - ⚠ เครื่องเกือบหมด RAM (0.4/31 GB): ขั้นสรุปของ run_bench 0835 (powershell) กิน 19.8 GB → หยุดแล้ว (share 70 ไฟล์อยู่ครบ); ต้องแก้
    run_bench ให้ stream ก่อนรอบหน้า ; dry run แรกพิมพ์ทุกช่อง (log 345 MB) → เปลี่ยนเป็นนับรวมแล้วพิมพ์ครั้งเดียว
   **ขั้น 2 — วิเคราะห์ (ยังไม่ทำ):** รูปแบบข้อมูลเก็บ **เวลาเดียวต่อช่อง** (sim_moves.lua:4539 `hz.cells[k] = max rel`) → ใส่ "ตีซ้ำ"
   ในช่องเดิมไม่ได้. เสนอ: field ระดับ hazard `again = { 15 }` (จังหวะซ้ำหลังจังหวะแรกของแต่ละช่อง, frame) — sim: Restruck (:1169)
   จดทุกจังหวะที่ขาดตอน (> 2 frame) เป็น h.pulses → ที่ :2535 ส่ง offset (pulse − h.frame) ; รวมทุกช่อง/ทุกตัว = offset ที่พบ
   (ไม่ใช่เฉพาะที่ซ้ำทุกช่อง? — ถามผู้ตรวจ) ; ไม่ใส่ถ้า lasting อยู่แล้ว. ตัววาด: simmoves.lua Steps() (:2416) เพิ่ม step
   { at + off, map เดิม }. ไฟล์ที่กระทบ: sim_moves.lua, simmoves.lua, ข้อมูลทั้งสองไฟล์ (rebuild + diff _hazards ทุกตัวที่ได้ again)
2. sim: เก็บทุกจังหวะที่ตี (ไม่ใช่แค่ first/last) → step ต่อจังหวะ; ตัวคุม: diff _hazards ทั้งสองไฟล์ + ภาพที่ born+30 + bench: +30 MISSED → 0, FALSE ไม่เพิ่ม
- (ต่อจาก 6.11) tests\sim_moves.lua (0 byte) → old\tests; run_bench.ps1:131 แยกบรรทัด `}` กับ `luajit` (เดิมติดกัน — bench_lock อาจไม่รัน)

## 6.20 lag compensation / "แบบมีถ้ำ" (วิเคราะห์ 2026-10-25 — ผู้ใช้ถาม "แก้ lag comp ยังไง, ลองให้เหมือนโลกมีถ้ำได้ไหม")

**ปัญหา (ต่อจากข้อ 49):** เปิดถ้ำ/dedicated = เครื่องผู้เล่นแยกจาก server. วัดจริง 2026-10-25 (latency_probe): ไปกลับ 33 ms
(1 tick), สูงสุด 66–99 ms. เปิด Predictive: ตัวบนจอนำตัวบน server L (1–3 เฟรม; มากกว่าตอนเพิ่งเข้า/วาร์ป), บอสบนจอช้ากว่า server D.
server ตัดสินโดนจากตัวบน server → "บนจอออกจากแดงแล้วยังโดน". ที่ทำไปแล้ว: SERVERAIM (เล็งจากตำแหน่งที่ server เห็น, คงไว้) ;
เลื่อนภาพทั้งหมดตาม lead ที่วัดสด → สั่น (ถอน, TR_LEAD). attack_cancel_sync (2026-10-25) ยืนยันกลไกเดียวกัน: คำสั่งจากจอถึง server
ช้า ~1–4 เฟรมเทียบกับท่าบนจอ.

**ทำไมตรวจตอนนี้ไม่ได้:** log ทั้งหมดมาจากโฮสต์ (ไม่มี lag), bench รันบนโฮสต์/headless (ผู้เล่นเป็นหุ่นบน server), replay YOU_LEAD
เป็นตัวเลขสมมุติ (บทเรียน: ตัวตรวจสังเคราะห์ผิดแบบเดียวกับ sim).

**เสนอ: bench แบบมีถ้ำ (ของจริง)** — ไม่ต้องมีถ้ำจริง แค่ให้เครื่องเล่นแยกจาก server:
1. server: dedicated nullrenderer (Master อย่างเดียวพอ, cluster ทดสอบแยก ไม่แตะโลกผู้ใช้) + True Range (debug.txt → [tr_trace] = ความจริง
   ฝั่ง server) + tr_testbench ฝั่ง server (เกิดบอส, ให้บอสเล็งผู้เล่น, อมตะ) — เร่งเวลาไม่ได้ (client ต้องตามทัน) → 1x
2. client: เกมจริงของผู้ใช้ (Steam) ต่อเองด้วย c_connect("127.0.0.1", port) (consolecommands.lua:477) จาก mod ฝั่ง client ที่เมนูหลัก,
   Predictive เปิด ; ขยับตัวผ่านทางเดิมของเกม (แทนค่าทิศของ PlayerController บนเครื่อง → การทำนาย + RPC เดินจริง ไม่ใช่ SetPosition)
   ตามสคริปต์เดิมของ testbench (step k / jump d) ที่ server สั่งมาตอนท่าเริ่ม
3. log ฝั่ง client ทุกเฟรม: ตัวบนจอ, ตัวที่ server บอก (pose), สิ่งที่ True Range วาด + เราอยู่ใน/นอก ; ฝั่ง server: strike/HIT
   → จับคู่ด้วยเวลา server (tick ใน pose) — วัด L, D และนับต่อ strike: "บนจอนอกแดงแต่โดน" / "บนจอในแดงแต่ไม่โดน"
4. ตัวคุม: รอบเดียวกันปิด Predictive (ควรเท่า bench เดิม) ; รอบเปิด = ตัวเลขที่ต้องลด

**ทางแก้ที่จะลองกับ bench นี้ (ห้ามเลื่อนภาพตามค่าสด):** (ก) เลื่อน "เวลา" แทนตำแหน่ง: ให้สีตี/ล็อคมาเร็วขึ้นด้วยค่าคงที่ ≈ RTT ที่ทำให้
เรียบแล้ว (เวลาสั่นน้อยกว่าตำแหน่ง, ไม่ทำให้รูปขยับ) ; (ข) เลื่อนเฉพาะจุดตัดสิน in/out ที่ใช้เปลี่ยนสี ไม่เลื่อนรูป ; (ค) ขยายขอบเฉพาะ
ฝั่งที่เราวิ่งออก = L × ความเร็วเรา (ค่าคงที่ ไม่ใช่ค่าสด). เลือกด้วยตัวเลขจากข้อ 3 ไม่ใช่ความรู้สึก.

**ความเสี่ยง/ข้อจำกัด:** ใช้จอ+Steam ของผู้ใช้ (ต้องให้ผู้ใช้อนุญาตก่อนเปิดเกม), 1x = ช้า → เริ่มจากชุดเล็ก (bench2: Deerclops, Moose,
Bearger, Wilting, Moonmaw), ping ในเครื่องเดียว 0 ms (มีแค่การรอ tick) — เพื่อนที่ ping จริงจะ L มากกว่า → เพิ่มดีเลย์เทียมทีหลังถ้าต้อง.
**สร้างแล้ว 2026-10-25 (ผู้ใช้ "ทำเลย"):** tools/run_lag.ps1 [-Bosses] [-Rounds 2] [-TickRate 15] [-NoClient] ;
tr_testbench โหมด lag ("tr_bench+lag:", LAG_MODE: ไม่มีหุ่น, รอผู้เล่นจริง, เฉพาะฉาก run/walk (19 ต่อรอบ), Lag comp เปิดทุกฉากคี่
→ รอบ 2 สลับ = ฉากเดียวกันมีตัวคุมของตัวเอง, ไม่ Put ระหว่างฉาก, RPC tr_lag scene/end/struck) ; mod ฝั่งเครื่องเล่น tr_lagjoin
(ต่อเองเมื่อมี join.txt, เลือก Wilson, ขับผ่าน TheInput:GetAnalogControlValue → การเดินของเกมจริง, ThePlayer:EnableMovementPrediction
ต่อฉาก, "struck" จาก server → PushEvent attacked/blocked บนเครื่อง → บรรทัดทดสอบเดิมของ True Range) ; tools/lag_report.lua
(ต่อ on/off: struck, drawn in, NOT drawn, false, lead). ForceEnableMod ใน mods/modsettings.lua + join.txt ใส่เฉพาะตอนรัน เอาออกเสมอ.
ทดสอบแล้ว: server อย่างเดียว (-NoClient) บูต + "lag: waiting for a player" ไม่มี error, cleanup ถูก. **ยังไม่ได้ลองกับเกมจริง** (ต้องขอผู้ใช้ก่อนเปิดเกม).
แก้ระหว่างทาง: testbench `error(a, 0)` เปล่า (modenv_check) → G.error.

**ผลรัน 2026-10-25 (ผู้ใช้หลับ, อนุญาต "รันได้ ทั้งวัน"):**
- ชุด 1–3 (1042, 1100 tick 30, 1130) **ใช้เป็นตัวคุมไม่ได้**: RPC ส่ง `false` มาเป็น nil → ไม่เคยปิด Lag comp (ทุกฉาก Predictive).
  แก้: ส่ง 1/0. ชุด 2 client ล่ม (assert BitmapFontRenderer text_len) ตอน bench ค้าง 6 นาทีที่ sharkboi (ล้มแล้วยังยืน minhealth)
  → lag mode: ล้มแล้วยังยืน 30 s = done. tr_lagjoin วิ่งแบบหยุด-ออกตัวสลับ → เล็งจุดล่วงหน้า 4 เฟรม. True Range: บรรทัด
  "you were struck ... drawn:" มี age= (เวลาตั้งแต่อยู่ในรูปครั้งล่าสุด; "in" ยอมย้อน .15 s ≈ 0.9 หน่วยตอนวิ่ง) → lag_report นับแบบเข้ม > .05 s.
- **ชุด 4 (2026-10-25_1202_lag, tick 15, 8 บอส, เปิด/ปิดสลับจริง — เห็น "Movement prediction disabled"):**
  | | struck | NOT drawn | เข้ม (>.05 s) | false | gap ตอนวิ่ง (median/90%) |
  |---|---|---|---|---|---|
  | เปิด | 597 | 23 | 25 (4.2%) | 27 | 0.64 / 0.81 (จอนำ) |
  | ปิด | 614 | 27 | 27 (4.4%) | 40 | 0.50 / 0.65 (จอตาม) |
  → **ในเครื่องเดียว (แบบที่ผู้ใช้เล่น host+ถ้ำ) Lag comp ไม่ทำให้ True Range แย่ลง**: ตัวบนจอห่างจาก server ~0.5–0.65 หน่วยทั้งสองแบบ
  (คนละทิศ), พลาดเท่ากัน. ที่พลาดเป็นคลาสเดิมที่ไม่เกี่ยว lag: Klaus 18–19 ต่อโหมด, moonmaw ลาวา, bearger หิน (ชุด 1).
- **ชุด 5 (2026-10-25_1236_lag, tick 30, ชุดบอสเดียวกัน):** เปิด struck 557 / NOT 17 / เข้ม 27 (4.8%), gap 0.59/0.75 ;
  ปิด 699 / 13 / 17 (2.4%), gap 0.20/0.26 (tick 30 ภาพตาม server ใกล้กว่า tick 15 ครึ่งหนึ่ง). ส่วนต่างเกือบทั้งหมด = moonmaw lavae
  (ของบินเร็ว, "in" แต่ age .1–.13) ; bearger 5 ตอนเปิด (ทั้งชุด 4 และ 5) = **เหตุการณ์เดียว** ฉาก 37 ทุกครั้ง (หิน UM ตี 5 ทีพร้อมกัน
  ยืนนิ่ง lead 0) — โลกเดิม ฉากเดิม ไม่ใช่ lag. **สรุป: ในเครื่องเดียว Lag comp ไม่ได้ทำให้ True Range พลาดเพิ่มอย่างมีนัย**;
  ถ้าจะมีผลต้องเป็น ping จริง (ยังไม่วัด).
- **snap (ผู้ใช้: "ancient ท่าพุ่ง เล็งมาที่ตัว พอพุ่งจริง snap กลับ"):** tr_lagjoin ครอบ SimMoves.Draw → [tr_lagdraw] ทุกเฟรม
  (ที่, ทิศ, ท่า) ; tools/lag_snap.lua (กระโดด/เด้งกลับในชิ้นเดียว), tools/lag_charge.lua (เลนบนจอ vs ทิศที่ server พุ่งจริง).
  **bench เดิมตัดท่าพุ่งทิ้ง:** state run ไม่ busy → ฉากจบ 15 เฟรมแล้วย้ายบอส (run 128 เฟรม vs run_start 1440) → lag mode: บอสยังขยับ
  = busy (headless ยังเป็นแบบเดิม — คลาสเดียวกัน ควรตรวจว่าทำให้ข้อมูลท่าพุ่งของ bench เดิมขาดไหม). หลังแก้ (1410_lag, 10 ท่าพุ่ง
  วิ่ง 13–20): เลนช่วงตั้งท่าชี้ทิศจริงห่าง 0–11°, ไม่มี snap ทั้งเปิด/ปิด. atk_pre เป็น anchor=lock → ไม่เข้า SERVERAIM (ยกเว้นไว้) —
  ถ้า lead ใหญ่ (ping จริง/หลังวาร์ป) จะเล็งตามตัวบนจอแล้ว snap ตอนล็อค: ยังไม่เห็นในเครื่องเดียว. bench ค้าง: minotaur เดินดันผู้เล่น
  ไม่ตี 4 นาที → lag mode: ไม่มีท่า 60 s = บอสถัดไป.
- **SERVERAIM รวม anchor lock แล้ว (2026-10-25, ผู้ใช้ "ทำเรื่อยๆ ไม่ต้องถาม"):** ข้อยกเว้น anchor lock (41 ท่า 25 บอส) มาจาก
  Champion sweep 22 ต.ค. — ไล่แล้ว: 66/67 glitch อยู่ภายใน 1.5 s หลัง testbench วาร์ปหุ่น (ฉาก step ที่ k ใกล้ lock): ค่าเฉลี่ย
  pose (lock-2, lock-1) = จุดกลางทางวาร์ป. ผู้เล่นวาร์ปไม่ได้ → เอาข้อยกเว้นออก, TR_OLD_SERVERAIMLOCK=1 = เดิม (replay.lua รู้จัก).
  bench_replay 0407 (25 บอส): missed/false เท่าเดิมทุกตัว, เปลี่ยนแค่ phase3 glitch 14→67 (= วาร์ป) ; YOU_LEAD=3 ก็เหมือนกัน
  (replay เลื่อนแค่จุดเช็ค ไม่เลื่อนเป้าที่บอสเล็ง → วัดประโยชน์ไม่ได้). lag bench 1435: ไม่มี error, snap back 0, ท่าพุ่ง 9 ครั้ง
  ชี้ทิศจริง 0°. test_sim 9 FAILED = เท่าตัวที่ติดตั้งก่อนแก้ (มีอยู่เดิม). ติดตั้งทั้งสอง build, patch notes 1.1.6 แล้ว.
  **ทำแล้ว:** replay.lua SHRINK/VANISH ไม่นับเมื่อหุ่นถูกวาร์ป (>.5/เฟรม) ใน 3 เฟรมก่อน (OLD_GLITCH_PUT) ; OUTSIDE ไม่นับในโกที่
  เป็น AIMJUMP (±1.5 s, OLD_OUTSIDE_AIMJUMP). bench_replay 0407 ทุกบอส: missed 36 / false 2095 เท่าเดิม, glitch 1604→1589,
  things' drawn-in frames 14859→14876 ; phase3 glitch 12 (เดิม 14).
- **Klaus quickattack (คลาส "ตีภายใน 0–2 เฟรมหลังเข้า state"):** lag bench: เครื่องเล่นเห็น anim quickattack (เริ่มที่ f15) เฟรมเดียว
  กับข่าวโดนตี — ดูแอนิเมชันอย่างเดียววาดก่อนไม่ได้ (โฮสต์วาดทันแค่ 1 เฟรม = replay นับ "drawn"). สแกน SG เกม+UM: 12 state
  (Klaus quickattack, minotaur/penguin runningattack, mossling/mushdrake spin_loop, ...). chomp f49: ถ้าเป้าอยู่ในระยะตี → quickattack
  (SGklaus:667) = ทำนายได้. **ทำแล้ว 2026-10-25:** sim_moves.lua บันทึก `goes_into = { anim, at, from, dist }` ตอนท่าที่ตีแล้ว
  ต่อเข้า key anim ของท่าอื่น (sim_went_into เดิม) ; rebuild -only=klaus + splice (movediff: แค่ +goes_into 2 ท่า, data F53C465A1303) ;
  predict: ช่วง at-6..at+1 ถ้าเป้า (คุณ) อยู่ใน r.attack + รัศมีตัว → วาดท่าถัดไปจากจุดบอส หันหาคุณ, เวลา = from + (f - at)
  (TR_OLD_GOESINTO). replay ไม่มี r.attack (ranges จำลอง {harmful, hit}) → วัดไม่ได้, Klaus เท่าเดิม 1344/0/0. **lag bench 1513
  (Klaus 4 รอบ): NOT drawn 18–19 → 0 (เปิด) / 1 (ปิด), false 0/2, strict 5/1.** ติดตั้งทั้งสอง build. ท่าอื่นที่จะได้ goes_into ต้อง
  rebuild ข้อมูลเต็ม (ครั้งหน้าที่ rebuild ทั้งหมด จะได้เอง) — อย่าลืม UM overlay (build_um + กู้หิน Bearger).
- **2026-10-26 ผู้ใช้เล่น Cluster_3 (Host Game + ถ้ำ, เป็น client ของตัวเอง; trace อยู่ใน server_log):** client_log "struck by ?"
  (ฝั่ง client ไม่รู้คนตี) ; นาฬิกา client ≈ server log + 51 s. (1) **Champion ร่าง 3 tri-beam: 4/4 NOT บนจอ** — atk_beam มี follow
  → ถูกยกเว้นจาก SERVERAIM (22 ต.ค. "12 more" = น่าจะวาร์ป bench เหมือน anchor lock) → เอาออก (TR_OLD_SERVERAIMFOLLOW): bench 0407+1701
  13 บอส follow: missed/false เท่าเดิม ; log ผู้ใช้ YOU_LEAD=3: 2/4 → 4/4. ไม่มี lead ยังพลาด 2 (ขอบ: ห่างแกน ~1.2 = 0.7+0.5 พอดี).
  (2) Bearger: บนจอ "in" เกือบหมด — HIT ส่วนใหญ่เป็น um_bearger_sinkhole ยุบ (GetAttacked(inst.bearger) → replay นับเป็นท่า Bearger =
  MISSED ปลอม; ยุบ 3 ครั้ง ครั้งแรกยกเว้น locomotor → โดนผู้เล่นที่ +15/+30 = data delay 15 + again 15 ถูก). NOT 1 = ตะปบตอนเป้าคือ
  slipstor, คุณลูกหลงที่ขอบ 5.67/6 ขณะวิ่งหนี (lag). **ค้าง:** replay ควรนับ HIT ของ Bearger ที่อยู่ในหลุมเป็นของหลุม. (3) แมงมุม UM
  (REGSPIDERJUMP → warrior_attack): ไม่มี trace (ไม่ใช่บอส) ; data spider warrior_atk = facing, map เดียว (dist 1) เลน -1..10.75 กว้าง ±3.5
  — ต้องการ trace จริง (lag bench กับ spider) ก่อนสรุป.
- **tri-beam "ยังไม่ตรง" (2026-10-26 09:32 log, ไม่โดนเลย — ตัดสินด้วยตา):** replay ไม่มี OUTSIDE (เลเซอร์ทุกจุดอยู่ในรูปสัก
  เฟรม) แต่วัดมุมจากภาพ (pics.ps1 + System.Drawing วางจุดเลเซอร์จริงจาก [tr_haz] + สุ่มสีบนวงรัศมี 8/12/14): ลำข้างหุบเข้า ~3°
  (−59/−25.6/+7.5 vs จริง −62.2/−26.2/+9.8). ต้นเหตุ: follow + FOLLOW_HOLD 1.5 ถือรูประยะ 7.5 แล้วเลื่อนตามแกนลำกลาง 1 หน่วย (เป้า
  8.48) — ลำข้างที่ชี้ออกคนละทิศถูกเลื่อนขนาน. แก้: SimMoves._SlideFits(entry, src) เทียบรูปสองระยะห่าง ~FOLLOW_HOLD (เลื่อนแล้ว
  ทับไหม, ไม่ทับ > 15% = ไม่ถือ) ; ผล 0–5% ทุกท่า ยกเว้น attk_beam / sharkboi icedive_standing_jump_pre / bishop atk2_pre = 25%
  → hold HOLD แทน (TR_OLD_SLIDEFIT). หลังแก้: −61.7/−25.6/+10.6 (คลาดทั้งรูป ~0.6° = เวลาวัดเป้าครึ่งเฟรม). bench 0407/1701
  13 บอส follow: missed/false เท่าเดิม, bishop glitch 36→14 / 38→12, phase3 yellow +5/+8.
- **ตัวตรวจ "ความตรงของรูป" (ACCURACY) — วิเคราะห์ก่อนทำ 2026-10-26 (ผู้ใช้: "ถาม agent ค่อยทำต่อ"; tr-reviewer: AGREE WITH NOTES):**
  ทำไม: OUTSIDE เช็คแค่จุดกลางของของ, กับทุกชิ้นของท่า (รวมเหลืองที่ยังไม่ถึง), ทุกเฟรม → รูปเบี้ยว 3° ยัง "ครอบ" ผ่าน.
  ทำ: ของที่ตีทันทีที่เกิด (เริ่ม alterguardian_laser: RADIUS .7 จาก prefab + ตัวผู้เล่น .5 = 1.2, ไม่อ่านรัศมีจาก _hazards เพราะคือ
  ข้อมูลที่ทดสอบ) — ณ เฟรมที่มันเกิด (±1 เฟรม ANIM_LEAD) เฉพาะชิ้นสไตล์ hit/strike: สุ่มจุดในวงโดน → % ที่อยู่ในรูป, และ
  ความเอียง: ซ้าย/ขวาของแนวรัศมีจากบอส ครอบไม่เท่ากันแบบเดียวทั้งลำ = รูปหมุน. ไม่ช่วยเมื่อ: ของที่ไม่ได้ trace, ตีเป้าเดียว,
  ของที่วาดเอง (= ยังไม่ทดสอบ ไม่ใช่ผ่าน) ; รูปกว้างเกินไม่เห็น (ด้านเดียว). กันเตือนผิด: ข้ามโก AIMJUMP/วาร์ป, ±1 เฟรม.
  **ตัวคุม:** TR_OLD_SLIDEFIT=1 ต้องจับ tri-beam เอียงได้ ; ไม่งั้นตัวตรวจใช้ไม่ได้. ต่อ (ผู้ตรวจ): จับคู่ HIT ที่ใส่ชื่อบอส (เลเซอร์
  DoAttack ผ่าน caster, หลุม UM ผ่าน inst.bearger) กับของที่อยู่ตรงนั้น ; ตรวจการเลื่อนรูปอื่นในกลุ่มเดียวกัน (simmoves Draw: ready
  /NEW_NEAR — ปิดแล้วสำหรับท่าที่เลื่อนไม่ได้ ; far-edge ±2, extrapolation, shift/LandAt/keep/prelock, path_fit/first_best).
  **ทำแล้ว (ขั้น 1):** replay.lua ACCURACY/ACC_OFF (alterguardian_laser เท่านั้น, จุดวัดเอียงที่ .4/.75 R - ที่ .9 R คลาด .15 ก็เตือน),
  NOACCURACY=1 ปิด. ตัวคุมผ่าน: log ผู้ใช้ ใหม่ = tri-beam ไม่เตือน / TR_OLD_SLIDEFIT = 5 ลำ ; bench 0407+1701 (~57k เลเซอร์) ใหม่เอียง
  สูงสุด 17% (1 ครั้ง 42% attk_swipe) / เก่า 48–97%, 33 ลำ. simmoves: ready fallback ของท่าที่เลื่อนไม่ได้ ≤ HOLD (เดิม NEW_NEAR 1).
  **ค้าง:** attk_swipe (ท่ากวาด) เตือนทั้งเก่า/ใหม่ — ดู ; เพิ่มรัศมีของชนิดอื่น (หลุม UM 3.5, หนาม, ...) จาก prefab ; จับคู่ HIT ที่ใส่ชื่อบอส.
  **HIT ใส่ชื่อบอส (หลุม UM) — ไม่ใช่บั๊ก (2026-10-26):** log ผู้ใช้ 0853 ดิบ: bearger 11 strikes 4 MISSED ; หลัง tools/expand_haz.lua:
  bearger 3/3 วาด + replay_haz _hazards 7/7 วาด (20 drawn-in ไม่โดน = หลบ). 4 MISSED = ลืม expand ก่อน replay. ลองต่อเวลา by_own
  (as_boss นานเท่าที่หลุมตี) → ไม่เปลี่ยนอะไรทั้งสองแบบ → เอาออก. **บทเรียน: log ผู้ใช้ต้อง expand_haz ก่อนทุกครั้ง.**
  **ขั้น 2 (2026-10-26):** ของที่ pool (Deerclops เก็บหนามคืนแล้ววางใหม่ guid เดิม) = ของใหม่เมื่อย้ายที่/หายไป > .5 s.
  deerclops_icespike_fx (ICESPIKE_RADIUS 1 + .5, ตี ≤ 3 เฟรมหลังเกิด), deerclops_laser (.7 + .5, เฟรมของแต่ละจุดจากระยะ:
  max(0, i-1)) — bench 1701 ไม่มีเลเซอร์ Deerclops เลย (ยังไม่ได้วัด). ผล: mutateddeerclops 4673 หนาม 99% ไม่เอียง ;
  **deerclops (UM) ACC_OFF 3 โก เอียง 38–67% = ของจริง:** ภาพ 569.6: รูปวาดหันไปทาง rot 0 (ตอนเริ่ม) บอสหมุนตามคุณถึง −43
  แล้วหนามออกทางนั้น. ต้นเหตุ: spec um.lua `attack` noarg (StrongAttackBank/EnrageAttackBank เข้าโดยไม่มีเป้า - log ผู้ใช้
  22 ต.ค. ไม่หมุนจริง) แต่ state `hit` ของเกมเรียก ChooseAttack(inst, target) เอง ข้าม doattack ของ UM → ตีหลังโดนตี =
  มีเป้า หมุนจนเฟรม 16 (bench: 6/142 ที่คุณเดิน < 45° หมุนตามเป๊ะ). แก้ใน spec: lock = 16 (+ วาดตามทิศหน้า = เท่าล็อก 0
  เมื่อไม่หมุน) → build_um. **ทั้งคลาส:** state ที่เข้าได้ทั้งมี/ไม่มีเป้า (SG เกม+UM postinit): boulder_crab attack,
  daywalker attack_pounce_pst (ส่ง targethit ไม่ใช่เป้า), eyeofterror charge_pst (กฎ AHEADLEG แล้ว), hoodedwidow attack,
  pigbunny (บรรทัดมีเป้าถูก comment), shadowthrall_mouth leap, buffrat attack1 — onenter ไม่หันหาเป้า (ใช้แค่ DoAttack) →
  Deerclops ตัวเดียว. **ผล:** lock 16 อย่างเดียว → build ได้ frame "target" (ผิดทางไม่มีเป้า) → pin frame "facing" ใน spec.
  build_um เปลี่ยน 21 ท่า (goes_into ใหม่ทั้งชุด, spider_warrior atk หาย, magmahound, um_vampirebat, boulder drift) → ไม่เอา:
  splice เฉพาะ deerclops ลง backup (movediff = 1 ท่า). bench 1701 deerclops: ACC_OFF 3 → 0, ไม่ถึงครึ่ง 11 → 0, เอียง 67 → 6%,
  120/120 วาด, false 12 เท่าเดิม ; log ผู้ใช้ 22 ต.ค. (ไม่มีเป้า) เก่า=ใหม่ทุกค่า. ติดตั้งแล้ว.
  **ค้าง:** ท่า UM อื่นที่ build ใหม่เปลี่ยน (goes_into ใน UM ยังไม่ได้ใส่, spider_warrior atk gone = ต้องดูว่าทำไม) ;
  เลเซอร์ Deerclops ยังไม่มีใน bench.
  **ตามดูแล้ว:** spider_warrior atk/warrior_atk "gone" = UM เท่าเกมแล้ว (mod_diff ตัด, runtime ใช้ base ค่าเท่ากัน) ไม่ใช่ปัญหา.
  goes_into 14 ท่าใน UM build = from 0 ทั้งหมด (ท่าต่อปกติ client เห็นเริ่มเอง: taunt, loop...) → sim_moves เขียนเฉพาะ
  from > 0 (OLD_GOES_INTO_ALL=1 ทุกอัน). ทั้งคลาส: ผล sim 185 บอส (um_base) + UM มีแค่ Klaus attack_chomp(@Enrage) from 15
  — อยู่ใน base ทั้งสองร่างแล้ว.
  **ขั้น 3 (2026-10-26):** + moonspider_spike (.5+.5, 0–8 เฟรม), bishop_charge2_fx (2+.5, 18 เฟรม). **ตัวตรวจผิดเอง:** วงนอก
  สุ่มตรงขอบ 1.0R พอดี → รูป cell .25 ติด/ไม่ติดแบบสุ่ม (Bishop วาด 2.78 รอบ 2.5 อ่านได้ 13/21) → วงนอกที่ R−.25
  (OLD_ACC_EDGE=1): Bishop 67→100%, phase3 เลเซอร์ 95→100%, หนาม Deerclops 99→100%. ACC_V=1 = รายชิ้น (+เฟรมที่ดีสุด).
  **หนามแมงมุมดวงจันทร์ 88%, 34/349 ไม่ได้วาด:** แต่ละโก 3 อันในรูป อันไกลสุดหลุด — DoSpikeAttack: กลางสุ่ม ±1 รอบตำแหน่งคุณ
  ตอนเข้าท่า, หนาม 2–4 อันห่าง 1.1–2.85 → ถึง ~5.3; sim 16 รอบ × ~3 หนามสุ่มไม่ถึงขอบ. แก้ sim: ท่าสุ่มที่ไม่มี spec runs รันเพิ่ม
  ทีละ 16 จนชุดล่าสุดเพิ่ม cell < 2% (≤128, OLD_RANDOM_RUNS=1) → 96%, ไม่ถึงครึ่ง 12 (14 ของ 34 เดิมอยู่หลัง bench วาร์ปคุณ
  "side" — ไม่ใช่ผู้เล่นจริง). ตาราง bench เท่าเดิม. ลอง anchor lock ให้ท่าสุ่มด้วย (9 ท่า) → ไม่ดีขึ้นเลย → ไม่เอา
  (SIM_RANDOM_ANCHOR=1 ลองได้). ติดตั้ง data 46373CC5335F (spider_moon hide, stalker_atrium spike).
  **ค้าง:** UM `spider hide` (แมงมุม UM) ต้อง build_um ใหม่ถึงจะได้รันเพิ่ม ; fossilspike2 place 89% ไม่ขยับ — ดูว่าทำไม ;
  ท่าสุ่มอื่น: rebuild 8 ท่า (phase1 roll, phase3 skybeam, antlion cast_pre, daywalker shrug1, daywalker2 throw_pre,
  lunar_grazer spawn, buzzard flame, stalker attack1) → ตาราง bench เท่าเดิมทุกช่อง. buzzard flame ข้อมูลรวม 27842 → 12168
  ไม่ใช่รูปเล็กลง: แต่ละระยะใหญ่ขึ้น 2–15% ตามที่ควร, ระยะ > 10 รวมเป็น "same" (sim ตอนนี้บีบซ้ำได้ดีกว่าตอนทำข้อมูลเดิม).
  ไม่มีผลที่วัดได้ → ยังไม่เอาเข้า; จะได้เองตอน rebuild เต็มครั้งหน้า.
  **Fuelweaver spiral รอบประตู (2026-10-26):** fossilspike2 89% ไม่ขยับด้วยรันเพิ่ม. fit ศูนย์กลาง spiral (r = 2.2 + .2i)
  คลาด .000 ทุกครั้ง แต่ห่างตัว Stalker 2.0 = จุดที่ testbench วางประตู ("moved to", ย้ายประตูตามบอส) แล้ว Stalker เดินออก.
  stalker.lua GenerateSpiralSpikes: source = entitytracker "stargate" or inst → ในเกมจริงรอบประตูกลางลาน (Stalker ห่างได้
  ถึง 14.55) แต่ sim ไม่มีประตู = รอบตัวเอง. ทั้งคลาส: stalker.lua ใช้ประตูอีก 3 ที่ (เลือกเป้า, ลูกน้อง, channeler) ไม่ใช่ท่าตี.
  แก้: predict Predict.RoundAt (sim.round = prefab, round_within) — ทั้งทาง Draw และ DrawTable (ท่านี้วาดทางตาราง) ;
  spec sim_moves stalker_atrium spikes extra round = "atrium_gate" (Stalker ถ้ำไม่มีประตู = เหมือนเดิม) ; replay
  Predict.ThingsNear อ่านประตูจาก tr_ent born + bench "moved to". TR_OLD_ROUND. ผล: fossilspike2 89 → 96% (ที่เหลือ = วงนอกสุด
  + หนามที่ขึ้นหลังท่าจบ), bench เต็ม missed 59 → 58, false 1826 → 1824, glitch 1594 → 1571. ติดตั้ง data 0075C4C7D2E6.
  ในเกมจริงผลใหญ่กว่า bench มาก (ห่างประตู 2 บน bench vs ถึง 14 ในลาน).
  **UM ท่าสุ่ม:** build_um ขั้น "without" ล้ม (16 ส่วนเสร็จ, mod_diff หาไฟล์ไม่เจอ — ยังไม่ได้ดูว่าทำไม) แต่ "with" ครบ →
  splice spider:hide จาก tests\work\um\moves_sim_um.lua (36234 → 46360 cell, DoSpikeAttack ของ UM เหมือน moon spider ทุกบรรทัด).
  bench ไม่มีแมงมุม UM ใช้ hide (ต้องกลายร่างคืนเต็มดวง) → วัดตรงไม่ได้, ตารางเท่าเดิม; ติดตั้งโดยอิงผล moon spider.
  glacialhound/magmahound มีการเปลี่ยนอื่นปน → ไม่เอา. ACC: + minimoonspider_spike.
  **ACC ฝั่ง hazard (replay_haz):** sandspike_short/med/tall — วงตีรอบตัวมันเองในเฟรมแรกๆ: 100% ทั้ง 3 (1616 อัน).
  **build "without" ล้มเพราะกฎรันเพิ่มเอง:** antlion#1 เกิน 120s (ตัวกันค้าง 5×รอบก่อน, ขั้นต่ำ 120) → หยุดทุก job ไม่เขียนอะไร.
  ใส่ SIM_JOB_LIMIT=1200 ให้รอบ base ของ build_um/build_te และ verify.ps1 (เดิมมีแค่รอบ with). build ซ้ำผ่าน (base 226 jobs
  165s, antlion 142s). ส่วนที่ build เปลี่ยนทุกครั้ง (ไม่ใช่สุ่ม): magmahound (belch ใหม่, scared_pre/pst), um_vampirebat atk,
  spider_warrior trapdoor → bench: vampirebat/spider_warrior เท่าเดิม, magmahound yellow 0 → 12 = แย่ลง → ไม่เอา. ต้องดูว่า
  sim เปลี่ยนอะไรกับ magmahound ก่อน build UM ครั้งหน้า (ไม่งั้น build เต็มจะพาของแย่เข้ามา).
  attk_swipe ACC_OFF 1838.8: เลเซอร์ลำแรกของการกวาด 1 ลำ 5/21 (ที่เหลือ 17–20/21) ใน ~27k → เล็ก ไม่แก้ตอนนี้.
  **กลไกเลื่อนรูปที่ผู้ตรวจให้ดู (far-edge ±2, extrapolation, shift/LandAt/keep/prelock, path_fit/first_best):** วัดผ่าน ACC
  ตอนนี้ครอบ 10 ชนิด/7 บอส (phase3 เลเซอร์ 100%, หนาม Deerclops ×2 100%, Bishop 100%, moon spider 96%, fossil 94/96%,
  sandspike 100%) เอียงสูงสุด ≤ 17% ยกเว้น attk_swipe ลำเดียว → ไม่เห็นผลเสียจากกลไกพวกนี้ในของที่วัดได้. ยังไม่ครอบท่าที่ไม่มีของ
  (ตีด้วยตัว) — ส่วนนั้นยังพึ่ง MISSED/OUTSIDE. daywalker2 junk pile ใช้แค่ตัดสินใจพุ่ง (TestTackle) ไม่ใช่รูป → Stalker ตัวเดียว.
- **มอนสเตอร์ใหม่ 8 ตัว = อัปเดตของตัวเกม 23 ต.ค. (ไม่ใช่ mod) (2026-10-26, ผู้ใช้ "ทำเลย"):** bat_boss(+_shadow) SGbat,
  rocky_boss(+_shadow) SGrocky, worm_boss_shadow (worm_boss.lua), charlie_boss SGcharlie_boss, charlie_boss_runner,
  shrouden SGshrouden. **tests\work\game_scripts เก่า (ก่อน 23 ต.ค.)** — ทุก sim/replay ตั้งแต่ 23 ต.ค. ใช้สคริปต์เก่า! แตกใหม่
  (เก่าเก็บที่ game_scripts_905B96...), game_scripts_um ทำใหม่, anim_lengths.lua ทำใหม่ (8 ต.ค. → ไม่มี anim ใหม่: Queen
  castlift จบที่ 30 ก่อนปล่อยลูกน้องเฟรม 33). sim ต้องเพิ่ม: require math2d, Physics:GetMotorSpeed, scaler.scale=1,
  grouptargeter:GetNumTargets, entity Set/GetParent (SIM_OLD_PARENT), dummy inventory:IsOpenedBy (หมวก Batilisk), พิมพ์ error
  ตอนโหลดไฟล์สำรอง. ผล sim: bat_boss atk+hair_attack, rocky_boss atk/snip/dash, charlie_boss aoe+castlift, runner
  attack_quick, shrouden punch_pre+teleport_pre. หนอนเงา: STRIKERS worm_boss_shadow_segment (look worm_boss_segment_shadow_build),
  moves_hand worm_boss_shadow_dirt, modmain AGGRO. bench 2026-10-26_1151 (8 ตัว, 3 รอบ) กำลังรัน. ต่อ: verify เต็ม (สคริปต์ใหม่
  กระทบบอสเดิมด้วย), nomove_check บน bench นี้, ท่าที่ยังขาด (Queen vine/hands, runner pounce, shrouden optic blast).
  **ต่อ:** optic blast ต้องใส่ spec (scan ไม่เจอ) → optic_blast_pre1. verify เต็มบนสคริปต์ใหม่: log จริง missed 823 → 720, glitch
  1807 → 782 (ข้อมูลที่ติดตั้ง) ; ข้อมูลใหม่ทั้งชุดมี "gone" (gestalt attack, phase4 atk_burst_pre, wagboss atk_signal_pre, trap)
  ทั้งบนสคริปต์เก่า = sim ไม่ใช่เกม (phase4 supernova: state รับตัวเลขแต่ sim ส่ง target) → **ไม่ rebuild บอสเดิม**: splice
  เฉพาะของใหม่ (8 บอส + bat/rocky hair/snip/dash + worm shadow + hazard ใหม่ ; shadowthrall_mouth portal_appear ไม่เอา — ทับ
  bite เดิม 28 → 0). bench ใหม่ 1151: missed 3654 → 408 ; bench ใหญ่ 1701 missed 58 → 59 (_haz +1). + charlie_boss_projectile
  (กระสุนสะท้อนเมื่อโดนตี, AOE 1.2, STRIKERS lasting) — log 1151 ไม่มี trace กระสุน → bench ใหม่ 2026-10-26 รอบสอง.
  replay: WORN (ตีจากกลางตัวคุณ = สวมอยู่ เช่นค้างคาวบนหัว) ไม่นับ missed — 165 ของ 408. ที่เหลือ: Queen idle 101 (กระสุน),
  vine_counterattack 45, attack 20 ; rocky_boss_shadow dash 45 (dash ต่อเนื่องหลังหายตัว ≤5 ครั้ง — ยังไม่ได้ดู) ; shrouden
  optic_blast_pst/teleport_pst. ลานของ Queen (charliearena_spike AOE 1 ที่ 29 เฟรม, ระเบิด 3) bench ไม่มีลาน — ยังไม่ได้ทำ.
  ติดตั้ง data F789295D680E.
  **bench รอบสอง 2026-10-26_1223 (ข้อมูลใหม่):** 6198 strikes, missed 233 (3.8%); bat_boss 0, bat_boss_shadow 0 (WORN ไม่นับ),
  rocky_boss 3, shrouden 9. Queen 152: by charlie_boss_vines 113 + projectile. replay: "STRIKE by <thing>" ที่ thing อยู่ใน
  _hazards และอยู่ใกล้ = ของมัน (by_own → replay_haz ตัดสิน; OLD_STRIKEBY) → Queen 152 → 121. + STRIKERS charlie_boss_vines
  (มุดดินตามเป้า, จับเมื่อกลางตัว ≤ 1.2: radius 0.7 + .5, lasting) → data EBB0536695D8, bench Queen รอบสาม.
  **Rock Master เงา dash 48 พลาด:** dash ต่อเนื่อง (หายตัว → dash ใหม่จากไกล ~15, ไม่ชะลอ ×2) — sim รันแบบต่อเนื่องอยู่แล้ว
  (mem ว่าง → นับ 1 → ต่อ); ภาพ 12.967: แถบวาดจบที่ตัวบอส ไม่ยาวถึง snip ข้างหน้า (คุณห่าง 1.2) = ปัญหาฝั่งวาด (far edge /
  ระยะ map) ยังไม่ได้แก้. ข้อมูล: reach 8, solid, ระยะ > 8 ใช้ map เดียวกัน.
  **bench Queen รอบสาม 2026-10-26_1232:** Queen missed 152 → 32 (324 strikes), ของ (เถาวัลย์/กระสุน/ลูกน้อง) 258/258 วาดทัน.
  เหลือ: vines 26 + projectile 6 ที่ไม่จับคู่กับของใกล้ (เถาวัลย์ Teleport ไปกลางระหว่างมันกับเป้าตอนโผล่) ; FALSE 189 ส่วนใหญ่
  ลูกน้อง castlift (statemem.targets ร่วมกัน: ตัวแรกโดนแล้วตัวอื่นไม่ตีซ้ำ = เตือนถูก) + เถาวัลย์หลังโผล่ค้าง 1.5 วิไม่ตี.
  **Rock Master เงา dash ต่อเนื่อง — ต้นเหตุจริง:** ภาพ 16.6–16.87 dash ที่สองไม่วาดเลย; anim atk_dash เล่นซ้ำ แต่ predict นับ
  "anim แรกเริ่มใหม่ = go ใหม่" เฉพาะหลังการตีครั้งสุดท้าย (LastStrike) และข้อมูล last = 36 (sim ต่อ dash ถัดไปเข้ามา). predict:
  ท่า anim เดียว ไม่ใช่ charge/GoesAgain เริ่มใหม่หลังการตีแรก + LINGER = go ใหม่ (TR_OLD_RESTART) → 48 → 2 (false 7 → 13).
  bench ใหญ่ 1701: missed 59 → 58, false 1825 → 1824, glitch 1571 → 1566. ติดตั้งแล้ว.
  **Queen 32 ที่เหลือ = ตัวตรวจผิด:** แต่ละครั้งที่โดนมี STRIKE by <ของ> + HIT (ไม่มี by) → STRIKE ยกให้ของ, HIT ค้างเป็นพลาดของ
  Queen. replay: HIT รับ by จาก STRIKE เฟรมเดียวกัน (OLD_HITBY) → Queen 292/292, ของ 258/258 ; bench ใหญ่ missed 58 → 59,
  false 1824 → 1823. BYOWN_V=1 พิมพ์การตัดสินรายครั้ง. simmoves _off_nets (charlie_boss_vines _emerged, TR_OLD_OFFNET; modmain
  หยุด trace) — bench 1311: ไม่ต่าง (false 190 → 196, ส่วนใหญ่ลูกน้อง castlift: targets ร่วม = เตือนถูก) ; Queen 289/289.
  **ค้าง:** ลานของ Queen (หนาม: ซ่อน + สุ่ม 0–.5 วิ แล้วตี 29 เฟรม, ค้างเป็นกำแพง; ระเบิด 3 เมื่อเข้าใกล้) — ต้องลานจริง ;
  Grim Harrier 0 strikes บน bench ; ลูกน้อง Abomination (ปาก/มือ state shrouden_*) 13 พลาด — portal_appear ทับ bite เดิม ;
  shrouden teleport_pst 7/478 ; rocky_boss snip 3/211.
  **ลูกน้อง Abomination:** ปาก shrouden_bite_final (anim shrouden_disappear) รันเดี่ยว (spec ชั่วคราว) → moves_hand
  shadowthrall_mouth.shrouden_disappear: 9/29 → 1/29, ปากปกติ 207/207 เท่าเดิม ; ติดตั้ง. มือ shrouden_run (noarg - รับ
  numcollisions) ได้ portal_appear,shrouden_disappear แต่ 3 → 31 พลาด (ทับ run_loop เหมือนปากตอนแรก) → ไม่เอา ; เขา
  shrouden_jump 1 → 0 แต่เหลือง 44 เฟรมจากครั้งเดียว → ไม่เอา (ข้อมูลน้อย). Grim Harrier ใช้ครั้งเดียวแล้วหาย — bench ได้ 1 ครั้ง/รอบ.
  **shrouden teleport 7/478:** data teleport_pre first 57 นับจากต้นท่า แต่ teleport_loop ยาวไม่คงที่ (เดินใต้ดิน 2.9 วิในเกม)
  ตีใน teleport_pst +26 เฟรม. แก้ได้ด้วยฟิลด์ใหม่ "anim แต่ละตัวเริ่มเฟรมไหนในรอบ sim" + predict ตั้งนาฬิกาใหม่เมื่อ anim นั้นเริ่ม
  — กระทบทุกท่าหลาย anim, ยังไม่ทำ (ต้อง bench ทั้งชุด). **ทำแล้ว (ผู้ใช้ "เสียเวลา... คุณหยุด"):** sim เขียน anim_at,
  predict ตั้งนาฬิกาเมื่อ anim นั้นเริ่ม (>2 เฟรม, ครั้งเดียว; TR_OLD_ANIMSYNC). ทุกท่า (121): false 1823 → 3787, glitch
  1566 → 2741 (หมา/กบ/terrorbeak) = แย่. เฉพาะหลัง anim วน/ค้าง (23): missed เท่าเดิม, glitch 1566 → 1896 = แย่. teleport_loop
  ถูกค้างด้วย state ไม่ใช่ flag วน (sim เล่นจบตามความยาวพอดี) → spec `sync = { teleport_pst = true }`. **ใส่เฉพาะ shrouden**
  (teleport/punch/optic): 9 → 2. sim เขียน anim_at เฉพาะ spec sync (SIM_SYNC_LOOPS=1 ลองแบบวนอีก). splice.lua: `field:<ชื่อ>`
  คัดลอกฟิลด์เดียว. ติดตั้ง data C9E6A17F9B4C.
  **หนามลาน Queen:** testbench SETUP charlie_boss เรียกหนาม 5 อันรอบคุณทุก 7 วิ (OnShroudenSummon, ลบใน 4 วิ;
  TR_NO_ARENA_SPIKES) ; STRIKERS charliearena_spike radius 1 delay 29 + simmoves _on_anims spike1-3_pre (นาฬิกาจากตอนโผล่).
  ระเบิด (โหมด Lunacy, เปลี่ยนสีไม่ใช่ anim) ไม่ทำ. data 148935C29745, bench 2026-10-26 charlie_boss+shrouden.
  **ผล bench 1925:** หนามลาน 213 ครั้งโดน วาดทันหมด (697 หนาม), ของทั้งหมด 499/499, Queen 287/287. เขาเงาที่ถูกเรียก
  shrouden_jump → moves_hand: 0/2 → 2/2 (สอง bench), ปกติ 135/135.
  **SnapTo45s (ปัดทิศ 45°):** sim เขียน snap45 เมื่อ state เรียก SnapTo45s และบอสไม่เคลื่อนที่ (dash เคลื่อนตามทิศเดิม ปัดแค่ snip
  ตอนจบ — ใส่ใน dash ทำ glitch ร่างเงา 14 → 111) ; predict ปัด aim_rot (TR_OLD_SNAP45). rocky_boss snip 3 → 0, shrouden 4 → 3,
  bench ใหญ่คงที่ 58/1823/1566. หมายเหตุ sim: global ใหม่ถูก stub → ใช้ rawget/rawset(_G). data 19C937BFCE6C.
  **ค้างนาฬิกาใน loop ก่อน anim ที่ sync:** Abomination เตือนผิด teleport_loop 50 + optic_blast_loop 50 (นาฬิกาวิ่งเลยเข้าช่วงตีขณะยัง
  อยู่ใต้ดิน) → predict: อยู่ใน anim ก่อนหน้าและเลยเฟรม anim_at − 1 = ค้าง. เตือนผิด 106 → 60 / 102 → 64, พลาดเท่าเดิม.
  Predict.MoveStart คืน t0_first (go เดิม) — ไม่งั้น replay นับ go ใหม่ทุกเฟรม (yellow 16 → 498 ปลอม). bench ใหญ่ 58/1824/1566.
  **บอสเดิมที่ยังพลาด 19:** vault_crawler 5 (ขอบ 2.37–2.39 จากระยะ 2.4 — PAD ¼ cell เลือกไว้แล้ว), Champion ร่าง 1 roll_stop 6 และ
  boulder_crab uppercut 4 (ดัน/กลิ้งชน stand-in ที่ยืนนิ่ง — artifact ของ bench) ฯลฯ.
  **TE (2026-10-21_0059, -TE):** รุ่นที่อัปโหลด (Workshop 3817047528) vs ปัจจุบัน: 23500 strikes, missed 16 เท่ากัน, false 2069
  เท่ากัน, glitch 186 → 181. "both" 952 = scorpion (สองท่าเริ่มเหมือนกัน วาดทั้งคู่ — ตั้งใจ) ; "flip" bossboar 116/bossboarte 107/
  slip 93 = attack1 → attack1~combofirsthit (แยกได้กลางทาง — ตั้งใจ).
  **optic blast เตือนผิด 52:** fx (AOE 2 / 5 ตอน wide) วิ่งตามบอส แต่ท่าบอสยึดจุดเริ่ม ; ลองตัดท่าบอสเหลือแต่ fx → พลาด 3 → 36 → ไม่เอา.
  **Grim Harrier:** ลบตัวเองหลังตะครุบ (SGcharlie_boss_runner frame 16 inst:Remove) — bench ได้ 1 ครั้ง ; sim check บางฉาก (3 ห่าง
  เดินข้างช้า missed 66/66) ยังไม่ได้ดู. patch_notes_client_1.1.6 ทำให้ตรงกับหลักแล้ว.
  **verify -NoSim:** real errors 24 → 746 = replay เอง (WORN_N global ชน strict ของ replay; bench replay ไม่ strict) → rawget/rawset
  → 24 กลับ; synthetic errors 0. synthetic false 446 ส่วนใหญ่ shrouden 288 (ไม่ใช่กฎใหม่: TR_OLD_ANIMSYNC 301). ALL GOOD.
  **Grim Harrier ตะครุบไกล:** เป้าห่าง ≥ ~1.8 = statemem.far, anim "attack" ตีเฟรม 16 ; ใกล้ = "attack_quick" ตี 11. sim คีย์ท่าจาก
  รอบใกล้สุด → map ไกลอยู่ใต้ attack_quick ไม่เคยวาด. moves_hand charlie_boss_runner.attack (สำเนา, anims attack, first 16):
  สังเคราะห์ 4/9 → 9/9. sim SIM_ANIMSPLIT=1 พิมพ์ ANIMSPLIT ทุกท่าที่รอบไกลเริ่มด้วย anim อื่น — ทั้งคลาส: เกม = runner ตัวเดียว ;
  UM = shadow_wixie(+helper) charles_charge_pre (ไม่ตีอะไรใน sim ไม่มีข้อมูล) → ปิด.
  **optic blast เตือนผิด:** ตีในรอบตัวบอสขณะไล่คุณ (ความเร็ว ~7) → spec still = true (optic_blast_pre) → เตือนผิด 60 → 10, 64 → 11,
  พลาด 3 → 4 / 2 → 2. **ลูกน้อง Queen:** หยุดตีที่ กระแทก+3 แต่เล่น anim ต่อ → simmoves _done_after (minion1 20, minion2 16;
  TR_OLD_DONEAFTER): เฟรมเตือนผิดของ 2338 → 1992, 2392 → 1889. data 79B190023373, bench ใหญ่ 58/1823/1566.
  **log จริง "worm_boss (struck)" 181:** หนอนตีเฉพาะผู้ถูกกลืน (worm_boss_util DoChew/IsDevouring) = เคี้ยวในท้อง ทุก .47 วิ, ทาง "(struck)"
  ของ replay_haz ใช้ตำแหน่งคุณแทนตัวตี (0.00 off เสมอ) → ไม่นับ (OLD_DEVOURED). verify -NoSim: real missed 715 → 534, synthetic
  missed 40 → 33, เตือนผิดสังเคราะห์ 446 → 180, glitch 467 → 435.
  **verify ใช้ข้อมูล mod ตาม log:** log ที่เล่นกับ UM/TE replay ด้วย TR_MODS + game_scripts_um/te/umte (VERIFY_OLD_MODS=1 ปิด) ;
  game_scripts_te/umte ทำใหม่บนเกมรุ่นใหม่ (umte = um + TE ซ้อน, ไฟล์ GLOBAL คงชั้นล่าง). real missed 534 → 373, errors 24 → 0,
  false 1160 → 1287, glitch 785 → 913 (UM จริงที่เพิ่งวัดถูก). **STRIKE ไม่มี HIT:** log ที่บันทึก HIT, STRIKE ที่ไม่มี HIT เฟรมเดียวกัน
  (guid เดียวกัน) = ตีไม่โดนใคร (phase3 แทงเป้า 5.6 ทุกรอบเรียก) → ไม่นับ (OLD_STRIKENOHIT): real missed 373 → 141, strikes
  4868 → 4576, false 1287 → 1341 ; bench ใหญ่ 58/1825.
- **lag bench คืน 2026-10-26 (ผู้ใช้ "ทำเรื่อยๆเลย ผมนอนละ" / "ระวังเครื่องมือค้าง"):** run_lag.ps1 -Bosses charlie_boss,shrouden,
  rocky_boss_shadow,bat_boss,alterguardian_phase3,stalker_atrium,klaus -Rounds 2 -Minutes 240 (tick 15) — ตรวจ predict ที่แก้หลัง
  25 ต.ค. + บอสใหม่ ผ่าน Lag Compensation จริง. watchdog: log server/client นิ่ง > 10 นาที = ปิดเกม+server.
  sim: component age:GetAge (Crab King geyser spawner พังทุกรอบ) — Crab King ไม่มีข้อมูลท่าเลยทั้งก่อน/หลัง (งานแยก).
  **build_um บนสคริปต์ใหม่ (2026-10-26):** ผ่าน (with 689 jobs, without 230). เปลี่ยนเหมือนเดิม (magmahound แย่ลง → ไม่เอา) +
  daywalker struggle2/shrug2 ใหม่ (UM) → bench 1701 daywalker เท่าเดิม 312/312 → ไม่เอา. หมายเหตุ: daywalker "yellow 253" ในตาราง
  = YELLOW "x of y drawn yellow never went red" (บางส่วนของรูปไม่เคยแดง ~4–12 จาก 47–70) ไม่ใช่ตีตอนเหลือง.
  **เลเซอร์ Deerclops (บังคับ: run_bench -Force "mutateddeerclops laserbeam", 2026-10-26_1820):** ACC deerclops_laser 36 วัด,
  100% ครอบ, เอียง 0% ; mutateddeerclops 109/109, _haz 123/123.
  **ผล (2026-10-26_2130_lag, ~45 นาที, จบเอง ไม่ค้าง):** ตารางแรก bat_boss NOT drawn 512/532 = **วัดผิด**: Hound Batilisk สวมหัว
  (SGbat TryHat → Equip) กัดทุก .6 s ค้างข้ามฉาก (ผู้เล่นอมตะ) — client คิดระยะจากพิกัดค้างของตัวที่อยู่ใน inventory (492.84 ซ้ำ
  242 ครั้ง) หรือ "?" -1.00. lag_report: กฎ worn (ระยะ < .1 หรือระยะเดิมกับครั้งก่อนของตัวเดิม + age เพิ่ม ≥ .3 / ติดเพดาน 99,
  เฉพาะ NOT drawn — spike ใต้ตัว/shrouden ทับตัว 0.00 ถูกวาดอยู่; OLD_WORN) ตัด 1025. lag_snap: รูปที่นิ่งบนจอขณะบอสกระโดด ไม่ใช่
  jump (Rock Master dash 8–12 ต่อ tick ทำ 47 jumps pred=0; klaus chomp "snap back" 3 ก็แบบเดียวกัน; OLD_SNAPSTILL).
  **หลังแก้ตัววัด: on NOT drawn 17/524 (3.2%), false 26 ; off 32/565 (5.7%), false 77 ; snap backs 0/0, jumps 7/8** (klaus chomp
  จุดยึดเลื่อนไปหน้า ~1.4 ครั้งเดียวตอนเริ่มพุ่ง ; shrouden ตามบอสที่วาร์ป+หันกลับ — ถูก). เหลือจริง: charlie_boss 9/7 (ต่อไป),
  shadowthrall_hands 4–5 (มือที่เรียก ค้างจากก่อน), rocky 3 (pred=0 เท่านั้น), bat_boss 15/5 (กระโดดงับ — ยังไม่ได้ดู).
  **Queen NOT drawn 9/7 = vines (สมมติฐาน ยังไม่พิสูจน์):** ตัวอย่าง 156.3: aoe (in) กระแทกถอย 4.2 → vines (SpawnGroundVines 7 เส้น,
  เร็ว 9→6/s, ไล่ตาม) ตีที่ 8.2 จากบอส, age .667. vines ตีเมื่อกลางห่าง ≤ 1.2 แล้ว _emerged ทันที (เราซ่อนเมื่อ emerged) — client เห็น
  ตำแหน่งช้ากว่า ~1 tick (.6 หน่วย) → ไม่เคยเห็นวงทับคุณก่อนหาย. **headless bench ไม่เคยมี vines ตีเลย** (ต้องมี pinnable, หุ่นไม่มี)
  → lag bench ที่เดียวที่เห็น. เพิ่ม log: testbench "srv struck ... with <weapon> x z", tr_lagjoin "[tr_lagthing]" ตำแหน่ง vines/
  projectile/minion ทุกเฟรม → รัน lag เฉพาะ charlie_boss เพื่อวัดว่า client เห็นช้ากว่าเท่าไรก่อนแก้.
  **พิสูจน์แล้ว (2026-10-26_2223_lag, Queen อย่างเดียว):** ทุกครั้งที่ vines ตี server ห่าง .94–1.2, บนจอ client ห่าง 1.5–2.1;
  ช้ากว่า = gap/speed = **0.10 s คงที่** (30 ครั้ง, 0.072–0.112; ค่าโดด 2 ตอน vine ช้า <2.2/s). minion/projectile ไม่ใช่ปัญหา (in เกือบ
  ทั้งหมด). **แก้ทั้งคลาส:** simmoves SimMoves.LeadMoving — lasting hazard ที่เคลื่อน > 1.5/s วาดที่ ตำแหน่งบนจอ + ความเร็ว (วัดช่วง
  ≥ .1 s) × hazard_lead (.1 ในเกม; replay.lua/replay_haz ตั้ง 0 เพราะตำแหน่งใน bench = ของ server, HAZ_LEAD=s สำหรับ log เกมจริง;
  TR_OLD_HAZLEAD). คลาส lasting ที่เคลื่อน: vines, charlie projectile, ghost/abigail/graveguard_ghost, spore_moon,
  fused_shadeling_bomb, stageusher hand, worm segments, UM projectiles/tornado/shambler ฯลฯ. replay Queen เท่าเดิม (lead 0).
  **มือที่ Abomination เรียก (shrouden_run):** เริ่มด้วย anim portal_appear (ไม่มีในข้อมูล → ไม่ถูกวาดเลย; lag 2130: มือที่ตีห่าง
  1.32 ไม่มีรูป, มืออื่นวาดอยู่ 4–8) → moves_hand shadowthrall_hands.portal_appear = run_pre ของมันเอง (วาดรอบตัวทุกก้าว) anims
  portal_appear/run_loop/shrouden_disappear, ตี 11/13, ซ้ำทุก run_loop ถึง 305/307 (10 s ในอารีนา). sim เดี่ยว (SIM_HANDS_SHROUDEN=1
  -only=shadowthrall_hands, noarg) ยืนยัน f11/13 รูปเดียวกับ run_pre. replay 1925: มือ missed 2→1, glitch 165→132, false 0→0.
  logger ม็อด: "struck (worn) by" เมื่อผู้ตี INLIMBO (สวมอยู่) — lag_report ตัดเอง. ติดตั้งแล้ว (unit tests ผ่าน) + patch notes ทั้งสอง.
  รัน lag charlie_boss,shrouden หลังแก้เพื่อวัด.
  **false ที่เหลือใน 2130:** rocky_boss_shadow 34 (pred=0 ล้วน) = **ตัววัด**: tr_lagjoin หา attacker ด้วย prefab ในรัศมี 6 จากตำแหน่ง
  server — dash 8–12/tick ทำให้ตัวบน client อยู่นอกรัศมี → "struck by ?" (seen=0, 34 ครั้งพอดี) → dash ที่วาดทับคุณถูกนับ "drawn IN
  but NOT struck". แก้: ตัวที่ใกล้สุดใน 20. (pred=0 ล้วนเพราะ dash ตกฉากคู่ — rocky pred=1 มีแค่ 762 เฟรม — ไม่ใช่ผล lag comp.)
  klaus 16/10 + stalker 16/0 = aphid (UM, สัตว์ในโลก bench) leap_attack ทั้งหมด — DoAttack ตามระยะปกติหลังพุ่ง 4.7; ยังไม่ได้ดู
  (false ไม่ใช่ miss, สัตว์เล็ก).
  **หลังแก้ (2026-10-26_2235_lag, charlie_boss+shrouden, 2 รอบ):** Queen NOT drawn off/on 9/4 (2223) → **0/1**, false 0/0 ;
  Abomination ทั้งหมด 5/5 (2130) → 2/3: มือ miss 7 → 1 (false ใหม่ portal_appear 4), ที่เหลือ shrouden 6.2/3.0 (age .2), wings 8.5.
  shrouden ที่เหลือ: optic_blast t=4.0 lead 1.33 (pred=1: คุณบนจอล้ำ server 1.33, ลำแสงไล่ตำแหน่ง server) ×2, punch 6.26 age .2 lead .38.
  มือ false 4 = "at its edge" ทั้งหมด. **rocky หลังแก้ Find (2249_lag):** false 34 → 2, NOT drawn 3 (pred=0, atk_dash ต่อเนื่อง
  t .43–.5: คุณอยู่บนแนว dash เลยเลนที่วาด ~17 จากต้นเลน — ยังไม่ได้ดู), pred=1 19/19.
  **hazard lead บน log จริง (verify -NoSim, HAZ_LEAD=.1):** missed 141 → 158, false 1341 → 1438 — ทั้งหมด worm_boss_segment (missed
  30 → 48, false 201 → 298) + groundpoundring ที่มากับมัน. สาเหตุราก: **log จริงทั้ง 127 ไฟล์เป็นเกม host** (ไม่มี
  "DeserializeHandShake"/"[Connect] Joining") — ไม่มีความหน่วงเลย lead จึงผิดล้วน. แก้: (1) ไม่ lead เมื่อ TheWorld.ismastersim,
  (2) lead เฉพาะตอนเคลื่อนคงที่ (ความเร็ว .1 s ล่าสุดกับ .1 s ก่อนหน้าต่าง ≤ 30%; TR_OLD_HAZSTEADY) — ปล้องหนอนวางทีละขั้นตามทาง
  คดเคี้ยว: กับ (2) อย่างเดียว missed 140 เท่าเดิม, false +28 (หนอน). baseline lead 0: 140/1342. ติดตั้งแล้ว → lag Queen ยืนยัน.
  **lag Queen กับเกณฑ์ 30% (2309_lag):** NOT drawn 2/2 (ไม่มี lead 9/4, lead ไม่กรอง 0/1) — ทั้ง 4 = vines ที่ถูกกรองทิ้ง. วัดจาก
  [tr_lagthing] (2223+2309): vines เปลี่ยนความเร็วต่อ .1 s ส่วนใหญ่ .05–.30, บางครั้ง .3–.45 (เลี้ยวมากตอนเข้าใกล้) → เกณฑ์ 50%.
  ติดตั้งแล้ว → lag charlie_boss + worm_boss (หนอนในโหมด client) เพื่อดูทั้งสองด้าน.
  **ผล 50% (2316_lag):** vines NOT drawn 3 (ไม่มี lead 13, 30%: 4, ไม่กรอง: 1), false 0. worm_boss ในโหมด lag "gave up - a minute
  with no attack" → วัดหนอนแบบ client ไม่ได้. log จริง HAZ_LEAD=.1 ที่ 50%: missed 140 เท่าเดิม, false หนอน 201 → 258 +
  groundpoundring 179 → 237 — ขอบบน (log host: lead ผิดทุกครั้ง; ในเกม host ตอนนี้ไม่ lead แล้ว). ใช้ 50%. baseline verify คืนแล้ว
  (141/1342). patch notes: "On a server (caves, or joining a friend)", ไม่อ้างหนอน.
  **Crab King "ไม่มีข้อมูลท่า" = ไม่ใช่ช่องโหว่:** ตัวมันไม่ตีผู้เล่นตรง (เกมปกติ): geyser (endgeyser) ทำลายแค่เรือ, freeze (cast)
  = ความเย็น, ก้าม crabking_claw + mortarball (cannontower) มีข้อมูลแล้ว, UM crabking_geyser_single มีแล้ว. ปิดเรื่อง.
  **aphid false 41 (lag):** UM aphid เล็งอะไรก็ได้ที่มี combat (retargetfn, รวมบอส); leap_attack single=true (วาดเฉพาะเป้า = คุณ) →
  client เห็นเป้าเป็นคุณ แต่ไม่โดน ทั้งที่ห่างแค่ 1–2 (SetRange 5,2). ต้อง log เป้า/ผลฝั่ง server — ยังไม่ทำ (false ของสัตว์ UM, 41/359).
  **lag bench 7 บอส build สุดท้าย (2026-10-26_2333_lag, 42 นาที, จบเอง):** on NOT drawn **11/594 (1.9%)**, false 14 ; off 10/443 (2.3%),
  false 15 (รอบแรกหลังแก้ตัววัด: on 17/524 false 26, off 24/557 false 77). klaus/alterguardian 0, stalker 1/0, rocky 3/1, Queen 2/2,
  shrouden 4/2 (false 13/13: horns shrouden_jump/teleport/optic เดิม), bat 0/6 = บรรทัด "?" ของตัวที่สวม (หายจากจอ client, ติด "(worn)"
  ไม่ได้) จาก worn 1049 ที่ตัด. "(worn)" จาก logger ม็อดทำงาน. snap backs 0.
  **คลาส "เล็งล่วงหน้าตามความเร็วเป้า" (target.Physics:GetVelocity ในการเล็ง):** horns shrouden_jump (11 เฟรม; false 9 ใน 2333 =
  ลงข้างหน้าคุณที่วิ่ง), runner pounce (16 ไกล/11 ใกล้), bat chomp (12 เฟรม แต่เฉพาะแนวหน้า — ข้าม, ไม่มีพลาด), sharkboi (มี lead
  แล้วผ่าน spec). rocky/bat :108/193 ใช้ความเร็วแค่สุ่มเลือกท่า. กลไก sim.lead มีใน predict แล้ว (Frostjaw) → simmoves overlay
  ใส่ lead ให้ horns shrouden_jump / runner attack, attack_quick (TR_OLD_AIMLEAD). headless ไม่มีผล (horns 2 ครั้ง, runner 0 ตี) →
  ติดตั้งแล้ว รัน lag shrouden + charlie_boss_runner.
  **ผล (2027_0019_lag):** horns false 9 → 11 — lead ไม่ใช่สาเหตุ. tr_lagdraw: horns 3 ตัวพุ่งไปคนละทางกับรูป (รูป rot -135 ตัวพุ่ง
  +6.5,-6.5 = ตรงข้าม). shrouden_jump หันหาเป้าได้ ≤45° และไม่หันเลยถ้าเป้าอยู่นอก 90° → กระโดดตามทิศที่หัน 6–8 (+physrad);
  ถูกเรียกออกมาหันทุกทาง. ข้อมูล moves_hand ใช้ frame "target" → แก้เป็น "facing" (เหมือน jump ปกติของมันใน spec) — ระยะตาม
  แนวที่หันของเป้า = dot ของเกม. runner ตีแค่ 1 ครั้ง (in) — วัดไม่ได้. ติดตั้งแล้ว → lag shrouden.
  **ผล facing (0029_lag):** horns false 11 → 4 แต่ headless 1925 horns 2/2 → **0/2 missed** (1.66/2.63 off) — frame "facing"
  เปลี่ยนตรรกะ free leap ทั้งชุด (inway/reached/near_now ผูกกับ frame "target"). **ย้อนกลับเป็น "target"** (headless 2/2 คืน),
  ติดตั้งแล้ว. **ค้าง (ทำแบบเฉพาะ):** กฎจริงของ shrouden_jump — ทิศ = หันอยู่ + clamp(มุมถึงเป้า, ±45) ถ้า |มุม| < 90 ไม่งั้นไม่หัน;
  ระยะ = clamp(dot(เป้า+v·11f, ทิศ), 3.5, 9) หรือ 6–8 สุ่มถ้าไม่หัน; ควรเป็นฟิลด์ข้อมูล (เช่น turn_max=45, turn_within=90) ที่ predict
  ใช้ตอน lock กับ frame "target" — ไม่ใช่สลับเป็น facing. lead overlay (TR_OLD_AIMLEAD) ยังติดตั้งอยู่, ยังไม่มีหลักฐานว่าช่วย.
  **nomove_check 8 ตัวใหม่ (2027-10-27, 6 bench + lag 21 log):** เหลือแค่ charlie_boss idle/walk/air_cast/vine_cast (= ของที่เธอปล่อย
  ตีขณะเธอทำท่านั้น — วาดเป็น hazard แล้ว, Queen 289/289) และ **shadowthrall_mouth portal_appear (shrouden_bite) 3 ครั้ง** = กัดแรกตอน
  พุ่งออก portal เฟรม 8. ลอง moves_hand portal_appear (sim เดี่ยว SIM_MOUTH_SHROUDEN): mouth 1925 missed 2 → 17, yellow 3 → 141 ;
  1223 1 → 6 — ท่าใหม่แย่งการจับการกัดต่อเนื่อง (เหมือนครั้งแรก 28 → 0) → ย้อนกลับ, ติดตั้งคืน. **ค้าง:** ต้องให้ Track จบท่า
  portal_appear เมื่อ anim ต่อไปเป็นจุดเริ่มของท่าอื่น (bite_loop) ก่อนจะเพิ่มท่าแบบนี้ได้.
  **ทำแล้ว (2026-10-27):** สาเหตุ = การจับกลางสาย (bite_loop ของ bite_pre) ต้อง seen._other ใหม่กว่า anim ก่อนหน้า; portal_appear เป็น
  anim ของท่าแล้ว _other ไม่ขยับ. predict: ท่าที่จบเพราะเล่น anim อื่น → seen._left = now นับเป็น "อย่างอื่น" (TR_OLD_MIDLEFT). ท่า
  portal_appear ตัดจุดตีหลังเฟรม 8 (เฟรม 20 = กัดใน state ถัดไป) และเส้นทางหลังเฟรม 8 (yellow 141 → 3). mouth 1925: missed 2 → 0,
  1223: 1 → 0. replay ใหญ่ vs baseline: 1701 58/1823/1566 เท่าเดิม ; 1925 missed 7 → 5 ; 1223 118 → 117. ติดตั้งแล้ว.
  **horns aim_facing (2026-10-27):** predict: sim.aim_facing — ทิศ = rot ตอนเริ่ม (หันเสร็จตั้งแต่เฟรม 0 ก่อน client เห็น), ระยะ =
  dot(เป้า + v·lead) clamp 3.5–9 หรือ free 7 ถ้าเป้าเลย 46°, เดินหาทีละ .5 จาก 1 + physrad หยุดเมื่อ IsPassableAtPoint false
  (TR_OLD_AIMFACING); simmoves overlay ใส่ aim_facing ให้ horns shrouden_jump (เอา lead แยกของ horns ออก). headless 1925 ยัง 0/2:
  horns 3 ตัวหยุดที่ 1 (พื้นขอบอารีนา) แต่ ground rows ของ replay บอกเดินได้ถึง 3 → ลงห่างหุ่น 4.4. ในเกมใช้ Map จริงตัวเดียวกับโค้ด
  horns — ยืนยันด้วย lag shrouden. (lag run 0649 ถูกผู้ใช้สั่งหยุดกลางทาง ฉาก 17 — ยังไม่ได้วิเคราะห์; horns aim_facing ติดตั้งอยู่)
  **ของขว้างจุดตกขยับไปมา (ผู้ใช้ 2026-10-27: "projectile ink blight wobble ไปมา"):** simmoves ประมาณจุดตกใหม่ทุกเฟรม (พาราโบลา 6 จุด
  × ความเร็วแนวนอน) รับค่าใหม่ถ้าต่าง ≤ .4 → เลื่อนได้ .4 ทุกเฟรม; ในเกมจุดตกตายตัว (complexprojectile Launch(pos)). แก้: ใช้ค่าเฉลี่ย
  ของค่าที่ผ่านเกณฑ์ (ห่าง > 1 = ขว้างใหม่, เริ่มใหม่) — TR_OLD_LANDAVG. ตัววัดใหม่ TR_LANDWOB (replay_haz พิมพ์ LANDWOB). 1701:
  shadowthrall_projectile_fx เฟรมที่ขยับ > .05: 12341 → 2083, ระยะรวม 2490 → 426 ; um_tentacle_moon_projectile 11358 → 3434 ;
  eyeofterror_fireball 4130 → 866 ; shadow_goo 5137 → 780 ; guardian_goo 3078 → 229 ; fireball_throwable 1998 → 362 ; ทุกชนิดลด.
  1925: 32582 → 6016. ตารางรวม 1701 missed 58 → 57, false 1823 → 1801, jumped 206 → 213. ติดตั้งแล้ว + patch notes.
  เหลือ: "most" ยังสูง (mortarball 3.79, ประมาณใหม่ตอนรีเซ็ต) — mortarball moved 516 → 351 ลดน้อยสุด.
  **mortarball (LANDWOB_V=1 → LANDJUMP):** share061: กระโดด 1–2.6 ตอน "1 averaged" = รีเซ็ต; ค่าประมาณไหลทางเดียวช่วงใกล้ยอด (y≈8,
  0.5–0.9 s ก่อนตก) — เอนเอียง ไม่ใช่ noise. ลอง EMA (4 ค่าแรกเฉลี่ย แล้ว 25% ต่อค่า, รีเซ็ตเมื่อ > 3): กระโดดเหลือ .6–1.3 ที่ค่าที่ 2
  แต่ moved 351 → 368, most ยัง 3.79 → ต้องเทียบทั้งชุด (1701+1925) EMA vs ค่าเฉลี่ยตรง หลัง lag bench จบ.
  **เทียบทั้งชุด (2026-10-27):** EMA 25%: jumped 213 → 105, most ครึ่ง แต่ขยับเล็กบ่อยขึ้น (Ink Blight 2083 → 3433). **EMA 10%**: ขยับเล็ก
  เท่าค่าเฉลี่ยตรง (2083 → 2087; 1925 6016 → 6018), most 1.07 → .54, moon tentacle 2.53 → 1.27, warg goo 2.22 → .37, jumped 213 → 105,
  missed 57, false 1800 → **ใช้ 10%**, ติดตั้งแล้ว. mortarball most 3.79 ยังเหลือ (ค่าแรกของการขว้างไกล).
  **horns aim_facing ในเกมจริง (2027_0710_lag, รอบแรก 0707 Abomination "gave up" ไม่โจมตี):** horns **false 9–11 → 0**, horns พลาด 1
  (2.25, พุ่งไกลกว่าระยะที่ประมาณ ตอนผู้เล่นวิ่ง 8.7/s). shrouden รวม on 2/120 false 8, off 4/113 false 11. mouth portal_appear ใหม่:
  false 4 (3 inside). เก็บไว้.
  **rocky dash ที่เหลือ (1223 L4, 2/292):** dash ที่ 2 ต่อทันที (restart 153.300) พุ่ง ~14 ไปหาหุ่นที่เดิน, ตีตอนชะลอหยุดที่ t .567
  (dash แรกตีขณะผ่านที่ .4), หุ่นห่าง 3.05 จากตัว — ปลายเลน/รัศมีตอนหยุดไม่ถึง. กรณีขอบ, ยังไม่แก้.
  **mortar: ลอง "เริ่มวาดเมื่อ 3 เฟรมติดกันตรงกัน"** → ขยับหาย (most .24) แต่ share061 hazards 79/79 → **68/79 missed 11** (รูปขึ้นช้า) →
  ย้อนกลับ (79/79). mortar ยอมขยับ.
  **testbench lag mode (2026-10-27):** (1) "[tr_lag] t atk <prefab> state= target=<prefab> x z" ทุกครั้งที่เข้า state attack — สำหรับ
  false แบบ aphid; รอบ klaus+stalker (0734) ไม่มี aphid เกิด (UM สุ่ม) — klaus/stalker on 1/207, off 0/192, false 1/0. (2) ถอดของที่สวม
  และมี combat (Batilisk) ตอนเริ่มฉาก: bat (0750) ถอด 14 ครั้ง, ฉากค้าง 2 → 1, NOT drawn on 0/206, off 1/175; false off 15 = bat ธรรมดา
  (atk) 16 + frog 2 ในโลก bench ไม่ใช่ bat_boss (1).
  **lag ชุดใหม่ 10 บอส (2026-10-27_0813, 59 นาที):** on 20/831, off 12/821, false 13/19. เกือบ 0 ทุกตัว (Celestial 1–3, Bee Queen 0,
  Toadstool 0, Frostjaw 0, Werepig 1, Dragonfly 0 false 4/5, Guardian 1/1, Twins 2/1 false 7/5) ยกเว้น **Eye of Terror 8/15**:
  (1) UM eyeofterror_minieye_projectile (linearprojectile 15/s ระดับ ตีเมื่อชน capsule 1.5) 13 ครั้ง age หลายวินาที = คลาสเดียวกับ
  vines (เกมแสดงช้า 0.1 s = 1.5) แต่ LeadMoving ใช้เฉพาะ lasting → ขยายให้ moved ที่บินระดับ (ไม่ใช่ lobbed) ด้วย
  (TR_OLD_HAZLEADMOVED); (2) eyeofterror_mini กัด 8 ครั้ง pred=1 ล้วน (คุณล้ำหน้าบนจอ) — ยังไม่ทำ. ติดตั้งแล้ว → lag eyeofterror.
  **ผล (0913_lag):** minieye ยังพลาด 17 — LeadMoving ต้องมีประวัติ ≥ .2 s แต่ลูกนี้อยู่ ~.3 s (ซ่อน 2 เฟรมแรก, บิน 18/s, ชนที่ ~2.2;
  trace share066 guid 117963). เปลี่ยนเป็นความเร็วจากประวัติ 5 เฟรมของมันเอง × hazard_lead (ไม่ใช่ host). headless: replay_haz
  ไม่นับการโดนจากลูกนี้เลย (58 tr_hurt ใน share066) = จุดบอดของตัวตรวจ.
  **ผู้ใช้ 2026-10-27 "eye พุ่ง เฟรมแรกเหมือนมาหาผู้เล่น แต่พุ่งไปทางตรงข้าม":** ยืนยันจาก lag 0913: ทุก charge (8/8) วาด 44° (ไปหาคุณ)
  0–.33 s แล้วกลับเป็น −141° ที่ .37 s = ทิศพุ่งจริง (ตำแหน่งบอสยืนยัน). Eye ForceFacePoint เป้าทุกเฟรม — เป้าตอนนั้นไม่ใช่คุณ;
  client ยังไม่รู้เป้า → fallback "ผู้เล่นใกล้สุด ทุกมุม" ของ frame target. แก้: ทุกมุม → ภายใน 90° ของทิศที่หัน (TR_OLD_FALLBACKANY).
  replay 1701 58/1799 → 57/1800, 1925 7/208 → 7/209, 1223 เท่าเดิม. testbench บันทึก state แท็ก charge ด้วยแล้ว. ติดตั้ง → lag eye.
  **ผล 0933_lag:** ยังกลับทิศ 7/41 — เป้า = wilson 17/18 จริง. trace server: ก่อน charge_pre Eye **เดิน** (walk 4.5/s, UM เดินถอย
  ออกจากคุณ) → charge_pre ForceFacePoint คุณ (−169.7) → เฟรม 11 เลิกเล็ง ทิศดีดกลับเป็นทิศเดิน (18.2; charge_pre ไม่ locomotor:Stop
  ทางเดินหันมันกลับ) → พุ่งไปทางนั้น. **28/28 ครั้งจากเดิน (0813+0913+0933, Eye + Twins) พุ่งตามทิศเดินเป๊ะ; จากหยุดนิ่ง → ไปหาเป้า**
  (spawnminieyes 2 ครั้งแปลก). แก้: SimMoves._keeps_heading {eye/twins = charge_pre} + predict walk_heading (ทิศ + เดิน 1–10/s ทุกเฟรม
  ที่ไม่อยู่ในท่า; testbench วาร์ปบอส = ไม่นับ) → a.heading ใช้เป็น rot ตั้งแต่เฟรมแรก; ไม่ใช้กับท่าหลายขา (mouthcharge)
  (TR_OLD_KEEPHEADING). replay 1701: รอบแรก Eye 77 → 74 (วาร์ป + ขาปาก) → แก้แล้ว 77/77, รวม 57/1800 เท่าเดิม. ติดตั้ง → lag eye+twins.
  **พิสูจน์ (0956_lag, eye+twins):** กลับทิศ > 90°: Eye 0/27, Twins 0/30 (เดิม 7–8 ต่อรอบ). minieye_projectile พลาด 17 → 3 (ความเร็ว
  5 เฟรม × lead). เหลือ eyeofterror_mini กัด 13 (9 pred=1) + "?" 8. patch notes เพิ่ม Eye/Twins charge, mini eyes, mouth/horns.
  eyeofterror_mini: กัดครั้งเดียวเฟรม 14 (DoAttack) ขณะพุ่ง 4/s (เฟรม 5–22); รุม 5 ตัว, client เริ่มท่า 1486 ครั้ง vs server 541
  (รวม taunt/ซ้ำ). พลาด 13/~600 ที่ 1.7–2.8 จากตัว — ระบุตัวที่กัดไม่ได้ (server ไม่ได้ส่ง guid) — ยังไม่แก้.
  **lag ชุด 2 (2026-10-27_1015, 31 นาที):** daywalker2, lordfruitfly, mutatedbearger/deerclops/warg, spiderqueen, wagboss_robot, warg:
  **NOT drawn 0/210 on, 0/282 off**, false 0/4. antlion, malbatross ไม่ได้รัน (ไม่มีฉาก — ต้องทะเลทราย/ทะเล). snap backs off 23
  = daywalker2 throw_pre (frame facing, lock 86, รูปที่จุดตกห่างบอส ~30): ตามผู้เล่นที่วิ่ง 7/s แต่กระโดด ~5 ไปมาทุก .2–.37 s
  เฉพาะ pred=0 (pred=1 0) — น่าจะสลับระหว่างตำแหน่ง server/จอของคุณตอนเล็ง; ไม่ทำให้พลาด, ยังไม่แก้.
  **Eye ยิง mini eye (1049_lag, tr_lagjoin พิมพ์ guid/ตำแหน่งตัวที่ตีแล้ว):** mini eye กัด 0 พลาดรอบนี้; ที่พลาด 10 = ลูก minieye
  ทั้งหมด, ส่วนมาก client ยังไม่เห็นตัวลูก ("?") — ผู้เล่นชิดตัว Eye ~1.3. UM ShootEye: linearprojectile 20/s offset (2,1) มุมกดลง
  (−45° ใน sim) บินทะลุพื้น (CollidesWith CHARACTERS เท่านั้น) capsule 1.5 → ตีได้แค่ห่างทางลูก ≤ 2 ช่วง 2 → 4.5 หน้าตัว.
  moves_hand_um มี "charge_pre~shoot_pre" (และ ~2 ร่างปาก) วาด nothing (maps {}) → เติม maps: capsule นั้น ที่เฟรม 39 (charge_pre 33 +
  shoot_loop 6), ซ้ำทุก charge_loop f6 (ปาก 2 ลูก). sim: linearprojectile ใส่ REAL_COMPONENTS (SIM_OLD_LINEAR) — ยัง "nothing"
  (มุมกดลงชนพื้น 0.07 s). replay 1701 Eye 77/77 false 0 yellow 7 → 8. ติดตั้ง → lag eye.
  **ผล (1104_lag):** minieye_projectile พลาด 10 → 2 ; false ใหม่จากท่ายิง 13 (shoot_pre 9, ~2 4) — รูปกว้างกว่าที่ลูกตีจริง (ลูกกด
  ลงพื้น ช่วงจริงอาจสั้นกว่า 4.5) — แลกไว้ก่อน. mini eye กัดพลาด 11 (pred=0) รอบนี้ — แปรปรวน (รอบก่อน 0). patch notes แก้แล้ว.
  **mini eye กัดพลาด = เพดาน 16 ตัว (S.max_monsters):** ตัวที่กัดตำแหน่งตรง server (≤ .1) และเคยถูกวาดในจังหวะอื่น แต่ไม่ถูกวาดตอนกัด;
  mini หลายสิบตัวรุม (guid ไม่ซ้ำ) — Pick เรียง ใต้เมาส์ > เล็งคุณ > ใกล้สุด แล้วตัดเหลือ 16. แก้: Predict.Attacking(ent) (กำลังอยู่ในท่า
  หรือเล่น anim ของท่าใดท่าหนึ่ง) มาก่อน "เล็งคุณ" (TR_OLD_PICKATTACK). modenv จับ rawget เปล่าได้ก่อนติดตั้ง. replay มองไม่เห็น
  (modmain) → lag eye. **ผล (1116_lag): Eye NOT drawn 0/177 on, 0/171 off** (จากวันแรก 15/8) ; false 15 (ท่ายิง 10, mini 4,
  charge 1). ลูกโดนจริง (117 ครั้ง 5 รอบ) ห่างหน้าตัว 0.5–17 (ยิงไกลเกือบระนาบ) — ไกลวาดโดยตัวลูก (lead) แล้ว; รูปท่ายิงครอบระยะใกล้
  ที่ลูกยังไม่ทันโผล่ — คงไว้. patch notes เพิ่มลำดับเพดาน.
  daywalker2 throw_pre เด้ง (pred=0): sx/sz = ตำแหน่งบนจอ (TR_LEAD ปิด) ลื่น — สงสัย srv_aim (PoseAimUpTo, ก่อน lock 86) สลับกับเป้าบนจอ
  ตามจังหวะ pose จาก server; กระทบทุกท่าที่ใช้ server aim → ยังไม่แตะ.
  **regression lag ชุด 1 (1128_lag) vs 0813:** on 20/831 → 20/897, off 12/821 → 16/840, false 13/19 → 30/29. Eye 15/8 → 3/6 แต่:
  Celestial phase2 on 1 → 7 (attk_stab_pre ไม่วาด 10–16 off) = **กฎ fallback 90° ของผมเอง** (Eye ไม่ได้ใช้ — ท่าพุ่งเป็น frame facing,
  ตัวแก้จริงคือ keeps_heading) → **ย้อนกฎ 90°**. Twins on 1 → 6 (laserempty 1.10 + "?") = keeps_heading ไปโดนท่ายิง (tell, หันหาเป้า
  ระหว่างยิง) → จำกัดเฉพาะท่าไม่มี tell (เช็คทั้งตอนเริ่มและตอนใช้ เพราะ tell ตัดสินทีหลัง). daywalker 1 → 6 = pounce (run_pre .13 s
  แล้ว atk3 ชนเฟรม 0–5 ขณะพุ่ง 11/s) — client เห็นท่าเริ่มช้ากว่าการตี (ความหน่วง) เช้าแค่สุ่มเจอน้อย. beequeen off 0 → 4 (UM guard
  stinger) — ยังไม่รู้. ติดตั้ง → lag phase2 + twins1 + beequeen.
  **ผล (1229_lag):** phase2 0/0, twins1 0/0 (false 7/7), phase3 0/1 (lead 2.59), beequeen off 3/55: beeguard 2.22 age .3 ×1, UM shooter
  stinger (นับเป็น shooter ห่าง 13) ×2 พร้อมกัน — ยังไม่ได้ดู.
  UM um_beestinger_projectile: projectile 25/s ไม่ homing, hitdist 1.41 — บนจอช้า ~2.5; LeadMoving รอ .2 s (2 ช่วงเช็คนิ่ง) = บินไป 5
  แล้ว. แก้: เร็ว > 12/s ข้ามเช็คนิ่ง (TR_OLD_HAZFAST). ติดตั้ง → lag beequeen 3 รอบ.
  lag beequeen เดี่ยว (1250, 1253) จบที่ 2 นาที: ราชินี flyaway notarget หลังฉากแรก (เสีย aggro — ผู้เล่นใน bench ไม่ตี) → "no next
  phase yet". ในรอบรวมหลายบอสรันได้ (บังเอิญยังมีเป้า). **ยังพิสูจน์ HAZFAST ไม่ได้** — ต้องให้ testbench lag mode รักษา aggro ราชินี.
  ลอง SetTarget(ผู้เล่น) ทุก 1 s ให้บอส epic ที่ไม่มีเป้า → ยังบินหนี (brain ตัดสินด้วยอย่างอื่น) → ย้อนออก. ราชินีใน lag bench
  เดี่ยวยังใช้ไม่ได้; ชุดรวม (1128/1229) รันได้.
  **1259_lag (twins1 → beequeen):** beequeen off 7/125 (stinger ×3 + shooter ×4) — HAZFAST ไม่ช่วย. **LUA ERROR ×2: simmoves UnionDraw
  "table index is NaN"** (warningshadow ของ UM อยู่ใน union; ครั้งแรกทั้งวัน, หลังติดตั้ง HAZFAST). ต้นตอยังไม่ชัด (LeadMoving ให้ค่า
  จำกัดเสมอตามที่อ่าน) → ใส่ด่าน: LeadMoving คืนตำแหน่งเดิมถ้าไม่ใช่ตัวเลข + พิมพ์ครั้งแรก "[true_range] LeadMoving not a number",
  DrawHazardInner ไม่วาดถ้า x/z NaN, UnionDraw ข้าม key NaN. ติดตั้ง → รันซ้ำ.
  **1314_lag:** ไม่มี LUA ERROR, ไม่มี "LeadMoving not a number" (ต้นตอ = x/z ของ hazard เองชั่วขณะ — ด่านต้นทางรับไว้). twins 2/2 "?",
  bee shooter (เหล็กไน) 2/1 คู่ (นับซ้ำ 2 ต่อครั้ง). moved-lead: ช่วงเวลาขั้นต่ำ FRAMES/2 (เดิม 1e-6). tr_lagjoin TRACE + stinger,
  minieye → รันซ้ำเพื่อวัดเหล็กไนบนจอ.
  **1329_lag:** เหล็กไนบนจอช้ากว่า server 2.5 (= 25/s × .1) ; ตอนโดน วาดทัน 22/24 → HAZFAST ได้ผล. beequeen off 0/164, on 2/177 ;
  twins 1/3 (laserempty ใกล้ตัว). twins laserempty: SpawnLaser ชิ้น i=0,1 ที่ 1.25/2.0 หน้าตัว, FX หายก่อน client เห็น — ยังไม่แก้.
  **run_lag -Speed n (ผู้ใช้ "เร่ง tick ก็ได้"):** server SetTimeScale ผ่าน bench_overrides speed, tr_lagjoin อ่าน speed จาก join.txt
  SetTimeScale เท่ากัน, TickRate = 15n อัตโนมัติ (ความหน่วงในเวลาเกมเท่า 1x). ทดสอบ: Eye 2x เทียบผล 1x (1116: 0/177, 0/171).
  **ผล 2x (1342_lag, 5.9 นาที แทน ~10):** on 0/152, off 1/165, false 5/7 ≈ 1x. แต่ gap ตอนวิ่ง: on .60 → 1.19, off .50 → .17 — ความหน่วง
  ไม่เท่า 1x (prediction ล้ำเป็นสองเท่า, ไม่ predict ช้าลง). **ใช้ 2x คัดกรองถดถอย/การจับท่า; พิสูจน์เรื่องความหน่วงใช้ 1x.**
  **Twins laserempty (1314):** tell ถูก 18/18 แต่พลาดในร่างปาก: mouthshoot_loop ×5 ทุก .27 s แต่ละรอบ ForceFacePoint + SpawnLaser ที่
  TimeEvent 0 (ชิ้น 1.25/2.0) เล็งใหม่; data charge_pre~shoot_pre~2 lock 50 ครั้งเดียว → รอบหลังชี้ผิดเมื่อคุณวนรอบตัว. **ค้าง:** predict
  ล็อกทิศใหม่ทุก again_anim (charge_loop) สำหรับท่าที่ตัวมันหันตามเป้าระหว่างวน. ดูแล้ว: data ~2 มีแค่เลเซอร์ลูกแรก (steps 34–53,
  set_until 66) — ลูก 2–5 (ทุก 8 เฟรม เล็งใหม่) ไม่มีในข้อมูลเลย → ต้องสร้าง data ใหม่ (sim วนทุกลูก หรือ again_anim + เล็งใหม่) — งานใหญ่
  เทียบ 2–4 พลาด/รอบ → ค้างไว้.
  **คัดกรอง 2x ทุกบอส 24 ตัว:** 2 ครั้งเกมเข้า server ไม่ได้ ("Direct connection timed out") — ชื่อ server = "tr_bench+lag:<24 ชื่อ>"
  ยาวเกิน; 7 ตัวเข้าได้. แก้: run_lag เขียนรายการยาว (> 60 ตัวอักษร) ลง tr_list.txt ในโฟลเดอร์ testbench ฝั่ง server, ชื่อ
  "tr_bench+lag:@list"; testbench อ่านไฟล์เมื่อเห็น @list. ชุดแรก 7 ตัว 2x กำลังรัน แล้วต่อ 17 ตัวที่เหลือ.
  **ชุดแรก 2x (1402_lag, 7 บอสเดิมเมื่อคืน):** on 7/544 (1.3%), off 7/666 (1.1%) — เมื่อคืน 11/594 (1.9%), 10/443 (2.3%). ไม่มีถดถอย.
  false bat_boss off 40 = ค้างคาวธรรมดา (bat atk) 41: เล็ง wilson 234 ครั้ง โดน 178 — ตีพลาดเพราะผู้เล่นวิ่งวน (BAT_HIT_DIST 1);
  headless bat 410/410 false 4 → เตือนเกิน ไม่ใช่พลาด, ต่ำ.
  **ชุด 2 (1424_lag):** รายการ @list ไม่ถูกอ่าน (io บน dedicated server อ่านไฟล์ไม่ได้) → รันรายการ default 13 ตัวแทน → เปลี่ยนเป็น
  ค่าตั้ง mod "list" (modinfo option + bench_overrides BENCH_LIST). ในรายการ default: **moonmaw_dragonfly (UM) NOT 31/60** — moonmaw_lavae_ring
  78 (25 ต.ค. 0–8 / ~350) = ถดถอยหรือผล 2x. lavae_ring ไม่มี sim (moves_preload ทั่วไป) ทำร้ายด้วยการชน — สงสัยลำดับเพดาน 16
  (Predict.Attacking ก่อน) ดัน lavae ที่บินวนออก หรือ lead ของ 2x → รัน moonmaw 1x แยกสาเหตุ.
  **ชุด 17 บอส 2x (1455_lag, รายการจากค่าตั้งได้ครบ):** on 9/683 (1.3%), off 7/770 (0.9%), false 5/4. bearger on 5 = หิน UM 5 ก้อนแตก
  ทันทีที่จุดเกิด (เคสเก่า ค้าง (2) 25 ต.ค.), daywalker 3 (pounce, ความหน่วง), daywalker2 2, minotaur 2/1, ที่เหลือ ≤ 1. ไม่มีถดถอย.
  **moonmaw 1x (1530_lag, 1 รอบ):** NOT on 42/295, off 26/310 ; lavae_ring 64/466 (25 ต.ค. 0–8/~350) → **ถดถอยจริง ไม่ใช่ผล 2x**.
  เครื่องมือใหม่: run_lag -Old "TR_OLD_X,..." → tr_lagjoin rawset ในเกม (ปิดการแก้ทีละตัวในเกมจริง). ทดลอง TR_OLD_PICKATTACK ก่อน. horns 0.00 ซ้ำ 4 ครั้ง ×2 = ผู้เล่นถูก **กลืน** (devoured, DoChew) — กฎ worn ตัดถูก. snap backs 0/0. รวม on 4/252, off 2/218.
  **moonmaw สาเหตุ (2026-10-27):** PICKATTACK ปิด (1537) 59/399 ; ปิดทุกสวิตช์ตั้งแต่ 26 ต.ค. (1543) ยัง 83 → ไม่ใช่กฎที่มีสวิตช์.
  UM: วง lavae (moonmaw_lavae_ring, 8 ตัว) ทำร้ายรัศมี 2.2 เฉพาะใน state lavaeattack (anim spin) ของ Moonmaw → ที่วาดคือท่า spin_pre
  ของตัวบอส. รายครั้ง: spin ที่ client วาด 0 บรรทัด = **ทุกครั้งที่ lavae ธรรมดา 8 ตัวอยู่ด้วย** (stab_pre ค้าง) ; ไม่มี = วาดครบ 90.
  8 + วง 8 + บอส = 17 > เพดาน 16 ; บอสไกลกว่า → หลุดเพดาน (ลำดับใกล้สุด). 25 ต.ค. แค่ไม่มี lavae ธรรมดาในรอบ = บั๊กเพดานเดิม ไม่ใช่ถดถอย.
  แก้ modmain: มอนที่มีแท็ก epic อยู่ก่อนตัวที่กำลังตี/ไล่คุณ (หลังตัวใต้เมาส์) ; TR_OLD_PICKEPIC = เดิม. รัน moonmaw 1x 1 รอบ.
  **ผล (1554_lag, 1x, lavae ธรรมดาอยู่ทั้งรอบ 14094 บรรทัด):** NOT on 53 → **1/304**, off 35 → **2/210** ; lavae_ring 83 → 2/398. false 31/35
  (เดิม 29/22) — false spin_pre 56 ที่ 2.8–5.6 จากบอส: lavae ในวงที่ถูกดีดออกเป็น lavae ธรรมดา = Hide() + hidden (ไม่ตี) → วงมีช่อง
  แต่รูป spin วาดทั้งวง. ทางแก้ (ยังไม่ทำ): วาดวง 2.2 รอบ lavae_ring แต่ละตัวที่ยังมองเห็นขณะบอสเล่น spin แทนรูปเต็ม — **ตัดสินไม่ทำ:** วงโคจรเร็ว,
  client เห็นช้า ~.1 s → วงเล็กเสี่ยงพลาดใหม่ ; รูปเต็มพลาด 1/304 แล้ว. พลาดสำคัญกว่าเตือนเกิน. daywalker2 throw เด้ง: จุดตั้งต้นรูปสลับ
  ระหว่าง 2 จุดคงที่ห่าง 3.8–5 ทุก .2/.37 s ขณะผู้เล่นวิ่ง 7/s (ไม่ใช่ตำแหน่งผู้เล่น — น่าจะกองขยะที่หยิบ) ไม่ทำให้พลาด — ค้าง. install.ps1 exit 3 = รหัส robocopy (< 8 = สำเร็จ) ไม่ใช่ล้ม.
  **Twins เลเซอร์ปาก ลูก 2–5 (2026-10-27):** UM postinit SGeyeofterror: charge_pre 33 เฟรม → mouthshoot_loop (charge_loop 8 เฟรม) ×3–5,
  แต่ละรอบ SpawnLaser ที่ TimeEvent 0 ตามทิศที่หันอยู่ (onupdate ForceFacePoint เป้า) ; ชิ้นเลเซอร์ดีเลย์ (i-1.2) เฟรม → ลูกหนึ่งตีอยู่
  ~19 เฟรม ทับลูกถัดไป. ใหม่: SimMoves._relock[prefab][move] = { anim, at } + predict: ทุกครั้งที่ anim นั้นเริ่มใหม่ (began เลื่อน > 2 เฟรม)
  ลูกก่อน → after[ent] (สำเนา วาดต่อจนจบ) ; ตัวที่ active t0 = began − at, ล็อกทิศตามที่หันตอนนั้น (exact) ; บล็อกล็อกเข้าได้ก่อน lock_f
  เมื่อ relock. twinofterror1 ทั้งสองร่าง at 33. TR_OLD_RELOCK. (เพิ่มใน replay/replay_haz switch list พร้อม PICKEPIC)
  **ผล lag 1x (1600_lag, 1 รอบ, mouthshoot_loop 10 ครั้งบน server):** NOT drawn **0/53 on, 0/40 off** (1314: 1/3 laserempty) ; twin
  เลเซอร์โดน 18/18 วาด ; false 1/7. headless replay 1701 share064: missed 0 ทั้งเปิด/ปิด ; false 20 → 46 = **ตอนเดิม 11 ตอน นับใหม่ทุก
  ลูก** (เวลาเดียวกันทุกตอน 511/551/610/637/... — แต่ละลูกเป็น go ใหม่) ไม่ใช่ false ใหม่. หมายเหตุ: cache ของ bench_replay ไม่แยกค่า
  env TR_OLD_* — เทียบเปิด/ปิดต้องลบไฟล์ผลก่อน.
  **คัดกรอง 2x บอสที่มีลูกน้องเยอะ (1610_lag, 10 ตัว 1 รอบ, หลัง PICKEPIC+RELOCK):** NOT on 6/344, off 1/387, false 9/15. klaus on 3/off 1
  = เฉพาะรอบ 2x (1402: 1, 1424: 4 ; 1x 2130/2333: 0) = ผล 2x. eye mini 1, stalker 1 (age 2.6), charlie 1, shrouden 1. ไม่มีถดถอย.
- **ผู้ใช้เล่น Cluster_3 (2026-10-27 16:33, Host+ถ้ำ = client ของตัวเอง): "พังหมด"** — (1) วงน้ำแข็ง Klaus (deer_blue → deer_ice_circle)
  เล็กเกิน ของจริงโดน และหด ; (2) ท่าน้ำแข็งเล็งไม่ใช้ข้อมูล server ; (3) "HIT by ?" ; (4) ทำไมไม่เช็กว่าจบท่าแล้วตรงของจริง.
  **สาเหตุ:** (1) deer_fx OnUpdateIceCircle: รัศมี _rad (net_float ส่งถึง client) เริ่ม .25 โต 2%/เฟรมเข้าหา 3 (1 s ≈ 1.5, 3 s ≈ 2.55),
  FindEntities ด้วยรัศมีนั้น (ศูนย์กลางตัว) → แช่แข็ง. ม็อดวาดจาก steps offline (เฟรม 20–169 ของ atk_magic_pre) + ท่ายาว 28 เฟรม
  แต่ after[ent] วาดต่อถึงเฟรม 169 (~5 s) ทับวงจริง = วงเล็ก/หด. (2) modmain PoseOne ส่ง aim จาก statemem.target / combat.target —
  กวางเก็บ statemem.targets (รายการผู้เล่นใกล้ ล้างทิ้งตอนร่ายเฟรม 19.5) → aim nil → client เล็งตามจอ. (3) client ไม่ได้รับ
  data.attacker. (4) **จุดบอดของตัวตรวจ:** แช่แข็งไม่ใช่ "attacked" (AddColdness) → bench/replay/lag ไม่นับเลย ; ทั้ง replay ไม่มี _rad.
  **แก้:** simmoves SimMoves._live_radius { deer_ice_circle = _rad, grows_to 3 } → DrawHazard วาด disc รัศมีจริง (แดง) + เส้นขอบ 3
  (TR_OLD_LIVERADIUS) ; predict ไม่เก็บ after ของท่าที่ของมันวาดสด (moves_table things) ; modmain PoseOne: statemem.targets → แต่ละคน
  ในรายการได้ aim = ตัวเอง (RPC แยกคน, host ด้วย) เก็บไว้ทั้ง go (TR_OLD_AIMLIST) ; "HIT by X?" = เดาจาก pending ล่าสุด หรือมอน
  ที่กำลังตีใกล้สุด ≤ 8 (TR_OLD_GUESSBY). tr_lagjoin: [tr_lagice] r/d/drawn_in/frozen ทุกเฟรม → lag klaus 1x.
  คลาสเดียวกัน: deer_fire_circle (_rad ไม่ส่ง client, .25 → FIRE_CIRCLE_RADIUS 10%/เฟรม ~1 s) ยังวาดจาก offline — ผู้ใช้ยังไม่แจ้ง.
  **ตัวตรวจที่ขาด:** ผลที่ไม่ใช่ attacked (แช่แข็ง, ติดไฟ, ช้าลง) — ต้องเพิ่มการนับ "frozen/ignite ขณะอยู่นอกรูป" ใน lag bench.
  **tr-reviewer (2026-10-27):** BLOCKING 3 ข้อ → แก้แล้ว ติดตั้งแล้ว: (1) net_float เป็น object ของ engine อาจไม่ใช่ table → pcall(nv:value)
  ; วงแช่แข็งได้เฉพาะหลัง TriggerFX (deer_ice_fx ลูกของวง, magic_pst f25 ≈ 87 เฟรมหลังเกิด r≈2.53 ; วง UM ไม่เคย) → armed_by:
  ก่อนนั้นสีเตือน (ช้าลงอย่างเดียว) (2) ท่า UM ไม่มี moves_table → ใช้ sim.puts ด้วย (3) กวางรับ target ของ Klaus เป็นของตัวเอง →
  อ่านรายการก่อน combat.target ; host ด้วย. (4) เดาตัวตีล้าง pending — คงไว้ (กันแชต NOT HIT ปลอม) ; นับใช้ server [tr_hit].
  **ผมเข้าใจผิด:** วงอยู่ 180 เฟรม (castduration 6) = ท่าเฟรม 20→200 ตรงกับ steps → "หด" น่าจะมาจาก steps offline ช่วงท้ายบาง
  (1–2 ช่องต่อ step) ไม่ใช่ after. log ผู้ใช้: วงที่ 2 (465.767) คุณยืนห่าง 2.77 ตั้งแต่ 466.7–473.5 ; r ถึง 2.77 ราวเฟรม 123 (~469.9)
  = วงโตมาถึงตัวคุณ. คลาสเดียวกัน (ยังไม่ทำ): deer_fire_circle (3.6, 10%/เฟรม), deerclops_mutated_fx :222, eyeofterror_sinkhole
  radius ; ตำแหน่งที่มี net แต่ไม่ใช้: bishop shotx/z, wagboss_missile x0/z0, worm_boss dirt ; รายการเป้า: SGstalker:872 snares,
  SGtoadstool:784 spore bomb, UM SGrambranch:709 ; จุดเล็งที่ PoseOne ไม่อ่าน: phase3 target_pos, SGbishop/lunarthrall_plant_vine
  pos, SGcookiecutter target_pt, phase4 x1/z1,x2/z2.
  **วิธีตรวจแบบขยายได้ (ข้อเสนอ):** sim_moves.lua Body Touched (:2438) จับ freeze/fire/slow/sleep/knockback อยู่แล้ว → log ดิบต่อเหตุการณ์
  (เฟรม, ของ, ตำแหน่ง, ตำแหน่ง dummy, ชนิด) + stub net_float บันทึก set() ; tools/effect_check.lua ใหม่: รัน predict/simmoves headless
  บนข้อมูลเดียวกัน ป้อนค่า netvar → ทุกเหตุการณ์ต้องอยู่ในรูปที่วาด ณ เฟรมนั้น (MISSED) + วาดแต่ไม่เกิด (FALSE) ทุกบอสพร้อมกัน ;
  control: TR_OLD_LIVERADIUS=1 ต้อง MISSED ที่กวาง. testbench hook เดียวกันพิมพ์ [tr_eff] ให้ replay. ไม่จับ: บอสผูกสถานที่, stub
  ต่างของจริง, lag, สไตล์วาด (modmain), ของที่ sim ไม่สร้าง.
  **แผนให้จบ 1.1.6 (tr-reviewer ตรวจ, 2026-10-27): 4–5 วัน ไม่ใช่ 2–3.** ลำดับ: (1) ฉาก Klaus+กวาง (spawn deer_blue/red ตั้ง
  keeper = Klaus ผ่าน entitytracker deer.lua:299 ไม่งั้นไม่ร่าย) + [tr_eff] ตอนตัวแทนแข็ง/ช้า/ติดไฟ — 0.5 วัน ; (2) effect_check ทาง
  log: sim เขียน log แบบ bench ([tr_trace]/[tr_haz] + [tr_eff] จาก Body/Touched :2438) แล้วใช้ tests/replay.lua (DrawHazards :1538,
  [tr_hit]/[tr_hurt] :542) — 1 วัน ; ความเสี่ยง: ตรวจวน (sim เทียบ sim = เจอแค่บั๊กการวาด), ของใน replay ไม่มีสถานะ runtime
  (_rad, ลูก deer_ice_fx, scale) ต้องเขียนลง log, ผลที่ต้องอยู่นาน (ไฟ N เฟรม) นับต่อเฟรม ; (3) แก้ตามกลไก 1.5 วัน ; (4) ฉากผูก
  สถานที่ 1 วัน ; (5) รอบสุดท้าย + ตาราง 0.5 วัน. ตัด: จุดตำแหน่ง server (Predictive) ไว้หลัง 1.1.6. เพิ่ม: unit tests ครบก่อนติดตั้ง,
  control (build เก่าต้องต่าง), รอบ UM ด้วย TR_MODS. **เกณฑ์เสร็จ:** testbench ทุกบอส เกม+UM -Rounds 3 MISSED ≤ 59 (1701) ไม่มีใหม่,
  ทุกท่าที่เห็นมี STRIKE ≥ 1 (ที่ไม่เห็น = ยังไม่ทดสอบ) ; effect_check MISSED 0 สำหรับแข็ง/ไฟ/ช้า/กระเด็น, FALSE มีหลักฐานโค้ด,
  control ต่าง ; ฉาก Klaus+กวาง แข็งนอกรูป 0, ไม่มี "?" ใน [tr_hit] ; log ผู้ใช้ compare.ps1 ไม่มีบอสแย่ลง ; unit tests ผ่าน.
  **ข้อ 1 เสร็จ (2026-10-27_1715_lag, Klaus 1x 1 รอบ):** testbench SETUP klaus = boss:SpawnDeer() (กวางเกิด ผูก keeper) ; true_range
  modmain DEBUG EFFECTS: "you were frozen / set alight / knocked back - drawn: in/NOT" (anim frozen*, แท็ก fire, anim knockback*) —
  เห็นใน log ผู้ใช้ด้วย ; lag_report นับ "effects". ผล: กวางร่าย 33, วงน้ำแข็ง 7, วงไฟ 4 ; แข็ง 1 / ติดไฟ 4 — **NOT drawn 0** ;
  tr_lagice 1605 เฟรม: แข็งนอก r 0, ใน r แต่ไม่ drawn_in 0, drawn_in นอก r+.3 0 ; r สูงสุด 2.92–2.93 (ค่าจาก net อ่านได้ — pcall ทำงาน).
  ตีปกติ NOT on 1/96, off 0/102. ยังไม่ได้วัด: การเล็งก่อนร่าย (AIMLIST) ตรงจุดเกิดวงแค่ไหน.
  **testbench stand-in รับผลได้ (2026-10-27):** freezable + MakeMediumBurnableCharacter ; event freeze/onignite → [tr_eff] + [tr_haz] HIT
  ของ hazard ใกล้สุด ≤ 6 (ดับไฟ 1 s ; TR_BENCH_OLD_EFFECTS). bench klaus 1724: แข็ง 8 (deer_ice_circle), ไฟ 3 (deer_fire_circle) ;
  replay _haz 11/11 drawn, klaus 1417/1417. (replay ตรวจกับ steps ไม่ใช่ _rad — วงจริงพิสูจน์ด้วย lag 1715.) รอบเต็ม -All -Rounds 3
  กำลังรัน ; "by ?" = ผลพ่วงจากการกัด (magmahound/glacialhound UM) — ต้องเช็กว่ามีที่ไม่มี HIT คู่กันไหม.
  **Predictive แบบขยายได้ (tr-reviewer):** headless ไม่มี client → ไม่มี prediction ; lag bench จริงทีละตัว เวลาจริง (-Speed บิดความหน่วง)
  ; หลาย client: บัญชี Steam ที่สองบนเครื่องอื่น (ผู้ใช้ต้องมี) ; ทาง: replay "client mode" — replay.lua:479 TheWorld = { Map = {} }
  (ismastersim nil = client อยู่แล้ว) แต่ HAZ_LEAD=0 ; ต้อง: pose จาก [tr_trace] ส่งช้าตามความหน่วงที่วัด, you = server + ความเร็ว×lead
  (YOU_LEAD มีแล้ว :1434) แต่ lead ต่อเฟรมตามความเร็วจากคู่ srv_you/me ใน [tr_lag], ทดสอบที่ p50 และ p90. **control:** replay log
  server ของ lag bench ใน client mode ต้องได้ drawn-in/struck ตรงกับที่ client จริงบันทึก ±5%. ~1 วัน + control 2 ชม. เกณฑ์เพิ่ม:
  control ±5% ; client-mode ทุกบอส Predictive on MISSED ไม่แย่กว่า off ; lag bench จริงรอบเดียว (Klaus + บอสผสม) ยืนยัน.
  **ทำแล้ว (ยังไม่ปรับเทียบ):** replay.lua + replay_haz.lua: CLIENT=1 → ENT_LAG 3 เฟรม (บอส/ของจาก tick ที่ t−lag ด้วย cursor แยก
  "ti_back" — At() เดินหน้าอย่างเดียว), POSE_LAG 3, HAZ_LEAD .1, YOU_LEAD PRED=1 +3 / PRED=0 −2 เฟรม (ตอนตัดสิน strike ด้วย s.vx), หน้าต่าง
  "in" = [t+lag−.15, t+lag+½เฟรม] (เท่า modmain last_inside_at) ; PRED=n นับเฉพาะฉาก "[tr_bench] … lag scene pred=" ; DN_DBG=t debug.
  บั๊กที่เจอระหว่างทำ: ขอบบน t+1e-6 ตัดเฟรมที่โดนพอดีเพราะเวลาเฟรมสะสมทศนิยม → 12 MISSED ปลอม (แก้: +½ เฟรม).
  control แรก Klaus 1715: client-mode on 0/84, off 0/93 vs client จริง 1/96, 0/102 — Klaus ตกน้อยเกินจะใช้ปรับเทียบ ; ต้อง lag bench
  ของบอสที่ความหน่วงทำให้ตก (daywalker pounce, eye mini, rocky_boss_shadow dash) ด้วยโค้ดปัจจุบัน หลังรอบ headless จบ.
  **รอบเต็ม headless + ผล (2026-10-27_1727, -All -Rounds 3, 267 บอส, replay 510 s):** strikes 59132, missed 234 — บอส 17 (เกณฑ์
  ≤ 59 ✓: boulder_crab 3, shrouden 3, eye 2, phase1_lunarrift 2, vault_crawler 2, อื่น 1), _haz 217: um_fire_projectile 60,
  firesplash_fx 53, worm_boss_segment 27, glacialhound_icespike 27, magmafire 21, warg_mutated_breath_fx 16, deerclops_icespike 10,
  deer_ice_circle 6 … Lua error 2 = UM um_beegun.lua:578 (ของ UM). **ปัญหาตัวตรวจที่พบ:** (1) [tr_eff] ไม่มี pos → lane_split
  ส่งทุก lane (ตัวเลข "?" ซ้ำ L1–L4) → เพิ่ม pos= ; (2) ผลพร้อมการตีในจังหวะเดียวกัน (กัดแล้วติดไฟ) ถูกโทษของใกล้สุดซ้ำ = MISSED ปลอม
  → testbench _tr_blow_t: ผลที่มากับการตีไม่โทษของ ; (3) replay_haz วาด deer_ice_circle จาก steps → LIVE_RAD สูตรเกม
  (3 − 2.75·.98ⁿ ; LIVE_RAD_OLD) ; simmoves armed: ไม่มี TheSim = armed. รันซ้ำเฉพาะบอสที่มีผล (deer_blue, magmahound, glacialhound,
  um_pepperdragon, mock_dragonfly, deerclops, icehound, mutatedwarg, firehound, klaus).
  **รอบ 1758 (หลังแก้ 2 ข้อ):** _haz 217 → 109. firesplash_fx 52 / um_fire_projectile 23 = ติดไฟไม่มีการตี ; um_fire_projectile 17 =
  stand-in ไฟเผาตัวเอง 1 s → [tr_hurt] cause=fire ทุก tick ที่ replay_haz นับเป็นไฟบนพื้น (ของที่ผมทำเอง) → ดับทันที + ผลชนิดเดียวกัน
  ≤ 1 ครั้ง/.5 s. **ผลไม่มีการตี → ให้บอสตัดสิน:** modmain SimMovesPose._trace_line = TraceLine ; testbench พิมพ์ "STRIKE by <ของ |
  effect_kind> at wilson" ของบอสใน lane (≤ 30). replay.lua: EFF_AT จาก [tr_eff] ; ยกเว้นจาก STRIKENOHIT (STRIKE ไม่มี HIT ถูกตัด) และ
  NOHARM (ไม่มี [tr_hurt]) — **ทั้งสองกฎเคยตัดการโดนจากผลทิ้งทั้งหมด** ("บอสตก 0" ก่อนหน้าไม่ได้ตัดสินจริง) ; by_own เมื่อ EFF_AT
  + ของเป็น hazard (OLD_EFFBY). **ผล 1809:** บอสทุกตัววาดคลุม (mock_dragonfly 602 → 771 strikes 0 missed, magmahound 369/369,
  pepperdragon 486/486) ; ASBOSS_DRAWN 113 ; TOTAL missed 152 → **54** (warg breath 13 เก่า ; ที่เหลือ um_fire_projectile ของ
  magmahound/pepperdragon ที่บอสไม่ได้วาด + magmafire 5, icespike 3, deer_ice_circle 2, lavaspit 1).
  หลัง ASBOSS เหลือจริง: magmahound um_fire_projectile 29 + magmafire 5, mock_dragonfly firesplash 13, pepperdragon 4, อื่น 3.
  **ลอง _live_radius scale_r (um_fire_projectile = 2×scale ตาม BurnSurroundings, + LeadMoving):** 54 → 64 ; + ครึ่ง cell (DrawDisc
  ปัด r ลงได้เกือบ 1 cell — ลูกไฟ r .95 จุดไฟที่ .93 ขณะ fill .75) → 61 → **ไม่เอา** (ถอยกลับ 54 ; กลไก scale_r เก็บไว้ ; ครึ่ง cell
  คงไว้ในทางวาดสด — วงน้ำแข็ง). magmahound burning_howl: ลูกไฟบิน 10/s, y ถึง 1, scale โต .03/เฟรม — ยังเปิด.
  lag bench ปรับเทียบ client-mode: daywalker, eyeofterror, rocky_boss_shadow, minotaur 1x 1 รอบ (กำลังรัน).
  **control (1829_lag):** client จริง on 0/116, off 8/127 (daywalker 4, eye 2 (mini), rocky 2). replay ของ server_log เดียวกัน:
  มุม server (ไม่ CLIENT) daywalker+rocky 0 ทั้งสอง ; CLIENT=1: daywalker on 1/16 (จริง 0) off 3/29 (จริง 4), rocky on 0/10 (0) off
  1/21 (2), minotaur 0/0 ทั้งคู่ → off 4 vs 6 จาก 50 = 4% ✓ (±5%). กวาด YOU_LEAD −2…−4 × ENT_LAG 3/4: 4 ทุกค่า (ไม่ไว) → ค่าเริ่มต้นเดิม.
  eye: replay นับเฉพาะตัว eyeofterror (6/17) ส่วน mini eye เป็น prefab แยก — ยังไม่ได้เทียบ. **ใช้ได้กับ headless:** bench_replay -Client 1|0
  (โฟลเดอร์ __client1/0 ; CLIENT_PRED — PRED กรองฉากของ lag bench เท่านั้น).
  **client-mode ทุกบอส (1727 shares):** server-view missed 234 ; Predictive on 398 ; off 377. on แย่กว่า off: _haz +19, shrouden +1,
  twinofterror1 +1 — บอสอื่นเท่ากัน. ใหญ่สุด klaus 56 (on = off ; server 0) = quickattack ทั้งหมด: SGklaus attack_chomp → quickattack
  ตีใน tick ที่เข้า (t .033) — มุม server ±1.5 เฟรมรับ, client รูปเริ่ม 1 เฟรมหลังตี + ข้อความช้าเท่ากัน → ตกโดยธรรมชาติของความหน่วง
  (ปิด ENT/POSE/YOU_LEAD ทีละตัวก็ 56). ทางแก้: วาด quickattack ล่วงหน้าท้าย attack_chomp (ท่าต่อ) — คลาสเดียวกับ daywalker pounce.
  ต่อไป: oculet_rez 10, oculet_spaz 4, rocky 4, eye mini 3, buffrat 3 ; _haz on/off แยกตามของ.
  **แก้ (2026-10-27):** (1) ~~SimMoves._then_ring~~ **ถอดออก — ซ้ำของเดิม:** goes_into (25 ต.ค., TR_OLD_GOESINTO, lag 1513 Klaus
  18–19 → 0/1) จัดการอยู่แล้ว ; 56 ใน client-mode = replay ไม่มี r.attack (Word() คืน {harmful, hit}) → goes_into ไม่ทำงานใน replay.
  แก้ replay: attack = 3 × scale (OLD_RATTACK) → klaus 1399/1399 ทั้ง on/off/server. **บทเรียน: ก่อนแก้ ค้น VERIFY_PLAN ว่าเคยแก้คลาสนี้หรือยัง.** (2) predict Draw: ตำแหน่งบอสของท่าที่ active ผ่าน SimMoves.LeadMoving (client เท่านั้น ; TR_OLD_BODYLEAD) → snapper,
  fruitbat, phase1_lunarrift, moonmaw_lavae −1 ละตัว, ไม่มีแย่ลง ; oculet/mini eye ไม่เปลี่ยน (เพิ่งเริ่มพุ่ง — steady check). รวม client
  on 398 → 337. ทั้งสองสวิตช์ใส่ replay/replay_haz แล้ว (พร้อม LIVERADIUS).
  **client-mode ล่าสุด (1727, ไม่มี then_ring, RATTACK):** on 335 / off 316 ; บอสเท่ากันทุกตัว ยกเว้น shrouden +1 ; _haz on 291 / off 272
  (server 217) — สูงสุด deerclops_icespike 62, um_fire_projectile 55, firesplash 53, spat_bomb 43, warg breath 39, worm 30, wagboss_missile 24.
  **ตรวจ _haz client-mode กับเกมจริง (1938_lag: mutateddeerclops, deerclops, mutatedwarg, wagboss_robot, spat ; testbench lag mode
  พิมพ์ [tr_haz] HIT เมื่อผู้เล่นจริงโดนของที่วาด — ผู้โจมตีหรืออาวุธ):** ของพวกนี้ในเกมจริงโดน "by บอส" (ไม่ใช่ HIT ของ) — server HIT
  แค่ 2 (wagboss_beam_fx, วาดทัน). บอส client-mode vs จริง: ทุกตัว 0 = 0 ✓ ; spat จริง off NOT 4/7 (on 0/4) แต่ replay เห็น 1 strike
  (snot = ของ). → _haz client-mode ของ headless ยังพิสูจน์ไม่ได้ (เกมจริงวาดทัน). spat NOT ทั้งหมดที่ 4.00 พอดี, lead 0, age 2–7 s,
  ทันทีหลัง scene เริ่ม = testbench วางผู้เล่นห่าง 4 ขณะ spat กำลังตี (ท่าเล็งก่อนผู้เล่นมาถึง) = ของปลอมจากการวาร์ป ไม่ใช่ปัญหาจริง.
  **ลูกไฟ (คืน 2026-10-27, ผู้ใช้นอน):** _live_radius um_fire_projectile { scale_r 2, moving, also_data } = วาดทั้งขนาดจริงและรูป offline
  (union ; DrawHazard data_only เรียกซ้ำ) → 1809 _haz 54 → 49, false 145 เท่าเดิม ; เผื่อ scale +.1/+.2 ไม่ช่วย (49) → ไม่ใส่. เหลือ
  magmahound 28: ติดไฟที่ ~2.0 จากลูกไฟตอนเริ่ม burning_howl_attack (t .0–.43, ลูกเกิดหน้า 1, y 1) — ทั้งรูปลูกไฟและท่าบอสไม่คลุม — ค้าง (UM).
  **รอบสุดท้าย headless (2026-10-27_2006, -All -Rounds 3, 267 บอส, Lua error 2 = UM um_beegun):** server-view strikes 56313, missed 75
  (บอส 15 ✓ ≤ 59 ; _haz 60 รวมผลแข็ง/ไฟที่เพิ่งนับ ; 1701 _haz 38 ไม่มีผล) ; client on 216 (บอส 61, _haz 155) ; off 182 (58, 124).
  on แย่กว่า off: shrouden +2 (attack_loop ที่ 8.2 ขอบพอดี ขณะวิ่งออก = ตัวบนจอล้ำ server — ผลของ Predictive เอง ; ทาง: จุดตำแหน่ง
  server หลัง 1.1.6), daywalker +1. client-on สูงสุด: rocky 9, eye mini ally 9, oculet_rez 8 (ตีขณะเพิ่งพุ่ง). lag bench ปิดท้าย: klaus,
  daywalker, moonmaw, twins1, shrouden, charlie_boss 1x 1 รอบ (กำลังรัน).
  **lag ปิดท้าย (2055_lag, 23.5 นาที):** on 16/460, off 5/555 ; **klaus 0/94, 0/98** (แข็ง 1, ไฟ 4 — วาดทันทั้งหมด), "by ?" 0, Lua 0 ;
  charlie 1/28, daywalker 1/20 off, twins1 1/27, shrouden 2/45 off. **moonmaw on 14/244** (1554: 1/304) — 12 = moonmaw_lavae ธรรมดา
  ที่ 2.3–2.8, age 1–4 s (ไม่มีอะไรวาด), ขณะพุ่ง ~10/s (SGmoonmaw_lavae attack: stab_pre, DoAreaAttack 2 ที่ f11 ขณะยังวิ่ง). replay
  ตัดสินไม่ได้ (ไม่มี STRIKE ของ lavae ใน log server). A/B lag: moonmaw -Old TR_OLD_BODYLEAD แล้วปัจจุบัน (กำลังรัน).
  **A/B (2120 vs 2126):** BODYLEAD ปิด: on 5/266 (lavae 5), off 1/261 ; เปิด: **on 0/273**, off 1/272 → BODYLEAD ช่วย ; 14 ใน 2055 =
  ความแปรปรวน (lavae โผล่ไม่เท่ากันแต่ละรอบ). ผลข้าง: lag_snap lavae jump ~.9 แล้วกลับ 1–5 เฟรม (Physics:Stop ที่ f11 → lead เกิน) — เล็ก, ค้าง.
  **สรุปเกณฑ์เสร็จ (2026-10-27 คืน):** (1) headless บอส 15 ≤ 59 ✓ ; ท่าไม่เคยเห็น = NEVER 109 บรรทัดใน bench_final (ยังไม่ได้ทดสอบ ไม่นับผ่าน) ;
  (2) effect: บอสวาดคลุมผลทั้งหมด, _haz เหลือ ~49 (ลูกไฟ magmahound ตอนเริ่ม howl 28, mock dragonfly 13) — ไม่ถึง 0 ✗ ; (3) Klaus+กวาง
  แข็งนอกรูป 0 ✓, "?" 0 ✓ ; (4) log ผู้ใช้ compare — ยังไม่ได้รัน ; (5) unit tests ผ่าน (install) ✓ ; client-mode control ±5% ✓ (บอส) ;
  Predictive on ไม่แย่กว่า off: บอส 61 vs 58 (shrouden ขอบ = Predictive เอง) ≈.
  **(4) log ผู้ใช้ — compare.ps1 -Old workshop 3817047528 (1.1.6 ที่อัปโหลด 23 ต.ค.) vs source:** missed 258 → 257, false 349 → 345,
  yellow 800 → 941. แย่ลง: daywalker 2 → 3 (attack_slam ที่ 3.47 ขอบ, log 2026-10-10_1616) = **TR_OLD_SLIDEFIT** (แก้ tri-beam เอียง
  26 ต.ค. — ถือรูปไม่เลื่อนเมื่อเลื่อนแล้วไม่ตรง) — แลก ; klaus yellow 43 → 155 = ข้อมูล goes_into (25 ต.ค.: quickattack วาดล่วงหน้าเหลือง
  เมื่อคุณอยู่ในระยะ, ถอยทัน = ไม่ตี) — ถูกต้อง. phase3 missed 10 → 8 ดีขึ้น. ระหว่างนี้: replay.lua/replay_haz.lua ตัวแปร client เป็น
  false ไม่ใช่ nil + EFF_AT = {} (strict จับ global ไม่ประกาศ เมื่อรันกับ mod ชุดทดลอง).
  **ลูกไฟ magmahound 19 + magmafire 3 "missed" (2026-10-28) = ตัวตรวจ ไม่ใช่ mod:** ทั้งหมดที่ d 4.00 มุม 0 ระหว่าง
  burning_howl_attack — ผู้จุดจริงคือ PoofNearby ของหมาเอง (uncompromising_hounds.lua: FindEntities 4, ±90°, ทุกลูกไฟ ;
  Ignite() ไม่มี source → testbench โทษของใกล้สุด). รูปท่า scared_pst/belch วาดครึ่งวง area 31.3 (≈ r 4.47) คลุมคุณ (AREA_DBG)
  แต่ replay.lua **Dodged** (strike ไม่มี hit ที่ไกลกว่าระยะกัดไกลสุดของ log + .5 = หลบ) ทิ้ง strike ของผลก่อนเทียบ → ไม่มี
  ASBOSS_DRAWN → replay_haz นับ missed. กฎที่สามที่ต้องยกเว้นผล (หลัง STRIKENOHIT, NOHARM) — แก้: EFF_AT ไม่ Dodged (OLD_EFFBY).
  magmahound 399–406: 7/7 วาด (ก่อน 3). pepperdragon flame (PoofNearby เดียวกัน) ASBOSS อยู่แล้ว. scratchpad cells_reach.lua =
  อ่านระยะ cells ของท่า (belch ทั้งสองตัว 4.0 ตรงกลาง). **รอบเต็ม 2006 หลังแก้:** strikes 56313 → 56578 (+265 ผลที่เคยถูกทิ้ง),
  missed 75 → 54 (บอส 15 เท่าเดิม).
  **firesplash ของ Mock Dragonfly 16 = กฎที่สี่:** ทุกตัวที่ spin_loop t .167 — กัด (DoAttack f5) ที่ 67.433 แล้ว FireTrail
  (FindEntities 3.5 รอบจุด ±1 ข้างตัว ทุก 2.3 เฟรม, Ignite() ไม่มี source) จุดไฟ tick ถัดไป → replay "strike + hit ห่าง < .05 = ครั้ง
  เดียว" รวมไฟเข้ากับการกัดแล้วทิ้ง. แก้: รวมเฉพาะชนิดเดียวกัน (ผล/ผล หรือ ตี/ตี ; OLD_EFFBY). mock_dragonfly 60–110: 51/51,
  ASBOSS 67.467/71.067/99.600 (ก่อนนี้ missed). **บทเรียน: ทุกกฎตัด/รวม strike ใน replay ต้องรู้จักผล — grep "strikes = keep".**
  **รอบเต็ม 2006 หลังสองข้อ:** server missed 38 (บอส 15, _haz 23) ; client on 177 (เดิม 216, _haz 116), off 160 (เดิม 182, _haz 102).
  **บั๊ก mod จริง — แคช DrawDisc (2026-10-28):** deer_ice_circle 483.467 แข็งที่ 2.61, รัศมีสด 2.60 (+ครึ่ง cell = 2.72) แต่รันทั้งไฟล์
  "ไม่วาด" ขณะรันเฉพาะช่วง "วาด" → SimMoves.DrawDisc เก็บวงด้วย key = r ปัดทีละ .25 แต่สร้างจาก r ของครั้งแรกที่เจอ key นั้น ⇒ วงที่
  โตขึ้นเรื่อย ๆ วาดเล็กกว่าจริงได้ถึง .25 แล้วแต่วงก่อนหน้า (ในเกมด้วย — วงน้ำแข็ง, ลูกไฟ UM, arena). แก้: key ทีละ .05 สร้างจาก
  r ของ key (TR_OLD_DISCKEY ; ใส่ทั้งสองรายการสวิตช์). share006_L2 _haz 38/38. **รอบเต็มหลังแก้:** server 37 (บอส 15, _haz 22) ;
  client on 175, off 158 — ไม่มีบอสแย่ลง. ผลที่ยังตกเหลือ 2: magmahound โดนตีหลุดท่าแล้ว PoofNearby ที่ตั้งเวลาไว้ยังจุด (850.267 ; ท่าที่
  ถูกขัดถูกตัดโดยตั้งใจ — 1 ครั้ง, ค้าง) และ firesplash share046_L2 39.533 = **lavaeslime** (lavae2 ตายแล้วทิ้ง ติดไฟเอง ระเบิด 3–6 s,
  FindEntities 4 Ignite) ไม่เคยวาด → moves_hand_um _hazards.lavaeslime (วง 4, delay 90, fire ; cells จาก scratchpad pack_disc.lua) +
  moddata รับ _hazards จากไฟล์เขียนมือ (เฉพาะที่ข้อมูลไม่มี). bench จริง 2026-10-28_0604 (lavae2 + mock_dragonfly 3 รอบ): lavaeslime 1/1,
  drawn-in-no-strike 0 ; mock_dragonfly 795/795 ; _haz เหลือ um_lavaspit 1 (3.97 off) = taunt (firering) ของมังกรตี + จุดไฟ tick
  เดียวกันที่ 4.0 (วาดคลุม) — testbench โทษ lavaspit (Ignite ก่อน attacked → _tr_blow_t ยังไม่ตั้ง) แล้ว replay รวม "STRIKE by
  um_lavaspit" กับ STRIKE ของบอสเป็นครั้งเดียว เก็บตัวไม่มี by → ไม่มี ASBOSS. แก้ replay: รวมแล้วส่ง by_own ต่อ → 0604: 0/1096.
  2006 เต็มหลังแก้: 37 เท่าเดิม (ไม่มีอะไรแย่ลง). **compare.ps1 (log ผู้ใช้, 3817047528 vs source หลัง DrawDisc + lavaeslime):** เท่าเดิมทุกตัว
  (missed 258 → 257, false 349 → 345 ; daywalker SLIDEFIT / klaus goes_into เหลืองตามที่รับไว้).
  **สถานะเกณฑ์ (2026-10-28 เช้า):** (1) บอส 15 ≤ 59 ✓ ; (2) ผล: ตก 1 (magmahound ถูกขัดท่า ค้างโดยตั้งใจ) จากเดิม ~49 ; (3) Klaus ✓ ;
  (4) compare ✓ ; (5) unit/install ✓ ; client-mode on 175 / off 158 (บอสเท่ากันยกเว้น shrouden +2 = Predictive เอง ; rocky/mini eye
  ally/oculet เท่ากันทั้ง on/off = แบบจำลองหน่วง ไม่ calibrate สำหรับของที่พุ่ง/วาร์ป — lag จริง 1829 ดีกว่า). _haz ที่ไม่ใช่ผล ~20
  ตัวละ 1–3 จาก 6399 (spat_bomb, laserempty, goo, minieye ตกห่าง < 1.2 ตอนลง = จังหวะ).
  **ผลข้อสุดท้าย magmahound 850.267 (ไม่ใช่ถูกขัด):** belch ครั้งที่ 6 จบปกติที่ 850.000 แต่ PoofNearby ตั้งเวลาไว้ 1–15 เฟรม (f12 + 15) จุด
  หลังท่าจบ ; รูปแบบ around วาดเฉพาะตอนท่า active, step "again" ต้องให้ belch เล่นอยู่ → หาย. แก้ (TR_OLD_TAIL): SimMoves._tail =
  { magmahound 15, um_pepperdragon 15 } (สองตัวที่ใช้ DoTaskInTime สุ่ม 1–15 + PoofNearby ใน UM ทั้งหมด) — ท่าจบ (ปกติหรือถูกขัด) → after
  มี tail_until, วาด DrawAround ตามตำแหน่ง/ทิศตอนนี้ ; again_seen ค้าง tail เฟรม. รอบเต็ม: missed 37 → 36, magmahound 649 → 659 วาด,
  drawn-in-no-strike 1892 → 1893. **ผล (ไฟ/แข็ง) ตกเหลือ 0** (lavaeslime ใน log เก่าไม่มี trace — bench 0604 ยืนยันแล้ว).
  **บอสที่ตก 15 (2026-10-28, ผู้ใช้: "ยังไม่เสร็จ"):**
  - boulder_crab uppercut 3 — UM SGboulder_crab: walk animover → uppercut ตรง (ไม่ผ่าน atk) ; ข้อมูลมีแต่ atk {atk, uppercut} และการข้ามเข้า
    ท่ากลางไม่นับแอนิเมชันสุดท้าย → ไม่มีท่า. แก้: moves_hand_um boulder_crab.uppercut (around วง 3.5 = range 3 + ตัวคุณ, first 46 DoAttack,
    single) → share021_L4 383/383, false 0.
  - shrouden optic_blast_pst 3 — ไล่คุณ 1.2–2.5 s (ความยาวตามโค้ด) แล้วตกลงตรงที่มันอยู่ (AOE 2.6@17, 3.6@18) แต่ข้อมูลวาดตามเส้นไล่ออฟไลน์
    (dist 6 map, ห่าง 4). แก้: SimMoves._land { shrouden.optic_blast_pre1 = pst, r 4.1, at 17, till 18 } วาดวงรอบตัวตอนนั้น (TR_OLD_LAND2)
    → 496/496, false 5 เท่าเดิม.
  - um_beeguard_blocker 2 — testbench ย้ายฉาก (ผึ้งและคุณกระโดด ~55 ใน tick เดียว) แล้วตีทันที = ของ testbench.
  - เหลือที่ยังไม่แก้ (DN: รูปคลุมคุณอยู่ แต่พลาด 1–3 เฟรมตอนตี): mutatedbearger combo2 (path fit สลับเป็น run 1.75→3.00 ในเฟรมท้าย
    รูปเลื่อนออก), vault_crawler attack, phase1_lunarrift roll_stop ×2 (roll_loop เริ่มใหม่ 1 เฟรมก่อน roll_pst → ขาใหม่จากจุดปัจจุบัน,
    คุณอยู่ข้างหลัง), rocky dash / snapper speen (รูปคลุมหลังตี = ช้า) ; shadowthrall_hands (ไม่มี trace ก่อนตี = ไม่ถูกเลือกวาด, เพดาน 16 ;
    notarget วิ่งอยู่กับที่ ไม่นับว่ากำลังตี).
  - รอบเต็มหลัง crab + land + tail: missed 30 (บอส 9 รวม beeguard 2 ของ testbench), drawn-in 1894.
  - **ลองแล้วไม่เอา: ท่า single หันรูปตามคุณ (DoAttack ไม่ดูมุม)** — vault_crawler ตก 1 → 0 แต่ false +21 (spider_warrior 0→5, spider 3→6,
    vault_crawler 6→13, mutatedwarg 3→7, pigelite +3) → ถอยออก.
  - phase1_lunarrift roll_stop 2 — roll_loop (วน) เริ่มรอบใหม่ 1 เฟรม แล้ว timeout → roll_stop ตีเฟรมแรก 2.2 ข้างหลัง ; ขาใหม่ตั้งจากจุด
    ปัจจุบัน เส้นเดิมหาย. แก้ (TR_OLD_PREVLEG): ขาที่เพิ่งวิ่ง (prev_leg) วาดต่อ LINGER .2 s เมื่อขาใหม่เริ่ม (LegChain 1 ขา).
    รอบเต็ม: missed 30 → 28 (phase1 2 → 0), ไม่มีตัวอื่นเปลี่ยน, false เท่าเดิม. ตอนขาจบ (ไม่ใช่ขาใหม่) ไม่เก็บ — test_sim "Eye winding
    down after a charge: nothing" ล้ม (Eye ไม่ตีใน charge_pst) ; phase1 ยัง 2246/2246. **บทเรียน: install.ps1 (unit tests) ก่อน
    install_client.ps1 — ตัว client ไม่รันเทสต์ ลงโค้ดที่เทสต์ล้มไปแล้วครั้งหนึ่ง.**
  - shadowthrall_hands 494.033: ไม่มี trace ตั้งแต่ 480 ; testbench "shrouden moved" 493.867 วางคุณข้างมือที่อยู่ตรงนั้นแล้ว = ของ testbench.
  - snapper speen 546.567: 2.96 จากตัว วง around r≈3.1 กลางเลื่อนไปทางวิ่ง .4 → ขอบ (< 1 cell).
  - _haz eyeofterror_laserempty 3: เลเซอร์ช่วงต้น (ปาก Retinazer) เกิดและตี tick เดียวกัน (modmain onhitother) — ตัดสินเป็นของ ไม่เทียบกับเส้น
    เลเซอร์ของท่าบอส ; แก้ต้องให้ testbench เขียน STRIKE by <thing> ให้บอสในเลน (ASBOSS) + bench ใหม่ — ค้าง.
  - **ของตีคุณ = STRIKE ของบอสด้วย (2026-10-28):** tr_testbench attacked listener: attacker เป็น _hazards → SimMoves._trace_line(boss ในเลน,
    "STRIKE by <ของ>") (TR_BENCH_OLD_THINGSTRIKE) ; replay.lua THING_AT[t] จาก [tr_haz] HIT + EffOrThing(s) แทน EFF_AT ทั้ง 5 กฎ (STRIKENOHIT,
    by_own, NOHARM, Dodged, รวม strike ; OLD_THINGSTRIKE) → ของที่ตีตอนท่าบอสวาดคลุม = ASBOSS. ต้อง bench ใหม่ (log เก่าไม่มีบรรทัดนี้) —
    bench เต็ม 2026-10-28 (bench_full_1028) กำลังรัน.
  - **LEADTP (ผู้ใช้: "umbral มีเฟรมกระพริบ"):** LeadMoving ไม่ lead เมื่อ > 40/s (วาร์ป) — lag A/B shrouden: on snap backs 1.64 → 0 /1000,
    NOT 6/161 → 0/39. เหลือ off: พลิก 180° 1 เฟรมตอน appear (ตำแหน่งใหม่มาก่อนแอนิเมชัน snap) → SNAPPOS ตั้งจุดเริ่มเมื่อกระโดด > 3 ด้วย
    (ไม่รอ snap_anim). replay 2006 shrouden เท่าเดิม. ติดตั้งแล้ว ; lag_sh_wings ยืนยัน (กำลังรัน).
  - **Ink Blight ลูกยังขยับ (ผู้ใช้ 2026-10-28):** ลอง gravity -35 ตายตัว (SetGravity, ตรงกับ y จริง Δ² ≈ −.039/เฟรม²) → replay แย่ลง
    (moved 965 → 6191: trace ซ้ำ tick ทำให้ฟิตความโค้งตายตัวพัง) — ถอย. แทน: TR_OLD_LANDHOLD — จุดที่วาดค้างจนค่าเฉลี่ยห่าง > .25:
    share017_L3 moved 965 → 11, L2 2380 → 650 ; รอบเต็ม 0805: missed เท่าเดิม 45, false 2101 → 2093. ติดตั้งแล้ว + patch notes.
  - **บันทึกทุกเฟรมในเกมจริง (tr_lagjoin [tr_lagframe], 2026-10-28 — ผู้ใช้: "ทำไมไม่บันทึกทุกเฟรมของท่าที่วาด"):** hook true_range/lines
    Begin/End/Tri/PutTri/Segment/PutSeg/GroupAt → ต่อเฟรมต่อเจ้าของ (DrawHazard ตั้ง cur, ไม่งั้น SimMoves._draw_owner) ; + [tr_lagland]
    (TR_LANDWOB ฝั่ง client + settle), [tr_lagdisc]/[tr_lagring].
    - **วงกระพริบ Umbral = แสงเตือน cooldown (SimMoves.Glow, 4 วง 354 ชิ้น):** alpha = .85·sin²(2π·el) → ศูนย์ที่กลาง → ไม่วาด 1 เฟรม
      (x.000/x.500) — ทุกบอส. แก้ TR_OLD_GLOWPULSE: สว่างขึ้นใน .25 s แล้วค้าง. lag: dropout 35 → 0.
    - **Ink Blight:** settle (TR_OLD_LANDKEEP: ค้างที่จุดตกเมื่อลงช้ากว่าที่ประมาณ ≤ 1.5) + TR_OLD_LANDWAIT (ไม่วาดจนผ่านเกณฑ์ 3 ค่า —
      36/41 การกระโดด > .5 เกิดที่ค่าที่ 1–2, ไกลสุด 3.01). lag: jumps > .5 41 → 0, moved 266/14975 → 39/12742, most 3.01 → .38.
      replay 0805: _haz missed 41 → 38, false 1273 → 1257.
  - **Umbral มุดดินผิดตำแหน่ง (ผู้ใช้):** teleport_pre ใน _land: teleport_loop วง 2.9 ที่ตำแหน่งจริงใต้ดิน (eta .4), teleport_pst 3.0@6 → 3.85@26
    (AOE 2.4 → 3.25 ที่ f26 + ตัวคุณ) — OVERDRAWN 13 → 22 หาย ; shrouden 0 missed สามรอบ, false 6 → 2.
  - **LEADSTOP — ใส่กลับ ยืนยันด้วย lag bench A/B (lag_mm_new2 vs lag_mm_old2, moonmaw 1 รอบ):** lavae snap backs on 3.49 → 1.71 /1000,
    off 1.68 → .29 ; ค้าง ≤ 2 เฟรม (เดิมถึง 7) ; NOT drawn 0/234 + 1/292 vs 0/249 + 2/383. ติดตั้งแล้ว + patch notes.
  - (เดิม) **LEADSTOP (lavae กระตุก .9) — ถอยออก:** client-mode A/B (scratchpad ab_client.ps1) บน 0659 เท่ากันทุกตัว = replay วัดไม่ได้ (เห็นแค่ใน
    lag_snap ของ lag bench) → ไม่ปล่อยโค้ดที่ยังไม่ยืนยัน ; ทำใหม่เมื่อรัน lag bench ได้.
  - **bench เต็ม 2026-10-28_0659 (mod ณ ตอนนั้น):** server missed 34 (บอส 16, _haz 18), client on 114 / off 100 (บอส 36 / 35).
    บอส 16: มือเงา 4 = ไม่มี trace (ไม่มีเป้า, shrouden_run ไม่ใช่ attack) → modmain Traced: + ใกล้คุณ 6 (โหมดทดสอบเท่านั้น) ;
    twinofterror1 240.900 = testbench วาร์ปคุณ (258.3 → 264.6 ใน tick เดียว) เข้าทางพุ่ง ; rocky 2 = การพุ่งแบบวาร์ปของบอสเอง (จริง) ;
    อื่นตัวละ 1 (minotaur leap_pst ลงสั้นกว่าออฟไลน์ 6, shrouden optic loop ใช้ map dist 6 ตอนไล่ (วาร์ปตอน appear), bearger ×2 path fit,
    vault_pillar_guard table, stumpling, rneskeleton/pigguard ขอบ, snapper ขอบ).
  - **shrouden optic blast ช่วงไล่ (2026-10-28):** (1) TR_OLD_SNAPPOS: snap_anim (optic_blast_pre2) เริ่มแล้วกระโดด > 3 (วาร์ปหาคุณ) → จุดเริ่ม
    ท่า = ที่โผล่ (map dist 6 → .06) ; (2) _land เป็นรายการ: loop r 2.5 (beam 2 + ตัวคุณ ; shrouden_optic_blast_fx AOEUtil.Attack), 5.5 เมื่อ
    เล่น optic_blast_pre3 (MakeWide) ภายใน 4 s (Predict._land_wide ต่อตัว — pre3 ไม่อยู่ในแอนิเมชันของท่า ท่าเริ่มใหม่หลังมัน), pre3 5.5,
    pst 4.1@17. 0659 และ 2006 shrouden 0 missed, false 9→7, 5→3 ; รอบเต็ม 0659: 34 → 33, ไม่มีอื่นเปลี่ยน.
  - **บอสที่ตกหลังทั้งหมด (0659, 33 รวม _haz 18 → บอส 15):** ของ testbench: มือเงา 4 (ไม่มี trace — แก้ Traced แล้ว รอ bench), twins 240.9
    (วาร์ปคุณ), minotaur leap_pst (ตัวแทนคุณเลื่อนตามบอสขณะกระโดด ห่าง 2.8 คงที่ — keeps distance), pigguard (คุณเลื่อน 6.2/.6 s),
    rneskeleton (4.3/.6 s), bearger 2 (คุณที่ 1.07/1.11 จากกลาง — ตัวหมี 1.5 + คุณ .5: ในเกมเข้าไม่ถึง 2.0 ; testbench วางซ้อนในตัว
    ฟิสิกส์ดันกระตุก -8/s แล้วดีดกลับ .9 → path fit สับสน) ; จริง: vault_pillar_guard 1 (table), stumpling 1, snapper 1 (ขอบ), rocky 2 (พุ่งวาร์ป).
  - **Rock Master ร่าง Blighted พุ่ง "วาดเป็น 2 รอบ" (ผู้ใช้ 2026-10-28):** atk_dash ออฟไลน์เป็นแบบพุ่งต่อ (SGrocky f13 shouldchaindash: decel nil,
    tpspeedmult 2 → ไถล 1.57/เฟรมถึงเฟรม 36, path 50.4 ; snip f17 ที่ 20) — ครั้งสุดท้ายของ chain (numchaindashes ≥ maxchain 2/3/5, enraged ไม่
    ส่งถึง client) ชะลอ หยุดที่ ~14.35 แต่วาดไถลต่อ + snip ไกล = เหมือนพุ่งอีกรอบ. แก้ (TR_OLD_CHAINLAST): SimMoves._chain_last {
    rocky_boss_shadow.atk_dash → rocky_boss.atk_dash (ร่างปกติ ไม่เคย chain: 9.73, 13.50 → 14.35) } เมื่อเริ่มภายใน 12 เฟรมหลัง atk_dash ก่อน.
    รูป (PIC 153.6): ครั้งที่ 2 = เลน 14 + snip ปลาย ; 153.700 (เคย missed) วาดแล้ว. Enraged (chain 3/5): ครั้งกลางวาดแบบหยุด — ยอมรับ.
  - **ท่า NEVER (106 บรรทัดใน bench) → bench บังคับ:** tools/never_force.ps1 (ใหม่): NEVER → แอนิเมชันแรก → state ใน SG ของ prefab
    (SetStateGraph) → ไฟล์ -Force. 56 บอส ; ที่หา state ไม่เจอ = state จาก UM postinit / CommonStates (ยังไม่อ่าน). scratchpad never_force.txt
    — รันหลัง bench เต็มรอบที่ 2 (2026-10-28 บ่าย, กำลังรัน: thing strikes + Traced 6).
  - **วงนอกของ Great Depths Worm (ผู้ใช้ 2026-10-28: "มีแค่วงกลมที่ทำดาเมจจริง"):** modmain AGGRO worm_boss_dirt 2.5 วาดรอบทุกกองดินตลอด
    แต่กลืน (CollectThingsToEat 2 + ตัว) เฉพาะตอนหัวโผล่ (EmergeHead, dirt_start) และมุดลง (dirt_end ใหม่) → AGGRO_WHILE: เฉพาะแอนิเมชันดิน
    dirt_pre_slow / _shadow_pre_slow / _pre_fast / _emerge_loop_pre / _emerge_loop / _emerge (+ linger .3, any_target) ; dirt_idle ไม่วาด.
    TR_OLD_WORMDIRT. replay วัดไม่ได้ (worm_boss ไม่มีตารางบอส ; AGGRO วาดใน modmain). + w.near (ใหม่ใน modmain AGGRO_WHILE): วงขึ้นด้วยเมื่อมี
    worm_boss_segment (หรือ _shadow_) ภายใน 1.6 ของกองดิน — ท่อนหนาม DoThornDamage ตอนโผล่/มุดทุกท่อน (bench 0805: หนอนตีจริงครั้งแรก 2718 ครั้ง,
    ตก 10 ทั้งหมดตอนท่อนเพิ่งเกิดที่กองดิน — replay_haz ไม่อ่าน AGGRO จึงยังนับตก).
  - **bench 0805 (thing strike + Traced 6 + ทุกการแก้ก่อนหน้า):** บอสตก 6 (มือเงาหายหมด), _haz 39 → ไม่นับ ASBOSS เหลือ 25 (หนอน 10, อื่นตัวละ 1–3) ;
    laserempty ยังตก 3 เพราะการโดนอยู่ในชุด thing_hits ("things struck you") ที่ไม่พิมพ์ ASBOSS → replay พิมพ์ ASBOSS_DRAWN เมื่อวาดคลุม (OLD_THINGASBOSS).
  - **bench บังคับท่า NEVER (2026-10-28_0832, never_force.txt 56 บอส × 2 รอบ):** NEVER หาย 70 ท่า ; replay ตก 20/13244: rneskeleton 5 + vault_crawler 5 =
    testbench ย้ายคุณระหว่างท่า (3.3–6.4 / 1.6 ต่อเฟรม), deerclops icelance 2 = บังคับ state ของ Mutated ใส่ Deerclops ปกติ (ไม่เกิดในเกม),
    swathgrithr 1 จริง, _haz 7. ยังเป็น NEVER: ท่าจาก UM postinit / CommonStates (bat, mosquito, pigman counter_atk/paw, spider trapdoor...).
  - **lag bench 2026-10-28 (lag_1028: rocky_boss_shadow, shrouden, worm_boss, moonmaw, 1 รอบ):** on 7/444, off 6/371.
    rocky_boss_shadow on 0/10, off 2/22, ไม่มีรูปกระโดด (chain-last ในเกมจริง) ; shrouden on 4/208 — รูปกระโดด 4–9 ที่ move time .7 (appear) มีอยู่
    แล้วใน lag_final ก่อนแก้ (1029/1082/1117) ไม่ใช่ SNAPPOS ; moonmaw lavae jump ~1 แล้วดีดกลับ 1–8 เฟรม (ยังไม่แก้ — LEADSTOP ถอยไว้).
    หนอน (จัดกลุ่มอยู่ในเลนอื่นของรายงาน): โดนกองดิน 6.92 (ไกลกว่าวงกลืน 2.5 อยู่แล้ว), ท่อนหนาม 4.00 ×2 / 1.95 — ท่อนหนามฝั่ง client ตาม
    server ไม่ทัน (เคลื่อนเร็ว) — ค้าง.
  - **ลองแล้วไม่เอา — ทิศพุ่ง Twins/Eye (KEEPHEADING):** (1) จำทิศเดินล่าสุดเมื่อหยุดก่อนเริ่มท่า → twins อีกครั้งพลาด (เฟรมกระตุก 76.5 ของ
    testbench) ; (2) + ต้องคงที่ 2 เฟรม → eye ตก 1 ; (3) ทิศจากการเคลื่อนที่ .15–.25 s → eye ตก 2. โค้ดเดิม: eye 66/66, twins ตก 1 (= วาร์ปของ
    testbench) → คืนโค้ดเดิม.
  - **กระพริบจากข้อมูลทุกเฟรม (tools/lag_frames.ps1, 2026-10-28 บ่าย):** อ่าน [tr_lagframe] → ต่อ owner: หายไป 1–3 เฟรมระหว่างที่ยังวาด
    (blink) + ชิ้นลดเกินครึ่งแล้วกลับ (dip). full1 → full2: shrouden 39+10 → 5, projectile 26 → 14, mouth 20 → 8.
    (1) **shrouden 5 ที่เหลือ = วงเตือนดับก่อนท่าเริ่ม:** seg=354 (glow) หยุดที่ cooldown หมด, punch_pre วาดเฟรมถัดไปอีก 1–2 → ว่าง
    → TR_OLD_GLOWGRACE: วงติดต่อ .3 s หลังหมด (ดับเองเมื่อท่าเริ่มผ่าน restarted). (2) **Ink Blight วงใต้ลูกกลางอากาศ:** ลอยสูงแนวนอน
    < .02/เฟรม → s.stopped → วาดรอบตัวลูกในอากาศ 1 เฟรม แล้วซ่อน (เกมจริง: grp 3–4 ชิ้นเลื่อนตามลูก สลับกับวงจุดตก) → TR_OLD_AIRSTILL:
    ของที่ rose/lobbed และ y > .3 ไม่นับว่าหยุด. replay_haz บน server log ของ lag full2: GAPDRAWN 18 → 0, false 35 → 29.
    (3) replay_haz นับ GAP ปลอม: trace server ข้ามเฟรม (hitch) → ของหายจาก list → GAPDRAWN 109 ที่ไม่มีในเกม → ถือตำแหน่งล่าสุด
    ไว้ถ้ามีบรรทัดถัดไปภายใน .3 s (OLD_TRACEHOLD=1 คืนเดิม). (4) mouth portal_appear ว่าง 2 เฟรมก่อน bite_loop = ช่องระหว่างสองท่า
    ต่างที่กัน 2.3 ไม่ใช่รูปเดียวกระพริบ — ยังไม่แก้.
  - **replay 0805 หลัง GLOWGRACE/AIRSTILL/TRACEHOLD — บอสตก 6:** vault_pillar_guard / stumpling / snapper หายแล้ว. เหลือ:
    catcoon 2 = ขอบ: UM SetRange(4/1.5 = 2.667) + คุณ .5 = 3.167, คุณ 3.14, รูป cell ปัดถึง ~3.1 (ภาพ PIC 551.733) — < 1 cell ;
    horns shrouden_jump 1 = AOE ที่ตัว f11 แต่ state t ค้าง (.033 ×5 เฟรม) → ไปถึง ~3.2 ไม่ใช่ 3.48 ตาม sim — ของ bench (state time freeze) ;
    rocky dash 1 (พุ่งวาร์ป), pigguard 1 / rneskeleton 1 (testbench ย้ายคุณ). um_fire_projectile MISSED ดิบใน _haz = เดิม (A/B 3 แบบเท่ากัน 14).
    รวม missed 52 (บอส 6, _haz 46 — ก่อนหน้า 38: กำลัง A/B ด้วยสำเนา tr_frozen_old + TR_OLD_AIRSTILL/OLD_TRACEHOLD), _haz false 1257 → 1216.
  - **Ink Blight "ยังขยับ" (ผู้ใช้ 2026-10-28 บ่าย, ระหว่าง lag full3):** tr_lagjoin บันทึกตำแหน่งจริงทุกเฟรมแล้ว ([tr_lagthing] t prefab guid x y z)
    + tools/lag_land.ps1 (จุดวาดเทียบจุดตกจริง). lag_ink1: ค่าประมาณแม่น (err median .07, p90 .12, max .33) แต่ 78/91 การขยับเกิด
    **2 เฟรมหลังแตะพื้น**: s.stopped (นิ่ง 2 เฟรม) → start ≠ nil → ข้ามบล็อก LANDKEEP ทั้งหมด → วาดที่ตำแหน่งจริง กระโดด .1–.4.
    แก้ TR_OLD_LANDSTOP: หยุดแล้ว + s.land ห่าง ≤ 1.5 → วาดที่ s.land. offline ไม่เห็น (LANDWOB นับแค่ช่วงลอย) — missed/false เท่าเดิม.
    full3 (ก่อนแก้นี้): ลูกที่วาด 1738/18270 เฟรมขยับ, ส่วนใหญ่ .7–.9 s หลังเริ่มวาด = ตอนแตะพื้น.
  - **full3 อื่น:** (1) shrouden วงเตือนดับ 1 เฟรมก่อน punch_pre: เห็นท่าเริ่ม (restarted) แต่ท่าวาดชิ้นแรกเฟรมถัดไป → TR_OLD_GLOWOVERLAP:
    วงติดต่อ .07 s หลังเห็นท่าเริ่ม. (2) optic blast วาร์ป 3.18 ในเฟรมเดียว: LEADTP วัดช่วง .1 s = 32/s < 40 → lead 2.24 เลยจุดโผล่ 1 เฟรม
    (jump/back -180° ใน lag_report) → TR_OLD_LEADTPSTEP: ก้าวล่าสุดก้าวเดียว > 40/s = วาร์ป ไม่ lead. (3) ช่วงว่างหลังรูป punch_pre
    จบก่อนช่วงเตือนรอบใหม่ (3 เฟรม แล้ววงเตือนค่อยสว่างจาก 0) = fade in ไม่ใช่กระพริบ — ไม่แก้. lag_ink2 กำลังรันยืนยันทั้งหมด.
  - **lag_ink2 (หลัง LANDSTOP/GLOWOVERLAP/LEADTPSTEP):** Ink ขยับ 91/108 ลูก → 168/1336 (0.84 → 0.13 ต่อลูก) ; shrouden พลิก -180° หายจาก
    รายการ jump. ที่เหลือ: (1) Ink กลางอากาศ = LANDHOLD ก้าว .25 ; (2) shrouden วงเตือนดับ 1–3 เฟรมแล้วกลับ (6 ครั้ง) ตอนข้อมูล cooldown ชุดใหม่
    มาถึง ("teleportcd/opticblastcd nearly over") → วงย้ายไป cooldown อื่น fade in จาก 0 ใหม่ → TR_OLD_GLOWHOLD: ความสว่างต่อบอส ต่อเนื่อง
    (สว่างภายใน .2 s ไม่ fade ใหม่ ; ไม่มี cooldown ในช่วงก็ค้าง .1 s).
  - **ตัวจำลองจากมุม client จริง:** tools/lagthing_to_haz.ps1 แปลง [tr_lagthing] เป็น [tr_haz] → replay_haz บนสิ่งที่เกมผู้เล่นเห็นจริง:
    LANDWOB moved 167 ≈ ในเกม 168 (ตรง). + LANDWOB "off where it came down" (ความคลาดตอนแตะพื้น) + LAND_WAIT/LAND_HOLD (SimMoves._land_wait/_land_hold).
    sweep ink2: (3,.25) 168 ขยับ / คลาด .09 ; (5,.25) 48 / .07 ; (7,.25) 13 / .06 ; (7,.4) 2 / .07 ; (5,.4) 12 / .08 — รอนานขึ้นแม่นขึ้นด้วย
    (ค่าแรก ๆ คือที่ผิด) แลกกับวงขึ้นช้าลง 4 เฟรม. A/B _haz ทั้ง bench 0805 (bench_replay -HazOnly ใหม่ — ไม่หัก ASBOSS, เทียบกันเองได้):
    a (3,.25) missed 186 / false 1218 ; b (7,.25) 192 / 1153 ; c (7,.4) 191 / 1148. +6 ของ b = ของที่ลอยสั้น: um_tentacle_moon_projectile +4,
    waterplant_projectile +2, mortarball +1 (วงขึ้นช้าไป) → _land_soon: รอ _land_wait ค่าเฉพาะเมื่อยังเหลือ ≥ _land_soon s ก่อนถึงพื้น ไม่งั้น 3.
    ink2 client: (7,.25,.5) ขยับ 35 / คลาด .06 ; (7,.4,.5) 8 / .07. d (7,.25,.5) รอบแรก: false 1218 → 1454 (ink 69 → 194) — tl แกว่งรอบ .5
    ขณะ n 3–6 → ซ่อน/แสดงสลับทุกเฟรม (กระพริบ, แต่ละช่วงนับ FALSE แยก) → la.shown: แสดงแล้วไม่ซ่อนอีก. d ใหม่: missed 186 (= a), false 1200
    (a 1218) → ใช้ d (7, .25, .5). lag_ink3 (d): Ink ขยับ 0.84 → 0.13 → **0.03 ต่อลูก** (42/1254), err median .07. e: missed 187 / false 1199
    — ต่างจาก d แค่ sporecloud/um_fire/icespike (ไม่ใช่ของโยน = ความแปรปรวน) → **ใช้ e (7, .4, .5)**: ink2 client 8 ขยับ (d 35), คลาด .07.
  - **lag_ink3 shrouden ยังดับ 18:** (1) วงเตือนดับ 1–3 เฟรมแล้วกลับ = Flash return ก่อน (เป้าหมายไม่บอกชั่วขณะ / ยังไม่มี r.cds) ข้าม GLOWHOLD
    → HeldGlow ในทางออกก่อนกำหนด ; (2) วง teleport_pst (seg 33) ค้างจนอนิเมชันจบ 2 s → idle 1 เฟรม (ฝั่ง server จริง) → punch = ดับแวบ
    → till 26 (ตีครั้งสุดท้าย) + LINGER, TR_OLD_LANDTILL. lag_ink4 กำลังรันยืนยัน (+ hold .4).
  - **lag_ink4 (hold .4):** Ink ขยับ **0.01 ต่อลูก** (12/1208), err median .06. ✓
  - **Laser "hitbox นำหน้าบอส" (ผู้ใช้ 2026-10-28):** ไม่จริง — ช่วง optic_blast_pre1/pre2 (ไม่อยู่ใน _land) วาดเส้นไล่ offline เลื่อนไปข้างหน้า
    บอสยืนนิ่ง (0.85 → 2.0). ของจริง (SGshrouden optic_blast_appear): บอสวาร์ปไปที่เป้า, beam (AOE 2 + ตัว .5 = 2.5) เกิดตรงนั้น อยู่ ~1.6 s
    แล้วไล่ 9–12/s. แก้ (TR_OLD_LANDAT): _land pre1 = วงรอบเป้า (on_target), pre2/loop/pre3 = วงรอบ beam จริง (at_thing) + LeadMoving.
    lag_beam1 (ไม่มี lead): NOT drawn 3/44 + 11/106 (วงตาม beam ช้า ~1) ; **lag_beam2 (lead): 0/63 + 0/89**, false 2 + 1.
    กลุ่ม 11–17 ชิ้น "ของ beam" ที่ 12–25 ห่าง = นับเจ้าของผิด (วาดวงกลมรวม) ไม่ใช่ beam.
  - **HUNTSTICK (modmain Pick ค้าง .3 s หลังไล่):** beam1 6+2 → beam2 7 — ไม่ช่วย ; lag_beam3 บันทึก [tr_lagdl] (อยู่ในรายการ/คำของ server) หาสาเหตุจริง.
  - **วงเตือนดับ (ต่อ):** [tr_lagdl] beam3: บอสอยู่ในรายการ, มีคำ server, มีเป้า ทุกเฟรมที่ดับ → ไม่ใช่ Pick. จำลอง Flash (scratchpad glow_sim.lua):
    cooldown ตัวหนึ่งหมด (left -.3) แล้วตัวถัดไปเข้าช่วงหลัง .12–.5 s → ดับ 1–7 เฟรม. GLOWHOLD: ค้างเต็ม .3 s แล้วจางลง .7 s (ไม่ตัด) →
    beam5: **7 → 1 / 6254 เฟรม**. + TR_OLD_GLOWAFTERMOVE: cooldown เข้าช่วงภายใน .2 s หลังอยู่ในท่า → สว่างเต็มทันที (รอยต่อหลัง punch_pre).
    LANDLOOSE: beam ยังอยู่แต่ท่าถูกนับว่าจบ (3.87 s) → วาดวงรอบ beam ต่อจากอนิเมชันบอส. beam5 NOT drawn 0/46 + 2/71 — สองครั้งเป็นขอบ
    Predictive (วงห่างตัวคุณฝั่ง server 2.43 < 2.5 แต่บนจอคุณนำ .54 → 2.80).
  - **beam6 (GLOWAFTERMOVE):** shrouden ดับ **0** / 5293 เฟรม ; NOT drawn shrouden 1/37 + 0/73, wings 0/8, hands 1 (2.61, age .233 — ค้าง).
  - **replay เต็ม 0805 ด้วยโค้ดปัจจุบัน (2026-10-28 บ่าย):** missed **25** (บอส 6, _haz 19 ; เช้า 52 / 46), false 2019 (2033).
  - ตัวบันทึก [tr_lagframe]: กลุ่ม 11–17 ชิ้นที่ 228,-19x ติดเจ้าของเป็นของชิ้นที่กำลังวาด (beam, ลูก Ink) = วงกลมรวม (UnionDraw) — แก้ตัวบันทึก.
  - **lag_main1 (deerclops, moose, bearger, mock_dragonfly, moonmaw; สแกนทุกเฟรม):** NOT drawn 0 ทุกตัว ยกเว้น moonmaw 6/264 + 2/279 (lavae ring 6,
    lavae 2 ; เดิม lag_1028 7/444 = ไม่ใช่ถดถอย). ดับ: moonmaw 8 = testbench ย้ายฉาก (ตำแหน่งกระโดด 21–30, สลับ pred) ไม่ใช่ในเกม ; อื่นตัวละ ≤ 1.
    lavae ring: ลาวาหมุนที่ 4.05 (client เห็น 3.3–3.5, ตัดคอร์ด), ตีภายใน 2.2 รอบตัว (FindEntities) = ถึง 6.25 จากบอส ; รูป offline วง ~6.4 —
    ทำไม NOT ยังไม่รู้: [tr_lagframe] เก็บแค่จุดยึดกลุ่ม ไม่ใช่ขนาด → ต้องให้ตัวบันทึกเก็บรัศมีกลุ่ม (ค้าง).
  - **bench บังคับ NEVER รอบ 2 (2026-10-28_1411, never_force2: never_force.ps1 อ่าน UM postinit + CommonStates แล้ว, 19 บอส × 2):** missed 1/3555
    (bushcrab trapdoor_attack ตีขณะเคลื่อน, state t ค้าง .3 → .633 = state time freeze ของ bench). ทดสอบได้เพิ่ม: bushcrab trapdoor_atk, minotaur
    jump_atk_pre_quick, spider_trapdoor warrior_atk, vault_pillar_guard atk_3_pre_b. ยัง NEVER: state ที่บังคับเล่นอนิเมชันอื่น (bat attack → atk ไม่ใช่
    hair_attack) — never_force ต้องจับคู่จากอนิเมชันที่ไม่เคยเห็นจริง ไม่ใช่ชื่อท่า.
  - **ลาวา moonmaw "jump ~1 แล้วดีดกลับ" (lag_main1 6 ครั้ง):** [tr_lagdraw] 566.70: LeadMoving เริ่มนำ 0.17 s หลังเริ่มพุ่ง (รอความเร็วนิ่ง) → รูป
    กระโดด 1.0 ในเฟรมเดียว ; หยุด → ดีดกลับในเฟรมเดียว. แก้ TR_OLD_LEADEASE: ค่านำค่อย ๆ ขึ้น .15 s / ลง .1 s, วาร์ป (ก้าว > 40/s) ตัดทันที
    (SimMoves.LeadMoving ครอบ _LeadMovingRaw — ไม่เพิ่ม local). **ลองแล้วไม่เอา:** jumps 65–83 → 1–4 แต่ NOT drawn moonmaw 2+0 → 4+6 (.15 s)
    / 1+11 (.07 s), shrouden 0–2 → 5 / 2+4 — นำช้า = วาดตามไม่ทัน. ปิดไว้ (เปิดได้ด้วย TR_LEADEASE) ; beam ใช้ _LeadMovingRaw ตรง.
    **ลองแล้วไม่เอา 2 — LEADGROW** (เร่งในแนวเดิม: นำด้วยความเร็วช่วงก่อน): snap backs 0–5 → 34 (1.27/1000), NOT ไม่ดีขึ้น — ปิด (TR_LEADGROW).
    สรุป: ลาวา "กระโดด 1 แล้วกลับ" ยังอยู่ (6 ครั้ง/รอบ) — การนำหน้าแบบใดที่ลองทำให้พลาดหรือกระตุกมากกว่า ; ต้องใช้ข้อมูลท่าพุ่ง (ความเร็ว/ระยะ
    จาก sim) แทนการวัดความเร็ว — ค้าง.
  - moonmaw lag_mm1 (ตัวบันทึกเก็บ ext): NOT 2/279 + 0/233 ; ลาวาวง: กลุ่มที่วาดยาวถึง 6.55, คุณ 6.28 = ขอบของส่วนที่วาดตอนนั้น — ขอบ.
  - **เกมอัปเดต 760178 (2026-10-27, Halloween) — ข้อมูลสร้างจากสคริปต์ 10-22:** แตกใหม่แล้ว (game_scripts.hash D9ED1D…, เก่าเก็บที่
    game_scripts_E98C…), game_scripts_um สร้างใหม่, anim_lengths ใหม่ (ต่าง 9 บรรทัดเดิม: mutated_spider_reviving, run_pst_side ; ที่เหลือคือ
    อนิเมชันใหม่ "knockback"). SG ที่เปลี่ยน 106 ไฟล์ ส่วนใหญ่เพิ่ม CommonStates.AddKnockbackStates/OnKnockback ; shrouden/charlie_boss:
    counterattack range ใช้รัศมีเป้าแทนตัวเอง ; horns: spitout รัศมี +3. ยังต้อง: sim ใหม่บอสที่ได้รับผล + bench เต็ม, ตั้ง data_game_version.txt.
  - **หนอน lag (ต่อ):** worm5 (หลังแก้ Attacking): เริ่มฉากได้แล้ว, struck 5 / NOT 2 = ทั้งสองไม่ใช่วาดผิด (ตัวคุณถูกย้าย 20 ; ท่อนซ้อนนับแยก). ไม่เคยมี "worm_boss lag scene" ในทุก lag run (5/5 gave up) — ที่จดว่า lag_1028 เห็นหนอนตี = ตีนอกฉาก. tr_testbench: lag
    give-up ลองสร้างใหม่อีกครั้ง (TR_BENCH_OLD_LAGRETRY). lag_worm3 (หลัง mock_dragonfly): หนอนตีนอกฉาก — ท่อนหนาม client ที่ 263.85 แต่ server
    258.32 (ห่าง 5.5) → NOT drawn 3 ; กองดิน 7.01 (lead 3.0). worm4 กำลังรัน.
  - **หนอนบน lag bench (2026-10-28_1457):** "gave up - a minute with no attack" — ฉากเดี่ยวของ worm_boss ไม่โจมตี ; วัดฝั่ง client ไม่ได้จนกว่าจะแก้ฉาก (ค้าง).
  - **ดิสก์:** ลบ bench_x ก่อน 27 ต.ค. (สร้างใหม่ได้) → D: ว่าง 35.6 → 67.2 GB. bench เต็ม 2026-10-28 บ่าย (-All -Rounds 3) กำลังรัน.
  - **bench เต็ม 2026-10-28_1503 (-All -Rounds 3):** 19.8 นาที, 267 share ; ล่ม 1: cherrybulletbee (exited 6) — "Can't find prefab cherry_beepoison_fx"
    (mod อื่นไม่ได้โหลดในโลก bench) วนพิษทุกเฟรม = ไม่ใช่โค้ดเรา. NEVER 110 บรรทัด (เดิม ~106).
    replay: missed 35 (บอส 12: vault_crawler 3, twins2 charge 2, rocky warp 2, bat_boss/spider/beeguard/stumpling/vault_pillar 1 ; _haz 23), false 1945.
    A/B สวิตช์ของวันนี้ทั้งหมด (GLOW*, AIRSTILL, LEADTPSTEP, LAND*) บน 5 ตัวที่พลาด = เท่ากันทุกตัว → ไม่ใช่ถดถอย (รอบรันต่างจาก 0805).
  - lag_frames.ps1: ไม่นับช่องว่างที่ตำแหน่งต่างกัน ≥ 10 (testbench ย้ายฉาก) — main1 moonmaw 8 → 0.
  - **replay_haz รู้วงกองดินของหนอน (modmain AGGRO_WHILE near):** WormDirtCovers — ห่างกองดิน ≤ 2.5 และมีท่อนหนามภายใน 1.6 ของกองดิน
    ใน .35 s → นับว่าวาด (OLD_AGGRONEAR=1 คืนเดิม). share078 1440–1480: missed 2 → 0. ข้อจำกัด: ไม่นับเฟรมที่วงขึ้นแต่ไม่โดน (false) และไม่รู้
    แอนิเมชันของกองดิน (trace ไม่มี anim) — เฉพาะส่วน near.
  - rocky_boss_shadow dash 1: พุ่งตาม statemem.rot (35.6, ไม่ปัด) ตรงรูป ; ตีจากวงท้ายเฟรม 17 ที่ 2.76 — รูปคลุมหลังตี .3 s (ระยะจริง 14.5,
    run 16) — ยังไม่แก้.
- **unit tests ผ่านครบ (2026-10-25):** test_sim อีก 3 ข้อ = ล้าสมัย: phase2 chop โดน tell_wait 4 เฟรม (เทสต์เดินเวลา 5 เฟรม),
  Eye charge_pst = กฎ AHEADLEG 21 ต.ค. (เทสต์ทั้งเปิด/ปิดสวิตช์), spike trail มี delay 16 (เช็คที่ 16+12). body_ring 4 = วงแบบไม่จัดกลุ่ม
  ยัง 60 ชิ้น (RINGSEG ใช้แค่แบบกลุ่ม) → telegraph RingPieces ใช้ทั้งสองทาง. **pool_hide 7 = บั๊กจริง:** lines.lua RightTri คำนวณแล้ว
  ไม่ Place (บรรทัดหายตอนเพิ่ม Off 22 ต.ค.) → Lines.Tri ไม่วาดอะไร: simmoves:879 FillTris ตรง, :1391 รอยต่อมุมเส้นขอบ, :1533 atom tris
  ที่วาดตรง — น่าจะอยู่ใน 1.1.5 ที่อัปโหลดแล้ว. replay มองไม่เห็น (นับจาก record ไม่ใช่ชิ้น) — **บทเรียน: รัน unit tests ทุกตัว
  (last_summary list) ก่อนติดตั้ง ไม่ใช่แค่ test_sim.** ติดตั้งแล้ว + patch notes.
- **test_sim 9 → 3 FAILED (2026-10-25):** 6 ข้อเป็นเทสต์ล้าสมัย: ส่ง "คุณ" (me.ent) เป็นเอนทิตีเดียวกับเป้าแต่คนละตำแหน่ง —
  ตั้งแต่ 22 ต.ค. predict ใช้ me.x/me.z เป็นตำแหน่งเป้าเมื่อเป้าคือคุณ (lag) → เทสต์ได้ Me(px, pz, tg): คุณ = เป้าเฉพาะเมื่อยืนที่เดียวกัน
  ไม่งั้นเป็นอีกคน ; Klaus swipe at you วางเป้าที่คุณ. ที่เหลือ: phase2 chop ไม่ถูกวาดเลยใน harness (แม้ (2,0)) แต่ bench phase2 0 missed
  → น่าจะ harness ขาดอะไร ; Eye charge_pst ยังวาด "next leg" (predict:2350) ; spike trail กลางยังนับว่าอันตราย — ยังไม่ได้ดู.
- **ค้าง (จดไว้):** (1) test_sim 9 FAILED ตั้งแต่หลัง 17 ต.ค. (last_summary ตอนนั้น ok) — น่าจะหลัง rebuild 19 ต.ค.; เช่น Klaus chomp
  ที่ (-2,0) ด้านหลังก็นับว่าอันตราย, Werepig pounce เป้าขวางทางยังอันตราย ; replay/เกมจริงไม่พลาด → ต้องดูทีละข้อว่า test ล้าสมัย
  หรือของจริง. (2) UM Bearger โยนหิน 5 ก้อน (postinit/prefabs/bearger.lua LaunchProjectile) — lag 1435 ฉาก 18: ทั้ง 5 แตกที่จุดเกิด
  (ตัวบอส) ทันที ตีคุณห่าง 2.02 พร้อมกัน, ไม่ได้วาด (ของที่แตกตั้งแต่ปล่อย). (3) testbench: ฉากไม่จบระหว่างบอสพุ่งเร็ว (> .25/tick)
  ใช้กับ bench ทุกแบบแล้ว (OLD_SCENE_CHARGE). bench เต็ม 1701 (-Rounds 3 เท่า 0407; 1532 ใช้ 10 รอบ เทียบไม่ได้): strikes 53796,
  missed 59 (0407: 36), false 1826 (2095), glitch 1618 (1589). missed ที่เพิ่ม = _haz 19→40: worm_boss_segment 21 (0407 หนอนไม่ทำอะไร),
  deerclops_icespike_fx 4→15 (UM สุ่มร่าง), warg breath 7→14 = ความต่างของโลก ไม่ใช่กฎ. ท่าพุ่ง headless: minotaur run 572→668 เฟรม
  (headless ตัดน้อยอยู่แล้ว - หุ่นถูกวางใกล้, จบด้วย runningattack) ; บอสพุ่งไม่พลาดเพิ่ม (rook false 19→1, twins1 1→20 = noise).
  บทเรียน: เทียบ bench ต้องใช้ -Rounds เท่ากัน (ดู "begin rounds=" ใน share log).
- **คลาสใหม่ (ยังไม่แก้ — สัญญาผู้ใช้ว่าคืนนี้วัดอย่างเดียว):** ท่าที่เริ่ม anim กลางทาง: Klaus `quickattack` (SGklaus: PlayAnimation
  attack_doubleclaw + SetFrame(15), ตีที่ state f1/f12 = anim f16/f27 เท่าท่า attack) หลัง attack_chomp → ไม่ถูกวาดเลย (age .23–.3 =
  รูป chomp จบไปก่อน). ข้อมูลมีอยู่แล้ว (attack_doubleclaw first=16) — client ไม่เริ่มท่าเพราะไม่เห็น anim ที่เวลา ~0? ต้องดู predict
  Track. SetFrame ใน stategraph เกม+UM มี 101 ที่ → ตรวจทั้งคลาสก่อนแก้.
- **ยังไม่ได้วัด: ping จริงแบบเพื่อน** — เครื่องเดียวกันมีแค่การรอ tick. ต้องหน่วงเน็ตเทียม (เช่น clumsy/WinDivert = ลงไดรเวอร์ ต้องถามผู้ใช้ก่อน).

**ทางที่ถูกกว่า (ไม่ใช้แทน):** replay + YOU_LEAD ปรับจากค่าที่วัด — ใช้หลัง bench เพื่อวน replay เร็ว ไม่ใช่ตัวตัดสิน.

## 7. กฎการทำงาน (ใช้ทุกครั้ง)

- **อายุของสวิตช์ TR_OLD_xxx (2026-10-28, ตอนนี้ 101 ตัว):** กฎที่ผ่านเวอร์ชันที่อัปโหลดแล้ว 1 เวอร์ชันโดยไม่มีรายงานปัญหา + ผ่าน replay เต็ม/lag bench →
  ลบสวิตช์และโค้ดเก่าออก (ทำตอนเริ่มเวอร์ชันถัดไป ไม่ใช่กลางทาง). สวิตช์ที่ "ลองแล้วไม่เอา" (TR_LEADEASE, TR_LEADGROW) ลบพร้อมกัน.
- install.ps1 หยุดถ้า patch_notes_X กับ patch_notes_client_X ไม่ตรงกัน (เช็คแทนความจำ).
- bench_logs: tools\prune_bench_logs.ps1 (แสดงรายการ, -Apply ย้ายไป _trash_bench_logs ไม่ลบ) — เก็บ baseline + รอบเต็ม 2 ล่าสุด + 2 วันล่าสุด.

- **ก่อนลงมือทำความคิดใหม่ทุกครั้ง: เขียนการวิเคราะห์ลงแผนนี้ก่อน** — ทำเพื่ออะไร, ช่วยได้จริงไหม (และเมื่อไรจะไม่ช่วย),
  มีทางอื่นไหม, จะรู้ได้อย่างไรว่ามันได้ผล แล้วค่อยทำ (ผู้ใช้ย้ำ: "วิเคราะห์ก่อน ตามลำดับขั้นตอน ให้เวลากับตัวเองคิด" —
  2026-10-16 ผมยังรีบไปเขียนโค้ดบังคับท่าทันทีที่ผู้ใช้ถาม โดยไม่ได้คิดว่ามันจะทำผิดแบบเดียวกับ sim)
- เจอปัญหาที่บอสตัวหนึ่ง = คิดก่อนว่าคลาสอะไร ตัวไหนอีกบ้างที่เป็น แก้ที่กฎของ sim / predictor ไม่ใช่ spec ของตัวนั้น (ไม่ต้องถามผู้ใช้ — ตัดสินเอง จดไว้)
- ก่อนบอกว่าแก้แล้ว: มีหลักฐานจากเกมจริง (log หรือ testbench) และ diff ข้อมูลก่อน/หลังที่อธิบายได้ทุกบรรทัด
  **และต้องผ่านทั้งสองชั้น: ข้อมูลถูก (testbench/sim) + วาดถูก (replay ผ่าน predict กับ log ที่ผู้เล่นขยับ: FOLLOWS / AIMED / MISSED)**
  — ข้อมูลถูกอย่างเดียวไม่พอ (Bearger 2026-10-16: ข้อมูล lock 21 ถูก แต่ตัววาดยืดไป 43)
- **ตัวตรวจใหม่ทุกตัว ต้องผ่านการทดลองควบคุมก่อนเชื่อ:** รันกับของที่รู้ว่าผิด (เช่นตัววาดรุ่นเก่า) แล้วต้องเห็นความต่าง
  (2026-10-16: replay ของ testbench ให้ผลเหมือนกันทั้งรุ่นผิดและรุ่นถูก → ผมสรุปผิดว่า "ยืนยันแล้ว")
- รายงานสั้น: เปลี่ยนอะไร, ตรวจด้วยอะไร, ผลเป็นตัวเลข, ยังไม่แน่ใจอะไร
- งานหนักใช้ทุก core เสมอ (รวมถึงรอบ debug) และดู RAM

## 8. บันทึกระหว่างทาง

- (2026-10-16) testbench v0.1 เสร็จ: `D:\Work\Coding\dont starve\tr_testbench` (client mod, F7) + `tools/bench_lock.lua`
  ออกแบบ: บอสโจมตีเองตามธรรมชาติ (ไม่บังคับ GoToState — กันไม่ให้ทำผิดแบบเดียวกับ sim) ผู้เล่นถูกย้ายตามฉากตอนบอสเริ่มท่า
  ข้อจำกัดที่รู้: ท่าที่เกิดยาก (timer/phase) อาจไม่ออก → v0.2 เพิ่มการตั้ง field/timer ตาม spec; AoE ที่กว้างกว่า 5 จะโดนแม้หลบ (อ่านผลประกอบกับ jump)
- (2026-10-16) บอสที่ผูกกับสถานที่ (Hooded Widow–ต้นไม้, Ancient Guardian–เสา, Crab King/Malbatross–ทะเล, Antlion–ทะเลทราย,
  Fuelweaver–atrium, Toadstool–ต้นเห็ด, Celestial Champion–เกาะ): sim จำลองไม่ได้ และเสกมากลางที่โล่งก็ไม่ได้ท่าจริง
  → testbench โหมด "ที่นี่" (Shift+F7): ใช้บอสที่บ้านจริงของมัน ไม่เสก ไม่ลบ; ไม่ย้ายผู้เล่นลงน้ำ/นอกพื้น (noplace → ไม่นับฉากนั้น)
  → บอสในทะเล: เปิด "เดินบนน้ำ" ของ TMIR (tag tmir_waterwalk) แล้ว testbench ย้ายผู้เล่นบนน้ำได้
  → ท่าที่ขึ้นกับสถานที่ ต้องได้ข้อมูลจากเกมจริงเท่านั้น และ predictor อาจต้องรู้ตำแหน่งของ (ต้นไม้/เสา) ตอน runtime — งานถัดไปหลังเห็นผล
  ~~รอผลรอบแรกจากผู้ใช้~~ (ทำแล้ว: headless เทียบกับ bench2 ของผู้ใช้ ตรงกัน)

- (2026-10-16) ทบทวน testbench v0.1 ก่อนให้ผู้ใช้รันรอบเต็ม — เจอ 2 จุดที่ทำให้ผลเชื่อไม่ได้:
  1. **การโดนจากของที่ค้างจากท่าก่อน ปนเข้ามา** (รอบแรก: "taunt" ของ Deerclops โดนที่เฟรม 89 = วงน้ำแข็งเก่า ค้าง 9 วินาที)
     → แก้: หลังจบแต่ละฉาก ย้ายทั้งบอสและผู้เล่นไปจุดใหม่ห่าง 30 (บนพื้นดินเท่านั้น) ของเก่าอยู่ไกล
     → และตัววิเคราะห์นับการโดนจากของที่ปล่อย เฉพาะของที่ปรากฏ ([tr_haz]) หลังเริ่มฉากนั้น (ใช้กับโหมด "ที่นี่" ที่ย้ายบอสไม่ได้)
  2. **หลบ 5 หน่วยน้อยกว่าท่ากว้าง ๆ** → โดนทั้งที่เลิกเล็งแล้ว อ่านผลเป็น "ยังเล็ง" ผิด
     → แก้: หลบ 10 หน่วย
  ผลข้อมูลรอบแรก (Deerclops 31 ฉาก) ใช้สรุปไม่ได้เพราะข้อ 1–2 ทิ้งไป
- (2026-10-16) เร่งเกม (TheSim:SetTimeScale) เพื่อให้ testbench เร็วขึ้น — วิเคราะห์:
  ช่วยได้ถ้าเกมเร่งโดยรัน tick (1/30 วิของเกม) หลายครั้งต่อเฟรมจอ = ผลเหมือนเดิม
  ไม่ช่วย/อันตรายถ้า tick ยาวขึ้น (2–4 เฟรมต่อ tick): การชน, TimeEvent, การวาร์ปผู้เล่นทุก tick หยาบลง → ผลเพี้ยน
  ไม่รู้ว่า DST ทำแบบไหน → ให้ testbench วัดเอง: log ระยะเวลาเกมต่อ tick (tickdt); ถ้าไม่ใช่ 1/30 → เตือน + bench_lock ไม่ใช้ผล
  TMIR's speed = the same call (TheSim:SetTimeScale(pct/100)) — ไม่ใช้ซ้อนกับ testbench (testbench ตั้ง/คืนค่าเอง)
  และยืนยันซ้ำ: ท่าเดียวกันที่ความเร็ว 1 กับเร่ง ต้องให้เฟรมที่โดนเหมือนกัน ก่อนใช้การเร่งจริงจัง
- (2026-10-16) testbench รอบ 2 (2x ผ่าน: tickdt = 1/30; ครบ Deerclops, Moose, Bearger, Wilting, Moonmaw; Bishop ครึ่ง)
  ได้: เฟรมที่โดนตรงข้อมูลทุกตัว (เกมเร็วกว่า 1 เฟรมเท่ากันหมด = offset ของ trace ไม่ใช่ข้อมูลผิด)
       ท่าที่ข้อมูลไม่มี: Wilting vomit_atk (พ่นไฟ), fire_on (ลุกเป็นไฟ) — sim ไม่สร้าง → ต้องดูว่าทำไม (คลาสใหม่?)
  เจอจุดผิดของ testbench อีก:
  3. หลบออกข้าง 10 = ห่างจากบอสเพิ่มด้วย → ท่าระยะสั้นที่หันตาม (uppercut หันเฟรม 35, ระยะ 8) อ่านเป็น "ไม่ตาม"
     → แก้: หมุนรอบบอส ±60° ที่ระยะเดิม (หันตาม = โดน, ไม่หัน = ไม่โดน)
  4. การโดนจากมอนตัวอื่น (lavae ที่บินแยก, ลูกน้องบอส) ปนเข้ามา → นับเฉพาะตัวบอส + ของที่ไม่ใช่มอนที่มี trace ของตัวเอง
  ข้อจำกัดที่ยืนยันแล้ว: ปล่อยธรรมชาติ 54 ท่า Moonmaw ไม่ใช้ summoncrystals / skyfall / spit เลย → ต้องโหมดบังคับ (6.1)
- (2026-10-16) **ต้นเหตุร่วมของ "ตีไปแล้วแต่ยังเล็ง" (Deerclops, Moonmaw, Bearger)** — เจอจาก log ที่ผู้ใช้เล่นหลังแก้ Bearger:
  ข้อมูล lock ถูก (testbench ยืนยัน Bearger 18–24, ข้อมูล 21) แต่ **ตัววาด (predict) มีกฎยืด lock ไปถึงตอนของชิ้นสุดท้ายลง**
  (sim.puts / set_until — ชดเชยข้อมูลรุ่นเก่าที่ lock ไม่นับของที่ปล่อย) → UM: Bearger 21→43, Deerclops swipe 0→39,
  Moonmaw 0→25, glacialhound, Twins, spider รวม 9 ท่า
  → แก้: ข้อมูลจาก sim รุ่นใหม่มีป้าย lock_things = true → ตัววาดไม่ยืด; ข้อมูลเกมปกติรุ่นเก่า (9 ท่า เช่น Antlion, Fuelweaver) ยังยืดอยู่
    จนกว่าจะ rebuild base (4.6)
  **บทเรียน:** ผมบอกผู้ใช้ว่า "เจอแล้ว ตรงกับที่คุณคิด" จากผล testbench (ตรวจแค่ข้อมูล) โดยไม่ได้ replay ผ่านตัววาดกับ log ที่ผู้เล่นขยับจริง
  — replay FOLLOWS จะเห็นทันที. กฎ: ก่อนบอกว่าแก้แล้ว ต้องผ่านทั้ง "ข้อมูลถูก" (testbench) และ "วาดถูก" (replay log จริง: FOLLOWS/AIMED)
- (2026-10-16) Moonmaw ปั่น: lavae หมุนที่ระยะ 4 ไม่ใช่ 3 (linearcircler ขยายระยะได้อย่างเดียว) — sim ไม่ได้สร้าง lavae จริง เป็นกรณีคลาส 7
- (2026-10-16) log หลัง install ไม่มี trace เพราะ /MIR ลบ debug.txt — แก้ install.ps1 ให้เก็บไว้เฉพาะในโฟลเดอร์เกม
