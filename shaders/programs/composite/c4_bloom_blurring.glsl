#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 6 */
    layout(location = 0) out vec4 bloom_downscale;

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/post/bloom.glsl"

    void main() {
        // First downscale pass: extract bright pixels and downsample
        vec2 texel_size = 1.0 / vec2(viewWidth, viewHeight);
        vec3 color = bloom_downsample(colortex0, uv, texel_size);

        // Extract only bright pixels above threshold
        float brightness = max(color.r, max(color.g, color.b));
        float threshold = 1.0; // Only pixels brighter than 1.0 will bloom
        vec3 bloom = max(color - threshold, 0.0);

        bloom_downscale = vec4(bloom, 1.0);
    }
#endif
