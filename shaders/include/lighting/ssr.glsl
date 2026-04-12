#if !defined INCLUDE_SSR
    #define INCLUDE_SSR

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/ids.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/pbr/material.glsl"

    #include "/include/utility/space_conversions.glsl"
    #include "/include/utility/random.glsl"
    #include "/include/utility/dither.glsl"

    #define BINARY_SEARCH_STEPS 8
    #define BINARY_SEARCH_RAY_DOWNSIZE 0.5

    void _binary_search_intersection(inout vec3 raymarched_position_screen, in vec3 ray_step_screen);

    vec2 raymarch_ssr(in Material material, in vec2 uv, in vec3 frag_position_view, in vec3 reflected_ray_view /* _space */ ) {
        if (material.block_id != ID_WATER) return uv;
        // if (length(material.f0) <= length(vec3(0.5)) && material.block_id != ID_WATER && material.roughness >= 0.3) return uv;

        // rough intersection determination

        float dither = compute_dither(gl_FragCoord.xy);

        vec3 raymarched_position_screen = view_to_screen(frag_position_view);
        vec3 reflected_ray_screen = view_to_screen(frag_position_view + reflected_ray_view) - raymarched_position_screen;
        vec3 ray_step_screen = min_of((sign(reflected_ray_screen) - raymarched_position_screen) / reflected_ray_screen) * reflected_ray_screen * rcp(SSR_STEPS);

        raymarched_position_screen += ray_step_screen; // start position

        const float depth_tolerance = max(abs(ray_step_screen.z) * 3.0, 0.02 / pow2(frag_position_view.z)); // from DrDesten and SixthSurge
        bool hit_object = false;
        for (uint march_step = 0; march_step < SSR_STEPS && !hit_object; raymarched_position_screen += ray_step_screen, march_step += 1) {
            if (uv_out_of_bounds(raymarched_position_screen.xy)) return uv;

            float real_raymarched_depth = texture(depthtex0, raymarched_position_screen.xy).r;
            hit_object = raymarched_position_screen.z > real_raymarched_depth
                    && abs(depth_tolerance - (raymarched_position_screen.z - real_raymarched_depth)) < depth_tolerance; // eliminates reflections where the object normally reflected is too close to actually be the reflected. taken from photon: https://github.com/sixthsurge/photon/blob/7a3ce7134a83edd5f5b4f5c00ece49b16640293d/shaders/include/misc/raytracer.glsl#L74
        }

        if (!hit_object) return uv;

        // focus in on intersection point using binary search
        _binary_search_intersection(raymarched_position_screen, ray_step_screen);

        // vec4.w = how close to the edge of the reflection the frag is
        // float distance_closest_x_border = min(abs(raymarched_position_screen.x), abs(1.0 - raymarched_position_screen.x));
        // float distance_closest_y_border = min(abs(raymarched_position_screen.y), abs(1.0 - raymarched_position_screen.y));
        // float distance_to_closest_corner = (distance_closest_x_border + distance_closest_y_border) * rcp(2.0);

        return raymarched_position_screen.xy;
    }

    void _binary_search_intersection(
    inout vec3 raymarched_position_screen,
    in vec3 ray_step_screen) {
        float real_raymarched_depth = texture(depthtex0, raymarched_position_screen.xy).r;
        float ray_direction = -1.0;

        vec3 last_raymarched_position_outside_geometry;
        for (uint search_step = 0; search_step < BINARY_SEARCH_STEPS; search_step += 1) {
            raymarched_position_screen += ray_direction * ray_step_screen;
            ray_step_screen *= BINARY_SEARCH_RAY_DOWNSIZE;

            real_raymarched_depth = texture(depthtex0, raymarched_position_screen.xy).r;
            ray_direction = sign(real_raymarched_depth - raymarched_position_screen.z);
            if (eq_eps(ray_direction, -1.0, 1e3)) last_raymarched_position_outside_geometry = raymarched_position_screen;
        }

        raymarched_position_screen = last_raymarched_position_outside_geometry;
    }
#endif
