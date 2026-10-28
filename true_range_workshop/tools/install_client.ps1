# True Range (Client): the client-only build, made from the same source as True Range - for servers
# without the mod. Put into the game's mods folder as "true_range_client".
#   powershell -File install_client.ps1
# 1. robocopy /MIR the source (true_range) into the game's folder
# 2. client_only.txt there: modmain then asks nothing of the server (CLIENT_ONLY)
# 3. its modinfo.lua made from True Range's: its own name and description, a client mod - the
#    settings, version and the rest kept the same as the main mod's
# (-Src <a true_range folder>: that one - a git worktree's, as install.ps1 -Src)
param([string]$Src = "")
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$src = if ($Src -ne "") { (Resolve-Path $Src).Path } else { Join-Path (Split-Path -Parent $root) 'true_range' }
$dst = 'D:\Games Manager\Games\steamapps\common\Don''t Starve Together\mods\true_range_client'
$noBom = New-Object System.Text.UTF8Encoding $false

& robocopy $src $dst /MIR /NJH /NJS /NFL /NDL /XF debug.txt | Out-Null
if ($LASTEXITCODE -ge 8) { Write-Host "robocopy failed ($LASTEXITCODE)"; exit 1 }
# (its own icon - CLIENT on it, not SERVER: client_icon\, made by make_icon.ps1 -ModDir client_icon)
foreach ($f in 'modicon.tex', 'modicon.xml') { Copy-Item (Join-Path $root (Join-Path 'client_icon' $f)) (Join-Path $dst $f) -Force }
[IO.File]::WriteAllText((Join-Path $dst 'client_only.txt'), "client-only build: nothing asked of the server`n", $noBom)

$info = [IO.File]::ReadAllText((Join-Path $src 'modinfo.lua'))
$i = $info.IndexOf('description = [[')
$j = $info.IndexOf(']]', $i) + 2
$desc = @'
description = [[
Client version - for servers that don't have True Range.

See where an attack will land, before it lands: the real areas of
bosses' and monsters' moves, worked out from the game's own code.
Less exact than True Range on the server: drawn from what your game
sees, a moment late with ping.

Hosting yourself? Use True Range (the server mod) instead.
O: settings window, in the game.
]]
'@
$info = $info.Remove($i, $j - $i).Insert($i, $desc.Replace("`r`n", "`n").TrimEnd())
$info = $info.Replace('name = "True Range+"', 'name = "True Range+ (Client)"')
$info = $info.Replace('all_clients_require_mod = true', 'all_clients_require_mod = false')
$info = $info.Replace('client_only_mod = false', 'client_only_mod = true')
$info = [regex]::Replace($info, '(?m)^server_filter_tags = .*\r?\n', '')
$info = $info.Replace('-- the server knows the real ranges (players'' games don''t), so everyone needs it', '-- the client-only build: only you need it')
[IO.File]::WriteAllText((Join-Path $dst 'modinfo.lua'), $info, $noBom)

# (each file the same as the source but these two)
$bad = @()
$n = 0
Get-ChildItem $src -Recurse -File | Where-Object { $_.Name -ne 'modinfo.lua' -and $_.Name -ne 'debug.txt' -and $_.Name -notlike 'modicon.*' } | ForEach-Object {
    $other = Join-Path $dst $_.FullName.Substring($src.Length)
    $n++
    if (-not (Test-Path -LiteralPath $other)) { $bad += "missing $($_.Name)" }
    elseif ((Get-FileHash $_.FullName -Algorithm SHA1).Hash -ne (Get-FileHash -LiteralPath $other -Algorithm SHA1).Hash) { $bad += "differs $($_.Name)" }
}
if ($bad.Count -gt 0) { Write-Host "INSTALL NOT THE SAME:"; $bad | Select-Object -First 20 | ForEach-Object { Write-Host "   $_" }; exit 1 }
Write-Host "installed True Range (Client): $n files + its modinfo and client_only.txt -> $dst"
