extends SceneTree

const Transaction = preload("res://scripts/services/saved_unit_file_transaction.gd")

var failures: Array[String] = []
var reject_final := false
var blocked_destination := ""


func _init() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	var fixture_dir := _fixture_dir()
	if fixture_dir == "":
		push_error("Pass --fixture-dir=D:/DevStorage/temp/star-soul-save-probe-<unique> after --; no user:// fallback exists")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(fixture_dir) != OK:
		push_error("Cannot create isolated fixture directory: %s" % fixture_dir)
		quit(2)
		return

	var old_path := fixture_dir.path_join("existing_unit.json")
	var new_path := fixture_dir.path_join("new_unit.json")
	var old_bytes := "{\"v\":1}"
	if not _write_fixture(old_path, old_bytes):
		quit(2)
		return
	var transaction = Transaction.new()
	var validator := Callable(self, "_validate_fixture")
	var invalid_reason: String = transaction.save(old_path, "{invalid", validator)
	_assert(invalid_reason != "", "invalid staged JSON is rejected")
	_assert(FileAccess.get_file_as_string(old_path) == old_bytes, "staged validation preserves old bytes")

	reject_final = true
	var rollback_reason: String = transaction.save(old_path, "{\"v\":2}", validator)
	reject_final = false
	_assert(rollback_reason != "", "postcommit validation failure is reported")
	_assert(FileAccess.get_file_as_string(old_path) == old_bytes, "postcommit rollback restores old bytes")

	var success_reason: String = transaction.save(old_path, "{\"v\":3}", validator)
	_assert(success_reason == "", "valid replacement succeeds")
	_assert(FileAccess.get_file_as_string(old_path) == "{\"v\":3}", "valid replacement is readable")
	var new_reason: String = transaction.save(new_path, "{invalid", validator)
	_assert(new_reason != "", "invalid new save is rejected")
	_assert(not FileAccess.file_exists(new_path), "invalid new save leaves no destination")
	blocked_destination = fixture_dir.path_join("commit_blocked.json")
	var blocked_reason: String = transaction.save(blocked_destination, "{\"v\":4}", Callable(self, "_validate_commit_blocker"))
	_assert(blocked_reason == "cannot replace the saved unit", "failed rename reports commit failure")
	_assert(DirAccess.dir_exists_absolute(blocked_destination), "failed rename preserves a concurrent destination")
	_assert(FileAccess.get_file_as_string(blocked_destination.path_join("keep.txt")) == "keep", "failed rename preserves concurrent destination bytes")
	_assert(_sidecars_absent(fixture_dir), "transaction leaves no pending or backup files")

	if failures.is_empty():
		print("PASS: Saved unit transaction validates staging, restores old bytes, and preserves blocked destinations")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
		print("FAIL: %s" % failure)
	quit(1)


func _fixture_dir() -> String:
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--fixture-dir="):
			continue
		var path := argument.trim_prefix("--fixture-dir=").replace("\\", "/").trim_suffix("/")
		if path.begins_with("D:/DevStorage/temp/star-soul-save-probe-") and not path.contains(".."):
			return path
	return ""


func _validate_fixture(path: String) -> String:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary) or not Dictionary(parsed).has("v"):
		return "fixture JSON rejected"
	if reject_final and path.ends_with(".json"):
		return "fixture final readback rejected"
	return ""


func _validate_commit_blocker(path: String) -> String:
	if path.ends_with(".pending"):
		if not DirAccess.dir_exists_absolute(blocked_destination) and DirAccess.make_dir_absolute(blocked_destination) != OK:
			return "fixture could not create a blocked destination"
		if not _write_fixture(blocked_destination.path_join("keep.txt"), "keep"):
			return "fixture could not write its marker"
	return ""


func _write_fixture(path: String, contents: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot create isolated fixture: %s" % path)
		return false
	file.store_string(contents)
	file.close()
	return true


func _sidecars_absent(path: String) -> bool:
	for name in DirAccess.get_files_at(path):
		if name.ends_with(".pending") or name.ends_with(".backup"):
			return false
	return true


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
