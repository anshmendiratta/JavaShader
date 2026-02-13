// General constants.
#define PI 3.1415926535897
#define TAU 2.0 * PI

// Smart denoise constants.
#define INV_PI 0.31830988618
#define INV_SQRT_OF_2PI 0.3989422804

// Helper fn defines.
#define rcp(x) 1.0 / x

// CS constants.
#define FP_OP_TOLERANCE rcp(255.0) // Chosen value because of common comparisons made in the shader.

// FP precision circumventing.
bool fp_eq(float x, float y) {
    return abs(x - y) < FP_OP_TOLERANCE;
}
