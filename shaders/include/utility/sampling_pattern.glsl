#if !defined INCLUDE_VOGEL_DISK_BLUR
    #define INCLUDE_VOGEL_DISK_BLUR

    #include "/include/utility/dither.glsl"

    // ------------------
    //     Prototypes
    // ------------------

    float _compute_vogel_disk_radius(uint idx, int sample_count);

    // ---------------------------
    //     Vogel Disk Sampling
    // ---------------------------

    const float GOLDEN_ANGLE = 2.39996322972865332; // radians

    vec2 compute_vogel_disk_sample_uv(uint idx, int sample_count) {
        float radius = _compute_vogel_disk_radius(idx, sample_count);
        float theta = float(idx) * GOLDEN_ANGLE;

        return radius * vec2(cos(theta), sin(theta));
    }

    float _compute_vogel_disk_radius(uint idx, int sample_count) {
        return sqrt((float(idx) + 0.5) / sample_count);
    }
#endif
