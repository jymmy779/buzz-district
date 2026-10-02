# Buzz District — Instructions for AI Coding Agents

This file is the default project context for Codex/AI coding agents.

## Read first

Before changing code, read:

1. `docs/INDEX.md`
2. `docs/GAME_OVERVIEW.md`
3. `docs/SYSTEMS_SPEC.md`
4. `docs/TECHNICAL_ARCHITECTURE.md`
5. `docs/ARCHITECTURE_DECISIONS.md`
6. `docs/DEVELOPMENT_WORKFLOW.md`

For content, trends, events, humor, or worldbuilding work, also read:

- `docs/CONTENT_BIBLE.md`
- `docs/LOCALIZATION_AND_REGION_PACKS.md`

For visuals/UI work, also read:

- `docs/ART_AND_UX_DIRECTION.md`

For current prototype numbers, read:

- `docs/BALANCE_REFERENCE.md`

## Project identity

**Buzz District** is a mobile-first 2D isometric urban management / simulation / tycoon game built with **Godot 4.x + GDScript**.

The core identity is:

> Build businesses, manage crowds, and react to the trends, memes, drama, and urban events that reshape demand across the district.

This is not a pure restaurant game, not a pure idle clicker, and not a meme compilation.

## Current implementation direction

The current prototype already includes or is expected to preserve:

- generic plot/building lifecycle
- generic business data
- Cafe
- Minimart
- service slots
- queue FIFO
- patience
- patience bar
- customer rerouting when a business becomes unavailable
- demand states
- build / upgrade / payment / income popup
- placeholder NPC movement

Do not replace working generic systems with business-specific duplicated logic.

## Rules for code changes

- Read the existing implementation before editing.
- Do not rewrite the project from scratch.
- Do not perform large refactors unless the task explicitly requires them.
- Preserve all currently working features unless the task explicitly changes behavior.
- Prefer data-driven business/content definitions.
- Avoid hard-coding `"cafe"` in customer, queue, patience, payment, rerouting, or generic service logic.
- Keep UI node renames and scene-tree changes minimal unless needed.
- Do not add unrelated features.
- Keep prototype code understandable; avoid premature frameworks.
- When a task affects asynchronous customer flows, guard against stale coroutines, duplicate payments, duplicate assignments, and freed-instance references.
- Validate Godot scripts/scenes when possible.
- Never claim runtime testing was completed if Godot could not actually be run.

## Product/service architecture rule

Long-term:

- NPC decides what it wants.
- Product/service defines base price and base processing time.
- Building defines capacity, speed, level, equipment, and operational state.

The current prototype may keep `service_time` and `income` at building-level as a temporary abstraction. Do not build a full product/menu system unless the task explicitly asks for it.

## Visual rule

Placeholder visuals are acceptable while the simulation is being proven.

Do not spend engineering effort on final art, pathfinding, advanced animation, or polish unless the task is specifically about those systems.

## Content rule

Real-world trends may inspire fictionalized content, but do not directly encode unverified accusations against real people or companies. Prefer archetypes, fictional brands, fictional creators, and fictional social posts.

## Workflow

Work one scoped task at a time.

After each task:

1. summarize changed files;
2. describe behavior changes;
3. run available validation/tests;
4. state what was not tested;
5. stop instead of silently adding the next feature.
