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
    #include "/include/post/accumulation.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/atmosphere.glsl"

    #include "/include/lighting/ssr.glsl"
    #include "/include/lighting/specular.glsl"

    #include "/include/utility/intersect.glsl"
    #include "/include/utility/dither.glsl"
    #include "/include/utility/depth.glsl"
    #include "/include/utility/coordinates.glsl"

    void main() {
        vec2 uv = uv - dot(
                    vec2(dFdx(uv).x, dFdy(uv).y),
                    taa_jitter
                ); // unjitter texture sampling
        uv = clamp01(uv);

        depth_history = texture(depthtex0, uv).x;
        color = texture(colortex0, uv);
        float depth = texture(depthtex0, uv).x;

        if (frag_is_hand(depth) || depth == 1. || texture(BUFFER_CLOUDS, uv).x == 1) return; // don't reflect hand or sky

        Material material;
        init_material_unpacked_colortex_read(material, uv);

        vec3 frag_pos_screen = vec3(uv, texture(depthtex0, uv).r);
        vec3 frag_pos_view = screen_to_view(frag_pos_screen);
        vec3 frag_pos_world = view_to_world(frag_pos_view);

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
            material.normal = TBN * (frag_normal_normal + ROUGH_REFLECTIONS * material.roughness * random_dir);
        }

        vec3 frag_view_vector_view = -normalize(frag_pos_view);
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
                vec3(1.) :
                _fresnel_rescaled_schlick(material, dot(light_source_vector_world, halfway_vector_world));
        }

        float specular_energy = avg_vec(fresnel * (1.0 - pow2(material.roughness))); // claude came up with this shit
        if (specular_energy < SSR_ENERGY_THRESHOLD && material.block_id != ID_WATER) {
            ssr_history = color;
            return;
        }

        vec2 reflected_uv;
        bool hit_ssr_object = raymarch_ssr(material, fresnel, uv, reflected_uv, frag_pos_view, frag_reflected_ray_view);
        if (uv_out_of_bounds(reflected_uv.xy))
            reflected_uv = uv;

        vec3 reflected_uv_screen = vec3(reflected_uv, texture(depthtex0, reflected_uv).r);
        vec3 reflected_uv_view = screen_to_view(reflected_uv_screen);
        vec3 reflected_uv_world = mat3(gbufferModelViewInverse) * normalize(reflected_uv_view);

        vec3 reflected_color = texture(colortex0, reflected_uv).rgb;

        // NOTE: reflect sky as fallback
        if (!hit_ssr_object) {
            vec3 frag_reflected_ray_world = mat3(gbufferModelViewInverse) * -frag_reflected_ray_view;
            vec3 sky_dome_intersection = ray_internal_intersect_hemisphere(frag_pos_world, frag_reflected_ray_world, 100.);
            vec3 cloud_plane_intersection = ray_intersect_plane(frag_pos_world, frag_reflected_ray_world, float(cloudHeight));

            vec4 cloud = texture(cloud_map, ivec3(cloud_plane_intersection));
            vec4 sky = texture(skycolor_map, ivec3(sky_dome_intersection));

            if (all(equal(cloud_plane_intersection, vec3(1., 0., 0.)))) {
                reflected_color = sky.rgb;
            } else {
                reflected_color = (sky * cloud).rgb;
            }

            // reflected_color = vec3(ivec3(cloud_plane_intersection));
            // reflected_color = cloud.rgb;
        }

        if (material.is_metal) reflected_color *= material.albedo;

        // --------------------
        //     Accumulation
        // --------------------

        vec3 reproj_uv = reproject_uv(uv, true);
        reproj_uv.z - distance(frag_pos_screen, reproj_uv); // reproj virtual motion (i.e., account for where the reflected fragment actually is)

        vec3 previous_frame = texture(BUFFER_SSR_ACC, reproj_uv.xy).rgb;
        vec3 current_frame = oklab_mix(color.rgb, reflected_color, SSR_VISIBILITY * fresnel);

        #if SSR_ACCUMULATION == 0
            color.rgb = current_frame;
            ssr_history = color;
            return;
        #endif

        float ssr_blend = 0.99;

        color_clamp(colortex21, uv, current_frame, previous_frame);
        depth_reject(frag_pos_screen, reproj_uv, ssr_blend);
        reduce_movement_blend(ssr_blend);

        color.rgb = oklab_mix(current_frame, previous_frame, ssr_blend);
        ssr_history = color;
        depth_history = texture(depthtex0, uv).x;
    }
#endif
