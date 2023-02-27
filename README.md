# crops (alpha)

functional UI component system for monome norns (+ grid/arc)

**🚧 DOCS UNDER CONSTRUCTION 🚧**

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
                crops.dirty.some_device = true
                
                do_something_with(value)
            end,
        }
    }
end

crops.connect_some_device(render)
```
