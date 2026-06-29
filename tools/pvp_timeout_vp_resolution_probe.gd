extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _init() -> void:
	_check_vp_leader_wins_timeout()
	_check_tied_vp_uses_health_fallback()
	if failed:
		quit(1)
		return
	print("PVP_TIMEOUT_VP_RESOLUTION_PROBE ok")
	quit(0)


func _check_vp_leader_wins_timeout() -> void:
	var main = _new_pvp_battle("pvp_timeout_vp_resolution_probe_vp")
	main.victory_points = {1: 1, 2: 3}
	_set_player_health(main, 1, 1.0)
	_set_player_health(main, 2, 0.05)
	main._resolve_timeout()
	_require(bool(main.game_over), "Timeout should end the battle.")
	_require(int(main.post_battle_review_winner_id) == 2, "Higher VP should decide timeout winner even with lower remaining health.")
	_require(String(main.post_battle_review_reason) == "timeout", "Timeout winner should preserve post-battle reason.")
	_require(main.post_battle_review_panel != null and bool(main.post_battle_review_panel.visible), "Timeout should open post-battle review panel.")


func _check_tied_vp_uses_health_fallback() -> void:
	var main = _new_pvp_battle("pvp_timeout_vp_resolution_probe_tie")
	main.victory_points = {1: 2, 2: 2}
	_set_player_health(main, 1, 0.15)
	_set_player_health(main, 2, 1.0)
	main._resolve_timeout()
	_require(bool(main.game_over), "Tied VP timeout should still end the battle.")
	_require(int(main.post_battle_review_winner_id) == 2, "Tied VP should use remaining health as timeout fallback.")


func _new_pvp_battle(reason: String):
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._begin_battle(MainScene.MODE_PVP, true, reason)
	main.match_time_remaining = 0.0
	return main


func _set_player_health(main, player_id: int, ratio: float) -> void:
	var hero = main.active_units[player_id]["hero"]
	if hero != null and is_instance_valid(hero):
		hero.max_health = 100
		hero.health = maxi(1, int(roundf(100.0 * clampf(ratio, 0.01, 1.0))))
	var barrier = main.active_units[player_id]["barrier"]
	if barrier != null and is_instance_valid(barrier):
		barrier.max_health = 100
		barrier.health = maxi(1, int(roundf(100.0 * clampf(ratio, 0.01, 1.0))))
	for unit in Array(main.active_units[player_id]["puppet"]):
		if unit != null and is_instance_valid(unit):
			unit.max_health = 100
			unit.health = maxi(1, int(roundf(100.0 * clampf(ratio, 0.01, 1.0))))


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
