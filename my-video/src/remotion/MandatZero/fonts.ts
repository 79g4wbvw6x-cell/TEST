import { continueRender, delayRender, staticFile } from 'remotion';

let fontHandleBebas: ReturnType<typeof delayRender> | null = null;
let fontHandleInter: ReturnType<typeof delayRender> | null = null;
let loaded = false;

export const loadLocalFonts = () => {
  if (loaded) return;
  loaded = true;

  fontHandleBebas = delayRender('Loading BebasNeue font');
  fontHandleInter = delayRender('Loading Inter font');

  const bebas = new FontFace(
    'BebasNeue',
    `url(${staticFile('fonts/BebasNeue.woff2')}) format('woff2'),
     url(${staticFile('fonts/BebasNeue-latin-ext.woff2')}) format('woff2')`,
    { weight: '400', style: 'normal' },
  );

  const interReg = new FontFace(
    'Inter',
    `url(${staticFile('fonts/Inter-Regular.woff2')}) format('woff2')`,
    { weight: '400', style: 'normal' },
  );

  const interBold = new FontFace(
    'Inter',
    `url(${staticFile('fonts/Inter-700.woff2')}) format('woff2')`,
    { weight: '700', style: 'normal' },
  );

  Promise.all([bebas.load(), interReg.load(), interBold.load()]).then((fonts) => {
    fonts.forEach((f) => document.fonts.add(f));
    if (fontHandleBebas) continueRender(fontHandleBebas);
    if (fontHandleInter) continueRender(fontHandleInter);
  });
};

export const BEBAS = 'BebasNeue, Arial Black, sans-serif';
export const INTER = 'Inter, Arial, sans-serif';
