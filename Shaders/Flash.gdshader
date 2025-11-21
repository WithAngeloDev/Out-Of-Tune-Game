shader_type canvas_item;

// your custom modulate color
uniform vec4 modulate_color : source_color = vec4(1.0);

// flash amount
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // sample base texture
    vec4 tex = texture(TEXTURE, UV);

    // apply your custom modulate
    vec4 base = tex * modulate_color;

    // flash overlay (white)
    vec3 flash_color = vec3(1.0);

    // mix base and flash
    vec3 final_rgb = mix(base.rgb, flash_color, flash_amount);

    COLOR = vec4(final_rgb, base.a);
}
