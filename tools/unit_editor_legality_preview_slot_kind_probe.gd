extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const UnitEditorLegalityService := preload("res://scripts/services/unit_editor_legality_service.gd")
const LegalStarterBlueprintFixture := preload("res://tools/fixtures/legal_starter_blueprint_fixture.gd")

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _has_code(report: Dictionary, code: String) -> bool:
	return Array(report.get("blocking_codes", [])).has(code)


func _slot_kind_blueprint(records: Array) -> Dictionary:
	return {
		"role": "hero",
		"special": -1,
		"slot_payloads": [{"kind": "soul"}],
		"socket_kind_records": records.duplicate(true),
	}


func _init() -> void:
	var service = UnitEditorLegalityService.new()
	_require(service.has_method("audit_socket_kinds"), "UnitEditorLegalityService should own exact socket-kind auditing.")
	if not service.has_method("audit_socket_kinds"):
		quit(1)
		return

	var not_owned_report: Dictionary = service.audit_socket_kinds(_slot_kind_blueprint([
		{
			"edge_id": "not_owned",
			"a_node_index": 0,
			"a_part_slot_kind": "muscle",
			"a_socket_kind": "distal",
			"a_owned_socket_kinds": ["root_joint"],
			"b_node_index": 1,
			"b_part_slot_kind": "muscle",
			"b_socket_kind": "root_joint",
			"b_owned_socket_kinds": ["root_joint"],
		},
	]))
	_require(_has_code(not_owned_report, "socket_kind_not_owned"), "Unowned socket kind should be rejected: %s" % str(not_owned_report))

	var pair_report: Dictionary = service.audit_socket_kinds(_slot_kind_blueprint([
		{
			"edge_id": "pair_mismatch",
			"a_node_index": 0,
			"a_part_slot_kind": "limb_muscle",
			"a_socket_kind": "root_joint",
			"a_owned_socket_kinds": ["root_joint", "distal"],
			"b_node_index": 1,
			"b_part_slot_kind": "muscle",
			"b_socket_kind": "root_joint",
			"b_owned_socket_kinds": ["root_joint"],
		},
	]))
	_require(_has_code(pair_report, "socket_pair_kind_mismatch"), "Root-to-root socket pair should be rejected: %s" % str(pair_report))

	var occupancy_report: Dictionary = service.audit_socket_kinds(_slot_kind_blueprint([
		{
			"edge_id": "occupied_a",
			"a_node_index": 0,
			"a_part_slot_kind": "limb_muscle",
			"a_socket_kind": "distal",
			"a_owned_socket_kinds": ["root_joint", "distal"],
			"b_node_index": 1,
			"b_part_slot_kind": "muscle",
			"b_socket_kind": "root_joint",
			"b_owned_socket_kinds": ["root_joint"],
		},
		{
			"edge_id": "occupied_b",
			"a_node_index": 0,
			"a_part_slot_kind": "limb_muscle",
			"a_socket_kind": "distal",
			"a_owned_socket_kinds": ["root_joint", "distal"],
			"b_node_index": 2,
			"b_part_slot_kind": "muscle",
			"b_socket_kind": "root_joint",
			"b_owned_socket_kinds": ["root_joint"],
		},
	]))
	_require(_has_code(occupancy_report, "socket_multiple_occupancy"), "Repeated socket ownership should be rejected: %s" % str(occupancy_report))

	var valid_report: Dictionary = service.audit_socket_kinds(_slot_kind_blueprint([
		{
			"edge_id": "valid",
			"a_node_index": 0,
			"a_part_slot_kind": "muscle",
			"a_socket_kind": "torso_port:0",
			"a_owned_socket_kinds": ["torso_port:0"],
			"b_node_index": 1,
			"b_part_slot_kind": "limb_muscle",
			"b_socket_kind": "root_joint",
			"b_owned_socket_kinds": ["root_joint", "distal"],
		},
	]))
	_require(bool(valid_report.get("valid", false)), "Torso-port to root-joint pair should remain legal: %s" % str(valid_report))

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var legal_bp := LegalStarterBlueprintFixture.build(main, "Socket Kind Preview Legal")
	_require(not legal_bp.is_empty(), "Could not build legal live-topology fixture.")
	if not legal_bp.is_empty():
		var legal_main_report: Dictionary = main._unit_editor_legality_report("hero", legal_bp)
		_require(bool(legal_main_report.get("valid", false)), "Legal live topology should remain valid: %s" % str(legal_main_report))
		var invalid_topology_bp: Dictionary = legal_bp.duplicate(true)
		var topology: Dictionary = Dictionary(invalid_topology_bp.get("custom_topology", {})).duplicate(true)
		var edges: Array = Array(topology.get("edges", [])).duplicate(true)
		_require(not edges.is_empty(), "Legal live-topology fixture should contain at least one edge.")
		if not edges.is_empty() and edges[0] is Dictionary:
			var damaged_edge: Dictionary = Dictionary(edges[0]).duplicate(true)
			damaged_edge["a_socket"] = "center"
			edges[0] = damaged_edge
			topology["edges"] = edges
			invalid_topology_bp["custom_topology"] = topology
			var invalid_topology_report: Dictionary = main._unit_editor_legality_report("hero", invalid_topology_bp)
			_require(_has_code(invalid_topology_report, "socket_kind_not_owned"), "Live topology adapter should report socket_kind_not_owned: %s" % str(invalid_topology_report))
			var invalid_topology_note := main._training_blueprint_illegal_note(1, "hero", invalid_topology_bp)
			_require(invalid_topology_note.contains("socket_kind_not_owned"), "Training/save gate should consume the same stable socket-kind report: %s" % invalid_topology_note)
	_require(main.has_method("_unit_editor_legality_preview_model"), "Main should expose one player-facing legality preview model.")
	_require(main.get("editor_legality_status_label") != null, "Unit Editor should create a dedicated legality status label.")
	if main.has_method("_unit_editor_legality_preview_model"):
		var invalid_bp := _slot_kind_blueprint([
			{
				"edge_id": "preview_invalid",
				"a_node_index": 0,
				"a_part_slot_kind": "muscle",
				"a_socket_kind": "distal",
				"a_owned_socket_kinds": ["root_joint"],
				"b_node_index": 1,
				"b_part_slot_kind": "muscle",
				"b_socket_kind": "root_joint",
				"b_owned_socket_kinds": ["root_joint"],
			},
		])
		var preview: Dictionary = main._unit_editor_legality_preview_model("hero", invalid_bp)
		_require(not bool(preview.get("valid", true)), "Preview should expose the shared invalid report: %s" % str(preview))
		_require(String(preview.get("status_text_zh", "")).contains("受阻"), "Chinese preview should show a blocked status: %s" % str(preview))
		_require(String(preview.get("status_text_en", "")).contains("BLOCKED"), "English preview should show a blocked status: %s" % str(preview))
		_require(String(preview.get("tooltip_zh", "")).contains("socket_kind_not_owned"), "Preview tooltip should preserve stable reason codes: %s" % str(preview))

		main.editor_canvas_mode = "blank"
		main.editor_role_index = MainScene.ROLE_ORDER.find("hero")
		main.editor_working_role_key = "hero"
		main.editor_working_blueprint = invalid_bp.duplicate(true)
		main._update_editor_ui(true)
		var status_label = main.get("editor_legality_status_label")
		if status_label != null:
			_require(status_label.visible, "Legality status label should stay visible in Unit Editor.")
			_require(String(status_label.text).contains("受阻"), "Live editor status should render the invalid preview: %s" % String(status_label.text))
			_require(String(status_label.text).contains("socket_kind_not_owned"), "Live editor status should expose the primary stable reason code: %s" % String(status_label.text))

	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_LEGALITY_PREVIEW_SLOT_KIND_PROBE ok")
	quit(0)
