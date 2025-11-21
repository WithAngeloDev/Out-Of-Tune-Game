shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform float blur_size : hint_range(0.0, 20.0) = 1.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 resolution = SCREEN_PIXEL_SIZE;

    vec3 col = vec3(0.0);

    // 5 sample blur (cheap)
    col += texture(SCREEN_TEXTURE, uv + vec2(-blur_size, -blur_size) * resolution).rgb;
    col += texture(SCREEN_TEXTURE, uv + vec2( blur_size, -blur_size) * resolution).rgb;
    col += texture(SCREEN_TEXTURE, uv + vec2(-blur_size,  blur_size) * resolution).rgb;
    col += texture(SCREEN_TEXTURE, uv + vec2( blur_size,  blur_size) * resolution).rgb;
    col += texture(SCREEN_TEXTURE, uv).rgb;

    col /= 5.0;

    COLOR = vec4(col, 1.0);
}
