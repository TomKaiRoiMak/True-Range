# powershell -File tests\tester_compare.ps1 -Env OLD_THING_GATE [-Logs <dir>] [-Filter *.txt] [-Bosses a,b] [-Mod <mod dir>]
# A change to the checkers themselves (replay.lua, replay_haz.lua), not the mod: the same mod, every log,
# every boss in it, run with env <Env>=1 (as before) and without (as now) - per boss where they differ:
# strikes, missed, by-thing (BYTHING), drawn-in-unstruck; and replay_haz per log. Every core.
# (compare.ps1 is two mods with one checker - not this.) Logs with things written only as they change
# must have gone through tools\expand_haz.lua first (tests\logs have, by tools\verify.ps1; the
# testbench's have not - expand a copy).
param([Parameter(Mandatory = $true)][string]$Env, [string]$Logs = "", [string]$Filter = "*.txt", [string[]]$Bosses, [string]$Mod = "")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
if ($Logs -eq "") { $Logs = Join-Path $root 'tests\logs' }
if ($Mod -eq "") { $Mod = Join-Path (Split-Path -Parent $root) 'true_range' }
$bossList = @(); if ($Bosses) { $bossList = @($Bosses | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
$work = Join-Path $root 'tests\work\tester_cmp'
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
New-Item -ItemType Directory -Force $work | Out-Null
$todo = @()
$n = 0
foreach ($l in Get-ChildItem $Logs -Filter $Filter) {
    $pf = @(Select-String $l.FullName -Pattern '\[tr_trace\] [\d.]+ (\w+) after' | ForEach-Object { $_.Matches[0].Groups[1].Value } | Sort-Object -Unique)
    $um = Select-String $l.FullName -Pattern 'moves of mods: Uncompromising|workshop-3193922031' -List -Quiet
    foreach ($b in @($pf) + @('_haz')) {
        if ($b -ne '_haz' -and $bossList.Count -gt 0 -and $bossList -notcontains $b) { continue }
        foreach ($v in 'old', 'new') {
            $n++
            $todo += [pscustomobject]@{ log = $l.FullName; name = $l.Name; um = $um; b = $b; v = $v; out = (Join-Path $work ("{0}_{1}.txt" -f $n, $v)) }
        }
    }
}
"tester_compare: $($todo.Count / 2) log x boss ($Env=1 as before)"
$max = [Math]::Max(1, [int]$env:NUMBER_OF_PROCESSORS)
$live = @()
$t0 = Get-Date
Push-Location $root
try {
    foreach ($j in $todo) {
        while (@($live | Where-Object { -not $_.HasExited }).Count -ge $max) { Start-Sleep -Milliseconds 100 }
        $live = @($live | Where-Object { -not $_.HasExited })
        $env:TR_MODS = if ($j.um) { 'workshop-3193922031' } else { '' }
        Set-Item "env:$Env" $(if ($j.v -eq 'old') { '1' } else { '' })
        $scr = if ($j.um) { 'tests\work\game_scripts_um' } else { 'tests\work\game_scripts' }
        $a = if ($j.b -eq '_haz') { @('tests\replay_haz.lua', "`"$Mod`"", "`"$($j.log)`"") } else { @('tests\replay.lua', "`"$Mod`"", "`"$($j.log)`"", $scr, $j.b) }
        $live += Start-Process luajit -ArgumentList $a -NoNewWindow -PassThru -RedirectStandardOutput $j.out -RedirectStandardError "$($j.out).err"
    }
    foreach ($p in $live) { $p.WaitForExit() }
} finally { Pop-Location; $env:TR_MODS = $null; Set-Item "env:$Env" '' }
"{0:N0}s on the clock" -f ((Get-Date) - $t0).TotalSeconds
function Count($f) {
    $c = @{ s = 0; m = 0; by = 0; fa = 0; err = 0 }
    foreach ($line in [IO.File]::ReadLines($f)) {
        if ($line -like 'MISSED*') { $c.m++ } elseif ($line -like 'BYTHING*') { $c.by++ } elseif ($line -like 'FALSE*') { $c.fa++ }
        elseif ($line -match '(\d+) strikes - ') { $c.s += [int]$Matches[1] }
    }
    if ((Get-Item "$f.err").Length -gt 0 -and (Select-String "$f.err" -Pattern '\b[Ee]rror' -Quiet)) { $c.err = 1 }
    return $c
}
$per = @{}
$pairs = @{}
foreach ($j in $todo) { $k = "$($j.b)|$($j.name)"; if (-not $pairs[$k]) { $pairs[$k] = @{ b = $j.b; log = $j.name } }; $pairs[$k][$j.v] = Count $j.out }
$T = @{}
foreach ($e in $pairs.Values) {
    if (-not $per[$e.b]) { $per[$e.b] = @{ os = 0; ns = 0; om = 0; nm = 0; ob = 0; nb = 0; of = 0; nf = 0; err = 0 } }
    $x = $per[$e.b]
    $x.os += $e.old.s; $x.ns += $e.new.s; $x.om += $e.old.m; $x.nm += $e.new.m; $x.ob += $e.old.by; $x.nb += $e.new.by
    $x.of += $e.old.fa; $x.nf += $e.new.fa; $x.err += $e.old.err + $e.new.err
    if ($e.old.m -ne $e.new.m -or $e.old.by -ne $e.new.by -or $e.old.s -ne $e.new.s) { "  {0} {1}: strikes {2}->{3} missed {4}->{5} bything {6}->{7}" -f $e.b, $e.log, $e.old.s, $e.new.s, $e.old.m, $e.new.m, $e.old.by, $e.new.by }
}
foreach ($k in ($per.Keys | Sort-Object)) {
    $x = $per[$k]
    foreach ($f in $x.Keys) { $T[$f] = $T[$f] + $x[$f] }
    if ($x.os -ne $x.ns -or $x.om -ne $x.nm -or $x.ob -ne $x.nb -or $x.of -ne $x.nf -or $x.err -gt 0) {
        "{0,-28} strikes {1}->{2}  missed {3}->{4}  bything {5}->{6}  drawn-in-no-strike {7}->{8}{9}" -f $k, $x.os, $x.ns, $x.om, $x.nm, $x.ob, $x.nb, $x.of, $x.nf, $(if ($x.err) { "  ERRORS $($x.err)" } else { "" })
    }
}
"TOTAL strikes {0}->{1}  missed {2}->{3}  bything {4}->{5}  drawn-in-no-strike {6}->{7}  errors {8}" -f $T.os, $T.ns, $T.om, $T.nm, $T.ob, $T.nb, $T.of, $T.nf, $T.err
