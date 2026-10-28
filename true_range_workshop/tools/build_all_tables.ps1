# True Range: REDESIGN.md tables for every move run offline - each move split in $Parts pieces (its
# angles) and its deciding frame, each piece its own luajit, as many at once as there are cores
# (a move to a process left the long ones running alone at the end); then put together, one process.
#   powershell -File build_all_tables.ps1 [-Only boss,boss] [-Budget 240]
# Writes tests/work/tables/<prefab>#<i>.lua and index.lua, then the mod's true_range/moves_table.lua
# (less tests/work/tables/drop.lua). Moves already built are kept (delete their file to build again).
param([string[]]$Only, [int]$Budget = 240, [int]$Parts = 6, [switch]$Again, [switch]$Wide)
# (-Wide: the runs' map wider - build_tables.lua -wide)
$wideArg = @(); if ($Wide) { $wideArg = @('-wide') }
$onlyList = @(); if ($Only) { $onlyList = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
$tools = $PSScriptRoot
$root = Split-Path -Parent $tools
$work = Join-Path $root 'tests\work'
$scripts = Join-Path $work 'game_scripts'
$out = Join-Path $work 'tables'
$mod = Join-Path (Split-Path -Parent $root) 'true_range'
New-Item -ItemType Directory -Force $out | Out-Null
Push-Location $tools
$moves = @(luajit build_tables.lua $scripts $out -list | ForEach-Object { ($_ -split ' ')[0] })
$todo = @($moves | Where-Object {
    $p = ($_ -split '#')[0]
    (-not $Only -or $onlyList -contains $p) -and ($Again -or -not (Test-Path (Join-Path $out "$_.lua")))
})
Write-Host ("{0} moves, {1} to build" -f $moves.Count, $todo.Count)
$slots = [int]$env:NUMBER_OF_PROCESSORS
$jobs = @(foreach ($m in $todo) { foreach ($pt in @('decide') + @(0..($Parts - 1) | ForEach-Object { "$_/$Parts" })) { [pscustomobject]@{ m = $m; part = $pt } } })
$running = @(); $i = 0; $t0 = Get-Date
while ($i -lt $jobs.Count -or $running.Count -gt 0) {
    while ($i -lt $jobs.Count -and $running.Count -lt $slots) {
        $j = $jobs[$i]; $i++; $m = $j.m
        $log = Join-Path $out ("_{0}_{1}.log" -f ($m -replace '#', '_'), ($j.part -replace '/', '_'))
        $p = Start-Process -FilePath 'luajit' -ArgumentList (@('build_tables.lua', "`"$scripts`"", "`"$out`"", "-one=$m", "-part=$($j.part)", "-budget=$Budget") + $wideArg) `
            -RedirectStandardOutput $log -RedirectStandardError "$log.err" -NoNewWindow -PassThru
        $running += [pscustomobject]@{ p = $p; m = "$m $($j.part)"; log = $log; j = $j }
    }
    Start-Sleep -Milliseconds 200
    $still = @()
    foreach ($r in $running) {
        if ($r.p.HasExited) {
            $line = (Get-Content $r.log -ErrorAction SilentlyContinue | Where-Object { $_ -like '==*' }) -join ' '
            if (-not $line) {
                $line = "== $($r.m): FAILED " + ((Get-Content "$($r.log).err" -ErrorAction SilentlyContinue | Select-Object -Last 2) -join ' ')
                # (a luajit at times stopped before it starts, nothing said - Windows: again, twice at most)
                $r.j | Add-Member -NotePropertyName tries -NotePropertyValue (1 + [int]$r.j.tries) -Force
                if ($r.j.tries -le 2) { $jobs += $r.j; $line += " - again" }
            }
            if ($line -notlike '*part*' -or $line -like '*FAILED*') { Write-Host ("[{0:N0}s] {1}" -f ((Get-Date) - $t0).TotalSeconds, $line) }
            [IO.File]::Delete($r.log); [IO.File]::Delete("$($r.log).err")
        } else { $still += $r }
    }
    $running = $still
}
Write-Host ("pieces done in {0:N0}s - putting them together" -f ((Get-Date) - $t0).TotalSeconds)
# (each move put together on its own, several at once - a move's finer places are run then)
$running = @(); $i = 0
while ($i -lt $todo.Count -or $running.Count -gt 0) {
    while ($i -lt $todo.Count -and $running.Count -lt $slots) {
        $m = $todo[$i]; $i++
        $log = Join-Path $out ("_merge_{0}.log" -f ($m -replace '#', '_'))
        $p = Start-Process -FilePath 'luajit' -ArgumentList (@('build_tables.lua', "`"$scripts`"", "`"$out`"", "-merge=$Parts", "-one=$m") + $wideArg) `
            -RedirectStandardOutput $log -RedirectStandardError "$log.err" -NoNewWindow -PassThru
        $running += [pscustomobject]@{ p = $p; m = $m; log = $log }
    }
    Start-Sleep -Milliseconds 200
    $still = @()
    foreach ($r in $running) {
        if ($r.p.HasExited) {
            $line = (Get-Content -LiteralPath $r.log -ErrorAction SilentlyContinue | Where-Object { $_ -like '==*' }) -join ' '
            if (-not $line) { $line = "== $($r.m): merge FAILED " + ((Get-Content -LiteralPath "$($r.log).err" -ErrorAction SilentlyContinue | Select-Object -Last 2) -join ' ') }
            Write-Host ("[{0:N0}s] {1}" -f ((Get-Date) - $t0).TotalSeconds, $line)
            [IO.File]::Delete($r.log); [IO.File]::Delete("$($r.log).err")
        } else { $still += $r }
    }
    $running = $still
}
# (every move's file there: the index the mod's file is made from)
$files = @($moves | Where-Object { Test-Path (Join-Path $out "$_.lua") } | ForEach-Object { "    `"$_.lua`"," })
Set-Content -Encoding ascii (Join-Path $out 'index.lua') (@('-- the moves built (tools/build_all_tables.ps1)', 'return {') + $files + @('}'))
luajit build_tables.lua $scripts $out "-client=$(Join-Path $mod 'scripts\true_range\moves_table.lua')"
Pop-Location
