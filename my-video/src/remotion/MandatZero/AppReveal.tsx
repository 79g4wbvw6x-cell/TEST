import React from 'react';
import { AbsoluteFill, Easing, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { loadFont as loadBebas } from '@remotion/google-fonts/BebasNeue';
import { loadFont as loadInter } from '@remotion/google-fonts/Inter';
import { CHARCOAL, NAVY, ORANGE, WHITE } from './constants';
import { Scanlines, Vignette } from './atoms';

const { fontFamily: bebas } = loadBebas();
const { fontFamily: inter } = loadInter();

const MISSIONS = [
  { icon: '🏛', title: 'Conseil municipal de Lyon', role: 'Marie Dupont · Maire', pts: 150 },
  { icon: '📋', title: 'Commission nationale Jeunesse', role: 'Jean Martin · Député 75', pts: 200 },
  { icon: '🗳', title: 'Forum citoyen Bordeaux', role: 'Claire Blanc · Sénatrice', pts: 120 },
];

export const AppReveal: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const sceneIn = interpolate(frame, [0, 18], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const sceneOut = interpolate(frame, [245, 270], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const opacity = sceneIn * sceneOut;

  const titleSpring = spring({ frame: frame - 8, fps, config: { damping: 22, stiffness: 260 } });
  const titleY = interpolate(titleSpring, [0, 1], [-40, 0]);

  const phoneSpring = spring({ frame: frame - 35, fps, config: { damping: 28, stiffness: 190, mass: 1.3 } });
  const phoneY = interpolate(phoneSpring, [0, 1], [700, 0]);

  // Animated points counter on the phone screen
  const pts = Math.floor(
    interpolate(frame, [60, 150], [0, 847], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.out(Easing.cubic) }),
  );
  const rank = Math.floor(
    interpolate(frame, [60, 150], [1240, 47], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing: Easing.out(Easing.cubic) }),
  );

  const subtitleOpacity = interpolate(frame, [140, 165], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{ backgroundColor: CHARCOAL, opacity }}>
      {/* Subtle grid */}
      <svg width={1080} height={1920} style={{ position: 'absolute', opacity: 0.04 }}>
        {Array.from({ length: 22 }, (_, i) => (
          <line key={`h${i}`} x1={0} y1={i * 88} x2={1080} y2={i * 88} stroke={WHITE} strokeWidth={1} />
        ))}
        {Array.from({ length: 13 }, (_, i) => (
          <line key={`v${i}`} x1={i * 90} y1={0} x2={i * 90} y2={1920} stroke={WHITE} strokeWidth={1} />
        ))}
      </svg>

      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'flex-start',
          paddingTop: 140,
          gap: 44,
        }}
      >
        {/* Title */}
        <div style={{ opacity: titleSpring, transform: `translateY(${titleY}px)`, textAlign: 'center' }}>
          <div style={{ fontFamily: bebas, fontSize: 34, color: ORANGE, letterSpacing: '12px' }}>
            LA SOLUTION
          </div>
          <div style={{ fontFamily: bebas, fontSize: 84, color: WHITE, letterSpacing: '-1px', lineHeight: 0.95 }}>
            MANDAT ZÉRO
          </div>
          <div
            style={{
              width: interpolate(frame, [18, 50], [0, 340], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
              height: 3,
              backgroundColor: ORANGE,
              margin: '12px auto 0',
              borderRadius: 2,
            }}
          />
        </div>

        {/* Phone mockup */}
        <div
          style={{
            transform: `translateY(${phoneY}px)`,
            width: 320,
            height: 660,
            backgroundColor: '#0A0A10',
            borderRadius: 44,
            border: '2.5px solid #2A2A3A',
            overflow: 'hidden',
            position: 'relative',
            boxShadow: `0 50px 120px rgba(0,0,0,0.9), 0 0 70px ${ORANGE}22, inset 0 1px 0 rgba(255,255,255,0.07)`,
          }}
        >
          {/* Dynamic island */}
          <div
            style={{
              position: 'absolute',
              top: 14,
              left: '50%',
              transform: 'translateX(-50%)',
              width: 88,
              height: 26,
              backgroundColor: '#000',
              borderRadius: 13,
              zIndex: 10,
            }}
          />

          {/* Screen */}
          <div style={{ padding: '52px 14px 14px', height: '100%', backgroundColor: '#0D0D18', overflow: 'hidden' }}>
            {/* App bar */}
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: 14,
              }}
            >
              <div style={{ fontFamily: bebas, fontSize: 18, color: ORANGE, letterSpacing: '2px' }}>
                MANDAT ZÉRO
              </div>
              <div
                style={{
                  width: 30,
                  height: 30,
                  borderRadius: '50%',
                  background: `linear-gradient(135deg, ${ORANGE}, ${NAVY})`,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: 12,
                  color: WHITE,
                  fontFamily: inter,
                  fontWeight: 700,
                }}
              >
                AM
              </div>
            </div>

            {/* Stats card */}
            <div
              style={{
                background: `linear-gradient(135deg, ${ORANGE}1A, ${NAVY}33)`,
                border: `1px solid ${ORANGE}33`,
                borderRadius: 14,
                padding: '12px 14px',
                marginBottom: 14,
                display: 'flex',
                justifyContent: 'space-between',
              }}
            >
              <div>
                <div style={{ fontFamily: inter, fontSize: 9, color: '#666', letterSpacing: '2px', textTransform: 'uppercase' }}>
                  MES POINTS
                </div>
                <div style={{ fontFamily: bebas, fontSize: 36, color: ORANGE, lineHeight: 1 }}>{pts}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontFamily: inter, fontSize: 9, color: '#666', letterSpacing: '2px', textTransform: 'uppercase' }}>
                  CLASSEMENT
                </div>
                <div style={{ fontFamily: bebas, fontSize: 36, color: WHITE, lineHeight: 1 }}>#{rank}</div>
              </div>
            </div>

            {/* Progress bar */}
            <div style={{ marginBottom: 14 }}>
              <div
                style={{
                  fontFamily: inter,
                  fontSize: 9,
                  color: '#555',
                  letterSpacing: '2px',
                  textTransform: 'uppercase',
                  marginBottom: 6,
                }}
              >
                Progression vers le TOP 50
              </div>
              <div style={{ height: 6, backgroundColor: '#1A1A28', borderRadius: 3, overflow: 'hidden' }}>
                <div
                  style={{
                    height: '100%',
                    width: `${interpolate(frame, [70, 160], [0, 62], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })}%`,
                    background: `linear-gradient(90deg, ${ORANGE}, #FF4500)`,
                    borderRadius: 3,
                  }}
                />
              </div>
            </div>

            {/* Missions */}
            <div
              style={{
                fontFamily: inter,
                fontSize: 9,
                color: '#444',
                letterSpacing: '2px',
                textTransform: 'uppercase',
                marginBottom: 8,
              }}
            >
              MISSIONS DISPONIBLES
            </div>

            {MISSIONS.map((m, i) => {
              const cardOp = interpolate(frame, [75 + i * 22, 105 + i * 22], [0, 1], {
                extrapolateLeft: 'clamp',
                extrapolateRight: 'clamp',
              });
              const cardY = interpolate(frame, [75 + i * 22, 105 + i * 22], [20, 0], {
                extrapolateLeft: 'clamp',
                extrapolateRight: 'clamp',
                easing: Easing.out(Easing.cubic),
              });

              return (
                <div
                  key={i}
                  style={{
                    opacity: cardOp,
                    transform: `translateY(${cardY}px)`,
                    backgroundColor: '#12121E',
                    borderRadius: 10,
                    padding: '9px 11px',
                    marginBottom: 7,
                    border: '1px solid #1E1E2E',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 9,
                  }}
                >
                  <div style={{ fontSize: 18 }}>{m.icon}</div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div
                      style={{
                        fontFamily: inter,
                        fontSize: 10,
                        fontWeight: 700,
                        color: WHITE,
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                      }}
                    >
                      {m.title}
                    </div>
                    <div style={{ fontFamily: inter, fontSize: 8, color: '#555' }}>{m.role}</div>
                  </div>
                  <div
                    style={{
                      backgroundColor: ORANGE,
                      borderRadius: 6,
                      padding: '3px 8px',
                      fontFamily: bebas,
                      fontSize: 14,
                      color: WHITE,
                      whiteSpace: 'nowrap',
                    }}
                  >
                    +{m.pts}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Subtitle */}
        <div style={{ opacity: subtitleOpacity, textAlign: 'center', padding: '0 70px' }}>
          <div style={{ fontFamily: inter, fontSize: 28, color: WHITE, lineHeight: 1.5, fontWeight: 300 }}>
            Des{' '}
            <span style={{ color: ORANGE, fontWeight: 700 }}>missions civiques</span> réelles,
            <br />
            validées par de vrais élus
          </div>
        </div>
      </AbsoluteFill>

      <Scanlines opacity={0.03} />
      <Vignette opacity={0.4} />
    </AbsoluteFill>
  );
};
