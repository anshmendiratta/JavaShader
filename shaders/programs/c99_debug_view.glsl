in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/lib/settings.glsl"
#include "/include/uniforms.glsl"
#include "/include/color/turbo_colormap_curve.glsl"

vec4 sample_colortex() {
    #if DEBUG_BUFFER == 1
    return texture(colortex1, uv);
    #elif DEBUG_BUFFER == 2 // Normals.
    return texture(colortex2, uv) * 2.0 - 1.0;
    #elif DEBUG_BUFFER == 3
    return texture(colortex3, uv);
    #elif DEBUG_BUFFER == 4 // SSAO.
    return vec4(vec3(texture(colortex4, uv).r), 1.0);
    #elif DEBUG_BUFFER == 5
    return texture(colortex5, uv);
    #elif DEBUG_BUFFER == 6 // Bloom.
    return texture(colortex6, uv);
    #elif DEBUG_BUFFER == 7
    return texture(colortex7, uv);
    #elif DEBUG_BUFFER == 8
    return texture(colortex8, uv);
    #elif DEBUG_BUFFER == 9
    return texture(colortex9, uv);
    #elif DEBUG_BUFFER == 10
    return texture(colortex10, uv);
    #elif DEBUG_BUFFER == 11
    return texture(colortex11, uv);
    #elif DEBUG_BUFFER == 12
    return texture(colortex12, uv);
    #elif DEBUG_BUFFER == 13
    return texture(colortex13, uv);
    #elif DEBUG_BUFFER == 14
    return texture(colortex14, uv);
    #elif DEBUG_BUFFER == 15
    return texture(colortex15, uv);
    #else
    return texture(colortex0, uv);
    #endif
}

vec4 sample_depthtex() {
    float depth = texture(depthtex0, uv).r;
    return vec4(vec3(depth), 1.0);
}

vec4 sample_shadowtex() {
    #if DEBUG_BUFFER == 17
    return texture(shadowtex0, uv);
    #elif DEBUG_BUFFER == 18
    return texture(shadowtex1, uv);
    #else
    return vec4(0.0);
    #endif
}

vec4 sample_shadowcolor() {
    return vec4(texture(shadowcolor0, uv).rgb, 1.0);
}

void main() {
    #if DEBUG_VIEW == 1
    #if DEBUG_BUFFER <= 15
    // -1 - +15.
    color = sample_colortex();
    #elif DEBUG_BUFFER <= 16
    // 16.
    color = vec4(interpolate_turbo(sample_depthtex().r), 1.0);
    #elif DEBUG_BUFFER <= 18
    // 17-18.
    color = sample_shadowtex();
    #elif DEBUG_BUFFER <= 19
    // 19.
    color = sample_shadowcolor();
    #endif
    #else
    color = texture(colortex0, uv);
    #endif
}
