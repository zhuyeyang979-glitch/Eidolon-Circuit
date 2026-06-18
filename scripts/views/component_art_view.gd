extends Control
class_name ComponentArtView

const PartArt = preload("res://scripts/part_art.gd")

var slot_key := ""
var part := {}
var snap_amount := 0.0
var image2_part_art_cache := {}
var asset_sheet: Texture2D
var joint_sheet: Texture2D
var limb_muscle_sheet: Texture2D
var blade_weapon_sheet: Texture2D
var blunt_weapon_sheet: Texture2D
var pierce_weapon_sheet: Texture2D
var torso_sheet: Texture2D
var booster_sheet: Texture2D
var engine_sheet: Texture2D
var last_component_signature := ""

func set_asset_sheet(texture: Texture2D) -> void:
	asset_sheet = texture
	queue_redraw()

func set_joint_sheet(texture: Texture2D) -> void:
	joint_sheet = texture
	queue_redraw()

func set_limb_muscle_sheet(texture: Texture2D) -> void:
	limb_muscle_sheet = texture
	queue_redraw()

func set_blade_weapon_sheet(texture: Texture2D) -> void:
	blade_weapon_sheet = texture
	queue_redraw()

func set_blunt_weapon_sheet(texture: Texture2D) -> void:
	blunt_weapon_sheet = texture
	queue_redraw()

func set_pierce_weapon_sheet(texture: Texture2D) -> void:
	pierce_weapon_sheet = texture
	queue_redraw()

func set_torso_sheet(texture: Texture2D) -> void:
	torso_sheet = texture
	queue_redraw()

func set_booster_sheet(texture: Texture2D) -> void:
	booster_sheet = texture
	queue_redraw()

func set_engine_sheet(texture: Texture2D) -> void:
	engine_sheet = texture
	queue_redraw()

func set_component(next_slot: String, next_part: Dictionary, next_snap: float = 0.0) -> void:
	var snap_key := snappedf(next_snap, 0.01)
	var signature := "%s|%s|%s|%s|%s|%s|%s|%s" % [
		next_slot,
		String(next_part.get("name", "")),
		str(next_part.get("cost", "")),
		str(next_part.get("mass", "")),
		str(next_part.get("length", "")),
		str(next_part.get("radius", "")),
		str(next_part.get("shape", "")),
		str(snap_key),
	]
	if signature == last_component_signature:
		return
	last_component_signature = signature
	slot_key = next_slot
	part = next_part.duplicate(true)
	snap_amount = next_snap
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.018, 0.026, 0.032, 0.96), true)
	_draw_grid()
	var center := size * 0.5
	var scale := minf(size.x, size.y) / 210.0
	var glow := clampf(snap_amount, 0.0, 1.0)
	if glow > 0.0:
		draw_circle(center, 82.0 * scale + glow * 18.0, Color(0.3, 0.92, 1.0, 0.18 * glow))
		draw_arc(center, 92.0 * scale + glow * 22.0, 0.0, TAU, 40, Color(1.0, 0.88, 0.28, 0.55 * glow), 3.0)
	_draw_component(center, scale)

func _asset_region_for_component() -> Rect2:
	var cell := asset_sheet.get_size() / 4.0
	var index := _asset_index_for_component()
	return Rect2(Vector2(float(index % 4) * cell.x, float(index / 4) * cell.y), cell)

func _joint_asset_region() -> Rect2:
	var cell := joint_sheet.get_size() / Vector2(4.0, 7.0)
	var column := _joint_material_column()
	var row := _joint_type_row()
	return Rect2(Vector2(float(column) * cell.x, float(row) * cell.y), cell)

func _joint_material_column() -> int:
	var name := String(part.get("name", "")).to_upper()
	var shape := String(part.get("shape", "")).to_lower()
	var material_class := String(part.get("material_class", "")).to_lower()
	if name.contains("CERAMIC") or name.contains("STONE") or shape.contains("ceramic") or material_class.contains("ceramic"):
		return 1
	if name.contains("WOOD") or name.contains("TIMBER") or name.contains("COMPOSITE") or shape.contains("wood") or material_class.contains("wood"):
		return 2
	if name.contains("FUR") or name.contains("SLEEVE") or name.contains("PADDED") or shape.contains("fur") or material_class.contains("fur"):
		return 3
	return 0

func _joint_type_row() -> int:
	var name := String(part.get("name", "")).to_upper()
	var shape := String(part.get("shape", "")).to_lower()
	var cancel_profile := String(part.get("cancel_profile", "")).to_lower()
	var joint_length := float(part.get("length", 0.12))
	var joint_range := float(part.get("range", 0.0))
	if _part_is_fixed_corner_joint():
		return 5
	if name.contains("90") or shape.contains("ball_90") or shape.contains("socket_90"):
		return 0
	if name.contains("180") or name.contains("YOKE") or name.contains("GIMBAL") or shape.contains("ball_180") or cancel_profile == "bidirectional":
		return 1
	if name.contains("CURVED") or name.contains("ARC") or shape.contains("curved") or shape.contains("arc"):
		return 5 if joint_length <= 0.34 else 6
	if name.contains("TELESCOPIC") or name.contains("LINEAR") or joint_range > 0.08:
		if joint_length <= 0.12:
			return 2
		if joint_length <= 0.32:
			return 3
		return 4
	if joint_length >= 0.42:
		return 4
	return 0

func _part_is_fixed_corner_joint() -> bool:
	var shape := String(part.get("shape", "")).to_lower()
	return bool(part.get("fixed_corner_joint", false)) or shape.contains("corner") or int(part.get("connection_angle_degrees", 0)) == 90

func _draw_fixed_corner_joint_overlay(center: Vector2, scale: float, color: Color, light: Color, dark: Color) -> void:
	var p0 := center + Vector2(-72.0, 44.0) * scale
	var corner := center + Vector2(-18.0, 44.0) * scale
	var p1 := center + Vector2(-18.0, -62.0) * scale
	var width := 18.0 * scale
	draw_line(p0, corner, dark, width + 8.0 * scale)
	draw_line(corner, p1, dark, width + 8.0 * scale)
	draw_line(p0, corner, color, width)
	draw_line(corner, p1, color, width)
	draw_circle(corner, 26.0 * scale, light)
	draw_circle(corner, 13.0 * scale, dark)
	draw_line(corner + Vector2(20.0, 0.0) * scale, corner + Vector2(20.0, -40.0) * scale, Color(0.9, 1.0, 1.0, 0.72), 3.0 * scale)
	draw_line(corner + Vector2(20.0, -40.0) * scale, corner + Vector2(58.0, -40.0) * scale, Color(0.9, 1.0, 1.0, 0.72), 3.0 * scale)
	draw_string(ThemeDB.get_fallback_font(), center + Vector2(14.0, 34.0) * scale, "90", HORIZONTAL_ALIGNMENT_CENTER, 54.0 * scale, int(32.0 * scale), Color(0.92, 1.0, 1.0, 0.9))

