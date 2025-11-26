shader_type canvas_item;

// Godot 4.5: you must manually declare this
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

// Size of the square (0 to 1)
uniform float square_size : hint_range(0.0, 1.0) = 0.6;

// Thickness of the outer outline
uniform float outline_size : hint_range(0.0, 0.5) = 0.08;

// Color inside the square
uniform vec4 inside_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Colors for the gradient outline
uniform vec4 outline_color_inner : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 outline_color_outer : source_color = vec4(1.0, 1.0, 0.0, 1.0);

void fragment() {
    vec2 uv = UV;

    float half = square_size * 0.5;
    vec2 center = vec2(0.5);
    vec2 d = abs(uv - center);

    bool inside_square = (d.x <= half && d.y <= half);

    float edge_dist = max(d.x - half, d.y - half);
    float outline_mask = smoothstep(0.0, outline_size, outline_size - edge_dist);

    float t = clamp(edge_dist / outline_size, 0.0, 1.0);
    vec4 grad_col = mix(outline_color_inner, outline_color_outer, t);

    if (inside_square) {
        COLOR = inside_color;
    } else if (outline_mask > 0.0) {
        COLOR = grad_col * outline_mask;
    } else {
        COLOR = vec4(0.0);
    }
}
