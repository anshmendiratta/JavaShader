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
    in vec4 starData; // rgb = star color, a = flag for whether or not this pixel is a star.
    in vec2 uv;
    in vec4 glcolor;

    /* RENDERTARGETS: 0 */
    layout(location = 0) out vec4 color;

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/math/convenience.glsl"
    #include "/include/utility/space_conversions.glsl"

    #include "/include/sky/color.glsl"

    void main() {
        if (starData.a == 1.0) {
            // NOTE: maybe add dropoff near the sun later? or some other kind so that stars near the horizon in daytime appear nicer
            color = vec4(starData.rgb, 1.0);
            return;
        }

        vec2 screen_uv = gl_FragCoord.xy / windowDimensions;
        vec3 fragment_position_ndc_space = vec3(screen_uv, /* depth */ 1.0) * 2.0 - 1.0;
        vec3 fragment_position_view_space = ndc_to_view(fragment_position_ndc_space);
        vec3 v = mat3(gbufferModelViewInverse) * normalize(fragment_position_view_space);

        #if PBR_SKY == 1.0
            color.rgb = get_pbr_sky_color(fragment_position_view_space);
            if (v.y < 0.0) {
                v.y *= -1;
                fragment_position_view_space = mat3(gbufferModelView) * v;
                color.rgb = get_pbr_sky_color(fragment_position_view_space);
            }
        #else
            vec3 fragment_vector_world_space = mat3(gbufferModelViewInverse) * normalize(fragment_position_view_space); // treat as vector
            float up_factor = max0(fragment_vector_world_space.y); // frag_player dot {0, 1, 0}
            color.rgb = get_sky_color(skyColor, fogColor, up_factor);
        #endif
    }
#endif
