#version 330 compatibility

uniform mat4 gbufferModelView, gbufferModelViewInverse, gbufferProjection, gbufferProjectionInverse;
uniform vec3 cameraPosition, sunPosition;
uniform int renderStage;

out vec4 glcolor;
out vec2 uv;

void main() {
    uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    // if (renderStage == MC_RENDER_STAGE_SUN) {
    gl_Position = ftransform();
    // }
    // if (renderStage == MC_RENDER_STAGE_MOON) {
    // 	gl_Position = ftransform();
    // }
    glcolor = gl_Color;
}
