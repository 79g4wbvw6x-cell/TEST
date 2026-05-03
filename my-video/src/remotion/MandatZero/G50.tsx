import React from 'react';
import { AbsoluteFill, useCurrentFrame, useVideoConfig } from 'remotion';
import { loadLocalFonts, SYNE, DM } from './fonts';
import { BG, NAVY, ORANGE } from './constants';
import { ic, sp, SceneWrap, OrangeLine, WordReveal } from './atoms';

loadLocalFonts();

// ── Hemicycle: 3 rows of curved seats ─────────────────────────────────────────
// Row i has seats arranged along an arc. Total = 51 seats (17 per row).
const ROWS = 3;
const SEATS_PER_ROW = 17;
const CX = 540;
const CY = 620; // arc center (below visible area gives proper curvature)
const ROW_RADII = [310, 380, 450];
const ARC_SPAN = Math.PI * 0.72; // arc from -span/2 to +span/2

interface Seat { row: number; col: number; x: number; y: number; globalIdx: number }

const seats: Seat[] = [];
for (let r = 0; r < ROWS; r++) {
  const radius = ROW_RADII[r];
  for (let c = 0; c < SEATS_PER_ROW; c++) {
    const angle = -ARC_SPAN / 2 + (c / (SEATS_PER_ROW - 1)) * ARC_SPAN - Math.PI / 2;
    seats.push({
      row: r,
      col: c,
      x: CX + Math.cos(angle) * radius,
      y: CY + Math.sin(angle) * radius,
      globalIdx: r * SEATS_PER_ROW + c,
    });
  }
}

const Hemicycle: React.FC<{ rowProgress: number[]; seatProgress: number[] }> = ({
  rowProgress,
  seatProgress,
}) => (
  <svg width={1080} height={520} viewBox="0 0 1080 520" style={{ display: 'block' }}>
    {/* Row outlines first */}
    {Array.from({ length: ROWS }, (_, r) => {
      const rp = rowProgress[r] ?? 0;
      if (rp <= 0) return null;
      const radius = ROW_RADII[r];
      const startAngle = -ARC_SPAN / 2 - Math.PI / 2;
      const endAngle   =  ARC_SPAN / 2 - Math.PI / 2;
      const sx = CX + Math.cos(startAngle) * radius;
      const sy = CY + Math.sin(startAngle) * radius;
      const ex = CX + Math.cos(endAngle)   * radius;
      const ey = CY + Math.sin(endAngle)   * radius;
      // Approximate arc length for dasharray
      const arcLen = radius * ARC_SPAN;
      return (
        <path
          key={r}
          d={`M ${sx} ${sy} A ${radius} ${radius} 0 0 1 ${ex} ${ey}`}
          fill="none"
          stroke={NAVY}
          strokeWidth={1.5}
          opacity={0.25}
          strokeDasharray={arcLen}
          strokeDashoffset={arcLen * (1 - rp)}
        />
      );
    })}
    {/* Seats */}
    {seats.map((s) => {
      const p = seatProgress[s.globalIdx] ?? 0;
      if (p <= 0) return null;
      const scale = Math.min(p * 1.2, 1);
      const filled = s.globalIdx < 50;
      return (
        <g key={s.globalIdx} transform={`translate(${s.x}, ${s.y}) scale(${scale})`}>
          <rect
            x={-7} y={-5} width={14} height={11} rx={2}
            fill={filled ? ORANGE : 'none'}
            stroke={filled ? ORANGE : NAVY}
            strokeWidth={1.5}
            opacity={filled ? 0.9 : 0.3}
          />
        </g>
      );
    })}
    {/* Speaker podium */}
    <rect x={510} y={470} width={60} height={40} rx={4} fill={NAVY} opacity={0.15} />
    <rect x={520} y={460} width={40} height={12} rx={2} fill={NAVY} opacity={0.25} />
  </svg>
);

export const G50: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const dur = 150;

  // "50" drops from top at frame 0
  const dropS = sp(frame, fps, 0, 10, 150);
  const dropY = ic(dropS, [0, 1], [-300, 0]);

  // "50" transforms: scale to 120px at frame 30, while "Les" and "meilleurs." slide in
  const shrinkS = sp(frame, fps, 28, 20, 180);
  const bigSize = ic(shrinkS, [0, 1], [240, 120]);
  const labelOp = ic(frame, [32, 45], [0, 1]);

  // Hemicycle rows draw at frames 40, 50, 60
  const rowProgress = [0, 1, 2].map((r) => ic(frame, [40 + r * 10, 60 + r * 10], [0, 1]));

  // Seats pop in: 2 frames apart, left-to-right across all rows
  const seatProgress = seats.map((s) => {
    const start = 70 + s.globalIdx * 1.4;
    return sp(frame, fps, Math.round(start), 9, 300);
  });

  // "SOMMET G50" text
  const textOp = ic(frame, [140, 152], [0, 1]);

  // Orange underline under "50" in the headline
  const underW = ic(frame, [34, 52], [0, 160]);

  return (
    <SceneWrap dur={dur} bg={BG}>
      <AbsoluteFill style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-start', paddingTop: 150, gap: 0 }}>

        {/* "Les 50 meilleurs." headline */}
        <div style={{
          display: 'flex',
          alignItems: 'baseline',
          gap: 16,
          transform: `translateY(${dropY}px)`,
          opacity: dropS,
        }}>
          <div style={{
            fontFamily: SYNE,
            fontSize: labelOp > 0.5 ? 72 : 0,
            fontWeight: 800,
            color: NAVY,
            opacity: labelOp,
            transition: 'none',
          }}>Les</div>

          <div style={{ position: 'relative' }}>
            <div style={{
              fontFamily: SYNE,
              fontSize: bigSize,
              fontWeight: 900,
              color: NAVY,
              lineHeight: 1,
            }}>50</div>
            {/* Underline under "50" only */}
            <div style={{
              position: 'absolute',
              bottom: -4,
              left: 0,
              height: 4,
              width: underW,
              backgroundColor: ORANGE,
              borderRadius: 2,
            }} />
          </div>

          <div style={{
            fontFamily: SYNE,
            fontSize: labelOp > 0.5 ? 72 : 0,
            fontWeight: 800,
            color: NAVY,
            opacity: labelOp,
          }}>meilleurs.</div>
        </div>

        {/* Hemicycle */}
        <div style={{ marginTop: 32, opacity: ic(frame, [38, 48], [0, 1]) }}>
          <Hemicycle rowProgress={rowProgress} seatProgress={seatProgress} />
        </div>

        {/* "SOMMET G50" + subtitle */}
        <div style={{ opacity: textOp, textAlign: 'center', marginTop: 16 }}>
          <div style={{ fontFamily: SYNE, fontSize: 64, fontWeight: 800, color: ORANGE, lineHeight: 1 }}>
            SOMMET G50
          </div>
          <OrangeLine startFrame={144} width={320} />
          <div style={{ fontFamily: DM, fontSize: 36, color: NAVY, marginTop: 12, fontWeight: 500 }}>
            <WordReveal text="Au cœur du Sénat." startFrame={148} framesPerWord={7} />
          </div>
        </div>
      </AbsoluteFill>
    </SceneWrap>
  );
};
