include 'lib/core'
_grid = include 'lib/routines/grid'

g = grid.connect()

local function App()
    local mom = 0
    local trig = 0
    local tog = 0
    
    return function()
        _grid.momentary{
            x = 2, 
            y = 2,
            level = { 4, 15 },
            state = { 
                mom, 
                function(v) 
                    mom = v 
                    print('momentary', mom)
                end
            },
        }

        _grid.trigger{
            x = 2,
            y = 4,
            level = { 4, 15 },
            state = { 
                trig, 
                function(v) 
                    trig = v 
                    if trig>0 then print('trigger') end
                end 
            },
        }
        
        _grid.toggle{
            x = 2,
            y = 6,
            level = { 4, 15 },
            state = { 
                tog, 
                function(v) 
                    tog = v 
                    print('toggle', tog)
                end 
            },
        }

        _grid.fills{
            x = 9,
            y = 4,
            level = 15,
            size = 6,
            wrap = 4,
            flow = 'right',
            flow_wrap = 'down',
            padding = 0
        }
    end
end

local _app = App()

crops.connect_grid(_app, g)
