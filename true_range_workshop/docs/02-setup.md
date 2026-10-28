# 02 · ตั้งเครื่องและติดตั้ง

[← สารบัญ](README.md)

## สิ่งที่ต้องมี

| โปรแกรม | ใช้ทำอะไร | หมายเหตุ |
|---|---|---|
| Don't Starve Together (Steam) | เกม + dedicated server สำหรับ bench | |
| Uncompromising Mode (Workshop `3193922031`) | บอสของ UM — bench รันกับ UM เปิดเสมอ | |
| LuaJIT (`luajit` ใน PATH) | replay, unit test, compile-check | ทุก tool `.lua` รันด้วย luajit |
| Windows PowerShell 5.1 | สคริปต์ `.ps1` ทั้งหมด | |
| Git | เวอร์ชันโค้ด | repo อยู่ที่ `D:\Work\Coding\dont starve` |
| Python (ไม่บังคับ) | แปลงภาพ `.ppm → .png` ของ `tests\pics.ps1` | |

## โฟลเดอร์ (path ที่ฝังในสคริปต์)

| Path | คืออะไร |
|---|---|
| `D:\Work\Coding\dont starve\true_range\` | **ต้นฉบับของ mod** |
| `D:\Work\Coding\dont starve\true_range_workshop\` | tools, tests, เอกสาร, patch notes |
| `D:\Work\Coding\dont starve\tr_testbench\` | mod ทดสอบฝั่ง server (เสกบอส, ใส่ตัวแทนผู้เล่น) |
| `D:\Work\Coding\dont starve\tr_lagjoin\` | mod ทดสอบฝั่ง client (เข้าเกมเอง, บันทึกทุกเฟรม) |
| `D:\Games Manager\Games\steamapps\common\Don't Starve Together\` | เกม (`mods\true_range` คือสำเนาที่เกมอ่านจริง) |
| `D:\Games Manager\Games\steamapps\workshop\content\322330\3193922031\` | Uncompromising Mode |

> ถ้าเครื่องคุณใช้ path ต่างจากนี้ ต้องแก้ใน `tools\install.ps1`, `install_client.ps1`, `run_bench.ps1`, `run_lag.ps1`, `hand_check.ps1` (ค้นคำว่า `Games Manager`)

## Git

```
repo: D:\Work\Coding\dont starve      (repo เดียวครอบ true_range, true_range_workshop, tr_testbench, tr_lagjoin)
```

`.gitignore` กันไว้แล้ว: mod อื่นในโฟลเดอร์เดียวกัน, `cluster_token.txt`, `_trash_*`, และของใหญ่ที่สร้างใหม่ได้
(`tests\work\`, `old\`, `tests\logs\`, `tests\perf_logs\`, `tests\controls\`)

ไฟล์ข้อมูล `moves_sim*.lua` (≈11 MB) **commit ด้วย** — เพื่อย้อนดูได้ว่าเวอร์ชันที่ปล่อยใช้ข้อมูลอะไร

A/B แบบ worktree:

```powershell
git worktree add ..\tr_ab_old <commit>
powershell -File tools\install.ps1 -Src ..\tr_ab_old\true_range          # ติดตั้งตัวเก่าเข้าเกม
powershell -File tests\bench_replay.ps1 -Mod ..\tr_ab_old\true_range     # replay ด้วยตัวเก่า (ผลแยกโฟลเดอร์)
```

## ติดตั้ง mod เข้าเกม

```powershell
cd D:\Work\Coding\dont starve\true_range_workshop
powershell -File tools\install.ps1          # ต้องเห็นบรรทัด "installed: ..." เท่านั้นถึงจะนับว่าติดตั้ง
powershell -File tools\install_client.ps1   # ตัว Client (สร้างจากต้นฉบับเดียวกัน) — รันหลัง install.ps1 ผ่านแล้วเท่านั้น
```

`install.ps1` ตรวจตามลำดับ และ **หยุด** ถ้าไม่ผ่าน:

| ขั้น | ตรวจ | ถ้าไม่ผ่าน |
|---|---|---|
| 0 | `modmain.lua` ไม่ใช้ของที่ mod environment ไม่มี (`modenv_check.lua`) | หยุด |
| 0b | `patch_notes_X.txt` = `patch_notes_client_X.txt` | หยุด |
| 0c | เวอร์ชันเกมตรงกับ `tools\data_game_version.txt` | **เตือน** (ไม่หยุด) |
| 0d | ท่าเขียนมือยังมี prefab/อนิเมชันในเกม (`hand_check.ps1`) | หยุด |
| — | ทุกไฟล์ `.lua` compile ได้ | หยุด |
| — | unit test ทุกตัวใน `tests\last_summary.txt` | หยุด |
| — | คัดลอก แล้วเทียบ hash ทุกไฟล์ | หยุด |

ตัวเลือก: `-Src <โฟลเดอร์ true_range อื่น>` (worktree), `-SkipTests` (อย่าใช้ก่อนส่งงาน)

## เช็คว่าเกมโหลดตัวที่ติดตั้งจริง

ใน `Documents\Klei\DoNotStarveTogether\client_log.txt` จะมี

```
[true_range] data <hash 12 ตัว>          ← ตรงกับที่ install.ps1 พิมพ์
[true_range] moves data loaded in 93 ms, 29.9 MB of Lua memory ...
```

## การเปิด debug log

`mods\true_range\debug.txt` (ในโฟลเดอร์เกม) — มีไฟล์นี้ mod จะพิมพ์ `[true_range] ...` ละเอียดลง log
`install.ps1` เก็บไฟล์นี้ไว้ให้ ไม่ลบทิ้งตอนคัดลอก
