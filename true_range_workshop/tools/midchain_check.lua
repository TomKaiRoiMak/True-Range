-- luajit midchain_check.lua <bench_replay cache folder> [data dir]: a move gone into part-way through - its later
-- animation played without the first (the Clockwork Rook's quick charge: "atk" with no "atk_pre"; the Shadow
-- Thrall mouth's bite_final straight after landing). The drawer knows a move by its first animation, so none
-- is drawn. Every "MISSED t boss state:" of the boss replays whose state is no first animation of that boss's
-- moves, but is a later one of some move's: counted per boss and state, with the moves it's part of.
DEGREES, FRAMES = math.pi / 180, 1 / 30
local RUN = arg[1]
local DATA = arg[2] or [[D:\Work\Coding\dont starve\true_range\scripts\true_range\]]
local data = {}
for _, f in ipairs({ "moves_sim.lua", "moves_sim_um.lua" }) do
    local ok, d = pcall(dofile, DATA .. f)
    if ok and type(d) == "table" then
        for b, ms in pairs(d) do
            if b:sub(1, 1) ~= "_" and type(ms) == "table" then
                data[b] = data[b] or {}
                for k, m in pairs(ms) do data[b][k] = m end
            end
        end
        for a, b in pairs(d._alias or {}) do data[a] = data[a] or data[b] end
    end
end
local count, total = {}, 0
local p = io.popen('dir /b "' .. RUN .. '\\*__*.txt" 2>nul')
for name in p:lines() do
    if not name:find("___haz") and not name:find("%.err$") then
        for l in io.lines(RUN .. "\\" .. name) do
            local b, st = l:match("^MISSED%s+[%d%.]+ ([%w_]+) ([%w_]+): struck")
            if b then
                total = total + 1
                local first, later = false, {}
                for k, m in pairs(data[b] or {}) do
                    local an = m.anims or {}
                    if an[1] == st then first = true end
                    for i = 2, #an do if an[i] == st then later[#later + 1] = k end end
                end
                if not first and #later > 0 then
                    table.sort(later)
                    local key = b .. " " .. st .. "  (part of " .. table.concat(later, ", ") .. ")"
                    count[key] = (count[key] or 0) + 1
                end
            end
        end
    end
end
p:close()
local list, n = {}, 0
for k, v in pairs(count) do list[#list + 1] = { k, v } n = n + v end
table.sort(list, function(a, b) return a[2] > b[2] end)
for _, e in ipairs(list) do print(string.format("%5d  %s", e[2], e[1])) end
print(string.format("%d of %d missed: a move gone into part-way through", n, total))
