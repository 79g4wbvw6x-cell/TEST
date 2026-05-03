import React from 'react';
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from 'remotion';
import { loadLocalFonts, SYNE } from './fonts';
import { BG, NAVY, ORANGE } from './constants';
import { CharReveal, ic, sp, OrangeLine } from './atoms';

loadLocalFonts();

const LEFT_WORDS  = ['LE RÉSEAU.',  'LE PISTON.', 'LE NOM.'];
const RIGHT_WORDS = ['LE MÉRITE.',  "L'ACTION.",  'LE TALENT.'];

// ── Strikethrough line that draws across text ─────────────────────────────────
const StrikeThrough: React.FC<{ startFrame: number; width: number }> = ({ startFrame, width }) => {
  const frame = useCurrentFrame();
  const w = ic(frame, [startFrame, startFrame + 12], [0, width]);
  return (
    <div style={{
      position: 'absolute',
      top: '52%',
      left: 0,
      width: w,
      height: 4,
      backgroundColor: ORANGE,
      borderRadius: 2,
    }} />
  );
};

export const SolutionSplit: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  // Left + right halves slide in from their sides (0-20 frames)
  const slideS = sp(frame, fps, 0, 16, 140);
  const leftX  = ic(slideS, [0, 1], [-540, 0]);
  const rightX = ic(slideS, [0, 1], [540, 0]);

  // Collapse at frame 110 → flash at 116 → "UNE SEULE RÈGLE." from 120
  const collapseS  = sp(frame, fps, 108, 14, 180);
  const collapseX  = ic(collapseS, [0, 1], [0, 540]);  // both sides move to center
  const flash      = interpolate(frame, [114, 116, 118, 122], [0, 1, 0.5, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const finalOp    = ic(frame, [120, 130], [0, 1]);

  // Left words: appear at 20, 38, 56
  // Right words: appear at 28, 46, 64
  const leftDelays  = [20, 38, 56];
  const rightDelays = [28, 46, 64];
  const strikeDelays= [30, 48, 66];

  const splitVisible = ic(frame, [108, 116], [1, 0]);

  return (
    <AbsoluteFill style={{ backgroundColor: BG }}>
      {/* Flash */}
      <AbsoluteFill style={{ backgroundColor: ORANGE, opacity: flash, zIndex: 20, pointerEvents: 'none' }} />

      {/* UNE SEULE RÈGLE. — final state */}
      <AbsoluteFill style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: finalOp, zIndex: 10 }}>
        <div style={{ textAlign: 'center', width: 1080 }}>
          <div style={{ fontFamily: SYNE, fontSize: 96, fontWeight: 800, color: NAVY, letterSpacing: '-1px', lineHeight: 1.1 }}>
            <div style={{ whiteSpace: 'nowrap' }}><CharReveal text="UNE SEULE" startFrame={120} framesPerChar={1} /></div>
            <div style={{ whiteSpace: 'nowrap' }}><CharReveal text="RÈGLE." startFrame={129} framesPerChar={1} /></div>
          </div>
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <OrangeLine startFrame={138} width={520} />
          </div>
        </div>
      </AbsoluteFill>

      {/* Split layout */}
      <AbsoluteFill style={{ opacity: splitVisible }}>
        {/* Orange divider at center */}
        <div style={{
          position: 'absolute',
          left: 540 - 1.5,
          top: 0,
          bottom: 0,
          width: 3,
          backgroundColor: ORANGE,
          opacity: slideS,
        }} />

        {/* LEFT half — navy bg */}
        <div style={{
          position: 'absolute',
          left: 0,
          top: 0,
          width: 540,
          bottom: 0,
          backgroundColor: NAVY,
          transform: `translateX(${leftX - collapseX}px)`,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'flex-start',
          justifyContent: 'center',
          paddingLeft: 60,
          paddingRight: 40,
          gap: 36,
          overflow: 'hidden',
        }}>
          {LEFT_WORDS.map((w, i) => {
            const wS = sp(frame, fps, leftDelays[i], 18, 200);
            const wX = ic(wS, [0, 1], [-60, 0]);
            const textW = 36 + w.length * 22; // rough estimate
            return (
              <div key={i} style={{ opacity: wS, transform: `translateX(${wX}px)`, position: 'relative' }}>
                <div style={{ fontFamily: SYNE, fontSize: 52, fontWeight: 800, color: '#FFFFFF', lineHeight: 1, whiteSpace: 'nowrap' }}>
                  {w}
                </div>
                <StrikeThrough startFrame={strikeDelays[i]} width={textW} />
              </div>
            );
          })}
        </div>

        {/* RIGHT half — white bg */}
        <div style={{
          position: 'absolute',
          left: 540,
          top: 0,
          width: 540,
          bottom: 0,
          backgroundColor: BG,
          transform: `translateX(${rightX + collapseX}px)`,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'flex-start',
          justifyContent: 'center',
          paddingLeft: 40,
          paddingRight: 60,
          gap: 36,
          overflow: 'hidden',
        }}>
          {RIGHT_WORDS.map((w, i) => {
            const wS  = sp(frame, fps, rightDelays[i], 8, 300);
            const wSc = interpolate(wS, [0, 0.6, 1], [0.7, 1.12, 1.0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
            return (
              <div key={i} style={{ opacity: wS, transform: `scale(${wSc})`, transformOrigin: 'left center' }}>
                <div style={{ fontFamily: SYNE, fontSize: 52, fontWeight: 800, color: NAVY, lineHeight: 1, whiteSpace: 'nowrap' }}>
                  {w}
                </div>
              </div>
            );
          })}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
