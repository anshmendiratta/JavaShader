#if !defined INCLUDE_TONEMAP_EXPOSURE
    #define INCLUDE_TONEMAP_EXPOSURE

    vec3 _tonemap_exposure(vec3 color) {
        const float exposure = 1.0;

        return 1.0 - exp(-color * exposure);
    }
#endif
