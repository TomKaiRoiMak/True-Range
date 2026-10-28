-- Player side: solid shapes laid on the ground (under characters, like the game's own range
-- rings): straight lines, filled wedges and filled discs, in any colour.
-- They come from the mod's own anim, anim/trshapes.zip (white, so they take any colour):
--   "square" 64 x 64 px, "disc" 256 px across, "wedge" 256 x 256 px (a triangle: its tip
--   at the left middle, its base the right edge)
-- At scale 1 the game draws 150 px per unit (its range ring: 1896 px across = 6.33 units
-- radius, see c_showradius); AnimState:SetScale stretches that.
-- (its log lines only with the mod's debugging on - TR_DEBUG, modmain: debug.txt in the mod's folder)
local print = function(...) if rawget(_G, "TR_DEBUG") then _G.print(...) end end

local Lines = {}

local PX_PER_UNIT = 150
local SQUARE_PX = 64
local DISC_PX = 256
local WEDGE_PX = 256

-- style -> colour, thickness (units, for lines), and which ring draws over which
-- (sort: which is drawn over which, higher on top - tested in the game (Lines.SortTest), lines'
-- pieces, fills' and discs' alike: 0 to 7 kept to every way; under 0 taken as 0, over 7 as 7,
-- and two alike the one made later on top (all moved up 4 once: edges and bands at 8 and 9, all
-- alike, laid over each other any which way). Fills under edges and bands; the
-- outline solid and light - the dark band on the deep red striking now, and a see-through
-- outline over it, were the same red: the edge lost in it, though drawn over it)
-- (each that may lie over another its own: two alike laid over each other - striking now on what
-- will strike soon - came out striped, the game drawing their triangles in turn. Faint and later
-- 0, fill 1, strike soon 2, striking now 3, band 4, seam 5, outline and your ring 6. Not 7: the
-- grid only showed 0 to 6 kept against each other - at 7 the outline went under a fill at 3)
local STYLES = {
    -- an attack winding up: a bright outline, its inside, and for
    -- ground pounds the part the wave has already swept, and where each wave reaches
    edge = { colour = { 1, .42, .42, 1 }, width = .1, sort = 6 },
    fill = { colour = { 1, .1, .12, .22 }, width = .06, sort = 1 },
    swept = { colour = { 1, .1, .12, .5 }, width = .06, sort = 1 },
    -- where something may hit (it's not the same every time), and where it's about to
    fill_light = { colour = { 1, .2, .2, .08 }, width = .06, sort = 0 },
    -- the part striking next (within a moment): all of it yellow - step out
    strike = { colour = { 1, .85, .1, .5 }, width = .06, sort = 2 },
    -- (striking now: the frames it does its damage - deep red)
    hit = { colour = { .75, 0, .02, .85 }, width = .06, sort = 3 },
    -- (parts striking later on: fainter, the later)
    later = { colour = { 1, .12, .12, .16 }, width = .06, sort = 0 },
    last = { colour = { 1, .15, .15, .11 }, width = .06, sort = 0 },
    -- the outline round where something may hit (not the same every time)
    edge_light = { colour = { 1, .2, .2, .3 }, width = .08, sort = 2 },
    -- (the band along its edge, inside and out: a frame or a step decides it there)
    -- (the coin toss along its edge: thin, dark)
    -- (opaque: its pieces overlap at their joints, and an opaque one over another shows no seam)
    -- (3: under the seam between colours (4) - the two alike, where they met at a corner which lay
    -- over which went by which was made later, changing frame to frame)
    edge_zone = { colour = { .55, .04, .07, 1 }, width = .1, sort = 4 },
    -- (between parts of different colours: a thin smooth dark line over their cells' steps)
    edge_seam = { colour = { .4, 0, .04, .9 }, width = .25, sort = 5 },
    -- a move that does no harm, only a status (sleep, knockback, slowed, stuck...): the same, in purple
    st_edge = { colour = { .75, .3, 1, .6 }, width = .1, sort = 6 },
    st_fill = { colour = { .65, .25, 1, .22 }, width = .06, sort = 1 },
    st_strike = { colour = { .85, .55, 1, .5 }, width = .06, sort = 2 },
    st_hit = { colour = { .5, .1, .85, .85 }, width = .06, sort = 3 },
    st_later = { colour = { .65, .25, 1, .16 }, width = .06, sort = 0 },
    st_last = { colour = { .65, .25, 1, .11 }, width = .06, sort = 0 },
    st_edge_zone = { colour = { .3, .06, .5, 1 }, width = .1, sort = 4 },
    st_edge_seam = { colour = { .25, .02, .4, .9 }, width = .25, sort = 5 },
    -- (whole shapes, drawn ahead of time: their pictures are white - faint inside, a strong
    -- darker band and a fine line at the edge - and take these colours whole)
    shape_hit = { colour = { .85, .04, .04, 1 }, width = .1, sort = 3 },
    shape_strike = { colour = { 1, .82, .1, .95 }, width = .1, sort = 2 },
    shape_fill = { colour = { 1, .15, .12, .75 }, width = .1, sort = 1 },
    shape_later = { colour = { 1, .15, .12, .55 }, width = .1, sort = 0 },
    shape_last = { colour = { 1, .15, .12, .4 }, width = .1, sort = 0 },
    shape_light = { colour = { 1, .25, .25, .3 }, width = .1, sort = 0 },
    shape_flash = { colour = { 1, 1, 1, 1 }, width = .1, sort = 6 },
    -- (a move it may make again soon: its outline, flashed)
    flash = { colour = { 1, 1, 1, .85 }, width = .2, sort = 5 },
    -- (or its body's edge, glowing)
    -- (red, fading outwards: strong at its inner edge, faint at its outer)
    glow_1 = { colour = { 1, .12, .08, .8 }, width = .24, sort = 4 },
    glow_2 = { colour = { 1, .12, .08, .5 }, width = .24, sort = 4 },
    glow_3 = { colour = { 1, .12, .08, .28 }, width = .24, sort = 4 },
    glow_4 = { colour = { 1, .12, .08, .12 }, width = .24, sort = 4 },
    halo = { colour = { 1, .25, .25, .1 }, width = .06, sort = 0 },
    soon = { colour = { 1, .05, .05, .55 }, width = .06, sort = 2 },
    wave = { colour = { 1, .55, .55, .8 }, width = .06, sort = 3 },
    -- a ground pound: ready (its next attack), the reach of its waves, coming back off cooldown
    pound_ready = { colour = { .75, .25, 1, .8 }, width = .11, sort = 0 },
    pound_wave = { colour = { .75, .25, 1, .4 }, width = .05, sort = 0 },
    pound_charging = { colour = { .75, .25, 1, .45 }, width = .08, sort = 0 },
    -- a boss's attack shape, shown all the time (fainter than a real warning)
    shape = { colour = { 1, .15, .1, .75 }, width = .07, sort = 0 },
    -- bodies: what blocks you (a monster's) / what attacks must reach (yours)
    -- (half as strong as they were - they hid too much)
    monster_body = { colour = { .85, .85, 1, .28 }, width = .06, sort = 0 },
    body = { colour = { 1, 1, 1, .45 }, width = .07, sort = 6 },
    body_danger = { colour = { 1, .6, .05, 1 }, width = .1, sort = 6 },
    body_hit = { colour = { 1, .05, .05, 1 }, width = .24, sort = 6 },
    -- how far you reach (green), and a friend (light blue) - by the weapon held
    own = { colour = { .25, 1, .35, .43 }, width = .07, sort = 6 },
    friend_own = { colour = { .35, .7, 1, .38 }, width = .06, sort = 6 },
    -- Abigail's reach (pale violet), and where a command of hers lands as you aim it (stronger)
    abigail = { colour = { .8, .6, 1, .4 }, width = .06, sort = 6 },
    abigail_cmd = { colour = { .85, .65, 1, .8 }, width = .08, sort = 6 },
    -- a monster's reach where it starts attacking you (yellow)
    attack_start = { colour = { 1, .85, .1, .4 }, width = .06, sort = 0 },
}

-- (pieces kept by kind, one heap whatever their sort order - nothing laid over anything else now
-- (true_range/simmoves), so which the game draws on top doesn't matter)
local pools = { square = {}, disc = {}, wedge = {}, tri = {} }
local used = { square = {}, disc = {}, wedge = {}, tri = {} }
local shown_top = { square = {}, disc = {}, wedge = {}, tri = {} }
local shapes, shapes_used = {}, 0  -- (whole shapes drawn ahead of time: Lines.Shape)
-- (the layer drawn in: the game's ground effects' own. Tried under them all (LAYER_GROUND): there
-- what's sorted under 4 went under the ground itself - the fills gone, only edges and bands - and
-- past 5 all alike, laid over each other any which way: two orders where six are needed)
local layer = LAYER_BACKGROUND

-- (testing: pieces made so far - true_range modmain's frame timing)
Lines.created = 0
-- (testing - F8 in true_range modmain: every piece hidden, all else the same - what the game's
-- drawing of them costs, apart from working them out. Each piece made, kept to hide or show)
Lines.unseen = false
local everything = {}
local function ShowP(p)
    if not Lines.unseen then p:Show() end
end
function Lines.SetUnseen(on)
    Lines.unseen = on
    for _, p in ipairs(everything) do
        if p:IsValid() then
            if on then p:Hide() elseif p._hidden == false then p:Show() end
        end
    end
end
local function New(anim)
    Lines.created = Lines.created + 1
    local inst = CreateEntity()
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst.AnimState:SetBank("trshapes")
    inst.AnimState:SetBuild("trshapes")
    -- (held on its first frame: the compiled anim's last frames are empty, so played to the end
    -- it would vanish)
    inst.AnimState:SetPercent(anim, 0)
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(layer)
    inst._layer = layer
    everything[#everything + 1] = inst
    -- (made while hidden for testing: hidden)
    if Lines.unseen then inst:Hide() end
    return inst
end

-- the next piece of this kind, coloured for `style`
local function Take(anim, style)
    local st = STYLES[style] or STYLES.edge
    -- (one heap whatever its sort: kept by sort, the early fights made a new piece mid-frame
    -- every time - not there the frame it was made, the shape flickered in and out)
    local s = 0
    local n = (used[anim][s] or 0) + 1
    used[anim][s] = n
    local pool = pools[anim][s]
    if pool == nil then pool = {} pools[anim][s] = pool end
    local p = pool[n]
    if p == nil or not p:IsValid() then
        p = New(anim)
        pool[n] = p
    end
    -- (the colour looked at every time: a style's opacity can pulse - but told the game only when
    -- it changed: hundreds of pieces, most the same as the frame before)
    local c = st.colour
    if p._r ~= c[1] or p._g ~= c[2] or p._b ~= c[3] or p._a ~= c[4] then
        p._r, p._g, p._b, p._a = c[1], c[2], c[3], c[4]
        p.AnimState:SetMultColour(c[1], c[2], c[3], c[4])
    end
    -- (the sort order told the game only when it changed - the style's own can, Lines.TestEdge)
    if p._sort ~= (st.sort or 4) then
        p.style, p._sort = style, st.sort or 4
        p.AnimState:SetSortOrder(p._sort)
    end
    if p._layer ~= layer then
        p._layer = layer
        p.AnimState:SetLayer(layer)
    end
    if p._hidden ~= false then
        p._hidden = false
        ShowP(p)
    end
    -- (how far up its heap pieces are shown: Lines.End hides up to there, not the whole heap)
    local top = shown_top[anim]
    if n > (top[s] or 0) then top[s] = n end
    return p
end

-- where a piece lies, turned and stretched - told the game only what changed
-- (testing: modmain's frame timing - pieces laid, calls made to the game, groups laid again, moved)
Lines.laid, Lines.calls, Lines.group_builds, Lines.groups_moved = 0, 0, 0, 0
local function Place(p, x, z, deg, sx, sy)
    Lines.laid = Lines.laid + 1
    if p._x ~= x or p._z ~= z then
        p._x, p._z = x, z
        p.Transform:SetPosition(x, 0, z)
        Lines.calls = Lines.calls + 1
    end
    if p._deg ~= deg then
        p._deg = deg
        p.Transform:SetRotation(deg)
        Lines.calls = Lines.calls + 1
    end
    if p._sx ~= sx or p._sy ~= sy then
        p._sx, p._sy = sx, sy
        p.AnimState:SetScale(sx, sy)
        Lines.calls = Lines.calls + 1
    end
end

-- How far everything that strikes is drawn moved, this frame - a player's game with the game's lag
-- compensation shows you on ahead of where the server has you, and the server strikes where it has you:
-- each move, thing and ring laid that much on with you, so your body out of the red is out of it as the
-- server has it (modmain: you as shown less you as the server tells, 0 the host's own). Not you, your
-- reach, the monsters' bodies, friends or Abigail - shown where they are (NOSHIFT)
Lines.ox, Lines.oz = 0, 0
local NOSHIFT = { monster_body = true, body = true, body_danger = true, body_hit = true, own = true, friend_own = true,
    abigail = true, abigail_cmd = true, sort_test = true }
local function Off(style)
    if NOSHIFT[style] then return 0, 0 end
    return Lines.ox, Lines.oz
end

-- a style's opacity, for this frame (the warning's inside breathes in and out)
function Lines.Pulse(style, alpha)
    local st = STYLES[style]
    if st ~= nil then
        st.colour[4] = alpha
    end
end

-- Pieces made ahead, a few a frame, hidden till wanted: a big move's first frame would make
-- hundreds at once - a hitch (the Celestial Champion's first laser: 380 in one frame)
-- (triangles for fills and corners, squares for lines)
local WARM = { tri = { [0] = 2200 }, square = { [0] = 800 } }
-- (pieces made ahead for groups - true_range/lines GroupPiece: taken, not made, as a thing
-- appears; hidden, belonging to none yet)
local STOCK = { tri = 4000, square = 2500 }
local stock = { tri = {}, square = {} }
Lines.stock_taken, Lines.stock_short = 0, 0  -- (testing: taken from it; wanted with it empty)
function Lines.Warm(per_frame)
    local n = 0
    for anim, by_sort in pairs(WARM) do
        for s, want in pairs(by_sort) do
            local pool = pools[anim][s]
            if pool == nil then pool = {} pools[anim][s] = pool end
            while #pool < want and n < per_frame do
                local p = New(anim)
                p._hidden = true
                p:Hide()
                pool[#pool + 1] = p
                n = n + 1
            end
        end
    end
    -- (and the groups' own stock, as many again: a thing new to the screen takes its pieces from
    -- it - the Crystal Deerclops' volley of spikes made 1900 pieces in one frame, 60ms)
    for anim, want in pairs(STOCK) do
        local list = stock[anim]
        while #list < want and n < per_frame do
            local p = New(anim)
            p._hidden = true
            p:Hide()
            list[#list + 1] = p
            n = n + 1
        end
    end
end

function Lines.Begin()
    shapes_used = 0
    for _, by_sort in pairs(used) do
        for s in pairs(by_sort) do by_sort[s] = 0 end
    end
end

-- a straight line from (x1, z1) to (x2, z2) (width: its thickness, if not the style's; exact:
-- not stretched past its ends - pieces along a curve, whose square ends would stick out)
-- (where a line's piece lies: its middle, turning, stretch - or nothing, too short)
local function SegCalc(x1, z1, x2, z2, style, width, exact)
    local dx, dz = x2 - x1, z2 - z1
    local len = math.sqrt(dx * dx + dz * dz)
    if len < .01 then
        return nil
    end
    local st = STYLES[style] or STYLES.edge
    width = width or st.width
    -- (the game's rotation: 0 points along +x, and turns from +x towards -z)
    -- (a little longer, so the joints between pieces don't show - only by a line's thickness:
    -- a wide band would grow square corners past the round ends drawn on it)
    -- (its edges sharp - the build's square reads one spot of its texture, see
    -- true_range_workshop/tools/tri_geometry.ps1: pieces side by side meet exactly)
    local unit = SQUARE_PX / PX_PER_UNIT
    return (x1 + x2) / 2, (z1 + z2) / 2, math.deg(math.atan2(-dz, dx)),
        (len + (exact and 0 or math.min(width, st.width))) / unit, width / unit
end
-- (one "square" a line - nothing is laid over anything else now (true_range/simmoves: the outline
-- and band just outside what's filled), so which kind of piece the game draws on top doesn't
-- matter; laid as two triangles they were twice the pieces - with the Great Depths Worm's 33
-- segments over 5000 a frame, the game's frames dropping. SegTris kept for the test.)
local SegTris  -- (below, with the triangles)
function Lines.Segment(x1, z1, x2, z2, style, width, exact)
    style = style or "edge"
    local mx, mz, deg, sx, sy = SegCalc(x1, z1, x2, z2, style, width, exact)
    if mx == nil then
        return
    end
    local ox, oz = Off(style)
    Place(Take("square", style), mx + ox, mz + oz, deg, sx, sy)
end
-- A line's piece worked out once, laid down as often as wanted (Lines.PutSeg): the same each
-- frame, as long as what it's part of stays put
function Lines.SegRec(x1, z1, x2, z2, style, width, exact)
    local mx, mz, deg, sx, sy = SegCalc(x1, z1, x2, z2, style or "edge", width, exact)
    if mx == nil then
        return nil
    end
    return { mx, mz, deg, sx, sy }
end
-- (dx, dz: moved by that much - one worked out round 0, 0, laid at many places)
function Lines.PutSeg(r, style, dx, dz)
    local ox, oz = Off(style)
    Place(Take("square", style), r[1] + (dx or 0) + ox, r[2] + (dz or 0) + oz, r[3], r[4], r[5])
end
Lines._SegTris = function(...) return SegTris(...) end
Lines._SegCalc = SegCalc

-- a filled disc
function Lines.Disc(x, z, r, style)
    local p = Take("disc", style)
    local s = 2 * r / (DISC_PX / PX_PER_UNIT)
    local ox, oz = Off(style)
    Place(p, x + ox, z + oz, 0, s, s)
end

-- a filled thin triangle from (x, z) out to `r`, from angle a1 to a2 (radians, the game's
-- way: x + cos, z - sin; a2 - a1 well under 90 degrees)
function Lines.Wedge(x, z, r, a1, a2, style)
    local mid = (a1 + a2) / 2
    local half = (a2 - a1) / 2
    local p = Take("wedge", style)
    local unit = WEDGE_PX / PX_PER_UNIT
    -- (its base sits at r along the middle; its far corners at r on the arc's chord)
    local len = r * math.cos(half)
    local ox, oz = Off(style)
end

-- A filled triangle (a, b, c: world x, z), as two right-angled ones (the picture "tri": its right
-- angle at its pivot, one side along its width, the other along its height). Which way its
-- height lies on the ground, turned: TRI_SIDE (the other way if the game mirrors it -
-- true_range/render: flip_tri).
local TRI_PX = 256
local Render = require("true_range/render")
-- (one right-angled piece: its corner f, along to p, up to a - where it lies, turning, stretch)
local function RightTriCalc(fx, fz, px, pz, ax, az)
    local lx, lz = px - fx, pz - fz
    local len = math.sqrt(lx * lx + lz * lz)
    local hx, hz = ax - fx, az - fz
    local h = math.sqrt(hx * hx + hz * hz)
    if len < .001 or h < .001 then
        return nil
    end
    local deg = math.deg(math.atan2(-lz, lx))
    -- (the side its height goes to, turned so: a quarter turn on from its width)
    local r = math.rad(deg + 90)
    local sx, sz = math.cos(r), -math.sin(r)
    local side = (hx * sx + hz * sz) >= 0 and 1 or -1
    if Render.flip_tri then side = -side end
    -- (its shape is the build's own three corners, not a picture's soft edge: exact - see
    -- true_range_workshop/tools/tri_geometry.ps1)
    local unit = TRI_PX / PX_PER_UNIT
    return fx, fz, deg, len / unit, side * h / unit
end
-- (a line's rectangle - its width across, and a line's width more in length unless exact - as two
-- right-angled triangles: corners A B C D round it, the right angles at B and D)
SegTris = function(x1, z1, x2, z2, style, width, exact)
    local dx, dz = x2 - x1, z2 - z1
    local len = math.sqrt(dx * dx + dz * dz)
    if len < .01 then return nil end
    local st = STYLES[style] or STYLES.edge
    width = width or st.width
    local ext = exact and 0 or math.min(width, st.width)
    local ux, uz = dx / len, dz / len
    local nx, nz = -uz * width / 2, ux * width / 2
    local ax, az = x1 - ux * ext / 2, z1 - uz * ext / 2
    local bx, bz = x2 + ux * ext / 2, z2 + uz * ext / 2
    local a = { RightTriCalc(bx + nx, bz + nz, ax + nx, az + nz, bx - nx, bz - nz) }
    local b = { RightTriCalc(ax - nx, az - nz, bx - nx, bz - nz, ax + nx, az + nz) }
    if a[1] == nil or b[1] == nil then return nil end
    return a, b
end
local function RightTri(fx, fz, px, pz, ax, az, style)
    local x, z, deg, sx, sy = RightTriCalc(fx, fz, px, pz, ax, az)
    if x ~= nil then
        local ox, oz = Off(style)
        -- (laid - this line was lost as Off came in, 2026-10-22: every triangle laid this way (Lines.Tri - simmoves
        -- straight-drawn hazards, band joins, filled shapes not kept) drew nothing; tests/pool_hide.lua, 2026-10-25)
        Place(Take("tri", style), x + ox, z + oz, deg, sx, sy)
    end
end
-- (split at the foot of the corner across from the longest side: f, and the corners b, c, a)
local function Split(ax, az, bx, bz, cx, cz)
    local ab = (ax - bx) ^ 2 + (az - bz) ^ 2
    local bc = (bx - cx) ^ 2 + (bz - cz) ^ 2
    local ca = (cx - ax) ^ 2 + (cz - az) ^ 2
    if ab >= bc and ab >= ca then ax, az, bx, bz, cx, cz = cx, cz, ax, az, bx, bz
    elseif ca >= ab and ca >= bc then ax, az, bx, bz, cx, cz = bx, bz, cx, cz, ax, az end
    -- (now bc is the longest: a's foot on it)
    local dx, dz = cx - bx, cz - bz
    local l2 = dx * dx + dz * dz
    if l2 < 1e-9 then return nil end
    local t = ((ax - bx) * dx + (az - bz) * dz) / l2
    return bx + dx * t, bz + dz * t, bx, bz, cx, cz, ax, az
end
function Lines.Tri(ax, az, bx, bz, cx, cz, style)
    local fx, fz, b1, b2, c1, c2, a1, a2 = Split(ax, az, bx, bz, cx, cz)
    if fx == nil then return end
    RightTri(fx, fz, b1, b2, a1, a2, style)
    RightTri(fx, fz, c1, c2, a1, a2, style)
end
-- A triangle's two pieces worked out once (into out), laid down as often as wanted (Lines.PutTri)
function Lines.TriRecs(ax, az, bx, bz, cx, cz, out)
    local fx, fz, b1, b2, c1, c2, a1, a2 = Split(ax, az, bx, bz, cx, cz)
    if fx == nil then return end
    for _, p in ipairs({ { b1, b2 }, { c1, c2 } }) do
        local x, z, deg, sx, sy = RightTriCalc(fx, fz, p[1], p[2], a1, a2)
        if x ~= nil then out[#out + 1] = { x, z, deg, sx, sy } end
    end
end
-- (testing, to be removed: the deep red striking now at sort 2 and the outline light and solid,
-- as now (1); the deep red at 3 (2) - over the edges, if 3 were drawn over 4 and 5; and the
-- outline see-through red as it was too (3))
local edge_test = 1
-- (bumped when a style's colour is changed for good - groups laid before then laid again)
Lines.version = 0
function Lines.TestEdge()
    Lines.version = Lines.version + 1
    edge_test = edge_test % 3 + 1
    local hit_sort = edge_test == 1 and 3 or 4
    STYLES.hit.sort, STYLES.st_hit.sort = hit_sort, hit_sort
    local c = edge_test == 3 and { 1, .1, .12, .55 } or { 1, .42, .42, 1 }
    for k = 1, 4 do STYLES.edge.colour[k] = c[k] end
    return edge_test
end
function Lines.PutTri(r, style, dx, dz)
    local ox, oz = Off(style)
    Place(Take("tri", style), r[1] + (dx or 0) + ox, r[2] + (dz or 0) + oz, r[3], r[4], r[5])
end

-- (testing, to be removed: which sort order the game draws over which - a grid round (x, z), 7 by
-- 7: along one way the first piece (red) at sort 0 to 6, along the other the second (blue) at 0
-- to 6, the two over each other in each cell; white marks the cell of 0 and 0, yellow 0 for red
-- and 6 for blue. Called again: the next test - 1: red a line's piece ("square"), blue a fill's
-- ("tri"); 2: both lines' pieces; 3: both fills'; 4: red a disc (a plain picture), blue a line's;
-- 5: red a disc, blue a fill's; then taken away)
local sort_test, sort_mode = nil, 0
function Lines.SortTest(x, z)
    if sort_test ~= nil then
        for _, p in ipairs(sort_test) do if p:IsValid() then p:Remove() end end
        sort_test = nil
    end
    sort_mode = sort_mode % 7 + 1
    if sort_mode == 7 then return 0 end
    sort_test = {}
    local function Piece(anim, colour, sort)
        local p = New(anim)
        p.AnimState:SetMultColour(colour[1], colour[2], colour[3], colour[4])
        p.AnimState:SetSortOrder(sort)
        sort_test[#sort_test + 1] = p
        return p
    end
    local RED, BLUE = { 1, .05, .05, 1 }, { .1, .45, 1, 1 }
    -- (a bar across the cell's middle, or a right-angled triangle over its left half)
    local function Bar(cx, cz, colour, sort, dz)
        local mx, mz, deg, sx, sy = SegCalc(cx - .5, cz + dz, cx + .5, cz + dz, "edge", .35, true)
        Place(Piece("square", colour, sort), mx, mz, deg, sx, sy)
    end
    local function Tri(cx, cz, colour, sort, dx)
        -- (its right angle on the bar's middle line, along it: over half the bar's width whichever side the game lays it - Render.flip_tri; first laid beside the bar, never over it)
        local fx, fz, tdeg, tsx, tsy = RightTriCalc(cx - .5 + dx, cz, cx + .5 + dx, cz, cx - .5 + dx, cz + .8)
        if fx ~= nil then Place(Piece("tri", colour, sort), fx, fz, tdeg, tsx, tsy) end
    end
    -- (a disc - a plain picture, its edge soft: not a triangle made of its own three corners)
    local function Disc(cx, cz, colour, sort)
        local s = .8 / (DISC_PX / PX_PER_UNIT)
        Place(Piece("disc", colour, sort), cx, cz, 0, s, s)
    end
    local GAP = 1.4
    for i = 0, 6 do
        for j = 0, 6 do
            local cx, cz = x + (i - 3) * GAP, z + (j - 3) * GAP
            if sort_mode == 1 then
                Bar(cx, cz, RED, i, 0) Tri(cx, cz, BLUE, j, 0)
            elseif sort_mode == 2 then
                -- (two bars crossing: the second a little up, turned square to the first - made
                -- with the first's ends: a cross)
                Bar(cx, cz, RED, i, 0)
                local mx, mz, deg, sx, sy = SegCalc(cx, cz - .5, cx, cz + .5, "edge", .35, true)
                Place(Piece("square", BLUE, j), mx, mz, deg, sx, sy)
            elseif sort_mode == 3 then
                Tri(cx, cz, RED, i, 0) Tri(cx, cz, BLUE, j, .35)
            elseif sort_mode == 6 then
                -- (how far the numbers go: two lines' pieces, crossing, at -10, -1, 0, 7, 8, 15, 100)
                local BIG = { -10, -1, 0, 7, 8, 15, 100 }
                Bar(cx, cz, RED, BIG[i + 1], 0)
                local mx, mz, deg, sx, sy = SegCalc(cx, cz - .5, cx, cz + .5, "edge", .35, true)
                Place(Piece("square", BLUE, BIG[j + 1]), mx, mz, deg, sx, sy)
            elseif sort_mode == 4 then
                Disc(cx - .15, cz, RED, i) Bar(cx, cz, BLUE, j, 0)
            else
                Disc(cx - .15, cz, RED, i) Tri(cx, cz, BLUE, j, .2)
            end
        end
    end
    -- (marks: which corner is which, whichever way the camera looks)
    local function Mark(i, j, colour)
        local cx, cz = x + (i - 3) * GAP, z + (j - 3) * GAP
        local mx, mz, deg, sx, sy = SegCalc(cx + .45, cz + .45, cx + .6, cz + .6, "edge", .2, true)
        Place(Piece("square", colour, 7), mx, mz, deg, sx, sy)
    end
    Mark(0, 0, { 1, 1, 1, 1 })
    Mark(0, 6, { 1, 1, 0, 1 })
    return sort_mode
end
-- A whole shape, drawn ahead of time (anim/trsil, animation `name`): its middle at (x, z), turned
-- `deg` (its picture's width along that way), `scale` times its picture's size, coloured for
-- `style` (flip: mirrored across its length).
function Lines.Shape(name, x, z, deg, scale, style, flip)
    shapes_used = shapes_used + 1
    local p = shapes[shapes_used]
    if p == nil or not p:IsValid() then
        p = CreateEntity()
        --[[Non-networked entity]]
        p.entity:SetCanSleep(false)
        p.persists = false
        p.entity:AddTransform()
        p.entity:AddAnimState()
        p:AddTag("CLASSIFIED")
        p:AddTag("NOCLICK")
        p:AddTag("FX")
        p.AnimState:SetBank("trsil")
        p.AnimState:SetBuild("trsil")
        p.AnimState:SetLightOverride(1)
        p.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
        p.AnimState:SetLayer(layer)
        p._layer = layer
        shapes[shapes_used] = p
    end
    if p._layer ~= layer then
        p._layer = layer
        p.style = nil
        p.AnimState:SetLayer(layer)
    end
    if p.shape ~= name then
        p.shape = name
        p.AnimState:SetPercent(name, 0)
    end
    local st = STYLES[style] or STYLES.edge
    local c = st.colour
    p.AnimState:SetMultColour(c[1], c[2], c[3], c[4])
    if p.style ~= style or p._layer ~= layer then
        p.style = style
        p.AnimState:SetSortOrder(st.sort or 1)
    end
    local ox, oz = Off(style)
    p.Transform:SetPosition(x + ox, 0, z + oz)
    p.Transform:SetRotation(deg)
    p.AnimState:SetScale(scale, flip and -scale or scale)
    ShowP(p)
end

-- Groups: one thing's pieces kept together under one parent, laid round it - moved, it's the
-- parent alone that's told; its pieces told again only when what's drawn changes (another turn,
-- other colours). Laid down one by one every frame, a hundred worm segments were thousands of
-- the game's calls a frame: the frame rate down from 60 to under 50 with one worm. A group is
-- bound to its thing (`slot`) while drawn each frame; one not drawn a frame is let go, its pieces
-- hidden, kept for another.
local frame = 0
local bound = setmetatable({}, { __mode = "k" })  -- slot -> { f = frame, n = drawn in it, g = { group } }
local groups_free = {}  -- (let go, by what they held last (sig): key -> { group })
local n_free = 0
local function PutFree(g)
    g.freed = frame
    local k = g.sig or false
    local list = groups_free[k]
    if list == nil then list = {} groups_free[k] = list end
    list[#list + 1] = g
    n_free = n_free + 1
end
-- (groups let go and not wanted again for TRIM_AFTER frames (a minute): taken away, a few a frame - the
-- worm and the deerclops' spikes left 27000 pieces standing about, hidden, the game minding
-- every one; kept as many as were wanted in the last few seconds)
local TRIM_AFTER, TRIM_EACH, TRIM_EVERY = 1800, 8, 10
Lines.groups_trimmed = 0  -- (testing: modmain's frame timing)
local function TrimFree()
    if n_free == 0 or frame % TRIM_EVERY ~= 0 then return end
    local done = 0
    for k, list in pairs(groups_free) do
        local i = 1
        while i <= #list and done < TRIM_EACH do
            local g = list[i]
            if frame - (g.freed or frame) > TRIM_AFTER then
                for _, pl in pairs(g.pieces) do
                    for _, p in ipairs(pl) do p:Remove() end
                end
                for _, pl in pairs(g.slots or {}) do
                    for _, p in pairs(pl) do p:Remove() end
                end
                g.parent:Remove()
                table.remove(list, i)
                n_free, done = n_free - 1, done + 1
                Lines.groups_trimmed = Lines.groups_trimmed + 1
            else
                i = i + 1
            end
        end
        if #list == 0 then groups_free[k] = nil end
        if done >= TRIM_EACH then return end
    end
end
local function TakeFree(key)
    if n_free == 0 then return nil end
    local k = key
    local list = key ~= nil and groups_free[key] or nil
    if list == nil then
        -- (none that held the same: any)
        k, list = next(groups_free)
    end
    if list == nil then return nil end
    n_free = n_free - 1
    local g = table.remove(list)
    -- (none left that held that: its list gone - not kept, nor what it held)
    if #list == 0 then groups_free[k] = nil end
    return g
end
Lines.groups_made, Lines.groups_revived = 0, 0  -- (testing: modmain's frame timing)
-- (a group's piece coloured for style - told the game only what changed)
local function GroupStyle(p, style)
    local st = STYLES[style] or STYLES.edge
    local c = st.colour
    if p._r ~= c[1] or p._g ~= c[2] or p._b ~= c[3] or p._a ~= c[4] then
        p._r, p._g, p._b, p._a = c[1], c[2], c[3], c[4]
        p.AnimState:SetMultColour(c[1], c[2], c[3], c[4])
    end
    if p._sort ~= (st.sort or 4) then
        p.style, p._sort = style, st.sort or 4
        p.AnimState:SetSortOrder(p._sort)
    end
end
-- (a group's pieces in three sets, each laid again on its own - true_range/simmoves Lay: f its
-- fills, e its outline and band round it, s the seams between two colours. A seam come or gone
-- as the Crystal Deerclops' spikes changed colour shifted every piece after it: whole groups
-- laid anew, a volley's at once, 2000-5800 pieces in one frame)
local KEY = { tri = { f = "tri_f", e = "tri_e", s = "tri_s" }, square = { f = "square_f", e = "square_e", s = "square_s" },
    disc = { f = "disc_f" } }
local SET_KEYS = { f = { "tri_f", "square_f", "disc_f" }, e = { "tri_e", "square_e" }, s = { "tri_s", "square_s" } }
Lines.FILL_TRI = KEY.tri.f
local function GroupPiece(g, anim, key, style)
    local list = g.pieces[key]
    if list == nil then list = {} g.pieces[key] = list end
    local n = (g.used[key] or 0) + 1
    g.used[key] = n
    local p = list[n]
    -- (not asked whether it's still there: the mod's own, never taken away while the world runs -
    -- asked, it was hundreds of calls to the game a frame)
    if p == nil then
        -- (from the stock made ahead, if any left - Lines.Warm)
        local s = stock[anim]
        p = s ~= nil and s[#s] or nil
        if p ~= nil then
            s[#s] = nil
            Lines.stock_taken = Lines.stock_taken + 1
        else
            p = New(anim)
            Lines.stock_short = Lines.stock_short + 1
        end
        p.entity:SetParent(g.parent.entity)
        list[n] = p
    end
    GroupStyle(p, style)
    if p._layer ~= layer then
        p._layer = layer
        p.AnimState:SetLayer(layer)
    end
    if p._hidden ~= false then
        p._hidden = false
        ShowP(p)
    end
    return p
end
-- (only its colour changed - what it's part of to strike sooner: the j-th piece of that kind,
-- as laid - true_range/simmoves Recolour)
function Lines.GroupRecolour(g, anim, j, style)
    local p = g.pieces[anim] ~= nil and g.pieces[anim][j] or nil
    if p ~= nil then GroupStyle(p, style) end
end
-- the group drawn for `slot` this frame - and whether it holds what was laid in it last (then
-- only Lines.GroupAt; else Lines.GroupClear, its pieces laid again, Lines.GroupDone)
-- (one thing may draw two a frame: each its own, by the order they're drawn in)
-- (key: what it'll hold - a new one given one let go that held the same if any: its pieces lie
-- where they're wanted already, only shown again - not each laid anew)
function Lines.GroupFor(slot, key)
    local by = bound[slot]
    if by == nil then by = { f = frame, n = 0, g = {} } bound[slot] = by end
    if by.f ~= frame then by.f, by.n = frame, 0 end
    by.n = by.n + 1
    local sub = by.n
    local g = by.g[sub]
    if g == nil then
        g = TakeFree(key)
        if g == nil then
            local parent = CreateEntity()
            --[[Non-networked entity]]
            parent.entity:SetCanSleep(false)
            parent.persists = false
            parent.entity:AddTransform()
            parent:AddTag("CLASSIFIED")
            parent:AddTag("NOCLICK")
            parent:AddTag("FX")
            g = { parent = parent, pieces = {}, used = {} }
            Lines.groups_made = Lines.groups_made + 1
        end
        if g.sig ~= nil and g.sig == key and g.held ~= nil then
            -- (one let go that held this same shape: its pieces lie where they're wanted - shown
            -- again, as many as it held; what it was coloured kept (true_range/simmoves SameLaid
            -- changes only what differs) - not each laid anew: the worm's segments and the
            -- deerclops' spikes, taking these, were 2000 pieces laid a frame for nothing)
            for k, n in pairs(g.held) do
                g.used[k] = n
                local list = g.pieces[k]
                for i = 1, n do
                    local p = list[i]
                    if p._hidden ~= false then
                        p._hidden = false
                        ShowP(p)
                    end
                end
            end
            Lines.groups_revived = Lines.groups_revived + 1
            -- (its slots hidden still: its new owner told to show them again)
            g.revived = true
        else
            g.sig = nil
        end
        by.g[sub] = g
    end
    g.frame = frame
    return g
end
-- What `slot` had drawn last frame kept as it is (moved to x, z) - nothing about it changed but
-- where it is (true_range/simmoves: a thing's memo). false: it had none, or not all of it in
-- groups - then drawn anew
function Lines.GroupKeep(slot, x, z, deg)
    local by = bound[slot]
    if by == nil or by.f ~= frame - 1 then return false end
    for _, g in pairs(by.g) do
        if g.frame ~= frame - 1 then return false end
    end
    by.f = frame
    for _, g in pairs(by.g) do
        g.frame = frame
        Lines.GroupAt(g, x, z, deg)
    end
    return true
end
-- (deg: turned so - only if the game turns a group's pieces with it, Lines.turns)
function Lines.GroupAt(g, x, z, deg)
    -- (a group: a move's or a thing's shape - moved as all those are, Off)
    x, z = x + Lines.ox, z + Lines.oz
    if g.x ~= x or g.z ~= z then
        g.x, g.z = x, z
        g.parent.Transform:SetPosition(x, 0, z)
        Lines.groups_moved = Lines.groups_moved + 1
    end
    deg = Lines.turns and deg or 0
    if g.deg ~= deg then
        g.deg = deg
        g.parent.Transform:SetRotation(deg)
    end
end

-- Whether the game turns a group's pieces with it - their places round it and their own turning:
-- then one set of pieces serves a shape however it's turned (true_range/simmoves: worked out
-- unturned, the group turned) - the Crystal Deerclops' spikes, each its own way, were each laid
-- anew: 2000 pieces laid in one frame as a volley came up. Asked of the game itself, once: a piece
-- one unit out from its parent, the parent turned a quarter - where the game puts it, against
-- where it should be (x on by cos, z back by sin - true_range/simmoves World). Not known yet, or
-- not so: false, each shape laid as turned
Lines.turns = false
local turn_test = nil
function Lines.TurnTest()
    if turn_test == "done" then return end
    if turn_test == nil then
        local parent = CreateEntity()
        parent.entity:SetCanSleep(false)
        parent.persists = false
        parent.entity:AddTransform()
        parent:AddTag("CLASSIFIED")
        parent:AddTag("NOCLICK")
        parent:AddTag("FX")
        local child = CreateEntity()
        child.entity:SetCanSleep(false)
        child.persists = false
        child.entity:AddTransform()
        child:AddTag("CLASSIFIED")
        child:AddTag("NOCLICK")
        child:AddTag("FX")
        child.entity:SetParent(parent.entity)
        parent.Transform:SetPosition(10, 0, 20)
        parent.Transform:SetRotation(90)
        child.Transform:SetPosition(1, 0, 0)
        turn_test = { parent = parent, child = child, frames = 0 }
        return
    end
    -- (asked a frame on, and a few more - its place may be worked out as the game draws)
    turn_test.frames = turn_test.frames + 1
    local x, _, z = turn_test.child.Transform:GetWorldPosition()
    local want_x, want_z = 10 + math.cos(math.rad(90)), 20 - math.sin(math.rad(90))
    local ok = x ~= nil and math.abs(x - want_x) < .01 and math.abs(z - want_z) < .01
    if ok or turn_test.frames >= 5 then
        Lines.turns = ok
        -- (all drawn so far laid as turned: laid again - Lines.version)
        if ok then Lines.version = Lines.version + 1 end
        print(string.format("[true_range] groups turn with their parent: %s (a piece at %.2f, %.2f - %.2f, %.2f wanted)",
            ok and "yes" or "no", x or 0, z or 0, want_x, want_z))
        turn_test.child:Remove()
        turn_test.parent:Remove()
        turn_test = "done"
    end
end
-- (set: one of its three sets (f, e, s) - nil: all)
function Lines.GroupClear(g, set)
    Lines.group_builds = Lines.group_builds + 1
    if set == nil then
        for k in pairs(g.used) do g.used[k] = 0 end
    else
        for _, k in ipairs(SET_KEYS[set]) do g.used[k] = 0 end
    end
end
-- (r: a piece worked out round the group's middle - Lines.TriRecs, Lines.SegRec; set: which of
-- its sets - fills if not said)
function Lines.GroupTri(g, r, style, set)
    Place(GroupPiece(g, "tri", KEY.tri[set or "f"], style), r[1], r[2], r[3], r[4], r[5])
end
-- Slots: a group's pieces kept by place - the i-th of `key`, shown as r (Lines.SegRec) in style,
-- or hidden (r nil); each on its own, the rest untouched (a round thing's arcs, true_range/
-- simmoves: cut where the circle's whole 12 degrees are - its ends moved, only the slots at its
-- ends change). Hidden as the group's let go; shown again by its owner, not as it's taken again
local slot_rec = {}  -- (one record, written over - Lines.GroupSlotLine)
function Lines.GroupSlot(g, key, i, r, style)
    local s = g.slots
    if s == nil then s = {} g.slots = s end
    local list = s[key]
    if list == nil then list = {} s[key] = list end
    local p = list[i]
    if r == nil then
        if p ~= nil and p._hidden ~= true then
            p._hidden = true
            p:Hide()
        end
        return
    end
    if p == nil then
        local st = stock.square
        p = st[#st]
        if p ~= nil then
            st[#st] = nil
            Lines.stock_taken = Lines.stock_taken + 1
        else
            p = New("square")
            Lines.stock_short = Lines.stock_short + 1
        end
        p.entity:SetParent(g.parent.entity)
        list[i] = p
    end
    GroupStyle(p, style)
    if p._layer ~= layer then
        p._layer = layer
        p.AnimState:SetLayer(layer)
    end
    if p._hidden ~= false then
        p._hidden = false
        ShowP(p)
    end
    Place(p, r[1], r[2], r[3], r[4], r[5])
end
-- (the same, its line from (x1, z1) to (x2, z2), width w, not stretched - worked out here, no
-- record made: a worm's arcs changing every frame made hundreds of them a frame, garbage)
function Lines.GroupSlotLine(g, key, i, x1, z1, x2, z2, w, style)
    local mx, mz, deg, sx, sy = SegCalc(x1, z1, x2, z2, "edge", w, true)
    if mx == nil then
        Lines.GroupSlot(g, key, i, nil)
        return
    end
    slot_rec[1], slot_rec[2], slot_rec[3], slot_rec[4], slot_rec[5] = mx, mz, deg, sx, sy
    Lines.GroupSlot(g, key, i, slot_rec, style)
end
local function HideSlots(g)
    for _, list in pairs(g.slots or {}) do
        for _, p in pairs(list) do
            if p._hidden ~= true then
                p._hidden = true
                p:Hide()
            end
        end
    end
end
-- (a filled disc round the group's middle, radius r - its fills: one piece for a round thing's
-- whole inside, not tens of triangles - true_range/simmoves, round things drawn together)
function Lines.GroupDisc(g, r, style)
    local s = 2 * r / (DISC_PX / PX_PER_UNIT)
    Place(GroupPiece(g, "disc", KEY.disc.f, style), 0, 0, 0, s, s)
end
function Lines.GroupSeg(g, r, style, set)
    Place(GroupPiece(g, "square", KEY.square[set or "f"], style), r[1], r[2], r[3], r[4], r[5])
end
local function HideList(g, k)
    local list = g.pieces[k]
    if list == nil then return end
    for i = (g.used[k] or 0) + 1, #list do
        local p = list[i]
        if p._hidden ~= true then
            p._hidden = true
            p:Hide()
        end
    end
end
local function HideRest(g, set)
    if set == nil then
        for k in pairs(g.pieces) do HideList(g, k) end
    else
        for _, k in ipairs(SET_KEYS[set]) do HideList(g, k) end
    end
end
Lines.GroupDone = HideRest

function Lines.End()
    -- (groups not drawn this frame: let go)
    for slot, by in pairs(bound) do
        local any = false
        for sub, g in pairs(by.g) do
            if g.frame ~= frame then
                by.g[sub] = nil
                -- (how many of each it held, kept: taken again for the same shape, shown again as they
                -- lie - Lines.GroupFor)
                if g.held == nil then g.held = {} end
                for k, v in pairs(g.used) do g.held[k], g.used[k] = v, 0 end
                HideRest(g)
                HideSlots(g)
                PutFree(g)
            else
                any = true
            end
        end
        if not any then bound[slot] = nil end
    end
    TrimFree()
    if turn_test ~= "done" and CreateEntity ~= nil then Lines.TurnTest() end
    frame = frame + 1
    for anim, by_sort in pairs(pools) do
        for s, pool in pairs(by_sort) do
            -- (only as far up as any was shown - the heap thousands long, gone through every frame)
            local top = shown_top[anim]
            local u = used[anim][s] or 0
            for i = u + 1, math.min(top[s] or 0, #pool) do
                local p = pool[i]
                if p._hidden ~= true and p:IsValid() then
                    p._hidden = true
                    p:Hide()
                end
            end
            top[s] = u
        end
    end
    for i = shapes_used + 1, #shapes do
        if shapes[i]:IsValid() then shapes[i]:Hide() end
    end
end

-- (the styles, for the picture-making test)
Lines._styles = STYLES

return Lines
