# 03 · Mod code (in game)

[<- Contents](README.md)

Source: `true_range\` · every file in `scripts\true_range\`

## File map

| File | Size | Job | Changed often |
|---|---|---|---|
| `modmain.lua` | 144 KB | entry point: picks monsters (`Pick`), hand-made rings (`AGGRO`, `AGGRO_WHILE`, `ANYWHERE`, `DARTS`), your/friends' rings, the "were you inside a drawn area when hit" check, Ctrl + settings key (all off) | ✔ |
| `predict.lua` | 270 KB | tracks bosses' moves + decides shape/position/colour | ✔✔ |
| `simmoves.lua` | 350 KB | draws move shapes and things put out from the data, works out where thrown things land, LeadMoving | ✔✔ |
| `lines.lua` | 47 KB | the pieces: pools, groups, Begin/End per frame, per-part opacity (`Lines.opacity`) | |
| `telegraph.lua` | 20 KB | outline rings (`Circle`, solid or dotted - `ring_dash`) and rings from "learned" data | |
| `learn.lua` | 41 KB | learns reach from real hits (monsters with no data) | |
| `moddata.lua` | 5 KB | loads the data + merges other mods' data (UM, Tropical Experience) | |
| `ranges.lua`, `rings.lua` | | basic attack ranges, body rings | |
| `silhouettes.lua`, `triangulate.lua` | | boss silhouettes, splitting shapes into triangles | |
| `settings.lua`, `settingsscreen.lua`, `render.lua` | | player settings (opacity, dotted rings, which monsters...) and the in-game window; render switches | |
| `profiler.lua`, `allocwatch.lua`, `probe.lua` | | performance measuring / debugging | |

The data files (`moves_*.lua`, `thing_sources.lua`) are described in [04](04-data-pipeline.md).

## predict.lua - key parts

| Function | What it does |
|---|---|
| `Track(ent, moves, now, ...)` | looks at the current animation -> which move the boss started (`a.move`, `a.t0` = start time by animation time); moves that start alike are told apart by tell/from/far |
| `Flash(ent, moves, r, a)` | the cooldown warning glow (cooldowns come from the server: `r.cds`, `r.at`) - holds brightness / fades out to avoid flicker. Off by default (`render.lua` `cooldown = false`) |
| `Predict.Draw(ents, ...)` | every frame: Track -> draw each boss's move |
| `Predict.DrawHazards(ents, ...)` | every frame: draw things put out (calls `SimMoves.DrawHazard`) |
| `LandSpot`, the `_land` branch | specially written moves (Umbral Abomination: teleport, optic blast; Klaus' chomp) - drawn round the target / round the real beam |

## simmoves.lua - key parts

| Part | What it does |
|---|---|
| `SimMoves.Draw(entry, x, z, rot, ...)` | draws a move's shape from the data (cells/maps/path) |
| `SimMoves.DrawHazard(ent, ...)` | things put out: thrown (fit the height -> landing spot, `_land_wait`, `_land_hold`, `_land_soon`), running, lying still |
| `SimMoves.LeadMoving(ent, x, z, now)` | draws moving things ahead (makes up for client lag) - does nothing on the host |
| `SimMoves._land`, `_tail`, `_chain_last`, `_lanes_of` | per-boss special cases |
| `SimMoves.Glow`, `DrawDisc` | warning ring, filled circle |
| `SimMoves.UnionDraw`, `LaneDraw` | many round things drawn as one, a group's lanes |

> ⚠ **simmoves.lua is at Lua's limit of 200 locals** - don't add new file-level `local`s, use `SimMoves.xxx` instead,
> and compile-check every time: `luajit -bl ..\true_range\scripts\true_range\simmoves.lua > $null`
> (plan: split it into modules - see [08](08-status.md))

## modmain.lua - watch out

- modmain's environment **lacks** `tonumber, setmetatable, getmetatable, rawget, rawset, pcall, xpcall, select, next, unpack, error, os, io, debug, package, _G` and more (full list: `MISSING` in `tools\modenv_check.lua`) - use `GLOBAL.xxx`. Forget it and the game crashes on load (`install.ps1` checks for you).
  (`pairs`, `ipairs`, `print`, `string`, `math`, `table` are fine)
- An undeclared global variable crashes DST - read switches like this:
  - in `modmain.lua`: `GLOBAL.rawget(GLOBAL, "TR_OLD_X")`
  - in `scripts\true_range\*.lua`: `rawget(_G, "TR_OLD_X")`
- A mod RPC's `false` argument arrives as `nil` - send `1`/`0`.

## Debug switches (globals the mod reads)

| Global | Effect |
|---|---|
| `TR_OLD_xxx` | turns that new rule off, back to the old behaviour (~100 of them, see the comments where each is used) |
| `TR_DEBUG` | detailed log lines (on by itself when `debug.txt` is there) |
| `TR_LANDWOB`, `TR_GAP`, `TR_JUMP` | counters for replays (how still landing spots are, gaps, jumps) |
| `TR_LEADEASE`, `TR_LEADGROW` | experimental leading that was **tried and dropped** (off) |

## Comment style in the code

Comments are written in English and tell the why: *what happened, which boss, what was measured, the date, the switch name*.
E.g. `-- (... the Ink Blights' balls, 78 of 91 moves ..., 2026-10-28. TR_OLD_LANDSTOP)` - write them this way so the next person knows why.
