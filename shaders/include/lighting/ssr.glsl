#if !defined INCLUDE_SSR
    #define INCLUDE_SSR

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/ids.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/pbr/material.glsl"

    #include "/include/utility/space_conversions.glsl"
    #include "/include/utility/random.glsl"

    vec2 raymarch_ssr(Material material, in vec2 uv, in vec3 frag_position_view, in vec3 reflected_ray_view /* _space */ ) {
        if (material.block_id != ID_WATER) return uv;
        // if (length(material.f0) <= length(vec3(0.5)) && material.block_id != ID_WATER && material.roughness >= 0.3) return uv;

        vec3 raymarched_position_view = frag_position_view;
        vec3 raymarched_position_screen = view_to_screen(raymarched_position_view);
        vec3 ray_step_view = reflected_ray_view / SSR_STEPS;

        for (uint march_step = 0; march_step < SSR_STEPS; march_step += 1) {
            if (raymarched_position_screen.z >= texture(depthtex0, raymarched_position_screen.xy).r) return raymarched_position_screen.xy;

            raymarched_position_view += ray_step_view;
            raymarched_position_screen = view_to_screen(raymarched_position_view);

            if (uv_out_of_bounds(raymarched_position_screen.xy)) return view_to_screen(raymarched_position_view - ray_step_view).xy;
        }

        // if (abs(raymarched_position_screen.z - texture(depthtex0, raymarched_position_screen.xy).r) > 1e-2) return uv;

        return raymarched_position_screen.xy;
    }
#endif
