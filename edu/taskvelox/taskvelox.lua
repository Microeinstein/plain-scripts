#!/usr/bin/lua5.3

-- use __newindex and __index to call coroutine.yield()
-- scopes + coroutines + metatables

--require "lanes".configure()

math.randomseed(os.time())
i18n = {
    ita = {
        bad_input          = "\027[A\027[K\027[1;31mInput non valido.\027[0m",
        interr_rcv         = "\n\027[1;33mInterrotto.\027[0m",
        unk_long_arg       = "\27[93mArgomento lungo sconosciuto: %s\n\n",
        unk_short_arg      = "\27[93mArgomento corto sconosciuto: %s\n\n",
        arg_err_one_exfile = "\27[93mScusa, solo un esercizio per favore.\n\n",
        role_proc          = "processo",
        role_sembin        = "semaforo binario",
        role_semint        = "semaforo intero",
        role_cnter         = "contatore",
        role_cust          = "altro: %s",
        role_res           = "risorsa",
        role_intern        = "interno: %s",
        exfiles_not_found  = "Esercizi non trovati."..[[
Specifiche:
    - codice lua
    - nome del file terminante in "%s"
    - presenti nella stessa cartella di questo script
]],
        avail_exfiles      = "Esercizi disponibili:\027[95m",
        select_exfile      = "Seleziona esercizio: ",
        warn_redefine      = '\n\27[93mAttenzione\27[0m: "%s" era definito di un altro tipo.',
        warn_redef_int     = '\n\27[93mAttenzione\27[0m: "%s" esiste già internamente come %s, verrà nascosto.',
        err_hint_syntax    = "→ Probabilmente Lua non supporta la sintassi usata in quel punto.",
        err_hint_expect    = "→ Probabilmente ti sei dimenticato di chiudere o definire qualcosa.",
        err_hint_file      = "→ File inesistente",
        err_hint_unk       = "→ Sono sicuro ci sia un errore, non so dirti la causa...",
        success_read       = "\27[92mLetto con successo.\27[0m",
        summary_res        = "\n\27[91mRisorse\27[0m:",
        summary_sem        = "\n\27[93mSemafori\27[0m:",
        summary_cnt        = "\n\27[96mContatori\27[0m:",
        summary_oth        = "\n\27[92mAltro\27[0m:",
        summary_prc        = "\n\27[95mProcessi\27[0m:",
        err_no_procs       = "\27[91mL'esercizio non ha senso: non contiene processi. Termino...\27[0m",
        sim_wait           = '\27[35m%s\27[90m attende \27[33m%s\27[0m\n',
        sim_enter          = '\27[95m%s\27[0m entra in \27[93m%s\27[0m',
        sim_leave          = '\27[95m%s\27[0m esce da \27[93m%s\27[0m',
        sim_access         = '\27[35m%s\27[90m accede a \27[36m%s\27[90m',
        sim_read           = '\27[35m%s\27[90m legge \27[36m%s\27[90m',
        sim_assign         = '\27[95m%s\27[0m assegna \27[96m%s\27[0m%s',
        sim_use            = '\27[95m%s\27[0m usa \27[91m%s\27[0m',
        sim_release        = '\27[95m%s\27[0m rilascia \27[91m%s\27[0m',
        sim_err_res_assign = 'tentativo di assegnazione alla risorsa "%s"',
        sim_err_res_busy   = 'tentativo di utilizzare la risorsa occupata "%s"',
        sim_err_lua_unk    = "Lua non conosce questa parola chiave",
        sim_err_sem_unk    = "\27[93m(Stai usando il nome di un semaforo non definito, typo?)\27[0m",
        sim_err_syntax     = "\27[93m(Errore sintassi)\27[0m ",
        sim_err            = "\27[93m(Errore simulazione)\27[0m ",
        sim_start          = "\27[93mSimulazione avviata, continua a premere Invio.\27[0m",
        sim_err_deadlock   = "\27[1;91mDeadlock?\27[0;91m Controlla i tuoi semafori.\27[0m\n"
    }
}
msgs = i18n.ita


