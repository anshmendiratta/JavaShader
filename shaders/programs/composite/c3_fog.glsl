#ifdef STAGE_VERTEX
    out vec2 uv;

    void main() {
        gl_Position = ftransform();

        uv = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    }
#endif

#ifdef STAGE_FRAGMENT
    #include "/include/settings.glsl"

    #include "/include/uniforms.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/sky/intensity.glsl"

    #include "/include/color/conversions.glsl"

    #include "/include/pbr/material.glsl"
    #include "/include/pbr/atmosphere.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/coordinates.glsl"
    #include "/include/utility/depth.glsl"

    in vec2 uv;

    /* RENDERTARGETS: 0 */

    layout(location = 0) out vec4 color;

    void main() {
        color = texture(colortex0, uv);
        float depth = texture(depthtex0, uv).r;
        if (depth == 1.0 || frag_is_hand(depth)) {
            // FIX: clouds are still being ignored. try using cloudDistance for clouds specifically instead of the far plane
            return;
        }

        Material material;
        init_material_unpacked_colortex_read(material, uv);

        vec2 screen_uv = uv;
        // vec2 screen_uv = gl_FragCoord.xy / windowDimensions;
        vec3 frag_pos_view = screen_to_view(vec3(uv, depth) * 2. - 1.);
        vec3 frag_pos_world = view_to_world(frag_pos_view);

        // water fog
        if (material.block_id == ID_WATER) {
            float depth_at_bottom = depth_to_z(texture(depthtex2, uv).x);
            float water_dist = max0(depth_at_bottom - depth_to_z(depth)) / far;

            float sun_moon_intensity = compute_direct_light_scalar(dayProgress);
            vec3 sunlight = sun_moon_intensity * SUNLIGHT_COLOR; // lightmap_uv.y fixes some light leaks

            vec3 optical_density = -1e6 * vec3(0.00502, 0.000372, 0.000109); // from: https://en.wikipedia.org/wiki/Optical_properties_of_water_and_ice
            vec3 beer = sunlight * clamp01(exp(optical_density * water_dist));

            color.rgb = material.albedo * beer;
        }

        #if FOG == 1
            float object_distance_as_render_distance_proportion = length(frag_pos_view) / far;
            float fog_factor = exp(-FOG_DENSITY * (1. - object_distance_as_render_distance_proportion));

            frag_pos_world.y *= -1;
            frag_pos_view = world_to_view(frag_pos_world);
            vec3 sky_color_at_horizon = get_pbr_sky_color(frag_pos_view);

            color.rgb = oklab_mix(color.rgb, rgb_to_linear(fogColor), clamp01(fog_factor));
        #endif
    }
#endif