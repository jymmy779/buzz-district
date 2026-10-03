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

Profile and trip state are transient NPC metadata. `customer_profile_id` identifies
the selected data record, `trip_plan` contains business-type IDs, `trip_index`
identifies the current need, and `visited_businesses` records completed plot names
for runtime/debug use. Offering, assignment, and patience metadata remain
per-customer runtime state. Save version 1 serializes none of these values.

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
                "service_speed_multiplier": 1.0,
                "income_bonus": 0,
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

Photobooth validates this direction. Its levels, costs, optional queue reaction,
offerings, and profile preferences are data additions. The only scene/controller
wiring added is one prototype build button. No Photobooth-specific service, queue,
patience, reroute, payment, upgrade, trip, or persistence code exists.

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

Successful payment calls one trip-transition path. It invalidates the completed
assignment, releases its service slot, promotes the old queue, clears the offering,
advances `trip_index`, resets remaining patience, and reuses the generic assignment
pipeline for the next required business type. The assignment ID invalidates the
old service coroutine before the new stop begins.

Upgrade rerouting uses the same destination selector but does not advance the trip,
clear a compatible offering, or reset patience. Candidate plots must match the
current trip business type. Both flows prefer an immediate slot before queue space.

CUSTOMER_PROFILE_DATA in the district controller owns profile spawn weight,
patience range, business preference weights, one/two-stop probabilities, and
offering preference weights. Spawn selects a profile first, then generates a trip
only from currently supported active business types. The first stop is weighted by
the selected profile; a second stop is selected from remaining types, so duplicate
business types are impossible in the current two-stop limit.

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

## Offering architecture — CURRENT

OFFERING_DATA in main.gd is keyed by stable IDs: coffee, matcha_latte and
quick_purchase. Each record defines display_name, building_type,
base_service_time, base_price and weight. BUILDING_DATA levels define
service_speed_multiplier and income_bonus instead of fixed service time/income.

Shared helpers:

- get_available_offering_ids filters by destination building type and positive weight.
- get_offering_selection_weight combines base, profile, and trend modifiers.
- choose_offering draws a random value across cumulative weights.
- assign_customer_offering keeps a supported existing ID or selects a replacement.
- get_offering_service_time divides offering base time by building speed.
- get_offering_income adds building income bonus to offering base price.

NPC metadata stores offering_id and customer_profile_id. Spawn chooses once per
stop; FIFO promotion and same-need rerouting preserve it. Trip advancement clears
it so the next business selects a valid offering using the same profile and current
trend. Service captures the offering when serving begins, logs its computed
time/price once, and uses assignment guards so interrupted service cannot pay.

Queue, patience and movement remain generic. No preferences, inventory, menu UI,
or new business-specific customer classes are introduced.
Trend modifiers use the centralized weight helper without rewriting
service/payment flow.

Offering regression: godot --headless --path . --script tests/offerings_test.gd.
This uses a dedicated test save, not the player's save.

## Save/load — CURRENT

The district controller implements local persistence at user://save.json.
save_game(), load_game() and has_save_game() operate on a versioned JSON snapshot:

- version: currently 1; unsupported/missing versions are rejected (no migration).
- money: nonnegative integer.
- demand_state: enum integer (0 LOW, 1 NORMAL, 2 HIGH).
- plots: records keyed by the direct plot name, containing building_type,
  level, state, upgrade_remaining and upgrade_target_level.

Only logical state is saved. NPCs, offering assignments, queues, patience, Tweens and
coroutines are never serialized. Missing optional fields receive defaults;
malformed known records reject the entire snapshot. Unknown plot names are ignored.
Invalid/unreadable files log a warning and start a fresh district.

Initialization connects plot signals, then load_game() first initializes default
metadata and clears transient state, validates/applies the snapshot, refreshes UI
and schedules spawning. Only after all plots are restored are upgrade timers resumed.

