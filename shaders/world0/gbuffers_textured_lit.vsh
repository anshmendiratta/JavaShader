#version 330 compatibility

// NOTE: Temporary copy from `gbuffers_terrain`.

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal; // Added.

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmcoord = lmcoord / (30.0 / 32.0) - (1.0 / 32.0);
    normal = gl_NormalMatrix * gl_Normal; // In view space.
    normal = mat3(gbufferModelViewInverse) * normal; // In player space.
    glcolor = gl_Color;
}
