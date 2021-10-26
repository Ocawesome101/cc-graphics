local primitives = require("primitives")
local pixman = require("pixman")

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

primitives.text({x=1, y=1, text="this is some text"})
primitives.text({x=10, y=100, text="!\"#$&'(", font = "5x5"})

local wst = ""
for i=32, 126, 1 do wst = wst .. string.char(i) end
primitives.text({x=1, y=14, text=wst, font="5x5"})

primitives.rounded_rect({
  x = 100, y = 100,
  w = 30, h = 20,
  color = 5, radius = 4
})

primitives.rounded_rect({
  x = 140, y = 110,
  w = 50, h = 40,
  color = 6, radius = 5
})

os.pullEvent("char")
term.setGraphicsMode(false)
