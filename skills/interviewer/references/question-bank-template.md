# Qt / C++ / Robotics Interview Question Bank Template

Last updated: manual baseline template

## 1. Usage

- This template defines a stable structure.
- Use `scripts/update_question_bank.py` to generate latest-topic questions.
- Keep scoring anchors fixed to preserve cross-candidate comparability.

## 2. Competency Matrix

| Domain | Core competency | Evidence signal |
|--------|------------------|-----------------|
| Qt | UI architecture, signal-slot, threading, performance | Can reason on event loop and real bug tradeoffs |
| C++ | Modern C++, memory model, concurrency, STL, tooling | Can write safe/efficient code and explain tradeoffs |
| Robotics | ROS2, perception/planning/control integration, reliability | Can connect algorithm to deployment constraints |

## 3. Question Blocks

## 3.1 Qt

### Fundamental
- Explain Qt event loop and how it affects UI responsiveness.
- Compare direct vs queued signal-slot connection and usage boundaries.

### Practical
- Given a freezing UI issue, propose a debugging path and fix options.
- Design a module split for a medium Qt app (UI, service, data).

### Advanced
- Discuss thread affinity, QObject lifetime, and race-risk mitigation.
- Design a high-frequency data update UI with stable FPS and low latency.

## 3.2 C++

### Fundamental
- Compare stack/heap/object lifetime and common ownership models.
- Explain move semantics and where misuse can hurt performance/correctness.

### Practical
- Refactor a legacy pointer-heavy class to modern RAII style.
- Diagnose a sporadic crash from iterator invalidation.

### Advanced
- Explain memory ordering choices in a lock-free/low-lock scenario.
- Design a plugin interface balancing ABI stability and extensibility.

## 3.3 Robotics Software Development

### Fundamental
- Explain ROS2 node, topic, service, action and when each fits best.
- Describe localization/planning/control boundaries in a mobile robot stack.

### Practical
- Investigate why robot navigation oscillates in a cluttered corridor.
- Propose test strategy for perception-to-control integration regressions.

### Advanced
- Design rollout strategy for over-the-air update with rollback safety.
- Discuss safety case evidence for production robot software releases.

## 4. Follow-up Script Template

For each main question, ask:

1. "What assumptions are you making?"
2. "What would fail first in production?"
3. "How would you validate your solution in one day?"

## 5. Scoring Rubric (1-5)

| Score | Signal |
|-------|--------|
| 1 | Concept confusion, cannot form runnable approach |
| 2 | Partial knowledge, weak tradeoff reasoning |
| 3 | Solid baseline, can solve common cases |
| 4 | Strong engineering judgment, reliable under constraints |
| 5 | System-level depth, anticipates risks and mitigation clearly |

## 6. Decision Rule

- No-hire if any hard-redline competency is below 2.
- Hire-ready baseline: average >= 3.5 and no core domain below 3.
- Strong hire: average >= 4.2 with at least one domain at 5.
