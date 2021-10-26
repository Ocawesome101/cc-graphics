local primitives = require"primitives"

local wx, wy = 10, 10

local wrect = {
  x = wx, y = wy, w = 100, h = 100, color = 7
}

local wirect = {
  x = wx, y = wy + 10, w = 100, h = 90, color = 8
}

local function draw_window()
  wrect.x = wx
  wrect.y = wy
  wirect.x = wx
  wirect.y = wy
  primitives.rect(wrect)
  primitives.rect(wirect)
end

