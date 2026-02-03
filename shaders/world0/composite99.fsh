#version 330 compatibility

// ----------
// Debug view.
// ----------

// Textures.
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform sampler2D colortex13;
uniform sampler2D colortex14;
uniform sampler2D colortex15;

in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/lib/settings.glsl"

vec4 sample_colortex(int debug_view) {
    vec3 rgb;
    switch (debug_view) {
        case 0:
        rgb = texture(colortex0, uv).rgb;
        break;
        case 1:
        rgb = texture(colortex1, uv).rgb;
        break;
        case 2:
        rgb = texture(colortex2, uv).rgb;
        break;
        case 3:
        rgb = texture(colortex3, uv).rgb;
        break;
        case 4:
        rgb = texture(colortex4, uv).rgb;
        break;
        case 5:
        rgb = texture(colortex5, uv).rgb;
        break;
        case 6:
        rgb = texture(colortex6, uv).rgb;
        break;
        case 7:
        rgb = texture(colortex7, uv).rgb;
        break;
        case 8:
        rgb = texture(colortex8, uv).rgb;
        break;
        case 9:
        rgb = texture(colortex9, uv).rgb;
        break;
        case 10:
        rgb = texture(colortex10, uv).rgb;
        break;
        case 11:
        rgb = texture(colortex11, uv).rgb;
        break;
        case 12:
        rgb = texture(colortex12, uv).rgb;
        break;
        case 13:
        rgb = texture(colortex13, uv).rgb;
        break;
        case 14:
        rgb = texture(colortex14, uv).rgb;
        break;
        case 15:
        rgb = texture(colortex15, uv).rgb;
        break;
    }

    return vec4(rgb, 1.0);
}

vec4 sample_shadowtex(int debug_view) {
    vec3 rgb;
    switch (debug_view) {
        case 17:
        rgb = texture(shadowtex0, uv).rgb;
        break;
        case 18:
        rgb = texture(shadowtex1, uv).rgb;
        break;
    }

    return vec4(rgb, 1.0);
}

#define sample_depthtex vec4(texture(depthtex0, uv).rgb, 1.0)
#define sample_shadowtex vec4(texture(shadowcolor0, uv).rgb, 1.0)

void main() {
    #if DEBUG_VIEW == -1
    // No debugging.
    color = sample_colortex(0);
    #elif DEBUG_VIEW <= 15
    // 0-15.
    color = sample_colortex(DEBUG_VIEW);
    #elif DEBUG_VIEW <= 16
    // 16.
    color = sample_depthtex;
    #elif DEBUG_VIEW <= 18
    // 17-18.
    color = sample_shadowtex(DEBUG_VIEW - 17);
    #elif DEBUG_VIEW <= 19
    // 19.
    color = sample_shadowcolor;
    #endif
}