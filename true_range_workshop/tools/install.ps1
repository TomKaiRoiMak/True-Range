# True Range: put the mod into the game's mods folder - and prove it got there.
#   powershell -File install.ps1
# 1. scripts/true_range/data_id.lua written: the moves data's hash (the mod logs it as it loads:
#    "[true_range] data <id>" in client_log.txt - which data a game ran on, told from its log)
# 2. robocopy /MIR into the game's folder
# 3. every file there compared by hash with the source; any not the same: said, and exit 1
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path (Split-Path -Parent $root) 'true_range'
$dst = 'D:\Games Manager\Games\steamapps\common\Don''t Starve Together\mods\true_range'
# (0. not one that fails as it loads: modmain reading a Lua builtin the mod's environment hasn't got (setmetatable, tonumber
#    ...) - tools\modenv_check.lua; and every Lua file compiling - a bare setmetatable went to the game once, 2026-10-21)
& luajit (Join-Path $PSScriptRoot 'modenv_check.lua') (Join-Path $src 'modmain.lua')
if ($LASTEXITCODE -ne 0) { Write-Host "not installed: modmain reads what the mod's environment hasn't got"; exit 1 }
# (0b. the newest patch notes and their client twin the same, word for word - the same scripts ship in both; kept by hand
#    till 2026-10-28, a check now, not a memory)
$pn = Get-ChildItem $root -Filter 'patch_notes_*.txt' | Where-Object { $_.Name -match '^patch_notes_(\d+\.\d+\.\d+)\.txt$' } |
    Sort-Object { [version]($_.Name -replace '^patch_notes_|\.txt$', '') } | Select-Object -Last 1
if ($pn -ne $null) {
    $twin = Join-Path $root ($pn.Name -replace '^patch_notes_', 'patch_notes_client_')
    if ((Test-Path $twin) -and (Get-FileHash $pn.FullName).Hash -ne (Get-FileHash $twin).Hash) {
        Write-Host "not installed: $($pn.Name) and $(Split-Path $twin -Leaf) differ"; exit 1
    }
}
# (0c. the moves data built against this game - a game update leaves it out of date silently (2026-10-27's changed 106 combat
#    scripts, SGshrouden among them): said loud, not stopped - tools\data_game_version.txt, set after a rebuild)
$gv = 'D:\Games Manager\Games\steamapps\common\Don''t Starve Together\version.txt'
$dv = Join-Path $PSScriptRoot 'data_game_version.txt'
if ((Test-Path $gv) -and (Test-Path $dv)) {
    $game = (Get-Content $gv -TotalCount 1).Trim()
    $built = (Get-Content $dv -TotalCount 1).Trim()
    if ($game -ne $built) { Write-Host "WARNING: moves data built for game $built, the game is $game - unpack game_scripts and rebuild (memory: game update = stale scripts)" }
}
# (0d. the moves written by hand still naming prefabs and animations the game has - tools\hand_check.ps1)
& powershell -NoProfile -File (Join-Path $PSScriptRoot 'hand_check.ps1') | Out-Host
if ($LASTEXITCODE -ne 0) { Write-Host "not installed: a hand-written move names what the game no longer has"; exit 1 }
foreach ($lf in Get-ChildItem $src -Recurse -Filter '*.lua') {
    & luajit -bl $lf.FullName > $null
    if ($LASTEXITCODE -ne 0) { Write-Host "not installed: $($lf.Name) does not compile"; exit 1 }
}
# (and the unit tests, every one (tests/last_summary.txt's "unit" list): none failing - tests/pool_hide.lua said for 3 days
#    that Lines.Tri drew nothing (a line lost), only test_sim was looked at, 2026-10-25. -SkipTests not given: required)
if ($args -notcontains '-SkipTests') {
    $tests = Join-Path $root 'tests'
    $units = @(Select-String -Path (Join-Path $tests 'last_summary.txt') -Pattern '^unit (\S+)' | ForEach-Object { $_.Matches[0].Groups[1].Value })
    Push-Location $tests
    foreach ($u in $units) {
        $f = Get-ChildItem $tests -Recurse -Filter "$u.lua" | Select-Object -First 1
        if ($f -eq $null) { continue }
        $out = @(& luajit $f.FullName $src 2>&1 | ForEach-Object { "$_" })
        $last = if ($out.Count -gt 0) { $out[-1] } else { "" }
        # (each says it its own way: "FAIL ..." lines, "n FAILED", "n wrong", "n of m points wrong" - none of them 0)
        if ($LASTEXITCODE -ne 0 -or ($out | Where-Object { $_ -match '^FAIL' }) -or $last -match '(^|\s)[1-9]\d* (FAILED|wrong)' -or $last -match '^[1-9]\d* of \d+ points wrong') {
            Pop-Location
            Write-Host "not installed: unit test $u failed - $last"
            exit 1
        }
    }
    Pop-Location
}
$data = Join-Path $src 'scripts\true_range\moves_sim.lua'
$id = (Get-FileHash $data -Algorithm SHA1).Hash.Substring(0, 12)
# (no BOM: the game's Lua reads the file as it is)
[IO.File]::WriteAllText((Join-Path $src 'scripts\true_range\data_id.lua'), "return `"$id`"`n", (New-Object System.Text.UTF8Encoding $false))
# (debug.txt - the traces on, for the replays - kept in the game's copy only: never in the source that's
# uploaded, not wiped by /MIR on every install either - the games after one went untraced)
& robocopy $src $dst /MIR /XF debug.txt /NJH /NJS /NFL /NDL | Out-Null
$dbg = Join-Path $dst 'debug.txt'
if (-not (Test-Path -LiteralPath $dbg)) { [IO.File]::WriteAllText($dbg, "traces on (installed copy only)`n", (New-Object System.Text.UTF8Encoding $false)) }
if ($LASTEXITCODE -ge 8) { Write-Host "robocopy failed ($LASTEXITCODE)"; exit 1 }
$bad = @()
$n = 0
Get-ChildItem $src -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($src.Length)
    $other = Join-Path $dst $rel
    $n++
    if (-not (Test-Path -LiteralPath $other)) { $bad += "missing $rel" }
    elseif ((Get-FileHash $_.FullName -Algorithm SHA1).Hash -ne (Get-FileHash -LiteralPath $other -Algorithm SHA1).Hash) { $bad += "differs $rel" }
}
$extra = @(Get-ChildItem $dst -Recurse -File | Where-Object { $_.FullName -ne $dbg -and -not (Test-Path -LiteralPath (Join-Path $src $_.FullName.Substring($dst.Length))) })
foreach ($e in $extra) { $bad += "extra $($e.FullName.Substring($dst.Length))" }
if ($bad.Count -gt 0) {
    Write-Host "INSTALL NOT THE SAME:"
    $bad | Select-Object -First 20 | ForEach-Object { Write-Host "   $_" }
    exit 1
}
Write-Host "installed: $n files, all the same as the source; data $id"
