-- luajit haz_compact.lua <log> <out>: an older log (each thing a line a tick) written as the game
-- now writes it (true_range modmain: only as it changes, GONE, "_you" once a tick) - for testing
-- tools/expand_haz.lua: compacted then expanded, the replays must find the same
local lines = {}
for line in io.lines(arg[1]) do lines[#lines + 1] = line end
local out = {}
local said = {}       -- guid -> its state last written
local said_still, said_at = {}, {}
local here_prev = {}  -- guid -> prefab, there the tick before
local tick_t, here = nil, nil
local function Flush()
    if tick_t == nil then return end
    -- (gone since the tick before)
    for g, pf in pairs(here_prev) do
        if here[g] == nil then
            out[#out + 1] = string.format("[tr_haz] %s %s guid=%s GONE", tick_t, pf, g)
            said[g] = nil
        end
    end
    here_prev = {}
    for g, v in pairs(here) do here_prev[g] = v end
end
for _, line in ipairs(lines) do
    local t, prefab, guid, rest = line:match("%[tr_haz%] ([%d%.]+) ([%w_]+) guid=(%d+) (.*)$")
    if t ~= nil and not rest:find("^HIT") then
        if t ~= tick_t then
            Flush()
            tick_t, here = t, {}
            local yx, yz = rest:match("you=([%d%.%-]+),([%d%.%-]+)")
            out[#out + 1] = string.format("[tr_haz] %s _you you=%s,%s", t, yx, yz)
        end
        here[guid] = prefab
        local state = rest:gsub("you=[%d%.%-]+,[%d%.%-]+ ", "")
        local still = rest:match("(y=.*)$") or ""
        -- (as the game: only moving, once in MOVE_EVERY ticks - true_range modmain, 1)
        local tn = tonumber(t)
        if said[guid] ~= state and (said[guid] == nil or said_still[guid] ~= still or tn - said_at[guid] >= 1 / 30 - .001) then
            said[guid], said_still[guid], said_at[guid] = state, still, tn
            out[#out + 1] = line
        end
    else
        out[#out + 1] = line
    end
end
Flush()
local fh = assert(io.open(arg[2], "wb"))
fh:write(table.concat(out, "\n"), "\n")
fh:close()
