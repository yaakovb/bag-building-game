# Development Roadmap

High-level milestones after MVP 1. Each MVP is a shippable increment. Do not start a later MVP until the previous one's acceptance criteria pass.

```
MVP 1 ──► MVP 2 ──► MVP 3 ──► MVP 4 ──► Full Alpha
 Core      Heroes    Discovery   Meta       Content
 loop      & injury  & journal   progression  & polish
```

---

## MVP 1 — Core Loop ✅ (current)

**Goal:** Playable 10-turn run with bag builder, hidden retire effects, and guild tracks.

See [MVP-1.md](MVP-1.md) for full spec.

**Exit criteria:** Core loop is fun; scrape feel validated; Godot project structure in place.

---

## MVP 2 — Heroes & Injury

**Goal:** Cards become people. Death and injury create scrape tension beyond track numbers.

### Adds

- **Hero card type** — distinct from generic guild assets; portrait placeholder, name
- **Injury system** — heroes become Injured on certain retire Risk effects or end-of-turn checks; injured heroes have −1 retire bonus
- **Death** — hero removed permanently; triggers memorial retire effect (hidden)
- **Equipment slot** — one item per hero; visible stat bonus, hidden curse possible
- **Fame spend** — use Fame to stabilize Morale or prevent injury escalation
- **Roster limit** — guild hall size (3 heroes MVP 2)

### Content target

- 6 hero cards, 4 equipment items, 4 non-hero guild assets
- 4 new retire effects (injury/death related)

### Acceptance criteria

- [ ] Hero can be injured, treated, and killed in a single run
- [ ] Equipment with hidden curse discoverable via journal
- [ ] Fame has at least one spend action
- [ ] Player can win and lose a 15-turn run with heroes

---

## MVP 3 — Discovery & Exploration

**Goal:** Hidden information becomes a first-class system, not just obfuscated text.

### Adds

- **Effect category tags** refined (Morale, Treasury, Risk, Roster, Hall)
- **Scout action** — spend tokens to reveal one hidden line before retiring
- **Cross-run discovery journal** — persisted to disk; effects stay revealed forever
- **Rumor hints** — between-run text snippets for undiscovered effects in the pool
- **Synergy discoveries** — e.g. "Bard + Banner" combo logged when first triggered
- **Offer variety** — 4-card offers; tier 3 cards introduced

### Acceptance criteria

- [ ] Journal persists across application restarts
- [ ] Scout action works and costs tokens
- [ ] Second run feels more informed than first without full spoilers
- [ ] At least 3 synergies discoverable

---

## MVP 4 — Meta Progression & Scenario

**Goal:** Reason to replay. Light meta unlocks that add content, not power.

### Adds

- **Scenario select** — 2 starting scenarios (e.g. "Debtor's Guild", "Frontier Post")
- **Unlockable card families** — Contracts, Facilities added to pools after milestones
- **Hall upgrades** — persistent between runs within a campaign (optional roguelike mode)
- **Rival guild pressure** — abstract clock that advances each turn; lose if it reaches end
- **Save/load run** — mid-run persistence
- **Balance pass** — tune all numbers from MVP 1–3 playtests

### Acceptance criteria

- [ ] 2 scenarios playable start to finish
- [ ] At least 1 card family unlocks via discovery milestone
- [ ] Run save/load works
- [ ] 30-minute run feels complete and replayable

---

## Full Alpha (post-MVP 4)

Not a single milestone — ongoing polish track.

| Area | Work |
|------|------|
| Art | Card frames, token icons, guild hall background |
| Audio | UI clicks, retire sting, victory/defeat stings |
| UX | Tutorial flow, tooltips, phase highlighting |
| Content | 40+ cards, 6+ token types, 20+ effects |
| Balance | Difficulty tiers, seed display for bug reports |
| Platform | Export templates, itch.io build |

---

## Principles for all milestones

1. **Playable over perfect** — each MVP ships a complete run, not a feature demo.
2. **Data-driven** — new cards and effects via data files, not code changes.
3. **Discover, don't spoil** — meta unlocks are hints and content, not +10% power.
4. **Tune after playtest** — numbers in docs are starting points; adjust after 3+ solo runs.
