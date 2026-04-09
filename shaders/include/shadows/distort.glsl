#if !defined INCLUDE_SHADOWS_DISTORT
    #define INCLUDE_SHADOWS_DISTORT

    #include "/include/settings.glsl"

    const float SHADOW_BIAS_STARTER = SHADOW_BIAS;
    const float SHADOW_BIAS_EPSILON = 0.08;

    float _compute_distortion_factor(vec2 shadow_clip_position);
    // void _multiply_shadow_distance(out vec4 shadow_clip_position);
    float _compute_shadow_bias(vec3 position);

    vec3 distort_shadow_clip_position(vec3 shadow_clip_position) {
        float distortion_factor = _compute_distortion_factor(shadow_clip_position.xy) + SHADOW_BIAS_EPSILON;
        shadow_clip_position.xy /= distortion_factor;

        return shadow_clip_position;
    }

    float _compute_distortion_factor(vec2 position) {
        return length(position.xy) + SHADOW_BIAS_EPSILON;
    }

    // void _multiply_shadow_distance(out vec4 shadow_clip_position) {
    //     shadow_clip_position.z /= SHADOW_DISTANCE_MULTIPLIER;
    // }

    float _compute_shadow_bias(vec3 position) {
        float distortion_factor = length(position.xy) + SHADOW_BIAS_EPSILON;

        return SHADOW_BIAS_STARTER / SHADOW_MAP_RESOLUTION * (distortion_factor * distortion_factor) / SHADOW_BIAS_EPSILON; // 1.0 / shadowMapResolution * square(length(position.xy) + EPSILON) / EPSILON
    }
#endif
