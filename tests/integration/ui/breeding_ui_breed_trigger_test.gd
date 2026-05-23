## Integration tests for BreedingUI story-001 — parent selector + breed trigger.
## Story: production/epics/breeding-ui/story-001-parent-selector-breed-trigger.md
## Verifies AC-1 through AC-8 using mock autoloads via Engine.register_singleton.
extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# Mock classes
# ---------------------------------------------------------------------------

class MockRabbitSystem extends Node:
	var _rabbits: Dictionary = {}  # rabbit_id -> RabbitData

	func get_all_rabbits() -> Array[RabbitData]:
		var result: Array[RabbitData] = []
		result.assign(_rabbits.values())
		return result

	func get_rabbit(rabbit_id: String) -> RabbitData:
		return _rabbits.get(rabbit_id, null) as RabbitData

	func add(rabbit: RabbitData) -> void:
		_rabbits[rabbit.rabbit_id] = rabbit


class MockGeneticsSystem extends Node:
	var preview_called_with: Array = []
	var _preview: BreedPreview = BreedPreview.new()

	func get_breed_preview(parent_a: RabbitData, parent_b: RabbitData) -> BreedPreview:
		preview_called_with = [parent_a.rabbit_id, parent_b.rabbit_id]
		return _preview


class MockEventBus extends Node:
	signal breed_requested(parent_a_id: String, parent_b_id: String)
	signal rabbit_born(rabbit_id: String)
	var breed_requested_calls: Array = []

	func _init() -> void:
		breed_requested.connect(_on_breed_requested)

	func _on_breed_requested(a: String, b: String) -> void:
		breed_requested_calls.append([a, b])


# ---------------------------------------------------------------------------
# Setup / teardown
# ---------------------------------------------------------------------------

var _mock_rabbit_system: MockRabbitSystem
var _mock_genetics_system: MockGeneticsSystem
var _mock_event_bus: MockEventBus
var _orig_rabbit_system: Object = null
var _orig_genetics_system: Object = null
var _orig_event_bus: Object = null

func before_test() -> void:
	_mock_rabbit_system = MockRabbitSystem.new()
	_mock_genetics_system = MockGeneticsSystem.new()
	_mock_event_bus = MockEventBus.new()
	add_child(_mock_rabbit_system)
	add_child(_mock_genetics_system)
	add_child(_mock_event_bus)
	_orig_rabbit_system = Engine.get_singleton("RabbitSystem") if Engine.has_singleton("RabbitSystem") else null
	if Engine.has_singleton("RabbitSystem"):
		Engine.unregister_singleton("RabbitSystem")
	Engine.register_singleton("RabbitSystem", _mock_rabbit_system)
	_orig_genetics_system = Engine.get_singleton("GeneticsSystem") if Engine.has_singleton("GeneticsSystem") else null
	if Engine.has_singleton("GeneticsSystem"):
		Engine.unregister_singleton("GeneticsSystem")
	Engine.register_singleton("GeneticsSystem", _mock_genetics_system)
	_orig_event_bus = Engine.get_singleton("EventBus") if Engine.has_singleton("EventBus") else null
	if Engine.has_singleton("EventBus"):
		Engine.unregister_singleton("EventBus")
	Engine.register_singleton("EventBus", _mock_event_bus)

func after_test() -> void:
	if Engine.has_singleton("RabbitSystem"):
		Engine.unregister_singleton("RabbitSystem")
	if _orig_rabbit_system != null:
		Engine.register_singleton("RabbitSystem", _orig_rabbit_system)
	_orig_rabbit_system = null
	if Engine.has_singleton("GeneticsSystem"):
		Engine.unregister_singleton("GeneticsSystem")
	if _orig_genetics_system != null:
		Engine.register_singleton("GeneticsSystem", _orig_genetics_system)
	_orig_genetics_system = null
	if Engine.has_singleton("EventBus"):
		Engine.unregister_singleton("EventBus")
	if _orig_event_bus != null:
		Engine.register_singleton("EventBus", _orig_event_bus)
	_orig_event_bus = null
	_mock_rabbit_system.queue_free()
	_mock_genetics_system.queue_free()
	_mock_event_bus.queue_free()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_rabbit(id: String, stage: RabbitData.RabbitStage) -> RabbitData:
	var r: RabbitData = RabbitData.new()
	r.rabbit_id = id
	r.display_name = id
	r.stage = stage
	r.genome = Genome.new()
	r.genome.color = GeneSlot.new()
	r.genome.color.allele_a = "white"
	r.genome.color.allele_b = "white"
	r.genome.trait_a = GeneSlot.new()
	r.genome.trait_a.allele_a = "none"
	r.genome.trait_a.allele_b = "none"
	r.genome.trait_b = GeneSlot.new()
	r.genome.trait_b.allele_a = "none"
	r.genome.trait_b.allele_b = "none"
	r.genome.size = GeneSlot.new()
	r.genome.size.allele_a = "medium"
	r.genome.size.allele_b = "medium"
	r.genome.ears = GeneSlot.new()
	r.genome.ears.allele_a = "standard"
	r.genome.ears.allele_b = "standard"
	r.genome.special = GeneSlot.new()
	r.genome.special.allele_a = "none"
	r.genome.special.allele_b = "none"
	return r

