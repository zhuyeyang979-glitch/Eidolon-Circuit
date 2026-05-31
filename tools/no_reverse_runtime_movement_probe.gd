extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _latest_unit2_path() -> String:
	var dir := DirAccess.open("user://saved_units")
	if dir == null:
		return ""
	var best_path := ""
	var best_time := -1
	for file_name in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var path := "user://saved_units/%s" % file_name
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		if not (parsed is Dictionary) or String(Dictionary(parsed).get("unit_name", "")) != "2":
			continue
		var mtime := int(FileAccess.get_modified_time(path))
		if mtime >= best_time:
			best_time = mtime
			best_path = path
	return best_path


func _init() -> void:
	var hero = FighterScene.new()
	root.add_child(hero)
	hero.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "DirectReverseProbe",
		"stats": {
			"health": 100,
			"mass": 10.0,
			"move_speed": 3.0,
			"body_move_speed": 3.0,
			"move_acceleration": 18.0,
			"thruster_acceleration": 18.0,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso"}],
		},
	})
	hero.deploy(4.0, 0.0)
	hero.set_facing_immediate(1)
	var start_x: float = hero.ring_pos
	hero.velocity = Vector2.ZERO
	hero.move_by(Vector2.LEFT, 0.2, MainScene.RING_LENGTH)
	hero.tick(0.2, MainScene.RING_LENGTH)
	if hero.velocity.x >= -0.001:
		_fail("Reverse input should produce ordinary backward movement.")
		return
	hero.ring_pos = start_x
	hero.lane = 0.0
	hero.velocity = Vector2.RIGHT * 1.4
	var speed_before: float = hero.velocity.length()
	hero.move_by(Vector2.LEFT, 0.25, MainScene.RING_LENGTH)
	hero.tick(0.25, MainScene.RING_LENGTH)
	if hero.velocity.x >= 1.4:
		_fail("Reverse input did not steer velocity toward reverse.")
		return
	print("NO_REVERSE_RUNTIME_MOVEMENT_PROBE direct_reverse speed %.3f -> %.3f" % [speed_before, hero.velocity.length()])
	quit()
