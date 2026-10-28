-- luajit merge_move.lua <moves_sim.lua> <part.lua> prefab move[,move...]
-- Puts single moves of one boss from a sim_moves.lua run (another build of it - -ends, say) into
-- the whole file the mod reads: each move's block ("        [\"move\"] = {" up to the next line at
-- that depth, or its boss's end) swapped for the new one; the boss's other moves untouched.
-- Checked: the result loads, and has every boss and move it had.
local dst_path, src_path, prefab, list = arg[1], arg[2], arg[3], arg[4]
local function Lines(p)
    local f = assert(io.open(p, "rb"))
    local t = f:read("*a")
    f:close()
    local out = {}
    for line in (t .. "\n"):gmatch("(.-)\n") do out[#out + 1] = line end
    if out[#out] == "" then out[#out] = nil end
    return out
end
-- (the lines of the boss's block: first after its head, up to its closing "    },")
local function BossSpan(lines)
    local head = '    ["' .. prefab .. '"] = {'
    for i, l in ipairs(lines) do
        if l == head then
            for j = i + 1, #lines do
                if lines[j]:match("^    }") then return i + 1, j - 1 end
            end
        end
    end
end
local function MoveSpan(lines, from, to, move)
    local head = '        ["' .. move .. '"] = {'
    for i = from, to do
        if lines[i]:sub(1, #head) == head then
            local j = i + 1
            while j <= to and not lines[j]:match('^        %[') do j = j + 1 end
            return i, j - 1
        end
    end
end
local dst, src = Lines(dst_path), Lines(src_path)
local sf, st = BossSpan(src)
assert(sf ~= nil, prefab .. ": not in " .. src_path)
for move in list:gmatch("[^,]+") do
    local df, dt = BossSpan(dst)
    assert(df ~= nil, prefab .. ": not in " .. dst_path)
    local a, b = MoveSpan(src, sf, st, move)
    assert(a ~= nil, move .. ": not in " .. src_path)
    local c, d = MoveSpan(dst, df, dt, move)
    local new = {}
    for i = 1, (c or dt + 1) - 1 do new[#new + 1] = dst[i] end
    for i = a, b do new[#new + 1] = src[i] end
    for i = (d or dt) + 1, #dst do new[#new + 1] = dst[i] end
    dst = new
end
local text = table.concat(dst, "\n") .. "\n"
local before = dofile(dst_path)
local data = assert(loadstring(text))()
for p, moves in pairs(before) do
    assert(data[p] ~= nil, p .. " lost")
    if type(moves) == "table" then for m in pairs(moves) do assert(data[p][m] ~= nil, p .. " " .. tostring(m) .. " lost") end end
end
local f = assert(io.open(dst_path, "wb"))
f:write(text)
f:close()
print("merged " .. prefab .. " " .. list .. " into " .. dst_path)