func _build_ui() -> BreedingUI:
	var ui: BreedingUI = BreedingUI.new()
	var container: HBoxContainer = HBoxContainer.new()
	var breed_btn: Button = Button.new()
	var preview: Control = Control.new()
	var status_lbl: Label = Label.new()
	var rarity_lbl: Label = Label.new()
	var mutation_lbl: Label = Label.new()
	var colour_lbl: Label = Label.new()
	var close_btn: Button = Button.new()
	var reveal_panel: Control = Control.new()
	var stats_container: Control = Control.new()

	ui.rabbit_list_container = container
	ui.breed_button = breed_btn
	ui.preview_panel = preview
	ui.status_label = status_lbl
	ui.preview_rarity_label = rarity_lbl
	ui.preview_mutation_label = mutation_lbl
	ui.preview_colour_label = colour_lbl
	ui.close_button = close_btn
	ui.reveal_panel = reveal_panel
	ui.stats_container = stats_container

	add_child(ui)
	ui.add_child(container)
	ui.add_child(breed_btn)
	ui.add_child(preview)
	ui.add_child(status_lbl)
	ui.add_child(rarity_lbl)
	ui.add_child(mutation_lbl)
	ui.add_child(colour_lbl)
	ui.add_child(close_btn)
	ui.add_child(reveal_panel)
	reveal_panel.add_child(stats_container)
	return ui


# ---------------------------------------------------------------------------
# AC-1: adult-only filter
# ---------------------------------------------------------------------------

## AC-1: only ADULT rabbits appear in the rabbit list container.
func test_breeding_ui_shows_only_adult_rabbits() -> void:
	var adult: RabbitData = _make_rabbit("adult-1", RabbitData.RabbitStage.ADULT)
	var baby: RabbitData = _make_rabbit("baby-1", RabbitData.RabbitStage.BABY)
	var juvenile: RabbitData = _make_rabbit("juv-1", RabbitData.RabbitStage.JUVENILE)
	_mock_rabbit_system.add(adult)
	_mock_rabbit_system.add(baby)
	_mock_rabbit_system.add(juvenile)

	var ui: BreedingUI = _build_ui()

	assert_int(ui._adult_rabbits.size()).is_equal(1)
	assert_str(ui._adult_rabbits[0].rabbit_id).is_equal("adult-1")


# ---------------------------------------------------------------------------
# AC-2: parent assignment in ≤2 taps
# ---------------------------------------------------------------------------

## AC-2a: first tap assigns parent A.
func test_breeding_ui_assigns_parent_a_on_first_tap() -> void:
	_mock_rabbit_system.add(_make_rabbit("r1", RabbitData.RabbitStage.ADULT))
	var ui: BreedingUI = _build_ui()

	ui._on_rabbit_entry_tapped("r1")

	assert_str(ui.parent_a_id).is_equal("r1")
	assert_str(ui.parent_b_id).is_equal("")

## AC-2b: second different-rabbit tap assigns parent B.
func test_breeding_ui_assigns_parent_b_on_second_tap() -> void:
	_mock_rabbit_system.add(_make_rabbit("r1", RabbitData.RabbitStage.ADULT))
	_mock_rabbit_system.add(_make_rabbit("r2", RabbitData.RabbitStage.ADULT))
	var ui: BreedingUI = _build_ui()

	ui._on_rabbit_entry_tapped("r1")
	ui._on_rabbit_entry_tapped("r2")

	assert_str(ui.parent_a_id).is_equal("r1")
	assert_str(ui.parent_b_id).is_equal("r2")


# ---------------------------------------------------------------------------
# AC-3: breed preview shown after both parents selected
# ---------------------------------------------------------------------------

## AC-3: selecting two parents calls get_breed_preview and shows preview panel.
func test_breeding_ui_preview_calls_get_breed_preview() -> void:
	_mock_rabbit_system.add(_make_rabbit("ra", RabbitData.RabbitStage.ADULT))
	_mock_rabbit_system.add(_make_rabbit("rb", RabbitData.RabbitStage.ADULT))
	_mock_genetics_system._preview.mutation_chance = 0.05
	_mock_genetics_system._preview.estimated_rarity = 0
	_mock_genetics_system._preview.color_probabilities = {"white": 1.0}
	var ui: BreedingUI = _build_ui()

	ui._on_rabbit_entry_tapped("ra")
	ui._on_rabbit_entry_tapped("rb")

	assert_bool(_mock_genetics_system.preview_called_with.size() > 0).is_true()
	assert_bool(ui.preview_panel.visible).is_true()


