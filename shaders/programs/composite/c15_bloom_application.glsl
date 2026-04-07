#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 color;

    #include "/include/settings.glsl"

    #include "/include/uniforms.glsl"

    void main() {
        vec4 base_color = texture(colortex0, uv);
        vec4 bloom_color = texture(colortex6, uv);

        color.a = base_color.a;
        color.rgb = mix(base_color.rgb, bloom_color.rgb, BLOOM_INTENSITY);
    }
#endif
