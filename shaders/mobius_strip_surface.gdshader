shader_type canvas_item;

uniform sampler2D surface_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool surface_texture_enabled = false;
uniform float twist_phase = 0.0;
uniform float depth_contrast = 1.0;
uniform float edge_fog = 1.0;
uniform float cosmic_mix = 0.18;
uniform float twist_uv_shear = 0.055;
uniform float twist_uv_warp = 0.035;

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
	vec2 p = vec2(fract(UV.x), tiled_uv.y) * 2.0 - vec2(1.0);
	float ribbon_wave = sin((p.x * 17.0 + p.y * 9.0) + TIME * 0.18 + twist_phase);
	float dust = smoothstep(0.56, 1.0, ribbon_wave * 0.5 + 0.5);
	float core = 1.0 - smoothstep(0.42, 1.25, length(p * vec2(0.82, 1.18)));
	float glow = clamp(core * edge_fog + dust * 0.32, 0.0, 1.0);
	vec3 nebula = vec3(0.18, 0.55, 0.88) * glow + vec3(1.0, 0.62, 0.22) * dust * 0.12;
	vec3 textured = art.rgb * (0.68 + glow * 0.20);
	COLOR.rgb = mix(COLOR.rgb * 0.45 + textured * 0.78, textured + nebula * depth_contrast, cosmic_mix);
	COLOR.a *= art.a * clamp(0.72 + glow * 0.28, 0.0, 1.0);
}
