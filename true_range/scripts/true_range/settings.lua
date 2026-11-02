-- True Range's settings, changed in the game (true_range/settingsscreen) and kept on this computer:
-- each one as the server's mod settings set it (modinfo), unless changed here since.

local json = require("json")

local Settings = {}

local FILE = "true_range_settings.json"

local KEYS = {
    { text = "R", data = "KEY_R" }, { text = "G", data = "KEY_G" }, { text = "H", data = "KEY_H" },
    { text = "V", data = "KEY_V" }, { text = "B", data = "KEY_B" }, { text = "N", data = "KEY_N" },
    { text = "Z", data = "KEY_Z" }, { text = "X", data = "KEY_X" }, { text = "O", data = "KEY_O" },
    { text = "K", data = "KEY_K" }, { text = "L", data = "KEY_L" }, { text = "J", data = "KEY_J" },
    { text = "F1", data = "KEY_F1" }, { text = "F2", data = "KEY_F2" }, { text = "F3", data = "KEY_F3" },
    { text = "F4", data = "KEY_F4" }, { text = "F5", data = "KEY_F5" }, { text = "F6", data = "KEY_F6" },
    { text = "F7", data = "KEY_F7" }, { text = "F8", data = "KEY_F8" }, { text = "F9", data = "KEY_F9" },
    { text = "F10", data = "KEY_F10" }, { text = "F11", data = "KEY_F11" },
    { text = "Insert", data = "KEY_INSERT" }, { text = "Delete", data = "KEY_DELETE" },
    { text = "Home", data = "KEY_HOME" }, { text = "End", data = "KEY_END" },
    { text = "Page Up", data = "KEY_PAGEUP" }, { text = "Page Down", data = "KEY_PAGEDOWN" },
}
local WHEN = {
    { text = "Off", data = "off" },
    { text = "In a fight", data = "fight" },
    { text = "Always", data = "always" },
}
local ONOFF = { { text = "On", data = true }, { text = "Off", data = false } }
-- (an opacity: 0% (not drawn) to 100%, 10% a step)
local PERCENT = {}
for i = 0, 10 do PERCENT[i + 1] = { text = (i * 10) .. "%", data = i / 10 } end

-- (each: its name as in modinfo, what it's called, what it does, its choices, and its value if
-- neither modinfo nor this computer says)
Settings.OPTIONS = {
    { name = "monsters", label = "Monsters shown", default = "all",
      hover = "Which monsters' attacks are drawn.",
      choices = { { text = "Pointed at", data = "hover" }, { text = "+ hunting you", data = "target" }, { text = "All nearby", data = "all" } } },
    { name = "max_monsters", label = "Most monsters drawn", default = 8,
      hover = "At most this many monsters' attacks drawn at once - the nearest, and those after you first. Fewer runs smoother with a crowd.",
      choices = { { text = "4", data = 4 }, { text = "8", data = 8 }, { text = "12", data = 12 }, { text = "16", data = 16 },
          { text = "20", data = 20 }, { text = "24", data = 24 }, { text = "28", data = 28 }, { text = "32", data = 32 },
          { text = "48", data = 48 }, { text = "64", data = 64 }, { text = "All on screen", data = 0 } } },
    { name = "own", label = "Your own reach", default = "always", choices = WHEN,
      hover = "How far your weapon reaches (green)." },
    { name = "body", label = "Your body ring", default = true, choices = ONOFF,
      hover = "The part of you attacks have to reach. Orange in danger, red when hit." },
    { name = "friend_body", label = "Friends' body rings", default = true, choices = ONOFF,
      hover = "A ring round each other player: the part of them attacks have to reach." },
    { name = "friend_own", label = "Friends' reach", default = "off", choices = WHEN,
      hover = "How far each other player's weapon reaches (light blue)." },
    { name = "abigail", label = "Abigail's reach", default = "fight", choices = { { text = "Off", data = "off" }, { text = "In a fight", data = "fight" }, { text = "Always", data = "always" } },
      hover = "Abigail's attack range (only while she's after something, or always), and her commands' ranges as you aim them." },
    { name = "start_ring", label = "Yellow ring", default = true, choices = ONOFF,
      hover = "How near a monster comes before it starts attacking you." },
    { name = "op_area", col = 2, label = "Attacks' opacity", default = 1, choices = PERCENT,
      hover = "How solid the inside of monsters' attacks is drawn." },
    { name = "op_edge", col = 2, label = "Outlines' opacity", default = 1, choices = PERCENT,
      hover = "How solid the outlines of monsters' attacks are drawn." },
    { name = "op_you", col = 2, label = "Your rings' opacity", default = 1, choices = PERCENT,
      hover = "How solid your body ring and your own reach are drawn." },
    { name = "op_others", col = 2, label = "Other rings' opacity", default = 1, choices = PERCENT,
      hover = "How solid monsters' and friends' rings, Abigail's reach and the yellow ring are drawn." },
    { name = "settings_key", col = 2, label = "This window's key", default = "KEY_O", choices = KEYS,
      hover = "Opens this window. Ctrl + this key: everything off, or on again, at once." },
}

-- (the values in use - the same table all along, changed in place: modmain keeps it)
Settings.values = {}
-- (counted up at each change: modmain lays its kept shapes again - their colours set as laid)
Settings.changed = 0
local defaults = {}

local function Valid(o, v)
    for _, c in ipairs(o.choices) do
        if c.data == v then return true end
    end
    return false
end

local function OptionOf(name)
    for _, o in ipairs(Settings.OPTIONS) do
        if o.name == name then return o end
    end
    return nil
end

-- config(name): the server's mod setting for it, nil if none
function Settings.Init(config)
    for _, o in ipairs(Settings.OPTIONS) do
        local v = config(o.name)
        if v == nil or not Valid(o, v) then v = o.default end
        defaults[o.name] = v
        Settings.values[o.name] = v
    end
    TheSim:GetPersistentString(FILE, function(ok, str)
        if not ok or type(str) ~= "string" or str == "" then return end
        local okj, saved = pcall(json.decode, str)
        if not okj or type(saved) ~= "table" then return end
        for name, v in pairs(saved) do
            local o = OptionOf(name)
            if o ~= nil and Valid(o, v) then Settings.values[name] = v end
        end
    end)
end

local function Save()
    -- (only what differs from the mod settings: a later change there still comes through)
    local out = {}
    for name, v in pairs(Settings.values) do
        if v ~= defaults[name] then out[name] = v end
    end
    TheSim:SetPersistentString(FILE, json.encode(out), false)
end

function Settings.Get(name)
    return Settings.values[name]
end

function Settings.Set(name, v)
    local o = OptionOf(name)
    if o == nil or not Valid(o, v) then return end
    Settings.values[name] = v
    Settings.changed = Settings.changed + 1
    Save()
end

-- back to the mod settings
function Settings.Reset()
    for name, v in pairs(defaults) do Settings.values[name] = v end
    Settings.changed = Settings.changed + 1
    Save()
end

-- a key setting's key code ("KEY_R" -> its number), nil if none
function Settings.KeyCode(name)
    local k = Settings.values[name]
    return type(k) == "string" and rawget(_G, k) or nil
end

return Settings
