-- circle bench --

local p = require'primitives'

local count = 30000

local circ = {x = 1, y = 1, r = 20, color = 0, fill = true}

term.setGraphicsMode(2)

local start = os.epoch("utc")
for i=1, count, 1 do
  circ.color = i % 16
  circ.x = math.random(1, 20)
  circ.y = math.random(1, 20)
  p.circle(circ)
end
local finish = os.epoch("utc")

term.setGraphicsMode(false)

print(count.." circles took " .. (finish - start) .. "ms")
