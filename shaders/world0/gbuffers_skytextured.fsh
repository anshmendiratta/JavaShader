#version 330 compatibility

in vec4 glcolor;
in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/include/uniforms.glsl"

void main() {
    color = texture(gtexture, uv);
}
