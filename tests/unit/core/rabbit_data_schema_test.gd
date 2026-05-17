## Unit tests for RabbitData schema: field presence, types, and defaults.
## Story: production/epics/rabbit-system/story-001-rabbit-data-schema.md
## RabbitData extends Resource — no scene or autoload required to instantiate.
extends GdUnitTestSuite


## AC-1: RabbitData.new() succeeds with no scene or autoload loaded.
func test_instantiation_succeeds_without_scene_or_autoload() -> void:
	var r := RabbitData.new()
	assert_bool(is_instance_valid(r)).is_true()


## AC-2: All visible stat fields default to correct values.
func test_default_stat_values_are_correct() -> void:
	var r := RabbitData.new()
	assert_float(r.hunger).is_equal(100.0)
	assert_float(r.happiness).is_equal(100.0)
	assert_float(r.health).is_equal(100.0)
	assert_float(r.cleanliness).is_equal(100.0)
	assert_float(r.growth_progress).is_equal(0.0)
	assert_float(r.fertility).is_equal(1.0)
	assert_int(r.birth_timestamp).is_equal(0)


## AC-2 (hidden stats): mutation_chance defaults to 0.05.
func test_mutation_chance_defaults_to_base_value() -> void:
	var r := RabbitData.new()
	assert_float(r.mutation_chance).is_equal_approx(0.05, 0.0001)


## AC-3: stage defaults to BABY.
func test_stage_defaults_to_baby() -> void:
	var r := RabbitData.new()
	assert_int(r.stage).is_equal(RabbitData.RabbitStage.BABY)


## AC-3: RabbitStage enum has all 5 lifecycle values.
func test_rabbit_stage_enum_has_five_values() -> void:
	assert_int(RabbitData.RabbitStage.BABY).is_equal(0)
	assert_int(RabbitData.RabbitStage.JUVENILE).is_equal(1)
	assert_int(RabbitData.RabbitStage.ADULT).is_equal(2)
	assert_int(RabbitData.RabbitStage.ELDER).is_equal(3)
	assert_int(RabbitData.RabbitStage.SANCTUARY).is_equal(4)


## AC-4 + AC-5: All String fields default to empty; parentage fields empty = founder rabbit.
func test_all_string_fields_default_to_empty_string() -> void:
	var r := RabbitData.new()
	assert_str(r.rabbit_id).is_equal("")
	assert_str(r.display_name).is_equal("")
	assert_str(r.aura_type).is_equal("")
	assert_str(r.parent_a_id).is_equal("")
	assert_str(r.parent_b_id).is_equal("")
	assert_str(r.hutch_id).is_equal("")


## AC-5: genome field is null until ADR-0006 Genome class is assigned.
func test_genome_field_defaults_to_null() -> void:
	var r := RabbitData.new()
	assert_bool(r.genome == null).is_true()
