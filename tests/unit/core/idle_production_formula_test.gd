## Unit tests for IdleProductionSystem production formula — Story 002.
## Uses _rabbit_override injection to avoid RabbitSystem autoload dependency.
extends GdUnitTestSuite

var _system: IdleProductionSystem


func before_test() -> void:
	_system = IdleProductionSystem.new()
	_system._base_rate = 0.05
	_system._rabbit_override = []


func after_test() -> void:
	_system.free()
	_system = null


## AC-1: get_tick_earnings() returns EarningsReport with delta_seconds = 1.0 and
## applied_multiplier = 1.0 when called with no rabbits.
func test_idle_production_tick_earnings_meta_fields_are_correct() -> void:
	var r: EarningsReport = _system.get_tick_earnings()
	assert_bool(r is EarningsReport).is_true()
	assert_float(r.delta_seconds).is_equal_approx(1.0, 0.0001)
	assert_float(r.applied_multiplier).is_equal_approx(1.0, 0.0001)


## AC-2: 0 productive rabbits → carrot_coin == 0.
func test_idle_production_zero_rabbits_yields_zero_coins() -> void:
	_system._rabbit_override = []
	var r: EarningsReport = _system.get_tick_earnings()
	assert_int(r.carrot_coin).is_equal(0)


## AC-3: 24 ADULT rabbits × base_rate 0.05 × 1 second → floor(1.2) = 1.
func test_idle_production_24_adult_rabbits_yields_one_coin() -> void:
	_system._rabbit_override = _make_rabbits(24, RabbitData.RabbitStage.ADULT)
	var r: EarningsReport = _system.get_tick_earnings()
	assert_int(r.carrot_coin).is_equal(1)


## AC-4: BABY and JUVENILE rabbits are not counted in productive_count.
func test_idle_production_baby_and_juvenile_not_counted() -> void:
	var babies: Array[RabbitData] = _make_rabbits(5, RabbitData.RabbitStage.BABY)
	var juvs: Array[RabbitData] = _make_rabbits(5, RabbitData.RabbitStage.JUVENILE)
	_system._rabbit_override = babies + juvs
	var r: EarningsReport = _system.get_tick_earnings()
	assert_int(r.carrot_coin).is_equal(0)


## AC-5: source_breakdown[0]["rabbits"] matches the productive rabbit count.
func test_idle_production_source_breakdown_contains_rabbit_count() -> void:
	_system._rabbit_override = _make_rabbits(10, RabbitData.RabbitStage.ADULT)
	var r: EarningsReport = _system.get_tick_earnings()
	assert_int(r.source_breakdown.size()).is_equal(1)
	assert_int(r.source_breakdown[0]["rabbits"]).is_equal(10)


## AC-6: Overriding _base_rate to 0.10; 10 ADULT rabbits × 0.10 × 1s = floor(1.0) = 1.
func test_idle_production_custom_base_rate_scales_output() -> void:
	_system._base_rate = 0.10
	_system._rabbit_override = _make_rabbits(10, RabbitData.RabbitStage.ADULT)
	var r: EarningsReport = _system.get_tick_earnings()
	assert_int(r.carrot_coin).is_equal(1)


## ELDER rabbits count as productive (same as ADULT).
func test_idle_production_elder_rabbits_are_counted() -> void:
	_system._rabbit_override = _make_rabbits(24, RabbitData.RabbitStage.ELDER)
	var r: EarningsReport = _system.get_tick_earnings()
	assert_int(r.carrot_coin).is_equal(1)


## Mixed stages: only ADULT + ELDER count; BABY/JUVENILE do not.
func test_idle_production_mixed_stages_only_productive_counted() -> void:
	var adults: Array[RabbitData] = _make_rabbits(12, RabbitData.RabbitStage.ADULT)
	var elders: Array[RabbitData] = _make_rabbits(12, RabbitData.RabbitStage.ELDER)
	var babies: Array[RabbitData] = _make_rabbits(10, RabbitData.RabbitStage.BABY)
	_system._rabbit_override = adults + elders + babies
	var r: EarningsReport = _system.get_tick_earnings()
	# 24 productive × 0.05 × 1s = floor(1.2) = 1
	assert_int(r.carrot_coin).is_equal(1)
	assert_int(r.source_breakdown[0]["rabbits"]).is_equal(24)


## Helper: creates N RabbitData instances with the given stage.
func _make_rabbits(count: int, stage: RabbitData.RabbitStage) -> Array[RabbitData]:
	var result: Array[RabbitData] = []
	for i: int in count:
		var r := RabbitData.new()
		r.stage = stage
		result.append(r)
	return result
