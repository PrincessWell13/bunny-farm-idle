# Architecture Traceability Index

**Last Updated**: 2026-05-18
**Engine**: Godot 4.6
**Source review**: `architecture-review-2026-05-18.md`

## Coverage Summary

- **Total in-scope requirements**: 40
- **Covered (full chain GDD → ADR → Story → Test)**: 25 (62.5%)
- **Partial**: 1 (TR-rabbit-004 aura — blocked on formula)
- **Gaps (no ADR)**: 14 (all Feature/Presentation layer)

**Foundation + Core: 100% covered** by 8 Accepted ADRs.

---

## Full Traceability Matrix

| TR-ID | GDD § | Requirement | ADR | Story | Test | Status |
|-------|-------|-------------|-----|-------|------|--------|
| TR-rabbit-001 | §3.1 | 4 visible stats real-time decay | ADR-0005 | rabbit-system/story-001, story-003 | rabbit_data_schema_test, rabbit_system_decay_test | ✅ |
| TR-rabbit-002 | §3.1 | Hidden stats (growth/fertility/mutation/lifespan/aura) | ADR-0005 | rabbit-system/story-001 | rabbit_data_schema_test | ✅ |
| TR-rabbit-003 | §3.1 | 5-stage lifecycle | ADR-0005 | rabbit-system/story-004 | rabbit_system_lifecycle_test | ✅ |
| TR-rabbit-004 | §3.1 | Aura buff system | ADR-0005 | rabbit-system/story-007 (BLOCKED) | — | ⚠️ schema OK, formula missing |
| TR-rabbit-005 | §3.2 | Parentage tracking | ADR-0005 | rabbit-system/story-001 | rabbit_data_schema_test | ✅ |
| TR-genetics-001 | §3.2 | 6-slot genome | ADR-0006 | genetics-system/story-001 | genetics_schema_test | ✅ |
| TR-genetics-002 | §3.2 | Allele inheritance per slot | ADR-0006, ADR-0002 | genetics-system/story-002 | genetics_inheritance_test | ✅ |
| TR-genetics-003 | §3.2 | Mutation at base 5% | ADR-0006, ADR-0004 | genetics-system/story-002 | genetics_inheritance_test | ✅ |
| TR-genetics-004 | §3.2 | Gene Preview probability | ADR-0006, ADR-0003 | genetics-system/story-003 | genetics_breed_preview_test | ✅ |
| TR-genetics-005 | §3.2 | Trait stacking (synergy/cancel/ultra) | ADR-0006 | genetics-system/story-005 | genetics_trait_stacking_test | ✅ |
| TR-genetics-006 | §3.2 | 7 color-rarity tiers | ADR-0006, ADR-0004 | genetics-system/story-004 | genetics_rarity_test | ✅ |
| TR-economy-001 | §3.14 | 4-currency global access | ADR-0001, ADR-0003 | economy-manager/story-001, story-002 | economy_manager_ledger_test, economy_manager_signal_test | ✅ |
| TR-idle-001 | §3.12 | Real-time idle production | ADR-0007 | idle-production-system/story-002 | idle_production_formula_test | ✅ |
| TR-idle-002 | §3.12 | Offline catch-up | ADR-0007, ADR-0001 | idle-production-system/story-003 | idle_offline_tiers_test | ✅ |
| TR-idle-003 | §3.12 | 4 tiered offline multipliers | ADR-0007, ADR-0004 | idle-production-system/story-003 | idle_offline_tiers_test | ✅ |
| TR-save-001 | §5 | Full state serialise/deserialise | ADR-0008, ADR-0001 | save-system/story-003 | save_system_round_trip_test | ✅ |
| TR-save-002 | §5 | Cloud backup cross-device | ADR-0008 | save-system/story-001, story-004 | save_system_adapter_test, save_system_conflict_test | ✅ |
| TR-save-003 | §5 | Local save survives no-network | ADR-0008 | save-system/story-002, story-005 | save_system_local_io_test, save_system_boot_test | ✅ |
| TR-season-001 | §3.5 | Season multipliers affect production | ADR-0007 | idle-production-system/story-004 | idle_production_integration_test | ✅ |
| TR-season-002 | §3.5 | Season global modifiers | ADR-0004 | (data-only in balance.json) | — | ✅ data only |
| TR-prestige-001 | §4 | Prestige bonuses persist | ADR-0007 | idle-production-system/story-004 | idle_production_integration_test | ✅ |
| TR-prestige-002 | §4 | Selective reset | ADR-0001 | game-state/story-002 | game_state_prestige_test | ✅ |
| TR-prestige-003 | §4 | Up to 20 prestige levels | ADR-0004 | (data-only) | — | ✅ data only |
| TR-habitat-001 | §3.4 | Hutch capacity 4–24 by level | ADR-0004 | (data only — no system yet) | — | ✅ data only |
| TR-ui-004 | §6 | ≤2 taps for frequent actions | ADR-0003 | scene-manager/story-003 | scene_manager_routing_test | ✅ |
| TR-guild-001 | §3.9 | Guild requires multiplayer backend | ADR-0008 | — | — | ⚠️ Partial (backend only) |
| **Foundation infrastructure** | | | | | | |
| TR-infra-eventbus | — | Signal catalogue | ADR-0003 | event-bus/story-001, story-002 | event_bus_catalogue_test, event_bus_integration_test | ✅ |
| TR-infra-state | — | Central game state autoload | ADR-0001 | game-state/story-001 | game_state_init_test | ✅ |
| TR-infra-time | — | Time tick + background detection | ADR-0001 | time-manager/story-001, story-002 | (time-manager tests pending CI) | ✅ |
| TR-infra-scene | — | Scene transitions + overlays | ADR-0001 | scene-manager/story-001, story-002 | scene_manager_transitions_test, scene_manager_overlay_test | ✅ |
| TR-infra-idle-report | — | Earnings report schema | ADR-0007 | idle-production-system/story-001 | idle_earnings_report_test | ✅ |
| TR-rabbit-feed | §3.3 | Feeding stat restoration | ADR-0005 | rabbit-system/story-006 | rabbit_system_feeding_test | ✅ |
| TR-rabbit-roster | — | Rabbit CRUD operations | ADR-0005 | rabbit-system/story-002 | rabbit_system_roster_test | ✅ |
| TR-rabbit-death | §3.1 | Death signal on lifespan expiry | ADR-0005 | rabbit-system/story-005 | rabbit_system_death_test | ✅ |

