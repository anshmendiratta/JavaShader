#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();

        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    in vec2 uv;

    /* RENDERTARGETS: 0,21,22 */

    layout(location = 0) out vec4 color;
    layout(location = 1) out vec4 ssr_history;
    layout(location = 2) out float depth_history;

    #include "/include/uniforms.glsl"
    #include "/include/buffers.glsl"

    #include "/include/shadows/compute.glsl"

    #include "/include/water/waves.glsl"

    #include "/include/color/conversions.glsl"

    #include "/include/post/taa.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/atmosphere.glsl"

    #include "/include/lighting/ssr.glsl"
    #include "/include/lighting/specular.glsl"

    #include "/include/utility/dither.glsl"
    #include "/include/utility/depth_conversion.glsl"
    #include "/include/utility/space_conversions.glsl"

    // TODO: implement a PBR sky with clouds so i can reflect them properly

    void main() {
        vec2 uv = uv - dot(
                    vec2(dFdx(uv).x, dFdy(uv).y),
                    taa_jitter
                ); // unjitter texture sampling
        uv = clamp01(uv);

        color = texture(colortex0, uv);
        float depth = texture(depthtex0, uv).x;

        if (frag_is_hand(depth) || depth == 1. || texture(BUFFER_CLOUDS, uv).x == 1) return; // don't reflect hand or sky

        Material material;
        init_material_unpacked_colortex_read(material, uv);

        vec3 frag_position_screen = vec3(uv, texture(depthtex0, uv).r);
        vec3 frag_position_view = screen_to_view(frag_position_screen);
        vec3 frag_position_world = view_to_world(frag_position_view);

        float dither = compute_dither(gl_FragCoord.xy);
        float phi = 2. * PI * dither;
        float theta = acos(sqrt(dither));
        vec3 random_dir = vec3(
                sin(phi) * sin(theta),
                cos(phi) * sin(theta),
                abs(cos(theta))
            );

        // fake rough reflections.
        // FIX: should not need a conditional since water roughness should be 0.
        if (material.block_id != ID_WATER) {
            mat3 TBN = get_tbn_matrix(material.normal);
            vec3 frag_normal_normal = transpose(TBN) * material.normal; // TBN is orthogonal, so transpose = inverse
            material.normal = TBN * (frag_normal_normal + ROUGH_REFLECTIONS * sqrt(material.roughness) * random_dir);
        }

        vec3 frag_view_vector_view = -normalize(frag_position_view);
        vec3 frag_view_vector_world = mat3(gbufferModelViewInverse) * frag_view_vector_view;
        vec3 frag_normal_view = mat3(gbufferModelView) * material.normal;
        vec3 frag_reflected_ray_view = reflect(-frag_view_vector_view, frag_normal_view); // TODO : why tf does this need a negative . the view vector already points out from the fragment ?

        vec3 fresnel = vec3(1.0, 0.0, 0.0); // debug-able fallback

        if (material.block_id == ID_WATER) {
            fresnel = _fresnel_schlick(material, dot(frag_view_vector_world, material.normal));
        } else {
            vec3 light_source_vector_world = normalize(mat3(gbufferModelViewInverse) * worldLightVector);
            vec3 halfway_vector_world = normalize(light_source_vector_world + frag_view_vector_world);

            fresnel = material.is_metal ?
                vec3(1.0) :
                _fresnel_rescaled_schlick(material, dot(halfway_vector_world, light_source_vector_world));
        }

        float specular_energy = avg_vec(fresnel * (1.0 - pow2(material.roughness))); // claude came up with this shit
        if (specular_energy < SSR_ENERGY_THRESHOLD || material.block_id == ID_WATER) {
            ssr_history = color;
            depth_history = texture(depthtex0, uv).x;
            return;
        }

        vec2 reflected_uv;
        bool hit_ssr_object = raymarch_ssr(material, fresnel, uv, reflected_uv, frag_position_view, frag_reflected_ray_view);
        if (uv_out_of_bounds(reflected_uv.xy))
            reflected_uv = uv;

        vec3 reflected_uv_screen = vec3(reflected_uv, texture(depthtex0, reflected_uv).r);
        vec3 reflected_uv_view = screen_to_view(reflected_uv_screen);
        vec3 reflected_uv_world = mat3(gbufferModelViewInverse) * normalize(reflected_uv_view);

        vec3 reflected_color = texture(colortex0, reflected_uv).rgb;

        // NOTE: reflect sky as fallback
        if (!hit_ssr_object) {
            reflected_color = get_sky_color(skyColor, fogColor, reflected_uv_world.y);
        }

        if (material.is_metal) reflected_color *= material.albedo;

        // --------------------
        //     Accumulation
        // --------------------

        vec3 current_frame = oklab_mix(color.rgb, reflected_color, SSR_VISIBILITY * fresnel);

        #if SSR_ACCUMULATION == 0
            color.rgb = current_frame;
            ssr_history = color;
            depth_history = texture(depthtex0, uv).x;
            return;
        #endif

        // TODO: account for virtual motion...?
        vec3 reproj_uv = reproject_uv(uv);
        reproj_uv.z -= distance(frag_position_screen, reproj_uv); // reproj virtual motion (i.e., account for where the reflected fragment actually is)

        vec3 previous_frame = texture(BUFFER_SSR_ACC, reproj_uv.xy).rgb;

        // color clamping: create a bounding box to clamp the reproj color into

        vec3 min_color = vec3(-1e3);
        vec3 max_color = vec3(1e3);

        const float COLOR_SEARCH_RADIUS = 2.;
        for (float x = -COLOR_SEARCH_RADIUS; x < COLOR_SEARCH_RADIUS; x += 1) {
            for (float y = -COLOR_SEARCH_RADIUS; y < COLOR_SEARCH_RADIUS; y += 1) {
                vec2 sample_uv = uv + vec2(x, y) / windowDimensions;
                vec3 sample_color = texture(colortex0, sample_uv).rgb;

                min_color = min(min_color, current_frame);
                max_color = max(max_color, current_frame);
            }
        }

        previous_frame = clamp(min_color, max_color, previous_frame);

        float ssr_blend = 0.99;

        if (abs(frag_position_screen.z - reproj_uv.z) > 1e-3) ssr_blend = 0.; // depth rejection
        ssr_blend /= mix(1., 8., tanh(10. * distance(previousCameraPosition, cameraPosition))); // bad motion vector substitute

        color.rgb = mix(current_frame, previous_frame, ssr_blend);

        ssr_history = color;
        depth_history = texture(depthtex0, uv).x;
    }
#endif
