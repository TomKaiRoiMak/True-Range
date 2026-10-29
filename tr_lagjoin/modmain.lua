-- TR Lag Join (local, testing only - never upload): the player's half of the testbench's lag mode
-- (tr_testbench "tr_bench+lag:...", tools/run_lag.ps1, VERIFY_PLAN 6.20). Your game and the server apart, as
-- with caves on: the server brings each boss and says when a scene begins; here you walk it through the game's
-- own movement (the move controls, as a stick would give them), Lag Compensation on or off as the scene says -
-- the game's real prediction, not a teleport. Each blow the server tells of is pushed here as the game pushes
-- "attacked" where the world runs: True Range's testing lines ("you were struck ... drawn:", "drawn IN but NOT
-- struck") then say what you stood in on your own screen. Does nothing without join.txt in this folder.
local G = GLOBAL

-- (join.txt: "ip port [speed]", written by tools/run_lag.ps1 and taken away when it's done - speed: as the server's, -Speed)
local function ReadJoin()
    local io = G.rawget(G, "io")
    if io == nil then return nil end
    local ok, fh = G.pcall(io.open, MODROOT .. "join.txt", "r")
    if not ok or fh == nil then return nil end
    local line = fh:read("*l")
    fh:close()
    local ip, port, speed = (line or ""):match("^(%S+)%s+(%d+)%s*(%d*)")
    -- (and switches back to how it was, by name - "TR_OLD_PICKATTACK ...": set as globals for True Range, run_lag -Old)
    for name in (line or ""):gmatch("TR_OLD_[%w_]+") do G.rawset(G, name, true) print("[tr_lag] switch " .. name) end
    return ip, port ~= nil and G.tonumber(port) or nil, speed ~= nil and G.tonumber(speed) or 1
end
local JOIN_IP, JOIN_PORT, JOIN_SPEED = ReadJoin()
if JOIN_IP == nil or JOIN_PORT == nil then return end

-- (the main menu: on to the bench's server, a moment after it's up)
AddClassPostConstruct("screens/redux/multiplayermainscreen", function(self)
    self.inst:DoTaskInTime(3, function()
        print(string.format("[tr_lag] joining %s:%d", JOIN_IP, JOIN_PORT))
        print("[tr_lag] c_connect " .. tostring(G.c_connect(JOIN_IP, JOIN_PORT)))
    end)
end)