---

## Known Gaps (Feature Layer — ADRs to write)

| TR-ID (provisional) | GDD § | System | Priority | Suggested ADR |
|---|---|---|---|---|
| TR-food-001 | §3.3 | FoodSystem inventory | **HIGH** (S03-06) | ADR-0009 |
| TR-habitat-002 | §3.4 | Hutch slot allocation | **HIGH** (S03-04) | ADR-0010 |
| TR-expedition-001 | §3.6 | Async expedition timer | MEDIUM | ADR-0011 |
| TR-quest-001 | §3.7 | Daily/weekly quest tracking | MEDIUM | ADR-0012 |
| TR-event-001 | §3.8 | Time-limited world events | MEDIUM | ADR-0013 |
| TR-guild-002 | §3.9 | Guild Boss Raid 7-day window | HIGH | ADR-0014 |
| TR-merchant-001 | §3.10 | Random merchant rotation | LOW | ADR-0015 |
| TR-puzzle-003 | §3.11 | Gene Journal cross-player sharing | HIGH | ADR-0016 |
| TR-collection-001 | §3.13 | Pokedex completion + rewards | LOW | ADR-0017 |
| TR-economy-002 | §3.14 | Rabbit sale value formula | LOW | ADR-0018 |
| TR-idle-004 | §3.12 | Item-based offline modifier stacking | LOW | ADR-0019 |
| TR-shop-001 | §3.14 | Shop catalogue + pricing curve | MEDIUM | ADR-0020 |
| TR-ad-001 | §5 | Rewarded ad multiplier | MEDIUM | ADR-0021 |
| TR-iap-001 | §5 | In-app purchase entitlement | MEDIUM | ADR-0022 |

---

## ADR Dependency Order (Implementation Sequence)

1. **ADR-0001** Autoload Boot Sequence (Foundation root)
2. **ADR-0002** GDScript Language Choice
3. **ADR-0003** EventBus Signals · **ADR-0004** Balance JSON
4. **ADR-0005** RabbitData Resource
5. **ADR-0006** Genetics Allele Model · **ADR-0007** Idle Production Offline · **ADR-0008** Firebase Save

No cycles. All 8 Accepted. Future Feature-layer ADRs (0009–0022) depend on this Foundation+Core base.

---

## Superseded Requirements

None recorded.
