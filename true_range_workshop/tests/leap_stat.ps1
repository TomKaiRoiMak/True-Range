# powershell -File tests\leap_stat.ps1 [mod root]
# Every kept game log (tests/logs), every boss in it with a move that sets where it strikes as it
# stops aiming (anchor "lock"): tests/replay.lua LEAP_STAT - its shape's jump the frame it stops
# aiming, and how far it goes and turns back after (set, it shouldn't move) - and the strikes
# missed and drawn-in with none, so a steadier shape isn't bought with a wrong one. Summed.
param([string]$mod = "")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
if ($mod -eq "") { $mod = Join-Path (Split-Path -Parent $root) 'true_range' }
$mod = (Resolve-Path $mod).Path
# (the bosses with such a move - from the mod's own data)
$prefabs = & luajit -e "package.path='$($mod -replace '\\','/')/scripts/?.lua;'..package.path DEGREES=math.pi/180 FRAMES=1/30 local D=require('true_range/moves_sim') for p,k in pairs(D) do if type(k)=='table' and p:sub(1,1)~='_' then for _,e in pairs(k.moves or k) do if type(e)=='table' and e.anchor=='lock' and not e.still then print(p) break end end end end"
$jobs = @()
foreach ($log in Get-ChildItem (Join-Path $here 'logs') -Filter *.txt) {
    $present = Select-String -Path $log.FullName -Pattern '\[tr_trace\] [\d.]+ (\w+) after' -List:$false |
        ForEach-Object { $_.Matches[0].Groups[1].Value } | Sort-Object -Unique | Where-Object { $prefabs -contains $_ }
    foreach ($pf in $present) {
        $jobs += Start-Job -ScriptBlock {
            param($root, $mod, $log, $pf)
            Set-Location $root
            $env:LEAP_STAT = 1
            $o = luajit tests\replay.lua $mod $log tests\work\game_scripts $pf 2>&1 | ForEach-Object { $_.ToString() }
            [pscustomobject]@{ pf = $pf; stat = ($o | Where-Object { $_ -like 'LEAP_STAT*' }); strikes = ($o | Where-Object { $_ -like '*strikes - *' } | Select-Object -Last 1) }
        } -ArgumentList $root, $mod, $log.FullName, $pf
    }
}
$res = $jobs | Wait-Job | Receive-Job
$jobs | Remove-Job
$tot = @{ goes = 0.0; lj = 0.0; tr = 0.0; rev = 0.0; fj = 0.0; fb = 0.0; missed = 0; drawnin = 0; strikes = 0 }
$by = @{}
foreach ($r in $res) {
    if ($r.stat -match ': (\d+) goes - jump at its lock ([\d.]+), after it went ([\d.]+) in all, turned back ([\d.]+) times.*far edge pulled back at its lock ([\d.]+), back after ([\d.]+)') {
        $g = [double]$Matches[1]
        $tot.goes += $g; $tot.lj += $g * [double]$Matches[2]; $tot.tr += $g * [double]$Matches[3]; $tot.rev += $g * [double]$Matches[4]; $tot.fj += $g * [double]$Matches[5]; $tot.fb += $g * [double]$Matches[6]; $fj5 = [double]$Matches[5]; $fb6 = [double]$Matches[6]
        if (-not $by[$r.pf]) { $by[$r.pf] = @{ goes = 0.0; tr = 0.0; rev = 0.0; lj = 0.0; fj = 0.0; fb = 0.0 } }
        $by[$r.pf].fj += $g * $fj5; $by[$r.pf].fb += $g * $fb6
        $by[$r.pf].goes += $g; $by[$r.pf].tr += $g * [double]$Matches[3]; $by[$r.pf].rev += $g * [double]$Matches[4]; $by[$r.pf].lj += $g * [double]$Matches[2]
    }
    if ($r.strikes -match '(\d+) strikes - \d+ drawn, (\d+) missed; (\d+) drawn-in') {
        $tot.strikes += [int]$Matches[1]; $tot.missed += [int]$Matches[2]; $tot.drawnin += [int]$Matches[3]
        if (-not $by[$r.pf]) { $by[$r.pf] = @{ goes = 0.0; tr = 0.0; rev = 0.0; lj = 0.0 } }
        $by[$r.pf].missed = [int]$by[$r.pf].missed + [int]$Matches[2]; $by[$r.pf].drawnin = [int]$by[$r.pf].drawnin + [int]$Matches[3]
    }
}
foreach ($k in ($by.Keys | Sort-Object)) {
    $b = $by[$k]
    if ($b.goes -gt 0) { "  {0,-24} {1,4} goes: lock jump {2:N2}, after went {3:N2}, turned back {4:N2}, far edge back at lock {7:N3} after {8:N3} | missed {5}, drawn-in {6}" -f $k, $b.goes, ($b.lj / $b.goes), ($b.tr / $b.goes), ($b.rev / $b.goes), [int]$b.missed, [int]$b.drawnin, ($b.fj / $b.goes), ($b.fb / $b.goes) }
}
$n = [Math]::Max(1, $tot.goes)
"LEAPS {0} goes: lock jump {1:N3}, after went {2:N3}, turned back {3:N3}, far edge back at lock {7:N3} after {8:N3} (each on average) | strikes {4}, missed {5}, drawn-in no strike {6}" -f $tot.goes, ($tot.lj / $n), ($tot.tr / $n), ($tot.rev / $n), $tot.strikes, $tot.missed, $tot.drawnin, ($tot.fj / $n), ($tot.fb / $n)
