#version 430 compatibility

in vec2 uv;

/* RENDERTARGETS: 0 */

layout(location = 0) out vec4 color;

#include "/include/buffers.glsl"
#include "/include/uniforms.glsl"
#include "/include/settings.glsl"

#include "/include/color/conversions.glsl"
#include "/include/color/tonemaps/tech.glsl"
#include "/include/color/tonemaps/lottes.glsl"
#include "/include/color/tonemaps/aces.glsl"

void main() {
    color = texture(colortex0, uv);

    // #if BLOOM == 1
        vec3 bloom = texture(BUFFER_BLOOM, uv * 0.5).rgb; // sample from mip 1
        color.rgb = bloom;
        // color.rgb = mix(color.rgb, bloom, BLOOM_STRENGTH);
    // #endif

    color.rgb = tonemap_lottes(color.rgb);
    color.rgb = linear_to_rgb(color.rgb);
}
