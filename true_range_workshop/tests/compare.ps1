# powershell -File tests\compare.ps1 [-Old <mod dir>] [-New <mod dir>] [-Bosses a,b] [-Logs pattern]
# Two versions of the mod side by side over every kept game log (tests/logs), every boss in each:
# strikes missed (MISSED), drawn-in with none (FALSE), yellow never gone red (YELLOW) - per boss,
# where they differ, the missed lines themselves, and the totals.
# -Old: the one installed in the game, unless said. -New: the source (true_range).
# Each version's replays kept (tests/work/cmp_cache/<its files' hash>): one not changed since is
# not run again - only the new one is. luajit run straight, as many at once as there are cores -
# not a PowerShell job each (some 500 of them, each a whole PowerShell starting up).
param([string]$Old = "", [string]$New = "", [string[]]$Bosses, [string]$Logs = "*.txt")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
if ($Old -eq "") { $Old = 'D:\Games Manager\Games\steamapps\common\Don''t Starve Together\mods\true_range' }
if ($New -eq "") { $New = Join-Path (Split-Path -Parent $root) 'true_range' }
$Old = (Resolve-Path $Old).Path; $New = (Resolve-Path $New).Path
$bossList = @(); if ($Bosses) { $bossList = @($Bosses | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
$sha = [System.Security.Cryptography.SHA1]::Create()
function HashOf($dir) {
    # (the mod's own scripts and the replay itself: a change to either is another version)
    $files = @(Get-ChildItem (Join-Path $dir 'scripts\true_range') -Recurse -File) + @(Get-Item (Join-Path $here 'replay.lua'))
    $all = New-Object System.IO.MemoryStream
    foreach ($f in ($files | Sort-Object Name)) { $b = [IO.File]::ReadAllBytes($f.FullName); $all.Write($b, 0, $b.Length) }
    return ([BitConverter]::ToString($sha.ComputeHash($all.ToArray())) -replace '-', '').Substring(0, 12)
}
$cacheRoot = Join-Path $root 'tests\work\cmp_cache'
$vers = @(@{ name = 'old'; dir = $Old; hash = (HashOf $Old) }, @{ name = 'new'; dir = $New; hash = (HashOf $New) })
foreach ($v in $vers) { $v.cache = Join-Path $cacheRoot $v.hash; New-Item -ItemType Directory -Force $v.cache | Out-Null }
# (every log, every boss in it)
$todo = @()
# (the bosses in each log: read once and kept by its name, size and time - every log read through on one
# core each time was most of the wait before any replay ran; the testbench's logs not here at all, its own
# check tools\run_bench.ps1)
$bossCache = Join-Path $cacheRoot 'bosses'
New-Item -ItemType Directory -Force $bossCache | Out-Null
foreach ($l in Get-ChildItem (Join-Path $root 'tests\logs') -Filter $Logs) {
    $ck = Join-Path $bossCache ("{0}_{1}_{2}.txt" -f $l.BaseName, $l.Length, $l.LastWriteTimeUtc.Ticks)
    if (Test-Path $ck) { $pf = @(Get-Content $ck | Where-Object { $_ }) }
    else {
        $pf = @(Select-String $l.FullName -Pattern '\[tr_trace\] [\d.]+ (\w+) after' | ForEach-Object { $_.Matches[0].Groups[1].Value } | Sort-Object -Unique)
        Set-Content -Path $ck -Value $pf -Encoding ascii
    }
    foreach ($b in $pf) {
        if ($bossList.Count -gt 0 -and $bossList -notcontains $b) { continue }
        foreach ($v in $vers) {
            $out = Join-Path $v.cache ("{0}__{1}.txt" -f $l.BaseName, $b)
            $todo += [pscustomobject]@{ log = $l.FullName; name = $l.Name; b = $b; v = $v.name; dir = $v.dir; out = $out }
        }
    }
}
$run = @($todo | Where-Object { -not (Test-Path $_.out) })
"compare: $($todo.Count / 2) log x boss; to run $($run.Count) (old $($vers[0].hash), new $($vers[1].hash))"
$max = [Math]::Max(1, [int]$env:NUMBER_OF_PROCESSORS)
$live = @()
Push-Location $root
try {
    foreach ($j in $run) {
        while (@($live | Where-Object { -not $_.p.HasExited }).Count -ge $max) { Start-Sleep -Milliseconds 100 }
        $live = @($live | Where-Object { -not $_.p.HasExited })
        $err = "$($j.out).err"
        $p = Start-Process luajit -ArgumentList @('tests\replay.lua', "`"$($j.dir)`"", "`"$($j.log)`"", 'tests\work\game_scripts', $j.b) -NoNewWindow -PassThru `
            -RedirectStandardOutput "$($j.out).tmp" -RedirectStandardError $err
        $live += [pscustomobject]@{ p = $p; j = $j }
    }
    foreach ($x in $live) { $x.p.WaitForExit() }
} finally { Pop-Location }
# (each run's lines that count, kept as the cache - written once it's done)
foreach ($j in $run) {
    $lines = @()
    foreach ($f in @("$($j.out).tmp", "$($j.out).err")) { if (Test-Path $f) { $lines += Get-Content $f; Remove-Item $f } }
    $lines | Where-Object { $_ -match '^(MISSED|FALSE|YELLOW)' -or $_ -like '*strikes - *' } | Set-Content $j.out -Encoding utf8
}
$by = @{}
foreach ($j in $todo) {
    $key = "$($j.b)|$($j.name)"
    if (-not $by[$key]) { $by[$key] = @{ b = $j.b; log = $j.name } }
    $by[$key][$j.v] = @(Get-Content $j.out)
}
$per = @{}
foreach ($e in $by.Values) {
    if (-not $per[$e.b]) { $per[$e.b] = @{ om = 0; nm = 0; of = 0; nf = 0; oy = 0; ny = 0 } }
    $x = $per[$e.b]
    $om = @($e.old | Where-Object { $_ -like 'MISSED*' }); $nm = @($e.new | Where-Object { $_ -like 'MISSED*' })
    $x.om += $om.Count; $x.nm += $nm.Count
    $x.of += @($e.old | Where-Object { $_ -like 'FALSE*' }).Count; $x.nf += @($e.new | Where-Object { $_ -like 'FALSE*' }).Count
    $x.oy += @($e.old | Where-Object { $_ -like 'YELLOW*' }).Count; $x.ny += @($e.new | Where-Object { $_ -like 'YELLOW*' }).Count
    Compare-Object $om $nm | ForEach-Object { "  $($e.b) $($e.log) $($_.SideIndicator) $($_.InputObject)" }
}
$T = @{ om = 0; nm = 0; of = 0; nf = 0; oy = 0; ny = 0 }
foreach ($k in ($per.Keys | Sort-Object)) {
    $x = $per[$k]
    foreach ($f in 'om', 'nm', 'of', 'nf', 'oy', 'ny') { $T[$f] += $x[$f] }
    if ($x.om -ne $x.nm -or $x.of -ne $x.nf -or $x.oy -ne $x.ny) {
        "{0,-28} missed {1}->{2}  drawn-in-no-strike {3}->{4}  yellow-never-red {5}->{6}" -f $k, $x.om, $x.nm, $x.of, $x.nf, $x.oy, $x.ny
    }
}
"TOTAL missed {0}->{1}  drawn-in-no-strike {2}->{3}  yellow-never-red {4}->{5}" -f $T.om, $T.nm, $T.of, $T.nf, $T.oy, $T.ny
