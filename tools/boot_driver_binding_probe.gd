extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const ProbeLib := preload("res://tools/boot_driver_probe_lib.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	ProbeLib.prepare_main(main)
	var fixture := ProbeLib.build_fixture(main, -1, -1, false)
	var unit_bp: Dictionary = fixture["unit_bp"]
	var module_index := int(fixture["module_index"])
	var limb := int(fixture["limb"])
	var weapon := int(fixture["weapon"])
	var module_part: Dictionary = main._selected_component("hero", "module", module_index)
	main.editor_working_blueprint = unit_bp
	main._start_editor_module_binding_flow(0, module_part)
	var limb_candidate: Dictionary = main._pending_module_binding_candidate_for_node(unit_bp, limb)
	if limb_candidate.is_empty() or not bool(limb_candidate.get("valid", false)):
		_fail("Rotating limb did not produce a valid Boot Driver candidate: %s" % str(limb_candidate))
	if String(limb_candidate.get("target_kind", "")) != "boot_driver_limb_group":
		_fail("Boot Driver candidate target kind mismatch: %s" % str(limb_candidate))
	if Array(limb_candidate.get("target_nodes", [])) != [limb, weapon]:
		_fail("Boot Driver limb candidate target nodes mismatch: %s" % str(limb_candidate))
	var weapon_candidate: Dictionary = main._pending_module_binding_candidate_for_node(unit_bp, weapon)
	if weapon_candidate.is_empty() or not bool(weapon_candidate.get("valid", false)):
		_fail("Telescopic weapon did not resolve back to the Boot Driver group: %s" % str(weapon_candidate))
	if Array(weapon_candidate.get("target_nodes", [])) != [limb, weapon]:
		_fail("Boot Driver weapon candidate target nodes mismatch: %s" % str(weapon_candidate))
	main._complete_pending_module_binding_with_selection(unit_bp, Array(weapon_candidate.get("selection", [])))
	main._set_pending_module_attack_key(1)
	var saved_bindings: Array = Array(unit_bp.get("module_bindings", []))
	if saved_bindings.size() != 1:
		_fail("Boot Driver UI binding did not save exactly one binding.")
	var saved: Dictionary = saved_bindings[0]
	if int(saved.get("module_index", -1)) != module_index or int(saved.get("attack_key", 0)) != 1:
		_fail("Boot Driver saved binding module/key mismatch: %s" % str(saved))
	if String(saved.get("target_kind", "")) != "boot_driver_limb_group" or Array(saved.get("target_nodes", [])) != [limb, weapon]:
		_fail("Boot Driver saved target mismatch: %s" % str(saved))
	if int(saved.get("boot_driver_rotating_node", -1)) != limb or int(saved.get("boot_driver_weapon_node", -1)) != weapon:
		_fail("Boot Driver saved derived nodes mismatch: %s" % str(saved))
	if not is_equal_approx(float(saved.get("boot_driver_extension_m", 0.0)), 2.0):
		_fail("Boot Driver saved extension should come from standard gauntlet: %s" % str(saved))
	var topology: Dictionary = unit_bp.get("custom_topology", {})
	var nodes: Array = Array(topology.get("nodes", []))
	if not Array(Dictionary(nodes[limb]).get("modules", [])).has(module_index):
		_fail("Boot Driver module was not attached to the rotating limb node.")
	var runtime_bindings: Array = main._runtime_module_bindings_for_blueprint("hero", unit_bp)
	if runtime_bindings.size() != 1:
		_fail("Expected one Boot Driver runtime binding, got %d." % runtime_bindings.size())
	var runtime: Dictionary = runtime_bindings[0]
	if not bool(runtime.get("runtime_valid", false)):
		_fail("Boot Driver runtime binding invalid: %s" % String(runtime.get("binding_valid_note", "")))
	if String(runtime.get("module_action_profile", "")) != "boot_action_driver" or Array(runtime.get("target_nodes", [])) != [limb, weapon]:
		_fail("Boot Driver runtime binding payload mismatch: %s" % str(runtime))
	if not is_equal_approx(float(runtime.get("boot_driver_extension_m", 0.0)), 2.0):
		_fail("Boot Driver runtime extension mismatch: %s" % str(runtime))
	print("BOOT_DRIVER_BINDING_PROBE ok nodes=%s" % str(runtime.get("target_nodes", [])))
	quit()
