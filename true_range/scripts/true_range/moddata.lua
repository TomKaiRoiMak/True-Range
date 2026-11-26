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
    { names = { "workshop-1505270912" }, file = "true_range/moves_sim_te", label = "Tropical Experience",
        hand = "true_range/moves_hand_te" },
}

-- (a move written by hand as another's run offline, its frames moved on (copy = { prefab, move }, shift = frames, drop = { fields },
-- the rest laid over it) - Uncompromising Mode's ice hounds' spike line is the Glacial Hound's own (one IceSpike function),
-- shot at frame 24 of their quickattack, not 8. nil if that one isn't there)
function ModData.Copy(data, e)
    local src = data[e.copy[1]] ~= nil and data[e.copy[1]][e.copy[2]] or nil
    if type(src) ~= "table" then return nil end
    local shift = e.shift or 0
    local function Deep(t)
        local c = {}
        for f, x in pairs(t) do c[f] = type(x) == "table" and Deep(x) or x end
        return c
    end
    local n = Deep(src)
    for _, list in ipairs({ n.maps or {}, n.free or {} }) do
        for _, m in ipairs(list) do
            for _, s in ipairs(m.steps or {}) do s.at = (s.at or 0) + shift end
        end
    end
    -- (its other frames too - set_until left at 19, the line given over to its spikes as the first came up: each drawn only as
    -- it struck)
    for _, f in ipairs({ "first", "set_until", "lock" }) do
        if type(n[f]) == "number" then n[f] = n[f] + shift end
    end
    -- (at_each: its one strike made several, at these frames - UM's merm karate, atk_combo striking at 12, 18 and 31 as its
    -- atk does once, postinit/stategraphs/SGmerm.lua :65-95)
    if e.at_each ~= nil then
        for _, list in ipairs({ n.maps or {}, n.free or {} }) do
            for _, m in ipairs(list) do
                local one = m.steps ~= nil and m.steps[1] or nil
                if one ~= nil then
                    m.steps = {}
                    for i, at in ipairs(e.at_each) do
                        local s = Deep(one)
                        s.at = at
                        m.steps[i] = s
                    end
                end
            end
        end
        n.first = e.at_each[1]
    end
    -- (path_k = { from = frame, k = factor }: how far it goes after that frame, times that - UM's strong Deerclops' dash at
    -- walkspeed 20, run offline 1.1 a frame, in the game .78)
    if e.path_k ~= nil then
        for _, list in ipairs({ n.maps or {}, n.free or {} }) do
            for _, m in ipairs(list) do
                if type(m.path) == "string" then
                    local p = {}
                    for v in m.path:gmatch("[^,]+") do p[#p + 1] = tonumber(v) end
                    local base = p[e.path_k.from + 1]
                    if base ~= nil then
                        for i = e.path_k.from + 2, #p do p[i] = base + (p[i] - base) * e.path_k.k end
                        for i = 1, #p do p[i] = string.format("%.2f", p[i]) end
                        m.path = table.concat(p, ",")
                    end
                end
            end
        end
    end
    -- (ring_from = { at = frame, from = "free", ahead = units }: that frame's shape, as its first map in that list has it, laid
    -- that much on from where it is there, in every map - UM's strong Deerclops' blow at 70 round where its dash ends, run
    -- offline 10.84 on from where it began, in the game 7.84 on, whoever's where)
    if e.ring_from ~= nil then
        local rf = e.ring_from
        local src0 = (n[rf.from or "free"] or {})[1]
        local cells0 = nil
        for _, st in ipairs(src0 and src0.steps or {}) do if st.at == rf.at then cells0 = st.cells end end
        if cells0 ~= nil then
            local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"
            local digit = {}
            for i = 1, #B64 do digit[B64:byte(i)] = i - 1 end
            local pos, runs, row = 1, {}, -1
            local function Num()
                local v, scale = 0, 1
                while true do
                    local d = digit[cells0:byte(pos)] or 0
                    pos = pos + 1
                    v = v + (d % 32) * scale
                    if d < 32 then return v end
                    scale = scale * 32
                end
            end
            while pos <= #cells0 do
                row = row + Num()
                local k, last_end = Num(), -1
                for _ = 1, k do
                    local from = last_end + 1 + Num()
                    local to = from + Num()
                    runs[#runs + 1] = { row, from, to }
                    last_end = to
                end
            end
            local sa, sn = 0, 0
            for _, r in ipairs(runs) do sa, sn = sa + (r[2] + r[3]) * .5 * (r[3] - r[2] + 1), sn + r[3] - r[2] + 1 end
            local grid = data._grid or { ahead = -20, step = .25 }
            local shift = math.floor((rf.ahead - grid.ahead) / grid.step + .5) - math.floor(sa / sn + .5)
            local out = {}
            local function Put(v)
                repeat
                    local d = v % 32
                    v = (v - d) / 32
                    out[#out + 1] = B64:sub((v > 0 and d + 32 or d) + 1, (v > 0 and d + 32 or d) + 1)
                until v == 0
            end
            local last_row, i = -1, 1
            while i <= #runs do
                local j = i
                while j + 1 <= #runs and runs[j + 1][1] == runs[i][1] do j = j + 1 end
                Put(runs[i][1] - last_row)
                Put(j - i + 1)
                local last_end = -1
                for q = i, j do
                    local from, to = math.max(0, runs[q][2] + shift), math.max(0, runs[q][3] + shift)
                    Put(math.max(0, from - last_end - 1))
                    Put(to - from)
                    last_end = to
                end
                last_row, i = runs[i][1], j + 1
            end
            local cells = table.concat(out)
            for _, list in ipairs({ n.maps or {}, n.free or {} }) do
                for _, m in ipairs(list) do
                    for _, st in ipairs(m.steps or {}) do if st.at == rf.at then st.cells = cells end end
                end
            end
        end
    end
    for _, f in ipairs(e.drop or {}) do n[f] = nil end
    for f, x in pairs(e) do
        if f ~= "copy" and f ~= "shift" and f ~= "drop" and f ~= "at_each" and f ~= "path_k" and f ~= "ring_from" then n[f] = x end
    end
    return n
end

-- enabled: function(folder name) -> whether that mod is on. Returns the names of those laid over.
function ModData.Apply(enabled)
    -- (how long the moves data takes to load in the game's own Lua, and what it holds - said once: whether loading it boss by
    -- boss is worth it, told by the game, not by LuaJIT offline (77 ms, 19 MB there), 2026-10-28)
    local c0, m0 = os.clock(), collectgarbage("count")
    local was_loaded = package.loaded["true_range/moves_sim"] ~= nil
    local data = require("true_range/moves_sim")
    -- (the tables (docs/04-data-pipeline.md) were run with the game's code alone: a move the mod lays anew has none -
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
                            -- (copy_hazard: another thing's shape and steps, these fields over them - UM's Moon Tentacle mine as
                            -- Toadstool's bomb, smaller: 2026-10-30)
                            if k == "_hazards" and type(hv) == "table" and hv.copy_hazard ~= nil and type(data._hazards[hv.copy_hazard]) == "table" then
                                local function Deep(t) local c = {} for f, x in pairs(t) do c[f] = type(x) == "table" and Deep(x) or x end return c end
                                local nv = Deep(data._hazards[hv.copy_hazard])
                                for f, x in pairs(hv) do if f ~= "copy_hazard" then nv[f] = x end end
                                hv = nv
                            end
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
                        -- (and who's drawn as whom, by hand - each where the run's data says nothing: Uncompromising Mode's
                        -- shadow hound (rnehound) a hound in all but its looks, never found by the run)
                        if k == "_alias" and type(v) == "table" then
                            data._alias = data._alias or {}
                            for ak, av in pairs(v) do if data._alias[ak] == nil and data[ak] == nil then data._alias[ak] = av end end
                        -- (and things written by hand - each where the run's data has none)
                        elseif k == "_hazards" and type(v) == "table" then
                            data[k] = data[k] or {}
                            for hk, hv in pairs(v) do
                                -- (copy_hazard, as above: a hand file's thing made from another's shape)
                                if type(hv) == "table" and hv.copy_hazard ~= nil and type(data[k][hv.copy_hazard]) == "table" then
                                    local function Deep(t) local c = {} for f, x in pairs(t) do c[f] = type(x) == "table" and Deep(x) or x end return c end
                                    local nv = Deep(data[k][hv.copy_hazard])
                                    for f, x in pairs(hv) do if f ~= "copy_hazard" then nv[f] = x end end
                                    hv = nv
                                end
                                -- (or over the run's own, said so (replace) - a ring run offline a little short)
                                if data[k][hk] == nil or (type(hv) == "table" and hv.replace) then data[k][hk] = hv end
                            end
                        elseif type(k) == "string" and k:sub(1, 1) ~= "_" and type(v) == "table" then
                            -- (one drawn as another (_alias - an ice hound as a hound) given a move of its own: the other's moves
                            -- first, as its own - else it'd have only the one)
                            local al = data._alias ~= nil and data._alias[k] or nil
                            if data[k] == nil and al ~= nil and type(data[al]) == "table" then
                                data[k] = {}
                                for mv2, e2 in pairs(data[al]) do data[k][mv2] = e2 end
                            end
                            data[k] = data[k] or {}
                            for mv, e in pairs(v) do
                                if type(e) == "table" and e.copy ~= nil then e = ModData.Copy(data, e) end
                                -- (or a move it hasn't, said false - one it has only by being drawn as another (_alias))
                                if e == false then
                                    data[k][mv] = nil
                                    if tables[k] ~= nil then tables[k][mv] = nil end
                                elseif e ~= nil and (data[k][mv] == nil or e.replace) then
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
