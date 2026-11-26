# powershell -File tools\run_bench.ps1 [-Rounds 10] [-Speed 32] [-Jobs 6] [-Bosses a,b,...] [-Minutes 240]
# The testbench (tr_testbench) on the game's own server with no screen and no one on - no one needs to
# play: worlds of their own (tests\work\bench_server, never the user's), Uncompromising Mode set as in
# the user's Cluster_4, True Range with its traces on, the testbench's server build - each starts by
# itself on a stand-in for you, goes through its share of the bosses, shuts down. A server runs on one
# core: -Jobs side by side, each its own world and ports, the bosses shared out (each ~2 GB of memory).
# Then tools/bench_lock.lua on their logs.
param([int]$Rounds = 10, [int]$Speed = 32, [int]$Jobs = 0, [string]$Bosses = "", [int]$Minutes = 240, [int]$Share = 1, [int]$Lanes = 4, [int]$LaneGap = 150, [string]$Force = "", [switch]$All, [switch]$NoTR, [switch]$TE, [string]$Friend = "")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$dev = Split-Path -Parent $root
$game = 'D:\Games Manager\Games\steamapps\common\Don''t Starve Together'
$ugc = 'D:\Games Manager\Games\steamapps\workshop'
$klei = Join-Path $env:USERPROFILE 'Documents\Klei\DoNotStarveTogether'
# (your Klei account's folder under Documents\Klei\DoNotStarveTogether: $env:DST_KLEI_ACCOUNT, else the only
# numbered folder there - the one with the newest client_save if there are several)
$account = $env:DST_KLEI_ACCOUNT
if (-not $account) {
    $account = Get-ChildItem $klei -Directory | Where-Object { $_.Name -match '^\d+$' } |
        Sort-Object { (Get-Item (Join-Path $_.FullName 'client_save') -ErrorAction SilentlyContinue).LastWriteTime } -Descending |
        Select-Object -First 1 -ExpandProperty Name
}
$userCluster = Join-Path $klei "$account\Cluster_4"
$store = Join-Path $root 'tests\work\bench_server'
$conf = Join-Path $store 'bench_conf'
$noBom = New-Object System.Text.UTF8Encoding $false
# (one run at a time: worlds are named Bench<slot> - a second run took Bench0 from a running one, both
# writing to one world, 2026-10-17)
$others = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -match 'run_bench\.ps1' })
if ($others.Count -gt 0) { "another run_bench is running (pid $($others.ProcessId -join ',')) - wait for it or stop it"; exit 1 }

