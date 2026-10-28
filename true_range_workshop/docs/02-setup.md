# 02 · ตั้งเครื่องและติดตั้ง

[← สารบัญ](README.md)

## สิ่งที่ต้องมี

| โปรแกรม | ใช้ทำอะไร | หมายเหตุ |
|---|---|---|
| Don't Starve Together (Steam) | เกม + dedicated server สำหรับ bench | |
| Uncompromising Mode (Workshop `3193922031`) | บอสของ UM — bench รันกับ UM เปิดเสมอ | |
| LuaJIT 2.1 (`luajit` ใน PATH) | replay, unit test, compile-check | ทุก tool `.lua` รันด้วย luajit (ดาวน์โหลด build สำหรับ Windows จาก luajit.org หรือ build เอง) |
| Windows PowerShell 5.1 | สคริปต์ `.ps1` ทั้งหมด | |
| Git | เวอร์ชันโค้ด | ติดตั้งที่ `C:\Program Files\Git` — ถ้า PowerShell หา `git` ไม่เจอ: `$env:Path += ';C:\Program Files\Git\cmd'` |
| Python + Pillow (ไม่บังคับ) | แปลงภาพ `.ppm → .png` ของ `tests\pics.ps1` | `pip install pillow` |

สำหรับ **lag bench** เพิ่มเติม: Steam เปิดและล็อกอินบัญชีที่มี DST, ปิดเกมก่อนรัน, มี `debug.txt` ในสำเนาที่ติดตั้ง (install.ps1 ทำให้), และ cluster `Cluster_4` ที่ตั้ง UM ไว้ (ดูตารางข้างล่าง)

## โฟลเดอร์ (path ที่ฝังในสคริปต์)

| Path | คืออะไร |
|---|---|
| `D:\Work\Coding\dont starve\true_range\` | **ต้นฉบับของ mod** |
| `D:\Work\Coding\dont starve\true_range_workshop\` | tools, tests, เอกสาร, patch notes |
| `D:\Work\Coding\dont starve\tr_testbench\` | mod ทดสอบฝั่ง server (เสกบอส, ใส่ตัวแทนผู้เล่น) |
| `D:\Work\Coding\dont starve\tr_lagjoin\` | mod ทดสอบฝั่ง client (เข้าเกมเอง, บันทึกทุกเฟรม) |
| `D:\Games Manager\Games\steamapps\common\Don't Starve Together\` | เกม (`mods\true_range` คือสำเนาที่เกมอ่านจริง) |
| `D:\Games Manager\Games\steamapps\workshop\content\322330\3193922031\` | Uncompromising Mode (รวม `postinit\`) |
| `Documents\Klei\DoNotStarveTogether\900782082\Cluster_4\` | ตั้งค่า world/mod (UM) ที่ bench และ lag bench คัดลอกไปใช้ |
| `Documents\Klei\DoNotStarveTogether\900782082\Cluster_17\cluster_token.txt` | token ของ server ที่ lag bench คัดลอกไปใช้ — **ความลับ** |
| `Documents\Klei\DoNotStarveTogether\client_log.txt` | log ของเกม (ที่ mod และ lag bench เขียน) |

> path เหล่านี้ฝังอยู่ในสคริปต์ราว 25 ไฟล์ — ถ้าเครื่องคุณต่าง ให้ค้นทั้ง `Games Manager` และ `900782082` ใน `tools\` กับ `tests\` แล้วแก้ให้ครบ

## Git

```
repo: D:\Work\Coding\dont starve      (repo เดียวครอบ true_range, true_range_workshop, tr_testbench, tr_lagjoin)
```

`.gitignore` กันไว้แล้ว: mod อื่นในโฟลเดอร์เดียวกัน, `cluster_token.txt`, `_trash_*`, และของใหญ่ที่สร้างใหม่ได้
(`tests\work\`, `old\`, `tests\logs\`, `tests\perf_logs\`, `tests\controls\`)

ไฟล์ข้อมูล `moves_sim*.lua` (≈11 MB) **commit ด้วย** — เพื่อย้อนดูได้ว่าเวอร์ชันที่ปล่อยใช้ข้อมูลอะไร

A/B แบบ worktree (รันทุกบรรทัดจาก `D:\Work\Coding\dont starve\true_range_workshop`):

```powershell
git worktree add ..\..\tr_ab_old <commit>                                     # ได้ D:\Work\Coding\tr_ab_old
powershell -File tools\install.ps1 -Src ..\..\tr_ab_old\true_range            # ติดตั้งตัวเก่าเข้าเกม
powershell -File tests\bench_replay.ps1 -Mod ..\..\tr_ab_old\true_range       # replay ด้วยตัวเก่า (ผลแยกโฟลเดอร์)
powershell -File tools\install.ps1                                            # เสร็จแล้ว ติดตั้งตัวปัจจุบันกลับ
git worktree remove ..\..\tr_ab_old
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
`install.ps1` **สร้างไฟล์นี้ในสำเนาที่ติดตั้งทุกครั้ง** (ต้นฉบับไม่มี) — สำเนาในเกมจึงเป็นตัวทดสอบเสมอ

> ⚠ **อัปโหลดจากต้นฉบับ `true_range\` เท่านั้น ห้ามอัปโหลดจาก `mods\true_range`** (มี debug.txt — ผู้เล่นจะได้ log เต็มจอ)
