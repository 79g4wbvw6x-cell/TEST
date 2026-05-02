import React from 'react';
import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { loadFont as loadBebas } from '@remotion/google-fonts/BebasNeue';
import { loadFont as loadInter } from '@remotion/google-fonts/Inter';
import { BLACK, ORANGE, WHITE } from './constants';
import { GlowOrb, ParticleField } from './atoms';

const { fontFamily: bebas } = loadBebas();
const { fontFamily: inter } = loadInter();

const BADGES = ['16–25 ANS', 'GRATUIT', 'MÉRITOCRATIQUE'];

export const Outro: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const sceneIn = interpolate(frame, [0, 18], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const logoSpring = spring({ frame: frame - 12, fps, config: { damping: 22, stiffness: 220 } });
  const taglineOpacity = interpolate(frame, [42, 62], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const urlOpacity = interpolate(frame, [55, 75], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const badgeOpacity = interpolate(frame, [68, 88], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // Fade to black at very end
  const fadeOut = interpolate(frame, [78, 90], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{ backgroundColor: BLACK, opacity: sceneIn }}>
      <ParticleField count={25} color={ORANGE} maxOpacity={0.12} />
      <GlowOrb
        x={540}
        y={880}
        radius={400}
        color={ORANGE}
        opacity={interpolate(logoSpring, [0, 1], [0, 0.08])}
      />

      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 28,
        }}
      >
        {/* Logo */}
        <div
          style={{
            opacity: logoSpring,
            transform: `scale(${interpolate(logoSpring, [0, 1], [0.82, 1])})`,
            textAlign: 'center',
          }}
        >
          <div style={{ fontFamily: bebas, fontSize: 72, color: WHITE, letterSpacing: '4px', lineHeight: 1 }}>
            MANDAT
          </div>
          <div
            style={{
              fontFamily: bebas,
              fontSize: 112,
              color: ORANGE,
              letterSpacing: '-3px',
              lineHeight: 0.88,
              textShadow: `0 0 80px ${ORANGE}55`,
            }}
          >
            ZÉRO
          </div>

          {/* Divider */}
          <div
            style={{
              width: interpolate(frame, [14, 38], [0, 300], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
              height: 3,
              backgroundColor: ORANGE,
              margin: '14px auto 0',
              borderRadius: 2,
            }}
          />
        </div>

        {/* Tagline */}
        <div
          style={{
            opacity: taglineOpacity,
            fontFamily: inter,
            fontSize: 24,
            color: 'rgba(255,255,255,0.6)',
            fontStyle: 'italic',
            textAlign: 'center',
            padding: '0 80px',
            lineHeight: 1.5,
          }}
        >
          "Fini le piston. Place au mérite."
        </div>

        {/* URL */}
        <div
          style={{
            opacity: urlOpacity,
            fontFamily: bebas,
            fontSize: 38,
            color: ORANGE,
            letterSpacing: '4px',
            textShadow: `0 0 30px ${ORANGE}66`,
          }}
        >
          mandatzero.fr
        </div>

        {/* Badges */}
        <div style={{ opacity: badgeOpacity, display: 'flex', gap: 14, flexWrap: 'wrap', justifyContent: 'center' }}>
          {BADGES.map((b, i) => (
            <div
              key={i}
              style={{
                backgroundColor: 'rgba(255,107,43,0.1)',
                border: `1px solid ${ORANGE}44`,
                borderRadius: 100,
                padding: '9px 22px',
                fontFamily: bebas,
                fontSize: 17,
                color: ORANGE,
                letterSpacing: '3px',
              }}
            >
              {b}
            </div>
          ))}
        </div>
      </AbsoluteFill>

      {/* Final fade to black */}
      <AbsoluteFill style={{ backgroundColor: BLACK, opacity: fadeOut }} />
    </AbsoluteFill>
  );
};
