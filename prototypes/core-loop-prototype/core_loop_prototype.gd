## CoreLoopPrototype — Wires Foundation systems into a playable core loop.
## Builds ALL UI programmatically. No save system — all state is in memory.
## Prototype scope: 2 hutches, 3 rabbits, idle production, feeding, breeding.
class_name CoreLoopPrototype extends Node2D

# ---------------------------------------------------------------------------
# Art Bible palette constants
# ---------------------------------------------------------------------------
const COLOR_PARCHMENT := Color(0.98, 0.98, 0.96)   # #FAFAF5 — background
const COLOR_HEARTHSTONE := Color(0.96, 0.90, 0.83)  # #F5E6D3 — card background
const COLOR_WORN_OAK := Color(0.55, 0.42, 0.29)     # #8B6B4A — borders, text
const COLOR_CARROT := Color(1.00, 0.55, 0.26)       # #FF8C42 — primary CTAs
const COLOR_LAVENDER := Color(0.61, 0.45, 0.81)     # #9B72CF — breeding accent
const COLOR_MEADOW := Color(0.72, 0.89, 0.72)       # #B8E4B8 — hutch panel

const SCREEN_W: float = 1080.0
const SCREEN_H: float = 1920.0
const HEADER_H: float = 100.0
const TABBAR_H: float = 100.0
const CONTENT_Y: float = HEADER_H
const CONTENT_H: float = SCREEN_H - HEADER_H - TABBAR_H

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _pending_coins: int = 0
var _rabbit_ids: Array[String] = []

# Breeding selection
var _parent_a_id: String = ""
var _parent_b_id: String = ""
var _picking_slot: int = 0  # 1 = picking A, 2 = picking B

# Rabbit card modal
var _card_rabbit_id: String = ""

# ---------------------------------------------------------------------------
# Node references (set during _build_ui)
# ---------------------------------------------------------------------------
var _coin_label: Label = null
var _collect_btn: Button = null
var _farm_view: Control = null
var _breeding_view: Control = null

# Hutch rabbit button containers
var _hutch1_container: VBoxContainer = null
var _hutch2_container: VBoxContainer = null

# Rabbit card modal
var _rabbit_card: Panel = null
var _card_name_label: Label = null
var _card_stats_label: Label = null
var _card_feed_btn: Button = null

# Breeding view nodes
var _parent_a_panel: Panel = null
var _parent_a_label: Label = null
var _parent_b_panel: Panel = null
var _parent_b_label: Label = null
var _breed_btn: Button = null
var _result_panel: Panel = null
var _result_label: Label = null
var _rabbit_picker: Panel = null
var _picker_list: VBoxContainer = null
var _breed_error_label: Label = null


# ---------------------------------------------------------------------------
# _ready
# ---------------------------------------------------------------------------
func _ready() -> void:
	_seed_starter_rabbits()
	_build_ui()
	_refresh_hutch_buttons()
	EventBus.currency_changed.connect(_on_currency_changed)


# ---------------------------------------------------------------------------
# Starter rabbit seeding
# ---------------------------------------------------------------------------
func _seed_starter_rabbits() -> void:
	var baby := RabbitData.new()
	baby.display_name = "Cottontail"
	baby.stage = RabbitData.RabbitStage.BABY
	baby.hunger = 80.0
	baby.genome = _make_genome("white", "floppy", "fast_eater")
	_rabbit_ids.append(RabbitSystem.add_rabbit(baby))

	var adult := RabbitData.new()
	adult.display_name = "Hazel"
	adult.stage = RabbitData.RabbitStage.ADULT
	adult.hunger = 70.0
	adult.genome = _make_genome("brown", "upright", "lucky")
	adult.birth_timestamp = int(Time.get_unix_time_from_system()) - 3600
	_rabbit_ids.append(RabbitSystem.add_rabbit(adult))

	var elder := RabbitData.new()
	elder.display_name = "Sage"
	elder.stage = RabbitData.RabbitStage.ELDER
	elder.hunger = 60.0
	elder.genome = _make_genome("grey", "stubby", "calm")
	elder.birth_timestamp = int(Time.get_unix_time_from_system()) - 86400
	_rabbit_ids.append(RabbitSystem.add_rabbit(elder))


