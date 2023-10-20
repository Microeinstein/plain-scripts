// ==UserScript==
// @name     UniVR questionari semplici
// @version  1
// @grant    https://univr.esse3.cineca.it/questionari/*
// ==/UserScript==


let HTMLElementPrototype = document.body.__proto__.__proto__

HTMLElementPrototype.ch = function(indexes) {
  indexes = Object.values(arguments)//.slice(1,)
  let node = this
  for (let i of indexes) {
    node = node.childNodes[i]
  }
  return node
}

HTMLElementPrototype.lbl = function(txt) {
  this.ch(0,1).data = txt
}

HTMLElementPrototype.follow = function(node) {
  this.parentNode.insertBefore(node, this)
  this.parentNode.insertBefore(this, node)
}



function better_50(node) {
  node.ch(2,0,1).data = ">= 50%"
  node.ch(3,0,1).data = "< 50%"
}

function better_yn(node) {
  node.ch(2,1).data = "Sì"
  node.ch(3,1).data = "No"
}

function better_gradient(node) {
  n2 = node.ch(2); n2.lbl("➖➖      ")
  n3 = node.ch(3); n3.lbl("➖       ")
  n4 = node.ch(4); n4.lbl("➕       ")
  n5 = node.ch(5); n5.lbl("➕➕      ")
  n6 = node.ch(6); n6.lbl("(blank)    ")
  n5.follow(n4)
  n4.follow(n6)
  n6.follow(n3)
  n3.follow(n2)
}

function better_grad_freq(node) {
  better_gradient(node)
  n7 = node.ch(7); n7.lbl("(lezioni non usufruite)")
  n4 = node.ch(4)
  n4.follow(n7)
}

function better_question(qid, txt, ans_mod) {
  let fieldset = document.getElementById(qid)
  if (fieldset === null)
    return
 	fieldset = fieldset.ch(1,1,1,1)
  
  //fieldset.ch(1,0).data = txt + " "
  fieldset.ch(1).innerText = txt + " "
  
  if (ans_mod === undefined)
    return
  ans_mod(fieldset)
}



function better_iter(ans_mod, incr, map) {
  pre_id = "quest_container_domanda_"
  for (let [num, obj] of Object.entries(map)) {
    num = Number(num)
    if (Array.isArray(obj)) {
      for (const txt of obj) {
        console.log(num, txt)
        better_question(pre_id + num, txt, ans_mod)
        num += incr;
      }
    } else {
      better_question(pre_id + num, obj, ans_mod)
    }
  }
}



better_iter(better_50, 1, {
  11984: ["Percentuale lezioni frequentate? (in aula, in streaming, videolezioni)"]
})

better_iter(better_yn, 1, {
  11998: ["Partecipare?"]
})

better_iter(better_gradient, 6, {
	12009: [
    "Conoscenze preliminari sufficienti?",
	  "Crediti proporzionati al carico?",
	  "Materiale didattico adeguato?",
	  "Modalità d'esame chiare?"
  ],
  
	12035: [
    "Orari di lezione rispettati?",
    "Docente stimola interesse verso il corso?",
    "Docente spiega in modo chiaro?",
    "Se presenti, sono stati utili esercitazioni, tutorato, laboratori?",
    "Insegnamento svolto come dichiarato sul sito?",
    "Docente disponibile per chiarimenti?"
  ],
  
  12073: "Docente disponibile per chiarimenti?",
  
	12081: [
    "Interessato agli argomenti?",
    "Soddisfatto del corso?",
  ],
  
  12093: "Soddisfatto del corso?",
})

better_iter(better_grad_freq, 7, {
	12105: [
    "Lezioni duali frequentate in presenza - svolgimento efficace?",
  	"Riuscito a mantenere l'attenzione a lezioni a distanza?",
    "Lezioni frequentate a distanza - interazione efficace?",
    "Lezioni frequentate in diretta (presenza/distanza) - videolezioni consultate comunque?",
    "Lezioni viste solo in differita - pubblicate in tempo?",
    "Lezioni viste solo in differita - interazione garantita?",
  ]
})


for (let chk of Array.from(document.getElementsByClassName('checkbox'))) {
  let txt = chk.ch(0,1)
  txt.data = txt.data.replace(/ - .+/, '')
}
