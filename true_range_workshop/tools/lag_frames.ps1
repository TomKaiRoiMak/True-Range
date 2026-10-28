# powershell -File tools\lag_frames.ps1 -Log <client_log.txt>
# What your game really drew, frame by frame (tr_lagjoin's "[tr_lagframe] t prefab guid tri= seg= grp=" lines): for each
# monster or thing, the times its drawing was gone for 1-3 frames between frames it was there (a blink - the Umbral
# Abomination's warning glow going out a frame between its pulses, 2026-10-28), and its line count jumping and back
# (a part flicking in and out). The lag bench's own report sees only where a move's shape is, never this.
param([string]$Log, [int]$Show = 12)
$frames = New-Object 'System.Collections.Generic.SortedSet[double]'
$by = @{}   # "prefab guid" -> t -> seg count (lines laid) + fills
foreach ($l in [IO.File]::ReadLines($Log)) {
    $i = $l.IndexOf('[tr_lagframe] ')
    if ($i -lt 0) { continue }
    $w = $l.Substring($i + 14).Split(' ')
    $t = [double]$w[0]; [void]$frames.Add($t)
    $k = $w[1] + ' ' + $w[2]
    $tri = [int]($w[3].Substring(4)); $seg = [int]($w[6].Substring(4)); $grp = [int]($w[8].Substring(4))
    # (where it's drawn: the first of fills, lines, groups there - a gap with it 10 or more elsewhere either side is the testbench
    # moving the scene, not a blink: the Moonmaw's 8, 2026-10-28)
    $pos = $null
    foreach ($ai in 5, 7, 9) { $p = $w[$ai].Substring(3).Split(','); if ([double]$p[0] -ne 0 -or [double]$p[1] -ne 0) { $pos = @([double]$p[0], [double]$p[1]); break } }
    if (-not $by.ContainsKey($k)) { $by[$k] = @{} }
    $by[$k][$t] = @($tri, $seg, $grp, $pos)
}
$all = @($frames)
$idx = @{}; for ($i = 0; $i -lt $all.Count; $i++) { $idx[$all[$i]] = $i }
$rows = @()
foreach ($k in $by.Keys) {
    $h = $by[$k]
    $ts = @($h.Keys | Sort-Object)
    $blinks = @(); $parts = @()
    for ($j = 1; $j -lt $ts.Count; $j++) {
        $gap = $idx[$ts[$j]] - $idx[$ts[$j - 1]] - 1
        $pa = $h[$ts[$j - 1]][3]; $pb = $h[$ts[$j]][3]
        $moved = $pa -ne $null -and $pb -ne $null -and (($pa[0] - $pb[0]) * ($pa[0] - $pb[0]) + ($pa[1] - $pb[1]) * ($pa[1] - $pb[1])) -gt 100
        if ($gap -ge 1 -and $gap -le 3 -and -not $moved) { $blinks += ('{0:F3}+{1}' -f $ts[$j - 1], $gap) }
        # (its pieces down by over half for 1-2 frames, then back)
        if ($j -ge 2) {
            $a = $h[$ts[$j - 2]]; $b = $h[$ts[$j - 1]]; $c = $h[$ts[$j]]
            $na = $a[0] + $a[1] + $a[2]; $nb = $b[0] + $b[1] + $b[2]; $nc = $c[0] + $c[1] + $c[2]
            if ($na -ge 8 -and $nc -ge 8 -and $nb -lt 0.5 * [Math]::Min($na, $nc) -and $idx[$ts[$j]] - $idx[$ts[$j - 2]] -le 3) { $parts += ('{0:F3}' -f $ts[$j - 1]) }
        }
    }
    $rows += [pscustomobject]@{ who = $k; frames = $ts.Count; blinks = $blinks.Count; dips = $parts.Count; at = (($blinks + $parts) | Select-Object -First 6) -join ' ' }
}
"frames $($all.Count), drawers $($rows.Count)"
$rows | Where-Object { $_.blinks + $_.dips -gt 0 } | Sort-Object { -($_.blinks + $_.dips) } | Select-Object -First $Show | Format-Table -AutoSize who, frames, blinks, dips, at
# by prefab
$rows | Group-Object { ($_.who -split ' ')[0] } | ForEach-Object {
    [pscustomobject]@{ prefab = $_.Name; drawers = $_.Count; frames = ($_.Group | Measure-Object frames -Sum).Sum; blinks = ($_.Group | Measure-Object blinks -Sum).Sum; dips = ($_.Group | Measure-Object dips -Sum).Sum }
} | Sort-Object { -($_.blinks + $_.dips) } | Format-Table -AutoSize
