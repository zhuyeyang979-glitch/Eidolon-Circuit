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
		"tools/construct_body_manufacturer_rejection_probe.gd",
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
	]:
		_require(main_source, gate, "main legality gate")
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_LEGALITY_ROADMAP_PROBE ok")
	quit(0)
