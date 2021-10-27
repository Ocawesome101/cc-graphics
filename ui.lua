-- user-interface library --

local primitives = require("primitives")
local expect = require("cc.expect").expect
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
      self.focused = c
      c:click(x,y)
      break
    end
  end
end

function _base:drag(x, y)
  for i=1, #self.children, 1 do
    local c = self.children[i]
    if x >= c.x and y >= c.y and x < c.x + c.w - 1 and y < c.y + c.h - 1 then
      self.focused = i
      c:drag(x,y)
      break
    end
  end
end

function _base:click_up(x, y)
  for i=1, #self.children, 1 do
    local c = self.children[i]
    if x >= c.x and y >= c.y and x < c.x + c.w - 1 and y < c.y + c.h - 1 then
      self.focus = i
      c:click_up(x,y)
      break
    end
  end
end

function _base:char(c)
  if self.focus then self.children[self.focus]:char(c) end
end

function _base:key(k, p)
  if self.focus then self.children[self.focus]:key(k, p) end
end

function _base:key_up(k)
  if self.focus then self.children[self.focus]:key_up(k) end
end

function _base:addChild(c)
  expect(1, c, "table")
  self.children[#self.children+1] = c
  return #self.children
end

function _base:redraw(x, y)
  for i=1, #self.children, 1 do
    self.children[i]:redraw(x + self.x, y + self.y)
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
  self.child_decorate = not not params.csd
  self.title = params.title or "NEW WINDOW"
end

function ui.Window:redraw(x, y)
  primitives.rect {
    x = self.x + 1, y = self.y + 1, w = self.w, h = self.h, color = 0,
  }
  primitives.rect {
    x = self.x, y = self.y, w = self.w, h = self.h,
    color = self.focused and 7 or 8,
  }
  if not self.child_decorate then
    primitives.text {
      x = self.x + 2, y = self.y + 2, text = self.title, color = 0,
      font = "5x5"
    }
    primitives.circle {
      r = 2, x = self.x + self.w - 7, y = self.y + 2, color = 9, fill = true
    }
  end
  _base.redraw(self, x, y)
end

function ui.Window:click_up(x, y, b)
  if x > self.w - 7 and y < 10 and not self.child_decorate then
    self.delete = true
  else
    _base.click_up(self, x, y, b)
  end
  self.isdrag = false
end

local xos, yos = 0, 0
function ui.Window:click(x, y, b)
  if y <= 10 and not self.child_decorate then
    xos, yos = x, y
    self.isdrag = true
  else
    _base.click(self, x, y, b)
  end
end

ui.Surface = _base:new()

function ui.Surface:__init(params)
  expect(1, params, "table")
  self.w = params.w or 100
  self.h = params.h or 50
  local line = string.rep("\0", self.w)
  self.buffer = {}
  for i=1, self.h, 1 do self.buffer[#self.buffer+1] = line end
end

function ui.Surface:setPixel(x, y, col)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, col, "number")
  if x > 0 and x < self.w and y > 0 and y < self.h then
    self.buffer[y] = self.buffer[y]:sub(0, math.max(0, x-1)) .. string.char(col)
      .. self.buffer[y]:sub(x + 1)
  end
  return self
end

function ui.Surface:drawPixels(x, y, buf, w, h)
  expect(1, x, "number")
  expect(2, y, "number")
  expect(3, buf, "number", "table")
  if type(buf) == "number" then
    expect(4, w, "number")
    expect(5, h, "number")
    if y + h < 0 then return end
    if x + w < 0 then return end
  else
    if #buf == 0 then return end
    if y + #buf < 0 then return end
    if x + #buf[1] < 0 then return end
  end
  if y > self.h then return end
  if x > self.w then return end
  
  local ox, oy = x, y
  x, y = math.max(0, math.min(x, self.w)), math.max(0, math.min(y, self.h))
  local xof, yof = math.abs(x - ox), math.abs(y - oy)
  if w then w = math.min(self.w - x, w - math.abs(x - ox)) end
  if h then h = math.min(self.h - y, h - math.abs(y - oy)) end
  if type(buf) == "number" then
    buf = string.char(buf):rep(w)
    for i=1, h, 1 do
      self.buffer[y+i-1] = self.buffer[y+i-1]:sub(0, math.max(0, x-1)) .. buf ..
        self.buffer[y+i-1]:sub(x + w)
    end
  else
    for i=1, h, 1 do
      self.buffer[y+i-1] = self.buffer[y+i-1]:sub(0, math.max(0, x-1)) ..
        buf[i+yof]
    end
  end
end

function ui.Surface:getSize()
  return self.w, self.h
end

function ui.Surface:redraw(x, y)
  term.drawPixels(x, y, self.buffer)
end

ui.View = _base:new()

ui.Label = _base:new()

function ui.Label:__init(params)
  expect(1, params, "table")
  self.x = params.x or 1
  self.y = params.y or 1
  self.text = params.text or ""
  self.color = params.color or 0
  self.font = params.font or "5x5"
end

ui.Button = _base:new()

function ui.Button:__init(params)
  expect(1, params, "table")
  self.x = params.x or 1
  self.y = params.y or 1
  self.w = params.w or 20
  self.h = params.h or 10
  self.r = params.radius or 2
  -- 0 rect
  -- 1 circle
  -- 2 rounded rect
  self.type = params.type or 2
  self.text = params.text
  self.surface = params.surface
end

function ui.Button:click()
  if self.onClick then
    self:onClick()
  end
end

function ui.Button:redraw(x, y)
  if self.type == 0 then
    primitives.rect({
      x = x + self.x, y = y + self.y,
      w = self.w, h = self.h,
      color = self.color
    }, self.surface)
  elseif self.type == 1 then
    primitives.circle({
      x = x + self.x, y = y + self.y,
      w = self.w, h = self.h, r = self.r,
      color = self.color, fill = true
    }, self.surface)
  elseif self.type == 2 then
    primitives.rounded_rect({
      x = x + self.x, y = y + self.y,
      w = self.w, h = self.h, radius = self.r,
      color = self.color
    }, self.surface)
  end
  if self.text then
    primitives.text({
      x = self.text.x, y = self.text.y, color = self.text.color,
      font = self.text.font
    }, self.surface)
  end
end

ui.Switch = ui.Button:new({})

function ui.Switch:__init(params)
  expect(1, params, "table")
  params.w = 10
  params.h = 5
  self.state = not not params.state
  ui.Button.__init(self, params)
end

function ui.Switch:click()
  self.state = not self.state
  if self.onClick then
    self:onClick(self.state)
  end
end

function ui.Switch:redraw(x, y)
  primitives.rect({
    x = x + self.x + 2,
    y = y + self.y, w = self.w - 4, h = self.h,
    color = self.state and 12 or 8
  }, self.surface)
  primitives.circle({
    x = x + self.x, y = y + self.y,
    color = (not self.state) and 15 or 12,
    r = 2, fill = true
  })
  primitives.circle({
    x = x + self.x + self.w - 4, y = y + self.y,
    color = self.state and 15 or 8,
    r = 2, fill = true
  })
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
    if windows[i] then 
      if windows[i].delete then
        del[#del+1] = i
      end
      windows[i]:redraw(0, 0)
    end
  end
  term.setFrozen(false)
  for i=#del, 1, -1 do
    t.removeFromTable(windows, del[i])
  end
  if not windows[1] then sig = {} end
  if sig[1] == "mouse_click" then
    local x, y = sig[3], sig[4]
    for i=1, #windows, 1 do
      local w = windows[i]
      if x >= w.x and y >= w.y and x < w.x + w.w - 1 and y < w.y + w.h - 1 then
        windows[1].focused = false
        t.removeFromTable(windows, i)
        t.insertIntoTable(windows, 1, w)
        w:click(x - w.x, y - w.y, sig[2])
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
      w:drag(x - w.x, y - w.y, sig[2])
    end
  elseif sig[1] == "mouse_up" then
    local x, y = sig[3], sig[4]
    local w = windows[1]
    if x >= w.x and y >= w.y and x < w.x + w.w - 1 and y < w.y + w.h - 1 then
      w:click_up(x - w.x, y - w.y, sig[2])
    end
  elseif sig[1] == "char" then
    windows[1]:char(sig[2])
  elseif sig[1] == "key" then
    windows[1]:key(sig[2], sig[3])
  elseif sig[1] == "key_up" then
    windows[1]:key_up(sig[2])
  end
  return true
end

return ui
