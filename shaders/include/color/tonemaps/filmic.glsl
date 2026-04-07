#if !defined IIONCLUDE_TONEMAP_FILMIC
    #define IIONCLUDE_TONEMAP_FILMIC

    vec3 tonemap_filmic(vec3 x) {
        vec3 X = max(vec3(0.0), x - 0.004);
        vec3 result = (X * (6.2 * X + 0.5)) / (X * (6.2 * X + 1.7) + 0.06);
        return pow(result, vec3(2.2));
    }
#endif
