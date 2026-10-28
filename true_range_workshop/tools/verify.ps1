# True Range: every check in one go - before anything goes to the game.
#   powershell -File verify.ps1 [-NoSim] [-Install]
# 1. unit tests (tests/strict_check, test_sim, glidetest, atomcheck)
# 2. the offline runs (tools/sim_moves.lua -jobs -check): how many check scenes are off, per move,
#    against the last time - and each run written out as a trace
# 3. synthetic replay: each of those traces through the mod's own drawing (tests/replay.lua) -
#    does what it draws agree with what the run hit?
# 4. real replay: every game log kept in tests/logs (the newest client_log.txt is added to it when
#    it has a trace no log there has), every boss in it
# 5. a summary, against the last one (tests/last_summary.txt): better, worse, the same
# -Install: the new offline data into the mod (true_range/scripts/true_range/moves_sim.lua) first,
# so the replays test it - else they test what's installed
# -Only boss,boss: only those bosses run offline again, put into the data as it is (tests/splice.lua),
# and only they replayed - seconds, not minutes, while working on one; the summary isn't kept
param([switch]$NoSim, [switch]$Install, [string[]]$Only)
# (given as a,b - PowerShell makes that a list: one comma-joined string again, and the list)
$onlyList = @(); if ($Only) { $onlyList = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ }); $Only = $onlyList -join ',' }
$onlyArg = if ($Only) { "-only=$Only" } else { $null }
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root 'tools'
$tests = Join-Path $root 'tests'
$mod = Join-Path (Split-Path -Parent $root) 'true_range'
$work = Join-Path $tests 'work'
$scripts = Join-Path $work 'game_scripts'
New-Item -ItemType Directory -Force $work, (Join-Path $tests 'logs') | Out-Null
# (the game's scripts, unpacked - again whenever the game's scripts.zip is another: an update)
$zip = 'D:\Games Manager\Games\steamapps\common\Don''t Starve Together\data\databundles\scripts.zip'
$zipHash = (Get-FileHash $zip -Algorithm SHA1).Hash
$hashFile = Join-Path $work 'game_scripts.hash'
$had = if (Test-Path $hashFile) { (Get-Content $hashFile -Raw).Trim() } else { '' }
if (-not (Test-Path (Join-Path $scripts 'stategraphs')) -or $had -ne $zipHash) {
    Write-Host "unpacking the game's scripts (scripts.zip $zipHash)..."
    $unz = Join-Path $work ('unz_' + $zipHash)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($zip, $unz)
    # (the old copy moved aside, not deleted - kept for comparing; tests/work/game_scripts_<hash>)
    if (Test-Path $scripts) { Move-Item $scripts (Join-Path $work ('game_scripts_' + $had)) }
    Move-Item (Join-Path $unz 'scripts') $scripts
    Set-Content -LiteralPath $hashFile -Value $zipHash
}
# (lasting things measured a few runs then let be (sim_moves THING_RUNS) - proven the same as
# measuring every run for this scripts.zip only (tools/check_thing_rule.ps1); another: every run)
$thingOk = Join-Path $tests 'thing_rule_ok.txt'
$thingProven = (Test-Path $thingOk) -and ((Get-Content $thingOk -Raw).Trim() -eq $zipHash)
if (-not $thingProven) {
    $env:SIM_ALL_THINGS = '1'
    Write-Host "   NOTE lasting-thing shortcut not proven for this scripts.zip - every run measured (slower); run tools\check_thing_rule.ps1"
}
$summary = [ordered]@{}
$fails = New-Object System.Collections.Generic.List[string]

