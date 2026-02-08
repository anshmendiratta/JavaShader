// General constants.
#define PI 3.1415926535897
#define TAU 2.0 * PI

#define rcp(x) 1.0 / x

// CS constants.
#define FP_OP_TOLERANCE rcp(255.0)

bool fp_eq(float x, float y) {
    return abs(x - y) < FP_OP_TOLERANCE;
}
