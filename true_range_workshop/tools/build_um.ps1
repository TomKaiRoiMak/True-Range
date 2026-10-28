# powershell -File tools\build_um.ps1
# Uncompromising Mode's moves, all of it, again - after the mod updates:
#   1. its scripts over the game's (mod_scripts.ps1), its animations' lengths (anim_lengths.ps1)
#   2. every boss it changes or adds, run in its world (SIM_MOD, SIM_MOD_CHANGED, sim_mods\um.lua)
#   3. the same bosses without it, by this same sim
#   4. only what differs, move by move (mod_diff.lua) -> true_range/scripts/true_range/moves_sim_um.lua
# Each run side by side on every core (-jobs).
# (-Mod 2039181790 -Name um_stable: the plain Uncompromising Mode, not its beta (3193922031) - its own moves, its own
# data file, moves_sim_um_stable.lua: the beta's drawn for it were none, true_range/moddata knowing only the beta's
# folder, the player 2026-10-22)
param([string]$Mod = '3193922031', [string]$Name = 'um')
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
Set-Location $root
$ws = "D:\Games Manager\Games\steamapps\workshop\content\322330\$Mod"
$work = Join-Path $root "tests\work\$Name"
$base = Join-Path $root 'tests\work\um_base'
New-Item -ItemType Directory -Force $work, $base | Out-Null
$sw = [Diagnostics.Stopwatch]::StartNew()
$start = Get-Date

powershell -File (Join-Path $here 'mod_scripts.ps1') -Mod $Mod -Name $Name
$zips = (Get-ChildItem (Join-Path $ws 'anim') -Filter *.zip).FullName
$animsFile = Join-Path $here "anim_lengths_$Name.lua"
& (Join-Path $here 'anim_lengths.ps1') -Out $animsFile @zips | Select-Object -Last 1
$outName = "moves_sim_$Name.lua"

function Sim($out, $scripts, $extra, [hashtable]$envs) {
    foreach ($k in $envs.Keys) { Set-Item "env:$k" $envs[$k] }
    $err = "$out.err"
    # (quoted: the folder's name has a space - "dont starve" - Start-Process splits it otherwise)
    $p = Start-Process luajit -ArgumentList (@('tools\sim_moves.lua', "`"$out`"", "`"$scripts`"", '-jobs') + $extra) -NoNewWindow -PassThru `
        -RedirectStandardError $err -RedirectStandardOutput "$out.out"
    $p.WaitForExit()
    foreach ($k in $envs.Keys) { Remove-Item "env:$k" }
    Get-Content $err | Select-String '^jobs:' | ForEach-Object { "  " + $_.Line }
}

"with the mod:"
# (SIM_JOB_LIMIT: no job stopped as hung for being slower than the last run - a fix to the sim can make
# one rightly take longer, the Celestial Champion's third form 24s -> 270s once it could teleport again)
Sim (Join-Path $work $outName) "tests\work\game_scripts_$Name" @() @{
    SIM_MOD = $ws; SIM_MOD_SPEC = 'tools\sim_mods\um.lua'; SIM_MOD_ANIMS = $animsFile; SIM_MOD_CHANGED = '1'; SIM_JOB_LIMIT = '1200' }
if (-not (Test-Path (Join-Path $work $outName)) -or (Get-Item (Join-Path $work $outName)).LastWriteTime -lt $start) {
    "the run with the mod wrote nothing - see $(Join-Path $work "$outName.err")"
    exit 1
}
$keys = @(Select-String (Join-Path $work $outName) -Pattern '^    \["([\w]+)"\] = \{' | ForEach-Object { $_.Matches[0].Groups[1].Value } | Where-Object { $_ -notlike '_*' })
# (the run without it: the same while the sim and the bosses run are - kept by their hash, not run again:
# 3-4 minutes each time, the Celestial Champion's moves alone at the end on one core)
$sha = [System.Security.Cryptography.SHA1]::Create()
$bytes = [IO.File]::ReadAllBytes((Join-Path $here 'sim_moves.lua')) + [Text.Encoding]::UTF8.GetBytes(($keys -join ','))
$hash = ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').Substring(0, 12)
$baseOut = Join-Path $base "moves_base.$hash.lua"
if (Test-Path $baseOut) {
    "without it ($($keys.Count) bosses): kept from before ($hash)"
} else {
    "without it ($($keys.Count) bosses):"
    # (SIM_JOB_LIMIT here too: a random move now runs on till it finds no more (sim_moves More) - the Antlion's
    # past 120s, every job stopped, nothing written, mod_diff then failing, 2026-10-26)
    Sim $baseOut 'tests\work\game_scripts' @("-only=$($keys -join ',')") @{ SIM_JOB_LIMIT = '1200' }
}

luajit tools\mod_diff.lua (Join-Path $work $outName) $baseOut (Join-Path $work "moves_sim_$($Name)_diff.lua") tools\sim_mods\um.lua `
    (Join-Path (Split-Path -Parent $root) 'true_range\scripts\true_range\moves_sim.lua') | Select-Object -First 1
Copy-Item (Join-Path $work "moves_sim_$($Name)_diff.lua") (Join-Path (Split-Path -Parent $root) "true_range\scripts\true_range\$outName")
"done in $([int]$sw.Elapsed.TotalSeconds)s"
