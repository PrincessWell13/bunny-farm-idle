## Tests for EconomyManager currency ledger: add/spend/get/set operations.
## Story: production/epics/economy-manager/story-001-currency-ledger.md
extends GdUnitTestSuite

const EconomyManagerScript := preload("res://src/core/economy_manager.gd")

var _economy: Node

func before_test() -> void:
	_economy = EconomyManagerScript.new()
	add_child(_economy)

func after_test() -> void:
	_economy.queue_free()
	_economy = null


## AC-6: all 4 currency balances initialise to 0.
func test_all_balances_initialise_to_zero() -> void:
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.CARROT_COIN)).is_equal(0)
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.STAR_DUST)).is_equal(0)
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.CRYSTAL_GEM)).is_equal(0)
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.GENE_FRAGMENT)).is_equal(0)


## AC-1: add() increases balance by the given amount.
func test_add_increases_balance() -> void:
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, 100)
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.CARROT_COIN)).is_equal(100)


## AC-1 edge: add(0) is a no-op.
func test_add_zero_is_no_op() -> void:
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, 0)
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.CARROT_COIN)).is_equal(0)


## AC-1 edge: add() with negative amount is a no-op.
func test_add_negative_is_no_op() -> void:
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, -50)
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.CARROT_COIN)).is_equal(0)


## AC-2: spend() returns true and deducts when balance is sufficient.
func test_spend_succeeds_when_sufficient() -> void:
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, 100)
	var result: bool = _economy.spend(EconomyManagerScript.CurrencyType.CARROT_COIN, 50)
	assert_bool(result).is_true()
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.CARROT_COIN)).is_equal(50)


## AC-2 edge: spend() of exact balance returns true and leaves balance at 0.
func test_spend_exact_balance_succeeds() -> void:
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, 75)
	var result: bool = _economy.spend(EconomyManagerScript.CurrencyType.CARROT_COIN, 75)
	assert_bool(result).is_true()
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.CARROT_COIN)).is_equal(0)


## AC-3: spend() returns false and leaves balance unchanged when insufficient.
func test_spend_fails_when_insufficient() -> void:
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, 100)
	var result: bool = _economy.spend(EconomyManagerScript.CurrencyType.CARROT_COIN, 200)
	assert_bool(result).is_false()
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.CARROT_COIN)).is_equal(100)


## AC-3 edge: balance never goes negative — spend on 0 balance returns false.
func test_spend_does_not_go_negative() -> void:
	var result: bool = _economy.spend(EconomyManagerScript.CurrencyType.CARROT_COIN, 1)
	assert_bool(result).is_false()
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.CARROT_COIN)).is_equal(0)


## AC-4: set_balance() sets the balance to the specified value directly.
func test_set_balance_sets_directly() -> void:
	_economy.set_balance(EconomyManagerScript.CurrencyType.STAR_DUST, 999)
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.STAR_DUST)).is_equal(999)


## AC-4 edge: set_balance() with negative value is clamped to 0.
func test_set_balance_negative_clamped_to_zero() -> void:
	_economy.set_balance(EconomyManagerScript.CurrencyType.STAR_DUST, -100)
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.STAR_DUST)).is_equal(0)


## AC-5: currencies are fully independent — modifying one does not affect others.
func test_currencies_are_independent() -> void:
	_economy.add(EconomyManagerScript.CurrencyType.CARROT_COIN, 500)
	_economy.add(EconomyManagerScript.CurrencyType.STAR_DUST, 10)
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.CARROT_COIN)).is_equal(500)
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.STAR_DUST)).is_equal(10)
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.CRYSTAL_GEM)).is_equal(0)
	assert_int(_economy.get_balance(EconomyManagerScript.CurrencyType.GENE_FRAGMENT)).is_equal(0)
