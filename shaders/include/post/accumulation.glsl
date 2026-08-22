#if !defined INCLUDE_ACCUMULATION
    #define INCLUDE_ACCUMULATION

    // ------------------------------
    //     Accumulation utilities
    // ------------------------------

    vec3 reproject_uv(in vec2 current_uv, bool use_previous_depth) {
        vec3 current_frag_screen = vec3(current_uv, texture(depthtex0, current_uv).x);
        vec3 current_frag_world = view_to_world(screen_to_view(current_frag_screen));
        vec3 previous_frag_view = (gbufferPreviousModelView * vec4(world_to_feet(current_frag_world), 1.)).xyz;
        vec3 previous_frag_screen = _project_and_divide(gbufferPreviousProjection, previous_frag_view) * 0.5 + 0.5;
        previous_frag_screen.z = use_previous_depth ?
            texture(colortex22, previous_frag_screen.xy).x :
            texture(depthtex0, previous_frag_screen.xy).x;

        return previous_frag_screen;
    }

    void color_clamp(in sampler2D tex, in const vec2 uv, in const vec3 current_frame, inout vec3 previous_frame) {
        vec3 min_value = vec3(-1e3);
        vec3 max_value = vec3(1e3);
        const float SEARCH_RADIUS = 2.;

        for (float x = -SEARCH_RADIUS; x < SEARCH_RADIUS; x += 1) {
            for (float y = -SEARCH_RADIUS; y < SEARCH_RADIUS; y += 1) {
                vec2 sample_uv = uv + vec2(x, y) / windowDimensions;
                vec3 sample_value = texture(tex, sample_uv).rgb;

                min_value = min(min_value, current_frame);
                max_value = max(max_value, current_frame);
            }
        }

        previous_frame = clamp(min_value, max_value, previous_frame);
    }

    void color_clamp(in sampler2D tex, in const vec2 uv, in const float current_frame, inout float previous_frame) {
        float min_value = -1e3;
        float max_value = 1e3;
        const float SEARCH_RADIUS = 2.;

        for (float x = -SEARCH_RADIUS; x < SEARCH_RADIUS; x += 1) {
            for (float y = -SEARCH_RADIUS; y < SEARCH_RADIUS; y += 1) {
                vec2 sample_uv = uv + vec2(x, y) / windowDimensions;
                float sample_value = texture(tex, sample_uv).x;

                min_value = min(min_value, current_frame);
                max_value = max(max_value, current_frame);
            }
        }

        previous_frame = clamp(min_value, max_value, previous_frame);
    }

    void depth_reject(in const vec3 uv, in const vec3 reprojected_uv, inout float acc_blend) {
        if (abs(uv.z - reprojected_uv.z) > 1e-3) acc_blend = 0.;
        if (abs(uv.z - reprojected_uv.z) > 1e-3) acc_blend = 0.;
    }

    // bad motion vector "substitute"
    void reduce_movement_blend(inout float acc_blend) {
        acc_blend /= mix(1., 8., tanh(10. * distance(previousCameraPosition, cameraPosition)));
    }
#endif
