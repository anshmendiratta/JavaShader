#ifdef STAGE_VERTEX
    out vec2 uv;

    #include "/include/post/taa.glsl"

    void main() {
        gl_Position = ftransform();

        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 color;

    #include "/include/buffers.glsl"

    #include "/include/uniforms.glsl"

    void main() {
        color = texture(colortex0, uv);
    }
#endif
