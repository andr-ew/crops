-- input routines for norns encoders

local _enc = {}

--delta. pass encoder deltas to the input callback
do
    local defaults = {
        n = 1,                      --enc index, 1-3(/4)
        input = function(d) end,    --input callback, passes delta on any input
    }
    defaults.__index = defaults

    function _enc.delta(props)
        if crops.device == 'enc' then
            setmetatable(props, defaults)

            if crops.mode == 'input' then
                local n, d = table.unpack(crops.args)

                if n == props.n then
                    props.input(d)
                end
            end
        end
    end
end

--decimal. any rational/floating point number.
do
    local defaults = {
        state = {0},
        n = 1,                      --enc index, 1-3(/4)
        sensitivity = 0.01,         --input sensitivity / incriment for each enc delta
        min = 0,                    --min value
        max = 1,                    --max value
        wrap = false,               --wrap value around min/max
    }
    defaults.__index = defaults

    function _enc.decimal(props)
        if crops.device == 'enc' then
            setmetatable(props, defaults)

            if crops.mode == 'input' then
                local n, d = table.unpack(crops.args)

                if n == props.n then
                    local old = crops.get_state(props.state) or 1
                    local v = old + (d * props.sensitivity)
                    local min = props.min
                    local max = props.max + 1 - props.sensitivity

                    if props.wrap then
                        while v > max do v = v - (max - min) end
                        while v < min do v = v + (max - min) end
                    end
 
                    v = util.clamp(v, min, max)
                    if old ~= v then
                        crops.set_state(props.state, v)
                    end
                end
            end
        end
    end
end

--integer. state is an integer number. fractional remainder after each delta is stored in a separate state.
do
    local defaults = {
        state = {1},
        state_remainder = {0.0},
        n = 1,                      --enc index, 1-3(/4)
        sensitivity = 0.5,          --input sensitivity / incriment for each enc delta
        min = 1,                    --min value
        max = 4,                    --max value
        wrap = false,               --wrap value around min/max
    }
    defaults.__index = defaults

    function _enc.integer(props)
        if crops.device == 'enc' then
            setmetatable(props, defaults)

            if crops.mode == 'input' then
                local n, d = table.unpack(crops.args)

                if n == props.n then
                    local old = math.floor(crops.get_state(props.state) or 1)
                                + (crops.get_state(props.state_remainder) or 0) 

                    local v = old + (d * props.sensitivity)
                    local min = props.min
                    local max = props.max + 1 - props.sensitivity

                    if props.wrap then
                        while v > max do v = v - (max - min) end
                        while v < min do v = v + (max - min) end
                    end
 
                    v = util.clamp(v, min, max)
                    if old ~= v then
                        local int, frac = math.modf(v)

                        crops.set_state(props.state, int)
                        crops.set_state(props.state_remainder, int)
                    end
                end
            end
        end
    end
end

local cs = require 'controlspec'

--control. decimal mapped to a controlspec.
do
    local defaults = {
        state = {0},
        n = 1,                      --enc index, 1-3(/4)
        controlspec = cs.new(),     --all other properties detirmined by the controlspec
    }
    defaults.__index = defaults

    function _enc.control(props)
        if crops.device == 'enc' then
            setmetatable(props, defaults)

            if crops.mode == 'input' then
                local n, d = table.unpack(crops.args)

                if n == props.n then
                    local old = crops.get_state(props.state) or 0
                    local v = props.controlspec:unmap(old) + (d * props.controlspec.quantum)

                    if props.controlspec.wrap then
                        while v > 1 do v = v - 1 end
                        while v < 0 do v = v + 1 end
                    end
                    
                    v = props.controlspec:map(util.clamp(v, 0, 1))
                    if old ~= v then
                        crops.set_state(props.state, v)
                    end
                end
            end
        end
    end
end

return _enc
