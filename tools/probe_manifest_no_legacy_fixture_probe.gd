extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var manifest_text := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://tools/probe_manifest.json"))
	if manifest_text == "":
		_fail("Missing probe manifest.")
	var parsed = JSON.parse_string(manifest_text)
	if not (parsed is Dictionary):
		_fail("Probe manifest is not a JSON object.")
	var manifest: Dictionary = parsed
	for section in ["core", "current", "legacy_rejection", "manual_visual", "obsolete_review"]:
		if not manifest.has(section):
			_fail("Probe manifest missing section %s." % section)
	var governed := []
	for entry in Array(manifest.get("current", [])):
		var name := String(entry)
		if name.ends_with(".ps1") or name.contains(" "):
			continue
		if not name.ends_with(".gd"):
			name = "%s.gd" % name
		var path := "res://tools/%s" % name
		if not governed.has(path):
			governed.append(path)
	var forbidden := ["body_move_speed", "thruster_momentum", "brake_efficiency", "recoil_cancel", "joint_power", "engine_motion_scale"]
	for path in governed:
		var text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))
		if text == "":
			continue
		for token in forbidden:
			if text.find(String(token)) >= 0:
				_fail("%s contains legacy fixture token %s." % [path, String(token)])
	for entry in Array(manifest.get("legacy_rejection", [])):
		var legacy_name := String(entry)
		if not legacy_name.ends_with(".gd"):
			legacy_name = "%s.gd" % legacy_name
		var legacy_path := "res://tools/%s" % legacy_name
		if FileAccess.file_exists(legacy_path):
			continue
		if ["drive_legacy_rejection_probe.gd", "drive_legacy_saved_unit_rejection_probe.gd", "legacy_pointer_rejection_probe.gd"].has(legacy_name):
			continue
		_fail("Legacy rejection probe missing: %s." % legacy_path)
	print("PROBE_MANIFEST_NO_LEGACY_FIXTURE_PROBE ok current=%d sections=%d" % [governed.size(), manifest.keys().size()])
	quit()
