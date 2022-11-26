local _screen = {}

--text
do
    local defaults = {
        text = 'abc',
        x = 10,
        y = 10,
        font_face = 1,
        font_size = 8,
        level = 15,
    }
end

--list
do
    local defaults = {
        text = {},
        x = 10,
        y = 10,
        font_face = 1,
        font_size = 8,
        margin = 5,
        levels = { 4, 15 },
        focus = nil,
        flow = 'right',          --primary direction to flow: 'up', 'down', 'left', 'right'
        font_headroom = 3/8,
        font_leftroom = 1/16,
    }
    --tsize = { x = screen.text_extents(txt), y = etc.font_size * (1 - etc.font_headroom) }

end


return _screen
