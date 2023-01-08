-- input & output UI routines for the grid

local _grid = {}

-- momentary. value is high while key is held. good starting point for custom grid components.
do
    --default values for every valid prop.
    local defaults = {
        state = {0},
        x = 1,                   --x position of the component
        y = 1,                   --y position of the component
        levels = { 0, 15 },      --brightness levels. expects a table of 2 ints 0-15
        input = function(z) end, --input callback, passes key held state on any input
    }
    defaults.__index = defaults

    --momentary render routine. remember that this function will be called both when the grid accepts input and every time the grid is redrawn. the argument is a table of key/value props. note that most of this function is 'biolerplate'.
    function _grid.momentary(props)
        if crops.device == 'grid' then --if the grid device is being processed
            setmetatable(props, defaults) --use metatables to set default values in the props table

            if crops.mode == 'input' then --if processing input
                local x, y, z = table.unpack(crops.args) --assign arguments to local vars

                if x == props.x and y == props.y then --check if the input overlaps this component
                    props.input(z) --run the input callback

                    local v = z --get the current value based on input received.

                    -- crops.dirty.grid = true --set the dirty flag for grids high
                    crops.set_state(props.state, v) --set the value using the state prop
                end
            elseif crops.mode == 'redraw' then --if drawing the device output
                local g = crops.handler --assign the device handler to a local var
                local v = crops.get_state(props.state) or 0 --get the value from the state prop

                local lvl = props.levels[v + 1] --get the correct brightness based on the level prop

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
        levels = { 0, 15 },      --brightness levels. expects a table of 2 ints 0-15
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
                        -- crops.dirty.grid = true
                        crops.set_state(props.state, 1)

                        clock.run(function()
                            clock.sleep(props.t)
                            -- crops.dirty.grid = true
                            crops.set_state(props.state, 0)
                        end)
                    end
                end
            elseif crops.mode == 'redraw' then
                local g = crops.handler
                local v = crops.get_state(props.state) or 0

                local lvl = props.levels[v + 1]

                if lvl>0 then g:led(props.x, props.y, lvl) end
            end
        end
    end
end

