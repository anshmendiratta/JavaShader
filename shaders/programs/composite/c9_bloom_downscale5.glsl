#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 10 */
    layout(location = 0) out vec4 bloom_downscale;

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/post/bloom.glsl"

    void main() {
        // Fifth downscale pass: colortex9 -> colortex10 (1/32 resolution)
        vec2 texel_size = 1.0 / (vec2(viewWidth, viewHeight) * 0.0625);
        vec3 bloom = bloom_downsample(colortex9, uv, texel_size);
        bloom_downscale = vec4(bloom, 1.0);
    }
#endif
