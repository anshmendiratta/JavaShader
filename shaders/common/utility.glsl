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

// https://backend.orbit.dtu.dk/ws/portalfiles/portal/126824972/onb_frisvad_jgt2012_v2.pdf
mat3 generate_tbn(vec3 n) {
    mat3 tbn;
    tbn[2] = n;
    if (n.z < -0.9) {
        tbn[0] = vec3(0.0, -1, 0);
        tbn[1] = vec3(-1, 0, 0);
    } else {
        float a = 1.0 / (1.0 + n.z);
        float b = -n.x * n.y * a;
        tbn[0] = vec3(1.0 - n.x * n.x * a, b, -n.x);
        tbn[1] = vec3(b, 1.0 - n.y * n.y * a, -n.y);
    }
    return tbn;
}

// From https://www.shadertoy.com/view/Xt23Ry.
float rand(float i) {
    return fract(sin(i * (91.3458)) * 47453.5453);
}

// // Coordinate space conversions from clip to world space.
// vec3 clip_to_view(vec4 clip_space_position) {
//     return (gbufferProjectionInverse * clip_space_position).xyz;
// }

// vec3 view_to_feet(vec3 view_space_position) {
//     return (gbufferModelViewInverse * vec4(view_space_position, 1.0)).xyz;
// }

// vec3 feet_to_world(vec3 feet_space_position) {
//     return feet_space_position + cameraPosition;
// }

// // Coordinate space conversions from world to clip space.
// vec3 world_to_feet(vec3 world_space_position) {
//     return world_space_position - cameraPosition;
// }

// vec3 feet_to_view(vec3 feet_space_position) {
//     return (gbufferModelView * vec4(feet_space_position, 1.0)).xyz;
// }

// vec3 view_to_clip(vec3 view_space_position) {
//     return gbufferProjection * vec4(view_space_position, 1.0);
// }
