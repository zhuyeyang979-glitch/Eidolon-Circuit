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
	if not Helpers.bind_scythe_action_side(main, unit_bp, int(setup.get("scythe", -1)), int(setup.get("module", -1)), "left", 2):
		_fail("Could not bind scythe action side.")
		return
	var bindings: Array = Array(unit_bp.get("module_bindings", []))
	if bindings.size() != 1 or not (bindings[0] is Dictionary):
		_fail("Expected exactly one saved module binding.")
		return
	var saved: Dictionary = bindings[0]
	if String(saved.get("side_mount_action_side", "")) != "left":
		_fail("Saved binding did not persist side_mount_action_side=left.")
		return
	if absf(float(saved.get("side_mount_action_angle_offset", 999.0)) + PI * 0.5) > 0.001:
		_fail("Saved binding did not persist left -90deg offset.")
		return
	var runtime: Array = main._runtime_module_bindings_for_blueprint("hero", unit_bp)
	if runtime.size() != 1 or not (runtime[0] is Dictionary):
		_fail("Runtime binding missing.")
		return
	var runtime_binding: Dictionary = runtime[0]
	if String(runtime_binding.get("side_mount_action_side", "")) != "left":
		_fail("Runtime binding did not keep side_mount_action_side.")
		return
	if absf(float(runtime_binding.get("side_mount_action_angle_offset", 999.0)) + PI * 0.5) > 0.001:
		_fail("Runtime binding did not derive left -90deg offset.")
		return
	print("SCYTHE_BINDING_ACTION_SIDE_PERSIST_PROBE ok")
	quit(0)
