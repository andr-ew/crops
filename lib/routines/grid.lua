-- input & output UI routines for the grid

local _grid = {}

-- momentary. value is high while key is held. good starting point for custom grid components.
do
    --default values for every valid prop.
    local defaults = {
        state = {0},
        x = 1,                   --x position of the component
        y = 1,                   --y position of the component
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
        x = 1,                   --x position of the component
        y = 1,                   --y position of the component
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
        x = 1,                   --x position of the component
        y = 1,                   --y position of the component
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
        x = 1,                   --x position of the component
        y = 1,                   --y position of the component
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

--return the x & y position of the Nth key, based on props
local function index_to_xy(props, n)
    local flow, flow_wrap = props.flow, props.flow_wrap

    local flows_along_x = (flow=='left') or (flow=='right')
    local flows_incrimentally = {
        main = (flow=='right') or (flow=='down'),
        cross = (flow_wrap=='right') or (flow_wrap=='down'),
    }
    local axis_x = flows_along_x and 'main' or 'cross'
    local axis_y = flows_along_x and 'cross' or 'main'

    local distance = n - 1 + props.padding
    local offset = {
        main = distance % props.wrap,
        cross = distance // props.wrap,
    }

    local x = flows_incrimentally[axis_x] and props.x + offset[axis_x] or props.x - offset[axis_x]
    local y = flows_incrimentally[axis_y] and props.y + offset[axis_y] or props.y - offset[axis_y]

    return x, y
end
local function xy_to_index(props, x, y)

end

-- fills. display a set brightness level (multiple keys).
do
    local defaults = {
        state = {0},
        x = 1,                   --x position of the component
        y = 1,                   --y position of the component
        level = 15,              --brightness level.
        size = 128,              --total number of keys
        wrap = 16,               --wrap to the next row/column every n keys
        flow = 'right',          --primary direction to flow: 'up', 'down', 'left', 'right'
        flow_wrap = 'down',      --direction to flow when wrapping. must be perpendicular to flow
        padding = 0,             --add blank spaces before the first key
    }
    defaults.__index = defaults

    function _grid.fills(props)
        if crops.device == 'grid' then
            setmetatable(props, defaults)

            if crops.mode == 'redraw' then
                local g = crops.handler

                local lvl = props.level

                for i = 1, props.size do
                    local x, y = index_to_xy(props, i)

                    if lvl>0 then g:led(x, y, lvl) end
                end
            end
        end
    end
end

return _grid
