import React from 'react';
import { AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig } from 'remotion';
import { loadLocalFonts, SYNE } from './fonts';
import { BLACK, NAVY, ORANGE, BG } from './constants';
import { FloatShape, ic, sp } from './atoms';

loadLocalFonts();

// Floating particles config — deterministic
const SHAPES = [
  { x: 120,  y: 280,  size: 28, shape: 'circle' as const, phase: 0.0 },
  { x: 960,  y: 340,  size: 22, shape: 'square' as const, phase: 1.1 },
  { x: 200,  y: 700,  size: 18, shape: 'circle' as const, phase: 2.2 },
  { x: 880,  y: 620,  size: 32, shape: 'square' as const, phase: 0.7 },
  { x: 80,   y: 1100, size: 14, shape: 'circle' as const, phase: 3.1 },
  { x: 1000, y: 1000, size: 24, shape: 'circle' as const, phase: 1.8 },
  { x: 300,  y: 1400, size: 20, shape: 'square' as const, phase: 0.4 },
  { x: 780,  y: 1350, size: 16, shape: 'circle' as const, phase: 2.5 },
  { x: 540,  y: 180,  size: 12, shape: 'square' as const, phase: 1.4 },
  { x: 160,  y: 1650, size: 26, shape: 'circle' as const, phase: 3.7 },
  { x: 920,  y: 1580, size: 19, shape: 'square' as const, phase: 0.9 },
  { x: 460,  y: 1740, size: 15, shape: 'circle' as const, phase: 2.0 },
  { x: 700,  y: 200,  size: 21, shape: 'circle' as const, phase: 1.6 },
  { x: 370,  y: 440,  size: 17, shape: 'square' as const, phase: 3.3 },
  { x: 840,  y: 880,  size: 30, shape: 'circle' as const, phase: 0.2 },
  { x: 220,  y: 960,  size: 13, shape: 'square' as const, phase: 2.8 },
  { x: 680,  y: 1500, size: 25, shape: 'circle' as const, phase: 1.2 },
  { x: 100,  y: 1850, size: 11, shape: 'square' as const, phase: 3.9 },
  { x: 980,  y: 1780, size: 23, shape: 'circle' as const, phase: 0.6 },
  { x: 540,  y: 1920, size: 18, shape: 'square' as const, phase: 2.1 },
];

export const Opening: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // ── Phase 0: horizontal white line draws from center (0-10)
  const lineW = ic(frame, [0, 10], [0, 1080], (t) => t);

  // ── MANDAT slams from top (frame 12), ZÉRO from bottom (frame 18)
  const mandatS = sp(frame, fps, 12, 8, 200);
  const zeroS   = sp(frame, fps, 18, 8, 200);
  const mandatY = ic(mandatS, [0, 1], [-300, 0]);
  const zeroY   = ic(zeroS,   [0, 1], [300, 0]);

  // ── Scale overshoot at 30 — both words pulse 1→1.08→1
  const pulse = sp(frame, fps, 30, 6, 300);
  const scaleWords = interpolate(pulse, [0, 0.6, 1], [1, 1.08, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // ── Flash at 45-46
  const flash = interpolate(frame, [45, 46, 48, 52], [0, 1, 0.6, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });

  // ── Text: white → navy at 54
  const textColorProgress = ic(frame, [50, 56], [0, 1]);
  const textColor = textColorProgress > 0.5 ? NAVY : '#FFFFFF';

  // ── Orange underline under ZÉRO draws left→right (60-90)
  const underlineW = ic(frame, [60, 80], [0, 400]);

  // ── Particles appear after flash
  const particleOp = ic(frame, [50, 70], [0, 1]);

  return (
    <AbsoluteFill style={{ backgroundColor: ic(frame, [47, 54], [0, 1]) > 0.5 ? BG : BLACK }}>

      {/* Floating shapes */}
      {SHAPES.map((s, i) => (
        <div key={i} style={{ opacity: particleOp }}>
          <FloatShape {...s} color={ORANGE} />
        </div>
      ))}

      {/* White flash */}
      <AbsoluteFill style={{ backgroundColor: '#FFFFFF', opacity: flash, pointerEvents: 'none' }} />

      {/* Horizontal line */}
      <div style={{
        position: 'absolute',
        top: '50%',
        left: (1080 - lineW) / 2,
        width: lineW,
        height: 2,
        backgroundColor: '#FFFFFF',
        opacity: ic(frame, [0, 8], [0, 1]) * ic(frame, [42, 46], [1, 0]),
      }} />

      {/* MANDAT + ZÉRO */}
      <AbsoluteFill style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 0 }}>
        <div style={{
          transform: `translateY(${mandatY}px) scale(${scaleWords})`,
          fontFamily: SYNE,
          fontSize: 110,
          fontWeight: 900,
          color: textColor,
          letterSpacing: '4px',
          lineHeight: 1,
          opacity: mandatS,
        }}>MANDAT</div>

        <div style={{
          transform: `translateY(${zeroY}px) scale(${scaleWords})`,
          fontFamily: SYNE,
          fontSize: 110,
          fontWeight: 900,
          color: ic(frame, [50, 58], [0, 1]) > 0.5 ? ORANGE : '#FFFFFF',
          letterSpacing: '4px',
          lineHeight: 1,
          opacity: zeroS,
        }}>ZÉRO</div>

        {/* Orange underline */}
        <div style={{
          width: underlineW,
          height: 4,
          backgroundColor: ORANGE,
          borderRadius: 2,
          marginTop: 8,
          alignSelf: 'center',
        }} />
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
