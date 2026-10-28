-- Player side: while a boss winds up an attack, the real shape it will hit is outlined on the
-- ground (a fan in front of it, a line, a circle...), turning with it.
-- Which attack is coming is told by its animation (players' games see those); the shapes
-- are read from the game's stategraph code (see SHAPES). Distances count from your middle:
-- the game adds your body's size (`addme`) for most of them.

local Telegraph = {}

local Lines = require("true_range/lines")

-- the outline's pieces: one every this many degrees along curves
local ARC_STEP = 6 * DEGREES

-- prefab -> list of { anims = {...}, shape = "fan" | "circle" | "line" | "pound", offset, radius,
-- half (degrees each side, fans), from / to / width (lines), addme, at = "target" (a circle
-- around where its target stood when the attack began), radius = "pound" (its ground pound's
-- reach, from the server), hitframe (pound: the animation frame its ground pound starts) }
local SHAPES = {}

local BEARGER = {
    -- SGbearger "attack": DoArcAttack(inst, 1, BEARGER_MELEE_RANGE), 90 degrees each side
    { anims = { "atk" }, shape = "fan", offset = 1, radius = 6, half = 90, addme = true },
    -- the combo swipes: DoComboArcAttack, COMBO_ARC_OFFSET .5
    { anims = { "atk1", "atk1a", "atk2" }, shape = "fan", offset = .5, radius = 6, half = 90, addme = true },
    -- "pound": GroundPound() on frame 20, its waves rolling out from there
    { anims = { "ground_pound" }, shape = "pound", offset = 0, hitframe = 20 },
}
SHAPES.bearger = BEARGER
SHAPES.mutatedbearger = {
    BEARGER[1], BEARGER[2], BEARGER[3],
    -- "butt": a ground pound 1 behind it on frame 8, then DoAOEAttack(inst, -1, 4)
    { anims = { "butt" }, shape = "pound", offset = -1, hitframe = 8 },
    { anims = { "butt", "butt_pst" }, shape = "circle", offset = -1, radius = 4, addme = true },
}

local DEERCLOPS = {
    -- SGdeerclops "attack" (SpawnIceFx): spikes out to 8 in a cone 35 degrees each side, each
    -- hitting 1 around it; and some 1-3 away all round
    -- The spikes come out near to far: SpawnIceFx on frame 31, sorted by distance, over
    -- ICESPAWNTIME (.25 s), each striking as it appears - a wave rolling out to 9.
    { anims = { "atk" }, shape = "fan", offset = 0, radius = 9, half = 35, addme = true,
      sweep = { frame = 31, time = .25, reach = 9 } },
    { anims = { "atk" }, shape = "circle", offset = 0, radius = 4, addme = true,
      sweep = { frame = 31, time = .25, reach = 9 } },
    -- "laserbeam" (Uncompromising Mode / Winter's Feast): a line of blasts from 1.25 out to
    -- about 9.5 in front, each hitting .7 around it
    { anims = { "atk2" }, shape = "line", from = 1.25, to = 9.5, width = .7, addme = true },
}
SHAPES.deerclops = DEERCLOPS
SHAPES.icedeerclops = DEERCLOPS
SHAPES.mutateddeerclops = {
    DEERCLOPS[1], DEERCLOPS[2],
    -- "icelance": lands where its target stood, ICE_LANCE_RADIUS 5.5 around
    { anims = { "throw", "throw_2" }, shape = "circle", at = "target", radius = 5.5 },
}

local Handmade = require("true_range/handmade")

function Telegraph.Knows(prefab)
    return Handmade.on and SHAPES[prefab] ~= nil
end

--------------------------------------------------------------------------------
-- drawing: solid lines on the screen (true_range/lines)

-- the arc around (cx, cz), radius r, from angle a1 to a2 (radians, the game's way: x + cos,
-- z - sin)
local function Arc(cx, cz, r, a1, a2, style, pieces)
    local n = pieces or math.max(2, math.ceil((a2 - a1) / ARC_STEP))
    local px, pz = cx + r * math.cos(a1), cz - r * math.sin(a1)
    for i = 1, n do
        local a = a1 + (a2 - a1) * i / n
        local x, z = cx + r * math.cos(a), cz - r * math.sin(a)
        Lines.Segment(px, pz, x, z, style)
        px, pz = x, z
    end
end

local function Segment(x1, z1, x2, z2, style)
    Lines.Segment(x1, z1, x2, z2, style)
end

-- style "shape": just the outline (a boss's attack shape, shown all the time); otherwise the
-- warning: a thick outline, filled in
local FILL_STEP = 10 * DEGREES

local function Fan(cx, cz, rot, r, half, style)
    local h = math.min(half, 180) * DEGREES
    if style ~= "shape" then
        if half >= 180 then
            Lines.Disc(cx, cz, r, "fill")
        else
            local n = math.max(1, math.ceil(2 * h / FILL_STEP))
            for i = 0, n - 1 do
                Lines.Wedge(cx, cz, r, rot - h + 2 * h * i / n, rot - h + 2 * h * (i + 1) / n, "fill")
            end
        end
    end
    Arc(cx, cz, r, rot - h, rot + h, style)
    if half < 180 then
        Segment(cx, cz, cx + r * math.cos(rot - h), cz - r * math.sin(rot - h), style)
        Segment(cx, cz, cx + r * math.cos(rot + h), cz - r * math.sin(rot + h), style)
    end
end
-- the part of a fan a wave has already struck, and its front
local function Swept(cx, cz, rot, front, half)
    if front <= 0 then
        return
    end
    local h = math.min(half, 180) * DEGREES
    if half >= 180 then
        Lines.Disc(cx, cz, front, "swept")
    else
        local n = math.max(1, math.ceil(2 * h / FILL_STEP))
        for i = 0, n - 1 do
            Lines.Wedge(cx, cz, front, rot - h + 2 * h * i / n, rot - h + 2 * h * (i + 1) / n, "swept")
        end
    end
    Arc(cx, cz, front, rot - h, rot + h, "edge")
end
-- a strip from `from` to `to` in front of (x, z), `width` to each side, rounded ends
local function Line(x, z, rot, from, to, width)
    local c, s = math.cos(rot), math.sin(rot)
    local px, pz = -s, -c -- (sideways)
    local ax, az = x + from * c, z - from * s
    local bx, bz = x + to * c, z - to * s
    Segment(ax + px * width, az + pz * width, bx + px * width, bz + pz * width)
    Segment(ax - px * width, az - pz * width, bx - px * width, bz - pz * width)
    Arc(bx, bz, width, rot - math.pi / 2, rot + math.pi / 2)
    Arc(ax, az, width, rot + math.pi / 2, rot + math.pi * 1.5)
    Lines.Segment(ax, az, bx, bz, "fill", width * 2)
    Lines.Disc(ax, az, width, "fill")
    Lines.Disc(bx, bz, width, "fill")
end

-- A ground pound's waves (GroundPounder, numbers from the server): wave i strikes everything
-- within first + step * (i - 1) + width, `delay` seconds after the one before; the first on
-- the animation's frame `hitframe`. Drawn as they will come: each wave's reach, the part
-- already swept, and the wave front rolling out. Returns whether (px, pz) is still to be hit.
local function Pound(cx, cz, w, t, hitframe, px, pz)
    local t0 = hitframe * FRAMES
    local reach = {}
    for i = 1, w.rings do
        reach[i] = w.first + w.step * (i - 1) + w.width
    end
    local last = reach[#reach] or 0
    if last <= 0 then
        return false
    end
    -- where the front is now (nothing yet before the first wave)
    local front = nil
    for i = 1, #reach do
        local ti = t0 + (i - 1) * w.delay
        if t >= ti then
            local nxt = reach[i + 1]
            if nxt ~= nil then
                local k = math.min(1, (t - ti) / math.max(w.delay, .01))
                front = reach[i] + (nxt - reach[i]) * k
            else
                front = reach[i]
            end
        end
    end
    Lines.Disc(cx, cz, last, "fill")
    for i = 1, #reach do
        Arc(cx, cz, reach[i], 0, 2 * math.pi, i == #reach and "edge" or "wave")
    end
    if front ~= nil then
        Lines.Disc(cx, cz, front, "swept")
        Arc(cx, cz, front, 0, 2 * math.pi, "edge")
    else
        -- winding up: a ring closing in on the first wave's reach as the moment comes
        local k = math.max(0, math.min(1, 1 - (t0 - t) / .6))
        Arc(cx, cz, reach[1] * k, 0, 2 * math.pi, "wave")
    end
    if px == nil then
        return false
    end
    local d2 = (px - cx) ^ 2 + (pz - cz) ^ 2
    return d2 <= last * last and (front == nil or d2 > front * front)
end
--------------------------------------------------------------------------------
local function Playing(ent, anims)
    for _, anim in ipairs(anims) do
        if ent.AnimState:IsCurrentAnimation(anim) then
            return true
        end
    end
    return false
end

-- where each boss's target stood when its attack began (for shapes at = "target")
local aimed = setmetatable({}, { __mode = "k" })

-- is the point (px, pz) inside these shapes? (the same tests the game makes, your body's size
-- already in the radius)
local function InFan(px, pz, cx, cz, rot, r, half)
    local dx, dz = px - cx, pz - cz
    if dx * dx + dz * dz > r * r then
        return false
    end
    if half >= 180 or (dx == 0 and dz == 0) then
        return true
    end
    local diff = math.abs(((math.atan2(-dz, dx) - rot) + math.pi) % (2 * math.pi) - math.pi)
    return diff <= half * DEGREES
end

local function InLine(px, pz, x, z, rot, from, to, width)
    local c, s = math.cos(rot), math.sin(rot)
    local dx, dz = px - x, pz - z
    local along = dx * c - dz * s
    local side = math.abs(dx * s + dz * c)
    local d = math.max(from, math.min(to, along))
    return (along - d) ^ 2 + side * side <= width * width
end

-- Every frame:
--   ents: bosses near you; ranges(ent) -> what the server said about one (for "pound")
--   my_radius: your body's size; me: where you are ({ x, z })
--   statics: { { ent, radius, offset, half }, ... } - bosses' attack shapes shown all the time
--     (a fan's outline, where a circle would overstate it)
-- Returns true if you stand inside an attack that's winding up.
function Telegraph.Draw(ents, ranges, my_radius, statics, me)
    -- (between Lines.Begin and Lines.End, called by whoever draws the frame)
    local danger = false
    for _, s in ipairs(statics or {}) do
        local ent = s.ent
        if ent:IsValid() then
            local x, _, z = ent.Transform:GetWorldPosition()
            local rot = ent.Transform:GetRotation() * DEGREES
            local cx, cz = x + s.offset * math.cos(rot), z - s.offset * math.sin(rot)
            Fan(cx, cz, rot, s.radius, s.half, "shape")
        end
    end
    for _, ent in ipairs(ents) do
        local shapes = ent:IsValid() and ent.AnimState ~= nil and SHAPES[ent.prefab] or nil
        local any = false
        for _, shape in ipairs(shapes or {}) do
            if Playing(ent, shape.anims) then
                any = true
                local x, _, z = ent.Transform:GetWorldPosition()
                local rot = ent.Transform:GetRotation() * DEGREES
                local radius = shape.radius
                if radius == "pound" then
                    local r = ranges(ent)
                    radius = r ~= nil and r.pound or 0
                end
                if shape.addme and type(radius) == "number" then
                    radius = radius + my_radius
                end
                local offset = shape.offset or 0
                local cx, cz = x + offset * math.cos(rot), z - offset * math.sin(rot)
                local inside = false
                if shape.at == "target" then
                    local a = aimed[ent]
                    if a == nil then
                        local combat = ent.replica.combat
                        local target = combat ~= nil and combat:GetTarget() or nil
                        if target ~= nil and target:IsValid() then
                            local tx, _, tz = target.Transform:GetWorldPosition()
                            a = { x = tx, z = tz }
                            aimed[ent] = a
                        end
                    end
                    if a ~= nil and radius > 0 then
                        Fan(a.x, a.z, 0, radius, 180)
                        inside = me ~= nil and InFan(me.x, me.z, a.x, a.z, 0, radius, 180)
                    end
                elseif (shape.shape == "fan" or shape.shape == "circle") and radius > 0 then
                    local half = shape.shape == "fan" and (shape.half or 180) or 180
                    Fan(cx, cz, rot, radius, half)
                    inside = me ~= nil and InFan(me.x, me.z, cx, cz, rot, radius, half)
                    -- a wave rolling out (Deerclops' spikes): the part already struck, and its front
                    local sw = shape.sweep
                    if sw ~= nil then
                        local k = (ent.AnimState:GetCurrentAnimationTime() - sw.frame * FRAMES) / sw.time
                        if k > 0 then
                            local front = math.min(radius, (sw.reach + (shape.addme and my_radius or 0)) * math.min(1, k))
                            Swept(cx, cz, rot, front, half)
                            if inside and (me.x - cx) ^ 2 + (me.z - cz) ^ 2 <= front * front then
                                inside = false -- (it has passed you)
                            end
                        end
                    end
                elseif shape.shape == "pound" then
                    local r = ranges(ent)
                    local w = r ~= nil and r.waves or nil
                    if w ~= nil then
                        inside = Pound(cx, cz, w, ent.AnimState:GetCurrentAnimationTime(), shape.hitframe or 0,
                            me ~= nil and me.x or nil, me ~= nil and me.z or nil)
                    elseif r ~= nil and r.pound > 0 then
                        Fan(cx, cz, rot, r.pound, 180)
                        inside = me ~= nil and InFan(me.x, me.z, cx, cz, rot, r.pound, 180)
                    end
                elseif shape.shape == "line" then
                    local width = shape.width + (shape.addme and my_radius or 0)
                    Line(x, z, rot, shape.from, shape.to, width)
                    inside = me ~= nil and InLine(me.x, me.z, x, z, rot, shape.from, shape.to, width)
                end
                danger = danger or inside
            end
        end
        if not any then
            aimed[ent] = nil
        end
    end
    return danger
end

-- (for the red rings: inside a fan shown all the time?)
Telegraph.InFan = InFan

-- A ground pound coming back off cooldown, around (x, z): its outer ring fades in as the
-- cooldown runs out (`progress` 0 to 1); when ready it blinks, with the reach of each of its
-- waves inside - its next attack can be the pound.
function Telegraph.Cooldown(x, z, r, progress, ready, waves)
    if r <= 0 then
        return
    end
    if ready then
        local on = math.sin(GetStaticTime() * 10) > 0
        Lines.Pulse("pound_ready", on and .9 or .3)
        Lines.Pulse("pound_wave", on and .45 or .15)
        Arc(x, z, r, 0, 2 * math.pi, "pound_ready")
        if waves ~= nil then
            for i = 1, waves.rings - 1 do
                Arc(x, z, waves.first + waves.step * (i - 1) + waves.width, 0, 2 * math.pi, "pound_wave")
            end
        end
    elseif progress > 0 then
        Lines.Pulse("pound_charging", .06 + .5 * math.min(1, progress))
        Arc(x, z, r, 0, 2 * math.pi, "pound_charging")
    end
end
-- Its next attack is a ground pound and it's about to attack (its target in reach): the
-- pound's reach in red already, before it even starts the move (each wave's reach, filled).
-- Returns whether (px, pz) is inside.
function Telegraph.PoundSoon(x, z, waves, px, pz)
    if waves == nil or waves.rings <= 0 then
        return false
    end
    local last = waves.first + waves.step * (waves.rings - 1) + waves.width
    Lines.Disc(x, z, last, "fill")
    for i = 1, waves.rings do
        Arc(x, z, waves.first + waves.step * (i - 1) + waves.width, 0, 2 * math.pi, i == waves.rings and "edge" or "wave")
    end
    return px ~= nil and (px - x) ^ 2 + (pz - z) ^ 2 <= last * last
end

-- a strip from (x1, z1) to (x2, z2), `width` to each side, rounded ends, filled - what's to be
-- swept between two things closing on each other (a ruins nightmare's horns)
function Telegraph.Lane(x1, z1, x2, z2, width)
    local len = math.sqrt((x2 - x1) ^ 2 + (z2 - z1) ^ 2)
    local rot = math.atan2(-(z2 - z1), x2 - x1)
    local c, s = math.cos(rot), math.sin(rot)
    local px, pz = -s, -c
    Segment(x1 + px * width, z1 + pz * width, x2 + px * width, z2 + pz * width)
    Segment(x1 - px * width, z1 - pz * width, x2 - px * width, z2 - pz * width)
    Arc(x2, z2, width, rot - math.pi / 2, rot + math.pi / 2)
    Arc(x1, z1, width, rot + math.pi / 2, rot + math.pi * 1.5)
    if len > 0 then Lines.Segment(x1, z1, x2, z2, "fill", width * 2) end
    -- (its round ends as halves, outwards - whole discs laid over the strip came out darker at
    -- both ends, two blots)
    local n = math.max(1, math.ceil(math.pi / FILL_STEP))
    for i = 0, n - 1 do
        local a, b = -math.pi / 2 + math.pi * i / n, -math.pi / 2 + math.pi * (i + 1) / n
        Lines.Wedge(x2, z2, width, rot + a, rot + b, "fill")
        Lines.Wedge(x1, z1, width, rot + math.pi + a, rot + math.pi + b, "fill")
    end
end

-- a whole circle's outline (your body ring)
-- (slot: whose ring - kept as a group of its own, laid again only as its size or colour changes,
-- else only moved: 60 pieces laid anew every frame for each body - yours, the boss's - was the
-- mod's biggest piece of the frame in the game's profile with Toadstool, 7% of its Lua time)
local ring_slot = setmetatable({}, { __mode = "k" })
-- (as many pieces as its size wants - about 0.75 of a unit each, 12 to 60; TR_OLD_RINGSEG=1: 60 each)
local function RingPieces(r)
    local n = math.max(2, math.ceil(2 * math.pi / ARC_STEP))
    if not rawget(_G, "TR_OLD_RINGSEG") then n = math.max(12, math.min(n, math.ceil(2 * math.pi * r / .75))) end
    return n
end
function Telegraph.Circle(x, z, r, style, slot)
    if slot == nil or Lines.GroupFor == nil then
        -- (laid piece by piece: the same pieces as kept as a group - 60 still here while the group's were cut to its size,
        -- tests/body_ring.lua's 4 failing, 2026-10-25)
        local n = RingPieces(r)
        Arc(x, z, r, 0, 2 * math.pi, style, n)
        return
    end
    local s = ring_slot[slot]
    if s == nil then s = {} ring_slot[slot] = s end
    local key = "ring|" .. math.floor(r * 100 + .5)
    local g = Lines.GroupFor(s, key)
    if g.sig ~= key or g.ring_style ~= style or g.ring_ver ~= Lines.version then
        Lines.GroupClear(g)
        -- (as many pieces as its size wants: every ring 60, a crowd's body rings were thousands of pieces for the
        -- game to draw - 110-130 frames a second for 144, a player's test (Render.bodies off: 144), 2026-10-23)
        local n = RingPieces(r)
        local px, pz = r, 0
        for i = 1, n do
            local a = 2 * math.pi * i / n
            local qx, qz = r * math.cos(a), -r * math.sin(a)
            local rec = Lines.SegRec(px, pz, qx, qz, style)
            if rec ~= nil then Lines.GroupSeg(g, rec, style, "e") end
            px, pz = qx, qz
        end
        Lines.GroupDone(g)
        g.sig, g.ring_style, g.ring_ver = key, style, Lines.version
    end
    Lines.GroupAt(g, x, z, 0)
end
return Telegraph
