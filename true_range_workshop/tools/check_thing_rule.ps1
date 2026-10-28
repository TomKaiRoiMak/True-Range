# True Range: prove the lasting-thing shortcut (sim_moves.lua THING_RUNS - a thing that strikes on and
# on round itself, its shape measured in a few runs, then run with no dummies) gives the very same data
# as measuring every run - for this scripts.zip. Two whole offline runs, one each way, compared byte
# for byte; the same: scripts.zip's hash written to tests/thing_rule_ok.txt (verify.ps1 uses the
# shortcut only then). Not the same: which bosses differ, and nothing written.
#   powershell -File check_thing_rule.ps1        (about 8 minutes)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$tools = Join-Path $root 'tools'
$tests = Join-Path $root 'tests'
$work = Join-Path $tests 'work'
$scripts = Join-Path $work 'game_scripts'
$zip = 'D:\Games Manager\Games\steamapps\common\Don''t Starve Together\data\databundles\scripts.zip'
$zipHash = (Get-FileHash $zip -Algorithm SHA1).Hash
$had = Get-Content (Join-Path $work 'game_scripts.hash') -Raw -ErrorAction SilentlyContinue
if ($null -eq $had -or $had.Trim() -ne $zipHash) {
    Write-Host "tests/work/game_scripts is not unpacked from this scripts.zip - run verify.ps1 first"
    exit 2
}
Push-Location $tools
$out = @{}
foreach ($mode in 'every', 'shortcut') {
    if ($mode -eq 'every') { $env:SIM_ALL_THINGS = '1' } else { $env:SIM_ALL_THINGS = $null }
    $f = Join-Path $work "thing_rule_$mode.lua"
    $t0 = Get-Date
    & luajit sim_moves.lua $f $scripts -jobs 2> (Join-Path $work "thing_rule_$mode.err") > $null
    $code = $LASTEXITCODE
    Write-Host ("{0}: exit {1}, {2:N0}s" -f $mode, $code, ((Get-Date) - $t0).TotalSeconds)
    if ($code -ne 0) { Pop-Location; Write-Host "a run failed - see tests/work/thing_rule_$mode.err"; exit 1 }
    $out[$mode] = $f
}
$env:SIM_ALL_THINGS = $null
Pop-Location
$a = [IO.File]::ReadAllText($out['every'])
$b = [IO.File]::ReadAllText($out['shortcut'])
if ($a -eq $b) {
    Set-Content -LiteralPath (Join-Path $tests 'thing_rule_ok.txt') -Value $zipHash
    Write-Host "the same, byte for byte - shortcut proven for scripts.zip $zipHash"
} else {
    Write-Host "NOT the same - the shortcut stays off; where they differ:"
    & luajit (Join-Path $tests 'tablediff.lua') $out['every'] $out['shortcut'] | Select-Object -First 30
    exit 1
}
