extends SceneTree

const MAIN_PATH := "res://scripts/main.gd"

var failed := false


func _init() -> void:
	var source := _read_text(MAIN_PATH)
	var update_body := _function_body(source, "func _update_laser_telegraphs")
	var gate_pos := update_body.find("_runtime_event_blocked_by_hardware_fault")
	var resolve_pos := update_body.find("_resolve_attack")
	_require(gate_pos >= 0, "Laser telegraph queue should check hardware fault dependencies before firing.")
	_require(resolve_pos >= 0, "Laser telegraph queue should still resolve ready shots.")
	_require(gate_pos >= 0 and resolve_pos >= 0 and gate_pos < resolve_pos, "Laser telegraph hardware fault gate must run before _resolve_attack.")
	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_LASER_TELEGRAPH_DEPENDENCY_PROBE ok")
	quit(0)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	_require(file != null, "Cannot read %s" % path)
	return file.get_as_text() if file != null else ""


func _function_body(source: String, signature: String) -> String:
	var start := source.find(signature)
	_require(start >= 0, "Missing function %s." % signature)
	if start < 0:
		return ""
	var next := source.find("\nfunc ", start + 1)
	return source.substr(start, next - start if next > start else source.length() - start)


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
