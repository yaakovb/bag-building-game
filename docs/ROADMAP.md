# Development Roadmap

High-level milestones. Each MVP is a shippable increment. Do not start a later MVP until the previous one's acceptance criteria pass.

```
MVP 1 ──► MVP 2 ──► MVP 3 ──► MVP 4 ──► Full Alpha
 Core      Depth     Discovery   Meta       Content
 loop      systems   & journal   & scenarios & polish
```

---

## MVP 1 — Core Loop (current)

**Goal:** Adventurers-only cards, action tokens, rotating contracts, token + assign resolution, partial outcomes.

See [MVP-1.md](MVP-1.md) for full spec.

**Includes:** 3 starters, bag builder, acquire/retire/act, 4 contracts, 2 guild actions, injury/death teach moment (Undead Crypt).

**Exit criteria:** Core loop fun; wrong-hero-assignment tension validated; Godot scaffold in place.

---

## MVP 2 — Roster Depth

**Goal:** Richer adventurers and guild board — not "add heroes" (already in MVP 1).

### Adds

- **Race** on every adventurer; race × class matchup rows
- **Full attribute model** — all five attributes on every hero with UI bars
- **Equipment slot** — visible bonus, hidden curse; equip via guild action
- **Injury tiers** — Injured vs Grave vs Death (Grave recoverable via costly Rest chain)
- **More guild actions** — Scout (reveal contract line), Equip, Dismiss
- **Third contract slot** on board
- **Leveling cap** raised; Train improvements

### Content target

- +6 adventurers, +4 contracts, +3 matchup rows per contract family
- 6 equipment items

### Acceptance criteria

- [ ] Race affects at least 3 contract matchups
- [ ] Equipment curse discoverable via journal
- [ ] Grave injury recoverable with multi-turn Rest investment
- [ ] 15-turn run winnable with roster management skill

---

## MVP 3 — Discovery & Exploration

**Goal:** Hidden information as a progression system across runs.

### Adds

- **Cross-run discovery journal** (persisted)
- **Rumor hints** between runs for undiscovered matchups
- **Contract reward tiers** upgrade UI when discovered ("Good", "Poor", etc.)
- **Scout guild action** — reveal one hidden line before committing
- **Synergy discoveries** — multi-hero combos (e.g. Cleric + Leader on Escort)
- **Tier 3 recruits** in offer pool

### Acceptance criteria

- [ ] Journal persists across restarts
- [ ] Second run player makes better Undead Crypt choice without full spoiler
- [ ] At least 5 synergies discoverable in content pool

---

## MVP 4 — Meta Progression & Scenarios

**Goal:** Replayability through scenarios and content unlocks, not raw power.

### Adds

- **2 scenarios** — different starter rosters, contract pools, win conditions
- **Unlockable contract families** via discovery milestones
- **Rival guild pressure** clock
- **Hall upgrades** — passive modifiers (e.g. +1 contract slot)
- **Save/load mid-run**
- Balance pass on MVP 1–3 numbers

### Acceptance criteria

- [ ] 2 scenarios complete start to finish
- [ ] 1 contract family gated behind discovery unlock
- [ ] 30-minute run feels complete

---

## Full Alpha (post-MVP 4)

| Area | Work |
|------|------|
| Art | Adventurer portraits, token icons, guild hall |
| Audio | Assignment confirm, injury sting, victory/defeat |
| UX | Tutorial highlighting Undead Crypt teach moment |
| Content | 30+ adventurers, 15+ contracts, full race list |
| Balance | Difficulty tiers, seeded runs |
| Platform | itch.io desktop build |

---

## Principles for all milestones

1. **Cards are always adventurers** — contracts and guild actions live on the board, not in the bag.
2. **Tokens are actions** — never reintroduce abstract resource tokens (gold in bag, etc.). Guild coin is the sole non-bag economy for hiring.
3. **Clear inputs, partial outputs** — every new contract documents visible costs before hidden matchups.
4. **Data-driven** — adventurers, contracts, matchups in JSON.
5. **Tune after playtest** — numbers in docs are starting points.
