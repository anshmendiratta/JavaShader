#version 430 compatibility

#include "/include/post/taa.glsl"

out vec2 uv;

void main() {
    gl_Position = ftransform();
    uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
