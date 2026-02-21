float compute_diffuse(vec3 light_source_direction_world_space, vec3 normal_world_space) {
    return clamp(dot(light_source_direction_world_space, normal_world_space), 0.0, 1.0);
}
