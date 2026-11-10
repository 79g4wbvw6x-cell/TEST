// Génère le cahier de séance à partir de la feuille de style du dossier.
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const d = __dirname, dos = path.join(d, '..', 'dossier');
const foot = '<div class="foot"><span>Mandat Zéro · Cahier de séance</span><span class="n"></span></div>';
const html = fs.readFileSync(path.join(dos, 'head.html'), 'utf8') + fs.readFileSync(path.join(d, 'body.html'), 'utf8').replace(/<!--F-->/g, foot) + '</body></html>';
const out = path.join(dos, 'seance.html'); fs.writeFileSync(out, html);
(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  await p.goto('file://' + out); await p.evaluate(() => document.fonts.ready);
  console.log(await p.evaluate(() => [...document.querySelectorAll('.page')].map((s, i) => { const f = s.querySelector('.foot'); const lim = f ? f.getBoundingClientRect().top : 0; let m = 0; s.querySelectorAll(':scope > *:not(.foot)').forEach(e => m = Math.max(m, e.getBoundingClientRect().bottom)); return `p${i + 1}:${Math.round(lim - m)}`; }).join(' ')));
  await p.pdf({ path: path.join(d, '..', 'MANDAT-ZERO-Cahier-de-seance.pdf'), format: 'A4', printBackground: true, preferCSSPageSize: true });
  await b.close();
})();
