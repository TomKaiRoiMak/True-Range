-- luajit leftover_count.lua <share log>...: for every boss's window in a bench share (its "spawned" line to
-- the next), the blows by what an earlier boss of the share left behind - born since the share's first
-- boss, before this one, not gone when it began - and the stand-in's hurts from anything born before it
-- (fire has no one striking). The cleanup's own check (tr_testbench NextBoss; VERIFY_PLAN 6.15): old logs
-- must show the Rabbit King's minions, new ones ~0. Also: GUIDs only ever go up from tick to tick.
-- Prints "share boss first left_hit left_trace before_hurt sources" a window, then "guid_order <bad>".
for _, path in ipairs(arg) do
    local name = path:match("([^\\/]+)$")
    local born, gone = {}, {}         -- guid -> prefab ; guid -> true
    local g0                          -- the share's first boss
    local win                         -- the window now: boss, guid, first, counts, sources
    local wins = {}
    local last_t, tick_min, tick_max, prev_max, bad = nil, nil, nil, -1, 0
    local pending                     -- a boss spawned, its guid not seen yet
    local function Close() if win then wins[#wins + 1] = win end end
    for line in io.lines(path) do
        local tag, rest = line:match("%[(tr_%w+)%] (.*)")
        if tag == "tr_ent" then
            local t, what, prefab, guid = rest:match("^([%d.]+) (%a+) (%S+) (%d+)")
            guid = tonumber(guid)
            if what == "born" and guid then
                born[guid] = prefab
                -- (a tick's lowest against the highest of the ticks before it - within one, out of order)
                if t ~= last_t then
                    if tick_min ~= nil and tick_min <= prev_max then bad = bad + 1 end
                    if tick_max ~= nil and tick_max > prev_max then prev_max = tick_max end
                    last_t, tick_min, tick_max = t, guid, guid
                else tick_min, tick_max = math.min(tick_min, guid), math.max(tick_max, guid) end
                if pending and prefab == pending then
                    Close()
                    g0 = g0 or guid
                    local alive = {}
                    for g, p in pairs(born) do if g >= g0 and g < guid and not gone[g] then alive[g] = p end end
                    win = { boss = prefab, guid = guid, first = (#wins == 0), hit = 0, trace = 0, hurt = 0, src = {}, alive = alive }
                    pending = nil
                end
            elseif what == "gone" and guid then gone[guid] = true end
        elseif tag == "tr_bench" then
            local p = rest:match("^[%d.]+ (%S+) spawned")
            if p then pending = p end
        elseif win and (tag == "tr_hit" or tag == "tr_hurt") then
            local prefab, guid = rest:match("^[%d.]+ (%S+) (%d+)")
            guid = tonumber(guid)
            if guid and win.alive[guid] then
                if tag == "tr_hit" then win.hit = win.hit + 1 end
                win.src[prefab] = (win.src[prefab] or 0) + 1
            end
            if tag == "tr_hurt" and guid and guid < win.guid then win.hurt = win.hurt + 1 end
        elseif win and tag == "tr_trace" and (rest:find(" HIT at ", 1, true) or rest:find(" STRIKE at ", 1, true)) then
            local guid = tonumber(rest:match(" guid=(%d+)"))
            if guid and win.alive[guid] then win.trace = win.trace + 1 end
        end
    end
    Close()
    for _, w in ipairs(wins) do
        local s = {}
        for p, n in pairs(w.src) do s[#s + 1] = p .. "=" .. n end
        table.sort(s)
        print(string.format("%s %s %s %d %d %d %s", name, w.boss, w.first and "first" or "-", w.hit, w.trace, w.hurt, table.concat(s, ",")))
    end
    print(string.format("%s guid_order %d", name, bad))
end
