-- luajit bench_speed.lua <share log>...: how fast each boss's window ran - game s a wall s, by its place in
-- its share, with the game clock at its spawn and the entities alive then (tr_ent born less gone) - to tell
-- what slows the later ones (VERIFY_PLAN 6.15: things left awake, or the season clock).
-- Prints "share pos boss clock0 game wall speed alive0 gaveup" a window.
for _, path in ipairs(arg) do
    local name = path:match("([^\\/]+)$")
    local alive, pos, cur = 0, 0, nil
    local function Out()
        if cur and cur.w1 > cur.w0 then
            print(string.format("%s %d %s %.0f %.0f %d %.1f %d %d", name, cur.pos, cur.boss, cur.t0, cur.t1 - cur.t0,
                cur.w1 - cur.w0, (cur.t1 - cur.t0) / (cur.w1 - cur.w0), cur.alive0, cur.gave))
        end
    end
    for line in io.lines(path) do
        local h, m, s, tag, t, rest = line:match("^%[(%d+):(%d+):(%d+)%]: %[(tr_%w+)%] ([%d.]+) (.*)")
        if h then
            local w, gt = h * 3600 + m * 60 + s, tonumber(t)
            if tag == "tr_ent" then
                if rest:sub(1, 5) == "born " then alive = alive + 1 elseif rest:sub(1, 5) == "gone " then alive = alive - 1 end
            elseif tag == "tr_bench" then
                local b = rest:match("^(%S+) spawned")
                if b then
                    Out()
                    pos = pos + 1
                    cur = { boss = b, pos = pos, t0 = gt, w0 = w, t1 = gt, w1 = w, alive0 = alive, gave = 0 }
                elseif cur and rest:find(" gave up", 1, true) then cur.gave = 1 end
            end
            if cur then cur.t1, cur.w1 = gt, w end
        end
    end
    Out()
end
