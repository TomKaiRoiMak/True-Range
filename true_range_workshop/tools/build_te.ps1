# powershell -File tools\build_te.ps1
# Tropical Experience's moves, all of it, again - after the mod updates (as tools\build_um.ps1 for UM):
#   1. its scripts over the game's (mod_scripts.ps1), its animations' lengths (anim_lengths.ps1)
#   2. every boss it changes or adds, run in its world (SIM_MOD, SIM_MOD_CHANGED, sim_mods\te.lua)
#   3. the same bosses without it, by this same sim
#   4. only what differs, move by move (mod_diff.lua) -> true_range/scripts/true_range/moves_sim_te.lua
# Each run side by side on every core (-jobs).
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
Set-Location $root
$ws = 'D:\Games Manager\Games\steamapps\workshop\content\322330\1505270912'
$work = Join-Path $root 'tests\work\te'
$base = Join-Path $root 'tests\work\te_base'
New-Item -ItemType Directory -Force $work, $base | Out-Null
$sw = [Diagnostics.Stopwatch]::StartNew()
$start = Get-Date

powershell -File (Join-Path $here 'mod_scripts.ps1') -Mod 1505270912 -Name te
$zips = (Get-ChildItem (Join-Path $ws 'anim') -Filter *.zip).FullName
& (Join-Path $here 'anim_lengths.ps1') -Out (Join-Path $here 'anim_lengths_te.lua') @zips | Select-Object -Last 1

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
Sim (Join-Path $work 'moves_sim_te.lua') 'tests\work\game_scripts_te' @() @{
    SIM_MOD = $ws; SIM_MOD_SPEC = 'tools\sim_mods\te.lua'; SIM_MOD_ANIMS = 'tools\anim_lengths_te.lua'; SIM_MOD_CHANGED = '1'; SIM_JOB_LIMIT = '1200' }
if (-not (Test-Path (Join-Path $work 'moves_sim_te.lua')) -or (Get-Item (Join-Path $work 'moves_sim_te.lua')).LastWriteTime -lt $start) {
    "the run with the mod wrote nothing - see $(Join-Path $work 'moves_sim_te.lua.err')"
    exit 1
}
$keys = @(Select-String (Join-Path $work 'moves_sim_te.lua') -Pattern '^    \["([\w]+)"\] = \{' | ForEach-Object { $_.Matches[0].Groups[1].Value } | Where-Object { $_ -notlike '_*' })
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
    # (SIM_JOB_LIMIT here too - tools/build_um.ps1, 2026-10-26)
    Sim $baseOut 'tests\work\game_scripts' @("-only=$($keys -join ',')") @{ SIM_JOB_LIMIT = '1200' }
}

luajit tools\mod_diff.lua (Join-Path $work 'moves_sim_te.lua') $baseOut (Join-Path $work 'moves_sim_te_diff.lua') tools\sim_mods\te.lua `
    (Join-Path (Split-Path -Parent $root) 'true_range\scripts\true_range\moves_sim.lua') | Select-Object -First 1
# 5. the monsters with a second stategraph of their own (sim_mods\te_second.lua): run again on it, its moves added
$second = @(luajit -e "for _, s in ipairs(dofile([[tools\sim_mods\te_second.lua]])) do print(s.prefab) end")
if ($second.Count -gt 0) {
    "second stategraphs ($($second -join ',')):"
    Sim (Join-Path $work 'moves_sim_te_second.lua') 'tests\work\game_scripts_te' @("-only=$($second -join ',')") @{
        SIM_MOD = $ws; SIM_MOD_SPEC = 'tools\sim_mods\te_second.lua'; SIM_MOD_ANIMS = 'tools\anim_lengths_te.lua' }
    luajit tools\merge_moves.lua (Join-Path $work 'moves_sim_te_diff.lua') (Join-Path $work 'moves_sim_te_second.lua') ($second -join ',') | Select-Object -Last 1
}
Copy-Item (Join-Path $work 'moves_sim_te_diff.lua') (Join-Path (Split-Path -Parent $root) 'true_range\scripts\true_range\moves_sim_te.lua')
"done in $([int]$sw.Elapsed.TotalSeconds)s"

