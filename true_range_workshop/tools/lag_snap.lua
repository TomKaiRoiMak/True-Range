-- luajit tools/lag_snap.lua <client_log.txt>: shapes that jump and come back ("snaps back") on the player's own screen,
-- from tr_lagjoin's [tr_draw] lines (each frame True Range lays a move down: where, which way, where its boss is) -
-- the lag mode's run (tools/run_lag.ps1), Lag Compensation on / off per scene.
--   jump       a frame where the shape moved more than JUMP_D past what its boss moved, or turned more than JUMP_R
--   snap back  a jump undone within BACK frames: moved back (or turned back) by at least half as much
-- Per boss and on/off, per 1000 frames drawn - what matters is on against off, the same scenes each.
local JUMP_D, JUMP_R, BACK = .6, 20, 10
local path = assert(arg[1], "usage: luajit lag_snap.lua <client_log>")
local seqs = {}
for line in io.lines(path) do
    local t, prefab, guid, part, x, z, rot, bx, bz, mt, pred = line:match(
        "%[tr_l?a?g?draw%] ([%d.]+) (%S+) (%S+) (%S+) (%-?[%d.]+) (%-?[%d.]+) (%-?[%d.]+) boss (%-?[%d.]+) (%-?[%d.]+) t=(%-?[%d.]+) pred=(%d)")
    if t ~= nil then
        local key = guid .. " " .. part
        local s = seqs[key]
        if s == nil then s = { prefab = prefab } seqs[key] = s end
        local r = { t = tonumber(t), x = tonumber(x), z = tonumber(z), rot = tonumber(rot), bx = tonumber(bx), bz = tonumber(bz),
            mt = tonumber(mt), pred = tonumber(pred) }
        -- (the same tick drawn again - each frame of the screen: the last of it)
        local last = s[#s]
        if last ~= nil and last.t == r.t then s[#s] = r else s[#s + 1] = r end
    end
end

local function Ang(a) a = (a + 180) % 360 - 180 return a end
local stats = {}
local examples = {}
for _, s in pairs(seqs) do
    local jumps = {}
    for i = 2, #s do
        local a, b = s[i - 1], s[i]
        -- (one move's frames only: next tick or two, its time going on)
        if b.t - a.t <= .07 and b.mt >= a.mt - .001 then
            -- (laid where its boss is: past what the boss moved; laid elsewhere (a charge's lane, kept where it
            -- began while the boss runs down it): what the shape itself moved - by the boss, 67 of the Ancient
            -- Guardian's lanes read as jumps, 2026-10-25)
            local on_boss = math.abs(a.x - a.bx) < .05 and math.abs(a.z - a.bz) < .05
            local dx, dz = b.x - a.x, b.z - a.z
            -- (one kept where it is as its boss leaps off (the Blighted Rock Master's dash, its lane kept where it began,
            -- the boss 8-12 on in a tick): still on your screen, not a jump - 47 of them so, 2026-10-26. OLD_SNAPSTILL=1:
            -- counted)
            local still = dx * dx + dz * dz < .0001 and not os.getenv("OLD_SNAPSTILL")
            if on_boss and not still then dx, dz = dx - (b.bx - a.bx), dz - (b.bz - a.bz) end
            local dd = math.sqrt(dx * dx + dz * dz)
            local dr = Ang(b.rot - a.rot)
            local k = s.prefab .. " pred=" .. b.pred
            stats[k] = stats[k] or { frames = 0, jumps = 0, backs = 0 }
            stats[k].frames = stats[k].frames + 1
            if dd > JUMP_D or math.abs(dr) > JUMP_R then
                stats[k].jumps = stats[k].jumps + 1
                local j = { i = i, dx = dx, dz = dz, dd = dd, dr = dr, k = k, t = b.t }
                -- (undone: an earlier jump within BACK frames, this one the other way and half its size at least)
                for q = #jumps, 1, -1 do
                    local p = jumps[q]
                    if i - p.i > BACK then break end
                    local back_d = p.dd > JUMP_D and (dx * p.dx + dz * p.dz) < 0 and dd >= p.dd * .5
                    local back_r = math.abs(p.dr) > JUMP_R and dr * p.dr < 0 and math.abs(dr) >= math.abs(p.dr) * .5
                    if back_d or back_r then
                        stats[k].backs = stats[k].backs + 1
                        examples[k] = examples[k] or {}
                        if #examples[k] < 3 then
                            examples[k][#examples[k] + 1] = string.format("t=%.3f jump %.2f/%.0f deg then back %.2f/%.0f deg %d frames on (move time %.2f)",
                                p.t, p.dd, p.dr, dd, dr, i - p.i, b.mt)
                        end
                        break
                    end
                end
                jumps[#jumps + 1] = j
            end
        end
    end
end
local keys = {}
for k in pairs(stats) do keys[#keys + 1] = k end
table.sort(keys)
print(string.format("%-34s %8s %6s %6s %10s", "boss / Lag comp", "frames", "jumps", "backs", "backs/1000"))
local tot = { [0] = { f = 0, j = 0, b = 0 }, [1] = { f = 0, j = 0, b = 0 } }
for _, k in ipairs(keys) do
    local s = stats[k]
    print(string.format("%-34s %8d %6d %6d %10.2f", k, s.frames, s.jumps, s.backs, s.backs * 1000 / math.max(1, s.frames)))
    local p = tonumber(k:match("pred=(%d)"))
    tot[p].f, tot[p].j, tot[p].b = tot[p].f + s.frames, tot[p].j + s.jumps, tot[p].b + s.backs
end
for _, p in ipairs({ 1, 0 }) do
    local t = tot[p]
    print(string.format("all, %s: frames %d, jumps %d, snap backs %d (%.2f per 1000)", p == 1 and "on" or "off", t.f, t.j, t.b, t.b * 1000 / math.max(1, t.f)))
end
for _, k in ipairs(keys) do
    for _, e in ipairs(examples[k] or {}) do print("  " .. k .. ": " .. e) end
end
