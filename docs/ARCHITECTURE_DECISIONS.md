# Buzz District — Architecture Decisions

This file records decisions that should not be repeatedly reopened without a concrete reason.

## ADR-001 — Godot 4 + GDScript

**Decision:** Use Godot 4.x and GDScript.

**Reason:** The game is a mobile 2D simulation and does not currently require the overhead of another engine.

**Status:** DECIDED.

---

## ADR-002 — Android first

**Decision:** Android is the initial platform.

iOS can be added later.

**Status:** DECIDED.

---

## ADR-003 — Simulation before final art

**Decision:** Prove business/customer simulation with placeholders before producing final building/NPC art.

**Status:** DECIDED.

---

## ADR-004 — Generic business systems

**Decision:** Queue, patience, service, payment, rerouting, and upgrade/customer handling should be generic.

Business-specific logic should only exist when the business truly behaves differently.

**Status:** CURRENT.

---

## ADR-005 — Offerings own base service values

**Decision:** Minimal generic offerings now own base_service_time, base_price and
selection weight. Building levels own service_speed_multiplier, income_bonus and
capacities. NPCs store a transient offering_id.

**Reason:** Cafe products and generic services share one service/payment pipeline.
The previous building-level fixed service_time/income abstraction is replaced.
No full menu, inventory or preference system is included. Minimal trend selection modifiers are described in ADR-015.

**Status:** CURRENT.

---

## ADR-006 — NPC does not decide service processing time

**Decision:** NPC traits can affect patience, preferences, movement, and spending behavior.

NPC should not arbitrarily decide how long a business takes to prepare a product/service.

**Status:** DECIDED.

---

## ADR-007 — Demand and capacity are separate

**Decision:** Customer demand exists independently of business capacity.

A full building does not stop demand from existing; overflow creates queue/rerouting/lost customers.

**Status:** CURRENT.

---

## ADR-008 — Queue capacity is abstract for now

**Decision:** Prototype queue uses numeric capacity and offset positions.

Future map/sidewalk geometry will constrain physical queue positions.

**Status:** DECIDED.

---

## ADR-009 — Upgrade causes operational downtime

**Decision:** An upgrading business cannot serve customers.

Customers must reroute or leave.

**Reason:** Upgrade timing should create gameplay trade-offs.

**Status:** CURRENT.

---

## ADR-010 — Rerouting before leaving

**Decision:** When a destination becomes unavailable, a customer tries another
valid active business for its current trip need before leaving the map.

Rerouting is same-business-type only. It does not advance the trip, reset patience,
or replace a compatible offering. Service restarts and remaining patience is
retained. Cross-business-type movement happens only after a successful purchase
advances the trip plan.

Future preferences can make alternatives more realistic.

**Status:** CURRENT.

---

## ADR-011 — Patience belongs to NPC

**Decision:** Patience varies by customer and only decreases while waiting.

Remaining patience persists across rerouting.

**Status:** CURRENT.

---

## ADR-012 — Local save before backend

**Decision:** Initial progression uses local persistence: versioned user://save.json. Save logical district state only; clear transient NPCs on load and resume upgrades from saved seconds without offline progression.

Do not introduce an online database until an online product requirement exists.

**Status:** CURRENT.

---

## ADR-013 — Fictionalize real-world satire

**Decision:** Real internet culture can inspire content, but recurring characters, brands, scandals, and incidents should normally be fictionalized.

**Status:** DECIDED.

---

## ADR-014 — Region packs instead of literal meme translation

**Decision:** Long-term localization can swap culturally specific trend/event content rather than translating every joke literally.

**Status:** DECIDED.


---

## ADR-015 — Small data-driven transient trend framework

**Decision:** Keep exactly one active trend in the district controller. Trend data
defines duration, offering-weight modifiers, customer-profile spawn modifiers, and
ThreadZ start/end copy. Gameplay systems query modifier sections through a generic
helper and do not identify Matcha Wave or Lunch Rush directly.

Starting the same trend is ignored. Starting another trend ends the current record
and begins the replacement at its full duration. The existing process loop owns the
only countdown, avoiding duplicate timers and stale callbacks.

**Reason:** Matcha Wave proves offering-mix pressure while Lunch Rush proves that a
profile-spawn modifier can indirectly change district behavior through existing
archetype preferences. This remains smaller than a scheduled event framework.

**Persistence:** Active trend state is intentionally not saved. Loading ends the
trend and restores normal selection weights; save version remains 1.

**Status:** CURRENT.

---

## ADR-016 — Minimal transient customer trips

**Decision:** Customers receive a one- or two-stop plan of business-type IDs at
spawn. With multiple supported types, the selected customer profile supplies the
one-stop/two-stop probabilities and first-business weights; a two-stop plan cannot
repeat a type.

Successful payment advances the plan. A new stop clears the previous offering and
assignment, resets remaining patience to the existing maximum, and reuses generic
service/queue assignment. If no valid destination can accept the next need, the
customer leaves without rewriting the plan.

**Persistence:** Trip plan, index, visited businesses, offering, assignment, and
patience are transient and remain outside save version 1.

**Status:** CURRENT.

---

## ADR-017 — Data-driven customer archetypes

**Decision:** Office Worker, Student, and Shipper share the same NPC scene and
generic service flow. A centralized profile record owns spawn weight, patience
range, business preference weights, trip-length probabilities, and optional
offering preferences.

Offering selection combines base offering weight, a profile modifier, and the
active trend modifier in one helper. Business preferences generate trips but never
change an unresolved need during rerouting.

**Persistence:** `customer_profile_id` and all NPC runtime state remain transient;
save version 1 is unchanged.

**Status:** CURRENT.
