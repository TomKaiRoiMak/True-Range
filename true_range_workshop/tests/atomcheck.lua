-- luajit atomcheck.lua <mod root> [prefab move]: every move's pieces - triangles off their piece,
-- areas that don't add up, and how long making them takes
package.path = arg[1] .. "/scripts/?.lua;" .. package.path
DEGREES, FRAMES = math.pi / 180, 1 / 30
GetTime = function() return 0 end
package.loaded["true_range/lines"] = { Begin = function() end, End = function() end, Pulse = function() end,
    Segment = function() end, Disc = function() end, Wedge = function() end, Tri = function() end, _styles = {} }
local SimMoves = require("true_range/simmoves")
local Data = require("true_range/moves_sim")
local T = SimMoves._test
local prof, last = {}, os.clock()
SimMoves._mark = function(k) local n = os.clock() prof[k] = (prof[k] or 0) + n - last last = n end
local maps, bad, n_tri, worst = 0, 0, 0, 0
local t0 = os.clock()
local area_off = 0
for prefab, moves in pairs(Data) do
    if prefab:sub(1, 1) ~= "_" and (arg[2] == nil or prefab == arg[2]) then
        for name, e in pairs(moves) do
            if arg[3] == nil or name == arg[3] then
                for di, m in ipairs(e.maps or {}) do
                    if not m.same and m.steps then
                        local owner = {}
                        for _, s in ipairs(m.steps) do owner[#owner + 1] = { cells = T.Unpack(s.cells or "").cells } end
                        local c0 = os.clock() last = c0
                        local A = SimMoves._Atoms(owner)
                        worst = math.max(worst, os.clock() - c0)
                        maps = maps + 1
                        -- (all pieces' area against the cells')
                        local cells_n, area = 0, 0
                        local all = {}
                        for _, o in ipairs(owner) do for k in pairs(o.cells) do all[k] = true end end
                        for _ in pairs(all) do cells_n = cells_n + 1 end
                        for l, atom in ipairs(A.atoms) do
                            for _, t in ipairs(atom.tris) do
                                n_tri = n_tri + 1
                                area = area + math.abs((t[3] - t[1]) * (t[6] - t[2]) - (t[4] - t[2]) * (t[5] - t[1])) / 2
                                -- (each corner near a cell of the move)
                                for q = 0, 2 do
                                    local cx, cy = t[1 + 2 * q], t[2 + 2 * q]
                                    local near = false
                                    for dr = -1, 1 do for dc = -1, 1 do
                                        if all[math.floor(cy + .5 + dr) * 1000 + math.floor(cx + .5 + dc)] then near = true end
                                    end end
                                    if not near then
                                        bad = bad + 1
                                        if bad <= 8 then print(string.format("off: %s %s dist#%d piece %d corner %.2f,%.2f", prefab, name, di, l, cy, cx)) end
                                        break
                                    end
                                end
                            end
                        end
                        local off = math.abs(area - cells_n) / math.max(1, cells_n)
                        if off > .15 then
                            area_off = area_off + 1
                            if area_off <= 8 then print(string.format("area: %s %s dist#%d cells %d drawn %.1f", prefab, name, di, cells_n, area)) end
                        end
                    end
                end
            end
        end
    end
end
print(string.format("%d maps, %d triangles, %d off their piece, %d with area off >15%%, worst %.1fms, all %.1fs", maps, n_tri, bad, area_off, worst * 1000, os.clock() - t0))

for k, v in pairs(prof) do print(string.format('  %-10s %.2fs', k, v)) end

print('fallbacks', SimMoves.fallbacks, 'atoms made', SimMoves.made)
