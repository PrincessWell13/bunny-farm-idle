# Story 007: Aura Bonus — get_aura_bonus(hutch_id)

> **Epic**: RabbitSystem
> **Status**: Blocked
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md` (§3.1 — "Aura thỏ đặc biệt tỏa aura buff cho thỏ xung quanh")
**Requirement**: `TR-rabbit-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**BLOCKED — Two blockers**:
1. ADR-0005 is Proposed — promote to Accepted
2. Aura stacking formula has no ADR or Quick Spec — `aura_type` keys map to numeric bonuses but the stacking/resolution math is unspecified. Run `/quick-design aura-bonus-formula` or `/architecture-decision` to define it before implementing.

**ADR Governing Implementation**: ADR-0005 (RabbitData `aura_type` field + RabbitSystem mutation contract)
**ADR Decision Summary (partial)**: `aura_type: String` on RabbitData is the data-level aura identifier. Elder rabbits have Aura effect ×2 (GDD §3.1). The formula mapping `aura_type` → numeric bonus and the stacking rules for multiple Elder/Sanctuary rabbits in the same hutch are not yet specified.

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules (Core layer)**:
- Forbidden: `upward_direct_method_calls` — `get_aura_bonus` must not call Feature or Presentation code
- Required: AuraBonus returned as a typed value — not a raw Dictionary

---

## Acceptance Criteria

*Pending formula spec — these ACs are draft only and will be revised when the aura ADR/Quick Spec is written.*

- [ ] `get_aura_bonus(hutch_id: String) -> AuraBonus` exists in `rabbit_system.gd`
- [ ] Returns an `AuraBonus` typed struct (Resource or inner class) with at minimum: `production_multiplier: float`, `growth_multiplier: float`
- [ ] For each ELDER rabbit in the hutch with non-empty `aura_type`: adds the aura bonus ×2 (Elder modifier per GDD)
- [ ] For each SANCTUARY rabbit in the hutch: adds aura bonus at base rate (GDD: Sanctuary = passive farm buff)
- [ ] Aura stacking formula: **[TO BE SPECIFIED]** — multiplicative, additive, or capped additive
- [ ] Returns `AuraBonus` with all multipliers == 1.0 (no bonus) when no aura rabbits present
- [ ] `aura_type` values map to numeric bonuses from balance.json or a Quick Spec table

---

## Implementation Notes

*Skeletal only — flesh out after aura formula is specified.*

```gdscript
class AuraBonus:
    var production_multiplier: float = 1.0
    var growth_multiplier: float = 1.0
    var happiness_bonus: float = 0.0

func get_aura_bonus(hutch_id: String) -> AuraBonus:
    var bonus := AuraBonus.new()
    var hutch_rabbits: Array[RabbitData] = get_rabbits_in_hutch(hutch_id)
    for rabbit: RabbitData in hutch_rabbits:
        if rabbit.aura_type.is_empty():
            continue
        var aura_mult: float = 1.0
        if rabbit.stage == RabbitData.RabbitStage.ELDER:
            aura_mult = 2.0  # GDD: Elder Aura effect ×2
        # [TODO: resolve aura_type → bonus values from spec]
        # bonus.production_multiplier += _resolve_aura(rabbit.aura_type) * aura_mult
    return bonus
```

The `_resolve_aura(aura_type)` function and stacking math are placeholders. They must be filled in once the formula spec is written.

---

## Out of Scope

- Feature layer: applying the AuraBonus return value to idle production calculations — that is IdleProductionSystem scope
- Story 004: ELDER stage transition that enables the aura effect

---

## QA Test Cases

*Draft only — will be revised when aura formula is specified.*

- **AC-1**: no aura rabbits → AuraBonus multipliers == 1.0
  - Given: hutch with 2 ADULT rabbits with empty `aura_type`
  - When: `get_aura_bonus("hutch-id")`
  - Then: `bonus.production_multiplier == 1.0`, `bonus.growth_multiplier == 1.0`

- **AC-2**: ELDER rabbit with aura_type → bonus applied at ×2
  - Given: hutch with 1 ELDER rabbit with `aura_type="golden"` (sample value)
  - When: `get_aura_bonus("hutch-id")`
  - Then: returned bonus reflects aura effect ×2 (exact value pending formula spec)

- **AC-3**: empty hutch → returns default AuraBonus (no crash)
  - Given: hutch_id with no rabbits
  - When: `get_aura_bonus("empty-hutch")`
  - Then: `bonus.production_multiplier == 1.0`; no error

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/core/rabbit_system_aura_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: **Story 002 must be DONE** (`get_rabbits_in_hutch` required)
- Unblock path: promote ADR-0005, then write aura formula spec via `/quick-design aura-bonus-formula`
- Unlocks: IdleProductionSystem epic (aura bonuses feed into production calculations)
