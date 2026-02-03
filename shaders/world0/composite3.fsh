#version 330 compatibility

// ----------
// Bloom Generation.
// ----------

// Textures.
uniform sampler2D colortex0;
uniform sampler2D colortex5; // Bloom.

uniform int viewWidth;
uniform int viewHeight;

/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 blurred_light;

in vec2 uv;

#include "/common/utility.glsl"
#include "/common/noise.glsl"
#include "/common/math.glsl"

#define sample_color(offset_x, offset_y) texture(colortex0, vec2(uv.x + offset_x, uv.y + offset_y))

// TODO: Bloom colortex is completely black.
void main() {
    vec4 final_out = vec4(0.0);

    // 3x3 Gaussian blur.
    mat3 kernel = mat3(
            1.0 / 16.0, 1.0 / 8.0, 1.0 / 16.0,
            1.0 / 8.0, 1.0 / 4.0, 1.0 / 8.0,
            1.0 / 16.0, 1.0 / 8.0, 1.0 / 16.0
        );

    // Red.
    for (float texel_x = 1.0 / viewWidth; texel_x < 1.0 - 1.0 / viewWidth; texel_x += 1.0 / viewWidth) {
        for (float texel_y = 1.0 / viewHeight; texel_y < 1.0 - 1.0 / viewHeight; texel_y += 1.0 / viewHeight) {
            mat3 pixel_grid_3x3 = mat3(
                    sample_color(texel_x - 1, texel_y + 1).r, sample_color(texel_x, texel_y + 1).r, sample_color(texel_x + 1, texel_y - 1).r,
                    sample_color(texel_x - 1, texel_y).r, sample_color(texel_x, texel_y).r, sample_color(texel_x + 1, texel_y).r,
                    sample_color(texel_x - 1, texel_y - 1).r, sample_color(texel_x, texel_y - 1).r, sample_color(texel_x + 1, texel_y + 1).r
                );
            mat3 multiplied = matrixCompMult(kernel, pixel_grid_3x3);
            float element_sum = dot(multiplied[0] + multiplied[1] + multiplied[2], vec3(1.0));
            final_out.r = element_sum;
        }
    }
    // Green.
    for (float texel_x = 1.0 / viewWidth; texel_x < 1.0 - 1.0 / viewWidth; texel_x += 1.0 / viewWidth) {
        for (float texel_y = 1.0 / viewHeight; texel_y < 1.0 - 1.0 / viewHeight; texel_y += 1.0 / viewHeight) {
            mat3 pixel_grid_3x3 = mat3(
                    sample_color(texel_x - 1, texel_y + 1).g, sample_color(texel_x, texel_y + 1).g, sample_color(texel_x + 1, texel_y - 1).g,
                    sample_color(texel_x - 1, texel_y).g, sample_color(texel_x, texel_y).g, sample_color(texel_x + 1, texel_y).g,
                    sample_color(texel_x - 1, texel_y - 1).g, sample_color(texel_x, texel_y - 1).g, sample_color(texel_x + 1, texel_y + 1).g
                );
            mat3 multiplied = matrixCompMult(kernel, pixel_grid_3x3);
            float element_sum = dot(multiplied[0] + multiplied[1] + multiplied[2], vec3(1.0));
            final_out.g = element_sum;
        }
    }
    // Blue.
    for (float texel_x = 1.0 / viewWidth; texel_x < 1.0 - 1.0 / viewWidth; texel_x += 1.0 / viewWidth) {
        for (float texel_y = 1.0 / viewHeight; texel_y < 1.0 - 1.0 / viewHeight; texel_y += 1.0 / viewHeight) {
            mat3 pixel_grid_3x3 = mat3(
                    sample_color(texel_x - 1, texel_y + 1).b, sample_color(texel_x, texel_y + 1).b, sample_color(texel_x + 1, texel_y - 1).b,
                    sample_color(texel_x - 1, texel_y).b, sample_color(texel_x, texel_y).b, sample_color(texel_x + 1, texel_y).b,
                    sample_color(texel_x - 1, texel_y - 1).b, sample_color(texel_x, texel_y - 1).b, sample_color(texel_x + 1, texel_y + 1).b
                );
            mat3 multiplied = matrixCompMult(kernel, pixel_grid_3x3);
            float element_sum = dot(multiplied[0] + multiplied[1] + multiplied[2], vec3(1.0));
            final_out.b = element_sum;
        }
    }
    // Alpha.
    for (float texel_x = 1.0 / viewWidth; texel_x < 1.0 - 1.0 / viewWidth; texel_x += 1.0 / viewWidth) {
        for (float texel_y = 1.0 / viewHeight; texel_y < 1.0 - 1.0 / viewHeight; texel_y += 1.0 / viewHeight) {
            mat3 pixel_grid_3x3 = mat3(
                    sample_color(texel_x - 1, texel_y + 1).a, sample_color(texel_x, texel_y + 1).a, sample_color(texel_x + 1, texel_y - 1).a,
                    sample_color(texel_x - 1, texel_y).a, sample_color(texel_x, texel_y).a, sample_color(texel_x + 1, texel_y).a,
                    sample_color(texel_x - 1, texel_y - 1).a, sample_color(texel_x, texel_y - 1).a, sample_color(texel_x + 1, texel_y + 1).a
                );
            mat3 multiplied = matrixCompMult(kernel, pixel_grid_3x3);
            float element_sum = dot(multiplied[0] + multiplied[1] + multiplied[2], vec3(1.0));
            final_out.a = element_sum;
        }
    }

    blurred_light = final_out;
}