shader_type canvas_item;

uniform bool render_noise = false;
uniform sampler2D noise_texture : repeat_enable; // set in inspector
uniform float amplitude : hint_range(0.0, 0.5, 0.01) = 0.2;
uniform float time_scale : hint_range(0.0, 5.0, 0.01) = 0.04;
uniform float noise_scale :hint_range(0.0, 2.0, 0.0001) = 0.001;
uniform float rotation_strength : hint_range(0.0, 5.0, 0.1) = 1;
uniform vec2 rotation_pivot = vec2(0.5, 1);
varying vec2 world_position;

void vertex(){
    world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

vec2 get_uv(vec2 uv, float scale, float time) {
	vec2 new_uv = uv;
	new_uv *= scale;
	new_uv += time;
	return new_uv;
}

vec2 rotateUV(vec2 uv, vec2 pivot, float rotation) {
	float cosa = cos(rotation);
	float sina = sin(rotation);
	uv -= pivot;
	return vec2(
		cosa * uv.x - sina * uv.y,
		cosa * uv.y + sina * uv.x
	) + pivot;
}

void fragment() {
	vec2 world_uv = get_uv(world_position, noise_scale, TIME * time_scale);
	float noise_color = texture(noise_texture, world_uv).r - 0.5f;

	float rotation = amplitude * noise_color;
	vec2 rotatedUVs = rotateUV(UV, rotation_pivot, rotation);

	float dist = distance(UV, rotation_pivot) * rotation_strength;
	vec2 uvs = mix(UV, rotatedUVs, dist);
	vec4 sample = texture(TEXTURE, uvs);
	COLOR = sample;

	if (render_noise) {
		vec3 color = sample.rgb;
		vec2 world_uv = get_uv(world_position, noise_scale, TIME * time_scale);
		color = texture(noise_texture, world_uv).rgb;
		COLOR = vec4(color, 1.0);
	}
}