#version 330 compatibility

uniform sampler2D colortex0;

in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    color = texture(colortex0, uv);
    color.rgb = pow(color.rgb, vec3(1.0 / 2.2)); // Redo gamma correction since the monitor expects the color to be in sRGB color space.
}