# the bosses: as given; -All: every monster the mod has moves for - the game's, Uncompromising Mode's,
# those drawn as another (a fire hound as a hound) - and the Great Depths Worm (its things); else the
# testbench's own list
# (-Force <file>: "boss state state ..." a line - those states gone into by the testbench (tr_force.txt, its FORCE); the
# bosses those of the file unless -Bosses says)
if ($Force -ne "" -and $Bosses -eq "") { $Bosses = (@(Get-Content $Force | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ }) -join ',') }
if ($All) {
    $list = @(& luajit -e "DEGREES=math.pi/180 FRAMES=1/30 local seen={} for _,f in ipairs({[[$dev\true_range\scripts\true_range\moves_sim.lua]],[[$dev\true_range\scripts\true_range\moves_sim_um.lua]]}) do local d=dofile(f) for k in pairs(d) do if k:sub(1,1)~='_' then seen[k]=true end end for k in pairs(d._alias or {}) do seen[k]=true end end seen.worm_boss=true local l={} for k in pairs(seen) do l[#l+1]=k end table.sort(l) print(table.concat(l,'\n'))")
} elseif ($Bosses -eq "") {
    $src = Get-Content (Join-Path $dev 'tr_testbench\modmain.lua') -Raw
    $m = [regex]::Match($src, 'local LIST = \{([^}]*)\}')
    $list = @([regex]::Matches($m.Groups[1].Value, '"([\w_]+)"') | ForEach-Object { $_.Groups[1].Value })
} else { $list = @($Bosses -split ',' | Where-Object { $_ }) }
# (-Jobs not given: as many as the machine holds - a server runs on one core (its main thread, ~1.0 core each at
# -Speed 32, the rest of the cores idle at 6), each ~2 GB: the cores but 2, as many as the memory free now
# holds keeping 4 GB back; 6 was 41% of 16 cores, 2026-10-17)
if ($Jobs -le 0) {
    $freeGB = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
    # (each 1.9-2.0 GB as measured, 3.5 kept back: 23.97 GB free gave 9 at a flat 2 with 4 back, 2026-10-18)
    # (in memory, each at most 1.7 GB (its peak working set; 2.2 GB committed, the rest never touched) - 1.95
    # left 13 of 16 cores idle as the last ones ran, 2026-10-19: 1.75)
    $Jobs = [math]::Max(1, [math]::Min([Environment]::ProcessorCount - 2, [math]::Floor(($freeGB - 3.5) / 1.75)))
    "jobs: $Jobs (free memory {0:N1} GB, {1} cores)" -f $freeGB, [Environment]::ProcessorCount
}
$Jobs = [math]::Max(1, [math]::Min($Jobs, $list.Count))
# (the longest first, by the game seconds each took last time (bench_logs\boss_cost.txt, written at the
# end of every run; not known: as long as the longest) - so the last to end are short, not an hour's one
# begun at the end)
$keepDir = Join-Path $root 'tests\work\bench_logs'; New-Item -ItemType Directory -Force $keepDir | Out-Null
$costFile = Join-Path $keepDir 'boss_cost.txt'
$cost = @{}
if (Test-Path $costFile) { foreach ($l in [IO.File]::ReadAllLines($costFile)) { $a = $l -split ' '; if ($a.Count -ge 2) { $cost[$a[0]] = [double]$a[1] } } }
$list = @($list | Sort-Object @{ Expression = { $b = $_ -replace '!np$', ''; if ($cost.ContainsKey($b)) { $cost[$b] } else { 1e9 } }; Descending = $true }, @{ Expression = { $_ } })
# (a boss a share by default - a world of its own, fresh, every one: in shares of 4 one ran slower the
# later it came - 18, 12, 9, 7x - in a world grown older (fires, trees, the season on), and was tested in
# another season too; a server's start, ~45 s, costs less: 50,974 -> ~34,500 s, VERIFY_PLAN 6.15)
# (queued - -Jobs servers at a time, each taking the next share as one ends: one monster bringing its
# server down loses only the rest of its share, and those go to the front of the queue again - at the
# back they were the last to end)
$queue = New-Object System.Collections.ArrayList
# (the Great Depths Worm after another in its share, as it always was before shares of one: first out in a
# world just begun, the stand-in held 4.03 off its mound - out of the ground only within 4, no further on
# within 6 (worm_boss_util.lua:271,497) - it did nothing the whole hour; why only first: open, VERIFY_PLAN 6.15)
$before = @{ worm_boss = 'deer' }
if ($Share -eq 1) { $list = @($list | ForEach-Object { if ($before.ContainsKey($_)) { "$($before[$_])+$_" } else { $_ } }) }
# (-Lanes K: K at once on one server, each in a lane of its own far apart - the world's cost each tick is most
# of it (idle 39x, a hound fighting 40x at Speed 128): near K times as many, a start each K (VERIFY_PLAN 6.18).
# Not those that change the world for all, or need a place of their own: set up (SETUP, SETUP_TICK), out
# only at night (NIGHT - the clock is the world's), the worm and the deer before it - alone, as before)
$solo = @{ worm_boss = 1; deer = 1 }
$tbSrc = Get-Content (Join-Path $dev 'tr_testbench\modmain.lua') -Raw
foreach ($blk in @('local SETUP = \{(.*?)\n\}', 'local SETUP_TICK = \{(.*?)\n\}')) {
    $m = [regex]::Match($tbSrc, $blk, 'Singleline')
    foreach ($k in [regex]::Matches($m.Groups[1].Value, '(?m)^    (\w+) = ')) { $solo[$k.Groups[1].Value] = 1 }
}
foreach ($k in [regex]::Matches([regex]::Match($tbSrc, 'local NIGHT = \{([^}]*)\}').Groups[1].Value, '(\w+)\s*=\s*true')) { $solo[$k.Groups[1].Value] = 1 }
# (and those that have brought a server down - the engine, no Lua error (exit 6): alone, and at once not tagged a
# player ("!np", what kept them up before) - in a lane one took three to fifteen others down with it, every one
# run again alone, 2026-10-19. bench_logs\crash_prone.txt: kept from run to run, each new one added)
$crashFile = Join-Path $keepDir 'crash_prone.txt'
if (-not (Test-Path $crashFile)) {
    # (the 2026-10-18 benches' ten: VERIFY_PLAN 6.15)
    [IO.File]::WriteAllLines($crashFile, @('warg', 'warglet', 'mutatedwarg', 'spider_trapdoor_hooded', 'pied_rat', 'hoodedwidow', 'cherrybulletbee', 'eyeofterror_mini_ally', 'worm_boss'), $noBom)
}
$crashProne = @{}; foreach ($c in [IO.File]::ReadAllLines($crashFile)) { if ($c.Trim()) { $crashProne[$c.Trim()] = 1 } }
if ($Lanes -gt 1 -and $Share -eq 1) {
    $alone = @(); $laned = @()
    foreach ($b in $list) {
        if ($b -match '\+' -or $b -match '!np$' -or $solo.ContainsKey($b)) { $alone += $b }
        elseif ($crashProne.ContainsKey($b)) { $alone += "$b!np" }
        else { $laned += $b }
    }
    # (one prefab once in a share: the logs parted by boss name too)
    $laned = @($laned | Select-Object -Unique)
    for ($i = 0; $i -lt $laned.Count; $i += $Lanes) { [void]$queue.Add(@($laned[$i..([math]::Min($i + $Lanes, $laned.Count) - 1)])) }
    foreach ($b in $alone) { [void]$queue.Add(@($b -split '\+')) }
    "lanes: $Lanes - $($laned.Count) in lanes, $($alone.Count) alone ($($alone -join ','))"
} else {
    for ($i = 0; $i -lt $list.Count; $i += $Share) { [void]$queue.Add(@($list[$i..([math]::Min($i + $Share, $list.Count) - 1)] | ForEach-Object { $_ -split '\+' })) }
}

