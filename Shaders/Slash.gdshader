shader_type canvas_item;

uniform float thickness : hint_range(0.0, 0.5) = 0.12;   // slash width
uniform float softness : hint_range(0.0, 0.5) = 0.15;    // how soft edges are
uniform float arc_angle : hint_range(0.0, 6.283) = 1.8;  // curve angle in radians
uniform float fade : hint_range(0.0, 2.0) = 0.0;         // fade-out over time

void fragment() {
    // normalized UV center at 0.5 → convert to local coords (-1..1)
    vec2 p = (UV - vec2(0.5)) * 2.0;

    float r = length(p);        // distance from center
    float a = atan(p.y, p.x);   // angle

    // normalize angle to [-PI, PI]
    // then clamp to arc range
    float half_arc = arc_angle * 0.5;

    // check if the angle is inside the slash arc
    float angle_mask = smoothstep(-half_arc, -half_arc + softness, a) *
                       (1.0 - smoothstep(half_arc - softness, half_arc, a));

    // slash is basically a curved band at radius r ~ 0.6
    float slash_radius = 0.6;

    // how close we are to the slash band
    float radial = 1.0 - smoothstep(thickness, thickness + softness, abs(r - slash_radius));

    float intensity = angle_mask * radial;

    // fade over time (you animate "fade" externally)
    intensity *= max(0.0, 1.0 - fade);

    COLOR = vec4(vec3(intensity * 2.0), intensity);
}
