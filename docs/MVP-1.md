# MVP 1 — Core Loop Prototype

## Purpose

MVP 1 validates the **core turn loop** in Godot with the correct conceptual model:

- **Cards = adventurers only**
- **Tokens = action types** (the five attributes)
- **Contracts rotate each turn** and require **tokens + assigned adventurers**
- **Outcomes are partial** — hints on the contract; full matchup results discovered through play

Placeholder art, no meta-progression, minimal content. If assigning the wrong hero to a contract doesn't feel tense by turn 5, fix the loop before expanding content.

## One-sentence goal

> The player starts with 3 basic adventurers, completes a 10-turn run using acquire → retire → contract/actions, and learns at least one hidden matchup the hard way.

## Player experience (MVP 1)

You inherit a guild with three green adventurers. Each turn new heroes appear for hire (basics free, better ones cost guild coin). You retire one veteran to draw action tokens from the bag — Attack, Defense, Magic, Support, Leadership. You spend those tokens and pick who goes on this week's contracts. The crypt contract says it needs Attack and Magic; a note mentions holy specialists. You send the cleric and hope. The fighter sits out — or you risk him and learn why that was a mistake.

## Scope

### In scope

| Area | MVP 1 delivery |
|------|----------------|
| Turn state machine | Acquire → Retire → Act → End Turn |
| Bag builder | Discard pile, bag draw, shuffle-when-empty |
| **Adventurers only** | All cards are heroes; no other card types |
| **Starting roster** | 3 basic adventurers at run start |
| Action tokens | 5 types: Attack, Defense, Magic, Support, Leadership |
| Acquire offer | 3 adventurers per turn: 1 free basic + 2 priced |
| Retire | Draw `2 + level + bonus`; hidden retire guild effect |
| **Contracts board** | 2 contracts refreshed each turn |
| **Guild actions** | 2 fixed actions (Rest, Train) |
| **Act phase** | Pay tokens + assign adventurers; resolve outcomes |
| Partial outcomes | Hints on contracts; hidden matchup table |
| Injury | 2 tiers: Injured, Grave (MVP death = removed from roster) |
| Discovery journal | In-run log of first-time matchup and retire reveals |
| Guild coin | Separate from bag — pays acquire costs only |
| Win / lose | Win after turn 10 with ≥ 2 living adventurers and ≥ 5 guild coin; lose if roster wiped or guild coin ≤ 0 |
| Content | 3 starters + 6 recruitable + 4 contracts + 2 guild actions |
| UI | Single screen: roster, offer, contracts, actions, bag, journal |
| Persistence | None |

### Out of scope (deferred)

- Race (attribute + class only in MVP 1)
- Equipment
- Meta-progression between runs
- Scout / reveal guild action
- More than 2 contract slots or 2 guild actions
- Save/load
- Audio, polished art
- Full five-attribute stat blocks on every hero (starters use simplified display)

## Turn flow (MVP 1 detail)

### Setup

- **Roster:** 3 basic adventurers (see starter table below).
- **Bag:** 2 of each action token (10 total) in the bag at start.
- **Guild coin:** 5 (acquire costs only; not drawn from bag).
- **Contracts:** Draw 2 from contract pool for turn 1.

### Phase 0 — Turn start

- Increment turn counter.
- Refresh **2 contracts** from the pool (can repeat; no duplicate display on board if pool exhausted).
- Generate acquire offer: **1 free basic** + **2 priced** adventurers.

### Phase 1 — Acquire

- Player picks **one** offered adventurer.
- **Cost:** Deduct **guild coin** (visible on card). Basics cost 0.
- **Roster limit:** Max 5 adventurers. If full, **Retire happens before Acquire** this turn.
- **Effect:** Adventurer joins roster; their **bag contribution** (action tokens) added to **discard pile**.

### Phase 2 — Retire

- Player selects **one** roster adventurer to retire.
- **Draw:** `2 + level + retire_bonus` tokens from bag. Shuffle discard into bag if empty mid-draw.
- **Retire effect:** Resolve hidden guild effect; log to journal if new.
- **Remove** adventurer permanently.

> **Cannot retire** the only living adventurer if it would leave 0 (must keep at least 1).

### Phase 3 — Act

