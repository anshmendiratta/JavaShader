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
    layout(location = 0) out vec4 blurred_light;

    #include "/lib/settings.glsl"

    #include "/include/uniforms.glsl"

    #include "/include/utility/vogel_disk_blur.glsl"
    #include "/include/utility/math_fp.glsl"

    #define BLOOM_BLUR_SAMPLE_COUNT 16 // Hard-code value as the bloom will be fine-tuned.

    void main() {
        vec4 final_out = vec4(0.0);

        for (int idx = 0; idx < BLOOM_BLUR_SAMPLE_COUNT; idx += 1) {
            vec2 sample_uv = BLOOM_RADIUS * compute_vogel_disk_sample_uv(idx, BLOOM_BLUR_SAMPLE_COUNT); // multplication by BLOOM_RADIUS is mostly arbitary and seems to produce sensible results
            final_out += sample_colortex(colortex0, uv, sample_uv);
        }

        blurred_light = final_out / BLOOM_BLUR_SAMPLE_COUNT;
    }
#endif
