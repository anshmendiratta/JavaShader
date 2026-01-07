#version 330 compatibility

#include "/lib/shadow_distort.glsl"

out vec2 texcoord;
out vec4 glcolor;

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
	gl_Position = ftransform();
	gl_Position.xyz = distort_shadow_clip_space_position(gl_Position.xyz);
}
