# The "tri" picture in anim/trshapes.zip made a true triangle: its shape in the build's own
# vertices (three corners, sharp), every corner reading one opaque spot of its texture. Pieces
# side by side then meet edge to edge exactly - the graphics card fills each pixel once - with no
# soft texture edge between them to show as a line.
#   powershell -File tri_geometry.ps1 <trshapes.zip from scml.exe> <out zip>
# Run after compiling art/trshapes.scml (the tri picture's corner at its pivot, 256 pixels).
param([string]$Zip, [string]$Out)
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$N = 256
$entries = @{}
$z = [IO.Compression.ZipFile]::OpenRead($Zip)
foreach ($e in $z.Entries) {
    $ms = New-Object IO.MemoryStream; $st = $e.Open(); $st.CopyTo($ms); $st.Close()
    $entries[$e.Name] = $ms.ToArray()
}
$z.Dispose()
$b = $entries["build.bin"]
function I32($o) { [BitConverter]::ToInt32($b, $o) }
# (where things are: symbols' frames, then the vertices, then the names)
$o = 8
$ns = I32 $o; $o += 8
$l = I32 $o; $o += 4 + $l
$na = I32 $o; $o += 4
for ($i = 0; $i -lt $na; $i++) { $l = I32 $o; $o += 4 + $l }
$frames = @()
$TRI_HASH = [uint32]965812971   # hash of "tri"
$SQUARE_HASH = [uint32]1696137821   # "square"
for ($s = 0; $s -lt $ns; $s++) {
    $hash = [BitConverter]::ToUInt32($b, $o); $fr = I32 ($o + 4); $o += 8
    for ($f = 0; $f -lt $fr; $f++) { $frames += [pscustomobject]@{ hash = $hash; off = $o; vi = (I32 ($o + 24)); nv = (I32 ($o + 28)) }; $o += 32 }
}
$nvOff = $o
$nverts = I32 $o; $o += 4
$vbase = $o
$tail = $o + $nverts * 24
$tri = $frames | Where-Object { $_.hash -eq $TRI_HASH }
if ($tri -eq $null) { throw "no tri symbol" }
# (its texture's place in the atlas: from its own vertices - u, v at x, y run straight)
$p0 = $vbase + $tri.vi * 24
$xs = @(); $us = @(); $ys = @(); $vs = @()
for ($k = 0; $k -lt $tri.nv; $k++) {
    $p = $vbase + ($tri.vi + $k) * 24
    $xs += [BitConverter]::ToSingle($b, $p); $ys += [BitConverter]::ToSingle($b, $p + 4)
    $us += [BitConverter]::ToSingle($b, $p + 12); $vs += [BitConverter]::ToSingle($b, $p + 16)
}
$w = [BitConverter]::ToSingle($b, $p0 + 20)
$ia = 0; $ib = 0
for ($k = 0; $k -lt $xs.Count; $k++) { if ($xs[$k] -ne $xs[$ia]) { $ib = $k; break } }
$du = ($us[$ib] - $us[$ia]) / ($xs[$ib] - $xs[$ia])
$u0 = $us[$ia] - $du * $xs[$ia]
for ($k = 0; $k -lt $ys.Count; $k++) { if ($ys[$k] -ne $ys[$ia]) { $ib = $k; break } }
$dv = ($vs[$ib] - $vs[$ia]) / ($ys[$ib] - $ys[$ia])
$v0 = $vs[$ia] - $dv * $ys[$ia]
# (a spot well inside the opaque corner)
$su = $u0 + $du * ($N * .15); $sv = $v0 + $dv * (-$N * .15)
"atlas spot u {0:F4} v {1:F4} (atlas {2})" -f $su, $sv, $w
$corners = @(@(0, 0), @($N, 0), @(0, -$N), @(0, 0), @(0, 0), @(0, 0))
$newv = New-Object IO.MemoryStream
$bw = New-Object IO.BinaryWriter $newv
foreach ($c in $corners) { $bw.Write([single]$c[0]); $bw.Write([single]$c[1]); $bw.Write([single]0); $bw.Write([single]$su); $bw.Write([single]$sv); $bw.Write([single]$w) }
$bw.Flush()
$triBytes = $newv.ToArray()
# the new file: frames' vertex starts moved, the tri's vertices swapped
$nb = New-Object IO.MemoryStream
$nb.Write($b, 0, $nvOff)
$vs2 = New-Object IO.MemoryStream
$shift = @{}
$next = 0
foreach ($fm in ($frames | Sort-Object vi)) {
    if ($fm.hash -eq $TRI_HASH) { $vs2.Write($triBytes, 0, $triBytes.Length); $shift[$fm.off] = @($next, 6); $next += 6 }
    elseif ($fm.hash -eq $SQUARE_HASH) {
        # (the square: its corners as they are, all reading its middle - sharp edges too, pieces
        # laid end to end meet exactly)
        [byte[]]$sq = New-Object byte[] ($fm.nv * 24)
        [Array]::Copy($b, $vbase + $fm.vi * 24, $sq, 0, $sq.Length)
        $mu = 0; $mv = 0
        for ($k = 0; $k -lt $fm.nv; $k++) { $mu += [BitConverter]::ToSingle($sq, $k * 24 + 12); $mv += [BitConverter]::ToSingle($sq, $k * 24 + 16) }
        $mu /= $fm.nv; $mv /= $fm.nv
        for ($k = 0; $k -lt $fm.nv; $k++) {
            [BitConverter]::GetBytes([single]$mu).CopyTo($sq, $k * 24 + 12)
            [BitConverter]::GetBytes([single]$mv).CopyTo($sq, $k * 24 + 16)
        }
        $vs2.Write($sq, 0, $sq.Length); $shift[$fm.off] = @($next, $fm.nv); $next += $fm.nv
    }
    else { $vs2.Write($b, $vbase + $fm.vi * 24, $fm.nv * 24); $shift[$fm.off] = @($next, $fm.nv); $next += $fm.nv }
}
[byte[]]$head = $nb.ToArray()
foreach ($k in $shift.Keys) {
    [BitConverter]::GetBytes([int]$shift[$k][0]).CopyTo($head, $k + 24)
    [BitConverter]::GetBytes([int]$shift[$k][1]).CopyTo($head, $k + 28)
}
$final = New-Object IO.MemoryStream
$final.Write($head, 0, $head.Length)
$final.Write([BitConverter]::GetBytes([int]$next), 0, 4)
$vb = $vs2.ToArray(); $final.Write($vb, 0, $vb.Length)
$final.Write($b, $tail, $b.Length - $tail)
$entries["build.bin"] = $final.ToArray()
"vertices $nverts -> $next"
if (Test-Path $Out) { Remove-Item $Out }
$zo = [IO.Compression.ZipFile]::Open($Out, [IO.Compression.ZipArchiveMode]::Create)
foreach ($name in $entries.Keys) {
    $en = $zo.CreateEntry($name)
    $st = $en.Open(); $st.Write($entries[$name], 0, $entries[$name].Length); $st.Close()
}
$zo.Dispose()
"written $Out"
