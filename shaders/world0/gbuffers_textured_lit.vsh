#version 430 compatibility

// out vec4 glcolor;
// out vec2 uv;

// void main() {
//     gl_Position = ftransform();
//     uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
//     glcolor = gl_Color;
// }

#define STAGE_VERTEX
#include "/programs/gbuffers/all_solid.glsl"
