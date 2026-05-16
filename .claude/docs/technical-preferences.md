# Technical Preferences — Bunny Farm Idle

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: Godot 2D (CanvasItem renderer), pixel art mode enabled
- **Physics**: Godot 2D physics (CharacterBody2D for interactive elements)

## Input & Platform

- **Target Platforms**: Android (primary), iOS (primary), PC (port post-launch)
- **Input Methods**: Touch (primary), Mouse (PC fallback)
- **Primary Input**: Touch — single finger, one-hand friendly
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: All UI must be reachable by thumb in bottom half of screen. Min touch target 44×44px.

## Naming Conventions

- **Classes**: PascalCase (e.g. `RabbitData`, `GeneticsSystem`)
- **Variables**: snake_case (e.g. `hunger_level`, `growth_rate`)
- **Signals/Events**: snake_case past tense (e.g. `rabbit_fed`, `breeding_completed`)
- **Files**: snake_case (e.g. `rabbit_data.gd`, `genetics_system.gd`)
- **Scenes**: PascalCase matching class (e.g. `RabbitCard.tscn`, `BreedingUI.tscn`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g. `MAX_HUNGER`, `BASE_MUTATION_CHANCE`)

## Performance Budgets

- **Target Framerate**: 60 FPS (desktop), 30 FPS stable (mobile)
- **Frame Budget**: 16.6ms (60fps) / 33ms (30fps)
- **Draw Calls**: < 50 per frame (use CanvasGroup and atlases)
- **Memory Ceiling**: 256MB RAM on mobile
- **Sprite Atlas**: All rabbit sprites in single atlas texture
- **Rabbit cap per scene**: Max 24 visible rabbits at once (Cosmic hutch max)

## Testing

- **Framework**: GdUnit4 (Godot native)
- **Minimum Coverage**: 80% for genetics formulas, 60% for economy systems
- **Required Tests**: Genetics inheritance formulas, economy balance, idle production math, offline calculation

## Forbidden Patterns

- No hardcoded balance values — all in `assets/data/balance.json`
- No direct node path references across scenes (`$../..`) — use signals or autoloads
- No blocking I/O on main thread — use ResourceLoader async for large assets
- No singletons for game state — use GameState autoload with explicit save/load

## Allowed Libraries / Addons

- GdUnit4 — testing framework
- No third-party addons without technical-director approval

## Architecture Decisions Log

- ADR-001: GDScript over C# — faster iteration, no compilation step, sufficient performance for idle game
- ADR-002: JSON config files for all balance data — enables live tuning without recompile
- ADR-003: Autoload pattern for global systems (GameState, TimeManager, EventBus)
- ADR-004: Signal-based inter-system communication — loose coupling, testable

## Engine Specialists

- **Primary**: godot-specialist
- **Language/Code Specialist**: gdscript-specialist
- **Shader Specialist**: godot-shader-specialist
- **UI Specialist**: godot-ui-specialist
- **Routing Notes**: All .gd files → gdscript-specialist; .tscn UI → godot-ui-specialist; shaders → godot-shader-specialist

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| `.gd` (game logic) | gdscript-specialist |
| `.gdshader` / `.tres` material | godot-shader-specialist |
| `.tscn` UI screens | godot-ui-specialist |
| `.tscn` gameplay scenes | gdscript-specialist |
| Architecture review | godot-specialist (primary) |
