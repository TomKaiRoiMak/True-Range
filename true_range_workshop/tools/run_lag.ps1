# powershell -File tools\run_lag.ps1 [-Bosses a,b,...] [-Rounds 2] [-TickRate 15] [-Minutes 60] [-NoClient]
# The testbench with your game and the server apart, as with caves on (VERIFY_PLAN 6.20): the game's server with no
# screen (a world of its own, tests\work\bench_server - never the user's) runs the testbench in lag mode
# ("tr_bench+lag:..."), your own game (Steam) joins it by itself (tr_lagjoin, join.txt) as Wilson, and walks each
# scene through the game's own movement - Lag Compensation on every other scene. True Range on both sides with its
# testing lines (debug.txt). Then tools/lag_report.lua on your game's log: struck / drawn, on and off.
# Your game is started and closed by this - not run while you play. -NoClient: the server only (join by hand).
param([string]$Bosses = "deerclops,moose,bearger,mock_dragonfly,moonmaw_dragonfly", [int]$Rounds = 2, [int]$TickRate = 15,
    [int]$Minutes = 60, [int]$Port = 11010, [switch]$NoClient, [int]$Speed = 1, [string]$Old = "", [string]$Event = "", [switch]$TE, [switch]$NoUM, [switch]$NoDebug)
# (-Old "TR_OLD_A,TR_OLD_B": True Range's switches back to how it was, set in your game (tr_lagjoin) - to tell which change did it)
# (-Speed n: the server and your game both n times as fast (TheSim:SetTimeScale - the testbench's own speed, tr_lagjoin from
# join.txt), the tick rate n times too unless given - the network's tick as often in the game's time as at 1x, its lag the same
# there; the user: "speed the tick up", 2026-10-27)
if ($Speed -gt 1 -and -not $PSBoundParameters.ContainsKey('TickRate')) { $TickRate = 15 * $Speed }
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$dev = Split-Path -Parent $root
$game = 'D:\Games Manager\Games\steamapps\common\Don''t Starve Together'
$ugc = 'D:\Games Manager\Games\steamapps\workshop'
$klei = Join-Path $env:USERPROFILE 'Documents\Klei\DoNotStarveTogether'
$userCluster = Join-Path $klei '900782082\Cluster_4'
$store = Join-Path $root 'tests\work\bench_server'
$conf = Join-Path $store 'bench_conf'
$noBom = New-Object System.Text.UTF8Encoding $false

# (not with a bench running - the server build of the testbench is one folder for both; nor with your game open)
$others = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -match 'run_(bench|lag)\.ps1' })
if ($others.Count -gt 0) { "another run_bench / run_lag is running (pid $($others.ProcessId -join ',')) - wait for it or stop it"; exit 1 }
if (-not $NoClient -and (Get-Process dontstarve_steam_x64 -ErrorAction SilentlyContinue)) { "your game is open - close it first (this starts and closes it)"; exit 1 }
# (-NoDebug: as players get it, no debug.txt - only crashes and what's drawn looked at, no struck/drawn table)
if (-not $NoDebug -and -not (Test-Path (Join-Path $game 'mods\true_range\debug.txt'))) { "True Range's debug.txt is missing in the game's copy - run tools\install.ps1"; exit 1 }

# 1. the testbench's server build, as run_bench makes it
$srv = Join-Path $game 'mods\tr_testbench_server'
New-Item -ItemType Directory -Force $srv | Out-Null
Copy-Item (Join-Path $dev 'tr_testbench\modmain.lua') $srv -Force
$forceDst = Join-Path $srv 'tr_force.txt'; if (Test-Path $forceDst) { Remove-Item $forceDst -Force }
$info = (Get-Content (Join-Path $dev 'tr_testbench\modinfo.lua') -Raw) -replace 'name = "TR Testbench \(local\)"', 'name = "TR Testbench (server, local)"' `
    -replace 'client_only_mod = true', 'client_only_mod = false' -replace 'all_clients_require_mod = false', "all_clients_require_mod = false`nserver_only_mod = true"
[IO.File]::WriteAllText((Join-Path $srv 'modinfo.lua'), $info, $noBom)

