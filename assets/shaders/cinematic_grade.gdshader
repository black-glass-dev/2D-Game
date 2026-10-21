// Original mobile-friendly post presentation pass. It is deliberately a single
// CanvasItem sample sequence: the Environment keeps bloom/tonemapping while this
// pass handles the inexpensive teal-shadow / amber-highlight grade, vignette,
// micro grain and restrained chromatic separation for the desert mood.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D scene_color : hint_screen_texture, filter_linear_mipmap;
uniform float grade_strength : hint_range(0.0, 1.0) = 0.72;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.24;
uniform float grain_strength : hint_range(0.0, 0.12) = 0.022;
uniform float chromatic_strength : hint_range(0.0, 1.0) = 0.22;
uniform float exposure_lift : hint_range(-0.25, 0.25) = 0.015;

float hash12(vec2 p) {
	p = fract(p * vec2(443.8975, 441.423));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

vec3 filmic_curve(vec3 color) {
	// A compact ACES-inspired shoulder that behaves well on Compatibility.
	const float a = 2.51;
	const float b = 0.03;
	const float c = 2.43;
	const float d = 0.59;
	const float e = 0.14;
	return clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center_delta = uv - vec2(0.5);
	float radius_sq = dot(center_delta, center_delta);
	// One scene sample is intentional. A three-tap RGB split cost more than the
	// entire rest of this pass on low-end phones; the slight edge tint below is
	// the tier-aware Compatibility fallback for chromatic separation.
	vec3 scene = texture(scene_color, uv).rgb;
	float edge_tint = smoothstep(0.12, 0.50, radius_sq) * chromatic_strength;
	scene.r *= 1.0 + edge_tint * 0.025;
	scene.b *= 1.0 - edge_tint * 0.018;

	float luminance = dot(scene, vec3(0.2126, 0.7152, 0.0722));
	float shadow_mask = 1.0 - smoothstep(0.08, 0.48, luminance);
	float highlight_mask = smoothstep(0.48, 1.12, luminance);
	vec3 teal_shadows = mix(scene, scene * vec3(0.76, 1.045, 1.10) + vec3(0.0, 0.018, 0.026), shadow_mask * grade_strength);
	vec3 graded = mix(teal_shadows, teal_shadows * vec3(1.075, 0.985, 0.89) + vec3(0.018, 0.003, 0.0), highlight_mask * grade_strength);
	graded = filmic_curve(max(graded + exposure_lift, vec3(0.0)));

	float vignette = smoothstep(0.18, 0.78, radius_sq * 1.95);
	graded *= 1.0 - vignette * vignette_strength;
	float grain = (hash12(floor(uv * vec2(960.0, 540.0))) - 0.5) * grain_strength;
	graded += grain;
	COLOR = vec4(clamp(graded, 0.0, 1.0), 1.0);
}
