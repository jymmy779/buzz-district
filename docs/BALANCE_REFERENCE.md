# Buzz District — Prototype Balance Reference

> These numbers are for prototype testing. They are not final balance.

## Offerings

| ID | Business | Display name | Base time | Base price | Default weight |
|---|---|---|---:|---:|---:|
| coffee | Cafe | Coffee | 4.0s | $10 | 70 |
| matcha_latte | Cafe | Matcha Latte | 5.5s | $14 | 30 |
| quick_purchase | Minimart | Quick Purchase | 3.0s | $8 | 100 |
| quick_shot | Photobooth | Quick Shot | 4.5s | $12 | 70 |
| premium_strip | Photobooth | Premium Strip | 7.0s | $20 | 30 |

Default weights are the fallback for customers without a profile override. Current
Cafe customers use their profile's Coffee/Matcha baseline, then Matcha Wave applies
its multiplier. Observed short queues are not guaranteed to match either ratio.

## Cafe

Build cost: $300. Max level: 3.

| Level | Capacity | Queue | Speed multiplier | Income bonus | Upgrade cost | Upgrade time |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 3 | 1.0 | $0 | $200 | 10s |
| 2 | 2 | 4 | 1.25 | $2 | $400 | 20s |
| 3 | 3 | 5 | 1.5 | $5 | — | — |

| Level | Coffee time / payment | Matcha time / payment |
|---|---|---|
| 1 | 4.0s / $10 | 5.5s / $14 |
| 2 | 3.2s / $12 | 4.4s / $16 |
| 3 | ~2.667s / $15 | ~3.667s / $19 |

Cafe Lv3 Coffee now uses exact 4 / 1.5 seconds rather than the old fixed 2.7s.

## Minimart

Build cost: $400. Max level: 3.

| Level | Capacity | Queue | Speed multiplier | Income bonus | Upgrade cost | Upgrade time |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 2 | 1.0 | $0 | $250 | 10s |
| 2 | 2 | 3 | 1.2 | $3 | $500 | 20s |
| 3 | 3 | 4 | 1.5 | $6 | — | — |

Quick Purchase effective time/payment: Lv1 3.0s/$8, Lv2 2.5s/$11, Lv3 2.0s/$14.

## Photobooth

Build cost: $500. Max level: 3.

| Level | Capacity | Queue | Speed multiplier | Income bonus | Upgrade cost | Upgrade time |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 2 | 1.0 | $0 | $300 | 12s |
| 2 | 2 | 3 | 1.2 | $3 | $600 | 24s |
| 3 | 2 | 4 | 1.45 | $6 | — | — |

| Level | Quick Shot time / payment | Premium Strip time / payment |
|---|---|---|
| 1 | 4.5s / $12 | 7.0s / $20 |
| 2 | 3.75s / $15 | ~5.833s / $23 |
| 3 | ~3.103s / $18 | ~4.828s / $26 |

For every offering:
- actual service time = base_service_time / service_speed_multiplier;
- payment = base_price + income_bonus.

## Customer profiles

| Profile | Spawn | Patience | Cafe / Mart / Photo | 1 / 2 stops | Coffee / Matcha | Quick / Premium |
|---|---:|---:|---:|---:|---:|---:|
| Office Worker | 45 | 8–12s | 55 / 35 / 10 | 55% / 45% | 80 / 20 | 75 / 25 |
| Student | 35 | 12–18s | 40 / 25 / 35 | 60% / 40% | 35 / 65 | 45 / 55 |
| Shipper | 20 | 6–10s | 20 / 70 / 10 | 80% / 20% | 85 / 15 | 90 / 10 |

Patience decreases only while waiting, is preserved across rerouting, and resets
to the same profile-generated maximum when a successful purchase starts a new stop.
Trip business weights only consider business types that currently exist and are
active in the district.

## Demand spawn ranges

### LOW

- approximately `2.5–5.0s`

### NORMAL

- approximately `1.2–3.0s`

### HIGH

- approximately `0.5–1.5s`

Default:

- `NORMAL`

## Stress-testing

Very fast spawn intervals such as `0.2–0.5s` are acceptable only for stress-testing service slots/queues.

They should not be treated as normal gameplay balance.

## Balance philosophy

Numbers should eventually be balanced around relationships:

- arrival rate;
- service rate;
- queue length;
- patience;
- revenue;
- upgrade cost;
- downtime.

Do not tune one number in isolation.

Example:

If Lv.3 clears customers so quickly that the third service slot almost never fills, the problem may be demand/service relationship rather than a broken capacity system.


## Matcha Wave — CURRENT

- Duration: 30 seconds of simulation time.
- Coffee modifier: x0.5 (70 -> 35).
- Matcha Latte modifier: x3.5 (30 -> 105).
- Profile preferences are applied before trend modifiers.
- Expected Office Worker mix during wave: ~36% Coffee / ~64% Matcha.
- Expected Student mix during wave: ~7% Coffee / ~93% Matcha.
- Expected Shipper mix during wave: ~45% Coffee / ~55% Matcha.
- Quick Purchase modifier: x1.0 (unchanged).
- Start while active: ignored; no refresh or stacking.
- End/load: restore base weights immediately for new selections.
- Demand spawn intervals, service times, prices and existing orders are unchanged.

At Cafe Lv1, expected processing time per new order rises from
0.7*4 + 0.3*5.5 = 4.45s to 0.25*4 + 0.75*5.5 = 5.125s.
This excludes walking and is not a guaranteed queue length: observed pressure also
depends on arrivals, level capacity, patience and the random sample.

## Lunch Rush — CURRENT

- Duration: 30 seconds of simulation time.
- Office Worker spawn modifier: x2.0 (45 -> 90 effective weight).
- Student spawn modifier: x0.75 (35 -> 26.25 effective weight).
- Shipper spawn modifier: x1.0 (20 -> 20 effective weight).
- Expected normalized mix: approximately 66.1% Office Worker, 19.3% Student,
  14.7% Shipper.
- Offering weights, profile patience, business preferences, and trip probabilities
  are unchanged directly.
- Replacement/expiry restores base profile weights immediately.
