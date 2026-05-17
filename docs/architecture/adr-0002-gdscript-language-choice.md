# ADR-0002: GDScript as the Sole Implementation Language

## Status
Proposed

## Date
2026-05-16

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Scripting |
| **Knowledge Risk** | MEDIUM — GDScript gained new features in 4.5 that are post-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`, `docs/engine-reference/godot/breaking-changes.md`, `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | `@abstract` decorator (4.5), variadic args `Variant...` (4.5) — both are opt-in additions, not breaking changes |
| **Verification Required** | Confirm GdUnit4 test runner works with `godot --headless --script` before committing to test framework |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 (boot sequence defines file paths as `.gd` — consistent with this decision) |
| **Enables** | All implementation epics — language choice must be settled before any code is written |
| **Blocks** | All implementation epics until Accepted |
| **Ordering Note** | Must be Accepted before ADR-0005 (RabbitData) and ADR-0006 (Genetics), which define class signatures |

## Context

### Problem Statement
Godot 4.6 supports both GDScript and C# (.NET) as first-class scripting languages. Both are fully viable for a mobile idle game of this scope. The choice affects daily iteration speed, export binary size, test tooling, CI setup, and maintainability. This decision must be explicit and recorded so that all contributors use the same language uniformly — mixed-language codebases in Godot require careful boundary management and add build complexity.

### Constraints
- Solo developer — compilation step latency directly impacts iteration speed
- Target platforms: Android and iOS primary. C# exports require bundling the .NET runtime, increasing APK/IPA size by ~20–30MB
- GdUnit4 (the chosen test framework) supports both languages; no constraint from test tooling
- The GDD's performance requirements (60fps desktop, 30fps mobile stable) are achievable in either language for an idle game

### Requirements
- Must enable fast iteration: change a formula, run the game, see the result without a build step
- Must produce small export binaries (mobile users are sensitive to download size)
- Must support the unit testing requirement (80% coverage for genetics formulas)
- Must be maintainable by a solo developer over a multi-month project

## Decision

**GDScript is the sole scripting language for this project.** No C# files will be added to the project. GDExtension (C/C++/Rust) may be introduced in a future ADR only if a specific performance bottleneck is profiled and confirmed to require native-speed code — not speculatively.

All `.gd` files use static typing everywhere. Untyped variables are only permitted in throwaway prototype scripts in `prototypes/` that will not be merged to main.

### Post-Cutoff GDScript Features in Use

Two 4.5+ features are explicitly approved for use in this project:

**1. `@abstract` — for base resource classes**
```gdscript
@abstract
class_name BaseHabitatBonus extends Resource

@abstract
func apply(rabbit: RabbitData) -> void:
    pass  # Subclasses MUST override
```
Use for: `BaseHabitatBonus`, `BaseFoodEffect`, `BaseExpeditionZone` — any resource that defines a contract but must never be instantiated directly.

**2. Variadic args — for debug/logging utilities only**
```gdscript
func log_event(category: String, values: Variant...) -> void:
    for v in values:
        print("[", category, "] ", v)
```
Do NOT use variadic args in game logic interfaces — they bypass static type checking. Permitted only in debug/logging utilities.

### Static Typing Rules

| Context | Rule |
|---------|------|
| All function parameters | Must be typed: `func feed(rabbit_id: String, food: FoodItem) → bool` |
| All return types | Must be typed or `→ void` |
| All class variables | Must be typed: `var hunger: float = 100.0` |
| Loop variables | Must be typed: `for rabbit: RabbitData in rabbits` |
| Dictionaries with mixed types | Use `Dictionary` annotation + comment describing the shape |
| Untyped | Only in `prototypes/` — never in `src/` |

### File Naming
- Game logic files: `snake_case.gd` (e.g., `rabbit_system.gd`, `genetics_system.gd`)
- Scene files: `PascalCase.tscn` matching class name (e.g., `RabbitCard.tscn`)

## Alternatives Considered

