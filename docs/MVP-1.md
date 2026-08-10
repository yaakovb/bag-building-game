# MVP 1 — Core Loop Prototype

## Purpose

MVP 1 validates the **core turn loop** and **classical bag-building** in Godot. It is a playable vertical slice with minimal content, placeholder art, and no meta-progression. If this isn't fun in ten turns, we fix the loop before adding heroes, injury, or discovery systems.

## One-sentence goal

> The player can complete a full 10-turn run: acquire cards, retire for tokens, spend tokens, and win or lose — with the bag economy feeling tense and readable.

## Player experience (MVP 1)

You are a guild master with a nearly empty hall. Each turn you pick a card from a small offer, retire one card to draw tokens from the bag, and spend those tokens to keep the guild afloat. Basics are free; better cards cost tokens. You don't know exactly what retiring a card will do to the guild — only that it belongs to a category (Morale, Risk, etc.). You scrape by until you hit the season goal or go broke.

## Scope

### In scope

| Area | MVP 1 delivery |
|------|----------------|
| Turn state machine | Acquire → Retire → Spend → End Turn |
| Bag builder | Discard pile, bag draw, shuffle-when-empty |
| Card offer | 3 cards per turn: 1 free basic + 2 priced |
| Acquire | Pick card, pay cost, add listed tokens to discard |
| Retire | Pick in-play card, draw `2 + level + bonus`, apply retire effect |
| Spend | Spend drawn tokens on guild tracks or card upgrades |
| Guild tracks | **Morale** and **Treasury** only (0–10 each) |
| Card upgrades | Pay tokens to raise card level (+1 retire draw per level) |
| Hidden retire effects | 6 effect types; show category tag only until first trigger |
| Discovery journal | In-run log of revealed effects |
| Win / lose | Win at Treasury ≥ 8 after turn 10; lose if Morale = 0 or Treasury = 0 |
| Content | 8 card definitions, 3 token types |
| UI | Single main screen: offer, in-play cards, bag/discard counts, guild tracks, journal panel |
| Persistence | None (single session) |

### Out of scope (deferred)

- Heroes as distinct entities (injury, death, equipment)
- Contracts, Facilities, Patrons card families
- Meta-progression between runs
- Map, events, shops, rival guilds
- Audio, animations, polished art
- Save/load
- Tutorial beyond a one-screen "how to play"
- Scout/reveal actions
- More than one scenario

## Turn flow (MVP 1 detail)

### Phase 0 — Turn start

- Increment turn counter (displayed).
- Generate offer: **1 Basic (tier 0, cost 0)** + **2 cards** drawn from the priced pool (tier 1–2).
- If offer cannot be filled (edge case), fill with basics.

### Phase 1 — Acquire

- Player selects exactly **one** card from the offer.
- **Cost:** Shown on card. Deduct from **Treasury** (not from bag tokens). Free cards cost 0.
- **Effect:** Card enters the **in-play row** (max 5 cards; if full, player must retire before acquire next turn — see note below).
- **Discard contribution:** Listed token types/amounts added to **discard pile** immediately.

> **Hand limit note:** MVP 1 enforces max 5 in-play cards. If at cap at start of Acquire, skip to Retire first OR force retire before acquire. **Decision: force Retire before Acquire when at cap** (retire phase comes first if hand is full).

**Revised order when hand full:** Retire → Acquire → Spend → End.

Normal order when hand not full: Acquire → Retire → Spend → End.

### Phase 2 — Retire

- Player selects exactly **one** in-play card.
- **Draw:** Pull `2 + card.level + card.retire_bonus` tokens from bag. If bag insufficient, shuffle discard into bag, then continue drawing.
- **Retire effect:** Resolve the card's hidden guild effect (see effect table). Log to discovery journal if first time seen.
- **Remove** card from play permanently (MVP 1: no memorial mechanics).

### Phase 3 — Spend

- Player spends **any or all** drawn tokens (unspent tokens are lost at end of turn — creates scrape pressure).
- **Allowed actions:**

| Action | Cost | Effect |
|--------|------|--------|
| Boost Morale | 2 Supply | Morale +1 (max 10) |
| Fill Treasury | 2 Coin | Treasury +1 (max 10) |
| Upgrade card | 3 Coin + 1 Supply | Target in-play card level +1 (max 3) |

