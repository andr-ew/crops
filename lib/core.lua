-- global states & device connection functions

-- global state table. 
--     these values are updated each time crops redraws a device or receives input. 
--     routines reference these values to know when and how to act
crops = {
    args = {},           --list of arguments from any device input callback
    device = nil,        --name of device currently being processed
    object = nil,        --device object, if relevant (g, a, etc)
    mode = nil,          --render mode name, either 'input' or 'redraw'
    dirty = {            --table of dirty flags for each output device
        grid = true,
        screen = true,
        arc = true,
    }
}

-- connect norns interface elements. overwrites global key, enc, redraw callbacks

nest.connect_enc = function(render)

    function enc(n, d)
        nest.args = { n, d }
        nest.device = 'enc'
        nest.object = nil
        nest.mode = 'input'

        render()
    end

end
nest.connect_key = function(render)

    function key(n, z)
        nest.args = { n, z }
        nest.device = 'key'
        nest.object = nil
        nest.mode = 'input'

        render()
    end

end
nest.connect_screen = function(render, fps)
    fps = fps or 30
    local name = 'screen'

    function redraw()
        screen.clear()

        nest.args = nil
        nest.device = name
        nest.object = nil
        nest.mode = 'redraw'
        render()

        screen.update()
    end

    local cl = clock.run(function()
        while true do
            clock.sleep(1/fps)
            if nest.dirty[name] then
                nest.dirty[name] = false
                redraw()
            end
        end
    end)

    return cl
end

-- connect a grid device (g). overwrites g.key
nest.connect_grid = function(render, g, fps)
    fps = fps or 30
    local name = 'grid'
    local obj = g

    obj.key = function(x, y, z)
        nest.args = { x, y, z }
        nest.device = name
        nest.object = obj
        nest.mode = 'input'
        render()
    end

    local redraw_device = function()
        obj:all(0)

        nest.args = nil
        nest.device = name
        nest.object = obj
        nest.mode = 'redraw'
        render()

        obj:refresh()
    end

    local cl = clock.run(function()
        while true do
            clock.sleep(1/fps)
            if nest.dirty[name] then
                nest.dirty[name] = false
                redraw_device()
            end
        end
    end)

    return redraw_device, cl
end

-- connect an arc device (a). overwrites g.delta
nest.connect_grid = function(render, a, fps)
    fps = fps or 120
    local name = 'arc'
    local obj = a

    obj.delta = function(n, d)
        nest.args = { n, d }
        nest.device = name
        nest.object = obj
        nest.mode = 'input'
        render()
    end
    obj.key = function(n, z) --2011 arc encoder pushbutton input
        nest.args = { n, z }
        nest.device = 'arc_key'
        nest.object = obj
        nest.mode = 'input'
        render()
    end

    local redraw_device = function()
        obj:all(0)

        nest.args = nil
        nest.device = name
        nest.object = obj
        nest.mode = 'redraw'
        render()

        obj:refresh()
    end

    local cl = clock.run(function()
        while true do
            clock.sleep(1/fps)
            if nest.dirty[name] then
                nest.dirty[name] = false
                redraw_device()
            end
        end
    end)

    return redraw_device, cl
end
