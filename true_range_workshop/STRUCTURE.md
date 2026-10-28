# True Range — แผนผังโครงสร้างทั้งหมด

(สถานะ 2026-10-28 · ไฟล์นี้อธิบายว่าแต่ละส่วนคืออะไร คุยกันยังไง และข้อมูลไหลจากไหนไปไหน)

---

## 1. ภาพรวมใหญ่ — มี 3 โลก

```
┌───────────────────────────┐     ┌──────────────────────────────┐     ┌───────────────────────────────┐
│ 1) ตัว mod (ในเกม)          │     │ 2) โรงงานข้อมูล (offline)       │     │ 3) โรงทดสอบ (offline + เกมจริง)   │
│ true_range\               │ ◀── │ true_range_workshop\tools\   │     │ tr_testbench\  tr_lagjoin\     │
│ วาดวงโจมตีจริงให้ผู้เล่นเห็น     │     │ รันโค้ดเกมจริงทีละท่า → ได้รูปท่า │     │ true_range_workshop\tests\     │
│                           │     │ เขียนลง moves_sim*.lua        │     │ วัดว่าวาดถูกไหม ทุกเฟรม ทุกการโดน │
└───────────────────────────┘     └──────────────────────────────┘     └───────────────────────────────┘
          ▲                                                                    │
          └─────────────────── install.ps1 คัดลอกไปที่โฟลเดอร์ mods ของเกม ◀────────┘ (ผ่านเทสต์ก่อน)
```

- **โลก 1** คือสิ่งที่ผู้เล่นได้ (อัปโหลดขึ้น Workshop)
- **โลก 2** สร้าง "รูปท่า" ของบอสทุกตัวจากโค้ดเกมจริง ไม่ได้วาดเดาเอง
- **โลก 3** พิสูจน์ว่าสิ่งที่วาดตรงกับที่โดนจริง ทั้งแบบ host (server) และแบบผู้เล่นที่มีแลค (client)

---

## 2. ตัว mod — `D:\Work\Coding\dont starve\true_range\`

ต้นฉบับอยู่ที่นี่ เกมไม่ได้อ่านโฟลเดอร์นี้ตรง ๆ เกมอ่านสำเนาใน `steamapps\common\Don't Starve Together\mods\true_range` (และ `true_range_client`) ที่ `install.ps1` คัดลอกไปให้

### 2.1 ไฟล์ระดับบน

| ไฟล์ | หน้าที่ |
|---|---|
| `modinfo.lua` | ชื่อ เวอร์ชัน ตัวเลือกในเมนู mod |
| `modmain.lua` (134KB) | **ประตูหลัก**: ทุกเฟรมเลือกว่าจะวาดมอนตัวไหน (`Pick`), วงพิเศษที่เขียนมือ (`AGGRO`, `AGGRO_WHILE` เช่นกองดินหนอน, `ANYWHERE`, `DARTS`), วงตัวผู้เล่น/เพื่อน, ตรวจว่าโดนตอนอยู่ในวงหรือไม่ (log "drawn: NOT") |
| `anim\trshapes.zip`, `anim\trsil.zip` | ภาพชิ้นส่วน (เส้น สามเหลี่ยม เงา) ที่ใช้ประกอบวง |

### 2.2 `scripts\true_range\` — สมองของ mod

```
modmain.lua
   │  ทุกเฟรม
   ▼
predict.lua ──── "บอสกำลังทำท่าอะไร ถึงเฟรมไหน วาดที่ไหน"
   │  Track()      จับว่าเริ่มท่าไหน (ดูอนิเมชัน)
   │  Flash()      วงเรืองแสงเตือน cooldown ใกล้หมด
   │  Draw()       วาดท่าของบอส        DrawHazards()  วาดของที่บอสปล่อย (ลูก ไฟ หนาม)
   ▼
simmoves.lua ─── "แปลงข้อมูลท่า → รูปบนพื้น"
   │  DrawHazard   ของที่ปล่อย (ลูกโยน: ประมาณจุดตก, ของวิ่ง: LeadMoving)
   │  LeadMoving   วาดนำหน้าของที่เคลื่อนที่ ชดเชยแลค
   │  _land        ท่าที่เขียนพิเศษ (Umbral วาร์ป/optic blast)
   │  Glow         วงเตือน
   ▼
lines.lua ────── "วางชิ้นส่วนลงพื้นจริง" (pool ของชิ้น, กลุ่ม, Begin/End ทุกเฟรม)
```

