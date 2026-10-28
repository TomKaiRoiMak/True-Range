# powershell -File tests\draw_compare.ps1 <client_log with [tr_draw]> <prefab> [mod root] [-Eps 0.001] [-Show 10]
# Where the game drew a move set as it stops aiming ([tr_draw], the local copy) against where the
# replay draws it from the same log (tests/replay.lua DRAWLOG), frame by frame: where from, its
# turning, the run, the shift - frames off by more than a hair counted, the first few shown
param([string]$log, [string]$prefab, [string]$mod = "", [string]$Eps = "", [int]$Show = 10)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
if ($mod -eq "") { $mod = Join-Path (Split-Path -Parent $root) 'true_range' }
$log = (Resolve-Path $log).Path
function Parse($line) {
    if ($line -match '\[tr_draw\] ([\d.]+) (\S+) (\S+) f=([\d.]+) at=([-\d.]+),([-\d.]+) rot=([-\d.]+) run=([-\d.]+) far=\S+ shift=(\S+) exact=(\S+)') {
        $sx, $sz = 0.0, 0.0
        if ($Matches[9] -ne '-') { $sp = $Matches[9].Split(','); $sx = [double]$sp[0]; $sz = [double]$sp[1] }
        return [pscustomobject]@{ t = [double]$Matches[1]; pf = $Matches[2]; move = $Matches[3]; f = [double]$Matches[4]; x = [double]$Matches[5]; z = [double]$Matches[6]
            rot = [double]$Matches[7]; run = [double]$Matches[8]; sx = $sx; sz = $sz; exact = $Matches[10]; line = $line }
    }
    return $null
}
$game = @(Select-String -Path $log -Pattern "\[tr_draw\] [\d.]+ $prefab " | ForEach-Object { Parse $_.Line } | Where-Object { $_ })
Push-Location $root
try {
    $env:DRAWLOG = 1
    if ($Eps -ne "") { $env:T_EPS = $Eps }
    $rep = @(luajit tests\replay.lua $mod $log tests\work\game_scripts $prefab -v 2>&1 | ForEach-Object { $_.ToString() } | Where-Object { $_ -like '*[tr_draw]*' } | ForEach-Object { Parse $_ } | Where-Object { $_ })
} finally {
    Remove-Item Env:DRAWLOG, Env:T_EPS -ErrorAction SilentlyContinue
    Pop-Location
}
$same, $off, $shown = 0, 0, 0
foreach ($g in $game) {
    $r = $rep | Where-Object { [Math]::Abs($_.t - $g.t) -lt .02 -and $_.move -eq $g.move } | Select-Object -First 1
    if (-not $r) { continue }
    $d = [Math]::Sqrt(($g.x - $r.x) * ($g.x - $r.x) + ($g.z - $r.z) * ($g.z - $r.z))
    $dr = [Math]::Abs((($g.rot - $r.rot) + 540) % 360 - 180)
    if ($d -lt .05 -and $dr -lt .5 -and [Math]::Abs($g.run - $r.run) -lt .01) { $same++ } else {
        $off++
        if ($shown -lt $Show) {
            $shown++
            "{0:N3} f={1} {2}: game at {3:N2},{4:N2} rot {5:N1} run {6} shift {7:N2},{8:N2} {9} | replay {10:N2},{11:N2} rot {12:N1} run {13} shift {14:N2},{15:N2} {16} | off {17:N2}" -f $g.t, $g.f, $g.move, $g.x, $g.z, $g.rot, $g.run, $g.sx, $g.sz, $g.exact, $r.x, $r.z, $r.rot, $r.run, $r.sx, $r.sz, $r.exact, $d
        }
    }
}
"draw_compare $prefab : game $($game.Count) frames, replay $($rep.Count); matched: same $same, off $off$(if ($Eps -ne '') { " (T_EPS $Eps)" })"
