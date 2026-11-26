# True Range: is each move better drawn from its table (docs/04-data-pipeline.md), or as before? Every replay
# (the game logs kept in tests/logs, and the offline runs' traces) of every boss with a table, run
# twice - with the tables, and without (TR_TABLES_OFF) - and what each says went wrong told to the
# move drawn then (replay.lua's SPAN lines, GATE=1). A move worse with its table goes into
# tests/work/tables/drop.lua (as before for it), and the mod's moves_table.lua is made again.
#   powershell -File table_gate.ps1 [-Only boss,boss]
param([string[]]$Only)
$onlyList = @(); if ($Only) { $onlyList = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ }) }
$tools = $PSScriptRoot
$root = Split-Path -Parent $tools
$tests = Join-Path $root 'tests'
$work = Join-Path $tests 'work'
$scripts = Join-Path $work 'game_scripts'
$tables = Join-Path $work 'tables'
$mod = Join-Path (Split-Path -Parent $root) 'true_range'
$client = Join-Path $mod 'scripts\true_range\moves_table.lua'
# (every move built, drop.lua or not: the gate judges them all again)
Remove-Item (Join-Path $tables 'drop.lua') -ErrorAction SilentlyContinue
Push-Location $tools
luajit build_tables.lua $scripts $tables "-client=$client" | Out-Null
$withTables = @(luajit -e "local t = dofile([[$client]]) for p in pairs(t) do print(p) end")
$allMoves = @(luajit -e "local t = dofile([[$client]]) for p, m in pairs(t) do for n in pairs(m) do print(p .. '|' .. n) end end")
$jobs = @()
foreach ($log in Get-ChildItem (Join-Path $tests 'logs') -Filter *.txt) {
    $prefabs = Select-String -Path $log.FullName -Pattern '\[tr_trace\] [\d\.]+ ([\w]+) after' | ForEach-Object { $_.Matches[0].Groups[1].Value } | Sort-Object -Unique
    foreach ($pf in $prefabs) { if ($withTables -contains $pf -and (-not $Only -or $onlyList -contains $pf)) { $jobs += [pscustomobject]@{ log = $log.FullName; prefab = $pf; ask = '-ask' } } }
}
foreach ($tr in Get-ChildItem (Join-Path $work 'traces') -Filter *.trace -ErrorAction SilentlyContinue) {
    $pf = $tr.BaseName -replace '#\d+$', ''
    if ($withTables -contains $pf -and (-not $Only -or $onlyList -contains $pf)) { $jobs += [pscustomobject]@{ log = $tr.FullName; prefab = $pf; ask = $null } }
}
Write-Host ("{0} replays, each twice" -f $jobs.Count)
$all = @(foreach ($j in $jobs) { foreach ($off in @($false, $true)) { [pscustomobject]@{ log = $j.log; prefab = $j.prefab; ask = $j.ask; off = $off } } })
$slots = [int]$env:NUMBER_OF_PROCESSORS
$env:GATE = '1'
$score = @{}   # "prefab|move" -> @{ on; off; on_what; off_what }
$weights = @{ MISSED = 5; FALSE = 2; OUTSIDE = 3; FLICKER = 1; VANISH = 1; SHRINK = 1; JUMP = 1; DROPPED = 1; WOBBLE = 1; SLIDE = 1; OUTRAN = 2; OVERDRAWN = 1; LATE = 1; FOLLOWS = 1; ERROR = 20 }
$running = @(); $i = 0; $n = 0
while ($i -lt $all.Count -or $running.Count -gt 0) {
    while ($i -lt $all.Count -and $running.Count -lt $slots) {
        $j = $all[$i]; $i++
        $outf = Join-Path $work ("gate_{0}.txt" -f $i)
        if ($j.off) { $env:TR_TABLES_OFF = '1' } else { Remove-Item Env:TR_TABLES_OFF -ErrorAction SilentlyContinue }
        $a = @("`"$(Join-Path $tests 'replay.lua')`"", "`"$mod`"", "`"$($j.log)`"", "`"$scripts`"", $j.prefab)
        if ($j.ask) { $a += $j.ask }
        $p = Start-Process -FilePath 'luajit' -ArgumentList $a -RedirectStandardOutput $outf -RedirectStandardError "$outf.err" -NoNewWindow -PassThru
        $running += [pscustomobject]@{ p = $p; j = $j; out = $outf }
    }
    Remove-Item Env:TR_TABLES_OFF -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 100
    $still = @()
    foreach ($r in $running) {
        if (-not $r.p.HasExited) { $still += $r; continue }
        $lines = @(Get-Content $r.out -ErrorAction SilentlyContinue) + @(Get-Content "$($r.out).err" -ErrorAction SilentlyContinue)
        Remove-Item $r.out, "$($r.out).err" -ErrorAction SilentlyContinue
        $spans = @(foreach ($l in $lines) { if ($l -match '^SPAN ([\d\.]+) ([\d\.]+) (\S+)') { [pscustomobject]@{ a = [double]$matches[1]; b = [double]$matches[2]; m = $matches[3] } } })
        $side = if ($r.j.off) { 'off' } else { 'on' }
        foreach ($l in $lines) {
            $kind = $null; $t = $null
            if ($l -match '^(MISSED|FALSE|OUTSIDE|FLICKER|VANISH|SHRINK|JUMP|DROPPED|WOBBLE|SLIDE|OUTRAN|OVERDRAWN|LATE|FOLLOWS)\s+([\d\.]+)') { $kind = $matches[1]; $t = [double]$matches[2] }
            elseif ($l -match '[Ee]rror:|traceback|attempt to|UNDECLARED') { $kind = 'ERROR' }
            if (-not $kind) { continue }
            # (the move drawn then - or within a second: a strike the tick after its move ended)
            $m = 'nil'
            if ($t -ne $null) {
                $best = 2.0
                foreach ($s in $spans) {
                    $d = if ($t -lt $s.a) { $s.a - $t } elseif ($t -gt $s.b) { $t - $s.b } else { 0 }
                    if ($d -lt $best -and $s.m -ne 'nil') { $best = $d; $m = $s.m }
                }
            }
            $key = "$($r.j.prefab)|$m"
            if (-not $score.ContainsKey($key)) { $score[$key] = @{ on = 0; off = 0; on_what = @{}; off_what = @{} } }
            $score[$key][$side] += $weights[$kind]
            $score[$key]["${side}_what"][$kind] = 1 + [int]$score[$key]["${side}_what"][$kind]
        }
        $n++
    }
    $running = $still
}
Remove-Item Env:GATE -ErrorAction SilentlyContinue
# (kept: only those better with their table, or the same with something to go by - one no
# replay ever saw is as before: nothing says its table is right)
$keep = @{}
$drop = @()
$report = @()
foreach ($k in ($score.Keys | Sort-Object)) {
    $s = $score[$k]
    $w = { param($h) ($h.Keys | Sort-Object | ForEach-Object { "$_ $($h[$_])" }) -join ', ' }
    $verdict = if ($s.on -gt $s.off) { 'WORSE' } elseif ($s.on -lt $s.off) { 'better' } else { 'same' }
    if ([int]$s.on_what['MISSED'] -gt [int]$s.off_what['MISSED']) { $verdict = 'WORSE' }
    $report += ("{0,-7} {1,-50} with {2,4} [{3}]  without {4,4} [{5}]" -f $verdict, $k, $s.on, (& $w $s.on_what), $s.off, (& $w $s.off_what))
    # (never more strikes missed than before, whatever else is better: a blow with no warning is the worst)
    $missOn, $missOff = [int]$s.on_what['MISSED'], [int]$s.off_what['MISSED']
    if ($missOn -gt $missOff) { $verdict = 'WORSE' }
    if ($verdict -eq 'better' -or ($verdict -eq 'same' -and $s.on -gt 0)) { $keep[$k] = $true }
}
# (and those the user saw right in the game: tests/work/tables/approved.lua)
$approved = @(luajit -e "local ok, t = pcall(dofile, [[$tables/approved.lua]]) for k in pairs(ok and t or {}) do print(k) end")
foreach ($k in $approved) { $keep[$k] = $true }
$drop = @($allMoves | Where-Object { -not $keep.ContainsKey($_) })
$report | Set-Content (Join-Path $work 'table_gate.txt')
$report | ForEach-Object { Write-Host $_ }
Set-Content -Encoding ascii (Join-Path $tables 'drop.lua') (@('-- moves worse with their table (tools/table_gate.ps1): drawn as before', 'return {') + @($drop | ForEach-Object { "    [`"$_`"] = true," }) + @('}'))
luajit build_tables.lua $scripts $tables "-client=$client"
Write-Host ("{0} kept: {1}" -f $keep.Count, (($keep.Keys | Sort-Object) -join ', '))
Pop-Location
