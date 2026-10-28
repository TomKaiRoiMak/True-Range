# 05 · การทดสอบ

[← สารบัญ](README.md)

มี 3 ระดับ เลือกตามคำถามที่อยากตอบ:

| ระดับ | ตอบคำถาม | เวลา | คำสั่ง |
|---|---|---|---|
| **Replay** (offline) | กฎใหม่ทำให้พลาด/วาดเกินมากขึ้นไหม — ทุกบอส | 5–20 นาที (16 core) | `tests\bench_replay.ps1` |
| **Testbench** (server ไร้จอ + บอท) | สร้าง log การต่อสู้จริงชุดใหม่ (หลังเกมอัปเดต, บอสใหม่) | ~20 นาที (ทุกบอส 3 รอบ) | `tools\run_bench.ps1` |
| **Lag bench** (เกมจริงของคุณ + server) | ผู้เล่นที่มีแลคเห็นอะไรจริง — ภาพกระพริบ กระโดด วาดช้า | 4–12 นาที | `tools\run_lag.ps1` |

ผลทดสอบเก็บที่ `tests\work\` (ไม่อยู่ใน git — ใหญ่และสร้างใหม่ได้)

---

## 1. Testbench — `tools\run_bench.ps1`

เปิด dedicated server หลายตัวพร้อมกัน แต่ละตัวมีหลายเลน (lane) mod `tr_testbench` เสกบอส วางหุ่นแทนผู้เล่นที่หลายระยะ/มุม/ท่าหลบ และเขียนทุก tick:

- `[tr_trace]` สถานะบอส, เวลาใน state, ตำแหน่ง, `STRIKE` / `HIT`
- `[tr_haz]` ของที่ปล่อยทุกชิ้น
- `[tr_bench]` เริ่ม/จบฉาก, give up

```powershell
powershell -File tools\run_bench.ps1 -All -Rounds 3                 # ทุกบอส (bench เต็ม)
powershell -File tools\run_bench.ps1 -Bosses shrouden,deerclops      # บางตัว
powershell -File tools\run_bench.ps1 -Force <ไฟล์> -Rounds 2         # บังคับเข้า state (ท่าที่ไม่เคยออก)
```

ผล: `tests\work\bench_logs\<วันเวลา>_shares\shareNNN.txt` + สรุป coverage (`tested` / `NEVER`) ท้าย output

ข้อควรรู้:
- **fail-fast** — ถ้าโค้ดของเรา error ระหว่างรัน มันหยุด ให้ดูนาทีแรกของทุกรอบเอง
- server ล่มด้วยของ mod อื่น (เช่น `cherrybulletbee` หา prefab ไม่เจอ) ไม่ใช่บั๊กของเรา — บอสพวกนี้รันเดี่ยว (`!np`)
- หนอน (`worm_boss`) ต้องรันหลังบอสอื่นใน share เดียวกัน (`deer+worm_boss`) — ตัวแรกในโลกใหม่ไม่ออกจากดิน

## 2. Replay — `tests\bench_replay.ps1`

เดินเวลาตาม trace ของ bench แล้ววาดด้วย **โค้ด mod จริง** (`predict.lua`/`simmoves.lua`) ทุกเฟรม เทียบกับการโดนจริง

```powershell
powershell -File tests\bench_replay.ps1 -Run tests\work\bench_logs\2026-10-28_0805_shares     # baseline
powershell -File tests\bench_replay.ps1 -Run <run> -Client 1        # จำลองมุมผู้เล่น Predictive เปิด (0 = ปิด)
powershell -File tests\bench_replay.ps1 -Run <run> -HazOnly         # เฉพาะของที่ปล่อย
powershell -File tests\bench_replay.ps1 -Run <run> -Mod <โฟลเดอร์ true_range อื่น>   # A/B (ผลแยกโฟลเดอร์)
```

### อ่านตาราง

```
TOTAL strikes 59086  missed 25  drawn-in-no-strike 2019  ...  gaps 160  glitches 2287
```

| คอลัมน์ | ความหมาย | ทิศที่ดี |
|---|---|---|
| strikes | การโดนจริงทั้งหมด | — |
| **missed** | โดน แต่ตอนนั้นไม่ได้วาดคลุมตัว | ↓ สำคัญที่สุด |
| drawn-in-no-strike (false) | วาดคลุมตัว แต่ไม่โดน | ↓ (รองลงมา) |
| gaps / jumped / glitches | ภาพขาด / กระโดด / ผิดปกติ ต่อเฟรม | ↓ |

ผลต่อไฟล์: `tests\work\bench_replay\<run>\<share>__<boss>.txt` มีบรรทัด `MISSED`, `FALSE`, `FOLLOWS`, `AIMED` พร้อมเวลา

### A/B ด้วยสวิตช์ (เร็วที่สุด)

```powershell
$env:TR_MODS='workshop-3193922031'; $env:TR_OLD_LANDSTOP='1'
luajit tests\replay.lua ..\true_range <share.txt> tests\work\game_scripts_um <boss>
luajit tests\replay_haz.lua ..\true_range <share.txt>
```

> ⚠ ผล replay มี cache ที่ไม่ดู env — ลบไฟล์ผลก่อนรัน A/B ด้วย bench_replay

### ตัวช่วยดูทีละเฟรม

| คำสั่ง | ได้อะไร |
|---|---|
| `DRAWLOG=1` + `-v` กับ `replay.lua` | `[tr_draw]` ทุกเฟรม: ท่า, เฟรม, ตำแหน่ง, run |
| `TRACE_GUID=<guid>` กับ `replay_haz.lua` | การตัดสินใจทุกเฟรมของของชิ้นนั้น (hide/draw และเหตุผล) |
| `GAP_V=1`, `LANDWOB_V=1` | รายการช่องว่าง / การขยับของจุดตก |
| `tests\pics.ps1 -Log <log> -Boss <b> -At t1,t2 -R 8` | ภาพ PNG ของสิ่งที่วาด + บอส + ตัวผู้เล่น ณ เวลานั้น |

## 3. Lag bench — `tools\run_lag.ps1`

server (testbench โหมด lag) + **เกม Steam ของคุณเข้าร่วมเอง** (mod `tr_lagjoin`) ฉากสลับ Lag Compensation Predictive/None

```powershell
powershell -File tools\run_lag.ps1 -Bosses shrouden,shadowthrall_wings -Rounds 1
```

ระหว่างรัน **อย่าใช้เกม** — มันขยับตัวละครเอง · ห้ามรัน bench/replay หนักพร้อมกัน (timing เพี้ยน)

### สิ่งที่ `client_log.txt` บันทึก (ทุกเฟรม)

| แท็ก | เนื้อหา |
|---|---|
| `[tr_lagdraw]` | ท่าที่วาด จุดยึด เทียบตำแหน่งบอส |
| `[tr_lagframe]` | ชิ้นที่วาดจริง ต่อเจ้าของ ต่อเฟรม: จำนวน ตำแหน่ง และขนาดกลุ่ม (`ext`) |
| `[tr_lagthing]` | ตำแหน่ง x y z จริงของของที่ปล่อย ทุกเฟรม |
| `[tr_lagdl]` | บอสอยู่ในรายการวาดไหม, คำของ server (cooldown, เป้า) |
| `you were struck ... drawn: NOT` | โดนตอนไม่ได้วาด |

### รายงานอัตโนมัติท้ายรัน

```
  shrouden pred=1     struck 89  NOT drawn 0  false 1
