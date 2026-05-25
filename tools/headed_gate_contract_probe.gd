extends SceneTree

const GATE_PATH := "res://tools/run_headed_gate.ps1"
const MANIFEST_PATH := "res://tools/probe_manifest.json"


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _require(text: String, token: String) -> void:
	if text.find(token) < 0:
		_fail("Headed gate script missing token: %s" % token)


func _init() -> void:
	var path := ProjectSettings.globalize_path(GATE_PATH)
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		_fail("Missing headed gate script.")
	var manifest_text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MANIFEST_PATH))
	var parsed = JSON.parse_string(manifest_text)
	if not (parsed is Dictionary):
		_fail("Probe manifest is missing or invalid.")
	var headed_gate: Dictionary = Dictionary(parsed).get("headed_gate", {})
	for group in ["navigation_menu", "unit_edit", "loading_first_interaction"]:
		if not headed_gate.has(group) or Array(headed_gate.get(group, [])).is_empty():
			_fail("Probe manifest headed_gate missing group: %s" % group)
		_require(text, group)
	_require(text, "probe_manifest.json")
	_require(text, "ConvertFrom-Json")
	if text.find("-Headed") < 0:
		_fail("Headed gate must force -Headed low-level runs.")
	if text.find("-Headless") >= 0:
		_fail("Headed gate must not invoke -Headless.")
	if text.find("-CheckOnly") < 0:
		_fail("Headed gate should include headed check-only.")
	print("HEADED_GATE_CONTRACT_PROBE ok")
	quit(0)
