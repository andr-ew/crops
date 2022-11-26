-- input routines for norns leys

local _key = {}

-- momentary. value is high while key is held.
do
    --default values for every valid prop.
    local defaults = {
        state = {0},
        n = 2,                   --key index, 1-3
        input = function(z) end, --input callback, passes key held state on any input
    }
    defaults.__index = defaults

    function _key.momentary(props)
        if crops.device == 'key' then 
            setmetatable(props, defaults) 

            if crops.mode == 'input' then 
                local n, z = table.unpack(crops.args) 

                if n == props.n then
                    props.input(z) 

                    local v = z 
                    crops.set_state(props.state, v) 
                end
            end
        end
    end
end

-- trigger. value is pinged on keypress for time `t`
do
    local defaults = {
        state = {0},
        n = 2,                   --key index, 1-3
        t = 0.2,                 --trigger time
        edge = 'rising',         --the input edge that causes the trigger. 'rising' or 'falling'.
        input = function(z) end, --input callback, passes key held state on any input
    }
    defaults.__index = defaults

    function _key.trigger(props)
        if crops.device == 'key' then
            setmetatable(props, defaults)

            if crops.mode == 'input' then
                local n, z = table.unpack(crops.args) 

                if n == props.n then
                    props.input(z)

                    if
                        (z == 1 and props.edge == 'rising')
                        or (z == 0 and props.edge == 'falling')
                    then
                        crops.set_state(props.state, 1)

                        clock.run(function()
                            clock.sleep(props.t)
                            crops.set_state(props.state, 0)
                        end)
                    end
                end
            end
        end
    end
end

--toggle. value cycles 0-1 on keypress.
do
    local defaults = {
        state = {0},
        n = 2,                   --key index, 1-3
        edge = 'rising',         --the input edge that causes the trigger. 'rising' or 'falling'.
        input = function(z) end, --input callback, passes key held state on any input
    }
    defaults.__index = defaults

    function _key.toggle(props)
        if crops.device == 'key' then
            setmetatable(props, defaults)

            if crops.mode == 'input' then
                local n, z = table.unpack(crops.args) 

                if n == props.n then
                    props.input(z)

                    if
                        (z == 1 and props.edge == 'rising')
                        or (z == 0 and props.edge == 'falling')
                    then
                        local v = crops.get_state(props.state) or 0
                        v = v ~ 1

                        crops.set_state(props.state, v)
                    end
                end
            end
        end
    end
end

--number. integer number.
do
    local defaults = {
        state = {1},
        n_next = 2,                 --key index, 1-3. incriments value
        n_prev = nil,               --key index, 1-3. decriments value
        min = 1,                    --min value
        max = 4,                    --max value
        wrap = true,                --wrap value around min/max
        edge = 'rising',            --the input edge that causes the trigger. 'rising' or 'falling'.
        input = function(n, z) end, --input callback, passes key held state on any input
    }
    defaults.__index = defaults

    function _key.number(props)
        if crops.device == 'key' then
            setmetatable(props, defaults)

            if crops.mode == 'input' then
                local n, z = table.unpack(crops.args) 
                local nxt, prev = n == props.n_next, n == props.n_prev

                if nxt or prev then
                    props.input(n, z)

                    if
                        (z == 1 and props.edge == 'rising')
                        or (z == 0 and props.edge == 'falling')
                    then
                        local old = crops.get_state(props.state) or 0
                        local v = old + (nxt and 1 or -1)

                        if props.wrap then
                            while v > props.max do v = v - (props.max - props.min + 1) end
                            while v < props.min do v = v + (props.max - props.min + 1) end
                        end
     
                        v = util.clamp(v, props.min, props.max)
                        if old ~= v then
                            crops.set_state(props.state, v)
                        end
                    end
                end
            end
        end
    end
end
--momentaries.
--toggles.

return _key
