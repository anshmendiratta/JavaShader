#if !defined INCLUDE_TAA
    #define INCLUDE_TAA

    #include "/include/uniforms.glsl"

    #include "/include/utility/space_conversions.glsl"

    // -----------
    //     TAA
    // -----------
    // jitter from shrimple

    vec2 taa_jitter = vec2(
    fract(0.75487766624669276005 * frameCounter + 0.5) - 0.5,
    fract(0.56984029099805326591 * frameCounter + 0.5) - 0.5
    )
    / (windowDimensions);

    mat4 JITTER_OFFSET_MATRIX = mat4(
    1., 0., 0., taa_jitter.x,
    0., 1., 0., taa_jitter.y,
    0., 0., 1., 0.,
    0., 0., 0., 1.
    );

    mat4 JITTER_OFFSET_MATRIX_INV = mat4(
    1., 0., 0., -taa_jitter.x,
    0., 1., 0., -taa_jitter.y,
    0., 0., 1., 0.,
    0., 0., 0., 1.
    );

    vec3 reproject_uv(in vec2 current_uv) {
        vec3 current_frag_screen = vec3(current_uv, texture(depthtex0, current_uv).x);
        vec3 current_frag_world = view_to_world(screen_to_view(current_frag_screen));
        vec3 previous_frag_view = (gbufferPreviousModelView * vec4(world_to_feet(current_frag_world), 1.)).xyz;
        vec3 previous_frag_screen = _project_and_divide(gbufferPreviousProjection, previous_frag_view) * 0.5 + 0.5;
        previous_frag_screen.z = texture(colortex22, previous_frag_screen.xy).x;

        return previous_frag_screen;
    }
#endif
