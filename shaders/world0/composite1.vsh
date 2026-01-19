#version 330 compatibility

// ----------
// Lighting.
// ----------

uniform sampler2D colortex4;

out vec2 texcoord;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
