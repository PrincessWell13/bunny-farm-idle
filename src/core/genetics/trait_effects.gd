## TraitEffects — transient value object produced by GeneticsSystem.get_trait_effects().
## Never saved to disk; no identity. Reflects synergy/cancellation/ultra-combo resolution.
class_name TraitEffects extends RefCounted

var growth_rate_bonus: float = 0.0
var fertility_bonus: float = 0.0
var mutation_bonus: float = 0.0
var coin_bonus: float = 0.0
var drop_rate_bonus: float = 0.0
var legendary_blood_bonus: float = 0.0
var has_ultra_trait: bool = false
var ultra_trait_id: String = ""
