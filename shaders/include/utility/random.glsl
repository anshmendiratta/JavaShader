#if !defined INCLUDE_RANDOM
    #define INCLUDE_RANDOM

    #include "/include/uniforms.glsl"

    #include "/include/math/convenience.glsl"

    // from: https://github.com/sixthsurge/photon/blob/82fe60e5705d69563d8b38dd75625261ac5cecd9/shaders/program/dh_terrain.fsh#L50
    mat3 get_tbn_matrix(in vec3 normal) {
        vec3 tangent = normal.y == 1.0
            ? vec3(1.0, 0.0, 0.0) : normalize(cross(vec3(0.0, 1.0, 0.0), normal));
        vec3 bitangent = normalize(cross(tangent, normal));
        return mat3(tangent, bitangent, normal);
    }

    vec3 _project_and_divide(mat4 projection_matrix, vec3 position) {
        vec4 homogenous_position = projection_matrix * vec4(position, 1.0);
        return homogenous_position.xyz / homogenous_position.w; // Perspective division.
    }

    bool fragment_is_hand(vec2 uv) {
        if (texture(colortex31, uv).r == 1) return true;

        return false;
    }

    bool fragment_is_translucent(vec2 uv) {
        return texture(depthtex0, uv).r != texture(depthtex1, uv).r;
    }

    bool uv_out_of_bounds(vec2 uv) {
        return clamp01(uv) != uv;
    }
#endif