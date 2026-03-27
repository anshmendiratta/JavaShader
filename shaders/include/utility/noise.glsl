#if !defined INCLUDE_NOISE
    #define INCLUDE_NOISE

    #include "/lib/settings.glsl"
    #include "/include/uniforms.glsl"

    // --------------------
    //     Waving noise
    // --------------------

    float f(float a, vec2 coords) {
        return 0.25 * pow(2 + sin(a * coords.x), sin(a * coords.y) * cos(a * coords.x));
    }

    float sample_desmos_noise(vec2 coords) {
        float accumulator = 0.0;
        for (int a = 1; a < 3; a++) {
            accumulator += f(a, coords);
        }
        return accumulator - 0.5; // subtraction to attempt to bring the average value of the above sum function  over some closed domain to 0.0
    }

    // --------------------

    vec4 sample_default_noise(vec2 screen_uv) {
        return textureLod(noisetex, screen_uv, 0);
    }
#endif
