#if !defined INCLUDE_COLOR_CONVERSIONS
    #define INCLUDE_COLOR_CONVERSIONS

    // ---------------------------
    //     General conversions
    // ---------------------------

    vec3 rgb_to_linear(vec3 rgb) {
        return pow(rgb, vec3(2.2));
    }

    vec3 linear_to_rgb(vec3 linear) {
        return pow(linear, vec3(1.0 / 2.2));
    }

    float rgb_to_luminance(vec3 rgb) {
        return dot(rgb, vec3(0.2126, 0.7152, 0.0722));
    }

    // ------------------
    //     RGB/ACEScg
    // ------------------

    const mat3 RGB_TO_XYZ = mat3(0.5149, 0.3654, 0.0248, 0.3244, 0.6704, 0.1248, 0.1607, 0.0642, 0.8504);
    const mat3 XYZ_TO_AP0 = mat3(1.0498110175, -0.4959030231, 0., 0., 1.3733130458, 0., -0.0000974845, 0.0982400361, 0.9912520182);
    const mat3 AP0_TO_AP1 = mat3(-1.4514393161, -0.0765537734, -0.0083161484, -0.2365107469, -1.1762296998, -0.0060324498, -0.2149285693, -0.0996759264, -0.9977163014);

    const mat3 SRGB_TO_ACESCG = mat3(0.6131, 0.0702, 0.0206, 0.3395, 0.9164, 0.1096, 0.0474, 0.0135, 0.8698);

    vec3 rgb_to_ap1(const in vec3 rgb) {
        return AP0_TO_AP1 * (XYZ_TO_AP0 * (RGB_TO_XYZ * rgb));
    }

    vec3 ap1_to_rgb(const in vec3 ap1) {
        return inverse(RGB_TO_XYZ) * (inverse(XYZ_TO_AP0) * (inverse(AP0_TO_AP1) * ap1));
    }

    // ---------------
    //     RGB/HSV
    // ---------------
    // from: https://gist.github.com/983/e170a24ae8eba2cd174f.

    vec3 rgb_to_hsv(vec3 rgb) {
        vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        vec4 p = mix(vec4(rgb.bg, K.wz), vec4(rgb.gb, K.xy), step(rgb.b, rgb.g));
        vec4 q = mix(vec4(p.xyw, rgb.r), vec4(rgb.r, p.yzx), step(p.x, rgb.r));

        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;

        return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }

    vec3 hsv_to_rgb(vec3 hsv) {
        vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
        return hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
    }

    // ---------------
    //     RGB/HSL
    // ---------------
    // from: https://www.shadertoy.com/view/XljGzV

    vec3 rgb_to_hsl(vec3 rgb) {
        float h = 0.0;
        float s = 0.0;
        float l = 0.0;
        float r = rgb.r;
        float g = rgb.g;
        float b = rgb.b;
        float rgbMin = min(r, min(g, b));
        float rgbMax = max(r, max(g, b));

        l = (rgbMax + rgbMin) / 2.0;
        if (rgbMax > rgbMin) {
            float rgbDelta = rgbMax - rgbMin;

            //s = l < .05 ? rgbDelta / ( rgbMax + rgbMin ) : rgbDelta / ( 2.0 - ( rgbMax + rgbMin ) ); Original
            s = l < .0 ? rgbDelta / (rgbMax + rgbMin) : rgbDelta / (2.0 - (rgbMax + rgbMin));

            if (r == rgbMax) {
                h = (g - b) / rgbDelta;
            } else if (g == rgbMax) {
                h = 2.0 + (b - r) / rgbDelta;
            } else {
                h = 4.0 + (r - g) / rgbDelta;
            }

            if (h < 0.0) {
                h += 6.0;
            }

            h = h / 6.0;
        }

        return vec3(h, s, l);
    }

    vec3 hsl_to_rgb(vec3 hsl) {
        vec3 rgb = clamp(abs(mod(hsl.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);

        return hsl.z + hsl.y * (rgb - 0.5) * (1.0 - abs(2.0 * hsl.z - 1.0));
    }

    // -----------------
    //     RGB/OKLAB
    // -----------------

    const mat3 RGB_TO_OKLAB_MAP = mat3(
    0.4121656120, 0.2118591070, 0.0883097947,
    0.5362752080, 0.6807189584, 0.2818474174,
    0.0514575653, 0.1074065790, 0.6302613616
    );

    vec3 rgb_to_oklab(vec3 rgb) {
        return RGB_TO_OKLAB_MAP * rgb;
    }

    const mat3 OKLAB_TO_RGB_MAP = mat3(
    4.0767245293, -1.2681437731, -0.0041119885,
    -3.3072168827, 2.6093323231, -0.7034763098,
    0.2307590544, -0.3411344290, 1.7068625689
    );

    vec3 oklab_to_rgb(vec3 lms) {
        return OKLAB_TO_RGB_MAP * lms;
    }

    vec3 oklab_mix(vec3 color1_rgb, vec3 color2_rgb, float mix_factor) {
        vec3 color1_oklab = rgb_to_oklab(color1_rgb);
        vec3 color2_oklab = rgb_to_oklab(color2_rgb);

        vec3 oklab_mixed = mix(color1_oklab, color2_oklab, mix_factor);
        vec3 rgb_mixed = oklab_to_rgb(oklab_mixed);

        return rgb_mixed;
    }

    vec3 oklab_mix(vec3 color1_rgb, vec3 color2_rgb, vec3 mix_factors) {
        vec3 color1_oklab = rgb_to_oklab(color1_rgb);
        vec3 color2_oklab = rgb_to_oklab(color2_rgb);

        vec3 oklab_mixed = mix(color1_oklab, color2_oklab, mix_factors);
        vec3 rgb_mixed = oklab_to_rgb(oklab_mixed);

        return rgb_mixed;
    }
#endif
