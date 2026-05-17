## Unit tests for GeneticsSystem breed() — inheritance algorithm and mutation rolls.
## Story: production/epics/genetics-system/story-002-inheritance-mutation.md
## Key invariant: breed() never modifies parents; RNG is injectable for determinism.
extends GdUnitTestSuite

var _system: GeneticsSystem
var _rng: RandomNumberGenerator


func before_test() -> void:
	_system = GeneticsSystem.new()
	_rng = RandomNumberGenerator.new()
	_rng.seed = 0
	_system.set_rng(_rng)


func after_test() -> void:
	_system.free()


func _make_rabbit(id: String = "", color_a: String = "white",
		color_b: String = "brown", mutation: float = 0.0) -> RabbitData:
	var data := RabbitData.new()
	data.rabbit_id = id
	data.genome = Genome.new()
	data.genome.color.allele_a = color_a
	data.genome.color.allele_b = color_b
	data.genome.size.allele_a = "medium"
	data.genome.size.allele_b = "small"
	data.genome.ears.allele_a = "floppy"
	data.genome.ears.allele_b = "upright"
	data.genome.trait_a.allele_a = "none"
	data.genome.trait_a.allele_b = "none"
	data.genome.trait_b.allele_a = "none"
	data.genome.trait_b.allele_b = "none"
	data.genome.special.allele_a = "none"
	data.genome.special.allele_b = "none"
	data.mutation_chance = mutation
	return data


## AC-1 & AC-2: breed() returns new RabbitData with non-null genome and correct parentage.
func test_breed_returns_rabbit_with_genome_and_parentage() -> void:
	var pa := _make_rabbit("rabbit_a")
	var pb := _make_rabbit("rabbit_b")
	var child := _system.breed(pa, pb)
	assert_bool(child != null).is_true()
	assert_bool(child.genome != null).is_true()
	assert_str(child.parent_a_id).is_equal("rabbit_a")
	assert_str(child.parent_b_id).is_equal("rabbit_b")


## AC-3: child.genome.color.allele_a is always from parent_a's color alleles (no mutation).
func test_breed_allele_a_sourced_from_parent_a() -> void:
	var pa := _make_rabbit("a", "white", "brown", 0.0)
	var pb := _make_rabbit("b", "grey", "spotted", 0.0)
	var parent_a_alleles: Array[String] = ["white", "brown"]
	for seed_val in 100:
		_rng.seed = seed_val
		var child := _system.breed(pa, pb)
		assert_bool(parent_a_alleles.has(child.genome.color.allele_a)).is_true()


## AC-4: child.genome.color.allele_b is always from parent_b's color alleles (no mutation).
func test_breed_allele_b_sourced_from_parent_b() -> void:
	var pa := _make_rabbit("a", "white", "brown", 0.0)
	var pb := _make_rabbit("b", "grey", "spotted", 0.0)
	var parent_b_alleles: Array[String] = ["grey", "spotted"]
	for seed_val in 100:
		_rng.seed = seed_val
		var child := _system.breed(pa, pb)
		assert_bool(parent_b_alleles.has(child.genome.color.allele_b)).is_true()


## AC-5: breed() does not modify parent_a or parent_b genome fields.
func test_breed_does_not_mutate_parents() -> void:
	var pa := _make_rabbit("a", "gold", "gold", 0.5)
	var pb := _make_rabbit("b", "silver", "silver", 0.5)
	_system.breed(pa, pb)
	assert_str(pa.genome.color.allele_a).is_equal("gold")
	assert_str(pa.genome.color.allele_b).is_equal("gold")
	assert_str(pb.genome.color.allele_a).is_equal("silver")
	assert_str(pb.genome.color.allele_b).is_equal("silver")
	assert_str(pa.genome.size.allele_a).is_equal("medium")
	assert_str(pb.genome.size.allele_a).is_equal("medium")


## AC-6: With mutation_chance = 0.0, child alleles are always from parent alleles only.
func test_breed_no_mutation_at_zero_chance() -> void:
	var pa := _make_rabbit("a", "white", "brown", 0.0)
	var pb := _make_rabbit("b", "grey", "spotted", 0.0)
	var valid: Array[String] = ["white", "brown", "grey", "spotted"]
	for seed_val in 100:
		_rng.seed = seed_val
		var child := _system.breed(pa, pb)
		assert_bool(valid.has(child.genome.color.allele_a)).is_true()
		assert_bool(valid.has(child.genome.color.allele_b)).is_true()


## AC-7: With mutation_chance = 1.0, child alleles are mutated (replaced from catalogue).
func test_breed_full_mutation_replaces_alleles() -> void:
	var pa := _make_rabbit("a", "white", "white", 1.0)
	var pb := _make_rabbit("b", "white", "white", 1.0)
	# With 100% mutation and 11 possible colors, virtually certain at least one differs from "white"
	var any_mutated := false
	for seed_val in 20:
		_rng.seed = seed_val
		var child := _system.breed(pa, pb)
		if child.genome.color.allele_a != "white" or child.genome.color.allele_b != "white":
			any_mutated = true
			break
	assert_bool(any_mutated).is_true()


## AC-8: With identical RNG seed, breed() produces identical child genome (deterministic).
func test_breed_deterministic_with_fixed_seed() -> void:
	var pa := _make_rabbit("a", "white", "brown", 0.1)
	var pb := _make_rabbit("b", "grey", "spotted", 0.1)
	_rng.seed = 12345
	var first := _system.breed(pa, pb)
	var color_a_0 := first.genome.color.allele_a
	var color_b_0 := first.genome.color.allele_b
	for _i in 99:
		_rng.seed = 12345
		var child := _system.breed(pa, pb)
		assert_str(child.genome.color.allele_a).is_equal(color_a_0)
		assert_str(child.genome.color.allele_b).is_equal(color_b_0)


## AC-9: Fuzz — after 1000 breeds, all child allele keys are valid catalogue entries.
func test_breed_fuzz_all_alleles_valid_catalogue_entries() -> void:
	var pa := _make_rabbit("a", "white", "gold", 0.1)
	var pb := _make_rabbit("b", "legendary", "grey", 0.1)
	pa.genome.trait_a.allele_a = "fast_eater"
	pa.genome.trait_b.allele_a = "curious"
	pb.genome.trait_a.allele_a = "lucky"
	var valid_colors: Array[String] = AlleleCatalogue.COLORS
	var valid_traits: Array[String] = []
	valid_traits.append_array(AlleleCatalogue.TRAITS_TIER1)
	valid_traits.append_array(AlleleCatalogue.TRAITS_TIER2)
	valid_traits.append_array(AlleleCatalogue.TRAITS_TIER3)
	valid_traits.append(AlleleCatalogue.TRAIT_NONE)
	for _i in 1000:
		var child := _system.breed(pa, pb)
		assert_bool(valid_colors.has(child.genome.color.allele_a)).is_true()
		assert_bool(valid_colors.has(child.genome.color.allele_b)).is_true()
		assert_bool(AlleleCatalogue.SIZES.has(child.genome.size.allele_a)).is_true()
		assert_bool(AlleleCatalogue.EARS.has(child.genome.ears.allele_a)).is_true()
		assert_bool(valid_traits.has(child.genome.trait_a.allele_a)).is_true()
		assert_bool(valid_traits.has(child.genome.trait_b.allele_a)).is_true()
