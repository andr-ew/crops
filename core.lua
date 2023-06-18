-- global states & device connection functions

-- global state table. 
--     these values are updated each time crops redraws a device or receives input. 
--     render routines reference these values to know if and how to act
crops = {
    args = {},           --list of arguments from any device input callback
    device = nil,        --name of device currently being processed
    handler = nil,       --device handler, if relevant (g, a, etc)
    mode = nil,          --render mode name, either 'input' or 'redraw'
    dirty = {            --table of dirty flags for each output device
        grid = true,
        screen = true,
        arc = true,
    }
}

-- connect norns interface elements. overwrites global enc, key, redraw callbacks, respectively
crops.connect_enc = function(render)

    function enc(n, d)
        crops.args = { n, d }
        crops.device = 'enc'
        crops.handler = nil
        crops.mode = 'input'

        render()
    end

end
crops.connect_key = function(render)

    function key(n, z)
        crops.args = { n, z }
        crops.device = 'key'
        crops.handler = nil
        crops.mode = 'input'

        render()
    end

end
crops.connect_screen = function(render, fps)
    fps = fps or 30
    local name = 'screen'

    function redraw()
        -- print('crops redraw()')

        screen.clear()

        crops.args = nil
        crops.device = name
        crops.handler = nil
        crops.mode = 'redraw'
        render()

        screen.update()
    end

    local cl = clock.run(function()
        while true do
            clock.sleep(1/fps)
            if crops.dirty[name] then
                crops.dirty[name] = false
                redraw()
            end
        end
    end)

    return cl
end

-- connect a grid device (g). overwrites g.key
crops.connect_grid = function(render, g, fps)
    fps = fps or 30
    local name = 'grid'
    local h = g

    h.key = function(x, y, z)
        crops.args = { x, y, z }
        crops.device = name
        crops.handler = h
        crops.mode = 'input'
        render()
    end

    local redraw_device = function()
        h:all(0)

        crops.args = nil
        crops.device = name
        crops.handler = h
        crops.mode = 'redraw'
        render()

        h:refresh()
    end

    local cl = clock.run(function()
        while true do
            clock.sleep(1/fps)
            if crops.dirty[name] then
                crops.dirty[name] = false
                redraw_device()
            end
        end
    end)

    return redraw_device, cl
end

-- connect an arc device (a). overwrites g.delta
crops.connect_arc = function(render, a, fps)
    fps = fps or 120
    local name = 'arc'
    local h = a

    h.delta = function(n, d)
        crops.args = { n, d }
        crops.device = name
        crops.handler = h
        crops.mode = 'input'
        render()
    end
    h.key = function(n, z) --2011 arc encoder pushbutton input
        crops.args = { n, z }
        crops.device = 'arc_key'
        crops.handler = h
        crops.mode = 'input'
        render()
    end

    local redraw_device = function()
        h:all(0)

        crops.args = nil
        crops.device = name
        crops.handler = h
        crops.mode = 'redraw'
        render()

        h:refresh()
    end

    local cl = clock.run(function()
        while true do
            clock.sleep(1/fps)
            if crops.dirty[name] then
                crops.dirty[name] = false
                redraw_device()
            end
        end
    end)

    return redraw_device, cl
end

--special functions used by routines to interact with the state prop
function crops.get_state(state)
    return state[1]
end
function crops.set_state(state, value)
    local args = {} --args sent to the state setter function

    for i,v in ipairs(state) do 
        --additional values in state tab sent as args, before value
        if i > 2 then table.insert(args, v) end
    end
    table.insert(args, value)

    if state[2] then state[2](table.unpack(args)) end
end
function crops.get_state_at(state, idx)
    return state[1][idx]
end
function crops.set_state_at(state, idx, value)
    local args = {}

    for i,v in ipairs(state) do 
        if i > 2 then table.insert(args, v) end
    end

    local old = state[1]
    local new = {}
    for k,v in pairs(old) do new[k] = v end
    new[idx] = value

    table.insert(args, new)

    if state[2] then state[2](table.unpack(args)) end
end
function crops.insert_state_at(state, pos_val, value)
    local args = {}

    for i,v in ipairs(state) do 
        if i > 2 then table.insert(args, v) end
    end

    local old = state[1]
    local new = {}
    for k,v in pairs(old) do new[k] = v end
    if value then
        table.insert(new, pos_val, value)
    else
        table.insert(new, pos_val)
    end

    table.insert(args, new)

    if state[2] then state[2](table.unpack(args)) end
end
function crops.remove_state_at(state, pos)
    local args = {}

    for i,v in ipairs(state) do 
        if i > 2 then table.insert(args, v) end
    end

    local old = state[1]
    local new = {}
    for k,v in pairs(old) do new[k] = v end
    table.remove(new, pos)

    table.insert(args, new)

    if state[2] then state[2](table.unpack(args)) end
end
function crops.copy_state_from(state, tab)
    local args = {}

    for i,v in ipairs(state) do 
        if i > 2 then table.insert(args, v) end
    end

    local new = {}
    for k,v in pairs(tab) do new[k] = v end

    table.insert(args, new)

    if state[2] then state[2](table.unpack(args)) end
end

--globally available 'of' state macros
function crops.of_variable(...)
    return { ... }
end
function crops.of_param(id)
    return {
        params:get(id), params.set, params, id
    }
end
