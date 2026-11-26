# 05 · Testing

[<- Contents](README.md)

Three levels - pick by the question you want answered:

| Level | Answers | Time | Command |
|---|---|---|---|
| **Replay** (offline) | does a new rule miss or over-draw more - for every boss | 5-20 min (16 cores) | `tests\bench_replay.ps1` |
| **Testbench** (headless server + bot) | makes a fresh set of real fight logs (after a game update, a new boss) | ~20 min (every boss, 3 rounds) | `tools\run_bench.ps1` |
| **Lag bench** (your real game + a server) | what a lagging player really sees - flicker, jumps, late drawing | 4-12 min | `tools\run_lag.ps1` |

Results go to `tests\work\` (not in git - big and can be remade).

---

## 1. Testbench - `tools\run_bench.ps1`

Starts several dedicated servers at once, each with several lanes. The `tr_testbench` mod spawns the boss, puts stand-in players at many distances/angles/dodges, and writes every tick:

- `[tr_trace]` the boss's state, time in state, position, `STRIKE` / `HIT`
- `[tr_haz]` every thing put out
- `[tr_bench]` scene start/end, give up

```powershell
powershell -File tools\run_bench.ps1 -All -Rounds 3                 # every boss (full bench - baselines use 3 rounds; the default is 10)
powershell -File tools\run_bench.ps1 -Bosses shrouden,deerclops      # some
powershell -File tools\run_bench.ps1 -Force <file> -Rounds 2         # force states (moves that never came up)
```

Results: `tests\work\bench_logs\<date-time>_shares\shareNNN.txt` + a coverage summary (`tested` / `NEVER`) at the end of the output.

Good to know:
- **fail-fast** - if our code errors during a run it stops; look at the first minute of every run yourself.
- A server dying from another mod (e.g. `cherrybulletbee` missing a prefab) isn't our bug - those bosses run alone (`!np`).
- The worm (`worm_boss`) must run after another boss in the same share (`deer+worm_boss`) - the first one in a new world never comes out of the ground.
- After a bench, grep for `LUA ERROR` and list monsters with ~0 strikes - a crash hides misses.

## 2. Replay - `tests\bench_replay.ps1`

Steps through a bench trace and draws with the **real mod code** (`predict.lua`/`simmoves.lua`) every frame, against the real hits.

```powershell
powershell -File tests\bench_replay.ps1 -Run "<full path>\tests\work\bench_logs\2026-11-01_1604_shares"   # UM baseline
powershell -File tests\bench_replay.ps1 -Run <run> -TE              # Tropical Experience runs
powershell -File tests\bench_replay.ps1 -Run <run> -Client 1        # as a player with Predictive on (0 = off)
powershell -File tests\bench_replay.ps1 -Run <run> -HazOnly         # things put out only
powershell -File tests\bench_replay.ps1 -Run <run> -Mod <another true_range folder>   # A/B (results in their own folder)
powershell -File tests\bench_replay.ps1 -Run <run> -Bosses shrouden,catcoon     # some bosses only
powershell -File tests\bench_replay.ps1 -Run <run> -Walk                        # the player walks in and out round the boss
```

### Reading the table

```
TOTAL strikes 59086  missed 25  drawn-in-no-strike 2019  ...  gaps 160  glitches 2287
```

| Column | Meaning | Better is |
|---|---|---|
| strikes | all real hits | - |
| **missed** | hit, but nothing was drawn over you then | ↓ most important |
| drawn-in-no-strike (false) | drawn over you, but no hit | ↓ (next) |
| gaps / jumped / glitches | missing / jumping / odd pictures, per frame | ↓ |

Per-file results: `tests\work\bench_replay\<run>\<share>__<boss>.txt` with `MISSED`, `FALSE`, `FOLLOWS`, `AIMED` lines and times.

### A/B with a switch (fastest)

```powershell
$env:TR_MODS='workshop-3193922031'; $env:TR_OLD_LANDSTOP='1'
luajit tests\replay.lua ..\true_range <share.txt> tests\work\game_scripts_um <boss>
luajit tests\replay_haz.lua ..\true_range <share.txt>
```

> ⚠ `replay.lua` treats **any** `CLIENT` value (even `CLIENT=0`) as client mode - leave it unset for the host.
>
> ⚠ A/B with `bench_replay.ps1`:
> - the cache keys on the env names and the `TR_OLD_*` switches found in the code, but **a new switch must be in `replay.lua`/`replay_haz.lua`'s list** or it's ignored; delete the result file before an on/off pair.
> - both runs write the same result folder (`tests\work\bench_replay\<run>`) - copy/rename the first run's folder before the second, or use `-Mod` (separate folder).
> - `NO_CACHE=1` = run everything again.
> - switches in `modmain.lua` (e.g. `HUNTSTICK`, `WORMDIRT`) are **invisible to replay** - A/B them with the lag bench's `-Old` only.

### Frame-by-frame helpers

| Command | Gives |
|---|---|
| `DRAWLOG=1` + `-v` with `replay.lua` | `[tr_draw]` every frame: move, frame, position, run |
| `DUMP=t0,t1` with `replay.lua` | what was drawn each frame in that time window (state vs move, drawn rotation vs travel) |
| `TRACE_GUID=<guid>` with `replay_haz.lua` | every frame's decision for that one thing (hide/draw and why) |
| `GAP_V=1`, `LANDWOB_V=1` | the gaps / landing-spot wobble listed |
| `tests\pics.ps1 -Log <log> -Boss <b> -At t1,t2 -R 8` | PNG pictures of what was drawn + the boss + the player at those times |

## 3. Lag bench - `tools\run_lag.ps1`

A server (testbench in lag mode) + **your Steam game joins it by itself** (the `tr_lagjoin` mod). Scenes switch Lag Compensation between Predictive and None.

```powershell
powershell -File tools\run_lag.ps1 -Bosses shrouden,shadowthrall_wings -Rounds 1
powershell -File tools\run_lag.ps1 -Bosses moonmaw_dragonfly -Rounds 1 -Old "TR_OLD_LEADSTOP,TR_OLD_LANDSTOP"   # A/B: switches set in the client game
powershell -File tools\run_lag.ps1 -Bosses tigershark -Rounds 1 -TE        # Tropical Experience (UM off - the two crash together with a player)
powershell -File tools\run_lag.ps1 -Bosses deerclops,klaus -Rounds 1 -NoUM -NoDebug   # the plain game, as players get it
```

Parameters: `-Bosses` (default deerclops, moose, bearger, mock_dragonfly, moonmaw_dragonfly), `-Rounds` (2), `-Old` (client-side switches), `-Speed` (faster time), `-TickRate` (15), `-TE`, `-NoUM`, `-NoDebug` (no debug.txt needed; only crashes and what's drawn are checked, no struck/drawn table).

Results: `tests\work\bench_logs\<date-time>_lag\` with `client_log.txt` (pass it to the analysers with `-Log`) and `server_log.txt`.

While it runs **don't use the game** - it moves the character itself. Don't run heavy benches/replays at the same time (timing goes off).

> ⚠ If you stop a lag bench part way (kill), check that the game's `mods\modsettings.lua` has no leftover `ForceEnableMod("tr_lagjoin")` line, and delete `mods\tr_lagjoin\join.txt` - otherwise the game joins the test server by itself next time it opens.
>
> ⚠ After a run, check for a client crash: the table can look fine after one. Grep for `.dmp` files; Windows' CrashReporter can block later runs.

### What `client_log.txt` records (every frame)

| Tag | Content |
|---|---|
| `[tr_lagdraw]` | the move drawn, its anchor, against the boss's position |
| `[tr_lagframe]` | the pieces really drawn, per owner, per frame: count, position and group size (`ext`) |
| `[tr_lagthing]` | the real x y z of every thing put out, every frame |
| `[tr_lagdl]` | whether the boss is in the draw list, the server's word (cooldowns, target) |
| `you were struck ... drawn: NOT` | hit while nothing was drawn |

### The report at the end of a run

```
  shrouden pred=1     struck 89  NOT drawn 0  false 1
