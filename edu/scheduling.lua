#!/usr/bin/lua5.3

--[[
test cases
printf "%s\n" 5  0 3  2 6  4 9  6 6  8 3 all | ./scheduling.lua
printf "%s\n" 5  0 4  1 5  2 6  1 3  0 2 all | ./scheduling.lua
printf "%s\n" 5  0 3  1 7  1 1  3 4  1 3 all | ./scheduling.lua
printf "%s\n" 5  2 2  1 5  0 2  2 7  3 1 all | ./scheduling.lua
printf "%s\n" 5  0 6  1 3  2 1  4 5  3 2 all | ./scheduling.lua
]]

math.randomseed(os.time())
msg_badinput = "\027[A\027[K\027[1;31mFun not allowed.\027[0m"
msg_interr   = "\n\027[1;33mInterrupt received.\027[0m"


--BEGIN Commons
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
        print(msg_interr)
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
    return asknum(fmt, f, msg_badinput, ...)
end
function askint1(fmt, ...)
    local function f(n)
        return n > 0 and n % 1 == 0
    end
    return asknum(fmt, f, msg_badinput, ...)
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
    return askchoicek(fmt, msg_badinput, tbl, ...)
end
function round(n)
    return math.floor(n + 0.5)
end
function randInt(min, max)
    max = max + 1
    local r = math.random() * (max - min) + min
    return math.floor(r)
end
--END

--BEGIN Grafico
procs = {}
graph = nil
function reset()
    graph = {
        len = 0,
        tcolors = {}
    }
end
function done()
    for _,v in pairs(procs) do
        if v.burst_t > 0 then
            return false
        end
    end
    return true
end
function consume(proc)
    local gl = graph.len + 1
    graph.len = gl
    if proc and proc.burst_t > 0 then
        graph[gl] = proc.num
        proc.burst_t = proc.burst_t - 1
    end
end
--END

--BEGIN Definizione algoritmi di scheduling
local algos
algo = {}
algo.all = "placeholder"
algo.fcfs = {
    step = function(this)
        local p, amin
        for _,v in pairs(procs) do
            if v.burst_t > 0
            and (not p or v.arrivo < amin)
            then
                p = v
                amin = v.arrivo
            end
        end
        if not p then return end
        for l=1, p.burst do
            consume(p)
        end
    end
}
algo.sjf = {
    step = function(this)
        local p, amin, bmin
        for _,v in pairs(procs) do
            if v.burst_t > 0
            and v.arrivo <= graph.len
            and (not p or v.burst < bmin)
            then
                p = v
                amin = v.arrivo
                bmin = v.burst
            end
        end
        if not p then return end
        for l=1, p.burst do
            consume(p)
        end
    end
}
algo.srtf = {
    step = function(this)
        local p, amin, bmin
        for _,v in pairs(procs) do
            if v.burst_t > 0
            and v.arrivo <= graph.len
            and (not p or v.burst_t < bmin)
            then
                p = v
                amin = v.arrivo
                bmin = v.burst_t
            end
        end
        if not p then return end
        consume(p)
    end
}
algo.rr = {
    _ask = function(this)
        this.quanto = askint1("Quanto di tempo? ")
    end,
    prepare = function(this)
        this._ask(this)
        this.reset(this)
    end,
    reset = function(this)
        this.q = -1
        this.lp = nil
    end,
    step = function(this)
        --cycle time counter: 0, 1, 2, 3, ...
        this.q = (this.q + 1) % this.quanto
        --fetch last process
        local p = procs[graph[graph.len]] or this.lp
        this.lp = p
        if this.q > 0 and p.burst_t > 0 then
            consume(p)
            return
        elseif p then
            if p.burst_t == 0 then
                this.q = 0
            else
                graph.tcolors[graph.len+1] = "1;93"
            end
        end
        if graph.len == 0 then
            --fetch first process
            local amin
            for _,v in pairs(procs) do
                if not p or v.arrivo < amin then
                    p = v
                    amin = v.arrivo
                end
            end
        else
            --fetch next process to execute
            local pn = p.num
            for att=1, #procs do
                pn = pn % #procs + 1
                p = procs[pn]
                if p.arrivo <= graph.len
                and p.burst_t > 0
                then
                    break
                end
            end
        end
        consume(p)
    end
}
algo.rr1 = {
    prepare = function(this)
        this.quanto = 1
        algo.rr.reset(this)
    end,
    step = algo.rr.step
}
algo.rr2 = {
    prepare = function(this)
        this.quanto = 2
        algo.rr.reset(this)
    end,
    step = algo.rr.step
}
algo.rr3 = {
    prepare = function(this)
        this.quanto = 3
        algo.rr.reset(this)
    end,
    step = algo.rr.step
}
algo.rr4 = {
    prepare = function(this)
        this.quanto = 4
        algo.rr.reset(this)
    end,
    step = algo.rr.step
}
algo.rr5 = {
    prepare = function(this)
        this.quanto = 5
        algo.rr.reset(this)
    end,
    step = algo.rr.step
}
algo.hrrn = {
    step = function(this)
        local p, amin, rmax
        for _,v in pairs(procs) do
            local r = (graph.len - v.arrivo)/v.burst + 1
            if v.burst_t > 0
            and v.arrivo <= graph.len
            and (not p or r > rmax)
            then
                p = v
                amin = v.arrivo
                rmax = r
            end
        end
        if not p then return end
        for l=1, p.burst do
            consume(p)
        end
    end
}
--END

