# Bag Building Game — Documentation

Design and development docs for a fantasy guild-management bag-builder built in Godot.

## Documents

| Document | Purpose |
|----------|---------|
| [Game Design](GAME_DESIGN.md) | Vision, pillars, core systems (adventurers, action tokens, contracts) |
| [MVP 1](MVP-1.md) | First playable vertical slice — scope, content, acceptance criteria |
| [Roadmap](ROADMAP.md) | Planned milestones after MVP 1 |

## Reading order

1. **Game Design** — understand the model: heroes as cards, tokens as actions, contracts on the guild board
2. **MVP 1** — what ships first
3. **Roadmap** — what comes next

## Core concepts (quick reference)

| Concept | Meaning |
|---------|---------|
| **Card** | Always an adventurer (never a generic guild asset) |
| **Token** | Action type = attribute: Attack, Defense, Magic, Support, Leadership |
| **Contract** | Guild-board opportunity each turn; costs tokens + assigned heroes |
| **Input** | Costs, attributes, who can be sent — always visible |
| **Output** | Rewards, injuries, bonuses — partial hints; full detail via discovery |

## Status

| Milestone | Status |
|-----------|--------|
| MVP 1 — Core loop (heroes, contracts, action tokens) | Planning |
| MVP 2 — Roster depth (race, equipment, injury tiers) | Not started |
| MVP 3 — Cross-run discovery | Not started |
| MVP 4 — Scenarios & meta | Not started |
