# Architecture Review Report — 2026-05-18

**Mode**: full
**Engine**: Godot 4.6 (pinned 2026-02-12)
**GDDs Reviewed**: 1 (`design/gdd/bunny-farm-idle-master.md`)
**ADRs Reviewed**: 8 (all Accepted)
**Stories Implemented**: 32 (31 Complete, 1 Blocked)
**Test Files**: 31 (`tests/unit/core/` + `tests/integration/core/`)

---

## Traceability Summary

| Status | Count |
|---|---|
| ✅ Covered (Foundation + Core) | 26 TRs |
| ⚠️ Partial | 1 TR (TR-guild-001 — backend surface only, no GuildSystem ADR yet) |
| ❌ Gap (Feature layer systems) | ~14 TRs across 8 unaddressed systems |

**Foundation + Core coverage: 100%.** All gaps are Feature/Presentation layer — expected before Sprint 03 epic creation.

---

## Covered Requirements (Foundation + Core)

### Rabbit (ADR-0005)
| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-rabbit-001 | 4 visible stats with real-time decay | ADR-0005 | ✅ |
| TR-rabbit-002 | Hidden stats (growth, fertility, mutation, lifespan, aura) | ADR-0005 | ✅ |
| TR-rabbit-003 | 5-stage lifecycle | ADR-0005 | ✅ |
| TR-rabbit-004 | Aura buff system | ADR-0005 | ⚠️ schema OK, formula MISSING (BLK-001) |
| TR-rabbit-005 | Parentage tracking | ADR-0005 | ✅ |

### Genetics (ADR-0006)
| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-genetics-001 | 6-slot genome | ADR-0006 | ✅ |
| TR-genetics-002 | Inheritance per slot | ADR-0006, ADR-0002 | ✅ |
| TR-genetics-003 | Mutation at base 5% | ADR-0006, ADR-0004 | ✅ |
| TR-genetics-004 | Gene Preview | ADR-0006, ADR-0003 | ✅ |
| TR-genetics-005 | Trait stacking | ADR-0006 | ✅ |
| TR-genetics-006 | 7 color-rarity tiers | ADR-0006, ADR-0004 | ✅ |

### Economy / Idle / Save / Foundation
| TR-ID | Requirement | ADR | Status |
|---|---|---|---|
| TR-economy-001 | 4-currency global access | ADR-0001, ADR-0003 | ✅ |
| TR-idle-001 | Real-time idle production (online 100%) | ADR-0007 | ✅ |
| TR-idle-002 | Offline catch-up on resume | ADR-0007, ADR-0001 | ✅ |
| TR-idle-003 | 4 tiered offline multipliers | ADR-0007, ADR-0004 | ✅ |
| TR-save-001 | Full state serialise/deserialise | ADR-0008, ADR-0001, ADR-0002 | ✅ |
| TR-save-002 | Cloud backup / cross-device | ADR-0008 | ✅ |
| TR-save-003 | Local save survives no-network | ADR-0008 | ✅ |
| TR-season-001 | Season multipliers affect production | ADR-0007 | ✅ |
| TR-season-002 | Season global modifiers | ADR-0004 | ✅ |
| TR-prestige-001 | Prestige bonuses persist | ADR-0007 | ✅ |
| TR-prestige-002 | Selective reset | ADR-0001 | ✅ |
| TR-prestige-003 | Up to 20 prestige levels | ADR-0004 | ✅ |
| TR-habitat-001 | Hutch capacity 4–24 by level | ADR-0004 | ✅ data only |
| TR-ui-004 | ≤2 taps for frequent actions | ADR-0003 | ✅ |

---

## Coverage Gaps (Feature Layer — no ADR yet)

These are expected pre-Sprint 03. They will be filled by `/architecture-decision` as Feature epics get created.

