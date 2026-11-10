// Assemble les pages, génère le PDF et les fichiers de logo.
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const d = __dirname, r = f => fs.readFileSync(path.join(d, f), 'utf8');
const foot = '<div class="foot"><span>Mandat Zéro · Dossier de lancement</span><span class="n"></span></div>';
const html = (r('head.html') + r('p1.html') + r('p2.html') + r('p3.html') + r('tail.html')).replace(/<!--F-->/g, foot);
fs.writeFileSync(path.join(d, 'dossier.html'), html); // fichier assemblé, régénéré à chaque build
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage();
  await p.goto('file://' + path.join(d, 'dossier.html'));
  await p.evaluate(() => document.fonts.ready);
  const rep = await p.evaluate(() => [...document.querySelectorAll('.page')].map((s, i) => {
    const f = s.querySelector('.foot'); const lim = f ? f.getBoundingClientRect().top : s.getBoundingClientRect().bottom;
    let m = 0; s.querySelectorAll(':scope > *:not(.foot):not(.meta)').forEach(e => { m = Math.max(m, e.getBoundingClientRect().bottom); });
    let wide = 0; s.querySelectorAll('*').forEach(e => { const q = e.getBoundingClientRect(); if (q.right > s.getBoundingClientRect().right - 40 && q.width > 0 && !e.closest('.cover')) wide++; });
    return `p${i + 1}: ${Math.round(lim - m)}px${wide ? ' WIDE' + wide : ''}`;
  }));
  console.log(rep.join(' | '));
  await p.pdf({ path: path.join(d, '..', 'MANDAT-ZERO-Dossier-de-lancement.pdf'), format: 'A4', printBackground: true, preferCSSPageSize: true });
  // logos
  const brand = path.join(d, '..', 'brand');
  for (const [name, dark] of [['symbole-encre', true], ['symbole-papier', false]])
    fs.writeFileSync(path.join(brand, name + '.svg'), await p.evaluate(k => MZ.logo(k).replace(' style="display:block;width:100%"', ''), dark));
  const q = await b.newPage({ deviceScaleFactor: 4 });
  for (const [name, dark] of [['logo-sur-papier', true], ['logo-sur-encre', false]]) {
    await q.setContent(`<style>@font-face{font-family:IS;src:url('file://${d}/fonts/instrument-serif-latin-400-normal.woff2')}@font-face{font-family:IS;font-style:italic;src:url('file://${d}/fonts/instrument-serif-latin-400-italic.woff2')}
      body{margin:0;background:transparent}#l{display:inline-flex;align-items:center;gap:22px;padding:30px 36px;font:400 96px/1 IS,serif;color:${dark ? '#141B2D' : '#F7F3EA'}}#l i{color:${dark ? '#86661F' : '#D8BC7A'}}#m{width:120px}</style>
      <div id="l"><span id="m"></span><span>Mandat <i>Zéro</i></span></div>`);
    await q.evaluate(([s]) => { document.getElementById('m').innerHTML = s; }, [await p.evaluate(k => MZ.logo(k), dark)]);
    await q.evaluate(() => document.fonts.ready);
    await q.locator('#l').screenshot({ path: path.join(brand, name + '.png'), omitBackground: true });
  }
  await b.close();
})();
