 
resources { go = 0 }
semBin.unico = 1
semBin.S = 0
semBin.A = 0
semBin.mutex = 1
counter = 0

function atleta(pid)
    p(mutex)
    counter = counter + 1
    if counter == 29 then
        v(S)
    end
    v(mutex)
    p(A)
    go()
    v(A)
end

function starter(pid)
    p(unico)
    while true do
        p(S)
        go()
        v(A)
    end
end
