import React from 'react';
import { AbsoluteFill, Easing, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { loadFont as loadBebas } from '@remotion/google-fonts/BebasNeue';
import { BLACK, ORANGE, WHITE } from './constants';
import { GlowOrb, ParticleField, Vignette } from './atoms';

const { fontFamily: bebas } = loadBebas();

export const Opening: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Particle convergence 2.5s → 4.8s
  const converge = interpolate(frame, [75, 144], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.in(Easing.quad),
  });

  // White flash at frame 145
  const flash = interpolate(frame, [143, 146, 155, 170], [0, 1, 0.4, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // MANDAT slides from left
  const mandatSpring = spring({ frame: frame - 148, fps, config: { damping: 18, stiffness: 220, mass: 0.9 } });
  const mandatX = interpolate(mandatSpring, [0, 1], [-500, 0]);

  // ZÉRO slides from right
  const zeroSpring = spring({ frame: frame - 155, fps, config: { damping: 14, stiffness: 200, mass: 1.1 } });
  const zeroX = interpolate(zeroSpring, [0, 1], [500, 0]);

  // Line draws itself after lock
  const lineProgress = interpolate(frame, [175, 200], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  // Tagline fades in
  const taglineOpacity = interpolate(frame, [190, 210], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // Overall scene fade-out at the end (last 10 frames)
  const sceneOut = interpolate(frame, [200, 210], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // Glow orb radius breathes
  const glowRadius = 260 + Math.sin(frame * 0.05) * 30;

  return (
    <AbsoluteFill style={{ backgroundColor: BLACK, opacity: sceneOut }}>
      {/* Ambient glow */}
      <GlowOrb x={540} y={960} radius={glowRadius} color={ORANGE} opacity={interpolate(frame, [0, 90, 144], [0, 0.12, 0.5], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })} />

      {/* Drifting particles that converge */}
      <ParticleField count={90} color={ORANGE} converge={converge} centerX={540} centerY={920} maxOpacity={0.7} />
      <ParticleField count={30} color={WHITE} converge={converge * 0.6} centerX={540} centerY={920} maxOpacity={0.3} />

      {/* Flash */}
      <AbsoluteFill style={{ backgroundColor: WHITE, opacity: flash, mixBlendMode: 'screen' }} />

      {/* ── Logo ── */}
      <AbsoluteFill style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 0 }}>
        {/* MANDAT */}
        <div
          style={{
            fontFamily: bebas,
            fontSize: 148,
            color: WHITE,
            letterSpacing: '8px',
            lineHeight: 1,
            transform: `translateX(${mandatX}px)`,
            opacity: mandatSpring,
          }}
        >
          MANDAT
        </div>

        {/* ZÉRO — larger, orange */}
        <div
          style={{
            fontFamily: bebas,
            fontSize: 210,
            color: ORANGE,
            letterSpacing: '-4px',
            lineHeight: 0.88,
            transform: `translateX(${zeroX}px)`,
            opacity: zeroSpring,
            textShadow: `0 0 80px ${ORANGE}66`,
          }}
        >
          ZÉRO
        </div>

        {/* Horizontal line */}
        <div
          style={{
            marginTop: 24,
            height: 3,
            width: lineProgress * 560,
            backgroundColor: ORANGE,
            borderRadius: 3,
            boxShadow: `0 0 12px ${ORANGE}`,
          }}
        />

        {/* Tagline */}
        <div
          style={{
            marginTop: 24,
            fontFamily: bebas,
            fontSize: 28,
            color: 'rgba(255,255,255,0.55)',
            letterSpacing: '10px',
            opacity: taglineOpacity,
          }}
        >
          L'ASCENSEUR RÉPUBLICAIN 2.0
        </div>
      </AbsoluteFill>

      <Vignette opacity={0.6} />
    </AbsoluteFill>
  );
};