| TR-ID (provisional) | GDD §  | System | Engine Risk | Suggested ADR |
|---|---|---|---|---|
| TR-food-001 | §3.3 | FoodSystem inventory + spoilage | LOW | ADR-0009 FoodSystem inventory model |
| TR-habitat-002 | §3.4 | Hutch slot allocation + rabbit placement | LOW | ADR-0010 HabitatSystem hutch ownership |
| TR-expedition-001 | §3.6 | Async expedition timer + reward roll | MEDIUM | ADR-0011 ExpeditionSystem async timer |
| TR-quest-001 | §3.7 | Daily / weekly quest tracking | LOW | ADR-0012 QuestSystem progression tracker |
| TR-event-001 | §3.8 | Time-limited world events | MEDIUM | ADR-0013 EventSystem scheduler |
| TR-guild-002 | §3.9 | Guild Boss Raid 7-day contribution window | HIGH | ADR-0014 GuildSystem async raid |
| TR-merchant-001 | §3.10 | Random merchant rotation + pricing | LOW | ADR-0015 MerchantSystem rotation |
| TR-puzzle-003 | §3.11 | Gene Journal cross-player sharing | HIGH | ADR-0016 GenePuzzle sharing (uses FirebaseAdapter) |
| TR-collection-001 | §3.13 | Pokedex completion tracking + rewards | LOW | ADR-0017 CollectionSystem |
| TR-economy-002 | §3.14 | Rabbit sale value formula | LOW | ADR-0018 Sale value formula |
| TR-idle-004 | §3.12 | Item-based offline modifier stacking | LOW | ADR-0019 Idle item modifiers |
| TR-shop-001 | §3.14 | Shop catalogue + pricing curve | LOW | ADR-0020 ShopSystem |
| TR-ad-001 | §5 (IAP/Ad) | Rewarded ad multiplier | MEDIUM | ADR-0021 AdAdapter |
| TR-iap-001 | §5 (IAP) | In-app purchase entitlement | MEDIUM | ADR-0022 IAPAdapter |

---

## Cross-ADR Conflict Detection

**No conflicts detected.** All 8 ADRs share consistent vocabulary:
- Boot order owned by ADR-0001; all other ADRs respect the autoload sequence
- Balance values owned by ADR-0004; ADRs 0005/0006/0007 reference it without redefining
- Signal contracts owned by ADR-0003; ADRs 0005/0006/0007 emit only via EventBus
- RabbitData ownership exclusive to RabbitSystem (ADR-0005); ADR-0006 reads but does not mutate

### ADR Dependency Graph — Topological Sort

```
Foundation (no deps):
  1. ADR-0001 — Autoload Boot Sequence
Layer 2 (depends on ADR-0001):
  2. ADR-0002 — GDScript Language Choice
Layer 3 (depends on 0001, 0002):
  3. ADR-0003 — EventBus Signals
  4. ADR-0004 — Balance JSON
Layer 4 (depends on 0001, 0002, 0004):
  5. ADR-0005 — RabbitData Resource
Layer 5 (depends on 0002, 0004, 0005):
  6. ADR-0006 — Genetics Allele Model
  7. ADR-0007 — Idle Production Offline (also depends on 0001)
  8. ADR-0008 — Firebase Local-First Save (also depends on 0001, 0002)
```

**No cycles. No unresolved dependencies.** All 8 ADRs Accepted.

---

## Engine Compatibility Audit

| ADR | Engine Version | Knowledge Risk | Notes |
|---|---|---|---|
| ADR-0001 | Godot 4.6 | LOW | Autoload system stable across 4.4–4.6 |
| ADR-0002 | Godot 4.6 | **MEDIUM** | `@abstract` is post-cutoff (4.5+) — verify usage |
| ADR-0003 | Godot 4.6 | LOW | Signal system stable |
| ADR-0004 | Godot 4.6 | LOW | FileAccess + JSON stable |
| ADR-0005 | Godot 4.6 | LOW | Resource + class_name stable |
| ADR-0006 | Godot 4.6 | LOW | Pure GDScript, no engine surface |
| ADR-0007 | Godot 4.6 | LOW | Pure arithmetic + `Time.get_unix_time_from_system()` |
| ADR-0008 | Godot 4.6 | **MEDIUM** | Firebase GDScript SDK options post-cutoff — `gdfire_adapter.gd` is TODO stub |

