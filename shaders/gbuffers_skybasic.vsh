#version 330 compatibility

#include "/lib/utility.glsl"

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;

out vec2 texcoord; // For coordinate conversions in the fragment shader.
out vec3 fragment_world_space_position; // For coordinate conversions in the fragment shader.

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    vec3 fragment_ndc_position = vec3(texcoord.xy, 1.0) * 2.0 - 1.0;
    vec3 fragment_ndc_model_view_position = project_and_divide(gbufferProjectionInverse, fragment_ndc_position);
    vec3 fragment_feet_player_space_position = (gbufferModelViewInverse * vec4(fragment_ndc_model_view_position, 1.0)).xyz;
    fragment_world_space_position = fragment_feet_player_space_position + cameraPosition;
}
