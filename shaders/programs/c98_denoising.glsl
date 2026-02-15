uniform sampler2D colortex0;

in vec2 atlas_uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/lib/settings.glsl"
#include "/common/math.glsl"

// Taken from https://www.shadertoy.com/view/3dd3Wr. Original source on https://github.com/BrutPitt/glslSmartDeNoise?tab=readme-ov-file.
vec4 smart_de_noise(vec2 atlas_uv) {
    float radius = round(K_SIGMA * SIGMA);
    float radQ = radius * radius;

    float invSigmaQx2 = 0.5 / SIGMA * SIGMA; // 1.0 / (sigma^2 * 2.0)
    float invSigmaQx2PI = INV_PI * invSigmaQx2; // 1.0 / (sqrt(PI) * SIGMA

    float invThresholdSqx2 = 0.5 / THRESHOLD * THRESHOLD; // 1.0 / (sigma^2 * 2.0)
    float invThresholdSqrt2PI = INV_SQRT_OF_2PI / THRESHOLD; // 1.0 / (sqrt(2*PI) * SIGMA

    vec4 centrPx = texture(colortex0, atlas_uv);

    float zBuff = 0.0;
    vec4 aBuff = vec4(0.0);
    vec2 size = vec2(textureSize(colortex0, 0));

    for (float x = -radius; x <= radius; x++) {
        float pt = sqrt(radQ - x * x); // pt = yRadius: have circular trend
        for (float y = -pt; y <= pt; y++) {
            vec2 d = vec2(x, y);

            float blurFactor = exp(-dot(d, d) * invSigmaQx2) * invSigmaQx2PI;

            vec4 walkPx = texture(colortex0, atlas_uv + d / size);

            vec4 dC = walkPx - centrPx;
            float deltaFactor = exp(-dot(dC, dC) * invThresholdSqx2) * invThresholdSqrt2PI * blurFactor;

            zBuff += deltaFactor;
            aBuff += deltaFactor * walkPx;
        }
    }

    return aBuff / zBuff;
}

void main() {
    color = smart_de_noise(atlas_uv);
}