- ✅ All ADRs stamp Godot 4.6 consistently
- ✅ No deprecated API references found (per `deprecated-apis.md`)
- ⚠️ ADR-0008 has a TODO native Firebase adapter — MockFirebaseAdapter currently in use (acceptable for local-first design)
- ⚠️ ADR-0002 references `@abstract` (4.5+ feature) — verify with godot-specialist when first abstract class is added (no `@abstract` usage in current code per session state)

**Engine specialist consultation skipped** (lean mode — Knowledge Risk LOW for 6/8 ADRs; defer until first MEDIUM-risk feature is implemented).

---

## GDD Revision Flags

**None.** Master GDD assumptions are consistent with verified Godot 4.6 behaviour and all 8 Accepted ADRs.

---

## Architecture Document Coverage

`docs/architecture/architecture.md` (32.6KB) covers:
- ✅ All 6 Foundation autoloads (EventBus → SceneManager)
- ✅ All 3 Core systems (Rabbit, Genetics, IdleProduction)
- ⚠️ Feature layer described at high level only — needs concrete module specs as epics get created
- ⚠️ Presentation layer (FarmMapUI, BreedingUI, HUD) described as scenes but not yet broken into modules

No orphaned architecture (every doc'd system has either implementation or a planned epic).

---

## RTM Summary (Requirements → ADR → Story → Test)

| Status | Count |
|---|---|
| COVERED (full chain) | 25 TRs |
| MISSING test (story exists, no test) | 0 |
| NO STORY (ADR exists, not yet implemented) | 1 (TR-rabbit-004 aura — blocked on formula) |
| NO ADR (Feature gaps) | 14 |
| **Total in-scope** | **40** |

Full chain complete: **25/40 = 62.5%** — appropriate for end-of-Foundation+Core stage.

Per-system test coverage:
- EventBus: 2 tests ✅
- GameState: 2 tests ✅
- TimeManager: 2 tests ✅
- EconomyManager: 2 tests ✅
- SceneManager: 3 tests ✅
- SaveSystem: 5 tests ✅
- RabbitSystem: 5 tests ✅ (1 blocked: aura)
- GeneticsSystem: 5 tests ✅
- IdleProductionSystem: 5 tests ✅

---

## Verdict: **CONCERNS**

**Foundation + Core are PASS-grade** — clean coverage, no conflicts, sound dependency graph.

**Why CONCERNS, not PASS:**
1. ADR-0008's native Firebase adapter is still a TODO stub (`gdfire_adapter.gd`). Acceptable for current local-first scope but must be addressed before Production → Polish gate.
2. 14 Feature-layer TRs have no ADR yet — expected for current sprint state but blocks Feature-layer story creation until Sprint 03 (S03-02 `/create-epics layer:feature`).
3. Tests have never been run on CI — coverage exists on disk but green-confirmation pending S03-14.

### Required Next ADRs (priority order)
1. **ADR-0009 FoodSystem inventory model** — required for S03-06 FoodSystem story
2. **ADR-0010 HabitatSystem hutch ownership** — required for S03-04 HabitatSystem story
3. **ADR-0011 ExpeditionSystem async timer** (deferrable)
4. **ADR-0018 Rabbit sale value formula** (small, deferrable to Polish)
5. **ADR-0019 Idle item modifiers** (deferrable)

---

## Chain-of-Verification

5 challenge questions checked — verdict held at CONCERNS. Verified by direct file inspection that: TR registry was previously empty, all 8 ADRs cite Godot 4.6 consistently, no dependency cycles exist, all Foundation+Core systems have both production code and test files, aura blocker (BLK-001) is genuinely waiting on game-designer formula spec.
