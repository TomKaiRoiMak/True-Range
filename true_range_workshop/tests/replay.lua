-- luajit replay.lua <mod root> <client_log.txt> <game scripts> <prefab> [from_s] [to_s] [-v]
-- Replays the server trace ([tr_trace] lines: the boss's state, time in state, position, facing,
-- and the player's position, tick by tick; STRIKE: it struck the player) through the mod's own
-- client prediction (true_range/predict + simmoves), frame by frame, and checks:
--   * every real strike: was the player inside what was drawn at that moment?
--   * every "drawn in, not struck" the drawing itself reports: was there really no strike?
-- (the mod's log lines, off in the game unless debugging (true_range modmain: debug.txt): on here)
rawset(_G, "TR_DEBUG", true)
rawset(_G, "TR_WENTLOG", {})
rawset(_G, "TR_BOTH", {})
rawset(_G, "TR_FLIP", {})
rawset(_G, "TR_JUMP", {})
rawset(_G, "TR_GAP", {})
package.path = arg[1] .. "/scripts/?.lua;" .. package.path
DEGREES, FRAMES = math.pi / 180, 1 / 30
-- (CLIENT=1: as a player's game would see it, not the host's - the monsters and their poses ENT_LAG / POSE_LAG frames late
-- (3: ~.1 s, measured on the lag bench), things drawn on ahead (HAZ_LEAD .1, as the mod does there), and you as that game
-- shows you: PRED=1 (Lag Compensation "Predictive") YOU_LEAD frames on from the server's you, PRED=0 that many behind -
-- each blow judged where you'd have seen yourself. Its numbers checked against the lag bench's own (tools/run_lag.ps1):
-- its server's log replayed so, against what its client logged. PRED=n alone: only the scenes so set ([tr_bench] lag scene))
CLIENT = os.getenv("CLIENT") ~= nil
PRED = tonumber(os.getenv("PRED") or "") or false
ENT_LAG = (tonumber(os.getenv("ENT_LAG") or "") or (CLIENT and 3 or 0)) * FRAMES
-- (CLIENT_PRED=n: on or off, every scene - a headless bench has none told)
CLIENT_PRED = PRED or tonumber(os.getenv("CLIENT_PRED") or "") or false
YOU_LEAD_F = tonumber(os.getenv("YOU_LEAD") or "") or (CLIENT and (CLIENT_PRED == 0 and -2 or 3) or false)
POSE_LAG_F = tonumber(os.getenv("POSE_LAG") or "") or (CLIENT and 3 or 0)
-- (the testbench's freezes and fires, by when ([tr_eff]) - read below)
EFF_AT = {}
-- (a thing's own blow told as its boss's "STRIKE by <thing>" too, that thing's [tr_haz] HIT that tick: judged as the effects are -
-- tr_testbench, 2026-10-28. OLD_THINGSTRIKE=1: not)
THING_AT = {}
function EffOrThing(s)
    local k = string.format("%.3f", s.t)
    return EFF_AT[k] ~= nil or (s.by ~= nil and THING_AT[k] == s.by and not os.getenv("OLD_THINGSTRIKE"))
end
-- (TR_TABLES_OFF: the mod as it was before REDESIGN.md's tables - tools/table_gate.ps1 compares)
if os.getenv("TR_TABLES_OFF") then TR_TABLES_OFF = true end
-- (DRAWLOG=1: true_range/simmoves "[tr_draw]" lines, as the local copy writes them in the game - with -v)
if os.getenv("DRAWLOG") then TR_DRAWLOG = true end
if os.getenv("TAB_DBG") then TR_TAB_DBG = true end
if os.getenv("OLD_LOCK") then TR_OLD_LOCK = true end
if os.getenv("PFDBG") then TR_PFDBG = true end
local report_done, pic_done = false, false
local now = 0
GetStaticTime = function() return now end
GetTime = GetStaticTime
function GetTableSize(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end
function DiffAngle(a, b) local d = math.abs(a - b) % 360 return d > 180 and 360 - d or d end
local pieces = 0
-- (not what's drawn aside - where standing makes it go on into another move: TR_ASIDE)
local function P() if rawget(_G, "TR_ASIDE") then return end pieces = pieces + 1 end
-- (what's filled in, frame by frame: its area and middle - a shape gone for a moment, halved, or
-- jumping off where the boss is not, is seen)
local area, cx_sum, cz_sum = 0, 0, 0
-- (and of it, what's drawn dark - winding up, coming, striking (fill, swept, strike, hit), not the pale may-strike: too big a
-- dark shape striking nothing is wrong - MacTusk's trap throw, the green tentacle's spike, 15-20 round them, BIGDARK)
local dark_area = 0
local DARK = { fill = true, swept = true, strike = true, hit = true }
-- (each go of a move: the most of it drawn dark in one frame - said if over BIGDARK_MIN square units (250: a ring 9 round))
local big_dark = {}
-- (every corner filled this frame - how far the shape reaches, FAR)
local tri_pts = { own = {} }
-- (SHAPE_CHECK=1: each frame's fills and lines looked at as a shape - tests/shapecheck.lua; TR_BREAK=
-- hole|overlap|edge: the drawing broken on purpose now and then, for the check to be seen catching it)
local SC = os.getenv("SHAPE_CHECK") and dofile((arg[0]:match("^(.*)[/\\]") or ".") .. "/shapecheck.lua") or nil
local BREAK = os.getenv("TR_BREAK")
local break_n = 0
local function Owner()
    local sm = package.loaded["true_range/simmoves"]
    local r = sm ~= nil and sm._record ~= nil and sm._record[#sm._record] or nil
    return r == nil and "0" or (#sm._record .. ":" .. tostring(r.key or "-"))
end
local function AddTri(ax, az, bx, bz, cx, cz, style)
    if ax == nil or rawget(_G, "TR_ASIDE") then return end
    if SC ~= nil then
        break_n = break_n + 1
        if BREAK == "hole" and break_n % 97 == 0 then return end
        -- (morph: a whole frame's shape set off 1.5 aside now and then)
        local o = (BREAK == "morph" and SC.n % 13 == 5) and 1.5 or 0
        SC.Tri(ax + o, az, bx + o, bz, cx + o, cz, Owner())
        if BREAK == "overlap" and break_n % 97 == 0 then SC.Tri(ax, az, bx, bz, cx, cz, Owner()) end
    end
    -- (a thing drawn in the whole frame (WHOLE): its shape looked at, not counted as the boss's - its
    -- size, middle, reach)
    if rawget(_G, "TR_HAZ_NOW") then return end
    local n = #tri_pts
    tri_pts[n + 1], tri_pts[n + 2], tri_pts[n + 3], tri_pts[n + 4], tri_pts[n + 5], tri_pts[n + 6] = ax, az, bx, bz, cx, cz
    local a = math.abs((bx - ax) * (cz - az) - (bz - az) * (cx - ax)) / 2
    area = area + a
    if DARK[style] then dark_area = dark_area + a end
    cx_sum, cz_sum = cx_sum + a * (ax + bx + cx) / 3, cz_sum + a * (az + bz + cz) / 3
    -- (and whose: each of a kind drawing at once its own - the glitch checks one by one)
    local smo = package.loaded["true_range/simmoves"]
    local o = smo ~= nil and smo._draw_owner or nil
    if o ~= nil then
        local w = tri_pts.own[o]
        if w == nil then w = { 0, 0, 0 } tri_pts.own[o] = w end
        w[1], w[2], w[3] = w[1] + a, w[2] + a * (ax + bx + cx) / 3, w[3] + a * (az + bz + cz) / 3
        if DARK[style] then w[4] = (w[4] or 0) + a end
    end
end
-- (PIC_AT=<time>: every triangle and line drawn that frame kept - written as a picture, PIC_OUT)
local pic = nil
local function PicTri(a, b, c, d, e, f, style) if pic ~= nil and a ~= nil then pic.tris[#pic.tris + 1] = { a, b, c, d, e, f, style, n = #pic.segs + #pic.tris } end end
-- (each line kept with its width and whether it's stretched past its ends - PIC_REAL paints them as
-- the game lays its pieces: true_range/lines' own widths, colours and sort orders)
local function PicSeg(a, b, c, d, style, width, exact)
    if SC ~= nil and a ~= nil and not rawget(_G, "TR_ASIDE") then
        break_n = break_n + 1
        if not (BREAK == "edge" and break_n % 97 == 0) then SC.Seg(a, b, c, d, Owner(), style) end
    end
    if pic ~= nil and a ~= nil then pic.segs[#pic.segs + 1] = { a, b, c, d, style, width, exact, n = #pic.segs + #pic.tris } end end
-- (REAL_LINES=1: the mod's own true_range/lines, not the stand-in - its pieces on stand-in entities
-- that carry their children as the game does (turned with their parent, tests/turn_groups.lua):
-- the shape's middle each frame from the pieces showing, where the world sees them - what the
-- game shows, groups, their turning and all; JUMP etc. said of that)
local REAL = os.getenv("REAL_LINES") ~= nil
local real_all = {}
if REAL then
    local function Noop() end
    CreateEntity = function()
        local e = { vis = true, lx = 0, lz = 0, rot = 0, sx = 1, sy = 1 }
        e.entity = { SetCanSleep = Noop, AddTransform = Noop, AddAnimState = Noop,
            SetParent = function(_, pe) e.parent = pe.owner end }
        e.entity.owner = e
        e.Transform = {
            SetPosition = function(_, x, _, z) e.lx, e.lz = x, z end,
            SetRotation = function(_, d) e.rot = d end,
            GetWorldPosition = function()
                local x, z = e.lx, e.lz
                local q = e.parent
                while q ~= nil do
                    local r = math.rad(q.rot)
                    x, z = q.lx + x * math.cos(r) + z * math.sin(r), q.lz - x * math.sin(r) + z * math.cos(r)
                    q = q.parent
                end
                return x, 0, z
            end,
        }
        e.AnimState = setmetatable({ SetPercent = function(_, a) e.anim = a end, SetScale = function(_, a, b) e.sx, e.sy = a, b end },
            { __index = function() return Noop end })
        function e:AddTag() end
        function e:IsValid() return not e.removed end
        function e:Show() e.vis = true end
        function e:Hide() e.vis = false end
        function e:Remove() e.vis = false e.removed = true end
        real_all[#real_all + 1] = e
        return e
    end
    ANIM_ORIENTATION, LAYER_BACKGROUND, LAYER_GROUND = { OnGround = 1 }, 4, 3
end
-- (REAL_DBG=t: about that moment, each group showing pieces - where it is, its turning, how many -
-- and the pieces not in one)
local real_dbg = tonumber(os.getenv("REAL_DBG") or "")
local function RealDump(t)
    local by = {}
    for _, e in ipairs(real_all) do
        if e.vis and not e.removed and (e.anim == "tri" or e.anim == "square" or e.anim == "disc") then
            local k = e.parent or "none"
            local b = by[k]
            if b == nil then b = { n = 0, sx = 0, sz = 0, w = 0, by = {} } by[k] = b end
            local x, _, z = e.Transform.GetWorldPosition()
            local w = math.abs(e.sx * e.sy)
            b.n, b.sx, b.sz, b.w = b.n + 1, b.sx + w * x, b.sz + w * z, b.w + w
            local ak = e.anim .. string.format('%.3f', w)
            b.by[e.anim] = (b.by[e.anim] or 0) + w
        end
    end
    for k, b in pairs(by) do
        io.stdout:write(string.format("REALDBG %.3f %s: %d pieces, middle %.2f,%.2f", t,
            k == "none" and "no group" or string.format("group at %.2f,%.2f turned %.1f (%s)", k.lx, k.lz, k.rot, tostring(k):sub(-6)), b.n, b.sx / b.w, b.sz / b.w) .. string.format(' weight %.2f (tri %.2f square %.2f disc %.2f)', b.w, b.by.tri or 0, b.by.square or 0, b.by.disc or 0) .. "\n")
    end
end
-- (REAL_HASH=1: every frame, every piece showing - kind, where the world sees it, its world turning,
-- stretch - sorted and written: drawn in groups against drawn piece by piece (NO_GROUPS=1), the
-- very same frame by frame, or a group shows something else than was meant)
local function RealHash(t)
    local out = {}
    for _, e in ipairs(real_all) do
        if e.vis and not e.removed and (e.anim == "tri" or e.anim == "square" or e.anim == "disc") then
            local x, _, z = e.Transform.GetWorldPosition()
            local turn = e.rot
            local q = e.parent
            while q ~= nil do turn = turn + q.rot q = q.parent end
            turn = (turn % 360 + 360) % 360
            if turn > 359.95 then turn = 0 end
            -- (not a sliver too thin to see - its turning a matter of rounding; places to a tenth)
            if math.abs(e.sx) >= .05 and math.abs(e.sy) >= .05 then
                -- (its turning as the way it points, to a tenth: 359.6 and 0.4 alike)
                out[#out + 1] = string.format("%s %.1f %.1f %.1f,%.1f %.1f %.1f", e.anim, x, z, math.cos(math.rad(turn)), math.sin(math.rad(turn)), e.sx, e.sy)
            end
        end
    end
    table.sort(out)
    io.stdout:write(string.format("RH %.3f %d %s\n", t, #out, table.concat(out, ";")))
end
local function RealMiddle()
    -- (the fills only - the triangles; lines round it weigh in as long as they are, and change
    -- with what strikes next: the middle moved with them though the shape did not)
    for _, e in ipairs(real_all) do
        if e.vis and not e.removed and e.anim == "tri" then
            local x, _, z = e.Transform.GetWorldPosition()
            local w = math.abs(e.sx * e.sy)
            area, cx_sum, cz_sum = area + w, cx_sum + w * x, cz_sum + w * z
            pieces = pieces + 1
        end
    end
end
if not REAL then package.loaded["true_range/lines"] = { TriRecs = function(a, b, c, d, e, f, out) out[#out + 1] = { a, b, c, d, e, f } out[#out + 1] = {} end,
    SegRec = function(a, b, c, d, _, width, exact) return { a, b, c, d, width = width, exact = exact } end, PutTri = function(r, style, dx, dz) dx, dz = dx or 0, dz or 0 P() if r[1] ~= nil then AddTri(r[1] + dx, r[2] + dz, r[3] + dx, r[4] + dz, r[5] + dx, r[6] + dz, style) PicTri(r[1] + dx, r[2] + dz, r[3] + dx, r[4] + dz, r[5] + dx, r[6] + dz, style) end end,
    PutSeg = function(r, style, dx, dz) dx, dz = dx or 0, dz or 0 P() PicSeg(r[1] + dx, r[2] + dz, r[3] + dx, r[4] + dz, style, r.width, r.exact) end, Begin = function() end,
    End = function() end, Pulse = function() end, Segment = function(a, b, c, d, style, width, exact) P() PicSeg(a, b, c, d, style, width, exact) end, Shape = P,
    Tri = function(a, b, c, d, e, f, style) P() AddTri(a, b, c, d, e, f, style) PicTri(a, b, c, d, e, f, style) end,
    Disc = P, Wedge = P, _styles = {} } end
local verbose = false
ASK = false
for i = 1, #arg do if arg[i] == "-v" then verbose = true end if arg[i] == "-ask" then ASK = true end end
local real_print = print
print = function(...) if verbose then real_print(...) end end
-- (the game's strict: reading a global nobody declares is an error there - a crash; here a name
-- the game's own scripts never use is said, as an error, once)
do
    local said, known = {}, {}
    setmetatable(_G, { __index = function(_, k)
        if type(k) ~= "string" or known[k] or said[k] then return nil end
        local fh = io.popen('findstr /s /m /r /c:"\\<' .. k .. '\\>" "' .. arg[3]:gsub("/", "\\") .. '\\*.lua" 2>nul')
        local hit = fh ~= nil and fh:read("*l") or nil
        if fh ~= nil then fh:close() end
        if hit ~= nil and hit ~= "" then known[k] = true return nil end
        said[k] = true
        real_print("UNDECLARED global read - an error in the game (strict): " .. k .. "\n" .. debug.traceback("", 2))
        return nil
    end })
end
-- (TR_MODS=<folder names>: those mods on - their monsters' moves over the game's, as the game lays them: true_range/moddata)
-- (the drawer's own switches back to before, from the shell: TR_OLD_LAND=1 ... - as the game reads them, globals)
for _, n in ipairs({ "TR_OLD_LAND", "TR_OLD_FALL", "TR_OLD_AGAIN", "TR_OLD_LANE", "TR_OLD_PENGUIN", "TR_OLD_TURNTELL", "TR_OLD_SAMEALT", "TR_OLD_SAMEFOOT", "TR_OLD_STRAIGHT", "TR_OLD_TELL", "TR_OLD_TELLWAIT", "TR_OLD_SLOW", "TR_OLD_LOB", "TR_OLD_LEAD", "TR_OLD_STILL", "TR_OLD_EARLY", "TR_OLD_HOP", "TR_OLD_LEAPAIM", "TR_OLD_ALTLOCK", "TR_OLD_LEAPTURN", "TR_OLD_FROMTELL", "TR_OLD_TELLSTILL", "TR_OLD_CHAINLOCK", "TR_OLD_TPKEEP", "TR_OLD_TELLWAITALL", "TR_OLD_AGAINLINGER", "TR_OLD_PREGO", "TR_OLD_AHEADLEG", "TR_OLD_FAR", "TR_OLD_FARTELL", "TR_OLD_BYONLY", "TR_OLD_ENDLINGER", "TR_OLD_LANEROW", "TR_OLD_AROUNDONCE", "TR_OLD_AROUNDFACE", "TR_OLD_SHADOWSIZE", "TR_OLD_LEAPSHORT", "TR_OLD_CHAINPOS", "TR_OLD_SELFGAP", "TR_OLD_AHEADOFF", "TR_OLD_SERVERAIM", "TR_OLD_SIMLANE", "TR_OLD_SERVERAIMLOCK", "TR_OLD_SERVERAIMFOLLOW", "TR_OLD_SLIDEFIT", "TR_OLD_ROUND", "TR_OLD_RESTART", "TR_OLD_OFFNET", "TR_OLD_ANIMSYNC", "TR_OLD_SNAP45", "TR_OLD_DONEAFTER", "TR_OLD_HAZLEAD", "TR_OLD_HAZSTEADY", "TR_OLD_AIMLEAD", "TR_OLD_MIDLEFT", "TR_OLD_RELOCK", "TR_OLD_BODYLEAD", "TR_OLD_LIVERADIUS", "TR_OLD_DISCKEY", "TR_OLD_TAIL", "TR_OLD_LAND2", "TR_OLD_PREVLEG", "TR_OLD_SNAPPOS", "TR_OLD_CHAINLAST", "TR_OLD_WORMDIRT", "TR_OLD_LEADSTOP", "TR_OLD_LEADTP", "TR_OLD_LANDHOLD", "TR_OLD_LANDKEEP", "TR_OLD_GLOWPULSE", "TR_OLD_GLOWGRACE", "TR_OLD_AIRSTILL", "TR_OLD_GLOWOVERLAP", "TR_OLD_LEADTPSTEP", "TR_OLD_LANDSTOP", "TR_OLD_GLOWHOLD", "TR_OLD_LANDTILL", "TR_OLD_LANDAT", "TR_OLD_HUNTSTICK", "TR_OLD_LANDLOOSE", "TR_OLD_GLOWAFTERMOVE", "TR_OLD_WORMPOUND", "TR_OLD_WENT", "TR_OLD_WENTSTART", "TR_OLD_TWIN", "TR_OLD_LANDWAIT", "TR_OLD_PICKEPIC", "TR_OLD_AIMFACING", "TR_OLD_LANDAVG", "TR_OLD_HAZLEADMOVED", "TR_OLD_FALLBACKANY", "TR_OLD_KEEPHEADING", "TR_OLD_HAZFAST" }) do if os.getenv(n) then rawset(_G, n, true) end end
if os.getenv("TR_MODS") then require("true_range/moddata").Apply(function(n) return os.getenv("TR_MODS"):find(n, 1, true) ~= nil end) end
local Predict = require("true_range/predict")
local SimMoves = require("true_range/simmoves")
-- (the bench's positions are the server's own - none of your game's lag to draw a fast thing on from: HAZ_LEAD=s for a
-- game's own log)
SimMoves.hazard_lead = tonumber(os.getenv("HAZ_LEAD") or "") or (CLIENT and .1 or 0)

local MOD, LOG, SCRIPTS, PREFAB = arg[1], arg[2], arg[3], arg[4]
-- (what stands still about that a move is laid round (predict sim.round - the Fuelweaver's atrium gate): where the
-- log says it was made, and where the testbench set it down again with its boss ("stalker_atrium moved to=") - the
-- game's own search, of those; as of the frame drawn)
do
    local fixed = nil
    Predict.ThingsNear = function(x, z, r)
        if fixed == nil then
            fixed = {}
            local gate = nil
            for line in io.lines(LOG) do
                local bt, bp, bx, bz = line:match("%[tr_ent%] ([%d%.]+) born (atrium_gate) %d+ ([%d%.%-]+) ([%d%.%-]+)")
                if bt ~= nil then
                    gate = { prefab = bp, at = { { t = tonumber(bt), x = tonumber(bx), z = tonumber(bz) } } }
                    fixed[#fixed + 1] = gate
                end
                local mt, mx, mz = line:match("%[tr_bench%] ([%d%.]+) stalker_atrium moved to=([%d%.%-]+),([%d%.%-]+)")
                if mt ~= nil and gate ~= nil then table.insert(gate.at, { t = tonumber(mt), x = tonumber(mx), z = tonumber(mz) }) end
            end
        end
        local at_t = GetTime()
        local out = {}
        for _, f in ipairs(fixed) do
            local p = nil
            for _, q in ipairs(f.at) do if q.t <= at_t + 1e-6 then p = q end end
            if p ~= nil and (p.x - x) ^ 2 + (p.z - z) ^ 2 <= r * r then out[#out + 1] = { prefab = f.prefab, cur = { x = p.x, z = p.z } } end
        end
        return out
    end
end
-- (the darts' lanes, as modmain hands them over in the game (DARTS) - SimMoves.DrawShot, a move that only shoots)
do
    local mf = io.open(MOD .. "/modmain.lua", "rb")
    local src = mf and mf:read("*a") or ""
    if mf then mf:close() end
    for name, body in (src:match("local DARTS = (%b{})") or ""):gmatch("([%w_]+) = (%b{})") do
        SimMoves.shots[name] = { len = tonumber(body:match("len = ([%d%.]+)")), width = tonumber(body:match("width = ([%d%.]+)")) }
    end
end
local FROM, TO = tonumber(arg[5] or "") or 0, tonumber(arg[6] or "") or math.huge
-- (COUNT_FROM=<t>: run from FROM, but count only what comes from t on - a log cut into pieces run side by
-- side, each begun a little early so its first move isn't caught half way, counted once; bench_replay.ps1)
local COUNT_FROM = tonumber(os.getenv("COUNT_FROM") or "") or -math.huge
-- (a picture or a pause report of one moment only: from 8s before it - the move it's in begun by
-- then - to 1s after; not the whole log)
do
    local at = tonumber(os.getenv("PIC_AT") or "") or tonumber(os.getenv("REPORT_AT") or "")
    if at ~= nil and FROM == 0 and TO == math.huge then FROM, TO = at - 8, at + 1 end
end
-- (PIC_TIMES=t1,t2,...: a picture at each, one run - a clip's frames, tests/clips.ps1; PIC_OUT then a pattern, %03d the
-- frame's number. From 8 s before the first to just after the last, as PIC_AT)
local pic_seq = { i = 1 }
for v in (os.getenv("PIC_TIMES") or ""):gmatch("[^,]+") do pic_seq[#pic_seq + 1] = tonumber(v) end
if #pic_seq > 0 and FROM == 0 and TO == math.huge then FROM, TO = pic_seq[1] - 8, pic_seq[#pic_seq] + .1 end
-- (modmain's AGGRO_WHILE, read from its source as the pictures need it: r, anims, linger, jump, core's r / warn / hit /
-- hit_after - prefab -> that)
local pic_aggro = nil
local function PicAggro()
    if pic_aggro ~= nil then return pic_aggro end
    pic_aggro = {}
    local mf = io.open(arg[1] .. "/modmain.lua", "rb")
    local src = mf and mf:read("*a") or ""
    if mf then mf:close() end
    local function Set(list)
        local s = {}
        for a in (list or ""):gmatch('"([%w_]+)"') do s[a] = true end
        return s
    end
    for name, body in (src:match("local AGGRO_WHILE = (%b{})") or ""):gmatch("\n%s*([%w_]+) = (%b{})") do
        local core = body:match("core = (%b{})") or ""
        local w = { r = tonumber(body:match("r = ([%d%.]+)")), anims = Set(body:match("anims = (%b{})")),
            linger = tonumber(body:match("linger = ([%d%.]+)")) or 0, core_r = tonumber(core:match("r = ([%d%.]+)")),
            core_warn = Set(core:match("warn = (%b{})")), core_hit = Set(core:match("hit = (%b{})")), hit_after = {} }
        for an, f in (core:match("hit_after = (%b{})") or ""):gmatch("([%w_]+) = ([%d%.]+)") do w.hit_after[an] = tonumber(f) end
        local jb = body:match("jump = (%b{})")
        if jb ~= nil then
            w.jump = { d = tonumber(jb:match("d = ([%d%.]+)")), warn = tonumber(jb:match("warn = ([%d%.]+)")), hit = tonumber(jb:match("hit = ([%d%.]+)")) }
        end
        if w.r ~= nil then pic_aggro[name] = w end
    end
    return pic_aggro
end
-- (PIC_TIMES=t1,t2,...: a picture at each, one run - frames of a clip (tests/clips.ps1); PIC_OUT then a pattern with
-- %d for its number; from 8 s before the first to 1 s after the last)
local pic_seq = {}
for v in (os.getenv("PIC_TIMES") or ""):gmatch("[^,]+") do pic_seq[#pic_seq + 1] = tonumber(v) end
pic_seq.i = 1
if #pic_seq > 0 and FROM == 0 and TO == math.huge then FROM, TO = pic_seq[1] - 8, pic_seq[#pic_seq] + 1 end

-- each state's first animation, from its stategraph (none: it plays none - hidden)
local SG_OF = { sharkboi = "SGsharkboi", minotaur = "SGminotaur", daywalker2 = "SGdaywalker2", mutatedbearger = "SGbearger",
    mutateddeerclops = "SGdeerclops", deer_red = "SGdeer", deer_blue = "SGdeer", klaus = "SGklaus", bearger = "SGbearger" }
local state_anim = {}
local state_loops = {}
do
    -- (as the offline runs made it - tools/sim_moves.lua writes them beside the game's scripts' copy)
    local ok, sg_of = pcall(dofile, (SCRIPTS:gsub("[/\\][^/\\]+[/\\]?$", "")) .. "/sg_of.lua")
    local sg_name = (ok and type(sg_of) == "table" and sg_of[PREFAB]) or SG_OF[PREFAB] or ("SG" .. PREFAB)
    local fh = io.open(SCRIPTS .. "/stategraphs/" .. sg_name .. ".lua", "rb")
    -- (not named after it - the Twins run the Eye of Terror's: the one its prefab's file sets, the
    -- file that makes Prefab("<it>"))
    if fh == nil then
        -- (named as written, a space or a folder before it too - Tropical Experience's Prefab( "monsters/crocodog", ...):
        -- looked for by its name in quotes, told by Lua's own pattern)
        local p = io.popen('findstr /m /c:"' .. PREFAB .. '\\"" "' .. SCRIPTS:gsub("/", "\\") .. '\\prefabs\\*.lua" 2>nul')
        for path in p:lines() do
            local pf = io.open(path:gsub("%s+$", ""), "rb")
            local ptext = pf and pf:read("*a") or ""
            if pf then pf:close() end
            local sg = ("\n" .. ptext):find('[^%w_]Prefab%(%s*"[%w_/]-%f[%w_]' .. PREFAB:gsub("%W", "%%%0") .. '"') and ptext:match('SetStateGraph%(%s*"([%w_]+)"') or nil
            if sg ~= nil then sg_name = sg break end
        end
        p:close()
        fh = io.open(SCRIPTS .. "/stategraphs/" .. sg_name .. ".lua", "rb")
    end
    local text = ""
    if fh ~= nil then text = fh:read("*a") fh:close() else real_print("ERROR no stategraph found for " .. PREFAB .. " - nothing drawn for it in this replay") end
    local pos = 1
    while true do
        local s, e, name = text:find('State%s*{%s*name%s*=%s*"([%w_]+)"', pos)
        if s == nil then break end
        local nxt = text:find('State%s*{%s*name%s*=', e) or #text
        local body = text:sub(e, nxt)
        local enter = body:match("onenter%s*=%s*function(.-)\n%s*end,") or body
        local anim = enter:match('PlayAnimation%(%s*"([%w_]+)"')
        state_anim[name] = anim or false
        -- (played looping: begun over in the same state, it's the same one again - the Eye of
        -- Terror's mouth charge, charge_loop going round - not the next of its move)
        if anim ~= nil and enter:find('PlayAnimation%(%s*"' .. anim .. '"%s*,%s*true') then state_loops[name] = true end
        pos = e
    end
    -- (states its stategraph takes from commonstates.lua - a deer's attack: its own animations as
    -- that gives them, unless handed others (anims = { attack = ... }: not known here)
    if text:find("CommonStates%.AddCombatStates") then
        for name, anim in pairs({ attack = "atk", death = "death" }) do
            if state_anim[name] == nil then state_anim[name] = anim end
        end
    end
end

-- (the log read once: every line the passes below go through kept (MAIN_LINES - all but the things'),
-- the things' own lines ([tr_haz] ... pos=) taken apart as they're read (HZ_*) - read five times over,
-- each a whole log, was most of a replay's time once its loops were mended; VERIFY_PLAN 6.15.
-- OLD_READ=1: each pass reads the file itself, as before)
local OLD_READ = os.getenv("OLD_READ") ~= nil
local MAIN_LINES, LOG_HAS_HAZ = {}, false
local HZ_t, HZ_p, HZ_g, HZ_x, HZ_z, HZ_n = {}, {}, {}, {}, {}, 0
if not OLD_READ then
    local nm = 0
    for line in io.lines(LOG) do
        local c = line:find("[tr", 1, true)
        if c ~= nil then
            if line:find("[tr_haz]", c, true) == c then
                LOG_HAS_HAZ = true
                local t, prefab, guid, x, z = line:match("%[tr_haz%] ([%d%.]+) ([%w_]+) guid=(%d+) pos=([%d%.%-]+),([%d%.%-]+)", c)
                if t ~= nil then
                    HZ_n = HZ_n + 1
                    HZ_t[HZ_n], HZ_p[HZ_n], HZ_g[HZ_n], HZ_x[HZ_n], HZ_z[HZ_n] = t, prefab, guid, x, z
                end
            else
                nm = nm + 1
                MAIN_LINES[nm] = line
            end
        end
    end
end
-- (the lines a pass goes through: the kept ones, or the file as before)
local function MainLines()
    if OLD_READ then return io.lines(LOG) end
    local i = 0
    return function() i = i + 1 return MAIN_LINES[i] end
end
-- (each [tr_haz] ... pos= line's t, prefab, guid, x, z - strings, as line:match gave them)
local function HazLines()
    if OLD_READ then
        local it = io.lines(LOG)
        return function()
            while true do
                local line = it()
                if line == nil then return nil end
                local t, prefab, guid, x, z = line:match("%[tr_haz%] ([%d%.]+) ([%w_]+) guid=(%d+) pos=([%d%.%-]+),([%d%.%-]+)")
                if t ~= nil then return t, prefab, guid, x, z end
            end
        end
    end
    local i = 0
    return function()
        i = i + 1
        if i > HZ_n then return nil end
        return HZ_t[i], HZ_p[i], HZ_g[i], HZ_x[i], HZ_z[i]
    end
end

-- the trace (one line per boss per tick; several of a kind at once: told apart by GUID if the
-- line has one, else by where each was last)
local ticks, strikes, has_hits = {}, {}, false
-- (a piece of the log (FROM > 0): what it takes from the whole - below, where the trace is read)
local LOG_FIRST_T, LOG_REACH = nil, nil
local GUID_FIRST = {}
local PIECE = FROM > 0 and not os.getenv("OLD_PIECE")
-- (struck by what it shot - a Walrus' dart, a Spitter's web come to you: "STRIKE by <it>" (modmain); its
-- hit the same blow. Counted apart, not judged: the darts are drawn by modmain's own code (DARTS), not
-- here - not to be called missed nor drawn till they are; VERIFY_PLAN C1)
local shot_strikes = {}
local DARTS = { blowdart_walrus = true, spider_web_spit = true, spider_web_spit_acidinfused = true }  -- (modmain.lua's DARTS)
local thing_hits = {}  -- (struck by something it set off - a deer's spell circle: no miss if not drawn, no false alarm if drawn)
-- what's round each boss, as the trace logged it ([tr_env]): the ground it may stand on, and
-- each thing with a body - the replay's world answers from it (no log of it: open flat ground)
COLLISION = { OBSTACLES = 512, SMALLOBSTACLES = 8192 }
local grounds, things_at = {}, {}
for line in MainLines() do
    local t, prefab, kind, rest = line:match("%[tr_env%] ([%d%.]+) ([%w_]+) guid=%d+ (%a+) (.*)$")
    if t ~= nil and prefab == PREFAB then
        if kind == "ground" then
            local x0, z0, n, rows = rest:match("x0=(%-?%d+) z0=(%-?%d+) step=1 n=(%d+) (.*)$")
            -- (written in parts now - row0=: each its first row; the parts of one grid joined. A log from
            -- before: one line, from row 0)
            local row0 = tonumber(rows:match("^row0=(%d+) ") or "")
            if row0 ~= nil then rows = rows:gsub("^row0=%d+ ", "") end
            local last = grounds[#grounds]
            local g
            if row0 ~= nil and row0 > 0 and last ~= nil and last.x0 == tonumber(x0) and last.z0 == tonumber(z0) and last.t == t then
                g = last
            else
                g = { x0 = tonumber(x0), z0 = tonumber(z0), n = tonumber(n), rows = {}, t = t }
                table.insert(grounds, g)
            end
            local k = row0 or 0
            for r in rows:gmatch("[01]+") do k = k + 1 g.rows[k] = r end
        elseif kind == "things" then
            for name, x, z, r, group, work, combat in rest:gmatch("([%w_?]+):([%d%.%-]+),([%d%.%-]+),([%d%.%-]+),(%d+),(%d),(%d)") do
                local key = string.format("%.1f,%.1f,%s", tonumber(x), tonumber(z), name)
                if not things_at[key] then
                    things_at[key] = { prefab = name, x = tonumber(x), z = tonumber(z), r = tonumber(r), group = tonumber(group),
                        work = work == "1", combat = combat == "1" }
                end
            end
        end
    end
end
local thing_list = {}
for _, v in pairs(things_at) do
    local e = { prefab = v.prefab, Transform = {}, Physics = {} }
    function e.Transform:GetWorldPosition() return v.x, 0, v.z end
    function e.Physics:GetCollisionGroup() return v.group end
    function e:GetPhysicsRadius() return v.r end
    function e:HasTag(tag)
        if tag == "_combat" then return v.combat end
        if tag:find("_workable$") then return v.work end
        return false
    end
    e._v = v
    table.insert(thing_list, e)
end
if #grounds > 0 or #thing_list > 0 then
    TheWorld = { Map = {} }
-- (FAKE_ARENA=x,z: in the Scion's arena, its barrier up, its middle there - the supernova drawn so)
if os.getenv("FAKE_ARENA") then
    local ax, az = os.getenv("FAKE_ARENA"):match("([%d%.%-]+),([%d%.%-]+)")
    TheWorld.Map.IsPointInWagPunkArenaAndBarrierIsUp = function() return true end
    TheWorld.Map.GetWagPunkArenaCenterXZ = function() return tonumber(ax), tonumber(az) end
end
    function TheWorld.Map:IsPassableAtPoint(x, y, z)
        -- (a row the trace never wrote - its ground line cut at the game's 4,095 characters, 49 of 81 rows: looked
        -- for in the others written, each round where the boss stood then; none has it - not known. The newest
        -- alone was asked, wherever the boss was then: the shark's bite vs its attack undecided 11,968 of 12,277.
        -- The twins agent, 2026-10-19. OLD_MAPROWS=1: as before)
        local unknown = false
        for i = #grounds, 1, -1 do
            local g = grounds[i]
            local col, row = math.floor(x + .5) - g.x0, math.floor(z + .5) - g.z0
            if col >= 0 and row >= 0 and col < g.n and row < g.n then
                local r = g.rows[row + 1]
                if r ~= nil and #r > col then return r:sub(col + 1, col + 1) == "1" end
                if os.getenv("OLD_MAPROWS") then return nil end
                unknown = true
            end
        end
        if unknown then return nil end
        return true
    end
    TheSim = {}
    function TheSim:FindEntities(x, y, z, r, must, cant)
        local out = {}
        for _, e in ipairs(thing_list) do
            local v = e._v
            if (v.x - x) ^ 2 + (v.z - z) ^ 2 <= r * r then
                local skip = false
                for _, tag in ipairs(cant or {}) do if e:HasTag(tag) then skip = true end end
                if not skip then table.insert(out, e) end
            end
        end
        return out
    end
end
local scene_of = {}  -- guid -> what the offline run was (a trace made by the sim)
-- (how big it was, the trace not saying: as the mod saw it - "(its size 1.68, run offline at ...)" -
-- from then on; enraged Klaus drawn as the smaller one, its chomp too short)
local size_seen = nil
-- (who "you" are: a trace says " me=" - the host; YOU=prefab for an older one (a game with a
-- friend: the host wolfgang, the friend wilson - every strike on the friend was taken as on you))
local YOU = os.getenv("YOU") or "wilson"
local WALK = os.getenv("WALK") ~= nil
-- (struck by a thing of its own - its lavae, its glass: "[true_range] you were struck by <thing>", with no
-- time of its own - at the boss's last trace line before it; its things as tr_env lists them round it)
local things_of, last_t, traced = {}, nil, {}
-- (when it harmed you: [tr_hurt] lines, guid@ms - a log with none of them, older, everything taken as harm)
HURT_AT, LOG_HAS_HURT = {}, false
for line in MainLines() do
    local me_p = line:match("%[tr_trace%] [%d%.]+ [%w_]+ .* me=([%w_]+)")
    if me_p ~= nil and me_p ~= "?" then YOU = me_p end
    local env_p, env_things = line:match("%[tr_env%] [%d%.]+ ([%w_]+) guid=%d+ things (.*)$")
    if env_p == PREFAB then for name in env_things:gmatch("([%w_]+):") do things_of[name] = true end end
    local by_thing = line:match("%[true_range%] you were struck[^,]* by ([%w_]+),")
    -- (its things listed maybe only later on: told apart once all is read)
    if by_thing ~= nil and by_thing ~= PREFAB and last_t ~= nil and last_t >= FROM and last_t <= TO then
        table.insert(thing_hits, { t = last_t, by = by_thing })
    end
    local hu_t, hu_p, hu_g = line:match("%[tr_hurt%] ([%d%.]+) ([%w_]+) (%d+) ")
    -- (a bench's: the testbench writes [tr_hit] and [tr_hurt] alike - a piece of it with no harm in it has
    -- [tr_hit] lines only; the tikiman's share, 2026-10-22)
    if hu_t ~= nil or line:find("[tr_hit]", 1, true) then LOG_HAS_HURT = true end
    -- (frozen or set alight with no blow, told as the boss's "STRIKE by <thing>" by the testbench ([tr_eff]): that thing's own)
    local ef_t = line:match("%[tr_eff%] ([%d%.]+) [%a ]+ by [%w_]+ pos=")
    if ef_t ~= nil then EFF_AT = EFF_AT or {} EFF_AT[ef_t] = true end
    local th_t, th_p = line:match("%[tr_haz%] ([%d%.]+) ([%w_]+) guid=%d+ HIT")
    if th_t ~= nil then THING_AT[th_t] = th_p end
    if hu_t ~= nil then
        if hu_p == PREFAB then HURT_AT[hu_g .. "@" .. math.floor(tonumber(hu_t) * 1000 + .5)] = true end
    end
    local lt_p, lt = line:match("%[tr_trace%] ([%d%.]+) ([%w_]+) ")
    if lt == PREFAB then last_t = tonumber(lt_p) end
    if lt ~= nil then traced[lt] = true end
    local sz_p, sz = line:match("%[true_range%] ([%w_]+) [^%(]*%(its size ([%d%.]+), run offline")
    if sz_p == PREFAB then size_seen = tonumber(sz) end
    local sg, sp, ss, sn = line:match("%[tr_trace%] SCENE (%d+) ([%w_]+) ([%w_]+) (.+)$")
    if sg ~= nil and sp == PREFAB then scene_of[sg] = ss .. ", " .. sn end
    local t, prefab, rest = line:match("%[tr_trace%] ([%d%.]+) ([%w_]+) (.*)$")
    if t ~= nil and prefab == PREFAB then
        t = tonumber(t)
        -- (what a piece of the log must take from the whole of it, to come out as the whole does: its first
        -- tick - the frames stepped from there; each one's first - when it's looked at again; how far off
        -- any blow of its ever landed - Dodged's reach. VERIFY_PLAN 6.15 (a2))
        LOG_FIRST_T = LOG_FIRST_T or t
        local g0 = rest:match("guid=(%d+)")
        if g0 ~= nil and GUID_FIRST[g0] == nil then GUID_FIRST[g0] = t end
        if rest:find("^HIT at " .. YOU .. " ") then
            local hx, hz = rest:match("pos=([%d%.%-]+),([%d%.%-]+)")
            local hyx, hyz = rest:match("you=([%d%.%-]+),([%d%.%-]+)")
            if hx ~= nil and hyx ~= nil then
                LOG_REACH = math.max(LOG_REACH or 0, math.sqrt((tonumber(hyx) - tonumber(hx)) ^ 2 + (tonumber(hyz) - tonumber(hz)) ^ 2))
            end
        end
        if t >= FROM and t <= TO then
            local st, ts, at = rest:match("state=([%w_]+) t=([%d%.%-]+) anim_t=([%d%.%-]+)")
            local px, pz = rest:match("pos=([%d%.%-]+),([%d%.%-]+)")
            local rot = rest:match("rot=([%d%.%-]+)")
            local yx, yz = rest:match("you=([%d%.%-]+),([%d%.%-]+)")
            local guid = rest:match("guid=(%d+)")
            local vx, vz = rest:match("yvel=([%d%.%-]+),([%d%.%-]+)")
            local anim = rest:match("anim=([%w_]+)")
            local scale = tonumber(rest:match("scale=([%d%.]+)") or "") or size_seen
            if rest:find("^HIT at " .. YOU .. " ") then has_hits = true end
            if rest:find("^THINGHIT at " .. YOU .. " ") then table.insert(thing_hits, { t = t }) end
            -- ("its target": struck with no one named (DoAttack()) - the trace written only while you're its
            -- target: you - a Prime Mate's every strike, never counted)
            -- (only shot off, "LAUNCH": no strike yet - not one here)
            -- (only those modmain draws itself (its DARTS) set apart - the rest, a monkey's poop, the Spat's
            -- snot, drawn by no one: strikes judged as ever)
            local shot_by = rest:match("^STRIKE by ([%w_]+) at " .. YOU .. " ") or rest:match("^STRIKE by ([%w_]+) at its target ")
            if shot_by ~= nil and DARTS[shot_by] then
                table.insert(shot_strikes, { t = t, by = shot_by, guid = guid, x = tonumber(yx), z = tonumber(yz), bx = tonumber(px), bz = tonumber(pz) })
            elseif shot_by ~= nil or rest:find("^STRIKE at " .. YOU .. " ") or rest:find("^STRIKE at its target ") or rest:find("^HIT at " .. YOU .. " ") then
                table.insert(strikes, { t = t, state = st, x = tonumber(yx), z = tonumber(yz), bx = tonumber(px), bz = tonumber(pz), guid = guid,
                    hit = rest:find("^HIT") ~= nil, by = shot_by, vx = tonumber(vx), vz = tonumber(vz) })
            elseif rest:find("^after") and st ~= nil then
                -- (WALK=1: you where a player walking about would be, not where the stand-in was - in at it
                -- and out again (1 to 12 off, every 6 s) and round it: what's drawn as you go from one
                -- distance's map to the next (VERIFY_PLAN 6.16, I9). Only what's drawn means anything then -
                -- the glitches, FLIP/BOTH/JUMP; strikes, missed and false are the stand-in's, not yours)
                if WALK and px ~= nil then
                    local d = 6.5 + 5.5 * math.sin(2 * math.pi * t / 6)
                    local a = t * .5
                    local wx, wz = tonumber(px) + d * math.cos(a), tonumber(pz) + d * math.sin(a)
                    local d2 = 6.5 + 5.5 * math.sin(2 * math.pi * (t + FRAMES) / 6)
                    local a2 = (t + FRAMES) * .5
                    vx, vz = (tonumber(px) + d2 * math.cos(a2) - wx) / FRAMES, (tonumber(pz) + d2 * math.sin(a2) - wz) / FRAMES
                    -- (its target, when that was the stand-in, you too - else aimed now at the stand-in, now at
                    -- you, its shape leaping between: a thing no game shows, you are its target there)
                    local ox, oz = tonumber(yx), tonumber(yz)
                    for _, key in ipairs({ "tgt", "tpos" }) do
                        local gx, gz = rest:match(" " .. key .. "=([%d%.%-]+),([%d%.%-]+)")
                        if gx ~= nil and ox ~= nil and (tonumber(gx) - ox) ^ 2 + (tonumber(gz) - oz) ^ 2 < .25 then
                            rest = rest:gsub(" " .. key .. "=[%d%.%-]+,[%d%.%-]+", string.format(" %s=%.3f,%.3f", key, wx, wz), 1)
                        end
                    end
                    yx, yz = wx, wz
                end
                table.insert(ticks, { t = t, state = st, ts = tonumber(ts), anim_t = tonumber(at), x = tonumber(px), z = tonumber(pz),
                    rot = tonumber(rot), yx = tonumber(yx), yz = tonumber(yz), guid = guid, yvx = tonumber(vx), yvz = tonumber(vz),
                    anim = anim, scale = scale, notarget = rest:find(" notarget", 1, true) ~= nil, forms = rest:match(" forms=(%S+)"),
                    tx = tonumber(rest:match(" tgt=([%d%.%-]+),") or ""), tz = tonumber(rest:match(" tgt=[%d%.%-]+,([%d%.%-]+)") or ""),
                    ram_t = tonumber(rest:match(" ram=([%d%.%-]+),") or ""), ram_d = tonumber(rest:match(" ram=[%d%.%-]+,([%d%.%-]+)") or ""),
                    tpx = tonumber(rest:match(" tpos=([%d%.%-]+),") or ""), tpz = tonumber(rest:match(" tpos=[%d%.%-]+,([%d%.%-]+)") or ""),
                    -- (how it looks - " build=", traced; a log from before: BUILD_BY_STATE=state=build,... as its states set it)
                    build = rest:match(" build=(%S+)") or (os.getenv("BUILD_BY_STATE") and ("," .. os.getenv("BUILD_BY_STATE") .. ","):match("," .. st .. "=([^,]+),") or nil) })
            end
        end
    end
end
-- (WHOLE=1: the whole frame, as the game draws it - every thing set off ([tr_haz]), whatever set it off,
-- drawn too, through the mod's own Predict.DrawHazards, after the boss each frame: for SHAPE_CHECK and
-- the pictures only - the strikes counted as ever, of the boss. Its moves and its things side by side,
-- a rock's ring beside its rock: what the game shows, apart till now (replay_haz.lua with no boss
-- drawn, and its own rule for which to leave out - not the game's))
local WHOLE = os.getenv("WHOLE") ~= nil
local haz_ents = {}
if WHOLE then
    local by_guid = {}
    for line in io.lines(LOG) do
        local t, prefab, guid, rest = line:match("%[tr_haz%] ([%d%.]+) ([%w_]+) guid=(%d+) (.*)$")
        if t ~= nil and not rest:find("^HIT") then
            local x, z = rest:match("pos=([%d%.%-]+),([%d%.%-]+)")
            if x ~= nil then
                local tr = by_guid[guid]
                if tr == nil then tr = { prefab = prefab, ticks = {} } by_guid[guid] = tr end
                tr.ticks[#tr.ticks + 1] = { t = tonumber(t), x = tonumber(x), z = tonumber(z), rot = tonumber(rest:match("rot=([%d%.%-]+)")),
                    y = tonumber(rest:match(" y=([%d%.%-]+)")), scale = tonumber(rest:match("scale=([%d%.%-]+)")) }
            end
        end
    end
    for guid, tr in pairs(by_guid) do
        local e = { prefab = tr.prefab, GUID = 900000000 + tonumber(guid), Transform = {}, AnimState = {}, i = 1, tr = tr }
        function e:IsValid() return e.cur ~= nil end
        function e:HasTag() return false end
        function e.Transform:GetWorldPosition() return e.cur.x, e.cur.y or 0, e.cur.z end
        function e.Transform:GetScale() local s = e.cur.scale return s, s, s end
        function e.Transform:GetRotation() return e.cur.rot or 0 end
        function e.AnimState:IsCurrentAnimation() return false end
        function e.AnimState:GetCurrentAnimationTime() return math.max(0, now - tr.ticks[1].t) end
        haz_ents[#haz_ents + 1] = e
    end
end
local function HazardsNow(t)
    local list = {}
    for _, e in ipairs(haz_ents) do
        local tk = e.tr.ticks
        while e.i < #tk and tk[e.i + 1].t <= t + 1e-6 do e.i = e.i + 1 end
        local c = tk[e.i]
        -- (there from its first line to its last, where it was last said to be between - the mod writes a
        -- line only as it changes, tools/expand_haz.lua makes one a tick of it: a log not gone through that
        -- had things vanish between their lines)
        if c.t <= t + 1e-6 and (e.i < #tk or t - c.t < 2 * FRAMES) then e.cur = c list[#list + 1] = e else e.cur = nil end
    end
    return list
end
-- (THING_ALL=1: every "struck by" kept, near this boss or not - each judged below with THING_V: whether anything was drawn
-- where you stood, for a thing with no data of its own - tools/nothing_check.lua's list, 2026-10-20)
local thing_all = os.getenv("THING_ALL") ~= nil
for k = #thing_hits, 1, -1 do
    local by = thing_hits[k].by
    if thing_all then break end
    -- (nor a monster of its own, traced itself - tr_env lists all round it: a Mini Eye, another boss)
    -- (but kept, one of the things this boss itself puts out - the Twins' lasers, no body of their own, so
    -- never in tr_env's list: 198 real laser hits thrown away, every frame drawn round them FALSE. OLD_PUTS=1: as before)
    local put_by_me = false
    if by ~= nil and not os.getenv("OLD_PUTS") then
        local h = (require("true_range/simmoves").Hazards() or {})[by]
        for _, b in ipairs(h and h.by or {}) do if b == PREFAB then put_by_me = true end end
    end
    if by ~= nil and not put_by_me and (not things_of[by] or traced[by]) then table.remove(thing_hits, k) end
end
-- (a hit the boss's own combat dealt, through a thing it set off - the Scrappy Werepig's junk
-- strikes with its combat, so the trace has the boss hitting you 20 away as it rummages: one of
-- its things ([tr_haz], its hazards' "by" this boss) right by you then - not its move's: not
-- counted here, said as BYTHING; the things are replay_haz.lua's)
local by_thing = {}
do
    local THING_NEAR, OWN_FAR = 3.5, 6
    local own = {}
    local SM = require("true_range/simmoves")
    -- (and modmain's DARTS that name their boss (by) - shot by its combat, their blows put down to it: as_boss, as one of the
    -- data's things - Tropical Experience's lizardman's spit; tests/replay_haz.lua the same. OLD_DART_ASBOSS=1: not)
    local HZ = setmetatable({}, { __index = SM.Hazards() or {} })
    if not os.getenv("OLD_DART_ASBOSS") then
        local mf = io.open(MOD .. "/modmain.lua", "rb")
        local src = mf and mf:read("*a") or ""
        if mf then mf:close() end
        for name, body in (src:match("local DARTS = (%b{})") or ""):gmatch("([%w_]+) = (%b{})") do
            local by = body:match('by = "([%w_]+)"')
            if by ~= nil then
                -- (one the data has as a thing too - Uncompromising Mode's guards' stinger: that, its boss added, as_boss)
                local h0 = (SM.Hazards() or {})[name]
                local h = {}
                for k, v in pairs(h0 or {}) do h[k] = v end
                local bys = { by }
                for _, b in ipairs(h.by or {}) do if b ~= by then bys[#bys + 1] = b end end
                h.by, h.as_boss, h.in_move = bys, true, nil
                h.moved = h0 == nil and true or h.moved
                h.strikes_until = math.max(h.strikes_until or 0, tonumber(body:match("strikes_until = (%d+)")) or 0)
                HZ[name] = h
            end
        end
    end
    for name, h in pairs(SM.Hazards() or {}) do
        -- (not one drawn with its move - a laser: that move's own, counted there)
        for _, b in ipairs(h.by or {}) do if b == PREFAB and not h.in_move then own[name] = true end end
    end
    for name, h in pairs(HZ) do
        for _, b in ipairs(h.by or {}) do if b == PREFAB then own[name] = true end end
    end
    local near = {}   -- time (ms) -> { x, z, age (s since first seen), its hazard } of its things then
    -- (a log gone through tools/expand_haz.lua - a line a tick for each: one standing still is
    -- written by the game only as it appears)
    if next(own) ~= nil then
        local first, last, at = {}, {}, {}
        for t, prefab, g, x, z in HazLines() do
            if t ~= nil and own[prefab] then
                t = tonumber(t)
                -- (its age from when it last came back - one kept in a pool and set out again, the
                -- Possessed Varg's flames: the same GUID each breath, its first time long gone)
                -- (or set out again somewhere else straight away - Deerclops' ice spikes, from its pool,
                -- never gone a frame: aged from their first time, 198 of its blows handed to nobody once
                -- their strikes_until was the game's 3, not 8 - as the drawer does, true_range/simmoves)
                local p = at[g]
                local hz0 = HZ[prefab]
                local moved_on = p ~= nil and not (hz0 and hz0.moved) and (p[1] - tonumber(x)) ^ 2 + (p[2] - tonumber(z)) ^ 2 > .25
                if last[g] == nil or t - last[g] > .1 or moved_on then first[g] = t end
                last[g] = t
                at[g] = { tonumber(x), tonumber(z) }
                local k = math.floor(t * 1000 + .5)
                near[k] = near[k] or {}
                table.insert(near[k], { tonumber(x), tonumber(z), t - first[g], HZ[prefab] })
            end
        end
    end
    -- (not "a HIT with no STRIKE": that is mostly the boss's own area blow, a DoAttack out of reach
    -- falling to DoAreaAttack round itself - the Celestial Champion's stab; VERIFY_PLAN 6.12b)
    -- (or one whose blows the game puts down to the boss (as_boss, from the offline runs: UM Bearger's
    -- sinkholes 4.5 from it, the Shadow Thrall's darts) by you while it still strikes - strikes_until
    -- frames from when it appeared, +2: a sinkhole lies there seconds after its last, a swipe of the
    -- boss's own over it the boss's; VERIFY_PLAN 6.12b)
    -- (how far round itself a thing strikes, as drawn - its cells' furthest: the Celestial Champion's spike wall
    -- raised 8 to either side of where its trail stopped - its blows 4-10 off it taken for its stab's, 41 "missed"
    -- once the stab was no longer drawn as a blob round all of them, 2026-10-20. OLD_THING_NEAR=1: 3.5 for all)
    local far_of = {}
    local function NearOf(h)
        if h == nil or os.getenv("OLD_THING_NEAR") then return THING_NEAR end
        if far_of[h] == nil then
            local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"
            -- (the data's _grid: step .25, row 0 / column 0 the cell at side -20 / ahead -20)
            local step, a0, s0 = .25, -20, -20
            local far = 0
            for _, st in ipairs(h.steps or {}) do
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
            far_of[h] = math.max(THING_NEAR, far + .5)
        end
        return far_of[h]
    end
    -- (a STRIKE with no HIT of it the same tick, in a log that tells HITs: its blow fell on no one - out of its reach, the
    -- Celestial Champion's stab at its target 5.6 off each time round its summon (atk_summon_loop do_stab_attack): 46 of a
    -- log's "missed", none of them landing; 2026-10-26. OLD_STRIKENOHIT=1: as before)
    if not os.getenv("OLD_STRIKENOHIT") then
        local hit_at, any_hit = {}, false
        for _, s in ipairs(strikes) do if s.hit then any_hit = true hit_at[string.format("%.3f|%s", s.t, tostring(s.guid))] = true end end
        if any_hit then
            local kept = {}
            for _, s in ipairs(strikes) do
                -- (or a freeze, a fire with no blow ([tr_eff]): no HIT of it ever, it landed all the same)
                if s.hit or hit_at[string.format("%.3f|%s", s.t, tostring(s.guid))]
                    or (EffOrThing(s) and not os.getenv("OLD_EFFBY")) then kept[#kept + 1] = s end
            end
            strikes = kept
        end
    end
    local keep = {}
    -- (a HIT is told with no "by": the STRIKE of the same tick says whose - else the missile's blow, handed to it, left
    -- its HIT as the Queen's own, missed; 2026-10-26. OLD_HITBY=1: as before)
    if not os.getenv("OLD_HITBY") then
        local by_at = {}
        for _, s in ipairs(strikes) do if s.by ~= nil then by_at[string.format("%.3f|%s", s.t, tostring(s.guid))] = s.by end end
        for _, s in ipairs(strikes) do if s.by == nil and s.hit then s.by = by_at[string.format("%.3f|%s", s.t, tostring(s.guid))] end end
    end
    for _, s in ipairs(strikes) do
        local hit_by, by_own = false, false
        if s.x ~= nil then
            for dk = -70, 70 do
                for _, p in ipairs(near[math.floor(s.t * 1000 + .5) + dk] or {}) do
                    local R = NearOf(p[4])
                    if (p[1] - s.x) ^ 2 + (p[2] - s.z) ^ 2 <= R * R then
                        hit_by = true
                        local h = p[4]
                        if h ~= nil and h.as_boss and p[3] <= ((h.strikes_until or 0) + 2) * FRAMES then by_own = true end
                    end
                end
            end
        end
        -- (as_boss, the boss near: its thing's only if its move didn't cover you - judged below. Handed
        -- over every time, the blows its move drew were taken from it, its drawing then "drawn in, not
        -- struck": Bearger's swipe fx, FALSE 5 -> 145; VERIFY_PLAN 6.0a)
        -- (or told so: "STRIKE by <thing>", a thing of the boss's own we draw (_hazards) striking with the boss's combat - the
        -- Shrouded Queen's shadow missiles (AOEUtil, attacker its caster): 106 "missed" with her standing idle, each the
        -- missile's; 2026-10-23 update. OLD_STRIKEBY=1: as before)
        if not by_own and hit_by and s.by ~= nil and not os.getenv("OLD_STRIKEBY") and SimMoves.Hazards()[s.by] ~= nil then by_own = true end
        -- (or a freeze, a fire with no blow, the testbench says by which thing ([tr_eff] that tick): that thing's, near or not -
        -- a splash gone before it was traced near. OLD_EFFBY=1: as above only)
        if not by_own and s.by ~= nil and EffOrThing(s) and not os.getenv("OLD_EFFBY")
            and SimMoves.Hazards()[s.by] ~= nil then by_own = true end
        s.by_own = by_own or nil
        -- (BYOWN_V=1: each strike's finding)
        if os.getenv("BYOWN_V") then real_print(string.format("BYOWN %.3f by=%s near=%s own=%s", s.t, tostring(s.by), tostring(hit_by), tostring(by_own))) end
        -- (and it far off - further than anything of its own reaches you)
        if hit_by and s.bx ~= nil and (s.x - s.bx) ^ 2 + (s.z - s.bz) ^ 2 > OWN_FAR * OWN_FAR then
            local last = by_thing[#by_thing]
            -- (only those in the stretch counted - a piece's lead-in is the piece before's: VERIFY_PLAN 6.15)
            if (last == nil or math.abs(last.t - s.t) >= .05) and s.t >= COUNT_FROM then by_thing[#by_thing + 1] = s end
        else
            keep[#keep + 1] = s
        end
    end
    strikes = keep
end
-- (the hit of a dart that came to you: its own blow, counted with it above - not the boss's; the one
-- hit of that same one in that same tick, no other - a pack's bites beside its spit)
if #shot_strikes > 0 then
    local keep, used = {}, {}
    for _, s in ipairs(strikes) do
        local shot = false
        if s.hit then
            for k, o in ipairs(shot_strikes) do
                if not used[k] and o.guid == s.guid and math.abs(o.t - s.t) < 1e-3 then used[k], shot = true, true break end
            end
        end
        if not shot then keep[#keep + 1] = s end
    end
    strikes = keep
end
-- (a shot of its that came to you and did no harm - a monkey's poop (monkeyprojectile, MONKEY_RANGED_DAMAGE 0: "attacked"
-- with damage 0, your sanity down a little): no [tr_hurt] that tick - nothing to warn of, drawing it the dark lane that harms
-- no one; the tikiman's 5 throws from 10-20 off counted missed, 2026-10-22. Only a log that has [tr_hurt] lines; that blow's
-- HIT line that tick with it. OLD_NOHARM_SHOT=1: judged as ever)
if LOG_HAS_HURT and not os.getenv("OLD_NOHARM_SHOT") then
    local keep, noharm, gone = {}, 0, {}
    for _, s in ipairs(strikes) do
        -- (not a freeze or a fire told so ([tr_eff]) - no harm that tick, the harm is the freeze)
        local eff = EffOrThing(s) and not os.getenv("OLD_EFFBY")
        if s.by ~= nil and s.guid ~= nil and not eff and not HURT_AT[s.guid .. "@" .. math.floor(s.t * 1000 + .5)] then
            gone[s.guid .. "@" .. math.floor(s.t * 1000 + .5)] = true
        end
    end
    for _, s in ipairs(strikes) do
        if s.guid ~= nil and gone[s.guid .. "@" .. math.floor(s.t * 1000 + .5)] then
            if s.by ~= nil then
                noharm = noharm + 1
                if s.t >= COUNT_FROM then real_print(string.format("NOHARM  %.3f %s %s: struck by %s, no harm done - not judged", s.t, PREFAB, s.state or "?", s.by)) end
            end
        else
            keep[#keep + 1] = s
        end
    end
    strikes = keep
end
-- (a dart of its that came to you as it flew - Tropical Experience's lizardman's spit, 8 off: modmain draws its
-- lane from where it was made, len ahead, width round (DARTS, face: turned to its target as it's made, as the boss
-- that made it, just ahead of it) - the log has where it was made, never where it flew, so not "drawn near": 3 of
-- the lizardman's at 8 off counted missed, 2026-10-22. Judged by that lane. OLD_DART_LANE=1: not)
if not os.getenv("OLD_DART_LANE") then
    local lanes = {}
    local mf = io.open(MOD .. "/modmain.lua", "rb")
    local src = mf and mf:read("*a") or ""
    if mf then mf:close() end
    for name, body in (src:match("local DARTS = (%b{})") or ""):gmatch("([%w_]+) = (%b{})") do
        local len, r = tonumber(body:match("len = ([%d%.]+)")), tonumber(body:match("width = ([%d%.]+)"))
        if body:match('by = "([%w_]+)"') == PREFAB and len ~= nil and r ~= nil then
            lanes[name] = { len = len, r = r, til = (tonumber(body:match("strikes_until = (%d+)")) or 30) * FRAMES }
        end
    end
    local wanted = false
    for _, s in ipairs(strikes) do if s.by ~= nil and lanes[s.by] ~= nil then wanted = true break end end
    if wanted then
        local born = {}
        for line in io.lines(LOG) do
            local bt, bp, bx, bz = line:match("%[tr_ent%] ([%d%.]+) born ([%w_]+) %d+ ([%d%.%-]+) ([%d%.%-]+)")
            if bt ~= nil and lanes[bp] ~= nil then born[#born + 1] = { t = tonumber(bt), prefab = bp, x = tonumber(bx), z = tonumber(bz) } end
        end
        for _, s in ipairs(strikes) do
            local L = s.by ~= nil and lanes[s.by] or nil
            if L ~= nil and s.x ~= nil then
                for _, b in ipairs(born) do
                    if b.prefab == s.by and b.t <= s.t + 1e-6 and s.t - b.t <= L.til then
                        -- (the boss as it was made - the way it went from it)
                        local ox, oz, ot = nil, nil, -1
                        for _, k in ipairs(ticks) do
                            if k.t <= b.t + 1e-6 and k.t > ot and (s.guid == nil or k.guid == s.guid) and k.x ~= nil then ox, oz, ot = k.x, k.z, k.t end
                        end
                        local dx, dz = ox ~= nil and b.x - ox or 0, oz ~= nil and b.z - oz or 0
                        local n = math.sqrt(dx * dx + dz * dz)
                        if n > 1e-3 then
                            local a = math.max(0, math.min(L.len, (s.x - b.x) * dx / n + (s.z - b.z) * dz / n))
                            local ex, ez = s.x - (b.x + dx / n * a), s.z - (b.z + dz / n * a)
                            if ex * ex + ez * ez <= L.r * L.r then s.dart_lane = true end
                        end
                    end
                end
            end
        end
        -- (and that blow's HIT line, that tick - the same blow, written twice)
        for _, s in ipairs(strikes) do
            if s.hit and not s.dart_lane then
                for _, o in ipairs(strikes) do
                    if o.dart_lane and o.guid == s.guid and math.abs(o.t - s.t) < 1e-3 then s.dart_lane = true break end
                end
            end
        end
    end
end
-- (a strike and its hit, the same blow: once - god mode blocks the hit, the strike's still there)
do
    table.sort(strikes, function(p, q) return p.t < q.t end)
    -- (a strike with no hit to it while hits do land round then - not god mode: out of its reach,
    -- dodged - the old traces noted a strike before the game looked at its reach - no strike)
    -- (told by how far off it ever really struck you in this log: a strike further off than any
    -- hit of its - Klaus 5 to 12 away, its hits within 4 - was out of reach; god mode on, hits not
    -- noted at all, the strike's all there is: kept)
    local reach = nil
    for _, o in ipairs(strikes) do
        if o.hit and o.x ~= nil and o.bx ~= nil then
            reach = math.max(reach or 0, math.sqrt((o.x - o.bx) ^ 2 + (o.z - o.bz) ^ 2))
        end
    end
    -- (a piece: as far as any blow of it landed in the whole log - not in its stretch alone)
    if PIECE then reach = LOG_REACH end
    local function Dodged(s)
        if s.hit or reach == nil or s.x == nil or s.bx == nil then return false end
        -- (nor a freeze, a fire with no blow ([tr_eff]): its reach not its bite's - the magma hound's breath sets you
        -- alight 4 off (PoofNearby), its bites land within 3.4: 19 "missed" fires the boss drew; 2026-10-28. OLD_EFFBY=1: as before)
        if EffOrThing(s) and not os.getenv("OLD_EFFBY") then return false end
        for _, o in ipairs(strikes) do
            if o.hit and math.abs(o.t - s.t) < .05 then return false end
        end
        return math.sqrt((s.x - s.bx) ^ 2 + (s.z - s.bz) ^ 2) > reach + .5
    end
    -- (a fire, a freeze ([tr_eff]) a tick after a blow is no part of it - the Mock Dragonfly's bite in its spin, its fire
    -- trail setting you alight the tick after: 16 "missed" fires the boss drew; 2026-10-28. OLD_EFFBY=1: one blow)
    local function Eff(s) return EffOrThing(s) and not os.getenv("OLD_EFFBY") end
    local keep = {}
    for _, s in ipairs(strikes) do
        local last = keep[#keep]
        if not Dodged(s) and not (last ~= nil and math.abs(last.t - s.t) < .05 and Eff(last) == Eff(s)) then keep[#keep + 1] = s
        -- (one blow told twice, once "by" a thing of its: the thing's word kept - the Mock Dragonfly's taunt ring setting you
        -- alight, put down to the lava spit by it, kept as its own plain strike: the spit's "missed"; 2026-10-28)
        elseif last ~= nil and s.by_own and Eff(s) and not Dodged(s) then last.by_own = true end
    end
    strikes = keep
end
table.sort(ticks, function(a, b) return a.t < b.t end)
if #ticks == 0 then real_print("no trace for " .. PREFAB) return end
-- (each tick a strike came, "you" where that strike says it found you - drawn for there and judged there:
-- the testbench sets its stand-in down again each tick, the tick's own "you" then a step - or a 60-degree
-- swing - off (the scheduler's order of its task and the trace's, by hash); judging only the strike's spot
-- against what was drawn for the tick's (STRIKE_POS_PARTS=1) took a swarm's strike as drawn in another's
-- shape - the Mini Eyes 145 -> 112, drawn for the spot 145. The real game: no change (660 -> 658).
-- VERIFY_PLAN 6.0a. OLD_STRIKE_POS=1: as before, the tick's "you")
-- (not under WALK: "you" is the walker there - set back to the stand-in on each strike's tick, it leapt there
-- and back, the map by distance with it: swathgrithr's twirl 182 -> 991 glitches walking, 192 without; the
-- miscfalse agent, 2026-10-19. TR_OLD_WALKPOS=1: as before)
if not os.getenv("OLD_STRIKE_POS") and not (WALK and not os.getenv("TR_OLD_WALKPOS")) then
    local at = {}
    for _, s in ipairs(strikes) do if s.x ~= nil then at[math.floor(s.t * 1000 + .5)] = s end end
    for _, k in ipairs(ticks) do
        local s = at[math.floor(k.t * 1000 + .5)]
        if s ~= nil then k.yx, k.yz = s.x, s.z end
    end
end
local tracks = {}
if os.getenv("OLD_TRACKS") then
    -- (as it was: every track gone through each tick - to check the one below gives the same, byte for byte)
    for _, k in ipairs(ticks) do
        local best, bd = nil, 4 * 4
        for _, tr in ipairs(tracks) do
            local l = tr.ticks[#tr.ticks]
            if k.guid ~= nil then
                if l.guid == k.guid then best = tr break end
            elseif l.t < k.t - 1e-6 and k.t - l.t < 3 then
                local d = (l.x - k.x) ^ 2 + (l.z - k.z) ^ 2
                if d < bd then best, bd = tr, d end
            end
        end
        if best == nil then best = { ticks = {} } table.insert(tracks, best) end
        table.insert(best.ticks, k)
    end
else
    -- (each tick to its track: by its GUID - the track whose last tick has it - or, with none, the
    -- nearest whose last tick is under 3 s before it. Looked up, not every track ever gone through
    -- each tick: the Eye of Terror's minis, born and gone by the hundred, took the replay 30 minutes)
    local by_guid, recent = {}, {}
    for _, k in ipairs(ticks) do
        local best, bd = nil, 4 * 4
        if k.guid ~= nil then
            best = by_guid[k.guid]
        else
            local keep = {}
            for _, tr in ipairs(recent) do
                local l = tr.ticks[#tr.ticks]
                if k.t - l.t >= 3 then tr.in_recent = nil end
                if k.t - l.t < 3 then
                    keep[#keep + 1] = tr
                    if l.t < k.t - 1e-6 then
                        local d = (l.x - k.x) ^ 2 + (l.z - k.z) ^ 2
                        if d < bd then best, bd = tr, d end
                    end
                end
            end
            recent = keep
        end
        if best == nil then
            best = { ticks = {}, idx = #tracks + 1, in_recent = true }
            table.insert(tracks, best)
            recent[#recent + 1] = best
        elseif k.guid ~= nil then
            -- (one gone a while, back by its GUID: among the recent again, where it was made - the
            -- order every track was gone through in, the first of two as near kept)
            -- (known to be among them by its own mark - looked through every time, a list only
            -- trimmed by ticks with no GUID grew to all of them: slower than before)
            if not best.in_recent then
                best.in_recent = true
                local at = #recent + 1
                for i, tr in ipairs(recent) do if tr.idx > best.idx then at = i break end end
                table.insert(recent, at, best)
            end
        end
        local prev = best.ticks[#best.ticks]
        if prev ~= nil and prev.guid ~= nil and by_guid[prev.guid] == best then by_guid[prev.guid] = nil end
        table.insert(best.ticks, k)
        if k.guid ~= nil then by_guid[k.guid] = best end
    end
end
-- (TPOS_ORACLE=1: a log from before " tpos=" was traced - the Ancient Guardian's leap: the spot
-- it goes for is where you were 1 s into it (its DoTaskInTime(1)), as the trace has you)
if os.getenv("TPOS_ORACLE") and PREFAB == "bishop" then
    -- (the Clockwork Bishop's aim: your spot as it begins, then crept after you - k .5, less .02
    -- each frame, till .02 (SGbishop LerpTargetingXZDir) - and shot there)
    for _, tr in ipairs(tracks) do
        local tx, tz, k, prev = nil, nil, nil, nil
        for _, tk in ipairs(tr.ticks) do
            if tk.state == "attack" and tk.yx ~= nil then
                if prev ~= "attack" then tx, tz, k = tk.yx, tk.yz, .5
                elseif k ~= nil then
                    tx, tz = tx + (tk.yx - tx) * k, tz + (tk.yz - tz) * k
                    if k > .02 then k = k - .02 else k = nil end
                end
                tk.tpx, tk.tpz = tx, tz
            elseif tk.state == "attack_shoot" and tx ~= nil then
                tk.tpx, tk.tpz = tx, tz
            end
            prev = tk.state
        end
    end
elseif os.getenv("TPOS_ORACLE") then
    for _, tr in ipairs(tracks) do
        local ks = tr.ticks
        local i = 1
        while i <= #ks do
            if ks[i].state == "leap_attack_pre" and (i == 1 or ks[i - 1].state ~= "leap_attack_pre") then
                local t0 = ks[i].t
                local yx, yz = nil, nil
                for q = i, #ks do
                    if ks[q].t >= t0 + 1 - 1e-6 then yx, yz = ks[q].yx, ks[q].yz break end
                end
                local q = i
                while q <= #ks and (ks[q].state == "leap_attack_pre" or ks[q].state == "leap_attack") do
                    if yx ~= nil and ks[q].t >= t0 + 1 - 1e-6 and ks[q].tpx == nil then ks[q].tpx, ks[q].tpz = yx, yz end
                    q = q + 1
                end
                i = q
            else
                i = i + 1
            end
        end
    end
end
-- (RAM_ORACLE=1: a log from before " ram=" was traced - its charge's time left taken from where it
-- really stopped, for the runs its brain gave up (on into "attack", not into you or a pillar): how
-- the time the server tells is used, tried on an old log)
if os.getenv("RAM_ORACLE") then
    local RUNS = { taunt = true, run_start = true, run = true }
    for _, tr in ipairs(tracks) do
        local ks = tr.ticks
        local i = 1
        while i <= #ks do
            if RUNS[ks[i].state] then
                local j = i
                while j < #ks and RUNS[ks[j + 1].state] do j = j + 1 end
                local after = ks[j + 1]
                local saw_run = false
                for q = i, j do if ks[q].state == "run" then saw_run = true end end
                if after ~= nil and after.state == "attack" and saw_run then
                    for q = i, j do
                        if ks[q].ram_t == nil then ks[q].ram_t = math.max(0, after.t - ks[q].t - .06) end
                    end
                end
                i = j + 1
            else
                i = i + 1
            end
        end
    end
end

-- the world at time t, for one boss: its tick before, moved on to t (the trace is sparse)
-- (ck: whose cursor - its own for a look further back (CLIENT's ENT_LAG); the cursor only ever goes on)
local function At(tr, t, ck)
    ck = ck or "ti"
    local ticks = tr.ticks
    local ti = tr[ck] or 1
    while ti < #ticks and ticks[ti + 1].t <= t + 1e-6 do ti = ti + 1 end
    tr[ck] = ti
    local a, b = ticks[ti], ticks[ti + 1]
    if a.t > t + .5 or (b == nil and t > a.t + .5) or (b ~= nil and b.t - a.t > 3 and t > a.t + .5) then return nil end
    local k = 0
    if b ~= nil and b.t > a.t and b.state == a.state then k = math.max(0, math.min(1, (t - a.t) / (b.t - a.t))) end
    local function L(p, q) return type(q) == "number" and p + (q - p) * k or p end
    return { state = a.state, ts = a.ts + (t - a.t), anim_t = a.anim_t + (t - a.t),
        x = L(a.x, b and b.state == a.state and b.x), z = L(a.z, b and b.state == a.state and b.z),
        rot = a.rot, yx = L(a.yx, b and b.yx), yz = L(a.yz, b and b.yz), yvx = a.yvx, yvz = a.yvz,
        anim = a.anim, scale = a.scale, guid = a.guid, notarget = a.notarget, forms = a.forms, tx = a.tx, tz = a.tz,
        ram_t = a.ram_t and math.max(0, a.ram_t - (t - a.t)), ram_d = a.ram_d, tpx = a.tpx, tpz = a.tpz, build = a.build }
end

-- (the animation after anim in one of its moves' lists - see IsCurrentAnimation below)
function NextAnim(anim)
    for _, m in ipairs(require("true_range/simmoves").Moves(PREFAB) or {}) do
        for i, x in ipairs(m.anims or {}) do
            if x == anim and m.anims[i + 1] ~= nil then return m.anims[i + 1] end
        end
    end
end
local me = { prefab = "wilson", Transform = {}, Physics = {} }
local you = { 0, 0 }
local my_vel = { 0, 0 }
function me:IsValid() return true end
function me:HasTag() return false end
function me.Transform:GetWorldPosition() return you[1], 0, you[2] end
function me.Physics:GetVelocity() return my_vel[1], 0, my_vel[2] end
AllPlayers = { me }
local ANIM_LENS = nil
for i, tr in ipairs(tracks) do
    local boss = { prefab = PREFAB, AnimState = {}, Transform = {}, GUID = i }
    tr.boss = boss
    function boss:IsValid() return tr.cur ~= nil end
    function boss:HasTag() return false end
    function boss.AnimState:IsCurrentAnimation(a)
        if tr.cur == nil then return false end
        local anim = tr.cur.anim or state_anim[tr.cur.state]
        -- (an older trace - no anim= in it: its animation begun over while still in the same state
        -- is a later one of it (atk1, then atk1_pst) - the one after it in a move's list)
        if tr.cur.anim == nil and anim and not state_loops[tr.cur.state] and tr.cur.ts ~= nil and tr.cur.anim_t ~= nil and tr.cur.ts - tr.cur.anim_t > 2 * FRAMES then
            anim = NextAnim(anim) or (anim .. "#later")
        end
        return anim ~= nil and anim ~= false and anim == a
    end
    -- (REDRAW: between ticks the client plays its animation on, frame by frame - a part of a frame
    -- behind where the tick has it, as its position is)
    function boss.AnimState:GetCurrentAnimationTime()
        if tr.redraw_k ~= nil and tr.cur.anim_t ~= nil then return math.max(0, tr.cur.anim_t + (tr.redraw_k - 1) * FRAMES) end
        return tr.cur.anim_t
    end
    function boss.AnimState:GetBuild() return tr.cur ~= nil and tr.cur.build or PREFAB end
    -- (how long its animation is, as the game would say - tools/anim_lengths(_um).lua,
    -- by the boss's own anim file; none known: nil)
    if not os.getenv("NO_ANIMLEN") then
        if ANIM_LENS == nil then
            ANIM_LENS = {}
            for _, f in ipairs({ "tools/anim_lengths_um.lua", "tools/anim_lengths.lua" }) do
                local ok, t = pcall(dofile, f)
                if ok and type(t) == "table" and t[PREFAB] ~= nil then for a, s in pairs(t[PREFAB]) do if ANIM_LENS[a] == nil then ANIM_LENS[a] = s end end end
            end
        end
        function boss.AnimState:GetCurrentAnimationLength()
            local a = tr.cur ~= nil and (tr.cur.anim or state_anim[tr.cur.state]) or nil
            local s = a ~= nil and ANIM_LENS[a] or nil
            return type(s) == "number" and s or nil
        end
    end
    -- (POS_LAG=n: where it was n frames back, a client's late picture of it)
    local pos_lag = (tonumber(os.getenv("POS_LAG") or "") or 0) * FRAMES
    function boss.Transform:GetWorldPosition()
        if pos_lag > 0 then
            local tk, want = tr.ticks, now - pos_lag
            local lo, hi = 1, #tk
            while lo < hi do local mid = math.floor((lo + hi + 1) / 2) if tk[mid].t <= want + 1e-6 then lo = mid else hi = mid - 1 end end
            return tk[lo].x, 0, tk[lo].z
        end
        -- (REDRAW: drawn between two ticks - the game slides it from where it was to where it is,
        -- frame by frame, its clock already on: tr.redraw_k of the way)
        if tr.redraw_k ~= nil and tr.prev_pos ~= nil then
            local k = tr.redraw_k
            return tr.prev_pos[1] + (tr.cur.x - tr.prev_pos[1]) * k, 0, tr.prev_pos[2] + (tr.cur.z - tr.prev_pos[2]) * k
        end
        return tr.cur.x, 0, tr.cur.z
    end
    function boss.Transform:GetRotation() return tr.cur.rot end
    function boss.Transform:GetScale() local s = tr.cur ~= nil and tr.cur.scale or 1 return s, s, s end
    -- (none once the trace says so: " notarget")
    -- (or someone else, once the trace says whom: " tgt=" - a friend there, where the server had them)
    local friend = { prefab = "friend", Transform = {}, Physics = {} }
    function friend:IsValid() return tr.cur ~= nil and tr.cur.tx ~= nil end
    function friend:HasTag() return false end
    function friend.Transform:GetWorldPosition() return tr.cur.tx, 0, tr.cur.tz end
    function friend.Physics:GetVelocity() return 0, 0, 0 end
    tr.Aim = function() if tr.cur ~= nil and tr.cur.tx ~= nil then return friend end return me end
    -- (FLIP_TARGET=n: whom it's after said to be you and the friend by turns, n frames each - two
    -- players hitting it, its target changing as each does - while its moves go at whom they began
    -- at, as the server tells with its poses: the shape mustn't follow its target to and fro)
    local flip = tonumber(os.getenv("FLIP_TARGET") or "")
    boss.replica = { combat = { GetTarget = function(_)
        if tr.cur ~= nil and tr.cur.notarget then return nil end
        if flip ~= nil and tr.cur ~= nil and tr.cur.tx ~= nil then
            return math.floor(now / FRAMES / flip + 1e-6) % 2 == 0 and friend or me
        end
        return tr.Aim()
    end } }
    -- (FAKE_PLAYER=dx,dz: another player that far from the boss, all along - AllPlayers, for one
    -- that goes for every player in reach (sim.multi))
    local fdx, fdz = (os.getenv("FAKE_PLAYER") or ""):match("([%d%.%-]+),([%d%.%-]+)")
    if fdx ~= nil and tr.ticks ~= nil then
        local fake = { Transform = {} }
        function fake:IsValid() return true end
        function fake.Transform:GetWorldPosition() return tr.cur.x + tonumber(fdx), 0, tr.cur.z + tonumber(fdz) end
        rawset(_G, "AllPlayers", { fake })
    end
end

-- things it set off, as the game makes them (true_range modmain: Predict.made_hazards, when each
-- was made) - from the trace ([tr_haz], those near you): there from their first line to their last
local replay_made = {}
do
    local made = {}
    for t, prefab, guid, x, z in HazLines() do
        if t ~= nil then
            t = tonumber(t)
            local h = made[guid]
            if h == nil then
                h = { prefab = prefab, first = t, last = t, pos = {} }
                made[guid] = h
            end
            h.last = math.max(h.last, t)
            h.pos[#h.pos + 1] = { t, tonumber(x), tonumber(z) }
        end
    end
    local list = replay_made
    for _, h in pairs(made) do
        local e = { prefab = h.prefab, Transform = {} }
        function e:IsValid() return now >= h.first - 1e-6 and now <= h.last + .05 end
        -- (where it is now: a cursor on, the clock only going on - not from its first line every call,
        -- a fifth of a replay's time; VERIFY_PLAN 6.15)
        local pi = 1
        function e.Transform:GetWorldPosition()
            local pos = h.pos
            if pi > 1 and pos[pi][1] > now + 1e-6 then pi = 1 end
            while pi < #pos and pos[pi + 1][1] <= now + 1e-6 do pi = pi + 1 end
            local p = pos[pi]
            return p[2], 0, p[3]
        end
        list[#list + 1] = { e = e, first = h.first, last = h.last }
    end
    -- (by when each was made, for the frame loop's cursor below)
    table.sort(list, function(a, b) return a.first < b.first end)
    Predict.made_hazards = {}
    -- (a trace with no word of what's made - an offline run's: the mod not told, either way)
    if next(made) == nil then TR_UNTOLD = true end
end

-- what the drawing reports at each part's strike (true_range modmain's test hook)
local said = {}
SimMoves.on_strike = function(ent, here, edge)
    table.insert(said, { t = now, here = here, edge = edge })
end

local drawn_at = {}   -- frame time -> whether you were in what was drawn
local made_i = 1      -- (the frame loop's cursor through replay_made)
local made_live = {}  -- (those made and not yet gone for good)
-- (how far off, and how often, the mod looks for bosses to draw - read from its modmain)
local PICK_FAR, PICK_EVERY = 24, .2
do
    local fh = io.open(MOD .. "/modmain.lua", "rb")
    if fh ~= nil then
        local text = fh:read("*a")
        fh:close()
        PICK_FAR = tonumber(text:match("\nlocal SIM_FAR = ([%d.]+)") or text:match("\nlocal NEAR = ([%d.]+)") or "") or PICK_FAR
        PICK_EVERY = tonumber(text:match("\nlocal PICK_EVERY = ([%d.]+)") or "") or PICK_EVERY
    end
end
local t0, t1 = ticks[1].t, ticks[#ticks].t
-- (a piece: on the whole log's frames - stepped from its first tick, as a whole run steps, not from the
-- piece's own first: a hair off, its verdicts moved - replay_haz the same, VERIFY_PLAN 6.15)
if PIECE and LOG_FIRST_T ~= nil and LOG_FIRST_T < t0 then
    t0 = LOG_FIRST_T + math.ceil((t0 - LOG_FIRST_T) / FRAMES - 1e-6) * FRAMES
end
-- (the things a move's state makes as it begins (sim.tell - the Eye's shot's chargepulse), as the game makes
-- them: [tr_ent] born lines - modmain's AddPrefabPostInit fills Predict.tell_things in the game; a log with
-- none of them (a player's) left untold, the drawing as without them)
local tells, tell_i = {}, 1
do
    local want = {}
    for _, mv in pairs(require("true_range/moves_sim")[PREFAB] or {}) do
        if type(mv) == "table" and mv.tell ~= nil then want[mv.tell] = true end
    end
    if next(want) ~= nil and Predict.tell_things ~= nil then
        for line in io.lines(LOG) do
            local bt, bp, bx, bz = line:match("%[tr_ent%] ([%d%.]+) born ([%w_]+) %d+ ([%d%.%-]+) ([%d%.%-]+)")
            if bt ~= nil and want[bp] then tells[#tells + 1] = { t = tonumber(bt), prefab = bp, x = tonumber(bx), z = tonumber(bz) } end
        end
        table.sort(tells, function(p, q) return p.t < q.t end)
    end
end
local prev = nil
local f = 0
local pose_queue = {}  -- (the server's poses on their way - POSE_LAG)
local draw_cost = { 0, 0, 0 }  -- (DRAW_TIME: seconds, KB made, frames)
while true do
    local t = t0 + f * FRAMES
    if t > t1 then break end
    -- (T_EPS: the clock a hair on - the game's frame times land a hair either side of a move's
    -- frames, the replay's just under: Klaus' bite at the frame it stops aiming was taken as still
    -- aiming here, as stopped in the game)
    now = t + (tonumber(os.getenv("T_EPS") or "") or 0)
    while tells[tell_i] ~= nil and tells[tell_i].t <= now + 1e-6 do
        local p = tells[tell_i]
        local e = { prefab = p.prefab, Transform = {} }
        function e:IsValid() return now - p.t < 1 end
        function e.Transform:GetWorldPosition() return p.x, 0, p.z end
        Predict.tell_things[e] = p.t
        tell_i = tell_i + 1
    end
    local list, state, py = {}, nil, nil
    for _, tr in ipairs(tracks) do
        tr.cur = At(tr, t)
        -- (CLIENT: it as a player's game has it, ENT_LAG back; you as the server has you now - moved by YOU_LEAD below)
        if ENT_LAG > 0 and tr.cur ~= nil then
            local back = At(tr, t - ENT_LAG, "ti_back")
            if back ~= nil then
                local c = {}
                for k, v in pairs(back) do c[k] = v end
                c.yx, c.yz, c.yvx, c.yvz = tr.cur.yx, tr.cur.yz, tr.cur.yvx, tr.cur.yvz
                tr.cur = c
            end
        end
        -- (picked as the mod picks: within SIM_FAR of you, looked at every PICK_EVERY - a boss at
        -- the edge drops out, its shape gone)
        if tr.cur ~= nil and tr.cur.yx ~= nil then
            -- (a piece: looked at on the round it had from when it first came - not from the piece's start)
            if PIECE and tr.pick_at == nil and tr.cur.guid ~= nil and GUID_FIRST[tr.cur.guid] ~= nil and GUID_FIRST[tr.cur.guid] < t - 1e-6 then
                local g0 = GUID_FIRST[tr.cur.guid]
                local frames_since = math.floor((t - g0) / FRAMES + .5)
                local per = math.max(1, math.floor(PICK_EVERY / FRAMES + .5))
                tr.pick_at = t - (frames_since % per) * FRAMES
                tr.picked = (tr.cur.x - tr.cur.yx) ^ 2 + (tr.cur.z - tr.cur.yz) ^ 2 <= PICK_FAR * PICK_FAR
            end
            if tr.pick_at == nil or t >= tr.pick_at + PICK_EVERY - 1e-6 then
                tr.pick_at = t
                tr.picked = (tr.cur.x - tr.cur.yx) ^ 2 + (tr.cur.z - tr.cur.yz) ^ 2 <= PICK_FAR * PICK_FAR
            end
            if not tr.picked then
                -- (you're still there, nothing drawn for it: a frame like any other)
                py = py or { tr.cur.yx, tr.cur.yz, tr.cur.yvx, tr.cur.yvz }
                state = state or (tr.cur.state .. " (not picked)")
                tr.cur = nil
            end
        end
        -- (the server's word on its pose, as true_range modmain sends it: the trace is the server's
        -- own - by the same code, true_range/simmoves PoseTrack; POSE_LAG=n: it gets here n frames
        -- on; NO_POSES: none, as a game without it)
        if tr.cur ~= nil and not os.getenv("NO_POSES") then
            tr.pose_st = tr.pose_st or {}
            local SMp = require("true_range/simmoves")
            local cur = tr.cur
            local key, go, ft = SMp.PoseTrack(tr.pose_st, PREFAB, function(a) return tr.boss.AnimState:IsCurrentAnimation(a) end, cur.anim_t or 0, t)
            if key ~= nil then
                pose_queue[#pose_queue + 1] = { at = t + POSE_LAG_F * FRAMES, boss = tr.boss,
                    key = key, go = go, ft = ft, x = cur.x, z = cur.z, rot = cur.rot, after = os.getenv("POSE_AFTER") or cur.forms or "", aim = (cur.tx ~= nil or not os.getenv("OLD_POSE_AIM")) and tr.Aim() or nil, ram_t = cur.ram_t, ram_d = cur.ram_d, tpx = cur.tpx, tpz = cur.tpz, apx = cur.yx, apz = cur.yz }
            end
        end
        if tr.cur ~= nil then
            table.insert(list, tr.boss)
            state = (state and (state .. "/") or "") .. tr.cur.state .. (scene_of[tr.cur.guid or ""] and (" [" .. scene_of[tr.cur.guid] .. "]") or "")
            py = py or { tr.cur.yx, tr.cur.yz, tr.cur.yvx, tr.cur.yvz }
        end
    end
    do
        local SMp = require("true_range/simmoves")
        local keep = {}
        for _, q in ipairs(pose_queue) do
            if q.at <= t + 1e-6 then SMp.Pose(q.boss, q.key, q.go, q.ft, q.x, q.z, q.rot, q.after, q.aim, q.ram_t or -1, q.ram_d or -1, q.tpx or -1e9, q.tpz or -1e9, q.apx or -1e9, q.apz or -1e9) else keep[#keep + 1] = q end
        end
        pose_queue = keep
    end
    -- ("you" from the newest tick of all - not the first track's, which may be one no longer traced, its
    -- last tick held on: a Mini Eye gone quiet had you where you were before the testbench moved you 30 on,
    -- its kin's bites at you drawn for there - 145 struck undrawn; VERIFY_PLAN 6.0a. OLD_PY=1: as before)
    if not os.getenv("OLD_PY") then
        local best, best_t = nil, nil
        for _, tr in ipairs(tracks) do
            local c = At(tr, t)
            local kt = c ~= nil and tr.ticks[tr.ti] ~= nil and tr.ticks[tr.ti].t or nil
            -- (a tick come already - not one a track is shown ahead of (At: up to .5 s before its first, one traced late):
            -- a tentacle in the testbench's next scene, first traced .5 s on, gave you there while one here struck
            -- you - 31 of its 43 "not drawn", 2026-10-20. OLD_PY_AHEAD=1: as before)
            if c ~= nil and c.yx ~= nil and kt ~= nil and (best_t == nil or kt > best_t) and (kt <= t + 1e-6 or os.getenv("OLD_PY_AHEAD")) then best, best_t = c, kt end
        end
        -- (as At has it between that track's ticks - its own tick's alone came a tick late, the stand-in set
        -- down anew each tick: the Celestial Champion 0 -> 15 so)
        if best ~= nil then py = { best.yx, best.yz, best.yvx, best.yvz } end
    end
    -- (PY_DBG=t0,t1: you and each one drawn for, frame by frame)
    local pd0, pd1 = (os.getenv("PY_DBG") or ""):match("([%d%.]+),([%d%.]+)")
    if pd0 ~= nil and t >= tonumber(pd0) and t <= tonumber(pd1) then
        local s = {}
        for _, tr in ipairs(tracks) do if tr.cur ~= nil then s[#s + 1] = string.format("%s@%.1f,%.1f %s %s/%.3f", tostring(tr.cur.guid), tr.cur.x, tr.cur.z, tostring(Predict.MoveOf(tr.boss)), tostring(tr.cur.anim), tr.cur.anim_t or -1) end end
        real_print(string.format("PYDBG %.3f you %s list %d: %s", t, py and string.format("%.2f,%.2f", py[1], py[2]) or "-", #list, table.concat(s, " ")))
    end
    -- (YOU_LEAD=n: you as a player's own game shows you - n frames on from the server's, by how fast you go: what
    -- the server tells of where it aims at you against what's seen, true_range/predict TR_OLD_SERVERAIM)
    if py ~= nil and py[3] ~= nil and YOU_LEAD_F then
        local n = YOU_LEAD_F * FRAMES
        py = { py[1] + py[3] * n, py[2] + py[4] * n, py[3], py[4] }
    end
    if py ~= nil then
        if py[3] ~= nil then my_vel[1], my_vel[2] = py[3], py[4]
        elseif prev ~= nil then my_vel[1], my_vel[2] = (py[1] - prev[1]) / FRAMES, (py[2] - prev[2]) / FRAMES end
        prev = py
        you[1], you[2] = py[1], py[2]
        pieces = 0
        area, cx_sum, cz_sum = 0, 0, 0
        dark_area = 0
        for i = #tri_pts, 1, -1 do tri_pts[i] = nil end
        tri_pts.own = {}
        -- (-ask: the server's word on a boss as the game gets it - asked once it's within 24 of
        -- you, back a moment later; until then none)
        local function Word(b)
            -- (its reach to begin a blow (r.attack - what true_range/predict's goes_into asks: Klaus' bite on into its quick
            -- swipe at whoever's within it): not traced - 3 times its size (KLAUS_ATTACK_RANGE ; a guess for the rest). Without, never
            -- drawn here, 56 "missed" as a player's game, 2026-10-27, its lag bench 0. OLD_RATTACK=1: none)
            local ra = not os.getenv("OLD_RATTACK") and 3 * ((tracks[b.GUID] and tracks[b.GUID].cur and tracks[b.GUID].cur.scale) or 1) or nil
            if not ASK then return { harmful = true, hit = 3, attack = ra } end
            local tr = tracks[b.GUID]
            local c = tr.cur
            local d2 = (c.x - py[1]) ^ 2 + (c.z - py[2]) ^ 2
            if d2 <= 24 * 24 and tr.asked == nil then tr.asked = t end
            if tr.asked ~= nil and t >= tr.asked + .3 then return { harmful = true, hit = 3, attack = ra } end
            return nil
        end
        -- (each thing made by now: there, as in the game)
        -- (a cursor through them by when made - not all of them every frame: a third of a replay's time)
        while made_i <= #replay_made and replay_made[made_i].first <= t + 1e-6 do
            local m = replay_made[made_i]
            if Predict.made_hazards[m.e] == nil then Predict.made_hazards[m.e] = m.first end
            made_live[#made_live + 1] = m
            made_i = made_i + 1
        end
        -- (and one gone for good let go, as the game's weak table lets a removed thing go - kept, every
        -- thing ever made was asked IsValid every frame: 15% of a replay; invalid then all the same)
        if not os.getenv("OLD_MADE") then
            for k = #made_live, 1, -1 do
                local m = made_live[k]
                if t > m.last + 1 then
                    Predict.made_hazards[m.e] = nil
                    made_live[k] = made_live[#made_live]
                    made_live[#made_live] = nil
                end
            end
        end
        local SM = require("true_range/simmoves")
        SM._record = {}
        local pat = tonumber(os.getenv("PIC_AT") or "")
        if #pic_seq > 0 then pat = pic_seq[pic_seq.i] if pat ~= nil then pic_done = false end end
        if pat ~= nil and t >= pat - .04 and not pic_done then pic = { tris = {}, segs = {} } end
        -- (REDRAW=n: drawn n+1 times at each moment, as the game draws between its ticks - the clock
        -- on already, the boss slid from where it was to where it is; REDRAW lines where the shape's
        -- middle went back and forth, or jumped, within one moment)
        local redraws = tonumber(os.getenv("REDRAW") or "") or 0
        for _, tr in ipairs(tracks) do tr.redraw_k = redraws > 0 and 0 or nil end
        -- (DRAW_TIME: how long the drawing itself takes, and what it makes, frame by frame - all told at the end)
        -- (FN_PROF=t0,t1: the mod's lines run in that stretch, by function (with what each calls) - said at the end)
        local fp0, fp1 = (os.getenv("FN_PROF") or ""):match("([%d%.]+),([%d%.]+)")
        local fprof = fp0 ~= nil and t >= tonumber(fp0) and t <= tonumber(fp1)
        if fprof then
            fn_lines = fn_lines or {}
            debug.sethook(function()
                local seen = {}
                for lv = 2, 40 do
                    local inf = debug.getinfo(lv, "Sn")
                    if inf == nil then break end
                    if inf.short_src:find("true_range", 1, true) then
                        local k = inf.short_src:match("[^/\\]+$") .. ":" .. inf.linedefined .. " " .. tostring(inf.name)
                        if not seen[k] then seen[k] = true fn_lines[k] = (fn_lines[k] or 0) + 1 end
                    end
                end
            end, "", 100)
            -- (LINE_IN=file:from-to: also its lines one by one, in that stretch of that file)
            local li = os.getenv("LINE_IN")
            if li ~= nil then
                local lf, la, lb = li:match("([^:]+):(%d+)-(%d+)")
                la, lb = tonumber(la), tonumber(lb)
                debug.sethook(function(_, line)
                    local inf = debug.getinfo(2, "S")
                    if line >= la and line <= lb and inf.short_src:find(lf, 1, true) then
                        fn_lines["line " .. line] = (fn_lines["line " .. line] or 0) + 1
                    end
                end, "l")
            end
        end
        local haz_in = false
        local dt_c0, dt_m0 = os.clock(), collectgarbage("count")
        local RL_ = REAL and require("true_range/lines") or nil
        if RL_ then RL_.Begin() if os.getenv("NO_TURNS") then RL_.turns = false end if os.getenv("NO_GROUPS") then RL_.GroupFor = nil end end
        local inside = Predict.Draw(list, Word, .5,
            { x = py[1], z = py[2], ent = me }, function() return false end)
        if WHOLE then
            rawset(_G, "TR_HAZ_NOW", true)
            local hl = HazardsNow(t)
            -- (what stands where, as the game's own search would find it - of what's traced)
            Predict.EntsNear = function(x, z, r)
                local out = {}
                for _, e in ipairs(hl) do if (e.cur.x - x) ^ 2 + (e.cur.z - z) ^ 2 <= r * r then out[#out + 1] = e end end
                return out
            end
            -- (you inside a thing's own shape this frame - its mini eyes, its lasers: what "things struck
            -- you ... drawn" asks; only the boss's shapes asked till now, 7 of 7 "not drawn" though drawn)
            haz_in = Predict.DrawHazards(hl, .5, { x = py[1], z = py[2] }) and true or false
            rawset(_G, "TR_HAZ_NOW", nil)
        end
        if RL_ then RL_.End() pieces, area, cx_sum, cz_sum = 0, 0, 0, 0 RealMiddle() if real_dbg ~= nil and math.abs(t - real_dbg) < .07 then RealDump(t) end if os.getenv("REAL_HASH") then RealHash(t) end end
        if fprof then debug.sethook() end
        draw_cost[1], draw_cost[2], draw_cost[3] = draw_cost[1] + (os.clock() - dt_c0), draw_cost[2] + math.max(0, collectgarbage("count") - dt_m0), draw_cost[3] + 1
        -- (DRAW_TIME: the slowest frames too - a hitch is one slow frame, the average hides it)
        if os.getenv("DRAW_TIME") then slow_draws = slow_draws or {} slow_draws[#slow_draws + 1] = { os.clock() - dt_c0, t, pieces } end
        local mids = { area > 0 and { cx_sum / area, cz_sum / area } or nil }
        local areas = { area }
        for i = 1, redraws do
            for _, tr in ipairs(tracks) do tr.redraw_k = i / redraws end
            pieces, area, cx_sum, cz_sum = 0, 0, 0, 0
            tri_pts.own = {}
            SM._record = {}
            inside = Predict.Draw(list, Word, .5, { x = py[1], z = py[2], ent = me }, function() return false end)
            mids[#mids + 1] = area > 0 and { cx_sum / area, cz_sum / area } or false
            areas[#areas + 1] = area
        end
        if redraws > 0 then
            local far, step = 0, 0
            for i = 2, #mids do
                local a, b = mids[1], mids[i]
                if a and b then far = math.max(far, math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2)) end
                local c = mids[i - 1]
                if c and b then step = math.max(step, math.sqrt((c[1] - b[1]) ^ 2 + (c[2] - b[2]) ^ 2)) end
            end
            local last = mids[#mids]
            local net = (mids[1] and last) and math.sqrt((mids[1][1] - last[1]) ^ 2 + (mids[1][2] - last[2]) ^ 2) or 0
            -- (or its size: bigger or smaller and back within the moment)
            local lo, hi = math.huge, 0
            for _, a in ipairs(areas) do lo, hi = math.min(lo, a), math.max(hi, a) end
            local a0, a1 = areas[1], areas[#areas]
            if hi > 0 and (hi - lo) - math.abs(a1 - a0) > .1 * hi then
                real_print(string.format("REDRAW  %.3f %s %s: within one moment its size went %.1f..%.1f (from %.1f to %.1f)", t, PREFAB, state or "-", lo, hi, a0, a1))
            end
            if far - net > .3 or step > 1 then
                real_print(string.format("REDRAW  %.3f %s %s: within one moment its middle went out %.2f and ended %.2f off (biggest step %.2f)", t, PREFAB, state or "-", far, net, step))
            end
        end
        -- (the pictures: the rings modmain draws round some (AGGRO_WHILE) - not Predict's, unseen here otherwise: when one
        -- last played what draws its ring, when it last jumped - PicAggro)
        if pic_seq[1] ~= nil or os.getenv("PIC_AT") then
            local w = PicAggro()[PREFAB]
            if w ~= nil then
                for _, tr in ipairs(tracks) do
                    if tr.cur ~= nil and tr.boss ~= nil then
                        for an in pairs(w.anims) do if tr.boss.AnimState:IsCurrentAnimation(an) then tr.aggro_on_t = t end end
                        if w.jump ~= nil and tr.prev_pos ~= nil and (tr.cur.x - tr.prev_pos[1]) ^ 2 + (tr.cur.z - tr.prev_pos[2]) ^ 2 > w.jump.d ^ 2 then
                            tr.aggro_jump_t = t
                        end
                    end
                end
            end
        end
        for _, tr in ipairs(tracks) do
            tr.redraw_k = nil
            if tr.cur ~= nil then tr.prev_pos = { tr.cur.x, tr.cur.z } end
        end
        if pic ~= nil and os.getenv("PIC_REAL") then
            -- (PIC_REAL: as the game shows it - every piece in its style's colour and opacity, over
            -- the ground, by sort order then the order laid; lines as the game's stretched squares
            -- (their width, and a line's width more in length unless exact); PIC_SCALE pixels a unit
            -- (80), PIC_R units round the boss (6))
            pic_done = true
            local RL = dofile(arg[1] .. "/scripts/true_range/lines.lua")
            local ST = RL._styles
            local bx, bz = py[1], py[2]
            if list[1] ~= nil then bx, _, bz = list[1].Transform:GetWorldPosition() end
            local S = tonumber(os.getenv("PIC_SCALE") or "") or 80
            local R = tonumber(os.getenv("PIC_R") or "") or 6
            local cxs, czs = os.getenv("PIC_C") and os.getenv("PIC_C"):match("([%d%.%-]+),([%d%.%-]+)")
            local x0, z0 = (tonumber(cxs) or bx) - R, (tonumber(czs) or bz) - R
            local W = math.floor(2 * R * S)
            local img = {}
            for i = 1, W * W do img[i] = { 120, 95, 55 } end
            local items = {}
            for _, tr in ipairs(pic.tris) do items[#items + 1] = { kind = "tri", p = { tr[1], tr[2], tr[3], tr[4], tr[5], tr[6] }, style = tr[7], n = tr.n } end
            for _, sg in ipairs(pic.segs) do
                local st = ST[sg[5]] or ST.edge
                local w = sg[6] or st.width
                local dx, dz = sg[3] - sg[1], sg[4] - sg[2]
                local len = math.sqrt(dx * dx + dz * dz)
                if len > .01 then
                    local ext = sg[7] and 0 or math.min(w, st.width)
                    local ux, uz = dx / len, dz / len
                    local hx, hz = -uz * w / 2, ux * w / 2
                    local ax, az = sg[1] - ux * ext / 2, sg[2] - uz * ext / 2
                    local ex, ez = sg[3] + ux * ext / 2, sg[4] + uz * ext / 2
                    items[#items + 1] = { kind = "quad", p = { ax + hx, az + hz, ex + hx, ez + hz, ex - hx, ez - hz, ax - hx, az - hz }, style = sg[5], n = sg.n }
                end
            end
            -- (and modmain's rings round it - AGGRO_WHILE, as it draws them: yellow while it winds up (core warn), red as it
            -- strikes (core hit, hit_after), pale for the rest; round where it jumped to (jump); its idle ring (idle_r) not)
            do
                local w = PicAggro()[PREFAB]
                for _, tr in ipairs(w ~= nil and tracks or {}) do
                    if tr.cur ~= nil and tr.boss ~= nil then
                        local A = tr.boss.AnimState
                        local function Circle(r, style)
                            local p = {}
                            for k = 0, 31 do local a = k / 32 * 2 * math.pi p[#p + 1] = tr.cur.x + r * math.cos(a) p[#p + 1] = tr.cur.z + r * math.sin(a) end
                            items[#items + 1] = { kind = "poly", p = p, style = style, n = 0 }
                        end
                        if w.jump ~= nil and tr.aggro_jump_t ~= nil and t - tr.aggro_jump_t <= w.jump.warn + w.jump.hit then
                            Circle(w.r, t - tr.aggro_jump_t >= w.jump.warn and "hit" or "strike")
                        end
                        if tr.aggro_on_t ~= nil and t - tr.aggro_on_t <= w.linger + .001 then
                            local style = nil
                            for an in pairs(w.core_hit) do if A:IsCurrentAnimation(an) then style = "hit" end end
                            for an, f in pairs(w.hit_after) do if A:IsCurrentAnimation(an) and (A:GetCurrentAnimationTime() or 0) >= f * FRAMES then style = "hit" end end
                            if style == nil then for an in pairs(w.core_warn) do if A:IsCurrentAnimation(an) then style = "strike" end end end
                            if style ~= nil and w.core_r ~= nil then Circle(w.core_r, style) end
                            if style == nil or (w.core_r or 0) < w.r then Circle(w.r, "fill_light") end
                        end
                    end
                end
            end
            for _, it in ipairs(items) do it.sort = (ST[it.style] or ST.edge).sort or 4 end
            table.sort(items, function(a, b) if a.sort ~= b.sort then return a.sort < b.sort end return a.n < b.n end)
            local owner, overlaps = {}, 0
            local function Fill(poly, c)
                local xs, ys = {}, {}
                for k = 1, #poly, 2 do xs[#xs + 1] = (poly[k] - x0) * S ys[#ys + 1] = (poly[k + 1] - z0) * S end
                local minx, maxx, miny, maxy = math.huge, -math.huge, math.huge, -math.huge
                for k = 1, #xs do minx, maxx, miny, maxy = math.min(minx, xs[k]), math.max(maxx, xs[k]), math.min(miny, ys[k]), math.max(maxy, ys[k]) end
                for yy = math.max(0, math.floor(miny)), math.min(W - 1, math.ceil(maxy)) do
                    for xx = math.max(0, math.floor(minx)), math.min(W - 1, math.ceil(maxx)) do
                        local sx, sy = xx + .5, yy + .5
                        local pos, neg = false, false
                        for k = 1, #xs do
                            local k2 = k % #xs + 1
                            local e = (xs[k2] - xs[k]) * (sy - ys[k]) - (ys[k2] - ys[k]) * (sx - xs[k])
                            if e > 0 then pos = true elseif e < 0 then neg = true end
                        end
                        if not (pos and neg) then
                            local idx = yy * W + xx + 1
                            -- (two styles on one spot: which the game shows is up to its own sorting -
                            -- counted, PIC overlaps)
                            if owner[idx] ~= nil and owner[idx] ~= c and not (xx == 0 or yy == 0) then overlaps = overlaps + 1 end
                            owner[idx] = c
                            local p = img[idx]
                            local a = c[4]
                            p[1], p[2], p[3] = p[1] * (1 - a) + c[1] * 255 * a, p[2] * (1 - a) + c[2] * 255 * a, p[3] * (1 - a) + c[3] * 255 * a
                        end
                    end
                end
            end
            for _, it in ipairs(items) do Fill(it.p, (ST[it.style] or ST.edge).colour) end
            real_print(string.format("PIC overlaps %d pixels (two styles on one spot)", overlaps))
            -- (where the boss is - white, a line the way it faces - and you, blue: rings, to look at)
            local function Ring(cx, cz, r, c)
                for k = 0, 63 do
                    local a = k / 64 * 2 * math.pi
                    for w = -1, 1 do
                        local xx = math.floor((cx + (r + w / S) * math.cos(a) - x0) * S)
                        local yy = math.floor((cz + (r + w / S) * math.sin(a) - z0) * S)
                        if xx >= 0 and yy >= 0 and xx < W and yy < W then img[yy * W + xx + 1] = { c[1], c[2], c[3] } end
                    end
                end
            end
            if list[1] ~= nil then
                local ex, _, ez = list[1].Transform:GetWorldPosition()
                Ring(ex, ez, .3, { 255, 255, 255 })
                local rr = (list[1].Transform:GetRotation() or 0) * math.pi / 180
                for k = 0, 40 do
                    local xx = math.floor((ex + k / 40 * 1.5 * math.cos(rr) - x0) * S)
                    local yy = math.floor((ez - k / 40 * 1.5 * math.sin(rr) - z0) * S)
                    if xx >= 0 and yy >= 0 and xx < W and yy < W then img[yy * W + xx + 1] = { 255, 255, 255 } end
                end
            end
            Ring(py[1], py[2], .5, { 60, 140, 255 })
            local buf = {}
            for i = 1, W * W do local p = img[i] buf[i] = string.char(math.floor(p[1]), math.floor(p[2]), math.floor(p[3])) end
            local out = os.getenv("PIC_OUT") or "pic.ppm"
            if #pic_seq > 0 then out = string.format(out, pic_seq.i) end
            local fh = assert(io.open(out, "wb"))
            fh:write(string.format("P6\n%d %d\n255\n", W, W) .. table.concat(buf))
            fh:close()
            real_print(string.format("PIC %d pieces at t=%.3f round %.2f,%.2f", #items, t, x0 + R, z0 + R))
            pic = nil
            -- (a clip: on to its next frame; its last made - done, the rest of the log not read)
            if #pic_seq > 0 then
                pic_seq.i = pic_seq.i + 1
                if pic_seq[pic_seq.i] == nil then os.exit(0) end
            end
        end
        if pic ~= nil then
            -- (the picture: 24 pixels a unit round the boss and you; each style its own colour, laid
            -- half over what's under it - two pieces over each other show darker/mixed; lines white;
            -- you green, the boss red; x to the right, z down)
            pic_done = true
            local bx, bz = py[1], py[2]
            if list[1] ~= nil then bx, _, bz = list[1].Transform:GetWorldPosition() end
            local x0, x1 = math.min(bx, py[1]) - 14, math.max(bx, py[1]) + 14
            local z0, z1 = math.min(bz, py[2]) - 14, math.max(bz, py[2]) + 14
            local S = 24
            local W, H = math.floor((x1 - x0) * S), math.floor((z1 - z0) * S)
            local img = {}
            for i = 1, W * H do img[i] = { 30, 30, 30 } end
            local cols, palette, np = {}, { { 255, 120, 60 }, { 80, 160, 255 }, { 255, 220, 60 }, { 200, 90, 255 }, { 60, 220, 160 }, { 255, 90, 160 } }, 0
            local function Col(style)
                style = tostring(style)
                if cols[style] == nil then np = np + 1 cols[style] = palette[(np - 1) % #palette + 1] real_print("PIC style " .. style .. " = colour " .. np) end
                return cols[style]
            end
            local function Px(x, z) return (x - x0) * S, (z - z0) * S end
            for _, tr in ipairs(pic.tris) do
                local c = Col(tr[7])
                local ax, ay = Px(tr[1], tr[2])
                local bx2, by = Px(tr[3], tr[4])
                local cx, cy = Px(tr[5], tr[6])
                local minx, maxx = math.max(0, math.floor(math.min(ax, bx2, cx))), math.min(W - 1, math.ceil(math.max(ax, bx2, cx)))
                local miny, maxy = math.max(0, math.floor(math.min(ay, by, cy))), math.min(H - 1, math.ceil(math.max(ay, by, cy)))
                local function E(px, py2, qx, qy, rx, ry) return (qx - px) * (ry - py2) - (qy - py2) * (rx - px) end
                local area = E(ax, ay, bx2, by, cx, cy)
                if area ~= 0 then
                    for yy = miny, maxy do
                        for xx = minx, maxx do
                            local sx, sy = xx + .5, yy + .5
                            local w0, w1, w2 = E(bx2, by, cx, cy, sx, sy), E(cx, cy, ax, ay, sx, sy), E(ax, ay, bx2, by, sx, sy)
                            if (area > 0 and w0 >= 0 and w1 >= 0 and w2 >= 0) or (area < 0 and w0 <= 0 and w1 <= 0 and w2 <= 0) then
                                local p = img[yy * W + xx + 1]
                                p[1], p[2], p[3] = (p[1] + c[1]) / 2, (p[2] + c[2]) / 2, (p[3] + c[3]) / 2
                            end
                        end
                    end
                end
            end
            for _, sg in ipairs(pic.segs) do
                local ax, ay = Px(sg[1], sg[2])
                local bx2, by = Px(sg[3], sg[4])
                local n = math.max(1, math.ceil(math.max(math.abs(bx2 - ax), math.abs(by - ay))))
                for k = 0, n do
                    local xx, yy = math.floor(ax + (bx2 - ax) * k / n), math.floor(ay + (by - ay) * k / n)
                    if xx >= 0 and xx < W and yy >= 0 and yy < H then img[yy * W + xx + 1] = { 255, 255, 255 } end
                end
            end
            -- (and each cell of the maps drawn: a dot in its colour, brighter - what the shapes were
            -- made from)
            local G = require("true_range/moves_sim")._grid
            for _, rec in ipairs(SM._record or {}) do
                local cr, sr = math.cos(rec.rot), math.sin(rec.rot)
                for _, td in ipairs(rec.todo or {}) do
                    local c = Col(td.style)
                    local bright = { math.min(255, c[1] + 80), math.min(255, c[2] + 80), math.min(255, c[3] + 80) }
                    for _, run in ipairs(td.map ~= nil and td.map.runs or {}) do
                        for row = run[1], run[1] + (run[4] or 1) - 1 do
                            for col = run[2], run[3] do
                                local ah, sd = G.ahead + col * G.step, -G.side + row * G.step
                                local wx, wz = rec.x + ah * cr + sd * sr, rec.z - ah * sr + sd * cr
                                local qx, qy = Px(wx, wz)
                                qx, qy = math.floor(qx), math.floor(qy)
                                if qx >= 0 and qx < W and qy >= 0 and qy < H then img[qy * W + qx + 1] = bright end
                            end
                        end
                    end
                end
            end
            local function Dot(x, z, c)
                local cx, cy = Px(x, z)
                for yy = math.floor(cy - 5), math.floor(cy + 5) do
                    for xx = math.floor(cx - 5), math.floor(cx + 5) do
                        if xx >= 0 and xx < W and yy >= 0 and yy < H and (xx - cx) ^ 2 + (yy - cy) ^ 2 <= 25 then img[yy * W + xx + 1] = c end
                    end
                end
            end
            Dot(bx, bz, { 255, 40, 40 })
            Dot(py[1], py[2], { 40, 255, 40 })
            local buf = {}
            for i = 1, W * H do local p = img[i] buf[i] = string.char(math.floor(p[1]), math.floor(p[2]), math.floor(p[3])) end
            local fh = assert(io.open(os.getenv("PIC_OUT") or "pic.ppm", "wb"))
            fh:write(string.format("P6\n%d %d\n255\n", W, H) .. table.concat(buf))
            fh:close()
            real_print(string.format("PIC %d tris, %d lines, %dx%d at t=%.3f", #pic.tris, #pic.segs, W, H, t))
            pic = nil
        end
        -- (REPORT_AT=<time>: what the game's pause would say then - Predict.Report)
        local rat = tonumber(os.getenv("REPORT_AT") or "")
        if rat ~= nil and t >= rat - .04 and not report_done then
            report_done = true
            for _, l in ipairs(Predict.Report(py[1], py[2])) do real_print("REPORT " .. l) end
        end
        local parts = {}
        for _, r in ipairs(SM._record) do
            if r.key == nil or r.key:sub(1, 8) ~= "_hazard|" then parts[#parts + 1] = r end
        end
        SM._record = nil
        local bx, bz = nil, nil
        -- (the boss drawn for - the first of them: tracks by GUID in newer traces, not [1] - read as
        -- [1], the boss was never there for the checks against how it moved)
        local btr = list[1] ~= nil and tracks[list[1].GUID] or nil
        if btr ~= nil and btr.cur ~= nil then bx, bz = btr.cur.x, btr.cur.z end
        local move = btr ~= nil and btr.cur ~= nil and Predict.MoveOf(btr.boss) or nil
        local move_t0 = btr ~= nil and btr.cur ~= nil and Predict.MoveStart(btr.boss) or nil
        if os.getenv("AREA_DBG") and math.abs(t - tonumber(os.getenv("AREA_DBG"))) < .15 then real_print(string.format("AREA %.3f %.1f pieces %d mid %.3f,%.3f", t, area, pieces, cx_sum / math.max(area, 1e-9), cz_sum / math.max(area, 1e-9))) end
        -- (LANE_AT=<time>: how wide what's drawn is either side of the boss's way then, and you off it)
        if os.getenv("LANE_AT") and math.abs(t - tonumber(os.getenv("LANE_AT"))) < FRAMES / 2 and btr ~= nil and btr.cur ~= nil then
            local r = btr.cur.rot * math.pi / 180
            local ux, uz = math.cos(r), -math.sin(r)
            local lo, hi = 0, 0
            for i = 1, #tri_pts, 2 do
                local s = (tri_pts[i] - bx) * -uz + (tri_pts[i + 1] - bz) * ux
                lo, hi = math.min(lo, s), math.max(hi, s)
            end
            real_print(string.format("LANE %.3f drawn %.2f and %.2f either side of its way; you %.2f aside", t, -lo, hi,
                (py[1] - bx) * -uz + (py[2] - bz) * ux))
        end
        -- (how far the shape reaches from where the boss was as the move began - the farthest corner)
        local far = nil
        if move_t0 ~= nil and btr ~= nil then
            if btr.far_t0 ~= move_t0 then btr.far_t0, btr.far_x, btr.far_z = move_t0, bx, bz end
            if btr.far_x ~= nil then
                for i = 1, #tri_pts, 2 do
                    local dd = math.sqrt((tri_pts[i] - btr.far_x) ^ 2 + (tri_pts[i + 1] - btr.far_z) ^ 2)
                    if far == nil or dd > far then far = dd end
                end
            end
        end
        -- (and you inside the very triangles laid this frame - what the game fills, not the cells the
        -- move's maps say: a leap's shape eased and joined drew you in where its cells did not -
        -- the Nightmare Werepig's pounce, you in the red as it struck, "not drawn"; VERIFY_PLAN 6.0a)
        local fill_in = false
        do
            local px_, pz_ = py[1], py[2]
            for i = 1, #tri_pts, 6 do
                local ax, az, bx2, bz2, cx2, cz2 = tri_pts[i], tri_pts[i + 1], tri_pts[i + 2], tri_pts[i + 3], tri_pts[i + 4], tri_pts[i + 5]
                local d1 = (px_ - bx2) * (az - bz2) - (ax - bx2) * (pz_ - bz2)
                local d2 = (px_ - cx2) * (bz2 - cz2) - (bx2 - cx2) * (pz_ - cz2)
                local d3 = (px_ - ax) * (cz2 - az) - (cx2 - ax) * (pz_ - az)
                if not ((d1 < 0 or d2 < 0 or d3 < 0) and (d1 > 0 or d2 > 0 or d3 > 0)) then fill_in = true break end
            end
        end
        -- (what's drawn decides: in its triangles counts as in - OLD_INSIDE=1: the cells' word alone)
        if fill_in and not os.getenv("OLD_INSIDE") then inside = true end
        -- (each part's owner's move then - several of a kind at once, a pack: each its own go, not the first's for all;
        -- SimMoves._record's owner, true_range/predict)
        for _, r in ipairs(parts) do
            if r.owner ~= nil then r.omove, r.omove_t0 = Predict.MoveOf(r.owner), Predict.MoveStart(r.owner) end
        end
        -- (each drawn for this frame on its own: what it drew, where it is, its state and move - every one drawn for,
        -- drawing or not, for the glitch checks one by one)
        local own = {}
        for _, b in ipairs(list) do
            local otr = b.GUID ~= nil and tracks[b.GUID] or nil
            if otr ~= nil and otr.cur ~= nil and otr.boss == b then
                local w = tri_pts.own[b]
                local oa = w ~= nil and w[1] or 0
                own[b] = { area = oa, pieces = oa > 0 and 1 or 0, cx = oa > 0 and w[2] / oa or nil, cz = oa > 0 and w[3] / oa or nil,
                    state = otr.cur.state, bx = otr.cur.x, bz = otr.cur.z, brot = otr.cur.rot, move = Predict.MoveOf(b), move_t0 = Predict.MoveStart(b) }
            end
        end
        drawn_at[#drawn_at + 1] = { t = t, inside = inside, state = state, pieces = pieces, area = area, move = move, move_t0 = move_t0, parts = parts, far = far,
            cx = area > 0 and cx_sum / area or nil, cz = area > 0 and cz_sum / area or nil, bx = bx, bz = bz, n = #list, px = py[1], pz = py[2],
            brot = btr ~= nil and btr.cur ~= nil and btr.cur.rot or nil, fill_in = fill_in, haz_in = haz_in, own = own }
        -- (each of them on its own - a swarm's guards, a pond's frogs drawn at once are no one big shape: by owner)
        for b, w in pairs(tri_pts.own) do
            local ow = own[b]
            if ow ~= nil and ow.move ~= nil and ow.move_t0 ~= nil and (w[4] or 0) > 0 then
                local k = tostring(b.GUID) .. "|" .. tostring(ow.move) .. "@" .. string.format("%.3f", ow.move_t0)
                local bd = big_dark[k]
                if bd == nil then bd = { move = ow.move, max = 0, t = t } big_dark[k] = bd big_dark[#big_dark + 1] = bd end
                if w[4] > bd.max then bd.max, bd.t = w[4], t end
            end
        end
        if SC ~= nil then SC.prefab = PREFAB SC.EndFrame(t, state, move) end
        if os.getenv("PIECES_DBG") then real_print(string.format("frame %.3f %s pieces %d area %.2f inside %s mid->boss %.2f mid->you %.2f", t, state or "-", pieces, area, tostring(inside),
            area > 0 and bx ~= nil and math.sqrt((cx_sum / area - bx) ^ 2 + (cz_sum / area - bz) ^ 2) or -1,
            area > 0 and math.sqrt((cx_sum / area - py[1]) ^ 2 + (cz_sum / area - py[2]) ^ 2) or -1)) end
    else
        prev = nil
    end
    f = f + 1
end

-- each real strike, drawn in: for how long before? the spot struck (where you stood as it struck,
-- not where you walked about) inside what was drawn, every frame back to then - shown only the
-- frame it struck, it was no warning: the Scion's stop came up under you as it hit, counted drawn
local WARN = tonumber(os.getenv("WARN_SECS") or "") or .4
local SM_InMap = require("true_range/simmoves")._InMap
local WARN_EDGE = { { 0, 0 } }
for i = 0, 7 do WARN_EDGE[#WARN_EDGE + 1] = { .3 * math.cos(i * math.pi / 4), .3 * math.sin(i * math.pi / 4) } end
local function WarnedFor(t, x, z)
    local first, gap = nil, 0
    for k = #drawn_at, 1, -1 do
        local d = drawn_at[k]
        if d.t <= t + FRAMES * 1.5 then
            if d.t < t - 3 then break end
            local inside = false
            for _, r in ipairs(d.parts or {}) do
                for _, p in ipairs(r.todo or {}) do
                    -- (or within EDGE of it: the edge eased in by a step as the boss got going is no
                    -- late warning - the spot was at its edge all along)
                    if p.map ~= nil then
                        for _, o in ipairs(WARN_EDGE) do
                            if SM_InMap(p.map, r.x, r.z, r.rot, x + o[1], z + o[2]) then inside = true break end
                        end
                    end
                    if inside then break end
                end
                if inside then break end
            end
            if os.getenv("WARN_DBG") and math.abs(t - tonumber(os.getenv("WARN_DBG"))) < .02 then real_print(string.format("WDBG %.3f parts %d inside %s", d.t, #(d.parts or {}), tostring(inside))) end
            -- (a frame or two not seen in - its parts drawn another way that frame: no gap)
            if inside then first, gap = d.t, 0
            elseif first ~= nil or d.t < t - FRAMES * 1.5 then
                gap = gap + 1
                if gap > 2 or first == nil then break end
            end
        end
    end
    return first ~= nil and (t - first) or 0
end
-- each real strike: drawn in at that moment (or the frame before - the trace is the tick after)?
-- (x, z: where the strike says you were - STRIKE_POS_PARTS=1 only, tried and left: a strike's spot
-- judged against what was drawn for the tick's "you" (see STRIKE_YOU above, what's used instead))
local SM_in = require("true_range/simmoves")._InMap
local function DrawnNear(t, x, z)
    -- (CLIENT: as a player's game says it - the blow's word come ENT_LAG on, "in" if you stood in what was drawn in the .15 s
    -- before it (true_range modmain: last_inside_at < .15))
    local lo, hi = t - FRAMES * 1.5, t + FRAMES * 1.5
    if CLIENT then lo, hi = t + ENT_LAG - .15, t + ENT_LAG + FRAMES / 2 end
    if os.getenv("DN_DBG") and math.abs(t - tonumber(os.getenv("DN_DBG"))) < .01 then
        for _, d in ipairs(drawn_at) do
            if math.abs(d.t - t) < .4 then real_print(string.format("DN %.3f d.t=%.3f inside=%s haz=%s", t, d.t, tostring(d.inside), tostring(d.haz_in))) end
        end
    end
    for _, d in ipairs(drawn_at) do
        if d.t >= lo and d.t <= hi then
            if d.inside or d.haz_in then return true end
            if x ~= nil and d.parts ~= nil and os.getenv("STRIKE_POS_PARTS") then
                for _, r in ipairs(d.parts) do
                    for _, p in ipairs(r.todo or {}) do
                        if p.map ~= nil and r.x ~= nil and SM_in(p.map, r.x, r.z, r.rot or 0, x, z) then return true end
                    end
                end
            end
        end
    end
    return false
end
-- (a log with no [tr_haz] lines - older: what this boss set off unseen; a strike with nothing of
-- its move drawn then, from a boss whose things are drawn on their own (the Celestial Champion's
-- crystals) can't be told from one of theirs - "unchecked", not missed: else a lasting noise in
-- the missed count, a real new miss lost in it)
local SM = require("true_range/simmoves")
local log_has_haz = false
if OLD_READ then
    for line in io.lines(LOG) do if line:find("[tr_haz]", 1, true) then log_has_haz = true break end end
else
    log_has_haz = LOG_HAS_HAZ
end
local own_things = false
for _, h in pairs(SM.Hazards() or {}) do
    if not h.in_move then for _, b in ipairs(h.by or {}) do if b == PREFAB then own_things = true end end end
end
local function NothingDrawn(t)
    for _, d in ipairs(drawn_at) do
        if math.abs(d.t - t) <= FRAMES * 1.5 and d.parts ~= nil and #d.parts > 0 then return false end
    end
    return true
end
-- (a move's shape up while the boss is in a state it strikes nothing from - taunting, idling,
-- walking, flinching - and hasn't struck in the moment before: drawn for nothing. IDLEDRAW, each
-- stretch once. The Eye of Terror's taunt after its charge was drawn as its next charge to come)
-- (not walking or running - a charge set off from a run (the Ancient Guardian's) is drawn as it runs;
-- nor what it threw, still on its way down as it idles: a move's own shape only, d.move)
local QUIET = { idle = true, taunt = true, hit = true }
local idle_draws = 0
do
    local last_strike = -math.huge
    local si = 1
    local open = nil
    for _, d in ipairs(drawn_at) do
        while strikes[si] ~= nil and strikes[si].t <= d.t do last_strike = strikes[si].t si = si + 1 end
        local st = d.state and d.state:match("^([%w_]+)") or nil
        local drawn = d.parts ~= nil and #d.parts > 0
        -- (not a move of that very state - the War Machine's "taunt" kicks all round it)
        local dead = drawn and d.move ~= nil and st ~= nil and QUIET[st] and d.move ~= st and d.n == 1 and d.t - last_strike > .5
        if dead and open == nil then
            open = d
        elseif not dead and open ~= nil then
            if d.t - open.t >= 2 * FRAMES and open.t >= COUNT_FROM then
                idle_draws = idle_draws + 1
                real_print(string.format("IDLEDRAW %.3f %s %s: a move drawn for %.2fs while it was in %s - nothing it strikes from there",
                    open.t, PREFAB, open.move or "?", d.t - open.t, open.state or "?"))
            end
            open = nil
        end
    end
end
-- (FILL_STATS=1: frame by frame, the cells' check against the triangles' - how often they agree)
if os.getenv("FILL_STATS") then
    local both, cells_only, fill_only, neither = 0, 0, 0, 0
    for _, d in ipairs(drawn_at) do
        if d.pieces > 0 then
            if d.inside and d.fill_in then both = both + 1 elseif d.inside then cells_only = cells_only + 1
            elseif d.fill_in then fill_only = fill_only + 1 else neither = neither + 1 end
        end
    end
    real_print(string.format("FILLSTATS %s: frames drawn - in both %d, cells only %d, triangles only %d, neither %d", PREFAB, both, cells_only, fill_only, neither))
end
-- (you gone at once - over 1 in a tick - right as its move took where you were (its lock, from its first
-- animation's start): the game may have read you either side of it, nothing here can tell which - the
-- Celestial Champion's beam and sweep, the bench's 150-degree step on frame 21 itself, all 48 of its
-- missed; a soul hop as it aims, in a real game. Said as AIMJUMP, apart from missed. OLD_AIMJUMP=1: missed)
-- (one with no moves of its own that is a thing that strikes itself - Uncompromising Mode's shadow Abigail, her bursts all round
-- her: its blows are that thing's, judged by tests/replay_haz.lua - here, with no move to judge them by, 392 "missed",
-- 2026-10-20. OLD_SELFTHING=1: judged here as before)
do
    local SMs = require("true_range/simmoves")
    if not os.getenv("OLD_SELFTHING") and (SMs.Hazards() or {})[PREFAB] ~= nil and #(SMs.Moves(PREFAB) or {}) == 0 and #strikes > 0 then
        real_print(string.format("SELFTHING %s: %d blows its own thing's - judged by replay_haz", PREFAB, #strikes))
        strikes = {}
    end
end
local function AimJumped(s)
    if os.getenv("OLD_AIMJUMP") then return false end
    local at = nil
    for _, k in ipairs(ticks) do
        if k.t > s.t + 1e-6 then break end
        if s.guid == nil or k.guid == s.guid then at = k end
    end
    if at == nil or at.anim == nil then return false end
    for _, m in ipairs(require("true_range/simmoves").Moves(PREFAB) or {}) do
        local mine = false
        for _, a in ipairs(m.anims or {}) do if a == at.anim then mine = true end end
        local lock = m.sim ~= nil and m.sim.lock or nil
        if mine and lock ~= nil and lock > 0 then
            -- (its first animation's start: the last tick in it, less its time)
            local start = nil
            for _, k in ipairs(ticks) do
                if k.t > s.t + 1e-6 then break end
                if (s.guid == nil or k.guid == s.guid) and k.anim == m.anims[1] and k.anim_t ~= nil then start = k.t - k.anim_t end
            end
            if start ~= nil then
                local read = start + lock * FRAMES
                local prev = nil
                for _, k in ipairs(ticks) do
                    if k.t > read + 1.5 * FRAMES then break end
                    if (s.guid == nil or k.guid == s.guid) and k.yx ~= nil then
                        if prev ~= nil and k.t >= read - 1.5 * FRAMES and (k.yx - prev.yx) ^ 2 + (k.yz - prev.yz) ^ 2 > 1 then return true end
                        prev = k
                    end
                end
            end
        end
    end
    return false
end
-- (modmain's AGGRO_WHILE: a faint ring of r round it - or round you (at_you) - while it plays one of anims, and linger s
-- after, drawn by its own code: Tropical Experience's twister's vacuum, its thunderbird's lightning - judged here as
-- modmain draws it, from the trace's animation. OLD_AGGRO=1: not judged, as before)
local AGGRO_WHILE = nil
local function AggroCovers(s)
    if os.getenv("OLD_AGGRO") then return false end
    if AGGRO_WHILE == nil then
        AGGRO_WHILE = {}
        local mf = io.open(MOD .. "/modmain.lua", "rb")
        local src = mf and mf:read("*a") or ""
        if mf then mf:close() end
        for name, body in (src:match("local AGGRO_WHILE = (%b{})") or ""):gmatch("\n%s*([%w_]+) = (%b{})") do
            local anims = {}
            for a in (body:match("anims = (%b{})") or ""):gmatch('"([%w_]+)"') do anims[a] = true end
            AGGRO_WHILE[name] = { r = tonumber(body:match("r = ([%d%.]+)")), anims = anims,
                at_you = body:find("at_you = true", 1, true) ~= nil, linger = tonumber(body:match("linger = ([%d%.]+)")) or 0 }
            -- (jump = { d, warn, hit }: drawn round where it jumped to, from the jump on for warn + hit s)
            local jb = body:match("jump = (%b{})")
            if jb ~= nil then
                AGGRO_WHILE[name].jump = { d = tonumber(jb:match("d = ([%d%.]+)")), warn = tonumber(jb:match("warn = ([%d%.]+)")),
                    hit = tonumber(jb:match("hit = ([%d%.]+)")) }
            end
        end
    end
    local w = AGGRO_WHILE[PREFAB]
    if w == nil or w.r == nil then return false end
    -- (OLD_AGGRO_JUMP=1: not judged - the control)
    if w.jump ~= nil and w.jump.d ~= nil and not os.getenv("OLD_AGGRO_JUMP") then
        local last = {}
        for _, k in ipairs(ticks) do
            if k.t > s.t + 1e-6 then break end
            local g = k.guid or 0
            local p = last[g]
            if p ~= nil and k.x ~= nil and p.x ~= nil and (k.x - p.x) ^ 2 + (k.z - p.z) ^ 2 > w.jump.d * w.jump.d
                and (s.guid == nil or k.guid == s.guid) and k.t >= s.t - w.jump.warn - w.jump.hit - 1.5 * FRAMES
                and (s.x - k.x) ^ 2 + (s.z - k.z) ^ 2 <= w.r * w.r then
                return true
            end
            last[g] = k
        end
    end
    -- (playing one of them then, or lately enough)
    local on = false
    for _, k in ipairs(ticks) do
        if k.t > s.t + 1e-6 then break end
        if (s.guid == nil or k.guid == s.guid) and k.anim ~= nil and w.anims[k.anim] and k.t >= s.t - w.linger - 1.5 * FRAMES then on = true end
    end
    if not on then return false end
    if w.at_you then return true end
    return (s.x - s.bx) ^ 2 + (s.z - s.bz) ^ 2 <= w.r * w.r
end
local missed, ok, unchecked, short, aimjump = 0, 0, 0, 0, 0
-- (when each of those was - OUTSIDE below leaves out what came down in the same go)
AIMJUMP_T = {}
-- (PRED=n: the lag bench's scenes so set, each till the next begins - [tr_bench] <t> <boss> lag scene n= pred=)
local pred_scenes = nil
if PRED then
    pred_scenes = {}
    for line in io.lines(LOG) do
        local st, sp = line:match("%[tr_bench%] ([%d%.]+) [%w_]+ lag scene n=%d+ pred=(%d)")
        if st ~= nil then pred_scenes[#pred_scenes + 1] = { t = tonumber(st), pred = tonumber(sp) } end
    end
end
local function InPredScene(t)
    if pred_scenes == nil then return true end
    local p = nil
    for _, s in ipairs(pred_scenes) do if s.t <= t then p = s.pred else break end end
    return p == PRED
end
for _, s in ipairs(strikes) do
    -- (CLIENT: where your game had you as it struck - YOU_LEAD frames on (or back) along how you went)
    if YOU_LEAD_F and s.vx ~= nil and not s.led then
        s.x, s.z, s.led = s.x + s.vx * YOU_LEAD_F * FRAMES, s.z + s.vz * YOU_LEAD_F * FRAMES, true
    end
    if s.t >= math.max(t0, COUNT_FROM) and s.t <= t1 and InPredScene(s.t) then
        if DrawnNear(s.t, s.x, s.z) or s.dart_lane then
            ok = ok + 1
            -- (a thing of its by you that strikes as the boss, its move drawn there all the same: said, for
            -- tests/bench_replay.ps1 to take it from that thing's missed - replay_haz.lua hands it the thing
            -- not knowing the move: the Possessed Varg's breath round its mouth (SGwarg DoFlamethrowerAOE,
            -- 3 ahead, 1.7 round), 32 of its flames' 34 missed, 2.5-3.6 from any flame)
            if s.by_own then real_print(string.format("ASBOSS_DRAWN %.3f %s", s.t, PREFAB)) end
            -- (and in time: the spot struck shown long enough before - as long as its move let it,
            -- begun less than that before)
            local began = nil
            for _, d in ipairs(drawn_at) do
                if math.abs(d.t - s.t) <= FRAMES * 1.5 and d.move_t0 ~= nil then began = d.move_t0 end
            end
            local lead = WarnedFor(s.t, s.x, s.z)
            -- (or you inside it all along, wherever you went - one that follows you, a spin chasing
            -- you round: the very spot came in late, you were in it the whole time)
            local you_first = nil
            for k = #drawn_at, 1, -1 do
                local d = drawn_at[k]
                if d.t <= s.t + FRAMES * 1.5 then
                    if d.inside then you_first = d.t elseif you_first ~= nil or d.t < s.t - FRAMES * 1.5 then break end
                end
            end
            lead = math.max(lead, you_first ~= nil and (s.t - you_first) or 0)
            -- (nor before it really began: the state it struck in, entered so long ago (the trace's
            -- time in state) - Klaus' quick swipe plays its animation from the middle, struck its
            -- first frame: its animation's time said it began half a second before)
            local in_state = nil
            for _, k in ipairs(ticks) do
                if k.t <= s.t + 1e-6 and (s.guid == nil or k.guid == s.guid) and k.state == s.state and k.ts ~= nil then in_state = k.t - k.ts end
                if k.t > s.t then break end
            end
            if in_state ~= nil then began = math.max(began or in_state, in_state) end
            local could = began ~= nil and math.min(WARN, s.t - began) or WARN
            -- (two frames' give, and a hair: the trace a tick after, the client a tick behind - shown
            -- from its very second frame came out .2667 against .2666)
            -- (a dart's lane: shown with its move from the start - DrawShot - and on as it flew, not in drawn_at)
            if lead < could - 2.5 * FRAMES and not s.dart_lane then
                short = short + 1
                real_print(string.format("SHORT   %.3f %s %s: the spot struck shown only %.2fs before (its move began %.2fs before)",
                    s.t, PREFAB, s.state, lead, began ~= nil and (s.t - began) or -1))
            end
        elseif s.by_own then
            -- (not drawn with its move, a thing of its by you that strikes as the boss: that thing's -
            -- replay_haz.lua judges it)
            by_thing[#by_thing + 1] = s
        elseif not log_has_haz and own_things and NothingDrawn(s.t) then
            unchecked = unchecked + 1
            real_print(string.format("UNCHECKED %.3f %s %s: struck, nothing of its move drawn - maybe a thing of its, not traced in this log", s.t, PREFAB, s.state))
        elseif AggroCovers(s) then
            ok = ok + 1
            real_print(string.format("AGGRO_DRAWN %.3f %s %s", s.t, PREFAB, s.state))
        elseif AimJumped(s) then
            aimjump = aimjump + 1
            AIMJUMP_T[#AIMJUMP_T + 1] = s.t
            real_print(string.format("AIMJUMP %.3f %s %s: struck, not drawn - you went over 1 in a tick as it took where you were", s.t, PREFAB, s.state))
        -- (struck from your own middle: worn on you, nothing to warn of - the Hound Batilisk on your head as a hat, biting
        -- every 0.6 s (SGbat TryHat), 165 "missed" so on the bench, its leap on drawn; 2026-10-23 update. OLD_WORN=1: missed)
        elseif (s.x - s.bx) ^ 2 + (s.z - s.bz) ^ 2 < .01 and not os.getenv("OLD_WORN") then
            rawset(_G, "WORN_N", (rawget(_G, "WORN_N") or 0) + 1)
            real_print(string.format("WORN    %.3f %s %s: struck from your own middle - worn on you", s.t, PREFAB, s.state))
        else
            missed = missed + 1
            real_print(string.format("MISSED  %.3f %s %s%s: struck, not drawn (you %.2f,%.2f; it %.2f,%.2f, %.2f off)", s.t, PREFAB, s.state,
                scene_of[s.guid or ""] and (" [" .. scene_of[s.guid] .. "]") or "",
                s.x, s.z, s.bx, s.bz, math.sqrt((s.x - s.bx) ^ 2 + (s.z - s.bz) ^ 2)))
            -- (NEAR_EDGE=<units>: was what's drawn then within that of you - a miss a wider edge would
            -- have caught, or one nothing near; VERIFY_PLAN 6.0a, how much a wider cell edge could help)
            -- (FILLIN: you were inside the triangles drawn then, though not in its cells - what's shown
            -- covered you; counted apart, the cells' check left as it is)
            for _, d in ipairs(drawn_at) do
                if math.abs(d.t - s.t) <= FRAMES * 1.5 and d.fill_in then
                    real_print(string.format("FILLIN  %.3f %s %s: not in its cells, inside what's drawn", s.t, PREFAB, s.state))
                    break
                end
            end
            local ne = tonumber(os.getenv("NEAR_EDGE") or "")
            if ne ~= nil and s.x ~= nil then
                local near = false
                for _, d in ipairs(drawn_at) do
                    if math.abs(d.t - s.t) <= FRAMES * 1.5 then
                        for _, r in ipairs(d.parts or {}) do
                            for _, p in ipairs(r.todo or {}) do
                                if p.map ~= nil and not near then
                                    for k = 0, 15 do
                                        local a = k * math.pi / 8
                                        for _, e in ipairs({ ne, ne / 2 }) do
                                            if SM_InMap(p.map, r.x, r.z, r.rot, s.x + e * math.cos(a), s.z + e * math.sin(a)) then near = true break end
                                        end
                                        if near then break end
                                    end
                                end
                            end
                        end
                    end
                end
                real_print(string.format("NEAREDGE %.3f %s %s: %s", s.t, PREFAB, s.state, near and "drawn within " .. ne or "nothing near"))
            end
        end
    end
end
-- (struck by a thing of its own, from the game's own word of it ("you were struck by"): inside what
-- was drawn then? THINGMISS - not; only said, apart from the strikes' count)
do
    local tk, tm, by_miss = 0, 0, {}
    for _, h in ipairs(thing_hits) do
        if h.by ~= nil and h.t >= math.max(t0, COUNT_FROM) and h.t <= t1 then
            -- (and drawn so, said as the boss's - tests/bench_replay.ps1 takes it from that thing's missed: Retinazer's laser
            -- striking the tick it was made, in its move's lane, 3 "missed" as a thing; 2026-10-28. OLD_THINGASBOSS=1: not said)
            if DrawnNear(h.t) then
                tk = tk + 1
                if not os.getenv("OLD_THINGASBOSS") then real_print(string.format("ASBOSS_DRAWN %.3f %s", h.t, PREFAB)) end
            else
                tm = tm + 1
                by_miss[h.by] = (by_miss[h.by] or 0) + 1
                if os.getenv("THING_V") then real_print(string.format("THINGMISS %.3f %s: struck by %s, not drawn", h.t, PREFAB, h.by)) end
            end
        end
    end
    if tk + tm > 0 then
        local s = {}
        for b, n in pairs(by_miss) do table.insert(s, b .. " " .. n) end
        table.sort(s)
        real_print(string.format("%s: things struck you %d - %d drawn, %d not%s", PREFAB, tk + tm, tk, tm, #s > 0 and (" (" .. table.concat(s, ", ") .. ")") or ""))
    end
end
-- YELLOW: what's drawn yellow (about to strike) must go red (striking) after, the same go of the
-- move - yellow and then gone, never red, warned of a strike that wasn't drawn coming (the user's
-- rule: "yellow is always followed by red"). Each part drawn yellow sampled every half unit; a
-- spot never inside a red part after, the go's frames on: counted, its area said
local yellow_never, yellow_goes, yellow_cut = 0, 0, 0
do
    local owner_tr = {}
    for _, tr in ipairs(tracks) do if tr.boss ~= nil then owner_tr[tr.boss] = tr end end
    local YELLOW = { strike = true, st_strike = true, shape_strike = true }
    local RED = { hit = true, st_hit = true, shape_hit = true }
    -- (over one run of frames - one of a kind's own, each its own shapes and its own go)
    -- (rel: each spot taken in the shape's own frame - ahead/aside of where it's drawn from - so a yellow carried along
    -- with a guard flying in, gone red where it got to, is the same spot gone red; in the world's frame its trail
    -- left behind counted "never red", 7321 over a pack of guards, 2026-10-20. A yellow drawn here and red drawn
    -- elsewhere: AIMJUMP's)
    local function YellowOver(drawn_at, rel)
    local i = 1
    while i <= #drawn_at do
        local d = drawn_at[i]
        local j = i
        while j + 1 <= #drawn_at and drawn_at[j + 1].move == d.move and drawn_at[j + 1].move_t0 == d.move_t0 and drawn_at[j + 1].t - drawn_at[j].t < 2.5 * FRAMES do j = j + 1 end
        if d.move ~= nil then
            local pts, seen, at_max, at_min = {}, {}, 0, nil
            for k = i, j do
                for _, r in ipairs(drawn_at[k].parts or {}) do
                    for _, p in ipairs(r.todo or {}) do
                        if p.map ~= nil and YELLOW[p.style or ""] then
                            if (p.map.at or 0) > at_max then at_max = p.map.at end
                            if p.map.at ~= nil and p.map.at > 0 and (at_min == nil or p.map.at < at_min) then at_min = p.map.at end
                            local key = tostring(p.map) .. string.format("|%.1f,%.1f,%.2f", r.x, r.z, r.rot)
                            if not seen[key] then
                                seen[key] = true
                                for gx = -16, 16, .5 do
                                    for gz = -16, 16, .5 do
                                        local x, z = r.x + gx, r.z + gz
                                        if SM_InMap(p.map, r.x, r.z, r.rot, x, z) then
                                            local q = { x = x, z = z, k = k }
                                            if rel then
                                                local c, s = math.cos(r.rot), math.sin(r.rot)
                                                q.a, q.s = gx * c - gz * s, gx * s + gz * c
                                            end
                                            local pk = rel and string.format("%.1f,%.1f", q.a, q.s) or string.format("%.1f,%.1f", x, z)
                                            if pts[pk] == nil then pts[pk] = q end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            -- (red looked for on to its strike's frame, past the go's end in its own view: one move handed on to the next
            -- as its state changes - the Ancient Guardian's tentacle, atk_pre's yellow gone red as atk_loop, 1,489 "never
            -- red" on strikes that came, 2026-10-20. OLD_YELLOW_GO=1: within the go)
            local jr = j
            if rel and d.move_t0 ~= nil and at_max > 0 and not os.getenv("OLD_YELLOW_GO") then
                while jr + 1 <= #drawn_at and drawn_at[jr + 1].t <= d.move_t0 + (at_max + 3) * FRAMES do jr = jr + 1 end
            end
            local left, n = 0, 0
            for _, q in pairs(pts) do
                n = n + 1
                local red = false
                for k = q.k, jr do
                    for _, r in ipairs(drawn_at[k].parts or {}) do
                        for _, p in ipairs(r.todo or {}) do
                            local qx, qz = q.x, q.z
                            if rel then
                                local c, s = math.cos(r.rot), math.sin(r.rot)
                                qx, qz = r.x + q.a * c + q.s * s, r.z - q.a * s + q.s * c
                            end
                            if p.map ~= nil and RED[p.style or ""] and SM_InMap(p.map, r.x, r.z, r.rot, qx, qz) then red = true break end
                        end
                        if red then break end
                    end
                    if red then break end
                end
                if not red then left = left + 1 if os.getenv("YELLOW_DBG") and math.abs(d.t - tonumber(os.getenv("YELLOW_DBG"))) < .05 then local r0 = drawn_at[q.k].parts[1] local c, s = math.cos(r0.rot), math.sin(r0.rot) real_print(string.format("YDBG along %.1f aside %.1f first yellow %.3f", (q.x - r0.x) * c - (q.z - r0.z) * s, (q.x - r0.x) * s + (q.z - r0.z) * c, drawn_at[q.k].t)) end end
            end
            if os.getenv("YELLOW_DBG") and math.abs(d.t - tonumber(os.getenv("YELLOW_DBG"))) < .05 then for k = i, j do if drawn_at[k].t > tonumber(os.getenv("YELLOW_DBG")) + tonumber(os.getenv("YDBG_FROM") or ".75") and drawn_at[k].t < tonumber(os.getenv("YELLOW_DBG")) + tonumber(os.getenv("YDBG_TO") or "1.15") then local st = {} for _, r in ipairs(drawn_at[k].parts or {}) do for _, p in ipairs(r.todo or {}) do st[#st + 1] = tostring(p.style) .. "@" .. tostring(p.map and p.map.at) end end real_print(string.format("YLAST %.3f %s %s", drawn_at[k].t, tostring(drawn_at[k].state), table.concat(st, " "))) end end real_print(string.format("YNEXT %s", drawn_at[j + 1] and string.format("%.3f %s %s", drawn_at[j + 1].t, tostring(drawn_at[j + 1].state), tostring(drawn_at[j + 1].move)) or "-")) end
            -- (in its own frame the yellow can't be seen put elsewhere as it goes red: the last yellow frame against the
            -- first red one, where they are - drawn here, struck there, the parts changing that frame so no JUMP said it.
            -- OLD_YELLOW_WORLD=1 has the world's frame throughout)
            local moved_at, moved_tot = 0, 0
            if rel and n > 0 then
                -- (shape by shape - its map: a pound's rings each yellow to red on their own frame, its first ring's red
                -- no match for its last ring's yellow, the Bearger's 190 so; and within half a unit, a cell's edge
                -- landing either way as it is laid a hair off - 1.0 on a guard's sting standing still)
                local otr = owner_tr[drawn_at[i].parts[1] and drawn_at[i].parts[1].owner or false]
                local function PosAt(t) local p = nil for _, tk in ipairs(otr.ticks) do if tk.t > t + 1e-6 then break end p = tk end return p end
                local lasty = {}
                for k = i, j do
                    for _, r in ipairs(drawn_at[k].parts or {}) do
                        for _, p in ipairs(r.todo or {}) do
                            if p.map ~= nil and YELLOW[p.style or ""] then lasty[p.map] = k end
                        end
                    end
                end
                local fault = tonumber(os.getenv("YELLOW_FAULT") or "") or 0
                for map, ky in pairs(lasty) do
                    local kr = nil
                    for k = ky + 1, jr do
                        for _, r in ipairs(drawn_at[k].parts or {}) do
                            for _, p in ipairs(r.todo or {}) do if p.map == map and RED[p.style or ""] then kr = kr or k end end
                        end
                        if kr ~= nil then break end
                    end
                    if kr ~= nil then
                        -- (less how far its owner went between the two frames - a guard flying in as it stings, its ring with
                        -- it. Its owner's track, the last tick at or before each)
                        -- (as the shape is laid: its anchor gone on no more than its owner went (+0.5) and turned under 0.1
                        -- - carried along, the same shape: a guard's ring with it as it flies, the Twins' lane laid where its
                        -- dash began as it dashes (its owner's move taken off, that lane counted 0.77 a frame off, 819 so))
                        local om = 0
                        if otr ~= nil then
                            local p1, p2 = PosAt(drawn_at[ky].t), PosAt(drawn_at[kr].t)
                            if p1 ~= nil and p2 ~= nil then om = math.sqrt((p2.x - p1.x) ^ 2 + (p2.z - p1.z) ^ 2) end
                        end
                        local fault = tonumber(os.getenv("YELLOW_FAULT") or "") or 0
                        local ra, rb = nil, nil
                        for _, r in ipairs(drawn_at[ky].parts or {}) do for _, p in ipairs(r.todo or {}) do if p.map == map and YELLOW[p.style or ""] then ra = ra or r end end end
                        for _, r in ipairs(drawn_at[kr].parts or {}) do for _, p in ipairs(r.todo or {}) do if p.map == map and RED[p.style or ""] then rb = rb or r end end end
                        local carried = false
                        if ra ~= nil and rb ~= nil then
                            local dr = math.abs(((rb.rot - ra.rot) + math.pi) % (2 * math.pi) - math.pi)
                            carried = math.sqrt((rb.x + fault - ra.x) ^ 2 + (rb.z - ra.z) ^ 2) <= om + .5 and dr < .1
                        end
                        local ox, oz = 0, 0
                        local done = {}
                        -- (and most of it gone from under the red - put somewhere else; a lane laid anew from where its owner
                        -- has got to drops the stretch behind it, the rest still under: the Celestial Champion's roll set from its
                        -- start then from itself 8 on, 727 so - its lane in parts, the parts behind it all gone: the whole go's)
                        local tot = 0
                        for _, r in ipairs(carried and {} or drawn_at[ky].parts or {}) do
                            for _, p in ipairs(r.todo or {}) do
                                if p.map == map and YELLOW[p.style or ""] then
                                    for gx = -16, 16, .5 do
                                        for gz = -16, 16, .5 do
                                            local x, z = r.x + gx, r.z + gz
                                            local pk = string.format("%.1f,%.1f", x, z)
                                            if not done[pk] and SM_InMap(p.map, r.x, r.z, r.rot, x, z) then
                                                done[pk] = true
                                                tot = tot + 1
                                                done._a = (done._a or 0) + gx * math.cos(r.rot) - gz * math.sin(r.rot)
                                                done._s = (done._s or 0) + gx * math.sin(r.rot) + gz * math.cos(r.rot)
                                                x, z = x + ox, z + oz
                                                local red = false
                                                for _, e in ipairs(WARN_EDGE) do
                                                    for _, r2 in ipairs(drawn_at[kr].parts or {}) do
                                                        for _, p2 in ipairs(r2.todo or {}) do
                                                            -- (YELLOW_FAULT=<units>: the red put that far off - this check's own control)
                                                            if p2.map == map and RED[p2.style or ""] and SM_InMap(p2.map, r2.x + fault, r2.z, r2.rot, x + e[1] * 5 / 3, z + e[2] * 5 / 3) then red = true break end
                                                        end
                                                        if red then break end
                                                    end
                                                    if red then break end
                                                end
                                                if not red then moved_at = moved_at + 1 end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        moved_tot = moved_tot + tot
                        if os.getenv("YMOVED_V") then real_print(string.format("YMOVED %.3f map %s yellow %.3f red %.3f owner moved %.2f; anchor %.2f,%.2f r%.3f -> %.2f,%.2f r%.3f; carried %s; yellow's middle %.2f ahead %.2f aside, at %s -> %d", d.t, tostring(map), drawn_at[ky].t, drawn_at[kr].t, om,
                            ra and ra.x or 0, ra and ra.z or 0, ra and ra.rot or 0, rb and rb.x or 0, rb and rb.z or 0, rb and rb.rot or 0, tostring(carried), (done._a or 0) / math.max(tot, 1), (done._s or 0) / math.max(tot, 1), tostring(map.at), moved_at)) end
                    end
                end
            end
            if n > 0 and d.t >= COUNT_FROM and moved_at * .25 >= 1 and moved_at > .5 * moved_tot then
                yellow_never = yellow_never + 1
                real_print(string.format("YELLOW  %.3f %s %s: %.1f of its last yellow not under its first red - put elsewhere as it struck", d.t, PREFAB, tostring(d.move), moved_at * .25))
            elseif n > 0 and d.t >= COUNT_FROM then
                yellow_goes = yellow_goes + 1
                -- (more than a sliver: a unit square and more of it)
                -- (cut short: the game's own trace of that one has it out of the state it began the go in - or gone -
                -- before its strike's frame came: no strike to go red for, the yellow rightly gone. A guard called up
                -- by its queen mid-sting, the 3 left of 174, 2026-10-20. Told by the trace, not the drawing: a drawing
                -- gone early on a strike that came still counts. OLD_YELLOW_CUT=1: counted as before)
                local cut = false
                local tr = owner_tr ~= nil and owner_tr[drawn_at[i].parts[1] and drawn_at[i].parts[1].owner or false] or nil
                -- (out of the move, not of a state: its animations, as its data has them - the Bearger's pound runs on
                -- through states, its far ring striking after; taken by its first state, 190 of its goes "cut", 2026-10-20)
                local anims = nil
                for _, m in ipairs(require("true_range/simmoves").Moves(PREFAB) or {}) do
                    if (m.name or (m.anims or {})[1]) == d.move then anims = {} for _, a in ipairs(m.anims or {}) do anims[a] = true end end
                end
                -- (before its first strike: one that struck, its far rings after on their own clock (the Bearger's pound,
                -- on into its taunt), is no cut)
                if left * .25 >= 1 and tr ~= nil and anims ~= nil and d.move_t0 ~= nil and at_min ~= nil and not os.getenv("OLD_YELLOW_CUT") then
                    local t_hit, t_end, s0, after = d.move_t0 + at_min * FRAMES - FRAMES * .5, drawn_at[j].t, nil, false
                    for _, tk in ipairs(tr.ticks) do
                        if tk.t <= d.t + 1e-6 then s0 = tk.anim
                        elseif tk.t > t_end + 1e-6 then
                            if tk.t >= t_hit then after = true break end
                            if tk.anim ~= nil and not anims[tk.anim] then s0 = tk.anim cut = true break end
                        end
                    end
                    -- (its trace over before then - you put out of its reach, the trace stopped: not known, the replay's
                    -- drawing stopped with what it was given, not the mod's; YELLOWGONE apart from a cut)
                    local gone = not cut and not after
                    if gone then cut = true end
                    if cut then
                        yellow_cut = yellow_cut + 1
                        if os.getenv("YELLOW_V") then real_print(gone and string.format("YELLOWGONE %.3f %s %s: its trace over before its strike", d.t, PREFAB, tostring(d.move))
                            or string.format("YELLOWCUT %.3f %s %s: into %s before its strike", d.t, PREFAB, tostring(d.move), tostring(s0))) end
                    end
                end
                if left * .25 >= 1 and not cut then
                    yellow_never = yellow_never + 1
                    real_print(string.format("YELLOW  %.3f %s %s: %.1f of %.1f drawn yellow never went red", d.t, PREFAB, tostring(d.move), left * .25, n * .25))
                end
            end
        end
        i = j + 1
    end
    end
    -- (each of a kind on its own: its parts, its own move and go, frame by frame - a pack of 8 guards taken as one, one's
    -- yellow judged against the next's go, 174 "never went red", 2026-10-20. Parts with no owner told (an older mod):
    -- as before, the frame's first. OLD_YELLOW_ONE=1: all as one)
    if os.getenv("OLD_YELLOW_ONE") then YellowOver(drawn_at) else
        local views, order = {}, {}
        for _, d in ipairs(drawn_at) do
            local per, porder = {}, {}
            for _, r in ipairs(d.parts or {}) do
                local o = r.owner or "_"
                if per[o] == nil then per[o] = {} porder[#porder + 1] = o end
                table.insert(per[o], r)
            end
            for _, o in ipairs(porder) do
                if views[o] == nil then views[o] = {} order[#order + 1] = o end
                local ps = per[o]
                local mv, mt0 = d.move, d.move_t0
                if o ~= "_" then mv, mt0 = ps[1].omove, ps[1].omove_t0 end
                table.insert(views[o], { t = d.t, move = mv, move_t0 = mt0, parts = ps, state = d.state })
            end
        end
        if os.getenv("YVIEW_DBG") then
            local tt = tonumber(os.getenv("YVIEW_DBG"))
            for _, o in ipairs(order) do
                for _, v in ipairs(views[o]) do
                    if math.abs(v.t - tt) < .7 then
                        local st = {}
                        for _, r in ipairs(v.parts) do for _, p in ipairs(r.todo or {}) do st[#st + 1] = tostring(p.style) .. "@" .. tostring(p.map and p.map.at) end end
                        real_print(string.format("YVIEW %s %.3f %s %s %s", tostring(o), v.t, tostring(v.move), tostring(v.move_t0), table.concat(st, " ")))
                    end
                end
            end
        end
        for _, o in ipairs(order) do YellowOver(views[o], o ~= "_" and not os.getenv("OLD_YELLOW_WORLD")) end
    end
end
-- each "drawn in" the drawing reported: a real strike within .3s?
local false_alarm = 0
for _, w in ipairs(said) do
    if w.here and w.t >= COUNT_FROM then
        local real = false
        for _, s in ipairs(strikes) do if math.abs(s.t - w.t) <= .3 then real = true end end
        for _, s in ipairs(thing_hits) do if math.abs(s.t - w.t) <= .3 then real = true end end
        -- (or a blow by a thing it set off that strikes as the boss (BYTHING), a moment after: the Possessed Varg's
        -- breath drawn as its fan, its flames reaching you 0.3-1 s on - 87 of its 98 "drawn in, not struck" so,
        -- 2026-10-20. OLD_FALSE_BYTHING=1: as before)
        if not real and not os.getenv("OLD_FALSE_BYTHING") then
            for _, s in ipairs(by_thing) do if s.t >= w.t - .3 and s.t <= w.t + 1 then real = true end end
        end
        -- (or its own strike in that same go a moment after - the same breath, its own round its mouth now
        -- drawn with its fan on through its loop (no longer handed to its flames): its sweep reaching you
        -- 0.3-1 s on. The same go: begun at the same moment (drawn_at move_t0). Only a move drawn striking on
        -- and on (a step's again_anim) - not a charge's part struck early, its blow 0.5 s on: that's drawn too
        -- soon (Rook, Rabbit King's dropkick - 30 FALSE hidden so at first). OLD_FALSE_SAMEGO=1: not)
        if not real and not os.getenv("OLD_FALSE_SAMEGO") then
            local function GoAt(t)
                for _, d in ipairs(drawn_at) do if math.abs(d.t - t) < FRAMES / 2 then return d.move_t0, d.move end end
                return nil
            end
            local g, mv = GoAt(w.t)
            local on_and_on = false
            for _, m in ipairs(SimMoves.Moves(PREFAB) or {}) do
                if m.name == mv and m.sim ~= nil then
                    for _, mp in ipairs(m.sim.maps or {}) do
                        for _, st in ipairs(mp.steps or {}) do if st.again_anim ~= nil and st.again_anim ~= "" then on_and_on = true end end
                    end
                end
            end
            if g ~= nil and on_and_on then
                for _, s in ipairs(strikes) do
                    if s.t > w.t and s.t <= w.t + 1 and GoAt(s.t) == g then real = true break end
                end
            end
        end
        if not real then
            false_alarm = false_alarm + 1
            local st = "?"
            for _, d in ipairs(drawn_at) do if math.abs(d.t - w.t) < FRAMES / 2 then st = d.state end end
            real_print(string.format("FALSE   %.3f %s %s: drawn in, not struck%s", w.t, PREFAB, st, w.edge and " (at its edge)" or ""))
        end
    end
end
-- (flicker: a frame drawing nothing between two that draw, the boss in the same state)
local flicker = 0
for i = 2, #drawn_at - 1 do
    local a, b, c = drawn_at[i - 1], drawn_at[i], drawn_at[i + 1]
    if b.pieces == 0 and a.pieces > 0 and c.pieces > 0 and a.state == b.state and b.state == c.state then
        flicker = flicker + 1
        real_print(string.format("FLICKER %.3f %s %s: nothing drawn for a frame", b.t, PREFAB, b.state))
    end
end
real_print(string.format("%s: %d frames flickered", PREFAB, flicker))
-- (GATE: which move was drawn when - "SPAN from to move", for tools/table_gate.ps1 to tell each
-- thing said above to its move)
if os.getenv("GATE") then
    local s = nil
    for _, d in ipairs(drawn_at) do
        if s ~= nil and (d.move ~= s.move or d.t - s.to > .5) then
            real_print(string.format("SPAN %.3f %.3f %s", s.from, s.to, tostring(s.move)))
            s = nil
        end
        if s == nil then s = { from = d.t, to = d.t, move = d.move } else s.to = d.t end
    end
    if s ~= nil then real_print(string.format("SPAN %.3f %.3f %s", s.from, s.to, tostring(s.move))) end
end
-- (what you'd see going wrong, frame to frame - each said, and counted)
-- VANISH: the shape gone for 1-3 frames and back - also across a change of state (a charge's
-- shape gone as it sets off)
-- SHRINK: half of it gone for a frame, then back
-- JUMP: the shape's middle off by over a unit from one frame to the next, the same size, the
-- boss hardly moving
local glitches = 0
local function Said(kind, d, text)
    if d ~= nil and d.t ~= nil and d.t < COUNT_FROM then return end
    glitches = glitches + 1
    real_print(string.format("%-7s %.3f %s %s: %s", kind, d.t, PREFAB, d.state or "-", text))
end
-- (over one run of frames - all of what's drawn, or one of a kind's own)
local function GlitchOver(drawn_at)
-- (you put somewhere else by the testbench within the last 3 frames - over .5 in a frame, as no player moves: a shape
-- aimed after you then shrinking or going for a frame is the step, not the drawer - 66 of the Celestial Champion's
-- 67 sweep glitches, its aim taken a frame and a half back, 2026-10-25. As JUMP below. OLD_GLITCH_PUT=1: counted)
local function Put(i)
    if os.getenv("OLD_GLITCH_PUT") then return false end
    for k = math.max(2, i - 3), i do
        local p, q = drawn_at[k - 1], drawn_at[k]
        if p ~= nil and q ~= nil and p.px ~= nil and q.px ~= nil and (q.px - p.px) ^ 2 + (q.pz - p.pz) ^ 2 > .25 then return true end
    end
    return false
end
for i = 2, #drawn_at - 1 do
    local a, b = drawn_at[i - 1], drawn_at[i]
    if a.area > 0 and b.area == 0 and not Put(i) then
        for k = i + 1, math.min(i + 3, #drawn_at) do
            local c = drawn_at[k]
            if c.area > 0 then
                -- (one move's shape gone and back - not one move over, its strikes done, and the
                -- next begun a frame or two on: nothing to stand clear of between them)
                if b.pieces == 0 and a.state == c.state and not (a.state == b.state and b.state == drawn_at[i + 1].state and k == i + 1) then
                    Said("VANISH", b, string.format("nothing drawn for %d frame(s), from %s to %s", k - i, a.state or "-", c.state or "-"))
                end
                break
            end
            if c.pieces > 0 then break end
        end
    end
    -- (DROPPED: the boss no longer among those the mod draws for, its shape up - gone till it is)
    if a.area > 0 and b.area == 0 and (b.state or ""):find("(not picked)", 1, true) then
        Said("DROPPED", b, "the boss dropped out of what the mod draws for (too far off), its shape gone")
    end
    if a.area > 1 and b.area < .6 * a.area and b.area > 0 and not Put(i) then
        for k = i + 1, math.min(i + 3, #drawn_at) do
            local c = drawn_at[k]
            if c.area >= .8 * a.area then
                Said("SHRINK", b, string.format("%.1f of %.1f drawn for %d frame(s), from %s to %s", b.area, a.area, k - i, a.state or "-", c.state or "-"))
                break
            end
            if c.area < .6 * a.area and c.area > 0 then else break end
        end
    end
    if a.cx ~= nil and b.cx ~= nil and math.abs(b.area - a.area) < .3 * a.area and a.bx ~= nil and b.bx ~= nil then
        local moved = math.sqrt((b.cx - a.cx) ^ 2 + (b.cz - a.cz) ^ 2)
        local boss = math.sqrt((b.bx - a.bx) ^ 2 + (b.bz - a.bz) ^ 2)
        -- (or its middle gone round with the boss as it turned that frame - a long lane turning after you
        -- (the Celestial Champion's dash, 25 long: its middle 12 out, 3 a frame for 15 degrees): the shape
        -- as the game turns it, not a leap - phase4 1,013 -> 3. The miscfalse agent, 2026-10-19.
        -- OLD_JUMP_TURN=1: counted as a jump, as before)
        if moved > 1 and boss < .3 and a.brot ~= nil and b.brot ~= nil and not os.getenv("OLD_JUMP_TURN") then
            local dr = (b.brot - a.brot) * math.pi / 180
            local vx, vz = a.cx - a.bx, a.cz - a.bz
            local c, s = math.cos(dr), math.sin(dr)
            local rx, rz = b.bx + vx * c + vz * s, b.bz - vx * s + vz * c
            if math.abs(dr) > .01 and math.sqrt((b.cx - rx) ^ 2 + (b.cz - rz) ^ 2) < .5 * moved then moved = 0 end
        end
        -- (nor one after you, you put somewhere else that frame - the testbench's steps round it, 60 or 150 at
        -- once, a beam or a leap re-aimed after you: no player moves more than 0.2 a frame. 5,670 "jumps" on the
        -- 2026-10-20 bench, the Celestial Champion's beam 5 a frame with you. OLD_JUMP_YOU=1: as before)
        local you = (a.px ~= nil and b.px ~= nil) and math.sqrt((b.px - a.px) ^ 2 + (b.pz - a.pz) ^ 2) or 0
        -- (or put there up to 3 frames before - a player's game aims at you where the server had you a frame and a half
        -- back (true_range/predict TR_OLD_SERVERAIM): after you as you were put there, two frames on. OLD_JUMP_YOU3=1: that frame only)
        if not os.getenv("OLD_JUMP_YOU3") then
            for k = math.max(2, i - 3), i - 1 do
                local p, q = drawn_at[k - 1], drawn_at[k]
                if p.px ~= nil and q.px ~= nil then you = math.max(you, math.sqrt((q.px - p.px) ^ 2 + (q.pz - p.pz) ^ 2)) end
            end
        end
        if moved > 1 and boss < .3 and you > .5 and not os.getenv("OLD_JUMP_YOU") then moved = 0 end
        -- (nor a new go begun that frame - the old one's shape gone, the new one's drawn: the Ancient Guardian
        -- landing its leap and leaping again at once, its landing ring then its next leap's. OLD_JUMP_NEWGO=1: as before)
        if moved > 1 and (a.move ~= b.move or a.move_t0 ~= b.move_t0) and not os.getenv("OLD_JUMP_NEWGO") then moved = 0 end
        -- (nor its parts changed that frame - one part's turn over and the next's begun, as its data has it: the
        -- Boulder Crab's swing, its middle 1.12 on at its frame 30 every go, nothing moving. OLD_JUMP_STEP=1: as before)
        if moved > 1 and not os.getenv("OLD_JUMP_STEP") then
            local function Sig(d)
                local l = {}
                for _, r in ipairs(d.parts or {}) do for _, p in ipairs(r.todo or {}) do l[#l + 1] = tostring(p.map) end end
                table.sort(l)
                return table.concat(l, ",")
            end
            if Sig(a) ~= Sig(b) then moved = 0 end
        end
        if moved > 1 and boss < .3 then
            Said("JUMP", b, string.format("its middle went %.2f in a frame, the boss %.2f", moved, boss))
        end
    end
end
-- WOBBLE: the shape going back and forth frame after frame - 3 turnabouts of its middle within 10
-- frames (a spin over you, turned round to you and back each frame: its edge a blur)
do
    local turns, said_until = {}, -1
    for i = 3, #drawn_at do
        local a, b, c = drawn_at[i - 2], drawn_at[i - 1], drawn_at[i]
        if a.cx ~= nil and b.cx ~= nil and c.cx ~= nil then
            local d1x, d1z = b.cx - a.cx, b.cz - a.cz
            local d2x, d2z = c.cx - b.cx, c.cz - b.cz
            if d1x * d2x + d1z * d2z < 0 and d1x * d1x + d1z * d1z > .01 and d2x * d2x + d2z * d2z > .01 then
                turns[#turns + 1] = i
                local n = 0
                for _, j in ipairs(turns) do if i - j < 10 then n = n + 1 end end
                if n >= 3 and i > said_until then
                    Said("WOBBLE", c, "its shape went back and forth 3 times in 10 frames")
                    said_until = i + 30
                end
            end
        end
    end
end
end
-- (each of a kind on its own when several draw at once - a pack of guards taken as one shape, one's ending and the
-- next's starting read as a shrink or a jump: 593 on the beeguards, 2026-10-20. One at a time drawing: as before, all of
-- what's drawn - its own control. OLD_GLITCH_ONE=1: all as one)
do
    local many = false
    for _, d in ipairs(drawn_at) do
        local n = 0
        for _, w in pairs(d.own or {}) do if w.area > 0 then n = n + 1 end end
        if n > 1 then many = true break end
    end
    if many and not os.getenv("OLD_GLITCH_ONE") then
        local views, order = {}, {}
        for _, d in ipairs(drawn_at) do
            for b, w in pairs(d.own or {}) do
                if views[b] == nil then views[b] = {} order[#order + 1] = b end
                local ps = {}
                for _, r in ipairs(d.parts or {}) do if r.owner == b then ps[#ps + 1] = r end end
                local v = views[b]
                v[#v + 1] = { t = d.t, area = w.area, pieces = w.pieces, cx = w.cx, cz = w.cz, state = w.state, bx = w.bx, bz = w.bz,
                    brot = w.brot, move = w.move, move_t0 = w.move_t0, parts = ps, px = d.px, pz = d.pz }
            end
        end
        real_print(string.format("GLITCH_EACH %s: %d of them, each its own", PREFAB, #order))
        for _, b in ipairs(order) do GlitchOver(views[b]) end
    else
        GlitchOver(drawn_at)
    end
end
-- SLIDE: a move that strikes by what it puts down (entry.set_until - the Klaus deer's circles):
-- once all is put down, its shape going on with the boss as it moves - it should stay put
do
    local SimMoves = require("true_range/simmoves")
    local entries = {}
    for _, m in ipairs(SimMoves.Moves(PREFAB) or {}) do if m.name ~= nil then entries[m.name] = m.sim end end
    local i = 1
    while i <= #drawn_at do
        local d = drawn_at[i]
        local j = i
        while j + 1 <= #drawn_at and drawn_at[j + 1].move == d.move and drawn_at[j + 1].move_t0 == d.move_t0 and drawn_at[j + 1].t - drawn_at[j].t < 2.5 * FRAMES do j = j + 1 end
        local e = d.move ~= nil and entries[d.move] or nil
        if e ~= nil and e.set_until ~= nil then
            local from = nil
            for k = i, j do
                local f = drawn_at[k]
                if f.t - d.t > (e.set_until + 3) * FRAMES and f.cx ~= nil and f.bx ~= nil then
                    if from == nil or math.abs(f.area - from.area) > .1 * from.area then from = f
                    elseif math.sqrt((f.cx - from.cx) ^ 2 + (f.cz - from.cz) ^ 2) > .5
                        and math.sqrt((f.bx - from.bx) ^ 2 + (f.bz - from.bz) ^ 2) > .5 then
                        Said("SLIDE", f, string.format("its shape went %.2f with the boss after all was put down (it should stay)",
                            math.sqrt((f.cx - from.cx) ^ 2 + (f.cz - from.cz) ^ 2)))
                        break
                    end
                end
            end
        end
        i = j + 1
    end
end
-- OUTRAN: a move it goes on (a charge, a dash): it went further than anything drawn for it all
-- the move long - the shape too short (Retinazor, the Scion). OVERDRAWN: drawn well past where it
-- stopped - too long (Spazmatism). Neither needs you hit: you dodging it showed nothing before.
do
    local SM = require("true_range/simmoves")
    local function Covered(i, j, px, pz)
        for k = i, j do
            for _, r in ipairs(drawn_at[k].parts or {}) do
                for _, p in ipairs(r.todo) do
                    if p.map ~= nil and SM._InMap(p.map, r.x, r.z, r.rot, px, pz) then return true end
                end
            end
        end
        return false
    end
    local i = 1
    while i <= #drawn_at do
        local d = drawn_at[i]
        local j = i
        while j + 1 <= #drawn_at and drawn_at[j + 1].move == d.move and drawn_at[j + 1].move_t0 == d.move_t0 and drawn_at[j + 1].t - drawn_at[j].t < 2.5 * FRAMES and drawn_at[j + 1].bx ~= nil do j = j + 1 end
        if d.move ~= nil and d.bx ~= nil and j - i >= 8 then
            local a, b = drawn_at[i], drawn_at[j]
            -- (how far it really went: its furthest from where it began)
            local far, fk = 0, i
            for k = i, j do
                local f = drawn_at[k]
                local dd = math.sqrt((f.bx - a.bx) ^ 2 + (f.bz - a.bz) ^ 2)
                if dd > far then far, fk = dd, k end
            end
            -- (one that teleports - a shadow piece, gone and back in a frame: not on its way between)
            local tele = false
            for k = i + 1, j do
                local p, q = drawn_at[k - 1], drawn_at[k]
                if (q.bx - p.bx) ^ 2 + (q.bz - p.bz) ^ 2 > 4 then tele = true break end
            end
            if far >= 2 and not tele then
                local ux, uz = (drawn_at[fk].bx - a.bx) / far, (drawn_at[fk].bz - a.bz) / far
                -- (how far on its way the shape reached, at any moment of the move)
                local s, miss, last = 0, 0, nil
                while s < far + 30 and (last == nil or miss < 6) do
                    if Covered(i, j, a.bx + ux * s, a.bz + uz * s) then last, miss = s, 0 elseif last ~= nil then miss = miss + 1 end
                    s = s + .25
                end
                last = last or 0
                if far - last > 1 then
                    Said("OUTRAN", a, string.format("it went %.1f on its way; drawn only to %.1f", far, last))
                end
                -- (a charge: well past where it stopped, more than its own reach round itself - and
                -- only one seen to its end: the trace going on after it, not cut off mid-way, the boss
                -- gone out of range)
                local ended = drawn_at[j + 1] ~= nil and drawn_at[j + 1].t - drawn_at[j].t < 2.5 * FRAMES
                if far >= 6 and last - far > 6 and ended then
                    Said("OVERDRAWN", a, string.format("it went %.1f; drawn on to %.1f", far, last))
                end
                -- LATE: each spot it got to on its way - drawn how long before it got there? (the
                -- Scion's dash: the far half shown only as it arrived)
                local worst, wk = nil, nil
                -- (only where it gets to once it can strike - from its first strike's frame (its data's first): the
                -- Celestial Champion walks 8 into its roll harmless, its roll drawn from where it will set off - 547
                -- "late" on that walk, 2026-10-20. OLD_LATE_ALL=1: all its way)
                local from_t = nil
                if not os.getenv("OLD_LATE_ALL") and d.move_t0 ~= nil then
                    for _, m in ipairs(require("true_range/simmoves").Moves(PREFAB) or {}) do
                        if (m.name or (m.anims or {})[1]) == d.move and m.sim ~= nil and m.sim.first ~= nil then from_t = d.move_t0 + (m.sim.first - 1) * FRAMES end
                    end
                end
                for k = i, j do
                    local f = drawn_at[k]
                    local along = (f.bx - a.bx) * ux + (f.bz - a.bz) * uz
                    if along >= 2 and (from_t == nil or f.t >= from_t) then
                        local first = nil
                        for e = i, k do
                            if Covered(e, e, f.bx, f.bz) then first = e break end
                        end
                        -- (never drawn where it passes - a leap over it, harmless there: not this)
                        local lead = first and (f.t - drawn_at[first].t) or nil
                        if lead ~= nil and (worst == nil or lead < worst) then worst, wk = lead, k end
                    end
                end
                -- (a charge or a dash, a long way: a lunge of a step or two is drawn part by part as
                -- it swings, rightly)
                -- (9 frames is .3 - its sum a hair under, 0.2999: 83 "late" at 0.30s, 2026-10-20)
                if worst ~= nil and worst < .3 - 1e-3 and far >= 6 then
                    Said("LATE", drawn_at[wk], string.format("where it got to %.1f on its way was drawn only %.2fs before",
                        (drawn_at[wk].bx - a.bx) * ux + (drawn_at[wk].bz - a.bz) * uz, worst))
                end
            end
        end
        i = j + 1
    end
end
-- FOLLOWS: past the moment it stops aiming (entry.lock), its shape still going along with you -
-- the boss standing where it is, you walking: a disc drawn round you (the Eye's charge) and the like
do
    local SM = require("true_range/simmoves")
    local entries = {}
    for _, m in ipairs(SM.Moves(PREFAB) or {}) do if m.name ~= nil then entries[m.name] = m.sim end end
    -- (one told by its table (REDESIGN.md): it stops aiming at its deciding frame)
    local tok, Tables = pcall(require, "true_range/moves_table")
    local tabs = tok and type(Tables) == "table" and Tables[PREFAB] or {}
    local i = 1
    while i <= #drawn_at do
        local d = drawn_at[i]
        local j = i
        while j + 1 <= #drawn_at and drawn_at[j + 1].move == d.move and drawn_at[j + 1].move_t0 == d.move_t0 and drawn_at[j + 1].t - drawn_at[j].t < 2.5 * FRAMES do j = j + 1 end
        local e = d.move ~= nil and entries[d.move] or nil
        local lock = e ~= nil and e.lock or nil
        if d.move ~= nil and tabs[d.move] ~= nil then lock = tabs[d.move].decide end
        if e ~= nil and lock ~= nil and not e.random and e.around == nil and e.leg == nil then
            local run = 0
            for k = i + 1, j do
                local a, b = drawn_at[k - 1], drawn_at[k]
                if b.move_t0 ~= nil and b.t - b.move_t0 > (lock + 3) * FRAMES and a.move_t0 == b.move_t0 and a.cx and b.cx and a.bx and b.bx and a.px and b.px
                    and math.abs(b.area - a.area) < .05 * a.area then
                    local mx, mz = b.cx - a.cx, b.cz - a.cz
                    local yx, yz = b.px - a.px, b.pz - a.pz
                    local boss = math.sqrt((b.bx - a.bx) ^ 2 + (b.bz - a.bz) ^ 2)
                    local m, y = math.sqrt(mx * mx + mz * mz), math.sqrt(yx * yx + yz * yz)
                    if boss < .05 and m > .05 and y > .05 and (mx * yx + mz * yz) / (m * y) > .7 then run = run + 1 else run = 0 end
                    if run == 5 then
                        Said("FOLLOWS", b, string.format("its shape goes along with you after it stopped aiming (frame %d of the move, it stops at %d), the boss standing still", math.floor((b.t - (b.move_t0 or d.t)) / FRAMES + .5), lock))
                        break
                    end
                end
            end
        end
        i = j + 1
    end
end
-- AIMED: its shape going along with you while the boss itself stood still and faced the same way -
-- by the game's own trace, not the data's lock (a lock set too late is no FOLLOWS: Deerclops' swipe,
-- Moonmaw's, the Moose's hop - "it stopped aiming, it struck already, and the drawing still aims").
-- From then on to its strike, said once per move with how long and from which frame; a move aimed at
-- where you stand, not the way it faces (a thing called down on you), can be right to - looked at by hand
local aimed = {}
do
    local i = 1
    while i <= #drawn_at do
        local d = drawn_at[i]
        local j = i
        while j + 1 <= #drawn_at and drawn_at[j + 1].move == d.move and drawn_at[j + 1].move_t0 == d.move_t0 and drawn_at[j + 1].t - drawn_at[j].t < 2.5 * FRAMES do j = j + 1 end
        if d.move ~= nil then
            local run, from = 0, nil
            for k = i + 1, j do
                local a, b = drawn_at[k - 1], drawn_at[k]
                if a.cx and b.cx and a.bx and b.bx and a.px and b.px and a.brot and b.brot and math.abs(b.area - a.area) < .1 * a.area then
                    local turned = math.abs((b.brot - a.brot + 180) % 360 - 180)
                    local boss = math.sqrt((b.bx - a.bx) ^ 2 + (b.bz - a.bz) ^ 2)
                    local mx, mz = b.cx - a.cx, b.cz - a.cz
                    local yx, yz = b.px - a.px, b.pz - a.pz
                    local m, y = math.sqrt(mx * mx + mz * mz), math.sqrt(yx * yx + yz * yz)
                    if boss < .05 and turned < .5 and m > .03 and y > .05 and (mx * yx + mz * yz) / (m * y) > .5 then
                        run = run + 1
                        from = from or a
                    else
                        if run >= 5 then break end
                        run, from = 0, nil
                    end
                end
            end
            if run >= 5 and from ~= nil then
                local fr = math.floor((from.t - (from.move_t0 or d.t)) / FRAMES + .5)
                local key = d.move
                local w = aimed[key]
                if w == nil then w = { n = 0, frames = {}, t = from.t } aimed[key] = w end
                w.n = w.n + 1
                w.frames[#w.frames + 1] = fr
                if os.getenv("AIM_V") then Said("AIMED", from, string.format("its shape went along with you %d frames from frame %d, the boss not moving or turning", run, fr)) end
            end
        end
        i = j + 1
    end
    for mv, w in pairs(aimed) do
        table.sort(w.frames)
        real_print(string.format("AIMED   %s %s: %d time(s) drawn following you, the boss still and not turning - from frame %s (first at %.3f)",
            PREFAB, mv, w.n, table.concat(w.frames, ","), w.t))
    end
end
-- OUTSIDE: what it threw or put down (the Scrappy Werepig's junk, a deer's circles - the things'
-- own trace, [tr_haz]) came down where nothing of its move was drawn, any moment from a while
-- before it appeared until it came down
do
    local SM = require("true_range/simmoves")
    local things = {}
    for t, prefab, guid, x, z in HazLines() do
        if t ~= nil then
            local th = things[guid]
            if th == nil then th = { prefab = prefab, t0 = tonumber(t) } things[guid] = th end
            th.t1, th.x, th.z = tonumber(t), tonumber(x), tonumber(z)
        end
    end
    local said = 0
    for _, th in pairs(things) do
        -- (only one of its own: appearing as it was at a move, near it)
        -- (set off by this boss, as the offline runs found - not the deer's circles near Klaus)
        -- (told first: another's thing needs none of the frames gone through - every thing against every
        -- frame was a third of a replay's time; VERIFY_PLAN 6.15)
        local hb = SM.Hazards()[th.prefab] ~= nil and SM.Hazards()[th.prefab].by or nil
        local mine = false
        for _, b in ipairs(hb or {}) do if b == PREFAB then mine = true end end
        -- (the frames from 3s before it appeared until it came down, with this boss's move drawn - from
        -- the first such, found by halves: drawn_at goes by time)
        local frames, near = {}, false
        if mine then
            local lo, hi = 1, #drawn_at + 1
            while lo < hi do
                local mid = math.floor((lo + hi) / 2)
                if drawn_at[mid].t < th.t0 - 3 then lo = mid + 1 else hi = mid end
            end
            for k = lo, #drawn_at do
                local d = drawn_at[k]
                if d.t > th.t1 then break end
                if d.move ~= nil and d.parts ~= nil and #d.parts > 0 then
                    frames[#frames + 1] = k
                    if d.bx ~= nil and (d.bx - th.x) ^ 2 + (d.bz - th.z) ^ 2 < 20 * 20 then near = true end
                end
            end
        end
        -- (nor one of a boss whose move is all things put down at random (sim.things_only - the
        -- Celestial Champion's crystals): no area of the move drawn, by design; each drawn itself)
        local own_drawn = false
        -- (or one no move of it puts down at all, drawn on its own - the crystals once their move became where they may
        -- come down (spec spot, no puts): taken for the beam's after it, 56 "OUTSIDE", 2026-10-20. OLD_OUTSIDE_PUTS=1: not)
        do
            local hz = SM.Hazards()[th.prefab]
            local put_by_a_move = false
            for _, m in ipairs(SM.Moves(PREFAB) or {}) do
                for _, p in ipairs(m.sim and m.sim.puts or {}) do if p == th.prefab then put_by_a_move = true end end
            end
            if hz ~= nil and not hz.in_move and not put_by_a_move and not os.getenv("OLD_OUTSIDE_PUTS") then own_drawn = true end
        end
        for _, m in ipairs(SM.Moves(PREFAB) or {}) do
            -- (only what that move puts down, or what that leaves lying there striking on - the crystal
            -- after its projectile; each crystal itself still judged, tests/replay_haz.lua)
            local hz = SM.Hazards()[th.prefab]
            if m.sim ~= nil and m.sim.things_only and hz ~= nil and not hz.in_move then
                for _, p in ipairs(m.sim.puts or {}) do if p == th.prefab then own_drawn = true end end
                if hz.lasting then own_drawn = true end
            end
        end
        if near and mine and not own_drawn and #frames > 0 and SM.Hazards()[th.prefab] ~= nil and not SM.Hazards()[th.prefab].burst
            and not SM.Hazards()[th.prefab].flies and not SM.Hazards()[th.prefab].moved
            -- (one carried off as it comes down - junk: it goes on after you after it's thrown; drawn
            -- itself as it falls, judged so - tests/replay_haz.lua)
            and SM.Hazards()[th.prefab].glide == nil
            -- (nor one of a go that took where you were as the testbench put you somewhere else (as AIMJUMP strikes): the
            -- Celestial Champion's sweep lasers, 36, 2026-10-25. OLD_OUTSIDE_AIMJUMP=1: counted)
            and (os.getenv("OLD_OUTSIDE_AIMJUMP") or not (AimJumped({ t = th.t0 }) or (function()
                for _, at in ipairs(AIMJUMP_T) do if math.abs(at - th.t0) < 1.5 then return true end end
                return false
            end)())) then
            local covered = false
            for _, k in ipairs(frames) do
                for _, r in ipairs(drawn_at[k].parts) do
                    for _, p in ipairs(r.todo) do
                        if p.map ~= nil and SM._InMap(p.map, r.x, r.z, r.rot, th.x, th.z) then covered = true break end
                    end
                    if covered then break end
                end
                if covered then break end
            end
            if not covered and said < 20 then
                said = said + 1
                Said("OUTSIDE", drawn_at[frames[#frames]], string.format("%s came down at %.1f,%.1f - nothing of its move drawn there", th.prefab, th.x, th.z))
            end
        end
    end
end
-- ACCURACY (VERIFY_PLAN, 2026-10-26): what strikes the moment it's made, its own hit circle (its radius from its prefab,
-- not from the data being tested, + your body .5) against the parts drawn striking (hit / strike) at that very frame,
-- +-1 frame: how much of the circle they hold, and whether they hold more of one side than the other along its way out
-- from the boss - a shape turned or moved off, still covering its middle (the Celestial Champion's side beams turned in
-- 3 degrees - OUTSIDE, any frame any part its middle only, found nothing). One line a boss/thing; ACC_OFF a go off.
-- NOACCURACY=1: none
if not os.getenv("NOACCURACY") then
    -- (r: how far from it your middle is struck, from its prefab; from/to: frames after it's first seen that it may strike -
    -- the best of them taken, its timing not known to the trace: a place check there, not a timing one)
    -- (alterguardian_laser.lua:24 RADIUS .7, :101 + the struck one's body (.5 for you); phase 3's beam no hitscale - at once)
    -- (sand_spike.lua:20-26 RADIUS + :28 padding .5, FindEntities on your middle; struck 2 frames after its rising anim)
    -- (fossil_spike(2).lua:13-14 .2 + .5; risen after the delay its maker hands it)
    -- (deerclops_laser.lua:24 RADIUS .7 + body, as the Champion's ; SGdeerclops SpawnLaser: all made at once, each striking
    -- max(0, i - 1) frames after, i its step out (dist = i * .75 + 1.25) - when: its own frame, from how far out it is)
    local ACC_THINGS = {
        alterguardian_laser = { r = .7 + .5, from = -1.5, to = 1.5 },
        -- (SGdeerclops (and UM's) DoIceSpikeAOE ICESPIKE_RADIUS 1 + your body ; each strikes 3 frames after the attack
        -- starts or as it rises, which is later - up to 3 frames after it's first seen)
        deerclops_icespike_fx = { r = 1 + .5, from = -1.5, to = 4.5 },
        -- (moonspider_spike.lua:17 ATTACK_RADIUS .5 + body ; :132 striking random 0-.25 s after it's made)
        moonspider_spike = { r = .5 + .5, from = -1.5, to = 9.5 },
        -- (Uncompromising Mode's spider's own, the same: scripts/prefabs/minimoonspider_spike.lua:17, :129)
        minimoonspider_spike = { r = .5 + .5, from = -1.5, to = 9.5 },
        -- (bishop_charge.lua:157 RADIUS 2.5 - .5, + your body ; :159 striking its first 18 frames)
        bishop_charge2_fx = { r = 2 + .5, from = -1.5, to = 18.5 },
        deerclops_laser = { r = .7 + .5, from = -1.5, to = 13.5,
            when = function(dist) return math.max(0, math.floor((dist - 1.25) / .75 + .5) - 1) end },
        -- (place only: when they strike isn't in the trace - a fossil spike rises after the delay it's handed, up to
        -- seconds (in 60 frames 7% of them drawn striking, in 150 21%): whether it's drawn there at all, and its lean)
        sandspike_short = { r = .2 + .5, from = 0, to = 30, place = true },
        sandspike_med = { r = .4 + .5, from = 0, to = 30, place = true },
        sandspike_tall = { r = .6 + .5, from = 0, to = 30, place = true },
        fossilspike = { r = .2 + .5, from = 0, to = 150, place = true },
        fossilspike2 = { r = .2 + .5, from = 0, to = 150, place = true },
    }
    local ACC_RADIUS = {}
    for k, v in pairs(ACC_THINGS) do ACC_RADIUS[k] = v.r end
    local SM = require("true_range/simmoves")
    -- (one a guid - and a new one where it's seen somewhere else, or after a while unseen: pooled things, Deerclops'
    -- spikes taken back and set down again)
    local things, last = {}, {}
    for t, prefab, guid, x, z in HazLines() do
        if t ~= nil and ACC_RADIUS[prefab] ~= nil then
            t, x, z = tonumber(t), tonumber(x), tonumber(z)
            local th = last[guid]
            if th == nil or math.abs(th.x - x) + math.abs(th.z - z) > .05 or t - th.seen > .5 then
                th = { prefab = prefab, t0 = t, x = x, z = z }
                last[guid] = th
                things[#things + 1] = th
            end
            th.seen = t
        end
    end
    -- (red: its parts striking; any: all it draws then - the lean is the shape's, not its colours': a sweep's front, the
    -- next part yellow one side only, read as leaning, the Champion's attk_swipe, 2026-10-26)
    local function Red(d, px, pz, any)
        for _, r in ipairs(d.parts or {}) do
            for _, p in ipairs(r.todo or {}) do
                if p.map ~= nil and (any or p.style == "hit" or p.style == "strike") and SM._InMap(p.map, r.x, r.z, r.rot, px, pz) then return true end
            end
        end
        return false
    end
    local stats = {}
    local gos = {}
    for _, th in pairs(things) do
        local hb = SM.Hazards()[th.prefab] ~= nil and SM.Hazards()[th.prefab].by or nil
        local mine = false
        for _, b in ipairs(hb or {}) do if b == PREFAB then mine = true end end
        local jumped = AimJumped({ t = th.t0 })
        for _, at in ipairs(AIMJUMP_T or {}) do if math.abs(at - th.t0) < 1.5 then jumped = true end end
        if mine and not jumped and th.t0 >= math.max(t0, COUNT_FROM) and th.t0 <= t1 then
            -- (the frames round its first: the one holding most of it)
            local win = ACC_THINGS[th.prefab]
            local lo, hi = 1, #drawn_at + 1
            while lo < hi do
                local mid = math.floor((lo + hi) / 2)
                if drawn_at[mid].t < th.t0 + win.from * FRAMES then lo = mid + 1 else hi = mid end
            end
            local R = ACC_RADIUS[th.prefab]
            local best = nil
            for k = lo, #drawn_at do
                local d = drawn_at[k]
                if d.t > th.t0 + win.to * FRAMES then break end
                if d.bx ~= nil then
                    -- (out from the boss through it: along, and the side square to that)
                    local ux, uz = th.x - d.bx, th.z - d.bz
                    local ul = math.sqrt(ux * ux + uz * uz)
                    if ul > .01 then ux, uz = ux / ul, uz / ul else ux, uz = 1, 0 end
                    local sx, sz = -uz, ux
                    if win.when ~= nil and math.abs(d.t - (th.t0 + win.when(ul) * FRAMES)) > 1.5 * FRAMES then ux = nil end
                    if ux ~= nil then
                    local n, inn, anyn = 0, 0, 0
                    -- (the outer ring a cell (.25) inside its edge: on the edge itself a shape of .25 cells is in or out
                    -- by chance - the Bishop's charge, drawn 2.78 round for its 2.5, read 13 of 21, 2026-10-26.
                    -- OLD_ACC_EDGE=1: on the edge)
                    local outer = os.getenv("OLD_ACC_EDGE") and 1 or math.max(.5, (R - .25) / R)
                    for _, ring in ipairs({ { 0, 1 }, { .5, 8 }, { outer, 12 } }) do
                        for i = 0, ring[2] - 1 do
                            local a = i * 2 * math.pi / ring[2]
                            local qx, qz = th.x + R * ring[1] * math.cos(a), th.z + R * ring[1] * math.sin(a)
                            n = n + 1
                            if Red(d, qx, qz) then inn = inn + 1 end
                            if Red(d, qx, qz, true) then anyn = anyn + 1 end
                        end
                    end
                    local left, right = 0, 0
                    -- (inside the edge: a shape off by under ~.3 - a cell, a frame's lead - not taken for leaning)
                    for _, f in ipairs({ .4, .75 }) do
                        for _, g in ipairs({ -.5, 0, .5 }) do
                            if Red(d, th.x + sx * R * f + ux * R * g, th.z + sz * R * f + uz * R * g, true) then left = left + 1 end
                            if Red(d, th.x - sx * R * f + ux * R * g, th.z - sz * R * f + uz * R * g, true) then right = right + 1 end
                        end
                    end
                    local better = best == nil
                    if not better and win.place then better = anyn > best.anyn
                    elseif not better then better = inn > best.inn or (inn == best.inn and anyn > best.anyn) end
                    if better then
                        best = { inn = inn, anyn = anyn, n = n, asym = (left - right) / 6, move = d.move, move_t0 = d.move_t0, t = d.t,
                            bearing = math.floor(math.atan2(-(th.z - d.bz), th.x - d.bx) / DEGREES / 10 + .5) * 10 }
                    end
                    end
                end
            end
            if best ~= nil then
                local key = th.prefab
                local s = stats[key]
                if s == nil then s = { n = 0, cover = 0, low = 0, any = 0 } stats[key] = s end
                local c = best.inn / best.n
                -- (ACC_V=1: each one measured)
                if os.getenv("ACC_V") then real_print(string.format("ACC_V %.3f %s at %.2f,%.2f: %d/%d striking, %d drawn, lean %.2f (%s, frame %.3f)",
                    th.t0, key, th.x, th.z, best.inn, best.n, best.anyn, best.asym, tostring(best.move), best.t)) end
                s.n, s.cover, s.any = s.n + 1, s.cover + c, s.any + best.anyn / best.n
                if c < .5 then s.low = s.low + 1 end
                -- (by go and by the way out it goes - one beam of several: its own side, not the others')
                local gk = string.format("%s|%s|%.3f|%d", key, tostring(best.move), best.move_t0 or 0, best.bearing)
                local g = gos[gk]
                if g == nil then g = { key = key, move = best.move, t = th.t0, bearing = best.bearing, n = 0, asym = 0, cover = 0 } gos[gk] = g end
                g.n, g.asym, g.cover = g.n + 1, g.asym + best.asym, g.cover + c
            end
        end
    end
    local worst = {}
    for _, g in pairs(gos) do
        if g.n >= 3 then
            local a = g.asym / g.n
            local w = worst[g.key]
            if w == nil or math.abs(a) > math.abs(w) then worst[g.key] = a end
            if math.abs(a) >= .3 then
                real_print(string.format("ACC_OFF %.3f %s %s (%s, out at %d deg): one side held %.0f%% more - turned or moved off, %d of it, %.0f%% held",
                    g.t, PREFAB, g.key, tostring(g.move), g.bearing, math.abs(a) * 100, g.n, g.cover / g.n * 100))
            end
        end
    end
    for key, s in pairs(stats) do
        if ACC_THINGS[key].place then
            real_print(string.format("ACCURACY %s %s (place only): %d measured, %.0f%% of their hit circles drawn there, worst side lean %.0f%%",
                PREFAB, key, s.n, s.any / s.n * 100, math.abs(worst[key] or 0) * 100))
        else
            real_print(string.format("ACCURACY %s %s: %d measured, %.0f%% of their hit circles drawn striking (%.0f%% drawn at all), %d under half, worst side lean %.0f%%",
                PREFAB, key, s.n, s.cover / s.n * 100, s.any / s.n * 100, s.low, math.abs(worst[key] or 0) * 100))
        end
    end
end
-- (DUMP=t0,t1: each frame drawn between, its middle and the boss's - to look at one closely)
if os.getenv("DUMP") ~= nil then
    local d0, d1 = os.getenv("DUMP"):match("([%d%.]+),([%d%.]+)")
    for _, d in ipairs(drawn_at) do
        if d.t >= tonumber(d0) and d.t <= tonumber(d1) then
            real_print(string.format("DUMP %.3f %-20s move %s far %s area %6.1f mid %s boss %s you %s", d.t, d.state or "-", tostring(d.move), d.far and string.format("%.2f", d.far) or "-", d.area or 0,
                d.cx and string.format("%.2f,%.2f", d.cx, d.cz) or "-", d.bx and string.format("%.2f,%.2f", d.bx, d.bz) or "-",
                d.px and string.format("%.2f,%.2f", d.px, d.pz) or "-") .. (d.parts and d.parts[1] and string.format(" from %.2f,%.2f rot %.1f", d.parts[1].x, d.parts[1].z, d.parts[1].rot / (math.pi / 180)) or ""))
        end
    end
end
real_print(string.format("%s: %d glitches", PREFAB, glitches))
-- (frames two shapes of it were drawn at once - one a moment, the other its lookalike: told apart too late)
for k, n in pairs(rawget(_G, "TR_BOTH") or {}) do real_print(string.format("BOTHDRAWN %s: %d frames", k, n)) end
-- (goes drawn as one move, then taken for another - the wrong one flashed first: Retinazor's charge as it
-- began its laser, the player's report 2026-10-18)
for k, n in pairs(rawget(_G, "TR_FLIP") or {}) do real_print(string.format("FLIPDRAWN %s: %d goes", k, n)) end
-- (its things drawn leaping further in a moment than they went - those drawn with its moves (in_move):
-- the Eye's mini eyes, the player's report 2026-10-18; replay_haz.lua counts the rest)
for k, n in pairs(rawget(_G, "TR_JUMP") or {}) do real_print(string.format("JUMPDRAWN %s: %d frames", k, n)) end
for k, n in pairs(rawget(_G, "TR_GAP") or {}) do real_print(string.format("GAPDRAWN %s: %d times", k, n)) end
-- (shapes cut on the cells' own edges - smoothing folded them: stairs in the game)
-- (only asked for: CUT_COUNT=1 - "eyeofterror" in it read as an error by tools/verify.ps1)
if os.getenv("CUT_COUNT") then real_print(string.format("%s: %d pieces cut on cell edges", PREFAB, require("true_range/simmoves").fallbacks or 0)) end
for _, s in ipairs(by_thing) do
    real_print(string.format("BYTHING %.3f %s %s: struck by a thing it set off, %.2f from it", s.t, PREFAB, s.state or "?",
        math.sqrt((s.x - s.bx) ^ 2 + (s.z - s.bz) ^ 2)))
end
if #by_thing > 0 then real_print(string.format("%s: %d hits by things it set off (not its moves')", PREFAB, #by_thing)) end
if #shot_strikes > 0 then
    local n, by = 0, {}
    for _, s in ipairs(shot_strikes) do
        if s.t >= COUNT_FROM then n = n + 1 by[s.by] = (by[s.by] or 0) + 1 end
    end
    local l = {}
    for b, c in pairs(by) do l[#l + 1] = b .. " " .. c end
    table.sort(l)
    real_print(string.format("%s: %d struck by what it shot (%s) - not judged here: modmain's DARTS, not drawn by the replay", PREFAB, n, table.concat(l, ", ")))
end
-- (STYLES=<move>: how that move was drawn, frame by frame - each style's frames: the Celestial Champion's crystals' area
-- drawn dark red where it should only warn, the player's report 2026-10-20)
if os.getenv("STYLES") then
    local n = {}
    for _, d in ipairs(drawn_at) do
        if d.move == os.getenv("STYLES") then
            for _, r in ipairs(d.parts or {}) do
                for _, p in ipairs(r.todo or {}) do local s = tostring(p.style) n[s] = (n[s] or 0) + 1 end
            end
        end
    end
    local l = {}
    for s, c in pairs(n) do l[#l + 1] = s .. "=" .. c end
    table.sort(l)
    real_print(string.format("STYLES %s %s: %s", PREFAB, os.getenv("STYLES"), table.concat(l, " ")))
end
-- (each go of a move it was seen in, with nothing at all drawn of it any frame - no warning came up: the
-- player's "Deerclops' area sometimes not shown", 2026-10-20 - a go striking nobody passed every other check)
do
    local goes, order = {}, {}
    for _, d in ipairs(drawn_at) do
        if d.move ~= nil and d.move_t0 ~= nil and d.t >= COUNT_FROM then
            local k = d.move .. "@" .. string.format("%.3f", d.move_t0)
            local g = goes[k]
            if g == nil then g = { move = d.move, t = d.t, n = 0, drawn = 0, state = d.state } goes[k] = g order[#order + 1] = k end
            g.n = g.n + 1
            if (d.pieces or 0) > 0 then g.drawn = g.drawn + 1 end
        end
    end
    local empty = 0
    for _, k in ipairs(order) do
        local g = goes[k]
        if g.drawn == 0 and g.n >= 3 then
            empty = empty + 1
            real_print(string.format("GOEMPTY %.3f %s %s (%s): nothing drawn all its go, %d frames", g.t, PREFAB, g.move, tostring(g.state), g.n))
        end
    end
    if #order > 0 then real_print(string.format("GOEMPTIES %s: %d of %d goes drew nothing", PREFAB, empty, #order)) end
end
if aimjump > 0 then real_print(string.format("AIMJUMPS %s: %d struck as you went over 1 in a tick as it aimed - not counted", PREFAB, aimjump)) end
do
    local lim = tonumber(os.getenv("BIGDARK_MIN") or "") or 250
    for _, b in ipairs(big_dark) do
        if b.max >= lim then real_print(string.format("BIGDARK %.3f %s %s: %.0f square units drawn dark at once (a ring %.1f round)", b.t, PREFAB, b.move, b.max, math.sqrt(b.max / math.pi))) end
    end
end
-- (WENT: each leap set as it stops aiming - how far it really went against its run offline, after a target or not:
-- true_range/simmoves WentSeen; tools/went_table.ps1 puts every boss's together)
for _, w in ipairs(TR_WENTLOG) do
    real_print(string.format("WENT %s %s %s offline=%.2f real=%.2f its target %.2f off", w[1], w[2], w[3] and "target" or "notarget", w[4], w[5], w[6] or -1))
end
if (rawget(_G, "WORN_N") or 0) > 0 then real_print(string.format("%s: %d strikes worn on you (not counted)", PREFAB, rawget(_G, "WORN_N"))) end
real_print(string.format("%s: %d strikes - %d drawn, %d missed; %d drawn-in with no strike; %d unchecked; %d short; %d idle-drawn", PREFAB, ok + missed + unchecked, ok, missed, false_alarm, unchecked, short, idle_draws))
if SC ~= nil then SC.Report() end

-- (REAL_LINES: and what was told the game - pieces laid, calls made, groups laid anew - the game's own cost)
if os.getenv("DRAW_TIME") and REAL then
    local RL_ = require("true_range/lines")
    real_print(string.format("LAID %d frames: %.0f pieces laid, %.0f calls, %.1f groups laid anew a frame", draw_cost[3],
        (RL_.laid or 0) / math.max(1, draw_cost[3]), (RL_.calls or 0) / math.max(1, draw_cost[3]), (RL_.group_builds or 0) / math.max(1, draw_cost[3])))
end
if os.getenv("DRAW_TIME") then real_print(string.format("DRAW_TIME %d frames: %.2f ms a frame, %.0f KB a frame made", draw_cost[3], draw_cost[1] * 1000 / math.max(1, draw_cost[3]), draw_cost[2] / math.max(1, draw_cost[3]))) end
if os.getenv("DRAW_TIME") and rawget(_G, "slow_draws") then table.sort(slow_draws, function(a, b) return a[1] > b[1] end) for i = 1, math.min(10, #slow_draws) do io.stdout:write(string.format("SLOW %.1f ms at t=%.3f, %d pieces\n", slow_draws[i][1] * 1000, slow_draws[i][2], slow_draws[i][3])) end end
if rawget(_G, "fn_lines") then local l = {} for k, v in pairs(fn_lines) do l[#l + 1] = { k, v } end table.sort(l, function(a, b) return a[2] > b[2] end) for i = 1, math.min(25, #l) do io.stdout:write(string.format("FN %-40s %d\n", l[i][1], l[i][2])) end end
-- (LEAP_STAT=1: each go of a move that sets where it strikes as it stops aiming (anchor "lock") -
-- how far its shape's middle jumped the frame it stopped aiming, and after: how far it went in
-- all, how often it turned back, how far it ever was from where it ended - all of it should be 0:
-- set, it doesn't move)
if os.getenv("LEAP_STAT") then
    local lock_of = {}
    for _, m in ipairs(SimMoves.Moves(PREFAB)) do
        if m.sim ~= nil and m.sim.anchor == "lock" and m.sim.lock ~= nil then lock_of[m.name or m.anims[1]] = m.sim.lock end
    end
    local goes, n, sum_lj, sum_tr, sum_rev, worst, sum_fj, sum_fb = {}, 0, 0, 0, 0, 0, 0, 0
    local cur = nil
    local function Close()
        if cur ~= nil and #cur.after > 1 then
            local tr, rev, far = 0, 0, 0
            local last = cur.after[#cur.after]
            local pdx, pdz = nil, nil
            for i = 2, #cur.after do
                local a, b = cur.after[i - 1], cur.after[i]
                local dx, dz = b[1] - a[1], b[2] - a[2]
                local d = math.sqrt(dx * dx + dz * dz)
                tr = tr + d
                if d > .05 then
                    if pdx ~= nil and dx * pdx + dz * pdz < 0 then rev = rev + 1 end
                    pdx, pdz = dx, dz
                end
            end
            for _, a in ipairs(cur.after) do far = math.max(far, math.sqrt((a[1] - last[1]) ^ 2 + (a[2] - last[2]) ^ 2)) end
            -- (its far edge: how far it pulled back at its lock, and back in all after)
            local fb = 0
            for i = 2, #cur.fars do if cur.fars[i] < cur.fars[i - 1] - .05 then fb = fb + cur.fars[i - 1] - cur.fars[i] end end
            n, sum_lj, sum_tr, sum_rev = n + 1, sum_lj + cur.lj, sum_tr + tr, sum_rev + rev
            sum_fj, sum_fb = sum_fj + math.max(0, -(cur.fj or 0)), sum_fb + fb
            worst = math.max(worst, tr)
            if os.getenv("LEAP_STAT") == "v" then
                real_print(string.format("LEAP %.3f %s: at its lock the middle jumped %.2f, its far edge %+.2f; after: went %.2f in all, turned back %d, farthest %.2f from where it ended; far edge back %.2f in all",
                    cur.t0, cur.move, cur.lj, cur.fj or 0, tr, rev, far, fb))
            end
        end
        cur = nil
    end
    local prev_d = nil
    for _, d in ipairs(drawn_at) do
        local lock = d.move ~= nil and lock_of[d.move] or nil
        if lock == nil or d.cx == nil or (cur ~= nil and (cur.move ~= d.move or cur.t0 ~= d.move_t0)) then Close() end
        if lock ~= nil and d.cx ~= nil and d.move_t0 ~= nil then
            if cur == nil then cur = { move = d.move, t0 = d.move_t0, after = {}, lj = 0, fars = {} } end
            if d.t - d.move_t0 >= lock * FRAMES - 1e-6 then
                if #cur.after == 0 and prev_d ~= nil and prev_d.cx ~= nil and prev_d.move == d.move then
                    cur.lj = math.sqrt((d.cx - prev_d.cx) ^ 2 + (d.cz - prev_d.cz) ^ 2)
                    if d.far ~= nil and prev_d.far ~= nil then cur.fj = d.far - prev_d.far end
                end
                if d.far ~= nil then cur.fars[#cur.fars + 1] = d.far end
                cur.after[#cur.after + 1] = { d.cx, d.cz }
            end
        end
        prev_d = d
    end
    Close()
    real_print(string.format("LEAP_STAT %s: %d goes - jump at its lock %.2f, after it went %.2f in all, turned back %.1f times (each on average); worst %.2f; far edge pulled back at its lock %.3f, back after %.3f",
        PREFAB, n, sum_lj / math.max(1, n), sum_tr / math.max(1, n), sum_rev / math.max(1, n), worst, sum_fj / math.max(1, n), sum_fb / math.max(1, n)))
end
