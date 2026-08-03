struct Interface {
    vec2 uv;
};

#ifdef STAGE_VERTEX
    out Interface v;

    #include "/include/post/taa.glsl"

    void main() {
        gl_Position = ftransform();

        v.uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    #include "/include/color/tonemaps/reversible.glsl"

    in Interface v;

    /* RENDERTARGETS: 0 */

    layout(location = 0) out vec4 color;

    void main() {
        color = texture(colortex0, v.uv);
        color = TonemapInvert(color);
    }
#endif
