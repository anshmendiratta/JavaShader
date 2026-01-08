#version 330 compatibility

#include "/lib/utility.glsl"
#include "/lib/constants.glsl"

// Uniforms.
// For coordinate space conversions.
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
// For sky coloring.
uniform vec3 sunPosition;
uniform vec3 cameraPosition;

in vec2 texcoord;
in vec3 fragment_world_space_position;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;


void main() {
	// Convert coordinate spaces to get to the world space coordinates of the fragment.
	vec3 sun_world_space_position = (gbufferModelViewInverse * vec4(sunPosition, 1.0)).xyz;
	vec3 sun_direction = normalize(sun_world_space_position - cameraPosition);
	vec3 fragment_direction = normalize(fragment_world_space_position - cameraPosition);
	// LERP the two sky colors depending on how far the fragment is the northern most sky fragment.
	float interpolation_factor = clamp(dot(fragment_direction, sun_direction), 0.0, 1.0);
	vec3 INTERPOLATED_SKY_COLOR = mix(SKY_COLOR_START, SKY_COLOR_END, interpolation_factor);
	color = vec4(pow(INTERPOLATED_SKY_COLOR, vec3(2.2)), 1.0); // Undo Gamma correction so this color matches with the FOG_COLOR after the final post-proc. pass redoes this correction.
}