## Builds a homozygous genome with one expressed trait.
func _make_genome(color: String, ears: String, p_trait: String) -> Genome:
	var genome := Genome.new()
	genome.color.allele_a = color
	genome.color.allele_b = color
	genome.size.allele_a = "medium"
	genome.size.allele_b = "medium"
	genome.ears.allele_a = ears
	genome.ears.allele_b = ears
	genome.trait_a.allele_a = p_trait
	genome.trait_a.allele_b = "none"
	genome.trait_b.allele_a = "none"
	genome.trait_b.allele_b = "none"
	genome.special.allele_a = "none"
	genome.special.allele_b = "none"
	return genome


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------
func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = COLOR_PARCHMENT
	bg.size = Vector2(SCREEN_W, SCREEN_H)
	add_child(bg)

	# HUD CanvasLayer (always on top)
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 5
	add_child(hud_layer)
	_build_hud(hud_layer)

	# Farm view
	_farm_view = Control.new()
	_place(_farm_view, 0.0, CONTENT_Y, SCREEN_W, CONTENT_H)
	add_child(_farm_view)
	_build_farm_view(_farm_view)

	# Breeding view (hidden by default)
	_breeding_view = Control.new()
	_place(_breeding_view, 0.0, CONTENT_Y, SCREEN_W, CONTENT_H)
	_breeding_view.visible = false
	add_child(_breeding_view)
	_build_breeding_view(_breeding_view)


func _build_hud(layer: CanvasLayer) -> void:
	# Header panel
	var header := _make_panel(COLOR_PARCHMENT)
	_place(header, 0.0, 0.0, SCREEN_W, HEADER_H)
	layer.add_child(header)

	_coin_label = Label.new()
	_coin_label.text = "Coins: 0"
	_coin_label.add_theme_color_override("font_color", COLOR_WORN_OAK)
	_coin_label.add_theme_font_size_override("font_size", 40)
	_place(_coin_label, 20.0, 20.0, 600.0, 60.0)
	header.add_child(_coin_label)

	# Tab bar panel
	var tabbar := _make_panel(COLOR_WORN_OAK)
	_place(tabbar, 0.0, SCREEN_H - TABBAR_H, SCREEN_W, TABBAR_H)
	layer.add_child(tabbar)

	var farm_tab := _make_button("FARM", COLOR_MEADOW)
	_place(farm_tab, 10.0, 10.0, (SCREEN_W / 2.0) - 15.0, TABBAR_H - 20.0)
	farm_tab.add_theme_color_override("font_color", COLOR_WORN_OAK)
	farm_tab.add_theme_font_size_override("font_size", 36)
	farm_tab.pressed.connect(_on_farm_tab_pressed)
	tabbar.add_child(farm_tab)

	var breed_tab := _make_button("BREEDING", COLOR_LAVENDER)
	_place(breed_tab, (SCREEN_W / 2.0) + 5.0, 10.0, (SCREEN_W / 2.0) - 15.0, TABBAR_H - 20.0)
	breed_tab.add_theme_font_size_override("font_size", 36)
	breed_tab.pressed.connect(_on_breeding_tab_pressed)
	tabbar.add_child(breed_tab)


