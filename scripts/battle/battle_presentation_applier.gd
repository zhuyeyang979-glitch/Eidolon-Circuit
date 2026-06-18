extends RefCounted
class_name BattlePresentationApplier


func apply_render_frame(host, plan: Dictionary) -> void:
	if host == null:
		return
	host.begin_presentation_frame(
		bool(plan.get("presentation_active", true)),
		float(plan.get("presentation_alpha", 1.0))
	)
	var frame_delta := float(plan.get("frame_delta", 0.0))
	var interpolation_alpha := float(plan.get("interpolation_alpha", plan.get("presentation_alpha", 1.0)))
	if bool(plan.get("refresh_mobius_surface", true)):
		host.refresh_mobius_surface()
	if bool(plan.get("update_parallax_background", true)):
		host.update_parallax_background()
	if bool(plan.get("refresh_unit_screen_positions", true)):
		host.refresh_unit_screen_positions(interpolation_alpha, frame_delta)
	if bool(plan.get("update_aim_lines", true)):
		host.update_aim_lines(frame_delta)
	if bool(plan.get("update_combat_geometry_debug_overlay", true)):
		host.update_combat_geometry_debug_overlay()
	if bool(plan.get("update_battle_action_diagnostics_overlay", false)):
		host.update_battle_action_diagnostics_overlay()
	if bool(plan.get("update_battle_ui", true)):
		host.update_battle_ui()
	host.finish_presentation_frame(bool(plan.get("presentation_active_after", false)))
