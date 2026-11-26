# 02 · Setup

[<- Contents](README.md)

## What you need

| Program | Used for | Notes |
|---|---|---|
| Don't Starve Together (Steam) | the game + the dedicated server for benches | |
| Uncompromising Mode (Workshop `3193922031`) | UM's bosses - benches run with UM on | |
| LuaJIT 2.1 (`luajit` on PATH) | replays, unit tests, compile checks | every tool `.lua` runs with luajit (a Windows build from luajit.org, or build it yourself) |
| Windows PowerShell 5.1 | all the `.ps1` scripts | |
| Git | version control | if PowerShell can't find `git`: `$env:Path += ';C:\Program Files\Git\cmd'` |
| Python + Pillow (optional) | turning `.ppm` pictures into `.png` for `tests\pics.ps1` | `pip install pillow` |

For the **lag bench** as well: Steam running and logged in with DST, the game closed before a run, a `debug.txt` in the installed copy (install.ps1 makes it), and a cluster `Cluster_4` set up with UM (see the table below).

## Folders (paths written into the scripts)

| Path | What it is |
|---|---|
| `D:\Work\Coding\dont starve\true_range\` | **the mod's source** |
| `D:\Work\Coding\dont starve\true_range_workshop\` | tools, tests, docs, patch notes |
| `D:\Work\Coding\dont starve\tr_testbench\` | server-side test mod (spawns bosses, puts in a stand-in player) |
| `D:\Work\Coding\dont starve\tr_lagjoin\` | client-side test mod (joins by itself, records every frame) |
| `D:\Games Manager\Games\steamapps\common\Don't Starve Together\` | the game (`mods\true_range` is the copy the game really reads) |
| `D:\Games Manager\Games\steamapps\workshop\content\322330\3193922031\` | Uncompromising Mode (including `postinit\`) |
| `Documents\Klei\DoNotStarveTogether\<account>\Cluster_4\` | world/mod settings (UM) that the bench and lag bench copy |
| `Documents\Klei\DoNotStarveTogether\<account>\Cluster_17\cluster_token.txt` | the server token the lag bench copies - **secret** |
| `Documents\Klei\DoNotStarveTogether\client_log.txt` | the game's log (written by the mod and the lag bench) |

> The game's path is written into about 25 scripts - if your machine differs, search `tools\` and `tests\` for `Games Manager` and change them all. Your Klei account folder (`<account>`) is found by the scripts themselves (the numbered folder with the newest client_save), or set `DST_KLEI_ACCOUNT`.

### `true_range_workshop\tests\work\` (big, not in git, can be remade)

| Folder | Notes |
|---|---|
| `bench_logs` | every bench's logs (~85 GB) - kept in check by `tools\prune_bench_logs.ps1` |
| `bench_x` | expanded copies for replay - can be remade |
| `bench_replay` | replay results per share |
| `bench_server` | the test server's config/world (holds the cluster token - never publish) |
| `game_scripts*`, `game_scripts.hash` | the game's / UM's / TE's code unpacked (unpack again after a game update) |

## Git

```
repo: D:\Work\Coding\dont starve      (one repo for true_range, true_range_workshop, tr_testbench, tr_lagjoin)
```

`.gitignore` already keeps out: other mods in the same folder, `cluster_token.txt`, `_trash_*`, and big files that can be remade
(`tests\work\`, `old\`, `tests\logs\`, `tests\perf_logs\`, `tests\controls\`).

The data files `moves_sim*.lua` (≈11 MB) **are committed** - so you can see which data a released version used.

A/B with a worktree (run every line from `D:\Work\Coding\dont starve\true_range_workshop`):

```powershell
git worktree add ..\..\tr_ab_old <commit>                                     # gives D:\Work\Coding\tr_ab_old
powershell -File tools\install.ps1 -Src ..\..\tr_ab_old\true_range            # install the old one into the game
powershell -File tests\bench_replay.ps1 -Mod ..\..\tr_ab_old\true_range       # replay with the old one (results in their own folder)
powershell -File tools\install.ps1                                            # done: install the current one back
git worktree remove ..\..\tr_ab_old
```

## Installing the mod into the game

```powershell
cd D:\Work\Coding\dont starve\true_range_workshop
powershell -File tools\install.ps1          # only counts as installed once you see the "installed: ..." line
powershell -File tools\install_client.ps1   # the Client build (made from the same source) - only after install.ps1 passed
```

`install.ps1` checks in order and **stops** if one fails:

| Step | Checks | If it fails |
|---|---|---|
| 0 | `modmain.lua` uses nothing the mod environment lacks (`modenv_check.lua`) | stop |
| 0b | `patch_notes_X.txt` = `patch_notes_client_X.txt` | stop |
| 0c | the game version matches `tools\data_game_version.txt` | **warn** (doesn't stop) |
| 0d | hand-written moves' prefabs/animations still exist in the game (`hand_check.ps1`) | stop |
| - | every `.lua` file compiles | stop |
| - | every unit test in `tests\last_summary.txt` | stop |
| - | copy, then compare the hash of every file | stop |

Options: `-Src <another true_range folder>` (worktree), `-SkipTests` (don't use before handing work in)

## Checking the game loaded the installed copy

`Documents\Klei\DoNotStarveTogether\client_log.txt` will have

```
[true_range] data <12-character hash>      <- the same as install.ps1 printed
[true_range] moves data loaded in 93 ms, 29.9 MB of Lua memory ...
```

## Debug log

`mods\true_range\debug.txt` (in the game's folder) - with this file there, the mod prints detailed `[true_range] ...` lines to the log.
`install.ps1` **creates it in the installed copy every time** (the source never has it) - so the game's copy is always the test one. Delete it to play as players do.

> ⚠ **Upload from the source `true_range\` only, never from `mods\true_range`** (it has debug.txt - players would get a log full of lines).
