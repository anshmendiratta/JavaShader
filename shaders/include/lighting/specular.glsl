float compute_specular(vec3 view_vector_world_space, vec3 light_source_direction_world_space, vec3 normal_world_space) {
    vec3 halfway_vector_world_space = normalize(light_source_direction_world_space + view_vector_world_space);
    return clamp(dot(normal_world_space, halfway_vector_world_space), 0.0, 1.0);
}
