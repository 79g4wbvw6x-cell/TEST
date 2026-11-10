// Génère le recueil des textes (mise en page continue, pied de page automatique).
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const d = __dirname, r = f => fs.readFileSync(path.join(d, f), 'utf8');
// Les textes et leurs articles sont renumérotés automatiquement.
let n = 0;
const body = (r('t1.html') + r('t2.html') + r('t3.html')).split('<div class="texte">').map((part, i) => {
  if (i === 0) return part; n++; let a = 0;
  return part.replace(/<div class="kicker">Texte \d+<\/div>/, `<div class="kicker">Texte ${n}</div>`).replace(/Article \d+ ·/g, () => `Article ${++a} ·`);
}).join('<div class="texte">');
fs.writeFileSync(path.join(d, 'textes.html'), r('head.html') + body + r('tail.html'));
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage();
  await p.goto('file://' + path.join(d, 'textes.html'));
  await p.evaluate(() => document.fonts.ready);
  await p.pdf({
    path: path.join(d, '..', 'MANDAT-ZERO-Recueil-des-textes.pdf'), format: 'A4', printBackground: true, preferCSSPageSize: true,
    displayHeaderFooter: true, headerTemplate: '<span></span>',
    footerTemplate: '<div style="width:100%;padding:0 19mm;font:7pt Arial,sans-serif;letter-spacing:.1em;color:#6F6A5C;display:flex;justify-content:space-between"><span>MANDAT ZÉRO · RECUEIL DES TEXTES · MODÈLES À FAIRE RELIRE</span><span class="pageNumber"></span></div>',
  });
  await b.close();
})();
