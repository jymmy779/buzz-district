# Buzz District — Prototype Balance Reference

> These numbers are for prototype testing. They are not final balance.

## Cafe

### General

- Build cost: `$300`
- Max level: `3`

| Level | Service capacity | Queue capacity | Service time | Income/customer | Upgrade cost | Upgrade time |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 3 | 4.0s | $10 | $200 | 10s |
| 2 | 2 | 4 | 3.2s | $12 | $400 | 20s |
| 3 | 3 | 5 | 2.7s | $15 | — | — |

## Minimart

### General

- Build cost: `$400`
- Max level: `3`

| Level | Service capacity | Queue capacity | Service time | Income/customer | Upgrade cost | Upgrade time |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 1 | 2 | 3.0s | $8 | $250 | 10s |
| 2 | 2 | 3 | 2.5s | $11 | $500 | 20s |
| 3 | 3 | 4 | 2.0s | $14 | — | — |

## Customer patience

Prototype:

- `patience_max`: random approximately `8–15s`
- decreases only while waiting
- preserved across rerouting

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
