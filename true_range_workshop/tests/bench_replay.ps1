# powershell -File tests\bench_replay.ps1 [-Run <bench_logs folder>] [-Mod <mod dir>] [-Bosses a,b]
# A whole testbench run checked at once (VERIFY_PLAN 6.13): every boss of every share through
# tests\replay.lua, every share's things through tests\replay_haz.lua - one table, every boss: its
# scenes, strikes, missed, drawn-in-unstruck, and whether it was tested at all. Every core.
# (1) shares whose things were written only as they changed are expanded first (tools\expand_haz.lua) -
#     to copies in tests\work\bench_x\<run>, the kept logs left as they are; without that a thing
#     standing still is there for the replays only as it appears
# (2) the testbench runs with Uncompromising Mode on: its scripts (game_scripts_um), TR_MODS
param([string]$Run = "", [string]$Mod = "", [string[]]$Bosses, [switch]$Walk, [switch]$TE, [string]$Client = "", [switch]$HazOnly)
# (-HazOnly: only the shares' things (tests/replay_haz.lua) - a change to how things are drawn tried on its own, 2026-10-28)
# (-Client 1 / 0: as a player's game would see it, Lag Compensation Predictive on / off (tests/replay.lua CLIENT, PRED) - checked
# against the lag bench's own client, 2026-10-27: its own folder, the cache keeps no word of it)
# (-TE: a run of the testbench with Tropical Experience on (run_bench -TE) - its data laid over too; not for the others: its
# changes to the game's monsters (its Dragonfly) are not theirs)
$scriptsDir = if ($TE) { 'tests\work\game_scripts_umte' } else { 'tests\work\game_scripts_um' }
$trMods = if ($TE) { 'workshop-3193922031 workshop-1505270912' } else { 'workshop-3193922031' }
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
if ($Run -eq "") { $Run = (Get-ChildItem (Join-Path $root 'tests\work\bench_logs') -Directory | Sort-Object Name | Select-Object -Last 1).FullName }
if ($Mod -eq "") { $Mod = Join-Path (Split-Path -Parent $root) 'true_range' }
$Run = (Resolve-Path $Run).Path; $Mod = (Resolve-Path $Mod).Path
$bossList = @(); if ($Bosses) { $bossList = @($Bosses | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
$name = Split-Path -Leaf $Run
$xdir = Join-Path $root "tests\work\bench_x\$name"
$out = Join-Path $root "tests\work\bench_replay\$name"
# (another mod replayed (-Mod, an agent's copy): its own folder - two runs at once wrote the same files,
# one's table read the other's half-written ones, 2026-10-18)
$defMod = (Resolve-Path (Join-Path (Split-Path -Parent $root) 'true_range')).Path
if ($Mod -ne $defMod) { $out = "$out" + '__' + (Split-Path -Leaf $Mod) + '_' + ([Math]::Abs($Mod.GetHashCode()) % 100000) }
# (-Walk: you walking in and out round each boss in the replays (tests/replay.lua WALK) - its own folder too)
if ($Walk) { $out = "$out" + '__walk'; $env:WALK = '1' } else { Remove-Item Env:WALK -ErrorAction SilentlyContinue }
if ($Client -ne "") { $out = "$out" + "__client$Client"; $env:CLIENT = '1'; $env:CLIENT_PRED = $Client } else { Remove-Item Env:CLIENT, Env:CLIENT_PRED -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force $xdir, $out | Out-Null
$max = [Math]::Max(1, [int]$env:NUMBER_OF_PROCESSORS)
# (a piece begun this long before its own stretch: what was under way then seen from its start - PIECE_LEAD)
$lead = if ($env:PIECE_LEAD) { [double]$env:PIECE_LEAD } else { 20 }
$t0 = Get-Date
function RunAll($jobs, $limit, [scriptblock]$heavy) {
    # (the heavy ones - the biggest logs - started first, two at most at once; while two run, the
    # others go on past them - waited on, the whole queue stood behind one 30-minute replay)
    $pending = New-Object System.Collections.ArrayList
    # (longest first, by its work (w: trace lines, share_plan.lua) - the Mini Eyes' 8 minutes begun at the
    # start, not left to the end alone)
    foreach ($j in @($jobs | Sort-Object -Descending { if ($_.w) { [double]$_.w } else { 0 } })) { [void]$pending.Add($j) }
    $live = @()
    # (each job's time, kept - _times.csv by the table: what the run's time went on, not guessed)
    $Done = {
        param($x)
        $script:jobtimes += [pscustomobject]@{ job = (Split-Path -Leaf $x.out); secs = [math]::Round(((Get-Date) - $x.start).TotalSeconds, 1); w = $x.w }
    }
    while ($pending.Count -gt 0) {
        foreach ($x in @($live | Where-Object { $_.p.HasExited -and -not $_.told })) { $x.told = $true; & $Done $x }
        $live = @($live | Where-Object { -not $_.p.HasExited })
        $nh = @($live | Where-Object { $_.heavy }).Count
        $pick = $null
        if ($live.Count -lt $limit) {
            foreach ($j in $pending) { if (-not ($j.heavy -and $nh -ge 2)) { $pick = $j; break } }
        }
        if ($null -eq $pick) { Start-Sleep -Milliseconds 200; continue }
        $pending.Remove($pick)
        if ($pick.env) { foreach ($k in $pick.env.Keys) { Set-Item "env:$k" $pick.env[$k] } }
        $p = Start-Process luajit -ArgumentList $pick.args -NoNewWindow -PassThru -RedirectStandardOutput $pick.out -RedirectStandardError "$($pick.out).err"
        $live += [pscustomobject]@{ p = $p; heavy = $pick.heavy; out = $pick.out; start = (Get-Date); w = $pick.w; told = $false }
    }
    while (@($live | Where-Object { -not $_.told }).Count -gt 0) {
        foreach ($x in @($live | Where-Object { $_.p.HasExited -and -not $_.told })) { $x.told = $true; & $Done $x }
        Start-Sleep -Milliseconds 200
    }
}
$script:jobtimes = @()
Push-Location $root
try {
    $shares = @(Get-ChildItem $Run -Filter 'share*.txt' | Sort-Object Name)
    # (0) each share read once, all side by side (tools/share_plan.lua): its bosses, things, cuts - read
    # four or five times over, one share after another, it was minutes before any replay began
    # (2026-10-18). Kept while the share is the same
    $pl = @()
    foreach ($s in $shares) {
        $pf = Join-Path $xdir ("plan_" + $s.Name)
        if (-not (Test-Path $pf) -or (Get-Item $pf).LastWriteTime -lt $s.LastWriteTime) {
            $pl += @{ args = @('tools\share_plan.lua', "`"$($s.FullName)`"", "$max", '40000'); out = $pf; heavy = $false }
        }
    }
    "bench_replay: $($shares.Count) shares, $($pl.Count) to plan"
    RunAll $pl $max
    $plans = @{}
    foreach ($s in $shares) {
        $p = @{ bosses = @(); haz = $false; you = $false; cuts = @{}; lines = @{} }
        foreach ($l in [IO.File]::ReadAllLines((Join-Path $xdir ("plan_" + $s.Name)))) {
            $w = $l -split ' '
            switch ($w[0]) {
                'boss' { $p.bosses += $w[1] }
                'haz' { $p.haz = $true }
                'you' { $p.you = $true }
                'cuts' { $p.cuts[$w[1]] = @($w[3..($w.Count - 1)] | ForEach-Object { [double]$_ }) }
                'lines' { $p.lines[$w[1]] = [double]$w[2] }
            }
        }
        $plans[$s.Name] = $p
    }
    # (1) expand - 4 at once (each holds its whole log: ~4x its size)
    $ex = @()
    foreach ($s in $shares) {
        $dst = Join-Path $xdir $s.Name
        $s | Add-Member -NotePropertyName use -NotePropertyValue $s.FullName
        if ($plans[$s.Name].you) {
            $s.use = $dst
            # (made again by a newer expander too, not only a newer log)
            if (-not (Test-Path $dst) -or (Get-Item $dst).LastWriteTime -lt $s.LastWriteTime -or (Get-Item $dst).LastWriteTime -lt (Get-Item (Join-Path $root 'tools\expand_haz.lua')).LastWriteTime) {
                $ex += @{ args = @('tools\expand_haz.lua', "`"$($s.FullName)`"", "`"$dst`""); out = "$dst.expand.txt"; heavy = $false; w = $s.Length }
            }
        }
    }
    "bench_replay: $($ex.Count) to expand"
    # (every core, the biggest first: 4 at a time, the 282 MB one begun late left it running alone at the end
    # - 2.7 min of 48, 2026-10-18)
    RunAll $ex $max
    # (1b) its things' cuts, by the expanded log's lines (what replay_haz goes through) - side by side
    $hc = @()
    if ($bossList.Count -eq 0) {
        foreach ($s in $shares) {
            $hf = Join-Path $xdir ("hazcuts_" + $s.Name)
            if ($plans[$s.Name].haz -and (Get-Item $s.use).Length -gt 50MB -and (-not (Test-Path $hf) -or (Get-Item $hf).LastWriteTime -lt (Get-Item $s.use).LastWriteTime)) {
                $hc += @{ args = @('tools\haz_cuts.lua', "`"$($s.use)`"", "$max"); out = $hf; heavy = $false }
            }
        }
        RunAll $hc $max
    }
    # (2) every boss with scenes, every share with things
    $todo = @()
    foreach ($s in $shares) {
        $bs = $plans[$s.Name].bosses
        # (and every other monster traced there - a boss's guards, its summons, one we've no data for at all: never judged
        # as itself, only its boss - the Bee Queen's own guards 841,818 trace lines, not one of their blows looked at, and one
        # with no data of ours never shown missed anywhere, 2026-10-20. OLD_BOSSES_ONLY=1: the testbench's bosses alone)
        if (-not $env:OLD_BOSSES_ONLY) {
            $bs = @($bs) + @($plans[$s.Name].lines.Keys | Where-Object { $bs -notcontains $_ -and $plans[$s.Name].lines[$_] -ge 50 } | Sort-Object)
        }
        $heavy = $s.Length -gt 500MB
        # (each boss cut by its own work - its [tr_trace] lines, at most 40000 a piece (share_plan.lua) -
        # not by the log's size or scenes: the Mini Eyes, one replay of 30 minutes in a 140 MB log, a core
        # alone while 15 stood idle, 2026-10-18. WORK_CUTS_OLD=1: as before, by scenes over 150 MB)
        $wc = @{}
        # (off unless BOSS_PIECES=1: pieces counted the Mini Eyes' misses 57 and 70, the whole log 15 - the
        # whole run, 8 min since the replay's loops were mended, is the one to trust; VERIFY_PLAN 6.15)
        if ($env:BOSS_PIECES -and -not $env:WORK_CUTS_OLD) { $wc = $plans[$s.Name].cuts }
        foreach ($b in $bs) {
            if ($HazOnly -or ($bossList.Count -gt 0 -and $bossList -notcontains $b)) { continue }
            # (what an earlier run left for it, whole or in pieces: gone - else counted twice by the table)
            Get-ChildItem $out -Filter "$($s.BaseName)*__$b.txt*" -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match ('^' + [regex]::Escape($s.BaseName) + '(#p\d+)?__' + [regex]::Escape($b) + '\.txt') } | Remove-Item -Force
            if ($wc.ContainsKey($b)) {
                $cuts = @(0) + $wc[$b]
                for ($i = 0; $i -lt $cuts.Count; $i++) {
                    $from = if ($i -eq 0) { 0 } else { $cuts[$i] - $lead }
                    $to = if ($i -lt $cuts.Count - 1) { $cuts[$i + 1] - 0.001 } else { 999999 }
                    $envs = @{ TR_MODS = $trMods; COUNT_FROM = $(if ($i -eq 0) { '' } else { "$($cuts[$i])" }) }
                    $todo += @{ args = @('tests\replay.lua', "`"$Mod`"", "`"$($s.use)`"", $scriptsDir, $b, "$from", "$to"); out = (Join-Path $out "$($s.BaseName)#p$i`__$b.txt"); heavy = $false; env = $envs }
                }
                continue
            }
            # (a big log cut at its scenes into 8, run side by side - each begun 5 s early, counted only
            # from its own first scene (COUNT_FROM): one 30-minute replay held the whole run up. Summed
            # back by the table, the boss the same - checked against one whole run, Deerclops 395/0/91)
            $starts = @()
            # (as many pieces as cores - each reads the whole log itself (~70 s for 928 MB), so more than
            # that only waits; logs over 150 MB)
            # (cut at any scene's start, every boss's - the whole log covered, from 0: the Eye of Terror's
            # minis strike all through its own fight, before a scene of theirs - cut at theirs alone,
            # 3,500 of their 9,150 strikes were left out)
            if ($env:WORK_CUTS_OLD -and (Get-Item $s.use).Length -gt 150MB) { $starts = @(Select-String $s.FullName -Pattern "\[tr_bench\] ([\d.]+) \S+ start" | ForEach-Object { [double]$_.Matches[0].Groups[1].Value }) }
            if ($starts.Count -ge 2 * $max) {
                $per = [Math]::Ceiling($starts.Count / $max); $cuts = @()
                for ($i = 0; $i -lt $starts.Count; $i += $per) { $cuts += $starts[$i] }
                for ($i = 0; $i -lt $cuts.Count; $i++) {
                    $from = if ($i -eq 0) { 0 } else { $cuts[$i] - $lead }
                    $to = if ($i -lt $cuts.Count - 1) { $cuts[$i + 1] - 0.001 } else { 999999 }
                    $envs = @{ TR_MODS = $trMods; COUNT_FROM = $(if ($i -eq 0) { '' } else { "$($cuts[$i])" }) }
                    $todo += @{ args = @('tests\replay.lua', "`"$Mod`"", "`"$($s.use)`"", $scriptsDir, $b, "$from", "$to"); out = (Join-Path $out "$($s.BaseName)#p$i`__$b.txt"); heavy = $false; env = $envs }
                }
            } else {
                $wl = [double]($plans[$s.Name].lines[$b])
                $todo += @{ args = @('tests\replay.lua', "`"$Mod`"", "`"$($s.use)`"", $scriptsDir, $b); out = (Join-Path $out "$($s.BaseName)__$b.txt"); heavy = ($wl -gt 400000); w = $wl; env = @{ TR_MODS = $trMods; COUNT_FROM = '' } }
            }
        }
        if ($bossList.Count -eq 0 -and $plans[$s.Name].haz) {
            Get-ChildItem $out -Filter "$($s.BaseName)*___haz.txt*" -ErrorAction SilentlyContinue | Remove-Item -Force
            # (its things too, cut the same way (HAZ_FROM/HAZ_TO, tests/replay_haz.lua): two whole-log
            # replays of things, a core each, were the last 15+ minutes of the run with 14 cores idle -
            # share026 and the Great Depths Worm's share071, 6-7 GB each; 2026-10-17)
            # (cut by its work - as many [tr_haz] lines a piece (tools/haz_cuts.lua) - not by scenes: the Great
            # Depths Worm's segments all in its own few scenes, one of 16 pieces by scenes held them all, 2026-10-18)
            $hcuts = @()
            $hf = Join-Path $xdir ("hazcuts_" + $s.Name)
            if ((Get-Item $s.use).Length -gt 50MB -and (Test-Path $hf)) { $hcuts = @([IO.File]::ReadAllLines($hf) | Where-Object { $_ -match '^[\d.]+$' } | ForEach-Object { [double]$_ }) }
            if ($hcuts.Count -ge 1) {
                $cuts = @(0) + $hcuts
                for ($i = 0; $i -lt $cuts.Count; $i++) {
                    $hf = if ($i -eq 0) { '' } else { "$($cuts[$i])" }
                    $ht = if ($i -lt $cuts.Count - 1) { "$($cuts[$i + 1])" } else { '' }
                    $todo += @{ args = @('tests\replay_haz.lua', "`"$Mod`"", "`"$($s.use)`""); out = (Join-Path $out "$($s.BaseName)#p$i`___haz.txt"); heavy = $false; env = @{ TR_MODS = $trMods; COUNT_FROM = ''; HAZ_FROM = $hf; HAZ_TO = $ht } }
                }
            } else {
                $todo += @{ args = @('tests\replay_haz.lua', "`"$Mod`"", "`"$($s.use)`""); out = (Join-Path $out "$($s.BaseName)___haz.txt"); heavy = $heavy; w = ((Get-Item $s.use).Length / 250); env = @{ TR_MODS = $trMods; COUNT_FROM = ''; HAZ_FROM = ''; HAZ_TO = '' } }
            }
        }
    }
    # (3) a replay already run with all it goes by the same - its log, the mod's code, its monster's own data
    # (tools/data_keys.lua), the checkers, its arguments and settings - taken from the cache, not run again:
    # a fix to one boss's data re-runs that boss, not 600 replays (VERIFY_PLAN 6.15). NO_CACHE=1: all run
    $cacheDir = Join-Path $root 'tests\work\replay_cache'
    New-Item -ItemType Directory -Force $cacheDir | Out-Null
    $sha = [System.Security.Cryptography.SHA1]::Create()
    function HashOf([string]$text) { ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))) -replace '-', '').Substring(0, 16) }
    function FilesHash($files) {
        $all = New-Object System.Text.StringBuilder
        foreach ($f in ($files | Sort-Object FullName)) { [void]$all.Append($f.Name + ':' + ([BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($f.FullName))) -replace '-', '')) }
        HashOf $all.ToString()
    }
    $codeH = FilesHash (@(Get-ChildItem (Join-Path $Mod 'scripts\true_range') -Recurse -File | Where-Object { $_.Name -notlike 'moves_sim*' }) + @(Get-Item (Join-Path $Mod 'modmain.lua')))
    # (the checkers, and all else they read: the stategraphs their animations come from, sg_of, the shape
    # check - the reviewer, 2026-10-18: a UM update re-extracted would otherwise keep old results)
    $testFiles = @(Get-Item (Join-Path $root 'tests\replay.lua'), (Join-Path $root 'tests\replay_haz.lua'))
    $testFiles += @(Get-ChildItem (Join-Path $root 'tests') -Filter 'shapecheck*.lua' -ErrorAction SilentlyContinue)
    $testFiles += @(Get-ChildItem (Join-Path $root 'tests\work') -Filter 'sg_of*.lua' -ErrorAction SilentlyContinue)
    $checkers = $testFiles
    # (all of Uncompromising Mode's scripts, not its stategraphs alone - its prefabs give each its stategraph,
    # the strict check reads the rest; and the expander, the logs read as it made them - the reviewer, 2026-10-18)
    $testFiles += @(Get-ChildItem (Join-Path $root $scriptsDir) -Recurse -Filter '*.lua' -ErrorAction SilentlyContinue)
    $testFiles += @(Get-Item (Join-Path $root 'tools\expand_haz.lua'))
    # (and its animations' lengths, read by replay.lua for the boss's GetCurrentAnimationLength)
    $testFiles += @(Get-ChildItem (Join-Path $root 'tools') -Filter 'anim_lengths*.lua' -ErrorAction SilentlyContinue)
    $testH = FilesHash $testFiles
    $dataK = @{}
    # (-TE: Tropical Experience's data too - left out, a change to it alone took every replay from the cache, the old
    # results: slipstor's new move "missed" still, 2026-10-21)
    $dataFiles = @((Join-Path $Mod 'scripts\true_range\moves_sim.lua'), (Join-Path $Mod 'scripts\true_range\moves_sim_um.lua'))
    if ($TE) { $dataFiles += (Join-Path $Mod 'scripts\true_range\moves_sim_te.lua') }
    # (and the hand files: a monster there only as another (moves_hand_um _alias - Shadow Wixie's clone as her) had no key at
    # all, its row kept from the cache when her shot's "by" changed - 63 missed that were 0, 2026-10-30)
    $keyFiles = $dataFiles + @(Get-ChildItem (Join-Path $Mod 'scripts\true_range') -Filter 'moves_hand*.lua' -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    foreach ($l in @(& luajit tools\data_keys.lua @keyFiles)) { $w = $l -split ' '; $dataK[$w[0]] = $w[1] }
    # (the things' replays go by every boss's data - near which boss a thing is, drawn with its move or not:
    # the whole of it, any change running them all again)
    $dataK['_haz'] = FilesHash @($dataFiles | ForEach-Object { Get-Item $_ })
    # (the settings a replay reads that aren't its job's own: the checkers' switches)
    # (every setting the checkers read, found in them by os.getenv - a hand list missed 25 of some 30; a
    # machine's own settings would change from one session to the next)
    $envNames = @{}
    # (the mod's own from the mod replayed (-Mod) - a path under this folder, there none, read nothing: the
    # reviewer, 2026-10-18)
    $modLua = @(Get-ChildItem (Join-Path $Mod 'scripts\true_range') -Recurse -Filter '*.lua') + @(Get-Item (Join-Path $Mod 'modmain.lua'))
    foreach ($f in $checkers + $modLua) {
        foreach ($m in [regex]::Matches([IO.File]::ReadAllText($f.FullName), 'getenv\(\s*"([A-Za-z0-9_]+)"')) { $envNames[$m.Groups[1].Value] = $true }
        # (and the old-way switches read by a list - for _, n in ipairs({ "TR_OLD_...", ... }) os.getenv(n): missed by
        # the above, TR_OLD_TELLWAIT=1 taken from the cache of a run without it, 2026-10-18)
        foreach ($m in [regex]::Matches([IO.File]::ReadAllText($f.FullName), '"((?:TR_|SIM_)?OLD_[A-Za-z0-9_]+)"')) { $envNames[$m.Groups[1].Value] = $true }
    }
    $envH = HashOf (($envNames.Keys | Sort-Object | ForEach-Object { "$_=$([Environment]::GetEnvironmentVariable($_))" }) -join ';')
    $logK = @{}
    $toRun = @(); $hit = 0
    foreach ($j in $todo) {
        $b = if ($j.out -match '___haz\.txt$') { '_haz' } else { ([IO.Path]::GetFileNameWithoutExtension($j.out) -split '__', 2)[1] }
        $lf = $j.args[2].Trim('"')
        if (-not $logK.ContainsKey($lf)) { $gi = Get-Item $lf; $logK[$lf] = "$($gi.Name):$($gi.Length):$($gi.LastWriteTimeUtc.Ticks)" }
        $envs = if ($j.env) { ($j.env.Keys | Sort-Object | ForEach-Object { "$_=$($j.env[$_])" }) -join ';' } else { '' }
        $j.key = HashOf ("$codeH|$testH|$($dataK[$b])|$($logK[$lf])|$(($j.args | Select-Object -Skip 3) -join ' ')|$envs|$envH|$b")
        $c = Join-Path $cacheDir "$($j.key).txt"
        if (-not $env:NO_CACHE -and (Test-Path $c)) {
            Copy-Item $c $j.out -Force
            if (Test-Path "$c.err") { Copy-Item "$c.err" "$($j.out).err" -Force } else { Set-Content "$($j.out).err" '' }
            $hit++
        } else { $toRun += $j }
    }
    "bench_replay: $($todo.Count) replays, $hit from the cache, $($toRun.Count) to run"
    RunAll $toRun $max
    foreach ($j in $toRun) {
        $ok = (Test-Path $j.out) -and -not ((Test-Path "$($j.out).err") -and (Select-String "$($j.out).err" -Pattern '\b[Ee]rror|traceback' -Quiet))
        if ($ok) {
            Copy-Item $j.out (Join-Path $cacheDir "$($j.key).txt") -Force
            if (Test-Path "$($j.out).err") { Copy-Item "$($j.out).err" (Join-Path $cacheDir "$($j.key).txt.err") -Force }
        }
    }
} finally { Pop-Location; $env:TR_MODS = $null }
"{0:N0}s on the clock" -f ((Get-Date) - $t0).TotalSeconds
# (3) the table
$rows = @{}
# (a thing's blow that strikes as its boss, the boss's move drawn there all the same - ASBOSS_DRAWN,
# tests/replay.lua: not missed - replay_haz.lua hands it the thing not knowing the move; by share, its
# pieces as one. OLD_ASBOSS=1: as before)
$asbossDrawn = @{}
if (-not $env:OLD_ASBOSS) {
    foreach ($f in Get-ChildItem $out -Filter '*.txt' | Where-Object { $_.Name -notlike '*.err' -and $_.Name -notlike '*___haz.txt' }) {
        $sh = (($f.BaseName -split '__', 2)[0]) -replace '#p\d+$', ''
        foreach ($line in [IO.File]::ReadLines($f.FullName)) {
            if ($line -match '^ASBOSS_DRAWN ([\d\.]+) ') {
                if (-not $asbossDrawn[$sh]) { $asbossDrawn[$sh] = New-Object System.Collections.Generic.List[double] }
                $asbossDrawn[$sh].Add([double]$Matches[1])
            }
        }
    }
}
$asbossTaken = 0
foreach ($f in Get-ChildItem $out -Filter '*.txt' | Where-Object { $_.Name -notlike '*.err' }) {
    $b = ($f.BaseName -split '__', 2)[1]
    $share = ($f.BaseName -split '__', 2)[0]
    if (-not $rows[$b]) { $rows[$b] = [pscustomobject]@{ boss = $b; shares = ''; strikes = 0; drawn = 0; missed = 0; false = 0; bything = 0; aimjump = 0; yellow = 0; err = 0; false_fr = 0; both = 0; flip = 0; jump = 0; gap = 0; glitch = 0; wobble = 0; bjump = 0 } }
    $r = $rows[$b]
    $r.shares = ($r.shares + ' ' + $share).Trim()
    $drawnBy = if ($b -eq '_haz') { $asbossDrawn[$share -replace '#p\d+$', ''] } else { $null }
    foreach ($line in [IO.File]::ReadLines($f.FullName)) {
        if ($drawnBy -and $line -match '^MISSED\s+([\d\.]+) ') {
            $mt = [double]$Matches[1]
            foreach ($dt in $drawnBy) { if ([math]::Abs($dt - $mt) -lt .05) { $r.missed--; $r.drawn++; $asbossTaken++; break } }
        }
        if ($line -match '(\d+) strikes - (\d+) drawn, (\d+) missed; (\d+) drawn-in with no strike') {
            $r.strikes += [int]$Matches[1]; $r.drawn += [int]$Matches[2]; $r.missed += [int]$Matches[3]; $r.false += [int]$Matches[4]
        } elseif ($line -match '^BOTHDRAWN [^:]+: (\d+) frames') { $r.both += [int]$Matches[1]
        } elseif ($line -match '^AIMJUMPS [^:]+: (\d+) struck') { $r.aimjump += [int]$Matches[1]
        } elseif ($line -match '^YELLOW  ') { $r.yellow += 1
        } elseif ($line -match '^FLIPDRAWN [^:]+: (\d+) goes') { $r.flip += [int]$Matches[1]
        } elseif ($line -match '^JUMPDRAWN [^:]+: (\d+) frames') { $r.jump += [int]$Matches[1]
        } elseif ($line -match '^GAPDRAWN [^:]+: (\d+) times') { $r.gap += [int]$Matches[1]
        } elseif ($line -match '^\S+: (\d+) glitches') { $r.glitch += [int]$Matches[1]
        } elseif ($line -match '^_hazards: (\d+) frame\(s\) drawn-in with no strike') { $r.false_fr += [int]$Matches[1]
        } elseif ($line -like 'BYTHING*') { $r.bything++
        # (a shape going back and forth (replay.lua WOBBLE) - said by the replays, never counted here: 441 in a client replay, 2026-10-29)
        } elseif ($line -like 'WOBBLE *') { $r.wobble++
        # (a boss's shape's middle leaping in a frame, the boss not (replay.lua JUMP) - said, never counted: 404 host / 1,402 client, Blighted Rock Master's dash among them, 2026-10-29)
        } elseif ($line -like 'JUMP  *') { $r.bjump++ }
    }
    if ((Get-Item "$($f.FullName).err").Length -gt 0 -and (Select-String "$($f.FullName).err" -Pattern '\b[Ee]rror|traceback' -Quiet)) { $r.err++ }
}
if ($asbossTaken -gt 0) { "things' missed drawn by their boss's move after all (ASBOSS_DRAWN): $asbossTaken" }
$table = @($rows.Values | Sort-Object @{ e = { $_.missed }; Descending = $true }, @{ e = { $_.false }; Descending = $true })
$table | Export-Csv (Join-Path $out '_table.csv') -NoTypeInformation -Encoding utf8
$script:jobtimes | Sort-Object secs -Descending | Export-Csv (Join-Path $out '_times.csv') -NoTypeInformation -Encoding utf8
"longest jobs: " + (($script:jobtimes | Sort-Object secs -Descending | Select-Object -First 5 | ForEach-Object { "$($_.job) $($_.secs)s" }) -join ', ')
"job time in all: {0:N0}s on {1} cores" -f ($script:jobtimes | Measure-Object secs -Sum).Sum, $max
$table | Format-Table boss, strikes, drawn, missed, aimjump, yellow, false, bything, err, false_fr, both, flip, jump, gap, glitch, wobble, bjump, shares -AutoSize | Out-String -Width 220
"TOTAL strikes {0}  missed {1}  drawn-in-no-strike {2}  errors {3}  things' drawn-in frames {4}  two-shapes frames {5}  flipped goes {6}  jumped frames {7}  gaps {8}  glitches {9}  wobbles {10}  boss jumps {11}" -f ($table | Measure-Object strikes -Sum).Sum, ($table | Measure-Object missed -Sum).Sum, ($table | Measure-Object false -Sum).Sum, ($table | Measure-Object err -Sum).Sum, ($table | Measure-Object false_fr -Sum).Sum, ($table | Measure-Object both -Sum).Sum, ($table | Measure-Object flip -Sum).Sum, ($table | Measure-Object jump -Sum).Sum, ($table | Measure-Object gap -Sum).Sum, ($table | Measure-Object glitch -Sum).Sum, ($table | Measure-Object wobble -Sum).Sum, ($table | Measure-Object bjump -Sum).Sum
