---
name: ai-work-os
description: Initialize and operate Business or Light software projects using the portable AI Work OS workflow, agents, trackers, routing contracts, gates and budgets.
---

# AI Work OS

The canonical system is installed at `{{AI_WORK_OS_HOME}}`. Treat that directory as read-only during project work.

## Activation

Use this skill when the user asks to start, plan, implement, review or resume a project under AI Work OS.

1. Work in the user's actual project directory, never in the AI Work OS distribution.
2. Read `{{AI_WORK_OS_HOME}}/core/WORKFLOW.md`, `TRACKERS.md`, `ROUTING.md`, `GATES.md` and `BUDGETS.md`.
3. Select the requested role contract under `{{AI_WORK_OS_HOME}}/core/agents/`.
4. If no profile is recorded, classify Business versus Light; default to Business when sensitivity is uncertain.
5. Persist state and handoffs in the project so another client or session can resume them.

## Primary entry points

- New or unclear Business project: `business-wayfinder`.
- Mature Business implementation: `business-engineer`.
- New or unclear Light project: `light-planner`.
- Mature Light implementation: `light-builder`.

Architect and reviewers are isolated advisory roles. Reviewer receives only a focused evidence package and no tools.

Never send secrets or real sensitive data to models. Business routes must not contain free endpoints. MCP, GitHub and OmniRoute are optional adapters, not requirements.
