import React from 'react';
import { AbsoluteFill, Sequence } from 'remotion';
import { BLACK } from './constants';
import { Opening } from './Opening';
import { Problem } from './Problem';
import { AppReveal } from './AppReveal';
import { HowItWorks } from './HowItWorks';
import { Leaderboard } from './Leaderboard';
import { Summit } from './Summit';
import { Manifesto } from './Manifesto';
import { Outro } from './Outro';

export const MandatZero: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: BLACK }}>
      {/* 0–7s: Cinematic opening — particles converge into the logo */}
      <Sequence from={0} durationInFrames={210}>
        <Opening />
      </Sequence>

      {/* 7–17s: The problem — nepotism statistics */}
      <Sequence from={210} durationInFrames={300}>
        <Problem />
      </Sequence>

      {/* 17–26s: The solution — app mockup */}
      <Sequence from={510} durationInFrames={270}>
        <AppReveal />
      </Sequence>

      {/* 26–36s: How it works — 4 steps */}
      <Sequence from={780} durationInFrames={300}>
        <HowItWorks />
      </Sequence>

      {/* 36–44s: National leaderboard */}
      <Sequence from={1080} durationInFrames={240}>
        <Leaderboard />
      </Sequence>

      {/* 44–52s: G50 Summit reveal */}
      <Sequence from={1320} durationInFrames={240}>
        <Summit />
      </Sequence>

      {/* 52–57s: The manifesto — word by word impact */}
      <Sequence from={1560} durationInFrames={150}>
        <Manifesto />
      </Sequence>

      {/* 57–60s: Outro — logo, URL, CTA */}
      <Sequence from={1710} durationInFrames={90}>
        <Outro />
      </Sequence>
    </AbsoluteFill>
  );
};
