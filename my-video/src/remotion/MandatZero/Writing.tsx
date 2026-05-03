import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from 'remotion';
import { loadLocalFonts, SYNE, DM } from './fonts';
import { BG, NAVY, ORANGE, GRAY } from './constants';
import { ic, sp, SceneWrap, OrangeLine } from './atoms';

loadLocalFonts();

// Blinking cursor component
const Cursor: React.FC = () => {
  const frame = useCurrentFrame();
  const opacity = Math.floor(frame / 15) % 2 === 0 ? 1 : 0;
  return <span style={{ opacity, color: ORANGE, fontWeight: 400 }}>|</span>;
};

// Line-by-line content of the editor
const EDITOR_LINES = [
  { label: 'I. Diagnostic', isTitle: true, delay: 30 },
  { label: 'Les communes de moins de 20 000 habitants concentrent 62 %', isTitle: false, delay: 46 },
  { label: "de la surface agricole utile. Trois leviers se distinguent...", isTitle: false, delay: 56 },
  { label: 'II. Recommandations', isTitle: true, delay: 72 },
  { label: '(1) Mutualisation intercommunale du versement,', isTitle: false, delay: 86 },
  { label: '(2) fonds vert décentralisé adossé à la fiscalité locale,', isTitle: false, delay: 96 },
  { label: '(3) PPP encadrés par', isTitle: false, delay: 106 }, // cursor appears at end
];