func _build_farm_view(parent: Control) -> void:
	var title := Label.new()
	title.text = "FARM"
	title.add_theme_color_override("font_color", COLOR_WORN_OAK)
	title.add_theme_font_size_override("font_size", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(title, 0.0, 20.0, SCREEN_W, 70.0)
	parent.add_child(title)

	# Hutch 1 (rabbits 0 and 1)
	var hutch1 := _make_panel(COLOR_MEADOW)
	_place(hutch1, 40.0, 110.0, SCREEN_W - 80.0, 460.0)
	parent.add_child(hutch1)

	var hutch1_title := Label.new()
	hutch1_title.text = "Hutch 1"
	hutch1_title.add_theme_color_override("font_color", COLOR_WORN_OAK)
	hutch1_title.add_theme_font_size_override("font_size", 36)
	_place(hutch1_title, 20.0, 10.0, 400.0, 50.0)
	hutch1.add_child(hutch1_title)

	_hutch1_container = VBoxContainer.new()
	_place(_hutch1_container, 20.0, 70.0, SCREEN_W - 120.0, 360.0)
	_hutch1_container.add_theme_constant_override("separation", 10)
	hutch1.add_child(_hutch1_container)

	# Hutch 2 (rabbit 2)
	var hutch2 := _make_panel(COLOR_MEADOW)
	_place(hutch2, 40.0, 610.0, SCREEN_W - 80.0, 360.0)
	parent.add_child(hutch2)

	var hutch2_title := Label.new()
	hutch2_title.text = "Hutch 2"
	hutch2_title.add_theme_color_override("font_color", COLOR_WORN_OAK)
	hutch2_title.add_theme_font_size_override("font_size", 36)
	_place(hutch2_title, 20.0, 10.0, 400.0, 50.0)
	hutch2.add_child(hutch2_title)

	_hutch2_container = VBoxContainer.new()
	_place(_hutch2_container, 20.0, 70.0, SCREEN_W - 120.0, 260.0)
	_hutch2_container.add_theme_constant_override("separation", 10)
	hutch2.add_child(_hutch2_container)

	# Idle earnings hint — always visible so players understand the loop
	var earn_hint := Label.new()
	earn_hint.text = "Rabbits earn coins automatically every second."
	earn_hint.add_theme_color_override("font_color", COLOR_WORN_OAK)
	earn_hint.add_theme_font_size_override("font_size", 28)
	earn_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	earn_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(earn_hint, 40.0, 985.0, SCREEN_W - 80.0, 60.0)
	parent.add_child(earn_hint)

	# Collect button — always visible; disabled (grey) when no coins are ready
	_collect_btn = _make_button("Waiting for coins…", COLOR_WORN_OAK)
	_place(_collect_btn, 100.0, 1055.0, SCREEN_W - 200.0, 110.0)
	_collect_btn.add_theme_font_size_override("font_size", 36)
	_collect_btn.disabled = true
	_collect_btn.pressed.connect(_on_collect_pressed)
	parent.add_child(_collect_btn)

	# Rabbit card modal (full-screen overlay, hidden by default)
	_rabbit_card = _make_panel(COLOR_HEARTHSTONE)
	_place(_rabbit_card, 80.0, 400.0, SCREEN_W - 160.0, 800.0)
	_rabbit_card.visible = false
	_rabbit_card.z_index = 10
	parent.add_child(_rabbit_card)

	_card_name_label = Label.new()
	_card_name_label.add_theme_color_override("font_color", COLOR_WORN_OAK)
	_card_name_label.add_theme_font_size_override("font_size", 44)
	_card_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(_card_name_label, 20.0, 30.0, SCREEN_W - 240.0, 80.0)
	_rabbit_card.add_child(_card_name_label)

	_card_stats_label = Label.new()
	_card_stats_label.add_theme_color_override("font_color", COLOR_WORN_OAK)
	_card_stats_label.add_theme_font_size_override("font_size", 36)
	_card_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(_card_stats_label, 30.0, 140.0, SCREEN_W - 260.0, 300.0)
	_rabbit_card.add_child(_card_stats_label)

	_card_feed_btn = _make_button("Feed (Grass)", COLOR_CARROT)
	_card_feed_btn.add_theme_font_size_override("font_size", 38)
	_place(_card_feed_btn, 30.0, 500.0, SCREEN_W - 340.0, 100.0)
	_card_feed_btn.pressed.connect(_on_feed_pressed)
	_rabbit_card.add_child(_card_feed_btn)

	var close_btn := _make_button("X", COLOR_WORN_OAK)
	close_btn.add_theme_font_size_override("font_size", 38)
	_place(close_btn, SCREEN_W - 340.0, 20.0, 100.0, 100.0)
	close_btn.pressed.connect(_on_card_close_pressed)
	_rabbit_card.add_child(close_btn)

	# Idle production timer
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_production_tick)
	add_child(timer)


