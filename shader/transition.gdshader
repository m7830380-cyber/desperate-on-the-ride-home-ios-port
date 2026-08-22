shader_type canvas_item;

uniform float progress : hint_range(-0.1, 1.1);
uniform sampler2D mask_texture;
uniform bool flip_h = false;
uniform bool flip_v = false;
uniform bool is_mask = false;

void fragment() {
	vec2 uv = UV;
	
	// Apply flipping for direction control
	if (flip_h) { uv.x = 1.0 - uv.x; }
	if (flip_v) { uv.y = 1.0 - uv.y; }
	
	float mask_value = texture(mask_texture, uv).r;
	float alpha;
	
	if (is_mask) {
		// Disney-style sharp edge: Closes from edges (1.0) to center (0.0)
		// progress 0.0 -> Clear, progress 1.1 -> Black
		alpha = step(1.0 - progress, mask_value);
	} else {
		// Smooth wipe: progress 0.0 -> Clear, progress 1.1 -> Black
		alpha = smoothstep(1.0 - progress, 1.1 - progress, mask_value);
	}
	
	COLOR.rgb = vec3(0.0, 0.0, 0.0);
	COLOR.a = alpha;
}