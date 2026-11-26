# 04 · Move data and how it's built

[<- Contents](README.md)

## Data files in `true_range\scripts\true_range\`

| File | Size | Comes from | Overwritten by a rebuild? |
|---|---|---|---|
| `moves_sim.lua` | 5.8 MB | the base game's sim (every boss, every move) | ✔ |
| `moves_sim_um.lua` | 2.7 MB | the sim with Uncompromising Mode on | ✔ |
| `moves_sim_te.lua` | 1.3 MB | the sim with Tropical Experience on | ✔ |
| `moves_table.lua` | 1.8 MB | moves that "strike where their target is", run at every angle/distance (see [Tables](#tables-moves_table)) | ✔ |
| `moves_preload.lua` | 0.1 MB | the part loaded first | ✔ |
| `moves_hand.lua`, `moves_hand_um.lua`, `moves_hand_te.lua` | | **written by hand** - moves/things the sim can't do | ✘ (safe) |
| `thing_sources.lua` | | which boss/move each thing comes from | ✔ |

In game everything loads in ~93 ms, ~30 MB of Lua memory (measured 2026-10-28).

**Finding a monster/move in the data:** [Monster and move catalog](catalog/README.md) - made from these files by `tools\make_catalog.ps1` (run it again whenever the data changes).

## One move's data (shortened)

```lua
catcoon = {
  atk = { anims = { "atk" }, first = 16, frame = "target", lock = 0,
          maps = { { dist = 1, path = "0.00", steps = { { at = 16, cells = "b21i28..." } } }, ... } },
}
_hazards = { shadowthrall_projectile_fx = { moved = ..., lasting = ..., delay = 26, steps = {...} }, ... }
```

| Field | Meaning |
|---|---|
| `anims` | animations that tell this move has started |
| `first` | first frame it strikes |
| `frame` | turns to its target (`target`) or keeps the way the boss faces (`facing`) |
| `lock` | frame the boss stops aiming |
| `maps[].dist` | the target's distance in the sim run (the map nearest the real distance is used) |
| `path` | how far the boss moves each frame |
| `steps[].at` / `cells` | frame it strikes / cells it hits (encoded as a string) |
| `_hazards` | things put out: moving (`moved`), lasting (`lasting`), delay, which frame they strike until |

## The build pipeline

```
data\databundles\scripts.zip ──► tests\work\game_scripts\       (unpack the game's code)
UM workshop scripts ───────────► tests\work\game_scripts_um\    (tools\mod_scripts.ps1 -Mod 3193922031 -Name um)
data\anim\*.zip ───────────────► tools\anim_lengths.lua         (tools\anim_lengths.ps1)
            │
            ▼
tools\sim_moves.lua   runs a boss's real stategraph frame by frame (offline, with target dummies at many distances/angles)
            │
            ▼
tools\build_um.ps1 / build_te.ps1 / build_all_tables.ps1 / build_all_follow.ps1 / merge_*.lua
            │
            ▼
true_range\scripts\true_range\moves_sim*.lua, moves_table.lua
```

> ⚠ `build_um.ps1` changes `bearger_boulder`'s scale at random every time - after a build, restore it from the backup and splice in only the boss you meant to change.
> ⚠ A full rebuild changes many bosses at once - do it on a branch/worktree and replay the whole set against the old one before merging.

## Tables (`moves_table`)

Some moves can't be drawn from a single offline scene. The sim runs each move in one test scene (boss at 0,0 facing right, you in front at 2-16), but in a real game you stand off to the side, run while it winds up, and the boss sometimes turns to follow you and sometimes doesn't. The first system guessed those cases with whole-move rules (`lock`, `frame`, `anchor`, `follow`, `snaps`, `set_until`, `shift`, `glide`...), and since different parts of one move depend on different things (Scrappy's junk: its direction from the boss's facing as it throws, its distance from where you were as it throws, then aimed again as it lands), every rule was partly wrong and each new one broke another move.

Tables replace guessing with measuring:

1. **Measure, don't guess.** Everything the drawing uses comes from running the game's code - no per-move rules.
2. **Work back from each hit.** For every hit, find which values it came from, read on which frame.
3. **Compare only where it matters.** Find the frame where the code reads your position / the boss's facing, then run the move (angle × distance) for that frame only.
4. **One rule in game:** reached the deciding frame? -> look up the table -> draw. The same for every move and boss.
5. **Know what can't be predicted.** What the game decides later (random, re-aimed mid-air, the boss's brain) is drawn as "may hit" until it happens, then the real thing.
6. **Run once, keep the result.** Each move's result is stored with a fingerprint (its game code + game version + sim code); nothing changed = no new run.
7. **Don't draw again what the game already warns about** correctly (a missile's target ring, a fire effect).

