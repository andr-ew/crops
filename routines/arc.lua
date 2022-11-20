-- input & output UI routines for the arc

local _arc = {}

--utility: loop over a range of leds on the arc using a for loop
local function ring_range(x1, x2)
    local i, x = 0, x1 - 1
    if x2 <= x1 then x2 = x2 + 64 - 1 end

    return function()
        if x <= x2 then
            i = i + 1; x = x + 1
            return i, (x - 1) % 64 + 1
        end
    end
end

-- fill. display a set brightness level over a range of keys
do
    local defaults = {
        n = 1,                      --ring index, 1-4 
        x = { 33, 32 },             --start & endpoint led indices. table of 2 ints 1-64
        level = 15,                 --brightness level, 0-15
    }
    defaults.__index = defaults

    function _arc.fill(props)
        if crops.device == 'arc' then
            setmetatable(props, defaults)

            if crops.mode == 'redraw' then
                local a = crops.handler

                if props.level > 0 then
                    for i, x in ring_range(props.x[1], props.x[2]) do
                        a:led(props.n, x, props.level)
                    end
                end
            end
        end
    end
end

--delta. pass encoder deltas to the input callback
do
    local defaults = {
        n = 1,                      --ring index, 1-4
        input = function(d) end,    --input callback, passes delta on any input
    }
    defaults.__index = defaults

    function _arc.delta(props)
        if crops.device == 'arc' then
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

-- number. a decimal controlled by arc roatation, one full rotation of of the indicator is equal to the value of cycle. the range of value may be finite or infinite (math.huge).
do
    local defaults = {
        state = {0},
        n = 1,                      --ring index, 1-4
        x = { 33, 33 },             --start & endpoint led indices. table of 2 ints 1-64
        levels = { 0, 15 },         --brightness levels, table of two ints 0-15
        min = 0,                    --min of value
        max = 1,                    --max of value
        wrap = false,               --wrap value around min/max
        cycle = 1.0,                --the amount that value will be incrimented after a full cycle
        sensitivity = 1/64,         --input sensitivity / incriment for each enc delta
        indicator = 1               --width of led indicator displayed
    }
    defaults.__index = defaults

    function _arc.number(props)
        if crops.device == 'arc' then
            setmetatable(props, defaults)

            if crops.mode == 'input' then
                local n, d = table.unpack(crops.args)

                if n == props.n then
                    local old = crops.get_state(props.state) or 0
                    local v = old + (d * props.sensitivity)

                    if props.wrap then
                        while v > props.max do v = v - (props.max - props.min) end
                        while v < props.min do v = v + (props.max - props.min) end
                    end

                    v = util.clamp(v, props.min, props.max)
                    if old ~= v then
                        crops.dirty.arc = true
                        crops.set_state(props.state, v)
                    end
                end
            elseif crops.mode == 'redraw' then
                local a = crops.handler
                local v = crops.get_state(props.state)

                local range = props.x[2] - props.x[1] + 1
                if props.x[1] >= props.x[2] then range = 64 + range - 1 end

                local _, remainder, mod = math.modf(v / props.cycle)

                if v == 0 then mod = 0
                elseif remainder == 0 then mod = props.cycle
                else mod = v % props.cycle end

                local scale = math.floor(mod * range) + 1
                for i, x in ring_range(props.x[1], props.x[2]) do
                    local lvl = props.levels[
                        (i >= scale and i <= scale + props.indicator - 1) and 2 or 1
                    ]
                    if lvl>0 then a:led(props.n, x, lvl) end
                end
            end
        end
    end
end

return _arc
