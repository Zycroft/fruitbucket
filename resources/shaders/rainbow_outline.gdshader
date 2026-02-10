shader_type canvas_item;

uniform float line_scale : hint_range(0, 20) = 4.0;
uniform float frequency : hint_range(0.0, 2.0) = 0.8;
uniform float light_offset : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * line_scale;

    float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
    outline = min(outline, 1.0);

    vec4 rainbow = vec4(
        light_offset + sin(2.0 * 3.14159 * frequency * TIME),
        light_offset + sin(2.0 * 3.14159 * frequency * TIME + radians(120.0)),
        light_offset + sin(2.0 * 3.14159 * frequency * TIME + radians(240.0)),
        1.0
    );

    vec4 color = texture(TEXTURE, UV);
    COLOR = mix(color, rainbow, outline - color.a);
}
