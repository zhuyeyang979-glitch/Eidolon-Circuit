extends SceneTree

const SERVICE_PATH := "res://scripts/services/unit_editor_assembly_template_service.gd"
const Service := preload("res://scripts/services/unit_editor_assembly_template_service.gd")

var failed := false
var part_catalog := {
	"muscle": [
		{"name": "Crab Core", "stable_key": "torso_crab", "is_torso": true},
		{"name": "Rail Blade", "stable_key": "weapon_rail", "weapon_family": "blade"},
		{"name": "Offboard Lance", "stable_key": "weapon_lance", "weapon_family": "lance"},
	],
	"limb_muscle": [
		{"name": "Flex Tendon", "stable_key": "limb_flex"},
	],
	"engine": [
		{"name": "Pulse Engine", "stable_key": "engine_pulse"},
	],
	"booster": [
		{"name": "Vector Booster", "stable_key": "booster_vector"},
	],
	"cooling": [
		{"name": "Mist Radiator", "stable_key": "cooling_mist"},
	],
	"special": [
		{"name": "Hero Soul", "stable_key": "special_soul"},
	],
	"module": [
		{"name": "Slash Module", "stable_key": "module_slash"},
	],
}


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _selected_component(_role_key: String, slot_key: String, part_index: int) -> Dictionary:
	var entries: Array = Array(part_catalog.get(slot_key, []))
	if part_index >= 0 and part_index < entries.size() and entries[part_index] is Dictionary:
		return Dictionary(entries[part_index]).duplicate(true)
	return {
		"name": "%s_%d" % [slot_key, part_index],
		"stable_key": "%s_%d" % [slot_key, part_index],
	}


func _short_part_name(part_name: String) -> String:
	return part_name


func _topology_node_is_component(node: Dictionary) -> bool:
	return node.has("slot") or node.has("slot_key") or node.has("part_index")


func _topology_node_slot(node: Dictionary) -> String:
	return String(node.get("slot", node.get("slot_key", "")))


func _topology_node_resolved_part_index(role_key: String, node: Dictionary, unit_bp: Dictionary) -> int:
	var slot_key := _topology_node_slot(node)
	return int(node.get("part_index", node.get(slot_key, unit_bp.get(slot_key, -1))))


func _topology_node_part(role_key: String, node: Dictionary, unit_bp: Dictionary) -> Dictionary:
	var slot_key := _topology_node_slot(node)
	var part_index := _topology_node_resolved_part_index(role_key, node, unit_bp)
	return _selected_component(role_key, slot_key, part_index)


func _component_is_torso(part: Dictionary) -> bool:
	return bool(part.get("is_torso", false))


func _payload_slot_key_for_kind(payload_kind: String) -> String:
	return payload_kind


func _payload_part_for_payload(role_key: String, payload: Dictionary) -> Dictionary:
	var payload_kind := String(payload.get("kind", ""))
	var slot_key := _payload_slot_key_for_kind(payload_kind)
	var part_index := int(payload.get(slot_key, payload.get(payload_kind, -1)))
	return _selected_component(role_key, slot_key, part_index)


func _runtime_module_bindings_for_blueprint(_role_key: String, unit_bp: Dictionary) -> Array:
	return Array(unit_bp.get("module_bindings", []))


func _callbacks() -> Dictionary:
	return {
		"selected_component": Callable(self, "_selected_component"),
		"short_part_name": Callable(self, "_short_part_name"),
		"topology_node_is_component": Callable(self, "_topology_node_is_component"),
		"topology_node_slot": Callable(self, "_topology_node_slot"),
		"topology_node_resolved_part_index": Callable(self, "_topology_node_resolved_part_index"),
		"topology_node_part": Callable(self, "_topology_node_part"),
		"component_is_torso": Callable(self, "_component_is_torso"),
		"payload_slot_key_for_kind": Callable(self, "_payload_slot_key_for_kind"),
		"payload_part_for_payload": Callable(self, "_payload_part_for_payload"),
		"runtime_module_bindings_for_blueprint": Callable(self, "_runtime_module_bindings_for_blueprint"),
	}


func _slot_by_key(slots: Array, key: String) -> Dictionary:
	for raw_slot in slots:
		if raw_slot is Dictionary:
			var slot: Dictionary = raw_slot
			if String(slot.get("key", "")) == key:
				return slot
	return {}


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))


