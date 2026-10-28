# 03 · โค้ดของ mod (ในเกม)

[← สารบัญ](README.md)

ต้นฉบับ: `true_range\` · ทุกไฟล์ใน `scripts\true_range\`

## แผนที่ไฟล์

| ไฟล์ | ขนาด | หน้าที่ | แก้บ่อย |
|---|---|---|---|
| `modmain.lua` | 134 KB | ประตูหลัก: เลือกมอน (`Pick`), วงเขียนมือ (`AGGRO`, `AGGRO_WHILE`, `ANYWHERE`, `DARTS`), วงตัวผู้เล่น/เพื่อน, ตรวจ "โดนตอนอยู่ในวงไหม" | ✔ |
| `predict.lua` | 240 KB | ติดตามท่าบอส + ตัดสินใจรูป/ตำแหน่ง/สี | ✔✔ |
| `simmoves.lua` | 294 KB | วาดรูปท่าและของที่ปล่อยจากข้อมูล, ประมาณจุดตก, LeadMoving | ✔✔ |
| `lines.lua` | 45 KB | ชิ้นภาพ: pool, กลุ่ม (group), Begin/End ต่อเฟรม | |
| `telegraph.lua` | 18 KB | วงเส้นขอบ (`Circle`) และวงจากข้อมูลที่ "เรียนรู้" | |
| `learn.lua` | 41 KB | เรียนระยะจากการโดนจริง (มอนที่ไม่มีข้อมูล) | |
| `moddata.lua` | 5 KB | โหลดข้อมูล + ผสมข้อมูลของ mod อื่น (UM, Tropical Experience) | |
| `ranges.lua`, `rings.lua` | | ระยะโจมตีพื้นฐาน, วงตัว | |
| `silhouettes.lua`, `triangulate.lua` | | เงาบอส, แบ่งรูปเป็นสามเหลี่ยม | |
| `settings.lua`, `settingsscreen.lua`, `render.lua` | | ตัวเลือกผู้เล่น (โหมดเรืองแสง/รูปทรง ฯลฯ) | |
| `profiler.lua`, `allocwatch.lua`, `probe.lua` | | วัดประสิทธิภาพ/ดีบัก | |

ไฟล์ข้อมูล (`moves_*.lua`, `thing_sources.lua`) อธิบายใน [04](04-data-pipeline.md)

## predict.lua — จุดสำคัญ

| ฟังก์ชัน | ทำอะไร |
|---|---|
| `Track(ent, moves, now, ...)` | ดูอนิเมชันปัจจุบัน → บอสเริ่มท่าไหน (`a.move`, `a.t0` = เวลาเริ่มตามเวลาอนิเมชัน) แยกท่าที่เริ่มเหมือนกันด้วย tell/from/far |
| `Flash(ent, moves, r, a)` | วงเรืองแสงเตือน cooldown (ข้อมูล cooldown มาจาก server: `r.cds`, `r.at`) — มีการค้างความสว่าง/จางออกกันกระพริบ |
| `Predict.Draw(ents, ...)` | ทุกเฟรม: Track → วาดท่าของบอสแต่ละตัว |
| `Predict.DrawHazards(ents, ...)` | ทุกเฟรม: วาดของที่ปล่อย (เรียก `SimMoves.DrawHazard`) |
| `LandSpot`, สาขา `_land` | ท่าที่เขียนพิเศษ (Umbral Abomination: วาร์ป, optic blast) — วาดรอบเป้า / รอบ beam จริง |

## simmoves.lua — จุดสำคัญ

| ส่วน | ทำอะไร |
|---|---|
| `SimMoves.Draw(entry, x, z, rot, ...)` | วาดรูปท่าจากข้อมูล (cells/maps/path) |
| `SimMoves.DrawHazard(ent, ...)` | ของที่ปล่อย: ลูกโยน (fit ความสูง → จุดตก, `_land_wait`, `_land_hold`, `_land_soon`), ของวิ่ง, ของวางนิ่ง |
| `SimMoves.LeadMoving(ent, x, z, now)` | วาดนำหน้าของที่เคลื่อนที่ (ชดเชยแลคฝั่ง client) — ไม่ทำงานบน host |
| `SimMoves._land`, `_tail`, `_chain_last` | ตารางกรณีพิเศษต่อบอส |
| `SimMoves.Glow`, `DrawDisc` | วงเตือน, วงกลมทึบ |
| `SimMoves.UnionDraw`, `LaneDraw` | วาดของกลมหลายชิ้นรวมกัน, เลนของกลุ่ม |

> ⚠ **simmoves.lua ชนเพดาน 200 local ของ Lua แล้ว** — ห้ามเพิ่ม `local` ระดับไฟล์ใหม่ ให้ใช้ `SimMoves.xxx` แทน
> และ compile-check ทุกครั้ง: `luajit -bl ..\true_range\scripts\true_range\simmoves.lua > $null`
> (แผน: แยกเป็นโมดูลหลังปล่อย 1.1.6 — ดู [08](08-status.md))

## modmain.lua — ข้อควรระวัง

- environment ของ modmain **ไม่มี** `tonumber, setmetatable, getmetatable, rawget, rawset, pcall, xpcall, select, next, unpack, error, os, io, debug, package, _G` ฯลฯ (รายการเต็ม: `MISSING` ใน `tools\modenv_check.lua`) — ต้องใช้ `GLOBAL.xxx` ถ้าลืม เกมจะ crash ตอนโหลด (`install.ps1` ตรวจให้)
  (`pairs`, `ipairs`, `print`, `string`, `math`, `table` ใช้ได้)
- ตัวแปร global ที่ไม่ได้ประกาศทำ DST crash — อ่านสวิตช์แบบนี้:
  - ใน `modmain.lua`: `GLOBAL.rawget(GLOBAL, "TR_OLD_X")`
  - ใน `scripts\true_range\*.lua`: `rawget(_G, "TR_OLD_X")`

## ตัวเลือกดีบัก (global ที่ mod อ่าน)

| Global | ผล |
|---|---|
| `TR_OLD_xxx` | ปิดกฎใหม่ข้อนั้น กลับเป็นแบบเดิม (มี ~100 ตัว ดูคอมเมนต์ใกล้จุดที่ใช้) |
| `TR_DEBUG` | พิมพ์ log ละเอียด (เปิดเองเมื่อมี `debug.txt`) |
| `TR_LANDWOB`, `TR_GAP`, `TR_JUMP` | ตัวนับสำหรับ replay (ความนิ่งของจุดตก, ช่องว่าง, การกระโดด) |
| `TR_LEADEASE`, `TR_LEADGROW` | การนำหน้าแบบทดลองที่ **ลองแล้วไม่เอา** (ปิดอยู่) |

## รูปแบบคอมเมนต์ในโค้ด

คอมเมนต์ในโค้ดเขียนเป็นภาษาอังกฤษแบบเล่าเหตุ: *อะไรเกิดขึ้น, บอสตัวไหน, วัดได้เท่าไร, วันที่, ชื่อสวิตช์*
เช่น `-- (... the Ink Blights' balls, 78 of 91 moves ..., 2026-10-28. TR_OLD_LANDSTOP)` — เขียนตามแบบนี้เพื่อให้คนต่อไปรู้ว่าทำไม
