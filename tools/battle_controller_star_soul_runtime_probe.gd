extends SceneTree

const BattleControllerScript := preload("res://scripts/controllers/battle_controller.gd")
const BPService := preload("res://scripts/services/star_soul_bp_service.gd")

var failed := false


func _init() -> void:
	var controller = BattleControllerScript.new()
	var bp_service = BPService.new()
	var catalog: Dictionary = bp_service.catalog_by_id()
	var payload: Dictionary = bp_service.build_spawn_queue([
		{"player": 1, "star_soul_id": "defense_tower_c"},
		{"player": 2, "star_soul_id": "punishment_tower_a"},
	], 1, 1, {"pool_ids": catalog.keys(), "announce_seconds": 10.0})
	_require(bool(payload.get("valid", false)), "Draft payload should be valid.")
	var start_state: Dictionary = controller.start_star_soul_runtime(payload, catalog, {"replay_seed": 99})
	_require(String(start_state.get("phase", "")) == "announcing", "Controller should start Star Soul runtime in announcing phase.")
	_require(int(start_state.get("replay_seed", 0)) == 99, "Controller should preserve Star Soul replay seed.")
	var ready: Dictionary = controller.tick_star_soul_runtime(10.0)
	_require(String(Dictionary(ready.get("state", {})).get("phase", "")) == "spawn_ready", "Controller tick should advance countdown to spawn_ready.")
	var committed: Dictionary = controller.commit_star_soul_spawn("ctrl_star_soul_a")
	_require(bool(committed.get("changed", false)), "Controller should commit pending Star Soul spawn.")
	_require(String(Dictionary(controller.star_soul_hud_snapshot().get("active_entry", {})).get("runtime_id", "")) == "ctrl_star_soul_a", "Controller HUD snapshot should expose active Star Soul.")
	var blocked: Dictionary = controller.commit_star_soul_spawn("ctrl_star_soul_b")
	_require(not bool(blocked.get("changed", true)), "Controller should not spawn a second Star Soul while active.")
	var destroyed: Dictionary = controller.exit_active_star_soul("destroyed", "ctrl_star_soul_a")
	_require(bool(destroyed.get("changed", false)), "Controller should process active Star Soul exit.")
	var vp_by_player: Dictionary = Dictionary(Dictionary(destroyed.get("state", {})).get("vp_by_player", {}))
	_require(int(vp_by_player.get(2, 0)) == 3, "Destroying P1 Star Soul should award P2 VP.")
	controller.clear_star_soul_runtime()
	_require(controller.star_soul_runtime_snapshot().is_empty(), "Controller should clear Star Soul runtime state.")

	if failed:
		quit(1)
		return
	print("BATTLE_CONTROLLER_STAR_SOUL_RUNTIME_PROBE ok")
	quit(0)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
