-- Monsters a mod changes or adds: their moves as run offline with the mod on (true_range_workshop/
-- tools/sim_moves.lua with SIM_MOD - tools/sim_mods/<mod>.lua), laid over the game's own
-- (true_range/moves_sim) when that mod is on. The same table every part of the mod reads - required
-- once, kept: changed in place here, before any of it is drawn.
local ModData = {}

-- (each: its folder names - the Workshop's; the file of its moves; its name, to say)
local MODS = {
    -- (the beta (3193922031) and the regular one (2039181790) alike: the beta's moves for both - the player's call,
    -- 2026-10-22, once a build of the regular one's own came out with its own faults)
    { names = { "workshop-3193922031", "workshop-2039181790" }, file = "true_range/moves_sim_um", label = "Uncompromising Mode",
        -- (and its moves written by hand - each where the run's data has none: kept through a rebuild)
        hand = "true_range/moves_hand_um" },
    -- (Tropical Experience - Shipwrecked's and Hamlet's monsters: true_range_workshop/tools/build_te.ps1)
    { names = { "workshop-1505270912" }, file = "true_range/moves_sim_te", label = "Tropical Experience" },
}

-- enabled: function(folder name) -> whether that mod is on. Returns the names of those laid over.
function ModData.Apply(enabled)
    -- (how long the moves data takes to load in the game's own Lua, and what it holds - said once: whether loading it boss by
    -- boss is worth it, told by the game, not by LuaJIT offline (77 ms, 19 MB there), 2026-10-28)
    local c0, m0 = os.clock(), collectgarbage("count")
    local was_loaded = package.loaded["true_range/moves_sim"] ~= nil
    local data = require("true_range/moves_sim")
    -- (REDESIGN.md's tables were run with the game's code alone: a move the mod lays anew has none -
    -- the game's table drawn for the mod's move was the game's blow, not the mod's: UM Treeguard's
    -- cone drawn all round, 2026-10-18)
    local tab_ok, tables = pcall(require, "true_range/moves_table")
    if not tab_ok or type(tables) ~= "table" then tables = {} end
    local applied = {}
    for _, m in ipairs(MODS) do
        local on = false
        for _, n in ipairs(m.names) do
            if enabled(n) then on = true end
        end
        if on then
            local ok, add = pcall(require, m.file)
            if ok and type(add) == "table" then
                local whole = add._replace or {}
                for k, v in pairs(add) do
                    -- (what things set off, and who's drawn as whom: added to, the mod's over the game's)
                    if k == "_hazards" or k == "_alias" then
                        data[k] = data[k] or {}
                        for hk, hv in pairs(v) do
                            -- (a thing set off by the game's bosses and the mod's: whose it is, both - its
                            -- own boss near is what lets it be drawn alone (true_range/predict): the
                            -- Mutated Deerclops' laser, the mod's Deerclops' too)
                            local was = data[k][hk]
                            if k == "_hazards" and type(was) == "table" and type(hv) == "table" and was.by ~= nil then
                                local nv, by, seen = {}, {}, {}
                                for f, x in pairs(hv) do nv[f] = x end
                                for _, list in ipairs({ hv.by or {}, was.by }) do
                                    for _, b in ipairs(list) do if not seen[b] then seen[b] = true by[#by + 1] = b end end
                                end
                                nv.by = by
                                hv = nv
                            end
                            data[k][hk] = hv
                        end
                    -- (a monster whose moves the mod sets out anew - Deerclops' mutations: all of them in
                    -- place of the game's)
                    elseif type(k) == "string" and k:sub(1, 1) ~= "_" and (whole[k] or data[k] == nil) then
                        data[k] = v
                        tables[k] = nil
                    -- (else move by move: only those it changes or adds - the rest the game's own)
                    elseif type(k) == "string" and k:sub(1, 1) ~= "_" then
                        for mv, m in pairs(v) do
                            data[k][mv] = m
                            if tables[k] ~= nil then tables[k][mv] = nil end
                        end
                    end
                end
                applied[#applied + 1] = m.label
            end
            if m.hand ~= nil then
                local hok, hand = pcall(require, m.hand)
                if hok and type(hand) == "table" then
                    for k, v in pairs(hand) do
                        -- (and things written by hand - each where the run's data has none)
                        if k == "_hazards" and type(v) == "table" then
                            data[k] = data[k] or {}
                            for hk, hv in pairs(v) do
                                if data[k][hk] == nil then data[k][hk] = hv end
                            end
                        elseif type(k) == "string" and k:sub(1, 1) ~= "_" and type(v) == "table" then
                            data[k] = data[k] or {}
                            for mv, e in pairs(v) do
                                if data[k][mv] == nil then
                                    data[k][mv] = e
                                    if tables[k] ~= nil then tables[k][mv] = nil end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    print(string.format("[true_range] moves data loaded in %.0f ms, %.1f MB of Lua memory (moves_sim %s), Lua memory now %.1f MB",
        (os.clock() - c0) * 1000, (collectgarbage("count") - m0) / 1024, was_loaded and "loaded before" or "loaded here",
        collectgarbage("count") / 1024))
    return applied
end

return ModData
