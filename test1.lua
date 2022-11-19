include 'lib/core'
_grid = include 'lib/routines/grid'

g = grid.connect()

local function App()
    local mom = 0
    local trig = 0
    local tog = 0

    local num = 1
    local moms = {}
    local togs = {}
    
    return function()
        _grid.momentary{
            x = 2, 
            y = 3,
            levels = { 4, 15 },
            state = { 
                mom, 
                function(v) 
                    mom = v 
                    print('momentary', mom)
                end
            },
        }

        _grid.toggle{
            x = 2,
            y = 5,
            levels = { 4, 15 },
            edge = 'rising',
            state = { 
                tog, 
                function(v) 
                    tog = v 
                    print('toggle', tog)
                end 
            },
        }

        _grid.trigger{
            x = 2,
            y = 7,
            levels = { 4, 15 },
            state = { 
                trig, 
                function(v) 
                    trig = v 
                    if trig>0 then print('trigger') end
                end 
            },
        }
        
        _grid.number{
            x = 4,
            y = 1,
            edge = 'rising',
            levels = { 4, 15 },
            state = { 
                num, 
                function(v) 
                    num = v 
                    print('number', num)
                end
            },
            size = 7,
            wrap = nil,
            flow = 'right',
            flow_wrap = 'down',
            padding = 0
        }

        _grid.momentaries{
            x = 4,
            y = 3,
            levels = { 4, 15 },
            state = { 
                moms, 
                function(v) 
                    moms = v 
                    print('momentaries')
                    tab.print(moms)
                end
            },
            size = 7,
            wrap = nil,
            flow = 'right',
            flow_wrap = 'down',
            padding = 0
        }

        _grid.toggles{
            x = 4,
            y = 5,
            levels = { 4, 15 },
            edge = 'rising',
            state = { 
                togs, 
                function(v) 
                    togs = v 
                    print('toggles')
                    tab.print(togs)
                end
            },
            size = 7,
            wrap = nil,
            flow = 'right',
            flow_wrap = 'down',
            padding = 0
        }
    end
end

local _app = App()

crops.connect_grid(_app, g)
