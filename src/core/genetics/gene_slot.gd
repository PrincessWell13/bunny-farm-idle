## GeneSlot — one slot in a rabbit's genome; holds two allele strings.
## allele_a is the expressed allele for color/size/ears; both express for traits.
## Only GeneticsSystem writes to allele fields (ADR-0005 immutability contract).
class_name GeneSlot extends Resource

var allele_a: String = "none"
var allele_b: String = "none"

## Returns the expressed allele. For color/size/ears this is allele_a (first-inherited).
## For traits, GeneticsSystem reads both directly — call expressed() for the dominant one.
func expressed() -> String:
	return allele_a