# 1. the testbench's server build: its code as it is, run on the server alone
$srv = Join-Path $game 'mods\tr_testbench_server'
New-Item -ItemType Directory -Force $srv | Out-Null
Copy-Item (Join-Path $dev 'tr_testbench\modmain.lua') $srv -Force
$forceDst = Join-Path $srv 'tr_force.txt'
if ($Force -ne "") { Copy-Item $Force $forceDst -Force; "forced states: $((Get-Content $Force | Measure-Object).Count) bosses" } elseif (Test-Path $forceDst) { Remove-Item $forceDst -Force }
$info = (Get-Content (Join-Path $dev 'tr_testbench\modinfo.lua') -Raw) -replace 'name = "TR Testbench \(local\)"', 'name = "TR Testbench (server, local)"' `
    -replace 'client_only_mod = true', 'client_only_mod = false' -replace 'all_clients_require_mod = false', "all_clients_require_mod = false`nserver_only_mod = true"
[IO.File]::WriteAllText((Join-Path $srv 'modinfo.lua'), $info, $noBom)
if (-not (Test-Path (Join-Path $game 'mods\true_range\debug.txt'))) { Write-Host "True Range's debug.txt is missing in the game's copy - run tools\install.ps1"; exit 1 }

# 2. a world for each of -Jobs slots (Bench0..): one shard, offline, never pausing with no one on, its own
#    ports; the share it runs now in its name (the testbench reads "tr_bench:a,b"); a world made before
#    copied in once, not made again (port 11001 on: the game takes only 10998-11018 - any other, it falls
#    back to 10999 for them all)
$seed = Join-Path $conf 'Bench\Master\save'
$exe = Join-Path $game 'bin64\dontstarve_dedicated_server_nullrenderer_x64.exe'
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$runDir = Join-Path $keepDir "${stamp}_shares"; New-Item -ItemType Directory -Force $runDir | Out-Null
$sw = [Diagnostics.Stopwatch]::StartNew()
$slots = @($null) * $Jobs
$nShare = 0
$crashed = @()
$retried = @{}
function StartShare($slot, $bosses) {
    $script:nShare++
    $name = "Bench$slot"
    $master = Join-Path $conf "$name\Master"
    New-Item -ItemType Directory -Force $master | Out-Null
    # (in lanes: "tr_bench@K:" - the testbench runs them at once. Before $share below: PowerShell's names have
    # no case - $share is $Share, the param read after as the boss list, never 1, 2026-10-19)
    $laned = $Lanes -gt 1 -and $script:Share -eq 1 -and $bosses.Count -gt 1 -and -not ($bosses | Where-Object { $solo.ContainsKey(($_ -replace '!np$', '')) })
    $share = $bosses -join ','
    # (-Friend friend|watch: a second stand-in beside you - one lane only; "+watch": True Range seen from its side)
    if ($Friend -ne "") { $laned = $false }
    $tag = if ($laned) { "tr_bench@$($bosses.Count)$(if ($LaneGap -gt 0) { "g$LaneGap" })" } else { 'tr_bench' }
    if ($Friend -ne "") { $tag = "$tag+$Friend" }
    [IO.File]::WriteAllText((Join-Path $conf "$name\cluster.ini"), "[GAMEPLAY]`ngame_mode = survival`nmax_players = 1`npvp = false`npause_when_empty = false`n`n[NETWORK]`ncluster_name = ${tag}:$share`noffline_cluster = true`nlan_only_cluster = true`ncluster_password =`n`n[MISC]`nconsole_enabled = true`n`n[SHARD]`nshard_enabled = false`n", $noBom)
    [IO.File]::WriteAllText((Join-Path $master 'server.ini'), "[NETWORK]`nserver_port = $(11001 + $slot)`n`n[SHARD]`nis_master = true`n`n[STEAM]`nauthentication_port = $(8800 + $slot)`nmaster_server_port = $(27100 + $slot)`n", $noBom)
    $lvl = Join-Path $userCluster 'Master\leveldataoverride.lua'
    if (Test-Path $lvl) { Copy-Item $lvl (Join-Path $master 'leveldataoverride.lua') -Force }
    luajit (Join-Path $here 'bench_overrides.lua') (Join-Path $userCluster 'Master\modoverrides.lua') (Join-Path $master 'modoverrides.lua') $Rounds $Speed $(if ($NoTR) { 'notr' } else { 'tr' }) $(if ($TE) { 'te' } else { '' }) | Out-Null
    # (the world made before, afresh for every share: a world kept from share to share saves as it goes -
    # what earlier shares left (a Treeguard standing idle by every stand-in since) and the clock on)
    if (Test-Path $seed) {
        if (Test-Path (Join-Path $master 'save')) { Remove-Item -Recurse -Force (Join-Path $master 'save') }
        Copy-Item $seed (Join-Path $master 'save') -Recurse
    }
    $log = Join-Path $master 'server_log.txt'
    # (the last server on this slot may still hold it a moment after it's gone: tried again for 10 s - not left
    # there, a new server's log read with the old one's lines, 2026-10-19)
    for ($r = 0; $r -lt 10 -and (Test-Path $log); $r++) { try { Remove-Item $log -Force -ErrorAction Stop } catch { Start-Sleep 1 } }
    $sargs = @('-persistent_storage_root', "`"$store`"", '-conf_dir', 'bench_conf', '-cluster', $name, '-shard', 'Master', '-ugc_directory', "`"$ugc`"")
    $p = Start-Process $exe -ArgumentList $sargs -WorkingDirectory (Join-Path $game 'bin64') -PassThru -WindowStyle Hidden
    Write-Host "started $name (share $($script:nShare)): $share"
    return [pscustomobject]@{ slot = $slot; n = $script:nShare; bosses = $bosses; log = $log; p = $p; t0 = Get-Date; laned = $laned }
}
# (one ended: its log kept as its share's; brought down partway - the monster it was on noted, those
#  after it queued again)
function EndShare($j, $why) {
    $out = Join-Path $runDir ("share{0:D3}.txt" -f $j.n)
    if (Test-Path $j.log) { Copy-Item $j.log $out -Force }
    # (read off the file as it goes, not all in as lines first: hundreds of MB, every slot waiting meanwhile)
    $done = (Test-Path $out) -and (Select-String -Path $out -Pattern '\[tr_bench\] [\d.]+ - all done' -Quiet)
    # (down by the bench's own code - the testbench's or True Range's, not a boss's: every share after goes down
    # the same - the run stopped there and then, the error said; not run again and again, 6 times over before
    # anyone looked, 2026-10-19)
    if (-not $done -and (Test-Path $out)) {
        $own = Select-String -Path $out -Pattern 'mods/(tr_testbench_server|true_range)/[^:]*:\d+:' | Select-Object -First 1
        if ($own) {
            "BENCH CODE ERROR in share $($j.n) - run stopped: $($own.Line.Trim())"
            $script:ownError = $true
        }
    }
    if ($j.laned -and (Test-Path $out)) {
        # (in lanes: parted into a log a lane, as if each had run alone - the whole kept aside; those whose
        # lane never ended, each again alone)
        $comb = Join-Path $runDir 'combined'; New-Item -ItemType Directory -Force $comb | Out-Null
        $split = luajit (Join-Path $here 'lane_split.lua') $out (Join-Path $runDir ("share{0:D3}" -f $j.n))
        "  share $($j.n) $split"
        Move-Item $out (Join-Path $comb (Split-Path $out -Leaf)) -Force
        if (-not $done) {
            $txt = [IO.File]::ReadAllText((Join-Path $comb (Split-Path $out -Leaf)))
            $laneOf = @{}; foreach ($m in [regex]::Matches($txt, '\[tr_lane\] [\d.]+ ([\w_]+) lane=(\d+)')) { if (-not $laneOf.ContainsKey($m.Groups[1].Value)) { $laneOf[$m.Groups[1].Value] = $m.Groups[2].Value } }
            $ended = @{}; foreach ($m in [regex]::Matches($txt, '\[tr_bench\] [\d.]+ \S+ lane done (\d+)')) { $ended[$m.Groups[1].Value] = 1 }
            $again = @($j.bosses | Where-Object { $b = $_ -replace '!np$', ''; -not ($laneOf.ContainsKey($b) -and $ended.ContainsKey($laneOf[$b])) })
            $script:crashed += "lanes of share $($j.n) ($why): $($again -join ',')"
            # (the server is one process: one bringing it down takes every lane with it - which one, the log can't
            # say (all trace every tick). Halved and each half run again in lanes; a half down again halved again -
            # the one that does it found alone in a few, the rest still in lanes. Every one alone was a start each,
            # 2026-10-19)
            if ($again.Count -ge 2) {
                $h = [math]::Ceiling($again.Count / 2)
                $a1 = @($again[0..($h - 1)]); $a2 = @($again[$h..($again.Count - 1)])
                "  share $($j.n) ended ($why) - again in halves: $($a1 -join ',') | $($a2 -join ',')"
                $queue.Insert(0, $a2); $queue.Insert(0, $a1)
            } elseif ($again.Count -eq 1) {
                "  share $($j.n) ended ($why) - again alone: $($again[0])"
                $queue.Insert(0, @($again[0]))
            }
        }
        return
    }
    if (-not $done) {
        $last = if (Test-Path $out) { Select-String -Path $out -Pattern '\[tr_bench\] [\d.]+ (\S+) spawned' | Select-Object -Last 1 } else { $null }
        $at = if ($last) { $last.Matches[0].Groups[1].Value } else { $null }
        $k = -1; if ($at) { for ($q = 0; $q -lt $j.bosses.Count; $q++) { if (($j.bosses[$q] -replace '!np$', '') -eq $at) { $k = $q } } }
        $rest = @(); if ($k -ge 0 -and $k + 1 -lt $j.bosses.Count) { $rest = @($j.bosses[($k + 1)..($j.bosses.Count - 1)]) }
        if ($k -lt 0) { $rest = @($j.bosses | Select-Object -Skip 1); $at = $j.bosses[0] }
        $script:crashed += "$at ($why)"
        # (one alone that brought its server down: kept, to be alone and "!np" from the first next time)
        if ($k -ge 0 -and $why -like 'exited*') {
            $cb = $j.bosses[$k] -replace '!np$', ''
            if (-not $script:crashProne.ContainsKey($cb)) { $script:crashProne[$cb] = 1; [IO.File]::AppendAllText($crashFile, "$cb`n", $noBom) }
        }
        "  share $($j.n) ended at $at ($why) - again: $($rest -join ',')"
        # (the one it went down on: once more with the stand-in not tagged a player ("!np") - code for real
        # players only brought the engine down; its moves still measured)
        if ($k -ge 0 -and $j.bosses[$k] -notlike '*!np') {
            $rest = @("$($j.bosses[$k])!np") + $rest; "  $at again as not a player"
            # (and still after the one it goes after - else first in a world again, the very case it's there for)
            if ($Share -eq 1 -and $before.ContainsKey($at)) { $rest = @($before[$at]) + $rest }
        }
        # (down before its first boss was out - the server itself, not a boss: that one again, once - in
        # shares of one it was dropped with nothing else to go on)
        if ($k -lt 0 -and -not $script:retried.ContainsKey($j.bosses[0])) { $script:retried[$j.bosses[0]] = $true; $rest = @($j.bosses[0]) + $rest; "  $at again" }
        if ($rest.Count -gt 0) { $queue.Insert(0, $rest) }
    }
}

# 3. as fast as the machine goes - no set time: one stopped only if its log stands still 3 minutes (hung),
#    or past -Minutes at all
$ownError = $false
# (the disk the logs go on: each server writes hundreds of MB - a full disk brought every server down at once and
# the halving ran them again and again, 466 shares in 170 minutes, nothing usable, 2026-10-19. Not begun under
# 25 GB free; stopped, said, under 8)
$drive = Get-PSDrive -Name ((Resolve-Path $keepDir).Drive.Name)
if ($drive.Free / 1GB -lt 25) { "only {0:N1} GB free on {1}: - not begun (bench logs, tests\work\bench_x)" -f ($drive.Free / 1GB), $drive.Name; exit 1 }
while ($sw.Elapsed.TotalMinutes -lt $Minutes -and -not $ownError) {
    if ((Get-PSDrive -Name $drive.Name).Free / 1GB -lt 8) { "DISK nearly full ({0:N1} GB) - run stopped" -f ((Get-PSDrive -Name $drive.Name).Free / 1GB); break }
    for ($s = 0; $s -lt $Jobs; $s++) {
        $j = $slots[$s]
        if ($j -ne $null -and $j.p.HasExited) { EndShare $j "exited $($j.p.ExitCode)"; $slots[$s] = $null; $j = $null }
        if ($j -ne $null -and (Test-Path $j.log) -and ((Get-Date) - (Get-Item $j.log).LastWriteTime).TotalSeconds -gt 180 -and ((Get-Date) - $j.t0).TotalSeconds -gt 240) {
            Stop-Process -Id $j.p.Id -Force; Start-Sleep 2; EndShare $j "hung"; $slots[$s] = $null; $j = $null
        }
        if ($j -eq $null -and $queue.Count -gt 0) { $next = $queue[0]; $queue.RemoveAt(0); $slots[$s] = StartShare $s $next }
    }
    if (@($slots | Where-Object { $_ -ne $null }).Count -eq 0 -and $queue.Count -eq 0) { break }
    # (a second, not 5: in shares of one, 260 of them, a slot stood empty 2.5 s on average each time)
    Start-Sleep 1
}
foreach ($j in $slots) { if ($j -ne $null) { if (-not $j.p.HasExited) { Stop-Process -Id $j.p.Id -Force; Start-Sleep 2 }; EndShare $j "past $Minutes min" } }
"servers ran $([math]::Round($sw.Elapsed.TotalMinutes, 1)) min, $nShare shares; brought down at: $(if ($crashed.Count) { $crashed -join '; ' } else { 'none' })"
# (each boss's game seconds this time, for the next run's order - kept for those not run this time)
$shareLogs = @(Get-ChildItem $runDir -Filter 'share*.txt' | ForEach-Object { $_.FullName })
if ($shareLogs.Count -gt 0) {
    foreach ($l in @(luajit (Join-Path $here 'bench_speed.lua') @shareLogs)) {
        $a = $l -split ' '
        if ($a.Count -ge 5) { $b = $a[2] -replace '!np$', ''; $cost[$b] = [double]$a[4] }
    }
    [IO.File]::WriteAllLines($costFile, @($cost.Keys | Sort-Object | ForEach-Object { "$_ $($cost[$_])" }), $noBom)
}

# 4. their logs kept (tests\work\bench_logs: hundreds of MB, made again at will - not the players' logs
#    compare.ps1 goes over): each share's on its own (things by GUID, places - one world's each:
#    tools/bench_things.lua), and all in one for tools/bench_lock.lua
$keep = Join-Path $keepDir "${stamp}_bench_headless.txt"
# (copied through as bytes, a file at a time - all read in as lines first, 70 shares took 20 GB of the
# 31 and nearly brought the machine down, 2026-10-17)
$outS = [IO.File]::Create($keep)
try {
    foreach ($f2 in (Get-ChildItem $runDir -Filter 'share*.txt' | Sort-Object Name)) {
        $inS = [IO.File]::OpenRead($f2.FullName)
        try { $inS.CopyTo($outS) } finally { $inS.Close() }
    }
} finally { $outS.Close() }
Select-String -Path $keep -Pattern '\[tr_bench\] .* (gave up|tickdt|speed)|LUA ERROR|no such prefab' | Select-Object -First 60 | ForEach-Object { $_.Line }
# (control: a hound, always attacking - none of its scenes begun means the bench itself is broken, not
# the monsters: SetMinHealth on the stand-in once made every monster pass it by, all of them read as
# "needs its arena")
$hs = @(Select-String -Path (Join-Path $runDir 'share*.txt') -Pattern '\[tr_bench\] [\d.]+ hound end ' -ErrorAction SilentlyContinue).Count
if ($list -contains 'hound') { if ($hs -eq 0) { "CONTROL FAILED: the hound began no scene - the bench is broken, its results not to be used" } else { "control ok: hound $hs scenes" } }
luajit (Join-Path $here 'bench_lock.lua') $keep (Join-Path $dev 'true_range') um
# (the all-in-one only for bench_lock: the same bytes as the shares - 54 of them kept, 48 GB, the disk full, 2026-10-19)
Remove-Item $keep -Force -ErrorAction SilentlyContinue