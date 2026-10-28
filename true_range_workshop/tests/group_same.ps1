# powershell -File tests\group_same.ps1 <mod root> <client_log> <prefab> [from] [to]
# A boss's shapes from a game log, with the mod's own true_range/lines on stand-in entities that
# carry their children as the game does (tests/replay.lua REAL_LINES): drawn in groups, turned
# with them, against drawn piece by piece (NO_GROUPS) - every piece showing, frame by frame, the
# same; else the frames where a group showed something other than was meant (the first few told)
param([string]$mod, [string]$log, [string]$prefab, [string]$from = "", [string]$to = "")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
Push-Location $root
try {
    $extra = @()
    if ($from -ne "") { $extra += $from; $extra += $to }
    $env:REAL_LINES = 1; $env:REAL_HASH = 1
    $a = luajit tests\replay.lua $mod $log tests\work\game_scripts $prefab @extra 2>&1 | ForEach-Object { $_.ToString() } | Where-Object { $_ -like 'RH *' }
    $env:NO_GROUPS = 1
    $b = luajit tests\replay.lua $mod $log tests\work\game_scripts $prefab @extra 2>&1 | ForEach-Object { $_.ToString() } | Where-Object { $_ -like 'RH *' }
} finally {
    Remove-Item Env:REAL_LINES, Env:REAL_HASH, Env:NO_GROUPS -ErrorAction SilentlyContinue
    Pop-Location
}
$bad = 0
$shown = 0
for ($i = 0; $i -lt [Math]::Min($a.Count, $b.Count); $i++) {
    if ($a[$i] -ne $b[$i]) {
        $bad++
        if ($shown -lt 3) {
            $shown++
            $ta = $a[$i].Split(' ')[1]; $na = $a[$i].Split(' ')[2]; $nb = $b[$i].Split(' ')[2]
            # (which pieces differ: in the groups' frame only, and in the one laid piece by piece only)
            $sa = $a[$i].Substring($a[$i].IndexOf(' ', $a[$i].IndexOf(' ', 3) + 1) + 1).Split(';')
            $sb = $b[$i].Substring($b[$i].IndexOf(' ', $b[$i].IndexOf(' ', 3) + 1) + 1).Split(';')
            $onlyA = $sa | Where-Object { $sb -notcontains $_ }
            $onlyB = $sb | Where-Object { $sa -notcontains $_ }
            "DIFF $ta - groups $na pieces, piece by piece $nb; only in groups: $($onlyA.Count), e.g. $($onlyA | Select-Object -First 2); only piece by piece: $($onlyB.Count), e.g. $($onlyB | Select-Object -First 2)"
        }
    }
}
"group_same $prefab : $($a.Count) frames, $bad differ$(if ($a.Count -ne $b.Count) { " (frame counts $($a.Count) / $($b.Count))" })"
