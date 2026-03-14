uniform sampler2D colortex4;

in vec2 uv;

/* RENDERTARGETS: 4 */
layout(location = 0) out float ssao_factor;

#include "/lib/settings.glsl"
#include "/include/utility/vogel_disk_blur.glsl"
#include "/include/utility/math_fp.glsl"

#define SSAO_BLUR_SAMPLE_COUNT 16 // Hard-code value as the blur will be fine-tuned.

// 2x2 box kernel.
void main() {
    float final_out = 0.0;

    for (int idx = 0; idx < SSAO_BLUR_SAMPLE_COUNT; idx += 1) {
        vec2 sample_uv = SSAO_RADIUS * compute_vogel_disk_sample_uv(idx, SSAO_BLUR_SAMPLE_COUNT); // multplication by BLOOM_RADIUS is mostly arbitary and seems to produce sensible results
        final_out += sample_colortex(colortex4, uv, sample_uv).r;
    }

    ssao_factor = final_out / SSAO_BLUR_SAMPLE_COUNT;
}
