// Assemble les pages, génère le PDF et les fichiers de logo.
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const d = __dirname, r = f => fs.readFileSync(path.join(d, f), 'utf8');
const ORDER = ['COVER', 'ESSENTIEL', 'PROMESSE', 'A1 BOUCLE', 'A2 MISSIONS', 'A3 DECISIONS', 'A4 RECOMPENSES', 'A5 EQUIPE', 'A6 SIEGE', 'A7 POINTS', 'A8 RETOUR', 'A9 TEST',
  'SAISON', '7 348', '8 SOMMET', '10 PARTENAIRES GAINS', '11 APOLITIQUE', 'GOUVERNANCE', 'QUI VOIR LOCAL', 'QUI VOIR', '14 SCRIPTS', '15 BUDGET SOMMET', 'BUDGET GLOBAL',
  '17 CALENDRIER', '18 PLAN 90 JOURS', '19 RISQUES', '20 IDENTITE 1', '21 IDENTITE 2', 'JEUDI'];
const src = ['p1.html', 'p2.html', 'p3.html', ...fs.readdirSync(path.join(d, 'new')).sort().map(f => 'new/' + f)].map(r).join('\n');
const secs = {};
for (const m of src.matchAll(/<!-- ([^>]+?) -->\s*(<section[\s\S]*?<\/section>)/g)) secs[m[1]] = m[2]; // les fichiers de new/ remplacent les anciens
const miss = ORDER.filter(k => !secs[k]); if (miss.length) throw new Error('sections manquantes: ' + miss);
const foot = '<div class="foot"><span>Mandat Zéro · Dossier de lancement</span><span class="n"></span></div>';
let i = 0;
let body = ORDER.map(k => secs[k]).join('\n\n')
  .replace(/<!--F-->/g, foot)
  .replace(/<div class="kicker">\d+ — /g, () => `<div class="kicker">${String(++i).padStart(2, '0')} — `)
  .replace(/\[\[p:([^\]]+)\]\]/g, (_, n) => { const j = ORDER.findIndex(k => k === n || k.endsWith(' ' + n)); if (j < 0) throw new Error('renvoi inconnu ' + n); return String(j + 1); });
fs.writeFileSync(path.join(d, 'dossier.html'), r('head.html') + body + r('tail.html'));
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage();
  await p.goto('file://' + path.join(d, 'dossier.html'));
  await p.evaluate(() => document.fonts.ready);
  const rep = await p.evaluate(() => [...document.querySelectorAll('.page')].map((s, i) => {
    const f = s.querySelector('.foot'); const lim = f ? f.getBoundingClientRect().top : s.getBoundingClientRect().bottom;
    let m = 0; s.querySelectorAll(':scope > *:not(.foot):not(.meta)').forEach(e => { m = Math.max(m, e.getBoundingClientRect().bottom); });
    return `p${i + 1}:${Math.round(lim - m)}`;
  }));
  console.log(rep.join(' '));
  await p.pdf({ path: path.join(d, '..', 'MANDAT-ZERO-Dossier-de-lancement.pdf'), format: 'A4', printBackground: true, preferCSSPageSize: true });
  await b.close();
})();
