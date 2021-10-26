-- graphical primitives --

local RC_RADIUS = 4

local pixman = require("pixman")

local lib = {}

function lib.rect(r)
  term.drawPixels(r.x, r.y, r.color, r.w, r.h)
end

-- copied from groups.csail.mit.edu
local function circlePoints(cx, cy, x, y, px, fill)
  local ln, lnx
  if fill then
    ln = {string.rep(string.char(px), y*2+1)}
    lnx = {string.rep(string.char(px), x*2+1)}
  end
  if x == 0 then
    term.setPixel(cx, cy + y, px)
    term.setPixel(cx, cy - y, px)
    if fill then
      term.drawPixels(cx - y, cy, ln)
    else
      term.setPixel(cx + y, cy, px)
      term.setPixel(cx - y, cy, px)
    end
  elseif x == y then
    if fill then
      term.drawPixels(cx - x, cy + y, ln)
      term.drawPixels(cx - x, cy - y, ln)
    else
      term.setPixel(cx + x, cy + y, px)
      term.setPixel(cx - x, cy + y, px)
      term.setPixel(cx + x, cy - y, px)
      term.setPixel(cx - x, cy - y, px)
    end
  elseif x < y then
    if fill then
      term.drawPixels(cx - x, cy + y, lnx)
      term.drawPixels(cx - x, cy - y, lnx)
      term.drawPixels(cx - y, cy + x, ln)
      term.drawPixels(cx - y, cy - x, ln)
    else
      term.setPixel(cx + x, cy + y, px)
      term.setPixel(cx - x, cy + y, px)
      term.setPixel(cx + x, cy - y, px)
      term.setPixel(cx - x, cy - y, px)
      term.setPixel(cx + y, cy + x, px)
      term.setPixel(cx - y, cy + x, px)
      term.setPixel(cx + y, cy - x, px)
      term.setPixel(cx - y, cy - x, px)
    end
  end
end

local function drawCircle(xcenter, ycenter, radius, color, fill)
  local x, y = 0, radius
  local p = (5 - radius*4)/4
  
  circlePoints(xcenter, ycenter, x, y, color, fill)
  while x < y do
    x = x + 1
    if p < 0 then
      p = p + 2*x+1
    else
      y = y - 1
      p = p + 2*(x-y)+1
    end
    circlePoints(xcenter, ycenter, x, y, color, fill)
  end
end

function lib.circle(c)
  drawCircle(c.x + c.r, c.y + c.r, c.r, c.color, c.fill)
end

local font = {}

-- NEW HEXFONT LOADER

local function reverse_bits()
end

for line in io.lines("gfx/font.hex") do
  local ch, dat = line:match("(%x+):(%x+)")
  ch = tonumber("0x"..ch)
  if ch > 255 then
    break
  end
  ch = string.char(ch)
  font[ch] = {}
  for bp in dat:gmatch("%x%x") do
    font[ch][#font[ch]+1] = tonumber("0x"..bp)
  end
end

function lib.glyph(x, y, char, color)
  local data = font[char]
  if not data then
    error("bad glyph " .. char)
  end
  for i, byte in ipairs(data) do
    for N = 7, 0, -1 do
      if bit32.band(byte, 2^N) ~= 0 then
        term.setPixel(x + (7-N), y + i - 1, color)
      end
    end
  end
end

function lib.text(t, r)
  local w, h = term.getSize(2)
  local x, y = t.x, t.y
  for c in t.text:gmatch(".") do
    lib.glyph(x, y, c, t.color or 0)
    x = x + 8
    if x + 8 > w then
      x = t.wrapTo or 0
      y = y + 16
      if y + 16 > h then
        pixman.yscroll(16, r)
        y = y - 16
      end
    end
  end
end

function lib.rounded_rect(r)
  local radius = r.radius or RC_RADIUS
  local r1 = {x = r.x + radius, y = r.y, w = r.w - radius * 2, h = r.h,
    color = r.color}
  local r2 = {x = r.x, y = r.y + radius, w = r.w, h = r.h - radius * 2,
    color = r.color}
  lib.rect(r1)
  lib.rect(r2)
  local points = {
    {r.x, r.y},
    {r.x, r.y + r.h - (radius * 2) - 1},
    {r.x + r.w - (radius * 2) - 1, r.y},
    {r.x + r.w - (radius * 2) - 1, r.y + r.h - (radius * 2) - 1},
  }
  for i=1, #points, 1 do
    lib.circle({x = points[i][1], y = points[i][2], r = radius,
      color = r.color, fill = true})
  end
end

return lib
