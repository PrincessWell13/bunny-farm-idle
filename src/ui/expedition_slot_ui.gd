## ExpeditionSlotUI — manages one expedition slot's three visual states.
## Attach to a Control node that contains empty_container, countdown_container,
## and collect_container as children (set via @export). The collect_button and
## countdown_label also live in those containers.
##
## State transitions are driven by the parent ExpeditionPanel — this node never
## calls ExpeditionSystem directly. Tap-to-collect is forwarded via collect_requested.
##
## Usage:
##   slot_ui.set_empty()
##   slot_ui.set_countdown("exp_0", Time.get_unix_time_from_system() + 300.0)
##   slot_ui.set_collect("exp_0")
class_name ExpeditionSlotUI
extends Control

## Three mutually-exclusive visual states for one expedition slot.
enum SlotState { EMPTY, COUNTDOWN, COLLECT }

## Emitted when the player taps COLLECT. The parent panel is responsible for
## calling ExpeditionSystem.collect(slot_id) — never triggered automatically.
signal collect_requested(slot_id: String)

## Container shown when the slot has no active expedition.
@export var empty_container: Control = null

## Container shown while an expedition is in progress.
@export var countdown_container: Control = null

## Container shown when an expedition is ready to collect.
@export var collect_container: Control = null

## Label inside countdown_container that shows remaining time (MM:SS or HH:MM:SS).
@export var countdown_label: Label = null

## Button inside collect_container. Player tap emits collect_requested.
@export var collect_button: Button = null

var _current_state: SlotState = SlotState.EMPTY
var _slot_id: String = ""
var _deadline: float = 0.0

## Accumulator for throttling label refreshes to ~once per second.
var _tick_accumulator: float = 0.0


func _ready() -> void:
	set_process(false)
	if collect_button != null:
		collect_button.pressed.connect(_on_collect_button_pressed)
	_apply_state()


func _process(delta: float) -> void:
	if _current_state != SlotState.COUNTDOWN:
		set_process(false)
		return

	_tick_accumulator += delta
	if _tick_accumulator < 1.0:
		return
	_tick_accumulator = 0.0

	_refresh_countdown_label()


# ---------------------------------------------------------------------------
# Public state-transition API
# ---------------------------------------------------------------------------

## Transitions this slot to EMPTY state. Clears slot_id and deadline.
##
## Example:
##   slot_ui.set_empty()
func set_empty() -> void:
	_slot_id = ""
	_deadline = 0.0
	_tick_accumulator = 0.0
	_current_state = SlotState.EMPTY
	set_process(false)
	_apply_state()


## Transitions this slot to COUNTDOWN state and begins live decrementing.
## deadline is an absolute Unix timestamp: slot.started_at + slot.duration.
##
## Example:
##   slot_ui.set_countdown("exp_0", Time.get_unix_time_from_system() + 300.0)
func set_countdown(slot_id: String, deadline: float) -> void:
	_slot_id = slot_id
	_deadline = deadline
	_tick_accumulator = 0.0
	_current_state = SlotState.COUNTDOWN
	_refresh_countdown_label()
	_apply_state()
	set_process(true)


## Transitions this slot to COLLECT state. Countdown stops; COLLECT button is shown.
##
## Example:
##   slot_ui.set_collect("exp_0")
func set_collect(slot_id: String) -> void:
	_slot_id = slot_id
	_tick_accumulator = 0.0
	_current_state = SlotState.COLLECT
	set_process(false)
	_apply_state()


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _apply_state() -> void:
	if empty_container != null:
		empty_container.visible = (_current_state == SlotState.EMPTY)
	if countdown_container != null:
		countdown_container.visible = (_current_state == SlotState.COUNTDOWN)
	if collect_container != null:
		collect_container.visible = (_current_state == SlotState.COLLECT)


## Recomputes remaining seconds from _deadline and updates countdown_label.text.
## Clamps to 0 — label never shows negative time.
func _refresh_countdown_label() -> void:
	if countdown_label == null:
		return
	var remaining: float = maxf(_deadline - Time.get_unix_time_from_system(), 0.0)
	countdown_label.text = _format_duration(int(remaining))


## Formats total seconds as HH:MM:SS (hours omitted when < 3600).
##
## Example:
##   _format_duration(90)   # "01:30"
##   _format_duration(3661) # "01:01:01"
func _format_duration(total_seconds: int) -> String:
	var hours: int = total_seconds / 3600
	var minutes: int = (total_seconds % 3600) / 60
	var seconds: int = total_seconds % 60
	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, seconds]
	return "%02d:%02d" % [minutes, seconds]


# ---------------------------------------------------------------------------
# Signal callbacks
# ---------------------------------------------------------------------------

## Forwards the player's COLLECT tap to the parent panel via collect_requested.
## NEVER called from a Timer or _process — ADR-0011 R2.
func _on_collect_button_pressed() -> void:
	if _slot_id == "":
		return
	collect_requested.emit(_slot_id)
