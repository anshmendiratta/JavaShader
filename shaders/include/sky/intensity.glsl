#if !defined INCLUDE_SKY_INTENSITY
    #define INCLUDE_SKY_INTENSITY

    #include "/include/settings.glsl"

    #include "/include/math/convenience.glsl"

    // Input range: [0., 1.]
    // - 0.5: sunset
    // - 1.0: dawn
    //
    // follows sin(theta) where theta is the solar altitude
    float compute_skylight_intensity_scalar(float daycycle_progress) {
        daycycle_progress *= 2.;
        float theta = 2. * PI * daycycle_progress;
        if (daycycle_progress < 1.) {
            return SUNLIGHT_INTENSITY * max0(sin(daycycle_progress));
        } else {
            return MOONLIGHT_INTENSITY * max0(sin(daycycle_progress));
        }
    }
#endif
