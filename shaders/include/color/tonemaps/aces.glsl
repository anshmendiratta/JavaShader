#if !defined INCLUDE_TONEMAP_ACES
    #define  INCLUDE_TONEMAP_ACES

    // Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
    vec3 tonemap_aces(vec3 x) {
        const float a = 2.51;
        const float b = 0.03;
        const float c = 2.43;
        const float d = 0.59;
        const float e = 0.14;
        return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
    }
#endif
