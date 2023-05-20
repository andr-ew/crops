# crops (alpha)

a functional UI component system for monome norns (+ grid/arc) based on closures.

**🚧 DOCS UNDER CONSTRUCTION 🚧**

## anatomy of a garden

```
include 'lib/crops/core'
Some_component = include 'lib/my_components/some_component'

local funtion My_component()
    local value = 1
    local _render_component = Some_component()

    return function()
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
end

local _render_loop = My_component()
crops.connect_some_device(_render_loop)
```