func _assert_source_guardrails() -> void:
	var main_source := _source("res://scripts/main.gd")
	var service_source := _source(SERVICE_PATH)
	for forbidden in [
		"func _editor_assembly_template_part_key",
		"func _editor_assembly_template_part_label",
		"func _editor_assembly_template_append_slot",
		"func _editor_assembly_template_append_warning",
	]:
		_assert(main_source.find(forbidden) < 0, "main.gd should not keep assembly template helper %s." % forbidden)
	_assert(main_source.find("UnitEditorAssemblyTemplateService") >= 0, "main.gd should preload and own UnitEditorAssemblyTemplateService.")
	_assert(main_source.find("_editor_assembly_template_callbacks") >= 0, "main.gd should expose callback adapter for assembly template service.")
	_assert(main_source.find("_unit_editor_assembly_template_service().model") >= 0, "main.gd wrapper should delegate model construction to the service.")
	for forbidden_service_token in ["extends Node", "Control", "CanvasItem", "DisplayServer", "Input.", "FileAccess"]:
		_assert(service_source.find(forbidden_service_token) < 0, "Assembly template service should stay free of Godot UI/runtime dependency %s." % forbidden_service_token)


func _init() -> void:
	if load(SERVICE_PATH) == null:
		_fail("Missing UnitEditorAssemblyTemplateService script.")
		quit(1)
		return
	_assert_source_guardrails()
	var service = Service.new()
	var unit_bp := {
		"muscle": 2,
		"limb_muscle": 0,
		"engine": 0,
		"booster": 0,
		"cooling": 0,
		"special": 0,
		"module": 0,
		"custom_topology": {
			"nodes": [
				{"slot": "muscle", "part_index": 0},
				{"slot": "limb_muscle", "part_index": 0},
				{"slot": "muscle", "part_index": 1},
			],
		},
		"slot_payloads": [
			{"kind": "engine", "engine": 0},
			{"kind": "module", "module": 0},
		],
		"module_bindings": [
			{"software_slot_index": 1, "runtime_valid": false},
		],
	}
	var zh_model: Dictionary = service.model("hero", unit_bp, {"illegal": true}, _callbacks(), true)
	_assert(not zh_model.is_empty(), "Hero topology should produce an assembly template model.")
	_assert(String(zh_model.get("title", "")) == "组装模板", "Chinese model title should be localized.")
	_assert(String(zh_model.get("status", "")) == "warn", "Invalid binding and build conflict should mark model as warn.")
	_assert(String(zh_model.get("summary", "")).find("核心1") >= 0, "Summary should count one torso core.")
	_assert(String(zh_model.get("summary", "")).find("绑定0/1") >= 0, "Summary should expose module binding ratio.")
	var slots: Array = Array(zh_model.get("slots", []))
	_assert(String(_slot_by_key(slots, "core").get("value", "")) == "1", "Core slot should count placed torso.")
	_assert(String(_slot_by_key(slots, "limb").get("value", "")) == "1", "Limb slot should count placed limb.")
	_assert(String(_slot_by_key(slots, "weapon").get("value", "")) == "1", "Weapon slot should count placed terminal weapon.")
	_assert(String(_slot_by_key(slots, "binding").get("state", "")) == "warn", "Binding slot should warn on invalid module binding.")
	_assert(int(zh_model.get("warning_count", 0)) >= 2, "Model should expose pending warnings.")
	_assert(String(zh_model.get("signature", "")) != "", "Model should expose a stable signature.")
	var en_model: Dictionary = service.model("hero", unit_bp, {}, _callbacks(), false)
	_assert(String(en_model.get("title", "")) == "Assembly Template", "English model title should be localized.")
	_assert(String(en_model.get("summary", "")).find("Core 1") >= 0, "English summary should count one torso core.")
	var unsupported_model: Dictionary = service.model("barrier", unit_bp, {}, _callbacks(), true)
	_assert(unsupported_model.is_empty(), "Non-hero roles should not produce hero assembly template model.")
	if failed:
		quit(1)
		return
	print("UNIT_EDITOR_ASSEMBLY_TEMPLATE_SERVICE_CONTRACT_PROBE ok")
	quit(0)
