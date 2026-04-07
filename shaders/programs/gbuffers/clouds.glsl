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

    #include "/include/utility/random.glsl"
    #include "/include/math/convenience.glsl"

    #include "/include/sky/intensity.glsl"

    void main() {
        color = texture(gtexture, uv) * glcolor;

        vec2 screen_uv = gl_FragCoord.xy / windowDimensions;
        vec3 fragment_position_ndc_space = vec3(screen_uv, /* depth */ 1.0) * 2.0 - 1.0;
        vec3 fragment_position_view_space = project_and_divide(gbufferProjectionInverse, fragment_position_ndc_space);
        vec3 fragment_position_player_space = mat3(gbufferModelViewInverse) * normalize(fragment_position_view_space);

        float cosine_to_horizon = abs(fragment_position_player_space.y);
        color.a = mix(0.0, color.a, sqrt(clamp01(cosine_to_horizon)));
        vec3 sun_dir_vector_world_space = mat3(gbufferModelViewInverse) * sunDirVector;
        // FIX: this "volumetric" falloff near the sun/moon does not work
        // float cosine_to_sun = dot(sun_dir_vector_world_space, fragment_position_player_space);
        // color.rgb *= clamp01(1.0 - cosine_to_sun); // simulate some volumetric lighting by lightening the clouds closer to the sun

        gl_FragDepth = 1.0;
    }
#endif