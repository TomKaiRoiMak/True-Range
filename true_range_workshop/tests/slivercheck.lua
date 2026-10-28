-- luajit slivercheck.lua <mod root> [-v]
-- Every move run offline, every distance: the parts it's drawn in, as they're shown one beside the
-- other (each part struck a frame or two after the one before shown with it - SimMoves'
-- clusters), looked at for what shows as a jagged edge in the game:
--   SLIVER: a part (6 cells or more) two cells thick at most - a rim round an earlier one,
--           a different colour along its edge: yellow slivers and notches (Armored Bearger's swipe)
--   SPIKE:  cells of a part sticking out on their own into another (3 of their 4 sides not it) -
--           a notch in the line between them
-- Prints each, and the counts: "slivers N, spikes N".
package.path = arg[1] .. "/scripts/?.lua;" .. package.path
DEGREES, FRAMES = math.pi / 180, 1 / 30
GetTime = function() return 0 end
GetStaticTime = GetTime
local verbose = arg[2] == "-v"
local SimMoves = require("true_range/simmoves")
local MapSteps = SimMoves._MapSteps
local M = require("true_range/moves_sim")
local function K(r, c) return r * 1000 + c end
local function RC(k) local r = math.floor((k + 500) / 1000) return r, k - r * 1000 end

local slivers, spikes, looked = 0, 0, 0
local bosses = {}
for b in pairs(M) do bosses[#bosses + 1] = b end
table.sort(bosses)
for _, boss in ipairs(bosses) do
    local moves = M[boss]
    local names = {}
    if type(moves) == "table" then for n in pairs(moves) do names[#names + 1] = n end end
    table.sort(names)
    for _, name in ipairs(names) do
        local e = moves[name]
        local said = {}
        for _, list in ipairs({ type(e) == "table" and e.maps or {}, type(e) == "table" and e.free or {} }) do
            for _, m in ipairs(list) do
                if m.steps ~= nil and not e.random then
                    looked = looked + 1
                    -- (the parts as shown: as the mod itself groups them - SimMoves' MapSteps)
                    local groups, by = {}, {}
                    local steps = MapSteps({ of = { raw = m } })
                    for _, s in ipairs(steps) do
                        local c = s.cl or s
                        if by[c] == nil then
                            by[c] = { at = c.at, cells = {} }
                            groups[#groups + 1] = by[c]
                        end
                        for k in pairs(s.cells) do by[c].cells[k] = true end
                    end
                    -- (each part: its cells not in an earlier one - shown in its own colour beside it)
                    local before = {}
                    for gi, g in ipairs(groups) do
                        local own, n = {}, 0
                        for k in pairs(g.cells) do if not before[k] then own[k] = true n = n + 1 end end
                        if gi > 1 and n >= 6 then
                            local thin, spike = 0, 0
                            for k in pairs(own) do
                                local r, c = RC(k)
                                local l, rt, u, d = own[K(r, c - 1)], own[K(r, c + 1)], own[K(r - 1, c)], own[K(r + 1, c)]
                                if not (l and rt and u and d) then thin = thin + 1 end
                                local sides = (l and 1 or 0) + (rt and 1 or 0) + (u and 1 or 0) + (d and 1 or 0)
                                -- (sticking out into an earlier part - not the move's own outside edge)
                                if sides <= 1 then
                                    local into = 0
                                    for _, q in ipairs({ K(r, c - 1), K(r, c + 1), K(r - 1, c), K(r + 1, c) }) do
                                        if before[q] then into = into + 1 end
                                    end
                                    if into >= 2 then spike = spike + 1 end
                                end
                            end
                            local key = string.format("%s %s part at %d", boss, name, g.at)
                            if thin >= .85 * n and not said["s" .. g.at] then
                                said["s" .. g.at] = true
                                slivers = slivers + 1
                                print(string.format("SLIVER  %s (dist %s): %d of its %d cells on its edge (two cells thick at most) - a rim round the part before", key, tostring(m.dist), thin, n))
                            end
                            if spike > 0 then
                                spikes = spikes + spike
                                if verbose or not said["p" .. g.at] then
                                    said["p" .. g.at] = true
                                    print(string.format("SPIKE   %s (dist %s): %d cells sticking out into the part before", key, tostring(m.dist), spike))
                                end
                            end
                        end
                        for k in pairs(g.cells) do before[k] = true end
                    end
                end
            end
        end
    end
end
print(string.format("looked at %d maps: slivers %d, spikes %d", looked, slivers, spikes))
