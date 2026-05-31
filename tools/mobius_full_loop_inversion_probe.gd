extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const MobiusWorld := preload("res://scripts/mobius_world.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var up0 := MobiusWorld.local_up_vector(0.0, MainScene.RING_LENGTH)
	var up1 := MobiusWorld.local_up_vector(MainScene.RING_LENGTH, MainScene.RING_LENGTH)
	var up2 := MobiusWorld.local_up_vector(MainScene.RING_LENGTH * 2.0, MainScene.RING_LENGTH)
	if up0.dot(up1) > -0.999:
		_fail("One full loop should invert local up direction.")
	if up0.dot(up2) < 0.999:
		_fail("Two full loops should restore local up direction.")
	var angle_delta := wrapf(MobiusWorld.twist_angle(MainScene.RING_LENGTH, MainScene.RING_LENGTH) - MobiusWorld.twist_angle(0.0, MainScene.RING_LENGTH), -TAU, TAU)
	if absf(absf(angle_delta) - PI) > 0.001:
		_fail("Twist angle should advance by PI over one loop.")
	print("MOBIUS_FULL_LOOP_INVERSION_PROBE ok")
	quit()
