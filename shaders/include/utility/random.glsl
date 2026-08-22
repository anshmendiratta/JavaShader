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

    bool fragment_is_translucent(vec2 uv) {
        return texture(depthtex0, uv).r != texture(depthtex1, uv).r;
    }

    bool uv_out_of_bounds(vec2 uv) {
        return clamp01(uv) != uv;
    }

    // const float hand_depth = MC_HAND_DEPTH * 0.5 + 0.5;
    const float hand_depth = .56;
    // const float hand_depth = MC_HAND_DEPTH *0.5+0.5;

    // --------------------
    //     Hand fuckery
    // --------------------
    // from photon: https://github.com/sixthsurge/photon/blob/eaf04bfa7b1cf3682818aaca4a91ce0995ca5639/shaders/include/global.glsl

    bool frag_is_hand(float depth) {
        return depth < hand_depth;
    }

    void fix_hand_depth(inout float depth) {
        if (!frag_is_hand(depth)) return;

        depth = depth * 2.0 - 1.0;
        depth *= rcp(MC_HAND_DEPTH);
        depth = depth * 0.5 + 0.5;
    }
#endif
