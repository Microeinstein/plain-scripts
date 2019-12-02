## TaskVelox

Debugging tool for Computer Science exercises on concurrent process synchronization.

<div align=center>
<a href="https://asciinema.org/a/284838?autoplay=1">
<img src="https://asciinema.org/a/284838.svg" alt="asciinema demo">
</a>
</div>

### Requirements

* Lua 5.3
* ANSI escapes-compatible terminal:
  * Linux: any terminal
  * Windows: [ANSICON](https://github.com/adoxa/ansicon) or [ConEmu](https://conemu.github.io/)

### Usage

Launch `taskvelox.lua` with an exercise, or let the script show you the choices:

    ./taskvelox.lua [exerciseName_es.lua]

then keep pressing `Enter` to continue execution.
At the moment the only way to terminate execution is to `Ctrl-C` or by killing lua process.
*(`CtrlZ` is used by Bash to suspend, not terminate)*

### Exercise format

Note: this format is subject to changes.

```lua
--[[
This is basic Lua language syntax,
and yes this is a multiline comment.
]]
--This is a singleline comment

--[[
definition of resources:
  "maxUsage" is an integer and represents how many tasks will be using that resource.
    0 means no limits, negative values are unexpected behavior.
]]
resources { resourceName = maxUsage, ... }
--This is a binary semaphore, its value range is [0..1]
semBin.name = initialValue
--This is a counting semaphore, its value range is [0..∞]
semInt.name = initialValue
--This is a counter, it can have any numeric value
counterName = initialValue
--This is a custom object with custom non-numeric value
anythingElseName = initialValue
arrayName = {val1,val2,val3,--[[ ... ,]],valN}
--ad-hoc lua syntax extensions:
arrayName = new {length, initialValue}
-- ...

--[[
This is a process, currently there's no way to control how or when it's started:
  the script just spawns randomly new instances of this.
There is a limit of maximum 8 processes existing simultaneously
]]
function processName(pid)
  --These are the basic semaphore functions P (or "wait")
  --and V (or "signal"), they are case-INsensitive
  p(semaphoreName) --also P(semaphoreName)
  v(semaphoreName) --also V(semaphoreName)
  --This is how you use a resource: just call it like a function
  resourceName()

  --lua syntax example
  if counter == 3 then
    return
  end
  for a = 1,10,1 do --from 1 to 10 included, increase by 1
    print(a) --you can call Lua standard library functions
  end
  --multiple assignment, local variables
  local var1, var2 = value1, value2
  --global variable, exposed to everything
  newVar = value
  --you can find more here:
  --  https://en.wikipedia.org/wiki/Lua_(programming_language)
  --  https://www.lua.org/manual/5.3/contents.html#contents
end

function processName2(pid)
  --(whatever)
end
```

You can find some example exercises in this repo, also the complete official Lua 5.3 reference is found [here](https://www.lua.org/manual/5.3/).

### TODO

* [ ] Full support for tables
* [ ] metatables sandbox
* [ ] `debug` library sandbox
