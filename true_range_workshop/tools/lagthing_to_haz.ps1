# powershell -File tools\lagthing_to_haz.ps1 -Log <client_log.txt> -Out <trace.txt> [-Prefab shadowthrall_projectile_fx]
# Your game's own view of the things (tr_lagjoin [tr_lagthing]: where each was, every frame) as a trace tests/replay_haz.lua
# reads ([tr_haz] lines, GONE after its last) - the drawer run offline on what a player's game really saw, not the server's
# 15-a-second ticks: the Ink Blights' landings tried that way, 2026-10-28. No blows in it: for how what's drawn moves (LANDWOB_V).
param([string]$Log, [string]$Out, [string]$Prefab = "shadowthrall_projectile_fx")
$last = @{}
$w = New-Object System.IO.StreamWriter($Out, $false, (New-Object System.Text.UTF8Encoding $false))
foreach ($l in [IO.File]::ReadLines($Log)) {
    $i = $l.IndexOf('[tr_lagthing] ')
    if ($i -lt 0) { continue }
    $p = $l.Substring($i + 14).Split(' ')
    if ($Prefab -ne "" -and $p[1] -ne $Prefab) { continue }
    $w.WriteLine("[tr_haz] $($p[0]) $($p[1]) guid=$($p[2]) pos=$($p[3]),$($p[5]) rot=0.0 you=$($p[3]),$($p[5]) y=$($p[4]) scale=1.000")
    $last[$p[2]] = @($p[0], $p[1])
}
foreach ($g in $last.Keys) { $t = [double]$last[$g][0] + 1 / 30; $w.WriteLine(("[tr_haz] {0:F3} {1} guid={2} GONE" -f $t, $last[$g][1], $g)) }
$w.Close()
"$($last.Count) things -> $Out"
