-- luajit patch_decide.lua <tables dir> <decide dir> [-apply]
-- Each move's deciding frames, run again (build_tables.lua -part=decide into <decide dir>) put into
-- its built file in <tables dir> - the rest of it as built, not run again (its places take hours).
-- Prints each move whose frames changed; -apply writes them. Then build_tables.lua -client.
local TABLES, DECIDE = arg[1], arg[2]
local APPLY = arg[3] == "-apply"

local function Read(path)
    local f = io.open(path, "rb")
    if f == nil then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

local function Line(map)
    local l = {}
    for k, v in pairs(map) do
        if type(k) == "string" then l[#l + 1] = string.format("[%q] = %d", k, v) else l[#l + 1] = string.format("[%d] = %d", k, v) end
    end
    table.sort(l)
    return "{ " .. table.concat(l, ", ") .. " }"
end

local p = io.popen('dir /b "' .. DECIDE:gsub("/", "\\") .. '\\*.pd.lua"')
local changed = 0
for name in p:lines() do
    local move = name:gsub("%.pd%.lua$", "")
    local ok, pd = pcall(dofile, DECIDE .. "/" .. name)
    local path = TABLES .. "/" .. move .. ".lua"
    local text = Read(path)
    if ok and type(pd) == "table" and pd.decide ~= nil and text ~= nil then
        local new_d, new_s = "    decide = " .. Line(pd.decide) .. ",", "    step_decide = " .. Line(pd.step or {}) .. ","
        local old_d = text:match("\n(    decide = {[^\n]-},)\n")
        local old_s = text:match("\n(    step_decide = {[^\n]-},)\n")
        if old_d ~= nil and old_s ~= nil and (old_d ~= new_d or old_s ~= new_s) then
            changed = changed + 1
            print(move)
            if old_d ~= new_d then print("  " .. old_d:gsub("^%s+", "") .. "  ->  " .. new_d:gsub("^%s+", "")) end
            if old_s ~= new_s then print("  " .. old_s:gsub("^%s+", "") .. "  ->  " .. new_s:gsub("^%s+", "")) end
            if APPLY then
                local function Esc(s) return (s:gsub("[%%%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")) end
                text = text:gsub("\n" .. Esc(old_d) .. "\n", function() return "\n" .. new_d .. "\n" end, 1)
                text = text:gsub("\n" .. Esc(old_s) .. "\n", function() return "\n" .. new_s .. "\n" end, 1)
                local f = assert(io.open(path, "wb"))
                f:write(text)
                f:close()
            end
        end
    end
end
p:close()
print(string.format("%d changed%s", changed, APPLY and " (written)" or ""))
