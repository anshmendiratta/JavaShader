#version 330 compatibility

#include "/lib/shadow_distort.glsl"

uniform sampler2D depthtex0; // For sky pixel check.
uniform sampler2D shadowtex0; // For shadows.
uniform sampler2D colortex0;
uniform sampler2D colortex1; // Lightmap.
uniform sampler2D colortex2; // Encoded normals.

uniform vec3 shadowLightPosition; // Sun/moon position.
uniform mat4 gbufferModelViewInverse; // To convert from view to world/player space.
// For coordinate space conversions to determine the shadowmap sample point.
uniform mat4 gbufferProjectionInverse; 
uniform mat4 shadowModelView; 
uniform mat4 shadowProjection; 

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

// Tell Iris to up the precision of colortex0 so it can store colors properly in the linear color space. If not for this, we would lose some colors since the buffer is meant to store gamma corrected colors. Of course, increasing the precision increases the mem footprint of the buffer, hence increasing the VRAM usage.
// Further, note that this is a multi-line comment so Iris reads it. If it were a single line `//` comment, the below would not work.
/*
const int colortex0format = RGB16;
*/

const vec3 blocklight_color = vec3(1.0, 0.5, 0.08);
const vec3 skylight_color = vec3(0.05, 0.15, 0.3);
const vec3 sunlight_color = vec3(1.0);
const vec3 ambient_color = vec3(0.1);

vec3 project_and_divide(mat4 projection_matrix, vec3 position) {
    vec4 homogenous_position = projection_matrix * vec4(position, 1.0);
    return homogenous_position.xyz / homogenous_position.w; // Perspective division.
}

void main() {
    // Get information from gbuffers.
    vec2 lightmap = texture(colortex1, texcoord).xy;
    vec3 encoded_normal = texture(colortex2, texcoord).xyz;
    vec3 normal = normalize(encoded_normal * 2.0 - 1.0); // Undo encoding from before writing to normal buffer -- convert from [0, 1.0] to [-1.0, 1.0].

    // Assign color (to "main screen gbuffer").
    color = texture(colortex0, texcoord);

    // Do sky pixel check.
    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        return;
    }
    // Compute shadow map screen position to use to sample from the shadow map.
    vec3 ndc_position = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 ndc_model_view_position = project_and_divide(gbufferProjectionInverse, ndc_position);
    vec3 world_space_position = (gbufferModelViewInverse * vec4(ndc_model_view_position, 1.0)).xyz;
    vec3 shadow_space_model_view_position = (shadowModelView * vec4(world_space_position, 1.0)).xyz;
    vec4 shadow_space_clip_position = shadowProjection * vec4(shadow_space_model_view_position, 1.0);
    const float SHADOW_BIAS = 0.01;
    shadow_space_clip_position.z -= SHADOW_BIAS; // Mitigate shadow acne.
    shadow_space_clip_position.xyz = distort_shadow_clip_space_position(shadow_space_clip_position.xyz);
    vec3 shadow_space_ndc_position = shadow_space_clip_position.xyz / shadow_space_clip_position.w;
    vec3 shadow_screen_position = shadow_space_ndc_position * 0.5 + 0.5; // Conversion from [-1.0, 1.0] to OpenGL's [0.0, 1.0].
    float shadow = step(shadow_screen_position.z, texture(shadowtex0, shadow_screen_position.xy).r);

    // Sun/moon light source.
    vec3 light_vector = normalize(shadowLightPosition);
    vec3 light_vector_in_world_space = mat3(gbufferModelViewInverse) * light_vector;
    float normal_aligned_with_light_vector = dot(normal, light_vector_in_world_space);

    vec3 blocklight = lightmap.r * blocklight_color; // x is blocklight
    vec3 skylight = lightmap.g * skylight_color; // y is skylight
    vec3 sunlight = clamp(normal_aligned_with_light_vector, 0.0, 1.0) * shadow * sunlight_color; // Multiply by the skylight from the light map since if an object is hidden from the sky, the object is also hidden from the sun.
    vec3 ambient = ambient_color;

    color.rgb *= blocklight + skylight + sunlight + ambient;
    color.rgb = pow(color.rgb, vec3(2.2)); // Undo gamma correction.
}
