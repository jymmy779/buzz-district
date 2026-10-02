# Buzz District — Technical Architecture

## Stack

- Godot 4.x
- GDScript
- Git / GitHub
- Android first
- Local save first
- Backend only when an actual online feature requires it

## Architecture principle

Build shared simulation systems first.

Business-specific behavior should be data/config-driven wherever possible.

Avoid:

`CafeCustomerSystem`
`MinimartCustomerSystem`
`EVCustomerSystem`

Prefer:

`CustomerSystem`
+ generic building data
+ optional specialized behavior only when needed.

## Current core entities

### Main / District controller

Responsible for prototype orchestration such as:

- plot initialization;
- money;
- building construction;
- upgrade flow;
- customer spawning;
- demand;
- assignment;
- queue/service promotion.

As complexity grows, responsibilities should gradually move into dedicated managers/components.

Do not split everything prematurely.

### Plot / Building

Current prototype can store building information on plot metadata.

Long-term, each plot/building should have a clearer data model.

Fields include:

- building type;
- level;
- state;
- customers;
- waiting customers;
- upgrade state.

### NPC / OfficeWorker

Current NPC scene is a placeholder `Node2D`.

Responsibilities:

- visual representation;
- movement tween;
- cancel movement;
- patience bar presentation.

Simulation ownership should not move entirely into the visual node.

## Generic business data

Recommended conceptual structure:

```gdscript
const BUILDING_DATA := {
    "cafe": {
        "display_name": "Cafe",
        "build_cost": 300,
        "max_level": 3,
        "levels": {
            1: {
                "capacity": 1,
                "queue_capacity": 3,
                "service_time": 4.0,
                "income": 10,
                "upgrade_cost": 200,
                "upgrade_time": 10
            }
        }
    }
}
```

Exact shape may evolve.

The important rule is:

**customer logic asks the building system for data instead of hard-coding one business type.**

## Customer assignment

Asynchronous flows are a major risk.

A customer can be:

- walking toward an old building;
- rerouted while walking;
- promoted from queue;
- interrupted by upgrade;
- leaving.

Therefore every long-running customer flow should verify that it still owns the NPC.

Recommended options:

- `current_building`
- `customer_state`
- `assignment_id`
- incrementing assignment version/token

A stale coroutine must return without:

- moving the NPC;
- paying;
- freeing the NPC;
- changing collections.

## Collections

Per building:

- active/service customers
- waiting customers

Invariants:

- no duplicate references;
- invalid instances cleaned;
- one NPC in one logical collection;
- unique slot indices.

## Movement

Current movement can use Tween.

NPC should expose something equivalent to:

- `walk_to(...)`
- `cancel_movement()`

Future pathfinding can replace internal movement without changing high-level simulation APIs.

## Service markers

Prototype:

- calculated offsets around plot center.

Future:

Building scenes expose child markers, for example:

```text
Cafe
├── ServiceSlots
│   ├── Slot0
│   ├── Slot1
│   └── Slot2
├── QueueSlots
│   ├── Queue0
│   └── ...
└── Entrance
```

Simulation asks the building for marker positions.

## Demand

Demand should remain separate from capacity.

Demand determines how much potential traffic exists.

Capacity determines how much a building can handle.

This distinction is required for queues to have meaning.

## Product architecture — future

Do not hard-code every menu item into customer logic.

Recommended data:

```text
Product
- id
- business categories
- base price
- base processing time
- trend tags
```

Building:

```text
- processing speed
- capacity
- equipment
```

Customer:

```text
- preferences
- budget
- needs
```

## Save/load direction

Save/load is planned after generic business behavior is stable.

Persist logical state, not runtime Node references.

Save examples:

- money;
- plot building type;
- level;
- lifecycle state if appropriate;
- upgrade remaining time if offline continuation is desired;
- progression/unlocks;
- settings.

Do not serialize:

- Tween;
- Node references;
- temporary customer arrays;
- runtime coroutine state.

Initially, active transient customers can simply be reconstructed/cleared on load.

## Data storage

Early game:

- JSON or Godot `ConfigFile` / resource-based local persistence is sufficient.

Do not add PostgreSQL, Supabase, Firebase, or a custom server solely for local progression.

Online backend becomes justified only for features such as:

- cloud saves;
- accounts;
- social features;
- live events;
- remote config;
- cross-device progression.

## Performance

Mobile target.

Avoid scaling by spawning thousands of live NPC Nodes.

Long-term:

### Visible simulation

Use real NPC nodes near the player.

### Statistical simulation

Use aggregated calculations for distant/offscreen areas.

## Signals/events

As systems grow, prefer clear events/signals for major transitions:

- building built;
- upgrade started/completed;
- customer paid;
- customer abandoned queue;
- demand changed;
- trend started/ended.

Do not introduce a complex event bus until multiple systems actually need it.

## Recommended future folder direction

Adapt to the current repository instead of reorganizing everything immediately.

```text
res://
├── scenes/
│   ├── world/
│   ├── buildings/
│   ├── npc/
│   └── ui/
├── scripts/
│   ├── systems/
│   ├── buildings/
│   ├── npc/
│   └── data/
├── data/
│   ├── buildings/
│   ├── products/
│   ├── trends/
│   └── events/
└── localization/
```

Move toward this only when current files become difficult to manage.
