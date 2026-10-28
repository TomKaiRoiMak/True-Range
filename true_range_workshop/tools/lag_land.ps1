# powershell -File tools\lag_land.ps1 -Log <client_log.txt> [-Prefab shadowthrall_projectile_fx] [-Show 3]
# Thrown things in your game, frame by frame (tr_lagjoin [tr_lagthing] where it is, [tr_lagframe] where its landing is drawn):
# how far what's drawn is from where it really came down (its first frame at y <= .05), as it flies - and each one's
# drawn-point moves. The Ink Blight's balls guessed short and crept on in the player's game, 2026-10-28.
param([string]$Log, [string]$Prefab = "shadowthrall_projectile_fx", [int]$Show = 3)
$pos = @{}; $drawn = @{}
foreach ($l in [IO.File]::ReadLines($Log)) {
    $i = $l.IndexOf('[tr_lagthing] ')
    if ($i -ge 0) {
        $w = $l.Substring($i + 14).Split(' ')
        if ($w[1] -eq $Prefab) { if (-not $pos[$w[2]]) { $pos[$w[2]] = New-Object System.Collections.ArrayList }; [void]$pos[$w[2]].Add(@([double]$w[0], [double]$w[3], [double]$w[4], [double]$w[5])) }
        continue
    }
    $i = $l.IndexOf('[tr_lagframe] ')
    if ($i -ge 0) {
        $w = $l.Substring($i + 14).Split(' ')
        if ($w[1] -eq $Prefab -and $w[8] -eq 'grp=1') { $p = $w[9].Substring(3).Split(','); $drawn["$($w[2]) $($w[0])"] = @([double]$p[0], [double]$p[1]) }
    }
}
$errs = @(); $shown = 0
foreach ($g in $pos.Keys) {
    $s = $pos[$g]
    $land = $null
    foreach ($k in $s) { if ($k[2] -le .05 -and $k[0] -gt $s[0][0] + .1) { $land = $k; break } }
    if ($land -eq $null) { continue }
    $rows = @()
    foreach ($k in $s) {
        $d = $drawn["$g $('{0:F3}' -f $k[0])"]
        $e = if ($d) { [Math]::Sqrt(($d[0] - $land[1]) * ($d[0] - $land[1]) + ($d[1] - $land[3]) * ($d[1] - $land[3])) } else { $null }
        if ($e -ne $null -and $k[0] -le $land[0]) { $errs += $e }
        $rows += ('{0:F3} y={1,5:F2} pos={2:F2},{3:F2} drawn={4} err={5}' -f $k[0], $k[2], $k[1], $k[3], $(if ($d) { '{0:F2},{1:F2}' -f $d[0], $d[1] } else { '-' }), $(if ($e -ne $null) { '{0:F2}' -f $e } else { '-' }))
    }
    if ($shown -lt $Show) { $shown++; "== $g lands $('{0:F3}' -f $land[0]) at $('{0:F2},{1:F2}' -f $land[1], $land[3])"; $rows }
}
$errs = @($errs | Sort-Object)
if ($errs.Count -gt 0) { "drawn frames before landing $($errs.Count): err median $('{0:F2}' -f $errs[[int]($errs.Count / 2)]), p90 $('{0:F2}' -f $errs[[int]($errs.Count * .9)]), max $('{0:F2}' -f $errs[-1])" }
