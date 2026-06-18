extends SceneTree

const SERVICE_PATH := "res://scripts/services/training_entry_service.gd"
const MAIN_PATH := "res://scripts/main.gd"
const TrainingEntryServiceScript := preload("res://scripts/services/training_entry_service.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	if not FileAccess.file_exists(SERVICE_PATH):
		_fail("Missing TrainingEntryService script.")
		return
	var service_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(SERVICE_PATH))
	for token in [
		"class_name TrainingEntryService",
		"clamped_radius",
		"ball_volume",
		"ball_mass",
		"ball_stats",
		"ball_entry",
		"ball_intro_segments",
		"pending_imports",
		"loadout_from_imports",
		"first_legal_hero_entry",
		"starter_loadout",
		"training_side_assignment",
	]:
		if service_source.find(token) < 0:
			_fail("TrainingEntryService missing token: %s" % token)
			return
	for forbidden in ["FileAccess", "DirAccess", "JSON.parse_string", "Button", "extends Control", "Control.new", "_begin_battle", "_compute_unit_stats", "_ai_starter_unit"]:
		if service_source.find(forbidden) >= 0:
			_fail("TrainingEntryService should stay pure; found forbidden token: %s" % forbidden)
			return
	var main_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(MAIN_PATH))
	for token in [
		"const TrainingEntryService = preload(\"res://scripts/services/training_entry_service.gd\")",
		"var training_entry_service: TrainingEntryService",
		"training_entry_service = TrainingEntryService.new()",
		"func _training_entry_service() -> TrainingEntryService",
		"_training_entry_service().clamped_radius",
		"_training_entry_service().ball_volume",
		"_training_entry_service().ball_mass",
		"_training_entry_service().ball_stats",
		"_training_entry_service().ball_entry",
		"_training_entry_service().ball_intro_segments",
		"_training_entry_service().pending_imports",
		"_training_entry_service().loadout_from_imports",
		"_training_entry_service().first_legal_hero_entry",
		"_training_entry_service().starter_loadout",
		"_training_entry_service().training_side_assignment",
	]:
		if main_source.find(token) < 0:
			_fail("main.gd should delegate training entry service token: %s" % token)
			return
	for forbidden in [
		"training_entry_service.clamped_radius",
		"training_entry_service.ball_volume",
		"training_entry_service.ball_mass",
		"training_entry_service.ball_stats",
		"training_entry_service.ball_entry",
		"training_entry_service.ball_intro_segments",
		"training_entry_service.pending_imports",
		"training_entry_service.loadout_from_imports",
		"training_entry_service.first_legal_hero_entry",
		"training_entry_service.starter_loadout",
		"training_entry_service.training_side_assignment",
		"training_entry_service != null",
		"_legacy_training_side_assignment",
		"_legacy_training_pending_imports",
		"_legacy_training_loadout_from_imports",
		"_legacy_first_training_hero_entry",
		"_legacy_training_starter_loadout",
		"_training_roster_from_single",
	]:
		if main_source.find(forbidden) >= 0:
			_fail("main.gd should not keep legacy TrainingEntryService fallback token: %s" % forbidden)
			return
	var service = TrainingEntryServiceScript.new()
	if absf(service.clamped_radius(0.873, 0.2, 2.0, 0.05) - 0.85) > 0.001:
		_fail("clamped_radius should step to nearest 0.05.")
	if absf(service.clamped_radius(5.0, 0.2, 2.0, 0.05) - 2.0) > 0.001:
		_fail("clamped_radius should clamp to max.")
	var volume := service.ball_volume(0.6)
	if absf(volume - (4.0 / 3.0 * PI * 0.6 * 0.6 * 0.6)) > 0.001:
		_fail("ball_volume returned unexpected value: %.4f" % volume)
	if absf(service.ball_mass(0.6, 0.6, 12.0) - 12.0) > 0.001:
		_fail("ball_mass should equal base mass at default radius.")
	if service.ball_mass(1.2, 0.6, 12.0) <= 90.0:
		_fail("ball_mass should scale by volume ratio.")
	var labels := {"name": "Probe Dummy", "unit_name": "Probe Dummy"}
	var constants := {"default_radius": 0.6, "base_mass": 12.0, "brake_delta_v": 1.5}
	var stats: Dictionary = service.ball_stats(0.6, labels, constants)
	if String(stats.get("role", "")) != "hero" or not bool(stats.get("training_ball_dummy", false)):
		_fail("ball_stats should return hero training dummy stats.")
	if String(stats.get("unit_name", "")) != "Probe Dummy" or float(stats.get("brake_power", 0.0)) <= 17.9:
		_fail("ball_stats should use labels and brake constants.")
	if float(stats.get("training_dummy_volume", 0.0)) <= 0.0 or Array(stats.get("runtime_topology_segments", [1])).size() != 0:
		_fail("ball_stats should expose dummy volume and no topology segments.")
	var entry: Dictionary = service.ball_entry(0.75, labels)
	var blueprint: Dictionary = Dictionary(entry.get("blueprint", {}))
	if String(entry.get("role", "")) != "hero" or not bool(blueprint.get("training_ball_dummy", false)) or absf(float(blueprint.get("training_dummy_radius_m", 0.0)) - 0.75) > 0.001:
		_fail("ball_entry should return a hero training dummy blueprint.")
	var segments := service.ball_intro_segments(0.9)
	if segments.size() != 1:
		_fail("ball_intro_segments should return exactly one segment.")
	var segment: Dictionary = Dictionary(segments[0])
	if String(segment.get("material_class", "")) != "training_dummy" or absf(float(segment.get("radius", 0.0)) - 0.9) > 0.001:
		_fail("ball_intro_segments should expose training dummy radius.")
	var pending_from_units := service.pending_imports([{"role": "hero", "blueprint": {"name": "A"}}], "puppet", {"name": "B"})
	if pending_from_units.size() != 1 or String(Dictionary(pending_from_units[0]).get("role", "")) != "hero":
		_fail("pending_imports should prefer explicit import_units.")
	var pending_from_fallback := service.pending_imports([], "puppet", {"name": "Fallback"})
	if pending_from_fallback.size() != 1 or String(Dictionary(pending_from_fallback[0]).get("role", "")) != "puppet":
		_fail("pending_imports should fall back to role+blueprint.")
	var import_result: Dictionary = service.loadout_from_imports([
		{"role": "invalid", "blueprint": {"name": "Skip"}},
		{"role": "puppet", "blueprint": {"name": "Puppet A"}},
		{"role": "hero", "blueprint": {"name": "Hero A"}},
	], ["hero", "puppet", "barrier"], Callable(self, "_import_legality_for_probe"), Callable(self, "_apply_pose_for_probe"))
	if not bool(import_result.get("ok", false)) or Array(import_result.get("loadout", [])).size() != 2:
		_fail("loadout_from_imports should build loadout from legal imports: %s" % str(import_result))
	if int(import_result.get("initial_slot", -1)) != 1 or String(import_result.get("initial_role", "")) != "hero":
		_fail("loadout_from_imports should prefer the first hero as initial slot.")
	var import_roster: Dictionary = Dictionary(import_result.get("roster", {}))
	var puppet_bp: Dictionary = Dictionary(Array(import_roster.get("puppet", []))[0])
	if not bool(puppet_bp.get("pose_applied", false)) or String(puppet_bp.get("role", "")) != "puppet":
		_fail("loadout_from_imports should apply pose callback and stamp role.")
	var illegal_import: Dictionary = service.loadout_from_imports([
		{"role": "hero", "blueprint": {"name": "Illegal"}},
	], ["hero", "puppet", "barrier"], Callable(self, "_import_legality_for_probe"), Callable(self, "_apply_pose_for_probe"))
	if bool(illegal_import.get("ok", true)) or String(illegal_import.get("error", "")) != "INVALID: probe illegal" or not bool(illegal_import.get("clear_import", false)):
		_fail("loadout_from_imports should surface legality callback errors.")
	var active_first: Dictionary = service.first_legal_hero_entry({"hero": [{"name": "A"}, {"name": "B"}, {"name": "C"}]}, {"hero": 1}, Callable(self, "_hero_entry_legal_for_probe"))
	if int(active_first.get("index", -1)) != 1:
		_fail("first_legal_hero_entry should prefer active legal hero.")
	var scan_after_active: Dictionary = service.first_legal_hero_entry({"hero": [{"name": "A"}, {"name": "B"}, {"name": "C"}]}, {"hero": 2}, Callable(self, "_hero_entry_legal_for_probe"))
	if int(scan_after_active.get("index", -1)) != 1:
		_fail("first_legal_hero_entry should scan after an illegal active hero.")
	var no_hero: Dictionary = service.first_legal_hero_entry({"hero": [{"name": "A"}]}, {"hero": 0}, Callable(self, "_hero_entry_never_legal_for_probe"))
	if not no_hero.is_empty():
		_fail("first_legal_hero_entry should return empty when no hero is legal.")
	var starter_state: Dictionary = service.starter_loadout({"name": "Starter"})
	if not bool(starter_state.get("ok", false)) or String(Dictionary(Array(Dictionary(starter_state.get("roster", {})).get("hero", []))[0]).get("name", "")) != "Starter":
		_fail("starter_loadout should build a hero roster.")
	var player_state := {
		"roster": {"hero": [{"name": "Player"}], "puppet": [], "barrier": []},
		"loadout": [{"role": "hero", "index": 0}],
		"initial_slot": 0,
		"initial_role": "hero",
	}
	var dummy_entry := {"role": "hero", "blueprint": {"name": "Dummy"}}
	var seat_one: Dictionary = service.training_side_assignment(player_state, dummy_entry, 1)
	if not bool(seat_one.get("ok", false)) or String(Dictionary(Array(Dictionary(Dictionary(seat_one.get("blueprints", {})).get(1, {})).get("hero", []))[0]).get("name", "")) != "Player":
		_fail("training_side_assignment should put player on P1 for seat 1/3.")
	if String(Dictionary(Array(Dictionary(Dictionary(seat_one.get("blueprints", {})).get(2, {})).get("hero", []))[0]).get("name", "")) != "Dummy":
		_fail("training_side_assignment should put dummy opposite player for seat 1.")
	var seat_two: Dictionary = service.training_side_assignment(player_state, dummy_entry, 2)
	if String(Dictionary(Array(Dictionary(Dictionary(seat_two.get("blueprints", {})).get(1, {})).get("hero", []))[0]).get("name", "")) != "Dummy":
		_fail("training_side_assignment should put dummy on P1 when player seat is 2.")
	if String(Dictionary(Array(Dictionary(Dictionary(seat_two.get("blueprints", {})).get(2, {})).get("hero", []))[0]).get("name", "")) != "Player":
		_fail("training_side_assignment should put player on P2 when seat is 2.")
	var missing_player: Dictionary = service.training_side_assignment({"roster": {}, "loadout": []}, dummy_entry, 1)
	if bool(missing_player.get("ok", true)) or String(missing_player.get("error", "")) == "":
		_fail("training_side_assignment should reject missing player state.")
	print("TRAINING_ENTRY_SERVICE_CONTRACT_PROBE ok")
	quit(0)


func _import_legality_for_probe(role_key: String, unit_bp: Dictionary) -> String:
	if String(unit_bp.get("name", "")) == "Illegal":
		return "INVALID: probe illegal"
	return ""


func _apply_pose_for_probe(unit_bp: Dictionary) -> void:
	unit_bp["pose_applied"] = true


func _hero_entry_legal_for_probe(entry: Dictionary) -> bool:
	return int(entry.get("index", -1)) == 1


func _hero_entry_never_legal_for_probe(entry: Dictionary) -> bool:
	return false
