## ExpeditionPanel — owns all expedition slot UIs and bridges them to the
## expedition signal pipeline (ADR-0011, ADR-0003).
##
## Responsibilities:
##   - Subscribe to EventBus expedition signals and route them to slot UIs.
##   - Restore slot states from GameState at boot via _init_from_game_state().
##   - Forward player COLLECT taps to ExpeditionSystem.collect(slot_id).
##   - Display loot notifications via the parent HUD.
##
## Usage (scene editor):
##   1. Add up to 5 ExpeditionSlotUI nodes as children; assign to slot_uis.
##   2. Assign the HUD node to the hud export.
class_name ExpeditionPanel
extends Control

## Up to 5 expedition slot UI nodes — one per zone. Set in scene editor.
@export var slot_uis: Array[Control] = []

## Reference to HUD for show_notification(). Set in scene editor or found via get_parent().
@export var hud: Control = null

## Map from slot_id -> index in slot_uis array.
var _slot_id_to_index: Dictionary = {}


func _ready() -> void:
	EventBus.expedition_started.connect(_on_expedition_started)
	EventBus.expedition_ready_to_collect.connect(_on_expedition_ready_to_collect)
	EventBus.expedition_collected.connect(_on_expedition_collected)

	for i: int in slot_uis.size():
		var slot_ui: ExpeditionSlotUI = slot_uis[i] as ExpeditionSlotUI
		if slot_ui == null:
			push_warning("ExpeditionPanel: slot_uis[%d] is not an ExpeditionSlotUI — skipping" % i)
			continue
		slot_ui.collect_requested.connect(_on_collect_tapped)

	_init_from_game_state()


func _exit_tree() -> void:
	if EventBus.expedition_started.is_connected(_on_expedition_started):
		EventBus.expedition_started.disconnect(_on_expedition_started)
	if EventBus.expedition_ready_to_collect.is_connected(_on_expedition_ready_to_collect):
		EventBus.expedition_ready_to_collect.disconnect(_on_expedition_ready_to_collect)
	if EventBus.expedition_collected.is_connected(_on_expedition_collected):
		EventBus.expedition_collected.disconnect(_on_expedition_collected)


# ---------------------------------------------------------------------------
# Boot initialisation
# ---------------------------------------------------------------------------

## Reads GameState.active_expeditions once at boot and sets each slot UI to the
## correct initial state. Slots already completed by offline resolve show COLLECT
## immediately (AC-9). Unmatched slot UIs remain EMPTY.
##
## Example:
##   _init_from_game_state()  # called once from _ready()
func _init_from_game_state() -> void:
	var active: Array = GameState.active_expeditions
	var slot_index: int = 0

	for slot: Dictionary in active:
		if slot_index >= slot_uis.size():
			push_warning("ExpeditionPanel: more active expeditions than slot UIs — extras skipped")
			break

		var slot_id: String = str(slot.get("slot_id", ""))
		var status: String = str(slot.get("status", ""))
		if slot_id == "":
			push_warning("ExpeditionPanel._init_from_game_state: slot missing slot_id — skipping")
			slot_index += 1
			continue

		_assign_slot(slot_id, slot_index)

		var slot_ui: ExpeditionSlotUI = slot_uis[slot_index] as ExpeditionSlotUI
		if slot_ui == null:
			slot_index += 1
			continue

		if status == "completed":
			slot_ui.set_collect(slot_id)
		elif status == "in_progress":
			var started_at: float = float(slot.get("started_at", 0.0))
			var duration: float = float(slot.get("duration", 0.0))
			var deadline: float = started_at + duration
			slot_ui.set_countdown(slot_id, deadline)
		else:
			push_warning("ExpeditionPanel._init_from_game_state: unknown status '%s' for slot '%s'" % [status, slot_id])

		slot_index += 1

	# Any remaining slot UIs with no active expedition stay EMPTY (already default).


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Records slot_id -> index mapping so signal handlers can look up the right slot UI.
func _assign_slot(slot_id: String, index: int) -> void:
	_slot_id_to_index[slot_id] = index


