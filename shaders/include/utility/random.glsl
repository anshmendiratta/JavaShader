#if !defined INCLUDE_RANDOM
    #define INCLUDE_RANDOM

    #include "/include/uniforms.glsl"

    vec3 _project_and_divide(mat4 projection_matrix, vec3 position) {
        vec4 homogenous_position = projection_matrix * vec4(position, 1.0);
        return homogenous_position.xyz / homogenous_position.w; // Perspective division.
    }

    bool fragment_is_hand(vec2 uv) {
        if (texture(colortex31, uv).r == 1) return true;

        return false;
    }
#endif
