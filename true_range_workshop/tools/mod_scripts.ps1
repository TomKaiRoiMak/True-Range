# powershell -File tools\mod_scripts.ps1 -Mod <workshop id or folder> [-Name um]
# The game's scripts with a mod's own laid over them, as the game finds them (a mod's scripts folder
# first): tests/work/game_scripts_<name> - for tools/sim_moves.lua run with SIM_MOD set (its
# modmain run in a mod's environment: tools/mod_env.lua).
param([Parameter(Mandatory = $true)][string]$Mod, [string]$Name = "")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$ws = 'D:\Games Manager\Games\steamapps\workshop\content\322330'
$dir = if (Test-Path $Mod) { (Resolve-Path $Mod).Path } else { Join-Path $ws $Mod }
if (-not (Test-Path (Join-Path $dir 'modmain.lua'))) { Write-Host "no modmain.lua in $dir"; exit 1 }
if ($Name -eq "") { $Name = Split-Path -Leaf $dir }
$game = Join-Path $root 'tests\work\game_scripts'
$out = Join-Path $root ("tests\work\game_scripts_" + $Name)
& robocopy $game $out /MIR /NJH /NJS /NFL /NDL | Out-Null
if ($LASTEXITCODE -ge 8) { Write-Host "robocopy (game) failed ($LASTEXITCODE)"; exit 1 }
$ms = Join-Path $dir 'scripts'
if (Test-Path $ms) {
    & robocopy $ms $out /E /NJH /NJS /NFL /NDL | Out-Null
    if ($LASTEXITCODE -ge 8) { Write-Host "robocopy (mod) failed ($LASTEXITCODE)"; exit 1 }
}
# (a file of the mod's own by a game file's name, written for the mod's environment (GLOBAL) - Tropical Experience's
# scripts/tuning.lua, added to the game's by its modmain, not in place of it: laid over, the game's own was gone and
# nothing loaded, 2026-10-20. Such the game's own, kept; the mod's run from its folder (SIM_MOD) as the game does)
$kept = 0
if (Test-Path $ms) {
    foreach ($f in Get-ChildItem $ms -Recurse -File) {
        $rel = $f.FullName.Substring($ms.Length + 1)
        $g = Join-Path $game $rel
        if ((Test-Path $g) -and ([IO.File]::ReadAllText($f.FullName) -match '\bGLOBAL\b')) {
            Copy-Item $g (Join-Path $out $rel) -Force
            $kept++
        }
    }
}
if ($kept -gt 0) { "the game's own kept for $kept of the mod's files by its names written for the mod's environment" }
$n = (Get-ChildItem $ms -Recurse -File -ErrorAction SilentlyContinue).Count
"scripts: $out ($n of the mod's laid over the game's); mod: $dir"
