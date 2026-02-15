#version 330 compatibility

uniform sampler2D colortex0;

in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/lib/buffers.glsl"
#include "/common/color_math.glsl"
#include "/programs/tonemapping.glsl"

void main() {
    color = texture(colortex0, uv);
    color.rgb = agx(color.rgb);
    color.rgb = saturate_rgb(color.rgb, 1.3);
    color.rgb = pow(color.rgb, vec3(1.0 / 2.2)); // redo gamma correction to get back to sRGB.
}
