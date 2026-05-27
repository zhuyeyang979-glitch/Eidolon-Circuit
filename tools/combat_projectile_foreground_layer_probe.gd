extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	if main.mobius_strip_surface_view == null:
		_fail("Missing Mobius surface view.")
		return
	if main.effects_root == null:
		_fail("Missing combat effects root.")
		return
	if main.effects_root.z_index < 78:
		_fail("Combat effects root should sit clearly above the Mobius field; got z=%d." % main.effects_root.z_index)
		return
	if main.effects_root.z_index <= main.mobius_strip_surface_view.z_index:
		_fail("Projectile/effect layer should be above Mobius surface.")
		return
	for player_id in [1, 2]:
		var line: Line2D = main.aim_lines.get(player_id, null)
		if line == null:
			_fail("Missing aim line for player %d." % player_id)
			return
		if line.z_index < 82:
			_fail("Aim line should be promoted above quiet field and combat effects; p%d z=%d." % [player_id, line.z_index])
			return
		if line.z_index <= main.mobius_strip_surface_view.z_index:
			_fail("Aim line should be above Mobius surface.")
			return
	print("COMBAT_PROJECTILE_FOREGROUND_LAYER_PROBE ok surface=%d effects=%d aim=%d" % [main.mobius_strip_surface_view.z_index, main.effects_root.z_index, (main.aim_lines[1] as Line2D).z_index])
	quit()
