extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const REQUIRED_FIELDS := [
	"momentum_min",
	"momentum_max",
	"allocated_limb_momentum",
	"joint_drive_kind",
	"joint_angle_range",
	"joint_extension_m",
	"limb_family",
	"stiffness_momentum",
]

const REQUIRED_FAMILIES := [
	"short_fast",
	"standard",
	"long_reach",
	"heavy_rigid",
	"telescopic",
	"hybrid_extend_swing",
	"flexible_chain",
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _check_limb(main, slot_key: String, part: Dictionary) -> void:
	var name := String(part.get("name", "?"))
	if slot_key == "muscle" and main._component_is_torso(part):
		return
	if slot_key == "muscle" and main._part_is_ammo_payload(part):
		return
	for key in REQUIRED_FIELDS:
		if not part.has(key):
			_fail("%s/%s missing %s" % [slot_key, name, key])
	if float(part.get("momentum_max", 0.0)) < float(part.get("momentum_min", 0.0)):
		_fail("%s has invalid momentum range." % name)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var families := {}
	var rotate_seen := false
	var extend_seen := false
	var short_seen := false
	var long_seen := false
	for slot_key in ["limb_muscle", "muscle"]:
		for part_raw in main._catalog_for("hero", slot_key):
			if not (part_raw is Dictionary):
				continue
			var part := Dictionary(part_raw)
			if slot_key == "muscle" and not bool(part.get("terminal_weapon", false)):
				continue
			_check_limb(main, slot_key, part)
			families[String(part.get("limb_family", ""))] = true
			var drive := String(part.get("joint_drive_kind", ""))
			rotate_seen = rotate_seen or drive.find("rot") >= 0 or drive.find("hybrid") >= 0
			extend_seen = extend_seen or drive.find("extend") >= 0 or drive.find("hybrid") >= 0
			short_seen = short_seen or float(part.get("length", 0.0)) <= 0.72
			long_seen = long_seen or float(part.get("length", 0.0)) >= 1.05
	for family in REQUIRED_FAMILIES:
		if not families.has(family):
			_fail("Missing limb family %s." % family)
	if not rotate_seen or not extend_seen:
		_fail("Limb catalog must contain rotation and extension drive kinds.")
	if not short_seen or not long_seen:
		_fail("Limb catalog must contain short and long reach gradients.")
	print("LIMB_GRADIENT_V3_PROBE ok families=%d" % families.size())
	quit()
