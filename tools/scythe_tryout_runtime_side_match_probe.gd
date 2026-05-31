extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main := Helpers.setup_main(self)
	var setup: Dictionary = Helpers.build_torso_limb_scythe_module(main, "right")
	if setup.is_empty():
		_fail("Could not build scythe module test unit.")
		return
	var unit_bp: Dictionary = setup.get("unit_bp", {})
	if not Helpers.bind_scythe_action_side(main, unit_bp, int(setup.get("scythe", -1)), int(setup.get("module", -1)), "left", 1):
		_fail("Could not bind scythe action side.")
		return
	var runtime: Array = main._runtime_module_bindings_for_blueprint("hero", unit_bp)
	if runtime.size() != 1 or not (runtime[0] is Dictionary):
		_fail("Runtime binding missing.")
		return
	var runtime_binding: Dictionary = runtime[0]
	if not main._tryout_editor_bound_module(1):
		_fail("Editor tryout failed for bound scythe module.")
		return
	if String(main.editor_bound_module_tryout.get("side_mount_action_side", "")) != String(runtime_binding.get("side_mount_action_side", "")):
		_fail("Editor tryout side does not match runtime binding.")
		return
	var stats: Dictionary = main._compute_unit_stats(1, "hero", -1, unit_bp)
	var fighter = FighterScene.new()
	root.add_child(fighter)
	fighter._ready()
	fighter.setup_unit({"unit_name": "Scythe Side Match", "owner_id": 1, "role": "hero", "stats": stats})
	fighter.deploy(0.0, 0.0)
	var event: Dictionary = fighter.begin_runtime_module_action("normal", runtime_binding, Vector2.RIGHT)
	if event.is_empty():
		_fail("Runtime scythe action did not start.")
		return
	if fighter.runtime_module_actions.is_empty():
		_fail("Runtime module action list missing started scythe action.")
		return
	var action: Dictionary = fighter.runtime_module_actions[fighter.runtime_module_actions.size() - 1]
	var action_binding: Dictionary = action.get("binding", {}) if action.get("binding", {}) is Dictionary else {}
	if String(action_binding.get("side_mount_action_side", "")) != "left":
		_fail("Runtime action did not receive side_mount_action_side=left.")
		return
	fighter.queue_free()
	print("SCYTHE_TRYOUT_RUNTIME_SIDE_MATCH_PROBE ok")
	quit(0)