## Returns the first slot UI index that is not currently tracked by any slot_id.
## Returns -1 if all slots are occupied.
func _find_empty_slot_index() -> int:
	for i: int in slot_uis.size():
		var occupied: bool = false
		for tracked_index: int in _slot_id_to_index.values():
			if tracked_index == i:
				occupied = true
				break
		if not occupied:
			return i
	return -1


## Builds a human-readable reward string from the rewards dictionary.
##
## Example:
##   _format_rewards({"carrot": 5, "star_dust": 2}) # "carrot × 5, star_dust × 2"
func _format_rewards(rewards: Dictionary) -> String:
	if rewards.is_empty():
		return "Expedition returned!"
	var parts: Array[String] = []
	for item_id: String in rewards:
		parts.append("%s × %d" % [item_id, rewards[item_id]])
	return "Expedition returned: %s" % ", ".join(parts)


## Shows a toast on the parent HUD after a successful collect.
func _show_loot_notification(rewards: Dictionary) -> void:
	if hud == null:
		return
	var hud_node: HUD = hud as HUD
	if hud_node == null:
		return
	hud_node.show_notification(_format_rewards(rewards), 4.0)


# ---------------------------------------------------------------------------
# EventBus signal callbacks (ADR-0003 F-03)
# ---------------------------------------------------------------------------

## Fired by ExpeditionSystem when a new expedition slot begins.
## Finds a free slot UI, assigns it, and starts the countdown.
func _on_expedition_started(slot_id: String, zone_id: String) -> void:
	var index: int = _find_empty_slot_index()
	if index == -1:
		push_warning("ExpeditionPanel: no free slot UI for expedition '%s' (zone '%s')" % [slot_id, zone_id])
		return

	_assign_slot(slot_id, index)

	var slot: Dictionary = ExpeditionSystem.get_slot(slot_id)
	if slot.is_empty():
		push_warning("ExpeditionPanel._on_expedition_started: get_slot('%s') returned empty" % slot_id)
		return

	var deadline: float = float(slot.get("started_at", 0.0)) + float(slot.get("duration", 0.0))

	var slot_ui: ExpeditionSlotUI = slot_uis[index] as ExpeditionSlotUI
	if slot_ui == null:
		return
	slot_ui.set_countdown(slot_id, deadline)


## Fired by ExpeditionSystem when an in-progress slot's deadline has passed.
## Transitions the matching slot UI from COUNTDOWN to COLLECT.
func _on_expedition_ready_to_collect(slot_id: String, _zone_id: String) -> void:
	if not _slot_id_to_index.has(slot_id):
		return
	var index: int = _slot_id_to_index[slot_id]
	var slot_ui: ExpeditionSlotUI = slot_uis[index] as ExpeditionSlotUI
	if slot_ui == null:
		return
	slot_ui.set_collect(slot_id)


## Fired by ExpeditionSystem after collect() succeeds (loot already granted).
## Clears the slot UI and shows a loot notification.
func _on_expedition_collected(slot_id: String, rewards: Dictionary) -> void:
	if not _slot_id_to_index.has(slot_id):
		return
	var index: int = _slot_id_to_index[slot_id]
	var slot_ui: ExpeditionSlotUI = slot_uis[index] as ExpeditionSlotUI
	if slot_ui != null:
		slot_ui.set_empty()
	_slot_id_to_index.erase(slot_id)
	_show_loot_notification(rewards)


# ---------------------------------------------------------------------------
# Slot UI signal callbacks
# ---------------------------------------------------------------------------

## Receives collect_requested from any slot UI and forwards to ExpeditionSystem.
## This is the ONLY call site for ExpeditionSystem.collect — always player-tap-driven.
## ADR-0011 R2: NEVER call collect() from a Timer or _process().
func _on_collect_tapped(slot_id: String) -> void:
	ExpeditionSystem.collect(slot_id)
	# Result arrives via _on_expedition_collected — nothing further to do here.
