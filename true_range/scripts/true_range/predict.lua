-- Player side: attack warnings for any monster, not just the bosses with hand-made shapes
-- (true_range/telegraph). What's known about its moves:
--   - preloaded: read from the game's and mods' code (true_range/moves_preload) - which
--     animation starts a move, and the frames its damage comes on
--   - learned by the server as the monster fights (true_range/learn): how far and how wide
--     its hits land (a fan, or a straight beam), how far a move carries it (a charge), and
--     which move usually follows which
-- When it starts a known move, its shape fills in towards the moment the damage comes; a
-- charge shows its path from where it set off to where it will stop; and a move that's
-- usually followed by a charge or a beam already shows that one, along where it faces.
-- (its log lines only with the mod's debugging on - TR_DEBUG, modmain: debug.txt in the mod's folder)
local print = function(...) if rawget(_G, "TR_DEBUG") then _G.print(...) end end

local Lines = require("true_range/lines")
local Learn = require("true_range/learn")
local SimMoves = require("true_range/simmoves")
local Legacy = require("true_range/legacy")
local Preload = require("true_range/moves_preload")
-- (REDESIGN.md's tables - the moves told that way: true_range/moves_table; none, if it isn't there)
local tab_ok, Tables = pcall(require, "true_range/moves_table")
if not tab_ok or type(Tables) ~= "table" then Tables = {} end

local Predict = {}

-- (testing, to be removed: what each part drawn this frame was drawn from - said in chat once the
-- game is paused (modmain), to tell just what's on the ground then. Kept as numbers and names,
-- put into words only then)
local notes, n_notes = {}, 0
local REPORT_FAR = 15   -- (things further off than this not said)
local function Note(ent, kind, move, t, v1, v2, v3, v4, v5, v6)
    n_notes = n_notes + 1
    local r = notes[n_notes]
    if r == nil then r = {} notes[n_notes] = r end
    r.ent, r.kind, r.move, r.t, r.v1, r.v2, r.v3, r.v4, r.v5, r.v6 = ent, kind, move, t, v1, v2, v3, v4, v5, v6