all, on: frames 24071, jumps 43, snap backs 5 (0.21 per 1000)
```

### ตัววิเคราะห์

| คำสั่ง | ตอบ |
|---|---|
| `tools\lag_frames.ps1 -Log <client_log>` | อะไรกระพริบ (หาย 1–3 เฟรมแล้วกลับ) ต่อเจ้าของ — กรองการย้ายฉากออกแล้ว |
| `tools\lag_land.ps1 -Log <client_log>` | ลูกโยน: จุดที่วาดห่างจุดตกจริงเท่าไร |
| `tools\lagthing_to_haz.ps1 -Log <client_log> -Out <trace>` | แปลงสิ่งที่เกม client เห็นจริงเป็น trace → `replay_haz.lua` บนมุม client (ทดลองค่าได้ offline) |

## 4. Unit test

อยู่ใน `tests\` (`test_sim.lua`, `pool_hide.lua`, ...) รายการที่ต้องผ่านอยู่ใน `tests\last_summary.txt` (บรรทัด `unit ...`) — `install.ps1` รันให้ทุกครั้ง

## 5. Baseline ปัจจุบัน

| ชุด | ใช้เทียบ |
|---|---|
| `bench_logs\2026-10-28_0805_shares` | replay หลักของเวอร์ชัน 1.1.6 (missed 25 ด้วยโค้ดปัจจุบัน) |
| `bench_logs\2026-10-28_1503_shares` | bench เต็มล่าสุด (missed 35 — ต่างรอบ ไม่ใช่ถดถอย) |

> รอบ bench ต่างกันให้ตัวเลขต่างกันได้ (โลก/จังหวะสุ่ม) — เทียบกฎด้วย A/B บน **log ชุดเดียวกัน** เสมอ
