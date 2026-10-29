# powershell -File tools\hand_check.ps1
# The moves and things written by hand (true_range moves_hand.lua, moves_hand_um.lua) still there in the game: a rebuild never
# touches them, so a game or Uncompromising Mode update renaming a prefab or an animation would leave them drawing nothing,
# silently. Each prefab checked against the game's and UM's prefab files, each animation against every animation known
# (tools/anim_lengths*.lua). Exit 1 if any is gone. (2026-10-28)
$root = Split-Path -Parent $PSScriptRoot
$src = Join-Path (Split-Path -Parent $root) 'true_range\scripts\true_range'
$um = 'D:\Games Manager\Games\steamapps\workshop\content\322330\3193922031'
# (every animation name in the game's and the mods' anim files)
$anims = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($f in Get-ChildItem (Join-Path $root 'tools') -Filter 'anim_lengths*.lua') {
    foreach ($m in [regex]::Matches([IO.File]::ReadAllText($f.FullName), '\["([^"]+)"\]\s*=\s*[\d.]')) { [void]$anims.Add($m.Groups[1].Value) }
}
# (every prefab made anywhere: Prefab("name" in the game's scripts, UM's scripts and postinit)
$prefabs = New-Object 'System.Collections.Generic.HashSet[string]'
$dirs = @((Join-Path $root 'tests\work\game_scripts_um\prefabs'), (Join-Path $root 'tests\work\game_scripts\prefabs'), (Join-Path $um 'scripts\prefabs'))
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { continue }
    foreach ($f in Get-ChildItem $d -Recurse -Filter '*.lua') {
        foreach ($m in [regex]::Matches([IO.File]::ReadAllText($f.FullName), 'Prefab\(\s*"([^"]+)"')) { [void]$prefabs.Add($m.Groups[1].Value) }
        # (and made by a maker of its file's own: return MakeMerm("merm", ...) - merm "GONE", 2026-10-29)
        foreach ($m in [regex]::Matches([IO.File]::ReadAllText($f.FullName), 'Make[A-Z]\w*\(\s*"([^"]+)"')) { [void]$prefabs.Add($m.Groups[1].Value) }
    }
}
# (what the hand files name: "file prefab move anim" lines)
$lua = @'
for _, f in ipairs({ "moves_hand", "moves_hand_um" }) do
  local ok, t = pcall(dofile, arg[1] .. "/" .. f .. ".lua")
  if ok and type(t) == "table" then
    for prefab, moves in pairs(t) do
      if type(moves) == "table" and prefab:sub(1, 1) ~= "_" then
        print(f .. " " .. prefab .. " - -")
        for name, m in pairs(moves) do
          if type(m) == "table" then for _, a in ipairs(m.anims or {}) do print(f .. " " .. prefab .. " " .. tostring(name) .. " " .. a) end end
        end
      elseif prefab == "_hazards" and type(moves) == "table" then
        for hp in pairs(moves) do print(f .. " " .. hp .. " - -") end
      end
    end
  else print("ERROR " .. f .. " " .. tostring(t)) end
end
'@
$tmp = Join-Path $env:TEMP 'tr_hand_check.lua'
[IO.File]::WriteAllText($tmp, $lua)
$bad = 0; $n = 0
foreach ($l in (& luajit $tmp $src)) {
    $w = $l -split ' '
    if ($w[0] -eq 'ERROR') { Write-Host $l; $bad++; continue }
    $n++
    if ($w[2] -eq '-') {
        if (-not $prefabs.Contains($w[1])) { Write-Host "GONE prefab $($w[1]) ($($w[0]))"; $bad++ }
    } elseif (-not $anims.Contains($w[3])) { Write-Host "GONE anim $($w[3]) of $($w[1]).$($w[2]) ($($w[0]))"; $bad++ }
}
"hand_check: $n names looked at ($($prefabs.Count) prefabs, $($anims.Count) animations known), $bad gone"
if ($bad -gt 0) { exit 1 }
