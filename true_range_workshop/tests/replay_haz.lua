-- luajit replay_haz.lua <mod root> <client_log.txt> [-v]
-- The things bosses set off, as the server traced them ([tr_haz] lines: each thing's position and
-- facing every tick, where you were; HIT: one of its own blows landed on you), drawn frame by
-- frame through the mod's own Predict.DrawHazards - and every hit checked: were you inside what
-- was drawn of them then? (A thing that's part of its boss's move, drawn with that, is checked
-- by replay.lua with the boss.)
-- (the mod's log lines, off in the game unless debugging (true_range modmain: debug.txt): on here)
rawset(_G, "TR_DEBUG", true)
package.path = arg[1] .. "/scripts/?.lua;" .. package.path
if os.getenv("GC_STOP") then collectgarbage("stop") end
DEGREES, FRAMES = math.pi / 180, 1 / 30
local now = 0
GetStaticTime = function() return now end
GetTime = GetStaticTime
function GetTableSize(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end
function DiffAngle(a, b) local d = math.abs(a - b) % 360 return d > 180 and 360 - d or d end
local pieces = 0
local function P() pieces = pieces + 1 end
kinds = {}
local SI = { tri = 7, puttri = 2, putseg = 2, seg = 5 }
local function K(n) return function(...) pieces = pieces + 1 local st = SI[n] and select(SI[n], ...) or "" local key = n .. ":" .. tostring(st) kinds[key] = (kinds[key] or 0) + 1 end end
haz_time, haz_mem, haz_frames, haz_pieces = 0, 0, 0, 0
-- (ENGINE_CALLS=1: the mod's own true_range/lines, its pieces as stand-ins that count every call
-- made to the game - per frame, said at the end; NO_GROUPS=1: as without groups)
engine_calls, engine_entities, engine_asked = 0, 0, 0
all_ents = {}
-- (UNION_FULL=1: a round thing's arcs all gone through each time, not only where they changed)
if os.getenv("UNION_FULL") then TR_UNION_FULL = true end
-- (UNION_EVERY=1: each round thing's arcs worked out every frame, not every other)
if os.getenv("UNION_EVERY") then TR_UNION_EVERY = true end
-- (UNION_NOEXIT=1: every one within reach looked at, not stopping once covered all round)
if os.getenv("UNION_NOEXIT") then TR_UNION_NOEXIT = true end
if os.getenv("ENGINE_CALLS") then
    engine_by = {}
    local counter = setmetatable({}, { __index = function(_, k) return function() engine_calls = engine_calls + 1 engine_by[k] = (engine_by[k] or 0) + 1 end end })
    CreateEntity = function()
        engine_entities = engine_entities + 1
        local e = { lx = 0, lz = 0, rot = 0, sx = 1, sy = 1, vis = true }
        all_ents[#all_ents + 1] = e
        -- (what it shows, kept for HAZ_PIC: its picture, stretch, colour, sort order)
        e.AnimState = setmetatable({
            SetPercent = function(_, a) engine_calls = engine_calls + 1 e.anim = a end,
            SetScale = function(_, a, b) engine_calls = engine_calls + 1 engine_by.SetScale = (engine_by.SetScale or 0) + 1 e.sx, e.sy = a, b end,
            SetMultColour = function(_, r, g, b, a) engine_calls = engine_calls + 1 engine_by.SetMultColour = (engine_by.SetMultColour or 0) + 1 e.colour = { r, g, b, a } end,
            SetSortOrder = function(_, s) engine_calls = engine_calls + 1 engine_by.SetSortOrder = (engine_by.SetSortOrder or 0) + 1 e.sort = s end }, { __index = counter })
        -- (its place and turning kept - a child turned with its parent, as the game does: Lines.TurnTest)
        e.entity = setmetatable({ SetParent = function(_, pe) engine_calls = engine_calls + 1 engine_by.SetParent = (engine_by.SetParent or 0) + 1 e.parent = pe.owner end }, { __index = counter })
        e.entity.owner = e
        e.Transform = setmetatable({
            SetPosition = function(_, x, _, z) engine_calls = engine_calls + 1 engine_by.SetPosition = (engine_by.SetPosition or 0) + 1 e.lx, e.lz = x, z end,
            SetRotation = function(_, d) engine_calls = engine_calls + 1 engine_by.SetRotation = (engine_by.SetRotation or 0) + 1 e.rot = d end,
            GetWorldPosition = function()
                local x, z = e.lx, e.lz
                local p = e.parent
                while p ~= nil do
                    local r = math.rad(p.rot)
                    x, z = p.lx + x * math.cos(r) + z * math.sin(r), p.lz - x * math.sin(r) + z * math.cos(r)
                    p = p.parent
                end
                return x, 0, z
            end }, { __index = counter })
        function e:AddTag() end
        function e:IsValid() engine_calls = engine_calls + 1 engine_by.IsValid = (engine_by.IsValid or 0) + 1 return true end
        function e:Show() e.vis = true engine_calls = engine_calls + 1 local i = debug.getinfo(2, "Sl") local k = "Show@" .. i.short_src:match("[^/\\]+$") .. ":" .. i.currentline engine_by[k] = (engine_by[k] or 0) + 1 end
        function e:Remove() engine_calls = engine_calls + 1 engine_entities = engine_entities - 1 e.vis = false e.removed = true end
        function e:Hide() e.vis = false engine_calls = engine_calls + 1 local i = debug.getinfo(2, "Sl") local i3 = debug.getinfo(3, "Sl") local k = "Hide@" .. i.short_src:match("[^/\\]+$") .. ":" .. i.currentline .. "<" .. (i3 and i3.currentline or 0) engine_by[k] = (engine_by[k] or 0) + 1 end
        return e
    end
    ANIM_ORIENTATION, LAYER_BACKGROUND, LAYER_GROUND = { OnGround = 1 }, 4, 3
    local L = require("true_range/lines")
    if os.getenv("NO_GROUPS") then L.GroupFor = nil end
    -- (made ahead, as the game does while you wait for the boss - PREWARM=0: not)
    if os.getenv("PREWARM") ~= "0" then L.Warm(1e9) end
    made0, laid0f = L.created, L.laid or 0
    -- (a thing drawn, skipped a frame, drawn again: its group let go and taken back - said by kind)
    local gf, last_f, gap_by = L.GroupFor, setmetatable({}, { __mode = "k" }), {}
    regroup_by = gap_by
    if gf ~= nil then L.GroupFor = function(slot, key)
        local f = math.floor(now * 30 + .5)
        local lf = last_f[slot]
        if lf ~= nil and lf < f - 1 and lf >= f - 5 then
            local k = (type(slot) == "table" and slot.prefab) or "move"
            gap_by[k] = (gap_by[k] or 0) + 1
        end
        last_f[slot] = f
        local g = gf(slot, key)
        if g.sig == nil then local k = ((type(slot) == "table" and slot.prefab) or "move") .. (g.parent and "" or "") regroup_new = regroup_new or {} regroup_new[k] = (regroup_new[k] or 0) + 1 end
        return g
    end end
else
package.loaded["true_range/lines"] = { TriRecs = function(a, b, c, d, e, f, out) out[#out + 1] = {} out[#out + 1] = {} end,
    SegRec = function() return {} end, PutTri = K("puttri"), PutSeg = K("putseg"), Begin = function() end,
    End = function() end, Pulse = function() end, Segment = K("seg"), Shape = K("shape"), Tri = K("tri"),
    Disc = K("disc"), Wedge = K("wedge"), _styles = {} }
end
local verbose = false
for i = 1, #arg do if arg[i] == "-v" then verbose = true end end
local real_print = print
print = function(...) if verbose then real_print(...) end end
-- (HAZ_FROM=<t> HAZ_TO=<t>: a piece of a long log - run from 5 s before it (what was set off before,
-- lying there), counted only from HAZ_FROM to before HAZ_TO; the pieces side by side, a core each,
-- add up to the whole: tests/bench_replay.ps1. Kept: only that stretch's things - share026's 11 GB)
local HAZ_FROM = tonumber(os.getenv("HAZ_FROM") or "") or -math.huge
local HAZ_TO = tonumber(os.getenv("HAZ_TO") or "") or math.huge
local HAZ_LEAD = 5
local function InPiece(t) return t >= HAZ_FROM and t < HAZ_TO end
-- (TR_MODS=<folder names>: those mods on - their monsters' moves over the game's, as the game lays them: true_range/moddata)
-- (the drawer's own switches back to before, from the shell: TR_OLD_LAND=1 ... - as the game reads them, globals)
for _, n in ipairs({ "TR_OLD_BYONLY", "TR_OLD_ENDLINGER", "TR_OLD_LANEROW", "TR_OLD_AROUNDONCE", "TR_OLD_AROUNDFACE", "TR_OLD_SHADOWSIZE", "TR_OLD_LAND", "TR_OLD_FALL", "TR_OLD_AGAIN", "TR_OLD_LANE", "TR_OLD_PENGUIN", "TR_OLD_LOB", "TR_OLD_LEAD", "TR_OLD_STILL", "TR_OLD_EARLY", "TR_OLD_HOP", "TR_OLD_LANDS", "TR_OLD_MOVEDDELAY", "TR_OLD_LEADAVG", "TR_OLD_HAZLEAD", "TR_OLD_HAZSTEADY", "TR_OLD_AIMLEAD", "TR_OLD_MIDLEFT", "TR_OLD_RELOCK", "TR_OLD_BODYLEAD", "TR_OLD_LIVERADIUS", "TR_OLD_DISCKEY", "TR_OLD_TAIL", "TR_OLD_LAND2", "TR_OLD_PREVLEG", "TR_OLD_SNAPPOS", "TR_OLD_CHAINLAST", "TR_OLD_WORMDIRT", "TR_OLD_LEADSTOP", "TR_OLD_LEADTP", "TR_OLD_LANDHOLD", "TR_OLD_LANDKEEP", "TR_OLD_GLOWPULSE", "TR_OLD_GLOWGRACE", "TR_OLD_AIRSTILL", "TR_OLD_GLOWOVERLAP", "TR_OLD_LEADTPSTEP", "TR_OLD_LANDSTOP", "TR_OLD_GLOWHOLD", "TR_OLD_LANDTILL", "TR_OLD_LANDAT", "TR_OLD_HUNTSTICK", "TR_OLD_LANDLOOSE", "TR_OLD_GLOWAFTERMOVE", "TR_OLD_WORMPOUND", "TR_OLD_WENT", "TR_OLD_WENTSTART", "TR_OLD_TWIN", "TR_OLD_STAYLEAD", "TR_OLD_LANDNOW", "TR_OLD_LOWAIR", "TR_OLD_POSEGO", "TR_OLD_R2FROM", "TR_OLD_JUMPLED", "TR_OLD_LOWAIRROSE", "TR_OLD_AIRDUP", "TR_OLD_LANDFIRST", "TR_OLD_WIDENET", "TR_OLD_TPPRE", "TR_OLD_SPATSNOT", "TR_OLD_NEAR", "TR_OLD_BEARSHOOT", "TR_OLD_LEADDUP", "TR_OLD_LEAPWARP", "TR_OLD_STARTLEAD", "TR_OLD_THINGWAIT", "TR_OLD_THINGNEW", "TR_OLD_LEADSTOP2", "TR_OLD_CHASELEAD", "TR_OLD_LANDWAIT", "TR_OLD_PICKEPIC", "TR_OLD_AIMFACING", "TR_OLD_LANDAVG", "TR_OLD_HAZLEADMOVED", "TR_OLD_FALLBACKANY", "TR_OLD_KEEPHEADING", "TR_OLD_HAZFAST", "TR_OLD_TRAILWAIT", "TR_OLD_MIRROR", "TR_OLD_HOMES", "TR_OLD_AIRDUP", "TR_OLD_AIRDUPHOST", "TR_OLD_MOONMINE", "TR_OLD_LEGRAW", "TR_OLD_ANIMFROM", "TR_OLD_STINGSHOT", "TR_OLD_LASTFIRST" }) do if os.getenv(n) then rawset(_G, n, true) end end

-- (and every other the mod reads, found in its own code - the list above kept by hand missed new ones (LASTFIRST: an A/B the
-- same to the digit, 2026-10-30))
do
    local files = { arg[1] .. "/modmain.lua" }
    local p = io.popen('dir /b "' .. (arg[1]:gsub("/", "\\")) .. [[\scripts\true_range\*.lua" 2>nul]])
    if p ~= nil then for f in p:lines() do files[#files + 1] = arg[1] .. "/scripts/true_range/" .. f end p:close() end
    for _, f in ipairs(files) do
        local h = io.open(f, "rb")
        if h ~= nil then
            for n in h:read("*a"):gmatch('"(TR_OLD_[%w_]+)"') do if os.getenv(n) then rawset(_G, n, true) end end
            h:close()
        end
    end
end
rawset(_G, "TR_JUMP", {}) if os.getenv("JUMP_V") then rawset(_G, "TR_JUMP_EV", {}) end
-- (where each thrown thing is drawn coming down, how far it moved frame to frame - simmoves TR_LANDWOB)
rawset(_G, "TR_LANDWOB", {}) if os.getenv("LANDWOB_V") then rawset(_G, "TR_LANDWOB_EV", {}) end
rawset(_G, "TR_GAP", {})
if os.getenv("GAP_V") then rawset(_G, "TR_GAP_EV", {}) end
-- (TRACE_GUID=<guid>: what the drawer made of that one thing, frame by frame - SimMoves._Trace)
if os.getenv("TRACE_GUID") then rawset(_G, "TR_TRACE_GUID", tonumber(os.getenv("TRACE_GUID"))) rawset(_G, "TR_TRACE_EV", {}) end
if os.getenv("TR_MODS") then require("true_range/moddata").Apply(function(n) return os.getenv("TR_MODS"):find(n, 1, true) ~= nil end) end
local Predict = require("true_range/predict")
-- (LAND_WAIT=n LAND_HOLD=r: the landing's wait and hold tried otherwise - simmoves _land_wait, _land_hold)
do
    local SMl = require("true_range/simmoves")
    if os.getenv("LAND_WAIT") then SMl._land_wait = tonumber(os.getenv("LAND_WAIT")) end
    if os.getenv("LAND_HOLD") then SMl._land_hold = tonumber(os.getenv("LAND_HOLD")) end
    if os.getenv("LAND_SOON") then SMl._land_soon = tonumber(os.getenv("LAND_SOON")) end
end
function SimMovesHazard(prefab) return require("true_range/simmoves").Hazards()[prefab] end

-- the trace: per thing (by GUID), its positions tick by tick; and the hits
local tracks, hits = {}, {}
local any_hit = {}   -- (every blow that landed on you, a boss's own too: a "drawn in" with none near is false)
local last_t = nil  -- (the game's clock, as the last traced line had it)
local struck = {}   -- (the mod's own "you were struck by" - a blow from what isn't traced: the worm's dirt)
local my_pos = nil  -- (where you were, as the last traced line had it)
local hurts = {}    -- (every loss of health the testbench saw, [tr_hurt] - fire's among them)
local first_seen = {}  -- (guid -> its first line's time, kept or not)
-- (the lines the later passes go through - a boss's trace, its surroundings, the mod's word - kept as
-- this first read goes: not the whole log read three more times; VERIFY_PLAN 6.15. OLD_READ=1: as before)
local OLD_READ = os.getenv("OLD_READ") ~= nil
local MAIN_LINES = {}
local function MainLines()
    if OLD_READ then return io.lines(arg[2]) end
    local i = 0
    return function() i = i + 1 return MAIN_LINES[i] end
end
for line in io.lines(arg[2]) do
    if not OLD_READ then
        local c = line:find("[tr", 1, true)
        if c ~= nil and line:find("[tr_haz]", c, true) ~= c then MAIN_LINES[#MAIN_LINES + 1] = line end
    end
    local ht = line:match("%[tr_trace%] ([%d%.]+) [%w_]+ HIT ")
    if ht ~= nil then any_hit[#any_hit + 1] = tonumber(ht) end
    local lt = line:match("%[tr_%a+%] ([%d%.]+) ")
    if lt ~= nil then last_t = tonumber(lt) end
    -- (harm straight to health, no blow - fire burning on you (Health:DoFireDamage: cause "fire" or
    -- the burner's prefab, a second after it first catches - fire_timestart): the testbench's [tr_hurt];
    -- a blow's own hurt is told apart below, by the HIT with it. OLD_HURT=1: as before, not counted)
    local hu_t, hu_by, hu_c = line:match("%[tr_hurt%] ([%d%.]+) (%S+) .-cause=(%S+)")
    -- (and health taken straight off by a thing, no one's blow - "?" its attacker: UM's lightning, cursed fire, TE's jellyfish
    -- (health:DoDelta) - counted nowhere till 2026-10-30, 884 of a bench's 952 inside a cursed fire. OLD_NOATTACKER=1: not)
    if hu_t ~= nil and not os.getenv("OLD_HURT") and (hu_c == "fire" or hu_c == hu_by or (hu_by == "?" and not os.getenv("OLD_NOATTACKER"))) then hurts[#hurts + 1] = { t = tonumber(hu_t), by = hu_by, cause = hu_c } end
    local by, d = line:match("you were struck by ([%w_]+), ([%d%.]+) from it")
    if by ~= nil and last_t ~= nil then
        any_hit[#any_hit + 1] = last_t
        struck[#struck + 1] = { t = last_t, by = by, d = tonumber(d) }
    end
    local t, prefab, guid, rest = line:match("%[tr_haz%] ([%d%.]+) ([%w_]+) guid=(%d+) (.*)$")
    -- (a piece: only its stretch kept - each thing's first sight kept all the same, its age as old as it is)
    if t ~= nil and first_seen[guid] == nil and not rest:find("^HIT") and not rest:find("^GONE") then first_seen[guid] = tonumber(t) end
    if t ~= nil and (tonumber(t) < HAZ_FROM - HAZ_LEAD or tonumber(t) > HAZ_TO + 1) then t = nil end
    if t ~= nil then
        t = tonumber(t)
        local x, z = rest:match("pos=([%d%.%-]+),([%d%.%-]+)")
        local yx, yz = rest:match("you=([%d%.%-]+),([%d%.%-]+)")
        if rest:find("^HIT") then
            -- (on someone else - a friend 13 off, struck by a missile of their own: not yours; the
            -- mod draws what's round you)
            local mine = my_pos == nil or (tonumber(yx) - my_pos[1]) ^ 2 + (tonumber(yz) - my_pos[2]) ^ 2 < 1.5 * 1.5
            if mine then
                any_hit[#any_hit + 1] = t
                hits[#hits + 1] = { t = t, prefab = prefab, x = tonumber(yx), z = tonumber(yz), bx = tonumber(x), bz = tonumber(z) }
            end
        elseif x ~= nil then
            if yx ~= nil then my_pos = { tonumber(yx), tonumber(yz) } end
            local tr = tracks[guid]
            if tr == nil then tr = { prefab = prefab, ticks = {} } tracks[guid] = tr end
            tr.ticks[#tr.ticks + 1] = { t = t, x = tonumber(x), z = tonumber(z), rot = tonumber(rest:match("rot=([%d%.%-]+)")),
                yx = tonumber(yx), yz = tonumber(yz), y = tonumber(rest:match(" y=([%d%.%-]+)")),
                scale = tonumber(rest:match("scale=([%d%.%-]+)")) }
        end
    end
end
-- (a hit the boss's own combat dealt through a thing of its - the Scrappy Werepig's junk: the
-- trace has the boss hitting you, 20 away - is that thing's: the nearest of its things to you
-- then, within 3.5, the boss over 6 off; not one already traced as the thing's own HIT)
do
    local Hz = require("true_range/simmoves").Hazards() or {}
    -- (and modmain's DARTS that name their boss (by): shot by its combat, the game putting their blows down to it - Tropical
    -- Experience's lizardman's spit, 15 of them "missed" with the spit right on you: as_boss, as a thing of the data's.
    -- tests/replay.lua the same. OLD_DART_ASBOSS=1: not)
    if not os.getenv("OLD_DART_ASBOSS") then
        local mf = io.open(arg[1] .. "/modmain.lua", "rb")
        local src = mf and mf:read("*a") or ""
        if mf then mf:close() end
        local merged = setmetatable({}, { __index = Hz })
        for name, body in (src:match("local DARTS = (%b{})") or ""):gmatch("([%w_]+) = (%b{})") do
            local by = body:match('by = "([%w_]+)"')
            if by ~= nil then
                -- (one the data has as a thing too - Uncompromising Mode's guards' stinger: that, its boss added, as_boss)
                local h0 = Hz[name]
                local h = {}
                for k, v in pairs(h0 or {}) do h[k] = v end
                local bys = { by }
                for _, b in ipairs(h.by or {}) do if b ~= by then bys[#bys + 1] = b end end
                h.by, h.as_boss, h.in_move = bys, true, nil
                h.moved = h0 == nil and true or h.moved
                h.strikes_until = math.max(h.strikes_until or 0, tonumber(body:match("strikes_until = (%d+)")) or 0)
                merged[name] = h
            end
        end
        Hz = merged
    end
    -- (the boss's own strike that same moment - a STRIKE with its HIT: its own blow (the Clockwork
    -- Bishop's shot, 8 off, landing as the crackle it leaves appears), judged with its move by
    -- replay.lua - not the thing's. OLD_OWNSTRIKE=1: as before)
    local strike_at = {}
    if not os.getenv("OLD_OWNSTRIKE") then
        for line in MainLines() do
            local st, sb = line:match("%[tr_trace%] ([%d%.]+) ([%w_]+) STRIKE at wilson")
            if st ~= nil then strike_at[#strike_at + 1] = { tonumber(st), sb } end
        end
    end
    -- (how far round itself a thing strikes, as drawn - its cells' furthest, 3.5 at least: the Celestial Champion's
    -- spike wall 8 to either side of its trail - replay.lua NearOf the same. OLD_THING_NEAR=1: 3.5 for all)
    local far_of = {}
    local function NearOf(h)
        if h == nil or h.steps == nil or os.getenv("OLD_THING_NEAR") then return 3.5 end
        if far_of[h] == nil then
            local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"
            -- (the data's _grid: step .25, row 0 / column 0 the cell at side -20 / ahead -20)
            local step, a0, s0 = .25, -20, -20
            local far = 0
            for _, st in ipairs(h.steps) do
                local text, pos, row = st.cells or "", 1, -1
                local function Num()
                    local v, scale = 0, 1
                    while true do
                        local d = (B64:find(text:sub(pos, pos), 1, true) or 1) - 1
                        pos = pos + 1
                        v = v + (d % 32) * scale
                        if d < 32 then return v end
                        scale = scale * 32
                    end
                end
                while pos <= #text do
                    row = row + Num()
                    local n, last_end = Num(), -1
                    for _ = 1, n do
                        local from = last_end + 1 + Num()
                        local to = from + Num()
                        for _, c in ipairs({ from, to }) do
                            far = math.max(far, math.sqrt((c * step + a0) ^ 2 + (row * step + s0) ^ 2))
                        end
                        last_end = to
                    end
                end
            end
            far_of[h] = math.max(3.5, far + .5)
        end
        return far_of[h]
    end
    local function OwnStrike(t, b)
        for _, s in ipairs(strike_at) do if s[2] == b and math.abs(s[1] - t) < .05 then return true end end
        return false
    end
    -- (not "a HIT with no STRIKE": mostly the boss's own area blow - replay.lua the same, VERIFY_PLAN 6.12b)
    for line in MainLines() do
        local t, b, rest = line:match("%[tr_trace%] ([%d%.]+) ([%w_]+) HIT at wilson (.*)$")
        if t ~= nil then
            t = tonumber(t)
            local bx, bz = rest:match("pos=([%d%.%-]+),([%d%.%-]+)")
            local yx, yz = rest:match("you=([%d%.%-]+),([%d%.%-]+)")
            bx, bz, yx, yz = tonumber(bx), tonumber(bz), tonumber(yx), tonumber(yz)
            local dup = false
            for _, h in ipairs(hits) do if math.abs(h.t - t) < .05 then dup = true end end
            -- (HAZ_ALL_NEAR=1: every one, the boss near or not - only to test the things' drawing by
            -- itself, on a boss with no area blows of its own (UM Bearger); never for counts)
            -- (or, the boss near, one whose blows the game puts down to the boss while it still strikes -
            -- as_boss, strikes_until frames from when it appeared, +2; replay.lua the same, VERIFY_PLAN 6.12b)
            local far = bx ~= nil and yx ~= nil and ((bx - yx) ^ 2 + (bz - yz) ^ 2 > 36 or os.getenv("HAZ_ALL_NEAR"))
            if not dup and bx ~= nil and yx ~= nil then
                local own_strike = OwnStrike(t, b)
                local best, bd = nil, math.huge
                for _, tr in pairs(tracks) do
                    local own = false
                    local hz = Hz[tr.prefab] or {}
                    for _, o in ipairs(hz.by or {}) do if o == b and not hz.in_move then own = true end end
                    -- (not one whose blows aren't put down to the boss (as_boss), the boss striking you itself then)
                    if own and own_strike and not hz.as_boss then own = false end
                    -- (its age from when it last came back, the ticks before t unbroken - one set out
                    -- again from a pool, the same GUID: replay.lua the same)
                    local young = false
                    if hz.as_boss then
                        local from = nil
                        for k = 1, #tr.ticks do
                            local tk = tr.ticks[k]
                            if tk.t > t + .07 then break end
                            -- (or set out again somewhere else straight away - Deerclops' ice spikes: replay.lua the same)
                            local pk = tr.ticks[k - 1]
                            if from == nil or tk.t - pk.t > .1 or (not hz.moved and (pk.x - tk.x) ^ 2 + (pk.z - tk.z) ^ 2 > .25) then from = tk.t end
                        end
                        young = from ~= nil and t - from <= ((hz.strikes_until or 0) + 2) * FRAMES
                    end
                    if own and (far or young) then
                        local R = NearOf(hz)
                        for _, k in ipairs(tr.ticks) do
                            if math.abs(k.t - t) < .07 then
                                local d = (k.x - yx) ^ 2 + (k.z - yz) ^ 2
                                if d <= R * R and d <= bd then best, bd = { prefab = tr.prefab, x = k.x, z = k.z }, d end
                            end
                        end
                    end
                end
                if best ~= nil then
                    hits[#hits + 1] = { t = t, prefab = best.prefab, x = yx, z = yz, bx = best.x, bz = best.z }
                end
            end
        end
    end
end
-- (a boss run offline near, traced then - its moves drawn in the game, and what's drawn with them
-- (in_move: a pound's ring, a laser) not again on its own: left out here the same)
local SimMoves = require("true_range/simmoves")
-- (the server's positions: nothing to draw on from - tests/replay.lua)
-- (CLIENT=1: as a player's game would see it - as tests/replay.lua's CLIENT: things ENT_LAG frames late, drawn on ahead
-- (HAZ_LEAD .1), you YOU_LEAD frames on (PRED=1) or back (PRED=0), "in" if in what was drawn the .15 s before the blow's word)
HZ_CLIENT = os.getenv("CLIENT") ~= nil
HZ_PRED = tonumber(os.getenv("PRED") or "") or false
HZ_CLIENT_PRED = HZ_PRED or tonumber(os.getenv("CLIENT_PRED") or "") or false
HZ_ENT_LAG = (tonumber(os.getenv("ENT_LAG") or "") or (HZ_CLIENT and 3 or 0)) * FRAMES
HZ_YOU_LEAD = tonumber(os.getenv("YOU_LEAD") or "") or (HZ_CLIENT and (HZ_CLIENT_PRED == 0 and -2 or 3) or false)
SimMoves.hazard_lead = tonumber(os.getenv("HAZ_LEAD") or "") or (HZ_CLIENT and .1 or 0)
local boss_at = {}  -- frame number -> { { x, z } }
for line in MainLines() do
    local t, b, x, z = line:match("%[tr_trace%] ([%d%.]+) ([%w_]+) after .-pos=([%d%.%-]+),([%d%.%-]+)")
    if t ~= nil and SimMoves.Has(b) then
        local f = math.floor(tonumber(t) * 30 + .5)
        boss_at[f] = boss_at[f] or {}
        table.insert(boss_at[f], { tonumber(x), tonumber(z), b, line:match("guid=(%d+)") or b })
    end
end
local function BossNear(t, x, z)
    local f = math.floor(t * 30 + .5)
    for g = f - 2, f + 2 do
        for _, p in ipairs(boss_at[g] or {}) do
            if (p[1] - x) ^ 2 + (p[2] - z) ^ 2 < 40 * 40 then return true end
        end
    end
    return false
end
local t0, t1 = math.huge, -math.huge
for _, tr in pairs(tracks) do
    t0, t1 = math.min(t0, tr.ticks[1].t), math.max(t1, tr.ticks[#tr.ticks].t)
end
if t0 == math.huge then real_print("no hazard trace") return end

-- each thing, as an entity the drawing asks about
local ents = {}
for guid, tr in pairs(tracks) do
    local e = { prefab = tr.prefab, GUID = tonumber(guid), Transform = {}, AnimState = {}, i = 1 }
    -- (each a call to the game, counted: ENGINE_CALLS - "asked" apart from what's laid)
    function e:IsValid() engine_asked = engine_asked + 1 return e.cur ~= nil end
    function e:HasTag() engine_asked = engine_asked + 1 return false end
    function e.Transform:GetWorldPosition() engine_asked = engine_asked + 1 return e.cur.x, e.cur.y or 0, e.cur.z end
    -- (not in older traces: drawn the size run offline)
    function e.Transform:GetScale() engine_asked = engine_asked + 1 local s = e.cur.scale return s, s, s end
    -- (ROT_JITTER=1: turned a hair more each frame, as the game slides it between ticks - a worm
    -- segment following its body)
    function e.Transform:GetRotation() engine_asked = engine_asked + 1 return (e.cur.rot or 0) + (os.getenv("ROT_JITTER") and (now * 30 % 7) * .3 or 0) end
    -- (one drawn only while it plays these (simmoves _on_anims) is traced only then (modmain's tracer): traced, it plays
    -- them - its ancient_hulk_mine's red_loop, every one "missed" here, 9 of 9, 2026-10-21. OLD_ONANIMS=1: none, as before)
    local on_list = {}
    if not os.getenv("OLD_ONANIMS") then
        for _, an in ipairs(require("true_range/simmoves")._on_anims[tr.prefab] or {}) do on_list[an] = true end
    end
    function e.AnimState:IsCurrentAnimation(an) engine_asked = engine_asked + 1 return on_list[an] == true end
    -- (its animation as long under way as it has been there - the glide's clock)
    function e.AnimState:GetCurrentAnimationTime() engine_asked = engine_asked + 1 return math.max(0, now - (first_seen[guid] or tr.ticks[1].t)) end
    -- (its reach as the server tells it (simmoves _live_radius): the game's own rule, from when it appeared - the Klaus deer's ice
    -- circle, .25 on 2% a frame to 3 (deer_fx OnUpdateIceCircle). LIVE_RAD_OLD=1: none - drawn from its run offline)
    local LIVE_RAD = { deer_ice_circle = function(n) return 3 - 2.75 * .98 ^ n end }
    if LIVE_RAD[tr.prefab] ~= nil and not os.getenv("LIVE_RAD_OLD") then
        local rule = LIVE_RAD[tr.prefab]
        e._rad = { value = function() return rule(math.max(0, (now - (first_seen[guid] or tr.ticks[1].t)) / FRAMES)) end }
    end
    e.tr = tr
    ents[#ents + 1] = e
end
-- (in a set order, by GUID: pairs over string keys goes in another order each run (LuaJIT's string hash is seeded) - a lot
-- of Toadstool's bombs found in another order drawn otherwise, the same log 343 / 345 / 346 lines run to run, 2026-10-29.
-- OLD_HAZ_ORDER=1: as pairs gives)
if not os.getenv("OLD_HAZ_ORDER") then table.sort(ents, function(p, q) return (p.GUID or 0) < (q.GUID or 0) end) end
local drawn = {}
local f = 0
-- (a piece: on the whole log's frames - from its first thing's first line, as a whole run steps -
-- not its own first line's: one frame or a millisecond off, its verdicts all moved)
if HAZ_FROM > -math.huge then
    local g0 = math.huge
    for _, ft in pairs(first_seen) do g0 = math.min(g0, ft) end
    if g0 < t0 then
        f = math.ceil((t0 - g0) / FRAMES - 1e-6)
        t0 = g0
    end
end
while true do
    local t = t0 + f * FRAMES
    if t > t1 + 1 then break end
    now = t
    local list, you = {}, nil
    for _, e in ipairs(ents) do
        local tk = e.tr.ticks
        while e.i < #tk and tk[e.i + 1].t <= t + 1e-6 do e.i = e.i + 1 end
        local c = tk[e.i]
        local h = SimMoves.Hazards()[e.prefab]
        -- (or its trace skipping a few frames while it's still there - a later line to come, within .3 s: the server's
        -- own hitch, not gone in a player's game; taken as gone, every such skip was a GAPDRAWN of ours, the Ink
        -- Blight's balls 2026-10-28. OLD_TRACEHOLD=1: as before)
        local held = tk[e.i + 1] ~= nil and t - c.t < .3 and not os.getenv("OLD_TRACEHOLD")
        if c.t <= t + 1e-6 and (t - c.t < 2 * FRAMES or held) and not (h ~= nil and h.in_move and BossNear(t, c.x, c.z)) then
            you = you or { c.yx, c.yz }
            -- (CLIENT: it as a player's game has it, ENT_LAG back - you as the server has you now)
            local young = false
            if HZ_ENT_LAG > 0 then
                local k = e.i
                while k > 1 and tk[k].t > t - HZ_ENT_LAG + 1e-6 do k = k - 1 end
                if tk[k].t <= t - HZ_ENT_LAG + 1e-6 then c = tk[k]
                -- (made less than ENT_LAG ago: not in a player's game yet - not shown where the server has it now, then
                -- jumped back ENT_LAG once it had a past: the Shadow Thralls' shots' heights went 4.21, 4.50, 4.21, their
                -- landing fitted at their start, 584 gaps, 2026-10-29. OLD_CLIENT_YOUNG=1: as before)
                elseif not os.getenv("OLD_CLIENT_YOUNG") then young = true end
            end
            if young then
                e.cur = nil
            else
                e.cur = c
                list[#list + 1] = e
            end
        else
            e.cur = nil
        end
    end
    -- (you struck by one just now: told, as modmain does - one of a lot sharing whom they strike)
    for _, h in ipairs(hits) do
        if h.t > t - FRAMES + 1e-6 and h.t <= t + 1e-6 and h.bx ~= nil then
            local best, bd = nil, 1
            for _, e in ipairs(list) do
                if e.prefab == h.prefab then
                    local d = (e.cur.x - h.bx) ^ 2 + (e.cur.z - h.bz) ^ 2
                    if d < bd then best, bd = e, d end
                end
            end
            if best ~= nil then SimMoves.Struck(best) end
        end
    end
    -- (CLIENT: you where your game shows you - YOU_LEAD frames on (back, -) along how you went)
    if you ~= nil and HZ_YOU_LEAD then
        local was = hz_you_prev
        hz_you_prev = { you[1], you[2] }
        if was ~= nil then you = { you[1] + (you[1] - was[1]) * HZ_YOU_LEAD, you[2] + (you[2] - was[2]) * HZ_YOU_LEAD } end
    end
    if you ~= nil then
        pieces = 0
        local SMr = require("true_range/simmoves")
        SMr._record = {}
        -- (HAZ_TIME: how long the drawing itself takes, and what it makes - frame by frame, all told at the end)
        local c0, m0 = os.clock(), collectgarbage("count")
        -- (ALLOC_PROF: memory made, by the line that made it - the worst said at the end)
        if os.getenv("ALLOC_PROF") then
            alloc_by = alloc_by or {}
            local last_line, last_mem = nil, collectgarbage("count")
            collectgarbage("stop")
            debug.sethook(function(_, line)
                local m = collectgarbage("count")
                if last_line ~= nil and m > last_mem then alloc_by[last_line] = (alloc_by[last_line] or 0) + m - last_mem end
                local info = debug.getinfo(2, "S")
                last_line, last_mem = info.short_src:match("[^/\\]+$") .. ":" .. line, collectgarbage("count")
            end, "l")
        end
        -- (ALLOC_PROF: memory made, by the line that made it - the worst said at the end)
        if os.getenv("ALLOC_PROF") then
            alloc_by = alloc_by or {}
            local last_line, last_mem = nil, collectgarbage("count")
            collectgarbage("stop")
            debug.sethook(function(_, line)
                local m = collectgarbage("count")
                if last_line ~= nil and m > last_mem then alloc_by[last_line] = (alloc_by[last_line] or 0) + m - last_mem end
                local info = debug.getinfo(2, "S")
                last_line, last_mem = info.short_src:match("[^/\\]+$") .. ":" .. line, collectgarbage("count")
            end, "l")
        end
        local LR = os.getenv("ENGINE_CALLS") and require("true_range/lines") or nil
        if LR then LR.Begin() end
        local calls0, asked0 = engine_calls, engine_asked
        -- (LINE_PROF: how many of the mod's lines run, by line - the game's Lua runs each about alike)
        if os.getenv("LINE_PROF") then
            line_by = line_by or {}
            debug.sethook(function(_, line)
                local src = debug.getinfo(2, "S").short_src
                if not src:find("replay_haz", 1, true) then
                    local k = os.getenv("LINE_PROF") == "fn" and (src:match("[^/\\]+$") .. ":" .. (debug.getinfo(2, "S").linedefined) .. " " .. tostring(debug.getinfo(2, "n").name)) or (src:match("[^/\\]+$") .. ":" .. line)
                    line_by[k] = (line_by[k] or 0) + 1
                    line_total = (line_total or 0) + 1
                end
            end, "l")
        end
        -- (what stands where, as the game's own search would find it - of what's traced)
        Predict.EntsNear = function(x, z, r)
            local out = {}
            for _, e in ipairs(list) do if (e.cur.x - x) ^ 2 + (e.cur.z - z) ^ 2 <= r * r then out[#out + 1] = e end end
            -- (and the bosses traced then - whose things these may be (predict's foreign_of))
            local f = math.floor(t * 30 + .5)
            for _, p in ipairs(boss_at[f] or boss_at[f - 1] or boss_at[f + 1] or {}) do
                if (p[1] - x) ^ 2 + (p[2] - z) ^ 2 <= r * r then out[#out + 1] = { prefab = p[3] } end
            end
            return out
        end
        local inside = Predict.DrawHazards(list, .5, { x = you[1], z = you[2] })
        -- (or inside what's laid as a lot's lane - SimMoves.LaneDraw, the Eye of Terror's laser drawn as one lane ahead: told
        -- by each blob only round itself, you in the lane ahead of the one going off "not drawn", 18 so, 2026-10-20.
        -- OLD_LANE_IN=1: as before)
        if not inside and not os.getenv("OLD_LANE_IN") and SMr._record ~= nil then
            for _, r in ipairs(SMr._record) do
                if r.lane and r.x ~= nil and r.todo ~= nil and r.todo[1] ~= nil and r.todo[1].map ~= nil
                    and SMr._InMap(r.todo[1].map, r.x, r.z, r.rot or 0, you[1], you[2]) then inside = true break end
            end
        end
        if os.getenv("LINE_PROF") then debug.sethook() end
        if LR then
            LR.End()
            engine_frame_calls = (engine_frame_calls or 0) + engine_calls - calls0
            if engine_calls - calls0 > (most_calls or 0) then
                most_calls, most_calls_t = engine_calls - calls0, t
                most_by = {}
                for k, v in pairs(engine_by) do most_by[k] = v - ((by0 or {})[k] or 0) end
                most_kept = {}
                for k, v in pairs(LR.dbg or {}) do most_kept[k] = v end
            end
            if engine_calls - calls0 > 3000 then heavy_frames = (heavy_frames or "") .. string.format(" %.2f:%d", t, engine_calls - calls0) end
            by0 = {}
            for k, v in pairs(engine_by) do by0[k] = v end
            -- (pieces made while drawing - not those made ahead after it, as the game warms)
            local laid_now = (LR.laid or 0) - (laid0f or 0)
            if laid_now > (most_laid or 0) then most_laid, most_laid_t = laid_now, t end
            laid_sum = (laid_sum or 0) + laid_now
            local made_now = LR.created - (made0 or 0)
            if made_now > (most_made or 0) then most_made, most_made_t = made_now, t end
            -- (HAZ_PIC=<time>: every piece showing then painted where the world sees it - its picture,
            -- stretch, turning with its parent's, colour, by sort order; HAZ_PIC_OUT, PIC_S pixels a
            -- unit (40), PIC_R units round you or PIC_C)
            local pic_t = tonumber(os.getenv("HAZ_PIC") or "")
            if pic_t ~= nil and not haz_pic_done and t >= pic_t - FRAMES / 2 then
                haz_pic_done = true
                local S = tonumber(os.getenv("PIC_S") or "") or 40
                local R = tonumber(os.getenv("PIC_R") or "") or 12
                local cxs, czs = (os.getenv("PIC_C") or ""):match("([%d%.%-]+),([%d%.%-]+)")
                local cx, cz = tonumber(cxs) or you[1], tonumber(czs) or you[2]
                local W = math.floor(2 * R * S)
                local img = {}
                for i = 1, W * W do img[i] = { 120, 95, 55 } end
                local items = {}
                for _, e in ipairs(all_ents) do
                    if e.vis and not e.removed and e.anim ~= nil and e.colour ~= nil then
                        local x, _, z = e.Transform.GetWorldPosition()
                        local deg = e.rot
                        local p = e.parent
                        while p ~= nil do deg = deg + p.rot p = p.parent end
                        local th = math.rad(deg)
                        local ux, uz = math.cos(th), -math.sin(th)
                        local vx, vz = math.cos(th + math.pi / 2), -math.sin(th + math.pi / 2)
                        local poly
                        if e.anim == "square" then
                            local L, Wd = e.sx * 64 / 150 / 2, e.sy * 64 / 150 / 2
                            poly = { x - ux * L - vx * Wd, z - uz * L - vz * Wd, x + ux * L - vx * Wd, z + uz * L - vz * Wd,
                                x + ux * L + vx * Wd, z + uz * L + vz * Wd, x - ux * L + vx * Wd, z - uz * L + vz * Wd }
                        elseif e.anim == "tri" then
                            local L, H = e.sx * 256 / 150, e.sy * 256 / 150
                            poly = { x, z, x + ux * L, z + uz * L, x + vx * H, z + vz * H }
                        elseif e.anim == "disc" then
                            local r = e.sx * 256 / 150 / 2
                            poly = {}
                            for k = 0, 47 do local a = k / 48 * 2 * math.pi poly[#poly + 1] = x + r * math.cos(a) poly[#poly + 1] = z + r * math.sin(a) end
                        end
                        if poly ~= nil then items[#items + 1] = { poly = poly, c = e.colour, sort = e.sort or 4, n = #items } end
                    end
                end
                table.sort(items, function(a, b) if a.sort ~= b.sort then return a.sort < b.sort end return a.n < b.n end)
                for _, it in ipairs(items) do
                    local xs, ys = {}, {}
                    for k = 1, #it.poly, 2 do xs[#xs + 1] = (it.poly[k] - (cx - R)) * S ys[#ys + 1] = (it.poly[k + 1] - (cz - R)) * S end
                    local minx, maxx, miny, maxy = math.huge, -math.huge, math.huge, -math.huge
                    for k = 1, #xs do minx, maxx, miny, maxy = math.min(minx, xs[k]), math.max(maxx, xs[k]), math.min(miny, ys[k]), math.max(maxy, ys[k]) end
                    for yy = math.max(0, math.floor(miny)), math.min(W - 1, math.ceil(maxy)) do
                        for xx = math.max(0, math.floor(minx)), math.min(W - 1, math.ceil(maxx)) do
                            local sx, sy = xx + .5, yy + .5
                            local pos, neg = false, false
                            for k = 1, #xs do
                                local k2 = k % #xs + 1
                                local ee = (xs[k2] - xs[k]) * (sy - ys[k]) - (ys[k2] - ys[k]) * (sx - xs[k])
                                if ee > 0 then pos = true elseif ee < 0 then neg = true end
                            end
                            if not (pos and neg) then
                                local px = img[yy * W + xx + 1]
                                local c = it.c
                                px[1], px[2], px[3] = px[1] * (1 - c[4]) + c[1] * 255 * c[4], px[2] * (1 - c[4]) + c[2] * 255 * c[4], px[3] * (1 - c[4]) + c[3] * 255 * c[4]
                            end
                        end
                    end
                end
                local buf = {}
                for i = 1, W * W do local px = img[i] buf[i] = string.char(math.floor(px[1]), math.floor(px[2]), math.floor(px[3])) end
                local fh = assert(io.open(os.getenv("HAZ_PIC_OUT") or "hazpic.ppm", "wb"))
                fh:write(string.format("P6\n%d %d\n255\n", W, W) .. table.concat(buf))
                fh:close()
                io.stdout:write(string.format("HAZ_PIC %d pieces showing at t=%.3f round %.2f,%.2f\n", #items, t, cx, cz))
            end
            LR.Warm(12)
            made0 = LR.created
            laid0f = LR.laid or 0
        end
        engine_frame_asked = (engine_frame_asked or 0) + engine_asked - asked0
        if os.getenv("ALLOC_PROF") then debug.sethook() collectgarbage("restart") end
        if os.getenv("ALLOC_PROF") then debug.sethook() collectgarbage("restart") end
        haz_time, haz_mem, haz_frames = haz_time + (os.clock() - c0), haz_mem + math.max(0, collectgarbage("count") - m0), haz_frames + 1
        -- (HAZ_TIME: the slowest frames, said at the end - one slow frame is a hitch, the average hides it)
        if os.getenv("HAZ_TIME") then slow_frames = slow_frames or {} slow_frames[#slow_frames + 1] = { os.clock() - c0, t, #list } end
        haz_pieces = haz_pieces + pieces
        -- (each thing's drawn parts this frame, for OUTSIDE below - its own key "_hazard|prefab")
        if os.getenv("HAZ_STYLES") then for _, r in ipairs(SMr._record) do if (r.key or "?"):find(os.getenv("HAZ_STYLES"), 1, true) or os.getenv("HAZ_STYLES") == "*" then local st = {} for _, q in ipairs(r.todo or {}) do st[#st + 1] = tostring(q.style) end io.stdout:write(string.format("HSTY %.3f %s at %.2f,%.2f %s\n", t, tostring(r.key), r.x or 0, r.z or 0, table.concat(st, " "))) end end end
        for _, r in ipairs(SMr._record) do
            for _, e in ipairs(list) do
                if r.key ~= nil and r.key:find("_hazard|" .. e.prefab, 1, true) and r.x ~= nil then
                    e.tr.drawn = e.tr.drawn or {}
                    table.insert(e.tr.drawn, { t = t, r = r })
                end
            end
        end
        -- (ATTR: which thing you were in - its drawn parts round you; or the nearest, none told)
        local inname = nil
        if inside and os.getenv("ATTR") then
            for _, r in ipairs(SMr._record) do
                local pf = r.key ~= nil and r.key:match("_hazard|([%w_]+)") or nil
                if pf ~= nil and r.x ~= nil then
                    for _, p in ipairs(r.todo or {}) do
                        if p.map ~= nil and SMr._InMap(p.map, r.x, r.z, r.rot or 0, you[1], you[2]) then inname = pf break end
                    end
                end
                if inname then break end
            end
        end
        SMr._record = nil
        local names, near, nearname = {}, math.huge, nil
        for _, e in ipairs(list) do
            names[#names + 1] = e.prefab
            local dd = math.sqrt((e.cur.x - you[1]) ^ 2 + (e.cur.z - you[2]) ^ 2)
            if dd < near then near, nearname = dd, e.prefab end
        end
        drawn[#drawn + 1] = { t = t, inside = inside, n = #list, pieces = pieces, names = table.concat(names, ","), px = you[1], pz = you[2], near = near,
            inname = inname or ("~" .. tostring(nearname)) }
    end
    f = f + 1
end
-- (a blow from something not traced itself, with something traced there then - a pound's ring
-- round the worm's dirt: a strike of that too)
local bosses, env_things = {}, {}
for line in MainLines() do
    local b = line:match("%[tr_trace%] [%d%.]+ ([%w_]+) ")
    if b ~= nil then bosses[b] = true end
    -- (nor a thing a drawn boss has round it - its tr_env "things": counted with that boss by
    -- replay.lua ("things struck you"), drawn with its move - the Moonmaw's crystal ring, counted
    -- here again and missed, as no thing of its own is drawn for it; VERIFY_PLAN 6.0a)
    local ep, et = line:match("%[tr_env%] [%d%.]+ ([%w_]+) guid=%d+ things (.*)$")
    if ep ~= nil and SimMoves.Has(ep) and not os.getenv("OLD_HAZ_STRUCK") then for name in et:gmatch("([%w_]+):") do env_things[name] = true end end
end
-- (nor one chewing on you as it holds you inside - the Great Depths Worm, striking only one it has devoured (worm_boss_util.lua
-- DoChew, IsDevouring): nothing to warn of in there; 181 "missed" in the kept logs, every 0.47 s. OLD_DEVOURED=1: counted)
local DEVOURS = { worm_boss = true, worm_boss_shadow = true }
local devoured_n = 0
for _, s in ipairs(struck) do
    if DEVOURS[s.by] and not os.getenv("OLD_DEVOURED") then
        devoured_n = devoured_n + 1
    elseif not bosses[s.by] and not env_things[s.by] and SimMovesHazard(s.by) == nil and not SimMoves.Has(s.by) then
        for _, d in ipairs(drawn) do
            if math.abs(d.t - s.t) <= FRAMES * 1.5 and d.n > 0 and d.near < 8 then
                hits[#hits + 1] = { t = s.t, prefab = s.by .. " (struck)", x = d.px, z = d.pz, bx = d.px, bz = d.pz }
                break
            end
        end
    end
end
if devoured_n > 0 then real_print(string.format("_hazards: %d blows on you held inside (devoured - not counted)", devoured_n)) end
if HAZ_FROM > -math.huge or HAZ_TO < math.huge then
    local keep = {}
    for _, h in ipairs(hits) do if InPiece(h.t) then keep[#keep + 1] = h end end
    hits = keep
end
-- (modmain's DARTS: a lane each, drawn by its own code as it flies - its way from where first seen to where first gone .3
-- on, len from there, round width; from where it is to its end: the "lane" a blow of one is judged by)
local DARTS = {}
do
    local mf = io.open(arg[1] .. "/modmain.lua", "rb")
    local src = mf and mf:read("*a") or ""
    if mf then mf:close() end
    for name, len, width, rest in (src:match("local DARTS = (%b{})") or ""):gmatch("([%w_]+) = { len = ([%d%.]+), width = ([%d%.]+)([^}]*)}") do
        DARTS[name] = { len = tonumber(len), width = tonumber(width), face = rest:find("face = true", 1, true) ~= nil }
    end
end
-- (whether you, at yx, yz, were in the lane of one of that kind drawn at t; and how far off its middle the nearest was)
local function DartCovers(prefab, t, yx, yz)
    local dd = DARTS[prefab]
    if dd == nil then return false, math.huge end
    local near = math.huge
    for _, tr in pairs(tracks) do
        if tr.prefab == prefab and tr.ticks[1].t <= t + .05 and tr.ticks[#tr.ticks].t >= t - .2 then
            local first, cur, wx, wz = tr.ticks[1], nil, nil, nil
            for _, k in ipairs(tr.ticks) do
                if k.t > t + 1e-6 then break end
                cur = k
                local mx, mz = k.x - first.x, k.z - first.z
                local ml = math.sqrt(mx * mx + mz * mz)
                if wx == nil and ml > .3 then wx, wz = mx / ml, mz / ml end
            end
            -- (as modmain: one turned to its target as it's made (face) - the way it faces till it has gone .3)
            if cur ~= nil and wx == nil and dd.face and cur.rot ~= nil then
                local r = cur.rot * math.pi / 180
                wx, wz = math.cos(r), -math.sin(r)
            end
            if cur ~= nil and wx ~= nil then
                local ex, ez = first.x + wx * dd.len, first.z + wz * dd.len
                local left = (ex - cur.x) * wx + (ez - cur.z) * wz
                if left > 0 then
                    local ax, az = ex - wx * left, ez - wz * left
                    local u = math.max(0, math.min(left, (yx - ax) * wx + (yz - az) * wz))
                    near = math.min(near, math.sqrt((yx - (ax + wx * u)) ^ 2 + (yz - (az + wz * u)) ^ 2))
                end
            end
        end
    end
    return near <= dd.width, near
end
-- (modmain's ruins nightmare horns: the lane between each and the other nearest it (within 22), 1.75 round - one with
-- none, 10 on the way it faces: drawn by modmain's own code, as the darts; you in it at t?)
-- (the worm's mounds as modmain rings them (AGGRO_WHILE w.near): 2.5 round a mound while one of its spiked segments is within
-- 1.6 of it, and .3 s after (linger) - a segment come up through it striking you there was drawn in the game, "missed" here,
-- 10 a bench, 2026-10-28. OLD_AGGRONEAR=1: as before)
local WORM_NEAR = { worm_boss_dirt = "worm_boss_segment", worm_boss_shadow_dirt = "worm_boss_shadow_segment" }
local function WormDirtCovers(t, yx, yz)
    local function At(tr, t0, t1)
        local cur = nil
        for _, k in ipairs(tr.ticks) do if k.t > t1 + 1e-6 then break end if k.t >= t0 - 1e-6 then cur = k end end
        return cur
    end
    for _, dt in pairs(tracks) do
        local seg = WORM_NEAR[dt.prefab]
        local d = seg ~= nil and At(dt, t - .1, t + .05) or nil
        if d ~= nil and (d.x - yx) ^ 2 + (d.z - yz) ^ 2 <= 2.5 * 2.5 then
            for _, st in pairs(tracks) do
                if st.prefab == seg then
                    for _, k in ipairs(st.ticks) do
                        if k.t > t + .05 then break end
                        if k.t >= t - .35 and (k.x - d.x) ^ 2 + (k.z - d.z) ^ 2 <= 1.6 * 1.6 then return true end
                    end
                end
            end
        end
    end
    return false
end
local function HornCovers(t, yx, yz)
    local at = {}
    for _, tr in pairs(tracks) do
        if tr.prefab == "ruinsnightmare_horn_attack" and tr.ticks[1].t <= t + .05 and tr.ticks[#tr.ticks].t >= t - .1 then
            local cur = nil
            for _, k in ipairs(tr.ticks) do if k.t > t + 1e-6 then break end cur = k end
            if cur ~= nil then at[#at + 1] = cur end
        end
    end
    local function Seg(ax, az, bx, bz)
        local vx, vz = bx - ax, bz - az
        local l2 = vx * vx + vz * vz
        local u = l2 > 1e-9 and math.max(0, math.min(1, ((yx - ax) * vx + (yz - az) * vz) / l2)) or 0
        return math.sqrt((yx - (ax + vx * u)) ^ 2 + (yz - (az + vz * u)) ^ 2) <= 1.75
    end
    for i, h in ipairs(at) do
        local other, best = nil, 22 * 22
        for j, o in ipairs(at) do
            if j ~= i then
                local d = (o.x - h.x) ^ 2 + (o.z - h.z) ^ 2
                if d < best then other, best = o, d end
            end
        end
        if other ~= nil then
            if Seg(h.x, h.z, other.x, other.z) then return true end
        elseif h.rot ~= nil then
            local r = h.rot * math.pi / 180
            if Seg(h.x, h.z, h.x + 10 * math.cos(r), h.z - 10 * math.sin(r)) then return true end
        end
    end
    return false
end
local missed, ok = 0, 0
-- (PRED=n: only the lag bench's scenes so set - [tr_bench] <t> <boss> lag scene n= pred=)
local hz_scenes = nil
if HZ_PRED then
    hz_scenes = {}
    for line in io.lines(arg[2]) do
        local st, sp = line:match("%[tr_bench%] ([%d%.]+) [%w_]+ lag scene n=%d+ pred=(%d)")
        if st ~= nil then hz_scenes[#hz_scenes + 1] = { t = tonumber(st), pred = tonumber(sp) } end
    end
end
local function HzInScene(t)
    if hz_scenes == nil then return true end
    local p = nil
    for _, s in ipairs(hz_scenes) do if s.t <= t then p = s.pred else break end end
    return p == HZ_PRED
end
-- (or you put there by the bench itself - over 1 in a tick in the half second before: set down on a spore cloud's middle as a
-- scene began, struck 0.2 s on, "0.00 off" undrawn, 4 so on the bench 2026-11-01_0433 - no player goes 1 in a tick. As
-- tests/replay.lua BenchMoved: said as BENCHMOVED, apart from missed. OLD_BENCHMOVED=1: missed)
-- (where the server had you - the traced things' "you", not where a player's game shows you: led on in CLIENT, 244 blows taken
-- for moved by the bench)
local you_raw = nil
local function HzBenchMoved(t)
    if os.getenv("OLD_BENCHMOVED") then return false end
    if you_raw == nil then
        local seen = {}
        you_raw = {}
        for _, tr in pairs(tracks) do
            for _, k in ipairs(tr.ticks) do
                if k.yx ~= nil and not seen[k.t] then seen[k.t] = true you_raw[#you_raw + 1] = { t = k.t, x = k.yx, z = k.yz } end
            end
        end
        table.sort(you_raw, function(a, b) return a.t < b.t end)
    end
    local prev = nil
    for _, d in ipairs(you_raw) do
        if d.t > t + 1e-6 then break end
        if prev ~= nil and d.t >= t - .5 and d.t - prev.t < 1.5 * FRAMES and (d.x - prev.x) ^ 2 + (d.z - prev.z) ^ 2 > 1 then return true end
        prev = d
    end
    return false
end
local benchmoved = 0
for _, h in ipairs(hits) do if HzInScene(h.t) then
    local near = false
    local lo, hi = h.t - FRAMES * 1.5, h.t + FRAMES * 1.5
    if HZ_CLIENT then lo, hi = h.t + HZ_ENT_LAG - .15, h.t + HZ_ENT_LAG + FRAMES / 2 end
    for _, d in ipairs(drawn) do
        if d.t >= lo and d.t <= hi and d.inside then near = true break end
    end
    -- (or one of modmain's DARTS too - drawn as its lane besides: the stingers of Uncompromising Mode's bees)
    if not near and DARTS[h.prefab] ~= nil and h.x ~= nil and not os.getenv("OLD_DARTS") then near = DartCovers(h.prefab, h.t, h.x, h.z) end
    -- (and the horns' lane - modmain's own, as the darts: 13 struck "undrawn" where they met on you, 2026-10-20. OLD_HORNS=1: as before)
    if not near and h.prefab == "ruinsnightmare_horn_attack" and h.x ~= nil and not os.getenv("OLD_HORNS") then near = HornCovers(h.t, h.x, h.z) end
    if not near and h.x ~= nil and h.prefab:find("^worm_boss") and not os.getenv("OLD_AGGRONEAR") then near = WormDirtCovers(h.t, h.x, h.z) end
    if near then ok = ok + 1
    elseif HzBenchMoved(h.t) then
        benchmoved = benchmoved + 1
        real_print(string.format("BENCHMOVED %.3f %s: struck just after the bench put you there (you %.2f,%.2f)", h.t, h.prefab, h.x or 0, h.z or 0))
    else
        missed = missed + 1
        real_print(string.format("MISSED  %.3f %s: struck, not drawn (you %.2f,%.2f; it %.2f,%.2f, %.2f off)", h.t, h.prefab,
            h.x or 0, h.z or 0, h.bx or 0, h.bz or 0, math.sqrt(((h.x or 0) - (h.bx or 0)) ^ 2 + ((h.z or 0) - (h.bz or 0)) ^ 2)))
    end
end end
if os.getenv("DUMP") ~= nil then
    local d0, d1 = os.getenv("DUMP"):match("([%d%.]+),([%d%.]+)")
    for _, d in ipairs(drawn) do
        if d.t >= tonumber(d0) and d.t <= tonumber(d1) then
            real_print(string.format("DUMP %.3f in %s pieces %d you %.2f,%.2f %s", d.t, tostring(d.inside), d.pieces, d.px, d.pz, d.names))
        end
    end
end
-- OUTSIDE: one carried off by its own code as it comes down (h.glide - the Scrappy Werepig's
-- junk): where it came down, inside what was drawn for its kind in its last moments?
do
    local SMo = require("true_range/simmoves")
    local by_prefab = {}
    for _, tr in pairs(tracks) do
        for _, d in ipairs(tr.drawn or {}) do
            by_prefab[tr.prefab] = by_prefab[tr.prefab] or {}
            table.insert(by_prefab[tr.prefab], d)
        end
    end
    local out, n = 0, 0
    for _, tr in pairs(tracks) do
        local h = SMo.Hazards()[tr.prefab]
        if h ~= nil and h.glide ~= nil and #tr.ticks > 3 then
            n = n + 1
            local last = tr.ticks[#tr.ticks]
            local covered = false
            for _, d in ipairs(by_prefab[tr.prefab] or {}) do
                if d.t >= last.t - .6 and d.t <= last.t + FRAMES then
                    for _, p in ipairs(d.r.todo) do
                        if p.map ~= nil and SMo._InMap(p.map, d.r.x, d.r.z, d.r.rot, last.x, last.z) then covered = true break end
                    end
                end
                if covered then break end
            end
            if not covered then
                out = out + 1
                if out <= 10 then real_print(string.format("OUTSIDE %.3f %s: came down at %.2f,%.2f - not inside what was drawn for it", last.t, tr.prefab, last.x, last.z)) end
            end
        end
    end
    for _, tr in pairs(tracks) do if tr.prefab == "junkball_fall_fx" and os.getenv("JDBG") then real_print(string.format("junk %d ticks, %d drawn, first %.2f,%.2f t%.3f last %.2f,%.2f t%.3f", #tr.ticks, #(tr.drawn or {}), tr.ticks[1].x, tr.ticks[1].z, tr.ticks[1].t, tr.ticks[#tr.ticks].x, tr.ticks[#tr.ticks].z, tr.ticks[#tr.ticks].t)) end end
    real_print(string.format("_hazards: %d carried-off things, %d came down outside what was drawn", n, out))
end
-- ACCURACY (as tests/replay.lua's, for what's drawn round itself as a thing - _hazards): its own hit circle (its radius
-- from its prefab, + your body .5) against what was drawn for it in its first frames, its best; the outer ring a cell
-- inside its edge. NOACCURACY=1: none
-- (sand_spike.lua:20-26 RADIUS .2/.4/.6 + :28 padding .5, FindEntities on your middle; struck 2 frames after it rises)
if not os.getenv("NOACCURACY") then
    local SMa = require("true_range/simmoves")
    local ACC_HAZ = {
        sandspike_short = { r = .2 + .5, to = 30 },
        sandspike_med = { r = .4 + .5, to = 30 },
        sandspike_tall = { r = .6 + .5, to = 30 },
    }
    local stats = {}
    for _, tr in pairs(tracks) do
        local w = ACC_HAZ[tr.prefab]
        local first = tr.ticks ~= nil and tr.ticks[1] or nil
        if w ~= nil and first ~= nil then
            local R = w.r
            local outer = math.max(.5, (R - .25) / R)
            local best, n = 0, 0
            for _, d in ipairs(tr.drawn or {}) do
                if d.t >= first.t - 1.5 * FRAMES and d.t <= first.t + w.to * FRAMES then
                    local inn = 0
                    n = 0
                    for _, ring in ipairs({ { 0, 1 }, { .5, 8 }, { outer, 12 } }) do
                        for i = 0, ring[2] - 1 do
                            local a = i * 2 * math.pi / ring[2]
                            local qx, qz = first.x + R * ring[1] * math.cos(a), first.z + R * ring[1] * math.sin(a)
                            n = n + 1
                            for _, p in ipairs(d.r.todo or {}) do
                                if p.map ~= nil and SMa._InMap(p.map, d.r.x, d.r.z, d.r.rot or 0, qx, qz) then inn = inn + 1 break end
                            end
                        end
                    end
                    best = math.max(best, inn)
                end
            end
            local s = stats[tr.prefab] or { n = 0, cover = 0, low = 0, none = 0 }
            stats[tr.prefab] = s
            s.n = s.n + 1
            if tr.drawn == nil or #tr.drawn == 0 then s.none = s.none + 1 end
            s.cover = s.cover + best / 21
            if best < 11 then s.low = s.low + 1 end
        end
    end
    for k, s in pairs(stats) do
        real_print(string.format("ACCURACY _hazards %s: %d measured, %.0f%% of their hit circles drawn round them, %d under half (%d never drawn)",
            k, s.n, s.cover / s.n * 100, s.low, s.none))
    end
end
-- (each stretch of frames you stood in something drawn, with no blow landing within .3s of it)
local false_in = 0
-- (and their frames all told: the stretches alone split at an edge you stood on - the Moon Tentacle's
-- 602 -> 2,409 stretches were 8,844 -> 5,885 frames, fewer; VERIFY_PLAN 6.15)
local false_frames = 0
-- (fire's harm, as fire does it: a hurt with no blow by it - and up to a second and more after you
-- stood in it, its burning only then begun (Health fire_timestart 1))
local fire_hurt = {}
do
    table.sort(any_hit)
    local k = 1
    local starts_only = os.getenv("HURT_STARTS") ~= nil
    local last_hu = -math.huge
    for _, hu in ipairs(hurts) do
        local gap = hu.t - last_hu
        last_hu = hu.t
        if starts_only and gap < .5 then goto next_hurt end
        while k <= #any_hit and any_hit[k] < hu.t - .1 do k = k + 1 end
        if not (k <= #any_hit and any_hit[k] <= hu.t + .1) then fire_hurt[#fire_hurt + 1] = hu.t + (tonumber(os.getenv("HURT_SHIFT") or "") or 0) end
        ::next_hurt::
    end
end
-- (the hits with no attacker: how many, and how many with you inside something drawn as they came - drawn or not, as
-- "missed" counts a blow; said apart, not in the table's missed. Inside a thing only - a boss's own move isn't drawn here: the
-- Scion's supernova burning, drawn as its move, is "out" here every time)
if not os.getenv("OLD_NOATTACKER") then
    local na, na_in, q = 0, 0, 1
    for _, hu in ipairs(hurts) do
        if hu.by == "?" and InPiece(hu.t) then
            na = na + 1
            while q < #drawn and drawn[q + 1].t <= hu.t do q = q + 1 end
            local d = drawn[q]
            if d ~= nil and math.abs(d.t - hu.t) <= FRAMES * 1.5 and d.inside then na_in = na_in + 1
            else real_print(string.format("NOATTACKER_OUT %.3f cause=%s", hu.t, tostring(hu.cause))) end
        end
    end
    real_print(string.format("NOATTACKER %d hits with no attacker, %d with you inside something drawn", na, na_in))
end
local FIRE_LATE = 1.3
local old_in, old_frames = 0, 0
local i = 1
while i <= #drawn do
    if drawn[i].inside then
        local j = i
        while j + 1 <= #drawn and drawn[j + 1].inside and drawn[j + 1].t - drawn[j].t < FRAMES * 1.5 do j = j + 1 end
        local real = false
        for _, ht in ipairs(any_hit) do
            if ht >= drawn[i].t - .3 and ht <= drawn[j].t + .3 then real = true break end
        end
        local real_old = real
        if not real then
            for _, ht in ipairs(fire_hurt) do
                if ht >= drawn[i].t - .3 and ht <= drawn[j].t + FIRE_LATE then real = true break end
            end
        end
        if not real_old and InPiece(drawn[i].t) then
            old_in, old_frames = (old_in or 0) + 1, (old_frames or 0) + j - i + 1
        end
        if not real_old and real and InPiece(drawn[i].t) and os.getenv("ATTR") then
            real_print(string.format("FIREOK  %.3f _hazards: drawn in for %d frame(s) (%s)", drawn[i].t, j - i + 1, drawn[i].names or "?"))
            local by = {}
            for q = i, j do local k = drawn[q].inname or "?" by[k] = (by[k] or 0) + 1 end
            local parts = {}
            for k, v in pairs(by) do parts[#parts + 1] = k .. "=" .. v end
            table.sort(parts)
            real_print("ATTR " .. table.concat(parts, " "))
        end
        if not real and InPiece(drawn[i].t) then
            false_in = false_in + 1
            false_frames = false_frames + j - i + 1
            real_print(string.format("FALSE   %.3f _hazards: drawn in for %d frame(s), not struck (%s)", drawn[i].t, j - i + 1, drawn[i].names or "?"))
            if os.getenv("ATTR") then
                local by = {}
                for q = i, j do local k = drawn[q].inname or "?" by[k] = (by[k] or 0) + 1 end
                local parts = {}
                for k, v in pairs(by) do parts[#parts + 1] = k .. "=" .. v end
                table.sort(parts)
                real_print("ATTR " .. table.concat(parts, " "))
            end
        end
        i = j + 1
    else
        i = i + 1
    end
end
real_print(string.format("_hazards: %d strikes - %d drawn, %d missed; %d drawn-in with no strike", ok + missed, ok, missed, false_in))
-- (and what modmain draws itself as it flies - its DARTS, a lane each: the Walrus' dart, the Spitter's web - judged as it
-- draws them (modmain: its way from where first seen to where first gone .3 on, len from there, round width; drawn from
-- where it is to its end): the "you were struck by" of each - never judged at all till now, 2026-10-20. OLD_DARTS=1: not)
if not os.getenv("OLD_DARTS") then
    local n, dok, dmiss = 0, 0, 0
    -- (each dart's blow on you: its shooter's trace says so - "STRIKE by <dart> at wilson", where you were then; the game
    -- names the shooter as who struck you, never the dart)
    local blows = {}
    for line in MainLines() do
        local t, by, yx, yz = line:match("%[tr_trace%] ([%d%.]+) %S+ STRIKE by ([%w_]+) at wilson .- you=([%d%.%-]+),([%d%.%-]+)")
        if t ~= nil and DARTS[by] ~= nil then blows[#blows + 1] = { t = tonumber(t), by = by, yx = tonumber(yx), yz = tonumber(yz) } end
    end
    for _, s in ipairs(blows) do
        local dd = DARTS[s.by]
        -- (not one that's a thing of ours too - judged above with its hits, its lane counted there: counted twice so)
        if dd ~= nil and InPiece(s.t) and SimMovesHazard(s.by) == nil then
            n = n + 1
            local covered, near = DartCovers(s.by, s.t, s.yx, s.yz)
            if covered then dok = dok + 1 else
                dmiss = dmiss + 1
                real_print(string.format("DARTMISS %.3f %s: struck, not in its drawn lane (%.2f off its middle, lane %.2f round)", s.t, s.by,
                    near, dd.width))
            end
        end
    end
    if n > 0 then real_print(string.format("_darts: %d strikes - %d drawn, %d missed; 0 drawn-in with no strike", n, dok, dmiss)) end
end
real_print(string.format("_hazards: %d frame(s) drawn-in with no strike", false_frames))
-- (drawn leaping further in a moment than the thing went - the Eye's mini eyes, the player's report 2026-10-18)
for _, l in ipairs(rawget(_G, "TR_LANDWOB_EV") or {}) do real_print(l) end
for k, w in pairs(rawget(_G, "TR_LANDWOB") or {}) do real_print(string.format("LANDWOB %s: %d frames, %d moved over .05, %.2f in all, most %.2f; off where it came down: %d, mean %.2f, most %.2f", k, w.n, w.moved, w.dist, w.most,
    w.err_n or 0, (w.err_sum or 0) / math.max(1, w.err_n or 0), w.err_most or 0)) end
for k, n in pairs(rawget(_G, "TR_JUMP") or {}) do real_print(string.format("JUMPDRAWN %s: %d frames", k, n)) end for _, l in ipairs(rawget(_G, "TR_JUMP_EV") or {}) do real_print(l) end
for k, n in pairs(rawget(_G, "TR_GAP") or {}) do real_print(string.format("GAPDRAWN %s: %d times", k, n)) end
-- (GAP_V=1: each - when it was drawn again, after how long gone)
for _, e in ipairs(rawget(_G, "TR_GAP_EV") or {}) do real_print(string.format("GAP     %.3f %s guid=%s gone %.3f", e[1], e[2], tostring(e[3]), e[4])) end
for _, l in ipairs(rawget(_G, "TR_TRACE_EV") or {}) do real_print("TRACE   " .. l) end
if os.getenv("ATTR") then real_print(string.format("_hazards(old rule): %d drawn-in with no strike, %d frame(s)", old_in or 0, old_frames or 0)) end

if os.getenv("ALLOC_PROF") and alloc_by then local l = {} for k, v in pairs(alloc_by) do l[#l + 1] = { k, v } end table.sort(l, function(a, b) return a[2] > b[2] end) for i = 1, math.min(25, #l) do io.stdout:write(string.format("ALLOC %-30s %.1f KB a frame\n", l[i][1], l[i][2] / math.max(1, haz_frames))) end end
if os.getenv("ALLOC_PROF") and alloc_by then local l = {} for k, v in pairs(alloc_by) do l[#l + 1] = { k, v } end table.sort(l, function(a, b) return a[2] > b[2] end) for i = 1, math.min(25, #l) do io.stdout:write(string.format("ALLOC %-30s %.1f KB a frame\n", l[i][1], l[i][2] / math.max(1, haz_frames))) end end
if os.getenv("HAZ_TIME") then for k, v in pairs(kinds) do io.stdout:write(string.format("  %s %.0f a frame\n", k, v / math.max(1, haz_frames))) end end
if os.getenv("HAZ_TIME") then local SMc = require("true_range/simmoves") io.stdout:write(string.format("CACHE built %d, used %d, drawn straight %d\n", SMc._cb or 0, SMc._ch or 0, SMc._cs or 0)) end
if os.getenv("ENGINE_CALLS") then for k, v in pairs(engine_by) do io.stdout:write(string.format("  %s %.1f a frame\n", k, v / math.max(1, haz_frames))) end end
if os.getenv("ENGINE_CALLS") and regroup_new then for k, v in pairs(regroup_new) do io.stdout:write(string.format("NEWBIND %s %.2f a frame\n", k, v / math.max(1, haz_frames))) end end
if os.getenv("ENGINE_CALLS") and regroup_by then for k, v in pairs(regroup_by) do io.stdout:write(string.format("REGROUP %s %d\n", k, v)) end end
if os.getenv("ENGINE_CALLS") then local SMk = require("true_range/simmoves") for k, v in pairs(SMk._kept or {}) do io.stdout:write(string.format("KEPT %s %.1f a frame\n", k, v / math.max(1, haz_frames))) end end
if os.getenv("ENGINE_CALLS") then for k, v in pairs(require("true_range/simmoves")._qk or {}) do io.stdout:write(string.format("QK %s %.1f a frame\n", k, v / math.max(1, haz_frames))) end end
if os.getenv("ENGINE_CALLS") then for k, v in pairs(require("true_range/simmoves")._how or {}) do io.stdout:write(string.format("HOW %s %.2f a frame\n", k, v / math.max(1, haz_frames))) end end
if os.getenv("ENGINE_CALLS") then local L = require("true_range/lines") io.stdout:write(string.format("TURNS %s; revived %d; frames over 3000 calls:%s\n", tostring(L.turns), L.groups_revived or 0, heavy_frames or " none")) io.stdout:write(string.format("GROUPS made %d, trimmed %d; pieces made %d; from stock %d, stock empty %d; most made drawing one frame %d (t=%.2f); most laid one frame %d (t=%.2f), %.0f a frame\n", L.groups_made, L.groups_trimmed or 0, L.created, L.stock_taken or 0, L.stock_short or 0, most_made or 0, most_made_t or 0, most_laid or 0, most_laid_t or 0, (laid_sum or 0) / math.max(1, haz_frames))) end
if os.getenv("ENGINE_CALLS") then io.stdout:write(string.format("MOSTCALLS %d (t=%.2f)\n", most_calls or 0, most_calls_t or 0)) for k, v in pairs(most_by or {}) do if v > 0 then io.stdout:write(string.format("   %s %d\n", k, v)) end end io.stdout:write(string.format("ENGINE %.0f calls to the game a frame laying pieces, %.0f asking about things; %d pieces made\n", (engine_frame_calls or 0) / math.max(1, haz_frames), (engine_frame_asked or 0) / math.max(1, haz_frames), engine_entities)) end
if os.getenv("LINE_PROF") and line_by then local l = {} for k, v in pairs(line_by) do l[#l + 1] = { k, v } end table.sort(l, function(a, b) return a[2] > b[2] end) io.stdout:write(string.format("LINES %.0f a frame\n", line_total / math.max(1, haz_frames))) for i = 1, math.min(30, #l) do io.stdout:write(string.format("LINE %-26s %.1f a frame\n", l[i][1], l[i][2] / math.max(1, haz_frames))) end end
if os.getenv("HAZ_TIME") then io.stdout:write(string.format("HAZ_TIME %d frames: %.2f ms a frame, %.0f KB a frame made, %.0f pieces a frame", haz_frames, haz_time * 1000 / math.max(1, haz_frames), haz_mem / math.max(1, haz_frames), haz_pieces / math.max(1, haz_frames)) .. "\n") end
-- (WEAK_SIZES=1: every weak table the mod holds - found by walking from the globals and loaded
-- modules, through upvalues - with its entry count, dead ones included; GC_STOP=1: no garbage
-- collection during the replay, as between the game's far-apart cycles; then one full collect, timed)
if os.getenv("WEAK_SIZES") then
    local seen, found = {}, {}
    local function walk(v, path, depth)
        local tv = type(v)
        if (tv ~= "table" and tv ~= "function") or seen[v] or depth > 40 then return end
        seen[v] = true
        if tv == "function" then
            for i = 1, 255 do
                local n, u = debug.getupvalue(v, i)
                if not n then break end
                walk(u, path .. ">" .. n, depth + 1)
            end
            return
        end
        local mt = debug.getmetatable(v)
        if mt and type(mt.__mode) == "string" then
            local n = 0
            for _ in next, v do n = n + 1 end
            found[#found + 1] = { path, n, mt.__mode }
        end
        if mt then walk(mt, path .. "<mt>", depth + 1) end
        for k, x in next, v do
            walk(k, path .. "[k]", depth + 1)
            walk(x, path .. "." .. tostring(k):sub(1, 20), depth + 1)
        end
    end
    walk(package.loaded, "loaded", 0)
    table.sort(found, function(a, b) return a[2] > b[2] end)
    local all = 0
    for i = 1, #found do all = all + found[i][2] end
    io.stdout:write(string.format("WEAK %d weak tables, %d entries in all\n", #found, all))
    for i = 1, math.min(20, #found) do io.stdout:write(string.format("WEAK %8d  %-2s %s\n", found[i][2], found[i][3], found[i][1]:sub(1, 120))) end
    local m0, c0 = collectgarbage("count"), os.clock()
    collectgarbage("restart")
    collectgarbage("collect")
    io.stdout:write(string.format("FULLGC %.0f MB -> %.0f MB in %.0f ms\n", m0 / 1024, collectgarbage("count") / 1024, (os.clock() - c0) * 1000))
end
if os.getenv("HAZ_TIME") and slow_frames then table.sort(slow_frames, function(a, b) return a[1] > b[1] end) for i = 1, math.min(12, #slow_frames) do io.stdout:write(string.format("SLOW %.2f ms at t=%.3f, %d things\n", slow_frames[i][1] * 1000, slow_frames[i][2], slow_frames[i][3])) end end
