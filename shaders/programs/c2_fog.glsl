#include "/common/shadow_distort.glsl"
#include "/common/utility.glsl"
#include "/common/constants.glsl"

uniform sampler2D depthtex0, colortex0;

uniform mat4 gbufferProjectionInverse;
uniform float far; // Render distance in blocks.

in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    // Assign color (to "main screen gbuffer").
    color = texture(colortex0, uv);

    // Do sky pixel check.
    float depth = texture(depthtex0, uv).r;
    if (depth == 1.0) {
        return;
    }

    // Compute shadow map screen position to use to sample from the shadow map.
    vec3 fragment_ndc_position = vec3(uv.xy, depth) * 2.0 - 1.0;
    vec3 fragment_ndc_model_view_position = project_and_divide(gbufferProjectionInverse, fragment_ndc_position);

    // Fog.
    float object_distance_as_render_distance_proportion = length(fragment_ndc_model_view_position) / far;
    float fog_factor = exp(-FOG_DENSITY * (1 - object_distance_as_render_distance_proportion));
    // TODO: Figure out why I _don't_ need gamma correction for the FOG_COLOR to match the SKY_COLOR.
    color.rgb = mix(color.rgb, /* Undo gamma correction */ FOG_COLOR, clamp(fog_factor, 0.0, 1.0));
}
