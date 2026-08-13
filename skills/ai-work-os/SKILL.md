---
name: ai-work-os
description: Initialize, resume and operate Business or Light software projects using the portable AI Work OS workflow. Always use when the user says riprendi, continua, resume, or asks to pick up prior AI Work OS work, even from a generic Code/Build agent; recover persisted project state and dispatch to the correct planning or engineering role.
---

# AI Work OS

The canonical system is installed at `{{AI_WORK_OS_HOME}}`. Treat that directory as read-only during project work.

## Activation

Use this skill when the user asks to start, plan, implement, review or resume a project under AI Work OS.

1. Work in the user's actual project directory, never in the AI Work OS distribution.
2. Read `{{AI_WORK_OS_HOME}}/core/DISPATCH.md`, `WORKFLOW.md`, `TRACKERS.md`, `ROUTING.md`, `GATES.md` and `BUDGETS.md`.
3. For resume requests, recover profile and state from `PROJECT.md`, the configured tracker and handoffs; follow `DISPATCH.md` instead of asking the user to remember the role. Do this even when the currently selected primary agent is a generic built-in such as Code or Build.
4. Select or invoke the corresponding role contract under `{{AI_WORK_OS_HOME}}/core/agents/` using the client capabilities available. When task/subagent invocation exists, delegate to the specialized role rather than imitating it in parallel.
5. If no profile is recorded, classify Business versus Light; default to Business when sensitivity is uncertain.
6. Persist state and handoffs in the project so another client or session can resume them.

## Primary entry points

- New or unclear Business project: `business-wayfinder`.
- Mature Business implementation: `business-engineer`.
- New or unclear Light project: `light-planner`.
- Mature Light implementation: `light-builder`.

Architect and reviewers are isolated advisory roles. Reviewer receives only a focused evidence package and no tools.

On clients with subagents, the dedicated `ai-work-os` primary agent performs
this dispatch directly. If this skill was activated from a generic primary
agent, apply the same dispatch table and invoke the selected specialized role.
On skill-only clients, adopt the selected role contract directly for the
current turn and re-evaluate state on the next resume request. Never claim that
the client UI changed agents when it did not: delegation changes the executing
role, not the label shown in the selector.

Never send secrets or real sensitive data to models. Business routes must not contain free endpoints. MCP, GitHub and OmniRoute are optional adapters, not requirements.