func _build_breeding_view(parent: Control) -> void:
	var title := Label.new()
	title.text = "BREEDING"
	title.add_theme_color_override("font_color", COLOR_WORN_OAK)
	title.add_theme_font_size_override("font_size", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(title, 0.0, 20.0, SCREEN_W, 70.0)
	parent.add_child(title)

	# Parent A panel (left)
	_parent_a_panel = _make_panel(COLOR_HEARTHSTONE)
	_place(_parent_a_panel, 30.0, 120.0, 480.0, 320.0)
	parent.add_child(_parent_a_panel)

	var pa_header := Label.new()
	pa_header.text = "Parent A"
	pa_header.add_theme_color_override("font_color", COLOR_WORN_OAK)
	pa_header.add_theme_font_size_override("font_size", 32)
	pa_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(pa_header, 10.0, 10.0, 460.0, 50.0)
	_parent_a_panel.add_child(pa_header)

	_parent_a_label = Label.new()
	_parent_a_label.text = "Tap to select\nParent A"
	_parent_a_label.add_theme_color_override("font_color", COLOR_WORN_OAK)
	_parent_a_label.add_theme_font_size_override("font_size", 30)
	_parent_a_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_parent_a_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(_parent_a_label, 10.0, 70.0, 460.0, 160.0)
	_parent_a_panel.add_child(_parent_a_label)

	var pick_a_btn := _make_button("Select", COLOR_LAVENDER)
	pick_a_btn.add_theme_font_size_override("font_size", 30)
	_place(pick_a_btn, 90.0, 250.0, 300.0, 60.0)
	pick_a_btn.pressed.connect(_on_pick_parent_a_pressed)
	_parent_a_panel.add_child(pick_a_btn)

	# Parent B panel (right)
	_parent_b_panel = _make_panel(COLOR_HEARTHSTONE)
	_place(_parent_b_panel, 570.0, 120.0, 480.0, 320.0)
	parent.add_child(_parent_b_panel)

	var pb_header := Label.new()
	pb_header.text = "Parent B"
	pb_header.add_theme_color_override("font_color", COLOR_WORN_OAK)
	pb_header.add_theme_font_size_override("font_size", 32)
	pb_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(pb_header, 10.0, 10.0, 460.0, 50.0)
	_parent_b_panel.add_child(pb_header)

	_parent_b_label = Label.new()
	_parent_b_label.text = "Tap to select\nParent B"
	_parent_b_label.add_theme_color_override("font_color", COLOR_WORN_OAK)
	_parent_b_label.add_theme_font_size_override("font_size", 30)
	_parent_b_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_parent_b_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(_parent_b_label, 10.0, 70.0, 460.0, 160.0)
	_parent_b_panel.add_child(_parent_b_label)

	var pick_b_btn := _make_button("Select", COLOR_LAVENDER)
	pick_b_btn.add_theme_font_size_override("font_size", 30)
	_place(pick_b_btn, 90.0, 250.0, 300.0, 60.0)
	pick_b_btn.pressed.connect(_on_pick_parent_b_pressed)
	_parent_b_panel.add_child(pick_b_btn)

	# Error label (duplicate parent warning)
	_breed_error_label = Label.new()
	_breed_error_label.text = ""
	_breed_error_label.add_theme_color_override("font_color", Color(0.9, 0.1, 0.1))
	_breed_error_label.add_theme_font_size_override("font_size", 30)
	_breed_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_breed_error_label, 0.0, 460.0, SCREEN_W, 50.0)
	parent.add_child(_breed_error_label)

	# Breed button
	_breed_btn = _make_button("BREED", COLOR_CARROT)
	_breed_btn.add_theme_font_size_override("font_size", 44)
	_breed_btn.disabled = true
	_place(_breed_btn, 290.0, 530.0, 500.0, 110.0)
	_breed_btn.pressed.connect(_on_breed_pressed)
	parent.add_child(_breed_btn)

	# Result panel (hidden until after breeding)
	_result_panel = _make_panel(COLOR_HEARTHSTONE)
	_place(_result_panel, 80.0, 680.0, SCREEN_W - 160.0, 320.0)
	_result_panel.visible = false
	parent.add_child(_result_panel)

	var result_header := Label.new()
	result_header.text = "Offspring Result"
	result_header.add_theme_color_override("font_color", COLOR_WORN_OAK)
	result_header.add_theme_font_size_override("font_size", 38)
	result_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(result_header, 10.0, 20.0, SCREEN_W - 180.0, 60.0)
	_result_panel.add_child(result_header)

	_result_label = Label.new()
	_result_label.text = ""
	_result_label.add_theme_color_override("font_color", COLOR_WORN_OAK)
	_result_label.add_theme_font_size_override("font_size", 34)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(_result_label, 20.0, 100.0, SCREEN_W - 200.0, 200.0)
	_result_panel.add_child(_result_label)

	# Rabbit picker modal (full-screen overlay, hidden by default)
	_rabbit_picker = _make_panel(COLOR_PARCHMENT)
	_place(_rabbit_picker, 60.0, 200.0, SCREEN_W - 120.0, CONTENT_H - 300.0)
	_rabbit_picker.visible = false
	_rabbit_picker.z_index = 10
	parent.add_child(_rabbit_picker)

	var picker_title := Label.new()
	picker_title.text = "Select a Rabbit"
	picker_title.add_theme_color_override("font_color", COLOR_WORN_OAK)
	picker_title.add_theme_font_size_override("font_size", 40)
	picker_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(picker_title, 10.0, 15.0, SCREEN_W - 200.0, 60.0)
	_rabbit_picker.add_child(picker_title)

	var picker_close := _make_button("X", COLOR_WORN_OAK)
	picker_close.add_theme_font_size_override("font_size", 36)
	_place(picker_close, SCREEN_W - 250.0, 10.0, 120.0, 80.0)
	picker_close.pressed.connect(_on_picker_close_pressed)
	_rabbit_picker.add_child(picker_close)

	var scroll := ScrollContainer.new()
	_place(scroll, 20.0, 90.0, SCREEN_W - 200.0, CONTENT_H - 420.0)
	_rabbit_picker.add_child(scroll)

	_picker_list = VBoxContainer.new()
	_picker_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_picker_list.add_theme_constant_override("separation", 12)
	scroll.add_child(_picker_list)


