#if !defined INCLUDE_COLOR_CONVERSIONS
    #define INCLUDE_COLOR_CONVERSIONS
    // The below two functions are taken from shrimple v2.
    // (https://github.com/search?q=repo%3ANull-MC%2FShrimple%20_RGBToLinear&type=code)
    vec3 rgb_to_linear(vec3 rgb) {
        return pow(rgb, vec3(2.2));
    }

    vec3 linear_to_rgb(vec3 linear) {
        return pow(linear, vec3(1.0 / 2.2));
    }

    float rgb_to_luminance(vec3 rgb) {
        return dot(rgb, vec3(0.2126, 0.7152, 0.0722));
    }

    // Taken from https://gist.github.com/983/e170a24ae8eba2cd174f.
    vec3 rgb_to_hsv(vec3 rgb) {
        vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        vec4 p = mix(vec4(rgb.bg, K.wz), vec4(rgb.gb, K.xy), step(rgb.b, rgb.g));
        vec4 q = mix(vec4(p.xyw, rgb.r), vec4(rgb.r, p.yzx), step(p.x, rgb.r));

        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;

        return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }

    // Taken from https://gist.github.com/983/e170a24ae8eba2cd174f.
    vec3 hsv_to_rgb(vec3 hsv) {
        vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
        return hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
    }

    // ---
    // Color grading.
    // ---

    struct ColorGrading {
        float saturation;
        float brightness;
    };

    vec3 saturate_rgb(vec3 rgb, float saturation) {
        vec3 grayscale = vec3(rgb_to_luminance(rgb));
        return mix(grayscale, rgb, saturation);
    }

    // TODO: complete.
    vec3 brighten_rgb(vec3 rgb, float brightness) {
        return vec3(0.0);
    }

    vec3 color_grade(vec3 rgb, ColorGrading cg) {
        return vec3(0.0);
    }
#endif
