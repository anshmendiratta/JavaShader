#if !defined INCLUDE_MATH_FP
    #define INCLUDE_MATH_FP

    // General constants.
    #define PI 3.1415926535897
    #define TAU 2.0 * PI

    // Smart denoise constants.
    #define INV_PI 0.31830988618
    #define INV_SQRT_OF_2PI 0.3989422804

    // Helper fn defines.
    #define rcp(x) (1.0 / (x))

    // CS constants.
    #define EPSILON rcp(255.0) // chosen value because of include comparisons made in the shader.

    // -------------------
    //     Convenience
    // -------------------

    float clamp01(float value) {
        return clamp(value, 0.0, 1.0);
    }

    vec2 clamp01(vec2 value) {
        return vec2(
            clamp01(value.x),
            clamp01(value.y)
        );
    }

    vec3 clamp01(vec3 value) {
        return vec3(
            clamp01(value.x),
            clamp01(value.y),
            clamp01(value.z)
        );
    }

    vec4 clamp01(vec4 value) {
        return vec4(
            clamp01(value.x),
            clamp01(value.y),
            clamp01(value.z),
            clamp01(value.w)
        );
    }

    float max0(float value) {
        return max(0.0, value);
    }

    float min0(float value) {
        return min(0.0, value);
    }

    float min1(float value) {
        return min(1.0, value);
    }

    float smoothstep01(float value) {
        return smoothstep(0.0, 1.0, value);
    }

    #define _define_float_pow(exp) float pow##exp(float value) { return pow(value, exp##.0); }

    _define_float_pow(2)
    _define_float_pow(3)
    _define_float_pow(4)
    _define_float_pow(5)

    #undef _define_float_pow

    #define _define_vec_pow(dim, exp) vec##dim pow##exp(vec##dim value) { return pow(value, vec##dim(exp##.0)); }

    _define_vec_pow(2, 2)
    _define_vec_pow(2, 3)
    _define_vec_pow(2, 4)
    _define_vec_pow(2, 5)
    _define_vec_pow(3, 2)
    _define_vec_pow(3, 3)
    _define_vec_pow(3, 4)
    _define_vec_pow(3, 5)
    _define_vec_pow(4, 2)
    _define_vec_pow(4, 3)
    _define_vec_pow(4, 4)
    _define_vec_pow(4, 5)

    #undef _define_vec_pow

    // ----------------------
    //     HLSL functions
    // ----------------------

    float sign_not_zero(float value) {
        return value >= 0.0 ? 1.0 : -1.0;
    }

    vec2 sign_not_zero(vec2 value) {
        return vec2(
            sign_not_zero(value.x),
            sign_not_zero(value.y)
        );
    }

    vec3 sign_not_zero(vec3 value) {
        return vec3(
            sign_not_zero(value.x),
            sign_not_zero(value.y),
            sign_not_zero(value.z)
        );
    }

    vec4 sign_not_zero(vec4 value) {
        return vec4(
            sign_not_zero(value.x),
            sign_not_zero(value.y),
            sign_not_zero(value.z),
            sign_not_zero(value.w)
        );
    }

#endif
