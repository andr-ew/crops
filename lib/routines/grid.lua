-- input & output UI routines for the grid

local _grid = {}

-- momentary. value is high while key is held. good starting point for custom grid components.
do
    --default values for every valid prop.
    local defaults = {
        state = {0},
        x = 0,                   --x position of the component
        y = 0,                   --y position of the component
        level = { 0, 15 },       --brightness levels. expects a table of 2 ints 0-15
    }
    defaults.__index = defaults

    --momentary render routine. remember that this function will be called both when the grid accepts input and every time the grid is redrawn. the argument is a table of key/value props. most of this function is 'biolerplate'.
    function _grid.momentary(props)
        if crops.device == 'grid' then --check device
            setmetatable(props, defaults) --use metatables to set default values in the props table

            if crops.mode == 'input' then --check for input mode
                local x, y, z = table.unpack(crops.args) --assign arguments to local vars

                if x == props.x and y == props.y then --check if the input overlaps this component

                    local v = z --get the current value based on input received.

                    crops.dirty.grid = true --set the dirty flag for grids high
                    crops.set_state(props.state, v) --set the value using the state prop
                end
            elseif crops.mode == 'redraw' then --check for output mode
                local g = crops.handler --assign the device handler to a local var
                local v = crops.get_state(props.state, v) --get the value from the state prop

                local lvl = props.level[v + 1] --get the correct brightness based on the level prop

                if lvl>0 then g:led(props.x, props.y, lvl) end --draw the component
            end
        end
    end
end

-- trigger. value is pinged on keypress for time `t`
do
    local defaults = {
        state = {0},
        x = 0,                   --x position of the component
        y = 0,                   --y position of the component
        level = { 0, 15 },       --brightness levels. expects a table of 2 ints 0-15
        t = 0.2,                 --trigger time
        edge = 'rising',         --the input edge that causes the trigger. 'rising' or 'falling'.
        input = function(z) end, --input callback, passes key held state on any input
    }
    defaults.__index = defaults

    function _grid.trigger(props)
        if crops.device == 'grid' then
            setmetatable(props, defaults)

            if crops.mode == 'input' then
                local x, y, z = table.unpack(crops.args)

                if x == props.x and y == props.y then
                    props.input(z)

                    if
                        (z == 1 and props.edge == 'rising')
                        or (z == 0 and props.edge == 'falling')
                    then
                        crops.dirty.grid = true
                        crops.set_state(props.state, 1)

                        clock.run(function()
                            clock.sleep(props.t)
                            crops.dirty.grid = true
                            crops.set_state(props.state, 0)
                        end)
                    end
                end
            elseif crops.mode == 'redraw' then
                local g = crops.handler
                local v = crops.get_state(props.state, v)

                local lvl = props.level[v + 1]

                if lvl>0 then g:led(props.x, props.y, lvl) end
            end
        end
    end
end

-- toggle. value cycles forward from 0-n on keypress. set number of levels with `level`.
do
    local defaults = {
        state = {0},
        x = 0,                   --x position of the component
        y = 0,                   --y position of the component
        level = { 0, 15 },       --brightness levels. 
                                 --    will cycle forward to the next level on each keypress .
                                 --    length can be 2 or more.
        edge = 'rising',         --the input edge that causes the toggle. 'rising' or 'falling'.
        input = function(z) end, --input callback, passes key held state on any input
    }
    defaults.__index = defaults

    function _grid.toggle(props)
        if crops.device == 'grid' then
            setmetatable(props, defaults)

            if crops.mode == 'input' then
                local x, y, z = table.unpack(crops.args)

                if x == props.x and y == props.y then
                    props.input(z)

                    if
                        (z == 1 and props.edge == 'rising')
                        or (z == 0 and props.edge == 'falling')
                    then
                        local v = crops.get_state(props.state, v)
                        v = (v + 1) % #props.level

                        crops.dirty.grid = true
                        crops.set_state(props.state, v)
                    end
                end
            elseif crops.mode == 'redraw' then
                local g = crops.handler
                local v = crops.get_state(props.state, v)

                local lvl = props.level[v + 1]

                if lvl>0 then g:led(props.x, props.y, lvl) end
            end
        end
    end
end

-- fill. just display a set brightness level.
do
    local defaults = {
        state = {0},
        x = 0,                   --x position of the component
        y = 0,                   --y position of the component
        level = 15               --brightness level.
    }
    defaults.__index = defaults

    function _grid.fill(props)
        if crops.device == 'grid' then
            setmetatable(props, defaults)

            if crops.mode == 'redraw' then
                local g = crops.handler

                local lvl = props.level

                if lvl>0 then g:led(props.x, props.y, lvl) end
            end
        end
    end
end

return _grid
