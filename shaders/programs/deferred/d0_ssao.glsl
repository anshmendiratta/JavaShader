#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();
        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 4 */
    layout(location = 0) out float occlusion_factor;

    #include "/include/uniforms.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/noise.glsl"
    #include "/include/utility/depth_conversion.glsl"
    #include "/include/utility/space_conversions.glsl"
    #include "/include/utility/dither.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/textures.glsl"

    void main() {
        float depth = texture(depthtex0, uv).x;
        // if (depth == 1. || frag_is_hand(depth)) {
        //     // occlusion_factor = 1.0;
        //     fix_hand_depth(depth);
        //     // return;
        // }

        Material material;
        init_material_unpacked_colortex_read(material);

        vec2 screen_uv = uv;
        vec3 fragment_position_screen = vec3(screen_uv, depth);
        vec3 fragment_position_view = screen_to_view(fragment_position_screen);
        // vec3 normal_world = texture(colortex3, uv).xyz * 2. - 1.;
        vec3 normal_world = material.normal;
        vec3 normal_view = normalize(mat3(gbufferModelView) * normal_world);

        mat3 TBN_matrix = get_tbn_matrix(normal_view);
        // Obtain depth samples for occlusion check.
        occlusion_factor = 0.;
        for (uint idx = 0; idx < SSAO_SAMPLES; idx += 1) {
            float scale = float(idx + 1) / float(SSAO_SAMPLES);
            float epsilon_zero = compute_dither(screen_uv);
            float phi = 2.0 * PI * epsilon_zero;
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

            float is_occluded = float(sample_position_screen.z >= sample_object_depth);
            float close_in_depth = smoothstep01(SSAO_RADIUS / abs(fragment_position_screen.z - sample_object_depth));

            occlusion_factor += is_occluded * close_in_depth;
        }

        occlusion_factor = 1. - clamp01(AO_STRENGTH * occlusion_factor / SSAO_SAMPLES);
    }
#endif
