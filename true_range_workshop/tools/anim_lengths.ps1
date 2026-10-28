# Reads how long each animation really is (frames / frame rate) from the game's anim zips, for
# sim_moves.lua (it needs to know when an animation ends: "animover").
#   powershell -File anim_lengths.ps1 <out.lua> <zip> [<zip> ...]
# anim.bin: "ANIM", version, 4 counts, then per animation: name, facing, root symbol, frame
# rate, frame count, and each frame (bounds, events, elements of 40 bytes).

param([string]$Out, [Parameter(ValueFromRemainingArguments = $true)][string[]]$Zips)

Add-Type -AssemblyName System.IO.Compression.FileSystem
$lines = @("-- Made by true_range_workshop/tools/anim_lengths.ps1: anim file -> animation -> seconds", "return {")
$count = 0
foreach ($zip in $Zips) {
    $seen = @{}
    $banks = @()
    $lines += ('    ["{0}"] = {{' -f [IO.Path]::GetFileNameWithoutExtension($zip))
    $archive = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        $entry = $archive.Entries | Where-Object { $_.FullName -eq "anim.bin" } | Select-Object -First 1
        if ($null -eq $entry) { continue }
        $ms = New-Object IO.MemoryStream
        $s = $entry.Open(); $s.CopyTo($ms); $s.Close()
        $ms.Position = 0
        $r = New-Object IO.BinaryReader($ms)
        $magic = [Text.Encoding]::ASCII.GetString($r.ReadBytes(4))
        if ($magic -ne "ANIM") { continue }
        $null = $r.ReadUInt32()                      # version
        $null = $r.ReadUInt32(); $null = $r.ReadUInt32(); $null = $r.ReadUInt32()
        $numanims = $r.ReadUInt32()
        for ($a = 0; $a -lt $numanims; $a++) {
            $len = $r.ReadUInt32()
            $name = [Text.Encoding]::ASCII.GetString($r.ReadBytes($len))
            $null = $r.ReadByte()                    # facing
            $bank = $r.ReadUInt32()                  # its bank (the hash of its name)
            $rate = $r.ReadSingle()
            $frames = $r.ReadUInt32()
            for ($f = 0; $f -lt $frames; $f++) {
                $null = $r.ReadBytes(16)             # bounds
                $ev = $r.ReadUInt32(); $null = $r.ReadBytes(4 * $ev)
                $el = $r.ReadUInt32(); $null = $r.ReadBytes(40 * $el)
            }
            # (a name may hold a backslash or quote - written as Lua would read it)
            $name = $name.Replace('\', '\\').Replace('"', '\"')
            if (-not $seen.ContainsKey($name) -and $rate -gt 0) {
                $seen[$name] = $true
                $count++
                $lines += ('        ["{0}"] = {1},' -f $name, ([double]$frames / $rate).ToString([Globalization.CultureInfo]::InvariantCulture))
                $banks += ('["{0}"] = {1}' -f $name, $bank)
            }
        }
    } finally {
        $archive.Dispose()
        # (which bank each animation is for - several bosses have an "atk": the one of its own bank)
        if ($banks.Count -gt 0) { $lines += ("        _banks = {{ {0} }}," -f ($banks -join ", ")) }
        $lines += "    },"
    }
}
$lines += "}"
[IO.File]::WriteAllText($Out, ($lines -join "`n"), (New-Object Text.UTF8Encoding($false)))
"{0} animations written to {1}" -f $count, $Out
