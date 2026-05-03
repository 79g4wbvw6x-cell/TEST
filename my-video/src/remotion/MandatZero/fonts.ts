import { continueRender, delayRender, staticFile } from 'remotion';

let loaded = false;
const handles: ReturnType<typeof delayRender>[] = [];

export const loadLocalFonts = () => {
  if (loaded) return;
  loaded = true;

  const faces = [
    new FontFace('Syne', `url(${staticFile('fonts/Syne-800.woff2')}) format('woff2')`,        { weight: '800', style: 'normal' }),
    new FontFace('Syne', `url(${staticFile('fonts/Syne-800-ext.woff2')}) format('woff2')`,    { weight: '700', style: 'normal' }),
    new FontFace('DMSans', `url(${staticFile('fonts/DMSans-400.woff2')}) format('woff2')`,    { weight: '400', style: 'normal' }),
    new FontFace('DMSans', `url(${staticFile('fonts/DMSans-400-ext.woff2')}) format('woff2')`,{ weight: '500', style: 'normal' }),
    new FontFace('DMSans', `url(${staticFile('fonts/DMSans-700.woff2')}) format('woff2')`,    { weight: '700', style: 'normal' }),
    new FontFace('DMSans', `url(${staticFile('fonts/DMSans-700-ext.woff2')}) format('woff2')`,{ weight: '800', style: 'normal' }),
  ];

  const h = delayRender('Loading fonts');
  handles.push(h);

  Promise.all(faces.map((f) => f.load())).then((loaded) => {
    loaded.forEach((f) => document.fonts.add(f));
    handles.forEach((hh) => continueRender(hh));
  });
};

export const SYNE   = "'Syne', 'Arial Black', sans-serif";
export const DM     = "'DMSans', 'Arial', sans-serif";