The pieces, each testable on its own:

```
 game code (scripts.zip, unpacked once)
        │
 [1] runner ──────── runs the game's code in a simulated world (tools/sim_moves.lua as a library: SIM_LIB=1)
        │
 [2] tracer ──────── while it runs: records every hit + which value of whom the code read, on which frame (tools/trace_moves.lua)
        │
 [3] table builder ─ runs angle × distance at the deciding frame -> a table per move, cached (tools/build_tables.lua, build_all_tables.ps1)
        │
   moves_table.lua (data shipped with the mod)
        │
 [4] in game ─────── before the deciding frame: look up with where you are now (still aiming - follows you);
                     from it on: with where you were at that frame (locked); random parts drawn faint until they happen
                     (predict.lua DrawTable)
```

A table move passes when, from replays of real logs: 0 real hits outside the drawn area (except parts marked random and covered by a "may hit" area), 0 jumps/flickers, 0 things landing outside the area in the predictable part, and no per-move rule in the drawing code. `tools\table_gate.ps1` compares each move drawn from its table against the old way, and `TR_TABLES_OFF` in a replay turns the tables off.

**Why LuaJIT, not a one-time port to another language:** DST's code is Lua 5.1 and the game itself runs it, so the sim has to run the same code. LuaJIT is the fastest Lua 5.1. Porting would mean the whole engine the bosses rely on (components, physics, tasks, events, tuning - hundreds of files), redone after every Klei update, for little speed. What's really needed - not running everything again each time - comes from the cache.

## When the game updates (the data goes quietly wrong if you forget)

`install.ps1` warns `WARNING: moves data built for game X, the game is Y` when the versions differ.

1. Unpack the new code: compare `scripts.zip`'s SHA1 with `tests\work\game_scripts.hash`; if different, unpack again (the old one is moved to `game_scripts_<old hash>`) - `tools\verify.ps1` does it for you.
2. `tools\mod_scripts.ps1 -Mod 3193922031 -Name um`
3. `tools\anim_lengths.ps1 -Out tools\anim_lengths.lua <all data\anim\*.zip>` (~17 s)
4. Diff the old/new stategraphs of bosses that have data -> run the sim again only for bosses whose attack timing changed.
5. Set `tools\data_game_version.txt` to the new version (first line = the game's `version.txt`).
6. Full bench + replay ([05](05-testing.md)).

## Moves the data lacks / never tested

| Tool | Answers |
|---|---|
| `tools\nomove_check.lua` | moves the game has but the data doesn't (run it before claiming "full coverage") |
| `tools\bench_lock.lua` (on bench results) | `NEVER` = moves in the data the bench never saw strike |
| `tools\never_force.ps1` | turns the NEVER list into a state-forcing file (`run_bench.ps1 -Force`); reads both UM postinit and CommonStates |
| `tools\hand_check.ps1` | hand-written moves still point to prefabs/animations that exist |
| `tools\state_coverage.lua`, `mod_coverage.lua`, `unknown_moves.lua` | other coverage |

> UM's `postinit\` code isn't in `game_scripts_um` - search the real workshop folder `...\322330\3193922031\postinit\`.

## Adding a hand-written move

Put it in `moves_hand.lua` (base game), `moves_hand_um.lua` (UM) or `moves_hand_te.lua` (TE), in the same format as the sim data.
Hand-written data is used only when the sim data **lacks** that move/thing (`moddata.lua`) - comment why the sim can't do it, and cite the line in the game's code.
