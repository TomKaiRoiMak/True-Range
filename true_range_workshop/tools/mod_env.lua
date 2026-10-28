-- A mod's modmain run in a mod's environment, inside tools/sim_moves.lua's fake world (SIM_MOD=<its
-- folder>): what it adds to the game kept - its prefab, component and stategraph post-inits, its
-- stategraphs' new states - and put on as the sim makes each thing (ModEnv.Prefab, .Component, .SG).
-- Its scripts are the game's with its own laid over them (tools/mod_scripts.ps1 - the sim's scripts
-- folder). Each modimport on its own: one failing (a widget, a recipe - nothing a monster needs)
-- is said and passed by, the rest still run.
local ModEnv = { prefab = {}, any = {}, comp = {}, sg = {}, sg_states = {}, failed = {}, ran = 0 }

-- (a stand-in for whatever the game has and the sim hasn't: indexed, itself again; called,
-- nothing back - as the sim's own no-op - the mod's setup code going through it, nothing done)
local STUB
STUB = setmetatable({}, {
    __index = function() return STUB end,
    __call = function() return nil end,
    __newindex = function() end,
})
ModEnv.STUB = STUB

local function Add(list, key, v)
    local l = list[key]
    if l == nil then l = {} list[key] = l end
    l[#l + 1] = v
end

function ModEnv.Run(root, name, scripts)
    root = root:gsub("[/\\]$", "")
    -- (its settings: each as its modinfo sets it to begin with)
    local opts, info = {}, setmetatable({}, { __index = _G })
    local fi = loadfile(root .. "/modinfo.lua")
    if fi ~= nil then
        setfenv(fi, info)
        pcall(fi)
        for _, o in ipairs(rawget(info, "configuration_options") or {}) do
            if type(o) == "table" and o.name ~= nil then opts[o.name] = o.default end
        end
        ModEnv.version = rawget(info, "version")
    end
    -- (asked about mods: its own name, as a text; no other mod on)
    if rawget(_G, "KnownModIndex") == nil then
        rawset(_G, "KnownModIndex", setmetatable({
            GetModFancyName = function(_, n) return tostring(n) end,
            IsModEnabled = function() return false end, IsModEnabledAny = function() return false end,
            GetModsToLoad = function() return {} end, GetModInfo = function() return {} end,
        }, { __index = function() return STUB end }))
    end
    -- (the game's own the sim never made - asked of in the mod's setup: stand-ins)
    for _, k in ipairs({ "KnownModIndex", "CurrentRelease", "TheFrontEnd", "TheInput", "ThePlayer", "Profile",
        "TheInventory", "TheRecipeBook", "TheCookbook", "TheScrapbookPartitions", "TheGenericKV", "TheSkillTree",
        -- (the sound mixer and the camera - Tropical Experience's twister turns the wind up as it comes, 2026-10-20)
        "TheMixer", "TheCamera", "TheFocalPoint" }) do
        if rawget(_G, k) == nil then rawset(_G, k, STUB) end
    end
    -- (the camera, as a server's is: its default heading, 45 (cameras/followcamera.lua SetDefault) - asked for in a move's own
    -- code: the Tiger Shark's leap turning its shadow by it, the Ancient Hulk's spin sweeping its 8 sectors from its down vector)
    if rawget(_G, "TheCamera") == STUB then
        local function Down() local h = 45 * math.pi / 180 return Vector3(math.cos(h), 0, math.sin(h)) end
        rawset(_G, "TheCamera", setmetatable({ GetHeading = function() return 45 end, GetHeadingTarget = function() return 45 end,
            GetDownVec = Down }, { __index = function() return STUB end }))
    end
    local env
    env = setmetatable({}, { __index = function(_, k)
        -- (what a mod may ask of the game it's given - added to, as it goes: none here but what's kept below)
        if type(k) == "string" and (k:match("^Add%u") or k:match("^Register%u") or k:match("^Remove%u")) then return function() end end
        local v = _G[k]
        if v ~= nil then return v end
        return nil
    end })
    -- (the game's own mod functions, each a field of its own as the game gives them - not found
    -- through the table's look-up: UM's lighter.lua puts its own look-up on it, GLOBAL's only)
    for _, k in ipairs({ "AddLevelPreInit", "AddLevelPreInitAny", "AddTaskSetPreInit", "AddTaskSetPreInitAny", "AddTaskPreInit",
        "AddRoomPreInit", "AddGamePostInit", "AddSimPostInit", "AddGlobalClassPostConstruct", "AddClassPostConstruct",
        "AddAction", "AddComponentAction", "AddPlayerPostInit", "AddReplicableComponent", "AddBrainPostInit",
        "AddStategraphEvent", "AddStategraphActionHandler", "AddModCharacter", "AddModRPCHandler", "AddClientModRPCHandler",
        "AddShardModRPCHandler", "AddRecipe", "AddRecipe2", "AddCharacterRecipe", "AddDeconstructRecipe", "AddRecipeFilter",
        "AddRecipeToFilter", "AddIngredientValues", "AddCookerRecipe", "AddMinimapAtlas", "AddUserCommand", "AddVoteCommand",
        "AddPopup", "AddCustomizeGroup", "AddCustomizeItem", "AddModShadersInit", "AddModShadersSortAndEnable",
        "AddPrototyperDef", "AddLoadingTip", "AddSkinnableCharacter", "AddWorldSettingsOption", "AddPrefabPostInitAny",
        "RegisterInventoryItemAtlas", "RegisterSkilltreeBGForCharacter", "RegisterSkilltreeIconsAtlas", "RegisterScrapbookIconAtlas",
        "ReloadPreloadAssets", "RemapSoundEvent", "SetModHUDFocus", "RemoveDefaultCharacter", "AddLevel", "AddTask", "AddRoom",
        "AddStartLocation", "AddTaskSet", "AddRecipeTab", "AddFoodTag", "AddSimPreInit", "AddHamletPrefab" }) do
        rawset(env, k, function() end)
    end
    env.GLOBAL, env.env, env.modname, env.MODROOT = _G, env, name or root:match("([^/\\]+)$"), root .. "/"
    env.GetModConfigData = function(o) return opts[o] end
    env.Assets, env.PrefabFiles = {}, {}
    env.modimport = function(path)
        if not path:find("%.lua$") then path = path .. ".lua" end
        local f, err = loadfile(root .. "/" .. path)
        if f == nil then
            ModEnv.failed[#ModEnv.failed + 1] = path .. ": " .. tostring(err)
            return
        end
        setfenv(f, env)
        -- (SIM_MOD_ERRORS: where in the mod's own file it failed, not only the game file it failed in)
        local ok, e = xpcall(f, os.getenv("SIM_MOD_ERRORS") and function(m)
            local tb = debug.traceback(tostring(m), 2)
            local own = {}
            for l in tb:gmatch("[^\n]+") do if l:find("3193922031", 1, true) or l:find("workshop", 1, true) then own[#own + 1] = l:gsub("^%s+", "") end end
            return tostring(m) .. (#own > 0 and (" <- " .. table.concat(own, " <- ", 1, math.min(#own, 3))) or "")
        end or function(m) return m end)
        ModEnv.ran = ModEnv.ran + 1
        if not ok then ModEnv.failed[#ModEnv.failed + 1] = path .. ": " .. tostring(e) end
    end
    env.AddPrefabPostInit = function(p, fn) Add(ModEnv.prefab, p, fn) end
    env.AddPrefabPostInitAny = function(fn) ModEnv.any[#ModEnv.any + 1] = fn end
    env.AddComponentPostInit = function(c, fn) Add(ModEnv.comp, c, fn) end
    env.AddStategraphPostInit = function(s, fn) Add(ModEnv.sg, s, fn) end
    env.AddStategraphState = function(s, st) Add(ModEnv.sg_states, s, st) end
    -- (what the game has loaded before any mod runs, the game's own - asked for by the mod, it gets those: Tropical
    -- Experience's require "containers" pulled in its own prefabs/oceanfishdef, on tiles it adds only later - its whole
    -- modmain failed, 2026-10-20. Loaded first from the game's scripts alone, the folder the mod's are laid over)
    -- (the world's tiles by name - filled as each tile is added (worldtiledefs AddTile), which the sim never does: the game's
    -- named grounds for them, so tables keyed by tile make - the fish by season, the game's own and Tropical Experience's)
    if type(rawget(_G, "WORLD_TILES")) == "table" and type(rawget(_G, "GROUND")) == "table" then
        for k, v in pairs(GROUND) do if WORLD_TILES[k] == nil then WORLD_TILES[k] = v end end
    end
    local game = scripts ~= nil and scripts:gsub("_[%w]+$", "") or nil
    if game ~= nil and game ~= scripts then
        local old = package.path
        package.path = game .. "/?.lua;" .. old
        -- (its strings too - the sim's stand-in for an unknown constants table gives each name back as a text,
        -- STRINGS.NAMES "NAMES": Tropical Experience's strings files, and its modmain with them, stopped there)
        if rawget(_G, "STRINGS") ~= nil and type(rawget(_G, "STRINGS").NAMES) ~= "table" then rawset(_G, "STRINGS", nil) end
        for _, m in ipairs({ "strings", "containers" }) do
            if package.loaded[m] == nil then
                local ok, err = pcall(require, m)
                -- (not made here - the game's own needs its menus' strings, never made in the sim: a stand-in, nothing a
                -- monster needs is in it)
                if not ok then
                    package.loaded[m] = STUB
                    if os.getenv("SIM_MOD_ERRORS") then io.stderr:write("[mod] (the game's own " .. m .. ": a stand-in) " .. tostring(err) .. "\n") end
                end
            end
        end
        package.path = old
    end
    -- (a mod putting its own look-up on its environment - Tropical Experience's first line, GLOBAL's only: the game's mod
    -- functions not listed above still answered, after its own - AddMinimap stopped its modmain, 2026-10-20)
    local real_smt = setmetatable
    rawset(_G, "setmetatable", function(t, mt)
        if t == env and type(mt) == "table" and type(mt.__index) == "function" then
            local own = mt.__index
            mt.__index = function(tt, k)
                local v = own(tt, k)
                if v == nil and type(k) == "string" and (k:match("^Add%u") or k:match("^Register%u") or k:match("^Remove%u")) then return function() end end
                return v
            end
        end
        return real_smt(t, mt)
    end)
    env.modimport("modmain.lua")
    rawset(_G, "setmetatable", real_smt)
    local n = 0
    for _ in pairs(ModEnv.sg) do n = n + 1 end
    io.stderr:write(string.format("[mod] %s %s: %d files run, %d failed; post-inits: %d stategraphs\n",
        env.modname, tostring(ModEnv.version), ModEnv.ran, #ModEnv.failed, n))
    if os.getenv("SIM_MOD_ERRORS") then
        for _, e in ipairs(ModEnv.failed) do io.stderr:write("[mod]   " .. e .. "\n") end
    end
end

-- A thing just made: the mod's post-inits for its kind, and for every kind
function ModEnv.Prefab(e, name)
    if type(e) ~= "table" then return end
    for _, fn in ipairs(ModEnv.prefab[name] or {}) do
        local ok, err = pcall(fn, e)
        if not ok and os.getenv("SIM_MOD_ERRORS") then io.stderr:write("[mod] post-init " .. name .. ": " .. tostring(err) .. "\n") end
    end
    for _, fn in ipairs(ModEnv.any) do pcall(fn, e) end
end

-- A component just added
function ModEnv.Component(c, name, inst)
    for _, fn in ipairs(ModEnv.comp[name] or {}) do
        local ok, err = pcall(fn, c, inst)
        if not ok and os.getenv("SIM_MOD_ERRORS") then io.stderr:write("[mod] component " .. name .. ": " .. tostring(err) .. "\n") end
    end
end

-- A stategraph as its file makes it ({ name, states = { list } }): the mod's states put in, its
-- post-inits run on it as the game's are - on its states by name - then a list again
function ModEnv.SG(sg)
    if type(sg) ~= "table" or sg.name == nil then return sg end
    local posts, added = ModEnv.sg[sg.name], ModEnv.sg_states[sg.name]
    if posts == nil and added == nil then return sg end
    local order, by = {}, {}
    for _, s in ipairs(sg.states or {}) do
        if s.name ~= nil then
            if by[s.name] == nil then order[#order + 1] = s.name end
            by[s.name] = s
        end
    end
    for _, s in ipairs(added or {}) do
        if s.name ~= nil then
            if by[s.name] == nil then order[#order + 1] = s.name end
            by[s.name] = s
        end
    end
    local events = {}
    for _, ev in ipairs(sg.events or {}) do
        if type(ev) == "table" and ev.name ~= nil then events[ev.name] = ev end
    end
    local view = { name = sg.name, states = by, events = events, actionhandlers = {} }
    -- (each state's own handlers by name too, as the game's State keeps them - a post-init reaching
    -- for attack.events["animqueueover"] (Uncompromising Mode's Beefalo, Koalefant): back to a list after)
    local function ByName(s)
        local m = {}
        for _, ev in ipairs(s.events or {}) do if type(ev) == "table" and ev.name ~= nil then m[ev.name] = ev end end
        s.events = m
    end
    local function ToList(s)
        if type(s.events) ~= "table" or s.events[1] ~= nil then return end
        local names, l = {}, {}
        for k in pairs(s.events) do names[#names + 1] = k end
        table.sort(names)
        for _, k in ipairs(names) do l[#l + 1] = s.events[k] end
        s.events = l
    end
    for _, s in pairs(by) do if type(s) == "table" then ByName(s) end end
    for _, fn in ipairs(posts or {}) do
        local ok, err = pcall(fn, view)
        if not ok then io.stderr:write("[mod] stategraph " .. sg.name .. ": " .. tostring(err) .. "\n") end
    end
    for _, s in pairs(view.states) do if type(s) == "table" then ToList(s) end end
    -- (new ones it put in by name, in a set order)
    local extra = {}
    for k in pairs(view.states) do
        local known = false
        for _, o in ipairs(order) do if o == k then known = true break end end
        if not known then extra[#extra + 1] = k end
    end
    table.sort(extra)
    for _, k in ipairs(extra) do order[#order + 1] = k end
    local list = {}
    for _, k in ipairs(order) do
        local s = view.states[k]
        if s ~= nil then
            if s.name == nil then s.name = k end
            list[#list + 1] = s
        end
    end
    sg.states = list
    local evs, names = {}, {}
    for k in pairs(view.events) do names[#names + 1] = k end
    table.sort(names)
    for _, k in ipairs(names) do evs[#evs + 1] = view.events[k] end
    sg.events = evs
    return sg
end

return ModEnv
