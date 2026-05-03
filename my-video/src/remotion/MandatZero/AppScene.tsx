import React from 'react';
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from 'remotion';
import { loadLocalFonts, SYNE, DM } from './fonts';
import { BG, NAVY, ORANGE, GRAY, BLACK } from './constants';
import { ic, sp, SpringText, SceneWrap, OrangeLine } from './atoms';

loadLocalFonts();

// Exact replica of the app's ranking screen (screen 07 from mockups)
const RankingScreen: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Rank counts from 999 → 384 over frames 20–60
  const rank = Math.round(ic(frame, [20, 60], [999, 384]));
  // Progress toward top 50: 753 pts remaining
  const barW = ic(frame, [30, 70], [0, 62], (t) => t);

  const statDelay = [40, 48, 56];
  const stats = [
    { label: 'SCORE', value: '1 247' },
    { label: 'MISSIONS', value: '18' },
    { label: 'POUR LE TOP 50', value: '753 pts' },
  ];

  const leaders = [
    { pos: 1, name: 'Inès Bouchard', pts: '4 218 pts', color: '#FFD700' },
    { pos: 2, name: 'Hugo Renaud',   pts: '3 984 pts', color: '#C0C0C0' },
    { pos: 3, name: 'Sami Kaci',     pts: '3 712 pts', color: '#CD7F32' },
  ];

  return (
    <div style={{ height: '100%', backgroundColor: BG, padding: '20px 16px', display: 'flex', flexDirection: 'column', gap: 12, overflowY: 'hidden' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ fontFamily: SYNE, fontSize: 20, fontWeight: 800, color: NAVY }}>Classement</div>
        <div style={{ display: 'flex', gap: 6 }}>
          {['France', 'Région', 'Amis'].map((t, i) => (
            <div key={i} style={{ fontFamily: DM, fontSize: 12, color: i === 0 ? NAVY : GRAY, fontWeight: i === 0 ? 700 : 400, borderBottom: i === 0 ? `2px solid ${NAVY}` : 'none', paddingBottom: 2 }}>{t}</div>
          ))}
        </div>
      </div>

      {/* Big rank card */}
      <div style={{ backgroundColor: NAVY, borderRadius: 16, padding: '16px 18px' }}>
        <div style={{ fontFamily: DM, fontSize: 10, color: 'rgba(255,255,255,0.5)', letterSpacing: '2px', textTransform: 'uppercase', textAlign: 'center' }}>VOTRE RANG FRANCE</div>
        <div style={{ fontFamily: SYNE, fontSize: 72, fontWeight: 900, color: '#FFFFFF', textAlign: 'center', lineHeight: 1, marginTop: 4 }}>
          #{rank}
        </div>
        <div style={{ fontFamily: DM, fontSize: 12, color: ORANGE, textAlign: 'center', marginTop: 4, fontWeight: 600 }}>
          ↑ 27 places cette semaine
        </div>

        {/* Stat columns */}
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 12, paddingTop: 10, borderTop: '1px solid rgba(255,255,255,0.1)' }}>
          {stats.map((s, i) => {
            const statS = sp(frame, fps, statDelay[i], 22, 260);
            return (
              <div key={i} style={{ opacity: statS, transform: `translateY(${ic(statS, [0, 1], [10, 0])}px)`, textAlign: 'center' }}>
                <div style={{ fontFamily: DM, fontSize: 9, color: 'rgba(255,255,255,0.4)', letterSpacing: '1px', textTransform: 'uppercase' }}>{s.label}</div>
                <div style={{ fontFamily: SYNE, fontSize: 14, fontWeight: 800, color: '#FFFFFF', marginTop: 2 }}>{s.value}</div>
              </div>
            );
          })}
        </div>

        {/* Progress bar toward top 50 */}
        <div style={{ marginTop: 12 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
            <div style={{ fontFamily: DM, fontSize: 9, color: 'rgba(255,255,255,0.4)', letterSpacing: '1px' }}>VOTRE PLACE</div>
            <div style={{ fontFamily: DM, fontSize: 9, color: ORANGE }}>#{rank} → top 50</div>
          </div>
          <div style={{ height: 5, backgroundColor: 'rgba(255,255,255,0.15)', borderRadius: 3, overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${barW}%`, background: `linear-gradient(90deg, ${ORANGE}, #FF4500)`, borderRadius: 3 }} />
          </div>
          <div style={{ fontFamily: DM, fontSize: 9, color: 'rgba(255,255,255,0.4)', marginTop: 4 }}>Encore 753 pts à gagner avant la sélection.</div>
        </div>
      </div>

      {/* Leader list */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
        {leaders.map((l, i) => {
          const rowS = sp(frame, fps, 50 + i * 8, 20, 220);
          return (
            <div key={i} style={{ opacity: rowS, transform: `translateX(${ic(rowS, [0, 1], [30, 0])}px)`, display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px', backgroundColor: '#F7F7F7', borderRadius: 10 }}>
              <div style={{ fontFamily: SYNE, fontSize: 16, fontWeight: 800, color: l.color, minWidth: 18 }}>{l.pos}</div>
              <div style={{ width: 28, height: 28, borderRadius: '50%', backgroundColor: NAVY + '33', flexShrink: 0 }} />
              <div style={{ flex: 1, fontFamily: DM, fontSize: 13, fontWeight: 600, color: NAVY }}>{l.name}</div>
              <div style={{ fontFamily: SYNE, fontSize: 13, fontWeight: 800, color: NAVY }}>{l.pts}</div>
            </div>
          );
        })}
        <div style={{ fontFamily: DM, fontSize: 12, color: GRAY, textAlign: 'center', padding: '4px 0' }}>···</div>
        {/* Current user row */}
        <div style={{
          opacity: ic(frame, [70, 82], [0, 1]),
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '10px 12px',
          backgroundColor: '#FFF3EE',
          borderRadius: 10,
          border: `1.5px solid ${ORANGE}44`,
        }}>
          <div style={{ fontFamily: SYNE, fontSize: 16, fontWeight: 800, color: ORANGE, minWidth: 28 }}>{rank}</div>
          <div style={{ width: 28, height: 28, borderRadius: '50%', backgroundColor: NAVY, flexShrink: 0 }} />
          <div style={{ flex: 1, fontFamily: DM, fontSize: 13, fontWeight: 600, color: NAVY }}>Vous · Léa M.</div>
          <div style={{ fontFamily: SYNE, fontSize: 13, fontWeight: 800, color: ORANGE }}>1 247 pts</div>
        </div>
      </div>
    </div>
  );
};

// Mission badges
const BADGES = [
  { label: 'TERRAIN',       color: '#22C55E', bg: '#DCFCE7' },
  { label: 'NUMÉRIQUE',     color: '#3B82F6', bg: '#DBEAFE' },
  { label: 'PLUME',         color: ORANGE,    bg: '#FFF3EE' },
  { label: 'CONSULTATION',  color: '#A855F7', bg: '#F3E8FF' },
];

export const AppScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const dur = 180;

  const phoneS = sp(frame, fps, 0, 14, 120);
  const phoneY = ic(phoneS, [0, 1], [400, 0]);

  // Phone tilt at frame 140 → returns to 0
  const tiltS  = sp(frame, fps, 140, 14, 200);
  const tilt   = interpolate(tiltS, [0, 0.5, 1], [0, 8, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  return (
    <SceneWrap dur={dur} bg={BG}>
      <AbsoluteFill style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-start', paddingTop: 120, gap: 32 }}>

        {/* Title */}
        <SpringText delay={0} fromY={40} style={{ textAlign: 'center' }}>
          <div style={{ fontFamily: SYNE, fontSize: 32, fontWeight: 800, color: ORANGE, letterSpacing: '8px' }}>LA PLATEFORME</div>
          <div style={{ fontFamily: SYNE, fontSize: 72, fontWeight: 800, color: NAVY, letterSpacing: '-1px', lineHeight: 1 }}>MANDAT ZÉRO</div>
          <OrangeLine startFrame={6} width={400} />
        </SpringText>

        {/* Phone shell */}
        <div style={{
          transform: `translateY(${phoneY}px) perspective(900px) rotateY(${tilt}deg)`,
          width: 340,
          height: 680,
          backgroundColor: '#FFFFFF',
          borderRadius: 44,
          border: `2px solid ${NAVY}22`,
          boxShadow: `0 32px 80px rgba(27,42,74,0.18), 0 0 0 1px rgba(27,42,74,0.05)`,
          overflow: 'hidden',
          position: 'relative',
          flexShrink: 0,
        }}>
          {/* Dynamic island */}
          <div style={{ position: 'absolute', top: 14, left: '50%', transform: 'translateX(-50%)', width: 88, height: 26, backgroundColor: BLACK, borderRadius: 13, zIndex: 10 }} />
          {/* Status bar */}
          <div style={{ position: 'absolute', top: 14, left: 22, fontSize: 10, fontFamily: DM, color: NAVY, fontWeight: 700, zIndex: 11 }}>9:41</div>
          <div style={{ height: '100%', paddingTop: 48 }}>
            <RankingScreen />
          </div>
        </div>

        {/* Mission badges */}
        <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap', justifyContent: 'center' }}>
          {BADGES.map((b, i) => {
            const bS = sp(frame, fps, 100 + i * 12, 18, 220);
            const bY = ic(bS, [0, 1], [60, 0]);
            return (
              <div key={i} style={{
                opacity: bS,
                transform: `translateY(${bY}px)`,
                backgroundColor: b.bg,
                borderRadius: 100,
                padding: '10px 22px',
                fontFamily: SYNE,
                fontSize: 14,
                fontWeight: 800,
                color: b.color,
                letterSpacing: '2px',
                boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
              }}>
                {b.label}
              </div>
            );
          })}
        </div>
      </AbsoluteFill>
    </SceneWrap>
  );
};
