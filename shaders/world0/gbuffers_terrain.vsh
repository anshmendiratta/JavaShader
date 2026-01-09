#version 330 compatibility

#include "/lib/noise.glsl"

uniform mat4 gbufferProjection;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec2 mc_midTexCoord;
uniform int worldTime;

in vec2 mc_Entity;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal; 

// Waving.
const float FOLIAGE_WAVE_SPEED = 0.05;
const float FOLIAGE_WAVE_AMPLITUDE = 0.05;


void main() {
	gl_Position = ftransform();

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0);
	normal = gl_NormalMatrix * gl_Normal;
	if (mc_Entity.x == 10000.0) {
        normal = gl_NormalMatrix * vec3(0.0, 1.0, 0.0);
    }
	normal = mat3(gbufferModelViewInverse) * normal;
	glcolor = gl_Color;

	// Waving: rooted foliage.
	if (mc_Entity.x == 10000.0) {
        // normal = vec3(0.0, 1.0, 0.0);

		// TOOD: Figure out why this check doesn't just move one half of the block.
		if (texcoord.y < mc_midTexCoord.y) { 
			float texture_distance = length(mc_midTexCoord - texcoord);
			vec3 v_view_space_position = (gbufferProjectionInverse * ftransform()).xyz;
			vec3 v_player_space_position = (gbufferModelViewInverse * vec4(v_view_space_position, 1.0)).xyz;
			vec3 v_world_position = v_player_space_position + cameraPosition;
			// Apply wave.
			v_world_position.x += sin(FOLIAGE_WAVE_SPEED * worldTime + texture_distance) * FOLIAGE_WAVE_AMPLITUDE;
			v_world_position.z -= sin(1.5 * FOLIAGE_WAVE_SPEED * worldTime + texture_distance) * FOLIAGE_WAVE_AMPLITUDE;
			// Undo 
			vec3 v_player_space_wave_position = v_world_position - cameraPosition; 
			vec3 v_view_space_wave_position = (gbufferModelView * vec4(v_player_space_wave_position, 1.0)).xyz;
			vec4 v_clip_space_wave_position = gbufferProjection * vec4(v_view_space_wave_position, 1.0);
			gl_Position = v_clip_space_wave_position;
		}
	}
}
