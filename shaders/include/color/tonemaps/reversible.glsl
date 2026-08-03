#if !defined INCLUDE_REVERSIBLE_TONEMAP
    #define INCLUDE_REVERSIBLE_TONEMAP

    #include "/include/utility/math/convenience.glsl"

    // --------------------------
    //     Reversible tonemap
    // --------------------------
    // from: https://gpuopen.com/learn/optimized-reversible-tonemapper-for-resolve/

    vec3 Tonemap(vec3 c) {
        return c / max_of(c.r, c.g, c.b) + 1.0;
    }

    // When the filter kernel is a weighted sum of fetched colors,
    // it is more optimal to fold the weighting into the tonemap operation.
    vec3 TonemapWithWeight(vec3 c, float w) {
        return c * (w / max_of(c.r, c.g, c.b) + 1.0);
    }

    // Apply this to restore the linear HDR color before writing out the result of the resolve.
    vec3 TonemapInvert(vec3 c) {
        return c / (1.0 - max_of(c.r, c.g, c.b));
    }
#endif
