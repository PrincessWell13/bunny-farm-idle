## BreedingUI — Presentation layer breeding screen.
## Reads state from RabbitSystem and GeneticsSystem (read-only); dispatches
## breed_requested via EventBus. Zero game logic here (ADR-0003).
## Presentation never decides — this file emits one signal and nothing else.
class_name BreedingUI
extends Control

const RARITY_LABELS: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]

## Exported node references — set in the scene editor or injected in tests.
## Story-001: parent selector
@export var rabbit_list_container: Container
@export var preview_panel: Control
@export var breed_button: Button
@export var status_label: Label
@export var preview_rarity_label: Label
@export var preview_mutation_label: Label
@export var preview_colour_label: Label

## Story-002: result reveal panel
@export var reveal_panel: Control
@export var stats_container: Control
@export var color_label: Label
@export var trait_a_label: Label
@export var trait_b_label: Label
@export var rarity_label: Label
@export var close_button: Button

var parent_a_id: String = ""
var parent_b_id: String = ""
var _adult_rabbits: Array[RabbitData] = []
var _entry_buttons: Dictionary = {}  # rabbit_id -> Button
var _reveal_duration: float = 1.5    # loaded from balance.json ui.breed_reveal_duration

func _ready() -> void:
	_load_balance_data()
	breed_button.pressed.connect(_on_breed_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	EventBus.rabbit_born.connect(_on_rabbit_born)
	_hide_reveal_panel()
	_populate_rabbit_list()
	_update_breed_button()
	_hide_preview()

func _exit_tree() -> void:
	if EventBus.rabbit_born.is_connected(_on_rabbit_born):
		EventBus.rabbit_born.disconnect(_on_rabbit_born)

## Clears and rebuilds the rabbit entry list, showing adult rabbits only (AC-1).
func _populate_rabbit_list() -> void:
	_adult_rabbits.clear()
	_entry_buttons.clear()
	for child: Node in rabbit_list_container.get_children():
		child.queue_free()
	var all_rabbits: Array[RabbitData] = RabbitSystem.get_all_rabbits()
	for rabbit: RabbitData in all_rabbits:
		if rabbit.stage != RabbitData.RabbitStage.ADULT:
			continue
		_adult_rabbits.append(rabbit)
		var btn: Button = Button.new()
		btn.text = rabbit.display_name if rabbit.display_name != "" else rabbit.rabbit_id
		btn.custom_minimum_size = Vector2(44, 44)
		btn.pressed.connect(_on_rabbit_entry_tapped.bind(rabbit.rabbit_id))
		rabbit_list_container.add_child(btn)
		_entry_buttons[rabbit.rabbit_id] = btn

## Handles a tap on a rabbit entry (AC-2, AC-8).
## Deselect if already A or B; assign A if empty; assign B if A is set; swap B if both full.
func _on_rabbit_entry_tapped(rabbit_id: String) -> void:
	if rabbit_id == parent_a_id:
		parent_a_id = ""
	elif rabbit_id == parent_b_id:
		parent_b_id = ""
	elif parent_a_id == "":
		parent_a_id = rabbit_id
	elif parent_b_id == "":
		parent_b_id = rabbit_id
	else:
		parent_b_id = rabbit_id
	_update_breed_button()
	_update_preview()

## Enables the breed button only when two distinct adult parents are selected (AC-4).
func _update_breed_button() -> void:
	var can_breed: bool = (
		parent_a_id != "" and
		parent_b_id != "" and
		parent_a_id != parent_b_id
	)
	breed_button.disabled = not can_breed

## Dispatches breed_requested via EventBus — no direct breed() call (AC-5, ADR-0003).
func _on_breed_button_pressed() -> void:
	if parent_a_id == "" or parent_b_id == "" or parent_a_id == parent_b_id:
		return
	EventBus.breed_requested.emit(parent_a_id, parent_b_id)

## Calls get_breed_preview() (pure read) and updates the preview panel labels (AC-3).
func _update_preview() -> void:
	if parent_a_id == "" or parent_b_id == "":
		_hide_preview()
		return
	var rabbit_a: RabbitData = RabbitSystem.get_rabbit(parent_a_id)
	var rabbit_b: RabbitData = RabbitSystem.get_rabbit(parent_b_id)
	if rabbit_a == null or rabbit_b == null:
		_hide_preview()
		return
	var bp: BreedPreview = GeneticsSystem.get_breed_preview(rabbit_a, rabbit_b)
	var rarity_idx: int = clampi(bp.estimated_rarity, 0, RARITY_LABELS.size() - 1)
	preview_rarity_label.text = RARITY_LABELS[rarity_idx]
	preview_mutation_label.text = "%.1f%%" % (bp.mutation_chance * 100.0)
	preview_colour_label.text = _top_key(bp.color_probabilities).capitalize()
	preview_panel.visible = true

func _hide_preview() -> void:
	preview_panel.visible = false

## Returns the key with the highest float value in a probability dictionary.
func _top_key(d: Dictionary) -> String:
	var best_key: String = ""
	var best_val: float = -1.0
	for key: String in d:
		var val: float = d[key] as float
		if val > best_val:
			best_val = val
			best_key = key
	return best_key

# ---------------------------------------------------------------------------
# Story-002: Result Reveal Panel (AC-1 through AC-6)
# ---------------------------------------------------------------------------

## Handles rabbit_born signal — reads child data and triggers reveal (AC-2).
## AC-6: silently skips if child not found (already removed from roster).
func _on_rabbit_born(child_id: String) -> void:
	var child: RabbitData = RabbitSystem.get_rabbit(child_id)
	if child == null:
		return
	_show_reveal_panel(child)

## Fades in the reveal panel then shows populated stats (AC-4).
## Duration is driven by balance.json ui.breed_reveal_duration (AC-4).
func _show_reveal_panel(child: RabbitData) -> void:
	reveal_panel.visible = true
	stats_container.visible = false
	reveal_panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(reveal_panel, "modulate:a", 1.0, _reveal_duration)
	await tween.finished
	_populate_reveal_data(child)
	stats_container.visible = true

## Populates reveal panel labels from child's genome (AC-3).
func _populate_reveal_data(child: RabbitData) -> void:
	color_label.text = child.genome.color.expressed()
	trait_a_label.text = child.genome.trait_a.expressed()
	trait_b_label.text = child.genome.trait_b.expressed()
	var rarity_int: int = int(GeneticsSystem.get_rarity(child))
	rarity_label.text = RARITY_LABELS[clampi(rarity_int, 0, RARITY_LABELS.size() - 1)]

## Hides the reveal panel and resets parent selection (AC-5).
func _on_close_button_pressed() -> void:
	_hide_reveal_panel()
	parent_a_id = ""
	parent_b_id = ""
	_update_breed_button()
	_hide_preview()

func _hide_reveal_panel() -> void:
	reveal_panel.visible = false
	stats_container.visible = false

## Loads ui.breed_reveal_duration from balance.json; falls back to 1.5s (AC-4).
func _load_balance_data() -> void:
	var text: String = FileAccess.get_file_as_string("res://assets/data/balance.json")
	if text.is_empty():
		return
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return
	var ui_section: Dictionary = (parsed as Dictionary).get("ui", {}) as Dictionary
	_reveal_duration = ui_section.get("breed_reveal_duration", _reveal_duration) as float
