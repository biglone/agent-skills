# 60-Minute Interview Pack (C++ / Mid)

Generated at (UTC): 2026-03-05T22:16:05+00:00
Duration: 60 minutes

## Interview Agenda

- 0-5 min: warm-up and context alignment
- 5-35 min: core technical questions (Mid level)
- 35-45 min: latest-topic deep dive
- 45-55 min: scenario tradeoff and risk discussion
- 55-60 min: candidate questions and wrap-up

## Core Questions

1. Refactor pointer-heavy legacy code to modern C++ style.
2. Diagnose data race in multithreaded producer-consumer code.
3. Choose between lock-based and lock-free approach for module X.

## Follow-up Script

- Which memory ordering assumptions are required?
- How do you prove correctness under load?

## Latest-Topic Deep Dive

1. Flavours of Reflection -- Bernard Teo
   - Source: https://isocpp.org//blog/2026/03/flavours-of-reflection-bernard-teo
   - Ask: Based on this topic, explain engineering impact and rollout/testing plan.
2. IIFE for Complex Initialization -- Bartlomiej Filipek
   - Source: https://isocpp.org//blog/2026/02/iife-for-complex-initialization-bartlomiej-filipek1
   - Ask: Based on this topic, explain engineering impact and rollout/testing plan.

## Scoring Anchors (1-5)

- `1`: unsafe concurrency reasoning
- `3`: workable refactor + race mitigation plan
- `5`: explicit tradeoffs on correctness/perf/complexity with tests

## Redlines

- Cannot identify race condition impact on correctness

## Scorecard

| Dimension | Score (1-5) | Evidence |
|-----------|-------------|----------|
| C++ fundamentals | | |
| C++ practical execution | | |
| System/risk judgment | | |
| Communication clarity | | |

## Decision Rule

- Recommended threshold (Mid): Avg >= 3.6 and no core domain < 3
- Decision: Hire / Hold / No-hire
- Notes: include 2-3 strongest evidence points
