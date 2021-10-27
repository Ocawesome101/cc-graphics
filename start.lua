local primitives = require("primitives")

local w, h = term.getSize(2) 

term.setGraphicsMode(2)

local palette = {
  0x000000,
  0x800000,
  0x008000,
  0x808000,
  0x000080,
  0x800080,
  0x008080,
  0xc0c0c0,
  0x808080,
  0xff0000,
  0x00ff00,
  0xffff00,
  0x66b6ff,
  0xff00ff,
  0x00ffff,
  0xffffff
}

for i=1, #palette, 1 do
  term.setPaletteColor(i - 1, palette[i])
end

primitives.rect {
  x = 0, y = 0,
  w = w, h = h,
  color = 0
}

local ui = require("ui")

local win = ui.Window:new {
  title = "TEST WINDOW",
  x = 10,
  y = 10
}

win:addChild(ui.Switch:new {
  x = 10,
  y = 10
})

ui.addWindow(win)

while true do
  if not ui.refresh() then break end
end

term.setGraphicsMode(false)

