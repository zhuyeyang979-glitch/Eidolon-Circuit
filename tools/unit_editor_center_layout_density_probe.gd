extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const AssemblyTemplateOverlayRenderer := preload("res://scripts/views/editor/assembly_template_overlay_renderer.gd")

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main._show_editor()
	var tutorial_panel := main.find_child("AssemblyTutorialPanel", true, false) as ColorRect
	if tutorial_panel == null:
		_fail("Editor should expose an AssemblyTutorialPanel.")
	else:
		var tutorial_rect := tutorial_panel.get_global_rect()
		if tutorial_rect.size.y > 68.0:
			_fail("Tutorial panel should stay compact, got height %.1f." % tutorial_rect.size.y)
		if tutorial_rect.end.y > 172.0:
			_fail("Tutorial panel should leave more center space, got bottom %.1f." % tutorial_rect.end.y)
	var renderer := AssemblyTemplateOverlayRenderer.new()
	if not renderer.has_method("overlay_panel_rect"):
		_fail("Assembly template renderer should expose overlay_panel_rect for layout verification.")
	else:
		var panel_rect: Rect2 = renderer.overlay_panel_rect(Vector2(908.0, 548.0))
		if panel_rect.size.x < 560.0:
			_fail("Assembly template should use wider center space, got width %.1f." % panel_rect.size.x)
		if panel_rect.size.y < 210.0:
			_fail("Assembly template should use taller center space, got height %.1f." % panel_rect.size.y)
		if panel_rect.position.y > 88.0:
			_fail("Assembly template should stay near the top center, got y %.1f." % panel_rect.position.y)
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_CENTER_LAYOUT_DENSITY_PROBE ok")
	quit(0)
