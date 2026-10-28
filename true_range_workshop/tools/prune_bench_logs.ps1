# powershell -File tools\prune_bench_logs.ps1 [-Keep 2] [-Baseline 2026-10-28_0805_shares] [-Apply]
# The bench's logs, kept to what's still used: the baseline full run, the newest -Keep full runs (_shares with 100+ files),
# every run of the last 2 days, and the lag runs of the last 7. The rest listed with their size - only listed unless -Apply,
# then moved (not deleted) to <dont starve>\_trash_bench_logs, to be deleted by hand once sure. tests/work/bench_x copies of the
# moved runs go too (made again from the logs if ever wanted). 85 GB of logs on the game drive, 2026-10-28.
param([int]$Keep = 2, [string]$Baseline = "2026-10-28_0805_shares", [switch]$Apply)
$root = Split-Path -Parent $PSScriptRoot
$logs = Join-Path $root 'tests\work\bench_logs'
$bx = Join-Path $root 'tests\work\bench_x'
$trash = Join-Path (Split-Path -Parent $root) '_trash_bench_logs'
$now = Get-Date
$runs = Get-ChildItem $logs -Directory | Sort-Object Name
$full = @($runs | Where-Object { $_.Name -match '_shares$' -and @(Get-ChildItem $_.FullName -File).Count -ge 100 })
$keepFull = @($full | Select-Object -Last $Keep | ForEach-Object { $_.Name }) + $Baseline
$go = @()
foreach ($r in $runs) {
    $age = ($now - $r.LastWriteTime).TotalDays
    $lag = $r.Name -match '_lag$'
    $keep = ($keepFull -contains $r.Name) -or $age -lt 2 -or ($lag -and $age -lt 7)
    if (-not $keep) { $go += $r }
}
$total = 0
foreach ($r in $go) {
    $s = (Get-ChildItem $r.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    $total += $s
    "{0,-28} {1,8:N2} GB" -f $r.Name, ($s / 1GB)
}
"{0} runs, {1:N1} GB to go; kept full runs: {2}" -f $go.Count, ($total / 1GB), ($keepFull -join ', ')
if ($Apply) {
    New-Item -ItemType Directory -Force $trash | Out-Null
    foreach ($r in $go) {
        Move-Item $r.FullName (Join-Path $trash $r.Name)
        $x = Join-Path $bx $r.Name
        if (Test-Path $x) { Move-Item $x (Join-Path $trash ($r.Name + '__bench_x')) }
    }
    "moved to $trash - delete it by hand when sure"
}
