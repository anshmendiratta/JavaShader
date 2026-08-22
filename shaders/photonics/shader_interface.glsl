#if !defined INCLUDE_PHOTONICS_INTERFACE
    #define INCLUDE_PHOTONICS_INTERFACE

    #include "/include/ids.glsl"
    #include "/include/uniforms.glsl"

    #include "/include/water/waves.glsl"

    #include "/include/utility/coordinates.glsl"

    #include "/include/post/taa.glsl"

    #include "/include/pbr/textures.glsl"
    #include "/include/pbr/hcm.glsl"
    #include "/include/pbr/material.glsl"

    vec3 sun_direction = light_dir;
    vec3 indirect_light_color = skyColor;

    vec3 load_world_position() {
        vec2 screen_uv = gl_FragCoord.xy / windowDimensions;
        vec3 frag_pos_screen = vec3(screen_uv, texture(depthtex0, screen_uv).x);
        vec3 frag_pos_view = screen_to_view(frag_pos_screen);
        return view_to_world(frag_pos_view);
    }

    void load_fragment_variables(out vec3 albedo, out vec3 world_pos, out vec3 geometry_normal, out vec3 texture_normal) {
        vec2 screen_uv = gl_FragCoord.xy / windowDimensions;
        // vec3 frag_pos_screen = vec3(v.uv, texture(depthtex0, v.uv).x);

        geometry_normal = texture(colortex3, screen_uv).xyz * 2. - 1.; // vert normal

        const mat3 TBN = get_tbn_matrix(mat3(gbufferModelView) * geometry_normal);
        Material m;
        init_material_raw_read(m, screen_uv, TBN);

        texture_normal = m.normal;
        albedo = m.albedo;
        world_pos = load_world_position() - 0.01 * geometry_normal;
    }

    vec2 get_taa_jitter() {
        #if TAA == 1
            return taa_jitter;
        #else
            return vec2(0.);
        #endif
    }

    bool is_in_world() {
        return texelFetch(depthtex0, ivec2(gl_FragCoord.xy), 0).x <= 0.99999f;
    }
#endif