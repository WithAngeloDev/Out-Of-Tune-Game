shader_type canvas_item;

#define iResolution 1.0/SCREEN_PIXEL_SIZE
#define iTime TIME
#define fragColor COLOR

uniform vec4 bg_color: source_color;
uniform float uv_scale : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float percentage: hint_range(0.0, 1.0) = 1.0;
uniform float speed = 1.0;

uniform float wave_1_speed = -1.0;
uniform float wave_2_speed = 1.0;

uniform float wave_1_freq = 1.2;
uniform float wave_2_freq = 1.0;

uniform float wave_1_amp = 0.015;
uniform float wave_2_amp = 0.01;

uniform vec3 sun_dir = vec3(-0.2, 0.4, 1.0);
uniform vec4 water_colour : source_color = vec4(0.2, 0.4, 0.6, 1.0);
uniform vec4 foam_colour : source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform vec4 sky_colour : source_color = vec4(0.2, 0.6, 0.8, 1.0);
uniform vec4 specular_colour : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform sampler2D notes_texture;
uniform float notes_count : hint_range(1.0, 300.0) = 40.0;
uniform float notes_scale : hint_range(0.1, 3.0) = 1.0;
uniform float notes_speed = 0.4;

vec2 hash(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453123);
}

////////////////////////////////////////////////////
// CLEAN FLOWING NOTES
////////////////////////////////////////////////////
vec4 flowing_notes(vec2 uv, float t){
	vec4 total = vec4(0.0);

	for (int i = 0; i < 80; i++){
		if (float(i) >= notes_count) break;

		vec2 seed = vec2(float(i), float(i) * 3.17);

		vec2 base_pos = hash(seed);

		vec2 drift;
		drift.x = sin(t * 0.4 + seed.x * 10.0) * 0.05;
		drift.y = cos(t * 0.6 + seed.y * 12.0) * 0.05;

		vec2 final_pos = base_pos + drift;

		vec2 tex_uv = (uv - final_pos) / (0.15 * notes_scale) + 0.5;

		vec4 note = texture(notes_texture, tex_uv);

		total = mix(total, note, note.a);
	}

	return total;
}

////////////////////////////////////////////////////
// WAVES + WATER (unchanged)
////////////////////////////////////////////////////
float noise(in vec2 p){
	const float K1 = 0.366025404;
	const float K2 = 0.211324865;

	vec2 i = floor(p + (p.x + p.y) * K1);
	vec2 a = p - i + (i.x + i.y) * K2;
	float m = step(a.y, a.x);
	vec2 o = vec2(m, 1.0 - m);
	vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0 * K2;
	vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
	vec3 n = h*h*h*h * vec3(dot(a, hash(i + 0.0)), dot(b, hash(i + o)), dot(c, hash(i + 1.0)));
	return dot(n, vec3(70.0));
}

#define MAX_WAVES 4
#define SUPERPOSITION 4
#define TAU 6.28318
#define PHI 1.618

float height(vec2 p, float t){
	float acc = 0.0;
	for(int i = 0; i < MAX_WAVES; i++){
		for(int j = 0; j < SUPERPOSITION; j++){
			int seed = i + 5*j;
			float theta = TAU * PHI * 10.0 * float(seed);
			float up = cos(theta) * p.x - sin(theta) * p.y;
			float vp = sin(theta) * p.x + cos(theta) * p.y;
			float initial_phase = TAU * PHI * float(seed);
			float k = pow(2.0, float(i));
			float phase = initial_phase + up * k + cos(vp) + 3.0 * t + 0.5 * k * t;
			float A = cos(phase) / (k * k);
			acc += A;
		}
	}
	return acc;
}

vec4 hn_fdm(vec2 p, float t){
	float h = height(p, t);
	vec2 vx = vec2(0.1, 0.0);
	vec2 vy = vec2(0.0, 0.1);
	float hx = height(p + vx, t);
	float hy = height(p + vy, t);
	float dx = (hx - h);
	float dy = (hy - h);

	vec3 v1 = normalize(vec3(vx.x, 0.0, dx));
	vec3 v2 = normalize(vec3(0.0, vy.y, dy));
	vec3 norm = cross(v1, v2);

	return vec4(norm, h);
}

vec4 wave(vec2 uv, vec4 c, float lvl, float freq, float amp, float shift, float spd){
	float sinus = sin((uv.x + shift + TIME * spd) * freq) * amp;
	float shifted = (1.0 + 2.0 * amp) * lvl - amp;
	float t = step(1.0 - sinus - shifted, uv.y);
	return c * t;
}

////////////////////////////////////////////////////
// MAIN
////////////////////////////////////////////////////
void fragment(){
	vec2 uv = UV;
	vec2 uv_screen = (uv - 0.5) * uv_scale;

	vec4 nh = hn_fdm(uv_screen * 10.0, iTime * speed);
	vec3 norm = nh.xyz;

	if(dot(sun_dir, norm) > 0.98){
		fragColor = specular_colour;
	} else {
		fragColor = mix(water_colour, sky_colour, dot(norm, normalize(vec3(0.0, 0.2, 1.0))));
	}

	vec2 uv2 = vec2(uv.y, 1.0 - uv.x);
	vec4 shadowWave = fragColor * 0.6;
	shadowWave.a = 1.0;

	vec4 w1 = wave(uv2, shadowWave, percentage, wave_1_freq, wave_1_amp, 0.0, wave_1_speed);
	vec4 w2 = wave(uv2, fragColor, percentage, wave_2_freq, wave_2_amp, 0.7785*TIME, wave_2_speed);
	vec4 waves = mix(w1, w2, w2.a);

	vec4 base_color = mix(bg_color, waves, waves.a);

	vec4 notes = flowing_notes(uv, iTime * notes_speed);

	COLOR = base_color + notes;
}
