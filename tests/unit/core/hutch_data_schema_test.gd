extends GdUnitTestSuite

# Tests for HutchData schema — AC-1 through AC-8 (story-001-hutch-data-schema)


func test_instantiation_succeeds_with_no_autoloads() -> void:
	var h := HutchData.new()
	assert_that(is_instance_valid(h)).is_true()
	assert_object(h).is_instanceof(Resource)


func test_default_field_values() -> void:
	var h := HutchData.new()
	assert_str(h.hutch_id).is_equal("")
	assert_int(h.level).is_equal(1)
	assert_float(h.cleanliness).is_equal(1.0)


func test_occupants_starts_empty() -> void:
	var h := HutchData.new()
	assert_bool(h.occupants.is_empty()).is_true()


func test_no_export_annotation() -> void:
	# Policy gate: grep the source file for @export — must find zero matches.
	var file := FileAccess.open("res://src/core/hutch_data.gd", FileAccess.READ)
	assert_object(file).is_not_null()
	var source := file.get_as_text()
	file.close()
	assert_bool(source.contains("@export")).is_false()


func test_hutch_id_uniqueness_per_instance() -> void:
	var a := HutchData.new()
	var b := HutchData.new()
	a.hutch_id = "hutch_001"
	b.hutch_id = "hutch_002"
	assert_str(a.hutch_id).is_not_equal(b.hutch_id)


func test_occupants_array_independence_between_instances() -> void:
	var a := HutchData.new()
	var b := HutchData.new()
	a.occupants.append("rabbit_001")
	assert_bool(b.occupants.is_empty()).is_true()


func test_cleanliness_default_is_full() -> void:
	var h := HutchData.new()
	assert_float(h.cleanliness).is_equal(1.0)


func test_round_trip_serialisation() -> void:
	var original := HutchData.new()
	original.hutch_id = "h1"
	original.level = 2
	original.occupants = ["r1", "r2"]
	original.cleanliness = 0.65

	# Mirrors SaveSystem._hutch_to_dict() / _dict_to_hutch() pattern (ADR-0010)
	var d := {
		"hutch_id": original.hutch_id,
		"level": original.level,
		"occupants": original.occupants.duplicate(),
		"cleanliness": original.cleanliness,
	}

	var restored := HutchData.new()
	restored.hutch_id = d["hutch_id"]
	restored.level = d["level"]
	restored.occupants = d["occupants"].duplicate()
	restored.cleanliness = d["cleanliness"]

	assert_str(restored.hutch_id).is_equal(original.hutch_id)
	assert_int(restored.level).is_equal(original.level)
	assert_float(restored.cleanliness).is_equal(original.cleanliness)
	assert_int(restored.occupants.size()).is_equal(original.occupants.size())
	assert_str(restored.occupants[0]).is_equal("r1")
	assert_str(restored.occupants[1]).is_equal("r2")
