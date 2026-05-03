import React from 'react';
import { AbsoluteFill, Sequence, useCurrentFrame } from 'remotion';
import { BG } from './constants';
import { GlobalProgress } from './atoms';
import { Opening } from './Opening';
import { Problem } from './Problem';
import { SolutionSplit } from './SolutionSplit';
import { AppScene } from './AppScene';
import { Writing } from './Writing';
import { G50 } from './G50';
import { FranceScene } from './FranceScene';
import { Final } from './Final';

// Scene boundaries (frames at 30fps)
const S1 = 0;
const S2 = 90;
const S3 = 270;
const S4 = 450;
const S5 = 630;
const S6 = 780;
const S7 = 960;
const S8 = 1080;
const TOTAL = 1800;

// Cross-fade overlay between scenes
const Fade: React.FC<{ at: number }> = ({ at }) => {
  const frame = useCurrentFrame();
  const op = frame >= at && frame < at + 8 ? 1 - (frame - at) / 8 :
             frame >= at - 8 && frame < at  ? (frame - (at - 8)) / 8 : 0;
  if (op <= 0) return null;
  return <AbsoluteFill style={{ backgroundColor: '#FFFFFF', opacity: op, zIndex: 50, pointerEvents: 'none' }} />;
};

export const MandatZero: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: BG }}>

      {/* S1 — Opening (0–90) */}
      <Sequence from={S1} durationInFrames={S2 - S1 + 8}>
        <Opening />
      </Sequence>

      {/* S2 — Problem (90–270) */}
      <Sequence from={S2} durationInFrames={S3 - S2 + 8}>
        <Problem />
      </Sequence>

      {/* S3 — Solution Split (270–450) */}
      <Sequence from={S3} durationInFrames={S4 - S3 + 8}>
        <SolutionSplit />
      </Sequence>

      {/* S4 — App Scene (450–630) */}
      <Sequence from={S4} durationInFrames={S5 - S4 + 8}>
        <AppScene />
      </Sequence>

      {/* S5 — Writing (630–780) */}
      <Sequence from={S5} durationInFrames={S6 - S5 + 8}>
        <Writing />
      </Sequence>

      {/* S6 — G50 (780–960) */}
      <Sequence from={S6} durationInFrames={S7 - S6 + 8}>
        <G50 />
      </Sequence>

      {/* S7 — France Scene (960–1080) */}
      <Sequence from={S7} durationInFrames={S8 - S7 + 8}>
        <FranceScene />
      </Sequence>

      {/* S8 — Final (1080–1800) */}
      <Sequence from={S8} durationInFrames={TOTAL - S8}>
        <Final />
      </Sequence>

      {/* Cross-fade dips between scenes */}
      <Fade at={S2} />
      <Fade at={S3} />
      <Fade at={S4} />
      <Fade at={S5} />
      <Fade at={S6} />
      <Fade at={S7} />
      <Fade at={S8} />

      {/* Global progress bar */}
      <GlobalProgress total={TOTAL} />
    </AbsoluteFill>
  );
};
