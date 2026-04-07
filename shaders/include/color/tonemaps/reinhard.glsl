#if !defined INCLUDE_TONEMAP_REINHARD
    #define INCLUDE_TONEMAP_REINHARD

    vec3 tonemap_reinhard(vec3 color) {
        return color / (color + vec3(1.0));
    }

    vec3 tonemap_reinhard2(vec3 x) {
        const float L_white = 1.0;

        return (x * (1.0 + x / (L_white * L_white))) / (1.0 + x);
    }
#endif
