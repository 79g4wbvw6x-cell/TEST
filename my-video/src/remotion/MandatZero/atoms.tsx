import React, { useMemo } from 'react';
import { AbsoluteFill, Easing, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { ORANGE } from './constants';

// ── Seeded RNG ────────────────────────────────────────────────────────────────
export const sr = (seed: number) => { const x = Math.sin(seed + 1) * 10000; return x - Math.floor(x); };

// ── Spring helper ─────────────────────────────────────────────────────────────
export const sp = (frame: number, fps: number, delay = 0, damping = 14, stiffness = 120, mass = 1) =>
  spring({ frame: frame - delay, fps, config: { damping, stiffness, mass } });

// ── Interpolate with clamp ────────────────────────────────────────────────────
export const ic = (v: number, i: [number, number], o: [number, number], easing?: (t: number) => number) =>
  interpolate(v, i, o, { extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing });

// ── Scene wrapper — fades in over 8f, out over 6f ────────────────────────────
export const SceneWrap: React.FC<{ children: React.ReactNode; dur: number; bg?: string }> = ({
  children, dur, bg = '#FFFFFF',
}) => {
  const frame = useCurrentFrame();
  const opacity = Math.min(
    ic(frame, [0, 8], [0, 1]),
    ic(frame, [dur - 6, dur], [1, 0]),
  );
  return <AbsoluteFill style={{ backgroundColor: bg, opacity }}>{children}</AbsoluteFill>;
};

// ── Orange underline that draws itself ────────────────────────────────────────
export const OrangeLine: React.FC<{ startFrame: number; width?: number; height?: number }> = ({
  startFrame, width = '100%' as unknown as number, height = 4,
}) => {
  const frame = useCurrentFrame();
  const pct = ic(frame, [startFrame, startFrame + 20], [0, 1], Easing.out(Easing.cubic));
  return (
    <div style={{
      height,
      width: typeof width === 'number' ? pct * width : width,
      maxWidth: typeof width === 'number' ? undefined : `${pct * 100}%`,
      backgroundColor: ORANGE,
      borderRadius: 2,
    }} />
  );
};

// ── Character-by-character reveal ─────────────────────────────────────────────
export const CharReveal: React.FC<{
  text: string;
  startFrame: number;
  framesPerChar?: number;
  style?: React.CSSProperties;
}> = ({ text, startFrame, framesPerChar = 1, style }) => {
  const frame = useCurrentFrame();
  return (
    <span style={{ display: 'inline-block', ...style }}>
      {text.split('').map((ch, i) => {
        const f0 = startFrame + i * framesPerChar;
        const op = ic(frame, [f0, f0 + 3], [0, 1]);
        return (
          <span key={i} style={{ display: 'inline-block', opacity: op, whiteSpace: ch === ' ' ? 'pre' : undefined }}>
            {ch === ' ' ? ' ' : ch}
          </span>
        );
      })}
    </span>
  );
};

// ── Word-by-word reveal ───────────────────────────────────────────────────────
export const WordReveal: React.FC<{
  text: string;
  startFrame: number;
  framesPerWord?: number;
  style?: React.CSSProperties;
}> = ({ text, startFrame, framesPerWord = 6, style }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const words = text.split(' ');
  return (
    <span style={{ display: 'inline', ...style }}>
      {words.map((w, i) => {
        const delay = startFrame + i * framesPerWord;
        const s = sp(frame, fps, delay, 22, 240);
        const y = ic(s, [0, 1], [14, 0]);
        return (
          <span key={i} style={{ display: 'inline-block', opacity: s, transform: `translateY(${y}px)` }}>
            {w}{i < words.length - 1 ? ' ' : ''}
          </span>
        );
      })}
    </span>
  );
};

// ── Spring-enter text block ───────────────────────────────────────────────────
export const SpringText: React.FC<{
  children: React.ReactNode;
  delay: number;
  fromY?: number;
  fromX?: number;
  fromScale?: number;
  damping?: number;
  stiffness?: number;
  style?: React.CSSProperties;
}> = ({ children, delay, fromY = 40, fromX = 0, fromScale = 1, damping = 14, stiffness = 120, style }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = sp(frame, fps, delay, damping, stiffness);
  const y = ic(s, [0, 1], [fromY, 0]);
  const x = ic(s, [0, 1], [fromX, 0]);
  const scale = ic(s, [0, 1], [fromScale, 1]);
  return (
    <div style={{ opacity: s, transform: `translateY(${y}px) translateX(${x}px) scale(${scale})`, ...style }}>
      {children}
    </div>
  );
};

// ── Floating geometric shape (oscillates forever) ─────────────────────────────
export const FloatShape: React.FC<{
  x: number; y: number; size: number; shape: 'circle' | 'square';
  color: string; phase: number; speed?: number; opacity?: number;
}> = ({ x, y, size, shape, color, phase, speed = 0.05, opacity = 0.18 }) => {
  const frame = useCurrentFrame();
  const dy = Math.sin(frame * speed + phase) * 18;
  const dx = Math.cos(frame * speed * 0.7 + phase) * 10;
  const rot = frame * speed * 15 + phase * 30;
  return (
    <div style={{
      position: 'absolute',
      left: x - size / 2,
      top: y - size / 2 + dy,
      transform: `translateX(${dx}px) rotate(${rot}deg)`,
      width: size,
      height: size,
      borderRadius: shape === 'circle' ? '50%' : 4,
      backgroundColor: color,
      opacity,
      pointerEvents: 'none',
    }} />
  );
};

// ── Particle burst ────────────────────────────────────────────────────────────
export const Burst: React.FC<{ startFrame: number; count?: number; color?: string; cx?: number; cy?: number }> = ({
  startFrame, count = 30, color = ORANGE, cx = 540, cy = 960,
}) => {
  const frame = useCurrentFrame();
  const particles = useMemo(
    () => Array.from({ length: count }, (_, i) => ({
      angle: (i / count) * Math.PI * 2 + sr(i) * 0.5,
      speed: sr(i * 7) * 300 + 80,
      size: sr(i * 3) * 10 + 5,
    })),
    [count],
  );
  return (
    <svg width={1080} height={1920} style={{ position: 'absolute', pointerEvents: 'none' }}>
      {particles.map((p, i) => {
        const t = ic(frame, [startFrame, startFrame + 20], [0, 1], Easing.out(Easing.cubic));
        const fadeOut = ic(frame, [startFrame + 8, startFrame + 20], [1, 0]);
        const px = cx + Math.cos(p.angle) * p.speed * t;
        const py = cy + Math.sin(p.angle) * p.speed * t;
        return <circle key={i} cx={px} cy={py} r={p.size * (1 - t * 0.5)} fill={color} opacity={fadeOut * 0.7} />;
      })}
    </svg>
  );
};

// ── Global progress bar ───────────────────────────────────────────────────────
export const GlobalProgress: React.FC<{ total: number }> = ({ total }) => {
  const frame = useCurrentFrame();
  const pct = ic(frame, [0, total], [0, 100]);
  return (
    <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, height: 3, backgroundColor: 'rgba(255,107,43,0.15)', zIndex: 100 }}>
      <div style={{ width: `${pct}%`, height: '100%', backgroundColor: ORANGE, borderRadius: 2 }} />
    </div>
  );
};
