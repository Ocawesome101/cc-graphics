-- require() this file, returns function to load from string
-- characters will be located at font.chars[ch] in output
-- bitmap rows may not be as wide as the entire character,
--  but the bitmap will be the same height as the character

local function string_split_word(text)
    local spat, epat, buf, quoted = [=[^(['"])]=], [=[(['"])$]=]
    local retval = {}
    for str in text:gmatch("%S+") do
        local squoted = str:match(spat)
        local equoted = str:match(epat)
        local escaped = str:match([=[(\*)['"]$]=])
        if squoted and not quoted and not equoted then
            buf, quoted = str, squoted
        elseif buf and equoted == quoted and #escaped % 2 == 0 then
            str, buf, quoted = buf .. ' ' .. str, nil, nil
        elseif buf then
            buf = buf .. ' ' .. str
        end
        if not buf then table.insert(retval, (str:gsub(spat,""):gsub(epat,""))) end
    end
    return retval
end

local function foreach(func, ...)
    local retval = {}
    for k,v in pairs({...}) do retval[k] = func(v) end
    return table.unpack(retval)
end

local function parseValue(str) 
    local ok, res = pcall(load("return " .. string.gsub(str, "`", "")))
    if not ok then return str else return res end
end

local function parseLine(str)
    local tok = string_split_word(str)
    return table.remove(tok, 1), foreach(parseValue, table.unpack(tok))
end

local propertymap = {
    FOUNDRY = "foundry",
    FAMILY_NAME = "family",
    WEIGHT_NAME = "weight",
    SLANT = "slant",
    SETWIDTH_NAME = "weight_name",
    ADD_STYLE_NAME = "add_style_name",
    PIXEL_SIZE = "pixels",
    POINT_SIZE = "points",
    SPACING = "spacing",
    AVERAGE_WIDTH = "average_width",
    FONT_NAME = "name",
    FACE_NAME = "face_name",
    COPYRIGHT = "copyright",
    FONT_VERSION = "version",
    FONT_ASCENT = "ascent",
    FONT_DESCENT = "descent",
    UNDERLINE_POSITION = "underline_position",
    UNDERLINE_THICKNESS = "underline_thickness",
    X_HEIGHT = "height_x",
    CAP_HEIGHT = "height_cap",
    RAW_ASCENT = "raw_ascent",
    RAW_DESCENT = "raw_descent",
    NORM_SPACE = "normal_space",
    RELATIVE_WEIGHT = "relative_weight",
    RELATIVE_SETWIDTH = "relative_setwidth",
    FIGURE_WIDTH = "figure_width",
    AVG_LOWERCASE_WIDTH = "average_lower_width",
    AVG_UPPERCASE_WIDTH = "average_upper_width"
}

local function ffs(value)
    if value == 0 then return 0 end
    local pos = 0;
    while bit32.band(value, 1) == 0 do
        value = bit32.rshift(value, 1);
        pos = pos + 1
    end
    return pos
end

local function readBDFFont(str)
    local retval = {comments = {}, resolution = {}, superscript = {}, subscript = {}, charset = {}, chars = {}}
    local mode = 0
    local ch
    local charname
    local chl = 1
    for line in str:gmatch("[^\n]+") do
        local values = {parseLine(line)}
        local key = table.remove(values, 1)
        if mode == 0 then
            if (key ~= "STARTFONT" or values[1] ~= 2.1) then
                error("Attempted to load invalid BDF font", 2)
            else mode = 1 end
        elseif mode == 1 then
            if key == "FONT" then retval.id = values[1]
            elseif key == "SIZE" then retval.size = {px = values[1], x_dpi = values[2], y_dpi = values[3]}
            elseif key == "FONTBOUNDINGBOX" then retval.bounds = {x = values[3], y = values[4], width = values[1], height = values[2]}
            elseif key == "COMMENT" then table.insert(retval.comments, values[1])
            elseif key == "ENDFONT" then return retval
            elseif key == "STARTCHAR" then 
                mode = 3
                charname = values[1]
            elseif key == "STARTPROPERTIES" then mode = 2 end
        elseif mode == 2 then
            if propertymap[key] ~= nil then retval[propertymap[key]] = values[1]
            elseif key == "RESOLUTION_X" then retval.resolution.x = values[1]
            elseif key == "RESOLUTION_Y" then retval.resolution.y = values[1]
            elseif key == "CHARSET_REGISTRY" then retval.charset.registry = values[1]
            elseif key == "CHARSET_ENCODING" then retval.charset.encoding = values[1]
            elseif key == "FONTNAME_REGISTRY" then retval.charset.fontname_registry = values[1]
            elseif key == "CHARSET_COLLECTIONS" then retval.charset.collections = string_split_word(values[1])
            elseif key == "SUPERSCRIPT_X" then retval.superscript.x = values[1]
            elseif key == "SUPERSCRIPT_Y" then retval.superscript.y = values[1]
            elseif key == "SUPERSCRIPT_SIZE" then retval.superscript.size = values[1]
            elseif key == "SUBSCRIPT_X" then retval.subscript.x = values[1]
            elseif key == "SUBSCRIPT_Y" then retval.subscript.y = values[1]
            elseif key == "SUBSCRIPT_SIZE" then retval.subscript.size = values[1]
            elseif key == "ENDPROPERTIES" then mode = 1 end
        elseif mode == 3 then
            if ch ~= nil then
                if charname ~= nil then
                    retval.chars[ch].name = charname
                    charname = nil
                end
                if key == "SWIDTH" then retval.chars[ch].scalable_width = {x = values[1], y = values[2]}
                elseif key == "DWIDTH" then retval.chars[ch].device_width = {x = values[1], y = values[2]}
                elseif key == "BBX" then 
                    retval.chars[ch].bounds = {x = values[3], y = values[4], width = values[1], height = values[2]}
                    retval.chars[ch].bitmap = {}
                    for y = 1, values[2] do retval.chars[ch].bitmap[y] = {} end
                elseif key == "BITMAP" then 
                    mode = 4 
                end
            elseif key == "ENCODING" then 
                ch = values[1] <= 255 and string.char(values[1]) or values[1]
                retval.chars[ch] = {}
            end
        elseif mode == 4 then
            if key == "ENDCHAR" then 
                ch = nil
                chl = 1
                mode = 1 
            else
                local num = tonumber("0x" .. key)
                --if type(num) ~= "number" then print("Bad number: 0x" .. num) end
                local l = {}
                local w = math.ceil(math.floor(math.log(num) / math.log(2)) / 8) * 8
                for i = ffs(num) or 0, w do l[w-i+1] = bit32.band(bit32.rshift(num, i-1), 1) == 1 end
                retval.chars[ch].bitmap[chl] = l
                chl = chl + 1
            end
        end
    end
    return retval
end

return readBDFFont