# 2. your game's half: tr_lagjoin, joined only while join.txt is there; on for this run alone (modsettings.lua's
#    ForceEnableMod - the line taken out again at the end, whatever happens)
$join = Join-Path $game 'mods\tr_lagjoin'
New-Item -ItemType Directory -Force $join | Out-Null
Copy-Item (Join-Path $dev 'tr_lagjoin\modmain.lua'), (Join-Path $dev 'tr_lagjoin\modinfo.lua') $join -Force
$settings = Join-Path $game 'mods\modsettings.lua'
$forceLine = 'ForceEnableMod("tr_lagjoin") -- tools/run_lag.ps1, taken out at its end'
$joinFile = Join-Path $join 'join.txt'
# (played.txt: put once your game is in - stopped part way, its server gone, your game back at the main menu shuts itself (tr_lagjoin))
$playedFile = Join-Path $join 'played.txt'
function Cleanup {
    if (Test-Path $joinFile) { Remove-Item $joinFile -Force }
    if (Test-Path $playedFile) { Remove-Item $playedFile -Force }
    if (Test-Path $settings) {
        $lines = @([IO.File]::ReadAllLines($settings) | Where-Object { $_ -ne $forceLine })
        [IO.File]::WriteAllLines($settings, $lines, $noBom)
    }
}
# (and first, before the server starts: a run stopped part way never got to its end - its line left in, the server too
# loaded tr_lagjoin, its RPCs four more than your game's: "Invalid RPC code: tr_lag 8", no scene ever told, 2026-10-31_0327)
Cleanup