# 1. unit tests
Write-Host "== unit tests"
foreach ($t in 'strict_check', 'test_sim', 'glidetest', 'segtris', 'pool_hide', 'turn_groups', 'near_holes', 'flash_aim', 'body_ring') {
    $out = & luajit (Join-Path $tests "$t.lua") $mod 2>&1 | ForEach-Object { "$_" }
    # (failed: a FAIL line, a Lua error - or no ALL PASSED where the test ends with one)
    $bad = @($out | Where-Object { $_ -match '^FAIL|^\S*luajit|traceback|attempt to' })
    if ($t -eq 'test_sim' -and -not ($out | Where-Object { $_ -match 'ALL PASSED' })) { $bad += 'no ALL PASSED' }
    $summary["unit $t"] = if ($bad) { 'FAIL' } else { 'ok' }
    if ($bad) { $fails.Add("unit $t"); $bad | Select-Object -First 5 | ForEach-Object { Write-Host "   $_" } }
    Write-Host ("   {0,-14} {1}" -f $t, $summary["unit $t"])
}
# (a boss's shapes drawn in groups the game turns, against drawn piece by piece - every piece the
# same, frame by frame: a new shape's first frame was drawn pointing nowhere, every warning flicking
# off its aim and back - tests/group_same.ps1, on a kept log of the Deerclops aiming at you)
$gsLog = Join-Path $tests 'perf_logs\client_log_20261012_2208_Q_deer.txt'
if (Test-Path $gsLog) {
    $gs = & powershell -File (Join-Path $tests 'group_same.ps1') $mod $gsLog deerclops 70 80 | Select-Object -Last 1
    $gsBad = -not ($gs -match ': (\d+) frames, 0 differ$' -and [int]$Matches[1] -gt 0)
    $summary['unit group_same'] = if ($gsBad) { 'FAIL' } else { 'ok' }
    if ($gsBad) { $fails.Add('unit group_same'); Write-Host "   $gs" }
    Write-Host ("   {0,-14} {1}" -f 'group_same', $summary['unit group_same'])
}
$atom = & luajit (Join-Path $tests 'atomcheck.lua') $mod 2>&1 | ForEach-Object { "$_" } | Select-String 'fallbacks' | ForEach-Object { $_.Line }
$summary['atom fallbacks'] = ($atom -replace '.*fallbacks\s+(\d+).*', '$1')
# (jagged edges: a part only a rim round the one before, cells sticking out into it - tests/slivercheck.lua)
$sl = & luajit (Join-Path $tests 'slivercheck.lua') $mod 2>&1 | ForEach-Object { "$_" }
$slLast = $sl | Where-Object { $_ -match 'slivers (\d+), spikes (\d+)' } | Select-Object -Last 1
if ($slLast -match 'slivers (\d+), spikes (\d+)') { $summary['edge slivers'] = [int]$matches[1]; $summary['edge spikes'] = [int]$matches[2] }
else { $summary['edge slivers'] = 'FAIL'; $fails.Add('slivercheck'); $sl | Select-Object -Last 5 | ForEach-Object { Write-Host "   $_" } }
$sl | Where-Object { $_ -match '^(SLIVER|SPIKE)' } | Set-Content (Join-Path $work 'slivers.txt')
Write-Host ("   slivercheck    slivers {0}, spikes {1} (each in tests/work/slivers.txt)" -f $summary['edge slivers'], $summary['edge spikes'])
Write-Host ("   atomcheck      fallbacks {0}" -f $summary['atom fallbacks'])
# (shapes of things put down going on with a boss that walks off - tests/slidecheck.lua)
$sc = & luajit (Join-Path $tests 'slidecheck.lua') $mod 2>&1 | ForEach-Object { "$_" }
$scLast = $sc | Where-Object { $_ -match 'slidecheck: (\d+) moves, (\d+) slid' } | Select-Object -Last 1
if ($scLast -match 'slidecheck: (\d+) moves, (\d+) slid') { $summary['put-down shapes slid'] = [int]$matches[2] }
else { $summary['put-down shapes slid'] = 'FAIL'; $fails.Add('slidecheck'); $sc | Select-Object -Last 5 | ForEach-Object { Write-Host "   $_" } }
$sc | Where-Object { $_ -match '^SLIDE' } | ForEach-Object { Write-Host "   $_" }
Write-Host ("   slidecheck     {0}" -f $scLast)

