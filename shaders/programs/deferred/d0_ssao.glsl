#ifdef STAGE_VERTEX
    out vec2 uv;

    #include "/include/post/taa.glsl"

    void main() {
        gl_Position = ftransform();

        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    #include "/include/uniforms.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/noise.glsl"
    #include "/include/utility/depth.glsl"
    #include "/include/utility/coordinates.glsl"
    #include "/include/utility/dither.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/post/taa.glsl"
    #include "/include/post/accumulation.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/textures.glsl"

    in vec2 uv;

    /* RENDERTARGETS: 4,19 */

    layout(location = 0) out float occlusion_factor;
    layout(location = 1) out float occlusion_history;

    void main() {
        vec2 uv = uv - dot(
                    vec2(dFdx(uv).x, dFdy(uv).y),
                    taa_jitter
                ); // unjitter texture sampling
        uv = clamp01(uv);

        float depth = texture(depthtex0, uv).x;

        Material material;
        init_material_unpacked_colortex_read(material, uv);

        vec2 screen_uv = uv;
        vec3 fragment_position_screen = vec3(screen_uv, depth);
        vec3 fragment_position_view = screen_to_view(fragment_position_screen);
        // vec3 normal_world = texture(colortex3, uv).xyz * 2. - 1.;
        vec3 normal_world = material.normal;
        vec3 normal_view = normalize(mat3(gbufferModelView) * normal_world);
        mat3 TBN_matrix = get_tbn_matrix(normal_view);

        occlusion_factor = 0.;

        for (uint idx = 0; idx < SSAO_SAMPLES; idx += 1) {
            float scale = float(idx + 1) / float(SSAO_SAMPLES);
            float epsilon_zero = compute_dither(screen_uv);
            float phi = 2. * PI * epsilon_zero;
            float theta = acos(sqrt(epsilon_zero));
            vec3 sample_offset_normal = scale * vec3(
                        cos(phi) * sin(theta),
                        sin(phi) * sin(theta),
                        abs(cos(theta))
                    );

            vec3 sample_offset_view = TBN_matrix * sample_offset_normal;
            vec3 sample_position_view = fragment_position_view + sample_offset_view;
            vec3 sample_position_screen = view_to_screen(sample_position_view);

            float sample_object_depth = texture(depthtex0, sample_position_screen.xy).r;
            vec3 sample_object_position_screen = vec3(sample_position_screen.xy, sample_object_depth);

            bool is_hand_or_sky = sample_object_depth == 1. || frag_is_hand(sample_object_depth);
            if (is_hand_or_sky) continue;

            float is_occluded = float(sample_position_screen.z >= sample_object_depth);
            float close_in_depth = 1. - smoothstep01(abs(fragment_position_screen.z - sample_object_depth));

            occlusion_factor += is_occluded * close_in_depth;
        }

        // --------------------
        //     Accumulation
        // --------------------

        vec3 reproj_uv = reproject_uv(uv, true);

        float previous_frame = texture(colortex19, reproj_uv.xy).x;
        float current_frame = 1. - clamp01(AO_STRENGTH * occlusion_factor / SSAO_SAMPLES);

        float ao_blend = 0.875;

        color_clamp(colortex21, uv, current_frame, previous_frame);
        depth_reject(fragment_position_screen, reproj_uv, ao_blend);
        reduce_movement_blend(ao_blend);

        occlusion_factor = mix(current_frame, previous_frame, ao_blend);
        occlusion_history = occlusion_factor;
    }
#endif
