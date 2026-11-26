<h1 align="center">True Range+</h1>

<p align="center"><b>See exactly where a monster's attack will land - before it lands.</b><br>
A Don't Starve Together mod, and the tools used to build and test it.</p>

<p align="center">
  <a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3819645697"><img src="true_range_workshop/preview_client.png" alt="True Range+ (Client)" width="220"></a>
  &nbsp;&nbsp;
  <a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3817047528"><img src="true_range_workshop/preview.png" alt="True Range+ (Server)" width="220"></a>
</p>

<p align="center">
  <a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3819645697"><img src="https://img.shields.io/badge/Steam_Workshop-Client-1b2838?logo=steam&logoColor=white" alt="Steam Workshop: Client"></a>
  <a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3817047528"><img src="https://img.shields.io/badge/Steam_Workshop-Server-1b2838?logo=steam&logoColor=white" alt="Steam Workshop: Server"></a>
  <img src="https://img.shields.io/badge/works_with-Uncompromising_Mode_%C2%B7_Tropical_Experience-6a4c93" alt="Works with Uncompromising Mode and Tropical Experience">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT license"></a>
</p>

---

## Get the mod

| | Version | Use it when |
|---|---|---|
| 🧍 | **[True Range+ (Client)](https://steamcommunity.com/sharedfiles/filedetails/?id=3819645697)** | you play on a server that doesn't have the mod - only you need it |
| 🖥️ | **[True Range+](https://steamcommunity.com/sharedfiles/filedetails/?id=3817047528)** | you host - everyone who joins gets it automatically |

Works with the base game, [Uncompromising Mode](https://steamcommunity.com/sharedfiles/filedetails/?id=3193922031) and [Tropical Experience](https://steamcommunity.com/sharedfiles/filedetails/?id=1505270912).

## Why it's different

- **Not guessed.** Every move's shape comes from running the game's own code offline, frame by frame - hundreds of monsters, 800+ moves.
- **Measured.** Each change is checked in test fights against every monster (with Uncompromising Mode): on the latest set, 17 (host) and 26 (lagging client) of about 59,500 hits landed outside the warning.
- **Lag-aware.** On a server (caves, or joining a friend) the warnings follow the game's Lag Compensation, so they match where the server has you.

## What you see

| | Colour | Means |
|:-:|---|---|
| <img src="https://img.shields.io/badge/-%20%20%20%20-F4A3A3" height="14" alt=""> | faint red | an attack coming later |
| <img src="https://img.shields.io/badge/-%20%20%20%20-FF1A1A" height="14" alt=""> | red | coming soon |
| <img src="https://img.shields.io/badge/-%20%20%20%20-FFD91A" height="14" alt=""> | yellow | about to strike |
| <img src="https://img.shields.io/badge/-%20%20%20%20-9E0005" height="14" alt=""> | deep red | striking now |
| <img src="https://img.shields.io/badge/-%20%20%20%20-A640FF" height="14" alt=""> | purple | only freezes you or puts you to sleep |
| <img src="https://img.shields.io/badge/-%20%20%20%20-40E659" height="14" alt=""> | green ring | your weapon's reach |
| <img src="https://img.shields.io/badge/-%20%20%20%20-E6C21A" height="14" alt=""> | yellow ring | how near a monster comes before it starts attacking you |
| <img src="https://img.shields.io/badge/-%20%20%20%20-D9D9D9" height="14" alt=""> | white ring | your body - the part attacks have to reach |

## Settings

Press **`O`** in game (the key can be changed):

- which monsters are drawn, and at most how many at once
- your reach, friends' rings and reach, Abigail's reach, the yellow ring
- the opacity of each part - attacks, outlines, your rings, other rings - from 0% to 100%
- rings drawn solid or dotted, and how close the dots

**`Ctrl` + `O`** turns everything off or on at once (until you rejoin).

---

## For developers

<details>
<summary><b>What's in this repo</b></summary>

| Folder | What it is |
|---|---|
| `true_range/` | the mod itself - this folder is what gets uploaded to the Workshop |
| `true_range_workshop/tools/` | building each move's data from the game's scripts (`sim_moves.lua`), install, benches |
| `true_range_workshop/tests/` | unit tests, replays of real game logs against the mod's drawing |
| `true_range_workshop/docs/` | developer docs - start at [docs/README.md](true_range_workshop/docs/README.md) |
| `tr_testbench/` | local test mod (server side): spawns bosses and a stand-in player - never uploaded |
| `tr_lagjoin/` | local test mod (client side): joins a test server by itself and records every drawn frame - never uploaded |

</details>

<details>
<summary><b>Getting started</b></summary>

You need Don't Starve Together, [LuaJIT 2.1](https://luajit.org) on your PATH and Windows PowerShell 5.1. Read [Setup](true_range_workshop/docs/02-setup.md), then [Workflow](true_range_workshop/docs/06-workflow.md) before your first change.

```powershell
luajit true_range_workshop/tests/test_sim.lua true_range      # unit tests
powershell -File true_range_workshop/tools/install.ps1         # copy the mod into the game's mods folder
```

- **The game's path is hard-coded** for the original machine (`D:\Games Manager\...`). Search `tools\` and `tests\` for `Games Manager` and change it to yours. Your Klei account folder is found by itself; set `DST_KLEI_ACCOUNT` if you have several.
- The game's own scripts aren't in the repo - they're unpacked from your game into `true_range_workshop/tests/work/`.
- Never commit a `cluster_token.txt` - `.gitignore` keeps them out.

</details>

📋 Open items: [docs/08-status.md](true_range_workshop/docs/08-status.md) · 📝 Changes: `true_range_workshop/patch_notes_<version>.txt`

## License

[MIT](LICENSE) - use it, change it, build on it; keep the copyright notice.
