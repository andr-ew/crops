local default_args = {
    flash_time = 0.2,
    blink_time = 0.2,
}
default_args.__index = default_args

local default_props = {
    x = 1,                           --x position of the component
    y = 1,                           --y position of the component
    varibright = true,
    pre_clear = function() end,
    pre_rec_stop = function() end,
    post_rec_start = function() end,
}
default_props.__index = default_props

local function PatternRecorder(args)
    args = args or {}
    setmetatable(args, default_args)

    local downtime = 0
    local lasttime = 0

    local flash = 0
    clock.run(function()
        while true do
            if pattern.rec == 1 or pattern.overdub == 1 then
                flash = 1
                crops.dirty.grid = true
                clock.sleep(args.flash_time)

                flash = 0
                crops.dirty.grid = true
                clock.sleep(args.flash_time)
            else
                flash = 0
                clock.sleep(args.flash_time)
            end
        end
    end)

    local blink = 0
    local bclock
    local function do_blink()
        clock.sleep(args.blink_time)

        blink = 0
        crops.dirty.grid = true
    end

    return function(props)
        local pattern = props.pattern

        if crops.mode == 'input' and (pattern.rec == 1 or pattern.overdub == 1) then
            blink = 1
            crops.dirty.grid = true

            if bclock then clock.cancel(bclock) end
            bclock = clock.run(do_blink)
        end

        if crops.device == 'grid' then
            setmetatable(props, default_props)

            if crops.mode == 'input' then
                local x, y, z = table.unpack(crops.args)

                if x == props.x and y == props.y then
                    if z==1 then
                        downtime = util.time()
                    else
                        local theld = util.time() - downtime
                        local tlast = util.time() - lasttime
                        
                        if theld > 0.5 then --hold to clear
                            pattern:stop()
                            props.pre_clear()
                            pattern:clear()
                        else
                            if pattern.data.count > 0 then
                                if tlast < 0.3 then --double-tap to overdub
                                    pattern:resume()
                                    pattern:set_overdub(1)
                                    props.post_rec_start()
                                else
                                    if pattern.rec == 1 then --play pattern / stop inital recording
                                        props.pre_rec_stop()
                                        pattern:rec_stop()
                                        pattern:start()
                                    elseif pattern.overdub == 1 then --stop overdub
                                        props.pre_rec_stop()
                                        pattern:set_overdub(0)
                                    else
                                        if pattern.play == 0 then --resume pattern
                                            pattern:resume()
                                        elseif pattern.play == 1 then --pause pattern
                                            pattern:stop() 
                                        end
                                    end
                                end
                            else
                                if pattern.rec == 0 then --begin initial recording
                                    pattern:rec_start()
                                    props.post_rec_start()
                                else
                                    pattern:rec_stop()
                                end
                            end
                        end

                        crops.dirty.grid = true
                        lasttime = util.time()
                    end
                end
            elseif crops.mode == 'redraw' then
                local g = crops.handler

                local lvl
                do
                    local off = 0
                    local dim = (props.varibright == false) and 0 or 4
                    local med = (props.varibright == false) and 15 or 4
                    local medhi = (props.varibright == false) and 15 or 8 
                    local hi = 15

                    local empty = 0
                    -- local armed = ({ off, med })[flash + 1]
                    local armed = ({ off, med })[flash + 1]
                    local recording = ({ off, medhi })[blink + 1]
                    local playing = hi
                    local paused = dim
                    local overdubbing = ({ dim, hi })[flash + 1]

                    lvl = (
                        pattern.rec==1 and (pattern.data.count>0 and recording or armed)
                        or (
                            pattern.data.count>0 and (
                                pattern.overdub==1 and overdubbing
                                or pattern.play==1 and playing
                                or paused
                            ) or empty
                        )
                    )
                end

                if lvl>0 then g:led(props.x, props.y, lvl) end
            end
        end
    end
end

return PatternRecorder
