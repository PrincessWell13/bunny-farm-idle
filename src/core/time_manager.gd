## TimeManager — game clock and offline-delta calculator.
## Autoload #2. Starts a 1-second tick timer in _ready().
## SaveSystem calls mark_session_start() after loading the save file.
## See ADR-0001 for boot sequence and ownership rules.
class_name TimeManager extends Node

## Emitted every 1 second by the internal Timer. delta is always 1.0 in
## normal play; float type preserved for future slow-device adaptation.
signal tick(delta: float)

var _offline_delta: float = 0.0
var _game_epoch: int = 0
## Set true by NOTIFICATION_APPLICATION_PAUSED (mobile background).
## Cleared by NOTIFICATION_APPLICATION_FOCUS_IN or reset_backgrounded().
var _backgrounded: bool = false

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)

## Called by SaveSystem immediately after load_game().
## last_seen_timestamp: the Unix timestamp stored in the save file (0 = first boot).
## Calculates offline delta and stores it for IdleProductionSystem to consume.
func mark_session_start(last_seen_timestamp: int) -> void:
	if last_seen_timestamp <= 0:
		_offline_delta = 0.0
		return
	_offline_delta = float(Time.get_unix_time_from_system() - last_seen_timestamp)
	if _offline_delta < 0.0:
		_offline_delta = 0.0

## Returns elapsed seconds since last session end. 0.0 if mark_session_start
## has not been called yet, or if this is the first boot.
func get_offline_delta() -> float:
	return _offline_delta

## Returns the current Unix timestamp as int.
func get_unix_time() -> int:
	return int(Time.get_unix_time_from_system())

## Returns the in-game day number relative to the game epoch.
## Day 0 = the day the game was first installed (epoch second).
## SaveSystem sets the epoch via set_game_epoch() on load.
func get_current_day() -> int:
	return (int(Time.get_unix_time_from_system()) - _game_epoch) / 86400

## Called by SaveSystem once after load_game(). epoch is the Unix timestamp
## of the player's first session (stored in the save file).
func set_game_epoch(epoch: int) -> void:
	_game_epoch = epoch

## Handles mobile app lifecycle and desktop window focus notifications.
## NOTIFICATION_APPLICATION_PAUSED: mobile app sent to background.
## NOTIFICATION_APPLICATION_FOCUS_IN: app returned to foreground (mobile + desktop).
## NOTIFICATION_WM_WINDOW_FOCUS_OUT: desktop window lost focus (does not set _backgrounded
## — desktop idle continues at full rate per GDD; only mobile background is penalised).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_backgrounded = true
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_backgrounded = false


## Returns true if the app was backgrounded (minimised on mobile) since last reset.
## SaveSystem reads this during boot to pass to IdleProductionSystem.calculate_offline_earnings().
func was_backgrounded() -> bool:
	return _backgrounded


## Called by SaveSystem after consuming the backgrounded flag so it does not
## persist into the next offline calculation.
func reset_backgrounded() -> void:
	_backgrounded = false


func _on_tick() -> void:
	tick.emit(1.0)
