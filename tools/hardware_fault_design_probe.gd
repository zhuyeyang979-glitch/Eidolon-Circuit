extends SceneTree

const DESIGN_PATH := "res://docs/plans/2026-06-24-hardware-fault-runtime.md"
const MAIN_PATH := "res://scripts/main.gd"
const FIGHTER_PATH := "res://scripts/fighter.gd"
const CONTACT_SERVICE_PATH := "res://scripts/services/runtime_contact_service.gd"

var failed := false


func _init() -> void:
	var design := _read_text(DESIGN_PATH)
	var main_source := _read_text(MAIN_PATH)
	var fighter_source := _read_text(FIGHTER_PATH)
	var contact_source := _read_text(CONTACT_SERVICE_PATH)

	for token in [
		"`normal`",
		"`faulted`",
		"`destroyed`",
		"raw_momentum > runtime_momentum_capacity",
		"path_capped_momentum",
		"hardware_capped_momentum",
		"target_construct_body_id",
		"target_hardware_node_id",
		"primary_core_node_id",
		"_battle_actor_disabled_modules()",
		"Save Compatibility",
		"Replay Determinism",
		"tools/hardware_fault_contract_probe.gd",
	]:
		_require(design.find(token) >= 0, "Design is missing contract token: %s" % token)

	for token in [
		"func _part_momentum_capacity(",
		"func _part_stiffness(",
		"func _battle_actor_disabled_modules(",
	]:
		_require(main_source.find(token) >= 0, "Current main adapter token missing: %s" % token)

	for token in [
		"stiffness_momentum",
		"path_stiffness_momentum",
		"_runtime_active_collider_node_set",
	]:
		_require(fighter_source.find(token) >= 0, "Current fighter runtime token missing: %s" % token)

	for token in [
		"func part_stiffness(",
		"func path_stiffness(",
		"func damage_intent(",
	]:
		_require(contact_source.find(token) >= 0, "Current contact service token missing: %s" % token)

	if failed:
		quit(1)
		return
	print("HARDWARE_FAULT_DESIGN_PROBE ok")
	quit(0)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	_require(file != null, "Cannot read %s" % path)
	return file.get_as_text() if file != null else ""


func _require(condition: bool, message: String) -> void:
	if condition:
		return
	failed = true
	push_error(message)
