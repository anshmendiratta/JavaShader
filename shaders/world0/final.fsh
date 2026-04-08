#version 430 compatibility

in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/include/buffers.glsl"

#include "/include/uniforms.glsl"

#include "/include/color/conversions.glsl"
#include "/include/color/tonemaps/aces.glsl"
#include "/include/color/tonemaps/lottes.glsl"

void main() {
    color = texture(colortex0, uv);
    color.rgb = tonemap_lottes(color.rgb);

    color.rgb = linear_to_rgb(color.rgb);
}
