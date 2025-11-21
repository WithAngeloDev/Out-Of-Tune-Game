shader_type canvas_item;

uniform float t : hint_range(0.0,1.0) = 0.0; // animation 0→1
uniform float direction = -1.0; // -1 left, 1 right

void fragment() {
    vec2 uv = UV * 2.0 - 1.0; // center coords

    // push effect left/right
    uv.x += t * 0.3 * direction;

    // distance from center
    float d = length(uv);

    // expanding circle with fade
    float circle = smoothstep(t * 0.6, t * 0.6 - 0.2, d);

    // radial spikes like HK
    float angle = atan(uv.y, uv.x);
    float spikes = abs(sin(angle * 6.0)) * (1.0 - t);
    spikes *= smoothstep(0.4, 0.0, d);

    // combine
    float burst = max(circle, spikes);

    COLOR = vec4(vec3(burst), burst);
}
