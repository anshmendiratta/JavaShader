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

    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 color;

    #include "/include/uniforms.glsl"

    void main() {
        color = texture(gtexture, uv) * glcolor;
        // color = vec3(1.);

        if (color.a < alphaTestRef) discard;
    }
#endif