# ---------------------------------------------------------------------------
# Hutch button refresh — rebuilds rabbit buttons from current roster
# ---------------------------------------------------------------------------
func _refresh_hutch_buttons() -> void:
	_clear_children(_hutch1_container)
	_clear_children(_hutch2_container)

	var all_rabbits: Array[RabbitData] = RabbitSystem.get_all_rabbits()
	# Limit display: hutch 1 = first 2, hutch 2 = third
	var slot: int = 0
	for rabbit: RabbitData in all_rabbits:
		var container: VBoxContainer = _hutch1_container if slot < 2 else _hutch2_container
		if slot >= 3:
			break
		var btn := _make_rabbit_button(rabbit)
		container.add_child(btn)
		slot += 1


func _make_rabbit_button(rabbit: RabbitData) -> Button:
	var stage_name: String = _stage_label(rabbit.stage)
	var color_str: String = rabbit.genome.color.expressed() if rabbit.genome != null else "?"
	var hunger_warn: String = "" if rabbit.hunger >= 30.0 else "⚠ "
	var label_text: String = "%s [%s] — %sHunger: %d" % [
		rabbit.display_name, stage_name, hunger_warn, int(rabbit.hunger)
	]
	var btn := _make_button(label_text, COLOR_HEARTHSTONE)
	btn.add_theme_color_override("font_color", COLOR_WORN_OAK)
	btn.add_theme_font_size_override("font_size", 28)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0.0, 80.0)
	# Capture the rabbit_id in a closure via a bound callable
	btn.pressed.connect(_on_rabbit_btn_pressed.bind(rabbit.rabbit_id))
	return btn


# ---------------------------------------------------------------------------
# Signal callbacks
# ---------------------------------------------------------------------------
func _on_currency_changed(currency: int, new_balance: int, _delta: int) -> void:
	if currency == EconomyManager.CurrencyType.CARROT_COIN:
		_coin_label.text = "Coins: %d" % new_balance


