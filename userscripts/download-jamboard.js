// ==UserScript==
// @name     Jamboard download
// @version  1
// @match    https://jamboard.google.com/d/*
// @run-at   document-idle
// @grant    unsafeWindow
// ==/UserScript==


let body = document.getElementsByTagName('body')[0];

//'translateX(-320.657px) translateY(1338.53px) rotate(-0.29rad) scale(0.291)'
let numex = /[\-0-9\.]+/g;
let urlex = /"(https?[^"]+)"/g;


function num(txt) {
  return Number(txt.match(numex)[0]);
}

function hook(el, evt) {
  return new Promise((resolve, reject) => {
    el.addEventListener(evt, () => resolve(el));
    el.addEventListener('error', reject);
  });
}

function evade(img, src) {
  img.crossOrigin = 'anonymous';  // rules evasion
  img.src = src + '#anon';  // reload image
  return hook(img, 'load');
}

async function draw(ctx, el, func) {
  let sty = el.parentElement.style;
  let sz = [num(sty.width)/2, num(sty.height)/2];
  let tr = sty.transform;
  let t = Array.from(tr.matchAll(numex), m => num(m[0]));
  let sc = 2;  // canvas=2K, viewport=1080p
  //console.log(t);
  
  // paint images on 
  //ctx2.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
  ctx.save();
  ctx.scale(1/sc, 1/sc);
  ctx.translate(sz[0], sz[1]);
  ctx.translate(t[0], t[1]);
  ctx.rotate(t[2]);
  ctx.scale(t[3], t[3]);
  await func(sz);
  ctx.restore();
}

async function drawimg(ctx, img) {
  await draw(ctx, img, async function (sz) {
    // paint at origin, with known size
    ctx.drawImage(img, -sz[0], -sz[1], sz[0]*2, sz[1]*2);
  });
}

async function drawsvg(ctx, svg) {
  await draw(ctx, svg, async function (sz) {
    let svgURL = new XMLSerializer().serializeToString(svg);
    let img = new Image();
    img.src = 'data:image/svg+xml; charset=utf8, ' + encodeURIComponent(svgURL);
    await hook(img, 'load');
    ctx.drawImage(img, -sz[0], -sz[1], sz[0]*2, sz[1]*2);
  });
}

async function drawtxt(ctx, txt) {
  await draw(ctx, txt, async function (sz) {
    let h = num(txt.style.lineHeight)/2;
    ctx.font = txt.style.fontSize + ' ' + (txt.style.fontFamily || 'Roboto');
    ctx.textAlign = txt.style.textAlign;
    ctx.fillText(txt.value, -sz[0], sz[1] - h);
  });
}

function drawbg(ctx, img) {
  let pat = ctx.createPattern(img, 'repeat');
  ctx.fillStyle = pat;
  ctx.rect(0, 0, ctx.canvas.width, ctx.canvas.height);
  ctx.fill();
}


async function bake(page) {
  let canvas = page.getElementsByClassName('jam-drawing-element-canvas')[0];
  let ctx = canvas.getContext('2d');
  ctx.globalCompositeOperation = 'destination-over';  // draw behind existing canvas
  
  console.log('evade images');
  let images = Array.from(page.getElementsByTagName('img'));
  await Promise.all(images.map(img => evade(img, img.src)));
  
  let elements = Array.from(page.getElementsByClassName('jam-element'));
  for (let el of elements) {
    if (el.classList.contains('jam-drawing-element')) {
      // skip
      
    } else if (el.classList.contains('jam-image-element')) {
      let img = el.getElementsByTagName('img')[0];
      await drawimg(ctx, img);
      img.style.visibility = 'hidden';
      
    } else if (el.classList.contains('jam-shape-element')) {
      let svg = el.getElementsByTagName('svg')[0];
      //await drawsvg(ctx, svg);
      //svg.style.visibility = 'hidden';
      console.log('warning: shapes are broken');
      
    } else if (el.classList.contains('jam-textbox-element')) {
      let txt = el.getElementsByTagName('textarea')[0];
      await drawtxt(ctx, txt);
      txt.style.visibility = 'hidden';
    
    } else {
      console.log('warning: unknown element kind', el.classList);
    }
  }
  
  console.log('drawing bg');
  let bg = page.getElementsByClassName('jam-frame-content')[0];
  let bgimg = document.createElement('img');
  let bgurl = Array.from(window.getComputedStyle(bg).backgroundImage.matchAll(urlex), m=>m[1])[0];
  console.log(bgurl);
  await evade(bgimg, bgurl);
  drawbg(ctx, bgimg);
  
  return canvas;
}

function download(canvas, num) {
  let link = document.createElement('a');
  link.download = 'page ' + num + '.png';
  link.href = canvas.toDataURL();
  link.click();
}

async function download_all() {
  let view = document.getElementsByClassName('jam-track')[0];
  let pages = view.getElementsByClassName('jam-frame');
  let active = view.getElementsByClassName('jam-frame-active')[0];
  pages = Array.from(pages);
  //await download(active, pages.indexOf(active)+1); return;
  
  let count = 0;
  for (let p of pages) {
    ++count;
    console.log('page', count);
    let canvas = await bake(p);
    download(canvas, count);
  }
}


let btn = document.createElement('input');
btn.type='button';
btn.value='Download all pages as PNG';
btn.addEventListener('click', (event) => {
  download_all();
})

document.getElementsByClassName('jam-bar-right-menu')[0].appendChild(btn);
