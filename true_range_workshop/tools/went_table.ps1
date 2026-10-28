# powershell -File tools\went_table.ps1 [-Dir <bench_replay folder or a folder of replay outputs>] [-Min 1]
# Every leap set as it stops aiming, every go the replays saw (tests/replay.lua "WENT" lines): how far it really went against
# its run offline, after a target or not - by boss and move. A move going (median) Min or more off its run is a leap the data
# draws too long or too short - Klaus' bite after you, 8.5 of 15 (2026-10-28): the class to look for in every boss, not one.
param([string]$Dir = "", [double]$Min = 1)
$root = Split-Path -Parent $PSScriptRoot
if ($Dir -eq "") {
    $Dir = (Get-ChildItem (Join-Path $root 'tests\work\bench_replay') -Directory | Sort-Object LastWriteTime | Select-Object -Last 1).FullName
}
$rows = @{}
foreach ($f in Get-ChildItem $Dir -Filter '*.txt' -File) {
    foreach ($line in [IO.File]::ReadLines($f.FullName)) {
        if ($line -notmatch '^WENT (\S+) (\S+) (\S+) offline=(\S+) real=(\S+)(?: its target (\S+) off)?') { continue }
        # (one that got to whom it went for - stopped in its way, not going less far: told apart, "reached")
        $reached = $Matches[6] -ne $null -and [double]$Matches[6] -gt 0 -and [double]$Matches[5] -ge [double]$Matches[6] - 2.5
        $k = "$($Matches[1]) $($Matches[2]) $($Matches[3])$(if ($reached) { ' reached' } else { '' })"
        if (-not $rows.ContainsKey($k)) { $rows[$k] = New-Object System.Collections.Generic.List[object] }
        $rows[$k].Add(@([double]$Matches[4], [double]$Matches[5]))
    }
}
function Med($xs) { $s = @($xs | Sort-Object); if ($s.Count -eq 0) { return 0 } return $s[[int][Math]::Floor(($s.Count - 1) / 2)] }
$out = foreach ($k in $rows.Keys) {
    $g = $rows[$k]
    $off = Med ($g | ForEach-Object { $_[0] }); $real = Med ($g | ForEach-Object { $_[1] })
    $diff = Med ($g | ForEach-Object { $_[1] - $_[0] })
    [pscustomobject]@{ Go = $k; N = $g.Count; Offline = [Math]::Round($off, 2); Real = [Math]::Round($real, 2); Diff = [Math]::Round($diff, 2) }
}
$out = @($out | Sort-Object { -[Math]::Abs($_.Diff) })
Write-Host "$($out.Count) leaps seen in $Dir"
$out | Where-Object { [Math]::Abs($_.Diff) -ge $Min } | Format-Table -AutoSize | Out-String -Width 200 | Write-Host
Write-Host "(within $Min of their runs: $(@($out | Where-Object { [Math]::Abs($_.Diff) -lt $Min }).Count))"
