#if !defined INCLUDE_SHADOWS_DISTORT
#define INCLUDE_SHADOWS_DISTORT

#include "/include/settings.glsl"
#include "/include/pipeline.glsl"

#include "/include/math/convenience.glsl"

// -------------------------
//     Shadow distortion
// -------------------------

void _multiply_shadow_distance(inout vec3 shadow_clip_position);
float _get_distortion_factor(vec2 position_shadow_clip);
float _quartic_length(vec2 v);

// from photon by sixthsurge.
// - https://github.com/sixthsurge/photon

void distort_shadow_clip_position(inout vec3 undistorted_position) {
    _multiply_shadow_distance(undistorted_position);
    float distortion_factor = _get_distortion_factor(undistorted_position.xy);
    undistorted_position *= vec3(vec2(1. / distortion_factor), 1.);
}

void undistort_shadow_clip_position(inout vec3 distorted_position) {
    distorted_position.xy *= (1. - SHADOW_DISTORTION) / (1. - _quartic_length(distorted_position.xy));
    distorted_position.z *= 1. / SHADOW_DISTANCE_MULTIPLIER;
}

void _multiply_shadow_distance(inout vec3 shadow_clip_position) {
    shadow_clip_position.z /= SHADOW_DISTANCE_MULTIPLIER;
}

float _quartic_length(vec2 v) {
    return sqrt(sqrt(pow4(v.x) + pow4(v.y)));
}

float _get_distortion_factor(vec2 position_shadow_clip) {
    return _quartic_length(position_shadow_clip.xy) * SHADOW_DISTORTION + (1. - SHADOW_DISTORTION);
}

// -----------------
//    Shadow bias
// -----------------

// bias taken from bliss: https://github.com/X0nk/Bliss-Shader/blob/81e403ed308141039a09d792a36f8eb328898a60/shaders/lib/Shadows.glsl#L2, which was in turn taken from comp. reimagined and rethinking voxels
void _xonk_gri_emin_shadow_fix(inout vec3 frag_world_position, in vec3 frag_world_normal, in float lightmap_sky);
void _escheridia_normal_offset_shadow_bias(inout vec4 frag_position_shadow_ndc, vec3 frag_world_normal);

// from complementary reimagined by Emin
// - https://github.com/ComplementaryDevelopment/ComplementaryReimagined
vec3 compute_shadow_bias(vec3 position, vec3 normal, float n_dot_l, float skylight) {
    return 0.25 * normal * clamp01(0.12 * 0.01 * length(position)) * (2. - clamp01(n_dot_l));
}

void _xonk_gri_emin_shadow_fix(inout vec3 frag_world_position, in vec3 frag_world_normal, in float lightmap_sky) {
    float minimum_value = 0.05;
    // give a tiny boost to the distance mulitplier when shadowmap resolution is below 2048.0
    float shadow_map_res_multiplier = 1.0 + (shadowDistance / 8.0) * (1.0 - min(shadowMapResolution, 2048) / 2048.0) * 0.3;
    float distance_multiplier = max(1.0 - max(1.0 - length(frag_world_position) / shadowDistance, 0.0), minimum_value) * shadow_map_res_multiplier;

    vec3 bias = frag_world_normal * distance_multiplier;

    vec2 scale = vec2(0.5, 0.25); // stop lightleaking by zooming up, centered on blocks
    vec3 zoom_shadow = scale.y - scale.x * fract(frag_world_position + cameraPosition + bias * scale.y);
    if (lightmap_sky < 0.1) bias = zoom_shadow;

    frag_world_position += bias;
}

void _escheridia_normal_offset_shadow_bias(inout vec4 frag_position_shadow_ndc, vec3 frag_world_normal) {
    float bias_adjust = log2(max(4.0, shadowDistance - shadowMapResolution * 0.125)) * 0.5;
    float factor = pow3(length(frag_position_shadow_ndc)) * 0.2;

    frag_position_shadow_ndc.xyz += mat3(shadowProjection) * (mat3(shadowModelView) * frag_world_normal) * factor * bias_adjust;
}

#endif
