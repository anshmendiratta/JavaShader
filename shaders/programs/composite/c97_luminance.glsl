struct Interface {
    vec2 uv;
};

#ifdef STAGE_VERTEX
    #include "/include/post/taa.glsl"

    out Interface v;

    void main() {
        gl_Position = ftransform();

        v.uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    #include "/include/uniforms.glsl"

    #include "/include/color/grading.glsl"

    in Interface v;

    /* RENDERTARGETS: 0 */

    layout(location = 0) out vec4 color;

    void main() {
        color = texture(colortex0, v.uv);
        // color.a = rgb_to_luminance(color.rgb);
        // color.a = 0.;
    }
#endif