# The right-angled triangle picture the fill is drawn with (art/tri/tri-0.png): its right angle
# at the bottom left (the pivot), legs along the bottom and left, the long side smooth - each
# pixel as opaque as how much of it the triangle covers (premultiplied: the game blends so).
# Big, so the long side's soft pixel is thin even scaled up across a wide shape.
#   powershell -File make_tri.ps1 <art dir> [size]
param([string]$Art, [int]$N = 256)
Add-Type -AssemblyName System.Drawing
$SS = 8
$b = New-Object Drawing.Bitmap $N, $N, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($y = 0; $y -lt $N; $y++) {
    $up = $N - 1 - $y
    for ($x = 0; $x -lt $N; $x++) {
        if ($x + $up + 2 -le $N) { $c = 1 }
        elseif ($x + $up -ge $N) { $c = 0 }
        else {
            $in = 0
            for ($i = 0; $i -lt $SS; $i++) {
                for ($j = 0; $j -lt $SS; $j++) {
                    if (($x + ($i + .5) / $SS) + ($up + ($j + .5) / $SS) -le $N) { $in++ }
                }
            }
            $c = $in / ($SS * $SS)
        }
        $v = [int][Math]::Round(255 * $c)
        $b.SetPixel($x, $y, [Drawing.Color]::FromArgb($v, $v, $v, $v))
    }
}
New-Item -ItemType Directory -Force (Join-Path $Art "tri") | Out-Null
$b.Save((Join-Path $Art "tri\tri-0.png"), [Drawing.Imaging.ImageFormat]::Png)
$b.Dispose()
"tri-0.png: $N x $N"
