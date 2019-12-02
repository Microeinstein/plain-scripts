resources { Bagno = 0 }
semBin.bagno = 1
semBin.masc  = 1
semBin.fem   = 1
uomini  = 0
femmine = 0

function Uomo(pid)
    P(masc)
    uomini = uomini + 1
    if uomini == 1 then
        P(bagno)
    end
    V(masc)
    Bagno()
    P(masc)
    uomini = uomini - 1
    if uomini == 0 then
        V(bagno)
    end
    V(masc)
end

function Donna(pid)
    P(fem)
    femmine = femmine + 1
    if femmine == 1 then
        P(bagno)
    end
    V(fem)
    Bagno()
    P(fem)
    femmine = femmine - 1
    if femmine == 0 then
        V(bagno)
    end
    V(fem)
end
