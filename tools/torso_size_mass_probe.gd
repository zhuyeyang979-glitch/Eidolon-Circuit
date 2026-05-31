extends SceneTree

const MainScene := preload("res://scripts/main.gd")
const PartArt := preload("res://scripts/part_art.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _expect_close(label: String, actual: float, expected: float, tolerance: float = 0.01) -> void:
	if absf(actual - expected) > tolerance:
		_fail("%s expected %.3f got %.3f" % [label, expected, actual])


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var expected_masses := {"XS": 6.0, "S": 12.0, "M": 24.0, "L": 48.0, "XL": 96.0}
	var previous_length := 0.0
	var previous_radius := 0.0
	for tier in ["XS", "S", "M", "L", "XL"]:
		var raw_torso := {
			"name": "%s OVERPORT TEST TORSO" % tier,
			"size_tier": tier,
			"size_class": tier,
			"is_torso": true,
			"material_class": "torso",
			"joint_ports": 14,
			"connection_ends": 14,
			"length": 1.2,
			"radius": 0.3,
			"cost": 1,
			"hp": 1,
		}
		var torso: Dictionary = main._component_with_size_design(raw_torso, "muscle")
		_expect_close("%s mass" % tier, float(torso.get("mass", 0.0)), float(expected_masses[tier]))
		if int(torso.get("joint_ports", 0)) != 6 or int(torso.get("connection_ends", 0)) != 6:
			_fail("%s torso ports were not capped to 6: %s/%s" % [tier, str(torso.get("joint_ports", "?")), str(torso.get("connection_ends", "?"))])
		if PartArt.connector_count_for("torso", torso) != 6:
			_fail("%s PartArt connector count was not capped to 6." % tier)
		if previous_length > 0.0 and (float(torso.get("length", 0.0)) <= previous_length or float(torso.get("radius", 0.0)) <= previous_radius):
			_fail("%s torso visual dimensions did not increase by volume-derived scale." % tier)
		previous_length = float(torso.get("length", 0.0))
		previous_radius = float(torso.get("radius", 0.0))
	var catalog: Array = main._catalog_for("hero", "muscle")
	var torso_count := 0
	for i in range(catalog.size()):
		var part := main._selected_component("hero", "muscle", i)
		if not main._component_is_torso(part):
			continue
		torso_count += 1
		if int(part.get("joint_ports", 0)) > 6 or int(part.get("connection_ends", 0)) > 6:
			_fail("Catalog torso %s exposes more than 6 ports." % String(part.get("name", i)))
	if torso_count <= 0:
		_fail("No torso parts found in hero muscle catalog.")
	print("TORSO_SIZE_MASS_PROBE torsos=%d masses=%s" % [torso_count, str(expected_masses)])
	quit()
