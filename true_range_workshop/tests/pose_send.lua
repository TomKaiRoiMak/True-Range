-- luajit pose_send.lua <mod root>: the server's poses, as modmain sends them - a boss in a move
-- with the host and a friend near, another boss far off, one removed: every pose given to the
-- host's own game (SimMoves.Pose) and sent to the friend's (the pose RPC), tick by tick, printed -
-- run against two copies of the mod, the same lines expected (verify compares with the last)
local root = arg[1]
package.path = root .. "/scripts/?.lua;" .. package.path
DEGREES, FRAMES = math.pi / 180, 1 / 30
local now = 0
GetTime = function() return now end
GetStaticTime = GetTime
local stub
stub = setmetatable({}, { __index = function() return stub end, __call = function() return stub end })
local G = setmetatable({
    GetTime = GetTime, GetStaticTime = GetStaticTime,
    setmetatable = setmetatable, pcall = pcall, tostring = tostring, tonumber = tonumber, type = type, pairs = pairs, ipairs = ipairs,
    select = select, unpack = unpack, next = next, math = math, string = string, table = table, error = error, assert = assert,
    rawget = rawget, rawset = rawset, getmetatable = getmetatable, os = os, require = require, collectgarbage = collectgarbage,
    TheWorld = { ismastersim = true }, AllPlayers = {},
    TheNet = { IsDedicated = function() return false end, GetIsServer = function() return true end },
}, { __index = function(_, k) return stub end })
local posts, worldposts = {}, {}
local out = {}
local env = {
    GLOBAL = G, modname = "true_range_test", Assets = {}, Asset = function() return {} end,
    pairs = pairs, ipairs = ipairs, math = math, string = string, table = table, tostring = tostring, type = type,
    require = require, print = function() end,
    AddPrefabPostInit = function(p, f) if p == "world" then worldposts[#worldposts + 1] = f else posts[p] = posts[p] or {} table.insert(posts[p], f) end end,
    GetModConfigData = function() return nil end,
    GetClientModRPC = function() return "pose" end,
    SendModRPCToClient = function(_, ids, inst, key, go, ft, x, z, rot, after, aim)
        out[#out + 1] = string.format("%.3f RPC %s to %s: %s %s %.3f %.2f,%.2f %.1f %s aim=%s", now, inst.prefab, table.concat(ids, ","), key, tostring(go), ft, x, z, rot, after, aim and aim.name or "-")
    end,
}
for _, n in ipairs({ "AddClassPostConstruct", "AddClientModRPCHandler", "AddComponentPostInit", "AddModRPCHandler", "AddPlayerPostInit",
    "AddPrefabPostInitAny", "GetModRPC", "SendModRPCToServer" }) do env[n] = function() end end
setmetatable(env, { __index = function(_, k) error("mod code read a name it does not have: " .. tostring(k), 2) end })
local SimMoves = require("true_range/simmoves")
SimMoves.Pose = function(inst, key, go, ft, x, z, rot, after, aim)
    out[#out + 1] = string.format("%.3f HOST %s: %s %s %.3f %.2f,%.2f %.1f %s aim=%s", now, inst.prefab, key, tostring(go), ft, x, z, rot, after, aim and aim.name or "-")
end
assert(pcall(setfenv(assert(loadfile(root .. "/modmain.lua")), env)))
local tasks = {}
local function Ent(prefab, x, z)
    local e = { prefab = prefab, name = prefab, listeners = {}, components = {}, x = x, z = z, anim = "idle", anim_t0 = 0 }
    e.Transform = { GetWorldPosition = function() return e.x, 0, e.z end, GetRotation = function() return 30 end, GetScale = function() return 1, 1, 1 end }
    e.AnimState = {
        IsCurrentAnimation = function(_, a) return a == e.anim end,
        GetCurrentAnimationTime = function() return now - e.anim_t0 end,
        GetBuild = function() return prefab end,
    }
    function e:IsValid() return not e.gone end
    function e:IsNear(o, r) return (e.x - o.x) ^ 2 + (e.z - o.z) ^ 2 < r * r end
    function e:HasTag() return false end
    function e:DoPeriodicTask(p, f) tasks[#tasks + 1] = { p = p, f = f, who = e } return {} end
    function e:DoTaskInTime(_, f) end
    function e:ListenForEvent(ev, f) e.listeners[ev] = e.listeners[ev] or {} table.insert(e.listeners[ev], f) end
    function e:Remove() e.gone = true for _, f in ipairs(e.listeners.onremove or {}) do f(e) end end
    return e
end
local w = Ent("forest", 0, 0) w.ismastersim = true
for _, f in ipairs(worldposts) do f(w) end
local host, friend = Ent("wilson", 0, 0), Ent("wolfgang", 3, 0)
host.Network, friend.Network = {}, {}
friend.userid = "KU_friend"
G.ThePlayer = host
G.AllPlayers = { host, friend }
local function Boss(prefab, x, z)
    local b = Ent(prefab, x, z)
    b.sg = { mem = {}, statemem = {} }
    b.components.combat = { target = host }
    for _, f in ipairs(posts[prefab] or {}) do f(b) end
    return b
end
local klaus = Boss("klaus", 5, 5)
local far = Boss("klaus", 300, 300)
local deer = Boss("deerclops", -6, 2)
-- (one walking in from well off, 10 units a second - the look at it every 0.3 s while far must not
-- start its poses later than looking every tick)
local walker = Boss("klaus", 0, 62)
walker.anim, walker.anim_t0 = "attack_chomp", 0
-- (each's first move: its key animation)
local function Key(prefab)
    local all = {}
    for _, m in ipairs(SimMoves.Moves(prefab)) do if m.anims ~= nil and m.anims[1] ~= nil then all[#all + 1] = m.anims[1] end end
    table.sort(all)
    return all[1]
end
local kk, dk = Key("klaus"), Key("deerclops")
for t = 1, 90 do
    now = t * FRAMES
    if t == 5 then klaus.anim, klaus.anim_t0 = kk, now klaus.sg.statemem.target = friend far.anim, far.anim_t0 = kk, now end
    if t == 20 then deer.anim, deer.anim_t0 = dk, now klaus.components.combat.target = host end
    if t == 40 then klaus.x = 44 end
    if t == 50 then klaus.x = 5 end
    if t == 60 then deer:Remove() end
    walker.z = 62 - t * 10 * FRAMES
    for _, tk in ipairs(tasks) do if tk.p == 0 and not tk.who.gone then tk.f(tk.who) end end
end
-- (BENCH=n: n more of them far off from everyone - most monsters in a world - 300 ticks timed)
local nb = tonumber(os.getenv("BENCH") or "")
if nb ~= nil then
    for i = 1, nb do Boss(i % 2 == 0 and "klaus" or "hound", 400 + i, 400) end
    collectgarbage("collect")
    local c0, m0 = os.clock(), collectgarbage("count")
    collectgarbage("stop")
    for t = 1, 300 do
        now = 10 + t * FRAMES
        for _, tk in ipairs(tasks) do if tk.p == 0 and not tk.who.gone then tk.f(tk.who) end end
    end
    io.stderr:write(string.format("BENCH %d far off: %.3f ms a tick, %.1f KB a tick made\n", nb, (os.clock() - c0) * 1000 / 300, (collectgarbage("count") - m0) / 300))
    collectgarbage("restart")
end
for _, l in ipairs(out) do print(l) end
print(string.format("pose_send: %d lines", #out))