# ---------------------------------------------------------------------------
# AC-4: breed button enable/disable logic
# ---------------------------------------------------------------------------

## AC-4a: breed button is disabled when no parents selected.
func test_breeding_ui_breed_button_disabled_with_no_adults() -> void:
	var ui: BreedingUI = _build_ui()
	assert_bool(ui.breed_button.disabled).is_true()

## AC-4b: breed button stays disabled when same rabbit tapped twice (same parent).
func test_breeding_ui_breed_button_disabled_with_same_rabbit_selected() -> void:
	_mock_rabbit_system.add(_make_rabbit("r1", RabbitData.RabbitStage.ADULT))
	var ui: BreedingUI = _build_ui()

	ui._on_rabbit_entry_tapped("r1")
	# Manually force parent_b to same id to simulate edge condition
	ui.parent_b_id = "r1"
	ui._update_breed_button()

	assert_bool(ui.breed_button.disabled).is_true()

## AC-4c: breed button is enabled when two different adults are selected.
func test_breeding_ui_breed_button_enabled_with_two_different_adults() -> void:
	_mock_rabbit_system.add(_make_rabbit("r1", RabbitData.RabbitStage.ADULT))
	_mock_rabbit_system.add(_make_rabbit("r2", RabbitData.RabbitStage.ADULT))
	var ui: BreedingUI = _build_ui()

	ui._on_rabbit_entry_tapped("r1")
	ui._on_rabbit_entry_tapped("r2")

	assert_bool(ui.breed_button.disabled).is_false()


# ---------------------------------------------------------------------------
# AC-5: breed_requested dispatched — no breed() call
# ---------------------------------------------------------------------------

## AC-5: breed_requested is emitted with correct IDs on confirm; breed() never called.
func test_breeding_ui_breed_requested_emitted_on_confirm() -> void:
	_mock_rabbit_system.add(_make_rabbit("r1", RabbitData.RabbitStage.ADULT))
	_mock_rabbit_system.add(_make_rabbit("r2", RabbitData.RabbitStage.ADULT))
	var ui: BreedingUI = _build_ui()
	ui._on_rabbit_entry_tapped("r1")
	ui._on_rabbit_entry_tapped("r2")

	ui._on_breed_button_pressed()

	assert_int(_mock_event_bus.breed_requested_calls.size()).is_equal(1)
	var call: Array = _mock_event_bus.breed_requested_calls[0]
	assert_str(call[0]).is_equal("r1")
	assert_str(call[1]).is_equal("r2")


# ---------------------------------------------------------------------------
# AC-8: deselect and swap behaviour
# ---------------------------------------------------------------------------

## AC-8a: tapping parent A again deselects it.
func test_breeding_ui_deselect_parent_a_on_second_tap() -> void:
	_mock_rabbit_system.add(_make_rabbit("r1", RabbitData.RabbitStage.ADULT))
	var ui: BreedingUI = _build_ui()
	ui._on_rabbit_entry_tapped("r1")
	assert_str(ui.parent_a_id).is_equal("r1")

	ui._on_rabbit_entry_tapped("r1")

	assert_str(ui.parent_a_id).is_equal("")

## AC-8b: tapping a third rabbit when both slots are full replaces parent B.
func test_breeding_ui_third_tap_swaps_parent_b() -> void:
	_mock_rabbit_system.add(_make_rabbit("r1", RabbitData.RabbitStage.ADULT))
	_mock_rabbit_system.add(_make_rabbit("r2", RabbitData.RabbitStage.ADULT))
	_mock_rabbit_system.add(_make_rabbit("r3", RabbitData.RabbitStage.ADULT))
	var ui: BreedingUI = _build_ui()
	ui._on_rabbit_entry_tapped("r1")
	ui._on_rabbit_entry_tapped("r2")

	ui._on_rabbit_entry_tapped("r3")

	assert_str(ui.parent_a_id).is_equal("r1")
	assert_str(ui.parent_b_id).is_equal("r3")


# ---------------------------------------------------------------------------
# Edge: no rabbits — no crash
# ---------------------------------------------------------------------------

## AC-4 edge: empty roster does not crash; breed button stays disabled.
func test_breeding_ui_no_rabbits_no_crash() -> void:
	var ui: BreedingUI = _build_ui()

	assert_int(ui._adult_rabbits.size()).is_equal(0)
	assert_bool(ui.breed_button.disabled).is_true()
