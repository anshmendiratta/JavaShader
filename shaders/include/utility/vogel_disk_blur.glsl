#if !defined INCLUDE_VOGEL_DISK_BLUR
    #define INCLUDE_VOGEL_DISK_BLUR

    #include "/include/utility/dither.glsl"

    #define GOLDEN_ANGLE 2.39996322972865332 // Radians.

    float _compute_vogel_disk_radius(float idx, int sample_count);

    vec2 compute_vogel_disk_sample_uv(float idx, int sample_count) {
        float dither = compute_dither(gl_FragCoord.xy);
        float radius = _compute_vogel_disk_radius(idx, sample_count);
        float theta = (idx + 1.0) * GOLDEN_ANGLE;

        return radius * vec2(cos(theta), sin(theta));
    }

    float _compute_vogel_disk_radius(float idx, int sample_count) {
        return sqrt((idx + 0.5) / sample_count);
    }
#endif