| ไฟล์ | หน้าที่ |
|---|---|
| `predict.lua` (240KB) | ติดตามท่าบอส + ตัดสินใจว่าวาดรูปไหน ตำแหน่งไหน สีอะไร |
| `simmoves.lua` (294KB) | วาดรูปท่า/ของที่ปล่อย จากข้อมูล — **ชนเพดาน 200 local** ต้องเพิ่มเป็น `SimMoves.xxx` |
| `lines.lua` | ตัวจัดการชิ้นภาพในเกม (สร้างล่วงหน้า ใช้ซ้ำ ซ่อน/แสดง) |
| `telegraph.lua` | วงเส้นขอบ (Circle) และวงจากข้อมูลที่ "เรียนรู้" |
| `learn.lua` | เรียนรู้ระยะจากการโดนจริง (สำหรับมอนที่ไม่มีข้อมูล) |
| `ranges.lua`, `rings.lua` | ระยะโจมตีพื้นฐาน, วงตัว |
| `silhouettes.lua`, `triangulate.lua` | เงาบอส, แบ่งรูปเป็นสามเหลี่ยม |
| `settings.lua`, `settingsscreen.lua`, `render.lua` | ตัวเลือกผู้เล่น (โหมดเรืองแสง/รูปทรง ฯลฯ) |
| `moddata.lua` | ผสมข้อมูลตาม mod ที่เปิด (UM, Tropical Experience) |

### 2.3 ไฟล์ข้อมูล (สร้างจากโรงงาน — โลก 2)

| ไฟล์ | มาจากไหน |
|---|---|
| `moves_sim.lua` (5.8MB) | ทุกท่าของบอสเกมปกติ: รันโค้ดเกมจริงทีละเฟรม บันทึกว่าโดนตรงไหน (cells), path, เฟรมที่ตี |
| `moves_sim_um.lua` (2.6MB) | ทับด้วยข้อมูลของ Uncompromising Mode |
| `moves_sim_te.lua` (1.2MB) | ทับด้วย Tropical Experience |
| `moves_table.lua` (1.8MB) | ตารางท่าที่ "ตีตามตำแหน่งเป้า" รันไว้ทุกมุม/ระยะ |
| `moves_hand.lua`, `moves_hand_um.lua` | **เขียนมือ** — ท่า/ของที่โรงงานทำไม่ได้ (rebuild ไม่ทับ) |
| `moves_preload.lua` | ข้อมูลที่โหลดก่อนตอนเริ่ม |
| `thing_sources.lua` | ของแต่ละชิ้นมาจากบอส/ท่าไหน |

---

## 3. โรงงานข้อมูล — `true_range_workshop\tools\`

```
game_scripts (โค้ดเกมแตกออกมา) + game_scripts_um (+ UM)
        │
        ▼
 sim_moves.lua / extract_moves.lua     ← รันสเตตกราฟของบอสจริงแบบ offline ทีละเฟรม
        │
        ▼
 build_um.ps1 / build_te.ps1 / build_all_*.ps1 / merge_*.lua
        │
        ▼
 true_range\scripts\true_range\moves_sim*.lua, moves_table.lua
```

| กลุ่ม | ไฟล์หลัก |
|---|---|
| สร้างข้อมูล | `sim_moves.lua`, `build_um.ps1`, `build_te.ps1`, `build_all_tables.ps1`, `build_all_follow.ps1`, `merge_sim.lua`, `merge_moves.lua` |
| ความยาวอนิเมชัน | `anim_lengths*.lua`, `anim_lengths.ps1` |
| ตรวจความครอบคลุม | `nomove_check.lua` (ท่าที่เกมมีแต่ข้อมูลไม่มี), `state_coverage.lua`, `mod_coverage.lua`, `unknown_moves.lua` |
| ติดตั้ง | `install.ps1` (รัน unit test + modenv ก่อน แล้วคัดลอก), `install_client.ps1`, `modenv_check.lua` |

