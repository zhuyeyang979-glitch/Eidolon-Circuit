extends SceneTree


const RAW_START := "const SPECIAL_CATALOG"
const RAW_END := "const PORTALS"
const LEGACY_FIELDS := [
	"power",
	"energy",
	"power_load",
	"engine_power",
	"required_power",
	"engine_torque",
	"engine_motion_scale",
	"normal_thrust",
	"boost_power",
	"thruster_momentum",
	"load_capacity",
	"momentum_capacity",
	"idle_heat",
]


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var path := ProjectSettings.globalize_path("res://scripts/main.gd")
	var source := FileAccess.get_file_as_string(path)
	if source == "":
		_fail("Could not read main.gd.")
	var start := source.find(RAW_START)
	var end := source.find(RAW_END)
	if start < 0 or end <= start:
		_fail("Could not isolate raw catalog block.")
	var catalog_text := source.substr(start, end - start)
	for field in LEGACY_FIELDS:
		var pattern := "\"%s\"" % field
		if catalog_text.find(pattern) >= 0:
			_fail("Raw catalog still contains legacy power field %s." % field)
	print("RAW_CATALOG_NO_LEGACY_POWER_FIELDS_PROBE ok")
	quit()
