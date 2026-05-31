extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	if main.editor_perf_overlay_label == null:
		_fail("TeamEdit perf overlay label was not created.")
	if main.editor_perf_overlay_label.visible:
		_fail("TeamEdit perf overlay should be hidden by default.")
	main._set_editor_perf_overlay_enabled(true)
	if not main.editor_perf_overlay_label.visible:
		_fail("TeamEdit perf overlay did not become visible.")
	var text: String = String(main.editor_perf_overlay_label.text)
	for token in ["CPU tick", "visible controls", "board set", "retained item", "gpu"]:
		if not text.contains(token):
			_fail("Perf overlay missing field: %s\n%s" % [token, text])
	main._set_editor_perf_overlay_enabled(false)
	if main.editor_perf_overlay_label.visible:
		_fail("TeamEdit perf overlay did not hide.")
	print("TEAMEDIT_LIVE_PERF_OVERLAY_PROBE ok")
	quit(0)