---

## 4. โรงทดสอบ — 3 ระดับ

### 4.1 Testbench (บอทแทนผู้เล่น ไม่มีจอ)  — `tr_testbench\` + `tools\run_bench.ps1`

```
run_bench.ps1 ──► เปิด server ไร้หน้าจอหลายตัวพร้อมกัน (lane/share)
                 └─ tr_testbench mod: เสกบอส, วางตัวแทนผู้เล่น ("you") หลายระยะ/มุม
                    ทุก tick เขียน [tr_trace] (สถานะบอส, ตำแหน่ง, STRIKE/HIT)
                               [tr_haz]   (ของที่ปล่อย ทุกชิ้น)
                 ▼
 tests\work\bench_logs\<วันที่>_shares\shareNNN.txt
```

- `-All -Rounds 3` = ทุกบอส (bench เต็ม) · `-Force <ไฟล์>` = บังคับเข้า state ที่ไม่เคยเกิด (`never_force.ps1` สร้างไฟล์)
- `bench_lock.lua` สรุป: ท่าไหนเคยตี/ไม่เคย (NEVER)

### 4.2 Replay (offline เร็ว ใช้ทุก core) — `tests\`

```
bench_logs ──► bench_replay.ps1 ──┬─► replay.lua      (ท่าบอส: เดินเวลาตาม trace แล้ววาดด้วยโค้ด mod จริง)
                                  └─► replay_haz.lua  (ของที่ปล่อย)
                                  ▼
                 ตาราง: strikes / missed / drawn-in-no-strike(false) / glitches ต่อบอส
```

- `-Client 1|0` = จำลองมุมผู้เล่นมีแลค (Predictive เปิด/ปิด) · `-HazOnly` = เฉพาะของที่ปล่อย · `-Mod <สำเนา>` = A/B
- เครื่องมือดูภาพ: `pics.ps1` (ภาพสิ่งที่วาด ณ เวลานั้น), `clips.ps1`
- unit test: `test_sim.lua` และอื่น ๆ (รันใน `install.ps1`)

### 4.3 Lag bench (เกมจริงของคุณ + server) — `tools\run_lag.ps1` + `tr_lagjoin\`

```
run_lag.ps1 ──► server (testbench โหมด lag) + เกม Steam ของคุณเข้าร่วมเอง (tr_lagjoin)
                ฉากสลับ Lag Compensation เปิด/ปิด
   client_log.txt ได้:
     [tr_lagdraw]  ท่าที่วาด ตำแหน่ง ทุกเฟรม
     [tr_lagframe] ชิ้นที่วาดจริง ต่อเจ้าของ ต่อเฟรม (จำนวน ตำแหน่ง ขนาดกลุ่ม ext)
     [tr_lagthing] ตำแหน่งจริงของของที่ปล่อย ทุกเฟรม (x y z)
     [tr_lagdl]    บอสอยู่ในรายการวาดไหม คำของ server
     "you were struck ... drawn: NOT"  โดนตอนไม่ได้วาด
   ▼
 lag_report.lua (อัตโนมัติ): struck / NOT drawn / false / jumps / snap backs
```

ตัววิเคราะห์ที่ใช้กับ log นี้:

| เครื่องมือ | ตอบคำถาม |
|---|---|
| `tools\lag_frames.ps1` | อะไรกระพริบ (หาย 1–3 เฟรมแล้วกลับ) — กรองการย้ายฉากของ bench ออก |
| `tools\lag_land.ps1` | ลูกโยน: จุดที่วาดห่างจุดตกจริงเท่าไร |
| `tools\lagthing_to_haz.ps1` | แปลงสิ่งที่เกมเห็นจริงเป็น trace → replay offline บนมุม client |

---

## 5. ข้อมูลไหลเวลาแก้บั๊ก 1 ตัว (ขั้นตอนจริงที่ใช้)

