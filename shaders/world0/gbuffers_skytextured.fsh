#version 330 compatibility

uniform sampler2D gtexture;
uniform vec2 mc_midTexCoord;

in vec4 glcolor;
in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    color = texture(gtexture, uv);
}