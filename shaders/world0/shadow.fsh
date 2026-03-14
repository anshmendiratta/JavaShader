#version 430 compatibility

#include "/include/shadows/distort.glsl"

uniform sampler2D gtexture;

in vec2 uv;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
    color = texture(gtexture, uv) * glcolor;
    if (color.a < 0.1) {
        discard;
    }
}