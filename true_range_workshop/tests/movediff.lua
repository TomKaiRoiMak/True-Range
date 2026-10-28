local A, B = dofile(arg[1]), dofile(arg[2])
local function Dump(v, out)
  if type(v) ~= "table" then out[#out+1] = tostring(v) return end
  local keys = {} for k in pairs(v) do keys[#keys+1] = k end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  out[#out+1] = "{" for _, k in ipairs(keys) do out[#out+1] = tostring(k) .. "=" Dump(v[k], out) out[#out+1] = "," end out[#out+1] = "}"
end
local n = 0
for p, moves in pairs(A) do
  if p:sub(1,1) ~= "_" and type(moves) == "table" then
    for m, e in pairs(moves) do
      local a, b = {}, {} Dump(e, a) Dump(B[p] and B[p][m], b)
      if table.concat(a) ~= table.concat(b) then
        n = n + 1
        local why = {}
        local f = B[p] and B[p][m]
        if f == nil then why[1] = "gone" else
          for k, v in pairs(e) do local x, y = {}, {} Dump(v, x) Dump(f[k], y) if table.concat(x) ~= table.concat(y) then why[#why+1] = k end end
          for k in pairs(f) do if e[k] == nil then why[#why+1] = "+" .. k end end
        end
        print(p, m, table.concat(why, ","))
      end
    end
  end
end
for p, moves in pairs(B) do if p:sub(1,1) ~= "_" and type(moves) == "table" then for m in pairs(moves) do if not (A[p] and A[p][m]) then print(p, m, "NEW") end end end end
-- (and the things set off, _hazards - a splice once added one drawn with its move only, unseen here, 2026-10-20)
local HA, HB = A._hazards or {}, B._hazards or {}
for k, v in pairs(HA) do
  local a, b = {}, {} Dump(v, a) Dump(HB[k], b)
  if table.concat(a) ~= table.concat(b) then n = n + 1 print("_hazards", k, HB[k] == nil and "gone" or "changed") end
end
for k in pairs(HB) do if HA[k] == nil then n = n + 1 print("_hazards", k, "NEW") end end
print("changed", n)
