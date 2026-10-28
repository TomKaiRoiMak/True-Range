name = "TR Testbench (local)"
description = "True Range's testbench: bosses brought in one by one, each left to attack you as it would, you moved by script at each attack (stepping aside at frame k, or jumping off to a distance) - every attack traced for True Range's replays. You invincible meanwhile. Only while you host, with True Range and its debug.txt. Never for upload. F7: start / stop."
author = "TomKaiRoiMak"
version = "0.1.0"
api_version = 10
dst_compatible = true
client_only_mod = true
all_clients_require_mod = false
priority = -200

configuration_options = {
    {
        name = "key",
        label = "Start / stop key",
        options = {
            { description = "F7", data = "KEY_F7" },
            { description = "F8", data = "KEY_F8" },
            { description = "F10", data = "KEY_F10" },
        },
        default = "KEY_F7",
    },
    {
        name = "speed",
        label = "Game speed while testing",
        hover = "Faster if the game keeps each tick 1/30 s (checked and logged as it starts; slowed back if not).",
        options = {
            { description = "1x", data = 1 },
            { description = "2x", data = 2 },
            { description = "4x", data = 4 },
            { description = "8x", data = 8 },
            { description = "16x", data = 16 },
            { description = "32x (no screen)", data = 32 },
        },
        default = 2,
    },
    {
        name = "rounds",
        label = "Rounds per boss",
        options = {
            { description = "1 (quick)", data = 1 },
            { description = "2", data = 2 },
            { description = "3", data = 3 },
            { description = "5", data = 5 },
            { description = "10 (no screen)", data = 10 },
        },
        default = 2,
    },
    {
        -- (the bosses to run, comma-separated - set by tools/run_lag.ps1 when too long for the server's name; empty: as named)
        name = "list",
        label = "Bosses (set by the tools)",
        options = { { description = "as named", data = "" } },
        default = "",
    },
}
