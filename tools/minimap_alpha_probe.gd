extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main.battle_minimap_view == null:
		_fail("Battle minimap view was not created.")
	if float(main.battle_minimap_view.panel_alpha) >= 0.4:
		_fail("Minimap panel background is too opaque.")
	if float(main.battle_minimap_view.map_alpha) >= 0.35:
		_fail("Minimap map fill is too opaque.")
	if float(main.battle_minimap_view.border_alpha) <= 0.25:
		_fail("Minimap border is too faint to read.")
	print("MINIMAP_ALPHA_PROBE panel=%.2f map=%.2f grid=%.2f border=%.2f" % [
		float(main.battle_minimap_view.panel_alpha),
		float(main.battle_minimap_view.map_alpha),
		float(main.battle_minimap_view.grid_alpha),
		float(main.battle_minimap_view.border_alpha),
	])
	quit()
