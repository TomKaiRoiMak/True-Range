-- Runs bosses' attacks offline - the game's own stategraph and prefab code, in a small fake
-- world - against dummies laid out all round, and writes where each move hits, for True Range
-- to draw (scripts/true_range/moves_sim.lua).
--
-- run: luajit sim_moves.lua <out.lua> <game scripts dir> [-show]
--   -show: also print each move as a picture (B the boss, P its target, X hit)
--
-- Each move is run with its target standing straight ahead at several distances (attacks aimed
-- at the target change with how far it is), a few times over (some are random); a dummy hit in
-- any run counts. Dummies have a player's body (radius .5): a cell is hit where a player standing
-- there would be.

-- (each run's garbage swept sooner - SIM_GC_PAUSE; Lua's own 200 lets a heap grow to twice what it
-- keeps: 16 runs side by side went to 24 of the machine's 31 GB. 120: a fifth less at their peak
-- (Deerclops and the Shadow Bishop: 9.1 -> 7.3 GB), a seventh longer, the same output to the byte)
collectgarbage("setpause", tonumber(os.getenv("SIM_GC_PAUSE") or "") or 120)

-- (SIM_STABLE_PAIRS=game (the default; SIM_RAW_PAIRS=1: LuaJIT's own)|all: pairs over a table keyed by tables - entities - in a set order, by
-- their GUIDs; LuaJIT's own goes by where each sits in memory, different every process: a run was
-- not the same twice. "game": only where the game's own code goes round one (the harness's own
-- loops over thousands of hits left as they are - sorting those made the crystals 15 times slower))
if os.getenv("SIM_RAW_PAIRS") == nil then
    local stable_pairs_mode = os.getenv("SIM_STABLE_PAIRS") or "game"
    local raw_pairs, raw_next = pairs, next
    local ids, last_id = setmetatable({}, { __mode = "k" }), 0
    local function Id(k)
        local g = type(k) == "table" and rawget(k, "GUID") or nil
        if type(g) == "number" then return g end
        if ids[k] == nil then last_id = last_id + 1 ids[k] = 1e9 + last_id end
        return ids[k]
    end
    local order = { number = 1, string = 2, boolean = 3, table = 4 }
    local sorted_cache = setmetatable({}, { __mode = "k" })
    local function Less(a, b)
        local ta, tb = type(a), type(b)
        if ta ~= tb then return (order[ta] or 9) < (order[tb] or 9) end
        if ta == "number" or ta == "string" then return a < b end
        if ta == "table" then return Id(a) < Id(b) end
        if ta == "boolean" then return (not a) and b end
        return false
    end
    local harness = debug.getinfo(1, "S").source
    -- (SIM_PAIRS_NOCACHE=1: sorted anew every time - slow, sure: to prove the kept orders right)
    pairs_nocache = os.getenv("SIM_PAIRS_NOCACHE") ~= nil
    -- (SIM_ADDR_SHIFT=n: n random-sized tables made and kept first - every address after moved: a
    -- run the same as one without it is no luck of memory falling alike)
    if os.getenv("SIM_ADDR_SHIFT") then
        -- (its own little generator: the game's math.random left untouched)
        local s = tonumber(os.getenv("SIM_ADDR_SHIFT")) or 1
        local function R(n) s = (s * 1103515245 + 12345) % 2147483648 return s % n end
        addr_shift_keep = {}
        for i = 1, 1000 + R(20000) do addr_shift_keep[i] = { string.rep("x", 1 + R(64)) } end
    end
    -- (the harness's loops after a run: from the line "hits apart" begins on, found in this file)
    STABLE_FROM_LINE = math.huge
    do
        local n = 0
        for line in io.lines(arg[0]) do
            n = n + 1
            if line:find("-- hits apart: the boss's own", 1, true) and not line:find("line:find", 1, true) then STABLE_FROM_LINE = n break end
        end
    end
    pairs = function(t)
        local k1 = raw_next(t)
        local tk = type(k1)
        if tk ~= "table" and tk ~= "function" and tk ~= "userdata" then return raw_pairs(t) end
        local mt = getmetatable(t)
        if mt ~= nil and mt.__pairs ~= nil then return raw_pairs(t) end
        if stable_pairs_mode == "game" then
            -- (the harness's own: only its loops after a run, over what it struck - once a run, and
            -- their order goes into what's written; not those going round every frame)
            local info = debug.getinfo(2, "Sl")
            if info.source == harness and info.currentline < STABLE_FROM_LINE then
                if os.getenv("SIM_PAIRS_DBG") then local w = "frame:" .. info.currentline pairs_dbg = pairs_dbg or {} pairs_dbg[w] = (pairs_dbg[w] or 0) + 1 end
                return raw_pairs(t)
            end
        end
        if os.getenv("SIM_PAIRS_DBG") then local info = debug.getinfo(2, "Sl") local w = info.short_src .. ":" .. info.currentline pairs_dbg = pairs_dbg or {} pairs_dbg[w] = (pairs_dbg[w] or 0) + 1 end
        -- (a snapshot of its keys, sorted: changed as it's gone round, it's what it held as it began)
        -- (the same keys as last time it was gone round - the harness's loops one after another
        -- over one run's hits: that order again, not sorted anew)
        local cached = sorted_cache[t]
        local n, same = 0, cached ~= nil
        for k in raw_next, t do n = n + 1 if same and cached.set[k] == nil then same = false end end
        local keys
        if same and n == cached.n and not pairs_nocache then
            keys = cached.keys
        else
            keys = {}
            -- (all of them tables: sorted by their ids as plain numbers - no comparing function)
            local ids, by_id, all_tables = {}, {}, true
            for k in raw_next, t do
                if type(k) ~= "table" then all_tables = false break end
                local id = Id(k)
                ids[#ids + 1] = id
                by_id[id] = k
            end
            if all_tables then
                table.sort(ids)
                for i, id in ipairs(ids) do keys[i] = by_id[id] end
            else
                for k in raw_next, t do keys[#keys + 1] = k end
                table.sort(keys, Less)
            end
            local set = {}
            for _, k in ipairs(keys) do set[k] = true end
            sorted_cache[t] = { n = n, keys = keys, set = set }
        end
        local i = 0
        return function()
            i = i + 1
            local k = keys[i]
            while k ~= nil and rawget(t, k) == nil do i = i + 1 k = keys[i] end
            if k == nil then return nil end
            return k, rawget(t, k)
        end, t, nil
    end
end
local OUT, SCRIPTS = arg[1], arg[2]
-- how long each animation really is (anim_lengths.ps1, next to this file)
local HERE = (arg[0]:match("^(.*)[/\\]") or ".")
ANIM_FILES = dofile(HERE .. "/anim_lengths.lua")
-- (and a mod's own - SIM_MOD_ANIMS=<file>, anim_lengths.ps1 over its anim zips: Uncompromising
-- Mode's Deerclops uppercut, unknown, ended at a second - before it struck)
if os.getenv("SIM_MOD_ANIMS") then
    for file, anims in pairs(dofile(os.getenv("SIM_MOD_ANIMS"))) do ANIM_FILES[file] = anims end
end
-- (an animation's length: from the files whose animation is of its very bank (the game's hash of
-- the bank's name, as the files keep it) - several bosses have an "atk", and a file of another's
-- picked at random made a spider's bite end before it struck, now and then; else the files
-- named after its bank or prefab; else any - always the same one: shortest name, then by name)
local function KleiHash(s)
    local h = 0
    s = s:lower()
    for i = 1, #s do h = (h * 65599 + s:byte(i)) % 4294967296 end
    return h
end
local function Better(file, best) return best == nil or #file < #best or (#file == #best and file < best) end
local anim_len_memo = {}
local AnimLenOf
function AnimLen(e, anim)
    if anim == nil then return 1 end
    local key = tostring(e.bank) .. "|" .. tostring(e.prefab) .. "|" .. anim
    local v = anim_len_memo[key]
    if v == nil then
        v = AnimLenOf(e, anim)
        anim_len_memo[key] = v
    end
    return v
end
function AnimLenOf(e, anim)
    if type(e.bank) == "string" then
        local h, best = KleiHash(e.bank), nil
        -- (not a build's file when another of the bank has it: Tropical Experience's slipstor_build holds a 0.1 s "anim" too,
        -- its attack's 8.6 s one in slipstor_attacks - the game plays that one, 180 struck on the bench; the build's ended
        -- its attack before it struck, 2026-10-21. SIM_OLD_ANIMBUILD=1: as before)
        local skip_build = os.getenv("SIM_OLD_ANIMBUILD") == nil
        local function Ok(file) return not (skip_build and file:find("_build$")) end
        for file, anims in pairs(ANIM_FILES) do
            if anims[anim] ~= nil and anims._banks ~= nil and anims._banks[anim] == h and Ok(file) and Better(file, best) then best = file end
        end
        if best == nil and skip_build then
            for file, anims in pairs(ANIM_FILES) do
                if anims[anim] ~= nil and anims._banks ~= nil and anims._banks[anim] == h and Better(file, best) then best = file end
            end
        end
        if best ~= nil then return ANIM_FILES[best][anim] end
    end
    for _, prefix in ipairs({ e.bank, e.prefab }) do
        if type(prefix) == "string" then
            -- (of the files named so that have it, the nearest name: eyeofterror_action, not
            -- eyeofterror_mini_actions)
            local best = nil
            for file, anims in pairs(ANIM_FILES) do
                if anims[anim] ~= nil and file:sub(1, #prefix) == prefix and Better(file, best) then best = file end
            end
            if best ~= nil then return ANIM_FILES[best][anim] end
        end
    end
    local best = nil
    for file, anims in pairs(ANIM_FILES) do
        if anims[anim] ~= nil and Better(file, best) then best = file end
    end
    if best ~= nil then return ANIM_FILES[best][anim] end
    return 1
end
local SHOW = arg[3] == "-show"
-- (-only=a,b: just these bosses - to look at them; the file written then holds only them)
local only = nil
for i = 3, #arg do
    -- (-ends: struck again for as long as in reach, and when each spot is out of reach written too
    -- - a map's ends: sim_rehit, globals - the main chunk holds all the locals it may)
    if arg[i] == "-ends" then sim_rehit = true end
    local list = arg[i]:match("^%-only=(.+)$")
    if list ~= nil then
        only = {}
        for p in list:gmatch("[^,]+") do
            -- (prefab#i: only its i-th move)
            local name, i = p:match("^([^#]+)#(%d+)$")
            if name ~= nil then
                only[name] = only[name] == true and true or (only[name] or {})
                if type(only[name]) == "table" then only[name][tonumber(i)] = true end
            else
                only[p] = true
            end
        end
    end
end
package.path = SCRIPTS .. "/?.lua;" .. package.path

-- the moves: per boss, its stategraph file and the states its attacks start in
local BOSSES = {
    -- (shield_pre / atk_summon: the gestalts it calls up, flying at you - _hazards)
    { prefab = "alterguardian_phase1", sg = "SGalterguardian_phase1", states = { "roll_start", "tantrum_pre", "shield_pre" } },
    -- (its rift kin: the same stategraph, the same moves - not as found on its own, rolls mid-way)
    { prefab = "alterguardian_phase1_lunarrift", sg = "SGalterguardian_phase1", states = { "roll_start", "tantrum_pre", "shield_pre" } },
    -- (its summon told from its chop by the summon fx it makes at once (SGalterguardian_phase2.lua:596) and by going
    -- again into itself up to twice (:625) - true_range/predict PickAlike, the twins agent 2026-10-19)
    -- (its stab: its own blow round it, at frame 28 - the spike walls its trails raise, 10-20 out every way at random,
    -- drawn on their own as they come (_hazards), not with the stab: things_apart)
    { prefab = "alterguardian_phase2", sg = "SGalterguardian_phase2", states = { "atk_chop", { name = "atk_spike", things_apart = true }, "spin_pre", { name = "atk_summon", extra = { tell = "alterguardian_summon_fx", from_self = 2 } } } },
    -- (atk_traps: crystals land all round at random - their hits are the crystals' own, drawn
    -- around each as it falls: _hazards)
    -- (and before the first is out, where any of them may come down - all of it: round it out to 12.5 (do_traps, its
    -- second ring 5.5 + 7, alterguardian_phase3.lua:190) and each one's 2.25 and your body: nothing shown its first 2
    -- seconds, each then a second before it fell, "late" - the player, 2026-10-20. Not the run's own, its rings' union at
    -- random: 3.5% of it missing at 13-14.5 - drawn, it must cover. Random (where one may come down, pale, no "drawn in, not
    -- struck"), from the first landing (frame 59 out, 31 on: 90) to the last alone (its two chains, 4 from 59 and 6 from 69,
    -- one each 15 frames: out by 144, down by 175; more with more players, each drawn itself))
    -- (its beams aimed at where you were at frame 21 (SGalterguardian_phase3.lua:668-697, turning after you
    -- within 45 and 16): the run's turn test saw it never turn (FRAMEOF: turned 0, stayed 581 - why not yet
    -- found), drawn the way it faced - 233 missed on the 2026-10-18 bench, none drawn at you. Said by hand: target)
    { prefab = "alterguardian_phase3", sg = "SGalterguardian_phase3", states = { "atk_stab", { name = "atk_beam", frame = "target" },
        { name = "atk_sweep", frame = "target" },
        { name = "atk_traps", spot = { ahead = 0, radius = 15.25, single = false, random = true, first = 90, ["until"] = 175, cooldown = "traps_cd", anims = { "attk_skybeam" } } }, "atk_summon_pre",
        { name = "atk_summon_pre", lucky = true } } },
    { prefab = "bearger", sg = "SGbearger", states = { "attack", "attack_combo1", "attack_combo1a", "attack_combo2", "pound" } },
    { prefab = "deerclops", sg = "SGdeerclops", states = { "attack" } },
    -- (its charge as in its later phase - a run of them, each from where it turned: one at a time,
    -- which does for the first phase's single charge too)
    -- (drawn the way they face, not at you - each its game reason, the miscfalse agent 2026-10-19 (the turn test fixed found
    -- them all turning; the bench drew them worse so): the Eye's/Twins' charge steers only while statemem.steering, then lets
    -- go; the mutated Deerclops' swipe turns only within 45 (DiffAngle) and stops at 16; the horns' slap faces in 45s
    -- (SetEightFaced), its jump goes for where you were and drops you; the Shadow Rook's teleport: no code reason found, the
    -- bench drew it worse - 227 -> 428 glitches)
    { prefab = "eyeofterror", sg = "SGeyeofterror", states = { { name = "charge_pre", frame = "facing" }, { name = "charge_pre", mem = { transformed = true }, frame = "facing" }, "chomp" } },
    -- (and enraged: bigger, reaching further - its own Enrage)
    -- (far: enraged, 1.68 times as big, its chomp leaps 9 x 1.68 = 15 - traced 15.1 - at you up to 18 off)
    { prefab = "klaus", sg = "SGklaus", far = 20, states = { "attack", "attack_chomp",
        { name = "attack", setup = "Enrage" }, { name = "attack_chomp", setup = "Enrage" } } },
    -- (its pounce as it comes running at you - most often; and its slam straight off, after a
    -- pounce that hit, or getting up from being worn out)
    { prefab = "daywalker", sg = "SGdaywalker", states = { { name = "attack_pounce_pre", data = { running = true } },
        "attack_slam_pre", "attack_slam" } },
    -- (and enraged - on fire: further reach, and its ground pounds; told apart in the game by its
    -- fiery look - look: what its build's name has in it)
    { prefab = "dragonfly", sg = "SGdragonfly", states = { "attack",
        { name = "attack", setup = "TransformFire", look = "fire" }, { name = "pound_pre", setup = "TransformFire", look = "fire" } } },
    { prefab = "beequeen", sg = "SGbeequeen", states = { "attack" } },
    { prefab = "moose", sg = "SGmoose", states = { "attack" } },
    { prefab = "malbatross", sg = "SGmalbatross", states = { "attack", "swoop_pre" } },
    -- (as it fights: its angry stategraph - sand spikes under you (its sand walls do no harm))
    { prefab = "antlion", sg = "SGantlion_angry", states = { "summonspikes" } },
    -- smaller monsters and animals (also: others made the same way, drawn the same - _alias)
    { prefab = "hound", sg = "SGhound", states = { "attack" },
        also = { "firehound", "icehound", "moonhound", "clayhound", "mutatedhound", "hedgehound" } },
    { prefab = "spider", sg = "SGspider", states = { "attack" }, also = { "spider_hider", "spider_healer" } },
    -- (the Sea Strider: its own stategraph, smaller than a spider - not drawn as one)
    { prefab = "spider_water", sg = "SGspider_water", states = { "attack" } },
    -- (the Dangling Depth Dweller leaps as a warrior does (warrior_attack) - drawn as a spider, its 422 leaps
    -- on the testbench were all struck undrawn; VERIFY_PLAN 6.0a)
    { prefab = "spider_warrior", sg = "SGspider", states = { "attack", "warrior_attack" }, also = { "spider_dropper" } },
    -- (the Shattered Spider: its spikes (spike_attack - moonspider_spike, each striking with its own combat,
    -- as it comes up and as it breaks): its own, not a spider's - 129 of 134 struck undrawn so)
    { prefab = "spider_moon", sg = "SGspider", states = { "attack", "spike_attack" } },
    -- (the Spitter: its bite; its web, spat from further, drawn as it flies - modmain DARTS)
    { prefab = "spider_spitter", sg = "SGspider", no_auto = { "spitter_attack" }, states = { "attack" } },
    { prefab = "tallbird", sg = "SGtallbird", states = { "attack" } },
    { prefab = "pigman", sg = "SGpig", states = { "attack",
        -- (gone werepig at full moon: its werepig bite - another stategraph, its own animations)
        { name = "attack", sg = "SGwerepig" },
        -- (Hallowed Nights' monster kinds (game 760944, TUNING.HN_MONSTER_CHANCE): the franken pig, the vampire bunny, the
        -- mummy merm - a jump forward, struck at 12 (hn_attack, SGpig.lua :539, SGbunnyman.lua :462, SGmerm.lua :1237). Its
        -- animation begun at its frame 4 (SetFrame(4)): anim_from - true_range times a move by its animation's own clock)
        { name = "hn_attack", extra = { anim_from = 4 } } }, also = { "pigguard" } },
    { prefab = "bunnyman", sg = "SGbunnyman", states = { "attack", { name = "hn_attack", extra = { anim_from = 4 } } } },
    { prefab = "merm", sg = "SGmerm", states = { "attack", { name = "hn_attack", extra = { anim_from = 4 } } }, also = { "mermguard", "merm_shadow", "mermguard_shadow", "merm_lunar", "mermguard_lunar" } },
    -- (the pigs of the moon event, at the Moon Stone)
    { prefab = "moonpig", sg = "SGmoonpig", states = { "attack" } },
    { prefab = "beefalo", sg = "SGBeefalo", states = { "attack" } },
    { prefab = "koalefant_summer", sg = "SGkoalefant", states = { "attack" }, also = { "koalefant_winter" } },
    { prefab = "lightninggoat", sg = "SGlightninggoat", states = { "attack" } },
    { prefab = "killerbee", sg = "SGbee", states = { "attack" }, also = { "bee" } },
    { prefab = "mosquito", sg = "SGmosquito", states = { "attack" } },
    { prefab = "frog", sg = "SGfrog", states = { "attack" }, also = { "lunarfrog" } },
    { prefab = "bat", sg = "SGbat", states = { "attack" } },
    -- (not its belly slide's "attack" (runningattack): it strikes on its first frame - nothing to warn
    -- of - and its slide_bounce is every slide's start too, drawn as a strike each time one set off;
    -- nor its walk after a peck, part of that move - drawn on as it walked off)
    { prefab = "penguin", sg = "SGpenguin", states = { "attack" }, no_auto = { "runningattack" }, stop = { "walk" } },
    { prefab = "mutated_penguin", sg = "SGpenguin", states = { "attack" }, no_auto = { "runningattack" }, stop = { "walk" } },
    { prefab = "catcoon", sg = "SGcatcoon", states = { "attack", "pounceattack" } },
    { prefab = "ticoon", sg = "SGticoon", states = { "attack" } },
    { prefab = "tentacle", sg = "SGtentacle", states = { "attack_pre" } },
    { prefab = "krampus", sg = "SGkrampus", states = { "attack" } },
    { prefab = "knight", sg = "SGknight", states = { "attack" }, also = { "knight_nightmare" } },
    -- (the Year of the Horse knights - its four horsemen: their kick, and their joust: turning to you till
    -- frame 18, then riding on at 8 (YOTH_KNIGHT_JOUST_SPEED), lance first, up to three times round its
    -- loop while you're ahead of it - run as it is, its target handed it)
    { prefab = "knight_yoth", sg = "SGknight", no_auto = { "joust_pre" }, states = { "attack",
        -- (one lane, set as it sets off (frame 18) - not after you: it turns but a degree a frame then; run
        -- as it was, its way picked by how far you were, the lane slid after you. 16.1 on - its three loops,
        -- jousting from 6 to 14 off (YOTH_KNIGHT_JOUST_RANGE); 11.3 only if you're by it as it begins its
        -- second; its lance 2.6 ahead, some 1 aside, and your body)
        { name = "joust_pre", ram = { dist = 17.6, time = 2.9, aim = 18 / 30, lock = 18, speed = 8, reach = 1.5, straight = true,
            anims = { "joust_pre", "joust_loop", "joust_pst1" } } } } },
    -- (the Clockwork Rook's charge: its brain's ChaseAndRam, as the Ancient Guardian's - pawing a second
    -- (run_start's timeout), turning to you till frame 15, then straight on: MAX_CHARGE_DIST 25,
    -- MAX_CHASE_TIME 5; ramming whoever's ahead of it within its hit range (2) and your body. Not its crash
    -- (runningattack, atk_collide) on its own: it strikes as it begins, its shape only after - part of the charge)
    { prefab = "rook", sg = "SGrook", also = { "rook_nightmare" }, no_auto = { "run_start", "run", "runningattack" }, states = {
        { name = "run_start", ram = { dist = 25, time = 5, aim = 1, lock = 15, front = true, anims = { "atk_pre", "paw_loop", "atk", "atk_collide" } } },
        -- (and its quick start, no pawing: "run" handed true - struck, or told to attack with you near
        -- (SGrook.lua:27-30, :481-500 CanQuickStartRun), faced to you once and straight on, atk at once - 4 off, it
        -- struck you its 6th frame, never drawn: 269 of the Nightmare Rook's 569 blows, once the testbench
        -- struck back, 2026-10-19)
        { name = "run", ram = { dist = 25, time = 5, aim = 0, lock = 0, front = true, anims = { "atk", "atk_collide" } } } } },
    -- (not the Rook: how far it charges is its brain's say, not its stategraph's)
    { prefab = "warg", sg = "SGwarg", states = { "attack" }, also = { "claywarg", "gingerbreadwarg" } },
    -- more bosses
    { prefab = "mutateddeerclops", sg = "SGdeerclops", states = { { name = "attack", frame = "facing" }, { name = "laserbeam", frame = "facing" }, "icelance",
        -- (thrown again straight after: its other arm, another animation)
        { name = "icelance", mem = { noice = 0 } } }, own_hazards = true },
    -- (not "attack": standing up first (taunt_pre), as it does after a pound too - its swipe that
    -- follows is the combo's atk1; and its butt slam, from standing or on the run)
    { prefab = "mutatedbearger", sg = "SGbearger", states = { "attack_combo1", "attack_combo1a", "attack_combo2", "pound", { name = "butt", data = {}, behind = true, facing = true } }, no_auto = { "attack" } },
    -- (and its fire breath: sweeping -45 to 45 degrees ahead of it, the Possessed Varg's)
    { prefab = "mutatedwarg", sg = "SGwarg", states = { "attack", { name = "flamethrower_pre", fan = { from = 3, to = 9, angle = 50,
        -- (its flames 0.9 round each, scaled up to 1.65 - and your body; its sweep -45 to 45, snapped to
        -- 45s as it aims: a little more each way)
        -- (the warning before its first flame - its flames once out drawn as they are, _hazards - and on all
        -- through its loop: its own breath round its mouth strikes every frame of it (SGwarg DoFlamethrowerAOE,
        -- 1.7 round a spot 3 ahead, swept with it), no flame there - gone after its first flame, 27 of its
        -- blows struck undrawn, 2026-10-20. Not in its pst: no breath of its own there)
        reach = 2.4, first = 19, lock = 16, again = { 58, "atk_breath_loop", 28 }, anims = { "atk_breath_pre", "atk_breath_loop", "atk_breath_pst" } } } } },
    { prefab = "twinofterror1", sg = "SGeyeofterror", states = { { name = "charge_pre", frame = "facing" }, { name = "charge_pre", mem = { transformed = true }, frame = "facing" }, "chomp" } },
    { prefab = "twinofterror2", sg = "SGeyeofterror", states = { { name = "charge_pre", frame = "facing" }, { name = "charge_pre", mem = { transformed = true }, frame = "facing" }, "chomp" } },
    { prefab = "toadstool", sg = "SGtoadstool", states = { "attack", "pound_pre", "sporebomb", "mushroombomb" } },
    -- (the Misery Toadstool on its own: its bombs are its own - mushroombomb_dark, never drawn as the other's)
    { prefab = "toadstool_dark", sg = "SGtoadstool", states = { "attack", "pound_pre", "sporebomb", "mushroombomb" } },
    -- (its stomp in place starts the same as its leap at you - jump_atk_pre - and can't be told apart
    -- as it starts: the leap's drawn, the later of the two here)
    { prefab = "minotaur", sg = "SGminotaur", states = { "attack", "runningattack", "leap_attack_pre",
        -- (its charge: its brain's ChaseAndRam - lined up while it paws (run_start, 1.5s), then
        -- straight on: MAX_CHARGE_DIST 25, MAX_CHASE_TIME 5)
        { name = "run_start", ram = { dist = 25, time = 5, aim = 1.5, anims = { "atk_pre", "paw_loop", "atk", "gore" } } } },
        -- (and kept out once a ground pound counted as harm (2026-10-20): drawn as a move, the leap took its shape now
        -- and then - 4 more glitches, bench 1049)
        no_auto = { "stomp" } },
    -- (its dropkick: faced at you as it begins, off at 10 frames, straight on a second at 12
    -- (RABBITKING_ABILITY_DROPKICK_SPEED, _MAXAIRTIME), striking whoever comes within 2 of its
    -- middle (its body .5, _HITRADIUS 1.5) - its whole way whoever's where, stopping at the first
    -- it strikes - its last look round at frame 39, 11.6 on: 12 drew the lane's end yellow, the
    -- move over before it went red. Run as it is, it stopped at the first dummy: only a ring where it struck you,
    -- 3.5 round (its combat's), none of its way)
    { prefab = "rabbitking_aggressive", sg = "SGrabbitking", also = { "rabbitking_passive", "rabbitking_lucky" }, no_auto = { "ability_dropkick" }, states = {
        { name = "ability_dropkick", ram = { dist = 11.6, time = 1, aim = 10 / 30, lock = 0, speed = 12, reach = 2, straight = true,
            anims = { "dropkick_pre", "dropkick_loop", "dropkick_hit", "dropkick_hit_pst" } } } } },
    -- (the Umbral Abomination's optic blast: gone into from its "dofarattack" and its stategraph's own (SGshrouden
    -- :23, :66), not found by the scan - it vanishes, comes down on its target and blasts (shrouden_optic_blast_fx);
    -- 2026-10-23 update - its other attacks found as they are)
    -- (its teleport held underground as long as its code says (SGshrouden teleport_loop: PushAnimation, its state's own
    -- time) - 1.2 s offline, 2.9 in the game: its clock set as it comes up (sync: anim_at for that animation))
        -- (its optic blast striking round where it is now as it chases you down (optic_blast_loop, its fx with it): drawn so - laid
    -- where it began, 60 "drawn in, not struck" -> 10; 2026-10-26)
    { prefab = "shrouden", sg = "SGshrouden", states = { { name = "optic_blast_pre", still = true }, { name = "teleport_pre", sync = { teleport_pst = true } } } },
    -- (its spike spiral round its atrium gate, not round itself (stalker.lua GenerateSpiralSpikes: entitytracker
    -- "stargate" or itself) - run here with none, round itself: true_range/predict sim.round lays it round the gate
    -- when there's one by (its arena 14.55 round it, atrium_gate.lua:26); the caves' Stalker has none)
    { prefab = "stalker_atrium", sg = "SGstalker", states = { "attack", { name = "snare", targets = true },
        { name = "spikes", extra = { round = "atrium_gate", round_within = 20 } } }, also = { "stalker" } },
    { prefab = "spiderqueen", sg = "SGspiderqueen", states = { "attack" } },
    { prefab = "leif", sg = "SGLeif", states = { "attack" }, also = { "leif_sparse" } },
    { prefab = "crabking_claw", sg = "SGcrabkingclaw", states = { "attack" } },
    -- (its dives and its torpedo aim ahead of you: where you'll be .3s on, as fast as you go;
    -- turning only so far - its dive from swimming, the way it has come round to)
    { prefab = "sharkboi", sg = "SGsharkboi", states = { "attack1", "attack2", "attack3", { name = "torpedo_pre", lead = .3 },
        { name = "dive_jump_delay", facing = true, lead = .3 }, { name = "standing_dive_jump_pre", facing = true, lead = .3 } } },
    { prefab = "daywalker2", sg = "SGdaywalker2", states = { "attack_swing", "cannon_pre", { name = "throw_pre", all_hits = true }, "tackle_pre", "attack_pounce_pre" }, own_hazards = true },
    { prefab = "wagboss_robot", sg = "SGwagboss_robot", init = "ConfigureHostile", states = { "stomp", "leap_pre", "missiles_pre", { name = "signal_pre", fields = { canorbitalstrike = true, canhackdrones = false } } } },
    { prefab = "alterguardian_phase4_lunarrift", sg = "SGalterguardian_phase4_lunarrift", states = { "slam", "dash_pre", "supernova" }, own_hazards = true },
    { prefab = "shadow_rook", sg = "SGshadow_rook", states = { { name = "attack", frame = "facing" }, { name = "attack", setup = "LevelUp", frame = "facing" }, { name = "attack", setup = "LevelUp,LevelUp", frame = "facing" } } },
    -- (and at levels 2 and 3: bigger, reaching further - told apart by their size)
    { prefab = "shadow_knight", sg = "SGshadow_knight", states = { "attack", "attack_short", "attack_long",
        { name = "attack", setup = "LevelUp" }, { name = "attack_short", setup = "LevelUp" }, { name = "attack_long", setup = "LevelUp" },
        { name = "attack", setup = "LevelUp,LevelUp" }, { name = "attack_short", setup = "LevelUp,LevelUp" }, { name = "attack_long", setup = "LevelUp,LevelUp" } } },
    { prefab = "shadow_bishop", sg = "SGshadow_bishop", states = { "attack", { name = "attack", setup = "LevelUp" }, { name = "attack", setup = "LevelUp,LevelUp" } } },
    -- (Jitters: it strikes as it runs at you, each stride (frames 11-13 of its run) - no state of
    -- its own for it, so never picked up by name)
    -- (SIM_HANDS_SHROUDEN=1 -only=shadowthrall_hands: as the Umbral Abomination calls them up instead (shrouden_run, handed a
    -- count) - run once so, its first stride the same as run_start's; kept in moves_hand from run_pre's, 2026-10-26)
    { prefab = "shadowthrall_hands", sg = "SGshadowthrall_hands", states = { os.getenv("SIM_HANDS_SHROUDEN") and { name = "shrouden_run", noarg = true } or "run_start" } },
    -- (the Deadly Brightshade's vines: their ends strike round themselves (frame 17 of "atk") - their
    -- own stategraph, never picked up: not a prefab of their own file)
    { prefab = "lunarthrall_plant_vine_end", sg = "SGlunarthrall_plant_vine", states = { "attack" } },
    { prefab = "shadowthrall_horns", sg = "SGshadowthrall_horns", states = { { name = "jump", frame = "facing" }, "spit", { name = "slap", frame = "facing" } } },
    -- (stop: its bite after landing only now and then - in reach, off cooldown: a move of its own)
    -- (not its getting over it (bite_pst, stalk_smile_pst): part of the move, its bite's shape went on
    -- after you, re-aimed, its biting done. Its bites: each the way it faces, where it is (still, facing) -
    -- it turns but 45 between bites, none in one; drawn at you all along, its last went on aiming)
    -- (its last bite on its own, straight from landing: written by hand (true_range/moves_hand.lua) - a state of its
    -- own here cut it out of bite_pre's run, 22 -> 102 undrawn, 2026-10-19)
    -- (SIM_MOUTH_SHROUDEN=1 -only=shadowthrall_mouth: as the Umbral Abomination calls it up instead - out of a portal, its first
    -- bite at frame 8 (shrouden_bite, portal_appear), its bites on after that its own moves; kept in moves_hand, 2026-10-27)
    { prefab = "shadowthrall_mouth", sg = "SGshadowthrall_mouth", cut = { "bite_pst", "stalk_smile_pst" }, states = os.getenv("SIM_MOUTH_SHROUDEN")
        and { { name = "shrouden_bite", facing = true, stop = { "shrouden_bite_loop", "shrouden_bite_final" } } }
        or { { name = "leap_pre", stop = { "bite_loop", "bite_final" } }, { name = "bite_pre", still = true, facing = true }, { name = "land", stop = { "bite_loop", "bite_final" } } } },
    { prefab = "shadowthrall_wings", sg = "SGshadowthrall_wings", states = { "cast" } },
    { prefab = "lunarthrall_plant", sg = "SGlunarthrall_plant", states = { "attack" } },
    { prefab = "gestalt_guard_evolved", sg = "SGgestalt_guard_evolved", states = { "attack", "attack_mid", "attack_far" } },
    -- (its second blow goes on into a third, re-aimed at you then: the second drawn up to it)
    -- (its leap (attack3): at frame 30 at you only if you're within 45 of the way it faces (DiffAngle < 45) - landing 1 short
    -- of you; further round, straight on 4 the way it faces, you or not (dist = 4): run with you before it always, drawn at
    -- you as it leapt off the other way, "the Ancient Guard Tower's leap still misses", the player 2026-10-22 -
    -- ahead_if_off / ahead_dist (5: drawn as for one 5 off, landing 1 short), true_range/predict)
    { prefab = "vault_pillar_guard", sg = "SGvault_pillar_guard", states = { "attack1", "attack2",
        { name = "attack3", extra = { ahead_if_off = 45, ahead_dist = 5 } }, "spin_pre",
        { name = "attack3", fields = { anim = "atk_2" }, extra = { ahead_if_off = 45, ahead_dist = 5 } } }, stop = { "atk_3_pre_a" } },
    { prefab = "stageusher", sg = "SGstageusher", states = { "attack" } },
    -- (and its roll - into you, on and on (roll_start): not run, never drawn - tools/nomove_check.lua, 2026-10-20)
    { prefab = "archive_centipede", sg = "SGcentipede", states = { "atk_aoe", "roll_start" } },
    { prefab = "fused_shadeling", sg = "SGfused_shadeling", states = { "jump_pre", "attack" } },
    -- more monsters
    { prefab = "rocky", sg = "SGrocky", states = { "attack" } },
    { prefab = "worm", sg = "SGworm", states = { "attack_pre" } },
    -- (its leap: 6.67 on the way it faces as it begins (20 a second, frames 20 to 30 - every one in the
    -- game went 6.67), biting whoever's within 2 of its middle there (IsNear) - stopped short by you in
    -- its way, there: its whole way (spec spot, lane); then onto your head, 2 on (8 a second, 8 to 23),
    -- at frame 24 within 2)
    { prefab = "slurper", sg = "SGslurper", no_auto = { "attack", "headslurp" }, states = {
        { name = "attack", spot = { ahead = 6.67, radius = 2, first = 30, go = { 20, 30 }, lane = true, anims = { "atk" } } },
        { name = "headslurp", spot = { ahead = 2, radius = 2, first = 23, go = { 8, 23 }, lane = true, anims = { "headslurp" } } } } },
    { prefab = "eyeplant", sg = "SGeyeplant", states = { "attack" } },
    { prefab = "tentacle_pillar_arm", sg = "SGtentacle_arm", states = { "attack" } },
    { prefab = "bigshadowtentacle", sg = "SGbigshadowtentacle", states = { "attack_pre" } },
    { prefab = "mossling", sg = "SGmossling", states = { "spin_pre" } },
    { prefab = "birchnutdrake", sg = "SGbirchnutdrake", states = { "attack_leap" } },
    { prefab = "deer_red", sg = "SGdeer", states = { "attack", { name = "magic_pre", targets = true, all_hits = true } } },
    { prefab = "deer_blue", sg = "SGdeer", states = { "attack", { name = "magic_pre", targets = true, all_hits = true } } },
    { prefab = "buzzard", sg = "SGbuzzard", states = { "attack" } },
    { prefab = "lavae", sg = "SGlavae", states = { "attack" } },
    { prefab = "eyeofterror_mini", sg = "SGeyeofterror_mini", states = { "attack" } },
    { prefab = "grassgator", sg = "SGgrassgator", states = { "attack" } },
    { prefab = "mushgnome", sg = "SGmushgnome", states = { "attack_pre" } },
    -- (not its phlegm as a move: it's spat afar, drawn where it lands - spat_bomb; as a move, a ring
    -- round it that never struck)
    { prefab = "spat", sg = "SGspat", no_auto = { "launchprojectile" }, states = { "attack" } },
    { prefab = "crawlinghorror", sg = "SGshadowcreature", states = { "attack" }, also = { "terrorbeak", "crawlingnightmare", "nightmarebeak" } },
    -- (the ruins' nightmares: their own stategraph - their horns closing on you are true_range's own, modmain)
    -- (round where it stands (still): it dashes only once rifts have made it planar - the
    -- ruins' own stand, run here as dashing, its shape slid on after you)
    { prefab = "ruinsnightmare", sg = "SGruinsnightmare", states = { { name = "attack", still = true }, { name = "attack", lasttags = { moving = true }, still = true } }, stop = { "taunt" } },
    { prefab = "wagdrone_flying", sg = "SGwagdrone_flying", states = { "attack" } },
    { prefab = "oceanhorror", sg = "SGoceanshadowcreature", states = { "attack" } },
    { prefab = "shadow_leech", sg = "SGshadow_leech", states = { "jump_pre" } },
    { prefab = "cave_vent_mite", sg = "SGcaveventmite", states = { "attack", "blow_attack" } },
    -- (the Lustrous Weevil: turning to you till frame 7, it lunges 0.9 on (frames 11 to 17) and bites at 13 and
    -- 14 - within 1.9 (VAULT_CRAWLER_HIT_RANGE) and your body of it, some 0.4 on then (in the game; 0.76 its
    -- code's speeds say, drawn 0.36 too far): there, set, the way
    -- it faces (spec spot) - run as it was, its shape slid on with its lunge as it bit)
    { prefab = "vault_crawler", sg = "SGvault_crawler", no_auto = { "attack" }, states = {
        -- (and only within 60 degrees either way of where it faces as it bites - VAULT_CRAWLER_HIT_ARC 120, the
        -- game's Combat:CanHitTarget: drawn all round it, you stepped round it after frame 7 were drawn in, never
        -- bitten - 193 drawn-in-unstruck on the bench, 2026-10-20)
        -- (turning to you on till frame 7 - statemem.tracking: the arc drawn the way it faces till then, not set as
        -- it began - set at 0, 79 of its bites were outside it, you stepped round it before frame 7)
        { name = "attack", spot = { ahead = 0.4, radius = 2.4, arc = 120, lock = 7, first = 13, go = { 11, 14 }, anims = { "attack" } } } } },
    -- (the monster once it shows itself - "chest_mimic" is the chest it hides as)
    { prefab = "chest_mimic_revealed", sg = "SGchest_mimic", states = { "attack" } },
    { prefab = "teenbird", sg = "SGtallbird", states = { "attack", "peck" } },
    { prefab = "smallbird", sg = "SGsmallbird", states = { "attack" } },
    { prefab = "mutatedbird", sg = "SGbird_mutant", states = { "attack" } },
    -- (the Misshapen Bird that spits: its "attack" throws bile - drawn where it lands (bilesplat); as a
    -- move, a ring round it that never struck)
    { prefab = "bird_mutant_spitter", sg = "SGbird_mutant", no_auto = { "attack", "shoot" }, states = {} },
    -- (and its dive at you from above, stuck in the ground after (flydown, stab): not run, never drawn - tools/nomove_check.lua)
    { prefab = "beeguard", sg = "SGbeeguard", states = { "attack", "flydown" } },
    -- (the lunar plant's tentacle: its lash - no entry at all, never drawn - tools/nomove_check.lua, 2026-10-20)
    { prefab = "lunarplanttentacle", sg = "SGlunarplanttentacle", states = { "attack" } },
    -- (and its blowdart: shot at frame 20 at where you are then, straight on at 60 (not homing) up to
    -- 25 from its middle (WALRUS_DART_RANGE, from where it stood), set off 3 ahead of it (its launch offset)
    -- towards you from there (launch: its lane from there, not from its middle) - striking you if within its hit
    -- distance (sqrt 5, 2 up) and your body: some 1.4 and your body aside. Run offline at your
    -- distances up to 16 it was drawn that far only - it struck you at 18 to 22)
    -- (its dart: not drawn as a move - two lanes, the move's and the dart's own, were one too many: the
    -- dart's, as it really flies, only - true_range modmain DARTS)
    -- (its blowdart in its hands first, as it is by the time it fights (EquipBlowdart, 1 s on): its attack only shoots - the
    -- dart drawn as it flies (true_range DARTS); with none yet, it struck you from 15 off, a huge dark ring never striking,
    -- the player 2026-10-22)
    { prefab = "walrus", sg = "SGwalrus", also = { "little_walrus" }, no_auto = { "blowdart" }, states = {
        { name = "attack", prep = function(boss) rawget(_G, "SIM_RUN_OWN_TASKS")(boss, 1.5) end } } },
    -- (the Gnarwail's body slam: come up 10 off you (its dive, a second away at DIVE_SPEED 10), it leaps at
    -- where you stood, striking at frame 33 round where it lands (DAMAGE_RADIUS) - drawn from as it leaps
    -- (attack_2); its wind-up (submerge) is every dive's. How far it gets isn't its own say - stopped short
    -- by what's in its way, 7 of its 11 in the game: round where it is (still), its strike there. Its horn on
    -- boats: not drawn)
    { prefab = "gnarwail", sg = "SGgnarwail", states = { { name = "body_slam", data = "@target_pos", still = true } } },
    -- (the pirate monkeys' captain - and the Dragon Boat race's, the same: its cutlass swipe)
    { prefab = "prime_mate", sg = "SGprimemate", states = { "attack" }, also = { "boatrace_primemate" } },
    -- (a Sea Weed: nothing of its own drawn - it spits from afar (waterplant_projectile, drawn where it
    -- lands); run as a move, its range was drawn round it as if it struck there)
    { prefab = "waterplant", sg = "SGwaterplant", no_auto = { "attack" }, states = {} },
    -- (its spin: drawn round where it is, all along - spec still)
    { prefab = "squid", sg = "SGsquid", states = { { name = "attack", still = true } } },
    -- (its bite: three snaps with no one aimed at (DoAttack()) - a miss strikes round it (SetAreaDamage);
    -- miss_area tried 2026-10-17: maps empty at many distances, reach 3.55, misses at 2 and 4 unchanged (206)
    -- - not yet understood, left off; VERIFY_PLAN 6.0a)
    -- (its plain attack only on the water, its bite only off it (sharkbrain.lua:41, 198-208): told apart by where it is)
    { prefab = "shark", sg = "SGshark", states = { { name = "attack", extra = { on = "water" } }, { name = "bite", extra = { on = "ground" } } } },
    -- (their spin: turned to you again as it sets off (frame 14), then straight on 0.7 s at 8 x its size
    -- (the knight 1.7: 13.6, 9.5 on - so in the game), striking 2.5 round 0.4 behind its middle (AOEAttack)
    -- and your body all the way - its lane 0.4 short of where it gets;
    -- run with you close, it stopped at you - in the game it spins on through)
    { prefab = "crabking_mob", sg = "SGcrabking_mob", no_auto = { "spin_attack" }, states = { "attack",
        { name = "spin_attack", ram = { dist = 5.2, time = 0.75, aim = 14 / 30, lock = 14, speed = 8, reach = 2.5, straight = true, anims = { "atk_pre", "atk_loop", "atk_pst" } } } } },
    { prefab = "crabking_mob_knight", sg = "SGcrabking_mob", no_auto = { "spin_attack" }, states = { "attack",
        { name = "spin_attack", ram = { dist = 9.1, time = 0.75, aim = 14 / 30, lock = 14, speed = 13.6, reach = 2.5, straight = true, anims = { "atk_pre", "atk_loop", "atk_pst" } } } } },
    { prefab = "pigelitefighter1", sg = "SGpigelitefighter", states = { "attack" }, also = { "pigelitefighter2", "pigelitefighter3", "pigelitefighter4" } },
    -- (the Pig King's four in its game - Wade, Ignatius, Dmitri, Sawyer: their prop swung, knocking you back
    -- (no harm) within 1.7 and your body of a spot 0.8 ahead, at frame 7 - DoAOEAttack, spec spot)
    { prefab = "pigelite1", sg = "SGpigelite", no_auto = { "attack" }, also = { "pigelite2", "pigelite3", "pigelite4" }, states = {
        { name = "attack", spot = { ahead = 0.8, radius = 2.2, first = 7, anims = { "atk_object" } } } } },
    -- (the Rabbit King's Royal Rabbit Enforcers)
    { prefab = "rabbitkingminion_bunnyman", sg = "SGrabbitking_bunnyman", states = { "attack" } },
    { prefab = "bishop", sg = "SGbishop", states = { "attack" }, also = { "bishop_nightmare" } },
    { prefab = "monkey", sg = "SGmonkey", states = { "attack" } },
    { prefab = "stalker_minion", sg = "SGstalker_minion", states = { "attack" } },
}
-- (a mod's own moves - SIM_MOD_SPEC=<file> (tools/sim_mods/<mod>.lua): a boss of the game's it
-- changes put in place of the game's, one of its own added)
if os.getenv("SIM_MOD_SPEC") then
    for _, d in ipairs(dofile(os.getenv("SIM_MOD_SPEC"))) do
        -- (alias_of: drawn as another - tools/mod_diff.lua's; nothing to run here)
        local put = d.striker ~= nil or d.alias_of ~= nil  -- (a thing of its own, no boss: below, with STRIKERS)
        -- (add: these states as well as the game's own listed ones - one the mod puts in, not
        -- tagged "attack" (Bee Queen's stomp); a boss not listed: one of its own, d.sg)
        if d.add ~= nil then
            for _, b in ipairs(BOSSES) do
                if b.prefab == d.prefab then
                    for _, s in ipairs(d.add) do table.insert(b.states, s) end
                    if d.no_auto ~= nil then b.no_auto = b.no_auto or {} for _, s in ipairs(d.no_auto) do table.insert(b.no_auto, s) end end
                    if d.dummy_player then b.dummy_player = true end
                    if d.strikes_running then b.strikes_running = d.strikes_running end
                    put = true
                    break
                end
            end
            -- (no_auto: states the scan would add that aren't its - one the same animations as one it uses)
            if not put then BOSSES[#BOSSES + 1] = { prefab = d.prefab, sg = d.sg, states = d.add, no_auto = d.no_auto, dummy_player = d.dummy_player, strikes_running = d.strikes_running } end
            put = true
        end
        for i, b in ipairs((d.add == nil and d.alias_of == nil) and BOSSES or {}) do
            -- (keep_game: not run here - the game's own data, the mod's changes not its)
            if b.prefab == d.prefab then
                if d.keep_game then table.remove(BOSSES, i) else BOSSES[i] = d end
                put = true
                break
            end
        end
        if not put and not d.keep_game then BOSSES[#BOSSES + 1] = d end
    end
end
-- (and every other thing that fights, found in the game's own files: a prefab with combat and a
-- stategraph, its attacks the states tagged "attack" that no other attack goes on into - not the
-- player's own kind, its helpers, the side modes (the Forge, the Gorge), what isn't a monster)
do
local AUTO_SKIP = { "^lavaarena", "^quagmire", "^player", "^wilson", "^willow", "^wendy", "^wolfgang", "^wx78", "^wickerbottom",
    "^woodie", "^wes$", "^waxwell", "^wathgrithr", "^webber", "^winona", "^warly", "^wortox", "^wormwood", "^wurt",
    "^walter", "^wanda", "^wonkey", "^abigail", "^bernie", "^yotb", "^yotc", "^yotd", "^carnival", "^balloon", "^boat",
    "^wall", "^eyeturret", "^shadowwaxwell", "^polly", "^chester", "^hutch", "^glommer", "^critter", "^kitcoon",
    "^pocketwatch", "^punchingbag", "^dummytarget", "^deck_of_cards", "^smashables", "^fence$", "^pumpkin_lantern",
    "^houndwarning", "^battlesong", "^trap", "^wagstaff", "^lavae_pet", "^ticoon", "^butterfly", "^moonbutterfly",
    "^lightflier", "^dustmoth", "^carrat", "^rabbit$", "^grassgekko", "^wobster", "^lightcrab", "^canary", "^perd$",
    "^babybeefalo", "^stalker_forest", "^mandrake_planted", "^gingerbreadhouse", "^ghost$" }
local function AutoSkip(name)
    for _, pat in ipairs(AUTO_SKIP) do if name:find(pat) then return true end end
    return false
end
SIM_SG_WEAPON = SIM_SG_WEAPON or {}   -- (stategraph -> state -> the weapon its "doattack" goes there with: { tag, has } - a global: read where the moves run)
local function AutoBosses()
    local have = {}
    for _, b in ipairs(BOSSES) do
        have[b.prefab] = true
        for _, a in ipairs(b.also or {}) do have[a] = true end
    end
    local added = 0
    local p = io.popen('dir /b "' .. SCRIPTS:gsub("/", "\\") .. '\\prefabs\\*.lua" 2>nul')
    local files = {}
    for file in p:lines() do files[#files + 1] = file end
    p:close()
    table.sort(files)
    local sg_states = {}
    local sg_direct = {}   -- (stategraph -> its attack states the game also goes into from elsewhere)
    for _, file in ipairs(files) do
        local fh = io.open(SCRIPTS .. "/prefabs/" .. file, "rb")
        local text = fh and fh:read("*a") or ""
        -- (its code only, not what's commented out - Uncompromising Mode's "--return Prefab( "swilson" ..." in a file of other
        -- stategraphs: the real swilson, made in another file, taken for that one's and left out, 54 of its blows undrawn on
        -- the bench, 2026-10-21. SIM_OLD_COMMENTS=1: as before)
        if os.getenv("SIM_OLD_COMMENTS") == nil then text = text:gsub("%-%-%[(=*)%[.-%]%1%]", ""):gsub("%-%-[^\n]*", "") end
        if fh then fh:close() end
        -- (its stategraphs, in order - a file making two (the Great Depths Worm's head and tail): the
        -- first with attacks)
        local sgs, order = {}, {}
        for sg in text:gmatch('SetStateGraph%(%s*"([%w_]+)"') do if not sgs[sg] then sgs[sg] = true order[#order + 1] = sg end end
        local combat = text:find('AddComponent%("combat"%)') ~= nil
        for _, only_sg in ipairs(combat and order or {}) do
            if sg_states[only_sg] == nil then
                -- (its attacks: where its "doattack" goes, the common "attack" state, states tagged
                -- "attack", states that harm or put a status on whoever's there - each gone into from
                -- outside: none of the others goes on into it)
                local sh = io.open(SCRIPTS .. "/stategraphs/" .. only_sg .. ".lua", "rb")
                local st = sh and sh:read("*a") or ""
                if sh then sh:close() end
                local HARM = { "DoAttack", "DoAreaAttack", "GetAttacked", '"knockback"', "AddColdness", ":Ignite",
                    "AddSleepiness", "AddGrogginess", '"yawn"', "AddDebuff", "DoAOEAttack", "DoArcAttack" }
                -- (and a ground pound (groundpounder): Tropical Experience's giant grub coming up, the Ancient Hulk
                -- landing - busy states, no "attack" tag: 150 and 28 of their blows undrawn on the bench, 2026-10-20.
                -- SIM_OLD_HARM2=1: as before, this and the prefab's own below)
                local old_harm2 = os.getenv("SIM_OLD_HARM2") ~= nil
                if not old_harm2 then HARM[#HARM + 1] = ":GroundPound(" end
                local list, seen, into, bodies = {}, {}, {}, {}
                local function Add(name) if name ~= nil and not seen[name] then seen[name] = true list[#list + 1] = name end end
                -- (and its own helpers that do so - the War Machine's stomps strike through DoKickAOE,
                -- named in its timeline, not called there: each a word that harms, followed on)
                HARM = { unpack(HARM) }
                -- (and the prefab's own, handed to it and called from its stategraph - inst.DoDamage = DoDamage, the
                -- Ancient Hulk's teleport, spin and barrier: "inst.DoDamage(inst, 4)")
                -- (its own helpers in turn: DoDamage harming through applydamagetoent)
                if not old_harm2 then
                    local pf, harms = {}, {}
                    for hname, hbody in ("\n" .. text):gmatch("\nlocal function ([%w_]+)%s*%((.-)\nend") do pf[hname] = hbody end
                    local words = { unpack(HARM) }
                    for _ = 1, 4 do
                        for hname, hbody in pairs(pf) do
                            if not harms[hname] then
                                for _, h in ipairs(words) do
                                    if hbody:find(h, 1, true) then harms[hname] = true words[#words + 1] = hname .. "(" break end
                                end
                            end
                        end
                    end
                    for hname in pairs(harms) do
                        if text:find("inst%." .. hname .. "%s*=%s*" .. hname .. "%f[^%w_]") then
                            HARM[#HARM + 1] = "." .. hname .. "("
                            HARM[#HARM + 1] = ":" .. hname .. "("
                        end
                    end
                end
                local helpers = {}
                for hname, hbody in ("\n" .. st):gmatch("\nlocal function ([%w_]+)%s*%((.-)\nend") do helpers[hname] = hbody end
                for _ = 1, 3 do
                    for hname, hbody in pairs(helpers) do
                        local known = false
                        for _, h in ipairs(HARM) do if h == hname then known = true end end
                        if not known then
                            for _, h in ipairs(HARM) do
                                if hbody:find(h, 1, true) then table.insert(HARM, hname) break end
                            end
                        end
                    end
                end
                local pos = 1
                while true do
                    local s, e, name = st:find('State%s*%{%s*name%s*=%s*"([%w_]+)"', pos)
                    if s == nil then break end
                    local nxt = st:find('State%s*%{%s*name%s*=', e + 1) or #st
                    local body = st:sub(e + 1, nxt - 1)
                    bodies[name] = body
                    local tags = body:match('tags%s*=%s*(%b{})') or ""
                    local harms = false
                    for _, h in ipairs(HARM) do if body:find(h, 1, true) then harms = true break end end
                    if tags:find('"attack"', 1, true) or harms then Add(name) end
                    pos = nxt
                end
                -- (its "doattack": where it goes)
                local da = st:match('EventHandler%(%s*"doattack"(.-)EventHandler%(') or st:match('EventHandler%(%s*"doattack"(.-)}%s*\n')
                if da ~= nil then for t in da:gmatch('GoToState%(%s*"([%w_]+)"') do if bodies[t] ~= nil then Add(t) end end end
                -- (or named first and gone to by that name - local nstate = "attack" ... GoToState(nstate): Tropical
                -- Experience's wild boars, their plain bite also the end of their charge's - only that one was run,
                -- 477 bites undrawn on the bench, 2026-10-20: each where its attacks begin, a move of its own.
                -- SIM_OLD_DOATTACK=1: as before)
                local da_named = {}
                if da ~= nil and os.getenv("SIM_OLD_DOATTACK") == nil and da:find("GoToState%(%s*[%a_]") then
                    for t in da:gmatch('=%s*"([%w_]+)"') do
                        if bodies[t] ~= nil then Add(t) da_named[t] = true end
                    end
                end
                -- (and which of its weapons it goes there with: "if weapon:HasTag(x) then <one> else <other>" -
                -- the Spat's phlegm or its bash; the move run with that one in its hands)
                if da ~= nil then
                    local wm = {}
                    for tag, yes, no in da:gmatch('HasTag%(%s*"([%w_]+)"%s*%)%s*then(.-)else(.-)end') do
                        for t in yes:gmatch('GoToState%(%s*"([%w_]+)"') do wm[t] = wm[t] or { tag = tag, has = true } end
                        for t in no:gmatch('GoToState%(%s*"([%w_]+)"') do wm[t] = wm[t] or { tag = tag, has = false } end
                    end
                    if next(wm) ~= nil then SIM_SG_WEAPON[only_sg] = wm end
                end
                if (st:find("CommonHandlers.OnAttack(", 1, true) or st:find("CommonStates.AddCombatStates(", 1, true)) and bodies.attack == nil then
                    -- (the common "attack" state, made by the game's commonstates)
                    Add("attack")
                end
                for _, name in ipairs(list) do
                    for call in (bodies[name] or ""):gmatch('GoToState(%b())') do
                        for t in call:gmatch('"([%w_]+)"') do if t ~= name then into[t] = true end end
                    end
                end
                -- (and one the game also goes into from elsewhere - an event handler, its walk: begun
                -- there as a move of its own, not only as the end of another. The worm bites straight
                -- from "doattack" unless it's a lure (SGworm:5, a call no "GoToState("name")" matched);
                -- the Knook hops at you from its walk. SIM_OLD_ENTRY=1: as before; VERIFY_PLAN 6.0a)
                -- (only from where an attack really begins: its "doattack" handler, every name in the call -
                -- a ternary too - or a state it walks or runs in; not from anywhere at all - idle, taunt,
                -- its death were taken so, and the Celestial Champion's roll, part of roll_start)
                local direct = {}
                if not os.getenv("SIM_OLD_ENTRY") then
                    local src = {}
                    local dah = st:match('EventHandler%(%s*"doattack"(.-)EventHandler%(') or st:match('EventHandler%(%s*"doattack"(.-)}%s*\n')
                    if dah ~= nil then src[#src + 1] = dah end
                    for _, fname in ipairs({ dah ~= nil and dah:match("^%s*,%s*([%w_]+)%s*%)") or nil }) do
                        -- (a handler named, not written there: "doattack", doattackfn - its body)
                        local fb = ("\n" .. st):match("\nlocal function " .. fname .. "%s*%((.-)\nend")
                        if fb ~= nil then src[#src + 1] = fb end
                    end
                    for name, body in pairs(bodies) do
                        local tags = body:match('tags%s*=%s*(%b{})') or ""
                        if not seen[name] and (tags:find('"moving"', 1, true) or tags:find('"running"', 1, true)) then src[#src + 1] = body end
                    end
                    -- (or one that goes on into itself - a tentacle lashing again and again while you stand
                    -- there (SGtentacle:163): each go begun anew, not only the first, drawn after its wind-up)
                    -- (standing where it is: not a roll going on in legs - the Celestial Champion's, its legs
                    -- run as one move already)
                    for _, name in ipairs(list) do
                        local body = bodies[name] or ""
                        local tags = body:match('tags%s*=%s*(%b{})') or ""
                        local moves_on = tags:find('"moving"', 1, true) or body:find("SetMotorVel", 1, true) or body:find("WalkForward", 1, true) or body:find("RunForward", 1, true)
                        if not moves_on then
                            for call in body:gmatch('GoToState(%b())') do
                                if call:find('"' .. name .. '"', 1, true) then src[#src + 1] = 'GoToState("' .. name .. '")' break end
                            end
                        end
                    end
                    -- (and an attack by its own tags - not one taken in only for harming: an idle, a taunt)
                    for _, text in ipairs(src) do
                        for call in text:gmatch('GoToState(%b())') do
                            for t in call:gmatch('"([%w_]+)"') do
                                local tt = bodies[t] ~= nil and (bodies[t]:match('tags%s*=%s*(%b{})') or "") or ""
                                if seen[t] and tt:find('"attack"', 1, true) then direct[t] = true end
                            end
                        end
                    end
                end
                sg_direct[only_sg] = direct
                local entry = {}
                -- (direct ones only for a boss listed by hand, below - one found on its own keeps its moves
                -- as one: the Boulder Crab's uppercut split from its swipe drew 40 strikes short, the
                -- Knook's hop gained nothing; VERIFY_PLAN 6.0a)
                for _, name in ipairs(list) do if not into[name] or da_named[name] then entry[#entry + 1] = name end end
                -- (one gone into only from a single busy state that harms nothing itself - its wind-up,
                -- the War Machine's tantrum_pre: from there, so its warning shows from the start)
                for i, name in ipairs(entry) do
                    local from, n = nil, 0
                    for other, body in pairs(bodies) do
                        if other ~= name and body:find('GoToState%(%s*"' .. name .. '"') then from, n = other, n + 1 end
                    end
                    local ftags = from and (bodies[from]:match('tags%s*=%s*(%b{})') or "") or ""
                    if n == 1 and not seen[from] and ftags:find('"busy"', 1, true) and from:find("pre", 1, true) then
                        entry[i] = from
                    end
                end
                sg_states[only_sg] = entry
            end
            -- (one listed by hand: the attacks found that it lacks, added - the War Machine's was
            -- listed with three, its stomping tantrum among those left out; but not one left out
            -- on purpose, b.no_auto)
            for _, b in ipairs(BOSSES) do
                -- (its name after any folders - "common/monsters/ancient_hulk", Tropical Experience: two of them, none of
                -- the attacks found added to the Hulk's listed two, 2026-10-20)
                if b.sg == only_sg and not b.auto and (text:find('Prefab%(%s*"' .. b.prefab .. '"') or text:find('Prefab%(%s*"[%w_/]-/' .. b.prefab .. '"')) then
                    local listed = {}
                    for _, s in ipairs(b.states) do listed[type(s) == "table" and s.name or s] = true end
                    for _, s in ipairs(b.no_auto or {}) do listed[s] = true end
                    local by_hand = {}
                    for s in pairs(listed) do by_hand[s] = true end
                    -- (nor one a listed state goes on into - part of that move: the Celestial
                    -- Champion's roll_start rolls on into roll; added apart, it cut the first short)
                    local sh2 = io.open(SCRIPTS .. "/stategraphs/" .. only_sg .. ".lua", "rb")
                    local st2 = sh2 and sh2:read("*a") or ""
                    if sh2 then sh2:close() end
                    local bodies2, pos2 = {}, 1
                    while true do
                        local s, e, name = st2:find('State%s*%{%s*name%s*=%s*"([%w_]+)"', pos2)
                        if s == nil then break end
                        local nxt = st2:find('State%s*%{%s*name%s*=', e + 1) or #st2
                        bodies2[name] = st2:sub(e + 1, nxt - 1)
                        pos2 = nxt
                    end
                    local todo = {}
                    for name in pairs(listed) do todo[#todo + 1] = name end
                    while #todo > 0 do
                        local name = table.remove(todo)
                        -- (every name in the call - "GoToState(n > 1 and "loop" or "pst")" too)
                        for call in (bodies2[name] or ""):gmatch('GoToState(%b())') do
                            for t in call:gmatch('"([%w_]+)"') do
                                if bodies2[t] ~= nil and not listed[t] and t ~= "idle" and not t:find("^hit") and not t:find("^death") then
                                    listed[t] = true
                                    todo[#todo + 1] = t
                                end
                            end
                        end
                    end
                    -- (nor one that goes on into a listed one - its wind-up, part of that move: Armored
                    -- Bearger's butt_pre, added apart, drew the butt slam twice over)
                    local into_listed = {}
                    for name, body in pairs(bodies2) do
                        for call in body:gmatch('GoToState(%b())') do
                            for t in call:gmatch('"([%w_]+)"') do
                                for _, s in ipairs(b.states) do
                                    if t == (type(s) == "table" and s.name or s) and t ~= name then into_listed[name] = true end
                                end
                            end
                        end
                    end
                    -- (those found, and those begun directly though another attack goes into them too)
                    local cands, cseen = {}, {}
                    for _, s in ipairs(sg_states[only_sg]) do cands[#cands + 1] = s cseen[s] = true end
                    local extra = {}
                    for s in pairs(sg_direct[only_sg] or {}) do if not cseen[s] then extra[#extra + 1] = s end end
                    table.sort(extra)
                    for _, s in ipairs(extra) do cands[#cands + 1] = s end
                    for _, s in ipairs(cands) do
                        -- (gone on into from a listed one, but also begun on its own - sg_direct: added
                        -- too, unless listed or left out by hand)
                        if (not listed[s] and not into_listed[s]) or ((sg_direct[only_sg] or {})[s] and not by_hand[s] and not into_listed[s]) then
                            table.insert(b.states, s)
                            listed[s] = true
                            if os.getenv("AUTOLIST") then io.stderr:write("MERGED " .. b.prefab .. " " .. s .. "\n") end
                        end
                    end
                end
            end
            if #sg_states[only_sg] > 0 then
                local text2 = "\n" .. text
                local names = {}
                for name in text2:gmatch('[^%w_]Prefab%(%s*"[%w_/]-%f[%w_]([%w_]+)"') do names[#names + 1] = name end
                -- (and those a maker function makes, its name handed in - Prefab(name, fn): Tropical Experience's Rhinocebros,
                -- MakeRhinoDrill("rhinodrill") - none of them found, all their blows undrawn, the player 2026-10-21. Only one
                -- that makes a combat in this stategraph is kept (left out after, AUTO LEFT OUT). SIM_OLD_MAKERS=1: as before)
                -- (only from a file of monsters - tagged "monster" or "hostile": not Maxwell's shadow minions (MakeMinion), nor
                -- the merm fisher's fishing (MakeMerm) - taken in so, their fishing and their blows on your foes drawn)
                if os.getenv("SIM_OLD_MAKERS") == nil and text2:find("[^%w_]Prefab%(%s*[%a_]")
                    and (text2:find('AddTag%(%s*"monster"%s*%)') or text2:find('AddTag%(%s*"hostile"%s*%)')) then
                    for name in text2:gmatch('[^%w_]Make[%w_]*%(%s*"([%w_]+)"') do names[#names + 1] = name end
                end
                for _, name in ipairs(names) do
                    if not have[name] and not AutoSkip(name) then
                        have[name] = true
                        BOSSES[#BOSSES + 1] = { prefab = name, sg = only_sg, states = sg_states[only_sg], auto = true }
                        added = added + 1
                    end
                end
                break
            end
        end
    end
    return added
end
local auto_off = false
for i = 3, #arg do if arg[i] == "-noauto" then auto_off = true end end
-- (what it found, kept to hand on to -jobs' parts (scan_auto): states put into listed bosses, and
-- the bosses added - SIM_SCAN_CACHE: a part takes those instead of looking again)
do
    local cached = nil
    if os.getenv("SIM_SCAN_CACHE") ~= nil then
        local ok, got = pcall(dofile, os.getenv("SIM_SCAN_CACHE"))
        if ok and type(got) == "table" and got.auto ~= nil then cached = got.auto end
    end
    if cached ~= nil then
        for _, b in ipairs(BOSSES) do
            -- (not one left out on purpose, b.no_auto - as the scan itself does: the cache put the Hooded Widow's fall
            -- back every build, its no_auto never seen, 2026-10-19)
            local skip = {}
            for _, s in ipairs(b.no_auto or {}) do skip[s] = true end
            for _, s in ipairs(cached.merged[b.prefab] or {}) do if not skip[s] then table.insert(b.states, s) end end
        end
        -- (those sharing one list of states share it here too - as the scan made them)
        for _, a in ipairs(cached.added) do
            BOSSES[#BOSSES + 1] = { prefab = a.prefab, sg = a.sg, states = cached.lists[a.list], auto = true }
        end
        AUTO_ADDED = #cached.added
    elseif not auto_off then
        local had_states, had_n = {}, #BOSSES
        for _, b in ipairs(BOSSES) do had_states[b] = #b.states end
        AUTO_ADDED = AutoBosses()
        scan_auto = { merged = {}, added = {}, lists = {} }
        local list_id = {}
        for i, b in ipairs(BOSSES) do
            if i <= had_n then
                for j = had_states[b] + 1, #b.states do
                    scan_auto.merged[b.prefab] = scan_auto.merged[b.prefab] or {}
                    table.insert(scan_auto.merged[b.prefab], b.states[j])
                end
            else
                if list_id[b.states] == nil then
                    scan_auto.lists[#scan_auto.lists + 1] = b.states
                    list_id[b.states] = #scan_auto.lists
                end
                table.insert(scan_auto.added, { prefab = b.prefab, sg = b.sg, list = list_id[b.states] })
            end
        end
    end
end
-- (and the states the coverage run found striking with no move to show it - tools/verify.ps1 runs
-- that first: coverage_add.lua beside the game's scripts' copy)
do
    local ok, add = pcall(dofile, (SCRIPTS:gsub("[/\\][^/\\]+[/\\]?$", "")) .. "/coverage_add.lua")
    if ok and type(add) == "table" and os.getenv("COVERAGE") == nil then
        for _, b in ipairs(BOSSES) do
            local have = {}
            for _, s in ipairs(b.states) do have[type(s) == "table" and s.name or s] = true end
            -- (not one left out on purpose (b.no_auto) - the Rook's run, its crash drawn on its own)
            for _, s in ipairs(b.no_auto or {}) do have[s] = true end
            for _, s in ipairs(add[b.prefab] or {}) do
                local name = type(s) == "table" and s.name or s
                local key = name .. "|" .. tostring(type(s) == "table" and s.mem and next(s.mem)) .. "|" .. tostring(type(s) == "table" and s.fields and next(s.fields))
                -- (one plain, as listed already: not again; one with a branch flag: its own)
                if not have[key] and not (have[name] and type(s) == "table" and s.mem == nil and s.fields == nil) then
                    table.insert(b.states, s)
                    have[key] = true
                end
            end
        end
    end
end
-- (AUTOLIST=1: what was found, and stop)
if os.getenv("AUTOLIST") then
    for _, b in ipairs(BOSSES) do
        local names = {}
        for _, s in ipairs(b.states) do names[#names + 1] = type(s) == "table" and tostring(s.name) or s end
        print(b.auto and "AUTO" or "LISTED", b.prefab, b.sg, table.concat(names, ","))
    end
    os.exit(0)
end
end
-- (bosses whose hazards are their own, not added to another's of the same prefab)
OWN_HAZARDS = {}
DBG = os.getenv("SIMDBG") ~= nil
for _, b in ipairs(BOSSES) do if b.own_hazards then OWN_HAZARDS[b.prefab] = true end end
-- (every half unit close in: where a leap lands moves on quickly with how far you are)
local DISTANCES = {}
local STEP_DIST = .25
-- (run every 1 first; then finer, down to STEP_DIST - every cell's width - only between two
-- that look different: a laser lands where its target stood, so a step between distances is that
-- much off at its edge)
for d = 1, 16 do table.insert(DISTANCES, d) end
local RUNS = 4             -- runs per distance (random attacks)
local STEP = .25           -- dummies (and cells) every this much
-- (a chase's strike round itself: all of it this close in - true_range/predict AROUND_TURN_FROM; a global, the chunk's locals all used)
AROUND_NEAR = 2
-- (a cell counts as struck if any of it is - not only its middle: a dummy a little wider than a
-- player, found a little further off. Monsters strike at the very edge of their reach, and that's
-- where you stand - a middle just out, its inner half in, was drawn out: you struck outside it)
-- (a quarter of a cell: half (as it was) drew the edge some .5 past the real reach, measured against the game's own logs - tools/verify.ps1)
local PAD = tonumber(os.getenv("SIM_PAD") or "") or STEP / 4
local AHEAD = { -20, 34 }  -- the map: this far behind/ahead of the boss...
local SIDE = 20            -- ...and to each side
-- (the cells as the files keep them: from these, whatever the map run - the mod's _grid)
sim_pack = { ahead = AHEAD, side = SIDE }
-- (wider, for runs that need it - tools/build_tables.lua -follow: junk thrown 20 off to the side)
if rawget(_G, "sim_ahead") ~= nil then AHEAD = sim_ahead end
if rawget(_G, "sim_side") ~= nil then SIDE = sim_side end
local SIDE_DIST = 6        -- one that goes the way it faces: its target this far off to its side, once
local MAX_FRAMES = 300     -- a move (with what follows it) is over by then
physics_lag = tonumber(os.getenv("SIM_LAG") or "") or .15
THING_RUNS = tonumber(os.getenv("SIM_THING_RUNS") or "") or 16  -- (runs a lasting thing's shape is measured in, each its own spots off the grid, before it's let be)
local AFTER = 600          -- ...and what it set off goes on at most this much longer
local LEG_MIN = 4          -- a leg carries it at least this far (a roll; a combo's lunge doesn't)

--------------------------------------------------------------------------------
-- the fake world

local NOOP = function() end
-- (a damage asked of a stand-in: none, not nothing - a merm working out its damage less its
-- planar damage stopped being made)
local function ZERO() return 0 end
local PERMISSIVE = { __index = function(_, k)
    if type(k) == "string" and k:match("^%u") then return k:match("^Get%a*Damage$") and ZERO or NOOP end
end }
local STUB = setmetatable({}, PERMISSIVE)

FRAMES, DEGREES, RADIANS, PI, TWOPI = 1 / 30, math.pi / 180, 180 / math.pi, math.pi, 2 * math.pi
-- (the time a tick takes, as the game hands it to onupdate and its update loops: the engine's own,
-- a 32-bit float - a hair over 1/30. Exactly 1/30 here, a count-down of 3 frames by it (the Eye
-- of Terror's charge, COLLIDE_TIME 3*FRAMES) still had a hair left after 3 ticks: struck every
-- 4th frame, the game every 3rd (its traced hits at frames 1, 4, 7 ... 28 of its charge))
TICK = 0.033333335071802139
rawset(_G, "eprint", function() end)
-- (the game's Make...Character helpers that hand back what they added - the prefab sets it up
-- further: Dragonfly's freezing)
for _, size in ipairs({ "Tiny", "Small", "Medium", "Large", "Huge" }) do
    for _, what in ipairs({ "FreezableCharacter", "BurnableCharacter", "Propagator" }) do
        local name = what:match("^%u%l+"):lower()
        rawset(_G, "Make" .. size .. what, function(inst)
            inst:AddComponent(name)
            return inst.components[name]
        end)
    end
end
unpack = unpack or table.unpack
require("class")
require("vector3")
require("mathutil")
require("util")
-- (the game's helpers for finding players round a spot - FindPlayersInRangeSq, FindEntity: over AllPlayers, set as the
-- run starts; missing, Tropical Experience's boar's flame bursts at each player stopped. SIM_OLD_SIMUTIL=1: as before)
if os.getenv("SIM_OLD_SIMUTIL") == nil then require("simutil") end
-- (and math2d, as main.lua has it since the 2026-10-23 update - util/hitbox.lua's, the Rock Master's snip; an older
-- scripts.zip has none)
pcall(require, "math2d")
TheNet = STUB
IsConsole = function() return false end
APP_VERSION = "0"
require("constants")
require("tuning")
Tune()
anglediff = anglediff or function(a, b) return ((a - b + 180) % 360) - 180 end
-- (a network value: starts as the game's does - a number at 0, a flag off, a text empty)
local function NetVarOf(start) return function() local v = { val = start } function v:set(x) self.val = x end function v:value() return self.val end
    v.set_local, v.push = v.set, NOOP return v end end
for _, n in ipairs({ "net_byte", "net_tinybyte", "net_smallbyte", "net_shortint", "net_ushortint", "net_int",
    "net_uint", "net_float", "net_hash" }) do
    _G[n] = NetVarOf(0)
end
net_bool, net_string = NetVarOf(false), NetVarOf("")
for _, n in ipairs({ "net_entity", "net_event", "net_bytearray", "net_smallbytearray" }) do _G[n] = NetVarOf(nil) end
-- (the weather where it stands: mild)
GetLocalTemperature, GetTemperatureAtXZ = function() return 20 end, function() return 20 end
ShakeAllCameras, Launch, GetEntityTemperature, DoDeltaTemperatureToEntity = NOOP, NOOP, NOOP, NOOP
-- (the Possessed Varg's breath: cools whoever it reaches - nothing here)
SetEntityTemperature = NOOP
-- (particles' looks - a Grazer's sleep cloud sets its up as it's made: nothing here)
EnvelopeManager, EmitterManager = setmetatable({}, PERMISSIVE), setmetatable({}, PERMISSIVE)
AllPlayers = {}
MakeInventoryPhysics, RemovePhysicsColliders = NOOP, NOOP
-- (bodies: how big it is - it can't walk through whoever it's after)
local function Body3(inst, mass, rad) if type(inst) == "table" then inst.radius = rad return inst.Physics end end
MakeCharacterPhysics, MakeGiantCharacterPhysics, MakeFlyingCharacterPhysics = Body3, Body3, Body3
-- (a small flier's body bumps into nothing but the world: it goes over whoever it's after - a
-- giant one, Dragonfly or the Bee Queen, still bumps into players)
local function FlyBody(inst, mass, rad) if type(inst) == "table" then inst.radius = rad rawset(inst, "flier", true) end end
MakeFlyingCharacterPhysics = FlyBody
MakeTinyFlyingCharacterPhysics, MakeFlyingGiantCharacterPhysics, MakeSmallFlyingCharacterPhysics = FlyBody, Body3, FlyBody
MakeHauntableGoToState = NOOP
-- (ghosts go through you - bats, Nightmare creatures' kin; things standing in the ground - a
-- tentacle, the Antlion: a body all the same, its size)
MakeGhostPhysics, MakeTinyGhostPhysics = FlyBody, FlyBody
do
local function Obstacle(inst, rad) if type(inst) == "table" then inst.radius = rad rawset(inst, "rooted", true) return inst.Physics end end
MakeObstaclePhysics, MakeWaterObstaclePhysics, MakeSmallObstaclePhysics = Obstacle, Obstacle, Obstacle
MakeHeavyObstaclePhysics, MakeSmallHeavyObstaclePhysics = Obstacle, Obstacle
end
-- (going through players / over rocks for a while - the game's standardcomponents helpers: as
-- they set its body's mask)
function ToggleOffCharacterCollisions(inst) if type(inst) == "table" then inst.nocollide = true end end
function ToggleOnCharacterCollisions(inst) if type(inst) == "table" then inst.nocollide = false end end
function ToggleOffAllObjectCollisions(inst) if type(inst) == "table" then inst.nocollide, inst.through = true, true end end
function ToggleOnAllObjectCollisionsAt(inst, x, z)
    if type(inst) == "table" then
        inst.nocollide, inst.through = false, false
        if x ~= nil and z ~= nil then inst.x, inst.z = x, z end
    end
end
MakeInventoryFloatable, MakeHauntable = NOOP, NOOP
ACTIONS = setmetatable({}, { __index = function(_, k) return k end })
CAMERASHAKE = setmetatable({}, { __index = function(_, k) return k end })
BrainCommon = STUB
Asset = function() return {} end
-- (other helpers prefabs call while being made - MakeXPhysics, SetSharedLootTable...: nothing)
setmetatable(_G, { __index = function(_, k)
    if type(k) == "string" and (k:match("^Make%u") or k:match("^Set%u") or k:match("^Add%u") or k:match("^Remove%u")) then
        return NOOP
    end
    -- (other helpers - ToggleOnCharacterCollisions...: nothing; not the world's objects, TheX)
    if type(k) == "string" and k:match("^%u%l") and not k:match("^The%u") then
        -- (a mod's world: also indexed, not only called - ModManager.mods, AllRecipes[...] -
        -- tools/mod_env.lua's stand-in, nothing back from a call all the same)
        local me = rawget(_G, "MODENV")
        if me ~= nil then return me.STUB end
        return NOOP
    end
    -- (constants tables the sim doesn't have - WORLDSTATETAGS...: each name stands for itself)
    if type(k) == "string" and k:match("^[%u_]+$") then
        local t = setmetatable({}, { __index = function(_, name)
            if type(name) == "string" and name:match("^%u%l") then return NOOP end -- (its functions)
            return name
        end })
        rawset(_G, k, t)
        return t
    end
end })

-- brains and such: never needed here
local real_require = require
require = function(name)
    if type(name) == "string" and (name:match("^brains/") or name:match("^widgets/") or name:match("^screens/")) then
        return setmetatable({}, PERMISSIVE)
    end
    return real_require(name)
end

local now, frame_n = 0, 0
GetTime = function() return now end
-- (the game's tick - a frame each: the Possessed Varg's breath strikes a tick at most once each)
GetTick = function() return math.floor(now / FRAMES + .5) end
GetStaticTime, GetTimeReal = GetTime, GetTime

local ents, tasks, hits = {}, {}, {}
local others, dummy_grid = {}, {}   -- (everything but the dummies; the dummies, by area)
local sim_boss, sim_target, last_query = nil, nil, nil
local target_found_at = nil   -- (the frame a search last turned up its target)
fly_queries = {}   -- searches made by things in flight: { by, frame, x, z, r }
thing_queries = {}  -- things it set off looking round themselves: thing -> { first, last } frame
thing_found = {}    -- ...and the dummies each found: thing -> dummy -> first frame
-- (things that strike each one once among them all - the Scrappy Werepig's junk, the pieces of one
-- throw sharing whom they've struck: a piece finding one another struck already passes it by.
-- prefab -> { passed = n, again = n } over every run; shared when passed by, never struck again)
shared_seen = {}
-- (set here, not left unset: an unset all-capitals name reads as a table in this world (the
-- constants catch-all below) - "not NO_DUMMIES" would be false)
NO_DUMMIES, SWEEP_MOVE = false, false
function SameList(a, b)
    for k, v in pairs(a) do
        if type(v) == "table" and rawget(b, k) == v and getmetatable(v) == nil and rawget(v, "prefab") == nil then
            return true
        end
    end
    return false
end
function Shared()
    for by, found in pairs(thing_found) do
        local prefab = by.prefab
        -- (how far round itself it harmed: one it passed by counts only well within that - it
        -- searches wider than it strikes)
        local reach = nil
        for d2, p in pairs(hit_proxies[by] or {}) do
            local h = hits[p]
            if h ~= nil and (h.kinds == nil or h.kinds.harm) and h.bx ~= nil then
                reach = math.max(reach or 0, math.sqrt((d2.x - h.bx) ^ 2 + (d2.z - h.bz) ^ 2))
            end
        end
        for d, f in pairs(reach ~= nil and found or {}) do
          if (d.x - by.x) ^ 2 + (d.z - by.z) ^ 2 <= (reach * .9) ^ 2 then
            -- (struck by it, harmed - not only knocked back: the junk's pile shoving all the throw struck)
            local hm = hit_proxies[by] ~= nil and hit_proxies[by][d] ~= nil and hits[hit_proxies[by][d]] or nil
            local mine = hm ~= nil and (hm.kinds == nil or hm.kinds.harm == true)
            -- (struck before by another of the same kind holding the very same table - a list,
            -- not a thing: the pieces of one throw, not another throw's)
            local other = false
            for by2, per in pairs(hit_proxies) do
                if by2 ~= by and by2.prefab == prefab and per[d] ~= nil and hits[per[d]] ~= nil and hits[per[d]].frame <= f
                    and SameList(by, by2) then
                    other = true
                    break
                end
            end
            -- (and of those none had struck yet, how many it struck - one that finds whom it doesn't
            -- strike anyway is no evidence)
            local s = shared_seen[prefab] or { passed = 0, again = 0, fresh = 0, fresh_hit = 0 }
            shared_seen[prefab] = s
            if other then
                if mine then s.again = s.again + 1 else s.passed = s.passed + 1 end
            else
                s.fresh = s.fresh + 1
                if mine then s.fresh_hit = s.fresh_hit + 1 end
            end
          end
        end
    end
end
boss_ground_went = 0  -- ...and on the ground at all (not flying)
boss_move_log = {}  -- this run's: { frame, how far, through, on the ground }
boss_solid, boss_through = 0, 0  -- how far the boss went, all runs of a move: bumping into rocks / over them
boss_queries = {}  -- the boss's own searches: "x,z,r" -> the frame last made
boss_queries_again = {}  -- ...and whether that was the frame after the one before
local acting = nil       -- whose task runs now (something the boss set off, or the boss)
-- (a dummy struck by something the boss set off is kept apart from the same dummy struck by the
-- boss, or by something else - a crystal landing, then the snare it leaves pulsing: a stand-in
-- for it per striker, at the same spot)
hit_proxies = setmetatable({}, { __mode = "k" })
function HitKey(d)
    local by = acting
    if by == nil or by == sim_boss then return d end
    local per = hit_proxies[by]
    if per == nil then per = {} hit_proxies[by] = per end
    local p = per[d]
    if p == nil then p = { x = d.x, z = d.z, dummy = d } per[d] = p end
    return p
end
local target_hits = {}              -- attacks on its target only: { frame, x, z (the boss), range }
local player_hits = {}              -- (-check) frames its target - a player, where it really is - was struck
local own_hits = {}                 -- (...by the boss itself - not something it set off: a trace's strikes)
local function PlayerHit()
    table.insert(player_hits, frame_n)
    if acting == nil or acting == sim_boss then table.insert(own_hits, frame_n) end
end
local boss_timers = {}              -- timers the boss started as it went: name -> seconds (a cooldown)
local target_hit = nil   -- an attack on its target only: how far it reached
FindWalkableOffset = function(pos, angle, radius)
    return Vector3(radius * math.cos(angle), 0, -radius * math.sin(angle))
end
FindValidPositionByFan = FindWalkableOffset

local function Schedule(owner, t, fn, period, ...)
    local task = { at = now + math.max(0, t or 0), fn = fn, args = { owner, ... }, nargs = select("#", ...) + 1, period = period }
    function task:Cancel() self.cancelled = true end
    table.insert(tasks, task)
    return task
end
-- (for a spec's prep: what one's own code set going as it was made, due within so many seconds, done now - as it is by
-- the time it fights in the game: MacTusk's blowdart, put in its hands 1 s after it's made (EquipBlowdart); run at
-- once, it struck you with no dart from 15 off)
rawset(_G, "SIM_RUN_OWN_TASKS", function(ent, within)
    for _, task in ipairs(tasks) do
        if task.args ~= nil and task.args[1] == ent and not task.cancelled and task.period == nil and task.at <= now + within then
            task.cancelled = true
            pcall(task.fn, unpack(task.args, 1, task.nargs))
        end
    end
end)

local Entity = {}
-- (its stategraph as it's made: what the prefab notes in it is kept for the run - a hound's
-- mem.nolunarmutate)
function Entity:SetStateGraph(name)
    rawset(self, "sg_name", name)
    rawset(self, "sg", { mem = {}, statemem = {}, HasStateTag = function() return false end, HasAnyStateTag = function() return false end,
        GoToState = function() end, InNewState = function() return true end })
end
Entity.__index = function(self, k)
    local v = rawget(Entity, k)
    if v ~= nil then return v end
    if type(k) == "string" then
        local b = k:byte(1)
        if b ~= nil and b >= 65 and b <= 90 then
            -- (with a mod's: called, nothing; indexed too - a field of its own holding a task by a name like a method's,
            -- Tropical Experience's fire twister's inst.ItemsMain:Cancel(), its file stopped there, 2026-10-20)
            if rawget(_G, "MODENV") ~= nil then return CALLABLE end
            return NOOP
        end
    end
    return nil
end
-- (called: nothing; indexed: itself again)
CALLABLE = setmetatable({}, { __call = function() return nil end })
getmetatable(CALLABLE).__index = function() return CALLABLE end

local function NewEntity(prefab)
    local e = setmetatable({ prefab = prefab, tags = {}, components = {}, replica = {}, x = 0, z = 0, rot = 0,
        vel = 0, valid = true, anim = nil }, Entity)
    -- (its sounds, before the prefab names them - or when it never does: any one, no sound)
    e.sounds = setmetatable({}, { __index = function() return "" end })
    e.GUID = #ents + 1
    e.born = frame_n
    e.Transform = setmetatable({
        -- (its height too: a missile launched up high comes down on you - at 0 it went off at once)
        GetWorldPosition = function() return e.x, e.y or 0, e.z end,
        SetPosition = function(_, x, y, z) e.x, e.z = x, z rawset(e, "y", tonumber(y) or 0) end,
        GetRotation = function() return e.rot end,
        SetRotation = function(_, r) e.rot = r end,
        -- (how big it's drawn: a boss grown bigger (enraged) shows it - its moves reach further)
        SetScale = function(_, s) e.scale = s end,
        GetScale = function() local s = e.scale or 1 return s, s, s end,
    }, PERMISSIVE)
    e.entity = setmetatable({ IsValid = function() return e.valid end, IsVisible = function() return true end,
        GetParent = NOOP, AddTransform = function() return e.Transform end,
        AddPhysics = function() return e.Physics end, AddAnimState = function() return e.AnimState end }, PERMISSIVE)
    -- (whose child it is, as set - the Umbral Abomination puts its portal back only if it's its child (shrouden.lua
    -- Portal_Recycle), asserting so: every attack of it stopped, 2026-10-23 update. SIM_OLD_PARENT=1: none)
    if os.getenv("SIM_OLD_PARENT") == nil then
        rawset(e.entity, "_owner", e)
        e.entity.SetParent = function(_, pent) rawset(e, "parent_ent", pent) end
        e.entity.GetParent = function() local p = rawget(e, "parent_ent") return p ~= nil and rawget(p, "_owner") or nil end
    end
    -- (animations as long as they really are - anim_lengths.lua - one after another, looping or not)
    e.anim_queue = {}
    e.AnimState = setmetatable({
        PlayAnimation = function(_, a, loop)
            e.anim, e.anim_t, e.anim_loop, e.anim_done, e.anim_queue = a, now, loop == true, false, {}
            if e.on_anim then e.on_anim(a, loop == true) end
        end,
        -- (queued after the one playing: also the move's)
        PushAnimation = function(_, a, loop)
            table.insert(e.anim_queue, { a, loop == true })
            if e.on_anim then e.on_anim(a, loop == true) end
        end,
        GetCurrentAnimationLength = function() return AnimLen(e, e.anim) end,
        SetBank = function(_, b) e.bank = b end,
        SetBankAndPlayAnimation = function(_, b, a, loop) e.bank = b e.AnimState.PlayAnimation(nil, a, loop) end,
        GetCurrentAnimationTime = function() return now - (e.anim_t or now) end,
        IsCurrentAnimation = function(_, a) return e.anim == a end,
        AnimDone = function() return e.anim_done == true end,
        SetFrame = function(_, f) e.anim_t = now - f * FRAMES end,
        GetCurrentAnimationNumFrames = function() return math.max(1, math.floor(AnimLen(e, e.anim) / FRAMES + .5)) end,
        GetCurrentAnimationFrame = function() return math.floor((now - (e.anim_t or now)) / FRAMES) end,
        -- (played slower, or held - Uncompromising Mode's shadow Wilson crouched still (0) from frame 5 to 28 before it leaps:
        -- its animation over before it struck, here; the run moves its start on - SIM_OLD_ANIMMULT=1: as before)
        SetDeltaTimeMultiplier = function(_, m)
            if os.getenv("SIM_OLD_ANIMMULT") == nil then
                rawset(e, "anim_mult", tonumber(m) or 1)
                -- (the boss's own held or slowed in this move: said in its data (held) - true_range/predict then doesn't take
                -- it for another move played slow)
                if e == sim_boss and (tonumber(m) or 1) < 1 then sim_anim_held = true end
            end
        end,
    }, PERMISSIVE)
    -- (its own speed forward: motor velocity, as the game moves things)
    e.Physics = setmetatable({
        SetMotorVelOverride = function(_, vx, vy) e.vel = vx or 0 rawset(e, "vy", tonumber(vy) or 0) end,
        SetMotorVel = function(_, vx, vy) e.vel = vx or 0 rawset(e, "vy", tonumber(vy) or 0) end,
        ClearMotorVelOverride = function() e.vel = 0 rawset(e, "vy", 0) end,
        Stop = function() e.vel = 0 rawset(e, "vy", 0) end,
        Teleport = function(_, x, y, z) e.x, e.z = x, z rawset(e, "y", tonumber(y) or 0) end,
        SetCapsule = function(_, r) e.radius = r end,
        -- (a body made by hand, not through the Make...Physics helpers: a bird, a tentacle)
        SetSphere = function(_, r) e.radius = e.radius or r end,
        SetCylinder = function(_, r) e.radius = e.radius or r rawset(e, "rooted", true) end,
        GetMotorVel = function() return e.vel or 0, 0, 0 end,
        -- (how fast it goes - the Umbral Abomination's gel trail, 2026-10-23 update)
        GetMotorSpeed = function() return math.abs(e.vel or 0) end,
        -- (its body's size - the Ancient Guardian making room for whoever stands right by it)
        GetRadius = function() return e.radius or .5 end,
        -- (what it bumps into: one leaping over whoever it's after sets its mask to the world alone -
        -- the Ancient Guardian's leap lands on you, not short of you)
        SetCollisionMask = function(_, ...)
            local m = 0
            for _, v in ipairs({ ... }) do if type(v) == "number" then m = bit.bor(m, v) end end
            e.nocollide = bit.band(m, COLLISION.CHARACTERS) == 0
            e.through = bit.band(m, COLLISION.OBSTACLES) == 0
        end,
        ClearCollisionMask = function() e.nocollide, e.through = true, true end,
        CollidesWith = function(_, m)
            if type(m) == "number" and bit.band(m, COLLISION.CHARACTERS) ~= 0 then e.nocollide = false end
            if type(m) == "number" and bit.band(m, COLLISION.OBSTACLES) ~= 0 then e.through = false end
        end,
        -- (rocks, walls: whether it bumps into them - a leap goes over, a charge is stopped)
        ClearCollidesWith = function(_, m)
            if type(m) == "number" and bit.band(m, COLLISION.CHARACTERS) ~= 0 then e.nocollide = true end
            if type(m) == "number" and bit.band(m, COLLISION.OBSTACLES) ~= 0 then e.through = true end
        end,
        GetCollisionMask = function()
            local m = bit.bor(COLLISION.WORLD or 0, COLLISION.GIANTS or 0, COLLISION.SMALLOBSTACLES or 0)
            if not e.nocollide then m = bit.bor(m, COLLISION.CHARACTERS) end
            if not e.through then m = bit.bor(m, COLLISION.OBSTACLES) end
            return m
        end,
        GetVelocity = function() return e.vel or 0, 0, 0 end,
    }, PERMISSIVE)
    e.SoundEmitter, e.Light, e.DynamicShadow, e.MiniMapEntity, e.Network = STUB, STUB, STUB, STUB, STUB
    table.insert(ents, e)
    table.insert(others, e)
    return e
end
-- What a prefab makes: anything it reaches for and hasn't got - a component its helpers would
-- have added (burnable, freezable), an engine part (Follower) - is there, doing nothing.
CreateEntity = function()
    local e = NewEntity("?")
    setmetatable(e.components, { __index = function(t, k)
        local c = setmetatable({ inst = e }, PERMISSIVE)
        if k == "inventory" then c.equipslots = {} end
        -- (as one added: not frozen at all - a laser asks whatever it struck how cold it is, a scorch mark here; nothing, it
        -- stopped - Tropical Experience's Ancient Robots, 2026-10-20)
        if k == "freezable" then c.coldness = 0 end
        -- (its size as one's made - the Rock Master's swipe sizes its sound by it (SGrocky PlayLobSound, its inventory
        -- here though it has none), nil stopping the swipe at its first frame, 2026-10-23 update)
        if k == "scaler" then c.scale = 1 end
        -- (and as warm as one's made: the game's own start, 35 of at most 90 - the same laser warms what it strikes, asking)
        if k == "temperature" then
            c.current, c.maxtemp, c.mintemp = 35, 90, -20
            c.GetCurrent = function(self) return self.current end
            c.GetMax = function(self) return self.maxtemp end
        end
        rawset(t, k, c)
        return c
    end })
    setmetatable(e.entity, { __index = function(_, k)
        local part = type(k) == "string" and k:match("^Add(%u%w*)$")
        if part ~= nil then
            return function()
                e[part] = rawget(e, part) or setmetatable({}, PERMISSIVE)
                return e[part]
            end
        end
        -- (seen, unless hidden - nothing told, none was: Tropical Experience's Forge boar's ground slam passes over whatever
        -- isn't, struck nothing, 2026-10-20. SIM_OLD_VISIBLE=1: as before)
        if k == "IsVisible" and not os.getenv("SIM_OLD_VISIBLE") then return function() return not rawget(e, "hidden") end end
        if type(k) == "string" and k:match("^%u") then return NOOP end
    end })
    return e
end

function Entity:IsValid() return self.valid end
-- (hidden and shown again, kept - for entity:IsVisible above)
function Entity:Hide() if not os.getenv("SIM_OLD_VISIBLE") then rawset(self, "hidden", true) end end
function Entity:Show() rawset(self, "hidden", nil) end
-- (what the game's classes answer: a thing is no Vector3 - it's an EntityScript (a missile
-- told a thing to chase, not a spot))
function Entity:is_a(c) return c ~= nil and c == EntityScript end
-- (dry)
function Entity:GetWetMultiplier() return 0 end
function Entity:GetIsWet() return false end
function Entity:IsInLimbo() return false end
function Entity:IsAsleep() return false end
function Entity:HasTag(t) return self.tags[t] == true end
local function AnyTag(self, ...) local l = type((...)) == "table" and (...) or { ... } for _, t in ipairs(l) do if self.tags[t] then return true end end return false end
Entity.HasAnyTag, Entity.HasOneOfTags = AnyTag, AnyTag
function Entity:AddTag(t) self.tags[t] = true end
function Entity:RemoveTag(t) self.tags[t] = nil end
function Entity:GetPosition() return Vector3(self.x, 0, self.z) end
function Entity:GetPhysicsRadius(d) return self.radius or d or 0 end
-- (its body's size, set apart from its physics - Armored Bearger, Frostjaw, the Ancient Guardian:
-- left a stub, they had no body here and went through whoever they were after)
function Entity:SetPhysicsRadiusOverride(r) rawset(self, "physicsradiusoverride", r) if r ~= nil then self.radius = r end end
function Entity:GetDistanceSqToPoint(x, y, z) if type(x) == "table" then x, z = x.x, x.z end return (self.x - x) ^ 2 + (self.z - z) ^ 2 end
function Entity:GetDistanceSqToInst(o) return self:GetDistanceSqToPoint(o.x, 0, o.z) end
function Entity:IsNear(o, d) return self:GetDistanceSqToInst(o) < d * d end
function Entity:GetAngleToPoint(x, y, z) if type(x) == "table" then x, z = x.x, x.z end return math.atan2(self.z - z, x - self.x) / DEGREES end
function Entity:ForceFacePoint(x, y, z) self.rot = self:GetAngleToPoint(x, y, z) end
function Entity:GetRotation() return self.rot end
function Entity:DoTaskInTime(t, fn, ...) return Schedule(self, t, fn, nil, ...) end
function Entity:DoPeriodicTask(p, fn, delay, ...) return Schedule(self, delay or p, fn, p, ...) end
function Entity:Remove() self.valid = false end
-- events: things listening for them (a gestalt waiting for its animation to end) - the boss's
-- own stategraph is run by hand, apart
function Entity:ListenForEvent(ev, fn, source)
    source = source or self
    source.listeners = rawget(source, "listeners") or {}
    source.listeners[ev] = source.listeners[ev] or {}
    table.insert(source.listeners[ev], { fn = fn, who = self })
end
function Entity:RemoveEventCallback(ev, fn, source)
    source = source or self
    local list = (rawget(source, "listeners") or {})[ev] or {}
    for i = #list, 1, -1 do if list[i].fn == fn then table.remove(list, i) end end
end
-- (struck again: when last - and when the first run of strikes frame after frame ended, h.run: a
-- spot struck on and on is in danger all the while; one struck once more much later - Frostjaw
-- landing over part of where it came up - only then, in that later part)
-- (DBG_PULSES: "boss thing offs lasting" -> cells, said once as the run ends)
pulse_sum = {}
local function Restruck(h, f, anim, anim_at)
    -- (each time struck anew - not running on from the frame before: when, h.pulses - a sinkhole's
    -- three stages half a second apart, the data had only the first; VERIFY_PLAN 6.12b)
    local prev = h.last ~= nil and h.last[1] or h.frame
    if f - prev > 2 then h.pulses = h.pulses or {} h.pulses[#h.pulses + 1] = f end
    if h.run == nil then h.run, h.run_open = { h.frame }, true end
    if h.run_open and f - h.run[1] <= 2 then
        h.run = { f, anim, anim_at }
    else
        h.run_open = false
    end
    h.last = { f, anim, anim_at }
    -- (and in which of the boss's states each time, first - how its legs end strikes all round
    -- where it stops, a spot its roll struck already too: the Celestial Champion's)
    local entry = sim_boss ~= nil and sim_boss.sg ~= nil and sim_boss.sg.entry or nil
    if entry ~= nil then
        -- (in the order struck - a list, not keyed by state: gone round in a set order)
        h.entries = h.entries or {}
        local seen_entry = false
        for _, en in ipairs(h.entries) do if en[1] == entry then seen_entry = true break end end
        if not seen_entry then h.entries[#h.entries + 1] = { entry, f } end
    end
end
-- (what the move being run does to whoever it reaches: harm, sleep, knockback... - its runs together)
move_effects = {}
pending_kind = nil
function EffectsField()
    local list, other = {}, false
    for k in pairs(move_effects) do list[#list + 1] = k if k ~= "harm" then other = true end end
    if not other then return "" end
    table.sort(list)
    return string.format(", effects = %q", table.concat(list, ","))
end
function Entity:PushEvent(ev, data)
    -- (a status put on a dummy by an event - knocked back, yawned at: as struck, of that kind)
    -- (from the boss's own stategraph, no one else acting: the boss)
    if self.is_dummy and STATUS_EVENTS[ev] ~= nil and (acting ~= nil or sim_boss ~= nil) then
        -- (knocked back by the blow that struck it this very frame: that blow's - only its kind
        -- noted, not struck again; as again, a spin's strikes on and on came out cut short)
        local h = hits[HitKey(self)]
        if h ~= nil and ((h.last and h.last[1]) or h.frame) == frame_n then
            move_effects[STATUS_EVENTS[ev]] = true
            return
        end
        local was = acting
        acting = acting or sim_boss
        self:PushEvent("attacked", { attacker = acting, status = STATUS_EVENTS[ev] })
        acting = was
        return
    end
    if ev == "attacked" and acting ~= nil and (self.is_dummy or self == sim_target) then
        -- (struck for nothing - a gestalt's, only sapping and making groggy: no harm)
        move_effects[data ~= nil and data.status or ((data ~= nil and data.damage == 0) and "nodamage" or "harm")] = true
    end
    -- (and what it did there, by whatever struck: a deer's circle only freezing)
    if ev == "attacked" and acting ~= nil and self.is_dummy then
        local h = hits[HitKey(self)]
        local kind = data ~= nil and data.status or ((data ~= nil and data.damage == 0) and "nodamage" or "harm")
        if h ~= nil then h.kinds = h.kinds or {} h.kinds[kind] = true else pending_kind = kind end
    end
    if ev == "attacked" and self == sim_target and acting ~= nil then PlayerHit() end
    if ev == "attacked" and sim_extra ~= nil and self == sim_extra and acting ~= nil then extra_attacked = true end
    if ev == "attacked" and self.is_dummy and acting ~= nil then
        -- (struck - something's pulse, no combat of its own: noted as its hit)
        local t = HitKey(self)
        if hits[t] ~= nil then
            Restruck(hits[t], frame_n, acting.anim, 0)
        else
            if acting ~= nil then acting_seen[acting] = true end
            hits[t] = { frame = frame_n, by = acting, bx = acting.x, bz = acting.z, brot = acting.rot,
                boss_anim = sim_boss ~= nil and sim_boss.anim or nil, boss_state = sim_boss ~= nil and sim_boss.sg ~= nil and sim_boss.sg.entry ~= nil and sim_boss.sg.entry.name or nil,
                sx = acting.x, sz = acting.z, srot = acting.rot, q = last_query, kinds = { [pending_kind or "harm"] = true },
                -- (a thing's blow the game puts down to the boss - GetAttacked(boss): UM Bearger's
                -- sinkholes, the Shadow Thrall's darts, a Sea Weed's seeds; the game's own trace says
                -- the boss struck. VERIFY_PLAN 6.12b as_boss)
                credit_boss = (data ~= nil and data.attacker ~= nil and data.attacker == sim_boss and acting ~= sim_boss) or nil }
            pending_kind = nil
        end
    end
    -- (to the boss's stategraph too, its state's own handlers, as the game's PushEvent does - the
    -- Shadow Thrall mouth's leap ends on "dupe_animover" from its stand-in; animover is the
    -- frame loop's)
    if self == sim_boss and ev ~= "animover" and ev ~= "animqueueover" then
        local sg = rawget(self, "sg")
        local st = sg ~= nil and rawget(sg, "currentstate") or nil
        if type(st) == "table" and type(st.events) == "table" then
            for _, h in ipairs(st.events) do
                if h.name == ev and type(h.fn) == "function" then
                    -- (its own doing, whoever sent the event - the stand-in's animation over, the
                    -- mouth's landing strike is the mouth's)
                    local was = acting
                    acting = sim_boss
                    local ok, err = pcall(h.fn, self, data)
                    acting = was
                    if not ok then io.stderr:write("state event " .. ev .. ": " .. tostring(err) .. "\n") end
                end
            end
        end
    end
    local list = (rawget(self, "listeners") or {})[ev]
    if list == nil then return end
    for _, l in ipairs({ unpack(list) }) do
        local was = acting
        acting = l.who
        local ok, err = pcall(l.fn, self, data)
        acting = was
        if not ok then io.stderr:write("event " .. ev .. ": " .. tostring(err) .. "\n") end
    end
end
-- components whose own code makes the hits (a ground pound's rings): the game's, for real
-- (aura: a cloud harming what's in it, tick by tick - Toadstool's spore cloud)
-- (linearprojectile: Uncompromising Mode's, laid out as complexprojectile is - the Eye of Terror's mini eyes flung at you; not
-- flown at all without it, its shot run as "nothing", never drawn - 13 of 13 undrawn on the lag bench 2026-10-27)
local REAL_COMPONENTS = { groundpounder = true, complexprojectile = true, aura = true, linearprojectile = not os.getenv("SIM_OLD_LINEAR") }
-- (a thing thrown in an arc - a mushroom bomb, a spat: the game works out its arc; here it flies
-- on along the ground as fast as the arc goes forward, and lands when the arc would come down)
function Entity:StartUpdatingComponent(c)
    if type(c) == "table" and c.velocity ~= nil and c.gravity ~= nil and c.Hit ~= nil then
        local vx, vy, g = c.velocity.x or 0, c.velocity.y or 0, -(c.gravity or -9.81)
        local y0 = c.launchoffset ~= nil and c.launchoffset.y or 0
        local ty = c.targetoffset ~= nil and c.targetoffset.y or 0
        local d = vy * vy + 2 * g * (y0 - ty)
        local t = g > 0 and d >= 0 and (vy + math.sqrt(d)) / g or 1
        if DBG then io.stderr:write(string.format("launch %s vx %.2f vy %.2f t %.2f at %.1f,%.1f rot %.0f\n", self.prefab, vx, vy, t, self.x, self.z, self.rot)) end
        self.vel = vx
        Schedule(self, t, function()
            self.vel = 0
            local was = acting
            acting = self
            c:Hit()
            acting = was
        end)
    end
end

function Entity:AddComponent(name)
    if REAL_COMPONENTS[name] then
        local ok, cls = pcall(require, "components/" .. name)
        if ok and type(cls) == "table" then
            local made, c = pcall(cls, self)
            if made and c ~= nil then
                self.components[name] = c
                return c
            end
            io.stderr:write("component " .. name .. ": " .. tostring(c) .. "\n")
        end
    end
    local c = setmetatable({ inst = self }, PERMISSIVE)
    -- (worn things: none - the War Machine's lunar burn looks through them)
    if name == "inventory" then c.equipslots = {} end
    -- (what it fights with in its hands, given it by its own prefab - the Spat's Snaut Bash, its 0.5 on top
    -- of its own reach: the game's GetHitRange counts it (combat.lua:1002), here it was left out and every
    -- bash 3.5-4 off went undrawn, 114 of 508. SIM_OLD_WEAPON=1: as before; VERIFY_PLAN 6.15)
    if not os.getenv("SIM_OLD_WEAPON") then
        if name == "inventory" then
            c.items, c.hands = {}, nil
            function c:GiveItem(item) if item ~= nil then self.items[#self.items + 1] = item end return true end
            function c:Equip(item) if item ~= nil then self.hands = item end end
            -- (and off again - Tropical Experience's green tentacle holds its spike thrower only as it shoots from afar
            -- (MakeWeapon: Equip, Unequip at once); kept in its hands here, its bite up close was taken for a shot, 361
            -- of its bites undrawn on the bench, 2026-10-22)
            function c:Unequip(slot) local h = self.hands self.hands = nil return h end
            function c:GetEquippedItem(slot) return (slot == nil or slot == "hands" or slot == (rawget(_G, "EQUIPSLOTS") or {}).HANDS) and self.hands or nil end
        elseif name == "weapon" then
            function c:SetRange(a, h) self.attackrange, self.hitrange = a, h or a end
            function c:SetProjectile(p) self.projectile = p end
        end
    end
    -- (who it fights: you alone - the Umbral Abomination counts them to pick how many to call up (SGshrouden), nil
    -- stopping its attack, 2026-10-23 update)
    if name == "grouptargeter" then
        function c:GetNumTargets() return 1 end
        function c:GetTargets() return {} end
    end
    -- (how long it has been about - the Crab King's freeze cast grows with it (crabking.lua :1753, :1970), nil stopping
    -- its geyser spawner, every run "making crabking_geyserspawner" failed; 2026-10-26)
    if name == "age" then
        local made = frame_n
        function c:GetAge() return (frame_n - made) * FRAMES end
    end
    -- (one thrown straight, not homing (its projectile component, Throw): flown for real - on the way it
    -- faces (its launch angle, or to its target), as fast as it's set, as far as its range - looking round
    -- itself each frame as far as it strikes (its hit distance and a body's .5): where it looked is where
    -- it may strike, as a gestalt's flight (fly_queries) - the Evolved Gestalt Guard's three shards, 5 of
    -- 266 struck undrawn, their move run offline striking nothing. A homing one as before. SIM_OLD_PROJECTILE=1)
    if name == "projectile" and not os.getenv("SIM_OLD_PROJECTILE") then
        c.speed, c.hitdist, c.homing = 10, 1, true
        function c:SetSpeed(s) self.speed = s end
        function c:SetRange(rg) self.range = rg end
        function c:SetHitDist(d) self.hitdist = d end
        function c:SetHoming(h) self.homing = h end
        function c:SetLaunchAngle(ang) self.launchangle = ang end
        function c:SetOnThrownFn(fn) self.onthrown = fn end
        function c:Throw(owner, target, attacker)
            if self.homing ~= false then return end
            local e = self.inst
            if self.launchangle ~= nil then
                e.rot = self.launchangle
            elseif target ~= nil and target.x ~= nil then
                e.rot = math.atan2(-(target.z - e.z), target.x - e.x) / DEGREES
            end
            e.vel = self.speed or 10
            -- (its blow its thrower's (Hit: the attacker's combat DoAttack) - as_boss, while it flies)
            if attacker ~= nil and attacker.components ~= nil and rawget(attacker.components, "combat") ~= nil then rawset(e, "throw_as_boss", true) end
            -- (its own word as it goes - the shard's, keeping it: made to be thrown that frame, else gone)
            if self.onthrown ~= nil then self.onthrown(e, owner, target, attacker) end
            local x0, z0, comp = e.x, e.z, self
            local task
            task = Schedule(e, 0, function(ent)
                if comp.range ~= nil and (ent.x - x0) ^ 2 + (ent.z - z0) ^ 2 > comp.range * comp.range then
                    ent.vel = 0
                    task:Cancel()
                    return
                end
                local was = acting
                acting = ent
                TheSim:FindEntities(ent.x, 0, ent.z, (comp.hitdist or 1) + .5, { "_combat" })
                acting = was
            end, FRAMES)
        end
    end    -- (what a prefab reads back to work out with: an amount, not nothing - Dragonfly drying off
    -- as it catches fire)
    if name == "moisture" then
        function c:GetMoisture() return 0 end
    end
    -- (and damage worked out from: none extra - a merm's planar damage, left nil, stopped it being made)
    if name == "planardamage" or name == "damagetypebonus" then
        function c:GetBaseDamage() return 0 end
        function c:GetDamage() return 0 end
    end
    self.components[name] = c
    if name == "domesticatable" then
        c.tendencies = {}
        function c:IsDomesticated() return false end
    end
    if name == "combat" then
        c.hitrange, c.attackrange = 3, 3
        function c:SetRange(a, h) self.attackrange, self.hitrange = a, h or a end
        c.min_attack_period = 3
        function c:SetAttackPeriod(p) self.min_attack_period = p end
        -- (and with what's in its hands, as the game's Combat:GetHitRange/GetAttackRange)
        function c:GetWeapon()
            local inv = self.inst ~= nil and self.inst.components ~= nil and rawget(self.inst.components, "inventory") or nil
            local h = inv ~= nil and rawget(inv, "hands") or nil
            return h ~= nil and h.components ~= nil and rawget(h.components, "weapon") ~= nil and h or nil
        end
        function c:GetHitRange()
            local w = self:GetWeapon()
            local wh = w ~= nil and rawget(w.components.weapon, "hitrange") or nil
            return self.temprange or (wh ~= nil and self.hitrange + wh) or self.hitrange
        end
        function c:GetAttackRange()
            local w = self:GetWeapon()
            local wa = w ~= nil and rawget(w.components.weapon, "attackrange") or nil
            return wa ~= nil and math.max(0, self.attackrange + wa) or self.attackrange
        end
        function c:CalcAttackRangeSq(t) local r = self:GetAttackRange() + (t or self.target):GetPhysicsRadius(0) return r * r end
        function c:CalcHitRangeSq(t) local r = self:GetHitRange() + (t or self.target):GetPhysicsRadius(0) return r * r end
        -- (within its reach, as the game's Combat:CanHitTarget - its hit range and the target's body; not
        -- here, it said nothing - no, every time: a strike only "if CanHitTarget" never came - the Lunar
        -- Grazer's devour, the Knook's hop after its bite; VERIFY_PLAN 6.0a)
        -- (and only within its arc ahead, if it has one - the game's Combat:SetHitArc, its CanHitTarget: the
        -- Vault Crawler's 120 degrees, turning to its target only to frame 7 - not here, all round it: drawn a
        -- whole ring, you 95 degrees round it drawn in and never struck, 193 times on the bench. SIM_OLD_ARC=1: none)
        function c:SetHitArc(a) if not os.getenv("SIM_OLD_ARC") then rawset(self, "hitarc", a) end end
        function c:CanHitTarget(t)
            t = t or self.target
            if t == nil or not t.valid then return false end
            if self.ignorehitrange then return true end
            if self.inst:GetDistanceSqToInst(t) > self:CalcHitRangeSq(t) then return false end
            local arc = rawget(self, "hitarc")
            if arc == nil then return true end
            local dx, dz = t.x - self.inst.x, t.z - self.inst.z
            if dx == 0 and dz == 0 then return true end
            local d = (math.atan2(-dz, dx) / DEGREES - (self.inst.rot or 0) + 540) % 360 - 180
            return math.abs(d) * 2 <= arc
        end
        function c:SetDefaultDamage(d) self.defaultdamage = d end
        -- (area damage round whom it strikes - kept: DoAttack below)
        function c:SetAreaDamage(range, scale) rawset(self, "areahitrange", range) end
        -- (all round a spot - a shadow piece's strike where it teleported to: each in reach struck,
        -- as the game's Combat:DoAreaAttack)
        function c:DoAreaAttack(target, range, weapon, validfn, stimuli, excludetags)
            target = target or self.inst
            local x, z = target.x, target.z
            local was = self.ignorehitrange
            self.ignorehitrange = true
            for _, ent in ipairs(TheSim:FindEntities(x, 0, z, range, { "_combat" }, excludetags)) do
                if ent ~= target and ent ~= self.inst and (validfn == nil or validfn(ent, self.inst)) then
                    if ent == sim_target then PlayerHit() else self:DoAttack(ent) end
                end
            end
            self.ignorehitrange = was
        end
        -- (damage dealt / taken modifiers: kept, never read here)
        local mods = setmetatable({ Get = function() return 1 end }, PERMISSIVE)
        c.externaldamagetakenmultipliers, c.externaldamagemultipliers, c.damagemultiplier = mods, mods, 1
        function c:CanTarget(t) return t ~= nil and t.valid end
        -- (after its target, as the game's Combat:HasTarget - not the do-nothing every unknown call is here,
        -- nil: taken for "no target", Uncompromising Mode's Dreadeye teleported off from you mid-swipe (its
        -- onnear), its strike never came near; VERIFY_PLAN 6.0a. SIM_OLD_HASTARGET=1: as before)
        if not os.getenv("SIM_OLD_HASTARGET") then
            function c:HasTarget() return self.target ~= nil end
        end
        function c:TargetIs(t) return self.target == t end
        function c:IsValidTarget(t) return t ~= nil and t.valid end
        -- an attack: on a dummy, noted (if within reach, as Combat:CanHitTarget checks it)
        -- (Uncompromising Mode's area swing, as its Combat:UMSetAreaDamage / DoAttack (postinit/components/
        -- combat.lua): each in reach and in its front cone (or close round it) struck, its target or not -
        -- not here, a do-nothing: the Treeguard drawn as the game's round swing, struck only in front, 153
        -- drawn-in unstruck on the testbench; VERIFY_PLAN 6.0a. A mod's world only; SIM_OLD_UMAREA=1: off)
        function c:UMSetAreaDamage(range, excludetags, coneangle, circleradius, conecheck, check)
            rawset(self, "um_area", range ~= nil and { range = range, excl = excludetags, cone = coneangle,
                circle = circleradius, conecheck = conecheck, check = check } or nil)
        end
        local function UMAreaAttack(self)
            local a = rawget(self, "um_area")
            local function V(v) if type(v) == "function" then return v(self) end return v end
            local radius = V(a.range) or 0
            local me = self.inst
            local fx, fz = math.cos(-(me.rot or 0) * DEGREES), math.sin(-(me.rot or 0) * DEGREES)
            local was = self.ignorehitrange
            self.ignorehitrange = true
            rawset(self, "um_in_area", true)
            for _, ent in ipairs(TheSim:FindEntities(me.x, 0, me.z, radius + 3, { "_combat" }, a.excl)) do
                local er = ent.GetPhysicsRadius ~= nil and ent:GetPhysicsRadius(0) or 0
                local range = radius + er
                local dsq = me:GetDistanceSqToInst(ent)
                if ent ~= me and dsq <= range * range then
                    local ok
                    if a.conecheck ~= nil and not a.conecheck(ent, me) then
                        ok = true
                    else
                        local circle = a.circle ~= nil and V(a.circle) + er or nil
                        if circle ~= nil and dsq < circle * circle then
                            ok = true
                        else
                            local dx, dz = ent.x - me.x, ent.z - me.z
                            local len = math.sqrt(dx * dx + dz * dz)
                            ok = len < 1e-6 or (dx * fx + dz * fz) / len >= math.cos((a.cone or 160) / 2 * DEGREES)
                        end
                    end
                    if ok and (a.check == nil or a.check(ent, me)) then
                        if ent == sim_target then PlayerHit() else self:DoAttack(ent) end
                    end
                end
            end
            rawset(self, "um_in_area", nil)
            self.ignorehitrange = was
        end
        function c:DoAttack(t)
            if rawget(self, "um_area") ~= nil and not rawget(self, "um_in_area") and rawget(_G, "MODENV") ~= nil
                and not os.getenv("SIM_OLD_UMAREA") then
                return UMAreaAttack(self)
            end
            t = t or self.target
            if t == nil then return end
            -- (no harm in it (SetDefaultDamage(0), nothing in its hands): its blow only sets off what does - Tropical Experience's
            -- knight boat, its cannonballs lobbed at you on its attack (onattackother): struck here from 20 off, a dark ring 23
            -- round it, nothing coming of it. SIM_OLD_NOHARM=1: as before)
            if rawget(self, "defaultdamage") == 0 and self:GetWeapon() == nil and not os.getenv("SIM_OLD_NOHARM")
                -- (not one that holds things: what it strikes with comes into its hands by the time it fights - a monkey's poop,
                -- not yet here: taken for no harm, 113 of the chimp's blows undrawn on the bench)
                and (self.inst == nil or self.inst.components == nil or rawget(self.inst.components, "inventory") == nil) then
                if self.inst ~= nil and self.inst.PushEvent ~= nil then pcall(self.inst.PushEvent, self.inst, "onattackother", { target = t }) end
                return
            end
            -- (with a weapon that shoots (weapon:SetProjectile, or a thrown one), as the game's Combat:DoAttack: it only
            -- shoots - no blow of its own; one flying straight (not homing) is drawn as it flies (true_range DARTS) -
            -- struck at once here, its whole reach was drawn struck: MacTusk's dart (15.5 round it), Tropical Experience's
            -- green tentacle's spike (20), dark and never striking, "too big, no damage, dark", the player 2026-10-22.
            -- A homing one (the Clockwork Bishop's charge) as before. SIM_OLD_RANGED=1: as before)
            if not os.getenv("SIM_OLD_RANGED") then
                local w = self:GetWeapon()
                local wc = w ~= nil and w.components or nil
                local shot = nil
                if wc ~= nil and rawget(wc, "projectile") ~= nil then shot = wc.projectile
                elseif wc ~= nil and rawget(wc, "weapon") ~= nil and rawget(wc.weapon, "projectile") ~= nil then
                    local ranged_homing = rawget(_G, "SIM_RANGED_HOMING")
                    if ranged_homing == nil then ranged_homing = {} rawset(_G, "SIM_RANGED_HOMING", ranged_homing) end
                    local pn = wc.weapon.projectile
                    if ranged_homing[pn] == nil then
                        local ok, p = pcall(SpawnPrefab, pn)
                        local pc = ok and p ~= nil and p.components ~= nil and rawget(p.components, "projectile") or nil
                        -- (or lobbed (complexprojectile): coming down where its target stood, drawn as it flies - a thing of its own
                        -- (striker): the Strange Scorpion's spit, struck at once here, a ring 24 round it)
                        local lob = ok and p ~= nil and p.components ~= nil and rawget(p.components, "complexprojectile") ~= nil
                        ranged_homing[pn] = lob and "lob" or (pc == nil or pc.homing ~= false)
                        if ok and p ~= nil and p.Remove ~= nil then pcall(p.Remove, p) end
                    end
                    -- (shot for real, as the game's Weapon:LaunchProjectile - flown its way, its blows the shooter's (as_boss):
                    -- its lane its move's, from where it stands - not nothing: a lizardman's spit from 1 off strikes before
                    -- its dart is seen, 183 undrawn so on the bench)
                    -- (said, the frame it shoots and what: the move kept as a shot - true_range draws a lane from it at you
                    -- till then (sim shoots), its dart's own once it flies (DARTS); a lizardman's spit from 1 off strikes
                    -- before its dart is ever seen)
                    if ranged_homing[pn] == "lob" then return end
                    if not ranged_homing[pn] then
                        if rawget(_G, "SIM_SHOT") == nil then rawset(_G, "SIM_SHOT", { prefab = pn, frame = frame_n }) end
                        return
                    end
                end
                if shot ~= nil and shot.homing == false then
                    if rawget(_G, "SIM_SHOT") == nil then rawset(_G, "SIM_SHOT", { prefab = w.prefab, frame = frame_n }) end
                    return
                end
            end
            -- (the other player, EXTRA_PLAYER, struck too - within reach, as the game checks it)
            if sim_extra ~= nil and t == sim_extra then
                local r = self:GetHitRange() + .5
                if self.ignorehitrange or self.inst:GetDistanceSqToInst(t) <= r * r then extra_attacked = true end
            end
            -- (the player itself struck - as the game checks it, its real body, not a cell's)
            if t == sim_target then
                local r = self:GetHitRange() + .5
                -- (missed - out of its reach - with area damage set (SetAreaDamage): all round itself that far
                -- instead, as the game's Combat:DoAttack does on a miss - the Wilting Dragonfly's bite and
                -- dash, 6 round it: struck 5.1 to 5.8 off, drawn 4.5. A mod's world only: the game's own
                -- moves as checked)
                -- (and in its reach too: you, its target, struck either way within that - stepping out as it
                -- strikes, struck by the miss: one shape for every distance, not its reach's alone)
                if not self.ignorehitrange and rawget(self, "areahitrange") ~= nil
                    and (rawget(_G, "MODENV") ~= nil or rawget(_G, "boss_miss_area")) and not rawget(self, "in_area") then
                    rawset(self, "in_area", true)
                    -- (its search ours, not the boss's looking round for what to strike: the target found
                    -- by it is no "found" - taken so, the strike's reach round the boss was dropped: the
                    -- Stumpling drawn to 1.5, striking to 2; VERIFY_PLAN 6.0a C5)
                    local found_was = target_found_at
                    self:DoAreaAttack(self.inst, self.areahitrange)
                    if not os.getenv("SIM_OLD_FOUND") then target_found_at = found_was end
                    rawset(self, "in_area", nil)
                end
                if self.ignorehitrange or (self.inst:GetDistanceSqToInst(t) <= r * r and (rawget(self, "hitarc") == nil or self:CanHitTarget(t))) then
                    PlayerHit()
                    -- (and round it, as the game's Combat:DoAttack does with area damage set
                    -- (SetAreaDamage) - all within that of whom it struck. OFF: round its target, that's
                    -- you - drawn round you, following you wherever, after it struck (the user, 2026-10-17:
                    -- "why a hitbox round the player"); you struck anyway, being its target. SIM_AREA=1: on)
                    if os.getenv("SIM_AREA") and rawget(self, "areahitrange") ~= nil and rawget(_G, "MODENV") ~= nil and not rawget(self, "in_area") then
                        rawset(self, "in_area", true)
                        self:DoAreaAttack(t, self.areahitrange)
                        rawset(self, "in_area", nil)
                    end
                end
            end
            if not t.is_dummy then
                -- (its target: only it - an attack on whoever it's after, within its hit range)
                -- (the boss's own: not a gestalt it sent going for its target - that one's drawn
                -- as it flies, wherever its target has gone by then, not round where it stood)
                -- (nor one that found it by looking round a spot just now - a swoop striking all it
                -- runs into: its cells say where already, not a ring of its reach)
                local found = target_found_at ~= nil and frame_n - target_found_at <= 5 and not os.getenv("NOFOUND")
                if t == self.target and not self.ignorehitrange and rawget(self.inst, "is_sim_boss") and not found then
                    local range = self:GetHitRange()
                    target_hit = math.max(target_hit or 0, range)
                    -- (and where it was then: a leap at its target bites where it lands)
                    -- (its arc, if it has one, and the way it faced as it struck - the cells within that only)
                    table.insert(target_hits, { frame = frame_n, x = self.inst.x, z = self.inst.z,
                        range = range, arc = rawget(self, "hitarc"), rot = self.inst.rot, anim = self.inst.anim,
                        anim_at = math.floor((now - (self.inst.anim_t or now)) / FRAMES + .5) })
                end
                return
            end
            if not self.ignorehitrange then
                local r = self:GetHitRange() + t:GetPhysicsRadius(0)
                if self.inst:GetDistanceSqToInst(t) > r * r then return end
                if rawget(self, "hitarc") ~= nil and not self:CanHitTarget(t) then return end
            end
            local anim, anim_at = self.inst.anim, math.floor((now - (self.inst.anim_t or now)) / FRAMES + .5)
            if DBG and os.getenv("SIMDBG_HIT") then io.stderr:write(string.format("hit dummy by %s (acting %s) at f%d\n", tostring(self.inst.prefab), tostring(acting and acting.prefab), frame_n)) end
            move_effects.harm = true
            t = HitKey(t)
            if hits[t] ~= nil then
                -- (struck again: when last, and in what)
                Restruck(hits[t], frame_n, anim, anim_at)
            end
            if hits[t] == nil then
                -- (who did it, and where it and the boss were then)
                local by = acting
                local sg = self.inst.sg
                if acting ~= nil then acting_seen[acting] = true end
                hits[t] = { frame = frame_n, by = by, bx = by and by.x, bz = by and by.z, brot = by and by.rot,
                    boss_anim = sim_boss ~= nil and sim_boss.anim or nil, boss_state = sim_boss ~= nil and sim_boss.sg ~= nil and sim_boss.sg.entry ~= nil and sim_boss.sg.entry.name or nil,
                    sx = self.inst.x, sz = self.inst.z, srot = self.inst.rot, q = last_query,
                    -- (struck by the boss's own combat, from a thing it set off - its laser's blasts
                    -- (fx.caster): the move's own too, drawn with it - Uncompromising Mode's blue laser,
                    -- drawn apart, its move's yellow never went red)
                    also_own = by ~= nil and by ~= sim_boss and self.inst == sim_boss or nil,
                    -- (struck by its swing's miss all round itself (DoAttack above, a mod's world) - not
                    -- the area its strike on its target gave the rest: below, kept from dropping that strike)
                    miss_area = rawget(self, "in_area") or nil,
                    -- (the state it was in, and where it stood and faced when that began)
                    entry = sg ~= nil and sg.entry or nil }
            end
        end
    elseif name == "locomotor" then
        c.walkspeed, c.runspeed = 4, 6
        -- (stopping: its body stops too, as the game's does - a boss on the move keeps going
        -- into a move that doesn't)
        function c:StopMoving() if self.inst.Physics ~= nil then self.inst.Physics:Stop() end end
        function c:Stop() self:StopMoving() end
        function c:GetSpeedMultiplier() return 1 end
        function c:GetRunSpeed() return self.runspeed end
        function c:GetWalkSpeed() return self.walkspeed end
        -- (running on the way it faces, as fast as set - the Wilting Dragonfly's dash, RunForward
        -- every frame at 15: stood still here, drawn 7 long, it went 16. A mod's world only: the
        -- game's own moves as checked)
        if rawget(_G, "MODENV") ~= nil then
            function c:RunForward() if self.inst.Physics ~= nil then self.inst.Physics:SetMotorVel(self.runspeed or 6) end end
            function c:WalkForward() if self.inst.Physics ~= nil then self.inst.Physics:SetMotorVel(self.walkspeed or 4) end end
        end
    elseif name == "timer" then
        function c:TimerExists() return false end
        -- (the boss's own: noted - one it starts as it goes is the move's cooldown)
        function c:StartTimer(n, t)
            if rawget(self.inst, "is_sim_boss") and type(n) == "string" and type(t) == "number" then
                boss_timers[n] = math.max(boss_timers[n] or 0, t)
            end
        end
        if things_timers then
            -- (something set off: its timers run - a snare charging, pulsing, charging again)
            c.timers = {}
            function c:StartTimer(n, t)
                if self.timers[n] ~= nil then self.timers[n]:Cancel() end
                self.timers[n] = Schedule(self.inst, t, function(inst)
                    self.timers[n] = nil
                    inst:PushEvent("timerdone", { name = n })
                end)
            end
            function c:StopTimer(n)
                if self.timers[n] ~= nil then self.timers[n]:Cancel() self.timers[n] = nil end
            end
            function c:TimerExists(n) return self.timers[n] ~= nil end
            function c:GetTimeLeft(n) local t = self.timers[n] return t ~= nil and t.at - now or nil end
        end
    elseif name == "health" then
        c.currenthealth, c.maxhealth, c.minhealth = 1000, 1000, 0
        function c:IsDead() return false end
        function c:GetPercent() return 1 end
    elseif name == "updatelooper" then
        -- (what it does every tick - junk falling, landing where it strikes: run every tick)
        c.fns = {}
        function c:AddOnUpdateFn(fn)
            local task
            task = Schedule(self.inst, 0, function(inst) if self.fns[fn] ~= task then return end fn(inst, TICK) end, FRAMES)
            self.fns[fn] = task
        end
        function c:RemoveOnUpdateFn(fn) if self.fns[fn] then self.fns[fn]:Cancel() self.fns[fn] = nil end end
        c.AddPostUpdateFn, c.RemovePostUpdateFn = c.AddOnUpdateFn, c.RemoveOnUpdateFn
        c.AddOnWallUpdateFn, c.RemoveOnWallUpdateFn = c.AddOnUpdateFn, c.RemoveOnUpdateFn
    elseif name == "grouptargeter" then
        c.num_targets = 1
        -- (whom it's fighting: its target - the War Machine's orbital strike picks among them)
        function c:GetTargets() local t = {} if sim_target ~= nil then t[sim_target] = true end return t end
    elseif name == "burnable" then
        c.fxdata = { {} }
    elseif name == "scaler" then
        c.scale = 1
    elseif name == "freezable" then
        c.coldness = 0
    elseif name == "playerprox" then
        c.AliveModes = setmetatable({}, { __index = function(_, k) return k end })
    end
    return c
end

-- (the game's entity class: what's a thing)
EntityScript = { is_instance = function(x) return type(x) == "table" and getmetatable(x) == Entity end }
-- (the game's task class: what's a task - one with Cancel; the Shadow Thrall mouth's bite cooldowns)
Periodic = { is_instance = function(x) return type(x) == "table" and x.Cancel ~= nil end }

-- (the tags every dummy has, and no other: Body)
DUMMY_TAGS = { _combat = true, _health = true, character = true, player = true, freezable = true }

-- the engine's search
TheSim = setmetatable({}, PERMISSIVE)
-- (dummies only answer an attack's small searches: a wide one is looking for whom to go
-- after, and that's its target alone here)
local WIDE = 12
-- (the dummies never move: kept in buckets BUCKET wide, looked up by area; everything else -
-- the boss, its target, what it sets off - in `others`, looked through one by one)
local BUCKET = 2
local function BucketKey(bx, bz) return bx * 100000 + bz end
local function Matches(e, x, z, r, must, cant, oneof)
    local dx, dz = e.x - x, e.z - z
    local rr = r + (e.pad or 0)
    if not e.valid or dx * dx + dz * dz > rr * rr then return false end
    if must ~= nil then for i = 1, #must do if not e.tags[must[i]] then return false end end end
    if cant ~= nil then for i = 1, #cant do if e.tags[cant[i]] then return false end end end
    if oneof ~= nil and #oneof > 0 then return AnyTag(e, oneof) end
    return true
end
function TheSim:FindEntities(x, y, z, r, must, cant, oneof)
    local out = {}
    -- (something the boss set off standing right where it asks about - an ice spike, a laser's
    -- blast: what's hit now is that thing's doing too)
    -- (not an effect at the boss itself - a pound's ring, a hole where it lands; the first set off
    -- of several there - a laser's blast, not the trail it leaves)
    last_query = { x = x, z = z, r = r, frame = frame_n }
    -- (something it set off, looking round itself frame after frame - the War Machine's laser
    -- burning on, each one it finds struck once: from when to when)
    if acting ~= nil and acting ~= sim_boss then
        local q = thing_queries[acting]
        if q == nil then q = { first = frame_n } thing_queries[acting] = q end
        q.last = frame_n
    end
    -- (the boss looking at the very same spot, as far round, as it did the frame before - on and
    -- on, every frame: not two searches some while apart, for something else)
    local again = false
    if acting == sim_boss and sim_boss ~= nil then
        local qk = string.format("%.1f,%.1f,%.2f", x, z, r)
        local seen = boss_queries[qk]
        again = seen == frame_n - 1 or (seen == frame_n and boss_queries_again[qk] == true)
        if seen ~= frame_n then boss_queries_again[qk] = again end
        boss_queries[qk] = frame_n
    end
    -- (something set off, flying, looking round itself for whom to strike - a gestalt: it would
    -- stop at the first it finds, and the dummies are everywhere; it's let fly on, and where it
    -- looked is where it may strike)
    -- (not one come down from up high - a missile: it goes off where it comes down, round itself,
    -- struck for real; `burst`)
    -- (and only a search for creatures - asking for what fights or lives (a gestalt's: _combat, _health). One with
    -- no such tag looks for something else: Uncompromising Mode's guardian goo for its own goo trail, 4 and 2
    -- round it every 0.4 s as it flies (shadow_goo.lua:27-48, :207-211, no tags) - drawn as rings along its way
    -- and nothing where it lands (1.5 round, :75): 32 of 32 of its blows missed, the player saw it, 2026-10-19.
    -- SIM_OLD_FLYQ=1: as before)
    local for_creatures = os.getenv("SIM_OLD_FLYQ") ~= nil
    for _, list in ipairs({ must or {}, oneof or {} }) do
        for i = 1, #list do
            local tg = list[i]
            if tg == "_combat" or tg == "_health" or tg == "player" or tg == "character" or tg == "creature" or tg == "monster" or tg == "animal" then for_creatures = true end
        end
    end
    if acting ~= nil and acting ~= sim_boss and (acting.vel or 0) ~= 0 and not rawget(acting, "was_up") and for_creatures then
        table.insert(fly_queries, { by = acting, frame = frame_n, x = x, z = z, r = r })
        return {}
    end
    if acting ~= nil and acting ~= sim_boss and (acting.vel or 0) ~= 0 and rawget(acting, "was_up") then rawset(acting, "burst", true) end
    local away = sim_boss == nil or (sim_boss.x - x) ^ 2 + (sim_boss.z - z) ^ 2 > 1
    for _, e in ipairs(others) do
        if away and e ~= sim_boss and e ~= sim_target and e.prefab ~= "world" and e.prefab ~= "?"
            and (e.x - x) ^ 2 + (e.z - z) ^ 2 < .0025
            and (last_query.ent == nil or e.GUID < last_query.ent.GUID) then
            last_query.ent = e
        end
        if Matches(e, x, z, r, must, cant, oneof) then table.insert(out, e) end
    end
    -- (a small search - for what to strike, not whom to go after: a pig looking round for
    -- someone to fight finds you too, and that's no strike)
    for _, e in ipairs(out) do
        if e == sim_target and r <= 4 then target_found_at = frame_n end
    end
    -- (asking for a tag no dummy has - another deer's ice circle: none of them, unlooked at)
    local dummy_may = true
    for i = 1, must ~= nil and #must or 0 do if not DUMMY_TAGS[must[i]] then dummy_may = false end end
    -- (or a wide one made to strike all there, not to pick whom to go after - the Scion's
    -- supernova, 24 round: its combat set to ignore range as it searches)
    local blast = sim_boss ~= nil and rawget(sim_boss.components, "combat") ~= nil
        and rawget(sim_boss.components.combat, "ignorehitrange") == true
    -- (something it set off that strikes on and on round itself, its shape already measured this
    -- move (skip_thing_dummies) - the Celestial Champion's crystals pulsing 20 s over thousands of
    -- dummies, run after run: no dummies for it now; it still runs as the game has it, on its own
    -- timers - SIM_ALL_THINGS=1: every run measured, as before)
    if acting ~= nil and acting ~= sim_boss and skip_thing_dummies ~= nil and skip_thing_dummies[acting.prefab] then dummy_may = false end
    -- (or a wide one the boss makes at a set frame of its move, its timeline: a strike looking far, then picking by a
    -- shape of its own - Tropical Experience's boar's ground slam, 16 round, then a lane 15 long ahead (SGbossboarte.lua
    -- GroundSlamTargets): struck nothing here, 2026-10-20. SIM_OLD_WIDE=1: as before)
    if sim_in_timeline ~= nil and sim_in_timeline == sim_boss and os.getenv("SIM_OLD_WIDE") == nil then blast = true end
    if (r <= WIDE or blast) and dummy_may and not NO_DUMMIES then
        for bx = math.floor((x - r) / BUCKET), math.floor((x + r) / BUCKET) do
            for bz = math.floor((z - r) / BUCKET), math.floor((z + r) / BUCKET) do
                for _, e in ipairs(dummy_grid[BucketKey(bx, bz)] or {}) do
                    if Matches(e, x, z, r, must, cant, oneof) then
                        table.insert(out, e)
                        -- (found by something it set off, and when first - told after whether it
                        -- struck them: Shared)
                        if acting ~= nil and acting ~= sim_boss then
                            local tf = thing_found[acting]
                            if tf == nil then tf = {} thing_found[acting] = tf end
                            tf[e] = tf[e] or frame_n
                        end
                        -- (the boss looking there again for whom to strike - struck already, so
                        -- passed over, but anyone stepping in now would be: still in danger then -
                        -- Frostjaw coming up, striking round itself all the while)
                        if again then
                            local h = hits[HitKey(e)]
                            if h ~= nil and h.frame < frame_n and (h.by == nil or h.by == sim_boss)
                                and (h.last == nil or h.last[1] < frame_n) then
                                Restruck(h, frame_n, sim_boss.anim,
                                    math.floor((now - (sim_boss.anim_t or now)) / FRAMES + .5))
                            end
                        end
                    end
                end
            end
        end
    end
    return out
end
-- (searches by tags registered ahead: the same, the tags looked at as they are)
function TheSim:GetTimeScale() return 1 end
function TheSim:RegisterFindTags(must, cant, oneof) return { must, cant, oneof } end
function TheSim:FindEntities_Registered(x, y, z, r, reg)
    reg = reg or {}
    return TheSim:FindEntities(x, y, z, r, reg[1], reg[2], reg[3])
end

-- prefabs: loaded from the game's files on first use (which file makes which prefab: read once
-- from the files' Prefab("...") lines)
local prefabs, loaded, searched = {}, {}, {}
-- (and in the game's own list of them - a mod's post-init digs into Prefabs.deerclops.fn)
Prefabs = {}
-- (named by its last part, as the game does - Tropical Experience's "monsters/crocodog" is crocodog)
Prefab = function(name, fn) name = name:match("([^/]+)$") or name prefabs[name] = fn local p = { name = name, fn = fn } Prefabs[name] = p return p end
local prefab_file, maker_file, own_file, alt_file = {}, {}, {}, {}
-- (read again if it came out short: with many runs side by side, the listing or a file can fail
-- now and then - a whole monster went missing once)
-- (a part of a -jobs run: the index the whole run made once, handed on - SIM_SCAN_CACHE; read
-- here again by each of 322 parts, it took each a second)
scan_cache = nil
if os.getenv("SIM_SCAN_CACHE") ~= nil then
    local ok, got = pcall(dofile, os.getenv("SIM_SCAN_CACHE"))
    if ok and type(got) == "table" and got.prefab_file ~= nil then
        scan_cache = got
        for k, v in pairs(got.prefab_file) do prefab_file[k] = v end
        for k, v in pairs(got.alt_file) do alt_file[k] = v end
    else
        io.stderr:write("SIM_SCAN_CACHE unreadable - scanning\n")
    end
end
for attempt = 1, scan_cache ~= nil and 0 or 5 do
    local files, read = 0, 0
    local p = io.popen('dir /b "' .. SCRIPTS:gsub("/", "\\") .. '\\prefabs\\*.lua" 2>nul')
    for file in p:lines() do
        files = files + 1
        local fh = io.open(SCRIPTS .. "/prefabs/" .. file, "rb")
        if fh ~= nil then
            read = read + 1
            local text = fh:read("*a")
            fh:close()
            local base = file:gsub("%.lua$", "")
            -- (its own file first: spider.lua, not hats.lua's MakeHat("spider") - the Spider was
            -- made from the hat file and was no spider at all)
            own_file[base] = true
            -- (Prefab(...) itself - not SpawnPrefab(...))
            for name in ("\n" .. text):gmatch('[^%w_]Prefab%(%s*"[%w_/]-%f[%w_]([%w_]+)"') do
                prefab_file[name] = prefab_file[name] or base
            end
            -- (made through a maker of its own: return MakeRook("rook", ...))
            for name in text:gmatch('return%s+Make%w*%(%s*"([%w_]+)"') do
                maker_file[name] = maker_file[name] or base
            end
            for name in text:gmatch(',%s*\n%s*Make%w*%(%s*"([%w_]+)"') do
                maker_file[name] = maker_file[name] or base
            end
            -- (or given a table: MakeWarg({ name = "mutatedwarg", ... }) - it was made from nothing)
            for name in text:gmatch('Make%w*%(%s*{%s*name%s*=%s*"([%w_]+)"') do
                maker_file[name] = maker_file[name] or base
            end
        end
    end
    p:close()
    if files > 500 and read == files then
        for name in pairs(own_file) do alt_file[name] = prefab_file[name] prefab_file[name] = name end
        for name, f in pairs(maker_file) do prefab_file[name] = prefab_file[name] or f end
        break
    end
    io.stderr:write(string.format("prefab files: listed %d, read %d - again\n", files, read))
end
SpawnPrefab = function(name)
    local file = prefab_file[name]
    -- (one of a family whose names are made as the file runs - "sandspike_" .. size: the file
    -- that makes the family's own name)
    local base = name
    while file == nil and base:find("_") do
        base = base:gsub("_[^_]*$", "")
        file = prefab_file[base]
    end
    file = file or name
    if prefabs[name] == nil and not loaded[file] then
        loaded[file] = true
        local f = loadfile(SCRIPTS .. "/prefabs/" .. file .. ".lua")
        for _ = 1, 4 do
            if f ~= nil or io.open(SCRIPTS .. "/prefabs/" .. file .. ".lua", "rb") == nil then break end
            f = loadfile(SCRIPTS .. "/prefabs/" .. file .. ".lua")
        end
        if f ~= nil then
            local ok, err = pcall(f)
            if not ok then io.stderr:write("loading " .. file .. ": " .. tostring(err) .. "\n") end
        end
    end
    -- (its own-named file didn't make it after all: where its Prefab(...) line is)
    if prefabs[name] == nil and alt_file[name] ~= nil and not loaded[alt_file[name]] then
        loaded[alt_file[name]] = true
        local f = loadfile(SCRIPTS .. "/prefabs/" .. alt_file[name] .. ".lua")
        if f ~= nil then pcall(f) end
    end
    -- (still not made: its name put together as a file runs - a table of them, name = "crawlinghorror":
    -- each file that names it, until one makes it)
    if prefabs[name] == nil and not searched[name] then
        searched[name] = true
        local fh = io.popen('findstr /m /c:"\\"' .. name .. '\\"" "' .. SCRIPTS:gsub("/", "\\") .. '\\prefabs\\*.lua" 2>nul')
        for path in fh:lines() do
            local fname = path:match("([^\\/]+)%.lua%s*$")
            if fname ~= nil and not loaded[fname] then
                loaded[fname] = true
                local f = loadfile(SCRIPTS .. "/prefabs/" .. fname .. ".lua")
                if f ~= nil then
                    local ok, err = pcall(f)
                    if not ok then io.stderr:write("loading " .. fname .. ": " .. tostring(err) .. "\n") end
                end
                if prefabs[name] ~= nil then break end
            end
        end
        fh:close()
    end
    local fn = prefabs[name]
    local e
    if fn ~= nil then
        local ok, res = pcall(fn)
        if ok and type(res) == "table" then e = res else
            io.stderr:write("making " .. name .. ": " .. tostring(res) .. "\n")
        end
    end
    e = e or NewEntity(name)
    e.prefab = name
    if rawget(_G, "MODENV") ~= nil and fn ~= nil then MODENV.Prefab(e, name) end
    if DBG then io.stderr:write(string.format("spawn %s at f%d\n", name, frame_n)) end
    -- (made facing some way of no meaning - not lined up with the boss and its target, as here
    -- they always are: what turns it later shows)
    if sim_boss ~= nil then e.rot = 137 end
    e.spawned_by = acting
    rawset(e, "spawn_frame", frame_n)
    return e
end

-- stategraphs
-- (each telling what it is, as the game's classes do - a mod's stategraph post-init checks: v:is_a(State))
State = function(t) t.is_a = function() return true end return t end
TimeEvent = function(t, fn) return { time = t, fn = fn } end
FrameEvent = function(f, fn) return { time = f * FRAMES, fn = fn } end
SoundTimeEvent = function(t) return { time = t, fn = NOOP } end
SoundFrameEvent = function(f) return { time = f * FRAMES, fn = NOOP } end
EventHandler = function(name, fn) return { name = name, fn = fn, is_a = function() return true end } end
ActionHandler = function(action) return { action = action or {}, is_a = function() return true end } end
StateGraph = function(name, states, events) return { name = name, states = states, events = events } end
CommonStates = setmetatable({}, PERMISSIVE)
CommonHandlers = setmetatable({}, { __index = function() return function() return {} end end })
SGDaywalkerCommon = setmetatable({}, PERMISSIVE)

-- (a mod's world over the game's - SIM_MOD=<its folder>, the scripts the game's with its own laid
-- over (tools/mod_scripts.ps1): its modmain run, what it adds put on as each thing is made -
-- tools/mod_env.lua. Globals: the main chunk holds all the locals it may)
if os.getenv("SIM_MOD") then
    MODENV = dofile(HERE .. "/mod_env.lua")
    local fwo = FindWalkableOffset
    MODENV.Run(os.getenv("SIM_MOD"), nil, SCRIPTS)
    -- (the game's simutil, pulled in by the mod, over the sim's own: its walkable test finds no ground here -
    -- nowhere to go; the sim's again - the Shadow Bishop's teleports before each charge)
    FindWalkableOffset, FindValidPositionByFan = fwo, fwo
    do
        local add = Entity.AddComponent
        function Entity:AddComponent(name)
            local had = self.components[name]
            local c = add(self, name)
            if had == nil and c ~= nil then MODENV.Component(c, name, self) end
            return c
        end
    end
end
-- (a stategraph file's, with the mod's states and post-inits)
function LoadSG(file)
    local sg = assert(loadfile(SCRIPTS .. "/stategraphs/" .. file .. ".lua"))()
    if rawget(_G, "MODENV") ~= nil then sg = MODENV.SG(sg) end
    return sg
end
-- (SIM_MOD_CHANGED=1: only what the mod changes or adds - its own prefab files, a prefab it changes,
-- a stategraph it changes; the rest are the game's, already run. A stategraph's new attacks - states
-- tagged "attack" the game's file hasn't - each a move of its own)
if rawget(_G, "MODENV") ~= nil and os.getenv("SIM_MOD_CHANGED") then
    MOD_FILES = {}
    do
        local pl = io.popen('dir /b "' .. os.getenv("SIM_MOD"):gsub("/", "\\") .. '\\scripts\\prefabs\\*.lua" 2>nul')
        for f in pl:lines() do MOD_FILES[f:gsub("%.lua%s*$", "")] = true end
        pl:close()
    end
    MOD_KEEP = {}
    for _, b in ipairs(BOSSES) do
        local touched = MODENV.prefab[b.prefab] ~= nil or (prefab_file[b.prefab] ~= nil and MOD_FILES[prefab_file[b.prefab]] == true)
        local ok, sg = pcall(LoadSG, b.sg)
        if ok and type(sg) == "table" and (MODENV.sg[sg.name] ~= nil or MODENV.sg_states[sg.name] ~= nil) then
            touched = true
            local okb, base = pcall(function() return assert(loadfile(SCRIPTS .. "/stategraphs/" .. b.sg .. ".lua"))() end)
            local had, have = {}, {}
            for _, s in ipairs(okb and base.states or {}) do if s.name ~= nil then had[s.name] = true end end
            for _, s in ipairs(b.states) do have[type(s) == "table" and s.name or s] = true end
            -- (nor one left out on purpose - b.no_auto: Moose's hop in mid-air, part of its hop)
            for _, s in ipairs(b.no_auto or {}) do have[s] = true end
            for _, s in ipairs(sg.states) do
                local attack = false
                for _, tg in ipairs(s.tags or {}) do if tg == "attack" then attack = true end end
                if attack and s.name ~= nil and not had[s.name] and not have[s.name] then
                    table.insert(b.states, s.name)
                    have[s.name] = true
                end
            end
        end
        if touched then MOD_KEEP[#MOD_KEEP + 1] = b end
    end
    for i = #BOSSES, 1, -1 do BOSSES[i] = nil end
    for i, b in ipairs(MOD_KEEP) do BOSSES[i] = b end
    io.stderr:write(string.format("[mod] %d bosses changed or added by the mod\n", #BOSSES))
end

-- (a thing that looks round as it flies strikes what it finds only if its code harms at all - its prefab's file or its
-- stategraph's: Tropical Experience's rogue waves look for a player within 2 only to splash them wet or speed them on
-- (wave_ripple.lua oncolliderogue), drawn struck round every wave once the game's GetClosestInstWithTag could run here,
-- 2026-10-20. SIM_OLD_FLYHARM=1: every one, as before)
FLY_HARMS = {}  -- (a global: the main chunk holds all the locals it may)
function FlyHarms(prefab)
    if os.getenv("SIM_OLD_FLYHARM") then return true end
    local v = FLY_HARMS[prefab]
    if v ~= nil then return v end
    v = false
    local function Read(path)
        local f = io.open(path, "rb")
        local s = f and f:read("*a") or ""
        if f then f:close() end
        return s
    end
    local text = Read(SCRIPTS .. "/prefabs/" .. (prefab_file[prefab] or prefab) .. ".lua")
    for sg in text:gmatch('SetStateGraph%(%s*"([%w_]+)"') do text = text .. Read(SCRIPTS .. "/stategraphs/" .. sg .. ".lua") end
    for _, h in ipairs({ "DoAttack", "DoAreaAttack", "GetAttacked", '"knockback"', "AddColdness", ":Ignite", "AddSleepiness",
        "AddGrogginess", '"yawn"', "AddDebuff", "DoAOEAttack", "DoArcAttack", ":GroundPound(", ":Explode(", "Ink(" }) do
        if text:find(h, 1, true) then v = true break end
    end
    FLY_HARMS[prefab] = v
    return v
end
--------------------------------------------------------------------------------
-- one run

local function Reset()
    ents, tasks, hits = {}, {}, {}
    others = {}   -- (the dummies stay: made once, never changed - see Dummies)
    now, frame_n, acting, target_hit = 0, 0, nil, nil
    target_hits, last_query, player_hits, boss_timers = {}, nil, {}, {}
    rawset(_G, "SIM_SHOT", nil)
    own_hits = {}
    boss_queries, boss_queries_again = {}, {}
    boss_move_log = {}
    fly_queries = {}
    thing_queries = setmetatable({}, { __mode = "k" })
    thing_found = setmetatable({}, { __mode = "k" })
    things_timers = false
    TheWorld = NewEntity("world")
    -- (not among what a search finds - the game's world never is: Tropical Experience's Ancient Herald's blast, nothing
    -- asked of what it found, struck the world - its every component a stand-in, coldness none - and stopped, 2026-10-20.
    -- SIM_OLD_WORLDFOUND=1: as before)
    if not os.getenv("SIM_OLD_WORLDFOUND") then
        for i = #others, 1, -1 do if others[i] == TheWorld then table.remove(others, i) end end
    end
    TheWorld.ismastersim = true
    TheWorld.Map = setmetatable({ IsPassableAtPoint = function() return true end, GetPlatformAtPoint = NOOP,
        IsOceanAtPoint = function() return false end, IsVisualGroundAtPoint = function() return true end }, PERMISSIVE)
    -- (the ground under a point: land, as all of it is here - nothing told, Tropical Experience's Ancient Robots' lasers
    -- compared it with a number and stopped, 2026-10-20. SIM_OLD_TILE=1: none, as before)
    if not os.getenv("SIM_OLD_TILE") then
        rawset(TheWorld.Map, "GetTileAtPoint", function() return (rawget(_G, "GROUND") ~= nil and rawget(GROUND, "DIRT")) or 6 end)
    end
    TheWorld.components = setmetatable({}, { __index = function() return STUB end })
    TheWorld.state = { season = "autumn", isday = true, cycles = 10, remainingdaysinseason = 10 }
end

-- (what a move does to whoever stands there besides harm - a status: sleep, knocked back, slowed...;
-- each noted as a hit too, with its kind - the move's `effects`, drawn in a colour of their own
-- where that's all it does)
STATUS_EVENTS = { knockback = "knockback", yawn = "sleep", knockedout = "sleep", pinned = "stuck",
    repelled = "knockback", feetslipped = "knockback", stunned = "stun", startfiredamage = "fire" }
local function Body(e)
    e.radius = .5
    -- (locomotor: a player walks - what the Fuelweaver's snares look for)
    e.tags = { _combat = true, _health = true, character = true, player = true, freezable = true, sleeper = true, locomotor = true }
    -- (frozen or set alight where it stands - Klaus' deer's circles: noted as a hit too)
    local function Touched(kind)
        if DBG then io.stderr:write("touched by " .. tostring(acting and acting.prefab) .. " " .. tostring(kind) .. "\n") end
        local by = acting or sim_boss
        if by ~= nil then
            local was = acting
            acting = by
            e:PushEvent("attacked", { attacker = by, status = kind })
            acting = was
        end
    end
    e.components.freezable = setmetatable({ AddColdness = function(_, amount) if (amount or 0) > 0 then Touched("freeze") end end, coldness = 0,
        ResolveResistance = function() return 1 end, IsFrozen = function() return false end }, PERMISSIVE)
    e.components.burnable = setmetatable({ Ignite = function() Touched("fire") end, IsBurning = function() return false end }, PERMISSIVE)
    e.components.health = setmetatable({ IsDead = function() return false end, IsInvincible = function() return false end }, PERMISSIVE)
    -- (its health taken straight off, no combat - Uncompromising Mode's mindweaver grabbing (SGmindweaver.lua:47 DoDelta(-40)),
    -- its goats' lightning, Tropical Experience's jellyfish: noted as a hit; nothing seen before. SIM_OLD_DODELTA=1: as before)
    if os.getenv("SIM_OLD_DODELTA") == nil then
        rawset(e.components.health, "DoDelta", function(_, d) if (tonumber(d) or 0) < 0 then Touched("harm") end end)
    end
    -- (its own stategraph, doing nothing in particular - asked whether it's asleep, knocked out:
    -- no; a gestalt looks before it touches)
    if rawget(e, "sg") == nil then
        e.sg = setmetatable({ HasStateTag = function() return false end, HasAnyStateTag = function() return false end,
            currentstate = { name = "idle" } }, PERMISSIVE)
    end
    -- (sapped - a gestalt's touch: its sanity taken)
    e.components.sanity = setmetatable({ DoDelta = function(_, d) if (d or 0) < 0 then Touched("sanity") end end, GetPercent = function() return 1 end }, PERMISSIVE)
    -- (struck by what something set off does itself - a bomb's blast: noted as a hit)
    -- (CanTarget: the Scion's supernova asks each one's own whether it can - yes)
    e.components.combat = setmetatable({ CanBeAttacked = function() return true end, CanTarget = function() return true end,
        GetAttacked = function(_, attacker)
            -- (or by something flying, come down - a lunar bird's bile: no one acting then, the attacker said)
            if acting ~= nil then e:PushEvent("attacked", { attacker = attacker })
            elseif attacker ~= nil then acting = attacker e:PushEvent("attacked", { attacker = attacker }) acting = nil end
        end }, PERMISSIVE)
    -- (inked - a squid's ink, come down: blinded, no harm - noted as a hit of its own kind)
    e.components.inkable = setmetatable({ Ink = function() Touched("ink") end }, PERMISSIVE)
    -- (slowed - a web, mud: its speed cut by something else)
    e.components.locomotor = setmetatable({ GetRunSpeed = function() return 6 end,
        SetExternalSpeedMultiplier = function(_, source, key, m) if (m or 1) < 1 and source ~= e then Touched("slow") end end }, PERMISSIVE)
    e.components.grogginess = setmetatable({ IsKnockedOut = function() return false end, knockoutduration = 0, grog_amount = 0,
        AddGrogginess = function(_, g) if (g or 0) > 0 then Touched("sleep") end end, KnockOut = function() Touched("sleep") end }, PERMISSIVE)
    e.components.sleeper = setmetatable({ IsAsleep = function() return false end,
        AddSleepiness = function(_, s) if (s or 0) > 0 then Touched("sleep") end end, GoToSleep = function() Touched("sleep") end }, PERMISSIVE)
    e.components.debuffable = setmetatable({ IsEnabled = function() return true end, HasDebuff = function() return false end,
        AddDebuff = function(_, name) Touched("debuff") end }, PERMISSIVE)
    e.components.pinnable = setmetatable({ IsStuck = function() return false end, IsValidPinTarget = function() return true end,
        Stick = function() Touched("stuck") end }, PERMISSIVE)
    -- (what it holds knocked out of its hands)
    -- (and open to its own: a player's is - the Hound Batilisk's chomp lands on your head only so (SGbat CanHatTarget),
    -- every chomp "nothing", 2026-10-23 update)
    e.components.inventory = setmetatable({ DropEquipped = function() Touched("disarm") end,
        GetEquippedItem = function() return nil end, IsFull = function() return false end, equipslots = {},
        IsOpenedBy = function(_, who) return who == e end }, PERMISSIVE)
    e.sg = { HasStateTag = function() return false end, HasAnyStateTag = function() return false end }
    -- (and put into a state by what struck it - Tropical Experience's spiky monkey's slam knocking it back
    -- (v.sg:GoToState("knockback")): nothing here, as before only it failed there. SIM_OLD_PLAYERSG=1: as before)
    if os.getenv("SIM_OLD_PLAYERSG") == nil then e.sg.GoToState = function() end end
end
-- The dummies: made the first time (some 30000 of them - making them each run was nearly all
-- the time it took), kept by area, never in `others`.
local all_dummies = nil
local function Dummies()
    if all_dummies ~= nil then
        -- (as they were: an attack that smashes what's round it - Bearger's - may have gone
        -- after them last run)
        for _, d in ipairs(all_dummies) do
            d.valid = true
            d.tags.player = spec_dummy_player or nil
        end
        return all_dummies
    end
    all_dummies = {}
    local keep = others
    for gx = AHEAD[1], AHEAD[2], STEP do
        for gz = -SIDE, SIDE, STEP do
            local d = NewEntity("dummy")
            d.x, d.z, d.is_dummy = gx, gz, true
            Body(d)
            d.radius = (d.radius or .5) + PAD
            d.pad = PAD
            -- (spec dummy_player: players too, for a boss that strikes only those tagged so - Uncompromising Mode's shadow
            -- creatures and Shadow Wixie (FindEntities(.., { "_combat", "player" })), its goats' lightning (HasTag("player")):
            -- "nothing" in every state. Not for every boss: others ask whether a player is near before going somewhere)
            d.tags.player, d.tags.locomotor = spec_dummy_player or nil, nil
            d.Remove = NOOP -- (stand-ins for players: never taken away)
            table.insert(all_dummies, d)
            local key = BucketKey(math.floor(gx / BUCKET), math.floor(gz / BUCKET))
            dummy_grid[key] = dummy_grid[key] or {}
            table.insert(dummy_grid[key], d)
        end
    end
    others = {}
    for _, e in ipairs(keep) do
        if not e.is_dummy then table.insert(others, e) end
    end
    return all_dummies
end

-- returns { [dummy] = frame hit }, the dummies, and the animations the move played
-- teleport: { frame, x, z } - its target jumps there then (to see when it stops aiming)
-- mem: what its stategraph remembers to begin with (a later phase: { transformed = true })
local no_body_said = {}
-- (where its state aims - true_range/modmain PoseOne, the same)
function TposOf(boss)
    local sm = boss.sg ~= nil and boss.sg.statemem or nil
    if sm == nil then return nil end
    local tp = rawget(sm, "targetpos")
    if type(tp) == "table" and type(tp.x) == "number" and type(tp.z) == "number" then return tp end
    if type(rawget(sm, "tgtx")) == "number" and type(rawget(sm, "tgtz")) == "number" then return { x = sm.tgtx, z = sm.tgtz } end
    return nil
end
-- (how the game goes into a state: handed its target, or nothing - read off its own code, every literal
-- GoToState("name"...) in its stategraph, a mod's post-init of it, its prefab and brain; all with nothing
-- handed on - it never turned to you as it began: Uncompromising Mode's Deerclops swipe, gone into
-- from its prefab with no target, run here handed one, drawn following you. Its target's handed on by
-- the stategraph's doattack (CommonHandlers.OnAttack) or an action: not seen here, so not said)
NOARG_CACHE = {}  -- (a global: the main chunk holds all the locals it may)
function AutoNoArg(prefab, sgfile, statename)
    if type(sgfile) ~= "string" or statename == nil then return false end
    local key = tostring(prefab) .. "|" .. sgfile .. "|" .. statename
    if NOARG_CACHE[key] ~= nil then return NOARG_CACHE[key] end
    local mod = os.getenv("SIM_MOD")
    local files = { SCRIPTS .. "/stategraphs/" .. sgfile .. ".lua", SCRIPTS .. "/prefabs/" .. tostring(prefab) .. ".lua",
        SCRIPTS .. "/brains/" .. tostring(prefab) .. "brain.lua" }
    if mod ~= nil then
        files[#files + 1] = mod .. "/postinit/stategraphs/" .. sgfile .. ".lua"
        files[#files + 1] = mod .. "/postinit/prefabs/" .. tostring(prefab) .. ".lua"
    end
    local with, without = 0, 0
    local pat = 'GoToState%s*%(%s*"' .. statename:gsub("%p", "%%%0") .. '"%s*([,%)])'
    for _, f in ipairs(files) do
        local fh = io.open(f, "rb")
        if fh ~= nil then
            local text = fh:read("*a")
            fh:close()
            for c in text:gmatch(pat) do if c == "," then with = with + 1 else without = without + 1 end end
            if statename == "attack" and text:find("CommonHandlers.OnAttack", 1, true) then with = with + 1 end
            if text:find('ActionHandler%s*%([^)]*"' .. statename:gsub("%p", "%%%0") .. '"') then without = without + 1 end
        end
    end
    local r = without > 0 and with == 0
    NOARG_CACHE[key] = r
    if r and os.getenv("AUTO_NOARG_V") then io.stderr:write(string.format("noarg %s %s %s\n", tostring(prefab), sgfile, statename)) end
    return r
end

local function Run(boss_def, sg, statename, dist, seed, teleport, mem)
    -- (a move from another stategraph it takes on - a pig gone werepig: spec sg)
    if spec_sg ~= nil then sg = spec_sg end
    Reset()
    math.randomseed(seed)
    -- (its target first: a boss looks the players over as it's made)
    local player = NewEntity("player")
    -- (behind: a move made with its back to its target - Armored Bearger's butt slam, leaping back)
    player.x = spec_behind and -dist or dist
    -- (never quite straight ahead, as in the game - the Scrappy Werepig's junk aims at you only
    -- if you're off its line both ways: "dx ~= 0 and dz ~= 0")
    player.z = .001
    -- (side: off to its side, square on - how far one that goes the way it faces goes then)
    if spec_side then player.x, player.z = 0, dist end
    -- (angle: that many degrees round from straight ahead)
    if spec_angle then player.x, player.z = dist * math.cos(spec_angle * DEGREES), -dist * math.sin(spec_angle * DEGREES) end
    Body(player)
    AllPlayers = { player }
    -- (another player standing by, EXTRA_PLAYER: does it go for them too - the Klaus deer's spells,
    -- cast on every player in reach at once)
    sim_extra, extra_attacked = nil, false
    -- (EXTRA_GHOST: nobody there - only the spot looked at after, to tell its own spread apart:
    -- Deerclops' spikes come up round it there anyway)
    local xp, xg = rawget(_G, "EXTRA_PLAYER"), rawget(_G, "EXTRA_GHOST")
    if xp ~= nil and xg then
        sim_extra = { x = xp[1], z = xp[2] }
    elseif xp ~= nil then
        local p2 = NewEntity("player")
        p2.x, p2.z = xp[1], xp[2]
        Body(p2)
        AllPlayers = { player, p2 }
        sim_extra = p2
    end
    -- (sim_hooks: tools/trace_moves.lua listening in - the target made, then the boss)
    if sim_hooks ~= nil and sim_hooks.player ~= nil then sim_hooks.player(player) end

    local boss = SpawnPrefab(boss_def.prefab)
    boss.x, boss.z, boss.rot = 0, 0, 0
    rawset(boss, "is_sim_boss", true)
    snap_rot0, snap_rot2, snap_turn, snap_f0 = nil, nil, nil, 0
    -- (made ready to fight as the game does it - the War Machine starts switched off, its fighting
    -- parts added only once it turns hostile: boss_def.init)
    if boss_def.init ~= nil then
        -- (its parts as they really are meanwhile - not made up on being looked at: its code asks
        -- whether it has a combat yet, and adds one only if not)
        local mt = getmetatable(boss.components)
        setmetatable(boss.components, nil)
        local ok, err = pcall(boss[boss_def.init], boss)
        setmetatable(boss.components, mt)
        if not ok and not init_said then init_said = true io.stderr:write("init " .. boss_def.prefab .. ": " .. tostring(err) .. "\n") end
    end
    -- (one with no body here goes through whoever it's after - said, once: verify.ps1 counts it)
    if boss.radius == nil and not rawget(boss, "flier") and not no_body_said[boss_def.prefab] then
        no_body_said[boss_def.prefab] = true
        io.stderr:write("NO BODY " .. boss_def.prefab .. ": it has no size here - it walks through you\n")
    end
    boss.components.locomotor = boss.components.locomotor or setmetatable({}, PERMISSIVE)
    if rawget(boss.components, "combat") == nil or boss.components.combat.DoAttack == nil then
        boss:AddComponent("combat")
    end
    boss.components.combat.target = player
    things_timers = true
    -- (as it is later on: its own code for that - Klaus enraged, bigger)
    -- (several, one after another: "LevelUp,LevelUp" - a shadow piece at level 3)
        if spec_setup ~= nil then for fn in spec_setup:gmatch("[^,]+") do boss[fn](boss) end end
    -- (fields set on it as a later phase of its fight sets them - the War Machine able to call its
    -- orbital strike: spec fields)
    for k, v in pairs(spec_fields or {}) do rawset(boss, k, v) end
    -- (spec prep: whatever else its brain or timers would have set by then - a function(boss, target) in the
    -- mod's spec: Uncompromising Mode's Deerclops spinning laser reads when it last attacked)
    if spec_prep ~= nil then spec_prep(boss, player) end
    -- (luck: every roll of it won - what comes more rarely: the larger gestalts)
    rawset(_G, "TryLuckRoll", spec_lucky and function() return true end or nil)
    sim_boss, sim_target = boss, player
    target_found_at = nil

    local dummies = Dummies()

    -- the stategraph, run by hand
    local states = {}
    for _, s in ipairs(sg.states) do states[s.name] = s end
    local anims, seen_anims = {}, {}
    local state_anim = {}   -- state -> the first animation it played
    local anim_frame = {}   -- animation -> the frame it first played on
    local anim_looped = {}  -- animation -> played going round (its length up to the code, not itself)
    local anim_pose = {}    -- animation -> where the boss stood, which way it faced, and where its target was then
    local sgi
    boss.on_anim = function(a, looped)
        if looped then anim_looped[a] = true end
        if not seen_anims[a] then
            seen_anims[a] = true
            table.insert(anims, a)
            anim_frame[a] = frame_n
            anim_pose[a] = { x = boss.x, z = boss.z, rot = boss.rot, px = player.x, pz = player.z, frame = frame_n }
        end
        if sgi ~= nil and sgi.entry ~= nil and state_anim[sgi.entry.name] == nil then
            state_anim[sgi.entry.name] = a
        end
    end
    local cur, tl, ti, entered_at
    local tags = {}
    local done = false
    sgi = { statemem = {}, mem = {}, timeinstate = 0 }
    local made_sg = rawget(boss, "sg")
    for k, v in pairs(made_sg ~= nil and made_sg.mem or {}) do sgi.mem[k] = v end
    for k, v in pairs(mem or {}) do sgi.mem[k] = v end
    -- (going into a state again: not a new one)
    function sgi:InNewState() return self.innew == true end
    sgi.lasttags = {}
    function sgi:HasStateTag(t) return tags[t] == true end
    function sgi:HasAnyStateTag(...)
        local l = type((...)) == "table" and (...) or { ... }
        for _, t in ipairs(l) do if tags[t] then return true end end
        return false
    end
    function sgi:AddStateTag(t) tags[t] = true end
    function sgi:RemoveStateTag(t) tags[t] = nil end
    function sgi:SetTimeout(t) self.timeout = now + t end
    function sgi:GetTimeInState() return self.timeinstate end
    -- (how far each state carried it, and how long it lasted: { [name] = { distances } })
    local legs, legs_dur, leg_from = {}, {}, nil
    local spans = {}   -- state -> { { frame it came in, frame it left } }
    function sgi:GoToState(name, data)
        -- (two runs: the states it went through, and when - SIM_TWO_PASS)
        if two_pass_cur ~= nil then table.insert(two_pass_cur.states, { frame_n, tostring(name) }) end
        if cur ~= nil and cur.onexit ~= nil then cur.onexit(boss) end
        if cur ~= nil and leg_from ~= nil then
            local d = math.sqrt((boss.x - leg_from[1]) ^ 2 + (boss.z - leg_from[2]) ^ 2)
            legs[cur.name] = legs[cur.name] or {}
            table.insert(legs[cur.name], d)
            -- (and which way: one turning round to its target before the next - turns)
            legs[cur.name].dirs = legs[cur.name].dirs or {}
            legs[cur.name].dirs[#legs[cur.name]] = math.atan2(-(boss.z - leg_from[2]), boss.x - leg_from[1])
            legs_dur[cur.name] = legs_dur[cur.name] or {}
            table.insert(legs_dur[cur.name], frame_n - leg_from[3])
            spans[cur.name] = spans[cur.name] or {}
            table.insert(spans[cur.name], { leg_from[3], frame_n })
        end
        leg_from = { boss.x, boss.z, frame_n }
        -- (whether it had struck before this state - not what this state strikes as it begins: a
        -- leap's landing, struck in its own onenter, isn't a blow before going on)
        local had_hits = next(hits) ~= nil or #target_hits > 0
        if os.getenv("DBGSTATE") then io.stderr:write(string.format("    [%d] -> %s (%s)\n", frame_n, tostring(name), debug.traceback("", 2):gsub("\n", " | "):sub(1, 300))) end
        local s = states[name]
        -- (back to standing about, or somewhere that isn't this attack: the move is over)
        -- (but "death" itself the move asked for, its first state - Moonmaw's lavae falling, striking
        -- 2 round where they land (SGmoonmaw_lavae "death", frame 11): run, not over before it began)
        if s == nil or name:match("idle") or (name == "death" and not (cur == nil and frame_n == 0)) then
            done = true
            cur = nil
            return
        end
        self.innew = cur ~= s
        self.lasttags = tags
        cur, entered_at, ti = s, now, 1
        self.statemem, self.timeout, self.currentstate = {}, nil, s
        self.entry = { name = name, x = boss.x, z = boss.z, frame = frame_n }
        tags = {}
        for _, t in ipairs(s.tags or {}) do tags[t] = true end
        tl = {}
        for _, ev in ipairs(s.timeline or {}) do table.insert(tl, ev) end
        table.sort(tl, function(a, b) return a.time < b.time end)
        if s.onenter ~= nil then s.onenter(boss, data) end
        -- (gone somewhere else as it began - a teleport (Uncompromising Mode's Shadow Bishop, off round you
        -- before each charge): its leg, and what it strikes, from there - not the jump counted as its way)
        if cur == s and leg_from ~= nil and (boss.x - self.entry.x) ^ 2 + (boss.z - self.entry.z) ^ 2 > 4 then
            leg_from = { boss.x, boss.z, frame_n }
            self.entry.x, self.entry.z = boss.x, boss.z
        end
        -- (which way it faced once it began)
        self.entry.rot = boss.rot
        local a = state_anim[name]
        if a ~= nil and anim_pose[a] ~= nil and anim_pose[a].frame == frame_n then
            anim_pose[a].rot = boss.rot
        end
        -- (on into another of its attacks once it's hit - Klaus' bite, then a swipe if you're still
        -- close: that's a move of its own, shown when it comes; a wind-up going into its slam isn't)
        if name ~= statename and a ~= nil and stop_at_anims ~= nil and stop_at_anims[a] ~= nil and stop_at_anims[a] ~= statename
            and had_hits then
            -- (which: tools/build_tables.lua - where its target stood said which way it went on)
            sim_went_into = name
            -- (and kept for the move: what it goes on into, at which frame, from which frame of that animation, as far as
            -- its target was - Klaus' bite on into its swipe at 49 with you in reach, the swipe begun 15 frames in and
            -- striking a frame on: a player's game sees it as it strikes. Written goes_into; true_range/predict draws it
            -- ahead, VERIFY_PLAN 6.20)
            local at_t = boss.AnimState ~= nil and boss.AnimState:GetCurrentAnimationTime() or 0
            local g = sim_goes_into
            if g == nil or frame_n < g.frame then
                sim_goes_into = { anim = a, frame = frame_n, from = math.floor(at_t / FRAMES + .5), dist = dist or 0 }
            elseif g.anim == a and (dist or 0) > g.dist then
                g.dist = dist
            end
            if two_pass_cur ~= nil then two_pass_cur.stopped = frame_n end
            done = true
            cur = nil
            if anims[#anims] == a then
                table.remove(anims)
                seen_anims[a] = nil
            end
        end
    end
    boss.sg = sgi
    sgi.inst = boss
    -- (what it's handed as it begins: its target, or a table saying more)
    local data = player
    -- (spec_noarg: gone into with nothing handed on - a state that takes a count, not a target)
    if spec_noarg then data = nil end
    -- (or as its own code goes into it: never handed a target there - AutoNoArg; spec noarg = false: handed one)
    if spec_noarg == nil and AutoNoArg(boss_def.prefab, boss_def.sg, statename) then data = nil end
    -- (a list of targets - Klaus' deer casting at each)
    -- (picked as the game picks them, its own code - every player in its reach, when it has one)
    if spec_targets then
        data = { player }
        -- (its own Find...Targets: FindCastTargets (the Klaus deer), FindSnareTargets (the Fuelweaver))
        local fct = nil
        for k, v in pairs(boss) do if type(k) == "string" and k:match("^Find%a*Targets$") and type(v) == "function" then fct = v end end
        if fct ~= nil then
            local ok, list = pcall(fct, boss)
            if ok and type(list) == "table" and #list > 0 then data = list end
        end
    end
    if spec_data == "@target" then
        -- (handed its target itself - the Year of the Horse knight's joust)
        data = player
    elseif spec_data == "@target_pos" then
        -- (handed where its target stands, as itself - the Gnarwail's body slam)
        data = player:GetPosition()
    elseif spec_data ~= nil then
        data = { target = player }
        -- ("@target_pos": where its target stands - handed on by the state before)
        for k, v in pairs(spec_data) do data[k] = v == "@target_pos" and player:GetPosition() or v end
    end
    -- (already on its way as the move begins: going towards its target this fast)
    if teleport ~= nil and teleport.boss_vel ~= nil then
        boss.vel, boss.vel_was = teleport.boss_vel, teleport.boss_vel
    end
    -- (spec lasttags: as if it came from a state with these - the Lurking Nightmare's bite on the move)
    if spec_lasttags ~= nil then for k, v in pairs(spec_lasttags) do tags[k] = v end end
    -- (the weapon its "doattack" takes into this state, in its hands - the one tagged so, or else one not)
    do
        -- (read off its stategraph here, once - not only for the bosses found by AutoBosses)
        SIM_SG_WEAPON = SIM_SG_WEAPON or {}
        if boss_def.sg ~= nil and SIM_SG_WEAPON[boss_def.sg] == nil then
            local wm0 = {}
            local sh = io.open(SCRIPTS .. "/stategraphs/" .. boss_def.sg .. ".lua", "rb")
            local st = sh and sh:read("*a") or ""
            if sh then sh:close() end
            local da = st:match('EventHandler%(%s*"doattack"(.-)EventHandler%(') or st:match('EventHandler%(%s*"doattack"(.-)}%s*\n') or ""
            for tag, yes, no in da:gmatch('HasTag%(%s*"([%w_]+)"%s*%)%s*then(.-)else(.-)end') do
                for t in yes:gmatch('GoToState%(%s*"([%w_]+)"') do wm0[t] = wm0[t] or { tag = tag, has = true } end
                for t in no:gmatch('GoToState%(%s*"([%w_]+)"') do wm0[t] = wm0[t] or { tag = tag, has = false } end
            end
            SIM_SG_WEAPON[boss_def.sg] = wm0
            -- (and a state its "doattack" takes only with its target this far off or more - "not
            -- inst:IsNear(data.target, R) and "warrior_attack" or "attack"": Tropical Experience's slip
            -- leaps only from past 3, its leap begun just as its bite (eat_pre) - drawn over every bite.
            -- SIM_OLD_FAR=1: none)
            SIM_SG_FAR = SIM_SG_FAR or {}
            local far0 = {}
            if os.getenv("SIM_OLD_FAR") == nil then
                for r, t in da:gmatch('not%s+inst:IsNear%(%s*data%.target%s*,%s*([%w_%.]+)%s*%)%s*and%s*"([%w_]+)"') do
                    local f = loadstring("return " .. r)
                    if f ~= nil then setfenv(f, _G) end
                    local ok, v = pcall(f or function() end)
                    if ok and type(v) == "number" then far0[t] = math.min(far0[t] or v, v) end
                end
            end
            SIM_SG_FAR[boss_def.sg] = far0
            -- (and the other way: a state taken only with its target this near - "if inst:IsNear(data.target, R) then
            -- inst.sg:GoToState("attack"...": Tropical Experience's lizardman bites only within 4, spits further - its bite's
            -- reach its combat's, 16 (for its spit): struck here from 16, a dark ring 16.5 round it. SIM_OLD_NEAR=1: none)
            local near0 = {}
            if os.getenv("SIM_OLD_NEAR") == nil then
                for r, t in da:gmatch('if%s+inst:IsNear%(%s*data%.target%s*,%s*([%w_%.]+)%s*%)%s*then%s*inst%.sg:GoToState%(%s*"([%w_]+)"') do
                    local f = loadstring("return " .. r)
                    if f ~= nil then setfenv(f, _G) end
                    local ok, v = pcall(f or function() end)
                    if ok and type(v) == "number" then near0[t] = math.max(near0[t] or v, v) end
                end
            end
            rawset(_G, "SIM_SG_NEAR", rawget(_G, "SIM_SG_NEAR") or {})
            SIM_SG_NEAR[boss_def.sg] = near0
        end
        sim_move_far = boss_def.sg ~= nil and (SIM_SG_FAR or {})[boss_def.sg] ~= nil and SIM_SG_FAR[boss_def.sg][statename] or nil
        rawset(_G, "SIM_MOVE_NEAR", boss_def.sg ~= nil and (rawget(_G, "SIM_SG_NEAR") or {})[boss_def.sg] ~= nil and SIM_SG_NEAR[boss_def.sg][statename] or nil)
        local wm = (SIM_SG_WEAPON[boss_def.sg] or {})[statename]
        local inv = boss.components ~= nil and rawget(boss.components, "inventory") or nil
        if wm ~= nil and inv ~= nil and rawget(inv, "items") ~= nil then
            for _, item in ipairs(inv.items) do
                local is_weapon = item.components ~= nil and rawget(item.components, "weapon") ~= nil
                if is_weapon and (item:HasTag(wm.tag) == wm.has) then inv:Equip(item) break end
            end
        end
    end
    -- (what it set going as it was made, due at once - Uncompromising Mode's bee guards flying in (DoTaskInTime(0) -> spawnin):
    -- long done in the game before it fights - run now, against the stategraph it was made with, not this move's: every move of
    -- the guards "nothing", cut short by their own arrival, 80 of their blows undrawn on the bench, 2026-10-21.
    -- SIM_OLD_SPAWNTASKS=1: as before, run in the move's first frame)
    if os.getenv("SIM_OLD_SPAWNTASKS") == nil and made_sg ~= nil then
        boss.sg = made_sg
        for _, t in ipairs(tasks) do
            if not t.cancelled and t.period == nil and t.args[1] == boss and t.at <= now + 1e-6 then
                t.cancelled = true
                pcall(t.fn, unpack(t.args, 1, t.nargs))
            end
        end
        boss.sg = sgi
    end
    sgi:GoToState(statename, data)

    local pose_at = {}   -- frame -> where the boss stood and faced, and where its target was, once that frame was done
    -- (once the move is done, what it set off goes on - flying, falling, pulsing - for up to
    -- AFTER frames more, the boss itself still)
    local after_until = nil
    for f = 0, MAX_FRAMES + AFTER do
        if done and after_until == nil then after_until = f + AFTER end
        if not done and f > MAX_FRAMES then break end
        -- (spec frames: run no further - all it does is set going by then, what it put down drawn on its own (Uncompromising
        -- Mode's Deerclops freezing: six ice circles there 9 seconds, every frame against 30000 dummies - 4 minutes a run))
        if spec_frames ~= nil and f > spec_frames then break end
        if after_until ~= nil then
            local busy = false
            for _, t in ipairs(tasks) do
                if not t.cancelled and not (t.period ~= nil and t.args[1] == boss) then busy = true break end
            end
            for _, e in ipairs(others) do
                if e ~= boss and e.valid and (e.vel or 0) ~= 0 then busy = true break end
            end
            if f >= after_until or not busy then break end
        end
        -- (spec still: kept where it began - the Skittersquid's spin, a few steps on as it goes,
        -- stopped against you as it does it in the game: drawn sliding on with its run, it stood)
        if spec_still then boss.x, boss.z = 0, 0 end
        if f > 0 then
            pose_at[f - 1] = { x = boss.x, z = boss.z, rot = boss.rot, px = player.x, pz = player.z,
                -- (and what it's at - a trace of the run, replayed through the mod's own drawing)
                state = cur ~= nil and cur.name or nil, anim = boss.anim, anim_t = now - (boss.anim_t or now),
                scale = boss.scale,
                -- (the spot it aims at, as the game's server tells the mod: statemem targetpos, or the
                -- Clockwork Bishop's creeping mark)
                tpos = TposOf(boss) }
        end
        frame_n, now = f, f * FRAMES
        -- (Snaps: which way it faces as it begins, and two frames on)
        if snap_rot0 == nil then snap_rot0, snap_f0 = boss.rot, f end
        if f == snap_f0 + 3 then snap_rot2 = boss.rot end
        -- (and when it first turned well round - to its target square to its side - in what
        -- animation: the Scrappy Werepig only as it begins to throw)
        if f > snap_f0 and snap_turn == nil and math.abs(((boss.rot or 0) - snap_rot0 + 540) % 360 - 180) >= 60 then
            snap_turn = { f - snap_f0, boss.anim }
        end
        -- (and moved before that too: teleport.before = { frame, x, z } - gone behind it after its first
        -- blow, then somewhere else: tools/build_tables.lua Branches)
        if teleport ~= nil and teleport.before ~= nil and f == teleport.before[1] then
            player.x, player.z = teleport.before[2], teleport.before[3]
        end
        if teleport ~= nil and f == teleport.frame then
            player.x, player.z = teleport.x, teleport.z
            -- (far: well out of its reach, straight on the way it faces then)
            if teleport.far then
                player.x = boss.x + math.cos(boss.rot * DEGREES) * 1000
                player.z = boss.z - math.sin(boss.rot * DEGREES) * 1000
            end
            -- (side: square off to its side, this far, as it is then)
            -- (ahead too: that far on the way it faces)
            if teleport.side ~= nil then
                local ahead = teleport.ahead or 0
                player.x = boss.x + math.sin(boss.rot * DEGREES) * teleport.side + math.cos(boss.rot * DEGREES) * ahead
                player.z = boss.z + math.cos(boss.rot * DEGREES) * teleport.side - math.sin(boss.rot * DEGREES) * ahead
            end
        end
        -- (its target walking along all the while: { x, z } a second)
        if teleport ~= nil and teleport.turn ~= nil and f == teleport.turn[1] then
            teleport.walk = { teleport.turn[2], teleport.turn[3] }
        end
        -- (and one way after another: { { frame, x, z }, ... } - wandering about)
        for _, tn in ipairs(teleport ~= nil and teleport.turns or {}) do
            if f == tn[1] then teleport.walk = { tn[2], tn[3] } end
        end
        if teleport ~= nil and teleport.walk ~= nil and f > 0 then
            local nx = player.x + teleport.walk[1] * FRAMES
            local nz = player.z + teleport.walk[2] * FRAMES
            -- (not through the boss's body - unless it's a small flier, over you)
            local reach = (boss.radius or 0) + (player.radius or .5)
            local d2 = (nx - boss.x) ^ 2 + (nz - boss.z) ^ 2
            if rawget(boss, "flier") or boss.radius == nil or d2 >= reach * reach
                or d2 >= (player.x - boss.x) ^ 2 + (player.z - boss.z) ^ 2 then
                player.x, player.z = nx, nz
            end
        end
        -- (things it set off: their animations end, and on - "animover" to whoever listens)
        for _, e in ipairs(others) do
            if e ~= boss and e.valid and e.anim ~= nil and not e.anim_done and rawget(e, "listeners") ~= nil
                and now - e.anim_t >= AnimLen(e, e.anim) - 1e-6 then
                if #e.anim_queue > 0 then
                    local nxt = table.remove(e.anim_queue, 1)
                    e.anim, e.anim_t, e.anim_loop = nxt[1], now, nxt[2]
                elseif e.anim_loop then
                    e.anim_t = now
                else
                    e.anim_done = true
                end
                e:PushEvent("animover")
            end
        end
        if cur ~= nil then
            local s = cur
            sgi.timeinstate = now - entered_at
            -- (as the game's own UpdateState: its time up first - then its timeline, then onupdate;
            -- the other way round, Frostjaw's torpedo struck once more on its last frame, a frame on)
            if sgi.timeout ~= nil and now >= sgi.timeout - .0001 then
                sgi.timeout = nil
                if s.ontimeout ~= nil then s.ontimeout(boss) end
            end
            while cur == s and tl[ti] ~= nil and tl[ti].time <= sgi.timeinstate + 1e-6 do
                ti = ti + 1
                sim_in_timeline = boss
                tl[ti - 1].fn(boss)
                sim_in_timeline = nil
            end
            if cur == s and s.onupdate ~= nil then s.onupdate(boss, TICK) end
            -- (its animation's clock held or slowed - SetDeltaTimeMultiplier: its start moved on by what didn't play)
            local am = rawget(boss, "anim_mult")
            if am ~= nil and am ~= 1 and boss.anim_t ~= nil then boss.anim_t = boss.anim_t + TICK * (1 - am) end
            -- (its animation is over: the next queued one plays, or it loops, or it's done -
            -- "animover" each time, "animqueueover" when nothing's left)
            if cur == s and boss.anim ~= nil and not boss.anim_done
                and now - boss.anim_t >= AnimLen(boss, boss.anim) - 1e-6 then
                local fire = { "animover" }
                if #boss.anim_queue > 0 then
                    local nxt = table.remove(boss.anim_queue, 1)
                    boss.anim, boss.anim_t, boss.anim_loop = nxt[1], now, nxt[2]
                elseif boss.anim_loop then
                    boss.anim_t = now
                else
                    boss.anim_done = true
                    table.insert(fire, "animqueueover")
                end
                for _, name in ipairs(fire) do
                    for _, ev in ipairs(s.events or {}) do
                        if cur == s and ev.name == name then
                            ev.fn(boss)
                        end
                    end
                end
            end
        end
        -- (-ends: whom its code has struck this go forgotten every frame - the Scrappy Werepig's
        -- tackle strikes all round it frame after frame but each one once (statemem.targets): so
        -- each spot is struck again for as long as it's in reach, and when it's out of reach is
        -- known - not only the crescent where it first came into reach)
        if sim_rehit and sgi ~= nil and type(sgi.statemem) == "table" then
            for _, v in pairs(sgi.statemem) do
                if type(v) == "table" then
                    for k in pairs(v) do
                        if type(k) == "table" and rawget(k, "is_dummy") then
                            v[k] = nil
                        end
                    end
                end
            end
        end
        -- (after its stategraph, as the game: its code strikes from where it is, then the physics
        -- moves it - traced, a dive's first tick already on its way at its new speed; the other way,
        -- Frostjaw's torpedo struck a frame further on than it does)
        -- things move
        for _, e in ipairs(others) do
            -- (a speed set takes hold the next tick - but not quite all of it: traced tick by tick
            -- in the game, the tick after a change goes 75-95% of the way from the old speed to
            -- the new (it varies from one go to the next); PHYSICS_LAG: the middle of that)
            local vel = e.vel * (1 - physics_lag) + (e.vel_was or e.vel) * physics_lag
            if DBG and e == boss and (frame_n % 5 == 0 or os.getenv("SIMDBG1")) then io.stderr:write(string.format("f%d state=%s anim=%s vel=%.2f x=%.2f rot=%.1f\n", frame_n, tostring(boss.sg and boss.sg.currentstate and boss.sg.currentstate.name), tostring(e.anim), e.vel, e.x, e.rot)) end
            e.vel_was = e.vel
            -- (up and down by its motor: a missile circling up, then diving)
            local vy = rawget(e, "vy")
            if vy ~= nil and vy ~= 0 and e.valid then rawset(e, "y", (rawget(e, "y") or 0) + vy * FRAMES) end
            if (rawget(e, "y") or 0) > 1 and e ~= boss then rawset(e, "was_up", true) end
            if vel ~= 0 and e.valid and not (done and e == boss) then
                if not e.moved then e.x0, e.z0, e.rot0 = e.x, e.z, e.rot end -- (where it set off from, which way)
                e.moved = true
                -- (how far it went bumping into rocks and walls as it goes - not leaping over them)
                if e == boss then
                    table.insert(boss_move_log, { frame_n, math.abs(vel) * FRAMES, e.through or e.tags.flying or rawget(e, "flier"),
                        not (e.tags.flying or rawget(e, "flier")) })
                end
                local r = e.rot * DEGREES
                -- (its motor speed is in its own scaled frame: a thing drawn 1.68 times as big goes
                -- 1.68 times as far - seen in the game, Klaus enraged leaping 15 for a 9)
                local v = vel * (e.scale or 1)
                local nx, nz = e.x + v * FRAMES * math.cos(r), e.z - v * FRAMES * math.sin(r)
                -- (the boss bumps into whoever it's after - it can't go through them, and doesn't
                -- shove them on (seen in the game: the Werepig's slam landing short, stopped at
                -- you) - unless it flies; a charge goes on into them - hitting them ends it, the
                -- game's own way)
                local blocked = false
                if e == boss and e.radius ~= nil and not e.tags.flying and not rawget(e, "flier") and not tags.charge and COLLIDE and not e.nocollide then
                    local reach = e.radius + player.radius
                    local before = (e.x - player.x) ^ 2 + (e.z - player.z) ^ 2
                    local after = (nx - player.x) ^ 2 + (nz - player.z) ^ 2
                    blocked = after < reach * reach and after < before
                    if blocked and before > reach * reach then
                        -- (on up to them, and no further: where along the way it's `reach` off)
                        local mx, mz = nx - e.x, nz - e.z
                        local fx, fz = e.x - player.x, e.z - player.z
                        local a, b, cc = mx * mx + mz * mz, 2 * (fx * mx + fz * mz), fx * fx + fz * fz - reach * reach
                        local disc = b * b - 4 * a * cc
                        if a > 0 and disc >= 0 then
                            local k = (-b - math.sqrt(disc)) / (2 * a)
                            if k > 0 and k < 1 then
                                e.x, e.z = e.x + mx * k, e.z + mz * k
                            end
                        end
                    end
                end
                if not blocked then
                    e.x, e.z = nx, nz
                end
            end
        end
        -- (two runs: where each was, kept - or put back where the run without dummies had it)
        if two_pass_cur ~= nil then TwoPassFrame(boss, player, f) end
        -- (things it set off: when they last turned before setting off - a gestalt faces its
        -- way only as it rises; drawn before, it would point wrong)
        for _, e in ipairs(others) do
            -- (and where it was first seen - one carried off by its own code, not its motor: junk falling)
            if e ~= boss and e ~= player and e.first_x == nil then e.first_x, e.first_z = e.x, e.z end
            if e ~= boss and e ~= player and not e.moved then
                if e.seen_rot ~= nil and e.rot ~= e.seen_rot then e.rot_at = frame_n end
                e.seen_rot = e.rot
            end
        end
        -- tasks due
        -- (one whose owner is gone is let go too - never run again, and kept it grew to thousands
        -- sorted every frame: the Celestial Champion's lasers took minutes)
        local due, gone = {}, false
        for i = #tasks, 1, -1 do
            local t = tasks[i]
            if t.cancelled or (done and t.period ~= nil and t.args[1] == boss)
                or (t.args[1] ~= nil and t.args[1].valid == false) then
                t.drop, gone = true, true
            elseif t.at <= now + 1e-6 then
                table.insert(due, t)
                -- (period 0: every tick, as the game runs it - a deer's fire circle burning on)
                if t.period ~= nil then t.at = t.at + math.max(t.period, FRAMES) else t.drop, gone = true, true end
            end
        end
        if gone then
            local keep = {}
            for _, t in ipairs(tasks) do if not t.drop then keep[#keep + 1] = t end end
            tasks = keep
        end
        table.sort(due, function(a, b) return a.at < b.at end)
        -- (one cancelled by another due the same frame runs all the same: the game runs a frame's
        -- in no set order (pairs) - a gestalt's last strike, due as it stops, came first in the
        -- game, never offline: its way drawn a step short)
        for _, t in ipairs(due) do
            if (t.args[1] == nil or t.args[1].valid ~= false) then
                acting = t.args[1]
                local ok, err = pcall(t.fn, unpack(t.args, 1, t.nargs or #t.args))
                acting = nil
                if not ok then io.stderr:write("task: " .. tostring(err) .. "\n") end
            end
        end
    end
    -- (the last state's way)
    if cur ~= nil and leg_from ~= nil then
        legs[cur.name] = legs[cur.name] or {}
        table.insert(legs[cur.name], math.sqrt((boss.x - leg_from[1]) ^ 2 + (boss.z - leg_from[2]) ^ 2))
        legs[cur.name].dirs = legs[cur.name].dirs or {}
        legs[cur.name].dirs[#legs[cur.name]] = math.atan2(-(boss.z - leg_from[2]), boss.x - leg_from[1])
    end
    -- hits apart: the boss's own (by it, or its code), and those of things it set off - seen
    -- from that thing (where it was, which way it faced), by its name
    -- (and when: frames after that thing's first hit; how long after it appeared that came, and
    -- whether it moved on the way - a spike trail runs out, then raises its wall spike by spike)
    Shared()
    -- (a hit the boss's code made where something it set off stands - an ice spike: that
    -- thing's too, seen from it)
    for _, h in pairs(hits) do
        if (h.by == nil or h.by == boss) and h.q ~= nil and h.q.ent ~= nil then
            local e = h.q.ent
            h.by, h.bx, h.bz, h.brot, h.also_own = e, e.x, e.z, e.rot, true
        end
    end
    -- (how it went, up to its last strike - not swimming off after: bumping into rocks or over them)
    local last_own = nil
    for _, h in pairs(hits) do
        if h.by == nil or h.by == boss then last_own = math.max(last_own or 0, h.frame) end
    end
    for _, m in ipairs(boss_move_log) do
        if last_own ~= nil and m[1] <= last_own then
            if m[3] then boss_through = boss_through + m[2] else boss_solid = boss_solid + m[2] end
            if m[4] then boss_ground_went = boss_ground_went + m[2] end
        end
    end
    local own, things, first_of = {}, {}, {}
    local spread = {}   -- hits of things set off that stay put (crystals, spikes), seen from the boss
    -- (a thing that harms: what it only shoved (or such) isn't where it strikes - the Scrappy
    -- Werepig's junk forming its pile knocks back all its throw struck, wherever they are; its
    -- reach came out 5.6 for 2. One that only freezes - a deer's circle - is all such)
    local harms = {}
    for _, h in pairs(hits) do
        if h.by ~= nil and h.by ~= boss and (h.kinds == nil or h.kinds.harm) then harms[h.by] = true end
    end
    for d, h in pairs(hits) do
        if h.by ~= nil and h.by ~= boss and harms[h.by] and h.kinds ~= nil and not h.kinds.harm then hits[d] = nil end
    end
    for _, h in pairs(hits) do
        if h.by ~= nil and h.by ~= boss then
            first_of[h.by] = math.min(first_of[h.by] or h.frame, h.frame)
        end
    end
    for d, h in pairs(hits) do
        -- (all: what it throws strikes too, as part of the move - Scrappy Werepig's junk falling round you)
        -- (things_apart: a blow its code makes where a thing of its stands is that thing's alone, drawn with it - not the
        -- move's too: the Celestial Champion's spike walls at the ends of trails run out every way at random, all of them
        -- drawn round it as it began its stab, a great blob that told nothing, the player's report 2026-10-20)
        if h.by == nil or h.by == boss or (h.also_own and not spec_apart) or spec_allhits then
            own[d] = h
        end
        if h.by ~= nil and h.by ~= boss then
            local c, s = math.cos(h.brot * DEGREES), math.sin(h.brot * DEGREES)
            local dx, dz = d.x - h.bx, d.z - h.bz
            local list = things[h.by.prefab] or {}
            things[h.by.prefab] = list
            local f0 = first_of[h.by]
            local by = h.by
            -- (DBG_PULSES=1: each cell's blows again after its first - offsets, frames - and whether it's
            -- drawn lasting; a dry run before the data says them)
            local poffs = {}
            for _, p in ipairs(h.pulses or {}) do poffs[#poffs + 1] = p - h.frame end
            if os.getenv("DBG_PULSES") then
                local lasting = (h.last ~= nil and h.last[1] - h.frame >= 20) or (not by.moved and thing_queries[by] ~= nil and thing_queries[by].last - h.frame >= 20)
                local k = string.format("%s %s offs=%s lasting=%s", boss.prefab or "?", by.prefab or "?", #poffs > 0 and table.concat(poffs, ",") or "-", tostring(lasting))
                pulse_sum[k] = (pulse_sum[k] or 0) + 1
            end
            table.insert(list, { dx * c - dz * s, dx * s + dz * c, rel = h.frame - f0, pulses = poffs,
                -- (its blows put down to the boss, and how old it is at its last - credit_boss, also_own)
                as_boss = (h.credit_boss or h.also_own) and true or nil,
                last_age = (h.last ~= nil and h.last[1] or h.frame) - (by.born or 0),
                delay = f0 - (by.born or 0), moved = by.moved == true, own = h.also_own == true,
                -- (struck on and on, a long while - a snare pulsing)
                lasting = (h.last ~= nil and h.last[1] - h.frame >= 20)
                    or (not by.moved and thing_queries[by] ~= nil and thing_queries[by].last - h.frame >= 20),
                kinds = h.kinds or { harm = true },
                burst = rawget(by, "burst") == true or nil,
                -- (how big it's drawn: a pound's ring is scaled to its reach)
                scale = rawget(by, "scale"),
                -- (how far it had run when it hit)
                travel = by.x0 ~= nil and math.sqrt((h.bx - by.x0) ^ 2 + (h.bz - by.z0) ^ 2) or nil,
                -- (carried off by its own code before it hit, straight on: frames from when it appeared -
                -- where it comes down is where it's going by then)
                glide = (not by.moved and by.first_x ~= nil and (h.bx - by.first_x) ^ 2 + (h.bz - by.first_z) ^ 2 > .25)
                    and f0 - (by.born or 0) or nil })
            -- (only what the boss set off itself - not what that left behind in turn: a crystal's
            -- snare is its own)
            if not by.moved and not h.also_own and (by.spawned_by == nil or by.spawned_by == boss) then
                spread[d] = h
            end
        end
    end
    -- (things that flew, looking round as they went: where they looked, seen from where they set
    -- off and the way they faced then)
    local fly_first = {}
    for _, q in ipairs(fly_queries) do
        fly_first[q.by] = math.min(fly_first[q.by] or q.frame, q.frame)
    end
    for _, q in ipairs(fly_queries) do
        local by = q.by
        if by.x0 ~= nil and FlyHarms(by.prefab) then
            local c, s = math.cos((by.rot0 or 0) * DEGREES), math.sin((by.rot0 or 0) * DEGREES)
            local list = things[by.prefab] or {}
            things[by.prefab] = list
            -- (what it looked for: things within its search of its middle - their bodies don't count,
            -- a gestalt goes by the middle (traced: within some 1.4 of it, not 1.9))
            local r = q.r + PAD
            for gx = q.x - r, q.x + r, STEP do
                for gz = q.z - r, q.z + r, STEP do
                    local kx, kz = math.floor(gx / STEP + .5) * STEP, math.floor(gz / STEP + .5) * STEP
                    if (kx - q.x) ^ 2 + (kz - q.z) ^ 2 <= r * r then
                        local dx, dz = kx - by.x0, kz - by.z0
                        table.insert(list, { dx * c - dz * s, dx * s + dz * c, rel = q.frame - fly_first[by],
                            delay = fly_first[by] - (by.born or 0), moved = false, flies = true,
                            as_boss = rawget(by, "throw_as_boss") or nil, last_age = q.frame - (by.born or 0),
                            aim = (by.rot_at or by.born or 0) - (by.born or 0) })
                    end
                end
            end
        end
    end
    -- (a strike on its target that its area strike gave it with the rest, that same moment - the
    -- Eye of Terror's charge: in its cells already; a disc round where the target was on top,
    -- drawn round you as you ran)
    -- (not one beside a miss's area round itself, ours (miss_area): that's no area of the strike's -
    -- taken so, Uncompromising Mode's Ancient Fuelweaver's swipe lost its reach, 4.3 round it, drawn
    -- 2.1: struck 2.3 to 4.0 off, 543 of 553 missed on the testbench; VERIFY_PLAN 6.0a; SIM_OLD_AREA=1: as before)
    local only_on_target = {}
    for _, th in ipairs(target_hits) do
        local with_area = false
        for d, h in pairs(own) do
            if d ~= sim_target and d.dummy ~= sim_target and math.abs(h.frame - th.frame) <= 1
                and (not h.miss_area or os.getenv("SIM_OLD_AREA")) then with_area = true break end
        end
        if not with_area or os.getenv("SIM_KEEPDISC") then only_on_target[#only_on_target + 1] = th end
    end
    target_hits = only_on_target
    -- (something it set off come down on the other player, EXTRA_PLAYER)
    local extra_put = false
    if sim_extra ~= nil then
        for _, e in ipairs(others) do
            if e ~= boss and e ~= sim_extra and e ~= player and rawget(e, "spawn_frame") ~= nil
                and (e.x - sim_extra.x) ^ 2 + (e.z - sim_extra.z) ^ 2 < 1.5 * 1.5 then
                local th, guard = e, 0
                while th.spawned_by ~= nil and th.spawned_by ~= boss and guard < 8 do th, guard = th.spawned_by, guard + 1 end
                if (th.spawned_by == boss or th.spawned_by == nil) and e.prefab ~= "world" then extra_put = true end
            end
        end
        -- (struck there anyway, nobody standing there - a dummy on that spot struck: its own
        -- reach, not going for whoever stands there)
        for d in pairs(hits) do
            if d.x ~= nil and (d.x - sim_extra.x) ^ 2 + (d.z - sim_extra.z) ^ 2 < 1 then extra_put = true end
        end
        if extra_attacked then extra_put = true end
    end
    -- (whether it struck anyone itself, not only through what it set off - the Celestial Champion's
    -- crystals: all its move's strikes are theirs)
    local boss_struck = #target_hits > 0
    for _, h in pairs(own) do if h.by == nil or h.by == boss then boss_struck = true end end
    return {
        boss_struck = boss_struck,
        -- (whether it ended by itself - not cut at MAX_FRAMES, a loop that goes on while its target lives)
        done = done,
        extra_put = extra_put,
        all_hits = hits,  -- (every blow, each dummy struck -> by whom, when: tools/trace_moves.lua)
        own = own, anims = anims, target_hit = target_hit, things = things, legs = legs, legs_dur = legs_dur,
        state_anim = state_anim, anim_frame = anim_frame, anim_looped = anim_looped, target_hits = target_hits, player_hits = player_hits, own_hits = own_hits, boss_timers = boss_timers, spread = spread,
        bank = boss.bank, end_x = boss.x, end_z = boss.z, scale = boss.scale, radius = boss.radius, anim_pose = anim_pose, spans = spans, pose_at = pose_at,
        shot = rawget(_G, "SIM_SHOT"),
    }
end

-- Two runs (SIM_TWO_PASS=prefab,prefab or all): the dummies stood all round to see where a move
-- strikes are things it can strike - struck, its own code goes on otherwise (a gestalt stops at its
-- first, the Scion passes over whom it struck, a dropkick lands on the first in its way). So: run
-- once with no dummies, its target alone - how it really goes: where it, its target and everything
-- it set off were, frame by frame, the states it went through; then again with the dummies, every
-- one of those put back each frame where the first run had it. The dummies see the move as it
-- really goes, and can't change it. The second not the same as the first - another state, at
-- another frame, a thing made or gone at another frame: the dummies changed its code's way, not
-- only where it is - the run as before, said (TWOPASS FALLBACK).
two_pass_mode, two_pass_rec, two_pass_cur = nil, nil, nil
acting_seen = setmetatable({}, { __mode = "k" })
function TwoPassFrame(boss, player, f)
    local cur = two_pass_cur
    -- (each by its kind and how many of that kind came before it - the same in both runs)
    for _, e in ipairs(others) do
        if cur.key[e] == nil then
            local k
            if e == boss then k = "boss" elseif e == player then k = "player"
            else
                local p = tostring(e.prefab)
                cur.count[p] = (cur.count[p] or 0) + 1
                k = p .. "#" .. cur.count[p]
            end
            cur.key[e] = k
            cur.born[k] = f
        end
    end
    for _, e in ipairs(others) do
        local k = cur.key[e]
        if not e.valid and cur.gone[k] == nil then cur.gone[k] = f end
        -- (one that looks round itself for whom to strike - not a trail's fx, its life a random roll
        -- the dummies' own hits drew ahead of it: those alone are compared)
        if thing_queries[e] ~= nil or acting_seen[e] then cur.active[k] = true end
        if two_pass_mode == "record" then
            cur.pos[k] = cur.pos[k] or {}
            cur.pos[k][f] = { e.x, e.z, e.rot }
        -- (the boss once it stopped by its own rule - the first went on into its next move: left where it stopped)
        elseif two_pass_mode == "replay" and e.valid and not (k == "boss" and cur.stopped ~= nil) then
            local r = two_pass_rec.pos[k] and two_pass_rec.pos[k][f] or nil
            if r ~= nil then
                local d = math.sqrt((e.x - r[1]) ^ 2 + (e.z - r[2]) ^ 2)
                if d > cur.maxdev then cur.maxdev, cur.maxdev_at = d, k .. "@" .. f end
                e.x, e.z, e.rot = r[1], r[2], r[3]
            end
        end
    end
end
function TwoPassNew() return { states = {}, pos = {}, key = setmetatable({}, { __mode = "k" }), count = {}, born = {}, gone = {}, active = {}, maxdev = 0 } end
-- (whether the second went as the first: why not, if not)
function TwoPassSame(a, b)
    -- (the second stopped by its own rule - on into another of its moves once it had struck: the
    -- first, striking no one, went on; the same as far as the second went is the same)
    local n = #a.states
    if b.stopped ~= nil and #b.states <= n then n = #b.states
    elseif #a.states ~= #b.states then return false, string.format("%d states, then %d", #a.states, #b.states) end
    for i = 1, n do
        local s = a.states[i]
        local t = b.states[i]
        if s[1] ~= t[1] or s[2] ~= t[2] then return false, string.format("state %d: %s@%d, then %s@%d", i, s[2], s[1], t[2], t[1]) end
    end
    for k, f in pairs(a.born) do
        -- (made after the second stopped: not one it would have made)
        -- (nor fx that strikes no one, in either)
        if not (a.active[k] or b.active[k]) or k == "player" then
        elseif b.stopped ~= nil and f > b.stopped then
        elseif b.born[k] ~= f then return false, string.format("%s made at %s, then %s", k, tostring(f), tostring(b.born[k])) end
        if a.gone[k] ~= b.gone[k] and not (b.stopped ~= nil and math.min(a.gone[k] or math.huge, b.gone[k] or math.huge) > b.stopped) then
            return false, string.format("%s gone at %s, then %s", k, tostring(a.gone[k]), tostring(b.gone[k]))
        end
    end
    for k in pairs(b.born) do
        if a.born[k] == nil and b.active[k] then return false, k .. " made only with the dummies" end
    end
    return true
end
two_pass_said = {}
function TwoPassRun(def, sg, statename, dist, seed, teleport, mem)
    local no_dummies = NO_DUMMIES
    two_pass_mode, two_pass_cur = "record", TwoPassNew()
    NO_DUMMIES = true
    local ok, res = pcall(Run, def, sg, statename, dist, seed, teleport, mem)
    local rec = two_pass_cur
    NO_DUMMIES = no_dummies
    if ok then
        two_pass_mode, two_pass_rec, two_pass_cur = "replay", rec, TwoPassNew()
        ok, res = pcall(Run, def, sg, statename, dist, seed, teleport, mem)
        local same, why = false, "it failed"
        if ok then same, why = TwoPassSame(rec, two_pass_cur) end
        local dev, dev_at = two_pass_cur.maxdev, two_pass_cur.maxdev_at
        two_pass_mode, two_pass_rec, two_pass_cur = nil, nil, nil
        if os.getenv("SIM_TWO_PASS_DBG") then io.stderr:write(string.format("TWOPASS %s %s dist %s seed %d: %s; moved back at most %.2f (%s)\n", def.prefab, statename, tostring(dist), seed, same and "same" or ("NOT " .. tostring(why)), dev, tostring(dev_at))) end
        if ok and same then
            res.two_pass = { maxdev = dev, at = dev_at }
            return res
        end
        local said = def.prefab .. " " .. statename
        if not two_pass_said[said] then
            two_pass_said[said] = true
            io.stderr:write(string.format("TWOPASS FALLBACK %s dist %s: %s\n", said, tostring(dist), why))
        end
    end
    two_pass_mode, two_pass_rec, two_pass_cur = nil, nil, nil
    return Run(def, sg, statename, dist, seed, teleport, mem)
end
-- (which bosses: SIM_TWO_PASS=all or a list)
function TwoPassFor(prefab)
    local v = os.getenv("SIM_TWO_PASS")
    if v == nil or v == "" then return false end
    if v == "all" then return true end
    for p in v:gmatch("[^,]+") do if p == prefab then return true end end
    return false
end

-- The animations of a stategraph's moving / running / standing-about states (read from the file:
-- PlayAnimation in each state with such a tag): a move starting with one of these can't be told
-- from just getting about.
local function GettingAbout(sgfile)
    local f = io.open(SCRIPTS .. "/stategraphs/" .. sgfile .. ".lua", "rb")
    if f == nil then return {} end
    local text = f:read("*a")
    f:close()
    local about = {}
    local starts = {}
    for pos in text:gmatch("()State%s*{") do table.insert(starts, pos) end
    for i, pos in ipairs(starts) do
        local block = text:sub(pos, (starts[i + 1] or #text + 1) - 1)
        local tags = block:match("tags%s*=%s*(%b{})") or ""
        -- (not one that's a move all the same - tagged charge, attack or ability: the Rabbit King's
        -- dropkick, "moving" and "running" as it flies at you, struck in its first animation)
        local a_move = tags:find('"charge"', 1, true) or tags:find('"attack"', 1, true) or tags:find('"ability"', 1, true)
        if not a_move and (tags:find('"moving"', 1, true) or tags:find('"running"', 1, true) or tags:find('"idle"', 1, true)) then
            for a in block:gmatch('PlayAnimation%(%s*"([^"]+)"') do about[a] = true end
        end
    end
    -- (walking and running made by the game's common states: their usual animations, or the
    -- ones named in the call)
    if text:find("AddRunStates", 1, true) or text:find("AddWalkStates", 1, true) or text:find("AddIdle", 1, true) then
        for _, a in ipairs({ "run_pre", "run_loop", "run_pst", "walk_pre", "walk_loop", "walk_pst", "idle", "idle_loop" }) do
            about[a] = true
        end
        for _, key in ipairs({ "startrun", "run", "stoprun", "startwalk", "walk", "stopwalk" }) do
            for a in text:gmatch(key .. '%s*=%s*"([^"]+)"') do about[a] = true end
        end
    end
    return about
end

--------------------------------------------------------------------------------
-- all of them

-- (a cell as one number - a string made for every cell looked at was a fifth of all the time)
local KOFF, KM = 10000, 100000
local function Key(gx, gz) return (math.floor(gx / STEP + .5) + KOFF) * KM + math.floor(gz / STEP + .5) + KOFF end
local function KeyXZ(k) return math.floor(k / KM) - KOFF, k % KM - KOFF end

-- the cells within the map, by row (sideways) then column (ahead), each sorted:
-- { { row, { col, ... } }, ... }
local function ByRow(cells)
    local nrows = math.floor(2 * sim_pack.side / STEP)
    local ncols = math.floor((sim_pack.ahead[2] - sim_pack.ahead[1]) / STEP)
    local row0, col0 = math.floor(-sim_pack.side / STEP + .5), math.floor(sim_pack.ahead[1] / STEP + .5)
    local rows, list = {}, {}
    for k in pairs(cells) do
        local ix, iz = KeyXZ(k)
        local row, col = iz - row0, ix - col0
        if row >= 0 and row <= nrows and col >= 0 and col <= ncols then
            local r = rows[row]
            if r == nil then r = {} rows[row] = r table.insert(list, row) end
            table.insert(r, col)
        end
    end
    table.sort(list)
    local out = {}
    for _, row in ipairs(list) do
        table.sort(rows[row])
        table.insert(out, { row, rows[row] })
    end
    return out
end
local function RunsOf(cols)
    local runs, i = {}, 1
    while i <= #cols do
        local s, e = cols[i], cols[i]
        while cols[i + 1] == e + 1 do i = i + 1 e = cols[i] end
        table.insert(runs, { s, e })
        i = i + 1
    end
    return runs
end

-- cells as rows of runs: "row:from-to,from-to;..." (row 0 at side -SIDE, column 0 at ahead AHEAD[1])
local function Rows(cells)
    local rows = {}
    local count = 0
    for _, rc in ipairs(ByRow(cells)) do
        local runs = {}
        for _, r in ipairs(RunsOf(rc[2])) do
            table.insert(runs, r[1] .. "-" .. r[2])
            count = count + r[2] - r[1] + 1
        end
        table.insert(rows, rc[1] .. ":" .. table.concat(runs, ","))
    end
    return table.concat(rows, ";"), count
end

-- The same cells, packed (what goes in the file): each row that has any, as numbers - how many
-- rows on from the last one, how many runs, then each run's start (on from the last run's end)
-- and length - each number in 5-bit pieces, one character of B64 apiece (32 added: more to come).
local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"
local function Num(out, v)
    repeat
        local piece = v % 32
        v = math.floor(v / 32)
        if v > 0 then piece = piece + 32 end
        table.insert(out, B64:sub(piece + 1, piece + 1))
    until v == 0
end
local function Pack(cells)
    local out = {}
    local last_row = -1
    for _, rc in ipairs(ByRow(cells)) do
        local row, runs = rc[1], RunsOf(rc[2])
        do
            Num(out, row - last_row)
            Num(out, #runs)
            local last_end = -1
            for _, r in ipairs(runs) do
                Num(out, r[1] - last_end - 1)
                Num(out, r[2] - r[1])
                last_end = r[2]
            end
            last_row = row
        end
    end
    return table.concat(out)
end

local function Show(title, cells, dist)
    print(title)
    for gz = -12, 12, 1 do
        local line = {}
        for gx = -8, 22, 1 do
            local ch = cells[Key(gx, gz)] and "X" or "."
            if gx == 0 and gz == 0 then ch = "B" elseif dist ~= nil and gx == dist and gz == 0 then ch = "P" end
            table.insert(line, ch)
        end
        print(table.concat(line))
    end
end

-- (when: and when, for telling a move random only - one striking the same cells at a frame picked at random,
-- Bearger's butt slam at 40 or 56, was taken for not random: one run, its frame a toss-up from one distance
-- to the next, its colours flashing as you walked - tools/map_steps_check.lua, 2026-10-18. SIM_OLD_SEED: as
-- before. Not for the rest: their keys are read back as places (KeyXZ) - bishop broke)
local function HitKeys(own, when)
    local keys = {}
    when = when and os.getenv("SIM_OLD_SEED") == nil
    -- (a number, as Key makes it, unless the frame's added - `.. ""` made every key a string, and Rotated's
    -- number keys never matched: every turn test "turned 0", 35 moves read as facing - the miscfalse agent,
    -- 2026-10-19. SIM_OLD_HITKEY: as that was)
    for d, h in pairs(own) do
        local k = Key(d.x, d.z)
        if when then k = k .. ":" .. tostring(type(h) == "table" and h.frame or "")
        elseif os.getenv("SIM_OLD_HITKEY") then k = k .. "" end
        keys[k] = true
    end
    return keys
end

local function Same(a, b)
    for k in pairs(a) do if not b[k] then return false end end
    for k in pairs(b) do if not a[k] then return false end end
    return true
end

-- From which frame on it no longer cares where its target is: its target jumps 4 to the side at
-- that frame, and what it hits stays the same (nil: it keeps following its target)
local LOCK_DIST, LOCK_SIDE, LOCK_STEP = 8, 4, 3

-- where a run hit: its own hits, and - an attack on its target only - where it was when it bit
local function MoveKeys(res)
    -- (not whether its target was hit on the way: a target jumped off the path isn't hit, though
    -- the path is the same - the Malbatross' swoop went on looking "aimed" long after it set off)
    local keys = HitKeys(res.own)
    -- (and where what it set off struck - sinkholes on a line to you, spikes called up under you: when
    -- those stop following you is when it stops aiming too, its own blow round itself the same either way;
    -- left out, Uncompromising Mode's Bearger was drawn aimed the way it faced from its first frame)
    for k in pairs(HitKeys(res.spread or {})) do keys[k] = true end
    if next(res.own) == nil and next(res.spread or {}) == nil then
        keys = { ["end:" .. Key(math.floor(res.end_x + .5), math.floor(res.end_z + .5))] = true }
    end
    return keys
end

-- (bodies bumping off: on - but not when telling when it stops aiming, or which way it lays its
-- attack out: there it'd tell where its target is all the way)
COLLIDE = true

local function LockFrame(def, sg, statename, last, mem)
    COLLIDE = false
    local lock = nil
    local ok, base = pcall(Run, def, sg, statename, LOCK_DIST, 1, nil, mem)
    if ok then
        local keys = MoveKeys(base)
        if next(keys) ~= nil then
            for f = last, 0, -LOCK_STEP do
                local ok2, moved = pcall(Run, def, sg, statename, LOCK_DIST, 1, { frame = f, x = LOCK_DIST, z = LOCK_SIDE }, mem)
                if not ok2 or not Same(keys, MoveKeys(moved)) then break end
                lock = f
            end
            -- (then frame by frame, back to the very frame it last looked)
            while lock ~= nil and lock > 0 do
                local ok2, moved = pcall(Run, def, sg, statename, LOCK_DIST, 1, { frame = lock - 1, x = LOCK_DIST, z = LOCK_SIDE }, mem)
                if not ok2 or not Same(keys, MoveKeys(moved)) then break end
                lock = lock - 1
            end
            -- (a run cut at MAX_FRAMES, still going after its target: a jump in its last second shows
            -- too late in what it strikes before the cut - not a frame it stopped aiming. The small
            -- Snapping Turtle's spin, homing with its momentum to the end: "lock" 276 of 300, no
            -- strike round itself drawn - FALSE 257 on the bench, the big one's (no lock) 13)
            if lock ~= nil and not base.done and lock > MAX_FRAMES - 30 then lock = nil end
        end
    end
    COLLIDE = true
    return lock
end


-- Does it lay its attack out towards where its target is, or the way it faces? Its target steps
-- 30 degrees round at `frame`: if what it hits turns with it, towards its target ("target");
-- if it stays more as it was, the way it faces ("facing") - it turns slower than that.
local TURN_TEST = 30
local function Rotated(keys, deg)
    local out = {}
    local c, s = math.cos(deg * DEGREES), math.sin(deg * DEGREES)
    for k in pairs(keys) do
        local gx, gz = KeyXZ(k)
        local x, z = gx * STEP, gz * STEP
        -- (the game's way round: angle a is (cos a, -sin a))
        out[Key(x * c + z * s, -x * s + z * c)] = true
    end
    return out
end
local function Overlap(a, b)
    local n = 0
    for k in pairs(a) do if b[k] then n = n + 1 end end
    return n
end
-- (and one laid out the way it faces: whether it turns right round to its target as it begins -
-- its target square to its side from the start, what it hits goes round with them: `snaps` (the
-- Eye of Terror's charge - not the Werepig's slam, turning slower than you run))
function Snaps(def, sg, statename, mem)
    local ok, base = pcall(Run, def, sg, statename, LOCK_DIST, 1, nil, mem)
    if not ok or next(base.own) == nil then return false end
    spec_angle = 90
    local ok2, moved = pcall(Run, def, sg, statename, LOCK_DIST, 1, nil, mem)
    spec_angle = nil
    if not ok2 then return false end
    -- (what it set off too, as MoveKeys)
    local keys, mkeys = HitKeys(base.own), HitKeys(moved.own)
    for k in pairs(HitKeys(base.spread or {})) do keys[k] = true end
    for k in pairs(HitKeys(moved.spread or {})) do mkeys[k] = true end
    -- (and it has turned most of the way within its first frames - not slowly, as it winds up)
    local turn = math.abs(((snap_rot2 or 0) - (snap_rot0 or 0) + 540) % 360 - 180)
    if os.getenv("DBGFRAME") then io.stderr:write(string.format("SNAPS %s %s: turned %.0f in its first frames, rot0 %.0f, turn at %s %s, rotated %s/%s\n", def.prefab, statename, turn, snap_rot0 or -1, tostring(snap_turn and snap_turn[1]), tostring(snap_turn and snap_turn[2]), tostring(Overlap(Rotated(keys, 90), mkeys)), tostring(Overlap(keys, mkeys)))) end
    local rotated = Overlap(Rotated(keys, 90), mkeys) > 2 * Overlap(keys, mkeys)
    -- (or turned round to it only later, as another of its animations begins - the Scrappy
    -- Werepig, rummaging the way it faced, turning to you as it throws: that animation)
    local later = rotated and snap_turn ~= nil and snap_turn[1] > 3 and snap_turn[2] ~= (base.anims or {})[1] and snap_turn[2] or nil
    return rotated and turn >= 60, later
end
local function FrameOf(def, sg, statename, frame, mem)
    COLLIDE = false
    local result = FrameOfRuns(def, sg, statename, frame, mem)
    local snaps, snap_anim = Snaps(def, sg, statename, mem)
    COLLIDE = true
    -- (aimed at its target until it turns to them, as that animation begins; then the way it
    -- faces - it may not turn all the way: the junk goes the way it faces, as far as you are along it)
    if snap_anim ~= nil then return "facing", false, snap_anim end
    return result, result == "facing" and snaps or false
end

function FrameOfRuns(def, sg, statename, frame, mem)
    local ok, base = pcall(Run, def, sg, statename, LOCK_DIST, 1, nil, mem)
    if not ok or next(base.own) == nil then return "target" end -- (on its target only: where it went)
    local a = TURN_TEST * DEGREES
    -- (one that aims as it begins - frame 0: its target off to one side from the start - moved there
    -- a frame in, it has already turned (or not) to where they were)
    local ok2, moved
    if frame <= 0 then
        spec_angle = TURN_TEST
        ok2, moved = pcall(Run, def, sg, statename, LOCK_DIST, 1, nil, mem)
        spec_angle = nil
    else
        ok2, moved = pcall(Run, def, sg, statename, LOCK_DIST, 1,
            { frame = frame, x = LOCK_DIST * math.cos(a), z = -LOCK_DIST * math.sin(a) }, mem)
    end
    if not ok2 then return "target" end
    -- (and what it set off that strikes where it's put - its own blow round itself the same any way it
    -- faces, the things on a line to you are what turn: Uncompromising Mode's Bearger's sinkholes)
    local function All(res)
        local k = HitKeys(res.own)
        for kk in pairs(HitKeys(res.spread or {})) do k[kk] = true end
        return k
    end
    local keys, mkeys = All(base), All(moved)
    if os.getenv("DBGFRAME") then
        local nk, nm = 0, 0 for _ in pairs(keys) do nk = nk + 1 end for _ in pairs(mkeys) do nm = nm + 1 end
        io.stderr:write(string.format("FRAMEOF %s %s: at frame %d, cells %d / %d, same %s, turned %d, stayed %d\n", def.prefab, statename, frame,
            nk, nm, tostring(Same(keys, mkeys)), Overlap(Rotated(keys, TURN_TEST), mkeys), Overlap(keys, mkeys)))
    end
    -- (the same with its target off to the side from the start: it never turns to them - Frostjaw's
    -- second and third swipe, the way it faces)
    if Same(keys, mkeys) then return frame <= 0 and "facing" or "target" end
    local turned = Overlap(Rotated(keys, TURN_TEST), mkeys)
    local stayed = Overlap(keys, mkeys)
    -- (near enough the same either way - where it lands is random, junk thrown: which way the
    -- middle of it all went round, with its target or not - the Scrappy Werepig turned to you to
    -- throw, drawn the way it faced as it rummaged, behind it)
    if math.abs(turned - stayed) < .25 * math.max(turned, stayed) then
        local function Mid(keys)
            local n, sx, sz = 0, 0, 0
            for k in pairs(keys) do
                local gx, gz = KeyXZ(k)
                n, sx, sz = n + 1, sx + gx * STEP, sz + gz * STEP
            end
            if n == 0 then return nil end
            sx, sz = sx / n, sz / n
            if sx * sx + sz * sz < 1 then return nil end
            return math.atan2(-sz, sx) / DEGREES
        end
        local a0, a1 = Mid(keys), Mid(mkeys)
        if a0 ~= nil and a1 ~= nil then
            local d = (a1 - a0 + 540) % 360 - 180
            return math.abs(d - TURN_TEST) < math.abs(d) and "target" or "facing"
        end
    end
    return stayed > turned and "facing" or "target"
end

-- cells (key -> frame hit, from the move's start) as steps: { { at, packed cells } } by when
-- they're hit, a few frames to a step
local STEP_FRAMES = 1
-- (and when they're struck again, last - a stomp after stomp: { frame, the animation it was in
-- and how far into it }, per cell)
local lasts_of = setmetatable({}, { __mode = "k" })
-- (single cells left out between struck ones - each way, or both - filled, struck as soon as
-- the soonest beside: seen turned (a thing facing some way), the grid's rounding leaves holes in
-- a row, each drawn as a tiny outlined hole in the game)
local function Close(cells, lasts)
    local add = {}
    for k in pairs(cells) do
        for _, e in ipairs({ k - 1, k + 1, k - KM, k + KM }) do
            if cells[e] == nil and add[e] == nil then
                local a, b = cells[e - 1], cells[e + 1]
                local c, d = cells[e - KM], cells[e + KM]
                if (a ~= nil and b ~= nil) or (c ~= nil and d ~= nil) then
                    local f, from = nil, nil
                    for _, n in ipairs({ e - 1, e + 1, e - KM, e + KM }) do
                        if cells[n] ~= nil and (f == nil or cells[n] < f) then f, from = cells[n], n end
                    end
                    add[e] = { f, from }
                end
            end
        end
    end
    for e, v in pairs(add) do
        cells[e] = v[1]
        if lasts ~= nil and lasts[v[2]] ~= nil then lasts[e] = lasts[v[2]] end
    end
end

-- (struck once more this many frames after its first run of strikes ended: a part of its own)
split_gap = 8
local function Steps(cells)
    local lasts = lasts_of[cells] or {}
    Close(cells, lasts)
    local by, times, until_ = {}, {}, {}
    local has = {}
    for _, f in pairs(cells) do has[math.floor(math.max(0, f) / STEP_FRAMES) * STEP_FRAMES] = true end
    local later = {}
    for k, f in pairs(cells) do
        local at = math.floor(math.max(0, f) / STEP_FRAMES) * STEP_FRAMES
        if by[at] == nil then by[at] = {} table.insert(times, at) end
        by[at][k] = true
        local l = lasts[k]
        -- (struck on and on, then once more much later in a part of its own (below): in danger
        -- only as long as it was struck on and on - not all the way to that later part)
        -- (or struck once more well after - the Scion's slam, the same spots again a second later:
        -- that a part of its own, coming, not "striking" all the while between)
        if l ~= nil and l[4] ~= nil then
            local lat = math.floor(math.max(0, l[1]) / STEP_FRAMES) * STEP_FRAMES
            local run_end = l[4] and l[4][1] or f
            -- (later within the same go of its animation - not the next go round of one that loops,
            -- a stomp after stomp: that's struck on and on)
            local same_go = (l[3] or 0) - (lat - run_end) >= 0
            if (has[lat] or (lat - run_end >= split_gap and same_go)) and lat > f + STEP_FRAMES then
                later[k] = lat
                l = l[4] or nil
            end
        end
        -- (two as late: the same one each run - by name - not whichever pairs() gives first)
        local u = until_[at]
        if l ~= nil and l[1] > f + STEP_FRAMES and (u == nil or l[1] > u[1]
            or (l[1] == u[1] and tostring(l[2]) .. ":" .. tostring(l[3]) < tostring(u[2]) .. ":" .. tostring(u[3]))) then
            until_[at] = l
        end
    end
    -- (struck again later as part of another step - Frostjaw coming up, then landing over part of
    -- where it came up: in that one too, so each is its whole shape - not a landing with a bite
    -- out of it where the first was)
    for k, f in pairs(cells) do
        local l = lasts[k]
        if l ~= nil then
            local at = math.floor(math.max(0, l[1]) / STEP_FRAMES) * STEP_FRAMES
            if later[k] ~= nil and by[at] == nil then by[at] = {} table.insert(times, at) end
            if by[at] ~= nil and at > f + STEP_FRAMES then by[at][k] = true end
        end
    end
    table.sort(times)
    local parts = {}
    for _, at in ipairs(times) do
        local u = until_[at]
        local again = u ~= nil and string.format(" again_until = %d, again_anim = %q, again_at = %d,", u[1], u[2] or "", u[3] or 0) or ""
        table.insert(parts, string.format("{ at = %d,%s cells = %q }", at, again, Pack(by[at])))
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
end

-- (-ends: each spot by the frame it went out of reach - the end of its first run of strikes frame
-- after frame, or its one strike: ", ends = { { at, cells }, ... }" - true_range/simmoves draws
-- what's in reach now from these, one shape, not the crescents where each spot first came into it)
function EndsOf(cells)
    if not sim_rehit then return "" end
    local lasts = lasts_of[cells] or {}
    local by, times = {}, {}
    for k, f in pairs(cells) do
        local l = lasts[k]
        local e = f
        if l ~= nil then
            local run = l[4]
            if run then e = run[1] elseif run == nil then e = l[1] end
        end
        e = math.max(e, f)
        if by[e] == nil then by[e] = {} times[#times + 1] = e end
        by[e][k] = true
    end
    table.sort(times)
    local parts = {}
    for _, e in ipairs(times) do parts[#parts + 1] = string.format("{ at = %d, cells = %q }", e, Pack(by[e])) end
    return ", ends = { " .. table.concat(parts, ", ") .. " }"
end

-- (a hit's last strike, from t0: { frame, anim, frame in it, the first run's end - the same, or
-- false: struck once, then once more later })
local function LastOf(h, t0)
    if h.last == nil then return nil end
    local run = false
    if h.run ~= nil and h.run[1] > h.frame then run = { h.run[1] - t0, h.run[2], h.run[3] } end
    return { h.last[1] - t0, h.last[2], h.last[3], run }
end

local function Earliest(cells, k, f, last)
    if cells[k] == nil or f < cells[k] then cells[k] = f end
    if last ~= nil then
        local lasts = lasts_of[cells] or {}
        lasts_of[cells] = lasts
        if lasts[k] == nil or last[1] > lasts[k][1] then lasts[k] = last end
    end
end

-- How a move shows: the first animation of its own state - not of one it went through on the
-- way, standing up - and not one it also gets about with (a run-up); then all it plays after.
function KeyAnims(res, statename, about)
    local list = {}
    local from = res.state_anim[statename]
    local on = from == nil
    for _, a in ipairs(res.anims) do
        if a == from then on = true end
        if on and not (#list == 0 and about[a]) then table.insert(list, a) end
    end
    -- (its move all in what looks like getting about - Jitters strikes as it runs, run_pre and
    -- run_loop its whole attack: none left, nothing drawn - those then)
    if #list == 0 then
        on = from == nil
        for _, a in ipairs(res.anims) do
            if a == from then on = true end
            if on then table.insert(list, a) end
        end
    end
    -- (key_cut: animations not part of it, from the boss's spec (cut) - its getting over it, the Rictus'
    -- bite_pst: kept as part of the move, its bite's shape went on after you, the biting done)
    if key_cut ~= nil then
        for i = #list, 2, -1 do
            if key_cut[list[i]] then table.remove(list, i) end
        end
    end
    return list
end

-- -check: does what the game draws (true_range/predict + simmoves, as they lay a move out) cover
-- where it really hits - with its target walking about meanwhile, or the boss already on its
-- way as it begins? Each move is run so, laid out as the game would from what it sees, and the
-- two compared, cell by cell (a cell next to one counts: turned, cells don't line up exactly).
local CHECK = false
for i = 3, #arg do if arg[i] == "-check" then CHECK = true end end
-- (speeds: a player walks 6, faster with a cane or on a road (7.5-9), slower when slowed (3);
-- turn: the way changes partway - { frame, x, z })
local SCENES = {
    { name = "you stand still", walk = { 0, 0 } },
    { name = "you walk sideways", walk = { 0, 6 } },
    { name = "you run sideways fast", walk = { 0, 9 } },
    { name = "you walk slowly sideways", walk = { 0, 3 } },
    { name = "you walk closer", walk = { -6, 0 } },
    { name = "you walk away", walk = { 6, 0 } },
    { name = "you run away fast", walk = { 9, 0 } },
    { name = "you walk across", walk = { 4, 4 } },
    { name = "you dodge, then stop", walk = { 0, 9 }, turn = { 12, 0, 0 } },
    { name = "you stand, then dodge", walk = { 0, 0 }, turn = { 15, 0, 9 } },
    { name = "you go sideways, then back", walk = { 0, 6 }, turn = { 15, 0, -6 } },
    { name = "it walks in", boss_vel = 4 },
    { name = "it runs in", boss_vel = 7 },
    { name = "it charges in", boss_vel = 12 },
    { name = "it walks in, you walk sideways", boss_vel = 4, walk = { 0, 6 } },
}
-- (and wandering about: a new way and speed (3 to 9 a second) every 8 to 20 frames - made the same
-- every time, by a generator of their own: the runs' own random numbers are the game's)
do
    local s = 12345
    local function R() s = (s * 1103515245 + 12345) % 2147483648 return s / 2147483648 end
    for k = 1, 4 do
        local turns, f = {}, 0
        local function Way()
            local a, v = R() * 2 * math.pi, 3 + R() * 6
            return v * math.cos(a), v * math.sin(a)
        end
        local wx, wz = Way()
        while f < 150 do
            f = f + 8 + math.floor(R() * 13)
            local x, z = Way()
            turns[#turns + 1] = { f, x, z }
        end
        SCENES[#SCENES + 1] = { name = "you wander " .. k, walk = { wx, wz }, turns = turns }
    end
end
local CHECK_DISTS = { 3, 6, 10 }
local function Near(set, k)
    if set[k] then return true end
    for _, d in ipairs({ 1, -1, KM, -KM, KM + 1, KM - 1, -KM + 1, -KM - 1 }) do
        if set[k + d] then return true end
    end
    return false
end
local you_outside, you_where = nil, nil
-- (a later form of a boss, run with mem set (spec mem = { key = true }): the animation of the
-- state that sets it - the Twins' "transform" - seen in the game, it's that form from then on)
function AfterAnim(def, mem)
    for key, v in pairs(mem or {}) do
        if v == true then
            local fh = io.open(SCRIPTS .. "/stategraphs/" .. def.sg .. ".lua", "rb")
            local st = fh and fh:read("*a") or ""
            if fh then fh:close() end
            local at = st:find("sg%.mem%." .. key .. "%s*=%s*true")
            if at ~= nil then
                local s0 = nil
                for p in st:sub(1, at):gmatch('()State%s*%{%s*name%s*=') do s0 = p end
                local anim = s0 and st:sub(s0, at):match('PlayAnimation%(%s*"([%w_]+)"') or nil
                if anim ~= nil then return anim, st:sub(s0, at):match('name%s*=%s*"([%w_]+)"'), key end
            end
        end
    end
    return nil
end
-- (SIMTRACE=<dir>: each move's check runs, these scenes, written out as traces - tools/verify.ps1)
SIMTRACE_DIR = os.getenv("SIMTRACE")
TRACE_SCENES = { ["you stand still"] = true, ["you walk sideways"] = true, ["you run away fast"] = true,
    ["you walk across"] = true, ["it walks in"] = true, ["you wander 1"] = true, ["you wander 2"] = true,
    ["you wander 3"] = true, ["you wander 4"] = true }
trace_n, trace_tag = 0, nil
local function CheckMove(def, sg, statename, mem, info)
    local report = {}
    local made = SpawnPrefab(def.prefab)
    -- (it gets about - legs (a locomotor), or a body that isn't set in the ground: not a tentacle)
    local boss_moves_at_all = made ~= nil and (rawget(made.components or {}, "locomotor") ~= nil
        or (made.radius ~= nil and not rawget(made, "rooted")))
    for _, scene in ipairs(SCENES) do
        for _, dist in ipairs(CHECK_DISTS) do
            -- (one that never moves - rooted in the ground, the Antlion: not on its way anywhere)
            if scene.boss_vel ~= nil and not boss_moves_at_all then goto next_scene end
            local ok, res = pcall(Run, def, sg, statename, dist, 1, { walk = scene.walk and { scene.walk[1], scene.walk[2] },
                turn = scene.turn, turns = scene.turns, boss_vel = scene.boss_vel }, mem)
            if not ok then
                table.insert(report, string.format("    %s, %d away: failed (%s)", scene.name, dist, tostring(res)))
            else
                -- (SIMTRACE: the run written as the game's trace is - replayed through the mod's own
                -- drawing, tests/replay.lua: does what it draws agree with what the run hit?)
                if SIMTRACE_DIR ~= nil and TRACE_SCENES[scene.name] then
                    trace_n = trace_n + 1
                    local guid = trace_n
                    local fh = io.open(string.format("%s/%s.trace", SIMTRACE_DIR, trace_tag or def.prefab), "ab")
                    if fh ~= nil then
                        local base = guid * 100
                        local pa = res.pose_at
                        -- (a later form: seen turning into it first, as in the game - else the mod takes it
                        -- for the first form)
                        local aa, astate = AfterAnim(def, mem)
                        if aa ~= nil and pa[0] ~= nil then
                            local p = pa[0]
                            for k = 1, 3 do
                                fh:write(string.format("[tr_trace] %.3f %s after state=%s t=0 anim_t=0 pos=%.3f,%.3f rot=%.2f vel=0,0 you=%.3f,%.3f d=0 guid=%d yvel=0,0 anim=%s scale=%.3f\n",
                                    base - 1 + k * FRAMES, def.prefab, tostring(astate), p.x, p.z, p.rot, p.px, p.pz, guid, aa, p.scale or 1))
                            end
                        end
                        local hit_at = {}
                        for _, hf in ipairs(res.player_hits) do hit_at[hf] = "thing" end
                        for _, hf in ipairs(res.own_hits) do hit_at[hf] = "own" end
                        for fr = 0, #pa do
                            local p = pa[fr]
                            if p ~= nil then
                                local q = pa[fr - 1] or p
                                local line = string.format("%.3f %s %%s state=%s t=0 anim_t=%.3f pos=%.3f,%.3f rot=%.2f vel=0,0 you=%.3f,%.3f d=0 guid=%d yvel=%.3f,%.3f anim=%s scale=%.3f\n",
                                    base + fr * FRAMES, def.prefab, tostring(p.state), p.anim_t or 0, p.x, p.z, p.rot, p.px, p.pz, guid,
                                    (p.px - q.px) / FRAMES, (p.pz - q.pz) / FRAMES, tostring(p.anim), p.scale or 1)
                                fh:write("[tr_trace] " .. (line:format("after"):gsub("\n$", p.tpos ~= nil and string.format(" tpos=%.2f,%.2f\n", p.tpos.x, p.tpos.z) or "\n")))
                                -- (struck by the boss itself - or by something it set off: drawn with the move or not)
                                if hit_at[fr] == "own" then fh:write("[tr_trace] " .. line:format("STRIKE at wilson"))
                                elseif hit_at[fr] == "thing" then fh:write("[tr_trace] " .. line:format("THINGHIT at wilson")) end
                            end
                        end
                        fh:write(string.format("[tr_trace] SCENE %d %s %s %s %d\n", guid, def.prefab, statename, scene.name, dist))
                        fh:close()
                    end
                end
                local key = info.key_anim[1]
                local t0 = res.anim_frame[key] or 0
                local start = res.anim_pose[key] or { x = 0, z = 0, rot = 0, px = dist, pz = 0 }
                local pa = res.pose_at
                local function At(fr) return pa[math.max(0, math.min(fr, #pa))] or pa[#pa] or start end
                -- (what the game sees when it stops aiming)
                local L = info.lock ~= nil and t0 + info.lock or nil
                local tgt = L ~= nil and At(L - 1) or nil
                local bp = L ~= nil and At(L) or nil
                local actual, predicted = {}, {}
                for _, list in ipairs({ res.own, res.spread }) do
                    for d in pairs(list) do actual[Key(d.x, d.z)] = true end
                end
                -- (one that only hits whoever it's after: where you were each time it struck you)
                local struck = {}
                -- (its attack on you lands only within its reach of where it is then - the game's
                -- own check; here every one is noted, near or far)
                for _, th in ipairs(res.target_hits) do
                    local p = At(th.frame)
                    if (p.px - th.x) ^ 2 + (p.pz - th.z) ^ 2 <= (th.range + .5) ^ 2 then
                        struck[th.frame] = Key(p.px, p.pz)
                    end
                end
                -- (each step as it's drawn then: from where, which way, which distance's map)
                local function Lay(fr)
                    local ox, oz = start.x, start.z
                    if info.anchor and bp ~= nil then ox, oz = bp.x, bp.z end
                    local now_p = At(t0 + fr)
                    if info.still then ox, oz = now_p.x, now_p.z end
                    local tx, tz
                    if tgt ~= nil then tx, tz = tgt.px, tgt.pz else tx, tz = now_p.px, now_p.pz end
                    local rot
                    if info.frame == "facing" then
                        rot = (bp ~= nil and bp.rot or now_p.rot) * DEGREES
                    else
                        rot = math.atan2(-(tz - oz), tx - ox)
                    end
                    local d = math.sqrt((tx - ox) ^ 2 + (tz - oz) ^ 2)
                    if info.frame == "facing" then
                        local along = (tx - ox) * math.cos(rot) - (tz - oz) * math.sin(rot)
                        if spec_behind then along = -along end
                        d = along >= d * .5 and along or (info.off or 1e6)
                    end
                    return ox, oz, rot, d
                end
                -- (its target out of its way at that frame: as it goes then - free)
                local function Best(d, list)
                    local best = nil
                    for _, m in ipairs(list or info.maps) do
                        if best == nil or math.abs(m.dist - d) < math.abs(best.dist - d) then best = m end
                    end
                    return best
                end
                -- (legs - rolls, charges: each leg's cells from where it set off, and how they end
                -- from where that began; round itself - a spin: its cells round it, towards its target,
                -- wherever it is as it strikes)
                if info.legs ~= nil or info.around ~= nil then
                    local function Place(set, cells, x, z, rot)
                        local cc, ss = math.cos(rot), math.sin(rot)
                        for k in pairs(cells) do
                            local ix, iz = KeyXZ(k)
                            local ahead, side = ix * STEP, iz * STEP
                            set[Key(x + ahead * cc + side * ss, z - ahead * ss + side * cc)] = true
                        end
                    end
                    local done_entry = {}
                    for _, list in ipairs({ res.own }) do
                        for _, h in pairs(list) do
                            local e = h.entry
                            if info.legs ~= nil and e ~= nil and not done_entry[e] then
                                done_entry[e] = true
                                if e.name == info.legs.state then
                                    Place(predicted, info.legs.cells, e.x, e.z, e.rot * DEGREES)
                                elseif e.name ~= statename then
                                    Place(predicted, info.legs.finish, e.x, e.z, e.rot * DEGREES)
                                end
                            end
                            if info.around ~= nil and h.sx ~= nil then
                                local p = At(h.frame)
                                local rot = math.atan2(-(p.pz - h.sz), p.px - h.sx)
                                Place(predicted, info.around, h.sx, h.sz, rot)
                            end
                        end
                    end
                    goto compare
                end
                do
                -- (frames its cells strike on: the map at the distance seen first)
                local _, _, _, d0 = Lay(0)
                local m0 = Best(d0)
                local function InWay(fr, ox, oz, rot)
                    if info.free == nil then return true end
                    local p = At(t0 + fr)
                    local dx, dz = p.px - ox, p.pz - oz
                    local along = dx * math.cos(rot) - dz * math.sin(rot)
                    local side = dx * math.sin(rot) + dz * math.cos(rot)
                    -- (in its way off to one side: it bumps you further on than square on - as the
                    -- map for a target that much further, square on)
                    local reach = (res.radius or 1) + .5
                    -- (ahead of it as it is then - one it has passed no longer stops it)
                    local gone = (p.x - ox) * math.cos(rot) - (p.z - oz) * math.sin(rot)
                    -- (or as far off its way as it goes for you - it stops by its own say: where you are)
                    if info.reach ~= nil then
                        return along > gone and math.abs(side) < info.reach, along
                    end
                    local inway = along > gone and math.abs(side) < reach
                    if inway then along = along + reach - math.sqrt(reach * reach - side * side) end
                    return inway, along
                end
                -- (the map to draw a frame with: in its way - stopped where you are then; not - free)
                local function Pick(fr, ox, oz, rot, d)
                    if info.free == nil then return Best(d) end
                    local inway, along = InWay(fr, ox, oz, rot)
                    if inway then return Best(along) end
                    return Best(d, info.free)
                end
                -- (each frame: what the map picked then strikes then - the map can change as you go)
                local frames = {}
                for _, list in ipairs({ info.maps, info.free or {} }) do
                    for _, m in ipairs(list) do
                        for _, fr in pairs(m.cells) do frames[fr] = true end
                    end
                end
                for fr in pairs(frames) do
                    local ox, oz, rot, d = Lay(fr)
                    local m = Pick(fr, ox, oz, rot, d)
                    local c, s = math.cos(rot), math.sin(rot)
                    for k, kf in pairs(m and m.cells or {}) do
                        if kf == fr then
                            local ix, iz = KeyXZ(k)
                            local ahead, side = ix * STEP, iz * STEP
                            predicted[Key(ox + ahead * c + side * s, oz - ahead * s + side * c)] = true
                        end
                    end
                end
                -- (only its target: when it struck, were you in what was drawn for then - and when
                -- you stood in a part drawn striking then, were you struck)
                if info.single then
                    local fails = {}
                    -- (what's drawn at a frame: all of it, laid out as then - a part struck already
                    -- stays drawn while it may strike again)
                    local function DrawnAt(fr)
                        local ox, oz, rot, d = Lay(fr)
                        local m = Pick(fr, ox, oz, rot, d)
                        local set = {}
                        local cc, ss = math.cos(rot), math.sin(rot)
                        for k in pairs(m and m.cells or {}) do
                            local ix, iz = KeyXZ(k)
                            local ahead, side = ix * STEP, iz * STEP
                            set[Key(ox + ahead * cc + side * ss, oz - ahead * ss + side * cc)] = true
                        end
                        return set
                    end
                    for f, k in pairs(struck) do
                        if not Near(DrawnAt(f - t0), k) then table.insert(fails, "struck at " .. (f - t0) .. " outside it") end
                    end
                    local _, _, _, d1 = Lay(0)
                    local m1 = Best(d1)
                    local strike_frames = {}
                    for _, fr in pairs(m1 and m1.cells or {}) do strike_frames[fr] = true end
                    for fr in pairs(strike_frames) do
                        local cells = DrawnAt(fr)
                        local p = At(t0 + fr)
                        local k = Key(p.px, p.pz)
                        if cells[k] and struck[t0 + fr] == nil then
                            -- (well inside: all round it drawn too)
                            local inside = true
                            for _, d in ipairs({ 1, -1, KM, -KM }) do if not cells[k + d] then inside = false end end
                            if inside then table.insert(fails, "well in it at " .. fr .. ", not struck") end
                        end
                    end
                    table.insert(report, string.format("    %s%s, %d away: %s", #fails > 0 and "!! " or "", scene.name, dist,
                        #fails > 0 and table.concat(fails, "; ") or (next(struck) and "struck, inside it" or "not struck, nor in it")))
                    goto next_scene
                end
                -- (you yourself struck - where you really were, not a cell's middle: in what was
                -- drawn striking by then, its very cell, as the game tells it)
                for _, f in ipairs(res.player_hits) do
                    local fr = f - t0
                    local ox, oz, rot, d = Lay(fr)
                    local m = Pick(fr, ox, oz, rot, d)
                    local p = At(f)
                    local dx, dz = p.px - ox, p.pz - oz
                    local ahead = dx * math.cos(rot) - dz * math.sin(rot)
                    local side = dx * math.sin(rot) + dz * math.cos(rot)
                    local kf = m and m.cells[Key(ahead, side)] or nil
                    if os.getenv("CHECK_SHOW") == def.prefab .. " " .. statename .. " " .. scene.name .. " " .. dist then
                        print(string.format("  hit at %d: t0 %d L %s tgt %s,%s origin %.2f,%.2f rot %.1f you %.2f,%.2f -> %.2f ahead %.2f aside, cell frame %s",
                            f, t0, tostring(L), tostring(tgt and tgt.px), tostring(tgt and tgt.pz), ox, oz, rot / DEGREES, p.px, p.pz, ahead, side, tostring(kf)))
                    end
                    -- (in a part still to strike counts: it's drawn - in the very cell, though; and not
                    -- one that's not the same each time - its things are drawn as each one comes)
                    if kf == nil and not info.random then
                        you_outside = (you_outside or 0) + 1
                        you_where = string.format("%.2f ahead %.2f aside at %d", ahead, side, fr)
                    end
                end
                end
                ::compare::
                local na, np, missed, extra = 0, 0, 0, 0
                if you_outside ~= nil then
                    table.insert(report, string.format("    !! %s, %d away: you struck outside it (%d times; %s)", scene.name, dist, you_outside, you_where))
                    you_outside = nil
                end
                for k in pairs(actual) do na = na + 1 if not Near(predicted, k) then missed = missed + 1 end end
                for k in pairs(predicted) do np = np + 1 if not Near(actual, k) then extra = extra + 1 end end
                -- (not the same each time: all it may do is drawn - only what it hit outside that counts)
                -- (legs: drawn as long as a leg goes - one cut short, its target gone off, is fine)
                local bad = (na > 0 and missed / na > .1) or (not info.random and info.legs == nil and np > 0 and extra / np > .25)
                if os.getenv("CHECK_SHOW") == def.prefab .. " " .. statename .. " " .. scene.name .. " " .. dist then
                    print("actual:") Show("", actual)
                    print("drawn:") Show("", predicted)
                end
                table.insert(report, string.format("    %s%s, %d away: missed %d of %d it hit, drew %d of %d where it didn't",
                    bad and "!! " or "", scene.name, dist, missed, na, extra, np))
            end
            ::next_scene::
        end
    end
    return report
end

local hazards = {}   -- prefab of something a boss sets off -> cells it hits, seen from it
local move_random = {}   -- "boss/state" -> whether that move is not the same each time
local RUNS_RANDOM = 16 -- runs per distance when it isn't the same each time (spikes, crystals)

local out = {
    "-- Made by true_range_workshop/tools/sim_moves.lua: the game's own attack code, run offline.",
    "-- prefab -> first animation of a move -> { anims (all it plays), first (frame its damage",
    "-- starts), lock (frame from which it no longer follows its target), frame (\"target\": laid",
    "-- out towards its target; \"facing\": the way it faces), random (not the same each time:",
    "-- where it may hit), single (it only hits whoever it's after), leg (it goes in straight",
    "-- legs: one leg's cells; restart \"wrap\": a new leg each time its animation starts over,",
    "-- \"enter\": each time it comes back to it), maps = { { dist (its target this far ahead),",
    "-- steps = { { at (frames after it starts), cells } } } } }",
    "-- cells: packed (see Pack); row 0 / column 0 are the cell at side -" .. SIDE .. " / ahead " .. AHEAD[1],
    "-- (seen from where the boss stood, its target straight ahead).",
    "-- _hazards: things bosses set off -> the cells they hit, seen from them.",
    "return {",
    string.format("    _grid = { ahead = %s, side = %s, step = %s },", tostring(AHEAD[1]), tostring(SIDE), tostring(STEP)),
}
-- (others made the same way, with the same moves: drawn as the one run)
do
    local parts = {}
    for _, def in ipairs(BOSSES) do
        for _, other in ipairs(def.also or {}) do table.insert(parts, string.format("%s = %q", other, def.prefab)) end
    end
    table.insert(out, "    _alias = { " .. table.concat(parts, ", ") .. " },")
end
-- (the ones found in the game's files: only a real fighter - made, it has combat and that
-- stategraph; not a spawner, a piece of fx, a shadow in the same file - said, as left out)
do
    local kept = {}
    for _, def in ipairs(BOSSES) do
        local ok = true
        -- (a run of a few alone - one of -jobs' parts: only those made to see; the rest aren't run
        -- here at all - making all 129 found took each part seconds of its own)
        if def.auto and (only == nil or only[def.prefab]) then
            Reset()
            local fine, e = pcall(SpawnPrefab, def.prefab)
            local comps = fine and type(e) == "table" and rawget(e, "components") or nil
            ok = comps ~= nil and rawget(comps, "combat") ~= nil and rawget(e, "sg_name") == def.sg
            if not ok and only ~= nil and only[def.prefab] then
                io.stderr:write("AUTO LEFT OUT " .. def.prefab .. ": no combat or not " .. def.sg .. "\n")
            end
        end
        if ok then kept[#kept + 1] = def end
    end
    for i = #BOSSES, 1, -1 do BOSSES[i] = nil end
    for i, def in ipairs(kept) do BOSSES[i] = def end
end
-- COVERAGE=<the mod's moves_sim.lua>: every state of every boss's stategraph run from - not only
-- the ones listed as attacks: a branch only taken in a later phase, or as its brain says, is
-- started from all the same - and the game's own code followed on to its end; every blow struck,
-- whose (the boss, as it played which animation - or a thing it set off, by what) - and each one
-- the mod's data has nothing for, said: UNCOVERED. tools/verify.ps1 counts them.
-- SIM_LIB=1: the world and its runs handed over, nothing more done here - the new parts
-- (tools/trace_moves.lua: what each blow depends on) run the game's code through it
if os.getenv("SIM_LIB") ~= nil or rawget(_G, "sim_lib_mode") == true then
    SimLib = {
        Run = Run, BOSSES = BOSSES, Entity = Entity, Key = Key, KeyXZ = KeyXZ, STEP = STEP, PAD = PAD,
        Steps = Steps, AHEAD = AHEAD, SIDE = SIDE, PACK_AHEAD = sim_pack.ahead, PACK_SIDE = sim_pack.side,
        Frame = function() return frame_n end, Acting = function() return acting end,
        Boss = function() return sim_boss end, Target = function() return sim_target end,
        SCRIPTS = SCRIPTS, GettingAbout = GettingAbout,
    }
    return SimLib
end
if os.getenv("COVERAGE") ~= nil then
    do
        local Data = dofile(os.getenv("COVERAGE"))
        local hazards = Data._hazards or {}
        local said, sources, uncovered = {}, 0, 0
        cover_add = {}
        for _, def in ipairs(BOSSES) do
            if only == nil or only[def.prefab] then
                local okl, sg = pcall(LoadSG, def.sg)
                local entries = Data[def.prefab] or Data[(Data._alias or {})[def.prefab] or ""] or {}
                local anims = {}
                for _, e in pairs(entries) do
                    if type(e) == "table" then
                        for _, a in ipairs(e.anims or {}) do anims[a] = true end
                        if e.leg ~= nil and e.leg.finish ~= nil then anims[e.leg.finish.anim] = true end
                    end
                end
                -- (each branch its code takes on a flag - sg.mem.<x> (the Twins transformed), inst.can<x>
                -- (the War Machine's orbital strike): each run with it on, one at a time, too)
                local branches = { {} }
                do
                    local fh = io.open(SCRIPTS .. "/stategraphs/" .. def.sg .. ".lua", "rb")
                    local text = fh and fh:read("*a") or ""
                    if fh then fh:close() end
                    local seen_flag = {}
                    for flag in text:gmatch("sg%.mem%.([%w_]+)") do
                        if not seen_flag["m" .. flag] then seen_flag["m" .. flag] = true table.insert(branches, { mem = { [flag] = true } }) end
                    end
                    for flag in text:gmatch("inst%.(can[%w_]+)") do
                        if not seen_flag["f" .. flag] then seen_flag["f" .. flag] = true table.insert(branches, { fields = { [flag] = true } }) end
                    end
                end
                for _, st in ipairs(okl and sg.states or {}) do
                  for _, br in ipairs(branches) do
                    spec_behind, spec_side, spec_angle, spec_setup, spec_lucky, spec_sg, spec_still, spec_lasttags = nil, nil, nil, nil, nil, nil, nil, nil
                    spec_fields, spec_frames, spec_prep = br.fields, nil, nil
                    for _, dist in ipairs({ 2, 6 }) do
                        -- (tried as it's likely gone into, then with nothing handed on, then with the
                        -- flag a count rather than yes - mouthcharge_count, loops)
                        local ok, res
                        for attempt = 1, 4 do
                            spec_noarg = attempt == 2 or attempt == 4
                            local mem = br.mem
                            if mem ~= nil and attempt >= 3 then
                                mem = {}
                                for k in pairs(br.mem) do mem[k] = 3 end
                            end
                            ok, res = pcall(Run, def, sg, st.name, dist, 1, nil, mem)
                            spec_noarg = nil
                            if ok then break end
                            if attempt == 2 and br.mem == nil then break end
                        end
                        -- (one that couldn't be run here: a hole - said, not passed over)
                        if not ok then
                            local key = def.prefab .. " error " .. tostring(res):gsub("%d+", "#")
                            if not said[key] then
                                said[key] = true
                                run_errors = (run_errors or 0) + 1
                                io.stderr:write(string.format("NOTRUN %s from %s: %s\n", def.prefab, st.name, tostring(res)))
                            end
                        end
                        if ok and type(res) == "table" then
                            for _, h in pairs(res.own or {}) do
                                if h.by == nil or rawget(h.by, "is_sim_boss") then
                                    local a = h.boss_anim or "?"
                                    local key = def.prefab .. " boss " .. a
                                    if not said[key] then
                                        said[key] = true
                                        sources = sources + 1
                                        if os.getenv("COVERLIST") then io.stderr:write("SOURCE " .. key .. " (" .. tostring(h.boss_state) .. ", from " .. st.name .. ")\n") end
                                        if not anims[a] then
                                            uncovered = uncovered + 1
                                            -- (the state it was run from: a move to add, next run)
                                            -- (with the branch it took - a flag on - and the state it struck in,
                                            -- too: run from there, a move of its own)
                                            cover_add[def.prefab] = cover_add[def.prefab] or {}
                                            local function Add(name)
                                                local k = name .. "|" .. tostring(br.mem and next(br.mem)) .. "|" .. tostring(br.fields and next(br.fields))
                                                cover_add[def.prefab][k] = { name = name, mem = br.mem, fields = br.fields }
                                            end
                                            -- (only the state it was run from: one it went on into from there is
                                            -- part of that move - added apart, it cut the first short: Bearger's
                                            -- pound, its waves landing as it staggers)
                                            Add(st.name)
                                            io.stderr:write(string.format("UNCOVERED %s: struck as it played %s (state %s, run from %s) - no move of it has that animation\n",
                                                def.prefab, a, tostring(h.boss_state), st.name))
                                        end
                                    end
                                end
                            end
                            for prefab in pairs(res.things or {}) do
                                local key = def.prefab .. " thing " .. prefab
                                if not said[key] then
                                    said[key] = true
                                    sources = sources + 1
                                    if os.getenv("COVERLIST") then io.stderr:write("SOURCE " .. key .. " (from " .. st.name .. ")\n") end
                                    if hazards[prefab] == nil then
                                        uncovered = uncovered + 1
                                        io.stderr:write(string.format("UNCOVERED %s: %s it set off struck (run from %s) - nothing drawn for it\n",
                                            def.prefab, prefab, st.name))
                                    end
                                end
                            end
                        end
                    end
                  end
                end
                spec_fields = nil
            end
        end
        io.stderr:write(string.format("coverage: %d sources of blows found, %d not covered, %d states that would not run\n", sources, uncovered, run_errors or 0))
        -- (the states it struck from that no move covers: added as moves the next run - beside the
        -- game's scripts' copy, coverage_add.lua)
        -- (kept from before as well: each found once stays a move - else, covered by it next time,
        -- it would be dropped, and come back the time after)
        local add_path = (SCRIPTS:gsub("[/\\][^/\\]+[/\\]?$", "")) .. "/coverage_add.lua"
        local okp, prev = pcall(dofile, add_path)
        if okp and type(prev) == "table" then
            for prefab, list in pairs(prev) do
                cover_add[prefab] = cover_add[prefab] or {}
                for _, s in ipairs(list) do
                    local name = type(s) == "table" and s.name or s
                    local k = name .. "|" .. tostring(type(s) == "table" and s.mem and next(s.mem)) .. "|" .. tostring(type(s) == "table" and s.fields and next(s.fields))
                    if cover_add[prefab][k] == nil then cover_add[prefab][k] = type(s) == "table" and s or { name = s } end
                end
            end
        end
        -- (written beside it, not over it: the runs going on alongside read it as they start -
        -- tools/verify.ps1 puts it in place once they're done)
        local cf = io.open((add_path:gsub("%.lua$", ".next.lua")), "wb")
        if cf ~= nil then
            cf:write("return {\n")
            for prefab, states in pairs(cover_add) do
                local l = {}
                for _, s in pairs(states) do
                    local extra = ""
                    if s.mem ~= nil then local k = next(s.mem) extra = extra .. string.format(", mem = { [%q] = %s }", k, tostring(s.mem[k])) end
                    if s.fields ~= nil then local k = next(s.fields) extra = extra .. string.format(", fields = { [%q] = %s }", k, tostring(s.fields[k])) end
                    l[#l + 1] = string.format("{ name = %q%s }", s.name, extra)
                end
                table.sort(l)
                cf:write(string.format("    [%q] = { %s },\n", prefab, table.concat(l, ", ")))
            end
            cf:write("}\n")
            cf:close()
        end
    end
    os.exit(0)
end
-- -jobs: every move of every boss in a process of its own, side by side (as many at once as
-- there are processors), then one file made of theirs: each move's lines in order, and what
-- they set off joined as one run would (-raw: a part also writes that, unpacked, to <out>.haz)
local jobs, raw = false, false
for i = 3, #arg do
    if arg[i] == "-jobs" then jobs = true end
    if arg[i] == "-raw" then raw = true end
end
local function Dump(v, ind)
    if type(v) == "table" then
        local parts = {}
        for k, x in pairs(v) do
            local key = type(k) == "number" and ("[" .. string.format("%.17g", k) .. "]") or string.format("[%q]", k)
            table.insert(parts, key .. " = " .. Dump(x))
        end
        return "{ " .. table.concat(parts, ", ") .. " }"
    elseif type(v) == "string" then
        return string.format("%q", v)
    elseif type(v) == "number" then
        return string.format("%.17g", v)
    end
    return tostring(v)
end
if jobs then
    local tasks = {}
    for bi, def in ipairs(BOSSES) do
        -- (-only: just those - tools/verify.ps1 -Only)
        if only == nil or only[def.prefab] then
            for i in ipairs(def.states) do table.insert(tasks, { prefab = def.prefab, i = i, order = bi }) end
        end
    end
    local exe = arg[-1] or "luajit"
    local slots = tonumber(os.getenv("NUMBER_OF_PROCESSORS") or "") or 4
    local running, next_task = {}, 1
    -- (a clock, and a nap: waiting on whichever finishes first, not the oldest - one long move
    -- held up every slot freed behind it)
    local ffi = require("ffi")
    pcall(ffi.cdef, "void Sleep(uint32_t ms); uint64_t GetTickCount64(void);")
    local function Now() return tonumber(ffi.C.GetTickCount64()) / 1000 end
    -- (the longest first, as long as each took last time - none left running alone at the end)
    local TIMES = OUT:gsub("[^/\\]*$", "") .. "sim_times.lua"
    local took = {}
    do
        local ok, t = pcall(dofile, TIMES)
        if ok and type(t) == "table" then took = t end
    end
    local function Name(t) return t.prefab .. "#" .. t.i end
    table.sort(tasks, function(a, b)
        local ta, tb = took[Name(a)] or 1e9, took[Name(b)] or 1e9
        if ta ~= tb then return ta > tb end
        return Name(a) < Name(b)
    end)
    -- (the scan of the game's prefab files, done once here: handed to every part - SIM_SCAN_CACHE)
    isolate = os.getenv("SIM_NO_ISOLATE") == nil and slots >= 4
    local scan_path = OUT .. ".scan.lua"
    do
        local function Q(s) return string.format("%q", s) end
        local function Map(m)
            local keys = {}
            for k in pairs(m) do keys[#keys + 1] = k end
            table.sort(keys)
            local o = {}
            for _, k in ipairs(keys) do o[#o + 1] = "[" .. Q(k) .. "]=" .. Q(m[k]) end
            return "{" .. table.concat(o, ",") .. "}"
        end
        -- (a state as listed: its name, or { name, mem, ... } - plain values all)
        local function Value(v)
            if type(v) == "string" then return Q(v) end
            if type(v) == "number" or type(v) == "boolean" then return tostring(v) end
            assert(type(v) == "table", "a state of " .. type(v) .. " - can't hand on")
            local keys = {}
            for k in pairs(v) do keys[#keys + 1] = k end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            local o = {}
            for _, k in ipairs(keys) do o[#o + 1] = "[" .. Value(k) .. "]=" .. Value(v[k]) end
            return "{" .. table.concat(o, ",") .. "}"
        end
        local function List(l)
            local o = {}
            for _, s in ipairs(l) do o[#o + 1] = Value(s) end
            return "{" .. table.concat(o, ",") .. "}"
        end
        local parts = { "return {", "prefab_file=" .. Map(prefab_file) .. ",", "alt_file=" .. Map(alt_file) .. "," }
        if scan_auto ~= nil then
            local merged, names = {}, {}
            for k in pairs(scan_auto.merged) do names[#names + 1] = k end
            table.sort(names)
            for _, k in ipairs(names) do merged[#merged + 1] = "[" .. Q(k) .. "]=" .. List(scan_auto.merged[k]) end
            local lists, added = {}, {}
            for _, l in ipairs(scan_auto.lists) do lists[#lists + 1] = List(l) end
            for _, a in ipairs(scan_auto.added) do added[#added + 1] = string.format("{prefab=%s,sg=%s,list=%d}", Q(a.prefab), Q(a.sg), a.list) end
            parts[#parts + 1] = "auto={merged={" .. table.concat(merged, ",") .. "},lists={" .. table.concat(lists, ",") .. "},added={" .. table.concat(added, ",") .. "}},"
        end
        parts[#parts + 1] = "}"
        local fh = assert(io.open(scan_path, "wb"))
        fh:write(table.concat(parts, "\n"))
        fh:close()
    end
    local function Start(t)
        t.part = OUT .. ".part_" .. t.prefab .. "_" .. t.i
        os.remove(t.part .. ".done")
        -- (what it says goes to a file: a pipe left unread fills up and stops it; done: a mark once
        -- it's over)
        -- (the longest, first: a core of its own - logical CPU 0, its twin 1 left idle; the rest kept
        -- off both. Sharing a core with another part it took 165 s, alone 80 - the whole run waited on
        -- it. SIM_NO_ISOLATE=1: as before)
        local aff = ""
        if isolate then
            if t == tasks[1] then
                aff = 'start "" /b /wait /affinity 1 '
                t.isolated = true
            else
                aff = string.format('start "" /b /wait /affinity %X ', 2 ^ slots - 1 - 3)
            end
        end
        local cmd = string.format('set "SIM_SCAN_CACHE=%s" & %s"%s" "%s" "%s" "%s" -only=%s#%d -raw%s > "%s.log" 2>&1 & echo.> "%s.done"', scan_path, aff, exe, arg[0], t.part, SCRIPTS,
            t.prefab, t.i, (CHECK and " -check" or "") .. (sim_rehit and " -ends" or ""), t.part, t.part)
        t.pipe = io.popen('"' .. cmd .. '"')
        t.began = Now()
        table.insert(running, t)
    end
    local function Done(t)
        local fh = io.open(t.part .. ".done", "rb")
        if fh ~= nil then fh:close() return true end
        return false
    end
    local function Finish(t)
        t.pipe:read("*a")
        t.pipe:close()
        os.remove(t.part .. ".done")
        took[Name(t)] = Now() - t.began
        local log = io.open(t.part .. ".log", "rb")
        if log ~= nil then
            for line in log:lines() do
                if not line:find("klaus.lua:269", 1, true) and not line:find("^written ") then io.stderr:write(line .. "\n") end
            end
            log:close()
            os.remove(t.part .. ".log")
        end
        local fh = assert(io.open(t.part, "rb"), "no part: " .. t.part)
        local text = fh:read("*a")
        fh:close()
        os.remove(t.part)
        local head = string.format("\n    [%q] = {\n", t.prefab)
        local s = text:find(head, 1, true)
        local e = s and text:find("\n    },\n", s, true)
        t.lines = s and e and text:sub(s + #head, e) or ""
        t.got = dofile(t.part .. ".haz")
        os.remove(t.part .. ".haz")
    end
    -- (what they set off, joined in the order they're listed - as one run does, whichever finished first)
    local function Merge(t)
        local got = t.got
        for k, v in pairs(got.move_random) do move_random[k] = move_random[k] or v end
        for k, v in pairs(got.shared_seen or {}) do
            local s = shared_seen[k] or { passed = 0, again = 0, fresh = 0, fresh_hit = 0 }
            shared_seen[k] = s
            for f, n in pairs(v) do s[f] = s[f] + n end
        end
        for prefab, p in pairs(got.hazards) do
            local hz = hazards[prefab]
            if hz == nil then
                hazards[prefab] = p
            elseif hz.boss ~= p.boss and OWN_HAZARDS[p.boss] then
                -- (another boss's own of the same: the first's kept - as one run does)
            elseif hz.scale ~= nil and p.scale ~= nil and math.abs(hz.scale - p.scale) > .01 then
                -- (another size of one drawn scaled: only how far it reached, as one run does)
                for _, s in ipairs(p.sizes or {}) do table.insert(hz.sizes, s) end
            else
                if hz.sizes ~= nil or p.sizes ~= nil then
                    hz.sizes = hz.sizes or {}
                    for _, s in ipairs(p.sizes or {}) do table.insert(hz.sizes, s) end
                    hz.scale = hz.scale or p.scale
                end
                for k, rel in pairs(p.cells) do hz.cells[k] = math.max(hz.cells[k] or rel, rel) end
                hz.delay = math.min(hz.delay or p.delay, p.delay or hz.delay)
                if p.delay_max ~= nil then hz.delay_max = math.max(hz.delay_max or p.delay_max, p.delay_max) end
                hz.moved = hz.moved or p.moved
                hz.flies = hz.flies or p.flies
                if p.aim ~= nil then hz.aim = math.max(hz.aim or 0, p.aim) end
                if p.glide ~= nil then hz.glide = math.max(hz.glide or 0, p.glide) end
                hz.lasting = hz.lasting or p.lasting
                for sig, n in pairs(p.pulse_sig or {}) do hz.pulse_sig = hz.pulse_sig or {} hz.pulse_sig[sig] = (hz.pulse_sig[sig] or 0) + n end
                hz.pulse_n = (hz.pulse_n or 0) + (p.pulse_n or 0)
                if p.as_boss then hz.as_boss = true hz.strikes_until = math.max(hz.strikes_until or 0, p.strikes_until or 0) end
                hz.burst = hz.burst or p.burst
                for k in pairs(p.kinds or {}) do hz.kinds = hz.kinds or {} hz.kinds[k] = true end
                hz.all_own = hz.all_own == true and p.all_own == true
                for from in pairs(p.from or {}) do hz.from = hz.from or {} hz.from[from] = true end
                if p.travel_min ~= nil then
                    hz.travel_min = math.min(hz.travel_min or p.travel_min, p.travel_min)
                    hz.travel_max = math.max(hz.travel_max or p.travel_max, p.travel_max)
                end
            end
        end
    end
    local t_all = Now()
    while next_task <= #tasks or #running > 0 do
        -- (while the one kept apart runs: two CPUs its own, the rest for the others)
        local in_use = #running
        for _, r in ipairs(running) do if r.isolated then in_use = in_use + 1 end end
        if next_task <= #tasks and in_use < slots then
            Start(tasks[next_task])
            next_task = next_task + 1
        else
            local any = false
            for i = #running, 1, -1 do
                if Done(running[i]) then
                    Finish(table.remove(running, i))
                    any = true
                end
            end
            if not any then ffi.C.Sleep(30) end
            -- (one going on far longer than it took last time - 5 times, 2 minutes at least: stuck,
            -- or something made it crawl (sorting every pairs once took the crystals 2 min -> 30+,
            -- every other core idle): all of them stopped, its name said, the whole run given up)
            for _, t in ipairs(running) do
                local limit = tonumber(os.getenv("SIM_JOB_LIMIT") or "") or math.max(120, 5 * (took[Name(t)] or 60))
                if Now() - t.began > limit then
                    io.stderr:write(string.format("TIMEOUT %s: %.0fs, past %.0fs (5 times the last run) - stopping every job, nothing written\n",
                        Name(t), Now() - t.began, limit))
                    for _, r in ipairs(running) do
                        os.execute('powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \\"Name=\'luajit.exe\'\\" | Where-Object { $_.CommandLine -like \'*'
                            .. r.part:gsub("[/\\]", "*") .. '*\' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }"')
                    end
                    os.exit(3)
                end
            end
        end
    end
    os.remove(scan_path)
    -- (how long each took: the order next time; the slowest, said)
    do
        local fh = io.open(TIMES, "wb")
        if fh ~= nil then
            fh:write("return {\n")
            local names = {}
            for n in pairs(took) do names[#names + 1] = n end
            table.sort(names)
            for _, n in ipairs(names) do fh:write(string.format("    [%q] = %.2f,\n", n, took[n])) end
            fh:write("}\n")
            fh:close()
        end
        table.sort(tasks, function(a, b) return (took[Name(a)] or 0) > (took[Name(b)] or 0) end)
        local slow = {}
        for i = 1, math.min(5, #tasks) do slow[#slow + 1] = string.format("%s %.0fs", Name(tasks[i]), took[Name(tasks[i])] or 0) end
        io.stderr:write(string.format("jobs: %d in %.0fs; slowest: %s\n", #tasks, Now() - t_all, table.concat(slow, ", ")))
        -- (back in the order they're written out in)
        table.sort(tasks, function(a, b)
            if a.order ~= b.order then return a.order < b.order end
            return a.i < b.i
        end)
        for _, t in ipairs(tasks) do Merge(t) end
    end
    local i = 1
    for _, def in ipairs(BOSSES) do
        table.insert(out, string.format("    [%q] = {", def.prefab))
        local names_used = {}  -- (as one run does: two begun alike both kept - the later renamed)
        while tasks[i] ~= nil and tasks[i].prefab == def.prefab do
            local lines = tasks[i].lines
            local spec = def.states[tasks[i].i]
            local statename = type(spec) == "table" and spec.name or spec
            lines = lines:gsub('\n        %["([^"]+)"%] = {', function(name)
                if names_used[name] then local base, k = name .. "~" .. tostring(statename), 2 name = base while names_used[name] do name = base .. "~" .. k k = k + 1 end end
                names_used[name] = true
                return string.format('\n        [%q] = {', name)
            end)
            lines = lines:gsub('^        %["([^"]+)"%] = {', function(name)
                if names_used[name] then local base, k = name .. "~" .. tostring(statename), 2 name = base while names_used[name] do name = base .. "~" .. k k = k + 1 end end
                names_used[name] = true
                return string.format('        [%q] = {', name)
            end)
            if lines ~= "" then table.insert(out, (lines:gsub("\n$", ""))) end
            i = i + 1
        end
        table.insert(out, "    },")
    end
    only = {}
end
for _, def in ipairs(BOSSES) do
    if only ~= nil and not only[def.prefab] then goto next_boss end    do
    local sg = LoadSG(def.sg)
    local about = GettingAbout(def.sg)
    -- (spec strikes_running: animations of a state tagged "moving" / "running" that strike all the same, with no "attack" tag
    -- - Shadow Wixie's charge, spearjab run at you, 75 to all within 2.9: keyed on the laugh after it instead, first -22)
    for _, an in ipairs(def.strikes_running or {}) do about[an] = nil end
    table.insert(out, string.format("    [%q] = {", def.prefab))
    -- (def.miss_area: its area struck round itself when a strike misses, as the game's DoAttack does -
    -- in the game's own world too, for this one: the shark's bite, 3 snaps round itself; VERIFY_PLAN 6.0a)
    boss_miss_area = def.miss_area or nil
    -- (how each of its moves shows: going on into one of them is another move)
    stop_at_anims = nil
    key_cut = nil
    if def.cut ~= nil then key_cut = {} for _, a in ipairs(def.cut) do key_cut[a] = true end end
    local stop_at = {}
    for _, spec in ipairs(def.states) do
        local statename = type(spec) == "table" and spec.name or spec
        spec_data = type(spec) == "table" and spec.data or nil
        spec_behind = type(spec) == "table" and spec.behind or nil
        spec_targets = type(spec) == "table" and spec.targets or nil
        spec_allhits = type(spec) == "table" and spec.all_hits or nil
        spec_apart = type(spec) == "table" and spec.things_apart or nil
        spec_setup = type(spec) == "table" and spec.setup or nil
        spec_fields = type(spec) == "table" and spec.fields or nil
        spec_lucky = type(spec) == "table" and spec.lucky or nil
        spec_lasttags = type(spec) == "table" and spec.lasttags or nil
        spec_still = type(spec) == "table" and spec.still or nil
        spec_frames = type(spec) == "table" and spec.frames or nil
        spec_prep = type(spec) == "table" and spec.prep or nil
        spec_dummy_player = def.dummy_player or nil
        spec_runs = type(spec) == "table" and spec.runs or nil
        sim_anim_held = nil
        spec_abort = type(spec) == "table" and spec.abort_turn or nil
        spec_extra = type(spec) == "table" and spec.extra or nil
        -- (spec noarg: gone into with no target handed on, as its own code goes into it - Uncompromising Mode's Deerclops
        -- swipe, never turned to you: drawn following you to frame 16, it swiped the way it faced)
        spec_noarg = type(spec) == "table" and spec.noarg or nil
        spec_sg = type(spec) == "table" and spec.sg ~= nil and LoadSG(spec.sg) or nil
        local ok, res = pcall(Run, def, sg, statename, 3, 1, nil, type(spec) == "table" and spec.mem or nil)
        local list = ok and KeyAnims(res, statename, about) or {}
        if list[1] ~= nil then stop_at[list[1]] = statename end
    end
    -- (and animations named to stop at: a combo's next blow, started its own way - re-aimed)
    for _, a in ipairs(def.stop or {}) do stop_at[a] = stop_at[a] or a end
    stop_at_anims = stop_at
    local names_used = {}  -- (two begun with the same animation - a leap and a stomp: both kept)
    for spec_i, spec in ipairs(def.states) do
        if type(only) == "table" and type(only[def.prefab]) == "table" and not only[def.prefab][spec_i] then goto next_move end
        do
        -- (a state, or { name, mem, data }: a later phase of it; what it's handed as it begins)
        local statename = type(spec) == "table" and spec.name or spec
        local mem = type(spec) == "table" and spec.mem or nil
        spec_data = type(spec) == "table" and spec.data or nil
        spec_behind = type(spec) == "table" and spec.behind or nil
        spec_targets = type(spec) == "table" and spec.targets or nil
        spec_allhits = type(spec) == "table" and spec.all_hits or nil
        spec_apart = type(spec) == "table" and spec.things_apart or nil
        spec_setup = type(spec) == "table" and spec.setup or nil
        spec_fields = type(spec) == "table" and spec.fields or nil
        spec_lucky = type(spec) == "table" and spec.lucky or nil
        spec_lasttags = type(spec) == "table" and spec.lasttags or nil
        spec_still = type(spec) == "table" and spec.still or nil
        spec_frames = type(spec) == "table" and spec.frames or nil
        spec_prep = type(spec) == "table" and spec.prep or nil
        spec_dummy_player = def.dummy_player or nil
        spec_runs = type(spec) == "table" and spec.runs or nil
        sim_anim_held = nil
        spec_abort = type(spec) == "table" and spec.abort_turn or nil
        spec_extra = type(spec) == "table" and spec.extra or nil
        -- (spec noarg: gone into with no target handed on, as its own code goes into it - Uncompromising Mode's Deerclops
        -- swipe, never turned to you: drawn following you to frame 16, it swiped the way it faced)
        spec_noarg = type(spec) == "table" and spec.noarg or nil
        spec_sg = type(spec) == "table" and spec.sg ~= nil and LoadSG(spec.sg) or nil
        -- (BENCH_LIST=<file>: each move run here, as the testbench (tr_testbench) is to start it in the real game -
        -- its state, handed its target or not (as its own code goes into it: AutoNoArg), the fields set and the
        -- setup called first; BENCH_LIST_ONLY: written, nothing run)
        if os.getenv("BENCH_LIST") ~= nil then
            local function Val(v)
                if type(v) == "string" then return string.format("%q", v) end
                if type(v) == "number" or type(v) == "boolean" then return tostring(v) end
                if type(v) == "table" then
                    local o = {}
                    for k2, v2 in pairs(v) do
                        if type(k2) == "string" and (type(v2) ~= "table" or next(v2) == nil) and type(v2) ~= "function" then o[#o + 1] = k2 .. " = " .. Val(v2) end
                    end
                    table.sort(o)
                    return "{ " .. table.concat(o, ", ") .. " }"
                end
                return "nil"
            end
            local noarg = spec_noarg
            if noarg == nil then noarg = AutoNoArg(def.prefab, def.sg, statename) end
            local fh = io.open(os.getenv("BENCH_LIST"), "ab")
            if fh ~= nil then
                fh:write(string.format("    { prefab = %q, state = %q, noarg = %s, setup = %s, fields = %s, mem = %s },\n", def.prefab, statename,
                    tostring(noarg == true), Val(spec_setup), Val(spec_fields or {}), Val(mem or {})))
                fh:close()
            end
            if os.getenv("BENCH_LIST_ONLY") ~= nil then goto next_move end
        end
        trace_tag, trace_n = def.prefab .. "#" .. spec_i, 0
        sim_goes_into = nil
        skip_thing_dummies, thing_runs = {}, {}
        -- (stop: this move's own animations to stop at - its next blow, only now and then: a move
        -- of its own (the Shadow Thrall mouth's bite after it lands); the others' as they are)
        stop_at_anims = stop_at
        if type(spec) == "table" and spec.stop ~= nil then
            stop_at_anims = {}
            for k, v in pairs(stop_at) do stop_at_anims[k] = v end
            for _, a in ipairs(spec.stop) do stop_at_anims[a] = a end
        end
        local spec_look = type(spec) == "table" and spec.look or nil
        -- (chase: it goes at its target again and again - bite after bite, each re-aimed: drawn as
        -- its strike round itself, towards its target, wherever it is, all along)
        local spec_chase = type(spec) == "table" and spec.chase or nil
        local spec_facing = type(spec) == "table" and spec.facing or nil
        local spec_lead = type(spec) == "table" and spec.lead or nil
        -- (ram: a charge its brain runs, not its stategraph - the Ancient Guardian's: { dist, time,
        -- aim }: it lines up on its target while it paws (aim seconds), then runs straight on, up to
        -- dist from where it began or for time seconds, goring whoever comes within its reach -
        -- its speed, reach and body as its prefab makes them; a lane of cells, struck as it gets there)
        local spec_ram = type(spec) == "table" and spec.ram or nil
        -- (fan: a breath swept to and fro ahead of it, flames thrown out round it - the Possessed
        -- Varg's: { from, to (how far its flames go out), angle (how far round either way), reach
        -- (each flame's, and your body), first (frame), lock (it stops turning), anims, again
        -- ({ until, anim, at }: struck again and again till then) }: one shape, all of it at once,
        -- red all the while it breathes - its flames coming and going all over, drawn each on its
        -- own, read as a mess)
        -- (spot: where it lands, as set when it sets off - the Slurper's leap: { ahead, radius, first,
        -- anims }: whoever's within radius of the spot ahead of where it began, the way it faced, at
        -- frame first; it doesn't turn as it goes. Run as it was, the way it went was picked by how far
        -- you were, sliding after you; round itself, a circle going along with it)
        if type(spec) == "table" and spec.spot ~= nil then
            local sp = spec.spot
            local quoted = {}
            for _, a in ipairs(sp.anims) do table.insert(quoted, string.format("%q", a)) end
            local cells = {}
            local R = sp.ahead + sp.radius + PAD
            for gx = -R, R, STEP do
                for gz = -R, R, STEP do
                    -- (lane: anywhere on its way - stopped by whoever's in it, it bites there)
                    local along = sp.lane and math.max(0, math.min(sp.ahead, gx)) or sp.ahead
                    -- (arc: only within arc/2 either way of the way it faces, from where it strikes - a hit arc)
                    local in_arc = sp.arc == nil or (gx == along and gz == 0)
                        or math.abs(math.atan2(-gz, gx - along) / DEGREES) * 2 <= sp.arc
                    if in_arc and (gx - along) ^ 2 + gz * gz <= (sp.radius + PAD) ^ 2 then cells[Key(gx, gz)] = true end
                end
            end
            -- (lock: the frame it stops turning to its target - drawn the way it faces till then)
            -- (single false: whoever it's after - what comes down round it comes down on anyone there)
            -- (cooldown: the timer it waits on, as a run's own entry says it)
            -- (random: where it may strike, not where it will - no part of it struck for sure, drawn pale, and none of it said
            -- "drawn in, not struck": the Celestial Champion's crystals, drawn all red at once and said "WELL INSIDE",
            -- one of them coming down at a time, the player's report 2026-10-20)
            table.insert(out, string.format("        [%q] = { anims = { %s }, first = %d, lock = %d, frame = \"facing\", random = %s, single = %s, scale = nil, ground = true, leg = nil%s, maps = {",
                sp.anims[1], table.concat(quoted, ", "), sp.first, sp.lock or 0, tostring(sp.random == true), tostring(sp.single ~= false),
                sp.cooldown ~= nil and string.format(", cooldown = %q", sp.cooldown) or ""))
            -- (its way, frame by frame - going from frame go[1] to go[2], all the way by then: it's known
            -- to go, not taken for one gone off its way and drawn from where it is)
            local path = {}
            for fr = 0, sp.first do
                local k = sp.go ~= nil and math.max(0, math.min(1, (fr - sp.go[1]) / (sp.go[2] - sp.go[1]))) or 0
                path[#path + 1] = string.format("%.2f", sp.ahead * k)
            end
            -- (until: and on striking somewhere in it till then - a second step, its last: the crystals coming down one by one)
            local packed = Pack(cells)
            local steps = string.format("{ at = %d, cells = %q }", sp.first, packed)
            if sp["until"] ~= nil then steps = steps .. string.format(", { at = %d, cells = %q }", sp["until"], packed) end
            table.insert(out, string.format("            { dist = 1, path = %q, steps = { %s } },", table.concat(path, ","), steps))
            table.insert(out, "        } },")
            goto next_move
        end
        if type(spec) == "table" and spec.fan ~= nil then
            local spec_fan = spec.fan
            local quoted = {}
            for _, a in ipairs(spec_fan.anims) do table.insert(quoted, string.format("%q", a)) end
            local cells = {}
            local R = spec_fan.to + spec_fan.reach + PAD
            for gx = -R, R, STEP do
                for gz = -R, R, STEP do
                    local hit = false
                    for a = -spec_fan.angle, spec_fan.angle, 3 do
                        local ca, sa = math.cos(a * DEGREES), math.sin(a * DEGREES)
                        -- (nearest point of that ray's flames, from .. to)
                        local along = math.max(spec_fan.from, math.min(spec_fan.to, gx * ca - gz * sa))
                        local fx, fz = along * ca, -along * sa
                        if (gx - fx) ^ 2 + (gz - fz) ^ 2 <= (spec_fan.reach + PAD) ^ 2 then hit = true break end
                    end
                    if hit then cells[Key(gx, gz)] = true end
                end
            end
            local ag = spec_fan.again
            table.insert(out, string.format("        [%q] = { anims = { %s }, first = %d, lock = %d, frame = \"facing\", random = false, single = true, scale = nil, anchor = \"lock\", still = true, ground = true, leg = nil, maps = {",
                spec_fan.anims[1], table.concat(quoted, ", "), spec_fan.first, spec_fan.lock))
            if ag ~= nil then
                table.insert(out, string.format("            { dist = 1, steps = { { at = %d, again_until = %d, again_anim = %q, again_at = %d, cells = %q } } },",
                    spec_fan.first, ag[1], ag[2], ag[3], Pack(cells)))
            else
                table.insert(out, string.format("            { dist = 1, steps = { { at = %d, cells = %q } } },", spec_fan.first, Pack(cells)))
            end
            table.insert(out, "        } },")
            goto next_move
        end
        if spec_ram ~= nil then
            Reset()
            local made = SpawnPrefab(def.prefab)
            local loco = rawget(made.components, "locomotor")
            local speed = spec_ram.speed or (loco ~= nil and loco.runspeed or 6)
            local combat = rawget(made.components, "combat")
            -- (how far its gore reaches: its attack range from its middle, and your body - it gores as
            -- its brain finds you that near (TryAttack), stopping dead; its hit range (1 more) only
            -- where it then strikes, a frame on - and you a frame's walk (.2) further off by then.
            -- Not its hit range: drawn 1 too wide all round, the Ancient Guardian's - every real
            -- gore of it in the kept logs within 4.24)
            local reach = (combat ~= nil and (combat.attackrange or combat.hitrange) or 3) + .5 + .2 + PAD
            -- (or as its spec says - one its stategraph flies, striking round itself: the Rabbit
            -- King's dropkick, its own reach (2) and your body; straight: its whole way whoever's where)
            if spec_ram.reach ~= nil then reach = spec_ram.reach + .5 + PAD end
            local aim_frames = math.floor(spec_ram.aim / FRAMES + .5)
            local full = math.min(spec_ram.dist, speed * spec_ram.time)
            local quoted = {}
            for _, a in ipairs(spec_ram.anims) do table.insert(quoted, string.format("%q", a)) end
            -- (fixed: how long it runs isn't up to where you are - one map per length it may be cut
            -- to by what's in its way (solid), its whole way when nothing is)
            -- (gore: its reach round itself, all the while it runs - it gores whoever comes within it,
            -- ahead of it or beside it, not only as it first gets there)
            table.insert(out, string.format("        [%q] = { anims = { %s }, first = %d, lock = %d, frame = \"target\", random = false, single = true, scale = nil, anchor = \"lock\", fixed = true, %ssolid = true, ground = true, speed = %.4g, gore = %.3g, leg = nil, maps = {",
                spec_ram.anims[1], table.concat(quoted, ", "), aim_frames, spec_ram.lock or aim_frames, (spec_ram.straight and "straight = true, " or "") .. (spec_ram.launch and string.format("launch = %g, ", spec_ram.launch) or "") .. (spec_ram.front and "front = true, " or ""), speed, reach))
            local lengths = {}
            for l = 0, math.floor(full) do lengths[#lengths + 1] = l end
            if lengths[#lengths] < full then lengths[#lengths + 1] = full end
            for _, length in ipairs(lengths) do
                local cells = {}
                -- (each spot: as soon as it's within reach of where it runs - round at both ends)
                for s = -reach, length + reach, STEP do
                    for w = -reach, reach, STEP do
                        local along = math.max(0, math.min(length, s))
                        if (s - along) ^ 2 + w * w <= reach * reach then
                            local first_at = math.max(0, s - math.sqrt(math.max(0, reach * reach - w * w)))
                            Earliest(cells, Key(s, w), aim_frames + math.floor(math.min(first_at, length) / speed / FRAMES + .5))
                        end
                    end
                end
                -- (its dist: how far it runs - its body's middle, to where it stops)
                table.insert(out, string.format("            { dist = %.4g, steps = %s },", length, Steps(cells)))
            end
            table.insert(out, "        } },")
            goto next_move
        end
        local boss_went = 0  -- the furthest the boss itself went from where it began, any run
        local set_until = nil  -- the last frame it set off something that strikes (random moves)
        move_puts = {}  -- (what those are: prefab -> true)
        move_effects = {}
        local moves_at = nil -- (the frame it first got going, from its first animation - soonest of any run)
        boss_solid, boss_through, boss_ground_went = 0, 0, 0
        local cooldown = nil -- (a timer it starts as it goes, a while long: its cooldown - the longest)
        local lock_maps = nil -- (anchored where it stops aiming: the maps seen from there - -check)
        local boss_scale = nil
        local first, last, maps, single, random = nil, nil, {}, nil, false
        local leg_lens, leg_durs = {}, {}
        local finish_cells, finish_anim, finish_until = {}, nil, 0
        local leg_anim, last_packed, leg_cells = nil, nil, {}
        local key_anim, key_frames = nil, nil
        SIM_KEY_LOOPED = nil  -- (a global: the main chunk holds all the locals it may)
        local only_target = true
        local leg_bank = nil
        local leg_gap = nil
        local around = {}   -- what its first strike hits, seen from where it was then (a chase: round itself)
        local kept = {}     -- per distance: each run's hits as it ran (to see again from where it stopped aiming)
        local sampled = {}  -- dist -> { packed, seen }
        -- (free: its target's body in nobody's way - it went off its path: a leap that stops at
        -- you goes its whole way then)
        local kept_free, sampled_free = {}, {}
        local leg_state_name = nil
        -- (one whose flight the dummies cut short - see SWEEP_MOVE below: runs again without them)
        SWEEP_MOVE, sweep_first_rel, sweep_state = false, nil, nil
        local function Sample(dist, free)
            local was_collide = COLLIDE
            if free then COLLIDE = false end
            local cells = {}
            local first_keys = nil
            local seen_dist, path = nil, nil
            local dist_runs = {}
            table.insert(free and kept_free or kept, { dist = dist, runs = dist_runs })
            -- (spec runs: more than RUNS_RANDOM for one scattered widely at random - Deerclops' ice spikes, 20-28 over a fan and
            -- behind it: 16 runs left gaps at the edges, 39 of their blows undrawn on the benches, 2026-10-21)
            local runs = RUNS
            local seed = 0
            -- (and one random with no runs told: RUNS_RANDOM more again, as long as the last lot still found
            -- 2% more cells (up to 8 lots) - the Moon Spider's spikes, 16 runs: its furthest out not drawn,
            -- 34 of 349 spikes, 2026-10-26. OLD_RANDOM_RUNS=1: RUNS_RANDOM only)
            local grown_at = nil
            local function More()
                if not random or spec_runs ~= nil or os.getenv("OLD_RANDOM_RUNS") ~= nil or runs >= RUNS_RANDOM * 8 then return false end
                local n = 0
                for _ in pairs(cells) do n = n + 1 end
                local more = grown_at == nil or n > grown_at * 1.02
                grown_at = n
                if more then runs = runs + RUNS_RANDOM end
                return more
            end
            while seed < runs or More() do
                seed = seed + 1
                NO_DUMMIES = SWEEP_MOVE
                -- (two runs - SIM_TWO_PASS: not one sweeping on (SWEEP_MOVE has its own))
                -- (the same seeds at every distance - what's left to chance picked alike at each, not
                -- one way at 2 and the other at 2.25: the Twins' charge 1365, 2823, 1367 cells by turns)
                -- (SIM_TRACEBACK=1: where it failed, the calls that led there - one line)
                -- (a run that failed inside a timeline step left it set: not carried into this one)
                sim_in_timeline = nil
                local ok, res = xpcall((TwoPassFor(def.prefab) and not SWEEP_MOVE) and TwoPassRun or Run,
                    os.getenv("SIM_TRACEBACK") and function(m)
                        -- (and what "v" was where it failed - which thing it was looking at)
                        local vv = ""
                        for i = 1, 60 do
                            local n, val = debug.getlocal(2, i)
                            if n == nil then break end
                            if n == "v" and type(val) == "table" then
                                local cs = {}
                                for cn, c in pairs(rawget(val, "components") or {}) do cs[#cs + 1] = cn .. (getmetatable(c) == PERMISSIVE and "*" or "") end
                                vv = " v=" .. tostring(rawget(val, "prefab")) .. (rawget(val, "is_dummy") and "(dummy)" or "") .. " [" .. table.concat(cs, ",") .. "]"
                            end
                        end
                        return tostring(m) .. vv .. " || " .. debug.traceback("", 2):gsub("\n%s*", " | "):sub(1, 900)
                    end or function(m) return m end,
                    def, sg, statename, dist,
                    seed * 7919 + ((os.getenv("SIM_OLD_SEED") ~= nil or os.getenv("SIM_DIST_SEED") ~= nil) and dist or 0),
                    (free and escape_at ~= nil) and { frame = escape_at, far = true } or nil, mem)
                NO_DUMMIES = false
                if not ok then
                    io.stderr:write(def.prefab .. " " .. statename .. ": " .. tostring(res) .. "\n")
                    break
                end
                if key_anim == nil then
                    key_anim, key_frames, SIM_KEY_LOOPED = KeyAnims(res, statename, about), res.anim_frame, res.anim_looped
                elseif os.getenv("SIM_ANIMSPLIT") ~= nil then
                    -- (SIM_ANIMSPLIT=1: a run further off begun with another animation - the move keyed by the nearest run's, the
                    -- other never drawn in the game (the Grim Harrier's pounce: "attack" from 1.8 off, "attack_quick" nearer))
                    local k2 = KeyAnims(res, statename, about)
                    if k2 ~= nil and k2[1] ~= nil and key_anim[1] ~= nil and k2[1] ~= key_anim[1] then
                        local seen_split = rawget(_G, "SIM_SPLIT_SEEN") or {}
                        rawset(_G, "SIM_SPLIT_SEEN", seen_split)
                        local sk = def.prefab .. "|" .. statename .. "|" .. k2[1]
                        if not seen_split[sk] then
                            seen_split[sk] = true
                            io.stderr:write(string.format("ANIMSPLIT %s %s: %s from %.2f off (keyed %s)\n", def.prefab, statename, k2[1], dist, key_anim[1]))
                        end
                    end
                end
                boss_scale = boss_scale or res.scale
                if res.boss_struck then leg_lens.boss_struck = true end
                if os.getenv("SIM_ALL_THINGS") == nil then
                    for tp, list in pairs(res.things or {}) do
                        local lasting, own = false, spec_allhits == true
                        for _, th in ipairs(list) do lasting = lasting or th.lasting own = own or th.own end
                        -- (only one that's none of the move's own cells - not where the boss's code strikes
                        -- round it: Deerclops' ice spikes are its move's, put down anew each run; and only in a move run
                        -- many times at random anyway (the crystals): one run once - its lance - is its whole shape)
                        if lasting and not own and random then thing_runs[tp] = (thing_runs[tp] or 0) + 1 if thing_runs[tp] >= THING_RUNS then skip_thing_dummies[tp] = true end end
                    end
                end
                -- (frames from when its first animation begins)
                local t0 = key_anim[1] ~= nil and res.anim_frame[key_anim[1]] or 0
                -- (and seen from where it stood then, the way it faced - a run-up before it, that
                -- looks like just getting about, is behind it by then: where it's seen to begin)
                local pose = key_anim[1] ~= nil and res.anim_pose[key_anim[1]] or nil
                pose = pose or { x = 0, z = 0, rot = 0, px = dist, pz = 0 }
                local pc, ps = math.cos(pose.rot * DEGREES), math.sin(pose.rot * DEGREES)
                local function Rel(x, z)
                    local dx, dz = x - pose.x, z - pose.z
                    return dx * pc - dz * ps, dx * ps + dz * pc
                end
                local function RelKey(x, z) return Key(Rel(x, z)) end
                if seed == 1 then
                    seen_dist = math.sqrt((pose.px - pose.x) ^ 2 + (pose.pz - pose.z) ^ 2)
                    -- (how far along it has gone, frame by frame from then, until it stops - one
                    -- whose length isn't told by where you are until it goes (Frostjaw's dive):
                    -- the game shows it once it's on its way)
                    path = {}
                    local n = 0
                    for f = t0, t0 + 90 do
                        local p = res.pose_at[f]
                        if p == nil then break end
                        local a = Rel(p.x, p.z)
                        path[#path + 1] = a
                        if #path == 1 or math.abs(a - path[#path - 1]) > .01 then n = #path end
                    end
                    for i = #path, n + 1, -1 do path[i] = nil end
                end
                if res.target_hit ~= nil and not free then single = math.max(single or 0, res.target_hit) end
                for n, secs in pairs(free and {} or res.boss_timers) do
                    if secs >= 2 and (cooldown == nil or secs > cooldown[2] or (secs == cooldown[2] and n < cooldown[1])) then cooldown = { n, secs } end
                end
                for f, p in pairs(free and {} or res.pose_at) do
                    local d = math.sqrt(p.x * p.x + p.z * p.z)
                    boss_went = math.max(boss_went, d)
                    if d > .3 and f - t0 >= 0 and (moves_at == nil or f - t0 < moves_at) then moves_at = f - t0 end
                end
                local kr = { pose_at = res.pose_at, pts = {}, discs = {} }
                table.insert(dist_runs, kr)
                for _, list in ipairs({ res.own, res.spread }) do
                    for d, h in pairs(list) do
                        table.insert(kr.pts, { d.x, d.z, h.frame - t0, LastOf(h, t0) })
                    end
                end
                for _, th in ipairs(res.target_hits) do
                    table.insert(kr.discs, { th.x, th.z, th.range + .5 + PAD, th.frame - t0, { th.frame - t0, th.anim, th.anim_at }, th.arc, th.rot })
                end
                -- (the same twice over, with nothing set off: nothing random in it - enough runs;
                -- not: more runs, to see all it may do)
                local keys = HitKeys(res.own, true)
                for d in pairs(res.spread) do keys[Key(d.x, d.z)] = true end
                if seed == 2 and free then
                    runs = random and (spec_runs or RUNS_RANDOM) or seed
                elseif seed == 2 then
                    if Same(first_keys, keys) then
                        runs = seed
                    else
                        random = true
                        runs = spec_runs or RUNS_RANDOM
                    end
                end
                first_keys = first_keys or keys
                if next(around) == nil and not free then
                    local f0 = nil
                    for _, h in pairs(res.own) do
                        if h.srot ~= nil and (f0 == nil or h.frame < f0) then f0 = h.frame end
                    end
                    for d, h in pairs(res.own) do
                        if h.frame == f0 then
                            local c, s = math.cos(h.srot * DEGREES), math.sin(h.srot * DEGREES)
                            local dx, dz = d.x - h.sx, d.z - h.sz
                            around[Key(dx * c - dz * s, dx * s + dz * c)] = true
                        end
                    end
                    -- (and all round it, close in: turned to its target as it strikes, one that close is
                    -- struck whichever way - true_range/predict turns it to you only from AROUND_NEAR
                    -- off, the way to you flipping about closer: Uncompromising Mode's Deerclops
                    -- uppercut, you 1.1 behind it as it turned round, struck, drawn the other way)
                    local far2 = 0
                    for k in pairs(around) do
                        local ax, az = KeyXZ(k)
                        far2 = math.max(far2, (ax * STEP) ^ 2 + (az * STEP) ^ 2)
                    end
                    if far2 > AROUND_NEAR * AROUND_NEAR then
                        for gx = -AROUND_NEAR, AROUND_NEAR + 1e-9, STEP do
                            for gz = -AROUND_NEAR, AROUND_NEAR + 1e-9, STEP do
                                if gx * gx + gz * gz <= AROUND_NEAR * AROUND_NEAR then around[Key(gx, gz)] = true end
                            end
                        end
                    end
                end
                -- (no dummies about, its flight not cut short: what it strikes round itself as it
                -- went (around), from its first strike on, at each frame until it stops or is pushed
                -- back - the Rabbit King's dropkick, its whole 12 with you off its way)
                if SWEEP_MOVE and sweep_first_rel ~= nil then
                    if os.getenv("SWEEP_DBG") and seed == 1 then
                        local np = 0
                        for _ in pairs(res.pose_at) do np = np + 1 end
                        io.stderr:write(string.format("SWEEPRUN dist=%s free=%s t0=%d rel=%d poses=%d at=%s\n", tostring(dist), tostring(free), t0, sweep_first_rel, np, tostring(res.pose_at[t0 + sweep_first_rel] ~= nil)))
                    end
                    local prevd = -1
                    for f = t0 + sweep_first_rel, t0 + 90 do
                        local p = res.pose_at[f]
                        if p == nil then break end
                        local d = math.sqrt((p.x - pose.x) ^ 2 + (p.z - pose.z) ^ 2)
                        if d < prevd - .05 then break end
                        prevd = math.max(prevd, d)
                        local c, s = math.cos(p.rot * DEGREES), math.sin(p.rot * DEGREES)
                        -- (struck on as it goes over: till this frame, in this animation - as a hit
                        -- struck again would say)
                        local an, an_at = nil, 0
                        for a, af in pairs(res.anim_frame) do
                            if af <= f and (an == nil or af > res.anim_frame[an]) then an = a end
                        end
                        if an ~= nil then an_at = f - res.anim_frame[an] end
                        local lst = { f - t0, an, an_at }
                        for k in pairs(around) do
                            local ia, is = KeyXZ(k)
                            local ah, sd = ia * STEP, is * STEP
                            local wx, wz = p.x + ah * c + sd * s, p.z - ah * s + sd * c
                            only_target = false
                            Earliest(cells, RelKey(wx, wz), f - t0, lst)
                        end
                        first = math.min(first or f, f)
                        last = math.max(last or f, f)
                    end
                    if os.getenv("SWEEP_DBG") and seed == 1 then
                        local nc = 0
                        for _ in pairs(cells) do nc = nc + 1 end
                        io.stderr:write(string.format("  cells %d prevd %.1f pose %.1f,%.1f rot %.0f\n", nc, prevd, pose.x, pose.z, pose.rot))
                    end
                end
                for d, h in pairs(res.own) do
                    only_target = false
                    if not SWEEP_MOVE and (sweep_first_rel == nil or h.frame - t0 < sweep_first_rel) then
                        sweep_first_rel = h.frame - t0
                        sweep_state = h.entry ~= nil and h.entry.name or h.boss_state
                    end
                    Earliest(cells, RelKey(d.x, d.z), h.frame - t0, LastOf(h, t0))
                    -- (struck by something it threw - the Scrappy Werepig's junk, come down in pieces the
                    -- ball let go: set as the boss let go of the ball, the first of the line)
                    if h.by ~= nil and not rawget(h.by, "is_sim_boss") and rawget(h.by, "spawn_frame") ~= nil then
                        local th, guard = h.by, 0
                        while th.spawned_by ~= nil and not rawget(th.spawned_by, "is_sim_boss") and rawget(th.spawned_by, "spawn_frame") ~= nil and guard < 8 do
                            th, guard = th.spawned_by, guard + 1
                        end
                        set_until = math.max(set_until or 0, rawget(th, "spawn_frame") - t0)
                        if th.prefab ~= nil then move_puts[th.prefab] = true end
                        if h.by.prefab ~= nil then move_puts[h.by.prefab] = true end
                    end
                    first = math.min(first or h.frame, h.frame)
                    last = math.max(last or h.frame, h.frame)
                end
                -- (where things it set off that stay put hit - crystals: all of it)
                for d, h in pairs(res.spread) do
                    only_target = false
                    Earliest(cells, RelKey(d.x, d.z), h.frame - t0, LastOf(h, t0))
                    -- (when what struck here was set off by the boss itself - a crystal's trap, put
                    -- down round where the boss stood then: after the last, where it may strike is fixed)
                    local th, guard = h.by, 0
                    while th ~= nil and th.spawned_by ~= nil and not rawget(th.spawned_by, "is_sim_boss") and guard < 8 do th, guard = th.spawned_by, guard + 1 end
                    -- (spawned_by none: put down by the boss's own code as it went - the deer's circles)
                    if th ~= nil and rawget(th, "spawn_frame") ~= nil then
                        set_until = math.max(set_until or 0, rawget(th, "spawn_frame") - t0)
                    end
                    if h.by ~= nil and h.by.prefab ~= nil then move_puts[h.by.prefab] = true end
                    first = math.min(first or h.frame, h.frame)
                    last = math.max(last or h.frame, h.frame)
                end
                -- (on its target only: round where it was when it struck - a leap lands first)
                for _, th in ipairs(res.target_hits) do
                    local r = th.range + .5 + PAD
                    local cx, cz = Rel(th.x, th.z)
                    for gx = cx - r, cx + r, STEP do
                        for gz = cz - r, cz + r, STEP do
                            local kx = math.floor(gx / STEP + .5) * STEP
                            local kz = math.floor(gz / STEP + .5) * STEP
                            -- (within its arc, the way it faced then, if it has one - SetHitArc above)
                            local in_arc = th.arc == nil or (kx == cx and kz == cz)
                                or math.abs((math.atan2(-(kz - cz), kx - cx) / DEGREES - ((th.rot or 0) - pose.rot) + 540) % 360 - 180) * 2 <= th.arc
                            if in_arc and (kx - cx) ^ 2 + (kz - cz) ^ 2 <= r * r then
                                Earliest(cells, Key(kx, kz), th.frame - t0, { th.frame - t0, th.anim, th.anim_at })
                            end
                        end
                    end
                    first = math.min(first or th.frame, th.frame)
                    last = math.max(last or th.frame, th.frame)
                end
                for prefab, list in pairs(free and {} or res.things) do
                    local hz = hazards[prefab] or { cells = {}, boss = def.prefab }
                    hazards[prefab] = hz
                    -- (one several bosses set off, each its own size - a laser, ice spikes: a boss
                    -- marked own_hazards adds nothing to another's, as it's drawn round the thing
                    -- alone, not knowing whose it is)
                    if hz.boss ~= def.prefab and def.own_hazards then list = {} end
                    -- (one drawn bigger the further it reaches - a pound's ring: each size seen, how far
                    -- it reached then; the cells only of the first, drawn scaled from that)
                    local sc = list[1] ~= nil and list[1].scale or nil
                    if sc ~= nil then
                        local reach = 0
                        for _, p in ipairs(list) do reach = math.max(reach, math.sqrt(p[1] ^ 2 + p[2] ^ 2)) end
                        hz.sizes = hz.sizes or {}
                        table.insert(hz.sizes, { sc, reach })
                        if hz.scale == nil then hz.scale = sc elseif math.abs(hz.scale - sc) > .01 then list = {} end
                    end
                    for _, p in ipairs(list) do
                        local k = Key(p[1], p[2])
                        -- (a cell two spikes cover is in danger until the later one rose)
                        hz.cells[k] = math.max(hz.cells[k] or p.rel, p.rel)
                        hz.delay = math.min(hz.delay or p.delay, p.delay)
                        -- (and the latest - a lot put down at once going off one after another: the Eye's laser)
                        hz.delay_max = math.max(hz.delay_max or p.delay, p.delay)
                        hz.moved = hz.moved or p.moved
                        hz.flies = hz.flies or p.flies
                        if p.aim ~= nil then hz.aim = math.max(hz.aim or 0, p.aim) end
                        if p.glide ~= nil then hz.glide = math.max(hz.glide or 0, p.glide) end
                        hz.lasting = hz.lasting or p.lasting
                        -- (struck again in the same cells after the first, how much later - each cell's,
                        -- counted: "again" only if nearly all say the same; VERIFY_PLAN 6.12b)
                        if p.as_boss then
                            hz.as_boss = true
                            hz.strikes_until = math.max(hz.strikes_until or 0, p.last_age or 0)
                        end
                        if p.pulses ~= nil then
                            local sig = table.concat(p.pulses, ",")
                            hz.pulse_sig = hz.pulse_sig or {}
                            hz.pulse_sig[sig] = (hz.pulse_sig[sig] or 0) + 1
                            hz.pulse_n = (hz.pulse_n or 0) + 1
                        end
                        hz.burst = hz.burst or p.burst
                        for k in pairs(p.kinds or {}) do hz.kinds = hz.kinds or {} hz.kinds[k] = true end
                        -- (all it strikes counted in the move too - a laser's blasts: drawn with it)
                        hz.all_own = hz.all_own ~= false and p.own == true
                        hz.from = hz.from or {}
                        hz.from[def.prefab .. "/" .. statename] = true
                        if p.travel ~= nil then
                            hz.travel_min = math.min(hz.travel_min or p.travel, p.travel)
                            hz.travel_max = math.max(hz.travel_max or p.travel, p.travel)
                        end
                    end
                end
                -- (a state it goes into again and again, each time carried well on - rolls, not a
                -- combo's lunges: legs)
                local leg_state = nil
                for name, d in pairs(free and {} or res.legs) do
                    if os.getenv("DBGLEGS") then io.stderr:write(string.format("legs %s %s: %s\n", def.prefab, name, table.concat(d, ","))) end
                    local long = 0
                    for _, len in ipairs(d) do
                        if len >= LEG_MIN then long = long + 1 end
                    end
                    if long >= 2 then
                        leg_state = name
                        leg_state_name = name
                        -- (how many it goes, every run: the fewest - the Scion's dash, twice)
                        leg_lens.count = math.min(leg_lens.count or long, long)
                        local prev_dir = nil
                        for i, len in ipairs(d) do
                            if len >= LEG_MIN then
                                -- (turned 20 degrees or more from the one before: it aims anew each)
                                local dir = d.dirs ~= nil and d.dirs[i] or nil
                                if dir ~= nil and prev_dir ~= nil then
                                    local diff = math.abs((dir - prev_dir + math.pi) % (2 * math.pi) - math.pi)
                                    if diff >= 20 * DEGREES then leg_lens.turns = true end
                                end
                                prev_dir = dir or prev_dir
                                table.insert(leg_lens, len)
                                table.insert(leg_durs, (res.legs_dur[name] or {})[i] or 0)
                            end
                        end
                    end
                end
                -- (and how its legs end - a slide, a slam: hits in the state after them, seen from
                -- where that began)
                if leg_state ~= nil then
                    leg_anim = res.state_anim[leg_state] or leg_anim
                    leg_bank = res.bank
                    -- (how long it stands between one leg and the next - turning to its target)
                    local sp = res.spans[leg_state] or {}
                    for i = 2, #sp do
                        leg_gap = math.max(leg_gap or 0, sp[i][1] - sp[i - 1][2])
                    end
                    for d, h in pairs(res.own) do
                        local e = h.entry
                        -- (one leg's hits, seen from where that leg set off)
                        if e ~= nil and e.name == leg_state then
                            local c, s = math.cos(e.rot * DEGREES), math.sin(e.rot * DEGREES)
                            local dx, dz = d.x - e.x, d.z - e.z
                            leg_cells[Key(dx * c - dz * s, dx * s + dz * c)] = true
                        end
                        -- (struck again as it ends, first struck on its way: that ending's too)
                        for _, en in ipairs(h.entries or {}) do
                            local e2, f2 = en[1], en[2]
                            if e2 ~= e and e2.name ~= leg_state and e2.name ~= statename then
                                local c, s = math.cos(e2.rot * DEGREES), math.sin(e2.rot * DEGREES)
                                local dx, dz = d.x - e2.x, d.z - e2.z
                                finish_cells[Key(dx * c - dz * s, dx * s + dz * c)] = true
                                finish_anim = res.state_anim[e2.name] or finish_anim
                                finish_until = math.max(finish_until, f2 - e2.frame)
                            end
                        end
                        if e ~= nil and e.name ~= leg_state and e.name ~= statename then
                            local c, s = math.cos(e.rot * DEGREES), math.sin(e.rot * DEGREES)
                            local dx, dz = d.x - e.x, d.z - e.z
                            finish_cells[Key(dx * c - dz * s, dx * s + dz * c)] = true
                            finish_anim = res.state_anim[e.name] or finish_anim
                            finish_until = math.max(finish_until, h.frame - e.frame)
                            -- (and how far on it goes, frame by frame from where that began - in the
                            -- game, stopped short (the Celestial Champion's roll ending against you), it
                            -- strikes where it got to: drawn back as far as it's behind this)
                            if leg_lens.finish_path == nil then
                                local finish_path = {}
                                leg_lens.finish_path = finish_path
                                local n = 0
                                for f = e.frame, e.frame + 90 do
                                    local p = res.pose_at[f]
                                    if p == nil then break end
                                    finish_path[#finish_path + 1] = (p.x - e.x) * c - (p.z - e.z) * s
                                    if #finish_path == 1 or math.abs(finish_path[#finish_path] - finish_path[#finish_path - 1]) > .01 then n = #finish_path end
                                end
                                for i = #finish_path, n + 1, -1 do finish_path[i] = nil end
                            end
                        end
                    end
                end
            end
            -- (packed by when they're hit; the same as the distance before: said so)
            -- (how far its target was as the move was seen to begin - nearer, after a run-up)
            COLLIDE = was_collide
            ;(free and sampled_free or sampled)[dist] = { packed = Steps(cells), seen = seen_dist or dist, cells = cells, path = path }
            if os.getenv("SWEEP_DBG") and SWEEP_MOVE then local nc = 0 for _ in pairs(cells) do nc = nc + 1 end io.stderr:write(string.format("STORE dist=%s free=%s cells=%d packed=%s\n", tostring(dist), tostring(free), nc, tostring((free and sampled_free or sampled)[dist].packed):sub(1, 80))) end
            if free then return end
            if SHOW and (dist == 3 or dist == 5 or dist == 11) then
                local _, count = Rows(cells)
                Show(string.format("%s %s%s, target %d ahead: %d cells", def.prefab, statename,
                    mem and " (later phase)" or "", dist, count), cells, dist)
            end
        end
        -- (roughly first; then, between two distances that look different, the one between -
        -- on down to STEP_DIST: fine only where the shape changes with the distance)
        -- (far: a boss that reaches you further off - a Shadow Rook teleporting onto you)
        local dists = {}
        for _, d in ipairs(DISTANCES) do table.insert(dists, d) end
        for d = #DISTANCES + 1, def.far or 0 do table.insert(dists, d) end
        for _, dist in ipairs(dists) do Sample(dist) end
        local todo = {}
        for i = 2, #dists do table.insert(todo, { dists[i - 1], dists[i] }) end
        while #todo > 0 do
            local span = table.remove(todo)
            local a, b = span[1], span[2]
            if b - a > STEP_DIST + 1e-6 and sampled[a] ~= nil and sampled[b] ~= nil
                and sampled[a].packed ~= sampled[b].packed then
                local m = (a + b) / 2
                Sample(m)
                table.insert(todo, { a, m })
                table.insert(todo, { m, b })
            end
        end
        -- (its flight cut short by the dummies all about - the Rabbit King's dropkick stops at the
        -- first it strikes, a step in front of it: drawn 5 long, it flew 12. Run once with none but
        -- its target, far off: gone well further - each run again so, and what it strikes round
        -- itself laid along its way)
        if not random and next(around) ~= nil and sweep_first_rel ~= nil and sweep_state ~= nil then
            -- (its target where it was, 16 off, both ways: only the dummies told apart - not a chase
            -- after a target run off, on and on; and how far it went in the state it first struck in
            -- - not a combo going on further, its target still ahead (the vault guard's))
            local function StateWent(res)
                local m = 0
                for _, s in ipairs(res.spans[sweep_state] or {}) do
                    local p0, p1 = res.pose_at[s[1]] or res.pose_at[s[1] - 1], res.pose_at[s[2] - 1]
                    if p0 ~= nil and p1 ~= nil then m = math.max(m, math.sqrt((p1.x - p0.x) ^ 2 + (p1.z - p0.z) ^ 2)) end
                end
                return m
            end
            NO_DUMMIES = true
            local okc, rc = pcall(Run, def, sg, statename, 16, 7919, nil, mem)
            NO_DUMMIES = false
            local okn, rn = pcall(Run, def, sg, statename, 16, 7919, nil, mem)
            local went = okc and StateWent(rc) or 0
            local normal_went = okn and StateWent(rn) or boss_went
            if os.getenv("SWEEP_DBG") then io.stderr:write(string.format("SWEEPCHK %s %s (%s): clear %.1f, with dummies %.1f\n", def.prefab, statename, tostring(sweep_state), went, normal_went)) end
            if went > normal_went + 2 and went > 4 then
                if DBG or os.getenv("SWEEP_DBG") then io.stderr:write(string.format("SWEEP %s %s: went %.1f, %.1f with dummies\n", def.prefab, statename, went, normal_went)) end
                local redo = {}
                for d in pairs(sampled) do redo[#redo + 1] = d end
                table.sort(redo)
                SWEEP_MOVE = true
                kept, sampled = {}, {}
                for _, dist in ipairs(redo) do Sample(dist) end
            end
        end
        -- (what it puts down, put on every player in reach at once? - the Klaus deer's spells: one
        -- more player standing off to its side, this far from it; as far as it still goes for them)
        multi_reach = nil
        if true then
            for _, r in ipairs({ 4, 8, 12, 16 }) do
                rawset(_G, "EXTRA_PLAYER", { 0, r })
                local okm, rm = pcall(Run, def, sg, statename, 8, 7919, nil, mem)
                rawset(_G, "EXTRA_GHOST", true)
                local okg, rg = pcall(Run, def, sg, statename, 8, 7919, nil, mem)
                rawset(_G, "EXTRA_GHOST", nil) rawset(_G, "EXTRA_PLAYER", nil)
                if okm and rm.extra_put and not (okg and rg.extra_put) then multi_reach = r end
                if os.getenv("SWEEP_DBG") then io.stderr:write(string.format("MULTICHK %s %s r=%d player=%s ghost=%s %s\n", def.prefab, statename, r, tostring(okm and rm.extra_put), tostring(okg and rg.extra_put), tostring(not okg and rg or ''))) end
            end
            if multi_reach ~= nil and os.getenv("SWEEP_DBG") then io.stderr:write(string.format("MULTI %s %s: %d\n", def.prefab, statename, multi_reach)) end
        end
        table.sort(kept, function(p, q) return p.dist < q.dist end)
        local dists = {}
        for d in pairs(sampled) do table.insert(dists, d) end
        table.sort(dists)
        local function PlainMaps(from)
            local list, cells_list, last_p = {}, {}, nil
            for _, dist in ipairs(dists) do
                local sm = from[dist]
                if sm ~= nil then
                    local shown_dist = string.format("%.4g", math.floor(sm.seen * 100 + .5) / 100)
                    -- (how far it goes, frame by frame - nowhere, for one that stands: shoved, it strikes where it is)
                    local path = ""
                    if sm.path ~= nil and #sm.path > 0 then
                        local nums = {}
                        for i, a in ipairs(sm.path) do nums[i] = string.format("%.2f", a) end
                        path = string.format(", path = %q", table.concat(nums, ","))
                    end
                    if sm.packed == last_p then
                        table.insert(list, string.format("{ dist = %s, same = true%s }", shown_dist, path))
                    else
                        table.insert(list, string.format("{ dist = %s, steps = %s%s%s }", shown_dist, sm.packed, path, EndsOf(sm.cells)))
                    end
                    table.insert(cells_list, { dist = sm.seen, cells = sm.cells })
                    last_p = sm.packed
                end
            end
            return list, cells_list
        end
        maps = PlainMaps(sampled)
        -- (and with its target out of its way - it goes on past where they stood: only if that
        -- comes out otherwise; the game picks by whether you stand in its way)
        local free_maps, free_cells = nil, nil
        local free_reach = nil
        if boss_went >= .1 then
            for _, dist in ipairs(dists) do Sample(dist, true) end
            table.sort(kept_free, function(p, q) return p.dist < q.dist end)
            local differs = false
            for _, dist in ipairs(dists) do
                if sampled_free[dist] ~= nil and sampled_free[dist].packed ~= sampled[dist].packed then differs = true end
            end
            if differs then free_maps, free_cells = PlainMaps(sampled_free) end
        end
        -- (its animations up to its last hit, and the one after - not what it does once it's done,
        -- a taunt)
        if key_anim ~= nil and last ~= nil then
            local kept, after = {}, false
            for _, a in ipairs(key_anim) do
                if (key_frames[a] or 0) <= last then
                    table.insert(kept, a)
                elseif not after then
                    table.insert(kept, a)
                    after = true
                end
            end
            key_anim = kept
        end
        if key_anim ~= nil and key_cut ~= nil then
            for i = #key_anim, 2, -1 do
                if key_cut[key_anim[i]] then table.remove(key_anim, i) end
            end
        end
        if key_anim ~= nil and #key_anim > 0 and last ~= nil then
            local quoted = {}
            for _, a in ipairs(key_anim) do table.insert(quoted, string.format("%q", a)) end
            local lock = LockFrame(def, sg, statename, last, mem)
            if DBG then io.stderr:write(string.format("%s %s: lock %s first %s last %s t0 %s\n", def.prefab, statename, tostring(lock), tostring(first), tostring(last), tostring(t0))) end
            -- (still following it at its last hit: it never stops)
            -- (unless it stopped as its first hit came, and what it set going strikes on after - a
            -- beam reaching further frame by frame, the Scrappy Werepig's cannon)
            if lock ~= nil and lock >= last - LOCK_STEP and not (lock <= first and last > first) then lock = nil end
            if spec_chase then lock = nil end
            -- (spec lock: when it stops turning, as seen in the game - the Crab Knight turns to you again
            -- as its spin sets off (frame 14), not run so here)
            if type(spec) == "table" and spec.lock ~= nil then lock = spec.lock end
            -- (one that stops as it reaches its target by its own say, not bumping into them - the
            -- Scrappy Werepig's tackle: its target out of its reach once it stops aiming, it goes its
            -- whole way - drawn so with you off its way, as one your body stops)
            if free_maps == nil and lock ~= nil and boss_went >= .1 and not random then
                escape_at = lock
                kept_free, sampled_free = {}, {}
                for _, dist in ipairs(dists) do Sample(dist, true) end
                escape_at = nil
                table.sort(kept_free, function(p, q) return p.dist < q.dist end)
                local differs = false
                for _, dist in ipairs(dists) do
                    if sampled_free[dist] ~= nil and sampled_free[dist].packed ~= sampled[dist].packed then differs = true end
                end
                if differs then
                    free_maps, free_cells = PlainMaps(sampled_free)
                    -- (how far off its way you still stop it - it goes for you that far round: its
                    -- target that far to its side, well ahead, and it stops short of its whole way)
                    local function Went(pose_at)
                        local m = 0
                        for _, p in pairs(pose_at) do m = math.max(m, math.sqrt(p.x * p.x + p.z * p.z)) end
                        return m
                    end
                    local full = nil
                    NO_DUMMIES = SWEEP_MOVE
                    local okf, rf = pcall(Run, def, sg, statename, 16, 7919, { frame = lock, far = true }, mem)
                    if okf then full = Went(rf.pose_at) end
                    for s = .5, 8, .25 do
                        if full == nil then break end
                        local ok, res = pcall(Run, def, sg, statename, 16, 7919,
                            { frame = math.max(0, lock - 1), side = s, ahead = 10 }, mem)
                        if not ok or Went(res.pose_at) >= full - .5 then break end
                        free_reach = s
                    end
                    NO_DUMMIES = false
                end
            end
            -- (one that chases on until something else stops it - the run never got that far: how
            -- it winds down, too - the Celestial Champion's spin still strikes as it stops)
            if lock == nil and next(around) ~= nil then
                local made = SpawnPrefab(def.prefab)
                local h = type(made.bank) == "string" and KleiHash(made.bank) or nil
                local have = {}
                for _, a in ipairs(key_anim) do have[a] = true end
                for _, a in ipairs({ unpack(key_anim) }) do
                    local pst = (a:match("^(.*)_loop$") or "~") .. "_pst"
                    if not have[pst] and h ~= nil and not (key_cut ~= nil and key_cut[pst]) then
                        for _, anims in pairs(ANIM_FILES) do
                            if anims[pst] ~= nil and anims._banks ~= nil and anims._banks[pst] == h then
                                table.insert(key_anim, pst)
                                table.insert(quoted, string.format("%q", pst))
                                have[pst] = true
                                break
                            end
                        end
                    end
                end
            end
            local frame, snaps
            frame, snaps, move_snap_anim = FrameOf(def, sg, statename, math.max(0, (lock or first) - 6), mem)
            -- (it stopped aiming before the move is seen to begin - set going on a run-up: the way
            -- it faces then is all the game has to go by, where you are by then is no use)
            if lock ~= nil and lock < (key_frames[key_anim[1]] or 0) then frame = "facing" end
            -- (facing: it goes the way it faces, turning to you only so fast - Frostjaw's dive, as
            -- far as you are, the way it has come round to by then)
            if spec_facing then frame = "facing" end
            -- (spec frame: said by hand - what it sets off aimed at where you stood, its own blow round itself
            -- the same any way it faces, so the test above saw no turn: Uncompromising Mode's Bearger, its
            -- sinkholes on a line to you)
            if type(spec) == "table" and spec.frame ~= nil then frame = spec.frame end
            -- (all its damage after it stops aiming: seen from where it stands and faces then - it
            -- may have gone round on the way (the Werepig's slam, turning after you), and how far
            -- its target is from there)
            local anchor = ""
            -- (not random ones: tried 2026-10-26 (SIM_RANDOM_ANCHOR=1) for the Moon Spider's spikes round where you were
            -- as it began - the 9 such moves on the bench no better, the Moon Spider's gaps its runs' (More, below))
            if lock ~= nil and first ~= nil and first >= lock and #leg_lens < 2 and (not random or os.getenv("SIM_RANDOM_ANCHOR") ~= nil) then
                anchor = ", anchor = \"lock\""
                local function LockMaps(kept)
                local lock_maps, maps, last_packed = {}, {}, nil
                for _, kd in ipairs(kept) do
                    local cells, sd = {}, nil
                    local lpath = nil
                    for _, kr in ipairs(kd.runs) do
                        -- (stopped aiming before the move is seen to begin - on its run-up: as the game
                        -- sees it, from where it is as it begins)
                        local at_f = math.max(lock, key_frames[key_anim[1]] or 0)
                        local p = kr.pose_at[at_f] or kr.pose_at[#kr.pose_at] or { x = 0, z = 0, rot = 0, px = kd.dist, pz = 0 }
                        sd = sd or math.sqrt((p.px - p.x) ^ 2 + (p.pz - p.z) ^ 2)
                        local pc, ps = math.cos(p.rot * DEGREES), math.sin(p.rot * DEGREES)
                        local function Rel(x, z)
                            local dx, dz = x - p.x, z - p.z
                            return dx * pc - dz * ps, dx * ps + dz * pc
                        end
                        -- (how far along it went, frame by frame from its first animation, seen from
                        -- there: as SimMoves.Draw goes by it - see Sample)
                        if lpath == nil then
                            lpath = {}
                            local k0, n = key_frames[key_anim[1]] or 0, 0
                            for f = k0, k0 + 90 do
                                local q = kr.pose_at[f]
                                if q == nil then break end
                                lpath[#lpath + 1] = Rel(q.x, q.z)
                                if #lpath == 1 or math.abs(lpath[#lpath] - lpath[#lpath - 1]) > .01 then n = #lpath end
                            end
                            for i = #lpath, n + 1, -1 do lpath[i] = nil end
                        end
                        for _, q in ipairs(kr.pts) do Earliest(cells, Key(Rel(q[1], q[2])), q[3], q[4]) end
                        for _, q in ipairs(kr.discs) do
                            local cx, cz = Rel(q[1], q[2])
                            local r = q[3]
                            for gx = cx - r, cx + r, STEP do
                                for gz = cz - r, cz + r, STEP do
                                    local kx = math.floor(gx / STEP + .5) * STEP
                                    local kz = math.floor(gz / STEP + .5) * STEP
                                    local in_arc = q[6] == nil or (kx == cx and kz == cz)
                                        or math.abs((math.atan2(-(kz - cz), kx - cx) / DEGREES - ((q[7] or 0) - p.rot) + 540) % 360 - 180) * 2 <= q[6]
                                    if in_arc and (kx - cx) ^ 2 + (kz - cz) ^ 2 <= r * r then Earliest(cells, Key(kx, kz), q[4], q[5]) end
                                end
                            end
                        end
                    end
                    local packed = Steps(cells)
                    table.insert(lock_maps, { dist = sd or kd.dist, cells = cells })
                    local shown = string.format("%.4g", math.floor((sd or kd.dist) * 100 + .5) / 100)
                    local path = ""
                    if lpath ~= nil and #lpath > 0 then
                        local nums = {}
                        for i, a in ipairs(lpath) do nums[i] = string.format("%.2f", a) end
                        path = string.format(", path = %q", table.concat(nums, ","))
                    end
                    if packed == last_packed then
                        table.insert(maps, string.format("{ dist = %s, same = true%s }", shown, path))
                    else
                        table.insert(maps, string.format("{ dist = %s, steps = %s%s%s }", shown, packed, path, EndsOf(cells)))
                    end
                    last_packed = packed
                end
                return maps, lock_maps
                end
                maps, lock_maps = LockMaps(kept)
                if free_maps ~= nil then free_maps, free_cells = LockMaps(kept_free) end
            end
            -- (laid out the way it faces, its target well off to its side: how far it goes then -
            -- the map whose run went as far (its full way, or as short as it goes - Frostjaw's
            -- dive goes as far along as you are, 2 at least))
            local off, off_cone, off_back = nil, nil, nil
            -- (one with free maps: you off its way, that's what's drawn already)
            if frame == "facing" and boss_went >= .5 and #kept > 0 and free_maps == nil then
                -- (up to its last strike - not swimming off after; from where its first animation begins - not
                -- swimming up to there first)
                local k0w = key_frames[key_anim[1]] or 0
                local function Went(pose_at)
                    local m = 0
                    local o = pose_at[k0w] or { x = 0, z = 0 }
                    for f, p in pairs(pose_at) do
                        if f >= k0w and (last == nil or f <= last) then m = math.max(m, math.sqrt((p.x - o.x) ^ 2 + (p.z - o.z) ^ 2)) end
                    end
                    return m
                end
                -- (there as it last aims - from the start, if it never stops)
                spec_side = (lock == nil or lock == 0) or nil
                local ok, res = pcall(Run, def, sg, statename, SIDE_DIST, 7919,
                    (lock ~= nil and lock > 0) and { frame = lock - 1, side = SIDE_DIST } or nil, mem)
                spec_side = nil
                if ok then
                    local w, best = Went(res.pose_at), nil
                    for i, kd in ipairs(kept) do
                        local d = math.abs(Went(kd.runs[1].pose_at) - w)
                        if best == nil or d < best[2] - .05 then best = { i, d } end
                    end
                    -- (as far as its full way - the furthest run: nothing to say)
                    if math.abs(Went(kept[#kept].runs[1].pose_at) - w) > .3 then
                        local kd = kept[best[1]]
                        off = lock_maps ~= nil and lock_maps[best[1]].dist or sampled[kd.dist].seen
                        -- (how far round it still turns to you: you that far off its way as it last
                        -- aims, it goes as far as for you straight ahead that far on - past that it
                        -- lets you go, going by where it last had you (Frostjaw: 45 degrees))
                        -- (you behind it as it last aims, as far back as straight ahead it goes for you:
                        -- it goes as far for you behind as in front - Frostjaw's "math.abs")
                        if lock ~= nil and lock > 0 then
                            local okb, rb = pcall(Run, def, sg, statename, SIDE_DIST / 2, 7919,
                                { frame = lock - 1, side = 0, ahead = -SIDE_DIST }, mem)
                            -- (against: straight ahead that far as it last aims - put there the same way)
                            local okf, rf = pcall(Run, def, sg, statename, SIDE_DIST / 2, 7919,
                                { frame = lock - 1, side = 0, ahead = SIDE_DIST }, mem)
                            if okb and okf and math.abs(Went(rb.pose_at) - Went(rf.pose_at)) <= .3 then off_back = true end
                        end
                        if lock ~= nil and lock > 0 then
                            for ang = 10, 80, 10 do
                                local a = ang * DEGREES
                                local ahead, side = SIDE_DIST * math.cos(a), SIDE_DIST * math.sin(a)
                                -- (where it had you before: nearer - kept, if it lets you go)
                                local ok1, r1 = pcall(Run, def, sg, statename, SIDE_DIST / 2, 7919,
                                    { frame = lock - 1, side = side, ahead = ahead }, mem)
                                local ok2, r2 = pcall(Run, def, sg, statename, ahead, 7919, nil, mem)
                                local ok3, r3 = pcall(Run, def, sg, statename, SIDE_DIST / 2, 7919,
                                    { frame = lock - 1, side = 0, ahead = SIDE_DIST }, mem)
                                -- (turned round to you, as far as you are - not let go, gone as far along as
                                -- you were as it did)
                                if not (ok1 and ok3) or math.abs(Went(r1.pose_at) - Went(r3.pose_at)) > .3 then break end
                                off_cone = ang + 5
                            end
                        end
                    end
                end
            end
            -- (its far edge goes on as far as its target is, map after map - a leap landing on you, a
            -- spell cast where you stand: as far as that holds - a map for another distance, until
            -- it's made, is drawn moved on by the difference)
            local follow = nil
            if not random then
                local list = {}
                if lock_maps ~= nil then
                    for _, m in ipairs(lock_maps) do list[#list + 1] = { m.dist, m.cells } end
                else
                    for _, d in ipairs(dists) do list[#list + 1] = { sampled[d].seen, sampled[d].cells } end
                end
                table.sort(list, function(p, q) return p[1] < q[1] end)
                -- (its near edge too: all of it moved on, not stretched out - Frostjaw's coming up stays
                -- round it while its landing goes on with you; a leap's way starts at it)
                local function Far(cells)
                    local m, n = nil, nil
                    for k in pairs(cells) do
                        local a = KeyXZ(k)
                        if m == nil or a > m then m = a end
                        if n == nil or a < n then n = a end
                    end
                    return m and m * STEP or nil, n and n * STEP or nil
                end
                local prev_d, prev_f, prev_n, run_from = nil, nil, nil, nil
                for _, e in ipairs(list) do
                    local f, n = Far(e[2])
                    -- (a whole unit apart at least: closer, a shape standing still is within the leeway)
                    if f ~= nil and prev_f ~= nil and e[1] - prev_d >= 1 then
                        local ok = math.abs((f - prev_f) - (e[1] - prev_d)) <= .3 and math.abs((n - prev_n) - (e[1] - prev_d)) <= .3
                        if ok then
                            run_from = run_from or prev_d
                            follow = e[1]
                        elseif follow ~= nil then
                            break
                        end
                    end
                    if f ~= nil and (prev_d == nil or e[1] - prev_d >= 1) then prev_d, prev_f, prev_n = e[1], f, n end
                end
                -- (only from close in, over a good stretch)
                if follow ~= nil and (run_from > 4 or follow - run_from < 3) then follow = nil end
                -- (spec no_follow: its shape only seemed to go on with its target, run offline - a dash stopped short by the
                -- stand-in it ran into: the Boarrior's, drawn on past you and pulled back, the player 2026-10-21)
                if type(spec) == "table" and spec.no_follow then follow = nil end
            end
            -- (taken only with its target that near (SIM_MOVE_NEAR), striking where it stands: only as far round it as that, and as far
            -- as one there could get before it strikes (6 a second) and their body - not its whole reach)
            local near_r = rawget(_G, "SIM_MOVE_NEAR")
            if near_r ~= nil and boss_went < .1 and first ~= nil then
                local k0n = key_frames[key_anim[1]] or 0
                local cap = near_r + 6 * math.max(0, first - k0n) * FRAMES + .5
                local src = {}
                if lock_maps ~= nil then for _, m in ipairs(lock_maps) do src[#src + 1] = { m.dist, m.cells } end
                else for _, dd in ipairs(dists) do src[#src + 1] = { sampled[dd].seen, sampled[dd].cells } end end
                local nm = {}
                for _, e in ipairs(src) do
                    local kept = {}
                    for k, f in pairs(e[2]) do
                        local ax, sz = KeyXZ(k)
                        if (ax * STEP) ^ 2 + (sz * STEP) ^ 2 <= cap * cap then kept[k] = f end
                    end
                    nm[#nm + 1] = string.format("{ dist = %s, steps = %s }", string.format("%.4g", e[1]), Steps(kept))
                end
                maps = nm
                free_maps = nil
            end
            -- (spec lane: a leap at a speed of its own, set as it begins (not how far its target is), striking where it is
            -- at one frame - stopped short by whom it runs into, else its whole way: all of its runs as one shape, its whole
            -- way, as it set off - the spider's leap (SGspider warrior_attack: 20 a second, frames 8-20, its bite at 19).
            -- Drawn run by run (follow, free), its landing slid after you and after it as it bounced off you - "the leap's
            -- hitbox floats in from somewhere else", the player 2026-10-22. true_range draws it as it is (fixed, no path))
            -- (by its stategraph too, whoever plays it: every spider with SGspider's leap - the warrior, the plain one in
            -- Uncompromising Mode, its trapdoor spiders, found on their own)
            local LANE_BY_SG = { spider = { warrior_attack = true } }
            if (type(spec) == "table" and spec.lane) or (type(sg) == "table" and LANE_BY_SG[sg.name or ""] ~= nil
                and LANE_BY_SG[sg.name][statename] and os.getenv("SIM_OLD_LANE") == nil) then
                local union = {}
                local src = {}
                if lock_maps ~= nil then
                    for _, m in ipairs(lock_maps) do src[#src + 1] = m.cells end
                else
                    for _, d in ipairs(dists) do src[#src + 1] = sampled[d].cells end
                end
                local function Add(cells, keep)
                    for k, f in pairs(cells) do
                        if (keep == nil or keep(k)) and (union[k] == nil or f < union[k]) then union[k] = f end
                    end
                end
                -- (in its way: only right along it - as near its way as stops it (free_reach: its body and yours) - and
                -- ahead of it; its bite round where it stopped at you reaches wider, but one standing there is off its way:
                -- it goes on past them - its whole way (free, below))
                local W = (free_reach or 1) + .01
                for _, cells in ipairs(src) do
                    Add(cells, function(k)
                        local ax, sz = KeyXZ(k)
                        return math.abs(sz * STEP) <= W and ax * STEP >= -W
                    end)
                end
                for _, m in ipairs(free_cells or {}) do Add(m.cells) end
                -- (one map, no path, no free, no follow: true_range draws it where it set off, the way it set off, as it
                -- is - not fixed, which lays a charge's line by its maps' lengths)
                maps = { string.format("{ dist = 1, steps = %s }", Steps(union)) }
                free_maps, follow = nil, nil
                spec_extra = spec_extra or {}
                spec_extra.lane = true
                -- (the way it faces, not at its target: warrior_attack turns it to no one (no ForceFacePoint) - it leaps
                -- the way its brain had it facing; you stepping aside as it set off, it went straight on, drawn turned
                -- to you - "drawn in, not struck", 11 on the bench, 2026-10-22)
                frame = "facing"
            end
            local leg = "nil"
            if #leg_lens >= 2 then
                local sum, dur = 0, 0
                for i, l in ipairs(leg_lens) do sum = sum + l dur = dur + leg_durs[i] end
                -- (one leg as long as its animation: each time it starts over is a new leg; else
                -- a new leg each time it comes back to it)
                local probe = { prefab = def.prefab, bank = leg_bank }
                local restart = (dur / #leg_durs) * FRAMES <= AnimLen(probe, leg_anim) * 1.25 and "wrap" or "enter"
                local finish = ""
                if finish_anim ~= nil then
                    local fp = {}
                    for i, v in ipairs(leg_lens.finish_path or {}) do fp[i] = string.format("%.2f", v) end
                    finish = string.format(", finish = { anim = %q, last = %d, cells = %q%s }", finish_anim, finish_until,
                        Pack(finish_cells), #fp > 0 and string.format(", path = %q", table.concat(fp, ",")) or "")
                    if SHOW then Show("  its finish (" .. finish_anim .. "), seen from where it began:", finish_cells) end
                end
                local gap = restart == "enter" and leg_gap ~= nil and string.format(", gap = %d", leg_gap) or ""
                leg = string.format("{ anim = %q, restart = %q, length = %.2f, count = %d%s, cells = %q%s%s }", leg_anim or "",
                    restart, sum / #leg_lens, leg_lens.count or 1, leg_lens.turns and ", turns = true" or "", Pack(leg_cells), gap, finish)
                if SHOW then Show("  one leg, seen from where it set off:", leg_cells) end
            end
            -- (frames from when its first animation begins, as the cells' are)
            local k0 = key_frames[key_anim[1]] or 0
            first = first and first - k0
            lock = lock and math.max(0, lock - k0)
            if CHECK then
                local maps_for = {}
                if lock_maps ~= nil then
                    maps_for = lock_maps
                else
                    for d, sm in pairs(sampled) do table.insert(maps_for, { dist = sm.seen, cells = sm.cells }) end
                end
                do
                    print(string.format("CHECK %s %s (lock %s, %s%s%s):", def.prefab, statename, tostring(lock), frame,
                        lock_maps ~= nil and ", from where it stops aiming" or "", boss_went < .1 and ", still" or ""))
                    for _, line in ipairs(CheckMove(def, sg, statename, mem, { key_anim = key_anim, lock = lock, frame = frame,
                        anchor = lock_maps ~= nil, still = boss_went < .1, single = only_target, maps = maps_for, free = free_cells,
                        random = random, off = off, reach = free_reach, around = (lock == nil and next(around) ~= nil) and around or nil,
                        legs = #leg_lens >= 2 and { state = leg_state_name, cells = leg_cells, finish = finish_cells } or nil })) do
                        print(line)
                    end
                end
            end
            if SHOW then
                print(string.format("  -> %s: first %s, lock %s, frame %s, random %s, single %s, leg %s", statename,
                    tostring(first), tostring(lock), frame, tostring(random), tostring(only_target), leg))
            end
            -- (a later form of it - setup: its own code for that - kept apart: "anim@setup"; and how big
            -- it's drawn, which tells them apart in the game)
            local name = key_anim[1] .. (spec_setup and ("@" .. spec_setup) or "") .. (spec_lucky and "@lucky" or "")
            if names_used[name] then local base, k = name .. "~" .. statename, 2 name = base while names_used[name] do name = base .. "~" .. k k = k + 1 end end
            names_used[name] = true
            move_random[def.prefab .. "/" .. statename] = move_random[def.prefab .. "/" .. statename] or random
            -- (spec extra leg = false: no legs - its animation looping as it goes on to strike again, not a
            -- run of legs: the Hooded Widow's swipes on its charge)
            if spec_extra ~= nil and spec_extra.leg == false then leg = "nil" end
            table.insert(out, string.format("        [%q] = { anims = { %s }, first = %d, lock = %s, frame = %q, random = %s, single = %s, scale = %s%s, leg = %s, maps = {",
                name, table.concat(quoted, ", "), first or -1, lock and tostring(lock) or "nil", frame,
                tostring(random), tostring(only_target), boss_scale and string.format("%.3g", boss_scale) or "nil",
                anchor .. (spec_look and string.format(", look = %q", spec_look) or "")
                -- (spec abort_turn: not drawn once facing this far off you after it stops aiming - true_range/predict)
                .. (spec_abort and string.format(", abort_turn = %d", spec_abort) or "")
                -- (spec extra: fields of its own for true_range to read, as they are - leg_whole)
                -- (a list too - from = { "scared_pst" }: written as one, not "table: 0x..." (a load error))
                .. (function()
                    local function V(v)
                        if type(v) == "string" then return string.format("%q", v) end
                        if type(v) == "table" then local l = {} for _, x in ipairs(v) do l[#l + 1] = V(x) end return "{ " .. table.concat(l, ", ") .. " }" end
                        return tostring(v)
                    end
                    local o = {} for k, v in pairs(spec_extra or {}) do if k ~= "leg" then o[#o + 1] = string.format(", %s = %s", k, V(v)) end end table.sort(o) return table.concat(o) end)()
                -- (lock_things: its lock counts what it set off too (MoveKeys) - not to be stretched to when the
                -- last of them is down, as data from before that was (true_range/predict sim.puts / set_until))
                .. ", lock_things = true"
                .. ((snaps and frame == "facing") and ", snaps = true" or "")
                .. ((move_snap_anim ~= nil and frame == "facing") and string.format(", snap_anim = %q", move_snap_anim) or "")
                -- (run as a later form of it (spec mem, set true) - told apart in the game by the
                -- animation of the state that sets it, seen once: the Twins' "transform")
                .. (AfterAnim(def, type(spec) == "table" and spec.mem or nil) and string.format(", after_anim = %q", AfterAnim(def, spec.mem)) or "")
                -- (and the flag it sets - the server reads it, one made already turned: a save loaded)
                .. (AfterAnim(def, type(spec) == "table" and spec.mem or nil) and string.format(", after_mem = %q", select(3, AfterAnim(def, spec.mem))) or "")
                -- (it doesn't go anywhere itself: seen in the game going on, it was already on the
                -- move - Dragonfly bites as it flies on: drawn round where it is now, all along)
                .. ((boss_went < .1 or spec_still) and ", still = true" or "")
                -- (its animation held or slowed by its own code (SetDeltaTimeMultiplier) - not another move played slow)
                .. (sim_anim_held and ", held = true" or "")
                -- (taken only with its target this far off or more - its "doattack" (SIM_SG_FAR))
                .. (sim_move_far ~= nil and string.format(", far = %.4g", sim_move_far) or "")
                -- (all it strikes by is what it puts down at random - drawn by those, as they come)
                .. ((random and not leg_lens.boss_struck) and ", things_only = true" or "")
                -- (the timer it waits on before it may do this again)
                .. (cooldown ~= nil and string.format(", cooldown = %q", cooldown[1]) or "")
                -- (what it goes on into once it has struck - frames from its first animation's start, as first/lock are;
                -- only one begun partway in (from > 0): one begun at its start a player's game sees begin, and draws
                -- itself - the Uncompromising build gave 14 such, a taunt or a loop ahead, 2026-10-26.
                -- OLD_GOES_INTO_ALL=1: every one)
                .. (sim_goes_into ~= nil and (sim_goes_into.from > 0 or os.getenv("OLD_GOES_INTO_ALL") ~= nil) and string.format(", goes_into = { anim = %q, at = %d, from = %d, dist = %.4g }",
                    sim_goes_into.anim, sim_goes_into.frame - k0, sim_goes_into.from, sim_goes_into.dist) or "")
                -- (its way set to the nearest 45 degrees as it strikes (its state's own SnapTo45s - the Rock Master's snip and
                -- dash, the Umbral Abomination, the Celestial Champion's last form): true_range/predict lays it so - aimed
                -- straight at you, up to 22.5 off, 3 of 211 snips undrawn; 2026-10-26)
                .. (function()
                    local SIM_STATE_TEXT = rawget(_G, "SIM_STATE_TEXT")
                    if type(SIM_STATE_TEXT) ~= "table" then SIM_STATE_TEXT = {} rawset(_G, "SIM_STATE_TEXT", SIM_STATE_TEXT) end
                    local key = tostring(def.sg) .. "|" .. tostring(statename)
                    if SIM_STATE_TEXT[key] == nil then
                        SIM_STATE_TEXT[key] = ""
                        local fh = io.open(SCRIPTS .. "/stategraphs/" .. tostring(def.sg) .. ".lua", "rb")
                        local text = fh ~= nil and fh:read("*a") or ""
                        if fh ~= nil then fh:close() end
                        local at = text:find('name%s*=%s*"' .. statename:gsub("%p", "%%%0") .. '"')
                        if at ~= nil then
                            local stop = text:find("\n%s*State%s*{", at)
                            SIM_STATE_TEXT[key] = text:sub(at, (stop or #text + 1) - 1)
                        end
                    end
                    if os.getenv("SNAP_DBG") then io.stderr:write("SNAPDBG " .. key .. " " .. #SIM_STATE_TEXT[key] .. " [" .. SIM_STATE_TEXT[key]:sub(1, 40):gsub("\n", "|") .. "]\n") end
                    -- (not one that goes somewhere: its way there not set so, only its blow at the end - the Rock Master's dash, glitches 14 -> 111)
                    return (SIM_STATE_TEXT[key]:find("SnapTo45s(", 1, true) and boss_went < .5 and not os.getenv("SIM_OLD_SNAP45")) and ", snap45 = true" or ""
                end)()
                -- (when each later animation of it began, frames from its first's start, as first/lock are - one held round
                -- a while, as long as its own code says, the Umbral Abomination underground (teleport_loop, 2.9 s in the game,
                -- its strike after): true_range/predict sets the move's clock by it as that animation is seen to begin;
                -- 2026-10-26)
                .. (function()
                    if key_anim == nil or #key_anim < 2 or key_frames == nil then return "" end
                    local parts = {}
                    for i = 2, #key_anim do
                        local f = key_frames[key_anim[i]]
                        -- (only one the spec names (sync): every later one, hounds' bites and frogs' were drawn wrong, false 1823 -> 3787;
                        -- every one after an animation going round or held, glitches 1566 -> 1896 on the bench - SIM_SYNC_LOOPS=1 to try again)
                        if f ~= nil and key_anim[i] ~= key_anim[1] and ((type(spec) == "table" and spec.sync ~= nil and spec.sync[key_anim[i]]) or (os.getenv("SIM_SYNC_LOOPS") ~= nil and ((SIM_KEY_LOOPED or {})[key_anim[i - 1]] or (rawget(_G, "sim_boss") ~= nil and key_frames[key_anim[i - 1]] ~= nil and (f - key_frames[key_anim[i - 1]]) > AnimLen(sim_boss, key_anim[i - 1]) / FRAMES + 1.5)))) then parts[#parts + 1] = string.format("[%q] = %d", key_anim[i], f - k0) end
                    end
                    return #parts > 0 and (", anim_at = { " .. table.concat(parts, ", ") .. " }") or ""
                end)()
                -- (it aims ahead of you, by how fast you go: where you'll be this many seconds on)
                .. (spec_lead and string.format(", lead = %.3g", spec_lead) or "")
                -- (its target off to its side: drawn as for this far)
                .. (off ~= nil and string.format(", off = %.4g", math.floor(off * 100 + .5) / 100) or "")
                -- (how far round it turns to you, degrees - past that, where it last had you)
                .. (off_cone ~= nil and string.format(", cone = %d", off_cone) or "")
                -- (you behind it count as far as in front)
                .. (off_back and ", back = true" or "")
                -- (it starts to follow you this many frames before its first animation - swimming
                -- up to you, out of sight: Frostjaw's dive)
                .. ((off_cone ~= nil and (key_frames[key_anim[1]] or 0) > 0) and string.format(", track = %d", key_frames[key_anim[1]]) or "")
                -- (how far off its way you still stop it)
                .. (free_reach ~= nil and string.format(", reach = %.3g", free_reach) or "")
                -- (made with its back to its target: how far behind it they are is what counts)
                .. (spec_behind and ", behind = true" or "")
                -- (what it does besides harm, if anything - sleep, knockback, slow...: "harm" among them
                -- or not, it does harm too)
                .. EffectsField()
                -- (where it may strike is set as it puts the last thing down: round where it is till then)
                -- (and one that goes nowhere itself, striking by what it puts down - the Klaus deer's
                -- circles: set where they were put, not moving on with the deer)
                .. (((random or boss_went < .1) and set_until ~= nil) and string.format(", set_until = %d", set_until) or "")
                -- (and what it puts down: once they're there they're drawn themselves, just where they
                -- are - the move's own shape not as well, a second ring just off them)
                .. (((random or boss_went < .1) and set_until ~= nil and next(move_puts) ~= nil) and (function()
                    local l = {}
                    for p in pairs(move_puts) do l[#l + 1] = string.format("%q", p) end
                    table.sort(l)
                    return ", puts = { " .. table.concat(l, ", ") .. " }"
                end)() or "")
                -- (its far edge goes on with its target, up to this far)
                .. (follow ~= nil and string.format(", follow = %.4g", math.floor(follow * 100 + .5) / 100) or "")
                -- (and on every other player this far off too, all at once)
                .. (multi_reach ~= nil and string.format(", multi = %d", multi_reach) or "")
                -- (when it first gets going - told apart so from one begun alike that stays put)
                .. ((boss_went >= .1 and moves_at ~= nil) and string.format(", moves_at = %d", moves_at) or "")
                -- (it goes on the ground, bumping into what's in its way - rocks, walls, the sea's
                -- edge stop it: told where it's drawn, in the game)
                .. ((boss_went >= .5 and boss_solid > boss_through) and ", solid = true" or "")
                -- (it goes on the ground at all - over rocks or not, the sea's edge stops it)
                .. ((boss_went >= .5 and boss_ground_went > 0) and ", ground = true" or ""), leg))
            for _, m in ipairs(maps) do table.insert(out, "            " .. m .. ",") end
            -- (free: as it goes with its target out of its way)
            if free_maps ~= nil then
                table.insert(out, "        }, free = {")
                for _, m in ipairs(free_maps) do table.insert(out, "            " .. m .. ",") end
            end
            -- (one that chases its target to the end - where it goes can't be told: what it hits
            -- round itself, drawn wherever it is)
            if lock == nil and next(around) ~= nil then
                table.insert(out, string.format("        }, around = %q },", Pack(around)))
                if SHOW then Show("  round itself as it chases:", around) end
            else
                table.insert(out, "        } },")
            end
        else
            -- (striking nothing itself, only shooting - a dart flying straight: kept as that, its frame and what it shoots -
            -- true_range draws a lane from it at you till then (shoots), its dart's own as it flies)
            local shot_res = nil
            if not os.getenv("SIM_OLD_RANGED") then
                local ok, res = pcall(Run, def, sg, statename, 3, 1, nil, mem)
                if ok and res ~= nil and res.shot ~= nil and res.anims ~= nil and #res.anims > 0 then shot_res = res end
            end
            if shot_res ~= nil then
                local res = shot_res
                local k0 = res.anim_frame ~= nil and res.anim_frame[res.anims[1]] or 0
                local q = {}
                for _, a in ipairs(res.anims) do
                    q[#q + 1] = string.format("%q", a)
                    if res.anim_frame ~= nil and (res.anim_frame[a] or 0) >= res.shot.frame then break end
                end
                local name = res.anims[1]
                if names_used[name] then local base, k = name .. "~" .. statename, 2 name = base while names_used[name] do name = base .. "~" .. k k = k + 1 end end
                names_used[name] = true
                local fs = math.max(0, res.shot.frame - k0)
                table.insert(out, string.format("        [%q] = { anims = { %s }, first = %d, lock = %d, frame = \"target\", random = false, single = true, scale = nil, anchor = \"lock\", still = true, shoots = %q, lock_things = true, leg = nil, maps = {",
                    name, table.concat(q, ", "), fs, fs, tostring(res.shot.prefab)))
                table.insert(out, "        } },")
                io.stderr:write(def.prefab .. " " .. statename .. ": shoots " .. tostring(res.shot.prefab) .. " at " .. fs .. "\n")
            else
            io.stderr:write(def.prefab .. " " .. statename .. ": nothing\n")
            if os.getenv("DBGNOTHING") then
                local ok, res = pcall(Run, def, sg, statename, 3, 1, nil, mem)
                io.stderr:write(string.format("  ok %s anims %s target_hits %d player_hits %d hit %s\n", tostring(ok),
                    ok and table.concat(res.anims, ",") or tostring(res), ok and #res.target_hits or -1,
                    ok and #res.player_hits or -1, ok and tostring(res.target_hit) or "-"))
            end
            end
        end
        end
        ::next_move::
    end
    table.insert(out, "    },")
    end
    ::next_boss::
end
-- (and every cloud that harms what's in it, tick by tick - an aura, Toadstool's spore cloud: put
-- on you, it never came out of a run with no players; drawn round itself, as far as its aura
-- reaches you, all the while it's there)
AUTO_SKIP_AURA = {}
if not raw then
    local p = io.popen('findstr /m /c:"AddComponent(\\"aura\\")" "' .. SCRIPTS:gsub("/", "\\") .. '\\prefabs\\*.lua" 2>nul')
    for path in p:lines() do
        local file = path:match("([^\\/]+)%.lua%s*$")
        local fh = file and io.open(SCRIPTS .. "/prefabs/" .. file .. ".lua", "rb")
        local text = fh and fh:read("*a") or ""
        if fh then fh:close() end
        for name in ("\n" .. text):gmatch('[^%w_]Prefab%(%s*"[%w_/]-%f[%w_]([%w_]+)"') do
            if hazards[name] == nil and not AUTO_SKIP_AURA[name] then
                Reset()
                local ok, e = pcall(SpawnPrefab, name)
                local comps = ok and type(e) == "table" and rawget(e, "components") or nil
                local aura = comps and rawget(comps, "aura") or nil
                local r = aura ~= nil and tonumber(aura.radius) or nil
                if r ~= nil and r > 0 and rawget(comps, "combat") ~= nil then
                    -- (by your middle, as the game's aura strikes - DoAreaAttack, FindEntities: not your body
                    -- added too - Uncompromising Mode's Wilting Dragonfly spit, its 3 drawn 3.5)
                    local cells, reach = {}, r + PAD
                    for gx = -reach, reach, STEP do
                        for gz = -reach, reach, STEP do
                            if gx * gx + gz * gz <= reach * reach then cells[Key(gx, gz)] = 0 end
                        end
                    end
                    hazards[name] = { cells = cells, delay = 0, moved = false, lasting = true, kinds = { harm = true } }
                end
            end
        end
    end
    p:close()
end
-- (things that strike round themselves when their owner's code says - no stategraph of theirs:
-- the Great Depths Worm's spiked segments (DoThornDamage) as each comes up out of a hole and goes
-- down into the next; their reach run for real (the game's own code); drawn round one while it's
-- at a hole (near), and only a spiked one (look: its build))
-- (radius: as far as it reaches, less your body's .5 added below - an area attack (DoAreaAttack, FindEntities)
-- goes by your middle, your body not counted: its own reach less .5 - the moon spore's 3, drawn 3.5, struck
-- within 3)
STRIKERS = {
    { prefab = "worm_boss_segment", call = "DoThornDamage", fields = { spiked = true }, look = "worm_boss_segment",
        near = { "worm_boss_dirt", 1.5 } },
    -- (the Blighted Great Depths Worm's the same, its own names - worm_boss.lua shadowsegmentfn, its spiked ones'
    -- build the first of its segment builds (worm_boss_util UpdateSegmentArt); 2026-10-23 update)
    { prefab = "worm_boss_shadow_segment", call = "DoThornDamage", fields = { spiked = true }, look = "worm_boss_segment_shadow_build",
        near = { "worm_boss_shadow_dirt", 1.5 } },
    -- (the Shrouded Queen's shadow missile, shot back at whoever strikes it (charlie_boss.lua SpawnReflectProjectileAtXYZ):
    -- homing, bursting 1.2 round itself as it reaches you (charlie_boss_projectiles.lua Detonate, AOEUtil: your body
    -- too) - drawn round it all the way; 2026-10-23 update)
    { prefab = "charlie_boss_projectile", radius = 1.2, delay = 0, lasting = true, by = { "charlie_boss" } },
    -- (and her vines, burrowing after whoever's near (charlie_boss_vines.lua OnUpdate_Server): they come up on one whose
    -- middle is within 1.2 of them (DETECT_RADIUS_HIT, no body added - 0.7 here, its .5 added below), striking with her
    -- combat - drawn round them all the way; 2026-10-23 update)
    { prefab = "charlie_boss_vines", radius = 0.7, delay = 0, lasting = true, by = { "charlie_boss" } },
    -- (and her arena's spikes, called up round you (charliearena_spike.lua OnShroudenSummon): striking 1 round them and your
    -- body (AOE_RADIUS, AOEUtil) 29 frames into rising - drawn only while they rise (true_range/simmoves _on_anims, its
    -- clock from as that begins: up 0-.5 s after made, hidden till then); a wall after, harming no one)
    { prefab = "charliearena_spike", radius = 1, delay = 29, by = { "charlie_boss", "shrouden" } },
    -- (a Birchnut Tree's root: it burrows to you 29 frames, comes up, and strikes round itself at
    -- 55 (DoTaskInTime - its combat's area damage, DECID_MONSTER_ROOT_ATTACK_RADIUS 3.7, and your
    -- body): no state, no call of its own to run - its reach as the game sets it)
    { prefab = "deciduous_root", radius = 3.2, delay = 55 },
    -- (the Crab King's mortar towers' balls: lobbed at you, bursting 3 round where they come down
    -- (CANNONBALL_SPLASH_RADIUS) - shot from its code, not a state of its; drawn where they'll land)
    { prefab = "mortarball", radius = 2.5, delay = 0, moved = true },
    -- (the Ewecus's phlegm: lobbed at you, sticking its target if within 4 of where it lands (SPAT_PHLEGM_RADIUS,
    -- middles - 3.5 and your body) - drawn where it'll come down)
    -- (the spitting Misshapen Bird's bile: lobbed at you, splashing 2 round where it lands (OnHitBile, middles) -
    -- its own, now its spitting isn't run as a move (that dropped its bile with it))
    -- (its blows the game's as the bird's (its combat, the bile its weapon's): as_boss, landed within strikes_until frames of
    -- appearing - the bird walking on by then: all 5 of its blows "missed" on the bench, the bile never handed them, 2026-10-21)
    { prefab = "bilesplat", radius = 1.5, delay = 0, moved = true, by = { "bird_mutant_spitter" }, as_boss = true, strikes_until = 45 },
    { prefab = "spat_bomb", radius = 3.5, delay = 0, moved = true, by = { "spat" }, as_boss = true, strikes_until = 15 },
    -- (the Gingerbread Varg's icing: six lobbed each attack_icing, each a way of its own (Launch2, a random
    -- theta), striking whoever's within 1.5 of where it lands (warg_gooicing.lua:37, middles - 1 and your
    -- body), its blow the Varg's (GetAttacked(caster)): as_boss - 11 of 11 of its struck-undrawn so, 2026-10-18)
    { prefab = "warg_gooicing", radius = 1.0, delay = 0, moved = true, by = { "gingerbreadwarg" }, as_boss = true, strikes_until = 60 },
    -- (the Possessed Varg's and the Lunar Buzzard's flames: each strikes 0.9 x its size round itself
    -- (1.4 to 2.2 - 1.6 taken) and your body while it burns - drawn as they really are, one shape
    -- all together (round, the same size: SimMoves.UnionDraw), gone as each dies down (simmoves OFF_ANIMS))
    -- (its size: 1.4-1.65, x1.2 under 6 off, up to x1.33 at 9 (SGwarg SpawnBreathFX) - struck within 0.9 x that
    -- (AOE_RANGE) and your body: 2.0 at most, taken - 1.6 drew 47 of 248 strikes short, struck 2.1-2.5 off)
    { prefab = "warg_mutated_breath_fx", radius = 2.0, delay = 0, lasting = true, by = { "mutatedwarg", "mutatedbuzzard_gestalt" }, as_boss = true,
        -- (burning 18-22 frames, a tall one up to 3 s (GetFlameTime, TALL_FLAMEWALL 2.5 + 0.5), striking every frame)
        strikes_until = 90 },
    -- (the Clockwork Bishop's shot where it lands: crackling on 18 frames after (HIT_DURATION), striking
    -- whoever comes within 2 (2.5 - .5) and your body - walked into after the shot, struck, drawn gone)
    { prefab = "bishop_charge2_fx", radius = 2, delay = 0, lasting = true, by = { "bishop" } },
    -- (the Ruins Nightmare's horns, its answer to being struck (SGruinsnightmare.lua:14, HORNATTACK_CHANCE): two
    -- made 10 off you either side, running in at where you stood, each striking 1.25 round itself and your body
    -- with the Nightmare's own combat (ruinsnightmare_horn_attack.lua:78-117) - its blows the Nightmare's, 13-19 off
    -- it: no run strikes it, never made; 186 of its 870 blows undrawn once the testbench struck back, 2026-10-19.
    -- Running till they meet: 10 at 5.5 speeding to 13.5 in 0.7 s - under a second)
    { prefab = "ruinsnightmare_horn_attack", radius = 1.25, delay = 0, moved = true, by = { "ruinsnightmare" }, as_boss = true, strikes_until = 36 },
    -- (a Sea Weed's spit: lobbed at you, bursting 2.25 round where it comes down (WATERPLANT.ATTACK_AOE
    -- 1.5, x 1.5) - middles, your body not counted (FindEntities): 1.75 and the .5 added; drawn where it'll land)
    -- (its blow the game puts down to the plant (waterplant_seed.lua:49 GetAttacked(thrower)): as_boss, while
    -- it flies and bursts - 25 a second, gravity 90: under a second)
    { prefab = "waterplant_projectile", radius = 1.75, delay = 0, moved = true, by = { "waterplant" }, as_boss = true, strikes_until = 30 },
    -- (moon spores - a mushgnome's, a moon mushtree's: drifting, they burst 3 round as one comes within
    -- 3.5 (MOONSPORE_ATTACK_RANGE, _PROXIMITY) - drawn round each all along)
    { prefab = "spore_moon", radius = 2.5, delay = 0, lasting = true },
    -- (the Stage Usher's hands: creeping at you along the ground, striking all within 2 (STAGEUSHER_ATTACK_
    -- DAMAGERADIUS, middles: 1.5 and your body) every 4 frames, each one again after 25 (STEPTIME), with the
    -- usher's own combat - till they give up (10 s). Run offline as a flight they were drawn ahead of where
    -- they set off, gone at 1.4 s while still creeping on at ~2 a second, striking: round each, all along)
    { prefab = "stageusher_attackhand", radius = 1.5, delay = 0, lasting = true, by = { "stageusher" }, as_boss = true, strikes_until = 300 },
    -- (the Fused Shadeling's bombs: one chasing you, bursting 3 round itself (FindEntities, middles: 2.5
    -- and your body) some 7-9 s after it shows - a spawn delay at random, then 4 s (fused_shadeling_bomb.lua
    -- 77, 101): when can't be told from outside, drawn all along; then three tossed out from it, each
    -- bursting the same 35 frames after it's made (QUICKFUSE_TIME), where it is; both drawn where each is - moved)
    { prefab = "fused_shadeling_bomb", radius = 2.5, delay = 0, moved = true, lasting = true, by = { "fused_shadeling" } },
    { prefab = "fused_shadeling_quickfuse_bomb", radius = 2.5, delay = 35, moved = true, by = { "fused_shadeling" } },
    -- (its sinkholes, set off under you while it rages (sinkholespawner, antlion_sinkhole.lua donextcollapse):
    -- striking all within RADIUS + 1 (3.5, middles) as it appears and twice more a second apart (3 stages,
    -- COLLAPSE_STAGE_DURATION 1) - again: each later blow; the hole stays on long after, harmless)
    { prefab = "antlion_sinkhole", radius = 3.0, delay = 0, again = { 30, 60 }, by = { "antlion" } },
}
-- (and a mod's: SIM_MOD_SPEC's entries { striker = { ... } } - its things struck by its own code, not a state)
if os.getenv("SIM_MOD_SPEC") then
    for _, d in ipairs(dofile(os.getenv("SIM_MOD_SPEC"))) do
        if d.striker ~= nil then STRIKERS[#STRIKERS + 1] = d.striker end
    end
end
if not raw then
    for _, s in ipairs(STRIKERS) do
        if s.radius ~= nil then
            local cells, reach = {}, s.radius + .5 + PAD
            for gx = -reach, reach, STEP do
                for gz = -reach, reach, STEP do
                    if gx * gx + gz * gz <= reach * reach then cells[Key(gx, gz)] = 0 end
                end
            end
            -- (effects: what it does instead of harm - a web pinning you: s.effects, a status - drawn as one)
            local kinds = { harm = true }
            if s.effects ~= nil then kinds = {} for k in s.effects:gmatch("[^,]+") do kinds[k] = true end end
            hazards[s.prefab] = { cells = cells, delay = s.delay or 0, moved = s.moved == true, lasting = s.lasting == true or nil, kinds = kinds,
                -- (struck again where it struck, these frames after: s.again - a sinkhole's stages, as its own code says)
                again_fixed = s.again,
                -- (its blows the game puts down to its boss - s.as_boss: the Possessed Varg's flames strike
                -- with the warg's own combat (warg_mutated_fx:47); for the replays, as the runs' own as_boss)
                as_boss = s.as_boss or nil, strikes_until = s.as_boss and (s.strikes_until or 0) or nil,
                -- (s.lands: it strikes only where it comes down (its onhit) - not drawn till where that is is known)
                lands = s.lands or nil,
                -- (whose they are, s.by: the replays judge each against its own)
                from = (function() local m = {} for _, b in ipairs(s.by or {}) do m[b .. "/striker"] = true end return m end)() }
            goto next_striker
        end
        Reset()
        Dummies()
        local ok, e = pcall(SpawnPrefab, s.prefab)
        local err = e
        if ok and type(e) == "table" then
            for k, v in pairs(s.fields or {}) do rawset(e, k, v) end
            e.x, e.z = 0, 0
            acting = e
            ok, err = pcall(e[s.call], e)
            acting = nil
        end
        local cells = {}
        for d in pairs(hits) do cells[Key(d.x, d.z)] = 0 end
        if next(cells) ~= nil then
            hazards[s.prefab] = { cells = cells, delay = 0, moved = false, lasting = true, kinds = { harm = true },
                look = s.look, near = s.near }
        else
            io.stderr:write("STRIKER " .. s.prefab .. " hit nothing: " .. tostring(err) .. "\n")
        end
        ::next_striker::
    end
end
table.insert(out, "    _hazards = {")
-- each: when its first hit comes (frames after it appears; moved: after it stops moving), and
-- its cells by when they're hit (frames after the first)
local hazard_names = {}
for prefab in pairs(hazards) do table.insert(hazard_names, prefab) end
table.sort(hazard_names)
for _, prefab in ipairs(hazard_names) do
    local hz = hazards[prefab]
    local by_time, times = {}, {}
    Close(hz.cells)
    -- (burst: all of it at once, round wherever it comes down)
    if hz.burst then for k in pairs(hz.cells) do hz.cells[k] = 0 end end
    for k, rel in pairs(hz.cells) do
        if by_time[rel] == nil then
            by_time[rel] = {}
            table.insert(times, rel)
        end
        by_time[rel][k] = true
    end
    table.sort(times)
    local steps = {}
    for _, rel in ipairs(times) do
        table.insert(steps, string.format("{ at = %d, cells = %q }", rel, Pack(by_time[rel])))
    end
    -- (one that moves: how far it runs before its first hit - shortest and longest seen)
    local travel = ""
    if hz.moved and hz.travel_min ~= nil then
        travel = string.format(", travel = { %.2f, %.2f }", hz.travel_min, hz.travel_max)
    end
    -- (in_move: all it strikes is in the move that set it off, which is the same each time -
    -- drawn with that already)
    local in_move = hz.all_own == true
    for from in pairs(hz.from or {}) do
        if move_random[from] then in_move = false end
    end
    -- (what it does besides harm: only a status - a deer's ice circle - drawn in its own colours)
    local fx = ""
    if hz.kinds ~= nil then
        local list, other = {}, false
        for k in pairs(hz.kinds) do list[#list + 1] = k if k ~= "harm" then other = true end end
        table.sort(list)
        if other then fx = string.format(", effects = %q", table.concat(list, ",")) end
    end
    -- (scale: the size it was drawn at, its cells; scale_pow: its reach goes with its size to this
    -- power - fitted to every size seen (a pound's ring: 2, its art scaled by the root of its reach))
    if hz.scale ~= nil and hz.sizes ~= nil then
        local n, sx, sy, sxx, sxy, lo, hi = 0, 0, 0, 0, 0, math.huge, -math.huge
        for _, s in ipairs(hz.sizes) do
            if s[1] > 0 and s[2] > 0 then
                local lx, ly = math.log(s[1]), math.log(s[2])
                n, sx, sy, sxx, sxy = n + 1, sx + lx, sy + ly, sxx + lx * lx, sxy + lx * ly
                lo, hi = math.min(lo, s[1]), math.max(hi, s[1])
            end
        end
        local pow = 1
        if n >= 2 and hi / lo > 1.05 then pow = (n * sxy - sx * sy) / (n * sxx - sx * sx) end
        fx = fx .. string.format(", scale = %.3f, scale_pow = %.2f", hz.scale, pow)
    end
    -- (flies: it strikes as it flies - seen from where it set off)
    table.insert(out, string.format("        [%q] = { delay = %d, moved = %s%s%s, steps = { %s } },", prefab, hz.delay or 0,
        tostring(hz.moved == true), (hz.flies and string.format(", flies = true, aim = %d", hz.aim or 0) or "") .. (hz.lasting and ", lasting = true" or "") .. (hz.burst and ", burst = true" or "")
            -- (the last of a lot going off one after another, when they spread over 4 frames or more - drawn all that while)
            .. ((hz.delay_max ~= nil and not hz.moved and not hz.lasting and not hz.flies and not hz.in_move and hz.delay_max - (hz.delay or 0) >= 4) and string.format(", delay_max = %d", hz.delay_max) or "")
            .. (hz.look and string.format(", look = %q", hz.look) or "")
            .. (hz.lands and ", lands = true" or "")
            -- (which bosses set it off - the replays judge each against its own)
            .. (function()
                local l, seen = {}, {}
                for from in pairs(hz.from or {}) do
                    local b = from:match("^([^/]+)")
                    if b ~= nil and not seen[b] then seen[b] = true l[#l + 1] = string.format("%q", b) end
                end
                table.sort(l)
                return #l > 0 and (", by = { " .. table.concat(l, ", ") .. " }") or ""
            end)()
            .. (hz.near and string.format(", near = { %q, %.2f }", hz.near[1], hz.near[2]) or "") .. (in_move and ", in_move = true" or "") .. (hz.glide and string.format(", glide = %d", hz.glide) or "")            -- (struck again where it struck, a while after - each cell the same: again = { frames after },
            -- drawn as more steps; UM Bearger's sinkholes half a second on. Not one lasting (drawn all
            -- along) or drawn with its move, nor one whose cells don't agree - a moving trail, 5 or 10 on)
            .. (function()
                if hz.again_fixed ~= nil and not hz.lasting then return ", again = { " .. table.concat(hz.again_fixed, ", ") .. " }" end
                if hz.lasting or in_move or (hz.pulse_n or 0) == 0 then return "" end
                local best, bn = nil, 0
                for sig, n in pairs(hz.pulse_sig or {}) do if n > bn then best, bn = sig, n end end
                if best == nil or best == "" or bn < .95 * hz.pulse_n then return "" end
                return ", again = { " .. best:gsub(",", ", ") .. " }"
            end)()
            -- (its blows put down to the boss, till it's this many frames old: the replays hand the boss's
            -- hits to it then, not to the boss's move - not drawn from, the checkers' only)
            .. (hz.as_boss and string.format(", as_boss = true, strikes_until = %d", hz.strikes_until or 0) or "")
            -- (shared: one of them strikes each once among them all - passed by whom another had
            -- struck, never struck again, and striking most it finds otherwise)
            .. ((function()
                local s = shared_seen[prefab]
                if os.getenv('SHARED_DBG') and s then io.stderr:write(string.format('SHARED %s passed=%d again=%d fresh=%d fresh_hit=%d\n', prefab, s.passed, s.again, s.fresh, s.fresh_hit)) end
                return s ~= nil and s.passed > 0 and s.again == 0 and s.fresh > 0 and s.fresh_hit / s.fresh > .5
            end)() and ", shared = true" or "") .. fx, travel,
        table.concat(steps, ", ")))
    if SHOW then
        local all = {}
        for k in pairs(hz.cells) do all[k] = true end
        Show(string.format("hazard %s (seen from it, facing right): first hit %d frames in%s, %d steps", prefab,
            hz.delay or 0, hz.moved and " (after moving)" or "", #times), all)
    end
end
if raw then
    local fh = assert(io.open(OUT .. ".haz", "wb"))
    fh:write("return " .. Dump({ hazards = hazards, move_random = move_random, shared_seen = shared_seen }) .. "\n")
    fh:close()
end
table.insert(out, "    },")
table.insert(out, "}")
if pairs_dbg then local l = {} for k, v in next, pairs_dbg do l[#l + 1] = { k, v } end table.sort(l, function(a, b) return a[2] > b[2] end) for i = 1, math.min(12, #l) do io.stderr:write("PAIRS " .. l[i][1] .. " " .. l[i][2] .. "\n") end end
local f = assert(io.open(OUT, "wb"))
f:write(table.concat(out, "\n"), "\n")
f:close()
-- (each one's stategraph, beside it - the replays find a boss's states by it: the Twins run the
-- Eye of Terror's, a warg the Varg's...)
if not raw then
    local sf = io.open((OUT:gsub("[^/\\]+$", "")) .. "sg_of.lua", "wb")
    if sf ~= nil then
        sf:write("return {\n")
        for _, def in ipairs(BOSSES) do
            sf:write(string.format("    [%q] = %q,\n", def.prefab, def.sg))
            for _, a in ipairs(def.also or {}) do sf:write(string.format("    [%q] = %q,\n", a, def.sg)) end
        end
        sf:write("}\n")
        sf:close()
    end
end
print("written " .. OUT)
if os.getenv("DBG_PULSES") then
    for k, n in pairs(pulse_sum) do io.stderr:write(string.format("PULSES %s cells=%d\n", k, n)) end
end