--[[INTERNALS]]
function printf(fmt, ...)
    io.write(string.format(fmt, ...))
end
function printfAlign(fmt, offset, ...)
    local str = string.format(fmt, ...)
    if offset < 0 then
        io.write(string.rep(" ", math.max(0, (-offset)-#str)))
    end
    io.write(str)
    if offset > 0 then
        io.write(string.rep(" ", math.max(0, offset-#str)))
    end
end
function ask(fmt, ...)
    if true then
        printf(fmt, ...)
    end
    local line
    if not pcall(function() line = io.read() end) then
        print(msgs.interr_rcv)
        os.exit(1)
    end
    return line
end
function asknum(fmt, filter, retry_msg, ...)
    local num, ok
    repeat
        local txt = ask(fmt, ...)
        num = tonumber(txt)
        ok = num or not retry_msg
        if not ok then
            print(retry_msg)
        elseif filter and not filter(num) then
            ok = false
            num = nil
            print(retry_msg)
        end
    until ok
    return num
end
function askintpos(fmt, ...)
    local function f(n)
        return n >= 0 and n % 1 == 0
    end
    return asknum(fmt, f, msgs.bad_input, ...)
end
function askint1(fmt, ...)
    local function f(n)
        return n > 0 and n % 1 == 0
    end
    return asknum(fmt, f, msgs.bad_input, ...)
end
function askchoicek(fmt, retry_msg, tbl, ...)
    local choice
    repeat
        choice = ask(fmt, ...)
        for k,_ in pairs(tbl) do
            if k == choice then
                return k
            end
        end
        print(retry_msg)
    until false
end
function askchoicek_(fmt, tbl, ...)
    return askchoicek(fmt, msgs.bad_input, tbl, ...)
end
function askchoicev(fmt, retry_msg, tbl, ...)
    local choice
    repeat
        choice = ask(fmt, ...)
        for k,v in pairs(tbl) do
            if v == choice then
                return k
            end
        end
        print(retry_msg)
    until false
end
function askchoicev_(fmt, tbl, ...)
    return askchoicev(fmt, msgs.bad_input, tbl, ...)
end
function round(n)
    return math.floor(n + 0.5)
end
function randInt(min, max)
    max = max + 1
    local r = math.random() * (max - min) + min
    return math.floor(r)
end
function new(tspecs)
    local r = {}
    for n = 1,tspecs[1] do
        r[n] = tspecs[2] or 0
    end
    return r
end
function dump(object)
    local str = ""
    if type(object) == 'table' then
        str = str..'['
        local nf = false
        for k2,v2 in pairs(object) do
            if nf then str = str..',' end
            nf = true
            str = str..string.format('%s', v2)
        end
        str = str..']'
    else
        str = str..string.format('%s', object)
    end
    return str
end

--[[COPIED FROM PERSONAL FRAMEWORK]]
utf8._len = utf8.len
utf8._codes_iter, _, _ = utf8.codes("")
utf8._codes = utf8.codes
process = {}
path = {}
path.dir_cmd   = [[find "%s" -maxdepth 1 -type d -printf '%%f\n']]
path.file_cmd  = [[find "%s" -maxdepth 1 -type f -printf '%%f\n']]
path.all_cmd   = [[find "%s" -maxdepth 1 -printf '%%f\n']]
path.dirr_cmd  = [[find "%s" -type d -printf '%%P\n']]
path.filer_cmd = [[find "%s" -type f -printf '%%P\n']]
path.allr_cmd  = [[find "%s" -printf '%%P\n']]
function math.isInteger(num)
    return num % 1 == 0
end
function math.between(a, v, b)
    return math.max(a, math.min(v, b))
end
function utf8.len(str)
    --if i > 0 and j > 0 and i < j then
    --  return 0
    --elseif i < 0 and j < 0 and i > j then
    --  return 0
    --end
    local l = 0
    local p = 1
    local op = 0
    
    ::finoallafine::
    local ul, ep = utf8._len(str, p)
    --print("UntilEnd:", ul, ep)
    if ul then
        goto fine
    end
    
    if ep == p then
        --print("FoundBad")
        l = l + 1
        p = p + 1
        goto finoallafine
    end
    --print("FoundGood")
    op = ep
    ep = ep - 1
    ul, ep = utf8._len(str, p, ep)
    --print("UntilChunk:", ul, ep)
    if not ul then
        error([[This can't happen, because last "ep" is used for current check...]])
    end
    l = l + ul
    p = op
    goto finoallafine
    
    ::fine::
    l = l + ul
    --print("End:", l)
    return l
end
function utf8.codes(str)
    local ok, p, v
    return function(s, i)
        local ok2, p2, v2 = ok, p, v
        ok, p, v = pcall(utf8._codes_iter, s, i)
        if ok then
            --print("u", p)
            return p, v, true
        else
            if ok2 then
                i = i + #(utf8.char(v2))
            else
                i = i + 1
            end
            --print("a", i)
            return i, string.byte(s, i, i), false
        end
    end, str, 0
end
function utf8.sub(str, i, j)
    j = j or -1
    if i == 1 and j == -1 then
        return str
    end
    if type(str) ~= "string" or type(i) ~= "number" or type(j) ~= "number" then
        error("There are arguments with invalid types.")
    end
    local l = utf8.len(str)
    if string.len(str) == l then
        return string.sub(str, i, j)
    end
    if i < 0 then i = l + i + 1 end
    if j < 0 then j = l + j + 1 end
    local ret = ""
    local c = 0
    for _, v, u in utf8.codes(str) do
        c = c + 1
        if c <= j then
            if c >= i then
                ret = ret .. (u and utf8.char(v) or string.char(v))
            end
        else
            return ret
        end
    end
    return ret
end
function path.getFiles(dir, recursive)
    recursive = recursive or false
    local proc = string.format(recursive and path.filer_cmd or path.file_cmd, dir)
    return process.getOutput(proc)
end
function process.getOutput(cmd)
    local t, i = {}, 0
    local output = io.popen(cmd)
    for line in output:lines() do
        i = i + 1
        t[i] = line
    end
    output:close()
    return t
end
function string.chars(self)
    local l = utf8.len(self)
    local ch = {}
    for i = 1, l do
        table.insert(ch, utf8.sub(self, i, i))
    end
    return ch
end
function string.contains(self, str)
    if self and str then
        if self == str then
            return true, 0
        end
        local lenA = utf8.len(self)
        local lenB = utf8.len(str)
        local lenMin = lenA - lenB + 1
        if lenMin < 1 then
            return false, -1
        end
        for i = 1, lenMin do
            local slice = utf8.sub(self, i, i + lenB - 1)
            if slice == str then
                return true, i
            end
        end
        return false, -1
    else
        return false, -1
    end
end
function string.split(self, sep, esc)
    if type(sep) == "number" then
        if self then
            local l = utf8.len(self)
            sep = math.between(0, sep, l)
            return utf8.sub(self, 1, sep), utf8.sub(self, sep + 1, l)
        else
            return "", ""
        end
    elseif type(sep) == "string" then
        local ret = {}
        local iret = 1
        if self then
            if sep == "" or self == "" then
                return { self }
            end
            local charsE, lenE
            if esc == "" then
                esc = nil
            end
            if esc then
                charsE = string.chars(esc)
                lenE = #charsE
            end
            local charsB = string.chars(sep)
            local lenB = #charsB
            local charsA = string.chars(self)
            local lenA = #charsA
            if lenA < lenB then
                return {}
            end
            local sliceSep = ""
            local sliceEsc = ""
            local nextTextAnchor = 1
            local escaped = false
            local nearEscaped = {}
            local inesc = 1
            for i, v in ipairs(charsA) do
                if i >= nextTextAnchor and v == charsB[1] then
                    --io.write(i .. "?")
                    sliceSep = table.concat(table.sub(charsA, i, i + lenB - 1))
                    --io.write(sliceSep)
                    if sliceSep == sep then --i is always at "Text Esc [S]ep"
                        --io.write("~")
                        escaped = false
                        if esc and i > lenE and charsA[i - lenE] == charsE[1] then
                            sliceEsc = table.concat(table.sub(charsA, i - lenE, i - 1))
                            --io.write(sliceEsc)
                            escaped = sliceEsc == esc
                        end
                        if not escaped then
                            --io.write("!")
                            ret[iret] = table.concat(nearEscaped) .. table.concat(table.sub(charsA, nextTextAnchor, i - 1))
                            iret = iret + 1
                            nearEscaped = {}
                            inesc = 1
                        else
                            --io.write("x")
                            nearEscaped[inesc] = table.concat(table.sub(charsA, nextTextAnchor, i - 1 - lenE)) .. sep
                            inesc = inesc + 1
                        end
                        nextTextAnchor = i + lenB
                    end
                    --io.write("\n")
                end
            end
            ret[iret] = table.concat(table.sub(charsA, nextTextAnchor, lenA))
        end
        return ret
    end
end
function string.startsWith(self, str)
    if self and str then
        if self == str then
            return true
        end
        local lenA = utf8.len(self)
        local lenB = utf8.len(str)
        local lenMin = lenA - lenB + 1
        if lenMin < 1 then
            return false
        end
        local slice = utf8.sub(self, 1, lenB)
        return slice == str
    else
        return false
    end
end
function string.endsWith(self, str)
    if self and str then
        if self == str then
            return true
        end
        local lenA = utf8.len(self)
        local lenB = utf8.len(str)
        local lenMin = lenA - lenB + 1
        if lenMin < 1 then
            return false
        end
        local slice = utf8.sub(self, lenA - lenB + 1, lenA)
        return slice == str
    else
        return false
    end
end
function table.append(self, values, onlyNumericalKeys)
    onlyNumericalKeys = onlyNumericalKeys or false
    local l = #self
    if onlyNumericalKeys then
        for _, v in ipairs(values) do
            l = l + 1
            self[l] = v
        end
    else
        for _, v in pairs(values) do
            l = l + 1
            self[l] = v
        end
    end
end
function table.len(self, nils) --nils = count also nil values with an integral key
    nils = nils or true
    local c = 0
    local ma = 0
    for k, v in pairs(self) do
        if nils and type(k) == "number" and k >= 1 and math.isInteger(k) then
            ma = math.max(ma, k)
        else
            c = c + 1
        end
    end
    return c + ma
end
function table.sub(self, from, to)
    to = to or -1
    if from == 1 and to == -1 then
        return self
    end
    local l = #self
    if l == 0 then
        return {}
    end
    if from < 0 then from = l + from + 1 end
    if to < 0 then to = l + to + 1 end
    if from > to then
        return {}
    elseif from == to then
        return { self[from] }
    end
    local ret = {}
    local iret = 1
    for i, v in ipairs(self) do
        if i <= to then
            if i >= from then
                ret[iret] = v
                iret = iret + 1
            end
        else
            return ret
        end
    end
    return ret
end
function table.where(self, lambda, ...)
    local ret = {}
    for k, v in pairs(self) do
        if lambda(k, v, ...) then
            ret[k] = v
        end
    end
    return ret
end
function table.select(self, lambda, ...)
    local ret = {}
    for k, v in pairs(self) do
        local a, b = lambda(k, v, ...)
        local k2 = b == nil and k or a
        local v2 = b == nil and a or b
        ret[k2] = v2
    end
    return ret
end
function table.aggregate(self, lambda, ...)
    local ret = nil
    local skip1 = true
    for k, v in pairs(self) do
        if skip1 then
            ret = v
            skip1 = false
        else
            ret = lambda(k, v, ret, ...)
        end
    end
    return ret
end
function table.compact(self)
    local ret = {}
    local numKey = 1
    local numbersEnd = false
    for k, v in pairs(self) do
        if numbersEnd or type(k) ~= "number" then
            numbersEnd = true
            ret[k] = v
        else
            ret[numKey] = v
            numKey = numKey + 1
        end
    end
    return ret
end
function table.removeObj(self, obj)
    local i
    for k,v in ipairs(self) do
        if v == obj then
            i = k
            break
        end
    end
    if not i then return false end
    table.remove(self, i)
    return true
end

function printlines(...)
    local args = {...}
    local len = table.len(args, true)
    for k=1, len do
        local v = args[k]
        local s
        if type(v) == "nil" then
            s = ""
        else
            s = tostring(v)
        end
        print(s)
    end
end


--[[REAL CODE]]
function __help_msg()
    printlines(
"\27[1;91mTaskVelox\27[0m v2"
,"\27[4mAuthor: Microeinstein\27[0m"
,"Lua script to help debugging of Computer Science exercises"
,"in concurrent processes synchronization."
,nil
,"\27[1;92mUsage\27[0m: "..arg[0].." [OPTIONS] [--] [exercise file]"
,nil
,"\27[1;93mOptions\27[0m:"
,"  -h  --help                  Show this help"
,"  -v  --verbose               Increase verbosity level"
,nil
,"\27[1;95mExamples\27[0m:"
,"  "..arg[0].." -v"
,"  "..arg[0].." -vv -- mySemaphores_es.lua"
,"  "..arg[0].." --help"
,nil
    );
    os.exit(0)
end

--lettura argomenti
ex_suffix = "_es"
extension = ex_suffix..".lua"
verbosity = 0
_no_more_args = false
_next_arg_value = nil
for i,arg in ipairs(arg) do
    if _no_more_args then
        break
    end
    if arg == "--" then
        _no_more_args = true
    elseif string.startsWith(arg, "--") then --long option
        _,arg = string.split(arg, 2)
        if arg == "help" then
            __help_msg()
        elseif arg == "verbose" then
            verbosity = verbosity + 1
        else
            --argparts = string.split(arg, "=")
            --TODO
            printf(msgs.unk_long_arg, arg)
            os.exit(1)
        end
    elseif string.startsWith(arg, "-") then --short option(s)
        _,arg = string.split(arg, 1)
        for i,arg in ipairs(string.chars(arg)) do
            if arg == "v" then
                verbosity = verbosity + 1
            elseif arg == "h" then
                __help_msg()
            else
                printf(msgs.unk_short_arg, arg)
                os.exit(1)
            end
            --TODO
        end
    else
        if exercise then
            printf(msgs.arg_err_one_exfile, arg)
            os.exit(1)
        end
        exercise = arg
    end
end

--selezione interattiva
if #arg < 1 or not exercise then
    choices = path.getFiles("exercises",false)
    --for k,v in pairs(choices) do print(k,v) end
    choices = table.compact(table.where(choices,
        function(k,v)
            return string.endsWith(v, extension)
        end
    ))
    --for k,v in pairs(choices) do print(k,v) end
    if #choices == 0 then
        printf(msgs.exfiles_not_found)
    end
    choices = table.select(choices,
        function(k,v)
            return utf8.sub(v,1,#v-#extension)
        end
    )

    io.write(msgs.avail_exfiles)
    for _,v in ipairs(choices) do
        io.write(" "..v)
    end
    print("\027[0m")
    choice = askchoicev_(msgs.select_exfile, choices)
    exercise = choices[choice]..extension
    choice = nil
    choices = nil
end


--lettura esercizio (magic)
procs  = {}
nprocs = {}
semBin = {}
semInt = {}
cnters = {}
newG   = {}
res    = {}
roles  = {}
resources = function(r)
    for k,v in pairs(r) do
        local re = {}
        re.maxusage = v
        re.using = {}
        res[k] = re
        setRole(k,res)
    end
end
--[[procs   = procs,
semBin  = semBin,
semInt  = semInt,
counter = counter,
newG    = newG,
res     = res,
roles   = roles,
__G     = _G,]]
sandbox = {}
function getRole(k)
    local r = roles[k]
    if r == procs      then return msgs.role_proc
    elseif r == semBin then return msgs.role_sembin
    elseif r == semInt then return msgs.role_semint
    elseif r == cnters then return msgs.role_cnter
    elseif r == newG   then return string.format(msgs.role_cust, type(newG[k]))
    elseif r == res    then return msgs.role_res
    end
    return string.format(msgs.role_intern, type(_G[k]))
end
function setRole(k,r)
    if roles[k] and roles[k] ~= r then
        printf(msgs.warn_redefine, k)
        rawset(roles[k],k,nil) --remove previous table-associated value
    elseif _ENV[k] then
        printf(msgs.warn_redef_int, k, type(_ENV[k]))
    end
    roles[k] = r
end
loadmeta = {
    __index = function(t,k)
        if t ~= sandbox then
            return
        elseif _ENV[k] then
            return _ENV[k]
        end
        return k
    end,
    __newindex = function(t,k,v)
        if t == procs
        or t == semBin
        or t == semInt
        or t == cnters then
            rawset(t,k,v)
            setRole(k,t)
            return
        end
        local ty = type(v)
        if ty == "function" then
            local np = {}
            np.name = k
            np.code = v
            np.dump = string.dump(v)
            rawset(procs,k,np)
            table.insert(nprocs,np)
            setRole(k,procs)
        elseif ty == "number" then
            rawset(cnters,k,v)
            setRole(k,cnters)
        else
            rawset(newG,k,v)
            setRole(k,newG)
        end
    end
}
setmetatable(procs,   loadmeta)
setmetatable(semBin,  loadmeta)
setmetatable(semInt,  loadmeta)
setmetatable(cnters,  loadmeta)
setmetatable(newG,    loadmeta)
setmetatable(sandbox, loadmeta)
tryload = {}
tryload.ok, tryload.error = loadfile(exercise, nil, sandbox) --function OR nil + error
if tryload.ok then
    tryload.ok, tryload.error = pcall(tryload.ok) --retvalue OR nil + error
end
setmetatable(sandbox, nil)
if not tryload.ok then
    printf("\27[91m%s\27[0m\n", tryload.error)
    if string.contains(tryload.error, "syntax error") then
        print(msgs.err_hint_syntax)
    elseif string.contains(tryload.error, "expected") then
        print(msgs.err_hint_expect)
    elseif string.contains(tryload.error, "No such file or directory") then
        print(msgs.err_hint_file)
    else
        print(msgs.err_hint_unk)
    end
    print()
    os.exit(1)
end
print(msgs.success_read)


function maxValueBy(tables, selector)
    local function lambda(k,v,prev)
        if selector(k,v) > selector(k,prev) then
            return v
        else
            return prev
        end
    end
    return table.aggregate(procs, lambda)
end


--sommario
listSpace = 0
for k,v in pairs(res) do    if #k > listSpace then listSpace = #k end end
for k,v in pairs(semBin) do if #k > listSpace then listSpace = #k end end
for k,v in pairs(semInt) do if #k > listSpace then listSpace = #k end end
for k,v in pairs(cnters) do if #k > listSpace then listSpace = #k end end
for k,v in pairs(newG) do   if #k > listSpace then listSpace = #k end end
for k,v in pairs(procs) do  if #k > listSpace then listSpace = #k end end
listSpace = listSpace + 3

empty = true
for k,v in pairs(res) do
    if empty then
        print(msgs.summary_res)
        empty = false
    end
    printfAlign("  %s", listSpace, k)
    printf(' (%d)\n', v.maxusage)
end

empty = true
for k,v in pairs(semBin) do
    if empty then
        print(msgs.summary_sem)
        empty = false
    end
    printfAlign("  %s", listSpace, k)
    printf(' (%d)\n', v)
end
for k,v in pairs(semInt) do
    printfAlign("  %s", listSpace, k)
    printf(' (%d)\n', v)
end

empty = true
for k,v in pairs(cnters) do
    if empty then
        print(msgs.summary_cnt)
        empty = false
    end
    printfAlign("  %s", listSpace, k)
    printf('= %d\n', v)
end

empty = true
for k,v in pairs(newG) do
    if empty then
        print(msgs.summary_oth)
        empty = false
    end
    printfAlign("  %s", listSpace, k)
    io.write('= ')
    io.write(dump(v))
    io.write('\n')
end

empty = true
for k,v in pairs(procs) do
    if empty then
        print(msgs.summary_prc)
        empty = false
    end
    printf("  %s\n", k)
end
print()


--preparazione
pcount = #nprocs
if pcount < 1 then
    print(msgs.err_no_procs)
    os.exit(1)
end
pnmlen = #maxValueBy(procs, function(k,v) return #k end).name
msgSpacer = pnmlen + 42
msgTidSpc = -5
pause = false

--messaggi simulazione
simulmsg = {
    wait = function(taskNum, procName, semName)
        if verbosity < 1 then return end
        --pause = false
        printfAlign('\27[90m%d. ', msgTidSpc-5, taskNum)
        printf(msgs.sim_wait, procName, semName)
    end,
    enter = function(taskNum, procName, semName, semValue)
        pause = true
        printfAlign('%d. ', msgTidSpc, taskNum)
        printfAlign(msgs.sim_enter, msgSpacer, procName, semName)
        printf(' (%d)\n', semValue)
    end,
    leave = function(taskNum, procName, semName, semValue)
        pause = true
        printfAlign('%d. ', msgTidSpc, taskNum)
        printfAlign(msgs.sim_leave, msgSpacer, procName, semName, semValue)
        printf(' (%d)\n', semValue)
    end,
    access = function(taskNum, procName, varName, varType)
        if verbosity < 2 then return end
        --pause = true
        printfAlign('\27[90m%d. ', msgTidSpc-5, taskNum)
        printfAlign(msgs.sim_access, msgSpacer+2, procName, varName)
        printf(' (%s)\27[0m\n', varType)
    end,
    read = function(taskNum, procName, varName, varValue)
        if verbosity < 2 then return end
        --pause = true
        printfAlign('\27[90m%d. ', msgTidSpc-5, taskNum)
        printfAlign(msgs.sim_read, msgSpacer+2, procName, varName)
        local vvd = dump(varValue)
        if not string.startsWith(vvd, '[') then
            vvd = '('..vvd..')'
        end
        printf(' %s\27[0m\n', vvd)
    end,
    assign = function(taskNum, procName, varName, varValue, new)
        pause = true
        printfAlign('%d. ', msgTidSpc, taskNum)
        printfAlign(msgs.sim_assign, msgSpacer, procName, varName, new and " (nuova)" or "")
        printf('= %s\n', varValue)
    end,
    use = function(taskNum, procName, resName, resValue)
        pause = true
        printfAlign('%d. ', msgTidSpc, taskNum)
        printfAlign(msgs.sim_use, msgSpacer, procName, resName, resValue)
        printf(' (%d)\n', resValue)
    end,
    release = function(taskNum, procName, resName, resValue)
        pause = true
        printfAlign('%d. ', msgTidSpc, taskNum)
        printfAlign(msgs.sim_release, msgSpacer, procName, resName, resValue)
        printf(' (%d)\n', resValue)
    end,
    init = function(taskNum, procName)
        --pause = true
        io.write('\27[1;92m+')
        printfAlign('\27[0;92m%d\27[0m ', -14, taskNum)
        printf('(\27[95m%s\27[0m)\n', procName)
    end,
    term = function(taskNum, procName)
        --pause = true
        io.write('\27[1;91m-')
        printfAlign('\27[0;91m%d\27[0m ', -14, taskNum)
        printf('(\27[95m%s\27[0m)\n', procName)
    end
}

--implementazione gestione base semafori
function p(task, tasknum, sem)
    local st = roles[sem]
    if st[sem] < 1 then
        simulmsg.wait(tasknum, task.name, sem)
    end
    while st[sem] < 1 do
        coroutine.yield()
    end
    st[sem] = st[sem] - 1
    simulmsg.enter(tasknum, task.name, sem, st[sem])
end
function v(task, tasknum, sem)
    local st = roles[sem]
    if st ~= semBin or st[sem] < 1 then
        st[sem] = st[sem] + 1
    end
    simulmsg.leave(tasknum, task.name, sem, st[sem])
end

--gestione processi (chiamati tasks) (still magic)
useResDummy = function() end
ltp = 0
tmax = pcount*3
tcount = 0
tid = 0
tasks = {}
taskmeta = {
    __newindex = function(t,k,v) --write
        local task, tasknum = coroutine.yield()
        local r = roles[k]
        simulmsg.assign(tasknum, task.name, k, v, not r)
        if not r then
            --error("attempt to assign to unknown object: ('"..k.."')")
            rawset(t.newG,k,v)
            setRole(k,t.newG)
            return
        end
        if r == res then
            error(string.format(msgs.sim_err_res_assign, k))
        end
        rawset(r,k,v)
    end,
    __index = function(t,k) --read, call
        --print("use: "..k)
        local task, tasknum = coroutine.yield()
        local lk = string.lower(k)
        local mapped = {
            p = function(n) return p(task, tasknum, n) end,
            v = function(n) return v(task, tasknum, n) end
        }
        for k,v in pairs(mapped) do
            if lk == k then
                simulmsg.access(tasknum, task.name, k, getRole(k))
                return v
            end
        end
        simulmsg.access(tasknum, task.name, k, getRole(k))
        local r = roles[k]
        if not r then
            --error("attempt to use undefined object: ('"..k.."')")
            return _ENV[k]
        end
        if r == semBin or r == semInt then
            return k
        end
        local obj = r[k]
        if r == res then --gestione risorse
            if obj.maxusage > 0 and #obj.using == obj.maxusage then
                error(string.format(msgs.sim_err_res_busy, k))
            end
            table.insert(obj.using,tasknum)
            simulmsg.use(tasknum, task.name, k, #obj.using)
            task, tasknum = coroutine.yield()
            table.removeObj(obj.using,tasknum)
            simulmsg.release(tasknum, task.name, k, #obj.using)
            return useResDummy
        end
        if not obj and k == "continue" then
            error(msgs.sim_err_lua_unk)
        end
        simulmsg.read(tasknum, task.name, k, obj)
        return obj
    end
}
function addNewTask(procNum)
    local function taskStep(proc, pid)
        local s = {}
        setmetatable(s, taskmeta)
        load(proc.dump, nil, nil, s)(pid)
    end
    local t = {}
    if tid >= tmax*2 then
        tid = 0
    end
    tid = tid + 1
    t.p  = nprocs[procNum]
    t.cr = coroutine.create(taskStep)
    t.id = tid
    tcount = tcount + 1
    tasks[tcount] = t
    simulmsg.init(tid, t.p.name)
end
function stepTask(taskNum)
    local t = tasks[taskNum]
    if coroutine.status(t.cr) == "dead" then
        simulmsg.term(t.id, t.p.name)
        table.remove(tasks, taskNum)
        tcount = tcount - 1
        return
    end
    --printf('[resume %d]\n', taskNum)
    local ok, err = coroutine.resume(t.cr, t.p, t.id)
    if not ok then
        local cust = ""
        if string.endsWith(err, "attempt to index a nil value (local 'st')") then
            err = err..msgs.sim_err_sem_unk
        else
            if string.startsWith(err, exercise) then
                cust = msgs.sim_err_syntax
            else
                cust = msgs.sim_err
            end
            err = cust..err
        end
        err = "\n"..err
        error(err)
    end
end


--esecuzione
print(msgs.sim_start)
nonpause = 0
while true do
    pause = false
    local op = randInt(0,1)
    if tcount == 0 or (op == 1 and tcount < tmax) then
        ltp = 1 + (ltp % pcount) --round robin
        addNewTask(ltp)
    end
    op = randInt(1, tcount)
    stepTask(op) --if not stepTask(op) then break end
    nonpause = nonpause + 1
    if nonpause > 500000 then
        printf(msgs.sim_err_deadlock)
        os.exit(2)
    end
    if pause then
        nonpause = 0
        ask("") --premi invio per continuare
        io.write("\27[A")
    end
end















