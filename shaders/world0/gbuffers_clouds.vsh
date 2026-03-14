#version 430 compatibility

out vec2 uv;

void main() {
    gl_Position = vec4(-1.0);
    uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}