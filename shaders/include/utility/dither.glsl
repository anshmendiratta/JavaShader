#if !defined INCLUDE_DITHER
    #define INCLUDE_DITHER

    #include "/include/utility/math_fp.glsl"

    // taken from https://docs.rs/dithereens/latest/src/dithereens/spatial.rs.html#30-37.
    float _interleaved_gradient_noise(vec2 xy) {
        float value = fract(52.982918 * (fract(0.06711056 * xy.x + 0.00583715 * xy.y)));

        return value * 2.0 - 1.0;
    }

    // uses whatever dither generation technique. currently interleaved gradient noise
    float compute_dither(vec2 xy) {
        float x_dither = _interleaved_gradient_noise(xy);
        float y_dither = _interleaved_gradient_noise(xy.yx);
        vec2 xy_dither = vec2(x_dither, y_dither);

        return rcp(2.0) * (xy_dither.x + xy_dither.y);
    }
#endif
