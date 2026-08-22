#if !defined INCLUDE_SHADOWS_DISTORT
    #define INCLUDE_SHADOWS_DISTORT

    #include "/include/settings.glsl"
    #include "/include/pipeline.glsl"

    #include "/include/math/convenience.glsl"

    // -------------------------
    //     Shadow distortion
    // -------------------------
    // from photon by sixthsurge.
    // - https://github.com/sixthsurge/photon

    void _multiply_shadow_distance(inout vec3 shadow_clip_position);
    float _get_distortion_factor(vec2 position_shadow_clip);
    float _quartic_length(vec2 v);

    void distort_shadow_clip_position(inout vec3 undistorted_position) {
        _multiply_shadow_distance(undistorted_position);
        float distortion_factor = _get_distortion_factor(undistorted_position.xy);
        undistorted_position *= vec3(vec2(1. / distortion_factor), 1.);
    }

    void undistort_shadow_clip_position(inout vec3 distorted_position) {
        distorted_position.xy *= (1. - SHADOW_DISTORTION) / (1. - _quartic_length(distorted_position.xy));
        distorted_position.z *= SHADOW_DISTANCE_MULTIPLIER;
    }

    void _multiply_shadow_distance(inout vec3 shadow_clip_position) {
        shadow_clip_position.z *= 1. / SHADOW_DISTANCE_MULTIPLIER;
    }

    float _quartic_length(vec2 v) {
        return sqrt(sqrt(pow4(v.x) + pow4(v.y)));
    }

    float _get_distortion_factor(vec2 position_shadow_clip) {
        return _quartic_length(position_shadow_clip.xy) * SHADOW_DISTORTION + (1. - SHADOW_DISTORTION);
    }

#endif
