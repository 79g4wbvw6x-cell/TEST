// Génère le recueil des textes (mise en page continue, pied de page automatique).
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const d = __dirname, r = f => fs.readFileSync(path.join(d, f), 'utf8');
fs.writeFileSync(path.join(d, 'textes.html'), r('head.html') + r('t1.html') + r('t2.html') + r('t3.html') + r('tail.html'));
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
