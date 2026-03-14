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
    #define FP_OP_TOLERANCE rcp(255.0) // Chosen value because of include comparisons made in the shader.

    // FP precision circumventing.

    bool fp_eq(float x, float y) {
        return abs(x - y) < FP_OP_TOLERANCE;
    }

    // Convenience.

    float clamp01(float value) {
        return clamp(value, 0.0, 1.0);
    }

    vec2 clamp01(vec2 value) {
        return clamp(value, 0.0, 1.0);
    }

    vec3 clamp01(vec3 value) {
        return clamp(value, 0.0, 1.0);
    }

    vec4 clamp01(vec4 value) {
        return clamp(value, 0.0, 1.0);
    }

    float max0(float value) {
        return max(0.0, value);
    }

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
