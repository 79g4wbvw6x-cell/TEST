const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage();
  await p.goto('file://' + path.resolve(__dirname, 'concept.html'));
  await p.evaluate(() => document.fonts.ready);
  const over = await p.evaluate(() => [...document.querySelectorAll('.page')].map((s, i) => {
    const foot = s.querySelector('.foot'); const limit = foot ? foot.getBoundingClientRect().top : s.getBoundingClientRect().bottom;
    let max = 0; s.querySelectorAll(':scope > *:not(.foot):not(.meta):not(.slash)').forEach(e => { max = Math.max(max, e.getBoundingClientRect().bottom); });
    return `p${i + 1}: free ${Math.round(limit - max)}px`;
  }));
  console.log(over.join('\n'));
  await p.pdf({ path: path.resolve(__dirname, '../MANDAT-ZERO-Concept-v2.pdf'), format: 'A4', printBackground: true, preferCSSPageSize: true });
  await b.close();
})();
