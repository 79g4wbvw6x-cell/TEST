import React from 'react';
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from 'remotion';
import { loadLocalFonts, SYNE, DM } from './fonts';
import { BG, NAVY, ORANGE, GRAY } from './constants';
import { ic, sp, WordReveal, SceneWrap, OrangeLine } from './atoms';

loadLocalFonts();

// ── Senate dome SVG — drawn with strokeDashoffset ─────────────────────────────
const SenateDome: React.FC<{ progress: number }> = ({ progress }) => {
  // Simplified: semicircle dome + column rectangles + steps
  // Total "virtual" stroke length = 1000 units

  return (
    <svg width={380} height={300} viewBox="0 0 380 300" style={{ display: 'block' }}>
      <defs>
        <style>{`
          .dome-path { fill: none; stroke: ${NAVY}; stroke-width: 3; stroke-linecap: round; }
        `}</style>
      </defs>

      {/* Dome semicircle */}
      <path
        className="dome-path"
        d="M 60 200 A 130 130 0 0 1 320 200"
        strokeDasharray={450}
        strokeDashoffset={450 * (1 - Math.min(progress * 3, 1))}
      />

      {/* Columns */}
      {[80, 115, 150, 185, 220, 255, 290].map((x, i) => {
        const p2 = Math.max(0, Math.min((progress - 0.33) * 3, 1));
        const colH = p2 * 70;
        return <rect key={i} x={x} y={200} width={6} height={colH} fill={NAVY} opacity={0.9} />;
      })}

      {/* Steps */}
      {[0, 1, 2].map((i) => {
        const p3 = Math.max(0, Math.min((progress - 0.66) * 3, 1));
        return (
          <rect key={i}
            x={40 - i * 12}
            y={270 + i * 8}
            width={300 + i * 24}
            height={7}
            fill={NAVY}
            opacity={0.7 * p3}
          />
        );
      })}

      {/* Flagpole */}
      <line
        x1={190} y1={70}
        x2={190} y2={200}
        stroke={NAVY}
        strokeWidth={2}
        opacity={Math.max(0, (progress - 0.5) * 2)}
      />
      <rect
        x={190} y={70}
        width={30} height={20}
        fill={ORANGE}
        opacity={Math.max(0, (progress - 0.6) * 2.5)}
      />
    </svg>
  );
};

// ── Padlock SVG ───────────────────────────────────────────────────────────────
const Padlock: React.FC<{ progress: number }> = ({ progress }) => {
  const p1 = Math.min(progress * 2, 1);
  const p2 = Math.max(0, (progress - 0.5) * 2);
  return (
    <svg width={70} height={80} viewBox="0 0 70 80">
      {/* Body */}
      <rect x={8} y={36} width={54} height={38} rx={6} fill="none" stroke={ORANGE} strokeWidth={3} opacity={p2} />
      {/* Arc (shackle) */}
      <path
        d="M 18 36 L 18 22 A 17 17 0 0 1 52 22 L 52 36"
        fill="none" stroke={ORANGE} strokeWidth={3} strokeLinecap="round"
        strokeDasharray={80}
        strokeDashoffset={80 * (1 - p1)}
      />
      {/* Keyhole */}
      <circle cx={35} cy={58} r={5} fill={ORANGE} opacity={p2} />
      <rect x={32} y={58} width={6} height={9} fill={ORANGE} opacity={p2} />
    </svg>
  );
};

export const Problem: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const dur = 120; // local duration

  const domeProg  = ic(frame, [0, 40], [0, 1]);
  const wordStart = 40;

  const pistonS   = sp(frame, fps, 65, 6, 280, 1);
  const pistonSc  = interpolate(pistonS, [0, 0.7, 1], [0.7, 1.05, 1.0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const lockProg  = ic(frame, [80, 100], [0, 1]);

  const exitSc    = ic(frame, [114, 120], [1, 0.95]);
  const exitOp    = ic(frame, [114, 120], [1, 0]);

  return (
    <SceneWrap dur={dur} bg={BG}>
      <AbsoluteFill style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 60px', gap: 32 }}>
        <div style={{ opacity: exitOp, transform: `scale(${exitSc})`, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 32 }}>

          {/* Senate dome */}
          <SenateDome progress={domeProg} />

          {/* "Le pouvoir politique" word by word */}
          <div style={{ fontFamily: DM, fontSize: 44, color: GRAY, textAlign: 'center', lineHeight: 1.4 }}>
            <WordReveal text="Le pouvoir politique" startFrame={wordStart} framesPerWord={6} />
          </div>

          {/* EST VERROUILLÉ. impact */}
          <div style={{
            transform: `scale(${pistonSc})`,
            opacity: pistonS,
            fontFamily: SYNE,
            fontSize: 88,
            fontWeight: 800,
            color: NAVY,
            textAlign: 'center',
            lineHeight: 1,
            letterSpacing: '-2px',
          }}>
            EST VERROUILLÉ.
          </div>

          <OrangeLine startFrame={70} width={520} />

          {/* Padlock */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 20 }}>
            <Padlock progress={lockProg} />
            <div style={{ fontFamily: DM, fontSize: 36, color: GRAY, fontWeight: 500 }}>
              Pas de mérite.<br />Juste le réseau.
            </div>
          </div>
        </div>
      </AbsoluteFill>
    </SceneWrap>
  );
};
