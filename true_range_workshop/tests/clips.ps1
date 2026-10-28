# powershell -File tests\clips.ps1 [-Out <dir>] [-Only a,b] [-Step 2]
# A short clip of each monster's each move as True Range draws it, from the bench runs (the game's own server): the vanilla
# and Uncompromising Mode run (0407) and the Tropical Experience one (0059). tests/clips_pick.lua picks a go of each move,
# tests/replay.lua (PIC_TIMES) draws its frames - one run a clip, side by side on every core but two - and
# tests/clips_gif.py makes them GIFs and index.html. "Not into the game to look - it hurts my eyes", the player 2026-10-21.
param([string]$Out = "", [string]$Only = "", [int]$Step = 2, [double]$R = 12, [int]$Scale = 20)
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root
if ($Out -eq "") { $Out = Join-Path $root 'tests\work\clips' }
$frames = Join-Path $Out 'frames'
New-Item -ItemType Directory -Force $frames | Out-Null
$mod = Join-Path (Split-Path -Parent $root) 'true_range'
$runs = @(
    @{ name = '2026-10-21_0407_shares'; scripts = 'tests\work\game_scripts_um'; mods = 'workshop-3193922031' },
    @{ name = '2026-10-21_0059_shares'; scripts = 'tests\work\game_scripts_umte'; mods = 'workshop-3193922031 workshop-1505270912' })
$onlyList = @($Only -split ',' | Where-Object { $_ })
$todo = @()
$tsvs = @()
foreach ($run in $runs) {
    $list = Join-Path $Out "logs_$($run.name).txt"
    Get-ChildItem (Join-Path $root "tests\work\bench_logs\$($run.name)") -Filter 'share*.txt' | ForEach-Object FullName | Set-Content $list -Encoding ascii
    $tsv = Join-Path $Out "picks_$($run.name).tsv"
    luajit tests\clips_pick.lua $list | Set-Content $tsv -Encoding utf8
    $tsvs += $tsv
    foreach ($line in Get-Content $tsv) {
        $p = $line -split "`t"
        if ($onlyList.Count -gt 0 -and $onlyList -notcontains $p[1]) { continue }
        $t0, $t1 = [double]$p[3], [double]$p[4]
        $times = @()
        for ($t = $t0; $t -le $t1 + 1e-6; $t += $Step / 30.0) { $times += ('{0:0.000}' -f $t) }
        $todo += @{ log = $p[0]; prefab = $p[1]; move = $p[2]; times = ($times -join ','); c = "$($p[5]),$($p[6])"; run = $run }
    }
}
"clips to draw: $($todo.Count)"
# (the previous clip's frames gone - a move no longer picked, its old frames not left in)
Get-ChildItem $frames -Filter *.ppm -ErrorAction SilentlyContinue | Remove-Item
$max = [Math]::Max(1, [int]$env:NUMBER_OF_PROCESSORS - 2)
$running = @()
$sw = [Diagnostics.Stopwatch]::StartNew()
$done = 0
foreach ($c in $todo) {
    while (@($running | Where-Object { -not $_.HasExited }).Count -ge $max) { Start-Sleep -Milliseconds 200 }
    $running = @($running | Where-Object { -not $_.HasExited })
    $name = "$($c.prefab)__$($c.move)"
    $env:PIC_TIMES = $c.times; $env:PIC_REAL = '1'; $env:PIC_OUT = (Join-Path $frames "${name}_%03d.ppm")
    $env:PIC_R = "$R"; $env:PIC_SCALE = "$Scale"; $env:PIC_C = $c.c; $env:TR_MODS = $c.run.mods; $env:COUNT_FROM = ''; $env:WHOLE = '1'
    $running += Start-Process luajit -ArgumentList 'tests\replay.lua', "`"$mod`"", "`"$($c.log)`"", $c.run.scripts, $c.prefab -NoNewWindow -PassThru `
        -WorkingDirectory $root -RedirectStandardOutput (Join-Path $frames "$name.out") -RedirectStandardError (Join-Path $frames "$name.err")
    $done++
    if ($done % 50 -eq 0) { "  $done of $($todo.Count) started, $([int]$sw.Elapsed.TotalSeconds)s" }
}
foreach ($k in 'PIC_TIMES', 'PIC_REAL', 'PIC_OUT', 'PIC_R', 'PIC_SCALE', 'PIC_C', 'TR_MODS', 'COUNT_FROM', 'WHOLE') { Remove-Item "env:$k" -ErrorAction SilentlyContinue }
$running | ForEach-Object { $_.WaitForExit() }
"drawn in $([int]$sw.Elapsed.TotalSeconds)s"
$env:CLIP_STEP_S = '{0:0.0000}' -f ($Step / 30.0)
python tests\clips_gif.py $Out @tsvs
# (the frames gone once they're GIFs - some 15 GB of them, on the game's drive)
Get-ChildItem $frames -Filter *.ppm -ErrorAction SilentlyContinue | Remove-Item
