import React, { useMemo } from 'react';
import { AbsoluteFill, Easing, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { ORANGE } from './constants';

export const seededRandom = (seed: number): number => {
  const x = Math.sin(seed + 1) * 10000;
  return x - Math.floor(x);
};

// ─── Particle Field ────────────────────────────────────────────────────────────
export const ParticleField: React.FC<{
  count?: number;
  color?: string;
  converge?: number;
  centerX?: number;
  centerY?: number;
  maxOpacity?: number;
}> = ({ count = 60, color = ORANGE, converge = 0, centerX = 540, centerY = 960, maxOpacity = 0.6 }) => {
  const frame = useCurrentFrame();

  const particles = useMemo(
    () =>
      Array.from({ length: count }, (_, i) => ({
        x: seededRandom(i * 7.3) * 1080,
        y: seededRandom(i * 13.1) * 1920,
        size: seededRandom(i * 3.7) * 2.5 + 0.8,
        speed: seededRandom(i * 5.9) * 0.6 + 0.15,
        angle: seededRandom(i * 11.3) * Math.PI * 2,
        opacity: seededRandom(i * 17.7) * 0.5 + 0.2,
      })),
    [count],
  );

  return (
    <svg width={1080} height={1920} style={{ position: 'absolute', top: 0, left: 0, pointerEvents: 'none' }}>
      {particles.map((p, i) => {
        const drift = frame * p.speed;
        const bx = p.x + Math.cos(p.angle + drift * 0.018) * 28;
        const by = p.y + Math.sin(p.angle + drift * 0.018) * 28;
        const x = bx + (centerX - bx) * converge;
        const y = by + (centerY - by) * converge;
        return (
          <circle
            key={i}
            cx={x}
            cy={y}
            r={p.size * (1 + converge * 1.5)}
            fill={color}
            opacity={Math.min(p.opacity * maxOpacity * (1 - converge * 0.4), 1)}
          />
        );
      })}
    </svg>
  );
};

// ─── Glow Orb ──────────────────────────────────────────────────────────────────
export const GlowOrb: React.FC<{
  x: number;
  y: number;
  radius: number;
  color: string;
  opacity?: number;
}> = ({ x, y, radius, color, opacity = 0.3 }) => (
  <div
    style={{
      position: 'absolute',
      left: x - radius,
      top: y - radius,
      width: radius * 2,
      height: radius * 2,
      borderRadius: '50%',
      background: `radial-gradient(circle, ${color} 0%, transparent 70%)`,
      opacity,
      pointerEvents: 'none',
    }}
  />
);

// ─── Glitch Text ───────────────────────────────────────────────────────────────
export const GlitchText: React.FC<{ text: string; style?: React.CSSProperties }> = ({ text, style }) => {
  const frame = useCurrentFrame();
  const active = (frame % 9 < 3) || (frame % 23 < 2);
  const gx = active ? (seededRandom(frame * 1.3) - 0.5) * 18 : 0;
  const gy = active ? (seededRandom(frame * 2.7) - 0.5) * 4 : 0;

  return (
    <div style={{ position: 'relative', display: 'inline-block', ...style }}>
      <span style={{ position: 'relative', zIndex: 2 }}>{text}</span>
      {active && (
        <>
          <span
            style={{
              position: 'absolute',
              inset: 0,
              transform: `translate(${gx}px, ${gy}px)`,
              color: '#FF2244',
              opacity: 0.55,
              mixBlendMode: 'screen',
              zIndex: 1,
            }}
          >
            {text}
          </span>
          <span
            style={{
              position: 'absolute',
              inset: 0,
              transform: `translate(${-gx * 0.8}px, ${-gy}px)`,
              color: '#22CCFF',
              opacity: 0.45,
              mixBlendMode: 'screen',
              zIndex: 1,
            }}
          >
            {text}
          </span>
        </>
      )}
    </div>
  );
};

// ─── Draw Line ─────────────────────────────────────────────────────────────────
export const DrawLine: React.FC<{
  progress: number;
  color?: string;
  thickness?: number;
  width?: number;
}> = ({ progress, color = ORANGE, thickness = 3, width = 400 }) => (
  <div
    style={{
      width: progress * width,
      height: thickness,
      backgroundColor: color,
      borderRadius: thickness,
      transition: 'none',
    }}
  />
);

// ─── Vignette ──────────────────────────────────────────────────────────────────
export const Vignette: React.FC<{ opacity?: number }> = ({ opacity = 0.5 }) => (
  <AbsoluteFill
    style={{
      background: `radial-gradient(ellipse at center, transparent 40%, rgba(0,0,0,${opacity}) 100%)`,
      pointerEvents: 'none',
    }}
  />
);

// ─── Scanlines ─────────────────────────────────────────────────────────────────
export const Scanlines: React.FC<{ opacity?: number }> = ({ opacity = 0.04 }) => (
  <AbsoluteFill
    style={{
      backgroundImage: `repeating-linear-gradient(
        0deg,
        transparent,
        transparent 3px,
        rgba(0,0,0,${opacity * 20}) 3px,
        rgba(0,0,0,${opacity * 20}) 4px
      )`,
      pointerEvents: 'none',
    }}
  />
);

// ─── Noise Grain ───────────────────────────────────────────────────────────────
export const FilmGrain: React.FC = () => {
  const frame = useCurrentFrame();
  const offset = (frame * 137) % 1000;
  return (
    <AbsoluteFill
      style={{
        opacity: 0.025,
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' seed='${offset}'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E")`,
        backgroundSize: '200px 200px',
        pointerEvents: 'none',
      }}
    />
  );
};

// ─── Word Impact ───────────────────────────────────────────────────────────────
export const ImpactWord: React.FC<{
  text: string;
  delay: number;
  color: string;
  fontSize: number;
  fontFamily: string;
}> = ({ text, delay, color, fontSize, fontFamily }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const s = spring({
    frame: frame - delay,
    fps,
    config: { damping: 11, stiffness: 280, mass: 0.9 },
  });

  const scale = interpolate(s, [0, 1], [1.35, 1]);
  const opacity = interpolate(frame - delay, [0, 4], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <div
      style={{
        fontFamily,
        fontSize,
        fontWeight: 900,
        color,
        lineHeight: 1,
        letterSpacing: '-2px',
        textTransform: 'uppercase',
        transform: `scale(${scale})`,
        opacity,
        display: 'inline-block',
      }}
    >
      {text}
    </div>
  );
};

// ─── Animated Count ────────────────────────────────────────────────────────────
export const AnimatedCount: React.FC<{
  from: number;
  to: number;
  startFrame: number;
  endFrame: number;
  locale?: string;
  style?: React.CSSProperties;
}> = ({ from, to, startFrame, endFrame, locale = 'fr-FR', style }) => {
  const frame = useCurrentFrame();
  const progress = interpolate(frame, [startFrame, endFrame], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
    easing: Easing.out(Easing.cubic),
  });
  const value = Math.floor(from + (to - from) * progress);
  return <span style={style}>{value.toLocaleString(locale)}</span>;
};
