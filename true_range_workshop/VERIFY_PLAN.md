# True Range - what counts as fixed, and the rules

This page is short on purpose: **what counts as fixed** and **the rules everyone follows**, nothing else.

| You want | Go to |
|---|---|
| the measurements / reasons behind each fix | `git log` (commit messages follow the template below) |
| open items, this version's status | [docs/08-status.md](docs/08-status.md) |
| how to use the test tools | [docs/05-testing.md](docs/05-testing.md) |
| an old commit hash cited in a note | [docs/history/hash_map.md](docs/history/hash_map.md) |

---

## 1. What counts as "fixed"

All of these:

1. **The cause is found in real game data** - you can say which frame and why (lag bench `[tr_lagframe]`/`[tr_lagthing]`, bench traces, pictures from `pics.ps1`), not from reading code alone.
2. **There's a `TR_OLD_xxx` switch** that turns it back, and its name is in the switch lists of `tests\replay.lua` + `tests\replay_haz.lua`.
3. **A/B shows nothing got worse** - replay (new vs `TR_OLD_xxx`) on the sets it touches; if the rule affects many bosses -> a full replay.
   (switches in `modmain.lua` are invisible to replay - A/B them with the lag bench's `-Old` instead)
4. **`install.ps1` passes** ("installed: ..."), then `install_client.ps1`.
5. **Client side** (if it's about lag/pictures) - lag bench before/after with the same numbers (NOT drawn, false, blinks, jumps/snap backs) - install first.
6. **Patch notes** in both files + a **commit** by the template.

"Tried and dropped" is committed and written down the same way (the worse numbers + kept behind an opt-in switch) - so the next person doesn't try it again.

## 2. Commit message template

```
<boss/part>: <what was fixed> (TR_OLD_xxx)

Problem:  <what the player sees / which number is wrong>
Cause:    <the wrong frame/rule, with evidence: log, time, value>
Fix:      <the new rule in 1-2 lines>
Measured: <before -> after> (test set: replay 1604 / lag_xxx)
Left:     <anything still unsure, if any>
```

Example:

```
Ink Blight: landing ring held still after touchdown (TR_OLD_LANDSTOP)

Problem:  the landing ring moved as the ball reached the ground
Cause:    78/91 of the moves came 2 frames after touchdown: s.stopped skipped LANDKEEP and drew at the real position (.1-.4 off)
Fix:      stopped + s.land within 1.5 -> drawn at s.land
Measured: lag: moved 0.84 -> 0.13 per ball (this rule alone); replay: missed/false unchanged
```

## 3. Team rules

- **One bug = a class** - find which rule is wrong, then check every boss that uses it. Fix the rule (sim / predict), not one boss's spec.
- **A new checker must pass a control test before it's trusted** - run it on something known to be wrong; it must see the difference.
- **Right data isn't enough** - it must be drawn right too (replay through the real predict).
- **Don't edit files a bench/replay/build is reading** - if it slipped, run again.
- **Installing = `install.ps1`** passing first, then `install_client.ps1`.
- **Don't upload to the Workshop yourself** · `tr_testbench` / `tr_lagjoin` are never uploaded · upload from the source `true_range\` only, not the game's copy (it has debug.txt) · never publish `cluster_token.txt`.
- **Don't touch a player's world/saves without asking.**
- **Compare A/B on the same logs** - different bench runs give different numbers by themselves.
- **The judge of pictures is `[tr_lagframe]` from the real game** - a simulating tool (proxy) isn't the truth.
- **A game update = stale data** until the code is unpacked again and rebuilt ([docs/04](docs/04-data-pipeline.md)) - `install.ps1` warns.
- **Use every core** for heavy work, check how many processes are already running first, check free space on the bench drive (the bench won't start under 25 GB).
- **Test in game without asking the owner to play** - use the lag bench + logs + pictures.
- **Commit as the noreply address** (`134504790+TomKaiRoiMak@users.noreply.github.com`), never a personal email.

### How long `TR_OLD_xxx` switches live (~100 now)

A rule that has been through one uploaded version with no reported problem, and passed a full replay / lag bench -> **remove the switch and the old code when the next version starts** (not part way through).
Opt-in switches for things "tried and dropped" (`TR_LEADEASE`, `TR_LEADGROW`) are removed at the same time.

## 4. Problem classes seen before (check every boss when touching these rules)

| Class | Example | Check with |
|---|---|---|
| a state entered with no target passed / lock from a thing put out | many bosses (fixed in sim) | bench real lock |
| radius from the middle vs from the body's edge (FindEntities doesn't count the target's body) | Moonmaw's lava 2.2 from the middle | read the game's code + bench |
| scale (hit range, speed) | UM catcoon: range 4/1.5 | lint SetRange × scale |
| special moves (teleport, legs, spinning things, changing move part way) | Umbral teleport/optic blast, Rock Master chain dash | `_land`, `_chain_last` + lag bench |
| moves that start with the same animation | Twins laser <-> charge | tell/from + bench FALSE |
| thrown things: guessing the landing spot | Ink Blight | `lag_land.ps1`, `lagthing_to_haz.ps1` |
| lag: drawn behind / led too far / teleports | beam, lavae, hands | lag bench jumps/snap backs/NOT drawn |
| flicker / gaps between moves | Umbral's warning ring | `lag_frames.ps1` |
| testbench artefacts (not bugs) | scene moves, state time freeze, player moved | read the trace before concluding |
