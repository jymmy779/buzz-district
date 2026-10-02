# Buzz District — Roadmap

This roadmap describes dependency order, not deadlines.

## Current prototype foundation

Implemented / currently established:

- Godot project
- plot selection
- generic building lifecycle
- money
- build
- upgrade countdown
- Cafe
- generic business architecture
- Minimart
- service slots
- customer movement
- queue FIFO
- queue repositioning
- patience
- patience bar
- customer rerouting
- demand states
- payment/income feedback

Visuals remain placeholders.

## Next phase — Persistence

### Local Save / Load

Persist:

- player money;
- building type per plot;
- building level;
- progression state needed to reconstruct the district.

Do not attempt to serialize transient NPC/Tween/coroutine state.

After load:

- rebuild logical building state;
- resume normal customer simulation.

Offline upgrade progression can be added later if needed.

## Next phase — Second simulation pass

Once persistence is stable:

- verify Cafe + Minimart differences feel meaningful;
- clean generic building API;
- reduce prototype-only debug logic;
- prepare building scene abstraction.

## Product/service layer

Add a minimal product/service system.

Example Cafe:

- Coffee
- Matcha

Product owns:

- base price;
- base processing time.

Building owns:

- capacity;
- speed.

NPC owns:

- preference.

This is the point where trends can alter what people order instead of only global spawn rate.

## Buzz / Trend MVP

Implement the smallest real Buzz loop:

1. trend starts;
2. ThreadZ signals it;
3. demand/preferences change;
4. simulation visibly changes;
5. trend expires.

First trend candidate:

**fictional Matcha Wave**

## Event framework

After one trend proves the loop:

- event definitions;
- modifiers;
- duration;
- target scope;
- UI signal;
- cleanup.

## Path / map upgrade

Replace prototype straight-line movement with:

- entrances;
- sidewalk/path network;
- real service markers;
- real queue markers.

Only do this once building layout/art direction is stable enough.

## More businesses

Candidates:

- EV Charging Station
- Photobooth
- Parcel Locker
- Coworking
- Pickleball Court

Do not add many businesses before the generic systems can support them without copy-paste.

## NPC differentiation

Add archetypes and preferences:

- Office Worker
- Student
- Shipper
- Creator
- Driver

## Advanced simulation

Later possibilities:

- time of day;
- weather;
- traffic;
- business reputation;
- staff;
- equipment;
- seating;
- inventory;
- district popularity.

## Art production

Begin serious art production after:

- map structure;
- building scene structure;
- core simulation;
- UI information hierarchy

are stable enough to avoid throwing art away.

## Online features

No backend required for the core game.

Only evaluate backend when a concrete feature needs it:

- cloud save;
- live events;
- account sync;
- social/community functionality;
- remote content configuration.
