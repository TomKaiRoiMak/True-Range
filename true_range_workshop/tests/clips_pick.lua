-- luajit tests/clips_pick.lua <list file: one log path a line> > picks.tsv
-- One clip for each monster's each move, from bench logs' traces (tests/clips.ps1): a move is its states one after another
-- from one that isn't plain going about (idle, walking, running, hit, ...) till it's back to that - named by its first state.
-- The go of it picked: one that struck the stand-in if any, then the nearest it as it began; from a little before it to a
-- little after it (4 s at most). Its strikes' times too, for the clip's marks.
-- Out: log, prefab, move, from, to, boss x, boss z, strikes (t;t;...) - tab apart, a line each.
local PLAIN = { "idle", "walk", "run", "hit", "death", "dead", "sleep", "wake", "frozen", "thaw", "stun", "despawn", "corpse",
    "eat", "home", "pickup", "premoving", "moving", "hide", "revive", "taunt", "spawn" }
local function Plain(state)
    for _, p in ipairs(PLAIN) do if state:find(p, 1, true) then return true end end
    return false
end
local best = {}   -- prefab|move -> pick
for path in io.lines(arg[1]) do
    local cur = {}  -- guid -> the move it's in
    local function Close(g, t_end)
        local c = cur[g]
        cur[g] = nil
        if c == nil or t_end - c.t0 < .1 then return end
        local k = c.prefab .. "|" .. c.move
        local p = best[k]
        local hit = #c.strikes > 0
        if p == nil or (hit and not p.hit) or (hit == p.hit and c.d < p.d - .5) then
            best[k] = { log = path, prefab = c.prefab, move = c.move, from = c.t0 - .3, to = math.min(t_end + .4, c.t0 + 4),
                x = c.x, z = c.z, d = c.d, strikes = c.strikes, hit = hit }
        end
    end
    for line in io.lines(path) do
        local t, prefab, kind, state = line:match("%[tr_trace%] ([%d%.]+) ([%w_]+) (%S+) .-state=(%S+)")
        if t ~= nil then
            t = tonumber(t)
            local g = line:match(" guid=(%d+)") or prefab
            local c = cur[g]
            if kind == "STRIKE" then
                if c ~= nil then c.strikes[#c.strikes + 1] = t end
            elseif kind == "after" then
                if Plain(state) then
                    if c ~= nil then Close(g, t) end
                elseif c == nil then
                    local x, z = line:match(" pos=([%-%d%.]+),([%-%d%.]+)")
                    local d = tonumber(line:match(" d=([%d%.]+)") or "") or 99
                    cur[g] = { prefab = prefab, move = state, t0 = t, x = tonumber(x), z = tonumber(z), d = d, strikes = {} }
                end
            end
        end
    end
end
local keys = {}
for k in pairs(best) do keys[#keys + 1] = k end
table.sort(keys)
for _, k in ipairs(keys) do
    local p = best[k]
    local st = {}
    for _, s in ipairs(p.strikes) do if s <= p.to then st[#st + 1] = string.format("%.3f", s) end end
    print(table.concat({ p.log, p.prefab, p.move, string.format("%.3f", p.from), string.format("%.3f", p.to),
        string.format("%.2f", p.x or 0), string.format("%.2f", p.z or 0), table.concat(st, ";") }, "\t"))
end
