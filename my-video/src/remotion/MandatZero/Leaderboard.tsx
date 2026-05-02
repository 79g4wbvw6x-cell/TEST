import React from 'react';
import { BEBAS, INTER, loadLocalFonts } from './fonts';
import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { BLACK, ORANGE, WHITE } from './constants';
import { Scanlines, Vignette } from './atoms';


const LEADERS = [
  { rank: 1, name: 'Amara K.', city: 'Lyon', pts: 2840, color: '#FFD700' },
  { rank: 2, name: 'Théo M.', city: 'Paris', pts: 2710, color: '#C0C0C0' },
  { rank: 3, name: 'Fatouma D.', city: 'Marseille', pts: 2640, color: '#CD7F32' },
  { rank: 4, name: 'Lucas B.', city: 'Bordeaux', pts: 2490, color: ORANGE },
  { rank: 5, name: 'Yasmine A.', city: 'Toulouse', pts: 2380, color: ORANGE },
  { rank: 48, name: 'Ibrahima S.', city: 'Strasbourg', pts: 1180, color: '#444' },
  { rank: 49, name: 'Léa F.', city: 'Lille', pts: 1120, color: '#444' },
  { rank: 50, name: 'Omar B.', city: 'Nice', pts: 1062, color: ORANGE },
];

const Row: React.FC<{ leader: (typeof LEADERS)[0]; index: number; isLast50: boolean }> = ({
  leader,
  index,
  isLast50,
}) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const s = spring({ frame: frame - (18 + index * 16), fps, config: { damping: 22, stiffness: 220 } });
  const x = interpolate(s, [0, 1], [160, 0]);

  const isTop3 = leader.rank <= 3;
  const isLimitRow = leader.rank === 50;

  return (
    <div
      style={{
        opacity: s,
        transform: `translateX(${x}px)`,
        display: 'flex',
        alignItems: 'center',
        gap: 14,
        backgroundColor: isTop3 ? 'rgba(255,107,43,0.08)' : 'rgba(255,255,255,0.03)',
        borderRadius: 13,
        padding: '13px 16px',
        border: `1px solid ${isLimitRow ? ORANGE + '55' : 'rgba(255,255,255,0.05)'}`,
        boxSizing: 'border-box',
      }}
    >
      {/* Rank */}
      <div
        style={{
          fontFamily: BEBAS,
          fontSize: 28,
          color: leader.color,
          minWidth: 44,
          textAlign: 'center',
          lineHeight: 1,
        }}
      >
        #{leader.rank}
      </div>

      {/* Avatar */}
      <div
        style={{
          width: 42,
          height: 42,
          borderRadius: '50%',
          background: `linear-gradient(135deg, ${leader.color}CC, ${leader.color}55)`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontFamily: BEBAS,
          fontSize: 18,
          color: BLACK,
          fontWeight: 900,
          flexShrink: 0,
        }}
      >
        {leader.name.charAt(0)}
      </div>

      {/* Info */}
      <div style={{ flex: 1 }}>
        <div style={{ fontFamily: BEBAS, fontSize: 22, color: WHITE, lineHeight: 1 }}>{leader.name}</div>
        <div style={{ fontFamily: INTER, fontSize: 12, color: '#555', marginTop: 1 }}>{leader.city}</div>
      </div>

      {/* Points */}
      <div style={{ fontFamily: BEBAS, fontSize: 26, color: ORANGE, lineHeight: 1 }}>
        {leader.pts.toLocaleString('fr-FR')}
      </div>
    </div>
  );
};

loadLocalFonts();

export const Leaderboard: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const sceneIn = interpolate(frame, [0, 18], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const sceneOut = interpolate(frame, [210, 240], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const opacity = sceneIn * sceneOut;

  const headerSpring = spring({ frame: frame - 5, fps, config: { damping: 22, stiffness: 300 } });

  const cutlineOpacity = interpolate(frame, [95, 120], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{ backgroundColor: '#080810', opacity }}>
      <Scanlines opacity={0.04} />

      {/* Top gradient */}
      <div
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          height: 300,
          background: `linear-gradient(180deg, ${ORANGE}0A 0%, transparent 100%)`,
          pointerEvents: 'none',
        }}
      />

      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'flex-start',
          paddingTop: 90,
          gap: 20,
        }}
      >
        {/* Title */}
        <div
          style={{
            opacity: headerSpring,
            transform: `scale(${interpolate(headerSpring, [0, 1], [0.92, 1])})`,
            textAlign: 'center',
          }}
        >
          <div style={{ fontFamily: BEBAS, fontSize: 30, color: ORANGE, letterSpacing: '10px' }}>
            CLASSEMENT NATIONAL
          </div>
          <div
            style={{
              fontFamily: BEBAS,
              fontSize: 100,
              color: WHITE,
              lineHeight: 0.9,
              letterSpacing: '-3px',
              textShadow: `0 0 60px ${ORANGE}44`,
            }}
          >
            TOP 50
          </div>
          <div
            style={{
              width: interpolate(frame, [8, 35], [0, 240], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }),
              height: 3,
              backgroundColor: ORANGE,
              margin: '6px auto 0',
              borderRadius: 2,
            }}
          />
        </div>

        {/* Rows + cut line */}
        <div style={{ width: '100%', padding: '0 44px', display: 'flex', flexDirection: 'column', gap: 8, boxSizing: 'border-box' }}>
          {LEADERS.map((leader, i) => (
            <React.Fragment key={leader.rank}>
              {i === 5 && (
                <div
                  style={{
                    opacity: cutlineOpacity,
                    display: 'flex',
                    alignItems: 'center',
                    gap: 12,
                    padding: '6px 0',
                  }}
                >
                  <div style={{ flex: 1, height: 1, backgroundColor: ORANGE }} />
                  <div
                    style={{
                      fontFamily: BEBAS,
                      fontSize: 15,
                      color: ORANGE,
                      letterSpacing: '4px',
                    }}
                  >
                    ACCÈS AU SOMMET G50
                  </div>
                  <div style={{ flex: 1, height: 1, backgroundColor: ORANGE }} />
                </div>
              )}
              <Row leader={leader} index={i} isLast50={leader.rank === 50} />
            </React.Fragment>
          ))}
        </div>
      </AbsoluteFill>

      <Vignette opacity={0.5} />
    </AbsoluteFill>
  );
};
