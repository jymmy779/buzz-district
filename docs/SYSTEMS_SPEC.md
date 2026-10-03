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
- service speed multiplier;
- income bonus;
- upgrade configuration;
- current service customers;
- current waiting customers.

Generic systems should resolve values from building data instead of checking one hard-coded business type.

Current implemented types are Cafe, Minimart, and Photobooth. Photobooth uses the
same lifecycle, capacity, queue, patience, upgrade interruption, rerouting, service,
payment, and persistence paths as the other businesses.

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

Each spawned customer also owns a small transient trip plan. With one supported
active business type the plan has one stop. With multiple supported active types,
the NPC's customer profile supplies its one-stop/two-stop probability and weighted
first-stop preference. Two-stop plans still contain different business types. The
NPC stores `customer_profile_id`, `trip_plan`, `trip_index`, and
`visited_businesses`; none are persisted.

Current profiles are Office Worker, Student, and Shipper. A weighted profile is
selected before trip generation. Profile data owns spawn weight, patience range,
business preference weights, trip-length probabilities, and optional offering
preferences. All three profiles use the same placeholder NPC scene.

After a successful payment, the current stop is completed and its assignment and
offering are cleared. If another stop remains, the customer selects a destination
and offering for that business type through the existing generic pipeline. The
customer leaves only after the plan is complete, or when the next stop has no
active business with service or queue capacity.

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

A successful purchase followed by a new trip stop is not a reroute. Starting that
new need resets `patience_remaining` to the existing `patience_max`; the maximum is
not randomized again. Rerouting the same unresolved need continues to preserve the
remaining value.

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
4. read the NPC offering_id and wait for offering.base_service_time / building.service_speed_multiplier;
5. verify assignment/building still valid;
6. pay offering.base_price + building.income_bonus exactly once;
7. show income feedback;
8. release slot;
9. release the slot and promote the queue immediately;
10. advance to the next planned stop, or begin leaving when the trip is complete.

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
5. find another active business of the current trip stop's required type;
6. prefer immediate service capacity;
7. otherwise use queue capacity;
8. if none accept the customer, leave the district.

Rerouting never advances the trip and never changes the current need to another
business type. A Cafe need may reroute from Cafe A to Cafe B, but not to a
Minimart. The existing offering remains valid because the destination type is the
same. Service restarts from the beginning, and remaining patience is preserved.

If no same-type active business with a valid offering has service or queue
capacity, the customer leaves.

For both rerouting and normal trip progression, destination choice prefers any
immediate service slot, then a queue with capacity. Distance, price, rating, and
preference scoring are not part of the prototype.

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

## 16. Offering layer — CURRENT

An offering represents a product or service without introducing inventory or menu UI.

- Cafe: Coffee (4.0s, $10, weight 70), Matcha Latte (5.5s, $14, weight 30).
- Minimart: Quick Purchase (3.0s, $8, weight 100).
- Photobooth: Quick Shot (4.5s, $12, weight 70), Premium Strip (7.0s,
  $20, weight 30).
- Each offering has a stable ID, display name, supported building type, base time,
  base price and default selection weight.
- A customer selects a weighted random valid offering when assigned to a business.
  The offering_id remains on that NPC through waiting/promotion.
- Queue and patience do not depend on the offering.
- Building levels own capacity, queue capacity, speed multiplier and income bonus.
- Actual service time = base_service_time / service_speed_multiplier.
- Payment = base_price + income_bonus.
- Offering assignments are transient and excluded from save version 1.

Effective offering weight is centralized as base offering weight × customer-profile
preference modifier × active trend modifier. Profile preference weights are
normalized against the base so their configured values remain the intended
baseline distribution. A profile without an offering override uses the base weight.
Spending power, inventory and menu UI are not implemented.

Customer profiles also define Photobooth preference weights. Office Workers use
Quick Shot / Premium Strip weights 75 / 25, Students 45 / 55, and Shippers 90 / 10.
These feed the same generic offering selector; there is no Photobooth service branch.

## 17. Future seating distinction

For businesses such as cafes, later distinguish:

- processing/service capacity;
- seating/stay capacity.

Payment may happen after preparation, while the NPC remains seated afterward.

Do not implement until the game actually needs it.


## 18. Data-driven trends — CURRENT

The prototype supports one active trend selected from centralized trend data. Each
record defines ID, display name, duration, offering-weight modifiers,
customer-profile spawn modifiers, and ThreadZ start/end message arrays. Empty
modifier sections have no effect, and missing target modifiers default to 1.0.

Matcha Wave runs for 30 seconds and changes new offering selection only: Coffee
weight x0.5 and Matcha Latte x3.5. Modifiers apply after customer-profile offering
preferences, so every profile shifts toward Matcha while retaining a distinct mix.

Lunch Rush runs for 30 seconds and changes profile spawn weights only: Office
Worker x2.0, Student x0.75, Shipper x1.0. Their patience, trips, business choices,
and offerings continue through normal profile data without trend-specific checks.

Only one trend may be active. Starting the same active trend is a no-op; starting a
different trend cleanly ends the old one before initializing the new duration and
modifiers. A single process-loop countdown prevents duplicate timers and stale
callbacks. Expiry removes every modifier and hides the shared trend indicator.

Load clears active trends; save schema remains version 1. Debug builds use T for
Matcha Wave and Y for Lunch Rush. There is no automatic scheduling or stacking.

## 19. ThreadZ prototype feed — CURRENT

ThreadZ is a text-only presentation panel opened/closed with the ThreadZ button
or its Close button. It starts empty, shows newest posts first, and retains at most
five posts. Bounded scrolling is only for those five posts, not an infinite history.

Each successful trend start adds one randomly chosen start post. A trend may also
define end posts; Lunch Rush publishes one on completion/replacement while Matcha
Wave currently has none. Repeated same-trend starts do not add posts, and posting
never occurs per frame.

Congestion reactions are optional BUILDING_DATA records and use one generic observer.
Cafe posts at three waiting customers; Photobooth posts at two. Falling below each
configured reset threshold rearms the episode. Inactive businesses and load reset
eligibility. Minimart has no queue reaction configured.

Feed history and episode flags are transient, never saved. Opening the feed does
not pause simulation. No social accounts, likes, comments, NPC posting or backend.

ThreadZ anti-repeat rules:
- Trend copy excludes the last published trend text, even if other posts intervene
  or that text has fallen out of the five-post history.
- Congestion posts share a 30-second simulation-time cooldown across all businesses.
  The per-business episode guard still applies. Episodes suppressed during cooldown
  are consumed, not queued for delayed posting; eligibility returns after queue <=1.
- Load clears these transient guards. Posts still do not expire with time.
