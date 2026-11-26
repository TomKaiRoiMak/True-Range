# 06 · Workflow and rules

[<- Contents](README.md)

## The standard steps (a real example: "the Ink Blight's landing ring still moves")

```
1. report ──► 2. find the real frame ──► 3. find the cause ──► 4. fix + switch ──► 5. A/B offline
                                                                                        │
8. commit ◀── 7. patch notes ◀── 6. install + confirm with the lag bench ◀───────────────┘
```

| Step | What | Example |
|---|---|---|
| 1 | read the reporter's log first (if there is one) | their latest `client_log.txt` |
| 2 | lag bench that boss -> look at every frame | `run_lag.ps1 -Bosses shadowthrall_wings -Rounds 1`, then `lag_land.ps1` |
| 3 | name the wrong frame/rule with numbers | "78/91 of the moves happen 2 frames after touching down" |
| 4 | fix the rule + `TR_OLD_xxx` + add the switch name to the lists in `tests\replay.lua` and `tests\replay_haz.lua` | `TR_OLD_LANDSTOP` |
| 5 | replay new vs old on the same logs | missed/false don't go up |
| 6 | `install.ps1` -> `install_client.ps1` -> the same lag bench again | moves 0.84 -> 0.13 per ball (LANDSTOP alone) |
| 7 | add a line to `patch_notes_<version>.txt` **and** `patch_notes_client_<version>.txt` (they must match) | short, in English, for players |
| 8 | commit with the template in [`VERIFY_PLAN.md`](../VERIFY_PLAN.md) | Problem / Cause / Fix / Measured / Left |

If it turned out **worse**: turn the rule off (make it an opt-in switch, e.g. `TR_LEADEASE`) and commit with the worse numbers - don't delete it quietly.

## Checklist before a commit

- [ ] `luajit -bl <changed file>` passes (especially `simmoves.lua` - the 200-local limit)
- [ ] no new undeclared globals (switches: `rawget(_G, "...")` in scripts, `GLOBAL.rawget(GLOBAL, "...")` in modmain)
- [ ] `true_range\scripts\true_range\data_id.lua` changes on every install - no need to commit it if the data didn't change
- [ ] changed a data file (`moves_*.lua`) -> run `tools\make_catalog.ps1` so the [catalog](catalog/README.md) matches the data
- [ ] the switch is in both replay files' lists
- [ ] the A/B has numbers
- [ ] `install.ps1` showed `installed:`
- [ ] both patch-notes files
- [ ] no big or secret file slipped into the commit (`git status` first)

## After a Workshop upload

Bump `version` in `true_range\modinfo.lua` right away and start empty `patch_notes_<next>.txt` and `patch_notes_client_<next>.txt`, so the next changes are noted in the right version.

## Team rules

All rules are in one place: [VERIFY_PLAN.md §3](../VERIFY_PLAN.md) - read them before your first change.

## Telling testbench artefacts from real bugs

Before concluding "missed", look at the trace around that time. These are **not mod bugs**:

| In the trace | Means |
|---|---|
| the player's/boss's position jumps > 10 in one tick | the testbench moved the scene |
| `t=` (state time) stuck for several frames, then jumps | the sped-up server's state time froze |
| `lead=20.00` in `struck by` | the player was moved as it was hit |
| hit by two things at the same spot, one "in" and one "NOT" | counted per striker - the player really was in the drawn area |
