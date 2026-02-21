in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

#include "/include/uniforms.glsl"
#include "/include/color/conversions.glsl"

void main() {
    color = texture(colortex0, uv);
    color.rgb += texture(colortex6, uv).rgb;
}