### Alternative B: C# (.NET)
- **Description**: All game logic written in C#. Full .NET ecosystem, strong IDE support (Rider, VS Code with Omnisharp).
- **Pros**: Compile-time type safety; richer standard library; marginally faster CPU-heavy loops; familiar to Unity developers.
- **Cons**: +20–30MB to APK/IPA from .NET runtime. 2–5 second compilation delay on every change. C# Godot bindings occasionally lag behind GDScript for new engine features.
- **Rejection Reason**: For an idle game, the GDScript/C# performance delta is imperceptible to players. The compilation overhead and export size increase are real daily costs with no meaningful payoff at this game's scale.

### Alternative C: Mixed — GDScript for gameplay, C# for math-heavy systems
- **Description**: Genetics formula engine and idle production math in C# for performance; UI and gameplay in GDScript.
- **Pros**: Performance where it matters most; iteration speed where it matters most.
- **Cons**: Cross-language boundaries require Variant marshalling overhead that can negate the C# speed benefit for small per-frame calculations. Two test frameworks. Higher cognitive load.
- **Rejection Reason**: Profile first, optimise second. The genetics formula runs at breed time (user-triggered, not per-frame). The idle math runs once per second. Neither is a hot path requiring native performance.

## Consequences

### Positive
- No compilation step — edit a formula, see results immediately
- Smaller Android APK and iOS IPA (no .NET runtime)
- New Godot engine features available in GDScript first
- Single test framework (GdUnit4) for all code
- `@abstract` (4.5) enables clean base class contracts

### Negative
- GDScript's type system is advisory — some type errors only surface at runtime even with annotations
- No LINQ, generics, or operator overloading — some patterns require more verbose GDScript equivalents
- If the genetics simulation ever becomes a bottleneck for bulk operations, the upgrade path is GDExtension (not C#)

### Risks
- **Risk**: GDScript performance becomes a bottleneck for bulk offline production calculation across many hutches.
  - **Mitigation**: `IdleProductionSystem.calculate_offline_earnings()` is a pure function with no I/O. Profile during Alpha. If it exceeds 10ms, rewrite in GDExtension — not C#.
- **Risk**: A contributor adds a `.cs` file inadvertently.
  - **Mitigation**: Add `*.cs` to `.gitignore` as a guardrail. This ADR is the explicit record.

## GDD Requirements Addressed

| GDD Requirement ID | Requirement | How This ADR Addresses It |
|--------------------|-------------|--------------------------|
| TR-genetics-002 | Breeding computation: allele selection per slot | GDScript with static typing is sufficient for per-breed computation (not per-frame). `@abstract` enables clean `BreedingStrategy` base class. |
| TR-idle-003 | Tiered offline multiplier calculation | Pure GDScript function — no I/O, runs once on resume. Deterministic and unit-testable via GdUnit4. |
| TR-save-001 | Full state serialisation | GDScript `JSON` class handles serialisation. `Dictionary` + `Array[RabbitData]` → JSON is idiomatic GDScript. |

## Performance Implications
- **CPU**: Negligible vs C# for idle game logic. Genetics formula: <1ms per breed. Idle math: <2ms per offline catch-up. Both well under frame budget.
- **Memory**: Marginally larger GDScript object footprint than C# structs — immaterial for max 24 active rabbits.
- **Load Time**: No .NET runtime initialisation — faster cold-start on mobile.
- **Network**: No impact.

## Migration Plan
Greenfield project — no migration required. Add `*.cs` to `.gitignore` from day one.

## Validation Criteria
- [ ] All `.gd` files in `src/` show zero untyped variable warnings in Godot editor
- [ ] GdUnit4 test runner executes without errors: `godot --headless --script tests/gdunit4_runner.gd`
- [ ] No `.cs` files present in `src/` at any point in git history
- [ ] Genetics formula unit tests run in <100ms total (GdUnit4 benchmark)

## Related Decisions
- ADR-0001: Boot sequence uses `.gd` file paths — consistent with this decision
- ADR-0005 (pending): RabbitData as Resource — class signature uses GDScript static typing and `@abstract`
- ADR-0006 (pending): Genetics algorithm — formula implementation is pure typed GDScript
- `.claude/docs/technical-preferences.md` — informal "ADR-001: GDScript over C#" superseded by this ADR
