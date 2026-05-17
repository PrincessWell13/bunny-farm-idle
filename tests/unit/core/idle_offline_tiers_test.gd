## Unit tests for IdleProductionSystem offline catch-up and multiplier tiers — Story 003.
## Uses _rabbit_override injection to avoid RabbitSystem autoload dependency.
extends GdUnitTestSuite

var _system: IdleProductionSystem


func before_test() -> void:
	_system = IdleProductionSystem.new()
	_system._base_rate = 0.05
	_system._multiplier_background = 0.75
	_system._multiplier_under_4h = 0.60
	_system._multiplier_4_to_12h = 0.50
	_system._multiplier_over_12h = 0.40
	_system._max_offline_hours = 72.0
	_system._rabbit_override = _make_rabbits(10, RabbitData.RabbitStage.ADULT)


func after_test() -> void:
	_system.free()
	_system = null


## AC-1: zero offline seconds → carrot_coin == 0 (delta * anything = 0).
func test_idle_offline_zero_seconds_yields_zero_coins() -> void:
	var r: EarningsReport = _system.calculate_offline_earnings(0.0, false)
	assert_int(r.carrot_coin).is_equal(0)


## AC-2: was_backgrounded = true → applied_multiplier == 0.75 regardless of duration.
func test_idle_offline_backgrounded_applies_background_multiplier() -> void:
	var r: EarningsReport = _system.calculate_offline_earnings(3600.0, true)
	assert_float(r.applied_multiplier).is_equal_approx(0.75, 0.0001)


## AC-3: 3-hour offline (< 4h boundary) → applied_multiplier == 0.60.
func test_idle_offline_3h_applies_under_4h_multiplier() -> void:
	var r: EarningsReport = _system.calculate_offline_earnings(3.0 * 3600.0, false)
	assert_float(r.applied_multiplier).is_equal_approx(0.60, 0.0001)


## AC-4: 8-hour offline (4–12h tier) → applied_multiplier == 0.50.
func test_idle_offline_8h_applies_4_to_12h_multiplier() -> void:
	var r: EarningsReport = _system.calculate_offline_earnings(8.0 * 3600.0, false)
	assert_float(r.applied_multiplier).is_equal_approx(0.50, 0.0001)


## AC-5: 20-hour offline (> 12h tier) → applied_multiplier == 0.40.
func test_idle_offline_20h_applies_over_12h_multiplier() -> void:
	var r: EarningsReport = _system.calculate_offline_earnings(20.0 * 3600.0, false)
	assert_float(r.applied_multiplier).is_equal_approx(0.40, 0.0001)


## AC-6: 100-hour offline exceeds 72h cap → delta_seconds in report == 72 * 3600.
func test_idle_offline_100h_capped_at_72h() -> void:
	var r: EarningsReport = _system.calculate_offline_earnings(100.0 * 3600.0, false)
	assert_float(r.delta_seconds).is_equal_approx(72.0 * 3600.0, 0.1)


## AC-7: Exactly 4h → 4–12h tier (0.50), not under-4h tier (0.60).
func test_idle_offline_exactly_4h_boundary_uses_4_to_12h_tier() -> void:
	var r: EarningsReport = _system.calculate_offline_earnings(4.0 * 3600.0, false)
	assert_float(r.applied_multiplier).is_equal_approx(0.50, 0.0001)


## Exactly 12h → over-12h tier (0.40), not 4-to-12h tier (0.50).
func test_idle_offline_exactly_12h_boundary_uses_over_12h_tier() -> void:
	var r: EarningsReport = _system.calculate_offline_earnings(12.0 * 3600.0, false)
	assert_float(r.applied_multiplier).is_equal_approx(0.40, 0.0001)


## Backgrounded flag takes priority: even 20h offline gets 0.75, not 0.40.
func test_idle_offline_backgrounded_flag_overrides_duration_tier() -> void:
	var r: EarningsReport = _system.calculate_offline_earnings(20.0 * 3600.0, true)
	assert_float(r.applied_multiplier).is_equal_approx(0.75, 0.0001)


## Capped earnings: 100h offline → same carrot_coin as 72h offline (not 100h worth).
func test_idle_offline_capped_earnings_match_72h_not_100h() -> void:
	var r_capped: EarningsReport = _system.calculate_offline_earnings(100.0 * 3600.0, false)
	var r_72h: EarningsReport = _system.calculate_offline_earnings(72.0 * 3600.0, false)
	assert_int(r_capped.carrot_coin).is_equal(r_72h.carrot_coin)


## Helper: creates N RabbitData instances with the given stage.
func _make_rabbits(count: int, stage: RabbitData.RabbitStage) -> Array[RabbitData]:
	var result: Array[RabbitData] = []
	for i: int in count:
		var r := RabbitData.new()
		r.stage = stage
		result.append(r)
	return result
