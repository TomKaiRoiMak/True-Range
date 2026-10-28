-- (testing, to be removed) Who makes Lua's garbage: every few thousand Lua instructions, how
-- much Lua memory grew since the last look is put down to the file running now - added up per
-- mod and per file, the top ones in client_log.txt ("[tr_alloc]") every REPORT seconds, for
-- WATCH seconds. A drop (the collector at work) is left out; what this itself makes is too.
local AllocWatch = {}

local EVERY = 2000      -- Lua instructions between looks
local REPORT = 20       -- seconds
local WATCH = 240       -- seconds
local SHOW = 12

local by_file, by_mod = {}, {}
local last = 0
local started, reported = nil, nil

local function ModOf(src)
    local m = src:match("mods[/\\]([^/\\]+)[/\\]")
    if m ~= nil then return m end
    if src:find("^%[string") or src:find("scripts/") or src:find("scripts\\") then return "game" end
    return "other: " .. src
end

local function Look()
    local now = collectgarbage("count")
    local d = now - last
    if d > 0 then
        local info = debug.getinfo(2, "S")
        local src = info ~= nil and info.short_src or "?"
        by_file[src] = (by_file[src] or 0) + d
    end
    -- (what this look made itself: not counted)
    last = collectgarbage("count")
end

local function Report(seconds)
    local files = {}
    for src, kb in pairs(by_file) do
        files[#files + 1] = { src, kb }
        local m = ModOf(src)
        by_mod[m] = (by_mod[m] or 0) + kb
    end
    table.sort(files, function(a, b) return a[2] > b[2] end)
    local mods = {}
    for m, kb in pairs(by_mod) do mods[#mods + 1] = { m, kb } end
    table.sort(mods, function(a, b) return a[2] > b[2] end)
    local total = 0
    for _, m in ipairs(mods) do total = total + m[2] end
    print(string.format("[tr_alloc] %.0fs: %.0f KB/s made in all (main thread)", seconds, total / seconds))
    for i = 1, math.min(#mods, 8) do
        print(string.format("[tr_alloc]   mod %-28s %7.0f KB/s  %4.1f%%", mods[i][1], mods[i][2] / seconds, mods[i][2] / math.max(1, total) * 100))
    end
    for i = 1, math.min(#files, SHOW) do
        print(string.format("[tr_alloc]   file %7.0f KB/s  %s", files[i][2] / seconds, files[i][1]))
    end
    by_file, by_mod = {}, {}
end

function AllocWatch.Start(inst)
    if debug == nil or debug.sethook == nil then
        print("[tr_alloc] can't watch here")
        return
    end
    started, reported = os.clock(), os.clock()
    last = collectgarbage("count")
    debug.sethook(Look, "", EVERY)
    local task
    task = inst:DoStaticPeriodicTask(1, function()
        local now = os.clock()
        if now - reported >= REPORT then
            Report(now - reported)
            reported = now
        end
        if now - started >= WATCH then
            debug.sethook()
            print("[tr_alloc] stopped")
            task:Cancel()
            return
        end
    end)
    print(string.format("[tr_alloc] watching who makes garbage for %ds", WATCH))
end

return AllocWatch
