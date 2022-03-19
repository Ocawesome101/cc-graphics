-- BDF-to-hexfont converter

local rbf = require("src.utils.readBDFfont")

local rawbdf = io.read("*a")
local fdata = rbf(rawbdf).chars

local w, h = fdata.A.bounds.width, fdata.A.bounds.height

for char, data in pairs(fdata) do
  local bmap = ""
  for _, line in ipairs(data.bitmap) do
    local n = 0
    for i, bit in ipairs(line) do
      if bit then n = bit32.bor(n, 2^(i-1)) end
    end
    bmap = bmap .. string.format("%02x", n)
  end
  print(string.format("%04x:%s", char:byte(), bmap))
end
