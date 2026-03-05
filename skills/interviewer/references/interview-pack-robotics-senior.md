# 60-Minute Interview Pack (Robotics / Senior)

Generated at (UTC): 2026-03-05T22:16:33+00:00
Duration: 60 minutes

## Interview Agenda

- 0-5 min: warm-up and context alignment
- 5-35 min: core technical questions (Senior level)
- 35-45 min: latest-topic deep dive
- 45-55 min: scenario tradeoff and risk discussion
- 55-60 min: candidate questions and wrap-up

## Core Questions

1. Design OTA upgrade with safe rollback for robot fleet.
2. Define safety evidence for production release gate.
3. Build multi-team delivery model for algorithm + platform + ops.

## Follow-up Script

- What is your incident response model?
- How do you constrain blast radius in rollout?

## Latest-Topic Deep Dive

1. ROS PMC Minutes for March 3, 2026
   - Source: https://discourse.openrobotics.org/t/ros-pmc-minutes-for-march-3-2026/52968
   - Ask: Based on this topic, explain engineering impact and rollout/testing plan.
2. Part 2: Canonical Observability Stack Tryout | Cloud Robotics WG Meeting 2026-03-09
   - Source: https://discourse.openrobotics.org/t/part-2-canonical-observability-stack-tryout-cloud-robotics-wg-meeting-2026-03-09/52967
   - Ask: Based on this topic, explain engineering impact and rollout/testing plan.

## Scoring Anchors (1-5)

- `1`: no production-risk control
- `3`: can define release gates and rollback
- `5`: full production-grade strategy (safety, observability, ops)

## Redlines

- No containment strategy for bad release in live fleet

## Scorecard

| Dimension | Score (1-5) | Evidence |
|-----------|-------------|----------|
| Robotics fundamentals | | |
| Robotics practical execution | | |
| System/risk judgment | | |
| Communication clarity | | |

## Decision Rule

- Recommended threshold (Senior): Avg >= 4.0 and system/risk dimension >= 4
- Decision: Hire / Hold / No-hire
- Notes: include 2-3 strongest evidence points
