#if !defined INCLUDE_SHADOWS_COMPUTE
#define INCLUDE_SHADOWS_COMPUTE

#include "/include/pipeline.glsl"
#include "/include/settings.glsl"

#include "/include/math/convenience.glsl"

#include "/include/utility/dither.glsl"
#include "/include/utility/vogel_disk_blur.glsl"
#include "/include/utility/depth_conversion.glsl"

#include "/include/shadows/distort.glsl"

// --------------------------
//     Shadow computation
// --------------------------

vec3 _get_shadow(in vec3 shadow_screen_position);
bool _frag_is_shadowed(in vec3 shadow_screen_position);
vec3 _get_soft_shadow(in vec4 shadow_clip_position, in vec3 normal_world, in float lightmap_sky);

#define SHADOW_BLUR_SAMPLE_COUNT SHADOW_RANGE * SHADOW_RANGE

vec3 _get_soft_shadow(in vec4 shadow_clip_position, vec3 normal_world, float lightmap_sky) {
    float dither = compute_dither(gl_FragCoord.xy);
    float rotation_angle = dither * TAU;
    mat2 rotation_matrix = mat2(cos(rotation_angle), -sin(rotation_angle), sin(rotation_angle), cos(rotation_angle));

    vec3 frag_world_position = (shadowModelViewInverse * vec4((shadowProjectionInverse * shadow_clip_position).xyz, 1.0)).xyz + cameraPosition;

    // TODO: actual pcss
    vec3 pcf_accumulator = vec3(0.0);

    for (uint idx = 0; idx < SHADOW_BLUR_SAMPLE_COUNT; idx += 1) {
        vec2 vogel_sample = compute_vogel_disk_sample_uv(idx, SHADOW_BLUR_SAMPLE_COUNT) / shadowMapResolution;
        vec2 rotated_sample = rotation_matrix * vogel_sample;
        vec2 sample_uv_offset = rotated_sample;

        _escheridia_normal_offset_shadow_bias(shadow_clip_position, normal_world);

        vec4 sample_uv = shadow_clip_position + vec4(sample_uv_offset, 0.0, 0.0);
        distort_shadow_clip_position(sample_uv.xyz);
        vec3 sample_uv_shadow_screen = shadow_clip_to_shadow_screen(sample_uv);

        pcf_accumulator += _get_shadow(sample_uv_shadow_screen);
    }

    return pcf_accumulator / float(SHADOW_BLUR_SAMPLE_COUNT);
}

// ---------------------
//     Shadow biases
// ---------------------

// comments are not my own

bool _frag_is_shadowed(vec3 shadow_screen_position) {
    return shadow_screen_position.z < texture(shadowtex0, shadow_screen_position.xy).r;
}

vec3 _get_shadow(vec3 shadow_screen_position) {
    float is_visible = float(_frag_is_shadowed(shadow_screen_position));
    if (is_visible == 1.0) return vec3(1.0); // Return full sunlight to use for light calculation.

    float is_opaque_shadowed = step(shadow_screen_position.z, texture(shadowtex1, shadow_screen_position.xy).r);
    // TODO: this might need to take into account hcm/metals that have wavelength-dependent f0s so that the shadowed area isnt grayscale and appears to have some kind of "GI" because of specular bounces. might be solved with rsm
    if (is_opaque_shadowed == 0.0) return vec3(0.0);

    // shadowed but by transparent objects. tint shadow
    vec4 shadow_color = texture(shadowcolor0, shadow_screen_position.xy);
    float light_passthrough_proportion = 1 - shadow_color.a;

    return shadow_color.rgb * light_passthrough_proportion;
}

#endif
