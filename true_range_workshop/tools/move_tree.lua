-- luajit tools/move_tree.lua <client_log> <server_log> [prefab]
-- Each boss's moves as a tree - state, then the animations within it - from a lag bench run (or any run with both sides'
-- testing lines): what the server did (frames, blows, how far) against what the player's game drew in that same stretch
-- (frames drawn, how big, how long each showing lasted), with what's odd in it flagged. The player, 2026-10-29: the same
-- bosses fixed for days, one stretch at a time as each was found - "a tree of the moves, to pick out anomalies".
-- Flags:
--   FLASH n      a shape bigger than both sides for 1-2 frames, n times (a frame drawn between two ways of drawing it)
--   NOT n        struck there, nothing drawn under you, n times
-- (and "no blow after p%": its frames drawn with no blow of the boss's own in the 2 s after - told only; TREE_FLAGGED=1: the
-- flagged stretches alone; TREE_LAG: the player's game's lag behind the server, .1)
-- (no "too big" flag: the testbench keeps you close, its blows' distances aren't the move's reach)
local cpath, spath, only = arg[1], arg[2], arg[3]
assert(cpath and spath, "usage: luajit tools/move_tree.lua <client_log> <server_log> [prefab]")

-- (1) the server: each boss's frames (state, animation) and blows
local frames = {}   -- prefab -> list of { t, state, anim, x, z }
local blows = {}    -- prefab -> list of { t, state, anim, d, by }
for line in io.lines(spath) do
    local t, pf, rest = line:match("%[tr_trace%] ([%d%.]+) ([%w_]+) (.*)")
    if t ~= nil and (only == nil or pf == only) then
        t = tonumber(t)
        local state, anim = rest:match("state=([%w_]+)"), rest:match("anim=([%w_]+)")
        if rest:match("^after ") then
            local x, z = rest:match("pos=([%d%.%-]+),([%d%.%-]+)")
            frames[pf] = frames[pf] or {}
            table.insert(frames[pf], { t = t, state = state, anim = anim, x = tonumber(x), z = tonumber(z) })
        elseif rest:match("^STRIKE ") then
            blows[pf] = blows[pf] or {}
            table.insert(blows[pf], { t = t, state = state, anim = anim, d = tonumber(rest:match(" d=([%d%.]+)")),
                by = rest:match("^STRIKE by ([%w_]+)") })
        end
    end
end

-- (2) the player's game: its clock against the server's ([tr_lag] you ... srv_t=), what it drew each frame, blows not drawn
local offs = {}     -- { client t, server t - client t }
local drawn = {}    -- prefab -> list of { t (server), r (reach round its middle), cx, cz }
local notd = {}     -- list of { t (server), prefab, from }
local last_ct = nil
local function Off(ct)
    -- (the nearest told before it)
    local lo, hi = 1, #offs
    if hi == 0 then return 0 end
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if offs[mid][1] <= ct then lo = mid else hi = mid - 1 end
    end
    return offs[lo][2]
end
local raw = {}
for line in io.lines(cpath) do
    local ct, st = line:match("%[tr_lag%] ([%d%.]+) you .-srv_t=([%d%.]+)")
    if ct ~= nil then
        ct, st = tonumber(ct), tonumber(st)
        offs[#offs + 1] = { ct, st - ct }
        last_ct = ct
    end
    local t, pf, guid, rest = line:match("%[tr_lagframe%] ([%d%.]+) ([%w_%?]+) (%d+) (.*)")
    if t ~= nil and (only == nil or pf == only) then
        t = tonumber(t)
        last_ct = t
        local tri, area, tx, tz = rest:match("tri=(%d+) area=([%d%.]+) at=([%d%.%-]+),([%d%.%-]+)")
        local grp, gx, gz = rest:match("grp=(%d+) at=([%d%.%-]+),([%d%.%-]+)")
        local ext = tonumber(rest:match("ext=([%d%.]+)")) or 0
        local r, cx, cz = nil, nil, nil
        if tonumber(grp) > 0 then r, cx, cz = ext / 2, tonumber(gx), tonumber(gz)
        elseif tonumber(tri) > 0 then r, cx, cz = math.sqrt(tonumber(area) / math.pi), tonumber(tx), tonumber(tz) end
        raw[#raw + 1] = { ct = t, pf = pf .. "#" .. guid, r = r, cx = cx, cz = cz }
    end
    local by, from, d = line:match("%[true_range%] you were struck.- by ([%w_]+), ([%d%.]+) from it %- drawn: (%a+)")
    if by ~= nil and d ~= "in" and last_ct ~= nil then notd[#notd + 1] = { ct = last_ct, prefab = by, from = tonumber(from) } end
end
-- (the boss as the player's game shows it: ENT_LAG behind the server's clock it hears - 3 frames; a drawing taken for
-- the next state's as its move ended (Umbral's punch "drawn in punch_pst", its first 3 frames only). TREE_LAG=0: none)
local LAG = tonumber(os.getenv("TREE_LAG") or "") or .1
for _, f in ipairs(raw) do
    drawn[f.pf] = drawn[f.pf] or {}
    table.insert(drawn[f.pf], { t = f.ct + Off(f.ct) - LAG, r = f.r, cx = f.cx, cz = f.cz })
end
for _, n in ipairs(notd) do n.t = n.ct + Off(n.ct) - LAG end

-- (3) each server time to the stretch it falls in
local function PhaseAt(list, t)
    if list == nil or #list == 0 then return nil end
    local lo, hi = 1, #list
    if t < list[1].t then return nil end
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        if list[mid].t <= t then lo = mid else hi = mid - 1 end
    end
    if t - list[lo].t > .2 then return nil end
    return list[lo]
end

local tree = {}     -- prefab -> state -> anim -> stats
local function Node(pf, st, an)
    tree[pf] = tree[pf] or {}
    tree[pf][st] = tree[pf][st] or { anims = {}, blows = 0 }
    local a = tree[pf][st].anims[an]
    if a == nil then
        a = { frames = 0, blows = 0, dmax = 0, drawn = 0, rs = {}, flashes = 0, notd = 0, order = 0 }
        tree[pf][st].anims[an] = a
    end
    return a
end
for pf, list in pairs(frames) do
    for i, f in ipairs(list) do
        local a = Node(pf, f.state or "?", f.anim or "?")
        a.frames = a.frames + 1
        if a.order == 0 then a.order = i end
    end
end
for pf, list in pairs(blows) do
    for _, b in ipairs(list) do
        local a = Node(pf, b.state or "?", b.anim or "?")
        a.blows = a.blows + 1
        tree[pf][b.state or "?"].blows = tree[pf][b.state or "?"].blows + 1
        if b.d ~= nil and b.d > a.dmax then a.dmax = b.d end
    end
end
-- (a flash: a stretch of 1-2 frames drawn unlike both the frames before and after it - its reach off theirs by 1 or more,
-- nothing on either side counting as 0: a shape up a frame from nothing, or another shape a frame between two of one)
for key, list in pairs(drawn) do
    local pf = key:match("^([^#]+)")
    local function R(i) local d = list[i] return d ~= nil and (d.r or 0) or 0 end
    local i = 2
    while i <= #list do
        local r0 = R(i - 1)
        if math.abs(R(i) - r0) >= 1 then
            for len = 1, 2 do
                local after = R(i + len)
                local same = true
                for k = i + 1, i + len - 1 do if math.abs(R(k) - R(i)) >= 1 then same = false end end
                -- (up, then down again: bigger than both sides - the optic blast's start, 4.2 -> 6 a frame -> nothing)
                if same and R(i) >= math.max(r0, after) + 1 then
                    local ph = PhaseAt(frames[pf], list[i].t)
                    if ph ~= nil then
                        local a = Node(pf, ph.state or "?", ph.anim or "?")
                        a.flashes = a.flashes + 1
                        a.flash_t = a.flash_t or {}
                        a.flash_t[#a.flash_t + 1] = string.format("%.3f(%.1f)", list[i].t, R(i))
                    end
                    i = i + len
                    break
                end
            end
        end
        i = i + 1
    end
end
for key, list in pairs(drawn) do
    local pf = key:match("^([^#]+)")
    local bl = blows[pf] or {}
    for i, d in ipairs(list) do
        local ph = PhaseAt(frames[pf], d.t)
        if ph ~= nil then
            local a = Node(pf, ph.state or "?", ph.anim or "?")
            if d.r ~= nil then
                a.drawn = a.drawn + 1
                -- (no blow of its own in the 2 s after: a warning of nothing)
                local ahead = false
                for _, b in ipairs(bl) do if b.t >= d.t - .1 and b.t <= d.t + 2 then ahead = true break end end
                if not ahead then a.noblow = (a.noblow or 0) + 1 end
                -- (its reach from the boss: the shape's middle off the boss plus its own size)
                local off = (d.cx ~= nil and ph.x ~= nil) and math.sqrt((d.cx - ph.x) ^ 2 + (d.cz - ph.z) ^ 2) or 0
                a.rs[#a.rs + 1] = off + d.r
            end
        end
    end
end
for _, n in ipairs(notd) do
    local ph = PhaseAt(frames[n.prefab], n.t)
    if ph ~= nil then
        local a = Node(n.prefab, ph.state or "?", ph.anim or "?")
        a.notd = a.notd + 1
    end
end

-- (4) the tree, odd stretches flagged
local function Median(t)
    if #t == 0 then return 0 end
    table.sort(t)
    return t[math.ceil(#t / 2)]
end
local pfs = {}
for pf in pairs(tree) do pfs[#pfs + 1] = pf end
table.sort(pfs)
local flagged = 0
for _, pf in ipairs(pfs) do
    print(pf)
    local sts = {}
    for st, s in pairs(tree[pf]) do sts[#sts + 1] = st end
    table.sort(sts)
    for _, st in ipairs(sts) do
        local s = tree[pf][st]
        local ans = {}
        for an, a in pairs(s.anims) do ans[#ans + 1] = an end
        table.sort(ans, function(x, y) return s.anims[x].order < s.anims[y].order end)
        print(string.format("  %s%s", st, s.blows > 0 and string.format("  (%d blows)", s.blows) or ""))
        for _, an in ipairs(ans) do
            local a = s.anims[an]
            local rmed = Median(a.rs)
            local flags = {}
            if a.flashes > 0 then flags[#flags + 1] = "FLASH " .. a.flashes .. (os.getenv("TREE_V") and (" at " .. table.concat(a.flash_t, " ")) or "") end
            -- (no blow after: told, not flagged - the testbench's player steps out of most, a blow missed isn't a move without one)
            if a.notd > 0 then flags[#flags + 1] = "NOT " .. a.notd end
            if #flags > 0 then flagged = flagged + 1 end
            if os.getenv("TREE_FLAGGED") == nil or #flags > 0 then
                print(string.format("    %-26s frames %5d  blows %3d%s  drawn %5d%s  no blow after %3d%%  %s", an, a.frames, a.blows,
                    a.blows > 0 and string.format(" (to %.1f)", a.dmax) or "           ", a.drawn,
                    a.drawn > 0 and string.format(" reach %.1f", rmed) or "          ",
                    a.drawn > 0 and math.floor(100 * (a.noblow or 0) / a.drawn) or 0, #flags > 0 and ("<< " .. table.concat(flags, ", ")) or ""))
            end
        end
    end
end
print(string.format("%d stretches flagged", flagged))
