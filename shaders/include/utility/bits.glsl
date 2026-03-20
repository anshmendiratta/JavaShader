#if !defined INCLUDE_BITS
    #define INCLUDE_BITS

    #include "/include/uniforms.glsl"

    #include "/include/utility/math_fp.glsl"

    // Type sizes (bits):
    // - uint: 32

    // octahedral encoding (apparently used by iris internally too)
    // https://jcgt.org/published/0003/02/01/paper-lowres.pdf

    // assumes `vector` is unit and returns encoding in [0, 1]^2. returns x, y each in [-1, 1]
    vec2 vector_encode_octahedral(vec3 vector) {
        vec2 p = vector.xy * (1.0 / (abs(vector.x) + abs(vector.y) + abs(vector.z)));
        if (vector.z <= 0.0) {
            // reflect the folds of the lower hemisphere over the diagonals
            return (1.0 - abs(p.yx)) * sign_not_zero(p);
        } else {
            return p;
        }
    }

    // takes encoding in [-1, 1]^2
    vec3 vector_decode_octahedral(vec2 encoding) {
        vec3 v = vec3(encoding.xy, 1.0 - abs(encoding.x) - abs(encoding.y));
        if (v.z < 0) {
            v.xy = (1.0 - abs(v.yx)) * sign_not_zero(v.xy);
        }

        return normalize(v);
    }
#endif
