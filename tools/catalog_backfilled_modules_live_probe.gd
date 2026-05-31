extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _module_part(main, name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", "module", name)
	if index < 0:
		_fail("Missing module catalog part: %s" % name)
		return {}
	return main._selected_component("hero", "module", index)


func _assert_live_module(main, name: String, expected_profile: String, expected_target: String) -> void:
	var part := _module_part(main, name)
	if part.is_empty():
		return
	if not bool(part.get("catalog_backfilled_live", false)):
		_fail("%s was not marked as backfilled live." % name)
	if String(part.get("module_action_profile", "")) != expected_profile:
		_fail("%s profile expected %s, got %s." % [name, expected_profile, String(part.get("module_action_profile", ""))])
	if String(part.get("module_target_kind", "")) != expected_target:
		_fail("%s target expected %s, got %s." % [name, expected_target, String(part.get("module_target_kind", ""))])
	var lifecycle: Dictionary = main._catalog_lifecycle_for_part("module", part)
	if String(lifecycle.get("catalog_lifecycle", "")) != "live":
		_fail("%s should be live after backfill, got %s / %s." % [name, String(lifecycle.get("catalog_lifecycle", "")), String(lifecycle.get("reason", ""))])
	if main._part_is_catalog_frozen("module", part):
		_fail("%s is still reported frozen." % name)
	if String(part.get("future_dev_tag", "")) != "":
		_fail("%s still exposes future_dev_tag." % name)


func _assert_frozen_module(main, name: String, expected_tag: String = "") -> void:
	var part := _module_part(main, name)
	if part.is_empty():
		return
	var lifecycle: Dictionary = main._catalog_lifecycle_for_part("module", part)
	if String(lifecycle.get("catalog_lifecycle", "")) != "frozen":
		_fail("%s should remain frozen." % name)
	if String(lifecycle.get("reason", "")).strip_edges() == "":
		_fail("%s frozen lifecycle lacks reason." % name)
	if expected_tag != "" and String(lifecycle.get("future_dev_tag", "")) != expected_tag:
		_fail("%s future tag expected %s, got %s." % [name, expected_tag, String(lifecycle.get("future_dev_tag", ""))])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	_assert_live_module(main, "COMBO ROUTER: BALANCE STRING", "swing_180", "ball_joint")
	_assert_live_module(main, "CLAMP ROUTER: VISE CLOSE", "inward_pincer_clamp", "dual_ball_joint")
	_assert_live_module(main, "ROUTE ROUTER: PICKUP DASH", "swing_180", "ball_joint")
	_assert_live_module(main, "MONSTER ROUTER: CRUSH WINDUP", "swing_180", "ball_joint")
	_assert_live_module(main, "DUEL ROUTER: FEINT THRUST", "rapier_feint_thrust", "telescopic_joint")
	_assert_live_module(main, "SALVO ROUTER: EXPLOSIVE ARC", "grenade_arc_activate", "gun_terminal")
	_assert_frozen_module(main, "GUNNER WRIST: QE MANUAL SWEEP", "future_dynamic_gun_profile")
	_assert_frozen_module(main, "RECOIL LOCK: BRACED GUN SWEEP", "future_dynamic_gun_profile")
	_assert_frozen_module(main, "TETHER CAST: AUTOSWING EJECT", "future_throw_receiver_system")
	_assert_frozen_module(main, "HIJACK ROUTER: PIN AND INSERT", "future_takeover_system")
	print("CATALOG_BACKFILLED_MODULES_LIVE_PROBE ok")
	quit()