-- (the character pick: Wilson, as he comes - his run is the scenes' RUN_SPEED)
AddClassPostConstruct("screens/redux/lobbyscreen", function(self)
    self.inst:DoTaskInTime(2, function()
        if self.cb ~= nil then
            print("[tr_lag] picking wilson")
            self.cb("wilson", "wilson_none")
        end
    end)
end)

local FRAMES = G.FRAMES
local RUN_SPEED = 6        -- (tr_testbench RUN_SPEED)
local LOOKAHEAD = 4
local SCENE_MAX = 3 * 360  -- (tr_testbench: 3 * MAX_FRAMES at most - an "end" never come, let go)
local scene = nil
local cur_pred = nil
local last_you = nil
local TRACE = { charlie_boss_vines = true, charlie_boss_projectile = true, charlie_boss_minion1 = true, charlie_boss_minion2 = true,
    um_beestinger_projectile = true, eyeofterror_minieye_projectile = true }

local function Find(prefab, x, z, r)
    for _, e in ipairs(G.TheSim:FindEntities(x, 0, z, r)) do
        if e.prefab == prefab then return e end
    end
end

-- (the move controls asked for while a scene runs: what playercontroller's GetWorldControllerVector reads)
local input = G.TheInput
local get = input.GetAnalogControlValue
input.GetAnalogControlValue = function(self, control, ...)
    local mv = scene ~= nil and scene.move or nil
    if mv ~= nil and mv[control] ~= nil then return mv[control] end
    return get(self, control, ...)
end

-- (each tick: where the scene wants you, as the server's own scene would put you (tr_testbench TickLane) -
-- round the boss at a run from frame k, or straight in at it / out from it - and the controls that go there)
local function Drive(p)
    local s = scene
    if s == nil then return end
    local f = (G.GetTime() - s.t0) / FRAMES
    if f > SCENE_MAX then
        print(string.format("[tr_lag] %.3f scene n=%d let go - no end", G.GetTime(), s.n))
        scene = nil
        return
    end
    local mx, _, mz = p.Transform:GetWorldPosition()
    -- (fast things near, where your game has them each frame - beside the server's "with ... x z" as they strike: how
    -- far behind your screen shows them; the Shrouded Queen's vines struck with nothing drawn under you, 2026-10-26)
    for _, e in ipairs(G.TheSim:FindEntities(mx, 0, mz, 10)) do
        if TRACE[e.prefab] then
            local ex, _, ez = e.Transform:GetWorldPosition()
            print(string.format("[tr_lagthing] %.3f %s %s %.2f %.2f you %.2f %.2f", G.GetTime(), e.prefab, tostring(e.GUID), ex, ez, mx, mz))
        end
    end
    local wx, wz = nil, nil
    if f >= s.k then
        if s.mode == "run" then
            local dx, dz = s.px - s.bx, s.pz - s.bz
            local d = math.sqrt(dx * dx + dz * dz)
            if d < 1.5 then dx, dz, d = 3 * math.cos(s.rot), -3 * math.sin(s.rot), 3 end
            -- (a point LOOKAHEAD frames on along the way, not the one for now: caught up with that one it stopped,
            -- went again - running and standing every other tick, 2026-10-25 run 2)
            local a_end = math.pi * 1.5
            local a = s.side * math.min(a_end, (f + LOOKAHEAD - s.k) * RUN_SPEED * FRAMES / d)
            local ca, sa = math.cos(a), math.sin(a)
            wx, wz = s.bx + dx * ca - dz * sa - mx, s.bz + dx * sa + dz * ca - mz
            if wx * wx + wz * wz < .04 then wx, wz = nil, nil end
        else
            local b = s.boss_ent
            if b == nil or not b:IsValid() then
                b = Find(s.prefab, s.bx, s.bz, 12)
                s.boss_ent = b
            end
            local bx, bz = s.bx, s.bz
            local near = 1
            if b ~= nil then
                local x, _, z = b.Transform:GetWorldPosition()
                bx, bz = x, z
                if b.GetPhysicsRadius ~= nil then near = math.max(near, b:GetPhysicsRadius(0) + .6) end
            end
            local dx, dz = mx - bx, mz - bz
            local d = math.sqrt(dx * dx + dz * dz)
            if d > .01 and ((s.walk < 0 and d > near) or (s.walk > 0 and d < 16)) then
                wx, wz = s.walk * dx / d, s.walk * dz / d
            end
        end
    end
    local mv = { [G.CONTROL_MOVE_UP] = 0, [G.CONTROL_MOVE_DOWN] = 0, [G.CONTROL_MOVE_LEFT] = 0, [G.CONTROL_MOVE_RIGHT] = 0 }
    if wx ~= nil then
        -- (the world way as the controls: dir = right * x - down * y, both flat and square to each other)
        local n = math.sqrt(wx * wx + wz * wz)
        wx, wz = wx / n, wz / n
        local r, dn = G.TheCamera:GetRightVec(), G.TheCamera:GetDownVec()
        local x = wx * r.x + wz * r.z
        local y = -(wx * dn.x + wz * dn.z)
        mv[G.CONTROL_MOVE_RIGHT], mv[G.CONTROL_MOVE_LEFT] = math.max(x, 0), math.max(-x, 0)
        mv[G.CONTROL_MOVE_UP], mv[G.CONTROL_MOVE_DOWN] = math.max(y, 0), math.max(-y, 0)
    end
    s.move = mv
end

AddPlayerPostInit(function(p)
    p:DoTaskInTime(0, function()
        if p ~= G.ThePlayer then return end
        print(string.format("[tr_lag] %.3f in game as %s", G.GetTime(), tostring(p.prefab)))
        -- (as fast as the server, -Speed: the scenes' times the same on both sides)
        if (JOIN_SPEED or 1) > 1 then G.TheSim:SetTimeScale(JOIN_SPEED) print(string.format("[tr_lag] time scale %d", JOIN_SPEED)) end
        p:DoPeriodicTask(0, Drive)
        -- (what True Range lays down each frame for a move - where, which way - with where the boss is: a shape
        -- that jumps and comes back ("snaps back") seen in tools/lag_snap.lua. Its own code untouched: wrapped)
        local ok, SM = G.pcall(G.require, "true_range/simmoves")
        if ok and type(SM) == "table" and SM.Draw ~= nil and not SM._tr_lag_wrapped then
            SM._tr_lag_wrapped = true
            local draw = SM.Draw
            SM.Draw = function(entry, x, z, rot, target, my_radius, px, pz, t, log, ent, ...)
                if ent ~= nil and ent.IsValid ~= nil and ent:IsValid() and x ~= nil and rot ~= nil then
                    local bx, _, bz = ent.Transform:GetWorldPosition()
                    -- ("[tr_lagdraw]": True Range's own testing line is "[tr_draw]")
                    local name = entry ~= nil and (entry.name or (entry.anims ~= nil and entry.anims[1])) or "?"
                    print(string.format("[tr_lagdraw] %.3f %s %s %s %.2f %.2f %.1f boss %.2f %.2f t=%.3f pred=%d move=%s",
                        G.GetTime(), tostring(ent.prefab), tostring(ent.GUID), tostring(log):sub(-8), x, z, rot / G.DEGREES,
                        bx, bz, t or -1, cur_pred and 1 or 0, tostring(name)))
                end
                return draw(entry, x, z, rot, target, my_radius, px, pz, t, log, ent, ...)
            end
            print("[tr_lag] watching True Range's drawing")
            -- (each boss (epic) given to Predict.Draw or not, and the server's word on it - "[tr_lagdl] t prefab guid in|OUT word=": what
            -- the frames its glow went out had - lag_beam2 2026-10-28)
            local okP, P = G.pcall(G.require, "true_range/predict")
            if okP and type(P) == "table" and P.Draw ~= nil then
                local pdraw = P.Draw
                local was_in = G.setmetatable({}, { __mode = "k" })
                P.Draw = function(ents, ranges, ...)
                    local now = G.GetTime()
                    local inl = {}
                    for _, e in G.ipairs(ents or {}) do
                        if e.HasTag ~= nil and e:HasTag("epic") then
                            inl[e] = true
                            local r = ranges ~= nil and ranges(e) or nil
                            local cds = r ~= nil and r.cds ~= nil and G.next(r.cds) ~= nil
                            local c = e.replica ~= nil and e.replica.combat or nil
                            local tg = c ~= nil and c:GetTarget() or nil
                            print(string.format("[tr_lagdl] %.3f %s %d in word=%s harmful=%s cds=%s at=%s target=%s", now, e.prefab, e.GUID, tostring(r ~= nil),
                                tostring(r ~= nil and r.harmful), tostring(cds), tostring(r ~= nil and r.at), tostring(tg ~= nil and tg.prefab)))
                            was_in[e] = now
                        end
                    end
                    for e, t in G.pairs(was_in) do
                        if not inl[e] and now - t < 1 then print(string.format("[tr_lagdl] %.3f %s %d OUT", now, tostring(e.prefab), e.GUID or 0)) end
                    end
                    local a1, a2, a3 = pdraw(ents, ranges, ...)
                    -- (how each was drawn this frame (its notes - Predict.Report), said as it changes: "[tr_lagnote] t line" - which way of
                    -- drawing a shape that flickers frame by frame went to and fro between, the Eye of Terror's charge_pst, lag 0646,
                    -- 2026-10-29: not seen in the replays)
                    if P.Report ~= nil then
                        local okR, rep = G.pcall(P.Report, nil, nil)
                        if okR and type(rep) == "table" then
                            local seen = {}
                            for _, line in G.ipairs(rep) do
                                local who = line:match("^(%S+)") or "?"
                                local key = line:gsub(" %(%d+%.%d off%)", ""):gsub(" frame %d+", ""):gsub(" @%d+", ""):gsub("[%-%d]+%.%d+", "#")
                                seen[who] = (seen[who] or "") .. "|" .. key
                            end
                            P._tr_lagnote = P._tr_lagnote or {}
                            for who, k in G.pairs(seen) do
                                if P._tr_lagnote[who] ~= k then
                                    P._tr_lagnote[who] = k
                                    print(string.format("[tr_lagnote] %.3f %s", now, k:sub(1, 400)))
                                end
                            end
                            for who in G.pairs(P._tr_lagnote) do
                                if seen[who] == nil then P._tr_lagnote[who] = nil print(string.format("[tr_lagnote] %.3f %s -", now, who)) end
                            end
                        end
                    end
                    return a1, a2, a3
                end
            end
            -- (EVERY piece True Range lays, every frame, by whose it is - "[tr_lagframe] t prefab guid": its fill triangles (count,
            -- area, middle), lines (count, middle), groups shown (count, middle) - whatever draws it (a move, a thing, a ring, a
            -- disc): a shape that moves, jumps, flickers or is gone a frame is in these, the player 2026-10-28 "why isn't every
            -- frame of every drawn shape recorded")
            local okL, L = G.pcall(G.require, "true_range/lines")
            if okL and type(L) == "table" and L.Begin ~= nil and L.End ~= nil then
                local fr = nil       -- this frame's: owner -> { tri n, area, ax, az, seg n, sx, sz, grp n, gx, gz }
                local cur = nil      -- the thing being drawn now (DrawHazard), else simmoves' _draw_owner
                local function Rec(o)
                    if fr == nil then return nil end
                    o = o or cur or SM._draw_owner or "?"
                    local r = fr[o]
                    if r == nil then r = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 } fr[o] = r end
                    return r
                end
                -- (and the glow's brightness each frame (Lines.Pulse: one style, every boss's glow shares it) - "[tr_lagpulse] t
                -- style alpha calls", said as it changes by .15 or more: a glow that blinks is in its brightness, not its pieces -
                -- the Blighted Rock Master "flickering", the player 2026-10-29, none of it in [tr_lagframe])
                local pulse_now, pulse_last = {}, {}
                if L.Pulse ~= nil and not L._tr_lag_pulse then
                    L._tr_lag_pulse = true
                    local pulse = L.Pulse
                    L.Pulse = function(style, alpha, ...)
                        local p = pulse_now[style] or { a = alpha, n = 0 }
                        p.a, p.n = alpha, p.n + 1
                        pulse_now[style] = p
                        return pulse(style, alpha, ...)
                    end
                end
                local begin, finish = L.Begin, L.End
                L.Begin = function(...) fr = {} return begin(...) end
                L.End = function(...)
                    if fr ~= nil then
                        local t = G.GetTime()
                        for o, r in pairs(fr) do
                            local name, guid = "?", 0
                            if type(o) == "table" and o.prefab ~= nil then name, guid = o.prefab, o.GUID or 0 elseif type(o) == "string" then name = o end
                            print(string.format("[tr_lagframe] %.3f %s %d tri=%d area=%.2f at=%.2f,%.2f seg=%d at=%.2f,%.2f grp=%d at=%.2f,%.2f pred=%d ext=%.2f",
                                t, name, guid, r[1], r[2], r[2] > 0 and r[3] / r[2] or 0, r[2] > 0 and r[4] / r[2] or 0,
                                r[5], r[5] > 0 and r[6] / r[5] or 0, r[5] > 0 and r[7] / r[5] or 0,
                                r[8], r[8] > 0 and r[9] / r[8] or 0, r[8] > 0 and r[10] / r[8] or 0, cur_pred and 1 or 0, r[11] or 0))
                        end
                    end
                    fr = nil
                    do
                        local t = G.GetTime()
                        for style, p in pairs(pulse_now) do
                            local was = pulse_last[style] or 0
                            if math.abs(p.a - was) >= .15 then print(string.format("[tr_lagpulse] %.3f %s %.2f calls=%d", t, style, p.a, p.n)) end
                            pulse_last[style] = p.a
                        end
                        for style, a in pairs(pulse_last) do
                            if pulse_now[style] == nil and a > 0 then print(string.format("[tr_lagpulse] %.3f %s none", t, style)) pulse_last[style] = 0 end
                        end
                        pulse_now = {}
                    end
                    return finish(...)
                end
                local tri = L.Tri
                L.Tri = function(ax, az, bx, bz, cx, cz, style)
                    local r = Rec()
                    if r ~= nil and ax ~= nil then
                        local a = math.abs((bx - ax) * (cz - az) - (bz - az) * (cx - ax)) / 2
                        r[1], r[2], r[3], r[4] = r[1] + 1, r[2] + a, r[3] + a * (ax + bx + cx) / 3, r[4] + a * (az + bz + cz) / 3
                    end
                    return tri(ax, az, bx, bz, cx, cz, style)
                end
                local putTri = L.PutTri
                L.PutTri = function(rr, style, dx, dz)
                    local r = Rec()
                    if r ~= nil and rr ~= nil then
                        r[1], r[2], r[3], r[4] = r[1] + 1, r[2] + 1, r[3] + rr[1] + (dx or 0), r[4] + rr[2] + (dz or 0)
                    end
                    return putTri(rr, style, dx, dz)
                end
                local seg = L.Segment
                L.Segment = function(x1, z1, x2, z2, ...)
                    local r = Rec()
                    if r ~= nil and x1 ~= nil then r[5], r[6], r[7] = r[5] + 1, r[6] + (x1 + x2) / 2, r[7] + (z1 + z2) / 2 end
                    return seg(x1, z1, x2, z2, ...)
                end
                local putSeg = L.PutSeg
                L.PutSeg = function(rr, style, dx, dz)
                    local r = Rec()
                    if r ~= nil and rr ~= nil then r[5], r[6], r[7] = r[5] + 1, r[6] + rr[1] + (dx or 0), r[7] + rr[2] + (dz or 0) end
                    return putSeg(rr, style, dx, dz)
                end
                local groupAt = L.GroupAt
                L.GroupAt = function(g, x, z, deg)
                    local r = Rec()
                    if r ~= nil and x ~= nil then r[8], r[9], r[10] = r[8] + 1, r[9] + x, r[10] + z end
                    -- (how far its pieces reach from where it's put - "ext": a group's size, not only where it is; the Moonmaw's
                    -- spin drawn as one group, its reach not told, 2026-10-28)
                    if r ~= nil and g ~= nil and g.pieces ~= nil then
                        local e2 = 0
                        for k, list in G.pairs(g.pieces) do
                            local n = G.math.min((g.used ~= nil and g.used[k]) or #list, #list)
                            for j = 1, n do
                                local p = list[j]
                                if p ~= nil and p.Transform ~= nil and p.Transform.GetLocalPosition ~= nil then
                                    local lx, _, lz = p.Transform:GetLocalPosition()
                                    if lx ~= nil and lx * lx + lz * lz > e2 then e2 = lx * lx + lz * lz end
                                end
                            end
                        end
                        r[11] = G.math.max(r[11] or 0, G.math.sqrt(e2))
                    end
                    return groupAt(g, x, z, deg)
                end
                -- (round things drawn together, lanes of a lot: their own owner - not whichever thing was drawn last, the beam
                -- "drawing" 17 discs 25 away, 2026-10-28)
                for _, fn in G.ipairs({ "UnionDraw", "LaneDraw" }) do
                    local orig = SM[fn]
                    if orig ~= nil then
                        local tag = fn == "UnionDraw" and "union" or "lane"
                        SM[fn] = function(...)
                            local was = cur
                            cur = tag
                            local r1, r2 = orig(...)
                            cur = was
                            return r1, r2
                        end
                    end
                end
                local drawHaz = SM.DrawHazard
                -- (and where each thing really is, every frame, drawn or not - "[tr_lagthing] t prefab guid x y z": what its drawing is
                -- set against - the Ink Blight's landing guessed off on your game alone, 2026-10-28)
                local thing_t = G.setmetatable({}, { __mode = "k" })
                SM.DrawHazard = function(ent, ...)
                    local now = G.GetTime()
                    if type(ent) == "table" and ent.Transform ~= nil and thing_t[ent] ~= now then
                        thing_t[ent] = now
                        local x, y, z = ent.Transform:GetWorldPosition()
                        print(string.format("[tr_lagthing] %.3f %s %d %.3f %.3f %.3f", now, ent.prefab or "?", ent.GUID or 0, x, y, z))
                    end
                    local was = cur
                    cur = ent
                    local res = drawHaz(ent, ...)
                    cur = was
                    return res
                end
                print("[tr_lag] recording every frame's pieces")
            end
            -- (and where each thrown thing is drawn coming down, frame to frame, as your game has it (simmoves TR_LANDWOB) -
            -- told every 10 s, "[tr_lagland]": the Ink Blight's balls sliding under the player, never seen by the replays, 2026-10-28)
            -- (and every filled disc and ring laid, each frame - "[tr_lagdisc]" / "[tr_lagring]": a ring flickering in the player's
            -- game (the Umbral Abomination's), not in True Range's shape lines - which frames have it, which don't)
            local draw_disc = SM.DrawDisc
            SM.DrawDisc = function(cx, cz, r, eta, px, pz)
                print(string.format("[tr_lagdisc] %.3f %.2f %.2f r=%.2f eta=%.2f", G.GetTime(), cx, cz, r, eta or -1))
                return draw_disc(cx, cz, r, eta, px, pz)
            end
            local okT, Tg = G.pcall(G.require, "true_range/telegraph")
            if okT and Tg ~= nil and Tg.Circle ~= nil then
                local circle = Tg.Circle
                Tg.Circle = function(x, z, r, style, slot)
                    if slot == nil then print(string.format("[tr_lagring] %.3f %.2f %.2f r=%.2f %s", G.GetTime(), x, z, r, tostring(style))) end
                    return circle(x, z, r, style, slot)
                end
            end
            G.rawset(G, "TR_LANDWOB", {})
            G.rawset(G, "TR_LANDWOB_EV", {})
            G.TheWorld:DoPeriodicTask(10, function()
                for k, w in pairs(G.rawget(G, "TR_LANDWOB") or {}) do
                    print(string.format("[tr_lagland] %.3f %s frames=%d moved=%d dist=%.2f most=%.2f settled_off=%d settle_most=%.2f pred=%d", G.GetTime(), k, w.n, w.moved, w.dist, w.most, w.settle_n or 0, w.settle_most or 0, cur_pred and 1 or 0))
                end
                local ev = G.rawget(G, "TR_LANDWOB_EV") or {}
                for i = 1, #ev do print("[tr_lagland] " .. ev[i]) ev[i] = nil end
                G.rawset(G, "TR_LANDWOB", {})
            end)
            -- (one drawn as the server tells its reach (SM._live_radius - the Klaus deer's ice circle): each frame, its reach,
            -- you from it, and whether you're frozen - "[tr_lagice]": frozen while outside it = drawn too small)
            local draw_haz = SM.DrawHazard
            SM.DrawHazard = function(ent, x, z, ...)
                local inside = draw_haz(ent, x, z, ...)
                local lr = SM._live_radius ~= nil and ent ~= nil and SM._live_radius[ent.prefab] or nil
                if lr ~= nil and ent[lr.field] ~= nil then
                    local me = G.ThePlayer
                    local mx, _, mz = me.Transform:GetWorldPosition()
                    local frozen = me.AnimState ~= nil and (me.AnimState:IsCurrentAnimation("frozen") or me.AnimState:IsCurrentAnimation("frozen_loop_pst")) or false
                    print(string.format("[tr_lagice] %.3f %s %s r=%.2f d=%.2f drawn_in=%d frozen=%d pred=%d", G.GetTime(), tostring(ent.prefab),
                        tostring(ent.GUID), ent[lr.field]:value(), math.sqrt((mx - x) ^ 2 + (mz - z) ^ 2), inside and 1 or 0, frozen and 1 or 0,
                        cur_pred and 1 or 0))
                end
                return inside
            end
        end
    end)
end)

-- (the server's words - tr_testbench registers the same three, in the same order)
AddClientModRPCHandler("tr_lag", "scene", function(n, mode, k, side, walk, bx, bz, rot, px, pz, pred, prefab)
    local p = G.ThePlayer
    if p == nil then return end
    -- (1 / 0: a false sent comes as nothing)
    pred = pred == 1
    if pred ~= cur_pred and p.EnableMovementPrediction ~= nil then
        p:EnableMovementPrediction(pred)
        cur_pred = pred
    end
    scene = { n = n, mode = mode, k = k, side = side, walk = walk, bx = bx, bz = bz, rot = rot, px = px, pz = pz,
        prefab = prefab, t0 = G.GetTime() }
    local mx, _, mz = p.Transform:GetWorldPosition()
    print(string.format("[tr_lag] %.3f scene n=%d mode=%s k=%d side=%d walk=%d pred=%d boss=%s srv_you=%.2f,%.2f me=%.2f,%.2f",
        G.GetTime(), n, tostring(mode), k, side, walk, pred and 1 or 0, tostring(prefab), px, pz, mx, mz))
end)

AddClientModRPCHandler("tr_lag", "end", function(n)
    if scene ~= nil and scene.n == n then scene = nil end
    print(string.format("[tr_lag] %.3f end n=%d", G.GetTime(), n))
end)

AddClientModRPCHandler("tr_lag", "struck", function(prefab, ax, az, sx, sz, st, blocked)
    local p = G.ThePlayer
    if p == nil then return end
    local mx, _, mz = p.Transform:GetWorldPosition()
    -- (the nearest of its kind to where the server had it, within 20: your game has a fast one well behind - the Blighted
    -- Rock Master's dash, 8-12 a tick, missed within 6: "struck by ?", its drawn dash "drawn IN but NOT struck", 34 of them)
    local by, bd = nil, 20 * 20
    for _, e in ipairs(G.TheSim:FindEntities(ax, 0, az, 20)) do
        if e.prefab == prefab then
            local ex, _, ez = e.Transform:GetWorldPosition()
            local d = (ex - ax) ^ 2 + (ez - az) ^ 2
            if d < bd then by, bd = e, d end
        end
    end
    -- (and which one, as your game knows it - its GUID, as [tr_lagdraw] gives it: of a swarm, the one that bit)
    local gx, gz = -1e9, -1e9
    if by ~= nil then local qx, _, qz = by.Transform:GetWorldPosition() gx, gz = qx, qz end
    print(string.format("[tr_lag] %.3f struck by %s srv_t=%.3f srv_you=%.2f,%.2f me=%.2f,%.2f lead=%.2f pred=%d scene=%s seen=%d guid=%s srv_at=%.2f,%.2f at=%.2f,%.2f",
        G.GetTime(), tostring(prefab), st, sx, sz, mx, mz, math.sqrt((mx - sx) ^ 2 + (mz - sz) ^ 2), cur_pred and 1 or 0,
        scene ~= nil and tostring(scene.n) or "-", by ~= nil and 1 or 0, by ~= nil and tostring(by.GUID) or "-", ax, az, gx, gz))
    p:PushEvent(blocked == 1 and "blocked" or "attacked", { attacker = by })
end)

-- (where the server had you, as it comes: "gap" = how far your screen has you from it then, and how fast you go)
AddClientModRPCHandler("tr_lag", "you", function(n, sx, sz, st)
    local p = G.ThePlayer
    if p == nil then return end
    local mx, _, mz = p.Transform:GetWorldPosition()
    -- (how fast from where your screen had you last time: with Lag Compensation off your body has no velocity of
    -- its own here - every one 0 in run 2)
    local now = G.GetTime()
    local speed = 0
    if last_you ~= nil and now > last_you.t then speed = math.sqrt((mx - last_you.x) ^ 2 + (mz - last_you.z) ^ 2) / (now - last_you.t) end
    last_you = { x = mx, z = mz, t = now }
    print(string.format("[tr_lag] %.3f you n=%d srv_t=%.3f gap=%.2f speed=%.2f pred=%d", now, n, st,
        math.sqrt((mx - sx) ^ 2 + (mz - sz) ^ 2), speed, cur_pred and 1 or 0))
end)
