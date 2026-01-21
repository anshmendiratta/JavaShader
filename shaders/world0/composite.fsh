#version 330 compatibility

// ----------
// SSAO.
// ----------

// Textures.
uniform sampler2D depthtex0; // For comparison to determine SSAO factors.
uniform sampler2D colortex0;
uniform sampler2D colortex2; // Encoded normals.
uniform sampler2D colortex4; // SSAO factors.

/*
colortex4Format = R32F;
*/

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform int viewWidth;
uniform int viewHeight;

/* RENDERTARGETS: 4 */
layout(location = 0) out float occlusion_factor;

in vec2 texcoord;

#include "/common/utility.glsl"
#include "/common/noise.glsl"
#include "/common/math.glsl"

vec3 ssao_sampling_kernel[SSAO_SAMPLE_COUNT]; // Vectors in tangent space.
vec3 ssao_noise_vector; // Create less than 1 per fragment to save memory. Use this as a tiling "texture."
vec2 TEXCOORD_NOISE_SCALE = vec2(viewWidth / 4.0, viewHeight / 4.0);

void main() {
    // Sampling kernel of random vector offsets.
    for (int count = 0; count < SSAO_SAMPLE_COUNT; count++) {
        float scale = float(count) / float(SSAO_SAMPLE_COUNT);
        scale = mix(0.0, 1.0, scale * scale); // Quadratic density.
        float epsilon_zero = rand(count * 1.0);
        float epsilon_one = rand(count * 2.0);
        float phi = 2 * PI * epsilon_one;
        float theta = acos(sqrt(epsilon_zero));
        ssao_sampling_kernel[count] = scale * vec3(
                    cos(phi) * sin(theta),
                    sin(phi) * sin(theta),
                    abs(cos(theta))
                );
    }

    // Random rotation vector.
    int count = int(16 * rand(texcoord.x + texcoord.y));
    float epsilon_zero = rand(count * 2.0);
    float epsilon_one = rand(count * 1.0);
    float phi = 2 * PI * epsilon_one;
    float theta = acos(sqrt(epsilon_zero));
    ssao_noise_vector = vec3(
            cos(phi) * sin(theta),
            sin(phi) * sin(theta),
            0.0
        );

    // Construct TBN.
    vec3 fragment_screen_space_position = vec3(texcoord, texture(depthtex0, texcoord).r);
    vec3 fragment_ndc_space_position = fragment_screen_space_position * 2.0 - 1.0;
    vec3 fragment_view_space_position = project_and_divide(gbufferProjectionInverse, fragment_ndc_space_position);
    vec3 normal_feet_space = texture(colortex2, texcoord).xyz * 2.0 - 1.0;
    vec3 normal_view_space = mat3(gbufferModelView) * normal_feet_space;
    vec3 random_vector = ssao_noise_vector;
    vec3 tangent_view_space = normalize(random_vector - normal_view_space * dot(normal_view_space, random_vector));
    vec3 bitangent_view_space = cross(normal_view_space, tangent_view_space);
    mat3 TBN_matrix = mat3(tangent_view_space, bitangent_view_space, normal_view_space); // Tangent space to view space.

    // Obtain depth samples for occlusion check.
    occlusion_factor = 0.0;
    for (int idx = 0; idx < SSAO_SAMPLE_COUNT; idx++) {
        vec3 sample_offset_view_space = TBN_matrix * ssao_sampling_kernel[idx];
        vec3 sample_view_space_position = fragment_view_space_position + sample_offset_view_space * SSAO_RADIUS;
        vec3 sample_screen_space_position = project_and_divide(gbufferProjection, sample_view_space_position) * 0.5 + 0.5;
        float sample_depth = texture(depthtex0, sample_screen_space_position.xy).r;
        float check_range_of_depths = smoothstep(0.0, 1.0, SSAO_RADIUS / abs(fragment_screen_space_position.z - sample_depth)); // For bounding how far away in z an object (that is adjacent in screen space) can be for it to contribute to the AO of our sample fragment.

        // TODO: Why do I check for \leq ?
        occlusion_factor += (sample_depth < (sample_screen_space_position.z + SSAO_BIAS) ? 0.5 : 0.0) * check_range_of_depths;
    }

    // Write occlusion factor.
    occlusion_factor = 1.0 - (occlusion_factor / float(SSAO_SAMPLE_COUNT)); // Subtract from 1.0 so this value can be immediately used for lighting calculations.
}
