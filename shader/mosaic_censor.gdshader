shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float pixel_size : hint_range(4.0, 64.0) = 16.0;
uniform float mask_threshold : hint_range(0.0, 1.0) = 0.5;
// Edge dilation radius in reference-resolution (2160p) pixels.
// Expands the white mask outward before applying mosaic.
uniform float expand_pixels : hint_range(0.0, 20.0) = 2.0;

const float REF_HEIGHT = 2160.0;

void fragment() {
	vec2 screen_res = 1.0 / SCREEN_PIXEL_SIZE;
	float res_scale = screen_res.y / REF_HEIGHT;

	// Mosaic grid: snap screen UV to cell center
	float scaled_pixel = pixel_size * res_scale;
	vec2 cell_count = screen_res / scaled_pixel;
	vec2 snapped_screen_uv = (floor(SCREEN_UV * cell_count) + 0.5) / cell_count;

	// Convert expand_pixels (ref-res) → mask UV offset
	vec2 uv_per_screen = vec2(
		dFdx(UV).x / dFdx(SCREEN_UV).x,
		dFdy(UV).y / dFdy(SCREEN_UV).y
	);
	vec2 expand_uv = SCREEN_PIXEL_SIZE * (expand_pixels * res_scale) * uv_per_screen;

	// 5-tap cross dilation on original (non-snapped) mask UV.
	// Fragment is censored if ANY tap lands on a white pixel.
	vec4 m0 = texture(TEXTURE, UV);
	vec4 m1 = texture(TEXTURE, UV + vec2(expand_uv.x, 0.0));
	vec4 m2 = texture(TEXTURE, UV - vec2(expand_uv.x, 0.0));
	vec4 m3 = texture(TEXTURE, UV + vec2(0.0, expand_uv.y));
	vec4 m4 = texture(TEXTURE, UV - vec2(0.0, expand_uv.y));

	bool censored =
		(m0.r >= mask_threshold && m0.a >= mask_threshold) ||
		(m1.r >= mask_threshold && m1.a >= mask_threshold) ||
		(m2.r >= mask_threshold && m2.a >= mask_threshold) ||
		(m3.r >= mask_threshold && m3.a >= mask_threshold) ||
		(m4.r >= mask_threshold && m4.a >= mask_threshold);

	if (censored) {
		COLOR = texture(screen_texture, snapped_screen_uv);
	} else {
		COLOR = vec4(0.0);
	}
}

