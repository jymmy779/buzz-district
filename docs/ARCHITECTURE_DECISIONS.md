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

## ADR-005 — Building-level service values are temporary

**Decision:** Current prototype may store `service_time` and `income` per building level.

Long-term, products/services should define base time and price while the building defines processing speed/capacity.

**Reason:** Avoid building a product system before the core management loop is validated.

**Status:** DECIDED.

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

**Decision:** When a destination becomes unavailable, a customer tries another valid active business before leaving the map.

Current prototype may allow cross-business-type rerouting.

Future preferences can make alternatives more realistic.

**Status:** CURRENT.

---

## ADR-011 — Patience belongs to NPC

**Decision:** Patience varies by customer and only decreases while waiting.

Remaining patience persists across rerouting.

**Status:** CURRENT.

---

## ADR-012 — Local save before backend

**Decision:** Initial progression uses local persistence.

Do not introduce an online database until an online product requirement exists.

**Status:** DECIDED.

---

## ADR-013 — Fictionalize real-world satire

**Decision:** Real internet culture can inspire content, but recurring characters, brands, scandals, and incidents should normally be fictionalized.

**Status:** DECIDED.

---

## ADR-014 — Region packs instead of literal meme translation

**Decision:** Long-term localization can swap culturally specific trend/event content rather than translating every joke literally.

**Status:** DECIDED.
