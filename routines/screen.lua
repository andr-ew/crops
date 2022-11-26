local _screen = {}

--text. display a single string.
do
    local defaults = {
        text = 'abc',            --string to display
        x = 10,                  --x position
        y = 10,                  --y position
        font_face = 1,           --font face
        font_size = 8,           --font size
        level = 15,              --brightness level, 0-15
        flow = 'right',          --direction for text to flow: 'left', 'right'
    }
    defaults.__index = defaults

    function _screen.text(props)
        if crops.device == 'screen' then
            setmetatable(props, defaults)

            if crops.mode == 'redraw' then
                screen.font_face(props.font_face)
                screen.font_size(props.font_size)
                screen.level(props.level)
                screen.move(props.x, props.y)

                if props.flow == 'left' then screen.text_right(props.text)
                else screen.text(props.text) end
            end
        end
    end
end

--list. display a table of strings with 1-2 brightness levels using the focus prop. non-numeric keys are displayed with values
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
        flow = 'right',          --direction of list to flow: 'up', 'down', 'left', 'right'
        font_headroom = 3/8,     --used to calculate height of letters. might need to adjust for non-default fonts
        -- font_leftroom = 1/16,
    }
    defaults.__index = defaults

    function _screen.list(props)
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

return _screen
