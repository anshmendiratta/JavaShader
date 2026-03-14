#if !defined INCLUDE_BITS
    #define INCLUDE_BITS

    #include "/include/uniforms.glsl"

    #include "/include/utility/math_fp.glsl"

    // Type sizes (bits):
    // - uint: 32

    // octahedral encoding (apparently used by iris internally too)
    // code taken from https://knarkowicz.wordpress.com/2014/04/16/octahedron-normal-vector-encoding/
    vec2 _octahedron_wrap(vec2 vector) {
        return (1.0 - abs(vector.yx)) * sign_not_zero(vector);
    }

    // assumes `vector` is unit and returns encoding in [0, 1]^2
    vec2 vector_encode_octahedral(vec3 vector) {
        vector /= (abs(vector.x) + abs(vector.y) + abs(vector.z));
        vector.xy = vector.z >= 0.0 ? vector.xy : _octahedron_wrap(vector.xy);
        vector.xy = vector.xy * 0.5 + 0.5;

        return vector.xy;
    }

    // takes encoding in [0, 1]^2
    vec3 vector_decode_octahedral(vec2 encoding) {
        encoding = encoding * 2.0 - 1.0;
        // https://twitter.com/Stubbesaurus/status/937994790553227264
        vec3 n = vec3(encoding.xy, 1.0 - abs(encoding.x) - abs(encoding.y));
        float t = clamp01(-n.z);
        n.xy += -sign_not_zero(n.xy) * t;

        return normalize(n);
    }
#endif
