#ifdef STAGE_VERTEX
    out vec2 uv;
    out vec4 glcolor;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        glcolor = gl_Color;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;
    in vec4 glcolor;

    /* RENDERTARGETS: 0,31 */
    layout(location = 0) out vec4 color;
    layout(location = 1) out uint frag_is_hand;

    #include "/include/uniforms.glsl"

    void main() {
        color = texture(gtexture, uv) * glcolor;
        frag_is_hand = 1; // buffer clear is 0 so value is 1 only for hand fragments

        if (color.a < alphaTestRef) discard;
    }
#endif
