vec3 project_and_divide(mat4 projection_matrix, vec3 position) {
    vec4 homogenous_position = projection_matrix * vec4(position, 1.0);
    return homogenous_position.xyz / homogenous_position.w; // Perspective division.
}
