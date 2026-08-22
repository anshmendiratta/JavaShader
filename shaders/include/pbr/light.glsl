#if !defined INCLUDE_PBR_LIGHT
    #define INCLUDE_PBR_LIGHT

    #include "/include/uniforms.glsl"

    #include "/include/pbr/atmosphere.glsl"

    vec3 get_sunlight_color(in float up_factor) {
        return get_sky_color(skyColor, fogColor, up_factor);
    }
#endif
