# powershell -File tools\make_catalog.ps1
# docs/catalog: every monster and move in True Range's data, pages to find and fix them by - made again from the data files
# (tools\make_catalog.lua); the in-game names from the game's strings, Uncompromising Mode's and Tropical Experience's.
# Run after any change to the data (a rebuild, a hand-written move). 2026-10-28.
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path (Split-Path -Parent $root) 'true_range'
$out = Join-Path $root 'docs\catalog'
$names = Join-Path $env:TEMP 'tr_catalog_names.tsv'
$um = 'D:\Games Manager\Games\steamapps\workshop\content\322330\3193922031'
$te = 'D:\Games Manager\Games\steamapps\workshop\content\322330\1505270912'
$lines = New-Object System.Collections.Generic.List[string]
# (the game's own: STRINGS.NAMES, its first block)
$gs = Join-Path $root 'tests\work\game_scripts\strings.lua'
if (Test-Path $gs) {
    $L = [IO.File]::ReadAllLines($gs)
    $start = -1
    for ($i = 0; $i -lt $L.Count; $i++) { if ($L[$i] -match '^\s{4}NAMES\s*=') { $start = $i; break } }
    if ($start -ge 0) {
        for ($i = $start + 1; $i -lt $L.Count; $i++) {
            if ($L[$i] -match '^\s{4}\},?\s*$') { break }
            if ($L[$i] -match '^\s+([A-Z0-9_]+)\s*=\s*"([^"]+)"') { $lines.Add("$($matches[1])`t$($matches[2])") }
        }
    }
}
# (the mods': NAMES.X = "..." - TE's English only, not its Languages folder)
foreach ($d in @((Join-Path $um 'init'), (Join-Path $um 'scripts'), (Join-Path $te 'scripts'))) {
    if (-not (Test-Path $d)) { continue }
    foreach ($f in Get-ChildItem $d -Recurse -Filter '*.lua' | Where-Object { $_.FullName -notmatch '\\Languages\\' }) {
        foreach ($m in [regex]::Matches([IO.File]::ReadAllText($f.FullName), 'NAMES\.([A-Z0-9_]+)\s*=\s*"([^"]+)"')) { $lines.Add("$($m.Groups[1].Value)`t$($m.Groups[2].Value)") }
    }
}
[IO.File]::WriteAllLines($names, $lines, (New-Object System.Text.UTF8Encoding $false))
if (Test-Path $out) { Get-ChildItem $out -Filter '*.md' | Remove-Item -Force -Confirm:$false }
New-Item -ItemType Directory -Force $out | Out-Null
& luajit (Join-Path $PSScriptRoot 'make_catalog.lua') $src $out $names
