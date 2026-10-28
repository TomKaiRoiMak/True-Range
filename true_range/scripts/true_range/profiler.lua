-- (testing, to be removed) Where the game's Lua time goes - F7 in true_range modmain, on and off.
-- Every EVERY Lua instructions, the time since the last look is put down to the function running
-- now (its file and where it begins) - what it called in the game's own code, and what ran between,
-- with it. Added up, the top ones in client_log.txt ("[tr_prof]") every REPORT seconds: by
-- function, and by mod (or the game). The clock is to the ms: each look's share is mostly 0 or 1,
-- right over thousands of looks. Slows the game while on - by how much, said too.
local Profiler = {}

local EVERY = 1000   -- Lua instructions between looks
local REPORT = 10    -- seconds
local SHOW = 25

local by_fn = {}
-- (the mod's own functions, with all they called: each look's time to every one of ours in the
-- stack, once - which of ours the time went under, the game's own calls included (lines.lua's
-- Take, called from where?))
local incl = {}
local seen_look = {}
local names = setmetatable({}, { __mode = "k" })  -- (function -> its file:line)
local last, started, reported, looks = 0, nil, nil, 0
local on = false

local function ModOf(src)
    local m = src:match("mods[/\\]([^/\\]+)[/\\]")
    if m ~= nil then return m end
    if src:find("scripts/") or src:find("scripts\\") or src:find("^%[string") then return "game" end
    return "other"
end

-- (whether a function is the mod's own - its file under mods/<this mod>, worked out once; the
-- folder from this file's own - the Workshop's copy is "workshop-<id>")
local MOD_DIR = (debug.getinfo(1, "S").source or ""):match("(mods[/\\][^/\\]+[/\\])") or "true_range"
local ours = setmetatable({}, { __mode = "k" })
local function Ours(f)
    local v = ours[f]
    if v == nil then
        local info = debug.getinfo(f, "S")
        v = info ~= nil and info.source ~= nil and info.source:find(MOD_DIR, 1, true) ~= nil and true or false
        ours[f] = v
    end
    return v
end

local function Look()
    local now = os.clock()
    local d = now - last
    last = now
    looks = looks + 1
    -- (by the function itself - its name and file worked out once, at the report)
    local info = debug.getinfo(2, "f")
    if info == nil or info.func == nil then return end
    local f = info.func
    by_fn[f] = (by_fn[f] or 0) + d
    for k in pairs(seen_look) do seen_look[k] = nil end
    for level = 2, 30 do
        local fi = debug.getinfo(level, "f")
        if fi == nil then break end
        local g = fi.func
        if g ~= nil and not seen_look[g] and Ours(g) then
            seen_look[g] = true
            incl[g] = (incl[g] or 0) + d
        end
    end
end
-- (a function's file and where it begins, and its name if it has one in its file)
local function KeyOf(f)
    local key = names[f]
    if key == nil then
        local info = debug.getinfo(f, "S")
        key = info ~= nil and (info.short_src .. ":" .. (info.linedefined or 0)) or "?"
        names[f] = key
    end
    return key
end

local function Report(seconds)
    local fns, mods, total = {}, {}, 0
    local merged = {}
    for f, t in pairs(by_fn) do
        local key = KeyOf(f)
        merged[key] = (merged[key] or 0) + t
    end
    for key, t in pairs(merged) do
        fns[#fns + 1] = { key, t }
        local m = ModOf(key)
        mods[m] = (mods[m] or 0) + t
        total = total + t
    end
    table.sort(fns, function(a, b) return a[2] > b[2] end)
    local ml = {}
    for m, t in pairs(mods) do ml[#ml + 1] = { m, t } end
    table.sort(ml, function(a, b) return a[2] > b[2] end)
    print(string.format("[tr_prof] %.0fs: %.0f ms of Lua a second (%d looks)", seconds, total * 1000 / seconds, looks))
    for i = 1, math.min(#ml, 8) do
        print(string.format("[tr_prof]   %-28s %7.1f ms/s  %4.1f%%", ml[i][1], ml[i][2] * 1000 / seconds, ml[i][2] / math.max(1e-9, total) * 100))
    end
    for i = 1, math.min(#fns, SHOW) do
        print(string.format("[tr_prof]   %7.1f ms/s %4.1f%%  %s", fns[i][2] * 1000 / seconds, fns[i][2] / math.max(1e-9, total) * 100, fns[i][1]))
    end
    -- (ours, with what they called)
    local il = {}
    for f, t in pairs(incl) do il[#il + 1] = { KeyOf(f), t } end
    table.sort(il, function(a, b) return a[2] > b[2] end)
    for i = 1, math.min(#il, 20) do
        print(string.format("[tr_prof] ours+  %7.1f ms/s %4.1f%%  %s", il[i][2] * 1000 / seconds, il[i][2] / math.max(1e-9, total) * 100, il[i][1]))
    end
    by_fn, incl, looks = {}, {}, 0
end

function Profiler.Toggle(inst)
    if debug == nil or debug.sethook == nil then
        print("[tr_prof] can't look here")
        return false
    end
    on = not on
    if on then
        started, reported, last, looks = os.clock(), os.clock(), os.clock(), 0
        by_fn = {}
        debug.sethook(Look, "", EVERY)
        if Profiler.task == nil then
            Profiler.task = inst:DoStaticPeriodicTask(1, function()
                if not on then return end
                local now = os.clock()
                if now - reported >= REPORT then
                    -- (not looked at while reporting)
                    debug.sethook()
                    Report(now - reported)
                    reported = os.clock()
                    last = reported
                    debug.sethook(Look, "", EVERY)
                end
            end)
        end
        print("[tr_prof] on")
    else
        debug.sethook()
        print("[tr_prof] off")
    end
    return on
end

return Profiler
