shader_type canvas_item;

uniform float clip_y : hint_range(0.0,1.0) = 0.5; // fraction from top

void fragment() {
    vec2 frame_uv = UV;
    
    // flip UV if you want top half kept
    if (frame_uv.y < clip_y) {
        COLOR = vec4(0.0); // fully transparent bottom
    } else {
        vec4 tex = texture(TEXTURE, UV);
        COLOR = vec4(tex.rgb, tex.a); // keep top half visible
    }
}
