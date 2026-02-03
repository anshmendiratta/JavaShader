#version 330 compatibility

// ----------
// Lighting.
// ----------

uniform sampler2D colortex5;

out vec2 uv;

void main() {
    gl_Position = ftransform();
    uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}