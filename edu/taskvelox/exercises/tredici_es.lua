resources { processR = 0 }
semBin.single1 = 1
semBin.single2 = 1
semBin.caricamento = 1
semInt.allocabile = 7 --N

function P1(pid)
  P(single1)
  while true do
    P(caricamento)
    for i=1, 5 do --N1
      P(allocabile)
    end
    V(caricamento)
    processR()
    for i=1, 5 do --N1
      V(allocabile)
    end
  end
end

function P2(pid)
  P(single2)
  while true do
    P(caricamento)
    for i=1, 7 do --N2
      P(allocabile)
    end
    V(caricamento)
    processR()
    for i=1, 7 do --N2
      V(allocabile)
    end
  end
end

