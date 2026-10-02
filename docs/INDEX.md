# Buzz District Documentation Index

This folder is the source of truth for what Buzz District is, how its systems are intended to work, and how the project should evolve.

## Core documents

### `GAME_OVERVIEW.md`

Read this first if you need to understand the game itself.

Contains:

- game identity
- player fantasy
- setting
- core loop
- long-term vision
- what makes Buzz District different

### `GAME_DESIGN.md`

Higher-level design of the playable experience.

Contains:

- player decisions
- progression
- business management
- simulation layers
- session structure
- design pillars

### `SYSTEMS_SPEC.md`

Behavioral specification of the simulation systems.

Contains:

- building lifecycle
- customer lifecycle
- service slots
- queue
- patience
- rerouting
- demand
- upgrade behavior
- future product/service architecture

### `CONTENT_BIBLE.md`

Creative content bank.

Contains:

- trend ideas
- drama/event ideas
- fictional archetypes
- social-media ideas
- satire boundaries
- reusable content patterns

### `TECHNICAL_ARCHITECTURE.md`

Engineering direction.

Contains:

- Godot architecture
- data-driven business definitions
- NPC state
- scene responsibilities
- save/load direction
- performance direction

### `ARCHITECTURE_DECISIONS.md`

Important decisions already made so the project does not repeatedly revisit the same questions.

### `BALANCE_REFERENCE.md`

Current prototype numbers such as service capacity, queue capacity, service time, income, upgrade values, and demand spawn ranges.

All values here are provisional until balancing begins.

### `ART_AND_UX_DIRECTION.md`

Visual identity, information hierarchy, UI principles, and future isometric presentation.

### `LOCALIZATION_AND_REGION_PACKS.md`

Localization strategy and long-term culture-pack design.

### `ROADMAP.md`

Current project state and major future phases.

This is not a rigid deadline schedule.

### `DEVELOPMENT_WORKFLOW.md`

How ChatGPT, Codex, Godot, Git, testing, and documentation should be used during development.

## Status vocabulary

Documents distinguish between:

- **CURRENT** — already implemented or actively used in the prototype.
- **DECIDED** — design direction chosen but not necessarily implemented.
- **PLANNED** — intended future work.
- **IDEA** — content/design possibility, not a commitment.

When code and documentation disagree, inspect the current implementation before changing behavior, then update the relevant document after the intended behavior is confirmed.
