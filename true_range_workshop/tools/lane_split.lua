-- luajit lane_split.lua <share log> <out prefix>: a server that ran several bosses at once, each in a lane of
-- its own far from the others (tr_testbench "tr_bench@K:..." - VERIFY_PLAN 6.18), its log parted into one per
-- lane (<out prefix>_L<k>.txt) as if each had run alone: the replays, bench_lock and state_coverage read
-- them as they are. Each line goes to the lane whose home it's nearest (its place: pos=, born/gone, you of a
-- blow, a ground grid's middle); one with no place by what it's of (a testbench line by its boss, a thing's
-- by its guid); what's of none (the server's own) to every lane.
-- Prints: lines per lane, and the checks - "far" (a line more than FAR from its lane's home: the lanes too
-- close, or one wandered), "cross" (a blow on one lane's stand-in by what's nearer another's home),
-- "unknown" (a testbench or guid line of no lane known) - each must be 0.
local IN, PREFIX = arg[1], arg[2]
-- (a fight's line further than this from its home: half the closest homes apart, at most 150 - set below)
local FAR = 150
local homes = {}          -- k -> { x, z }
local by_prefab = {}      -- boss -> k
local by_guid = {}        -- guid -> k
local outs = {}
local header = {}
local counts, far, cross, unknown, maxd = {}, 0, 0, 0, 0
-- (far counted of what the replays read of a fight - a trace, a blow, a thing near you - not the world's
-- own coming and going: a sapling grown 445 off)
local function Lane(x, z, fight)
    local best, bd = nil, math.huge
    for k, h in pairs(homes) do
        local d = (x - h[1]) ^ 2 + (z - h[2]) ^ 2
        if d < bd then best, bd = k, d end
    end
    local d = math.sqrt(bd)
    if fight then
        if d > maxd then maxd = d end
        if d > FAR then far = far + 1 end
    end
    return best
end
local function Out(k, l)
    local f = outs[k]
    if f == nil then
        f = assert(io.open(string.format("%s_L%d.txt", PREFIX, k), "wb"))
        outs[k] = f
        for _, h in ipairs(header) do f:write(h, "\n") end
    end
    f:write(l, "\n")
    counts[k] = (counts[k] or 0) + 1
end
local function All(l)
    if next(homes) == nil then header[#header + 1] = l return end
    for k in pairs(homes) do Out(k, l) end
end
local pending = {}
local function To(k, l)
    for _, p in ipairs(pending) do Out(k, p) end
    pending = {}
    Out(k, l)
end
local N = "(%-?[%d%.]+)"
for l in io.lines(IN) do
    local k = nil
    local hk, hx, hz = l:match("%[tr_lane%] [%d%.]+ %- lane=(%d+) home=" .. N .. "," .. N)
    if hk then
        homes[tonumber(hk)] = { tonumber(hx), tonumber(hz) }
        for k1, a in pairs(homes) do
            for k2, b in pairs(homes) do
                if k1 ~= k2 then FAR = math.min(FAR, math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2) / 2) end
            end
        end
        -- (the lines before every home was known: to each, as the start of its own)
        All(l)
        goto continue
    end
    do
        local lp, lk = l:match("%[tr_lane%] [%d%.]+ ([%w_]+) lane=(%d+)")
        if lp then by_prefab[lp] = tonumber(lk) To(tonumber(lk), l) goto continue end
    end
    if next(homes) == nil then header[#header + 1] = l goto continue end
    do
        -- (the testbench's own lines: by the boss they're of; "-" is the server's - every lane's)
        local bb = l:match("%[tr_bench%] [%d%.]+ (%S+) ")
        if bb then
            if bb == "-" then All(l)
            elseif by_prefab[bb] then To(by_prefab[bb], l)
            else unknown = unknown + 1 All(l) end
            goto continue
        end
        -- (a blow on a stand-in: the stand-in's place; and what struck it, if it's nearer another lane's)
        local ax, az, yx, yz = l:match("%[tr_h[iu]r?t?%] [%d%.]+ %S+ %d+ " .. N .. " " .. N .. " you " .. N .. " " .. N)
        if yx then
            k = Lane(tonumber(yx), tonumber(yz), true)
            local axn = tonumber(ax)
            if axn > -1e8 then
                local hk2 = nil
                local best, bd = nil, math.huge
                for kk, h in pairs(homes) do
                    local d = (axn - h[1]) ^ 2 + (tonumber(az) - h[2]) ^ 2
                    if d < bd then best, bd = kk, d end
                end
                hk2 = best
                if hk2 ~= k then cross = cross + 1 end
            end
            To(k, l)
            goto continue
        end
        local guid = tonumber(l:match("guid=(%d+)"))
        local px, pz = l:match("pos=" .. N .. "," .. N)
        if px == nil then px, pz = l:match("_you you=" .. N .. "," .. N) end
        local eg, ex, ez = l:match("%[tr_ent%] [%d%.]+ %a+ %S+ (%d+) " .. N .. " " .. N)
        if ex then px, pz, guid = ex, ez, tonumber(eg) end
        if px == nil then
            local x0, z0 = l:match("x0=" .. N .. " z0=" .. N)
            if x0 then px, pz = tonumber(x0) + 40, tonumber(z0) + 40 end
        end
        if px ~= nil then
            k = Lane(tonumber(px), tonumber(pz), l:find("[tr_trace]", 1, true) ~= nil or l:find("[tr_haz]", 1, true) ~= nil)
            if guid ~= nil then by_guid[guid] = k end
            To(k, l)
            goto continue
        end
        if guid ~= nil then
            if by_guid[guid] then To(by_guid[guid], l) else unknown = unknown + 1 All(l) end
            goto continue
        end
        -- (what's said of a blow just before it's written with its places: with that one)
        if l:find("[true_range] you were struck", 1, true) then pending[#pending + 1] = l goto continue end
        All(l)
    end
    ::continue::
end
for _, p in ipairs(pending) do All(p) end
for _, f in pairs(outs) do f:close() end
local parts = {}
for k in pairs(homes) do parts[#parts + 1] = string.format("L%d=%d", k, counts[k] or 0) end
table.sort(parts)
print(string.format("lanes %d %s far=%d cross=%d unknown=%d maxd=%.1f farline=%.0f", #parts, table.concat(parts, " "), far, cross, unknown, maxd, FAR))
