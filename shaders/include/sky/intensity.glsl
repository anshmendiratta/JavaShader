#if !defined INCLUDE_SKY_INTENSITY
    #define INCLUDE_SKY_INTENSITY

    #include "/include/utility/math_fp.glsl"

    // Input range: [0., 24000.]
    // Useful range: [0., 2.]
    //
    // Assumes:
    // - Min sun intensity = min moon intensity = 0.3
    // - Max sun intensity = 1.0
    // - Max moon intensity = 0.5
    float compute_skylight_intensity_scalar(float world_time) {
        float useful_worldtime = world_time / 12000.0;
        float scalar = -1.6 * pow(useful_worldtime, 4.0) + 6.93333 * pow(useful_worldtime, 3.0) - 9.6 * pow(useful_worldtime, 2.0) + 4.26667 * useful_worldtime + 0.5;

        return clamp01(scalar);
    }
#endif
