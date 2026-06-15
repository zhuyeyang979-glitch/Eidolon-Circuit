extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	main.loading_auto_transitions_enabled = false
	main._show_training_config(true)
	var slider := main.scout_layer.find_child("ScoutDummyRadiusSlider", true, false) as HSlider
	var plus := main.scout_layer.find_child("ScoutDummyRadiusPlus", true, false) as Button
	var reset := main.scout_layer.find_child("ScoutDummyRadiusReset", true, false) as Button
	var value_label := main.scout_layer.find_child("ScoutDummyValue", true, false) as Label
	var idle := main.scout_layer.find_child("ScoutDummyStateIdleBrake", true, false) as Button
	var free := main.scout_layer.find_child("ScoutDummyStateFreePhysics", true, false) as Button
	var fixed := main.scout_layer.find_child("ScoutDummyStateFixed", true, false) as Button
	if slider == null or plus == null or reset == null or value_label == null or idle == null or free == null or fixed == null:
		_fail("Training dummy setup controls should exist on training config page.")
	if not slider.visible or slider.min_value > 0.21 or slider.max_value < 1.99:
		_fail("Training dummy radius slider has wrong visibility or range.")
	if not idle.visible or not free.visible or not fixed.visible:
		_fail("Training dummy state controls should be visible on training config page.")
	free.pressed.emit()
	if main.training_dummy_state != "free_physics":
		_fail("Free physics dummy state button did not update training_dummy_state.")
	fixed.pressed.emit()
	if main.training_dummy_state != "fixed":
		_fail("Fixed dummy state button did not update training_dummy_state.")
	main._set_training_ball_dummy_radius(0.85)
	if absf(float(slider.value) - 0.85) > 0.001:
		_fail("Slider did not reflect programmatic dummy radius update.")
	plus.pressed.emit()
	if absf(main._training_ball_dummy_radius() - 0.90) > 0.001:
		_fail("Plus button should advance radius by one step, got %.3f" % main._training_ball_dummy_radius())
	reset.pressed.emit()
	if absf(main._training_ball_dummy_radius() - MainScene.TRAINING_DUMMY_RADIUS_DEFAULT) > 0.001:
		_fail("Reset should restore default dummy radius.")
	if main.training_dummy_state != "fixed":
		_fail("Resetting radius should not change dummy state.")
	idle.pressed.emit()
	if main.training_dummy_state != "idle_brake":
		_fail("Idle brake dummy state button did not restore default state.")
	if String(value_label.text).find("体积") < 0 and String(value_label.text).to_lower().find("vol") < 0:
		_fail("Dummy radius label should include volume/mass summary, got: %s" % String(value_label.text))
	print("TRAINING_BALL_DUMMY_RADIUS_UI_PROBE ok label=%s state=%s" % [String(value_label.text), main.training_dummy_state])
	quit()
