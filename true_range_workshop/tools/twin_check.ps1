# powershell -File tools\twin_check.ps1 [-Run <bench_logs folder>]
# A state that begins with one animation or another (picked at random, by where you are, by how far): run offline down
# one way only, the move known by that animation alone - Bearger's butt_pre_L / _R, the Shadow Runner's attack_quick /
# attack (2026-10-28). From the testbench's traces ([tr_trace] ... state= t=0 ... anim=): each boss's states, the
# animations each began with, and which of those the data has a move for - a state with some known, some not, is one.
param([string]$Run = "")
$root = Split-Path -Parent $PSScriptRoot
if ($Run -eq "") { $Run = (Get-ChildItem (Join-Path $root 'tests\work\bench_logs') -Directory | Where-Object { $_.Name -match '_shares$' } | Sort-Object LastWriteTime | Select-Object -Last 1).FullName }
$data = Join-Path (Split-Path -Parent $root) 'true_range\scripts\true_range'
# (every move's first animation, by boss: moves_sim*.lua, "boss = {" then "name = { ... anims = { "a", ...")
$keys = @{}
foreach ($f in Get-ChildItem $data -Filter 'moves_sim*.lua') {
    $boss = $null
    foreach ($l in [IO.File]::ReadLines($f.FullName)) {
        if ($l -match '^\s{4}\[?"?([\w]+)"?\]? = \{\s*$') { $boss = $Matches[1] }
        elseif ($boss -ne $null -and $l -match 'anims = \{ "([^"]+)"') { $keys["$boss|$($Matches[1])"] = $true }
    }
}
$seen = @{}
foreach ($f in Get-ChildItem $Run -Filter '*.txt') {
    foreach ($l in [IO.File]::ReadLines($f.FullName)) {
        if ($l -match '\[tr_trace\] \S+ (\S+) after state=(\S+) t=0\.000 .*anim=(\S+)') {
            $k = "$($Matches[1])|$($Matches[2])"
            if (-not $seen.ContainsKey($k)) { $seen[$k] = @{} }
            $seen[$k][$Matches[3]] = $true
        }
    }
}
foreach ($k in ($seen.Keys | Sort-Object)) {
    $boss = $k.Split('|')[0]
    $anims = @($seen[$k].Keys)
    if ($anims.Count -lt 2) { continue }
    $known = @($anims | Where-Object { $keys.ContainsKey("$boss|$_") })
    $unknown = @($anims | Where-Object { -not $keys.ContainsKey("$boss|$_") })
    if ($known.Count -gt 0 -and $unknown.Count -gt 0) { "{0}: known {1} | not in the data {2}" -f $k, ($known -join ','), ($unknown -join ',') }
}
