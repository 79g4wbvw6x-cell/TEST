import React from 'react';
import { BEBAS, loadLocalFonts } from './fonts';
import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';
import { CHARCOAL, ORANGE, WHITE } from './constants';
import { FilmGrain, ParticleField, Vignette } from './atoms';


const WORDS = [
  { text: 'FINI', delay: 4, color: WHITE, size: 182, shake: true },
  { text: 'LE', delay: 18, color: WHITE, size: 110, shake: false },
  { text: 'PISTON.', delay: 28, color: WHITE, size: 148, shake: true },
  { text: 'PLACE', delay: 60, color: ORANGE, size: 182, shake: true },
  { text: 'AU', delay: 74, color: ORANGE, size: 110, shake: false },
  { text: 'MÉRITE.', delay: 84, color: ORANGE, size: 148, shake: true },
];

const WordImpact: React.FC<{ word: (typeof WORDS)[0] }> = ({ word }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const s = spring({ frame: frame - word.delay, fps, config: { damping: 9, stiffness: 320, mass: 0.85 } });
  const scale = interpolate(s, [0, 1], [1.4, 1]);
  const opacity = interpolate(frame - word.delay, [0, 5], [0, 1], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  // Subtle shake on impact
  const shakeX =
    word.shake && frame >= word.delay && frame < word.delay + 6
      ? Math.sin(frame * 40) * interpolate(frame - word.delay, [0, 6], [3, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' })
      : 0;

  return (
    <div
      style={{
        fontFamily: BEBAS,
        fontSize: word.size,
        color: word.color,
        lineHeight: 0.95,
        letterSpacing: '-2px',
        transform: `scale(${scale}) translateX(${shakeX}px)`,
        opacity,
        textShadow: word.color === ORANGE ? `0 0 60px ${ORANGE}66` : `0 0 40px rgba(255,255,255,0.15)`,
      }}
    >
      {word.text}
    </div>
  );
};

loadLocalFonts();

export const Manifesto: React.FC = () => {
  const frame = useCurrentFrame();

  const sceneIn = interpolate(frame, [0, 12], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const sceneOut = interpolate(frame, [128, 150], [1, 0], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  const opacity = sceneIn * sceneOut;

  // After MÉRITE appears, background flashes orange
  const bgFlash = interpolate(frame, [84, 88, 100, 120], [0, 0.18, 0.06, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{ backgroundColor: CHARCOAL, opacity }}>
      {/* Orange burst flash */}
      <AbsoluteFill style={{ backgroundColor: ORANGE, opacity: bgFlash }} />

      <ParticleField count={35} color={ORANGE} maxOpacity={0.25} />
      <FilmGrain />

      <AbsoluteFill
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 4,
        }}
      >
        {WORDS.map((word, i) => (
          <WordImpact key={i} word={word} />
        ))}
      </AbsoluteFill>

      <Vignette opacity={0.55} />
    </AbsoluteFill>
  );
};
