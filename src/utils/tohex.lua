local final = ""
for line in io.lines() do
  io.stderr:write(line.."\n")
  local value = 0
  local n = 0
  for c in line:gmatch(".") do
    if c ~= " " then
      value = value | 2^(7 - n)
    end
    n = n + 1
  end
  final = final .. string.format("%02x", value)
end
print(final)
