# powershell -File tools\lag_jumps.ps1 -Log <client_log.txt> [-Prefab moonmaw_lavae] [-Jump .8]
# "Jump then back" from what the game really drew ([tr_lagdraw] t prefab guid map x z rot boss bx bz ...): where a move's shape
# was drawn against where the boss was shown, frame by frame; a frame whose offset moves Jump or more, and goes back
# within 3 frames - the lava pups' "jump 1.0 then back" (2026-10-28). Counts by prefab and move, with the times.
param([string]$Log, [string]$Prefab = "", [double]$Jump = .8, [int]$Show = 8)
$last = @{}; $hist = @{}; $out = @{}; $times = @{}
foreach ($l in [IO.File]::ReadLines($Log)) {
    if ($l -notmatch '\[tr_lagdraw\] (\S+) (\S+) (\d+) \S+ (\S+) (\S+) \S+ boss (\S+) (\S+) .*move=(\S+)') { continue }
    $t = [double]$Matches[1]; $pf = $Matches[2]; $g = $Matches[3]
    if ($Prefab -ne "" -and $pf -ne $Prefab) { continue }
    $ox = [double]$Matches[4] - [double]$Matches[6]; $oz = [double]$Matches[5] - [double]$Matches[7]
    $k = "$g|$($Matches[8])"
    $h = $hist[$k]
    if ($null -eq $h -or $t - $h[$h.Count - 1][0] -gt .15) { $h = [System.Collections.Generic.List[object]]::new(); $hist[$k] = $h }
    $h.Add(@($t, $ox, $oz))
    $n = $h.Count
    # (the frame 3 back jumped from the one before it, and now within .3 of where it was before the jump)
    if ($n -ge 5) {
        $a = $h[$n - 5]; $b = $h[$n - 4]
        $jx = $b[1] - $a[1]; $jz = $b[2] - $a[2]
        if ($jx * $jx + $jz * $jz -ge $Jump * $Jump) {
            foreach ($i in ($n - 3)..($n - 1)) {
                $c = $h[$i]
                if (($c[1] - $a[1]) * ($c[1] - $a[1]) + ($c[2] - $a[2]) * ($c[2] - $a[2]) -lt .09) {
                    $key = "$pf $($Matches[8])"
                    $out[$key] = 1 + [int]$out[$key]
                    if (-not $times.ContainsKey($key)) { $times[$key] = @() }
                    $times[$key] += ("{0:N3}({1:N1})" -f $b[0], [Math]::Sqrt($jx * $jx + $jz * $jz))
                    break
                }
            }
        }
    }
}
foreach ($k in ($out.Keys | Sort-Object { -$out[$_] })) { "{0,-40} {1,4}  {2}" -f $k, $out[$k], (($times[$k] | Select-Object -First $Show) -join ' ') }
if ($out.Count -eq 0) { "no jump-and-back of $Jump or more" }