func _limb_muscle_asset_region() -> Rect2:
	var cell := limb_muscle_sheet.get_size() / Vector2(4.0, 3.0)
	var column := _limb_muscle_material_column()
	var row := _limb_muscle_length_row()
	return Rect2(Vector2(float(column) * cell.x, float(row) * cell.y), cell)

func _limb_muscle_material_column() -> int:
	var name := String(part.get("name", "")).to_upper()
	var shape := String(part.get("shape", "")).to_lower()
	var material_class := String(part.get("material_class", "")).to_lower()
	if name.contains("CERAMIC") or name.contains("SHIN") or shape.contains("ceramic") or material_class.contains("ceramic"):
		return 1
	if name.contains("WOOD") or name.contains("STAKE") or name.contains("COMPOSITE") or shape.contains("wood") or shape.contains("stake") or material_class.contains("wood"):
		return 2
	if name.contains("FUR") or name.contains("SLEEVE") or name.contains("FIBER") or shape.contains("fur") or material_class.contains("fur"):
		return 3
	return 0

func _limb_muscle_length_row() -> int:
	var muscle_length := float(part.get("length", 0.48))
	if muscle_length <= 0.4:
		return 0
	if muscle_length <= 0.7:
		return 1
	return 2

func _blade_weapon_asset_region() -> Rect2:
	var cell := blade_weapon_sheet.get_size() / Vector2(3.0, 3.0)
	var column := _blade_weapon_family_column()
	var row := _blade_weapon_length_row()
	return Rect2(Vector2(float(column) * cell.x, float(row) * cell.y), cell)

func _part_is_blade_weapon() -> bool:
	var name := String(part.get("name", "")).to_upper()
	var shape := String(part.get("shape", "")).to_lower()
	var damage_type := String(part.get("damage_type", ""))
	var material_class := String(part.get("material_class", "")).to_lower()
	var terminal_like := bool(part.get("terminal_weapon", false)) or int(part.get("connection_ends", 2)) <= 1 or material_class in ["weapon", "racket"]
	return damage_type == "tear" and (terminal_like or name.contains("SCYTHE") or name.contains("KATANA") or name.contains("GREATSWORD") or name.contains("GREAT SWORD") or name.contains("BUSTER") or name.contains("ODACHI") or name.contains("MACHETE") or name.contains("RAZOR") or name.contains("SABER") or name.contains("WING") or name.contains("TAIL") or shape.contains("scythe") or shape.contains("katana") or shape.contains("greatsword") or shape.contains("great_sword") or shape.contains("machete") or shape.contains("blade") or shape.contains("razor") or shape.contains("saber") or shape.contains("wing") or shape.contains("tail"))

func _blade_weapon_family_column() -> int:
	var name := String(part.get("name", "")).to_upper()
	var shape := String(part.get("shape", "")).to_lower()
	if name.contains("SCYTHE") or shape.contains("scythe") or shape.contains("crescent"):
		return 0
	if name.contains("KATANA") or name.contains("ODACHI") or shape.contains("katana") or shape.contains("saber"):
		return 1
	return 2

func _blade_weapon_length_row() -> int:
	var name := String(part.get("name", "")).to_upper()
	var muscle_length := float(part.get("length", 0.66))
	var mass := float(part.get("mass", 8.0))
	if name.contains("SHORT") or name.contains("LIGHT") or muscle_length <= 0.52 or mass <= 5.0:
		return 0
	if name.contains("LONG") or name.contains("HEAVY") or name.contains("KAIJU") or name.contains("COLOSSUS") or muscle_length >= 1.0 or mass >= 28.0:
		return 2
	return 1

func _blunt_weapon_asset_region() -> Rect2:
	var cell := blunt_weapon_sheet.get_size() / Vector2(3.0, 3.0)
	var column := _blunt_weapon_family_column()
	var row := _blunt_weapon_length_row()
	return Rect2(Vector2(float(column) * cell.x, float(row) * cell.y), cell)

func _part_is_blunt_weapon() -> bool:
	var name := String(part.get("name", "")).to_upper()
	var shape := String(part.get("shape", "")).to_lower()
	var damage_type := String(part.get("damage_type", ""))
	var material_class := String(part.get("material_class", "")).to_lower()
	var terminal_like := bool(part.get("terminal_weapon", false)) or int(part.get("connection_ends", 2)) <= 1 or material_class in ["weapon", "racket"]
	return damage_type == "blunt" and (terminal_like or name.contains("SHIELD") or name.contains("BUCKLER") or name.contains("HAMMER") or name.contains("MACE") or name.contains("GLOVE") or name.contains("GAUNTLET") or name.contains("FIST") or name.contains("JACK") or shape.contains("shield") or shape.contains("hammer") or shape.contains("glove") or shape.contains("gauntlet") or shape.contains("fist") or shape.contains("jack"))

func _blunt_weapon_family_column() -> int:
	var name := String(part.get("name", "")).to_upper()
	var shape := String(part.get("shape", "")).to_lower()
	if name.contains("SHIELD") or name.contains("BUCKLER") or shape.contains("shield") or shape.contains("buckler"):
		return 0
	if name.contains("HAMMER") or name.contains("MACE") or name.contains("JACK") or shape.contains("hammer") or shape.contains("jack") or shape.contains("mace"):
		return 1
	return 2

func _blunt_weapon_length_row() -> int:
	var name := String(part.get("name", "")).to_upper()
	var muscle_length := float(part.get("length", 0.5))
	var mass := float(part.get("mass", 9.0))
	if name.contains("SHORT") or name.contains("LIGHT") or name.contains("BUCKLER") or muscle_length <= 0.45 or mass <= 6.0:
		return 0
	if name.contains("LONG") or name.contains("HEAVY") or name.contains("COLOSSUS") or name.contains("TOWER") or muscle_length >= 0.95 or mass >= 32.0:
		return 2
	return 1

func _pierce_weapon_asset_region() -> Rect2:
	var cell := pierce_weapon_sheet.get_size() / Vector2(3.0, 3.0)
	var column := _pierce_weapon_family_column()
	var row := _pierce_weapon_length_row()
	return Rect2(Vector2(float(column) * cell.x, float(row) * cell.y), cell)

func _part_is_pierce_weapon() -> bool:
	var name := String(part.get("name", "")).to_upper()
	var shape := String(part.get("shape", "")).to_lower()
	var damage_type := String(part.get("damage_type", ""))
	var material_class := String(part.get("material_class", "")).to_lower()
	var terminal_like := bool(part.get("terminal_weapon", false)) or int(part.get("connection_ends", 2)) <= 1 or material_class in ["weapon", "racket"]
	return damage_type == "pierce" and (terminal_like or name.contains("LANCE") or name.contains("SPEAR") or name.contains("PIKE") or name.contains("HARPOON") or name.contains("RAPIER") or name.contains("FOIL") or name.contains("EPEE") or name.contains("NEEDLE") or name.contains("STILETTO") or name.contains("DRILL") or name.contains("AUGER") or name.contains("BORER") or name.contains("SPIKE") or name.contains("TALON") or shape.contains("lance") or shape.contains("spear") or shape.contains("pike") or shape.contains("harpoon") or shape.contains("rapier") or shape.contains("foil") or shape.contains("needle") or shape.contains("drill") or shape.contains("auger") or shape.contains("spike") or shape.contains("talon"))

