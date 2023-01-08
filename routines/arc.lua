-- input & output UI routines for the arc

local _arc = {}

--utility: iterate over a range of leds on the arc using a for loop
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

_arc.util = {}
_arc.util.ring_range = ring_range

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

--decimal. rational/floating point number + 360 indicator. one full rotation of of the indicator is equal to the value of cycle.
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

    function _arc.decimal(props)
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
                        -- crops.dirty.arc = true
                        crops.set_state(props.state, v)
                    end
                end
            elseif crops.mode == 'redraw' then
                local a = crops.handler
                local v = crops.get_state(props.state) or 0

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

local cs = require 'controlspec'

--control. decimal mapped to a controlspec + 'fader' display
do
    local defaults = {
        state = {0},
        n = 1,                      --ring index, 1-4
        x = { 42, 24 },             --start & endpoint led indices. table of 2 ints 1-64
        levels = { 0, 4, 15 },      --brightness levels, table of three ints 0-15
                                    --    (levels: background, fill, indicator)
        sensitivity = 1,            --input sensitivity / incriment for each enc delta
        controlspec = cs.new(),     --all other properties detirmined by the controlspec
    }
    defaults.__index = defaults

    function _arc.control(props)
        if crops.device == 'arc' then
            setmetatable(props, defaults)

            if crops.mode == 'input' then
                local n, d = table.unpack(crops.args)

                if n == props.n then
                    local old = crops.get_state(props.state) or 0
                    local v = props.controlspec:unmap(old) + (
                        d * props.controlspec.quantum * props.sensitivity
                    )

                    if props.controlspec.wrap then
                        while v > 1 do v = v - 1 end
                        while v < 0 do v = v + 1 end
                    end
                    
                    v = props.controlspec:map(util.clamp(v, 0, 1))
                    if old ~= v then
                        -- crops.dirty.arc = true
                        crops.set_state(props.state, v)
                    end
                end
            elseif crops.mode == 'redraw' then
                local a = crops.handler
                local v = crops.get_state(props.state) or 0

                local range = props.x[2] - props.x[1] + 1
                if props.x[1] >= props.x[2] then range = 64 + range - 1 end

                v = math.floor(props.controlspec:unmap(v) * range) + 1
 
                for i, x in ring_range(props.x[1], props.x[2]) do
                    local l, m = 0, util.linlin(
                        1, range, props.controlspec.minval, props.controlspec.maxval, i
                    )
                    if i == v then l = 2
                    elseif i > v and m <= 0 then l = 1
                    elseif i < v and m >= 0 then l = 1 end
                    
                    local lvl = props.levels[l + 1]
                    if lvl>0 then a:led(props.n, x, lvl) end
                end
            end
        end
    end
end

--integer. an integer number + 'tab' display. fractional remainder after each delta is stored in a separate state.
do
    local defaults = {
        state = {1},
        state_remainder = {0.0},
        n = 1,                      --ring index, 1-4
        x = { 33, 33 },             --start & endpoint led indices. table of 2 ints 1-64
        levels = { 4, 15 },         --brightness levels, table of two ints 0-15
        sensitivity = 0.25,         --input sensitivity / incriment for each enc delta
        min = 1,                    --min value
        max = 4,                    --max value. # of tabs = max - min + 1
        wrap = false,               --wrap value around min/max
        size = nil,                 --number of leds in tabs. nil (auto), single value, or table
        margin = 0,                 --margin between tabs
    }
    defaults.__index = defaults

    function _arc.integer(props)
        if crops.device == 'arc' then
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
                        crops.set_state(props.state_remainder, frac)
                    end
                end
            elseif crops.mode == 'redraw' then
                local a = crops.handler
                local v = crops.get_state(props.state) or 0
                
                local count = props.x[2] - props.x[1]
                if props.x[1] >= props.x[2] then count = 64 + count end

                local options = props.max - props.min + 1
                local vr = math.floor(v)
                local margin = props.margin
                local stab = type(props.size) == 'table'
                local size = props.size or (count/options - props.margin)

                local st = 0
                for i = props.min, props.max, 1 do
                    local sel = vr == i
                    local l = sel and 2 or 1
                    local sz = (stab and size[i] or size)

                    local lvl = props.levels[l]

                    if lvl > 0 then for j = st, st + sz - 1 do
                        a:led(props.n, math.floor(j + props.x[1]) % 64, lvl)
                    end end
                    
                    st = st + sz + margin
                end
            end
        end
    end
end

return _arc
