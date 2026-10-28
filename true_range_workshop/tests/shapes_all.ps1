# powershell -File tests\shapes_all.ps1 [-Old <mod dir>] [-New <mod dir>] [-Logs pattern] [-Bosses a,b]
# What's drawn looked at as shapes (replay.lua SHAPE_CHECK=1, tests/shapecheck.lua), every kept game log,
# every boss in it, two versions side by side: frames with two shapes over each other (OVERLAP), its
# pieces or holes other for a frame or two (SPLIT), a frame unlike those either side (MORPH), an
# outline left open (OPEN) - per boss where they differ, and the totals. Every core.
param([string]$Old = "", [string]$New = "", [string]$Logs = "*.txt", [string[]]$Bosses, [int]$Max = 0)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
if ($Old -eq "") { $Old = 'D:\Games Manager\Games\steamapps\common\Don''t Starve Together\mods\true_range' }
if ($New -eq "") { $New = Join-Path (Split-Path -Parent $root) 'true_range' }
$bossList = @(); if ($Bosses) { $bossList = @($Bosses | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
$work = Join-Path $root 'tests\work\shapes'
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
New-Item -ItemType Directory -Force $work | Out-Null
# (the bosses in each log - compare.ps1's list, kept by name, size and time)
$bossCache = Join-Path $root 'tests\work\cmp_cache\bosses'
New-Item -ItemType Directory -Force $bossCache | Out-Null
$todo = @()
$n = 0
foreach ($l in Get-ChildItem (Join-Path $root 'tests\logs') -Filter $Logs) {
    $ck = Join-Path $bossCache ("{0}_{1}_{2}.txt" -f $l.BaseName, $l.Length, $l.LastWriteTimeUtc.Ticks)
    if (Test-Path $ck) { $pf = @(Get-Content $ck | Where-Object { $_ }) }
    else {
        $pf = @(Select-String $l.FullName -Pattern '\[tr_trace\] [\d.]+ (\w+) after' | ForEach-Object { $_.Matches[0].Groups[1].Value } | Sort-Object -Unique)
        Set-Content -Path $ck -Value $pf -Encoding ascii
    }
    # (a game with Uncompromising Mode on - the mod says so as it starts: its moves on too, its scripts)
    $um = Select-String $l.FullName -Pattern 'moves of mods: Uncompromising' -List -Quiet
    foreach ($b in $pf) {
        if ($bossList.Count -gt 0 -and $bossList -notcontains $b) { continue }
        foreach ($v in @(@{ n = 'old'; d = $Old }, @{ n = 'new'; d = $New })) {
            $n++
            $todo += [pscustomobject]@{ log = $l.FullName; um = $um; b = $b; v = $v.n; dir = $v.d; out = (Join-Path $work ("{0}_{1}.txt" -f $n, $v.n)) }
        }
    }
}
"shapes: $($todo.Count / 2) log x boss"
$env:SHAPE_CHECK = '1'; $env:WHOLE = '1'
$max = if ($Max -gt 0) { $Max } else { [Math]::Max(1, [int]$env:NUMBER_OF_PROCESSORS) }
$live = @()
$t0 = Get-Date
Push-Location $root
try {
    foreach ($j in $todo) {
        while (@($live | Where-Object { -not $_.HasExited }).Count -ge $max) { Start-Sleep -Milliseconds 100 }
        $live = @($live | Where-Object { -not $_.HasExited })
        $env:TR_MODS = if ($j.um) { 'workshop-3193922031' } else { '' }
        $scr = if ($j.um) { 'tests\work\game_scripts_um' } else { 'tests\work\game_scripts' }
        $live += Start-Process luajit -ArgumentList @('tests\replay.lua', "`"$($j.dir)`"", "`"$($j.log)`"", $scr, $j.b) -NoNewWindow -PassThru `
            -RedirectStandardOutput $j.out -RedirectStandardError "$($j.out).err"
    }
    foreach ($p in $live) { $p.WaitForExit() }
} finally { Pop-Location; $env:SHAPE_CHECK = $null; $env:WHOLE = $null; $env:TR_MODS = $null }
"{0:N0}s on the clock" -f ((Get-Date) - $t0).TotalSeconds
$per = @{}
$T = @{ old = @(0, 0, 0, 0); new = @(0, 0, 0, 0) }
foreach ($j in $todo) {
    $line = Get-Content $j.out -ErrorAction SilentlyContinue | Where-Object { $_ -match 'shapes - (\d+) overlap, (\d+) split, (\d+) morph, (\d+) open-edge' } | Select-Object -Last 1
    if ($line -notmatch 'shapes - (\d+) overlap, (\d+) split, (\d+) morph, (\d+) open-edge') { continue }
    $c = @([int]$Matches[1], [int]$Matches[2], [int]$Matches[3], [int]$Matches[4])
    if (-not $per[$j.b]) { $per[$j.b] = @{ old = @(0, 0, 0, 0); new = @(0, 0, 0, 0) } }
    for ($i = 0; $i -lt 4; $i++) { $per[$j.b][$j.v][$i] += $c[$i]; $T[$j.v][$i] += $c[$i] }
    # (each kind's lines kept for the new one, to look at)
    if ($j.v -eq 'new') { Get-Content $j.out | Where-Object { $_ -match '^(OVERLAP|SPLIT|MORPH|OPEN|OVERLAPS) ' } | Add-Content (Join-Path $work 'new_lines.txt') }
}
foreach ($k in ($per.Keys | Sort-Object)) {
    $o, $w = $per[$k].old, $per[$k].new
    if (($o -join ',') -ne ($w -join ',') -or ($w | Measure-Object -Sum).Sum -gt 0) {
        "{0,-30} overlap {1}->{2}  split {3}->{4}  morph {5}->{6}  open {7}->{8}" -f $k, $o[0], $w[0], $o[1], $w[1], $o[2], $w[2], $o[3], $w[3]
    }
}
"TOTAL overlap {0}->{1}  split {2}->{3}  morph {4}->{5}  open {6}->{7}" -f $T.old[0], $T.new[0], $T.old[1], $T.new[1], $T.old[2], $T.new[2], $T.old[3], $T.new[3]
# (and over all: outline running inside another shape, as long; line ends left loose - an outline cut
# to dashes shows as many more of them: tests/shapecheck.lua)
$E = @{ old = @(0, 0); new = @(0, 0) }
foreach ($j in $todo) {
    $line = Get-Content $j.out -ErrorAction SilentlyContinue | Where-Object { $_ -match '\(([\d.]+) long\), \d+ dashed \((\d+) loose ends in all\)' } | Select-Object -Last 1
    if ($line -match '\(([\d.]+) long\), \d+ dashed \((\d+) loose ends in all\)') { $E[$j.v][0] += [double]$Matches[1]; $E[$j.v][1] += [int]$Matches[2] }
}
"TOTAL outline inside another {0:N0}->{1:N0}  loose line ends {2:N0}->{3:N0}" -f $E.old[0], $E.new[0], $E.old[1], $E.new[1]
