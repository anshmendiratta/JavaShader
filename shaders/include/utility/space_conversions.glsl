#if !defined INCLUDE_SPACE_CONVERSIONS
#define INCLUDE_SPACE_CONVERSIONS

#include "/include/uniforms.glsl"

// Coordinate space conversions from screen to world space.
vec3 screen_to_ndc(vec3 screen_space_position) {
    return screen_space_position * 2.0 - 1.0;
}

vec3 ndc_to_view(vec3 ndc_space_position) {
    return project_and_divide(gbufferProjectionInverse, ndc_space_position);
}

vec3 clip_to_view(vec4 clip_space_position) {
    return (gbufferProjectionInverse * clip_space_position).xyz;
}

vec3 view_to_feet(vec3 view_space_position) {
    return (gbufferModelViewInverse * vec4(view_space_position, 1.0)).xyz;
}

vec3 feet_to_world(vec3 feet_space_position) {
    return feet_space_position + cameraPosition;
}

// Coordinate space conversions from world to clip space.
vec3 world_to_feet(vec3 world_space_position) {
    return world_space_position - cameraPosition;
}

vec3 feet_to_view(vec3 feet_space_position) {
    return (gbufferModelView * vec4(feet_space_position, 1.0)).xyz;
}

vec4 view_to_clip(vec3 view_space_position) {
    return gbufferProjection * vec4(view_space_position, 1.0);
}

vec3 view_to_ndc(vec3 view_space_position) {
    return project_and_divide(gbufferProjection, view_space_position);
}

vec3 ndc_to_screen(vec3 ndc_space_position) {
    return ndc_space_position * 0.5 + 0.5;
}

#endif
