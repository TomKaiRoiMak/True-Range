local A, B = dofile(arg[1]), dofile(arg[2])
local B64 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/"
local DIGIT = {} for i = 1, #B64 do DIGIT[B64:byte(i)] = i - 1 end
local function Cells(text, set)
  local pos = 1
  local function Num() local v, s = 0, 1 while true do local d = DIGIT[text:byte(pos)] or 0 pos = pos + 1 v = v + (d % 32) * s if d < 32 then return v end s = s * 32 end end
  local row = -1
  while pos <= #text do row = row + Num() local n = Num() local le = -1 for _ = 1, n do local f = le + 1 + Num() local t = f + Num() for c = f, t do set[row * 1000 + c] = true end le = t end end
end
local function All(m) local s = {} if m and m.steps then for _, st in ipairs(m.steps) do if st.cells then Cells(st.cells, s) end end end return s end
local worst = {}
for p, moves in pairs(A) do if p:sub(1,1) ~= "_" then for mv, e in pairs(moves) do local f = B[p] and B[p][mv]
  if f and e.maps then
    local tot, dif = 0, 0
    local function ByDist(maps) local r, last = {}, nil for _, m in ipairs(maps) do local c = m.same and last or All(m) last = c r[#r+1] = { m.dist, c } end return r end
    local da, db = ByDist(e.maps), ByDist(f.maps)
    local function Near(list, d) local best for _, x in ipairs(list) do if best == nil or math.abs(x[1] - d) < math.abs(best[1] - d) then best = x end end return best[2] end
    for _, x in ipairs(da) do
      local a, b = x[2], Near(db, x[1])
      for k in pairs(a) do tot = tot + 1 if not b[k] then dif = dif + 1 end end
      for k in pairs(b) do if not a[k] then dif = dif + 1 end end
    end
    if dif > 0 then table.insert(worst, { p .. " " .. mv, dif, tot }) end
  end end end end
table.sort(worst, function(x, y) return x[2] / x[3] > y[2] / y[3] end)
for _, w in ipairs(worst) do print(string.format("%-45s %6d of %7d cells  %.2f%%", w[1], w[2], w[3], w[2] / w[3] * 100)) end

