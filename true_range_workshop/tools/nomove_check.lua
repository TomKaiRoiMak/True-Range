-- luajit tools/nomove_check.lua <mod root> <log> [log ...] > out
-- The other way round from every replay check: not "what we draw, was it right" but "what the game played - is
-- there anything of ours for it at all". Each monster traced ([tr_trace]), each animation it played: one it struck
-- you in (STRIKE), or named like a blow, with no move in the data (moves_sim, moves_sim_um, moves_hand, by _alias)
-- having that animation - nothing could ever be drawn for it, and no other check looks (they all start from the
-- data). The plain spider's leap (Uncompromising Mode's "alljumperspiders"): 319 frames on the bench, never drawn,
-- unseen till the player met it, 2026-10-20.
-- Prints: NOMOVE <monster> <animation> (<state>): <frames> frames, <strikes> strikes - one line each, worst first.
local ROOT = arg[1]
local function Load(name)
    local ok, t = pcall(dofile, ROOT .. "/scripts/true_range/" .. name .. ".lua")
    return ok and type(t) == "table" and t or {}
end
local data = { Load("moves_sim"), Load("moves_sim_um"), Load("moves_hand"), Load("moves_hand_um") }
-- (NOMOVE_TE=1: Tropical Experience's too - for its bench's logs, not the others': its changes aren't theirs)
if os.getenv("NOMOVE_TE") then data[#data + 1] = Load("moves_sim_te") end
local alias = {}
for _, d in ipairs(data) do for k, v in pairs(d._alias or {}) do alias[k] = v end end
-- (monster -> animation -> true: every animation any of its moves plays)
local known = {}
for _, d in ipairs(data) do
    for boss, moves in pairs(d) do
        if type(boss) == "string" and boss:sub(1, 1) ~= "_" and type(moves) == "table" then
            known[boss] = known[boss] or {}
            for _, e in pairs(moves) do
                if type(e) == "table" then
                    for _, a in ipairs(e.anims or {}) do known[boss][a] = true end
                    if e.leg ~= nil and e.leg.anim ~= nil then known[boss][e.leg.anim] = true end
                end
            end
        end
    end
end
-- (named like a blow - not getting about, being hit, dying)
local BLOW = { "atk", "attack", "leap", "jump", "pounce", "slam", "bite", "chomp", "charge", "spit", "shoot", "swipe", "stomp",
    "throw", "lunge", "dash", "spin", "pound", "smash", "stab", "slash", "roar", "breath", "beam", "laser", "tackle", "ram" }
local NOT_BLOW = { "hit", "death", "dead", "walk", "run", "idle", "sleep", "taunt_pst", "spawn", "despawn", "emerge", "eat" }
local function Blowlike(a)
    a = a:lower()
    for _, w in ipairs(NOT_BLOW) do if a == w or a:find("^" .. w .. "_") or a:find("_" .. w .. "$") then return false end end
    for _, w in ipairs(BLOW) do if a:find(w, 1, true) then return true end end
    return false
end
local seen = {}   -- key "monster anim" -> { frames, strikes, state }
for i = 2, #arg do
    for line in io.lines(arg[i]) do
        if line:find("[tr_trace]", 1, true) then
            local who, rest = line:match("%[tr_trace%] [%d%.]+ ([%w_]+) (.*)$")
            if who ~= nil then
                local anim = rest:match(" anim=([%w_]+)")
                local state = rest:match("state=([%w_]+)")
                if anim ~= nil then
                    local k = who .. " " .. anim
                    local s = seen[k]
                    if s == nil then s = { frames = 0, strikes = 0, state = state, who = who, anim = anim } seen[k] = s end
                    if rest:find("^after ") then s.frames = s.frames + 1 end
                    if rest:find("^STRIKE ") then s.strikes = s.strikes + 1 end
                end
            end
        end
    end
end
local out = {}
for _, s in pairs(seen) do
    local b = s.who
    local k = known[b] or (alias[b] and known[alias[b]]) or {}
    if not k[s.anim] and (s.strikes > 0 or Blowlike(s.anim) or Blowlike(s.state or "")) then out[#out + 1] = s end
end
table.sort(out, function(a, b) if a.strikes ~= b.strikes then return a.strikes > b.strikes end return a.frames > b.frames end)
for _, s in ipairs(out) do
    print(string.format("NOMOVE %s %s (%s): %d frames, %d strikes%s", s.who, s.anim, tostring(s.state), s.frames, s.strikes,
        known[s.who] == nil and (alias[s.who] == nil) and " - no data for it at all" or ""))
end
print(string.format("NOMOVES: %d animations played with nothing of ours for them", #out))
