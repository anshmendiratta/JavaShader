#if !defined INCLUDE_SKY_INTENSITY
    #define INCLUDE_SKY_INTENSITY

    #include "/include/utility/math_fp.glsl"

    // Input range: [0., 1.]
    //
    // Assumes:
    // - Min sun intensity = min moon intensity = 0.3
    // - Max sun intensity = 1.0
    // - Max moon intensity = 0.3
    float compute_skylight_intensity_scalar(float daycycle_progress) {
        float t = 2.0 * daycycle_progress;
        float scalar = -2.67 * pow4(t) + 11.47 * pow3(t) - 15.73 * pow2(t) + 6.93 * t + 0.1;

        return clamp01(scalar);
    }
#endif
