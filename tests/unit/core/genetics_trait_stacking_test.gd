## Unit tests for GeneticsSystem.get_trait_effects() — trait stacking resolution.
## Story: production/epics/genetics-system/story-005-trait-stacking.md
## Resolution order: cancellation → synergy → hidden combo. Parents never modified.
extends GdUnitTestSuite

const EPSILON: float = 0.0001

var _system: GeneticsSystem


func before_test() -> void:
	_system = GeneticsSystem.new()
	# Use known defaults so tests are independent of balance.json on disk.
	_system._trait_synergies = [
		{"traits": ["fast_eater", "efficient_eater"], "bonus": {"growth_rate_bonus": 0.3}},
		{"traits": ["speed_grower", "high_fertility"], "bonus": {"fertility_bonus": 0.25}},
	]
	_system._trait_cancellations = [
		{"traits": ["calm", "active"], "suppressed": "active"},
	]
	_system._ultra_combos = [
		{"traits": ["gene_beacon", "mutation_master", "golden_touch"], "ultra_trait_id": "omega_gene"},
	]


func after_test() -> void:
	_system.free()


func _make_trait_rabbit(trait_a: String, trait_b: String,
		special: String = AlleleCatalogue.TRAIT_NONE) -> RabbitData:
	var data := RabbitData.new()
	data.genome = Genome.new()
	data.genome.color.allele_a = "white"
	data.genome.color.allele_b = "white"
	data.genome.trait_a.allele_a = trait_a
	data.genome.trait_a.allele_b = AlleleCatalogue.TRAIT_NONE
	data.genome.trait_b.allele_a = trait_b
	data.genome.trait_b.allele_b = AlleleCatalogue.TRAIT_NONE
	data.genome.special.allele_a = special
	data.genome.special.allele_b = AlleleCatalogue.TRAIT_NONE
	return data


## AC-1: get_trait_effects() returns a TraitEffects object (not null).
func test_genetics_get_trait_effects_returns_trait_effects() -> void:
	var rabbit := _make_trait_rabbit(AlleleCatalogue.TRAIT_NONE, AlleleCatalogue.TRAIT_NONE)
	var fx := _system.get_trait_effects(rabbit)
	assert_bool(fx != null).is_true()
	assert_bool(fx is TraitEffects).is_true()


## AC-2: No traits → all bonuses are 0.0, has_ultra_trait is false.
func test_genetics_no_traits_produces_zero_effects() -> void:
	var rabbit := _make_trait_rabbit(AlleleCatalogue.TRAIT_NONE, AlleleCatalogue.TRAIT_NONE)
	var fx := _system.get_trait_effects(rabbit)
	assert_float(fx.growth_rate_bonus).is_equal_approx(0.0, EPSILON)
	assert_float(fx.fertility_bonus).is_equal_approx(0.0, EPSILON)
	assert_float(fx.coin_bonus).is_equal_approx(0.0, EPSILON)
	assert_bool(fx.has_ultra_trait).is_false()


## AC-3: fast_eater + efficient_eater → growth_rate_bonus > 0.
func test_genetics_synergy_fast_eater_efficient_eater_applies_growth_bonus() -> void:
	var rabbit := _make_trait_rabbit("fast_eater", "efficient_eater")
	var fx := _system.get_trait_effects(rabbit)
	assert_float(fx.growth_rate_bonus).is_greater(0.0)


## AC-4: calm + active → active is suppressed; its bonus does not apply.
## Verify by confirming no active-exclusive synergy fires.
## We add a test synergy for "active" alone and verify it is blocked.
func test_genetics_cancellation_calm_active_suppresses_active() -> void:
	# Inject a synergy that fires only if "active" is NOT cancelled.
	_system._trait_synergies = [
		{"traits": ["active", "curious"], "bonus": {"coin_bonus": 1.0}},
	]
	# rabbit has calm, active, curious — active cancelled → synergy (active+curious) blocked
	var rabbit := _make_trait_rabbit("calm", "active", "curious")
	var fx := _system.get_trait_effects(rabbit)
	assert_float(fx.coin_bonus).is_equal_approx(0.0, EPSILON)


## AC-5: Cancellation runs before synergy — cancelled trait cannot contribute to synergy.
## Setup: "beta_t" cancels "alpha_t"; synergy requires "alpha_t" + "gamma_t".
## With all three present: alpha_t is cancelled → synergy does NOT fire.
func test_genetics_cancellation_runs_before_synergy_blocks_synergy() -> void:
	_system._trait_cancellations = [
		{"traits": ["beta_t", "alpha_t"], "suppressed": "alpha_t"},
	]
	_system._trait_synergies = [
		{"traits": ["alpha_t", "gamma_t"], "bonus": {"growth_rate_bonus": 0.5}},
	]
	_system._ultra_combos = []
	var rabbit := _make_trait_rabbit("beta_t", "alpha_t", "gamma_t")
	var fx := _system.get_trait_effects(rabbit)
	assert_float(fx.growth_rate_bonus).is_equal_approx(0.0, EPSILON)


## AC-6: Hidden combo gene_beacon + mutation_master + golden_touch → ultra trait unlocked.
func test_genetics_ultra_combo_unlocks_ultra_trait() -> void:
	var rabbit := _make_trait_rabbit("gene_beacon", "mutation_master", "golden_touch")
	var fx := _system.get_trait_effects(rabbit)
	assert_bool(fx.has_ultra_trait).is_true()
	assert_str(fx.ultra_trait_id).is_equal("omega_gene")


## AC-6 (negative): Incomplete combo does not unlock ultra trait.
func test_genetics_incomplete_ultra_combo_does_not_unlock() -> void:
	var rabbit := _make_trait_rabbit("gene_beacon", "mutation_master")
	var fx := _system.get_trait_effects(rabbit)
	assert_bool(fx.has_ultra_trait).is_false()
	assert_str(fx.ultra_trait_id).is_equal("")


## AC-7: get_trait_effects() does not modify the rabbit's genome.
func test_genetics_get_trait_effects_does_not_modify_rabbit() -> void:
	var rabbit := _make_trait_rabbit("fast_eater", "efficient_eater", "gene_beacon")
	_system.get_trait_effects(rabbit)
	assert_str(rabbit.genome.trait_a.allele_a).is_equal("fast_eater")
	assert_str(rabbit.genome.trait_b.allele_a).is_equal("efficient_eater")
	assert_str(rabbit.genome.special.allele_a).is_equal("gene_beacon")
