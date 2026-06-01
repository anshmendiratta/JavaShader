#if !defined INCLUDE_DITHER
    #define INCLUDE_DITHER

    #include "/include/utility/noise.glsl"

    #include "/include/math/convenience.glsl"

    // taken from https://docs.rs/dithereens/latest/src/dithereens/spatial.rs.html#30-37.
    float _interleaved_gradient_noise(in const vec2 xy) {
        float value = fract(52.982918 * (fract(0.06711056 * xy.x + 0.00583715 * xy.y)));

        return value * 2.0 - 1.0;
    }

    // taken from rre36's nostalgia shader. clearly the same as above but with a temporal factor
    float _rre36_temporal_blue_noise() {
        return fract(52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y + 0.00623715 * (frameCounter * 0.31)));
    }

    // uses blue noise texture for high-quality, stable dithering without banding
    float _blue_noise_dither(in const vec2 xy) {
        const float NOISE_TRANSLATION_SPEED = 100.0;
        ivec2 noise_uv = ivec2(NOISE_TRANSLATION_SPEED * frameTimeCounter + pow2(xy)) % 256; // assuming 256x256 noise texture
        return sample_default_noise(noise_uv).r;
    }

    // uses whatever dither generation technique. currently blue noise
    float compute_dither(in const vec2 xy) {
        // return _blue_noise_dither(xy);
        return _rre36_temporal_blue_noise();
    }
#endif
