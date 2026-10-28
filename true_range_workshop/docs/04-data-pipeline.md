# 04 · ข้อมูลท่าและการสร้างข้อมูล

[← สารบัญ](README.md)

## ไฟล์ข้อมูลใน `true_range\scripts\true_range\`

| ไฟล์ | ขนาด | มาจาก | rebuild ทับ? |
|---|---|---|---|
| `moves_sim.lua` | 5.8 MB | sim ของเกมปกติ (ทุกบอส ทุกท่า) | ✔ |
| `moves_sim_um.lua` | 2.6 MB | sim เมื่อเปิด Uncompromising Mode | ✔ |
| `moves_sim_te.lua` | 1.2 MB | sim เมื่อเปิด Tropical Experience | ✔ |
| `moves_table.lua` | 1.8 MB | ท่าที่ "ตีตามเป้า" รันไว้ทุกมุม/ระยะ (ดู `REDESIGN.md`) | ✔ |
| `moves_preload.lua` | 0.1 MB | ส่วนที่โหลดก่อน | ✔ |
| `moves_hand.lua`, `moves_hand_um.lua` | | **เขียนมือ** — ท่า/ของที่ sim ทำไม่ได้ | ✘ (ปลอดภัย) |
| `thing_sources.lua` | | ของแต่ละชิ้นมาจากบอส/ท่าไหน | ✔ |

ในเกมโหลดทั้งหมด ~93 ms, ~30 MB Lua memory (วัดจริง 2026-10-28)

**หามอน/ท่าในข้อมูล:** [สารบัญมอนและท่า](catalog/README.md) — สร้างจากไฟล์เหล่านี้ด้วย `tools\make_catalog.ps1` (รันใหม่ทุกครั้งที่ข้อมูลเปลี่ยน)

## หน้าตาของข้อมูล 1 ท่า (ย่อ)

```lua
catcoon = {
  atk = { anims = { "atk" }, first = 16, frame = "target", lock = 0,
          maps = { { dist = 1, path = "0.00", steps = { { at = 16, cells = "b21i28..." } } }, ... } },
}
_hazards = { shadowthrall_projectile_fx = { moved = ..., lasting = ..., delay = 26, steps = {...} }, ... }
```

| ช่อง | ความหมาย |
|---|---|
| `anims` | อนิเมชันที่ใช้จับว่าเริ่มท่านี้ |
| `first` | เฟรมแรกที่ตี |
| `frame` | หันตามเป้า (`target`) หรือตามที่บอสหัน (`facing`) |
| `lock` | เฟรมที่บอสหยุดเล็ง |
| `maps[].dist` | ระยะเป้าตอนรัน sim (เลือก map ที่ใกล้ระยะจริงที่สุด) |
| `path` | ระยะที่บอสเคลื่อนที่ในแต่ละเฟรม |
| `steps[].at` / `cells` | เฟรมที่ตี / ช่องที่โดน (เข้ารหัสเป็น string) |
| `_hazards` | ของที่ปล่อย: เคลื่อนที่ไหม (`moved`), อยู่นานไหม (`lasting`), ดีเลย์, ตีถึงเฟรมไหน |

## สายการสร้างข้อมูล

```
data\databundles\scripts.zip ──► tests\work\game_scripts\       (แตกโค้ดเกม)
UM workshop scripts ───────────► tests\work\game_scripts_um\    (tools\mod_scripts.ps1 -Mod 3193922031 -Name um)
data\anim\*.zip ───────────────► tools\anim_lengths.lua         (tools\anim_lengths.ps1)
            │
            ▼
tools\sim_moves.lua   รัน stategraph ของบอสจริงทีละเฟรม (offline, ใส่หุ่นเป้าหลายระยะ/มุม)
            │
            ▼
tools\build_um.ps1 / build_te.ps1 / build_all_tables.ps1 / build_all_follow.ps1 / merge_*.lua
            │
            ▼
true_range\scripts\true_range\moves_sim*.lua, moves_table.lua
```

> ⚠ `build_um.ps1` เปลี่ยนค่า scale ของ `bearger_boulder` แบบสุ่มทุกครั้ง — หลัง build ให้คืนค่าจาก backup และ splice เฉพาะบอสที่ตั้งใจแก้
> ⚠ rebuild ทั้งก้อนเปลี่ยนหลายบอสพร้อมกัน — ทำบน branch/worktree แล้ว replay เทียบทั้งชุดก่อนรวม

## เมื่อเกมอัปเดต (ข้อมูลจะเพี้ยนเงียบ ๆ ถ้าลืม)

`install.ps1` จะเตือน `WARNING: moves data built for game X, the game is Y` เมื่อเวอร์ชันไม่ตรง

1. แตกโค้ดใหม่: เทียบ SHA1 ของ `scripts.zip` กับ `tests\work\game_scripts.hash` ถ้าต่าง → แตกใหม่ (ตัวเดิมย้ายไป `game_scripts_<hash เก่า>`) — `tools\verify.ps1` ทำให้อัตโนมัติ
2. `tools\mod_scripts.ps1 -Mod 3193922031 -Name um`
3. `tools\anim_lengths.ps1 -Out tools\anim_lengths.lua <data\anim\*.zip ทั้งหมด>` (~17 วินาที)
4. diff stategraph เก่า/ใหม่ของบอสที่มีข้อมูล → sim ใหม่เฉพาะบอสที่จังหวะการโจมตีเปลี่ยน
5. ตั้ง `tools\data_game_version.txt` เป็นเวอร์ชันใหม่ (บรรทัดแรก = เนื้อใน `version.txt` ของเกม)
6. bench เต็ม + replay ([05](05-testing.md))

## ท่าที่ข้อมูลไม่มี / ไม่เคยทดสอบ

| เครื่องมือ | ตอบคำถาม |
|---|---|
| `tools\nomove_check.lua` | ท่าที่เกมมี แต่ข้อมูลไม่มี (ต้องรันก่อนอ้างว่า "ครอบคลุมครบ") |
| `tools\bench_lock.lua` (ผลของ bench) | `NEVER` = ท่าในข้อมูลที่ bench ไม่เคยเห็นตีจริง |
| `tools\never_force.ps1` | แปลงรายการ NEVER → ไฟล์บังคับ state (`run_bench.ps1 -Force`) อ่านทั้ง UM postinit และ CommonStates |
| `tools\hand_check.ps1` | ท่าเขียนมือยังชี้ prefab/อนิเมชันที่มีอยู่จริง |
| `tools\state_coverage.lua`, `mod_coverage.lua`, `unknown_moves.lua` | ความครอบคลุมด้านอื่น |

> โค้ด UM ส่วน `postinit\` ไม่ได้อยู่ใน `game_scripts_um` — ค้นที่โฟลเดอร์ workshop จริง `...\322330\3193922031\postinit\`

## เพิ่มท่าเขียนมือ

ใส่ใน `moves_hand.lua` (เกมปกติ) หรือ `moves_hand_um.lua` (UM) ใช้รูปแบบเดียวกับข้อมูล sim
ข้อมูลเขียนมือใช้เฉพาะเมื่อข้อมูล sim **ไม่มี** ท่า/ของนั้น (`moddata.lua`) — เขียนคอมเมนต์อธิบายว่าทำไม sim ทำไม่ได้ และอ้างบรรทัดในโค้ดเกม
