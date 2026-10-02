# Buzz District — Art & UX Direction

## Visual goal

Modern stylized 2D isometric city.

Avoid:

- retro pixel-game look;
- overly realistic rendering;
- visually dense UI;
- old mobile-game aesthetic.

The game should feel contemporary and social-media-era.

## World readability

The player must be able to visually distinguish:

- empty plot;
- active business;
- upgrading business;
- service customer;
- waiting customer;
- unhappy/impatient customer;
- high-demand business;
- event hotspot.

Readability is more important than visual detail.

## Buildings

Buildings should have:

- strong silhouette;
- recognizable category;
- clear upgrade progression;
- visible entrances/service areas when relevant.

Upgrade levels should eventually change more than text.

## NPCs

Prototype NPCs can remain simple shapes.

Final NPC direction:

- stylized;
- readable at mobile scale;
- archetype recognizable through clothing/accessories;
- limited but expressive animations.

Potential archetypes:

- office worker;
- student;
- shipper;
- creator;
- driver.

## Isometric direction

Use a consistent isometric grid/layout once map art begins.

Avoid mixing UI `Control` positioning logic with world-space simulation in ways that make movement difficult.

Current Button-based plots are prototype UI/world placeholders.

They are not the final art architecture.

## UI principles

### Minimal actions

Common management actions should take as few taps as possible.

### Contextual controls

Selecting a building should expose only relevant actions.

### State visibility

Upgrade countdown, queue, patience, money, and important events should be visible without opening deep menus.

### Mobile-first targets

Buttons and touch areas must remain usable on phone screens.

## Customer feedback

Current:

- income popup;
- patience bar.

Future:

- small emotion bubble;
- service icon;
- queue indicator;
- event reaction.

Avoid floating too many labels simultaneously.

## ThreadZ presentation

ThreadZ should feel like an in-world social feed.

It should communicate:

- trends;
- complaints;
- creator visits;
- local chatter.

It should not become a separate full social-media app inside the game.

## Trend visualization

Players should see trend effects in the district, not only in UI text.

Examples:

- more customers physically arriving;
- queue length changing;
- particular NPC archetypes appearing;
- one business becoming a hotspot.

## Placeholder policy

Do not block simulation development waiting for final visuals.

Placeholder visuals are expected until:

- core loop is stable;
- building types are proven;
- movement/path architecture is clearer.