all, on: frames 24071, jumps 43, snap backs 5 (0.21 per 1000)
```

### Analysers

| Command | Answers |
|---|---|
| `tools\lag_frames.ps1 -Log <client_log>` | what flickers (gone 1-3 frames and back) per owner - scene changes filtered out |
| `tools\lag_land.ps1 -Log <client_log> [-Prefab <thing>]` | thrown things: how far the drawn spot was from where they really landed (default `-Prefab shadowthrall_projectile_fx` = Ink Blight) |
| `tools\lagthing_to_haz.ps1 -Log <client_log> -Out <trace> [-Prefab <thing>]` | turns what the client really saw into a trace -> `replay_haz.lua` from the client's view (try values offline) - also Ink Blight by default |
| `tools\move_tree.lua` | every stretch of a move on a lag run, flagged where drawing and reality part - fix all flagged stretches together |

## 4. Unit tests

In `tests\` (`test_sim.lua`, `body_ring.lua`, `pool_hide.lua`, ...). The list that must pass is in `tests\last_summary.txt` (the `unit ...` lines) - `install.ps1` runs them every time.

## 5. Current baselines

| Set | Used for |
|---|---|
| `bench_logs\2026-11-01_1604_shares` (UM, every monster) | the main replay. 2026-11-02: host missed 17 / 59,548, false 1,347; client 26 / 59,510, false 2,089 |
| `bench_logs\2026-11-01_0556_shares` (TE, 170 monsters) | `-TE` replay. 2026-11-02: host 15 / 25,717, false 421; client 11 / 25,709, false 594 |

> Different bench runs can give different numbers (random worlds/timing) - always compare rules with A/B on **the same set of logs**.
