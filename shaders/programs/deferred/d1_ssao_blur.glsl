#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 4 */
    layout(location = 0) out float ssao_factor;

    #include "/lib/settings.glsl"

    #include "/include/uniforms.glsl"

    #include "/include/utility/vogel_disk_blur.glsl"
    #include "/include/utility/math_fp.glsl"
    #include "/include/utility/dither.glsl"

    #define SSAO_BLUR_SAMPLE_COUNT 16 // Hard-code value as the blur will be fine-tuned.

    // TODO: find a way better blur

    void main() {
        float final_out = 0.0;
        vec2 texel_size = 1.0 / textureSize(colortex4, 0);

        for (int idx = 0; idx < SSAO_BLUR_SAMPLE_COUNT; idx += 1) {
            vec2 sample_uv = SSAO_RADIUS * texel_size * compute_vogel_disk_sample_uv(idx, SSAO_BLUR_SAMPLE_COUNT);
            vec2 dither = vec2(compute_dither(sample_uv)) / uv;
            final_out += sample_colortex(colortex4, uv, sample_uv).r;
        }

        ssao_factor = final_out / SSAO_BLUR_SAMPLE_COUNT;
    }
#endif
