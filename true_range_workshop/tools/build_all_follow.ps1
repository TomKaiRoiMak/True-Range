# True Range: build_tables.lua -follow for every move built (tests/work/tables/<prefab>#<i>.lua) - how
# far each goes with its target late on - as many at once as there are cores; then the mod's file again.
#   powershell -File build_all_follow.ps1 [-Only boss,boss] [-Again]
param([string[]]$Only, [switch]$Again)
$onlyList = @(); if ($Only) { $onlyList = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
$tools = $PSScriptRoot
$root = Split-Path -Parent $tools
$work = Join-Path $root 'tests\work'
$scripts = Join-Path $work 'game_scripts'
$out = Join-Path $work 'tables'
$mod = Join-Path (Split-Path -Parent $root) 'true_range'
Push-Location $tools
$moves = @(luajit build_tables.lua $scripts $out -list | ForEach-Object { ($_ -split ' ')[0] })
$todo = @($moves | Where-Object {
    $p = ($_ -split '#')[0]
    (-not $Only -or $onlyList -contains $p) -and (Test-Path -LiteralPath (Join-Path $out "$_.lua")) -and
        ($Again -or -not (Test-Path -LiteralPath (Join-Path $out "$_.follow.lua")))
})
Write-Host ("{0} moves to look at" -f $todo.Count)
$slots = [int]$env:NUMBER_OF_PROCESSORS
$running = @(); $i = 0; $t0 = Get-Date
while ($i -lt $todo.Count -or $running.Count -gt 0) {
    while ($i -lt $todo.Count -and $running.Count -lt $slots) {
        $m = $todo[$i]; $i++
        $log = Join-Path $out ("_follow_{0}.log" -f ($m -replace '#', '_'))
        $p = Start-Process -FilePath 'luajit' -ArgumentList @('build_tables.lua', "`"$scripts`"", "`"$out`"", "-one=$m", '-follow') `
            -RedirectStandardOutput $log -RedirectStandardError "$log.err" -NoNewWindow -PassThru
        $running += [pscustomobject]@{ p = $p; m = $m; log = $log }
    }
    Start-Sleep -Milliseconds 300
    $still = @()
    foreach ($r in $running) {
        if ($r.p.HasExited) {
            $line = (Get-Content -LiteralPath $r.log -ErrorAction SilentlyContinue | Where-Object { $_ -like '==*' }) -join ' '
            if (-not $line) { $line = "== $($r.m): follow FAILED " + ((Get-Content -LiteralPath "$($r.log).err" -ErrorAction SilentlyContinue | Select-Object -Last 2) -join ' ') }
            Write-Host ("[{0:N0}s] {1}" -f ((Get-Date) - $t0).TotalSeconds, $line)
            try { [IO.File]::Delete($r.log); [IO.File]::Delete("$($r.log).err") } catch {}
        } else { $still += $r }
    }
    $running = $still
}
luajit build_tables.lua $scripts $out "-client=$(Join-Path $mod 'scripts\true_range\moves_table.lua')"
Pop-Location