export const Writing: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  // Word counter
  const wc =
    frame < 20 ? 0 :
    frame < 55 ? Math.round(ic(frame, [20, 55], [0, 247])) :
    frame < 80 ? Math.round(ic(frame, [55, 80], [247, 891])) :
                 Math.round(ic(frame, [80, 110], [891, 1247]));

  // Submit button pulse at frame 115
  const btnPulse = 1 + Math.sin(Math.max(0, frame - 115) * 0.18) * 0.025;
  const btnGlow  = Math.max(0, (frame - 115) / 30);

  const phoneS = sp(frame, fps, 0, 14, 120);
  const phoneY = ic(phoneS, [0, 1], [300, 0]);

  // Orange pulse circle outside the phone
  const circleScale = 0.95 + Math.sin(frame * 0.08) * 0.05;

  return (
    <SceneWrap dur={150} bg={BG}>
      {/* Pulsing bg circle */}
      <div style={{
        position: 'absolute',
        right: -80,
        top: '30%',
        width: 200,
        height: 200,
        borderRadius: '50%',
        backgroundColor: ORANGE,
        opacity: 0.08,
        transform: `scale(${circleScale})`,
      }} />

      <AbsoluteFill style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-start', paddingTop: 120, gap: 32 }}>
        {/* Scene title */}
        <div style={{ opacity: sp(frame, fps, 0, 20, 200), textAlign: 'center' }}>
          <div style={{ fontFamily: SYNE, fontSize: 30, fontWeight: 800, color: ORANGE, letterSpacing: '8px' }}>EN ACTION</div>
          <div style={{ fontFamily: SYNE, fontSize: 64, fontWeight: 800, color: NAVY, lineHeight: 1 }}>LA RÉDACTION</div>
          <OrangeLine startFrame={4} width={360} />
        </div>

        {/* Phone */}
        <div style={{
          transform: `translateY(${phoneY}px)`,
          width: 340,
          height: 680,
          backgroundColor: '#FFFFFF',
          borderRadius: 44,
          border: `2px solid ${NAVY}18`,
          boxShadow: `0 32px 80px rgba(27,42,74,0.15)`,
          overflow: 'hidden',
          position: 'relative',
          flexShrink: 0,
        }}>
          {/* Dynamic island */}
          <div style={{ position: 'absolute', top: 14, left: '50%', transform: 'translateX(-50%)', width: 88, height: 26, backgroundColor: '#000', borderRadius: 13, zIndex: 10 }} />

          {/* Screen content */}
          <div style={{ height: '100%', paddingTop: 50, display: 'flex', flexDirection: 'column' }}>
            {/* Nav bar */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 16px', borderBottom: `1px solid ${NAVY}10` }}>
              <div style={{ fontFamily: DM, fontSize: 11, color: GRAY }}>Annuler</div>
              <div style={{ fontFamily: DM, fontSize: 11, color: NAVY, fontWeight: 600 }}>Brouillon · Auto</div>
              <div style={{ fontFamily: DM, fontSize: 11, color: ORANGE, fontWeight: 700 }}>Aperçu</div>
            </div>

            {/* Mission badge */}
            <div style={{ padding: '12px 16px 0' }}>
              <div style={{
                display: 'inline-block',
                backgroundColor: `${ORANGE}18`,
                borderRadius: 6,
                padding: '3px 10px',
                fontFamily: DM,
                fontSize: 10,
                fontWeight: 700,
                color: ORANGE,
                letterSpacing: '1px',
              }}>
                MISSION #M-247
              </div>

              {/* Title */}
              <div style={{ fontFamily: SYNE, fontSize: 17, fontWeight: 800, color: NAVY, marginTop: 8, lineHeight: 1.3 }}>
                Note · Transition agricole
              </div>

              {/* Word counter */}
              <div style={{ fontFamily: DM, fontSize: 10, color: GRAY, marginTop: 4 }}>
                {wc} mots · enregistré il y a 3s
              </div>
            </div>

            {/* Editor body */}
            <div style={{ flex: 1, padding: '12px 16px', overflowY: 'hidden' }}>
              {EDITOR_LINES.map((line, i) => {
                const lineS = sp(frame, fps, line.delay, 22, 280);
                const lineY = ic(lineS, [0, 1], [12, 0]);
                const isLast = i === EDITOR_LINES.length - 1;
                return (
                  <div key={i} style={{
                    opacity: lineS,
                    transform: `translateY(${lineY}px)`,
                    fontFamily: line.isTitle ? SYNE : DM,
                    fontSize: line.isTitle ? 12 : 10,
                    fontWeight: line.isTitle ? 800 : 400,
                    color: line.isTitle ? NAVY : GRAY,
                    marginBottom: line.isTitle ? 6 : 3,
                    marginTop: line.isTitle && i > 0 ? 10 : 0,
                    lineHeight: 1.5,
                  }}>
                    {line.label}{isLast && <Cursor />}
                  </div>
                );
              })}
            </div>

            {/* Toolbar */}
            <div style={{
              borderTop: `1px solid ${NAVY}10`,
              padding: '8px 16px',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              opacity: ic(frame, [100, 116], [0, 1]),
            }}>
              <div style={{ display: 'flex', gap: 14 }}>
                {['B', 'I', 'U', '¶', '↩'].map((ch, i) => (
                  <div key={i} style={{ fontFamily: DM, fontSize: 14, color: GRAY, fontWeight: ch === 'B' ? 700 : 400 }}>{ch}</div>
                ))}
              </div>
              <div style={{ fontFamily: DM, fontSize: 10, color: GRAY }}>Sources · 4</div>
            </div>

            {/* Submit button */}
            <div style={{
              margin: '0 16px 16px',
              backgroundColor: ORANGE,
              borderRadius: 14,
              padding: '14px',
              textAlign: 'center',
              transform: `scale(${btnPulse})`,
              boxShadow: `0 ${8 + btnGlow * 8}px ${20 + btnGlow * 20}px ${ORANGE}${Math.round(btnGlow * 55).toString(16).padStart(2, '0')}`,
              opacity: ic(frame, [108, 120], [0, 1]),
            }}>
              <div style={{ fontFamily: SYNE, fontSize: 14, fontWeight: 800, color: '#fff' }}>
                Soumettre · +80 pts
              </div>
            </div>
          </div>
        </div>
      </AbsoluteFill>
    </SceneWrap>
  );
};
