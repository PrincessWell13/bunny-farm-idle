## Unit tests for GeneticsSystem data schema: GeneSlot, Genome, AlleleCatalogue,
## BreedPreview, TraitEffects. Story: production/epics/genetics-system/story-001-genome-schema.md
## All types must instantiate without autoloads or scene dependencies.
extends GdUnitTestSuite


## AC-1 + AC-2: GeneSlot defaults and expressed() returns allele_a.
func test_gene_slot_defaults_and_expressed() -> void:
	var slot := GeneSlot.new()
	assert_str(slot.allele_a).is_equal("none")
	assert_str(slot.allele_b).is_equal("none")
	slot.allele_a = "gold"
	assert_str(slot.expressed()).is_equal("gold")


## AC-2 edge: expressed() returns allele_a even when allele_b differs.
func test_gene_slot_expressed_returns_allele_a_not_b() -> void:
	var slot := GeneSlot.new()
	slot.allele_a = "white"
	slot.allele_b = "legendary"
	assert_str(slot.expressed()).is_equal("white")


## AC-3: Genome instantiates with 6 named GeneSlot fields, none null.
func test_genome_has_six_gene_slot_fields() -> void:
	var genome := Genome.new()
	assert_bool(genome.color != null).is_true()
	assert_bool(genome.size != null).is_true()
	assert_bool(genome.ears != null).is_true()
	assert_bool(genome.trait_a != null).is_true()
	assert_bool(genome.trait_b != null).is_true()
	assert_bool(genome.special != null).is_true()
	assert_bool(genome.color is GeneSlot).is_true()
	assert_bool(genome.trait_b is GeneSlot).is_true()


## AC-4: AlleleCatalogue array sizes match spec (11 colors, 6+8+10 traits).
func test_allele_catalogue_sizes() -> void:
	assert_int(AlleleCatalogue.COLORS.size()).is_equal(11)
	assert_int(AlleleCatalogue.TRAITS_TIER1.size()).is_equal(6)
	assert_int(AlleleCatalogue.TRAITS_TIER2.size()).is_equal(8)
	assert_int(AlleleCatalogue.TRAITS_TIER3.size()).is_equal(10)
	assert_str(AlleleCatalogue.TRAIT_NONE).is_equal("none")


## AC-4 supplemental: COLORS contains expected landmark entries.
func test_allele_catalogue_colors_contains_expected_entries() -> void:
	assert_bool(AlleleCatalogue.COLORS.has("white")).is_true()
	assert_bool(AlleleCatalogue.COLORS.has("legendary")).is_true()
	assert_bool(AlleleCatalogue.COLORS.has("gold")).is_true()
	assert_bool(AlleleCatalogue.COLORS.has("galaxy")).is_true()


## AC-5: BreedPreview defaults — empty dicts, zero mutation_chance.
func test_breed_preview_default_fields() -> void:
	var preview := BreedPreview.new()
	assert_bool(preview.color_probabilities.is_empty()).is_true()
	assert_bool(preview.trait_a_probabilities.is_empty()).is_true()
	assert_bool(preview.trait_b_probabilities.is_empty()).is_true()
	assert_float(preview.mutation_chance).is_equal(0.0)


## AC-6: TraitEffects defaults — all bonuses zero, no ultra trait.
func test_trait_effects_default_fields() -> void:
	var fx := TraitEffects.new()
	assert_float(fx.growth_rate_bonus).is_equal(0.0)
	assert_float(fx.fertility_bonus).is_equal(0.0)
	assert_float(fx.mutation_bonus).is_equal(0.0)
	assert_float(fx.coin_bonus).is_equal(0.0)
	assert_float(fx.drop_rate_bonus).is_equal(0.0)
	assert_float(fx.legendary_blood_bonus).is_equal(0.0)
	assert_bool(fx.has_ultra_trait).is_false()
	assert_str(fx.ultra_trait_id).is_equal("")


## AC-7: All 5 types instantiate without autoload or scene dependency.
func test_all_types_instantiate_without_dependencies() -> void:
	var slot := GeneSlot.new()
	var genome := Genome.new()
	var preview := BreedPreview.new()
	var fx := TraitEffects.new()
	assert_bool(slot != null).is_true()
	assert_bool(genome != null).is_true()
	assert_bool(preview != null).is_true()
	assert_bool(fx != null).is_true()
