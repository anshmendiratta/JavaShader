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

in vec2 texcoord;

#include "/common/utility.glsl"
#include "/common/noise.glsl"
#include "/common/math.glsl"

#define sample_color(offset_x, offset_y) texture(colortex0, vec2(texcoord.x + offset_x, texcoord.y + offset_y))

void main() {
    // 3x3 Gaussian blur.
    mat3 kernel = mat3(
            1.0 / 16.0, 1.0 / 8.0, 1.0 / 16.0,
            1.0 / 8.0, 1.0 / 4.0, 1.0 / 8.0,
            1.0 / 16.0, 1.0 / 8.0, 1.0 / 16.0
        );
    for (float texel_x = 0.0; texel_x < 1.0; texel_x += 1.0 / viewWidth) {
        for (float texel_y = 0.0; texel_y < 1.0; texel_y += 1.0 / viewHeight) {
            mat3 pixel_grid_3x3 = mat3(
                    sample_color(texel_x - 1, texel_y - 1), sample_color(texel_x - 1, texel_y), sample_color(texel_x - 1, texel_y + 1),
                    sample_color(texel_x, texel_y - 1), sample_color(texel_x, texel_y), sample_color(texel_x, texel_y + 1),
                    sample_color(texel_x + 1, texel_y - 1), sample_color(texel_x + 1, texel_y), sample_color(texel_x + 1, texel_y + 1)
                );
            mat3 multiplied = matrixCompMult(kernel, pixel_grid_3x3);
            float element_sum = dot(multiplied[0] + multiplied[1] + multiplied[2], vec3(1.0));
            blurred_light = element_sum;
        }
    }
}
