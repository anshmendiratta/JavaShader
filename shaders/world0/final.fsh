#version 430 compatibility

in vec2 uv;

/* RENDERTARGETS: 0 */

layout(location = 0) out vec4 color;

#include "/include/buffers.glsl"
#include "/include/uniforms.glsl"
#include "/include/settings.glsl"
#include "/include/debug_text.glsl"

#include "/include/math/convenience.glsl"

#include "/include/color/grading.glsl"
#include "/include/color/conversions.glsl"
#include "/include/color/tonemaps/aces.glsl"
#include "/include/color/tonemaps/lottes.glsl"
#include "/include/color/tonemaps/agx.glsl"

void main() {
    color = texture(colortex0, uv);
    // color.rgb = rgb_to_linear(color.rgb);

    #if BLOOM == 1
        vec3 bloom = texture(BUFFER_BLOOM, uv).rgb; // sample from mip 1
        color.rgb = oklab_mix(color.rgb, bloom, BLOOM_STRENGTH);
    #endif

    // ----------------
    //     Purkinje
    // ----------------

    #if PURKINJE_SHIFT == 1
        apply_purkinje(color.rgb, rgb_to_luminance(color.rgb));
    #endif

    // -----------
    //     LUT
    // -----------
    // FIX: white splotches from when `lut_uv` exceeds 1.

    float blue_tile = min(63. / 64., floor(color.b * 64.) / 64.);
    vec2 blue_tile_extent = vec2(1. / 64., 1.);

    vec2 blue_tile_uv = color.rg;
    vec2 lut_uv = (vec2(blue_tile, 0.) + blue_tile_uv * blue_tile_extent);

    // color.rgb = texture(colortex29, lut_uv).rgb;

    // -------------------
    //     Tonemapping
    // -------------------

    #if TONEMAP == 0
        color.rgb = tonemap_agx(color.rgb);
    #elif TONEMAP == 1
        color.rgb = tonemap_lottes(color.rgb);
    #endif

    color.rgb = linear_to_rgb(color.rgb);
}
