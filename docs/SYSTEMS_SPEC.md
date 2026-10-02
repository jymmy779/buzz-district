# Buzz District — Systems Specification

This document describes intended system behavior. It is not tied to one exact implementation.

## 1. Plot lifecycle

A plot contains zero or one building.

Current states:

- `empty`
- `active`
- `upgrading`

Possible future states:

- `constructing`
- `closed`
- `broken`
- `demolishing`
- `out_of_stock`

Customer systems must only target a building that is operational.

## 2. Building data

A business is identified by `building_type`.

A building has:

- type;
- level;
- lifecycle state;
- service capacity;
- queue capacity;
- service time;
- income;
- upgrade configuration;
- current service customers;
- current waiting customers.

Generic systems should resolve values from building data instead of checking one hard-coded business type.

## 3. Customer lifecycle

Conceptual lifecycle:

`spawned`
→ `choosing`
→ `going_to_service` or `going_to_queue`
→ `waiting`
→ `moving_from_queue_to_service`
→ `serving`
→ `leaving`

Additional transient state:

- `rerouting`

Implementation may use simpler strings/metadata while the prototype remains small.

## 4. Customer assignment

A customer must have one current assignment.

Important invariants:

- one customer cannot belong to two businesses at once;
- one customer cannot be in both `customers` and `waiting_customers`;
- two customers cannot reserve the same service slot;
- queue ordering must remain consistent;
- stale asynchronous flows must stop after assignment changes.

An assignment/version/token guard may be used to invalidate stale coroutines.

## 5. Service slots

`capacity` represents the number of customers that can be actively handled at the same time.

A customer reserves a service slot before traveling to it.

Prototype service positions may be offsets around the plot center.

Future building scenes should expose explicit service markers.

## 6. Queue

If all service slots are occupied:

- the customer may join the waiting queue if capacity remains;
- otherwise the customer should choose another valid destination or leave.

Queue uses FIFO.

When the first waiting customer is promoted:

1. remove from waiting collection;
2. reserve the free service slot;
3. add to service collection;
4. move to the service position;
5. shift remaining queue members forward.

## 7. Queue capacity

Current queue capacity is data-driven per building/level.

Long-term queue capacity should also consider physical map space.

A small storefront should not support an infinite abstract queue.

## 8. Patience

Each NPC has:

- `patience_max`
- `patience_remaining`

Patience decreases only while truly waiting.

Patience does not decrease while:

- actively walking to service;
- being served;
- leaving;
- rerouting;
- moving from queue into a reserved service slot.

If patience reaches zero:

- remove customer from queue;
- release queue position;
- shift queue;
- customer leaves;
- no payment occurs.

If rerouted into another queue, remaining patience is preserved.

## 9. Patience presentation

Waiting customers display a progress bar above the NPC.

The bar:

- is hidden outside waiting state;
- represents `remaining / max`;
- follows the NPC;
- reaches zero when the customer gives up.

Future polish can add emotion or color states.

## 10. Service

Current prototype service flow:

1. reserve service slot;
2. travel to slot;
3. enter serving state;
4. wait for building service duration;
5. verify assignment/building still valid;
6. pay exactly once;
7. show income feedback;
8. release slot;
9. begin leaving;
10. promote queue immediately.

A customer leaving the service slot does not need to fully exit the map before that slot can be reused.

## 11. Payment

Payment occurs only if:

- service completes;
- the building remains valid/active;
- the customer still belongs to the same assignment;
- the customer is not leaving;
- payment has not already occurred.

Duplicate payment is always a bug.

## 12. Upgrade

Upgrade flow:

1. validate building and cost;
2. deduct money;
3. set building to `upgrading`;
4. detach active/waiting customers;
5. attempt rerouting;
6. start countdown;
7. reject new customers while unavailable;
8. complete level change;
9. return to `active`.

## 13. Rerouting

When a customer's destination becomes unavailable:

1. invalidate old assignment;
2. remove from old collections;
3. clear old service/queue slot;
4. cancel old movement;
5. find another active business;
6. prefer immediate service capacity;
7. otherwise use queue capacity;
8. if none accept the customer, leave the district.

Current generic prototype allows rerouting across business types.

Future customer preferences may restrict valid alternatives.

## 14. Demand

Demand controls how often potential customers appear.

Current conceptual states:

- LOW
- NORMAL
- HIGH

Demand should not directly change customers already in the simulation.

Future systems that can modify demand:

- time of day;
- trends;
- events;
- district popularity;
- weather;
- creator activity;
- local drama.

## 15. Business selection

Current prototype can use random selection among valid businesses.

Future selection can score candidates using:

- customer need;
- product preference;
- travel distance;
- price;
- queue length;
- reputation;
- trend sensitivity.

## 16. Product/service architecture — planned

Long-term service time and price should not belong entirely to the NPC.

Preferred model:

### NPC

Determines:

- need;
- preferences;
- spending power;
- patience.

### Product / Service

Determines:

- base price;
- base processing time.

### Building

Determines:

- capacity;
- speed multiplier;
- equipment;
- level.

Example:

`actual_time = product.base_time / building.speed_multiplier`

This system is planned, not required for the current prototype.

## 17. Future seating distinction

For businesses such as cafes, later distinguish:

- processing/service capacity;
- seating/stay capacity.

Payment may happen after preparation, while the NPC remains seated afterward.

Do not implement until the game actually needs it.
