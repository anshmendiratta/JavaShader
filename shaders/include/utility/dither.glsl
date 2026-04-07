#if !defined INCLUDE_DITHER
    #define INCLUDE_DITHER

    #include "/include/math/convenience.glsl"
    #include "/include/utility/noise.glsl"

    // taken from https://docs.rs/dithereens/latest/src/dithereens/spatial.rs.html#30-37.
    float _interleaved_gradient_noise(vec2 xy) {
        float value = fract(52.982918 * (fract(0.06711056 * xy.x + 0.00583715 * xy.y)));

        return value * 2.0 - 1.0;
    }

    // uses blue noise texture for high-quality, stable dithering without banding
    float _blue_noise_dither(vec2 xy) {
        // Tile noise texture to avoid repetition patterns
        vec2 noise_uv = xy / 256.0; // assuming 256x256 noise texture
        vec4 blue_noise = sample_default_noise(fract(noise_uv));
        
        // Return value in [0, 1] range
        return blue_noise.r;
    }

    // uses whatever dither generation technique. currently blue noise
    float compute_dither(vec2 xy) {
        return _blue_noise_dither(xy);
    }
#endif