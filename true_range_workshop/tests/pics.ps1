# powershell -File tests\pics.ps1 -Log <log> -Boss <prefab> -At 12.3,12.6,... [-R 10] [-Mods workshop-3193922031] [-Out <dir>]
# What the mod draws at each moment, as the game shows it (replay.lua PIC_REAL) - the boss white (its
# facing a line), you blue - one picture each, side by side on every core, as PNGs to look at.
param([Parameter(Mandatory = $true)][string]$Log, [Parameter(Mandatory = $true)][string]$Boss,
    [Parameter(Mandatory = $true)][string]$At, [double]$R = 10, [string]$Mods = "workshop-3193922031", [string]$Out = "")
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
if ($Out -eq "") { $Out = Join-Path $root 'tests\work\pics' }
New-Item -ItemType Directory -Force $Out | Out-Null
$mod = Join-Path (Split-Path -Parent $root) 'true_range'
$times = $At -split ',' | Where-Object { $_ }
$ps = @()
foreach ($t in $times) {
    $ppm = Join-Path $Out ("{0}_{1}.ppm" -f $Boss, $t)
    $env:PIC_AT = $t; $env:PIC_REAL = "1"; $env:PIC_OUT = $ppm; $env:PIC_R = "$R"; $env:PIC_SCALE = "40"
    if ($Mods -ne "") { $env:TR_MODS = $Mods }
    $ps += Start-Process luajit -ArgumentList 'tests\replay.lua', "`"$mod`"", "`"$Log`"", 'tests\work\game_scripts', $Boss -NoNewWindow -PassThru `
        -WorkingDirectory $root -RedirectStandardOutput "$ppm.txt" -RedirectStandardError "$ppm.err"
}
foreach ($k in 'PIC_AT', 'PIC_REAL', 'PIC_OUT', 'PIC_R', 'PIC_SCALE', 'TR_MODS') { Remove-Item "env:$k" -ErrorAction SilentlyContinue }
$ps | ForEach-Object { $_.WaitForExit() }
$py = @"
import sys, glob, os
from PIL import Image
for f in sys.argv[1:]:
    if os.path.exists(f):
        Image.open(f).transpose(Image.FLIP_TOP_BOTTOM).save(f[:-4] + '.png')
        os.remove(f)
"@
$script = Join-Path $Out 'topng.py'
Set-Content -Path $script -Value $py -Encoding utf8
$ppms = @($times | ForEach-Object { Join-Path $Out ("{0}_{1}.ppm" -f $Boss, $_) })
# (not -I: Pillow is in the user's own site-packages; the script is ours)
python $script @ppms
foreach ($t in $times) {
    $png = Join-Path $Out ("{0}_{1}.png" -f $Boss, $t)
    if (Test-Path $png) { $png } else { "no picture at $t" }
}
