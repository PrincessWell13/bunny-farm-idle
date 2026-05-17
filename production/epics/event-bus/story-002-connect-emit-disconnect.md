# Story 002: EventBus Connect-Emit-Disconnect Integration

> **Epic**: EventBus
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: pending — run `/create-control-manifest` to assign

## Context

**GDD**: `design/gdd/bunny-farm-idle-master.md`
**Requirements**: `TR-rabbit-001`, `TR-economy-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-0003: Signal-Based Inter-System Communication via EventBus
**ADR Decision Summary**: All cross-system events use typed callables: `EventBus.signal_name.connect(callable)` in `_ready()`, `EventBus.signal_name.disconnect(callable)` in `_exit_tree()`. Fire-and-forget emit: `EventBus.signal_name.emit(args)`. String-based connect is forbidden. Freed nodes must disconnect to prevent crashes.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Callable-based `connect()` is stable in 4.6. Confirm callable-based signal works correctly with typed parameters in GdUnit4 headless test environment (noted in ADR-0003 Verification Required).

**Control Manifest Rules (Foundation layer)**:
- Required: Connect via callable: `EventBus.rabbit_born.connect(_on_rabbit_born)`
- Required: Disconnect in `_exit_tree()` for any node freed mid-session
- Forbidden: `string_based_signal_connect` — never `connect("signal_name", obj, "method")`
- Forbidden: `upward_direct_method_calls`

---

## Acceptance Criteria

*From ADR-0003 Validation Criteria:*

- [ ] GdUnit4: connect callable to `rabbit_born`, emit with `"test-id"` → callable receives `"test-id"` as `String`
- [ ] GdUnit4: connect callable to `currency_changed`, emit with `(0, 100, 50)` → callable receives `currency=0`, `new_balance=100`, `delta=50` as typed `int` values
- [ ] GdUnit4: connect callable to `production_ticked`, emit with `(5, 2)` → callable receives correct values
- [ ] GdUnit4: a Node connects in `_ready()`, is freed → `_exit_tree()` disconnects → subsequent emit does not crash
- [ ] GdUnit4: multiple callables connected to the same signal all receive the emit
- [ ] No string-based `connect("signal_name", ...)` calls anywhere in `src/` (grep verified in CI)

---

## Implementation Notes

*Derived from ADR-0003 Connect Pattern:*

### Connect pattern (correct)

```gdscript
# In any consumer's _ready():
func _ready() -> void:
    EventBus.rabbit_born.connect(_on_rabbit_born)

func _on_rabbit_born(rabbit_id: String) -> void:
    # handle event
    pass

# In _exit_tree() for nodes freed mid-session:
func _exit_tree() -> void:
    EventBus.rabbit_born.disconnect(_on_rabbit_born)
```

Autoloads and permanent scene roots that live the full session **do not** need to disconnect.

### Emit pattern (correct)

```gdscript
# In any producer, after the action is complete:
EventBus.rabbit_born.emit(child.rabbit_id)
```

### GdUnit4 test structure

```gdscript
# tests/integration/core/event_bus_integration_test.gd
extends GdUnitTestSuite

var _event_bus: Node

func before_test() -> void:
    _event_bus = preload("res://src/core/event_bus.gd").new()
    add_child(_event_bus)

func after_test() -> void:
    _event_bus.queue_free()

func test_rabbit_born_emit_received() -> void:
    var received_id: String = ""
    _event_bus.rabbit_born.connect(func(id: String) -> void: received_id = id)
    _event_bus.rabbit_born.emit("bunny-42")
    assert_str(received_id).is_equal("bunny-42")

func test_currency_changed_typed_params() -> void:
    var received_currency: int = -1
    var received_balance: int = -1
    var received_delta: int = -1
    _event_bus.currency_changed.connect(
        func(c: int, b: int, d: int) -> void:
            received_currency = c
            received_balance = b
            received_delta = d
    )
    _event_bus.currency_changed.emit(0, 100, 50)
    assert_int(received_currency).is_equal(0)
    assert_int(received_balance).is_equal(100)
    assert_int(received_delta).is_equal(50)

