## BreedPreview — value object returned by GeneticsSystem.get_breed_preview().
## Pure analytical result — no RNG used to produce it (ADR-0006).
## probability dictionaries map allele_key → probability float (0.0–1.0, normalised).
class_name BreedPreview extends Resource

var color_probabilities: Dictionary = {}    # allele_key → float
var trait_a_probabilities: Dictionary = {}
var trait_b_probabilities: Dictionary = {}
var mutation_chance: float = 0.0
var estimated_rarity: int = 0  # GeneticsSystem.RarityTier value (int until enum accessible cross-file)
