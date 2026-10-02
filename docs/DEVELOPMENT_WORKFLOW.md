# Buzz District — Development Workflow

## Development style

Build incrementally.

Do not ask Codex to “finish the whole game.”

Each task should have:

- one clear goal;
- explicit non-goals;
- acceptance tests;
- preservation requirements.

## Roles

### ChatGPT

Useful for:

- system design;
- architecture review;
- task decomposition;
- Codex prompts;
- debugging reasoning;
- balancing discussion;
- documentation.

### Codex

Useful for:

- reading the actual repository;
- modifying project files;
- refactoring code in place;
- updating `.tscn` scenes;
- running available terminal validation/tests.

### User

Manual testing is still required for:

- visual positioning;
- UX feel;
- NPC movement appearance;
- queue readability;
- timing feel;
- touch/UI behavior.

## Before each Codex task

Prompt Codex to:

1. read current files first;
2. preserve working behavior;
3. stay inside task scope;
4. list changed files afterward;
5. validate if possible;
6. state clearly when runtime testing was unavailable.

## Documentation rule

For architecture-changing tasks, Codex should read:

- `AGENTS.md`
- `docs/TECHNICAL_ARCHITECTURE.md`
- `docs/ARCHITECTURE_DECISIONS.md`
- `docs/SYSTEMS_SPEC.md`

For creative content tasks:

- `docs/CONTENT_BIBLE.md`

## Testing rule

At the prototype stage:

### Automated / tool-assisted checks

Use when available for:

- GDScript syntax;
- scene loading;
- missing node paths;
- type errors;
- pure logic.

### Manual gameplay checks

Required for:

- NPC rerouting;
- queue movement;
- patience UI;
- service slots;
- upgrade interruption;
- visual overlap.

## Regression test habit

After a task touching customer logic, test at least:

- normal service;
- queue;
- patience expiry;
- upgrade with customers present;
- reroute;
- payment once;
- no invalid-instance errors.

After adding a business, test coexistence with existing businesses.

## Git workflow

Make a commit at a clean milestone.

Examples:

```bash
git add .
git commit -m "feat: thêm queue và patience cho khách"
git push
```

or:

```bash
git commit -m "feat: thêm hệ thống business tổng quát và Minimart"
```

Do not commit generated cache folders such as `.godot/`.

## Debug output

Temporary logs are fine during a task.

Remove or reduce noisy per-frame logs after the behavior is confirmed.

## Scope control

When a task uncovers a future feature, document it instead of implementing it immediately unless it blocks the current system.

Examples:

- queue should later follow sidewalks;
- cafe should later have products;
- customers should later have preferences.

Those are valid future requirements, but they should not automatically expand today's task.

## Definition of done

A task is done when:

- requested behavior works;
- previous core behavior still works;
- no known critical error remains;
- acceptance tests are checked;
- code changes are understandable;
- relevant docs are updated if the architecture changed.
