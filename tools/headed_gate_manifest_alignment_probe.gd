extends SceneTree

const GATE_PATH := "res://tools/run_headed_gate.ps1"
const MANIFEST_PATH := "res://tools/probe_manifest.json"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _probe_names_for_group(text: String, group_name: String) -> Array:
	var marker := "%s = @(" % group_name
	var start := text.find(marker)
	if start < 0:
		_fail("Headed gate missing group: %s" % group_name)
	var open_index := text.find("@(", start)
	var close_index := text.find(")", open_index)
	if open_index < 0 or close_index < 0:
		_fail("Could not parse headed gate group: %s" % group_name)
	var body := text.substr(open_index + 2, close_index - open_index - 2)
	var names := []
	for raw_line in body.split("\n"):
		var line := String(raw_line).strip_edges()
		line = line.trim_suffix(",").strip_edges()
		if line.begins_with("\"") and line.ends_with("\""):
			names.append(line.trim_prefix("\"").trim_suffix("\""))
	return names


func _init() -> void:
	var gate_text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(GATE_PATH))
	var manifest_text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MANIFEST_PATH))
	if gate_text.is_empty() or manifest_text.is_empty():
		_fail("Missing headed gate or probe manifest.")
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
		var gate_names := _probe_names_for_group(gate_text, group)
		var manifest_names := Array(headed_gate.get(group, []))
		if gate_names.size() != manifest_names.size():
			_fail("%s gate/manifest count mismatch. gate=%d manifest=%d" % [group, gate_names.size(), manifest_names.size()])
		for i in range(gate_names.size()):
			if String(manifest_names[i]) != String(gate_names[i]):
				_fail("%s mismatch at %d. gate=%s manifest=%s" % [group, i, String(gate_names[i]), String(manifest_names[i])])
	if gate_text.find("-Headless") >= 0:
		_fail("Headed gate must not invoke -Headless.")
	print("HEADED_GATE_MANIFEST_ALIGNMENT_PROBE ok groups=3")
	quit(0)
