extends SceneTree

const PART_IDENTITY_PATH := "res://scripts/part_identity.gd"
const PartIdentity := preload("res://scripts/part_identity.gd")

var failed := false


func _fail(message: String) -> void:
	push_error(message)
	failed = true


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)


func _source_contains(path: String, needle: String) -> bool:
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))
	return source.find(needle) >= 0


func _init() -> void:
	if load(PART_IDENTITY_PATH) == null:
		_fail("Missing PartIdentity script.")
		quit(1)
		return
	var torso_part := {
		"name": "Crab Core",
		"stable_key": "torso_crab_core",
		"is_torso": true,
		"joint_ports": 4,
	}
	var torso_identity: Dictionary = PartIdentity.identity_for("muscle", torso_part, "zh")
	_assert(String(torso_identity.get("prefix", "")) == "TRS", "Torso identity should use TRS prefix.")
	_assert(String(torso_identity.get("code", "")).begins_with("TRS-"), "Torso identity code should expose a readable TRS family.")
	_assert(int(torso_identity.get("scan_level", -1)) == PartIdentity.FULL_SCAN, "Default identity should be fully scanned.")
	_assert(String(torso_identity.get("family", "")).find("躯干") >= 0, "Chinese torso family should be localized.")
	var partial_identity: Dictionary = PartIdentity.identity_for("muscle", torso_part, "en", PartIdentity.PARTIAL_SCAN)
	_assert(String(partial_identity.get("code", "")).find("??") >= 0, "Partial scan should hide exact subtype.")
	_assert(int(partial_identity.get("scan_level", -1)) == PartIdentity.PARTIAL_SCAN, "Partial identity should preserve scan level.")
	var unknown_identity: Dictionary = PartIdentity.identity_for("muscle", torso_part, "en", PartIdentity.UNKNOWN_SCAN)
	_assert(String(unknown_identity.get("code", "")).begins_with("???-"), "Unknown scan should hide family code.")
	_assert(String(unknown_identity.get("family", "")).to_lower().find("unknown") >= 0, "Unknown scan should expose only coarse identity.")
	var gun_part := {
		"name": "Glass Laser Rifle",
		"stable_key": "laser_rifle",
		"gun_kind": "laser",
		"projectile_style": "beam",
	}
	var gun_identity: Dictionary = PartIdentity.identity_for("muscle", gun_part, "en")
	_assert(String(gun_identity.get("prefix", "")) == "GUN", "Ranged terminal weapon should use GUN prefix.")
	_assert(String(gun_identity.get("subcode", "")) == "LSR", "Laser terminal weapon should use LSR subtype.")
	_assert(String(PartIdentity.signature_for("muscle", gun_part, "en")) == String(gun_identity.get("signature", "")), "signature_for should match identity signature.")
	for view_path in [
		"res://scripts/views/catalog/part_catalog_card_button.gd",
		"res://scripts/views/catalog/catalog_card_retained_item.gd",
		"res://scripts/views/catalog/part_preview_texture_render_canvas.gd",
		"res://scripts/views/editor/editor_part_hover_popup_view.gd",
		"res://scripts/views/battle_part_preview_view.gd",
	]:
		_assert(_source_contains(view_path, "res://scripts/part_identity.gd"), "%s should preload PartIdentity." % view_path)
	if failed:
		quit(1)
		return
	print("PART_IDENTITY_CONTRACT_PROBE ok")
	quit(0)
