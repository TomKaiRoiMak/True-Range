# True Range - developer docs

True Range is a Don't Starve Together mod that draws the **real attack areas** of bosses, and of the things they put out (fireballs, spikes, lasers), on the ground in real time.
No move's shape is guessed: each comes from running the game's own code offline, and accuracy is measured as numbers on both the host and a lagging client.

> New here? Read in order. Fixing an urgent bug? Go straight to [06 Workflow](06-workflow.md).

## Contents

| # | Page | Read it when |
|---|---|---|
| 01 | [Overview](01-overview.md) | you want to see how the whole system fits together |
| 02 | [Setup](02-setup.md) | day one - getting it to run on your machine |
| 03 | [Mod code (in game)](03-mod-code.md) | you're changing how things are drawn or how moves are tracked |
| 04 | [Move data and how it's built](04-data-pipeline.md) | a new boss, a game update, a move the data lacks |
| 05 | [Testing](05-testing.md) | you need to prove a fix is right |
| 06 | [Workflow and rules](06-workflow.md) | **before changing anything** |
| 07 | [Reference: tools, switches, terms](07-reference.md) | quick lookup |
| 08 | [Status (open items)](08-status.md) | you want to know what's pending and pick up work |
| 📖 | [**Monster and move catalog**](catalog/README.md) | finding any monster or move: which data file and line, where its special code is (408 monsters, 810 moves) |

## 5 things to know before you touch anything

1. **The source is `true_range\`.** The game doesn't read that folder - run `tools\install.ps1` first; only then is it "installed".
2. **Every new rule has a `TR_OLD_xxx` switch** that turns it back to the old behaviour, for A/B comparison - see [06](06-workflow.md).
3. **Don't edit files a bench or replay is reading** while it runs (the results get mixed).
4. **Don't upload to the Workshop yourself.** The project owner uploads. `tr_testbench` and `tr_lagjoin` are never uploaded.
5. **`cluster_token.txt` is secret.** Never commit it or paste it anywhere (`.gitignore` keeps it out).

All rules: [VERIFY_PLAN.md §3](../VERIFY_PLAN.md)

## Other documents

- `../VERIFY_PLAN.md` - what counts as "fixed", the commit template, the team rules (short)
- `git log` - the measurements and reasons behind each fix (since 2026-10-28)
- [history/hash_map.md](history/hash_map.md) - old commit hashes (cited in older notes) mapped to the current ones
- `../patch_notes_<version>.txt` - what changed in each version (for players)
- [04 Data pipeline - tables](04-data-pipeline.md#tables-moves_table) - the table system (`moves_table`)
