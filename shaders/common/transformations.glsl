// Coordinate space conversions from clip to world space.
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

vec3 view_to_clip(vec3 view_space_position) {
    return gbufferProjection * vec4(view_space_position, 1.0);
}
