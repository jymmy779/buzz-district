# Buzz District — Game Design

## Design pillars

### 1. Readable simulation

The player should quickly understand:

- where customers are going;
- which business is full;
- who is waiting;
- who is losing patience;
- which business is upgrading;
- where demand is concentrating.

The player should not need a spreadsheet to understand the basic state of the district.

### 2. Systems interact

Important systems must affect each other.

Examples:

- high demand creates queues;
- queues consume patience;
- low patience loses customers;
- upgrades temporarily close businesses;
- closures reroute customers;
- reroutes overload nearby businesses;
- trends change demand;
- business mix changes how demand is absorbed.

### 3. Modern urban identity

The game should feel grounded in contemporary city life and online culture.

### 4. Humor through simulation

The funniest moments should emerge from systems.

Example:

A creator makes one cafe viral, its queue explodes, nearby customers reroute into a minimart, and the minimart also becomes overloaded.

That is stronger than simply showing a joke popup.

### 5. Expandable content

Adding a new business, trend, event, or region should not require rewriting the entire simulation.

## Main player decisions

The player repeatedly decides:

- what to build;
- where to build it;
- when to upgrade;
- whether current capacity can handle demand;
- whether to build another copy of a popular business;
- whether to diversify the district;
- whether a temporary trend is worth investing in;
- how to respond when one business closure overloads another.

## Customer trips

Customers can make a lightweight district trip instead of always leaving after one
purchase. Most prototype trips still contain one stop; some contain two different
business types when both Cafe and Minimart are active. Each stop independently
selects a valid offering, so a Cafe visit still participates in Matcha Wave before
the same customer moves to a Minimart purchase.

Trip progression and rerouting are intentionally different. A successful purchase
can advance to a different planned business type and restores the customer's full
patience for that new decision. An interrupted unresolved stop may reroute only to
another building of the same type and keeps the patience already spent. If the next
planned stop cannot accept the customer, the trip ends cleanly.

## Customer archetypes

The prototype has three data-driven customer archetypes sharing one placeholder
visual: Office Worker, Student, and Shipper. They differ only through authored
simulation weights: how often they spawn, patience, preferred first business, trip
length, and Cafe offering mix. Office Workers lean toward Cafe and Coffee, Students
lean toward Matcha and wait longer, and Shippers favor Minimart, shorter trips, and
lower patience.

Preferences influence selection; they do not override an explicit current need.
Trends multiply the profile's offering mix, so Matcha Wave shifts every archetype
toward Matcha while preserving differences between them.

## Progression layers

### Business progression

Unlock and upgrade businesses.

### Plot progression

Gain access to additional plots.

### District progression

Expand into larger neighborhoods or new district layouts.

### System progression

Later unlock:

- products;
- staff;
- equipment;
- more complex events;
- district reputation;
- creator mechanics.

### Region progression

Future content packs can introduce regional business/trend/event sets.

## Economy philosophy

Money should come primarily from successful customer service.

Revenue is affected indirectly by:

- demand;
- throughput;
- patience;
- queue length;
- downtime during upgrades;
- business selection.

Costs can include:

- building construction;
- upgrades;
- plot expansion;
- future equipment/staff;
- future maintenance.

The game should avoid becoming a passive “wait for timer, collect money” loop.

## Upgrade design

Upgrade is not a free statistical improvement.

It should create a temporary operational cost.

When a business upgrades:

- it becomes unavailable;
- current customers must reroute or leave;
- nearby businesses may receive overflow;
- queue pressure can move elsewhere.

This makes upgrade timing a decision.

## Business specialization

Businesses should eventually differ by more than numbers.

Examples:

### Cafe

- trend-sensitive;
- products with different preparation times;
- potential seating/service distinction.

### Minimart

- quicker service;
- lower revenue per customer;
- handles overflow well.

### EV Charging Station

- long service duration;
- vehicle-specific demand;
- capacity constrained by charger count.

### Photobooth

- **CURRENT prototype:** Quick Shot and Premium Strip use generic offering/service
  flow; Students prefer this business and Premium Strip more than other profiles.
- Future possibilities: session-based presentation, group customers, poses, and
  stronger trend sensitivity. These are not implemented yet.

### Pickleball Court

- long sessions;
- limited courts;
- strong time-of-day demand.

## Session feel

A normal play session should alternate between:

- observing the district;
- reacting to congestion;
- spending money;
- opening/upgrading businesses;
- responding to trend/event signals;
- watching consequences.

The game should not constantly demand high-speed tapping.

## Emergent stories

The long-term goal is for the player to remember situations created by the simulation:

- “I upgraded both cafes at the wrong time.”
- “That matcha trend completely destroyed my queue.”
- “The minimart saved the district while the cafe was closed.”
- “A creator visit made this block explode.”

These stories are more valuable than heavily scripted missions.
