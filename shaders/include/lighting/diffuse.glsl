#if !defined INCLUDE_DIFFUSE
    #define INCLUDE_DIFFUSE

    #include "/include/utility/math_fp.glsl"

    float compute_diffuse(vec3 light_source_direction_world_space, vec3 normal_world_space) {
        return clamp01(dot(light_source_direction_world_space, normal_world_space));
    }
#endif
