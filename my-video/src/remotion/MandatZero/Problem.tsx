import React from 'react';
import { BEBAS, INTER, loadLocalFonts } from './fonts';
import { AbsoluteFill, Easing, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { CHARCOAL, NAVY, ORANGE, WHITE } from './constants';
import { AnimatedCount, GlitchText } from './atoms';


loadLocalFonts();

export const Problem: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Scene in / out
  const sceneIn = interpolate(frame, [0, 20], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const sceneOut = interpolate(frame, [270, 300], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const opacity = sceneIn * sceneOut;

  const titleSpring = spring({ frame: frame - 5, fps, config: { damping: 22, stiffness: 280 } });
  const titleY = interpolate(titleSpring, [0, 1], [-50, 0]);

  const stat1Spring = spring({ frame: frame - 30, fps, config: { damping: 20, stiffness: 240 } });
  const stat1Y = interpolate(stat1Spring, [0, 1], [40, 0]);

  // Nepotism bar: 0 → 70%
  const barPct = interpolate(frame, [80, 160], [0, 70], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  const pistonSpring = spring({ frame: frame - 165, fps, config: { damping: 12, stiffness: 220, mass: 1 } });

  // Separator line
  const sepLine = interpolate(frame, [20, 50], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{ backgroundColor: WHITE, opacity }}>
      {/* Top accent */}
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 8, backgroundColor: ORANGE }} />

      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '0 72px',
          gap: 0,
        }}
      >
        {/* CHAQUE ANNÉE */}
        <div
          style={{
            opacity: titleSpring,
            transform: `translateY(${titleY}px)`,
            fontFamily: BEBAS,
            fontSize: 52,
            color: NAVY,
            letterSpacing: '10px',
            marginBottom: 4,
          }}
        >
          CHAQUE ANNÉE
        </div>

        {/* Orange separator */}
        <div
          style={{
            width: sepLine * 280,
            height: 3,
            backgroundColor: ORANGE,
            marginBottom: 20,
            borderRadius: 2,
          }}
        />

        {/* Counter */}
        <div
          style={{
            opacity: stat1Spring,
            transform: `translateY(${stat1Y}px)`,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
          }}
        >
          <div
            style={{
              fontFamily: BEBAS,
              fontSize: 116,
              color: ORANGE,
              lineHeight: 1,
              letterSpacing: '-2px',
            }}
          >
            <AnimatedCount from={0} to={600000} startFrame={35} endFrame={120} />
          </div>
          <div
            style={{
              fontFamily: INTER,
              fontSize: 26,
              fontWeight: 600,
              color: NAVY,
              letterSpacing: '3px',
              textTransform: 'uppercase',
              marginTop: 4,
            }}
          >
            stages distribués en France
          </div>
        </div>

        {/* Divider */}
        <div style={{ width: '100%', height: 1, backgroundColor: '#E0E0E0', margin: '36px 0' }} />

        {/* Nepotism stat */}
        <div style={{ width: '100%', opacity: interpolate(frame, [70, 95], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }) }}>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              marginBottom: 10,
              fontFamily: INTER,
              fontSize: 20,
              color: CHARCOAL,
            }}
          >
            <span style={{ fontWeight: 500 }}>Obtenus par le réseau</span>
            <span style={{ fontWeight: 800, color: ORANGE }}>{Math.round(barPct)}%</span>
          </div>
          <div style={{ height: 18, backgroundColor: '#EBEBEB', borderRadius: 9, overflow: 'hidden' }}>
            <div
              style={{
                height: '100%',
                width: `${barPct}%`,
                background: `linear-gradient(90deg, ${ORANGE} 0%, #FF4500 100%)`,
                borderRadius: 9,
                boxShadow: `0 0 16px ${ORANGE}66`,
              }}
            />
          </div>
          <div
            style={{
              marginTop: 10,
              fontFamily: INTER,
              fontSize: 14,
              color: '#999',
              letterSpacing: '1px',
            }}
          >
            Source: Observatoire des inégalités
          </div>
        </div>

        {/* Divider */}
        <div style={{ width: '100%', height: 1, backgroundColor: '#E0E0E0', margin: '32px 0' }} />

        {/* LE PISTON DOMINE */}
        <div
          style={{
            opacity: pistonSpring,
            transform: `scale(${interpolate(pistonSpring, [0, 1], [0.85, 1])})`,
            textAlign: 'center',
          }}
        >
          <div
            style={{
              fontFamily: BEBAS,
              fontSize: 104,
              color: NAVY,
              letterSpacing: '-1px',
              lineHeight: 1,
            }}
          >
            <GlitchText text="LE PISTON" />
          </div>
          <div
            style={{
              fontFamily: BEBAS,
              fontSize: 42,
              color: CHARCOAL,
              letterSpacing: '8px',
              marginTop: -4,
            }}
          >
            DOMINE LA FRANCE
          </div>
        </div>
      </AbsoluteFill>

      {/* Bottom accent */}
      <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 8, backgroundColor: ORANGE }} />
    </AbsoluteFill>
  );
};
