extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var source := FileAccess.get_file_as_string("res://tools/run_godot_checked.ps1")
	if source.is_empty():
		_fail("Unable to read run_godot_checked.ps1.")
	if not source.contains("[string]$Probe"):
		_fail("Wrapper does not expose -Probe.")
	if not source.contains("$Script = $Probe"):
		_fail("Wrapper does not route -Probe to -Script.")
	if not source.contains("EndsWith(\".gd\")"):
		_fail("Wrapper does not append .gd for probe aliases.")
	print("RUN_WRAPPER_PROBE_ALIAS_PROBE ok")
	quit(0)