func _pierce_weapon_family_column() -> int:
	var name := String(part.get("name", "")).to_upper()
	var shape := String(part.get("shape", "")).to_lower()
	if name.contains("DRILL") or name.contains("AUGER") or name.contains("BORER") or shape.contains("drill") or shape.contains("auger") or shape.contains("borer"):
		return 2
	if name.contains("RAPIER") or name.contains("FOIL") or name.contains("EPEE") or name.contains("NEEDLE") or name.contains("STILETTO") or name.contains("ROD") or shape.contains("rapier") or shape.contains("foil") or shape.contains("needle") or shape.contains("rod"):
		return 1
	return 0

func _pierce_weapon_length_row() -> int:
	var name := String(part.get("name", "")).to_upper()
	var muscle_length := float(part.get("length", 0.62))
	var mass := float(part.get("mass", 6.0))
	if name.contains("SHORT") or name.contains("LIGHT") or name.contains("MICRO") or name.contains("FOIL") or muscle_length <= 0.48 or mass <= 4.0:
		return 0
	if name.contains("LONG") or name.contains("HEAVY") or name.contains("TITAN") or name.contains("COLOSSUS") or name.contains("SIEGE") or muscle_length >= 1.05 or mass >= 30.0:
		return 2
	return 1

func _torso_asset_region() -> Rect2:
	var cell := torso_sheet.get_size() / Vector2(8.0, 4.0)
	var column := _torso_archetype_column()
	var row := _torso_material_row()
	return Rect2(Vector2(float(column) * cell.x, float(row) * cell.y), cell)

func _part_is_torso() -> bool:
	var material_class := String(part.get("material_class", "")).to_lower()
	return bool(part.get("is_torso", false)) or material_class == "torso"

func _torso_archetype_column() -> int:
	var name := String(part.get("name", "")).to_upper()
	var shape := String(part.get("shape", "")).to_lower()
	var archetype := String(part.get("archetype", "")).to_lower()
	var key := "%s %s %s" % [name.to_lower(), shape, archetype]
	if key.contains("shrimp") or key.contains("prawn") or key.contains("lobster"):
		return 1
	if key.contains("octopus") or key.contains("mantle") or key.contains("tentacle"):
		return 2
	if key.contains("snake") or key.contains("serpent"):
		return 3
	if key.contains("centipede") or key.contains("leviathan"):
		return 4
	if key.contains("tank") or key.contains("arsenal"):
		return 5
	if key.contains("hound") or key.contains("dog"):
		return 6
	if key.contains("human") or key.contains("pilot") or key.contains("humanoid") or key.contains("head") or key.contains("chest") or key.contains("scout_core"):
		return 7
	return 0

func _torso_material_row() -> int:
	var name := String(part.get("name", "")).to_upper()
	var visual := String(part.get("torso_material", part.get("material_visual", ""))).to_lower()
	if visual.contains("ceramic") or name.contains("CERAMIC") or name.contains("STONE"):
		return 1
	if visual.contains("wood") or name.contains("WOOD") or name.contains("TIMBER"):
		return 2
	if visual.contains("fur") or visual.contains("padded") or name.contains("FUR") or name.contains("PADDED") or name.contains("SLEEVE"):
		return 3
	return 0

func _booster_asset_region() -> Rect2:
	var cell := booster_sheet.get_size() / Vector2(3.0, 4.0)
	var column := _booster_family_column()
	var row := _booster_art_row()
	return Rect2(Vector2(float(column) * cell.x, float(row) * cell.y), cell)

func _booster_family_column() -> int:
	var flame := String(part.get("flame_color", "")).to_lower()
	var style := String(part.get("thruster_family", "")).to_lower()
	var name := String(part.get("name", "")).to_upper()
	if flame.contains("yellow") or style.contains("sustain") or name.contains("YELLOW") or name.contains("SUSTAIN"):
		return 1
	if flame.contains("red") or style.contains("overburn") or style.contains("burst") or name.contains("RED") or name.contains("OVERBURN"):
		return 2
	return 0

func _booster_art_row() -> int:
	var name := String(part.get("name", "")).to_upper()
	var mass := float(part.get("mass", 0.0))
	var momentum := float(part.get("boost_momentum", 0.0)) + float(part.get("drive_demand", part.get("momentum_min", part.get("allocated_momentum", 0.0))))
	if name.contains("NANO") or name.contains("MICRO") or mass <= 2.5 or momentum <= 70.0:
		return 0
	if name.contains("COLOSSUS") or name.contains("TITAN") or name.contains("SIEGE") or mass >= 34.0 or momentum >= 360.0:
		return 3
	if name.contains("HEAVY") or mass >= 10.0 or momentum >= 170.0:
		return 2
	return 1

func _engine_asset_region() -> Rect2:
	var cell := engine_sheet.get_size() / Vector2(3.0, 3.0)
	var column := _engine_family_column()
	var row := _engine_size_row()
	return Rect2(Vector2(float(column) * cell.x, float(row) * cell.y), cell)

func _engine_family_column() -> int:
	var name := String(part.get("name", "")).to_upper()
	var family := String(part.get("engine_family", "")).to_lower()
	if family.contains("furnace") or name.contains("FURNACE") or name.contains("TITAN") or name.contains("COLOSSUS"):
		return 2
	if family.contains("mobility") or name.contains("LIGHT") or name.contains("TURBINE") or name.contains("COMPACT"):
		return 1
	return 0

func _engine_size_row() -> int:
	var tier := String(part.get("slot_volume_tier", "")).to_upper()
	var power := float(part.get("power", 0.0))
	var mass := float(part.get("mass", 0.0))
	if tier in ["XS", "S"] or _engine_name_contains_any(["NANO", "SPARK"]) or power <= 28.0 or mass <= 3.0:
		return 0
	if tier == "XL" or _engine_name_contains_any(["TITAN", "COLOSSUS"]) or power >= 140.0 or mass >= 70.0:
		return 2
	return 1

func _engine_name_contains_any(tokens: Array) -> bool:
	var name := String(part.get("name", "")).to_upper()
	for token in tokens:
		if name.contains(String(token)):
			return true
	return false

