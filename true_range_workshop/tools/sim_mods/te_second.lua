-- Tropical Experience's monsters with a second stategraph of their own (tools/build_te.ps1 runs each on its own, then
-- tools/merge_moves.lua adds its moves to the monster's): one prefab's file sets two, swapped as it goes - the run takes
-- the first it finds only, 2026-10-20.
return {
    -- (the Tiger Shark: SGtigershark_water swimming, SGtigershark_ground on land (tigershark.lua) - on land its bite)
    -- (not its leap ("jump"): nothing strikes as it goes up; at fallwarn it's moved above whom it's after and its shadow put
    -- down under it, the ground pound landing there (fallpost) - drawn by the shadow (te.lua tigersharkshadow, as_boss). Run
    -- as a move of its own as well, it was drawn where it leapt from and slid after its shadow .6 a frame, over it - "strange,
    -- not right, not smooth at all", the player 2026-10-21)
    { prefab = "tigershark", sg = "SGtigershark_ground", states = { "attack" } },
}
