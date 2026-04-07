#if !defined INCLUDE_TONEMAP_TECH
    #define INCLUDE_TONEMAP_TECH

    vec3 tonemap_tech(vec3 color, float contrast) {
        float c = rcp(contrast);
        vec3 a = color * min(vec3(1.0), 1.0 - exp(-c * color));
        a = mix(a, color, color * color);
        return a / (a + 0.6);
    }
#endif
