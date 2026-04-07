#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 9 */
    layout(location = 0) out vec4 bloom_upscale;

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/post/bloom.glsl"

    void main() {
        // First upscale: upsample colortex10 (1/32) -> colortex9 (1/16)
        vec2 texel_size = 1.0 / (vec2(viewWidth, viewHeight) * 0.0625);
        vec3 bloom = bloom_upsample(colortex10, uv, texel_size, 2.0);
        bloom_upscale = vec4(bloom, 1.0);
    }
#endif