func _asset_index_for_component() -> int:
	var name := String(part.get("name", "")).to_upper()
	var shape := String(part.get("shape", "")).to_lower()
	var material_class := String(part.get("material_class", ""))
	var damage_type := String(part.get("damage_type", part.get("projectile_damage_type", "blunt")))
	if slot_key == "special":
		return 0
	if slot_key == "joint":
		if name.contains("TELESCOPIC"):
			return 5
		if name.contains("VECTOR") or name.contains("BALL"):
			return 6
		if name.contains("CHAIN"):
			return 7
		return 4
	if slot_key == "limb_muscle":
		if material_class == "chain" or name.contains("CHAIN") or name.contains("TENDON"):
			return 7
		if name.contains("COLOSSUS") or name.contains("GIRDER"):
			return 14
		if name.contains("CERAMIC") or name.contains("SHIN"):
			return 5
		return 6
	if slot_key == "booster":
		return 15
	if slot_key == "engine" or slot_key == "cooling" or slot_key == "module":
		return 6
	if bool(part.get("projectile", false)) or material_class in ["gun", "missile_launcher"]:
		if name.contains("MISSILE") or name.contains("MORTAR") or name.contains("CANNON") or name.contains("TURRET") or shape.contains("missile") or shape.contains("mortar"):
			return 11
		if String(part.get("projectile_damage_type", damage_type)) == "laser":
			return 9
		if String(part.get("projectile_damage_type", damage_type)) == "chemical":
			return 10
		return 8
	if material_class == "chain" or name.contains("CHAIN") or name.contains("TENTACLE"):
		return 7
	if damage_type == "tear" or name.contains("SCYTHE") or name.contains("KATANA") or name.contains("BLADE") or name.contains("MACHETE"):
		return 12
	if damage_type == "pierce" or name.contains("SPIKE") or name.contains("LANCE") or name.contains("PIKE") or name.contains("TALON"):
		return 13
	return 14

func _draw_grid() -> void:
	for x in range(0, int(size.x), 28):
		draw_line(Vector2(float(x), 0.0), Vector2(float(x), size.y), Color(0.45, 0.92, 1.0, 0.05), 1.0)
	for y in range(0, int(size.y), 28):
		draw_line(Vector2(0.0, float(y)), Vector2(size.x, float(y)), Color(0.45, 0.92, 1.0, 0.05), 1.0)

func _image2_part_art_for_component() -> Dictionary:
	var part_id := _image2_part_id_for_component()
	if part_id == "" or not PartArt.IMAGE2_PART_TEXTURE_PATHS.has(part_id):
		return {}
	if image2_part_art_cache.has(part_id):
		return Dictionary(image2_part_art_cache[part_id])
	var path := String(PartArt.IMAGE2_PART_TEXTURE_PATHS[part_id])
	var image := Image.new()
	if image.load(path) != OK:
		image2_part_art_cache[part_id] = {}
		return {}
	var used_rect_i := image.get_used_rect()
	if used_rect_i.size.x <= 0 or used_rect_i.size.y <= 0:
		used_rect_i = Rect2i(Vector2i.ZERO, image.get_size())
	var used_rect := Rect2(
		Vector2(float(used_rect_i.position.x), float(used_rect_i.position.y)),
		Vector2(float(used_rect_i.size.x), float(used_rect_i.size.y))
	)
	var texture := ImageTexture.create_from_image(image)
	var art := {
		"id": part_id,
		"texture": texture,
		"region": used_rect,
	}
	image2_part_art_cache[part_id] = art
	return art


func _image2_part_id_for_component() -> String:
	if part.is_empty():
		return ""
	var style := PartArt.style_for(slot_key, part, "card")
	var resolved_slot := String(style.get("slot", slot_key))
	var shape_kind := String(style.get("shape_kind", "")).to_lower()
	var terminal_profile := String(style.get("terminal_profile", "")).to_lower()
	var software_icon := String(style.get("software_icon_kind", "")).to_lower()
	var material_style := String(style.get("material_style", "")).to_lower()
	var damage_style := String(style.get("damage_style", "")).to_lower()
	var key := _image2_part_match_key()
	if resolved_slot == "torso":
		return "torso_core"
	if resolved_slot == "joint":
		return "telescopic_joint" if shape_kind.contains("telescopic") or key.contains("rail") else "ball_joint"
	if resolved_slot == "limb_muscle":
		if shape_kind.contains("barrier") or shape_kind.contains("girder") or shape_kind.contains("steel") or key.contains("heavy") or key.contains("shield"):
			return "heavy_barrier_strut"
		return "light_forearm_strut"
	if resolved_slot == "booster" or shape_kind == "thruster_nozzle":
		return "thruster_nozzle_pair"
	if resolved_slot == "engine" or software_icon == "engine_core":
		return "engine_reactor_capsule"
	if resolved_slot == "cooling" or software_icon == "cooling_fins":
		return "cooling_fin_module"
	if resolved_slot == "barrier_tile" or shape_kind.contains("plate") or shape_kind.contains("panel") or shape_kind.contains("field") or key.contains("barrier"):
		return "barrier_emitter_plate"
	if resolved_slot == "special" or software_icon in ["soul_star", "source_star", "ether_orbit"]:
		return "soul_source_ether_chip"
	if resolved_slot == "ammo" or software_icon == "ammo_stack" or key.contains("ammo"):
		return "ammo_pod"
	if resolved_slot in ["module", "software"] or shape_kind == "software_chip" or material_style == "software":
		return "sensor_eye_array"
	if resolved_slot == "projectile" or _image2_terminal_profile_is_ranged(terminal_profile) or _image2_key_is_ranged(key):
		if terminal_profile.contains("missile") or terminal_profile.contains("launcher") or key.contains("missile") or key.contains("rocket") or damage_style == "explosive":
			return "missile_tube_pod"
		return "railgun_pod"
	if resolved_slot == "terminal":
		if terminal_profile.contains("shield"):
			return "barrier_emitter_plate"
		if terminal_profile.contains("claw") or key.contains("claw") or key.contains("jaw") or key.contains("talon") or key.contains("pincer"):
			return "paired_pincer_claw"
		return "curved_blade_claw"
	return ""


func _image2_part_match_key() -> String:
	return ("%s %s %s %s %s %s %s %s" % [
		String(part.get("name", "")),
		String(part.get("component_name", "")),
		String(part.get("label", "")),
		String(part.get("shape", "")),
		String(part.get("material_class", "")),
		String(part.get("weapon_family", "")),
		String(part.get("gun_kind", "")),
		String(part.get("projectile_style", "")),
	]).to_lower()


func _image2_terminal_profile_is_ranged(terminal_profile: String) -> bool:
	return terminal_profile in [
		"web_spool_gun",
		"missile_tube_pod",
		"prism_laser_gun",
		"chemical_sprayer",
		"grenade_launcher",
		"heavy_launcher",
		"scoped_sniper",
		"stocked_rifle",
		"muzzle",
	]


func _image2_key_is_ranged(key: String) -> bool:
	for token in ["gun", "rifle", "cannon", "launcher", "missile", "laser", "mortar", "turret", "sniper"]:
		if key.contains(token):
			return true
	return false


func _draw_image2_component_art(art: Dictionary, center: Vector2) -> void:
	var texture := art.get("texture", null) as Texture2D
	var region: Rect2 = art.get("region", Rect2())
	if texture == null or region.size.x <= 0.0 or region.size.y <= 0.0:
		return
	var max_draw_size := Vector2(maxf(24.0, size.x - 24.0), maxf(24.0, size.y - 10.0))
	var fit := minf(max_draw_size.x / region.size.x, max_draw_size.y / region.size.y)
	var draw_size := region.size * fit
	var draw_rect := Rect2(center - draw_size * 0.5, draw_size)
	draw_texture_rect_region(texture, draw_rect, region, Color.WHITE)


