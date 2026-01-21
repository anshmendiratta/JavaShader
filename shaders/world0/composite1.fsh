#version 330 compatibility

// ----------
// Lighting.
// ----------

// Textures.
uniform sampler2D depthtex0; // For sky pixel check.
uniform sampler2D lightmap; // For sky pixel check.
uniform sampler2D shadowtex0; // For shadows cast by all objects.
uniform sampler2D shadowtex1; // For shadows cast *only* by opaque objects.
uniform sampler2D shadowcolor0; // Information about the color, including transparency, of things that cast a shadow.
uniform sampler2D colortex0;
uniform sampler2D colortex1; // Lightmap coordinates.
uniform sampler2D colortex2; // Encoded normals.
uniform sampler2D colortex3; // Encoded speculars.
uniform sampler2D colortex4; // SSAO value.

// Other uniforms.
uniform vec3 cameraPosition; // In world space.
uniform vec3 shadowLightPosition; // Sun/moon position.
uniform mat4 gbufferModelView; // To convert from view to world/player space.
uniform mat4 gbufferModelViewInverse; // To convert from view to world/player space.
// For coordinate space conversions to determine the shadowmap sample point.
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
// For texelFetch in shadowing.
uniform float viewWidth;
uniform float viewHeight;
// Control sunlight intensity.
uniform int worldTime;
// Reflection.
uniform int renderStage;

in vec2 texcoord;
in vec2 lmcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

// Tell Iris to up the precision of colortex0 so it can store colors properly in the linear color space. If not for this, we would lose some colors since the buffer is meant to store gamma corrected colors. Of course, increasing the precision increases the mem footprint of the buffer, hence increasing the VRAM usage.
// Further, note that this is a multi-line comment so Iris reads it. If it were a single line `//` comment, the below would not work.
/*
const int colortex0Format = RGBA16;
*/

#include "/common/utility.glsl"
#include "/common/constants.glsl"
#include "/common/noise.glsl"
#include "/common/shadow_distort.glsl"
#include "/common/shadows.glsl"

void main() {
    // Get information from gbuffers.
    vec2 lightmap_coords = texture(colortex1, texcoord).xy;
    vec3 normal_feet_space = texture(colortex2, texcoord).xyz * 2.0 - 1.0;
    vec3 normal_world_space = normal_feet_space;

    #ifdef DEBUG_VIEW
    color.rgb = normal_feet_space;
    return;
    #endif

    color = texture(colortex0, texcoord);

    // Do sky pixel check.
    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        return;
    }

    // Compute shadow map screen position to use to sample from the shadow map.
    vec3 fragment_ndc_space_position = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 fragment_view_space_position = project_and_divide(gbufferProjectionInverse, fragment_ndc_space_position);
    vec3 fragment_feet_space_position = (gbufferModelViewInverse * vec4(fragment_view_space_position, 1.0)).xyz;
    vec3 shadow_view_space_position = (shadowModelView * vec4(fragment_feet_space_position, 1.0)).xyz;
    vec4 shadow_clip_space_position = shadowProjection * vec4(shadow_view_space_position, 1.0);
    vec3 shadow = get_soft_shadow(shadow_clip_space_position);

    // Sun/moon light source.
    vec3 fragment_world_space_position = fragment_feet_space_position + cameraPosition;
    vec3 light_source_world_space_position = (gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz + cameraPosition;
    vec3 light_source_direction_world_space = normalize(light_source_world_space_position - fragment_world_space_position);
    float n_dot_l = clamp(dot(light_source_direction_world_space, normal_world_space), 0.0, 1.0);

    float light_brightness;
    #ifdef SPECULAR_MAPPING
    vec4 specular_data = texture(colortex3, texcoord);
    float perceptual_roughness = specular_data.r;
    float roughness = pow(1.0 - perceptual_roughness, 2.0);
    float smoothness = 1.0 - roughness;

    // TODO: Why does the light direction need a negation?
    vec3 R_hat = reflect(-light_source_direction_world_space, normal_world_space); // Reflected light vector.
    vec3 V_hat = normalize(cameraPosition - fragment_world_space_position); // Point back to camera.
    float r_dot_v = clamp(dot(R_hat, V_hat), 0.0, 1.0);

    float shininess = smoothness * 200.0 + 1.0;
    float specular_light_factor = clamp(smoothness * pow(r_dot_v, shininess), 0.0, 1.0);
    float diffuse_light_factor = clamp(roughness * n_dot_l, 0.0, 1.0);
    light_brightness = diffuse_light_factor + specular_light_factor;
    #else
    light_brightness = n_dot_l;
    #endif
    vec3 sunlight = light_brightness * shadow * lightmap_coords.y * SUNLIGHT_COLOR * mix(SUNLIGHT_COLOR_INTENSITY, MOONLIGHT_COLOR_INTENSITY, pow(sin(worldTime / 24000.), 2.0)); // Multiply by the skylight from the light map since if an object is hidden from the sky, the object is also hidden from the sun.
    vec3 blocklight = lightmap_coords.x * BLOCKLIGHT_COLOR; // x is blocklight
    vec3 skylight = lightmap_coords.y * SKYLIGHT_COLOR; // y is skylight

    // Blur SSAO with a 2x2 box kernel for ambient lighting.
    float ssao_factor;
    vec2 ssao_texel_size = 1.0 / vec2(textureSize(colortex4, 0));
    const int box_kernel_n_half = 4;
    for (int x = -box_kernel_n_half; x < box_kernel_n_half; x++) {
        for (int y = -box_kernel_n_half; y < box_kernel_n_half; y++) {
            vec2 texcoord_offset = vec2(float(x), float(y)) * ssao_texel_size;
            ssao_factor += texture(colortex4, texcoord + texcoord_offset).r;
        }
    }
    ssao_factor /= 4 * box_kernel_n_half * box_kernel_n_half;

    vec3 ambient = AMBIENT_COLOR * ssao_factor;
    color.rgb *= blocklight + skylight + sunlight + ambient;
    // color.rgb = vec3(ssao_factor);

    color.rgb = pow(color.rgb, vec3(2.2)); // Undo gamma correction.
}
