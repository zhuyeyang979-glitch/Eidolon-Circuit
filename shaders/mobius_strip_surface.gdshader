shader_type canvas_item;

uniform sampler2D surface_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool surface_texture_enabled = false;
uniform vec2 camera_surface_coord = vec2(0.0);
uniform vec2 surface_view_world_size = vec2(7.2, 5.2);
uniform float loop_length = 24.0;
uniform float grid_cell_world = 0.16;
uniform vec2 grid_texture_cells = vec2(128.0, 16.0);
uniform vec2 ridge_normal = vec2(0.70710678, 0.70710678);
uniform vec2 ridge_pivot_bias = vec2(0.0);
uniform float ridge_period = 1.92;
uniform float ridge_width = 1.0;
uniform float ridge_offset = 0.96;
uniform float ridge_warp_amplitude = 0.125;
uniform float twist_phase = 0.0;
uniform float depth_contrast = 1.0;
uniform float edge_fog = 1.0;
uniform float cosmic_mix = 0.18;
uniform float twist_uv_shear = 0.055;
uniform float twist_uv_warp = 0.035;
uniform float surface_alpha_gain = 1.0;
uniform float surface_alpha_max = 0.18;
uniform float surface_color_gain = 1.0;
uniform float far_brightness = 0.52;
uniform float near_brightness = 0.88;
uniform float grid_far_brightness = 0.52;
uniform float grid_near_brightness = 0.88;

float smooth_unit(float value) {
	float t = clamp(value, 0.0, 1.0);
	return t * t * (3.0 - 2.0 * t);
}

void fragment() {
	vec2 plane = UV * 2.0 - vec2(1.0);
	vec2 normal_axis = normalize(ridge_normal);
	vec2 tangent_axis = vec2(-normal_axis.y, normal_axis.x);
	float safe_period = max(ridge_period, 0.001);
	float ridge_coord = dot(plane + ridge_pivot_bias, normal_axis) + ridge_offset;
	float ridge_distance = abs(fract(ridge_coord / safe_period + 0.5) - 0.5) * safe_period;
	float ridge_distance01 = clamp(ridge_distance / (safe_period * 0.5), 0.0, 1.0);
	float ridge_depth = 1.0 - smooth_unit(clamp(ridge_distance01 / max(ridge_width, 0.001), 0.0, 1.0));
	float depth01 = clamp(0.5 + (ridge_depth - 0.5) * depth_contrast, 0.0, 1.0);

	// Inverse sampling: source grid frequency falls near a ridge and rises in a valley.
	float ridge_wave = sin((PI * 2.0) * ridge_coord / safe_period);
	vec2 sampled_plane = plane - normal_axis * ridge_wave * clamp(ridge_warp_amplitude, 0.0, 0.20);
	float preliminary_s = camera_surface_coord.x + sampled_plane.x * surface_view_world_size.x * 0.5;
	float mobius_twist = PI * preliminary_s / max(loop_length, 0.001);
	float u_shear = sin(mobius_twist + twist_phase) * ridge_wave * twist_uv_shear;
	float v_warp = sin(mobius_twist * 2.0 + twist_phase) * ridge_wave * twist_uv_warp;
	sampled_plane += tangent_axis * u_shear + normal_axis * v_warp;

	vec2 surface_coord = camera_surface_coord + sampled_plane * surface_view_world_size * 0.5;
	vec2 safe_cells = max(grid_texture_cells, vec2(1.0));
	float safe_grid_world = max(grid_cell_world, 0.001);
	vec2 tiled_uv = vec2(
		surface_coord.x / (safe_grid_world * safe_cells.x),
		surface_coord.y / (safe_grid_world * safe_cells.y)
	);
	float twist = PI * surface_coord.x / max(loop_length, 0.001);
	float mirror_weight = 0.5 - 0.5 * cos(twist);
	vec4 art = vec4(0.34, 0.88, 1.0, 0.20);
	if (surface_texture_enabled) {
		vec4 normal_art = texture(surface_texture, tiled_uv);
		vec4 flipped_art = texture(surface_texture, vec2(tiled_uv.x, 1.0 - tiled_uv.y));
		art = mix(normal_art, flipped_art, mirror_weight);
	}
	float brightness = mix(max(grid_far_brightness, 0.0), max(grid_near_brightness, 0.0), depth01);
	float tint_mix = clamp(cosmic_mix, 0.0, 0.32);
	vec3 projection_tint = mix(vec3(0.78, 0.84, 0.94), vec3(0.22, 0.62, 0.92) * 3.0, tint_mix);
	COLOR.rgb = min(art.rgb * projection_tint * brightness * max(surface_color_gain, 0.0), vec3(1.0));
	COLOR.a = min(art.a * max(surface_alpha_gain, 0.0) * brightness, max(surface_alpha_max, 0.0));
}
