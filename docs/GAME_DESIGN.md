# Game Design Document

## Elevator pitch

You run a struggling fantasy adventurers' guild. Every card is an **adventurer**. Each turn you recruit heroes, retire veterans to pull **action tokens** from the bag, and assign adventurers to **contracts** and **guild duties** — paying tokens and risking bodies. Inputs are explicit; outcomes are only partly known. Sending a cleric to fight undead might earn a bonus reward; sending a fighter might get him gravely injured.

## Setting & fantasy

- **World:** Classic fantasy — taverns, dungeons, rival guilds, petty nobles.
- **Role:** Guild master (player avatar), not a single field hero.
- **Tone:** Scarcity and triage. Adventurers get hurt often and die. The guild persists; people don't.
- **Feel:** Scraping for the right **actions** each turn — never enough tokens, never the perfect hero, always gambling on partial information.

## Design pillars

1. **Cards are adventurers** — There is no separate "guild asset" card type. Every card is a hero with race, class, attributes, and a personal bag contribution.
2. **Tokens are actions, not resources** — Bag tokens represent action types aligned with hero attributes: **Attack, Defense, Magic, Support, Leadership**. They are spent to perform guild activities, not traded as abstract gold or supplies.
3. **Clear inputs, partial outputs** — Contract and guild-action costs, required tokens, and adventurer assignment rules are fully visible. Success totals, rewards, injuries, deaths, and bonus synergies are hidden or hinted until discovered.
4. **Retire is the heartbeat** — Retiring an adventurer pulls action tokens from the bag and triggers retire effects on the guild. It is the main way to fuel the turn.
5. **Classical bag builder** — New adventurers add tokens to the discard pile. The bag draws when retiring; empty bag shuffles discard in. Dilution and composition matter.
6. **Exploration through play** — A discovery journal records what the guild has learned about contracts, matchups, and retire outcomes across runs.

## Core loop (full game)

```
┌──────────────────────────────────────────────────────────────────┐
│  TURN START — Offer new adventurers (free basics, priced veterans) │
│            + Refresh guild contracts + guild action board        │
├──────────────────────────────────────────────────────────────────┤
│  1. ACQUIRE  — Pick one offered adventurer                       │
│              → Adds their action tokens to the discard pile      │
├──────────────────────────────────────────────────────────────────┤
│  2. RETIRE   — Remove one adventurer from the roster             │
│              → Draw 2 + level + retire bonuses from the bag      │
│              → Apply retire effect(s) on the guild                 │
├──────────────────────────────────────────────────────────────────┤
│  3. ACT      — Spend drawn tokens + assign adventurers to:       │
│              • Contracts (rotating each turn)                      │
│              • Other guild actions (train, rest, scout, etc.)      │
│              → Resolve partial/hidden outcomes per assignment    │
├──────────────────────────────────────────────────────────────────┤
│  4. END TURN — Injuries persist, upkeep, win/lose checks          │
└──────────────────────────────────────────────────────────────────┘
```

## Systems overview

### Bag & action tokens

| Concept | Description |
|---------|-------------|
| **Bag** | Draw pool of action tokens. |
| **Discard pile** | New adventurers add tokens here. When the bag is empty, shuffle discard into bag. |
| **Action tokens** | Five types, matching adventurer attributes: **Attack, Defense, Magic, Support, Leadership**. |

Drawing tokens gives you **actions you can perform this turn**. Unspent tokens are typically lost at end of turn (scrape pressure).

### Adventurers (cards)

Every card is an adventurer. There are no non-hero card types.

| Property | MVP | Full game | Visibility |
|----------|-----|-----------|------------|
| Name | ✓ | ✓ | Visible |
| Level | ✓ | ✓ | Visible |
| Tokens added to discard | ✓ | ✓ | Visible |
| Retire draw bonus | ✓ | ✓ | Visible |
| Retire guild effect | ✓ | ✓ | Tag visible; effect hidden until triggered |
| Race | — | ✓ | Visible |
| Class | ✓ (simplified) | ✓ | Visible |
| Attributes (5) | ✓ (subset) | ✓ | Visible |
| Injury / death state | ✓ | ✓ | Visible state; severity partly hidden |
| Equipment | — | ✓ | Visible slot; hidden curse possible |

**Attributes** (each maps 1:1 to an action token type):