func _on_production_tick() -> void:
	var report: EarningsReport = IdleProductionSystem.get_tick_earnings()
	_pending_coins += report.carrot_coin
	if _pending_coins > 0:
		_collect_btn.text = "TAP TO COLLECT  +%d coins" % _pending_coins
		_collect_btn.disabled = false
		# Swap button style to carrot orange so it draws the eye
		var style := StyleBoxFlat.new()
		style.bg_color = COLOR_CARROT
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		_collect_btn.add_theme_stylebox_override("normal", style)
		_collect_btn.add_theme_stylebox_override("hover", style)
		_collect_btn.add_theme_stylebox_override("pressed", style)


func _on_collect_pressed() -> void:
	EconomyManager.add(EconomyManager.CurrencyType.CARROT_COIN, _pending_coins)
	_pending_coins = 0
	_collect_btn.text = "Waiting for coins…"
	_collect_btn.disabled = true
	# Reset to grey style
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_WORN_OAK
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_collect_btn.add_theme_stylebox_override("normal", style)
	_collect_btn.add_theme_stylebox_override("hover", style)
	_collect_btn.add_theme_stylebox_override("pressed", style)


func _on_farm_tab_pressed() -> void:
	_farm_view.visible = true
	_breeding_view.visible = false


func _on_breeding_tab_pressed() -> void:
	_farm_view.visible = false
	_breeding_view.visible = true


func _on_rabbit_btn_pressed(rabbit_id: String) -> void:
	_card_rabbit_id = rabbit_id
	_refresh_rabbit_card()
	_rabbit_card.visible = true


func _refresh_rabbit_card() -> void:
	var rabbit: RabbitData = RabbitSystem.get_rabbit(_card_rabbit_id)
	if rabbit == null:
		_rabbit_card.visible = false
		return

	_card_name_label.text = "%s  [%s]" % [rabbit.display_name, _stage_label(rabbit.stage)]

	var hunger_prefix: String = "⚠ " if rabbit.hunger < 30.0 else ""
	var stats: String = "Hunger: %s%d/100\nHealth: %d/100\nHappiness: %d/100" % [
		hunger_prefix, int(rabbit.hunger), int(rabbit.health), int(rabbit.happiness)
	]
	if rabbit.genome != null:
		var color_val: String = rabbit.genome.color.expressed()
		var ears_val: String = rabbit.genome.ears.expressed()
		var trait_val: String = rabbit.genome.trait_a.expressed()
		stats += "\nColor: %s  Ears: %s\nTrait: %s" % [color_val, ears_val, trait_val]
	_card_stats_label.text = stats


func _on_feed_pressed() -> void:
	if _card_rabbit_id.is_empty():
		return
	var food := RabbitSystem.FoodItem.new("grass")
	RabbitSystem.feed_rabbit(_card_rabbit_id, food)
	_refresh_rabbit_card()
	_refresh_hutch_buttons()


func _on_card_close_pressed() -> void:
	_rabbit_card.visible = false
	_card_rabbit_id = ""


# ---------------------------------------------------------------------------
# Breeding callbacks
# ---------------------------------------------------------------------------
func _on_pick_parent_a_pressed() -> void:
	_picking_slot = 1
	_populate_picker()
	_rabbit_picker.visible = true


func _on_pick_parent_b_pressed() -> void:
	_picking_slot = 2
	_populate_picker()
	_rabbit_picker.visible = true


func _populate_picker() -> void:
	_clear_children(_picker_list)
	var all_rabbits: Array[RabbitData] = RabbitSystem.get_all_rabbits()
	for rabbit: RabbitData in all_rabbits:
		if rabbit.stage != RabbitData.RabbitStage.ADULT and rabbit.stage != RabbitData.RabbitStage.ELDER:
			continue
		var stage_name: String = _stage_label(rabbit.stage)
		var color_str: String = rabbit.genome.color.expressed() if rabbit.genome != null else "?"
		var btn_text: String = "%s [%s] — %s" % [rabbit.display_name, stage_name, color_str]
		var btn := _make_button(btn_text, COLOR_HEARTHSTONE)
		btn.add_theme_color_override("font_color", COLOR_WORN_OAK)
		btn.add_theme_font_size_override("font_size", 30)
		btn.custom_minimum_size = Vector2(0.0, 90.0)
		btn.pressed.connect(_on_picker_rabbit_selected.bind(rabbit.rabbit_id))
		_picker_list.add_child(btn)


