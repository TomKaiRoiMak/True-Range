-- luajit tools/lag_report.lua <client_log.txt> [server_log.txt]: the lag mode's run (tools/run_lag.ps1, VERIFY_PLAN 6.20)
-- read from your game's side - each blow and each drawn-in-not-struck in the scene it came in, that scene's Lag
-- Compensation on or off (tr_lagjoin "[tr_lag] ... scene n= pred="):
--   struck      blows the server told of in scenes
--   drawn in    of those, you stood in what True Range drew just then (on your screen) - "drawn: in"
--   NOT drawn   struck where nothing was drawn under you on your screen - the one lag compensation makes worse
--   false       you stood in a part drawn striking and weren't struck ("drawn IN but NOT struck")
--   lead        how far your game had you from where the server had you as each blow's word came (median / most)
-- With the server's log: its own count of blows, to see none went untold.
local cpath, spath = arg[1], arg[2]
assert(cpath, "usage: luajit lag_report.lua <client_log> [server_log]")

local by = { [0] = { struck = 0, inn = 0, notd = 0, false_ = 0, leads = {}, scenes = 0, out = 0 },
    [1] = { struck = 0, inn = 0, notd = 0, false_ = 0, leads = {}, scenes = 0, out = 0 } }
local scene, pred = nil, nil
local outside = { struck = 0, false_ = 0 }
local per_boss = {}
local effects = nil
local boss = nil
local notes = {}
-- (ahead: struck NOT drawn while your game had you over AHEAD_D on from where the server had you - a lag spike, you
-- run on in your own game while the server strikes you where you were; the ring is where it is, you aren't. Moonmaw's
-- lavae, 2026-10-29_1230: 8 of 15 at 3.6 on, 6 at 1.2 - against 0 of 78 the same code at 0945)
local AHEAD_D = tonumber(os.getenv("AHEAD_D") or "") or 2
local last_lead = nil
for line in io.lines(cpath) do
    local n, p, b = line:match("%[tr_lag%] [%d.]+ scene n=(%d+) .- pred=(%d) boss=(%S+)")
    if n ~= nil then
        scene, pred, boss = tonumber(n), tonumber(p), b
        by[pred].scenes = by[pred].scenes + 1
    elseif line:match("%[tr_lag%] [%d.]+ you n=") then
        local gap, speed, gp = line:match("gap=([%d.]+) speed=([%d.]+) pred=(%d)")
        if gap ~= nil and tonumber(speed) > 1 then
            local t = by[tonumber(gp)]
            t.gaps = t.gaps or {}
            t.gaps[#t.gaps + 1] = tonumber(gap)
        end
    elseif line:match("%[tr_lag%] [%d.]+ end n=") then
        -- (kept till the next begins: "drawn IN but NOT struck" is said .4 s on, often after the end)
    else
        local lead, lp = line:match("%[tr_lag%] [%d.]+ struck by .- lead=([%d.]+) pred=(%d)")
        if lead ~= nil and scene ~= nil then
            local t = by[pred]
            t.leads[#t.leads + 1] = tonumber(lead)
        end
        if lead ~= nil then last_lead = tonumber(lead) end
        local drawn = line:match("%[true_range%] you were struck.- drawn: (%a+)")
        -- (struck from its own middle: worn on you - the Hound Batilisk as a hat biting every 0.6 s, as replay.lua's WORN;
        -- 832 of bat_boss's 1107 "struck" on 2026-10-26. Worn, your game keeps it where it was put on - the same "from it"
        -- each bite while you walk on (492.80 242 times), so: under .1, or not drawn just as far as its last blow with
        -- nothing drawn since (age on by .3 at least) or further than any blow reaches (20). Not just the same distance:
        -- scenes come again the same - the Shrouded Queen's vines struck 8.20 from her three times, 2026-10-26.
        -- OLD_WORN=1: counted)
        local who, from = line:match("by ([^,]+), ([%d.%-]+) from it")
        from = tonumber(from)
        local age = tonumber(line:match("age=([%d.]+)"))
        outside.last = outside.last or {}
        local last = who ~= nil and outside.last[who] or nil
        -- (gone from your game - "?", -1.00 - the same, bitten on every .6 s)
        -- (only not drawn: a spike under you or the Abomination over you are drawn, 0.00 from them. Also swallowed: the
        -- Shadow Thrall horns chewing you (SGshadowthrall_horns devoured, DoChew), 0.00 from you - nothing to warn of then)
        -- (a newer log says so itself: "(worn)", in your inventory as it struck)
        local worn = (drawn ~= nil and line:match("struck.- %(worn%) by") ~= nil) or drawn ~= nil and drawn ~= "in" and from ~= nil
            and ((from >= 0 and from < .1) or (last ~= nil and math.abs(from - last.from) < .005
                and (from > 20 or (age ~= nil and last.age ~= nil and (age > last.age + .3 or age >= 99)))))
        if drawn ~= nil and who ~= nil then outside.last[who] = { from = from, age = age } end
        if worn and not os.getenv("OLD_WORN") then
            outside.worn = (outside.worn or 0) + 1
            drawn = nil
        elseif drawn ~= nil then
            if scene == nil then
                outside.struck = outside.struck + 1
            else
                local t = by[pred]
                t.struck = t.struck + 1
                if drawn == "in" then t.inn = t.inn + 1 else t.notd = t.notd + 1 end
                -- (strict: out of it longer than a frame and a half as the word came - "in" takes .15 s back)
                local age = tonumber(line:match("age=([%d.]+)"))
                if age ~= nil then
                    t.aged = (t.aged or 0) + 1
                    if age > .05 then t.strict = (t.strict or 0) + 1 end
                end
                local k = boss .. " pred=" .. pred
                per_boss[k] = per_boss[k] or { struck = 0, notd = 0, false_ = 0 }
                per_boss[k].struck = per_boss[k].struck + 1
                if drawn ~= "in" then
                    per_boss[k].notd = per_boss[k].notd + 1
                    if last_lead ~= nil and last_lead > AHEAD_D then per_boss[k].ahead = (per_boss[k].ahead or 0) + 1 end
                end
            end
        elseif line:match("%[true_range%] drawn IN but NOT struck") then
            if scene == nil then
                outside.false_ = outside.false_ + 1
            else
                local t = by[pred]
                t.false_ = t.false_ + 1
                local k = boss .. " pred=" .. pred
                per_boss[k] = per_boss[k] or { struck = 0, notd = 0, false_ = 0 }
                per_boss[k].false_ = per_boss[k].false_ + 1
            end
        elseif line:match("%[true_range%] you were (%a+ ?%a*) %- drawn: ") then
            -- (frozen, set alight, knocked back - no blow told: true_range modmain's EFFECTS, 2026-10-27)
            local kind, d = line:match("%[true_range%] you were (%a+ ?%a*) %- drawn: (%a+)")
            local k = (boss or "-") .. " pred=" .. tostring(pred) .. " " .. kind
            effects = effects or {}
            effects[k] = effects[k] or { n = 0, notd = 0 }
            effects[k].n = effects[k].n + 1
            if d ~= "in" then effects[k].notd = effects[k].notd + 1 end
        elseif line:match("LUA ERROR") or line:match("%[tr_lag%] [%d.]+ scene n=%d+ let go") then
            notes[#notes + 1] = line
        end
    end
end

if effects ~= nil then
    local ks = {}
    for k in pairs(effects) do ks[#ks + 1] = k end
    table.sort(ks)
    print("effects (not blows): boss pred kind | times | NOT drawn")
    for _, k in ipairs(ks) do print(string.format("  %-44s %4d  NOT drawn %4d", k, effects[k].n, effects[k].notd)) end
end
local function Med(l)
    if #l == 0 then return "-", "-" end
    table.sort(l)
    return string.format("%.2f", l[math.floor((#l + 1) / 2)]), string.format("%.2f", l[#l])
end
print("lag compensation | scenes | struck | drawn in | NOT drawn | false | lead median / most")
for _, k in ipairs({ 1, 0 }) do
    local t = by[k]
    local m, mx = Med(t.leads)
    print(string.format("%-16s | %6d | %6d | %8d | %9d | %5d | %s / %s", k == 1 and "on (Predictive)" or "off (None)", t.scenes, t.struck, t.inn, t.notd, t.false_, m, mx))
end
for _, k in ipairs({ 1, 0 }) do
    local t = by[k]
    if (t.aged or 0) > 0 then
        print(string.format("strict, %s: %d of %d struck out of the drawn part for over .05 s", k == 1 and "on" or "off", t.strict or 0, t.aged))
    end
end
print(string.format("before the first scene: struck %d, false %d", outside.struck, outside.false_))
if (outside.worn or 0) > 0 then print(string.format("worn on you (not counted): %d", outside.worn)) end
-- (moving only, over 1 a second: screen vs server, as each of the server's words comes)
for _, k in ipairs({ 1, 0 }) do
    local g = by[k].gaps or {}
    if #g > 0 then
        table.sort(g)
        print(string.format("gap while moving, %s: median %.2f, 90%% %.2f, most %.2f (%d samples)", k == 1 and "on" or "off",
            g[math.floor((#g + 1) / 2)], g[math.max(1, math.floor(#g * .9))], g[#g], #g))
    end
end
local keys = {}
for k in pairs(per_boss) do keys[#keys + 1] = k end
table.sort(keys)
for _, k in ipairs(keys) do
    local t = per_boss[k]
    print(string.format("  %-34s struck %4d  NOT drawn %4d  false %4d%s", k, t.struck, t.notd, t.false_,
        (t.ahead or 0) > 0 and string.format("  (ahead %d)", t.ahead) or ""))
end
for _, l in ipairs(notes) do print("  note: " .. l) end
if spath ~= nil then
    local f = io.open(spath, "r")
    if f ~= nil then
        local n = 0
        for line in f:lines() do if line:match("%[tr_lag%] [%d.]+ srv struck") then n = n + 1 end end
        f:close()
        print(string.format("server: %d blows told", n))
    end
end
