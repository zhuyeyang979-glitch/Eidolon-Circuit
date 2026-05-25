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
		_fail("Missing headed gate or probe manifest.")
	if gate_text.find("probe_manifest.json") < 0 or gate_text.find("ConvertFrom-Json") < 0:
		_fail("Headed gate should read probe_manifest.json as its probe source.")
	for stale_probe in ["navigation_service_contract_probe", "teamedit_probe", "startup_loading_stage_probe"]:
		if gate_text.find("\"%s\"" % stale_probe) >= 0:
			_fail("Headed gate should not hard-code probe name: %s" % stale_probe)
	var parsed = JSON.parse_string(manifest_text)
	if not (parsed is Dictionary):
		_fail("Probe manifest is not JSON object.")
	var manifest: Dictionary = parsed
	if not (manifest.get("headed_gate", {}) is Dictionary):
		_fail("Probe manifest missing headed_gate section.")
	var headed_gate: Dictionary = manifest.get("headed_gate", {})
	for group in ["navigation_menu", "unit_edit", "loading_first_interaction"]:
		if not headed_gate.has(group):
			_fail("Probe manifest headed_gate missing group: %s" % group)
		var manifest_names := Array(headed_gate.get(group, []))
		if manifest_names.is_empty():
			_fail("Probe manifest headed_gate group is empty: %s" % group)
	if gate_text.find("-Headless") >= 0:
		_fail("Headed gate must not invoke -Headless.")
	print("HEADED_GATE_MANIFEST_ALIGNMENT_PROBE ok groups=3")
	quit(0)
