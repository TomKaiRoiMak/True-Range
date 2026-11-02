-- Player side: rings drawn on the ground (the game's own range ring, the one the Ice
-- Flingomatic shows when placed), kept on whatever they belong to.

local Rings = {}

-- the ring texture's size: from the game's c_showradius ("300: game unit to pixel, 1900: the
-- texture's size"; the scale is a square root because the transform's scale counts twice)
local function ScaleFor(radius)
    return math.sqrt(math.max(radius, .05) * 300 / 1900)
end

local COLOURS = {
    hit = { 1, .15, .1, .75 },    -- where its attack lands on you (fainter than a real warning)
    attack = { 1, .85, .1, .6 },  -- where it starts attacking
    area = { .7, .2, 1, .75 },    -- its splash, around whoever it hits
    own = { .2, 1, .3, 1 },       -- your own reach
    own_start = { .2, 1, .3, .5 },
    -- a friend's reach (another player's): light blue, told apart from yours
    friend_own = { .3, .7, 1, .8 },
    -- your body (what monsters' attacks have to reach): safe / in reach of something / just hit
    body = { 1, 1, 1, .9 },
    body_danger = { 1, .6, .05, 1 },
    body_hit = { 1, .05, .05, 1 },
}
-- which ring is drawn over which (higher on top): red over yellow, so where they're the same only
-- red shows
local SORT = { attack = 1, area = 2, hit = 3, own_start = 3, own = 4, friend_own = 4, body = 5, body_danger = 5, body_hit = 5 }
-- how much of the colour is added on top of the texture
local ADD = .55
-- each kind's opacity setting (true_range/settings: op_*); Rings.opacity: the settings' values
-- (modmain gives it)
local OPACITY = { own = "op_you", own_start = "op_you", body = "op_you", body_danger = "op_you", body_hit = "op_you",
    friend_own = "op_others", attack = "op_others" }
Rings.opacity = nil
local function Alpha(kind, a)
    local o = Rings.opacity
    if o == nil then return a end
    return a * (o[OPACITY[kind] or "op_area"] or 1)
end

-- (the ring's texture is light blue: multiplying alone turns colours grey, so the colour is
-- added on top too)
local function Colour(inst, kind)
    local c = COLOURS[kind] or COLOURS.hit
    inst._a = Alpha(kind, c[4])
    inst.AnimState:SetMultColour(c[1], c[2], c[3], inst._a)
    inst.AnimState:SetAddColour(c[1] * ADD, c[2] * ADD, c[3] * ADD, 0)
    inst.AnimState:SetSortOrder(SORT[kind] or 3)
end

local function NewRing(kind)
    local inst = CreateEntity()
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst.AnimState:SetBank("firefighter_placement")
    inst.AnimState:SetBuild("firefighter_placement")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(SORT[kind] or 3)
    Colour(inst, kind)
    return inst
end

-- One ring: `kind` (a colour above) of `radius` around `owner` (an entity, followed as it
-- moves). Rings are kept by key and reused; Sweep removes the ones not touched since Begin.
local rings = {} -- key -> { inst, owner, radius, used }
local round = 0

function Rings.Begin()
    round = round + 1
end

-- offset: the circle's middle this far in front of the owner (negative: behind), turning with it
function Rings.Show(key, kind, owner, radius, offset)
    if owner == nil or not owner:IsValid() or radius == nil or radius <= 0 then
        return
    end
    local r = rings[key]
    if r == nil or not r.inst:IsValid() then
        r = { inst = NewRing(kind), kind = kind }
        rings[key] = r
    elseif r.kind ~= kind then
        r.kind = kind
        Colour(r.inst, kind)
    elseif r.inst._a ~= Alpha(kind, (COLOURS[kind] or COLOURS.hit)[4]) then
        Colour(r.inst, kind)  -- (its opacity setting changed)
    end
    r.owner = owner
    r.offset = offset or 0
    if r.radius ~= radius then
        r.radius = radius
        local s = ScaleFor(radius)
        r.inst.Transform:SetScale(s, s, s)
    end
    r.used = round
end

function Rings.Sweep()
    for key, r in pairs(rings) do
        if r.used ~= round or r.owner == nil or not r.owner:IsValid() then
            if r.inst:IsValid() then
                r.inst:Remove()
            end
            rings[key] = nil
        end
    end
end

-- every frame: rings stay on their owners
function Rings.Follow()
    for _, r in pairs(rings) do
        if r.owner ~= nil and r.owner:IsValid() and r.inst:IsValid() then
            local x, _, z = r.owner.Transform:GetWorldPosition()
            if r.offset ~= 0 then
                local rot = r.owner.Transform:GetRotation() * DEGREES
                x = x + r.offset * math.cos(rot)
                z = z - r.offset * math.sin(rot)
            end
            r.inst.Transform:SetPosition(x, 0, z)
        end
    end
end

function Rings.Clear()
    round = round + 1
    Rings.Sweep()
end

return Rings
