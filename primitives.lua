-- graphical primitives --

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

-- font.txt is expected to contain a monospace 8x16 font
-- see the example one for the exact format
local handle = io.open("font.txt", "r")
local n, c = 0, ""
for line in handle:lines("l") do
  if n == 0 or n == 17 then
    font[line] = {}
    n = 1
    c = line
  else
    local byte = 0
    local N = 0
    for c in line:gmatch(".") do
      if c == "#" then
        byte = bit32.bor(byte, (2^N))
      end
      N = N + 1
    end
    n = n + 1
    table.insert(font[c], byte)
  end
end

handle:close()

function lib.glyph(x, y, char, color)
  local data = font[char]
  if not data then
    error("bad glyph " .. char)
  end
  for i, byte in ipairs(data) do
    for N = 0, 7, 1 do
      if bit32.band(byte, 2^N) ~= 0 then
        term.setPixel(x + N, y + i - 1, color)
      end
    end
  end
end

local function insertIntoTable(t, n, i)
  local ogn = #t
  for j=ogn, n, -1 do
    t[j+1] = t[j]
  end
  t[n] = i
end

local function removeFromTable(t, n)
  local ogn = #t
  t[n] = nil
  for i=n+1, ogn, 1 do
    t[i-1] = t[i]
  end
  if n < ogn then t[#t] = nil end
end

function lib.scroll(n, r)
  r = r or {}
  r.x = r.x or 0
  r.y = r.y or 0
  local w, h = term.getSize(2)
  r.w = r.w or w
  r.h = r.h or h
  local pixels = term.getPixels(r.x, r.y, r.w, r.h, true)
  if n > 0 then
    for i=1, n, 1 do
      removeFromTable(pixels, 1)
      pixels[#pixels+1] = string.char(r.color or 15):rep(r.w)
    end
  elseif n < 0 then
    for i=1, math.abs(n), 1 do
      insertIntoTable(pixels, 1, string.char(r.color or 15):rep(r.w))
      pixels[#pixels] = nil
    end
  end
  term.drawPixels(r.x, r.y, pixels)
end

function lib.scrollX(n, r)
  r = r or {}
  r.x = r.x or 0
  r.y = r.y or 0
  local w, h = term.getSize(2)
  r.w = r.w or w
  r.h = r.h or h
  local pixels = term.getPixels(r.x, r.y, r.w, r.h, true)
  local _end = string.char(r.color or 15):rep(math.abs(n))
  if n > 0 then
    for i=1, #pixels, 1 do
      pixels[i] = pixels[i]:sub(n+1) .. _end
    end
  elseif n < 0 then
    for i=1, #pixels, 1 do
      pixels[i] = _end .. pixels[i]:sub(1, n - 1)
    end
  end
  term.drawPixels(r.x, r.y, pixels)
end

function lib.text(x, y, str, wrapTo)
  local w, h = term.getSize(2)
  for c in str:gmatch(".") do
    lib.glyph(x, y, c, 0)
    x = x + 8
    if x + 8 > w then
      x = wrapTo or 0
      y = y + 16
      if y + 16 > h then
        lib.scroll(16)
        y = y - 16
      end
    end
  end
end

return lib
