extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const ProbeLib := preload("res://tools/boot_driver_probe_lib.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _first_terminal(main, predicate: Callable) -> int:
	return ProbeLib.first_part(main, func(part: Dictionary) -> bool:
		return main._part_counts_as_terminal_weapon(part, "muscle") and predicate.call(part)
	)


func _reason_for_fixture(main, fixture: Dictionary, target_nodes: Array) -> String:
	var unit_bp: Dictionary = fixture["unit_bp"]
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var module_part: Dictionary = main._selected_component("hero", "module", int(fixture["module_index"]))
	return main._boot_driver_invalid_reason_for_nodes("hero", unit_bp, Array(topology.get("nodes", [])), Array(topology.get("edges", [])), target_nodes, module_part)


func _assert_invalid(main, label: String, terminal_index: int) -> void:
	var fixture := ProbeLib.build_fixture(main, terminal_index, -1, false)
	var nodes := [int(fixture["limb"]), int(fixture["weapon"])]
	var reason := _reason_for_fixture(main, fixture, nodes)
	if reason == "":
		_fail("%s should be an invalid Boot Driver binding." % label)
	var unit_bp: Dictionary = fixture["unit_bp"]
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var module_part: Dictionary = main._selected_component("hero", "module", int(fixture["module_index"]))
	var resolved: Array = main._boot_driver_binding_nodes_for_selection("hero", unit_bp, Array(topology.get("nodes", [])), Array(topology.get("edges", [])), [int(fixture["limb"])], module_part)
	if not resolved.is_empty():
		_fail("%s unexpectedly resolved as Boot Driver binding nodes: %s" % [label, str(resolved)])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	ProbeLib.prepare_main(main)
	var shield_index := _first_terminal(main, func(part: Dictionary) -> bool:
		return bool(part.get("blunt_shield", false))
	)
	var ranged_index := _first_terminal(main, func(part: Dictionary) -> bool:
		return bool(part.get("projectile", false))
	)
	var non_blunt_index := _first_terminal(main, func(part: Dictionary) -> bool:
		return String(part.get("damage_type", "")).to_lower() in ["pierce", "tear"] and not bool(part.get("projectile", false))
	)
	if shield_index < 0 or ranged_index < 0 or non_blunt_index < 0:
		_fail("Missing invalid Boot Driver fixture parts.")
		return
	_assert_invalid(main, "no-extension blunt shield", shield_index)
	_assert_invalid(main, "ranged projectile weapon", ranged_index)
	_assert_invalid(main, "non-blunt melee terminal", non_blunt_index)

	var legal := ProbeLib.build_fixture(main, -1, -1, false)
	var torso_reason := _reason_for_fixture(main, legal, [int(legal["torso"]), int(legal["weapon"])])
	if not torso_reason.contains("root"):
		_fail("Torso root should be rejected, got: %s" % torso_reason)
	var joint_fixture := ProbeLib.build_fixture(main, -1, -1, false)
	var joint_unit: Dictionary = joint_fixture["unit_bp"]
	var topology: Dictionary = joint_unit.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", []))
	var joint_node := {"id": nodes.size(), "label": "JOINT", "slot": "joint", "part_index": 0, "pos": Vector2(0.5, 0.5)}
	nodes.append(joint_node)
	topology["nodes"] = nodes
	joint_unit["custom_topology"] = topology
	joint_fixture["unit_bp"] = joint_unit
	var joint_reason := _reason_for_fixture(main, joint_fixture, [int(joint_node["id"]), int(joint_fixture["weapon"])])
	if not joint_reason.contains("root"):
		_fail("Standalone joint root should be rejected, got: %s" % joint_reason)

	var two_limb := ProbeLib.build_two_limb_fixture(main)
	var two_limb_reason := _reason_for_fixture(main, two_limb, [int(two_limb["limb_a"]), int(two_limb["limb_b"])])
	if not two_limb_reason.contains("weapon"):
		_fail("Two ordinary limbs should be rejected as missing telescopic blunt terminal, got: %s" % two_limb_reason)
	print("BOOT_DRIVER_INVALID_BINDING_PROBE ok")
	quit()
