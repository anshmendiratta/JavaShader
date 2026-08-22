#ifdef STAGE_VERTEX
    out vec2 uv;

    #include "/include/post/bloom.glsl"

    #include "/include/utility/coordinates.glsl"

    void main() {
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        gl_Position = ftransform();

        // [960, 540] -> [480, 270]
        gl_Position.xy = gl_Position.xy * 0.5 + 0.5;
        gl_Position.xy = map_uv_to_tile(gl_Position.xy, 2u);
        gl_Position.xy = gl_Position.xy * 2. - 1.;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 29 */

    out vec3 bloom_ds;

    #include "/include/uniforms.glsl"
    #include "/include/buffers.glsl"

    #include "/include/post/bloom.glsl"

    void main() {
        bloom_ds = bloom_downsample(colortex29, map_uv_to_tile(uv, 1u), 1u);
    }
#endif