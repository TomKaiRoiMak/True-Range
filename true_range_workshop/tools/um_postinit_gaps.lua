-- luajit tools/um_postinit_gaps.lua <UM workshop folder>
-- Uncompromising Mode's own states laid into the game's stategraphs (postinit/stategraphs/SG*.lua, AddStategraphState) - not in
-- the offline runs (they run the game's stategraphs), so a state that strikes there has no move in the data unless written by
-- hand: the ice hound's quickattack, Bearger's boulder shot, 2026-10-29. Each state that strikes (DoAttack, LaunchProjectile,
-- an AOE, a projectile or spike spawned), its first animation, and whether the data (moves_sim_um + moves_hand_um, the
-- game's moves_sim under it) has a move begun with that animation for the stategraph's monsters.
local um = assert(arg[1], "usage: luajit tools/um_postinit_gaps.lua <UM workshop folder>")
package.path = "../true_range/scripts/?.lua;" .. package.path
local MD = require("true_range/moddata")
MD.Apply(function(n) return n == "workshop-3193922031" end)
local data = require("true_range/moves_sim")
-- (monsters by stategraph: SG<name> is <name>'s, and any drawn as it (_alias))
local function Owners(sg)
    local o = { [sg] = true }
    for a, b in pairs(data._alias or {}) do if b == sg then o[a] = true end end
    -- (the game's own sharing: hounds' SGhound for all hounds, SGbearger for the Mutated one too)
    if sg == "hound" then for _, p in ipairs({ "firehound", "icehound", "glacialhound", "lightninghound", "magmahound", "sporehound" }) do o[p] = true end end
    if sg == "bearger" then o.mutatedbearger = true end
    if sg == "deerclops" then o.mutateddeerclops = true end
    return o
end
local function HasAnim(owners, anim)
    for p in pairs(owners) do
        for _, e in pairs(data[p] or {}) do
            if type(e) == "table" and e.anims ~= nil then
                for _, a in ipairs(e.anims) do if a == anim then return p end end
            end
        end
    end
    return nil
end
local STRIKES = { "DoAttack", "LaunchProjectile", "DoAreaAttack", "AOEUtil", "FindEntities", "SpawnPrefab%(\"[%w_]*projectile",
    "SpawnPrefab%(\"[%w_]*spike", "IceSpike", "ShootFire", "ShootProjectile", "Shoot%(", "GetAttacked" }
local p = io.popen('dir /b "' .. um .. '\\postinit\\stategraphs\\SG*.lua"')
local found = 0
for f in p:lines() do
    local sg = f:match("^SG(.-)%.lua$")
    local src = io.open(um .. "\\postinit\\stategraphs\\" .. f, "rb"):read("*a")
    local owners = Owners(sg)
    -- (each state: from its name to the next)
    local starts = {}
    for pos, name in src:gmatch("()name%s*=%s*\"([%w_]+)\"") do starts[#starts + 1] = { pos = pos, name = name } end
    for i, s in ipairs(starts) do
        local body = src:sub(s.pos, (starts[i + 1] or { pos = #src + 1 }).pos - 1)
        local anim = body:match("PlayAnimation%(\"([%w_]+)\"")
        local hits = {}
        for _, pat in ipairs(STRIKES) do if body:find(pat) then hits[#hits + 1] = (pat:gsub("%%", "")) end end
        if anim ~= nil and #hits > 0 then
            local who = HasAnim(owners, anim)
            if who == nil then
                found = found + 1
                print(string.format("SG%-18s %-24s anim %-20s strikes by %s  -- no move", sg, s.name, anim, table.concat(hits, ",")))
            end
        end
    end
end
p:close()
print(found .. " states that strike with no move begun by their animation")
