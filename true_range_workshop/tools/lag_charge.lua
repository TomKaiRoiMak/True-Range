-- luajit tools/lag_charge.lua <client_log> <server_log> [prefab=minotaur]: each charge the server ran (its "run_start" then "run"),
-- the way it really went (where it was at the run's end from where it began), set beside the way True Range drew it on the
-- player's screen frame by frame (tr_lagjoin [tr_lagdraw]) - Lag Compensation on / off as the scene was. "Snaps back": the
-- drawn lane off the real way during the wind-up (aimed where your screen had you), then turned to it at once.
--   wind-up off   how far the drawn lane pointed from the real way, its last frame before the run (degrees)
--   turn          the largest one-frame turn of the drawing from 0.3 s before the run to 0.5 s into it
-- Clocks: the server's time on the player's game from tr_lagjoin's "you" lines (median of game time - server time).
local cpath, spath, want = arg[1], arg[2], arg[3] or "minotaur"
assert(cpath and spath, "usage: luajit lag_charge.lua <client_log> <server_log> [prefab]")
local function Ang(a) return (a + 180) % 360 - 180 end

-- the clocks
local offs = {}
for line in io.lines(cpath) do
    local ct, st = line:match("%[tr_lag%] ([%d.]+) you n=%d+ srv_t=([%d.]+)")
    if ct ~= nil then offs[#offs + 1] = tonumber(ct) - tonumber(st) end
end
table.sort(offs)
local off = offs[math.max(1, math.floor((#offs + 1) / 2))] or 0

-- the server's charges: run_start ... run, contiguous
local charges = {}
local cur = nil
for line in io.lines(spath) do
    local t, st, x, z = line:match("%[tr_trace%] ([%d.]+) " .. want .. " after state=(%S+) .- pos=(%-?[%d.]+),(%-?[%d.]+)")
    if t ~= nil then
        t, x, z = tonumber(t), tonumber(x), tonumber(z)
        if st == "run_start" then
            if cur == nil or cur.run_t ~= nil then cur = { t0 = t, x0 = x, z0 = z } charges[#charges + 1] = cur end
        elseif st == "run" and cur ~= nil then
            if cur.run_t == nil then cur.run_t, cur.rx, cur.rz = t, x, z end
            cur.ex, cur.ez, cur.et = x, z, t
        elseif cur ~= nil and cur.run_t ~= nil then
            cur = nil
        end
    end
end

-- the drawing
local draws = {}
local pred_at = {}
for line in io.lines(cpath) do
    local p = line:match("%[tr_lag%] [%d.]+ scene .- pred=(%d)")
    local tt = tonumber(line:match("%[tr_lag%] ([%d.]+) scene"))
    if p ~= nil then pred_at[#pred_at + 1] = { t = tt, p = p } end
    local t, prefab, rot, mv = line:match("%[tr_lagdraw%] ([%d.]+) (%S+) %S+ %S+ %-?[%d.]+ %-?[%d.]+ (%-?[%d.]+) boss .- move=(%S+)")
    if t ~= nil and prefab == want then draws[#draws + 1] = { t = tonumber(t) - off, rot = tonumber(rot), move = mv } end
end
local function PredAt(ct)
    local p = "?"
    for _, e in ipairs(pred_at) do if e.t <= ct then p = e.p else break end end
    return p
end

print(string.format("clock: game = server + %.3f (%d samples); charges %d", off, #offs, #charges))
print("server t | Lag comp | ran (u) | real way | wind-up off | turn near the run | moves drawn")
local sums = { ["0"] = { n = 0, off = 0, turn = 0, snaps = 0 }, ["1"] = { n = 0, off = 0, turn = 0, snaps = 0 } }
for _, c in ipairs(charges) do
    if c.run_t ~= nil and c.ex ~= nil then
        local dx, dz = c.ex - c.rx, c.ez - c.rz
        local ran = math.sqrt(dx * dx + dz * dz)
        if ran > 2 then
            local way = math.atan2(-dz, dx) * 180 / math.pi
            local last_off, turn, prev, moves = nil, 0, nil, {}
            for _, d in ipairs(draws) do
                if d.t >= c.t0 - .1 and d.t <= c.et then
                    moves[d.move] = true
                    if d.t < c.run_t then last_off = Ang(d.rot - way) end
                    if prev ~= nil and d.t - prev.t <= .07 and d.t >= c.run_t - .3 and d.t <= c.run_t + .5 then
                        turn = math.max(turn, math.abs(Ang(d.rot - prev.rot)))
                    end
                    prev = d
                end
            end
            local ml = {}
            for m in pairs(moves) do ml[#ml + 1] = m end
            table.sort(ml)
            local p = PredAt(c.t0 + off)
            print(string.format("%8.2f | %s | %6.1f | %6.0f | %s | %5.0f | %s", c.t0, p == "1" and "on " or (p == "0" and "off" or " ? "), ran, way,
                last_off ~= nil and string.format("%5.0f", last_off) or "    -", turn, table.concat(ml, ",")))
            local s = sums[p]
            if s ~= nil then
                s.n = s.n + 1
                s.off = s.off + math.abs(last_off or 0)
                s.turn = s.turn + turn
                if math.abs(last_off or 0) > 20 and turn > 20 then s.snaps = s.snaps + 1 end
            end
        end
    end
end
for _, p in ipairs({ "1", "0" }) do
    local s = sums[p]
    if s.n > 0 then
        print(string.format("%s: %d charges, wind-up off %.0f deg on average, turn %.0f deg, snapped (off >20 and turned >20) %d",
            p == "1" and "on" or "off", s.n, s.off / s.n, s.turn / s.n, s.snaps))
    end
end
