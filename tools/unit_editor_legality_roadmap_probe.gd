extends SceneTree

const ROADMAP_PATH := "res://docs/plans/2026-06-24-unit-editor-legality-roadmap.md"
const MAIN_PATH := "res://scripts/main.gd"

var failed := false


func _fail(message: String) -> void:
	failed = true
	push_error(message)


func _require(text: String, token: String, label: String) -> void:
	if text.find(token) < 0:
		_fail("%s missing token: %s" % [label, token])


func _init() -> void:
	var roadmap := FileAccess.get_file_as_string(ROADMAP_PATH)
	for rule in [
		"at least one hardware part",
		"One compatible part per matching slot/socket",
		"Part size is less than or equal to slot capacity",
		"Every construct body uses hardware from one manufacturer",
		"Hero requires exactly one Soul",
		"Puppet requires at least one Source Code",
		"Barrier requires Ether",
	]:
		_require(roadmap, rule, "legality roadmap")
	for owner in [
		"scripts/services/unit_editor_legality_service.gd",
		"scripts/main.gd::_training_blueprint_illegal_note()",
		"tools/role_identity_software_rejection_probe.gd",
		"tools/unit_editor_socket_size_rejection_probe.gd",
		"tools/unit_editor_topology_socket_size_gate_probe.gd",
		"tools/construct_body_manufacturer_rejection_probe.gd",
		"tools/unit_editor_puppet_source_code_main_gate_probe.gd",
		"tools/unit_editor_barrier_ether_main_gate_probe.gd",
		"tools/unit_editor_legality_team_validation_probe.gd",
		"tools/unit_editor_legality_battle_entry_probe.gd",
		"tools/unit_editor_legality_formal_entry_probe.gd",
		"tools/unit_editor_legality_combined_rule_probe.gd",
		"tools/unit_editor_legality_preview_slot_kind_probe.gd",
		"tools/unit_editor_legality_cross_entrypoint_probe.gd",
		"tools/ai_entry_probe.gd",
	]:
		_require(roadmap, owner, "legality roadmap")
	for evidence in [
		"tools/unit_library_legality_gate_probe.gd",
		"tools/editor_endpoint_socket_probe.gd",
		"tools/drag_connected_no_resnap_probe.gd",
		"tools/torso_slot_capacity_plus_one_probe.gd",
	]:
		_require(roadmap, evidence, "legality roadmap")

	var main_source := FileAccess.get_file_as_string(MAIN_PATH)
	for gate in [
		"func _training_blueprint_illegal_note",
		"func _prepare_editor_canvas_training_import",
		"func _unit_library_save_audit",
		"func _saved_unit_entry_illegal_note",
		"func _topology_rule_note",
		"func _unit_editor_legality_topology_socket_size_records",
		"func _unit_editor_legality_topology_socket_kind_records",
		"func _unit_editor_legality_preview_model",
		"unit_legality_note",
		"func _formal_battle_start_blocking_summary",
	]:
		_require(main_source, gate, "main legality gate")
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_LEGALITY_ROADMAP_PROBE ok")
	quit(0)
