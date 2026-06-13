extends SceneTree

const FighterScene := preload("res://scripts/fighter.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _make_unit(boost_momentum: float, reaction_cancel: float):
	var unit = FighterScene.new()
	root.add_child(unit)
	unit.setup_unit({
		"owner_id": 1,
		"role": "hero",
		"unit_name": "ReactionCancelProbe",
		"stats": {
			"health": 100,
			"mass": 24.0,
			"boost_momentum": boost_momentum,
			"thruster_momentum": boost_momentum * 0.5,
			"boost_duration": 0.3,
			"reaction_cancel": reaction_cancel,
			"teamedit_runtime_topology": true,
			"runtime_topology_segments": [{"part_kind": "torso"}],
		},
	})
	unit.deploy(0.0, 0.0)
	return unit


func _init() -> void:
	var none = _make_unit(0.0, 2.0)
	var weak = _make_unit(120.0, 0.25)
	var strong = _make_unit(120.0, 1.5)
	var none_cancel: float = none._available_attack_reaction_cancel_momentum(true)
	var weak_cancel: float = weak._available_attack_reaction_cancel_momentum(true)
	var strong_cancel: float = strong._available_attack_reaction_cancel_momentum(true)
	if none_cancel > 0.001:
		_fail("No boost momentum should mean no active reaction cancel budget.")
		return
	if weak_cancel <= 0.001:
		_fail("Boost momentum should provide active reaction cancel budget.")
		return
	if strong_cancel <= weak_cancel:
		_fail("Higher reaction_cancel should increase active reaction cancel budget.")
		return
	print("ATTACK_REACTION_CANCEL_PROBE ok weak=%.2f strong=%.2f" % [weak_cancel, strong_cancel])
	quit()
