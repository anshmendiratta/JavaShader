#version 330 compatibility

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;
uniform vec3 sunPosition;
# Reflection.
uniform int renderStage;

out vec4 glcolor;
out vec2 texcoord;

// const float SUN_SCALAR = 1.5;
// const float MOON_SCALAR = 0.1;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    if (renderStage == MC_RENDER_STAGE_SUN) {
        gl_Position = ftransform();
    }
    // if (renderStage == MC_RENDER_STAGE_MOON) {
    // 	gl_Position = ftransform();
    // }
    glcolor = gl_Color;
}
