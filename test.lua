local primitives = require("primitives")

term.setGraphicsMode(2)
term.clear()

primitives.rect({
  x = 10, y = 10, w = 20, h = 20, color = 1
})

primitives.circle({
  color = 2,
  r = 30, x = 10, y = 10,
  fill = true
})

primitives.circle({
  color = 3,
  r = 10,
  x = 20, y = 20,
  fill = true
})

primitives.text(1, 1, "this is some text")

local wst = ""
for i=32, 126, 1 do wst = wst .. string.char(i) end
primitives.text(1, 14, wst)

for i=1, 16, 1 do
  primitives.scroll(1, {x=1, y=1, w=50, h=50})
  os.sleep(0.05)
end

for i=1, 16, 1 do
  primitives.scroll(-1, {x=1, y=1, w=50, h=50})
  os.sleep(0.05)
end

for i=1, 16, 1 do
  primitives.scrollX(1)
  os.sleep(0.05)
end

for i=1, 16, 1 do
  primitives.scrollX(-1)
  os.sleep(0.05)
end

sleep(1)
primitives.text(1, 150, wst, 1)

os.pullEvent("char")
term.setGraphicsMode(false)

