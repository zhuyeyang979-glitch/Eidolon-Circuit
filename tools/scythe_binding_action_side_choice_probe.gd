extends SceneTree

const Helpers := preload("res://tools/scythe_link_probe_helpers.gd")


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
	var scythe: int = int(setup.get("scythe", -1))
	var module_index: int = int(setup.get("module", -1))
	if not Helpers.select_scythe_binding_target(main, unit_bp, scythe, module_index):
		_fail("Could not select scythe binding target.")
		return
	if not bool(main.editor_pending_module_binding.get("side_mount_action_required", false)):
		_fail("Scythe binding did not require an action-side choice.")
		return
	if String(main.editor_pending_module_binding.get("side_mount_action_side", "")) != "":
		_fail("Scythe action side should not be preselected before player choice.")
		return
	main._refresh_torso_detail_view()
	if main.editor_torso_detail_view == null or not bool(main.editor_torso_detail_view.binding_action_side_required):
		_fail("Torso detail binding panel did not show action-side choice.")
		return
	if bool(main.editor_torso_detail_view.binding_key_ready):
		_fail("Attack key should not be ready before action side is selected.")
		return
	main._select_torso_detail_binding_action_side("left")
	if String(main.editor_pending_module_binding.get("side_mount_action_side", "")) != "left":
		_fail("Action-side selection did not write pending binding side.")
		return
	main._refresh_torso_detail_view()
	if not bool(main.editor_torso_detail_view.binding_key_ready):
		_fail("Attack key should become ready after action side is selected.")
		return
	print("SCYTHE_BINDING_ACTION_SIDE_CHOICE_PROBE ok")
	quit(0)
