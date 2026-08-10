# Game Design Document

## Elevator pitch

You run a struggling fantasy adventurers' guild. Each turn you scrape together resources from a token bag, recruit and retire guild assets, and try to keep heroes alive long enough to matter. Inputs are clear; outcomes are uncertain — discovery is part of the game.

## Setting & fantasy

- **World:** Classic fantasy — taverns, dungeons, rival guilds, petty nobles.
- **Role:** Guild master (player avatar), not a single hero.
- **Tone:** Scarcity and triage. Heroes get hurt often and die. The guild persists; people don't.
- **Feel:** Scraping resources every turn — never quite enough, always choosing the least bad option.

## Design pillars

1. **Scrape, don't optimize** — The player should feel resource-poor most of the time. Free basics keep you alive; expensive picks are gambles.
2. **Clear inputs, hidden outputs** — Costs, levels, token types added to discard, and retire draw formula are always visible. Retire effects, injury severity, equipment curses, and some synergies are hidden until discovered.
3. **Retire is the heartbeat** — Retiring a card is the main way to pull from the bag and trigger guild-wide consequences.
4. **Classical bag builder** — Tokens go to discard; bag draws from discard when empty; dilution and composition matter.
5. **Exploration through play** — A discovery journal logs what the guild has learned. Runs teach; meta unlocks hints, not raw power.

## Core loop (full game)

```
┌─────────────────────────────────────────────────────────────┐
│  TURN START — Offer cards (free basics + priced upgrades)   │
├─────────────────────────────────────────────────────────────┤
│  1. ACQUIRE  — Pick one card → adds tokens to discard pile  │
├─────────────────────────────────────────────────────────────┤
│  2. RETIRE   — Remove one card from play                    │
│              → Draw 2 + card level + retire bonuses         │
│              → Apply retire effect(s) on guild              │
├─────────────────────────────────────────────────────────────┤
│  3. SPEND    — Use drawn tokens on heroes, cards, or guild  │
├─────────────────────────────────────────────────────────────┤
│  4. RESOLVE  — Injuries, deaths, upkeep, end-of-turn hooks │
└─────────────────────────────────────────────────────────────┘
```

## Systems overview

### Bag & tokens

| Concept | Description |
|---------|-------------|
| **Bag** | Draw pool. Tokens are pulled when retiring a card. |
| **Discard pile** | New cards add tokens here. When the bag is empty, shuffle discard into bag. |
| **Token types** | MVP starts with 2–3 types; full game expands (Coin, Supply, Fame, etc.). |

### Cards

| Property | Visibility |
|----------|------------|
| Tier & cost | Visible |
| Tokens added to discard | Visible |
| Level | Visible |
| Retire draw bonus | Visible |
| Retire guild effect(s) | Hidden (tags hint at category) |
| Upgrade paths | Visible cost; hidden perks possible at thresholds |

**Card families (full game):** Heroes, Contracts, Facilities, Patrons.

### Retire formula

```
tokens_drawn = 2 + retired_card.level + retired_card.retire_bonus
```

### Heroes (full game)

- **Leveling** — Spend tokens to increase level (improves retire draw).
- **Equipment** — One slot; modifies spend or survival; may have hidden downsides.
- **Injury** — Common; reduces effectiveness until treated.
- **Death** — Removed from play; may trigger hidden retire-adjacent effects.

### Guild board (full game)

Tracks such as Morale, Reputation, Treasury, Hall level. Retire effects and spending modify these.

### Hidden information model

| Always visible | Hidden until triggered |
|----------------|------------------------|
| Card tier and acquire cost | Exact retire guild effect text |
| Tokens added to discard | Injury/death outcome details |
| Card level and retire draw math | Equipment curse effects |
| Effect category tags (e.g. Morale, Risk) | Synergy combinations |

**Discovery journal:** First time an effect fires, it is recorded permanently (in-run and across runs in full game).

### Win & lose (full game)

To be tuned. Candidates:

- **Win:** Survive N seasons, complete a saga arc, or reach reputation threshold.
- **Lose:** Morale hits zero, treasury bankrupt, or roster wiped with no recovery path.

## Technical target

- **Engine:** Godot 4.x
- **Platform (MVP):** Desktop (Windows/Linux/macOS)
- **Data:** Card/token/effect definitions as Godot Resources or JSON for easy iteration
- **Architecture:** Turn-state machine, bag simulator, effect resolver, discovery journal service

## Out of scope for design doc

- Art style guide (separate doc later)
- Audio
- Localization
- Multiplayer
