#version 330 compatibility

// ----------
// Fog.
// ----------

#include "/common/shadow_distort.glsl"
#include "/common/utility.glsl"
#include "/common/constants.glsl"

#define FOG_DENSITY 10.0

// Textures.
uniform sampler2D depthtex0; // For sky pixel check.
uniform sampler2D colortex0;

// Other uniforms.
// For coordinate space conversions to determine the shadowmap sample point.
uniform mat4 gbufferProjectionInverse;
uniform float far; // Render distance in blocks.
// uniform vec3 fogColor;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    // Assign color (to "main screen gbuffer").
    color = texture(colortex0, texcoord);

    // Do sky pixel check.
    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        return;
    }

    // Compute shadow map screen position to use to sample from the shadow map.
    vec3 fragment_ndc_position = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 fragment_ndc_model_view_position = project_and_divide(gbufferProjectionInverse, fragment_ndc_position);

    // Fog.
    float object_distance_as_render_distance_proportion = length(fragment_ndc_model_view_position) / far;
    float fog_factor = exp(-FOG_DENSITY * (1 - object_distance_as_render_distance_proportion));
    // TODO: Figure out why I _don't_ need gamma correction for the FOG_COLOR to match the SKY_COLOR.
    color.rgb = mix(color.rgb, /* Undo gamma correction */ FOG_COLOR, clamp(fog_factor, 0.0, 1.0));
}