-- toggle. value cycles forward from 0-n on keypress. set number of levels with `levels`.
do
    local defaults = {
        state = {0},
        x = 1,                   --x position of the component
        y = 1,                   --y position of the component
        levels = { 0, 15 },      --brightness levels. 
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
                        local v = crops.get_state(props.state) or 0
                        v = (v + 1) % #props.levels

                        -- crops.dirty.grid = true
                        crops.set_state(props.state, v)
                    end
                end
            elseif crops.mode == 'redraw' then
                local g = crops.handler
                local v = crops.get_state(props.state)

                local lvl = props.levels[v + 1]

                if lvl>0 then g:led(props.x, props.y, lvl) end
            end
        end
    end
end

-- fill. display a set brightness level.
do
    local defaults = {
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

--utility: return the x & y position of the Nth key, based on wrap & flow props
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

--utility: return the index of the key, based on x & y position + wrap & flow props. returns nil when out of bounds
local function xy_to_index(props, x, y)
    local flow, flow_wrap = props.flow, props.flow_wrap

    local flows_along_x = (flow=='left') or (flow=='right')
    local flows_incrimentally = {
        main = (flow=='right') or (flow=='down'),
        cross = (flow_wrap=='right') or (flow_wrap=='down'),
    }
    local axis_x = flows_along_x and 'main' or 'cross'
    local axis_y = flows_along_x and 'cross' or 'main'

    local offset = {}  
    offset[axis_x] = x - props.x
    offset[axis_y] = y - props.y

    local in_quad = {
        main = (
            (flows_incrimentally.main and offset.main >= 0)
            or (not flows_incrimentally.main and offset.main <= 0)
        ),
        cross = (
            (flows_incrimentally.cross and offset.cross >= 0)
            or (not flows_incrimentally.cross and offset.cross <= 0)
        ),
    }

    if in_quad.main and in_quad.cross and math.abs(offset.main) < props.wrap then
        local n = (math.abs(offset.cross) * props.wrap) + math.abs(offset.main) + 1 - props.padding

        if n > 0 and n <= props.size then
            return n
        end
    end
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

-- integer. select an integer number 1-`size` across `size` keys.
do
    --default values for every valid prop.
    local defaults = {
        state = {1},
        x = 1,                      --x position of the component
        y = 1,                      --y position of the component
        edge = 'rising',            --input edge sensitivity. 'rising' or 'falling'.
        input = function(n, z) end, --input callback, passes last key state on any input
        levels = { 0, 15 },         --brightness levels. expects a table of 2 ints 0-15
        size = 128,                 --total number of keys
        wrap = 16,                  --wrap to the next row/column every n keys
        flow = 'right',             --primary direction to flow: 'up', 'down', 'left', 'right'
        flow_wrap = 'down',         --direction to flow when wrapping. must be perpendicular to flow
        padding = 0,                --add blank spaces before the first key
    }
    defaults.__index = defaults

    function _grid.integer(props)
        if crops.device == 'grid' then 
            setmetatable(props, defaults) 

            if crops.mode == 'input' then 
                local x, y, z = table.unpack(crops.args) 
                local n = xy_to_index(props, x, y)

                if n then 
                    props.input(n, z)

                    if
                        (z == 1 and props.edge == 'rising')
                        or (z == 0 and props.edge == 'falling')
                    then
                        local v = n

                        -- crops.dirty.grid = true 
                        crops.set_state(props.state, v) 
                    end
                end
            elseif crops.mode == 'redraw' then 
                local g = crops.handler 

                local v = crops.get_state(props.state)
                for i = 1, props.size do
                    local lvl = props.levels[(i == v) and 2 or 1] 

                    local x, y = index_to_xy(props, i)

                    if lvl>0 then g:led(x, y, lvl) end
                end
            end
        end
    end
end

-- momentaries. values are high while key is held (multiple keys).
do
    --default values for every valid prop.
    local defaults = {
        state = {{}},
        x = 1,                      --x position of the component
        y = 1,                      --y position of the component
        levels = { 0, 15 },         --brightness levels. expects a table of 2 ints 0-15
        input = function(n, z) end, --input callback, passes last key state on any input
        size = 128,                 --total number of keys
        wrap = 16,                  --wrap to the next row/column every n keys
        flow = 'right',             --primary direction to flow: 'up', 'down', 'left', 'right'
        flow_wrap = 'down',         --direction to flow when wrapping. must be perpendicular to flow
        padding = 0,                --add blank spaces before the first key
    }
    defaults.__index = defaults

    function _grid.momentaries(props)
        if crops.device == 'grid' then 
            setmetatable(props, defaults) 

            if crops.mode == 'input' then 
                local x, y, z = table.unpack(crops.args) 
                local n = xy_to_index(props, x, y)

                if n then 
                    props.input(n, z)

                    local v = z

                    -- crops.dirty.grid = true 
                    crops.set_state_at(props.state, n, v) 
                end
            elseif crops.mode == 'redraw' then 
                local g = crops.handler 

                for i = 1, props.size do
                    local v = crops.get_state_at(props.state, i) or 0
                    local lvl = props.levels[v + 1] 

                    local x, y = index_to_xy(props, i)

                    if lvl>0 then g:led(x, y, lvl) end
                end
            end
        end
    end
end

--toggles. values cycle forward from 0-n on keypress. set number of levels with `levels` (multiple keys).
do
    --default values for every valid prop.
    local defaults = {
        state = {{}},
        x = 1,                   --x position of the component
        y = 1,                   --y position of the component
        levels = { 0, 15 },      --brightness levels. 
                                 --    will cycle forward to the next level on each keypress .
                                 --    length can be 2 or more.
        edge = 'rising',         --the input edge that causes the toggle. 'rising' or 'falling'.
        input = function(z) end, --input callback, passes key held state on any input
        size = 128,              --total number of keys
        wrap = 16,               --wrap to the next row/column every n keys
        flow = 'right',          --primary direction to flow: 'up', 'down', 'left', 'right'
        flow_wrap = 'down',      --direction to flow when wrapping. must be perpendicular to flow
        padding = 0,             --add blank spaces before the first key
    }
    defaults.__index = defaults

    function _grid.toggles(props)
        if crops.device == 'grid' then 
            setmetatable(props, defaults) 

            if crops.mode == 'input' then 
                local x, y, z = table.unpack(crops.args) 
                local n = xy_to_index(props, x, y)

                if n then 
                    if
                        (z == 1 and props.edge == 'rising')
                        or (z == 0 and props.edge == 'falling')
                    then
                        local v = crops.get_state_at(props.state, n) or 0
                        v = (v + 1) % #props.levels

                        -- crops.dirty.grid = true 
                        crops.set_state_at(props.state, n, v) 
                    end
                end
            elseif crops.mode == 'redraw' then 
                local g = crops.handler 

                for i = 1, props.size do
                    local v = crops.get_state_at(props.state, i) or 0
                    local lvl = props.levels[v + 1] 

                    local x, y = index_to_xy(props, i)

                    if lvl>0 then g:led(x, y, lvl) end
                end
            end
        end
    end
end

return _grid
