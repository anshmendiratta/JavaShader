#ifdef STAGE_VERTEX
    out vec2 uv;
    out vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.
    out vec4 glcolor;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        starData = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0)); // Check if white.
        glcolor = gl_Color;
    }
#endif

#ifdef STAGE_FRAGMENT
    // TODO: understand why the sky coloring works how it does.

    in vec4 starData; // rgb = star color, a = flag for weather or not this pixel is a star.
    in vec2 uv;
    in vec4 glcolor;

    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 color;

    #include "/lib/settings.glsl"

    #include "/include/uniforms.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/math_fp.glsl"
    #include "/include/utility/space_conversions.glsl"

    #include "/include/color/conversions.glsl"

    void main() {
        if (starData.a == 1.0) {
            // NOTE: maybe add dropoff near the sun later? or some other kind so that stars near the horizon in daytime appear nicer
            color = vec4(starData.rgb, 1.0);
            return;
        }

        vec2 screen_uv = gl_FragCoord.xy / windowDimensions;
        vec3 fragment_position_ndc_space = vec3(screen_uv, /* depth */ 1.0) * 2.0 - 1.0;
        vec3 fragment_position_view_space = project_and_divide(gbufferProjectionInverse, fragment_position_ndc_space);
        vec3 fragment_position_player_space = mat3(gbufferModelViewInverse) * normalize(fragment_position_view_space);

        float up_dot_frag = clamp01(abs(fragment_position_player_space.y)); // frag_player dot {0, 1, 0}
        float up_factor = up_dot_frag;

        color.rgb = mix(rgb_to_linear(fogColor), rgb_to_linear(skyColor), up_factor);
        color.a = 1.0;
    }
#endif
