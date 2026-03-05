# 60-Minute Interview Pack (Qt / Mid)

Generated at (UTC): 2026-03-05T22:16:05+00:00
Duration: 60 minutes

## Interview Agenda

- 0-5 min: warm-up and context alignment
- 5-35 min: core technical questions (Mid level)
- 35-45 min: latest-topic deep dive
- 45-55 min: scenario tradeoff and risk discussion
- 55-60 min: candidate questions and wrap-up

## Core Questions

1. Design a medium Qt app module split (UI/service/data).
2. Compare `QThread`, worker-object pattern, and task-based model.
3. How to optimize high-frequency UI updates (charts/telemetry)?

## Follow-up Script

- Where will lifetime bugs likely happen?
- What tests catch regressions earliest?

## Latest-Topic Deep Dive

1. Accelerated 2D Canvas Benchmarks
   - Source: https://www.qt.io/blog/accelerated-2d-canvas-benchmarks
   - Ask: Based on this topic, explain engineering impact and rollout/testing plan.
2. What's new in QML Tooling in 6.11, part 1: QML Language Server (qmlls)
   - Source: https://www.qt.io/blog/whats-new-in-qml-language-server-in-6.11
   - Ask: Based on this topic, explain engineering impact and rollout/testing plan.

## Scoring Anchors (1-5)

- `1`: architecture is vague, no ownership model
- `3`: clear module boundaries and workable threading plan
- `5`: gives explicit ownership, performance budget, and rollback plan

## Redlines

- No strategy for race/lifetime risk in threaded code

## Scorecard

| Dimension | Score (1-5) | Evidence |
|-----------|-------------|----------|
| Qt fundamentals | | |
| Qt practical execution | | |
| System/risk judgment | | |
| Communication clarity | | |

## Decision Rule

- Recommended threshold (Mid): Avg >= 3.6 and no core domain < 3
- Decision: Hire / Hold / No-hire
- Notes: include 2-3 strongest evidence points
