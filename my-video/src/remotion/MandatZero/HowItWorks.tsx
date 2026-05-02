import React from 'react';
import { BEBAS, INTER, loadLocalFonts } from './fonts';
import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { NAVY, ORANGE, WHITE } from './constants';
import { ParticleField, Vignette } from './atoms';


const STEPS = [
  {
    n: '01',
    title: 'CHOISIS UNE MISSION',
    desc: 'Un élu publie une mission civique.\nTu la sélectionnes sur la plateforme.',
    icon: '🎯',
  },
  {
    n: '02',
    title: 'ACCOMPLIS-LA',
    desc: "Participe, contribue, agis.\nPas de diplôme requis — juste l'engagement.",
    icon: '⚡',
  },
  {
    n: '03',
    title: 'GAGNE DES POINTS',
    desc: "L'élu valide ta contribution.\nTu montes dans le classement national.",
    icon: '🏆',
  },
  {
    n: '04',
    title: 'TOP 50 → SÉNAT',
    desc: "Les 50 meilleurs rejoignent le Sommet G50\nà l’intérieur du Sénat Français.",
    icon: '🏛',
  },
];

const Step: React.FC<{ step: (typeof STEPS)[0]; index: number }> = ({ step, index }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const s = spring({ frame: frame - (25 + index * 45), fps, config: { damping: 22, stiffness: 200 } });
  const x = interpolate(s, [0, 1], [-120, 0]);

  return (
    <div
      style={{
        opacity: s,
        transform: `translateX(${x}px)`,
        display: 'flex',
        alignItems: 'flex-start',
        gap: 22,
        width: '100%',
        backgroundColor: 'rgba(255,255,255,0.04)',
        backdropFilter: 'blur(4px)',
        borderRadius: 18,
        padding: '22px 24px',
        border: '1px solid rgba(255,255,255,0.07)',
        borderLeft: `5px solid ${ORANGE}`,
        boxSizing: 'border-box',
      }}
    >
      <div style={{ fontFamily: BEBAS, fontSize: 52, color: ORANGE, opacity: 0.5, lineHeight: 1, minWidth: 56 }}>
        {step.n}
      </div>
      <div style={{ flex: 1 }}>
        <div
          style={{
            fontFamily: BEBAS,
            fontSize: 26,
            color: WHITE,
            letterSpacing: '3px',
            marginBottom: 5,
          }}
        >
          {step.title}
        </div>
        <div
          style={{
            fontFamily: INTER,
            fontSize: 15,
            color: 'rgba(255,255,255,0.55)',
            lineHeight: 1.55,
            whiteSpace: 'pre-line',
          }}
        >
          {step.desc}
        </div>
      </div>
      <div style={{ fontSize: 34, lineHeight: 1 }}>{step.icon}</div>
    </div>
  );
};

loadLocalFonts();

export const HowItWorks: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const sceneIn = interpolate(frame, [0, 18], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const sceneOut = interpolate(frame, [270, 300], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const opacity = sceneIn * sceneOut;

  const headerSpring = spring({ frame: frame - 8, fps, config: { damping: 22, stiffness: 260 } });

  return (
    <AbsoluteFill style={{ backgroundColor: NAVY, opacity }}>
      {/* Decorative circles */}
      <svg width={1080} height={1920} style={{ position: 'absolute', opacity: 0.07 }}>
        <circle cx={980} cy={160} r={320} fill="none" stroke={WHITE} strokeWidth={1.5} />
        <circle cx={980} cy={160} r={220} fill="none" stroke={ORANGE} strokeWidth={1} />
        <circle cx={100} cy={1760} r={280} fill="none" stroke={WHITE} strokeWidth={1.5} />
        <circle cx={540} cy={960} r={500} fill="none" stroke={WHITE} strokeWidth={0.5} />
      </svg>

      <ParticleField count={25} color={ORANGE} maxOpacity={0.2} />

      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '0 60px',
          gap: 24,
        }}
      >
        {/* Header */}
        <div
          style={{
            opacity: headerSpring,
            transform: `translateY(${interpolate(headerSpring, [0, 1], [-40, 0])}px)`,
            textAlign: 'center',
            marginBottom: 12,
          }}
        >
          <div style={{ fontFamily: BEBAS, fontSize: 26, color: ORANGE, letterSpacing: '10px' }}>
            MÉCANISME
          </div>
          <div style={{ fontFamily: BEBAS, fontSize: 68, color: WHITE, letterSpacing: '-1px', lineHeight: 1 }}>
            COMMENT ÇA MARCHE
          </div>
          <div
            style={{
              width: interpolate(frame, [10, 40], [0, 300], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
              height: 3,
              backgroundColor: ORANGE,
              margin: '10px auto 0',
              borderRadius: 2,
            }}
          />
        </div>

        {STEPS.map((step, i) => (
          <Step key={i} step={step} index={i} />
        ))}
      </AbsoluteFill>

      <Vignette opacity={0.35} />
    </AbsoluteFill>
  );
};
