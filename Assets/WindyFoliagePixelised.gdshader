shader_type canvas_item;

uniform bool render_noise = false;
uniform sampler2D noise_texture : repeat_enable; // set in inspector
uniform float amplitude : hint_range(0.0, 0.5, 0.01) = 0.2;
uniform float time_scale : hint_range(0.0, 5.0, 0.01) = 0.04;
uniform float noise_scale : hint_range(0.0, 2.0, 0.0001) = 0.001;
uniform float rotation_strength : hint_range(0.0, 1.0, 0.05) = 1;
uniform vec2 rotation_pivot = vec2(0.5, 1);
uniform float distance_cutoff : hint_range(0.0, 1.0, 0.05) = 0.3;
varying vec2 world_position;

void vertex(){
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

vec2 get_sample_pos(vec2 pos, float scale, float offset) {
	pos *= scale;
	pos += offset;
	return pos;
}

vec2 rotate_vec(vec2 vec, vec2 pivot, float rotation) {
	float cosa = cos(rotation);
	float sina = sin(rotation);
	vec -= pivot;
	return vec2(
		cosa * vec.x - sina * vec.y,
		cosa * vec.y + sina * vec.x
	) + pivot;
}

vec2 get_pixelated_uvs(vec2 uv, vec2 texture_pixel_size) {
    vec2 texture_dimensions = 1.0 / texture_pixel_size;
    vec2 pixel_coords = uv * texture_dimensions;
    vec2 snapped_pixel_coords = vec2(round(pixel_coords.x), round(pixel_coords.y));
    vec2 pixelated_uv = snapped_pixel_coords / texture_dimensions;
	return pixelated_uv;
}

void fragment() {
	vec2 uv = get_pixelated_uvs(UV, TEXTURE_PIXEL_SIZE);
	
	// get noise from texture
	vec2 noise_sample_pos = get_sample_pos(uv, noise_scale, TIME * time_scale);
	float noise_amount = texture(noise_texture, noise_sample_pos).r - 0.5f;

	// get rotation position around a pivot
	float rotation = amplitude * noise_amount;
	vec2 rotated_uvs = rotate_vec(uv, rotation_pivot, rotation);

	// blend original uvs and rotated uvs based on distance to pivot
	float dist = distance(uv, rotation_pivot);
	dist = clamp(dist, distance_cutoff, 1) * rotation_strength - distance_cutoff;
	vec2 result_uvs = mix(uv, rotated_uvs, dist);

	// output color
	COLOR = texture(TEXTURE, result_uvs);

	// optional, preview noise texture for debugging
	if (render_noise) {
		vec4 noise_color = texture(noise_texture, noise_sample_pos);
		COLOR = noise_color;
	}
}