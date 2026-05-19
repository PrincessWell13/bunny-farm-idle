## EconomyManager — authoritative ledger for all 4 game currencies.
## Autoload #3. All balances initialise to 0; SaveSystem.set_balance() populates
## them from the save file after boot. All income and expenditure pass through
## add() and spend() — never by direct field access from other systems.
## See ADR-0001 for ownership rules and boot sequence.
extends Node

enum CurrencyType { CARROT_COIN, STAR_DUST, CRYSTAL_GEM, GENE_FRAGMENT }

var _balances: Dictionary = {}

func _ready() -> void:
	_balances = {
		CurrencyType.CARROT_COIN:   0,
		CurrencyType.STAR_DUST:     0,
		CurrencyType.CRYSTAL_GEM:   0,
		CurrencyType.GENE_FRAGMENT: 0,
	}

## Adds amount to the given currency balance and emits EventBus.currency_changed.
## No-op if amount <= 0.
func add(currency: CurrencyType, amount: int) -> void:
	if amount <= 0:
		return
	_balances[currency] += amount
	EventBus.currency_changed.emit(currency, _balances[currency], amount)

## Deducts amount from the given currency balance.
## Returns true, deducts, and emits EventBus.currency_changed when balance is sufficient.
## Returns false and changes nothing when insufficient — does not emit.
func spend(currency: CurrencyType, amount: int) -> bool:
	if amount <= 0:
		return false
	if _balances[currency] < amount:
		return false
	_balances[currency] -= amount
	EventBus.currency_changed.emit(currency, _balances[currency], -amount)
	return true

## Returns the current balance for the given currency.
func get_balance(currency: CurrencyType) -> int:
	return _balances[currency]

## Sets balance to a specific amount. Called by SaveSystem only at boot.
## Does not emit currency_changed — boot population must not spam the signal.
func set_balance(currency: CurrencyType, amount: int) -> void:
	_balances[currency] = max(0, amount)


## Adds expedition loot rewards by item_id string (ADR-0011 R4).
## Routes known item_ids to their corresponding CurrencyType; unknown ids are logged.
## Called by ExpeditionSystem.collect() — item_id comes from balance.json loot_table entries.
## GDScript does not support overloading, so this wrapper uses a distinct name.
##
## Example:
##   EconomyManager.add_loot_reward("star_dust", 10)
func add_loot_reward(item_id: String, quantity: int) -> void:
	match item_id:
		"carrot_coin":
			add(CurrencyType.CARROT_COIN, quantity)
		"star_dust":
			add(CurrencyType.STAR_DUST, quantity)
		"crystal_gem":
			add(CurrencyType.CRYSTAL_GEM, quantity)
		"gene_fragment":
			add(CurrencyType.GENE_FRAGMENT, quantity)
		_:
			push_warning("EconomyManager.add_loot_reward: unknown item_id '%s' — reward dropped" % item_id)
