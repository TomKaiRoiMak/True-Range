-- luajit tablediff.lua <a.lua> <b.lua>: where two data files (each returning a table) differ, down to 3 levels
local a, b = dofile(arg[1]), dofile(arg[2])
local function ser(v)
  if type(v) ~= "table" then return tostring(v) end
  local ks = {}
  for k in pairs(v) do ks[#ks+1] = k end
  table.sort(ks, function(x, y) return tostring(x) < tostring(y) end)
  local o = {}
  for _, k in ipairs(ks) do o[#o+1] = tostring(k) .. "=" .. ser(v[k]) end
  return "{" .. table.concat(o, ",") .. "}"
end
local function cmp(x, y, path, depth)
  if ser(x) == ser(y) then return end
  if type(x) ~= "table" or type(y) ~= "table" or depth >= 3 then print("DIFF " .. path) return end
  local ks = {}
  for k in pairs(x) do ks[k] = true end
  for k in pairs(y) do ks[k] = true end
  for k in pairs(ks) do cmp(x[k], y[k], path .. "." .. tostring(k), depth + 1) end
end
cmp(a, b, "", 0)
