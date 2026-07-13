#ifdef STAGE_VERTEX
    out vec2 uv;

    #include "/include/post/bloom.glsl"

    #include "/include/utility/space_conversions.glsl"

    void main() {
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        gl_Position = ftransform();

        // [120, 67] -> [60, 33]
        gl_Position.xy = gl_Position.xy * 0.5 + 0.5;
        gl_Position.xy = map_uv_to_tile(gl_Position.xy, 5u);
        gl_Position.xy = gl_Position.xy * 2. - 1.;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 30 */

    out vec3 bloom_ds;

    #include "/include/uniforms.glsl"
    #include "/include/buffers.glsl"

    #include "/include/post/bloom.glsl"

    void main() {
        bloom_ds = bloom_downsample(colortex30, map_uv_to_tile(uv, 4u));
    }
#endif
