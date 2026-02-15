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
#include "/common/turbo_colormap_curve.glsl"

vec4 sample_colortex() {
    vec3 sampled;

    #if DEBUG_VIEW == 1
    sampled = texture(colortex1, uv).rgb;
    #elif DEBUG_VIEW == 2 // Normals.
    sampled = texture(colortex2, uv).rgb * 2.0 - 1.0;
    #elif DEBUG_VIEW == 3
    sampled = texture(colortex3, uv).rgb;
    #elif DEBUG_VIEW == 4 // SSAO.
    sampled = vec3(texture(colortex4, uv).r);
    #elif DEBUG_VIEW == 5
    sampled = texture(colortex5, uv).rgb;
    #elif DEBUG_VIEW == 6 // Bloom.
    sampled = texture(colortex6, uv).rgb;
    #elif DEBUG_VIEW == 7
    sampled = texture(colortex7, uv).rgb;
    #elif DEBUG_VIEW == 8
    sampled = texture(colortex8, uv).rgb;
    #elif DEBUG_VIEW == 9
    sampled = texture(colortex9, uv).rgb;
    #elif DEBUG_VIEW == 10
    sampled = texture(colortex10, uv).rgb;
    #elif DEBUG_VIEW == 11
    sampled = texture(colortex11, uv).rgb;
    #elif DEBUG_VIEW == 12
    sampled = texture(colortex12, uv).rgb;
    #elif DEBUG_VIEW == 13
    sampled = texture(colortex13, uv).rgb;
    #elif DEBUG_VIEW == 14
    sampled = texture(colortex14, uv).rgb;
    #elif DEBUG_VIEW == 15
    sampled = texture(colortex15, uv).rgb;
    #else
    sampled = texture(colortex0, uv).rgb;
    #endif

    return vec4(sampled, 1.0);
}

vec4 sample_shadowtex(int debug_view) {
    vec3 sampled;

    #if DEBUG_VIEW == 1:
    sampled = texture(shadowtex0, uv).rgb;
    #elif DEBUG_VIEW == 1
    sampled = texture(shadowtex1, uv).rgb;
    #endif

    return vec4(sampled, 1.0);
}

#define sample_depthtex vec4(texture(depthtex0, uv).rgb, 1.0)
#define sample_shadowcolor vec4(texture(shadowcolor0, uv).rgb, 1.0)

void main() {
    #if DEBUG_VIEW <= 15
    // -1 - +15.
    color = sample_colortex();
    #elif DEBUG_VIEW <= 16
    // 16.
    color = vec4(interpolate_turbo(sample_depthtex.r), 1.0);
    #elif DEBUG_VIEW <= 18
    // 17-18.
    color = sample_shadowtex(DEBUG_VIEW - 17);
    #elif DEBUG_VIEW <= 19
    // 19.
    color = sample_shadowcolor;
    #endif
}
