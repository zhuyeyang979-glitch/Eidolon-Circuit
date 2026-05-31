extends SceneTree

const GATE_PATH := "res://tools/run_headed_gate.ps1"
const MANIFEST_PATH := "res://tools/probe_manifest.json"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var gate_text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(GATE_PATH))
	var manifest_text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MANIFEST_PATH))
	if gate_text.is_empty() or manifest_text.is_empty():
		_fail("Missing headed gate or manifest.")
	for token in ["probe_manifest.json", "ConvertFrom-Json", "$Manifest.headed_gate", "$GateGroups[$groupName]"]:
		if gate_text.find(token) < 0:
			_fail("Headed gate script should read manifest source token: %s" % token)
	if gate_text.find("-Headless") >= 0:
		_fail("Headed gate must never invoke -Headless.")
	var parsed = JSON.parse_string(manifest_text)
	if not (parsed is Dictionary):
		_fail("Manifest JSON is invalid.")
	var manifest: Dictionary = parsed
	for group in ["navigation_menu", "unit_edit", "loading_first_interaction"]:
		var probes := Array(Dictionary(manifest.get("headed_gate", {})).get(group, []))
		if probes.is_empty():
			_fail("Manifest headed_gate group missing probes: %s" % group)
	for aux_group in ["ui_auxiliary", "parser_auxiliary"]:
		if not manifest.has(aux_group):
			_fail("Manifest missing auxiliary group: %s" % aux_group)
	print("HEADED_GATE_MANIFEST_SOURCE_PROBE ok")
	quit(0)
