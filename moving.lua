local primitives = require("primitives")

local rect = {
  x = 1, y = 1, w = 20, h = 20,
  color = 1
}

local rect2 = {
  x = 1, y = 1, w = 20, h = 20,
  color = 1
}

term.setGraphicsMode(2)
term.clear()

local w, h = term.getSize(2)
while true do
  os.sleep(0.01)
  term.setFrozen(true)
  rect.color = 15
  rect2.color = 15
  primitives.rect(rect)
  primitives.rect(rect2)
  rect.color = 1
  rect2.color = 2
  rect.x = rect.x + 2
  if rect.x > w then
    rect.x = -20
  end
  rect.y = (1/500)*math.floor(rect.x^2 - rect.x)
  rect2.x = w - rect.x
  rect2.y = h - rect.y
  primitives.rounded_rect(rect)
  primitives.rounded_rect(rect2)
  term.setFrozen(false)
end

term.setGraphicsMode(false)
