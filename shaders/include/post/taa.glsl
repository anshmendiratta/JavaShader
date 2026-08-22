#if !defined INCLUDE_TAA
    #define INCLUDE_TAA

    #include "/include/uniforms.glsl"

    #include "/include/utility/coordinates.glsl"

    // -----------
    //     TAA
    // -----------
    // jitter from shrimple

    vec2 taa_jitter = vec2(
    fract(0.75487766624669276005 * frameCounter + 0.5) - 0.5,
    fract(0.56984029099805326591 * frameCounter + 0.5) - 0.5
    )
    / (2. * windowDimensions);
#endif
