#if !defined INCLUDE_CONVENIENCE
    #define INCLUDE_CONVENIENCE

    // General constants.
    #define PI 3.1415926535897
    #define TAU 2.0 * PI
    #define SQRT_TWO 1.414213562373095048801688724209

    // Smart denoise constants.
    #define INV_PI 0.31830988618
    #define INV_SQRT_OF_2PI 0.3989422804

    // Helper fn defines.
    #define rcp(x) (1.0 / (x))

    // CS constants.
    #define EPSILON 1e-4 // chosen value because of include comparisons made in the shader.

    // -------------------
    //     Convenience
    // -------------------

    bool eq_eps(float first, float second, float epsilon_scalar) {
        return abs(first - second) < EPSILON * epsilon_scalar;
    }

    bool eq_eps(float first, float second) {
        return abs(first - second) < EPSILON;
    }

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

    float max_eps(float value) {
        return max(EPSILON, value);
    }

    float max0(float value) {
        return max(0.0, value);
    }

    #define _define_max0_vec(dim) vec##dim max0(vec##dim value) { return max(vec##dim(0.0), value); }
    _define_max0_vec(2);
    _define_max0_vec(3);
    _define_max0_vec(4);
    #undef _define_max0_vec

    float max1(float value) {
        return max(1.0, value);
    }

    #define _define_max1_vec(dim) vec##dim max1(vec##dim value) { return max(vec##dim(1.0), value); }
    _define_max1_vec(2);
    _define_max1_vec(3);
    _define_max1_vec(4);
    #undef _define_max0_vec

    float min0(float value) {
        return min(0.0, value);
    }

    #define _define_min0_vec(dim) vec##dim min0(vec##dim value) { return min(vec##dim(0.0), value); }
    _define_min0_vec(2);
    _define_min0_vec(3);
    _define_min0_vec(4);
    #undef _define_min0_vec

    float min1(float value) {
        return min(1.0, value);
    }

    #define _define_min1_vec(dim) vec##dim min1(vec##dim value) { return min(vec##dim(1.0), value); }
    _define_min1_vec(2);
    _define_min1_vec(3);
    _define_min1_vec(4);
    #undef _define_min1_vec

    float min_of(vec2 value) {
        return min(value.x, value.y);
    }

    float min_of(vec3 value) {
        return min(value.z, min_of(value.xy));
    }

    float min_of(vec4 value) {
        return min(value.w, min_of(value.xyz));
    }

    float max_of(vec2 value) {
        return max(value.x, value.y);
    }

    float max_of(vec3 value) {
        return max(value.z, max_of(value.xy));
    }

    float max_of(vec4 value) {
        return max(value.w, max_of(value.xyz));
    }

    float avg_vec(vec2 value) {
        return dot(vec2(rcp(2.0)), value);
    }

    float avg_vec(vec3 value) {
        return dot(vec3(rcp(3.0)), value);
    }

    float avg_vec(vec4 value) {
        return dot(vec4(rcp(4.0)), value);
    }

    float smoothstep01(float value) {
        return smoothstep(0.0, 1.0, value);
    }

    // from: https://en.wikipedia.org/wiki/Smoothstep#Variations
    float smootherstep01(float value) {
        float x = clamp(value, 0., 1.);
        return x * x * x * (x * (6. * x - 15.) + 10.);
    }

    #define _define_smoothstep01_vec(dim) vec##dim smoothstep01(vec##dim value) { return smoothstep(vec##dim(0.0), vec##dim(1.0), value); }
    _define_smoothstep01_vec(2);
    _define_smoothstep01_vec(3);
    _define_smoothstep01_vec(4);
    #undef _define_smoothstep01_vec

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

    // -------------------------------
    //     Mystical math functions
    // -------------------------------

    // positive characteristic, chi_+
    float char_positive(float value) {
        if (value > 0.0) return 1.0;
        return 0.0;
    }
#endif