func _draw_component(center: Vector2, scale: float) -> void:
	var name := String(part.get("name", ""))
	var shape := String(part.get("shape", ""))
	var color := _part_color()
	var dark := color.darkened(0.45)
	var light := color.lerp(Color.WHITE, 0.38)
	var image2_art := _image2_part_art_for_component()
	if not image2_art.is_empty():
		_draw_image2_component_art(image2_art, center)
		return
	if slot_key == "special":
		_draw_diamond(center, 58.0 * scale, color)
		draw_circle(center, 20.0 * scale, Color(1.0, 0.88, 0.28, 0.85))
		for i in range(6):
			var angle := TAU * float(i) / 6.0
			draw_line(center + Vector2(cos(angle), sin(angle)) * 24.0 * scale, center + Vector2(cos(angle), sin(angle)) * 58.0 * scale, light, 2.0 * scale)
	elif slot_key == "joint":
		if _part_is_fixed_corner_joint():
			_draw_fixed_corner_joint_overlay(center, scale, color, light, dark)
		elif name.contains("HINGE"):
			draw_line(center + Vector2(-70.0, 0.0) * scale, center + Vector2(70.0, 0.0) * scale, light, 9.0 * scale)
			draw_circle(center, 32.0 * scale, color)
			draw_circle(center, 15.0 * scale, dark)
		elif name.contains("VECTOR"):
			_draw_triangle(center + Vector2(-34.0, 0.0) * scale, 40.0 * scale, -PI * 0.5, color)
			_draw_triangle(center + Vector2(34.0, 0.0) * scale, 40.0 * scale, PI * 0.5, light)
			draw_circle(center, 18.0 * scale, dark)
		elif name.contains("LOCK"):
			draw_rect(Rect2(center - Vector2(48.0, 48.0) * scale, Vector2(96.0, 96.0) * scale), color, true)
			draw_rect(Rect2(center - Vector2(26.0, 26.0) * scale, Vector2(52.0, 52.0) * scale), dark, true)
		else:
			for i in range(4):
				draw_rect(Rect2(center + Vector2(-76.0 + float(i) * 38.0, -16.0) * scale, Vector2(26.0, 32.0) * scale), color.lerp(light, float(i) * 0.18), true)
			draw_line(center + Vector2(-76.0, 0.0) * scale, center + Vector2(74.0, 0.0) * scale, light, 5.0 * scale)
	elif slot_key == "limb_muscle":
		var axis := Vector2.RIGHT
		var radius := 18.0 * scale
		if shape.contains("chain"):
			for i in range(6):
				var x := -72.0 + float(i) * 28.0
				draw_circle(center + Vector2(x, sin(float(i)) * 7.0) * scale, 13.0 * scale, color.lerp(light, float(i) * 0.08))
				draw_line(center + Vector2(x + 10.0, sin(float(i)) * 7.0) * scale, center + Vector2(x + 26.0, sin(float(i + 1)) * 7.0) * scale, light, 5.0 * scale)
		else:
			draw_line(center - axis * 82.0 * scale, center + axis * 82.0 * scale, dark, radius)
			draw_line(center - axis * 64.0 * scale, center + axis * 64.0 * scale, color, radius * 0.72)
			for x in [-82.0, 82.0]:
				draw_circle(center + Vector2(x, 0.0) * scale, 15.0 * scale, light)
				draw_circle(center + Vector2(x, 0.0) * scale, 7.0 * scale, dark)
			for i in range(5):
				var rib_x := -48.0 + float(i) * 24.0
				draw_line(center + Vector2(rib_x, -16.0) * scale, center + Vector2(rib_x + 10.0, 16.0) * scale, light.lerp(color, 0.35), 3.0 * scale)
	elif slot_key == "muscle":
		if _part_is_torso():
			var port_count := PartArt.torso_saddle_port_count(part)
			var length := 168.0 * scale
			var front_width := 60.0 * scale
			var rear_width := 118.0 * scale
			draw_colored_polygon(_component_saddle_polygon(center, Vector2.RIGHT, length, front_width, rear_width), dark)
			draw_colored_polygon(_component_saddle_polygon(center, Vector2.RIGHT, length * 0.62, front_width * 0.58, rear_width * 0.58), color)
			draw_line(center + Vector2(length * 0.5, -front_width * 0.42), center + Vector2(length * 0.5, front_width * 0.42), light, maxf(1.0, 3.0 * scale))
			for port_pos in _component_saddle_port_positions(center, Vector2.RIGHT, port_count, length, front_width, rear_width):
				draw_circle(port_pos, maxf(4.0, 6.0 * scale), light)
				draw_circle(port_pos, maxf(1.6, 2.4 * scale), dark)
			return
		# Base part art is procedural-only. Legacy image sheets are
		# intentionally ignored here so TeamEdit previews and combat use the
		# same AssemblyBoard-style visual language.
		if shape == "electronic_armor" or shape == "shield_software":
			draw_circle(center, 62.0 * scale, Color(0.08, 0.22, 0.34, 0.92))
			draw_arc(center, 74.0 * scale, 0.0, TAU, 54, Color(0.36, 0.92, 1.0, 0.82), 5.0 * scale)
			draw_arc(center, 46.0 * scale, -0.7, TAU - 0.7, 48, Color(0.86, 1.0, 1.0, 0.72), 3.0 * scale)
			for i in range(6):
				var angle := TAU * float(i) / 6.0
				var p0 := center + Vector2(cos(angle), sin(angle)) * 20.0 * scale
				var p1 := center + Vector2(cos(angle + 0.34), sin(angle + 0.34)) * 58.0 * scale
				draw_line(p0, p1, color.lerp(Color.WHITE, 0.32), 3.0 * scale)
			draw_string(ThemeDB.get_fallback_font(), center + Vector2(-31.0, 12.0) * scale, "SH", HORIZONTAL_ALIGNMENT_CENTER, 36.0 * scale, int(64.0 * scale), Color(0.9, 1.0, 1.0, 0.95))
		elif shape == "web_gun":
			draw_rect(Rect2(center + Vector2(-74.0, -18.0) * scale, Vector2(104.0, 36.0) * scale), dark, true)
			draw_rect(Rect2(center + Vector2(20.0, -10.0) * scale, Vector2(66.0, 20.0) * scale), color.lerp(Color.WHITE, 0.16), true)
			for i in range(4):
				draw_arc(center + Vector2(-34.0 + float(i) * 17.0, 0.0) * scale, 16.0 * scale, -1.2, 1.2, 18, Color(0.84, 0.96, 1.0, 0.72), 2.0 * scale)
			draw_line(center + Vector2(84.0, 0.0) * scale, center + Vector2(116.0, -22.0) * scale, Color(0.86, 0.96, 1.0, 0.86), 2.0 * scale)
			draw_line(center + Vector2(84.0, 0.0) * scale, center + Vector2(118.0, 22.0) * scale, Color(0.86, 0.96, 1.0, 0.86), 2.0 * scale)
			draw_circle(center + Vector2(94.0, 0.0) * scale, 8.0 * scale, Color(0.9, 0.98, 1.0, 1.0))
		elif shape == "light_sink":
			draw_rect(Rect2(center + Vector2(-76.0, -20.0) * scale, Vector2(112.0, 40.0) * scale), dark, true)
			draw_circle(center + Vector2(42.0, 0.0) * scale, 34.0 * scale, Color(0.02, 0.0, 0.06, 1.0))
			draw_arc(center + Vector2(42.0, 0.0) * scale, 42.0 * scale, 0.0, TAU, 42, Color(0.54, 0.74, 1.0, 0.72), 3.0 * scale)
			for i in range(8):
				var angle := TAU * float(i) / 8.0
				draw_line(center + Vector2(42.0, 0.0) * scale, center + Vector2(42.0, 0.0) * scale + Vector2(cos(angle), sin(angle)) * 64.0 * scale, Color(0.1, 0.02, 0.22, 0.42), 3.0 * scale)
		elif shape == "drone_core":
			draw_circle(center, 54.0 * scale, dark)
			draw_circle(center, 34.0 * scale, color)
			draw_circle(center, 14.0 * scale, Color(0.9, 0.98, 1.0, 0.9))
			for i in range(6):
				var angle := TAU * float(i) / 6.0
				var p0 := center + Vector2(cos(angle), sin(angle)) * 38.0 * scale
				var p1 := center + Vector2(cos(angle), sin(angle)) * 76.0 * scale
				draw_line(p0, p1, light, 4.0 * scale)
				draw_circle(p1, 7.0 * scale, color.lerp(Color.WHITE, 0.25))
		elif shape == "gun":
			draw_rect(Rect2(center + Vector2(-70.0, -18.0) * scale, Vector2(108.0, 36.0) * scale), dark, true)
			draw_rect(Rect2(center + Vector2(26.0, -9.0) * scale, Vector2(62.0, 18.0) * scale), color, true)
			draw_rect(Rect2(center + Vector2(-48.0, 18.0) * scale, Vector2(28.0, 42.0) * scale), color.darkened(0.2), true)
			draw_circle(center + Vector2(94.0, 0.0) * scale, 9.0 * scale, _damage_color(String(part.get("projectile_damage_type", "bullet"))))
		elif shape == "scythe":
			draw_arc(center + Vector2(4.0, 16.0) * scale, 72.0 * scale, -2.2, 0.7, 38, light, 14.0 * scale)
			draw_line(center + Vector2(-64.0, 42.0) * scale, center + Vector2(46.0, -44.0) * scale, dark, 8.0 * scale)
			draw_circle(center + Vector2(-64.0, 42.0) * scale, 12.0 * scale, color)
		elif shape == "spike":
			_draw_triangle(center + Vector2(18.0, 0.0) * scale, 86.0 * scale, PI * 0.5, color)
			draw_rect(Rect2(center + Vector2(-78.0, -18.0) * scale, Vector2(70.0, 36.0) * scale), dark, true)
		elif shape == "glove":
			draw_rect(Rect2(center + Vector2(-78.0, -16.0) * scale, Vector2(60.0, 32.0) * scale), dark, true)
			for i in range(4):
				draw_circle(center + Vector2(-4.0 + float(i) * 22.0, -20.0) * scale, 18.0 * scale, color.lerp(light, float(i) * 0.12))
			draw_circle(center + Vector2(28.0, 18.0) * scale, 38.0 * scale, color)
		elif shape == "hammer":
			draw_line(center + Vector2(-82.0, 30.0) * scale, center + Vector2(42.0, -32.0) * scale, dark, 13.0 * scale)
			draw_rect(Rect2(center + Vector2(24.0, -62.0) * scale, Vector2(70.0, 46.0) * scale), color, true)
			draw_rect(Rect2(center + Vector2(8.0, -50.0) * scale, Vector2(18.0, 24.0) * scale), light, true)
		elif shape == "jack":
			draw_rect(Rect2(center + Vector2(-78.0, -14.0) * scale, Vector2(96.0, 28.0) * scale), dark, true)
			draw_rect(Rect2(center + Vector2(12.0, -8.0) * scale, Vector2(72.0, 16.0) * scale), color, true)
			draw_line(center + Vector2(-36.0, -36.0) * scale, center + Vector2(42.0, 36.0) * scale, light, 5.0 * scale)
			draw_line(center + Vector2(-36.0, 36.0) * scale, center + Vector2(42.0, -36.0) * scale, light, 5.0 * scale)
		elif shape.begins_with("wood"):
			var amp := 34.0 if shape == "wood_curve_large" else (16.0 if shape == "wood_curve_small" else 0.0)
			var pts := PackedVector2Array()
			for i in range(18):
				var t := float(i) / 17.0
				pts.append(center + Vector2(lerpf(-86.0, 86.0, t), sin(t * PI) * amp) * scale)
			draw_polyline(pts, Color(0.78, 0.7, 0.52, 1.0), 15.0 * scale)
			draw_circle(center + Vector2(-90.0, 0.0) * scale, 10.0 * scale, light)
			draw_circle(center + Vector2(90.0, 0.0) * scale, 10.0 * scale, light)
		elif shape == "crab":
			draw_rect(Rect2(center + Vector2(-70.0, -44.0) * scale, Vector2(140.0, 88.0) * scale), dark, true)
			for i in range(6):
				var side := -1.0 if i < 3 else 1.0
				var y := -34.0 + float(i % 3) * 34.0
				draw_line(center + Vector2(side * 70.0, y) * scale, center + Vector2(side * 112.0, y + side * 4.0) * scale, light, 5.0 * scale)
			draw_circle(center, 24.0 * scale, color)
		elif shape == "machete":
			draw_line(center + Vector2(-84.0, 34.0) * scale, center + Vector2(58.0, -36.0) * scale, dark, 8.0 * scale)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-22.0, -16.0) * scale, center + Vector2(92.0, -56.0) * scale, center + Vector2(78.0, -4.0) * scale, center + Vector2(-8.0, 22.0) * scale]), color)
		elif shape == "katana":
			draw_line(center + Vector2(-88.0, 42.0) * scale, center + Vector2(88.0, -44.0) * scale, light, 7.0 * scale)
			draw_line(center + Vector2(-74.0, 36.0) * scale, center + Vector2(-34.0, 14.0) * scale, dark, 12.0 * scale)
			draw_rect(Rect2(center + Vector2(-38.0, 4.0) * scale, Vector2(18.0, 8.0) * scale), color, true)
		elif shape == "pike":
			draw_line(center + Vector2(-92.0, 0.0) * scale, center + Vector2(54.0, 0.0) * scale, dark, 8.0 * scale)
			_draw_triangle(center + Vector2(86.0, 0.0) * scale, 38.0 * scale, PI * 0.5, color)
		elif shape == "cactus":
			draw_rect(Rect2(center + Vector2(-60.0, -16.0) * scale, Vector2(80.0, 32.0) * scale), dark, true)
			for i in range(9):
				var angle := -0.9 + float(i) * 0.22
				var base := center + Vector2(14.0 + float(i % 3) * 10.0, -18.0 + float(floori(float(i) / 3.0)) * 18.0) * scale
				draw_line(base, base + Vector2(cos(angle), sin(angle)) * 42.0 * scale, color, 4.0 * scale)
		elif shape in ["octopus", "bull", "hound", "lizard", "centipede", "roach", "bird", "dino"]:
			var side_map: Dictionary = {"octopus": 8, "bull": 5, "hound": 6, "lizard": 7, "centipede": 10, "roach": 6, "bird": 5, "dino": 7}
			var sides: int = int(side_map.get(shape, 6))
			draw_colored_polygon(_regular_preview_polygon(center, 62.0 * scale, int(sides)), dark)
			draw_colored_polygon(_regular_preview_polygon(center, 38.0 * scale, int(sides)), color)
			for i in range(int(sides)):
				var angle := TAU * float(i) / float(sides)
				draw_line(center + Vector2(cos(angle), sin(angle)) * 44.0 * scale, center + Vector2(cos(angle), sin(angle)) * 78.0 * scale, light, 4.0 * scale)
		elif shape in ["tentacle", "antenna"]:
			var pts := PackedVector2Array()
			for i in range(22):
				var t := float(i) / 21.0
				pts.append(center + Vector2(lerpf(-92.0, 92.0, t), sin(t * TAU * 1.5) * 28.0) * scale)
			draw_polyline(pts, color, 10.0 * scale)
			draw_polyline(pts, light, 3.0 * scale)
		elif shape in ["horn", "talon", "pike", "gecko_claw", "paw", "segment_leg"]:
			draw_line(center + Vector2(-78.0, 18.0) * scale, center + Vector2(34.0, -18.0) * scale, dark, 9.0 * scale)
			_draw_triangle(center + Vector2(76.0, -22.0) * scale, 40.0 * scale, PI * 0.5, color)
			if shape in ["paw", "gecko_claw", "segment_leg"]:
				for i in range(3):
					draw_circle(center + Vector2(20.0 + float(i) * 18.0, 22.0) * scale, 10.0 * scale, light)
		elif shape in ["jaw", "dino_jaw"]:
			draw_arc(center + Vector2(-8.0, 4.0) * scale, 62.0 * scale, -0.8, 0.8, 24, color, 13.0 * scale)
			draw_arc(center + Vector2(-8.0, -4.0) * scale, 62.0 * scale, -0.8, 0.8, 24, dark, 7.0 * scale)
			for i in range(5):
				_draw_triangle(center + Vector2(22.0 + float(i) * 14.0, -20.0 + float(i % 2) * 38.0) * scale, 8.0 * scale, PI * 0.5, light)
		elif shape in ["wing", "feather_wing"]:
			draw_colored_polygon(PackedVector2Array([center + Vector2(-78.0, 34.0) * scale, center + Vector2(-20.0, -54.0) * scale, center + Vector2(92.0, -12.0) * scale, center + Vector2(20.0, 46.0) * scale]), color)
			for i in range(5):
				draw_line(center + Vector2(-42.0 + float(i) * 22.0, 28.0) * scale, center + Vector2(-8.0 + float(i) * 20.0, -32.0) * scale, dark, 2.0 * scale)
		elif shape in ["tail_scythe", "dino_tail"]:
			var pts := PackedVector2Array()
			for i in range(18):
				var t := float(i) / 17.0
				pts.append(center + Vector2(lerpf(-94.0, 72.0, t), sin(t * PI) * 34.0) * scale)
			draw_polyline(pts, dark, 12.0 * scale)
			draw_arc(center + Vector2(54.0, -10.0) * scale, 38.0 * scale, -1.9, 0.3, 20, color, 10.0 * scale)
		elif shape == "question_block":
			draw_rect(Rect2(center + Vector2(-54.0, -54.0) * scale, Vector2(108.0, 108.0) * scale), Color(0.54, 0.28, 0.04, 1.0), true)
			draw_rect(Rect2(center + Vector2(-44.0, -44.0) * scale, Vector2(88.0, 88.0) * scale), Color(1.0, 0.74, 0.12, 1.0), true)
			draw_string(ThemeDB.get_fallback_font(), center + Vector2(-18.0, 22.0) * scale, "?", HORIZONTAL_ALIGNMENT_CENTER, 36.0 * scale, int(58.0 * scale), Color(1.0, 0.98, 0.62, 1.0))
			for i in range(4):
				var sx := -36.0 if i < 2 else 36.0
				var sy := -36.0 if i % 2 == 0 else 36.0
				draw_circle(center + Vector2(sx, sy) * scale, 5.0 * scale, Color(1.0, 0.92, 0.38, 1.0))
		elif shape == "speed_lane":
			draw_rect(Rect2(center + Vector2(-88.0, -24.0) * scale, Vector2(176.0, 48.0) * scale), Color(0.22, 0.2, 0.12, 1.0), true)
			for i in range(5):
				var y := -16.0 + float(i) * 8.0
				draw_line(center + Vector2(-78.0, y) * scale, center + Vector2(78.0, y) * scale, Color(1.0, 0.86, 0.18, 1.0), 2.0 * scale)
			for i in range(4):
				var x := -56.0 + float(i) * 34.0
				_draw_triangle(center + Vector2(x, 0.0) * scale, 12.0 * scale, PI * 0.5, Color(0.32, 0.96, 1.0, 0.9))
		elif shape == "one_way_shield":
			draw_rect(Rect2(center + Vector2(-82.0, -34.0) * scale, Vector2(164.0, 68.0) * scale), Color(0.12, 0.26, 0.38, 1.0), true)
			draw_rect(Rect2(center + Vector2(-74.0, -22.0) * scale, Vector2(148.0, 44.0) * scale), Color(0.32, 0.86, 1.0, 0.36), true)
			draw_line(center + Vector2(-76.0, -26.0) * scale, center + Vector2(76.0, -26.0) * scale, Color(0.88, 1.0, 1.0, 1.0), 3.0 * scale)
			draw_line(center + Vector2(-76.0, 26.0) * scale, center + Vector2(76.0, 26.0) * scale, Color(0.88, 1.0, 1.0, 1.0), 3.0 * scale)
			for i in range(4):
				_draw_triangle(center + Vector2(-42.0 + float(i) * 28.0, 0.0) * scale, 13.0 * scale, PI * 0.5, Color(0.96, 1.0, 1.0, 0.9))
		elif shape in ["gravity_plate", "repulsor_field", "heat_field", "coolant_field", "hack_field"]:
			var field_color := Color(0.62, 0.48, 1.0, 1.0)
			if shape == "repulsor_field":
				field_color = Color(1.0, 0.22, 0.62, 1.0)
			elif shape == "heat_field":
				field_color = Color(1.0, 0.32, 0.08, 1.0)
			elif shape == "coolant_field":
				field_color = Color(0.18, 0.92, 1.0, 1.0)
			elif shape == "hack_field":
				field_color = Color(0.34, 1.0, 0.42, 1.0)
			draw_rect(Rect2(center + Vector2(-52.0, -52.0) * scale, Vector2(104.0, 104.0) * scale), dark, true)
			draw_circle(center, 34.0 * scale, field_color.darkened(0.3))
			for i in range(3):
				draw_arc(center, (50.0 + float(i) * 18.0) * scale, 0.0, TAU, 44, Color(field_color.r, field_color.g, field_color.b, 0.24 + float(i) * 0.12), 3.0 * scale)
			for i in range(8):
				var angle := TAU * float(i) / 8.0
				var dir := Vector2(cos(angle), sin(angle))
				var p0 := center + dir * (26.0 if shape != "repulsor_field" else 58.0) * scale
				var p1 := center + dir * (72.0 if shape == "repulsor_field" else 42.0) * scale
				draw_line(p0, p1, field_color.lerp(Color.WHITE, 0.18), 3.0 * scale)
		elif shape == "siphon":
			draw_rect(Rect2(center + Vector2(-62.0, -16.0) * scale, Vector2(78.0, 32.0) * scale), dark, true)
			draw_arc(center + Vector2(34.0, 0.0) * scale, 38.0 * scale, -1.1, 1.1, 24, color, 8.0 * scale)
			draw_circle(center + Vector2(82.0, 0.0) * scale, 9.0 * scale, Color(1.0, 0.9, 0.12, 1.0))
		else:
			draw_rect(Rect2(center + Vector2(-84.0, -22.0) * scale, Vector2(168.0, 44.0) * scale), color, true)
	elif slot_key == "booster":
		draw_rect(Rect2(center + Vector2(-58.0, -34.0) * scale, Vector2(74.0, 68.0) * scale), dark, true)
		_draw_triangle(center + Vector2(44.0, 0.0) * scale, 68.0 * scale, PI * 0.5, Color(1.0, 0.42, 0.16, 0.9))
		draw_line(center + Vector2(-28.0, -24.0) * scale, center + Vector2(12.0, -24.0) * scale, light, 4.0 * scale)
		draw_line(center + Vector2(-28.0, 24.0) * scale, center + Vector2(12.0, 24.0) * scale, light, 4.0 * scale)
	elif slot_key == "engine":
		draw_circle(center, 62.0 * scale, dark)
		draw_circle(center, 36.0 * scale, color)
		draw_arc(center, 76.0 * scale, 0.2, TAU - 0.2, 48, light, 5.0 * scale)
		draw_line(center + Vector2(-82.0, 0.0) * scale, center + Vector2(82.0, 0.0) * scale, light, 3.0 * scale)
	elif slot_key == "cooling":
		for i in range(6):
			draw_rect(Rect2(center + Vector2(-82.0 + float(i) * 28.0, -54.0) * scale, Vector2(14.0, 108.0) * scale), color.lerp(light, float(i) * 0.08), true)
		draw_rect(Rect2(center + Vector2(-84.0, -10.0) * scale, Vector2(172.0, 20.0) * scale), dark, true)
	else:
		draw_rect(Rect2(center + Vector2(-72.0, -50.0) * scale, Vector2(144.0, 100.0) * scale), color, true)
		for i in range(7):
			draw_line(center + Vector2(-88.0, -42.0 + float(i) * 14.0) * scale, center + Vector2(-72.0, -42.0 + float(i) * 14.0) * scale, light, 2.0 * scale)
			draw_line(center + Vector2(72.0, -42.0 + float(i) * 14.0) * scale, center + Vector2(88.0, -42.0 + float(i) * 14.0) * scale, light, 2.0 * scale)
		draw_polyline(PackedVector2Array([center + Vector2(-46.0, 18.0) * scale, center + Vector2(-18.0, -20.0) * scale, center + Vector2(12.0, 12.0) * scale, center + Vector2(48.0, -24.0) * scale]), dark, 5.0 * scale)

