#version 330 compatibility

uniform sampler2D gtexture /* texture atlas */ , depthtex0, shadowtex0, shadowtex1, shadowcolor0;

uniform mat4 gbufferModelViewInverse, gbufferProjectionInverse, shadowModelView, shadowProjection;
uniform float viewWidth, viewHeight;

in vec4 glcolor;
in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    float depth = texture(depthtex0, uv).r;
    color = texture(gtexture, uv) * glcolor;
}
