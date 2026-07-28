#if !defined INCLUDE_RSM
    #define INCLUDE_RSM

    #include "/include/settings.glsl"
    #include "/include/uniforms.glsl"
    #include "/include/pipeline.glsl"

    #include "/include/math/convenience.glsl"

    #include "/include/color/conversions.glsl"

    #include "/include/shadows/distort.glsl"

    #include "/include/utility/random.glsl"
    #include "/include/utility/dither.glsl"
    #include "/include/utility/space_conversions.glsl"
    #include "/include/utility/vogel_disk_blur.glsl"

    // -----------------------------
    //     Reflective Shadow Map
    // -----------------------------
    // resources:
    //     https://users.soe.ucsc.edu/~pang/160/s13/proposal/mijallen/proposal/media/p203-dachsbacher.pdf
    //     https://github.com/jbritain/glint-shaders/blob/a92967eedd3bb0928d32b6545059df3e6a548bfe/shaders/lib/lighting/reflectiveShadowMapping.glsl#L22

    vec3 compute_rsm_gi(vec3 fragment_pos_world, vec3 fragment_normal_world) {
        vec3 fragment_pos_feet = world_to_feet(fragment_pos_world);
        vec4 fragment_pos_sclip = feet_to_shadow_clip(fragment_pos_feet);
        vec3 fragment_pos_sscreen = shadow_clip_to_shadow_screen(fragment_pos_sclip);

        float dither = _interleaved_gradient_noise(gl_FragCoord.xy);
        // float dither = compute_dither(gl_FragCoord.xy);

        vec3 total_irradiance = vec3(0.);
        uint useful_samples = 0;

        const float RADIUS_SCALAR = SHADOW_DISTANCE_MULTIPLIER * RSM_RADIUS / shadowDistance;

        vec2 dSDepth = (dFdx(fragment_pos_sscreen.xy) + dFdy(fragment_pos_sscreen.xy));

        for (uint idx = 0; idx < RSM_SAMPLES; idx += 1) {
            vec2 texel_offset = dither * RADIUS_SCALAR * compute_vogel_disk_sample_uv(idx + 1, RSM_SAMPLES);
            vec3 sample_pos_sscreen = fragment_pos_sscreen + vec3(texel_offset, dot(texel_offset, dSDepth));
            vec4 sample_pos_sclip = shadow_screen_to_shadow_clip(sample_pos_sscreen);
            distort_shadow_clip_position(sample_pos_sclip.xyz);
            sample_pos_sscreen = shadow_clip_to_shadow_screen(sample_pos_sclip);

            if (uv_out_of_bounds(sample_pos_sscreen.xy) || sample_pos_sscreen.z == 1.) continue; // doesn't actually ever run... I think
            useful_samples += 1;

            vec4 sample_color = texture(shadowcolor0, sample_pos_sscreen.xy);
            vec3 radiant_flux = (sample_color.rgb * sample_color.a);

            vec3 sample_normal_world = texture(shadowcolor1, sample_pos_sscreen.xy).xyz * 2. - 1.;

            undistort_shadow_clip_position(sample_pos_sclip.xyz);
            vec3 sample_pos_world = feet_to_world(shadow_view_to_feet(shadow_clip_to_shadow_view(sample_pos_sclip)));
            vec3 direction = (sample_pos_world - fragment_pos_world);

            float dist = max(distance(sample_pos_world, fragment_pos_world), 1e-3);

            float distortion_factor = _get_distortion_factor(sample_pos_sclip.xy);

            total_irradiance += radiant_flux
                    * max0(dot(fragment_normal_world, direction))
                    * max0(dot(sample_normal_world, -direction))
                    / pow4(dist)
                    * tanh(distortion_factor);
        }

        if (useful_samples == 0) return vec3(0.);

        total_irradiance *= 1e2 * RSM_BRIGHTNESS / float(useful_samples);

        return total_irradiance;
    }
#endif
