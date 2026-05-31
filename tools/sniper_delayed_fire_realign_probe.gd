extends SceneTree


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	if file == null:
		_fail("Cannot open main.gd.")
	var source := file.get_as_text()
	var fn_pos := source.find("func _runtime_gun_activation_event_for")
	if fn_pos < 0:
		_fail("Missing runtime gun activation event helper.")
	var next_fn := source.find("\nfunc ", fn_pos + 1)
	var body := source.substr(fn_pos, next_fn - fn_pos if next_fn > fn_pos else source.length() - fn_pos)
	if body.find("unit.set_aim_pose") < 0:
		_fail("Gun activation should set the runtime aim pose before firing.")
	if body.find("direction = direction.normalized()") < 0:
		_fail("Gun activation should normalize the final firing direction before pose/fire.")
	if body.find("_true_bullet_event_for_aim(unit, direction") < 0:
		_fail("Projectile event should be generated from the same final gun normal.")
	print("SNIPER_DELAYED_FIRE_REALIGN_PROBE ok")
	quit()
