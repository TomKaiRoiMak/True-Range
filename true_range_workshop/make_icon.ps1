# Makes the Workshop preview and the in-game mod icon from one square picture.
#   powershell -File make_icon.ps1 <picture.png>
# preview.png: 600x600 next to this script (Steam takes previews under 1 MB).
# ..\true_range\modicon.tex + modicon.xml: 128x128, the game's KTEX format, uncompressed RGBA,
# rows stored bottom to top as the game reads them.
# (-ModDir / -Preview: where the icon and the preview go - the client build's own, tools\install_client.ps1)
param([Parameter(Mandatory = $true)][string]$Source, [string]$ModDir = '', [string]$Preview = '')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$here = $PSScriptRoot
$mod = if ($ModDir -ne '') { $ModDir } else { Join-Path (Split-Path -Parent $here) 'true_range' }
if ($Preview -eq '') { $Preview = Join-Path $here 'preview.png' }
New-Item -ItemType Directory -Force $mod | Out-Null

function Resized($img, $size) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.DrawImage($img, 0, 0, $size, $size)
    $g.Dispose()
    return $bmp
}

$src = [System.Drawing.Image]::FromFile((Resolve-Path $Source))
try {
    $prev = Resized $src 600
    $prev.Save($Preview, [System.Drawing.Imaging.ImageFormat]::Png)
    $prev.Dispose()

    $n = 128
    $icon = Resized $src $n
    $data = New-Object byte[] ($n * $n * 4)
    $i = 0
    for ($y = $n - 1; $y -ge 0; $y--) {
        for ($x = 0; $x -lt $n; $x++) {
            $c = $icon.GetPixel($x, $y)
            # (alpha premultiplied, as the game draws)
            $a = $c.A / 255
            $data[$i] = [byte][math]::Round($c.R * $a)
            $data[$i + 1] = [byte][math]::Round($c.G * $a)
            $data[$i + 2] = [byte][math]::Round($c.B * $a)
            $data[$i + 3] = $c.A
            $i += 4
        }
    }
    $icon.Dispose()
    # header: platform 0, pixel format 4 (RGBA), texture type 1 (2D), 1 mip, flags 0, the rest set
    [uint32]$head = [uint32]4293918720 + (1 -shl 13) + (1 -shl 9) + (4 -shl 4)
    $ms = New-Object System.IO.MemoryStream
    $w = New-Object System.IO.BinaryWriter $ms
    $w.Write([byte[]][char[]]'KTEX')
    $w.Write($head)
    $w.Write([uint16]$n); $w.Write([uint16]$n); $w.Write([uint16]($n * 4)); $w.Write([uint32]$data.Length)
    $w.Write($data)
    $w.Flush()
    [IO.File]::WriteAllBytes((Join-Path $mod 'modicon.tex'), $ms.ToArray())
    $w.Dispose()
    $xml = '<Atlas><Texture filename="modicon.tex" /><Elements><Element name="modicon.tex" u1="0.00390625" u2="0.99609375" v1="0.00390625" v2="0.99609375" /></Elements></Atlas>'
    [IO.File]::WriteAllText((Join-Path $mod 'modicon.xml'), $xml, (New-Object System.Text.UTF8Encoding($false)))
} finally {
    $src.Dispose()
}
Get-Item $Preview, (Join-Path $mod 'modicon.tex'), (Join-Path $mod 'modicon.xml') | ForEach-Object { "{0} {1}" -f $_.Name, $_.Length }
