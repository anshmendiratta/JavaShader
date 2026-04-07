#if !defined INCLUDE_TONEMAP_UNCHARTED
    #define  INCLUDE_TONEMAP_UNCHARTED

    vec3 tonemap_uncharted2(vec3 x) {
        float A = 0.15;
        float B = 0.50;
        float C = 0.10;
        float D = 0.20;
        float E = 0.02;
        float F = 0.30;
        float W = 11.2;
        return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
    }
#endif
