vec3 project_and_divide(mat4 projection_matrix, vec3 position) {
    vec4 homogenous_position = projection_matrix * vec4(position, 1.0);
    return homogenous_position.xyz / homogenous_position.w; // Perspective division.
}

mat3 tbn_normal_tangent(vec3 normal, vec3 tangent) {
    // TODO: Figure out why this works.
    // For DirectX normal mapping you want to switch the order of these
    vec3 bi_tangent = normalize(cross(tangent, normal));

    return mat3(tangent, bi_tangent, normal);
}

// From https://www.shadertoy.com/view/Xt23Ry.
float rand(float i) {
    return fract(sin(i * (92.3458)) * 47453.5453);
}
