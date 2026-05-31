extends SceneTree

const MainScene := preload("res://scripts/main.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _init() -> void:
	var main = MainScene.new()
	root.add_child(main)
	main._ready()
	var target := Node2D.new()
	target.visible = true
	target.position = Vector2(320.0, 240.0)
	root.add_child(target)
	var before: int = main.effects_root.get_child_count() if main.effects_root != null else 0
	main._spawn_hit_effect(target, 0, "blunt", false, "")
	var after: int = main.effects_root.get_child_count() if main.effects_root != null else 0
	if after != before:
		_fail("Tier-0 ordinary hit spawned a visible effect: %d -> %d." % [before, after])
	main._spawn_hit_effect(target, 0, "blunt", false, "impact")
	var styled_after: int = main.effects_root.get_child_count() if main.effects_root != null else 0
	if styled_after <= after:
		_fail("Styled tier-0 VFX should still be available for real contact feedback.")
	var effect = main.effects_root.get_child(styled_after - 1)
	if String(effect.get("label")) == "NONE":
		_fail("Styled tier-0 VFX still exposes player-facing NONE label.")
	print("RUNTIME_NO_PRECONTACT_NONE_PROBE effects=%d label='%s'" % [styled_after, String(effect.get("label"))])
	quit()
