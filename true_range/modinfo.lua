name = "True Range+"
description = [[
See exactly where an attack will land, before it lands.

When a monster winds up, the real area its move will hit is drawn on the
ground - worked out from its own game code, not guessed.

Faint red: later   Red: soon   Yellow: about to strike   Deep red: now
Purple: only freezes or puts you to sleep

Green: your reach (by your weapon). Yellow outline: where a monster starts
attacking you. Body ring: orange in danger, red when hit.
Friends: a body ring each, and their reach if you turn it on.

O: settings window, in the game. Ctrl+O: everything off / on.
Players get it automatically when they join.
]]
author = "TomKaiRoiMak"
version = "1.1.7"
icon_atlas = "modicon.xml"
icon = "modicon.tex"

api_version = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false

-- the server knows the real ranges (players' games don't), so everyone needs it
all_clients_require_mod = true
client_only_mod = false
server_filter_tags = { "true range" }

local keys = {
    { description = "R", data = "KEY_R" },
    { description = "G", data = "KEY_G" },
    { description = "H", data = "KEY_H" },
    { description = "V", data = "KEY_V" },
    { description = "B", data = "KEY_B" },
    { description = "N", data = "KEY_N" },
    { description = "Z", data = "KEY_Z" },
    { description = "X", data = "KEY_X" },
    { description = "O", data = "KEY_O" },
    { description = "K", data = "KEY_K" },
    { description = "L", data = "KEY_L" },
    { description = "J", data = "KEY_J" },
    { description = "F1", data = "KEY_F1" },
    { description = "F2", data = "KEY_F2" },
    { description = "F3", data = "KEY_F3" },
    { description = "F4", data = "KEY_F4" },
    { description = "F5", data = "KEY_F5" },
    { description = "F6", data = "KEY_F6" },
    { description = "F7", data = "KEY_F7" },
    { description = "F8", data = "KEY_F8" },
    { description = "F9", data = "KEY_F9" },
    { description = "F10", data = "KEY_F10" },
    { description = "F11", data = "KEY_F11" },
    { description = "Insert", data = "KEY_INSERT" },
    { description = "Delete", data = "KEY_DELETE" },
    { description = "Home", data = "KEY_HOME" },
    { description = "End", data = "KEY_END" },
    { description = "Page Up", data = "KEY_PAGEUP" },
    { description = "Page Down", data = "KEY_PAGEDOWN" },
}

-- (an opacity: 0% (not drawn) to 100%, 10% a step)
local percent = {}
for i = 0, 10 do percent[i + 1] = { description = (i * 10) .. "%", data = i / 10 } end

configuration_options = {
    {
        name = "monsters",
        label = "Monsters shown",
        hover = "Which monsters' attacks are drawn.",
        options = {
            { description = "Pointed at", data = "hover", hover = "Only the one under your mouse." },
            { description = "+ hunting you", data = "target", hover = "The one under your mouse, and every one that's after you." },
            { description = "All nearby", data = "all", hover = "Every monster near you, all the time." },
        },
        default = "all",
        client = true,
    },
    {
        name = "max_monsters",
        label = "Most monsters drawn",
        hover = "At most this many monsters' attacks drawn at once - the nearest, and those after you first. Fewer runs smoother with a crowd.",
        options = {
            { description = "4", data = 4 }, { description = "8", data = 8 }, { description = "12", data = 12 },
            { description = "16", data = 16 }, { description = "20", data = 20 }, { description = "24", data = 24 },
            { description = "28", data = 28 }, { description = "32", data = 32 }, { description = "48", data = 48 },
            { description = "64", data = 64 }, { description = "All on screen", data = 0 },
        },
        default = 8,
        client = true,
    },
    {
        name = "own",
        label = "Your own ring",
        hover = "Show how far your weapon reaches.",
        options = {
            { description = "Off", data = "off" },
            { description = "In a fight", data = "fight", hover = "While something is after you, or you're attacking." },
            { description = "Always", data = "always" },
        },
        default = "always",
        client = true,
    },
    {
        name = "abigail",
        label = "Abigail's reach",
        hover = "Abigail's attack range, and her commands' ranges as you aim them.",
        options = {
            { description = "Off", data = "off" },
            { description = "In a fight", data = "fight", hover = "Only while she's after something." },
            { description = "Always", data = "always" },
        },
        default = "fight",
        client = true,
    },
    {
        name = "start_ring",
        label = "Yellow ring",
        hover = "How near a monster comes before it starts attacking you.",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
        client = true,
    },
    {
        name = "settings_key",
        label = "Settings window key",
        hover = "Opens a window to change these settings in the game (kept on your computer). Ctrl + this key: everything off, or on again, at once.",
        options = keys,
        default = "KEY_O",
        client = true,
    },
    {
        name = "op_area",
        label = "Attacks' opacity",
        hover = "How solid the inside of monsters' attacks is drawn.",
        options = percent,
        default = 1,
        client = true,
    },
    {
        name = "op_edge",
        label = "Outlines' opacity",
        hover = "How solid the outlines of monsters' attacks are drawn.",
        options = percent,
        default = 1,
        client = true,
    },
    {
        name = "op_you",
        label = "Your rings' opacity",
        hover = "How solid your body ring and your own reach are drawn.",
        options = percent,
        default = 1,
        client = true,
    },
    {
        name = "op_others",
        label = "Other rings' opacity",
        hover = "How solid monsters' and friends' rings, Abigail's reach and the yellow ring are drawn.",
        options = percent,
        default = 1,
        client = true,
    },
    {
        name = "ring_dash",
        label = "Rings' line",
        hover = "Rings that aren't attacks (your body and reach, friends', monsters' bodies, the yellow ring, Abigail's) drawn solid or dotted - and how close the dots.",
        options = {
            { description = "Solid", data = 0 },
            { description = "Dots: very dense", data = .25 },
            { description = "Dots: dense", data = .4 },
            { description = "Dots: medium", data = .6 },
            { description = "Dots: sparse", data = .9 },
            { description = "Dots: very sparse", data = 1.3 },
        },
        default = 0,
        client = true,
    },
    {
        name = "body",
        label = "Your body ring",
        hover = "A small ring around you: the part of you attacks have to reach. Orange while you stand where an attack reaches, red when you're hit.",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
        client = true,
    },
    {
        name = "friend_body",
        label = "Friends' body rings",
        hover = "A small ring around each other player: the part of them attacks have to reach.",
        options = {
            { description = "On", data = true },
            { description = "Off", data = false },
        },
        default = true,
        client = true,
    },
    {
        name = "friend_own",
        label = "Friends' reach",
        hover = "Show how far each other player's weapon reaches (light blue).",
        options = {
            { description = "Off", data = "off" },
            { description = "In a fight", data = "fight", hover = "While they're attacking, or something is after them." },
            { description = "Always", data = "always" },
        },
        default = "off",
        client = true,
    },
}
