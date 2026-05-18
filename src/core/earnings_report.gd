## EarningsReport — value object returned by IdleProductionSystem (ADR-0007).
## Caller passes carrot_coin to EconomyManager.add(); UI reads source_breakdown.
## star_dust is reserved for expeditions — idle production never sets it non-zero.
class_name EarningsReport extends RefCounted

var carrot_coin: int = 0        # floored int — pass to EconomyManager.add()
var carrot_coin_raw: float = 0.0 # unflored rate — use for fractional accumulation
var star_dust: int = 0
var applied_multiplier: float = 1.0
var delta_seconds: float = 0.0
var source_breakdown: Array = []
