# Qt / C++ / Robotics Question Bank by Level

Last updated: 2026-03-06

## 1. How To Use

1. Pick one target level: `Junior` / `Mid` / `Senior`.
2. Use same question set for all candidates at that level.
3. Score with fixed anchors first, then add interviewer notes.

## 2. Level Definition

| Level | Signal |
|-------|--------|
| Junior | Understands fundamentals, can deliver guided tasks |
| Mid | Can solve module-level problems independently |
| Senior | Can lead architecture decisions and risk tradeoffs |

## 3. Qt Question Templates

## 3.1 Junior (Qt)
- Q1: Explain Qt event loop and why UI can freeze.
- Q2: Difference between direct and queued signal-slot connection.
- Q3: Given a simple UI lag issue, describe your debugging steps.

Follow-up:
- Which metrics would you log first?
- How do you verify your fix did not break behavior?

Scoring anchors:
- `1`: cannot explain event loop basics
- `3`: gives correct model and basic debugging steps
- `5`: can reason thread-affinity and measurable validation plan

Redline:
- Recommends blocking long task on UI thread without mitigation

## 3.2 Mid (Qt)
- Q1: Design a medium Qt app module split (UI/service/data).
- Q2: Compare `QThread`, worker-object pattern, and task-based model.
- Q3: How to optimize high-frequency UI updates (charts/telemetry)?

Follow-up:
- Where will lifetime bugs likely happen?
- What tests catch regressions earliest?

Scoring anchors:
- `1`: architecture is vague, no ownership model
- `3`: clear module boundaries and workable threading plan
- `5`: gives explicit ownership, performance budget, and rollback plan

Redline:
- No strategy for race/lifetime risk in threaded code

## 3.3 Senior (Qt)
- Q1: Lead migration from legacy Widgets to mixed Widgets+QML.
- Q2: Define production observability for Qt client performance.
- Q3: Design plugin extension mechanism with stable interfaces.

Follow-up:
- What tradeoff did you choose and why?
- What is your de-risk plan for the first release?

Scoring anchors:
- `1`: strategy lacks phased rollout and risk control
- `3`: can define migration phases and risk areas
- `5`: robust strategy with compatibility, telemetry, and fallback

Redline:
- No rollback/safe-release strategy for major UI/runtime migration

## 4. C++ Question Templates

## 4.1 Junior (C++)
- Q1: Explain RAII and why it prevents leaks.
- Q2: Explain copy vs move semantics with examples.
- Q3: Find likely bug in iterator invalidation scenario.

Follow-up:
- Which STL container behavior caused this issue?
- What test case reproduces the bug?

Scoring anchors:
- `1`: ownership model unclear
- `3`: correct baseline and valid bug-fix direction
- `5`: precise boundary handling and test-driven validation

Redline:
- Suggests unmanaged raw-pointer ownership as default approach

## 4.2 Mid (C++)
- Q1: Refactor pointer-heavy legacy code to modern C++ style.
- Q2: Diagnose data race in multithreaded producer-consumer code.
- Q3: Choose between lock-based and lock-free approach for module X.

Follow-up:
- Which memory ordering assumptions are required?
- How do you prove correctness under load?

Scoring anchors:
- `1`: unsafe concurrency reasoning
- `3`: workable refactor + race mitigation plan
- `5`: explicit tradeoffs on correctness/perf/complexity with tests

Redline:
- Cannot identify race condition impact on correctness

## 4.3 Senior (C++)
- Q1: Design ABI-stable plugin interface for long-lived product.
- Q2: Build performance strategy for low-latency hot path.
- Q3: Decide migration path from old standard/toolchain to new one.

Follow-up:
- What breaks first in production?
- What constraints drive your architecture tradeoff?

Scoring anchors:
- `1`: no ABI/risk awareness
- `3`: solid design with compatibility concerns
- `5`: full lifecycle strategy (ABI, observability, upgrade safety)

Redline:
- Ignores compatibility/upgrade risks in core interface design

## 5. Robotics Software Question Templates

## 5.1 Junior (Robotics)
- Q1: Explain ROS2 topic/service/action usage boundaries.
- Q2: Describe localization-planning-control pipeline at high level.
- Q3: Why can robot behavior differ between sim and real world?

Follow-up:
- Which logs would you inspect first?
- How do you reproduce issue deterministically?

Scoring anchors:
- `1`: core ROS2 communication model unclear
- `3`: can explain pipeline and basic debugging flow
- `5`: can connect pipeline errors to practical verification steps

Redline:
- Cannot describe safe stop/fallback behavior when control fails

## 5.2 Mid (Robotics)
- Q1: Diagnose navigation oscillation in narrow corridor.
- Q2: Build regression tests from perception to control loop.
- Q3: Propose ROS2 package architecture for maintainability.

Follow-up:
- Which parameter tuning has highest leverage?
- How will you separate algorithm bug vs integration bug?

Scoring anchors:
- `1`: no systematic debug strategy
- `3`: practical root-cause workflow and test plan
- `5`: strong integration thinking with measurable acceptance criteria

Redline:
- No test/validation plan before deployment

## 5.3 Senior (Robotics)
- Q1: Design OTA upgrade with safe rollback for robot fleet.
- Q2: Define safety evidence for production release gate.
- Q3: Build multi-team delivery model for algorithm + platform + ops.

Follow-up:
- What is your incident response model?
- How do you constrain blast radius in rollout?

Scoring anchors:
- `1`: no production-risk control
- `3`: can define release gates and rollback
- `5`: full production-grade strategy (safety, observability, ops)

Redline:
- No containment strategy for bad release in live fleet

## 6. Decision Thresholds by Level

| Level | Recommended hire threshold |
|-------|----------------------------|
| Junior | Avg >= 3.2 and no core domain < 2 |
| Mid | Avg >= 3.6 and no core domain < 3 |
| Senior | Avg >= 4.0 and system/risk dimension >= 4 |

## 7. Interview Note Card (Reusable)

```markdown
# Candidate: [Name]
# Target Level: Junior / Mid / Senior
# Domain Focus: Qt / C++ / Robotics

## Evidence Highlights
- Strengths:
- Gaps:
- Risks:

## Score
| Domain | Score | Evidence |
|--------|-------|----------|
| Qt | | |
| C++ | | |
| Robotics | | |
| System/Risk Judgment | | |

## Decision
- Hire / Hold / No-hire
- Why:
- Follow-up:
```
