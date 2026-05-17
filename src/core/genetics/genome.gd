## Genome — 6-slot gene layout for one rabbit (ADR-0006).
## Stored as a nested Resource on RabbitData. Only GeneticsSystem writes to slots.
class_name Genome extends Resource

var color: GeneSlot = GeneSlot.new()    # allele keys: AlleleCatalogue.COLORS
var size: GeneSlot = GeneSlot.new()     # allele keys: "small" | "medium" | "large"
var ears: GeneSlot = GeneSlot.new()     # allele keys: "floppy" | "upright" | "stubby"
var trait_a: GeneSlot = GeneSlot.new()  # allele keys: AlleleCatalogue.TRAITS_TIER* | "none"
var trait_b: GeneSlot = GeneSlot.new()
var special: GeneSlot = GeneSlot.new()  # allele keys: special catalogue or "none"
