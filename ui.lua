-- user-interface library --

local primitives = require("primitives")
local expect = require("cc.expect")
local t = require("table-lib")

local _base = {}

function _base:new(...)
  local new = setmetatable({}, {__index = self})
  if new.__init then new:__init(...) end
  new.children = {}
  return new
end

function _base:click(x, y)
  for i=1, #self.children, 1 do
    local c = self.children[i]
    if x >= c.x and y >= c.y and x < c.x + c.w - 1 and y < c.y + c.h - 1 then
      c:click(x,y)
      break
    end
  end
end

function _base:drag(x, y)
  for i=1, #self.children, 1 do
    local c = self.children[i]
    if x >= c.x and y >= c.y and x < c.x + c.w - 1 and y < c.y + c.h - 1 then
      c:drag(x,y)
      break
    end
  end
end

function _base:click_up(x, y)
  for i=1, #self.children, 1 do
    local c = self.children[i]
    if x >= c.x and y >= c.y and x < c.x + c.w - 1 and y < c.y + c.h - 1 then
      c:click_up(x,y)
      break
    end
  end
end

local ui = {}

local windows = {}

ui.Window = _base:new()

function ui.Window:__init(params)
  expect(1, params, "table")
  self.x = params.x or 5
  self.y = params.y or 5
  self.w = params.w or 100
  self.h = params.h or 50
  self.title = params.title or "NEW WINDOW"
end

function ui.Window:redraw()
  primitives.rect {
    x = self.x + 1, y = self.y + 1, w = self.w, h = self.h, color = 0,
  }
  primitives.rect {
    x = self.x, y = self.y, w = self.w, h = self.h,
    color = self.focused and 7 or 8,
  }
  primitives.text {
    x = self.x + 2, y = self.y + 2, text = self.title, color = 0,
    font = "5x5"
  }
  primitives.circle {
    r = 2, x = self.x + self.w - 7, y = self.y + 2, color = 9, fill = true
  }
end

function ui.Window:click_up(x, y)
  if x > self.w - 7 and y < 10 then
    self.delete = true
  else
    _base.click_up(self)
  end
  self.isdrag = false
end

local xos, yos = 0, 0
function ui.Window:click(x, y)
  if y <= 10 then
    xos, yos = x, y
    self.isdrag = true
  else
    _base.click(self)
  end
end

function ui.addWindow(win)
  expect(1, window, "table")
  if windows[1] then windows[1].focused = false end
  t.insertIntoTable(windows, 1, win)
  windows[1].focused = true
  return true
end

function ui.refresh()
  local sig = table.pack(os.pullEvent())
  local del = {}
  term.setFrozen(true)
  term.clear()
  for i=#windows, 1, -1 do
    if windows[i].delete then
      del[#del+1] = i
    end
    windows[i]:redraw()
  end
  term.setFrozen(false)
  for i=#del, 1, -1 do
    t.removeFromTable(windows, del[i])
  end
  if sig[1] == "mouse_click" then
    local x, y = sig[3], sig[4]
    for i=1, #windows, 1 do
      local w = windows[i]
      if x >= w.x and y >= w.y and x < w.x + w.w - 1 and y < w.y + w.h - 1 then
        windows[1].focused = false
        t.removeFromTable(windows, i)
        t.insertIntoTable(windows, 1, w)
        w:click(x - w.x, y - w.y)
        w.focused = true
        break
      end
    end
  elseif sig[1] == "mouse_drag" then
    local x, y = sig[3], sig[4]
    local w = windows[1]
    if w.isdrag then
      w.x, w.y = x - xos, y - yos
    else
      w:drag(x - w.x, y - w.y)
    end
  elseif sig[1] == "mouse_up" then
    local x, y = sig[3], sig[4]
    local w = windows[1]
    if x >= w.x and y >= w.y and x < w.x + w.w - 1 and y < w.y + w.h - 1 then
      w:click_up(x - w.x, y - w.y)
    end
  end
  if sig[1] == "char" and sig[2] == "q" then return false end
  return true
end

return ui