Player spends **drawn tokens** (this turn only) on **contracts** and/or **guild actions**. Each activity:

1. Pay listed **action token** costs from drawn pool.
2. Assign **required adventurers** from roster (not injured unless action allows).
3. Resolve — apply visible + hidden outcomes.

- Player may perform **multiple activities** if tokens and adventurers allow.
- **Unspent drawn tokens** are lost at end of turn.
- Same adventurer **cannot** be assigned to two activities in one turn.

#### Contracts (2 per turn)

See contract table below. Each shows:

- Token cost (visible)
- Adventurer count (visible)
- **Hint line** (partial outcome)
- **Risk tag** if injury possible (partial)

#### Guild actions (always available)

| Action | Token cost | Assign | Visible result | Hidden |
|--------|------------|--------|----------------|--------|
| **Rest** | 1 Support | 1 injured adventurer | "Recover from injury" | 70% heal / 30% stay injured |
| **Train** | 1 Leadership | 1 healthy adventurer | "Gain experience" | Level +1, or injured on bad luck |

### Phase 4 — End turn

- Lose if: **guild coin ≤ 0** OR **zero living adventurers**.
- Win if: **turn ≥ 10** AND **≥ 2 living adventurers** AND **guild coin ≥ 5**.
- Clear unspent drawn tokens.
- Injured adventurers stay injured until Rest or contract outcome heals them.

## Action tokens (MVP 1)

Tokens are **not resources**. They are the actions the guild can take this turn.

| Token | Attribute | Used for |
|-------|-----------|----------|
| Attack | Attack | Martial contracts |
| Defense | Defense | Holding / escort contracts |
| Magic | Magic | Arcane or holy contracts |
| Support | Support | Rest, logistics-heavy contracts |
| Leadership | Leadership | Train, coordination contracts |

## Adventurer model (MVP 1)

### Attributes

Each adventurer has values for all five attributes (0–3 in MVP 1). Attributes:

- Are **visible** on the card.
- Determine **which tokens they add to discard** when acquired (see bag contribution).
- Gate **hidden contract matchups** (class + attribute thresholds).

Full race system deferred; **class** is the primary matchup key in MVP 1.

### Starter roster (3 basic adventurers)

| ID | Name | Class | Atk | Def | Mag | Sup | Ldr | Bag contribution | Retire bonus |
|----|------|-------|-----|-----|-----|-----|-----|------------------|--------------|
| `starter_fighter` | Tomás | Fighter | 2 | 1 | 0 | 0 | 0 | 2 Attack | 0 |
| `starter_cleric` | Sister Maren | Cleric | 0 | 1 | 2 | 1 | 0 | 1 Magic, 1 Support | 0 |
| `starter_ranger` | Edda | Ranger | 1 | 1 | 0 | 1 | 1 | 1 Attack, 1 Leadership | 0 |

All starters: level 1, cost 0, retire effect tag **Morale**.

### Recruitable pool (6 adventurers)

| ID | Name | Class | Tier | Cost | Bag contribution | Retire bonus | Tag |
|----|------|-------|------|------|------------------|--------------|-----|
| `recruit_squire` | Young Squire | Fighter | 0 | 0 | 2 Attack | 0 | Morale |
| `recruit_acolyte` | Acolyte | Cleric | 0 | 0 | 1 Magic, 1 Support | 0 | Morale |
| `recruit_bard` | Tavern Bard | Bard | 1 | 2 | 1 Support, 1 Leadership | 0 | Morale |
| `recruit_knight` | Hedge Knight | Fighter | 1 | 3 | 2 Attack, 1 Defense | 1 | Treasury |
| `recruit_mage` | Hedge Mage | Mage | 2 | 4 | 2 Magic | 1 | Risk |
| `recruit_captain` | Retired Captain | Leader | 2 | 5 | 2 Leadership, 1 Defense | 0 | Treasury |

Attribute blocks for recruits defined in data files (not all listed here — implementer fills from class templates).

## Contracts (MVP 1)

Four definitions in pool; 2 shown per turn.

