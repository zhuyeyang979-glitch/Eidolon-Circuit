extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _assert_advisory_shape(report: Dictionary) -> void:
	if bool(report.get("blocking", true)):
		_fail("Training validation report should never block training.")
	if not bool(report.get("advisory_only", false)):
		_fail("Training validation report should be advisory-only.")
	for forbidden_key in ["strength_score", "power_score", "rating_total", "fixed_score"]:
		if report.has(forbidden_key):
			_fail("Training validation report should not expose fixed strength score key: %s" % forbidden_key)
	var entries: Array = Array(report.get("entries", []))
	if entries.is_empty():
		_fail("Training validation report should have entries.")
	for raw_entry in entries:
		if not (raw_entry is Dictionary):
			_fail("Training validation entry should be a dictionary.")
		var entry: Dictionary = raw_entry
		if not bool(entry.get("advisory_only", false)):
			_fail("Training validation entry should be advisory-only: %s" % str(entry))
		if String(entry.get("kind", "")) == "INVALID":
			_fail("Training validation report should not emit INVALID entries.")


func _init() -> void:
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/main.gd"))
	for token in [
		"const TrainingValidationReportService = preload(\"res://scripts/services/training_validation_report_service.gd\")",
		"var training_validation_report_service: TrainingValidationReportService",
		"training_validation_report_service = TrainingValidationReportService.new()",
		"func _training_validation_report_for_current_training",
		"training_validation_report_service.report",
		"training_validation_report_service.report_text",
	]:
		if source.find(token) < 0:
			_fail("Main training validation report integration missing token: %s" % token)
			return

	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	if main.game_state == MainScene.STATE_LOADING:
		main._show_menu(true)
	main._show_training_config(true)
	if main.game_state != MainScene.STATE_SCOUT:
		_fail("Training config should open the scout/config page.")
	if main.pending_battle_mode != MainScene.MODE_TRAINING:
		_fail("Training config should keep pending battle mode as training.")
	if main.training_validation_report_service == null:
		_fail("Main should own a training validation report service instance.")
	var report: Dictionary = main._training_validation_report_for_current_training()
	_assert_advisory_shape(report)
	if main.scout_detail_view == null:
		_fail("Training config should create a scout detail view.")
	var detail_text := String(main.scout_detail_view.detail_text)
	if detail_text.find("训练验证报告") < 0 and detail_text.find("TRAINING VALIDATION") < 0:
		_fail("Training config detail panel should show the advisory report, got: %s" % detail_text)
	if detail_text.find("建议") < 0 and detail_text.find("SUGGEST") < 0:
		_fail("Training config report should include suggestions, got: %s" % detail_text)
	var entry_count := Array(report.get("entries", [])).size()
	root.remove_child(main)
	main.free()
	print("TRAINING_VALIDATION_REPORT_MAIN_PROBE ok entries=%d" % entry_count)
	quit(0)