- Tokens are **typed** and **fungible only within spend recipes** (player must have exact types).

### Phase 4 — End turn

- Check lose: Morale ≤ 0 or Treasury ≤ 0 → **defeat**.
- Check win: Turn ≥ 10 AND Treasury ≥ 8 → **victory**.
- Clear unspent drawn tokens.
- Next turn.

## Token types (MVP 1)

| Token | Color | Role |
|-------|-------|------|
| **Coin** | Gold | Treasury spending, upgrades |
| **Supply** | Brown | Morale healing, upgrades |
| **Fame** | Purple | No spend use in MVP 1 (bag dilution / future hook) |

Fame tokens enter the bag via cards but cannot be spent in MVP 1. This teaches dilution without extra systems.

## Card content (MVP 1)

8 cards total. All are generic "Guild Assets" (no hero identity yet).

### Basics (tier 0, cost 0) — 2 definitions

| ID | Name | To discard | Retire bonus | Hidden effect tag |
|----|------|--------------|--------------|-------------------|
| `basic_supplies` | Supply Crate | 2 Supply | 0 | Morale |
| `basic_coins` | Coin Purse | 2 Coin | 0 | Treasury |

### Tier 1 (cost 1 Treasury) — 3 definitions

| ID | Name | To discard | Retire bonus | Hidden effect tag |
|----|------|--------------|--------------|-------------------|
| `merchant_contact` | Merchant Contact | 1 Coin, 1 Supply | 0 | Treasury |
| `bard_recruit` | Tavern Bard | 1 Fame, 1 Supply | 0 | Morale |
| `scout_map` | Scout's Map | 1 Coin, 1 Fame | 1 | Risk |

### Tier 2 (cost 2 Treasury) — 3 definitions

| ID | Name | To discard | Retire bonus | Hidden effect tag |
|----|------|--------------|--------------|-------------------|
| `guild_banner` | Guild Banner | 2 Fame, 1 Supply | 0 | Morale |
| `vault_key` | Vault Key | 3 Coin | 1 | Treasury |
| `old_contract` | Old Contract | 2 Coin, 2 Fame | 0 | Risk |

## Hidden retire effects (MVP 1)

Category tag shown on card before retire. Exact effect revealed on first trigger in the run.

| Tag | Effect (on retire) | Design intent |
|-----|-------------------|---------------|
| **Morale** | Morale +2 | Relief |
| **Morale** | Morale −1 | Scrape tax |
| **Treasury** | Treasury +1 | Windfall |
| **Treasury** | Treasury −1 | Hidden cost |
| **Risk** | Morale −2, then draw +1 extra token | High risk scrape |
| **Risk** | 50% Morale −1 / 50% Treasury +2 | Variance |

Each card is assigned one effect from its tag column at data definition time (not random per trigger).

## Guild tracks (MVP 1)

| Track | Start | Lose trigger | Notes |
|-------|-------|--------------|-------|
| Morale | 5 | ≤ 0 = defeat | Spend Supply to recover |
| Treasury | 3 | ≤ 0 = defeat | Earn via spend action or retire effects |

## UI wireframe (MVP 1)

```
┌──────────────────────────────────────────────────────────────┐
│  Turn 3/10          Morale: ██████░░░░  Treasury: ███░░░░░░░ │
├──────────────────────────────────────────────────────────────┤
│  OFFER (pick one)                                            │
│  [ Basic: Supply Crate ] [ Merchant Contact ① ] [ Bard ① ] │
├──────────────────────────────────────────────────────────────┤
│  IN PLAY (retire one)                    Bag: 12  Discard: 8 │
│  [ Scout's Map  Lv1 ] [ Coin Purse ] [ Guild Banner Lv2 ]   │
├──────────────────────────────────────────────────────────────┤
│  DRAWN THIS TURN:  ●Coin ●Coin ●Supply ●Fame                 │
│  SPEND: [Morale +1] [Treasury +1] [Upgrade selected]       │
├──────────────────────────────────────────────────────────────┤
│  JOURNAL: "Old Contract — Risk: Morale −2, draw +1" (new!)   │
├──────────────────────────────────────────────────────────────┤
│                              [ END TURN ]                    │
└──────────────────────────────────────────────────────────────┘
```

Placeholder: colored rectangles + text labels. No illustration required.

