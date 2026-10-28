-- Server side: the ranges the game itself checks for something that fights.
--   attack: it starts an attack once the target's edge is this close (Combat:CalcAttackRangeSq)
--   hit:    the attack lands if the target's edge is still this close (Combat:CalcHitRangeSq)
--   area:   splash damage around whoever it hit, this far from them (Combat:DoAreaAttack)
--   radius: its own body size (the "edge" in the lines above is the target's body)
-- Weapons count: their attackrange / hitrange are added the way Combat does.

local Ranges = {}

local function Num(x)
    return type(x) == "number" and x or 0
end

-- Attacks some monsters make in their stategraph instead of with Combat's ranges (read from
-- the game's own stategraph code). Each: radius (plus the target's body, like the game
-- does), offset (how far in front of it the circle's middle is; negative: behind), half (a
-- fan: only this many degrees each side of where it faces hit; none: all round), kind ("hit":
-- its attack, "area": a slam, "aroundtarget": around whoever it's after), and
-- replaces (its Combat hit range isn't what lands: hide that ring).
local Handmade = require("true_range/handmade")

local function Specials(ent)
    if not Handmade.on then
        return nil
    end
    local prefab = ent.prefab
    if prefab == "bearger" or prefab == "mutatedbearger" then
        -- SGbearger: DoArcAttack(inst, 1, BEARGER_MELEE_RANGE) - 90 degrees to each side
        local list = {
            { radius = Num(TUNING.BEARGER_MELEE_RANGE), offset = 1, half = 90, kind = "hit", replaces = true },
        }
        if prefab == "mutatedbearger" then
            -- the butt slam: DoAOEAttack(inst, -1, 4)
            table.insert(list, { radius = 4, offset = -1, kind = "area" })
        end
        return list
    end
    if prefab == "deerclops" or prefab == "icedeerclops" then
        -- SGdeerclops SpawnIceFx: ice spikes out to DEERCLOPS_ATTACK_RANGE in a cone 35
        -- degrees to each side in front, and some 1-3 away behind it; each spike hits what's
        -- within ICESPIKE_RADIUS (1) of it
        local reach = Num(TUNING.DEERCLOPS_ATTACK_RANGE) + 1
        return {
            { radius = reach, offset = 0, half = 35, kind = "hit", replaces = true },
            { radius = 3 + 1, offset = 0, kind = "hit" },
        }
    end
    if prefab == "mutateddeerclops" then
        -- the ice lance: DoIceLanceAOE, ICE_LANCE_RADIUS (5.5) around where it lands (on you)
        return {
            { radius = 5.5, offset = 0, kind = "aroundtarget" },
        }
    end
    return nil
end

-- the ground pound's reach (GroundPounder: the damaging rings, plus how wide each one is)
local function PoundRadius(ent)
    local gp = ent.components.groundpounder
    if gp == nil or Num(gp.damageRings) <= 0 then
        return 0
    end
    local rings = math.min(Num(gp.numRings), Num(gp.damageRings))
    return Num(gp.initialRadius) + Num(gp.radiusStepDistance) * math.max(0, rings - 1) + Num(gp.ringWidth)
end

-- the ground pound's waves as text: "first radius,step,width,damaging rings,delay between"
-- (GroundPounder: wave i hits everything within first + step * (i - 1) + width, ringDelay
-- seconds after the one before)
local function PoundWaves(ent)
    local gp = ent.components.groundpounder
    if gp == nil or Num(gp.damageRings) <= 0 then
        return ""
    end
    return string.format("%.2f,%.2f,%.2f,%d,%.2f", Num(gp.initialRadius), Num(gp.radiusStepDistance),
        Num(gp.ringWidth), math.min(Num(gp.numRings), Num(gp.damageRings)), Num(gp.ringDelay))
end

function Ranges.DecodeWaves(text)
    local a, b, c, d, e = string.match(text or "", "^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$")
    if a == nil then
        return nil
    end
    return { first = tonumber(a) or 0, step = tonumber(b) or 0, width = tonumber(c) or 0,
        rings = tonumber(d) or 0, delay = tonumber(e) or 0 }
end

-- Is its ground pound ready to use? Some keep a cooldown timer for it (Bearger: "GroundPound",
-- which its brain and stategraph check before pounding); the others count as always ready.
local POUND_TIMERS = { bearger = "GroundPound", mutatedbearger = "GroundPound" }

local function TimerName(ent)
    return Handmade.on and POUND_TIMERS[ent.prefab] or nil
end

local function PoundReady(ent)
    local timer_name = TimerName(ent)
    local timer = ent.components.timer
    if timer_name == nil or timer == nil then
        return true
    end
    return not timer:TimerExists(timer_name)
end

-- its cooldown: seconds left (0: ready) and how long the whole cooldown is (0: none known)
local function PoundCooldown(ent)
    local timer_name = TimerName(ent)
    local timer = ent.components.timer
    if timer_name == nil or timer == nil then
        return 0, 0
    end
    local total = timer.timers ~= nil and timer.timers[timer_name] ~= nil and timer.timers[timer_name].initial_time
        or Num(TUNING.BEARGER_NORMAL_GROUNDPOUND_COOLDOWN)
    if not timer:TimerExists(timer_name) then
        return 0, Num(total)
    end
    return Num(timer:GetTimeLeft(timer_name)), Num(total)
end

-- specials as text for the network: "radius,offset,half,kind,replaces;..."
local function Encode(list)
    local parts = {}
    for _, s in ipairs(list or {}) do
        table.insert(parts, string.format("%.2f,%.2f,%d,%s,%d", s.radius, s.offset or 0, s.half or 0,
            s.kind or "hit", s.replaces and 1 or 0))
    end
    return table.concat(parts, ";")
end

function Ranges.Decode(text)
    local list = {}
    for part in string.gmatch(text or "", "[^;]+") do
        local r, o, f, k, rep = string.match(part, "^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$")
        if r ~= nil then
            table.insert(list, { radius = tonumber(r) or 0, offset = tonumber(o) or 0, half = tonumber(f) or 0,
                kind = k, replaces = rep == "1" })
        end
    end
    return list
end

-- nil if it doesn't fight
-- Its moves' cooldowns (the timers the offline runs saw each move start): "name=seconds left;..."
-- (0: ready now)
local SimData = nil
local function Cooldowns(ent)
    SimData = SimData or require("true_range/moves_sim")
    local moves = SimData[ent.prefab] or SimData[(SimData._alias or {})[ent.prefab] or ""]
    local timer = ent.components.timer
    if moves == nil or timer == nil or ent.prefab:sub(1, 1) == "_" then
        return ""
    end
    local out, seen = {}, {}
    for _, entry in pairs(moves) do
        local name = entry.cooldown
        if name ~= nil and not seen[name] then
            seen[name] = true
            local left = timer:TimerExists(name) and timer:GetTimeLeft(name) or 0
            table.insert(out, string.format("%s=%.2f", name, Num(left)))
        end
    end
    return table.concat(out, ";")
end

function Ranges.Of(ent)
    local combat = ent ~= nil and ent:IsValid() and ent.components.combat or nil
    if combat == nil then
        return nil
    end
    local ok, attack, hit = pcall(function()
        return combat:GetAttackRange(), combat:GetHitRange()
    end)
    if not ok then
        attack, hit = combat.attackrange, combat.hitrange
    end
    local area = 0
    if combat.areahitrange ~= nil and not combat.areahitdisabled then
        area = combat.areahitrange
    end
    -- harmless: no damage of its own and no weapon (birds, butterflies, rabbits...)
    local weapon = combat.GetWeapon ~= nil and combat:GetWeapon() or nil
    -- (a weapon that shoots or is thrown - a dart, a staff, a snowball, the Gloomerang: its reach is where
    -- it starts (attack range), the shot then strikes wherever it gets to (Projectile:Hit, ignorehitrange);
    -- its hit range, 2 more, is only the leeway as it's let go - drawn, the ring showed 2 too far; the
    -- client-only build drew the attack range already. A player's only: a monster's dart may be let go
    -- with you out to its hit range - its warning kept that wide)
    local wc = weapon ~= nil and ent:HasTag("player") and weapon.components or nil
    if wc ~= nil and (wc.projectile ~= nil
        or (wc.complexprojectile ~= nil and not wc.complexprojectile.ismeleeweapon)
        or (wc.weapon ~= nil and wc.weapon.CanRangedAttack ~= nil and wc.weapon:CanRangedAttack())) then
        hit = attack
    end
    local harmful = weapon ~= nil or Num(combat.defaultdamage) > 0
        or type(combat.defaultdamage) == "function"
    return {
        attack = Num(attack),
        hit = Num(hit),
        area = Num(area),
        radius = Num(ent:GetPhysicsRadius(0)),
        harmful = harmful,
        pound = PoundRadius(ent),
        waves = PoundWaves(ent),
        pound_ready = PoundReady(ent),
        pound_cd = string.format("%.2f,%.2f", PoundCooldown(ent)),
        specials = Encode(Specials(ent)),
        cds = Cooldowns(ent),
    }
end

return Ranges
