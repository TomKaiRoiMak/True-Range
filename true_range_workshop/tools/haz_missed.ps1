# powershell -File tools\haz_missed.ps1 -Dir <tests\work\bench_replay\run[__client1]> [-Group]
# The things' MISSED lines of a bench_replay folder as its table counts them: less those its boss's move drew (ASBOSS_DRAWN
# within .05 s, the same share) - the raw lines count those too, and a piece's lead twice (2026-10-29: "44 icespikes", 0 real).
param([string]$Dir, [switch]$Group)
$as = @{}
foreach ($f in Get-ChildItem $Dir -Filter '*.txt' | Where-Object { $_.Name -notlike '*___haz.txt' }) {
    $sh = (($f.BaseName -split '__', 2)[0]) -replace '#p\d+$', ''
    foreach ($m in (Select-String -Path $f.FullName -Pattern '^ASBOSS_DRAWN ([\d\.]+)')) {
        if (-not $as.ContainsKey($sh)) { $as[$sh] = New-Object System.Collections.Generic.List[double] }
        $as[$sh].Add([double]$m.Matches[0].Groups[1].Value)
    }
}
$rows = foreach ($f in Get-ChildItem $Dir -Filter '*___haz.txt') {
    $sh = (($f.BaseName -split '__', 2)[0]) -replace '#p\d+$', ''
    foreach ($m in (Select-String -Path $f.FullName -Pattern '^MISSED\s+([\d\.]+) (\S+):')) {
        $t = [double]$m.Matches[0].Groups[1].Value
        $taken = $false
        if ($as.ContainsKey($sh)) { foreach ($x in $as[$sh]) { if ([math]::Abs($x - $t) -lt .05) { $taken = $true; break } } }
        if (-not $taken) { [pscustomobject]@{ share = $sh; t = $t; thing = $m.Matches[0].Groups[2].Value.TrimEnd(':'); line = $m.Line } }
    }
}
$rows = @($rows | Sort-Object share, t -Unique)
if ($Group) { $rows | Group-Object thing | Sort-Object Count -Descending | Format-Table Count, Name -AutoSize }
else { foreach ($r in $rows) { "{0}: {1}" -f $r.share, $r.line } }
"{0} missed" -f $rows.Count