## Godot architecture (MVP 1)

### Project structure

```
res://
├── scenes/
│   ├── main.tscn              # Entry point
│   ├── ui/
│   │   ├── game_screen.tscn
│   │   ├── card_view.tscn
│   │   └── journal_panel.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_state.gd      # Turn phase, win/lose
│   │   └── discovery_journal.gd
│   ├── systems/
│   │   ├── bag.gd
│   │   ├── offer_generator.gd
│   │   └── effect_resolver.gd
│   ├── models/
│   │   ├── card_data.gd       # Resource
│   │   └── token_type.gd
│   └── ui/
│       └── game_screen.gd
├── data/
│   └── cards/                 # .tres or .json per card
└── docs/                      # (repo root docs/, linked in README)
```

### Key classes

| Class | Responsibility |
|-------|----------------|
| `GameState` | Phase enum, turn counter, guild tracks, in-play cards |
| `Bag` | Token list, draw, discard, shuffle |
| `CardData` | Resource: id, tier, cost, discard contribution, retire bonus, effect id |
| `EffectResolver` | Map effect id → guild mutations |
| `OfferGenerator` | Build 3-card offer from pools |
| `DiscoveryJournal` | Append-only revealed effect log |

### State machine

```
INIT → [HAND_FULL ? RETIRE : ACQUIRE] → RETIRE → SPEND → END_TURN → (win/lose check) → ...
```

## Acceptance criteria

MVP 1 is **done** when all of the following are true:

- [ ] Godot 4 project runs without errors on desktop
- [ ] Player can complete a full 10-turn run start to finish
- [ ] Bag shuffles discard when empty mid-draw
- [ ] Acquire cost deducts from Treasury; free basics always offered
- [ ] Retire draw uses `2 + level + bonus` correctly
- [ ] At least 6 distinct hidden retire effects work and log to journal on first reveal
- [ ] Spend actions consume correct token types
- [ ] Win (Treasury ≥ 8 at turn 10) and lose (Morale or Treasury at 0) screens appear
- [ ] Card upgrade raises level and increases next retire draw
- [ ] Fame tokens dilute the bag but cannot be spent (intentional friction)
- [ ] No hard-coded card logic in UI scripts — all card data driven from files

## Success metrics (playtest)

After internal playtest (solo, 3+ runs):

1. **Readability:** Player can explain the turn loop without help after turn 2.
2. **Scrape feel:** Player reports feeling token-poor at least 50% of turns.
3. **Tension:** Retire decisions feel meaningful (not obvious auto-picks).
4. **Discovery:** Player is surprised at least once by a hidden retire effect in a run.
5. **Bag math:** Player notices Fame diluting their draws by turn 5–7.

## Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Hidden effects feel unfair | MVP 1 effects are mild (+/−1 or +/−2); tags telegraph category |
| Too few cards → repetitive | 8 cards × offer randomness = enough for 10 turns; expand in MVP 2 |
| Fame feels bad with no use | Journal entry teases "Fame may matter later"; MVP 2 gives Fame spends |
| Hand limit confuses | UI banner when at cap: "Retire first — hall is full" |

## Open questions (resolve before implementation)

| # | Question | Proposed default |
|---|----------|------------------|
| 1 | Data format: `.tres` Resources vs JSON? | **JSON** for faster iteration outside Godot |
| 2 | Unspent tokens: lost or banked? | **Lost** (scrape pressure) |
| 3 | Starting bag contents? | 4 Coin, 4 Supply, 2 Fame (10 total) |
| 4 | Can player skip spend? | **Yes** — confirm with End Turn |
| 5 | Show bag composition to player? | **Counts by type in discard; bag shows total only** |

## Implementation order

1. `Bag` — draw, shuffle, discard (unit-testable)
2. `CardData` + JSON loader — 8 cards
3. `GameState` — phase machine, guild tracks
4. `EffectResolver` — 6 effects
5. `GameScreen` UI — wire phases to buttons
6. Win/lose screens
7. Discovery journal panel
8. Playtest pass and tune numbers

## Estimated content budget

| Asset | Count |
|-------|-------|
| Card definitions | 8 |
| Token types | 3 |
| Retire effects | 6 |
| Scenes | 4–5 |
| Scripts | ~10 |

Placeholder art only. No external assets required.
