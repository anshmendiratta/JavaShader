// General constants.
#define PI 3.1415926535897
#define TAU 2.0 * PI
// CS constants.
#define FP_OP_TOLERANCE 1e-3

#define rcp(x) 1.0 / x

bool eq(x, y) {
    return abs(x - y) < FP_OP_TOLERANCE;
}
