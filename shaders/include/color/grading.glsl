#if !defined INCLUDE_COLOR_GRADING
    #define INCLUDE_COLOR_GRADING

    #include "/include/color/conversions.glsl"

    // ------------------
    //     Prototypes
    // ------------------

    void brighten_rgb(inout vec3 rgb, in float brightness);
    void saturate_rgb(inout vec3 rgb, in float saturation);
    void contrast_rgb(inout vec3 rgb, in float contrast);

    // ---------------------
    //     Color grading
    // ---------------------

    struct ColorGrading {
        float saturation;
        float brightness;
        float contrast;
    };

    void color_grade(inout vec3 rgb, in ColorGrading cg) {
        saturate_rgb(rgb, cg.saturation);
        brighten_rgb(rgb, cg.brightness);
        contrast_rgb(rgb, cg.contrast);
    }

    #if PURKINJE_SHIFT == 1
        // Average wavelengths (nm)
        // (red, green, blue) = (688, 512, 473)

        const mat3 RGB_TO_XYZ = mat3(
        0.5149, 0.3654, 0.0248,
        0.3244, 0.6704, 0.1248,
        0.1607, 0.0642, 0.8504
        );

        void apply_purkinje(inout vec3 rgb, in float luminance) {
            vec3 xyz = RGB_TO_XYZ * rgb;
            float scotopic_luminance = xyz.y * (1.33 * (1 + (xyz.y + xyz.z) / xyz.x) - 1.68);
            vec3 purkinje_color = vec3(0.3, 0.7, 1.);
            float weight = exp(-100. * luminance);

            rgb = mix(rgb, scotopic_luminance * purkinje_color, weight);
        }
    #endif

    // -------------------------
    //     Atomic operations
    // -------------------------

    void saturate_rgb(inout vec3 rgb, in float saturation) {
        vec3 grayscale = vec3(rgb_to_luminance(rgb));
        rgb = mix(grayscale, rgb, saturation);
    }

    // TODO: complete.
    void brighten_rgb(inout vec3 rgb, in float brightness) {
        vec3 hsl = rgb_to_hsv(rgb);
        rgb = hsv_to_rgb(hsl * vec3(vec2(1.f), brightness));
    }

    void contrast_rgb(inout vec3 rgb, in float contrast) {}
#endif