```
คุณเห็นบั๊กในเกม
   │
   ▼
lag bench (เกมจริง) ──► client_log ทุกเฟรม ──► หาเฟรม/สาเหตุจริง (ไม่เดา)
   │
   ▼
แก้ใน true_range\ (ทุกกฎใหม่มีสวิตช์ TR_OLD_xxx ปิดได้ ใส่ใน replay.lua/replay_haz.lua)
   │
   ├─► replay offline A/B (ใหม่ vs TR_OLD) ──► ไม่ถดถอย?
   ▼
install.ps1 (unit test ต้องผ่าน "installed:") → install_client.ps1
   │
   ▼
lag bench อีกรอบ ยืนยันด้วยตัวเลข ──► VERIFY_PLAN.md + patch_notes_1.1.6 (+ _client ต้องตรงกัน)
```

---

## 6. โฟลเดอร์อื่นใน `D:\Work\Coding\dont starve\`

| โฟลเดอร์ | คืออะไร | อัปโหลด? |
|---|---|---|
| `true_range` | ตัว mod (ต้นฉบับ) | ✅ (คุณอัปเอง) |
| `true_range_workshop` | โรงงาน + เทสต์ + patch notes + VERIFY_PLAN | ❌ |
| `tr_testbench` | mod ทดสอบ (F7) บอทเสกบอส | ❌ ห้าม |
| `tr_lagjoin` | mod ฝั่ง client ของ lag bench (บันทึกทุกเฟรม) | ❌ ห้าม |
| `tmir_quick`, `tmir_modded_bosses` | ทดสอบ TMIR | ❌ |
| `find_me`, `crockpot_guide`, `fps_meter`, `boss_report` | mod อื่นของคุณ | (แยกต่างหาก) |
| `server_patches`, `workshop_patches` | แพตช์ server/mod ของ cluster คุณ | ❌ |
| `tr_land_a` … `tr_land_e` | **สำเนาชั่วคราว** ใช้ A/B ค่า Ink วันนี้ — ลบได้ | ❌ |

### `true_range_workshop\tests\work\` (ใหญ่ — สร้างใหม่ได้)

| โฟลเดอร์ | ขนาดโดยประมาณ | หมายเหตุ |
|---|---|---|
| `bench_logs` | ~85 GB | log ของ bench ทุกครั้ง — รอบเก่าลบได้ |
| `bench_x` | ล้างแล้ว เหลือชุด 27–28 ต.ค. | สำเนาขยายสำหรับ replay — สร้างใหม่ได้ |
| `bench_replay` | | ผล replay แยกต่อ share |
| `bench_server` | | config/world ของ server ทดสอบ (มี cluster token — ห้ามเผยแพร่) |
| `game_scripts*` | | โค้ดเกม/UM/TE แตกออกมา (ต้องแตกใหม่หลังเกมอัปเดต) |

---

## 7. เอกสารหลัก

| ไฟล์ | ใช้ทำอะไร |
|---|---|
| `VERIFY_PLAN.md` | บันทึกทุกการวิเคราะห์ ผลวัด สิ่งที่ลองแล้วไม่เอา งานค้าง (อ่านก่อนแก้ทุกครั้ง) |
| `REDESIGN.md` | การออกแบบระบบตาราง (moves_table) |
| `patch_notes_1.1.6.txt` / `patch_notes_client_1.1.6.txt` | สิ่งที่เปลี่ยนในเวอร์ชันนี้ (สองไฟล์ต้องเหมือนกัน) |
| `description*.txt` | คำอธิบายบน Workshop |

---

## 8. ของเหลือที่ควรเก็บกวาด (ไม่กระทบ mod)

- `true_range_workshop\fix_*`, `live_*` (.txt/.err ~80 ไฟล์), `l`, `10`, `15`, `20`, `pic.ppm`, `hazpic.ppm` — ไฟล์ผลชั่วคราวจากการทดลองเก่า
- `tr_land_a`…`tr_land_e` — สำเนา A/B วันนี้
- `tests\replay_base_tmp.lua` — สำเนาชั่วคราว

(ยังไม่ได้ลบ — รอคุณบอกก่อน)
