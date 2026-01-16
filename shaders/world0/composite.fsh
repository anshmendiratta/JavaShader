#version 330 compatibility

// Textures.
uniform sampler2D depthtex0; // For sky pixel check.
uniform sampler2D lightmap; // For sky pixel check.
uniform sampler2D shadowtex0; // For shadows cast by all objects.
uniform sampler2D shadowtex1; // For shadows cast *only* by opaque objects.
uniform sampler2D shadowcolor0; // Information about the color, including transparency, of things that cast a shadow.
uniform sampler2D colortex0;
uniform sampler2D colortex1; // Lightmap.
uniform sampler2D colortex2; // Encoded normals.
uniform sampler2D colortex3; // Encoded PBR normals.

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

#include "/lib/settings.glsl"
#include "/common/noise.glsl"
#include "/common/utility.glsl"
#include "/common/constants.glsl"
#include "/common/shadow_distort.glsl"
#include "/common/shadows.glsl"

void main() {
    // Get information from gbuffers.
    vec2 lightmap_coords = texture(colortex1, texcoord).xy;
    vec3 normal_feet_space = texture(colortex2, texcoord).xyz * 2.0 - 1.0;
    // #ifdef LABPBR_ENABLED
    vec3 pbr_normal_feet_space = texture(colortex3, texcoord).xyz * 2.0 - 1.0; // PBR normal.
    // #endif

    #ifdef DEBUG_VIEW
    color.rgb = normal_feet_space;
    #ifdef LABPBR_ENABLED
    color.rgb = pbr_normal_feet_space;
    #endif
    return;
    #endif

    // Assign color (to "main screen gbuffer").
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
    // NOTE: Not sure if I should use world space before shadow conversions here.
    vec3 shadow_view_space_position = (shadowModelView * vec4(fragment_feet_space_position, 1.0)).xyz;
    vec4 shadow_clip_space_position = shadowProjection * vec4(shadow_view_space_position, 1.0);
    vec3 shadow = get_soft_shadow(shadow_clip_space_position);

    // Sun/moon light source.
    vec3 light_vector_view_space = normalize(shadowLightPosition);
    vec3 light_vector_feet_space = mat3(gbufferModelViewInverse) * light_vector_view_space;
    float n_dot_l = dot(light_vector_feet_space,
            #ifdef LABPBR_ENABLED
            pbr_normal_feet_space
            #else
            normal_feet_space
        #endif
        );

    vec3 blocklight = lightmap_coords.x * BLOCKLIGHT_COLOR; // x is blocklight
    vec3 skylight = lightmap_coords.y * SKYLIGHT_COLOR; // y is skylight
    vec3 sunlight = clamp(n_dot_l, 0.0, 1.0) * shadow * lightmap_coords.y * SUNLIGHT_COLOR * mix(SUNLIGHT_COLOR_INTENSITY, MOONLIGHT_COLOR_INTENSITY, pow(sin(24000 * worldTime), 2.0)); // Multiply by the skylight from the light map since if an object is hidden from the sky, the object is also hidden from the sun.
    vec3 ambient = AMBIENT_COLOR;
    color.rgb *= blocklight + skylight + sunlight + ambient;

    color.rgb = pow(color.rgb, vec3(2.2)); // Undo gamma correction.
}