end
-- each a line: the boss (or thing), its move, the frame of it, what was drawn and how
function Predict.Report(px, pz)
    local out = {}
    for i = 1, n_notes do
        local r = notes[i]
        local ent, mv = r.ent, r.move
        local who = "?"
        local far = false
        if ent ~= nil and ent:IsValid() then
            local x, _, z = ent.Transform:GetWorldPosition()
            local d = px ~= nil and math.sqrt((x - px) ^ 2 + (z - pz) ^ 2) or 0
            who = string.format("%s (%.1f off)", ent.prefab or "?", d)
            -- (a thing well off you - spikes left standing 20 away: not said, the chat filled with them)
            far = mv == nil and d > REPORT_FAR
        end
        -- (which of its move's animations it plays now, and how far in)
        local anim = ""
        if mv ~= nil and ent ~= nil and ent:IsValid() and ent.AnimState ~= nil then
            for _, an in ipairs(mv.anims or {}) do
                if ent.AnimState:IsCurrentAnimation(an) then
                    anim = string.format(" anim %s @%d", an, math.floor(ent.AnimState:GetCurrentAnimationTime() / FRAMES + .5))
                    break
                end
            end
        end
        local name = mv ~= nil and (mv.name or (mv.anims ~= nil and mv.anims[1]) or "?") or "-"
        local frame = r.t ~= nil and string.format(" frame %d", math.floor(r.t / FRAMES + .5)) or ""
        local how = ""
        if r.kind == "table" then
            how = string.format("table: aim at frame %d (%s), row %d (shape of row %d), goes with %s%s", r.v1, r.v2 and "set" or "still following",
                r.v3, r.v4, tostring(r.v5), r.v6 and ", junk thrown - going after you only so far" or "")
        elseif r.kind == "old" then
            how = string.format("offline map: stops aiming at frame %s (%s)", tostring(r.v1), r.v2 and "set" or "still following")
            -- (and what it was drawn from: boss given at, drawn at, facing, distance, run used, parts)
            local lg = r.v3
            if lg ~= nil and lg.r_x ~= nil then
                how = how .. string.format(" | given %.2f,%.2f drawn %.2f,%.2f rot %.1f dist %.2f run %.2f parts %d",
                    lg.r_in_x, lg.r_in_z, lg.r_x, lg.r_z, lg.r_rot / DEGREES, lg.r_dist, lg.r_best, lg.r_parts)
            end
        elseif r.kind == "after" then
            how = "its move over, drawn on to its last strike"
        elseif r.kind == "branch" then
            how = string.format("where standing makes it go on - looks at frame %d", r.v1)
        elseif r.kind == "hazard" then
            how = string.format("thing set off, %.2fs old%s", r.v1 or 0, r.v2 and " (its move drawn: not on its own)" or "")
        else
            how = r.kind
        end
        if not far then out[#out + 1] = string.format("%s %s%s%s - %s", who, name, frame, anim, how) end
    end
    return out
end

-- from the server: prefab -> anim -> { radius, half, frames, travel, width, next } (learn.lua)
Predict.learned = {}

local LINGER = .2              -- a move stays "on" this long after its last damage frame
local FINISH_BEHIND = .5       -- how far behind how its legs end goes before that's drawn back
local ARC_STEP = 8 * DEGREES
local MIN_TRAVEL = 1.5         -- a move carrying it less than this isn't drawn as a charge

local function Arc(cx, cz, r, a1, a2, style)
    local n = math.max(2, math.ceil((a2 - a1) / ARC_STEP))
    local px, pz = cx + r * math.cos(a1), cz - r * math.sin(a1)
    for i = 1, n do
        local a = a1 + (a2 - a1) * i / n
        local x, z = cx + r * math.cos(a), cz - r * math.sin(a)
        Lines.Segment(px, pz, x, z, style)
        px, pz = x, z
    end
end

local function FilledFan(cx, cz, rot, r, half, style)
    if r <= 0 then
        return
    end
    if half >= 180 then
        Lines.Disc(cx, cz, r, style)
        return
    end
    local h = half * DEGREES
    local n = math.max(1, math.ceil(2 * h / (10 * DEGREES)))
    for i = 0, n - 1 do
        Lines.Wedge(cx, cz, r, rot - h + 2 * h * i / n, rot - h + 2 * h * (i + 1) / n, style)
    end
end

local function FanOutline(cx, cz, rot, r, half, style)
    if half >= 180 then
        Arc(cx, cz, r, 0, 2 * math.pi, style)
        return
    end
    local h = half * DEGREES
    Arc(cx, cz, r, rot - h, rot + h, style)
    Lines.Segment(cx, cz, cx + r * math.cos(rot - h), cz - r * math.sin(rot - h), style)
    Lines.Segment(cx, cz, cx + r * math.cos(rot + h), cz - r * math.sin(rot + h), style)
end

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

-- A strip from (x, z) `length` ahead along `rot`, `hw` to each side, round at both ends (a
-- charge's path - its end circle is where it stops - or a beam). fill / edge: styles.
local function Strip(x, z, rot, length, hw, fill, edge)
    local c, s = math.cos(rot), math.sin(rot)
    local bx, bz = x + length * c, z - length * s
    local px, pz = -s * hw, -c * hw -- (sideways)
    if fill ~= nil then
        -- (the band, and a half disc beyond each end - not over the band: no darker overlap)
        Lines.Segment(x, z, bx, bz, fill, 2 * hw)
        FilledFan(bx, bz, rot, hw, 90, fill)
        FilledFan(x, z, rot + math.pi, hw, 90, fill)
    end
    Lines.Segment(x + px, z + pz, bx + px, bz + pz, edge)
    Lines.Segment(x - px, z - pz, bx - px, bz - pz, edge)
    Arc(bx, bz, hw, rot - math.pi / 2, rot + math.pi / 2, edge)
    Arc(x, z, hw, rot + math.pi / 2, rot + math.pi * 1.5, edge)
end

local function InStrip(px, pz, x, z, rot, length, hw)
    local c, s = math.cos(rot), math.sin(rot)
    local dx, dz = px - x, pz - z
    local along = math.max(0, math.min(length, dx * c - dz * s))
    local ax, az = x + along * c, z - along * s
    return (px - ax) ^ 2 + (pz - az) ^ 2 <= hw * hw
end

local function Playing(ent, anims)
    for _, a in ipairs(anims) do
        if ent.AnimState:IsCurrentAnimation(a) then
            return true
        end
    end
    return false
end

-- the charge or beam that usually (at least half the time) comes after move m, if any
local NEXT_SHARE = .5

local TURN = 5 * DEGREES -- turned more than this since the move began: it's taking aim

local function LeadsTo(learned_all, anim, share)
    local nxt = anim ~= nil and learned_all[anim] or nil
    if nxt ~= nil and (share or 1) >= NEXT_SHARE and (nxt.travel >= MIN_TRAVEL or nxt.width > 0) then
        return nxt
    end
    return nil
end

-- turned: whether it turned since the move began (nil: either way - any of them). What
-- follows when it turned / held still is told apart once seen enough; until then, all told.
local function Leads(learned_all, m, turned)
    if m == nil then
        return nil
    end
    if turned == nil then
        return LeadsTo(learned_all, m.next, m.next_share) or LeadsTo(learned_all, m.next_turned, m.turned_share)
            or LeadsTo(learned_all, m.next_still, m.still_share)
    end
    if turned and m.next_turned ~= nil then
        return LeadsTo(learned_all, m.next_turned, m.turned_share)
    end
    if not turned and m.next_still ~= nil then
        return LeadsTo(learned_all, m.next_still, m.still_share)
    end
    return LeadsTo(learned_all, m.next, m.next_share)
end

-- its moves: the preloaded ones, plus moves only the server has seen (a charge, a beam, the
-- frames of a mod monster's attack)
local merged = {}

local function MovesOf(prefab)
    -- (run offline from the game's own code: that, and nothing guessed)
    if SimMoves.Has(prefab) then
        return SimMoves.Moves(prefab)
    end
    -- (the old ways: off for now - true_range/legacy)
    if not Legacy.on then
        return nil
    end
    local pre = Preload[prefab]
    local learned = Predict.learned[prefab]
    if learned == nil then
        return pre
    end
    local cached = merged[prefab]
    if cached ~= nil and cached.from == learned then
        return cached
    end
    cached = { from = learned }
    local covered = {}
    for _, move in ipairs(pre or {}) do
        table.insert(cached, move)
        covered[move.anims[1]] = true
    end
    for anim, m in pairs(learned) do
        local leads = Leads(learned, m) ~= nil
        local idle = string.find(string.lower(anim), "idle", 1, true) ~= nil or m.shared
        if not covered[anim] and not idle and (#m.frames > 0 or m.travel >= MIN_TRAVEL or m.width > 0 or leads) then
            table.insert(cached, { anims = { anim }, frames = m.frames })
        end
    end
    merged[prefab] = cached
    return cached
end

-- the move a monster is in: { move, t0, x, z, rot } - when its first animation began, and
-- where it stood and faced then (a charge's path starts there)
local active = setmetatable({}, { __mode = "k" })
-- (where it was going, each frame it's in no move of its own - SimMoves._keeps_heading)
local walk_heading = setmetatable({}, { __mode = "k" })
-- (a thing a move's state makes as it begins, told by its sim.tell - Uncompromising Mode's shot, its
-- eyeofterror_chargepulse at the boss on entering it, the charge none: thing -> when it was made
-- (modmain, its AddPrefabPostInit); where it is read when it's looked at, put there after it's made)
Predict.tell_things = setmetatable({}, { __mode = "k" })
-- (each tell thing ever seen made - its absence a word only once its kind has been seen at all: a game (or a replay)
-- not told of them would take every shot for the charge)
Predict.tell_seen = {}
-- (each boss's last go of a move, and when it ended: ent -> { name, t } - one begun again straight after itself (sim.from_self))
Predict.last_go = setmetatable({}, { __mode = "k" })
-- (whom each was after last, and when - kept this many seconds: Predict.Draw)
local last_target, TARGET_KEEP = setmetatable({}, { __mode = "k" }), 3
-- (each one's moves' animations seen, anim -> when: Track)
local anims_seen = setmetatable({}, { __mode = "k" })

-- (testing: the move a monster is in now, as tracked - nil: none)
function Predict.MoveOf(ent)
    local a = active[ent]
    return a ~= nil and a.move.name or nil
end
-- (...and when it began, as tracked)
function Predict.MoveStart(ent)
    local a = active[ent]
    -- (as it began - not its clock as moved since (a later animation's start, held short of one: t0_first))
    return a ~= nil and (a.t0_first or a.t0) or nil
end

local function IsCharge(learned_all, move)
    local m = learned_all ~= nil and learned_all[move.anims[1]] or nil
    return m ~= nil and m.travel >= MIN_TRAVEL and not m.leap
end

local ANIM_LEAD = 1 / 30
-- (a charge run by its brain (the game's behaviours/chaseandram.lua): its target over 60 degrees
-- off its way and 10 or more from it - it stops; the Ancient Guardian's give-up distance)
local RAM_TURN, RAM_GIVE_UP = 60, 10
-- (a body that charges, running with no charge under way (SimMoves.PoseNoRam): how far ahead of it
-- it's drawn ramming - testing: TR_RAM_FLEE)
local RAM_FLEE = tonumber(os ~= nil and os.getenv ~= nil and os.getenv("TR_RAM_FLEE") or "") or 4
local RAM_FLEE_FWD = tonumber(os ~= nil and os.getenv ~= nil and os.getenv("TR_RAM_FLEE_FWD") or "") or 1
-- (how far along its line (from lx, lz, cos c, sin s) its charge goes before its brain gives it up,
-- as the server told: the time it has left run at its speed from when it sets off (its lock), the
-- way it has left - from where the server had it then; RAM_LATE: its brain looks only every .125 s,
-- so as much as that on. nil: not told)
local RAM_LATE = .1
-- (a shot's way drawn on this long past its time at most)
local LINGER_SHOT = 3 * FRAMES
local function RamEnd(ent, sim, lx, lz, c, s)
    local r = SimMoves.PoseRam(ent)
    if r == nil then return nil end
    local left = math.huge
    if r[1] >= 0 then left = (sim.speed or 6) * math.max(0, r[1] + RAM_LATE - math.max(0, (sim.lock or 0) * FRAMES - r[3])) end
    if r[2] >= 0 then left = math.min(left, r[2] + (sim.speed or 6) * RAM_LATE) end
    if left == math.huge then return nil end
    return (r[4] - lx) * c - (r[5] - lz) * s + left
end
-- (a spin round itself: turned to you only while you're this far off; where it is followed by this
-- much of the way a frame, while it shakes about by under a unit)
local AROUND_TURN_FROM, AROUND_EASE = 2, .35
local AROUND_AHEAD, AROUND_AHEAD_HOLD, AROUND_AHEAD_DECAY = .5, .6, 3  -- (seconds on: how far ahead a chaser spinning round itself is drawn coming; held within this)
local AROUND_AHEAD_GROW = 1.4
local RETURN_TURN = 10 * DEGREES -- a charge facing another way now: a new leg (rolls, one after another)
local AHEAD_LEG = 30 * DEGREES -- or facing its target already between legs: the next leg may come straight on

local function Turned(a, b)
    return math.abs(((a - b) + math.pi) % (2 * math.pi) - math.pi)
end

-- (a move's last strike, in frames from its start - any distance; cached)
local last_strike = setmetatable({}, { __mode = "k" })
-- (first_go: its first go's alone - not again_until, a go over again the run took at some
-- distance only, by chance: the shark's bite begun over (animover, 30%) - at 2 off the run never
-- did, so the second bite there, waited for till 94, wasn't drawn at all)
local function LastStrike(sim, first_go)
    local c = last_strike[sim]
    if c == nil then
        local v, f = 0, 0
        for _, m in ipairs(sim.maps or {}) do
            for _, s in ipairs(m.steps or {}) do
                v = math.max(v, s.again_until or s.at or 0)
                f = math.max(f, s.at or 0)
            end
        end
        -- (and its first strike, steps or none - a move that only shoots (maps {}, sim.shoots) struck at nothing so: Uncompromising
        -- Mode's bee shooter, its shoot_pre looping every .2 s till it shoots at 1 s, taken for a new go each loop and its lane
        -- never drawn, lag 0748. The others' first is never past their last step. TR_OLD_LASTFIRST: as before)
        if not rawget(_G, "TR_OLD_LASTFIRST") then
            v, f = math.max(v, sim.first or 0), math.max(f, sim.first or 0)
        end
        c = { v, f }
        last_strike[sim] = c
    end
    return first_go and c[2] or c[1]
end
local goes_again = setmetatable({}, { __mode = "k" })
local function GoesAgain(sim)
    local v = goes_again[sim]
    if v == nil then
        v = false
        for _, m in ipairs(sim.maps or {}) do
            for _, s in ipairs(type(m.steps) == "table" and m.steps or {}) do
                if s.again_anim ~= nil then v = true end
            end
        end
        goes_again[sim] = v
    end
    return v
end
-- (a move cut short before its last strike - its boss killed, knocked out of it: until then,
-- what it set off that's drawn with it is drawn on its own - a laser burning on)
local cut_until = -math.huge
-- (a move whose animation ended before its last strike, its boss on to something else: ent -> it)
local after = setmetatable({}, { __mode = "k" })
-- (the two, gone through for every thing on the ground every frame - one list, not one made each time)
local ACTIVE_AFTER = { active, after }
-- (each boss's last move, and when it ended: a thing drawn with its move not on its own straight
-- after - a ground pound's ring playing on as the pound is over, striking nothing - MOVE_GRACE)
local move_ended = setmetatable({}, { __mode = "k" })
local MOVE_GRACE = 1

-- (a boss run offline, the server not heard from about it yet: harmful, nothing else known)
local NO_WORD = { harmful = true, hit = 3, attack = 3, area = 0, radius = 0 }

-- (how far round one turns to you, the most of its moves - sim.cone; ent -> where you stepped out)
local cone_of = setmetatable({}, { __mode = "k" })
local cones = setmetatable({}, { __mode = "k" })
-- (and how far ahead of you it aims, as it lets you go: sim.lead)
local function ConeOf(moves)
    local c = cone_of[moves]
    if c == nil then
        c = { false, 0 }
        for _, m in ipairs(moves) do
            if m.sim ~= nil and m.sim.cone ~= nil then
                c[1] = math.max(c[1] or 0, m.sim.cone)
                c[2] = math.max(c[2], m.sim.lead or 0)
            end
        end
        cone_of[moves] = c
    end
    return c[1] or nil, c[2]
end

-- whether two moves run offline strike alike - the same cells, at the same frames, at every
-- distance (their maps' packed steps, compared once)
local same_shape = setmetatable({}, { __mode = "k" })
local function ShapeKey(sim)
    local parts = { tostring(sim.first), tostring(sim.lock), tostring(sim.frame), tostring(sim.anchor), tostring(sim.still), tostring(sim.single), tostring(sim.free ~= nil), tostring(sim.leg ~= nil), tostring(sim.around ~= nil) }
    for _, m in ipairs(sim.maps or {}) do
        parts[#parts + 1] = tostring(m.dist)
        for _, s in ipairs(type(m.steps) == "table" and m.steps or {}) do parts[#parts + 1] = tostring(s.at) .. ":" .. tostring(s.cells) end
    end
    return table.concat(parts, "|")
end
local function SameShape(a, b)
    same_shape[a] = same_shape[a] or ShapeKey(a)
    same_shape[b] = same_shape[b] or ShapeKey(b)
    return same_shape[a] == same_shape[b]
end
-- whether two moves strike the same cells, step for step, at every distance both were run at -
-- only a few frames apart, at most (how many: the second value). The Ancient Guardian's gore out of
-- its charge at frame 1 or, stopping, at 5; the Malbatross's dive with its splash or not
local same_foot = setmetatable({}, { __mode = "k" })
local function SameFoot(a, b)
    local key = same_foot[a]
    if key == nil then key = {} same_foot[a] = key end
    if key[b] ~= nil then return key[b][1], key[b][2] end
    local function Per(sim)
        local t, last = {}, nil
        for _, m in ipairs(sim.maps or {}) do
            local st = (type(m.steps) == "table" and #m.steps > 0) and m.steps or (m.same and last) or nil
            if st ~= nil then last = st t[m.dist] = st end
        end
        return t
    end
    local pa, pb = Per(a), Per(b)
    local common, shift, ok = 0, 0, true
    for d, sa in pairs(pa) do
        local sb = pb[d]
        if sb ~= nil and ok then
            if #sa ~= #sb then ok = false else
                for i = 1, #sa do
                    if sa[i].cells ~= sb[i].cells then ok = false break end
                    shift = math.max(shift, math.abs((sa[i].at or 0) - (sb[i].at or 0)))
                end
            end
            common = common + 1
        end
    end
    ok = ok and common > 0
    key[b] = { ok, shift }
    return ok, shift
end
-- (the frame a move that goes somewhere first gets .3 from where it began - its path run offline (free / maps, a
-- distance a frame), or sim.moves_at; nil if not known)
function Predict.SetsOffAt(s)
    if s == nil then return nil end
    if s._sets_off == nil then
        s._sets_off = false
        if s.moves_at ~= nil then s._sets_off = s.moves_at end
        local list = s.free or s.maps
        local p = list ~= nil and list[1] ~= nil and list[1].path or nil
        if s._sets_off == false and type(p) == "string" then
            local i = 0
            for v in p:gmatch("[^,]+") do
                if (tonumber(v) or 0) > .3 then s._sets_off = i break end
                i = i + 1
            end
        end
    end
    return s._sets_off or nil
end
-- (two begun alike told apart at once by where it came from or where it stands - see Track: m1, m2 the two; returns
-- the one it is and why, or nil. TR_OLD_FROMTELL: none)
function Predict.PickAlike(ent, a, m1, m2, seen)
    if rawget(_G, "TR_OLD_FROMTELL") or m1 == nil or m2 == nil then return nil end
    local function Says(m)
        local s = m.sim
        if s == nil then return nil end
        if s.from_self then
            local lg = Predict.last_go[ent]
            -- (as many times over as its code goes again (sim.from_self: how many), within 12 frames - a trace's
            -- gap of 10 frames left the third howl taken for a bite)
            -- (and nothing else played between - its code goes again on its animation's end, straight in: the glacial
            -- hound's bite 0.2 s after its third howl, idle and a run's start between, taken for a fourth - drawn as a
            -- howl's lane, its bite struck undrawn. TR_OLD_SELFGAP: as before)
            -- (anims_seen._other: when it last played none of its moves' animations)
            local between = false
            if lg ~= nil and not rawget(_G, "TR_OLD_SELFGAP") then
                local o = anims_seen[ent] ~= nil and anims_seen[ent]._other or nil
                -- (its last such frame the very one it's seen beginning in - begun from the animation's own clock)
                between = o ~= nil and o > lg.t + .001 and o <= a.t0 + FRAMES / 2
            end
            if lg ~= nil and not between and lg.name == m.name and a.t0 - lg.t <= 12 * FRAMES and (lg.chain or 0) < (tonumber(s.from_self) or 99) then return true, "itself" end
        end
        if s.from ~= nil then
            local hit = false
            for _, an in ipairs(s.from) do
                local w = math.max(seen[an] or -math.huge, seen["^" .. an] or -math.huge)
                -- (seen up to a frame and a half in: its own animation's clock puts its start a frame before the frame it's seen
                -- in - the Glacial Hound's scared_pst last seen 1.01 frames after its howl's start, the howl taken for a bite, its
                -- three spike lines undrawn, 2026-10-29. TR_OLD_FROMEDGE: a frame)
                local edge = rawget(_G, "TR_OLD_FROMEDGE") and FRAMES or 1.5 * FRAMES
                if w >= a.t0 - 4 * FRAMES and w <= a.t0 + edge then hit = true end
            end
            if hit then return true, "from" end
            -- (not come from there - known only once it was seen doing something before)
            if seen._other ~= nil or Predict.last_go[ent] ~= nil then return false, "not from" end
        end
        -- (taken by its code only with its target this far off or more (sim.far) - nearer, not this one:
        -- Tropical Experience's slip leaps only from past 3, begun just as its bite; drawn over it, each
        -- bite. TR_OLD_FAR: as before)
        if s.far ~= nil and not rawget(_G, "TR_OLD_FAR") then
            local combat = ent.replica ~= nil and ent.replica.combat or nil
            local tgt = combat ~= nil and combat:GetTarget() or nil
            if tgt ~= nil and tgt.Transform ~= nil then
                local x, _, z = ent.Transform:GetWorldPosition()
                local tx, _, tz = tgt.Transform:GetWorldPosition()
                if (tx - x) ^ 2 + (tz - z) ^ 2 < s.far * s.far then return false, "near" end
            end
        end
        -- (and only with it this near or nearer (sim.near) - the ice hound's bite, past 3 off its quickattack's spike line
        -- instead (UM SGhound doattack): the bite drawn for the spike line, 11 struck undrawn, 2026-10-29. TR_OLD_NEAR: as before)
        if s.near ~= nil and not rawget(_G, "TR_OLD_NEAR") then
            local combat = ent.replica ~= nil and ent.replica.combat or nil
            local tgt = combat ~= nil and combat:GetTarget() or nil
            if tgt ~= nil and tgt.Transform ~= nil then
                local x, _, z = ent.Transform:GetWorldPosition()
                local tx, _, tz = tgt.Transform:GetWorldPosition()
                if (tx - x) ^ 2 + (tz - z) ^ 2 > s.near * s.near then return false, "far" end
            end
        end
        if s.on ~= nil then
            local W = rawget(_G, "TheWorld")
            local map = W ~= nil and W.Map or nil
            if map ~= nil then
                local x, _, z = ent.Transform:GetWorldPosition()
                local ground
                local ok, g = false, nil
                if map.IsVisualGroundAtPoint ~= nil then ok, g = pcall(map.IsVisualGroundAtPoint, map, x, 0, z)
                elseif map.IsPassableAtPoint ~= nil then ok, g = pcall(map.IsPassableAtPoint, map, x, 0, z) end
                if ok then ground = g end
                if ent.GetCurrentPlatform ~= nil and ent:GetCurrentPlatform() ~= nil then ground = true end
                if ground ~= nil then return (s.on == "ground") == ground, "on " .. (ground and "ground" or "water") end
            end
        end
        return nil
    end
    local yes_m, why_m = Says(m1)
    local yes_a, why_a = Says(m2)
    if yes_a == true and yes_m ~= true then return m2, why_a
    elseif yes_m == true and yes_a ~= true then return m1, why_m
    elseif yes_a == false and yes_m ~= false then return m1, why_a
    elseif yes_m == false and yes_a ~= false then return m2, why_m end
    return nil
end
local function Track(ent, moves, now, learned_all)
    -- (which of its moves' animations it has been seen playing, and when - two forms of one move
    -- begun alike, told apart by what only one of them plays: the Twins' charge as an eye or, once
    -- transformed, as a mouth)
    local seen = anims_seen[ent]
    if seen == nil then seen = {} anims_seen[ent] = seen end
    -- (and when last it played none of them - doing something else: seen._other)
    local in_any = false
    for _, m in ipairs(moves) do
        for i = 1, #m.anims do
            if ent.AnimState:IsCurrentAnimation(m.anims[i]) then
                in_any = true
                if i >= 2 then seen[m.anims[i]] = now else seen["^" .. m.anims[i]] = now end
            end
        end
        -- (and the animation of its turning into a later form, once seen: sim.after_anim)
        local aa = m.sim ~= nil and m.sim.after_anim or nil
        if aa ~= nil and ent.AnimState:IsCurrentAnimation(aa) then seen[aa] = now end
    end
    if not in_any then seen._other = now end
    local a = active[ent]
    -- (its first animation played well slower than it ran offline: not that move - Uncompromising
    -- Mode's Fire Hound's quick breath and Ice Hound's quick spike play the bite's atk_pre at .3 its
    -- speed and never bite (postinit/stategraphs/SGhound.lua quickbreath, quickspike), their fire
    -- and spikes drawn on their own: 202 / 201 drawn in with no strike. A state's timeline goes by
    -- the clock, not its animation, so a slowed one is another state, not the move at another pace.
    -- Not taken up again till that animation is over or begun again - its time gone back, the idle
    -- between not seen (an Ice Hound's bite straight after its spike, one frame of idle): seen._slow)
    if seen._slow ~= nil then
        local at = ent.AnimState:GetCurrentAnimationTime()
        if not ent.AnimState:IsCurrentAnimation(seen._slow) or at < seen._slow_at - .02 then
            seen._slow = nil
        else
            seen._slow_at = at
        end
    end
    -- (only one whose run went on from that animation to another, its strikes not kept to it -
    -- not Wigfrid's twirl (Uncompromising Mode's shadow Wigfrid, lunge_pre at .3 and striking, again
    -- and again with it: GoesAgain) - 17 -> 336 missed when it was dropped too)
    -- (nor one whose own code holds its animation (sim.held - Uncompromising Mode's shadow Wilson crouched still before it
    -- leaps): dropped as played slow, all 54 of its blows went undrawn, 2026-10-21)
    if a ~= nil and a.anim0 ~= nil and a.move.sim ~= nil and #a.move.anims > 1 and not GoesAgain(a.move.sim)
        and not a.move.sim.held and ent.AnimState:IsCurrentAnimation(a.move.anims[1]) then
        -- (its first animation begun over - its time gone back: a new go of it, not one played slow -
        -- the Pengull's slide_bounce played again as it strikes off its slide, 4-6 frames after it last
        -- began: taken for slowed, its slide dropped the frame it struck, 2 of 294 missed. TR_OLD_SLOW: as before)
        local at_now = ent.AnimState:GetCurrentAnimationTime()
        if a.anim_prev ~= nil and at_now < a.anim_prev - .02 and not rawget(_G, "TR_OLD_SLOW") then a.anim0, a.real0 = at_now, now end
        a.anim_prev = at_now
        local wall = now - a.real0
        if wall >= 2 * FRAMES - .001 and wall <= 10 * FRAMES then
            local ran = ent.AnimState:GetCurrentAnimationTime() - a.anim0
            if ran >= 0 and ran < .5 * wall then
                seen._slow, seen._slow_at = a.move.anims[1], ent.AnimState:GetCurrentAnimationTime()
                active[ent] = nil
                a = nil
            end
        end
    end
    -- (which form it's in now - the server's word, true_range/simmoves after_seen: over what's been
    -- seen here - turned before you came (the Eye of Terror already a mouth as you joined, its
    -- charges drawn as an eye's), or turned back (healed past its turning point, an eye again, its
    -- one charge drawn as a mouth's with more to come - through its taunt); the form being drawn
    -- swapped for the right one, from the same start)
    local told = SimMoves.after_seen[ent]
    if told ~= nil then
        for _, m in ipairs(moves) do
            local aa = m.sim ~= nil and m.sim.after_anim or nil
            if aa ~= nil then
                if told[aa] then seen[aa] = seen[aa] or now else seen[aa] = nil end
            end
        end
        if a ~= nil and a.move.sim ~= nil then
            local want_aa = nil
            for _, m in ipairs(moves) do
                local aa = m.sim ~= nil and m.sim.after_anim or nil
                if aa ~= nil and m.anims[1] == a.move.anims[1] and told[aa] then want_aa = aa end
            end
            if a.move.sim.after_anim ~= want_aa then
                for _, m in ipairs(moves) do
                    if m ~= a.move and m.anims[1] == a.move.anims[1] and m.sim ~= nil and m.sim.after_anim == want_aa then
                        a.move, a.locked, a.hist, a.log, a.alt = m, nil, nil, nil, nil
                        break
                    end
                end
            end
        end
    end
    if a ~= nil and not Playing(ent, a.move.anims) then
        -- (taken for one form, it's playing the other's: that one, from the same start - only a form
        -- it is in, if the server has said (told): the Eye of Terror as an eye taunting after its
        -- charge, a taunt its mouth form's offline run happened to end in - taken for a mouth, with
        -- more charges to come, drawn through its taunt)
        for _, m in ipairs(moves) do
            local form_ok = told == nil or (m.sim ~= nil and (m.sim.after_anim == nil or told[m.sim.after_anim]))
            -- (nor by its last animation alone - what it winds down into, as its offline run happened
            -- to: the Eye's mouth form ran into a taunt, a roll of the dice after any charge)
            local tells = false
            for i = 1, #m.anims - 1 do
                if ent.AnimState:IsCurrentAnimation(m.anims[i]) then tells = true end
            end
            if m ~= a.move and m.anims[1] == a.move.anims[1] and form_ok and tells then
                a.move, a.locked, a.hist, a.log, a.alt = m, nil, nil, nil, nil
                break
            end
        end
    end
    -- (or back into one of its earlier animations - going again, charge after charge: only the
    -- form whose run goes in legs again and again does that - the Eye of Terror as a mouth, its
    -- turning into one not seen (you came after): that one, and that form from now on)
    if a ~= nil and (a.move.sim == nil or a.move.sim.leg == nil) then
        local at = nil
        for i, an in ipairs(a.move.anims) do
            if ent.AnimState:IsCurrentAnimation(an) then at = i break end
        end
        if at ~= nil and a.anim_i ~= nil and at < a.anim_i and at > 1 then
            for _, m in ipairs(moves) do
                if m ~= a.move and m.anims[1] == a.move.anims[1] and m.sim ~= nil and m.sim.leg ~= nil
                    and (m.sim.leg.count or 1) > 1 then
                    a.move, a.locked, a.hist, a.log, a.alt = m, nil, nil, nil, nil
                    a.leg_t, a.legs_begun, a.legs_done = nil, true, 1
                    if m.sim.after_anim ~= nil then seen[m.sim.after_anim] = now end
                    break
                end
            end
        end
        a.anim_i = math.max(a.anim_i or 0, at or 0)
    end
    if a ~= nil then
        -- (a charge's animation often loops: it stays the same charge, from the same start,
        -- for as long as it plays)
        local frames = a.move.frames
        local charge = IsCharge(learned_all, a.move) or (a.move.sim ~= nil and a.move.sim.leg ~= nil)
        local last = (#frames == 0 or charge) and math.huge or frames[#frames] * FRAMES + LINGER
        -- (on into the first animation of another of its moves - Armored Bearger's swipe, then the
        -- next of its combo: that one, from its own start - not the end of this one, drawn as over)
        local into = false
        for _, m in ipairs(moves) do
            if m ~= a.move and m.anims[1] ~= a.move.anims[1] and ent.AnimState:IsCurrentAnimation(m.anims[1])
                -- (not one that waited its way there (sim.waits) and goes on into it itself - the bomber bee's dive on into
                -- stab_death, where it strikes: its ring gone 1-2 frames before the blow while the other move was taken up, 5 of
                -- 16 on lag 0853. TR_OLD_SIMWAITS: into it)
                and not (a.move.sim ~= nil and a.move.sim.waits ~= nil and not rawget(_G, "TR_OLD_SIMWAITS") and Playing(ent, a.move.anims)) then
                into = true
                break
            end
        end
        -- (or its own first animation begun over once all of it has struck - the Celestial
        -- Champion's summoning chop again straight after: a new go, from its own start - not the
        -- old one, over, drawn as nothing)
        local first_at = ent.AnimState:IsCurrentAnimation(a.move.anims[1]) and ent.AnimState:GetCurrentAnimationTime() or nil
        if first_at ~= nil and a.first_at ~= nil and first_at < a.first_at - .05 and a.move.sim ~= nil
            and now - a.t0 > LastStrike(a.move.sim, true) * FRAMES + LINGER then
            into = true
        end
        -- (or, one of a single animation, begun over once its first blow is past - the Blighted Rock Master's dashes one
        -- after another (SGrocky dash_attack into itself at 36, its run's blows taken on to there): the next taken for this
        -- one still on, none of it drawn, 48 of 292 undrawn; 2026-10-23 update. Not one going again in itself, nor a charge.
        -- TR_OLD_RESTART: as before)
        if first_at ~= nil and a.first_at ~= nil and first_at < a.first_at - .05 and a.move.sim ~= nil and #a.move.anims == 1
            and not charge and not GoesAgain(a.move.sim) and not rawget(_G, "TR_OLD_RESTART")
            and now - a.t0 > (a.move.sim.first or 0) * FRAMES + LINGER then
            into = true
        end
        -- (or begun over before it ever went on to its next animation - one struck by its own body
        -- (no sim.puts) whose run went on from it: a new go, the old one left. A Glacial Hound's ice
        -- howl plays the bite's atk_pre three times and never its atk - the first go's bite was drawn
        -- on and struck at its frame in the second: 17 drawn in, no strike)
        if first_at ~= nil and a.first_at ~= nil and first_at < a.first_at - .05 and a.move.sim ~= nil
            and a.move.sim.puts == nil and a.move.sim.still and #a.move.anims > 1 and a.move.anims[2] ~= a.move.anims[1] and (a.anim_i or 1) <= 1 then
            -- (not one that goes again by playing its first again - Wigfrid's twirl: still it)
            if not GoesAgain(a.move.sim) then into = true end
        end
        -- (or back to it after its later animations - Uncompromising Mode's Moose hopping at you
        -- twice, landing in between: the second hop wasn't drawn at all, the first taken as still on;
        -- the Wilting Dragonfly dashing again and again, each drawn where the first went. Not one whose
        -- list has its first again further on - that's still it)
        -- (once it has struck at least once - not a Mini Eye's bite begun over before it struck: 19
        -- drawn with no strike)
        -- (not one going in legs - its legs again and again are its own: below)
        -- (struck, not struck and lingered on: having played its later animations already, its first again
        -- is a new go - the Ancient Guardian's quick leap lands at 44 and leaps again at 45, twice: the
        -- second taken as the first still on, never aimed or drawn anew - the player's report 2026-10-19.
        -- TR_OLD_AGAINLINGER: as before)
        if first_at ~= nil and a.first_at == nil and (a.anim_i or 0) > 1 and a.move.sim ~= nil and a.move.sim.leg == nil
            and now - a.t0 > (a.move.sim.first or 0) * FRAMES + (rawget(_G, "TR_OLD_AGAINLINGER") and LINGER or 0) then
            local again = false
            for i = 2, #a.move.anims do if a.move.anims[i] == a.move.anims[1] then again = true end end
            if not again then into = true end
        end
        a.first_at = first_at
        -- (a later animation of it seen to begin: its clock set by when that began in the run offline (sim.anim_at) - one held
        -- round as long as its own code says (the Umbral Abomination underground, 2.9 s in the game, 1.2 offline): drawn ended
        -- before it struck as it came up, 7 of 478. Once each, by over 2 frames. 2026-10-26. TR_OLD_ANIMSYNC: as before)
        if a.move.sim ~= nil and a.move.sim.anim_at ~= nil and not rawget(_G, "TR_OLD_ANIMSYNC") then
            for an, f in pairs(a.move.sim.anim_at) do
                if ent.AnimState:IsCurrentAnimation(an) then
                    a.synced = a.synced or {}
                    if not a.synced[an] then
                        a.synced[an] = true
                        local began = now - ent.AnimState:GetCurrentAnimationTime()
                        local want = a.t0 + f * FRAMES
                        if math.abs(began - want) > 2 * FRAMES then a.t0_first = a.t0_first or a.t0 a.t0 = a.t0 + (began - want) end
                    end
                elseif not (a.synced or {})[an] then
                    -- (and, still in the one before it, held short of it - not on into its blows while it stays under: the
                    -- Abomination's teleport and optic blast drawn striking all the while, 100 "drawn in, not struck")
                    local prev = nil
                    for i, m in ipairs(a.move.anims) do if m == an and i > 1 then prev = a.move.anims[i - 1] end end
                    if prev ~= nil and ent.AnimState:IsCurrentAnimation(prev) and now - a.t0 > (f - 1) * FRAMES then
                        a.t0_first = a.t0_first or a.t0
                        a.t0 = now - (f - 1) * FRAMES
                    end
                end
            end
        end
        -- (gone somewhere else at a stroke as its snap animation begins (sim.snap_anim) - the Umbral Abomination's optic blast
        -- teleporting onto you (optic_blast_appear: Physics:Teleport to its target): from there on, from where it came up -
        -- drawn from where it began, its chase's shape 4 off it, 2026-10-28. TR_OLD_SNAPPOS)
        -- (or seen gone there before its snap animation is - your game told where it is a frame before what it plays: from
        -- there at once, not a frame drawn from where it began turned the way it now faces - flipped round and back, the
        -- player's "flickering frame", lag bench 2026-10-28)
        if a.move.sim ~= nil and a.move.sim.snap_anim ~= nil and not a.snap_pos and not rawget(_G, "TR_OLD_SNAPPOS") then
            local sx, _, sz = ent.Transform:GetWorldPosition()
            local lp = a.snap_last
            local jumped = lp ~= nil and (sx - lp[1]) ^ 2 + (sz - lp[2]) ^ 2 > 3 * 3
            a.snap_last = { sx, sz }
            if ent.AnimState:IsCurrentAnimation(a.move.sim.snap_anim) or jumped then
                a.snap_pos = true
                if (sx - a.x) ^ 2 + (sz - a.z) ^ 2 > 3 * 3 then a.x, a.z = sx, sz end
            end
        end
        -- (one striking anew each time an animation of it starts over (SimMoves._relock): each go drawn from that frame of
        -- the move, locked the way it faces as it starts - the one before left burning on to its end (after). Uncompromising
        -- Mode's Retinazer's mouth laser, 3-5 in a row, each aimed anew. TR_OLD_RELOCK)
        local rl = SimMoves._relock[ent.prefab] ~= nil and SimMoves._relock[ent.prefab][a.move.name] or nil
        if rl ~= nil and not rawget(_G, "TR_OLD_RELOCK") and ent.AnimState:IsCurrentAnimation(rl.anim) then
            local began = now - ent.AnimState:GetCurrentAnimationTime()
            if a.relock_began == nil or began > a.relock_began + 2 * FRAMES then
                if a.relock_began ~= nil then
                    local old = {}
                    for k, v in pairs(a) do old[k] = v end
                    old.log = nil
                    after[ent] = old
                end
                a.relock_began = began
                a.t0 = began - rl.at * FRAMES
                local lx, _, lz = ent.Transform:GetWorldPosition()
                local r = ent.Transform:GetRotation() * DEGREES
                a.locked = { target = { x = lx + 8 * math.cos(r), z = lz - 8 * math.sin(r), me = false }, rot = r, x = lx, z = lz, exact = true }
            end
        end
        -- (in a state its code may go through on the way, never run offline - the Scrappy Werepig,
        -- its target lost as it winds up, holding its junk (throw_loop) till it has one again: the
        -- same move, its clock held still meanwhile - Tables._waits)
        local waits = Tables._waits ~= nil and Tables._waits[ent.prefab] ~= nil and Tables._waits[ent.prefab][a.move.name] or nil
        -- (or the move's own (sim.waits, a hand file's): Uncompromising Mode's bomber bee dives from 35 up in stab_pre and stab
        -- till it's down, then strikes at frame 3 of stab_death - its ring round it drawn the whole way down, not its first
        -- 3 frames only: struck 13 times with no ring there, lag 0841. Not "no target" after it (the werepig's rule): its
        -- target isn't its combat's. TR_OLD_SIMWAITS: none)
        local own_waits = waits == nil and a.move.sim ~= nil and a.move.sim.waits or nil
        if own_waits ~= nil and not rawget(_G, "TR_OLD_SIMWAITS") then waits = own_waits end
        local waiting = waits ~= nil and not into and Playing(ent, waits)
        if waiting then
            if a.wait_at ~= nil then a.t0 = a.t0 + (now - a.wait_at) end
            a.wait_at = now
            -- (one falling to strike as it's down (sim.fall: how fast it falls, units a second): the time it has yet to fall,
            -- for its colour - SimMoves.dt_add. TR_OLD_FALLTIME: none, red the whole way down)
            if own_waits ~= nil and a.move.sim.fall ~= nil and not rawget(_G, "TR_OLD_FALLTIME") then
                local _, y = ent.Transform:GetWorldPosition()
                a.fall_left = math.max(0, (y or 0) - 1) / a.move.sim.fall
            end
        else
            a.fall_left = nil
            -- (out of it with still no target - the Scrappy Werepig waited its time out and throws
            -- the way it faces, 12 on: not where you are - not drawn there; what it throws drawn
            -- on its own as it comes)
            if a.wait_at ~= nil and own_waits == nil then
                local combat = ent.replica ~= nil and ent.replica.combat or nil
                if combat ~= nil and combat:GetTarget() == nil then a.untargeted = true end
            end
            a.wait_at = nil
        end
        if not into and (waiting or Playing(ent, a.move.anims)) and now - a.t0 <= last then
            if charge and Turned(ent.Transform:GetRotation() * DEGREES, a.rot) > RETURN_TURN then
                -- (it set off another way: from here)
                local x, _, z = ent.Transform:GetWorldPosition()
                a.x, a.z, a.rot = x, z, ent.Transform:GetRotation() * DEGREES
            end
            -- (two moves begun the same way - the Ancient Guardian's leap and its stomp: taken for
            -- the one that goes somewhere; still where it began well after that would have set off -
            -- the other)
            local sim = a.move.sim
            if sim ~= nil and a.alt == nil then
                for _, m in ipairs(moves) do
                    -- (alike as it's drawn too - not a bigger level of it, the Shadow Knight's: that's told
                    -- apart by its size)
                    if m ~= a.move and m.sim ~= nil and m.anims[1] == a.move.anims[1]
                    -- (and of the same form - not the Twins' mouth laser, three of them after you, for
                    -- the eye's one: told apart by after_anim as the move itself was)
                        and (m.sim.scale or 1) == (sim.scale or 1) and m.sim.look == sim.look
                        and m.sim.after_anim == sim.after_anim then
                        if not sim.still and m.sim.still then a.alt = m end
                        -- (both staying put - the shark's bite and its bites one after another: no way
                        -- to tell them apart - both drawn, all along)
                        -- (not one that strikes just the same - Uncompromising Mode's Krampus feint, the
                        -- plain kick's own timeline with its counter after: one shape, drawn once, not two
                        -- copies aimed a little apart; its counter is a move of its own. TR_OLD_SAMEALT: as before)
                        -- (or one striking the very same cells a few frames apart - the Ancient Guardian's gore
                        -- and its gore as it stops: drawn once, the earlier of the two. TR_OLD_SAMEFOOT: as before)
                        -- (and of two the same shape, the one that goes again drawn - the Celestial Champion's
                        -- summon chops three times over: the plain chop kept, nothing drawn 208 times between)
                        -- (not a lookalike that only follows another move of its own straight on, for one begun
                        -- from idle or running - the Glacial Hound's ice howl comes only after its charge
                        -- (289 of 289), its bite only from idle or running (1,103 of 1,103): the howl not drawn
                        -- over a bite. TR_OLD_STRAIGHT: as before)
                        local skip_alt = sim.still and m.sim.still and a.straight == false
                            and (m.name or ""):find("~", 1, true) ~= nil and (a.move.name or ""):find("~", 1, true) == nil
                            and m.sim.things_only and not sim.things_only and not rawget(_G, "TR_OLD_STRAIGHT")
                        if skip_alt then
                            a.alt, a.alt_always = false, nil
                            break
                        elseif sim.still and m.sim.still then
                            local foot, shift = false, 0
                            if not rawget(_G, "TR_OLD_SAMEFOOT") then foot, shift = SameFoot(m.sim, a.move.sim) end
                            foot = foot and shift * FRAMES <= LINGER
                            if foot and not SameShape(m.sim, sim) then
                                if (m.sim.first or 0) < (a.move.sim.first or 0) then a.move, a.locked, a.hist, a.log = m, nil, nil, nil end
                            elseif rawget(_G, "TR_OLD_SAMEALT") or not SameShape(m.sim, sim) then
                                a.alt, a.alt_always = m, true
                            elseif GoesAgain(m.sim) and not GoesAgain(a.move.sim) then
                                a.move, a.locked, a.hist, a.log = m, nil, nil, nil
                            end
                        end
                    end
                end
                a.alt = a.alt or false
            end
            -- (two begun alike told apart at once by where it came from or where it stands - the game's own
            -- way into each (its code): sim.from, the animations its state is only entered after (Uncompromising
            -- Mode's Glacial Hound ice howl only from its charge's scared_pst, 320 of 320; its bite never, 0 of
            -- 1,195); sim.from_self, its state begun again straight after itself (the howl three times, the
            -- Celestial Champion's summon chop); sim.on = "water" / "ground", entered only there (the shark's
            -- bite out of the water, its plain attack in it - its brain, sharkbrain.lua isOnWater). Both drawn
            -- till then, all along for those staying put. TR_OLD_FROMTELL: as before)
            if a.alt and a.told == nil and a.from_told == nil and not rawget(_G, "TR_OLD_FROMTELL") then
                local pick, why = Predict.PickAlike(ent, a, a.move, a.alt, seen)
                if pick ~= nil then
                    a.from_told = why
                    a.chain = why == "itself" and ((Predict.last_go[ent] or {}).chain or 0) + 1 or 0
                    if pick ~= a.move then a.move, a.locked, a.hist, a.log, a.lock_rot = pick, nil, nil, nil, nil end
                    a.alt, a.alt_always, a.tell_wait = false, nil, nil
                    if pick.name ~= nil then
                        print(string.format("[true_range] %s %s (its size told by %s) began %.2fs ago", ent.prefab, pick.name, why, now - a.t0))
                    end
                end
            end
            -- (one taken by its code only from afar (sim.far) and at random there, going somewhere, with one begun alike
            -- staying put - Tropical Experience's slip: past 3 it leaps (1 in 3) or bites where it stands, eat_pre either
            -- way: the leap drawn shooting off as it bit, the player 2026-10-21. The bite alone till the frame the leap
            -- would set off (its path's first step past .3); gone from where it began by then - the leap, else the bite.
            -- TR_OLD_FARTELL: as before)
            if a.far_told == nil and not rawget(_G, "TR_OLD_FARTELL") then
                if a.far_mv == nil and a.far_looked == nil and a.from_told == nil then
                    a.far_looked = true
                    local mv, st = nil, nil
                    for _, m in ipairs(moves) do
                        if m ~= a.move and m.sim ~= nil and sim ~= nil and m.anims[1] == a.move.anims[1] then
                            if sim.far ~= nil and not sim.still and m.sim.still then mv, st = a.move, m
                            elseif m.sim.far ~= nil and not m.sim.still and sim.still then mv, st = m, a.move end
                        end
                    end
                    local at = mv ~= nil and Predict.SetsOffAt(mv.sim) or nil
                    if at ~= nil then
                        a.far_mv, a.far_at = mv, at
                        if st ~= a.move then a.move, a.locked, a.hist, a.log, a.lock_rot = st, nil, nil, nil, nil end
                        a.alt, a.alt_always = false, nil
                    end
                end
                if a.far_mv ~= nil then
                    local x, _, z = ent.Transform:GetWorldPosition()
                    if (x - a.x) ^ 2 + (z - a.z) ^ 2 > .3 * .3 then
                        a.far_told = true
                        a.move, a.locked, a.hist, a.log, a.lock_rot = a.far_mv, nil, nil, nil, nil
                        if a.move.name ~= nil then
                            print(string.format("[true_range] %s %s (its size told by setting off) began %.2fs ago", ent.prefab, a.move.name, now - a.t0))
                        end
                    elseif now - a.t0 > (a.far_at + 3) * FRAMES then
                        a.far_told = true
                    end
                end
            end
            -- (or told at once by what one of them makes as it begins (sim.tell) - Uncompromising Mode's
            -- shot puts an eyeofterror_chargepulse at the boss on entering its state, the charge never
            -- (bench: 374 pulses, 374 shots): one made by it within its first frames - that one; none by
            -- frame 3 - the other. TR_OLD_TELL: as before)
            -- (and of two both staying put too - the Celestial Champion's summon chop, its summon_fx at it as it begins:
            -- TR_OLD_TELLSTILL, as before)
            if a.alt and (not a.alt_always or (not rawget(_G, "TR_OLD_TELLSTILL") and ((a.alt.sim ~= nil and a.alt.sim.tell ~= nil) or sim.tell ~= nil))) and a.told == nil and not rawget(_G, "TR_OLD_TELL") then
                local tm, other = nil, nil
                if a.alt.sim ~= nil and a.alt.sim.tell ~= nil then tm, other = a.alt, a.move
                elseif sim.tell ~= nil then tm, other = a.move, a.alt end
                if tm ~= nil then
                    local x, _, z = ent.Transform:GetWorldPosition()
                    local seen_it = false
                    for thing, made in pairs(Predict.tell_things) do
                        if thing.prefab ~= nil then Predict.tell_seen[thing.prefab] = true end
                        if thing.prefab == tm.sim.tell and made >= a.t0 - 2 * FRAMES and made <= a.t0 + 4 * FRAMES
                            and thing.IsValid ~= nil and thing:IsValid() then
                            local tx, _, tz = thing.Transform:GetWorldPosition()
                            if (tx - x) ^ 2 + (tz - z) ^ 2 < .5 * .5 then seen_it = true break end
                        end
                    end
                    -- (none seen: told only once such things have been seen made at all - else left to the
                    -- rules below, as before: the replays fed none, every shot was decided a charge, FALSE x3)
                    -- (not yet told, its first 4 frames: nothing drawn - the one it was taken for drawn the frame
                    -- before the pulse came, Retinazor's charge flashed as it began its laser, the player's
                    -- report 2026-10-18. TR_OLD_TELLWAIT: as before)
                    -- (kept as the time it ends - past it drawn again, whatever else decides it)
                    a.tell_wait = not rawget(_G, "TR_OLD_TELLWAIT") and a.t0 + 4 * FRAMES or nil
                    -- (or none such ever seen yet, but this game told of what's made all the same (not TR_UNTOLD) - in
                    -- a game, every one made is told (modmain): Retinazor's first dashes, before any shot had made
                    -- a pulse, were drawn with its laser too, all the way, the player's report 2026-10-20.
                    -- TR_OLD_TELLSEEN: as before)
                    local can_tell = Predict.tell_seen[tm.sim.tell] or (not rawget(_G, "TR_UNTOLD") and not rawget(_G, "TR_OLD_TELLSEEN"))
                    if seen_it or (now - a.t0 > 4 * FRAMES and can_tell) then
                        a.tell_wait = nil
                        a.told = seen_it and tm.sim.tell or "none"
                        local pick = seen_it and tm or other
                        if pick ~= a.move then a.move, a.locked, a.hist, a.log, a.lock_rot = pick, nil, nil, nil, nil end
                        a.alt, a.alt_always = false, nil
                        -- (said as a new begin, for tools/move_state_check.lua: what it was taken for once told)
                        if pick.name ~= nil then
                            print(string.format("[true_range] %s %s (its size told by %s) began %.2fs ago", ent.prefab, pick.name, a.told, now - a.t0))
                        end
                    end
                end
            end
            -- (or still turning after you past the frame the one that goes stops aiming - the Twins' shot, not
            -- their charge: a charge never turned after its frame 11 (14,800 goes, the bench and a player's
            -- log), a shot went on after you 8 or more 60 / 42 times in 72 - both drawn at once till frame
            -- 34 otherwise, the player's report. TR_OLD_TURNTELL: as before)
            if a.alt and not a.alt_always and sim.lock ~= nil and not rawget(_G, "TR_OLD_TURNTELL") then
                local el, r = now - a.t0, ent.Transform:GetRotation()
                if el >= sim.lock * FRAMES and a.lock_rot == nil then a.lock_rot = r end
                if a.lock_rot ~= nil and el >= (sim.lock + 4) * FRAMES and math.abs(((r - a.lock_rot) + 180) % 360 - 180) > 8 then
                    a.move, a.alt, a.locked, a.hist, a.log, a.lock_rot = a.alt, false, nil, nil, nil, nil
                end
            end
            if a.alt and not a.alt_always and now - a.t0 > ((sim.moves_at or sim.lock or 0) + 3) * FRAMES then
                local x, _, z = ent.Transform:GetWorldPosition()
                if (x - a.x) ^ 2 + (z - a.z) ^ 2 < .25 then
                    a.move, a.alt, a.locked, a.hist, a.log = a.alt, false, nil, nil, nil
                else
                    a.alt = false
                end
            end
            return a
        end
        if a.move.name ~= nil then
            -- (what really happened, for checking against what was drawn: client_log.txt)
            local x, _, z = ent.Transform:GetWorldPosition()
            print(string.format("[true_range] %s %s over: it went %.2f from where it began, %.2fs",
                ent.prefab, a.move.name, math.sqrt((x - a.x) ^ 2 + (z - a.z) ^ 2), now - a.t0))
        end
        -- (and kept: how far its leap really goes this game - SimMoves._WentDist; seen at its end, the client's picture
        -- of it caught up - Klaus' bite seen standing still all through its leap, there at once later)
        if a.move.sim ~= nil and a.log ~= nil and a.log.went_base ~= nil then
            local x, _, z = ent.Transform:GetWorldPosition()
            SimMoves.WentSeen(ent, a.move.sim, math.sqrt((x - a.x) ^ 2 + (z - a.z) ^ 2), a.log)
        end
        -- (or over within its linger after the last (LINGER) - the Ancient Guardian's leaps one after another (Uncompromising
        -- Mode's leap_attack_pre_quick): each lands as the next begins, a few frames later than run offline - gone that very
        -- frame, its landing undrawn; a friend beside the one it leapt at struck there 35 times unwarned, the testbench's
        -- friend 2026-10-21. TR_OLD_ENDLINGER: as before)
        local last_by = a.move.sim ~= nil and LastStrike(a.move.sim) * FRAMES + (rawget(_G, "TR_OLD_ENDLINGER") and 0 or LINGER) or 0
        -- (its last blows set going for later (SimMoves._tail) - struck after it ends as it should, not only when knocked out of it:
        -- the Magma Hound's last breath setting you alight a third of a second after its sixth belch was over)
        local health0 = ent.replica ~= nil and ent.replica.health or nil
        if a.move.sim ~= nil and SimMoves._tail[ent.prefab] ~= nil and not rawget(_G, "TR_OLD_TAIL") and ent:IsValid()
            and not ent:HasTag("dead") and not (health0 ~= nil and health0:IsDead()) then
            a.tail_until = now + SimMoves._tail[ent.prefab] * FRAMES
            after[ent] = a
        elseif a.move.sim ~= nil and now - a.t0 < last_by then
            -- (its animation over before its last strike: killed - what it set off on its own;
            -- else it just went on to the next, its lasers still burning - the move drawn on,
            -- whole, until its last)
            local health = ent.replica ~= nil and ent.replica.health or nil
            if not ent:IsValid() or ent:HasTag("dead") or (health ~= nil and health:IsDead()) then
                cut_until = now + 2
            -- (not one that strikes as it runs, its length its own (sim.fixed) - the Ancient
            -- Guardian's charge: stopped, its brain giving up on you off its way, nothing's left -
            -- its whole way drawn on ahead of it, though it stood biting)
            -- (nor one whose own body goes its way striking (sim.free) - the Rabbit King's dropkick,
            -- landed on you: its flight over, nothing left of it)
            -- (nor a bite where it stands, struck by its own body alone - still, nothing put down
            -- (sim.puts): alive, on to an animation not its own, it has left its state and its
            -- strike with it - the Smallbird's bite (not busy: off after you as you step aside, its
            -- atk queued behind its walk), a Glacial Hound's bite taken for its ice howl's atk_pre,
            -- gone to idle, never to atk; a frog's put to sleep, a penguin's into its taunt: 444 /
            -- 89 / 47 / 46 drawn in, no strike. Not one that goes somewhere - the Ancient
            -- Guardian's leap, landed stunned, still strikes as it lands)
            elseif a.move.sim.leg == nil and a.move.sim.around == nil and not a.move.sim.fixed and a.move.sim.free == nil
                and (a.move.sim.puts ~= nil or not a.move.sim.still) then
                -- (not one whose thing is drawn as the server tells its reach (SimMoves._live_radius): that is all of it - the
                -- Klaus deer's cast drawn on 5 s as run offline, over its ice circle as it really grew, smaller and shrinking,
                -- the player 2026-10-27. TR_OLD_LIVERADIUS)
                local live = false
                local tab = not rawget(_G, "TR_OLD_LIVERADIUS") and a.move.name ~= nil and Tables[ent.prefab] ~= nil
                    and Tables[ent.prefab][a.move.name] or nil
                for _, th in ipairs(tab ~= nil and tab.things or {}) do
                    if SimMoves._live_radius[th] ~= nil then live = true end
                end
                -- (and what its data says it puts down - Uncompromising Mode's moves have no table)
                if not rawget(_G, "TR_OLD_LIVERADIUS") and type(a.move.sim.puts) == "table" then
                    for _, th in ipairs(a.move.sim.puts) do
                        if SimMoves._live_radius[th] ~= nil then live = true end
                    end
                end
                if not live then after[ent] = a end
            end
        end
        Predict.last_go[ent] = { name = a.move.name, t = now, chain = a.chain }
        -- (a move of its own over, into an animation not its own: something else, as far as going straight into another's
        -- later animation goes (below) - the Shadow Thrall mouth out of the Umbral Abomination's portal (a move of its own,
        -- portal_appear) straight into bite_loop: idle never seen between, its bites never taken up. seen._left)
        if not Playing(ent, a.move.anims) and not rawget(_G, "TR_OLD_MIDLEFT") then seen._left = now end
        active[ent] = nil
        -- (one not drawn - thrown with no target: what it set off not held back after it)
        if not a.untargeted then move_ended[ent] = now end
    end
    -- (one boss's move run offline as it is now and in a later, bigger form (Klaus enraged): the
    -- one as big as it's drawn now)
    local scale = ent.Transform.GetScale ~= nil and ent.Transform:GetScale() or nil
    -- (or as it looks: Dragonfly on fire - sim.look: what its build's name has in it then)
    local build = ent.AnimState.GetBuild ~= nil and ent.AnimState:GetBuild() or nil
    local function Off(move)
        local look = move.sim ~= nil and move.sim.look or nil
        -- (looking so: before the plain one; not: never)
        local off = 0
        if look ~= nil then
            off = (build ~= nil and build:find(look, 1, true)) and -1000 or 1000
        end
        -- (run offline at its own size: 1 - a shadow piece at level 1, against its bigger levels)
        local s = move.sim ~= nil and move.sim.scale or 1
        -- (one of two forms begun alike: the one whose own animations it was seen playing last)
        for _, m in ipairs(moves) do
            if m ~= move and m.anims[1] == move.anims[1] then
                local mine, theirs = -1, -1
                local in_m = {}
                for _, x in ipairs(m.anims) do in_m[x] = true end
                -- (not by the last animation alone - what its offline run happened to wind down into: the
                -- Twins' laser into a taunt, a roll of the dice after a charge too - seen taunting, its
                -- next charge was taken for a laser, the charge not drawn)
                for i, x in ipairs(move.anims) do if (i < #move.anims or i == 1) and not in_m[x] and seen[x] then mine = math.max(mine, seen[x]) end end
                local in_move = {}
                for _, x in ipairs(move.anims) do in_move[x] = true end
                for i, x in ipairs(m.anims) do if (i < #m.anims or i == 1) and not in_move[x] and seen[x] then theirs = math.max(theirs, seen[x]) end end
                if theirs > mine then off = off + 500 end
                -- (the later form - after_anim: only once it has been seen turning into it; the
                -- other, once it has)
                local mine_aa = move.sim ~= nil and move.sim.after_anim or nil
                local theirs_aa = m.sim ~= nil and m.sim.after_anim or nil
                if mine_aa ~= nil and not seen[mine_aa] then off = off + 1000 end
                if theirs_aa ~= nil and seen[theirs_aa] then off = off + 1000 end
            end
        end
        -- (its size not known: as it first is, the smallest)
        return off + (scale ~= nil and math.abs(s - scale) or s)
    end
    local best = nil
    for _, move in ipairs(moves) do
        -- (as alike: the one that goes somewhere first - see Track)
        if ent.AnimState:IsCurrentAnimation(move.anims[1]) and (best == nil or Off(move) < Off(best)
            or (Off(move) == Off(best) and best.sim ~= nil and best.sim.still and move.sim ~= nil and not move.sim.still
                -- (not one taken only from afar, at random (sim.far): the one staying put till it sets off - Track)
                and (move.sim.far == nil or rawget(_G, "TR_OLD_FARTELL")))
            -- (both alike that way too: the one listed first - its name has no "~")
            or (Off(move) == Off(best) and best.sim ~= nil and move.sim ~= nil and (best.sim.still == true) == (move.sim.still == true)
                and (best.name or ""):find("~", 1, true) ~= nil and (move.name or ""):find("~", 1, true) == nil)) then
            best = move
        end
    end
    -- (none begun - gone straight into one of its later animations, its wind-up skipped: the
    -- Shadow Thrall mouth out of hiding, straight into its bite's loop - that move, its strikes
    -- under way (as from its first strike); only an animation no other move of it plays)
    local skip_to = 0
    -- (not its last - winding down; nor where it got by its earlier ones since it last did something
    -- else - the same go of it looping on, a deer's spell going round three times, not a new one)
    local other_at = math.max(seen._other or -math.huge, seen._left or -math.huge)
    if best == nil and other_at > -math.huge then
        local found, count = nil, 0
        for _, move in ipairs(moves) do
            -- (not one that puts things down where its target was (sim.set_until) - where it put
            -- them, missed, can't be told: drawn under you instead, a deer's spell already cast)
            if move.sim ~= nil and move.sim.set_until == nil then
                for i = 2, #(move.anims or {}) - 1 do
                    if ent.AnimState:IsCurrentAnimation(move.anims[i]) then
                        local before = seen["^" .. move.anims[1]] or -math.huge
                        for j = 2, i - 1 do before = math.max(before, seen[move.anims[j]] or -math.huge) end
                        if before < other_at then found, count = move, count + 1 end
                        break
                    end
                end
            end
        end
        if count == 1 then best, skip_to = found, (found.sim.first or 0) * FRAMES end
    end
    if best ~= nil and seen._slow ~= nil and best.anims[1] == seen._slow then best = nil end
    if best ~= nil then
        local x, _, z = ent.Transform:GetWorldPosition()
        -- (sim.anim_from: its state begins its animation that far in (SetFrame) - its frames counted from the state, this
        -- clock from the animation: Hallowed Nights' mummy merm and vampire bunny (hn_attack, SetFrame(4)), game 760944.
        -- TR_OLD_ANIMFROM: as before)
        local from = (best.sim ~= nil and not rawget(_G, "TR_OLD_ANIMFROM") and best.sim.anim_from or 0) * FRAMES
        a = { move = best, t0 = now - ent.AnimState:GetCurrentAnimationTime() - skip_to + from, x = x, z = z,
            rot = ent.Transform:GetRotation() * DEGREES,
            anim0 = skip_to == 0 and ent.AnimState:GetCurrentAnimationTime() or nil, real0 = now }
        a.rot_begin = a.rot
        -- (begun again straight after itself, the last of a chain (SimMoves._chain_last): as that other one's run, the one that
        -- stops - TR_OLD_CHAINLAST)
        local cl = SimMoves._chain_last[ent.prefab]
        if cl ~= nil and cl[best.name] ~= nil and not rawget(_G, "TR_OLD_CHAINLAST") then
            local lg = Predict.last_go[ent]
            if lg ~= nil and lg.name == best.name and a.t0 - lg.t <= 12 * FRAMES then
                for _, m in ipairs(SimMoves.Moves(cl[best.name].prefab)) do
                    if m.name == cl[best.name].move then
                        a.move = { anims = best.anims, frames = best.frames, sim = m.sim, name = best.name }
                        a.chain_last = true
                    end
                end
            end
        end
        -- (begun alike with one told by what it makes (sim.tell): nothing drawn its first 4 frames, from
        -- this very frame - told only from the next, the charge flashed first, FLIPDRAWN 233 of 235
        -- at frame 2-3. TR_OLD_TELLWAIT: as before)
        -- (told at once, the very frame it begins, where it came from or stands (Predict.PickAlike) - a frame
        -- later the shark's plain attack had flashed first, FLIPDRAWN 131)
        if best.sim ~= nil and not rawget(_G, "TR_OLD_FROMTELL") then
            for _, m in ipairs(moves) do
                if m ~= best and m.sim ~= nil and m.anims[1] == best.anims[1] then
                    local pick, why = Predict.PickAlike(ent, a, best, m, seen)
                    if pick ~= nil then
                        a.from_told = why
                        a.chain = why == "itself" and ((Predict.last_go[ent] or {}).chain or 0) + 1 or 0
                        a.move, a.alt = pick, false
                        break
                    end
                end
            end
        end
        if not rawget(_G, "TR_OLD_TELLWAIT") and not rawget(_G, "TR_OLD_TELL") and best.sim ~= nil and a.from_told == nil then
            for _, m in ipairs(moves) do
                -- (not one going again straight after itself (sim.from_self) - told by that at once, no wait: the
                -- Celestial Champion's summon chop again, a gap drawn between - VANISH 172)
                local lg = Predict.last_go[ent]
                local again = lg ~= nil and m.sim ~= nil and m.sim.from_self and lg.name == m.name and a.t0 - lg.t <= 12 * FRAMES
                    and (lg.chain or 0) < (tonumber(m.sim.from_self) or 99) and not rawget(_G, "TR_OLD_FROMTELL")
                local still_pair = m.sim ~= nil and m.sim.still and best.sim.still
                if m.sim ~= nil and m.sim.tell ~= nil and m.anims[1] == best.anims[1] and not again
                    and not (still_pair and rawget(_G, "TR_OLD_TELLSTILL")) then a.tell_wait = a.t0 + 4 * FRAMES break end
            end
        end
        -- (begun straight after one of its own moves, or after something else - idle, running: a.straight false)
        if seen._other ~= nil then a.straight = seen._other < a.t0 + skip_to - 2 * FRAMES end
        active[ent] = a
        if a.move.name ~= nil then
            print(string.format("[true_range] %s %s (its size %s, run offline at %s) began %.2fs ago",
                ent.prefab, a.move.name, tostring(scale), tostring(a.move.sim and a.move.sim.scale), now - a.t0))
        end
        return a
    end
    return nil
end

function Predict.Knows(prefab)
    return MovesOf(prefab) ~= nil
end

-- Whether it's in one of its moves now - tracked, or playing an animation one of them plays (not tracked: one
-- left out of those drawn) - for which to keep when there are too many to draw (modmain Pick)
function Predict.Attacking(ent)
    if active[ent] ~= nil then return true end
    local moves = MovesOf(ent.prefab)
    if moves == nil or ent.AnimState == nil then return false end
    for _, m in ipairs(moves) do
        for _, an in ipairs(m.anims or {}) do
            if ent.AnimState:IsCurrentAnimation(an) then return true end
        end
    end
    return false
end

-- One move's shape, with the monster at (x, z) facing rot. k: how close the damage is (0 to 1;
-- nil: no countdown, all of it filled). Returns whether (px, pz) is inside.
-- A map of where hits came (true_range/learn: Learn.GRID), around (x, z) facing rot: each
-- sector's runs of marked rings drawn as one piece. Returns whether (px, pz) - or a point
-- my_radius off it - is in a marked cell.
local GRID = Learn.GRID

local function Grid(cells, my_radius, x, z, rot, px, pz, fill, edge, scale)
    scale = scale or 1
    local step = GRID.step * scale
    local da = 2 * math.pi / GRID.sectors
    for sector = 0, GRID.sectors - 1 do
        -- (local angles: off its facing; the world's: rot minus that)
        local a1 = sector * da - math.pi
        local w1, w2 = rot - (a1 + da), rot - a1
        local ring = 0
        while ring < GRID.rings do
            if cells[sector * GRID.rings + ring] then
                local first = ring
                while ring + 1 < GRID.rings and cells[sector * GRID.rings + ring + 1] do
                    ring = ring + 1
                end
                local r1, r2 = first * step, (ring + 1) * step
                local mid = (w1 + w2) / 2
                if fill ~= nil then
                    if first == 0 then
                        Lines.Wedge(x, z, r2, w1, w2, fill)
                    else
                        local rm = (r1 + r2) / 2
                        Lines.Segment(x + r1 * math.cos(mid), z - r1 * math.sin(mid), x + r2 * math.cos(mid),
                            z - r2 * math.sin(mid), fill, 2 * rm * math.sin(da / 2) + .05)
                    end
                end
                Arc(x, z, r2, w1, w2, edge)
            end
            ring = ring + 1
        end
    end
    if px == nil then
        return false
    end
    local c, s = math.cos(rot), math.sin(rot)
    for _, o in ipairs({ { 0, 0 }, { my_radius, 0 }, { -my_radius, 0 }, { 0, my_radius }, { 0, -my_radius } }) do
        local dx, dz = (px + o[1] - x) / scale, (pz + o[2] - z) / scale
        local cell = Learn.Cell(dx * c - dz * s, dx * s + dz * c)
        if cell ~= nil and cells[cell] then
            return true
        end
    end
    return false
end

-- An area attack around (x, z) facing rot: a fan (or a circle), centred `offset` ahead, and
-- maybe a circle all round it too (inner).
local function Area(learned, hit, my_radius, x, z, rot, k, px, pz, fill, edge, preview, target)
    if learned ~= nil and learned.grid ~= nil then
        local mode = learned.grid_mode or 0
        if mode == 0 then
            return Grid(learned.grid, my_radius, x, z, rot, px, pz, fill, edge)
        end
        -- (laid out from where its target is, or scaled by how far that is: no target, no map)
        if target == nil then
            return false
        end
        local d = (target.x - x) * math.cos(rot) - (target.z - z) * math.sin(rot)
        if d < 1 then
            return false
        end
        if mode == 1 then
            return Grid(learned.grid, my_radius, x + d * math.cos(rot), z - d * math.sin(rot), rot, px, pz, fill, edge)
        end
        return Grid(learned.grid, my_radius, x, z, rot, px, pz, fill, edge, d / Learn.GRID_REF)
    end
    local radius, half
    local inner = 0
    local cx, cz = x, z
    if learned ~= nil and learned.single then
        -- (it only ever hits what it's after: all round it, out to its reach - whichever way
        -- its target stands)
        radius, half = math.max(learned.radius, hit) + my_radius, 180
    elseif learned ~= nil and learned.radius > 0 then
        -- (what it learned from hits is only as far as they happened to land - never less than
        -- the hit range the game checks; measured with probes, it's the real thing)
        radius, half = (learned.probed and learned.radius or math.max(learned.radius, hit)) + my_radius, learned.half
        local off = learned.offset or 0
        cx, cz = x + off * math.cos(rot), z - off * math.sin(rot)
        inner = (learned.inner or 0) > 0 and learned.inner + my_radius or 0
    else
        radius, half = hit + my_radius, 180
    end
    -- (fill nil: just its outline - it's after someone else, you're not in it)
    local inside = false
    if inner > 0 then
        if fill ~= nil then
            Lines.Disc(x, z, inner, fill)
            if k ~= nil and k > 0 and not preview then
                Lines.Disc(x, z, inner * math.min(1, k), "swept")
            end
        end
        Arc(x, z, inner, 0, 2 * math.pi, edge)
        inside = px ~= nil and (px - x) ^ 2 + (pz - z) ^ 2 <= inner * inner
    end
    if radius > my_radius + .05 then
        if fill ~= nil then
            FilledFan(cx, cz, rot, radius, half, fill)
            if k ~= nil and k > 0 and not preview then
                FilledFan(cx, cz, rot, radius * math.min(1, k), half, "swept")
            end
        end
        FanOutline(cx, cz, rot, radius, half, edge)
        inside = inside or (px ~= nil and InFan(px, pz, cx, cz, rot, radius, half))
    end
    return inside
end

local function Shape(learned, hit, my_radius, x, z, rot, start, k, px, pz, preview, target)
    local fill = preview and "fill" or "fill"
    local edge = preview and "wave" or "edge"
    if learned ~= nil and learned.single and not (target ~= nil and target.me) then
        -- (it only hits what it's after, and that isn't you: shown, but you're safe)
        fill, edge, px, pz = nil, "wave", nil, nil
    end
    if learned ~= nil and learned.at_target then
        -- thrown at its target: around where its target is
        if target == nil then
            return false
        end
        return Area(learned, hit, my_radius, target.x, target.z, rot, k, px, pz, fill, edge, preview)
    end
    if learned ~= nil and learned.travel >= MIN_TRAVEL and learned.leap then
        -- a leap: it only hits where it lands - as far as it usually goes along the way it set
        -- off (start), or, if it goes for its target, where that stands
        local sx, sz, srot = x, z, rot
        if start ~= nil then
            sx, sz, srot = start.x, start.z, start.rot
        end
        local lx, lz = sx + learned.travel * math.cos(srot), sz - learned.travel * math.sin(srot)
        if learned.aim and target ~= nil then
            local reach = (learned.travel_max or learned.travel) + 2
            if (target.x - sx) ^ 2 + (target.z - sz) ^ 2 <= reach * reach then
                lx, lz = target.x, target.z
            end
        end
        -- (faced the way it's going)
        local lrot = (lx ~= sx or lz ~= sz) and math.atan2(-(lz - sz), lx - sx) or srot
        -- (its way there, just a thin line: it's in the air, nothing on the way is hit)
        Lines.Segment(x, z, lx, lz, "wave")
        return Area(learned, hit, my_radius, lx, lz, lrot, k, px, pz, fill, edge, preview)
    end
    if learned ~= nil and learned.travel >= MIN_TRAVEL and learned.chase and target ~= nil then
        -- it chases its target: from where it is now, straight at them (as far as it goes)
        local side = learned.width > 0 and learned.width or hit
        local hw = side + my_radius
        local dx, dz = target.x - x, target.z - z
        local dist = math.sqrt(dx * dx + dz * dz)
        local length = math.min(dist, learned.travel_max or learned.travel)
        local crot = dist > .01 and math.atan2(-dz, dx) or rot
        Strip(x, z, crot, length, hw, fill, edge)
        return px ~= nil and InStrip(px, pz, x, z, crot, length, hw)
    end
    if learned ~= nil and learned.travel >= MIN_TRAVEL then
        -- a charge: fixed to where it set off (start) and the way it faced then, out to where
        -- it will stop - plus how far in front of itself its hits land. Only the part still
        -- ahead of it is drawn.
        local side = learned.width > 0 and learned.width or hit
        local hw = side + my_radius
        local length = learned.travel + math.max(0, learned.radius - side)
        local sx, sz, srot = x, z, rot
        if start ~= nil then
            sx, sz, srot = start.x, start.z, start.rot
            local c, s = math.cos(srot), math.sin(srot)
            local done = math.max(0, math.min(length, (x - sx) * c - (z - sz) * s))
            sx, sz, length = sx + done * c, sz - done * s, length - done
        end
        Strip(sx, sz, srot, length, hw, fill, edge)
        return px ~= nil and InStrip(px, pz, sx, sz, srot, length, hw)
    end
    if learned ~= nil and learned.width > 0 then
        -- a beam straight ahead
        local hw = learned.width + my_radius
        Strip(x, z, rot, learned.radius, hw, fill, edge)
        return px ~= nil and InStrip(px, pz, x, z, rot, learned.radius, hw)
    end
    return Area(learned, hit, my_radius, x, z, rot, k, px, pz, fill, edge, preview, target)
end

-- A move whose cooldown is nearly over (the server's timers: r.cds, as of r.at): its outline in
-- white, flashed twice, then gone - it may come any moment now. (Of a move run offline at
-- several sizes, the one as big as it is now.)
-- (two soft pulses over its last second: brightening and fading like breath, not blinking)
local FLASH_BEFORE, FLASH_PULSES, FLASH_ALPHA = 1, 2, .85
local Render = require("true_range/render")
local flashed = setmetatable({}, { __mode = "k" })  -- (testing: ent -> the cooldown last flashed, said once)
-- (ent -> cooldown -> when a move on it began: its cooldown started over then - the server's
-- word from before that is out of date for it, not flashed on top of the move itself)
local restarted = setmetatable({}, { __mode = "k" })
-- (ent -> when it was last in a move, by our clock)
local move_seen = setmetatable({}, { __mode = "k" })
-- (ent -> { t, a }: when its glow was last lit by a cooldown, how bright)
local glow_lit = setmetatable({}, { __mode = "k" })
-- (ent -> cooldown -> when we first saw that move begun, by our clock)
local begun_seen = setmetatable({}, { __mode = "k" })
-- (ent -> { p = whom its flash is drawn at, t = when the flash began })
local flash_aim = setmetatable({}, { __mode = "k" })
-- (its glow as last lit, kept the moment Flash has nothing to go on - whom it's after not said a frame, the server's word not
-- come yet: out 1-3 frames between, GLOWHOLD alone not reaching it, lag_ink3 2026-10-28. TR_OLD_GLOWHOLD)
local function HeldGlow(ent)
    if rawget(_G, "TR_OLD_GLOWHOLD") or Render.cooldown ~= "glow" then return end
    local gl = glow_lit[ent]
    local age = gl ~= nil and (GetStaticTime or GetTime)() - gl.t or 1e9
    local a = gl ~= nil and gl.a * math.min(1, 1 - (age - .3) / .7) or 0
    if a <= .02 then return end
    for i, style in ipairs(SimMoves.GLOW_STYLES) do
        Lines.Pulse(style, ({ .8, .5, .28, .12 })[i] * a / FLASH_ALPHA)
    end
    local x, _, z = ent.Transform:GetWorldPosition()
    SimMoves.Glow(x, z, ent:GetPhysicsRadius(0))
end
local function Flash(ent, moves, r, a)
    if r.cds == nil or r.at == nil or next(r.cds) == nil then
        HeldGlow(ent)
        return
    end
    local cd = a ~= nil and a.move.sim ~= nil and a.move.sim.cooldown or nil
    local now0 = (GetStaticTime or GetTime)()
    if a ~= nil then move_seen[ent] = now0 end
    if cd ~= nil then
        restarted[ent] = restarted[ent] or {}
        local was = restarted[ent][cd]
        restarted[ent][cd] = math.max(was or a.t0, a.t0)
        if restarted[ent][cd] ~= was then
            begun_seen[ent] = begun_seen[ent] or {}
            begun_seen[ent][cd] = now0
        end
    end
    local re = restarted[ent] or {}
    -- (lit on two frames into the move that put it out: its shape laid only from the frame after it's seen begun - a frame
    -- with neither, the glow blinking out before the punch, [tr_lagframe] full3 2026-10-28. TR_OLD_GLOWOVERLAP: out at once)
    local bs = begun_seen[ent] or {}
    local overlap = rawget(_G, "TR_OLD_GLOWOVERLAP") and -1 or .07
    local combat = ent.replica ~= nil and ent.replica.combat or nil
    local tgt = combat ~= nil and combat:GetTarget() or nil
    if tgt == nil or not tgt:IsValid() then
        HeldGlow(ent)
        return
    end
    local since = (GetStaticTime or GetTime)() - r.at
    local scale = ent.Transform.GetScale ~= nil and ent.Transform:GetScale() or nil
    local build = ent.AnimState.GetBuild ~= nil and ent.AnimState:GetBuild() or nil
    local best = {}   -- cooldown -> { sim, off }
    for _, move in ipairs(moves) do
        local sim = move.sim
        local name = sim ~= nil and sim.cooldown or nil
        local left = name ~= nil and r.cds[name] or nil
        if left ~= nil and not (re[name] ~= nil and re[name] >= r.at - .5 and now0 - (bs[name] or -1e9) > overlap) then
            left = left - since
            local el = FLASH_BEFORE - left
            -- (lit on past its end until the move begins (re[name] above puts it out then): the boss starts it a server
            -- tick and the trip to us later - 1-3 frames with nothing drawn between glow and move, the "flickering ring"
            -- left after the pulses went, [tr_lagframe] 2026-10-28. TR_OLD_GLOWGRACE: out at its end)
            if left > (rawget(_G, "TR_OLD_GLOWGRACE") and 0 or -.3) and el >= 0 then
                local off = math.abs((sim.scale or 1) - (scale or 1))
                if sim.look ~= nil then off = off + ((build ~= nil and build:find(sim.look, 1, true)) and -1000 or 1000) end
                local alpha = FLASH_ALPHA * math.sin(math.pi * FLASH_PULSES * el / FLASH_BEFORE) ^ 2
                -- (glowing up and staying lit, not two pulses: between them it went out a frame - a ring blinking round the boss,
                -- the Umbral Abomination's "flickering ring", the player 2026-10-28, seen at last in the lag bench's every-frame
                -- record ([tr_lagframe]: its 354 pieces gone at x.000 and x.500). TR_OLD_GLOWPULSE: the pulses)
                if not rawget(_G, "TR_OLD_GLOWPULSE") then alpha = FLASH_ALPHA * math.min(1, el / .25) end
                -- (lit at once, not faded in, straight after a move's shape: its punch gone, 1-3 frames of nothing, then the glow
                -- coming up from nothing - a blink between, lag_beam4 2026-10-28. TR_OLD_GLOWAFTERMOVE)
                if (move_seen[ent] or -1e9) >= now0 - .2 and not rawget(_G, "TR_OLD_GLOWAFTERMOVE") then alpha = FLASH_ALPHA end
                if best[name] == nil or off < best[name].off then best[name] = { sim = sim, off = off, alpha = alpha } end
            end
        end
    end
    -- (at whom it was after as the flash began, all through it: two players hitting it, its
    -- target changed with each blow - the flash jumped from one to the other and back)
    local now_f = (GetStaticTime or GetTime)()
    if next(best) == nil then
        flash_aim[ent] = nil
    else
        local fa = flash_aim[ent]
        if fa ~= nil and fa.p:IsValid() and now_f - fa.t <= FLASH_BEFORE + .2 then
            tgt = fa.p
        else
            flash_aim[ent] = { p = tgt, t = now_f }
        end
    end
    local x, _, z = ent.Transform:GetWorldPosition()
    local tx, _, tz = tgt.Transform:GetWorldPosition()
    -- (several at once: glowing as bright as the brightest)
    local glow = 0
    for name, b in pairs(best) do
        if Render.cooldown == "shape" then
            Lines.Pulse("flash", b.alpha)
            SimMoves.Flash(b.sim, x, z, ent.Transform:GetRotation() * DEGREES, tx, tz)
        end
        glow = math.max(glow, b.alpha)
        if flashed[ent] ~= name .. math.floor(r.at) then
            flashed[ent] = name .. math.floor(r.at)
            print(string.format("[true_range] %s: %s nearly over - flashed", ent.prefab, name))
        end
    end
    -- (one glow per boss, kept going: lit a moment ago, as bright again - not faded in anew as the server's word moves it on
    -- to another cooldown (teleportcd, opticblastcd), nor out a frame or two between: the Umbral Abomination's ring out 1-3
    -- frames and back, 6 times a run ([tr_lagframe] lag_ink2, 2026-10-28). TR_OLD_GLOWHOLD: as each says)
    if not rawget(_G, "TR_OLD_GLOWHOLD") then
        local gl = glow_lit[ent]
        -- (.3 with none of its cooldowns due: the next one's last second begun up to .3 after the last one's end went
        -- dark 1-4 frames between - tests offline 2026-10-28)
        -- (and past that fading out over .7 s, not cut - the next one due a little later lit on from there: out 1-3 frames and
        -- back again, lag_beam4 2026-10-28)
        if gl ~= nil and now_f - gl.t <= 1 then glow = math.max(glow, gl.a * math.min(1, 1 - (now_f - gl.t - .3) / .7)) end
        if glow > .02 and (gl == nil or gl.t ~= now_f) then
            if next(best) ~= nil then glow_lit[ent] = { t = now_f, a = glow } end
        end
    end
    if Render.cooldown == "glow" and glow > .02 then
        for i, style in ipairs(SimMoves.GLOW_STYLES) do
            Lines.Pulse(style, ({ .8, .5, .28, .12 })[i] * glow / FLASH_ALPHA)
        end
        SimMoves.Glow(x, z, ent:GetPhysicsRadius(0))
    end
end

-- (tests/flash_aim.lua)
Predict._Flash = Flash

-- A move with a table (true_range/moves_table, REDESIGN.md): where it strikes with its target at
-- each place round it, run offline. One rule: until its deciding frame (tab.decide), for where its
-- target is now; from then, for where its target was then - nothing else matters after. Its place
-- in the table: the nearest angle and distance run, turned and moved on to just where its target
-- is. Once what it strikes by has been set off (tab.things), not drawn: those are, themselves.
-- (what it strikes by seen this many frames after it's made, at most - across the network)
local MADE_LATE = 6
-- (where standing makes it go on: shown this many frames before it looks)
local BRANCH_LEAD = 10
local branch_cells = {}
-- (the boss off its run's way: DrawTable)
local TAB_SHIFT_FRAMES, TAB_SHIFT_STEP, TAB_SHIFT_MAX = 2, .6, 12
local TAB_TURN_STEP = 360 * DEGREES
local paths = setmetatable({}, { __mode = "k" })
-- (not yet for one that goes in legs, spins round after you, or runs a set way: what it strikes
-- is up to how its target moves all along, not where it is at one moment - as before)
-- (TR_TABLES_OFF: none - the replays, comparing with how it was)
local function TableOf(prefab, move)
    if rawget(_G, "TR_TABLES_OFF") then return nil end
    local p = Tables[prefab]
    local sim = move ~= nil and move.sim or nil
    -- (nor one run as one shape, its whole way as it set off (sim.lane - the spider's leap): a table's rows go with its
    -- target, the very thing that floated its landing about. TR_OLD_SIMLANE: as before)
    if p == nil or sim == nil or move.name == nil or sim.leg ~= nil or sim.around ~= nil or sim.fixed
        or (sim.lane and not rawget(_G, "TR_OLD_SIMLANE")) then return nil end
    return p[move.name]
end
-- (a row of a table as SimMoves draws one of its moves: made once)
-- (the deciding frame of a blow striking at frame `at`: its own (tab.step_decide - by the
-- nearest blow of the run it was found for), else the move's)
local function DecideOf(tab, at)
    -- (one where it strikes at random - junk falling where it may: one deciding frame for all, the
    -- move's - a blow told apart from another by chance alone was taken as aimed at another moment,
    -- two heaps of junk drawn)
    if tab.random then return tab.decide end
    local best, off = nil, nil
    for fr, f in pairs(tab.step_decide or {}) do
        if off == nil or math.abs(fr - at) < off then best, off = f, math.abs(fr - at) end
    end
    return best or tab.decide
end
-- (each deciding frame of a move's blows, once)
local function Decides(tab)
    if tab._decides == nil then
        local set, list = {}, {}
        for _, e in ipairs(tab.entries) do
            for _, s in ipairs(e.steps or {}) do
                local d = DecideOf(tab, s.at)
                if not set[d] then set[d] = true list[#list + 1] = d end
            end
        end
        if #list == 0 then list[1] = tab.decide end
        table.sort(list)
        tab._decides = list
    end
    return tab._decides
end
-- (what it strikes by that the mod draws on its own once there - not one drawn only with its move,
-- a laser laid along its beam: those go on being drawn with it)
local function OwnThings(tab)
    if tab._own == nil then
        tab._own = {}
        for _, p in ipairs(tab.things or {}) do
            local hz = SimMoves.Hazards()[p]
            if hz ~= nil and not hz.in_move then tab._own[#tab._own + 1] = p end
        end
    end
    return tab._own
end
local table_rows = setmetatable({}, { __mode = "k" })
local function Row(prefab, sim, name, tab, i, dec)
    local e = tab.entries[i]
    table_rows[e] = table_rows[e] or {}
    local r = table_rows[e][dec]
    if r == nil then
        -- (only its blows set by where its target was at frame dec)
        local steps = {}
        for _, s in ipairs(e.steps or {}) do
            if #Decides(tab) == 1 or DecideOf(tab, s.at) == dec then steps[#steps + 1] = s end
        end
        -- (struck only by what it sets off: never seen striking - gone once those are there; one
        -- piece, not its parts by when they'd be struck)
        r = { maps = { { dist = e.dist, steps = steps } }, random = tab.random, effects = sim.effects, anims = sim.anims,
            whole = #OwnThings(tab) > 0,
            -- (one only on whoever it's after: only when that's you - as before)
            single = sim.single,
            _key = prefab .. "|" .. name .. "|row" .. i .. "|" .. dec }
        table_rows[e][dec] = r
    end
    return r
end
-- (the middle of what a row strikes, seen from the boss as the move began)
local function Middle(tab, i)
    local e = tab.entries[i]
    local s = e.like ~= nil and tab.entries[e.like] or e
    local x, z = s.cx or 0, s.cz or 0
    if e.dx ~= nil then x, z = x + e.dx, z + e.dz end
    return x, z
end
-- (...and where it would be with its target at angle ang, d away: between the places run round
-- there - the two angles either side (round to the left), at each the two distances either side;
-- run finer where it changes fast, so not all angles have all distances. nil: not run round it)
-- (the places run are this far apart, at most - beyond the furthest, not known)
local TAB_DIST = 2
local function Eased(tab, ang, d, far_ok)
    local grid = tab._grid
    if grid == nil then
        grid = { angles = {} }
        for i, e in ipairs(tab.entries) do
            if grid[e.angle] == nil then grid[e.angle] = {} grid.angles[#grid.angles + 1] = e.angle end
            table.insert(grid[e.angle], { e.dist, i })
        end
        table.sort(grid.angles)
        for _, a in ipairs(grid.angles) do table.sort(grid[a], function(p, q) return p[1] < q[1] end) end
        tab._grid = grid
    end
    local list = grid.angles
    if #list == 0 then return nil end
    -- (the angles either side, round past 180)
    local a0, a1 = list[#list], list[1]
    for k = 1, #list do
        if list[k] <= ang then a0 = list[k] end
    end
    for k = #list, 1, -1 do
        if list[k] > ang then a1 = list[k] end
    end
    local span = (a1 - a0) % 360
    if span == 0 then span = 360 end
    local ka = ((ang - a0) % 360) / span
    -- (at one angle: between the distances either side - its middle as polar)
    local function At(a)
        local ds = grid[a]
        local lo, hi = ds[1], ds[#ds]
        -- (far_ok: further than the furthest run at that angle - as there)
        local d = (far_ok and d > ds[#ds][1]) and ds[#ds][1] or d
        for _, p in ipairs(ds) do
            if p[1] <= d then lo = p end
        end
        for k = #ds, 1, -1 do
            if ds[k][1] >= d then hi = ds[k] end
        end
        if d < ds[1][1] or d > ds[#ds][1] + TAB_DIST then return nil end
        local k = hi[1] > lo[1] and (d - lo[1]) / (hi[1] - lo[1]) or 0
        k = math.max(0, math.min(1, k))
        local x0, z0 = Middle(tab, lo[2])
        local x1, z1 = Middle(tab, hi[2])
        local x, z = x0 + (x1 - x0) * k, z0 + (z1 - z0) * k
        return math.atan2(-z, x) / DEGREES, math.sqrt(x * x + z * z)
    end
    local p0, r0 = At(a0)
    local p1, r1 = At(a1)
    if p0 == nil or p1 == nil then return nil end
    p1 = p0 + (p1 - p0 + 180) % 360 - 180
    return p0 + (p1 - p0) * ka, r0 + (r1 - r0) * ka
end
-- one part of a move with a table: its blows set by where its target was at frame dec (aim: that,
-- or where it is now, before then) - see DrawTable
local function DrawPart(ent, a, tab, t, aim, dec, my_radius, px, pz)
    local st = a.tab_st[dec]
    if st == nil then st = {} a.tab_st[dec] = st end
    -- (its target as seen from where it began, the way it faced then)
    local dx, dz = aim.x - a.x, aim.z - a.z
    local c, s = math.cos(a.rot), math.sin(a.rot)
    local ahead, side = dx * c - dz * s, dx * s + dz * c
    local d = math.sqrt(ahead * ahead + side * side)
    local ang = d > .01 and math.atan2(-side, ahead) / DEGREES or 0
    local best, best_off = nil, nil
    for i, e in ipairs(tab.entries) do
        local da = math.abs((ang - e.angle + 180) % 360 - 180)
        local off = da * 1000 + math.abs(d - e.dist)
        if best_off == nil or off < best_off then best, best_off = i, off end
    end
    local e = tab.entries[best]
    -- (a row struck just as another: that one's)
    local src_i = e.like or best
    local src = tab.entries[src_i]
    -- what its shape goes with: (a) its target - one moved on with it, or one others are (kind
    -- "target"): moved on to just where its target is; (b) the boss, the same whichever way its
    -- target is - like one at another angle, or one others are (kind "boss"): as it is; (c) else
    -- turned round where it began by as much as its target is off the row's, and moved on by as
    -- much as it's further (only within a row's step: further than any run, not known)
    local goes = (e.dx ~= nil and "target") or (e.like ~= nil and src.angle ~= e.angle and "boss") or src.kind
    -- (one striking at random that goes with its target - junk heaped where you are: the same
    -- heap all along, moved on with you - not another row's heap each time you cross into it, the
    -- heap changing shape and jumping a unit and more as you walked)
    -- (and goes with the same all along: a row far off told apart from the rest by chance alone -
    -- turned with the boss as it turned round holding its junk, the heap thrown 30 the other way)
    -- (what most of its rows go with: not the first row's - one by the boss told apart too)
    if tab.random then
        if tab._goes == nil then
            local n = {}
            for _, r in ipairs(tab.entries) do
                local rs = r.like ~= nil and tab.entries[r.like] or r
                local k = (r.dx ~= nil and "target") or (r.like ~= nil and rs.angle ~= r.angle and "boss") or rs.kind or "turned"
                n[k] = (n[k] or 0) + 1
            end
            local most = nil
            for k, c in pairs(n) do if most == nil or c > n[most] then most = k end end
            tab._goes = most
        end
        goes = tab._goes ~= "turned" and tab._goes or nil
    end
    if goes == "target" and tab.random then
        if st.src_i == nil then st.src_i = src_i end
        src_i, src = st.src_i, tab.entries[st.src_i]
    end
    local ox, oz, rot = a.x, a.z, a.rot
    if goes == "target" and src_i ~= (e.like or best) then
        -- (the one heap kept, its middle where the place's own heap has its middle - not moved on
        -- all the way with you: junk thrown at you 28 off comes down 21 off)
        -- (between the places run round where its target is - not jumping as it crosses from one
        -- row to the next)
        local bx, bz
        -- (further than the places run round there: as at the furthest that are - junk thrown at
        -- you 30 off coming down no further than at 28)
        local phi, rho = Eased(tab, ang, d, true)
        if phi ~= nil then
            bx, bz = rho * math.cos(phi * DEGREES), -rho * math.sin(phi * DEGREES)
        else
            local px0, pz0 = e.dist * math.cos(e.angle * DEGREES), -e.dist * math.sin(e.angle * DEGREES)
            bx, bz = Middle(tab, best)
            bx, bz = bx + (ahead - px0), bz + (side - pz0)
        end
        local sx, sz = Middle(tab, src_i)
        local mx, mz = bx - sx, bz - sz
        ox, oz = a.x + mx * c + mz * s, a.z - mx * s + mz * c
    elseif goes == "target" then
        local sx, sz = src.dist * math.cos(src.angle * DEGREES), -src.dist * math.sin(src.angle * DEGREES)
        local mx, mz = ahead - sx, side - sz
        ox, oz = a.x + mx * c + mz * s, a.z - mx * s + mz * c
    elseif goes ~= "boss" then
        -- (eased between the places run: the middle of what it strikes, as between the four round
        -- where its target is - the row's shape turned and moved on to have its middle there; not
        -- jumping as its target crosses from one row to the next - the boss turning only so far)
        local phi, rho = Eased(tab, ang, d)
        local mx, mz = Middle(tab, best)
        local rho_e = math.sqrt(mx * mx + mz * mz)
        if phi ~= nil and rho > .5 and rho_e > .5 then
            local phi_e = math.atan2(-mz, mx) / DEGREES
            rot = a.rot + ((phi - phi_e + 180) % 360 - 180) * DEGREES
            local way, on = a.rot + phi * DEGREES, rho - rho_e
            ox, oz = a.x + on * math.cos(way), a.z - on * math.sin(way)
        else
            rot = a.rot + ((ang - e.angle + 180) % 360 - 180) * DEGREES
            local way = a.rot + ang * DEGREES
            local on = d - e.dist
            if math.abs(on) > 1.01 then on = 0 end
            ox, oz = a.x + on * math.cos(way), a.z - on * math.sin(way)
        end
    end
    -- (laid round a thing by it, not round itself - its places run round itself: moved on by as much; Predict.RoundAt)
    do
        local g = a.move ~= nil and a.move.sim ~= nil and Predict.RoundAt(a, a.move.sim, a.x, a.z) or nil
        if g then ox, oz = ox + g.x - a.x, oz + g.z - a.z end
    end
    local cx, cz = math.cos(rot), math.sin(rot)
    -- (one it strikes with itself (tab.by_boss), or by what it sets off from where it is and the way
    -- it faces - not round its target (goes "target": a spell where you stand): the boss off where
    -- it was in the run by now - pushed, stopped short by you, lunging on further: the shape moved
    -- on by as much. Where it was: the nearest of the run's moments within TAB_SHIFT_FRAMES of now
    -- (a frame early or late is no shove); moved TAB_SHIFT_STEP a frame at most, not over
    -- TAB_SHIFT_MAX)
    -- (not a row struck as another moved on with its target (e.dx): the boss went that much further
    -- than in the other's run - the Vault Guard leaping at you 7 off, taken as off its way by 7 (the
    -- run it was like had you 1.5 off, the boss standing): the shape pulled back onto the boss)
    if (tab.by_boss or goes ~= "target") and src.path ~= nil and src.path ~= "" and e.dx == nil then
        local p = paths[src]
        if p == nil then
            p = {}
            for x, z, r in src.path:gmatch("([%-%d%.]+),([%-%d%.]+),?([%-%d%.]*)") do
                p[#p + 1] = { tonumber(x), tonumber(z), tonumber(r) }
            end
            paths[src] = p
        end
        local fi = math.floor(t / FRAMES + .5)
        local ex, _, ez = ent.Transform:GetWorldPosition()
        -- (and the way it really faces: turned only so far, or not at all, as its target ran round
        -- it - the run had it turning to where its target stood: the shape turned back by as much,
        -- round where the boss was then)
        -- (the nearest of the run's moments within TAB_SHIFT_FRAMES, as for where it is; turned
        -- TAB_TURN_STEP a frame at most - a turn a frame early or late is no turn)
        local q, want_turn = nil, nil
        local real = ent.Transform:GetRotation() * DEGREES
        for k = fi - TAB_SHIFT_FRAMES, fi + TAB_SHIFT_FRAMES do
            local qk = p[math.max(1, math.min(#p, k + 1))]
            if qk ~= nil and qk[3] ~= nil then
                local dk = ((real - (rot + qk[3] * DEGREES)) + math.pi) % (2 * math.pi) - math.pi
                if want_turn == nil or math.abs(dk) < math.abs(want_turn) then q, want_turn = qk, dk end
            end
        end
        if q ~= nil then
            -- (its first moment: as it is - nothing to ease from)
            local had = st.turn or want_turn
            local delta = had + math.max(-TAB_TURN_STEP, math.min(TAB_TURN_STEP, want_turn - had))
            st.turn = delta
            local bx, bz = ox + q[1] * cx + q[2] * cz, oz - q[1] * cz + q[2] * cx
            local vx, vz = ox - bx, oz - bz
            local dc, ds = math.cos(delta), math.sin(delta)
            ox, oz = bx + vx * dc + vz * ds, bz - vx * ds + vz * dc
            rot = rot + delta
            cx, cz = math.cos(rot), math.sin(rot)
        end
        local want, near = nil, nil
        for k = fi - TAB_SHIFT_FRAMES, fi + TAB_SHIFT_FRAMES do
            local q = p[math.max(1, math.min(#p, k + 1))]
            if q ~= nil then
                local wx, wz = ox + q[1] * cx + q[2] * cz, oz - q[1] * cz + q[2] * cx
                local d2 = (ex - wx) ^ 2 + (ez - wz) ^ 2
                if near == nil or d2 < near then near, want = d2, { ex - wx, ez - wz } end
            end
        end
        if want == nil or near > TAB_SHIFT_MAX * TAB_SHIFT_MAX then want = { 0, 0 } end
        local sh = st.shift or want
        local mx, mz = want[1] - sh[1], want[2] - sh[2]
        local md = math.sqrt(mx * mx + mz * mz)
        if md > TAB_SHIFT_STEP then mx, mz = mx * TAB_SHIFT_STEP / md, mz * TAB_SHIFT_STEP / md end
        st.shift = { sh[1] + mx, sh[2] + mz }
        ox, oz = ox + st.shift[1], oz + st.shift[2]
    end
    -- (testing: TR_TAB_DBG, set by the replays - what it drew from)
    if rawget(_G, "TR_TAB_DBG") then
        local mx, mz = Middle(tab, src_i)
        print(string.format("TABDBG t=%.3f dec=%d row=%d src=%d goes=%s ang=%.1f d=%.2f o=%.2f,%.2f rot=%.1f aim=%.2f,%.2f mid=%.2f,%.2f", t, dec, best, src_i, tostring(goes), ang, d, ox, oz, rot / DEGREES, aim.x, aim.z,
            ox + mx * cx + mz * cz, oz - mx * cz + mz * cx))
    end
    st.logs = st.logs or {}
    st.logs[src_i] = st.logs[src_i] or {}
    local row = Row(ent.prefab, a.move.sim, a.move.name, tab, src_i, dec)
    -- (its target as the row's is: just where the row was run for)
    local at = { x = ox + e.dist * math.cos(e.angle * DEGREES) * cx + (-e.dist * math.sin(e.angle * DEGREES)) * cz,
        z = oz - e.dist * math.cos(e.angle * DEGREES) * cz + (-e.dist * math.sin(e.angle * DEGREES)) * cx, me = aim.me }
    -- (its cells kept moved back by sx ahead, sz aside - further off than the file's map holds, junk
    -- 26 off to the side: drawn on by as much)
    if src.sx ~= nil then ox, oz = ox + src.sx * cx + src.sz * cz, oz - src.sx * cz + src.sz * cx end
    Note(ent, "table", a.move, t, dec, a.tab_aims[dec] ~= nil, best, src_i, goes or "the boss, turned", a.tab_from ~= nil)
    return SimMoves.Draw(row, ox, oz, rot, at, my_radius, px, pz, t, st.logs[src_i], ent, nil)
end

-- (where its code saw its target at frame f: what's seen here of you runs a frame on from what its
-- code sees - between the two moments seen either side)
local function SeenAt(h, f)
    local want = (f - 1) * FRAMES
    local seen = h[1]
    for i = #h, 1, -1 do
        if h[i].t <= want + .001 then
            seen = h[i]
            local n = h[i + 1]
            if n ~= nil and n.t > seen.t then
                local k = math.min(1, (want - seen.t) / (n.t - seen.t))
                seen = { x = seen.x + (n.x - seen.x) * k, z = seen.z + (n.z - seen.z) * k, me = seen.me }
            end
            break
        end
    end
    return seen
end
-- (one going with its target only so far after a frame (tab.follow - junk thrown, turning 45 degrees
-- at most after you): where it goes for its target at pos - its target then (a.tab_from), moved on
-- by as much as the runs had its middle go for its target moved off that much; the place run
-- round it, between the moves run round where its target went)
local function Followed(a, tab, pos)
    local p = a.tab_from
    local c, s = math.cos(a.rot), math.sin(a.rot)
    local function In(q) local dx, dz = q.x - a.x, q.z - a.z return dx * c - dz * s, dx * s + dz * c end
    local pa, ps = In(p)
    local qa, qs = In(pos)
    qa, qs = qa - pa, qs - ps
    local fo = tab.follow
    -- (between the two of a sorted list either side of v: their indexes, and how far on)
    local function Either(list, v)
        if v <= list[1] then return 1, 1, 0 end
        for k = 1, #list - 1 do
            if v <= list[k + 1] then return k, k + 1, (v - list[k]) / (list[k + 1] - list[k]) end
        end
        return #list, #list, 0
    end
    -- (the four round, weighted - those not run left out, the rest as much more)
    local function Four(get, i0, i1, ki, j0, j1, kj)
        local wsum, x, z = 0, 0, 0
        for _, c in ipairs({ { i0, j0, (1 - ki) * (1 - kj) }, { i1, j0, ki * (1 - kj) }, { i0, j1, (1 - ki) * kj }, { i1, j1, ki * kj } }) do
            local v = c[3] > 0 and get(c[1], c[2]) or nil
            if v ~= nil then wsum, x, z = wsum + c[3], x + v[1] * c[3], z + v[2] * c[3] end
        end
        if wsum <= 0 then return nil end
        return { x / wsum, z / wsum }
    end
    if fo._grid == nil then
        -- (places by angle and distance; at each, its moves by how far (radii, 0 first: none) and
        -- which way (turns round))
        local g = { angles = {}, dists = {}, at = {}, radii = { 0 } }
        for _, r in ipairs(fo.radii) do g.radii[#g.radii + 1] = r end
        local sa, sd = {}, {}
        for _, e in ipairs(fo.at) do
            if not sa[e.a] then sa[e.a] = true g.angles[#g.angles + 1] = e.a end
            if not sd[e.d] then sd[e.d] = true g.dists[#g.dists + 1] = e.d end
            -- (radius by radius from the first run (index 2: 0 is none), round each: "mx,mz;...", ""
            -- not known)
            local m, n = {}, 0
            for v in (e.s .. ";"):gmatch("([^;]*);") do
                local mx, mz = v:match("^([^,]+),(.+)$")
                if mx ~= nil then m[(2 + math.floor(n / fo.turns)) * 1000 + n % fo.turns] = { tonumber(mx), tonumber(mz) } end
                n = n + 1
            end
            g.at[e.a .. "|" .. e.d] = m
        end
        table.sort(g.angles)
        table.sort(g.dists)
        fo._grid = g
    end
    local g = fo._grid
    -- (at one place run: between the moves run there round where its target went)
    local qr = math.sqrt(qa * qa + qs * qs)
    local qt = (math.atan2(-qs, qa) / (2 * math.pi) * fo.turns) % fo.turns
    local r0, r1, kr = Either(g.radii, qr)
    local t0 = math.floor(qt)
    local t1, kt = (t0 + 1) % fo.turns, qt - t0
    local function At(key)
        local m = g.at[key]
        if m == nil then return nil end
        local v = Four(function(ri, ki)
            if ri == 1 then return { 0, 0 } end
            return m[ri * 1000 + ki]
        end, r0, r1, kr, t0, t1, kt)
        -- (none of the four run - off the map the runs kept: the nearest move run there - not
        -- gone all the way with its target, junk thrown at you 26 off)
        if v == nil then
            local off = nil
            for k, mv in pairs(m) do
                local ri, ki = math.floor(k / 1000), k % 1000
                local qq, qk = g.radii[ri], ki * 2 * math.pi / fo.turns
                local o = (qq * math.cos(qk) - qa) ^ 2 + (-qq * math.sin(qk) - qs) ^ 2
                if off == nil or o < off then off, v = o, mv end
            end
        end
        return v
    end
    -- (between the places run round where its target was then: angles either side, round past 180)
    local pd = math.sqrt(pa * pa + ps * ps)
    local pang = math.atan2(-ps, pa) / DEGREES
    local list = g.angles
    local a0, a1 = list[#list], list[1]
    for k = 1, #list do if list[k] <= pang then a0 = list[k] end end
    for k = #list, 1, -1 do if list[k] > pang then a1 = list[k] end end
    local span = (a1 - a0) % 360
    if span == 0 then span = 360 end
    local ka = ((pang - a0) % 360) / span
    local d0, d1, kd = Either(g.dists, pd)
    local v = Four(function(a, di) return At(a .. "|" .. g.dists[di]) end, a0, a1, ka, d0, d1, kd)
    if v == nil then return pos end
    local mx, mz = pa + v[1], ps + v[2]
    return { x = a.x + mx * c + mz * s, z = a.z - mx * s + mz * c, me = pos.me }
end
-- (sim.round: laid round the nearest thing of that name, not round itself, when there's one by - the Ancient
-- Fuelweaver's spike spiral, round its atrium gate (stalker.lua GenerateSpiralSpikes: entitytracker "stargate",
-- or itself): it fights up to 14.55 off it, the spiral drawn round it came up 2 off on the testbench, 2026-10-26.
-- Found once a go (a.round_at; false: none by). { x, z } or nil. TR_OLD_ROUND: round itself)
function Predict.RoundAt(a, sim, x, z)
    if sim == nil or sim.round == nil or rawget(_G, "TR_OLD_ROUND") then return nil end
    if a.round_at == nil then
        a.round_at = false
        local reach = sim.round_within or 20
        local near = Predict.ThingsNear ~= nil and Predict.ThingsNear(x, z, reach)
            or (TheSim ~= nil and TheSim:FindEntities(x, 0, z, reach)) or {}
        local best_d2 = nil
        for _, o in ipairs(near) do
            if o.prefab == sim.round then
                local gx, gy, gz
                if o.cur ~= nil then gx, gz = o.cur.x, o.cur.z else gx, gy, gz = o.Transform:GetWorldPosition() end
                local d2 = (gx - x) ^ 2 + (gz - z) ^ 2
                if best_d2 == nil or d2 < best_d2 then best_d2, a.round_at = d2, { x = gx, z = gz } end
            end
        end
    end
    return a.round_at or nil
end
-- (one that goes for every player in reach at once (sim.multi, how far) - the Klaus deer's
-- spells: each other player but the one it's after, within that of it - fn(player, { x, z }))
function Predict.EachOther(ent, sim, target, fn)
    local players = sim ~= nil and sim.multi ~= nil and rawget(_G, "AllPlayers") or nil
    if players == nil then return end
    local x, _, z = ent.Transform:GetWorldPosition()
    for _, p in ipairs(players) do
        if p:IsValid() and p.Transform ~= nil then
            local qx, _, qz = p.Transform:GetWorldPosition()
            local is_target = target ~= nil and (qx - target.x) ^ 2 + (qz - target.z) ^ 2 < .01
            if not is_target and (qx - x) ^ 2 + (qz - z) ^ 2 <= sim.multi * sim.multi then
                fn(p, { x = qx, z = qz })
            end
        end
    end
end

-- (where one that goes at you only if you're near the way it faces goes, you where you are now: you, or straight on so far -
-- sim.ahead_if_off / ahead_dist; as it winds up too, not only as it decides: the Ancient Guard Tower's leap drawn round you
-- as you ran round behind it, then thrown out ahead as it decided - "it aims after me, then leaps the other way", the
-- player 2026-10-22. TR_OLD_AHEADOFF)
local function AheadIfOff(ent, sim, target)
    if target == nil or sim == nil or sim.ahead_if_off == nil or rawget(_G, "TR_OLD_AHEADOFF") then return target end
    local bx, _, bz = ent.Transform:GetWorldPosition()
    local r = ent.Transform:GetRotation() * DEGREES
    local off = math.abs(((math.atan2(-(target.z - bz), target.x - bx) - r) + math.pi) % (2 * math.pi) - math.pi)
    if off <= sim.ahead_if_off * DEGREES then return target end
    local d = sim.ahead_dist or 4
    return { t = target.t, x = bx + d * math.cos(r), z = bz - d * math.sin(r), me = false }
end
local function DrawTable(ent, a, tab, t, target, my_radius, px, pz)
    -- (thrown with no target - Track's a.untargeted: not where you are)
    if a.untargeted then
        Note(ent, "no target as it threw: not drawn on you (what it throws is, as it comes)", a.move, t)
        return false
    end
    a.tab_hist = a.tab_hist or {}
    a.tab_aims = a.tab_aims or {}
    a.tab_st = a.tab_st or {}
    local h = a.tab_hist
    if target ~= nil and (#h == 0 or h[#h].t < t) then
        h[#h + 1] = { t = t, x = target.x, z = target.z, me = target.me }
        if #h > 90 then table.remove(h, 1) end
    end
    local follow = tab.follow ~= nil and #Decides(tab) == 1
    if follow and a.tab_from == nil and t >= tab.follow.from * FRAMES - .001 and #h > 0 then
        a.tab_from = SeenAt(h, tab.follow.from)
    end
    follow = follow and a.tab_from ~= nil
    for _, dec in ipairs(Decides(tab)) do
        if a.tab_aims[dec] == nil and t >= dec * FRAMES - .001 and #h > 0 then
            a.tab_aims[dec] = SeenAt(h, dec)
            if follow then a.tab_aims[dec] = Followed(a, tab, a.tab_aims[dec]) end
            -- (you further round from the way it faces than it turns to as it decides: straight on, so far - sim.ahead_if_off,
            -- as the lock way above; the Ancient Guard Tower's leap is drawn this way, by its table. TR_OLD_AHEADOFF)
            a.tab_aims[dec] = AheadIfOff(ent, a.move ~= nil and a.move.sim or nil, a.tab_aims[dec])
        end
    end
    if follow and target ~= nil then target = Followed(a, tab, target) end
    local own = OwnThings(tab)
    if #own > 0 and Predict.made_hazards ~= nil then
        for thing, made in pairs(Predict.made_hazards) do
            -- (made by this go of it: not before it makes them (tab.made) - the lance of the throw
            -- before, coming down after this one began, isn't this one's)
            local from = a.t0 + math.max(0, (tab.made or 0) - MADE_LATE) * FRAMES
            if thing:IsValid() and (type(made) ~= "number" or made >= from) then
                for _, p in ipairs(own) do
                    if thing.prefab == p then return false end
                end
            end
        end
        -- (and well past when the first of them is made (tab.made), none made: none coming - the
        -- War Machine's beam only for one within 18 of it, its signal at times only calling drones;
        -- known so only for things the mod is told of as they're made)
        local told = #own == #tab.things
        -- (TR_UNTOLD: nothing is told of what's made - a replay of an offline run: not known)
        if told and not rawget(_G, "TR_UNTOLD") and tab.made ~= nil and t > (tab.made + MADE_LATE) * FRAMES then return false end
    end
    local any = false
    for _, dec in ipairs(Decides(tab)) do
        local aim = a.tab_aims[dec] or AheadIfOff(ent, a.move ~= nil and a.move.sim or nil, target)
        if aim ~= nil then any = DrawPart(ent, a, tab, t, aim, dec, my_radius, px, pz) or any end
    end
    return any
end

-- Every frame (between Lines.Begin and Lines.End): ents - monsters near you; ranges(ent) ->
-- what the server said about one; skip(prefab) -> true for the ones with hand-made shapes.
-- Returns true if you stand where a coming hit will land.
-- (where a SimMoves._land part strikes from: whom it's after (ld.on_target - the optic blast teleports onto them, SGshrouden
-- optic_blast_appear), the thing itself once made (ld.at_thing - the beam, chasing you), on where it is by now as a thing
-- moving (9-12 a second, shown a tenth behind: 11 blows struck just past it, lag_beam1 2026-10-28); else round the boss.
-- TR_OLD_LANDAT: round the boss)
local function LandSpot(ent, ld, x, z, target, now)
    if rawget(_G, "TR_OLD_LANDAT") then return x, z end
    local dx, dz = x, z
    if ld.on_target and target ~= nil then dx, dz = target.x, target.z end
    if ld.at_thing ~= nil then
        local near = Predict.EntsNear ~= nil and Predict.EntsNear(x, z, 30)
            or (TheSim ~= nil and TheSim:FindEntities(x, 0, z, 30)) or {}
        local best, bd = nil, 1e9
        -- (not one first seen under 2 frames ago - its first word in a player's game not yet where it's put: the beam's first
        -- frame 4 off, drawn there and back (frame_check POP, lag 0836). TR_OLD_THINGNEW: at once)
        -- (by its GUID - what stands for it may be made anew each frame)
        Predict._thing_seen = Predict._thing_seen or {}
        for _, o in ipairs(near) do
            local id = o.prefab == ld.at_thing and (o.GUID or o.guid) or nil
            if id ~= nil and Predict._thing_seen[id] == nil then Predict._thing_seen[id] = now end
            if o.prefab == ld.at_thing and o.Transform ~= nil
                and (id == nil or now - Predict._thing_seen[id] >= 1.5 * FRAMES or rawget(_G, "TR_OLD_THINGNEW")) then
                local ox, _, oz = o.Transform:GetWorldPosition()
                local d = (ox - x) ^ 2 + (oz - z) ^ 2
                if d < bd then best, bd = o, d end
            end
        end
        if best ~= nil then
            local ox, _, oz = best.Transform:GetWorldPosition()
            -- (its lead at once, not eased in - it chases you on steady: eased, 5 blows struck just past it, lag_ease1)
            dx, dz = SimMoves._LeadMovingRaw(best, ox, oz, now, true)
        end
        return dx, dz, best
    end
    return dx, dz
end
function Predict.Draw(ents, ranges, my_radius, me, skip)
    -- (the world's clock: it stops with the game paused, as the bosses do)
    local now = (GetTime or GetStaticTime)()
    local danger = false
    -- (any left waiting to be drawn as one - an error between: none held back for good)
    SimMoves.MergeEnd()
    -- (a new frame of shapes - an outline not laid inside another's: SimMoves._rg)
    SimMoves.RegionsBegin()
    local px, pz = me ~= nil and me.x or nil, me ~= nil and me.z or nil
    n_notes = 0
    for _, ent in ipairs(ents) do
        -- (whose shapes these are, for the replay's record - SimMoves._record, each part its owner's: a pack's 8 guards'
        -- shapes taken for one, its checks counting one ending as another began as glitches, 2026-10-20)
        SimMoves._draw_owner = ent
        local moves = ent:IsValid() and ent.AnimState ~= nil and not skip(ent.prefab) and MovesOf(ent.prefab) or nil
        local r = moves ~= nil and ranges(ent) or nil
        -- (one run offline: not waiting on the server's word about it - a boss charging in from
        -- far off, asked about only once near, was drawn only partway through its charge)
        if r == nil and moves ~= nil and SimMoves.Has(ent.prefab) then r = NO_WORD end
        -- (one run offline: harmful whatever the server took it for - the Prime Mate, no damage of its
        -- own and its cutlass not in hand as it was asked: never drawn)
        if r ~= nil and (r.harmful or SimMoves.Has(ent.prefab)) then
            local learned_all = Predict.learned[ent.prefab]
            -- (one that goes on the way it was walking, not at whom it turned to (SimMoves._keeps_heading - the Eye of
            -- Terror's charge from walking): where it was going while in no move, a frame back - walking or not)
            local kh = SimMoves._keeps_heading[ent.prefab]
            if kh ~= nil and active[ent] == nil and not rawget(_G, "TR_OLD_KEEPHEADING") then
                local hx, _, hz = ent.Transform:GetWorldPosition()
                local w = walk_heading[ent]
                -- (walking: 1 to 10 a second - not set down somewhere at a stroke, the testbench putting it in place)
                local d2 = w ~= nil and now > w.t and ((hx - w.x) ^ 2 + (hz - w.z) ^ 2) / (now - w.t) ^ 2 or 0
                local moving = d2 > 1 and d2 < 100
                walk_heading[ent] = { x = hx, z = hz, t = now, rot = ent.Transform:GetRotation(), moving = moving }
            end
            local a = Track(ent, moves, now, learned_all)
            -- (its SimMoves._land parts' going wide seen every frame - played outside the move's own animations, the
            -- Umbral Abomination's optic_blast_pre3: never drawn, never seen)
            if SimMoves._land[ent.prefab] ~= nil then
                for _, list in pairs(SimMoves._land[ent.prefab]) do
                    local ld = Predict._LandNow(ent, a, list)
                    -- (its beam still out with the move it came with taken as over - drawn all the same, round the beam: the
                    -- optic blast "over" at 3.87 s, its beam chasing on, a blow struck undrawn, lag_beam3 2026-10-28. TR_OLD_LANDLOOSE)
                    if ld ~= nil and ld.at_thing ~= nil and a == nil and not rawget(_G, "TR_OLD_LANDLOOSE") then
                        local bx, _, bz = ent.Transform:GetWorldPosition()
                        local dx, dz = LandSpot(ent, ld, bx, bz, nil, now)
                        if dx ~= bx or dz ~= bz then
                            local lw = Predict._land_wide[ent]
                            local r = (ld.wide_anim ~= nil and lw ~= nil and now - lw < 4) and ld.wide_r or ld.r
                            danger = SimMoves.DrawDisc(dx, dz, r, 0, px, pz) or danger
                            require("true_range/telegraph").Circle(dx, dz, r, "edge")
                        end
                    end
                end
            end
            -- (one charge, not its mouth's charges one after another (sim.leg) - each of those aimed anew; nor the shot begun
            -- alike (sim.tell, Uncompromising Mode's): it keeps turning to you as it shoots - the Twins' laser drawn the way it
            -- had walked, 1 -> 6 undrawn on the lag bench 2026-10-27_1128)
            if kh ~= nil and a ~= nil and a.heading == nil and a.move.anims[1] == kh and (a.move.sim == nil or (a.move.sim.leg == nil and a.move.sim.tell == nil))
                and not rawget(_G, "TR_OLD_KEEPHEADING") then
                local w = walk_heading[ent]
                a.heading = (w ~= nil and w.moving and now - w.t < .2) and w.rot or false
            end
            -- (one that turns to you only so far round - sim.cone, Frostjaw's 45 degrees: you stepping
            -- out of that, it lets you go, keeping where you were as you did - its dive goes that far
            -- along; not taken up again until it comes at you anew)
            local cone, cone_lead = ConeOf(moves)
            if cone ~= nil and me ~= nil and me.ent ~= nil and me.ent:IsValid() then
                local ct = cones[ent]
                if ct == nil then ct = {} cones[ent] = ct end
                local bx, _, bz = ent.Transform:GetWorldPosition()
                local mx, _, mz = me.ent.Transform:GetWorldPosition()
                local off = math.abs(((math.atan2(-(mz - bz), mx - bx) - ent.Transform:GetRotation() * DEGREES) + math.pi) % (2 * math.pi) - math.pi)
                -- (each moment: whether you were in it, and where it keeps you if not - where you'll be a
                -- moment on, by how fast you go, as it aims)
                local vx, vz = 0, 0
                if me.ent.Physics ~= nil then
                    local ux, _, uz = me.ent.Physics:GetVelocity()
                    vx, vz = ux or 0, uz or 0
                end
                local h = ct.h
                if h == nil then h = {} ct.h = h end
                if #h == 0 or h[#h].t < now then
                    h[#h + 1] = { t = now, inside = off < cone * DEGREES, x = mx + vx * cone_lead, z = mz + vz * cone_lead }
                    if #h > 150 then table.remove(h, 1) end
                end
            end
            -- (whom it's after, as said - kept a moment, for when it isn't: below)
            do
                local c = ent.replica ~= nil and ent.replica.combat or nil
                local p = c ~= nil and c:GetTarget() or nil
                if p ~= nil and p:IsValid() then last_target[ent] = { p = p, t = now } end
            end
            -- (also while it's at another move: a cooldown runs out whatever it's doing)
            Flash(ent, moves, r, a)
            if a ~= nil then
                -- (its animation runs a frame ahead of its stategraph: traced in the game, a move's
                -- animation time is one frame on from its time in state - and its code goes by that)
                local t = math.max(0, now - a.t0 - ANIM_LEAD)
                local key = a.move.anims[1]
                local learned = learned_all ~= nil and learned_all[key] or nil
                -- the next damage frame still to come (none known, or a charge - it hits all
                -- along the way: the whole move counts)
                local charge = learned ~= nil and learned.travel >= MIN_TRAVEL and not learned.leap
                local hit_at, any = nil, #a.move.frames == 0 or charge
                for _, f in ipairs(charge and {} or a.move.frames) do
                    if f * FRAMES + LINGER >= t then
                        hit_at = f * FRAMES
                        any = true
                        break
                    end
                end
                local x, _, z = ent.Transform:GetWorldPosition()
                -- (a player's game: it shown a moment behind where it is - striking as it runs, its blow drawn that far back: the
                -- Eye of Terror's mini eyes and Oculets biting at 4 a second, 2.1 off and undrawn, as a player's game would see it
                -- (tests/replay.lua CLIENT), 2026-10-27. On by how fast it goes, as a thing moving (SimMoves.LeadMoving - the host's
                -- game: none). TR_OLD_BODYLEAD)
                -- (nor its move's first frames, one that begins standing (its run's first frames still) - it has just stopped to
                -- wind up, the trip to us still saying it runs: drawn 1.3-2.5 on for a frame and back, the Ancient Guardian's
                -- every quick leap (frame_check AIM, lag 0646, 21 of them). TR_OLD_STARTLEAD: led on)
                -- (all the while it stands, not 3 frames only: led on again at its 4th, 1.2-2.2 on - frame_check, lag 0836)
                local start_still = a.move.sim ~= nil and now - (a.t0 or now) < Predict._StillFrames(a.move.sim) * FRAMES
                    and not rawget(_G, "TR_OLD_STARTLEAD")
                -- (nor one that only shoots (sim.shoots): its lane from it as it's shown - Uncompromising Mode's bee shooters fly
                -- round their queen sideways as they aim, the lead's "furthest on" held then caught up: the lane 1.4 back and on
                -- again, 7 a minute (frame_check JUMP, lag 0801). TR_OLD_SHOTRAW: led on)
                local shot_raw = a.move.sim ~= nil and a.move.sim.shoots ~= nil and not rawget(_G, "TR_OLD_SHOTRAW")
                if not rawget(_G, "TR_OLD_BODYLEAD") and not start_still and not shot_raw then
                    local lx, lz = SimMoves.LeadMoving(ent, x, z, now)
                    -- (one whose move, run offline, stays where it began - coming to a stop, sliding on what it had: led on, but
                    -- never back - Moonmaw's lavae gliding 10 -> 0 a second into their stab, drawn 1 on past them and back as they
                    -- slowed, 10 a run (tools/lag_jumps.ps1, lag 2026-10-28_1849); not led at all, 2 -> 12 stabs undrawn (1856) -
                    -- they stab where they stop, on past where your game shows them. The furthest on it has been drawn, this go.
                    -- TR_OLD_STAYLEAD: led on and back, as before)
                    if a.move.sim ~= nil and not rawget(_G, "TR_OLD_STAYLEAD") and SimMoves._StaysPut(a.move.sim) then
                        local r0 = ent.Transform:GetRotation() * DEGREES
                        if a.stay_x == nil or (lx - a.stay_x) * math.cos(r0) - (lz - a.stay_z) * math.sin(r0) > 0 then
                            a.stay_x, a.stay_z = lx, lz
                        end
                        lx, lz = a.stay_x, a.stay_z
                    end
                    x, z = lx, lz
                end
                local rot = ent.Transform:GetRotation() * DEGREES
                if a.heading and (a.move.sim == nil or a.move.sim.tell == nil) then rot = a.heading * DEGREES end
                -- (who it's after: a leap at its target lands on them)
                local combat = ent.replica ~= nil and ent.replica.combat or nil
                local tgt = combat ~= nil and combat:GetTarget() or nil
                -- (and whom it's after as the game says, nothing put in for it - a slide drawn only at that one)
                local said_tgt = tgt
                -- (whom the move itself goes at, as the server says with its poses - not whom it's
                -- after now: a friend's blow turns Klaus to them mid-bite, the bite goes on at you)
                -- (once told, kept for the move: not back to whom it's after now for a frame, as the
                -- server's word comes a moment late - the shape flicking between two players)
                local aim = SimMoves.PoseAim(ent)
                if aim ~= nil then
                    a.aim_ent = aim
                elseif a.aim_ent ~= nil and a.aim_ent:IsValid() then
                    aim = a.aim_ent
                end
                tgt = aim or tgt
                local target = nil
                -- (whom it's after not said for a moment - the first frame of a move, or as the
                -- server's word changes: whom it was after a moment ago - not none, its shape drawn
                -- for a target at its feet, flashing back onto it)
                if tgt ~= nil and tgt:IsValid() then
                    last_target[ent] = { p = tgt, t = now }
                elseif last_target[ent] ~= nil and now - last_target[ent].t < TARGET_KEEP and last_target[ent].p:IsValid()
                    and not last_target[ent].p:HasTag("playerghost") then
                    tgt = last_target[ent].p
                end
                -- (whom it's after not said - it happens, mid-move, though it keeps turning after
                -- you: the nearest player it faces, within 45 degrees and 16 - as its aim goes)
                if (tgt == nil or not tgt:IsValid()) and a.move.sim ~= nil and AllPlayers ~= nil then
                    local best_d = 16 * 16
                    for _, p in ipairs(AllPlayers) do
                        if p:IsValid() and not (p:HasTag("playerghost") or p:HasTag("corpse")) then
                            local qx, _, qz = p.Transform:GetWorldPosition()
                            local dx, dz = qx - x, qz - z
                            local d = dx * dx + dz * dz
                            local off = math.abs(((math.atan2(-dz, dx) - rot) + math.pi) % (2 * math.pi) - math.pi)
                            -- (one that turns to its target as it begins: any way round - its first
                            -- frame, still facing away, drawn behind it)
                            -- (tried 2026-10-27: not one over 90 round - the Celestial Champion's stab then went undrawn at
                            -- 10-16 off, 1 -> 7 on the lag bench; the Eye's flip was its walk, not this: SimMoves._keeps_heading)
                            if d < best_d and (off < 45 * DEGREES or a.move.sim.frame == "target") then
                                best_d, tgt = d, p
                            end
                        end
                    end
                end
                if tgt ~= nil and tgt:IsValid() then
                    local tx, _, tz = tgt.Transform:GetWorldPosition()
                    -- (you: where you were given - in a player's game, where the server has you, not shown on ahead
                    -- (modmain's lead); the host's own the same)
                    local mine = me ~= nil and me.ent ~= nil and tgt == me.ent
                    if mine and me.x ~= nil and me.z ~= nil then tx, tz = me.x, me.z end
                    target = { x = tx, z = tz, me = mine }
                end
                -- (one that turns to its target only so far as it sets off, then goes the way it faces (sim.aim_facing) -
                -- the Shadow Thrall horns as the Umbral Abomination calls them up (SGshadowthrall_horns shrouden_jump, frame
                -- 0: at most 45 round to you, none if you're over 90 round, then on 3.5-9 by how far ahead you are, 6-8 if it
                -- didn't turn). Called up facing every way, three leapt away from you, drawn at you: 9 of 10 "drawn IN but
                -- NOT struck". Its turn is done before your game sees it begin - the way it faces then is its way: where you
                -- are along that, set on as its own code reads you (af.lead), as far as it goes. TR_OLD_AIMFACING: at you)
                local af = a.move.sim ~= nil and a.move.sim.aim_facing or nil
                if af ~= nil and target ~= nil and a.rot_begin ~= nil and not rawget(_G, "TR_OLD_AIMFACING") then
                    local c, s = math.cos(a.rot_begin), math.sin(a.rot_begin)
                    local dx, dz = target.x - a.x, target.z - a.z
                    if target.me and af.lead ~= nil and me ~= nil and me.ent ~= nil and me.ent.Physics ~= nil then
                        local vx, _, vz = me.ent.Physics:GetVelocity()
                        dx, dz = dx + (vx or 0) * af.lead, dz + (vz or 0) * af.lead
                    end
                    local len = math.sqrt(dx * dx + dz * dz)
                    local along = dx * c - dz * s
                    if len < .01 or along < len * math.cos((af.turn + 1) * DEGREES) then
                        along = af.free
                    else
                        along = math.max(af.min, math.min(af.max, along))
                    end
                    -- (and only as far on as the ground lets it: half a unit at a time from 1, its body's width added, stopped
                    -- short where it can't stand - three on the bench by the shore leapt 1, the stand-in 1.44 behind struck)
                    local map = TheWorld ~= nil and TheWorld.Map or nil
                    if map ~= nil and map.IsPassableAtPoint ~= nil then
                        local pr = ent.GetPhysicsRadius ~= nil and ent:GetPhysicsRadius(0) or 0
                        local want = along + pr
                        local d = math.min(1, want)
                        while d < want do
                            local ok, pass = pcall(map.IsPassableAtPoint, map, a.x + c * d, 0, a.z - s * d)
                            if ok and pass == false then break end
                            d = math.min(want, d + .5)
                        end
                        along = math.max(1, d - pr)
                    end
                    target = { x = a.x + c * along, z = a.z - s * along, me = target.me }
                end
                -- (a wind-up that only leads into a charge has no shape of its own)
                local own = not (learned ~= nil and #a.move.frames == 0 and learned.travel < MIN_TRAVEL and learned.width <= 0)
                local sim = a.move.sim
                local finish = sim ~= nil and sim.leg ~= nil and sim.leg.finish or nil
                -- (the Scion's supernova in its arena, barrier up: the whole arena, 40 round its middle -
                -- run offline with no arena, 24 round itself: drawn smaller than it struck)
                local arena = nil
                if sim ~= nil and sim.cooldown == "supernova_cd" and TheWorld ~= nil and TheWorld.Map ~= nil
                    and TheWorld.Map.IsPointInWagPunkArenaAndBarrierIsUp ~= nil then
                    local ok, inside = pcall(TheWorld.Map.IsPointInWagPunkArenaAndBarrierIsUp, TheWorld.Map, x, 0, z)
                    if ok and inside then
                        local ok2, cx, cz = pcall(TheWorld.Map.GetWagPunkArenaCenterXZ, TheWorld.Map)
                        if ok2 and cx ~= nil and cz ~= nil then arena = { cx, cz, 40 } end
                    end
                end
                -- (out of its arena: 24 round itself (WagBossUtil.SupernovaNoArenaRange) - run offline, its
                -- shape cut flat where the runs' grid ends (20 out), a square with round corners)
                if arena == nil and sim ~= nil and sim.cooldown == "supernova_cd" then arena = { x, z, 24 } end
                -- (not yet told which of two begun alike it is (a.tell_wait, its first 4 frames): nothing drawn by
                -- any way of drawing - the Eye's charge has legs, drawn by its own branch, its lane shown a frame
                -- before the pulse said shot; only the plain branch waited. The player's report 2026-10-19.
                -- TR_OLD_TELLWAITALL: the plain branch only, as before)
                local waiting_tell = a.tell_wait ~= nil and now <= a.tell_wait and not rawget(_G, "TR_OLD_TELLWAITALL")
                -- (counted for the replays, by every branch: drawn as one move, then taken for another in the same
                -- go - the wrong one flashed first; TR_FLIP. Once only the plain branch counted: the legs' flash unseen)
                if not waiting_tell then
                    local flip = rawget(_G, "TR_FLIP")
                    if flip ~= nil and a.drawn_any ~= nil and a.drawn_any ~= a.move then
                        local k = string.format("%s %s>%s@%d", ent.prefab or "?", a.drawn_any.name or "?", a.move.name or "?", math.floor((now - a.t0) / FRAMES + .5))
                        flip[k] = (flip[k] or 0) + 1
                    end
                    a.drawn_any = a.move
                end
                if waiting_tell then
                    Note(ent, "not yet told which (tell_wait)", a.move, t)
                elseif arena ~= nil then
                    Note(ent, "the whole arena (supernova)", a.move, t)
                    local inside, style = SimMoves.DrawDisc(arena[1], arena[2], arena[3], (sim.first or 0) * FRAMES - t, px, pz)
                    require("true_range/telegraph").Circle(arena[1], arena[2], arena[3], style == "hit" and "edge_zone" or "edge")
                    danger = inside or danger
                elseif finish ~= nil and ent.AnimState:IsCurrentAnimation(finish.anim) then
                    -- run offline: how its legs end (a slide, a slam), from where that began, until done
                    if a.finish == nil then
                        a.finish = { x = x, z = z, rot = rot, t = now }
                    end
                    if now - a.finish.t <= (finish.last or 0) * FRAMES + LINGER then
                        Note(ent, "how its legs end", a.move, now - a.finish.t)
                        -- (stopped short of how far on it goes by now (finish.path) - the Celestial
                        -- Champion's roll ending against you: it strikes where it got to - drawn back
                        -- by as far as it's behind; never on ahead of it)
                        local fx, fz, frot = a.finish.x, a.finish.z, a.finish.rot
                        local behind = 0
                        if finish.path ~= nil then
                            if finish.steps == nil then
                                finish.steps = {}
                                for n in finish.path:gmatch("[^,]+") do finish.steps[#finish.steps + 1] = tonumber(n) end
                            end
                            local k = math.floor((now - a.finish.t) / FRAMES + .5)
                            local want = k >= 1 and (finish.steps[math.min(k, #finish.steps)] or 0) or 0
                            local got = (x - fx) * math.cos(frot) - (z - fz) * math.sin(frot)
                            behind = math.max(a.finish.behind or 0, want - got)
                            if behind < FINISH_BEHIND then behind = a.finish.behind or 0 end
                            a.finish.behind = behind
                        end
                        danger = SimMoves.DrawCells(finish, fx - behind * math.cos(frot), fz + behind * math.sin(frot), frot, px, pz) or danger
                    end
                elseif sim ~= nil and TableOf(ent.prefab, a.move) ~= nil then
                    -- (its first animation begun over - a plant biting again and again, the one
                    -- animation going round: a new go of it, from where it is now)
                    local at0 = ent.AnimState:IsCurrentAnimation(a.move.anims[1]) and ent.AnimState:GetCurrentAnimationTime() or nil
                    -- (only once all of the go before has struck: an animation going round in the
                    -- middle of one - a charge's loop - is the same go)
                    local tab0 = TableOf(ent.prefab, a.move)
                    if at0 ~= nil and a.tab_anim_t ~= nil and at0 < a.tab_anim_t - .05 and t > (tab0.last or 0) * FRAMES then
                        a.t0, a.x, a.z, a.rot = now - at0, x, z, rot
                        a.tab_hist, a.tab_aims, a.tab_st, a.alt_a, a.tab_from = nil, nil, nil, nil, nil
                        t = math.max(0, now - a.t0 - ANIM_LEAD)
                    end
                    a.tab_anim_t = at0
                    danger = DrawTable(ent, a, TableOf(ent.prefab, a.move), t, target, my_radius, px, pz) or danger
                    -- (and under every other player it goes for too - each its own aim, kept apart)
                    Predict.EachOther(ent, a.move.sim, target, function(p, q)
                        a.multi_subs = a.multi_subs or {}
                        -- (its own aims, its own history - the rest as the move's)
                        a.multi_subs[p] = a.multi_subs[p] or setmetatable({ tab_hist = {}, tab_aims = {}, tab_st = {} }, { __index = a })
                        danger = DrawTable(ent, a.multi_subs[p], TableOf(ent.prefab, a.move), t, q, my_radius, px, pz) or danger
                    end)
                    -- (not yet told from the one begun alike that stays put - the shark's bite and its
                    -- bites one after another: that too, from the same start - as before)
                    if a.alt and a.alt.sim ~= nil then
                        local atab = TableOf(ent.prefab, a.alt)
                        if atab ~= nil then
                            a.alt_a = a.alt_a or { x = a.x, z = a.z, rot = a.rot, t0 = a.t0, move = a.alt }
                            -- (counted too: two shapes at once by the table way - uncounted till now, the reviewer's note)
                            local both = rawget(_G, "TR_BOTH") if both ~= nil then local k = (ent.prefab or "?") .. (a.alt_always and " (always)" or "") .. " (table)" both[k] = (both[k] or 0) + 1 end
                            SimMoves.maybe = true
                            danger = DrawTable(ent, a.alt_a, atab, t, target, my_radius, px, pz) or danger
                            SimMoves.maybe = nil
                        else
                            local arot = rot
                            if target ~= nil and ((target.x - x) ^ 2 + (target.z - z) ^ 2) > .01 then
                                arot = math.atan2(-(target.z - z), target.x - x)
                            end
                            -- (aimed only till its own lock (or till all it strikes by is down) - as below; TR_OLD_ALTLOCK)
                            local alock = a.alt.sim.lock
                            if alock == nil and a.alt.sim.set_until ~= nil then alock = math.min(a.alt.sim.first or a.alt.sim.set_until, a.alt.sim.set_until + 1) end
                            if alock ~= nil and t >= alock * FRAMES and not rawget(_G, "TR_OLD_ALTLOCK") then
                                if a.alt_rot == nil or a.alt_rot_for ~= a.alt then a.alt_rot, a.alt_rot_for = arot, a.alt end
                                arot = a.alt_rot
                            end
                            a.alt_log = a.alt_log or {}
                            Note(ent, "the one begun alike, too (offline map)", a.alt, t)
                        -- (counted for the replays: two shapes of one boss drawn at once - the Twins' charge with their shot, a player's report; TR_BOTH)
                        -- (not one that draws nothing - the Eye's shot (moves_hand_um, maps {}): 128 frames counted, none drawn, 2026-10-19)
                        local both = rawget(_G, "TR_BOTH") if both ~= nil and not (a.alt.sim.nothing and #(a.alt.sim.maps or {}) == 0) then local k = (ent.prefab or "?") .. (a.alt_always and " (always)" or "") both[k] = (both[k] or 0) + 1 end
                            SimMoves.maybe = true
                        danger = SimMoves.Draw(a.alt.sim, x, z, arot, target, my_radius, px, pz, t, a.alt_log, ent, target) or danger
                        SimMoves.maybe = nil
                        end
                    end
                elseif sim ~= nil and sim.leg ~= nil and sim.leg_whole and sim.leg_len ~= nil then
                    -- (a lane as long as it can go (sim.leg_len), from where it stood as its leg's animation began
                    -- or it jumped there (a teleport), the way it faced till it set off - drawn while that
                    -- animation and the next play: the Shadow Bishop, off round you, half a second, then charging)
                    local leg_anim = sim.leg.anim
                    local anims, on = sim.anims or {}, false
                    for i, an in ipairs(anims) do
                        if an == leg_anim and (ent.AnimState:IsCurrentAnimation(an) or (anims[i + 1] ~= nil and ent.AnimState:IsCurrentAnimation(anims[i + 1]))) then on = true end
                    end
                    if on and sim.leg_follow and not rawget(_G, "TR_OLD_PENGUIN") then
                        -- (sim.leg_follow: no lane from where it set off - its reach just ahead of where it is,
                        -- all the slide long, while it comes at you: after you as the game says, you ahead of it
                        -- within 45 - not as it flees, panics or follows; the Pengull's belly slide)
                        local mine = said_tgt ~= nil and me ~= nil and me.ent ~= nil and said_tgt == me.ent
                        -- (you ahead of it only for a lane - a ring round it has no ahead: the Smallbird turning
                        -- as it walked put its ring out a frame at a time)
                        if mine and (sim.leg_len or 0) > 0 then
                            local mx, _, mz = me.ent.Transform:GetWorldPosition()
                            local off = math.abs(((math.atan2(-(mz - z), mx - x) - rot) + math.pi) % (2 * math.pi) - math.pi)
                            mine = off < 45 * DEGREES
                        end
                        if mine then
                            Note(ent, "its slide, at you", a.move, t)
                            danger = SimMoves.DrawCapsule(x, z, rot, sim.leg_len, sim.leg_r or 2, "strike", px, pz) or danger
                        end
                    elseif on then
                        local in_leg = ent.AnimState:IsCurrentAnimation(leg_anim)
                        local lw = a.lw
                        if lw == nil or (in_leg and not lw.in_leg) or (x - lw.px) ^ 2 + (z - lw.pz) ^ 2 > 9 then
                            lw = { x = x, z = z, rot = rot }
                            a.lw = lw
                        end
                        lw.in_leg, lw.px, lw.pz = in_leg, x, z
                        local off = (x - lw.x) ^ 2 + (z - lw.z) ^ 2 > .09
                        if not off then lw.rot = rot
                        -- (once off, the way it's gone: turned to you the very tick it set off, the Shadow Bishop's
                        -- lane kept its facing from before - 25 off, its blows on you outside it; and it comes on
                        -- after you all along. TR_OLD_LANE: as before)
                        elseif not rawget(_G, "TR_OLD_LANE") then
                            -- (not the other way round from the way it faces - its place as drawn a hair back from where it set
                            -- off (a player's game, led on and back): the Shadow Bishop's lane turned about for a frame or two,
                            -- its middle 18-22 off and back, lag 1925. TR_OLD_LANEFLIP)
                            local nr = math.atan2(-(z - lw.z), x - lw.x)
                            local d = math.abs(((nr - rot) + math.pi) % (2 * math.pi) - math.pi)
                            if d < math.pi / 2 or rawget(_G, "TR_OLD_LANEFLIP") then lw.rot = nr end
                        end
                        Note(ent, "its lane, from where it set off", a.move, t)
                        danger = SimMoves.DrawCapsule(lw.x, lw.z, lw.rot, sim.leg_len, sim.leg_r or 2, off and "strike" or "fill", px, pz) or danger
                    elseif a.lw ~= nil then
                        a.lw.in_leg = false
                    end
                elseif sim ~= nil and sim.leg ~= nil then
                    -- run offline: it goes in straight legs (rolls) - each from where it set off,
                    -- when its rolling animation starts (again)
                    -- ("wrap": a leg as long as its animation - each time it starts over is the next;
                    -- "enter": a leg each time it comes back to its animation from another)
                    local leg_anim = sim.leg.anim ~= "" and sim.leg.anim or nil
                    if leg_anim ~= nil and ent.AnimState:IsCurrentAnimation(leg_anim) then
                        local at = ent.AnimState:GetCurrentAnimationTime()
                        local new_leg = a.leg_t == nil or (sim.leg.restart ~= "enter" and at < a.leg_t)
                        -- (one whose legs run on straight as one (wrap, not turning - the Scion's dash):
                        -- from where its first set off, all of them - not set again as each starts, nor
                        -- swung as it steers after you: the shape jumped 3.8 between its legs, and swung
                        -- to and fro as it turned. Set as it dashes, it stays)
                        local one_run = sim.leg.restart == "wrap" and not sim.leg.turns
                        -- (its first leg from where it stood as it aimed - it's seen a frame or so into
                        -- it already: set there, the shape went on .5 at you as it set off - the Eye of
                        -- Terror as a mouth)
                        local just_off = (a.legs_done or 0) == 0 and a.x ~= nil and (x - a.x) ^ 2 + (z - a.z) ^ 2 < 1.5 * 1.5
                        if new_leg and not (one_run and (a.legs_done or 0) >= 1) and not (just_off and not one_run) then
                            -- (the leg just run kept a moment (LINGER) - striking on as it ends: the Celestial Champion's roll
                            -- going round once more a frame as it stops, struck from roll_pst's first frame 2.2 behind it, its
                            -- lane gone that frame; 2026-10-28. TR_OLD_PREVLEG)
                            if a.leg_t ~= nil and not rawget(_G, "TR_OLD_PREVLEG") then
                                a.prev_leg = { x = a.x, z = a.z, rot = a.leg_rot or a.rot, till = now + LINGER }
                            end
                            a.x, a.z, a.rot = x, z, rot
                        end
                        -- (its first leg begun: how far it went before it, from where it stood - for next time)
                        if new_leg and (a.legs_done or 0) == 0 and a.pre_x ~= nil then
                            Predict._pre_go = Predict._pre_go or {}
                            local go = (x - a.pre_x) * math.cos(rot) - (z - a.pre_z) * math.sin(rot)
                            if go > 0 and go < 6 then Predict._pre_go[(ent.prefab or "?") .. "|" .. (a.move.name or "?")] = go end
                        end
                        if new_leg then a.legs_done = (a.legs_done or 0) + 1 end
                        a.leg_t = at
                        -- (the way it went on its leg - as its leg ended, it may have turned already that
                        -- very frame: the Wilting Dragonfly facing you again as its next wind-up began)
                        a.leg_rot = rot
                        a.legs_begun = true
                        a.leg_end = nil
                    else
                        -- (winding up: the roll to come, from where it is)
                        if a.leg_t ~= nil then
                            a.leg_end, a.end_rot, a.next_leg = now, a.leg_rot or rot, nil
                        end
                        -- (its first frames, its turn to its target not come through yet - the Eye of
                        -- Terror's charge drawn behind it for a frame: towards its target till it has)
                        local wr = rot
                        if sim.snaps and not a.legs_begun and target ~= nil and t < 3 * FRAMES and math.abs(rot - a.rot_begin) < 1e-4
                            and ((target.x - x) ^ 2 + (target.z - z) ^ 2) > .01 then
                            wr = math.atan2(-(target.z - z), target.x - x)
                        end
                        a.x, a.z, a.rot, a.leg_t = x, z, wr, nil
                        -- (between legs, stopped: where it's shown, not led on - its last word of going at 20 a second still in
                        -- hand a frame after it stopped (a repeat taken as "nothing new"), its next leg drawn 2 on for a frame and
                        -- back: the Eye of Terror, 3 in 70 minutes, lag 0314. TR_OLD_LEGRAW)
                        if a.legs_begun and not rawget(_G, "TR_OLD_LEGRAW") then
                            local rx, _, rz = ent.Transform:GetWorldPosition()
                            a.x, a.z = rx, rz
                        end
                        -- (before its first leg: from where it stood (till it starts to move, sim.moves_at),
                        -- on by as far as it was seen to go before its leg the last time - the
                        -- Scion slides 1.65 into its dash: the shape slid that much on at you with it)
                        if not a.legs_begun then
                            if a.pre_x == nil or (sim.moves_at ~= nil and t < sim.moves_at * FRAMES) then a.pre_x, a.pre_z = x, z end
                            Predict._pre_go = Predict._pre_go or {}
                            local go = Predict._pre_go[(ent.prefab or "?") .. "|" .. (a.move.name or "?")] or 0
                            -- (from the start: its leg begins there - not on by that much in one frame as it
                            -- starts to move)
                            a.x, a.z = a.pre_x + go * math.cos(wr), a.pre_z - go * math.sin(wr)
                            -- (its run offline telling how far it has still to go before its leg: from where it is now, on
                            -- by that - the Celestial Champion walks 8 into its roll, drawn where it stood its yellow was
                            -- left behind, its red come up on it, 889 "put elsewhere", 2026-10-20; and held up (against you)
                            -- it goes no way: from where it is, not 8 on past you. TR_OLD_PREGO=1: as before)
                            local p_first = (not rawget(_G, "TR_OLD_PREGO") and sim.maps ~= nil and sim.maps[1] ~= nil and sim.first ~= nil)
                                and SimMoves._PathAt(sim.maps[1], sim.first - 1) or nil
                            if p_first ~= nil and p_first > 0 and p_first < 12 then
                                local p_now = SimMoves._PathAt(sim.maps[1], math.max(0, math.floor(t / FRAMES + .5))) or 0
                                local left = math.max(0, p_first - p_now)
                                a.x, a.z = x + left * math.cos(wr), z - left * math.sin(wr)
                            end
                        end
                    end
                    -- (one leg's cells, from where it set off - before the first, the one to come;
                    -- between them, for as long as it stands before the next (sim.leg.gap): once it
                    -- turns round to its target, the next is coming that way - one that stays as it
                    -- faced has done)
                    -- (and only while it's at what comes straight after a leg - the Eye of Terror's
                    -- charge_pst, where it turns to you only if there's another to come; not on in
                    -- its taunt after the last, turning to you then too: a charge that never came)
                    local winding, winding_after = false, false
                    if leg_anim ~= nil then
                        local anims = sim.anims or {}
                        for i, an in ipairs(anims) do
                            if an == leg_anim and anims[i + 1] ~= nil and ent.AnimState:IsCurrentAnimation(anims[i + 1]) then
                                winding, winding_after = true, true
                            end
                        end
                        -- (or winding up again as it first did - the Wilting Dragonfly's dash after dash, each
                        -- from its dash_pre: the next not drawn till it was off)
                        if a.legs_begun and anims[1] ~= nil and anims[1] ~= leg_anim and ent.AnimState:IsCurrentAnimation(anims[1]) then
                            winding = true
                        end
                    end
                    if a.leg_end ~= nil and a.leg_t == nil and winding and Turned(rot, a.end_rot) > RETURN_TURN then
                        a.next_leg = true
                    end
                    -- (or no need to turn - facing you already, you straight ahead (within AHEAD_LEG): the Eye of Terror's mouth
                    -- charging again with you right in front of it, struck the first frame of its next leg with nothing drawn
                    -- before - 30 of the stress bench's, 2026-10-21. Faint (between legs: wait 1) - its last charge's
                    -- charge_pst too. TR_OLD_AHEADLEG=1: as before)
                    -- (only in what comes straight after a leg (winding_after - the Eye's charge_pst): not winding up again as it
                    -- first did - the Wilting Dragonfly's dash_pre, drawn the moment it began, the player 2026-10-21)
                    if a.leg_end ~= nil and a.leg_t == nil and winding_after and not a.next_leg and target ~= nil and not rawget(_G, "TR_OLD_AHEADLEG")
                        and ((target.x - x) ^ 2 + (target.z - z) ^ 2) > .01
                        and Turned(rot, math.atan2(-(target.z - z), target.x - x)) < AHEAD_LEG then
                        a.next_leg = true
                    end
                    -- (a leg drawn as a wave, coloured by when it gets to each part - SimMoves.DrawLegWave:
                    -- how far on its way it is, how fast it goes (as last seen going), how long till it
                    -- sets off)
                    local function Wave(cells_t, wx, wz, wrot)
                        local along_now, wait = 0, 0
                        if a.leg_t ~= nil then
                            along_now = math.max(0, (x - wx) * math.cos(wrot) - (z - wz) * math.sin(wrot))
                        elseif not a.legs_begun then
                            wait = math.max(0, (sim.first or 0) * FRAMES - t)
                        else
                            -- (between legs, the next not yet begun - it may turn elsewhere first (the Eye of
                            -- Terror): no nearer than faint red till it's away; yellow, it turned and its
                            -- yellow never went red)
                            wait = 1
                        end
                        -- (sim.leg_whole: one striking all round itself as it goes - the Wilting Dragonfly's dash, 6
                        -- round it: its lane as one piece - as a wave, cut by when its round front gets to each
                        -- part, it came out as crescents. Yellow once it's off, or about to be)
                        if sim.leg_whole then
                            -- (its lane, as far as a leg goes, sim.leg_r round its way; its cells run offline came
                            -- out hollow - each spot struck once, as it first came within reach)
                            return SimMoves.DrawCapsule(wx, wz, wrot, sim.leg_len or sim.leg.length or 12, sim.leg_r or 6, (a.leg_t ~= nil or wait <= .5) and "strike" or "fill", px, pz)
                        end
                        Predict._leg_speed = Predict._leg_speed or {}
                        local key = (ent.prefab or "?") .. "|" .. (a.move.name or "?")
                        if a.leg_t ~= nil and ent.Physics ~= nil then
                            local vx, _, vz = ent.Physics:GetVelocity()
                            local v = vx ~= nil and vz ~= nil and math.sqrt(vx * vx + vz * vz) or 0
                            if v > 2 then Predict._leg_speed[key] = v end
                        end
                        local speed = Predict._leg_speed[key] or (sim.leg.length or 12) / 1.2
                        return SimMoves.DrawLegWave(cells_t, wx, wz, wrot, px, pz, along_now, speed, wait, sim.reach or 2)
                    end
                    -- (sim.wait_anim: its first leg not drawn till this plays - where it aims then (the Wilting Dragonfly turns to
                    -- you anew as its dash_pre begins): drawn through its fire_on before, aimed at where you'd been, the player
                    -- 2026-10-21: "up before it should be")
                    if sim.wait_anim ~= nil and not a.legs_begun and not a.waited then
                        if ent.AnimState:IsCurrentAnimation(sim.wait_anim) then a.waited = true end
                    end
                    local held_back = sim.wait_anim ~= nil and not a.legs_begun and not a.waited
                    local pl = a.prev_leg
                    if pl ~= nil and now <= pl.till then
                        Note(ent, "the leg just run, as it ends", a.move, t)
                        danger = SimMoves.DrawCells(SimMoves.LegChain(sim.leg, 1), pl.x, pl.z, pl.rot, px, pz) or danger
                    end
                    if held_back then
                        Note(ent, "the leg to come, not yet aimed", a.move, t)
                    elseif a.leg_t ~= nil or not a.legs_begun then
                        Note(ent, a.leg_t ~= nil and "a leg, from where it set off" or "the leg to come", a.move, t)
                        if sim.leg.restart == "wrap" and not sim.leg.turns then
                            -- (the legs still to come, straight on - each as its animation goes round
                            -- again (wrap): the Scion's dash, twice - one shape, this leg and those after
                            -- run together; two side by side read as two dashes)
                            -- (steering after you as it goes - the Scion's dash bends your way: along the
                            -- way it's going now, from as far back as it has gone)
                            local ox, oz, orot = a.x, a.z, a.rot
                            -- (steering after you as it goes - the Scion's dash bends your way: along the
                            -- way it's going now, from as far back as it has gone - always, smoothly: not
                            -- only once turned 5 degrees, flipping between the two as it hovered there, to
                            -- and fro. Held straight instead, 3 strikes at its edge went undrawn)
                            if a.leg_t ~= nil then
                                local gone = math.sqrt((x - a.x) ^ 2 + (z - a.z) ^ 2)
                                if gone > .5 then
                                    ox, oz, orot = x - gone * math.cos(rot), z + gone * math.sin(rot), rot
                                end
                            end
                            -- (all its legs from where the first set off, once it's away)
                            local n = math.max(1, sim.leg.count or 1)
                            -- (one piece, not a wave: steering your way, its wave's yellow slid off to one
                            -- side and never went red there)
                            -- (and how its legs end, where they will - the Scion's stop, striking all
                            -- round it as it slides on: shown only once there, it came up under you
                            -- the very frame it struck) - one shape with them, not one over their end
                            danger = SimMoves.DrawCells(SimMoves.LegChain(sim.leg, n, sim.leg.finish), ox, oz, orot, px, pz) or danger
                        else
                            -- (one that turns round to you before each (sim.leg.turns) - the Celestial
                            -- Champion's roll: only this one - where it goes next is up to where you are
                            -- then; even faint, it read as two)
                            danger = Wave(sim.leg, a.x, a.z, a.rot) or danger
                        end
                    -- (no gap run offline - winding up again as it first did (the Wilting Dragonfly's dash_pre):
                    -- as long as its first wind-up)
                    elseif a.next_leg and (sim.leg.gap ~= nil or sim.first ~= nil) and now - a.leg_end <= (sim.leg.gap or sim.first) * FRAMES + LINGER then
                        Note(ent, "the next leg, as it turned round", a.move, t)
                        danger = Wave(sim.leg, a.x, a.z, a.rot) or danger
                    end
                elseif sim ~= nil and sim.around ~= nil then
                    -- run offline: it chases its target to the end (the Celestial Champion's spin,
                    -- as fast as you run) - round itself, wherever it is, towards its target
                    -- (you right by it - it spins back and forth over you: the way to you flips round
                    -- frame by frame; kept as it was then, and where it is eased, not jumped to - else
                    -- the shape turns and shakes every frame, its edge a blur)
                    local crot = a.around_rot or rot
                    local d2 = target ~= nil and ((target.x - x) ^ 2 + (target.z - z) ^ 2) or 0
                    -- (in its last animation, winding down (*_pst): after you no more - it slides on
                    -- as it was going, striking once round itself at most (the Celestial Champion's
                    -- spin, 8 frames in) or not at all (Rictus' bite); shown that long, not on after
                    -- you as it stops)
                    local anims = sim.anims or {}
                    local last = anims[#anims]
                    local winding_down = last ~= nil and last:find("_pst$") ~= nil and ent.AnimState:IsCurrentAnimation(last)
                    local over = winding_down and ent.AnimState:GetCurrentAnimationTime() > 10 * FRAMES
                    -- (one standing where it is (sim.still) that has struck all it strikes this go - by the time into
                    -- its animation now, not since the move began: one going round again (the Pepper Dragon's
                    -- breaths, its flame_loop played over) is aiming anew. Not on after you, and gone a moment on:
                    -- Deerclops' uppercut, turned to you at 35 and struck, was drawn following you to its end -
                    -- "it struck already and it still aims" (tr_testbench, run round it: AIMED at 37, 48))
                    -- (only one of one animation, aimed at you: not one biting on in a loop after its first - the
                    -- Shadow Thrall mouth's bite_loop, its later bites in the next animations, hidden: 18 missed)
                    if sim.still and not over and #anims == 1 and sim.frame == "target" then
                        if sim._last_step == nil then
                            sim._last_step = 0
                            for _, st in ipairs(((sim.maps or {})[1] or {}).steps or {}) do sim._last_step = math.max(sim._last_step, st.at or 0) end
                        end
                        local first_anim = anims[1]
                        local into = ent.AnimState:GetCurrentAnimationTime()
                        local past = first_anim ~= nil and (not ent.AnimState:IsCurrentAnimation(first_anim) or into > (sim._last_step + 1) * FRAMES)
                        if sim._last_step > 0 and past then
                            winding_down = true
                            over = not ent.AnimState:IsCurrentAnimation(first_anim) or into > (sim._last_step + 6) * FRAMES
                        end
                    end
                    -- (or one staying put that strikes once, its last strike run offline long past, not going again - its later
                    -- animations only its own lingering: Uncompromising Mode's bees stuck in the ground after their stab (stab_pst,
                    -- stuck_loop x6), drawn deep red all through - 2 s and more after their one blow, the player 2026-10-21.
                    -- TR_OLD_AROUNDONCE: as before)
                    -- (going or not: the Hooded Widow's charge strike, one blow a go of it at frame 12 as she runs)
                    if not over and not GoesAgain(sim) and not rawget(_G, "TR_OLD_AROUNDONCE") then
                        local ls = LastStrike(sim)
                        if ls > 0 and t ~= nil and t > (ls + 6) * FRAMES then winding_down, over = true, true end
                    end
                    -- (one striking the way it faces (sim.frame "facing"): turned as it turns, not to you - Uncompromising Mode's
                    -- Hooded Widow's charge strikes ahead of her (ChargeAttacked, 90 degrees either side), turning after you only
                    -- 2 degrees a frame: drawn swung round to you, "turning to and fro, not where it hits", the player
                    -- 2026-10-21. TR_OLD_AROUNDFACE: as before)
                    -- (one that goes - not one biting where it stands, turning to you at once: the Shadow Thrall mouth's bite,
                    -- turned to you, 2 struck undrawn as its face's way)
                    if sim.frame == "facing" and not sim.still and not rawget(_G, "TR_OLD_AROUNDFACE") then
                        crot = rot
                    elseif not winding_down and target ~= nil and d2 > AROUND_TURN_FROM * AROUND_TURN_FROM then
                        crot = math.atan2(-(target.z - z), target.x - x)
                    end
                    a.around_rot = crot
                    local sx, sz = x, z
                    local ap = a.around_pos
                    if ap ~= nil and (x - ap.x) ^ 2 + (z - ap.z) ^ 2 < 1 then
                        sx, sz = ap.x + (x - ap.x) * AROUND_EASE, ap.z + (z - ap.z) * AROUND_EASE
                    end
                    a.around_pos = { x = sx, z = sz }
                    -- (and on ahead, as far as it's coming in AROUND_AHEAD seconds at the speed it's
                    -- coming your way - never past you: a spin rushing at you, under you only as it
                    -- got there)
                    a.around_hist = a.around_hist or {}
                    local hist = a.around_hist
                    if #hist == 0 or hist[#hist][1] < now then
                        hist[#hist + 1] = { now, x, z }
                        if #hist > 6 then table.remove(hist, 1) end
                    end
                    local ahead = 0
                    local h0 = hist[1]
                    -- (or over its last two frames, if that's on further: just set off, the six frames
                    -- back were mostly standing - reaching out a few frames late, the spot it struck
                    -- shown a frame short of the warning it could have had)
                    if #hist >= 3 and now - h0[1] > .05 then
                        local along = 0
                        for _, h in ipairs({ h0, hist[#hist - 2] }) do
                            local vx, vz = (x - h[2]) / (now - h[1]), (z - h[3]) / (now - h[1])
                            along = math.max(along, vx * math.cos(crot) - vz * math.sin(crot))
                        end
                        -- (not once it's on you - spinning round over you, the way to you flips about)
                        ahead = math.max(0, math.min(along * AROUND_AHEAD, math.sqrt(d2) - AROUND_TURN_FROM))
                    end
                    -- (held till it's well off what's drawn: its speed read frame by frame wavers - the
                    -- shape went to and fro)
                    -- (longer at once, shorter only slowly: slowing as it nears you, it stays drawn reaching you)
                    -- (longer by AROUND_AHEAD_GROW a frame at most: its middle no jump as it sets off)
                    if a.around_ahead == nil or ahead > a.around_ahead + AROUND_AHEAD_HOLD then
                        a.around_ahead = math.min(ahead, (a.around_ahead or 0) + AROUND_AHEAD_GROW)
                    elseif ahead < a.around_ahead - AROUND_AHEAD_HOLD then
                        a.around_ahead = math.max(ahead, a.around_ahead - AROUND_AHEAD_DECAY * FRAMES)
                    end
                    Note(ent, "round itself, after you", a.move, t)
                    if not over then
                        danger = SimMoves.DrawAround(sim, sx, sz, crot, px, pz, t, winding_down and 0 or a.around_ahead) or danger
                    end
                -- (coming down where it is, after a chase of its own length (SimMoves._land): round it now - TR_OLD_LAND2)
                elseif sim ~= nil and a.move.name ~= nil and SimMoves._land[ent.prefab] ~= nil and SimMoves._land[ent.prefab][a.move.name] ~= nil
                    and Predict._LandNow(ent, a, SimMoves._land[ent.prefab][a.move.name]) ~= nil and not rawget(_G, "TR_OLD_LAND2") then
                    local ld = Predict._LandNow(ent, a, SimMoves._land[ent.prefab][a.move.name])
                    local into = ent.AnimState:GetCurrentAnimationTime()
                    if into <= ((rawget(_G, "TR_OLD_LANDTILL") and ld.till_old) or ld.till) * FRAMES + LINGER then
                        local lw = Predict._land_wide[ent]
                        local r = (ld.wide_anim ~= nil and lw ~= nil and now - lw < 4) and ld.wide_r or ld.r
                        -- (wider from a frame on - the teleport's strike 3.25 round from its frame 26)
                        -- (from r2_from on: it stands still from frame 6, so the whole wider ring is coming - drawn wide only as it
                        -- widened, a player's game showed it 3 frames after the blow, 3 struck undrawn 3.6 off, client replay
                        -- 2026-10-29. TR_OLD_R2FROM)
                        local r2_at = (ld.r2_from ~= nil and not rawget(_G, "TR_OLD_R2FROM")) and ld.r2_from or ld.r2_at
                        if ld.r2 ~= nil and into >= r2_at * FRAMES then r = ld.r2 end
                        -- (round where it really strikes from: whom it's after (ld.on_target - its optic blast teleports onto them,
                        -- SGshrouden optic_blast_appear), the thing itself once made (ld.at_thing - the beam, made there, chasing you
                        -- 1.6 s on); not its offline chase laid out ahead of it, "the laser's hitbox out in front of the boss", the
                        -- player 2026-10-28. TR_OLD_LANDAT: round itself)
                        local dx, dz, thing = LandSpot(ent, ld, x, z, target, now)
                        -- (round a thing not there yet - the beam a frame before it's made, as pre1 gives way to pre2: where it was
                        -- drawn the frame before, not round the boss 16 off for that frame and back (frame_check POP, [tr_lagnote]
                        -- lag 0822, 2026-10-29). TR_OLD_THINGWAIT: round itself)
                        -- (from a spot really found, a moment ago - not from itself kept on: no beam ever, held there for good,
                        -- 25 struck undrawn in a replay)
                        if ld.at_thing ~= nil and thing == nil and a.land_xy ~= nil and now - a.land_xy[3] < .2
                            and not rawget(_G, "TR_OLD_THINGWAIT") then
                            dx, dz = a.land_xy[1], a.land_xy[2]
                        elseif ld.at_thing == nil or thing ~= nil then
                            a.land_xy = { dx, dz, now }
                        end
                        -- (aimed till lock_at, then kept where it was aimed - Spat's phlegm, shot at where you were)
                        if ld.lock_at ~= nil and into >= ld.lock_at * FRAMES then
                            if a.land_lock == nil then a.land_lock = { dx, dz } end
                            dx, dz = a.land_lock[1], a.land_lock[2]
                        end
                        -- (wide by the thing's own word (its net "wide") - the boss's short optic_blast_pre3 missed in a player's
                        -- game, the wide beam (5) drawn 2.5: struck 3.7 off undrawn twice, lag 0549 2026-10-29. TR_OLD_WIDENET)
                        if ld.wide_r ~= nil and thing ~= nil and type(thing.wide) == "table" and thing.wide.value ~= nil
                            and thing.wide:value() and not rawget(_G, "TR_OLD_WIDENET") then r = ld.wide_r end
                        a.land_drawn = now
                        Note(ent, "round itself, where it is", a.move, t)
                        danger = SimMoves.DrawDisc(dx, dz, r, ld.eta or (ld.at * FRAMES - into), px, pz) or danger
                        require("true_range/telegraph").Circle(dx, dz, r, "edge")
                    end
                -- (one drawn its own way all through (SimMoves._land has its own first animation), that animation not yet
                -- playing - a player's game knows the move a frame before its animation comes: nothing, not its offline run
                -- laid out 7-20 long for that frame - the Umbral Abomination's optic blast, a big shape flashed on each
                -- one, the player 2026-10-29 ([tr_lagframe] lag 0549, 5 of 5). TR_OLD_LANDFIRST: drawn so)
                elseif sim ~= nil and a.move.name ~= nil and SimMoves._land[ent.prefab] ~= nil and SimMoves._land[ent.prefab][a.move.name] ~= nil
                    and Predict._LandOwn(SimMoves._land[ent.prefab][a.move.name], a.move.name, sim) and not rawget(_G, "TR_OLD_LANDFIRST")
                    and not rawget(_G, "TR_OLD_LAND2") then
                    Note(ent, "its own way, not yet", a.move, t)
                elseif sim ~= nil then
                    -- run offline from the game's code (where its target stood straight ahead):
                    -- laid out towards its target - not the way it faces; once it stops aiming
                    -- (sim.lock), towards where it aimed then; a move that never stops aiming (a
                    -- chase, a spin) still from where it began - towards where its target is now
                    -- (drawn from where it is, the part it has already gone through would be
                    -- pushed on past you)
                    local ox, oz = a.x, a.z
                    -- ("facing": it lays it out the way it faces - it turns slower than you run)
                    -- (the spot it aims at, as the server tells it, near where you're seen - the Clockwork
                    -- Bishop's creeps after you, slowing, till it shoots: aimed there, all along)
                    local tp_live = SimMoves.PoseTargetPos(ent)
                    -- (once taken for this go - its mark, seen near you as it began: kept on however far you
                    -- then are from it - it creeps after you, slowing; you gone 7 off at once (a leap, a
                    -- hop) were taken instead, the shape thrown 8-13 out for a frame or two till the mark
                    -- came round - the Clockwork Bishop on the bench, 2026-10-19. TR_OLD_TPKEEP: as before)
                    if tp_live ~= nil and sim.still and target ~= nil and a.locked == nil
                        and ((tp_live.x - target.x) ^ 2 + (tp_live.z - target.z) ^ 2 < 6 * 6
                            or (a.tp_last ~= nil and not rawget(_G, "TR_OLD_TPKEEP"))) then
                        target = { x = tp_live.x, z = tp_live.z, me = target.me }
                    else
                        tp_live = nil
                    end
                    local aim, aim_rot = target, rot
                    -- (you round behind one that goes at you only if you're near the way it faces: where it goes then)
                    if a.locked == nil then aim = AheadIfOff(ent, sim, aim) end
                    -- (sim.anchor "lock": all its damage comes after it stops aiming - seen from
                    -- where it stands then; until then from where it is now)
                    if sim.anchor == "lock" then
                        ox, oz = x, z
                    end
                    -- (where it was and faced, and where its target was, moment by moment - for the very
                    -- moment it stops aiming: seen a frame late, it may be off already - the
                    -- Werepig leaps the frame after)
                    a.hist = a.hist or {}
                    if a.locked == nil then
                        table.insert(a.hist, { t = t, x = x, z = z, rot = rot, target = target })
                        if #a.hist > 30 then table.remove(a.hist, 1) end
                    end
                    -- (what it strikes by all put down only after it stops aiming - the War Machine's
                    -- beam, coming down on you after you as it goes: aimed at you until it's there,
                    -- not left where you stood as it began)
                    local lock_f = sim.lock
                    -- (only things drawn on their own - not lasers laid along its locked beam, drawn
                    -- with the move: the Celestial Champion's)
                    -- (not one whose lock already counts what it set off - sim.lock_things, run offline since
                    -- that was put right: stretched again, Uncompromising Mode's Bearger was drawn aiming at you
                    -- on to its last sinkhole (frame 43) though the line was set at 21 - and Deerclops' swipe to
                    -- 39, Moonmaw's to 25: "it struck already and it still aims")
                    if lock_f ~= nil and not sim.lock_things and sim.puts ~= nil and sim.set_until ~= nil and sim.set_until > lock_f then
                        local own = true
                        for _, p in ipairs(sim.puts) do
                            local hz = SimMoves.Hazards()[p]
                            if hz == nil or hz.in_move then own = false end
                        end
                        if own then lock_f = sim.set_until end
                    end
                    -- (its deciding frame from the game's code, where known - tools/trace_moves.lua,
                    -- true_range/moves_table _decide: the last frame where its target stands
                    -- counts; it stops aiming the frame after - not guessed from what it puts down,
                    -- Deerclops' spikes following you on to frame 39, it stopped turning at 16)
                    local dd = a.move.name ~= nil and Tables._decide ~= nil and Tables._decide[ent.prefab] ~= nil
                        and Tables._decide[ent.prefab][a.move.name] or nil
                    -- (only where it was taken as aiming on until what it puts down is down - known
                    -- from its code instead; elsewhere sim.lock, as run offline, stands)
                    -- (testing: TR_OLD_LOCK - as it was, to compare)
                    if dd ~= nil and dd > 0 and lock_f ~= sim.lock and not rawget(_G, "TR_OLD_LOCK") then lock_f = dd + 1 end
                    -- (its aim told live by the server: on till just before it strikes, not set at a frame
                    -- read from its code - the Clockwork Bishop's taken as set at 6, it aims on to 30)
                    -- (only one seen to creep - a spot set once and kept, Frostjaw's dive, is no aim
                    -- going on)
                    if tp_live ~= nil then
                        if sim.still and a.tp_last ~= nil and (tp_live.x - a.tp_last.x) ^ 2 + (tp_live.z - a.tp_last.z) ^ 2 > 1e-4 then a.tp_moves = true end
                        a.tp_last = tp_live
                    end
                    if tp_live ~= nil and a.tp_moves and lock_f ~= nil and sim.first ~= nil then lock_f = math.max(lock_f, sim.first - 1) end
                    -- (one that goes on into another move of its own - an animation of it the first of that
                    -- other, aimed at its target: its blow is that one's, aimed as that one begins - the
                    -- Uncompromising catcoon's hiss into its pounce (pounce_pre, then pounceattack turns to
                    -- you, rot 90 -> 30): aimed after you on till then, not set as it began and swung round
                    -- as the other takes over. TR_OLD_CHAINLOCK: set at its own lock, as before)
                    if lock_f ~= nil and sim.frame == "target" and sim.first ~= nil and not rawget(_G, "TR_OLD_CHAINLOCK") then
                        if sim._chain_lock == nil then
                            sim._chain_lock = false
                            local ok, data = pcall(require, "true_range/moves_sim")
                            local mine = ok and type(data) == "table" and ent.prefab ~= nil and data[ent.prefab] or nil
                            if type(mine) == "table" and sim.anims ~= nil then
                                for i = 2, #sim.anims do
                                    for _, o in pairs(mine) do
                                        if type(o) == "table" and o ~= sim and o.anims ~= nil and o.anims[1] == sim.anims[i]
                                            and o.frame == "target" and o.first ~= nil and sim.first > o.first then
                                            local l = sim.first - o.first + (o.lock or 0)
                                            if sim._chain_lock == false or l < sim._chain_lock then sim._chain_lock = l end
                                        end
                                    end
                                    if sim._chain_lock then break end
                                end
                            end
                        end
                        if sim._chain_lock and sim._chain_lock > lock_f then lock_f = sim._chain_lock end
                    end
                    -- (aiming on past its own lock - into the move it goes on into, above: only its aim. Where
                    -- it's laid from is where it stood at its own lock, as run offline - from where it is
                    -- now, the way it had already gone was laid on again past you: the Boarrior's dash,
                    -- drawn 3.5 on from where it had got to, then snapped back. TR_OLD_CHAINPOS: as before)
                    if sim.anchor == "lock" and lock_f ~= nil and sim.lock ~= nil and lock_f > sim.lock and not rawget(_G, "TR_OLD_CHAINPOS") then
                        if a.anchor_at == nil and t >= sim.lock * FRAMES then
                            local h0 = a.hist[1]
                            for i = #a.hist, 1, -1 do
                                if a.hist[i].t <= sim.lock * FRAMES + .001 then h0 = a.hist[i] break end
                            end
                            if h0 ~= nil then a.anchor_at = { x = h0.x, z = h0.z } end
                        end
                        if a.anchor_at ~= nil then ox, oz = a.anchor_at.x, a.anchor_at.z end
                    end
                    -- (a player's game, while it still aims: at you where the server has you this moment of the move
                    -- (its pose for t) - not where you're seen, a frame or two on with ping: drawn turned on past where it
                    -- then locked, and snapped back, the player 2026-10-22. As at the lock below: one that stops at its
                    -- own lock. TR_OLD_SERVERAIM)
                    -- (one laid from where it stands as it locks too (anchor "lock" - the Ancient Guardian's charge, Bearger's
                    -- swipes, the Eye's charge: 41 moves): left out on 2026-10-22 for the Champion's sweep - 66 of its 67 glitches
                    -- then came within 1.5 s of the testbench moving its stand-in at a stroke, its middle taken as where you
                    -- were; no player moves so. Left out, the charge was drawn after you as your screen has you and snapped
                    -- back as it set off, the player 2026-10-25. TR_OLD_SERVERAIMLOCK: left out again)
                    if a.locked == nil and target ~= nil and target.me and aim == target and lock_f ~= nil and lock_f == sim.lock
                        and lock_f >= 3 and (sim.anchor ~= "lock" or not rawget(_G, "TR_OLD_SERVERAIMLOCK"))
                        -- (one aimed on after too (sim.follow - the Celestial Champion's tri-beam, Klaus' chomp, 13 bosses): left
                        -- out on 2026-10-22 for 12 undrawn on a bench whose stand-in was moved at a stroke; a player's own game had
                        -- the beams turned after you as it shows you - the player's log 2026-10-26: 4 of 4 beam blows undrawn on
                        -- their screen, 4 of 4 drawn with it, the benches no worse. TR_OLD_SERVERAIMFOLLOW: left out again)
                        and (sim.follow == nil or not rawget(_G, "TR_OLD_SERVERAIMFOLLOW"))
                        and me ~= nil and me.ent ~= nil and SimMoves.PoseAim(ent) == me.ent
                        and not rawget(_G, "TR_OLD_SERVERAIM") then
                        -- (half way between its poses 2 and 1 frames back, as the lock takes it below: on into the lock
                        -- with no step - from its pose for t, it turned 3.4 on past the lock and snapped back)
                        -- (its first frames: its first poses; once taken, kept on through a frame not told yet - not
                        -- back and forth between the server's and what's seen: the Deerclops' beam's middle 6 to and fro,
                        -- 268 such on the bench)
                        a.log = a.log or {}
                        local x1, z1 = SimMoves.PoseAimUpTo(ent, sim, a.log, math.max(0, t - 2 * FRAMES))
                        local x2, z2 = SimMoves.PoseAimUpTo(ent, sim, a.log, math.max(0, t - FRAMES))
                        if x1 ~= nil and x2 ~= nil then
                            local sx, sz = (x1 + x2) / 2, (z1 + z2) / 2
                            if (sx - target.x) ^ 2 + (sz - target.z) ^ 2 < 8 * 8 then a.srv_aim = { x = sx, z = sz, me = true } end
                        end
                        if a.srv_aim ~= nil then aim = a.srv_aim a.srv_aim_t = now end
                    -- (a frame or two the server's aim not on hand (its pose not told yet) before it locks: the last kept, not
                    -- your screen's place for those frames - the Moose's hop lane 1.7 short two frames, from 5.6 to 1.8 off and
                    -- back, lag 1636. TR_OLD_AIMHOLD)
                    elseif a.locked == nil and a.srv_aim ~= nil and a.srv_aim_t ~= nil and now - a.srv_aim_t <= 4 * FRAMES
                        and target ~= nil and target.me and aim == target and not rawget(_G, "TR_OLD_AIMHOLD") then
                        aim = a.srv_aim
                    end
                    -- (or locked anew as it went again: SimMoves._relock, above)
                    if (lock_f ~= nil and t >= lock_f * FRAMES) or (a.relock_began ~= nil and a.locked ~= nil) then
                        if a.locked == nil then
                            local at = a.hist[#a.hist]
                            for i = #a.hist, 1, -1 do
                                if a.hist[i].t <= lock_f * FRAMES + .001 then
                                    at = a.hist[i]
                                    break
                                end
                            end
                            -- (where its target stood: the last frame it still looked is the one
                            -- before - and what's seen here of you runs half a frame on from what
                            -- its code sees: traced tick by tick, the beam's target 1-2 frames late)
                            local aim_t = (lock_f - 1.5) * FRAMES
                            local seen = at.target
                            for i = #a.hist, 1, -1 do
                                local h, h2 = a.hist[i], a.hist[i + 1]
                                if h.t <= aim_t + .001 then
                                    seen = h.target
                                    if h2 ~= nil and h.target ~= nil and h2.target ~= nil and h2.t > h.t then
                                        local k = math.min(1, (aim_t - h.t) / (h2.t - h.t))
                                        seen = { x = h.target.x + (h2.target.x - h.target.x) * k,
                                            z = h.target.z + (h2.target.z - h.target.z) * k, me = h.target.me }
                                    end
                                    break
                                end
                            end
                            -- (a player's game, not the host's: where the server had you as it took its aim - not where
                            -- you're seen here, your own moving shown a frame or two on from the server's (more as the
                            -- game has just loaded): Bearger's sinkhole line drawn 0.8 off you, turned on past the wave,
                            -- joined to a server - the player 2026-10-22. Only told to players' games (true_range
                            -- modmain). With the game's lag compensation on, you're shown on ahead of where the server has you - struck though you look
                            -- clear: the game's own, its own lasers drawn so too, the player 2026-10-22. TR_OLD_SERVERAIM)
                            -- (only one that aims a while and stops at its own lock: not one done aiming as it begins
                            -- (lock 0 - the glacial hound's bite, 3 more undrawn), nor one aimed on after (sim.follow, a lock
                            -- moved on - the Celestial Champion's beam, 12 more); one laid from where it stands as it locks (anchor lock)
                            -- too since 2026-10-25 - its sweep's 36 outside were the testbench's own teleports, above. TR_OLD_SERVERAIMLOCK)
                            if seen ~= nil and seen.me and lock_f == sim.lock and lock_f >= 3 and (sim.follow == nil or not rawget(_G, "TR_OLD_SERVERAIMFOLLOW"))
                                and (sim.anchor ~= "lock" or not rawget(_G, "TR_OLD_SERVERAIMLOCK")) and me ~= nil and me.ent ~= nil
                                and SimMoves.PoseAim(ent) == me.ent
                                and not rawget(_G, "TR_OLD_SERVERAIM") then
                                -- (at the same moment as the host's own, aim_t - half way between the server's two ticks
                                -- round it: the host's game and a player's then draw alike. Two frames back, as measured on
                                -- Bearger alone, took the glacial hound's howl-or-bite 3 undrawn)
                                a.log = a.log or {}
                                local x1, z1 = SimMoves.PoseAimUpTo(ent, sim, a.log, (lock_f - 2) * FRAMES)
                                local x2, z2 = SimMoves.PoseAimUpTo(ent, sim, a.log, (lock_f - 1) * FRAMES)
                                if x1 ~= nil and x2 ~= nil then
                                    local sx, sz = (x1 + x2) / 2, (z1 + z2) / 2
                                    if (sx - seen.x) ^ 2 + (sz - seen.z) ^ 2 < 8 * 8 then seen = { x = sx, z = sz, me = true } end
                                end
                            end
                            -- (it aims ahead of its target, by how fast that goes - Frostjaw's dives:
                            -- where it'll be sim.lead seconds on; its speed over the last few moments)
                            -- (you: how fast you go right now, as its code reads it - you set off
                            -- in its last frame of aiming, and it leapt that much further)
                            local vx, vz = nil, nil
                            if sim.lead ~= nil and seen ~= nil and seen.me and me.ent.Physics ~= nil then
                                local ux, _, uz = me.ent.Physics:GetVelocity()
                                if ux ~= nil and uz ~= nil then vx, vz = ux, uz end
                            end
                            if vx ~= nil then
                                seen = { x = seen.x + vx * sim.lead, z = seen.z + vz * sim.lead, me = seen.me }
                            elseif sim.lead ~= nil and seen ~= nil then
                                local old = nil
                                for i = #a.hist, 1, -1 do
                                    local h = a.hist[i]
                                    if h.t <= aim_t - .1 and h.target ~= nil then old = h break end
                                end
                                if old ~= nil and aim_t > old.t then
                                    local k = sim.lead / (aim_t - old.t)
                                    seen = { x = seen.x + (seen.x - old.target.x) * k, z = seen.z + (seen.z - old.target.z) * k, me = seen.me }
                                end
                            end
                            -- (you stepped out of how far round it turns: where you were then)
                            -- (from when it began to follow you - sim.track frames before it's seen to begin -
                            -- the first moment you were out of it)
                            local ct = sim.cone ~= nil and cones[ent] or nil
                            if ct ~= nil and ct.h ~= nil and seen ~= nil and seen.me then
                                -- (its first frame of following you, it has only just turned to you: from the one after)
                                local from, to = a.t0 - math.max(0, (sim.track or 0) - 1) * FRAMES - .001, a.t0 + (sim.lock - 1) * FRAMES + .001
                                for _, s in ipairs(ct.h) do
                                    if s.t >= from and s.t <= to and not s.inside then
                                        print(string.format("[true_range] %s let you go at %.2fs before it began: kept at %.2f,%.2f",
                                            ent.prefab, a.t0 - s.t, s.x, s.z))
                                        seen = { x = s.x, z = s.z, me = true }
                                        break
                                    end
                                end
                            end
                            a.locked = { target = seen or at.target, rot = at.rot, x = at.x, z = at.z }
                            -- (at you only if you're that near the way it faces as it stops aiming - further round,
                            -- straight on the way it faces, so far (sim.ahead_if_off degrees, sim.ahead_dist): the
                            -- Ancient Guard Tower's leap, drawn at you as it leapt off the other way. TR_OLD_AHEADOFF)
                            if sim.ahead_if_off ~= nil and a.locked.target ~= nil and at.rot ~= nil and not rawget(_G, "TR_OLD_AHEADOFF") then
                                local lt0 = a.locked.target
                                local off = math.abs(((math.atan2(-(lt0.z - at.z), lt0.x - at.x) - at.rot) + math.pi) % (2 * math.pi) - math.pi)
                                if off > sim.ahead_if_off * DEGREES then
                                    local d = sim.ahead_dist or 4
                                    a.locked.target = { x = at.x + d * math.cos(at.rot), z = at.z - d * math.sin(at.rot), me = false }
                                end
                            end
                            local lt = a.locked.target
                            if lt ~= nil then
                                print(string.format("[true_range] %s %s aimed at %.2fs: its target %.2f from where it began",
                                    ent.prefab, a.move.name or "?", t, math.sqrt((lt.x - a.x) ^ 2 + (lt.z - a.z) ^ 2)))
                            end
                        end
                        -- (and the spot it goes for, as the server's state took it (statemem.targetpos) -
                        -- where you were, there; here you were seen late, the Ancient Guardian's landing
                        -- drawn .5 to 1 off, put right only as it struck. Only one near where you were
                        -- seen: a state's targetpos that's somewhere else is no word on you)
                        -- (and on after, as long as the server tells it - the Clockwork Bishop's aim creeps
                        -- on after you past what was run offline as its lock: drawn there, not stopped early)
                        do
                            local tp = SimMoves.PoseTargetPos(ent)
                            local lt = a.locked.target
                            if tp ~= nil and lt ~= nil and ((a.locked.tpos and a.tp_moves) or (not a.locked.tpos and (tp.x - lt.x) ^ 2 + (tp.z - lt.z) ^ 2 < 2 * 2)) then
                                if lt.x ~= tp.x or lt.z ~= tp.z then a.locked.target = { x = tp.x, z = tp.z, me = lt.me } end
                                a.locked.tpos = true
                            end
                        end
                        -- (where it was as it stopped aiming, as the server has it - not as seen here,
                        -- late and slid between ticks: once told, that - true_range/simmoves Pose;
                        -- simmoves then takes it as it is, log.lock_exact)
                        if not a.locked.exact then
                            a.log = a.log or {}
                            local s = SimMoves._PoseAt(ent, sim, a.log, lock_f * FRAMES, now - a.t0)
                            if s ~= nil then
                                a.locked.x, a.locked.z, a.locked.exact = s[2], s[3], true
                                a.log.lock_exact = true
                            end
                        end
                        aim, aim_rot = a.locked.target, a.locked.rot
                        if sim.anchor == "lock" and a.anchor_at == nil then
                            ox, oz = a.locked.x, a.locked.z
                        end
                    end
                    -- (sim.still: it goes nowhere itself - moving all the same, it was already on its
                    -- way as it began (Dragonfly bites as it flies on): round where it is now)
                    -- (one that sets things down round itself - the Celestial Champion's crystals: where it
                    -- stands as it puts the last down, sim.set_until; after that it's set, not moving on
                    -- with it)
                    if sim.still then
                        if sim.set_until ~= nil and t > (sim.set_until + 1) * FRAMES and a.set_at ~= nil then
                            ox, oz = a.set_at.x, a.set_at.z
                        else
                            ox, oz = x, z
                            if sim.set_until ~= nil then a.set_at = { x = x, z = z } end
                        end
                    end
                    -- (laid round a thing by it, not round itself - Predict.RoundAt)
                    do
                        local g = Predict.RoundAt(a, sim, x, z)
                        if g then ox, oz = g.x, g.z end
                    end
                    if sim.frame ~= "facing" and aim ~= nil and ((aim.x - ox) ^ 2 + (aim.z - oz) ^ 2) > .01 then
                        aim_rot = math.atan2(-(aim.z - oz), aim.x - ox)
                    end
                    -- (its way set to the nearest 45 degrees as it strikes (sim.snap45 - its state's own SnapTo45s): the Rock
                    -- Master's snip aimed straight at you came down up to 22.5 off; 2026-10-26. TR_OLD_SNAP45: as before)
                    if sim.snap45 and aim_rot ~= nil and not rawget(_G, "TR_OLD_SNAP45") then
                        aim_rot = math.floor(aim_rot / (math.pi / 4) + .5) * (math.pi / 4)
                    end
                    -- (sim.abort_turn: one alike to another that sets off some other way - the Hooded
                    -- Widow's leap to a tree, the same animations as its leap at you: once it has stopped
                    -- aiming and faces more than this many degrees off you, it's that other - not drawn)
                    if sim.abort_turn ~= nil and a.locked ~= nil and not a.aborted then
                        do
                            local off = math.abs((rot - aim_rot + math.pi) % (2 * math.pi) - math.pi)
                            if off > sim.abort_turn * math.pi / 180 then a.aborted = true end
                        end
                    end
                    -- (what it strikes by thrown or put down already (sim.set_until) - the Scrappy
                    -- Werepig's junk in the air: where it was aimed then, not after you as you run on)
                    -- (not while the server tells where it aims - the Clockwork Bishop's mark, put down
                    -- at 6, creeps after you on till it shoots)
                    if sim.set_until ~= nil and t > (sim.set_until + 1) * FRAMES and not (tp_live ~= nil and a.tp_moves) then
                        if a.set_aim == nil then a.set_aim = { aim = aim, rot = aim_rot } end
                        aim, aim_rot = a.set_aim.aim, a.set_aim.rot
                    end
                    -- (one laid out the way it faces that turns right round to its target as it
                    -- begins (sim.snaps), its first frames - that turn not come through yet (the Eye of Terror's charge, drawn behind it for
                    -- a frame): towards its target, until it has turned)
                    -- (one that turns to its target only as a later animation of it begins
                    -- (sim.snap_anim - the Scrappy Werepig's throw): towards its target until then,
                    -- the way it faces after - it may not turn all the way round)
                    if sim.frame == "facing" and sim.snap_anim ~= nil and target ~= nil and a.set_aim == nil
                        and ((target.x - x) ^ 2 + (target.z - z) ^ 2) > .01 then
                        local now_i, snap_i = nil, nil
                        for i, an in ipairs(a.move.anims) do
                            if now_i == nil and ent.AnimState:IsCurrentAnimation(an) then now_i = i end
                            if snap_i == nil and an == sim.snap_anim then snap_i = i end
                        end
                        if now_i ~= nil and snap_i ~= nil and now_i < snap_i then
                            aim_rot = math.atan2(-(target.z - z), target.x - x)
                        end
                    end
                    if sim.frame == "facing" and sim.snaps and a.locked == nil and target ~= nil and t < 3 * FRAMES
                        and math.abs(rot - a.rot_begin) < 1e-4 and ((target.x - x) ^ 2 + (target.z - z) ^ 2) > .01 then
                        aim_rot = math.atan2(-(target.z - z), target.x - x)
                    end
                    -- (one shot off from ahead of it (sim.launch - MacTusk's dart, set off 3 ahead the way
                    -- it faces): its lane from there towards what it aims at, not from its middle - it
                    -- facing a little off you, the dart's way went at a slant to the lane drawn)
                    if sim.launch ~= nil and aim ~= nil then
                        local fr = a.locked ~= nil and a.locked.rot or rot
                        local lx, lz = ox + sim.launch * math.cos(fr), oz - sim.launch * math.sin(fr)
                        if (aim.x - lx) ^ 2 + (aim.z - lz) ^ 2 > .01 then
                            ox, oz = lx, lz
                            aim_rot = math.atan2(-(aim.z - oz), aim.x - ox)
                        end
                    end
                    a.log = a.log or {}
                    -- (one whose length isn't up to you - the Ancient Guardian's charge, sim.fixed: once
                    -- it's running, from where it is now, the way it's really going - along a wall it
                    -- slides into - for as far as it has still to go)
                    -- (on its line: laid where it set off, its parts gone as it gets past them - by how
                    -- far it has really gone, not the time it was thought to take; off its line, a
                    -- wall turning it: from where it is, the way it's going, as far as it has left)
                    local len, tt = nil, t
                    -- (winding up, turning to you as it does: as far as you are - its brain runs it
                    -- till it gets to you - its farthest at most)
                    if sim.fixed and a.locked == nil and target ~= nil then
                        if sim._full == nil then
                            sim._full = 0
                            for _, m in ipairs(sim.maps or {}) do sim._full = math.max(sim._full, m.dist or 0) end
                        end
                        len = math.min(sim._full, math.sqrt((target.x - ox) ^ 2 + (target.z - oz) ^ 2))
                        -- (one that goes its whole way whoever's where - the Rabbit King's dropkick)
                        if sim.straight then len = sim._full - (sim.launch or 0) end
                        local cap = RamEnd(ent, sim, ox, oz, math.cos(aim_rot), math.sin(aim_rot))
                        if cap ~= nil then len = math.max(0, math.min(len, cap)) end
                    end
                    if sim.fixed and a.locked ~= nil then
                        if sim._full == nil then
                            sim._full = 0
                            for _, m in ipairs(sim.maps or {}) do sim._full = math.max(sim._full, m.dist or 0) end
                        end
                        -- (its line: where it set off, the way it really runs - taken from its first
                        -- stretch of running; turned off it by a wall: a new line from there, as far
                        -- as it has left - once, not made again every frame)
                        a.mv = a.mv or { x = x, z = z, rot = aim_rot }
                        local line = a.line
                        if line == nil then
                            line = { x = sim.launch ~= nil and ox or a.locked.x, z = sim.launch ~= nil and oz or a.locked.z, rot = aim_rot, len = nil, settling = true }
                            a.line = line
                        end
                        local dx, dz = x - a.mv.x, z - a.mv.z
                        if dx * dx + dz * dz > .09 then
                            a.mv.rot, a.mv.x, a.mv.z = math.atan2(-dz, dx), x, z
                            a.gone = (a.gone or 0) + math.sqrt(dx * dx + dz * dz)
                            local fx, fz = x - line.x, z - line.z
                            if line.settling then
                                if fx * fx + fz * fz > .25 then line.rot = math.atan2(-fz, fx) end
                                if fx * fx + fz * fz > 4 then line.settling = false end
                            end
                        end
                        local c, s = math.cos(line.rot), math.sin(line.rot)
                        local along = (x - line.x) * c - (z - line.z) * s
                        local side = (x - line.x) * s + (z - line.z) * c
                        if not line.settling and math.abs(side) > 1 then
                            line = { x = x, z = z, rot = a.mv.rot, len = math.max(0, sim._full - (a.gone or 0)), settling = true }
                            a.line = line
                            along = 0
                        end
                        ox, oz, aim_rot, len = line.x, line.z, line.rot, line.len
                        -- (and how far it runs as its brain has it (ChaseAndRam) - not to where you
                        -- were as it took aim: on while you're ahead of it, within RAM_TURN of its way,
                        -- till it gets to you; you off that and RAM_GIVE_UP or more away, it stops where
                        -- it is; off it nearer than that, on till it's that far from you - never past
                        -- its farthest (the maps' last: 25 from where it set off))
                        if line.len == nil and sim.straight then
                            len = sim._full - (sim.launch or 0)
                        elseif line.len == nil and target ~= nil then
                            -- (stepped on along its way, you where you are now, as its brain looks: its
                            -- way and you each as an angle made positive, then their difference - not
                            -- the angle between them (ChaseAndRam: math.abs(angle - math.abs(ram_angle))),
                            -- the Rook stopping where none was drawn; or stopped at you, in reach)
                            local tx, tz = target.x - line.x, target.z - line.z
                            local ta, ts = tx * c - tz * s, tx * s + tz * c
                            local qx, qz = line.x + c * along, line.z - s * along
                            local off = math.abs(math.abs(math.atan2(-(target.z - qz), target.x - qx) / DEGREES) - math.abs(line.rot / DEGREES))
                            local away = math.sqrt((ta - along) ^ 2 + ts * ts)
                            local want = ta
                            if off > RAM_TURN then
                                want = away >= RAM_GIVE_UP and along or ta + math.sqrt(math.max(0, RAM_GIVE_UP * RAM_GIVE_UP - ts * ts))
                            end
                            -- (as len: how far it goes from where it set off - SimMoves.Draw takes a
                            -- fixed one's length from it, its whole way without)
                            len = math.max(along, math.min(sim._full, want))
                        end
                        -- (and no further than its brain lets it: the time and way it has left)
                        local cap = RamEnd(ent, sim, line.x, line.z, c, s)
                        if cap ~= nil then len = math.max(along, math.min(len or sim._full, cap)) end
                        -- (where it is on its way, by its clock: what it gores behind itself, still within
                        -- its reach, kept by SimMoves (entry.gore) - not this clock set that far back: 6
                        -- frames behind it, its lane's end went yellow and never red, the move over first)
                        tt = (sim.first or sim.lock or 0) * FRAMES + math.max(0, along) / (sim.speed or 6)
                        -- (never back within one go: where it is as your game shows it steps back a hair now and then, its
                        -- clock with it - the Nightmare Rook's charge 8 parts left, 13, 8 a frame apart, lag 2220. TR_OLD_TTMONO)
                        if not rawget(_G, "TR_OLD_TTMONO") then
                            if a.tt_mono ~= nil and tt < a.tt_mono then tt = a.tt_mono end
                            a.tt_mono = tt
                        end
                        -- (a shot - MacTusk's dart: what flies is the dart, not it - by the clock, not by how far
                        -- on it is)
                        if sim.straight and #(sim.anims or {}) == 1 then tt = t end
                    end
                    -- (one its brain runs (sim.fixed), the server telling it runs none now: not a charge -
                    -- the Rook's run from you, its attack spent (RookBrain Dodge, RunAway), the same
                    -- run_start and run, drawn as a lane at you while it ran off: 886 of its 1049 frames
                    -- drawn in with no strike. Nothing while it stands pawing; running, it still rams
                    -- what's ahead of it (SGrook DoRamAOE): only that - from where it is, the way it
                    -- faces, RAM_FLEE on)
                    local no_ram, flee_log = sim.fixed and SimMoves.PoseNoRam(ent), nil
                    -- (running: faster than 2 a second - and on till it's been slower for 3 frames
                    -- running, not gone for a frame where it's seen in the same spot twice; looked at
                    -- all along, not only once it's told running off: its lane gone for 2-3 frames then)
                    if sim.fixed then
                        local lm = a.flee_at
                        if lm == nil or now > lm.t then
                            if lm ~= nil then
                                local fast = ((x - lm.x) ^ 2 + (z - lm.z) ^ 2) > (2 * (now - lm.t)) ^ 2
                                a.flee_slow = fast and 0 or (a.flee_slow or 3) + 1
                            end
                            a.flee_at = { t = now, x = x, z = z }
                        end
                    end
                    if no_ram then
                        if (a.flee_slow or 3) < 3 then
                            -- (one that rams only what's ahead of it (sim.front - SGrook DoRamAOE, 75 either
                            -- way): its lane begun its reach on, none of it behind it - 190 of the 191 frames
                            -- left drawn in with no strike, you 1 or more behind it)
                            local fwd = sim.front and (sim.gore or 0) * RAM_FLEE_FWD or 0
                            ox, oz, aim_rot, len = x + fwd * math.cos(rot), z - fwd * math.sin(rot), rot, RAM_FLEE
                            -- (its near end striking now, the rest to come as it gets there)
                            tt = (sim.first or sim.lock or 0) * FRAMES
                            no_ram = false
                            -- (its own log: laid afresh each frame where it is, not its charge's line)
                            a.flee_log = a.flee_log or {}
                            flee_log = a.flee_log
                        end
                    end
                    -- (all it strikes by put down now, and here - the Klaus deer's circles: they're drawn
                    -- themselves, just where they are; not this too, a ring just off them flickering)
                    local put_down = false
                    -- (all it strikes by is what it puts down at random, each drawn as it comes - the
                    -- Celestial Champion's crystals, anywhere round it: where they may fall, laid out
                    -- towards you, turned after you and fell elsewhere - not drawn)
                    -- (only things that show themselves well before they strike (their delay) - not ones striking as
                    -- they come up: Deerclops' ice spikes, there and striking the same frame - its swipe drawn as
                    -- nothing at all till then, no warning, the player's report 2026-10-20 (555 of 670 goes on the
                    -- bench drew nothing). Those: drawn as where it may strike, till they're down (below).
                    -- TR_OLD_THINGSONLY: as before)
                    if sim.things_only and sim.puts ~= nil then
                        put_down = true
                        for _, p in ipairs(sim.puts) do
                            local hz = SimMoves.Hazards()[p]
                            if hz == nil or hz.in_move then put_down = false end
                            -- (10 frames: a third of a second shown before it strikes, at the least)
                            if hz ~= nil and (hz.delay or 0) < 10 and not rawget(_G, "TR_OLD_THINGSONLY") then put_down = false end
                        end
                    end
                    if not put_down and sim.puts ~= nil and sim.set_until ~= nil and t > (sim.set_until + 2) * FRAMES and Predict.made_hazards ~= nil then
                        for thing in pairs(Predict.made_hazards) do
                            if thing:IsValid() then
                                for _, p in ipairs(sim.puts) do
                                    -- (one drawn on its own - not one only ever drawn with its move: a laser)
                                    local hz = SimMoves.Hazards()[p]
                                    if thing.prefab == p and hz ~= nil and not hz.in_move then
                                        local hx, _, hz = thing.Transform:GetWorldPosition()
                                        if (hx - x) ^ 2 + (hz - z) ^ 2 < 30 * 30 then put_down = true end
                                    end
                                end
                            end
                            if put_down then break end
                        end
                    end
                    -- (one that goes its whole way unless it strikes first (straight): struck - into
                    -- its animations after flying - it's over. The Rabbit King bouncing back off you
                    -- was taken for going the other way: its lane drawn behind it, 12 back in a frame)
                    if sim.straight and sim.anims ~= nil and ent.AnimState ~= nil
                        and not ent.AnimState:IsCurrentAnimation(sim.anims[1]) and not ent.AnimState:IsCurrentAnimation(sim.anims[2] or sim.anims[1])
                        -- (one shot off on its own - MacTusk's dart, one animation: on till it's flown its way,
                        -- the animation over long before - its far end went yellow and never red)
                        and not (#sim.anims == 1 and t <= (sim.first or 0) * FRAMES + (sim._full or 0) / (sim.speed or 6) + LINGER_SHOT) then
                        put_down = true
                    end
                    -- (it and the one begun alike, drawn as one shape where they're laid alike - SimMoves.MergeBegin)
                    SimMoves.MergeBegin()
                    if not put_down and not a.untargeted and not a.aborted and not no_ram and not (a.tell_wait ~= nil and now <= a.tell_wait) then
                        Note(ent, "old", a.move, tt, sim.lock, a.locked ~= nil, a.log)
                        -- (counted for the replays: drawn as one move, then taken for another in the same go -
                        -- the wrong one flashed first, Retinazor's charge as it began its laser; TR_FLIP)
                        local flip = nil
                        if flip ~= nil and a.drawn_move ~= nil and a.drawn_move ~= a.move then
                            local k = string.format("%s %s>%s@%d", ent.prefab or "?", a.drawn_move.name or "?", a.move.name or "?", math.floor((now - a.t0) / FRAMES + .5))
                            flip[k] = (flip[k] or 0) + 1
                        end
                        a.drawn_move = a.move
                        -- (one going its whole way, still aiming: no nearer than faint red - turning after you,
                        -- its yellow went off one side and never red)
                        SimMoves.maybe = sim.straight and a.locked == nil or nil
                        -- (one that only shoots a dart flying straight: its lane at you till it shoots - SimMoves.DrawShot)
                        if sim.shoots ~= nil then
                            if aim ~= nil and aim.me then danger = SimMoves.DrawShot(sim, ox, oz, aim_rot, tt, px, pz) or danger end
                        else
                            SimMoves.dt_add = a.fall_left
                            danger = SimMoves.Draw(sim, ox, oz, aim_rot, aim, my_radius, px, pz, tt, flee_log or a.log, ent, target, len) or danger
                            SimMoves.dt_add = nil
                        end
                        SimMoves.maybe = nil
                        -- (one that goes for every player in reach at once (sim.multi, how far) - the
                        -- Klaus deer's spells: under each of them too, not only the one it's after)
                        Predict.EachOther(ent, sim, target, function(p, q)
                            a.multi_logs = a.multi_logs or {}
                            a.multi_logs[p] = a.multi_logs[p] or {}
                            local qrot = math.atan2(-(q.z - oz), q.x - ox)
                            danger = SimMoves.Draw(sim, ox, oz, qrot, q, my_radius, px, pz, tt, a.multi_logs[p], ent, q, len) or danger
                        end)
                    end
                    -- (not yet told from the one begun alike that stays put - the stomp: that too,
                    -- round where it is, towards its target)
                    -- (not one that strikes just the same, from the same spot, only a later form of it -
                    -- Armored Bearger's pound, staggering after or not: drawn twice over, its edges
                    -- doubled and jagged)
                    if a.alt and a.alt.sim ~= nil and not (a.tell_wait ~= nil and now <= a.tell_wait) and not (SameShape(a.alt.sim, sim) and ox == x and oz == z and (a.alt.sim.after_anim ~= nil or sim.after_anim ~= nil)) then
                        local arot = rot
                        if target ~= nil and ((target.x - x) ^ 2 + (target.z - z) ^ 2) > .01 then
                            arot = math.atan2(-(target.z - z), target.x - x)
                        end
                        -- (aimed only till its own lock, as the game does - after it, the way it faced then:
                        -- it went on turning after you all along, struck or not - the Celestial Champion's
                        -- chop drawn a second time beside the summon, swinging round with you)
                        local alock = a.alt.sim.lock
                        -- (none, but what it strikes by put down from its first strike on (sim.first, sim.set_until) - aimed till then: Uncompromising Mode's Glacial Hound ice howl, its spikes set by
                        -- frame 19, drawn turning after you on and on beside the bite, a second lane as you walk.
                        -- TR_OLD_ALTLOCK: as before)
                        if alock == nil and a.alt.sim.set_until ~= nil and not rawget(_G, "TR_OLD_ALTLOCK") then alock = math.min(a.alt.sim.first or a.alt.sim.set_until, a.alt.sim.set_until + 1) end
                        if alock ~= nil and t >= alock * FRAMES then
                            if a.alt_rot == nil or a.alt_rot_for ~= a.alt then a.alt_rot, a.alt_rot_for = arot, a.alt end
                            arot = a.alt_rot
                            -- (aimed alike till then: the way it locked, the same as its own - drawn as one)
                            if sim.lock == alock and math.abs((arot - aim_rot + math.pi) % (2 * math.pi) - math.pi) < 3 * DEGREES then arot = aim_rot end
                        end
                        a.alt_log = a.alt_log or {}
                        Note(ent, "the one begun alike, too (offline map)", a.alt, t)
                        -- (counted for the replays: two shapes of one boss drawn at once - the Twins' charge with their shot, a player's report; TR_BOTH)
                        -- (not one that draws nothing - the Eye's shot (moves_hand_um, maps {}): 128 frames counted, none drawn, 2026-10-19)
                        local both = rawget(_G, "TR_BOTH") if both ~= nil and not (a.alt.sim.nothing and #(a.alt.sim.maps or {}) == 0) then local k = (ent.prefab or "?") .. (a.alt_always and " (always)" or "") both[k] = (both[k] or 0) + 1 end
                        SimMoves.maybe = true
                        danger = SimMoves.Draw(a.alt.sim, x, z, arot, target, my_radius, px, pz, t, a.alt_log, ent, target) or danger
                        SimMoves.maybe = nil
                    end
                    -- (what it goes on into once it's struck (sim.goes_into, from its offline run): Klaus' bite on into his
                    -- swipe at its frame 49 with you in his reach, the swipe begun 15 frames in and striking a frame on - a
                    -- player's game sees that animation only as it strikes, never drawn, 18 of ~170 blows on the lag bench,
                    -- 2026-10-25. Drawn from 6 frames before, as that move from where he'll begin it, at you - only while you're
                    -- in his reach, as his code asks (SGklaus:667, attack range + your body). TR_OLD_GOESINTO: not)
                    local gi = sim.goes_into
                    if gi ~= nil and not rawget(_G, "TR_OLD_GOESINTO") and target ~= nil and target.me and r ~= nil and r.attack ~= nil then
                        local fnow = t / FRAMES
                        local reach = r.attack + (my_radius or .5)
                        if fnow >= gi.at - 6 and fnow <= gi.at + 1 and (target.x - x) ^ 2 + (target.z - z) ^ 2 <= reach * reach then
                            -- (the one of its own size - Klaus enraged)
                            local nm = nil
                            for _, m in ipairs(moves) do
                                if m.anims[1] == gi.anim and m.sim ~= nil and (nm == nil or (m.sim.scale or 1) == (sim.scale or 1)) then nm = m end
                            end
                            if nm ~= nil then
                                a.goes_log = a.goes_log or {}
                                danger = SimMoves.Draw(nm.sim, x, z, math.atan2(-(target.z - z), target.x - x), target, my_radius, px, pz,
                                    (gi.from + fnow - gi.at) * FRAMES, a.goes_log, ent, target) or danger
                            end
                        end
                    end
                    SimMoves.MergeEnd()
                elseif any and own then
                    local k = hit_at ~= nil and t / math.max(hit_at, FRAMES) or nil
                    Note(ent, "learned from the server (not run offline)", a.move, t)
                    danger = Shape(learned, r.hit, my_radius, x, z, rot, a, k, px, pz, false, target) or danger
                end
                -- (where you standing makes it go on into another of its moves - a combo's next swipe
                -- while you're still in front of it, in reach: lightly, from BRANCH_LEAD frames before
                -- it looks to then, round where it is and the way it faces - true_range/moves_table
                -- _branches; not counted as standing in harm's way)
                local brs = a.move.name ~= nil and Tables._branches ~= nil and Tables._branches[ent.prefab] ~= nil
                    and Tables._branches[ent.prefab][a.move.name] or nil
                for _, b in ipairs(brs or {}) do
                    if t >= (b.at - BRANCH_LEAD) * FRAMES and t <= (b.at + 1) * FRAMES then
                        Note(ent, "branch", a.move, t, b.at)
                        for _, cells in pairs(b.zones) do
                            branch_cells[cells] = branch_cells[cells] or { cells = cells }
                            -- (testing: TR_ASIDE while it's drawn - the replays don't take it for the
                            -- move's own shape)
                            rawset(_G, "TR_ASIDE", true)
                            SimMoves.DrawCells(branch_cells[cells], x, z, rot, px, pz, "fill_light")
                            rawset(_G, "TR_ASIDE", nil)
                        end
                    end
                end
                -- what usually comes next, if that's a charge or a beam: along where it faces now
                -- (also while one charge winds down into the next: drawn over the end of it)
                local turned = math.abs(((rot - a.rot) + math.pi) % (2 * math.pi) - math.pi) > TURN
                local nxt = learned ~= nil and a.move.sim == nil and not learned.shared and Leads(learned_all, learned, turned) or nil
                if nxt ~= nil and not charge then
                    Note(ent, "what usually comes next (a charge, a beam)", a.move, t)
                    danger = Shape(nxt, r.hit, my_radius, x, z, rot, nil, nil, px, pz, true, target) or danger
                end
            end
            -- (a move over before its last strike - lasers burning on: as it was laid out, to the end)
            local f = after[ent]
            -- (not when what it went on into is the rest of it - its wind-up over, the slam itself
            -- begun (the Werepig's): that one is drawn, as itself - its slam drawn twice, the
            -- wind-up's where it began)
            if f ~= nil and a ~= nil and f ~= a then
                for _, an in ipairs(f.move.anims or {}) do
                    -- (not the same move begun again - the Ancient Guardian's next leap begun as the last one's outer ring was
                    -- still to strike, 0.17 s on (groundpounder ringDelay): that ring undrawn, TR_OLD_ENDLINGER)
                    if an == a.move.anims[1] and (a.move ~= f.move or rawget(_G, "TR_OLD_ENDLINGER")) then after[ent], f = nil, nil break end
                end
            end
            if f ~= nil and f ~= a then
                local sim = f.move.sim
                local tab = TableOf(ent.prefab, f.move)
                if (f.tail_until == nil and now - f.t0 > (tab ~= nil and tab.last or LastStrike(sim)) * FRAMES + LINGER)
                    or (f.tail_until ~= nil and now > f.tail_until) then
                    after[ent] = nil
                elseif tab ~= nil then
                    Note(ent, "after", f.move, now - f.t0)
                    -- (over before its deciding frame: where its target was last seen)
                    if f.tab_hist ~= nil and #f.tab_hist > 0 then
                        f.tab_aims = f.tab_aims or {}
                        for _, dec in ipairs(Decides(tab)) do
                            if f.tab_aims[dec] == nil then
                                f.tab_aims[dec] = f.tab_hist[#f.tab_hist]
                                -- (and gone with only so far, after it: tab.follow)
                                if f.tab_from ~= nil and tab.follow ~= nil then f.tab_aims[dec] = Followed(f, tab, f.tab_aims[dec]) end
                            end
                        end
                    end
                    danger = DrawTable(ent, f, tab, math.max(0, now - f.t0 - ANIM_LEAD), nil, my_radius, px, pz) or danger
                -- (its blows set going for later, round itself (SimMoves._tail, sim.around): drawn round it as it is now, the
                -- way it faces - its steps go only with its animation, gone with it)
                elseif f.tail_until ~= nil and sim.around ~= nil then
                    Note(ent, "after", f.move, now - f.t0)
                    local tx, _, tz = ent.Transform:GetWorldPosition()
                    local trot = ent.Transform:GetRotation() * DEGREES
                    danger = SimMoves.DrawAround(sim, tx, tz, sim.frame == "facing" and trot or (f.around_rot or trot), px, pz, nil, 0) or danger
                else
                    local ox, oz = f.x, f.z
                    -- (over just as it would stop aiming - the Scrappy Werepig's junk still up in the
                    -- air: aimed where its target was last seen)
                    if f.locked == nil and f.hist ~= nil and #f.hist > 0 then
                        local h = f.hist[#f.hist]
                        f.locked = { target = h.target, rot = h.rot, x = h.x, z = h.z }
                    end
                    local aim, aim_rot = f.locked ~= nil and f.locked.target or nil, f.locked ~= nil and f.locked.rot or f.rot
                    if sim.anchor == "lock" and f.locked ~= nil then
                        ox, oz = f.locked.x, f.locked.z
                    end
                    if sim.frame ~= "facing" and aim ~= nil and ((aim.x - ox) ^ 2 + (aim.z - oz) ^ 2) > .01 then
                        aim_rot = math.atan2(-(aim.z - oz), aim.x - ox)
                    end
                    -- (its way set to the nearest 45 degrees as it strikes (sim.snap45 - its state's own SnapTo45s): the Rock
                    -- Master's snip aimed straight at you came down up to 22.5 off; 2026-10-26. TR_OLD_SNAP45: as before)
                    if sim.snap45 and aim_rot ~= nil and not rawget(_G, "TR_OLD_SNAP45") then
                        aim_rot = math.floor(aim_rot / (math.pi / 4) + .5) * (math.pi / 4)
                    end
                    f.log = f.log or {}
                    Note(ent, "after", f.move, now - f.t0)
                    if os ~= nil and os.getenv ~= nil and os.getenv("AFTER_DBG") then
                        print(string.format("[true_range] after: %s %s still drawn (%.2fs on), with %s", ent.prefab, f.move.name or "?", now - f.t0, a ~= nil and (a.move.name or "?") or "nothing"))
                    end
                    danger = SimMoves.Draw(sim, ox, oz, aim_rot, aim, my_radius, px, pz,
                        math.max(0, now - f.t0 - ANIM_LEAD), f.log, ent, nil) or danger
                end
            end
        end
    end
    return danger
end

-- Things bosses set off (traps, spikes, lasers - Predict.spawns: boss -> { prefab = version }):
-- what's known of where each hurts, outlined around it. Returns whether you stand in one.
Predict.spawns = {}
local HAZARD = "@hazard"

-- what it sets off that's known from the offline runs (prefab -> true)
Predict.SimHazards = SimMoves.Hazards
-- (which of its SimMoves._land parts it is in now, by the animation playing - nil: none; and when it last played a part's
-- wide_anim (Predict._land_wide, by monster - that animation not its move's own, the move begun again after it))
Predict._land_wide = setmetatable({}, { __mode = "k" })
-- (how many frames a move's run offline stands before it sets off - its first map's path the same as at 0 till then; 0: off
-- at once. Cached)
local starts_still = setmetatable({}, { __mode = "k" })
function Predict._StillFrames(sim)
    local c = starts_still[sim]
    if c == nil then
        c = 0
        local m = (sim.maps ~= nil and sim.maps[1]) or (sim.free ~= nil and sim.free[1]) or nil
        local p = m ~= nil and m.path or nil
        local vals = {}
        if type(p) == "table" then for i = 1, #p do vals[i] = tonumber(p[i]) or 0 end
        elseif type(p) == "string" then for v in p:gmatch("[^,]+") do vals[#vals + 1] = tonumber(v) or 0 end end
        -- (one that never sets off - a bite, a stab, struck where it is as it flies or glides on: 0, led all along - the mini
        -- eyes biting at 4 a second, the lavae's stab)
        for i = 2, #vals do if math.abs(vals[i] - vals[1]) > .05 then c = i - 2 break end end
        starts_still[sim] = c
    end
    return c
end
-- (whether a move's _land list has its own first animation - drawn its own way from the start)
function Predict._LandOwn(list, name, sim)
    local first = sim ~= nil and sim.anims ~= nil and sim.anims[1] or nil
    for _, ld in ipairs(list) do
        if ld.anim == name or (first ~= nil and ld.anim == first) then return true end
    end
    return false
end
function Predict._LandNow(ent, a, list)
    local found = nil
    for _, ld in ipairs(list) do
        if ld.wide_anim ~= nil and ent.AnimState:IsCurrentAnimation(ld.wide_anim) then Predict._land_wide[ent] = (GetTime or GetStaticTime)() end
        if found == nil and ent.AnimState:IsCurrentAnimation(ld.anim) then found = ld end
    end
    return found
end
-- (things struck with in their boss's move, and what else sets each off for real - tools/thing_sources.lua)
do
    local ok, t = pcall(require, "true_range/thing_sources")
    Predict.thing_sources = ok and type(t) == "table" and t or {}
end
-- (whether one's moves were run offline - a boss: its body ring shown)
Predict.HasSim = SimMoves.Has
Predict.Simulated = SimMoves.Has

local function HazardShape(learned_all)
    local m = learned_all[HAZARD]
    if m ~= nil then
        return m
    end
    -- (else the farthest reaching of what it did)
    for _, move in pairs(learned_all) do
        if move.radius > 0 and (m == nil or move.radius > m.radius) then
            m = move
        end
    end
    return m
end

local hazard_seen = setmetatable({}, { __mode = "k" })
Predict.haz_n, Predict.haz_draw_t = 0, 0
local boss_xs, boss_zs = {}, {}  -- (DrawHazards: the bosses near, this frame)
-- (testing: DrawHazards' time by stage, summed - true_range modmain says them every 10s)
Predict.stage = { bosses = 0, ask = 0, quick = 0, quick_miss = 0, full_pre = 0, full = 0, loop = 0,
    things = 0, n_quick = 0, n_full = 0, frames = 0 }
function Predict.DrawHazards(ents, my_radius, me)
    local danger = false
    local s_t0 = os.clock()
    SimMoves.UnionBegin()
    local px, pz = me ~= nil and me.x or nil, me ~= nil and me.z or nil
    local sim_hazards = SimMoves.Hazards()
    -- (where each boss in a move drawn is, or one just out of one - asked once a frame, not once for
    -- every thing on the ground: hundreds of calls to the game a frame)
    local clock = (GetTime or GetStaticTime)()
    local nb = 0
    for b, ended in pairs(move_ended) do
        if b:IsValid() and clock - ended >= 0 and clock - ended < MOVE_GRACE then
            local bx, _, bz = b.Transform:GetWorldPosition()
            nb = nb + 1
            boss_xs[nb], boss_zs[nb] = bx, bz
        end
    end
    for i, list in ipairs(ACTIVE_AFTER) do
        for b, a in pairs(list) do
            if a.move ~= nil and a.move.sim ~= nil and b:IsValid() and not a.untargeted
                and (i == 1 or clock >= cut_until) then
                local bx, _, bz = b.Transform:GetWorldPosition()
                nb = nb + 1
                boss_xs[nb], boss_zs[nb] = bx, bz
            end
        end
    end
    -- (every boss near, of any kind, by its name - whose things these are (their data's by): a thing
    -- struck with in its own boss's move, drawn alone only if that boss is about - a pound's ring is
    -- only a picture, struck with by the Minotaur's leap; the same ring where a rock of Uncompromising
    -- Mode's Bearger comes down, the Koalefant's stomp, never strikes: drawn as the Minotaur's, 5 round,
    -- round every rock - the testbench: in it 47 times, never struck)
    local src = boss_xs.src
    if src == nil then src = {} boss_xs.src = src end
    for k, l in pairs(src) do for q = #l, 1, -1 do l[q] = nil end end
    for b in pairs(anims_seen) do
        if b:IsValid() and b.prefab ~= nil then
            local bx, _, bz = b.Transform:GetWorldPosition()
            -- (and as the one it was run offline as - a nightmare bishop as a bishop)
            for _, name in ipairs({ b.prefab, SimMoves.AliasOf(b.prefab) or false }) do
                if name then
                    local l = src[name]
                    if l == nil then l = {} src[name] = l end
                    l[#l + 1], l[#l + 2] = bx, bz
                end
            end
        end
    end
    -- (testing: modmain's frame timing - each stage's time, for every thing: asking the game where
    -- it is, the quick look (QuickKeep), the whole way (DrawHazard); the bosses first)
    local ST = Predict.stage
    ST.frames = ST.frames + 1
    local s_t = os.clock()
    ST.bosses = ST.bosses + s_t - s_t0
    SimMoves._draw_owner = nil
    for _, ent in ipairs(ents) do
        SimMoves._draw_owner = ent
        local valid = ent:IsValid()
        local learned_all = Legacy.on and valid and Predict.learned[ent.prefab] or nil
        local m = learned_all ~= nil and HazardShape(learned_all) or nil
        local hz_def = valid and sim_hazards[ent.prefab] or nil
        ST.things = ST.things + 1
        -- (its strikes all past, standing still: passed over at once - SimMoves.Spent)
        -- (testing: the stages' times only for the whole way - five looks at the clock for every
        -- thing, hundreds a frame, were a fifth of this loop's time in the game's profile)
        local x, _, z
        if hz_def ~= nil then x, _, z = ent.Transform:GetWorldPosition() end
        -- (nowhere yet - not put anywhere: passed over)
        if x == nil or z == nil then hz_def = nil end
        if hz_def ~= nil and SimMoves.Spent(ent, x, z) then
            ST.n_quick = ST.n_quick + 1
        elseif hz_def ~= nil then
            -- (run offline: where it hits, seen from it)
            local rot = ent.Transform:GetRotation() * DEGREES
            -- (drawn just as last frame: kept so - nothing else gone through; SimMoves.QuickKeep)
            local kept = SimMoves.QuickKeep(ent, x, z, rot, px, pz, clock)
            if kept ~= nil then
                Predict.haz_n = Predict.haz_n + 1
                ST.n_quick = ST.n_quick + 1
                danger = kept or danger
            else
                local d0 = os.clock()
                -- (a laser of a move that's drawn already: not again - unless that move was cut short,
                -- its boss killed or knocked out of it, and the laser burns on; or no boss near is in a
                -- move drawn at all - a pound's ring from the Great Depths Worm's dirt, which has none)
                local in_moves = false
                for k = 1, nb do
                    if (boss_xs[k] - x) ^ 2 + (boss_zs[k] - z) ^ 2 < 40 * 40 then in_moves = true break end
                end
                -- (one struck with in its boss's move, that boss nowhere near: not its doing - nothing
                -- of it to draw; above)
                if not in_moves and hz_def.in_move and hz_def.by ~= nil and #hz_def.by > 0 then
                    local mine = false
                    for _, bp in ipairs(hz_def.by) do
                        local l = src[bp]
                        if l ~= nil then
                            for q = 1, #l, 2 do
                                if (l[q] - x) ^ 2 + (l[q + 1] - z) ^ 2 < 40 * 40 then mine = true break end
                            end
                        end
                        if mine then break end
                    end
                    -- (or one of those setting it off through a component of theirs right where it is -
                    -- the Great Depths Worm's dirt, pounding as the Minotaur does: struck with there too;
                    -- true_range/thing_sources - looked for once, where it first stands)
                    if not mine then
                        local of = boss_xs.src_of
                        if of == nil then of = setmetatable({}, { __mode = "k" }) boss_xs.src_of = of end
                        if of[ent] == nil then
                            of[ent] = false
                            local srcs = Predict.thing_sources ~= nil and Predict.thing_sources[ent.prefab] or nil
                            if srcs ~= nil then
                                local near = Predict.EntsNear ~= nil and Predict.EntsNear(x, z, .5)
                                    or (TheSim ~= nil and TheSim:FindEntities(x, 0, z, .5)) or {}
                                for _, o in ipairs(near) do
                                    for _, p in ipairs(srcs) do if o.prefab == p then of[ent] = true end end
                                end
                            end
                        end
                        mine = of[ent]
                    end
                    -- (as one drawn with its move: none of it alone - DrawHazard's in_move)
                    if not mine then in_moves = true end
                end
                -- (a thing only its own bosses' (hz_def.by), none of them about: not theirs - not drawn at all. The Ancient Hulk's
                -- lasers (its spin, spawnburns) are set off as they're made - at the world's middle, before they're moved out round
                -- it - and strike nothing where they're seen: drawn as the Ancient Robots' (whose do strike), past its ring, the
                -- player 2026-10-21. Not one that lies there a while (lasting - a mine, its boss gone off). TR_OLD_BYONLY: as before)
                -- (looked for once, as it's first seen - anything of those names within 40, seen moving or not)
                -- (a pound that strikes for nothing where it's set off by these (SimMoves._harmless_from): the Great Depths Worm's
                -- dirt pounds as it comes up, its combat's damage never set (worm_boss.lua: SetDefaultDamage commented out) - 0
                -- damage, the biggest ring round every new mound, "it never hurts", the player 2026-10-28. TR_OLD_WORMPOUND)
                local harmless = false
                local hf = SimMoves._harmless_from[ent.prefab]
                if hf ~= nil and not rawget(_G, "TR_OLD_WORMPOUND") then
                    local ho = boss_xs.harmless_of
                    if ho == nil then ho = setmetatable({}, { __mode = "k" }) boss_xs.harmless_of = ho end
                    if ho[ent] == nil then
                        ho[ent] = false
                        local near = Predict.EntsNear ~= nil and Predict.EntsNear(x, z, .5)
                            or (TheSim ~= nil and TheSim:FindEntities(x, 0, z, .5)) or {}
                        for _, o in ipairs(near) do if hf[o.prefab] then ho[ent] = true break end end
                    end
                    harmless = ho[ent]
                end
                local foreign = false
                if not rawget(_G, "TR_OLD_BYONLY") and not hz_def.in_move and not hz_def.lasting and hz_def.by ~= nil and #hz_def.by > 0 then
                    local fo = boss_xs.foreign_of
                    if fo == nil then fo = setmetatable({}, { __mode = "k" }) boss_xs.foreign_of = fo end
                    if fo[ent] == nil then
                        local names = {}
                        for _, bp in ipairs(hz_def.by) do names[bp] = true end
                        local near = Predict.EntsNear ~= nil and Predict.EntsNear(x, z, 40)
                            or (TheSim ~= nil and TheSim:FindEntities(x, 0, z, 40)) or nil
                        if near == nil then
                            fo[ent] = false
                        else
                            -- (another's: one of other names about with moves of its own, none of its own - not one whose boss is
                            -- gone, its last bombs still to burst: the Fused Shadeling's, 10 s after it died, 2 struck so undrawn)
                            local own, other = false, false
                            for _, o in ipairs(near) do
                                if o.prefab ~= nil then
                                    if names[o.prefab] or names[SimMoves.AliasOf(o.prefab) or false] then own = true break end
                                    if SimMoves.Has(o.prefab) then other = true end
                                end
                            end
                            fo[ent] = other and not own
                        end
                    end
                    foreign = fo[ent]
                end
                -- (a warning shadow under a treeguard's throw - its coconut, its snake striking within 1.5 of its middle (FindEntities
                -- 1.5): drawn 3/4 as big as one under the Queen Womant's debris, striking within 2 - one size for both, the palm
                -- treeguard's drawn too big, the player 2026-10-21. Told once, as it's first seen: a treeguard within 30, no queen.
                -- TR_OLD_SHADOWSIZE: as before)
                if ent.prefab == "warningshadow" and not rawget(_G, "TR_OLD_SHADOWSIZE") then
                    SimMoves._k_of = SimMoves._k_of or setmetatable({}, { __mode = "k" })
                    if SimMoves._k_of[ent] == nil then
                        local near = Predict.EntsNear ~= nil and Predict.EntsNear(x, z, 30)
                            or (TheSim ~= nil and TheSim:FindEntities(x, 0, z, 30)) or {}
                        local tg, queen = false, false
                        for _, o in ipairs(near) do
                            if o.prefab == "treeguard" or o.prefab == "jungletreeguard" then tg = true end
                            if o.prefab == "antqueen" then queen = true end
                        end
                        SimMoves._k_of[ent] = (tg and not queen) and .75 or false
                    end
                end
                -- (a warning shadow with something harmless falling on it (Predict.harmless_falls - modmain: the Queen Womant's
                -- eggs): no blow to come there - not drawn. Looked for its first half second, then kept. TR_OLD_EGGSHADOW: as before)
                if not foreign and ent.prefab == "warningshadow" and Predict.harmless_falls ~= nil and not rawget(_G, "TR_OLD_EGGSHADOW") then
                    local ho = boss_xs.harmless_of
                    if ho == nil then ho = setmetatable({}, { __mode = "k" }) boss_xs.harmless_of = ho end
                    local h = ho[ent]
                    if h == nil then h = { t = clock, yes = false } ho[ent] = h end
                    if not h.yes and clock - h.t < .5 then
                        for f in pairs(Predict.harmless_falls) do
                            if f.IsValid ~= nil and f:IsValid() and f.Transform ~= nil then
                                local fx, _, fz = f.Transform:GetWorldPosition()
                                if (fx - x) ^ 2 + (fz - z) ^ 2 < 1 then h.yes = true break end
                            end
                        end
                    end
                    foreign = h.yes
                end
                local made = Predict.made_hazards ~= nil and Predict.made_hazards[ent] or nil
                Note(ent, "hazard", nil, nil, type(made) == "number" and clock - made or nil, in_moves)
                -- (testing: modmain's frame timing - how many things, the time drawing them takes)
                Predict.haz_n = Predict.haz_n + 1
                local f0 = os.clock()
                ST.full_pre = ST.full_pre + f0 - d0
                if not foreign and not harmless then danger = SimMoves.DrawHazard(ent, x, z, rot, px, pz, clock, in_moves) or danger end
                local f1 = os.clock()
                Predict.haz_draw_t = Predict.haz_draw_t + f1 - d0
                ST.full, ST.n_full = ST.full + f1 - f0, ST.n_full + 1
                -- (testing: each thing's first frame looked at - client_log.txt)
                if not hazard_seen[ent] then
                    hazard_seen[ent] = true
                    print(string.format("[true_range] hazard %s looked at (in_moves %s)", ent.prefab, tostring(in_moves)))
                end
            end
        elseif m ~= nil then
            local x, _, z = ent.Transform:GetWorldPosition()
            local rot = ent.Transform:GetRotation() * DEGREES
            danger = Area(m, 0, my_radius, x, z, rot, nil, px, pz, nil, "wave", false) or danger
        end
    end
    -- (round things of a kind, drawn together once all are known - true_range/simmoves)
    SimMoves.UnionDraw()
    ST.loop = ST.loop + os.clock() - s_t0
    return danger
end

return Predict
