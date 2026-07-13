#if !defined INCLUDE_COLOR_GRADING
    #define INCLUDE_COLOR_GRADING
    // ------------------
    //     Prototypes
    // ------------------

    void _brighten_rgb(inout vec3 rgb, in float brightness);
    void _saturate_rgb(inout vec3 rgb, in float saturation);

    // ---------------------
    //     Color grading
    // ---------------------

    struct ColorGrading {
        float saturation;
        float brightness;
        float contrast;
    };

    void color_grade(inout vec3 rgb, in ColorGrading) {
        return vec3(0.0);
    }

    // -------------------------
    //     Atomic operations
    // -------------------------

    void _saturate_rgb(inout vec3 rgb, in float saturation) {
        vec3 grayscale = vec3(rgb_to_luminance(rgb));
        return mix(grayscale, rgb, saturation);
    }

    // TODO: complete.
    void _brighten_rgb(inout vec3 rgb, in float brightness) {
        return vec3(0.0);
    }
#endif