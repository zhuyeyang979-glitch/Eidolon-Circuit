extends SceneTree

const UnitBlueprintValidator := preload("res://scripts/services/unit_blueprint_validator.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var validator := UnitBlueprintValidator.new()
	var legacy_payload := {
		"name": "OLD",
		"custom_topology": {
			"nodes": [
				{"slot": "booster", "body_move_speed": 1.2},
			],
			"attack_groups": [],
		},
	}
	var legacy_path := validator.first_legacy_drive_path(legacy_payload)
	if legacy_path == "":
		_fail("Validator did not detect legacy drive/pointer payload.")
	var clean_payload := {
		"stats": {
			"drive_output_total": 120.0,
			"drive_demand_total": 80.0,
			"drive_margin": 40.0,
			"move_speed": 1.2,
			"boost_speed": 2.4,
			"action_drive_scale": 1.0,
			"stability_drive_scale": 1.0,
		},
		"module_bindings": [
			{"module_action_profile": "two_link_forward_snap", "joint_drive_allocation_total": 24.0},
		],
	}
	if validator.has_legacy_drive_data(clean_payload):
		_fail("Validator falsely rejected new drive contract payload.")
	print("UNIT_VALIDATOR_SINGLE_SOURCE_PROBE ok legacy_path=%s" % legacy_path)
	quit()