func _part_color() -> Color:
	var damage_type := String(part.get("damage_type", part.get("projectile_damage_type", "")))
	if damage_type != "":
		return _damage_color(damage_type)
	var palette := {
		"special": Color(1.0, 0.86, 0.24, 1.0),
		"joint": Color(0.28, 0.88, 1.0, 1.0),
		"muscle": Color(0.92, 0.24, 0.44, 1.0),
		"booster": Color(1.0, 0.44, 0.18, 1.0),
		"engine": Color(0.58, 0.44, 1.0, 1.0),
		"cooling": Color(0.32, 1.0, 0.64, 1.0),
		"module": Color(0.92, 0.94, 0.9, 1.0),
	}
	return palette.get(slot_key, Color(0.8, 0.84, 0.9, 1.0))

func _damage_color(damage_type: String) -> Color:
	match damage_type:
		"bullet":
			return Color(1.0, 0.1, 0.08, 1.0)
		"chemical":
			return Color(1.0, 0.9, 0.12, 1.0)
		"laser":
			return Color(0.2, 0.8, 1.0, 1.0)
		"blunt":
			return Color(0.78, 0.84, 0.9, 1.0)
		"pierce":
			return Color(0.9, 0.3, 1.0, 1.0)
		"tear":
			return Color(0.18, 1.0, 0.62, 1.0)
	return Color(0.8, 0.84, 0.9, 1.0)

