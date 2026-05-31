extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const ActionProfileRegistry := preload("res://scripts/services/action_profile_registry.gd")


class FakeHero:
	extends RefCounted
	func forward_vector() -> Vector2:
		return Vector2.RIGHT


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var registry := ActionProfileRegistry.new()
	if registry.command_state_for("X") != "normal":
		_fail("X should map to normal.")
	if registry.command_state_for("4X") != "active":
		_fail("4X should map to active.")
	if registry.command_state_for("6X") != "armor":
		_fail("6X should map to armor.")
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var fake := FakeHero.new()
	if main._boot_driver_initial_state_for_input(fake, Vector2.ZERO) != "normal":
		_fail("Boot Driver neutral input should start normal.")
	if main._boot_driver_initial_state_for_input(fake, Vector2.LEFT) != "active":
		_fail("Boot Driver 4X input should start active for a right-facing unit.")
	if main._boot_driver_initial_state_for_input(fake, Vector2.RIGHT) != "armor":
		_fail("Boot Driver 6X input should start armor for a right-facing unit.")
	if main._boot_driver_initial_state_for_input(fake, Vector2.UP) != "normal":
		_fail("Boot Driver vertical input should not become 4X/6X.")
	print("BOOT_DRIVER_STATE_MAPPING_PROBE ok")
	quit()
