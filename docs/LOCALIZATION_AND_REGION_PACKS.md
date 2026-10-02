# Buzz District — Localization & Region Packs

## Initial languages

Target:

- English
- Vietnamese

Potential later languages:

- Thai
- Indonesian
- Korean
- Japanese
- Simplified Chinese

## Text architecture

Avoid hard-coded player-facing strings when UI structure becomes stable.

Use Godot localization keys / `tr()`.

Examples:

```text
building.cafe.name
building.minimart.name
ui.build
ui.upgrade
event.matcha_wave.title
```

## Culture is not only translation

Internet jokes, trends, and social behavior do not translate literally.

Long-term content should support culture/region packs.

Shared simulation:

- demand;
- queue;
- patience;
- event modifiers.

Localized content:

- event flavor;
- trend names;
- fictional brands;
- social posts;
- business skins;
- NPC archetypes.

## Example

Shared event template:

**Viral drink trend**

Simulation:

- cafe demand increases;
- one product preference increases;
- queues grow.

Vietnam pack:

- fictional matcha trend.

Another region:

- another culturally relevant drink/product.

Same mechanic, different content.

## Translation tone

ThreadZ content should be localized for natural internet speech.

Do not translate slang word-for-word when it becomes unnatural.

## Content fallback

Every culture-specific event should have:

- internal ID;
- simulation effect;
- default English copy;
- region-specific copy when available.

Game logic must not depend on one exact localized string.

## Proper nouns

Prefer fictional names that are easy to localize or preserve.

Avoid building core progression around trademarks.

## UI constraints

Localization must account for:

- longer English text;
- Vietnamese diacritics;
- CJK fonts;
- button width;
- line wrapping.

Do not bake text into art assets when avoidable.
