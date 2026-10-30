-- luajit tools/gap_scan.lua <scripts dir> <mod root> [moves files...]
-- Every prefab with a combat and a stategraph in its file, with nothing of ours for it: not in the data (moves_sim*,
-- moves_hand*, their _alias / _hazards), not named anywhere in the mod's own Lua (modmain's AGGRO tables, moves_preload).
-- The runs only see what their list holds - UM's mindweaver, fuelseeker, the haunt's hands, TE's big foot and jellyfish
-- none of it, found so 2026-10-30. Commented-out lines skipped (TE's snake_fire, deadsnake: --Prefab(...)).
-- Prints: <file> <prefab> - one line each; read them: a pet, an effect or a drain is no gap.
local dir, mod = arg[1], arg[2]
local have = {}
local files = {}
for i = 3, #arg do files[#files + 1] = arg[i] end
if #files == 0 then
    for _, n in ipairs({ "moves_sim", "moves_sim_um", "moves_sim_te", "moves_hand", "moves_hand_um", "moves_hand_te" }) do
        files[#files + 1] = mod .. "/scripts/true_range/" .. n .. ".lua"
    end
end
for _, f in ipairs(files) do
    local ok, d = pcall(dofile, f)
    if ok and type(d) == "table" then
        for k in pairs(d) do have[k] = true end
        for k in pairs(d._alias or {}) do have[k] = true end
        for k in pairs(d._hazards or {}) do have[k] = true end
    end
end
-- (anything the mod's own Lua names as a word: modmain's AGGRO / AGGRO_WHILE, moves_preload's learned moves)
local named = {}
local p = io.popen('dir /b /s "' .. mod:gsub("/", "\\") .. '\\*.lua" 2>nul')
for f in p:lines() do
    local h = io.open(f, "rb")
    if h then
        for w in h:read("*a"):gmatch("[%a_][%w_]*") do named[w] = true end
        h:close()
    end
end
p:close()
local function Strip(t)
    -- (block comments, then line comments)
    t = t:gsub("%-%-%[(=*)%[.-%]%1%]", "")
    return (t:gsub("%-%-[^\n]*", ""))
end
local list = io.popen('dir /b "' .. dir:gsub("/", "\\") .. '\\prefabs\\*.lua" 2>nul')
local n = 0
for f in list:lines() do
    local h = io.open(dir .. "/prefabs/" .. f, "rb")
    local t = Strip(h:read("*a"))
    h:close()
    if t:find('AddComponent%(%s*"combat"') and t:find("SetStateGraph") then
        local seen = {}
        for name in t:gmatch('%f[%w_]Prefab%(%s*"[%w_/]-([%w_]+)"') do
            if not seen[name] and not have[name] and not named[name] then
                seen[name] = true
                n = n + 1
                print(f, name)
            end
        end
    end
end
list:close()
io.stderr:write(n .. " prefabs with combat and a stategraph, nothing of ours for them\n")
