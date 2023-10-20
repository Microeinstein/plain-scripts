resources { passa = 2 }
semInt.peso = 8
semBin.enter = 1
semBin.leave = 1

function Auto(pid)
    P(enter)
    P(peso)
    V(enter)

    passa()

    P(leave)
    V(peso)
    V(leave)
end

function Furgone(pid)
    P(enter)
    P(peso)
    P(peso)
    V(enter)

    passa()

    P(leave)
    V(peso)
    V(peso)
    V(leave)
end
 