func _on_picker_rabbit_selected(rabbit_id: String) -> void:
	_breed_error_label.text = ""
	if _picking_slot == 1:
		if rabbit_id == _parent_b_id:
			_breed_error_label.text = "Cannot use the same rabbit for both parents!"
			return
		_parent_a_id = rabbit_id
		var r: RabbitData = RabbitSystem.get_rabbit(rabbit_id)
		_parent_a_label.text = r.display_name if r != null else rabbit_id
	elif _picking_slot == 2:
		if rabbit_id == _parent_a_id:
			_breed_error_label.text = "Cannot use the same rabbit for both parents!"
			return
		_parent_b_id = rabbit_id
		var r: RabbitData = RabbitSystem.get_rabbit(rabbit_id)
		_parent_b_label.text = r.display_name if r != null else rabbit_id

	_rabbit_picker.visible = false
	_picking_slot = 0
	_breed_btn.disabled = _parent_a_id.is_empty() or _parent_b_id.is_empty()


func _on_picker_close_pressed() -> void:
	_rabbit_picker.visible = false
	_picking_slot = 0


func _on_breed_pressed() -> void:
	if _parent_a_id.is_empty() or _parent_b_id.is_empty():
		return
	var parent_a: RabbitData = RabbitSystem.get_rabbit(_parent_a_id)
	var parent_b: RabbitData = RabbitSystem.get_rabbit(_parent_b_id)
	if parent_a == null or parent_b == null:
		_breed_error_label.text = "Could not find selected parents."
		return

	var child: RabbitData = GeneticsSystem.breed(parent_a, parent_b)
	var child_id: String = RabbitSystem.add_rabbit(child)
	_rabbit_ids.append(child_id)
	_refresh_hutch_buttons()

	var child_color: String = child.genome.color.expressed() if child.genome != null else "unknown"
	var child_ears: String = child.genome.ears.expressed() if child.genome != null else "unknown"
	var rarity: String = _rarity_label(child_color)

	_result_label.text = "Offspring: %s %s rabbit\nRarity: %s\nAdded to hutch!" % [child_color, child_ears, rarity]
	_result_panel.visible = true

	# Reset selections for next breed
	_parent_a_id = ""
	_parent_b_id = ""
	_parent_a_label.text = "Tap to select\nParent A"
	_parent_b_label.text = "Tap to select\nParent B"
	_breed_btn.disabled = true


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _rarity_label(color: String) -> String:
	match color:
		"white", "brown", "grey":
			return "Common"
		"spotted", "striped", "calico":
			return "Uncommon"
		"gold", "silver":
			return "Rare"
		"galaxy", "rainbow":
			return "Epic"
		"legendary":
			return "LEGENDARY"
		_:
			return "Unknown"


func _stage_label(stage: RabbitData.RabbitStage) -> String:
	match stage:
		RabbitData.RabbitStage.BABY:
			return "Baby"
		RabbitData.RabbitStage.JUVENILE:
			return "Juvenile"
		RabbitData.RabbitStage.ADULT:
			return "Adult"
		RabbitData.RabbitStage.ELDER:
			return "Elder"
		RabbitData.RabbitStage.SANCTUARY:
			return "Sanctuary"
		_:
			return "?"


func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		child.queue_free()


# ---------------------------------------------------------------------------
# Layout / style helpers
# ---------------------------------------------------------------------------
## Sets position and size on a Control node directly (no anchors).
func _place(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.position = Vector2(x, y)
	node.size = Vector2(w, h)


## Creates a Panel with a StyleBoxFlat using the palette color and Worn Oak border.
func _make_panel(color: Color) -> Panel:
	var p := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_WORN_OAK
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	p.add_theme_stylebox_override("panel", style)
	return p


## Creates a styled Button with the given text and background color.
func _make_button(text: String, bg: Color) -> Button:
	var b := Button.new()
	b.text = text
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	b.add_theme_stylebox_override("normal", style)
	b.add_theme_stylebox_override("hover", style)
	b.add_theme_stylebox_override("pressed", style)
	b.add_theme_color_override("font_color", Color.WHITE)
	return b
