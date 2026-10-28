# powershell -File tools\check_te.ps1 [-NoSim] [-Only a,b]
# Tropical Experience's moves checked (as tools\check_te.ps1) with no game log: every boss it changes or adds run offline with
# check scenes (sim_moves.lua -check, SIMTRACE: each run written as a trace), then each trace through
# the mod's own drawing (tests/replay.lua, TR_MODS) - what the run struck, was it drawn? Side by side
# on every core. Run after tools\build_te.ps1 (the replays read true_range's moves_sim_te.lua).
param([switch]$NoSim, [string]$Only = "")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
Set-Location $root
$ws = 'D:\Games Manager\Games\steamapps\workshop\content\322330\1505270912'
$traces = Join-Path $root 'tests\work\traces_te'
$out = Join-Path $root 'tests\work\te_check'
$mod = Join-Path (Split-Path -Parent $root) 'true_range'
$onlyList = @($Only -split ',' | Where-Object { $_ })
if (-not $NoSim) {
    if (Test-Path $traces) { Get-ChildItem $traces -Filter *.trace | Where-Object { $onlyList.Count -eq 0 -or $onlyList -contains ($_.BaseName -replace '#\d+$', '') } | Remove-Item -Force }
    New-Item -ItemType Directory -Force $traces | Out-Null
    $envs = @{ SIMTRACE = $traces; SIM_MOD = $ws; SIM_MOD_SPEC = 'tools\sim_mods\te.lua'; SIM_MOD_ANIMS = 'tools\anim_lengths_te.lua'; SIM_MOD_CHANGED = '1'; SIM_JOB_LIMIT = '1200' }
    foreach ($k in $envs.Keys) { Set-Item "env:$k" $envs[$k] }
    $a = @('tools\sim_moves.lua', '"tests\work\te\check_te.lua"', 'tests\work\game_scripts_te', '-jobs', '-check')
    if ($onlyList.Count -gt 0) { $a += "-only=$Only" }
    $p = Start-Process luajit -ArgumentList $a -NoNewWindow -PassThru -RedirectStandardError 'tests\work\te\check_te.txt' -RedirectStandardOutput 'tests\work\te\check_te.out'
    $p.WaitForExit()
    foreach ($k in $envs.Keys) { [Environment]::SetEnvironmentVariable($k, $null, 'Process') }
    Get-Content 'tests\work\te\check_te.txt' | Select-String '^jobs:' | ForEach-Object { "sim: " + $_.Line }
}
New-Item -ItemType Directory -Force $out | Out-Null
$jobs = @(Get-ChildItem $traces -Filter *.trace | Where-Object { $onlyList.Count -eq 0 -or $onlyList -contains ($_.BaseName -replace '#\d+$', '') })
$env:TR_MODS = 'workshop-1505270912'
$max = [int]$env:NUMBER_OF_PROCESSORS
$running = @()
foreach ($j in $jobs) {
    while (@($running | Where-Object { -not $_.HasExited }).Count -ge $max) { Start-Sleep -Milliseconds 100 }
    $prefab = $j.BaseName -replace '#\d+$', ''
    $o = Join-Path $out ($j.BaseName + '.out')
    $running += Start-Process luajit -ArgumentList 'tests\replay.lua', "`"$mod`"", "`"$($j.FullName)`"", 'tests\work\game_scripts_te', $prefab -NoNewWindow -PassThru `
        -RedirectStandardOutput $o -RedirectStandardError "$o.err"
}
$running | ForEach-Object { $_.WaitForExit() }
[Environment]::SetEnvironmentVariable('TR_MODS', $null, 'Process')
# (per boss: strikes, drawn, missed - and every missed line)
$tot = @{ s = 0; m = 0; f = 0 }
$rows = foreach ($j in $jobs) {
    $o = Join-Path $out ($j.BaseName + '.out')
    $sum = Get-Content $o -ErrorAction SilentlyContinue | Select-String 'strikes - (\d+) drawn, (\d+) missed; (\d+) drawn-in' | Select-Object -Last 1
    $err = Get-Content $o, "$o.err" -ErrorAction SilentlyContinue | Select-String '^ERROR|traceback|attempt to' | Select-Object -First 1
    if ($sum) {
        $s = [int]$sum.Matches[0].Groups[1].Value + [int]$sum.Matches[0].Groups[2].Value; $m = [int]$sum.Matches[0].Groups[2].Value; $f = [int]$sum.Matches[0].Groups[3].Value
        $tot.s += $s; $tot.m += $m; $tot.f += $f
        [pscustomobject]@{ trace = $j.BaseName; strikes = $s; missed = $m; false = $f; error = if ($err) { $err.Line } else { '' } }
    } else {
        [pscustomobject]@{ trace = $j.BaseName; strikes = 0; missed = 0; false = 0; error = if ($err) { $err.Line } else { 'no summary' } }
    }
}
$rows | Where-Object { $_.missed -gt 0 -or $_.error -ne '' } | Sort-Object missed -Descending | Format-Table -AutoSize | Out-String -Width 220
"{0} traces: strikes {1}, missed {2}, drawn-in with none {3}" -f $jobs.Count, $tot.s, $tot.m, $tot.f

