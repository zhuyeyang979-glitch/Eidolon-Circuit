extends SceneTree

const MainScene := preload("res://scripts/main.gd")

var failed := false


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_scout(MainScene.MODE_PVP, true)
	main._legalize_ai_player_roster(1, true)
	main._legalize_ai_player_roster(2, true)
	main._show_star_soul_bp(MainScene.MODE_PVP)
	_require(main.star_soul_bp_active, "PVP Star Soul BP should become active before battle.")
	_require(main.star_soul_bp_view != null and main.star_soul_bp_view.visible, "PVP Star Soul BP view should be visible.")
	while not Array(main.star_soul_bp_model.get("available_ids", [])).is_empty():
		var current_turn: Dictionary = Dictionary(main.star_soul_bp_model.get("current_turn", {}))
		var available_ids: Array = Array(main.star_soul_bp_model.get("available_ids", []))
		main._on_star_soul_bp_selected(int(current_turn.get("player", 1)), String(available_ids[0]))
	main._on_star_soul_bp_confirmed(1)
	main._on_star_soul_bp_confirmed(2)
	_require(not main.star_soul_bp_active, "Completing both confirmations should close BP.")
	_require(main.game_state == MainScene.STATE_BATTLE, "Completing BP should enter battle.")
	var runtime: Dictionary = main.battle_controller.star_soul_runtime_snapshot()
	_require(String(runtime.get("phase", "")) == "announcing", "Battle should begin with the first Star Soul announcement.")
	_require(int(Dictionary(runtime.get("pending_entry", {})).get("owner", 0)) == 1, "First pick player should own the first announced Star Soul.")
	_require(Array(runtime.get("queue", [])).size() == 20, "Standard BP should create a 20-entry alternating queue.")
	if failed:
		quit(1)
		return
	print("STAR_SOUL_MAIN_BP_FLOW_PROBE ok first=", Dictionary(runtime.get("pending_entry", {})).get("star_soul_id", ""))
	main.queue_free()
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
