#if !defined INCLUDE_COLOR_GRADING
    #define INCLUDE_COLOR_GRADING

    #include "/include/color/conversions.glsl"

    // ------------------
    //     Prototypes
    // ------------------

    vec3 brighten_rgb(in vec3 rgb, in float brightness);
    vec3 saturate_rgb(in vec3 rgb, in float saturation);
    vec3 contrast_rgb(in vec3 rgb, in float contrast);

    // ---------------------
    //     Color grading
    // ---------------------

    struct ColorGrading {
        float saturation;
        float brightness;
        float contrast;
    };

    void color_grade(inout vec3 rgb, in ColorGrading cg) {
        rgb = saturate_rgb(rgb, cg.saturation);
        rgb = brighten_rgb(rgb, cg.brightness);
        rgb = contrast_rgb(rgb, cg.contrast);
    }

    #if PURKINJE_SHIFT == 1
        // Average wavelengths (nm)
        // (red, green, blue) = (688, 512, 473)

        void apply_purkinje(inout vec3 rgb, in float luminance) {
            vec3 purkinje_color = vec3(0.3, 0.7, 1.);
            float weight = exp(-100. * luminance);

            vec3 xyz = RGB_TO_XYZ * rgb;
            float scotopic_luminance = xyz.y * (1.33 * (1 + (xyz.y + xyz.z) / xyz.x) - 1.68);

            rgb = oklab_mix(rgb, scotopic_luminance * purkinje_color, weight);
        }
    #endif

    // -------------------------
    //     Atomic operations
    // -------------------------

    vec3 saturate_rgb(in vec3 rgb, in float saturation) {
        vec3 grayscale = vec3(rgb_to_luminance(rgb));
        return mix(grayscale, rgb, saturation);
    }

    vec3 brighten_rgb(in vec3 rgb, in float brightness) {
        vec3 hsv = rgb_to_hsv(rgb);
        return hsv_to_rgb(hsv * vec3(vec2(1.f), brightness));
    }

    vec3 contrast_rgb(in vec3 rgb, in float contrast) {
        return rgb;
    }
#endif
