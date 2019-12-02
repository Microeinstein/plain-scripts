--[[
Si consideri un sistema per la creazione di molecole d'acqua su cui confluiscono un flusso di atomi di ossigeno e un
flusso di atomi di idrogeno. Per creare una molecola d'acqua (H20) è necessario combinare due atomi di idrogeno (H)
e un atomo di ossigeno (O). Per una corretta creazione di una sequenza di molecole d'acqua, è necessario pertanto
realizzare una barriera che sincronizzi i due flussi di atomi. Non appena un atomo supera la barriera, egli invoca il
metodo crea_legame() per unirsi agli altri atomi necessari per creare la molecola d'acqua. È necessario garantire che i
tre atomi che compongono una molecola abbiano chiamato il metodo crea_legame() prima che lo stesso metodo venga
invocato dagli atomi che comporranno la molecola successiva.

Si utilizzino i semafori per sincronizzare correttamente i due flussi di atomi in modo da creare una sequenza di molecole
d'acqua.

Suggerimento: se esaminiamo la sequenza di invocazioni del metodo crea-legame() e la dividiamo a sottogruppi di 3
invocazioni, ogni gruppo deve contenere due chiamate dall'idrogeno e una dall'ossigeno. Non ha importanza l'ordine.

Una sequenza di invocazione corretta potrebbe essere: OHH | HHO | HOH | ...
Una sequenza di invocazione non corretta è invece: OHH | HHH | OOH | ...
]]
--Questa soluzione non funziona, va in deadlock
resources { crea_legame = 1 }
semInt.edit = 1
semBin.wh = 0
semBin.wo = 0
count = 3
hydro = 2
oxy   = 1

function idrogeno(pid)
    P(edit)
    if hydro == 0 then
        V(edit)
        P(wh)
        P(edit)
    end
    crea_legame()
    hydro = hydro - 1
    count = count - 1
    if count == 0 then
        count = 3
        hydro = 2
        oxy   = 1
        V(wo)
        V(wh)
        P(wo)
        P(wh)
    end
    V(edit)
end

function ossigeno(pid)
    P(edit)
    if oxy == 0 then
        V(edit)
        P(wo)
        P(edit)
    end
    crea_legame()
    oxy = oxy - 1
    count = count - 1
    if count == 0 then
        count = 3
        hydro = 2
        oxy   = 1
        V(wh)
        V(wo)
        P(wh)
        P(wo)
    end
    V(edit)
end