| ID | Name | Token cost | Send | Hint (partial) | Risk tag |
|----|------|------------|------|----------------|----------|
| `contract_undead` | Clear Undead Crypt | 2 Attack, 1 Magic | 1–2 | "Holy specialists thrive against undead" | High |
| `contract_escort` | Escort Merchant | 1 Defense, 1 Leadership | 1–2 | "A steady blade and a calm voice" | Low |
| `contract_bandits` | Drive Off Bandits | 2 Attack | 1–3 | "Sheer force works — but someone may get hurt" | Medium |
| `contract_ritual` | Disrupt Dark Ritual | 2 Magic, 1 Support | 1–2 | "Without support, the party unravels" | Medium |

### Hidden matchup outcomes (MVP 1)

Logged to journal on first trigger.

| Contract | Condition (assigned adventurer) | Outcome |
|----------|----------------------------------|---------|
| **Undead Crypt** | Cleric assigned | +3 guild coin, hint revealed |
| **Undead Crypt** | Fighter assigned (no Cleric) | Fighter → **Grave injury** (death in MVP 1) |
| **Undead Crypt** | Ranger only | +1 guild coin, Ranger injured |
| **Escort Merchant** | Leadership ≥ 1 on any assignee | +2 guild coin |
| **Escort Merchant** | No Defense token spent... | (cost already requires Defense — mismatch if injured Def hero sent) |
| **Bandits** | Attack ≥ 2 on any assignee | +3 guild coin |
| **Bandits** | Any assignee Attack 0 | Assignee injured |
| **Dark Ritual** | Mage or Cleric + Support ≥ 1 | +4 guild coin |
| **Dark Ritual** | No Support in party | All assignees injured |

MVP 1 implements **at least 6 distinct matchup rows** across the four contracts; Undead + Cleric/Fighter is the **tutorial teach moment**.

### Visible vs hidden on contract card UI

```
┌─────────────────────────────────────┐
│  CLEAR UNDEAD CRYPT                 │
│  Cost: ⚔×2  ✦×1                     │
│  Send: 1–2 adventurers              │
│  "Holy specialists thrive..."       │
│  Risk: HIGH                         │
│  Reward: ???                        │  ← hidden until discovered or resolved
└─────────────────────────────────────┘
```

After first Cleric success, journal shows reward tier; contract UI may upgrade to "Reward: Good (discovered)".

## Hidden retire effects (MVP 1)

Tag visible on adventurer card. Six effects in data:

| Tag | Example effect |
|-----|----------------|
| Morale | Next acquire offer includes 1 extra basic |
| Morale | Lose 1 guild coin |
| Treasury | +2 guild coin |
| Treasury | +1 guild coin, next contract Risk +1 display |
| Risk | Draw +1 token, random assignee injured if any contract failed this turn |

## Guild coin (MVP 1)

- **Not** an action token. Simple run track for acquire costs and contract rewards.
- Starting: 5. Win requires ≥ 5. Lose if ≤ 0.
- Keeps acquire economy readable without conflating bag actions with hiring budget.

## Injury (MVP 1)

| State | Effect |
|-------|--------|
| Healthy | Can be assigned |
| Injured | Cannot assign; must Rest or receive heal outcome |
| Grave | Adventurer dies (removed); MVP 1 has no recovery |

## UI wireframe (MVP 1)

```
┌────────────────────────────────────────────────────────────────────┐
│  Turn 4/10    Guild coin: 6    Bag: 8    Discard: 11             │
├────────────────────────────────────────────────────────────────────┤
│  ROSTER                          DRAWN THIS TURN                   │
│  [Tomás Fighter L1 ⚔2]           ⚔ ⚔ ✦ ⊕ ★                        │
│  [Maren Cleric L1]  injured      (Attack Defense Magic Support Lead)│
│  [Edda Ranger L1]                                                │
├────────────────────────────────────────────────────────────────────┤
│  CONTRACTS (pick + assign)         GUILD ACTIONS                   │
│  [Undead Crypt] [Escort]         [Rest] [Train]                    │
├────────────────────────────────────────────────────────────────────┤
│  OFFER (acquire one)                                               │
│  [Squire 0] [Hedge Knight 3] [Bard 2]                              │
├────────────────────────────────────────────────────────────────────┤
│  JOURNAL: "Undead Crypt + Cleric → bonus reward (+3 coin)" NEW    │
├────────────────────────────────────────────────────────────────────┤
│  [ RETIRE... ]                              [ END TURN ]           │
└────────────────────────────────────────────────────────────────────┘
```

