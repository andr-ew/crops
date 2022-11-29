# crops

functional UI component system for norns/grid/arcs

**🚧 UNDER CONSTRUCTION 🚧**

## anatomy of a garden

```
include 'lib/crops/core'
_some_routine = include 'lib/my_routines/some_routine'

local value = 1

local function render()
    _some_routine{
        some_prop = 7,
        state = { 
            value, 
            function(v) 
                value = v 
                crops.some_device.dirty = true
                do_something_with(value)
            end,
        }
    }
end

crops.connect_some_device(render)
```
