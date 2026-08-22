#version 430 compatibility

in vec2 uv;
in vec4 glcolor;

/* RENDERTARGETS: 0 */

layout(location = 0) out vec4 color;

#include "/include/uniforms.glsl"

#include "/include/color/grading.glsl"

void main() {
    color = texture(gtexture, uv) * glcolor;
    if (color.a < alphaTestRef) discard;

    // color.rgb = brighten_rgb(color.rgb, 1.);
}
