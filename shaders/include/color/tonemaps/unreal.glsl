#if !defined INCLUDE_TONEMAP_UNREAL
    #define INCLUDE_TONEMAP_UNREAL

    #include "/include/color/conversions.glsl"

    vec3 _tonemap_unreal(vec3 x) {
        x = rgb_to_linear(x);
        return x / (x + 0.155) * 1.019;
    }
#endif