func test_disconnect_prevents_crash() -> void:
    var node: Node = Node.new()
    add_child(node)
    var called: bool = false
    _event_bus.rabbit_born.connect(func(_id: String) -> void: called = true)
    # Simulate: node is freed, disconnect called in _exit_tree
    _event_bus.rabbit_born.disconnect(_event_bus.rabbit_born.get_connections()[0]["callable"])
    _event_bus.rabbit_born.emit("test")
    assert_bool(called).is_false()
    node.queue_free()

func test_multiple_listeners_all_receive() -> void:
    var count: int = 0
    _event_bus.save_requested.connect(func() -> void: count += 1)
    _event_bus.save_requested.connect(func() -> void: count += 1)
    _event_bus.save_requested.emit()
    assert_int(count).is_equal(2)
```

---

## Out of Scope

*Handled by other epics:*
- Updating placeholder `int` signal types to proper enum types — each downstream epic handles its own
- Testing that a specific game system (FarmMapUI, HUD) reacts correctly to signals — those are integration tests in their own epics
- Testing `breed_requested` / `breeding_completed` end-to-end — GeneticsSystem epic

---

## QA Test Cases

*Story Type: Integration — automated test specs*

**AC-1**: `rabbit_born` connect/emit
- Given: EventBus instantiated; lambda callable connected to `rabbit_born`
- When: `EventBus.rabbit_born.emit("bunny-42")`
- Then: Lambda receives `"bunny-42"` as `String`
- Edge cases: Emit before connect → callable not called (verify initial state)

**AC-2**: `currency_changed` typed parameters
- Given: EventBus instantiated; callable connected
- When: `EventBus.currency_changed.emit(0, 100, 50)`
- Then: Callable receives `currency=0`, `new_balance=100`, `delta=50` — all `int`
- Edge cases: Negative delta (spend) → `delta = -amount`, `new_balance` correctly reflects post-spend balance

**AC-3**: `production_ticked` multi-param
- Given: EventBus instantiated; callable connected
- When: `EventBus.production_ticked.emit(5, 2)`
- Then: Callable receives `carrot_coin=5`, `star_dust=2`
- Edge cases: Zero earnings tick → `emit(0, 0)` → callable still fires

**AC-4**: disconnect prevents crash on freed node
- Given: Callable connected to `rabbit_born`; then disconnected
- When: `EventBus.rabbit_born.emit("post-disconnect")`
- Then: No crash; callable not invoked
- Edge cases: Disconnect before any emit → no error

**AC-5**: multiple listeners
- Given: Two callables connected to `save_requested`
- When: `EventBus.save_requested.emit()`
- Then: Both callables receive the event (count == 2)
- Edge cases: One callable disconnects mid-session → only remaining callable fires

**AC-6**: no string-based connect in `src/`
- Given: Full `src/` directory
- When: `grep -r 'connect("' src/`
- Then: Zero matches
- Edge cases: Test files in `tests/` are exempt — only `src/` is checked

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/core/event_bus_integration_test.gd` — must exist and pass

```
tests/integration/core/event_bus_integration_test.gd
  test_rabbit_born_emit_received()
  test_currency_changed_typed_params()
  test_production_ticked_multi_param()
  test_disconnect_prevents_crash()
  test_multiple_listeners_all_receive()
  test_no_string_based_connect_in_src() [grep assertion]
```

**Status**: [x] Created — `tests/integration/core/event_bus_integration_test.gd`

---

## Dependencies

- Depends on: **Story 001 must be DONE** — signal declarations must exist before connect/emit tests can run
- Unlocks: All other Foundation epics can now depend on EventBus being tested and working

---

## Completion Notes
**Completed**: 2026-05-16
**Criteria**: 6/6 passing
**Deviations**: ADR-0003 still Proposed (recommend promoting to Accepted); TR registry empty (IDs unverifiable); control manifest missing
**Test Evidence**: Integration: `tests/integration/core/event_bus_integration_test.gd` — 7 test functions
**Code Review**: Skipped — Lean mode
