## RabbitData — canonical data container for a single rabbit.
## Only RabbitSystem methods may write to these fields (ADR-0005 immutability contract).
## All other systems receive references and may read fields freely — never assign.
class_name RabbitData extends Resource

## 5-stage lifecycle. RabbitSystem owns all transitions (ADR-0005).
enum RabbitStage { BABY, JUVENILE, ADULT, ELDER, SANCTUARY }

var rabbit_id: String = ""
var display_name: String = ""
var stage: RabbitStage = RabbitStage.BABY
## Genome resource — 6 GeneSlot fields. Null for founder rabbits with no genetics data.
var genome: Genome = null
var hunger: float = 100.0
var happiness: float = 100.0
var health: float = 100.0
var cleanliness: float = 100.0
var growth_progress: float = 0.0
## Fertility multiplier; 1.0 = base. Modified by traits and food.
var fertility: float = 1.0
## Base mutation chance from balance.json; boosted by items and traits.
var mutation_chance: float = 0.05
## Empty string = no aura. Non-empty = AuraSystem lookup key (TR-rabbit-004).
var aura_type: String = ""
## Unix seconds at birth. Used for lifespan and stage-advance timing.
var birth_timestamp: int = 0
## Empty = founder rabbit (no parents).
var parent_a_id: String = ""
var parent_b_id: String = ""
var hutch_id: String = ""
