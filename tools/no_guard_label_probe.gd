extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var null_label := main._hit_effect_nullified_label("")
	var shield_label := main._hit_effect_nullified_label("shield")
	var threshold_label := main._hit_effect_nullified_label("threshold")
	for label in [null_label, shield_label, threshold_label]:
		var text := String(label).to_lower()
		if text.contains("block") or text.contains("格挡"):
			_fail("Hit effect label still uses guard/block wording: %s" % label)
			return
	if null_label != "动量不足":
		_fail("Default nullified label should be 动量不足 in Chinese UI, got %s." % null_label)
		return
	if shield_label != "护盾吸收":
		_fail("Shield nullified label should be 护盾吸收, got %s." % shield_label)
		return
	if threshold_label != "未破阈值":
		_fail("Threshold label should be 未破阈值, got %s." % threshold_label)
		return
	print("NO_GUARD_LABEL_PROBE labels=%s/%s/%s" % [null_label, shield_label, threshold_label])
	quit()
