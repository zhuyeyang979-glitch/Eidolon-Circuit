shader_type canvas_item;

uniform sampler2D surface_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool surface_texture_enabled = false;
uniform float twist_phase = 0.0;
uniform float depth_contrast = 1.0;
uniform float edge_fog = 1.0;
uniform float cosmic_mix = 0.18;
uniform float twist_uv_shear = 0.055;
uniform float twist_uv_warp = 0.035;
uniform float surface_alpha_gain = 1.0;
uniform float surface_alpha_max = 0.18;
uniform float surface_color_gain = 1.0;

void fragment() {
	float twist = 3.14159265359 * UV.x;
	float mirror_weight = 0.5 - 0.5 * cos(twist);
	float twist_sine = sin(twist);
	float centered_v = clamp(UV.y, 0.0, 1.0) - 0.5;
	float u_shear = centered_v * twist_sine * twist_uv_shear;
	float v_warp = sin((fract(UV.x) - 0.5) * 6.28318530718 + twist_phase) * twist_sine * twist_uv_warp;
	vec2 tiled_uv = vec2(UV.x + u_shear, clamp(UV.y + v_warp, 0.0, 1.0));
	vec4 art = vec4(COLOR.rgb, 1.0);
	if (surface_texture_enabled) {
		vec4 normal_art = texture(surface_texture, tiled_uv);
		vec4 flipped_art = texture(surface_texture, vec2(tiled_uv.x, 1.0 - tiled_uv.y));
		art = mix(normal_art, flipped_art, mirror_weight);
	}
	float tint_mix = clamp(cosmic_mix, 0.0, 0.32);
	float projection_gain = clamp(0.86 + depth_contrast * 0.10, 0.72, 1.08);
	vec3 projection_tint = mix(vec3(0.78, 0.84, 0.94), COLOR.rgb * 3.0, tint_mix);
	COLOR.rgb = min(art.rgb * projection_tint * projection_gain * max(surface_color_gain, 0.0), vec3(1.0));
	COLOR.a = min(clamp(COLOR.a, 0.0, 1.0) * art.a * max(surface_alpha_gain, 0.0), max(surface_alpha_max, 0.0));
}
