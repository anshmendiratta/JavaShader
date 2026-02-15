// Textures.
uniform sampler2D colortex0;

uniform int viewWidth, viewHeight;

/* RENDERTARGETS: 0,7 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 blurred_light;

in vec2 uv;

#include "/common/utility.glsl"
#include "/common/noise.glsl"
#include "/common/math.glsl"

// sc = sample_color
#define sc(offset_x, offset_y) texture(colortex0, uv + vec2(offset_x, offset_y) / vec2(textureSize(colortex0, 0)))

// 5x5 Gaussian blur kernel.
// const mat5 kernel = mat5(
//         1.0 / 256.0, 4.0 / 256.0, 6.0 / 256.0, 4.0 / 256.0, 1.0 / 256.0,
//         4.0 / 256.0, 16.0 / 256.0, 24.0 / 256.0, 16.0 / 256.0, 4.0 / 256.0,
//         6.0 / 256.0, 24.0 / 256.0, 36.0 / 256.0, 24.0 / 256.0, 6.0 / 256.0,
//         4.0 / 256.0, 16.0 / 256.0, 24.0 / 256.0, 16.0 / 256.0, 4.0 / 256.0,
//         1.0 / 256.0, 4.0 / 256.0, 6.0 / 256.0, 4.0 / 256.0, 1.0 / 256.0
//     );

// TODO: Bloom colortex is completely black.
void main() {
    color = texture(colortex0, uv);

    vec4 final_out = vec4(0.0);

    final_out.r =
        (1.0 / 256.0) * (sc(-2 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).r + sc(2 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).r + sc(-2 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).r + sc(2 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).r) +
            (4.0 / 256.0) * (sc(-1 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).r + sc(1 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).r + sc(-2 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).r + sc(2 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).r + sc(-2 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).r + sc(2 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).r + sc(-1 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).r + sc(1 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).r) +
            (6.0 / 256.0) * (sc(0, 2 * BLOOM_RADIUS).r + sc(-2 * BLOOM_RADIUS, 0).r + sc(2 * BLOOM_RADIUS, 0).r + sc(0, -2 * BLOOM_RADIUS).r) +
            (16.0 / 256.0) * (sc(-1 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).r + sc(1 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).r + sc(-1 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).r + sc(1 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).r) +
            (24.0 / 256.0) * (sc(-1 * BLOOM_RADIUS, 0).r + sc(1 * BLOOM_RADIUS, 0).r + sc(0, 1 * BLOOM_RADIUS).r + sc(0, -1 * BLOOM_RADIUS).r) +
            (36.0 / 256.0) * sc(0, 0).r;

    final_out.g =
        (1.0 / 256.0) * (sc(-2 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).g + sc(2 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).g + sc(-2 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).g + sc(2 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).g) +
            (4.0 / 256.0) * (sc(-1 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).g + sc(1 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).g + sc(-2 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).g + sc(2 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).g + sc(-2 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).g + sc(2 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).g + sc(-1 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).g + sc(1 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).g) +
            (6.0 / 256.0) * (sc(0, 2 * BLOOM_RADIUS).g + sc(-2 * BLOOM_RADIUS, 0).g + sc(2 * BLOOM_RADIUS, 0).g + sc(0, -2 * BLOOM_RADIUS).g) +
            (16.0 / 256.0) * (sc(-1 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).g + sc(1 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).g + sc(-1 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).g + sc(1 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).g) +
            (24.0 / 256.0) * (sc(-1 * BLOOM_RADIUS, 0).g + sc(1 * BLOOM_RADIUS, 0).g + sc(0, 1 * BLOOM_RADIUS).g + sc(0, -1 * BLOOM_RADIUS).g) +
            (36.0 / 256.0) * sc(0, 0).g;

    final_out.b =
        (1.0 / 256.0) * (sc(-2 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).b + sc(2 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).b + sc(-2 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).b + sc(2 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).b) +
            (4.0 / 256.0) * (sc(-1 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).b + sc(1 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).b + sc(-2 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).b + sc(2 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).b + sc(-2 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).b + sc(2 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).b + sc(-1 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).b + sc(1 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).b) +
            (6.0 / 256.0) * (sc(0, 2 * BLOOM_RADIUS).b + sc(-2 * BLOOM_RADIUS, 0).b + sc(2 * BLOOM_RADIUS, 0).b + sc(0, -2 * BLOOM_RADIUS).b) +
            (16.0 / 256.0) * (sc(-1 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).b + sc(1 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).b + sc(-1 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).b + sc(1 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).b) +
            (24.0 / 256.0) * (sc(-1 * BLOOM_RADIUS, 0).b + sc(1 * BLOOM_RADIUS, 0).b + sc(0, 1 * BLOOM_RADIUS).b + sc(0, -1 * BLOOM_RADIUS).b) +
            (36.0 / 256.0) * sc(0, 0).b;

    final_out.a =
        (1.0 / 256.0) * (sc(-2 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).a + sc(2 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).a + sc(-2 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).a + sc(2 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).a) +
            (4.0 / 256.0) * (sc(-1 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).a + sc(1 * BLOOM_RADIUS, 2 * BLOOM_RADIUS).a + sc(-2 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).a + sc(2 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).a + sc(-2 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).a + sc(2 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).a + sc(-1 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).a + sc(1 * BLOOM_RADIUS, -2 * BLOOM_RADIUS).a) +
            (6.0 / 256.0) * (sc(0, 2 * BLOOM_RADIUS).a + sc(-2 * BLOOM_RADIUS, 0).a + sc(2 * BLOOM_RADIUS, 0).a + sc(0, -2 * BLOOM_RADIUS).a) +
            (16.0 / 256.0) * (sc(-1 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).a + sc(1 * BLOOM_RADIUS, 1 * BLOOM_RADIUS).a + sc(-1 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).a + sc(1 * BLOOM_RADIUS, -1 * BLOOM_RADIUS).a) +
            (24.0 / 256.0) * (sc(-1 * BLOOM_RADIUS, 0).a + sc(1 * BLOOM_RADIUS, 0).a + sc(0, 1 * BLOOM_RADIUS).a + sc(0, -1 * BLOOM_RADIUS).a) +
            (36.0 / 256.0) * sc(0, 0).a;

    blurred_light = final_out;
}
