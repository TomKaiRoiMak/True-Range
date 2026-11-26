# 07 · Reference

[<- Contents](README.md)

## Common tools (`true_range_workshop\`)

### Install / check

| Command | What it does |
|---|---|
| `tools\install.ps1 [-Src <dir>] [-SkipTests]` | checks + tests + copies the mod into the game |
| `tools\install_client.ps1 [-Src <dir>]` | makes the Client build from the same source |
| `tools\hand_check.ps1` | hand-written moves still point to things that exist in the game |
| `tools\modenv_check.lua` | modmain uses nothing the mod environment lacks |
| `tools\nomove_check.lua` | moves the game has but the data doesn't |
| `tools\make_catalog.ps1` | makes the [monster and move catalog](catalog/README.md) from the data files |

### Testing

| Command | What it does |
|---|---|
| `tools\run_bench.ps1` | testbench (see [05](05-testing.md)) |
| `tools\run_lag.ps1` | lag bench (the real game) |
| `tests\bench_replay.ps1` | replays a whole set into a table |
| `tests\replay.lua`, `tests\replay_haz.lua` | replays a boss / things put out (one file) |
| `tests\pics.ps1` | pictures of what was drawn at given times |
| `tools\lag_frames.ps1`, `lag_land.ps1`, `lagthing_to_haz.ps1`, `move_tree.lua` | analyse lag bench logs |
| `tools\never_force.ps1` | makes a state-forcing file from the NEVER list |
| `tools\went_table.ps1 [-Dir <replay results>]` | every charge: how far it really goes vs the data (with/without a target) - finds charges drawn too long/short |

### Building data

| Command | What it does |
|---|---|
| `tools\sim_moves.lua` | runs a boss's stategraph offline |
| `tools\build_um.ps1`, `build_te.ps1`, `build_all_tables.ps1`, `build_all_follow.ps1` | build whole data files |
| `tools\mod_scripts.ps1 -Mod <id> -Name <n>` | the game's code + a mod's code laid over it (`game_scripts_<n>`) |
| `tools\anim_lengths.ps1` | every animation's length |
| `tools\verify.ps1` | unpacks the game's code again when `scripts.zip` changes + overall checks |

### Disk

| Command | What it does |
|---|---|
| `tools\prune_bench_logs.ps1 [-Apply]` | lists (or moves to the trash) old logs - keeps the baselines + the last 2 full runs + the last 2 days |

## Switches worth knowing

Each is a global (`TR_OLD_X=1` in a replay's env) = back to the old behaviour. See the comment next to the code for details and numbers.

| Switch | Rule |
|---|---|
| `TR_OLD_LANDSTOP`, `LANDKEEP`, `LANDHOLD`, `LANDWAIT`, `AIRSTILL` | thrown things: a still landing spot, nothing drawn mid-air |
| `TR_OLD_GLOWPULSE`, `GLOWGRACE`, `GLOWOVERLAP`, `GLOWHOLD`, `GLOWAFTERMOVE` | the cooldown warning glow doesn't flicker (the glow itself is off by default) |
| `TR_OLD_LANDAT`, `LANDLOOSE`, `LANDTILL`, `LAND2` | Umbral optic blast/teleport drawn at the real beam/target |
| `TR_OLD_LEADTP`, `LEADTPSTEP`, `LEADSTOP` | LeadMoving: no leading while teleporting/stopping |
| `TR_OLD_CHAINLAST` | Rock Master: the last dash of a chain |
| `TR_OLD_WENT` | charges that lock their spot when they stop aiming: the landing drawn as far as that boss really charges in this game (with/without a target) - Klaus with a target charges 8.5, not 15 |
| `TR_OLD_WORMPOUND` | worm: no pound ring round dirt mounds (0 damage) |
| `TR_OLD_WORMDIRT` (modmain) | worm: dirt-mound rings only while its head comes up / a segment passes |
| `TR_OLD_HUNTSTICK` (modmain) | a boss kept in the draw list .3 s after it stops hunting |
| `TR_OLD_QUEENTURN`, `TR_OLD_MINIONRING` | Shrouded Queen: swipe lanes turn with her hidden aim; her shadows drawn round themselves |
| `TR_BENCH_OLD_*` | testbench-side switches |

> Switches marked (modmain) are invisible to replay - A/B them with `run_lag.ps1 -Old "..."`.

## Terms

| Term | Meaning |
|---|---|
| **move** | one kind of a boss's attack (named by its first animation) |
| **hazard / thing** | an entity a boss makes that deals damage (fireball, spike, beam) - `_hazards` in the data |
| **sim** | running the game's real code offline to build move shapes |
| **share / lane** | the testbench's units: 1 server = 1 share, split into lanes (several bosses at once, far apart) |
| **scene** | one time a boss starts a move + the player placed by the test pattern |
| **missed** | hit, but nothing drawn over you |
| **false / drawn-in-no-strike** | drawn over you, but no hit |
| **NOT drawn** | (lag bench) missed on the client |
| **NEVER** | a move in the data the bench never saw strike |
| **blink** | one owner's picture gone 1-3 frames, then back |
| **jump / snap back** | the shape jumps far in one frame / jumps and comes back |
| **Predictive / None** | the game's Lag Compensation option (pred=1 / pred=0) |
| **LeadMoving** | drawing moving things ahead, to make up for the client seeing them late |
| **UM / TE** | Uncompromising Mode / Tropical Experience |
| **ASBOSS** | a hit from a thing the boss put out, but already covered by the boss's own move (not counted as missed) |
