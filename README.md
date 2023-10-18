# crops (alpha)

a functional UI component system for monome norns (+ grid/arc) based on closures.

**🚧 DOCS UNDER CONSTRUCTION 🚧**
- ((examples reflect a few planned API changes that have yet to be implimented))
    - instead of `crops.grid.dirty()`, use `crops.dirty.grid = true`
    - `state` is currently required in most components. soon it will be optional.
- API reference also WIP, but code comments throughout describe most components/props/methods/etc

**TODO - genereal:**
- add gifs for examples w/ [GridCapture](https://github.com/tlubke/GridCapture)

## what is a UI component?

a UI component is an atomic piece of a user interface that is self-contained. a component can define input behavior, display behavior, or both.

the primay benefit of component-based design is reusability – a component can be used many different times, in different contexts, without modifying another part of the program. components can also be useful for separating the different concerns of your interface, and keeping larger codebases organized. the declarative, or descriptive, style of working with component libraries can also make it easier to reason about your program, and easier to change details of your interface later on, like changing the width of a slider or its brightness level.

conversely, components, as with most any kind of programming abstraction, come with a performance cost, which should be considered when deciding how to structure your program.

## what is a closure?

simply put, a [closure](https://www.lua.org/pil/6.1.html) is a function returned by another function. what might seem like a strange pattern has many powerful uses in the lua language. closures allow regular functions to continuously manipulate private, “closed in” variables. if you’ve ever used an [anonymous function] as a callback, you’ve likely already used closures without even realizing it.

## what is crops?

crops is two things. first, it's a light-weight, single file component framework, defined in a couple hundred lines of code in `core.lua`.

second, it's a library of basic components, found in `components/`, that interact with norns' keys, encoders, and screen, as well as the grid and arc. these components were designed to be both useful in basic scripts, but also easy to understand, so they can be used as starting points for creating your own custom components, which you'll learn how to do at the end of this document.

## getting started

TODO: install options
- including externally (easiest)

## crops components

in crops, a component is a closure that performs redraw and/or input logic for some device — be it grid, arc, or norns’ screen, keys, or encoders. crops ships with a number of simple, but useful, components, and you can also define your own. we can create a new instance of a component by calling its constructor function:
```
_component_function = Constructor_function{ arg = 'foo' }
```
the constructor is usually called only once, when your script first loads. a component constructor may have any number of arguments, passed as a table, and the value of these arguments cannot change.

the return value of the constructor function is the component function. after initializing, we render that component by calling the component function within a render function:
```
function render_device()
    _component_function{ prop = 'foo' }
end
```
then, the render function is passed to crops as a callback:
```
crops.connect_device(render_device, device)
```
crops calls the render function many times. in the case of the grid, it is called every time the grid receives input and when the grid is redrawn – the component closure knows which action to perform in each case. a component may be called with any number of props, passed as a table. these props may change, as they are re-defined each time the render function is called.

note the naming convention – the constructor function is `Capitalized`, and the component function is preceded by an `_underscore`. this convention is completely optional, but we’ll be using it throughout these examples.

## follow along

TODO: link to a maiden-installable repo with scripts for the examles in each section

## using components
```
engine.name = 'PolySub'

g = grid.connect()

_toggle = Grid.toggle()

column = 1

function gate(value)
    local id, hz = 1, 440

    if gate == 1 then
        engine.start(id, hz)
    elseif gate == 0 then
        engine.stop(id)
    end
end

function render_grid()
    _toggle{
        x = column,
        y = 1,
        levels = { 4, 15 },
        action = gate,
    }
end

crops.connect_grid(render_grid, g)
```
TODO:
- describe modules (like Grid)
- note coupled interaction & internal data storage – one of crops’ superpowers.
- note callback props, like the action prop
- describe dynamic props + dirty flags

## the state prop

as mentioned previously, closures’ superpower is the ability to store private, internal data. this has its uses – however – often, we actually do want to be able to access & modify some of the data associated with a component externally, for example, whether our toggle button is on or off.

the state prop allows us to do this by defining a state variable outside of a component (and outside the associated render function), then passing it into the component, along with a state setter function. the setter function needs to do 3 things:
1. assign a new value to our state variable, passed in from the component
2. mark the default grid device as dirty – this will trigger a redraw of the grid. dirty must manually be called for any device that this state data affects.
3. (optional) perform any actions associated with the change of state, such as printing a message or sending an engine command. 
    - avoid using the action prop when using state – you may want other processes to be able to call the setter function, and you’ll want to ensure that the same action takes place (as in the example below).

the state variable value & state setter function are passed to the component with the help of the `crops.of_variable` function. there are several variants of this function for different state sources. a component may have multiple state props, but generally there is just one.

here’s an example of a stateful toggle button using Grid’s toggle component:
```
engine.name = 'PolySub'

g = grid.connect()

_button = Grid.toggle()

gate = 0
set_gate = function(new_value)
    gate = new_value

    crops.grid.dirty()

    local id, hz = 1, 440
    if gate == 1 then
        engine.start(id, hz)
    elseif gate == 0 then
        engine.stop(id)
    end
end

function render_grid()
    _button{
        x = 1,
        y = 1,
        levels = { 4, 15 },
        state = crops.of_variable(gate, set_gate),
    }
end

crops.connect_grid(render_grid, g)
```
as with the last example, we’re able to take some form of action as a result of an input. but unlike before, we can interact with `gate` programmatically, outside of our component:
- we can check the value of `gate` at any time, just type `gate` in the REPL
- we can set gate & our component will respond correctly. call `set_gate(1)` & `set_gate(0)` in the REPL – the grid is redrawn & always shows the correct value. 

in the last example, you could call `gate(1)` externally, but the grid would never reflect whatever new value you sent. there was also no way to check gate. grid’s strength is in creating interfaces that combine human & machine control – state allows UI to visually reflect this collaboration.

## params as a state source
```
engine.name = 'PolyPerc'

g = grid.connect()

scale = { 1/1, 9/8, 81/64, 3/2, 27/16 }

params:add{
    type = 'number',
    id = 'note',
    min = 1,
    max = 5,
    action = function(value)
        local hz = 110 * scale[value]
        engine.hz(hz)

        crops.grid.dirty()
    end
}

_keyboard = Grid.integer()

function render_grid()
    _keyboard{
        x = 1,
        y = 1,
        size = 5,
        levels = { 4, 15 },
        state = crops.of_param('note'),
    }
end

crops.connect_grid(render_grid, g)
```
TODO:
- describe state source, `of_param`
- note calling dirty flag in param.action

## repetition & pagination

TODO:
- sequencer using sequins/timeline
- add a second page for octaves

## multi-key components

TODO:
- basic grid keyboard using momentaries & action
- discuss flat layout of table states, math needed to get x/y from index

## table states

TODO:
- turn keyboard into drone machine with toggles
- correct to allow machine control w/o relying on action
- snapshots/immutability

## crops + pattern_time

(TODO)

## creating closures
```
function Closure()
    local idx = 1
    
    return function()
        print('idx:', idx)
        idx = idx + 1
    end
end
```
```
> _func = Closure()
> _func()
idx:   1
> _func()
idx:   2
> _func()
idx:   3
```
TODO:
- describe example, ref: https://www.lua.org/pil/6.1.html
- description of pure functions – ref: https://react.dev/learn/keeping-components-pure
- what happens in a closure – stays in a closure ;)

## creating  group components

TODO: describe the issues of polluting global namespace & of reusability
```
function Group_component() --the component constructor. it runs once

    -- local variable initialization
    --     if a variable is re-assigned between renders (like state), 
           initialize it here
    --     intialize any components that are used in the render loop
    --     define functions used in the render loop

    return function() --the component render loop. it runs many times

        -- rendering logic
        --     render components here, you may access any data defined above
        --     if a variable is re-assigned between renders (like state), do NOT  
        --     define it here, define it above
        --     do NOT initialize other components here
    end
end

---

g = grid.connect()

function Button(args)
    local _button = Grid.toggle()

    local button_value = 0
    local set_button = function(new_value)
        button_value = new_value
        print(args.name..' is '..button_value)

        crops.grid.dirty()
    end

    return function(props)
        _button{
            x = props.x,
            y = props.y,
            levels = { 4, 15 },
            state = crops.of_value(button_value, set_button),
        }
    end
end

local _button1 = Button{ name = 'button 1' }
local _button2 = Button{ name = 'button 2' }

function render_grid()
    _button1{ x = 1, y = 1 }
    _button2{ x = 2, y = 1 }
end

crops.connect_grid(render_grid, g)
```

## creating device components

TODO
- overview of boilerplate & 'copy from components/' strategy
- optional use of metatables for prop & arg defaults
<!--stackedit_data:
eyJoaXN0b3J5IjpbNDI3MTE2ODE0XX0=
-->

## distributing the crops library with your script

TODO
- options:
    - copying `crops/`, easier
    - adding a submodule, harder, but better
