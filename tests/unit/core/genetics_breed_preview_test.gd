## Unit tests for GeneticsSystem.get_breed_preview() — pure probability tables.
## Story: production/epics/genetics-system/story-003-breed-preview.md
## Key invariant: no RNG calls; probabilities sum to 1.0; parents never modified.
extends GdUnitTestSuite

const GeneticsSystemScript := preload("res://src/core/genetics_system.gd")
const EPSILON: float = 0.0001

var _system: Node


func before_test() -> void:
	_system = GeneticsSystemScript.new()


func after_test() -> void:
	_system.free()


func _make_rabbit(color_a: String = "white", color_b: String = "brown",
		trait_a_a: String = "fast_eater", trait_b_a: String = "calm",
		mutation: float = 0.05) -> RabbitData:
	var data := RabbitData.new()
	data.genome = Genome.new()
	data.genome.color.allele_a = color_a
	data.genome.color.allele_b = color_b
	data.genome.trait_a.allele_a = trait_a_a
	data.genome.trait_a.allele_b = AlleleCatalogue.TRAIT_NONE
	data.genome.trait_b.allele_a = trait_b_a
	data.genome.trait_b.allele_b = AlleleCatalogue.TRAIT_NONE
	data.genome.special.allele_a = AlleleCatalogue.TRAIT_NONE
	data.genome.special.allele_b = AlleleCatalogue.TRAIT_NONE
	data.mutation_chance = mutation
	return data


func _sum_dict(d: Dictionary) -> float:
	var total: float = 0.0
	for v in d.values():
		total += v as float
	return total


## AC-1: get_breed_preview() returns a BreedPreview resource.
func test_get_breed_preview_returns_breed_preview() -> void:
	var pa := _make_rabbit()
	var pb := _make_rabbit("grey", "spotted")
	var preview: BreedPreview = _system.get_breed_preview(pa, pb)
	assert_bool(preview != null).is_true()
	assert_bool(preview is BreedPreview).is_true()


## AC-2 (purity check): identical parents produce identical results on every call.
## If _rng were called, results would diverge after the first call.
func test_get_breed_preview_is_pure_same_result_every_call() -> void:
	var pa := _make_rabbit("gold", "silver", "fast_eater", "lucky", 0.1)
	var pb := _make_rabbit("white", "grey", "curious", "calm", 0.1)
	var p1: BreedPreview = _system.get_breed_preview(pa, pb)
	var p2: BreedPreview = _system.get_breed_preview(pa, pb)
	for key: String in p1.color_probabilities:
		assert_float(p1.color_probabilities[key]).is_equal_approx(
			p2.color_probabilities[key], EPSILON)


## AC-3: color_probabilities values sum to 1.0 (± epsilon).
func test_color_probabilities_sum_to_one() -> void:
	var pa := _make_rabbit("white", "brown", "fast_eater", "calm", 0.05)
	var pb := _make_rabbit("grey", "spotted", "curious", "lucky", 0.05)
	var preview: BreedPreview = _system.get_breed_preview(pa, pb)
	assert_float(_sum_dict(preview.color_probabilities)).is_equal_approx(1.0, EPSILON)


## AC-4: trait_a_probabilities values sum to 1.0 (± epsilon).
func test_trait_a_probabilities_sum_to_one() -> void:
	var pa := _make_rabbit()
	var pb := _make_rabbit("grey", "spotted", "speed_grower", "high_fertility", 0.05)
	var preview: BreedPreview = _system.get_breed_preview(pa, pb)
	assert_float(_sum_dict(preview.trait_a_probabilities)).is_equal_approx(1.0, EPSILON)


## AC-5: trait_b_probabilities values sum to 1.0 (± epsilon).
func test_trait_b_probabilities_sum_to_one() -> void:
	var pa := _make_rabbit()
	var pb := _make_rabbit()
	var preview: BreedPreview = _system.get_breed_preview(pa, pb)
	assert_float(_sum_dict(preview.trait_b_probabilities)).is_equal_approx(1.0, EPSILON)


## AC-6: With mutation_chance = 0.0, only parent alleles appear in color_probabilities.
func test_zero_mutation_only_parent_alleles_in_probabilities() -> void:
	var pa := _make_rabbit("white", "brown", "fast_eater", "calm", 0.0)
	var pb := _make_rabbit("white", "brown", "fast_eater", "calm", 0.0)
	var preview: BreedPreview = _system.get_breed_preview(pa, pb)
	for key: String in preview.color_probabilities:
		# With no mutation, only parent alleles should have non-zero probability
		if preview.color_probabilities[key] > EPSILON:
			assert_bool(["white", "brown"].has(key)).is_true()


## AC-7: preview.mutation_chance equals average of both parents' mutation_chance.
func test_mutation_chance_is_average_of_parents() -> void:
	var pa := _make_rabbit("white", "brown", "fast_eater", "calm", 0.1)
	var pb := _make_rabbit("grey", "spotted", "curious", "lucky", 0.3)
	var preview: BreedPreview = _system.get_breed_preview(pa, pb)
	assert_float(preview.mutation_chance).is_equal_approx(0.2, EPSILON)


## AC-8 (parent immutability): parents unchanged after get_breed_preview().
func test_get_breed_preview_does_not_modify_parents() -> void:
	var pa := _make_rabbit("gold", "silver", "fast_eater", "calm", 0.05)
	var pb := _make_rabbit("legendary", "grey", "curious", "lucky", 0.05)
	_system.get_breed_preview(pa, pb)
	assert_str(pa.genome.color.allele_a).is_equal("gold")
	assert_str(pa.genome.color.allele_b).is_equal("silver")
	assert_str(pb.genome.color.allele_a).is_equal("legendary")
	assert_str(pb.genome.trait_a.allele_a).is_equal("curious")
