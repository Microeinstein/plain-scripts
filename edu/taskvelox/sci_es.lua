--[[
Un gruppo composto da m ragazzi si reca in montagna per festeggiare il superamento dell’esame di sistemi operativi.
Alcuni ragazzi vogliono imparare a sciare e si rivolgono a una scuola di sci. Sfortunatamente ci sono solo n maestri
di sci disponibili (n < m), pertanto sono obbligati a sciare a turno, in quanto non sono previste lezioni di gruppo,
ma solo individuali. I ragazzi senza maestro prendono il sole di fronte alla baita attendendo che si liberi un maestro,
mentre gli altri sciano. Chi scia lo può fare finchè ne ha voglia. Quando un ragazzo smette di sciare il corrispondente
maestro diventa libero per un’altra lezione. Se nessuno vuole prendere lezione di sci, i maestri liberi si mettono dentro
alla baita a leggere in attesa di qualcuno che voglia sciare. Fornire una soluzione che usi i semafori per sincronizzare
ragazzi e maestri.
]]

resources { legge = 0, scia = 0 }
semBin.mutex = 1
semBin.maestri = 0
stato_maestri = {}
n_studenti = 0

function maestro(pid)
    legge()
    stato_maestri[pid] = 0
    p(maestri)
    p(mutex)
    n_studenti = n_studenti - 1
    v(mutex)
    scia()
    p(mutex)
    stato_maestri[pid] = nil
    v(mutex)
    v(maestri)
end

function studente(pid)
    p(mutex)
    n_studenti = n_studenti + 1
    for m,s in pairs(stato_maestri) do
        if s == 0 then
            stato_maestri[m] = 1
            scia()
            v(mutex)
            v(maestri)
        else
            v(mutex)
        end
    end
end