--BEGIN Lettura interattiva
numproc = askint1("Numero processi? ")
for i=1, numproc do
    print()
    local a = askintpos("P%d: \027[92mArrivo\027[0m? ", i)
    local b = askint1("P%d: \027[93mBurst\027[0m?  ", i)
    procs[i] = {
        arrivo  = a,
        burst   = b,
        num     = i
    }
end
print()
io.write("Algoritmi disponibili:\027[95m")
algok = {}
for k,_ in pairs(algo) do
    algok[#algok+1] = k
end
table.sort(algok)
for _,v in ipairs(algok) do
    io.write(" "..v)
end
print("\027[0m")
algoc = askchoicek_("Scelta? ", algo)
--END

--BEGIN Esecuzione
function drawData()
    local function vbar(b)
        if b then
            io.write("\027[90m│\027[0m")
        else
            io.write(" ")
        end
    end
    --io.write("\27[4m")
    io.write(" P")
    vbar()
    io.write("\027[91mArr\027[0m \027[93mBrs\027[0m")
    vbar()
    io.write("\027[92mRsp\027[0m \027[96mAtt\027[0m \027[94mTrn\027[0m  ")
    tspaces = math.floor(math.log10(graph.len-1))+1
    for t=0, graph.len-1 do
        local str = tostring(t)
        printfAlign("%d", tspaces+1, str)
    end
    --io.write("\27[0m")
    print()
    local colorRnd = randInt(1,6)
    local colorExec = "\027[10"..colorRnd.."m"
    local colorWait = "\027[4"..colorRnd.."m"
    for k,v in pairs(procs) do
        v.burst_t = v.burst
        local pgraph = ""
        local firstexec = false
        --local qnt = 0
        local tr, ta, tt
        for t=1, graph.len do
            local pdone = v.burst_t < 1
            if t < (v.arrivo+1) or pdone then
                pgraph = pgraph.."\027[100m"
                if pdone and not tt then
                    tt = t - v.arrivo - 1
                end
            elseif graph[t] ~= k then
                pgraph = pgraph..(firstexec and colorWait or "\027[47m")
                if firstexec then
                    ta = ta + 1
                end
            else
                if not firstexec then
                    firstexec = true
                    tr = t - v.arrivo - 1
                    ta = tr
                end
                pgraph = pgraph..colorExec
                v.burst_t = v.burst_t - 1
            end
            if graph.tcolors[t] then
                pgraph = pgraph.."\027["..graph.tcolors[t].."m"
            end
            --[[if algos.quanto then
                if t > 1 and qnt == 0 then
                    pgraph = pgraph.."\027[1;93m"
                elseif v.burst_t == 0 then
                    qnt = -1
                end
                qnt = (qnt + 1) % algos.quanto
            end]]
            pgraph = pgraph.."▏\027[2;30m"
            pgraph = pgraph..string.rep(" ", tspaces)
        end
        if not tt then --ultimo processo
            tt = graph.len - v.arrivo
        end
        printfAlign("%d", -2, k)        vbar(1)
        printfAlign("%d", -3, v.arrivo) vbar()
        printfAlign("%d", -3, v.burst)  vbar(1)
        printfAlign("%d", -3, tr)       vbar()
        printfAlign("%d", -3, ta)       vbar()
        printfAlign("%d", -3, tt)       vbar()
        io.write(" \027[30m")
        io.write(pgraph)
        io.write("\027[0m\027[K")
        if not firstexec then
            io.write(" \027[1;91m[!]\027[0m")
        end
        print()
    end
end
function execAlgo()
    reset()
    for _,v in pairs(procs) do
        v.burst_t = v.burst
    end
    algotimes=0
    algomax=500
    if algos.prepare then
        algos.prepare(algos)
        if algos._ask then
            print()
        end
    end
    while not done() and algotimes < algomax do
        algos.step(algos)
        algotimes = algotimes + 1
    end
    if algotimes >= algomax then
        print("\027[1;37;41mQuesto è imbarazzante, l'algoritmo selezionato non funziona...\027[0m\027[K")
        os.exit(1)
    end
    drawData()
end
if algoc == "all" then
    for _,v in ipairs(algok) do
        algos=algo[v]
        if type(algos) == "table" and not algos._ask then
            printf("\n\027[1;35m%s:\027[0m\n", string.upper(v))
            execAlgo()
        end
    end
else
    algos=algo[algoc]
    execAlgo(algoc)
end
--END
