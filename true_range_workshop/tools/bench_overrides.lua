-- luajit tools/bench_overrides.lua <a cluster's Master/modoverrides.lua> <out modoverrides.lua> <rounds> <speed>
-- The headless testbench's mods: Uncompromising Mode as the user has it set (read from their own
-- cluster, not changed), True Range, and the testbench's server build - nothing else.
local src, out, rounds, speed = arg[1], arg[2], tonumber(arg[3]) or 2, tonumber(arg[4]) or 4
-- (notr: True Range off - to tell a crash of the game or Uncompromising Mode from one of ours)
local notr = arg[5] == "notr"
local mods = dofile(src)
local function Dump(v, ind)
    ind = ind or ""
    if type(v) == "table" then
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        local parts = {}
        for _, k in ipairs(keys) do
            local key = type(k) == "string" and string.format("[%q]", k) or ("[" .. tostring(k) .. "]")
            parts[#parts + 1] = ind .. "  " .. key .. " = " .. Dump(v[k], ind .. "  ")
        end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. ind .. "}"
    elseif type(v) == "string" then
        return string.format("%q", v)
    end
    return tostring(v)
end
local um = mods["workshop-3193922031"]
assert(um ~= nil, "no Uncompromising Mode in " .. src)
local t = {
    ["workshop-3193922031"] = um,
    true_range = { enabled = not notr, configuration_options = (mods.true_range or {}).configuration_options or {} },
    tr_testbench_server = { enabled = true, configuration_options = { rounds = rounds, speed = speed, list = os.getenv("BENCH_LIST") or "" } },
}
-- (te: Tropical Experience on too, its own settings as it comes - its monsters benched in the testbench's own world,
-- never the user's; 2026-10-20)
for i = 5, #arg do
    if arg[i] == "te" then t["workshop-1505270912"] = { enabled = true, configuration_options = {} } end
end
local fh = assert(io.open(out, "wb"))
fh:write("return " .. Dump(t) .. "\n")
fh:close()
print("modoverrides: Uncompromising Mode, True Range, testbench (rounds " .. rounds .. ", speed " .. speed .. ")")
