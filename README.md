# crops (alpha)

functional UI component system for monome norns (+ grid/arc)

**🚧 DOCS UNDER CONSTRUCTION 🚧**

## anatomy of a garden

```
include 'lib/crops/core'
Some_component = include 'lib/my_components/some_component'

local value = 1

local _render_component = Some_component()

local function render()
    _render_component{
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