# 3. its world: one shard, LAN only, your token (a server others can join needs one), the tick rate asked for
$name = 'Lag'
$master = Join-Path $conf "$name\Master"
New-Item -ItemType Directory -Force $master | Out-Null
$tag = "tr_bench+lag:$Bosses"
# (a long list in a file beside the server's testbench, the name short - 24 bosses in it and your game never got in)
$listFile = Join-Path $srv 'tr_list.txt'; if (Test-Path $listFile) { Remove-Item $listFile -Force }
# (the dedicated server read nothing from the file - passed as the testbench's "list" setting instead, bench_overrides.lua BENCH_LIST)
Remove-Item Env:BENCH_LIST -ErrorAction SilentlyContinue
if ($tag.Length -gt 60) { $env:BENCH_LIST = $Bosses; $tag = "tr_bench+lag:@list" }
[IO.File]::WriteAllText((Join-Path $conf "$name\cluster.ini"), "[GAMEPLAY]`ngame_mode = survival`nmax_players = 2`npvp = false`npause_when_empty = false`n`n[NETWORK]`ncluster_name = $tag`noffline_cluster = false`nlan_only_cluster = true`ncluster_password =`ntick_rate = $TickRate`n`n[MISC]`nconsole_enabled = true`n`n[SHARD]`nshard_enabled = false`n", $noBom)
[IO.File]::WriteAllText((Join-Path $master 'server.ini'), "[NETWORK]`nserver_port = $Port`n`n[SHARD]`nis_master = true`n`n[STEAM]`nauthentication_port = 8810`nmaster_server_port = 27110`n", $noBom)
$token = Join-Path $klei '900782082\Cluster_17\cluster_token.txt'
if (Test-Path $token) { Copy-Item $token (Join-Path $conf "$name\cluster_token.txt") -Force }
$lvl = Join-Path $userCluster 'Master\leveldataoverride.lua'
if (Test-Path $lvl) { Copy-Item $lvl (Join-Path $master 'leveldataoverride.lua') -Force }
# (-Event hallowed_nights: that event on in the bench's world - its copy only, your world's file as it is: the Hallowed Nights
# monsters (franken pig, mummy merm, vampire bunny: 30% of pigs, merms, bunnymen while it's on), 2026-10-30)
if ($Event) { $lo = Join-Path $master 'leveldataoverride.lua'; (Get-Content $lo -Raw) -replace "$Event=`"default`"", "$Event=`"enabled`"" | ForEach-Object { [IO.File]::WriteAllText($lo, $_, (New-Object Text.UTF8Encoding($false))) } }
luajit (Join-Path $here 'bench_overrides.lua') (Join-Path $userCluster 'Master\modoverrides.lua') (Join-Path $master 'modoverrides.lua') $Rounds $Speed tr $(if ($TE) { 'te' } else { '' }) $(if ($TE -or $NoUM) { 'noum' } else { '' }) | Out-Null
$seed = Join-Path $conf 'Bench\Master\save'
if (Test-Path $seed) {
    if (Test-Path (Join-Path $master 'save')) { Remove-Item -Recurse -Force (Join-Path $master 'save') }
    Copy-Item $seed (Join-Path $master 'save') -Recurse
}
$log = Join-Path $master 'server_log.txt'
if (Test-Path $log) { Remove-Item $log -Force }

$keepDir = Join-Path $root 'tests\work\bench_logs'
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmm'
$runDir = Join-Path $keepDir "${stamp}_lag"; New-Item -ItemType Directory -Force $runDir | Out-Null
$clientLog = Join-Path $klei 'client_log.txt'
# (your game writes its log anew each start: the last one kept first)
if (Test-Path $clientLog) { Copy-Item $clientLog (Join-Path $runDir 'client_log_before.txt') -Force }

$exe = Join-Path $game 'bin64\dontstarve_dedicated_server_nullrenderer_x64.exe'
$sargs = @('-persistent_storage_root', "`"$store`"", '-conf_dir', 'bench_conf', '-cluster', $name, '-shard', 'Master', '-ugc_directory', "`"$ugc`"")
$p = Start-Process $exe -ArgumentList $sargs -WorkingDirectory (Join-Path $game 'bin64') -PassThru -WindowStyle Hidden
"server started (tick rate $TickRate, port $Port): $Bosses"
$sw = [Diagnostics.Stopwatch]::StartNew()
$ready = $false
while ($sw.Elapsed.TotalSeconds -lt 240 -and -not $p.HasExited) {
    if ((Test-Path $log) -and (Select-String -Path $log -Pattern 'lag: waiting for a player' -Quiet)) { $ready = $true; break }
    Start-Sleep 2
}
if (-not $ready) {
    "server not ready in 240 s$(if ($p.HasExited) { " (exited $($p.ExitCode))" })"
    if (Test-Path $log) { Select-String -Path $log -Pattern 'LUA ERROR|error' | Select-Object -First 10 | ForEach-Object { $_.Line } }
    if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
    Cleanup; exit 1
}
"server ready after $([math]::Round($sw.Elapsed.TotalSeconds)) s"

$client = $null
try {
    if (-not $NoClient) {
        [IO.File]::WriteAllText($joinFile, "127.0.0.1 $Port $Speed $($Old -replace ',',' ')`n", $noBom)
        if (-not (Select-String -Path $settings -SimpleMatch $forceLine -Quiet -ErrorAction SilentlyContinue)) { [IO.File]::AppendAllText($settings, "`n$forceLine`n", $noBom) }
        Start-Process 'steam://rungameid/322330'
        "your game started - it joins by itself"
        # (in: tr_lagjoin's "in game" in its log within 5 minutes, else stopped)
        $in = $false
        $t0 = Get-Date
        while (((Get-Date) - $t0).TotalSeconds -lt 300 -and -not $p.HasExited) {
            if ((Test-Path $clientLog) -and ((Get-Item $clientLog).LastWriteTime -gt $t0) -and (Select-String -Path $clientLog -Pattern '\[tr_lag\] [\d.]+ in game' -Quiet)) { $in = $true; break }
            Start-Sleep 3
        }
        $client = Get-Process dontstarve_steam_x64 -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $in) { "your game didn't get in within 5 minutes - stopped"; if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }; throw "no join" }
        "in game after $([math]::Round(((Get-Date) - $t0).TotalSeconds)) s"
        # (in once: the main menu after - the server gone - mustn't join again)
        Remove-Item $joinFile -Force
        [IO.File]::WriteAllText($playedFile, "1`n", $noBom)
    } else {
        "-NoClient: join by hand (LAN, port $Port)"
    }
    # 4. till the server ends (all done, or the player gone) or -Minutes; the log's first minute looked at for errors
    $errSeen = $false
    while (-not $p.HasExited -and $sw.Elapsed.TotalMinutes -lt $Minutes) {
        Start-Sleep 5
        if (-not $errSeen -and (Test-Path $log)) {
            $e = Select-String -Path $log -Pattern 'mods/(tr_testbench_server|true_range)/[^:]*:\d+:' | Select-Object -First 1
            if ($e) { $errSeen = $true; "BENCH CODE ERROR: $($e.Line.Trim())"; Stop-Process -Id $p.Id -Force; break }
        }
    }
    if (-not $p.HasExited) { "past $Minutes min - stopped"; Stop-Process -Id $p.Id -Force }
} finally {
    Cleanup
    if ($client -ne $null -and -not $client.HasExited) { Start-Sleep 5; Stop-Process -Id $client.Id -Force; Start-Sleep 3 }
    if (Test-Path $log) { Copy-Item $log (Join-Path $runDir 'server_log.txt') -Force }
    if (-not $NoClient -and (Test-Path $clientLog)) { Copy-Item $clientLog (Join-Path $runDir 'client_log.txt') -Force }
}
"ran $([math]::Round($sw.Elapsed.TotalMinutes, 1)) min - logs in $runDir"
if (Test-Path (Join-Path $runDir 'client_log.txt')) {
    luajit (Join-Path $here 'lag_report.lua') (Join-Path $runDir 'client_log.txt') (Join-Path $runDir 'server_log.txt')
    luajit (Join-Path $here 'lag_snap.lua') (Join-Path $runDir 'client_log.txt')
}
