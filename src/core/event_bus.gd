## EventBus — cross-system signal catalogue.
## Autoload #1. All cross-layer events are defined here and nowhere else.
## Emit:       EventBus.signal_name.emit(args)
## Connect:    EventBus.signal_name.connect(callable)   in _ready()
## Disconnect: EventBus.signal_name.disconnect(callable) in _exit_tree()
extends Node

## Rabbit lifecycle
signal rabbit_born(rabbit_id: String)
## new_stage: int placeholder — update to RabbitData.RabbitStage when rabbit-system epic story-001 is done (ADR-0005).
signal rabbit_matured(rabbit_id: String, new_stage: int)
signal rabbit_stat_changed(rabbit_id: String)
signal rabbit_died(rabbit_id: String)

## Economy
signal currency_changed(currency: int, new_balance: int, delta: int)

## Production
signal production_ticked(carrot_coin: int, star_dust: int)

## Breeding
signal breed_requested(parent_a_id: String, parent_b_id: String)
signal breeding_completed(child_id: String)

## Habitat
signal hutch_dirtied(hutch_id: String)
signal hutch_upgraded(hutch_id: String, new_level: int)
signal rabbit_assigned_to_hutch(rabbit_id: String, hutch_id: String)
signal hutch_cleanliness_changed(hutch_id: String, cleanliness: float)

## Expedition — ADR-0011 slot-level signals
signal expedition_started(slot_id: String, zone_id: String)          # ADR-0011 slot-level signal
signal expedition_completed(slot_id: String, zone_id: String)        # ADR-0011 slot-level signal (replaces old int/string version)
signal expedition_collected(slot_id: String, rewards: Dictionary)    # ADR-0011 slot-level signal
signal rabbit_sent_on_expedition(slot_id: String, zone_id: String, rabbit_ids: Array)      # ADR-0011 slot-level signal
signal rabbit_returned_from_expedition(slot_id: String, zone_id: String, rabbit_ids: Array) # ADR-0011 slot-level signal
signal expedition_ready_to_collect(slot_id: String, zone_id: String) # ADR-0011 slot-level signal

## Save / sync
signal save_requested()
signal save_synced()
signal new_game_started()

## UI navigation — tab: int placeholder — update to HUD.NavTab when HUD epic story-001 is done.
signal nav_tab_pressed(tab: int)
signal notification_requested(text: String, duration_sec: float)

## Events / seasons — new_season: int placeholder — update to SeasonSystem.Season when SeasonSystem epic story-001 is done.
signal season_changed(new_season: int)
signal event_activated(event_id: String)
signal merchant_appeared()

## Prestige
signal prestige_executed(new_prestige_count: int)

## Guild
signal guild_contribution_submitted(amount: int)
signal guild_boss_attacked(damage: int)

## Food (ADR-0009)
signal food_harvested(food_id: String, quantity: int)
signal food_used(food_id: String)
signal farm_plots_updated()
