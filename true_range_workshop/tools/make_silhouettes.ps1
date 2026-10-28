# Draws each shape from silhouettes.lua's shapes.txt as a picture, and the Spriter file that
# makes them one animation build for the game (Mod Tools scml.exe):
#   powershell -File make_silhouettes.ps1 <dir with shapes.txt>
# Each picture: white, the inside faint, a band along the inside of its edge darker and strong,
# the edge itself a fine bright line - the game colours it (SetMultColour), so one picture does
# for every colour. Smooth: drawn with anti-aliasing, from the smooth outline.
param([string]$Dir)
Add-Type -AssemblyName System.Drawing
$FILL_ALPHA = 115    # the inside
$BAND_PX = 3         # the band's width, in pixels (1.5 cells at 8 px a unit)
$BAND_GREY = 110     # the band: darker...
$BAND_ALPHA = 225    # ...and strong
$EDGE_PX = 1.3       # the edge line
$SS = 4              # drawn this many times bigger, then made small: smooth inner edges too
$lines = Get-Content (Join-Path $Dir "shapes.txt")
$folders = @()
$anims = @()
$i = 0
foreach ($line in $lines) {
    $parts = $line.Split(" ")
    $name, $w, $h = $parts[0], [int]$parts[1], [int]$parts[2]
    $bmp = New-Object Drawing.Bitmap ($w * $SS), ($h * $SS), ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.ScaleTransform($SS, $SS)
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([Drawing.Color]::FromArgb(0, 0, 0, 0))
    # the outline's pieces, joined into loops where they meet end to end
    $path = New-Object Drawing.Drawing2D.GraphicsPath
    $path.FillMode = [Drawing.Drawing2D.FillMode]::Alternate
    $pts = New-Object System.Collections.Generic.List[Drawing.PointF]
    $lastX, $lastY = $null, $null
    for ($k = 3; $k -lt $parts.Length; $k++) {
        $v = $parts[$k].Split(",") | ForEach-Object { [single]$_ }
        if ($lastX -ne $null -and ([Math]::Abs($v[0] - $lastX) -gt .01 -or [Math]::Abs($v[1] - $lastY) -gt .01)) {
            if ($pts.Count -ge 3) { $path.AddPolygon($pts.ToArray()) }
            $pts.Clear()
        }
        if ($pts.Count -eq 0) { $pts.Add((New-Object Drawing.PointF $v[0], $v[1])) }
        $pts.Add((New-Object Drawing.PointF $v[2], $v[3]))
        $lastX, $lastY = $v[2], $v[3]
    }
    if ($pts.Count -ge 3) { $path.AddPolygon($pts.ToArray()) }
    # inside
    $fill = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb($FILL_ALPHA, 255, 255, 255))
    $g.FillPath($fill, $path)
    # the band: the edge drawn twice as wide, kept to the inside
    $g.SetClip($path)
    $g.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $band = New-Object Drawing.Pen ([Drawing.Color]::FromArgb($BAND_ALPHA, $BAND_GREY, $BAND_GREY, $BAND_GREY)), (2 * $BAND_PX)
    $band.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
    $g.DrawPath($band, $path)
    $g.ResetClip()
    $g.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceOver
    # the edge
    $edge = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(255, 255, 255, 255)), $EDGE_PX
    $edge.LineJoin = [Drawing.Drawing2D.LineJoin]::Round
    $g.DrawPath($edge, $path)
    $g.Dispose()
    $sub = Join-Path $Dir $name
    New-Item -ItemType Directory -Force $sub | Out-Null
    $small = New-Object Drawing.Bitmap $w, $h, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gs = [Drawing.Graphics]::FromImage($small)
    $gs.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gs.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $gs.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
    $gs.DrawImage($bmp, (New-Object Drawing.Rectangle 0, 0, $w, $h))
    $gs.Dispose()
    $bmp.Dispose()
    # (the game blends pictures as premultiplied: each colour times its own opacity - else where it's
    # clear still adds its colour, and the whole square showed)
    $rect = New-Object Drawing.Rectangle 0, 0, $w, $h
    $data = $small.LockBits($rect, [Drawing.Imaging.ImageLockMode]::ReadWrite, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $n = $data.Stride * $h
    $px = New-Object byte[] $n
    [Runtime.InteropServices.Marshal]::Copy($data.Scan0, $px, 0, $n)
    for ($q = 0; $q -lt $n; $q += 4) {
        $a = $px[$q + 3]
        if ($a -lt 255) {
            $px[$q] = [byte][Math]::Round($px[$q] * $a / 255)
            $px[$q + 1] = [byte][Math]::Round($px[$q + 1] * $a / 255)
            $px[$q + 2] = [byte][Math]::Round($px[$q + 2] * $a / 255)
        }
    }
    [Runtime.InteropServices.Marshal]::Copy($px, 0, $data.Scan0, $n)
    $small.UnlockBits($data)
    $small.Save((Join-Path $sub "$name-0.png"), [Drawing.Imaging.ImageFormat]::Png)
    $small.Dispose()
    $folders += ('  <folder id="{0}" name="{1}"><file id="0" name="{1}/{1}-0.png" width="{2}" height="{3}" pivot_x="0.5" pivot_y="0.5"/></folder>' -f $i, $name, $w, $h)
    $anims += ('  <animation id="{0}" name="{1}" length="100" interval="100" looping="false">' -f $i, $name)
    $anims += ('   <mainline><key id="0" time="0"><object_ref id="0" timeline="0" key="0" z_index="0"/></key></mainline>')
    $anims += ('   <timeline id="0" name="{1}"><key id="0" time="0" spin="0"><object folder="{0}" file="0" x="0" y="0" angle="0"/></key></timeline>' -f $i, $name)
    $anims += ('  </animation>')
    $i++
}
$scml = @('<?xml version="1.0" encoding="UTF-8"?>', '<spriter_data scml_version="1.0" generator="BrashMonkey Spriter" generator_version="b5">')
$scml += $folders
$scml += ' <entity id="0" name="trsil">'
$scml += $anims
$scml += ' </entity>'
$scml += '</spriter_data>'
[IO.File]::WriteAllText((Join-Path $Dir "trsil.scml"), ($scml -join "`n"))
"{0} pictures, trsil.scml written" -f $i
