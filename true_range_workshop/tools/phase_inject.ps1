# powershell -File tools\phase_inject.ps1
# Each boss's health thresholds (tools/phase_scan.lua -> tools/phase_levels.lua) put into the testbench
# (tr_testbench/modmain.lua, between "-- PHASE_LEVELS BEGIN" and "-- PHASE_LEVELS END"): its Tick takes each boss
# down just under each of them in turn (VERIFY_PLAN 6.17). Run phase_scan first after a game or mod update.
$root = Split-Path -Parent $PSScriptRoot
$tb = Join-Path (Split-Path -Parent $root) 'tr_testbench\modmain.lua'
$lv = [IO.File]::ReadAllText((Join-Path $root 'tools\phase_levels.lua'))
$body = $lv -replace '(?s)^.*?return \{', '' -replace '\}\s*$', ''
$block = "-- PHASE_LEVELS BEGIN (written from tools/phase_levels.lua by tools/phase_inject.ps1 - each boss's health thresholds)`nlocal PHASE_LEVELS = {$body}`n-- PHASE_LEVELS END`n"
$t = [IO.File]::ReadAllText($tb)
if ($t -notmatch '(?s)-- PHASE_LEVELS BEGIN.*?-- PHASE_LEVELS END\r?\n') { Write-Host "no PHASE_LEVELS block in $tb"; exit 1 }
$t = [regex]::Replace($t, '(?s)-- PHASE_LEVELS BEGIN.*?-- PHASE_LEVELS END\r?\n', $block)
[IO.File]::WriteAllText($tb, $t, (New-Object Text.UTF8Encoding $false))
& luajit -bl $tb > $null
if ($LASTEXITCODE -ne 0) { Write-Host "testbench no longer compiles"; exit 1 }
"injected: " + (@($body -split "`n" | Where-Object { $_ -match '=' }).Count) + " bosses"
