#version 430 compatibility

in vec4 glcolor;
in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/include/uniforms.glsl"

#include "/include/color/conversions.glsl"

void main() {
    color = texture(gtexture, uv) * glcolor;
    color.rgb = rgb_to_linear(color.rgb);

    if (color.a < alphaTestRef) discard;
}

// #define STAGE_FRAGMENT
// #include "/programs/gbuffers/all_solid.glsl"
