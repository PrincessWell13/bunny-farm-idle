## AlleleCatalogue — authoritative constant lists for all valid allele keys (ADR-0006).
## Never use inline allele strings in game logic — always reference these constants.
## Order within COLORS determines rarity tier: index 0 = most common.
class_name AlleleCatalogue

# Color alleles — ordered by ascending rarity (common → legendary)
const COLORS: Array[String] = [
	"white", "brown", "grey",           # common  (~60%)
	"spotted", "striped", "calico",     # uncommon (~25%)
	"gold", "silver",                   # rare     (~10%)
	"galaxy", "rainbow",                # epic      (~4%)
	"legendary",                        # legendary (~1%)
]

# Trait alleles — 24 traits across 3 tiers
const TRAITS_TIER1: Array[String] = [
	"fast_eater", "efficient_eater", "active", "calm", "sturdy", "curious",
]
const TRAITS_TIER2: Array[String] = [
	"speed_grower", "high_fertility", "lucky", "charming",
	"heat_resistant", "cold_adapted", "night_owl", "early_bird",
]
const TRAITS_TIER3: Array[String] = [
	"gene_beacon", "immortal_gene", "mutation_master",
	"golden_touch", "legendary_blood",
	"aura_emitter", "ultra_sense", "time_bender", "void_walker", "cosmic_link",
]

const TRAIT_NONE: String = "none"

# Size and ears catalogues used by _random_allele() in GeneticsSystem
const SIZES: Array[String] = ["small", "medium", "large"]
const EARS: Array[String] = ["floppy", "upright", "stubby"]
