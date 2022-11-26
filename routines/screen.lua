local _screen = {}

--text. display a single string.
do
    local defaults = {
        text = 'abc',
        x = 10,
        y = 10,
        font_face = 1,
        font_size = 8,
        level = 15,
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
                screen.text(props.text)
            end
        end
    end
end

--list. display a table of strings with 1-2 brightness levels using the focus prop. non-numeric keys are displayed with values
do
    local defaults = {
        text = {},
        x = 10,
        y = 10,
        font_face = 1,
        font_size = 8,
        margin = 5,
        levels = { 4, 15 },
        focus = 2,
        flow = 'right',          --primary direction to flow: 'up', 'down', 'left', 'right'
        font_headroom = 3/8,
        -- font_leftroom = 1/16,
    }
    --tsize = { x = screen.text_extents(txt), y = etc.font_size * (1 - etc.font_headroom) }

end


return _screen
