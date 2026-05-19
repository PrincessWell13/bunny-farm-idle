class_name HutchData extends Resource

## Immutable-from-outside data container for a single hutch.
## Only HabitatSystem may write to these fields (see ADR-0010).

var hutch_id: String = ""
var level: int = 1
var occupants: Array[String] = []
var cleanliness: float = 1.0
