import React, { useMemo } from 'react';
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from 'remotion';
import { loadLocalFonts, SYNE, DM } from './fonts';
import { BG, NAVY, ORANGE, GRAY } from './constants';
import { sr, ic, sp } from './atoms';

loadLocalFonts();

const CITIES = [
  { name: 'PARIS',     missions: 14 },
  { name: 'LYON',      missions: 9  },
  { name: 'MARSEILLE', missions: 11 },
  { name: 'BORDEAUX',  missions: 7  },
  { name: 'LILLE',     missions: 8  },
  { name: 'BOMPAS',    missions: 3  },
];

const PARTOUT = 'PARTOUT.'.split('');

const CityCard: React.FC<{ city: typeof CITIES[0]; idx: number; scatter: number }> = ({ city, idx, scatter }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Random fly-in direction per card (deterministic)
  const angle = sr(idx * 7 + 1) * Math.PI * 2;
  const dist  = 900 + sr(idx * 7 + 2) * 300;
  const fromX = Math.cos(angle) * dist;
  const fromY = Math.sin(angle) * dist;

  const delay = idx * 18;
  const arrS  = sp(frame, fps, delay, 8, 220);

  // Grid positions (2 columns × 3 rows), centered
  const col = idx % 2;
  const row = Math.floor(idx / 2);
  const cardW = 200, cardH = 220, gapX = 40, gapY = 32;
  const totalW = cardW * 2 + gapX;
  const totalH = cardH * 3 + gapY * 2;
  const gridX  = col * (cardW + gapX) - totalW / 2 + cardW / 2;
  const gridY  = row * (cardH + gapY) - totalH / 2 + cardH / 2;

  const x = ic(arrS, [0, 1], [fromX, gridX]) + scatter * (fromX * 0.4);
  const y = ic(arrS, [0, 1], [fromY, gridY]) + scatter * (fromY * 0.4);
  const op = ic(arrS, [0, 0.2], [0, 1]) * (1 - scatter);

  // Pulsing dot
  const dotScale = 0.85 + Math.sin(frame * 0.12 + idx) * 0.15;

  return (
    <div style={{
      position: 'absolute',
      width: cardW,
      height: cardH,
      left: '50%',
      top: '50%',
      transform: `translate(calc(-50% + ${x}px), calc(-50% + ${y}px))`,
      opacity: op,
      backgroundColor: '#FFFFFF',
      borderRadius: 16,
      border: `2px solid ${NAVY}22`,
      boxShadow: '0 12px 40px rgba(27,42,74,0.12)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 10,
      padding: '20px 16px',
    }}>
      <div style={{
        width: 10,
        height: 10,
        borderRadius: '50%',
        backgroundColor: ORANGE,
        transform: `scale(${dotScale})`,
        boxShadow: `0 0 ${6 + dotScale * 4}px ${ORANGE}88`,
      }} />
      <div style={{ fontFamily: SYNE, fontSize: 28, fontWeight: 800, color: NAVY, letterSpacing: '-0.5px', textAlign: 'center', lineHeight: 1 }}>
        {city.name}
      </div>
      <div style={{ fontFamily: DM, fontSize: 18, color: GRAY, fontWeight: 400, textAlign: 'center', lineHeight: 1.3 }}>
        {city.missions} missions<br />actives
      </div>
    </div>
  );
};

export const FranceScene: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  // Cards scatter at frame 80
  const scatterS = sp(frame, fps, 80, 10, 160);
  const scatter  = ic(scatterS, [0, 1], [0, 1]);

  // "PARTOUT." assembles letter by letter from frame 85
  const burstOp = ic(frame, [78, 82], [0, 1]);

  // 35-particle burst
  const particles = useMemo(() =>
    Array.from({ length: 35 }, (_, i) => ({
      angle: (i / 35) * Math.PI * 2,
      speed: 180 + sr(i * 3) * 220,
      size:  3 + sr(i * 3 + 1) * 5,
    })), []);

  return (
    <AbsoluteFill style={{ backgroundColor: BG }}>
      {/* City cards */}
      {CITIES.map((city, i) => (
        <CityCard key={i} city={city} idx={i} scatter={scatter} />
      ))}

      {/* Particle burst */}
      <AbsoluteFill style={{ opacity: burstOp, pointerEvents: 'none' }}>
        {particles.map((p, i) => {
          const t = Math.max(0, frame - 80) / 30;
          const r = p.speed * t * Math.exp(-t * 1.8);
          const px = 540 + Math.cos(p.angle) * r;
          const py = 960 + Math.sin(p.angle) * r;
          const pop = interpolate(Math.min(t, 1), [0, 0.15, 1], [0, 1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
          return (
            <div key={i} style={{
              position: 'absolute',
              left: px - p.size / 2,
              top: py - p.size / 2,
              width: p.size,
              height: p.size,
              borderRadius: '50%',
              backgroundColor: i % 3 === 0 ? NAVY : ORANGE,
              opacity: pop,
            }} />
          );
        })}
      </AbsoluteFill>

      {/* "PARTOUT." letter reveal */}
      <AbsoluteFill style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', pointerEvents: 'none' }}>
        <div style={{ display: 'flex' }}>
          {PARTOUT.map((char, i) => {
            const lDelay = 85 + i * 6;
            const lS = sp(frame, fps, lDelay, 6, 300);
            const angle2 = sr(i * 5) * Math.PI * 2;
            const lFromX = Math.cos(angle2) * 400;
            const lFromY = Math.sin(angle2) * 400;
            const lX = ic(lS, [0, 1], [lFromX, 0]);
            const lY = ic(lS, [0, 1], [lFromY, 0]);
            return (
              <div key={i} style={{
                fontFamily: SYNE,
                fontSize: 150,
                fontWeight: 900,
                color: NAVY,
                lineHeight: 1,
                letterSpacing: '-4px',
                opacity: lS,
                transform: `translate(${lX}px, ${lY}px)`,
              }}>
                {char}
              </div>
            );
          })}
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
