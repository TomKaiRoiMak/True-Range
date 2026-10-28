-- What's drawn as lines and rings (range rings, bodies, outlines, the old shapes) on or off.
-- Off: only the cells of the offline-run moves (true_range/simmoves) are drawn.
-- outline: the offline-run moves' cells also get a bright outline round them, smoothed (cut
-- across their corners) - the shape they make, not just the boxes.
-- band: a thin dark band along each edge, where it may hit or not - a coin toss in the game itself.
-- bodies: rings round your body and the bosses' (where they bump), even with lines off.
-- cooldown: a boss's move nearly off cooldown - "glow": its body's edge glows, pulsing;
-- "shape": the move's outline flashes; false: nothing.
-- flip_shapes: the shapes drawn ahead of time mirrored across their length (if they come out the
-- wrong way round in the game).
-- tris: each part filled with triangles to its smooth outline (not cells); flip_tri: they come
-- out on the wrong side of their long edge in the game (all of them: then turn this on).
-- prerendered: the whole-move pictures (anim/trsil) instead - off.
return { lines = false, outline = true, band = true, bodies = true, cooldown = "glow", flip_shapes = false,
    tris = true, flip_tri = false, prerendered = false }
