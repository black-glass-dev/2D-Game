shader_type canvas_item;
render_mode unshaded;

// Mobile-safe ADS glass: only a translucent tint and a soft peripheral vignette.
// The centre alpha remains deliberately low, so this can never recreate the
// opaque black scope card that the old viewmodel optic produced.
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.30;
uniform float edge = 0.014;
uniform float vignette_strength = 0.42;
uniform vec4 glass_tint : source_color = vec4(0.018, 0.045, 0.040, 0.075);

void fragment() {
	vec2 uv = UV;
	vec2 aspect = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
	float d = length((uv - center) * aspect);
	float inside = 1.0 - smoothstep(radius - edge, radius + edge, d);
	float vignette = smoothstep(radius * 0.62, radius * 1.78, d) * vignette_strength;
	float ring = smoothstep(radius + edge, radius, d) * 0.34;
	float alpha = glass_tint.a * inside + vignette * (1.0 - inside) + ring;
	vec3 shade = mix(vec3(0.015, 0.025, 0.028), glass_tint.rgb, inside);
	COLOR = vec4(shade, clamp(alpha, 0.0, 0.55));
}
