local Screen = {}

--text. display a single string.
do
    local defaults = {
        text = 'abc',            --string to display
        x = 10,                  --x position
        y = 10,                  --y position
        font_face = 1,           --font face
        font_size = 8,           --font size
        level = 15,              --brightness level, 0-15
        flow = 'right',          --direction for text to flow: 'left', 'right', or 'center'
    }
    defaults.__index = defaults

    function Screen.text()
        return function(props)
            if crops.device == 'screen' then
                setmetatable(props, defaults)

                if crops.mode == 'redraw' then
                    screen.font_face(props.font_face)
                    screen.font_size(props.font_size)
                    screen.level(props.level)
                    screen.move(props.x, props.y)

                    if props.flow == 'left' then screen.text_right(props.text)
                    elseif props.flow == 'center' then screen.text_center(props.text)
                    else screen.text(props.text) end
                end
            end
        end
    end
end

--list. display a table of strings. the string with index `focus` displays the second brightness level. non-numeric keys are displayed with values
do
    local defaults = {
        text = {},               --list of strings to display. non-numeric keys are displayed as labels with thier values. (e.g. { cutoff = value })
        x = 10,                  --x position
        y = 10,                  --y position
        font_face = 1,           --font face
        font_size = 8,           --font size
        margin = 5,              --pixel space betweeen list items
        levels = { 4, 15 },      --table of 2 brightness levels, 0-15
        focus = 2,               --only this index in the resulting list will have the second brightness level. nil for no focus.
        flow = 'right',          --direction of flow: 'up', 'down', 'left', 'right'
        font_headroom = 3/8,     --used to calculate height of letters. might need to adjust for non-default fonts
        -- font_leftroom = 1/16,
    }
    defaults.__index = defaults

    function Screen.list()
        return function(props)
            if crops.device == 'screen' then
                setmetatable(props, defaults)

                if crops.mode == 'redraw' then
                    screen.font_face(props.font_face)
                    screen.font_size(props.font_size)

                    local x, y, i, flow = props.x, props.y, 1, props.flow

                    local function txt(v)
                        screen.level(props.levels[(i == props.focus) and 2 or 1])
                        screen.move(x, y)

                        if flow == 'left' then screen.text_right(v)
                        else screen.text(v) end

                        if flow == 'right' then 
                            x = x + screen.text_extents(v) + props.margin
                        elseif flow == 'left' then 
                            x = x - screen.text_extents(v) - props.margin
                        elseif flow == 'down' then 
                            y = y + (props.font_size * (1 - props.font_headroom)) + props.margin
                        elseif flow == 'up' then 
                            y = y - (props.font_size * (1 - props.font_headroom)) - props.margin
                        end

                        i = i + 1
                    end

                    if #props.text > 0 then for _,v in ipairs(props.text) do txt(v) end
                    else for k,v in pairs(props.text) do txt(k); txt(v) end end
                end
            end
        end
    end
end

local newline = [[

]]
local newline_byte = string.byte(newline)

--glyph. specify a custom glyph using a multi-line string. the `levels` table maps characters to pixel brightness level. all other characters (including spaces & tabs) are ignored.
do
    local defaults = {
        x = 10,                  --x position
        y = 10,                  --y position
        glyph = [[
            . # .
            # . #
            . # .
        ]],
        levels = { ['.'] = 0, ['#'] = 15 },
        align = 'left'
    }
    defaults.__index = defaults

    function Screen.glyph()
        return function(props)
            if crops.device == 'screen' then
                setmetatable(props, defaults)

                if crops.mode == 'redraw' then
                    local glyph_bytes = table.pack(string.byte(props.glyph, 1, -1))
                    local level_bytes = {}
                    for k,v in pairs(props.levels) do level_bytes[string.byte(k)] = v end

                    local x, y = props.x, props.y

                    if props.align == 'left' then
                        for _,byte in ipairs(glyph_bytes) do
                            if byte == newline_byte then
                                y = y + 1
                                x = props.x
                            elseif level_bytes[byte] then
                                screen.level(level_bytes[byte])
                                screen.pixel(x, y)
                                screen.fill()
                                x = x + 1
                            end
                        end
                    else
                        for i = #glyph_bytes, 1, -1 do
                            local byte = glyph_bytes[i]
                            if byte == newline_byte then
                                y = y - 1
                                x = props.x
                            elseif level_bytes[byte] then
                                screen.level(level_bytes[byte])
                                screen.pixel(x, y)
                                screen.fill()
                                x = x - 1
                            end
                        end
                    end
                end
            end
        end
    end
end

return Screen
