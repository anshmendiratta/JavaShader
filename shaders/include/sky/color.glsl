#if !defined INCLUDE_SKY_COLOR
    #define INCLUDE_SKY_COLOR

    #include "/include/color/conversions.glsl"

    #define MAGIC_FOG_VALUE 0.08 // taken from shrimple v2: https://github.com/Null-MC/Shrimple/blob/f4fcab627cc62bd2e66813c58cd657bb4ecbb84f/shaders/lib/fog/fog_common.glsl#L1

    float _fogify(float x, float w) {
        return w / (x * x + w);
    }

    // returns in linear space
    vec3 get_sky_color(vec3 sky_color, vec3 fog_color, float up_factor) {
        vec3 fogcolor_oklab = rgb_to_oklab(fog_color);
        vec3 skycolor_oklab = rgb_to_oklab(sky_color);

        float fogified_factor = _fogify(up_factor, MAGIC_FOG_VALUE);
        vec3 oklab_mixed = mix(skycolor_oklab, fogcolor_oklab, fogified_factor);
        vec3 rgb_mixed = oklab_to_rgb(oklab_mixed);

        return rgb_to_linear(rgb_mixed);
    }
#endif