Flow note: Retire button opens picker; Act phase uses drag-or-click assign then confirm per contract/action.

## Godot architecture (MVP 1)

### Project structure

```
res://
├── scenes/
│   ├── main.tscn
│   └── ui/
│       ├── game_screen.tscn
│       ├── adventurer_card.tscn
│       ├── contract_card.tscn
│       └── journal_panel.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_state.gd
│   │   └── discovery_journal.gd
│   ├── systems/
│   │   ├── bag.gd
│   │   ├── offer_generator.gd
│   │   ├── contract_board.gd
│   │   ├── matchup_resolver.gd
│   │   └── effect_resolver.gd
│   ├── models/
│   │   ├── adventurer_data.gd
│   │   ├── contract_data.gd
│   │   ├── guild_action_data.gd
│   │   └── action_token.gd
│   └── ui/
│       └── game_screen.gd
├── data/
│   ├── adventurers/
│   ├── contracts/
│   ├── guild_actions/
│   └── matchups/
└── docs/
```

### Key classes

| Class | Responsibility |
|-------|----------------|
| `GameState` | Phase enum, turn counter, roster, guild coin, drawn tokens |
| `Bag` | Action token list, draw, discard-to-bag shuffle |
| `AdventurerData` | Class, attributes, bag contribution, retire fields |
| `ContractBoard` | Refresh 2 contracts per turn |
| `MatchupResolver` | Assigned heroes + contract → outcomes |
| `DiscoveryJournal` | First-time reveal log |

### State machine

```
INIT → [ROSTER_FULL ? RETIRE : ACQUIRE] → RETIRE → ACT → END_TURN → ...
```

## Acceptance criteria

- [ ] Godot 4 project runs on desktop without errors
- [ ] Run starts with exactly 3 basic adventurers
- [ ] All cards are adventurers — no non-hero card type exists
- [ ] Five action token types; no "gold/supply" resource tokens in bag
- [ ] Acquire adds correct tokens to discard; priced hires cost guild coin
- [ ] Retire draws `2 + level + bonus`; shuffle-when-empty works
- [ ] 2 contracts refresh each turn
- [ ] Contract resolution requires token payment + adventurer assignment
- [ ] Undead Crypt: Cleric → bonus coin; Fighter alone → severe outcome (death/injury)
- [ ] Rest and Train guild actions work with token + assign rules
- [ ] Partial hints visible on contracts; full matchup logs to journal once
- [ ] Win and lose screens trigger correctly
- [ ] All content driven from data files

## Success metrics (playtest)

1. Player identifies action tokens as "what I can do" not "currency" by turn 2.
2. Player hesitates before assigning fighter to Undead Crypt after reading hint.
3. At least one "I didn't know that would happen" moment per run from hidden matchup.
4. Retire decision competes with keeping a leveled hero for contracts.

## Open questions (resolve before implementation)

| # | Question | Proposed default |
|---|----------|------------------|
| 1 | Grave injury = death in MVP 1? | **Yes** — simpler; injury tiers expand in MVP 2 |
| 2 | Guild coin name in UI? | **Guild coin** (flavor: paying recruits, contract fees) |
| 3 | Show attribute numbers on card faces? | **Yes** — inputs stay clear |
| 4 | Multiple contracts per turn? | **Yes**, if tokens and heroes allow |
| 5 | Data format | **JSON** |

## Implementation order

1. `Bag` + `ActionToken` enum (five types)
2. `AdventurerData` + starters + recruit pool JSON
3. `GameState` phase machine + roster
4. `ContractBoard` + `MatchupResolver`
5. Acquire + Retire phases
6. Act phase UI (assign + pay)
7. Guild actions Rest / Train
8. Journal + win/lose
9. Playtest Undead Crypt teach moment

## Estimated content budget

| Asset | Count |
|-------|-------|
| Adventurers | 9 (3 starter + 6 recruit) |
| Action token types | 5 |
| Contracts | 4 |
| Guild actions | 2 |
| Matchup rows | 6+ |
| Retire effects | 6 |

Placeholder art only.
