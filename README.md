# crops (alpha)

functional UI component system for norns/grid/arcs

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

function init()
    crops.connect_some_device(render)
end
```
