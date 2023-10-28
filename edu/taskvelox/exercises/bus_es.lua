-- comando test rapido:
-- $ yes | ./taskvelox.lua bus_es.lua

semBin.carica = 1
semBin.sali = 0
attesa = 0

cust = {
    glob = _G,
    hacks = function(c)
        -- aumenta il numero di processi simultanei
        c.glob.tmax = 100
        -- disabilita messaggi inizio / fine processi
        c.glob.simulmsg.init = function(a, b) end
        c.glob.simulmsg.term = function(a, b) end
        -- test veloce
        c.glob.ask = function(a, ...)
            c.glob.io.write('\n')
        end
    end
}

function HACKS(pid)
    cust:hacks()
end


function Studente(pid)
    -- attendi caricamento
    P(carica)
    -- coda di attesa
    attesa = attesa + 1
    V(carica)
    P(sali)
end

function Bus(pid)
    P(carica)
    occupati = 0
    -- ripeti se ci sono studenti
    -- e se non è tutto occupato
    while attesa > 0 and occupati < 50 do
        V(sali)
        occupati = occupati + 1
        attesa = attesa - 1
    end
    -- parti
    V(carica)
end
