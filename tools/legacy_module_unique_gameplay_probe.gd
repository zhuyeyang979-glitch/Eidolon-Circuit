extends SceneTree

const MainScene := preload("res://scripts/main.gd")

const EXPECTED := {
	"COMBO ROUTER: BALANCE STRING": ["balance_string", "balance_string", "combo_balance_cooldown_mult"],
	"CLAMP ROUTER: VISE CLOSE": ["vise_close", "vise_close", "clamp_pin_seconds"],
	"ROUTE ROUTER: PICKUP DASH": ["pickup_dash", "pickup_dash", "pickup_dash_impulse"],
	"MONSTER ROUTER: CRUSH WINDUP": ["crush_windup", "crush_windup", "crush_contact_momentum_mult"],
	"DUEL ROUTER: FEINT THRUST": ["feint_thrust", "feint_thrust", "feint_retarget_degrees"],
	"SALVO ROUTER: EXPLOSIVE ARC": ["explosive_arc_salvo", "explosive_arc", "salvo_arc_max_range"],
}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _module_part(main, name: String) -> Dictionary:
	var index: int = main._component_index_by_exact_name("hero", "module", name)
	if index < 0:
		_fail("Missing module catalog part: %s" % name)
		return {}
	return main._selected_component("hero", "module", index)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	for raw_name in EXPECTED.keys():
		var name := String(raw_name)
		var expected: Array = Array(EXPECTED[name])
		var part := _module_part(main, name)
		if part.is_empty():
			return
		if main._part_is_catalog_frozen("module", part):
			_fail("%s should remain live." % name)
		if String(part.get("module_variant_key", "")) != String(expected[0]):
			_fail("%s variant expected %s, got %s." % [name, String(expected[0]), String(part.get("module_variant_key", ""))])
		if String(part.get("module_visual_family", "")) != String(expected[1]):
			_fail("%s visual family expected %s, got %s." % [name, String(expected[1]), String(part.get("module_visual_family", ""))])
		if not part.has(String(expected[2])):
			_fail("%s missing gameplay parameter %s." % [name, String(expected[2])])
		if String(part.get("module_variant_summary", "")).strip_edges() == "":
			_fail("%s missing variant hover summary." % name)
		var detail_lines: Array = main._hover_card_player_detail_lines("module", part)
		var joined := "\n".join(detail_lines)
		if joined.find(String(part.get("module_variant_label", ""))) < 0:
			_fail("%s hover detail does not expose variant label. lines=%s" % [name, joined])
	print("LEGACY_MODULE_UNIQUE_GAMEPLAY_PROBE ok modules=%d" % EXPECTED.size())
	quit()
