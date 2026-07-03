#if !defined INCLUDE_SHADOWS_DISTORT
    #define INCLUDE_SHADOWS_DISTORT

    #include "/include/settings.glsl"

    const float SHADOW_BIAS_STARTER = SHADOW_BIAS;
    const float SHADOW_BIAS_EPSILON = 0.08;

    float _compute_distortion_factor(vec2 shadow_clip_position);
    float _compute_undistortion_factor(vec2 shadow_clip_position);
    void _multiply_shadow_distance(out vec3 shadow_clip_position);
    float _compute_shadow_bias(vec3 position);

    const float k = 3.0;

    void distort_shadow_clip_position(inout vec2 shadow_clip_position) {
        shadow_clip_position *= _compute_distortion_factor(shadow_clip_position);
    }

    void distort_shadow_clip_position(inout vec3 shadow_clip_position) {
        shadow_clip_position *= _compute_distortion_factor(shadow_clip_position.xy);
        _multiply_shadow_distance(shadow_clip_position);
    }

    void undistort_shadow_clip_position(inout vec2 distorted_position) {
        distorted_position *= _compute_undistortion_factor(distorted_position);
    }

    void undistort_shadow_clip_position(inout vec3 distorted_position) {
        distorted_position.xy *= _compute_undistortion_factor(distorted_position.xy);
    }

    float _compute_distortion_factor(vec2 position) {
        return 1. / (1. + k * length(position));
    }

    float _compute_undistortion_factor(vec2 position) {
        return 1. / (1. - k * length(position));
    }

    void _multiply_shadow_distance(out vec3 shadow_clip_position) {
        shadow_clip_position.z /= SHADOW_DISTANCE_MULTIPLIER;
    }

    float _compute_shadow_bias(vec3 position) {
        float distortion_factor = length(position.xy) + SHADOW_BIAS_EPSILON;

        return SHADOW_BIAS_STARTER / SHADOW_MAP_RESOLUTION * (distortion_factor * distortion_factor) / SHADOW_BIAS_EPSILON; // 1.0 / shadowMapResolution * square(length(position.xy) + EPSILON) / EPSILON
    }
#endif
