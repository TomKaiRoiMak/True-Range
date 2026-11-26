# 01 · Overview

[<- Contents](README.md)

## The system has 3 parts

```
┌────────────────────────┐   ┌───────────────────────────────┐   ┌───────────────────────────────┐
│ ① The mod (in game)    │   │ ② Building data (offline)     │   │ ③ Testing (offline + real game)│
│ true_range\            │◀──│ true_range_workshop\tools\    │   │ tr_testbench\  tr_lagjoin\     │
│ draws attack areas     │   │ runs the game's own code,     │   │ true_range_workshop\tests\     │
│ every frame            │   │ one move at a time            │   │ measures whether it's drawn    │
│                        │   │ -> moves_sim*.lua files       │   │ right, every frame, every hit  │
└────────────────────────┘   └───────────────────────────────┘   └───────────────────────────────┘
          ▲                                                                   │
          └──── tools\install.ps1 (unit tests must pass first) copies into the game ◀──┘
```

| Part | What it produces | Who uses it |
|---|---|---|
| ① mod | What players get (Workshop: "True Range+" and "True Range+ (Client)") | players |
| ② data | Every boss's "move shapes": which cells each move hits, on which frame, how it moves | the mod reads them at game start |
| ③ tests | Numbers: hit but not drawn (missed), drawn but no hit (false), flicker, jumps | the team - to decide whether a fix is right |

## How the project thinks (more important than code details)

1. **Don't guess.** Move shapes come from running the game's real stategraphs. If something is drawn wrong, find the real frame in a log before fixing - don't fix from reading code alone.
2. **Measure both sides as numbers.** The host (server) with replays, and a lagging player with the lag bench (the real game joined to a real server).
3. **One bug = a whole class.** Found on one boss? Find which rule is wrong, then check every boss that uses the same rule. Don't fix just the one.
4. **Every new rule can be turned off** (`TR_OLD_xxx`) - for A/B comparison, and to go back if it's worse.
5. **Write everything down.** Measurements, what was tried and dropped, and why - in the commit message, by the template ([VERIFY_PLAN §2](../VERIFY_PLAN.md)).

## How data flows in the game (one frame)

```
modmain.lua           picks the monsters to draw (Pick) + hand-made rings (AGGRO etc.)
   │
   ▼
predict.lua           Track: which move a boss started, which frame it's on (from its animation)
   │                  Flash: the glow warning that a cooldown is nearly over (off by default since 1.1.7)
   │                  Draw / DrawHazards: picks the shape, position, colour
   ▼
simmoves.lua          turns move data into shapes on the ground; things put out (thrown, running)
   │
   ▼
lines.lua             lays the actual pieces on the ground (pools, groups, Begin/End per frame)
```

Each file in detail: [03 Mod code](03-mod-code.md)

## Server vs client - why measure both

- **Host / no caves** - the player's game is the server itself; what you see is where things really are.
- **A player joined to a server** - sees monsters about 0.1-0.3 s late (network + interpolation).
  So the mod has to "draw ahead" for moving things (`SimMoves.LeadMoving`), and the game's Lag Compensation option (Predictive/None) has to be tested both ways.

An offline replay can only model part of this. The judge on the client side is the **lag bench** ([05](05-testing.md)).
