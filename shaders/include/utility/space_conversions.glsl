#if !defined INCLUDE_CONVERSIONS
#define INCLUDE_CONVERSIONS

#include "/include/uniforms.glsl"

#include "/include/utility/random.glsl"

#include "/include/shadows/distort.glsl"

vec4 view_to_clip(vec3 view_position);

// ---------------------------------------------------------------
//     Coordinate conversions from screen space to world space
// ---------------------------------------------------------------

vec3 screen_to_ndc(vec3 screen_position) {
    return screen_position * 2.0 - 1.0;
}

vec3 ndc_to_view(vec3 ndc_position) {
    return _project_and_divide(gbufferProjectionInverse, ndc_position);
}

vec3 clip_to_view(vec4 clip_position) {
    return (gbufferProjectionInverse * clip_position).xyz;
}

vec3 view_to_feet(vec3 view_position) {
    return (gbufferModelViewInverse * vec4(view_position, 1.0)).xyz;
}

vec3 feet_to_world(vec3 feet_position) {
    return feet_position + cameraPosition;
}

vec3 view_to_world(vec3 view_position) {
    return feet_to_world(view_to_feet(view_position));
}

vec3 screen_to_view(vec3 screen_position) {
    return ndc_to_view(screen_to_ndc(screen_position));
}

vec4 screen_to_clip(vec3 screen_position) {
    return view_to_clip(ndc_to_view(screen_to_ndc(screen_position)));
}

// ---------------------------------------------------------------
//     Coordinate conversions from world space to screen space
// ---------------------------------------------------------------

vec3 world_to_feet(vec3 world_position) {
    return world_position - cameraPosition;
}

vec3 feet_to_view(vec3 feet_position) {
    return (gbufferModelView * vec4(feet_position, 1.0)).xyz;
}

vec4 view_to_clip(vec3 view_position) {
    return gbufferProjection * vec4(view_position, 1.0);
}

vec3 view_to_ndc(vec3 view_position) {
    return _project_and_divide(gbufferProjection, view_position);
}

vec3 ndc_to_screen(vec3 ndc_position) {
    return ndc_position * 0.5 + 0.5;
}

vec3 view_to_screen(vec3 view_position) {
    return ndc_to_screen(view_to_ndc(view_position));
}

vec3 world_to_view(vec3 world_position) {
    return feet_to_view(world_to_feet(world_position));
}

vec3 clip_to_ndc(vec4 clip_position) {
    return clip_position.xyz / clip_position.w;
}

vec3 clip_to_screen(vec4 clip_position) {
    return ndc_to_screen(clip_to_ndc(clip_position));
}

// --------------------------------------------------------------
//     Coordinate conversions from feet space to shadow space
// --------------------------------------------------------------

vec3 feet_to_shadow_view(vec3 feet_position) {
    return (shadowModelView * vec4(feet_position, 1.0)).xyz;
}

vec4 shadow_view_to_shadow_clip(vec3 shadow_view_position) {
    return shadowProjection * vec4(shadow_view_position, 1.0);
}

vec4 feet_to_shadow_clip(vec3 feet_position) {
    return shadow_view_to_shadow_clip(feet_to_shadow_view(feet_position));
}

vec3 shadow_view_to_shadow_ndc(vec3 shadow_view_position) {
    return _project_and_divide(shadowProjection, shadow_view_position);
}

vec3 shadow_clip_to_shadow_ndc(vec4 shadow_clip_position) {
    return shadow_clip_position.xyz / shadow_clip_position.w;
}

vec3 shadow_clip_to_shadow_screen(vec4 shadow_clip_position) {
    return shadow_clip_to_shadow_ndc(shadow_clip_position) * 0.5 + 0.5;
}

// --------------------------------------------------------------
//     Coordinate conversions from shadow space to feet space
// --------------------------------------------------------------

vec3 shadow_screen_to_shadow_view(vec3 shadow_screen_position) {
    return _project_and_divide(shadowProjectionInverse, shadow_screen_position * 2.0 - 1.0);
}

vec3 shadow_clip_to_shadow_view(vec4 shadow_clip_position) {
    return (shadowProjectionInverse * shadow_clip_position).xyz;
}

vec3 shadow_view_to_feet(vec3 shadow_view_position) {
    return (shadowModelViewInverse * vec4(shadow_view_position, 1.0)).xyz;
}

vec4 shadow_screen_to_shadow_clip(vec3 shadow_screen_position) {
    return shadow_view_to_shadow_clip(shadow_screen_to_shadow_view(shadow_screen_position));
}
#endif
