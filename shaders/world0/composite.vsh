#version 330 compatibility

// ----------
// SSAO.
// ----------

uniform sampler2D colortex4;
uniform sampler2D colortex15;

out vec2 texcoord;

void main() {
    gl_Position = ftransform();
    #ifdef POM
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    texcoord = texture(colortex15, texcoord).xy;
    #else
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    #endif
}