func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([center + Vector2(0.0, -radius), center + Vector2(radius, 0.0), center + Vector2(0.0, radius), center + Vector2(-radius, 0.0)]), color)

func _draw_triangle(center: Vector2, radius: float, rotation: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(3):
		var angle := rotation + TAU * float(i) / 3.0
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(pts, color)

func _component_saddle_polygon(center: Vector2, axis: Vector2, length: float, front_width: float, rear_width: float) -> PackedVector2Array:
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var right := Vector2(-forward.y, forward.x)
	var pts := PackedVector2Array()
	for local in PartArt.torso_hull_local_points(part, length, front_width, rear_width):
		var p: Vector2 = local
		pts.append(center + forward * p.x + right * p.y)
	return pts

func _component_saddle_port_positions(center: Vector2, axis: Vector2, port_count: int, length: float, front_width: float, rear_width: float) -> Array:
	var forward := axis.normalized()
	if forward.length() < 0.01:
		forward = Vector2.RIGHT
	var right := Vector2(-forward.y, forward.x)
	var positions: Array = []
	for local in PartArt.torso_hull_port_local_offsets(part, port_count, length, front_width, rear_width):
		var p: Vector2 = local
		positions.append(center + forward * p.x + right * p.y)
	return positions

func _regular_preview_polygon(center: Vector2, radius: float, sides: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(maxi(3, sides)):
		var angle := -PI * 0.5 + TAU * float(i) / float(maxi(3, sides))
		pts.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return pts
