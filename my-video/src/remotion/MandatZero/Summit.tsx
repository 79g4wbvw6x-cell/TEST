import React from 'react';
import { AbsoluteFill, Easing, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { loadFont as loadBebas } from '@remotion/google-fonts/BebasNeue';
import { loadFont as loadInter } from '@remotion/google-fonts/Inter';
import { NAVY, ORANGE, WHITE } from './constants';
import { ParticleField, Vignette } from './atoms';

const { fontFamily: bebas } = loadBebas();
const { fontFamily: inter } = loadInter();

const SenateSilhouette: React.FC<{ opacity: number }> = ({ opacity }) => (
  <svg
    width={1080}
    height={480}
    viewBox="0 0 1080 480"
    style={{ position: 'absolute', bottom: 100, left: 0, opacity }}
  >
    {/* Sky glow */}
    <defs>
      <radialGradient id="skyGlow" cx="50%" cy="80%" r="60%">
        <stop offset="0%" stopColor="#FF6B2B" stopOpacity="0.2" />
        <stop offset="100%" stopColor="transparent" stopOpacity="0" />
      </radialGradient>
    </defs>
    <ellipse cx={540} cy={400} rx={420} ry={200} fill="url(#skyGlow)" />

    {/* Ground */}
    <rect x={0} y={440} width={1080} height={40} fill={WHITE} opacity={0.08} />

    {/* Main building body */}
    <rect x={140} y={260} width={800} height={180} fill={WHITE} opacity={0.12} />

    {/* Columns */}
    {Array.from({ length: 14 }, (_, i) => (
      <rect key={i} x={168 + i * 54} y={240} width={10} height={200} fill={WHITE} opacity={0.22} rx={2} />
    ))}

    {/* Pediment / triangular top */}
    <polygon points="240,240 540,110 840,240" fill="none" stroke={WHITE} strokeWidth={1.5} opacity={0.35} />

    {/* Central dome */}
    <ellipse cx={540} cy={230} rx={110} ry={72} fill={WHITE} opacity={0.14} />
    <ellipse cx={540} cy={230} rx={75} ry={52} fill={WHITE} opacity={0.12} />
    <ellipse cx={540} cy={230} rx={44} ry={32} fill={WHITE} opacity={0.1} />

    {/* Dome lantern */}
    <rect x={526} y={155} width={28} height={55} fill={WHITE} opacity={0.18} rx={4} />

    {/* Flagpole + flag */}
    <line x1={540} y1={155} x2={540} y2={55} stroke={WHITE} strokeWidth={3} opacity={0.5} />
    <rect x={540} y={55} width={52} height={36} fill={ORANGE} opacity={0.85} rx={2} />

    {/* Steps */}
    <rect x={90} y={432} width={900} height={12} fill={WHITE} opacity={0.16} />
    <rect x={60} y={444} width={960} height={12} fill={WHITE} opacity={0.1} />

    {/* Side wings */}
    <rect x={60} y={310} width={80} height={130} fill={WHITE} opacity={0.08} />
    <rect x={940} y={310} width={80} height={130} fill={WHITE} opacity={0.08} />

    {/* Windows row */}
    {Array.from({ length: 10 }, (_, i) => (
      <rect key={i} x={175 + i * 73} y={290} width={28} height={38} fill={ORANGE} opacity={0.12} rx={2} />
    ))}
  </svg>
);

export const Summit: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const sceneIn = interpolate(frame, [0, 18], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const sceneOut = interpolate(frame, [210, 240], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const opacity = sceneIn * sceneOut;

  // Light rays
  const raysProgress = interpolate(frame, [15, 100], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });

  // Building rise
  const buildingSpring = spring({ frame: frame - 25, fps, config: { damping: 32, stiffness: 140, mass: 1.5 } });
  const buildingY = interpolate(buildingSpring, [0, 1], [120, 0]);

  // G50 impact
  const g50Spring = spring({ frame: frame - 75, fps, config: { damping: 13, stiffness: 250, mass: 1 } });

  const sommetOpacity = interpolate(frame, [38, 60], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const subtitleOpacity = interpolate(frame, [110, 140], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const statsOpacity = interpolate(frame, [155, 185], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  const lineWidth = interpolate(frame, [130, 168], [0, 380], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill style={{ backgroundColor: NAVY, opacity }}>
      {/* Light rays */}
      <svg width={1080} height={1920} style={{ position: 'absolute' }}>
        {Array.from({ length: 16 }, (_, i) => {
          const angle = (i / 16) * Math.PI * 2;
          const len = 1300 * raysProgress;
          return (
            <line
              key={i}
              x1={540}
              y1={780}
              x2={540 + Math.cos(angle) * len}
              y2={780 + Math.sin(angle) * len}
              stroke={ORANGE}
              strokeWidth={2 + (i % 3)}
              opacity={0.06 * raysProgress}
            />
          );
        })}
      </svg>

      <ParticleField count={20} color={ORANGE} maxOpacity={0.15} />

      {/* Building */}
      <div style={{ transform: `translateY(${buildingY}px)`, opacity: buildingSpring }}>
        <SenateSilhouette opacity={1} />
      </div>

      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          paddingBottom: 480,
          gap: 0,
        }}
      >
        {/* SOMMET label */}
        <div
          style={{
            opacity: sommetOpacity,
            fontFamily: bebas,
            fontSize: 32,
            color: ORANGE,
            letterSpacing: '16px',
            marginBottom: 0,
          }}
        >
          SOMMET
        </div>

        {/* G50 */}
        <div
          style={{
            opacity: g50Spring,
            transform: `scale(${interpolate(g50Spring, [0, 1], [0.6, 1])})`,
            fontFamily: bebas,
            fontSize: 186,
            color: WHITE,
            letterSpacing: '-6px',
            lineHeight: 0.88,
            textShadow: `0 0 120px ${ORANGE}44`,
          }}
        >
          G50
        </div>

        {/* Orange line */}
        <div
          style={{
            width: lineWidth,
            height: 3,
            backgroundColor: ORANGE,
            borderRadius: 2,
            marginTop: 20,
            boxShadow: `0 0 10px ${ORANGE}`,
          }}
        />

        {/* Subtitle */}
        <div style={{ opacity: subtitleOpacity, textAlign: 'center', padding: '24px 80px 0', lineHeight: 1.65 }}>
          <div style={{ fontFamily: inter, fontSize: 26, color: 'rgba(255,255,255,0.65)', fontWeight: 300 }}>
            Une vraie session parlementaire
            <br />
            <span style={{ color: WHITE, fontWeight: 700 }}>au Sénat Français</span>
            <br />
            pour interroger les leaders de tous les partis
          </div>
        </div>

        {/* Stats */}
        <div
          style={{
            opacity: statsOpacity,
            display: 'flex',
            gap: 56,
            marginTop: 36,
          }}
        >
          {[
            { val: '50', label: 'jeunes / an', dim: false },
            { val: '100%', label: 'mérite', dim: false },
            { val: '0', label: 'piston', dim: true },
          ].map((s, i) => (
            <div key={i} style={{ textAlign: 'center' }}>
              <div
                style={{
                  fontFamily: bebas,
                  fontSize: 48,
                  color: s.dim ? '#3A3A4A' : ORANGE,
                  lineHeight: 1,
                  textDecoration: s.dim ? 'line-through' : 'none',
                }}
              >
                {s.val}
              </div>
              <div
                style={{
                  fontFamily: inter,
                  fontSize: 13,
                  color: 'rgba(255,255,255,0.4)',
                  letterSpacing: '3px',
                  textTransform: 'uppercase',
                  marginTop: 2,
                }}
              >
                {s.label}
              </div>
            </div>
          ))}
        </div>
      </AbsoluteFill>

      <Vignette opacity={0.4} />
    </AbsoluteFill>
  );
};