# 2. the offline runs (and their traces)
$traces = Join-Path $work 'traces'
if (-not $NoSim) {
    # (coverage first: every state of every boss run from, every branch on its flags - each blow
    # struck that the mod's data has nothing for, said; those states are added as moves in the run
    # below - tests/work/coverage_add.lua)
    # (side by side with the runs below - its own process; those it finds added the next time)
    Write-Host "== coverage (every state, every branch) - alongside the offline runs"
    $env:COVERAGE = Join-Path $mod 'scripts\true_range\moves_sim.lua'
    $covArgs = @('sim_moves.lua', "`"$(Join-Path $work 'coverage_unused.lua')`"", "`"$scripts`"")
    if ($onlyArg) { $covArgs += $onlyArg }
    $covOut = Join-Path $work 'coverage_out.txt'
    $covProc = Start-Process -FilePath 'luajit' -ArgumentList $covArgs -WorkingDirectory $tools -RedirectStandardError $covOut -RedirectStandardOutput "$covOut.std" -NoNewWindow -PassThru
    $env:COVERAGE = $null
    Write-Host "== offline runs (about 1.5 minutes)"
    New-Item -ItemType Directory -Force $traces | Out-Null
    Get-ChildItem $traces -Filter *.trace | Where-Object { -not $Only -or $onlyList -contains ($_.BaseName -replace '#\d+$', '') } | ForEach-Object { [IO.File]::Delete($_.FullName) }
    $env:SIMTRACE = $traces
    # (no job taken for hung for being 5 times slower than its last run: a random move now runs on till it finds no
    # more (sim_moves More) - the Antlion past 120s stopped a whole run, nothing written, 2026-10-26)
    $env:SIM_JOB_LIMIT = '1200'
    Push-Location $tools
    if ($Only) {
        # (those bosses alone, then put into the data as installed)
        & luajit sim_moves.lua (Join-Path $work 'moves_sim_part.lua') $scripts -jobs -check $onlyArg 2> (Join-Path $work 'check.txt') > $null
        & luajit (Join-Path $tests 'splice.lua') (Join-Path $mod 'scripts\true_range\moves_sim.lua') (Join-Path $work 'moves_sim_part.lua') (Join-Path $work 'moves_sim.lua') $Only | Out-Null
    } else {
        & luajit sim_moves.lua (Join-Path $work 'moves_sim.lua') $scripts -jobs -check 2> (Join-Path $work 'check.txt') > $null
    }
    # (the moves built with -ends (tools/ends_moves.txt): their bosses run again so, those moves put in -
    # a run without it drops their "ends"; each checked to have them)
    $endsList = @(Get-Content (Join-Path $tools 'ends_moves.txt') | Where-Object { $_ -match '^\w+:\w' })
    if (-not $Only) { $endsMine = $endsList } else { $endsMine = @($endsList | Where-Object { $onlyList -contains ($_ -split ':')[0] }) }
    if ($endsMine.Count -gt 0) {
        $endsBosses = (@($endsMine | ForEach-Object { ($_ -split ':')[0] }) | Sort-Object -Unique) -join ','
        & luajit sim_moves.lua (Join-Path $work 'moves_sim_ends.lua') $scripts -jobs -ends "-only=$endsBosses" 2> (Join-Path $work 'ends.txt') > $null
        & luajit (Join-Path $tests 'splice.lua') (Join-Path $work 'moves_sim.lua') (Join-Path $work 'moves_sim_ends.lua') (Join-Path $work 'moves_sim.lua') ($endsMine -join ',') | Out-Null
        $noEnds = @(& luajit -e "DEGREES=math.pi/180 FRAMES=1/30 local d=dofile([[$(Join-Path $work 'moves_sim.lua')]]) local function H(t,n) if type(t)~='table' or n>6 then return false end if t.ends~=nil then return true end for _,v in pairs(t) do if H(v,n+1) then return true end end return false end for x in ([[$($endsMine -join ',')]]):gmatch('[^,]+') do local b,m=x:match('(.-):(.+)') local k=d[b] local e=k and (k.moves or k)[m] if not H(e,0) then print(x) end end")
        if ($noEnds.Count -gt 0) { $fails.Add("built without ends: $($noEnds -join ', ')"); Write-Host "   NO ENDS: $($noEnds -join ', ')" }
        else { Write-Host "   -ends moves put in: $($endsMine.Count)" }
    }
    Pop-Location
    # (the coverage run alongside: done by now, or waited for)
    $covProc.WaitForExit()
    $nextAdd = Join-Path $work 'coverage_add.next.lua'
    if (Test-Path $nextAdd) { Move-Item $nextAdd (Join-Path $work 'coverage_add.lua') -Force }
    $cov = Get-Content $covOut -ErrorAction SilentlyContinue
    $cl = $cov | Where-Object { $_ -match 'coverage: (\d+) sources of blows found, (\d+) not covered, (\d+) states' } | Select-Object -Last 1
    if ($cl -match 'coverage: (\d+) sources of blows found, (\d+) not covered, (\d+) states') {
        $summary['blows found (coverage)'] = [int]$matches[1]
        $summary['blows not covered (coverage)'] = [int]$matches[2]
        $summary['states that would not run'] = [int]$matches[3]
    } else { $fails.Add('coverage'); $cov | Select-Object -Last 5 | ForEach-Object { Write-Host "   $_" } }
    $cov | Where-Object { $_ -match '^(UNCOVERED|NOTRUN)' } | Set-Content (Join-Path $work 'coverage.txt')
    $cov | Where-Object { $_ -match '^UNCOVERED' } | ForEach-Object { Write-Host "   $_" }
    Write-Host ("   {0}" -f $cl)
    $env:SIMTRACE = $null
$env:SIM_JOB_LIMIT = $null
    $lines = Get-Content (Join-Path $work 'check.txt')
    # (a boss with no body offline walks through you there - each one counted)
    $summary['sim no body'] = @($lines | Where-Object { $_ -match '^NO BODY' } | Sort-Object -Unique).Count
    $lines | Where-Object { $_ -match '^NO BODY' } | Sort-Object -Unique | ForEach-Object { Write-Host "   $_" }
    if ($lines | Where-Object { $_ -match 'no part|blocked by your organization' }) {
        Write-Host "   a run was blocked (Device Guard) - run again"; $fails.Add('sim blocked')
    }
    $bad = @{}; $cur = ''; $scenes = 0
    foreach ($x in $lines) {
        if ($x -match '^CHECK (\S+ \S+)') { $cur = $matches[1] }
        elseif ($x -match '^\s+(!! )?(you|it) ') { $scenes++; if ($x -match '!!') { $bad[$cur] = 1 + [int]$bad[$cur] } }
    }
    $nbad = ($bad.Values | Measure-Object -Sum).Sum
    $summary['sim check scenes'] = $scenes
    $summary['sim check off'] = $nbad
    $prevFile = Join-Path $tests 'last_check.txt'
    if (Test-Path $prevFile) {
        $prev = @{}
        Get-Content $prevFile | ForEach-Object { $p = $_ -split "`t"; if (-not $Only -or $onlyList -contains ($p[0] -split ' ')[0]) { $prev[$p[0]] = [int]$p[1] } }
        foreach ($k in (@($bad.Keys) + @($prev.Keys) | Sort-Object -Unique)) {
            $a, $b = [int]$prev[$k], [int]$bad[$k]
            if ($b -gt $a) { $fails.Add("sim $k worse $a -> $b"); Write-Host "   WORSE  $k : $a -> $b" }
            elseif ($b -lt $a) { Write-Host "   better $k : $a -> $b" }
        }
    }
    $bad.GetEnumerator() | ForEach-Object { "$($_.Key)`t$($_.Value)" } | Set-Content (Join-Path $work 'this_check.txt')
    Write-Host ("   {0} scenes, {1} off" -f $scenes, $nbad)
    $diff = & luajit (Join-Path $tests 'movediff.lua') (Join-Path $mod 'scripts\true_range\moves_sim.lua') (Join-Path $work 'moves_sim.lua') 2>&1 | ForEach-Object { "$_" }
    $summary['data changed vs installed'] = (($diff | Select-Object -Last 1) -replace 'changed\s+', '')
    Write-Host "   data changed against what's installed: $($summary['data changed vs installed']) moves"
    if ($Install) {
        Copy-Item (Join-Path $work 'moves_sim.lua') (Join-Path $mod 'scripts\true_range\moves_sim.lua') -Force
        Write-Host "   installed into the mod"
    }
}

# the replays, in parallel (each its own luajit)
function Replay-All($jobs, $extra) {
    if (-not $extra) { $extra = '-quiet' }
    $results = @()
    # (longest first, by how long each took last time - unknown ones first of all: one long log
    # started last kept every core waiting on it)
    $timesFile = Join-Path $work 'replay_times.txt'
    $times = @{}
    if (Test-Path $timesFile) { Get-Content $timesFile | ForEach-Object { $t = $_ -split "`t"; if ($t.Count -eq 2) { $times[$t[0]] = [double]$t[1] } } }
    $jobs = @($jobs | Sort-Object -Descending { $k = "$([IO.Path]::GetFileName($_.log))|$($_.prefab)"; if ($times.ContainsKey($k)) { $times[$k] } else { 1e9 } })
    $wall = Get-Date
    $slots = [int]$env:NUMBER_OF_PROCESSORS
    $running = @()
    $i = 0
    while ($i -lt $jobs.Count -or $running.Count -gt 0) {
        while ($i -lt $jobs.Count -and $running.Count -lt $slots) {
            $j = $jobs[$i]; $i++
            $outf = Join-Path $work ("rp_{0}.txt" -f $i)
            # (a log played with Uncompromising Mode / Tropical Experience on: replayed with their data and scripts too, as the game
            # had them - a UM bench log replayed without, its Mock Dragonfly 66 "missed", 0 with; 2026-10-26. VERIFY_OLD_MODS=1: none)
            if (-not $script:logMods) { $script:logMods = @{} }
            if (-not $script:logMods.ContainsKey($j.log)) {
                $head = Get-Content $j.log -TotalCount 3000 -ErrorAction SilentlyContinue
                $um = [bool]($head | Select-String -SimpleMatch 'workshop-3193922031' -Quiet)
                $te = [bool]($head | Select-String -SimpleMatch 'workshop-1505270912' -Quiet)
                $script:logMods[$j.log] = @{ um = $um; te = $te }
            }
            $lm = $script:logMods[$j.log]
            $jscripts = $scripts
            if (-not $env:VERIFY_OLD_MODS -and $lm.um) {
                $env:TR_MODS = if ($lm.te) { 'workshop-3193922031 workshop-1505270912' } else { 'workshop-3193922031' }
                $jscripts = Join-Path $work $(if ($lm.te) { 'game_scripts_umte' } else { 'game_scripts_um' })
            } elseif (-not $env:VERIFY_OLD_MODS -and $lm.te) {
                $env:TR_MODS = 'workshop-1505270912'
                $jscripts = Join-Path $work 'game_scripts_te'
            } else { Remove-Item Env:TR_MODS -ErrorAction SilentlyContinue }
            # (_hazards: the things bosses set off, drawn as the mod does - tests/replay_haz.lua)
            $args1 = if ($j.prefab -eq '_hazards') { @("`"$(Join-Path $tests 'replay_haz.lua')`"", "`"$mod`"", "`"$($j.log)`"") } else { @("`"$(Join-Path $tests 'replay.lua')`"", "`"$mod`"", "`"$($j.log)`"", "`"$jscripts`"", $j.prefab, $extra) }
            $p = Start-Process -FilePath 'luajit' -ArgumentList $args1 `
                -RedirectStandardOutput $outf -RedirectStandardError "$outf.err" -NoNewWindow -PassThru
            Remove-Item Env:TR_MODS -ErrorAction SilentlyContinue
            $running += [pscustomobject]@{ p = $p; out = $outf; job = $j; began = Get-Date }
        }
        Start-Sleep -Milliseconds 100
        $still = @()
        foreach ($r in $running) {
            if ($r.p.HasExited) {
                $text = (Get-Content $r.out -ErrorAction SilentlyContinue) + (Get-Content "$($r.out).err" -ErrorAction SilentlyContinue)
                $results += [pscustomobject]@{ job = $r.job; lines = $text; secs = ((Get-Date) - $r.began).TotalSeconds }
                Remove-Item $r.out, "$($r.out).err" -ErrorAction SilentlyContinue
            } else { $still += $r }
        }
        $running = $still
    }
    foreach ($r in $results) { $times["$([IO.Path]::GetFileName($r.job.log))|$($r.job.prefab)"] = [math]::Round($r.secs, 1) }
    $times.GetEnumerator() | ForEach-Object { "$($_.Key)`t$($_.Value)" } | Set-Content $timesFile
    $slow = $results | Sort-Object -Descending secs | Select-Object -First 3
    Write-Host ("   {0} replays, {1:N0}s on the clock; longest: {2}" -f $results.Count, ((Get-Date) - $wall).TotalSeconds, (($slow | ForEach-Object { "{0} {1} {2:N0}s" -f [IO.Path]::GetFileName($_.job.log), $_.job.prefab, $_.secs }) -join ', '))
    return $results
}
function Tally($results, $label) {
    $missed = 0; $false_in = 0; $flicker = 0; $strikes = 0; $errors = 0; $glitch = 0; $unchecked = 0; $short = 0; $idle = 0
    $detail = New-Object System.Collections.Generic.List[string]
    foreach ($r in $results) {
        foreach ($l in $r.lines) {
            if ($l -match '(\d+) strikes - (\d+) drawn, (\d+) missed; (\d+) drawn-in') { $strikes += [int]$matches[1]; $missed += [int]$matches[3]; $false_in += [int]$matches[4]; if ($l -match '; (\d+) unchecked') { $unchecked += [int]$matches[1] }; if ($l -match '; (\d+) short') { $short += [int]$matches[1] }; if ($l -match '; (\d+) idle-drawn') { $idle += [int]$matches[1] } }
            elseif ($l -match '(\d+) frames flickered') { $flicker += [int]$matches[1] }
            elseif ($l -match ': (\d+) glitches') { $glitch += [int]$matches[1] }
            elseif ($l -match '^(IDLEDRAW|MISSED|UNCHECKED|SHORT|FALSE|FLICKER|VANISH|SHRINK|JUMP|DROPPED|WOBBLE|SLIDE|OUTRAN|OVERDRAWN|LATE|OUTSIDE|FOLLOWS)') { $detail.Add($l) }
            elseif ($l -match '^ERROR|\b[Ee]rror:|traceback|attempt to') { $errors++; $detail.Add("ERROR $($r.job.prefab): $l") }
        }
    }
    $summary["$label strikes"] = $strikes
    $summary["$label missed"] = $missed
    # (a strike that couldn't be judged - an old log without what was set off traced: kept apart)
    $summary["$label unchecked"] = $unchecked
    # (struck, drawn - but the spot struck shown less than WARN_SECS before, though its move gave time)
    $summary["$label warned too late"] = $short
    $summary["$label drawn while it can't strike"] = $idle
    $summary["$label drawn-in no strike"] = $false_in
    $summary["$label flicker frames"] = $flicker
    $summary["$label errors"] = $errors
    $summary["$label glitches (vanish/shrink/jump/dropped/wobble)"] = $glitch
    Write-Host ("   {0} strikes: {1} missed, {2} drawn-in with no strike, {3} flicker frames, {4} glitches, {5} errors" -f $strikes, $missed, $false_in, $flicker, $glitch, $errors)
    $detail | Set-Content (Join-Path $work "$label.txt")
    $detail | Where-Object { $_ -match '^(MISSED|FLICKER|ERROR|VANISH|SHRINK|JUMP|DROPPED|WOBBLE|SLIDE|OUTRAN|OVERDRAWN|LATE|OUTSIDE|FOLLOWS)' } | Select-Object -First 25 | ForEach-Object { Write-Host "     $_" }
}

# 3. synthetic replay
if (Test-Path $traces) {
    Write-Host "== synthetic replay (the offline runs through the mod's own drawing)"
    $jobs = @(Get-ChildItem $traces -Filter *.trace | ForEach-Object { [pscustomobject]@{ log = $_.FullName; prefab = ($_.BaseName -replace '#\d+$', '') } } | Where-Object { -not $Only -or $onlyList -contains $_.prefab })
    Tally (Replay-All $jobs) 'synthetic'
}

# 4. real replay
Write-Host "== real replay (every game log kept)"
$client = Join-Path $env:USERPROFILE 'Documents\Klei\DoNotStarveTogether\client_log.txt'
if (Test-Path $client) {
    $first = Select-String -Path $client -Pattern '\[tr_trace\]' -List | Select-Object -First 1
    if ($first) {
        # (one game session, one log: told by its first 64KB - the game still writing to it, read
        # shared; the same session grown since, kept again over the old - not twice, its strikes
        # counted twice)
        $fs = [IO.File]::Open($client, 'Open', 'Read', 'ReadWrite')
        try {
            $buf = New-Object byte[] 65536
            $n = $fs.Read($buf, 0, $buf.Length)
            $sha = [Security.Cryptography.SHA1]::Create()
            $hash = ([BitConverter]::ToString($sha.ComputeHash($buf, 0, $n)) -replace '-', '').Substring(0, 12)
            $have = @(Get-ChildItem (Join-Path $tests 'logs') -Filter "*_$hash.txt")
            $len = $fs.Length
            # (how long the game's log was when kept - the kept one is written out longer: its
            # things on the ground a line a tick again, tools/expand_haz.lua)
            $keptLen = if ($have.Count -gt 0) { $side = "$($have[0].FullName).len"; if (Test-Path $side) { [int64](Get-Content $side) } else { $have[0].Length } } else { 0 }
            if ($have.Count -eq 0 -or $keptLen -lt $len) {
                $name = if ($have.Count -gt 0) { $have[0].Name } else { (Get-Item $client).LastWriteTime.ToString('yyyy-MM-dd_HHmm') + "_$hash.txt" }
                $fs.Position = 0
                $keptPath = Join-Path $tests "logs\$name"
                $out = [IO.File]::Create($keptPath)
                try { $fs.CopyTo($out) } finally { $out.Close() }
                Set-Content "$keptPath.len" $len
                & luajit (Join-Path $root 'tools\expand_haz.lua') $keptPath | ForEach-Object { Write-Host "   $_" }
                Write-Host ("   kept the newest game log: $name" + $(if ($have.Count -gt 0) { ' (the same session, grown)' } else { '' }))
            }
        } finally { $fs.Close() }
    }
}
$jobs = @()
foreach ($log in Get-ChildItem (Join-Path $tests 'logs') -Filter *.txt) {
    $prefabs = Select-String -Path $log.FullName -Pattern '\[tr_trace\] [\d\.]+ ([\w]+) after' | ForEach-Object { $_.Matches[0].Groups[1].Value } | Sort-Object -Unique
    foreach ($pf in $prefabs) { if (-not $Only -or $onlyList -contains $pf) { $jobs += [pscustomobject]@{ log = $log.FullName; prefab = $pf } } }
    if (Select-String -Path $log.FullName -Pattern '\[tr_haz\]' -List -Quiet) { $jobs += [pscustomobject]@{ log = $log.FullName; prefab = '_hazards' } }
}
# (the game's own word: each hit the mod in the game said it hadn't drawn ("drawn: NOT") in the
# newest log - what no replay sees: a thing the game never let it find (the War Machine's missiles))
$newest = Get-ChildItem (Join-Path $tests 'logs') -Filter *.txt | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($newest) {
    $nots = @(Select-String -Path $newest.FullName -Pattern 'you were struck by (\S+), [\d\.]+ from it - drawn: NOT' | ForEach-Object { $_.Matches[0].Groups[1].Value })
    $summary['game said NOT drawn (newest log)'] = $nots.Count
    $nots | Group-Object | Sort-Object Count -Descending | ForEach-Object { Write-Host ("   game NOT: {0} x{1}" -f $_.Name, $_.Count) }
}
Write-Host ("   {0} logs, {1} boss replays" -f (Get-ChildItem (Join-Path $tests 'logs') -Filter *.txt).Count, $jobs.Count)
# (-ask: the server's word as the game gets it - late for a boss coming in from far off)
if ($jobs.Count -gt 0) { Tally (Replay-All $jobs '-ask') 'real' }

# (what the game has installed: the very files tested here? - each by hash; else said, and failed:
# a fix tested here but never installed was once taken for in the game)
$game = 'D:\Games Manager\Games\steamapps\common\Don''t Starve Together\mods\true_range'
$notSame = @()
if (Test-Path $game) {
    Get-ChildItem $mod -Recurse -File | ForEach-Object {
        $other = Join-Path $game $_.FullName.Substring($mod.Length)
        if (-not (Test-Path -LiteralPath $other) -or (Get-FileHash $_.FullName -Algorithm SHA1).Hash -ne (Get-FileHash -LiteralPath $other -Algorithm SHA1).Hash) {
            $notSame += $_.FullName.Substring($mod.Length)
        }
    }
    $summary['installed in the game'] = if ($notSame.Count -eq 0) { 'same as tested' } else { "DIFFERENT ($($notSame.Count) files)" }
    if ($notSame.Count -gt 0) { $notSame | Select-Object -First 5 | ForEach-Object { Write-Host "   not installed: $_" }; Write-Host "   (tools\install.ps1 puts it there)" }
}

# 5. summary, against the last one
Write-Host "== summary"
$lastFile = Join-Path $tests 'last_summary.txt'
# (-Only: a part of it - not set against the whole last time, nor kept as it)
if ($Only) { $lastFile = Join-Path $work ('last_summary_only_' + ($Only -replace '[^\w]', '_') + '.txt'); Write-Host "   (-Only $Only - these bosses alone, against the last -Only run)" }
$last = @{}
if (Test-Path $lastFile) { Get-Content $lastFile | ForEach-Object { $p = $_ -split "`t"; $last[$p[0]] = $p[1] } }
$worseIsUp = 'off|missed|no strike|flicker|errors|fallbacks|glitches|slivers|spikes|no body|slid|not covered|would not run'
foreach ($k in $summary.Keys) {
    $v = "$($summary[$k])"; $was = $last[$k]
    $mark = ''
    if ($was -ne $null -and $was -ne $v -and ($v -as [double]) -ne $null -and ($was -as [double]) -ne $null) {
        $up = [double]$v -gt [double]$was
        if ($k -match $worseIsUp) { $mark = if ($up) { '  WORSE (was ' + $was + ')' } else { '  better (was ' + $was + ')' } }
        else { $mark = "  (was $was)" }
        if ($k -match $worseIsUp -and $up) { $fails.Add("$k $was -> $v") }
    }
    Write-Host ("   {0,-36} {1}{2}" -f $k, $v, $mark)
}
$summary.GetEnumerator() | ForEach-Object { "$($_.Key)`t$($_.Value)" } | Set-Content $lastFile
if (-not $NoSim -and -not $Only -and (Test-Path (Join-Path $work 'this_check.txt'))) { Copy-Item (Join-Path $work 'this_check.txt') (Join-Path $tests 'last_check.txt') -Force }
if ($fails.Count -eq 0) { Write-Host "ALL GOOD" } else { Write-Host ("{0} THINGS WORSE OR FAILING:" -f $fails.Count); $fails | ForEach-Object { Write-Host "   $_" } }
