## Unit tests for EarningsReport schema — Story 001.
## Verifies fields, defaults, and RefCounted inheritance.
extends GdUnitTestSuite


## AC-1: EarningsReport instantiates with correct field defaults.
func test_idle_earnings_report_default_fields_are_zero() -> void:
	var r := EarningsReport.new()
	assert_int(r.carrot_coin).is_equal(0)
	assert_int(r.star_dust).is_equal(0)
	assert_float(r.applied_multiplier).is_equal_approx(1.0, 0.0001)
	assert_float(r.delta_seconds).is_equal_approx(0.0, 0.0001)
	assert_array(r.source_breakdown).is_empty()


## AC-2: Fields are writable and hold assigned values.
func test_idle_earnings_report_fields_are_writable() -> void:
	var r := EarningsReport.new()
	r.carrot_coin = 42
	r.star_dust = 5
	r.applied_multiplier = 0.60
	r.delta_seconds = 3600.0
	r.source_breakdown = [{"rabbits": 24}]
	assert_int(r.carrot_coin).is_equal(42)
	assert_int(r.star_dust).is_equal(5)
	assert_float(r.applied_multiplier).is_equal_approx(0.60, 0.0001)
	assert_float(r.delta_seconds).is_equal_approx(3600.0, 0.0001)
	assert_int(r.source_breakdown.size()).is_equal(1)


## AC-3: EarningsReport is a RefCounted — no scene tree required.
func test_idle_earnings_report_is_ref_counted() -> void:
	var r := EarningsReport.new()
	assert_bool(r is RefCounted).is_true()
	assert_bool(r is EarningsReport).is_true()
