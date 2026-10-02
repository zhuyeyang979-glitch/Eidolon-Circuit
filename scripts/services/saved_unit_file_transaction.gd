extends RefCounted


func save(path: String, contents: String, validate_file: Callable) -> String:
	if path == "" or not validate_file.is_valid():
		return "invalid saved unit destination or validator"
	var token := "%d_%d" % [Time.get_ticks_usec(), randi()]
	var staged_path := "%s.%s.pending" % [path, token]
	var backup_path := "%s.%s.backup" % [path, token]
	if FileAccess.file_exists(staged_path) or FileAccess.file_exists(backup_path):
		return "cannot reserve a temporary saved unit path"
	var staged := FileAccess.open(staged_path, FileAccess.WRITE)
	if staged == null:
		return "cannot write to unit library"
	staged.store_string(contents)
	staged.flush()
	var write_error := staged.get_error()
	staged.close()
	if write_error != OK:
		_remove_if_exists(staged_path)
		return "cannot finish writing the temporary saved unit"
	var staged_reason := String(validate_file.call(staged_path))
	if staged_reason != "":
		_remove_if_exists(staged_path)
		return staged_reason

	var had_previous := FileAccess.file_exists(path)
	if had_previous:
		if DirAccess.copy_absolute(path, backup_path) != OK or not _files_match(path, backup_path):
			_remove_if_exists(staged_path)
			_remove_if_exists(backup_path)
			return "cannot back up the previous saved unit"
	if DirAccess.rename_absolute(staged_path, path) != OK:
		_remove_if_exists(staged_path)
		if had_previous:
			if not _files_match(path, backup_path):
				return "cannot replace the saved unit; previous copy remains at %s" % backup_path
			if not _remove_if_exists(backup_path):
				push_warning("Saved unit backup could not be removed: %s" % backup_path)
		return "cannot replace the saved unit"

	var final_reason := String(validate_file.call(path))
	if final_reason != "":
		var validation_rollback := _rollback(path, had_previous, backup_path)
		return "%s%s" % [final_reason, validation_rollback]
	if had_previous and not _remove_if_exists(backup_path):
		push_warning("Saved unit backup could not be removed: %s" % backup_path)
	return ""


func _rollback(path: String, had_previous: bool, backup_path: String) -> String:
	if not had_previous:
		if _remove_if_exists(path):
			return ""
		return "; failed to remove invalid new file at %s" % path
	if DirAccess.rename_absolute(backup_path, path) == OK:
		return ""
	if DirAccess.copy_absolute(backup_path, path) == OK and _files_match(path, backup_path):
		push_warning("Saved unit rollback left a backup at %s" % backup_path)
		return ""
	return "; previous saved unit remains in backup at %s, but restoration failed" % backup_path


func _files_match(first_path: String, second_path: String) -> bool:
	var first := FileAccess.open(first_path, FileAccess.READ)
	var second := FileAccess.open(second_path, FileAccess.READ)
	if first == null or second == null:
		return false
	var length := first.get_length()
	return length == second.get_length() and first.get_buffer(length) == second.get_buffer(length)


func _remove_if_exists(path: String) -> bool:
	return not FileAccess.file_exists(path) or DirAccess.remove_absolute(path) == OK
