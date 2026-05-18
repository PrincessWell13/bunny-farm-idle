## GeneticsSystem — owns the breeding algorithm and trait stacking resolution (ADR-0006).
## breed() and get_breed_preview() never modify parent rabbits (ADR-0005 immutability rule).
## All probability weights and mutation config loaded from balance.json (ADR-0004).
extends Node

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _rarity_weights: Dictionary = {
	"common": 0.60, "uncommon": 0.25, "rare": 0.10, "epic": 0.04, "legendary": 0.01
}
var _trait_synergies: Array = [
	{"traits": ["fast_eater", "efficient_eater"], "bonus": {"growth_rate_bonus": 0.3}}
]
var _trait_cancellations: Array = [
	{"traits": ["calm", "active"], "suppressed": "active"}
]
var _ultra_combos: Array = [
	{"traits": ["gene_beacon", "mutation_master", "golden_touch"], "ultra_trait_id": "omega_gene"}
]

## Rarity tier for a rabbit's expressed color. Value derived, never stored on RabbitData.
enum RarityTier { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

func _ready() -> void:
	_load_balance_data()

## Inject a seeded RNG for deterministic unit testing.
func set_rng(rng: RandomNumberGenerator) -> void:
	_rng = rng

## Returns a new RabbitData child from two parents. Parents are never modified.
## Child genome is built by _build_child_genome; parentage and timestamp set here.
func breed(parent_a: RabbitData, parent_b: RabbitData) -> RabbitData:
	var child: RabbitData = RabbitData.new()
	var effective_mutation: float = (parent_a.mutation_chance + parent_b.mutation_chance) * 0.5
	child.genome = _build_child_genome(
		parent_a.genome, parent_b.genome, effective_mutation
	)
	child.parent_a_id = parent_a.rabbit_id
	child.parent_b_id = parent_b.rabbit_id
	child.birth_timestamp = int(Time.get_unix_time_from_system())
	return child

## Constructs a child Genome slot-by-slot from two parent Genomes.
## effective_mutation is the averaged mutation chance of both parents.
func _build_child_genome(genome_a: Genome, genome_b: Genome,
		effective_mutation: float) -> Genome:
	var child_genome: Genome = Genome.new()
	child_genome.color   = _inherit_slot(genome_a.color,   genome_b.color,   effective_mutation, "color")
	child_genome.size    = _inherit_slot(genome_a.size,    genome_b.size,    effective_mutation, "size")
	child_genome.ears    = _inherit_slot(genome_a.ears,    genome_b.ears,    effective_mutation, "ears")
	child_genome.trait_a = _inherit_slot(genome_a.trait_a, genome_b.trait_a, effective_mutation, "trait")
	child_genome.trait_b = _inherit_slot(genome_a.trait_b, genome_b.trait_b, effective_mutation, "trait")
	child_genome.special = _inherit_slot(genome_a.special, genome_b.special, effective_mutation, "special")
	return child_genome

## Inherits one GeneSlot from two parent slots. Exactly 4 RNG calls per slot:
## 1) pick allele_a from parent_a, 2) pick allele_b from parent_b,
## 3) mutation roll for allele_a, 4) mutation roll for allele_b.
func _inherit_slot(slot_a: GeneSlot, slot_b: GeneSlot,
		mutation_chance: float, catalogue_key: String) -> GeneSlot:
	var child_slot: GeneSlot = GeneSlot.new()
	child_slot.allele_a = slot_a.allele_a if _rng.randf() < 0.5 else slot_a.allele_b
	child_slot.allele_b = slot_b.allele_a if _rng.randf() < 0.5 else slot_b.allele_b
	if _rng.randf() < mutation_chance:
		child_slot.allele_a = _random_allele(catalogue_key)
	if _rng.randf() < mutation_chance:
		child_slot.allele_b = _random_allele(catalogue_key)
	return child_slot

## Returns a random valid allele for the given catalogue slot.
## Only AlleleCatalogue arrays are used — never inline string literals (ADR-0006).
func _random_allele(catalogue_key: String) -> String:
	match catalogue_key:
		"color":
			return _random_color_by_rarity()
		"size":
			return AlleleCatalogue.SIZES[_rng.randi() % AlleleCatalogue.SIZES.size()]
		"ears":
			return AlleleCatalogue.EARS[_rng.randi() % AlleleCatalogue.EARS.size()]
		"trait":
			var all_traits: Array[String] = []
			all_traits.append_array(AlleleCatalogue.TRAITS_TIER1)
			all_traits.append_array(AlleleCatalogue.TRAITS_TIER2)
			all_traits.append_array(AlleleCatalogue.TRAITS_TIER3)
			all_traits.append(AlleleCatalogue.TRAIT_NONE)
			return all_traits[_rng.randi() % all_traits.size()]
		"special":
			return AlleleCatalogue.TRAIT_NONE
		_:
			push_warning("GeneticsSystem: unknown catalogue key '%s'" % catalogue_key)
			return AlleleCatalogue.TRAIT_NONE

## Loads genetics balance data from balance.json.
## Story 004 adds rarity_weights loading. Story 005 adds synergy/cancellation tables.
## Returns a BreedPreview with per-slot probability distributions — pure function, no RNG.
## color_probabilities and trait probabilities each sum to 1.0 (normalised).
func get_breed_preview(parent_a: RabbitData, parent_b: RabbitData) -> BreedPreview:
	var preview := BreedPreview.new()
	var effective_mutation: float = (parent_a.mutation_chance + parent_b.mutation_chance) * 0.5
	preview.color_probabilities = _slot_probabilities(
		parent_a.genome.color, parent_b.genome.color, effective_mutation, "color")
	preview.trait_a_probabilities = _slot_probabilities(
		parent_a.genome.trait_a, parent_b.genome.trait_a, effective_mutation, "trait")
	preview.trait_b_probabilities = _slot_probabilities(
		parent_a.genome.trait_b, parent_b.genome.trait_b, effective_mutation, "trait")
	preview.mutation_chance = effective_mutation
	preview.estimated_rarity = _estimate_rarity(preview.color_probabilities)
	return preview

## Computes the probability distribution of the expressed allele (allele_a) for one slot.
## P(child.slot.expressed() == k) = inheritance_contrib + mutation_contrib, normalised.
## Pure function — no _rng calls.
func _slot_probabilities(slot_a: GeneSlot, slot_b: GeneSlot,
		mutation_chance: float, catalogue_key: String) -> Dictionary:
	var catalogue: Array[String] = _get_catalogue(catalogue_key)
	var cat_size: int = catalogue.size()
	var probs: Dictionary = {}
	if cat_size == 0:
		return probs
	var no_mut: float = 1.0 - mutation_chance
	var mut_contrib: float = mutation_chance / float(cat_size)
	# Seed every catalogue entry with its uniform mutation contribution
	for key: String in catalogue:
		probs[key] = mut_contrib
	# Add 50/50 inheritance probability for each of parent_a's alleles (expressed = allele_a)
	probs[slot_a.allele_a] = probs.get(slot_a.allele_a, 0.0) + 0.5 * no_mut
	probs[slot_a.allele_b] = probs.get(slot_a.allele_b, 0.0) + 0.5 * no_mut
	# Normalise — guards against floating-point drift
	var total: float = 0.0
	for v: float in probs.values():
		total += v
	if total > 0.0:
		for key: String in probs:
			probs[key] = probs[key] / total
	return probs

## Returns a TraitEffects value object for a rabbit. Resolution order: cancellation →
## synergy → hidden combo. Does not modify the rabbit.
func get_trait_effects(rabbit: RabbitData) -> TraitEffects:
	var fx := TraitEffects.new()
	var active: Array[String] = _collect_active_traits(rabbit)
	# Step 1: cancellation — build set of suppressed traits
	var cancelled: Dictionary = {}
	for pair: Dictionary in _trait_cancellations:
		var pts: Array = pair.get("traits", [])
		var sup: String = pair.get("suppressed", "")
		if pts.size() == 2 and active.has(pts[0]) and active.has(pts[1]) and sup != "":
			cancelled[sup] = true
	# Step 2: synergy — only if neither trait in the pair was cancelled
	for syn: Dictionary in _trait_synergies:
		var st: Array = syn.get("traits", [])
		if st.size() != 2:
			continue
		if active.has(st[0]) and active.has(st[1]):
			if not cancelled.has(st[0]) and not cancelled.has(st[1]):
				_apply_bonus_dict(fx, syn.get("bonus", {}))
	# Step 3: hidden combo — cancellation status does not block combo detection
	for combo: Dictionary in _ultra_combos:
		var ct: Array = combo.get("traits", [])
		var uid: String = combo.get("ultra_trait_id", "")
		if uid == "":
			continue
		var all_present: bool = true
		for t: String in ct:
			if not active.has(t):
				all_present = false
				break
		if all_present:
			fx.has_ultra_trait = true
			fx.ultra_trait_id = uid
			break
	return fx

## Collects expressed trait strings from trait_a, trait_b, and special slots.
## Skips "none" entries — they do not participate in stacking.
func _collect_active_traits(rabbit: RabbitData) -> Array[String]:
	var traits: Array[String] = []
	for expressed: String in [
		rabbit.genome.trait_a.expressed(),
		rabbit.genome.trait_b.expressed(),
		rabbit.genome.special.expressed(),
	]:
		if expressed != AlleleCatalogue.TRAIT_NONE:
			traits.append(expressed)
	return traits

## Adds bonus dictionary values into a TraitEffects object.
func _apply_bonus_dict(fx: TraitEffects, bonus: Dictionary) -> void:
	fx.growth_rate_bonus     += bonus.get("growth_rate_bonus",     0.0) as float
	fx.fertility_bonus       += bonus.get("fertility_bonus",       0.0) as float
	fx.mutation_bonus        += bonus.get("mutation_bonus",        0.0) as float
	fx.coin_bonus            += bonus.get("coin_bonus",            0.0) as float
	fx.drop_rate_bonus       += bonus.get("drop_rate_bonus",       0.0) as float
	fx.legendary_blood_bonus += bonus.get("legendary_blood_bonus", 0.0) as float

## Returns the rarity tier of a rabbit's expressed color allele. Derived — never stored.
func get_rarity(rabbit: RabbitData) -> RarityTier:
	return _color_to_rarity_tier(rabbit.genome.color.expressed())

## Maps a color allele key to its RarityTier. All 11 AlleleCatalogue.COLORS covered.
func _color_to_rarity_tier(color: String) -> RarityTier:
	match color:
		"white", "brown", "grey":
			return RarityTier.COMMON
		"spotted", "striped", "calico":
			return RarityTier.UNCOMMON
		"gold", "silver":
			return RarityTier.RARE
		"galaxy", "rainbow":
			return RarityTier.EPIC
		"legendary":
			return RarityTier.LEGENDARY
		_:
			push_warning("GeneticsSystem: unknown color '%s'" % color)
			return RarityTier.COMMON

## Returns all AlleleCatalogue.COLORS that belong to the given tier.
func _colors_for_tier(tier: RarityTier) -> Array[String]:
	var result: Array[String] = []
	for color: String in AlleleCatalogue.COLORS:
		if _color_to_rarity_tier(color) == tier:
			result.append(color)
	return result

## Picks a random color allele weighted by rarity tier probabilities from balance.json.
## Tier is selected first by cumulative weight roll; then a uniform pick within that tier.
func _random_color_by_rarity() -> String:
	var roll: float = _rng.randf()
	var cum: float = 0.0
	var weights: Array[float] = [
		_rarity_weights.get("common", 0.60) as float,
		_rarity_weights.get("uncommon", 0.25) as float,
		_rarity_weights.get("rare", 0.10) as float,
		_rarity_weights.get("epic", 0.04) as float,
		_rarity_weights.get("legendary", 0.01) as float,
	]
	var selected: int = weights.size() - 1
	for i: int in weights.size():
		cum += weights[i]
		if roll < cum:
			selected = i
			break
	var pool: Array[String] = _colors_for_tier(selected as RarityTier)
	if pool.is_empty():
		return AlleleCatalogue.COLORS[0]
	return pool[_rng.randi() % pool.size()]

## Returns the full allele catalogue array for a given slot key.
## Mirrors the dispatch logic in _random_allele — keep in sync.
func _get_catalogue(catalogue_key: String) -> Array[String]:
	match catalogue_key:
		"color":
			return AlleleCatalogue.COLORS
		"size":
			return AlleleCatalogue.SIZES
		"ears":
			return AlleleCatalogue.EARS
		"trait":
			var all_traits: Array[String] = []
			all_traits.append_array(AlleleCatalogue.TRAITS_TIER1)
			all_traits.append_array(AlleleCatalogue.TRAITS_TIER2)
			all_traits.append_array(AlleleCatalogue.TRAITS_TIER3)
			all_traits.append(AlleleCatalogue.TRAIT_NONE)
			return all_traits
		"special":
			return [AlleleCatalogue.TRAIT_NONE]
	return []

## Estimates a rarity tier (int matching RarityTier enum) from a color probability dict.
## Uses _color_to_rarity_tier() — no inline strings.
func _estimate_rarity(color_probs: Dictionary) -> int:
	var weighted: float = 0.0
	for color: String in color_probs:
		weighted += _color_to_rarity_tier(color) * (color_probs[color] as float)
	return int(round(weighted))

func _load_balance_data() -> void:
	var text: String = FileAccess.get_file_as_string("res://assets/data/balance.json")
	if text.is_empty():
		return
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return
	var genetics: Dictionary = (parsed as Dictionary).get("genetics", {}) as Dictionary
	var rarity_w: Dictionary = genetics.get("rarity_weights", {}) as Dictionary
	if not rarity_w.is_empty():
		_rarity_weights = rarity_w
	var syn: Array = genetics.get("trait_synergies", []) as Array
	if not syn.is_empty():
		_trait_synergies = syn
	var can: Array = genetics.get("trait_cancellations", []) as Array
	if not can.is_empty():
		_trait_cancellations = can
	var ult: Array = genetics.get("ultra_combos", []) as Array
	if not ult.is_empty():
		_ultra_combos = ult
