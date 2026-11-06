// usage: node render.cjs <outdir> <w> <h> <fps|stills> [t1,t2,...]
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
const ROOT = __dirname;
const [outDir, w, h, mode, list] = process.argv.slice(2);
fs.mkdirSync(outDir, { recursive: true });
(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
  const page = await browser.newPage({ viewport: { width: +w, height: +h } });
  page.on('console', m => { if (m.type() === 'error' || m.type() === 'warning') console.log('[page]', m.text()); });
  page.on('pageerror', e => console.log('[pageerror]', e.message));
  await page.route('**/*', async route => {
    const url = route.request().url();
    let file = null;
    const m = url.match(/three@0\.170\.0\/(.*)$/);
    if (m) file = path.join(ROOT, 'node_modules/three', m[1]);
    else if (url.startsWith('http://local.test/')) file = path.join(ROOT, url.replace('http://local.test/', '').split('?')[0]);
    if (!file) return route.abort();
    const body = fs.readFileSync(file);
    const ct = file.endsWith('.js') ? 'text/javascript' : 'text/html';
    const wrap = file.endsWith('.html') ? Buffer.concat([Buffer.from('<!doctype html><html><head><meta charset="utf-8"></head><body style="margin:0">'), body]) : body;
    route.fulfill({ body: wrap, contentType: ct });
  });
  await page.goto(`http://local.test/index.html?render=1&w=${w}&h=${h}`);
  await page.waitForFunction(() => window.__ready, null, { timeout: 120000 });
  const dur = await page.evaluate(() => window.__duration);
  const times = mode === 'stills' ? list.split(',').map(Number) : Array.from({ length: Math.floor(dur * +mode) + 1 }, (_, i) => i / +mode);
  const t0 = Date.now();
  for (let i = 0; i < times.length; i++) {
    const data = await page.evaluate(t => { window.__frame(t); return document.querySelector('canvas').toDataURL('image/jpeg', 0.93); }, times[i]);
    fs.writeFileSync(path.join(outDir, mode === 'stills' ? `s_${times[i]}.jpg` : `f_${String(i).padStart(5, '0')}.jpg`), Buffer.from(data.split(',')[1], 'base64'));
    if (i % 25 === 0 || i === times.length - 1) console.log(`frame ${i}/${times.length} ${((Date.now() - t0) / (i + 1) / 1000).toFixed(2)}s/frame`);
  }
  await browser.close();
})();
