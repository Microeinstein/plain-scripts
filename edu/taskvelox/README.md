## TaskVelox

Debugging tool for Computer Science exercises on concurrent process synchronization.

<div align=center>
<a href="https://asciinema.org/a/284838?autoplay=1">
<img src="https://asciinema.org/a/284838.svg" alt="asciinema demo">
</a>
</div>

### Requirements

* [Lua 5.3](https://en.wikipedia.org/wiki/Lua_(programming_language)):
  * ArchLinux: `pacman -S lua`
  * Ubuntu: `apt install lua5.3`
  * Windows: [choose a binary here](http://luabinaries.sourceforge.net/download.html)
* ANSI escapes-compatible terminal:
  * Linux: any terminal
  * Windows: [ANSICON](https://github.com/adoxa/ansicon) or [ConEmu](https://conemu.github.io/)

### Usage

1. Launch `taskvelox.lua` with an exercise, or let the script show you the choices:

```
./taskvelox.lua [OPTIONS] [--] [exercise file]
```

2. Keep pressing `Enter` to continue execution.

At the moment, the only way to terminate execution is to `Ctrl-C`, or by killing lua process.
*(`CtrlZ` is used by Bash to suspend, not terminate)*

### Arguments

| Name | Description |
| - | - |
| `-h` `--help`     | Show help message |
| `-v` `--verbose`  | Increase verbosity level |

### Exercise format

You can find some example exercises in this repo, also the complete official Lua 5.3 reference is found [here](https://www.lua.org/manual/5.3/).

Note: this format is subject to change.

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
This is a process.
Currently there's no way to control how or when they are started:
  the script spawns new instances using RoundRobin algorithm.
There is a limit of maximum (#processes * 3) instances existing simultaneously.
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
end

function processName2(pid)
  --(whatever)
end
```

### TODO

* [ ] Full support for tables
* [ ] Recursive table access log
* [ ] Custom process generation
* [ ] metatables sandbox
* [ ] `debug` library sandbox
