import React, { useMemo } from 'react';
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from 'remotion';
import { loadLocalFonts, SYNE, DM } from './fonts';
import { BG, NAVY, ORANGE } from './constants';
import { sr, ic, sp, OrangeLine } from './atoms';

loadLocalFonts();

// Word collision helper
const CollideWord: React.FC<{
  text: string;
  fromX: number;
  fromY: number;
  delay: number;
  fontSize: number;
  color: string;
}> = ({ text, fromX, fromY, delay, fontSize, color }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = sp(frame, fps, delay, 5, 260);
  const x = ic(s, [0, 1], [fromX, 0]);
  const y = ic(s, [0, 1], [fromY, 0]);
  return (
    <div style={{
      fontFamily: SYNE,
      fontSize,
      fontWeight: 900,
      color,
      lineHeight: 1,
      letterSpacing: '-3px',
      opacity: s,
      transform: `translate(${x}px, ${y}px)`,
      whiteSpace: 'nowrap',
    }}>
      {text}
    </div>
  );
};

// Orbiting dot
const OrbitDot: React.FC<{ idx: number; radius: number; size: number; speed: number; color: string }> = ({ idx, radius, size, speed, color }) => {
  const frame = useCurrentFrame();
  const offset = sr(idx * 3) * Math.PI * 2;
  const angle  = frame * speed + offset;
  const x = Math.cos(angle) * radius;
  const y = Math.sin(angle) * radius;
  return (
    <div style={{
      position: 'absolute',
      width: size,
      height: size,
      borderRadius: '50%',
      backgroundColor: color,
      left: '50%',
      top: '50%',
      transform: `translate(calc(-50% + ${x}px), calc(-50% + ${y}px))`,
      opacity: 0.6,
    }} />
  );
};

export const Final: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  // Phase 1: "FINI LE PISTON." word collision, frames 0-30
  const flash1 = interpolate(frame, [26, 28, 32, 38], [0, 1, 0.6, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Phase 2: "PLACE AU MÉRITE." collision, frames 40-70
  const flash2 = interpolate(frame, [66, 68, 72, 78], [0, 1, 0.6, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Phase 3: Logo + tagline assembly, frames 80+
  const logoS   = sp(frame, fps, 80, 10, 180);
  const taglineS = sp(frame, fps, 100, 18, 200);

  // Logo breathing (from frame 120)
  const breathT = Math.max(0, frame - 120);
  const breathSc = 1 + Math.sin(breathT * 0.04) * 0.018;

  // Orange ring pulse
  const ringScale = 0.9 + Math.sin(breathT * 0.055) * 0.08;
  const ringOp    = 0.12 + Math.sin(breathT * 0.04) * 0.06;

  // Phase visibility
  const phase1Op = ic(frame, [30, 38], [1, 0]);
  const phase2Op = ic(frame, [0, 4], [0, 1]) * ic(frame, [70, 78], [1, 0]);
  const phase3Op = ic(frame, [78, 90], [0, 1]);

  const orbits = useMemo(() => [
    { radius: 220, size: 10, speed: 0.025, color: ORANGE },
    { radius: 280, size: 7,  speed: -0.018, color: NAVY   },
    { radius: 340, size: 5,  speed: 0.013, color: ORANGE  },
    { radius: 180, size: 6,  speed: -0.031, color: NAVY   },
  ], []);

  return (
    <AbsoluteFill style={{ backgroundColor: BG }}>
      {/* Orange flash overlays */}
      <AbsoluteFill style={{ backgroundColor: ORANGE, opacity: flash1, zIndex: 30, pointerEvents: 'none' }} />
      <AbsoluteFill style={{ backgroundColor: ORANGE, opacity: flash2, zIndex: 30, pointerEvents: 'none' }} />

      {/* Phase 1: FINI LE PISTON. */}
      <AbsoluteFill style={{ opacity: phase1Op, display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 10 }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0 }}>
          <div style={{ display: 'flex', gap: 24 }}>
            <CollideWord text="FINI" fromX={-500} fromY={-200} delay={0} fontSize={110} color={NAVY} />
            <CollideWord text="LE"   fromX={500}  fromY={-200} delay={4} fontSize={110} color={NAVY} />
          </div>
          <CollideWord text="PISTON." fromX={0} fromY={600} delay={8} fontSize={110} color={ORANGE} />
        </div>
      </AbsoluteFill>

      {/* Phase 2: PLACE AU MÉRITE. */}
      <AbsoluteFill style={{ opacity: phase2Op, display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 10 }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 0 }}>
          <div style={{ display: 'flex', gap: 24 }}>
            <CollideWord text="PLACE" fromX={-500} fromY={-300} delay={40} fontSize={100} color={NAVY} />
            <CollideWord text="AU"    fromX={500}  fromY={-300} delay={44} fontSize={100} color={NAVY} />
          </div>
          <CollideWord text="MÉRITE." fromX={0} fromY={700} delay={48} fontSize={100} color={ORANGE} />
        </div>
      </AbsoluteFill>

      {/* Phase 3: Logo + breathing */}
      <AbsoluteFill style={{ opacity: phase3Op, display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 10 }}>
        {/* Orbiting dots */}
        {frame > 120 && orbits.map((o, i) => (
          <OrbitDot key={i} idx={i} {...o} />
        ))}

        {/* Pulsing orange ring */}
        <div style={{
          position: 'absolute',
          width: 320,
          height: 320,
          borderRadius: '50%',
          border: `3px solid ${ORANGE}`,
          transform: `scale(${ringScale})`,
          opacity: ringOp,
        }} />

        {/* Logo block */}
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          transform: `scale(${ic(logoS, [0, 1], [0.7, 1]) * breathSc})`,
          opacity: logoS,
        }}>
          {/* MZ monogram */}
          <div style={{
            width: 100,
            height: 100,
            borderRadius: 24,
            backgroundColor: NAVY,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            marginBottom: 24,
            boxShadow: `0 20px 60px ${NAVY}44`,
          }}>
            <div style={{ fontFamily: SYNE, fontSize: 44, fontWeight: 900, color: '#FFFFFF', lineHeight: 1, letterSpacing: '-2px' }}>
              MZ
            </div>
          </div>

          <div style={{ fontFamily: SYNE, fontSize: 52, fontWeight: 900, color: NAVY, letterSpacing: '2px', lineHeight: 1 }}>
            MANDAT
          </div>
          <div style={{ fontFamily: SYNE, fontSize: 52, fontWeight: 900, color: ORANGE, letterSpacing: '2px', lineHeight: 1 }}>
            ZÉRO
          </div>

          <OrangeLine startFrame={88} width={280} />

          <div style={{
            opacity: ic(taglineS, [0, 1], [0, 1]),
            transform: `translateY(${ic(taglineS, [0, 1], [20, 0])}px)`,
            fontFamily: DM,
            fontSize: 28,
            color: '#8A8FA8',
            marginTop: 20,
            textAlign: 'center',
            letterSpacing: '1px',
          }}>
            Le mérite. Pas le réseau.
          </div>

          {/* CTA */}
          <div style={{
            opacity: ic(frame, [130, 145], [0, 1]),
            marginTop: 36,
            backgroundColor: ORANGE,
            borderRadius: 100,
            padding: '18px 48px',
            boxShadow: `0 ${8 + Math.sin(breathT * 0.04) * 4}px ${32 + Math.sin(breathT * 0.04) * 12}px ${ORANGE}55`,
          }}>
            <div style={{ fontFamily: SYNE, fontSize: 28, fontWeight: 800, color: '#FFFFFF', letterSpacing: '1px' }}>
              mandatzero.fr
            </div>
          </div>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
