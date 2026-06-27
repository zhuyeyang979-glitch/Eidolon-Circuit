extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const LegalStarterBlueprintFixture := preload("res://tools/fixtures/legal_starter_blueprint_fixture.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _maker_for(main, slot_key: String, part_index: int) -> String:
	var part: Dictionary = main._selected_component("hero", slot_key, part_index)
	return String(part.get("maker", part.get("manufacturer", ""))).strip_edges()


func _different_maker_part(main, slot_key: String, source_part_index: int) -> int:
	var source_maker := _maker_for(main, slot_key, source_part_index)
	for i in range(main._catalog_for("hero", slot_key).size()):
		var maker := _maker_for(main, slot_key, i)
		if maker != "" and source_maker != "" and maker != source_maker:
			return i
	return -1


func _has_code(report: Dictionary, code: String) -> bool:
	return Array(report.get("blocking_codes", [])).has(code)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var legal_bp := LegalStarterBlueprintFixture.build(main, "Topology Manufacturer Gate Legal")
	_require(not legal_bp.is_empty(), "Could not build legal starter fixture.")
	if failed:
		quit(1)
		return
	var legal_report: Dictionary = main._unit_editor_legality_report("hero", legal_bp)
	_require(bool(legal_report.get("valid", false)), "Legal starter should remain valid before maker mutation: %s" % str(legal_report))

	var mixed_bp: Dictionary = legal_bp.duplicate(true)
	var topology: Dictionary = Dictionary(mixed_bp.get("custom_topology", {})).duplicate(true)
	var nodes: Array = Array(topology.get("nodes", [])).duplicate(true)
	_require(nodes.size() >= 2 and nodes[1] is Dictionary, "Fixture should expose a connected limb node.")
	if failed:
		quit(1)
		return
	var limb_node: Dictionary = Dictionary(nodes[1]).duplicate(true)
	var replacement := _different_maker_part(main, String(limb_node.get("slot", "limb_muscle")), int(limb_node.get("part_index", 0)))
	_require(replacement >= 0, "Need a same-slot replacement from another manufacturer.")
	if failed:
		quit(1)
		return
	var replacement_part: Dictionary = main._selected_component("hero", String(limb_node.get("slot", "limb_muscle")), replacement)
	limb_node["part_index"] = replacement
	limb_node["part_name"] = String(replacement_part.get("name", ""))
	nodes[1] = limb_node
	topology["nodes"] = nodes
	mixed_bp["custom_topology"] = topology

	var mixed_report: Dictionary = main._unit_editor_legality_report("hero", mixed_bp)
	_require(not bool(mixed_report.get("valid", true)), "Mixed live topology manufacturers should be rejected: %s" % str(mixed_report))
	_require(_has_code(mixed_report, "construct_body_mixed_manufacturer"), "Mixed live topology should report construct_body_mixed_manufacturer: %s" % str(mixed_report))

	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_TOPOLOGY_MANUFACTURER_GATE_PROBE ok")
	quit(0)