| Attribute | Action token | Typical adventurer use |
|-----------|--------------|------------------------|
| Attack | Attack | Martial contracts, clearing threats |
| Defense | Defense | Holding lines, escort, survival |
| Magic | Magic | Arcane or holy problems |
| Support | Support | Healing, logistics, buffs |
| Leadership | Leadership | Coordinating parties, negotiation |

### Retire formula

```
tokens_drawn = 4 + retired_adventurer.level + retired_adventurer.retire_bonus
```

### Guild: contracts

Contracts are **not cards**. They are guild-board opportunities that **refresh each turn**.

| Element | Visibility |
|---------|------------|
| Contract name & flavor | Visible |
| Required tokens (to attempt) | Visible |
| Required heroes (1 or 2) and optional extra slots | Visible |
| Success totals (tokens + attributes needed) | Hidden |
| Optional extra tokens the player may add | Visible to spend; effect hidden |
| Outcome hints (tags, partial text) | Partially visible |
| Exact rewards | Hidden until resolved or discovered |
| Class bonuses (e.g. Cleric always wins) | Hidden until discovered |
| Injury/death on fail | Hidden or hinted ("High risk") |

**Example — Clear Undead Crypt**

| Visible | Hidden (MVP 1) | Deferred |
|---------|----------------|----------|
| Required: 2 Attack, 1 Magic; 1 hero | Cleric → always succeeds, extra gold | Low defense → injury on success / death on fail |
| Succeeds at 3 Attack + 2 Magic (hidden) | Failed fighter → death | Heavy support → uncover a new contract |
| Optional extra tokens and +1 hero | | |

Success is `required tokens + extra tokens + hero attributes` against hidden totals. A warrior plus an extra Magic token can succeed; a warrior plus a mage can succeed on attributes.

To perform a contract: pay the required tokens, send the minimum heroes, optionally add extras, then resolve success/fail and any hidden matchup. **One contract per round.**

### Guild: other actions

Permanent or rotating **guild actions** beyond contracts — things adventurers do at the hall.

Examples (full game):

| Action | Token cost | Adventurers | Partial info |
|--------|------------|-------------|--------------|
| Rest & recover | 1 Support | 1 injured hero | "Recovery likely" |
| Train | 2 Leadership | 1 hero | Level gain; hidden injury risk on failed roll |
| Scout contract | 1 Leadership | 1 hero | Reveals one hidden line on a contract |
| Upgrade equipment | 1 Attack + 1 Defense | 1 hero | Visible slot; hidden curse chance |
| Guild promotion | 3 Leadership | 1 hero | Improves retire bonus; morale impact hidden |

Same rule: **pay tokens + send adventurers**. Inputs clear; outcomes partial.

### Injury & death

- Adventurers can be **injured** (reduced effectiveness, cannot redeploy until treated) or **killed** (removed from roster).
- Bad contract matchups are a primary injury source in the full game.
- Treatment is a guild action (Support tokens + assign healer-type adventurer).

### Hidden information model

| Always visible | Partially visible | Hidden until triggered |
|----------------|-------------------|------------------------|
| Token costs | Outcome hints, risk tags | Exact reward amounts, success totals |
| Adventurer attributes & class | "Bonus for holy types" | Full matchup table row |
| Tokens added to discard | Reward tier ("good / poor") | Which class triggers bonus |
| Retire draw math | Contract difficulty band | Exact injury severity |
| Who must be sent (count) | | Equipment curse effects |
| Acquire cost & level | | Some retire guild effects |

**Discovery journal:** Records first-time revelations — e.g. "Undead Crypt + Cleric → bonus reward", "Undead Crypt + Fighter → severe injury".

### Win & lose (full game)

To be tuned. Candidates:

- **Win:** Complete a contract saga, reach reputation threshold, survive N seasons with roster intact.
- **Lose:** All adventurers dead, guild morale collapsed, or failed critical contract chain.

## Technical target

- **Engine:** Godot 4.x
- **Platform (MVP):** Desktop (Windows / Linux / macOS)
- **Data:** Adventurer, contract, guild-action, and matchup definitions as JSON or Godot Resources
- **Architecture:** Turn-state machine, bag simulator, contract board, matchup resolver, discovery journal

## Out of scope for this doc

- Art style guide
- Audio
- Localization
- Multiplayer
