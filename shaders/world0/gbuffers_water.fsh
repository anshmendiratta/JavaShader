#version 330 compatibility

uniform sampler2D gtexture;
uniform sampler2D depthtex0; // For sky pixel check.
uniform sampler2D shadowtex0; // For shadows cast by all objects.
uniform sampler2D shadowtex1; // For shadows cast *only* by opaque objects.
uniform sampler2D shadowcolor0; // Information about the color, including transparency, of things that cast a shadow.

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform float viewWidth;
uniform float viewHeight;

in vec4 glcolor;
in vec2 texcoord;
in vec3 water_normal;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec3 encoded_normal;

#include "/common/utility.glsl"
#include "/common/noise.glsl"
#include "/common/shadow_distort.glsl"
#include "/common/shadows.glsl"

void main() {
    float depth = texture(depthtex0, texcoord).r;
    color = texture(gtexture, texcoord) * glcolor;
    encoded_normal = water_normal;
}
