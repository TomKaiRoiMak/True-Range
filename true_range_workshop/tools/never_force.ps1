# powershell -File tools\never_force.ps1 -Bench <run_bench output> -Out <force file>
# The moves a full bench never saw strike (tools/bench_lock.lua's "boss: NEVER a, b" lines) as a -Force file for
# tools/run_bench.ps1: "boss state state ..." - each move by its first animation (a move's name is its first animation's,
# "~..." and "@..." its variants), the state that plays it found in the boss's stategraph (its prefab's SetStateGraph; the
# game's scripts with Uncompromising Mode's over them, tests/work/game_scripts_um). A move no state plays is said, not forced.
param([string]$Bench, [string]$Out, [string]$Scripts = "", [string]$UmPost = "D:\Games Manager\Games\steamapps\workshop\content\322330\3193922031\postinit\stategraphs")
$root = Split-Path -Parent $PSScriptRoot
if ($Scripts -eq "") { $Scripts = Join-Path $root 'tests\work\game_scripts_um' }
$sgDir = Join-Path $Scripts 'stategraphs'
$pfDir = Join-Path $Scripts 'prefabs'
# (which stategraph each prefab uses: the files naming it, its SetStateGraph)
$sgOf = @{}
function SgOf($boss) {
    if ($sgOf.ContainsKey($boss)) { return $sgOf[$boss] }
    $sgs = @()
    foreach ($f in Get-ChildItem $pfDir -Filter '*.lua') {
        $t = [IO.File]::ReadAllText($f.FullName)
        if ($t -match ('Prefab\(\s*"' + [regex]::Escape($boss) + '"')) {
            foreach ($m in [regex]::Matches($t, 'SetStateGraph\("([^"]+)"\)')) { $sgs += $m.Groups[1].Value }
        }
    }
    $sgOf[$boss] = @($sgs | Select-Object -Unique)
    return $sgOf[$boss]
}
# (each stategraph's states by the animation they play first: anim -> state)
$statesOf = @{}
function StatesOf($sg) {
    if ($statesOf.ContainsKey($sg)) { return $statesOf[$sg] }
    $map = @{}
    # (and the states Uncompromising Mode adds to it (its postinit/stategraphs, AddStategraphPostInit - not in game_scripts_um),
    # and CommonStates' own: AddCombatStates' "attack" playing "atk" or its anims.attack, AddSimpleState's - the NEVER moves
    # found no state for, 2026-10-28)
    foreach ($p in @((Join-Path $sgDir "$sg.lua"), (Join-Path $UmPost "$sg.lua"))) {
        if (-not (Test-Path $p)) { continue }
        $t = [IO.File]::ReadAllText($p)
        $parts = [regex]::Split($t, 'State\s*\{')
        foreach ($part in $parts[1..($parts.Count - 1)]) {
            $n = [regex]::Match($part, 'name\s*=\s*"([^"]+)"')
            $a = [regex]::Match($part, 'PlayAnimation\(\s*"([^"]+)"')
            if ($n.Success -and $a.Success -and -not $map.ContainsKey($a.Groups[1].Value)) { $map[$a.Groups[1].Value] = $n.Groups[1].Value }
        }
        foreach ($m in [regex]::Matches($t, 'CommonStates\.AddSimpleState\(\s*\w+\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"')) {
            if (-not $map.ContainsKey($m.Groups[2].Value)) { $map[$m.Groups[2].Value] = $m.Groups[1].Value }
        }
        $c = [regex]::Match($t, 'CommonStates\.AddCombatStates\(([^\n]*(\n[^\n]*){0,12})')
        if ($c.Success) {
            $att = [regex]::Match($c.Groups[1].Value, '\battack\s*=\s*"([^"]+)"')
            $an = if ($att.Success) { $att.Groups[1].Value } else { 'atk' }
            if (-not $map.ContainsKey($an)) { $map[$an] = 'attack' }
        }
    }
    $statesOf[$sg] = $map
    return $map
}
$lines = @()
foreach ($l in Get-Content $Bench) {
    if ($l -match '^\s+(\S+): NEVER (.+)$') {
        $boss = $Matches[1]; $states = @(); $unknown = @()
        foreach ($mv in ($Matches[2] -split ',\s*')) {
            $anim = ($mv -split '[~@]')[0].Trim()
            $st = $null
            foreach ($sg in (SgOf $boss)) { $m = StatesOf $sg; if ($m.ContainsKey($anim)) { $st = $m[$anim]; break } }
            if ($st -ne $null) { $states += $st } else { $unknown += $mv }
        }
        $states = @($states | Select-Object -Unique)
        if ($states.Count -gt 0) { $lines += "$boss $($states -join ' ')" }
        if ($unknown.Count -gt 0) { Write-Host "$boss`: no state plays $($unknown -join ', ')" }
    }
}
[IO.File]::WriteAllLines($Out, $lines)
Write-Host "$($lines.Count) bosses to force -> $Out"