Upgrades continue from saved integer seconds, with no offline time or earnings.
A simulation generation invalidates pre-load timers, and a per-plot generation
guard prevents duplicate countdowns. Loading during a live session also cancels
movement and removes old NPCs/popups; asynchronous customer flows validate instances
and assignment ownership before continuing.

Save triggers: build, upgrade start/completion, demand changes, every 15 seconds,
and NOTIFICATION_WM_CLOSE_REQUEST. Writes use a sibling temporary file and replace
the save only after a successful write. There is no reset UI or cloud persistence.
Force-killing the process can lose changes since the last successful save.

Regression: godot --headless --path . --script tests/local_persistence_test.gd.
The test uses its own user://buzz_district_persistence_test.json, leaving the
player's save untouched.

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


## Data-driven trend state — CURRENT

TREND_DATA in main.gd is keyed by trend ID. Every record supplies id, display_name,
duration, offering_weight_modifiers, customer_profile_spawn_modifiers,
threadz_start_posts, and threadz_end_posts. Matcha Wave and Lunch Rush use the same
schema; adding a comparable trend normally requires data rather than customer-flow
branches.

The controller keeps one active_trend_id and trend_remaining. get_active_trend and
get_trend_modifier(section, target_id, default) are the generic read API. Offering
selection queries offering_weight_modifiers; weighted profile selection queries
customer_profile_spawn_modifiers. Base offering/profile data is never mutated.

start_trend validates the ID. A repeated same-ID start is ignored; a different ID
calls end_active_trend before installing the new record and full duration. The one
existing _process countdown calls update_trend, so no timer nodes, callbacks, or
coroutines can survive replacement and end a newer trend.

publish_trend_message handles both start/end arrays through the existing cosmetic
RNG and last-message exclusion. The shared UI/TrendLabel reflects the active data
record. Debug T starts Matcha Wave; debug Y starts Lunch Rush. Both are disabled in
release builds and reject key repeat.

reset_transient_and_district_state ends and clears any active trend. No trend fields
are serialized; save version 1 remains compatible.

Regression: godot --headless --path . --script tests/trends_test.gd and
tests/trend_framework_test.gd.

## ThreadZ feed — CURRENT

The existing controller exposes add_threadz_post(text, type = "system").
Posts are dictionaries containing text, type and a monotonically increasing order
index. Insert at the front, remove the oldest beyond five, and refresh the plain-text
RichTextLabel. Other simulation systems can call the same helper at discrete events.
No Node references or persisted history are stored in posts.

TREND_DATA supplies three threadz_start_posts for Matcha Wave. Successful start
uses a separate RandomNumberGenerator so cosmetic choices do not consume simulation
randomness. An active trend's existing duplicate-start guard also prevents duplicate
posts. No end-of-trend post is emitted.

BUILDING_DATA optionally defines queue_reaction {threshold, reset_below, text}.
Only Cafe configures it (3 / 2). check_queue_threadz_reaction observes queue mutations
and cleanup, not frames. Per-plot queue_threadz_posted is hysteresis-based: post once
at >=3, rearm at <=1 or when unavailable. The observer only updates presentation
state; it never changes assignment, queue ordering, service, payment or patience.

Main.tscn adds UI/ThreadZButton and UI/ThreadZPanel with a header, close button and
bounded scrolling text area. Reset/load clears history, order index, episode flags
and closes the panel. Save version remains 1.

Regression: godot --headless --path . --script tests/threadz_test.gd.

ThreadZ anti-spam state adds last_threadz_trend_text and
threadz_queue_cooldown_remaining. Trend selection filters out the remembered text
before using the cosmetic RNG; if no alternative exists, it skips that post.
The shared queue cooldown decrements in _process and resets to 30 seconds only
when a congestion post is published. A suppressed episode still sets the per-plot
guard, preventing a backlog when the cooldown ends. Load clears both fields.
No save-schema, UI, service or queue-assignment changes are required.
