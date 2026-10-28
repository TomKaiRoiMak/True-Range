-- luajit move_state_check.lua <log>...: each move the drawer began ("[true_range] <boss> <move> ... began"),
-- against the state the server says it's in on the boss's next trace line: a move named a~b expects state b,
-- a plain one a state of its own name (or, those run from the game's "attack" state, attack). A move drawn for
-- a state it isn't - Uncompromising Mode's mouth-form shot drawn as the mouth charge - shows here and nowhere
-- else (no strike, no two shapes). The reviewer, 2026-10-18; VERIFY_PLAN 6.15.
-- Prints "<boss> drawn <move> for state <state>: n" for every pairing, MISMATCH first.
local pairs_n = {}
for _, path in ipairs(arg) do
    local pending = {}   -- boss -> move begun, waiting for its next trace line
    for line in io.lines(path) do
        local boss, move = line:match("%[true_range%] (%S+) (%S+) %(its size [^)]*%) began")
        if boss == nil then boss, move = line:match("%[true_range%] (%S+) (%S+) began") end
        if boss and move and not move:find(":", 1, true) then pending[boss] = move end
        local tb, st = line:match("%[tr_trace%] [%d%.]+ (%S+) after state=(%S+)")
        if tb and pending[tb] then
            local mv = pending[tb]
            pending[tb] = nil
            local key = tb .. "\t" .. mv .. "\t" .. st
            pairs_n[key] = (pairs_n[key] or 0) + 1
        end
    end
end
-- (moves are named by their first animation, "~state" added only when two share it - so a name says little
-- by itself: wrong only where the data has a move made for that very state (named it, or "~it") and another
-- was drawn instead)
DEGREES, FRAMES = math.pi / 180, 1 / 30
local names = {}
for _, f in ipairs({ [[D:\Work\Coding\dont starve\true_range\scripts\true_range\moves_sim.lua]],
    [[D:\Work\Coding\dont starve\true_range\scripts\true_range\moves_sim_um.lua]] }) do
    local ok, d = pcall(dofile, f)
    if ok then
        for boss, mv in pairs(d) do
            if boss:sub(1, 1) ~= "_" and type(mv) == "table" then
                names[boss] = names[boss] or {}
                for m in pairs(mv) do names[boss][m] = true end
            end
        end
    end
end
local function ForState(boss, st)
    for m in pairs(names[boss] or {}) do
        if m == st or m:match("~" .. st .. "$") or m:match("~" .. st .. "~%d+$") then return m end
    end
end
local out = {}
for key, n in pairs(pairs_n) do
    local boss, mv, st = key:match("^(.-)\t(.-)\t(.-)$")
    local better = ForState(boss, st)
    local ok = better == nil or better == mv or mv:match("~" .. st .. "$") ~= nil or mv:match("~" .. st .. "~%d+$") ~= nil
    out[#out + 1] = { ok = ok, boss = boss, mv = mv, st = st .. (ok and "" or (" (the data has " .. better .. ")")), n = n }
end
table.sort(out, function(a, b)
    if a.ok ~= b.ok then return not a.ok end
    if a.boss ~= b.boss then return a.boss < b.boss end
    return a.n > b.n
end)
for _, e in ipairs(out) do
    print(string.format("%s %s drawn %s for state %s: %d", e.ok and "ok      " or "MISMATCH", e.boss, e.mv, e.st, e.n))
end
